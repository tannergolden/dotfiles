#!/bin/sh
# --- The one command: `sh -c "$(curl -fsSL .../install.sh)"` ---
#
# THIS FILE HAS TWO LIVES, decided by one test below.
#
#   1. DISPATCHER. Codespaces clones this repository and runs the first of
#      install.sh, install, bootstrap.sh, ... it finds at the repository
#      root. The name and location are fixed by the platform, exactly like
#      `.gitignore`. When the repository is already on disk around this
#      file, it execs scripts/bootstrap.sh and adds nothing.
#
#   2. FETCHER. Piped from curl there is no repository around it - $0 is
#      "sh" or a /dev/fd path - so it puts the repository at ~/.dotfiles
#      first, then execs the same bootstrap. This is what makes install a
#      single command on a machine that has nothing yet.
#
# POSIX sh, not bash. A Codespaces base image is not guaranteed to have
# bash on a fixed path, and in fetcher mode this runs before anything has
# been provisioned at all.
#
# WHY THE FETCHER PREFERS A TARBALL OVER git ON A FRESH MAC. On macOS
# `git` is a stub until the Xcode Command Line Tools are installed, and
# invoking it pops a GUI install dialog - a manual step, which is exactly
# what this file exists to remove. `curl` and `tar` are real binaries on
# every macOS and every Codespaces image. So: git when it is genuinely
# present, tarball otherwise, and bootstrap turns the tarball into a git
# clone afterwards, once provisioning has installed git.

set -eu

REPO_SLUG="tannergolden/dotfiles"
REPO_REF="${DOTFILES_REF:-Development}"
TARGET="${DOTFILES_DIR:-${HOME}/.dotfiles}"

# The two-lives test. dirname of a piped $0 never contains this repository.
SELF_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd || echo /nonexistent)"

if [ -x "${SELF_DIR}/scripts/bootstrap.sh" ]; then
  exec "${SELF_DIR}/scripts/bootstrap.sh" "$@"
fi

# --- fetcher mode ----------------------------------------------------------
echo "==> fetching ${REPO_SLUG}@${REPO_REF} to ${TARGET}"

[ -n "${HOME:-}" ] || { echo "HOME is unset; refusing to guess" >&2; exit 1; }

if [ -e "${TARGET}" ] && [ ! -x "${TARGET}/scripts/bootstrap.sh" ]; then
  echo "error: ${TARGET} exists but is not this repository; move it aside first" >&2
  exit 1
fi

fetch_tarball() {
  # codeload serves the branch as a tarball with a single top directory
  # whose name embeds the ref; --strip-components peels it off so the
  # layout matches a clone.
  _url="https://codeload.github.com/${REPO_SLUG}/tar.gz/refs/heads/${REPO_REF}"
  mkdir -p "${TARGET}"
  curl -fsSL "${_url}" | tar -xz -C "${TARGET}" --strip-components=1
}

if [ -x "${TARGET}/scripts/bootstrap.sh" ]; then
  # Already fetched once. Freshen a git clone; leave a tarball copy as it
  # is rather than half-updating it - bootstrap reports its gitless state.
  if [ -d "${TARGET}/.git" ] && command -v git >/dev/null 2>&1; then
    git -C "${TARGET}" fetch origin "${REPO_REF}" 2>/dev/null \
      && git -C "${TARGET}" checkout -q "${REPO_REF}" 2>/dev/null \
      && git -C "${TARGET}" merge --ff-only "origin/${REPO_REF}" 2>/dev/null \
      || echo "  could not fast-forward ${TARGET}; continuing with what is there" >&2
  fi
elif command -v git >/dev/null 2>&1 \
  && { [ "$(uname -s)" != "Darwin" ] || xcode-select -p >/dev/null 2>&1; }; then
  # Real git: clone, so updates work from day one. The xcode-select probe
  # is what distinguishes macOS's real git from the dialog-popping stub.
  git clone --branch "${REPO_REF}" "https://github.com/${REPO_SLUG}" "${TARGET}"
else
  fetch_tarball
fi

exec "${TARGET}/scripts/bootstrap.sh" "$@"
