#!/usr/bin/env bash
# --- ShellCheck the shell this repository GENERATES, not just the shell it stores ---
#
# WHY THIS EXISTS, and it is the same hole check-powershell.sh was written
# to close, left open on the other side.
#
# `make lint-shell` runs ShellCheck over install.sh, scripts/*.sh and the
# ai-* bin scripts. The four provisioning scripts are .sh.tmpl, so that
# glob never saw them, and render-all-os.sh only proves they are valid GO
# TEMPLATES - it says nothing about whether what comes out is valid shell.
#
# The smoke test does execute them, but with CI_STUB=1 every one exits
# inside the stub branch at the top, three lines in. Bash parses a script
# in full before running it, so a syntax error would be caught - but a
# quoting bug, an unquoted expansion or a misused array in the REAL branch
# runs on a new machine having passed a green pipeline, which is exactly
# where this repository can least afford to fail.
#
# So: render each template for its own OS, then parse and lint the result.
#
# WHAT A PASS DOES NOT MEAN. This is static analysis of one rendering. It
# cannot know whether `brew bundle` succeeded, and a template whose data
# makes it render differently on another machine is only checked in the
# form produced here.
#
# BASH 3.2 ONLY, like every other script in this directory.

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI="${CHEZMOI:-chezmoi}"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck not installed; skipping rendered-template lint (CI installs it)"
  exit 0
fi
if ! command -v "${CHEZMOI}" >/dev/null 2>&1; then
  echo "chezmoi not on PATH; cannot render .sh.tmpl for linting" >&2
  exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
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

TMPLS="$(cd "${REPO_DIR}" && find . -name '*.sh.tmpl' -not -path './.git/*' | sort)"
if [ -z "${TMPLS}" ]; then
  echo "FAIL no .sh.tmpl files found; this check examined nothing" >&2
  exit 1
fi

checked=0
failed=0

while IFS= read -r rel; do
  [ -n "${rel}" ] || continue
  src="${REPO_DIR}/${rel#./}"

  # Each template renders for exactly one OS - the one its own guard
  # admits - so a darwin template rendered for linux produces an empty
  # file that proves nothing. The name carries the answer.
  case "${rel}" in
    *darwin*)  os=darwin ;;
    *windows*) continue ;;   # check-powershell.sh owns these
    *linux*)   os=linux ;;
    *posix*)   os=linux ;;   # the POSIX scripts guard on `ne windows`
    *)         os=linux ;;
  esac

  flat="$(printf '%s' "${rel#./}" | tr '/' '_')"
  out="${STAGE}/rendered/${flat%.tmpl}"

  if ! cm execute-template --override-data "{\"chezmoi\":{\"os\":\"${os}\"}}" \
       < "${src}" > "${out}" 2>"${STAGE}/render-err"; then
    echo "FAIL could not render ${rel#./} for os=${os}" >&2
    sed 's/^/       /' "${STAGE}/render-err" >&2 || :
    failed=$((failed + 1))
    continue
  fi

  # An empty rendering means the OS guard excluded everything, which means
  # the case above chose the wrong OS and this file was never really
  # checked. Fail rather than count a vacuous pass.
  if [ ! -s "${out}" ]; then
    echo "FAIL ${rel#./} rendered empty for os=${os}; the check would be vacuous" >&2
    failed=$((failed + 1))
    continue
  fi

  checked=$((checked + 1))

  if ! bash -n "${out}" 2>"${STAGE}/parse-err"; then
    echo "FAIL ${rel#./} (rendered for os=${os}) is not valid bash:"
    sed "s|${out}|${rel#./}|g; s/^/       /" "${STAGE}/parse-err" >&2 || :
    failed=$((failed + 1))
    continue
  fi

  # Rewrite the staging path in the output to the source template, so a
  # finding names a file somebody can open rather than one in /tmp that
  # is deleted by the time they read the message.
  if ! sc_out="$(shellcheck --severity=style --shell=bash "${out}" 2>&1)"; then
    echo "FAIL ${rel#./} (rendered for os=${os}):"
    printf '%s\n' "${sc_out}" | sed "s|${out}|${rel#./} [rendered]|g; s/^/       /"
    failed=$((failed + 1))
  fi
done <<EOF
${TMPLS}
EOF

if [ "${checked}" -eq 0 ]; then
  echo "FAIL rendered no shell templates; this check examined nothing" >&2
  exit 1
fi

if [ "${failed}" -eq 0 ]; then
  echo "ok   ${checked} rendered shell template(s) parse and lint clean"
  exit 0
fi

echo "=== ${failed} rendered shell template(s) failed ===" >&2
exit 1
