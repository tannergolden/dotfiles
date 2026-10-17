#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════
# scripts/bootstrap.zsh · the hook, installed · and the tools under it
# ══════════════════════════════════════════════════════════════════════════
# TWO JOBS.  The first: make Terminal.app open TERMINAL.  It links three
# leaves of home/ into ~, appends one marked block to ~/.zshrc, and turns
# the switch on.  Then every new window is the menu, every machine in the
# folder is a keypress from it, and `alien` opens it from any prompt.
#
# The second: PUT THE TOOLS THE MACHINES LEAN ON WHERE THEY CAN REACH THEM.
# INTELLIGENCE's LOCAL page pulls models through ollama and runs them in
# OpenCode; its CONSOLE talks to whatever runner is up; its CLOUD page
# installs CODEX with npm.  None of that is in this folder -- it is what the
# Brewfile at the repo root names -- and a cabinet that says "brew install
# ollama" on a machine with no brew is a cabinet that has stopped short.
# `--tools` runs the Homebrew installer if there is no brew, then `brew
# bundle` on the Brewfile, then starts ollama as a service so the runner is
# up on every login.  It is INTERACTIVE, because Homebrew's own installer
# asks for a password and a RETURN, so TERMINAL steps aside for it (the
# cabinet's surf_handover) rather than reading it as records.
#
# WHAT IT LEAVES TO THE MACHINES: the four cloud agents.  Each one signs in
# on its own account, and INTELLIGENCE's [I] shows the vendor's exact line
# and waits for a Y before it runs it -- once per agent, which is the right
# grain for something that costs money.
#
# THE NAME IS NOT A PREFERENCE, IT IS A REFERENCE.  terminal.command names
# `scripts/bootstrap.zsh` in six places -- the two rows that open it, the two
# tests that decide whether those rows can stand, and the two messages that
# say so when it is missing -- and it opens it two ways:
#
#     run_here scripts/bootstrap.zsh              [N] INSTALL
#     run_here scripts/bootstrap.zsh --on reset   [E] RESET
#
# So `--on` is a STARTING PAGE here and not a switch, whatever it might have
# read like; the switch is `--hook on|off` below.  Anything named otherwise
# is a file the door cannot find, and two rows that grey out with `no
# bootstrap.zsh in this folder`.
#
# WHY zsh AND NOT PYTHON.  The name this file wore first was bootstrap.py,
# and the repo it came from renamed it for the reason that outlives the
# preference: this is the file that has to run on a Mac where NOTHING is
# installed yet.  macOS ships zsh and does not ship python3 -- /usr/bin/python3
# is a stub that offers to download the Command Line Tools -- so an installer
# written in python is an installer that asks for a two-gigabyte download
# before it can put a symlink somewhere.  Everything it does here is `ln`,
# `mkdir` and reading a file by line, which is a shell's own work anyway.
#
# WHAT IT WILL NOT DO.  It will not replace ~/.zshrc, or reorder it, or write
# outside the two marks.  It keeps a copy before it touches it.  It is safe to
# run twice.  --remove puts the file back the way it found it.
#
# ── THE THING THAT MATTERS MOST ────────────────────────────────────────────
# A HOOK THAT OPENS A FULL-SCREEN PROGRAM ON EVERY NEW SHELL CAN LOCK
# SOMEBODY OUT OF THEIR OWN MACHINE.  That is not a dramatic way of putting
# it -- if the surface crashes on start, every window crashes on start, and
# the way to fix it is a shell you can no longer get.  So there are four ways
# out, and they are printed at the end of the install rather than buried:
#
#   ALIEN_NO_TERMINAL=1 zsh    a plain prompt in this window, right now
#   [Q] from the menu          leaves you at the prompt, window intact
#   bootstrap.zsh --hook off   the switch, without uninstalling anything
#   bootstrap.zsh --remove     the block out of ~/.zshrc, links unlinked
#
# ...and the hook itself refuses to open at all in a pipe, in tmux, over ssh,
# in an editor's terminal, or in a shell that is already inside the suite.
# Read scripts/../home/.config/zsh/conf.d/10-alien-terminal.zsh: every guard
# in it is a case where opening a surface would take something away from
# whoever started the shell.
emulate -L zsh
setopt SH_WORD_SPLIT NO_NOMATCH
set -u

