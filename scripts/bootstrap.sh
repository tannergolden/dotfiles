#!/usr/bin/env bash
# --- Bootstrap: blank machine to working environment ---
#
# Targets macOS, Linux (including a Codespaces container), and Windows via
# the separate scripts/bootstrap.ps1.
#
# BASH 3.2 ONLY. macOS ships bash 3.2.57 (2007) as /bin/bash and will not
# ship a GPLv3 bash. No associative arrays, no `mapfile`, no `${x^^}`, no
# `declare -g`, no namerefs. This is checked by `make lint` under shellcheck.
#
# STAGE 1 IS NOT OPTIONAL. `chezmoi apply` overwrites a pre-existing file
# silently, unattended, at exit 0, with no backup and no undo. It is also
# not atomic: a script that fails mid-apply leaves every target that sorts
# before it already written. The snapshot is the only way back.

set -euo pipefail

CHEZMOI_VERSION="v2.71.1"

# --- --reset ---------------------------------------------------------------
#
# OFF BY DEFAULT, and that is not timidity. Bootstrap runs unattended
# during codespace creation, from a PUBLIC repository, with nobody present
# to read a prompt. A default that deletes unmanaged files in that context
# is indefensible no matter how well chosen the list is.
#
# So every run REPORTS what overrides this repository, and only a run that
# was explicitly asked to will remove any of it. Everything removed is
# preserved into the same snapshot the backup writes, so the ordinary
# restore puts it back.
RESET=false
for _arg in "$@"; do
  case "${_arg}" in
    --reset) RESET=true ;;
    --help|-h)
      cat <<'EOF'
usage: bootstrap.sh [--reset]

  --reset   Also remove configuration that silently overrides this
            repository, such as a ~/.gitconfig that beats
            ~/.config/git/config. Everything removed is preserved into the
            snapshot first and comes back with restore-backup.sh.

Without --reset the conflicts are reported and nothing is removed.
EOF
      exit 0
      ;;
    *) printf 'unknown argument: %s (try --help)\n' "${_arg}" >&2; exit 2 ;;
  esac
done

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${HOME}/.dotfiles-backup-${STAMP}"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror\033[0m %s\n' "$*" >&2; exit 1; }

# --- platform -------------------------------------------------------------
case "$(uname -s)" in
  Darwin) PLATFORM=darwin ;;
  Linux)  PLATFORM=linux  ;;
  *)      die "unsupported platform: $(uname -s). Windows uses scripts/bootstrap.ps1." ;;
esac

# `CODESPACES` is set by the platform and is the documented hook for
# codespace-specific conditionals.
IN_CODESPACES="${CODESPACES:-false}"

# NOTHING PROMPTS EITHER WAY - install is one command with zero input.
# The distinction that remains is mechanical: without a tty, chezmoi gets
# --no-tty and a closed stdin so it cannot even try to open one. CI
# runners and Codespaces provisioning are the without-a-tty case.
if [ -t 0 ] && [ -t 1 ] && [ "${CI:-false}" != "true" ]; then
  INTERACTIVE=true
else
  INTERACTIVE=false
fi

log "platform=${PLATFORM} codespaces=${IN_CODESPACES} interactive=${INTERACTIVE}"

# --- stage 0: chezmoi ------------------------------------------------------
# Pinned and installed to a user-writable prefix. Deliberately NOT
# `sh -c "$(curl -fsLS get.chezmoi.io)"`: that endpoint has a documented
# incident history (expired TLS cert, a PowerShell one-liner broken for
# ~4 weeks after its fix merged, a Defender false-positive on the winget
# package). A pinned artifact fails loudly instead of silently changing.
BIN_DIR="${HOME}/.local/bin"

# Checked before anything is downloaded or written, so an unusable
# environment fails in the first second rather than after a snapshot has
# been taken and half an install has happened.
[ -n "${HOME:-}" ] || die "HOME is unset; refusing to guess where to write"
[ -d "${HOME}" ] || die "HOME (${HOME}) is not a directory"
[ -w "${HOME}" ] || die "HOME (${HOME}) is not writable"
[ -d "${REPO_DIR}/home" ] || die "no source state at ${REPO_DIR}/home; is ${REPO_DIR} the repository root?"
[ -x "${REPO_DIR}/scripts/backup-targets.sh" ] || die "scripts/backup-targets.sh is missing or not executable"
[ -x "${REPO_DIR}/scripts/restore-backup.sh" ] || die "scripts/restore-backup.sh is missing; there would be no way to undo this"

for _tool in curl tar; do
  command -v "${_tool}" >/dev/null 2>&1 || die "${_tool} is required and not on PATH"
