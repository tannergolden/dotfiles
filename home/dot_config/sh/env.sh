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

# LOWEST PRIORITY FIRST, because _pathadd PREPENDS: the last call wins.
# Listed Apple-Silicon-first, as it read before, the order came out
# inverted - /usr/local/bin ended up ahead of /opt/homebrew/bin, so on an
# Apple Silicon Mac with any Intel or third-party tool in /usr/local, that
# copy shadowed the Homebrew one this repository installs. Both prefixes
# are probed rather than assumed, so one file still covers both
# generations of Mac and Linux, where neither exists.
_pathadd "/usr/local/sbin"
_pathadd "/usr/local/bin"
_pathadd "/opt/homebrew/sbin"
_pathadd "/opt/homebrew/bin"
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

# Man pages through bat, which gives them the same Catppuccin theme as
# every other file this setup renders. `-p` is plain style: a man page
# already has its own headers, and line numbers down the side of one are
# noise. Debian names the binary batcat, so resolve rather than assume -
# man runs this string with sh, where an interactive alias does not
# apply. Left unset when neither exists, so man keeps its own default.
if command -v bat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif command -v batcat >/dev/null 2>&1; then
    export MANPAGER="sh -c 'col -bx | batcat -l man -p'"
fi

# Tool configuration that is genuinely portable across every shell and
# platform, because each tool reads a path from the environment.
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"

# fzf sources files with fd instead of find: it honours .gitignore, skips
# .git, and follows the same rules ripgrep uses, so the three tools agree
# about what "the files" means. Debian installs the binary as fdfind, and
# fzf executes this string with sh, where an interactive alias does not
# apply, so the name must be resolved here rather than aliased.
if command -v fd >/dev/null 2>&1; then
    _fd=fd
elif command -v fdfind >/dev/null 2>&1; then
    _fd=fdfind
else
    _fd=""
fi
if [ -n "${_fd}" ]; then
    export FZF_DEFAULT_COMMAND="${_fd} --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="${FZF_DEFAULT_COMMAND}"
    export FZF_ALT_C_COMMAND="${_fd} --type d --hidden --follow --exclude .git"
fi
unset _fd
# The preview chain degrades: bat, then Debian's batcat, then plain cat.
export FZF_CTRL_T_OPTS="--preview 'bat --color=always {} 2>/dev/null || batcat --color=always {} 2>/dev/null || cat {}'"
# Catppuccin Mocha, from catppuccin/fzf (MIT). Colours only; behaviour
# flags stay out of the environment so a script embedding fzf is not
# surprised by layout options it never asked for.
#
# NO selected-fg/selected-bg/selected-hl HERE, AND THAT IS NOT AN
# OVERSIGHT. Those colour names arrived in fzf 0.55, and fzf REJECTS an
# unknown colour name outright rather than ignoring it: "invalid color
# specification", exit 2, before the finder ever draws. Ubuntu 24.04 -
# what a codespace runs - ships fzf 0.44, so one cosmetic line for
# multi-select made every fzf invocation on that platform fail: bare
# fzf, anything piping into it, and zoxide's `zi`. Verified against the
# real 0.44 binary, both with the line (exit 2) and without it (clean).
# The remaining names are all understood by 0.44 and by current fzf.
export FZF_DEFAULT_OPTS="\
--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
--color=border:#6C7086,label:#CDD6F4"

# Previews for the other two widgets, so all three agree about what a
# result looks like. Ctrl-T's preview is set above; Alt-C changes
# directory, so it previews a listing rather than a file, and Ctrl-R
# recalls long commands that need wrapping rather than truncating.
# eza degrades to ls, which exists everywhere.
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=1 --color=always {} 2>/dev/null || ls -1 {}'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:hidden:wrap --bind '?:toggle-preview'"

# Opt out of Homebrew's analytics before any brew command runs. Documented
# by Homebrew itself as the supported opt-out.
export HOMEBREW_NO_ANALYTICS=1

export LANG="${LANG:-en_US.UTF-8}"