REPO="${0:A:h:h}"
# THE NAME, TAKEN WHILE $0 STILL MEANS THE SCRIPT.  zsh sets $0 to the
# FUNCTION's name inside a function, so a `${0:t}` in the ways-out list below
# printed `page_install --hook off` -- an instruction to run something that
# does not exist, in the one place a reader goes when they are locked out.
SELF="${0:t}"
ZRC="${ZDOTDIR:-$HOME}/.zshrc"
CONF="$REPO/terminal.conf"
ZBEG='# >>> ALIEN dotfiles >>>'
ZEND='# <<< ALIEN dotfiles <<<'
CONFD="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/conf.d"

# THE BLOCK, IN ONE PLACE.  The step that writes it and the step that removes
# it read the same array, so they cannot drift apart.
#
# (N-.) AND NOT (N.) · the leaves standing under ~ are SYMLINKS into the repo,
# and a glob qualifier judges the LINK unless `-` tells it to follow.  `(N.)`
# matched nothing in a linked conf.d, so the block sourced an empty loop and
# nothing ever opened -- an install that looked complete and did nothing.
ZLINES=(
"$ZBEG"
'# Added by scripts/bootstrap.zsh — the ALIEN dotfiles installer.'
'# It sources ~/.config/zsh/conf.d, which this repo fills: one leaf puts'
'# ~/.local/bin on PATH, another opens TERMINAL on a new window when the'
'# terminal.hook switch is on.  Take it out with `bootstrap.zsh --remove`,'
'# or by deleting these lines.'
'if [[ -d "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/conf.d" ]]; then'
'  for _alien_rc in "${XDG_CONFIG_HOME:-$HOME/.config}"/zsh/conf.d/*.zsh(N-.); do'
'    source "$_alien_rc"'
'  done'
'  unset _alien_rc'
'fi'
"$ZEND"
)
LEAVES=('.config/zsh/conf.d/00-alien-path.zsh' '.config/zsh/conf.d/10-alien-terminal.zsh'
        '.local/bin/alien')
BREWFILE="$REPO/Brewfile"
# THE STATE DIRECTORY, MADE HERE ONCE.  The house token, the dealing flag
# and the suite's other short-lived facts live under it; every writer
# already mkdir -p's on the way, but an installer that names the folder is
# an installer whose --remove can say what it left there.
STATED="${XDG_STATE_HOME:-$HOME/.local/state}/alien"

B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; N=$'\033[0m'
[[ -t 1 ]] || { B=''; D=''; G=''; Y=''; R=''; N='' }

# ── SAYING THE SAME THING TWICE, TO TWO DIFFERENT READERS ──────────────────
# THIS FILE HAS TWO SURFACES NOW.  Run from a prompt it is a page of text and
# these four print it.  Opened from TERMINAL's [N] INSTALL it is a page ON
# THE GLASS, and the glass does its own ink -- so `ALIEN_REPORT=1` turns every
# line into `state<TAB>text` and lets the cabinet colour it.
#
# ONE SET OF EMITTERS, NOT TWO PATHS THROUGH THE WORK.  Every step below
# already says what it did through ok/warn/bad/note; teaching those four a
# second way to speak is what puts the whole installer inside the glass
# without a line of it being written twice -- and it is why the two surfaces
# cannot drift apart, because there is only ever one installer.
#
# `print -r` AND A REAL TAB.  -r is raw on purpose -- a path or a filename is
# not a place to be processing escapes -- so `\t` in the string would go out
# as a backslash and a t, and every record would arrive as one field.
typeset -gi RPT=0
[[ -n "${ALIEN_REPORT:-}" ]] && RPT=1
ok()   { (( RPT )) && { print -r -- "ok"$'\t'"$1";   return 0 }; print -r -- "  ${G}·${N} $1" }
warn() { (( RPT )) && { print -r -- "warn"$'\t'"$1"; return 0 }; print -r -- "  ${Y}·${N} $1" }
bad()  { (( RPT )) && { print -r -- "bad"$'\t'"$1";  return 0 }; print -r -- "  ${R}·${N} $1" }
note() { (( RPT )) && { print -r -- "info"$'\t'"$1"; return 0 }; print -r -- "    ${D}$1${N}" }

