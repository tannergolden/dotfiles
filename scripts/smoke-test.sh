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
#
# THE CANARY IS THE POINT OF THIS SECTION. Directories the manifest
# recorded as `absent` (~/.config, ~/.local, ~/.ssh on a fresh machine)
# were once removed with `rm -rf`, so anything written into them after
# bootstrap - another app's settings, an ssh key, chezmoi's own state -
# was destroyed by the documented undo. A file placed in one of those
# directories now must survive, and its parent with it.
CANARY_DIR="${HOME}/.config/bat"
CANARY="${CANARY_DIR}/unrelated-user-file"
printf 'written by something else after bootstrap\n' > "${CANARY}"

check "restore-backup.sh succeeds" \
  '"${REPO_DIR}/scripts/restore-backup.sh" "${BACKUP}"'
check "restore KEPT an unrelated file written after bootstrap" \
  '[ -f "${CANARY}" ]'
check "restore kept the directory that file lives in" '[ -d "${CANARY_DIR}" ]'
check "restore put the ORIGINAL content back" \
  'grep -q "PRE-EXISTING USER CONTENT" "${HOME}/${VICTIM}"'
if [ "${WINDOWS_HOST}" = "false" ]; then
  check "restore put the original mode back" \
    '[ "$(stat -c %a "${HOME}/${VICTIM}" 2>/dev/null || stat -f %Lp "${HOME}/${VICTIM}")" = "640" ]'
fi
# Still deleted, canary or not: CREATED is a FILE inside that same kept
# directory, so this proves the fix discriminates by type rather than
# simply having stopped deleting things.
check "restore DELETED a file that apply had created" \
  '[ ! -e "${HOME}/${CREATED}" ]'
rm -f "${CANARY}"

# --- 9. provisioning fires once, not twice ---------------------------------
cm apply --force >/dev/null 2>&1
before="$(cm apply --force 2>&1 | grep -c 'would install' || true)"
check "provisioning does not re-run on an unchanged apply" '[ "${before}" = "0" ]'

# --- 9b. keys without a person ---------------------------------------------
# The zero-input contract: bootstrap generates keys BEFORE apply so the
# git config's signing gate flips on the same machine state, and appends
# the machine's own key to the trust list AFTER apply. Exercised here
# against the sandbox HOME, exactly as bootstrap drives it.
GK="${REPO_DIR}/scripts/generate-keys.sh"

# ASK GIT, NEVER grep. A template chomp once glued the [commit] header
# onto the previous line, so git saw no [commit] section at all and
# commit.gpgsign was UNSET on every platform - nothing was ever signed -
# while `grep gpgsign` matched happily and every text-based check passed.
# A config assertion that does not go through the parser proves nothing.
gitcfg() { git config -f "${HOME}/.config/git/config" --get "$1" 2>/dev/null; }

if command -v git >/dev/null 2>&1; then
  check "git can parse the rendered config at all" \
    'git config -f "${HOME}/.config/git/config" --list >/dev/null'
  check "allowedSignersFile is a clean path, not a glued section header" \
    '[ "$(gitcfg gpg.ssh.allowedSignersFile)" = "~/.config/git/allowed_signers" ]'
  check "commit.verbose reaches the [commit] section" \
    '[ "$(gitcfg commit.verbose)" = "true" ]'
  # Keys git must NOT see, each one a bug this suite has already paid for.
  check "core settings did not land in [delta]" \
    '[ -z "$(gitcfg delta.longpaths)" ] && [ -z "$(gitcfg delta.precomposeUnicode)" ]'
  check "fetch.pruneTags is unset, so unpushed local tags survive a fetch" \
    '[ -z "$(gitcfg fetch.pruneTags)" ]'
fi

if command -v ssh-keygen >/dev/null 2>&1; then
  # Before any key exists, the rendered config must keep signing OFF - a
  # hardcoded true fails every commit on a machine with no key, with a
  # gpg error that says nothing about why.
  check "gpgsign is off while no signing key exists" \
    '[ "$(gitcfg commit.gpgsign)" = "false" ]'

  check "generate-keys.sh keys exits 0" '"${GK}" keys'
  check "auth keypair generated" \
    '[ -f "${HOME}/.ssh/id_auth_ed25519" ] && [ -f "${HOME}/.ssh/id_auth_ed25519.pub" ]'
  check "signing keypair generated" \
    '[ -f "${HOME}/.ssh/id_signing_ed25519" ] && [ -f "${HOME}/.ssh/id_signing_ed25519.pub" ]'

  # It only ever fills absence: a second run must replace nothing, or a
  # re-bootstrap would rotate keys behind their owner's back.
  KEY_BEFORE="$(cat "${HOME}/.ssh/id_signing_ed25519.pub")"
  check "a second keys run exits 0" '"${GK}" keys'
  check "a second keys run replaces nothing" \
    '[ "$(cat "${HOME}/.ssh/id_signing_ed25519.pub")" = "${KEY_BEFORE}" ]'

  # The gate itself: the key now exists, so a re-apply flips signing on.
  # Asserted through git, so a config git cannot see counts as a failure.
  check "re-apply exits 0 with keys present" 'cm apply --force'
  check "commit.gpgsign flipped on by the key existing" \
    '[ "$(gitcfg commit.gpgsign)" = "true" ]'
  check "tag.gpgSign flipped on too" '[ "$(gitcfg tag.gpgSign)" = "true" ]'

  # The trust list: appended once, never twice.
  check "trust append exits 0" '"${GK}" trust "smoke@example.invalid"'
  check "allowed_signers holds the machine key" \
    'grep -q "smoke@example.invalid namespaces=\"git\" ssh-ed25519" "${HOME}/.config/git/allowed_signers"'
  check "a second trust run exits 0" '"${GK}" trust "smoke@example.invalid"'
  check "the trust entry is not duplicated" \
    '[ "$(grep -c "smoke@example.invalid" "${HOME}/.config/git/allowed_signers")" = "1" ]'
