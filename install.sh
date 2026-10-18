#!/bin/sh
# Set up a new machine or codespace from these dotfiles.
#
# GitHub Codespaces runs this script by itself for a dotfiles repository.
# Each step may fail without stopping the ones after it, so a missing tool
# or an unreachable release never blocks a new codespace from starting.

cd "$(dirname "$0")" || exit 0

# The universal rules for every AI coding agent, from tannergolden/intelligence.
sh agents/home-kit.sh install \
  || printf 'dotfiles: the agent rules were not installed; run make agents to retry\n' >&2

exit 0