zrc_has() {   # is the block in ~/.zshrc, and is it whole
  [[ -r "$ZRC" ]] || return 1
  local line; local -i beg=0 end=0
  while IFS= read -r line; do
    [[ "$line" == "$ZBEG" ]] && beg=1
    [[ "$line" == "$ZEND" ]] && end=1
  done < "$ZRC"
  (( beg && end ))
}

conf_hook() {   # -> HOOKV, what the switch currently says
  HOOKV=off
  [[ -r "$CONF" ]] || return 0
  local line
  while IFS= read -r line; do
    line="${line## }"
    [[ "$line" == (terminal|door).hook* ]] || continue
    line="${line#*hook}"; line="${line## }"; line="${line#=}"; line="${line## }"
    HOOKV="${${line%% *}:l}"
  done < "$CONF"
  return 0
}

conf_set() {   # conf_set on|off — the switch, and every other key left alone
  local want="$1" line out='' seen=0
  if [[ -r "$CONF" ]]; then
    while IFS= read -r line; do
      if [[ "${line## }" == (terminal|door).hook* ]]; then
        (( seen )) && continue           # an older duplicate goes
        out+="terminal.hook = $want"$'\n'; seen=1
      else
        out+="$line"$'\n'
      fi
    done < "$CONF"
  fi
  (( seen )) || out+="terminal.hook = $want"$'\n'
  print -rn -- "$out" > "$CONF" || return 1
  return 0
}

# THE CHECKS ALONE, so the glass can ask for the reading without the page
# around it.  do_status is this plus a header and the three hints; TERMINAL's
# [N] INSTALL wants the five lines and draws its own chrome.
do_checks() {
  [[ -f "$REPO/terminal.command" ]] && ok "terminal.command is here" \
                                    || bad "terminal.command is NOT here — wrong folder?"
  if zrc_has; then ok "the block is in ${ZRC/#$HOME/~}"
  else warn "no block in ${ZRC/#$HOME/~}"; fi
  local leaf
  for leaf in "${LEAVES[@]}"; do
    # A LINK IS JUDGED BY WHERE IT POINTS, and -L is the whole test: a link is
    # a link whether or not its far end exists, and a dangling one is exactly
    # the case worth naming rather than skipping past.
    if [[ -L "$HOME/$leaf" ]]; then
      if [[ "$(readlink "$HOME/$leaf" 2>/dev/null)" == "$REPO/home/$leaf" ]]; then
        [[ -r "$HOME/$leaf" ]] && ok "~/$leaf → this repo" \
                              || bad "~/$leaf links here, but nothing is at the far end"
      else
        warn "~/$leaf is a link somewhere else"
      fi
    elif [[ -e "$HOME/$leaf" ]]; then warn "~/$leaf is a real file, not a link"
    else warn "~/$leaf is not there"; fi
  done
  conf_hook
  # THE BOLD IS LEFT OUT OF THE RECORD.  A glass that is handed `${B}on${N}`
  # draws the escape, because a record is text and not a terminal.
  if [[ "$HOOKV" == on ]]; then
    (( RPT )) && ok "the switch is on — a new window opens TERMINAL" \
              || ok "the switch is ${B}on${N} — a new window opens TERMINAL"
  else warn "the switch is off — a new window is just a prompt"; fi
  do_tools_checks
  return 0
}

# ── THE TOOLS · what the machines reach for, and whether it is here ────────
# Read with `whence -p`, which is the same question the machines ask, on the
# same PATH -- so a tool this says is here is a tool INTELLIGENCE will find.
# HOMEBREW'S OWN DIRECTORY IS LOOKED IN TOO: a brew that was just installed
# is at /opt/homebrew/bin whether or not this shell's PATH has caught up,
# and the report should not call it missing for the length of one window.
have() {   # have NAME — on PATH, or in Homebrew's bin
  whence -p "$1" >/dev/null 2>&1 && return 0
  [[ -x "/opt/homebrew/bin/$1" || -x "/usr/local/bin/$1" ]]
}
runner_up() {   # is ollama answering on its port
  (( ${+commands[curl]} )) || return 1
  curl -fsS --max-time 0.4 http://127.0.0.1:11434/api/tags >/dev/null 2>&1
}
do_tools_checks() {
  if have brew; then ok "homebrew is here"
  else warn "no homebrew — the tools below come from it"; fi
  if have ollama; then
    if runner_up; then ok "ollama is here and up — INTELLIGENCE can pull and load models"
    else ok "ollama is here — INTELLIGENCE starts it, or brew services keeps it up"; fi
  else warn "no ollama — LOCAL cannot pull a model without a runner"; fi
  if have llama-server; then ok "llama.cpp is here — a runner for .gguf files"
  else note "no llama.cpp — the other runner, for .gguf files (optional)"; fi
  if have opencode; then ok "opencode is here — ⏎ on a LOCAL model runs it in the glass"
  else warn "no opencode — a pulled model has nothing to run it"; fi
  if have node; then ok "node is here — CODEX installs with npm"
  else warn "no node — CODEX's installer needs npm"; fi
  [[ -r "$BREWFILE" ]] || bad "no Brewfile at the repo root — the tools phase has nothing to read"
  return 0
}

