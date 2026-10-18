# ~/.config/zsh/conf.d/10-alien-terminal.zsh — TERMINAL, ON EVERY NEW SHELL
#
# This file is a SYMLINK into the dotfiles repo.  scripts/bootstrap.zsh's
# link step puts it here; its zshrc step puts the one marked block in
# ~/.zshrc that sources this directory.  Editing this file edits the repo,
# which is the point of the whole mirror.
#
# WHAT IT DOES, IN ONE SENTENCE: opens terminal.command when a shell is a
# person sitting at a terminal, and gets out of the way otherwise.  Every
# guard below is one of those "otherwise" cases, and every one of them is a
# case where opening a full-screen surface would take something away from
# whoever started the shell.  A hook like this is the most dangerous file in
# a dotfiles repo -- it runs before anything else and it can lock somebody
# out of their own machine -- so it is written to fail toward a plain prompt
# every single time it is not certain.
#
# AND IT HAS A SWITCH, which is `terminal.hook` in terminal.conf.  Off means
# nothing below runs and a new tab is just a prompt.

# ── not a person at a terminal ──────────────────────────────────────────────
# A script, a `zsh -c`, a pipe, an scp, a `ssh host command`: all of them run
# this file and none of them has anybody to open a surface for.  A surface
# that draws itself into a pipe is a surface that has corrupted somebody's
# output -- which is how a dotfiles repo breaks `scp`, `rsync` and `git push`
# for its owner and takes a week to be blamed for it.
[[ -o interactive ]]                 || return 0
[[ -n "${ZSH_EXECUTION_STRING:-}" ]] && return 0
[[ -t 0 && -t 1 ]]                   || return 0
[[ "${TERM:-dumb}" == dumb ]]        && return 0

# ── somebody else's window ──────────────────────────────────────────────────
# tmux and screen multiply shells inside one tab, and ssh brings its own far
# end: a surface that opened in every pane, or on a machine only reached to
# run one command, is taking windows it was never dealt.  And an editor's
# terminal opens shells to work BESIDE something -- code, a session -- not to
# live in: this would sit over the one thing that window exists to show.
[[ -n "${TMUX:-}${STY:-}${SSH_TTY:-}${SSH_CONNECTION:-}" ]] && return 0
[[ "${TERM_PROGRAM:-}" == (vscode|WarpTerminal|Hyper) ]]    && return 0

# ── already inside the suite ────────────────────────────────────────────────
# ONE TERMINAL PER PROCESS TREE.  A shell opened FROM it -- the prompt [Q]
# hands back, anything the reader spawns while inside -- is a shell they
# asked for, and answering it with the menu again is a room with no way out.
# ALIEN_DOOR is the exported path of terminal.command once it is running:
# the name is older than the rename and is left alone on purpose, because the
# four machines in scripts/suite read it and a variable is a contract.
[[ -n "${ALIEN_DOOR:-}" ]] && return 0

# ── the reader said not to, this once ───────────────────────────────────────
# `ALIEN_NO_TERMINAL=1 zsh` is the one-shell override: a bare prompt now,
# whatever the switch says.  It beats even an `on` switch, for the one shell
# it is set on.  ALIEN_NO_DOOR is the name this had before the rename and is
# still honoured, because somebody's muscle memory is not a thing to break.
[[ -n "${ALIEN_NO_TERMINAL:-}${ALIEN_NO_DOOR:-}" ]] && return 0

# ── a tab TERMINAL is opening right now ─────────────────────────────────────
# The machines are dealt as tabs of TERMINAL's own window, and each one is a
# FRESH INTERACTIVE SHELL: it sources this hook before it runs the `exec
# <machine>` it was opened for.  Nothing in that command's environment is
# visible here, because a tab's shell runs its rc before its command -- so
# without this, every dealt tab would open a menu of its own and the machine
# behind it would never be seen.  The one thing TERMINAL can leave where this
# will find it is a file, so while it is spawning tabs it writes a
# short-lived `dealing` flag holding an expiry.
#
# IT IS EXPIRY AND NOT A DELETE that clears it: a TERMINAL that dies mid-deal
# must not leave every new shell without a way in for ever.
_alien_deal="${XDG_STATE_HOME:-$HOME/.local/state}/alien/dealing"
if [[ -r "$_alien_deal" ]]; then
  _alien_exp="$(<"$_alien_deal")" 2>/dev/null
  _alien_now="$(date +%s 2>/dev/null)"
  if [[ "$_alien_exp" == <-> && "$_alien_now" == <-> ]] && (( _alien_exp > _alien_now )); then
    unset _alien_deal _alien_exp _alien_now
    return 0
  fi
  unset _alien_exp _alien_now
fi
unset _alien_deal

# ── where the repo is, and whether it wants this ────────────────────────────
() {
  # FROM THIS FILE'S OWN RESOLVED PATH, not from a path written into ~/.zshrc
  # at install time: the link is what says where the repo is, and a second
  # copy of that answer is a second thing to go stale when the repo moves.
  #
  # %x IS THE FILE THE LINE IS IN.  %N is the name of the script, the sourced
  # file OR THE FUNCTION -- and inside this anonymous function that is
  # `(anon)`, off which five :h resolve to nothing.  The hook then found no
  # repo, opened nothing, and was a no-op that looked installed.
  local self="${${(%):-%x}:A}" root=''
  root="${ALIEN_REPO:-${self:h:h:h:h:h}}"
  # A path is not a way in until there is something at it.  A copied rather
  # than linked snippet lands here with a root that is not a repo, and the
  # honest answer to that is silence: a shell is not the place to report an
  # installer's mistake.
  [[ -f "$root/terminal.command" && -r "$root/terminal.command" ]] || return 0

  # ── the switch ────────────────────────────────────────────────────────────
  # `terminal.hook` in terminal.conf, and off unless it reads exactly `on`.
  # READ BY EYE HERE, NEVER SOURCED: a config that gets sourced can run
  # anything, and a file that runs on every new shell must not hand another
  # file that authority.  Missing file, missing key, any other value: stand
  # aside.  `door.hook` is the name this had before the rename and still
  # answers, so an older install does not silently stop working.
  local hook=off line conf="$root/terminal.conf"
  if [[ -r "$conf" && -f "$conf" ]]; then
    while IFS= read -r line; do
      line="${line## }"
      [[ "$line" == (terminal|door).hook=* || "$line" == (terminal|door).hook' '* ]] || continue
      line="${line#*hook}"; line="${line## }"; line="${line#=}"; line="${line## }"
      hook="${${line%% *}:l}"
    done < "$conf"
  fi
  [[ "$hook" == on ]] || return 0

  export ALIEN_DOOR=1
  export ALIEN_REPO="$root"
  # THIS WINDOW IS THE HOUSE'S, and only this line can say so.  TERMINAL works
  # out for itself whether Finder opened it -- its launcher is its parent and
  # login stands above that -- but a window THIS opened has the reader's own
  # zsh in between, which is the same shape as one somebody typed at a prompt,
  # and TERMINAL must never take Terminal.app down over one of those.
  export ALIEN_HOUSE=1

  # NOT `exec`.  This is the way IN, not the shell itself: [Q] leaves it and
  # leaves you at the prompt you would have had, in the window you already
  # have.  `exec` would make quitting and closing the window the same act.
  zsh "$root/terminal.command"
}