else
  ok "ssh-keygen unavailable; key checks skipped (generate-keys.sh degrades the same way)"
fi

# --- 10. the guards themselves must be able to fire ------------------------
#
# EVERY ASSERTION BELOW IS ABOUT A FAILURE PATH, which is the part of a
# backup tool nobody exercises until the day it matters. A guard that has
# never been shown to fire is a guard nobody should trust, so each one is
# driven into its error case here and required to exit non-zero.
#
# These run against throwaway copies, never the snapshot the earlier
# sections depend on.

BK="${REPO_DIR}/scripts/backup-targets.sh"
RS="${REPO_DIR}/scripts/restore-backup.sh"

# --- 10a. backup refuses to destroy an existing snapshot -------------------
check "backup refuses to overwrite an existing snapshot" \
  '! "${BK}" "${CHEZMOI}" "${REPO_DIR}" "${BACKUP}"'

# --- 10b. backup fails loudly when it cannot enumerate ---------------------
# The Windows bug in another shape: a source it cannot read must not
# produce an empty manifest and exit 0.
check "backup fails when the source state cannot be read" \
  '! "${BK}" "${CHEZMOI}" "${SANDBOX}/no-such-repo" "${SANDBOX}/bk-bad"'

# --- 10c. restore rejects a corrupt archive WITHOUT deleting anything ------
#
# The single most important assertion in this file. The old order was
# delete-then-extract, so a corrupt archive was discovered only once the
# files it was meant to replace were already gone.
CORRUPT="${SANDBOX}/bk-corrupt"
mkdir -p "${CORRUPT}"
printf 'file\t.config/git/config\t644\n' > "${CORRUPT}/manifest.tsv"
printf 'absent\t.canary-must-survive\t-\n' >> "${CORRUPT}/manifest.tsv"
printf 'not a gzip stream at all\n' > "${CORRUPT}/targets.tar.gz"
printf 'canary\n' > "${HOME}/.canary-must-survive"
check "restore refuses a corrupt archive" '! "${RS}" "${CORRUPT}"'
check "restore deleted NOTHING when it refused" \
  '[ -f "${HOME}/.canary-must-survive" ]'

# --- 10d. restore rejects a malformed manifest ----------------------------
MALFORMED="${SANDBOX}/bk-malformed"
mkdir -p "${MALFORMED}"
printf 'absent\t.canary-must-survive\n' > "${MALFORMED}/manifest.tsv"
check "restore refuses a manifest with malformed rows" '! "${RS}" "${MALFORMED}"'
check "restore deleted nothing on a malformed manifest" \
  '[ -f "${HOME}/.canary-must-survive" ]'

# --- 10e. restore rejects a path that escapes HOME ------------------------
ESCAPE="${SANDBOX}/bk-escape"
mkdir -p "${ESCAPE}"
printf 'absent\t../escaped\t-\n' > "${ESCAPE}/manifest.tsv"
printf 'canary\n' > "${SANDBOX}/escaped"
check "restore refuses a manifest path containing '..'" '! "${RS}" "${ESCAPE}"'
check "the path outside HOME still exists" '[ -f "${SANDBOX}/escaped" ]'

# --- 10f. a Windows snapshot is named, not silently skipped ---------------
#
# bootstrap.ps1 writes targets.zip. This script reads targets.tar.gz. That
# combination used to report "nothing existed at backup time", delete what
# apply had created, and restore nothing.
WINZIP="${SANDBOX}/bk-winzip"
mkdir -p "${WINZIP}"
printf 'file\t.config/git/config\t644\n' > "${WINZIP}/manifest.tsv"
printf 'absent\t.canary-must-survive\t-\n' >> "${WINZIP}/manifest.tsv"
printf 'PK\n' > "${WINZIP}/targets.zip"
check "restore refuses a Windows snapshot instead of restoring nothing" \
  '! "${RS}" "${WINZIP}"'