done

mkdir -p "${BIN_DIR}" || die "cannot create ${BIN_DIR}"

ensure_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    log "chezmoi present: $(chezmoi --version | head -1)"
    return 0
  fi
  if [ -x "${BIN_DIR}/chezmoi" ]; then
    log "chezmoi present at ${BIN_DIR}/chezmoi"
    return 0
  fi

  local arch
  case "$(uname -m)" in
    x86_64|amd64) arch=amd64 ;;
    arm64|aarch64) arch=arm64 ;;
    *) die "unsupported architecture: $(uname -m)" ;;
  esac

  local ver="${CHEZMOI_VERSION#v}"
  local tarball="chezmoi_${ver}_${PLATFORM}_${arch}.tar.gz"
  local url="https://github.com/twpayne/chezmoi/releases/download/${CHEZMOI_VERSION}/${tarball}"
  local tmp
  tmp="$(mktemp -d)"

  log "installing chezmoi ${CHEZMOI_VERSION} (${PLATFORM}/${arch})"
  curl -fsSL -o "${tmp}/${tarball}" "${url}" \
    || die "could not download ${url}"

  # Verify against the checksums published with the release. This defends
  # against a corrupted or swapped artifact. It does NOT defend against a
  # compromised release process, because the checksum file is served from
  # the same origin. Stated so the guarantee is not overread.
  curl -fsSL -o "${tmp}/checksums.txt" \
    "https://github.com/twpayne/chezmoi/releases/download/${CHEZMOI_VERSION}/chezmoi_${ver}_checksums.txt" \
    || die "could not download checksums"

  # sha256sum is GNU/Linux, shasum is the macOS spelling, and neither is
  # guaranteed on the other. Pick whichever exists rather than assuming.
  if command -v sha256sum >/dev/null 2>&1; then
    ( cd "${tmp}" && grep " ${tarball}\$" checksums.txt | sha256sum -c - ) \
      || die "checksum mismatch for ${tarball}"
  elif command -v shasum >/dev/null 2>&1; then
    ( cd "${tmp}" && grep " ${tarball}\$" checksums.txt | shasum -a 256 -c - ) \
      || die "checksum mismatch for ${tarball}"
  else
    die "no sha256 tool available; refusing to install an unverified binary"
  fi

  tar -xzf "${tmp}/${tarball}" -C "${tmp}" chezmoi
  install -m 0755 "${tmp}/chezmoi" "${BIN_DIR}/chezmoi"
  rm -rf "${tmp}"
  log "chezmoi installed to ${BIN_DIR}/chezmoi"
}

ensure_chezmoi
CHEZMOI="$(command -v chezmoi || echo "${BIN_DIR}/chezmoi")"

# --- stage 0b: Homebrew ----------------------------------------------------
# On a fresh Mac the provisioning script inside `chezmoi apply` finds no
# brew and degrades to "install it and re-run", which is two manual steps.
# Install is one command with zero input, so Homebrew is put in place here,
# BEFORE apply, with its own NONINTERACTIVE mode. The one thing that can
# still stop and ask is sudo wanting your account password - that is
# Apple's gate on writing /opt/homebrew, not a decision this script is
# asking you to make, and there is no legitimate way around it.
if [ "${PLATFORM}" = "darwin" ] && ! command -v brew >/dev/null 2>&1; then
  log "installing Homebrew (sudo may ask for your macOS password once - Apple's gate, not a prompt of ours)"
  if NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    # brew is not on PATH yet in this same process; shellenv fixes that so
    # the provisioning inside apply can find it. Apple Silicon first, then
    # Intel, same order env.sh probes.
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    warn "Homebrew install failed; packages will be skipped until 'chezmoi apply' after you install it"
  fi
fi

# --- stage 0c: SSH keys ----------------------------------------------------
# BEFORE apply, because the git config template gates commit.gpgsign on
# the signing key existing at render time: a key generated now means
# signing is on from the very first apply, instead of after a second one
# somebody has to remember. Skipped in a codespace, which authenticates
# through the platform's own credential helper and signs nothing locally.
if [ "${IN_CODESPACES}" = "false" ]; then
  "${REPO_DIR}/scripts/generate-keys.sh" keys \
    || warn "key generation failed; git works, commits are unsigned"
fi

# --- stage 1: back up every target before anything is written -------------
log "snapshotting existing targets to ${BACKUP_DIR}"
"${REPO_DIR}/scripts/backup-targets.sh" "${CHEZMOI}" "${REPO_DIR}" "${BACKUP_DIR}" \
  || die "backup failed; refusing to apply"

