#!/usr/bin/env bash
# --- Render every template for every platform, from any platform ---
#
# THIS IS THE MOST VALUABLE CHECK IN THE REPOSITORY.
#
# `--override-data` changes both template rendering AND .chezmoiignore
# evaluation, so a Linux box can type-check the entire Windows branch of
# the tree. A typo in a Windows-only template is invisible to every macOS
# apply and would otherwise surface on a new Windows machine at the worst
# possible moment. This catches it in about twenty seconds on the cheapest
# runner available.
#
# EXCLUSION THAT IS NOT A CHEAT: .chezmoi.toml.tmpl cannot be rendered this
# way. Its promptStringOnce and promptBoolOnce functions exist only during
# `chezmoi init`, so `execute-template` fails with "function not defined"
# no matter how correct the file is. It is exercised separately below by
# running an actual init against a throwaway directory.

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_DIR}/home"
CHEZMOI="${CHEZMOI:-chezmoi}"

command -v "${CHEZMOI}" >/dev/null 2>&1 || { echo "chezmoi not on PATH" >&2; exit 127; }

SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT

cm() {
  "${CHEZMOI}" --source="${SRC}" --destination="${SCRATCH}/home" \
    --config="${SCRATCH}/cfg/chezmoi.toml" --cache="${SCRATCH}/cache" "$@"
}

[ -d "${SRC}" ] || { echo "no source state at ${SRC}" >&2; exit 1; }

mkdir -p "${SCRATCH}/home" "${SCRATCH}/cfg" "${SCRATCH}/cache"
if ! init_err="$(cm init --promptDefaults --no-tty </dev/null 2>&1)"; then
  echo "FAIL could not initialise a scratch chezmoi to render against" >&2
  printf '%s\n' "${init_err}" | sed 's/^/       /' >&2
  exit 1
fi

failures=0

# --- 1. the config template, via a real init -------------------------------
#
# One init, not a loop. This was written as `for os in darwin linux
# windows` with an unconditional `break` in both branches, so it ran
# exactly once and the loop variable was never used: the shape implied
# three platforms were being initialised when only one ever was. Init
# reads the host's own OS and --override-data does not reach it, so one
# run is all this can honestly claim. The per-platform coverage is
# section 2, where --override-data does apply.
probe="$(mktemp -d)"
if init_err="$("${CHEZMOI}" --source="${SRC}" --destination="${probe}/home" \
     --config="${probe}/cfg/chezmoi.toml" --cache="${probe}/cache" \
     init --promptDefaults --no-tty </dev/null 2>&1)"; then
  echo "ok   .chezmoi.toml.tmpl initialises"
else
  echo "FAIL .chezmoi.toml.tmpl does not initialise"
  printf '%s\n' "${init_err}" | head -5 | sed 's/^/       /'
  failures=$((failures + 1))
fi
rm -rf "${probe}"

# --- 2. every other template, for every platform ---------------------------
# A repository with no templates would sail through section 2 reporting
# three cheerful ok lines, so the list is counted once, up front.
TMPL_LIST="${SCRATCH}/templates"
( cd "${SRC}" && find . -name '*.tmpl' ) | sed 's|^\./||' | sort > "${TMPL_LIST}"
if [ ! -s "${TMPL_LIST}" ]; then
  echo "FAIL found no .tmpl files under ${SRC}; this check would pass vacuously" >&2
  exit 1
fi

for os in darwin linux windows; do
  os_failures=0
  os_rendered=0
  while IFS= read -r rel; do
    case "${rel}" in
      .chezmoi.toml.tmpl) continue ;;
    esac
    os_rendered=$((os_rendered + 1))
    if ! out="$(cm execute-template --override-data "{\"chezmoi\":{\"os\":\"${os}\"}}" \
                  < "${SRC}/${rel}" 2>&1)"; then
      echo "FAIL [${os}] ${rel}"
      printf '%s\n' "${out}" | head -3 | sed 's/^/       /'
      os_failures=$((os_failures + 1))
    fi
  done < "${TMPL_LIST}"

  if [ "${os_rendered}" -eq 0 ]; then
    echo "FAIL rendered no templates for os=${os}"
    failures=$((failures + 1))
  elif [ "${os_failures}" -eq 0 ]; then
    echo "ok   all ${os_rendered} templates render for os=${os}"
  fi
  failures=$((failures + os_failures))
done

# --- 3. what each platform would ignore ------------------------------------
#
# `2>/dev/null` used to hide a failing `chezmoi ignored` behind a printed
# "ok" with an empty list, which reads as "this platform ignores nothing"
# rather than "the question was never answered".
for os in darwin linux windows; do
  if ! ignored="$(cm ignored --override-data "{\"chezmoi\":{\"os\":\"${os}\"}}" 2>&1)"; then
    echo "FAIL could not list ignores for os=${os}"
    printf '%s\n' "${ignored}" | head -3 | sed 's/^/       /'
    failures=$((failures + 1))
    continue
  fi
  printf 'ok   os=%-8s ignores: %s\n' "${os}" "$(printf '%s' "${ignored}" | tr '\n' ' ')"
done

echo "=== ${failures} render failure(s) ==="
[ "${failures}" -eq 0 ] || exit 1
exit 0