# ── THE PLAN · the exact lines --tools would run, as records for the gate ──
# Nothing here runs.  The glass shows these under a question and waits for
# a Y, which is the same contract every gate in the suite keeps: the line
# on the glass IS the line that runs.
HOMEBREW_LINE='/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
do_plan() {
  local -i n=0
  if ! have brew; then note "$HOMEBREW_LINE"; (( n++ )); fi
  if [[ -r "$BREWFILE" ]] && ! brew_bundle_done; then
    note "brew bundle --file=\"${BREWFILE/#$HOME/~}\""; (( n++ ))
  fi
  if have ollama || [[ -r "$BREWFILE" ]]; then
    runner_service_on || { note "brew services start ollama"; (( n++ )) }
  fi
  (( n )) || ok "every tool is already here — nothing to run"
  return 0
}
brew_bundle_done() {   # every formula in the Brewfile is on this machine
  have brew || return 1
  have ollama && have llama-server && have opencode && have node
}
runner_service_on() {   # is ollama registered to start at login
  local f
  for f in "$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"; do
    [[ -r "$f" ]] && return 0
  done
  return 1
}

# ── THE TOOLS · run, in the terminal, with the reader watching ─────────────
# INTERACTIVE ON PURPOSE.  Homebrew's installer asks for a password and a
# RETURN; brew bundle prints its progress; none of it should be captured
# and summarised after the fact.  TERMINAL hands this the real terminal
# through surf_handover and comes back when it returns.
do_tools() {
  local rc=0 brew=''
  print -r -- ''
  print -r -- "${B}ALIEN dotfiles · the tools${N}  ${D}$REPO${N}"
  print -r -- ''
  if ! have brew; then
    print -r -- "  ${B}homebrew is not on this Mac.${N}  Its own installer runs next:"
    print -r -- "    ${D}$HOMEBREW_LINE${N}"
    print -r -- ''
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      print -r -- ''; bad "homebrew's installer stopped — nothing below it was run"; return 1 }
    print -r -- ''
  fi
  # THE BREW THAT WAS JUST INSTALLED, whether or not PATH knows it yet
  for brew in "$(whence -p brew 2>/dev/null)" /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -n "$brew" && -x "$brew" ]] && break
  done
  [[ -n "$brew" && -x "$brew" ]] || { bad "no brew to run the Brewfile with"; return 1 }
  if [[ -r "$BREWFILE" ]]; then
    print -r -- "  ${B}the Brewfile:${N}"
    print -r -- "    ${D}$brew bundle --file=\"${BREWFILE/#$HOME/~}\"${N}"
    print -r -- ''
    "$brew" bundle --file="$BREWFILE" || { print -r -- ''; bad "brew bundle stopped"; rc=1 }
    print -r -- ''
  else
    warn "no Brewfile at the repo root — skipped"
  fi
  if [[ -x "${brew:h}/ollama" ]] || have ollama; then
    if runner_service_on; then ok "ollama already starts at login"
    else
      print -r -- "  ${B}the runner, up on every login:${N}"
      print -r -- "    ${D}$brew services start ollama${N}"
      print -r -- ''
      "$brew" services start ollama && ok "ollama starts at login, on 127.0.0.1:11434" \
                                    || { bad "brew services could not start ollama"; rc=1 }
    fi
  fi
  print -r -- ''
  print -r -- "  ${B}What is here now:${N}"
  do_tools_checks
  print -r -- ''
  print -r -- "  ${D}The four cloud agents are INTELLIGENCE's: [I] on its CLOUD page shows${N}"
  print -r -- "  ${D}each vendor's line and runs it on a Y.  They sign in on your own account.${N}"
  print -r -- ''
  return $rc
}