# --- stage 1b: conflicting configuration ----------------------------------
#
# AFTER the snapshot, so nothing is removed that has not already been
# recorded, and BEFORE the apply, so this repository's files land on a
# machine where nothing quietly outranks them.
if [ "${RESET}" = "true" ]; then
  "${REPO_DIR}/scripts/reset-conflicts.sh" "${CHEZMOI}" "${REPO_DIR}" "${BACKUP_DIR}" \
    || die "reset failed; refusing to apply"
else
  # Reported on every run. Knowing that a stray ~/.gitconfig is beating
  # this configuration is worth more than the two lines it costs, and
  # finding it out later is how an afternoon disappears.
  "${REPO_DIR}/scripts/reset-conflicts.sh" "${CHEZMOI}" "${REPO_DIR}" \
    || warn "could not check for conflicting configuration"
fi

# --- stage 2: apply --------------------------------------------------------
# --promptDefaults ON EVERY RUN, interactive included. Install is one
# command with zero input, so nothing here may ask; the declared defaults
# ARE this repository owner's identity, which makes them the right answer,
# not a guess. Anyone forking this edits the defaults in
# home/.chezmoi.toml.tmpl, which is also where they are documented.
#
# APPLY IS NOT ATOMIC. It writes target by target, so a failure part way
# through leaves a home directory that is part old and part new. `set -e`
# would end the script here with chezmoi's own error and nothing else,
# which is the exact moment somebody needs to be told that a snapshot
# exists and how to use it, rather than having to know to go and read a
# document. Hence the explicit trap rather than letting set -e do it.
log "applying dotfiles"

# Ctrl-C DURING APPLY LEAVES THE SAME HALF-WRITTEN HOME A FAILURE DOES,
# and it used to leave it silently: the interrupt killed the script before
# any of the messages below, so the one thing worth knowing - that a
# snapshot exists and how to use it - was never printed. Installed only
# now, because before the snapshot succeeded there is nothing to restore.
interrupted() {
  cat >&2 <<EOF

  INTERRUPTED part way through applying.

  chezmoi applies file by file, so this machine is part old and part new.
  Everything that existed beforehand was captured first. To put it back:

    ${REPO_DIR}/scripts/restore-backup.sh ${BACKUP_DIR}

EOF
  exit 130
}
trap interrupted INT TERM

apply_failed() {
  local code="$1"
  cat >&2 <<EOF

  APPLY FAILED with exit code ${code}.

  chezmoi applies file by file, so this machine is part old and part new.
  Everything that existed beforehand was captured first. To put it back:

    ${REPO_DIR}/scripts/restore-backup.sh ${BACKUP_DIR}

EOF
  exit "${code}"
}

if [ "${INTERACTIVE}" = "true" ]; then
  "${CHEZMOI}" init --apply --source="${REPO_DIR}" --promptDefaults \
    || apply_failed "$?"
else
  "${CHEZMOI}" init --apply --source="${REPO_DIR}" --promptDefaults --no-tty </dev/null \
    || apply_failed "$?"
fi

# Past the non-atomic window: an interrupt from here on costs nothing
# that needs restoring.
trap - INT TERM

# --- stage 3: verify --------------------------------------------------------
log "verifying"
if "${CHEZMOI}" verify --source="${REPO_DIR}"; then
  log "target state matches source state"
else
  warn "drift reported by 'chezmoi verify'; run 'chezmoi diff' to inspect"
fi

# --- stage 4: the signing trust list ---------------------------------------
# AFTER apply, because allowed_signers is a `create_` target that does not
# exist until apply has run once. The email comes from the chezmoi data the
# init above just persisted, so the trust entry matches the commit identity
# without asking anyone anything.
if [ "${IN_CODESPACES}" = "false" ]; then
  IDENTITY_EMAIL="$("${CHEZMOI}" execute-template '{{ .email }}' 2>/dev/null || true)"
  if [ -n "${IDENTITY_EMAIL}" ]; then
    "${REPO_DIR}/scripts/generate-keys.sh" trust "${IDENTITY_EMAIL}" \
      || warn "could not update allowed_signers; local signature verification stays off"
  else
    warn "could not read the commit email from chezmoi data; allowed_signers not updated"
  fi
fi

