#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2317
#
# THE THREE DIRECTIVES ABOVE, and why they are not a cover-up:
#
#   SC2016 expressions do not expand in single quotes
#   SC2034 variable appears unused
#   SC2317 command appears unreachable
#
# Every assertion in this file is passed to `check` as a SINGLE-QUOTED
# string and evaluated there, so it is expanded at check time rather than
# at definition time. That is the whole point: it lets each assertion be
# printed alongside its result. ShellCheck cannot see through `eval`, so it
# reads the quoting as a mistake and the variables as unused. They are not.
#
# --- Bootstrap and idempotency proof, against a throwaway HOME ---
#
# Runs on macOS, Linux and Windows (under Git Bash), so there is one smoke
# script rather than three that drift apart.
#
# WHAT "CLEAN MACHINE" MEANS HERE, honestly: a throwaway directory, not a
# container. Neither the macOS nor the Windows GitHub runner offers a
# disposable filesystem, and both arrive dirty (the macOS image ships
# Homebrew preinstalled). Anything the bootstrap touches OUTSIDE $HOME is
# therefore not isolated and not clean, which is exactly why package
# installation is stubbed rather than exercised.
#
# BASH 3.2 ONLY.

set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI="${CHEZMOI:-chezmoi}"
SANDBOX="$(mktemp -d)"

pass=0
fail=0
ok()   { pass=$((pass + 1)); printf 'ok   %s\n' "$*"; }
bad()  { fail=$((fail + 1)); printf 'FAIL %s\n' "$*"; }

# The assertion is passed as a SINGLE-QUOTED string and evaluated here, so
# it is expanded at check time rather than at definition time. ShellCheck
# reads that as unexpanded expressions and unused variables; both are
# deliberate, hence the directives at the call sites' scope.
# shellcheck disable=SC2016,SC2034
check(){ if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

cleanup() { rm -rf "${SANDBOX}"; }
trap cleanup EXIT

# NTFS has ACLs rather than POSIX mode bits, and chezmoi's Chmod is a
# documented no-op on Windows, so mode assertions there would fail for a
# reason that is not a defect in this repository. Determined once, up
# front, because several sections need it.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) WINDOWS_HOST=true ;;
  *) WINDOWS_HOST=false ;;
esac

# THE VICTIM FILE MUST BE MANAGED ON EVERY PLATFORM.
#
# This previously used .zshrc, which is correct on macOS and Linux and
# meaningless on Windows: .chezmoiignore excludes the whole zsh set there,
# so chezmoi rightly never touches it. Four assertions were therefore
# testing a file the tool is supposed to leave alone, and several others
# passed vacuously for the same reason. .config/git/config is managed on
# all three, so the same assertions now mean the same thing everywhere.
VICTIM='.config/git/config'
# Managed everywhere and absent on a clean machine, so apply creates it.
# That is what proves restore DELETES rather than merely overwrites.
CREATED='.config/bat/config'

export HOME="${SANDBOX}/home"
export USERPROFILE="${HOME}"   # Windows equivalent, so one script covers both
mkdir -p "${HOME}" "${SANDBOX}/cfg" "${SANDBOX}/cache"

cm() {
  "${CHEZMOI}" --source="${REPO_DIR}/home" --destination="${HOME}" \
    --config="${SANDBOX}/cfg/chezmoi.toml" --cache="${SANDBOX}/cache" "$@"
}

