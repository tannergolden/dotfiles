#!/usr/bin/env bash
# --- Parse every PowerShell file this repository ships ---
#
# WHY THIS EXISTS.
#
# Until now nothing checked the PowerShell at all. `make lint` ran
# ShellCheck over install.sh and scripts/*.sh, and the two .ps1 files were
# never read by any tool. A syntax error in bootstrap.ps1 would therefore
# survive every green pipeline and surface exactly once: at a new Windows
# machine, in the first command typed on it, which is the worst place this
# repository can fail.
#
# WHAT IT CHECKS, stated so a pass is not overread. This is a PARSER, not
# an analyser. It catches syntax errors, unbalanced braces, and malformed
# expressions. It does not catch an undefined variable, a wrong cmdlet
# name, or a logic error, and it does not run a single line of the file.
# PSScriptAnalyzer would catch more, and is deliberately not used: it
# installs from PSGallery at run time, which is network dependency and
# supply chain surface in exchange for lint on two files.
#
# Skips rather than fails when pwsh is absent, matching lint-shell's
# treatment of a missing shellcheck. CI runs on a runner that has it.

set -euo pipefail

# Exported because the pwsh block below reads it as $env:REPO_DIR. Computed
# here rather than trusted from the caller, so running the script directly
# behaves the same as running it through make.
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_DIR

if ! command -v pwsh >/dev/null 2>&1; then
  echo "pwsh not installed; skipping PowerShell parse (CI has it)"
  exit 0
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

# The work list is two tab-separated columns: the LABEL to report a problem
# against, and the PATH to actually parse. They differ for a rendered
# template, where the path is a staging file nobody can open and the label
# is the source template somebody can fix. Reporting the staging path was
# the first version, and it sent a reader to a directory that no longer
# exists by the time they read the message.
WORK="$(mktemp)"
trap 'rm -rf "${STAGE}"; rm -f "${WORK}"' EXIT

# Plain .ps1 files, parsed where they sit.
( cd "${REPO_DIR}" && find . -name '*.ps1' -not -path './.git/*' | sort ) \
  | while IFS= read -r rel; do
      [ -n "${rel}" ] || continue
      printf '%s\t%s\n' "${rel#./}" "${REPO_DIR}/${rel#./}"
    done > "${WORK}"

if [ ! -s "${WORK}" ]; then
  echo "no .ps1 files found; nothing to parse" >&2
  exit 1
fi

# --- and the templated ones, which are the three that actually matter -----
#
# The Windows provisioning scripts are .ps1.tmpl, so a plain find never saw
# them and nothing has ever parsed them. render-all-os.sh proves they are
# valid GO TEMPLATES; it says nothing about whether what comes out the
# other side is valid PowerShell. These three run on every Windows
# bootstrap, unattended, before anything else, so a syntax error in one
# reaches a new machine having passed a green pipeline.
#
# Rendered for os=windows because that is the only branch that ever runs,
# then parsed alongside the rest.
CHEZMOI="${CHEZMOI:-chezmoi}"
TMPLS="$(cd "${REPO_DIR}" && find . -name '*.ps1.tmpl' -not -path './.git/*' | sort)"

if [ -n "${TMPLS}" ]; then
  if ! command -v "${CHEZMOI}" >/dev/null 2>&1; then
    echo "chezmoi not on PATH; cannot render .ps1.tmpl for parsing" >&2
    exit 1
  fi
  mkdir -p "${STAGE}/rendered" "${STAGE}/home" "${STAGE}/cfg" "${STAGE}/cache"
  cm() {
    "${CHEZMOI}" --source="${REPO_DIR}/home" --destination="${STAGE}/home" \
      --config="${STAGE}/cfg/chezmoi.toml" --cache="${STAGE}/cache" "$@"
  }
  if ! init_err="$(cm init --promptDefaults --no-tty </dev/null 2>&1)"; then
    echo "FAIL could not initialise a scratch chezmoi to render templates" >&2
    printf '%s\n' "${init_err}" | sed 's/^/       /' >&2
    exit 1
  fi

  rendered_count=0
  while IFS= read -r rel; do
    [ -n "${rel}" ] || continue
    src="${REPO_DIR}/${rel#./}"
    # Flattened name, so two templates in different directories cannot
    # collide in the staging directory.
    flat="$(printf '%s' "${rel#./}" | tr '/' '_')"
    out="${STAGE}/rendered/${flat%.tmpl}"
    if ! cm execute-template --override-data '{"chezmoi":{"os":"windows"}}' \
         < "${src}" > "${out}" 2>"${STAGE}/render-err"; then
      echo "FAIL could not render ${rel} for os=windows" >&2
      sed 's/^/       /' "${STAGE}/render-err" >&2 || :
      exit 1
    fi
    rendered_count=$((rendered_count + 1))
    # Labelled by the source template, rendered for windows, so a failure
    # names a file in the repository rather than one in /tmp.
    printf '%s (rendered for os=windows)\t%s\n' "${rel#./}" "${out}" >> "${WORK}"
  done <<EOF
${TMPLS}
EOF

  if [ "${rendered_count}" -eq 0 ]; then
    echo "FAIL found .ps1.tmpl files but rendered none" >&2
    exit 1
  fi
fi

# The parse runs inside pwsh because only PowerShell can parse PowerShell.
# Errors are printed with file, line and column, then the count decides the
# exit code.
#
# SINGLE QUOTES ARE LOAD-BEARING, not an oversight. Every $ below belongs
# to PowerShell, and letting bash expand $path, $errors or $_ would hand
# pwsh a script with those words deleted. ShellCheck cannot tell this
# argument is another language, so it reads the quoting as the usual
# mistake and has to be told once, here.
# shellcheck disable=SC2016
pwsh -NoProfile -NonInteractive -Command '
  $ErrorActionPreference = "Stop"
  $failed = 0
  $checked = 0
  foreach ($line in $input) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $parts = $line -split "`t", 2
    if ($parts.Count -ne 2) { continue }
    $label = $parts[0]
    $path  = $parts[1]
    $checked++
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
      $path, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
      foreach ($e in $errors) {
        $ext = $e.Extent
        Write-Host ("FAIL {0}:{1}:{2} {3}" -f `
          $label, $ext.StartLineNumber, $ext.StartColumnNumber, $e.Message)
      }
      $failed++
    }
  }
  if ($checked -eq 0) {
    Write-Host "FAIL parsed no PowerShell files"
    exit 1
  }
  if ($failed -eq 0) {
    Write-Host ("ok   {0} PowerShell file(s) parse" -f $checked)
    exit 0
  }
  Write-Host ("=== {0} PowerShell file(s) failed to parse ===" -f $failed)
  exit 1
' < "${WORK}"
