#!/usr/bin/env bash
# --- Guard against chezmoi attribute prefixes written in the wrong order ---
#
# THE BUG THIS CATCHES, which is a silent secret exposure.
#
# chezmoi's attribute prefixes have a fixed order. Written out of order,
# they are NOT an error: the unrecognised prefix is folded into the target
# FILENAME and its meaning is lost. Reproduced:
#
#   private_dot_correct  ->  ~/.correct         mode 0600   correct
#   dot_private_token    ->  ~/.private_token   mode 0644   WRONG
#
# Exit code 0. No warning. And `chezmoi doctor` reports
# "ok  suspicious-entries  no suspicious entries" for both.
#
# So a file you believe is mode 0600 is world-readable, in a public
# repository, and nothing tells you. This check is the only thing that does.
#
# The correct order is:
#   remove_ external_ exact_ encrypted_ create_ modify_ private_ readonly_
#   empty_ executable_ symlink_ dot_  <name>  [.tmpl]

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_DIR}/home"
CHEZMOI="${CHEZMOI:-chezmoi}"

command -v "${CHEZMOI}" >/dev/null 2>&1 || { echo "chezmoi not on PATH" >&2; exit 127; }

SCRATCH="$(mktemp -d)"
trap 'rm -rf "${SCRATCH}"' EXIT
mkdir -p "${SCRATCH}/home" "${SCRATCH}/cfg" "${SCRATCH}/cache"

cm() {
  "${CHEZMOI}" --source="${SRC}" --destination="${SCRATCH}/home" \
    --config="${SCRATCH}/cfg/chezmoi.toml" --cache="${SCRATCH}/cache" "$@"
}

if ! init_err="$(cm init --promptDefaults --no-tty </dev/null 2>&1)"; then
  echo "FAIL could not initialise a scratch chezmoi to run the check against" >&2
  printf '%s\n' "${init_err}" | sed 's/^/       /' >&2
  exit 1
fi

# Any of these appearing in a TARGET path means the prefix was not
# consumed as an attribute, which means it did not take effect.
PREFIXES='private_|readonly_|executable_|empty_|exact_|encrypted_|create_|modify_|symlink_|remove_|external_|literal_|run_|dot_'

# THE LIST IS MATERIALISED BEFORE IT IS READ, and that is the point.
#
# This used to be `done < <(cm managed ... 2>/dev/null || true)`, which
# meant a chezmoi that failed for any reason fed the loop nothing, `leaked`
# stayed 0, and the script printed "ok no attribute prefix leaked" having
# examined not one path. A check that cannot fail is worse than no check,
# because it is believed. Now the enumeration is a separate, fatal step and
# an empty result is itself an error.
TARGETS="${SCRATCH}/targets"
if ! cm managed --path-style=relative > "${TARGETS}" 2>"${SCRATCH}/managed-err"; then
  echo "FAIL could not enumerate managed targets" >&2
  sed 's/^/       /' "${SCRATCH}/managed-err" >&2 || :
  exit 1
fi
if [ ! -s "${TARGETS}" ]; then
  echo "FAIL chezmoi reports no managed targets; this check examined nothing" >&2
  exit 1
fi

leaked=0
examined=0
while IFS= read -r target; do
  [ -n "${target}" ] || continue
  examined=$((examined + 1))
  base="$(basename "${target}")"
  if printf '%s' "${base}" | grep -qE "^\.?(${PREFIXES})"; then
    echo "FAIL leaked attribute prefix in target path: ${target}"
    leaked=$((leaked + 1))
  fi
done < "${TARGETS}"

if [ "${examined}" -eq 0 ]; then
  echo "FAIL read the target list but examined nothing" >&2
  exit 1
fi

if [ "${leaked}" -eq 0 ]; then
  echo "ok   no attribute prefix leaked into a target path (${examined} examined)"
else
  cat >&2 <<'EOF'

A prefix appears in a target filename, which means chezmoi did not treat it
as an attribute. Check the prefix ORDER in the source filename. The most
common instance is writing dot_private_x when you meant private_dot_x.
EOF
fi

[ "${leaked}" -eq 0 ] || exit 1
exit 0