do_status() {
  print -r -- ''
  print -r -- "${B}ALIEN dotfiles${N}  ${D}$REPO${N}"
  print -r -- ''
  do_checks
  print -r -- ''
  print -r -- "  ${D}--install      link, write the block, switch on · no questions${N}"
  print -r -- "  ${D}--tools        homebrew if it is missing, the Brewfile (ollama · llama.cpp · opencode · node), ollama at login · interactive${N}"
  print -r -- "  ${D}--plan         the exact lines --tools would run, and nothing run${N}"
  print -r -- "  ${D}--hook on|off  the switch only${N}"
  print -r -- "  ${D}--remove       take the hook back out · no questions${N}"
  print -r -- ''
}

do_link() {
  local leaf src dst
  mkdir -p "$CONFD" 2>/dev/null || { bad "cannot make $CONFD"; return 1 }
  mkdir -p "$STATED" 2>/dev/null && ok "${STATED/#$HOME/~} is where the house keeps its token"
  for leaf in "${LEAVES[@]}"; do
    src="$REPO/home/$leaf"; dst="$HOME/$leaf"
    [[ -r "$src" ]] || { bad "$src is missing from the repo"; return 1 }
    mkdir -p "${dst:h}" 2>/dev/null
    if [[ -L "$dst" ]]; then
      [[ "$(readlink "$dst")" == "$src" ]] && { ok "~/$leaf already links here"; continue }
      rm -f "$dst" 2>/dev/null
    elif [[ -e "$dst" ]]; then
      # SOMEBODY ELSE'S FILE IS MOVED ASIDE, NEVER REPLACED.
      mv -f "$dst" "$dst.pre-alien" 2>/dev/null || { bad "cannot move ~/$leaf aside"; return 1 }
      warn "~/$leaf was a real file — kept as $leaf.pre-alien"
    fi
    ln -s "$src" "$dst" 2>/dev/null || { bad "cannot link ~/$leaf"; return 1 }
    ok "~/$leaf → this repo"
  done
  return 0
}

do_zrc() {
  if zrc_has; then ok "the block is already in ${ZRC/#$HOME/~}"; return 0; fi
  # A COPY BEFORE ANYTHING, and it is left behind on purpose: it is the one
  # thing here that could still be wanted after the suite is gone.
  if [[ -e "$ZRC" && ! -e "$ZRC.pre-alien" ]]; then
    cp -p "$ZRC" "$ZRC.pre-alien" 2>/dev/null && ok "kept a copy at ${ZRC/#$HOME/~}.pre-alien"
  fi
  { print -r -- ''; print -rl -- "${ZLINES[@]}" } >> "$ZRC" || { bad "cannot write $ZRC"; return 1 }
  ok "wrote the block to ${ZRC/#$HOME/~}"
  return 0
}

do_unzrc() {
  zrc_has || { warn "no block to remove"; return 0 }
  local line out='' ; local -i inside=0 dropped=0
  while IFS= read -r line; do
    [[ "$line" == "$ZBEG" ]] && { inside=1; dropped=1; continue }
    if (( inside )); then [[ "$line" == "$ZEND" ]] && inside=0; continue; fi
    out+="$line"$'\n'
  done < "$ZRC"
  # the blank line the install put in front of it goes too
  out="${out%$'\n\n'}"$'\n'
  print -rn -- "$out" > "$ZRC" || { bad "cannot write $ZRC"; return 1 }
  (( dropped )) && ok "took the block out of ${ZRC/#$HOME/~}"
  return 0
}

do_unlink() {
  local leaf dst
  for leaf in "${LEAVES[@]}"; do
    dst="$HOME/$leaf"
    [[ -L "$dst" ]] || continue
    [[ "$(readlink "$dst")" == "$REPO/home/$leaf" ]] || continue
    rm -f "$dst" 2>/dev/null && ok "unlinked ~/$leaf"
  done
  return 0
}

