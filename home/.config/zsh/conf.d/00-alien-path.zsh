# ~/.config/zsh/conf.d/00-alien-path.zsh — ~/.local/bin ON PATH · and homebrew's
#
# This file is a SYMLINK into the dotfiles repo.  scripts/bootstrap.zsh's
# link step puts it here; the block it writes to ~/.zshrc sources this
# directory, so this runs on every new shell -- BEFORE 10-alien-terminal.zsh,
# which is what the 00 is for: the suite's other way in is a command, and a
# command that is not on PATH is not a way in.
#
# WHAT IT DOES: puts ~/.local/bin on PATH when it is not already there, and
# Homebrew's own bin when there is a Homebrew and PATH has not heard of it.
# Nothing here is the suite's alone -- ~/.local/bin is the XDG spot for a
# user's own programs and a great many tools expect it on PATH; this repo is
# simply the thing that noticed it was missing.
#
# HOMEBREW'S BIN, BECAUSE THE MACHINES LOOK THERE.  The installer puts
# ollama, llama.cpp and node in with brew, and INTELLIGENCE finds a runner
# the way any shell does: by name, on PATH.  Homebrew's own advice is a
# `brew shellenv` line in ~/.zprofile, and a Mac that has that keeps it --
# this only steps in when the directory exists and nothing has put it on
# PATH, which is exactly the Mac the installer just put Homebrew on.
#
# ONCE, AND ONLY IF MISSING.  zsh's `path` is the PATH array and `typeset -U
# path` keeps it duplicate-free, so prepending a directory already on it is a
# no-op -- but -U is a global setting this file must not assume somebody else
# has turned on, so it checks.
() {
  local bin="${XDG_BIN_HOME:-$HOME/.local/bin}" brew='' d
  # already there?  leave it where it is -- moving it to the front would
  # change which of two same-named programs wins, which is not this file's
  # call to make
  _alien_on_path() { local d; for d in $path; do [[ "$d" == "$1" ]] && return 0; done; return 1 }
  # homebrew first, so that ~/.local/bin lands in front of it below
  for brew in /opt/homebrew/bin /usr/local/bin; do
    [[ -x "$brew/brew" ]] || continue
    _alien_on_path "$brew" || path=("$brew" $path)
    break
  done
  # only a real directory · an entry on PATH that does not exist is a lookup
  # cost on every command for nothing, and a promise the shell cannot keep
  if [[ -d "$bin" ]] && ! _alien_on_path "$bin"; then
    path=("$bin" $path)
  fi
  unfunction _alien_on_path 2>/dev/null
}
