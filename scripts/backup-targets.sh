#!/usr/bin/env bash
# --- Snapshot every target chezmoi is about to touch ---
#
# Usage: backup-targets.sh <chezmoi-binary> <repo-dir> <backup-dir>
#
# WHY A MANIFEST AND NOT JUST A TARBALL.
#
# A tarball alone cannot undo an apply. `chezmoi apply` CREATES files that
# did not exist before, and extracting an archive over the result leaves
# every one of those in place. The undo therefore has to know which paths
# were absent beforehand so it can delete them. That is what the manifest
# records, and it is the difference between a restore and a mess.
#
# BASH 3.2 ONLY (macOS /bin/bash is 3.2.57).
#
# KNOWN LIMIT, stated rather than hidden: `chezmoi managed` enumerates
# MANAGED entries only. An `exact_` directory additionally deletes unmanaged
# strays, which this snapshot never saw. If you introduce an `exact_`
# directory, back up that whole directory, not just its managed children.

set -euo pipefail

CHEZMOI="${1:?chezmoi binary required}"
REPO_DIR="${2:?repo dir required}"
BACKUP_DIR="${3:?backup dir required}"

DEST="${HOME}"
MANIFEST="${BACKUP_DIR}/manifest.tsv"
BUNDLE="${BACKUP_DIR}/targets.tar.gz"

mkdir -p "${BACKUP_DIR}"

# Portable mode read: GNU stat and BSD/macOS stat disagree on every flag.
perm_of() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null || echo '644'
}

# RELATIVE paths, deliberately, and this is load-bearing on Windows.
#
# With --path-style=absolute, chezmoi emits native paths: C:\Users\you\...
# on Windows. This script runs under Git Bash, where $HOME is /c/Users/you
# or similar, so stripping "${DEST}/" from a backslashed absolute path
# never matches. Every entry then falls through to the `external` branch,
# the archive captures nothing, and restore has nothing to restore.
#
# That failed silently: the script exited 0 and wrote a manifest full of
# rows, so it LOOKED like a backup. Relative paths sidestep the whole
# problem, because they are already what the manifest and the archive want.
#
# NUL-separated so a path containing whitespace survives. Scripts are
# excluded because they are listed as managed but produce no target file.
TARGETS="${BACKUP_DIR}/.targets"
"${CHEZMOI}" managed --source="${REPO_DIR}" --path-style=relative \
  --exclude=scripts,remove -0 > "${TARGETS}" 2>/dev/null || : > "${TARGETS}"

: > "${MANIFEST}"
PRESENT="${BACKUP_DIR}/.present"
: > "${PRESENT}"

count_total=0
count_present=0

while IFS= read -r -d '' rel; do
  [ -n "${rel}" ] || continue
  count_total=$((count_total + 1))
  # chezmoi may emit backslashes on Windows even for relative paths.
  # Normalise, because everything downstream (tar, the manifest, restore)
  # speaks forward slashes under Git Bash. Parameter expansion rather than
  # tr: no subshell per path, and no argument about how many backslashes a
  # quoted tr pattern really contains.
  rel="${rel//\\//}"
  target="${DEST}/${rel}"
  if [ -L "${target}" ]; then
    printf 'symlink\t%s\t%s\n' "${rel}" "$(readlink "${target}")" >> "${MANIFEST}"
    printf '%s\n' "${rel}" >> "${PRESENT}"
    count_present=$((count_present + 1))
  elif [ -d "${target}" ]; then
    printf 'dir\t%s\t%s\n' "${rel}" "$(perm_of "${target}")" >> "${MANIFEST}"
    printf '%s\n' "${rel}" >> "${PRESENT}"
    count_present=$((count_present + 1))
  elif [ -e "${target}" ]; then
    printf 'file\t%s\t%s\n' "${rel}" "$(perm_of "${target}")" >> "${MANIFEST}"
    printf '%s\n' "${rel}" >> "${PRESENT}"
    count_present=$((count_present + 1))
  else
    # The critical row. Restore must DELETE these, not skip them.
    printf 'absent\t%s\t-\n' "${rel}" >> "${MANIFEST}"
  fi
done < "${TARGETS}"

if [ -s "${PRESENT}" ]; then
  sort -u "${PRESENT}" -o "${PRESENT}"
  # --no-recursion because the manifest already names every entry; letting
  # tar recurse would pull in unmanaged children of a managed directory.
  ( cd "${DEST}" && tar --no-recursion -czf "${BUNDLE}" -T "${PRESENT}" ) 2>/dev/null \
    || ( cd "${DEST}" && tar -n -czf "${BUNDLE}" -T "${PRESENT}" )
else
  # A genuinely blank machine. Record the fact rather than leaving the
  # caller unable to tell "nothing to back up" from "backup failed".
  printf 'nothing existed to back up\n' > "${BACKUP_DIR}/EMPTY"
fi

rm -f "${TARGETS}" "${PRESENT}"

printf '%s targets managed, %s existed and were captured\n' \
  "${count_total}" "${count_present}" > "${BACKUP_DIR}/SUMMARY"
cat "${BACKUP_DIR}/SUMMARY"
