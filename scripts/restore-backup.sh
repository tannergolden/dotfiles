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

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
die() { printf 'restore: %s\n' "$*" >&2; exit 1; }

# --- 0. everything that must be true BEFORE a single file is touched ------
#
# THIS SECTION EXISTS BECAUSE STEP 1 DELETES. Every check that can be made
# up front is made up front: once the deletions start, a failure leaves a
# home directory with the new files gone and the old ones not yet back,
# which is the worst state this script can produce.

[ -n "${DEST}" ] || die "HOME is unset; refusing to guess where to restore"
[ -d "${DEST}" ] || die "HOME (${DEST}) is not a directory"
[ -d "${BACKUP_DIR}" ] || die "no such backup directory: ${BACKUP_DIR}"
[ -f "${MANIFEST}" ] || die "no manifest at ${MANIFEST}"
[ -s "${MANIFEST}" ] || die "manifest at ${MANIFEST} is empty"

# A manifest row is three tab-separated fields. Anything else means the
# file was truncated or edited, and acting on half a manifest deletes a
# real file on the strength of a corrupt line.
if awk -F'\t' 'NF != 3 { bad = 1 } END { exit !bad }' "${MANIFEST}"; then
  die "manifest at ${MANIFEST} has malformed rows; refusing to act on it"
fi

# THE ARCHIVE IS VERIFIED BEFORE THE DELETIONS, not after. Previously the
# order was: delete what apply created, then extract. A corrupt or missing
# archive was therefore discovered only after the deletions had already
# happened, leaving nothing to put back. Reading the table of contents
# first costs a fraction of a second and makes that state unreachable.
if [ -f "${BUNDLE}" ]; then
  tar -tzf "${BUNDLE}" >/dev/null 2>&1 \
    || die "${BUNDLE} is unreadable; refusing to delete anything"
elif awk -F'\t' '$1 == "file" || $1 == "dir" || $1 == "symlink" { found = 1 }
                 END { exit !found }' "${MANIFEST}"; then
  # The manifest says files existed, so an archive should exist too. This
  # is the exact state a Windows bootstrap used to leave behind, where the
  # snapshot was written as targets.zip and this script looked only for
  # targets.tar.gz, then reported "nothing existed" and restored nothing.
  [ -f "${BACKUP_DIR}/targets.zip" ] \
    && die "this snapshot holds targets.zip, written by bootstrap.ps1; undo it with scripts/restore-backup.ps1"
  die "manifest records files that existed, but ${BUNDLE} is missing"
fi

# Reject any path that would escape $HOME before it reaches rm -rf. The
# manifest is generated locally, so this is a guard against corruption
# rather than an attacker, but the operation it guards is irreversible.
safe_rel() {
  case "$1" in
    ''|/*|[A-Za-z]:[/\\]*) return 1 ;;
    ..|../*|*/../*|*/..) return 1 ;;
  esac
  return 0
}

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

# DELETION IS TYPE-AWARE, AND THAT IS THE MOST IMPORTANT LINE IN THIS
# SCRIPT. The manifest records every managed target that did not exist as
# `absent`, and on a fresh machine that includes DIRECTORIES: ~/.config,
# ~/.local, ~/.local/bin, ~/.ssh and more. A blanket `rm -rf` on those
# took everything ANY program had written there since bootstrap - the ssh
# keys generated during the install, another application's settings,
# chezmoi's own state - and called it undo. Verified: after a bootstrap
# into an empty HOME, an unrelated ~/.config/some-app/settings.json and a
# hand-made ~/.ssh key were both destroyed at exit 0.
#
# So: files and symlinks are removed outright, directories only when the
# reverse sort above has already emptied them. A directory that gained
# unrelated content is KEPT and reported. `rmdir` is the whole mechanism -
# it refuses a non-empty directory by definition, so there is no race
# between testing and deleting.
removed=0
kept=0
while IFS= read -r rel; do
  [ -n "${rel}" ] || continue
  if ! safe_rel "${rel}"; then
    die "manifest names a path outside HOME: ${rel}"
  fi
  target="${DEST}/${rel}"
  if [ -L "${target}" ] || [ ! -d "${target}" ]; then
    # A symlink to a directory must be unlinked, never followed, hence
    # the -L test first.
    if [ -L "${target}" ] || [ -e "${target}" ]; then
      rm -f -- "${target}" || die "could not remove ${target}"
      printf '  removed %s\n' "${rel}"
      removed=$((removed + 1))
    fi
  elif [ -d "${target}" ]; then
    if rmdir "${target}" 2>/dev/null; then
      printf '  removed %s\n' "${rel}"
      removed=$((removed + 1))
    else
      printf '  kept    %s (not empty: it gained content after bootstrap)\n' "${rel}"
      kept=$((kept + 1))
    fi
  fi
