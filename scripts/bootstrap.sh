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

# A TTY is the difference between "may prompt" and "must not". CI runners
# and Codespaces provisioning both run without one.
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
# --promptDefaults takes every declared default and asks nothing, which is
# what makes an unattended run possible. An interactive run gets the prompts.
#
# APPLY IS NOT ATOMIC. It writes target by target, so a failure part way
# through leaves a home directory that is part old and part new. `set -e`
# would end the script here with chezmoi's own error and nothing else,
# which is the exact moment somebody needs to be told that a snapshot
# exists and how to use it, rather than having to know to go and read a
# document. Hence the explicit trap rather than letting set -e do it.
log "applying dotfiles"
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
  "${CHEZMOI}" init --apply --source="${REPO_DIR}" || apply_failed "$?"
else
  "${CHEZMOI}" init --apply --source="${REPO_DIR}" --promptDefaults --no-tty </dev/null \
    || apply_failed "$?"
fi

# --- stage 3: report -------------------------------------------------------
log "verifying"
if "${CHEZMOI}" verify --source="${REPO_DIR}"; then
  log "target state matches source state"
else
  warn "drift reported by 'chezmoi verify'; run 'chezmoi diff' to inspect"
fi

cat <<EOF

  Bootstrap complete.

  Backup of everything that existed beforehand:
    ${BACKUP_DIR}
  To undo:
    ${REPO_DIR}/scripts/restore-backup.sh ${BACKUP_DIR}

EOF

if [ "${INTERACTIVE}" = "true" ] && [ "${PLATFORM}" = "darwin" ]; then
  cat <<'EOF'
  Remaining steps need a person and are not run automatically:
    scripts/macos-interactive.sh    Terminal.app profile, macOS defaults

EOF
fi
