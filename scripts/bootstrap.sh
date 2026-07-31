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
mkdir -p "${BIN_DIR}"

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

# --- stage 2: apply --------------------------------------------------------
# --promptDefaults takes every declared default and asks nothing, which is
# what makes an unattended run possible. An interactive run gets the prompts.
log "applying dotfiles"
if [ "${INTERACTIVE}" = "true" ]; then
  "${CHEZMOI}" init --apply --source="${REPO_DIR}"
else
  "${CHEZMOI}" init --apply --source="${REPO_DIR}" --promptDefaults --no-tty </dev/null
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
