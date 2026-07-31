#!/usr/bin/env bash
# --- Clear the config that silently overrides this repository ---
#
# Usage:
#   reset-conflicts.sh <chezmoi-binary> <repo-dir>                 report only
#   reset-conflicts.sh <chezmoi-binary> <repo-dir> <backup-dir>    preserve, then remove
#
# WHAT THIS IS FOR, and what it deliberately is not.
#
# A machine drifts from this repository in a way `chezmoi verify` cannot
# see, because the files that cause it are ones chezmoi does not manage. It
# reports every managed file as identical and correct, and the machine
# still behaves differently, which is the most confusing shape a
# configuration bug can take.
#
# THE WORKED EXAMPLE, verified rather than assumed. Git reads
# ~/.config/git/config, which this repository owns. It ALSO reads
# ~/.gitconfig, and ~/.gitconfig wins. With both present and only the
# stray setting user.email, `git config --global --get user.email` returns
# the stray value; delete it and the repository's value appears. So every
# line of the git configuration here, the signing gate included, loses
# silently to a file nothing in this repository looks at.
#
# WHAT IT WILL NOT TOUCH, on purpose:
#
#   * Terminal.app and Windows Terminal preferences. Those hold every
#     profile, window group and setting you have, not only the one this
#     repository owns. Resetting them to clear one profile destroys the
#     rest, and on macOS it cannot work from a shell running inside
#     Terminal anyway: Terminal rewrites its own preferences on quit, so
#     the write races the process that will overwrite it.
#   * Anything this repository never claimed. The list below is short and
#     specific by design. A reset that removes whatever it does not
#     recognise is a reset nobody can safely run twice.
#   * The documented escape hatches. ~/.zshrc.local and
#     ~/.config/git/config.local exist so a machine CAN differ on purpose.
#     They are reported, never removed.
#
# REPORTING IS THE DEFAULT. Removal happens only when a backup directory is
# given, and every removed file is preserved into it first, so the ordinary
# restore puts it back.
#
# BASH 3.2 ONLY.

set -euo pipefail

CHEZMOI="${1:?chezmoi binary required}"
REPO_DIR="${2:?repo dir required}"
BACKUP_DIR="${3:-}"

DEST="${HOME}"
[ -n "${DEST}" ] || { echo "reset: HOME is unset" >&2; exit 1; }
[ -d "${DEST}" ] || { echo "reset: HOME (${DEST}) is not a directory" >&2; exit 1; }

MODE="report"
[ -n "${BACKUP_DIR}" ] && MODE="remove"

CONFLICTS_DIR="${BACKUP_DIR}/conflicts"
CONFLICTS_TSV="${BACKUP_DIR}/conflicts.tsv"

found=0
removed=0
noted=0

# --- helpers --------------------------------------------------------------

perm_of() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null || printf '%s' '-'
}

# Preserve into the snapshot, then remove. The copy happens first and its
# failure is fatal: removing a file whose preservation failed is exactly
# the outcome this whole design exists to prevent.
take() {
  local rel="$1" why="$2"
  local target="${DEST}/${rel}"
  found=$((found + 1))

  if [ "${MODE}" = "report" ]; then
    printf '  would remove  %-28s %s\n' "${rel}" "${why}"
    return 0
  fi

  mkdir -p "${CONFLICTS_DIR}/$(dirname "${rel}")" \
    || { echo "reset: cannot stage ${rel}" >&2; exit 1; }
  cp -R "${target}" "${CONFLICTS_DIR}/${rel}" \
    || { echo "reset: could not preserve ${rel}; refusing to remove it" >&2; exit 1; }
  printf '%s\t%s\n' "${rel}" "$(perm_of "${target}")" >> "${CONFLICTS_TSV}"

  rm -rf -- "${target}" || { echo "reset: could not remove ${target}" >&2; exit 1; }
  printf '  removed       %-28s %s\n' "${rel}" "${why}"
  removed=$((removed + 1))
}

# Reported and left alone. These are not mistakes.
note() {
  printf '  kept          %-28s %s\n' "$1" "$2"
  noted=$((noted + 1))
}

echo "checking for configuration that overrides this repository"

# --- 1. files that win over a file this repository owns -------------------

# Verified above: this beats ~/.config/git/config outright.
if [ -e "${DEST}/.gitconfig" ]; then
  take '.gitconfig' 'beats .config/git/config'
fi

# --- 2. orphans: applied here once, ignored on this platform now ----------
#
# chezmoi's own answer to "what does this platform skip", asked at run
# time rather than hardcoded. A path it ignores that nevertheless EXISTS
# was almost certainly written by an earlier version of this repository,
# or by an apply on a different platform into a synced home directory.
# Recovery.md calls these out as the case where `status`, `verify` and
# `managed` all report clean while stale configuration sits on disk.
IGNORED="$("${CHEZMOI}" ignored --source="${REPO_DIR}" 2>/dev/null || true)"
if [ -n "${IGNORED}" ]; then
  while IFS= read -r rel; do
    [ -n "${rel}" ] || continue
    case "${rel}" in
      # Only ever paths under $HOME, and never an escape upward.
      /*|..|../*|*/../*|*/..) continue ;;
      # Repository infrastructure, ignored so it never reaches a home
      # directory. It is not an orphan and will not be sitting in one.
      README.md|LICENSE|Makefile|install.sh|.github/*|docs/*|scripts/*|packages/*) continue ;;
    esac
    if [ -e "${DEST}/${rel}" ]; then
      take "${rel}" 'orphan: ignored on this platform'
    fi
  done <<EOF
${IGNORED}
EOF
fi

# --- 3. deliberate divergence, reported and kept --------------------------

# .zshrc sources this by design, last, so it wins on purpose.
[ -e "${DEST}/.zshrc.local" ] && note '.zshrc.local' 'your escape hatch, sourced last'

# The git config includes this last for the same reason.
[ -e "${DEST}/.config/git/config.local" ] \
  && note '.config/git/config.local' 'your escape hatch, included last'

# Nothing to delete, but it explains "none of my configuration loaded":
# a login shell that is not zsh never reads any of it.
if [ -n "${SHELL:-}" ]; then
  case "${SHELL}" in
    */zsh) ;;
    *) printf '  note          %-28s %s\n' "login shell" \
         "${SHELL} is not zsh; the zsh configuration will not load" ;;
  esac
fi

# --- summary --------------------------------------------------------------

if [ "${found}" -eq 0 ]; then
  echo "  nothing overriding this repository was found"
fi

if [ "${MODE}" = "report" ]; then
  if [ "${found}" -gt 0 ]; then
    printf '\n  %s file(s) would be removed. Nothing was changed.\n' "${found}"
    printf '  Bootstrap with --reset to remove them, preserved into the snapshot.\n'
  fi
else
  printf '  %s removed, %s kept\n' "${removed}" "${noted}"
fi

exit 0
