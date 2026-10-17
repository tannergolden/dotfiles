#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════
# scripts/suite/intelligence.zsh · THE AGENT CABINET, on TERMINAL's own glass
# ══════════════════════════════════════════════════════════════════════════
# MODEL IQ-88.  The suite's switchboard for AI command lines: which of them are
# on this machine, which install of each is the one you would actually get,
# what it is signed in as, what model it is set to -- and the local side, where
# a model on your own disk is held in memory by a runner and answers over HTTP.
#
# IT INSTALLS, REMOVES AND REPORTS.  It will not reach for Homebrew and it will
# not install a package of its own accord; that is scripts/bootstrap.zsh's job,
# and every line this file would run is shown before it is run.
#
# ── WHERE AN AGENT RUNS ───────────────────────────────────────────────────
# INSIDE THE PICTURE, like the original: ⏎ on an agent, or on a local model,
# opens it in a terminal exactly the size of the glass, and the cabinet draws
# what comes back.  That terminal -- the pty, the grid, the scrollback, the
# keyboard while the agent has it -- is the cabinet's own (terminal.command,
# SECTION 18b) and this file only says which page to show around it.  The
# one thing still dealt a real tab of the window is a RUNNER ([S] on LOCAL),
# because a session in the glass ends with the cabinet and a runner should
# not.
#
# ── THE PACK CONTRACT ─────────────────────────────────────────────────────
# A machine hands the cabinet five functions and five strings and draws inside
# the rectangle it is given.  The cabinet keeps the walls, the beat, the
# governor and the tube.  This file never writes to the terminal itself.
#
# ── ONE ZSH FACT THIS WHOLE FILE DEPENDS ON ───────────────────────────────
# `${(FLAGS)NAME}` ON A BARE ARRAY NAME EXPANDS ELEMENT ZERO AND NOTHING ELSE.
# Not the array -- element zero.  `${(j:·:)MDL}` is the first model, `${(O)p}`
# is the first pair, `${(@)A:#pat}` is the first element filtered.  Every one
# of those reads as the obvious thing and every one of them is a list quietly
# truncated to its first item, which on a glass full of tables looks like a
# probe that found one of something rather than a bug.  The subscript is what
# makes it the array: `${(j:·:)MDL[@]}`.  A slice (`[0,59]`) or a nested
# expansion counts as a subscript and is already safe.
#
# ITS OWN FURNITURE, ON PURPOSE.  The page vocabulary below (in_panel, in_kv,
# in_row …) is this pack's, not shared with scripts/suite/system.zsh, and that
# is the design rather than an oversight: a page pack is a file somebody else
# could write, and one that reached into another machine's internals would
# break the moment that machine was edited.  The CABINET supplies the
# primitives -- v_text, v_put, cmix, cshade -- and a pack supplies its pages.

# ── the seam · sourced by the door, or run on its own to be looked at ──────
if [[ -z "${PACK_SOURCED:-}" ]] && [[ "${ZSH_EVAL_CONTEXT:-toplevel}" != *:file* ]]; then
  print -r -- 'intelligence.zsh is a page pack for terminal.command.'
  print -r -- 'Open TERMINAL and choose INTELLIGENCE from the menu.'
  exit 0
fi

typeset -gi IN_MOCK=0
[[ -n "${INTELLIGENCE_MOCK:-}${TERMINAL_MOCK:-}" ]] && IN_MOCK=1

# ══════════════════════════════════════════════════════════════════════════
# THE ROSTER · four command lines, because those are the four this is FOR
# ══════════════════════════════════════════════════════════════════════════
# EVERY FIELD IS A QUESTION, NOT AN ANSWER: which binaries to look for and in
# what order, what to ask for a version, which file holds the model setting,
# which variable holds the key, and the exact line that installs it.
#
#   BINS   more than one name, because these tools do not all agree with
#          themselves about what they are called.  The first one on PATH wins,
#          and the row reports THAT path -- so a brew install and a curl
#          install of the same agent can be told apart on the glass.
#   GET    the line that installs it, verbatim, exactly as it is shown on the
#          gate before it is run.  Nothing is assembled behind your back.
#   ASK    the one-shot form, which is what BENCH and REWRITE run.  Empty
#          means the agent has no way to answer a single question and come
#          back, so it is left out of both rather than started and killed.
#
# ADDING AN AGENT IS ADDING A ROW -- for the scan, the table, the bench, the
# gate and the tab.  Two things below this are NOT row-driven and would need a
# line each: in_model and in_auth, which know where these four in particular
# keep their settings and their credentials (a file apiece, in four different
# shapes, and no convention between them), and the local side, which knows
# ollama is the runner with a `ps` and a pull.  A fifth row without those two
# would read `default` and `not signed in` rather than being wrong.
# OPENCODE IS NOT ON THIS ROSTER.  It runs the LOCAL models -- ⏎ on a model
# on the LOCAL page opens it in the glass with that model -- so it is that
# page's, found and named there (in_scan_opencode), and the cloud roster
# stays the four that sign in to somebody's account.
IN_NAME=('CLAUDE CODE' 'ANTIGRAVITY' 'GROK BUILD' 'CODEX')
IN_BINS=('claude' 'agy antigravity' 'grok' 'codex')
IN_HOME=('~/.claude' '~/.antigravitycli' '~/.grok' '~/.codex')
IN_ENVS=('ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN' 'GEMINI_API_KEY GOOGLE_API_KEY' \
         'XAI_API_KEY' 'OPENAI_API_KEY')
IN_GET=('curl -fsSL https://claude.ai/install.sh | bash' \
        'curl -fsSL https://antigravity.google/cli/install.sh | bash' \
        'curl -fsSL https://x.ai/cli/install.sh | bash' \
        'npm install -g @openai/codex')
IN_ASK=('-p' '' '-p' 'exec')
# ...AND HOW EACH IS TOLD WHICH MODEL, when the reader wants one that is not
# its default: claude and codex take a flag in print mode, the other two do
# not, so REWRITE's picker offers those two as they are configured and no
# further.  The aliases are claude's own short names for its three tiers.
IN_MFLAG=('--model' '' '' '-m')
IN_MALIAS=('sonnet opus haiku' '' '' '')
IN_BLURB=("Anthropic's coding agent. Signs in with your own account; an API key is optional." \
          "Google's terminal agent — the Antigravity harness without the editor around it." \
          "xAI's coding agent. Keyed on XAI_API_KEY, and it answers a single prompt with -p." \
          "OpenAI's coding agent. Signs in with ChatGPT, or takes a key.")
typeset -gi IN_N=4

# what the probe fills in, one flat table keyed by row
typeset -gA IA
typeset -gi IN_STEP=0

# ── the local side · a runner holds a model and answers over HTTP ─────────
# THE TEST IS THE SAME FOR ALL FOUR: is the port open, and does the endpoint
# behind it list models?
IN_RNAME=('OLLAMA' 'LLAMA.CPP' 'LM STUDIO' 'MLX')
IN_RBIN=('ollama' 'llama-server' 'lms' 'mlx_lm.server')
IN_RPORT=(11434 8080 1234 8081)
IN_RAPI=('/api/tags' '/v1/models' '/v1/models' '/v1/models')
IN_RGET=('brew install ollama' 'brew install llama.cpp' \
         'brew install --cask lm-studio' 'uv tool install mlx-lm')
typeset -gi IN_RN=4

# ══════════════════════════════════════════════════════════════════════════
# READING THE MACHINE · one agent a tick, never all four at once
# ══════════════════════════════════════════════════════════════════════════
# ASKING A COMMAND LINE ITS VERSION IS A FORK, AND SOME OF THEM TAKE HALF A
# SECOND TO ANSWER.  Four of those on the frame that opens the machine is two
# seconds of frozen picture on the one surface whose subject is what is
# running -- so the scan walks ONE row per tick, the way the monitor walks one
# sampler per frame, and a row that has not been reached yet says `…` rather
# than lying about being empty.
in_env_set() {   # in_env_set NAME... -> IEV the first one that is set, or ''
  IEV=''
  local v
  for v in "$@"; do
    [[ -n "$v" ]] || continue
    [[ -n "${(P)v:-}" ]] && { IEV="$v"; return 0 }
  done
  return 0
}

in_exists() {   # in_exists PATH — with ~ expanded, and mock-aware
  local p="${1/#\~/$HOME}"
  (( IN_MOCK )) && { [[ " $IN_MOCK_FILES " == *" $p "* ]]; return $? }
  [[ -e "$p" ]]
}

# ONE `key = value` OUT OF A TOML, AT THE TOP LEVEL ONLY.  A naive read finds
# the first `model =` ANYWHERE -- including inside a [model_providers.xyz]
# table further down, which is a different setting with the same name.  So it
# stops at the first section header.
in_toml() {   # in_toml FILE KEY -> ITV
  ITV=''
  local f="${1/#\~/$HOME}" k="$2" line v
  [[ -r "$f" ]] || return 0
  while IFS= read -r line; do
    # ALL THE LEADING WHITESPACE, not one space.  `${line## }` strips exactly
    # one, so an indented `  [model_providers.xyz]` did not look like a
    # section header, the loop ran on past it, and the naive read this
    # function exists to prevent came back -- the wrong `model =`, from a
    # table further down that happens to use the same key.
    #
    # A LOOP AND NOT `[[:space:]]##`, because `#` as a repetition operator is
    # EXTENDED_GLOB, which this cabinet deliberately does not set -- so the
    # obvious one-liner is not a pattern here at all, it is the literal
    # characters, and it strips nothing.
    while [[ "$line" == [[:space:]]* ]]; do line="${line#?}"; done
    while [[ "$line" == *[[:space:]] ]]; do line="${line%?}"; done
    [[ "$line" == \[* ]] && break
    [[ "$line" == "$k"[[:space:]]*=* || "$line" == "$k"=* ]] || continue
    v="${line#*=}"; v="${v%%#*}"
    v="${v## }"; v="${v%% }"
    v="${v#\"}"; v="${v%\"}"; v="${v#\'}"; v="${v%\'}"
    [[ -n "$v" ]] && { ITV="$v"; return 0 }
  done < "$f"
  return 0
}

# ONE VALUE OUT OF A JSON CONFIG, without caring how it is nested and without
# a parser.  It is looking for `"key": "value"` and nothing cleverer; a config
# that does not have it answers empty, which is what `default` is for.
in_json() {   # in_json FILE KEY -> IJV
  IJV=''
  local f="${1/#\~/$HOME}" k="$2" t v pre
  local -i n
  [[ -r "$f" ]] || return 0
  # BOUNDED, BECAUSE ONE OF THESE FILES IS NOT.  ~/.claude.json carries a
  # history entry for every project on the machine and is megabytes on a
  # working Mac; `$(<file)` would pull all of it into a shell variable and
  # then run four string removals over the whole thing -- tens of
  # milliseconds, on a row, on a surface with a thirty-frame budget.  Every
  # key this function is asked for lives in the object at the top.
  t="$(head -c 131072 -- "$f" 2>/dev/null </dev/null)" || return 0
  [[ "$t" == *"\"$k\""* ]] || return 0
  # ── THE ONE ZSH PERFORMANCE FACT THIS MACHINE TURNS ON ────────────────
  # `${t#*PAT}` -- NON-GREEDY prefix removal with a leading star -- IS
  # QUADRATIC.  It tries every prefix length from the shortest up and
  # rescans from the start each time.  Measured on this dialect:
  #
  #        4 KB    0.065 s        64 KB   26.9 s
  #       16 KB    1.417 s       128 KB   over a minute
  #
  # Every other form is linear and finishes in milliseconds at 64 KB:
  # `${t##*PAT}`, `${t%PAT*}`, `${t%%PAT*}`, `[[ $t == *PAT* ]]`, a slice.
  #
  # This function reads ~/.claude.json, which on a working Mac is tens or
  # hundreds of kilobytes of accumulated project history -- so `${t#*"$k"}`
  # here was ELEVEN SECONDS of frozen cabinet, per agent row, every time the
  # scan came round.  That is the whole of "INTELLIGENCE is slow".
  #
  # So: the GREEDY SUFFIX form gives everything before the FIRST match, which
  # is linear, and its LENGTH is the offset of the match.  From there a 400
  # character window is plenty for any JSON value, and every step after it
  # runs on 400 bytes instead of 128 kilobytes.
  pre="${t%%\"$k\"*}"
  n=$(( ${#pre} + ${#k} + 2 ))
  v="${t[$n,$(( n + 400 ))]}"
  v="${v#*:}"
  v="${v## }"; v="${v%%,*}"; v="${v%%\}*}"
  v="${v## }"; v="${v%% }"
  v="${v#\"}"; v="${v%\"}"
  [[ "$v" == *'"'* || "$v" == *'{'* ]] && return 0
  IJV="$v"
  return 0
}

# WHICH INSTALL OF THIS AGENT IS THE ONE ON PATH.  Two installs of the same
# agent -- one from brew, one from npm -- is an ordinary thing to end up with,
# and the row about to be opened should say which one it is rather than
# leaving it to `which`.  An unrecognised one falls back to the name of the
# directory ABOVE its bin, which is what a version manager's directory is
# called.
in_from() {   # in_from PATH -> IFR
  local d="${1:h}"
  IFR=''
  case "$d" in
    /usr/bin|/bin|/usr/sbin|/sbin) IFR='system'; return 0 ;;
  esac
  case "$d/" in
    */opt/homebrew/*) IFR='homebrew' ;;
    */.nvm/*)         IFR='nvm' ;;
    */.bun/*)         IFR='bun' ;;
    */.volta/*)       IFR='volta' ;;
    */.cargo/*)       IFR='cargo' ;;
    */.deno/*)        IFR='deno' ;;
    */go/bin/*)       IFR='go' ;;
    */.local/bin/*)   IFR='~/.local/bin' ;;
    */.npm-global/*)  IFR='npm -g' ;;
    */Library/pnpm/*) IFR='pnpm' ;;
    */usr/local/*)    IFR='/usr/local' ;;
  esac
  [[ -n "$IFR" ]] && return 0
  if [[ "${d:t}" == (bin|sbin) ]]; then
    IFR="${${d:h}:t}"
    [[ -n "$IFR" ]] && return 0
  fi
  IFR="${d/#$HOME/~}"
  return 0
}

in_scan_row() {   # in_scan_row I — everything one agent's row says
  local -i i=$1
  local b p v
  IA[$i.here]=0; IA[$i.bin]=''; IA[$i.path]=''; IA[$i.from]=''
  IA[$i.ver]=''; IA[$i.model]=''; IA[$i.auth]='not signed in'
  IA[$i.state]='no'; IA[$i.proof]=''
  # the FIRST name on PATH wins, and the row then reports that path
  for b in ${=IN_BINS[$i]}; do
    if (( IN_MOCK )); then
      [[ " $IN_MOCK_BINS " == *" $b "* ]] || continue
      p="/opt/homebrew/bin/$b"
    else
      p="$(whence -p "$b" 2>/dev/null)" || p=''
      [[ -n "$p" ]] || continue
    fi
    IA[$i.here]=1; IA[$i.bin]="$b"; IA[$i.path]="$p"
    in_from "$p"; IA[$i.from]="$IFR"
    break
  done
  (( ${IA[$i.here]:-0} )) || return 0
  in_ver $i
  in_model $i
  in_auth $i
  return 0
}

# THE VERSION IS THE ONE PLACE THIS MACHINE RUNS A STRANGER'S PROGRAM, and it
# is treated accordingly: once per session per install, on a three second
# leash, and with NO TERMINAL ANYWHERE -- stdout into a pipe, stderr into the
# floor, and stdin from /dev/null.
#
# THE STDIN REDIRECT IS THE IMPORTANT ONE and it was missing.  Every one of
# these agents is an interactive terminal application, and an interactive
# terminal application asks `isatty(0)` before it decides what it is.  With
# the cabinet's own tty on its standard input it could answer `yes`, start
# bringing up its interface -- raw mode, bracketed paste, MOUSE REPORTING --
# and then be killed by the leash three seconds later with none of it turned
# back off.  After that the terminal answers every movement of the mouse with
# a burst of escape sequences, and the cabinet, whose keyboard is that same
# stream, reads them as somebody typing very fast.
#
# With no tty on any of the three, the same program takes its non-interactive
# path: it prints a version and exits.
typeset -gA IN_VER_SEEN
in_ver() {   # in_ver I
  local -i i=$1 asked=0
  local out=''
  if (( IN_MOCK )); then
    IA[$i.ver]="${IN_MOCK_VER[$i]:-}"
    return 0
  fi
  # ONCE PER SESSION, PER INSTALL.  A version does not change while a cabinet
  # is open, and this is the ONE place this machine runs a program it did not
  # write -- so it is the one place worth doing as rarely as it can be done.
  # Keyed on the PATH, so an install or a remove re-asks by itself; [R] clears
  # the whole table.
  if [[ -n "${IN_VER_SEEN[${IA[$i.path]:-}]:-}" ]]; then
    IA[$i.ver]="${IN_VER_SEEN[${IA[$i.path]}]#=}"
    return 0
  fi
  # THE LEASH IS PERL'S ALARM, and it is here because the sentence above it
  # was otherwise a promise the code did not keep: a plain `$(cmd --version)`
  # waits for ever, and an agent that opens a socket before it prints its
  # version -- or one whose install is half-finished -- would hang the whole
  # cabinet on the frame that reached its row.  perl is on every Mac.
  local pth="${IA[$i.path]:-}"
  # ...AND IT HAS USUALLY BEEN ASKED ALREADY (in_pf_start): every install, at
  # once, out of sight, when this machine was started.  Still out, the row
  # reads `…` -- which is true -- and is answered the tick the job lands.
  if (( IN_PF_PID > 0 )) && ! in_pf_poll; then IN_VER_OWED=1; return 0; fi
  if [[ -n "${IN_PF[$pth]+x}" ]]; then
    out="${IN_PF[$pth]}"
  elif (( ${WARMING:-0} )); then
    # NEVER A STRANGER'S PROGRAM IN FRONT OF THE LOADING SCREEN: a version the
    # job did not bring back is asked when the machine is opened, as it was
    IN_VER_OWED=1; return 0
  elif (( ${+commands[perl]} )); then
    asked=1
    # AND setsid, WHICH IS THE ONLY COMPLETE ANSWER.  Redirecting the three
    # standard descriptors is not enough on its own: a process that still has
    # a CONTROLLING TERMINAL can open /dev/tty and write to it whatever its
    # descriptors point at, which is exactly how a half-started interface
    # leaves mouse reporting switched on.  setsid() puts the probe in a
    # session of its own, with no controlling terminal to open.  perl is on
    # every Mac, the eval means a refusal is not fatal, and the alarm still
    # survives the exec.
    out="$( perl -e 'eval { require POSIX; POSIX::setsid() }; alarm shift; exec @ARGV' \
              3 "$pth" --version </dev/null 2>/dev/null | head -n 1 )" || out=''
  else
    asked=1
    # NO PERL, NO LEASH.  It is on every Mac Apple ships, so this branch is
    # for the machine somebody has pared down -- and there it is an unbounded
    # wait rather than a three-second one, which is worth knowing rather than
    # leaving the sentence above reading as an absolute.
    out="$( "$pth" --version </dev/null 2>/dev/null | head -n 1 )" || out=''
  fi
  out="${out//[^[:print:]]/ }"
  out="${out## }"; out="${out%% }"
  # most of them print `name x.y.z (extra)`; the number is what the column is
  local w
  for w in ${=out}; do
    [[ "$w" == <->.<->* || "$w" == v<->.<->* ]] && { out="${w#v}"; break }
  done
  # A PROBE THAT ANSWERED NOTHING IS STILL AN ANSWER.  Left empty, the row
  # drew the `…` of a row the scan had not reached yet, for the whole session.
  [[ -n "$out" ]] || out='—'
  IA[$i.ver]="${out[0,11]}"
  IN_VER_SEEN[$pth]="=${out[0,11]}"
  # ...AND THE TERMINAL IS PUT BACK THE WAY THE CABINET LEFT IT.  See the
  # note above scr_guard in terminal.command: an agent that starts to bring
  # up its own interface before this one kills it can leave mouse reporting
  # switched on, and from then on every twitch of the mouse pours escape
  # sequences into the cabinet's keyboard.
  # (an answer the background job brought back was never on this terminal)
  (( asked )) && (( ${+functions[scr_guard]} )) && scr_guard
  return 0
}

# ── THE VERSIONS, ASKED ALL AT ONCE AND OUT OF SIGHT ───────────────────────
# ONE ROW A TICK WAS THE KINDEST THE FOREGROUND COULD BE, and it was still a
# frozen frame per agent -- the better part of a second for the ones that
# start a whole runtime to print a number -- on the first seconds of the
# page.  So when this machine is started (at power-on, behind the stars, or
# cold when its door is opened first) every install the scan is going to find
# is asked its version AT ONCE, side by side, in a process of its own, on
# exactly the leash in_ver puts on one: perl's alarm, setsid, nothing of the
# cabinet's terminal on any descriptor.  The rows read `…` until the answers
# land, and what lands is what IN_VER_SEEN keeps for the session -- nothing
# is asked twice.
typeset -g  IN_PF_DIR=''          # where the answers are written · '' when none are out
typeset -gi IN_PF_PID=0           # the job asking them
typeset -gi IN_VER_OWED=0         # a row (or opencode) is still waiting for its version
typeset -gF IN_PF_T0=0.0
typeset -gA IN_PF                 # install path → the first line it answered
IN_PF_WAIT=4.0                    # how long the loading screen holds for them
in_pf_start() {
  (( IN_MOCK || IN_PF_PID > 0 )) && return 0
  # NO PERL, NO LEASH -- and an unleashed stranger is not one to start out of
  # sight: in_ver asks in front of the reader, as it always did
  (( ${+commands[perl]} )) || return 0
  in_tmpdir alien-ver || return 0
  IN_PF_DIR="$ITMP"; IN_PF_T0=$EPOCHREALTIME
  local d="$IN_PF_DIR"
  {
    # THE SAME INSTALLS THE SCAN WILL FIND, found the same way: each row's
    # first name on PATH, and opencode where in_scan_opencode looks for it
    local b p
    local -i i k=0
    local -a paths
    local -A asked
    for (( i = 0; i < IN_N; i++ )); do
      for b in ${=IN_BINS[$i]}; do
        p="$(whence -p "$b" 2>/dev/null)" || p=''
        [[ -n "$p" ]] && { paths+=("$p"); break }
      done
    done
    p="$(whence -p opencode 2>/dev/null)" || p=''
    if [[ -z "$p" ]]; then
      for p in /opt/homebrew/bin/opencode /usr/local/bin/opencode "$HOME/.opencode/bin/opencode"; do
        [[ -x "$p" ]] && break
        p=''
      done
    fi
    [[ -n "$p" ]] && paths+=("$p")
    for p in "${paths[@]}"; do
      [[ -n "${asked[$p]:-}" ]] && continue
      asked[$p]=1; (( k++ ))
      print -r -- "$p" > "$d/p.$k"
      perl -e 'eval { require POSIX; POSIX::setsid() }; alarm shift; exec @ARGV' \
        3 "$p" --version </dev/null 2>/dev/null | head -n 1 > "$d/v.$k" &
    done
    wait
    # THE COUNT IS WRITTEN LAST AND MOVED INTO PLACE, so a count that can be
    # read is a set of answers that are all there
    print -r -- "$k" > "$d/n.part" && mv -f "$d/n.part" "$d/n"
  } </dev/null >/dev/null 2>&1 &!
  IN_PF_PID=$!
  return 0
}
in_pf_poll() {   # 0 once the answers are in -- or are not coming · 1 while they are still out
  (( IN_PF_PID > 0 )) || return 0
  local d="$IN_PF_DIR" n p
  local -i j
  if [[ ! -r "$d/n" ]]; then
    # STILL OUT -- unless it went without a word, or has run past any leash
    # it was given (each probe has three seconds, and they run side by side)
    kill -0 $IN_PF_PID 2>/dev/null && (( EPOCHREALTIME - IN_PF_T0 < 8.0 )) && return 1
    [[ -r "$d/n" ]] || { in_pf_end 1; return 0 }
  fi
  n="$(<"$d/n")"
  if [[ "$n" == <-> ]]; then
    for (( j = 1; j <= n; j++ )); do
      [[ -r "$d/p.$j" ]] || continue
      p="$(<"$d/p.$j")"
      [[ -n "$p" ]] || continue
      IN_PF[$p]=''
      [[ -r "$d/v.$j" ]] && IN_PF[$p]="$(<"$d/v.$j")"
    done
  fi
  in_pf_end 0
  return 0
}
in_pf_end() {   # in_pf_end STOP — the job done with, its folder with it · STOP 1 if it may still be running
  (( $1 && IN_PF_PID > 1 )) && in_kill_tree $IN_PF_PID
  IN_PF_PID=0
  [[ -n "$IN_PF_DIR" ]] && in_tmp_drop "$IN_PF_DIR"
  IN_PF_DIR=''
  return 0
}
# EVERY VERSION STILL OWED, ANSWERED NOW: from the job if it brought one back
# (no fork, so all of them at once), and otherwise asked here, ONE STRANGER A
# TICK, the way the sweep always asked them.  1 when it asked one.
in_pf_adopt() {
  local -i i
  local p
  IN_VER_OWED=0
  for (( i = 0; i < IN_N; i++ )); do
    (( ${IA[$i.here]:-0} )) || continue
    [[ -z "${IA[$i.ver]:-}" ]] || continue
    p="${IA[$i.path]:-}"
    if [[ -n "${IN_VER_SEEN[$p]:-}" || -n "${IN_PF[$p]+x}" ]] || (( ${WARMING:-0} )); then
      in_ver $i; continue
    fi
    in_ver $i; IN_VER_OWED=1; return 1
  done
  if [[ -n "$IOC_PATH" && -z "${IN_VER_SEEN[$IOC_PATH]:-}" ]]; then
    if [[ -n "${IN_PF[$IOC_PATH]+x}" ]] || (( ${WARMING:-0} )); then in_scan_opencode
    else in_scan_opencode; return 1; fi
  fi
  return 0
}
# WHAT WAS STARTED FOR THIS MACHINE BEFORE IT WAS EVER OPENED goes down with
# the cabinet -- the job, if it is still out, and the disk walk the loading
# screen's sweep began.  A machine that HAS been opened keeps its own way out
# (intel_leave) for all of that, exactly as before.
typeset -gi IN_OPENED=0
in_warm_exit() {
  local t
  in_pf_end 1
  (( IN_OPENED )) && return 0
  (( IN_DISK_PID > 1 )) && in_kill_tree $IN_DISK_PID
  IN_DISK_PID=0
  for t in "${IN_TMP[@]}"; do
    [[ -n "$t" ]] && rm -rf -- "$t" 2>/dev/null
  done
  IN_TMP=()
  return 0
}
(( ${+functions[pack_at_exit]} )) && pack_at_exit in_warm_exit

in_model() {   # in_model I — whichever of the three places this agent keeps it
  local -i i=$1
  local m=''
  case $i in
    0) in_json '~/.claude/settings.json' model; m="$IJV"
       [[ -n "$m" ]] || { in_env_set ANTHROPIC_MODEL; [[ -n "$IEV" ]] && m="${(P)IEV}" } ;;
    1) in_env_set ANTIGRAVITY_MODEL GEMINI_MODEL; [[ -n "$IEV" ]] && m="${(P)IEV}" ;;
    2) in_toml '~/.grok/config.toml' model; m="$ITV"
       [[ -n "$m" ]] || { in_env_set GROK_MODEL; [[ -n "$IEV" ]] && m="${(P)IEV}" } ;;
    3) in_toml '~/.codex/config.toml' model; m="$ITV"
       [[ -n "$m" ]] || { in_env_set CODEX_MODEL; [[ -n "$IEV" ]] && m="${(P)IEV}" } ;;
  esac
  (( IN_MOCK )) && m="${IN_MOCK_MODEL[$i]:-$m}"
  IA[$i.model]="${m:-default}"
  return 0
}

# SIGNED IN, AND WHAT SAID SO.  Each answers three things: what to call it,
# whether it counts as signed in, and WHICH FILE OR VARIABLE proved it.  The
# third is the one that settles an argument, so it is carried to the KEYS page
# rather than left implicit.
in_auth() {   # in_auth I
  local -i i=$1
  local -a files
  case $i in
    0) # claude signs in with an account far more often than with a key, and
       # the credentials file is the thing that says so
       if in_exists '~/.claude/.credentials.json'; then
         IA[$i.auth]='subscription'; IA[$i.state]='ok'
         IA[$i.proof]='~/.claude/.credentials.json'; return 0
       fi
       in_json '~/.claude.json' oauthAccount
       if [[ -n "$IJV" ]] || { in_exists '~/.claude.json' && grep -q oauthAccount "${HOME}/.claude.json" 2>/dev/null }; then
         IA[$i.auth]='subscription'; IA[$i.state]='ok'; IA[$i.proof]='~/.claude.json'; return 0
       fi
       files=() ;;
    1) files=('~/.antigravitycli' '~/.antigravity') ;;
    2) files=('~/.grok/config.toml' '~/.grok') ;;
    3) files=('~/.codex/auth.json' '~/.codex') ;;
  esac
  local f
  for f in "${files[@]}"; do
    if in_exists "$f"; then
      IA[$i.auth]='signed in'; IA[$i.state]='ok'; IA[$i.proof]="$f"; return 0
    fi
  done
  in_env_set ${=IN_ENVS[$i]}
  if [[ -n "$IEV" ]]; then
    IA[$i.auth]='api key'; IA[$i.state]='ok'; IA[$i.proof]="$IEV"; return 0
  fi
  # the home directory existing but nothing in it proving anything is its own
  # answer: configured, and not usable yet
  if in_exists "${IN_HOME[$i]}"; then
    IA[$i.auth]='configured'; IA[$i.state]='warn'; IA[$i.proof]="${IN_HOME[$i]}"; return 0
  fi
  IA[$i.auth]='not signed in'; IA[$i.state]='no'; IA[$i.proof]=''
  return 0
}

# ── the runners, and what is resident ────────────────────────────────────
typeset -gA IR
in_scan_runner() {   # in_scan_runner I
  local -i i=$1
  local p
  # WHAT IT IS SERVING SURVIVES THE RESCAN, and then in_scan_serving decides.
  # The two run back to back in one tick, so a runner that is still up would
  # otherwise blank its own SERVING cell for the instant between them.
  IR[$i.here]=0; IR[$i.up]=0; IR[$i.path]=''
  [[ -n "${IR[$i.served]:-}" ]] || IR[$i.served]=''
  IR[$i.seen]=1                       # read at least once · the title card's `…` until then
  if (( IN_MOCK )); then
    [[ " $IN_MOCK_BINS " == *" ${IN_RBIN[$i]} "* ]] && { IR[$i.here]=1; IR[$i.path]="/opt/homebrew/bin/${IN_RBIN[$i]}" }
    [[ " $IN_MOCK_PORTS " == *" ${IN_RPORT[$i]} "* ]] && IR[$i.up]=1
    return 0
  fi
  p="$(whence -p "${IN_RBIN[$i]}" 2>/dev/null)" || p=''
  [[ -n "$p" ]] && { IR[$i.here]=1; IR[$i.path]="$p" }
  # THE PORT IS THE QUESTION, NOT THE BINARY.  A runner installed and not
  # started answers nothing, and a runner started from somewhere this cabinet
  # cannot see still answers -- so the test is the socket.
  # ZTCP, WHICH IS ZSH'S OWN AND NOT A FORK.  The obvious fallback here was
  # bash's /dev/tcp, which zsh does not have at all -- so on a Mac without
  # netcat that branch could only ever fail, and every runner would have read
  # `down` however many of them were listening.  A refused connection on
  # loopback comes back at once; there is nothing to time out against.
  if zmodload -F zsh/net/tcp +b:ztcp 2>/dev/null && ztcp 127.0.0.1 ${IN_RPORT[$i]} 2>/dev/null; then
    IR[$i.up]=1
    [[ -n "${REPLY:-}" ]] && ztcp -c $REPLY 2>/dev/null
  elif (( ${+commands[nc]} )); then
    nc -z -G 1 127.0.0.1 ${IN_RPORT[$i]} >/dev/null 2>&1 && IR[$i.up]=1
  fi
  return 0
}

# THE WHOLE MACHINE AT ONCE, WHICH IS WHAT [R] IS.  Deliberately not what the
# opening frame does -- the pump above exists precisely so that opening this
# machine costs one fork rather than a dozen.
in_scan() {   # in_scan — everything, on demand
  local -i i
  for (( i = 0; i < IN_N; i++ )); do in_scan_row $i; done
  for (( i = 0; i < IN_RN; i++ )); do in_scan_runner $i; in_scan_serving $i; done
  in_scan_opencode
  in_scan_models
  in_scan_resident
  in_scan_keys
  in_sample_mach
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# THE LOCAL SIDE · a runner holds a model, and the model costs this machine
# ══════════════════════════════════════════════════════════════════════════
# THIS IS THE PAGE WHERE THIS CABINET AND THE MONITOR ARE OBVIOUSLY THE SAME
# MACHINE.  A cloud agent's price is on somebody's invoice; a local model's
# price is memory, a chip and a fan -- so the numbers on the bottom of this
# page are read the same way SYSTEM reads them, out of sysctl, vm_stat and
# pmset, and the resident figure is the runner's own measured RSS rather than
# the size of the file on disk.  Nothing here is an estimate.
IN_RSTART=('ollama serve' 'llama-server -m <model>.gguf --port 8080' \
           'lms server start' 'mlx_lm.server --port 8081')

# WHERE A .gguf ACTUALLY ENDS UP, which is six places because six different
# tools put it in six different ones.
IN_GGUF_DIRS=('~/models' '~/.cache/llama.cpp' '~/Library/Caches/llama.cpp' \
              '~/.local/share/alien/models' '~/.lmstudio/models' \
              '~/.cache/huggingface/hub')

# ONE JSON LIST OF MODELS, IN BOTH SHAPES AND WITHOUT A PARSER.  ollama
# answers {"models":[{"name":…}]} and everything with an OpenAI-shaped API
# answers {"data":[{"id":…}]}, so the reader looks for the three keys those
# two use and takes whichever one the body actually has.
in_models_from() {   # in_models_from BODY -> MDL
  MDL=()
  local b="$1" rest v k pre win
  local -i n=0 at
  for k in name id model; do
    rest="$b"; MDL=(); n=0
    while [[ "$rest" == *"\"$k\""* ]]; do
      # THE SAME OFFSET-THEN-WINDOW AS in_json, and for the same reason: a
      # runner holding a dozen models answers with a body big enough for
      # `${rest#*PAT}` to cost seconds, once per key, in a loop.
      pre="${rest%%\"$k\"*}"
      at=$(( ${#pre} + ${#k} + 2 ))
      win="${rest[$at,$(( at + 200 ))]}"
      rest="${rest[$at,-1]}"
      win="${win#*:}"
      win="${win## }"
      [[ "$win" == '"'* ]] || continue
      v="${win#\"}"; v="${v%%\"*}"
      [[ -n "$v" ]] || continue
      # the same name under two keys is one model, not two
      [[ " ${MDL[*]} " == *" $v "* ]] && continue
      MDL+=("${v[0,43]}"); (( n++ ))
      (( n >= 24 )) && break
    done
    (( ${#MDL[@]} )) && return 0
  done
  return 0
}

# CURL, WITH A LEASH, AND ONLY AT A PORT THAT ANSWERED.  A runner that is up
# still has to be asked what it is holding, and a runner that is up and WEDGED
# is exactly the case a plain fetch would hang the cabinet on.
in_http() {   # in_http URL -> IHB
  IHB=''
  (( ${+commands[curl]} )) || return 0
  IHB="$(curl -fsS --max-time 1.5 -H 'Accept: application/json' -- "$1" 2>/dev/null </dev/null)" || IHB=''
  return 0
}
in_http_post() {   # in_http_post URL JSON -> IHB · the body goes through a 0600 file, like every request
  IHB=''
  (( ${+commands[curl]} )) || return 0
  in_tmp alien-post || return 0
  local f="$ITMP"
  print -rn -- "$2" > "$f" 2>/dev/null
  IHB="$(curl -fsS --max-time 1.5 -H 'Content-Type: application/json' --data-binary @"$f" -- "$1" 2>/dev/null </dev/null)" || IHB=''
  in_tmp_drop "$f"
  return 0
}
# ONE VALUE OUT OF A JSON BODY BY KEY, the way in_json reads a config: the
# first match, a window after it, and the number or string that follows.
in_body_val() {   # in_body_val BODY KEY -> IBV
  local b="$1" k="$2" pre win
  local -i at
  IBV=''
  [[ "$b" == *"\"$k\""* ]] || return 0
  pre="${b%%\"$k\"*}"
  at=$(( ${#pre} + ${#k} + 2 ))
  win="${b[$at,$(( at + 120 ))]}"
  win="${win#*:}"; win="${win## }"
  if [[ "$win" == '"'* ]]; then win="${win#\"}"; IBV="${win%%\"*}"
  else IBV="${win%%[^0-9.eE+-]*}"; fi
  return 0
}

# ── what each runner is serving ───────────────────────────────────────────
in_scan_serving() {   # in_scan_serving I
  local -i i=$1
  # A RUNNER THAT IS DOWN IS SERVING NOTHING, and one that is up keeps what it
  # had until the fetch says otherwise -- which is the point of the line in
  # in_scan_runner that preserves it, and which this used to undo by clearing
  # unconditionally one tick later.
  (( ${IR[$i.up]:-0} )) || { IR[$i.served]=''; return 0 }
  if (( IN_MOCK )); then
    IR[$i.served]="${IN_MOCK_SERVED[$i]:-}"
    return 0
  fi
  in_http "http://127.0.0.1:${IN_RPORT[$i]}${IN_RAPI[$i]}"
  [[ -n "$IHB" ]] || return 0
  in_models_from "$IHB"
  # `[@]` ON THE NAME, WHICH IS NOT DECORATION -- see the note at the top of
  # this file.  `${(j:…:)MDL}` joins element ZERO to nothing and hands back
  # the first model as though it were the only one it found.
  IR[$i.served]="${(j: · :)MDL[@]}"
  return 0
}

# ── OPENCODE · what runs a local model, and where it is ────────────────────
# FOUND HERE AND NOT ON THE CLOUD ROSTER, because it is the LOCAL page's:
# the four cloud rows sign in to somebody's account, and OpenCode is what a
# pulled model is run in.  Looked for on PATH and in Homebrew's bin -- a
# brew that INSTALL just put in may be off this shell's PATH for the
# length of one window -- and asked its version once, on the same leash
# the roster puts on a stranger's program.
typeset -g IOC_PATH='' IOC_VER=''
# VERSIONS OF OPENCODE THAT FAIL EVERY PROMPT.  1.18.30 ships with a broken
# service graph (anomalyco/opencode #48645, #48803): the TUI opens, the model
# is listed and chosen, and the first prompt answers `Unexpected server
# error` whatever the provider.  A reader who has just pulled a model and
# pressed ⏎ deserves to be told that it is not their model, on the page,
# with the line that fixes it.
IN_OC_BAD=('1.18.30')
IN_OC_GOOD='1.18.20'
in_oc_bad() {   # -> IOCB · 1 if the opencode on this machine is a known-broken one
  local v
  IOCB=0
  [[ -n "$IOC_VER" ]] || return 0
  for v in "${IN_OC_BAD[@]}"; do [[ "$IOC_VER" == "$v" ]] && { IOCB=1; return 0 }; done
  return 0
}
in_scan_opencode() {
  local p out
  if (( IN_MOCK )); then
    if [[ " $IN_MOCK_BINS " == *" opencode "* ]]; then IOC_PATH=/opt/homebrew/bin/opencode; IOC_VER='1.2.0'
    else IOC_PATH=''; IOC_VER=''; fi
    return 0
  fi
  p="$(whence -p opencode 2>/dev/null)" || p=''
  if [[ -z "$p" ]]; then
    for p in /opt/homebrew/bin/opencode /usr/local/bin/opencode "$HOME/.opencode/bin/opencode"; do
      [[ -x "$p" ]] && break
      p=''
    done
  fi
  IOC_PATH="$p"
  [[ -n "$p" ]] || { IOC_VER=''; return 0 }
  if [[ -z "${IN_VER_SEEN[$p]:-}" ]]; then
    # ASKED AHEAD WITH THE ROSTER (in_pf_start), and owed until it lands
    if (( IN_PF_PID > 0 )) && ! in_pf_poll; then IN_VER_OWED=1; IOC_VER=''; return 0; fi
    local -i asked=0
    if [[ -n "${IN_PF[$p]+x}" ]]; then
      out="${IN_PF[$p]}"
    elif (( ${WARMING:-0} )); then
      IN_VER_OWED=1; IOC_VER=''; return 0
    elif (( ${+commands[perl]} )); then
      asked=1
      out="$( perl -e 'eval { require POSIX; POSIX::setsid() }; alarm shift; exec @ARGV' \
                3 "$p" --version </dev/null 2>/dev/null | head -n 1 )" || out=''
    else
      asked=1
      out="$( "$p" --version </dev/null 2>/dev/null | head -n 1 )" || out=''
    fi
    out="${out//[^[:print:]]/ }"; out="${out## }"; out="${out%% }"
    local w
    for w in ${=out}; do
      [[ "$w" == <->.<->* || "$w" == v<->.<->* ]] && { out="${w#v}"; break }
    done
    IN_VER_SEEN[$p]="=${out[0,11]}"
    (( asked )) && (( ${+functions[scr_guard]} )) && scr_guard
  fi
  IOC_VER="${IN_VER_SEEN[$p]#=}"
  return 0
}

# ── every model on this disk that this cabinet can see ────────────────────
typeset -ga IM_NAME IM_WHERE IM_QUANT IM_SIZE IM_PATH
typeset -gi IM_N=0

# THE QUANTISATION IS IN THE FILENAME and nowhere else, which is the one
# genuinely useful thing a .gguf's name carries: it is the difference between
# a model that fits this machine and the same model that does not.
in_quant() {   # in_quant NAME -> IQT
  local s="${1:u}" w
  IQT=''
  for w in ${(s:-:)${s//./-}}; do
    case "$w" in
      Q<->*|IQ<->*|F16|BF16|F32|MLX|<->BIT) IQT="$w"; return 0 ;;
    esac
  done
  return 0
}

in_size_h() {   # in_size_h BYTES -> ISZ, the way a model is talked about
  # THE GUARD IS NOT BELT AND BRACES.  `local -F n=<not a number>` is a failed
  # ASSIGNMENT, and a failed assignment in a non-interactive shell ENDS THE
  # SHELL -- unlike the same bad expression inside (( )), which merely returns
  # non-zero.  So every float fed from parsed text is put through arithmetic
  # that can fail safely before it is allowed to be a float.
  #
  # `, 1` IS WHY THE TEST IS A COMMA EXPRESSION.  `(( n = $1 ))` reports the
  # VALUE as its status, so a legitimate zero reads as a refusal; the comma
  # makes the status mean "did this parse", which is the question.  And a
  # pattern would not have done: zsh prints 3.0 as `3.` and small numbers in
  # scientific notation, so `<->.<->` refuses the shell's own output.
  local -F n=0.0
  (( n = $1, 1 )) 2>/dev/null || { ISZ='?'; return 0 }
  local u
  for u in B KB MB GB TB; do
    if (( n < 1024.0 )) || [[ "$u" == TB ]]; then
      if (( n >= 100.0 )) || [[ "$u" == B || "$u" == KB ]]; then
        printf -v ISZ '%.0f %s' $n "$u"
      else
        printf -v ISZ '%.1f %s' $n "$u"
      fi
      return 0
    fi
    n=$(( n / 1024.0 ))
  done
  ISZ='?'
  return 0
}

# WHAT IS ON THE DISK CHANGES ABOUT ONCE A WEEK, so it is not asked every
# thirty seconds.  The glob has to go four levels down six roots, one of which
# is huggingface's cache -- a hundred milliseconds on a machine with a couple
# of thousand of those directories -- and paying that on the roster's clock
# was a hitch you could feel, twice a minute, for an answer that had not moved
# since the last time.  [R] still asks immediately; so does the first sweep.
typeset -gF IN_DISK_AT=0.0
IN_DISK_EVERY=180.0
IN_DISK_LOG=''
typeset -gi IN_DISK_PID=0

# ...AND IT IS WALKED BESIDE THE PICTURE, NOT IN IT.  Four levels down six
# roots is most of a second on a machine with a couple of thousand model
# directories, and a second is thirty frames -- the whole cabinet stopping
# dead, on a page that is otherwise idle.  So the walk is a background `find`
# like every other slow thing this machine does, and the list is picked up
# whenever it is ready.  `find` also settles the depth question in one flag
# rather than four globs.
in_disk_start() {
  local d
  local -a dirs
  (( IN_DISK_PID > 1 )) && return 0
  dirs=()
  for d in "${IN_GGUF_DIRS[@]}"; do
    d="${d/#\~/$HOME}"
    [[ -d "$d" ]] && dirs+=("$d")
  done
  # NO DIRECTORY IS NO FILES -- NOT NO MODELS.  This cleared the JOINED list,
  # pulled half included, so a Mac with ollama and no ~/models read `no model
  # on this disk that this cabinet can see` under a runner holding six.
  (( ${#dirs[@]} )) || { IM_GG_NAME=(); IM_GG_WHERE=(); IM_GG_QUANT=(); IM_GG_SIZE=(); IM_GG_PATH=()
                         in_models_join; IN_DISK_AT=$IN_NOW; return 0 }
  in_tmp alien-disk || return 1
  IN_DISK_LOG="$ITMP"
  { find "${dirs[@]}" -maxdepth 4 -type f -name '*.gguf' -print
    print -r -- '__END__' } >"$IN_DISK_LOG" 2>/dev/null </dev/null &!
  IN_DISK_PID=$!
  return 0
}

in_disk_poll() {
  local line nm sz path
  local -a out p pairs
  local -i i
  (( IN_DISK_PID > 1 )) || return 0
  [[ -n "$IN_DISK_LOG" && -r "$IN_DISK_LOG" ]] || return 0
  out=("${(@f)$(<"$IN_DISK_LOG")}")
  # THE SENTINEL IS THE ONLY THING THAT SAYS IT FINISHED.  A file that has
  # stopped growing has not necessarily stopped being written to.
  (( ${#out[@]} )) || return 0
  [[ "${out[-1]}" == '__END__' ]] || return 0
  IN_DISK_PID=0
  in_tmp_drop "$IN_DISK_LOG"; IN_DISK_LOG=''
  IN_DISK_AT=$IN_NOW
  IM_GG_NAME=(); IM_GG_WHERE=(); IM_GG_QUANT=(); IM_GG_SIZE=(); IM_GG_PATH=()
  zmodload -F zsh/stat +b:zstat 2>/dev/null || { in_models_join; return 0 }
  pairs=()
  for line in "${out[@]}"; do
    [[ -n "$line" && "$line" != '__END__' ]] || continue
    sz=''
    zstat -A p +size -- "$line" 2>/dev/null && sz="${p[0]}"
    [[ "$sz" == <-> ]] || continue
    printf -v nm '%014d' $sz
    pairs+=("$nm|$sz|$line")
  done
  for line in "${(@O)pairs[@]}"; do
    line="${line#*|}"
    sz="${line%%|*}"; path="${line#*|}"; nm="${path:t}"; nm="${nm%.gguf}"
    in_size_h $sz
    IM_GG_NAME+=("${nm[0,43]}"); IM_GG_WHERE+=(gguf); IM_GG_SIZE+=("$ISZ"); IM_GG_PATH+=("$path")
    in_quant "$nm"; IM_GG_QUANT+=("$IQT")
    (( ${#IM_GG_NAME[@]} >= 40 )) && break
  done
  in_models_join
  return 0
}

# THE PULLED LIST AND THE FILES ON DISK ARE READ AT DIFFERENT SPEEDS, so they
# are kept apart and joined for the page: ollama answers in milliseconds and
# the disk takes as long as it takes.
typeset -ga IM_OL_NAME IM_OL_WHERE IM_OL_QUANT IM_OL_SIZE IM_OL_PATH
typeset -ga IM_GG_NAME IM_GG_WHERE IM_GG_QUANT IM_GG_SIZE IM_GG_PATH
in_models_join() {
  IM_NAME=("${IM_OL_NAME[@]}" "${IM_GG_NAME[@]}")
  IM_WHERE=("${IM_OL_WHERE[@]}" "${IM_GG_WHERE[@]}")
  IM_QUANT=("${IM_OL_QUANT[@]}" "${IM_GG_QUANT[@]}")
  IM_SIZE=("${IM_OL_SIZE[@]}" "${IM_GG_SIZE[@]}")
  IM_PATH=("${IM_OL_PATH[@]}" "${IM_GG_PATH[@]}")
  IM_N=${#IM_NAME[@]}
  return 0
}

in_scan_models_due() {
  (( IN_DISK_AT > 0.0 && IN_NOW - IN_DISK_AT < IN_DISK_EVERY )) && return 0
  in_scan_models
  return 0
}
in_scan_models() {
  IN_DISK_AT=$IN_NOW
  IM_OL_NAME=(); IM_OL_WHERE=(); IM_OL_QUANT=(); IM_OL_SIZE=(); IM_OL_PATH=()
  local line nm
  local -a out p
  local -i i
  if (( IN_MOCK )); then
    for (( i = 0; i < ${#IN_MOCK_MNAME[@]}; i++ )); do
      IM_OL_NAME+=("${IN_MOCK_MNAME[$i]}"); IM_OL_WHERE+=("${IN_MOCK_MWHERE[$i]}")
      IM_OL_SIZE+=("${IN_MOCK_MSIZE[$i]}"); IM_OL_PATH+=("${IN_MOCK_MPATH[$i]:-}")
      in_quant "${IN_MOCK_MNAME[$i]}"; IM_OL_QUANT+=("$IQT")
    done
    IM_GG_NAME=(); IM_GG_WHERE=(); IM_GG_QUANT=(); IM_GG_SIZE=(); IM_GG_PATH=()
    in_models_join
    return 0
  fi
  # OLLAMA'S OWN LIST IS THE FAST HALF, because a pulled model is not a file
  # you can find: it is a blob in a content-addressed store under a name only
  # ollama knows.  `NAME  ID  SIZE UNIT  MODIFIED…`, split in the shell -- an
  # awk a row would be one fork per model on a surface that forks enough.
  if (( ${+commands[ollama]} )); then
    out=("${(@f)$(ollama list 2>/dev/null </dev/null)}")
    for (( i = 1; i < ${#out[@]}; i++ )); do     # row 0 is the header
      line="${out[$i]}"
      [[ -n "${line// /}" ]] || continue
      p=(${=line})
      (( ${#p[@]} >= 4 )) || continue
      IM_OL_NAME+=("${p[0][0,43]}"); IM_OL_WHERE+=(ollama); IM_OL_PATH+=('')
      IM_OL_SIZE+=("${p[2]} ${p[3]}")
      in_quant "${p[0]}"; IM_OL_QUANT+=("$IQT")
      (( ${#IM_OL_NAME[@]} >= 40 )) && break
    done
  fi
  # ...AND THE RUNNER IS ASKED TOO.  A brew-installed ollama is at a path
  # this cabinet's shell may not have on it, and a pull that has just
  # finished is registered with the server before `ollama list` on some
  # other PATH knows -- so what the server says it holds is the list, and
  # the binary's answer is merged into it rather than being the only one.
  if (( ${IR[0.up]:-0} )); then
    in_http "http://127.0.0.1:${IN_RPORT[0]}/api/tags"
    [[ -n "$IHB" ]] && in_ollama_tags "$IHB"
  fi
  # ...AND MLX IS ASKED THE SAME WAY.  mlx_lm.server speaks the OpenAI shape,
  # so /v1/models is its list -- the models it has already pulled from Hugging
  # Face into the HF cache and can load.  A .gguf is llama.cpp's and an ollama
  # blob is ollama's; an `mlx-community/…` weight in 4-bit is MLX's, and this
  # is the only runner that will serve it.
  if (( ${IR[3.up]:-0} )); then
    in_http "http://127.0.0.1:${IN_RPORT[3]}/v1/models"
    [[ -n "$IHB" ]] && in_mlx_tags "$IHB"
  fi
  in_models_join
  # ...AND THE SLOW HALF GOES OUT OF PROCESS.
  in_disk_start
  return 0
}

# in_ollama_tags BODY — /api/tags, folded into the pulled list.  The body is
# {"models":[{"name":"…","size":N,…},…]}; each name is taken with the size
# that follows it in the same record, and a name already listed is skipped.
in_ollama_tags() {
  local rest="$1" pre win v sz
  local -i at n=0
  while [[ "$rest" == *'"name"'* ]]; do
    pre="${rest%%\"name\"*}"
    at=$(( ${#pre} + 6 ))
    win="${rest[$at,$(( at + 400 ))]}"
    rest="${rest[$at,-1]}"
    win="${win#*:}"; win="${win## }"
    [[ "$win" == '"'* ]] || continue
    v="${win#\"}"; v="${v%%\"*}"
    [[ -n "$v" ]] || continue
    [[ " ${IM_OL_NAME[*]} " == *" ${v[0,43]} "* ]] && continue
    sz=''
    if [[ "$win" == *'"size"'* ]]; then
      sz="${win#*\"size\"}"; sz="${sz#*:}"; sz="${sz## }"; sz="${sz%%[^0-9]*}"
    fi
    if [[ "$sz" == <-> ]]; then in_size_h $sz; sz="$ISZ"; else sz='?'; fi
    IM_OL_NAME+=("${v[0,43]}"); IM_OL_WHERE+=(ollama); IM_OL_SIZE+=("$sz"); IM_OL_PATH+=('')
    in_quant "$v"; IM_OL_QUANT+=("$IQT")
    (( ++n >= 40 )) && break
  done
  return 0
}

# in_mlx_tags BODY — /v1/models, the OpenAI shape, folded into the list the
# same way.  The body is {"object":"list","data":[{"id":"…","object":"model",
# …},…]}; each `"id"` is a model MLX can serve.  No size comes back -- the
# endpoint does not carry one and the weight is a directory in the HF cache,
# not a file to stat -- so the size reads `?`, the way a merged ollama tag
# with no size does.  A name already listed is skipped, so a model that is
# both here and somewhere else is not doubled.
in_mlx_tags() {
  local rest="$1" pre win v
  local -i at n=0
  while [[ "$rest" == *'"id"'* ]]; do
    pre="${rest%%\"id\"*}"
    at=$(( ${#pre} + 4 ))
    win="${rest[$at,$(( at + 300 ))]}"
    rest="${rest[$at,-1]}"
    win="${win#*:}"; win="${win## }"
    [[ "$win" == '"'* ]] || continue
    v="${win#\"}"; v="${v%%\"*}"
    [[ -n "$v" ]] || continue
    [[ " ${IM_OL_NAME[*]} " == *" ${v[0,43]} "* ]] && continue
    IM_OL_NAME+=("${v[0,43]}"); IM_OL_WHERE+=(mlx); IM_OL_SIZE+=('?'); IM_OL_PATH+=('')
    in_quant "$v"; IM_OL_QUANT+=("$IQT")
    (( ++n >= 40 )) && break
  done
  return 0
}

# ── WHAT A PULLED MODEL CAN DO · asked of ollama, not guessed ─────────────
# ollama's /api/show carries a `capabilities` array -- `tools`, `completion`,
# `embedding`, `vision` -- which is the one true answer to "can this drive
# opencode": opencode is an agent, and an agent needs `tools`.  A model with
# no tools cannot make a tool call; an embedding model cannot chat at all.
# So the ON DISK list marks the exceptions, and ⏎ into opencode reads this
# rather than the crude size guess it used before.
#
# ONE MODEL A TICK, THEN NEVER AGAIN.  A model's capabilities do not change,
# so each is asked once and remembered for the session; the resolver walks
# one unknown model per call off the beat, the way the scan walks one row.
typeset -gA IM_CAP        # model name → tools · chat · embed · ?(asked, unknown)
typeset -gF IN_CAPS_AT=0.0
in_caps_step() {
  local m caps
  local -i i
  (( ${IR[0.up]:-0} )) || return 0
  (( IN_NOW - IN_CAPS_AT < 0.3 )) && return 0
  for (( i = 0; i < ${#IM_OL_NAME[@]}; i++ )); do
    [[ "${IM_OL_WHERE[$i]:-ollama}" == ollama ]] || continue
    m="${IM_OL_NAME[$i]}"
    [[ -n "${IM_CAP[$m]:-}" ]] && continue
    IN_CAPS_AT=$IN_NOW
    if (( IN_MOCK )); then
      case "$m" in
        *embed*)                        IM_CAP[$m]=embed ;;
        *coder*|qwen3*|gpt-oss*|*mistral*|*llama3*) IM_CAP[$m]=tools ;;
        *)                              IM_CAP[$m]=chat ;;
      esac
      return 0
    fi
    in_json_esc "$m"
    in_http_post "http://127.0.0.1:${IN_RPORT[0]}/api/show" "{\"name\":\"$IJE\"}"
    if [[ "$IHB" == *'"capabilities"'* ]]; then
      # SCOPED TO THE ARRAY, so the word `tools` inside a prompt template does
      # not read as a capability.
      caps="${IHB#*\"capabilities\"}"; caps="${caps%%]*}"
      if   [[ "$caps" == *'"tools"'* ]];     then IM_CAP[$m]=tools
      elif [[ "$caps" == *'"embedding"'* ]]; then IM_CAP[$m]=embed
      else                                        IM_CAP[$m]=chat; fi
    else
      # older ollama with no capabilities field, or a refusal: asked, unknown
      IM_CAP[$m]='?'
    fi
    return 0
  done
  return 0
}

# THE VERDICT A ROW GETS, and ⏎ acts on · ok · small · notools · embed.  It
# reads the measured capability first and falls back to the size heuristic
# for a model ollama could not describe (an older server, or a .gguf).
in_model_verdict() {   # in_model_verdict NAME -> IMV
  local m="$1"
  IMV=ok
  case "${IM_CAP[$m]:-}" in
    embed) IMV=embed; return 0 ;;
    chat)  IMV=notools; return 0 ;;
  esac
  in_model_small "$m"; (( IMS )) && IMV=small
  return 0
}

# ── what is awake right now, measured ─────────────────────────────────────
typeset -ga IZ_NAME IZ_SIZE IZ_PROC IZ_UNTIL IZ_WHERE
typeset -gi IZ_N=0
in_scan_resident() {
  IZ_NAME=(); IZ_SIZE=(); IZ_PROC=(); IZ_UNTIL=(); IZ_WHERE=(); IZ_N=0
  local line nm
  local -a out p
  local -i i j kb
  if (( IN_MOCK )); then
    IZ_N=0
    if [[ -n "$IN_MOCK_RESIDENT" ]]; then
      IZ_NAME=("${IN_MOCK_RESIDENT%%|*}")
      line="${IN_MOCK_RESIDENT#*|}"
      IZ_SIZE=("${line%%|*}"); line="${line#*|}"
      IZ_PROC=("${line%%|*}"); IZ_UNTIL=("${line#*|}"); IZ_WHERE=(ollama)
      IZ_N=1
    fi
    return 0
  fi
  # `ollama ps` IS THE ONLY THING THAT KNOWS what ollama is holding and for
  # how long -- a model on disk says nothing about whether it is awake.
  if (( ${+commands[ollama]} )) && (( ${IR[0.up]:-0} )); then
    out=("${(@f)$(ollama ps 2>/dev/null </dev/null)}")
    for (( i = 1; i < ${#out[@]}; i++ )); do
      line="${out[$i]}"
      [[ -n "${line// /}" ]] || continue
      p=(${=line})
      (( ${#p[@]} >= 4 )) || continue
      IZ_NAME+=("${p[0][0,37]}")
      IZ_SIZE+=("${p[2]} ${p[3]}")
      nm=''
      for (( j = 0; j < ${#p[@]} - 1; j++ )); do
        [[ "${p[$j]}" == *% ]] && { nm="${p[$j]} ${p[$(( j + 1 ))]}"; break }
      done
      IZ_PROC+=("$nm")
      IZ_UNTIL+=("${(j: :)${(@)p[-4,-1]}}")
      IZ_WHERE+=(ollama)
      (( ${#IZ_NAME[@]} >= 8 )) && break
    done
  fi
  # EVERY OTHER RUNNER ANSWERS WITH ITS OWN FOOTPRINT.  llama-server and the
  # rest have no `ps` of their own, so what a model is costing is the process
  # holding it, out of the system's process table.
  # THE PROCESS TABLE IS READ ONCE, not once per runner.  `ps -Ao` is a fork
  # and then several hundred iterations of zsh word-splitting, and it was
  # inside the loop -- so three live runners meant three forks and three walks
  # of every process on the machine, for one number each.
  out=()
  for (( i = 1; i < IN_RN; i++ )); do
    (( ${IR[$i.up]:-0} )) && [[ -n "${IR[$i.served]:-}" ]] && {
      out=("${(@f)$(ps -Ao rss=,comm= 2>/dev/null </dev/null)}"); break
    }
  done
  for (( i = 1; i < IN_RN; i++ )); do
    (( ${IR[$i.up]:-0} )) || continue
    [[ -n "${IR[$i.served]:-}" ]] || continue
    kb=0
    for line in "${out[@]}"; do
      p=(${=line})
      (( ${#p[@]} >= 2 )) || continue
      [[ "${p[1]:t}" == "${IN_RBIN[$i]}"* ]] || continue
      [[ "${p[0]}" == <-> ]] && (( kb += ${p[0]} ))
    done
    ISZ=''
    (( kb > 0 )) && in_size_h $(( kb * 1024.0 ))
    IZ_NAME+=("${${IR[$i.served]%% · *}[0,37]}")
    IZ_SIZE+=("$ISZ"); IZ_PROC+=(''); IZ_UNTIL+=('')
    IZ_WHERE+=("${IN_RNAME[$i]:l}")
  done
  IZ_N=${#IZ_NAME[@]}
  return 0
}

# ── and what the machine has left ─────────────────────────────────────────
typeset -gF IN_MEM_USED=0.0 IN_MEM_TOTAL=0.0 IN_MEM_PCT=0.0 IN_LOAD=0.0
typeset -gi IN_NCPU=1 IN_THERM_LIM=100 IN_HW_READ=0
typeset -gF IN_THERM_AT=0.0
typeset -gi IN_HW_MEM=0
IN_THERM=''
# HOW OFTEN EACH OF THE THREE IS WORTH ASKING FOR.  They were one function on
# one clock, so every three seconds this machine forked FIVE times -- and one
# of the five is `pmset -g therm`, which goes to the SMC and is far and away
# the slowest of them.  Twenty of those a minute is a hitch you can feel on a
# page that is otherwise doing nothing.
#
#   the chip and the memory size   never change · read once
#   memory in use, load            move constantly · the 3 s clock
#   thermal                        moves slowly · its own 15 s clock
IN_THERM_EVERY=15.0
in_sample_mach() {
  local txt line
  local -a p
  local n k v
  local -i page=4096 tot=0 anon=0 purge=0 wired=0 comp=0 app=0
  if (( IN_MOCK )); then
    IN_MEM_TOTAL=16.0; IN_MEM_USED=9.4
    IN_MEM_PCT=$(( 100.0 * IN_MEM_USED / IN_MEM_TOTAL ))
    IN_LOAD=2.14; IN_NCPU=14; IN_THERM=''; IN_THERM_LIM=100
    return 0
  fi
  # EVERY NUMBER OUT OF A COMMAND IS CHECKED BEFORE IT IS A NUMBER.  These
  # are assignments to typed parameters (`typeset -gi`, `local -i`), and a
  # typed assignment that fails to parse ENDS THE SHELL -- so a sysctl that
  # answers `unknown oid` on some future macOS would take the cabinet down
  # rather than showing one wrong figure.
  if (( ! IN_HW_READ )); then
    IN_HW_READ=1
    txt="$(sysctl -n hw.ncpu 2>/dev/null </dev/null)" || txt=''
    [[ "$txt" == <-> ]] && IN_NCPU=$txt || IN_NCPU=1
    (( IN_NCPU < 1 )) && IN_NCPU=1
    txt="$(sysctl -n hw.memsize 2>/dev/null </dev/null)" || txt=''
    [[ "$txt" == <-> ]] && IN_HW_MEM=$txt || IN_HW_MEM=0
  fi
  tot=$IN_HW_MEM
  if (( tot > 0 )); then
    txt="$(vm_stat 2>/dev/null </dev/null)" || txt=''
    [[ "$txt" == *'page size of '* ]] && {
      # `##` AND NOT `#`: there is one `page size of` in vm_stat's output, so
      # the greedy form gives the same answer -- linear rather than quadratic.
      line="${txt##*page size of }"; line="${line%% *}"
      [[ "$line" == <-> ]] && page=$line
    }
    for line in ${(f)txt}; do
      line="${line## }"
      # THE SAME QUEUES SYSTEM READS, AND THE SAME ARITHMETIC.  The comment
      # at the top of this section says these are read the way the monitor
      # reads them, and they were not: this took total minus free minus
      # speculative, which counts the whole file cache and the aged-out
      # inactive queue as used, and on the same Mac in the same second LOCAL's
      # meter and SYSTEM's meter disagreed by gigabytes -- beside a panel
      # whose own label says SYSTEM HAS THE REST OF IT.
      #
      # Activity Monitor's figure, which is the one a reader can check
      # against, is app memory + wired + compressed, where app memory is the
      # anonymous pages less the ones marked purgeable.
      k="${line%%:*}"; v="${line#*:}"
      [[ "$line" == *:* ]] || continue
      v="${v//[[:space:]]/}"; v="${v%.}"; k="${k//\"/}"
      [[ "$v" == <-> ]] || continue
      case "$k" in
        'Anonymous pages')             anon=$v ;;
        'Pages purgeable')             purge=$v ;;
        'Pages wired down')            wired=$v ;;
        'Pages occupied by compressor') comp=$v ;;
      esac
    done
    app=$(( anon - purge )); (( app < 0 )) && app=0
    IN_MEM_TOTAL=$(( tot / 1073741824.0 ))
    IN_MEM_USED=$(( (app + wired + comp) * page / 1073741824.0 ))
    (( IN_MEM_USED < 0.0 )) && IN_MEM_USED=0.0
    IN_MEM_PCT=$(( IN_MEM_TOTAL > 0.0 ? 100.0 * IN_MEM_USED / IN_MEM_TOTAL : 0.0 ))
  fi
  # `sysctl vm.loadavg` PRINTS `{ 2.14 1.86 1.62 }`, braces and all -- and a
  # pattern that NAMED those braces inside ${...} is the thing that took the
  # monitor down, because zsh counts braces to find the end of the expansion
  # and a `}` inside a bracket expression ends it early.  So the tokens that
  # ARE numbers are kept and the rest is dropped, which never spells one.
  txt="$(sysctl -n vm.loadavg 2>/dev/null </dev/null)" || txt=''
  for line in ${=txt}; do
    [[ "$line" == <->.<-> ]] && { IN_LOAD=$line; break }
  done
  # ...AND THE SLOW ONE ON ITS OWN CLOCK.
  (( IN_NOW - IN_THERM_AT < IN_THERM_EVERY )) && return 0
  IN_THERM_AT=$IN_NOW
  IN_THERM=''; IN_THERM_LIM=100
  txt="$(pmset -g therm 2>/dev/null </dev/null)" || txt=''
  if [[ "$txt" == *CPU_Scheduler_Limit* ]]; then
    line="${txt##*CPU_Scheduler_Limit}"; line="${line##*= }"; line="${line%%$'\n'*}"
    line="${line%% *}"
    [[ "$line" == <-> ]] && IN_THERM_LIM=$line
  fi
  (( IN_THERM_LIM < 100 )) && IN_THERM='throttled'
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE FIXTURE · one Mac, invented, with the agents a demo wants to show
# ══════════════════════════════════════════════════════════════════════════
# Reached only under mock.  Every string is the shape the real command prints,
# because the readers above are the ones that would read it.
IN_MOCK_BINS='claude codex agy opencode ollama llama-server mlx_lm.server ps sysctl vm_stat pmset sw_vers brew pbcopy'
IN_MOCK_SERVED=('qwen3:8b · gpt-oss:20b · llama3.2:3b' 'Qwen3-14B-Q4_K_M' '' 'mlx-community/Qwen3-Coder-8B-4bit')
IN_MOCK_MNAME=('gpt-oss:20b' 'qwen3:8b' 'llama3.2:3b' 'nomic-embed-text:latest' \
               'Qwen3-14B-Q4_K_M' 'Mistral-7B-Instruct-v0.3-Q5_K_M' \
               'Phi-4-mini-3.8B-Q8_0' 'TinyLlama-1.1B-Chat-F16' \
               'DeepSeek-Coder-6.7B-Q4_0' 'mlx-community/Qwen3-Coder-8B-4bit')
IN_MOCK_MWHERE=(ollama ollama ollama ollama gguf gguf gguf gguf gguf mlx)
IN_MOCK_MSIZE=('13 GB' '5.2 GB' '2.0 GB' '274 MB' '8.5 GB' '5.1 GB' '4.1 GB' '2.2 GB' '3.8 GB' '4.8 GB')
IN_MOCK_MPATH=('' '' '' '' "$HOME/models/Qwen3-14B-Q4_K_M.gguf" \
               "$HOME/models/Mistral-7B-Instruct-v0.3-Q5_K_M.gguf" \
               "$HOME/models/Phi-4-mini-3.8B-Q8_0.gguf" \
               "$HOME/models/TinyLlama-1.1B-Chat-F16.gguf" \
               "$HOME/models/DeepSeek-Coder-6.7B-Q4_0.gguf" '')
IN_MOCK_RESIDENT='qwen3:8b|5.2 GB|100% GPU|4 minutes from now'
IN_MOCK_CHAT='sleep 0.5
for w in "Because the endpoint is stateless, " "the console sends the whole " \
         "conversation every time — which is also why the context figure on " \
         "the right grows the way it does.

" \
         "The rate beside it is a difference, not a division: it is what " \
         "arrived since the last look, so a model that stalls halfway reads " \
         "as a model that stalled."; do
  print -rn -- "$w"; sleep 0.55
done
print -r -- ""
print -r -- "412 96" > "${ALIEN_USE:-/dev/null}"'
IN_MOCK_ASK='sleep 0.6
print -r -- "A shell has no floating point, so the usual trick is to scale:"
print -r -- ""
print -r -- "  print $(( 22.0 / 7 ))"
print -r -- ""
print -r -- "zsh is the exception here — it does have float arithmetic, and"
print -r -- "(( x = 1.5 )) works the way you would expect it to. bash does"
print -r -- "not, which is where the scaling habit comes from."
sleep 1.4
print -r -- ""
print -r -- "For portable scripts, awk or bc is the usual answer."'
IN_MOCK_PORTS='11434 8080 8081'
IN_MOCK_FILES="$HOME/.claude/.credentials.json $HOME/.codex/auth.json $HOME/.antigravitycli"
IN_MOCK_RUN='print -r -- "  % downloading";
for i in 1 2 3 4 5 6 7 8; do
  printf "  %3d%%  %s\n" $(( i * 12 )) "$(printf "#%.0s" {1..$i})"
  sleep 0.4
done
print -r -- "  verifying checksum";
print -r -- "  linking into ~/.local/bin";
print -r -- "  done."'
IN_MOCK_VER=('2.1.4' '0.4.2' '' '0.9.1')
IN_MOCK_MODEL=('claude-sonnet-4-6' 'gemini-3-pro' '' 'gpt-5.2-codex')

# ══════════════════════════════════════════════════════════════════════════
# THE FURNITURE · seven surfaces, one machine
# ══════════════════════════════════════════════════════════════════════════
typeset -gi I_FG=0 I_LBL=0 I_DIM=0 I_WARM=0 I_HOT=0 I_WHITE=0
typeset -gi I_OK=0 I_WARNC=0 I_NO=0
in_palette() {
  I_FG=$CYAN; I_LBL=$GREY; I_DIM=$DIM
  I_WARM=$PURPLE; I_HOT=$MAGENTA; I_WHITE=$WHITE
  I_OK=$LIME; I_WARNC=$AMBER
  cshade $GREY 0.85; I_NO=$CS
  # THE BENCH'S THREE, AT FULL STRENGTH.  The columns are told apart by colour
  # and by nothing else, so these are the three pure hues rather than three
  # mixes toward white -- which is what they were, and which made a cyan dot
  # and a lime dot the same off-white dot at this size.
  IN_ASK_INK[0]=$CYAN; IN_ASK_INK[1]=$LIME; IN_ASK_INK[2]=$PURPLE
  return 0
}
in_ink() {   # in_ink STATE -> IIN the colour, IID the mark
  case "$1" in
    ok)   IIN=$I_OK;    IID='●' ;;
    warn) IIN=$I_WARNC; IID='◐' ;;
    wait) cshade $GREY 0.9; IIN=$CS; IID='◐' ;;
    *)    IIN=$I_NO;    IID='○' ;;
  esac
}

in_ell() {   # in_ell TEXT N -> ELL, with a real ellipsis rather than a cut
  local s="$1"
  local -i n=$2
  if (( ${#s} <= n )); then ELL="$s"; return 0; fi
  # AT n == 1 THE SLICE WOULD BE [0,-1], WHICH IS THE WHOLE STRING under
  # KSH_ARRAYS -- so the one width that should truncate hardest did not
  # truncate at all.  Not reachable from any current call site; guarded so it
  # stays that way when somebody adds a narrow column.
  (( n < 2 )) && { ELL="${${s[0,0]}:-}"; return 0 }
  ELL="${s[0,$(( n - 2 ))]}…"
}
# `IRP`, NOT `RPD`.  This wrote its answer into a global called RPD, and the
# CABINET already has one: RPD is radians-per-degree, the constant every sun
# and moon angle on this machine is computed from.  So the first time CLOUD
# drew its `terminal` label, `RPD` stopped being 0.0174 and became the string
# `terminal `, and from that frame on every sky calculation in the door failed
# -- silently, because sky_sun answers "I do not know where you are" rather
# than complaining.  The mascot's day and night went with it.
#
# A PACK SHARES THE HOST'S NAMESPACE.  There is no scope between them: this
# file is SOURCED into the door, so every unprefixed global it writes is one
# the door might already be using.  Everything this pack owns is prefixed --
# IN_, IA, IR, IM_, IZ_, BN_, CH_, IP_ -- and the short output variables
# (ELL, SHT, WRP, SEC…) are the ones to check against terminal.command before
# adding another.
in_rpad() { IRP="$1"; while (( ${#IRP} < $2 )); do IRP+=' '; done }
in_short() { SHT="${1/#$HOME/~}" }

# WHAT A PROGRAM WROTE, AS A TERMINAL WOULD HAVE SHOWN IT.  A log is not
# text: ollama redraws its progress bars in place with carriage returns,
# `\e[K` and cursor-up, and hides the cursor and holds frames with private
# modes around every update.  Read raw, those bytes went onto the glass --
# and through it, since a cell is emitted verbatim: the `\e[K` erased the
# bezel beside the strip and the mode switches reached Terminal.app.  So a
# line is reduced to what a terminal would have left on it: the text after
# the last carriage return, with every escape sequence and control byte
# gone.
in_plain() {   # in_plain TEXT -> IPL
  setopt localoptions extendedglob
  local s="$1"
  # the last thing written over a carriage return is the thing that stayed
  s="${s%%[$'\r\n']#}"; s="${s##*$'\r'}"
  # CSI · OSC to BEL or ST · any other two-byte escape · what is left
  s="${s//$'\e'\[[0-9;?<=>!]#[ -\/]#[@-~]/}"
  s="${s//$'\e'\][^$'\a'$'\e']#($'\a'|$'\e'\\)/}"
  s="${s//$'\e'?/}"
  s="${s//$'\t'/  }"
  s="${s//[[:cntrl:]]/}"
  IPL="$s"
  return 0
}

in_panel() {   # in_panel X Y W H TITLE [RIGHT]
  v_box $1 $2 $3 $4 $I_DIM $GLASS round
  v_text $(( $1 + 2 )) $2 " $5 " $AMBER $GLASS
  [[ -n "${6:-}" ]] && {
    local r=" $6 "
    v_text $(( $1 + $3 - 3 - ${#r} + 1 )) $2 "$r" $I_DIM $GLASS
  }
  return 0
}

in_kv() {   # in_kv X Y LABEL VALUE [LW] [TONE]
  local -i x=$1 y=$2 lw=${5:-12} col=${6:--2}
  in_rpad "$3" $lw
  v_text $x $y "$IRP" $I_LBL
  (( col == -2 )) && col=$I_FG
  v_text $(( x + lw + 1 )) $y "$4" $col
  return 0
}

# ◂ CLOUD ▸ AND THE TWO OR THREE NUMBERS THAT PAGE IS ABOUT.  pages=0 for the
# surfaces ◂ ▸ cannot reach: a chooser you are standing in is not one of the
# seven, and silk-screening the arrows onto it would promise a key that does
# nothing.
in_head() {   # in_head TITLE PAGES RIGHT [LAB VAL COL]... — on the suite's title bar
  local t="$1" right="$3"
  local -i pages=$2 x hb
  # THE BRAND, THE SKY AND THE RULE ARE THE CABINET'S NOW · app_head lays the lit
  # band, prints ◤ INTELLIGENCE in its corner and the sky's caption in the other,
  # and hands back the room between them.  This machine fills that room with its
  # page name and its readings, drawn on the band's own ground.
  cmix $GLASS $PURPLE 0.32; hb=$CM
  app_head INTELLIGENCE
  x=$APP_HX
  # ◂ TITLE ▸ · the page name, with its arrows when the page can be turned
  if (( pages )); then
    cshade $PURPLE 1.15;      v_text $x 0 '◂ ' $CS $hb
    cmix $WHITE $CYAN 0.15;   v_text $(( x + 2 )) 0 "$t" $CM $hb
    cshade $PURPLE 1.15;      v_text $(( x + 2 + ${#t} )) 0 ' ▸' $CS $hb
    x=$(( x + 5 + ${#t} ))
  else
    cmix $WHITE $CYAN 0.15;   v_text $x 0 "$t" $CM $hb
    x=$(( x + 2 + ${#t} ))
  fi
  shift 3
  # THE BAND HAS AN END, and it is where the sky's caption starts (APP_HR).
  # On the cabinet's own glass a night caption is forty columns long, and the
  # readings used to run on into it regardless -- LOCAL's came out as
  # `Rnothing…nonexinOPENCODEsnone` printed over the moon -- with the right-
  # hand reading forced in at eight columns on top of whatever was there.  A
  # reading that does not fit is left off, and every one after it; the right-
  # hand reading goes in only where there is room for it.
  while (( $# >= 3 )); do
    (( x + ${#1} + 1 + ${#2} > APP_HR )) && break
    v_text $x 0 "$1" $I_LBL $hb
    v_text $(( x + ${#1} + 1 )) 0 "$2" $3 $hb
    x=$(( x + ${#1} + ${#2} + 4 ))
    shift 3
  done
  # the machine's own right-hand reading (a working dir, a count) sits just
  # inside the caption now, not out at the glass edge
  if [[ -n "$right" ]]; then
    local -i room=$(( APP_HR - x ))
    (( room > 46 )) && room=46
    if (( room >= 8 )); then
      # cut at a word when it is words (a phrase reads `values are…`, not
      # `values are n…`); a path has no spaces and is cut where it must be
      ELL="$right"
      if (( ${#right} > room )); then
        ELL="${right[0,$(( room - 2 ))]}"
        [[ "$ELL" == *' '?* ]] && ELL="${ELL% *}"
        # a word or two is not a reading · `a…` says nothing, so it goes
        if (( ${#ELL} < 6 )); then ELL=''; else ELL+='…'; fi
      fi
      [[ -n "$ELL" ]] && v_text $(( APP_HR - ${#ELL} + 1 )) 0 "$ELL" $I_LBL $hb
    fi
  fi
  return 0
}

# THE ROW UNDER THE CURSOR · a wash the width of the list, so the eye has one
# thing to follow down it
# in_glide NAME TARGET IDX -> IGS IGON · how much of the cursor's band row IDX
# holds while the band glides toward TARGET (the cabinet's MO_CURSOR curve),
# and whether this row counts as the one under the cursor
in_glide() {
  mo_ease "in.$1" $2 $IN_NOW $MO_CURSOR
  IGS=$(( 1.0 - abs($3 - MV) )); (( IGS < 0.0 )) && IGS=0.0
  IGON=0; (( IGS >= 0.5 )) && IGON=1
  return 0
}
in_band() {   # in_band X Y W STRENGTH -> IBG the background to draw the row on
  if (( $4 > 0.001 )); then
    cmix $GLASS $I_DIM $(( 0.55 * $4 )); IBG=$CM
  else
    IBG=$GLASS
  fi
  # the run of spaces comes from the cabinet's _run (padding in C) where it has one
  local s='' i
  if (( ${+functions[_run]} )); then _run $3 ' '; s="$RUN"
  else for (( i = 0; i < $3; i++ )); do s+=' '; done; fi
  v_text $1 $2 "$s" $GREY $IBG
  return 0
}

in_foot() {   # in_foot KEY WORD ... — INTELLIGENCE's keys, on the suite's one nav bar
  # THE FOOTER IS THE CABINET'S NOW, not this machine's.  app_nav rides the same
  # two rows in the same ink on every surface in the suite; INTELLIGENCE hands it
  # its keys, wrapped in the brackets its pages have always drawn them in, and
  # nothing else.  (app_nav clears its own row, so the modal-over-page interleave
  # this used to guard against is handled there, once, for everyone.)
  local -a a; local k
  while (( $# >= 2 )); do
    k="$1"
    # THE SAME BRACKET SPLIT THE MENU DRAWS · a named key (a letter, a digit, or
    # the escape) wears brackets; a gesture glyph (▴▾ ◂▸ ⏎ ⇥ ⌫) does not.
    [[ "$k" == [A-Za-z0-9] || "$k" == ⎋ ]] && k="[$k]"
    a+=("$k" "$2"); shift 2
  done
  app_nav "${a[@]}"
  return 0
}

# A WORD-WRAPPED PARAGRAPH.  Note what it does NOT do: it never breaks a word,
# so a line longer than the width comes back at full length and the caller
# clips it.  Every caller that draws inside a box does.
in_wrap() {   # in_wrap TEXT W -> WRP, the lines
  local -a out
  local line='' w
  WRP=()
  for w in ${=1}; do
    if (( ${#line} + ${#w} + 1 > $2 )); then
      [[ -n "$line" ]] && WRP+=("$line")
      line="$w"
    else
      line="${line:+$line }$w"
    fi
  done
  [[ -n "$line" ]] && WRP+=("$line")
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# CLOUD · which agent gets the terminal
# ══════════════════════════════════════════════════════════════════════════
# ONE ROW PER COMMAND LINE, and the row says what ⏎ will do before ⏎ does it:
# the binary that will run, the version of it, the model it is set to, how it
# is signed in, and which of the several installs of it on this machine is the
# one on PATH.  That last column is not decoration -- a node install and a brew
# install of the same agent are a real thing to have, and the row tells you
# which one you are about to be inside.
in_draw_cloud() {
  local -i i y on here=0 ready=0 up=0 col bg
  local s
  # ON THE WHOLE WINDOW the roster and its two detail panels widen, the last
  # roster columns ride the right edge, and RECENT grows down onto the footer
  local -i fw=102 band=100 rs=0 sx=2 sw=52 wx=56 ww2=48 recH=6
  if (( SCR_W > 120 )); then
    fw=$(( SCR_W - 4 )); band=$(( SCR_W - 6 )); rs=$(( fw - 102 ))
    sw=$(( (SCR_W - 6) * 52 / 100 )); wx=$(( sx + sw + 2 )); ww2=$(( SCR_W - 4 - wx ))
    recH=$(( SCR_H - 24 ))
  fi
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  for (( i = 0; i < IN_N; i++ )); do
    (( ${IA[$i.here]:-0} )) && (( here++ ))
    [[ "${IA[$i.state]:-no}" == ok ]] && (( ready++ ))
  done
  for (( i = 0; i < IN_RN; i++ )); do (( ${IR[$i.up]:-0} )) && (( up++ )); done
  if (( IZ_N )); then s="${IZ_NAME[0]} · ${IZ_SIZE[0]:-—}"
  elif (( up )); then s="$up up · nothing loaded"
  else s='none up'; fi
  cmix $WHITE $LIME 0.4; col=$CM
  in_short "$PWD"
  in_head CLOUD 1 "$SHT" \
     HERE "$here of $IN_N" $I_WHITE \
     READY "$ready" $col \
     LOCAL "$s" $I_LBL

  in_panel 2 3 $fw 8 'THE FOUR' '[I] INSTALLS · [U] REMOVES'
  v_text 10 4 '#'       $I_DIM
  v_text 14 4 'AGENT'   $I_DIM
  v_text 29 4 'BINARY'  $I_DIM
  v_text 41 4 'VERSION' $I_DIM
  v_text 52 4 'MODEL'   $I_DIM
  v_text $(( 74 + rs )) 4 'SIGNED IN' $I_DIM
  v_text $(( 90 + rs )) 4 'FROM'    $I_DIM
  # FOUR ROWS IS WHAT THE BOX HAS.  Bounded by the panel as well as by the
  # roster, so a fifth agent is a row this page does not draw rather than a
  # row drawn over the summary line and the border below it.
  for (( i = 0; i < IN_N && i < 4; i++ )); do
    y=$(( 5 + i )); in_glide cloud $IN_SEL $i; on=$IGON
    in_band 3 $y $band $IGS; bg=$IBG
    if (( on )); then cmix $WHITE $LIME 0.3; v_put 4 $y '▸' $CM $bg; fi
    if (( ${IA[$i.here]:-0} )); then
      # a row that is here but has not been reached by the scan yet says so
      [[ -n "${IA[$i.ver]:-}" ]] && in_ink "${IA[$i.state]:-wait}" || in_ink wait
      v_put 8 $y "$IID" $IIN $bg
    else
      cshade $GREY 0.55
      v_put 8 $y '○' $CS $bg
    fi
    (( on )) && col=$AMBER || { cshade $AMBER 0.6; col=$CS }
    v_text 10 $y "[$(( i + 1 ))]" $col $bg
    in_ell "${IN_NAME[$i]}" 14
    if (( ${IA[$i.here]:-0} )); then
      (( on )) && col=$I_WHITE || col=$I_LBL
    else
      cshade $GREY 0.8; col=$CS
    fi
    v_text 14 $y "$ELL" $col $bg
    if (( ! ${IA[$i.here]:-0} )); then
      in_ell "${IN_BINS[$i]%% *}" 11
      v_text 29 $y "$ELL" $I_DIM $bg
      in_ell "${IN_GET[$i]}" 46
      v_text 41 $y "$ELL" $I_DIM $bg
      (( on )) && { cmix $I_DIM $AMBER 0.5; col=$CM } || col=$I_DIM
      v_text $(( 90 + rs )) $y '[I] installs' $col $bg
      continue
    fi
    in_ell "${IA[$i.bin]:-}" 11
    (( on )) && col=$I_LBL || col=$I_DIM
    v_text 29 $y "$ELL" $col $bg
    in_ell "${IA[$i.ver]:-…}" 10
    v_text 41 $y "$ELL" $col $bg
    in_ell "${IA[$i.model]:-…}" $(( 21 + rs ))
    if (( on )); then cmix $WHITE $PURPLE 0.35; else cmix $I_DIM $PURPLE 0.5; fi
    v_text 52 $y "$ELL" $CM $bg
    in_ink "${IA[$i.state]:-wait}"
    in_ell "${IA[$i.auth]:-reading…}" 15
    (( on )) || { cshade $IIN 0.7; IIN=$CS }
    v_text $(( 74 + rs )) $y "$ELL" $IIN $bg
    in_ell "${IA[$i.from]:-}" 13
    v_text $(( 90 + rs )) $y "$ELL" $I_DIM $bg
  done
  if (( ! ${IA[$IN_SEL.here]:-0} )); then
    s='⏎ on this one offers to install it, on a gate'
  else
    s='⏎ opens the one under the cursor, in the glass'
  fi
  v_text 14 9 "$here installed · $ready signed in · $s" $I_DIM

  # ── the one under the cursor, and the deed ──
  local -i a=$IN_SEL
  in_ell "${IN_NAME[$a]}" 24
  in_panel $sx 11 $sw 10 "$ELL" SELECTED
  in_wrap "${IN_BLURB[$a]}" $(( sw - 6 ))
  for (( i = 0; i < ${#WRP[@]} && i < 2; i++ )); do
    v_text 4 $(( 12 + i )) "${WRP[$i]}" $I_LBL
  done
  if (( ${IA[$a.here]:-0} )); then
    cmix $WHITE $PURPLE 0.35
    in_ell "${IA[$a.model]:-…}" 34; in_kv 4 15 model "$ELL" 10 $CM
    in_ink "${IA[$a.state]:-wait}"
    in_ell "${IA[$a.auth]:-reading…}" 34;  in_kv 4 16 'signed in' "$ELL" 10 $IIN
    in_ell "${IA[$a.ver]:-…}" 34; in_kv 4 17 version "$ELL" 10
    in_short "${IA[$a.path]:-}"; in_ell "$SHT" 34
    in_kv 4 18 binary "$ELL" 10
  else
    cshade $GREY 0.9
    in_kv 4 15 state 'not installed' 10 $CS
    cmix $WHITE $AMBER 0.35
    in_ell "${IN_GET[$a]}" 34; in_kv 4 16 install "$ELL" 10 $CM
    in_ell "${IN_HOME[$a]}" 34; in_kv 4 17 config "$ELL" 10
    # A REAL ARRAY, AND NOT A NESTED SUBSCRIPT.  `${${=IN_ENVS[$a]}[0]}` reads
    # as "the first word", and it is -- until the field holds ONE word, at
    # which point zsh has a scalar rather than an array and hands back the
    # first CHARACTER of it.  Three of these four rows hold one word, so the
    # key column read `X`, `O`, `A` on the glass and looked like a rendering
    # fault rather than a subscript.
    local -a ev; ev=(${=IN_ENVS[$a]})
    in_kv 4 18 key "${ev[0]:-—}" 10
  fi

  # ── what ⏎ would do, said before it does it ──
  if (( ${IA[$a.here]:-0} )); then
    local -i wc=$(( wx + 2 ))
    in_panel $wx 11 $ww2 10 'WHAT ⏎ OPENS' 'FROM THIS FOLDER'
    cmix $WHITE $AMBER 0.4
    in_ell "${IA[$a.bin]:-}" $(( ww2 - 5 ))
    v_text $wc 12 "$ELL" $CM
    in_short "$PWD"; in_ell "$SHT" $(( ww2 - 18 ))
    in_kv $wc 14 in "$ELL" 10
    in_env_set ${=IN_ENVS[$a]}
    in_kv $wc 15 inherits "${IEV:-no key — it uses its own sign-in}" 10
    cmix $WHITE $LIME 0.35
    if in_sh_live "${IN_BINS[$a]%% *}"; then
      in_kv $wc 16 opens 'it is already up · ⏎ steps back in' 10 $CM
    else
      in_kv $wc 16 opens 'a terminal of its own, in the glass' 10 $CM
    fi
    cshade $I_DIM 1.1
    v_text $wc 18 'the cabinet keeps the window · ^] comes back' $CS
  else
    local -i wc=$(( wx + 2 ))
    in_panel $wx 11 $ww2 10 'WHAT ⏎ WOULD RUN'
    v_text $wc 12 'nothing — it is not on this machine' $I_DIM
    cmix $WHITE $AMBER 0.35
    in_wrap "${IN_GET[$a]}" $(( ww2 - 5 ))
    for (( i = 0; i < ${#WRP[@]} && i < 2; i++ )); do
      v_text $wc $(( 14 + i )) "${WRP[$i]}" $CM
    done
    v_text $wc 17 '⏎ and [I] both show it on a gate first' $I_DIM
  fi

  # THE STRIP ALONG THE BOTTOM: what has been run from this cabinet, and the
  # job itself while there is one.  Same rectangle either way — taller on fill.
  in_draw_strip 21 $recH

  if [[ "$IN_JOB_STATE" == run ]]; then
    in_foot ▴▾ choose ◂▸ pages X stop ⎋ menu
  elif (( ${IA[$a.here]:-0} )); then
    if in_sh_live "${IN_BINS[$a]%% *}"; then
      in_foot ▴▾ choose ⏎ 'back into it' U remove ⎋ menu
    else
      in_foot ▴▾ choose ⏎ 'open it in the glass' U remove ⎋ menu
    fi
  else
    in_foot ▴▾ choose ◂▸ pages ⏎ install I install ⎋ menu
  fi
  return 0
}


# ── two more pieces of page vocabulary, which LOCAL is the first to need ──
in_meter() {   # in_meter X Y W FRAC LABEL VALUE
  local -i x=$1 y=$2 w=$3 i n col
  local -F f=$4
  local lab="$5" val="$6" d='' b=''
  (( f < 0.0 )) && f=0.0; (( f > 1.0 )) && f=1.0
  # THE BAR EASES; THE FIGURE DOES NOT · the cabinet's MO_VALUE, like the monitor's gauges
  mo_ease "in.meter.$lab.$x.$y" $f $IN_NOW; f=$MV
  in_rpad "$lab" 9
  v_text $x $y "$IRP" $I_LBL
  for (( i = 0; i < w; i++ )); do d+='░'; done
  v_text $(( x + 10 )) $y "$d" $I_DIM
  n=$(( int(f * w + 0.5) ))
  for (( i = 0; i < n; i++ )); do b+='▓'; done
  if   (( f >= 0.85 )); then col=$I_HOT
  elif (( f >= 0.65 )); then col=$I_WARNC
  else                       cmix $WHITE $LIME 0.35; col=$CM; fi
  [[ -n "$b" ]] && v_text $(( x + 10 )) $y "$b" $col
  v_text $(( x + 11 + w )) $y "$val" $I_FG
  return 0
}

# A THUMB, WHEN THERE IS MORE OF A LIST THAN THERE IS ROOM FOR -- and nothing
# at all when there is not, because a full-height scrollbar beside a list that
# fits is a control that promises somewhere else to go.
in_scroll_mark() {   # in_scroll_mark X Y H TOP SHOWN TOTAL
  local -i x=$1 y=$2 h=$3 top=$4 shown=$5 total=$6 i a b
  (( total <= shown || h < 1 || total < 1 )) && return 0
  cshade $I_DIM 0.7
  for (( i = 0; i < h; i++ )); do v_put $x $(( y + i )) '│' $CS $GLASS; done
  a=$(( int(h * top / (total + 0.0) + 0.5) ))
  b=$(( int(h * (top + shown) / (total + 0.0) + 0.5) ))
  (( b <= a )) && b=$(( a + 1 ))
  for (( i = a; i < h && i < b; i++ )); do v_put $x $(( y + i )) '┃' $I_FG $GLASS; done
  return 0
}

in_scroll_into() {   # in_scroll_into SEL TOP SHOWN TOTAL -> ITOP
  local -i sel=$1 top=$2 shown=$3 total=$4
  if (( total <= shown )); then ITOP=0; return 0; fi
  (( top < 0 )) && top=0
  (( top > total - shown )) && top=$(( total - shown ))
  if   (( sel < top ));          then top=$sel
  elif (( sel >= top + shown )); then top=$(( sel - shown + 1 )); fi
  (( top < 0 )) && top=0
  (( top > total - shown )) && top=$(( total - shown ))
  ITOP=$top
  return 0
}

in_right() {   # in_right XEND Y TEXT [FG] [BG]
  v_text $(( $1 - ${#3} + 1 )) $2 "$3" ${4:--2} ${5:--2}
}

# ══════════════════════════════════════════════════════════════════════════
# LOCAL · the models on this disk, and what one of them costs to keep awake
# ══════════════════════════════════════════════════════════════════════════
# TWO LISTS AND ONE CURSOR BETWEEN THEM.  ⇥ moves the cursor from the runners
# to the models and back, because they are two questions about the same thing
# -- what can hold a model, and which models there are to hold -- and giving
# each its own cursor would mean two highlighted rows and no way to tell which
# one ⏎ was about to act on.
typeset -gi IN_LSEL=0 IN_LTOP=0 IN_RSEL=0
IN_LFOCUS='model'    # model · runner

# ══════════════════════════════════════════════════════════════════════════
# ROUTE · one prompt, and the router decides where it goes
# ══════════════════════════════════════════════════════════════════════════
# THE PAGE IS OPENCODE POINTED AT THE ROUTER, and the chrome around it is the
# receipt: which preference is set, whether the proxy is answering, what it can
# reach.  The decision itself lives in the proxy on this machine (the dossier
# says why); this page starts it and shows what it is working with.
typeset -gF IN_ROUTER_AT=0.0
in_route_poll() {
  (( IN_NOW - IN_ROUTER_AT < 3.0 )) && return 0
  IN_ROUTER_AT=$IN_NOW
  if (( IN_MOCK )); then IN_ROUTER_UP=1; return 0; fi
  in_http "http://127.0.0.1:${IN_RPROXY_PORT}/v1/models"
  [[ -n "$IHB" ]] && IN_ROUTER_UP=1 || IN_ROUTER_UP=0
  return 0
}
# THE ROUTER OPENCODE CONFIG · one provider, one logical model (router/auto);
# the proxy behind it is what fans out to local and cloud.
in_route_config() {   # -> IRCF the file
  local d="${XDG_STATE_HOME:-$HOME/.local/state}/alien" json
  IRCF=''
  mkdir -p "$d" 2>/dev/null || return 1
  json='{"$schema":"https://opencode.ai/config.json","provider":{'
  json+='"router":{"npm":"@ai-sdk/openai-compatible","name":"Router (local)",'
  json+='"options":{"baseURL":"http://127.0.0.1:'"$IN_RPROXY_PORT"'/v1"},'
  json+='"models":{"auto":{"name":"auto · local or cloud"}}}},'
  json+='"agent":{"chat":{"description":"chat, no tools","mode":"primary",'
  json+='"tools":{"write":false,"edit":false,"patch":false,"bash":false,"read":false,"grep":false,"glob":false,"list":false,"webfetch":false,"todowrite":false,"todoread":false},'
  json+='"permission":{"edit":"deny","bash":"deny","webfetch":"deny"}}},'
  json+='"model":"router/auto"}'
  print -r -- "$json" > "$d/opencode-route.json" 2>/dev/null || return 1
  chmod 600 "$d/opencode-route.json" 2>/dev/null
  IRCF="$d/opencode-route.json"
  return 0
}
in_route_run() {
  [[ -n "$IOC_PATH" ]] || in_scan_opencode
  if [[ -z "$IOC_PATH" ]]; then say 'no opencode on this machine · INSTALL puts it in'; snd no; return 0; fi
  if (( ! IN_ROUTER_UP )); then
    say 'the router is not running · start litellm on :4000'; snd no; return 0
  fi
  in_route_config || { say 'could not write the router config'; snd no; return 0 }
  local line="env OPENCODE_CONFIG=$(_sh "$IRCF") $(_sh "$IOC_PATH") --model router/auto"
  in_short "$PWD"
  if in_sh_open "route" ROUTE "$line" "$PWD" "auto"; then
    [[ "$IN_VIEW" == shell ]] && ! (( GT_BACK )) && { in_log_add open ROUTE "router/auto · in the glass" 1 0; snd coin }
    return 0
  fi
  return 1
}

# ── THE COMPOSER · type → rewrite → decide → hand to a vehicle ─────────────
# ⏎ IN THE FIELD SENDS.  The raw line is guarded first -- a secret is never
# sent out, not even to be rewritten -- and then a local model rewrites it and
# the tick carries the result to the gate.  With no local engine, the line is
# routed as it was typed rather than not at all.
in_route_send() {
  [[ -n "$IN_LINE" ]] || { say 'type a prompt first'; snd no; return 0 }
  in_guard_scan "$IN_LINE"
  (( IGS )) && { say "kept here · the prompt has ${IGS_WHAT}"; snd no; return 0 }
  # A TRIVIAL PROMPT IS ROUTED AS TYPED · a greeting or a short one-liner is no
  # better for a rewrite, and a small local model handed "rewrite Hello" tends to
  # paraphrase the instructions instead of the prompt.  So under eight words the
  # rewrite is skipped and the line itself is routed.
  local -a _w=(${=IN_LINE})
  if (( ${#_w[@]} < 8 )); then
    # TOO SHORT TO BE WORTH A MODEL · the keyword heuristic (freshness and all)
    # decides it, and it routes as typed.
    RT_PROMPT="$IN_LINE"; in_route_decide "$RT_PROMPT"; in_line_clear; in_route_gate; return 0
  fi
  rw_engines local
  if (( ${#RW_EK[@]} == 0 )); then
    # NO LOCAL MODEL TO REWRITE OR CLASSIFY ON · the heuristic stands in.
    RT_PROMPT="$IN_LINE"; in_route_decide "$RT_PROMPT"; in_line_clear; in_route_gate; return 0
  fi
  RW_ESEL=0; RW_PLAIN=1; RW_ROUTE=1
  if rw_start; then RT_STATE='rw'; in_line_clear; say 'rewriting · then routing'; snd pick
  else RW_ROUTE=0; RT_STATE=''; fi
  return 0
}

# FRESHNESS IS THE ONE SIGNAL A LOCAL MODEL CANNOT ARGUE WITH · it does not know
# today's facts at any size.  This is the HARD override: whatever else decides,
# a prompt that turns on current knowledge goes to the cloud.  Kept as its own
# helper because both the heuristic and the classifier's verdict defer to it.
in_route_fresh() {   # in_route_fresh TEXT -> IRF (1 if it needs current knowledge)
  emulate -L zsh; setopt extendedglob
  local t="${1:l}" w
  IRF=0
  for w in latest today 'this year' 'this week' 2026 2027 news 'right now' \
           'who is' 'who won' 'look up' 'up to date' 'state of' price 'stock price' \
           weather 'as of' 'this morning' 'yesterday' 'last night'; do
    [[ "$t" == *${w}* ]] && { IRF=1; return 0 }
  done
  return 0
}

# in_route_decide TEXT -> RT_KIND (local|cloud) · RT_WHY.  THE FALLBACK BRAIN.
# The real decision is a local classifier (in_route_classify); this keyword
# heuristic stands in when there is no local model to ask, when the classifier
# fails, or for a prompt too trivial to be worth a model call.  A subscription
# is a CLI the proxy cannot reach, so the local-vs-cloud fork is the cabinet's
# to make -- the dial tips the balance, the signals are only a lean.
in_route_decide() {
  emulate -L zsh; setopt extendedglob
  local t="${1:l}" w
  local -i hard=0 loc=0 cloud need
  in_route_fresh "$1"
  for w in research compare 'trade-off' tradeoff architecture 'design a' 'design the' \
           essay 'write a long' benchmark 'prove ' 'derive ' 'plan a' 'strategy'; do
    [[ "$t" == *${w}* ]] && (( hard++ ))
  done
  for w in fix refactor rename reformat format convert summar tidy lint typo \
           'this function' 'this file' 'this code' 'this snippet' regex docstring \
           'add a comment' 'explain this' 'rewrite this'; do
    [[ "$t" == *${w}* ]] && (( loc++ ))
  done
  (( ${#1} > 900 )) && (( hard++ ))
  (( ${#1} < 80 && ! IRF )) && (( loc++ ))
  cloud=$(( IRF * 3 + hard ))
  case $IN_RMODE in 0) need=2 ;; 1) need=0 ;; *) need=-2 ;; esac
  if (( cloud - loc > need )); then RT_KIND=cloud
    (( IRF )) && RT_WHY='needs current facts a local model would not have' \
              || RT_WHY='looks like it wants a frontier model'
  else RT_KIND=local; RT_WHY='a capable local model can take it'; fi
  return 0
}

# in_route_verdict TEXT -> RT_KIND · RT_WHY · 1 if the model was unclear.  Reads
# the classifier's answer: the first of LOCAL / CLOUD it names wins, and the
# short reason after the dash becomes the WHY the gate shows.  Freshness has the
# last word -- a model that said LOCAL to "who won last night" is overruled.
in_route_verdict() {
  emulate -L zsh
  local t="$1" u="${1:u}" reason pre
  local -i pc=999999 pl=999999
  [[ "$u" == *CLOUD* ]] && { pre="${u%%CLOUD*}"; pc=${#pre} }
  [[ "$u" == *LOCAL* ]] && { pre="${u%%LOCAL*}"; pl=${#pre} }
  (( pc == 999999 && pl == 999999 )) && return 1
  (( pl <= pc )) && RT_KIND=local || RT_KIND=cloud
  reason="${t##*[-–—]}"; reason="${reason%%$'\n'*}"
  reason="${reason## }"; reason="${reason%% }"
  if [[ -n "$reason" && ${#reason} -le 52 && "$reason" != "$t" ]]; then RT_WHY="$reason"
  elif [[ "$RT_KIND" == cloud ]]; then RT_WHY='a frontier model, the classifier judged'
  else RT_WHY='a local model, the classifier judged'; fi
  # FRESHNESS IS ON THE PROMPT, NOT THE ANSWER · a model that said LOCAL to a
  # question about today is overruled -- it cannot know, whatever it replied.
  in_route_fresh "$RT_PROMPT"
  (( IRF )) && { RT_KIND=cloud; RT_WHY='needs current facts a local model would not have' }
  return 0
}

# ── THE CLASSIFIER · the real decision, asked of a local model ─────────────
# The heuristic above is a lean on keywords; this is a judgment.  A fast, low-
# temperature call to a model already on this machine, told what a local model
# can and cannot do and dialled by the reader's preference, answering LOCAL or
# CLOUD with a reason.  It never leaves the machine (the guard cleared the
# prompt, and this asks a LOCAL model about it), it is short, and a failure or
# an unclear reply falls straight back to the heuristic -- so the router still
# decides even when the classifier will not.
typeset -g RC_LOG=''
typeset -gi RC_PID=0
typeset -gF RC_POLL=0.0 RC_T0=0.0
in_route_classify() {   # classify RT_PROMPT · async · RT_STATE='cls'
  if ! in_route_local_pick || (( ! ${+commands[curl]} )) || (( ! ${+commands[awk]} )); then
    in_route_decide "$RT_PROMPT"; in_route_gate; return 0
  fi
  in_tmp alien-cls || { in_route_decide "$RT_PROMPT"; in_route_gate; return 0; }
  RC_LOG="$ITMP"
  local cmd
  if (( IN_MOCK )); then
    in_route_decide "$RT_PROMPT"
    local mv="${(U)RT_KIND} - the mock classifier said so"
    cmd="print -rn -- $(_sh "$mv")"
  else
    local sys dial msgs body url bodyf
    case $IN_RMODE in
      0) dial='On a close call, prefer LOCAL, to keep it free and private.' ;;
      2) dial='On a close call, prefer CLOUD, for the stronger answer.' ;;
      *) dial='Pick whichever will genuinely do the better job.' ;;
    esac
    sys="You are a routing classifier for a local AI cabinet. Decide whether a small local model (about 8B parameters, running on the user's own laptop) can handle the request WELL, or whether it needs a large frontier cloud model. Local models are good at code edits, refactoring, explanations, summarising pasted text, quick questions and formatting. Local models CANNOT know current events, news, prices, sports results or anything recent, and they struggle with very long, deeply specialised or subtle reasoning. ${dial} Reply with EXACTLY one word, LOCAL or CLOUD, then ' - ' and a reason of at most eight words. Output nothing else."
    in_json_esc "$sys"; msgs="{\"role\":\"system\",\"content\":\"$IJE\"}"
    in_json_esc "$RT_PROMPT"; msgs+=",{\"role\":\"user\",\"content\":\"$IJE\"}"
    in_json_esc "$RT_LMODEL"
    body="{\"model\":\"$IJE\",\"stream\":true,\"temperature\":0.0,\"messages\":[$msgs]}"
    in_tmp alien-cls-body || { in_route_decide "$RT_PROMPT"; in_route_gate; return 0; }
    bodyf="$ITMP"; print -rn -- "$body" > "$bodyf" 2>/dev/null
    url="http://127.0.0.1:${IN_RPORT[$RT_LR]}/v1/chat/completions"
    cmd="curl -sN --max-time 60 -H 'Content-Type: application/json' --data-binary @$(_sh "$bodyf") $(_sh "$url") | ALIEN_USE=/dev/null awk $(_sh "$IN_SSE_AWK")"
  fi
  { zsh -lc "$cmd"; _rc=$?; print -r -- ""; print -r -- "__RC__ $_rc" } >>"$RC_LOG" 2>/dev/null </dev/null &!
  RC_PID=$!
  RT_STATE='cls'; RC_T0=$IN_NOW; RC_POLL=0.0
  say 'deciding where to send it'; snd pick
  return 0
}
in_route_classify_poll() {   # in_route_classify_poll T
  local -F t=$1
  local body rc
  [[ "$RT_STATE" == cls ]] || return 0
  (( t - RC_POLL < 0.2 )) && return 0
  RC_POLL=$t
  [[ -n "$RC_LOG" && -r "$RC_LOG" ]] || return 0
  body="$(<"$RC_LOG")" 2>/dev/null || body=''
  if [[ "$body" != *$'\n__RC__ '* ]]; then
    # A CLASSIFIER THAT WILL NOT ANSWER MUST NOT HANG THE COMPOSER · after a
    # minute, the heuristic decides and the gate opens anyway.
    (( t - RC_T0 > 60.0 )) && { in_tmp_drop "$RC_LOG"; RC_LOG=''; RT_STATE=''; in_route_decide "$RT_PROMPT"; in_route_gate }
    return 0
  fi
  rc="${body##*$'\n__RC__ '}"; rc="${rc%%$'\n'*}"
  body="${body%$'\n__RC__ '*}"
  in_tmp_drop "$RC_LOG"; RC_LOG=''; RC_PID=0; RT_STATE=''
  if [[ "$rc" == 0 ]] && in_route_verdict "$body"; then :
  else in_route_decide "$RT_PROMPT"; fi
  in_route_gate
  return 0
}

# in_route_target -> RT_DEST (sub|api|none) · RT_PROV · RT_AGENT.  PREFER A
# SIGNED-IN SUBSCRIPTION over a metered key -- a subscription is flat-rate and a
# key is per-token, and the reader said cost.  A subscription is reached only
# through its own CLI (RT_AGENT); a key is fronted by the proxy (RT_DEST=api).
in_route_target() {
  local -i p a
  RT_DEST=none; RT_PROV=-1; RT_AGENT=-1
  (( ${#IN_CLOUD_ST[@]} )) || in_cloud_scan
  local -a order=(1 0 2 3)     # Anthropic · OpenAI · Gemini · xAI, by general strength
  for p in $order; do
    a=${IN_PROV_AGENT[$p]}
    (( a >= 0 )) || continue
    case "${IA[$a.auth]:-}" in
      subscription|'signed in') RT_DEST=sub; RT_PROV=$p; RT_AGENT=$a; return 0 ;;
    esac
  done
  for (( p = 0; p < ${#IN_CLOUD_NAME[@]}; p++ )); do
    [[ "${IN_CLOUD_ST[$p]:-}" == key ]] && { RT_DEST=api; RT_PROV=$p; return 0 }
  done
  return 0
}

# in_route_gate · the rewrite is in RT_PROMPT · decide, resolve a destination,
# build the EXACT line, and raise the same confirm gate an install uses.  A
# subscription verdict names its CLI; everything else is the router.  Nothing
# runs until [Y] -- and the line shown is the line that runs.
in_route_gate() {   # RT_KIND is already set (by the classifier or the heuristic)
  local cmd='' who='' p
  RT_STATE=''
  if [[ "$RT_KIND" == local ]]; then
    # A LOCAL MODEL DIRECTLY · no router in the way.  Only if nothing local can
    # chat does it fall back to the proxy, which can still reach the cloud.
    if in_route_local_pick; then
      RT_DEST=local; who="$RT_LMODEL"
      cmd="$RT_LMODEL · ${IN_RNAME[$RT_LR]:l} :${IN_RPORT[$RT_LR]} · /v1/chat/completions"
    else
      RT_DEST=proxy; who='THE ROUTER'
    fi
  else
    in_route_target
    case "$RT_DEST" in
      sub)  who="${IN_NAME[$RT_AGENT]}"
            p="${IA[$RT_AGENT.path]:-${IN_BINS[$RT_AGENT]%% *}}"
            if [[ -n "${IN_ASK[$RT_AGENT]}" ]]; then cmd="$p ${IN_ASK[$RT_AGENT]} $(_sh "$RT_PROMPT")"
            else cmd="$p"; fi ;;
      api)  RT_DEST=proxy; who='THE ROUTER' ;;
      *)    RT_DEST=proxy; who='THE ROUTER' ;;
    esac
  fi
  if [[ "$RT_DEST" == proxy ]]; then
    [[ -n "$IOC_PATH" ]] || in_scan_opencode
    cmd="env OPENCODE_CONFIG=~/.local/state/alien/opencode-route.json ${IOC_PATH:-opencode} --model router/auto"
  fi
  IN_GATE_KIND='route'; IN_GATE_WHO="$who"; IN_GATE_LINE="$cmd"
  IN_GATE=1; modal_open; snd pick
  return 0
}

# [Y] on the route gate · open the vehicle the gate named.  For a subscription
# that is its official CLI on the rewritten prompt; for anything else it is
# opencode on router/auto, where the proxy makes the fine local-vs-metered call.
in_route_go() {
  case "$RT_DEST" in
    sub)   in_route_handoff ;;
    local) in_route_console_go ;;
    *)     (( ${+commands[pbcopy]} )) && [[ -n "$RT_PROMPT" ]] && print -rn -- "$RT_PROMPT" | pbcopy 2>/dev/null
           in_route_run
           [[ "$IN_VIEW" == shell ]] && say 'rewritten prompt copied · paste it into opencode' ;;
  esac
  RT_PROMPT=''
  return 0
}

# in_route_handoff · NEVER RISK THE ACCOUNT · a subscription is used only by
# running its own program.  Jump to CLOUD, land on the agent, and open its CLI
# on the rewritten prompt in a session of its own -- claude and codex and grok
# take it as a one-shot flag; an agent with no such flag opens and the prompt
# goes on the clipboard to paste.  No key, no token, no proxy, ever.
in_route_handoff() {
  local -i a=$RT_AGENT
  local p="${IA[$a.path]:-}" cmd
  (( a >= 0 )) || { say 'no subscription to route to'; snd no; return 1 }
  (( ${IA[$a.here]:-0} )) || { in_go_view cloud; IN_SEL=$a; say "${IN_NAME[$a]} · not on this machine · [I] installs it"; snd no; return 1 }
  [[ -n "$p" && -x "$p" ]] || { in_go_view cloud; IN_SEL=$a; say "${IN_NAME[$a]} · that binary will not run"; snd no; return 1 }
  in_go_view cloud; IN_SEL=$a
  in_short "$PWD"
  cmd="cd $(_sh "$PWD") && $(_sh "$p")"
  if [[ -n "${IN_ASK[$a]}" ]]; then cmd+=" ${IN_ASK[$a]} $(_sh "$RT_PROMPT")"
  elif (( ${+commands[pbcopy]} )); then print -rn -- "$RT_PROMPT" | pbcopy 2>/dev/null; fi
  if in_sh_open "${IN_BINS[$a]%% *}" "${IN_NAME[$a]}" "$cmd" "$PWD" "${IA[$a.model]:-}"; then
    [[ "$IN_VIEW" == shell ]] && ! (( GT_BACK )) && {
      in_log_add open "${IN_NAME[$a]}" "routed · a rewritten prompt, on your own account" 1 0
      [[ -z "${IN_ASK[$a]}" ]] && say 'opened · prompt copied, paste it in' || snd coin
    }
    return 0
  fi
  return 1
}

# in_route_local_pick -> RT_LMODEL · RT_LWHERE · RT_LR (runner idx), or fail.
# A LOCAL VERDICT NEEDS NO PROXY · the router is only for deciding local-vs-cloud,
# and that is already decided.  So a local prompt goes straight to a local model
# over HTTP -- which is why ROUTE works with the router down.  Prefer a model that
# is already resident (no load wait); an embedder cannot chat and is skipped.
in_route_local_pick() {
  RT_LMODEL=''; RT_LWHERE=''; RT_LR=-1
  local -i i r pick=-1 pickr=-1
  for (( i = 0; i < IM_N; i++ )); do
    case "${IM_WHERE[$i]}" in ollama) r=0 ;; gguf) r=1 ;; mlx) r=3 ;; *) continue ;; esac
    (( ${IR[$r.up]:-0} )) || continue
    in_model_verdict "${IM_NAME[$i]}"; [[ "$IMV" == embed ]] && continue
    in_is_resident "${IM_NAME[$i]}"
    if (( IRES )); then RT_LMODEL="${IM_NAME[$i]}"; RT_LWHERE="${IM_WHERE[$i]}"; RT_LR=$r; return 0; fi
    (( pick < 0 )) && { pick=$i; pickr=$r }
  done
  (( pick >= 0 )) || return 1
  RT_LMODEL="${IM_NAME[$pick]}"; RT_LWHERE="${IM_WHERE[$pick]}"; RT_LR=$pickr
  return 0
}

# [Y] on a LOCAL route · bind the console to the picked local model and send the
# rewritten prompt.  No router, no opencode, no clipboard -- the console speaks
# the runner's own endpoint and the answer streams in the glass.  A fresh session,
# so a routed prompt is not glued to whatever was said before.
in_route_console_go() {
  if ! in_route_local_pick; then say 'no local model here can chat · pull one on LOCAL'; snd no; return 0; fi
  in_chat_new
  CH_PINNED=$RT_LR; CH_RUNNER=$RT_LR; CH_MODEL="$RT_LMODEL"; CH_LOCK=1
  in_go_view console
  in_line_set "$RT_PROMPT"
  in_chat_send
  return 0
}
in_draw_route() {
  local -i i y col up=0
  # ON THE WHOLE WINDOW the full-width panels span the glass, the two half
  # panels split it and grow taller, and BUDGET and the job ride the footer
  local -i fw=102 lw=50 cx=54 cw=50 ph2=9 by=19 jy=24
  if (( SCR_W > 120 )); then
    fw=$(( SCR_W - 4 )); lw=$(( (SCR_W - 6) / 2 )); cx=$(( 2 + lw + 2 )); cw=$(( SCR_W - 2 - cx ))
    # THE TWO CHOOSERS ARE SIZED TO THEIR CONTENT · three modes and six providers
    # are all they ever hold, so stretching them to the glass only opened a void
    # under each.  The room they used to eat goes to the RECENT log below them.
    jy=$(( SCR_H - 6 )); by=$(( jy - 5 )); ph2=9
  fi
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  for (( i = 0; i < IN_RN; i++ )); do (( ${IR[$i.up]:-0} )) && (( up++ )); done
  local rtxt rcol ltxt lcol
  if (( IN_ROUTER_UP )); then rtxt="up · :${IN_RPROXY_PORT}"; cmix $WHITE $LIME 0.4; rcol=$CM
  else                        rtxt='not running'; rcol=$I_WARNC; fi
  if (( up )); then ltxt="$up up"; cmix $WHITE $LIME 0.4; lcol=$CM
  else              ltxt='none up'; lcol=$I_WARNC; fi
  in_head ROUTE 1 "${IN_RMODE_NAME[$IN_RMODE]}" ROUTER "$rtxt" $rcol LOCAL "$ltxt" $lcol MODELS "$IM_N" $I_WHITE

  in_panel 2 3 $fw 6 'SEND A PROMPT' 'rewritten, then routed — nothing runs until you confirm'
  if [[ "$RT_STATE" == rw || "$RT_STATE" == cls ]]; then
    cmix $WHITE $AMBER 0.5
    if [[ "$RT_STATE" == cls ]]; then
      in_ell "deciding on ${RT_LMODEL:-a local model} · local or a frontier model…" $(( fw - 6 ))
    else
      in_ell "rewriting on ${RW_ENGINE:-a local model} · then a local model decides…" $(( fw - 6 ))
    fi
    v_put 4 5 '◈' $CM; v_text 6 5 "$ELL" $CM
    cshade $GREY 0.9
    v_text 4 7 'the guard already cleared it · a secret would never have left this machine' $CS
  else
    in_draw_line 6 5 $(( fw - 10 )) 'type a prompt · ⏎ rewrites it and the router decides where it goes'
    cmix $WHITE $LIME 0.45;   v_put 4 7 '●' $CM; v_text 6 7 'LOCAL' $CM
    v_text 12 7 'free' $I_DIM
    cmix $WHITE $PURPLE 0.45; v_put 20 7 '●' $CM; v_text 22 7 'CLOUD' $CM
    v_text 28 7 'a metered key, via the router' $I_DIM
    cmix $WHITE $AMBER 0.45;  v_put 58 7 '●' $CM; v_text 60 7 'SUBSCRIPTION' $CM
    v_text 73 7 'its own CLI · never a token' $I_DIM
  fi

  in_panel 2 9 $lw $ph2 'PREFERENCE' '[M] cycles it'
  for (( i = 0; i < 3; i++ )); do
    y=$(( 11 + i * 2 ))
    if (( i == IN_RMODE )); then cmix $WHITE $AMBER 0.55; col=$CM; v_put 4 $y '▸' $col
    else cshade $GREY 0.85; col=$CS; fi
    v_text 6 $y "${IN_RMODE_NAME[$i]}" $col
    in_right $lw $y "${IN_RMODE_PCT[$i]}" $col
    v_text 8 $(( y + 1 )) "${IN_RMODE_DESC[$i]}" $I_DIM
  done

  (( ${#IN_CLOUD_ST[@]} )) || in_cloud_scan
  in_panel $cx 9 $cw $ph2 'CLOUD PROVIDERS' 'keys stay on this machine'
  for (( i = 0; i < ${#IN_CLOUD_NAME[@]} && i < 6; i++ )); do
    y=$(( 11 + i ))
    if [[ "${IN_CLOUD_ST[$i]:-}" == key ]]; then
      cmix $WHITE $LIME 0.4; v_text $(( cx + 2 )) $y "${IN_CLOUD_NAME[$i]}" $CM
      in_right $(( cx + cw - 2 )) $y 'routable' $I_OK
    else
      cshade $GREY 0.8; v_text $(( cx + 2 )) $y "${IN_CLOUD_NAME[$i]}" $CS
      in_right $(( cx + cw - 2 )) $y 'add a key' $I_DIM
    fi
  done

  # THE ROOM UNDER THE TWO CHOOSERS IS THE RECENT LOG · on a tall glass the page
  # would otherwise be two short panels over a void; the log fills it and says
  # what the router has actually been doing.  The float cabinet has no room for it.
  if (( SCR_W > 120 )); then
    local -i ry rh
    ry=$(( 9 + ph2 + 1 )); rh=$(( by - 1 - ry ))
    (( rh >= 4 )) && in_draw_recent $ry $rh
  fi

  if (( IN_ROUTER_UP )); then
    local -i cap=${IN_BUDGET_OPT[$IN_BUDGET_SEL]}
    in_panel 2 $by $fw 4 'BUDGET' 'metered cloud only · a subscription is flat-rate · [B] sets it'
    if (( cap > 0 )); then
      cmix $WHITE $LIME 0.4
      v_text 4 $(( by + 2 )) "\$$cap a day per provider · \$$(( cap * 30 )) a month over the lot · local is free" $CM
    else
      cshade $GREY 0.9
      v_text 4 $(( by + 2 )) 'no cap · [B] sets a daily limit per metered provider · local is always free' $CS
    fi
  else
    in_panel 2 $by $fw 4 'START THE ROUTER' '[G] writes the config from your keys'
    cmix $WHITE $AMBER 0.4
    in_ell "litellm --config ~/.local/state/alien/litellm.yaml --port $IN_RPROXY_PORT" $(( fw - 6 ))
    v_text 4 $(( by + 2 )) "$ELL" $CM
  fi

  if [[ -n "$IN_JOB_STATE" ]]; then in_draw_job $jy 3; fi
  if [[ "$IN_MODE" == edit ]];   then in_foot ⏎ 'rewrite & route' ⎋ cancel
  else                                in_foot ⏎ 'a prompt' O session M mode G config ◂▸ pages ⎋ menu; fi
  return 0
}

in_draw_local() {
  local -i i ix y on col bg rows=8 up=0 disk=0 mlxc=0 rfoc=0 rcol
  # ON THE WHOLE WINDOW the three panels widen, the model list grows to as
  # many rows as the glass is tall, and THIS MACHINE drops to the footer
  local -i fw=102 band=100 rs=0 tmy=21 odh=11
  if (( SCR_W > 120 )); then
    fw=$(( SCR_W - 4 )); band=$(( SCR_W - 6 )); rs=$(( fw - 102 ))
    tmy=$(( SCR_H - 8 )); odh=$(( tmy - 10 )); rows=$(( tmy - 13 ))
  fi
  local s base
  # THE FOCUS AS A NUMBER, because the two row loops below ask about it inside
  # $(( )) -- and `$(( "$IN_LFOCUS" == runner ))` is not a string comparison
  # there at all: arithmetic would go looking for a PARAMETER called `runner`,
  # and under `set -u` looking for one that does not exist ends the shell.
  [[ "$IN_LFOCUS" == runner ]] && rfoc=1
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  for (( i = 0; i < IN_RN; i++ )); do (( ${IR[$i.up]:-0} )) && (( up++ )); done
  for (( i = 0; i < IM_N; i++ )); do
    case "${IM_WHERE[$i]}" in gguf) (( disk++ )) ;; mlx) (( mlxc++ )) ;; esac
  done
  base='nothing serving'
  for (( i = 0; i < IN_RN; i++ )); do
    (( ${IR[$i.up]:-0} )) && { base="http://127.0.0.1:${IN_RPORT[$i]}/v1"; break }
  done
  if (( up )); then cmix $WHITE $LIME 0.4; col=$CM; else col=$I_LBL; fi
  if (( IZ_N )); then s="${IZ_SIZE[0]:-—}"; cmix $WHITE $LIME 0.4; rcol=$CM
  else s='none'; rcol=$I_LBL; fi
  local occ ocv
  in_oc_bad
  if (( IOCB )); then ocv="$IOC_VER · broken"; occ=$I_WARNC
  elif [[ -n "$IOC_PATH" ]]; then ocv="${IOC_VER:-here}"; cmix $WHITE $LIME 0.4; occ=$CM
  else ocv='none'; occ=$I_WARNC; fi
  in_head LOCAL 1 "$base" \
     RUNNERS "$up up" $col \
     MODELS "$IM_N" $I_WHITE \
     RESIDENT "$s" $rcol \
     OPENCODE "$ocv" $occ
  if (( IOCB )); then
    v_text 2 2 "opencode $IOC_VER fails every prompt, upstream · brew uninstall opencode && npm i -g opencode-ai@$IN_OC_GOOD" $I_WARNC
  fi

  # ── what could hold one ──
  if [[ "$IN_LFOCUS" == runner ]]; then s='▴▾ HERE · [S] STARTS IT'
  else                                  s='[⇥] TO MOVE HERE'; fi
  in_panel 2 3 $fw 7 RUNNERS "$s"
  v_text 10 4 RUNNER  $I_DIM
  v_text 26 4 BINARY  $I_DIM
  v_text 41 4 PORT    $I_DIM
  v_text 49 4 STATE   $I_DIM
  v_text 68 4 SERVING $I_DIM
  for (( i = 0; i < IN_RN && i < 4; i++ )); do
    y=$(( 5 + i ))
    if (( rfoc )); then in_glide local.r $IN_RSEL $i; else IGS=0.0; IGON=0; fi
    on=$IGON
    in_band 3 $y $band $IGS; bg=$IBG
    if (( ${IR[$i.up]:-0} ));     then in_ink ok
    elif (( ${IR[$i.here]:-0} )); then in_ink warn
    else                               in_ink no; fi
    (( on )) && { cmix $WHITE $LIME 0.3; v_put 4 $y '▸' $CM $bg }
    v_put 8 $y "$IID" $IIN $bg
    (( on )) && col=$I_WHITE || col=$I_LBL
    in_ell "${IN_RNAME[$i]}" 14; v_text 10 $y "$ELL" $col $bg
    (( on )) && col=$I_LBL || col=$I_DIM
    in_ell "${IN_RBIN[$i]}" 14;  v_text 26 $y "$ELL" $col $bg
    v_text 41 $y "${IN_RPORT[$i]}" $col $bg
    # `holds`, FOR OLLAMA: its list is every model it has, loaded on demand,
    # not what is in memory -- RESIDENT is that.  The other runners serve
    # what they were started on.
    if (( ${IR[$i.up]:-0} )); then
      if (( i == 0 )) && [[ -n "${IR[$i.served]:-}" ]]; then
        local -a held; held=("${(@s: · :)IR[$i.served]}")
        s="up · holds ${#held[@]}"
      else s='up · serving'; fi
    elif (( ${IR[$i.here]:-0} )); then s='installed, stopped'
    else                               s='not installed'; fi
    if (( on )); then col=$IIN; else cshade $IIN 0.75; col=$CS; fi
    # 18, WHICH IS WHAT THE HEADERS SAY.  STATE is at 49 and SERVING at 68;
    # `installed, not running` is 22 characters and ran three columns into the
    # next field, which is then drawn over it -- so the normal state of an
    # installed-but-stopped runner read `installed, not runn` jammed against
    # `brew install llama.cpp`, cut mid-word and with no ellipsis to say so.
    in_ell "$s" 18; v_text 49 $y "$ELL" $col $bg
    # THE LAST COLUMN IS THE NEXT THING TO DO, and which that is depends on
    # how far along this runner already is: what it is serving, or the line
    # that would start it, or the line that would put it here at all.
    if [[ -n "${IR[$i.served]:-}" ]]; then s="${IR[$i.served]}"; col=$I_FG
    elif (( ${IR[$i.up]:-0} ));      then s='up · holding nothing'; col=$I_FG
    elif (( ${IR[$i.here]:-0} ));    then s="${IN_RSTART[$i]}"; col=$I_DIM
    else                                  s="${IN_RGET[$i]}"; col=$I_DIM; fi
    in_ell "$s" $(( fw - 69 )); v_text 68 $y "$ELL" $col $bg
  done

  # ── and every model it could hold ──
  # PULLED IS OLLAMA'S WORD, so an MLX weight is not counted as one -- it is a
  # Hugging Face weight mlx_lm serves, and it earns its own tally the moment
  # there is one, the way the RUNNERS panel above already lists MLX on its own row.
  local counts="$disk GGUF · $(( IM_N - disk - mlxc )) PULLED"
  (( mlxc )) && counts+=" · $mlxc MLX"
  if [[ "$IN_LFOCUS" == runner ]]; then s="[⇥] TO MOVE HERE · $counts"
  else                                  s="▴▾ HERE · $counts"; fi
  in_panel 2 10 $fw $odh 'ON DISK' "$s"
  v_text 10 11 '#'     $I_DIM
  v_text 14 11 MODEL   $I_DIM
  v_text $(( 58 + rs )) 11 WHERE   $I_DIM
  v_text $(( 70 + rs )) 11 QUANT   $I_DIM
  in_right $(( 92 + rs )) 11 SIZE  $I_DIM
  if (( IM_N == 0 )); then
    v_text 14 13 'no model on this disk that this cabinet can see' $I_DIM
    v_text 14 15 'ollama pull qwen3:8b' $I_LBL
    v_text 14 16 '…or drop a .gguf in ~/models' $I_DIM
  fi
  in_scroll_into $IN_LSEL $IN_LTOP $rows $IM_N; IN_LTOP=$ITOP
  for (( i = 0; i < rows && i < IM_N; i++ )); do
    ix=$(( IN_LTOP + i ))
    (( ix >= IM_N )) && break
    y=$(( 12 + i ))
    if (( ! rfoc )); then in_glide local.m $IN_LSEL $ix; else IGS=0.0; IGON=0; fi
    on=$IGON
    in_band 3 $y $band $IGS; bg=$IBG
    in_is_resident "${IM_NAME[$ix]}"
    (( on )) && { cmix $WHITE $LIME 0.3; v_put 4 $y '▸' $CM $bg }
    if (( IRES )); then v_put 8 $y '●' $I_OK $bg
    else cshade $GREY 0.55; v_put 8 $y '○' $CS $bg; fi
    (( on )) && col=$AMBER || { cshade $AMBER 0.6; col=$CS }
    (( ix < 9 )) && v_text 10 $y "[$(( ix + 1 ))]" $col $bg
    (( on )) && col=$I_WHITE || col=$I_LBL
    in_ell "${IM_NAME[$ix]}" $(( 42 + rs )); v_text 14 $y "$ELL" $col $bg
    (( on )) && col=$I_LBL || col=$I_DIM
    v_text $(( 58 + rs )) $y "${IM_WHERE[$ix]}" $col $bg
    if (( on )); then cmix $WHITE $PURPLE 0.35; else cmix $I_DIM $PURPLE 0.5; fi
    v_text $(( 70 + rs )) $y "${IM_QUANT[$ix]:-—}" $CM $bg
    (( on )) && col=$I_FG || col=$I_LBL
    in_right $(( 92 + rs )) $y "${IM_SIZE[$ix]}" $col $bg
    # THE LAST WORD ON A ROW IS THE MOST LIVE THING ABOUT IT, in this order:
    # a model with an opencode session open (⏎ steps back in); one held in
    # memory (resident); or -- for the rest -- why it is NOT an opencode
    # target: an embedding model cannot chat, a chat-only model has no tools
    # for the agent to call, a small one parrots the prompt.  A tool-capable
    # model of a workable size gets no badge, which is the point: the bare
    # rows are the ones that drive opencode.
    # 94, NOT 95: eight letters from 95 end on 102, the scroll track's column.
    if in_sh_live "oc:${IM_NAME[$ix]}"; then
      if (( on )); then cmix $WHITE $LIME 0.4; col=$CM; else cshade $LIME 0.7; col=$CS; fi
      v_text $(( 94 + rs )) $y opencode $col $bg
    elif (( IRES )); then
      (( on )) && col=$I_OK || { cshade $I_OK 0.7; col=$CS }
      v_text $(( 94 + rs )) $y resident $col $bg
    else
      in_model_verdict "${IM_NAME[$ix]}"
      case "$IMV" in
        embed)   (( on )) && col=$I_LBL || col=$I_DIM;  v_text $(( 94 + rs )) $y embed      $col $bg ;;
        notools) (( on )) && col=$I_WARNC || { cshade $I_WARNC 0.7; col=$CS }; v_text $(( 94 + rs )) $y 'no tools' $col $bg ;;
        small)   (( on )) && col=$I_WARNC || { cshade $I_WARNC 0.7; col=$CS }; v_text $(( 94 + rs )) $y small      $col $bg ;;
      esac
    fi
  done
  # 102 IS THE LAST INTERIOR COLUMN; 103 is the box's right-hand border, and
  # drawing the track there repainted eight rows of the outline a shade darker
  # with a heavy ┃ set into it.  PROMPTS already gets this right.
  in_scroll_mark $fw 12 $rows $IN_LTOP $rows $IM_N

  # ── and what holding one costs ──
  # THE STRIP KEEPS THE LAST JOB, WHICH IS RIGHT; THE FOOTER MUST NOT.  This
  # tested `-n`, and IN_JOB_STATE is only ever cleared by intel_init -- so one
  # `ollama pull` replaced THIS MACHINE, RIGHT NOW with a finished job panel
  # for the rest of the session, dropped `[I]` and `⏎` from the footer though
  # both still worked, and advertised `[X] stop` with nothing to stop.
  if [[ -n "$IN_JOB_STATE" ]]; then
    in_draw_job $tmy 6
    if [[ "$IN_JOB_STATE" == run ]]; then
      in_foot ▴▾ choose ◂▸ pages X stop ⇥ 'runner/model' ⎋ menu
    elif [[ "$IN_LFOCUS" == runner ]]; then
      in_foot ▴▾ choose ◂▸ pages S 'start it' I 'a model' ⇥ 'runner/model' ⎋ menu
    else
      in_foot I 'a model' ⏎ 'chat or opencode' D 'keep it loaded' U remove ⇥ 'runner/model' ⎋ menu
    fi
    return 0
  fi
  in_panel 2 $tmy $fw 6 'THIS MACHINE, RIGHT NOW' 'SYSTEM HAS THE REST OF IT'
  in_size_g $IN_MEM_USED; s="$IGB"; in_size_g $IN_MEM_TOTAL
  in_meter 4 $(( tmy + 1 )) 22 $(( IN_MEM_TOTAL > 0.0 ? IN_MEM_PCT / 100.0 : 0.0 )) memory "$s of $IGB"
  printf -v s '%.2f · %d cores' $IN_LOAD $IN_NCPU
  in_meter 4 $(( tmy + 2 )) 22 $(( 1.0 * IN_LOAD / IN_NCPU )) load "$s"
  in_rpad thermal 9; v_text 4 $(( tmy + 3 )) "$IRP" $I_LBL
  if [[ -n "$IN_THERM" ]]; then
    v_text 14 $(( tmy + 3 )) throttled $I_HOT
  else
    v_text 14 $(( tmy + 3 )) "nominal · scheduler at ${IN_THERM_LIM}%" $I_FG
  fi
  if (( IZ_N )); then
    cmix $WHITE $PURPLE 0.35
    in_ell "${IZ_NAME[0]}" 30;  in_kv $(( 58 + rs )) $(( tmy + 1 )) resident "$ELL" 10 $CM
    cmix $WHITE $LIME 0.35
    in_kv $(( 58 + rs )) $(( tmy + 2 )) holding "${IZ_SIZE[0]:-—} · ${IZ_PROC[0]:-—}" 10 $CM
    in_ell "${IZ_UNTIL[0]:-you unload it}" 30; in_kv $(( 58 + rs )) $(( tmy + 3 )) until "$ELL" 10
  else
    v_text $(( 58 + rs )) $(( tmy + 1 )) 'nothing is resident' $I_LBL
    v_text $(( 58 + rs )) $(( tmy + 2 )) '[I] finds the right one for this machine' $I_DIM
    v_text $(( 58 + rs )) $(( tmy + 3 )) 'and installs it · ⏎ runs one in OpenCode' $I_DIM
  fi
  # ...AND ⏎ IS TWO DIFFERENT VERBS, so the footer names the one the cursor
  # is actually over rather than the one it is not.
  if [[ "$IN_LFOCUS" == runner ]]; then
    in_foot ▴▾ choose ◂▸ pages I 'install a model' ⏎ 'start it' ⇥ 'runner/model' ⎋ menu
  else
    in_foot I 'install' ⏎ 'chat or opencode' D 'keep it loaded' U remove ⇥ 'runner/model' ⎋ menu
  fi
  return 0
}

# IS THIS ROW THE THING THAT IS AWAKE?  `qwen3:8b` on disk and `qwen3:8b` in
# `ollama ps` are the same model; `qwen3:8b` and `qwen3:30b` are not.  This
# compared the part BEFORE the colon, which is the one test that calls those
# two the same -- so every size of a family lit `resident` when one of them
# was.  The whole name is compared, with the `:latest` ollama adds to a tag
# it was not given taken off both sides.
in_is_resident() {   # in_is_resident NAME -> IRES
  local a="${1%:latest}" b
  local -i i
  IRES=0
  [[ -n "$a" ]] || return 0
  for (( i = 0; i < IZ_N; i++ )); do
    b="${IZ_NAME[$i]%:latest}"
    [[ "$b" == "$a" ]] && { IRES=1; return 0 }
  done
  return 0
}

in_size_g() {   # in_size_g GIB -> IGB
  local -F v=$1
  if (( v >= 100.0 )); then printf -v IGB '%.0f gb' $v
  else                      printf -v IGB '%.1f gb' $v; fi
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# WHICH LOCAL MODEL THIS MACHINE SHOULD RUN IN OPENCODE
# ══════════════════════════════════════════════════════════════════════════
# CURATED, AND OPENCODE-READY BY CONSTRUCTION.  ⏎ on a model runs it in
# opencode, and opencode drives a model as an agent -- a big system prompt,
# tool schemas, a plan-mode reminder.  A model has to clear three bars to be
# worth offering: it must FIT this Mac, it must SUPPORT TOOLS, and it must be
# BIG ENOUGH to follow the agent (a 1.5B code-completion model parrots the
# prompt back instead).  The last two are settled here, by only listing models
# that pass them; the first is measured against the Mac at draw time.  So
# "filter out the ones with no tooling / too small for opencode" is not a
# runtime test -- it is what this list IS.
#
# EACH ROW CARRIES WHAT THE MACHINE CANNOT KNOW ABOUT A MODEL IT HAS NOT
# PULLED: how big the download is (disk), and the least RAM it wants to run at
# opencode's 64k context (which is not the file size -- the KV cache for 64k
# is gigabytes on top, and a mixture-of-experts model breaks any tidy
# params->RAM rule, so the minimum is curated per model rather than derived).
# A dated list, maintained like the version table above.
IN_CAT_TAG=('qwen2.5-coder:7b' 'qwen3:8b' 'qwen2.5-coder:14b' 'gpt-oss:20b' \
            'qwen3-coder:30b' 'qwen2.5-coder:32b' 'gpt-oss:120b')
IN_CAT_GB=(4.7 5.2 9.0 13.0 19.0 20.0 65.0)          # the download · disk
IN_CAT_RAM=(16 16 24 24 32 32 96)                    # least RAM to run at 64k context
IN_CAT_ROLE=(coding general coding reasoning coding coding reasoning)
IN_CAT_WHY=('the smallest that still drives opencode well' \
            'general-purpose, and it reasons before it answers' \
            'stronger on code, once the Mac has the memory for it' \
            'openai’s open reasoning model, mixture-of-experts' \
            'a MoE coder: 30B on disk, a fraction awake per token' \
            'top local coding, if this Mac can hold it' \
            'the largest worth running at home')
typeset -gi IN_CAT_N=7

# ── how the Mac is measured · RAM is the bar, and the tell ─────────────────
# THE DOWNLOAD IS DISK AND THE RUN IS RAM, and they are different numbers: a
# 20 GB model needs far more than 20 GB of memory once opencode's 64k context
# is loaded on top of it.  So the fit is the Mac's total RAM against the
# curated minimum, not the file size against a share of memory.
in_cat_fit() {   # in_cat_fit I -> ICFIT · 2 comfortable · 1 tight · 0 too big
  local -F ram=$IN_MEM_TOTAL
  local -i need=${IN_CAT_RAM[$1]}
  ICFIT=0
  (( ram + 0.5 >= need * 1.5 )) && { ICFIT=2; return 0 }
  (( ram + 0.5 >= need )) && ICFIT=1
  return 0
}

in_cat_here() {   # in_cat_here TAG -> ICH · 1 if ollama already holds it
  local -i j
  local a="${1%:latest}"
  ICH=0
  for (( j = 0; j < ${#IM_OL_NAME[@]}; j++ )); do
    [[ "${IM_OL_WHERE[$j]:-ollama}" == ollama ]] || continue
    [[ "${IM_OL_NAME[$j]%:latest}" == "$a" ]] && { ICH=1; return 0 }
  done
  return 0
}

in_pick() {   # in_pick -> IPICK · the biggest one that fits, else the smallest
  local -i i
  IPICK=0
  for (( i = IN_CAT_N - 1; i >= 0; i-- )); do
    in_cat_fit $i; (( ICFIT >= 1 )) && { IPICK=$i; return 0 }
  done
  return 0
}

# ── the chooser · every model in the catalogue, measured against this Mac ──
# THE ARITHMETIC IS THE SAME ONE IT ALWAYS WAS -- the largest that fits -- but
# the answer is a CURSOR POSITION rather than a decision.  Everything else is
# on the list too, so what this machine can and cannot hold is one screen
# instead of a sentence.
typeset -gi IN_PICK_OPEN=0 IN_PICKSEL=0

in_pick_open() {
  in_pick
  IN_PICKSEL=$IPICK
  IN_PICK_OPEN=1
  modal_open
  return 0
}
# 2 IS "FOLDING AWAY": the box is still drawn while it sits down, but it no
# longer answers keys
in_pick_close() { IN_PICK_OPEN=2; modal_close; return 0 }

# ONE ROW PER MODEL NOW, not two, because there are seven of them and the
# `why` is worth reading once for the model under the cursor rather than
# seven times down the list.  Every row is opencode-ready; what the row says
# is whether THIS Mac can hold it, and the cursor's row gets the sentence.
in_draw_pick() {
  local -i x=18 y=6 w=70 h=16 i yy col best=-1
  local s ram
  v_fill $x $y $w $h ' ' $GREY $GLASS
  in_size_g $IN_MEM_TOTAL; ram="$IGB"
  in_panel $x $y $w $h 'A LOCAL MODEL' "$ram OF RAM"
  in_pick; best=$IPICK
  v_text $(( x + 3 )) $(( y + 1 )) 'every one drives opencode · ★ is the best fit for this Mac' $I_LBL
  for (( i = 0; i < IN_CAT_N && i < 7; i++ )); do
    yy=$(( y + 3 + i ))
    in_cat_fit $i
    in_cat_here "${IN_CAT_TAG[$i]}"
    in_glide pick $IN_PICKSEL $i
    in_band $(( x + 1 )) $yy $(( w - 2 )) $IGS
    (( IGON )) && { cmix $WHITE $LIME 0.3; v_put $(( x + 2 )) $yy '▸' $CM $IBG }
    # the dot is the fit · lit when it runs comfortably, half when it is tight
    if   (( ICFIT == 2 )); then col=$I_OK; s='●'
    elif (( ICFIT == 1 )); then col=$I_WARNC; s='◐'
    else cshade $GREY 0.8; col=$CS; s='○'; fi
    v_put $(( x + 4 )) $yy "$s" $col $IBG
    (( IGON )) && col=$I_WHITE || col=$(( ICFIT ? I_LBL : I_DIM ))
    in_ell "${IN_CAT_TAG[$i]}" 20; v_text $(( x + 6 )) $yy "$ELL" $col $IBG
    (( IGON )) && { cmix $WHITE $PURPLE 0.35; col=$CM } || col=$I_DIM
    v_text $(( x + 27 )) $yy "${IN_CAT_ROLE[$i]}" $col $IBG
    printf -v s '%.1f GB' ${IN_CAT_GB[$i]}
    in_right $(( x + 46 )) $yy "$s" $(( ICFIT ? I_FG : I_DIM )) $IBG
    # the last word · already on the disk, the best pick, a plain fit, or the
    # RAM it would take that this Mac has not got.  The star and `here` can
    # both be true -- the best pick you already pulled -- so they combine
    # rather than one hiding the other.
    if (( ICH )); then
      (( i == best )) && s='★ here' || s='here ✓'
      cmix $WHITE $LIME 0.4; col=$CM
    elif (( i == best )); then cmix $WHITE $LIME 0.5; col=$CM; s='★ best'
    elif (( ICFIT == 2 )); then col=$I_OK; s='fits'
    elif (( ICFIT == 1 )); then col=$I_WARNC; s='tight'
    else col=$I_DIM; printf -v s 'needs %d GB' ${IN_CAT_RAM[$i]}; fi
    v_text $(( x + 49 )) $yy "$s" $col $IBG
  done
  # ── the sentence for the row under the cursor ──
  local -i sel=$IN_PICKSEL
  (( sel >= 0 && sel < IN_CAT_N )) || sel=0
  v_hline $(( x + 1 )) $(( y + 11 )) $(( w - 2 )) '─' $I_DIM
  cmix $WHITE $AMBER 0.4
  in_ell "${IN_CAT_WHY[$sel]}" $(( w - 6 ))
  v_text $(( x + 3 )) $(( y + 12 )) "$ELL" $CM
  in_cat_fit $sel
  if (( ICFIT == 0 )); then
    printf -v s 'this Mac has %s · %s wants %d GB to run well in opencode' "$ram" "${IN_CAT_TAG[$sel]}" ${IN_CAT_RAM[$sel]}
  else
    s='opencode wants 64k context · set OLLAMA_CONTEXT_LENGTH=65536'
  fi
  cshade $GREY 0.95
  in_ell "$s" $(( w - 6 )); v_text $(( x + 3 )) $(( y + 13 )) "$ELL" $CS
  in_foot ▴▾ choose ⏎ 'see the line' ⎋ 'not now'
  return 0
}

# ── and the one gate that downloads ───────────────────────────────────────
# THE SIZE, THE REASON, WHAT IT LEAVES THE MACHINE, AND THE EXACT LINE -- and
# then Y, or nothing happens at all.  It is the same gate CLOUD uses, given a
# row out of the catalogue rather than a row out of the roster, which is why
# there is only one of them.
in_pull_gate() {   # in_pull_gate IX
  local -i i=$1
  IN_GATE_KIND='pull'; IN_GATE_ROW=$i
  IN_GATE_WHO="${IN_CAT_TAG[$i]}"
  IN_GATE_LINE="ollama pull ${IN_CAT_TAG[$i]}"
  IN_PICK_OPEN=0
  IN_GATE=1
  modal_open
  return 0
}

# ── and the gate that takes one back off ──────────────────────────────────
# THE SAME GATE, GIVEN A MODEL OFF THE DISK LIST rather than a row off the
# catalogue: the exact line, what it deletes, and then Y or nothing.  IX is a
# JOINED-MODEL index -- the number the disk list draws against -- so the WHO,
# the WHERE and the PATH are all read with the one number and never crossed.
in_drop_gate() {   # in_drop_gate IX
  local -i i=$1
  IN_GATE_KIND='drop'; IN_GATE_ROW=$i
  IN_GATE_WHO="${IM_NAME[$i]}"
  in_model_rm_line "${IM_NAME[$i]}" "${IM_WHERE[$i]}" "${IM_PATH[$i]:-}"
  IN_GATE_LINE="$IRML"
  IN_GATE=1
  modal_open
  return 0
}

# ── ⏎ on a model row · hold it in memory ─────────────────────────────────
# LOADING IS A POST, NOT A COMMAND.  `ollama run` wants a terminal; what this
# page wants is the model RESIDENT and the cabinet still in front of you, and
# the empty-prompt generate with a keep_alive is exactly the request ollama
# provides for that.
in_load_line() {   # in_load_line NAME -> ILL
  ILL=''
  (( ${+commands[curl]} )) || return 1
  # THE MODEL NAME IS NOT MINE, so it does not go into a quoted JSON literal
  # on a command line.  It is scraped out of `ollama list` and out of a
  # runner's HTTP response, and a name containing an apostrophe would have
  # closed the quoting and left the rest of it running as shell.  The body
  # goes through the JSON escaper into a 0600 file and curl reads it from
  # there; nothing about the name is ever parsed by a shell.
  in_json_esc "$1"
  in_tmp alien-load || return 1
  print -rn -- "{\"model\":\"$IJE\",\"keep_alive\":\"30m\"}" > "$ITMP" 2>/dev/null
  ILL="curl -fsS --max-time 120 --data-binary @$(_sh "$ITMP") "
  ILL+="http://127.0.0.1:${IN_RPORT[0]}/api/generate >/dev/null && "
  local said="holding $1 for 30 minutes"
  ILL+="print -r -- ${(qq)said}"
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# A LINE YOU CAN TYPE ON · which is three pages' worth of this machine
# ══════════════════════════════════════════════════════════════════════════
# ONE KEY AT A TIME IS ALL A PACK EVER GETS, so the field is a string and an
# index into it and nothing more -- no readline, no history, no kill ring.
# What it does have is the four things a sentence needs to be typed and fixed:
# insert where the cursor is, take back the character behind it, and move.
#
# THE CURSOR IS A COUNT OF CHARACTERS BEFORE IT, not an index of one.  0 is in
# front of everything and ${#s} is past the end, which makes both ends of the
# line the same arithmetic as the middle -- and it is why the splice below
# takes the head and the tail SEPARATELY rather than as one subscript: under
# KSH_ARRAYS `${s[0,-1]}` is the whole string, so an insert at the very front
# written the obvious way duplicates the line instead of prepending to it.
IN_LINE=''
typeset -gi IN_LI=0
IN_MODE='nav'       # nav · edit

in_line_set() { IN_LINE="$1"; IN_LI=${#IN_LINE} }
in_line_clear() { IN_LINE=''; IN_LI=0 }

in_line_ins() {   # in_line_ins CH
  local ch="$1" h='' t=''
  [[ ${#ch} == 1 ]] || return 0
  [[ "$ch" == [[:print:]] ]] || return 0
  (( ${#IN_LINE} >= 480 )) && return 0
  (( IN_LI > 0 )) && h="${IN_LINE[0,$(( IN_LI - 1 ))]}"
  (( IN_LI < ${#IN_LINE} )) && t="${IN_LINE[$IN_LI,-1]}"
  IN_LINE="$h$ch$t"; (( IN_LI++ ))
  return 0
}

in_line_back() {
  local h='' t=''
  (( IN_LI > 0 )) || return 0
  (( IN_LI > 1 )) && h="${IN_LINE[0,$(( IN_LI - 2 ))]}"
  (( IN_LI < ${#IN_LINE} )) && t="${IN_LINE[$IN_LI,-1]}"
  IN_LINE="$h$t"; (( IN_LI-- ))
  return 0
}

# THE FIELD, DRAWN WITH ITS OWN WINDOW ONTO A LINE that may be longer than
# the box.  The window follows the CURSOR rather than the end of the string,
# because a reader who has gone back to fix a word at the front should be
# looking at the front.
in_draw_line() {   # in_draw_line X Y ROOM PLACEHOLDER [ACCENT]
  local -i x=$1 y=$2 room=$3 off=0 typing=0 bg acc=${5:--1}
  local txt
  (( acc < 0 )) && acc=$AMBER
  [[ "$IN_MODE" == edit ]] && typing=1
  if (( typing )); then cmix $GLASS $acc 0.16; else cmix $GLASS $acc 0.06; fi
  bg=$CM
  v_fill $(( x - 2 )) $y $(( room + 4 )) 1 ' ' $GREY $bg
  cmix $WHITE $acc 0.45
  v_put $(( x - 1 )) $y '▸' $CM $bg
  txt="$IN_LINE"
  (( off = (typing ? IN_LI : ${#txt}) - room ))
  (( off < 0 )) && off=0
  if [[ -z "$txt" ]] && (( ! typing )); then
    v_text $(( x + 1 )) $y "$4" $I_DIM $bg
  else
    in_ell "${txt[$off,$(( off + room - 1 ))]}" $room
    v_text $(( x + 1 )) $y "$ELL" $I_WHITE $bg
  fi
  if (( typing )) && { (( IN_NOW - IN_KEY_AT < 0.5 )) || (( (int(IN_NOW * MO_BLINK) & 1) == 0 )); }; then
    # THE CARET BLINKS ON THE HOUSE RATE, and holds solid for half a second
    # after every keystroke so it is never missing while you are typing
    cmix $WHITE $acc 0.7
    v_put $(( x + 1 + (IN_LI - off > room ? room : IN_LI - off) )) $y '▏' $CM $bg
  fi
  return 0
}
typeset -gF IN_KEY_AT=-100.0

# EVERY KEY WHILE THE FIELD IS LIVE IS THE FIELD'S, and that is the whole
# rule: a handler that let one through would be a cabinet that powers off
# halfway through the word `question`.
in_line_key() {   # in_line_key KEY — 0 always; the caller is in edit mode
  local k="$1"
  IN_KEY_AT=$IN_NOW
  case "$k" in
    left)     (( IN_LI > 0 )) && (( IN_LI-- )) ;;
    right)    (( IN_LI < ${#IN_LINE} )) && (( IN_LI++ )) ;;
    up)       IN_LI=0 ;;
    down)     IN_LI=${#IN_LINE} ;;
    back)     in_line_back ;;
    $'\x01')  IN_LI=0 ;;                       # ^A
    $'\x05')  IN_LI=${#IN_LINE} ;;             # ^E
    $'\x15')  in_line_clear ;;                 # ^U
    $'\x17')                                   # ^W — back one word
      while (( IN_LI > 0 )) && [[ "${IN_LINE[$(( IN_LI - 1 )),$(( IN_LI - 1 ))]}" == ' ' ]]; do
        in_line_back
      done
      while (( IN_LI > 0 )) && [[ "${IN_LINE[$(( IN_LI - 1 )),$(( IN_LI - 1 ))]}" != ' ' ]]; do
        in_line_back
      done ;;
    enter|esc) : ;;                            # the caller's, not the field's
    *)        in_line_ins "$k" ;;
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# BENCH · one prompt, every engine that can answer one, side by side
# ══════════════════════════════════════════════════════════════════════════
# THREE AT ONCE, IN THREE EMPTY DIRECTORIES.  These are AGENTS: given a
# working directory with something in it they will read it, and some of them
# will write to it.  The bench is for QUESTIONS, so every run is started in a
# scratch directory of its own with nothing in it -- which is not a sandbox
# and is not claimed to be one on the page.  The agent still runs as you.
#
# AND THE NUMBERS ARE MEASURED, not divided out at the end: the first-byte
# figure is when the log stopped being empty, and the finish is when the
# run's own exit status was written to it.
IN_ASK_INK=(0 0 0)
typeset -ga BN_NAME BN_MODEL BN_LOG BN_STATE BN_TEXT BN_DIR BN_PID
typeset -ga BN_T0 BN_FIRST BN_END BN_RC
typeset -ga BN_TOP                     # per column · the first line shown · -1 is the page's own choice
typeset -gi BN_N=0
typeset -gF BN_START=0.0 BN_POLL=0.0
BN_PROMPT=''
BN_CWD=''

in_askable() {   # in_askable -> IASK, the rows that can answer one question
  local -i i
  IASK=()
  for (( i = 0; i < IN_N; i++ )); do
    (( ${IA[$i.here]:-0} )) || continue
    [[ -n "${IN_ASK[$i]}" ]] || continue
    [[ "${IA[$i.state]:-no}" == no ]] && continue
    IASK+=($i)
  done
  return 0
}

in_bench_start() {
  local -i i n=0
  local dir cmd
  in_askable
  (( ${#IASK[@]} )) || { say 'nothing here can answer one question and stop'; snd no; return 1 }
  [[ -n "$IN_LINE" ]] || { say 'no question to ask'; snd no; return 1 }
  # WHATEVER IS STILL GOING STOPS FIRST.  [A] again used to reset every BN_*
  # array without touching the three agents behind them: they kept running,
  # kept writing to logs nothing read any more, and kept spending -- on a page
  # whose own verdict line says `real calls · on your own account`.
  in_bench_stop
  in_bench_sweep
  BN_NAME=(); BN_MODEL=(); BN_LOG=(); BN_STATE=(); BN_TEXT=(); BN_PID=()
  BN_DIR=(); BN_T0=(); BN_FIRST=(); BN_END=(); BN_RC=(); BN_N=0; BN_TOP=()
  BN_PROMPT="$IN_LINE"; BN_START=$IN_NOW; BN_CWD=''
  for i in "${IASK[@]}"; do
    (( n >= 3 )) && break
    in_tmpdir alien-bench || continue
    dir="$ITMP"
    [[ -n "$BN_CWD" ]] || BN_CWD="$dir"
    BN_NAME+=("${IN_NAME[$i]}"); BN_MODEL+=("${IA[$i.model]:-default}")
    BN_DIR+=("$dir")
    BN_LOG+=("$dir/out")
    cmd="cd $(_sh "$dir") && $(_sh "${IA[$i.path]}")"
    cmd+=" ${IN_ASK[$i]} $(_sh "$BN_PROMPT")"
    BN_STATE+=(running); BN_TEXT+=(''); BN_RC+=(0); BN_TOP+=(-1)
    BN_T0+=($IN_NOW); BN_FIRST+=(0.0); BN_END+=(0.0)
    (( IN_MOCK )) && cmd="$IN_MOCK_ASK"
    : > "$dir/out" 2>/dev/null
    { zsh -lc "$cmd"; print -r -- "__RC__ $?" } >"$dir/out" 2>&1 </dev/null &!
    BN_PID+=($!)
    (( n++ ))
  done
  BN_N=$n
  (( BN_N )) || { say 'could not make a scratch directory'; snd no; return 1 }
  snd pick
  return 0
}

in_bench_live() {   # -> IBLIVE
  local -i i
  IBLIVE=0
  for (( i = 0; i < BN_N; i++ )); do
    [[ "${BN_STATE[$i]}" == running ]] && { IBLIVE=1; return 0 }
  done
  return 0
}

in_bench_poll() {   # in_bench_poll T
  local -F t=$1
  local body line
  local -i i
  (( BN_N )) || return 0
  in_bench_live
  (( IBLIVE )) || return 0
  (( t - BN_POLL < 0.25 )) && return 0
  BN_POLL=$t
  for (( i = 0; i < BN_N; i++ )); do
    [[ "${BN_STATE[$i]}" == running ]] || continue
    [[ -r "${BN_LOG[$i]}" ]] || continue
    # `$(<file)` IS A READ, NOT A FORK.  Three of these a quarter-second is
    # three processes a quarter-second if it is written `$(cat …)`, on a
    # surface that is already running three agents.
    body="$(<"${BN_LOG[$i]}")" 2>/dev/null || body=''
    [[ -n "$body" ]] && (( ${BN_FIRST[$i]} == 0.0 )) && BN_FIRST[$i]=$(( t - ${BN_T0[$i]} ))
    if [[ "$body" == *'__RC__ '* ]]; then
      line="${body##*__RC__ }"; line="${line%%$'\n'*}"
      BN_RC[$i]=${line:-0}
      BN_END[$i]=$(( t - ${BN_T0[$i]} ))
      (( ${BN_RC[$i]} == 0 )) && BN_STATE[$i]=done || BN_STATE[$i]=failed
      body="${body%__RC__*}"
    fi
    # AN AGENT'S ANSWER IS TEXT ONLY ONCE ITS COLOUR IS TAKEN OFF.  One of
    # them prints in green; read raw, the escape went into the column and
    # out to the terminal.  Line by line, so the paragraphs keep their shape.
    if [[ "$body" == *[[:cntrl:]]* ]]; then
      local -a bl; local out=''
      bl=("${(@f)body}")
      for line in "${bl[@]}"; do in_plain "$line"; out+="$IPL"$'\n'; done
      body="${out%$'\n'}"
    fi
    BN_TEXT[$i]="$body"
  done
  in_bench_live
  (( IBLIVE )) || {
    snd coin
    # WHAT WAS ASKED IS NOT WRITTEN DOWN, and the page two keys away says so
    # in as many words.  This used to log `$BN_PROMPT` -- the entire question
    # somebody typed -- into the column HISTORY draws under the header WHAT,
    # four rows above the line `no prompt and no answer is ever written here`.
    # What belongs in a log of runs is the run: who answered, how many of them
    # came back clean, and how long it took.
    local -i ok=0 ndone=0 i
    for (( i = 0; i < BN_N; i++ )); do
      [[ "${BN_STATE[$i]}" == done ]] && { (( ok++ )); (( ndone++ )) }
      [[ "${BN_STATE[$i]}" == failed || "${BN_STATE[$i]}" == stopped ]] && (( ndone++ ))
    done
    in_log_add bench "${(j:, :)BN_NAME[@]}" \
               "$ok of $BN_N answered" $(( ok > 0 )) $(( t - BN_START ))
  }
  return 0
}

in_bench_stop() {
  local -i i
  (( BN_N )) || return 1
  for (( i = 0; i < BN_N; i++ )); do
    [[ "${BN_STATE[$i]}" == running ]] || continue
    (( ${BN_PID[$i]:-0} > 1 )) && in_kill_tree ${BN_PID[$i]}
    BN_PID[$i]=0
    BN_STATE[$i]=stopped; BN_END[$i]=$(( IN_NOW - ${BN_T0[$i]} ))
  done
  return 0
}

# THE SCRATCH DIRECTORIES GO WITH THEM.  Three a run, never removed, is a
# /tmp that grows all session and holds whatever the agents wrote in them.
in_bench_sweep() {
  local d
  for d in "${BN_DIR[@]}"; do in_tmp_drop "$d"; done
  BN_DIR=()
  return 0
}

# A DIGIT KEEPS ONE, which means the clipboard: the answer is already on the
# glass and what a reader wants next is it somewhere else.  pbcopy is the
# Mac's, and a machine without it says so rather than pretending it worked.
in_bench_keep() {   # in_bench_keep I
  local -i i=$1
  (( i >= 0 && i < BN_N )) || { snd no; return 0 }
  if (( ! ${+commands[pbcopy]} )); then
    say 'no pbcopy on this machine'; snd no; return 0
  fi
  print -rn -- "${BN_TEXT[$i]}" | pbcopy 2>/dev/null
  say "${BN_NAME[$i]} · copied"; snd coin
  return 0
}

in_human_n() {   # in_human_n N -> IHN
  local -F n=$1
  if   (( n >= 1000000.0 )); then printf -v IHN '%.1fM' $(( n / 1000000.0 ))
  elif (( n >= 1000.0 ));    then printf -v IHN '%.1fk' $(( n / 1000.0 ))
  else                            printf -v IHN '%d' $(( int(n) )); fi
  return 0
}

in_draw_bench() {
  local -i i j y x col ink W=34 live=0 nd=0 keep
  # ON THE WHOLE WINDOW the answer columns widen and grow taller (more of each
  # answer visible), and the stats, caption and verdict ride the footer
  local -i fw=102 vy=26 cy=25 aph=18 hly=19 sty=20 nlines=11
  if (( SCR_W > 120 )); then
    fw=$(( SCR_W - 4 )); vy=$(( SCR_H - 3 )); cy=$(( vy - 1 ))
    aph=$(( cy - 7 )); hly=$(( cy - 6 )); sty=$(( cy - 5 )); nlines=$(( cy - 14 ))
  fi
  local s body
  local -F el=0.0 v
  local -a lines
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  in_bench_live; live=$IBLIVE
  (( BN_START > 0.0 )) && el=$(( IN_NOW - BN_START ))
  # `done`, NOT `not running`.  After [X] the header read ANSWERED 3 of 3
  # over three columns that had been cut off mid-sentence.
  for (( i = 0; i < BN_N; i++ )); do
    [[ "${BN_STATE[$i]}" == done ]] && (( nd++ ))
  done
  if   (( live )); then printf -v s 'asking · %.1fs' $el
  elif (( BN_N ));  then printf -v s 'all in · %.1fs' $el
  else                   s='a scratch directory, not yours'; fi
  if (( BN_N )); then
    if (( live )); then col=$I_LBL; else cmix $WHITE $LIME 0.4; col=$CM; fi
    in_head BENCH 1 "$s" ENGINES "$BN_N" $I_WHITE ANSWERED "$nd of $BN_N" $col
  else
    in_head BENCH 1 "$s" ENGINES '—' $I_WHITE ANSWERED '—' $I_LBL
  fi

  # ── the line you type on ──
  (( live )) && s='[X] STOP' || s='[⏎] ASK'
  in_panel 2 3 $fw 4 PROMPT "$s"
  in_draw_line 6 4 $(( fw - 8 )) 'press ⏎ and type a question'
  # THE CAVEAT GOES FIRST, because in_ell keeps the HEAD of a line and of the
  # two halves the path is the one to lose.
  if [[ -n "$BN_CWD" ]]; then
    in_short "$BN_CWD"
    s="a scratch cwd, not a sandbox · the agent runs as you · asked in $SHT"
  else
    s='every installed agent with a one-shot form answers at once · the run is in a scratch directory'
  fi
  in_ell "$s" $(( fw - 6 ))
  v_text 6 5 "$ELL" $I_DIM

  # ── who would answer, before anyone has ──
  if (( BN_N == 0 )); then
    in_bench_who
    if [[ "$IN_MODE" == edit ]]; then
      in_foot ⏎ ask ⎋ 'leave the field' ⌫ 'take one back'
    else
      in_foot ⏎ 'type a prompt' C cloud O console ⎋ menu
    fi
    return 0
  fi

  # ── and the answers ──
  # THE COLUMNS SHARE THE WIDTH.  Two engines drew two thirds of the row and
  # left the last third dark; one engine drew a third.  102 is what there is.
  W=$(( fw / (BN_N < 3 ? BN_N : 3) ))
  for (( i = 0; i < BN_N && i < 3; i++ )); do
    x=$(( 2 + i * W ))
    ink=${IN_ASK_INK[$i]}
    in_ell "${BN_NAME[$i]}" 14; s="$ELL"
    in_ell "${BN_MODEL[$i]}" 13
    in_panel $x 7 $W $aph "$s" "$ELL"
    body="${BN_TEXT[$i]}"
    body="${body//$'\t'/  }"
    [[ -n "${body//[[:space:]]/}" ]] || {
      [[ "${BN_STATE[$i]}" == running ]] && body='…' || body='(nothing came back)'
    }
    in_wrap_keep "$body" $(( W - 4 ))
    # A RUNNING COLUMN SHOWS ITS TAIL and a finished one its head: while an
    # answer is arriving the new words are the interesting end, and once it
    # has stopped the beginning is.  A column the reader has wheeled shows
    # the line they stopped on instead, until they wheel it back.
    if (( ${BN_TOP[$i]:--1} >= 0 )); then
      keep=${BN_TOP[$i]}
      (( keep > ${#WRP[@]} - nlines )) && keep=$(( ${#WRP[@]} - nlines ))
      (( keep < 0 )) && keep=0
    elif [[ "${BN_STATE[$i]}" == running ]] && (( ${#WRP[@]} > nlines )); then
      keep=$(( ${#WRP[@]} - nlines ))
    else
      keep=0
    fi
    for (( j = 0; j + keep < ${#WRP[@]} && j < nlines; j++ )); do
      v_text $(( x + 2 )) $(( 8 + j )) "${WRP[$(( j + keep ))][0,$(( W - 5 ))]}" $I_LBL
    done
    (( ${#WRP[@]} > nlines )) && in_scroll_mark $(( x + W - 2 )) 8 $nlines $keep $nlines ${#WRP[@]}
    v_hline $(( x + 1 )) $hly $(( W - 2 )) '─' $I_DIM
    case "${BN_STATE[$i]}" in
      running) col=$ink ;;
      done)    col=$I_OK ;;
      *)       col=$I_WARNC ;;
    esac
    if (( ${BN_FIRST[$i]} > 0.0 )); then printf -v s '%.1fs' ${BN_FIRST[$i]}; else s='—'; fi
    in_kv2 $(( x + 2 )) $sty $(( x + W - 3 )) 'first byte' "$s" $I_FG
    if [[ "${BN_STATE[$i]}" == running ]]; then
      printf -v s '%.1fs …' $(( IN_NOW - ${BN_T0[$i]} ))
    else
      printf -v s '%.1fs' ${BN_END[$i]}
    fi
    in_kv2 $(( x + 2 )) $(( sty + 1 )) $(( x + W - 3 )) finished "$s" $col
    in_human_n $(( ${#BN_TEXT[$i]} / 4.0 ))
    in_kv2 $(( x + 2 )) $(( sty + 2 )) $(( x + W - 3 )) output "≈ $IHN tokens" $I_FG
    case "${BN_STATE[$i]}" in
      running) s='still going' ;;
      done)    s='clean' ;;
      *)       s="${BN_STATE[$i]}" ;;
    esac
    in_kv2 $(( x + 2 )) $(( sty + 3 )) $(( x + W - 3 )) ended "$s" $col
    # ROW 25 IS OUTSIDE THE PANEL NOW.  The box used to be 19 tall, which put
    # its bottom border on exactly this row, and the caption punched a hole in
    # the outline of all three columns.
    v_text $(( x + 2 )) $cy "[$(( i + 1 ))] keeps this one" $I_DIM
  done

  # ── the verdict, on its own lit bar ──
  cmix $GLASS $AMBER 0.22; local -i vb=$CM
  v_fill 2 $vy $fw 1 ' ' $GREY $vb
  v_text 4 $vy VERDICT $I_LBL $vb
  if (( live )); then
    printf -v s 'still asking · %.1fs' $el
    v_text 13 $vy "$s" $I_FG $vb
  else
    in_bench_verdict
    x=13
    if (( BFAST >= 0 )); then
      v_text $x $vy fastest $I_LBL $vb
      in_ell "${BN_NAME[$BFAST]}" 12; s="$ELL"
      printf -v s '%s %.1fs' "$s" ${BN_END[$BFAST]}
      cmix $WHITE $LIME 0.4
      v_text $(( x + 8 )) $vy "$s" $CM $vb
      x=$(( x + 10 + ${#s} ))
    fi
    # THE RIGHT-HAND CAPTION IS FIXED AT COLUMNS 71-102, so what is left for
    # `longest` is whatever the `fastest` half did not take -- and a long
    # agent name beside a three-figure time pushed the token count under it.
    if (( BMOST >= 0 && x + 8 < 70 )); then
      v_text $x $vy longest $I_LBL $vb
      in_human_n $(( ${#BN_TEXT[$BMOST]} / 4.0 ))
      in_ell "${BN_NAME[$BMOST]}" 12
      cmix $WHITE $CYAN 0.4
      in_ell "$ELL ≈ $IHN tok" $(( 69 - x - 8 ))
      v_text $(( x + 8 )) $vy "$ELL" $CM $vb
    fi
    in_right $fw $vy 'real calls · on your own account' $I_DIM $vb
  fi
  if [[ "$IN_MODE" == edit ]]; then
    in_foot ⏎ ask ⎋ 'leave the field' ⌫ 'take one back'
  elif (( live )); then
    in_foot X stop ◂▸ pages 1-3 keep ⎋ menu
  else
    in_foot ⏎ 'ask again' A again 1-3 keep ◂▸ pages ⎋ menu
  fi
  return 0
}

in_bench_verdict() {   # -> BFAST BMOST
  local -i i
  local -F best=0.0 most=-1.0 v
  BFAST=-1; BMOST=-1
  for (( i = 0; i < BN_N; i++ )); do
    if [[ "${BN_STATE[$i]}" == done ]]; then
      if (( BFAST < 0 || ${BN_END[$i]} < best )); then BFAST=$i; best=${BN_END[$i]}; fi
    fi
    v=$(( ${#BN_TEXT[$i]} + 0.0 ))
    (( v > most )) && { BMOST=$i; most=$v }
  done
  return 0
}

# ── who would answer · the page before there is anything to compare ───────
in_bench_who() {
  local -i i n y
  local -a cant
  local -i fw=$(( SCR_W > 120 ? SCR_W - 4 : 102 )) ph=$(( SCR_W > 120 ? SCR_H - 12 : 18 ))
  in_askable
  in_panel 2 8 $fw $ph 'WHO WOULD ANSWER' 'THREE AT A TIME'
  v_text 4 9 'One prompt, sent to the first three of these at the same moment:' $I_LBL
  n=${#IASK[@]}
  for (( i = 0; i < n && i < 3; i++ )); do
    v_put 4 $(( 11 + i )) '●' ${IN_ASK_INK[$i]}
    in_ell "${IN_NAME[${IASK[$i]}]}" 16; in_rpad "$ELL" 17
    v_text 6 $(( 11 + i )) "$IRP" $I_WHITE
    in_ell "${IA[${IASK[$i]}.model]:-default}" 22; in_rpad "$ELL" 23
    cmix $WHITE $PURPLE 0.35
    v_text 24 $(( 11 + i )) "$IRP" $CM
    in_ell "${IA[${IASK[$i]}.bin]} ${IN_ASK[${IASK[$i]}]} …" $(( fw - 52 ))
    v_text 48 $(( 11 + i )) "$ELL" $I_DIM
  done
  (( n )) || v_text 6 11 'nothing installed here can answer one question and stop' $I_DIM
  y=15
  if (( n > 3 )); then
    v_text 4 $y 'Here too, and next in line:' $I_LBL
    for (( i = 3; i < n && i < 6; i++ )); do
      cshade $GREY 0.6
      v_put 4 $(( y + i - 2 )) '○' $CS
      in_ell "${IN_NAME[${IASK[$i]}]}" 16; in_rpad "$ELL" 17
      v_text 6 $(( y + i - 2 )) "$IRP" $I_LBL
      in_ell "${IA[${IASK[$i]}.model]:-default}" 22
      cmix $I_DIM $PURPLE 0.6
      v_text 24 $(( y + i - 2 )) "$ELL" $CM
    done
    y=$(( y + 2 + (n - 3 > 3 ? 3 : n - 3) ))
  fi
  # LEFT OUT ON PURPOSE, and the page says which and why.  An agent with no
  # one-shot form is not broken and not missing -- it is a program that wants
  # a terminal, which is what ⏎ on CLOUD is for.
  cant=()
  for (( i = 0; i < IN_N; i++ )); do
    (( ${IA[$i.here]:-0} )) || continue
    [[ -n "${IN_ASK[$i]}" ]] && continue
    cant+=($i)
  done
  if (( ${#cant[@]} )); then
    v_text 4 $y 'Left out on purpose:' $I_LBL
    for (( i = 0; i < ${#cant[@]} && i < 2; i++ )); do
      cshade $GREY 0.55
      v_put 4 $(( y + 1 + i )) '○' $CS
      in_ell "${IN_NAME[${cant[$i]}]}" 16; in_rpad "$ELL" 17
      v_text 6 $(( y + 1 + i )) "$IRP" $I_LBL
      v_text 24 $(( y + 1 + i )) 'no one-shot form — ⏎ on CLOUD opens it in the glass' $I_DIM
    done
  fi
  v_text 4 $(( ph + 6 )) 'Every run happens in an empty temporary directory. These are agents; the bench is for questions.' $I_DIM
  return 0
}

# TWO HALVES OF A ROW, ONE LEFT AND ONE RIGHT, which is the shape every
# figure in a bench column has and nothing else on this machine does.
in_kv2() {   # in_kv2 X Y XEND LABEL VALUE [COL]
  v_text $1 $2 "$4" $I_LBL
  in_ell "$5" 18
  in_right $3 $2 "$ELL" ${6:--2}
  return 0
}

# WRAP THAT KEEPS THE BLANK LINES, because an agent's answer is paragraphs and
# code, and in_wrap's habit of dropping empty lines turns a listing into one
# run-on block.  Leading spaces survive too: they are the indentation.
in_wrap_keep() {   # in_wrap_keep TEXT W -> WRP
  local -i w=$2 i
  local para line word pad
  local -a paras
  # QUOTED, AND INTO AN ARRAY.  Unquoted `${(f)…}` is word splitting, and word
  # splitting DROPS the empty fields -- which are exactly the blank lines this
  # function exists to keep.  A two-paragraph answer came back as one.
  paras=("${(@f)1}")
  WRP=()
  for para in "${paras[@]}"; do
    if [[ -z "${para//[[:space:]]/}" ]]; then WRP+=(''); continue; fi
    pad=''
    while [[ "$para" == ' '* ]]; do pad+=' '; para="${para# }"; done
    (( ${#pad} > w / 2 )) && pad="${pad[0,$(( w / 2 - 1 ))]}"
    line=''
    for word in ${=para}; do
      if (( ${#line} + ${#word} + 1 + ${#pad} > w )); then
        [[ -n "$line" ]] && WRP+=("$pad$line")
        line="$word"
      else
        line="${line:+$line }$word"
      fi
      (( ${#WRP[@]} > 200 )) && break
    done
    [[ -n "$line" ]] && WRP+=("$pad$line")
    (( ${#WRP[@]} > 200 )) && break
  done
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# CONSOLE · one session on the local model, with the machine beside it
# ══════════════════════════════════════════════════════════════════════════
# IT DOES NOT WRAP ANOTHER PROGRAM.  It speaks the OpenAI-compatible endpoint
# every local runner already serves, which is why the numbers on the right are
# real: the rate is measured from what has ARRIVED rather than divided out at
# the end, the first-token figure is when the stream stopped being empty, and
# the token counts are the model's own out of its usage block.
#
# IT HAS NO FILE OF YOURS, WHICH IS NOT THE SAME AS TOUCHING NO FILE.  HTTP is
# the only verb it has -- there is no tool call here, nothing that opens a
# path you name, nothing an answer can ask it to read.  What it does write is
# its own scratch: the request body and the arriving answer, both 0600, both
# in $TMPDIR, both removed when the session is cleared or the cabinet closes.
# The page says that rather than the shorter, wronger sentence it used to.
#
# THE EXTRACTION IS AWK'S, NOT THE SHELL'S, and that is the whole design of
# this page.  A streamed answer is hundreds of `data: {…}` lines a second and
# picking the text out of each one in zsh is a character loop per chunk --
# thousands of elementary steps a second, on a cabinet with thirty frames to
# draw.  So the background job is `curl | awk > log`, awk unescapes the JSON
# string as it goes, and the log on disk is already the plain text the page
# wants: the draw does `$(<log)` and nothing else.
CN_LW=72

typeset -ga CH_WHO CH_TXT
typeset -gi CH_N=0
typeset -gi CH_TOPIX=-1  # the first transcript line on the glass · -1 follows the end
CH_STATE=''              # '' idle · run · done · fail
CH_LOG=''
CH_USE=''
typeset -gi CH_IN=0 CH_OUT=0 CH_CTX=0 CH_RUNNER=-1 CH_PID=0
CH_BODY=''
CH_MODEL=''
typeset -gF CH_T0=0.0 CH_FIRST=0.0 CH_END=0.0 CH_POLL=0.0 CH_STARTED=0.0
typeset -gF CH_RATE=0.0 CH_LASTN=0.0 CH_LASTT=0.0

in_json_esc() {   # in_json_esc TEXT -> IJE
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  # ANY OTHER CONTROL BYTE IS DROPPED.  JSON forbids a raw character below
  # 0x20 in a string, and the text on this side is not all mine -- a model's
  # own reply goes back into the next request, and one stray escape or bell in
  # it would make the body the server rejects rather than the one it answers.
  s="${s//[[:cntrl:]]/}"
  IJE="$s"
  return 0
}

# WHICHEVER RUNNER IS ACTUALLY UP, and the first one that is.  The page does
# not ask to be pointed at one: a console for the local model should find the
# local model, and the probe is already looking every few seconds.
# THE MODEL'S OWN FACTS, asked for once.  A name says almost nothing about a
# pulled model -- `qwen2.5-coder:7b` carries no quantisation, no context
# window -- and the rail read `quant —` beside a model ollama knows to be
# Q4_K_M with 32k of context.  ollama's /api/show has all three; llama-
# server's /v1/models carries the size and the training context in `meta`.
# Kept per model name for the session; a runner that will not answer is
# asked again a minute later, not every frame.
typeset -gA CH_INFO CH_INFO_AT      # model → "params|quant|context" · when it was last asked
in_model_info() {   # in_model_info RUNNER MODEL -> CHI_PARAMS CHI_QUANT CHI_CTX (each '' when unknown)
  local -i r=$1
  local m="$2" key rec body
  CHI_PARAMS=''; CHI_QUANT=''; CHI_CTX=''
  [[ -n "$m" ]] || return 0
  key="$r|$m"
  if (( IN_MOCK )); then CH_INFO[$key]='7.6B|Q4_K_M|32768'; fi
  if [[ -z "${CH_INFO[$key]:-}" ]] || { [[ "${CH_INFO[$key]}" == '||' ]] && (( IN_NOW - ${CH_INFO_AT[$key]:-0} > 60.0 )); }; then
    CH_INFO_AT[$key]=$IN_NOW
    CH_INFO[$key]='||'
    if (( r == 0 )); then
      in_json_esc "$m"
      in_http_post "http://127.0.0.1:${IN_RPORT[0]}/api/show" "{\"name\":\"$IJE\"}"
      body="$IHB"
      if [[ -n "$body" ]]; then
        in_body_val "$body" parameter_size;     rec="$IBV|"
        in_body_val "$body" quantization_level; rec+="$IBV|"
        # the context key is `<arch>.context_length`, whatever the arch --
        # found with the greedy-suffix offset trick (see in_json), because
        # /api/show carries the licence text and can be tens of kilobytes
        if [[ "$body" == *'.context_length"'* ]]; then
          local pre="${body%%.context_length\"*}" win
          local -i at=$(( ${#pre} + 16 ))
          win="${body[$at,$(( at + 40 ))]}"
          win="${win#*:}"; win="${win## }"; win="${win%%[^0-9]*}"
          rec+="$win"
        fi
        CH_INFO[$key]="$rec"
      fi
    elif (( r == 1 )); then
      in_http "http://127.0.0.1:${IN_RPORT[1]}/v1/models"
      body="$IHB"
      if [[ -n "$body" ]]; then
        rec=''
        in_body_val "$body" n_params
        if [[ "$IBV" == <-> ]]; then
          if (( IBV >= 1000000000 )); then printf -v rec '%.1fB' $(( IBV / 1000000000.0 ))
          else printf -v rec '%.0fM' $(( IBV / 1000000.0 )); fi
        fi
        in_quant "$m"; rec+="|$IQT|"
        in_body_val "$body" n_ctx_train; [[ "$IBV" == <-> ]] && rec+="$IBV"
        CH_INFO[$key]="$rec"
      fi
    fi
  fi
  rec="${CH_INFO[$key]}"
  CHI_PARAMS="${rec%%|*}"; rec="${rec#*|}"
  CHI_QUANT="${rec%%|*}"; CHI_CTX="${rec#*|}"
  [[ -n "$CHI_QUANT" ]] || { in_quant "$m"; CHI_QUANT="$IQT"; }
  return 0
}
in_ctx_h() {   # in_ctx_h TOKENS -> ICH · 32768 → 32k, 131072 → 128k
  local -i n=$1
  if (( n >= 1024 && n % 1024 == 0 )); then ICH="$(( n / 1024 ))k"
  elif (( n >= 1000 )); then printf -v ICH '%.1fk' $(( n / 1000.0 ))
  else ICH="$n"; fi
  return 0
}

typeset -gi CH_PINNED=-1 CH_LOCK=0
in_chat_target() {
  local -i i
  CH_RUNNER=-1
  # A MODEL THE READER CHOSE ([E]) IS KEPT while its runner is up; the first
  # runner standing is only the answer when nothing was chosen, or when the
  # chosen one has gone.
  if (( CH_LOCK && CH_PINNED >= 0 && ${IR[$CH_PINNED.up]:-0} )); then
    CH_RUNNER=$CH_PINNED
    return 0
  fi
  CH_LOCK=0
  for (( i = 0; i < IN_RN; i++ )); do
    (( ${IR[$i.up]:-0} )) || continue
    CH_RUNNER=$i
    # THE MODEL FOLLOWS THE RUNNER.  This kept the first name it ever saw for
    # the life of the pack: stop ollama and start llama.cpp and the rail
    # correctly said LLAMA.CPP on port 8080 while the header still named
    # ollama's model -- and that stale name is what would have been POSTed.
    if (( CH_PINNED != i )) || [[ -z "$CH_MODEL" ]]; then
      CH_MODEL="${${IR[$i.served]:-}%% · *}"
      CH_PINNED=$i
    fi
    return 0
  done
  return 0
}
in_chat_pick() {   # in_chat_pick K — an engine row, taken as the console's model
  local -i k=$1
  [[ "${RW_EK[$k]:-}" == local ]] || { snd no; return 1 }
  CH_PINNED=${RW_EI[$k]}; CH_MODEL="${RW_EM[$k]}"; CH_LOCK=1
  CH_RUNNER=$CH_PINNED
  if [[ "$CH_STATE" == run ]]; then say "next turn on $CH_MODEL"
  else say "$CH_MODEL · on ${IN_RNAME[$CH_PINNED]}"; fi
  return 0
}

# \uXXXX IS DECODED, NOT DROPPED.  Ollama's server is Go, and Go's JSON
# writes < > and & as \u003c \u003e \u0026 -- so every angle bracket and
# ampersand in an answer used to vanish on the way to the glass, and any
# character a server chose to escape went with it.  The code point is read,
# a surrogate pair is joined, and it is written as UTF-8 by hand on an awk
# that counts bytes (macOS's) and through %c on one that counts characters.
IN_SSE_AWK='
function hx(s,   i, n, c) {
  n = 0
  for (i = 1; i <= length(s); i++) {
    c = index("0123456789abcdef", tolower(substr(s, i, 1))) - 1
    if (c < 0) return -1
    n = n * 16 + c
  }
  return n
}
function cp(n) {
  if (u8 || n < 128) return sprintf("%c", n)
  if (n < 2048) return sprintf("%c%c", 192 + int(n / 64), 128 + n % 64)
  if (n < 65536) return sprintf("%c%c%c", 224 + int(n / 4096), 128 + int(n / 64) % 64, 128 + n % 64)
  return sprintf("%c%c%c%c", 240 + int(n / 262144), 128 + int(n / 4096) % 64, 128 + int(n / 64) % 64, 128 + n % 64)
}
BEGIN { u = ENVIRON["ALIEN_USE"]; u8 = (length("\303\251") == 1) }
{
  if (u != "" && match($0, /"(prompt_eval_count|prompt_tokens)"[ ]*:[ ]*[0-9]+/)) {
    t = substr($0, RSTART, RLENGTH); sub(/^[^0-9]+/, "", t); pin = t
  }
  if (u != "" && match($0, /"(eval_count|completion_tokens)"[ ]*:[ ]*[0-9]+/)) {
    t = substr($0, RSTART, RLENGTH); sub(/^[^0-9]+/, "", t); pout = t
    printf "%s %s\n", pin, pout > u; fflush(u)
  }
  k = index($0, "\"content\":")
  if (k == 0) next
  s = substr($0, k + 10)
  sub(/^[ \t]+/, "", s)
  if (substr(s, 1, 1) != "\"") next
  s = substr(s, 2)
  out = ""; i = 1; n = length(s)
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\\") {
      d = substr(s, i + 1, 1)
      if (d == "n") out = out "\n"
      else if (d == "t") out = out "\t"
      else if (d == "r") { }
      else if (d == "u") {
        v = hx(substr(s, i + 2, 4))
        if (v < 0) { i += 2; continue }
        i += 6
        if (v >= 55296 && v <= 56319 && substr(s, i, 2) == "\\u") {
          w = hx(substr(s, i + 2, 4))
          if (w >= 56320 && w <= 57343) { v = 65536 + (v - 55296) * 1024 + (w - 56320); i += 6 }
        }
        out = out cp(v)
        continue
      }
      else out = out d
      i += 2
    } else if (c == "\"") { break }
    else { out = out c; i++ }
  }
  printf "%s", out; fflush()
}'

in_chat_send() {
  local body msgs cmd url
  local -i i
  [[ -n "$IN_LINE" ]] || { say 'nothing to send'; snd no; return 1 }
  in_chat_target
  (( CH_RUNNER >= 0 )) || { say 'no local endpoint is answering'; snd no; return 1 }
  (( ${+commands[curl]} )) || { say 'no curl on this machine'; snd no; return 1 }
  (( ${+commands[awk]} ))  || { say 'no awk on this machine'; snd no; return 1 }
  (( CH_STARTED == 0.0 )) && CH_STARTED=$IN_NOW
  CH_WHO+=(you); CH_TXT+=("$IN_LINE"); CH_N=${#CH_WHO[@]}
  CH_TOPIX=-1                                # a new line is read at the end
  # THE WHOLE CONVERSATION GOES EVERY TIME, because the endpoint is stateless
  # and a console that sent only the last line would be a console with no
  # memory of the paragraph it just wrote.
  msgs=''
  for (( i = 0; i < CH_N; i++ )); do
    in_json_esc "${CH_TXT[$i]}"
    [[ "${CH_WHO[$i]}" == you ]] && body=user || body=assistant
    msgs+="${msgs:+,}{\"role\":\"$body\",\"content\":\"$IJE\"}"
  done
  in_json_esc "$CH_MODEL"
  # stream_options IS HOW AN OPENAI-SHAPED SERVER IS ASKED FOR THE USAGE
  # BLOCK on a stream at all; ollama and llama-server send it unasked, LM
  # Studio does not, and the counts on the rail come from it.
  body="{\"model\":\"$IJE\",\"stream\":true,\"stream_options\":{\"include_usage\":true},\"messages\":[$msgs]}"
  in_tmp_drop "$CH_LOG"; in_tmp_drop "$CH_USE"; in_tmp_drop "$CH_BODY"
  in_tmp alien-chat || { say 'nowhere to write the answer'; snd no; return 1 }
  CH_LOG="$ITMP"
  in_tmp alien-chat-use || { say 'nowhere to write the answer'; snd no; return 1 }
  CH_USE="$ITMP"
  url="http://127.0.0.1:${IN_RPORT[$CH_RUNNER]}/v1/chat/completions"
  CH_WHO+=("${IN_RNAME[$CH_RUNNER]}"); CH_TXT+=(''); CH_N=${#CH_WHO[@]}
  CH_STATE='run'; CH_T0=$IN_NOW; CH_FIRST=0.0; CH_END=0.0
  CH_RATE=0.0; CH_LASTN=0.0; CH_LASTT=$IN_NOW
  # THE REQUEST GOES IN A FILE, NOT ON A COMMAND LINE.  `curl -d '<the whole
  # conversation>'` put every prompt and every prior answer in this machine's
  # argv, where `ps` shows it to every other process on the Mac -- on the one
  # page whose selling point is that the conversation never leaves the
  # machine.  `@file` is the same request with none of that, and the file is
  # 0600 and removed with the session.
  in_tmp alien-chat-body || { say 'nowhere to write the request'; snd no; return 1 }
  CH_BODY="$ITMP"
  print -rn -- "$body" > "$CH_BODY" 2>/dev/null
  cmd="curl -sN --max-time 300 -H 'Content-Type: application/json'"
  cmd+=" --data-binary @$(_sh "$CH_BODY") $(_sh "$url")"
  cmd+=" | ALIEN_USE=$(_sh "$CH_USE") awk $(_sh "$IN_SSE_AWK")"
  (( IN_MOCK )) && cmd="ALIEN_USE=$(_sh "$CH_USE"); $IN_MOCK_CHAT"
  # THE END OF THE STREAM IS WRITTEN DOWN, like every other job's.  This page
  # used to learn an answer was over only from the usage block -- and a
  # server that streams without one left the rail at `generating…` for ever,
  # with [X] the only way out.
  { zsh -lc "$cmd"; _rc=$?; print -r -- ""; print -r -- "__RC__ $_rc" } >>"$CH_LOG" 2>/dev/null </dev/null &!
  CH_PID=$!
  in_line_clear
  return 0
}

# THE RATE IS A DIFFERENCE, NOT A DIVISION.  Dividing the whole answer by the
# whole elapsed time reports the average of a run that has not finished, which
# on a model that stalls halfway looks exactly like a model that is still
# going at full speed.  This is what arrived since the last look.
in_chat_poll() {   # in_chat_poll T
  local -F t=$1 n dn dt
  local body line
  [[ "$CH_STATE" == run ]] || return 0
  (( t - CH_POLL < 0.2 )) && return 0
  CH_POLL=$t
  [[ -n "$CH_LOG" && -r "$CH_LOG" ]] || return 0
  body="$(<"$CH_LOG")" 2>/dev/null || body=''
  local -i over=0 rc=0
  if [[ "$body" == *$'\n__RC__ '* ]]; then
    over=1
    line="${body##*$'\n__RC__ '}"; line="${line%%$'\n'*}"
    [[ "$line" == <-> ]] && rc=$line || rc=1
    body="${body%$'\n__RC__ '*}"
    body="${body%$'\n'}"
  fi
  (( CH_N > 0 )) && CH_TXT[$(( CH_N - 1 ))]="$body"
  n=$(( ${#body} / 4.0 ))
  if (( n > 0.0 && CH_FIRST == 0.0 )); then CH_FIRST=$(( t - CH_T0 )); fi
  dt=$(( t - CH_LASTT ))
  if (( dt >= 0.4 )); then
    dn=$(( n - CH_LASTN ))
    (( dn < 0.0 )) && dn=0.0
    CH_RATE=$(( CH_RATE * 0.5 + (dn / dt) * 0.5 ))
    CH_LASTN=$n; CH_LASTT=$t
  fi
  # THE USAGE BLOCK IS THE MODEL'S OWN and it arrives last, which is also how
  # this page knows the answer is complete without polling the process table.
  if [[ -n "$CH_USE" && -s "$CH_USE" ]]; then
    body="$(<"$CH_USE")" 2>/dev/null || body=''
    body="${body%%$'\n'*}"
    # THE PROMPT COUNT IS CUMULATIVE ALREADY.  The whole conversation is
    # re-sent every turn, so turn two's prompt_tokens CONTAINS turn one --
    # adding them made the row labelled `context` read about double what the
    # model was actually holding by the third turn.  What this session has
    # spent is the running sum of the OUTPUT plus the last prompt; what the
    # context IS, is the last turn's prompt plus its completion.
    [[ "${body%% *}" == <-> ]] && CH_IN=${body%% *}
    [[ "${body##* }" == <-> ]] && CH_OUT=$(( CH_OUT + ${body##* } ))
    CH_CTX=$(( CH_IN + ${body##* } ))
    CH_END=$(( t - CH_T0 )); CH_STATE='done'
    rm -f "$CH_USE" 2>/dev/null; CH_USE=''
    snd coin
  elif (( over )); then
    # THE STREAM ENDED AND NO USAGE CAME.  The answer is complete (or the
    # request failed, which an empty answer says); the counts stay as they
    # were, since guessing them is what the rail was built not to do.
    CH_END=$(( t - CH_T0 )); CH_STATE='done'
    rm -f "$CH_USE" 2>/dev/null; CH_USE=''
    if (( rc != 0 )) && [[ -z "${CH_TXT[$(( CH_N - 1 ))]//[[:space:]]/}" ]]; then
      CH_TXT[$(( CH_N - 1 ))]="(nothing came back · the runner refused it, rc $rc)"
      snd no
    else
      snd coin
    fi
  fi
  return 0
}

in_chat_stop() {
  [[ "$CH_STATE" == run ]] || return 1
  (( CH_PID > 1 )) && in_kill_tree $CH_PID
  CH_PID=0
  CH_STATE='done'; CH_END=$(( IN_NOW - CH_T0 ))
  return 0
}

in_chat_new() {
  # A SESSION THAT HAPPENED IS A LINE IN THE LOG, and that is all of it: how
  # many turns and how long, which is exactly what the CONSOLE page's own
  # `history` row promises and nothing more.
  if (( CH_STARTED > 0.0 && CH_N > 0 )); then
    in_chat_turns
    # GUARDED, BECAUSE -1 IS A VALID SUBSCRIPT.  Under KSH_ARRAYS a negative
    # index counts from the end, so a CH_RUNNER of -1 would not be an error --
    # it would quietly name the LAST runner in the table.
    local who=console
    (( CH_RUNNER >= 0 )) && who="${IN_RNAME[$CH_RUNNER]}"
    in_log_add console "$who" "$ICT turns" 1 $(( IN_NOW - CH_STARTED ))
  fi
  in_chat_stop 2>/dev/null
  CH_WHO=(); CH_TXT=(); CH_N=0; CH_STATE=''; CH_TOPIX=-1
  CH_IN=0; CH_OUT=0; CH_CTX=0; CH_STARTED=0.0
  CH_RATE=0.0; CH_FIRST=0.0; CH_END=0.0
  in_tmp_drop "$CH_LOG"; in_tmp_drop "$CH_USE"; in_tmp_drop "$CH_BODY"
  CH_LOG=''; CH_USE=''; CH_BODY=''
  in_line_clear
  return 0
}

in_chat_turns() {   # -> ICT, how many of them were yours
  local -i i
  ICT=0
  for (( i = 0; i < CH_N; i++ )); do [[ "${CH_WHO[$i]}" == you ]] && (( ICT++ )); done
  return 0
}

# ── [S] · THE SESSION, AS A MARKDOWN REPORT ────────────────────────────────
# The whole conversation and the counts beside it, written to the reader's
# Downloads as one .md file.  It is built from what the page already holds --
# CH_WHO/CH_TXT for the turns, the usage block for the tokens -- so it says
# exactly what the glass says.  A local session is free and never left the
# machine, and the report says so.
typeset -g CHRPT='' CH_WHEN=''
in_chat_report() {   # -> CHRPT
  local nl=$'\n' who line model runner ep dur spec ctxs=''
  local -i i
  in_chat_turns
  model="${CH_MODEL:-a local model}"
  runner='—'; ep='—'
  if (( CH_RUNNER >= 0 )); then
    runner="${IN_RNAME[$CH_RUNNER]} :${IN_RPORT[$CH_RUNNER]}"
    ep="http://127.0.0.1:${IN_RPORT[$CH_RUNNER]}/v1/chat/completions"
  fi
  dur='—'; (( CH_STARTED > 0.0 )) && { in_secs $(( IN_NOW - CH_STARTED )); dur="$SEC"; }
  spec=''
  if (( CH_RUNNER >= 0 )); then
    in_model_info $CH_RUNNER "$CH_MODEL"
    spec="${CHI_PARAMS:-}${CHI_PARAMS:+ · }${CHI_QUANT:-}"
    [[ "$CHI_CTX" == <-> ]] && { in_ctx_h $CHI_CTX; spec+="${spec:+ · }$ICH context"; }
  fi
  [[ -n "$spec" ]] || spec='—'
  (( CH_CTX )) && ctxs=" · ${CH_CTX} context"
  CHRPT="# Console session · ${model}${nl}${nl}"
  CHRPT+="- **Saved:** ${CH_WHEN:-—}${nl}"
  CHRPT+="- **Model:** ${model}${nl}"
  CHRPT+="- **Runner:** ${runner}${nl}"
  CHRPT+="- **Endpoint:** ${ep}${nl}"
  CHRPT+="- **Spec:** ${spec}${nl}"
  CHRPT+="- **Turns:** ${ICT}${nl}"
  CHRPT+="- **Tokens:** ${CH_IN} in · ${CH_OUT} out${ctxs}${nl}"
  CHRPT+="- **Duration:** ${dur}${nl}"
  CHRPT+="- **Cost:** \$0.00 — local, stays on this machine${nl}${nl}"
  CHRPT+="---${nl}${nl}## Transcript${nl}${nl}"
  for (( i = 0; i < CH_N; i++ )); do
    line="${CH_TXT[$i]}"
    [[ -n "${line//[[:space:]]/}" ]] || continue     # skip a streaming placeholder
    [[ "${CH_WHO[$i]}" == you ]] && who='you' || who="$model"
    CHRPT+="**${who}**${nl}${nl}${line}${nl}${nl}"
  done
  CHRPT+="---${nl}_saved from the AD-1 console · ALIEN DYNAMICS_${nl}"
  return 0
}

# WRITE IT · to ~/Downloads if that folder is there, else the home directory.
# The name carries the model and a timestamp so two saves never collide.  A
# session with nothing in it has nothing to save.
in_chat_save() {
  if (( CH_N == 0 )); then say 'nothing to save yet · ask it something first'; snd no; return 0; fi
  local dir="$HOME/Downloads" stamp when f slug
  [[ -d "$dir" ]] || dir="$HOME"
  zmodload zsh/datetime 2>/dev/null
  if (( ${+EPOCHSECONDS} )); then
    strftime -s stamp '%Y%m%d-%H%M%S' $EPOCHSECONDS
    strftime -s when  '%Y-%m-%d %H:%M' $EPOCHSECONDS
  else
    stamp="$(date '+%Y%m%d-%H%M%S' 2>/dev/null)"; when="$(date '+%Y-%m-%d %H:%M' 2>/dev/null)"
  fi
  CH_WHEN="$when"
  in_chat_report
  slug="${CH_MODEL:-console}"; slug="${slug//[^A-Za-z0-9._-]/-}"
  f="$dir/alien-console-${slug}-${stamp}.md"
  if print -r -- "$CHRPT" > "$f" 2>/dev/null; then
    say "saved · ${f:t}"; snd coin
    in_log_add save "${CH_MODEL:-console}" "session report → ${f:t}" 1 0
  else
    say 'could not write to Downloads'; snd no
  fi
  return 0
}

# ── the transcript, as lines with a speaker on the first of each ──────────
typeset -ga CT_WHO CT_LN CT_FIRST
in_chat_lines() {   # in_chat_lines W
  local -i i j w=$1
  CT_WHO=(); CT_LN=(); CT_FIRST=()
  for (( i = 0; i < CH_N; i++ )); do
    local body="${CH_TXT[$i]}"
    if [[ -z "$body" ]]; then
      # a reply that has not started yet is three dots arriving, over and
      # over, rather than an ellipsis standing still
      if [[ "$CH_STATE" == run ]]; then
        case $(( int(IN_NOW * 3) % 3 )) in 0) body='·' ;; 1) body='··' ;; *) body='···' ;; esac
      else body=''; fi
    fi
    in_wrap_keep "$body" $w
    for (( j = 0; j < ${#WRP[@]}; j++ )); do
      CT_WHO+=("${CH_WHO[$i]}"); CT_LN+=("${WRP[$j]}")
      CT_FIRST+=($(( j == 0 )))
    done
    CT_WHO+=(''); CT_LN+=(''); CT_FIRST+=(0)
  done
  return 0
}

in_draw_console() {
  local -i i n y bg col mcol RX RW rows=20 lw=$CN_LW iry=25
  # ON THE WHOLE WINDOW the transcript takes the width the rail does not need
  # and grows to as many lines as the glass is tall; the input rides the foot
  if (( SCR_W > 120 )); then
    lw=$(( SCR_W - 34 )); rows=$(( SCR_H - 10 )); iry=$(( SCR_H - 5 ))
  fi
  local s
  local -F f
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  in_chat_target
  in_chat_turns
  if (( CH_RUNNER >= 0 )); then
    [[ -n "$CH_MODEL" ]] && s="$CH_MODEL" || s='—'
    cmix $WHITE $PURPLE 0.4; col=$CM
    cmix $WHITE $LIME 0.35;  mcol=$CM
    in_ell "$s" 26; s="$ELL"
  else
    s='nothing is up'; col=$I_LBL; mcol=$I_LBL
  fi
  if (( CH_STARTED > 0.0 )); then in_secs $(( IN_NOW - CH_STARTED )); else SEC='not started'; fi
  if (( CH_RUNNER >= 0 )); then
    in_head CONSOLE 1 "TURN $ICT · $SEC" '' "$s" $col · local $mcol
  else
    in_head CONSOLE 1 "TURN $ICT · $SEC" '' "$s" $col
  fi
  if (( CH_RUNNER >= 0 )); then
    v_text 0 2 "http://127.0.0.1:${IN_RPORT[$CH_RUNNER]}/v1/chat/completions" $I_DIM
  else
    v_text 0 2 'no local endpoint is answering' $AMBER
  fi

  if (( CH_RUNNER < 0 )); then
    in_panel 0 4 $lw $rows 'NOTHING IS UP'
    in_wrap 'This page talks to a model running on this machine, and there is not one running. Start one and it appears here by itself — the probe looks every few seconds.' $(( lw - 6 ))
    for (( i = 0; i < ${#WRP[@]} && i < 4; i++ )); do
      v_text 3 $(( 6 + i )) "${WRP[$i]}" $I_LBL
    done
    for (( i = 0; i < IN_RN && i < 4; i++ )); do
      y=$(( 11 + i * 2 ))
      (( ${IR[$i.here]:-0} )) && in_ink warn || in_ink no
      v_put 3 $y "$IID" $IIN
      in_ell "${IN_RNAME[$i]}" 12; in_rpad "$ELL" 13
      v_text 5 $y "$IRP" $I_FG
      (( ${IR[$i.here]:-0} )) && { s="${IN_RSTART[$i]}"; col=$I_LBL } \
                              || { s="${IN_RGET[$i]}";   col=$I_DIM }
      in_ell "$s" $(( lw - 22 ))
      v_text 19 $y "$ELL" $col
    done
  elif (( CH_N == 0 )); then
    # AN EMPTY TRANSCRIPT SHOULD SAY WHAT THIS PAGE IS, not sit blank.
    v_text 2 5 'A session on the model this machine is already running.' $I_WHITE
    in_wrap "It is not a wrapper around another command line. The console speaks the OpenAI-compatible endpoint ${IN_RNAME[$CH_RUNNER]:l} is serving — which is why the counts on the right are the model's own — and why this page has no way to reach a file of yours." $(( lw - 4 ))
    for (( i = 0; i < ${#WRP[@]} && i < 5; i++ )); do
      v_text 2 $(( 7 + i )) "${WRP[$i]}" $I_LBL
    done
    for (( i = 0; i < 4; i++ )); do
      case $i in
        0) s=endpoint ;; 1) s=serving ;; 2) s=costs ;; *) s=history ;;
      esac
      v_text 2 $(( 13 + i )) "$s" $I_DIM
      case $i in
        0) s="http://127.0.0.1:${IN_RPORT[$CH_RUNNER]}/v1/chat/completions" ;;
        1) s="${IR[$CH_RUNNER.served]:-whatever it is holding}" ;;
        2) s='nothing, and nothing leaves this machine' ;;
        *) s='that a session happened, how many turns, how long' ;;
      esac
      in_ell "$s" $(( lw - 15 ))
      v_text 13 $(( 13 + i )) "$ELL" $I_FG
    done
    v_text 2 19 'press ⏎ and ask it something' $AMBER
  else
    in_chat_lines $(( lw - 10 ))
    n=${#CT_LN[@]}
    # THE WINDOW ONTO THE TRANSCRIPT: the last twenty lines, unless the
    # reader has wheeled up into it -- then it is anchored to the line they
    # stopped on (CH_TOPIX), and an answer still streaming in grows below
    # rather than pulling the page out from under them.
    local -i start=$(( n > rows ? n - rows : 0 ))
    if (( CH_TOPIX >= 0 )); then
      (( CH_TOPIX > start )) && CH_TOPIX=-1 || start=$CH_TOPIX
    fi
    (( n > rows )) && in_scroll_mark $lw 4 $rows $start $rows $n
    for (( i = 0; i < rows && i < n; i++ )); do
      local -i ix=$(( start + i ))
      (( ix >= n )) && break
      y=$(( 4 + i ))
      if [[ "${CT_WHO[$ix]}" == you ]]; then
        cmix $GLASS $MAGENTA 0.22; bg=$CM
        v_fill 0 $y $lw 1 ' ' $GREY $bg
        if (( ${CT_FIRST[$ix]} )); then
          cmix $WHITE $MAGENTA 0.4
          v_put 0 $y '▸' $CM $bg
          v_text 2 $y you $CM $bg
        fi
        v_text 9 $y "${CT_LN[$ix][0,$(( lw - 10 ))]}" $I_WHITE $bg
      elif [[ -n "${CT_WHO[$ix]}" ]]; then
        if (( ${CT_FIRST[$ix]} )); then
          cmix $WHITE $PURPLE 0.35
          in_ell "${CT_WHO[$ix]:l}" 6
          v_text 2 $y "$ELL" $CM
        fi
        if [[ "${CT_LN[$ix]}" == ' '* ]]; then cmix $WHITE $LIME 0.2; col=$CM
        else cshade $WHITE 0.92; col=$CS; fi
        # CLIPPED FOR THE SAME REASON AS THE GATE.  A model that answers with
        # a URL or an absolute path hands back one word longer than the
        # column, and it was drawn straight through THE MODEL, THIS SESSION
        # and RATE -- whose panels are borders, not fills, so it showed.
        v_text 9 $y "${CT_LN[$ix][0,$(( lw - 10 ))]}" $col
      fi
    done
  fi

  # ── the instrument rail ──
  RX=$(( lw + 2 )); RW=$(( SCR_W - lw - 2 ))
  in_panel $RX 3 $RW 6 'THE MODEL'
  (( CH_RUNNER >= 0 )) && in_model_info $CH_RUNNER "$CH_MODEL" || { CHI_PARAMS=''; CHI_QUANT=''; CHI_CTX=''; }
  for (( i = 0; i < 4; i++ )); do
    case $i in
      0) s=runner ;; 1) s=size ;; 2) s=context ;; *) s=holding ;;
    esac
    v_text $(( RX + 2 )) $(( 4 + i )) "$s" $I_LBL
    col=$I_FG
    case $i in
      # THE PORT RIDES WITH THE RUNNER, which freed a row for what the model
      # is: its parameters and quantisation, and how much it can hold.
      0) (( CH_RUNNER >= 0 )) && s="${IN_RNAME[$CH_RUNNER]} :${IN_RPORT[$CH_RUNNER]}" || s='—' ;;
      1) s="${CHI_PARAMS:-}${CHI_PARAMS:+ · }${CHI_QUANT:-}"; [[ -n "$s" ]] || s='—'
         cmix $WHITE $PURPLE 0.3; col=$CM ;;
      2) if [[ "$CHI_CTX" == <-> ]]; then in_ctx_h $CHI_CTX; s="$ICH tokens"; else s='—'; fi
         cmix $WHITE $CYAN 0.3; col=$CM ;;
      *) # THE MODEL ON THE RAIL, NOT THE FIRST ONE AWAKE: the size beside
         # `holding` read the first resident model's while the header named
         # another.
         s='—'
         local -i z
         for (( z = 0; z < IZ_N; z++ )); do
           [[ "${IZ_NAME[$z]%:latest}" == "${CH_MODEL%:latest}" ]] && { s="${IZ_SIZE[$z]:-—}"; break }
         done
         [[ "$s" == '—' ]] && { in_is_resident "$CH_MODEL"; (( IRES )) || s='not loaded'; }
         cmix $WHITE $LIME 0.35; col=$CM ;;
    esac
    in_ell "$s" $(( RW - 12 ))
    in_right $(( RX + RW - 3 )) $(( 4 + i )) "$ELL" $col
  done

  in_panel $RX 9 $RW 7 'THIS SESSION'
  for (( i = 0; i < 5; i++ )); do
    case $i in
      0) s=turns ;; 1) s='tokens in' ;; 2) s='tokens out' ;;
      3) s=context ;; *) s=cost ;;
    esac
    v_text $(( RX + 2 )) $(( 10 + i )) "$s" $I_LBL
    col=$I_FG
    case $i in
      0) s="$ICT" ;;
      1) in_human_n $CH_IN;  s="$IHN" ;;
      2) in_human_n $CH_OUT; s="$IHN" ;;
      3) if (( CH_CTX )); then in_human_n $CH_CTX; s="$IHN"
           [[ "$CHI_CTX" == <-> ]] && { in_ctx_h $CHI_CTX; s+=" of $ICH"; }
         elif [[ "$CHI_CTX" == <-> ]]; then in_ctx_h $CHI_CTX; s="0 of $ICH"
         else s='—'; fi
         cmix $WHITE $CYAN 0.3; col=$CM ;;
      *) s='$0.00'; cmix $WHITE $LIME 0.4; col=$CM ;;
    esac
    in_right $(( RX + RW - 3 )) $(( 10 + i )) "$s" $col
  done

  in_panel $RX 16 $RW 5 RATE
  if [[ "$CH_STATE" == run ]]; then
    # `≈`, BECAUSE THIS ONE IS NOT THE MODEL'S OWN.  tokens in and tokens out
    # above it come out of the usage block; this is characters over four,
    # differenced against the last look -- honest about the SHAPE of the
    # stream, and an estimate about its size.  It sat in the same column as
    # two measured figures with nothing to say which was which.
    printf -v s '≈ %.1f' $CH_RATE
    cmix $WHITE $LIME 0.4
    v_text $(( RX + 2 )) 18 "$s" $CM
    in_right $(( RX + RW - 3 )) 18 'tok/s' $I_LBL
    in_bar $(( RX + 2 )) 17 $(( RW - 5 )) $(( CH_RATE / 120.0 ))
    if (( CH_FIRST > 0.0 )); then printf -v s 'first token %.1fs' $CH_FIRST
    else s='waiting…'; fi
    v_text $(( RX + 2 )) 19 "$s" $I_DIM
  else
    cshade $I_DIM 0.8
    v_hline $(( RX + 2 )) 17 $(( RW - 5 )) '─' $CS
    v_text $(( RX + 2 )) 18 idle $I_LBL
    in_right $(( RX + RW - 3 )) 18 'tok/s' $I_DIM
    v_text $(( RX + 2 )) 19 'nothing is being generated' $I_DIM
  fi

  in_panel $RX 21 $RW 5 MACHINE
  for (( i = 0; i < 2; i++ )); do
    y=$(( 22 + i ))
    if (( i == 0 )); then
      s=memory; f=$(( IN_MEM_PCT / 100.0 )); col=$LIME
      in_size_g $IN_MEM_USED
    else
      s=load; f=$(( 1.0 * IN_LOAD / IN_NCPU )); col=$CYAN
      printf -v IGB '%.2f' $IN_LOAD
    fi
    v_text $(( RX + 2 )) $y "$s" $I_LBL
    v_hline $(( RX + 10 )) $y 10 '░' $I_DIM
    in_bar $(( RX + 10 )) $y 10 $f $col
    in_right $(( RX + RW - 3 )) $y "$IGB" $I_FG
  done
  v_text $(( RX + 2 )) 24 thermal $I_LBL
  if [[ -n "$IN_THERM" ]]; then in_right $(( RX + RW - 3 )) 24 throttled $I_HOT
  else                          in_right $(( RX + RW - 3 )) 24 nominal $I_FG; fi

  # ── the line you type on ──
  v_hline 0 $iry $lw '─' $I_DIM
  # ONE FIELD, DRAWN BY ONE FUNCTION.  Filling the row and putting the caret
  # here as well as in in_draw_line meant two accents on one line and a fill
  # that ran five columns past the conversation's own column.
  in_draw_line 2 $(( iry + 1 )) $(( lw - 4 )) 'press ⏎ and type' $LIME
  if [[ "$CH_STATE" == run ]]; then
    cmix $GLASS $LIME 0.18
    in_right $(( lw - 1 )) $(( iry + 1 )) 'generating…' $I_DIM $CM
  fi
  # THE FIELD OWNS THE KEYBOARD AFTER YOU SEND -- deliberately, because a
  # conversation is a series of lines -- and the footer used to go on
  # advertising [X], [N] and [L] anyway.  They were not inert: they typed
  # `x`, `n` and `l` into the prompt, at the exact moment [X] stop is most
  # wanted.  Now the footer says which keyboard you are on.
  if [[ "$IN_MODE" == edit ]]; then
    if [[ "$CH_STATE" == run ]]; then
      in_foot ⏎ send ⎋ 'leave the field, then [X] stops it'
    else
      in_foot ⏎ send ⎋ 'leave the field'
    fi
  elif [[ "$CH_STATE" == run ]]; then
    in_foot X stop E model N 'new session' ⎋ local
  else
    in_foot ⏎ type E model S save N 'new session' ⎋ local
  fi
  return 0
}

in_bar() {   # in_bar X Y W FRAC [COL]
  local -i x=$1 y=$2 w=$3 i n
  local -F f=$4
  local b=''
  (( f < 0.0 )) && f=0.0; (( f > 1.0 )) && f=1.0
  mo_ease "in.bar.$x.$y" $f $IN_NOW; f=$MV
  n=$(( int(f * w + 0.5) ))
  (( n < 1 && f > 0.0 )) && n=1
  for (( i = 0; i < n; i++ )); do b+='▓'; done
  [[ -n "$b" ]] && v_text $x $y "$b" ${5:-$I_FG}
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# THE LIBRARY · forty-three prompts, and the twelve rules underneath them
# ══════════════════════════════════════════════════════════════════════════
# NOT A LIST OF CLEVER PHRASINGS.  Every one of these is shaped by the same
# handful of rules, and the page shows WHICH rules a prompt is using beside
# the prompt itself -- because the rules are the part that transfers and the
# wording is not.  Copy one, or read why it is the shape it is and write your
# own better than it.
#
# FOUR PARALLEL ARRAYS AND NO RECORDS, which is zsh's only offer: the group it
# belongs to, what it is called, which rules it leans on, and the prompt.
IP_CAT=('READ IT' \
         'READ IT' \
         'READ IT' \
         'READ IT' \
         'READ IT' \
         'READ IT' \
         'FIND THE BUG' \
         'FIND THE BUG' \
         'FIND THE BUG' \
         'FIND THE BUG' \
         'FIND THE BUG' \
         'FIND THE BUG' \
         'CHANGE IT' \
         'CHANGE IT' \
         'CHANGE IT' \
         'CHANGE IT' \
         'CHANGE IT' \
         'CHANGE IT' \
         'REVIEW' \
         'REVIEW' \
         'REVIEW' \
         'REVIEW' \
         'REVIEW' \
         'TESTS' \
         'TESTS' \
         'TESTS' \
         'TESTS' \
         'REFACTOR' \
         'REFACTOR' \
         'REFACTOR' \
         'REFACTOR' \
         'PLAN' \
         'PLAN' \
         'PLAN' \
         'PLAN' \
         'WRITE' \
         'WRITE' \
         'WRITE' \
         'WRITE' \
         'THE META ONES' \
         'THE META ONES' \
         'THE META ONES' \
         'THE META ONES')
IP_NAME=('Walk me through it' \
          'What breaks if I change it' \
          'Why is it like this' \
          'The five minute tour' \
          'What does this assume' \
          'Edge cases it handles' \
          'Root cause, not symptom' \
          'Failing test first' \
          'Which commit did it' \
          'Explain this error' \
          'Prove it is fixed' \
          'Can two of these collide' \
          'The smallest diff' \
          'Follow what is already here' \
          'Implement, then verify' \
          'Everywhere it applies' \
          'Undo the clever' \
          'Touch nothing else' \
          'Correctness only' \
          'Try to break it' \
          'Against what was asked' \
          'Security only' \
          'What a reviewer will ask' \
          'Test what can fail' \
          'One test, one reason' \
          'Is the test wrong' \
          'What is not covered' \
          'Behaviour identical' \
          'Name things properly' \
          'Delete what is dead' \
          'One thing at a time' \
          'Plan before code' \
          'Interview me' \
          'Two real options' \
          'What will this cost me' \
          'Explain it to a person' \
          'The commit message' \
          'The README section' \
          'Say it shorter' \
          'Do not guess' \
          'Show your evidence' \
          'Start over, better' \
          'How sure are you')
IP_USES=('NAME IT · SET THE LENGTH' \
          'READ BEFORE CLAIMING · ASK FOR EVIDENCE' \
          'NAME IT · LET IT NOT KNOW' \
          'SET THE LENGTH · NAME IT' \
          'LONG THING FIRST · NAME IT' \
          'ASK FOR EVIDENCE' \
          'NAME IT · FENCE THE SCOPE · GIVE IT A CHECK' \
          'GIVE IT A CHECK · ASK FOR EVIDENCE' \
          'NAME IT · LET IT NOT KNOW' \
          'LONG THING FIRST · ONE TASK' \
          'ASK FOR EVIDENCE' \
          'ASK FOR EVIDENCE · LET IT NOT KNOW' \
          'FENCE THE SCOPE · SET THE LENGTH' \
          'NAME IT · ASK FOR EVIDENCE' \
          'GIVE IT A CHECK · ASK FOR EVIDENCE' \
          'NAME IT · ASK FOR EVIDENCE' \
          'FENCE THE SCOPE' \
          'FENCE THE SCOPE · SAY WHAT TO DO' \
          'ONE TASK · ASK FOR EVIDENCE · LET IT NOT KNOW' \
          'SAY WHAT TO DO · ASK FOR EVIDENCE' \
          'NAME IT · FENCE THE SCOPE' \
          'ONE TASK · LET IT NOT KNOW' \
          'SET THE LENGTH' \
          'SAY WHAT TO DO · GIVE IT A CHECK · ASK FOR EVIDENCE' \
          'SAY WHAT TO DO' \
          'ONE TASK · LET IT NOT KNOW' \
          'SAY WHAT TO DO · SET THE LENGTH' \
          'GIVE IT A CHECK · ASK FOR EVIDENCE' \
          'FENCE THE SCOPE' \
          'ASK FOR EVIDENCE · LET IT NOT KNOW' \
          'PLAN WHEN IT IS BIG' \
          'PLAN WHEN IT IS BIG · FENCE THE SCOPE' \
          'ONE TASK · PLAN WHEN IT IS BIG' \
          'SET THE LENGTH · SAY WHAT TO DO' \
          'PLAN WHEN IT IS BIG' \
          'SAY WHAT TO DO · SET THE LENGTH' \
          'SET THE LENGTH · SAY WHAT TO DO' \
          'SAY WHAT TO DO · SET THE LENGTH' \
          'SET THE LENGTH · CUT THE CEREMONY' \
          'READ BEFORE CLAIMING · LET IT NOT KNOW' \
          'ASK FOR EVIDENCE' \
          'ONE TASK' \
          'LET IT NOT KNOW · SET THE LENGTH')
IP_TEXT=('Explain what this code does in the order it actually executes. Start at the entry point and follow the calls. Give the file and line as you go. At most eight sentences.' \
          'List everything that depends on this. For each one, say what would break if its behaviour changed, and give the file and line where you found it. Do not describe code you have not opened.' \
          'Look through the git history for this file and tell me how it ended up this way. Quote the commit messages that explain the decisions. If the history does not say, tell me that instead of inventing a reason.' \
          'I am new to this repository. Tell me where execution starts, the three or four files I will spend most of my time in, and the one thing about this codebase that would surprise an experienced engineer. Name the files. At most ten sentences, no lists.' \
          'Read the code above and tell me three things: what it does, what it assumes about its input, and what it does when those assumptions are wrong. If any of it is unreachable, say which lines.' \
          'List the edge cases this code already handles and the ones it does not. For every case you say it handles, quote the line that handles it.' \
          'This is failing. Find the root cause rather than a way to suppress the symptom. Show me the smallest input that reproduces it, then the fix as a diff. Change nothing that is not part of the fix.' \
          'Reproduce this as a failing test before you change any code. Paste the test failing. Then fix the cause. Then paste the test passing. If the test would have passed before your change, say so.' \
          'This worked before and does not now. Use the git history to narrow down which change caused it. Name the commit and quote the line in it that did it. If you cannot narrow it to one commit, tell me what you ruled out.' \
          'Explain the error above in plain language: what it was trying to do, what it found instead, and which line to look at first. Do not propose a fix yet.' \
          'Show me the evidence that this is fixed: the exact command you ran, its exit status, and its output. Not a summary of the output — the output.' \
          'Tell me whether this can misbehave when two of them run at once. If it can, describe the exact interleaving that breaks it. If it cannot, quote the lock, the queue or the ordering guarantee that makes it safe.' \
          'Make this change with the smallest diff that is still correct. No new files, no new options, no abstraction for a single caller, no refactoring of code you did not have to touch. Show me the diff.' \
          'Do this the way this codebase already does it. Find the closest existing example first and tell me which file it is, then follow that pattern. Do not add a dependency that is not already in use.' \
          'Implement this, then run the tests and paste the output. If one fails, fix the cause and run them again. Keep going until they pass, or until you can tell me exactly why they cannot.' \
          'Make this change everywhere in the repository it applies, not only in the file in front of you. List every file you changed and what changed in it. Where it looks like it should apply but does not, say which and why.' \
          'This is harder to read than it needs to be. Rewrite it so a tired person can follow it at two in the morning, without changing what it does. Show the diff and say what behaviour you were careful to preserve.' \
          'Change only what I asked for. Leave formatting, names, imports and nearby problems exactly as they are. If you notice something worth fixing, list it at the end instead of doing it.' \
          'Review this for correctness only. Ignore style, naming and formatting. For each finding give the file, the line, the input that triggers it, and what goes wrong. If you find nothing, say so rather than finding something.' \
          'Assume this is wrong and look for the input that proves it. Report only what actually fails, with the input that fails it and what it does instead.' \
          'Check this work against what was asked for. For each requirement say done, partly done or missing, and point at the code. Flag anything that changed which was not asked for. Report gaps, not style preferences.' \
          'Look at this for security only: untrusted input reaching a shell, a query or a path; secrets in code or in logs; a missing authorisation check. Quote the line for each. Where it depends on how the code is called, say so rather than assuming the worst.' \
          'I am about to send this for review. Give me the three questions a careful reviewer would ask about it, and answer each one from the code.' \
          'Write tests for the cases that can actually fail — the boundaries, the empty case, the error path — rather than the happy path twice. Use real objects where a real object will do. Run them and paste the output.' \
          'Each test should fail for exactly one reason. Split any test here that could fail for several, and name each one after the thing it proves.' \
          'This test is failing. Before you change any code, tell me whether the test is right. If the test is wrong, fix the test. If the code is wrong, fix the code. Say which one it was and how you decided.' \
          'Tell me what this suite does not cover that matters, ranked by what would actually break in front of a user. Ignore coverage percentages. At most five items.' \
          'Refactor this without changing what it does. Run the tests after each step and paste the result. If you cannot keep the behaviour identical, stop and tell me where and why.' \
          'Rename what is misnamed here so the names say what the things are. Change no logic at all. List every rename as old → new.' \
          'Find code here that nothing reaches any more. For each one show me the search you ran and what it returned, so I can see why you believe it. Delete nothing you are not certain about — list those separately.' \
          'This does several things. Show me the shape you would split it into before you move any code. Then, if I agree, do it in steps that each keep the tests green.' \
          'Do not write code yet. Read what is relevant, then give me a plan: the files that change, what changes in each, the order to do them in, and what is out of scope. Then stop.' \
          'I want to build something and I have not thought it all the way through. Interview me. Ask about the hard parts, the edge cases and the trade-offs I am likely to have missed — one question at a time, and skip the obvious ones. When we have covered it, write the spec to a file.' \
          'Give me two ways to do this that are genuinely different, not one way and a variation of it. For each: what it costs now, what it makes easy, and what it makes hard later. Then say which you would choose and why. Under three hundred words.' \
          'Before we start: what is the risky part of this change, what does it touch that I am probably not thinking about, and what would make you stop and ask me a question halfway through?' \
          'Explain this to someone who is good at their job and has never seen this system. Write flowing paragraphs. At most two hundred words. If a detail would not change what they do next, leave it out.' \
          'Write the commit message for this change. First line under seventy-two characters, saying what changed. Then a blank line, then why it changed — the reason, not a restatement of the diff.' \
          'Write the part of the README that covers this: what it is for, the one command that runs it, and the two things people get wrong. Plain sentences, no marketing, no adjectives you cannot measure.' \
          'Cut this to half its length without losing anything that would change a decision. Keep every number, name and command. Cut the throat-clearing, the restatement of the question, and the summary at the end.' \
          'For everything in this conversation: if you have not opened the file, say so rather than describing what is probably in it. Three sentences you are sure of beat a page you are not.' \
          'For every claim you make about this code, give the file and line you got it from. Where you inferred something instead of reading it, mark it as an inference.' \
          'We have gone back and forth on this and it is not converging. Ignore everything we have tried so far. Describe the problem from scratch in your own words, then tell me the approach you would take if you were starting now.' \
          'Answer, then tell me how sure you are and what would change your mind. If you are less than certain, name the one thing you would check first.')
typeset -gi IP_N=43
IP_CATS=('READ IT' 'FIND THE BUG' 'CHANGE IT' 'REVIEW' 'TESTS' 'REFACTOR' 'PLAN' 'WRITE' 'THE META ONES')
typeset -gi IP_CN=9

# ── and the twelve · the reason any of the above is worth copying ─────────
# A RULE IS A NAME, A LINE, AND WHY.  The name is what a prompt cites and the
# line is what to do; those two are what the page draws beside a prompt, in
# the width it has.  The paragraph is the argument for the rule -- kept here,
# where the rules are, for a reader of this file rather than of the glass.
IR_NAME=('NAME IT' \
         'SAY WHAT TO DO' \
         'GIVE IT A CHECK' \
         'ASK FOR EVIDENCE' \
         'FENCE THE SCOPE' \
         'LET IT NOT KNOW' \
         'ONE TASK' \
         'LONG THING FIRST' \
         'SET THE LENGTH' \
         'CUT THE CEREMONY' \
         'READ BEFORE CLAIMING' \
         'PLAN WHEN IT IS BIG')
IR_SHORT=('Say the file, the function, the symptom, the command.' \
          'Ask for the behaviour you want, not the one you don'\''t.' \
          'A test, a command, an example input and its answer.' \
          'The output it got, not its word that it worked.' \
          'Say what not to touch, and what is out of scope.' \
          'Give explicit permission to say "I am not sure".' \
          'One prompt, one job. Start a new session for the next one.' \
          'Paste the code, log or document ABOVE the question.' \
          '"At most six sentences." "The diff only."' \
          'No please, no persona, no throat-clearing.' \
          '"Do not describe code you have not opened."' \
          'Multi-file or unfamiliar: ask for the plan first, code second.')
IR_WHY=('A prompt that could be about any codebase gets an answer about any codebase. Naming the thing is the single change that removes the most back-and-forth.' \
         '"Do not use bullet points" performs worse than "write flowing paragraphs". A prohibition leaves the target unspecified; an instruction does not.' \
         'Without something that returns pass or fail, "looks done" is the only signal there is, and you become the verification loop. With one, the loop closes without you.' \
         'Reading the test output is faster than re-running it yourself, and it is the only thing that distinguishes a run that passed from a run that was said to have passed.' \
         'Current models over-engineer by default -- extra files, extra options, abstractions for one caller. The fence is one sentence and it saves the whole diff.' \
         'A model with no way out of a question guesses. One that has been told uncertainty is an acceptable answer says so instead, and hallucinations drop.' \
         'Context is the constraint everything else bends around: performance degrades as it fills, and the fastest way to fill it with irrelevance is to change the subject.' \
         'On long inputs, putting the material first and the question last measures up to thirty per cent better than the other way round.' \
         'Length is the cheapest quality control there is. An unbounded answer costs tokens on both sides and buries the part you wanted.' \
         '"You are a world-class expert" and "could you possibly help me" are tokens that change nothing. The vendors'\'' own guidance now says to drop them.' \
         'The most common wrong answer about a codebase is a plausible one about a file that was never read. One sentence forbids it.' \
         'Planning is overhead on a one-line change and the difference between right and wrong on a ten-file one. If you could describe the diff in a sentence, skip it.')
typeset -gi IR_N=12

typeset -gi IN_PSEL=0 IN_PTOP=0

# THE LIST IS HEADINGS AND ROWS IN ONE COLUMN, which is why it is built rather
# than indexed: the cursor moves between PROMPTS and the headings are passed
# over, so the drawing needs a flat list of both and the cursor needs a map
# from a prompt back to its line in it.
typeset -ga PR_KIND PR_LABEL PR_IX
typeset -gi PR_N=0
# BUILT ONCE.  Fifty-two array appends and forty-three string comparisons, for
# a table whose inputs are constants compiled into this file, were being done
# on every frame this page was in front.
in_prompt_rows() {
  local c=''
  local -i i
  (( PR_N )) && return 0
  PR_KIND=(); PR_LABEL=(); PR_IX=(); PR_N=0
  for (( i = 0; i < IP_N; i++ )); do
    if [[ "${IP_CAT[$i]}" != "$c" ]]; then
      c="${IP_CAT[$i]}"
      PR_KIND+=(h); PR_LABEL+=("$c"); PR_IX+=(-1)
    fi
    PR_KIND+=(p); PR_LABEL+=("${IP_NAME[$i]}"); PR_IX+=($i)
  done
  PR_N=${#PR_KIND[@]}
  return 0
}

in_prompt_at() {   # in_prompt_at SEL -> IPAT, the line the cursor is on
  local -i i
  IPAT=0
  for (( i = 0; i < PR_N; i++ )); do
    (( ${PR_IX[$i]} == $1 )) && { IPAT=$i; return 0 }
  done
  return 0
}

in_rule_ix() {   # in_rule_ix NAME -> IRX, or -1
  local -i i
  IRX=-1
  for (( i = 0; i < IR_N; i++ )); do
    [[ "${IR_NAME[$i]}" == "$1" ]] && { IRX=$i; return 0 }
  done
  return 0
}

in_words() {   # in_words TEXT -> IWN
  local -a w; w=(${=1})
  IWN=${#w[@]}
  return 0
}

in_draw_prompts() {
  local -i i j y on bg col sel top H=21 n
  # ON THE WHOLE WINDOW the library list grows taller, and the prompt and its
  # notes widen and the notes panel grows down onto the footer
  local -i rw=60 libH=24 whyH=11 wcap=25
  if (( SCR_W > 120 )); then
    rw=$(( SCR_W - 46 )); libH=$(( SCR_H - 6 )); H=$(( SCR_H - 9 ))
    whyH=$(( SCR_H - 19 )); wcap=$(( 16 + whyH - 2 ))
  fi
  local s lab
  local -a uses
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  (( IP_N )) || return 0
  sel=$IN_PSEL
  (( sel < 0 )) && sel=0
  (( sel >= IP_N )) && sel=$(( IP_N - 1 ))
  IN_PSEL=$sel
  cmix $WHITE $LIME 0.4
  in_head PROMPTS 1 '⏎ copies the one under the cursor' \
     'READY TO PASTE' "$IP_N" $I_WHITE \
     GROUPS "$IP_CN" $I_WHITE \
     'BLANKS TO FILL IN' none $CM

  in_prompt_rows
  in_prompt_at $sel
  in_scroll_into $IPAT $IN_PTOP $H $PR_N; IN_PTOP=$ITOP; top=$ITOP
  in_panel 2 3 40 $libH 'THE LIBRARY' "$(( sel + 1 )) of $IP_N"
  for (( i = 0; i < H; i++ )); do
    j=$(( top + i ))
    (( j >= PR_N )) && break
    y=$(( 5 + i ))
    lab="${PR_LABEL[$j]}"
    if [[ "${PR_KIND[$j]}" == h ]]; then
      cmix $WHITE $PURPLE 0.35
      v_text 4 $y "$lab" $CM
      v_hline $(( 5 + ${#lab} )) $y $(( 34 - ${#lab} )) '─' $I_DIM
      continue
    fi
    in_glide prompts $sel ${PR_IX[$j]}; on=$IGON
    in_band 3 $y 37 $IGS; bg=$IBG
    (( on )) && { cmix $WHITE $LIME 0.3; v_put 4 $y '▸' $CM $bg }
    in_ell "$lab" 32
    (( on )) && col=$I_WHITE || col=$I_LBL
    v_text 6 $y "$ELL" $col $bg
  done
  in_scroll_mark 40 5 $H $top $H $PR_N

  # ── the prompt itself ──
  in_ell "${IP_NAME[$sel]}" 30
  in_panel 44 3 $rw 12 "$ELL" "${IP_CAT[$sel]}"
  # THE LINE BREAKS IN THE SOURCE ARE FOR READING THE SOURCE.  This panel is a
  # different width, so it gets the paragraph and wraps it itself.
  in_wrap "${IP_TEXT[$sel]}" $(( rw - 6 ))
  for (( i = 0; i < ${#WRP[@]} && i < 7; i++ )); do
    v_text 46 $(( 5 + i )) "${WRP[$i]}" $I_FG
  done
  in_words "${IP_TEXT[$sel]}"
  v_text 46 13 "$IWN words · about $(( int(${#IP_TEXT[$sel]} / 4.0 + 0.5) )) tokens" $I_DIM

  # ── and why it is shaped like that ──
  in_panel 44 16 $rw $whyH 'WHY IT IS SHAPED LIKE THAT'
  y=18
  uses=("${(@s:·:)IP_USES[$sel]}")
  for (( i = 0; i < ${#uses[@]} && i < 3; i++ )); do
    s="${uses[$i]}"; s="${s## }"; s="${s%% }"
    [[ -n "$s" ]] || continue
    in_rule_ix "$s"
    (( IRX >= 0 )) || continue
    (( y > wcap )) && break
    cmix $WHITE $AMBER 0.4
    v_text 46 $y "$s" $CM
    (( y++ ))
    # THE SHORT LINE, NOT THE ARGUMENT.  The paragraph under each rule is
    # worth reading once and this panel is read forty-three times; what
    # belongs beside a prompt is the instruction the prompt is obeying.
    in_wrap "${IR_SHORT[$IRX]}" $(( rw - 8 ))
    for (( j = 0; j < ${#WRP[@]} && j < 2; j++ )); do
      (( y > wcap )) && break
      v_text 48 $y "${WRP[$j]}" $I_LBL
      (( y++ ))
    done
    # TESTED BEFORE THE NEXT ONE IS DRAWN, not after.  The panel's last
    # interior row is 25; the guard used to run at the bottom of the loop, so
    # a third rule whose line wrapped could write its second row onto the box.
    (( y > wcap )) && break
  done
  in_foot ▴▾ choose ⏎ 'copy it' W rewrite ◂▸ pages ⎋ menu
  return 0
}

in_prompt_copy() {
  (( IP_N )) || return 0
  (( IN_PSEL < 0 )) && IN_PSEL=0
  (( IN_PSEL >= IP_N )) && IN_PSEL=$(( IP_N - 1 ))
  if (( ! ${+commands[pbcopy]} )); then
    say 'no pbcopy on this machine'; snd no; return 0
  fi
  print -rn -- "${IP_TEXT[$IN_PSEL]}" | pbcopy 2>/dev/null
  say "${IP_NAME[$IN_PSEL]} · copied"; snd coin
  # THE NAME, NOT THE PROMPT.  Same reason as the bench: the library's text
  # is a prompt, and HISTORY promises not to keep one.
  in_log_add copy "${IP_NAME[$IN_PSEL]}" "to the clipboard" 1 0
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# HISTORY · what has been run from this cabinet, and nothing about it
# ══════════════════════════════════════════════════════════════════════════
# NO PROMPT AND NO ANSWER IS EVER WRITTEN.  What, where, how long, and how it
# ended -- and the page says so on its own bottom line rather than in a
# comment only the author reads.  It is also why this log lives in memory and
# not on disk: what it is FOR is "what did I just do", and the window that
# question needs is this session.
typeset -gi IN_HSEL=0 IN_HTOP=0 IN_HROWS=20 IN_TALLY_AT=-1
IN_TALLY=''

in_draw_hist() {
  local -i i ix y on bg col tally
  # ON THE WHOLE WINDOW the log spans the glass and shows as many runs as it
  # is tall, and the tally line drops to the footer
  local -i band=100 fw=102 rs=0 tly=26 ph=23
  if (( SCR_W > 120 )); then
    band=$(( SCR_W - 6 )); fw=$(( SCR_W - 4 )); rs=$(( fw - 102 ))
    tly=$(( SCR_H - 3 )); ph=$(( tly - 3 )); IN_HROWS=$(( tly - 6 ))
  else
    IN_HROWS=20
  fi
  local s who
  local -F tot=0.0
  local -a seen cnt
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  for (( i = 0; i < IN_LOG_N; i++ )); do tot=$(( tot + ${IN_LOG_SEC[$i]} )); done
  in_secs $tot
  cmix $WHITE $AMBER 0.4
  in_head HISTORY 1 'this session only · never written to disk' \
     RUNS "$IN_LOG_N" $I_WHITE \
     TIME "$SEC" $CM
  in_panel 2 3 $fw $ph 'EVERY RUN' 'NEWEST FIRST'
  v_text 4  4 WHEN  $I_DIM
  v_text 17 4 KIND  $I_DIM
  v_text 27 4 AGENT $I_DIM
  v_text 46 4 WHAT  $I_DIM
  in_right $(( 101 + rs )) 4 LASTED $I_DIM
  if (( IN_LOG_N == 0 )); then
    v_text 4 6 'nothing has been run from this cabinet yet.' $I_LBL
    in_wrap 'A line lands here every time an agent or a model opens in the glass, the bench when it asks, REWRITE when it answers, the console when a session ends, and [I] whenever something is installed.' $(( fw - 10 ))
    for (( i = 0; i < ${#WRP[@]} && i < 2; i++ )); do
      v_text 4 $(( 8 + i )) "${WRP[$i]}" $I_DIM
    done
    in_wrap 'No prompt and no answer is ever written — what, where, how long, and how it ended.' $(( fw - 10 ))
    for (( i = 0; i < ${#WRP[@]} && i < 2; i++ )); do
      v_text 4 $(( 11 + i )) "${WRP[$i]}" $I_DIM
    done
  fi
  (( IN_HSEL >= IN_LOG_N )) && IN_HSEL=$(( IN_LOG_N > 0 ? IN_LOG_N - 1 : 0 ))
  (( IN_HSEL < 0 )) && IN_HSEL=0
  in_scroll_into $IN_HSEL $IN_HTOP $IN_HROWS $IN_LOG_N; IN_HTOP=$ITOP
  for (( i = 0; i < IN_HROWS && i < IN_LOG_N; i++ )); do
    ix=$(( IN_HTOP + i ))
    (( ix >= IN_LOG_N )) && break
    y=$(( 5 + i )); in_glide hist $IN_HSEL $ix; on=$IGON
    in_band 3 $y $band $IGS; bg=$IBG
    (( ${IN_LOG_OK[$ix]} )) && col=$I_OK || col=$I_WARNC
    (( on )) && { cmix $WHITE $LIME 0.3; v_put 4 $y '▸' $CM $bg }
    in_rpad "${IN_LOG_T[$ix]}" 11
    v_text 6 $y "$IRP" $(( on ? I_WHITE : I_LBL )) $bg
    v_put 17 $y '●' $col $bg
    in_ell "${IN_LOG_KIND[$ix]}" 7
    v_text 19 $y "$ELL" $(( on ? I_LBL : I_DIM )) $bg
    # 27, NOT 26.  KIND is drawn at 19 and `install` is exactly the seven
    # characters that column has, so `● installGROK BUILD` came out as one
    # word.  AGENT still has eighteen before WHAT at 46.
    in_ell "${IN_LOG_WHO[$ix]}" 18
    v_text 27 $y "$ELL" $(( on ? I_WHITE : I_FG )) $bg
    in_ell "${IN_LOG_CMD[$ix]}" $(( 46 + rs ))
    if (( on )); then cmix $WHITE $PURPLE 0.35; else cmix $I_DIM $PURPLE 0.6; fi
    v_text 46 $y "$ELL" $CM $bg
    in_secs ${IN_LOG_SEC[$ix]}
    (( on )) || { cshade $col 0.75; col=$CS }
    in_right $(( 101 + rs )) $y "$SEC" $col $bg
  done
  in_scroll_mark $fw 5 $IN_HROWS $IN_HTOP $IN_HROWS $IN_LOG_N

  # ── who it was, mostly ──
  # RECOUNTED WHEN THE LOG CHANGES, not on every frame.  This is quadratic in
  # the number of entries -- sixty of them is thirty-six hundred string
  # comparisons -- and the answer only moves when a run finishes.
  if (( IN_TALLY_AT != IN_LOG_N )); then
    IN_TALLY_AT=$IN_LOG_N
    seen=(); cnt=()
    for (( i = 0; i < IN_LOG_N; i++ )); do
      who="${IN_LOG_WHO[$i]}"
      tally=-1
      for (( ix = 0; ix < ${#seen[@]}; ix++ )); do
        [[ "${seen[$ix]}" == "$who" ]] && { tally=$ix; break }
      done
      if (( tally < 0 )); then seen+=("$who"); cnt+=(1)
      else cnt[$tally]=$(( ${cnt[$tally]} + 1 )); fi
    done
    IN_TALLY=''
    for (( i = 0; i < ${#seen[@]} && i < 6; i++ )); do
      IN_TALLY+="${IN_TALLY:+  ·  }${seen[$i]} ${cnt[$i]}"
    done
  fi
  s="$IN_TALLY"
  # 53, NOT 70.  The caption on the right is 44 characters ending at column
  # 102, so it starts at 59; a tally of four agents is already 60 characters
  # from column 3 and the privacy line, drawn second, ate the end of it.
  in_ell "$s" 53
  v_text 3 $tly "$ELL" $I_DIM
  in_right $(( SCR_W - 4 )) $tly 'no prompt and no answer is ever written here' $I_DIM
  in_foot ▴▾ read ◂▸ pages C cloud ⎋ menu
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# KEYS · which providers this machine is carrying, and NOTHING about them
# ══════════════════════════════════════════════════════════════════════════
# THE VALUE OF A KEY IS NEVER READ, never printed, never logged and never
# sent.  This page knows two things about each one: that it is set, and how
# long it is.  That is enough to answer the question anybody actually has --
# "is the key the agent is about to use the one I think it is" -- and not
# enough to be worth a screenshot.
#
# THE LENGTH IS THE WHOLE TRICK.  A key that is 51 characters and a key that
# is 164 are different keys, and a variable that is 3 characters long is a
# typo; none of that requires looking at one.
IN_KEXTRA=(OPENROUTER_API_KEY GROQ_API_KEY MISTRAL_API_KEY DEEPSEEK_API_KEY \
           TOGETHER_API_KEY OLLAMA_HOST OPENAI_BASE_URL)

typeset -ga IK_VAR IK_SET IK_N_ IK_URL
typeset -gi IK_N=0
in_scan_keys() {
  local v val
  local -a want
  local -i i
  IK_VAR=(); IK_SET=(); IK_N_=(); IK_URL=(); IK_N=0
  want=()
  for (( i = 0; i < IN_N; i++ )); do
    for v in ${=IN_ENVS[$i]}; do
      [[ " ${want[*]} " == *" $v "* ]] || want+=("$v")
    done
  done
  for v in "${IN_KEXTRA[@]}"; do
    [[ " ${want[*]} " == *" $v "* ]] || want+=("$v")
  done
  for v in "${want[@]}"; do
    # ITS LENGTH AND WHETHER IT LOOKS LIKE AN ADDRESS, and then the value is
    # dropped on the floor by going out of scope.  It is never assigned to
    # anything this page can draw.
    val="${(P)v:-}"
    IK_VAR+=("$v")
    if [[ -n "$val" ]]; then
      IK_SET+=(1); IK_N_+=(${#val})
      [[ "$val" == *'://'* ]] && IK_URL+=(1) || IK_URL+=(0)
    else
      IK_SET+=(0); IK_N_+=(0); IK_URL+=(0)
    fi
  done
  IK_N=${#IK_VAR[@]}
  return 0
}

in_draw_keys() {
  local -i i y n on=0 col
  # ON THE WHOLE WINDOW the two lists split the width, grow to as many rows as
  # the glass is tall, and the privacy note drops to the footer
  local -i lw=50 cx=54 cw=50 ph=20 rows=17 nly=24
  if (( SCR_W > 120 )); then
    lw=$(( (SCR_W - 6) / 2 )); cx=$(( 2 + lw + 2 )); cw=$(( SCR_W - 2 - cx ))
    nly=$(( SCR_H - 6 )); ph=$(( nly - 4 )); rows=$(( nly - 7 ))
  fi
  local s
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  for (( i = 0; i < IK_N; i++ )); do (( ${IK_SET[$i]} )) && (( on++ )); done
  cmix $WHITE $LIME 0.4
  in_head KEYS 1 'values are never read' \
     VARIABLES "$IK_N" $I_WHITE \
     SET "$on" $CM

  in_panel 2 3 $lw $ph 'THE ENVIRONMENT'
  v_text 4 4 VARIABLE $I_DIM
  v_text 32 4 STATE   $I_DIM
  in_right $(( lw - 1 )) 4 LENGTH $I_DIM
  for (( i = 0; i < IK_N && i < rows; i++ )); do
    y=$(( 5 + i ))
    if (( ${IK_SET[$i]} )); then
      v_put 4 $y '●' $I_OK
      in_ell "${IK_VAR[$i]}" 25; v_text 6 $y "$ELL" $I_FG
      (( ${IK_URL[$i]} )) && s='an address' || s='set'
      v_text 32 $y "$s" $I_LBL
      in_right $(( lw - 1 )) $y "${IK_N_[$i]}" $I_LBL
    else
      cshade $GREY 0.5; v_put 4 $y '○' $CS
      in_ell "${IK_VAR[$i]}" 25; v_text 6 $y "$ELL" $I_DIM
      v_text 32 $y 'not set' $I_DIM
      in_right $(( lw - 1 )) $y '—' $I_DIM
    fi
  done

  in_panel $cx 3 $cw $ph 'WHO USES WHAT'
  v_text $(( cx + 2 )) 4 AGENT          $I_DIM
  v_text $(( cx + 18 )) 4 'SIGNED IN'    $I_DIM
  v_text $(( cx + 31 )) 4 'WHAT SAID SO' $I_DIM
  n=0
  for (( i = 0; i < IN_N; i++ )); do
    (( ${IA[$i.here]:-0} )) || continue
    (( n >= rows )) && break
    y=$(( 5 + n )); (( n++ ))
    in_ink "${IA[$i.state]:-wait}"
    v_put $(( cx + 2 )) $y "$IID" $IIN
    in_ell "${IN_NAME[$i]}" 13;          v_text $(( cx + 4 )) $y "$ELL" $I_FG
    in_ell "${IA[$i.auth]:-reading…}" 12; v_text $(( cx + 18 )) $y "$ELL" $IIN
    # WHAT SAID SO IS A FILE OR A VARIABLE NAME, never a value -- and the file
    # is shown by its LAST component, because the useful half of
    # `~/.claude/.credentials.json` is the end of it.
    s="${IA[$i.proof]:-}"
    [[ "$s" == */* ]] && s="${s:t}"
    in_ell "$s" 18; v_text $(( cx + 31 )) $y "$ELL" $I_DIM
  done
  (( n )) || v_text $(( cx + 4 )) 6 'nothing installed' $I_DIM

  in_wrap 'A key is only ever counted here — never read, never printed, never logged, never sent. What an agent opened in the glass inherits is your own environment, unchanged.' $(( SCR_W - 6 ))
  for (( i = 0; i < ${#WRP[@]} && i < 2; i++ )); do
    v_text 3 $(( nly + i )) "${WRP[$i]}" $I_DIM
  done
  in_foot ◂▸ pages C cloud ⎋ menu
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE SEVEN SURFACES · letters reach pages, digits reach rows
# ══════════════════════════════════════════════════════════════════════════
# THAT DIVISION IS THE WHOLE KEYBOARD on this machine, and it is why nothing
# here ever has to argue about whether [C] means CONSOLE or CLAUDE: the agents
# are NUMBERED and the pages are LETTERED, so neither can want the other's key.
# EVERY PAGE ON ITS OWN FIRST LETTER · and REWRITE is not one of them: it is a
# tool of the same trade as PROMPTS -- one shelves finished prompts, the other
# turns a rough one into a finished one -- so it lives UNDER prompts, reached
# with [W] there, the way CONSOLE lives under LOCAL.  That is what frees [R] for
# ROUTE, and dropping the manual rescan (the probe runs on its own) frees it too.
IN_PK=(C L R B P H K)
IN_PV=(cloud local route bench prompts hist keys)
IN_PN=(CLOUD LOCAL ROUTE BENCH PROMPTS HISTORY KEYS)
IN_PD=('every agent here · ⏎ opens one in the glass' \
       'models on this disk · ⏎ to chat here or open opencode' \
       'the router picks local, cloud or a subscription' \
       'one prompt, every engine, side by side' \
       'ready to paste · [W] rewrites a rough one' \
       'what has been run from this cabinet' \
       'which providers are authenticated')
typeset -gi IN_PAGES=7

# ── ROUTE · the auto surface · state ──────────────────────────────────────
# THE PREFERENCE IS A DIAL, NOT A GUESS.  Three named modes set how eagerly the
# router spends a metered cloud call; the percentages are the operating points
# the research settled on (prefer-local recovers most of the gap at ~15% cloud,
# balanced at the hardest quarter).  Local is always free and always first.
typeset -gi IN_RMODE=1                       # 0 prefer local · 1 balanced (default) · 2 prefer cloud
typeset -gi IN_ROUTER_UP=0                   # is the LiteLLM proxy answering on :4000
IN_RPROXY_PORT=4000
IN_RMODE_NAME=('prefer local' 'balanced' 'prefer cloud')
IN_RMODE_PCT=('~15% cloud' '~28% cloud' '~75% cloud')
IN_RMODE_DESC=('cloud only for the clearly-hard' 'the hardest quarter goes cloud' 'local only for the easy')
# THE CAP IS ON METERED CLOUD ONLY · a subscription is flat-rate, so no cap could
# touch it.  A per-provider DAILY limit is what actually stops a runaway loop
# inside a day; the monthly is a trailing-30-day ceiling over all of them.  It is
# the proxy that enforces both -- LiteLLM's provider_budget_config and max_budget
# -- so the cap is real only once [G] has written it and the router is restarted.
# 0 is no cap.  The dollars are per provider per day.
IN_BUDGET_OPT=(2 5 10 20 0)
typeset -gi IN_BUDGET_SEL=1
# A CURATED SET the proxy can front once a key is present · discovery fills the
# state at runtime (routable · needs a key · on the CLOUD page as a subscription).
IN_CLOUD_NAME=('OpenAI' 'Anthropic' 'Gemini' 'xAI Grok' 'DeepSeek' 'Mistral')
IN_CLOUD_ENV=('OPENAI_API_KEY' 'ANTHROPIC_API_KEY' 'GEMINI_API_KEY' 'XAI_API_KEY' 'DEEPSEEK_API_KEY' 'MISTRAL_API_KEY')
IN_CLOUD_LLM=('openai/gpt-5.6' 'anthropic/claude-sonnet-5' 'gemini/gemini-3-pro' 'xai/grok-4' 'deepseek/deepseek-chat' 'mistral/mistral-large-latest')
typeset -ga IN_CLOUD_ST                       # per provider · 'key' routable · '' needs a key
# THE COMPOSER · a prompt is held only long enough to rewrite it, decide, and
# open a vehicle.  Its text is never logged (the log keeps the destination, not
# the words) and a secret in it never leaves -- the guard runs before anything.
typeset -g RT_STATE=''                        # '' idle · rw rewriting · (the confirm is IN_GATE, kind route)
typeset -g RT_PROMPT='' RT_KIND='' RT_WHY='' RT_DEST='' RT_LMODEL='' RT_LWHERE=''
typeset -gi RT_AGENT=-1 RT_PROV=-1 RT_LR=-1
# PROVIDER → THE OFFICIAL CLI THAT IS ITS SUBSCRIPTION.  This is the whole of
# how the cabinet ever touches an account: it runs the account's own program,
# never a token of its own.  DeepSeek and Mistral have no agent on the roster,
# so they are API-only (-1) -- a metered key the proxy fronts on this machine,
# never a login this cabinet could proxy.
IN_PROV_AGENT=(3 0 1 2 -1 -1)                 # OpenAI→CODEX · Anthropic→CLAUDE · Gemini→ANTIGRAVITY · xAI→GROK
# WHICH CLOUD MODELS THE PROXY CAN ACTUALLY SPEND · a metered key is a routable
# backend; a subscription is not (that lives on CLOUD as its official CLI).  We
# test only for PRESENCE of the provider's env key -- never its value.
in_cloud_scan() {
  local en; local -i i
  IN_CLOUD_ST=()
  for (( i = 0; i < ${#IN_CLOUD_NAME[@]}; i++ )); do
    if (( IN_MOCK )); then
      (( i < 2 )) && IN_CLOUD_ST+=(key) || IN_CLOUD_ST+=('')
      continue
    fi
    en="${IN_CLOUD_ENV[$i]}"
    [[ -n "${(P)en:-}" ]] && IN_CLOUD_ST+=(key) || IN_CLOUD_ST+=('')
  done
  return 0
}
# THE LiteLLM STARTER · one on-machine proxy fronting the local endpoint and
# every metered cloud key found.  Keys go in as os.environ refs, never written
# out.  It is a working baseline; the auto-router brain is tuned on the Mac.
in_litellm_config() {   # -> ILCF
  local d="${XDG_STATE_HOME:-$HOME/.local/state}/alien" y slug prov first_slug=''
  local -i i mlxport=8081 n=0 cap=${IN_BUDGET_OPT[$IN_BUDGET_SEL]}
  ILCF=''
  mkdir -p "$d" 2>/dev/null || return 1
  y='# generated by the cabinet · litellm --config this --port '"$IN_RPROXY_PORT"$'\n'
  y+='model_list:'$'\n'
  y+='  - model_name: local-auto'$'\n'
  y+='    litellm_params:'$'\n'
  y+='      model: openai/local'$'\n'
  y+='      api_base: http://127.0.0.1:'"$mlxport"'/v1'$'\n'
  y+='      api_key: "not-needed"'$'\n'
  (( ${#IN_CLOUD_ST[@]} )) || in_cloud_scan
  for (( i = 0; i < ${#IN_CLOUD_NAME[@]}; i++ )); do
    [[ "${IN_CLOUD_ST[$i]:-}" == key ]] || continue
    slug="${${(L)IN_CLOUD_NAME[$i]}// /}"
    [[ -n "$first_slug" ]] || first_slug="$slug"
    y+='  - model_name: cloud-'"$slug"$'\n'
    y+='    litellm_params:'$'\n'
    y+='      model: '"${IN_CLOUD_LLM[$i]}"$'\n'
    y+='      api_key: os.environ/'"${IN_CLOUD_ENV[$i]}"$'\n'
    (( n++ ))
  done
  y+='litellm_settings:'$'\n'
  y+='  drop_params: true'$'\n'
  y+='  num_retries: 2'$'\n'
  # THE MONTHLY CEILING · litellm_settings.max_budget is a global trailing-30-day
  # cap in USD (its duration is fixed at 30 days upstream, which is exactly the
  # month we want).  Derived from the daily so the two knobs stay one knob.
  (( cap > 0 )) && y+='  max_budget: '"$(( cap * 30 ))"$'\n'
  # THE HYBRID BASELINE · everything asks local-auto first.  A local error steps
  # up to the first cloud key found (fallbacks), and a prompt too big for local's
  # context does too (context_window_fallbacks) -- the one difficulty signal a
  # proxy can read for itself.  The semantic cascade is layered on top, on the Mac.
  (( n )) && y+='  fallbacks: [{"local-auto": ["cloud-'"$first_slug"'"]}]'$'\n'
  (( n )) && y+='  context_window_fallbacks: [{"local-auto": ["cloud-'"$first_slug"'"]}]'$'\n'
  y+='guardrails:'$'\n'
  y+='  - guardrail_name: egress'$'\n'
  y+='    litellm_params:'$'\n'
  y+='      guardrail: alien_guard.EgressGuard'$'\n'
  y+='      mode: pre_call'$'\n'
  # THE DAILY CAP · one per metered provider, the window LiteLLM enforces from
  # router_settings.provider_budget_config.  A subscription has no entry here at
  # all -- it is not a routable backend, so there is nothing to meter.  The key
  # is the provider LiteLLM parses from the model id (`anthropic/…` → anthropic).
  if (( cap > 0 && n )); then
    y+='router_settings:'$'\n'
    y+='  provider_budget_config:'$'\n'
    for (( i = 0; i < ${#IN_CLOUD_NAME[@]}; i++ )); do
      [[ "${IN_CLOUD_ST[$i]:-}" == key ]] || continue
      prov="${IN_CLOUD_LLM[$i]%%/*}"
      y+='    '"$prov"':'$'\n'
      y+='      budget_limit: '"$cap"$'\n'
      y+='      time_period: 1d'$'\n'
    done
  fi
  print -r -- "$y" > "$d/litellm.yaml" 2>/dev/null || return 1
  chmod 600 "$d/litellm.yaml" 2>/dev/null
  ILCF="$d/litellm.yaml"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE EGRESS GUARD · what must not leave this machine
# ══════════════════════════════════════════════════════════════════════════
# FAIL CLOSED · a deterministic scan for secrets, keys and credentials.  It runs
# before anything the cabinet sends to a cloud engine, and it can only ever keep
# a prompt LOCAL -- never send one.  Near-zero false positives, biased that way
# on purpose: an over-block costs a keystroke, a miss cannot be undone.  The
# report names the CATEGORY, never the value.
typeset -gi IN_PIN_LOCAL=0          # the reader pinned this session local-only
typeset -g IGS_WHAT=''
in_guard_scan() {   # in_guard_scan TEXT -> IGS (1 sensitive) · IGS_WHAT
  local t="$1"
  IGS=0; IGS_WHAT=''
  setopt localoptions extendedglob
  [[ "$t" == *"-----BEGIN "*"PRIVATE KEY-----"* ]] && { IGS=1; IGS_WHAT='a private key'; return 0 }
  [[ "$t" == *sk-ant-* ]]                          && { IGS=1; IGS_WHAT='an Anthropic key'; return 0 }
  [[ "$t" == *AKIA[A-Z0-9](#c16)* ]]               && { IGS=1; IGS_WHAT='an AWS key'; return 0 }
  [[ "$t" == (*ghp_*|*gho_*|*ghs_*) ]]             && { IGS=1; IGS_WHAT='a GitHub token'; return 0 }
  [[ "$t" == *sk-[A-Za-z0-9_-](#c20,)* ]]          && { IGS=1; IGS_WHAT='an API key'; return 0 }
  [[ "$t" == *eyJ[A-Za-z0-9_-]##.[A-Za-z0-9_-]##.* ]] && { IGS=1; IGS_WHAT='a token'; return 0 }
  [[ "$t" == *://[A-Za-z0-9]##:*@* ]]              && { IGS=1; IGS_WHAT='a connection string'; return 0 }
  return 0
}
# THE SAME GUARD, FOR THE PROXY · a LiteLLM pre-call guardrail in Python so the
# router path is covered too.  Written here, run on the Mac; it never blocks a
# local route, and blocked traffic never leaves.
in_guard_hook() {   # -> IGHF
  local d="${XDG_STATE_HOME:-$HOME/.local/state}/alien"
  IGHF=''
  mkdir -p "$d" 2>/dev/null || return 1
  print -r -- '# generated by the cabinet · a fail-closed egress guard for LiteLLM
# it is wired into the generated litellm.yaml under guardrails: (egress, pre_call)
import re
from litellm.integrations.custom_guardrail import CustomGuardrail
from litellm.proxy._types import UserAPIKeyAuth
PATTERNS = [
    ("a private key", re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("an Anthropic key", re.compile(r"sk-ant-")),
    ("an OpenAI key", re.compile(r"sk-[A-Za-z0-9_-]{20,}")),
    ("an AWS key", re.compile(r"AKIA[A-Z0-9]{16}")),
    ("a GitHub token", re.compile(r"gh[pos]_[A-Za-z0-9]{20,}")),
    ("a JWT", re.compile(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.")),
    ("a connection string", re.compile(r"[a-z]+://[^\s:@/]+:[^\s@]+@")),
]
class EgressGuard(CustomGuardrail):
    async def async_pre_call_hook(self, user_api_key_dict: UserAPIKeyAuth, cache, data, call_type):
        model = str(data.get("model", ""))
        if model.startswith("local") or model.startswith("router"):
            return data  # a local route is never blocked
        text = " ".join(str(m.get("content", "")) for m in data.get("messages", []) if isinstance(m, dict))
        for what, rx in PATTERNS:
            if rx.search(text):
                raise ValueError("egress blocked: the prompt contains " + what + "; it was kept off the cloud")
        return data
' > "$d/alien_guard.py" 2>/dev/null || return 1
  chmod 600 "$d/alien_guard.py" 2>/dev/null
  IGHF="$d/alien_guard.py"
  return 0
}

IN_VIEW='menu'
typeset -gi IN_SEL=0 IN_PAGE=0 IN_MROW=0

# ══════════════════════════════════════════════════════════════════════════
# CHANGING WHAT IS ON THE GLASS · through the raster, never in place of it
# ══════════════════════════════════════════════════════════════════════════
# THE SAME CHANNEL CHANGE THE MONITOR USES, because it is the same code: the
# raster lets go, collapses to a line, and unfolds again with the new surface
# already on it.  The transition -- its stages, its curves, its timing, the
# wash it lays over the new page -- lives in the CABINET (xf_arm / xf_frame
# in terminal.command) beside the tube it is drawn through, which is what
# both packs actually have in common.  This file only says WHEN: in_go_view
# arms it, intel_draw paints the standing page, the cabinet runs the frames
# between.
# ...AND EACH PAGE KEEPS ITS OWN LINE.  The field is one buffer, and it
# used to follow the reader from page to page: a question typed on BENCH was
# waiting in the CONSOLE's field, and ⏎ there put it in front of whatever was
# typed next.  The line is put away with the page it was typed on and taken
# out again with it.
typeset -gA IN_LINE_OF
in_go_view() {   # in_go_view DEST — the only way IN_VIEW is ever written
  [[ "$1" == "$IN_VIEW" ]] && return 0
  IN_LINE_OF[$IN_VIEW]="$IN_LINE"
  IN_VIEW="$1"
  in_line_set "${IN_LINE_OF[$1]:-}"
  local -i i
  for (( i = 0; i < IN_PAGES; i++ )); do
    [[ "${IN_PV[$i]}" == "$1" ]] && { IN_PAGE=$i; break }
  done
  xf_arm
  return 0
}

# ONE BLANK ROW, BUILT ONCE · the footer clears its row with it
IN_ROW=''
in_row_init() {
  [[ ${#IN_ROW} == $SCR_W ]] && return 0
  local -i i
  IN_ROW=''
  for (( i = 0; i < SCR_W; i++ )); do IN_ROW+=' '; done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# REWRITE · a rough prompt in, a prompt any model will follow well out
# ══════════════════════════════════════════════════════════════════════════
# THE ONE PAGE THAT WRITES FOR YOU RATHER THAN ABOUT THE MACHINE.  Type what
# you mean in a line; an engine of your choosing -- the local model already
# serving on this machine, or any cloud agent installed here that can answer
# one question and stop -- rewrites it the way a prompt engineer would: role
# and goal up front, the context it needs, the task made explicit, the
# constraints and the shape of the answer spelled out.  What comes back is
# shown beside what went in, with the engine's own notes on what it changed,
# and ⏎ puts the rewritten prompt on the clipboard for whichever model you
# were going to use.
#
# THE LOCAL ENGINE IS THE DEFAULT when one is up, for the same reason the
# CONSOLE exists: the prompt never leaves the machine.  A cloud engine is a
# real call on your own account, and the page says so while it runs.
#
# HISTORY GETS A LINE, NOT A PROMPT.  Like the bench and the library: the
# engine and how long it took, never the words.
typeset -g RW_STATE='' RW_ENGINE='' RW_LOG='' RW_USE='' RW_BODY='' RW_DIR=''
typeset -g RW_IN='' RW_OUT='' RW_PROMPT='' RW_NOTES='' RW_PICKED='' RW_KEEP='' RW_TOK=''
typeset -gi RW_PID=0 RW_ESEL=0 RW_TOP=0 RW_PK_OPEN=0 RW_PKSEL=0 RW_PKTOP=0 RW_MTYPE=0 RW_PLAIN=0
# RW_ROUTE · set only by the ROUTE composer · when the rewrite it started lands,
# the tick reads the result and routes it, instead of the page showing it.
typeset -gi RW_ROUTE=0
typeset -gF RW_T0=0.0 RW_FIRST=0.0 RW_END=0.0 RW_POLL=0.0
typeset -ga RW_EK RW_EI RW_EM RW_EN RW_ES   # engines · kind · runner/agent · model · name · note
typeset -ga RW_PK RW_PT                     # the picker's rows · engine index (-1 = a heading) · text
typeset -gA RW_CUSTOM                       # agent index → a model the reader typed for it
typeset -g RW_PK_FOR='rewrite'              # who opened it · rewrite (every engine) · console (the local ones)

# WHAT THE ENGINE IS TOLD.  Two things this used to leave out are now said
# outright: do not invent what the rough line does not contain (a placeholder
# marks the gap instead), and do not pad -- a rewritten prompt that is three
# times longer than it needs to be is worse than the rough one.
RW_SYSTEM='You are an expert prompt engineer. Rewrite the rough prompt below into a clear, complete, self-contained prompt that any capable AI model will follow well. Keep the user'"'"'s intent, facts and constraints exactly. Do not invent facts, names, numbers or requirements the rough prompt does not contain; where something the model will need is missing, leave a short bracketed placeholder such as [your audience] for the user to fill in. Never answer the prompt yourself. Apply these practices: open with the role the model should take and the goal; supply the context and definitions the model needs; state the task explicitly and unambiguously; list the constraints and what to avoid; specify the output format, length and tone; add a short example when it clarifies; tell the model to state its assumptions or ask for missing information rather than guess; for a complex task, ask it to reason step by step before giving the final answer. Keep it as short as the task allows: no padding, no restating, and if the rough prompt is already good, tighten it rather than expand it. Write in the same language as the rough prompt. Output ONLY the rewritten prompt, with no title, no preamble and no code fence, then a line containing exactly --- and then three to five short bullets, each starting with "- ", saying what you changed and why. Nothing after the bullets.'

# THE SAME WORK WITH NO PLACEHOLDERS · the mode the router reuses.  REWRITE'"'"'s
# default leaves [bracketed] gaps for you to fill, which is right when you are
# crafting a prompt by hand -- but a gap cannot be auto-sent, so this variant is
# told to add NOTHING it was not given: no bracketed slots, and no invented
# specifics to fill them either.  A prompt that is missing something stays
# general rather than guessing.  [P] on REWRITE flips between the two.
RW_SYSTEM_SEND='You are an expert prompt engineer. Rewrite the rough prompt below into a clear, complete, self-contained prompt that any capable AI model will follow well and that is ready to use exactly as written. Keep the intent, facts and constraints of the rough prompt exactly. Do NOT invent facts, names, numbers or requirements the rough prompt does not contain, and do NOT insert placeholders or bracketed slots such as [your audience]: the result must be usable with no further editing. Where the rough prompt leaves something unspecified, keep the request general rather than inventing a specific value or leaving a blank to fill in. Never answer the prompt yourself. Apply these practices where they fit what was given: open with the role the model should take and the goal; state the task explicitly; list the constraints and what to avoid; specify the output format, length and tone; for a complex task, ask the model to reason step by step before the final answer; and tell it to state any assumptions it makes rather than guess silently. Keep it as short as the task allows: no padding, no restating, and if the rough prompt is already good, tighten it rather than expand it. Write in the same language as the rough prompt. Output ONLY the rewritten prompt, with no title, no preamble and no code fence, then a line containing exactly --- and then three to five short bullets, each starting with "- ", saying what you changed and why. Nothing after the bullets.'

# ── which engines can rewrite · every model on every up runner, then the agents ─
# AN ENGINE IS A MODEL, NOT A RUNNER.  /v1/models is each runner's own list --
# for ollama that is every model it holds, which it loads on demand; for
# llama-server the one file it was started on; for LM Studio what is loaded --
# so every one of them is a row, and an embedding model is left off because
# it cannot write a sentence.  The cloud rows are each agent that can answer
# one question, as it is configured, then claude's three tiers by their short
# names, then any model the reader typed for an agent that takes a flag.
rw_engines() {   # rw_engines [local] — every engine, or only the ones on this machine
  local -i i j k n
  local m note served only="${1:-}"
  local -a ms
  RW_EK=(); RW_EI=(); RW_EM=(); RW_EN=(); RW_ES=()
  for (( i = 0; i < IN_RN; i++ )); do
    (( ${IR[$i.up]:-0} )) || continue
    served="${IR[$i.served]:-}"
    ms=("${(@s: · :)served}")
    (( ${#ms[@]} )) || ms=('')
    for m in "${ms[@]}"; do
      [[ "$m" == *embed* ]] && continue
      note=''
      if [[ -n "$m" ]]; then
        in_is_resident "$m"; (( IRES )) && note='resident'
        if [[ -z "$note" ]]; then
          for (( j = 0; j < IM_N; j++ )); do
            [[ "${IM_NAME[$j]}" == "$m" ]] && { note="${IM_SIZE[$j]}"; break }
          done
        fi
        [[ -n "$note" ]] || note='serving'
      else
        note='up · no model named'
      fi
      RW_EK+=(local); RW_EI+=($i); RW_EM+=("$m"); RW_ES+=("$note")
      RW_EN+=("${IN_RNAME[$i]}${m:+ · $m}")
    done
  done
  [[ "$only" == local ]] && { n=${#RW_EK[@]}; RW_ESEL=0; return 0 }
  in_askable
  for i in "${IASK[@]}"; do
    RW_EK+=(cloud); RW_EI+=($i); RW_EM+=(''); RW_ES+=('its default')
    RW_EN+=("${IN_NAME[$i]} · ${IA[$i.model]:-default}")
    [[ -n "${IN_MFLAG[$i]}" ]] || continue
    for m in ${=IN_MALIAS[$i]}; do
      RW_EK+=(cloud); RW_EI+=($i); RW_EM+=("$m"); RW_ES+=('alias')
      RW_EN+=("${IN_NAME[$i]} · $m")
    done
    m="${RW_CUSTOM[$i]:-}"
    [[ -n "$m" ]] || continue
    RW_EK+=(cloud); RW_EI+=($i); RW_EM+=("$m"); RW_ES+=('typed')
    RW_EN+=("${IN_NAME[$i]} · $m")
  done
  # THE CHOICE SURVIVES THE LIST CHANGING.  It is remembered as WHAT it was,
  # not where it sat, and found again each time -- or, if that model has
  # gone, the first engine standing takes over, which is a local one whenever
  # a runner is up.
  n=${#RW_EK[@]}
  RW_ESEL=0
  if [[ -n "$RW_PICKED" ]]; then
    for (( k = 0; k < n; k++ )); do
      [[ "${RW_EK[$k]}|${RW_EI[$k]}|${RW_EM[$k]}" == "$RW_PICKED" ]] && { RW_ESEL=$k; break }
    done
  fi
  return 0
}
rw_engine_name() {   # -> RWEN · the chosen engine, or what is missing
  rw_engines
  if (( ${#RW_EK[@]} == 0 )); then RWEN='nothing up that can rewrite'; return 1; fi
  RWEN="${RW_EN[$RW_ESEL]}"
  return 0
}
rw_engine_pick() {   # rw_engine_pick K
  local -i k=$1
  (( k >= 0 && k < ${#RW_EK[@]} )) || return 1
  RW_PICKED="${RW_EK[$k]}|${RW_EI[$k]}|${RW_EM[$k]}"
  RW_ESEL=$k
  say "engine · ${RW_EN[$k]}"
  return 0
}

# ── the picker · a box over the page, one row per engine ────────────────────
# [E] USED TO CYCLE, which is fine for three engines and hopeless for twelve:
# every press was a guess at what the next one would be.  A list you can see
# is the honest version.  The cursor is an ENGINE index; headings are rows the
# cursor steps over.
rw_pick_open() {   # rw_pick_open [console]
  local -i k
  RW_PK_FOR="${1:-rewrite}"
  if [[ "$RW_PK_FOR" == console ]]; then
    rw_engines local
    (( ${#RW_EK[@]} )) || { say 'no local model is up · start a runner on LOCAL'; snd no; return 1 }
    rw_pick_rows
    RW_PKSEL=0
    for (( k = 0; k < ${#RW_EK[@]}; k++ )); do
      (( ${RW_EI[$k]} == CH_RUNNER )) && [[ "${RW_EM[$k]}" == "$CH_MODEL" ]] && { RW_PKSEL=$k; break }
    done
  else
    rw_engines
    (( ${#RW_EK[@]} )) || { say 'no engine · start a local model on LOCAL, or sign in to an agent on CLOUD'; snd no; return 1 }
    rw_pick_rows
    RW_PKSEL=$RW_ESEL
  fi
  RW_MTYPE=0
  RW_PK_OPEN=1
  modal_open
  return 0
}
rw_pick_take() {   # ⏎ in the picker · whichever page opened it gets the row
  if [[ "$RW_PK_FOR" == console ]]; then in_chat_pick $RW_PKSEL
  else rw_engine_pick $RW_PKSEL; fi
  rw_pick_close
  return 0
}
rw_pick_close() { RW_MTYPE=0; RW_PK_OPEN=2; modal_close; return 0 }
rw_pick_rows() {
  local -i k
  local was=''
  RW_PK=(); RW_PT=()
  for (( k = 0; k < ${#RW_EK[@]}; k++ )); do
    if [[ "${RW_EK[$k]}" != "$was" ]]; then
      was="${RW_EK[$k]}"
      RW_PK+=(-1)
      if [[ "$was" == local ]]; then RW_PT+=('LOCAL · nothing leaves this machine')
      else RW_PT+=('CLOUD · a real call, on your own account'); fi
    fi
    RW_PK+=($k); RW_PT+=('')
  done
  return 0
}
rw_pick_row_of() {   # rw_pick_row_of K -> RWROW · the row the engine sits on
  local -i r
  RWROW=0
  for (( r = 0; r < ${#RW_PK[@]}; r++ )); do (( ${RW_PK[$r]} == $1 )) && { RWROW=$r; return 0 }; done
  return 0
}
rw_pick_move() {   # rw_pick_move N → 0 if it moved
  local -i c=$(( RW_PKSEL + $1 )) n=${#RW_EK[@]}
  (( n )) || return 1
  (( c < 0 )) && c=0
  (( c > n - 1 )) && c=$(( n - 1 ))
  (( c == RW_PKSEL )) && return 1
  RW_PKSEL=$c
  return 0
}
# [M] IN THE PICKER: a model of the reader's own, for an agent that takes one.
# The rough line is put aside while the field is borrowed, and put back.
rw_model_ask() {
  local -i i=${RW_EI[$RW_PKSEL]}
  if [[ "${RW_EK[$RW_PKSEL]}" != cloud || -z "${IN_MFLAG[$i]:-}" ]]; then
    say 'that one is picked from the list · [M] types a model for claude or codex'; snd no; return 0
  fi
  RW_KEEP="$IN_LINE"
  in_line_set "${RW_CUSTOM[$i]:-}"
  RW_MTYPE=1; IN_MODE='edit'
  snd pick
  return 0
}
rw_model_typed() {   # ⏎ in that field
  local m="${IN_LINE## }"; m="${m%% }"
  local -i i=${RW_EI[$RW_PKSEL]} k
  RW_MTYPE=0
  in_line_set "$RW_KEEP"
  if [[ -z "$m" ]]; then
    [[ -n "${RW_CUSTOM[$i]:-}" ]] && unset "RW_CUSTOM[$i]"
    rw_engines; rw_pick_rows
    (( RW_PKSEL >= ${#RW_EK[@]} )) && RW_PKSEL=$(( ${#RW_EK[@]} - 1 ))
    say 'nothing typed · the list stands'; snd away
    return 0
  fi
  RW_CUSTOM[$i]="$m"
  rw_engines; rw_pick_rows
  for (( k = 0; k < ${#RW_EK[@]}; k++ )); do
    [[ "${RW_EK[$k]}" == cloud && ${RW_EI[$k]} -eq $i && "${RW_EM[$k]}" == "$m" ]] && { rw_engine_pick $k; break }
  done
  rw_pick_close; snd pick
  return 0
}
rw_model_untyped() {   # ⎋ in that field
  RW_MTYPE=0
  in_line_set "$RW_KEEP"
  snd away
  return 0
}

rw_draw_pick() {
  local -i x=10 y=3 w=86 h=22 r rr k e i yy col rows=14 n now=-1
  local s note nm
  v_fill $x $y $w $h ' ' $GREY $GLASS
  if [[ "$RW_PK_FOR" == console ]]; then rw_engines local; else rw_engines; fi
  rw_pick_rows
  n=${#RW_EK[@]}
  (( n )) || { in_panel $x $y $w $h 'THE ENGINE' 'NOTHING STANDING'; return 0 }
  (( RW_PKSEL >= n )) && RW_PKSEL=$(( n - 1 ))
  (( RW_PKSEL < 0 )) && RW_PKSEL=0
  # WHICH ROW IS THE ONE IN USE depends on who is asking: REWRITE's chosen
  # engine, or the model the console is talking to.
  if [[ "$RW_PK_FOR" == console ]]; then
    for (( k = 0; k < n; k++ )); do
      (( ${RW_EI[$k]} == CH_RUNNER )) && [[ "${RW_EM[$k]}" == "$CH_MODEL" ]] && { now=$k; break }
    done
    in_panel $x $y $w $h 'THE MODEL' "$n UP"
    v_text $(( x + 3 )) $(( y + 1 )) 'which local model the console talks to · every model on every runner that is up' $I_LBL
  else
    now=$RW_ESEL
    in_panel $x $y $w $h 'THE ENGINE' "$n STANDING"
    v_text $(( x + 3 )) $(( y + 1 )) 'which model rewrites your line · every model on every up runner, then the agents' $I_LBL
  fi
  rw_pick_row_of $RW_PKSEL; r=$RWROW
  in_scroll_into $r $RW_PKTOP $rows ${#RW_PK[@]}; RW_PKTOP=$ITOP
  for (( rr = 0; rr < rows; rr++ )); do
    k=$(( RW_PKTOP + rr ))
    (( k >= ${#RW_PK[@]} )) && break
    yy=$(( y + 3 + rr ))
    e=${RW_PK[$k]}
    if (( e < 0 )); then
      cmix $WHITE $PURPLE 0.35
      v_text $(( x + 3 )) $yy "${RW_PT[$k]}" $CM
      continue
    fi
    i=${RW_EI[$e]}
    in_glide rwpick $RW_PKSEL $e
    in_band $(( x + 1 )) $yy $(( w - 3 )) $IGS
    (( IGON )) && { cmix $WHITE $LIME 0.3; v_put $(( x + 2 )) $yy '▸' $CM $IBG }
    # THE DOT SAYS WHAT IT SAYS EVERYWHERE ELSE ON THIS MACHINE: lit when the
    # thing is awake -- a resident model, a signed-in agent -- and not when
    # the first answer will have to wait for it.
    if [[ "${RW_EK[$e]}" == local ]]; then
      nm="${IN_RNAME[$i]}"
      [[ "${RW_ES[$e]}" == resident || "${RW_ES[$e]}" == serving ]] && col=$I_OK || { cshade $GREY 0.55; col=$CS }
    else
      nm="${IN_NAME[$i]}"
      [[ "${IA[$i.state]:-no}" == ok ]] && col=$I_OK || { cshade $GREY 0.55; col=$CS }
    fi
    (( col == I_OK )) && v_put $(( x + 4 )) $yy '●' $col $IBG || v_put $(( x + 4 )) $yy '○' $col $IBG
    (( IGON )) && col=$I_WHITE || col=$I_LBL
    in_ell "$nm" 13; v_text $(( x + 6 )) $yy "$ELL" $col $IBG
    if [[ "${RW_EK[$e]}" == local ]]; then s="${RW_EM[$e]:-—}"
    elif [[ -n "${RW_EM[$e]}" ]]; then s="${RW_EM[$e]}"
    else s="${IA[$i.model]:-default}"; fi
    (( IGON )) && { cmix $WHITE $LIME 0.2; col=$CM } || col=$I_FG
    in_ell "$s" 42; v_text $(( x + 20 )) $yy "$ELL" $col $IBG
    (( IGON )) && col=$I_LBL || col=$I_DIM
    in_ell "${RW_ES[$e]}" 16; v_text $(( x + 63 )) $yy "$ELL" $col $IBG
    if (( e == now )); then cmix $WHITE $LIME 0.4; in_right $(( x + w - 3 )) $yy 'now' $CM $IBG; fi
  done
  in_scroll_mark $(( x + w - 2 )) $(( y + 3 )) $rows $RW_PKTOP $rows ${#RW_PK[@]}
  # THE LAST LINE IS THE FIELD, OR THE THING WORTH KNOWING about the row the
  # cursor is on.
  e=$RW_PKSEL; i=${RW_EI[$e]}
  if (( RW_MTYPE )); then
    in_draw_line $(( x + 5 )) $(( y + 19 )) $(( w - 10 )) "a model id for ${IN_NAME[$i]} · ⏎ uses it · ⎋ keeps the list"
  else
    cshade $GREY 0.95
    if [[ "${RW_EK[$e]}" == local ]]; then
      if (( i == 0 )); then s='ollama loads whichever you pick · the first answer takes a moment longer'
      else s="${IN_RNAME[$i]} holds what it was started on · start it on another file to change it"; fi
    elif [[ -n "${IN_MFLAG[$i]:-}" ]]; then
      s="[M] types a model id for ${IN_NAME[$i]} · anything its ${IN_MFLAG[$i]} flag takes"
    else
      s="${IN_NAME[$i]} runs the model it is configured with"
    fi
    v_text $(( x + 3 )) $(( y + 19 )) "$s" $CS
  fi
  if (( RW_MTYPE )); then in_foot ⏎ 'use that model' ⎋ 'the list'
  elif [[ "$RW_PK_FOR" == console ]]; then in_foot ▴▾ choose ⏎ 'talk to it' ⎋ keep
  else in_foot ▴▾ choose ⏎ 'use it' M 'type a model' ⎋ keep; fi
  return 0
}

# ── the run ────────────────────────────────────────────────────────────────
rw_reset() {
  rw_stop
  in_tmp_drop "$RW_LOG"; in_tmp_drop "$RW_USE"; in_tmp_drop "$RW_BODY"
  RW_LOG=''; RW_USE=''; RW_BODY=''
  RW_STATE=''; RW_OUT=''; RW_PROMPT=''; RW_NOTES=''; RW_TOP=0; RW_TOK=''
  RW_FIRST=0.0; RW_END=0.0
  return 0
}
rw_stop() {
  [[ "$RW_STATE" == run ]] || return 1
  (( RW_PID > 1 )) && in_kill_tree $RW_PID
  RW_PID=0
  RW_STATE='stopped'; RW_END=$(( IN_NOW - RW_T0 ))
  rw_split
  return 0
}
rw_start() {
  local cmd url body msgs kind model sys
  local -i i
  sys="$RW_SYSTEM"; (( RW_PLAIN )) && sys="$RW_SYSTEM_SEND"
  [[ -n "$IN_LINE" ]] || { say 'nothing to rewrite'; snd no; return 1 }
  rw_engine_name || { say 'no engine · start a local model or sign in to an agent'; snd no; return 1 }
  rw_reset
  RW_IN="$IN_LINE"
  kind="${RW_EK[$RW_ESEL]}"; i=${RW_EI[$RW_ESEL]}; model="${RW_EM[$RW_ESEL]}"
  RW_ENGINE="${RW_EN[$RW_ESEL]}"
  # THE GUARD BEFORE A CLOUD ENGINE · a secret is never sent out to be rewritten,
  # and a session pinned local refuses the cloud outright.  A local engine never
  # leaves the machine, so it is not gated.
  if [[ "$kind" != local ]]; then
    if (( IN_PIN_LOCAL )); then say 'session pinned local · a cloud engine is off'; snd no; return 1; fi
    in_guard_scan "$RW_IN"
    (( IGS )) && { say "kept local · the prompt has ${IGS_WHAT}"; snd no; return 1 }
  fi
  in_tmp alien-rw || { say 'nowhere to write the answer'; snd no; return 1 }
  RW_LOG="$ITMP"
  if [[ "$kind" == local ]]; then
    (( ${+commands[curl]} )) || { say 'no curl on this machine'; snd no; return 1 }
    (( ${+commands[awk]} ))  || { say 'no awk on this machine'; snd no; return 1 }
    in_tmp alien-rw-use || { say 'nowhere to write the answer'; snd no; return 1 }
    RW_USE="$ITMP"
    in_json_esc "$sys"; msgs="{\"role\":\"system\",\"content\":\"$IJE\"}"
    in_json_esc "ROUGH PROMPT:"$'\n'"$RW_IN"; msgs+=",{\"role\":\"user\",\"content\":\"$IJE\"}"
    # THE MODEL IS THE ONE PICKED, and a runner asked for a model it holds
    # but has not loaded loads it.  Low temperature, on purpose: this is
    # editing, and editing should come out the same way twice.
    in_json_esc "${model:-${${IR[$i.served]:-}%% · *}}"
    body="{\"model\":\"$IJE\",\"stream\":true,\"temperature\":0.3,\"messages\":[$msgs]}"
    in_tmp alien-rw-body || { say 'nowhere to write the request'; snd no; return 1 }
    RW_BODY="$ITMP"
    print -rn -- "$body" > "$RW_BODY" 2>/dev/null
    url="http://127.0.0.1:${IN_RPORT[$i]}/v1/chat/completions"
    # THE REQUEST GOES IN A FILE, NOT ON A COMMAND LINE · see in_chat_send
    cmd="curl -sN --max-time 300 -H 'Content-Type: application/json'"
    cmd+=" --data-binary @$(_sh "$RW_BODY") $(_sh "$url")"
    cmd+=" | ALIEN_USE=$(_sh "$RW_USE") awk $(_sh "$IN_SSE_AWK")"
    (( IN_MOCK )) && cmd="ALIEN_USE=$(_sh "$RW_USE"); $IN_MOCK_REWRITE"
    # `_rc` FIRST.  `$?` after the blank-line print was the PRINT's status,
    # so a curl that failed outright reported 0 and read as a rewrite that
    # merely came back empty.
    { zsh -lc "$cmd"; _rc=$?; print -r -- ""; print -r -- "__RC__ $_rc" } >>"$RW_LOG" 2>/dev/null </dev/null &!
  else
    in_tmpdir alien-rw || { say 'could not make a scratch directory'; snd no; return 1 }
    RW_DIR="$ITMP"
    # THE WHOLE INSTRUCTION IS THE PROMPT for an agent in print mode: it has
    # no system channel from here, so the practices go in front of the line.
    # The model, when one was picked, goes in through the agent's own flag.
    cmd="cd $(_sh "$RW_DIR") && $(_sh "${IA[$i.path]}") ${IN_ASK[$i]}"
    [[ -n "$model" && -n "${IN_MFLAG[$i]:-}" ]] && cmd+=" ${IN_MFLAG[$i]} $(_sh "$model")"
    cmd+=" $(_sh "$sys"$'\n\n'"ROUGH PROMPT:"$'\n'"$RW_IN")"
    (( IN_MOCK )) && cmd="$IN_MOCK_REWRITE"
    { zsh -lc "$cmd"; _rc=$?; print -r -- ""; print -r -- "__RC__ $_rc" } >>"$RW_LOG" 2>&1 </dev/null &!
  fi
  RW_PID=$!
  RW_STATE='run'; RW_T0=$IN_NOW; RW_POLL=0.0
  say "rewriting · $RW_ENGINE"; snd pick
  return 0
}
# THE ANSWER IS THE PROMPT, A RULE, AND THE NOTES · split on the first line
# that is exactly ---.  A model that ignored the shape gives a prompt and no
# notes, which is still a prompt.
#
# ...AND WHAT A MODEL WRAPS AROUND ITS ANSWER IS TAKEN OFF FIRST.  A thinking
# model's thoughts (<think>…</think>), a code fence around the whole prompt, a
# title line saying "Rewritten prompt:", and -- when the --- never came -- a
# headed list of changes at the end, which is the notes under another name.
# Each of these was a real answer from a real small model that the old
# splitter handed back with the dressing still on.
rw_clean() {   # rw_clean TEXT -> RWC
  local s="$1"
  s="${s//$'\r'/}"
  while [[ "$s" == *"<think>"*"</think>"* ]]; do s="${s%%"<think>"*}${s#*"</think>"}"; done
  [[ "$s" == *"<think>"* ]] && s="${s%%"<think>"*}"
  RWC="$s"; return 0
}
rw_label_p() {   # rw_label_p LINE → 0 if it is a title and not a sentence
  local lab="${1//[*#:_.[:space:]]/}"
  lab="${lab:l}"
  [[ "$lab" == (hereis|heres|)(the|your|a|)(rewritten|improved|final|new|better|)(prompt|version) ]] && return 0
  [[ "$lab" == (whatchanged|whatichanged|changes|changesmade|changelog|notes|notesonchanges|whyitchanged) ]] && return 0
  return 1
}
rw_split() {
  setopt localoptions extendedglob
  local line pre='' post=''
  local -i seen=0 j
  local -a ls
  rw_clean "$RW_OUT"; local out="$RWC"
  for line in "${(@f)out}"; do
    if (( ! seen )) && [[ "${line//[[:space:]]/}" == '---' ]]; then seen=1; continue; fi
    if (( seen )); then post+="$line"$'\n'; else pre+="$line"$'\n'; fi
  done
  if (( ! seen )); then
    ls=("${(@f)pre}")
    for (( j = ${#ls[@]} - 1; j > 0; j-- )); do
      line="${ls[$j]##[[:space:]]#}"
      [[ "$line" == ([-•*]\ *|<->.\ *) ]] && continue   # a bullet: "- x", "• x", "* x", "1. x"
      [[ -z "$line" ]] && continue
      if rw_label_p "$line"; then
        pre="${(F)ls[0,$(( j - 1 ))]}"$'\n'; post="${(F)ls[$(( j + 1 )),-1]}"$'\n'
      fi
      break
    done
  fi
  while [[ "$pre"  == *$'\n' ]]; do pre="${pre%$'\n'}"; done
  while [[ "$pre"  == $'\n'* ]]; do pre="${pre#$'\n'}"; done
  while [[ "$post" == *$'\n' ]]; do post="${post%$'\n'}"; done
  while [[ "$post" == $'\n'* ]]; do post="${post#$'\n'}"; done
  # a fence around the whole prompt, and a title over it
  ls=("${(@f)pre}")
  if (( ${#ls[@]} >= 2 )) && [[ "${ls[0]}" == '```'* && "${ls[-1]//[[:space:]]/}" == '```' ]]; then
    pre="${(F)ls[1,-2]}"; ls=("${(@f)pre}")
  fi
  if (( ${#ls[@]} >= 2 )) && rw_label_p "${ls[0]}"; then pre="${(F)ls[1,-1]}"; fi
  while [[ "$pre"  == $'\n'* ]]; do pre="${pre#$'\n'}"; done
  # a model that put the notes first has still written a prompt somewhere
  [[ -z "$pre" && -n "$post" ]] && { pre="$post"; post=''; }
  RW_PROMPT="$pre"; RW_NOTES="$post"
  return 0
}
rw_poll() {   # rw_poll T
  local -F t=$1
  local body rc
  [[ "$RW_STATE" == run ]] || return 0
  (( t - RW_POLL < 0.2 )) && return 0
  RW_POLL=$t
  [[ -n "$RW_LOG" && -r "$RW_LOG" ]] || return 0
  body="$(<"$RW_LOG")" 2>/dev/null || body=''
  if [[ "$body" == *$'\n__RC__ '* ]]; then
    rc="${body##*$'\n__RC__ '}"; rc="${rc%%$'\n'*}"
    body="${body%$'\n__RC__ '*}"
    RW_OUT="$body"
    (( RW_FIRST == 0.0 )) && (( ${#body} )) && RW_FIRST=$(( t - RW_T0 ))
    RW_END=$(( t - RW_T0 )); RW_PID=0
    rw_split
    # THE RUNNER'S OWN COUNT of what went in and what came out, for the bar
    RW_TOK=''
    if [[ -n "$RW_USE" && -r "$RW_USE" ]]; then
      local use; use="$(<"$RW_USE")" 2>/dev/null || use=''
      use="${use##*$'\n'}"
      [[ "$use" == <->\ <-> ]] && RW_TOK="${use%% *}→${use#* }"
    fi
    if [[ "$rc" == 0 && -n "${RW_PROMPT//[[:space:]]/}" ]]; then
      RW_STATE='done'; snd coin
      in_log_add rewrite "$RW_ENGINE" "one prompt, rewritten" 1 $(( int(RW_END) ))
    else
      RW_STATE='failed'; snd no
      in_log_add rewrite "$RW_ENGINE" "rewrite failed" 0 $(( int(RW_END) ))
    fi
    in_tmp_drop "$RW_USE"; RW_USE=''
    return 0
  fi
  RW_OUT="$body"
  (( RW_FIRST == 0.0 )) && (( ${#body} )) && RW_FIRST=$(( t - RW_T0 ))
  return 0
}
rw_copy() {
  [[ "$RW_STATE" == done && -n "$RW_PROMPT" ]] || { say 'nothing rewritten yet'; snd no; return 1 }
  if (( ! ${+commands[pbcopy]} )); then say 'no pbcopy on this machine'; snd no; return 1; fi
  print -rn -- "$RW_PROMPT" | pbcopy 2>/dev/null
  local -i n=${(w)#RW_PROMPT}          # words as a reader counts them · (z) counted shell tokens
  say "rewritten prompt · copied · $n words"; snd coin
  in_log_add copy "$RW_ENGINE" "the rewritten prompt, to the clipboard" 1 0
  return 0
}

# ── the page ───────────────────────────────────────────────────────────────
in_draw_rewrite() {
  local s r who col
  local -i i j n keep col2 W=50 L=2 R=54
  # ON THE WHOLE WINDOW the two columns split the glass and grow tall, so more
  # of the rough prompt and its rewrite is on screen at once
  local -i fw=102 ph=19 lines=16 vy=26
  if (( SCR_W > 120 )); then
    fw=$(( SCR_W - 4 )); W=$(( (SCR_W - 6) / 2 )); R=$(( L + W + 2 ))
    ph=$(( SCR_H - 10 )); lines=$(( ph - 3 )); vy=$(( SCR_H - 3 ))
  fi
  local -F el
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  rw_engine_name; who="$RWEN"
  case "$RW_STATE" in
    run)     el=$(( IN_NOW - RW_T0 )); printf -v s 'rewriting · %.1fs' $el; col=$I_FG ;;
    done)    printf -v s 'done · %.1fs' $RW_END; col=$I_OK ;;
    failed)  s='failed'; col=$I_WARNC ;;
    stopped) s='stopped'; col=$I_WARNC ;;
    *)       s='idle'; col=$I_DIM ;;
  esac
  in_head REWRITE 1 "$s" ENGINE "$who" $I_FG

  # ── the rough prompt · one line, yours ──
  local mode; (( RW_PLAIN )) && mode='ready to send' || mode='template'
  if [[ "$RW_STATE" == run ]]; then r='[X] STOP'; else r="[⏎] REWRITE · [E] ENGINE · [P] $mode"; fi
  in_panel 2 3 $fw 4 'THE ROUGH PROMPT' "$r"
  # WHILE THE PICKER HAS BORROWED THE FIELD for a model id, this one shows
  # the rough line it is keeping, at rest, rather than the id being typed.
  if (( RW_MTYPE )); then
    local keepl="$IN_LINE" keepm="$IN_MODE"
    local -i keepi=$IN_LI
    IN_LINE="$RW_KEEP"; IN_MODE='nav'
    in_draw_line 6 4 $(( fw - 8 )) 'press ⏎ and type what you mean, roughly'
    IN_LINE="$keepl"; IN_MODE="$keepm"; IN_LI=$keepi
  else
    in_draw_line 6 4 $(( fw - 8 )) 'press ⏎ and type what you mean, roughly'
  fi
  if (( ${#RW_EK[@]} == 0 )); then
    cshade $GREY 0.95
    v_text 4 5 'no engine is up · start a local model on LOCAL, or sign in to an agent on CLOUD' $CS
  elif [[ "${RW_EK[$RW_ESEL]}" == local ]]; then
    cshade $GREY 0.95
    v_text 4 5 'this model rewrites it here · nothing leaves this machine · [E] picks another' $CS
  else
    cshade $GREY 0.95
    v_text 4 5 'a real call, on your own account · [E] picks a local model instead when one is up' $CS
  fi

  # ── before, and after ──
  in_panel $L 7 $W $ph 'BEFORE'
  if [[ -n "$RW_IN" ]]; then
    in_wrap_keep "$RW_IN" $(( W - 4 ))
    for (( j = 0; j < ${#WRP[@]} && j < lines; j++ )); do
      v_text $(( L + 2 )) $(( 8 + j )) "${WRP[$j][0,$(( W - 5 ))]}" $I_LBL
    done
    # ...AND UNDER IT, WHAT THE ENGINE CHANGED, once it has: the notes live
    # beside the prompt they explain, where there is room to read them.
    if [[ "$RW_STATE" == done && -n "$RW_NOTES" ]]; then
      i=$(( 9 + j ))
      if (( i < ph + 3 )); then
        v_hline $(( L + 1 )) $i $(( W - 2 )) '─' $I_DIM
        v_text $(( L + 2 )) $i ' WHAT CHANGED ' $AMBER
        (( i++ ))
        local note
        cmix $WHITE $AMBER 0.4; col2=$CM
        for note in "${(@f)RW_NOTES}"; do
          note="${note#- }"; note="${note#• }"; note="${note#\* }"; note="${note#<->. }"
          [[ -n "${note//[[:space:]]/}" ]] || continue
          in_wrap_keep "$note" $(( W - 6 ))
          for (( j = 0; j < ${#WRP[@]} && i < ph + 5; j++ )); do
            if (( j == 0 )); then v_text $(( L + 2 )) $i "· ${WRP[$j][0,$(( W - 7 ))]}" $col2
            else v_text $(( L + 4 )) $i "${WRP[$j][0,$(( W - 7 ))]}" $col2; fi
            (( i++ ))
          done
        done
      fi
    fi
  else
    cshade $GREY 0.9
    v_text $(( L + 2 )) 9 'what you typed goes here, as you typed it' $CS
  fi
  case "$RW_STATE" in
    done) r='[⏎] COPIES IT' ;;
    run)  r="$RW_ENGINE" ;;
    *)    r='' ;;
  esac
  in_panel $R 7 $W $ph 'AFTER' "$r"
  local body="$RW_OUT"
  if [[ "$RW_STATE" == done ]]; then body="$RW_PROMPT"; fi
  body="${body//$'\t'/  }"
  if [[ -z "${body//[[:space:]]/}" ]]; then
    case "$RW_STATE" in
      run)    case $(( int(IN_NOW * 3) % 3 )) in 0) body='·' ;; 1) body='··' ;; *) body='···' ;; esac ;;
      failed) body='(nothing usable came back · [A] tries again)' ;;
      *)      body='' ;;
    esac
  fi
  if [[ -n "$body" ]]; then
    in_wrap_keep "$body" $(( W - 4 ))
    n=${#WRP[@]}
    # a running answer shows its tail; a finished one is read from the top,
    # and ▴▾ scroll it when it is longer than the box
    if [[ "$RW_STATE" == run ]] && (( n > lines )); then keep=$(( n - lines ))
    else
      keep=$RW_TOP; (( keep > n - lines )) && keep=$(( n - lines )); (( keep < 0 )) && keep=0
      RW_TOP=$keep
    fi
    cmix $WHITE $LIME 0.2; col2=$CM
    for (( j = 0; j + keep < n && j < lines; j++ )); do
      v_text $(( R + 2 )) $(( 8 + j )) "${WRP[$(( j + keep ))][0,$(( W - 5 ))]}" $col2
    done
    in_scroll_mark $(( R + W - 2 )) 8 $lines $keep $lines $n
  elif [[ -z "$RW_STATE" ]]; then
    cshade $GREY 0.9
    v_text $(( R + 2 )) 9 'the rewritten prompt lands here' $CS
    v_text $(( R + 2 )) 11 'role and goal up front · the context it needs' $CS
    v_text $(( R + 2 )) 12 'the task made explicit · constraints spelled out' $CS
    v_text $(( R + 2 )) 13 'the shape of the answer · an example where it helps' $CS
  fi

  # ── what changed, on its own lit bar ──
  cmix $GLASS $AMBER 0.22; local -i vb=$CM
  v_fill 2 $vy $fw 1 ' ' $GREY $vb
  v_text 4 $vy 'VERDICT' $I_LBL $vb
  if [[ "$RW_STATE" == done ]]; then
    local -i nw=${(w)#RW_PROMPT} nn=0
    for s in "${(@f)RW_NOTES}"; do [[ -n "${s//[[:space:]]/}" ]] && (( nn++ )); done
    # THE ENGINE GOES LAST: the head strip names it too, so it is the part
    # that can afford to lose letters when the bar runs out of room.
    printf -v r '%d words · %d changes noted · %.1fs' $nw $nn $RW_END
    (( RW_FIRST > 0.0 )) && { printf -v s ' · first word %.1fs' $RW_FIRST; r+="$s" }
    [[ -n "$RW_TOK" ]] && r+=" · $RW_TOK tokens"
    r+=" · $RW_ENGINE"
    in_ell "$r" $(( fw - 16 ))
    v_text 13 $vy "$ELL" $I_FG $vb
  elif [[ "$RW_STATE" == run ]]; then
    v_text 13 $vy "$RW_ENGINE is rewriting it" $I_FG $vb
  elif [[ "$RW_STATE" == failed ]]; then
    v_text 13 $vy 'nothing usable came back · [A] asks again, [E] tries another engine' $I_WARNC $vb
  elif [[ "$RW_STATE" == stopped ]]; then
    v_text 13 $vy 'stopped before it finished · [A] asks again' $I_WARNC $vb
  else
    v_text 13 $vy 'the engine says what it changed, and why, once it is done' $I_DIM $vb
  fi
  case "$RW_STATE" in
    run)  in_foot X stop ◂▸ 'another page' ⎋ menu ;;
    done) in_foot ⏎ 'copy the prompt' A 'ask again' E engine ◂▸ pages ⎋ prompts ;;
    *)    in_foot ⏎ 'type the rough prompt' E engine ◂▸ pages ⎋ prompts ;;
  esac
  return 0
}
IN_MOCK_REWRITE='sleep 0.4
for w in "You are a senior technical writer. " "Explain how a zsh script can do floating-point arithmetic, for a reader who knows bash but not zsh.

" "Cover: (1) that zsh has native floats and bash does not, (2) the (( )) and \$(( )) forms with a worked example, (3) the portable fallbacks (awk, bc) and when to prefer them. " "Keep it under 200 words, in plain prose with one short code block. " "State any assumption you make about the zsh version.
"; do
  print -rn -- "$w"; sleep 0.45
done
print -r -- "---"
print -r -- "- gave the model a role and a reader, so the depth is right"
print -r -- "- split the vague ask into three named points to cover"
print -r -- "- fixed the length and the shape of the answer"
print -r -- "- asked it to state assumptions rather than guess the version"
print -r -- "412 96" > "${ALIEN_USE:-/dev/null}"'

# A SURFACE THAT IS NOT FITTED SAYS SO, in its own words, on its own page.
# Falling back to CLOUD instead is how six pages that do not exist yet look
# exactly like a machine refusing to open anything.
in_draw_soon() {   # in_draw_soon IX
  local -i ix=$1
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  in_head "${IN_PN[$ix]}" 1 '' STATE 'not fitted' $I_WARNC
  in_panel 26 10 54 8 "${IN_PN[$ix]}" 'NOT FITTED'
  cmix $WHITE $PURPLE 0.35
  v_center 12 "${IN_PN[$ix]}" $CM $GLASS 26 54
  v_center 14 "${IN_PD[$ix]}" $I_LBL $GLASS 26 54
  cshade $GREY 0.9
  v_center 16 '◂ ▸ reach the pages that are' $CS $GLASS 26 54
  in_foot ◂▸ 'another page' C cloud ⎋ menu
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# MENU · the machine's own landing, the way SYSTEM has one
# ══════════════════════════════════════════════════════════════════════════
# ONE PAGE THAT IS ABOUT THE MACHINE, NOT INSIDE IT.  The seven surfaces stand
# in a list -- each on its own first letter, its one-line description, and the
# one live number it is about -- and the reader picks one with ⏎ or its letter.
# It is the top of this machine the way OVERVIEW is the top of SYSTEM: ◂ ▸ ring
# the pages from anywhere, ⎋ climbs back here from any of them, and ⎋ here is
# the one that hands the door back its roster.  The number beside each row is
# the same reading that surface prints in its own title bar, read straight from
# the state the probes keep, so nothing here has to go and look.
in_menu_read() {   # in_menu_read IDX -> IMR, the live number this surface is about
  local -i i n=0
  IMR=''
  case "${IN_PV[$1]}" in
    cloud)   for (( i = 0; i < ${IN_N:-0}; i++ )); do (( ${IA[$i.here]:-0} )) && (( n++ )); done
             IMR="$n here" ;;
    local)   n=${IM_N:-0};    IMR="$n on disk" ;;
    route)   IMR="${IN_RMODE_NAME[${IN_RMODE:-1}]:-balanced}" ;;
    prompts) n=${IP_N:-0};    IMR="$n ready" ;;
    hist)    n=${IN_LOG_N:-0}; (( n == 1 )) && IMR='1 run' || IMR="$n runs" ;;
    keys)    for (( i = 0; i < ${IK_N:-0}; i++ )); do (( ${IK_SET[$i]:-0} )) && (( n++ )); done
             IMR="$n set" ;;
    bench)   if (( ${BN_N:-0} )); then
               for (( i = 0; i < BN_N; i++ )); do
                 [[ "${BN_STATE[$i]:-}" == running ]] && { IMR='asking'; return 0; }
                 [[ "${BN_STATE[$i]:-}" == done ]] && (( n++ ))
               done
               IMR="$n of $BN_N in"
             else
               in_askable; n=${#IASK[@]}; (( n > 3 )) && n=3
               if (( n == 1 )); then IMR='1 engine'; else IMR="$n engines"; fi
             fi ;;
  esac
  return 0
}

in_draw_menu() {   # in_draw_menu — the seven surfaces, the switchboard under them, the shelves, the particulars
  # THE LIST, THE BOARD, THE PARTICULARS -- SYSTEM's page, in this machine's
  # own terms.  The seven surfaces up top, each with its reading and a picture
  # of it beside the reading; under them the card's own switchboard reaching
  # from one side of the glass to the other -- the agents and the runners on
  # their lines into the glass, the live ones carrying their pulses, and on a
  # board with the rows for it what each line carries written under it; on a
  # tall wide glass the three shelves under the board (the models on this
  # disk, the prompts, what has been run); and along the foot the machine's
  # particulars.  A job takes the shelves' place while there is one, or on a
  # glass without shelves the particulars'.  The still part is painted once
  # per reading of the machine and kept; the cursor's band, the pulses and a
  # running job are live over it.
  in_menu_geom
  in_title_key
  in_menu_key
  glass_cached "in.menu|$IN_MPK|${IN_JOB_STATE:-}|$CAPTION|$IN_MN_SIG" in_menu_base
  in_menu_rows
  if [[ "$IN_BOARD_SIG" == "$IN_MN_BSX|$IN_MN_BSY|$IN_MN_BCW|$IN_MN_BCH" ]]; then
    in_board_live $IN_NOW 0
  else
    GLASS_KEY=''                                   # the board was painted somewhere else since · next frame paints it here again
  fi
  [[ -n "${IN_JOB_STATE:-}" ]] && (( IN_MN_SH )) && in_draw_job $IN_MN_SY $IN_MN_SH
  return 0
}
typeset -gi IN_MN_PX=2 IN_MN_PW=102 IN_MN_PY=3 IN_MN_PH=9 IN_MN_BSX=0 IN_MN_BSY=0 IN_MN_BCW=0 IN_MN_BCH=0
typeset -gi IN_MN_TY=0 IN_MN_TH=0 IN_MN_R1=0 IN_MN_FY=0 IN_MN_SY=0 IN_MN_SH=0 IN_MN_WIDE=0
typeset -g  IN_MN_SIG=''
in_menu_geom() {   # where the list page puts things on this glass -> IN_MN_*
  # THE MAP, SYSTEM's: the list three rows down, the particulars' rule seven
  # rows up from the foot of the cabinet's glass and six up from the foot of
  # the whole window's, the board in what is left between them with a row of
  # air either side -- and on a wide glass with the rows for them, the three
  # shelves under the board, the board taller when there is room for both
  local -i top bot avail ch tb=0 gap=0 lead
  IN_MN_WIDE=0; (( SCR_W > 120 )) && IN_MN_WIDE=1
  if (( IN_MN_WIDE )); then IN_MN_PX=3; IN_MN_PW=$(( SCR_W - 6 )); IN_MN_R1=$(( SCR_H - 6 ))
  else                      IN_MN_PX=2; IN_MN_PW=$(( SCR_W - 4 )); IN_MN_R1=$(( SCR_H - 7 )); fi
  IN_MN_FY=$(( IN_MN_R1 + 1 ))
  IN_MN_PY=3; IN_MN_PH=$(( IN_PAGES + 2 ))
  top=$(( IN_MN_PY + IN_MN_PH + 1 )); bot=$(( IN_MN_R1 - 2 )); avail=$(( bot - top + 1 ))
  if (( IN_MN_WIDE && avail >= 11 + 1 + 7 )); then
    if (( avail - 17 - 1 >= 9 )); then ch=15; else ch=9; fi
    gap=1; tb=$(( avail - (ch + 2) - gap )); (( tb > 12 )) && tb=12
  else
    ch=$(( avail - 2 ))
    if (( ch >= 15 )); then ch=15; elif (( ch >= 9 )); then ch=9; else ch=7; fi
  fi
  lead=$(( (avail - (ch + 2) - (tb ? tb + gap : 0)) / 2 )); (( lead < 0 )) && lead=0
  IN_MN_BCH=$ch; IN_MN_BCW=$(( SCR_W - 6 )); IN_MN_BSX=2; IN_MN_BSY=$(( top + lead ))
  IN_MN_TH=$tb; IN_MN_TY=$(( IN_MN_BSY + ch + 2 + gap ))
  # A JOB, while there is one, where the shelves are -- or on a glass without
  # them, over the particulars
  IN_MN_SH=0; IN_MN_SY=0
  if [[ -n "${IN_JOB_STATE:-}" ]]; then
    if (( tb )); then IN_MN_SY=$IN_MN_TY; IN_MN_SH=$tb
    else              IN_MN_SY=$IN_MN_R1; IN_MN_SH=4; fi
  fi
  IN_MN_SIG="${SCR_W}x${SCR_H}|$IN_MN_BSY|$IN_MN_BCH|$IN_MN_TH|$IN_MN_SH"
  return 0
}
typeset -g IN_MPK=''
in_menu_key() {   # in_menu_key -> IN_MPK · everything the list page's still part and its pictures are a picture of
  in_menu_inks
  IN_MPK="$ITKEY|${IN_RMODE:-1}|${IN_ROUTER_UP:-0}|${IP_N:-0}|${BN_N:-0}${(j::)BN_STATE[@]}|${(j:,:)IZ_NAME[@]}|${(j:,:)IM_SIZE[@]}|${(j:,:)IN_LOG_T[@]}|$IN_MI_KEY"
  return 0
}
in_menu_base() {   # the list page's still part · the band, the list, the board, the shelves, the particulars
  local -i i here=0 up=0 tw tx
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  # THE MACHINE'S HEADLINE, in the title bar the way every page carries its
  # own: the agents on this machine, the models on its disk, the runners up
  for (( i = 0; i < ${IN_N:-0}; i++ )); do (( ${IA[$i.here]:-0} )) && (( here++ )); done
  for (( i = 0; i < ${IN_RN:-0}; i++ )); do (( ${IR[$i.up]:-0} )) && (( up++ )); done
  in_head MENU 0 '' \
     AGENTS  "$here"      $I_WHITE \
     LOCAL   "${IM_N:-0}" $I_FG \
     RUNNERS "$up"        $I_FG
  # NO MAKER'S LINE OVER THE LIST, and no CHOOSE ONE on its rule: the list sits
  # right under the band, its rows right under its rule, as SYSTEM's do
  in_panel $IN_MN_PX $IN_MN_PY $IN_MN_PW $IN_MN_PH SURFACES
  in_menu_rows
  IN_BOARD_MENU=1
  in_board_paint $IN_MN_BSX $IN_MN_BSY $IN_MN_BCW $IN_MN_BCH
  IN_BOARD_MENU=0
  if (( IN_MN_TH )) && [[ -z "${IN_JOB_STATE:-}" ]]; then
    tw=$(( (IN_MN_BCW + 2 - 4) / 3 )); tx=$IN_MN_BSX
    in_shelf_models  $tx $IN_MN_TY $tw $IN_MN_TH
    in_shelf_prompts $(( tx + tw + 2 )) $IN_MN_TY $tw $IN_MN_TH
    in_shelf_runs    $(( tx + 2 * (tw + 2) )) $IN_MN_TY $(( IN_MN_BCW + 2 - 2 * (tw + 2) )) $IN_MN_TH
  fi
  (( IN_MN_SH && IN_MN_SY == IN_MN_R1 )) || in_menu_facts
  in_foot ▴▾ choose ⏎ open ⎋ out
  return 0
}

# ── the list ──────────────────────────────────────────────────────────────
typeset -g  IN_MI_KEY=''
typeset -gi IN_MI_DOFF=0 IN_MI_DON=0 IN_MI_ROFF=0 IN_MI_OFF=0 IN_MI_EMP=0 IN_MI_OK=0 IN_MI_TRK=0 IN_MI_PRM=0 IN_MI_SUB=0 IN_MI_SUBD=0
typeset -gi IN_MENU_READ=12                    # the readings' column, as wide as the widest of them
in_menu_inks() {   # the list page's inks, worked out when the palette is new
  local key="$I_LBL|$I_WHITE|$I_FG|$GREY|$PURPLE|$MAGENTA|$PINK"
  [[ "$key" == "$IN_MI_KEY" ]] && return 0
  IN_MI_KEY="$key"
  cmix $I_LBL $I_WHITE 0.35; IN_MI_DON=$CM
  cshade $I_LBL 0.82;        IN_MI_DOFF=$CS
  cshade $I_FG 0.74;         IN_MI_ROFF=$CS
  cshade $GREY 0.36;         IN_MI_OFF=$CS     # the empty part of a meter, off the cursor's band
  cshade $GREY 0.62;         IN_MI_EMP=$CS     # and on it
  cmix $CYAN $LIME 0.5;      IN_MI_OK=$CM
  cshade $GREY 0.55;         IN_MI_TRK=$CS     # the route dial's track
  cmix $PURPLE $PINK 0.40;   IN_MI_PRM=$CM     # the prompt shelves
  cshade $GREY 0.92;         IN_MI_SUB=$CS     # what a live line on the board carries
  cshade $GREY 0.48;         IN_MI_SUBD=$CS    # and a line that is not
  return 0
}
in_menu_rows() {   # the seven rows · the band under the cursor glides, so they are live
  local -i i j n y px=$IN_MN_PX pw=$IN_MN_PW py=$IN_MN_PY on bg col xr vx dw
  local read
  local -a xs ts ks
  in_menu_inks
  in_menu_pics
  # THE COLUMNS, SYSTEM's · the reading ends three in from the box's right
  # edge, its picture in a ten-cell column just before it, and the
  # description has the rest of the row to itself
  xr=$(( px + pw - 3 )); vx=$(( xr - IN_MENU_READ - 10 )); dw=$(( vx - 2 - (px + 18) ))
  for (( i = 0; i < IN_PAGES; i++ )); do
    y=$(( py + 1 + i ))
    in_glide menu $IN_MROW $i; on=$IGON
    in_band $(( px + 1 )) $y $(( pw - 2 )) $IGS; bg=$IBG
    if (( on )); then cmix $WHITE $LIME 0.3; v_put $(( px + 2 )) $y '▸' $CM $bg
    else                                     v_put $(( px + 2 )) $y ' ' $I_DIM $bg; fi
    if (( on )); then col=$AMBER; else cshade $AMBER 0.6; col=$CS; fi
    v_text $(( px + 4 )) $y "[${IN_PK[$i]}]" $col $bg
    (( on )) && col=$I_WHITE || col=$I_LBL
    v_text $(( px + 8 )) $y "${(r:9:)IN_PN[$i]}" $col $bg
    # the line under each name readable from across the room, not only under the cursor
    (( on )) && col=$IN_MI_DON || col=$IN_MI_DOFF
    in_ell "${IN_PD[$i]}" $dw
    v_text $(( px + 18 )) $y "$ELL" $col $bg
    if [[ -n "${IN_MP_X[$i]:-}" ]]; then
      xs=(${=IN_MP_X[$i]}); ts=("${(@ps:\t:)IN_MP_T[$i]}")
      if (( on )); then ks=(${=IN_MP_K1[$i]}); else ks=(${=IN_MP_K0[$i]}); fi
      n=${#xs[@]}
      for (( j = 0; j < n; j++ )); do v_text $(( vx + xs[j] )) $y "${ts[$j]}" ${ks[$j]} $bg; done
    fi
    in_menu_read $i; read="$IMR"
    (( ${#read} > IN_MENU_READ )) && { in_ell "$read" $IN_MENU_READ; read="$ELL"; }
    if (( on )); then col=$I_FG; else col=$IN_MI_ROFF; fi
    in_right $xr $y "$read" $col $bg
  done
  return 0
}

# ── each row's picture · the ten cells before its reading ──────────────────
# ONE LOOK SAYS WHAT THE NUMBER BESIDE IT ONLY COUNTS.  CLOUD a mark a line in
# the board's own inks; LOCAL every model on the disk as a bar as tall as it is
# big, in its runner's ink; ROUTE the dial, its knob where the preference is
# set and lit while the router answers; BENCH its three columns in their own
# three inks; PROMPTS a bar a shelf; HISTORY the last ten runs, each as tall as
# it was long; KEYS the share of the providers with a key, on SYSTEM's meter.
# Worked out again only when what they are pictures of has changed -- the
# rows are redrawn every frame for the cursor's band, and the pictures are not.
typeset -g  IN_MP_GEN=''
typeset -ga IN_MP_X IN_MP_T IN_MP_K0 IN_MP_K1 IMS_X IMS_T IMS_K0 IMS_K1 IN_SHC
typeset -ga IN_LVL; IN_LVL=('' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
typeset -gi IMK0=0 IMK1=0 IWK=0
typeset -gF IGV=0.0
in_mp_ink() { IMK1=$1; cshade $1 0.78; IMK0=$CS; return 0 }   # in_mp_ink INK -> IMK1 and its off-row shade IMK0
in_mp_seg() {   # in_mp_seg X TEXT ON OFF — a run of a picture, joined to the last one when it carries on in the same inks
  local -i n=${#IMS_X[@]}
  if (( n )) && (( IMS_K1[n - 1] == $3 && IMS_K0[n - 1] == $4 && IMS_X[n - 1] + ${#IMS_T[n - 1]} == $1 )); then
    IMS_T[$(( n - 1 ))]+="$2"; return 0
  fi
  IMS_X+=($1); IMS_T+=("$2"); IMS_K1+=($3); IMS_K0+=($4)
  return 0
}
in_gb() {   # in_gb SIZE -> IGV · a size the way the pages print one ("13 GB", "274 MB"), in gigabytes
  local s="${1%% *}" u="${1##* }"
  IGV=0.0
  [[ "$s" == <->(|.<->) ]] || return 0
  IGV=$s
  case "${(U)u}" in
    TB) IGV=$(( IGV * 1024.0 )) ;;
    MB) IGV=$(( IGV / 1024.0 )) ;;
    KB) IGV=$(( IGV / 1048576.0 )) ;;
  esac
  return 0
}
in_gbs() {   # in_gbs GB -> IGS · a total, short
  if (( $1 >= 100.0 )); then printf -v IGS '%.0f GB' $1
  else                       printf -v IGS '%.1f GB' $1; fi
  return 0
}
in_where_ink() {   # in_where_ink WHERE -> IWK · a model's runner, as an ink
  case "$1" in
    ollama) IWK=$CYAN ;;
    gguf)   IWK=$AMBER ;;
    mlx)    IWK=$MAGENTA ;;
    *)      cshade $GREY 0.8; IWK=$CS ;;
  esac
  return 0
}
in_shelf_counts() {   # in_shelf_counts -> IN_SHC · how many prompts on each of IP_CATS's shelves
  local -i j k nc=${#IP_CATS[@]}
  IN_SHC=()
  for (( k = 0; k < nc; k++ )); do IN_SHC+=(0); done
  for (( j = 0; j < ${IP_N:-0}; j++ )); do
    for (( k = 0; k < nc; k++ )); do
      [[ "${IP_CAT[$j]:-}" == "${IP_CATS[$k]}" ]] && { (( IN_SHC[k]++ )); break }
    done
  done
  return 0
}
in_menu_pics() {   # every row's picture -> IN_MP_*
  [[ "$IN_MP_GEN" == "$IN_MPK" ]] && return 0
  IN_MP_GEN="$IN_MPK"
  local -i i j n w p s k mx
  local -F v vmax
  IN_MP_X=(); IN_MP_T=(); IN_MP_K0=(); IN_MP_K1=()
  for (( i = 0; i < IN_PAGES; i++ )); do
    IMS_X=(); IMS_T=(); IMS_K0=(); IMS_K1=()
    case "${IN_PV[$i]}" in
      cloud)
        n=${IN_N:-0}; (( n > 5 )) && n=5; w=$(( 2 * n - 1 ))
        for (( j = 0; j < n; j++ )); do
          in_tc_line 0 $j; in_mp_ink $ITN
          in_mp_seg $(( 10 - w + 2 * j )) "$ITG" $IMK1 $IMK0
        done ;;
      local)
        n=${IM_N:-0}; (( n > 10 )) && n=10
        vmax=0.0
        for (( j = 0; j < n; j++ )); do in_gb "${IM_SIZE[$j]:-}"; (( IGV > vmax )) && vmax=$IGV; done
        (( vmax > 0.0 )) || n=0
        for (( j = 0; j < n; j++ )); do
          in_gb "${IM_SIZE[$j]:-}"
          p=$(( int(IGV / vmax * 8.0 + 0.5) )); (( p < 1 )) && p=1; (( p > 8 )) && p=8
          in_where_ink "${IM_WHERE[$j]:-}"; in_mp_ink $IWK
          in_mp_seg $(( 10 - n + j )) "${IN_LVL[$p]}" $IMK1 $IMK0
        done ;;
      route)
        p=$(( 1 + 3 * ${IN_RMODE:-1} ))           # the knob at 2, 5 or 8 of the dial's nine
        in_mp_ink $IN_MI_TRK
        _run $(( p - 1 )) '─'; (( p > 1 )) || RUN=''
        in_mp_seg 1 "┠$RUN" $IMK1 $IMK0
        if (( ${IN_ROUTER_UP:-0} )); then in_mp_ink $I_OK; else in_mp_ink $I_WARNC; fi
        in_mp_seg $(( 1 + p )) '●' $IMK1 $IMK0
        in_mp_ink $IN_MI_TRK
        _run $(( 7 - p )) '─'; (( p < 7 )) || RUN=''
        in_mp_seg $(( 2 + p )) "$RUN┨" $IMK1 $IMK0 ;;
      bench)
        if (( ${BN_N:-0} )); then
          n=$BN_N; (( n > 5 )) && n=5; w=$(( 2 * n - 1 ))
          for (( j = 0; j < n; j++ )); do
            case "${BN_STATE[$j]:-}" in
              done)    in_mp_ink ${IN_ASK_INK[$(( j % 3 ))]} ;;
              running) in_mp_ink $IN_MI_TRK ;;
              *)       in_mp_ink $I_WARNC ;;
            esac
            in_mp_seg $(( 10 - w + 2 * j )) '●' $IMK1 $IMK0
          done
        else
          in_askable; n=${#IASK[@]}; (( n > 3 )) && n=3; w=$(( 2 * n - 1 ))
          for (( j = 0; j < n; j++ )); do
            in_mp_ink ${IN_ASK_INK[$j]}; in_mp_seg $(( 10 - w + 2 * j )) '●' $IMK1 $IMK0
          done
        fi ;;
      prompts)
        in_shelf_counts; n=${#IN_SHC[@]}; (( n > 10 )) && n=10
        mx=0; for (( j = 0; j < n; j++ )); do (( IN_SHC[j] > mx )) && mx=${IN_SHC[$j]}; done
        if (( mx )); then
          for (( j = 0; j < n; j++ )); do
            p=$(( (IN_SHC[j] * 8 + mx / 2) / mx )); (( IN_SHC[j] && p < 1 )) && p=1
            if (( p )); then in_mp_ink $IN_MI_PRM; in_mp_seg $(( 10 - n + j )) "${IN_LVL[$p]}" $IMK1 $IMK0
            else              in_mp_seg $(( 10 - n + j )) '▁' $IN_MI_EMP $IN_MI_OFF; fi
          done
        fi ;;
      hist)
        n=${IN_LOG_N:-0}; (( n > 10 )) && n=10
        vmax=1.0
        for (( j = 0; j < n; j++ )); do v=$(( log(1.0 + ${IN_LOG_SEC[$j]:-0}) )); (( v > vmax )) && vmax=$v; done
        for (( j = n - 1; j >= 0; j-- )); do
          p=$(( int(log(1.0 + ${IN_LOG_SEC[$j]:-0}) / vmax * 8.0 + 0.5) )); (( p < 1 )) && p=1; (( p > 8 )) && p=8
          if (( ${IN_LOG_OK[$j]:-0} )); then in_mp_ink $IN_MI_OK; else in_mp_ink $I_WARNC; fi
          in_mp_seg $(( 9 - j )) "${IN_LVL[$p]}" $IMK1 $IMK0
        done ;;
      keys)
        n=${IK_N:-0}
        if (( n )); then
          s=0; for (( j = 0; j < n; j++ )); do (( ${IK_SET[$j]:-0} )) && (( s++ )); done
          p=$(( (s * 8 + n / 2) / n )); (( s && p < 1 )) && p=1; (( p > 8 )) && p=8
          if (( p )); then _run $p '▰'; in_mp_ink $IN_MI_OK; in_mp_seg 2 "$RUN" $IMK1 $IMK0; fi
          if (( p < 8 )); then _run $(( 8 - p )) '▱'; in_mp_seg $(( 2 + p )) "$RUN" $IN_MI_EMP $IN_MI_OFF; fi
        fi ;;
    esac
    IN_MP_X+=("${(j: :)IMS_X[@]}"); IN_MP_T+=("${(pj:\t:)IMS_T[@]}")
    IN_MP_K1+=("${(j: :)IMS_K1[@]}"); IN_MP_K0+=("${(j: :)IMS_K0[@]}")
  done
  return 0
}

# ── the shelves · three instruments under the board, on a tall wide glass ──
in_iframe() {   # in_iframe X Y W H TITLE [RIGHT] — an instrument: black inside, the board's own ink round it
  local -i x=$1 y=$2 w=$3 h=$4
  local t="$5" rt="${6:-}"
  in_tc_inks
  v_box $x $y $w $h ${IN_TC_INK[box]} $BLACK round 1
  v_text $(( x + 2 )) $y " $t " $AMBER $BLACK
  [[ -n "$rt" ]] && v_text $(( x + w - ${#rt} - 4 )) $y " $rt " $GREY $BLACK
  return 0
}
in_shelf_bar() {   # in_shelf_bar X Y W FRACTION INK — a gauge in half cells, the board's own heavy line, along a faint track
  # THE BOARD'S LINE, NOT A BLOCK.  Full-height blocks on rows one under the
  # other run together into a wall of colour; a heavy rule keeps every row its
  # own, and it is the line the live wires above are drawn in
  local -i x=$1 y=$2 w=$3 e2 full
  local -F f=$4
  (( f < 0.0 )) && f=0.0; (( f > 1.0 )) && f=1.0
  e2=$(( int(f * w * 2.0 + 0.5) )); (( f > 0.0 && e2 < 1 )) && e2=1
  full=$(( e2 / 2 ))
  cshade $GREY 0.24; _run $w '─'; v_text $x $y "$RUN" $CS $BLACK
  (( full )) && { _run $full '━'; v_text $x $y "$RUN" $5 $BLACK; }
  (( e2 % 2 )) && v_put $(( x + full )) $y '╸' $5 $BLACK
  return 0
}
in_shelf_models() {   # in_shelf_models X Y W H — every model on this disk, biggest first, as long as it is big
  local -i x=$1 y=$2 w=$3 h=$4 n i j r rows bw nw bx show ny lx
  local -F tot=0.0 vmax=0.0 rest=0.0
  local -a ord kinds
  local s kd
  n=${IM_N:-0}
  for (( i = 0; i < n; i++ )); do
    in_gb "${IM_SIZE[$i]:-}"; tot=$(( tot + IGV )); (( IGV > vmax )) && vmax=$IGV
    printf -v s '%014.4f|%d' $IGV $i; ord+=("$s")
  done
  in_gbs $tot
  if (( n )); then in_iframe $x $y $w $h 'MODELS ON DISK' "$IGS"; else in_iframe $x $y $w $h 'MODELS ON DISK'; fi
  rows=$(( h - 2 ))
  if (( ! n )); then
    s='no models on this disk yet'; cshade $GREY 0.8
    v_text $(( x + (w - ${#s}) / 2 )) $(( y + (h - 1) / 2 )) "$s" $CS $BLACK
    return 0
  fi
  ord=("${(@O)ord[@]}")
  bw=$(( w / 4 )); (( bw < 8 )) && bw=8; (( bw > 16 )) && bw=16
  bx=$(( x + w - 10 - bw )); nw=$(( bx - 2 - (x + 4) ))
  show=$n; (( n > rows )) && show=$(( rows - 1 ))
  for (( r = 0; r < show; r++ )); do
    i=${ord[$r]#*|}; ny=$(( y + 1 + r ))
    # A MODEL HELD IN MEMORY wears the LOCAL page's own mark
    in_is_resident "${IM_NAME[$i]}"
    if (( IRES )); then v_put $(( x + 2 )) $ny '●' $I_OK $BLACK
    else cshade $GREY 0.40; v_put $(( x + 2 )) $ny '·' $CS $BLACK; fi
    in_ell "${IM_NAME[$i]}" $nw
    if (( IRES )); then v_text $(( x + 4 )) $ny "$ELL" $I_WHITE $BLACK
    else                v_text $(( x + 4 )) $ny "$ELL" $I_LBL $BLACK; fi
    in_gb "${IM_SIZE[$i]:-}"; in_where_ink "${IM_WHERE[$i]:-}"
    in_shelf_bar $bx $ny $bw $(( vmax > 0.0 ? IGV / vmax : 0.0 )) $IWK
    in_right $(( x + w - 3 )) $ny "${IM_SIZE[$i]}" $I_FG $BLACK
  done
  if (( show < n )); then
    for (( r = show; r < n; r++ )); do i=${ord[$r]#*|}; in_gb "${IM_SIZE[$i]:-}"; rest=$(( rest + IGV )); done
    in_gbs $rest
    s="+ $(( n - show )) more · $IGS"; cshade $GREY 0.72
    v_text $(( x + 4 )) $(( y + 1 + show )) "$s" $CS $BLACK
  fi
  # THE KEY, ON THE FRAME'S FOOT · a runner's word in the ink its bars wear
  for (( i = 0; i < n; i++ )); do
    [[ " ${(j: :)kinds[@]} " == *" ${IM_WHERE[$i]} "* ]] || kinds+=("${IM_WHERE[$i]}")
  done
  s=''; for kd in "${kinds[@]}"; do s+="${s:+ · }$kd"; done
  lx=$(( x + w - 3 - ${#s} - 2 ))
  v_text $lx $(( y + h - 1 )) " " $GREY $BLACK
  (( lx++ ))
  for (( j = 0; j < ${#kinds[@]}; j++ )); do
    (( j )) && { cshade $GREY 0.6; v_text $lx $(( y + h - 1 )) ' · ' $CS $BLACK; (( lx += 3 )); }
    in_where_ink "${kinds[$j]}"; cshade $IWK 0.85
    v_text $lx $(( y + h - 1 )) "${kinds[$j]}" $CS $BLACK; (( lx += ${#kinds[$j]} ))
  done
  v_text $lx $(( y + h - 1 )) " " $GREY $BLACK
  return 0
}
in_shelf_prompts() {   # in_shelf_prompts X Y W H — the prompt shelves, each as long as it is full
  local -i x=$1 y=$2 w=$3 h=$4 n j r rows mx bw bx show ny
  local -a ord
  local s
  in_shelf_counts; n=${#IN_SHC[@]}
  in_iframe $x $y $w $h 'PROMPT SHELVES' "${IP_N:-0} READY"
  rows=$(( h - 2 ))
  (( n )) || return 0
  mx=0; for (( j = 0; j < n; j++ )); do (( IN_SHC[j] > mx )) && mx=${IN_SHC[$j]}; done
  (( mx )) || mx=1
  # ON A SHORT SHELF the fullest shelves, and how many more there are
  if (( n > rows )); then
    for (( j = 0; j < n; j++ )); do printf -v s '%04d|%04d' ${IN_SHC[$j]} $(( 9999 - j )); ord+=("$s"); done
    ord=("${(@O)ord[@]}"); show=$(( rows - 1 ))
  else
    for (( j = 0; j < n; j++ )); do printf -v s '0|%04d' $(( 9999 - j )); ord+=("$s"); done
    show=$n
  fi
  bx=$(( x + 18 )); bw=$(( w - 18 - 7 )); (( bw < 4 )) && bw=4
  for (( r = 0; r < show; r++ )); do
    j=$(( 9999 - ${ord[$r]#*|} )); ny=$(( y + 1 + r ))
    in_ell "${(L)IP_CATS[$j]}" 14; v_text $(( x + 2 )) $ny "$ELL" $I_LBL $BLACK
    in_shelf_bar $bx $ny $bw $(( IN_SHC[j] * 1.0 / mx )) $IN_MI_PRM
    in_right $(( x + w - 3 )) $ny "${IN_SHC[$j]}" $I_FG $BLACK
  done
  if (( show < n )); then
    s="+ $(( n - show )) more shelves"; cshade $GREY 0.72
    v_text $(( x + 2 )) $(( y + 1 + show )) "$s" $CS $BLACK
  fi
  return 0
}
in_shelf_runs() {   # in_shelf_runs X Y W H — what has been run from this cabinet, newest first
  local -i x=$1 y=$2 w=$3 h=$4 n i rows ny ww
  local s
  n=${IN_LOG_N:-0}
  if (( n )); then in_iframe $x $y $w $h 'RECENT RUNS' "$n THIS SESSION"
  else             in_iframe $x $y $w $h 'RECENT RUNS' 'THIS SESSION'; fi
  rows=$(( h - 2 ))
  if (( ! n )); then
    s='nothing run yet'; cshade $GREY 0.85
    v_text $(( x + (w - ${#s}) / 2 )) $(( y + (h - 1) / 2 - (rows > 2 ? 1 : 0) )) "$s" $CS $BLACK
    if (( rows > 2 )); then
      s='⏎ on CLOUD opens an agent in the glass'; cshade $GREY 0.55
      in_ell "$s" $(( w - 4 ))
      v_text $(( x + (w - ${#ELL}) / 2 )) $(( y + (h - 1) / 2 + 1 )) "$ELL" $CS $BLACK
    fi
    return 0
  fi
  ww=$(( w - 2 - 10 - 8 - 10 - 3 )); (( ww < 6 )) && ww=6
  for (( i = 0; i < n && i < rows; i++ )); do
    ny=$(( y + 1 + i ))
    v_text $(( x + 2 )) $ny "${IN_LOG_T[$i]}" $I_LBL $BLACK
    in_ell "${(L)IN_LOG_KIND[$i]}" 7; cshade $GREY 0.62; v_text $(( x + 12 )) $ny "$ELL" $CS $BLACK
    in_ell "${(L)IN_LOG_WHO[$i]}" $ww; v_text $(( x + 20 )) $ny "$ELL" $I_WHITE $BLACK
    in_secs ${IN_LOG_SEC[$i]:-0}
    in_right $(( x + w - 5 )) $ny "$SEC" $I_FG $BLACK
    if (( ${IN_LOG_OK[$i]:-0} )); then v_put $(( x + w - 3 )) $ny '●' $IN_MI_OK $BLACK
    else                               v_put $(( x + w - 3 )) $ny '●' $I_WARNC $BLACK; fi
  done
  return 0
}

# ── the particulars along the foot ────────────────────────────────────────
in_menu_facts() {   # a rule, and three rows of two · what this machine has, rather than how much
  local -i i j n c1l=2 c1v=11 c2l c2v w1 w2 y
  local -F tot=0.0 big=0.0
  local s bigname='' kd
  local -a k1 v1 k2 v2 held kinds
  local -A cnt
  if (( IN_MN_WIDE )); then c2l=$(( SCR_W / 2 )); else c2l=56; fi
  c2v=$(( c2l + 9 )); w1=$(( c2l - c1v - 2 )); w2=$(( SCR_W - c2v - 2 ))
  v_hline 0 $IN_MN_R1 $SCR_W '─' $I_DIM
  # THE AGENTS SIGNED IN, by name
  s=''
  for (( i = 0; i < ${IN_N:-0}; i++ )); do
    [[ "${IA[$i.state]:-}" == ok ]] && s+="${s:+ · }${(L)IN_NAME[$i]}"
  done
  if [[ -z "$s" ]]; then
    n=0; for (( i = 0; i < ${IN_N:-0}; i++ )); do (( ${IA[$i.here]:-0} )) && (( n++ )); done
    if (( n )); then s='none signed in yet'; else s='none on this machine yet'; fi
  fi
  k1=(AGENTS); v1=("$s")
  # WHAT THE RUNNERS HOLD IN MEMORY, every runner that is up
  s=''; n=0
  for (( i = 0; i < ${IN_RN:-0}; i++ )); do
    (( ${IR[$i.up]:-0} )) || continue
    (( n++ ))
    [[ -n "${IR[$i.served]:-}" ]] && s+="${s:+ · }${IR[$i.served]}"
  done
  if [[ -z "$s" ]]; then (( n )) && s='nothing in memory' || s='no runner is up'; fi
  k1+=(SERVING); v1+=("$s")
  if (( ${IN_ROUTER_UP:-0} )); then s='LiteLLM · answering'; else s='LiteLLM · not answering'; fi
  k1+=(ROUTER); v1+=("$s")
  # THE DISK · how much, and whose
  n=${IM_N:-0}
  for (( i = 0; i < n; i++ )); do
    in_gb "${IM_SIZE[$i]:-}"; tot=$(( tot + IGV ))
    (( IGV > big )) && { big=$IGV; bigname="${IM_NAME[$i]} · ${IM_SIZE[$i]}"; }
    j=${cnt[${IM_WHERE[$i]:-?}]:-0}; cnt[${IM_WHERE[$i]:-?}]=$(( j + 1 ))
    [[ " ${(j: :)kinds[@]} " == *" ${IM_WHERE[$i]:-?} "* ]] || kinds+=("${IM_WHERE[$i]:-?}")
  done
  if (( n )); then
    in_gbs $tot; s="$IGS"
    for kd in "${kinds[@]}"; do s+=" · $kd ${cnt[$kd]}"; done
  else s='no models yet'; fi
  k2=('ON DISK'); v2=("$s")
  if (( n )); then s="$bigname"; else s='—'; fi
  k2+=(LARGEST); v2+=("$s")
  if (( ${IN_LOG_N:-0} )); then
    in_secs ${IN_LOG_SEC[0]:-0}
    s="${IN_LOG_T[0]} · ${(L)IN_LOG_WHO[0]} · $SEC"
    (( ${IN_LOG_OK[0]:-0} )) || s+=' · failed'
  else s='nothing yet this session'; fi
  k2+=('LAST RUN'); v2+=("$s")
  for (( i = 0; i < 3; i++ )); do
    y=$(( IN_MN_FY + i ))
    v_text $c1l $y "${(r:8:)k1[$i]}" $I_LBL
    in_ell "${v1[$i]}" $w1; v_text $c1v $y "$ELL" $I_FG
    v_text $c2l $y "${(r:8:)k2[$i]}" $I_LBL
    in_ell "${v2[$i]}" $w2; v_text $c2v $y "$ELL" $I_FG
  done
  return 0
}

in_surface() {   # in_surface T — whichever page is standing
  case "$IN_VIEW" in
    menu)  in_draw_menu; return 0 ;;
    shell) in_draw_shell $1; return 0 ;;
    cloud) in_draw_cloud ;;
    local) in_draw_local ;;
    route) in_draw_route ;;
    bench) in_draw_bench ;;
    console) in_draw_console ;;
    rewrite) in_draw_rewrite ;;
    prompts) in_draw_prompts ;;
    hist)    in_draw_hist ;;
    keys)    in_draw_keys ;;
    *)     in_draw_soon $IN_PAGE ;;
  esac
  # A BOX THAT IS FOLDING AWAY (state 2) is drawn until the fold is done; a
  # fold that was overtaken by another box opening is simply over.
  if (( IN_PICK_OPEN )); then
    if (( IN_PICK_OPEN == 2 )) && ! modal_busy; then IN_PICK_OPEN=0
    else
      modal_frame 18 6 70 16 in_draw_pick $IN_NOW
      modal_gone && IN_PICK_OPEN=0
    fi
  fi
  if (( IN_GATE )); then
    if (( IN_GATE == 2 )) && ! modal_busy; then IN_GATE=0
    else
      modal_frame 22 7 62 13 in_draw_gate $IN_NOW
      modal_gone && IN_GATE=0
    fi
  fi
  if (( IN_TALK )); then
    if (( IN_TALK == 2 )) && ! modal_busy; then IN_TALK=0
    else
      modal_frame 26 10 54 11 in_draw_talk $IN_NOW
      modal_gone && IN_TALK=0
    fi
  fi
  if (( RW_PK_OPEN )); then
    if (( RW_PK_OPEN == 2 )) && ! modal_busy; then RW_PK_OPEN=0
    else
      modal_frame 10 3 86 22 rw_draw_pick $IN_NOW
      modal_gone && RW_PK_OPEN=0
    fi
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE GATE, AND THE JOB IT STARTS
# ══════════════════════════════════════════════════════════════════════════
# NOTHING IS ASSEMBLED BEHIND YOUR BACK.  [I] and [U] do not install and
# remove; they put the exact line on the glass and wait to be told twice.  The
# line on the gate IS the line that runs -- not a description of it -- and it
# is the roster's own string, so a reader who distrusts it can check it
# against the vendor's page before they answer.
#
# AND THEN IT GETS OUT OF THE WAY.  The gate is the question; once it is
# answered the modal closes and the work goes into the strip along the bottom
# of the page, where RECENT already lives.  A curl-to-bash is a minute of
# network on a good day, and a minute of modal is a minute of cabinet you
# cannot use -- so the job runs beside the picture, and the picture keeps the
# cursor, the pages and the keys it had.
typeset -gi IN_GATE=0 IN_GATE_ROW=0 IN_TALK=0
IN_GATE_KIND=''      # install · remove · pull
IN_GATE_WHO=''       # ...and WHAT, carried rather than looked up: a pull's
                     # row is a catalogue index and an install's is a roster
                     # index, and one table read with the other's number is a
                     # gate that offers to install the wrong thing.
IN_GATE_LINE=''

# WHAT REMOVES IT IS WHAT INSTALLED IT, and the row already knows which that
# was.  Guessing one line for every install of an agent would be wrong for
# three of the four ways it can arrive, so the removal is derived from the
# path the scan actually found and shown on the gate like any other.
in_rm_line() {   # in_rm_line I -> IRM
  local -i i=$1
  local g="${IN_GET[$i]}" b="${IA[$i.bin]:-}" p="${IA[$i.path]:-}"
  IRM=''
  [[ -n "$p" ]] || return 0
  case "${IA[$i.from]:-}" in
    homebrew) IRM="brew uninstall $b"; return 0 ;;
    'npm -g')
      [[ "$g" == 'npm install -g '* ]] && { IRM="npm uninstall -g ${g#npm install -g }"; return 0 }
      IRM="npm uninstall -g $b"; return 0 ;;
  esac
  if [[ "$g" == 'npm install -g '* ]]; then
    IRM="npm uninstall -g ${g#npm install -g }"; return 0
  fi
  # QUOTED, AND THE PATH IT ACTUALLY FOUND.  This used to abbreviate the path
  # back to `~/…` and leave it unquoted, and the result was handed to a fresh
  # login shell -- so an agent at `~/My Tools/bin/claude` produced
  # `rm -f ~/My Tools/bin/claude`, which word-splits into THREE arguments:
  # the agent survived, `$HOME/My` was deleted, and `Tools/bin/claude` was
  # resolved against the cabinet's own working directory and deleted there
  # too.  The gate shows the quoting because the quoting is what runs.
  IRM="rm -f -- $(_sh "$p")"
  return 0
}

# WHAT REMOVES A MODEL IS WHAT HOLDS IT.  A pulled model is a blob in ollama's
# own store, addressed by a name only ollama knows, so `ollama rm` is the only
# thing that can take it back out cleanly -- deleting the blob by hand would
# leave the manifest pointing at nothing.  A .gguf is a plain file, so it is
# the file that goes.  Either way the NAME AND THE PATH ARE SINGLE-QUOTED with
# the same _sh the agent removal trusts: a model called `qwen'; rm -rf ~` is a
# name, not a second command, and the quoting is what the gate shows because
# the quoting is what runs.
in_model_rm_line() {   # in_model_rm_line NAME WHERE PATH -> IRML
  local nm="$1" where="$2" path="$3"
  IRML=''
  if [[ "$where" == ollama ]]; then
    IRML="ollama rm $(_sh "$nm")"
  elif [[ -n "$path" ]]; then
    IRML="rm -f -- $(_sh "$path")"
  fi
  return 0
}

in_gate_open() {   # in_gate_open KIND ROW
  local -i i=$2
  IN_GATE_KIND="$1"; IN_GATE_ROW=$i; IN_GATE_WHO="${IN_NAME[$i]}"
  if [[ "$1" == install ]]; then
    IN_GATE_LINE="${IN_GET[$i]}"
  else
    in_rm_line $i; IN_GATE_LINE="$IRM"
  fi
  IN_GATE=1
  modal_open
  return 0
}

in_gate_close() { IN_GATE=2; modal_close; return 0 }

in_cat_ix() {   # in_cat_ix TAG -> ICX
  local -i i
  ICX=0
  for (( i = 0; i < IN_CAT_N; i++ )); do
    [[ "${IN_CAT_TAG[$i]}" == "$1" ]] && { ICX=$i; return 0 }
  done
  return 0
}

in_draw_gate() {
  local -i x=22 y=7 w=62 h=13 i
  local t s
  v_fill $x $y $w $h ' ' $GREY $GLASS
  case "$IN_GATE_KIND" in
    install) t='INSTALL' ;;
    pull)    t='DOWNLOAD' ;;
    route)   t='ROUTE' ;;
    *)       t='REMOVE' ;;
  esac
  in_ell "$IN_GATE_WHO" 20
  in_panel $x $y $w $h "$t · $ELL" 'NOTHING HAS RUN YET'
  if [[ -z "$IN_GATE_LINE" ]]; then
    v_text $(( x + 3 )) $(( y + 2 )) 'there is no line for this one' $I_WARNC
    v_text $(( x + 3 )) $(( y + 4 )) 'nothing here knows how it arrived on this' $I_LBL
    v_text $(( x + 3 )) $(( y + 5 )) 'machine, so nothing here will guess at how' $I_LBL
    v_text $(( x + 3 )) $(( y + 6 )) 'to take it off again.' $I_LBL
    in_foot ⎋ close
    return 0
  fi
  if [[ "$IN_GATE_KIND" == route && "$RT_DEST" == local ]]; then
    v_text $(( x + 3 )) $(( y + 2 )) 'it sends this to a local model:' $I_LBL
  else
    v_text $(( x + 3 )) $(( y + 2 )) 'this exact line, in a shell of its own:' $I_LBL
  fi
  in_wrap "$IN_GATE_LINE" $(( w - 8 ))
  cmix $WHITE $AMBER 0.4
  # CLIPPED, BECAUSE in_wrap CANNOT BREAK A WORD.  An nvm or volta removal is
  # one unbreakable 79-character path, and it came back at full length and was
  # drawn unclipped -- twenty-one columns past this modal's right border, out
  # across the page underneath it, which the box does not paint over.
  for (( i = 0; i < ${#WRP[@]} && i < 3; i++ )); do
    v_text $(( x + 3 )) $(( y + 4 + i )) "${WRP[$i][0,$(( w - 7 ))]}" $CM
  done
  cshade $GREY 0.95
  case "$IN_GATE_KIND" in
    install)
      v_text $(( x + 3 )) $(( y + 8 ))  'it reaches the network and writes' $CS
      v_text $(( x + 3 )) $(( y + 9 ))  'outside this folder.' $CS ;;
    pull)
      in_cat_ix "$IN_GATE_WHO"
      printf -v s '%.1f gb over the network, into ollama'"'"'s store.' ${IN_CAT_GB[$ICX]}
      v_text $(( x + 3 )) $(( y + 8 )) "$s" $CS
      in_ell "${IN_CAT_WHY[$ICX]}" $(( w - 8 ))
      v_text $(( x + 3 )) $(( y + 9 )) "$ELL" $CS ;;
    drop)
      if [[ "$IN_GATE_LINE" == 'ollama rm '* ]]; then
        v_text $(( x + 3 )) $(( y + 8 )) 'it deletes this model from the ollama store.' $CS
      else
        v_text $(( x + 3 )) $(( y + 8 )) 'it deletes the .gguf file from this disk.' $CS
      fi
      v_text $(( x + 3 )) $(( y + 9 )) 'the space comes back. nothing else changes.' $CS ;;
    route)
      in_ell "why · $RT_WHY" $(( w - 8 ))
      v_text $(( x + 3 )) $(( y + 7 )) "$ELL" $I_DIM
      if [[ "$RT_DEST" == sub ]]; then
        v_text $(( x + 3 )) $(( y + 8 )) 'it runs one prompt on your own account —' $CS
        v_text $(( x + 3 )) $(( y + 9 )) 'its own CLI, no key and no proxy.' $CS
      elif [[ "$RT_DEST" == local ]]; then
        v_text $(( x + 3 )) $(( y + 8 )) 'it stays on this machine · free —' $CS
        v_text $(( x + 3 )) $(( y + 9 )) 'the answer opens in the console.' $CS
      else
        v_text $(( x + 3 )) $(( y + 8 )) 'it opens in the glass, on router/auto —' $CS
        v_text $(( x + 3 )) $(( y + 9 )) 'the proxy picks local or a metered call.' $CS
      fi ;;
    *)
      v_text $(( x + 3 )) $(( y + 8 ))  'it takes the agent off this machine.' $CS
      v_text $(( x + 3 )) $(( y + 9 ))  'whatever it was configured with stays.' $CS ;;
  esac
  cmix $WHITE $LIME 0.35
  if [[ "$IN_GATE_KIND" == route && "$RT_DEST" == local ]]; then
    v_text $(( x + 3 )) $(( y + 11 )) 'the answer streams here, in the console' $CM
  else
    v_text $(( x + 3 )) $(( y + 11 )) 'it runs in the strip, not in a modal' $CM
  fi
  in_foot Y 'run it' N 'not now' ⎋ 'not now'
  return 0
}

# ── the little chooser · how you want to talk to the model under the cursor ──
# ⏎ on a LOCAL model used to open opencode outright; now it asks, because the
# console and opencode are two real answers and the reader is the one who knows
# which they want.  [1] the quick console chat · [2] the full opencode TUI.
in_draw_talk() {
  local -i x=26 y=10 w=54 h=11
  v_fill $x $y $w $h ' ' $GREY $GLASS
  in_ell "${IM_NAME[$IN_LSEL]:-a model}" 22
  in_panel $x $y $w $h "TALK TO · $ELL" 'LOCAL · STAYS ON THIS MACHINE'
  v_text $(( x + 3 )) $(( y + 2 )) 'how do you want to talk to it?' $I_LBL
  cmix $WHITE $LIME 0.4
  v_text $(( x + 3 )) $(( y + 4 )) '[1] chat here' $CM
  v_text $(( x + 5 )) $(( y + 5 )) 'a quick console chat, in the glass' $I_DIM
  cmix $WHITE $AMBER 0.4
  v_text $(( x + 3 )) $(( y + 7 )) '[2] opencode' $CM
  v_text $(( x + 5 )) $(( y + 8 )) 'the full TUI · tools to code, or just chat' $I_DIM
  in_foot 1 'chat here' 2 opencode ⎋ back
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE CHILDREN THIS MACHINE STARTS, AND HOW THEY ARE PUT DOWN
# ══════════════════════════════════════════════════════════════════════════
# A PID, NOT A PATTERN.  Every stop on this machine used to be `pkill -f` with
# the job's own command line as the pattern, and that was wrong three ways at
# once.  `pkill -f` takes an EXTENDED REGEX matched against the full argv of
# every process on the machine -- and three of the four install lines contain
# a `|`, so `curl -fsSL https://claude.ai/install.sh | bash` was the
# ALTERNATION "contains the curl" OR "contains ` bash`", and [X] STOP would
# SIGTERM every login shell, `ssh host bash -lc …` and `man bash` running
# anywhere on the machine.  A `{…}` in the load line made it a bad interval
# and matched nothing at all.  And the thing it was aiming at was not there
# anyway: zsh EXEC-OPTIMISES the last command of a `-c` script, so
# `zsh -lc "cd /tmp/alien-bench.X && claude -p …"` becomes `claude` and no
# longer carries the pattern -- so the bench read `stopped` on the glass while
# three agents ran to completion on somebody's account.
#
# So the launch is wrapped in a two-command group, which forks and does NOT
# exec away, `$!` is kept, and the stop walks that pid's real children.
# Nothing else on the machine is ever a candidate.
typeset -ga IN_TMP
in_tmp() {   # in_tmp TEMPLATE -> ITMP · created 0600, tracked for the way out
  ITMP="$(mktemp "${TMPDIR:-/tmp}/$1.XXXXXX" 2>/dev/null)" || { ITMP=''; return 1 }
  chmod 600 -- "$ITMP" 2>/dev/null
  IN_TMP+=("$ITMP")
  return 0
}
in_tmpdir() {   # in_tmpdir TEMPLATE -> ITMP · mktemp -d is already 0700
  ITMP="$(mktemp -d "${TMPDIR:-/tmp}/$1.XXXXXX" 2>/dev/null)" || { ITMP=''; return 1 }
  IN_TMP+=("$ITMP")
  return 0
}
in_tmp_drop() {   # in_tmp_drop PATH
  [[ -n "$1" ]] || return 0
  rm -rf -- "$1" 2>/dev/null
  IN_TMP=("${(@)IN_TMP[@]:#$1}")
  return 0
}

in_kill_tree() {   # in_kill_tree PID — depth first, so nothing is reparented
  local -i pid=$1
  local c
  local -a kids
  (( pid > 1 )) || return 0
  # ONE PID A LINE, read as lines: split on IFS this came back as one word
  # whenever the caller was a trap that fired inside an `IFS= read`
  kids=("${(@f)$(pgrep -P $pid 2>/dev/null </dev/null)}")
  for c in "${kids[@]}"; do
    [[ "$c" == <-> ]] && in_kill_tree $c
  done
  kill -TERM $pid 2>/dev/null
  return 0
}

# ── the job · beside the picture, never instead of it ─────────────────────
# THE EXIT STATUS IS WRITTEN RATHER THAN WAITED FOR.  The job is disowned the
# moment it starts -- it has to be, or the shell would wait on it on the way
# out, and the way out of this cabinet is a signal -- so this shell has
# nothing left to wait on and the last line of the log is what says how it
# went.
# THE CLOCK, WHERE THE PAGES CAN REACH IT.  The cabinet hands the beat to
# the tick and the draw and to nothing else, and a panel that needs to say how
# long something has been running would otherwise have to be passed it through
# four functions that have no other use for it.
typeset -gF IN_NOW=0.0

IN_JOB_STATE=''       # '' none · run · done · fail
IN_JOB_LINE=''
IN_JOB_LABEL=''
IN_JOB_KIND=''
IN_JOB_LOG=''
typeset -gi IN_JOB_ROW=0 IN_JOB_RC=0
typeset -gF IN_JOB_T0=0.0 IN_JOB_END=0.0 IN_JOB_POLL=0.0
typeset -ga IN_JOB_OUT

in_job_start() {   # in_job_start KIND ROW LABEL LINE
  # ONE AT A TIME.  This used to overwrite IN_JOB_LOG and IN_JOB_PID
  # unconditionally, which orphaned whatever was already running: the first
  # job's handle was gone, so it could never be polled, stopped or reported,
  # and it finished invisibly some minutes later.
  if [[ "$IN_JOB_STATE" == run ]]; then
    say "$IN_JOB_LABEL is still running · [X] stops it"; snd no; return 1
  fi
  in_tmp_drop "$IN_JOB_LOG"
  IN_JOB_KIND="$1"; IN_JOB_ROW=$2; IN_JOB_LABEL="$3"; IN_JOB_LINE="$4"
  IN_JOB_OUT=(); IN_JOB_RC=0; IN_JOB_END=0.0; IN_JOB_POLL=0.0
  IN_JOB_PID=0
  IN_JOB_T0=$IN_NOW
  # `mktemp` AND NOT `$$.$RANDOM`.  zsh's $RANDOM is a PID-seeded PRNG, so the
  # name was guessable -- and `: >` follows a symlink, so anyone with write
  # access to a shared /tmp could pre-create the path and have this write
  # somewhere else.  mktemp is atomic and O_EXCL, and in_tmp chmods it 0600
  # because installer output is nobody else's business.
  if ! in_tmp alien-intel; then
    IN_JOB_STATE='fail'; IN_JOB_RC=1; IN_JOB_LOG=''
    IN_JOB_OUT=('there is nowhere to write the log')
    return 1
  fi
  IN_JOB_LOG="$ITMP"
  IN_JOB_STATE='run'
  local line="$IN_JOB_LINE"
  # THE FIXTURE INTERCEPTS THE RUN, NOT THE GATE.  Under mock the glass still
  # shows the line a real machine would run -- that is the whole point of a
  # picture of this page -- and what is actually started is a transcript of
  # roughly the right shape and length.  Inverting the two, so the gate
  # advertised the fixture, would make every screenshot of this cabinet a
  # screenshot of something that never installs anything.
  (( IN_MOCK )) && line="$IN_MOCK_RUN"
  # A LOGIN SHELL, because that is the shell the line was written for: every
  # one of these install lines expects the PATH a human's own shell has, and
  # running it under `zsh -f` would install into a PATH that nothing else on
  # this machine can see.
  # THE GROUP IS WHAT MAKES THE PID A HANDLE.  `&` forks, and a group of TWO
  # commands cannot be exec-optimised away -- so $! is a shell that stays put
  # for as long as the work does, and the real worker is its child.  A single
  # `zsh -lc "$line" &!` would have exec'd into curl and left nothing with a
  # stable identity to walk down from.
  { zsh -lc "$line"; print -r -- "__RC__ $?" } \
      >"$IN_JOB_LOG" 2>&1 </dev/null &!
  IN_JOB_PID=$!
  return 0
}

# FOUR READS A SECOND, not thirty.  `tail` is a fork, and a fork a frame on a
# surface that is already forking for its own scan is a machine that spends
# its whole budget asking how the last question went.
in_job_poll() {   # in_job_poll T
  local -F t=$1
  local line
  [[ "$IN_JOB_STATE" == run ]] || return 0
  (( t - IN_JOB_POLL < 0.25 )) && return 0
  IN_JOB_POLL=$t
  [[ -n "$IN_JOB_LOG" && -r "$IN_JOB_LOG" ]] || return 0
  # THE TAIL IS READ AS A TERMINAL WOULD HAVE SHOWN IT.  Twenty raw lines
  # rather than six, because a program redrawing a progress bar writes the
  # same line over and over: each is reduced to what stayed on it (in_plain),
  # and a line that begins the way an earlier one did -- the same bar,
  # redrawn -- replaces it rather than following it, so a pull shows one row
  # per layer instead of six rows of the same layer a moment apart.
  local -a raw
  local k
  local -i j found
  raw=("${(@f)$(tail -n 20 -- "$IN_JOB_LOG" 2>/dev/null </dev/null)}")
  IN_JOB_OUT=()
  for line in "${raw[@]}"; do
    [[ "$line" == '__RC__ '* ]] && { IN_JOB_OUT+=("$line"); continue }
    in_plain "$line"; line="$IPL"
    [[ -n "${line// /}" ]] || continue
    k="${line[0,23]}"
    found=0
    for (( j = 0; j < ${#IN_JOB_OUT[@]}; j++ )); do
      [[ "${IN_JOB_OUT[$j][0,23]}" == "$k" ]] || continue
      IN_JOB_OUT[$j]="$line"; found=1; break
    done
    (( found )) || IN_JOB_OUT+=("$line")
  done
  for line in "${IN_JOB_OUT[@]}"; do
    [[ "$line" == '__RC__ '* ]] || continue
    # GUARDED, BECAUSE IN_JOB_RC IS `typeset -gi`.  An installer that prints
    # a line of its own beginning `__RC__ ` would otherwise assign prose to an
    # integer, which is a failed typed assignment and ends the shell.
    line="${line#__RC__ }"; line="${line%% *}"
    [[ "$line" == <-> ]] && IN_JOB_RC=$line || IN_JOB_RC=1
    IN_JOB_END=$t
    if (( IN_JOB_RC == 0 )); then IN_JOB_STATE='done'; snd coin
    else                          IN_JOB_STATE='fail'; snd no; fi
    if (( IN_JOB_ROW >= 0 )); then in_scan_row $IN_JOB_ROW
    else
      in_scan_models; in_scan_resident
      # ...and once more a few seconds on: a pull's last write is the
      # manifest, and the server can answer the list a beat after it says
      # it is done
      IN_DISK_AT=$(( t - IN_DISK_EVERY + 3.0 ))
    fi
    in_log_add "$IN_JOB_KIND" "$IN_JOB_LABEL" "$IN_JOB_LINE" \
               $(( IN_JOB_RC == 0 )) $(( t - IN_JOB_T0 ))
    break
  done
  # THE SENTINEL IS BOOKKEEPING, NOT OUTPUT -- and it is dropped with `[@]`
  # on the name, which is not decoration.  `${(@)NAME:#pat}` on a BARE array
  # name expands element ZERO and nothing else, so the same line without the
  # subscript silently threw away every log line but the first and left the
  # strip showing one row of a curl that was printing dozens.
  IN_JOB_OUT=("${(@)IN_JOB_OUT[@]:#__RC__ *}")
  # ...and `${(@f)}` of nothing is ONE empty field, not none
  [[ ${#IN_JOB_OUT[@]} == 1 && -z "${IN_JOB_OUT[0]}" ]] && IN_JOB_OUT=()
  return 0
}

# [X] STOPS IT, and stopping it means the WHOLE TREE under the pid this pack
# kept: a curl piped into a bash is two processes and a pipe, and killing only
# the shell would leave the download running with nothing left to read it.
in_job_stop() {
  [[ "$IN_JOB_STATE" == run ]] || return 1
  (( IN_JOB_PID > 1 )) && in_kill_tree $IN_JOB_PID
  IN_JOB_PID=0
  IN_JOB_STATE='fail'; IN_JOB_RC=130; IN_JOB_END=$IN_NOW
  IN_JOB_OUT+=('stopped from the glass')
  in_log_add "$IN_JOB_KIND" "$IN_JOB_LABEL" "$IN_JOB_LINE" 0 \
             $(( IN_JOB_END - IN_JOB_T0 ))
  return 0
}

in_job_secs() {   # in_job_secs T -> JSEC
  local -F t=$1 d
  if [[ "$IN_JOB_STATE" == run ]]; then d=$(( t - IN_JOB_T0 ))
  else                                  d=$(( IN_JOB_END - IN_JOB_T0 )); fi
  (( d < 0.0 )) && d=0.0
  in_secs $d
  JSEC="$SEC"
  return 0
}

in_secs() {   # in_secs SECONDS -> SEC, in the largest unit that stays short
  local -F v=0.0
  (( v = $1, 1 )) 2>/dev/null || { SEC='—'; return 0 }
  (( v < 0.0 )) && v=0.0
  if   (( v >= 3600.0 )); then printf -v SEC '%.1f h' $(( v / 3600.0 ))
  elif (( v >= 90.0 ));   then printf -v SEC '%d min' $(( int(v / 60.0 + 0.5) ))
  elif (( v >= 10.0 ));   then printf -v SEC '%d s' $(( int(v + 0.5) ))
  else                         printf -v SEC '%.1f s' $v; fi
  return 0
}

# THE STRIP ALONG THE BOTTOM, which is RECENT until there is a job and the
# job afterwards.  Same rectangle either way: a panel that moved when
# something started would take the eye with it at the one moment the eye is
# already on the row that started it.
in_draw_job() {   # in_draw_job Y H
  local -i y=$1 h=$2 i n col
  local -i pw=$(( SCR_W > 120 ? SCR_W - 4 : 102 ))
  local t r
  case "$IN_JOB_STATE" in
    run)  t='INSTALLING'; r='[X] STOP'; col=$I_FG ;;
    done) t='INSTALLED';  r='[R] READS THE ROW AGAIN'; col=$I_OK ;;
    *)    t='THE LAST ONE'; r='[I] TRIES AGAIN'; col=$I_WARNC ;;
  esac
  case "$IN_JOB_KIND" in
    remove|drop) case "$IN_JOB_STATE" in
              run) t='REMOVING' ;; done) t='REMOVED' ;; esac ;;
    pull)   case "$IN_JOB_STATE" in
              run) t='DOWNLOADING' ;; done) t='DOWNLOADED' ;; esac ;;
    load)   case "$IN_JOB_STATE" in
              run) t='LOADING' ;; done) t='RESIDENT' ;; esac
            [[ "$IN_JOB_STATE" == run ]] || r='[D] LOADS ANOTHER · ⏎ RUNS IT' ;;
  esac
  in_panel 2 $y $pw $h "$t" "$r"
  if [[ "$IN_JOB_STATE" == run ]]; then
    # A RIBBON ALONG THE PANEL'S RULE while the job runs -- the one thing on
    # the strip that says "still going" without a number it does not have.
    local -i rx rw=8 x0=$(( 4 + ${#t} + 3 )) x1=$(( pw - 4 - ${#r} )) k
    local -F ph
    if (( x1 - x0 > rw + 2 )); then
      ph=$(( IN_NOW * 0.45 )); ph=$(( ph - floor(ph) ))
      rx=$(( x0 + int(ph * (x1 - x0 - rw)) ))
      for (( k = 0; k < rw; k++ )); do
        cmix $I_DIM $AMBER $(( 0.25 + 0.75 * (1.0 - abs(k - rw / 2.0) / (rw / 2.0)) ))
        v_put $(( rx + k )) $y '─' $CM
      done
    fi
  fi
  in_ell "$IN_JOB_LINE" $(( pw - 26 ))
  cmix $WHITE $AMBER 0.35
  v_text 4 $(( y + 1 )) "$ELL" $CM
  in_job_secs $IN_NOW
  r="${IN_JOB_STATE} · $JSEC"
  v_text $(( SCR_W - 3 - ${#r} )) $(( y + 1 )) "$r" $col
  n=${#IN_JOB_OUT[@]}
  for (( i = 0; i < n && i < h - 3; i++ )); do
    in_ell "${IN_JOB_OUT[$(( n - (n > h - 3 ? h - 3 : n) + i ))]//$'\t'/  }" $(( pw - 4 ))
    v_text 4 $(( y + 2 + i )) "$ELL" $I_LBL
  done
  return 0
}

# ── what has been run from this cabinet ───────────────────────────────────
# KEPT IN MEMORY AND NOWHERE ELSE.  A log on disk is a file this pack would
# have to own, rotate and be trusted with; what this page is actually for is
# "what did I just do", and the window it needs is this session.
typeset -ga IN_LOG_T IN_LOG_KIND IN_LOG_WHO IN_LOG_CMD IN_LOG_OK IN_LOG_SEC
typeset -gi IN_LOG_N=0
in_log_add() {   # in_log_add KIND WHO CMD OK SECS
  local ts; strftime -s ts '%H:%M:%S' $EPOCHSECONDS 2>/dev/null || ts='--:--:--'
  IN_LOG_T=("$ts" "${IN_LOG_T[@]}")
  IN_LOG_KIND=("$1" "${IN_LOG_KIND[@]}")
  IN_LOG_WHO=("$2" "${IN_LOG_WHO[@]}")
  IN_LOG_CMD=("$3" "${IN_LOG_CMD[@]}")
  IN_LOG_OK=($4 "${IN_LOG_OK[@]}")
  IN_LOG_SEC=($5 "${IN_LOG_SEC[@]}")
  IN_LOG_N=${#IN_LOG_T[@]}
  (( IN_LOG_N > 60 )) && {
    IN_LOG_T=("${(@)IN_LOG_T[0,59]}");    IN_LOG_KIND=("${(@)IN_LOG_KIND[0,59]}")
    IN_LOG_WHO=("${(@)IN_LOG_WHO[0,59]}"); IN_LOG_CMD=("${(@)IN_LOG_CMD[0,59]}")
    IN_LOG_OK=("${(@)IN_LOG_OK[0,59]}");  IN_LOG_SEC=("${(@)IN_LOG_SEC[0,59]}")
    IN_LOG_N=60
  }
  return 0
}

in_draw_recent() {   # in_draw_recent Y H
  local -i y=$1 h=$2 i n col
  local r
  local -i pw=$(( SCR_W > 120 ? SCR_W - 4 : 102 )) cmw=$(( SCR_W > 120 ? SCR_W - 54 : 52 ))
  in_panel 2 $y $pw $h RECENT '[H] FULL HISTORY'
  if (( IN_LOG_N == 0 )); then
    v_text 4 $(( y + 1 )) 'nothing yet — ⏎ opens one, [I] installs one' $I_DIM
    return 0
  fi
  n=$(( h - 2 )); (( n > IN_LOG_N )) && n=$IN_LOG_N
  for (( i = 0; i < n; i++ )); do
    (( ${IN_LOG_OK[$i]} )) && col=$I_OK || col=$I_WARNC
    in_rpad "${IN_LOG_T[$i]}" 10;      v_text 4 $(( y + 1 + i )) "$IRP" $I_LBL
    in_ell "${IN_LOG_KIND[$i]}" 8; in_rpad "$ELL" 9
    v_text 15 $(( y + 1 + i )) "$IRP" $I_DIM
    in_ell "${IN_LOG_WHO[$i]}" 17; in_rpad "$ELL" 18
    v_text 25 $(( y + 1 + i )) "$IRP" $I_FG
    in_ell "${IN_LOG_CMD[$i]}" $cmw
    v_text 44 $(( y + 1 + i )) "$ELL" $I_DIM
    in_secs ${IN_LOG_SEC[$i]}
    v_text $(( SCR_W - 3 - ${#SEC} )) $(( y + 1 + i )) "$SEC" $col
  done
  return 0
}

in_draw_strip() {   # in_draw_strip Y H — the job if there is one, else RECENT
  if [[ -n "$IN_JOB_STATE" ]]; then in_draw_job $1 $2
  else                              in_draw_recent $1 $2; fi
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# ⏎ · THE AGENT, IN THE GLASS
# ══════════════════════════════════════════════════════════════════════════
# There was briefly a choice here -- in this window, or in a tab of its own --
# and both were wrong.  Handing the window over got the agent but lost the
# machine; a tab got neither, because Terminal.app cannot be made to open one
# without a permission macOS may never give, and because a tab is not in the
# picture at all.
#
# The original never had that choice and never needed one: the agent gets a
# TERMINAL OF ITS OWN, exactly as wide and as tall as the glass, and the
# cabinet draws what comes back.  The raster stays up, the neon stays on, the
# coin door still says what the machine is doing, and ^] brings the keyboard
# home with the agent still running behind it.
in_deal() {   # in_deal I
  local -i i=$1
  local p="${IA[$i.path]:-}"
  (( ${IA[$i.here]:-0} )) || { say "${IN_NAME[$i]} · not on this machine"; snd no; return 1 }
  [[ -n "$p" && -x "$p" ]] || { say "${IN_NAME[$i]} · that binary will not run"; snd no; return 1 }
  in_short "$PWD"
  # THE ROSTER'S OWN KEY, so ⏎ on an agent already running steps back into
  # THAT one rather than starting a second copy beside it.
  if in_sh_open "${IN_BINS[$i]%% *}" "${IN_NAME[$i]}" "$(_sh "$p")" \
                "$PWD" "${IA[$i.model]:-}"; then
    [[ "$IN_VIEW" == shell ]] && {
      in_log_add open "${IN_NAME[$i]}" "in the glass, in $SHT" 1 0
      snd coin
    }
    return 0
  fi
  return 1
}


# ── TAB · a new tab of this window, through the door's own AppleScript ───
# THE SAME THREE THINGS [T] TERMINAL NEEDS: a mac, Apple's Terminal, and a
# handle on this window.  The window id is not one of the three -- it is a
# thing the cabinet fetches -- and separating them is what lets each failure
# name the right thing to go and fix.
#
# IT DOES NOT JOIN THE HOUSE.  A suite token would enroll the agent's tab in
# the cabinet's own accounting, where a tab that is not a machine would be
# counted, waited for and closed with the rest -- so the agent gets a plain
# tab with a title, and the house stays exactly as big as it was.
# THE COIN DOOR HAS FORTY-FOUR COLUMNS AND THIS NEEDS MORE.  Every one of
# these failures is something the reader has to go and DO something about,
# and a sentence cut at `· [W] open` tells them nothing -- so the toast stays
# short and the reason goes in the panel, which is forty-four wide and two
# rows empty.
# WHICH TERMINAL AM I READING, IN THE SPELLING TERMINAL.APP USES.
#
# `term_tty` first and not `$TTY`, even though `$TTY` is free: the whole
# value of this string is that it can be COMPARED to what Terminal answers
# for a tab, and `term_tty` is the one already proven to compare -- it is
# what `window_id` matches tab-by-tab to find this window at all.  A string
# that is right but spelled differently is worse than no string, because the
# comparison it fails is `is this tab me`, and failing THAT is how the
# command ends up typed into the cabinet.
#
# Empty is safe, and safe here means the tab is not attempted at all.
ITT=''
in_mytty() {
  ITT=''
  (( ${+functions[term_tty]} )) && ITT="$(term_tty 2>/dev/null)"
  [[ -n "$ITT" ]] || ITT="${TTY:-}"
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# THE PACK · what terminal.command asks of a machine, and nothing more
# ══════════════════════════════════════════════════════════════════════════
PACK_NAME='INTELLIGENCE'
PACK_MODEL='IQ-88'
PACK_INIT='intel_init'
PACK_WARM='intel_warm'
PACK_TICK='intel_tick'
PACK_DRAW='intel_draw'
PACK_KEY='intel_key'
PACK_DRESS='intel_dress'
PACK_LEAVE='intel_leave'
PACK_RAW='intel_raw'

# ══════════════════════════════════════════════════════════════════════════
# ATTACHED: THE KEYBOARD IS THE AGENT'S, BYTE FOR BYTE
# ══════════════════════════════════════════════════════════════════════════
# Not parsed into names, not looked at for [M] -- handed over exactly as it
# was typed, because the agent is the one that knows what ^R or ⎋ or a bare
# ESC means to it.  ^] is the only key this machine keeps.
#
# The door asks `want` before every key and only bypasses its own parser when
# the answer is yes, so a machine with no agent up behaves exactly as it did.
intel_raw() {   # intel_raw want | intel_raw mouse | intel_raw feed BYTES
  case "$1" in
    want)
      (( ${SURF_TITLE:-0} )) && return 1      # a title card up takes keys, not bytes
      [[ "$IN_VIEW" == shell ]] || return 1
      [[ -n "$GT_AT" ]] || return 1
      gt_live "$GT_AT" || return 1
      return 0 ;;
    # WHOSE MOUSE IT IS.  The door reports the mouse for its own wheel (its
    # scr_enter says why), and a program that has asked this terminal for
    # the mouse is owed the reports -- moved into its grid by kb_mouse below.
    # One that has not asked gets none, and the wheel scrolls the past.
    mouse)
      (( VT_MOUSE )) && return 0
      return 1 ;;
    feed)
      # WHERE THE AGENT'S TOP-LEFT CELL IS, IN THE READER'S WINDOW.  A mouse
      # report is counted from the corner of the terminal and the agent
      # counts from the corner of its own screen, so the whole chain has to
      # be subtracted: where the cabinet stands in the window (OX/OY), where
      # the glass sits inside the cabinet (C_SCR/R_SCR), and where the
      # terminal sits inside the glass (GT_Y).  Off by any one of them and
      # a click lands on the wrong line of whatever the agent is showing.
      kb_feed "$2" $(( OX + C_SCR )) $(( OY + R_SCR + GT_Y ))
      if (( KB_BACK )); then
        in_sh_detach
        say 'detached — it is still running'
        snd away
      fi
      return 0 ;;
  esac
  return 1
}
IN_MODEL='IQ-88'

# THE CABINET GOING DOWN TAKES THIS MACHINE'S CHILDREN WITH IT.  An installer,
# three agents and a streaming request are real processes that this pack
# started and nothing else on the machine knows about; disowned, they are not
# even in the shell's job table, so they do not get a HUP when it exits.  They
# outlived the program that started them, still downloading, still spending,
# with nothing left anywhere to stop them or say they were there.
#
# NO DRAWING AND NO DECISIONS HERE.  The door calls this from cleanup, which
# runs on the way out of a signal, and the one thing that matters more than
# this is that the terminal is handed back in a usable state.
intel_leave() {
  local t
  # THE AGENTS GO FIRST.  A pty outlives the shell that opened it, and an
  # agent left holding one after the cabinet is gone is a process with a
  # terminal nobody is reading and no way to be told to stop.
  in_sh_raw 0 2>/dev/null
  in_sh_all_stop 2>/dev/null
  in_chat_stop 2>/dev/null
  in_job_stop 2>/dev/null
  in_bench_stop 2>/dev/null
  (( IN_DISK_PID > 1 )) && in_kill_tree $IN_DISK_PID
  IN_DISK_PID=0
  for t in "${IN_TMP[@]}"; do
    [[ -n "$t" ]] && rm -rf -- "$t" 2>/dev/null
  done
  IN_TMP=()
  return 0
}

# EVERY FIELD EXISTS BEFORE ANYTHING READS ONE.  The cabinet runs under `set
# -u`, where reading a key this table has not been given yet does not read
# empty -- it ends the whole shell, from inside a draw, with the alternate
# screen still up.  The scan walks one row a tick and the glass is drawn on
# the first, so for the first four frames most of this table is exactly that
# key, and seeding it here is what makes `…` a reading rather than a crash.
in_seed() {
  local -i i
  for (( i = 0; i < IN_N; i++ )); do
    IA[$i.here]=0; IA[$i.bin]=''; IA[$i.path]=''; IA[$i.from]=''
    IA[$i.ver]=''; IA[$i.model]=''; IA[$i.auth]='reading…'
    IA[$i.state]='wait'; IA[$i.proof]=''
  done
  for (( i = 0; i < IN_RN; i++ )); do
    IR[$i.here]=0; IR[$i.up]=0; IR[$i.path]=''; IR[$i.served]=''
  done
  IM_NAME=(); IM_WHERE=(); IM_QUANT=(); IM_SIZE=(); IM_PATH=(); IM_N=0
  IM_OL_NAME=(); IM_OL_WHERE=(); IM_OL_QUANT=(); IM_OL_SIZE=(); IM_OL_PATH=()
  IM_GG_NAME=(); IM_GG_WHERE=(); IM_GG_QUANT=(); IM_GG_SIZE=(); IM_GG_PATH=()
  IZ_NAME=(); IZ_SIZE=(); IZ_PROC=(); IZ_UNTIL=(); IZ_WHERE=(); IZ_N=0
  return 0
}

typeset -gF IN_LAST=0.0 IN_MLAST=0.0
IN_SAMPLE=30.0
# THE MACHINE'S OWN NUMBERS MOVE AND THE ROSTER DOES NOT.  An agent's version
# is the same version it was thirty seconds ago; the memory under a model that
# is being loaded is not, and LOCAL draws it as a meter.  So the roster sweeps
# on the slow clock and the three live figures have one of their own.
IN_MACH=3.0

intel_init() {
  RW_STATE=''; RW_OUT=''; RW_IN=''; RW_PROMPT=''; RW_NOTES=''; RW_ESEL=0
  RW_PK_OPEN=0; RW_PKSEL=0; RW_PKTOP=0; RW_MTYPE=0; RW_KEEP=''; RW_TOK=''
  RW_ROUTE=0; RT_STATE=''; RT_PROMPT=''; RT_DEST=''; RT_AGENT=-1; RT_LMODEL=''; RT_LWHERE=''; RT_LR=-1
  RC_LOG=''; RC_PID=0; RC_POLL=0.0
  in_palette
  # THE AGENT'S SIXTEEN, AND THE CUBE UNDER THEM.  Without this every colour
  # a session asks for resolves to zero -- and zero is black, on a ground
  # that is also black, so the agent's screen was drawn perfectly and was
  # invisible.  Built once; it never changes.
  vt_palette
  in_row_init
  in_seed
  IN_VIEW='menu'; IN_PAGE=0; IN_SEL=0; IN_MROW=0
  IN_STEP=0; IN_LAST=0.0
  IN_GATE=0; IN_TALK=0; IN_GATE_KIND=''; IN_GATE_LINE=''; IN_GATE_WHO=''
  IN_PICK_OPEN=0; IN_PICKSEL=0
  modal_reset
  IN_LSEL=0; IN_LTOP=0; IN_RSEL=0; IN_LFOCUS='model'
  IN_JOB_STATE=''; IN_JOB_LOG=''; IN_JOB_OUT=(); IN_JOB_PID=0
  IN_TMP=()
  IN_MODE='nav'; in_line_clear
  IN_PSEL=0; IN_PTOP=0; IN_HSEL=0; IN_HTOP=0
  BN_N=0; BN_PROMPT=''; BN_CWD=''; BN_START=0.0
  CH_WHO=(); CH_TXT=(); CH_N=0; CH_STATE=''; CH_MODEL=''
  CH_IN=0; CH_OUT=0; CH_CTX=0; CH_STARTED=0.0; CH_RUNNER=-1; CH_PINNED=-1
  CH_PID=0; CH_LOG=''; CH_USE=''; CH_BODY=''
  BN_PID=(); BN_DIR=()
  # EVERY VERSION, ASKED NOW AND OUT OF SIGHT · see in_pf_start
  in_pf_start
  return 0
}

# THE FIRST SWEEP, TAKEN BEHIND THE LOADING SCREEN (terminal.command, SECTION
# 22b): the same samplers the tick walks, one a step, so the page opens on a
# table that is already full.  The runners come first because the models and
# what is resident are read off their ports; the rows and opencode come last,
# because their versions are the background job's and it has had the longest
# to answer by then -- and while it has not, a row step waits (2) rather than
# leave a `…` that the opening could have filled.  The sweep it finishes is
# the tick's own: the slow clock starts from here, exactly as if the page had
# been open for it.
intel_warm() {   # intel_warm N T
  local -i n=$1
  local -F t=$2
  IN_NOW=$t
  case $n in
    0|1|2|3) in_scan_runner $n; in_scan_serving $n ;;
    4)       in_scan_models_due ;;
    5)       in_scan_resident ;;
    6)       in_scan_keys ;;
    7)       in_sample_mach; IN_MLAST=$t ;;
    8|9|10|11)
      if (( IN_PF_PID > 0 )) && ! in_pf_poll; then
        (( EPOCHREALTIME - IN_PF_T0 < IN_PF_WAIT )) && return 2
      fi
      in_scan_row $(( n - 8 )) ;;
    12)      in_scan_opencode ;;
    *)       (( IN_VER_OWED && IN_PF_PID == 0 )) && in_pf_adopt
             IN_STEP=0; IN_LAST=$t
             return 1 ;;
  esac
  return 0
}

# ONE AGENT A TICK, and the runners after them.  Asking four command lines
# their version on the frame that opens the machine is two seconds of frozen
# picture; asking one is sixty milliseconds, and by the fourth frame the table
# is full.  A row the walk has not reached yet reads `…`, which is true.
typeset -gi IN_STEPS=$(( IN_N + IN_RN + 3 ))   # the rows, the runners, then models · resident · keys
intel_tick() {   # intel_tick T
  local -F t=$1
  IN_NOW=$t
  in_job_poll $t
  in_bench_poll $t
  in_chat_poll $t
  rw_poll $t
  # THE COMPOSER'S REWRITE HAS LANDED · route it, do not show it.  A rewrite
  # the ROUTE page started (RW_ROUTE) is a step on the way to a vehicle, so its
  # finish opens the gate rather than the REWRITE page's result view; a failed
  # one still routes, as the line the reader typed.
  if (( RW_ROUTE )); then
    case "$RW_STATE" in
      done)
        RW_ROUTE=0; RT_PROMPT="${RW_PROMPT:-$RW_IN}"
        # A REWRITE THAT PARROTED THE INSTRUCTIONS IS NOT A REWRITE · a small model
        # handed a thin prompt sometimes rewrites the system prompt itself.  If the
        # result carries the tell-tale instruction words, keep what was typed.
        local _rl="${RT_PROMPT:l}"
        [[ "$_rl" == *'rough prompt'* || "$_rl" == *'prompt engineer'* || "$_rl" == *'rewritten prompt'* ]] && RT_PROMPT="$RW_IN"
        in_route_classify ;;
      failed|stopped)  RW_ROUTE=0; RT_PROMPT="$RW_IN"; say 'rewrite did not land · routing the line as typed'; in_route_decide "$RT_PROMPT"; in_route_gate ;;
    esac
  fi
  # THE CLASSIFIER'S ANSWER · read it, then open the gate on its verdict
  [[ "$RT_STATE" == cls ]] && in_route_classify_poll $t
  in_disk_poll
  in_caps_step
  in_route_poll
  # THE VERSIONS ASKED AT START-UP, taken in the tick they land -- and any a
  # row is still owed.  A version asked HERE is this tick's one fork.
  if (( IN_PF_PID > 0 )); then in_pf_poll && IN_VER_OWED=1; fi
  if (( IN_VER_OWED && IN_PF_PID == 0 )); then in_pf_adopt || { in_badge; return 0 }; fi
  # ONE SAMPLER A TICK, NEVER TWO.  The whole reason the scan is a pump is
  # that a frame can afford one fork and not six, and a fast clock that ran
  # ITS step and then fell through to the sweep's would quietly do both.
  if (( t - IN_MLAST >= IN_MACH )); then
    IN_MLAST=$t; in_sample_mach; return 0
  fi
  if (( IN_STEP == 0 )); then
    (( IN_LAST == 0.0 )) && IN_LAST=$(( t - IN_SAMPLE ))
    (( t - IN_LAST < IN_SAMPLE )) && return 0
    IN_LAST=$t
  fi
  # BY THE ROSTER'S OWN COUNT, so a fifth agent is a fifth step and not a
  # row the walk never reaches
  if   (( IN_STEP < IN_N ));         then in_scan_row $IN_STEP
  elif (( IN_STEP < IN_N + IN_RN )); then in_scan_runner $(( IN_STEP - IN_N )); in_scan_serving $(( IN_STEP - IN_N ))
  else
    case $(( IN_STEP - IN_N - IN_RN )) in
      0) in_scan_opencode; in_scan_models_due ;;
      1) in_scan_resident ;;
      2) in_scan_keys ;;
    esac
  fi
  (( IN_STEP++ ))
  # ...AND THE COIN DOOR IS TOLD.  surf_dress runs ONCE, when the machine is
  # opened -- the plate, the sign and the control panel are painted into the
  # static layer and there is no reason to compute them again -- but the badge
  # beside the tag is drawn live every frame, and this one counts something
  # the scan is still in the middle of finding out.  Set once at open it said
  # `0 OF 4 HERE` for ever, on a page whose own header said three.
  (( IN_STEP >= IN_STEPS )) && IN_STEP=0
  in_badge
  return 0
}

in_badge() {
  local -i i here=0
  for (( i = 0; i < IN_N; i++ )); do (( ${IA[$i.here]:-0} )) && (( here++ )); done
  SURF_BADGE=" $here OF $IN_N HERE "
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE TITLE CARD · four command lines, one glass
# ══════════════════════════════════════════════════════════════════════════
# What the door puts up every time this machine is walked into -- the tc_*
# vocabulary is terminal.command's, so the four machines' cards read as one
# family -- and this machine's whole idea drawn as what it is: the agents on
# the left and the local runners on the right, each on a line of its own,
# the lines merging into one trunk a side and the two trunks into THE GLASS
# in the middle.  Nothing on it says what the bezel, the plate and the coin
# door already say (the motto is the coin door's).  Every node is what the
# scan found.  A line that is live
# carries a pulse in, in its own ink -- an agent signed in, lime; a runner
# listening, cyan -- and the glass lights as each one lands.  A line that is
# here and not ready is drawn, and still; one that is not on this machine is
# a dotted ghost.  And while the scan has not reached a line yet, a grey
# pulse runs the other way, out to its node: the machine asking.
#
# AS THE CARD COMES UP the glass comes on first, and the wires go out from
# it -- the trunks, then each line -- and every node lights as its wire
# reaches it, its name typing in beside it.  Only then do the pulses start.
#
# FOUR A SIDE.  The roster and the runners are four each; a fifth would be
# counted in the figures and the status and left off the drawing, rather
# than the drawing growing past the glass.
typeset -gA IN_TC_INK                          # the card's inks, each worked out once
IN_TC_WORD=('NO' 'ONE' 'TWO' 'THREE' 'FOUR' 'FIVE' 'SIX' 'SEVEN' 'EIGHT' 'NINE')
in_tc_inks() {
  (( ${IN_TC_INK[ready]:-0} )) && return 0
  cmix $PURPLE $MAGENTA 0.30; cshade $CM 0.70; IN_TC_INK[live]=$CS   # a line that is live
  cshade $PURPLE 0.45;     IN_TC_INK[idle]=$CS    # here, not ready
  cshade $GREY 0.32;       IN_TC_INK[ghost]=$CS   # not on this machine
  cshade $GREY 0.50;       IN_TC_INK[read]=$CS    # not read yet
  cmix $GREY $WHITE 0.35;  IN_TC_INK[ask]=$CM     # the question going out
  cshade $PURPLE 0.42;     IN_TC_INK[box]=$CS
  cshade $PURPLE 0.85;     IN_TC_INK[hub]=$CS
  cmix $MAGENTA $WHITE 0.40; IN_TC_INK[hubhot]=$CM
  cmix $PINK $WHITE 0.45;  IN_TC_INK[hubtx]=$CM
  cshade $WHITE 0.94;      IN_TC_INK[n2]=$CS      # a name, by how live its line is
  cshade $WHITE 0.70;      IN_TC_INK[n1]=$CS
  cshade $GREY 0.62;       IN_TC_INK[n0]=$CS
  cshade $GREY 0.45;       IN_TC_INK[v0]=$CS      # and the word beside it
  cshade $GREY 0.80;       IN_TC_INK[vr]=$CS
  cshade $AMBER 0.75;      IN_TC_INK[stop]=$CS
  cshade $CYAN 0.85;       IN_TC_INK[up]=$CS
  IN_TC_INK[ready]=1
  return 0
}
in_tc_mix() {   # in_tc_mix A B Q -> ITK · A toward B by Q twentieths, worked out once
  ITK=${IN_TC_INK[$1:$2:$3]:-0}
  (( ITK )) && return 0
  cmix $1 $2 $(( $3 / 20.0 )); ITK=$CM; IN_TC_INK[$1:$2:$3]=$ITK
  return 0
}
in_tc_line() {   # in_tc_line SIDE I -> ITL, ITN ITG the node's ink and mark, ITP the pulse's ink, ITW1 ITW2 the words
  # ITL · 2 live · 1 here and not ready · 0 not on this machine · -1 not read yet
  local -i i=$2
  local -a held
  if (( $1 == 0 )); then
    case "${IA[$i.state]:-wait}" in
      wait) ITL=-1 ;;
      ok)   ITL=2 ;;
      *)    if (( ${IA[$i.here]:-0} )); then ITL=1; else ITL=0; fi ;;
    esac
    in_ink "${IA[$i.state]:-wait}"
    ITP=$LIME; ITW1="${IN_NAME[$i]}"
    case $ITL in
      -1) ITW2='…' ;;
      0)  ITW2='not here' ;;
      *)  ITW2="${IA[$i.ver]:-…}" ;;
    esac
  else
    if   (( ! ${IR[$i.seen]:-0} )); then ITL=-1; in_ink wait
    elif (( ${IR[$i.up]:-0} ));     then ITL=2;  in_ink ok
    elif (( ${IR[$i.here]:-0} ));   then ITL=1;  in_ink warn
    else                                 ITL=0;  in_ink no; fi
    ITP=$CYAN; ITW1="${IN_RNAME[$i]}"
    case $ITL in
      -1) ITW2='…' ;;
      0)  ITW2='not here' ;;
      1)  ITW2='stopped' ;;
      *)  ITW2='up'
          if [[ -n "${IR[$i.served]:-}" ]]; then
            held=("${(@s: · :)IR[$i.served]}"); ITW2="up · ${#held[@]}"
          fi ;;
    esac
  fi
  ITN=$IIN; ITG="$IID"
  return 0
}
# WHERE THE STILL PART PUT THINGS, for the live part to light: each line's
# level, its node and the node's ink and mark, its pulse's ink, and its path
# -- the cells from the node to the glass, with the wire's own ink in each --
# and every cell of wire with how far along the wires it is from the glass
typeset -gi IN_TC_OY=0 IN_TC_CH=7 IN_TC_MID=0 IN_TC_HL=0 IN_TC_HR=0 IN_TC_TS0=0 IN_TC_TS1=0 IN_TC_STC=0 IN_TC_DMAX=0
typeset -g  IN_TC_ST='' ITKEY=''
typeset -ga IN_TC_LV IN_TC_NX IN_TC_NY IN_TC_NK IN_TC_NG IN_TC_PK IN_TC_PATH IN_TC_P0 IN_TC_PW IN_TC_ND
typeset -ga IN_TC_WK IN_TC_WD IN_TC_WI
# the beats · the glass comes on · the wires leave it, so many cells a second
typeset -gF IN_TC_HUB0=0.50 IN_TC_WIRE0=0.62 IN_TC_WV=55.0
typeset -gF IN_BNOW=0.0                        # the board's clock this frame (the card's, or the list page's)
typeset -g  IN_BOARD_SIG=''                    # where the board was last painted, for the live part to check
typeset -gi IN_BOARD_MENU=0                    # the board is the list page's: what each line carries goes under it
in_title_key() {   # in_title_key -> ITKEY · everything the still part is a picture of
  local -i i
  ITKEY="in|$IN_N|$IN_RN|${IM_N:-0}|${IN_LOG_N:-0}|${IK_N:-0}"
  for (( i = 0; i < IN_N && i < 4; i++ )); do
    ITKEY+="|${IA[$i.state]:-wait}${IA[$i.here]:-0}${IA[$i.ver]:-}"
  done
  for (( i = 0; i < IN_RN && i < 4; i++ )); do
    ITKEY+="|${IR[$i.seen]:-0}${IR[$i.up]:-0}${IR[$i.here]:-0}${IR[$i.served]:-}"
  done
  for (( i = 0; i < ${IK_N:-0}; i++ )); do ITKEY+="${IK_SET[$i]:-0}"; done
  return 0
}
in_tc_wire() {   # in_tc_wire KEY DIST — a cell of wire, for the live part to draw out from the glass
  IN_TC_WK+=($1); IN_TC_WD+=($2); IN_TC_WI+=(${GF[$1]})
  (( $2 > IN_TC_DMAX )) && IN_TC_DMAX=$2
  return 0
}
in_title_base() {   # the card's still part, painted once per reading of the machine and kept (tc_card)
  local -i oy cw ch sx sy i here=0 ok=0 wait=0 keys=0
  local s
  in_tc_inks
  tc_base INTELLIGENCE
  # THE COUNTS, over the whole roster (not just the four drawn)
  for (( i = 0; i < IN_N; i++ )); do
    case "${IA[$i.state]:-wait}" in wait) (( wait++ )) ;; ok) (( ok++ )) ;; esac
    (( ${IA[$i.here]:-0} )) && (( here++ ))
  done
  for (( i = 0; i < ${IK_N:-0}; i++ )); do (( ${IK_SET[$i]:-0} )) && (( keys++ )); done
  # the band's right-hand reading, the coin door's own
  s="$here OF $IN_N HERE"
  cmix $GLASS $PURPLE 0.32; v_text $(( APP_HR - ${#s} + 1 )) 0 "$s" $I_LBL $CM
  # a line a row apart from the next, the glass five rows tall between them
  # · a taller CRT, a row of air above and below; a wider one, longer lines
  ch=7; (( TC_H >= 34 )) && ch=9
  cw=$(( TC_W - 19 ))
  if (( TC_H >= 34 )); then (( cw > 111 )) && cw=111; else (( cw > 97 )) && cw=97; fi
  oy=$(( (TC_H - (ch + 17)) / 2 )); (( oy < 0 )) && oy=0
  tc_big INTELLIGENCE $(( oy + 1 )) $PURPLE $MAGENTA
  # ── the switchboard ──
  sx=$(( TC_X0 + (TC_W - cw - 2) / 2 )); sy=$(( TC_Y0 + oy + 9 ))
  in_board_paint $sx $sy $cw $ch
  tc_quiet $sx $sy $(( cw + 2 )) $(( ch + 2 ))
  IN_TC_OY=$oy; IN_TC_CH=$ch
  # ── the figures, under the switchboard end to end, and what the cabinet makes of them ──
  TC_MJX=$sx; TC_MJW=$(( cw + 2 ))
  tc_figs $(( oy + ch + 12 )) READY "$ok OF $IN_N" MODELS "${IM_N:-0} ON DISK" KEYS "$keys SET" RUNS "${IN_LOG_N:-0}"
  tc_reveal $TC_FX $(( TC_Y0 + oy + ch + 12 )) $TC_FW 1.02 0.30
  if   (( wait ));       then IN_TC_ST='READING THE MACHINE'; IN_TC_STC=$CYAN
  elif (( ok >= IN_N )); then IN_TC_ST="ALL ${IN_TC_WORD[$IN_N]:-$IN_N} LINES LIVE"; IN_TC_STC=$LIME
  elif (( ok ));         then IN_TC_ST="${IN_TC_WORD[$ok]:-$ok} OF ${IN_TC_WORD[$IN_N]:-$IN_N} LINES LIVE"; IN_TC_STC=$LIME
  elif (( here ));       then IN_TC_ST='NO LINE SIGNED IN YET'; IN_TC_STC=$AMBER
  else                        IN_TC_ST='NO AGENTS ON THIS MACHINE YET'; IN_TC_STC=$AMBER; fi
  tc_nav 'open the glass'
  return 0
}
in_board_paint() {   # in_board_paint SX SY CW CH — the switchboard: its box at SX,SY, CW × CH inside (the card's and the list page's)
  local -i sx=$1 sy=$2 cw=$3 ch=$4 half cx reach NL NR TL TR hL hR mid base
  local -i l sd i r ry lv x x0 x1 y k tx ts rd wk tk nk vk dy
  local -i TS0=0 TS1=0 RD0=0 RD1=0
  local s gl wg vg hg
  local -a rows W1 W2
  in_tc_inks
  IN_BOARD_SIG="$sx|$sy|$cw|$ch"
  v_box $sx $sy $(( cw + 2 )) $(( ch + 2 )) ${IN_TC_INK[box]} $BLACK round 1
  v_fill $(( sx + 1 )) $(( sy + 1 )) $cw $ch ' ' $GREY $BLACK
  v_text $(( sx + 2 )) $sy ' CLOUD · AGENTS ' $AMBER $BLACK
  s=' LOCAL · RUNNERS '; v_text $(( sx + cw - ${#s} )) $sy "$s" $AMBER $BLACK
  # the nodes stand a reach either side of the middle, the glass in it, a
  # trunk five cells out from the glass a side
  half=$(( cw / 2 )); cx=$(( sx + 1 + half )); reach=$(( half - 23 ))
  NL=$(( cx - reach )); NR=$(( cx + reach ))
  hL=$(( cx - 7 )); hR=$(( cx + 7 )); TL=$(( hL - 5 )); TR=$(( hR + 5 ))
  mid=$(( sy + 1 + ch / 2 ))
  # the lines a row apart, or on a board with the rows for it, three
  if (( ch >= 15 )); then rows=($(( mid - 6 )) $(( mid - 2 )) $(( mid + 2 )) $(( mid + 6 )))
  else                    rows=($(( mid - 3 )) $(( mid - 1 )) $(( mid + 1 )) $(( mid + 3 ))); fi
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  # every line's level first · a side's trunk is as heavy as its liveliest line
  IN_TC_LV=(); IN_TC_NX=(); IN_TC_NY=(); IN_TC_NK=(); IN_TC_NG=(); IN_TC_PK=(); IN_TC_ND=()
  IN_TC_WK=(); IN_TC_WD=(); IN_TC_WI=(); IN_TC_DMAX=0
  for (( l = 0; l < 8; l++ )); do
    sd=$(( l / 4 )); i=$(( l % 4 ))
    if (( sd )); then IN_TC_NX+=($NR); else IN_TC_NX+=($NL); fi
    IN_TC_NY+=(${rows[$i]})
    dy=$(( rows[i] - mid )); (( dy < 0 )) && dy=$(( -dy ))
    IN_TC_ND+=($(( 5 + dy + TL - NL )))       # how far along the wires its node is from the glass
    if (( (sd == 0 && i >= IN_N) || (sd == 1 && i >= IN_RN) )); then
      IN_TC_LV+=(-9); IN_TC_NK+=(0); IN_TC_NG+=(''); IN_TC_PK+=(0); W1+=(''); W2+=(''); continue
    fi
    in_tc_line $sd $i
    IN_TC_LV+=($ITL); IN_TC_NK+=($ITN); IN_TC_NG+=("$ITG"); IN_TC_PK+=($ITP); W1+=("$ITW1"); W2+=("$ITW2")
    if (( sd == 0 )); then
      (( ITL > TS0 )) && TS0=$ITL; (( ITL == -1 )) && RD0=1
    else
      (( ITL > TS1 )) && TS1=$ITL; (( ITL == -1 )) && RD1=1
    fi
  done
  # each line's own run, node to trunk
  for (( l = 0; l < 8; l++ )); do
    lv=${IN_TC_LV[$l]}; (( lv < -1 )) && continue
    sd=$(( l / 4 )); ry=${rows[$(( l % 4 ))]}
    dy=$(( ry - mid )); (( dy < 0 )) && dy=$(( -dy ))
    case $lv in
      2) wk=${IN_TC_INK[live]};  wg='━' ;;
      1) wk=${IN_TC_INK[idle]};  wg='─' ;;
      0) wk=${IN_TC_INK[ghost]}; wg='┄' ;;
      *) wk=${IN_TC_INK[read]};  wg='┄' ;;
    esac
    if (( sd == 0 )); then x0=$(( NL + 1 )); x1=$(( TL - 1 )); else x0=$(( TR + 1 )); x1=$(( NR - 1 )); fi
    for (( x = x0; x <= x1; x++ )); do
      k=$(( base + ry * TCOLS + x )); GCH[$k]="$wg"; GF[$k]=$wk
      if (( sd == 0 )); then in_tc_wire $k $(( 5 + dy + TL - x )); else in_tc_wire $k $(( 5 + dy + x - TR )); fi
    done
  done
  # each side's trunk, its joints, and the run from it into the glass
  for (( sd = 0; sd < 2; sd++ )); do
    if (( sd == 0 )); then ts=$TS0; rd=$RD0; tx=$TL; else ts=$TS1; rd=$RD1; tx=$TR; fi
    case $ts in
      2) tk=${IN_TC_INK[live]}; vg='┃'; hg='━' ;;
      1) tk=${IN_TC_INK[idle]}; vg='│'; hg='─' ;;
      *) if (( rd )); then tk=${IN_TC_INK[read]}; else tk=${IN_TC_INK[ghost]}; fi
         vg='┆'; hg='┄' ;;
    esac
    for (( y = rows[0]; y <= rows[3]; y++ )); do
      k=$(( base + y * TCOLS + tx )); GCH[$k]="$vg"; GF[$k]=$tk
    done
    for (( r = 0; r < 4; r++ )); do
      lv=${IN_TC_LV[$(( sd * 4 + r ))]}; (( lv < -1 )) && continue
      # heavy where a live line meets a heavy trunk; the trunk heavy and the
      # line not, the joint says so
      if (( ts == 2 && sd == 0 )); then
        case $r in 0) gl='┒' ;; 3) gl='┚' ;; *) gl='┨' ;; esac
        (( lv == 2 )) && case $r in 0) gl='┓' ;; 3) gl='┛' ;; *) gl='┫' ;; esac
      elif (( ts == 2 )); then
        case $r in 0) gl='┎' ;; 3) gl='┖' ;; *) gl='┠' ;; esac
        (( lv == 2 )) && case $r in 0) gl='┏' ;; 3) gl='┗' ;; *) gl='┣' ;; esac
      elif (( sd == 0 )); then
        case $r in 0) gl='┐' ;; 3) gl='┘' ;; *) gl='┤' ;; esac
      else
        case $r in 0) gl='┌' ;; 3) gl='└' ;; *) gl='├' ;; esac
      fi
      GCH[$(( base + rows[r] * TCOLS + tx ))]="$gl"
    done
    k=$(( base + mid * TCOLS + tx ))
    if (( sd == 0 )); then
      if (( ts == 2 )); then GCH[$k]='┣'; else GCH[$k]='├'; fi
      x0=$(( TL + 1 )); x1=$(( hL - 1 ))
    else
      if (( ts == 2 )); then GCH[$k]='┫'; else GCH[$k]='┤'; fi
      x0=$(( hR + 1 )); x1=$(( TR - 1 ))
    fi
    for (( x = x0; x <= x1; x++ )); do
      k=$(( base + mid * TCOLS + x )); GCH[$k]="$hg"; GF[$k]=$tk
      if (( sd == 0 )); then in_tc_wire $k $(( hL - x )); else in_tc_wire $k $(( x - hR )); fi
    done
    for (( y = rows[0]; y <= rows[3]; y++ )); do
      dy=$(( y - mid )); (( dy < 0 )) && dy=$(( -dy ))
      in_tc_wire $(( base + y * TCOLS + tx )) $(( 5 + dy ))
    done
  done
  # the nodes at rest, and their words · each typing in as its wire reaches it
  for (( l = 0; l < 8; l++ )); do
    lv=${IN_TC_LV[$l]}; (( lv < -1 )) && continue
    sd=$(( l / 4 )); ry=${rows[$(( l % 4 ))]}
    case $lv in
      2) nk=${IN_TC_INK[n2]}; if (( sd )); then vk=${IN_TC_INK[up]}; else vk=$GREY; fi ;;
      1) nk=${IN_TC_INK[n1]}; if (( sd )); then vk=${IN_TC_INK[stop]}; else vk=$GREY; fi ;;
      0) nk=${IN_TC_INK[n0]}; vk=${IN_TC_INK[v0]} ;;
      *) nk=${IN_TC_INK[vr]}; vk=${IN_TC_INK[vr]} ;;
    esac
    in_ell "${W2[$l]}" 9; s="$ELL"
    v_put ${IN_TC_NX[$l]} $ry "${IN_TC_NG[$l]}" ${IN_TC_NK[$l]}
    if (( sd == 0 )); then
      in_ell "${W1[$l]}" 11; v_text $(( NL - 22 )) $ry "$ELL" $nk
      v_text $(( NL - 1 - ${#s} )) $ry "$s" $vk
      tc_reveal $(( NL - 22 )) $ry 21 $(( IN_TC_WIRE0 + IN_TC_ND[l] / IN_TC_WV )) 0.24
    else
      in_ell "${W1[$l]}" 11; v_text $(( NR + 2 )) $ry "$ELL" $nk
      v_text $(( NR + 23 - ${#s} )) $ry "$s" $vk
      tc_reveal $(( NR + 2 )) $ry 21 $(( IN_TC_WIRE0 + IN_TC_ND[l] / IN_TC_WV )) 0.24
    fi
  done
  # WHAT EACH LINE CARRIES, written under it · on the list page's board, when
  # it has a free row under every line: an agent's model and how it is signed
  # in, from the name out toward the trunk; a runner's models in memory, in
  # under its word from the far edge
  if (( IN_BOARD_MENU && ch >= 9 )); then
    in_menu_inks
    for (( l = 0; l < 8; l++ )); do
      lv=${IN_TC_LV[$l]}; (( lv < 0 )) && continue
      sd=$(( l / 4 )); i=$(( l % 4 )); ry=$(( rows[i] + 1 ))
      if (( lv == 2 )); then vk=$IN_MI_SUB; else vk=$IN_MI_SUBD; fi
      if (( sd == 0 )); then
        if (( ${IA[$i.here]:-0} )); then
          s="${IA[$i.model]:-}"; [[ -n "${IA[$i.auth]:-}" ]] && s+="${s:+ · }${IA[$i.auth]}"
        else s='not on this machine'; fi
        in_ell "$s" $(( TL - NL + 21 ))
        v_text $(( NL - 22 )) $ry "$ELL" $vk
      else
        if   (( ${IR[$i.up]:-0} ));   then s="${IR[$i.served]:-nothing in memory}"
        elif (( ${IR[$i.here]:-0} )); then s='here · not running'
        else                               s='not on this machine'; fi
        in_ell "$s" $(( NR - TR + 21 ))
        v_text $(( NR + 23 - ${#ELL} )) $ry "$ELL" $vk
      fi
    done
  fi
  # THE PATHS THE PULSES RUN, node outward to the glass, with the wire's ink
  # under every cell of them (the live part mixes from it)
  IN_TC_PATH=(); IN_TC_P0=(); IN_TC_PW=()
  for (( l = 0; l < 8; l++ )); do
    IN_TC_P0+=(${#IN_TC_PATH[@]})
    lv=${IN_TC_LV[$l]}
    (( lv == 2 || lv == -1 )) || continue
    sd=$(( l / 4 )); ry=${rows[$(( l % 4 ))]}
    if (( sd == 0 )); then
      for (( x = NL + 1; x < TL; x++ )); do IN_TC_PATH+=($(( base + ry * TCOLS + x ))); done
      tx=$TL
    else
      for (( x = NR - 1; x > TR; x-- )); do IN_TC_PATH+=($(( base + ry * TCOLS + x ))); done
      tx=$TR
    fi
    if (( ry < mid )); then for (( y = ry; y <= mid; y++ )); do IN_TC_PATH+=($(( base + y * TCOLS + tx ))); done
    else                    for (( y = ry; y >= mid; y-- )); do IN_TC_PATH+=($(( base + y * TCOLS + tx ))); done; fi
    if (( sd == 0 )); then for (( x = TL + 1; x < hL; x++ )); do IN_TC_PATH+=($(( base + mid * TCOLS + x ))); done
    else                   for (( x = TR - 1; x > hR; x-- )); do IN_TC_PATH+=($(( base + mid * TCOLS + x ))); done; fi
  done
  IN_TC_P0+=(${#IN_TC_PATH[@]})
  for k in "${IN_TC_PATH[@]}"; do IN_TC_PW+=(${GF[$k]}); done
  IN_TC_MID=$mid; IN_TC_HL=$hL; IN_TC_HR=$hR; IN_TC_TS0=$TS0; IN_TC_TS1=$TS1
  in_tc_hub 0.0
  return 0
}
in_tc_hub() {   # in_tc_hub GLOW [LIVE] — THE GLASS, lit as much as what has just landed in it · LIVE, light crossing it now and then
  local -i q hk hb htx r x gk base k
  local -F gp
  local gl
  q=$(( int($1 * 20.0 + 0.5) )); (( q > 20 )) && q=20
  in_tc_mix ${IN_TC_INK[hub]} ${IN_TC_INK[hubhot]} $q; hk=$ITK
  in_tc_mix $BLACK $PURPLE $(( 2 + q / 5 )); hb=$ITK
  in_tc_mix ${IN_TC_INK[hubtx]} $WHITE $(( q / 2 )); htx=$ITK
  _run 13 '─'
  v_text $IN_TC_HL $(( IN_TC_MID - 2 )) "╭${RUN}╮" $hk $BLACK
  v_text $IN_TC_HL $(( IN_TC_MID + 2 )) "╰${RUN}╯" $hk $BLACK
  _run 13 ' '
  for r in -1 1; do
    v_put $IN_TC_HL $(( IN_TC_MID + r )) '│' $hk $BLACK
    v_text $(( IN_TC_HL + 1 )) $(( IN_TC_MID + r )) "$RUN" $hk $hb
    v_put $IN_TC_HR $(( IN_TC_MID + r )) '│' $hk $BLACK
  done
  if (( IN_TC_TS0 == 2 )); then gl='┥'; else gl='┤'; fi; v_put $IN_TC_HL $IN_TC_MID "$gl" $hk $BLACK
  if (( IN_TC_TS1 == 2 )); then gl='┝'; else gl='├'; fi; v_put $IN_TC_HR $IN_TC_MID "$gl" $hk $BLACK
  v_text $(( IN_TC_HL + 1 )) $IN_TC_MID '  THE GLASS  ' $htx $hb
  [[ -n "${2:-}" ]] || return 0
  # A GLINT now and then, the way the light catches a screen: a slant of
  # brighter glass crossing it in under a second, every few seconds
  gp=$(( IN_BNOW / 4.6 )); gp=$(( (gp - floor(gp)) * 4.6 ))
  (( gp < 1.0 )) || return 0
  gp=$(( gp * 20.0 - 4.0 ))
  in_tc_mix $hb $PINK 3; gk=$ITK
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for r in -1 0 1; do
    for (( x = int(gp) - r; x <= int(gp) - r + 1; x++ )); do
      (( x >= 0 && x < 13 )) || continue
      GB[$(( base + (IN_TC_MID + r) * TCOLS + IN_TC_HL + 1 + x ))]=$gk
    done
  done
  return 0
}
in_board_live() {   # in_board_live NOW INTRO — the board's live part: the pulses, the nodes they leave and reach, the glass lit by what lands
  # INTRO is the card coming up: a node is dark until its wire reaches it and
  # flashes as it does, no pulse sets off before its line is up, and the
  # glass is dark until its beat and comes on with a flash
  local -F now=$1 h ph G=0.0 g d f arr P V
  local -i intro=$2 l lv j L p0 q tail pk k c base hy
  local -a NF
  local -A PQ PI PH PW
  IN_BNOW=$now
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  # THE PULSES · every live line's in, every unread line's out, each on a
  # clock of its own so they never all land at once, and none of them until
  # the line's wire is up
  for (( l = 0; l < 8; l++ )); do
    NF+=(0.0)
    lv=${IN_TC_LV[$l]:--9}
    (( lv < -1 )) && continue
    arr=-100.0
    if (( intro )); then
      arr=$(( IN_TC_WIRE0 + IN_TC_ND[l] / IN_TC_WV ))
      if (( now < arr )); then GCH[$(( base + IN_TC_NY[l] * TCOLS + IN_TC_NX[l] ))]=' '; continue; fi
      f=$(( now - arr )); (( f < 0.40 )) && NF[$l]=$(( 1.0 - f / 0.40 ))   # a node lit as its wire reaches it
    fi
    (( lv == 2 || lv == -1 )) || continue
    p0=${IN_TC_P0[$l]}; L=$(( IN_TC_P0[l + 1] - p0 ))
    (( L > 0 )) || continue
    if (( lv == 2 )); then P=2.8; V=14.0; tail=5; pk=${IN_TC_PK[$l]}
      ph=$(( now / P + l * 0.29 + (l / 4) * 0.5 ))
    else                   P=2.2; V=11.0; tail=4; pk=${IN_TC_INK[ask]}
      ph=$(( now / P + l * 0.29 ))
    fi
    ph=$(( ph - floor(ph) ))
    (( now - ph * P >= arr + 0.15 )) || continue  # this pulse set off before the line was up
    h=$(( ph * P * V - 1.5 ))
    for (( j = 0; j < L; j++ )); do
      if (( lv == 2 )); then d=$(( h - j )); else d=$(( h - (L - 1 - j) )); fi
      (( d < 0.0 || d >= tail )) && continue
      q=$(( int((1.0 - d / tail) ** 1.6 * 20.0 + 0.5) ))
      (( q > 0 )) || continue
      k=${IN_TC_PATH[$(( p0 + j ))]}
      (( q > ${PQ[$k]:-0} )) || continue
      PQ[$k]=$q; PI[$k]=$pk; PW[$k]=${IN_TC_PW[$(( p0 + j ))]}
      if (( d < 1.0 )); then PH[$k]=1; else PH[$k]=0; fi
    done
    # the glass lights as a pulse lands; a node, as one leaves it or the
    # question reaches it
    if (( lv == 2 )); then
      d=$(( h - L )); if (( d >= 0.0 && d < 4.0 )); then g=$(( 1.0 - d / 4.0 )); (( g > G )) && G=$g; fi
      d=$(( abs(h) )); (( d < 1.5 )) && { f=$(( 1.0 - d / 1.5 )); (( f > NF[l] )) && NF[$l]=$f; }
    else
      d=$(( abs(h - L) )); (( d < 2.5 )) && { f=$(( 1.0 - d / 2.5 )); (( f > NF[l] )) && NF[$l]=$f; }
    fi
  done
  for k in "${(@k)PQ[@]}"; do
    in_tc_mix ${PW[$k]} ${PI[$k]} ${PQ[$k]}; c=$ITK
    (( ${PH[$k]:-0} )) && { in_tc_mix $c $WHITE 7; c=$ITK }
    GF[$k]=$c
  done
  for (( l = 0; l < 8; l++ )); do
    f=${NF[$l]}
    (( f > 0.0 )) || continue
    in_tc_mix ${IN_TC_NK[$l]} $WHITE $(( int(f * 12.0) ))
    v_put ${IN_TC_NX[$l]} ${IN_TC_NY[$l]} "${IN_TC_NG[$l]}" $ITK
  done
  # ── THE GLASS · dark until its beat, then on with a flash; after that
  # breathing a little on its own, and lit by whatever lands ──
  if (( intro && now < IN_TC_HUB0 )); then
    for (( hy = IN_TC_MID - 2; hy <= IN_TC_MID + 2; hy++ )); do
      k=$(( base + hy * TCOLS + IN_TC_HL ))
      for (( j = 0; j < 15; j++ )); do GCH[$(( k + j ))]=' '; GB[$(( k + j ))]=$BLACK; done
    done
  else
    (( intro )) && { f=$(( now - IN_TC_HUB0 )); (( f < 0.5 )) && { g=$(( 1.0 - f / 0.5 )); (( g > G )) && G=$g; }; }
    wave $now 0.5 0; g=$(( 0.12 * WV )); (( g > G )) && G=$g
    (( G > 1.0 )) && G=1.0
    in_tc_hub $G live
  fi
  return 0
}
in_title() {   # in_title T — the card: the still part kept, and the wires, the pulses, the glass and the type live over it
  local -F t=$1 d grow
  local -i i n
  PACK_FILL=1
  in_tc_inks
  in_title_key
  tc_card "$ITKEY" in_title_base $t
  tc_spaced $(( IN_TC_OY + 7 )) 'EVERY AGENT · EVERY MODEL' $MAGENTA $CYAN $t 0.42
  # THE WIRES GOING OUT · past the front, nothing yet; the front itself a
  # spark of the wire's own ink, whitened
  grow=$(( (TC_NOW - IN_TC_WIRE0) * IN_TC_WV ))
  if (( grow < IN_TC_DMAX + 2.0 )); then
    n=${#IN_TC_WK[@]}
    for (( i = 0; i < n; i++ )); do
      d=$(( IN_TC_WD[i] - grow ))
      if (( d > 0.0 )); then GCH[${IN_TC_WK[$i]}]=' '
      elif (( d > -2.0 )); then in_tc_mix ${IN_TC_WI[$i]} $WHITE 12; GF[${IN_TC_WK[$i]}]=$ITK; fi
    done
  fi
  in_board_live $TC_NOW 1
  tc_status $(( IN_TC_OY + IN_TC_CH + 14 )) "$IN_TC_ST" $IN_TC_STC $t 1.28
  tc_prompt $(( IN_TC_OY + IN_TC_CH + 16 )) $t '' 1.55
  return 0
}

intel_draw() {   # intel_draw T — the standing page · the cabinet runs the channel change around it
  IN_NOW=$1
  # THE TITLE CARD, while the door has it up (tc_*, terminal.command)
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_card]} )); then in_title $1; return 0; fi
  # WHICH PAGES HAVE A FILL LAYOUT YET.  The rest keep the cabinet glass and
  # centre on the lit fill until they are taught to reflow, one by one.
  case "$IN_VIEW" in
    menu|cloud|local|prompts|hist|keys|bench|console|rewrite|route) PACK_FILL=1 ;;
    *)                                                         PACK_FILL=0 ;;
  esac
  in_row_init
  in_surface $1
  return 0
}


# ── how many rows the page in front has a cursor in ───────────────────────
# WHICH LIST THE CURSOR IS IN, AND HOW LONG IT IS.  Every page that has a
# cursor answers here rather than in the key handler, so ▴▾ is one piece of
# code however many lists this machine grows.
in_rows() {
  case "$IN_VIEW" in
    menu)  IROWS=$IN_PAGES; IRSEL=$IN_MROW ;;
    cloud) IROWS=$IN_N; IRSEL=$IN_SEL ;;
    rewrite) IROWS=0; IRSEL=0 ;;
    local) if [[ "$IN_LFOCUS" == runner ]]; then IROWS=$IN_RN; IRSEL=$IN_RSEL
           else IROWS=$IM_N; IRSEL=$IN_LSEL; fi ;;
    prompts) IROWS=$IP_N; IRSEL=$IN_PSEL ;;
    hist)    IROWS=$IN_LOG_N; IRSEL=$IN_HSEL ;;
    *)     IROWS=0; IRSEL=0 ;;
  esac
  return 0
}
in_set_sel() {   # in_set_sel N — back into whichever cursor in_rows just read
  case "$IN_VIEW" in
    menu)  IN_MROW=$1 ;;
    cloud) IN_SEL=$1 ;;
    local) if [[ "$IN_LFOCUS" == runner ]]; then IN_RSEL=$1; else IN_LSEL=$1; fi ;;
    prompts) IN_PSEL=$1 ;;
    hist)    IN_HSEL=$1 ;;
  esac
  return 0
}

in_page_go() {   # in_page_go D — ◂ and ▸, and they wrap
  local -i d=$1 n
  n=$(( (IN_PAGE + d + IN_PAGES) % IN_PAGES ))
  in_go_view "${IN_PV[$n]}"; snd move
  return 0
}

# ── THE WHEEL, ON EVERY SURFACE OF THIS MACHINE ────────────────────────────
# The door hands a wheel notch over the glass to the machine as a word --
# wheelup, wheeldown, one per notch -- with where it landed in WH_X, WH_Y
# (glass cells), and PAGE UP / PAGE DOWN as pgup, pgdn.  A page with a
# cursor moves it, quietly; a page with more text than room moves the text;
# a box standing over the page moves its own cursor; and a session's
# terminal goes back through the lines that have left its screen.  Nothing
# is ever DONE by the wheel: a notch never opens, closes, sends or copies,
# and it never leaves the field the reader is typing in.
in_wheel() {   # in_wheel KEY -> 0, always
  local -i n=1 page=0 c
  case "$1" in
    wheelup)   n=-1 ;;
    wheeldown) n=1 ;;
    pgup)      n=-1; page=1 ;;
    pgdn)      n=1;  page=1 ;;
  esac
  # the terminal: up is into the past, down is back toward now
  if [[ "$IN_VIEW" == shell && -n "$GT_AT" ]]; then
    gt_wheel "$1"
    return 0
  fi
  if (( RW_PK_OPEN == 1 )); then
    (( page )) && n=$(( n * 7 ))
    rw_pick_move $n
    return 0
  fi
  if (( IN_PICK_OPEN == 1 )); then
    c=$(( IN_PICKSEL + n ))
    (( c < 0 )) && c=0
    (( c > IN_CAT_N - 1 )) && c=$(( IN_CAT_N - 1 ))
    IN_PICKSEL=$c
    return 0
  fi
  (( IN_GATE == 1 )) && return 0
  case "$IN_VIEW" in
    rewrite)
      (( page )) && n=$(( n * 14 ))
      RW_TOP=$(( RW_TOP + n )); (( RW_TOP < 0 )) && RW_TOP=0
      return 0 ;;
    console) in_console_wheel $n $page; return 0 ;;
    bench)   in_bench_wheel $n $page; return 0 ;;
    local)
      # the list under the pointer is the list that moves
      if   (( ${WH_Y:-0} >= 3  && ${WH_Y:-0} < 10 )); then IN_LFOCUS=runner
      elif (( ${WH_Y:-0} >= 10 && ${WH_Y:-0} < 21 )); then IN_LFOCUS=model; fi ;;
  esac
  in_rows
  (( IROWS > 0 )) || return 0
  (( page )) && n=$(( n * 8 ))
  c=$(( IRSEL + n ))
  (( c < 0 )) && c=0
  (( c > IROWS - 1 )) && c=$(( IROWS - 1 ))
  (( c != IRSEL )) && in_set_sel $c
  return 0
}
in_console_wheel() {   # in_console_wheel N PAGE
  local -i n=$1 rows=20 total start
  in_chat_lines $(( CN_LW - 10 ))
  total=${#CT_LN[@]}
  (( total > rows )) || { CH_TOPIX=-1; return 0 }
  (( $2 )) && n=$(( n * (rows - 2) ))
  start=$(( CH_TOPIX >= 0 ? CH_TOPIX : total - rows ))
  start=$(( start + n ))
  (( start < 0 )) && start=0
  # wheeled back down to the end, the transcript follows the end again
  if (( start >= total - rows )); then CH_TOPIX=-1; else CH_TOPIX=$start; fi
  return 0
}
in_bench_wheel() {   # in_bench_wheel N PAGE — the column under the pointer
  local -i n=$1 i W=34 keep nl
  local body
  (( BN_N )) || return 0
  i=$(( (${WH_X:-0} - 2) / W ))
  (( i < 0 )) && i=0
  (( i > BN_N - 1 )) && i=$(( BN_N - 1 ))
  body="${BN_TEXT[$i]}"; body="${body//$'\t'/  }"
  in_wrap_keep "$body" $(( W - 4 ))
  nl=${#WRP[@]}
  (( nl > 11 )) || { BN_TOP[$i]=-1; return 0 }
  (( $2 )) && n=$(( n * 9 ))
  if (( ${BN_TOP[$i]:--1} >= 0 )); then keep=${BN_TOP[$i]}
  elif [[ "${BN_STATE[$i]}" == running ]]; then keep=$(( nl - 11 ))
  else keep=0; fi
  keep=$(( keep + n ))
  (( keep < 0 )) && keep=0
  (( keep > nl - 11 )) && keep=$(( nl - 11 ))
  # wheeled back to the tail of an answer still arriving, the column
  # follows the tail again
  if [[ "${BN_STATE[$i]}" == running ]] && (( keep == nl - 11 )); then BN_TOP[$i]=-1
  else BN_TOP[$i]=$keep; fi
  return 0
}

intel_key() {   # intel_key KEY — 0 if this machine took it
  local k="$1"
  local -i i
  # THE TITLE CARD ANSWERS FIRST: its keys are the door's, on every machine
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_key]} )); then tc_key "$k"; return $?; fi
  # THE WHEEL FIRST, whatever is standing: it is never a key, and every
  # surface below answers "any key" with something the wheel must not do.
  case "$k" in
    wheelup|wheeldown|pgup|pgdn) in_wheel "$k"; return 0 ;;
  esac
  # A SESSION THAT HAS ENDED IS STILL ON THE GLASS, SO YOU CAN READ IT.  The
  # keyboard came back the moment the agent went -- raw mode belongs to
  # whoever is listening -- so the machine is answering keys again, and the
  # first one of them means "I have read it, take it away".  Every key, not
  # one nominated key: nobody should have to work out which.
  if [[ "$IN_VIEW" == shell ]]; then
    in_sh_done
    return 0
  fi
  # THE GATE OWNS THE KEYBOARD WHILE IT IS UP.  A modal that let ◂ through
  # would change the page behind itself, and a modal that let ⎋ through while
  # a job was running would hide the job -- so it answers everything, and it
  # answers the two questions it is actually asking.
  # THE FIELD OWNS THE KEYBOARD WHILE IT IS LIVE, and it answers EVERY key:
  # this is the branch the door's ⌫, [M] and [Q] now reach through, and a key
  # that fell past it would close the machine or open the power gate in the
  # middle of a typed word.
  if [[ "$IN_MODE" == edit ]]; then
    case "$k" in
      enter) IN_MODE='nav'
             # the field on loan to the engine picker gives back a model id
             if (( RW_MTYPE )); then rw_model_typed; return 0; fi
             case "$IN_VIEW" in
               bench)   in_bench_start ;;
               route)   in_route_send ;;
               rewrite) rw_start ;;
               # THE FIELD STAYS LIVE ON THE CONSOLE, because a conversation is
               # a series of lines and making the reader press ⏎ twice between
               # each of them would be a chat that argues with its own shape.
               console) in_chat_send && IN_MODE='edit' ;;
             esac
             return 0 ;;
      esc)   IN_MODE='nav'
             if (( RW_MTYPE )); then rw_model_untyped; return 0; fi
             snd away; return 0 ;;
      *)     in_line_key "$k"; return 0 ;;
    esac
  fi
  # THE ENGINE PICKER, on REWRITE: ▴▾ walk the engines, ⏎ takes one, [M]
  # borrows the field for a model of the reader's own, anything else keeps
  # what was chosen.
  if (( RW_PK_OPEN == 1 )); then
    case "$k" in
      down)  rw_pick_move 1  && snd move; return 0 ;;
      up)    rw_pick_move -1 && snd move; return 0 ;;
      enter) rw_pick_take; snd pick; return 0 ;;
      m|M)   [[ "$RW_PK_FOR" == console ]] && { say 'a local model is picked from the list'; snd no; return 0 }
             rw_model_ask; return 0 ;;
      *)     rw_pick_close; snd away; return 0 ;;
    esac
  fi

  # THE CHOOSER, WHICH IS A MODAL IN FRONT OF A MODAL: [I] on LOCAL opens the
  # catalogue, ⏎ there opens the gate, and Y there is the only thing that
  # downloads.  Three steps rather than one, and deliberately: the arithmetic
  # is the machine's business and the nineteen gigabytes is yours.
  if (( IN_PICK_OPEN == 1 )); then
    case "$k" in
      down) (( IN_PICKSEL < IN_CAT_N - 1 )) && { (( IN_PICKSEL++ )); snd move }
            return 0 ;;
      up)   (( IN_PICKSEL > 0 )) && { (( IN_PICKSEL-- )); snd move }
            return 0 ;;
      enter)    in_pull_gate $IN_PICKSEL; snd pick; return 0 ;;
      *)        in_pick_close; snd away; return 0 ;;
    esac
  fi
  if (( IN_GATE == 1 )); then
    case "$k" in
      # [Y] AND ONLY [Y].  ⏎ is how you ARRIVED here -- it is the key that
      # opened the gate from the row behind it -- so accepting ⏎ as the
      # affirmative meant a double tap, or a key held a moment too long, ran
      # a curl-to-bash.  That is the exact accident this gate exists for.
      y|Y)
        if [[ -z "$IN_GATE_LINE" ]]; then snd no; return 0; fi
        # A ROUTE OPENS A VEHICLE, NOT A JOB · the gate confirmed the line, so
        # [Y] hands it to the CLI or the router and steps into the glass.
        if [[ "$IN_GATE_KIND" == route ]]; then in_gate_close; in_route_go; return 0; fi
        in_gate_close
        # A PULL OR A DROP RE-READS THE DISK, NOT A ROSTER ROW.  The job's row
        # number is the one its finish hands back to the scan, and a catalogue
        # or disk index handed to in_scan_row would re-probe an unrelated agent
        # -- so both hand back -1, which is the whole-model-list rescan.
        if [[ "$IN_GATE_KIND" == pull || "$IN_GATE_KIND" == drop ]]; then
          in_job_start "$IN_GATE_KIND" -1 "$IN_GATE_WHO" "$IN_GATE_LINE"
        else
          in_job_start "$IN_GATE_KIND" $IN_GATE_ROW "$IN_GATE_WHO" "$IN_GATE_LINE"
        fi
        say "$IN_GATE_WHO · running"; snd pick
        return 0 ;;
      *) in_gate_close; snd away; return 0 ;;
    esac
  fi
  # THE CHOOSER OWNS THE KEYBOARD WHILE IT IS UP · [1]/[c] the console,
  # [2]/[o]/⏎ opencode, anything else backs out and nothing opens.
  if (( IN_TALK == 1 )); then
    case "$k" in
      1|c|C)       in_talk_close; in_local_chat; return 0 ;;
      2|o|O|enter) in_talk_close; in_local_run;  return 0 ;;
      *)           in_talk_close; snd away;      return 0 ;;
    esac
  fi
  in_rows
  case "$k" in
    # ARROWS ONLY, AND NO j/k -- WHICH IS NOT AN OVERSIGHT.  On this machine
    # LETTERS REACH PAGES and digits reach rows, and that division is the
    # whole keyboard: [K] is KEYS, silk-screened on the control panel in front
    # of the reader.  Binding `k` to `up` as well, the way the monitor can
    # afford to, meant the one key the panel promises for KEYS quietly moved
    # the cursor instead -- and the panel is on the glass while the vim habit
    # is only in the reader's fingers.  So the habit loses.
    down)
      # on REWRITE the arrows scroll the answer, which has no rows to select
      [[ "$IN_VIEW" == rewrite ]] && { (( RW_TOP++ )); return 0 }
      (( IROWS > 0 && IRSEL < IROWS - 1 )) && { in_set_sel $(( IRSEL + 1 )); snd move }
      return 0 ;;
    up)
      [[ "$IN_VIEW" == rewrite ]] && { (( RW_TOP > 0 )) && (( RW_TOP-- )); return 0 }
      (( IROWS > 0 && IRSEL > 0 )) && { in_set_sel $(( IRSEL - 1 )); snd move }
      return 0 ;;
    # ⇥ IS THE ONLY KEY ON THIS MACHINE THAT MOVES BETWEEN TWO LISTS on one
    # page, and LOCAL is the only page with two.
    $'\t')
      if [[ "$IN_VIEW" == local ]]; then
        [[ "$IN_LFOCUS" == runner ]] && IN_LFOCUS=model || IN_LFOCUS=runner
        snd move; return 0
      fi
      return 1 ;;
    # ◂ ▸ ARE THE PAGES, and on this machine that is all they are: there is no
    # chooser to be standing in, so left has nothing else it could mean.
    left)  [[ "$IN_VIEW" == menu ]] && return 0; in_page_go -1; return 0 ;;
    right) [[ "$IN_VIEW" == menu ]] && return 0; in_page_go  1; return 0 ;;
    # ⎋ IS BACK ONE, and one level up from CLOUD is the door's own roster.
    # Refusing it is how the machine says so: the cabinet offered this key
    # here first, and takes a refusal as its own.
    # ⌫ ON A PAGE WITH A FIELD IS THE FIELD'S.  A reader looking at the
    # question they typed, who presses ⌫ to fix a word, meant to edit it --
    # and what happened was that the door took the key and closed the machine,
    # losing the line.  On the two pages that have a field it reopens the
    # field with the cursor at the end; everywhere else it is still the way
    # out, which is what the door offered it here for.
    back)
      if [[ "$IN_VIEW" == bench || "$IN_VIEW" == console || "$IN_VIEW" == rewrite || "$IN_VIEW" == route ]]; then
        IN_MODE='edit'; IN_LI=${#IN_LINE}; snd move; return 0
      fi
      return 1 ;;
    # THE OTHER THREE THE DOOR OFFERS FIRST.  Outside the field they are the
    # door's, and refusing them is how this machine says so -- which leaves
    # [M] closing it and [Q] opening the power gate, exactly as before.
    # ⎋ ON THE CONSOLE IS BACK ONE, TO LOCAL · the console is a surface under
    # LOCAL now, not a top-level page, so ⎋ climbs to it rather than closing the
    # whole machine.  [M] still closes it, the way the door offers everywhere.
    esc)
      # ⎋ ON THE MENU IS THE ONE THAT LEAVES · the menu is the top of this machine,
      # so refusing the key here is how it hands the door back its own roster.
      if [[ "$IN_VIEW" == menu ]]; then return 1; fi
      if [[ "$IN_VIEW" == console ]]; then in_go_view local; snd move; return 0; fi
      # REWRITE IS A SUB-PAGE OF PROMPTS · ⎋ climbs to it, not out of the machine.
      if [[ "$IN_VIEW" == rewrite ]]; then in_go_view prompts; snd move; return 0; fi
      # EVERY TOP-LEVEL PAGE CLIMBS TO THE MENU · the one the footers have always
      # promised.  ⎋ here is BACK ONE, and one level up from any page is the menu.
      in_go_view menu; snd move; return 0 ;;
    # [M] CYCLES THE ROUTE PREFERENCE · elsewhere it is still the door's close
    m|M)
      if [[ "$IN_VIEW" == route ]]; then
        (( IN_RMODE = (IN_RMODE + 1) % 3 ))
        say "${IN_RMODE_NAME[$IN_RMODE]} · ${IN_RMODE_PCT[$IN_RMODE]}"; snd move; return 0
      fi
      return 1 ;;
    # [B] ON ROUTE CYCLES THE METERED-CLOUD CAP · it takes effect when [G]
    # rewrites the config and the proxy is restarted, which the toast says.
    b|B)
      if [[ "$IN_VIEW" == route ]]; then
        (( IN_BUDGET_SEL = (IN_BUDGET_SEL + 1) % ${#IN_BUDGET_OPT[@]} ))
        local -i c=${IN_BUDGET_OPT[$IN_BUDGET_SEL]}
        (( c > 0 )) && say "cap \$$c/day per provider · [G] writes it" || say 'no cap · [G] writes it'
        snd move; return 0
      fi
      ;;   # off ROUTE, fall through so [B] still reaches BENCH
    q|Q) return 1 ;;
    # ⏎ IS "DO THE ONE THING THIS ROW IS FOR", and what that is depends on
    # whether the agent is here: an agent on this machine gets a tab, and one
    # that is not gets the gate that would put it here.  The row has said
    # which of the two it is since the frame it was drawn.
    enter)
      case "$IN_VIEW" in
        menu) in_go_view "${IN_PV[$IN_MROW]}"; snd pick ;;
        cloud)
          if (( ${IA[$IN_SEL.here]:-0} )); then in_deal $IN_SEL
          else in_gate_open install $IN_SEL; snd pick; fi ;;
        local) in_local_enter ;;
        route) IN_MODE='edit'; in_line_set "$IN_LINE"; snd pick ;;
        bench)   IN_MODE='edit'; in_line_set "$IN_LINE"; snd pick ;;
        console) IN_MODE='edit'; in_line_set "$IN_LINE"; snd pick ;;
        # ⏎ ON REWRITE IS THE NEXT THING TO DO: type, or -- once a prompt has
        # come back -- take it.  [A] is how you ask again from a result.
        rewrite) if [[ "$RW_STATE" == done ]]; then rw_copy
                 elif [[ "$RW_STATE" == run ]]; then snd no
                 else IN_MODE='edit'; in_line_set "$IN_LINE"; snd pick; fi ;;
        prompts) in_prompt_copy ;;
      esac
      return 0 ;;
    n|N)
      if [[ "$IN_VIEW" == console ]]; then
        in_chat_new; say 'new session'; snd away; return 0
      fi
      return 1 ;;
    a|A)
      if [[ "$IN_VIEW" == bench ]]; then
        [[ -n "$IN_LINE" ]] && { in_bench_start; return 0 }
        IN_MODE='edit'; snd pick; return 0
      fi
      if [[ "$IN_VIEW" == rewrite ]]; then
        [[ "$RW_STATE" == run ]] && { snd no; return 0 }
        IN_MODE='edit'; in_line_set "${IN_LINE:-$RW_IN}"; snd pick; return 0
      fi
      return 1 ;;
    e|E)
      if [[ "$IN_VIEW" == rewrite ]]; then
        [[ "$RW_STATE" == run ]] && { say 'wait for it, or [X] stops it'; snd no; return 0 }
        rw_pick_open; return 0
      fi
      # ...AND THE CONSOLE'S MODEL, from the same list, the local half of it.
      # Mid-answer it takes effect on the next turn.
      if [[ "$IN_VIEW" == console ]]; then
        rw_pick_open console; return 0
      fi
      return 1 ;;
    # [P] FLIPS REWRITE BETWEEN A TEMPLATE (placeholders to fill) and a
    # ready-to-send prompt (add-nothing, no brackets) · the router uses the latter
    p|P)
      if [[ "$IN_VIEW" == rewrite ]]; then
        [[ "$RW_STATE" == run ]] && { snd no; return 0 }
        (( RW_PLAIN = ! RW_PLAIN ))
        (( RW_PLAIN )) && say 'ready to send · no placeholders' \
                       || say 'template · leaves placeholders to fill'
        snd move; return 0
      fi
      ;;   # off REWRITE, fall through so [P] still reaches PROMPTS
    # [W] ON PROMPTS OPENS REWRITE · the workshop under the shelf.  reWrite,
    # and ⎋ from there climbs back to PROMPTS -- the way CONSOLE sits under LOCAL.
    w|W)
      if [[ "$IN_VIEW" == prompts ]]; then in_go_view rewrite; snd pick; return 0; fi
      ;;   # elsewhere W is not a page key; fall through and the ring refuses it
    # [G] ON ROUTE WRITES THE PROXY CONFIG from the keys the scan found
    g|G)
      if [[ "$IN_VIEW" == route ]]; then
        if in_litellm_config; then
          in_route_config; in_guard_hook
          say 'wrote litellm.yaml, the guard + the router config'; snd pick
        else say 'could not write the config'; snd no; fi
        return 0
      fi
      return 1 ;;
    # [O] ON ROUTE OPENS THE FULL SESSION · opencode on router/auto, for a back-
    # and-forth where the proxy routes every turn.  The composer's ⏎ is for one
    # prompt at a time; this is the whole conversation, in the glass.
    o|O)
      if [[ "$IN_VIEW" == route ]]; then in_route_run; return 0; fi
      return 1 ;;
    s|S)
      if [[ "$IN_VIEW" == local && "$IN_LFOCUS" == runner ]]; then
        in_runner_start $IN_RSEL; return 0
      fi
      # [S] ON THE CONSOLE SAVES THE SESSION · a markdown report of the whole
      # conversation and its counts, written to the reader's Downloads.
      if [[ "$IN_VIEW" == console ]]; then in_chat_save; return 0; fi
      return 1 ;;
    # [D] KEEPS A MODEL LOADED in ollama without opening anything -- the
    # thing ⏎ used to do, kept for the console and the rewrite page, which
    # answer faster on a model that is already awake
    d|D)
      if [[ "$IN_VIEW" == local && "$IN_LFOCUS" == model ]]; then
        in_local_load; return 0
      fi
      return 1 ;;
    # [X] STOPS WHAT THIS PAGE IS SHOWING YOU.  Three different things can be
    # running at once, and resolving the key by a fixed priority meant that
    # pressing [X] on CLOUD -- whose footer was at that moment promising to
    # stop the install in the strip below it -- stopped a console session on
    # another page instead, and said `stopped`, which was true of something
    # you could not see.  The page decides; then, only if this page has
    # nothing of its own to stop, the job in the strip does.
    x|X)
      case "$IN_VIEW" in
        console)
          if [[ "$CH_STATE" == run ]]; then
            in_chat_stop; say 'the answer was cut off'; snd no; return 0
          fi ;;
        bench)
          in_bench_live
          if (( IBLIVE )); then in_bench_stop; say 'the bench was stopped'; snd no; return 0; fi ;;
        rewrite)
          if [[ "$RW_STATE" == run ]]; then rw_stop; say 'the rewrite was stopped'; snd no; return 0; fi ;;
      esac
      if [[ "$IN_JOB_STATE" == run ]]; then
        in_job_stop; say "${IN_JOB_LABEL} · stopped"; snd no; return 0
      fi
      return 1 ;;
    # [R] IS ROUTE NOW · the manual rescan is gone (the probe runs on its own
    # every few seconds), so R falls through to the page ring below and opens
    # ROUTE, its own first letter.
    i|I)
      case "$IN_VIEW" in
        cloud)
          if (( ${IA[$IN_SEL.here]:-0} )); then
            say "${IN_NAME[$IN_SEL]} · already here"; snd no
          else
            in_gate_open install $IN_SEL; snd pick
          fi
          return 0 ;;
        local) in_pick_open; snd pick; return 0 ;;
      esac
      return 1 ;;
    u|U)
      if [[ "$IN_VIEW" == cloud ]]; then
        if (( ${IA[$IN_SEL.here]:-0} )); then
          in_gate_open remove $IN_SEL; snd pick
        else
          say "${IN_NAME[$IN_SEL]} · not on this machine"; snd no
        fi
        return 0
      fi
      # [U] ON LOCAL REMOVES THE MODEL UNDER THE CURSOR, and it is handled here
      # rather than being allowed to fall through: past this pack the door reads
      # [U] as UNINSTALL THE WHOLE SUITE, and one model taken off is not the
      # nine agents taken off.  So local always answers it, even to refuse.
      if [[ "$IN_VIEW" == local ]]; then
        in_local_drop; return 0
      fi
      return 1 ;;
  esac
  # DIGITS REACH ROWS -- and on BENCH the rows are the three columns, which
  # is the one page where a digit means something other than an agent.
  if [[ "$k" == <1-9> ]]; then
    i=$(( k - 1 ))
    if [[ "$IN_VIEW" == bench ]] && (( BN_N > 0 )); then
      in_bench_keep $i; return 0
    fi
    # LOCAL DRAWS `[1]`…`[9]` DOWN ITS MODEL LIST in the same column and the
    # same amber CLOUD uses for the keys that work.  They did not work: a
    # digit there jumped to CLOUD and selected an AGENT, so `[2]` beside
    # `qwen3:8b` selected ANTIGRAVITY on another page.
    if [[ "$IN_VIEW" == local ]] && (( IM_N > 0 )); then
      if (( i < IM_N && i < 9 )); then
        IN_LFOCUS='model'; IN_LSEL=$i; snd pick
      else
        snd no
      fi
      return 0
    fi
    if (( i < IN_N )); then
      IN_SEL=$i
      [[ "$IN_VIEW" == cloud ]] || in_go_view cloud
      snd pick; return 0
    fi
    snd no; return 0
  fi
  # ...AND LETTERS REACH PAGES
  for (( i = 0; i < IN_PAGES; i++ )); do
    [[ "${k:u}" == "${IN_PK[$i]}" ]] || continue
    in_go_view "${IN_PV[$i]}"; snd pick; return 0
  done
  return 1
}

# ⏎ ON LOCAL, WHICH IS TWO DIFFERENT VERBS depending on which of the two
# lists the cursor is in -- and that is exactly why ⇥ exists and why the panel
# title says which list is live.
in_local_enter() {
  if [[ "$IN_LFOCUS" == runner ]]; then in_runner_start $IN_RSEL; return 0; fi
  in_talk_open
  return 0
}

# ⏎ ON A MODEL ASKS HOW YOU WANT TO TALK TO IT · the console is folded into
# LOCAL now, so CONSOLE is no longer a page of its own -- it is the quick,
# in-glass chat you reach here, beside opencode.  [1] the console · [2] opencode.
in_talk_open() {
  (( IM_N > 0 )) || { say 'nothing on this disk · [I] installs one'; snd no; return 0 }
  (( IN_LSEL < IM_N )) || return 0
  # AN EMBEDDING MODEL CANNOT CHAT EITHER WAY, so it never gets the chooser.
  in_model_verdict "${IM_NAME[$IN_LSEL]}"
  [[ "$IMV" == embed ]] && { say 'an embedding model · it cannot chat · ⎋'; snd no; return 0 }
  IN_TALK=1; modal_open; snd pick
  return 0
}
in_talk_close() { IN_TALK=2; modal_close; return 0 }

# [1] · the built-in console, bound to the model the cursor is on.  ollama
# loads on demand so any pulled model works; a .gguf must already be served.
in_local_chat() {
  local m where
  local -i r=-1
  (( IN_LSEL < IM_N )) || return 0
  m="${IM_NAME[$IN_LSEL]}"; where="${IM_WHERE[$IN_LSEL]}"
  case "$where" in
    ollama) r=0 ;;
    gguf)   r=1 ;;
    mlx)    r=3 ;;
    *) say "$m · nothing here can chat that"; snd no; return 0 ;;
  esac
  if (( ! ${IR[$r.up]:-0} )); then
    case $r in
      0) say 'ollama is not up — [⇥] then [S] starts it' ;;
      3) say 'mlx_lm.server is not up — [⇥] then [S] starts it' ;;
      *) say 'llama-server is not holding it — start it first' ;;
    esac
    snd no; return 0
  fi
  CH_PINNED=$r; CH_RUNNER=$r; CH_MODEL="$m"; CH_LOCK=1
  in_go_view console
  return 0
}

# [D] KEEPS A MODEL LOADED · the empty-prompt generate with a keep_alive
in_local_load() {
  (( IM_N > 0 )) || { say 'nothing on this disk to load'; snd no; return 0 }
  (( IN_LSEL < IM_N )) || return 0
  if [[ "${IM_WHERE[$IN_LSEL]}" != ollama ]]; then
    say "${IM_NAME[$IN_LSEL]} · a .gguf is llama-server's to load, not ollama's"
    snd no; return 0
  fi
  if (( ! ${IR[0.up]:-0} )); then
    say 'ollama is not up — [⇥] then [S] starts it'; snd no; return 0
  fi
  if ! in_load_line "${IM_NAME[$IN_LSEL]}"; then
    say 'no curl on this machine'; snd no; return 0
  fi
  in_job_start load -1 "${IM_NAME[$IN_LSEL]}" "$ILL"
  say "${IM_NAME[$IN_LSEL]} · loading"; snd pick
  return 0
}

# [U] TAKES A MODEL OFF THIS DISK · the gate shows the exact line first
# THE CURSOR IS ON A MODEL OR IT IS ON A RUNNER, and [U] is the model's verb.
# A runner is ollama or llama-server itself, not a thing this page installed,
# so [U] on the runner list refuses rather than guessing which model the last
# model-cursor was on -- taking off a model the reader cannot see is exactly
# the accident the gate exists to prevent.
in_local_drop() {
  (( IM_N > 0 )) || { say 'nothing on this disk to remove'; snd no; return 0 }
  if [[ "$IN_LFOCUS" == runner ]]; then
    say 'that is a runner · ⇥ to a model to remove'; snd no; return 0
  fi
  (( IN_LSEL < IM_N )) || return 0
  in_model_rm_line "${IM_NAME[$IN_LSEL]}" "${IM_WHERE[$IN_LSEL]}" "${IM_PATH[$IN_LSEL]:-}"
  if [[ -z "$IRML" ]]; then
    say 'nothing here knows where that one lives'; snd no; return 0
  fi
  in_drop_gate $IN_LSEL; snd pick
  return 0
}

# ── ⏎ ON A MODEL · OPENCODE, IN THE GLASS, ON THAT MODEL ──────────────────
# A MODEL IS RUN BY OPENCODE, NOT BY A CHAT OF THIS CABINET'S OWN.  The
# CONSOLE page can talk to a runner, but a pulled model is worth more than
# a chat: OpenCode is a whole coding agent, it takes any OpenAI-shaped
# endpoint as a provider, and it runs inside the picture like the cloud
# agents do.  So ⏎ on a model opens OpenCode in the glass with that model
# as its default, in the folder the cabinet was opened from.
#
# EVERY LOCAL MODEL IS IN THE CONFIG IT IS HANDED, not just the one under
# the cursor.  OpenCode reads a config file named in OPENCODE_CONFIG as one
# more layer over the reader's own (~/.config/opencode is neither written
# nor read differently), so the cabinet writes one of its own beside the
# house token every time it opens OpenCode: a provider per runner that is
# up -- ollama's /v1 endpoint with every model it holds, llama-server's
# with the file it was started on -- and the chosen one as the default.
# Inside OpenCode, /models then lists every model this page lists, and the
# one that was pressed is already selected.  A model pulled into ollama is
# `ollama/<name>`; a .gguf llama-server holds is `llamacpp/<its id>`.
in_oc_config() {   # in_oc_config PROV/MODEL -> IOCF, the file
  local d="${XDG_STATE_HOME:-$HOME/.local/state}/alien" json='' models='' nm
  local -i i n=0
  IOCF=''
  mkdir -p "$d" 2>/dev/null || return 1
  json='{"$schema":"https://opencode.ai/config.json","provider":{'
  if (( ${IR[0.up]:-0} )); then
    models=''
    for (( i = 0; i < ${#IM_OL_NAME[@]}; i++ )); do
      [[ "${IM_OL_WHERE[$i]:-ollama}" == ollama ]] || continue   # a file on disk is llama.cpp's
      in_json_esc "${IM_OL_NAME[$i]}"
      models+="${models:+,}\"$IJE\":{\"name\":\"$IJE\"}"
    done
    json+='"ollama":{"npm":"@ai-sdk/openai-compatible","name":"Ollama (local)",'
    json+='"options":{"baseURL":"http://127.0.0.1:'"${IN_RPORT[0]}"'/v1"},"models":{'"$models"'}}'
    (( n++ ))
  fi
  if (( ${IR[1.up]:-0} )); then
    nm="${IR[1.served]%% · *}"
    [[ -n "$nm" ]] || nm='default'
    in_json_esc "$nm"
    (( n )) && json+=','
    json+='"llamacpp":{"npm":"@ai-sdk/openai-compatible","name":"llama.cpp (local)",'
    json+='"options":{"baseURL":"http://127.0.0.1:'"${IN_RPORT[1]}"'/v1"},"models":{"'"$IJE"'":{"name":"'"$IJE"'"}}}'
    (( n++ ))
  fi
  if (( ${IR[3.up]:-0} )); then
    models=''
    for (( i = 0; i < ${#IM_OL_NAME[@]}; i++ )); do
      [[ "${IM_OL_WHERE[$i]:-}" == mlx ]] || continue
      in_json_esc "${IM_OL_NAME[$i]}"
      models+="${models:+,}\"$IJE\":{\"name\":\"$IJE\"}"
    done
    (( n )) && json+=','
    json+='"mlx":{"npm":"@ai-sdk/openai-compatible","name":"MLX (local)",'
    json+='"options":{"baseURL":"http://127.0.0.1:'"${IN_RPORT[3]}"'/v1"},"models":{'"$models"'}}'
    (( n++ ))
  fi
  in_json_esc "$1"
  json+='},"agent":{"chat":{"description":"chat, no tools","mode":"primary","tools":{"write":false,"edit":false,"patch":false,"bash":false,"read":false,"grep":false,"glob":false,"list":false,"webfetch":false,"todowrite":false,"todoread":false},"permission":{"edit":"deny","bash":"deny","webfetch":"deny"}}},"model":"'"$IJE"'"}'
  print -r -- "$json" > "$d/opencode.json" 2>/dev/null || return 1
  chmod 600 "$d/opencode.json" 2>/dev/null
  IOCF="$d/opencode.json"
  return 0
}
in_oc_line() {   # in_oc_line MODEL WHERE -> IOCL the command · IOCM provider/model
  local m="$1" where="$2" prov id
  IOCL=''; IOCM=''
  [[ -n "$IOC_PATH" ]] || return 1
  case "$where" in
    ollama) prov=ollama;   id="$m" ;;
    gguf)   prov=llamacpp; id="${IR[1.served]%% · *}"; [[ -n "$id" ]] || id='default' ;;
    mlx)    prov=mlx;      id="$m" ;;
    *)      return 1 ;;
  esac
  IOCM="$prov/$id"
  in_oc_config "$IOCM" || return 1
  IOCL="env OPENCODE_CONFIG=$(_sh "$IOCF") $(_sh "$IOC_PATH") --model $(_sh "$IOCM")"
  return 0
}
# TOO SMALL TO DRIVE AN AGENT · opencode hands the model a large agentic
# prompt -- tool schemas, a plan-mode reminder, the lot -- and a small model
# cannot hold it: instead of answering it parrots the prompt back, often as a
# broken tool call.  A code-completion model under about seven billion
# parameters is the usual culprit, and on this Mac their download is the tell
# -- a Q4 7B is around four gigabytes, so much under that is small.
in_model_small() {   # in_model_small NAME -> IMS · 1 if likely too small for opencode
  local sz='' m="$1"
  local -i j
  IMS=0
  for (( j = 0; j < IM_N; j++ )); do
    [[ "${IM_NAME[$j]}" == "$m" ]] && { sz="${IM_SIZE[$j]}"; break }
  done
  [[ -n "$sz" ]] || return 0
  [[ "$sz" == *MB || "$sz" == *KB ]] && { IMS=1; return 0 }
  if [[ "$sz" == (<->|<->.<->)' GB' ]]; then
    local -F g=0.0
    (( g = ${sz% GB}, 1 )) 2>/dev/null || return 0
    (( g < 4.0 )) && IMS=1
  fi
  return 0
}

in_local_run() {
  local m where
  (( IM_N > 0 )) || { say 'nothing on this disk to run · [I] installs one'; snd no; return 0 }
  (( IN_LSEL < IM_N )) || return 0
  m="${IM_NAME[$IN_LSEL]}"; where="${IM_WHERE[$IN_LSEL]}"
  [[ -n "$IOC_PATH" ]] || in_scan_opencode
  if [[ -z "$IOC_PATH" ]]; then
    say 'no opencode on this machine — INSTALL puts it in (brew install opencode)'; snd no; return 0
  fi
  case "$where" in
    ollama) (( ${IR[0.up]:-0} )) || { say 'ollama is not up — [⇥] then [S] starts it'; snd no; return 0 } ;;
    gguf)   (( ${IR[1.up]:-0} )) || { say "llama-server is not holding it — start it on ${m}.gguf first"; snd no; return 0 } ;;
    mlx)    (( ${IR[3.up]:-0} )) || { say 'mlx_lm.server is not up — [⇥] then [S] starts it'; snd no; return 0 } ;;
    *)      say "$m · nothing here can run that"; snd no; return 0 ;;
  esac
  # AN EMBEDDING MODEL CANNOT CHAT AT ALL, so ⏎ does not open opencode on it --
  # there is nothing for opencode to talk to.  It is the one verdict that
  # refuses rather than warns.
  in_model_verdict "$m"
  [[ "$IMV" == embed ]] && { say 'an embedding model · it cannot chat · ⎋'; snd no; return 0 }
  in_oc_line "$m" "$where" || { say 'opencode could not be given that model'; snd no; return 0 }
  in_oc_bad
  (( IOCB )) && { say "opencode $IOC_VER · every prompt fails upstream"; snd no; }
  in_short "$PWD"
  # ONE SESSION PER MODEL, so ⏎ on the same model steps back into the one
  # already running and ⏎ on another opens another beside it
  if in_sh_open "oc:$m" OPENCODE "$IOCL" "$PWD" "$m"; then
    [[ "$IN_VIEW" == shell ]] && ! (( GT_BACK )) && {
      in_log_add open OPENCODE "$IOCM · in the glass, in $SHT" 1 0
      # SAID LAST SO IT STANDS · a model that cannot really drive opencode
      # makes it echo its own prompt, which reads like a cabinet fault and is
      # not one.  A chat-only model has no tools; a tiny one is too small.
      case "$IMV" in
        notools) say 'no tools for opencode · try [1] chat here' ;;
        small)   say 'too small for opencode · use a 7B+ model' ;;
        *)       snd coin ;;
      esac
    }
    return 0
  fi
  return 1
}

# [S] STARTS A RUNNER, AND A RUNNER IS NOT A JOB.  `ollama serve` does not
# finish -- it serves until it is stopped -- so putting it in the strip would
# leave a progress panel running for the rest of the session with nothing to
# report.  It gets a tab, the same way an agent does.
in_runner_start() {   # in_runner_start I
  local -i i=$1
  local cmd
  if (( ${IR[$i.up]:-0} )); then
    say "${IN_RNAME[$i]} · already up on ${IN_RPORT[$i]}"; snd move; return 0
  fi
  if (( ! ${IR[$i.here]:-0} )); then
    say "${IN_RNAME[$i]} · not on this machine · ${IN_RGET[$i]}"; snd no; return 0
  fi
  if ! have_osa || ! window_id; then
    say "${IN_RNAME[$i]} · run ${IN_RSTART[$i]} in a terminal"; snd no; return 0
  fi
  cmd="cd $(_sh "$PWD") && exec ${IN_RSTART[$i]}"
  # `count|kind`, NOT A BARE COUNT.  This read `[[ "$OSA_OUT" == <-> ]]` after
  # the script started answering `1|tab`, so a runner that started perfectly
  # was reported as refused and the reader was sent to type the command out by
  # hand -- a lie told by a test that was right the day before.
  in_mytty
  # THE SAME FLAG.  A runner's tab is as fresh a shell as an agent's.
  (( ${+functions[suite_dealing]} )) && suite_dealing 8
  OSA_KIND=''
  if osa_run "$AS_OPEN_SUITE" "$WINID" "$ITT" "$cmd" "${IN_RNAME[$i]}" \
     && [[ "${OSA_OUT%%|*}" == <-> ]] && (( ${OSA_OUT%%|*} > 0 )); then
    OSA_KIND="${OSA_OUT#*|}"
    (( ${+functions[scr_drain]} )) && scr_drain
    if [[ "$OSA_KIND" == tab ]]; then
      in_log_add start "${IN_RNAME[$i]}" "${IN_RSTART[$i]}" 1 0
      say "${IN_RNAME[$i]} · dealt a tab"
    else
      in_log_add start "${IN_RNAME[$i]}" "${IN_RSTART[$i]} · a window" 1 0
      say "${IN_RNAME[$i]} · a new window"
    fi
    snd coin; return 0
  fi
  (( ${+functions[scr_drain]} )) && scr_drain
  say "${IN_RNAME[$i]} · the window would not take a tab"; snd no
  return 0
}

in_spaced() { local s="$1" o='' i; for (( i = 0; i < ${#s}; i++ )); do
                o+="${o:+ }${s[$i,$i]}"; done; ISP="$o" }

intel_dress() {
  local -i i
  IN_OPENED=1                         # its own way out is intel_leave from here on
  SURF_MODEL="$IN_MODEL"
  in_spaced "$PACK_NAME"; SURF_SIGN="◂ $ISP ▸"
  SURF_TAG="ALIEN DYNAMICS · MODEL $IN_MODEL"
  local out=''
  for (( i = 0; i < IN_PAGES; i++ )); do
    out+="${out:+   }[${IN_PK[$i]}]${IN_PN[$i]}"
  done
  SURF_KEYS="[◂▸]PAGE   [▲▼]ROW   $out   [⎋]BACK"
  (( ${SURF_TITLE:-0} )) && SURF_KEYS="${TC_KEYS:-$SURF_KEYS}"
  in_badge
  SURF_MSG='FOUR COMMAND LINES · ONE GLASS'
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE GLASS TERMINAL · which is the cabinet's now
# ══════════════════════════════════════════════════════════════════════════
# Everything that ran an agent INSIDE the picture -- the terminal written
# out in zsh, the pty, the keyboard while the agent has it, the paint --
# was this file's, and it is terminal.command's SECTION 18b now: the door
# wanted a plain shell on the same glass, and one emulator has one owner.
# What stays here is what is this machine's about it: which page it turns
# to when an agent takes the keyboard and which when it gives it back, and
# the words on the coin door.  The store (gt_*) keeps every session, the
# door's shell included, and the cabinet pumps them all every frame.
in_sh_live()  { gt_live "$@" }
in_sh_close() { gt_close "$@" }
in_sh_all_stop() { gt_all_stop }
in_sh_raw()   { gt_raw "$@" }

# THROUGH THE RASTER, like every other change of surface on this machine.
# THE PAGE THE SESSION WAS OPENED FROM IS THE PAGE IT COMES BACK TO.  An
# agent is opened from the CLOUD roster and OpenCode from a LOCAL model; a
# reader who detaches from either should land where they pressed ⏎, not on
# whichever page happened to be first.
typeset -g IN_SH_FROM='cloud'
in_sh_attach() {   # in_sh_attach KEY
  gt_attach "$1"
  IN_GATE=0; IN_TALK=0; IN_PICK_OPEN=0; RW_PK_OPEN=0; RW_MTYPE=0; modal_reset
  [[ "$IN_VIEW" == shell ]] || IN_SH_FROM="$IN_VIEW"
  in_go_view shell
  return 0
}
in_sh_detach() {
  [[ -n "$GT_AT" ]] || return 0
  gt_detach
  [[ "$IN_VIEW" == shell ]] && in_go_view "${IN_SH_FROM:-cloud}"
  return 0
}
# A SESSION THE READER HAS FINISHED READING: forget it, and come back.
in_sh_done() {
  gt_done
  [[ "$IN_VIEW" == shell ]] && in_go_view "${IN_SH_FROM:-cloud}"
  return 0
}
in_sh_open() {   # in_sh_open KEY NAME CMD CWD NOTE
  local nm="$2"
  if ! gt_open "$@"; then
    in_ell "$SS_ERR" 40
    say "it would not start: $ELL"
    snd no
    return 1
  fi
  IN_GATE=0; IN_TALK=0; IN_PICK_OPEN=0; RW_PK_OPEN=0; RW_MTYPE=0; modal_reset
  [[ "$IN_VIEW" == shell ]] || IN_SH_FROM="$IN_VIEW"
  in_go_view shell
  if (( GT_BACK )); then say "back in ${nm:l}"; snd move; fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE AGENT'S OWN TERMINAL, PAINTED ONTO THE GLASS
# ══════════════════════════════════════════════════════════════════════════
# The cabinet paints it (gt_draw_shell); this page only has to know what to
# show when there is no session on the keyboard, which is the roster.
in_draw_shell() {   # in_draw_shell T
  [[ -n "$GT_AT" ]] || { in_draw_cloud; return 0 }
  gt_draw_shell $1
  return 0
}
