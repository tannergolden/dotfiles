# shellcheck shell=sh
# --- POSIX environment, shared by every shell that can read it ---
#
# STRICTLY POSIX. Sourced by zsh, by /bin/sh, and potentially by macOS's
# bash 3.2. No arrays, no [[ ]], no `local`, no ${x^^}, no `typeset -U`.
# Those are the zsh and bash 4 constructs that silently break under dash.
#
# This is the ONLY file shared between shells. Aliases, functions, prompt
# and keybindings are deliberately not here: that is where zsh and other
# shells diverge expensively for no benefit.
#
# NOTE: this file cannot reach GUI applications launched from Finder or the
# Dock. Those inherit launchd's environment, not any shell's.

# Idempotent PATH prepend. The case guard means sourcing this file twice
# adds nothing twice, which matters because it is deliberately sourced from
# both .zshenv and .zprofile.
_pathadd() {
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) [ -d "$1" ] && PATH="$1:${PATH}" ;;
    esac
}

# Homebrew, Apple Silicon then Intel. Both are probed rather than assumed
# so one file covers both generations of Mac.
_pathadd "/opt/homebrew/sbin"
_pathadd "/opt/homebrew/bin"
_pathadd "/usr/local/sbin"
_pathadd "/usr/local/bin"
_pathadd "${HOME}/.local/bin"
_pathadd "${HOME}/bin"

export PATH
unset -f _pathadd

# XDG. Exported before anything that reads them.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-${HOME}/.local/state}"

# Editor. `code --wait` blocks correctly for commit messages and rebases.
# The fallback chain matters: a broken VS Code install must not strand you
# without an editor during a merge conflict.
if command -v code >/dev/null 2>&1; then
    export EDITOR="code --wait"
elif command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim"
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim"
else
    export EDITOR="vi"
fi
export VISUAL="${EDITOR}"

# -F quit if one screen, -i smart case, -R pass colour through,
# -X do not clear the screen on exit.
export PAGER="less"
export LESS="-FiRX"
export LESSHISTFILE="-"

# Tool configuration that is genuinely portable across every shell and
# platform, because each tool reads a path from the environment.
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"

export LANG="${LANG:-en_US.UTF-8}"
