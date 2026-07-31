#!/usr/bin/env bash
# --- macOS defaults and the Terminal profile ---
#
# Run automatically by bootstrap inside a real GUI login session, and
# runnable by hand any time. Deliberately NOT part of `chezmoi apply`:
# everything here either races a running application, needs a logout or a
# Terminal restart to take effect, or opens a window, none of which
# belongs inside an apply that must stay silent and idempotent.
#
# BASH 3.2 ONLY.

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# NOT "Pro", AND THE NAME IS LOAD-BEARING TWICE OVER. Terminal.app ships
# a stock profile called Pro, so the old name collided with it: importing
# a duplicate name makes Terminal register ours as "Pro 2" while
# `defaults write "Default Window Settings" -string "Pro"` selects the
# STOCK one, so the theme never became the default and nothing said so.
# The second reason is detection: `defaults read` prints OpenStep plist,
# where a purely alphanumeric string is UNQUOTED, so the quoted grep
# below could never match "Pro" and every run re-imported. A multi-word
# name is quoted in that output, which makes the check work.
PROFILE_NAME="Catppuccin Mocha"
PROFILE_FILE="${HOME}/.config/terminal/terminal-pro.terminal"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }

[ "$(uname -s)" = "Darwin" ] || { echo "macOS only" >&2; exit 1; }

# --- Terminal.app profile --------------------------------------------------
#
# THE RACE, stated plainly because it decides how this works.
#
# Terminal.app rewrites com.apple.Terminal.plist when it quits, and
# defaults(1) says so itself: "you shouldn't modify the defaults of a
# running application... the application won't see the change and might
# even overwrite the default." On a fresh Mac this script is running INSIDE
# Terminal.app, so a plain `defaults write` of the profile array is racing
# the very process that will overwrite it.
#
# So the profile is IMPORTED by Terminal itself via `open`, which is the
# supported path, and the default-profile keys are set afterwards with a
# restart required to take effect. If it does not stick, quit Terminal
# fully and re-run.

if [ -f "${PROFILE_FILE}" ]; then
  if defaults read com.apple.Terminal "Window Settings" 2>/dev/null \
       | grep -q "\"${PROFILE_NAME}\""; then
    log "Terminal profile '${PROFILE_NAME}' is already imported"
  else
    log "importing Terminal profile '${PROFILE_NAME}' (135x35, Monaco 12)"
    open "${PROFILE_FILE}"
    # Terminal needs a moment to read and register the profile before the
    # defaults below can name it.
    sleep 2
  fi

  log "setting '${PROFILE_NAME}' as the default and startup profile"
  defaults write com.apple.Terminal "Default Window Settings" -string "${PROFILE_NAME}"
  defaults write com.apple.Terminal "Startup Window Settings" -string "${PROFILE_NAME}"

  warn "Quit Terminal.app completely (Cmd-Q) and reopen it for this to take effect."
  warn "If the profile does not stick, Terminal overwrote it on quit. Re-run this script."
else
  warn "profile not found at ${PROFILE_FILE}; run 'chezmoi apply' first"
fi

# --- system defaults -------------------------------------------------------
#
# THIS LIST IS SHORT ON PURPOSE, and it will look under-ambitious next to
# the 200-line macOS scripts in circulation. That is the point.
#
# defaults(1) as shipped is dated 3 November 2003 and documents not one
# preference key. Every key below is reverse engineered folklore, and Apple
# removes them without notice: the application firewall's plist simply
# ceased to exist in Sequoia, and a Tahoe point release killed a widely
# copied appearance toggle within weeks. The best curated corpus available
# has 74 entries of which 16 claim a test against Sequoia and one against
# Tahoe.
#
# So: only settings with a recent corroborated test, each carrying the date
# of that claim, and NOTHING security related. A firewall or screen lock
# setting that silently fails is strictly worse than no setting, because
# you believe you have it. Those belong in a checklist a person reads.

changed_dock=false
changed_finder=false

# Read-compare-write. The payoff is not avoiding a redundant write, it is
# only restarting Dock and Finder when something actually changed, so
# re-running does not blow away every open Finder window.
ensure() { # domain key type value
  local cur want
  cur="$(defaults read "$1" "$2" 2>/dev/null || true)"
  want="$4"
  if [ "$3" = "bool" ]; then
    case "$4" in true|yes|1) want=1 ;; *) want=0 ;; esac
  fi
  if [ "${cur}" != "${want}" ]; then
    defaults write "$1" "$2" "-$3" "$4"
    printf '    set %s %s = %s\n' "$1" "$2" "$4"
    return 0
  fi
  return 1
}

log "applying macOS defaults"

# Dock. All corroborated against a Sequoia test claim dated 2026-02-04.
for setting in \
  "autohide bool true" \
  "autohide-delay float 0" \
  "autohide-time-modifier float 0.5" \
  "show-recents bool false" \
  "mru-spaces bool false"
do
  # shellcheck disable=SC2086  # deliberate word split: "key type value"
  if ensure com.apple.dock ${setting}; then changed_dock=true; fi
done

# Finder. ShowStatusBar and ShowPathbar corroborated on Sequoia
# (2026-02-03); _FXEnableColumnAutoSizing on Tahoe (2026-02-03).
for setting in \
  "ShowStatusBar bool true" \
  "ShowPathbar bool true" \
  "_FXEnableColumnAutoSizing bool true" \
  "AppleShowAllExtensions bool true" \
  "FXEnableExtensionChangeWarning bool false"
do
  # shellcheck disable=SC2086  # deliberate word split: "key type value"
  if ensure com.apple.finder ${setting}; then changed_finder=true; fi
done

# NSGlobalDomain has no daemon to restart. These need a logout, so they are
# grouped separately and reported rather than silently not applied.
needs_logout=false
for setting in \
  "AppleKeyboardUIMode int 2" \
  "NSQuitAlwaysKeepsWindows bool false"
do
  # shellcheck disable=SC2086  # deliberate word split: "key type value"
  if ensure NSGlobalDomain ${setting}; then needs_logout=true; fi
done

# killall is not an apply mechanism, it is a crash: it sends SIGTERM and
# relies on launchd restarting the process, which re-reads preferences on
# the way up. It works for Dock and Finder only because those tolerate it.
# Note killall Finder closes every open Finder window, hence the guard.
if [ "${changed_dock}" = "true" ]; then
  log "restarting Dock"
  killall Dock 2>/dev/null || true
fi
if [ "${changed_finder}" = "true" ]; then
  log "restarting Finder (this closes open Finder windows)"
  killall Finder 2>/dev/null || true
fi
if [ "${needs_logout}" = "true" ]; then
  warn "Some settings apply at login only. Log out and back in for them to take effect."
fi

# Deliberately not restarting cfprefsd. defaults already writes THROUGH it,
# so the write is committed; killing it gains nothing and can disturb other
# processes' pending state.

log "done"
printf '\nStill yours to do by hand, because no script can decide them for\n'
printf 'you: the security settings. See %s/docs/Manual-Setup.md\n\n' "${REPO_DIR}"