# --- 0. the isolation assertion, before anything else ----------------------
# If this is wrong, every later check is operating on a real home directory.
case "${HOME}" in
  "${SANDBOX}"/*) ok "HOME is inside the sandbox" ;;
  *) bad "HOME is NOT inside the sandbox: ${HOME}"; exit 1 ;;
esac

command -v "${CHEZMOI}" >/dev/null 2>&1 || { echo "chezmoi not on PATH" >&2; exit 127; }

# --- 1. a machine that already has config ---------------------------------
# The realistic case, and the one chezmoi handles worst: apply overwrites a
# pre-existing file silently, unattended, at exit 0.
mkdir -p "$(dirname "${HOME}/${VICTIM}")"
printf 'PRE-EXISTING USER CONTENT\n' > "${HOME}/${VICTIM}"
chmod 0640 "${HOME}/${VICTIM}"
mkdir -p "${HOME}/.ssh" && chmod 0700 "${HOME}/.ssh"
printf 'Host preexisting\n' > "${HOME}/.ssh/config"
chmod 0600 "${HOME}/.ssh/config"

check "init --promptDefaults exits 0" \
  'cm init --promptDefaults --no-tty </dev/null'
check "a config file was generated" \
  '[ -f "${SANDBOX}/cfg/chezmoi.toml" ]'
# Guards the worst everyday-use bug found in review: without a persisted
# sourceDir, every bare chezmoi command after bootstrap resolves an EMPTY
# default source, and verify reports clean forever.
check "generated config persists sourceDir" \
  'grep -q "^sourceDir = " "${SANDBOX}/cfg/chezmoi.toml"'

# --- 2. the backup, before any apply ---------------------------------------
BACKUP="${SANDBOX}/backup"
check "backup-targets.sh succeeds" \
  '"${REPO_DIR}/scripts/backup-targets.sh" "${CHEZMOI}" "${REPO_DIR}" "${BACKUP}"'
check "backup recorded a manifest" \
  '[ -s "${BACKUP}/manifest.tsv" ]'
check "manifest records the pre-existing file" \
  'grep -q "^file	${VICTIM}	" "${BACKUP}/manifest.tsv"'
check "manifest records an absent target so restore can delete it" \
  'grep -q "^absent	${CREATED}	" "${BACKUP}/manifest.tsv"'
# Guards the Windows path bug directly: with absolute paths every row fell
# through to `external`, the archive captured nothing, and the whole thing
# still exited 0.
check "manifest has no unresolvable 'external' rows" \
  '! grep -q "^external	" "${BACKUP}/manifest.tsv"'

# --- 3. apply --------------------------------------------------------------
export CI_STUB=1
check "apply exits 0" 'cm apply --force'
check "apply overwrote the pre-existing file (expected, hence the backup)" \
  '! grep -q "PRE-EXISTING USER CONTENT" "${HOME}/${VICTIM}"'
check "every managed target now exists" \
  'cm managed --exclude=scripts,remove --path-style=absolute | while IFS= read -r t; do [ -e "$t" ] || [ -L "$t" ] || exit 1; done'

# --- 4. permissions --------------------------------------------------------
if [ "${WINDOWS_HOST}" = "false" ]; then
  check ".ssh is 0700" \
    '[ "$(stat -c %a "${HOME}/.ssh" 2>/dev/null || stat -f %Lp "${HOME}/.ssh")" = "700" ]'
  check ".ssh/config is 0600" \
    '[ "$(stat -c %a "${HOME}/.ssh/config" 2>/dev/null || stat -f %Lp "${HOME}/.ssh/config")" = "600" ]'
  # ssh refuses to create the ControlPath directory itself, so a missing
  # ~/.ssh/cm makes every multiplexed connection fail with "cannot bind".
  check "ssh multiplexing directory exists" \
    '[ -d "${HOME}/.ssh/cm" ]'
fi

# --- 5. the ssh config's load-bearing ordering -----------------------------
check "IgnoreUnknown is the first directive in ~/.ssh/config" \
  '[ "$(grep -vE "^[[:space:]]*#|^[[:space:]]*$" "${HOME}/.ssh/config" | head -1)" = "IgnoreUnknown UseKeychain" ]'

# --- 6. idempotency --------------------------------------------------------
check "status is empty after apply" '[ -z "$(cm status)" ]'
check "verify exits 0 when clean" 'cm verify'
check "diff is empty when clean" '[ -z "$(cm diff)" ]'
check "second apply exits 0" 'cm apply --force'
check "verify still 0 after a second apply" 'cm verify'

# --- 7. negative control: the checks must be able to FAIL ------------------
printf '\n# hand edit\n' >> "${HOME}/${VICTIM}"
check "verify catches a hand edit" '! cm verify'
check "status reports the drift" '[ -n "$(cm status)" ]'
check "apply repairs the drift" 'cm apply --force && cm verify'

# --- 8. restore round trip -------------------------------------------------
check "restore-backup.sh succeeds" \
  '"${REPO_DIR}/scripts/restore-backup.sh" "${BACKUP}"'
check "restore put the ORIGINAL content back" \
  'grep -q "PRE-EXISTING USER CONTENT" "${HOME}/${VICTIM}"'
if [ "${WINDOWS_HOST}" = "false" ]; then
  check "restore put the original mode back" \
    '[ "$(stat -c %a "${HOME}/${VICTIM}" 2>/dev/null || stat -f %Lp "${HOME}/${VICTIM}")" = "640" ]'
fi
check "restore DELETED a file that apply had created" \
  '[ ! -e "${HOME}/${CREATED}" ]'

# --- 9. provisioning fires once, not twice ---------------------------------
cm apply --force >/dev/null 2>&1
before="$(cm apply --force 2>&1 | grep -c 'would install' || true)"
check "provisioning does not re-run on an unchanged apply" '[ "${before}" = "0" ]'

printf '\n=== %s passed, %s failed ===\n' "${pass}" "${fail}"
[ "${fail}" -eq 0 ] || exit 1
exit 0