done < "${ABSENT_LIST}"
log "removed ${removed} path(s) that bootstrap had created"
if [ "${kept}" -gt 0 ]; then
  log "kept ${kept} directory(ies) that gained content after bootstrap"
fi

# --- 2. put back what was there --------------------------------------------
if [ -f "${BUNDLE}" ]; then
  log "restoring archived targets"
  # Verified readable in section 0, so a failure here is an extraction
  # problem (a full disk, a permission) rather than a corrupt archive, and
  # it must stop the run: continuing to section 3 would chmod files that
  # were never put back.
  tar -xpzf "${BUNDLE}" -C "${DEST}" \
    || die "extraction failed; ${DEST} is partially restored, archive intact at ${BUNDLE}"
else
  log "no archive present (nothing existed at backup time)"
fi

# --- 3. re-assert modes ----------------------------------------------------
#
# A mode recorded as `-` means the backup could not read it, which the
# backup reported at the time. Those are skipped rather than guessed at,
# and counted, so "3 modes not restored" is visible instead of implied.
log "re-asserting recorded permissions"
restored_modes=0
skipped_modes=0
failed_modes=0
while IFS="$(printf '\t')" read -r kind rel extra; do
  case "${kind}" in
    file|dir)
      safe_rel "${rel}" || die "manifest names a path outside HOME: ${rel}"
      target="${DEST}/${rel}"
      [ -e "${target}" ] || continue
      case "${extra}" in
        [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7])
          if chmod "${extra}" "${target}" 2>/dev/null; then
            restored_modes=$((restored_modes + 1))
          else
            # NTFS has no POSIX mode bits, so this is expected under Git
            # Bash and must not fail the restore. Counted and reported
            # once at the end rather than printed per file.
            failed_modes=$((failed_modes + 1))
          fi
          ;;
        *) skipped_modes=$((skipped_modes + 1)) ;;
      esac
      ;;
    *) ;;
  esac
done < "${MANIFEST}"

printf '  %s mode(s) restored' "${restored_modes}"
[ "${skipped_modes}" -eq 0 ] || printf ', %s unrecorded at backup time' "${skipped_modes}"
[ "${failed_modes}" -eq 0 ] || printf ', %s not settable on this filesystem' "${failed_modes}"
printf '\n'

# --- 4. put back anything --reset cleared ---------------------------------
#
# reset-conflicts.sh preserves each file it removes into conflicts/ and
# records it in conflicts.tsv. Kept separate from the main archive rather
# than appended to it, because appending to a compressed tar is not a
# thing you can do reliably, and because a reader looking at a snapshot
# should be able to see at a glance which files were removed for
# conflicting rather than merely overwritten.
CONFLICTS_TSV="${BACKUP_DIR}/conflicts.tsv"
CONFLICTS_DIR="${BACKUP_DIR}/conflicts"
if [ -f "${CONFLICTS_TSV}" ]; then
  log "restoring configuration that --reset cleared"
  restored_conflicts=0
  while IFS="$(printf '\t')" read -r rel mode; do
    [ -n "${rel}" ] || continue
    safe_rel "${rel}" || die "conflicts.tsv names a path outside HOME: ${rel}"
    [ -e "${CONFLICTS_DIR}/${rel}" ] \
      || die "conflicts.tsv lists ${rel} but ${CONFLICTS_DIR}/${rel} is missing"
    mkdir -p "$(dirname "${DEST}/${rel}")"
    cp -R "${CONFLICTS_DIR}/${rel}" "${DEST}/${rel}" \
      || die "could not restore ${rel}"
    case "${mode}" in
      [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]) chmod "${mode}" "${DEST}/${rel}" 2>/dev/null || : ;;
    esac
    printf '  restored %s\n' "${rel}"
    restored_conflicts=$((restored_conflicts + 1))
  done < "${CONFLICTS_TSV}"
  log "restored ${restored_conflicts} file(s) that --reset had cleared"
fi

log "restore complete from ${BACKUP_DIR}"
