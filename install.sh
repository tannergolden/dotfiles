#!/bin/sh
# --- GitHub Codespaces entrypoint ---
#
# WHY THIS FILE IS AT THE ROOT, breaking the `scripts/` convention.
#
# Codespaces clones this repository into a new container and runs the FIRST
# of these names it finds, at the repository root:
#
#   install.sh, install, bootstrap.sh, bootstrap,
#   script/bootstrap, setup.sh, setup, script/setup
#
# The name and location are fixed by the platform, exactly like `.gitignore`
# or `.editorconfig`. It therefore falls under the platform-fixed exception
# rather than the `scripts/` rule, and it carries no logic of its own: it is
# a dispatcher, so there is nothing here to drift out of step with
# `scripts/bootstrap.sh`, which is the file a human invokes.
#
# POSIX sh, not bash. A Codespaces base image is not guaranteed to have
# bash on a fixed path, and this file must run before anything is provisioned.

set -eu

REPO_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"

exec "${REPO_DIR}/scripts/bootstrap.sh" "$@"