# Redirected to a file rather than piped into grep: this script runs under
# `pipefail`, so a pipeline whose FIRST command exits non-zero fails as a
# whole even when grep matches, and restore exiting non-zero is the very
# thing being tested.
check "restore names restore-backup.ps1 when it finds targets.zip" \
  '"${RS}" "${WINZIP}" >"${SANDBOX}/winzip.out" 2>&1; grep -q "restore-backup.ps1" "${SANDBOX}/winzip.out"'
check "restore deleted nothing when it refused the Windows snapshot" \
  '[ -f "${HOME}/.canary-must-survive" ]'

# --- 10g. the Windows undo actually ships ---------------------------------
# The gap above is only closed if the file a POSIX restore points at is
# really in the repository.
check "scripts/restore-backup.ps1 exists" \
  '[ -f "${REPO_DIR}/scripts/restore-backup.ps1" ]'

# --- 10h. a real backup still round-trips after all of that ---------------
# The guards must reject bad input without having made good input harder.
FRESH="${SANDBOX}/bk-fresh"
check "a fresh backup still succeeds" \
  '"${BK}" "${CHEZMOI}" "${REPO_DIR}" "${FRESH}"'
check "the fresh archive is readable" \
  'tar -tzf "${FRESH}/targets.tar.gz" >/dev/null'

rm -f "${HOME}/.canary-must-survive"

# --- 11. --reset removes only what it says, and gives it all back ---------
#
# This is the only thing in the repository that deletes a file it does not
# manage, so it gets the most coverage. Three properties are asserted:
# reporting changes nothing, removal is confined to the documented list,
# and everything removed comes back through the ordinary restore.

RC="${REPO_DIR}/scripts/reset-conflicts.sh"
RHOME="${SANDBOX}/reset-home"
mkdir -p "${RHOME}/.config/git"
# The verified case: this beats .config/git/config outright.
printf '[user]\n\temail = stray@example.com\n' > "${RHOME}/.gitconfig"
# A documented escape hatch, which must survive.
printf '# mine\n' > "${RHOME}/.zshrc.local"
printf '# mine\n' > "${RHOME}/.config/git/config.local"
# An unrelated file, which must never be touched.
printf 'unrelated\n' > "${RHOME}/.bashrc"

check "reset reports the stray .gitconfig" \
  'HOME="${RHOME}" "${RC}" "${CHEZMOI}" "${REPO_DIR}" >"${SANDBOX}/reset.out" 2>&1; grep -q "would remove .*\.gitconfig" "${SANDBOX}/reset.out"'
check "reporting removed NOTHING" '[ -f "${RHOME}/.gitconfig" ]'

RBK="${SANDBOX}/reset-backup"
mkdir -p "${RBK}"
printf 'absent\t.nothing\t-\n' > "${RBK}/manifest.tsv"
check "reset --with-backup succeeds" \
  'HOME="${RHOME}" "${RC}" "${CHEZMOI}" "${REPO_DIR}" "${RBK}"'
check "reset removed the stray .gitconfig" '[ ! -e "${RHOME}/.gitconfig" ]'
check "reset preserved it before removing it" \
  '[ -f "${RBK}/conflicts/.gitconfig" ]'
check "reset recorded it in conflicts.tsv" \
  'grep -q "^\.gitconfig	" "${RBK}/conflicts.tsv"'

# The three that prove the blast radius is bounded.
check "reset KEPT .zshrc.local, a documented escape hatch" \
  '[ -f "${RHOME}/.zshrc.local" ]'
check "reset KEPT .config/git/config.local, the other escape hatch" \
  '[ -f "${RHOME}/.config/git/config.local" ]'
check "reset did not touch an unrelated file" \
  '[ -f "${RHOME}/.bashrc" ]'

check "restore puts back what reset cleared" \
  'HOME="${RHOME}" "${REPO_DIR}/scripts/restore-backup.sh" "${RBK}"'
check "the stray .gitconfig is back, byte for byte" \
  'grep -q "stray@example.com" "${RHOME}/.gitconfig"'

# Removal must never outrun preservation. A backup directory that cannot
# be created has to stop the run with the file still on disk.
#
# The unwritable directory is a path UNDER A REGULAR FILE, not a directory
# with its mode stripped. Mode bits do not stop uid 0, so the mode version
# of this test passed on a CI runner and failed for anyone running the
# suite as root, which makes it a test of the environment rather than of
# the script. mkdir fails with ENOTDIR for everyone.
NOT_A_DIR="${SANDBOX}/reset-blocker"
printf 'this is a file, not a directory\n' > "${NOT_A_DIR}"
check "reset refuses when it cannot preserve" \
  '! HOME="${RHOME}" "${RC}" "${CHEZMOI}" "${REPO_DIR}" "${NOT_A_DIR}/bk"'
check "the file it could not preserve is still there" \
  '[ -f "${RHOME}/.gitconfig" ]'

printf '\n=== %s passed, %s failed ===\n' "${pass}" "${fail}"
[ "${fail}" -eq 0 ] || exit 1
exit 0
