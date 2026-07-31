#!/usr/bin/env bash
# --- SSH keys without a person: generation and the signing trust list ---
#
# Called by bootstrap in two phases, because the pieces live on opposite
# sides of `chezmoi apply`:
#
#   generate-keys.sh keys             BEFORE apply. The git config template
#                                     gates commit.gpgsign on the signing
#                                     key existing AT RENDER TIME, so a key
#                                     generated first means signing is on
#                                     from the very first apply, not after
#                                     a second one someone has to remember.
#
#   generate-keys.sh trust <email>    AFTER apply. The allowed_signers file
#                                     is a `create_` target, so it does not
#                                     exist until apply has run once; this
#                                     appends the machine's own signing key
#                                     to it, which is what makes
#                                     `git log --show-signature` verify
#                                     locally instead of silently reporting
#                                     "No signature".
#
# NO PASSPHRASE, STATED RATHER THAN HIDDEN. These keys never leave the
# machine and exist so that a fresh install needs zero manual input. A
# passphrase would reintroduce a prompt on every commit on a machine with
# no agent yet - the exact thing being removed. If you want passphrased
# keys, generate them yourself with the same filenames and this script
# will not touch them: it only ever fills absence.
#
# BASH 3.2 ONLY, same contract as bootstrap.sh.

set -euo pipefail

MODE="${1:-}"

warn() { printf '\033[1;33m warn\033[0m %s\n' "$*" >&2; }
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

command -v ssh-keygen >/dev/null 2>&1 || {
  warn "ssh-keygen not found; skipping key setup (git still works, unsigned)"
  exit 0
}

SSH_DIR="${HOME}/.ssh"

ensure_key() { # path comment
  if [ -f "$1" ]; then
    log "key exists: $1"
    return 0
  fi
  # -N '' is the zero-input contract; -q keeps the randomart out of a log
  # that people scan for errors.
  ssh-keygen -q -t ed25519 -N '' -C "$2" -f "$1" \
    || { warn "could not generate $1; continuing"; return 0; }
  log "generated $1"
}

case "${MODE}" in
  keys)
    # chezmoi will also create ~/.ssh with private_ permissions, but this
    # phase runs first, so the directory must be made safe here: ssh
    # refuses keys in a group-readable directory.
    mkdir -p "${SSH_DIR}"
    chmod 0700 "${SSH_DIR}" 2>/dev/null || true
    ensure_key "${SSH_DIR}/id_auth_ed25519"    "auth"
    ensure_key "${SSH_DIR}/id_signing_ed25519" "signing"
    ;;

  trust)
    EMAIL="${2:-}"
    [ -n "${EMAIL}" ] || { warn "trust: no email given; skipping"; exit 0; }
    PUB="${SSH_DIR}/id_signing_ed25519.pub"
    SIGNERS="${HOME}/.config/git/allowed_signers"
    [ -f "${PUB}" ]     || { warn "no signing key at ${PUB}; skipping trust list"; exit 0; }
    [ -f "${SIGNERS}" ] || { warn "no ${SIGNERS}; run 'chezmoi apply' first"; exit 0; }

    # Fields one and two are the key type and the base64 blob; the comment
    # is deliberately dropped, matching the file's own documented format.
    KEY="$(cut -d' ' -f1,2 "${PUB}")"
    if grep -qF "${KEY}" "${SIGNERS}"; then
      log "signing key already in allowed_signers"
      exit 0
    fi
    # namespaces="git" pins the signature context: a signature made over a
    # file cannot be replayed as a commit signature. See the comments the
    # allowed_signers file itself ships with.
    printf '%s namespaces="git" %s\n' "${EMAIL}" "${KEY}" >> "${SIGNERS}"
    log "added signing key to allowed_signers for ${EMAIL}"
    ;;

  *)
    echo "usage: generate-keys.sh keys | trust <email>" >&2
    exit 2
    ;;
esac