# ── ASKING, BECAUSE THE DOOR PROMISED THIS FILE WOULD ─────────────────────
# do_install's comment says "it asks before it does anything, and TERMINAL
# comes back, rescanned, when it is done", and that promise is made to the
# reader by a program that cannot keep it on this file's behalf.  run_here
# has handed the whole terminal over by the time anything here runs, so an
# honest question and a typed answer are exactly what this surface has.
ask() {   # ask QUESTION — 0 for yes, and anything but y is no
  local a
  print -rn -- "  ${B}$1${N} ${D}[y/N]${N} "
  read -r a || a=''
  [[ "${a:l}" == y(es|) ]]
}

page_install() {
  do_status
  ask "Link the leaves, write the block, and switch the hook on?" || {
    print -r -- ''; note 'nothing was changed.'; print -r -- ''; return 0 }
  print -r -- ''
  do_link || return 1
  do_zrc  || return 1
  conf_set on && ok "the switch is on" || { bad "cannot write $CONF"; return 1 }
  print -r -- ''
  print -r -- "  ${B}A new Terminal window will open TERMINAL.${N}"
  print -r -- "  ${D}This window keeps the shell it already has.${N}"
  print -r -- ''
  # ...AND THE TOOLS, ASKED SEPARATELY: the hook is a symlink and a block,
  # the tools are a package manager and a download, and one Y should not
  # cover both.
  if ! brew_bundle_done || ! runner_service_on; then
    print -r -- "  ${B}The tools the machines lean on:${N}"
    do_plan
    print -r -- ''
    if ask "Run those now?"; then print -r -- ''; do_tools || return 1
    else print -r -- ''; note "later: $SELF --tools"; print -r -- ''; fi
  fi
  print -r -- "  ${B}Ways out, and they all work:${N}"
  print -r -- "    ${D}ALIEN_NO_TERMINAL=1 zsh${N}     a plain prompt, right now"
  print -r -- "    ${D}[Q] from the menu${N}           back to this prompt, window kept"
  print -r -- "    ${D}$SELF --hook off${N}"
  print -r -- "    ${D}$SELF --remove${N}"
  print -r -- ''
  return 0
}

page_reset() {
  do_status
  ask "Take the block out of ~/.zshrc and unlink the leaves?" || {
    print -r -- ''; note 'nothing was changed.'; print -r -- ''; return 0 }
  print -r -- ''
  do_unzrc; do_unlink
  conf_set off >/dev/null 2>&1
  note "~/.zshrc.pre-alien is left where it is — it is yours."
  print -r -- ''
  return 0
}

# ── THE ARGUMENTS ARE THE DOOR'S, AND THEN THIS FILE'S ────────────────────
case "${1:-}" in
  '')            page_install ;;
  --on)
    # a STARTING PAGE · terminal.command's [E] RESET opens this file with
    # `--on reset`, and its [N] INSTALL opens it with nothing at all
    case "${2:-install}" in
      reset)   page_reset ;;
      install) page_install ;;
      *)       print -r -- "unknown page: ${2:-}"; exit 2 ;;
    esac ;;
  --install)     print -r -- ''; do_link && do_zrc && conf_set on && ok "the switch is on"; print -r -- '' ;;
  --remove)      print -r -- ''; do_unzrc; do_unlink; conf_set off >/dev/null 2>&1
                 note "~/.zshrc.pre-alien is left where it is — it is yours."
                 note "ollama, llama.cpp, opencode and node stay — they are homebrew's: brew uninstall <name>"
                 note "so does ollama at login — brew services stop ollama takes it off"
                 print -r -- '' ;;
  # THE TOOLS · interactive, in the terminal · and the plan, as records
  --tools)       do_tools ;;
  --plan)        RPT=1; do_plan ;;
  --hook)
    case "${2:-}" in
      on)  conf_set on  && ok "the switch is on — a new window opens TERMINAL" \
                        || bad "cannot write $CONF" ;;
      off) conf_set off && ok "the switch is off — a new window is just a prompt" \
                        || bad "cannot write $CONF" ;;
      *)   print -r -- "usage: $SELF --hook on|off"; exit 2 ;;
    esac
    print -r -- '' ;;
  --status)      do_status ;;
  # THE GLASS'S OWN WAY IN · records only, no page around them
  --report)      RPT=1; do_checks ;;
  *) print -r -- "usage: $SELF [--on install|reset] [--install] [--tools] [--plan] [--remove] [--hook on|off] [--status] [--report]"
     exit 2 ;;
esac
