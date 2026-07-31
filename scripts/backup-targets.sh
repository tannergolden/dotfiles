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

die() { printf 'backup: %s\n' "$*" >&2; exit 1; }

# EVERY FAILURE BELOW IS FATAL, and that is the whole design of this file.
# A backup that fails halfway is worse than one that never ran, because
# bootstrap continues on a zero exit and applies over the originals. The
# caller treats non-zero as "refuse to apply", so anything uncertain here
# must exit non-zero rather than carry on with a partial snapshot.

[ -n "${DEST}" ] || die "HOME is unset; refusing to guess where targets live"
[ -d "${DEST}" ] || die "HOME (${DEST}) is not a directory"
[ -x "${CHEZMOI}" ] || command -v "${CHEZMOI}" >/dev/null 2>&1 \
  || die "chezmoi not executable: ${CHEZMOI}"
[ -d "${REPO_DIR}/home" ] || die "no source state at ${REPO_DIR}/home"

# Refuse to write into a directory that already holds a snapshot. Bootstrap
# names these by UTC second, so a collision means two runs in the same
# second or a hand-passed path, and overwriting either one destroys the
# only copy of somebody's original files.
if [ -e "${BACKUP_DIR}/manifest.tsv" ] || [ -e "${BACKUP_DIR}/targets.tar.gz" ]; then
  die "${BACKUP_DIR} already contains a snapshot; refusing to overwrite it"
fi

mkdir -p "${BACKUP_DIR}" || die "cannot create ${BACKUP_DIR}"
[ -w "${BACKUP_DIR}" ] || die "${BACKUP_DIR} is not writable"

# Portable mode read: GNU stat and BSD/macOS stat disagree on every flag.
#
# A FAILURE HERE IS REPORTED, NOT PAPERED OVER. This previously fell back
# to 644 in silence, which is the wrong direction to guess in: restore
# re-asserts whatever the manifest says, so a 0600 file whose mode could
# not be read came back world-readable and nothing announced it. Now the
# unreadable mode is recorded as `-`, restore leaves such a file's mode
# alone, and the reason is printed once here.
perm_of() {
  local mode
  if mode="$(stat -c '%a' "$1" 2>/dev/null)" && [ -n "${mode}" ]; then
    printf '%s' "${mode}"
  elif mode="$(stat -f '%Lp' "$1" 2>/dev/null)" && [ -n "${mode}" ]; then
    printf '%s' "${mode}"
  else
    printf 'could not read mode of %s; restore will leave it unchanged\n' "$1" >&2
    printf '%s' '-'
  fi
}

# A relative path from `chezmoi managed` should never be absolute and never
# climb out of $HOME. If one does, something upstream is wrong and restore
# would later rm -rf that path, so this refuses rather than records it.
reject_unsafe() {
  case "$1" in
    /*|[A-Za-z]:[/\\]*) die "refusing an absolute managed path: $1" ;;
    ..|../*|*/../*|*/..) die "refusing a managed path containing '..': $1" ;;
  esac
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
#
# A FAILING ENUMERATION IS FATAL. This used to redirect stderr to nowhere
# and fall back to an empty list, so a chezmoi that could not read the
# source state produced a snapshot of nothing, exited 0, and bootstrap
# applied straight over the originals. That is precisely the shape of the
# Windows path bug described above: exit 0, plausible output, no backup.
TARGETS="${BACKUP_DIR}/.targets"
MANAGED_ERR="${BACKUP_DIR}/.managed-err"
if ! "${CHEZMOI}" managed --source="${REPO_DIR}" --path-style=relative \
     --exclude=scripts,remove -0 > "${TARGETS}" 2>"${MANAGED_ERR}"; then
  printf 'backup: chezmoi could not enumerate managed targets\n' >&2
  sed 's/^/  /' "${MANAGED_ERR}" >&2 || :
  rm -f "${TARGETS}" "${MANAGED_ERR}"
  exit 1
fi
rm -f "${MANAGED_ERR}"

# An empty list is legitimate on a repository with nothing managed, but it
# is indistinguishable from a broken enumeration, so say which one it is
# rather than leaving the caller to infer it from a silent exit.
if [ ! -s "${TARGETS}" ]; then
  printf 'backup: chezmoi reports NO managed targets for %s\n' "${REPO_DIR}" >&2
  printf '        nothing can be backed up, and apply would write unguarded\n' >&2
  rm -f "${TARGETS}"
  exit 1
fi

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
  reject_unsafe "${rel}"
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
  # GNU spells it --no-recursion and BSD spells it -n, so try each in turn.
  # The stderr of the first attempt is kept and only shown if BOTH fail,
  # which is the difference between "your tar wanted the other flag" and
  # "the archive could not be written".
  TAR_ERR="${BACKUP_DIR}/.tar-err"
  if ! ( cd "${DEST}" && tar --no-recursion -czf "${BUNDLE}" -T "${PRESENT}" ) 2>"${TAR_ERR}"; then
    if ! ( cd "${DEST}" && tar -n -czf "${BUNDLE}" -T "${PRESENT}" ) 2>>"${TAR_ERR}"; then
      printf 'backup: could not write %s\n' "${BUNDLE}" >&2
      sed 's/^/  /' "${TAR_ERR}" >&2 || :
      rm -f "${TAR_ERR}"
      exit 1
    fi
  fi
  rm -f "${TAR_ERR}"

  # PROVE THE ARCHIVE IS READABLE BEFORE ANYONE RELIES ON IT. A tar that
  # exits 0 having written a truncated file is rare but not impossible, and
  # the moment it matters is the moment you cannot check. Listing costs a
  # fraction of a second and turns "the backup is corrupt" from a discovery
  # made during a restore into a failure before apply ever runs.
  if ! tar -tzf "${BUNDLE}" >/dev/null 2>&1; then
    printf 'backup: %s was written but cannot be read back\n' "${BUNDLE}" >&2
    exit 1
  fi

  # Every path recorded as present must actually be in the archive, or the
  # restore silently puts back less than it claims to.
  archived="$(tar -tzf "${BUNDLE}" 2>/dev/null | sed 's|/$||' | sort -u | wc -l | tr -d ' ')"
  expected="$(wc -l < "${PRESENT}" | tr -d ' ')"
  if [ "${archived}" -lt "${expected}" ]; then
    printf 'backup: archive holds %s entries but %s were recorded as present\n' \
      "${archived}" "${expected}" >&2
    exit 1
  fi
else
  # A genuinely blank machine. Record the fact rather than leaving the
  # caller unable to tell "nothing to back up" from "backup failed".
  printf 'nothing existed to back up\n' > "${BACKUP_DIR}/EMPTY"
fi

rm -f "${TARGETS}" "${PRESENT}"

printf '%s targets managed, %s existed and were captured\n' \
  "${count_total}" "${count_present}" > "${BACKUP_DIR}/SUMMARY"
cat "${BACKUP_DIR}/SUMMARY"