# --- stage 5: register the keys on GitHub, when a credential exists --------
# The one genuinely manual step left is telling GitHub about the new public
# keys, because that needs a credential no fresh machine holds. But a
# machine that HAS one - gh already logged in - should not hand the job
# back to a person. Best effort, loud on both outcomes, never fatal.
#
# Registration is TWICE PER KEY-USE on purpose: a key added only under
# Authentication signs commits GitHub then shows as Unverified, with no
# error anywhere explaining why.
KEYS_REGISTERED=false
if [ "${IN_CODESPACES}" = "false" ] && [ "${CI:-false}" != "true" ] \
   && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  register_key() { # pubkey-path type title-suffix
    [ -f "$1" ] || return 0
    _blob="$(cut -d' ' -f2 "$1")"
    if gh ssh-key list 2>/dev/null | grep -qF "${_blob}"; then
      log "already on GitHub: $1"
      return 0
    fi
    if gh ssh-key add "$1" --type "$2" --title "$(hostname) $3" 2>/dev/null; then
      log "registered on GitHub ($2): $1"
    else
      warn "could not register $1; if the token lacks scope, run: gh auth refresh -s admin:public_key,admin:ssh_signing_key"
      return 1
    fi
  }
  REG_OK=true
  register_key "${HOME}/.ssh/id_auth_ed25519.pub"    authentication auth || REG_OK=false
  register_key "${HOME}/.ssh/id_signing_ed25519.pub" signing        signing || REG_OK=false
  [ "${REG_OK}" = "true" ] && KEYS_REGISTERED=true
fi

# --- stage 6: macOS defaults and the Terminal profile ----------------------
# Automated rather than pointed at, but only inside a real GUI login
# session: `launchctl managername` says Aqua there and nothing else, which
# keeps this away from ssh sessions and CI runners where `defaults` and
# `open` would write to the wrong place or hang.
MACOS_DEFAULTS_RAN=false
if [ "${PLATFORM}" = "darwin" ] && [ "${CI:-false}" != "true" ] \
   && [ "$(launchctl managername 2>/dev/null || true)" = "Aqua" ]; then
  log "applying macOS defaults and the Terminal profile"
  if "${REPO_DIR}/scripts/macos-defaults.sh"; then
    MACOS_DEFAULTS_RAN=true
  else
    warn "macos-defaults.sh reported errors; re-run it by hand"
  fi
fi

# --- stage 7: a tarball install becomes a clone ----------------------------
# The one-command install fetches a tarball when git is missing (on a
# fresh Mac, invoking the git stub pops a GUI dialog). Provisioning has
# installed a real git by now, so graft history back so `chezmoi update`
# works from here on. Fresh install, so reset --hard forfeits nothing.
if [ "${IN_CODESPACES}" = "false" ] && [ ! -e "${REPO_DIR}/.git" ] \
   && command -v git >/dev/null 2>&1; then
  DOTFILES_REF="${DOTFILES_REF:-Development}"
  log "turning the tarball at ${REPO_DIR} into a git clone (${DOTFILES_REF})"
  if git -C "${REPO_DIR}" init -q -b "${DOTFILES_REF}" \
     && git -C "${REPO_DIR}" remote add origin "https://github.com/tannergolden/dotfiles" \
     && git -C "${REPO_DIR}" fetch -q origin "${DOTFILES_REF}" \
     && git -C "${REPO_DIR}" reset -q --hard "origin/${DOTFILES_REF}" \
     && git -C "${REPO_DIR}" branch -q --set-upstream-to="origin/${DOTFILES_REF}"; then
    log "history restored; future updates are 'chezmoi update'"
  else
    warn "could not graft git history; installs still work, updates need a fresh clone"
  fi
fi

# --- stage 8: report --------------------------------------------------------
cat <<EOF

  Bootstrap complete.

  Backup of everything that existed beforehand:
    ${BACKUP_DIR}
  To undo:
    ${REPO_DIR}/scripts/restore-backup.sh ${BACKUP_DIR}

EOF

if [ "${IN_CODESPACES}" = "false" ] && [ "${KEYS_REGISTERED}" = "false" ] \
   && [ -f "${HOME}/.ssh/id_signing_ed25519.pub" ]; then
  cat <<'EOF'
  One step needs a credential no fresh machine holds - telling GitHub
  about this machine's new public keys. Either sign in once and re-run
  bootstrap, which registers them for you:

    gh auth login

  or paste them yourself at https://github.com/settings/keys:

    ~/.ssh/id_auth_ed25519.pub       as an Authentication key
    ~/.ssh/id_signing_ed25519.pub    as a Signing key (a SEPARATE list)

EOF
fi

if [ "${MACOS_DEFAULTS_RAN}" = "true" ]; then
  cat <<'EOF'
  Quit Terminal completely (Cmd-Q) and reopen it to land in the Pro
  profile. Terminal rewrites its preferences on quit, so a restart is
  what makes the imported profile stick.

EOF
fi
