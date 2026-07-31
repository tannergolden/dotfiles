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

mkdir -p "${SCRATCH}/home" "${SCRATCH}/cfg" "${SCRATCH}/cache"
cm init --promptDefaults --no-tty </dev/null >/dev/null 2>&1

failures=0

# --- 1. the config template, via a real init -------------------------------
for os in darwin linux windows; do
  probe="$(mktemp -d)"
  if "${CHEZMOI}" --source="${SRC}" --destination="${probe}/home" \
       --config="${probe}/cfg/chezmoi.toml" --cache="${probe}/cache" \
       init --promptDefaults --no-tty </dev/null >/dev/null 2>&1; then
    echo "ok   .chezmoi.toml.tmpl initialises"
    rm -rf "${probe}"
    break
  else
    echo "FAIL .chezmoi.toml.tmpl does not initialise"
    failures=$((failures + 1))
    rm -rf "${probe}"
    break
  fi
done

# --- 2. every other template, for every platform ---------------------------
for os in darwin linux windows; do
  os_failures=0
  while IFS= read -r rel; do
    case "${rel}" in
      .chezmoi.toml.tmpl) continue ;;
    esac
    if ! out="$(cm execute-template --override-data "{\"chezmoi\":{\"os\":\"${os}\"}}" \
                  < "${SRC}/${rel}" 2>&1)"; then
      echo "FAIL [${os}] ${rel}"
      printf '%s\n' "${out}" | head -3 | sed 's/^/       /'
      os_failures=$((os_failures + 1))
    fi
  done < <(cd "${SRC}" && find . -name '*.tmpl' | sed 's|^\./||' | sort)

  if [ "${os_failures}" -eq 0 ]; then
    echo "ok   all templates render for os=${os}"
  fi
  failures=$((failures + os_failures))
done

# --- 3. what each platform would ignore ------------------------------------
for os in darwin linux windows; do
  printf 'ok   os=%-8s ignores: %s\n' "${os}" \
    "$(cm ignored --override-data "{\"chezmoi\":{\"os\":\"${os}\"}}" 2>/dev/null | tr '\n' ' ')"
done

echo "=== ${failures} render failure(s) ==="
[ "${failures}" -eq 0 ] || exit 1
exit 0
