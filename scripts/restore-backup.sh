#!/usr/bin/env bash
# --- Undo a bootstrap ---
#
# Usage: restore-backup.sh <backup-dir>
#
# Restores $HOME to the state recorded by backup-targets.sh:
#   1. delete every path the manifest marked `absent` (apply created these)
#   2. extract the archive, preserving modes
#   3. re-assert recorded modes, because tar's -p is not universally honoured
#
# Deletion runs in REVERSE sort order so children go before their parents.
#
# BASH 3.2 ONLY.

set -euo pipefail

BACKUP_DIR="${1:?usage: restore-backup.sh <backup-dir>}"
MANIFEST="${BACKUP_DIR}/manifest.tsv"
BUNDLE="${BACKUP_DIR}/targets.tar.gz"
DEST="${HOME}"

[ -f "${MANIFEST}" ] || { echo "no manifest at ${MANIFEST}" >&2; exit 1; }

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- 1. remove what apply created ------------------------------------------
#
# Reverse sort so children are removed before their parents. The list is
# materialised to a temp file rather than piped, because a `while` on the
# right of a pipe runs in a subshell and any counter it keeps is lost when
# that subshell exits.
log "removing paths that did not exist before bootstrap"
ABSENT_LIST="$(mktemp)"
trap 'rm -f "${ABSENT_LIST}"' EXIT

awk -F'\t' '$1 == "absent" { print $2 }' "${MANIFEST}" | sort -r > "${ABSENT_LIST}"

removed=0
while IFS= read -r rel; do
  [ -n "${rel}" ] || continue
  target="${DEST}/${rel}"
  if [ -L "${target}" ] || [ -e "${target}" ]; then
    rm -rf -- "${target}"
    printf '  removed %s\n' "${rel}"
    removed=$((removed + 1))
  fi
done < "${ABSENT_LIST}"
log "removed ${removed} path(s) that bootstrap had created"

# --- 2. put back what was there --------------------------------------------
if [ -f "${BUNDLE}" ]; then
  log "restoring archived targets"
  tar -xpzf "${BUNDLE}" -C "${DEST}"
else
  log "no archive present (nothing existed at backup time)"
fi

# --- 3. re-assert modes ----------------------------------------------------
log "re-asserting recorded permissions"
while IFS="$(printf '\t')" read -r kind rel extra; do
  case "${kind}" in
    file|dir)
      target="${DEST}/${rel}"
      [ -e "${target}" ] || continue
      case "${extra}" in
        [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) chmod "${extra}" "${target}" ;;
      esac
      ;;
    *) ;;
  esac
done < "${MANIFEST}"

log "restore complete from ${BACKUP_DIR}"
