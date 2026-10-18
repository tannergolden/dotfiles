#!/usr/bin/env zsh
#==============================================================================
#
#   T E R M I N A L        the way into the ALIEN suite
#   (c) ALIEN DYNAMICS 1984  ·  model AD-1 "SYNTHWAVE"
#
#   Double-click this file to power it up.  A cabinet comes on, filling the
#   window, and on its glass is every machine in this suite and what each one
#   is doing right now.  Make the window bigger and the machine floats centred
#   with the night dealt around it.
#
#   ── WHAT CHANGED, AND WHY ──────────────────────────────────────────────
#   The old TERMINAL borrowed its cabinet.  chassis.zsh drew the walls, the neon,
#   the bezel, the coin door and both power sequences; theme, worlds, exit,
#   nav, sound, sky and save drew or decided the rest; vanity.py lit the
#   visitor and the sky over him.  Nine files had to be present and readable
#   before TERMINAL could say a word, and the first thing a fresh Mac gets
#   from a repo it has not installed yet is a machine that cannot open it.
#
#   THIS ONE IS ONE FILE.  Everything the nine did that this surface actually
#   uses is in here, in the order it is used, and nothing is sourced: a
#   terminal.command copied out on its own, dropped on a desktop, or run out
#   of a half-cloned repo still comes up, still reads the machine, and still
#   knows how to install the rest.  TERMINAL is the one thing in the suite
#   that has to work before the suite does.
#
#   AND IT IS THE ARCADE'S MACHINE NOW.  scripts/suite/arcade.py is where this
#   house keeps its best drawing -- the marquee with its chase lights and its
#   lit block name, the neon tubes up both walls, the bezel silk-screen, the
#   CRT that dims and rolls and flickers, the starfield outside, the streak
#   that crosses it, the phosphor dot that opens and closes the picture, the
#   selected row that lights from its own left edge.  TERMINAL drew a quieter
#   version of half of that and none of the rest.  So the cabinet here is the
#   arcade's, ported term for term into zsh: the same row map, the same
#   palette, the same waves, the same halo kernel, the same vignette depths,
#   the same 256-colour lift.  The marquee is where TERMINAL's own name went;
#   the glass underneath it is TERMINAL's business and nobody else's.
#
#   IT IS STILL ZSH, AND THAT IS STILL THE POINT.  It was a bash launcher
#   around a python payload once, and on a Mac with no command line tools that
#   meant a TERMINAL that printed "needs a working python3" and stopped -- before
#   INSTALL, the one thing that would have fixed it, could be reached.  zsh is
#   what macOS ships.
#
#   WHAT IT CANNOT DRAW, IT CARRIES.  The visitor and the sun and moon over
#   him are lit sprites: a grid of materials, one key light, a downsample to
#   whole cells.  None of that is done here -- the CARDS vanity.py composed
#   are carried in this file, cell for cell, folded on the one axis they
#   repeat along (he is alive in his eyes and nowhere else, so the head is
#   stored once and the eyes as bands).  Same visitor, same light, no python3
#   anywhere in the path.  DRESSED, he is the ARCADE's to compose: its
#   wardrobe is that same pipeline ported to zsh, so the door borrows it --
#   read from the arcade's own file the first time he has something on --
#   rather than carrying a second one to keep in step.
#
#   THE ROSTER IS THE MACHINES, one row each on the readout:
#     SYSTEM        the machine at once -- scope, tapes, gauges
#     INTELLIGENCE  agents, models, and the prompt library
#     XENOGOTCHI    the adoption centre -- one animal, one room
#     ARCADE        twelve cabinets, one coin a game
#
#   ...and the MENU is what TERMINAL DOES, which is not the same list:
#     not installed     [N] INSTALL    [R] RESCAN
#     installed         [T] TERMINAL   [E] RESET   [R] RESCAN
#   and [Q] the way out.  [V] steps aside to the VISITOR's own page: him in
#   whatever the arcade has put on him, and a line to talk to him on, answered
#   by a model running on this Mac and by nothing that leaves it.
#
#   FLAGS
#     --once     paint one frame and exit       --fast   the card, no ceremony
#     --probe    what it found, as text         --256    force the xterm palette
#     --plain    no colour at all               --check  glyph test card
#     --sharp    the sprites as ink, not ground --fps N  pin the rate
#     --back     skip the power-up              --true   24-bit even on Terminal
#
#   ── THE SEAMS ──  Every one of them is for a harness, and every one of them
#   is off unless something sets it.  TERMINAL_MOCK=1 reads a FIXTURE instead
#   of this machine -- the same suite, mirror, host and night on any machine,
#   on any day -- so the pictures in the repo are reproducible and leak
#   nothing.  ALIEN_AT=<seconds> puts a CEILING on the animation clock: it
#   runs the way it always does and then stops at that instant and holds, so a
#   captured frame is the same frame on a slow machine and a fast one.
#   ALIEN_OSASCRIPT names a stand-in for osascript, which is how a container
#   with no Terminal.app can be shown dealing tabs.  ALIEN_MIRROR=<n>/<m>
#   stands in for the reader's own ~, which is the one fact a fixture in a
#   repo cannot carry and the one that decides which menu is standing.
#
#==============================================================================
emulate -L zsh
setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH
set -u
zmodload zsh/datetime 2>/dev/null || true
zmodload zsh/mathfunc 2>/dev/null || true

# ── WHERE THE SUITE IS ──────────────────────────────────────────────────────
# From this file's OWN resolved path, never from the working directory and
# never from an environment that may be another checkout's.  %x is the file
# this line is in and :A follows the link into the repo, which is the same
# answer ~/.local/bin/alien works from and for the same reason: the file is
# the one true statement of where the repo is.
SELF="${${(%):-%x}:A}"
REPO="${SELF:h}"
export ALIEN_REPO="$REPO"
ALIEN_DOOR=""; [[ -r "$SELF" ]] && ALIEN_DOOR="$SELF"
export ALIEN_DOOR

# ── THE FIXTURE, AND THE CLOCK THAT STOPS ───────────────────────────────────
MOCK=0; [[ -n "${TERMINAL_MOCK:-}" ]] && MOCK=1
# TERMINAL's own night, the one the previews are taken on · 2026-08-23, 23:48
MOCK_NOW=1787528880
FROZEN=''; [[ "${ALIEN_AT:-}" == (<->|<->.<->) ]] && FROZEN="$ALIEN_AT"

# ── ARGUMENTS ───────────────────────────────────────────────────────────────
OPT_ONCE=0 OPT_FAST=0 OPT_BACK=0 OPT_256=0 OPT_TRUE=0 OPT_PLAIN=0
OPT_PROBE=0 OPT_CHECK=0 OPT_SHARP=0 OPT_FPS=0
# CONFIG's OWN TWO, the settings no command-line flag already carries.  They
# sit here with the flags because terminal.conf sets them at power-up the same
# way an argument would (cfg_load, SECTION 18d), and a reader changes them on
# the CONFIG page by hand.
CFG_SOUND=1                          # sound: 1 heard 0 silent · the tube stays 24-bit
CFG_FILL=0                           # 0 the cabinet floats · 1 the glass fills the terminal (SCREEN, 18d)
# BOOT IS NOT --fast.  It used to set the flag's own variable, and --fast is
# the harness's `paint one card and leave` -- so a reader who chose BOOT FAST
# on the CONFIG page got a TERMINAL that drew one frame and exited on every
# launch after, with no page left to change it back on.  FAST means what the
# page says it means: skip the ceremony and open on the menu.
CFG_BOOT_FAST=0                      # boot: 0 the whole opening · 1 straight to the menu (BOOT, 18d)
_argv=("$@")
_i=0
while (( _i < ${#_argv[@]} )); do
  case "${_argv[$_i]}" in
    --once)  OPT_ONCE=1 ;;
    --fast)  OPT_FAST=1 ;;
    --back)  OPT_BACK=1 ;;
    --256)   OPT_256=1 ;;
    --true)  OPT_TRUE=1 ;;
    --plain) OPT_PLAIN=1 ;;
    --probe) OPT_PROBE=1 ;;
    --check) OPT_CHECK=1 ;;
    --sharp) OPT_SHARP=1 ;;
    --fps)   (( _i++ )); OPT_FPS="${_argv[$_i]:-0}" ;;
  esac
  (( _i++ ))
done
unset _argv _i
[[ "$OPT_FPS" == <-> ]] || OPT_FPS=0
(( OPT_FPS && OPT_FPS < 4 )) && OPT_FPS=4
(( OPT_FPS > 144 )) && OPT_FPS=144
# NOTHING TO READ KEYS FROM MEANS NOTHING CAN EVER QUIT: the loop would spin
# until it was killed.  One frame and out is the only sane thing to do.
[[ -t 0 && -t 1 ]] || OPT_ONCE=1
# ...and a redirected run has nobody to show colour to
[[ -t 1 ]] || OPT_PLAIN=1
[[ -n "${NO_COLOR:-}" ]] && OPT_PLAIN=1

# ── THE SHELL HAS TO COUNT CHARACTERS, NOT BYTES ───────────────────────────
# EVERY MEASUREMENT IN THIS FILE IS A CHARACTER COUNT: how wide a rule is,
# where a right-aligned reading starts, how many cells a box takes.  A `─` is
# three bytes, and a shell whose LC_CTYPE is not a multibyte locale answers
# three to `${#}` -- so every rule overshoots, every box leans, and the
# machine draws as a heap.  Terminal.app sets a UTF-8 locale by default and
# the old TERMINAL simply relied on that; a reader who turned that setting off,
# or an ssh session that carried a locale the far end does not have, got the
# heap and no explanation.
#
# So it is TESTED, and fixed if it can be.  macOS carries a bare `UTF-8`
# locale alias precisely for this, and zsh re-reads the locale the moment
# LC_CTYPE is assigned -- so one of these four takes, or none do and --check
# is where it says so.
_mb_ok() { local g='─'; (( ${#g} == 1 )) }
if ! _mb_ok; then
  for _loc in "${LC_ALL:-}" "${LANG:-}" en_US.UTF-8 UTF-8 C.UTF-8; do
    [[ -n "$_loc" ]] || continue
    [[ "$_loc" == *[Uu][Tt][Ff]* ]] || continue
    export LC_CTYPE="$_loc"
    _mb_ok && break
  done
fi
MB_OK=0; _mb_ok && MB_OK=1

IS_MAC=0
[[ "$OSTYPE" == darwin* ]] && IS_MAC=1
(( MOCK )) && IS_MAC=1

# TRUE24 · what this terminal can be given.  Terminal.app gets the xterm
# palette unless it says COLORTERM (Tahoe's does); every other terminal gets
# 24-bit.  The same rule, in the same words, as arcade.py's _TRUECOLOR and as
# every other cabinet in the suite.
TRUE24=1
[[ "${TERM_PROGRAM:-}" == Apple_Terminal && -z "${COLORTERM:-}" ]] && TRUE24=0
(( OPT_256 )) && TRUE24=0
(( OPT_TRUE )) && TRUE24=1

# term_now — TERMINAL's clock, which the fixture stops
term_now() { (( MOCK )) && print -r -- $MOCK_NOW || print -r -- $EPOCHSECONDS; }
# ...and the same clock read into NOW without a subshell -- it is asked for on
# every frame, and a command substitution is a fork.
term_now_set() { (( MOCK )) && NOW=$MOCK_NOW || NOW=$EPOCHSECONDS; return 0 }
# WHAT THE GLASS IS A PICTURE OF, counted.  Declared here, at the top, because
# the probe bumps it and the probe runs before the section that explains it.
GLASS_GEN=0
# THE ANIMATION CLOCK IS A PARAMETER, NOT A FUNCTION.  It was `$(mono)`, and
# a command substitution is a FORK -- five of them a frame, half a
# millisecond each, fed straight into the governor that then steps the
# machine down a rung to pay for them.  zsh/datetime puts the same number in
# $EPOCHREALTIME for nothing, so that is what is read.

# ══════════════════════════════════════════════════════════════════════════
# SECTION 1 · COLOUR              arcade.py's section 2, carried whole
# ══════════════════════════════════════════════════════════════════════════
# A COLOUR IS ONE INTEGER HERE, and that is the whole performance story of
# this file.  The old TERMINAL kept three parallel channel arrays a cell and
# spent six subscripts comparing two cells; the arcade keeps a tuple, which
# Python hashes for free and zsh has no equivalent of.  So a colour is
# (r << 16) | (g << 8) | b -- one array element, one comparison, one
# associative key for the escape sequence it turns into.  Every channel is
# already quantised to a multiple of four before it is packed, which is what
# makes the pack lossless and the cache small.
#
#   -1  as an INK   · nothing was written in this cell
#   -1  as a GROUND · the void, which is SGR 49 and means "the terminal's
#                     own background".  Outside the cabinet is not a colour
#                     at the reader's word: a black rectangle on a terminal
#                     set to warm grey is a rectangle sitting on somebody's
#                     desktop.  arcade.py's VOID, exactly.
VOID=-1

# _q V — clamp, then mask.  Masking a value over 255 wraps it modulo 256
# (267 & 0xFC == 8), which turns an over-bright highlight into a dark colour
# instead of saturating toward white.  The arcade found that one the hard way
# and says so at its own q(); it is repeated here because the bug is the same
# bug in any language.
_pack() { PK=$(( ((($1 < 0 ? 0 : ($1 > 255 ? 252 : $1)) & 0xFC) << 16) \
               | ((($2 < 0 ? 0 : ($2 > 255 ? 252 : $2)) & 0xFC) << 8) \
               |  (($3 < 0 ? 0 : ($3 > 255 ? 252 : $3)) & 0xFC) )) }

# cmix A B T -> CM · blend two packed colours.  t=0 is A, t=1 is B.
cmix() {
  local -i a=$1 b=$2
  local -F t=$3
  (( t < 0.0 )) && t=0.0
  (( t > 1.0 )) && t=1.0
  local -i ar=$(( (a >> 16) & 255 )) ag=$(( (a >> 8) & 255 )) ab=$(( a & 255 ))
  CM=$(( ((int(ar + ((((b >> 16) & 255) - ar) * t)) & 0xFC) << 16) \
       | ((int(ag + ((((b >>  8) & 255) - ag) * t)) & 0xFC) <<  8) \
       |  (int(ab + (((b & 255) - ab) * t)) & 0xFC) ))
}

# cshade C F -> CS · scale brightness.  f may be over one, which is why every
# channel is clamped on the way back in.
cshade() {
  local -i c=$1
  local -F f=$2
  local -i r=$(( int(((c >> 16) & 255) * f) )) \
           g=$(( int(((c >>  8) & 255) * f) )) \
           b=$(( int((c & 255) * f) ))
  (( r < 0 )) && r=0; (( r > 255 )) && r=252
  (( g < 0 )) && g=0; (( g > 255 )) && g=252
  (( b < 0 )) && b=0; (( b > 255 )) && b=252
  CS=$(( ((r & 0xFC) << 16) | ((g & 0xFC) << 8) | (b & 0xFC) ))
}

# ── the xterm-256 quantiser ─────────────────────────────────────────────────
# Terminal.app is 256-colour only, and the cube's darkest non-zero level is 95
# -- a huge jump from black.  Naive quantisation turns this suite's dark
# saturated purples into vivid navy.  So: LIFT the darks with a gamma curve
# first, then pick the nearest entry with a perceptually weighted distance.
# Both halves are the arcade's.
#
# WHAT IS NOT THE ARCADE'S is the search.  It walks all two hundred and forty
# palette entries per colour, which in Python is a millisecond and in zsh is a
# tenth of a second -- five hundred distinct colours in a frame would be a
# frame that took a minute.  The cube is a PRODUCT of three independent
# ladders, so the nearest cube entry is the nearest level on each channel
# taken separately; the grey ramp is the only entry that can beat it, and
# there is exactly one grey worth testing.  Two candidates, weighed the
# arcade's way, and the answer agrees with the full search on everything this
# file actually paints.
typeset -ga LIFT
_lift_init() {
  local -i v
  local -F x
  for (( v = 0; v < 256; v++ )); do
    x=$(( (v / 255.0) ** 0.80 ))
    LIFT[$v]=$(( int(255.0 * x + 0.5) ))
  done
}
CUBE=(0 95 135 175 215 255)
_lvl() {   # _lvl V -> LV LI · the nearest cube level, ties to the lower
  local -i v=$1
  if   (( v <   48 )); then LI=0
  elif (( v <= 115 )); then LI=1
  elif (( v <= 155 )); then LI=2
  elif (( v <= 195 )); then LI=3
  elif (( v <= 235 )); then LI=4
  else                      LI=5; fi
  LV=${CUBE[$LI]}
}
_to256() {   # _to256 R G B -> TO256 · no subshell: Terminal.app is 256-colour
             # and this ran once per new colour, as a fork, on the wire
  local -i r=$1 g=$2 b=$3 mx
  mx=$r; (( g > mx )) && mx=$g; (( b > mx )) && mx=$b
  if (( mx > 20 )); then
    local -F k=1.0
    (( mx < 80 )) && k=$(( (mx - 20) / 60.0 ))
    r=$(( int(r + (LIFT[$r] - r) * k) ))
    g=$(( int(g + (LIFT[$g] - g) * k) ))
    b=$(( int(b + (LIFT[$b] - b) * k) ))
  fi
  local -i ri gi bi rv gv bv dr dg db best idx
  _lvl $r; ri=$LI; rv=$LV
  _lvl $g; gi=$LI; gv=$LV
  _lvl $b; bi=$LI; bv=$LV
  dr=$(( r - rv )); dg=$(( g - gv )); db=$(( b - bv ))
  best=$(( 2 * dr * dr + 4 * dg * dg + 3 * db * db ))
  idx=$(( 16 + ri * 36 + gi * 6 + bi ))
  # ...and the greys.  Under this metric the best grey is the WEIGHTED mean,
  # not the plain one -- (2r + 4g + 3b) / 9 -- and the ramp is coarse enough
  # that its two neighbours can still win, so four steps are asked and the
  # cube keeps every tie, which is what walking the palette in index order
  # with a strict `<` does in the file this is ported from.
  local -i m=$(( (2 * r + 4 * g + 3 * b) / 9 )) g0 gk gv3 d
  g0=$(( (m - 8) / 10 ))
  for (( gk = g0 - 1; gk <= g0 + 2; gk++ )); do
    (( gk < 0 || gk > 23 )) && continue
    gv3=$(( 8 + gk * 10 ))
    dr=$(( r - gv3 )); dg=$(( g - gv3 )); db=$(( b - gv3 ))
    d=$(( 2 * dr * dr + 4 * dg * dg + 3 * db * db ))
    (( d < best )) && { best=$d; idx=$(( 232 + gk )) }
  done
  TO256=$idx
}

# ── the escape a colour turns into, worked out once ─────────────────────────
# Three thousand cells share a few hundred colours between them, and turning
# a packed integer into an SGR string is the same answer every time.
typeset -gA SGF SGB
typeset -gi SGF_N=0 SGB_N=0 REPC_N=0 PTC_N=0
# THE CACHES ARE COUNTED BY HAND.  `${#assoc[@]}` walks the whole table --
# eight hundred microseconds at twenty thousand entries -- and it was asked
# on every miss, which on a machine whose neon puts a hundred and fifty new
# colours a frame through here grew into most of the frame by the evening.
sgf() {   # sgf PACKED -> SF
  # -1 IS NO INK AT ALL, and it has to be caught here as well as in the
  # renderer: `(-1 >> 16) & 255` is 255 on every channel, so an unguarded
  # miss turns the one value that means "nothing was written" into pure
  # white -- and then CACHES it over the deliberate empty entry, because an
  # empty cache value is indistinguishable from a miss.
  if (( $1 < 0 )); then SF=''; return 0; fi
  SF="${SGF[$1]:-}"
  [[ -n "$SF" ]] && return 0
  local -i c=$1
  if (( TRUE24 )); then
    SF=$'\033[38;2;'$(( (c >> 16) & 255 ))';'$(( (c >> 8) & 255 ))';'$(( c & 255 ))'m'
  else
    _to256 $(( (c >> 16) & 255 )) $(( (c >> 8) & 255 )) $(( c & 255 ))
    SF=$'\033[38;5;'"$TO256"'m'
  fi
  # BOUNDED, because the dim path stopped masking.  Every colour this file
  # MIXES is a multiple of four on each channel, which keeps the space small;
  # a dimmed one is any integer at all, so a machine left up all night could
  # otherwise put a few hundred thousand escape sequences in here.  arcade.py
  # caps its two caches at twenty-four thousand for the same reason.
  (( SGF_N++ > 24000 )) && { SGF=(); SGF_N=0 }
  SGF[$1]="$SF"
}
sgb() {   # sgb PACKED -> SB · the void hands the cell back to the terminal
  if (( $1 < 0 )); then SB=$'\033[49m'; return 0; fi
  SB="${SGB[$1]:-}"
  [[ -n "$SB" ]] && return 0
  local -i c=$1
  if (( TRUE24 )); then
    SB=$'\033[48;2;'$(( (c >> 16) & 255 ))';'$(( (c >> 8) & 255 ))';'$(( c & 255 ))'m'
  else
    _to256 $(( (c >> 16) & 255 )) $(( (c >> 8) & 255 )) $(( c & 255 ))
    SB=$'\033[48;5;'"$TO256"'m'
  fi
  if (( SGB_N++ > 24000 )); then
    # THE VOID'S OWN ENTRY IS NOT A CACHED COLOUR, it is the one value the
    # renderer looks up by hand every frame -- so it goes straight back in.
    SGB=(); SGB[-1]=$'\033[49m'; SGB_N=0
    (( OPT_PLAIN )) && SGB[-1]=''
  fi
  SGB[$1]="$SB"
}

# ── the synthwave palette · arcade.py's, number for number ──────────────────
_pack   4   2  10; BLACK=$PK
_pack   0   0   0; VOID_MIX=$PK        # you cannot mix a colour with an absence
_pack  26  12  46; ARC_DARK=$PK        # arcade body shadow
_pack  44  20  74; ARC_BODY=$PK        # arcade body
_pack  72  34 118; ARC_LIT=$PK         # arcade highlight
_pack  20  10  36; BEZEL=$PK
_pack   8   4  20; GLASS=$PK           # CRT background
_pack 255  42 168; MAGENTA=$PK
_pack 255 108 200; PINK=$PK
_pack  60 240 255; CYAN=$PK
_pack  86 128 255; BLUE=$PK
_pack 168  78 255; PURPLE=$PK
_pack 255 186  62; AMBER=$PK
_pack  96 255 168; LIME=$PK
_pack 255  74  92; RED=$PK
_pack 238 232 255; WHITE=$PK
_pack 128 116 158; GREY=$PK
_pack  78  68 104; DIM=$PK
_pack  30  16  52; PLATE=$PK           # the control panel's own plate
_pack  22  11  40; DOORP=$PK           # the coin door's
_pack  10   5  22; WELL=$PK            # a sunken readout well

# under --plain there is no colour at all, and every ink is the terminal's own
if (( OPT_PLAIN )); then
  sgf() { SF=''; }
  sgb() { SB=''; }
fi

# ── the wave every lamp in this house breathes on ───────────────────────────
# arcade.py's _wave: 0.5 + 0.5 sin(t · speed · tau + phase).  Every pulse,
# glow, chase and shimmer in this file is one of these, which is why they all
# look like they belong to the same machine.
TAU=6.283185307179586
wave() { WV=$(( 0.5 + 0.5 * sin($1 * $2 * TAU + $3) )) }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 2 · GEOMETRY            the arcade's row map, one marquee taller
# ══════════════════════════════════════════════════════════════════════════
# EVERY NUMBER BELOW IS DERIVED, and the two that are not are the two the
# reader's window has to hold.  Line them up against arcade.py's own map and
# against the old TERMINAL's chassis and something worth saying falls out: the
# old cabinet IS this cabinet with the marquee cut off.  Its DIV1 is at 35,
# its panel at 36 and 37, its coin door at 39, its floor at 41 -- the same
# rows these land on, to the row, because both were cut from the same
# machine.  So the marquee slots into the nine rows TERMINAL never had, the
# glass keeps the width it always had, and a window that could hold the old
# TERMINAL can hold this one.
ARC_W=122; ARC_H=43                  # the whole machine
SCR_W=106; SCR_H=30                  # the glass inside it
# ── THE MARQUEE IS GONE, AND THE GLASS HAS ITS ROWS ────────────────────────
# It was nine rows: a crown, two strips of chase lights and five of the name
# in lit block letters -- arcade.py's own, and beautiful, and a fifth of the
# window spent saying a word the bezel and the coin door already say twice.
# On a cabinet you walk up to, the marquee is what you read from across the
# room and the glass is small because a game is small.  TERMINAL is the other
# way round: nobody is across the room, and what is on the glass is the whole
# point of opening it.
#
# So the body's top edge is row zero now and the glass is thirty rows instead
# of twenty-one -- half as much picture again, in exactly the same window.
# Line the rest of it up against the machine this was cut from and it is the
# old chassis to the row: screen at 3, bezel at 34, panel at 36 and 37, coin
# door at 39, floor at 41.  It was always this shape underneath.
R_ARC_TOP=0                          # the body's top edge
R_BEZ_TOP=1                          # bezel padding over the glass
R_SCR_TOP=2                          # the screen frame
R_SCR=3                              # the glass itself (3 .. 32)
R_SCR_BOT=$(( R_SCR + SCR_H ))       # 33
R_BEZ_BOT=$(( R_SCR_BOT + 1 ))       # 34
R_DIV1=$(( R_BEZ_BOT + 1 ))          # 35
R_PANEL_A=$(( R_DIV1 + 1 ))          # 36  the switches
R_PANEL_B=$(( R_PANEL_A + 1 ))       # 37  the key strip
R_DIV2=$(( R_PANEL_B + 1 ))          # 38
R_COIN=$(( R_DIV2 + 1 ))             # 39  the coin door
R_ARC_BOT=$(( R_COIN + 1 ))          # 40
R_FLOOR=$(( R_ARC_BOT + 1 ))         # 41  the spill on the floor
R_FOOT=$(( R_FLOOR + 1 ))            # 42
C_WALL_L=0; C_TUBE_L=1; C_IN_L=2
C_IN_R=$(( ARC_W - 3 ))              # 119
C_TUBE_R=$(( ARC_W - 2 ))            # 120
C_WALL_R=$(( ARC_W - 1 ))            # 121
IN_W=$(( C_IN_R - C_IN_L + 1 ))      # 118
C_SCR_BOX=$(( C_IN_L + (IN_W - (SCR_W + 2)) / 2 ))   # 7
C_SCR=$(( C_SCR_BOX + 1 ))                            # 8
# THE WINDOW THE OLD TERMINAL ASKED FOR, to the row.  arcade.py wants one row
# more than its machine is tall so the bottom-right cell cannot scroll the
# screen out from under it; this file turns AUTOWRAP OFF on the way in
# (scr_enter's ?7l), which is the same guarantee without the row -- so a
# window that could hold the old TERMINAL holds this one.
MIN_W=$ARC_W; MIN_H=$ARC_H

# ── the glass's own map · TERMINAL's business and nobody else's ─────────────
# THE ARCADE'S MENU IS TWO COLUMNS and so is this one: a list on the left, a
# panel on the right, a rule between them.  What is in the right-hand column
# is the difference between a cabinet that sells you a game and a TERMINAL that
# lets you into a house -- there it is a preview of the machine under the
# cursor, here it is the VISITOR, standing under whatever the sky is doing.
G_HEAD=0                             # the header band
G_DIV=104                            # the list's own right edge now, not a rule
G_LW=104                             # the list column, 0 .. 103
G_SUITE=2                            # the menu's box · top row
G_MACH=9                             # the readout's box · top row (was 8; nudged
                                     # down one when CONFIG became a fourth SUITE
                                     # row -- that box is S_N+2 tall, so one more
                                     # row would have put its floor on this box's
                                     # ceiling.  One down keeps the gap between
                                     # them and still clears the mirror below)
G_MIRROR=16                          # the mirror's gauge
G_SPEC=18                            # ...and the machine's own readings under it
# THE SAME DESIGN, STANDING IN A TALLER BOX.  Nothing above moved: the header
# is still the top row, the menu still sits under it, the readout still under
# that.  What the nine new rows buy is the FLOOR -- the rule and the key bar
# go to the bottom of the glass where they belong, and the visitor stands on
# it rather than a third of the way up, which is where he stood on the machine
# this was cut from.
G_RULE=28
G_HINT=29
G_CEL_X=93; G_CEL_Y=2                # what hangs over him · his own card's
                                     # top three rows are air, so it clears him
G_VIS_X=82; G_VIS_Y=18               # ...and where he stands, his own card's
                                     # three columns of headroom either side
                                     # already taken off
G_NAME_X=5; G_DESC_X=19; G_READ_R=102
# THIRTEEN, AND EVERY ONE OF THEM SPOKEN FOR.  INTELLIGENCE is twelve cells
# and used to set this on its own -- but a suite row spends four of them on
# its `[X] ` before the name starts, so the longest name a suite row could
# wear was eight, and UNINSTALL is nine.  It came out as `[U] UNINSTAL`: a
# menu misspelling the one row that undoes everything.
NAME_W=13
DESC_MAX=66                          # ...and what is left before the reading

# ── SCREEN=fill · the glass reflows to the whole window ─────────────────────
# The constants above are the cabinet's FIXED glass (106x30), hand-set for a
# machine that floats.  Fill mode keeps them as the baseline and, on every
# resize, recomputes the same layout for a glass the size of the whole
# terminal -- so every v_* painter already written fills the window without
# being touched.  geom_float puts the fixed glass back, exactly, from a copy
# taken here once; geom_fill stretches it.  Only the menu's own map moves; the
# cabinet's rows (R_SCR_TOP, R_COIN, ...) are the machine's and stay put.
typeset -gi GEOM_FILL=0
F_SCR_W=$SCR_W F_SCR_H=$SCR_H F_C_SCR=$C_SCR F_R_SCR=$R_SCR F_SCR_BOT=$R_SCR_BOT
F_G_DIV=$G_DIV F_G_LW=$G_LW F_G_READ_R=$G_READ_R F_G_DESC_X=$G_DESC_X F_DESC_MAX=$DESC_MAX
F_G_SUITE=$G_SUITE F_G_MACH=$G_MACH F_G_MIRROR=$G_MIRROR F_G_SPEC=$G_SPEC
F_G_RULE=$G_RULE F_G_HINT=$G_HINT
F_G_CEL_X=$G_CEL_X F_G_CEL_Y=$G_CEL_Y F_G_VIS_X=$G_VIS_X F_G_VIS_Y=$G_VIS_Y
geom_float() {   # the cabinet's fixed glass, put back cell-for-cell
  # the machine floats centred again · c_size's own sums, in case fill zeroed them
  OX=$(( (TCOLS - ARC_W) / 2 )); (( OX < 0 )) && OX=0
  OY=$(( (TROWS - ARC_H) / 2 )); (( OY < 0 )) && OY=0
  SCR_W=$F_SCR_W; SCR_H=$F_SCR_H; C_SCR=$F_C_SCR; R_SCR=$F_R_SCR; R_SCR_BOT=$F_SCR_BOT
  G_DIV=$F_G_DIV; G_LW=$F_G_LW; G_READ_R=$F_G_READ_R; G_DESC_X=$F_G_DESC_X; DESC_MAX=$F_DESC_MAX
  G_SUITE=$F_G_SUITE; G_MACH=$F_G_MACH; G_MIRROR=$F_G_MIRROR; G_SPEC=$F_G_SPEC
  G_RULE=$F_G_RULE; G_HINT=$F_G_HINT
  G_CEL_X=$F_G_CEL_X; G_CEL_Y=$F_G_CEL_Y; G_VIS_X=$F_G_VIS_X; G_VIS_Y=$F_G_VIS_Y
  GEOM_FILL=0
  return 0
}
geom_fill() {   # the same map, stretched to the whole terminal
  local -i gw gh sn mn
  sn=${S_N:-4}; mn=${M_N:-4}
  gw=$TCOLS; gh=$(( TROWS - 1 ))       # the glass IS the window · one row spared at the foot for keys
  (( gw < F_SCR_W )) && gw=$F_SCR_W
  (( gh < F_SCR_H )) && gh=$F_SCR_H
  OX=0; OY=0                           # the glass starts at the window's own corner
  SCR_W=$gw; SCR_H=$gh; C_SCR=0; R_SCR=0; R_SCR_BOT=$gh
  G_LW=$(( gw - 2 )); G_DIV=$G_LW              # the list fills the glass · the visitor has his own page now
  G_READ_R=$(( G_LW - 3 ))
  G_DESC_X=$F_G_DESC_X
  DESC_MAX=$(( G_READ_R - G_DESC_X - 17 )); (( DESC_MAX < 12 )) && DESC_MAX=12
  # vertical · the chooser rides the top and the host readout rides the foot, so
  # a tall glass reads as a cabinet -- controls up top, the machine's own figures
  # down at the bottom rail, the sky between them -- rather than one centred block
  # marooned in the middle with dust above and below it.  On a glass too short to
  # breathe, the stack keeps its old centred shape, since there the gap was small.
  local -i ch off
  ch=$(( sn + mn + 16 ))               # SUITE box + gap + MACHINES box + gap + mirror + specs
  if (( gh - 3 >= ch + 10 )); then     # room to breathe · anchor the two ends
    G_SUITE=3
    G_MACH=$(( G_SUITE + sn + 3 ))
    G_SPEC=$(( gh - 6 ))               # five spec rows, ending just above the key strip
    G_MIRROR=$(( G_SPEC - 2 ))
  else                                 # tight · keep the centred block
    off=$(( 2 + (gh - 3 - ch) / 2 )); (( off < 2 )) && off=2
    G_SUITE=$off
    G_MACH=$(( G_SUITE + sn + 3 ))
    G_MIRROR=$(( G_MACH + mn + 3 ))
    G_SPEC=$(( G_MIRROR + 2 ))
  fi
  G_RULE=$(( gh - 1 )); G_HINT=$(( gh - 1 ))
  # G_CEL_X / G_VIS_X are the visitor page's to set now · the menu draws neither
  GEOM_FILL=1
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 3 · THE CANVAS          arcade.py's section 3, in three arrays
# ══════════════════════════════════════════════════════════════════════════
# A grid of (glyph, ink, ground) that renders itself, and every painter in
# this file writes into it in whatever order suits it.  ONE pass at the end
# puts the tube over the glass and cuts the lot into runs.
#
#   GCH  the glyph
#   GF   the ink, packed · -2 is never stored, it is only ever an ARGUMENT
#   GB   the ground, packed · -1 is the void
#
# -2 AS AN ARGUMENT means "leave this one alone", which is arcade.py's `None`
# default on put/text/fill and is the whole reason the mark can be laid over
# its own bloom without knowing the bloom is there.
typeset -ga GCH GF GB BLK_CH BLK_F BLK_B
TCOLS=0; TROWS=0; GN=0
OX=0; OY=0                           # where the machine stands in the window
FITS=1

# ── a run of one value, without a loop ──────────────────────────────────────
# A text write sets one ink and one ground across every cell it touches, and
# zsh will replace a whole slice of an array in one C-level move if it is
# handed a list.  Building that list a value at a time costs more than the
# loop it replaces, so it is built by DOUBLING -- seven concatenations for a
# hundred and twenty cells -- and then kept, because the next frame asks for
# the same run of the same colour.
#
# KEPT AS AN ARRAY, UNDER A NAME OF ITS OWN.  It used to be kept as a string
# and split back into a list on every call, and the split was the cost: sixty
# microseconds a side on a long text, twice a text, two hundred texts a page
# -- a quarter of what a machine's page cost to draw was this one function
# undoing its own cache.  An array named for its length and its value goes
# into a slice in one move through ${(P)}, so a run asked for a second time
# costs a lookup and the move.  A few thousand runs are kept; past that the
# lot is let go and made again as it is asked for.
typeset -gA REPC
typeset -ga REPA REPN_L
typeset -gi REPN_N=0
typeset -g  REPN='' REPV=''
_repn() {   # _repn N VAL -> REPN · the NAME of an array holding N copies of VAL
            #                  REPV · that name with [@], for "${(@P)REPV}"
  # (KSH_ARRAYS: a bare name through (P) is element 0 alone · [@] is the lot)
  REPN="REP_${1}_${2//-/m}"; REPV="${REPN}[@]"
  [[ -n "${REPC[$REPN]:-}" ]] && return 0
  local -a a; a=("$2")
  while (( ${#a[@]} < $1 )); do a=("${a[@]}" "${a[@]}"); done
  # a value that is not a number cannot name an array · the list itself, then
  if [[ "$REPN" != REP_<->_(m|)<-> ]]; then REPA=("${(@)a[0,$(( $1 - 1 ))]}"); REPN=REPA; REPV='REPA[@]'; return 0; fi
  # A THOUSAND IS THE CEILING, and it is a ceiling on the shell's own table:
  # every one of these is a global parameter, and past a couple of thousand
  # of them every variable the machine touches is found a little more
  # slowly -- measured, a tenth of a frame.  A page keeps to a few hundred.
  if (( REPN_N >= 1000 )); then unset "${(@)REPN_L[@]}" 2>/dev/null; REPN_L=(); REPC=(); REPN_N=0; fi
  typeset -ga "$REPN"
  set -A "$REPN" -- "${(@)a[0,$(( $1 - 1 ))]}"   # -- · a value of -1 is not an option
  REPC[$REPN]=1; REPN_L+=("$REPN"); (( ++REPN_N ))
  return 0
}
_rep() {   # _rep N VAL -> REPA
  _repn $1 $2
  [[ "$REPN" == REPA ]] || REPA=("${(@P)REPV}")
  return 0
}

# THE WINDOW IS MEASURED TWICE A SECOND, not every frame.  stty is a fork,
# and a fork on every beat of a sixty-hertz machine is a millisecond or two
# of every frame spent asking a question whose answer changes once a session.
# A resize noticed within half a second is a resize noticed; a WINCH trap
# would notice it sooner and cannot be used -- zsh holds the trap while
# `read -k` is waiting on the keyboard, which on this machine is always.
typeset -F SIZE_AT=0.0
SIZE_EVERY=0.5
c_size() {   # c_size [FORCE] — measure the window, and rebuild the grid if it moved
  local -a wh
  if (( ! ${1:-0} )) && (( SIZE_AT > 0.0 && $EPOCHREALTIME - SIZE_AT < SIZE_EVERY )); then return 1; fi
  SIZE_AT=$EPOCHREALTIME
  wh=(${=$( { stty size </dev/tty; } 2>/dev/null )})
  local -i r=${wh[0]:-0} c=${wh[1]:-0}
  (( r )) || r=${LINES:-24}
  (( c )) || c=${COLUMNS:-80}
  (( r == TROWS && c == TCOLS )) && return 1
  TROWS=$r; TCOLS=$c; GN=$(( TCOLS * TROWS ))
  r_forget                             # a block's bytes were for the old grid
  OX=$(( (TCOLS - ARC_W) / 2 )); (( OX < 0 )) && OX=0
  OY=$(( (TROWS - ARC_H) / 2 )); (( OY < 0 )) && OY=0
  FITS=1
  (( TCOLS < MIN_W || TROWS < MIN_H )) && FITS=0
  # the blank grid, made once, copied per frame · an array copy of five
  # thousand cells is half a millisecond and the loop it replaces is twenty
  local -i i
  # CLEARED TO NO INK, ON PURPOSE -- the same clearing glass_base does, for
  # the same reason, and it took the stars going out to notice the outside of
  # the machine had never had it.  Three things say a cell is UNCLAIMED night
  # a star may sit in: no ground, no glyph, and no ink ever written.  The
  # third is the one that keeps a speck out of the SPACE BETWEEN TWO WORDS of
  # the footer, which is written on the void and answers the first two.  But
  # the blank grid was handing every cell $DIM as its ink -- a real colour,
  # invisible only because the glyph over it is a space -- so "no ink ever
  # written" was false EVERYWHERE and the night went dark: no sky over the
  # cabinet, and an overture that held a black window for three seconds.
  # Nothing else moves: an ink under a space is not drawn either way, and
  # every reader of GF already skips a negative one.
  BLK_CH=(); BLK_F=(); BLK_B=()
  for (( i = 0; i < GN; i++ )); do BLK_CH[$i]=' '; BLK_F[$i]=-1; BLK_B[$i]=$VOID; done
  GCH=("${BLK_CH[@]}"); GF=("${BLK_F[@]}"); GB=("${BLK_B[@]}")
  NBLK=$(( (TCOLS + BLK - 1) / BLK ))
  PSIG=(); PBSIG=()
  REPC=()
  return 0
}

c_clear() { GCH=("${BLK_CH[@]}"); GF=("${BLK_F[@]}"); GB=("${BLK_B[@]}") }

c_put() {   # c_put X Y GLYPH [FG] [BG]
  local -i x=$1 y=$2 k
  (( x < 0 || x >= TCOLS || y < 0 || y >= TROWS )) && return 0
  k=$(( y * TCOLS + x ))
  GCH[$k]="$3"
  # THE TESTS ARE NOT ONE TEST.  `(( $# >= 4 && $4 != -2 ))` expands $4 while
  # it builds the expression, before a single `&&` has been evaluated -- so
  # under `set -u` a three-argument call dies on an argument it was asking
  # whether it had.  Two arithmetic commands, and the shell only expands the
  # second one when it reaches it.
  (( $# >= 4 )) && (( ${4} != -2 )) && GF[$k]=$4
  (( $# >= 5 )) && (( ${5} != -2 )) && GB[$k]=$5
  return 0
}

c_tint() {  # c_tint X Y BG — a cell's ground, its glyph untouched
  local -i x=$1 y=$2
  (( x < 0 || x >= TCOLS || y < 0 || y >= TROWS )) && return 0
  GB[$(( y * TCOLS + x ))]=$3
  return 0
}

c_text() {  # c_text X Y STR [FG] [BG]
  local -i x=$1 y=$2 n k
  local s="$3"
  (( y < 0 || y >= TROWS )) && return 0
  # NOTHING THAT IS NOT A GLYPH GOES INTO A CELL.  The canvas is emitted to
  # the terminal verbatim, so a control byte in a cell is a control byte on
  # the wire: an escape that got this far -- a line out of a program's log,
  # with the `\e[K` it used to redraw itself -- erased the rest of the
  # terminal's row, bezel and all, and a stray `\e[?2026h` left Terminal.app
  # holding frames.  A control character is a space here, whatever sent it.
  [[ "$s" == *[[:cntrl:]]* ]] && s="${s//[[:cntrl:]]/ }"
  n=${#s}
  (( n )) || return 0
  if (( x < 0 )); then
    (( -x >= n )) && return 0
    s="${s[$(( -x )),-1]}"; n=${#s}; x=0
  fi
  (( x >= TCOLS )) && return 0
  if (( x + n > TCOLS )); then
    n=$(( TCOLS - x )); s="${s[0,$(( n - 1 ))]}"
  fi
  k=$(( y * TCOLS + x ))
  GCH[$k,$(( k + n - 1 ))]=("${(@s::)s}")
  # the run of ink and the run of ground come from the run cache, looked up
  # here rather than through _repn: a call saved on each, two hundred times a
  # page (_repn still makes a run the cache has not got)
  if (( $# >= 4 )) && (( ${4} != -2 )); then
    REPN="REP_${n}_${4//-/m}"
    if [[ -n "${REPC[$REPN]:-}" ]]; then REPV="${REPN}[@]"; else _repn $n $4; fi
    GF[$k,$(( k + n - 1 ))]=("${(@P)REPV}")
  fi
  if (( $# >= 5 )) && (( ${5} != -2 )); then
    REPN="REP_${n}_${5//-/m}"
    if [[ -n "${REPC[$REPN]:-}" ]]; then REPV="${REPN}[@]"; else _repn $n $5; fi
    GB[$k,$(( k + n - 1 ))]=("${(@P)REPV}")
  fi
  return 0
}

c_center() {   # c_center Y STR [FG] [BG] [X0] [W]
  local -i w=${6:-$TCOLS} x0=${5:-0}
  c_text $(( x0 + (w - ${#2}) / 2 )) $1 "$2" ${3:--2} ${4:--2}
}

# A RUN OF ONE GLYPH IS PADDING, and zsh pads in C: ${(l:N::G:)} on nothing
# is N copies of G, in three microseconds where a loop appending them one at
# a time took two hundred -- and a page is dozens of these a frame.  A glyph
# that is the flag's own delimiter would break the expansion, so that one
# is padded with another delimiter.
_run() {   # _run N GLYPH -> RUN · N copies of GLYPH
  # The (l) flag pads an EMPTY string out to N with the glyph: one C-level
  # loop instead of N shell appends.  The padded parameter has to exist
  # (set -u), and the delimiter must not be the glyph itself.  A "glyph" of
  # more than one character, or none, is not padding -- the flag would cut a
  # pattern off at N characters where the loop it replaced made N copies of
  # it -- so that one is appended, the way it always was.
  local -i n=$1 i; local g="$2" e=''
  if (( n <= 0 )); then RUN=''
  elif (( ${#g} != 1 )); then RUN=''; for (( i = 0; i < n; i++ )); do RUN+="$g"; done
  elif [[ "$g" == : ]]; then RUN="${(pl.$n..$g.)e}"
  else RUN="${(pl:$n::$g:)e}"; fi
  return 0
}
c_fill() {   # c_fill X Y W H [GLYPH] [FG] [BG]
  local -i x=$1 y=$2 w=$3 h=$4 yy
  (( w > 0 )) || return 0
  _run $w "${5:- }"
  local s="$RUN"
  for (( yy = y; yy < y + h; yy++ )); do c_text $x $yy "$s" ${6:--2} ${7:--2}; done
}

c_box() {    # c_box X Y W H [FG] [BG] [STYLE] [FILL]
  local -i x=$1 y=$2 w=$3 h=$4 fg=${5:--2} bg=${6:--2} yy
  local st="${7:-round}" tl tr bl br hz vt
  case "$st" in
    double) tl='╔'; tr='╗'; bl='╚'; br='╝'; hz='═'; vt='║' ;;
    heavy)  tl='┏'; tr='┓'; bl='┗'; br='┛'; hz='━'; vt='┃' ;;
    light)  tl='┌'; tr='┐'; bl='└'; br='┘'; hz='─'; vt='│' ;;
    *)      tl='╭'; tr='╮'; bl='╰'; br='╯'; hz='─'; vt='│' ;;
  esac
  (( ${8:-0} )) && c_fill $(( x + 1 )) $(( y + 1 )) $(( w - 2 )) $(( h - 2 )) ' ' $fg $bg
  local line=''
  (( w > 2 )) && { _run $(( w - 2 )) "$hz"; line="$RUN"; }
  c_text $x $y "$tl$line$tr" $fg $bg
  c_text $x $(( y + h - 1 )) "$bl$line$br" $fg $bg
  for (( yy = y + 1; yy < y + h - 1; yy++ )); do
    c_put $x $yy "$vt" $fg $bg
    c_put $(( x + w - 1 )) $yy "$vt" $fg $bg
  done
}

# ── the same, but in the glass's own coordinates ────────────────────────────
# arcade.py has a View for this -- a clipped, offset window onto the canvas,
# which is what every page in the cabinet draws into.  A shell has no object
# to hang one on, so it is four functions that add the offset and clip, and
# the glass is the only view this file ever needs.
# A CELL IS WRITTEN HERE, NOT HANDED ON.  v_put was the one call every
# plotter, waterfall and sprite in the house made per cell, and it made c_put
# for each of them: two calls, two sets of locals, for three assignments.  It
# is c_put's arithmetic in c_put's order, clipped to the glass and then to
# the grid, in one function -- the same cells, at half the cost a cell.
v_put()    { (( $1 < 0 || $1 >= SCR_W || $2 < 0 || $2 >= SCR_H )) && return 0
             local -i x=$(( OX + C_SCR + $1 )) y=$(( OY + R_SCR + $2 )) k
             (( x < 0 || x >= TCOLS || y < 0 || y >= TROWS )) && return 0
             k=$(( y * TCOLS + x ))
             GCH[$k]="$3"
             [[ -n "${4:-}" ]] && (( $4 != -2 )) && GF[$k]=$4
             [[ -n "${5:-}" ]] && (( $5 != -2 )) && GB[$k]=$5
             return 0 }
v_tint()   { (( $1 < 0 || $1 >= SCR_W || $2 < 0 || $2 >= SCR_H )) && return 0
             local -i x=$(( OX + C_SCR + $1 )) y=$(( OY + R_SCR + $2 ))
             (( x < 0 || x >= TCOLS || y < 0 || y >= TROWS )) && return 0
             GB[$(( y * TCOLS + x ))]=$3
             return 0 }
# v_text IS c_text WITH THE GLASS'S CLIPPING IN FRONT OF IT, in one function:
# it was the one call every page made most, and half of what it cost was
# calling c_text and having c_text clip the string a second time.  The same
# cuts in the same order -- the glass's, then the grid's -- and the same cells.
v_text()   { local -i x=$1 y n k
             local s="$3"
             (( $2 < 0 || $2 >= SCR_H )) && return 0
             (( x >= SCR_W )) && return 0
             if (( x < 0 )); then
               (( -x >= ${#s} )) && return 0
               s="${s[$(( -x )),-1]}"; x=0
             fi
             (( x + ${#s} > SCR_W )) && s="${s[0,$(( SCR_W - x - 1 ))]}"
             [[ -n "$s" ]] || return 0
             x=$(( OX + C_SCR + x )); y=$(( OY + R_SCR + $2 ))
             (( y < 0 || y >= TROWS )) && return 0
             [[ "$s" == *[[:cntrl:]]* ]] && s="${s//[[:cntrl:]]/ }"
             n=${#s}
             (( n )) || return 0
             if (( x < 0 )); then
               (( -x >= n )) && return 0
               s="${s[$(( -x )),-1]}"; n=${#s}; x=0
             fi
             (( x >= TCOLS )) && return 0
             if (( x + n > TCOLS )); then
               n=$(( TCOLS - x )); s="${s[0,$(( n - 1 ))]}"
             fi
             k=$(( y * TCOLS + x ))
             GCH[$k,$(( k + n - 1 ))]=("${(@s::)s}")
             if [[ -n "${4:-}" ]] && (( $4 != -2 )); then
               REPN="REP_${n}_${4//-/m}"
               if [[ -n "${REPC[$REPN]:-}" ]]; then REPV="${REPN}[@]"; else _repn $n $4; fi
               GF[$k,$(( k + n - 1 ))]=("${(@P)REPV}")
             fi
             if [[ -n "${5:-}" ]] && (( $5 != -2 )); then
               REPN="REP_${n}_${5//-/m}"
               if [[ -n "${REPC[$REPN]:-}" ]]; then REPV="${REPN}[@]"; else _repn $n $5; fi
               GB[$k,$(( k + n - 1 ))]=("${(@P)REPV}")
             fi
             return 0 }
v_center() { local -i w=${6:-$SCR_W} x0=${5:-0}
             v_text $(( x0 + (w - ${#2}) / 2 )) $1 "$2" ${3:--2} ${4:--2} }
# A FILL OF THE WHOLE GLASS IS BAKED (glass_bake).  Nearly every page in the
# house begins by clearing its glass to one glyph on one ground, and did it
# again every frame -- fifty-four rows of it, on top of the copy frame_begin
# had just made of a layer whose glass was about to be cleared.  The cleared
# glass is the still layer's glass now, under a key that says what it was
# cleared to, so the next frame's copy arrives cleared and the fill is a
# lookup.  Anything the page draws on top is drawn on top, as it was.
v_fill()   { local -i y yy=$2 h=$4
             (( $3 > 0 )) || return 0
             if (( $1 == 0 && yy == 0 && $3 == SCR_W && h == SCR_H )); then
               glass_baked "vfill|${5:- }|${6:--2}|${7:--2}|${SCR_W}x${SCR_H}" && return 0
               [[ -n "$GSTILL_KEY" ]] && { glass_unbake; glass_base_canvas }   # a fill that leaves ink or ground alone leaves the BASE's
               _run $3 "${5:- }"
               for (( y = 0; y < h; y++ )); do v_text 0 $y "$RUN" ${6:--2} ${7:--2}; done
               glass_bake "vfill|${5:- }|${6:--2}|${7:--2}|${SCR_W}x${SCR_H}"
               return 0
             fi
             _run $3 "${5:- }"
             for (( y = yy; y < yy + h; y++ )); do v_text $1 $y "$RUN" ${6:--2} ${7:--2}; done }
v_hline()  { (( $3 > 0 )) || return 0
             _run $3 "$4"
             v_text $1 $2 "$RUN" ${5:--2} ${6:--2} }
v_box()    { local -i x=$1 y=$2
             c_box $(( OX + C_SCR + x )) $(( OY + R_SCR + y )) $3 $4 ${5:--2} ${6:--2} "${7:-round}" ${8:-0} }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 4 · THE RENDERER        arcade.py's section 4, row-diffed
# ══════════════════════════════════════════════════════════════════════════
# EMIT ONLY WHAT MOVED.  The old TERMINAL painted every cell of its glass every
# frame -- three thousand cells, nineteen thousand channel quantisations --
# and the reason it could afford to is that it only ever painted the GLASS:
# the cabinet around it was drawn once on a resize and never again.  This
# machine animates everywhere at once -- the chase lights, the tubes, the
# side art, the lamps, the floor, the stars outside -- so the split the old
# TERMINAL used is not available, and the arcade's answer is what is used
# instead.
#
# ROW-LEVEL DIFFING IS NOT ENOUGH, and arcade.py says so: one animated neon
# cell would drag a whole hundred-and-twenty-column row onto the wire every
# frame.  So a changed row is scanned for RUNS of changed cells, runs
# separated by less than a cursor move's worth of unchanged cells are
# merged, and those are emitted as colour runs.
#
# WHAT IS ZSH'S OWN is the row signature.  Python compares three lists with
# one `==` and the interpreter does it in C; a shell comparing five thousand
# cells three ways a frame is a shell that has no frames left.  So a row is
# JOINED -- three array slices into one string, which zsh also does in C --
# and a row whose string is the string it was last time is skipped without a
# single cell being looked at.  Only the rows that survive that are walked.
typeset -ga PSIG PBSIG
BLK=16; NBLK=0
# ── the renderer, second edition · the same bytes for a fifth of the work ──
# THREE THINGS CHANGED AND NOTHING ON THE WIRE DID.
#   · A ROW IS JOINED IN PLACE.  Slicing a row out of the canvas first cost
#     the size of the canvas three times a row (ninety microseconds of the
#     hundred and ten a row was costing) and the slice was only ever joined.
#     ${(j:,:)GCH[a,b]} joins the cells where they lie, and the slice is gone.
#   · A BLOCK REMEMBERS ITS BYTES.  The light on this machine cycles: a tube
#     has thirty-odd steps, a chase has a few, a breath has its ladder.  A
#     block whose cells and post-question are exactly what they were some
#     frames ago comes out as exactly the same bytes, so the bytes are kept
#     under the block's position and signature and looked up before the cell
#     walk -- which is where the frame went, in float mode: forty milliseconds
#     of walking cells that had been walked before.  A fade is left out of it
#     (every rung is new bytes, once) and the lot is let go at twelve thousand.
#   · A BLOCK IS ONE PIECE OF OUTPUT.  Every colour change pushed a list
#     element -- two thousand pushes a frame on a floating cabinet, ten
#     microseconds each.  A block's bytes gather in one short string, and
#     the list takes the string.
typeset -gA RBM PBCON PBREC VRUN UNI
typeset -gi RBM_N=0
# r_forget · what the renderer remembered about blocks, let go: the bytes a
# block came out as (RBM), the runs it walked in (PBCON, PBREC) and the tube's
# rungs across it (VRUN) · all tied to the block's position on the grid and
# under the tube
r_forget() { RBM=(); RBM_N=0; PBCON=(); PBREC=(); VRUN=() }
r_invalidate() { PSIG=(); PBSIG=(); r_forget }
r_heal_row() {   # r_heal_row Y — forget one row, blocks and all
  local -i b
  PSIG[$1]=''
  for (( b = 0; b < NBLK; b++ )); do PBSIG[$(( $1 * NBLK + b ))]=''; done
  return 0
}

SYNC_ON=$'\033[?2026h'; SYNC_OFF=$'\033[?2026l'
SGB[-1]=$'\033[49m'
# ...AND AN INK OF -1 IS NO INK AT ALL.  The glass is cleared to it so that
# "has anything been written in this cell" is a question the grid can answer
# -- which is what the dust needs and what a space cannot say on its own.
# Nothing visible is ever drawn in it, so leaving the terminal's own
# foreground alone is exactly right.
SGF[-1]=''
(( OPT_PLAIN )) && SGB[-1]=''
r_flush() {
  local sig csig bsig fs bs seq rpk rpo key d a ob mk rec hdr
  local -a O
  local -i y x i k ke off oe b x0 x1 bk cb cf cb2 cf2 run v inr bw bin
  local -i lastf lastb lastn lastin lastf2 lastb2 lastbd
  local -i mq=$TUBE_MQ gd=$GDIM_N post glass roll gy vb memo fd=$(( GDIM_N < DIM_STEPS )) plain vi
  local -i bdk bxa bxb bd                # the backdrop on this row · this cell
  local -i gbase_y=$(( OY + R_SCR )) gbase_x=$(( OX + C_SCR )) gend_x=$(( OX + C_SCR + SCR_W ))
  # no tube before the glass has been measured (the overture runs on a bare
  # canvas, before the cabinet is stood up)
  (( ${#VIGN[@]} == SCR_W * SCR_H )) || gbase_y=-100000
  if (( ${#PSIG[@]} != TROWS )); then
    PSIG=(); PBSIG=(); r_forget
    O+=($'\033[2J')
  fi
  memo=$(( gd >= DIM_STEPS ))
  for (( y = 0; y < TROWS; y++ )); do
    off=$(( y * TCOLS )); oe=$(( off + TCOLS - 1 ))
    # WHAT THE WIRE DOES TO THIS ROW.  A glass row goes through the tube, and
    # through whatever wash or roll the frame put on it; any row goes through
    # the fade when the cabinet is fading.  The row's own answer is part of
    # its signature, so a roll moving down a row re-emits that row and no
    # other, and a fade stepping a rung re-emits the lot -- which is the
    # picture changing, and is what it always cost.
    gy=$(( y - gbase_y ))
    glass=0; post=0; rpk=''; rpo=''; a=''; roll=0; vb=0; bdk=0; bxa=0; bxb=0; plain=0
    if (( gy >= 0 && gy < SCR_H )); then
      glass=1; post=1
      a="${PW_A[$gy]:-}"; roll=${PR_B[$gy]:-0}
      rpk="$a/$roll/$mq/$gd"; rpo="//256/$gd"
      vb=$(( gy * SCR_W ))
      # a box standing over the page: this row's cutout, in screen columns
      # (none, when the row is above or below the box), and the level
      if (( BD_K && gy < BD_YF )); then
        bdk=$BD_K; bxa=0; bxb=0
        (( gy >= BD_Y0 && gy < BD_Y1 )) && { bxa=$(( gbase_x + BD_X0 )); bxb=$(( gbase_x + BD_X1 )) }
        rpk+="/$bdk/$bxa/$bxb"
      fi
    elif (( gd < DIM_STEPS && y >= OY && y < OY + ARC_H )); then
      # the cabinet's own rows fade · the rows above and below it are night
      post=1; rpo="//256/$gd"; rpk="$rpo"
    fi
    (( glass && ! bdk && roll == 0 && mq == 256 && gd >= DIM_STEPS )) && [[ -z "$a" ]] && plain=1
    # THE WHOLE ROW FIRST.  A row whose three arrays join to the string they
    # joined to last time has not moved, and on this machine most of them
    # have not: the walls, the bezel, the frame, the silk-screen and the
    # footer are the same cells they were, and skipping them costs three
    # joins rather than three hundred and ninety comparisons.
    sig="${(j:,:)GCH[$off,$oe]}${(j:,:)GF[$off,$oe]}${(j:,:)GB[$off,$oe]}|$rpk"
    [[ "$sig" == "${PSIG[$y]:-}" ]] && continue
    PSIG[$y]="$sig"
    # ...AND THEN THE ROW IN BLOCKS.  arcade.py walks the changed row cell by
    # cell and merges the hits into spans, which in Python is a list
    # comprehension over three zipped lists and in zsh is eleven microseconds
    # a cell -- sixty milliseconds a frame, which was half the renderer.  The
    # same question asked of a SIXTEEN-CELL block is one more join and it
    # answers for sixteen cells at once: a neon tube's column comes out as
    # one block, a row of text as the two or three it actually occupies.
    for (( b = 0; b < NBLK; b++ )); do
      x0=$(( b * BLK )); x1=$(( x0 + BLK ))
      (( x1 > TCOLS )) && x1=$TCOLS
      (( x0 >= x1 )) && break
      k=$(( off + x0 )); ke=$(( off + x1 - 1 )); bw=$(( x1 - x0 ))
      # a block that never touches the glass does not answer for the glass's
      # wash or roll · only for the fade
      if (( glass && x1 > gbase_x && x0 < gend_x )); then key="$rpk"; else key="$rpo"; fi
      fs="${(j:,:)GF[$k,$ke]}"; bs="${(j:,:)GB[$k,$ke]}"
      csig="${(j:,:)GCH[$k,$ke]}$fs$bs"
      bsig="$csig|$key"
      bk=$(( y * NBLK + b ))
      [[ "$bsig" == "${PBSIG[$bk]:-}" ]] && continue
      PBSIG[$bk]="$bsig"
      # THE BYTES THIS BLOCK CAME OUT AS LAST TIME IT LOOKED LIKE THIS
      if (( memo )); then
        mk="$bk|$bsig"; ob="${RBM[$mk]:-}"
        if [[ -n "$ob" ]]; then O+=("$ob"); continue; fi
      fi
      ob=$'\033['$(( y + 1 ))';'$(( x0 + 1 ))'H'
      lastf=-9; lastb=-9; lastn=-9; lastin=-9; lastf2=-9; lastb2=-9; lastbd=-9
      run=0; bd=0
      # THE SAME CELLS UNDER A DIFFERENT LIGHT ARE WALKED IN RUNS, NOT CELLS.
      # A page changing channel, a cabinet fading, a box standing up over a
      # page: the picture holds still and the question put to every cell
      # moves a step a frame -- and every cell of the glass was looked at
      # again to find out that the runs were where they were.  The walk below
      # writes down where each run began and what it asked (its colours, its
      # rung of the tube, whether it is glass); a block whose cells are the
      # cells they were replays those runs with the new question, so a
      # washed frame costs a lookup a run where it cost a lookup a cell.
      # (The record is only as good as its premises: the same fade state,
      # the same box cutout -- the header -- and the same cells, the content
      # signature.  Anything else and the cells are walked, and written down.)
      hdr="$fd/$(( bdk != 0 ))/$bxa/$bxb"
      if (( post )); then
        #   bin=1  the whole block is glass · bin=0 none of it · bin=-1 the edge
        if (( glass && x0 >= gbase_x && x1 <= gend_x )); then bin=1
        elif (( glass && x1 > gbase_x && x0 < gend_x )); then bin=-1
        else bin=0; fi
        # A BLOCK OF ONE COLOUR ASKS ONLY WHERE THE TUBE'S RUNGS CHANGE.  The
        # blank glass of a page change, the dark of a fade, the room of any
        # page: whole blocks of one ink on one ground, whose runs would come
        # out at the rung boundaries and nowhere else -- and those are the
        # block's own, worked out once (VRUN) and good until the tube moves.
        # The runs are written down as if walked, and the replay takes them.
        if (( bin > 0 && ! bdk )) && [[ "${PBCON[$bk]:-}" != "$csig" ]]; then
          cf=${GF[$k]}; cb=${GB[$k]}
          d="${UNI[$bw,$cf]:-}"; [[ -n "$d" ]] || { _repn $bw $cf; d="${(j:,:)${(@P)REPV}}"; UNI[$bw,$cf]="$d" }
          if [[ "$fs" == "$d" ]]; then
            d="${UNI[$bw,$cb]:-}"; [[ -n "$d" ]] || { _repn $bw $cb; d="${(j:,:)${(@P)REPV}}"; UNI[$bw,$cb]="$d" }
            if [[ "$bs" == "$d" ]]; then
              rec="${VRUN[$bk]:-}"
              if [[ -z "$rec" ]]; then
                lastn=-9
                for (( x = 0; x < bw; x++ )); do
                  v=${VIGN[$(( vb + x0 + x - gbase_x ))]}
                  (( v == lastn )) && continue
                  rec+="$x $v "; lastn=$v
                done
                VRUN[$bk]="$rec"
              fi
              set -- ${=rec}; rec=''
              while (( $# )); do rec+="$1 $cb $cf $2 1 "; shift 2; done
              PBCON[$bk]="$csig"; PBREC[$bk]="$hdr|$rec"
            fi
          fi
        fi
      fi
      if (( post )) && [[ "${PBCON[$bk]:-}" == "$csig" && "${PBREC[$bk]%%|*}" == "$hdr" ]]; then
        set -- ${=${PBREC[$bk]#*|}}
        while (( $# )); do
          x=$1; cb=$2; cf=$3; v=$4; inr=$5; shift 5
          if (( inr == 1 && bdk )); then
            bd=$bdk; (( x0 + x >= bxa && x0 + x < bxb )) && bd=0
          else bd=0; fi
          if (( inr == 2 )); then
            cb2=$cb; cf2=$cf
          else
            if (( inr )); then key="$v,$mq,$a,$roll,$gd,$bd"; else key="$DIM_STEPS,256,,0,$gd,0"; fi
            d="${PTC[f$cf,$key]:-}"
            if [[ -z "$d" ]]; then
              if (( inr )); then post_calc 0 $cf $v $mq "$a" $roll $gd $bd; else post_calc 0 $cf $DIM_STEPS 256 '' 0 $gd; fi
              d=$PC
              (( PTC_N++ > 30000 )) && { PTC=(); PTC_N=0 }
              PTC[f$cf,$key]=$d
            fi
            cf2=$d
            d="${PTC[b$cb,$key]:-}"
            if [[ -z "$d" ]]; then
              if (( inr )); then post_calc 1 $cb $v $mq "$a" $roll $gd $bd; else post_calc 1 $cb $DIM_STEPS 256 '' 0 $gd; fi
              d=$PC
              PTC[b$cb,$key]=$d
            fi
            cb2=$d
          fi
          (( cb2 == lastb2 && cf2 == lastf2 )) && continue
          (( x > run )) && ob+="${(j::)GCH[$(( k + run )),$(( k + x - 1 ))]}"
          if (( cb2 != lastb2 )); then
            seq="${SGB[$cb2]:-}"
            [[ -n "$seq" ]] || { sgb $cb2; seq="$SB" }
            ob+="$seq"; lastb2=$cb2
          fi
          if (( cf2 != lastf2 )); then
            if (( cf2 < 0 )); then
              seq=''
            else
              seq="${SGF[$cf2]:-}"
              [[ -n "$seq" ]] || { sgf $cf2; seq="$SF" }
            fi
            ob+="$seq"; lastf2=$cf2
          fi
          run=$x
        done
        (( bw > run )) && ob+="${(j::)GCH[$(( k + run )),$ke]}"
        ob+=$'\033[0m'
        O+=("$ob")
        if (( memo )); then
          (( RBM_N++ > 12000 )) && { RBM=(); RBM_N=0 }
          RBM[$mk]="$ob"
        fi
        continue
      fi
      rec=''
      # THE COLOUR IS COMPARED AS A NUMBER, not as the escape sequence it
      # turns into.  Neighbouring cells share a colour far more often than
      # not, and an integer equal to the last one costs one comparison where
      # a string equal to the last one costs a hash, a lookup and a compare.
      #
      # AND THE GLYPHS GO OUT IN RUNS, not one at a time.  A cell whose two
      # colours are the colours already set needs no escape sequence at all
      # and no decision -- it is another character of the run in progress --
      # so the run is remembered and JOINED when a colour finally moves.
      if (( post && plain && bin > 0 )); then
        # THE PLAIN TUBE, WORKED OUT WHERE IT STANDS.  On a row with no wash,
        # no roll, no fade and no box -- which is every row of every settled
        # frame -- the tube's whole answer for a cell is its colour taken
        # down to the vignette's rung, three multiplies.  Looking that up
        # cost more than doing it: a key built and two tables asked, a run at
        # a time.  So it is done in place, the same integer arithmetic
        # post_calc does, and the run is written down for the replay exactly
        # as the walk below would write it.
        for (( x = 0, i = k, vi = vb + x0 - gbase_x; x < bw; x++, i++, vi++ )); do
          (( cb = GB[i], cf = GF[i], v = VIGN[vi] ))
          (( cb == lastb && cf == lastf && v == lastn )) && continue
          (( lastb = cb, lastf = cf, lastn = v ))
          rec+="$x $cb $cf $v 1 "
          (( cf2 = (cf < 0 || v >= DIM_STEPS) ? cf : (((((cf >> 16) & 255) * v / DIM_STEPS) << 16) | ((((cf >> 8) & 255) * v / DIM_STEPS) << 8) | ((cf & 255) * v / DIM_STEPS)),
             cb2 = (cb < 0 || v >= DIM_STEPS) ? cb : (((((cb >> 16) & 255) * v / DIM_STEPS) << 16) | ((((cb >> 8) & 255) * v / DIM_STEPS) << 8) | ((cb & 255) * v / DIM_STEPS)) ))
          (( cb2 == lastb2 && cf2 == lastf2 )) && continue
          (( x > run )) && ob+="${(j::)GCH[$(( k + run )),$(( i - 1 ))]}"
          if (( cb2 != lastb2 )); then
            seq="${SGB[$cb2]:-}"
            [[ -n "$seq" ]] || { sgb $cb2; seq="$SB" }
            ob+="$seq"; lastb2=$cb2
          fi
          if (( cf2 != lastf2 )); then
            if (( cf2 < 0 )); then
              seq=''
            else
              seq="${SGF[$cf2]:-}"
              [[ -n "$seq" ]] || { sgf $cf2; seq="$SF" }
            fi
            ob+="$seq"; lastf2=$cf2
          fi
          run=$x
        done
        PBCON[$bk]="$csig"; PBREC[$bk]="$hdr|$rec"
      elif (( post )); then
        # THE TUBE, ON THE WAY OUT.  The raw colour, the cell's own rung of
        # the vignette and the row's wash and roll are the whole question,
        # and a cell that asks the same question as the cell before it is the
        # same run.  Only a new question is looked up, and only a question
        # never asked before is worked out.  (bin was settled above.)
        for (( x = 0, i = k; x < bw; x++, i++ )); do
          cb=${GB[$i]}; cf=${GF[$i]}
          if (( bin > 0 )); then
            v=${VIGN[$(( vb + x0 + x - gbase_x ))]}; inr=1
          elif (( bin < 0 )) && (( x0 + x >= gbase_x && x0 + x < gend_x )); then
            v=${VIGN[$(( vb + x0 + x - gbase_x ))]}; inr=1
          else
            v=$DIM_STEPS; inr=0
            # the night is not the machine and does not fade with it
            (( gd < DIM_STEPS )) && [[ -n "${NIGHTK[$i]:-}" ]] && inr=2
          fi
          # behind a box, unless this cell is the box
          if (( bdk && inr == 1 )); then
            bd=$bdk; (( x0 + x >= bxa && x0 + x < bxb )) && bd=0
          else bd=0; fi
          (( cb == lastb && cf == lastf && v == lastn && inr == lastin && bd == lastbd )) && continue
          lastb=$cb; lastf=$cf; lastn=$v; lastin=$inr; lastbd=$bd
          rec+="$x $cb $cf $v $inr "
          if (( inr == 2 )); then
            cb2=$cb; cf2=$cf
          else
            if (( inr )); then key="$v,$mq,$a,$roll,$gd,$bd"; else key="$DIM_STEPS,256,,0,$gd,0"; fi
            d="${PTC[f$cf,$key]:-}"
            if [[ -z "$d" ]]; then
              if (( inr )); then post_calc 0 $cf $v $mq "$a" $roll $gd $bd; else post_calc 0 $cf $DIM_STEPS 256 '' 0 $gd; fi
              d=$PC
              (( PTC_N++ > 30000 )) && { PTC=(); PTC_N=0 }
              PTC[f$cf,$key]=$d
            fi
            cf2=$d
            d="${PTC[b$cb,$key]:-}"
            if [[ -z "$d" ]]; then
              if (( inr )); then post_calc 1 $cb $v $mq "$a" $roll $gd $bd; else post_calc 1 $cb $DIM_STEPS 256 '' 0 $gd; fi
              d=$PC
              PTC[b$cb,$key]=$d
            fi
            cb2=$d
          fi
          (( cb2 == lastb2 && cf2 == lastf2 )) && continue
          (( x > run )) && ob+="${(j::)GCH[$(( k + run )),$(( i - 1 ))]}"
          if (( cb2 != lastb2 )); then
            seq="${SGB[$cb2]:-}"
            [[ -n "$seq" ]] || { sgb $cb2; seq="$SB" }
            ob+="$seq"; lastb2=$cb2
          fi
          if (( cf2 != lastf2 )); then
            if (( cf2 < 0 )); then
              seq=''                     # no ink · leave the terminal's own
            else
              seq="${SGF[$cf2]:-}"
              [[ -n "$seq" ]] || { sgf $cf2; seq="$SF" }
            fi
            ob+="$seq"; lastf2=$cf2
          fi
          run=$x
        done
        PBCON[$bk]="$csig"; PBREC[$bk]="$hdr|$rec"
      else
        for (( x = 0, i = k; x < bw; x++, i++ )); do
          cb=${GB[$i]}; cf=${GF[$i]}
          (( cb == lastb && cf == lastf )) && continue
          (( x > run )) && ob+="${(j::)GCH[$(( k + run )),$(( i - 1 ))]}"
          if (( cb != lastb )); then
            seq="${SGB[$cb]:-}"
            [[ -n "$seq" ]] || { sgb $cb; seq="$SB" }
            ob+="$seq"; lastb=$cb
          fi
          if (( cf != lastf )); then
            if (( cf < 0 )); then
              seq=''                       # no ink · leave the terminal's own
            else
              seq="${SGF[$cf]:-}"
              [[ -n "$seq" ]] || { sgf $cf; seq="$SF" }
            fi
            ob+="$seq"; lastf=$cf
          fi
          run=$x
        done
      fi
      (( bw > run )) && ob+="${(j::)GCH[$(( k + run )),$ke]}"
      ob+=$'\033[0m'
      O+=("$ob")
      if (( memo )); then
        (( RBM_N++ > 12000 )) && { RBM=(); RBM_N=0 }
        RBM[$mk]="$ob"
      fi
    done
  done
  # THE FRAME IS GATHERED AS A LIST AND JOINED ONCE.  Appending to a string
  # that is already fifty kilobytes long copies the fifty kilobytes, and a
  # frame appends a thousand times: a quarter of the renderer was the shell
  # moving the same bytes around.  A list push is a pointer, and the join is
  # one C loop at the end.
  # ONE FRAME, WHOLE: a terminal that speaks synchronised output (iTerm2,
  # Ghostty, kitty, WezTerm) holds the repaint until the closing sequence, so
  # nothing ever tears; Terminal.app ignores both and is no worse off.
  (( ${#O[@]} )) && print -rn -- "$SYNC_ON${(j::)O[@]}$SYNC_OFF"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 5 · THE TUBE            arcade.py's section 10, applied on the wire
# ══════════════════════════════════════════════════════════════════════════
# A vignette, a scanline and a roll -- every number the arcade's, and the
# reason the glass reads as glass rather than as text sitting in a rectangle.
# On a 256-colour terminal a deep vignette BANDS, so it runs shallow there,
# which is the same call arcade.py makes at the same line for the same reason.
#
# THE TUBE IS NOT PAINTED INTO THE PICTURE ANY MORE.  It used to be: a pass
# over every cell of the glass, two memo lookups each, sixty milliseconds a
# frame on every surface that could not cache its picture -- the power gate,
# the installer, every page of every machine -- and the caches that saved the
# menu from it (a baked glass, a dimmed row here and there) were a second
# renderer written around the first.  What every one of those passes had in
# common is that the tube is a function of POSITION and COLOUR and nothing
# else, and the renderer already walks exactly the cells that changed, one
# colour at a time, on its way to the wire.  So the tube is applied THERE:
# the canvas holds the raw picture, r_flush turns each emitted colour through
# the tube (and the roll, and whatever wash or fade the frame asked for) as
# it makes the escape sequence, and a cell that did not change costs nothing
# -- which on this machine is nearly all of them, nearly all of the time.
# The arithmetic is the same integer ladder it always was, so the picture on
# the wire is the picture it always was; it is only ever made once.
#
# TWENTY-FOUR BANDS.  A smooth per-cell vignette gives every column its own
# colour and each change costs eleven bytes of escape sequence; twenty-four is
# smooth at this size and still a long way from giving every cell its own
# ink, and now that the tube costs nothing to apply, the bands are all it
# costs on the wire.
VIG_DEPTH=0.30; VIG_BANDS=24; DIM_STEPS=64
typeset -ga VIGN
vig_init() {
  (( ${#VIGN[@]} == SCR_W * SCR_H )) && return 0
  r_forget                             # the tube is the memo's silent partner
  # THE LEVEL IS AN INTEGER FROM HERE ON.  The vignette is a smooth function
  # of position and the tube's answer is a brightness ladder; the ladder has
  # sixty-four rungs, so a shift does the whole thing on the wire.
  (( TRUE24 )) && VIG_DEPTH=0.30 || VIG_DEPTH=0.11
  local -i y x
  local -F scan dx dy d v
  VIGN=()
  for (( y = 0; y < SCR_H; y++ )); do
    scan=1.0; (( y & 1 )) && scan=0.70
    for (( x = 0; x < SCR_W; x++ )); do
      dx=$(( (x - (SCR_W - 1) / 2.0) / (SCR_W / 2.0) ))
      dy=$(( (y - (SCR_H - 1) / 2.0) / (SCR_H / 2.0) ))
      d=$(( sqrt(dx * dx * 0.72 + dy * dy) ))
      v=$(( 1.0 + VIG_DEPTH * 0.2 - VIG_DEPTH * d * d * d ))
      (( v < 0.55 )) && v=0.55; (( v > 1.0 )) && v=1.0
      v=$(( v * scan ))
      VIGN[$(( y * SCR_W + x ))]=$(( int(int(v * VIG_BANDS + 0.5) / (VIG_BANDS + 0.0) * DIM_STEPS) ))
    done
  done
  return 0
}

# ── what a frame asks of the wire ──────────────────────────────────────────
# Four things can happen to a colour between the canvas and the terminal, in
# this order, which is the order the passes used to run in:
#
#   the WASH   · a page transition lifting a row toward the phosphor's core
#                (per row · set by the transition engine below)
#   the TUBE   · the vignette and scanline (per cell · VIGN, scaled by TUBE_MQ
#                when the boot card is still warming the glass)
#   the ROLL   · the bright row travelling down the tube (per row)
#   the FADE   · the whole cabinet dimming, marquee and all (per frame · the
#                power-up's neon coming up under the raster)
#
# Every one of them is a pure function of (colour, row, cell) and the four
# small tables below, so the renderer looks each answer up once per colour
# per row and remembers it.
typeset -ga PW_A PR_B                  # per glass row · wash strength · roll
typeset -gA PTC NIGHTK                 # the memo · the cells the night wrote
typeset -gi TUBE_MQ=256 GDIM_N=64      # tube multiplier ×256 · fade level /64
typeset -gi XF_CORE=0                  # the phosphor every wash lifts toward
# THE BACKDROP · a box standing over a page.  Everything on the glass that is
# not the box recedes -- its ground darkened toward the unlit tube, its ink
# muted further -- so the box is the one lit thing and reads as a question
# put to the reader rather than as more of the page.  A rectangle and a
# level are the whole description: the renderer asks each emitted cell
# whether it is inside the rectangle, and only the answer goes into the memo.
typeset -gi BD_K=0 BD_STEPS=16         # the level /16 · 0 is no backdrop
typeset -gi BD_X0=0 BD_X1=0 BD_Y0=0 BD_Y1=0 BD_YF=0   # the box · rows from BD_YF down are left alone
typeset -gi BD_CORE=0                  # the dark the backdrop recedes toward
post_reset() { PW_A=(); PR_B=(); NIGHTK=(); TUBE_MQ=256; GDIM_N=64; BD_K=0 }
# post_backdrop X Y W H K [YF] — the glass outside the box x,y,w,h recedes K
# of the way (1.0 is a box fully open) · rows from YF down keep the page
post_backdrop() {
  local -F k=$5
  (( k <= 0.0 )) && { BD_K=0; return 0 }
  (( k > 1.0 )) && k=1.0
  BD_X0=$1; BD_Y0=$2; BD_X1=$(( $1 + $3 )); BD_Y1=$(( $2 + $4 ))
  BD_YF=${6:-$SCR_H}
  BD_K=$(( int(k * BD_STEPS + 0.5) ))
  return 0
}
post_tube()  { TUBE_MQ=$(( int($1 * 256.0) )); (( TUBE_MQ > 256 )) && TUBE_MQ=256; (( TUBE_MQ < 0 )) && TUBE_MQ=0; return 0 }
post_dim()   {   # post_dim LEVEL — 1.0 is no fade at all
  local -F lv=$1
  if (( lv >= 0.999 )); then GDIM_N=64; return 0; fi
  (( lv < 0.0 )) && lv=0.0
  GDIM_N=$(( int(lv * DIM_STEPS) ))
  return 0
}
# post_roll T — the bright row travelling down the tube · one row in a
# three-second window every twenty-one seconds, nine rows a second
post_roll() {
  local -F t=$1
  (( int(t * 0.33) % 7 == 0 )) || return 0
  local -i r=$(( int((t * 0.30 - 3.0 * floor(t * 0.30 / 3.0)) * SCR_H) ))
  (( r < 0 || r >= SCR_H )) && return 0
  PR_B[$r]=1
  return 0
}
# post_wash Y0 H KIND K — a transition's phosphor over rows y0 .. y0+h
#   unfold · the band opening: brightest at its centre row, fading as k→1
#   settle · the whole glass: k is the strength, odd rows at half of it
post_wash() {
  local -i y0=$1 hh=$2 yy i
  local kind="$3"
  local -F k=$4 a half
  half=$(( hh / 2.0 )); (( half < 1.0 )) && half=1.0
  for (( i = 0; i < hh; i++ )); do
    yy=$(( y0 + i ))
    (( yy < 0 || yy >= SCR_H )) && continue
    if [[ "$kind" == unfold ]]; then
      a=$(( (1.0 - abs(yy - (SCR_H - 1) / 2.0) / half * 0.5) * (1.0 - 0.88 * k) ))
    else
      a=$(( k * ((yy & 1) ? 0.5 : 1.0) ))
    fi
    (( a <= 0.004 )) && continue
    (( a > 0.94 )) && a=0.94
    PW_A[$yy]=$a
  done
  return 0
}

# post_calc ISBG C V MQ A ROLL GD [BD] -> PC · one colour, through the stages
# (V is the cell's rung of the vignette, MQ the boot card's warming multiplier,
# BD the backdrop's level for a cell behind a box)
#
# THE TUBE AND THE FADE DO NOT MASK.  Every other colour in this file is
# snapped to a multiple of four -- arcade.py's q(), right for an animated
# colour that would otherwise put an escape on the wire for a difference
# nobody can see.  A dim is not an animated colour, and on the glass's own
# (8, 4, 20) the mask is louder than the thing it is quantising: one rung
# down is (7, 3, 19), the mask makes it (4, 0, 16), and half the red is gone.
# The roll is a cshade, which does mask, exactly as it always did.
# THE BACKDROP AND THE WASH ARE ONE STAGE, AND IT IS REMEMBERED.  A colour,
# how far behind a box it stands and how far into the phosphor it has gone,
# comes out the same on every row and every frame that asks -- and a frame
# of a page settling asks it for every run of every block on the glass, two
# blends a run, twenty microseconds a blend.  Kept under (ink-or-ground,
# colour, wash, backdrop), the stage is a lookup; what is left below it is
# integer arithmetic on the way out.
typeset -gA PW1
typeset -gi PW1_N=0
post_calc() {
  local -i c=$2 n=$3 roll=$6 gd=$7 bd=${8:-0}
  local a="$5" w
  (( $4 != 256 )) && { n=$(( (n * $4) >> 8 )); (( n < 0 )) && n=0 }
  if (( bd )) || [[ -n "$a" ]]; then
    # ON 256 COLOURS THE BACKDROP IS FLAT: down at this level the palette
    # has two or three rungs to spend, and the vignette's bands land on
    # different ones cell by cell -- patches, where the eye wants a shade.
    (( bd && ! TRUE24 )) && n=$DIM_STEPS
    w="${PW1[$1,$c,$a,$bd]:-}"
    if [[ -n "$w" ]]; then c=$w
    else
      local -i c0=$c
      if (( bd )); then
        # behind a box: the ground goes a little over half way to the dark, the
        # ink nearly three quarters -- the page is still there, and still the
        # page, but it is no longer what the eye is asked to read.
        if (( $1 )); then
          (( c < 0 )) && c=$BLACK
          cmix $c $BD_CORE $(( bd * 0.58 / BD_STEPS )); c=$CM
        elif (( c >= 0 )); then
          cmix $c $BD_CORE $(( bd * 0.72 / BD_STEPS )); c=$CM
        fi
      fi
      if [[ -n "$a" ]]; then
        if (( $1 )); then
          (( c < 0 )) && c=$BLACK
          cmix $c $XF_CORE $a; c=$CM
        elif (( c >= 0 )); then
          cmix $c $XF_CORE $(( a * 0.55 )); c=$CM
        fi
      fi
      (( PW1_N++ > 20000 )) && { PW1=(); PW1_N=0 }
      PW1[$1,$c0,$a,$bd]=$c
    fi
  fi
  if (( c < 0 )); then PC=$c; return 0; fi
  (( n < DIM_STEPS )) && c=$(( (((c >> 16) & 255) * n / DIM_STEPS) << 16 \
                             | (((c >>  8) & 255) * n / DIM_STEPS) <<  8 \
                             |  ((c & 255) * n / DIM_STEPS) ))
  (( roll )) && { cshade $c 1.30; c=$CS }
  (( gd < DIM_STEPS )) && c=$(( (((c >> 16) & 255) * gd / DIM_STEPS) << 16 \
                              | (((c >>  8) & 255) * gd / DIM_STEPS) <<  8 \
                              |  ((c & 255) * gd / DIM_STEPS) ))
  PC=$c
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 5a · MOTION             one clock, one set of curves, one table
# ══════════════════════════════════════════════════════════════════════════
# EVERY EASE IN THE HOUSE IS ONE OF THESE, and every duration is in the table
# under them.  The two machines used to carry their own copy of the page
# transition -- the same hundred lines, the same three numbers, renamed --
# and the opening and the closing had the same curves inline with numbers of
# their own.  A cabinet whose surfaces all move the same way is a cabinet
# that reads as one machine; this is where the way is written down.
#
#   mo_smooth K      -> MK   smoothstep · the raster's own curve
#   mo_out K         -> MK   ease-out cubic · a thing arriving, then resting
#   mo_inout K       -> MK   ease-in-out sine · a thing that leaves and lands
#   mo_settle K A B  -> MK   a(1-k) + b·sin((1-k)π) · a picture settling in
#   mo_clamp K       -> MK   0..1
mo_clamp()  { MK=$1; (( MK < 0.0 )) && MK=0.0; (( MK > 1.0 )) && MK=1.0 }
mo_smooth() { mo_clamp $1; MK=$(( MK * MK * (3.0 - 2.0 * MK) )) }
mo_out()    { mo_clamp $1; MK=$(( 1.0 - (1.0 - MK) * (1.0 - MK) * (1.0 - MK) )) }
mo_inout()  { mo_clamp $1; MK=$(( 0.5 - 0.5 * cos(MK * 3.141592653589793) )) }
mo_settle() { mo_clamp $1; MK=$(( $2 * (1.0 - MK) + $3 * sin((1.0 - MK) * 3.141592653589793) )) }

# ── a value on its way somewhere ───────────────────────────────────────────
# mo_ease NAME TARGET T [DUR] -> MV · the eased value of NAME at time T.
# The first time a name is seen it is simply AT its target; every time the
# target moves the value sets off from wherever it had got to, ease-out,
# over DUR -- so a target that moves again mid-flight is re-aimed, never
# queued, and the thing on the glass never lags the hand on the key.
# A reading eases with it: the figure printed beside a bar is always the
# measured one; only the bar's length takes MO_VALUE to get there.
typeset -gA MOE_FROM MOE_TO MOE_T0
typeset -F MOE_LAST=-1000.0            # when anything was last re-aimed
mo_moving() { (( $1 - MOE_LAST < ${2:-$MO_VALUE} )) }   # mo_moving T [DUR] · is anything still in flight
mo_ease() {
  local n="$1"
  local -F to=$2 t=$3 dur=${4:-$MO_VALUE} from t0 k
  if [[ -z "${MOE_TO[$n]:-}" ]]; then
    MOE_FROM[$n]=$to; MOE_TO[$n]=$to; MOE_T0[$n]=-1000.0; MV=$to; return 0
  fi
  from=${MOE_FROM[$n]}; t0=${MOE_T0[$n]}
  # A TARGET IS "MOVED" WHEN IT MOVES BY SOMETHING A BAR COULD SHOW.  The
  # table keeps its figures to ten places and a caller hands in seventeen,
  # so a third was never equal to the third stored for it: every bar whose
  # target was not a round number was re-aimed every frame, by nothing, and
  # a page that repaints while anything is in flight (SYSTEM's, through
  # mo_moving) repainted itself from scratch on every beat for as long as it
  # was open.  A billionth is the eye's margin a thousand times over.
  if (( abs(to - ${MOE_TO[$n]}) > 1e-9 )); then
    # where it had got to becomes where it sets off from
    k=$(( dur > 0.0 ? (t - t0) / dur : 1.0 ))
    mo_out $k
    from=$(( from + (${MOE_TO[$n]} - from) * MK ))
    MOE_FROM[$n]=$from; MOE_TO[$n]=$to; MOE_T0[$n]=$t; t0=$t
    MOE_LAST=$t
  fi
  k=$(( dur > 0.0 ? (t - t0) / dur : 1.0 ))
  if (( k >= 1.0 )); then MV=$to; return 0; fi
  mo_out $k
  MV=$(( from + (to - from) * MK ))
  return 0
}
mo_forget() { unset "MOE_TO[$1]" "MOE_FROM[$1]" "MOE_T0[$1]" 2>/dev/null; return 0 }

# ── the table ──────────────────────────────────────────────────────────────
MO_XF_LINE=0.14; MO_XF_UNFOLD=0.34; MO_XF_SETTLE=0.52   # a page changing channel
MO_MODAL_IN=0.14; MO_MODAL_OUT=0.10                     # a question standing up / sitting down
MO_QUICK_IN=0.27; MO_QUICK_OUT=0.19                     # ...as a fraction of the channel change, for a full-glass question
MO_CURSOR=0.11                                          # the band under the cursor gliding
MO_TOAST=5.0; MO_TOAST_FADE=0.15                        # the coin door's message · its edges
MO_VALUE=0.35                                           # a reading easing to its new figure
MO_SLOW=0.35; MO_BREATHE=0.7; MO_ALERT=1.0              # the three pulses, in hertz
MO_BLINK=1.8                                            # every cursor and caret, in hertz

# ── the page transition · LINE, UNFOLD, SETTLE ─────────────────────────────
# A channel change on a tube: the picture drops to a bright line, the line
# opens back out onto the new picture, and the new picture settles through a
# breath of phosphor.  Both machines change page with it, and the cabinet
# changes machine with it, so a page is a channel and a machine is a channel
# and the reader learns one thing.
#
#   xf_arm            the next frame starts the transition
#   xf_busy           true while one is running or armed
#   xf_frame FN T     draw this frame · FN paints the standing picture
#
# -2.0 IS "STARTING, ON THE NEXT FRAME".  A key handler is not given the
# clock -- it has no business with one -- so the transition is armed there
# and the first frame that draws it writes down when it began.
XF_T0=-1.0
XF_ROW=''
typeset -F XF_SCALE=1.0
xf_arm()  { XF_T0=-2.0; XF_SCALE=${1:-1.0}; glass_unbake }   # xf_arm [SCALE] · a scale under 1 is a quicker change · the glass is about to change hands
xf_off()  { XF_T0=-1.0 }
xf_busy() { (( XF_T0 == -2.0 || XF_T0 >= 0.0 )) }
xf_row_init() {
  [[ ${#XF_ROW} == $SCR_W ]] && return 0
  local -i i
  XF_ROW=''
  for (( i = 0; i < SCR_W; i++ )); do XF_ROW+=' '; done
  return 0
}
xf_raster() {   # xf_raster HH K — the band, collapsing or opening
  local -i hh=$1 y0 yy
  local -F k=$2 d a half
  half=$(( hh / 2.0 )); (( half < 1.0 )) && half=1.0
  y0=$(( (SCR_H - hh) / 2 ))
  for (( yy = y0; yy < y0 + hh; yy++ )); do
    (( yy < 0 || yy >= SCR_H )) && continue
    d=$(( abs(yy - (SCR_H - 1) / 2.0) / half ))
    a=$(( (1.0 - d * 0.5) * (0.30 + 0.70 * k) ))
    cshade $XF_CORE $a
    v_text 0 $yy "$XF_ROW" -1 $CS
  done
  return 0
}
xf_blank_outside() {   # what the raster has not reached yet is unlit glass
  local -i y0=$1 hh=$2 yy
  for (( yy = 0; yy < SCR_H; yy++ )); do
    (( yy >= y0 && yy < y0 + hh )) && continue
    v_text 0 $yy "$XF_ROW" $GREY $BLACK
  done
  return 0
}
xf_frame() {   # xf_frame FN T
  local fn="$1"
  local -F t=$2 el k
  local -i hh y0
  xf_row_init
  (( XF_T0 == -2.0 )) && XF_T0=$t
  if (( XF_T0 < 0.0 )); then $fn $t; return 0; fi
  el=$(( XF_SCALE > 0.0 ? (t - XF_T0) / XF_SCALE : MO_XF_SETTLE ))
  if (( el >= MO_XF_SETTLE )); then XF_T0=-1.0; XF_SCALE=1.0; $fn $t; return 0; fi
  if (( el < MO_XF_LINE )); then
    # the picture is gone and the line it left is collapsing toward the centre
    mo_smooth $(( el / MO_XF_LINE )); k=$MK
    for (( hh = 0; hh < SCR_H; hh++ )); do v_text 0 $hh "$XF_ROW" $GREY $BLACK; done
    hh=$(( int((1.0 - k) * SCR_H) )); (( hh < 1 )) && hh=1
    xf_raster $hh $k
  elif (( el < MO_XF_UNFOLD )); then
    # the new picture, opening out of the line
    mo_smooth $(( (el - MO_XF_LINE) / (MO_XF_UNFOLD - MO_XF_LINE) )); k=$MK
    $fn $t
    hh=$(( int(k * SCR_H) )); (( hh < 1 )) && hh=1
    y0=$(( (SCR_H - hh) / 2 ))
    xf_blank_outside $y0 $hh
    post_wash $y0 $hh unfold $k
  else
    # ...and settling, through a breath of phosphor on alternate rows
    $fn $t
    mo_settle $(( (el - MO_XF_UNFOLD) / (MO_XF_SETTLE - MO_XF_UNFOLD) )) 0.30 0.15
    post_wash 0 $SCR_H settle $MK
  fi
  return 0
}

# ── a modal standing up, and sitting down ──────────────────────────────────
# A question that opens over a page unfolds from its own centre line in
# MO_MODAL_IN and folds back into it in MO_MODAL_OUT -- the raster's own
# gesture, at the size of the box.  The page under it is kept while it
# opens: the box is drawn whole, then the rows the fold has not reached are
# put back from the page.
#
#   modal_open           the next frame starts the box opening
#   modal_close          the next frame starts it folding away
#   modal_busy           a fold is in progress (the box must still be drawn)
#   modal_gone           the fold-away finished this frame (clear your flag)
#   modal_frame X Y W H FN T   draw the box through FN, folded as far as it is
#
# AND THE PAGE BEHIND IT RECEDES.  A box drawn straight onto a page of the
# same ink and the same ground is more of the page; the backdrop darkens and
# mutes everything outside the box, in step with the fold, so the box comes
# up lit and the page comes back as the box sits down.  The foot rows are
# the box's own -- its hints are written there -- and are left lit.
typeset -F MD_T0=-1.0
typeset -i MD_DIR=0 MD_GONE=0 MD_FOOT=3
typeset -ga MDS_C MDS_F MDS_B
modal_open()  { MD_T0=-2.0; MD_DIR=1; MD_GONE=0 }
modal_close() { MD_T0=-2.0; MD_DIR=-1; MD_GONE=0 }
modal_busy()  { (( MD_T0 == -2.0 || MD_T0 >= 0.0 )) }
modal_gone()  { (( MD_GONE )) }
modal_reset() { MD_T0=-1.0; MD_DIR=0; MD_GONE=0 }
modal_frame() {   # modal_frame X Y W H FN T
  local -i x=$1 y=$2 w=$3 h=$4
  local fn="$5"
  local -F t=$6 k dur
  local -i yy hh y0 y1 k0 base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  MD_GONE=0
  (( MD_T0 == -2.0 )) && MD_T0=$t
  if (( MD_T0 < 0.0 )); then $fn $t; post_backdrop $x $y $w $h 1.0 $(( SCR_H - MD_FOOT )); return 0; fi
  dur=$MO_MODAL_IN; (( MD_DIR < 0 )) && dur=$MO_MODAL_OUT
  k=$(( dur > 0.0 ? (t - MD_T0) / dur : 1.0 ))
  if (( k >= 1.0 )); then
    if (( MD_DIR < 0 )); then MD_T0=-1.0; MD_DIR=0; MD_GONE=1; return 0; fi
    MD_T0=-1.0; MD_DIR=0; $fn $t; post_backdrop $x $y $w $h 1.0 $(( SCR_H - MD_FOOT )); return 0
  fi
  mo_out $k; k=$MK
  (( MD_DIR < 0 )) && k=$(( 1.0 - k ))
  # the page under the box, kept
  MDS_C=(); MDS_F=(); MDS_B=()
  for (( yy = 0; yy < h; yy++ )); do
    k0=$(( base + (y + yy) * TCOLS + x ))
    MDS_C+=("${(@)GCH[@]:$k0:$w}"); MDS_F+=("${(@)GF[@]:$k0:$w}"); MDS_B+=("${(@)GB[@]:$k0:$w}")
  done
  $fn $t
  hh=$(( int(k * h + 0.5) )); (( hh < 1 )) && hh=1
  y0=$(( (h - hh) / 2 )); y1=$(( y0 + hh ))
  for (( yy = 0; yy < h; yy++ )); do
    (( yy >= y0 && yy < y1 )) && continue
    k0=$(( base + (y + yy) * TCOLS + x ))
    GCH[$k0,$(( k0 + w - 1 ))]=("${(@)MDS_C[@]:$(( yy * w )):$w}")
    GF[$k0,$(( k0 + w - 1 ))]=("${(@)MDS_F[@]:$(( yy * w )):$w}")
    GB[$k0,$(( k0 + w - 1 ))]=("${(@)MDS_B[@]:$(( yy * w )):$w}")
  done
  # the backdrop comes up with the fold, and the cutout is the box as far as
  # it has opened -- what the fold has not reached is still the page, behind
  post_backdrop $x $(( y + y0 )) $w $hh $k $(( SCR_H - MD_FOOT ))
  # the fold's own edges carry a little of the phosphor while they move
  local -F a=$(( (1.0 - k) * 0.55 ))
  local -i xx c
  if (( a > 0.02 )); then
    for yy in $y0 $(( y1 - 1 )); do
      k0=$(( base + (y + yy) * TCOLS + x ))
      for (( xx = 0; xx < w; xx++ )); do
        c=${GB[$(( k0 + xx ))]}; (( c < 0 )) && c=$BLACK
        cmix $c $XF_CORE $a; GB[$(( k0 + xx ))]=$CM
      done
    done
  fi
  return 0
}
cmix $WHITE $CYAN 0.22; XF_CORE=$CM
cshade $GLASS 0.5; BD_CORE=$CS         # the unlit tube, a shade darker than the glass


# ══════════════════════════════════════════════════════════════════════════
# SECTION 5b · THE BEAT           arcade.py's frame governor, in zsh
# ══════════════════════════════════════════════════════════════════════════
# THE MACHINE RUNS AT THE DISPLAY'S OWN REFRESH RATE when it can keep up, and
# otherwise at an EXACT DIVISOR of it.  That second half is the whole point
# and it is arcade.py's: locking to a divisor is what makes motion buttery
# rather than merely fast, because every frame lands on a real display
# refresh instead of drifting across them.  A cabinet painting at twenty-two
# frames a second on a sixty hertz panel shows every third frame twice and
# every fourth frame once, and the eye reads that as a stutter even though
# nothing has dropped.  Twenty is slower and looks smoother.
#
# THE OLD TERMINAL DID NOT DO THIS AT ALL.  It parsed --fps, ignored it, and then
# slept a flat twelfth of a second between keys -- so it ran at whatever was
# left after a repaint, on every machine, against every panel.
#
# ── HOW THE RATE IS FOUND ──  Three ways, cheapest first, and none of them
# is a dependency:
#
#   ALIEN_FPS     · a harness said so.  Believed, clamped, and that is that.
#   CoreGraphics  · the window server's own answer, in microseconds, through
#                   python3's ctypes.  arcade.py's first probe, and python3
#                   is asked for POLITELY here: if it is not on this machine
#                   TERMINAL does not care, which is the whole reason this
#                   file carries its own sprites.
#   system_profiler · the slow one.  Built-in panels often report zero
#                   through CoreGraphics, and this takes whole seconds -- so
#                   it is started in the BACKGROUND and read when it lands,
#                   exactly as arcade.py hands it to a thread rather than
#                   staring at a black window while it runs.
#
# ...and sixty until one of them answers, because sixty is what nearly every
# panel is and a wrong guess costs one adjustment.
FPS_FLOOR=5.0                        # a shell is not a game engine
FPS_CEIL=144.0
HZ=60.0
HZ_PROBE=''                          # where the slow answer will land
typeset -ga LADDER
RUNG=0; FPS=30.0; NEXT_FRAME=0.0
WORK_AVG=0.0; HOT=0; COOL=0
FPS_SEEN=0.0; FPS_N=0; FPS_T0=0.0    # what it is ACTUALLY managing

_hz_coregraphics() {
  # The window server, asked directly.  python3 is optional here and nothing
  # below it depends on the answer.
  local py c out
  for c in python3 /usr/bin/python3; do
    whence -p "$c" >/dev/null 2>&1 && { py="$c"; break }
  done
  [[ -n "${py:-}" ]] || return 1
  out="$("$py" - <<'PYEOF' 2>/dev/null
import ctypes, ctypes.util, sys
try:
    path = (ctypes.util.find_library("CoreGraphics")
            or "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
    cg = ctypes.CDLL(path)
    cg.CGMainDisplayID.restype = ctypes.c_uint32
    cg.CGDisplayCopyDisplayMode.restype = ctypes.c_void_p
    cg.CGDisplayCopyDisplayMode.argtypes = [ctypes.c_uint32]
    cg.CGDisplayModeGetRefreshRate.restype = ctypes.c_double
    cg.CGDisplayModeGetRefreshRate.argtypes = [ctypes.c_void_p]
    cg.CGDisplayModeRelease.argtypes = [ctypes.c_void_p]
    cg.CGDisplayPixelsWide.restype = ctypes.c_size_t
    cg.CGDisplayPixelsHigh.restype = ctypes.c_size_t
    cg.CGDisplayPixelsWide.argtypes = [ctypes.c_uint32]
    cg.CGDisplayPixelsHigh.argtypes = [ctypes.c_uint32]
    d = cg.CGMainDisplayID()
    m = cg.CGDisplayCopyDisplayMode(d)
    if m:
        hz = float(cg.CGDisplayModeGetRefreshRate(m))
        cg.CGDisplayModeRelease(m)
        sys.stdout.write("%.3f %d %d" % (hz, cg.CGDisplayPixelsWide(d),
                                         cg.CGDisplayPixelsHigh(d)))
except Exception:
    pass
PYEOF
)" || return 1
  local -a f; f=(${=out})
  [[ "${f[0]:-}" == (<->.<->|<->) ]] || return 1
  (( ${f[0]} >= 20.0 )) || return 1
  HZ=${f[0]}
  [[ "${f[1]:-}" == <-> && "${f[2]:-}" == <-> ]] && SPEC_PANEL="${f[1]} x ${f[2]}"
  return 0
}

_hz_probe_start() {
  # THE SLOW ONE, OFF TO ONE SIDE.  system_profiler can take seconds; nothing
  # here waits on it, and if it never lands TERMINAL simply keeps the rate it
  # already has.
  (( IS_MAC )) || return 0
  whence -p system_profiler >/dev/null 2>&1 || return 0
  HZ_PROBE="$(mktemp -t alien-hz.XXXXXX 2>/dev/null)" || { HZ_PROBE=''; return 0 }
  rm -f "$HZ_PROBE" 2>/dev/null
  # WRITTEN BESIDE ITSELF AND MOVED OVER.  The reader polls this path every
  # frame, and `-s` is true the moment the report's first block lands -- so a
  # half-written file was being parsed for its largest hertz figure and then
  # DELETED, which loses the probe for good.  A rename is atomic: the path
  # either does not exist or holds the whole report.
  { { system_profiler SPDisplaysDataType > "$HZ_PROBE.part" 2>/dev/null \
      && mv -f "$HZ_PROBE.part" "$HZ_PROBE" 2>/dev/null } &! } 2>/dev/null
  return 0
}
_hz_probe_read() {
  # ...and read once, when it is there.  The largest hertz figure in the
  # report is the panel this window is most likely on.
  [[ -n "$HZ_PROBE" ]] || return 1
  [[ -f "$HZ_PROBE" && -s "$HZ_PROBE" ]] || return 1
  local line best=0.0 v
  while IFS= read -r line; do
    [[ "$line" == *[Hh]z* ]] || continue
    for v in ${=line}; do
      [[ "$v" == <->.<->[Hh]z || "$v" == <->[Hh]z ]] || continue
      v="${v%[Hh]z}"
      (( v > best )) && best=$v
    done
  done < "$HZ_PROBE"
  rm -f "$HZ_PROBE" 2>/dev/null
  HZ_PROBE=''
  (( best >= 20.0 && best <= 480.0 )) || return 1
  HZ=$best
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# WHAT MACHINE THIS IS          the self test's own subject
# ══════════════════════════════════════════════════════════════════════════
# A POWER-ON SELF TEST THAT TESTS NOTHING IS A CARTOON.  The arcade's boots a
# Z80 and finds 512 KB of phosphor core, and that is right for a cabinet
# pretending to be from 1984 -- but this cabinet is a TERMINAL, standing on a real
# machine, and the one thing a self test is for is telling you what it found.
# So it reads the machine: the chip, the memory, the disk, the panel, the
# terminal, the shell, the system.  The chrome around it is still 1984.
#
# EVERY READING IS A SHELL COMMAND ALREADY, which is the same argument this
# file makes for the probe: `sysctl`, `df`, `uname`, `sw_vers`.  They are read
# ONCE, at power up, on the way into a card whose whole job is to show them --
# nine forks in the one place in this program where nine forks are the point.
SPEC_CPU=''; SPEC_RAM=''; SPEC_DISK=''; SPEC_PANEL=''; SPEC_ARCH=''; SPEC_OSB=''
# ...and HOW FULL, which is a different reading from how big.  The card says
# `994 GB · 512 GB FREE` because those are the two numbers a person quotes;
# the glass draws a bar, and a bar needs the ratio between them.
typeset -F SPEC_DISK_USE=0.0
_human_bytes() {   # HB = a size a person reads
  local -F v=$1
  if   (( v >= 1099511627776.0 )); then HB="$(printf '%.1f TB' $(( v / 1099511627776.0 )))"
  elif (( v >= 1073741824.0 ));    then HB="$(printf '%.0f GB' $(( v / 1073741824.0 )))"
  elif (( v >= 1048576.0 ));       then HB="$(printf '%.0f MB' $(( v / 1048576.0 )))"
  else                                  HB="$(printf '%.0f KB' $(( v / 1024.0 )))"; fi
}
specs_read() {
  local v
  local -a f
  local -i CORES=0
  if (( MOCK )); then
    # THE FIXTURE HAS A MACHINE TOO, and it has to: a self test is a card of
    # facts about the reader's own computer, and a preview committed to a
    # repo must not carry one of them.  Same suite, same night, same specs,
    # on anybody's Mac.
    SPEC_CPU='ALIEN AD-1 · 8 CORES · ARM64'; SPEC_ARCH='ARM64'
    SPEC_RAM='16 GB'; SPEC_DISK='994 GB · 512 GB FREE'
    SPEC_DISK_USE=0.485
    SPEC_PANEL='3456 x 2234'; SPEC_OSB='24F74'
    return 0
  fi
  SPEC_ARCH="$(uname -m 2>/dev/null)"
  SPEC_ARCH="${SPEC_ARCH//[^[:print:]]/·}"
  # ASKED OF THE MACHINE, NOT OF ITS NAME.  `sysctl` answers on a Mac and on
  # the BSDs and /proc answers on Linux, and which one is here is a question
  # with a one-line answer -- so it is asked that way rather than inferred
  # from $OSTYPE, which is a guess about which tool exists.
  if whence -p sysctl >/dev/null 2>&1 && [[ "$(sysctl -n hw.memsize 2>/dev/null)" == <-> ]]; then
    v="$(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
    [[ -n "$v" ]] || v="$(sysctl -n hw.model 2>/dev/null)"
    SPEC_CPU="${v//[^[:print:]]/·}"
    v="$(sysctl -n hw.ncpu 2>/dev/null)"
    [[ "$v" == <-> ]] && CORES=$v
    v="$(sysctl -n hw.memsize 2>/dev/null)"
    [[ "$v" == <-> ]] && { _human_bytes $v; SPEC_RAM="$HB" }
  fi
  if [[ -z "$SPEC_CPU" && -r /proc/cpuinfo ]]; then
    local -i ncore=0
    while IFS= read -r v; do
      [[ "$v" == processor*:* ]] && (( ncore++ ))
      [[ -n "$SPEC_CPU" ]] && continue
      [[ "$v" == 'model name'*:* || "$v" == 'Model name'*:* || "$v" == 'Model'*:* ]] \
        && { _trim "${v#*:}"; SPEC_CPU="$TR" }
    done < /proc/cpuinfo
    (( ncore )) && CORES=$ncore
    while IFS= read -r v; do
      [[ "$v" == MemTotal:* ]] && { f=(${=v}); _human_bytes $(( ${f[1]} * 1024 )); SPEC_RAM="$HB"; break }
    done < /proc/meminfo
  fi
  # JOINED, NOT CONCATENATED.  A separator printed either side of a reading
  # that is not there is a machine reporting `Xeon ·  · x86_64`, which reads
  # as a fault rather than as a missing figure.
  local -a bits
  [[ -n "$SPEC_CPU" ]] && bits+=("$SPEC_CPU")
  (( CORES )) && bits+=("$CORES CORES")
  [[ -n "$SPEC_ARCH" ]] && bits+=("$SPEC_ARCH")
  # ${(j:...:)NAME} IS ELEMENT ZERO under KSH_ARRAYS, not the array -- the
  # same trap the frame ladder fell into.  The subscript is what makes it the
  # whole of it.
  SPEC_CPU="${(j: · :)${bits[@]}}"
  # THE MARKETING COMES OFF.  `Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz` is
  # forty characters of which six are a trademark notice; every tool that has
  # ever printed a processor name has taken them off, and the card has a
  # column to keep to.
  SPEC_CPU="${SPEC_CPU//\(R\)/}"; SPEC_CPU="${SPEC_CPU//\(TM\)/}"
  SPEC_CPU="${SPEC_CPU// CPU / }"; SPEC_CPU="${SPEC_CPU// Processor/}"
  SPEC_CPU="${SPEC_CPU//  / }"
  _trim "$SPEC_CPU"; SPEC_CPU="$TR"
  SPEC_CPU="${SPEC_CPU//[^[:print:]]/·}"; SPEC_CPU="${SPEC_CPU[0,51]}"
  # the disk the repo is standing on, not somebody's idea of the disk
  if whence -p df >/dev/null 2>&1; then
    v="$( { df -k "$REPO" 2>/dev/null || df -k / 2>/dev/null; } | tail -1 )"
    f=(${=v})
    if (( ${#f[@]} >= 4 )) && [[ "${f[1]}" == <-> && "${f[3]}" == <-> ]]; then
      _human_bytes $(( ${f[1]} * 1024.0 )); local tot="$HB"
      _human_bytes $(( ${f[3]} * 1024.0 ))
      SPEC_DISK="$tot · $HB FREE"
      # AGAINST THE TWO FIGURES PRINTED, not against df's own `used`, which
      # on a Mac is smaller than total minus free by whatever the filesystem
      # is holding back -- and a bar that disagrees with the numbers beside
      # it is worse than no bar.
      (( ${f[1]} > 0 )) && SPEC_DISK_USE=$(( (${f[1]} - ${f[3]}) / (${f[1]} + 0.0) ))
    fi
  fi
  if (( IS_MAC )) && whence -p sw_vers >/dev/null 2>&1; then
    SPEC_OSB="$(sw_vers -buildVersion 2>/dev/null)"
    SPEC_OSB="${SPEC_OSB//[^[:print:]]/·}"
  fi
  return 0
}

fps_ladder() {   # fps_ladder HZ -> LADDER, low to high
  # THE RATE AND ITS INTEGER DIVISORS.  arcade.py stops at six because below
  # thirty nothing it draws is worth watching; a shell painting five thousand
  # cells needs the rungs underneath that, so this goes to sixteen and floors
  # at five.  Every rung is still hz/n, which is the only property that
  # matters: whatever it settles on, the frames land on real refreshes.
  local -F hz=$1 r
  local -i n hd
  local -a out
  local seen='' rs
  for (( n = 1; n <= 16; n++ )); do
    r=$(( hz / n ))
    (( r < FPS_FLOOR || r > FPS_CEIL )) && continue
    # TWO DECIMALS AND NO MORE.  A rung is a number a person may read off
    # --probe, and `8.5714285714285712` is not one.
    # NO EXTENDED_GLOB TO TRIM IT WITH, and none is set on purpose: this
    # file reads a conf with `${line%%#*}` in it, and under EXTENDED_GLOB the
    # `#` in that is a repetition operator rather than a comment.  So the
    # trailing zeros come off with arithmetic, which needs no options at all.
    hd=$(( int(r * 100 + 0.5) ))
    if (( hd % 100 == 0 )); then rs="$(( hd / 100 ))"
    elif (( hd % 10 == 0 )); then rs="$(( hd / 100 )).$(( (hd % 100) / 10 ))"
    elif (( hd % 100 < 10 )); then rs="$(( hd / 100 )).0$(( hd % 100 ))"
    else rs="$(( hd / 100 )).$(( hd % 100 ))"; fi
    [[ " $seen " == *" $rs "* ]] && continue
    seen+=" $rs"
    out=($rs "${out[@]}")
  done
  (( ${#out[@]} )) || out=($(( hz < FPS_FLOOR ? FPS_FLOOR : (hz > FPS_CEIL ? FPS_CEIL : hz) )))
  LADDER=("${out[@]}")
  return 0
}

beat_reset() {   # the ladder, and where on it to start
  if (( OPT_FPS )); then
    LADDER=($(( OPT_FPS + 0.0 )))            # --fps PINS it, at the reader's word
  elif [[ -n "${ALIEN_FPS:-}" && "${ALIEN_FPS}" == (<->|<->.<->) ]]; then
    LADDER=($(( ALIEN_FPS < FPS_FLOOR ? FPS_FLOOR : (ALIEN_FPS > FPS_CEIL ? FPS_CEIL : ALIEN_FPS) )))
  else
    fps_ladder $HZ
  fi
  # START AT THE TOP AND LET THE GOVERNOR FIND THE FLOOR, which is arcade.py's
  # own choice: a machine that can hold the panel's rate should be given it,
  # and one that cannot finds out in half a second.
  RUNG=$(( ${#LADDER[@]} - 1 ))
  FPS=${LADDER[$RUNG]}
  HOT=0; COOL=0; NEXT_FRAME=0.0; WORK_AVG=0.0
  return 0
}

beat_govern() {   # beat_govern WORK — find the rung this machine can hold
  # Rungs are exact divisors of the refresh rate, so a step never lands on a
  # rate that beats against the display.
  #
  # IT SEEKS RATHER THAN WALKS, and that is not the same as arcade.py's.  A
  # cabinet that finds itself one rung too high steps down one and is right;
  # a TERMINAL that opens at sixty on a machine that can hold twelve is FOUR
  # rungs too high, and walking down them eight frames at a time is three
  # seconds of a machine visibly hunting for its own speed -- during the
  # opening, which is the first thing anybody sees.  The measured frame time
  # already says which rung is the right one, so it goes there.
  local -F work=$1 budget
  local -i want
  WORK_AVG=$(( WORK_AVG * 0.88 + work * 0.12 ))
  budget=$(( 1.0 / FPS ))
  if (( WORK_AVG > budget * 0.92 )); then
    COOL=0; (( HOT++ ))
    if (( HOT > 6 && RUNG > 0 )); then
      # the highest rung whose own budget this frame time would actually fit
      want=0
      for (( want = RUNG - 1; want > 0; want-- )); do
        (( 1.0 / ${LADDER[$want]} > WORK_AVG * 1.08 )) && break
      done
      RUNG=$want; FPS=${LADDER[$RUNG]}; HOT=0
    fi
  elif (( RUNG < ${#LADDER[@]} - 1 )) \
       && (( 1.0 / ${LADDER[$(( RUNG + 1 ))]} > WORK_AVG * 1.25 )); then
    HOT=0; (( COOL++ ))
    # ...and back up ONE at a time, slowly.  Coming down is a correction and
    # going up is a guess, so the guess is made cautiously and only after the
    # machine has been comfortable for a good three seconds.
    #
    # THE TEST IS THE NEXT RUNG'S OWN BUDGET, not a fraction of this one's.
    # arcade.py asks whether the frame fits in 45% of the CURRENT budget,
    # which is right on a machine running at a tenth of its capacity and is a
    # one-way ratchet on one running at the edge: at seven and a half frames
    # a second the test wants a sixty-millisecond frame before it will try
    # ten, and a machine that can comfortably hold ten takes eighty.  It
    # never climbed back.  Asking whether the frame fits the rung ABOVE, with
    # a quarter to spare, is the same question the step DOWN asks and it can
    # be answered yes.
    if (( COOL > 90 )); then
      (( RUNG++ )); FPS=${LADDER[$RUNG]}; COOL=0
    fi
  else
    HOT=0; COOL=0
  fi
  return 0
}

beat_gap() {   # beat_gap -> GAP, the seconds left in this frame's slot
  local -F now=$EPOCHREALTIME
  (( NEXT_FRAME <= 0.0 )) && NEXT_FRAME=$now
  NEXT_FRAME=$(( NEXT_FRAME + 1.0 / FPS ))
  GAP=$(( NEXT_FRAME - now ))
  if (( GAP <= 0.0 )); then
    # a frame that overran its slot does not try to make it up -- it takes
    # the next one from here, so a slow patch cannot turn into a sprint
    (( GAP < -0.25 )) && NEXT_FRAME=$now
    GAP=0.0005
  fi
  return 0
}

# ── THE OPENING'S OWN BEAT, WHICH IS THE VISIT'S ──────────────────────────
# THE OPENING HAD NO BEAT AT ALL.  Its three loops ran flat out and read the
# wall clock, and that is two mistakes with one symptom.
#
# RUNNING FLAT OUT means every frame costs whatever it happens to cost, and
# on these particular loops that cost MOVES: a raster two rows tall is
# cheaper to draw than one thirty rows tall, so the tube opening out gets
# steadily more expensive as it opens and the tube collapsing gets steadily
# cheaper as it collapses.  READING THE WALL CLOCK means that unevenness IS
# the motion -- a frame that took twice as long does not arrive late, it
# moves twice as far -- so the raster does not unfold at an even rate, it
# unfolds at the exact rate of its own drawing cost, decelerating into the
# middle and accelerating out of it.  Nobody could name that, and everybody
# could see it.
#
# The visit solved both of these for itself a long time ago -- the governor
# for the pacing, TANIM for the stride -- and never shared them, so the part
# of this program that stuttered was the part everybody sees first, every
# time, before anything else has had a chance to make an impression.
#
# So the opening gets them: the same ladder, the same governor, and a clock
# that advances by exactly one frame's worth per frame whatever the scheduler
# did with it.  Three details are worth their lines.
#
# THE WAIT IS A READ, not a sleep.  A `sleep` a frame is a FORK a frame, and
# a fork costs more than most of these frames do; `read -t` is a builtin, it
# waits just as accurately, and a key pressed in the middle of a slot is
# answered in the middle of it instead of at the end.  So the opening's key
# arrives through the same call that paces it, in OV_KEY.
#
# THE CLOCK MAY NOT DRIFT.  A machine that cannot hold its rung would
# otherwise run the whole opening in slow motion for ever, so once the clock
# has wandered a quarter second from the wall it is put back -- the visit's
# own threshold, for the visit's own reason.
#
# ...AND THE STRIDE IS THE SMOOTHED FRAME TIME, not the rung's nominal one.
# Stepping by exactly 1/FPS is what the visit does and it is right there,
# because the visit runs for minutes and settles.  An opening lasts four
# seconds and spends the first of them being measured: the governor opens at
# the panel's rate, discovers over seven frames that this machine manages a
# fifth of it, and steps down -- and for those seven frames a clock stepping
# by the NOMINAL rung advances an eighth of a second per half second of wall.
# That is not judder, it is SLOW MOTION, arriving exactly where the tube is
# finding itself, and then ending in a lurch when the rung lands.
#
# So the clock steps by how long the frames are ACTUALLY taking, rate-limited
# so that no step can be far from the one before it.  That is even, which is
# the whole of what the eye wanted, and it tracks the real rate, so the
# raster unfolds in the four seconds it says it will however fast the machine
# is.  It needs no drift guard and it cannot lurch: there is nothing to
# correct back to.  The outer clamp is only there so that one frame lost to a
# machine that went swapping cannot become half a second of animation
# delivered in a single step.
typeset -F OB_T=0.0 OB_W=0.0 OB_H=0.0 OB_STEP=0.0
OV_KEY=''
ob_start() {   # begin an opening loop's clock at zero
  OB_W=$EPOCHREALTIME; OB_T=0.0; OB_STEP=0.0
  NEXT_FRAME=0.0; HOT=0; COOL=0; OV_KEY=''
  return 0
}
ob_wait() {   # ob_wait SECONDS — burn the rest of the slot, or take a key
  local -F w=$1
  OV_KEY=''; OV_SEQ=''
  (( w < 0.0005 )) && w=0.0005
  [[ -t 0 ]] || { sleep $w; return 0 }
  IFS= read -rsk1 -u0 -t $w OV_KEY || OV_KEY=''
  # A WHEEL NOTCH DURING THE OPENING IS NOT A KEY.  The mouse is reported
  # from the moment the screen is taken (SECTION 18), and a report that
  # began with an escape read here would have skipped the opening and left
  # its tail in the buffer for the menu.  The sequence is read whole, and a
  # report is dropped where it lands; an arrow is a skip like any key.
  if [[ "$OV_KEY" == $'\e' ]]; then
    key_seq
    if (( MOUSE )); then OV_KEY=''; WH_N=0; else OV_SEQ="$KSEQ"; fi
  fi
  return 0
}
OV_SEQ=''
ob_beat() {   # ...and the end of a frame: govern it, pace it, step the clock
  local -F now dt work
  # A HELD CARD IS NOT A SLOW FRAME.  What the governor is handed is the time
  # this frame spent DRAWING -- and the frame that spans a hold spent almost
  # all of its time waiting for a person, ten seconds of it if that is how
  # long they looked.  Handed that as a measurement the governor concludes
  # the machine manages a tenth of a frame a second, seeks to the bottom
  # rung, and then has to climb back one careful step per ninety comfortable
  # frames -- which after a ten second hold is around two minutes of a menu
  # running at five.  Half a second is already hopeless by every rung's
  # standard, so nothing above it carries a measurement worth keeping, and
  # cutting it there costs the governor nothing it would have used.
  work=$(( $EPOCHREALTIME - OB_W ))
  (( work < 0.0 ))  && work=0.0
  (( work > 0.50 )) && work=0.50
  beat_govern $work
  beat_gap
  ob_wait $GAP
  now=$EPOCHREALTIME
  dt=$(( now - OB_W ))                 # the whole frame, its pacing included
  (( dt < 0.004 )) && dt=0.004
  (( dt > 0.50 ))  && dt=0.50
  # NO STEP MAY BE MUCH BIGGER OR SMALLER THAN THE ONE BEFORE IT, which is
  # the whole of what the eye was complaining about.  A frame that cost twice
  # as long moves the picture a third further rather than twice as far, and a
  # RUN of them walks the stride up to the new cost in three frames -- so a
  # real change of pace is followed quickly and a single slow frame is
  # absorbed.  A rate limit rather than an average, and the difference is not
  # academic here: these frames change cost by STAGE, a raster unfolding
  # being dearer than the same raster settling, and an average drags the old
  # stage's cost into the new one for as long as it takes to forget it --
  # which on a slow machine is most of the stage.
  (( OB_STEP <= 0.0 )) && OB_STEP=$dt
  if   (( dt > OB_STEP * 1.40 )); then OB_STEP=$(( OB_STEP * 1.40 ))
  elif (( dt < OB_STEP * 0.70 )); then OB_STEP=$(( OB_STEP * 0.70 ))
  else                                 OB_STEP=$dt
  fi
  OB_T=$(( OB_T + OB_STEP ))
  OB_W=$now
  return 0
}
# A KEY THE OPENING TOOK AND HAD NO USE FOR.  Every frame of the opening is
# paced by a READ, and a read takes whatever is there -- including, in the
# four frames of white between the self test and the menu, the keystroke of
# somebody still pressing to get past a card that has already gone.  Nothing
# in those four frames wants a key and the tty cannot be given one back, so
# it is left here for the visit to find.
PEND_KEY=''
ob_hold()  { OB_H=$EPOCHREALTIME }
# ...and coming back off a hold, the frame that spanned it is not a frame:
# forgetting when the last one ended is what stops five held seconds being
# delivered as one enormous step.
ob_go_on() { OB_W=$EPOCHREALTIME; NEXT_FRAME=0.0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 6 · THE BLOCK FONT      arcade.py's section 7
# ══════════════════════════════════════════════════════════════════════════
# Five rows tall, five columns wide, one column of kerning.  The whole
# alphabet is carried because the gate and the cards spell things the marquee
# never does, and a font missing a letter is a word with a hole in it.
typeset -gA FONT5
_f() { FONT5[$1]="$2 $3 $4 $5 $6" }
FONT_SP=' '
_f ' ' '.....' '.....' '.....' '.....' '.....'
_f , '.....' '.....' '.....' '..#..' '.#...'
_f A '.###.' '#...#' '#####' '#...#' '#...#'
_f B '####.' '#...#' '####.' '#...#' '####.'
_f C '.####' '#....' '#....' '#....' '.####'
_f D '####.' '#...#' '#...#' '#...#' '####.'
_f E '#####' '#....' '####.' '#....' '#####'
_f F '#####' '#....' '####.' '#....' '#....'
_f G '.####' '#....' '#..##' '#...#' '.###.'
_f H '#...#' '#...#' '#####' '#...#' '#...#'
_f I '#####' '..#..' '..#..' '..#..' '#####'
_f J '....#' '....#' '....#' '#...#' '.###.'
_f K '#...#' '#..#.' '###..' '#..#.' '#...#'
_f L '#....' '#....' '#....' '#....' '#####'
_f M '#...#' '##.##' '#.#.#' '#...#' '#...#'
_f N '#...#' '##..#' '#.#.#' '#..##' '#...#'
_f O '.###.' '#...#' '#...#' '#...#' '.###.'
_f P '####.' '#...#' '####.' '#....' '#....'
_f Q '.###.' '#...#' '#...#' '#..#.' '.##.#'
_f R '####.' '#...#' '####.' '#..#.' '#...#'
_f S '.####' '#....' '.###.' '....#' '####.'
_f T '#####' '..#..' '..#..' '..#..' '..#..'
_f U '#...#' '#...#' '#...#' '#...#' '.###.'
_f V '#...#' '#...#' '#...#' '.#.#.' '..#..'
_f W '#...#' '#...#' '#.#.#' '##.##' '#...#'
_f X '#...#' '.#.#.' '..#..' '.#.#.' '#...#'
_f Y '#...#' '.#.#.' '..#..' '..#..' '..#..'
_f Z '#####' '...#.' '..#..' '.#...' '#####'
_f 0 '.###.' '#..##' '#.#.#' '##..#' '.###.'
_f 1 '..#..' '.##..' '..#..' '..#..' '.###.'
_f 2 '.###.' '#...#' '..##.' '.#...' '#####'
_f 3 '####.' '....#' '.###.' '....#' '####.'
_f 4 '#..#.' '#..#.' '#####' '...#.' '...#.'
_f 5 '#####' '#....' '####.' '....#' '####.'
_f 6 '.###.' '#....' '####.' '#...#' '.###.'
_f 7 '#####' '....#' '...#.' '..#..' '..#..'
_f 8 '.###.' '#...#' '.###.' '#...#' '.###.'
_f 9 '.###.' '#...#' '.####' '....#' '.###.'
_f - '.....' '.....' '.###.' '.....' '.....'
_f . '.....' '.....' '.....' '.....' '..#..'
_f ! '..#..' '..#..' '..#..' '.....' '..#..'
_f ? '.###.' '#...#' '..##.' '.....' '..#..'
_f : '.....' '..#..' '.....' '..#..' '.....'
_f / '....#' '...#.' '..#..' '.#...' '#....'
_f '<' '...#.' '..#..' '.#...' '..#..' '...#.'
_f '>' '.#...' '..#..' '...#.' '..#..' '.#...'
_f '[' '.###.' '.#...' '.#...' '.#...' '.###.'
_f ']' '.###.' '...#.' '...#.' '...#.' '.###.'
_f '=' '.....' '.###.' '.....' '.###.' '.....'
_f '+' '.....' '..#..' '.###.' '..#..' '.....'
_f '*' '#.#.#' '.###.' '#####' '.###.' '#.#.#'
GLYPH_W=5; KERN=1; CELL_W=6

big_width() { BW=$(( ${#1} * CELL_W - KERN )); (( BW < 0 )) && BW=0; return 0 }

# ── the halo · arcade.py's kernel, weight for weight ────────────────────────
# A smooth two-cell bloom around every lit pixel, painted into the GROUND of
# the cells that are NOT lit.  That is what makes a word read as lit elements
# on a panel rather than as text: the letters write glyphs, the bloom writes
# grounds, and neither has to know about the other.
HALO_K=(-1,0,100 1,0,100 0,-1,80 0,1,80 -1,-1,45 1,-1,45 -1,1,45 1,1,45 \
        -2,0,26 2,0,26 0,-2,14 0,2,14)
typeset -ga BIGX BIGY HALX HALY HALV
BIGN=0; HALN=0

big_shape() {   # big_shape STR X Y -> BIGX/BIGY (lit) and HALX/HALY/HALV (bloom)
  local s="${1:u}"
  local -i x0=$2 y0=$3 li ry rx gx gy hx hy hw
  local -a rows
  local g h rest key
  typeset -A lit halo
  lit=(); halo=()
  BIGX=(); BIGY=(); HALX=(); HALY=(); HALV=()
  for (( li = 0; li < ${#s}; li++ )); do
    # THE BLANK IS LOOKED UP THROUGH A VARIABLE.  `${FONT5[' ']}` asks for a
    # key with the quote marks in it, which nothing ever stored -- so a glyph
    # the font did not have was not a blank, it was an unset read, and under
    # set -u that is the shell ending.  A comma in a big score found it.
    rows=(${=FONT5[${s[$li]}]:-${FONT5[$FONT_SP]}})
    for (( ry = 0; ry < 5; ry++ )); do
      g="${rows[$ry]}"
      for (( rx = 0; rx < GLYPH_W; rx++ )); do
        [[ "${g[$rx]}" == '#' ]] || continue
        lit[$(( x0 + li * CELL_W + rx )),$(( y0 + ry ))]=1
      done
    done
  done
  for key in "${(k)lit[@]}"; do
    gx=${key%%,*}; gy=${key##*,}
    # THE LOOP VARIABLE IS NOT AN INTEGER, and once it was: a `-i` parameter
    # handed "-1,0,100" takes the ARITHMETIC of it, and the comma operator
    # answers 100 -- so every weight came out the same and the bloom was a
    # solid block.  It is a string here, and split by hand.
    for h in "${HALO_K[@]}"; do
      hx="${h%%,*}"; rest="${h#*,}"; hy="${rest%%,*}"; hw="${rest##*,}"
      local q="$(( gx + hx )),$(( gy + hy ))"
      [[ -n "${lit[$q]:-}" ]] && continue
      halo[$q]=$(( ${halo[$q]:-0} + hw ))
    done
    BIGX+=($gx); BIGY+=($gy)
  done
  for key in "${(k)halo[@]}"; do
    HALX+=(${key%%,*}); HALY+=(${key##*,})
    local -F v=$(( ${halo[$key]} / 100.0 * 0.42 ))
    (( v > 1.0 )) && v=1.0
    HALV+=($v)
  done
  BIGN=${#BIGX[@]}; HALN=${#HALX[@]}
  return 0
}

# ── the same word, the same place, the same bloom · remembered ──────────────
# THE GATE AND THE INSTALLER ASKED FOR THE SHAPE EVERY FRAME -- two associative
# arrays rebuilt from the font, twelve kernel taps per lit pixel, and then a
# cmix per bloom cell -- to paint a word that has not moved since the page
# stood up.  Sixty milliseconds a frame, on the two pages whose only motion
# is a pulse.  The shape is worked out once per (word, place) and the bloom's
# tints once per (word, place, glow); a frame only has to lay them down.
typeset -gA BIG_MEMO HALO_MEMO
big_word() {   # big_word STR X Y GLOW — the bloom into the grounds, the shape into BIGX/BIGY
  local key="$1|$2|$3" hkey="$1|$2|$3|$4"
  local -i i k base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  if [[ -z "${BIG_MEMO[$key]:-}" ]]; then
    big_shape "$1" $2 $3
    BIG_MEMO[$key]="${(j: :)BIGX[@]}|${(j: :)BIGY[@]}|${(j: :)HALX[@]}|${(j: :)HALY[@]}|${(j: :)HALV[@]}"
  else
    local -a parts
    parts=("${(@s:|:)BIG_MEMO[$key]}")
    BIGX=(${=parts[0]}); BIGY=(${=parts[1]}); HALX=(${=parts[2]}); HALY=(${=parts[3]}); HALV=(${=parts[4]})
    BIGN=${#BIGX[@]}; HALN=${#HALX[@]}
  fi
  local -a tint
  if [[ -z "${HALO_MEMO[$hkey]:-}" ]]; then
    for (( i = 0; i < HALN; i++ )); do
      cmix $GLASS $4 $(( 0.135 * HALV[$i] ))
      tint+=($CM)
    done
    HALO_MEMO[$hkey]="${(j: :)tint[@]}"
  else
    tint=(${=HALO_MEMO[$hkey]})
  fi
  for (( i = 0; i < HALN; i++ )); do
    (( HALX[$i] < 0 || HALX[$i] >= SCR_W || HALY[$i] < 0 || HALY[$i] >= SCR_H )) && continue
    GB[$(( base + HALY[$i] * TCOLS + HALX[$i] ))]=${tint[$i]}
  done
  return 0
}
big_lit() {   # big_lit INK — the lit pixels, after big_word
  local -i i base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR )) k
  for (( i = 0; i < BIGN; i++ )); do
    (( BIGX[$i] < 0 || BIGX[$i] >= SCR_W || BIGY[$i] < 0 || BIGY[$i] >= SCR_H )) && continue
    k=$(( base + BIGY[$i] * TCOLS + BIGX[$i] ))
    GCH[$k]='█'; GF[$k]=$1
  done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 7 · THE TWO FILES BESIDE THIS ONE
# ══════════════════════════════════════════════════════════════════════════
# terminal.conf is every setting the suite has and terminal.save is every
# machine's progress, and TERMINAL reads both and writes exactly two lines of
# one of them.  The old TERMINAL borrowed scripts/universal/save.zsh for this --
# four hundred and seventy lines that also WRITE the save, lock it, quote it
# and walk its children, none of which TERMINAL has ever needed.
#
# WHAT IS KEPT IS THE CONTRACT, not the code: a conf is `key = value` with
# `#` comments and the last spelling of a key wins; a save is one flattened
# dotted path a line with a JSON scalar on the right.  A key TERMINAL does
# not know is a key it leaves alone, which is what makes it safe for five
# programs to share one file none of them has a schema for.
# TERMINAL READS ONE OF THE TWO FILES BESIDE IT, and it used to read both.
# terminal.conf is every setting the suite has, and the only key in it
# TERMINAL ever wanted was `sound` -- so when the switch went, the reader,
# the writer and the in-place rewriter that kept another machine's keys
# intact went with it.  A hundred lines that answered a question nobody
# asks.  The file is still there and still belongs to the suite; TERMINAL
# simply has no opinion about it.
#
# terminal.save is the other one: every machine's progress, one flattened
# dotted path a line with a JSON scalar on the right.  The animal next door
# and the arcade's coin bank are read out of it, which is what puts them on
# the glass -- so that half stays, and a key it does not know is a key it
# leaves alone.
SAVE_FILE="$REPO/terminal.save"
[[ -f "$SAVE_FILE" ]] || SAVE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/alien/terminal.save"
[[ -n "${ALIEN_SAVE:-}" ]] && SAVE_FILE="${ALIEN_SAVE/#\~/$HOME}"
typeset -gA SAVE
# ...AND WHAT WAS FOUND, kept for the self test to say out loud.  A reader who
# has just carried a save over from another Mac has no other way to know the
# cabinet actually picked it up: a save that was read and a save that was not
# found look identical until the first machine opens and the progress is not
# there.  found · empty · unreadable · none, and how many keys came in.
typeset -g  SAVE_STATE='none'
typeset -gi SAVE_KEYS=0

_trim() {   # TR = $1 without its outer whitespace, and no fork
  TR="$1"
  while [[ "$TR" == [[:space:]]* ]]; do TR="${TR#?}"; done
  while [[ "$TR" == *[[:space:]] ]]; do TR="${TR%?}"; done
  return 0
}

save_load() {
  SAVE=()
  local line k v
  local -i n=0
  SAVE_KEYS=0
  if [[ ! -e "$SAVE_FILE" ]]; then SAVE_STATE='none'; return 0; fi
  if [[ ! -f "$SAVE_FILE" || ! -r "$SAVE_FILE" ]]; then SAVE_STATE='unreadable'; return 0; fi
  while IFS= read -r line || [[ -n "$line" ]]; do
    (( ++n > 20000 )) && break
    line="${line%$'\r'}"
    # TRIMMED ONLY WHERE THERE IS SOMETHING TO TRIM.  Three calls a line was
    # three thousand function calls for a save with every table dealt, and
    # this reader runs after every write the arcade makes; a line, key or
    # value with no space at either end is already what _trim would hand back.
    [[ "$line" == [[:space:]]* || "$line" == *[[:space:]] ]] && { _trim "$line"; line="$TR" }
    [[ -n "$line" && "$line" != '#'* ]] || continue
    [[ "$line" == *'='* ]] || continue
    k="${line%%=*}"; v="${line#*=}"
    [[ "$k" == [[:space:]]* || "$k" == *[[:space:]] ]] && { _trim "$k"; k="$TR" }
    [[ "$v" == [[:space:]]* || "$v" == *[[:space:]] ]] && { _trim "$v"; v="$TR" }
    [[ -n "$k" ]] && SAVE[$k]="$v"
  done < "$SAVE_FILE"
  SAVE_KEYS=${#SAVE[@]}
  (( SAVE_KEYS )) && SAVE_STATE='found' || SAVE_STATE='empty'
  return 0
}
save_get() {   # save_get PATH [DEFAULT] — what that scalar stands for
  local v="${SAVE[$1]:-}"
  [[ -n "$v" ]] || { print -r -- "${2:-}"; return 1 }
  if [[ "$v" == '"'*'"' ]]; then
    v="${v[1,-2]}"
    v="${v//\\\"/\"}"; v="${v//\\\\/\\}"; v="${v//\\n/ }"
  fi
  print -r -- "$v"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 8 · THE ROSTER          a row per machine, and one for the house
# ══════════════════════════════════════════════════════════════════════════
# SIX FIELDS A MACHINE, in the order the Python TERMINAL kept them: the key that
# opens it, its name on the glass, the file it lives in, the name its tab
# wears, the line beside it, and the KIND of reading its row carries.  Kept
# as parallel arrays because zsh has no record and a six-column table read by
# eye is worth more than a packing scheme read by nobody.
M_KEY=(S I X A)
# SHORT ON THE ROSTER, FULL EVERYWHERE ELSE.  These are only the names the main
# menu wears on the glass, cut to a uniform six so the column reads as a set.  A
# machine's name in full is M_TAB below (the tab it opens in) and the PACK_NAME
# its own glass is signed with -- neither of which this line touches, so inside
# a machine it is still INTELLIGENCE and XENOGOTCHI.
M_NAME=(SYSTEM INTELL XENOGO ARCADE)
M_PATH=("scripts/suite/system.py" "scripts/suite/intelligence.py" \
        "scripts/suite/xenogotchi.py" "scripts/suite/arcade.py")
M_TAB=(SYSTEM INTELLIGENCE XENOGOTCHI ARCADE)
M_DESC=("the machine at once — scope, tapes, gauges" \
        "agents, models, and the prompt library" \
        "the adoption centre — one animal, one room" \
        "twelve cabinets, one coin a game")
M_KIND=(load agents pet credits)
# ...AND A SEVENTH, WHICH IS THE ONE THIS DOOR CAN ACTUALLY STAND IN.  A
# machine's own file is a whole program with a cabinet of its own -- 122 x 43
# of walls, neon, bezel and coin door, drawn in Python because at the time
# nothing else was going to draw them.  Something else is now, and it is
# already running and already standing the same cabinet at the same row map,
# so what the machine needs to hand over is the part that was ever really its
# own: the readings and the pictures.  That is the PACK.  A machine with one
# opens IN this glass; a machine without still opens the old way, in a tab.
M_PACK=("scripts/suite/system.zsh" "scripts/suite/intelligence.zsh" "scripts/suite/xenogotchi.zsh" "scripts/suite/arcade.zsh")
M_N=${#M_KEY[@]}

# ══════════════════════════════════════════════════════════════════════════
# THE SURFACE · which machine is standing in the cabinet
# ══════════════════════════════════════════════════════════════════════════
# ONE CABINET, MORE THAN ONE MACHINE IN IT.  The walls, the tube, the beat,
# the governor, the night and the coin door all belong to the door and stay
# where they are; what changes when a reader presses [S] is the GLASS and the
# handful of words silk-screened around it.  Those words are named here so a
# machine can set them without knowing how any of them are drawn -- and so
# that TERMINAL, which is a surface like any other, sets them the same way.
UI_SURF=''                # '' is TERMINAL's own menu · otherwise a machine key
SURF_MODEL='AD-1'         # the plate let into the bezel's lip
SURF_SIGN=''              # ...and the sign centred between it and the series
SURF_TAG=''               # the coin door's middle line
SURF_KEYS=''              # the control panel's second row
SURF_BADGE=''             # ...and the lit badge at the end of the coin door
SURF_MSG=''               # what the door says when it has nothing else to
PACK_AT=''                # which pack file is sourced, if any
# ...AND EVERY PACK THAT HAS EVER STOOD, WITH THE HOOKS IT DECLARED.  A pack
# is sourced ONCE per cabinet: sourcing runs its top level, and its top level
# is where its tables are declared and zeroed -- so a cabinet that went from
# INTELLIGENCE to SYSTEM and back sourced INTELLIGENCE a second time and
# wiped its console, its bench, its rewrite and the install that was running
# in its strip, which ran on with nothing left holding its pid.  Walking
# back into a machine is now its hooks put back and a repaint.
typeset -gA PACK_SEEN     # pack path → its eleven hooks, joined on \x1e
PACK_NAME=''; PACK_MODEL=''
# A MACHINE SAYS WHETHER THE PAGE IT IS SHOWING CAN FILL THE WINDOW.  Fill mode
# stretches the glass to the whole terminal only for surfaces that have a fill
# layout; a page that has not been given one yet keeps the fixed cabinet glass,
# centred on the lit fill, so it reads as itself rather than as a stretch.  The
# pack raises this per page as each one is taught to reflow; default off.
typeset -gi PACK_FILL=0
PACK_INIT=''; PACK_TICK=''; PACK_DRAW=''; PACK_KEY=''; PACK_DRESS=''
# ...AND A SIXTH, WHICH IS THE WAY OUT.  A machine that starts real processes
# -- an installer, an agent, a request that streams -- owns them, and the door
# is the only thing that knows when the cabinet is going down.  Without this
# hook a `curl | bash` started on the glass outlived the program that started
# it, with nothing left anywhere to stop it or say it was running.
PACK_LEAVE=''
# ...WHICH IS THE LAST PACK'S.  A cabinet that has visited two machines has
# two packs standing, and the hook names one of them; a pack whose way out
# must run whichever machine was opened last registers it here instead, and
# cleanup runs them all.  A pack sourced twice registers once.
typeset -ga PACK_EXITS
pack_at_exit() {   # pack_at_exit FN
  local f
  for f in "${(@)PACK_EXITS[@]}"; do [[ "$f" == "$1" ]] && return 0; done
  PACK_EXITS+=("$1")
  return 0
}
# ...AND TWO FOR THE LOADING SCREEN (SECTION 22b).  Every machine is read in
# behind the stars at power-on, so opening one is a repaint and not a wait.
#   PACK_WARM    `${PACK_WARM} N T` -- step N of getting ready ahead of time,
#                at the cabinet's clock T.  Answers 0 for a step taken (ask
#                for the next), 1 for nothing left, 2 for not yet (ask again).
#   PACK_FIRST   what opening the machine means to the reader -- a visit
#                counted, the save read as it stands NOW, a clock caught up --
#                and so is NOT done ahead of time.  Run once, when the door is
#                first opened onto it, right where INIT used to run.
# A machine that declares neither is read in and started early all the same.
PACK_WARM=''; PACK_FIRST=''
# ── AND ONE MORE, FOR A MACHINE THAT IS RUNNING SOMETHING WITH A KEYBOARD ──
# A pack that puts a terminal on the glass needs the bytes, not the names.
# The door asks `${PACK_RAW} want` before it parses anything; only if the
# pack says yes do the bytes go to it instead, and a pack that never says yes
# -- which is every pack that is not showing a terminal -- sees exactly the
# key loop it always saw.
PACK_RAW=''

surf_dress() {   # the chrome, for whichever surface is standing
  if [[ -n "$UI_SURF" && -n "$PACK_DRESS" ]]; then
    ${PACK_DRESS}
    return 0
  fi
  SURF_MODEL='AD-1'; SURF_SIGN=''
  SURF_TAG='ALIEN DYNAMICS · AD-1 · TERMINAL'
  panel_keys; SURF_KEYS="$PANEL_KEYS"
  SURF_BADGE=''            # the door's own badge is the mirror's, drawn live
  SURF_MSG=''
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 9 · THE MENU            what TERMINAL OFFERS, not what it opens
# ══════════════════════════════════════════════════════════════════════════
# The glass used to carry the five machines, a row apiece, and it was the
# wrong list.  Every one of those rows could REFUSE -- a machine whose file
# is missing, or whose interpreter is not on this PATH, is a row that draws
# perfectly and does nothing -- and on a Mac with no command line tools that
# is four rows of five, with the fifth (the house) refusing too because it
# opens the same four.  What was left that actually acted was INSTALL, which
# is why TERMINAL felt like it had one key however many rows it drew.
#
# A menu of things that do not happen is not a menu.  So the roster is the
# ACTIONS, and the machines are what an action opens.  There are two shapes,
# and the machine decides which one is standing:
#
#     not installed        [N] INSTALL    [R] RESCAN
#     installed            [T] TERMINAL   [E] RESET   [R] RESCAN
#
# INSTALLED MEANS TERMINAL could actually open the house if it were asked:
# the mirror linked, every machine's file in the folder, and every machine's
# interpreter on this PATH.  Anything short of that and the row is INSTALL,
# with the reading beside it saying what is short -- one row that says the
# true thing, in place of five that each said it separately and then did
# nothing about it.
#
# AND THE MACHINES ARE STILL ON THE GLASS, in the readout under the menu,
# where a thing you cannot press belongs.  That is the whole argument the old
# TERMINAL made for taking them off the menu and it is the one this keeps: the
# menu is what happens when you press it, the readout is what is true.
U_KEY=(); U_NAME=(); U_DESC=(); U_ACT=(); U_KIND=(); U_WHY=(); U_ACC=()
R_N=0
# HOW MANY OF THE ROWS ARE THE SUITE'S.  The machines sit behind them in the
# same list -- one cursor, one ⏎, every openable thing on the glass reached
# the same way -- but they are drawn in their own box, so the split has to be
# written down somewhere and this is it.  A machine's index is its row minus
# this, which is why there is no second array to keep in step with the first.
S_N=0
UI_ROW=0

INSTALLED_WHY=''
installed_p() {   # can this folder open its own house right now?
  local -i j
  INSTALLED_WHY=''
  # The three questions are asked in the order a reader would ask them, and
  # the FIRST one that answers no is the one U_WHY carries, because a row
  # that lists three faults is a row nobody reads to the end.
  if (( ! P_LEAVES )) || (( P_LINKED < P_LEAVES )); then
    INSTALLED_WHY="$P_LINKED of $P_LEAVES linked"
    return 1
  fi
  for (( j = 0; j < M_N; j++ )); do
    if (( ! ${P_HERE[${M_PATH[$j]}]:-0} )); then
      INSTALLED_WHY="no ${${M_PATH[$j]}:t}"
      return 1
    fi
  done
  for (( j = 0; j < M_N; j++ )); do
    if [[ -n "${P_NEEDS[${M_PATH[$j]}]:-}" ]]; then
      INSTALLED_WHY="needs ${P_NEEDS[${M_PATH[$j]}]}"
      return 1
    fi
  done
  return 0
}

menu_build() {
  local -i was=$R_N
  U_KEY=(); U_NAME=(); U_DESC=(); U_ACT=(); U_KIND=(); U_WHY=(); U_ACC=()
  # [T] TERMINAL IS A SHELL IN THE GLASS, and it stands whether or not the
  # house is installed: a prompt of the reader's own needs nothing linked.
  U_KEY+=(T); U_NAME+=(TERMINAL); U_ACT+=(terminal); U_KIND+=(shell)
  U_WHY+=(''); U_ACC+=($LIME)
  U_DESC+=("your own shell, in the glass")
  if installed_p; then
    # ONE SLOT, TWO NAMES.  The row that installs and the row that takes it
    # back out are the same row wearing the state it is in: INSTALL while the
    # house is not whole, UNINSTALL once it is.  A menu offering both at once
    # would be offering one that cannot do anything.
    U_KEY+=(U); U_NAME+=(UNINSTALL); U_ACT+=(uninstall); U_KIND+=(mirror)
    U_WHY+=(''); U_ACC+=($RED)
    U_DESC+=("take it all back out — put this Mac back")
  else
    U_KEY+=(N); U_NAME+=(INSTALL);  U_ACT+=(install);  U_KIND+=('')
    U_WHY+=("$INSTALLED_WHY"); U_ACC+=($AMBER)
    U_DESC+=("link the mirror into ~ · alien on a prompt")
  fi
  U_KEY+=(R); U_NAME+=(RESCAN);     U_ACT+=(rescan);   U_KIND+=(depth)
  U_WHY+=(''); U_ACC+=($CYAN)
  U_DESC+=("read this machine again")
  # [C] CONFIG · THE CABINET'S OWN, and a SUITE row because it is the house's
  # setting and not any one machine's -- the sound, the tube and the rate every
  # surface in the glass is drawn at.  It stands whether or not the house is
  # installed, the way [T] does: the blips can be turned off on a bare Mac.
  U_KEY+=(C); U_NAME+=(CONFIG);     U_ACT+=(config);   U_KIND+=('')
  U_WHY+=(''); U_ACC+=($CYAN)
  U_DESC+=("the cabinet itself · sound, tube, rate")
  S_N=${#U_KEY[@]}
  # ── ...AND THE MACHINES, WHICH ARE ROWS NOW AND NOT A READING ───────────
  # THEY USED TO BE A LIST WITH A LETTER EACH, and a list is not a way in.
  # The letter was the ONLY way to open one; it was printed on the control
  # panel and nowhere the eye goes when it is looking for something to press,
  # so a reader who did not already know it was there had no way to find out.
  # A machine is a thing you OPEN, so it is a row you can put the cursor on,
  # and ⏎ opens whatever the cursor is on -- one gesture for every openable
  # thing on this glass, which is the whole point of having a menu at all.
  local -i j
  for (( j = 0; j < M_N; j++ )); do
    U_KEY+=(''); U_NAME+=("${M_NAME[$j]}"); U_ACT+=(machine)
    U_KIND+=("${M_KIND[$j]}"); U_WHY+=(''); U_ACC+=($CYAN)
    U_DESC+=("${M_DESC[$j]}")
  done
  R_N=${#U_KEY[@]}
  # THE CURSOR IS A ROW, AND THE ROWS JUST CHANGED.  Installing turns two
  # rows into three and a reset turns three back into two; a UI_ROW left
  # pointing past the end is a highlighted row that is not there and a ⏎
  # that reads an unset array element under `set -u`.
  (( UI_ROW >= R_N )) && UI_ROW=$(( R_N - 1 ))
  (( UI_ROW < 0 )) && UI_ROW=0
  # THE KEY STRIP IS THE MENU, SPELLED TWICE.  It is rebuilt here so there is
  # no third place that has to be told the shape changed -- a strip still
  # offering [T] after a reset would be the surface promising a row that is
  # not on it.
  hint_build
  return 0
}

# the agents the intelligence row counts, by the command each one installs
AGENTS=(claude codex gemini cursor-agent aider opencode crush amp goose q)

# ── THE SWITCHES · two, and both of them live in terminal.conf ──────────────
# ══════════════════════════════════════════════════════════════════════════
# SECTION 10 · THE PROBE          one sweep of the machine, and its readings
# ══════════════════════════════════════════════════════════════════════════
# EVERY READING IS A SHELL COMMAND ALREADY, which is the argument for the
# TERMINAL being zsh at all: `uname`, `sysctl`, `sw_vers`, a glob over home/ and
# a `readlink`.  The Python TERMINAL shelled out for all of them and parsed what
# came back; this one simply asks.
# TWO QUESTIONS ABOUT A MACHINE, NOT ONE.
#
#   P_HERE  can this machine be OPENED at all — its own program is in the
#           folder, or it has a page pack that is
#   P_TAB   can it be dealt a TAB — which needs its own program, because a
#           pack is not a thing you can run, it is a thing this door sources
#
# They used to be one answer, and the one they gave was about the `.py`.  So a
# machine that had been cut down to a page pack -- no program of its own any
# more, because the door draws it now -- was reported ABSENT by the row, left
# out of the count, and refused when it was chosen: INTELLIGENCE, which works,
# reading `not here` next to the file that makes it work.
typeset -gA P_HERE P_NEEDS P_TAB
P_LEAVES=0 P_LINKED=0 P_HOST='' P_OS='' P_LOAD='' P_AGENTS=0
P_PET='' P_PETHP=0 P_CREDITS='' P_AT=0

_on_path() { whence -p "$1" >/dev/null 2>&1 }

_shebang() {   # SB = the interpreter the file's own first line names
  SB=()
  local first=''
  [[ -f "$1" && -r "$1" ]] || return 1
  IFS= read -r first < "$1" 2>/dev/null || return 1
  [[ "$first" == '#!'* ]] || return 1
  SB=(${=first#\#!})
  [[ "${SB[0]:t}" == env ]] && SB=("${SB[@]:1}")
  (( ${#SB[@]} )) || return 1
  return 0
}

needs_of() {   # the interpreter this PATH cannot find, or nothing
  # EACH ROW KNOWS ITS FILE AND WHAT RUNS IT.  A machine whose interpreter is
  # not on this PATH is not a machine TERMINAL can open, however present its
  # file -- named, so the row can say so instead of going grey with no reason.
  _shebang "$1" || { print -rn -- ''; return 0 }
  if [[ "${SB[0]}" == /* ]]; then
    [[ -x "${SB[0]}" ]] && print -rn -- '' || print -rn -- "${SB[0]:t}"
  else
    _on_path "${SB[0]}" && print -rn -- '' || print -rn -- "${SB[0]}"
  fi
  return 0
}

_mirror_seam() {
  # ALIEN_MIRROR=<linked>/<leaves> — the mirror, as a harness needs it.  The
  # menu has two shapes and which one is standing is a fact about the
  # reader's ~, which is the one thing a fixture in a repo cannot carry.
  local m="${ALIEN_MIRROR:-}"
  [[ -n "$m" ]] || return 0
  [[ "$m" == <->/<-> ]] || return 0
  P_LINKED=${m%%/*}; P_LEAVES=${m##*/}
  return 0
}

_mirror() {
  # A LINK THAT POINTS SOMEWHERE ELSE IS NOT OURS.  The count is of leaves
  # whose target resolves back into THIS repo, so a reader with their own
  # ~/.zshrc is told twelve of twenty-four rather than told they are
  # installed.  (N.D) · N no error on no match, . files only, D INCLUDE
  # DOTFILES -- and the whole mirror is dotfiles.  Without D this counted
  # nought of nought and told a fully installed Mac it had nothing linked.
  P_LEAVES=0; P_LINKED=0
  local root="$REPO/home" f rel dst
  [[ -d "$root" ]] || return 0
  for f in "$root"/**/*(N.D); do
    [[ "${f:t}" == .DS_Store ]] && continue
    (( P_LEAVES++ ))
    rel="${f#$root/}"
    dst="$HOME/$rel"
    [[ -e "$dst" && "${dst:A}" == "${f:A}" ]] && (( P_LINKED++ ))
  done
  return 0
}

_credits() {
  P_CREDITS=''
  local v="$(save_get arcade.credits '')"
  [[ "$v" == <-> ]] && P_CREDITS="$v"
  return 0
}

_pet() {
  # The xenogotchi keeps its animals in `pets`, with `active` saying which is
  # awake; `cat` and `vitals` are aliases it builds on load and does NOT
  # write, which is why reading them found no animal for as long as the cryo
  # bay has existed.  A save from before the bay still has its one animal at
  # the top level, and is read that way.
  P_PET=''; P_PETHP=0
  local a n h
  a="$(save_get xenogotchi.active '')"
  if [[ "$a" == <-> ]]; then
    n="$(save_get "xenogotchi.pets.$a.name" '')"
    h="$(save_get "xenogotchi.pets.$a.vitals.health" '')"
  fi
  if [[ -z "${n:-}" ]]; then
    n="$(save_get xenogotchi.cat.name '')"
    h="$(save_get xenogotchi.cat.vitals.health '')"
    [[ -n "${h:-}" ]] || h="$(save_get xenogotchi.vitals.health '')"
  fi
  [[ -n "${n:-}" ]] || return 0
  P_PET="${${n//[^[:print:]]/·}:u}"
  P_PET="${P_PET[0,8]}"
  # <->* MATCHES `93%` AND `12/100`, and `int(93%)` is a math error printed
  # onto a screen a row-diffing renderer will never repair.  The whole of the
  # integer part has to BE an integer.
  local hi="${h%%.*}"
  [[ "${hi:-}" == <-> ]] && P_PETHP=$(( hi )) || P_PETHP=0
  return 0
}

probe_scan() {
  P_AT=$(term_now)
  local i p
  local pk
  for (( i = 0; i < M_N; i++ )); do
    p="$REPO/${M_PATH[$i]}"
    pk="${M_PACK[$i]:-}"; [[ -n "$pk" ]] && pk="$REPO/$pk"
    if (( MOCK )); then
      P_HERE[${M_PATH[$i]}]=1; P_TAB[${M_PATH[$i]}]=1; P_NEEDS[${M_PATH[$i]}]=''
      continue
    fi
    [[ -f "$p" && -r "$p" ]] && P_TAB[${M_PATH[$i]}]=1 || P_TAB[${M_PATH[$i]}]=0
    if [[ -n "$pk" && -f "$pk" && -r "$pk" ]]; then
      # A PACK NEEDS NOTHING THIS PROCESS HAS NOT GOT.  It is sourced into the
      # shell that is already running, so there is no interpreter to go
      # looking for -- and asking the machine's OLD program what it needs was
      # its own small lie: SYSTEM would have read `needs python3` on a Mac
      # without python, for a machine that has been zsh for weeks.
      P_HERE[${M_PATH[$i]}]=1; P_NEEDS[${M_PATH[$i]}]=''
    elif (( ${P_TAB[${M_PATH[$i]}]} )); then
      P_HERE[${M_PATH[$i]}]=1; P_NEEDS[${M_PATH[$i]}]="$(needs_of "$p")"
    else
      P_HERE[${M_PATH[$i]}]=0; P_NEEDS[${M_PATH[$i]}]=''
    fi
  done
  if (( MOCK )); then
    # the fixture · the same machine every time, and nobody's real one.  THE
    # MIRROR IS WHOLE HERE, because the fixture's job is the picture the
    # suite is meant to be looked at in and that is a house that opens.  The
    # OTHER shape -- the one a fresh Mac gets -- is reached with ALIEN_MIRROR,
    # which is how a harness captures both from one fixture.
    P_LEAVES=4; P_LINKED=4
    P_HOST=moonbase; P_OS="macOS 15.5"
    P_LOAD=2.41; P_AGENTS=4; P_PET=MOCHI; P_PETHP=93; P_CREDITS=37
    _mirror_seam
    menu_build
    (( GLASS_GEN++ ))
    return 0
  fi
  _mirror
  _mirror_seam
  # EVERY CHARACTER FROM OUTSIDE IS LAUNDERED: a host name is a thing
  # somebody typed into a settings pane, and this one is going to a terminal
  # that executes control sequences.
  P_HOST="$(hostname -s 2>/dev/null || uname -n 2>/dev/null || print -r -- '')"
  P_HOST="${P_HOST%%.*}"
  P_HOST="${P_HOST//[^[:print:]]/·}"
  P_HOST="${P_HOST[0,17]}"
  if (( IS_MAC )) && whence -p sw_vers >/dev/null 2>&1; then
    local v="$(sw_vers -productVersion 2>/dev/null)"
    P_OS="${v:+macOS $v}"; : ${P_OS:=macOS}
  else
    P_OS="$(uname -s 2>/dev/null) ${$(uname -r 2>/dev/null)%%-*}"
    P_OS="${P_OS//[^[:print:]]/·}"
    P_OS="${P_OS[0,21]}"
  fi
  # THE LOAD, off uptime, which both platforms have and word differently:
  # Linux says "load average: 0.01, 0.05, 0.02" and macOS says "load
  # averages: 0.01 0.05 0.02".  Cutting after the last "average" and then
  # after the first colon lands on the first figure in both, and the shape
  # test at the end is what stops a locale nobody tested writing a comma into
  # the number itself.
  P_LOAD=''
  local up rest
  local -a lf
  up="$(uptime 2>/dev/null)" || up=''
  if [[ "$up" == *average* ]]; then
    rest="${up##*average}"; rest="${rest#*:}"
    # SPLIT ON WHITESPACE rather than trimming it.  `${x##[[:space:]]#}` is
    # the obvious way to eat a leading space and it needs EXTENDED_GLOB,
    # which this file does not set -- without it the `#` is a literal and the
    # strip silently does nothing, which is how the load came out empty while
    # every part of the parse looked right.
    # ${lf[0]} ON AN EMPTY SPLIT IS FATAL under `set -u` -- an arithmetic
    # subscript of a missing element is silently zero, an EXPANSION of one
    # ends the program.  probe_scan runs at power up and on every [R].
    lf=(${=rest}); rest="${lf[0]:-}"; rest="${rest%,}"
    [[ "$rest" == <->.<-> ]] && P_LOAD="$rest"
  fi
  P_AGENTS=0
  local a
  for a in "${AGENTS[@]}"; do _on_path "$a" && (( P_AGENTS++ )); done
  _pet
  _credits
  # THE MENU IS A FUNCTION OF THE PROBE and is rebuilt with it, here and
  # nowhere else -- so INSTALL becomes TERMINAL the moment the installer
  # comes back and the reading says the house is whole, without a single
  # caller having to remember to ask for it.
  menu_build
  (( GLASS_GEN++ ))
  return 0
}

# ── row_here I — can this row act? ──────────────────────────────────────────
# EVERY MENU ROW ACTS, and that is the whole point of the menu: INSTALL is
# offered when the house is not whole and TERMINAL when it is, so neither is
# ever a row that draws and refuses.  The one thing that can still be missing
# under a row is the installer's own file, and INSTALL is the row that would
# want it -- so that is the single question left here.
row_here() {
  case "${U_ACT[$1]}" in
    install|uninstall) [[ -f "$REPO/scripts/bootstrap.zsh" ]] ;;
    # A MACHINE'S ROW IS READY WHEN THE MACHINE IS IN THE FOLDER.  It is the
    # one row whose answer is about a file somebody else ships, so the row
    # greys out rather than opening onto nothing.
    machine)           (( ${P_HERE[${M_PATH[$(( $1 - S_N ))]}]:-0} )) ;;
    *)                 return 0 ;;
  esac
}
RNEED=''
row_needs() {   # row_needs I -> RNEED
  RNEED=''
  case "${U_ACT[$1]}" in
    install|uninstall) [[ -f "$REPO/scripts/bootstrap.zsh" ]] || RNEED='bootstrap.zsh' ;;
    machine)
      local -i m=$(( $1 - S_N ))
      if (( ! ${P_HERE[${M_PATH[$m]}]:-0} )); then
        # WHICHEVER FILE WOULD ACTUALLY MAKE IT OPEN.  A machine with a pack
        # declared is one this door would stand in its own glass, so the file
        # it is missing is the pack -- naming the old program instead sent a
        # reader looking for something that is not coming back.
        if [[ -n "${M_PACK[$m]:-}" ]]; then RNEED="${${M_PACK[$m]}:t}"
        else                                RNEED="${${M_PATH[$m]}:t}"; fi
      fi ;;
  esac
  return 0
}

# reading KIND -> RD.  IT USED TO PRINT, and every row on the glass asked it
# through a command substitution -- which in a shell is a FORK.  Eight rows a
# frame is eight processes a frame for eight short strings, and it cost more
# than every colour on the machine put together.  Nothing about the readings
# changed; they are handed back in a variable instead of down a pipe.
RD=''
reading() {   # reading KIND -> RD
  RD=''
  case "$1" in
    load)    if [[ -n "$P_LOAD" ]]; then RD="load $P_LOAD"; else RD='—'; fi ;;
    agents)  RD="$P_AGENTS agent"; (( P_AGENTS == 1 )) || RD+='s' ;;
    pet)     if [[ -n "$P_PET" ]]; then RD="$P_PET $P_PETHP%"; else RD='no pet'; fi ;;
    credits) if [[ -z "$P_CREDITS" ]]; then RD='no save yet'
             else RD="$P_CREDITS credit"; (( P_CREDITS == 1 )) || RD+='s'; fi ;;
    shell)   # THE SHELL THAT IS RUNNING IN THE GLASS, or the one that would
             if gt_live shell; then
               gt_secs $(( EPOCHSECONDS - ${GT_S[shell.t0]:-EPOCHSECONDS} ))
               RD="running · $GSEC"
             else RD="${${SHELL:-/bin/zsh}:t}"; fi ;;
    suite)   # HOW MANY MACHINES ARE ACTUALLY IN THE FOLDER, which is the one
             # thing worth knowing before pressing a row that opens all of
             # them.  A row saying "5 machines" over a folder holding three
             # would be the roster lying in the reading column.
             # ...AND A TAB IS THE QUESTION, not presence.  A machine that lives
             # in this glass as a page pack has no program to deal a tab, so
             # counting it here would promise a tab that never opens.
             local -i n=0 j
             for (( j = 0; j < M_N; j++ )); do (( ${P_TAB[${M_PATH[$j]}]:-0} )) && (( n++ )); done
             (( n == M_N )) && RD="$n machines" || RD="$n of $M_N in a tab" ;;
    depth)   # WHAT THIS TERMINAL CAN ACTUALLY SHOW, which is the one thing
             # about a lab full of inks that is a fact about YOUR machine
             if (( OPT_PLAIN )); then RD='no colour'
             elif (( TRUE24 )); then RD='24-bit'
             else RD='xterm 256'; fi ;;
    mirror)  if (( P_LEAVES && P_LINKED >= P_LEAVES )); then RD='all linked'
             else RD="$(( P_LEAVES > P_LINKED ? P_LEAVES - P_LINKED : 0 )) waiting"; fi ;;
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 11 · THE SKY OVER THE MACHINE      a reading, not a picture
# ══════════════════════════════════════════════════════════════════════════
# WHAT HANGS IN THE CORNER is the sprite's to draw and TERMINAL's to CHOOSE:
# is it night, which phase is the moon at, is the sun low enough for the warm
# ink.  Those are questions about the sky over this machine, and they are
# arithmetic -- so they are here, and the picture is asked for by their
# answers.
#
# TERMINAL USED TO CALL IT NIGHT AT SIX O'CLOCK, which is right twice a year
# and wrong by up to two hours the rest of the time: in late August the sun
# is still well up at eight across most of the inhabited world, and TERMINAL
# was hanging a moon over a reader who could see the sun out of the window.
# So the sun gets the same treatment the moon already had -- its real
# position, and whether it is above THIS reader's horizon.
#
# EVERY LINE OF THE ARITHMETIC IS THE PYTHON TERMINAL'S, TERM FOR TERM: the
# equation of the centre, the evection, the variation and the annual term on
# the moon; the equation of time and the hour angle on the sun.  Porting
# arithmetic between languages is exactly where a sign or a modulo goes
# quietly missing, which is what --caption below exists to catch.
#
# zsh's % IS NOT PYTHON'S.  C's fmod keeps the sign of the dividend, so
# fmod(-10, 360) is -10 where Python's -10 % 360 is 350 -- and every angle
# below goes negative sooner or later.  `v - m * floor(v / m)` is the
# positive one, written out at every site rather than hidden in a helper,
# because a wrapped angle is worth seeing wrapped.
RPD=0.017453292519943
HORIZON=-0.833                       # the disc's own width, and refraction
ZOD_NAME=(aries taurus gemini cancer leo virgo libra scorpio sagittarius \
          capricorn aquarius pisces)
PH_NAME=("new moon" "waxing crescent" "first quarter" "waxing gibbous" \
         "full moon" "waning gibbous" "last quarter" "waning crescent")
MOON_PH=0 MOON_ZOD='' SUN_ALT='' WHERE_LAT='' WHERE_LON='' WHERE_KNOWN=-1

sky_moon() {   # sky_moon TS -> MOON_PH (0..7), MOON_ZOD
  local -F dd lp mp ls ms dm lmn lsn phf lw
  dd=$(( ($1 - 946728000.0) / 86400.0 ))
  lp=$(( 218.3164477 + 13.17639648 * dd )); lp=$(( lp - 360.0 * floor(lp / 360.0) ))
  mp=$(( 134.9633964 + 13.06499295 * dd )); mp=$(( mp - 360.0 * floor(mp / 360.0) ))
  ls=$(( 280.4664567 + 0.98564736 * dd )); ls=$(( ls - 360.0 * floor(ls / 360.0) ))
  ms=$(( 357.5291092 + 0.98560028 * dd )); ms=$(( ms - 360.0 * floor(ms / 360.0) ))
  dm=$(( lp - ls ))
  lmn=$(( lp + 6.289 * sin(mp * RPD) + 1.274 * sin((2.0 * dm - mp) * RPD) \
          + 0.658 * sin(2.0 * dm * RPD) - 0.186 * sin(ms * RPD) ))
  lsn=$(( ls + 1.9148 * sin(ms * RPD) ))
  phf=$(( lmn - lsn )); phf=$(( phf - 360.0 * floor(phf / 360.0) ))
  MOON_PH=$(( int(floor(int(phf * 16.0 / 360.0 + 1.0) / 2.0)) ))
  MOON_PH=$(( MOON_PH - 8 * int(floor(MOON_PH / 8.0)) ))
  lw=$(( lmn - 360.0 * floor(lmn / 360.0) ))
  MOON_ZOD="${ZOD_NAME[$(( int(lw / 30.0) ))]}"
  return 0
}

# sky_where — this machine's latitude and longitude, or nothing.  The zone
# its clock is set from names a row in the tz database, and every spelling of
# where macOS keeps that is tried, because a symlink that moved between
# releases is not worth a sky.  The old TERMINAL also carried a cut of the table
# in scripts/universal/zones.tab; this one has no scripts/ to reach into, so
# the system's own is the only table asked.
sky_where() {
  (( WHERE_KNOWN >= 0 )) && return $(( WHERE_KNOWN ? 0 : 1 ))
  WHERE_KNOWN=0
  if (( MOCK )); then
    # THE FIXTURE STANDS SOMEWHERE, and it has to be the same somewhere for
    # everybody: a mock house whose sky depended on the reader's own timezone
    # would show a sun in Sydney and a moon in Chicago off one frozen
    # instant.  Greenwich, where the clock it is frozen against is kept.
    WHERE_LAT=51.5; WHERE_LON=0.0; WHERE_KNOWN=1; return 0
  fi
  local zone="${TZ:-}" real tab
  zone="${zone#:}"
  if [[ -z "$zone" && -e /etc/localtime ]]; then
    real="${${:-/etc/localtime}:A}"
    [[ "$real" == */zoneinfo/* ]] && zone="${real#*/zoneinfo/}"
  fi
  [[ -n "$zone" ]] || return 1
  for tab in /usr/share/zoneinfo/zone.tab /usr/share/zoneinfo/zone1970.tab \
             /var/db/timezone/zoneinfo/zone.tab /var/db/timezone/zoneinfo/zone1970.tab \
             /usr/share/zoneinfo.default/zone.tab /usr/share/zoneinfo.default/zone1970.tab; do
    [[ -r "$tab" ]] || continue
    while IFS=$'\t' read -r _c _co _z _rest; do
      [[ "$_c" == '#'* ]] && continue
      [[ ",${_z:-}," == *",$zone,"* ]] || continue
      _iso6709 "${_co:-}" && { WHERE_KNOWN=1; return 0 }
    done < "$tab"
  done
  return 1
}

_iso6709() {   # +DDMM+DDDMM, and +DDMMSS+DDDMMSS on the wider rows
  local co="$1" lat lon
  local -i cut=0 i
  for (( i = ${#co} - 1; i > 0; i-- )); do
    [[ "${co[$i]}" == (+|-) ]] && { cut=$i; break }
  done
  (( cut > 0 )) || return 1
  lat="${co[0,$(( cut - 1 ))]}"; lon="${co[$cut,-1]}"
  local fine=0; (( ${#lat} > 5 )) && fine=1
  WHERE_LAT="$(_deg "$lat" 0 $fine)" || return 1
  WHERE_LON="$(_deg "$lon" 1 $fine)" || return 1
  return 0
}
_deg() {   # _deg ±DDMM[SS] WIDE FINE
  local v="$1" sgn=1
  local -i wide=$2 fine=$3 dn
  [[ "${v[0]}" == '-' ]] && sgn=-1
  v="${v[1,-1]}"
  dn=$(( wide ? 3 : 2 ))
  [[ "$v" == <-> ]] || return 1
  local dd="${v[0,$(( dn - 1 ))]}" mm="${v[$dn,$(( dn + 1 ))]}" ss=''
  (( fine )) && ss="${v[$(( dn + 2 )),$(( dn + 3 ))]}"
  print -r -- $(( sgn * (dd + mm / 60.0 + (${ss:-0} + 0.0) / 3600.0) ))
  return 0
}

sky_sun() {   # sky_sun TS -> SUN_ALT, or nothing when we do not know where
  SUN_ALT=''
  sky_where || return 1
  local -F dd g q2 lam eps dec ra gmst ha
  dd=$(( ($1 - 946728000.0) / 86400.0 ))
  g=$(( 357.529 + 0.98560028 * dd )); g=$(( g - 360.0 * floor(g / 360.0) ))
  q2=$(( 280.459 + 0.98564736 * dd )); q2=$(( q2 - 360.0 * floor(q2 / 360.0) ))
  lam=$(( q2 + 1.915 * sin(g * RPD) + 0.020 * sin(2.0 * g * RPD) ))
  lam=$(( lam - 360.0 * floor(lam / 360.0) ))
  eps=$(( 23.439 - 0.00000036 * dd ))
  dec=$(( asin(sin(eps * RPD) * sin(lam * RPD)) / RPD ))
  ra=$(( atan(cos(eps * RPD) * sin(lam * RPD), cos(lam * RPD)) / RPD ))
  gmst=$(( 18.697374558 + 24.06570982441908 * dd )); gmst=$(( gmst - 24.0 * floor(gmst / 24.0) ))
  ha=$(( gmst * 15.0 + WHERE_LON - ra + 180.0 ))
  ha=$(( ha - 360.0 * floor(ha / 360.0) - 180.0 ))
  SUN_ALT=$(( asin(sin(WHERE_LAT * RPD) * sin(dec * RPD) \
              + cos(WHERE_LAT * RPD) * cos(dec * RPD) * cos(ha * RPD)) / RPD ))
  return 0
}

is_day() {   # is_day TS — is the sun up, really up, where this machine stands
  if sky_sun "$1"; then
    (( SUN_ALT > HORIZON )); return $?
  fi
  # ...and back to the old six-to-six window only on a machine that cannot
  # say what its own offset from UTC is, which is a machine with no clock
  # worth reading anyway
  local h; strftime -s h '%H' "$1" 2>/dev/null || h=12
  (( 10#$h >= 6 && 10#$h < 18 ))
}

twilight() {   # the hour either side of the horizon · the civil six degrees
  if sky_sun "$1"; then
    (( SUN_ALT >= -6.0 && SUN_ALT <= 6.0 )); return $?
  fi
  local h; strftime -s h '%H' "$1" 2>/dev/null || h=12
  [[ "$(( 10#$h ))" == (5|6|17|18) ]]
}

CLKSTR=''
clock_str() {   # clock_str TS -> CLKSTR · twelve-hour, the meridiem whispered
  local -a hm
  # ONE strftime, NOT FOUR, and none of them in a subshell.  `-s` puts the
  # answer in a parameter, which is the difference between a builtin and a
  # fork -- and this is asked once a minute by tick_slow, not once a frame.
  strftime -s hm '%H %M %p' "$1" 2>/dev/null || { CLKSTR=''; return 0 }
  local -a f; f=(${=hm})
  if (( ${#f[@]} < 3 )); then CLKSTR="${f[0]:-00}:${f[1]:-00}"; return 0; fi
  local -i h=$(( 10#${f[0]} % 12 ))
  (( h )) || h=12
  CLKSTR="$h:${f[1]} ${${f[2]}:l}"
  return 0
}

caption() {   # caption TS -> CAPTION · what is up, and what time it is
  clock_str "$1"
  if is_day "$1"; then CAPTION="sunny · $CLKSTR"; return 0; fi
  sky_moon "$1"
  CAPTION="${PH_NAME[$MOON_PH]} in $MOON_ZOD · $CLKSTR"
  return 0
}

# ── THE SLOW CLOCK · the answers that only change on the minute ────────────
# THE SKY IS NOT A FRAME'S BUSINESS.  Where the sun is, which phase the moon
# is at, what o'clock it is and what the coin door has to say are all answers
# that hold for a minute at a time -- and working them out on every frame cost
# three transcendental sweeps, two forks and a strftime, thirty times over,
# for a line that had not changed.  So they are worked out when the MINUTE
# changes, and read from a variable in between.  The animation clock is
# untouched: everything that actually moves still moves on its own beat.
NOW=0; NOW_MIN=-1
CAPTION=''; GREETING=''; SKY_IDX=-1
tick_slow() {
  term_now_set
  local -i m=$(( NOW / 60 ))
  (( m == NOW_MIN )) && return 0
  NOW_MIN=$m
  (( GLASS_GEN++ ))
  caption "$NOW"
  greeting "$NOW"
  # ...and which card is hanging over him, which is the same question asked
  # of the same arithmetic
  local -i night=0 tw=0 ph=0 i
  is_day "$NOW" || night=1
  twilight "$NOW" && tw=1
  (( night )) && { sky_moon "$NOW"; ph=$MOON_PH }
  local key="$night,$ph,$tw"
  SKY_IDX=-1
  for (( i = 0; i < ${#SKY_KEY[@]}; i++ )); do
    [[ "${SKY_KEY[$i]}" == "$key" ]] && { SKY_IDX=$i; break }
  done
  return 0
}

# ── the greeting on the coin door ───────────────────────────────────────────
# ONE LINE A MINUTE, dealt from the hour's own pool by a hash of the minute,
# so it is stable while you look at it and different when you come back.  The
# pools with NAME in them are only in play when there is a name to put there;
# on the fixture there never is, which is why the previews always read one of
# the nameless ones.
GREET_M=('good morning, NAME' 'morning, NAME' 'the day is new, NAME' \
  'coffee first, NAME' 'up with the light, NAME' 'hello again, NAME' \
  'a clean slate today, NAME' 'the terminal missed you, NAME' \
  'early and upright, NAME' 'the sun took its time too, NAME' \
  'first light, best light' 'the stars clocked out for you' \
  'today has not been touched yet' 'begin gently')
GREET_A=('good afternoon, NAME' 'afternoon, NAME' 'still at it, NAME' \
  'midday and moving, NAME' 'the day is half yours, NAME' \
  'steady on, NAME' 'carry on, NAME' 'no hurry, NAME' \
  'the afternoon suits you, NAME' 'hello from the bright side' \
  'plenty of light left' 'the sun is doing its part')
GREET_E=('good evening, NAME' 'evening, NAME' 'the light is leaving, NAME' \
  'day nearly done, NAME' 'home stretch, NAME' 'ease off soon, NAME' \
  'golden hour somewhere, NAME' 'wind down when ready, NAME' \
  'the stars are queueing up' 'dusk becomes this terminal' \
  'the sky is changing shifts' 'a good hour to be quiet')
GREET_L=('up late, NAME' 'still awake, NAME' 'the small hours, NAME' \
  'night owl, NAME' 'quiet out there, NAME' 'the night is patient' \
  'the moon keeps you company, NAME' 'the stars are all yours, NAME' \
  'insomnia or inspiration, NAME' 'past bedtime, worth it' \
  'small hours, sharp mind' 'sleep is optional, apparently' \
  'the dark is good company' 'one more thing, then rest')

greeting() {   # greeting TS -> GREETING
  local -a pool
  local hh
  strftime -s hh '%H' "$1" 2>/dev/null || hh=12
  local -i h=$(( 10#$hh ))
  if   (( h < 5 ));  then pool=("${GREET_L[@]}")
  elif (( h < 12 )); then pool=("${GREET_M[@]}")
  elif (( h < 18 )); then pool=("${GREET_A[@]}")
  elif (( h < 23 )); then pool=("${GREET_E[@]}")
  else                    pool=("${GREET_L[@]}"); fi
  local who=''
  (( MOCK )) || who="${${USER:-}//[^[:print:]]/·}"
  who="${who[0,23]}"
  if [[ -z "$who" ]]; then
    local -a named
    local line
    for line in "${pool[@]}"; do [[ "$line" == *NAME* ]] || named+=("$line"); done
    (( ${#named[@]} )) && pool=("${named[@]}")
  fi
  # THE HASH IS THE PYTHON'S, and it has to be: 2654435761 is the golden
  # ratio's 32-bit reciprocal and the product overflows 64 bits for any
  # plausible epoch minute, so it is taken modulo 2^64 the way Python's
  # unbounded integer would not -- zsh's arithmetic wraps there for free, and
  # the two agree because the modulo by the pool length only ever sees the
  # low bits.
  local -i seed=$(( $1 / 60 ))
  local -i k=$(( (seed * 2654435761) % ${#pool[@]} ))
  (( k < 0 )) && k=$(( k + ${#pool[@]} ))
  GREETING="${${pool[$k]//NAME/$who}:u}"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 12 · THE VISITOR AND THE SKY OVER HIM
# ══════════════════════════════════════════════════════════════════════════
# A SHELL CANNOT LIGHT A SPRITE and must not learn how.  He is a grid of
# MATERIALS at twenty pixels by eighteen, two pixel rows to a cell, lit once
# from the suite's key light and downsampled to whole cells -- a wide
# cranium, a face falling away to a rounded chin, two big lids with a
# catchlight in each.  None of that belongs in zsh.
#
# THE OLD TERMINAL ASKED FOR IT.  One call to scripts/vanity/vanity.py at power
# up, every pose and every phase, parsed once and spent from an array -- and
# with no python3 on the machine he was simply not there, which on a fresh
# Mac with no command line tools is exactly the machine that most needed
# something friendly on the glass.
#
# SO HE IS CARRIED.  What follows is that call's own answer, cell for cell,
# the same hex the same pipeline printed -- not redrawn, not re-lit, not
# approximated.  He is folded on the one axis he repeats along: he is alive
# in his EYES and nowhere else (moving the head a pixel is moving it half a
# cell, which re-quantises the whole silhouette and everything he is
# wearing), so the head is stored ONCE and the three rows that move are
# stored as the bands they actually take.  Twenty-five poses out of thirty-
# two rows.
#
# WHAT HE IS WEARING.  vanity.py dresses him from the arcade's ledger -- a
# hat, glasses, a smoke, an aura -- and a hat is not a sticker over his head,
# it is more pixels in his grid, lit by the same light and re-quantised with
# him.  That cannot be folded into a card and it cannot be faked, so the card
# below is him BARE, and a dressed visitor is composed by the ARCADE's own
# wardrobe (vis_draw_dressed, under draw_visitor) rather than by a second copy
# of it here that would have to be kept in step.
# ── HIS CARD, as vanity.py composed it · w=26 h=12 ox=3 oy=3 ────────────
# THE HEAD IS ONE CARD AND THE EYES ARE THREE BANDS.  vanity.py hands the old
# TERMINAL twenty-five whole cards and twenty-two of every card's rows are the
# same in all of them -- he is alive in his eyes and nowhere else, which is
# the wardrobe's own rule.  So what is carried here is the head ONCE and the
# three rows that move (5, 6, 7) as the two, nine and nine bands they
# actually take, with a pose naming its three by number.  Cell for cell it is
# the same visitor: not redrawn, not re-lit, not approximated -- the same hex
# the same pipeline printed, folded on the axis it repeats along.
VIS_W=26; VIS_H=12; VIS_OX=3; VIS_OY=3
CEL_W=12; CEL_H=6
VIS_ROW=(
'- - - - - - - - - - - - - - - - - - - - - - - - - -'
'- - - - - - - - - - - - - - - - - - - - - - - - - -'
'- - - - - - - - - - - - - - - - - - - - - - - - - -'
'- - - - - - - - - - b8bcc4@62 bcbcc8@62 989cb8@62 acb4c4 bcc0cc@62 bcc0cc@62 c8d0d4@62 - - - - - - - - -'
'- - - - - - - 9094ac@62 9090a4 80809c 786c8c 78708c 787090 7c7490 807494 807894 908ca4 a49cb0 b0b8c8 c8d0d8@62 - - - - - -'
'- - - - - - 8c90a8@62 806084 6c6480 706884 746888 746c88 78708c 787090 7c7490 807494 807894 847c94 887c98 9ca0b8 c8d0d8@62 - - - - -'   # 5 · the band
'- - - - - - 905c8c a09ca0 04000c 04000c 04040c 343440 746888 786c8c 78708c a4a4a8 04040c 04040c 04040c 343444 9ca0b4 - - - - -'   # 6 · the band
'- - - - - - 94588c 04000c 04000c 04000c 04040c 343440 706884 746888 746c8c 04040c 04040c 04040c 04040c 343444 98a0b4 - - - - -'   # 7 · the band
'- - - - - - - 94588c@62 7c5884 685c7c 686080 6c6080 6c6480 706884 746888 746888 746c8c 787090 8884a0 989cb4@62 - - - - - -'
'- - - - - - - - - 945890@62 744c7c 504468 605c74 605c74 605c78 544c68 747088 9094ac@62 - - - - - - - -'
'- - - - - - - - - - - 985890 5c5070 504868 5c5474 8c8ca8 - - - - - - - - - -'
'- - - - - - - - - - - - 985890@62 9c5c90@62 8888a4@62 - - - - - - - - - - -'
)
# row 5 · the brow, wide or narrowed
VIS_E5=(
'- - - - - - 8c90a8@62 806084 6c6480 706884 746888 746c88 78708c 787090 7c7490 807494 807894 847c94 887c98 9ca0b8 c8d0d8@62 - - - - -'
'- - - - - - 8c90a8@62 806084 343440 343440 343440 746c88 78708c 787090 7c7490 807494 343440 343440 343444 9ca0b8 c8d0d8@62 - - - - -'
)
# row 6 · the lids and the look
VIS_E6=(
'- - - - - - 905c8c a09ca0 04000c 04000c 04040c 343440 746888 786c8c 78708c a4a4a8 04040c 04040c 04040c 343444 9ca0b4 - - - - -'
'- - - - - - 905c8c 343440 343440 343440 343440 343440 746888 786c8c 78708c 343440 343440 343440 343444 343444 9ca0b4 - - - - -'
'- - - - - - ccbccc 04000c 04000c 04000c 343440 343440 746888 786c8c ccc8d4 04040c 04040c 04040c 343444 343444 9ca0b4 - - - - -'
'- - - - - - ccbccc 04000c 04000c 04000c 04040c 343440 746888 786c8c ccc8d4 04040c 04040c 04040c 04040c 343444 9ca0b4 - - - - -'
'- - - - - - 905c8c 343440 a0a0a4 04000c 04040c 343440 746888 786c8c 78708c 343440 a4a4a8 04040c 04040c 343444 9ca0b4 - - - - -'
'- - - - - - 905c8c 04000c a0a0a4 04000c 04040c 04040c 746888 786c8c 78708c 04040c a4a4a8 04040c 04040c 04040c 9ca0b4 - - - - -'
'- - - - - - 905c8c 343440 a0a0a4 04000c 04040c 04040c 746888 786c8c 78708c 343440 a4a4a8 04040c 04040c 04040c 9ca0b4 - - - - -'
'- - - - - - 905c8c 343440 343440 a0a0a4 04040c 04040c 746888 786c8c 78708c 343440 343440 a4a4a8 04040c 04040c 9ca0b4 - - - - -'
'- - - - - - 905c8c 343440 04000c a0a0a4 04040c 04040c 746888 786c8c 78708c 343440 04040c a4a4a8 04040c 04040c 9ca0b4 - - - - -'
)
# row 7 · the pupils under them
VIS_E7=(
'- - - - - - 94588c 04000c 04000c 04000c 04040c 343440 706884 746888 746c8c 04040c 04040c 04040c 04040c 343444 98a0b4 - - - - -'
'- - - - - - 94588c 343440 343440 343440 343440 343440 706884 746888 746c8c 343440 343440 343440 343444 343444 98a0b4 - - - - -'
'- - - - - - 94588c 645c7c 343440 343440 343440 706884 706884 746888 746c8c 78708c 343440 343440 343444 807894 98a0b4 - - - - -'
'- - - - - - 94588c 645c7c 68607c 6c6080 6c6080 706884 706884 746888 746c8c 78708c 787090 7c7490 807494 807894 98a0b4 - - - - -'
'- - - - - - 94588c 04000c 04000c 04000c 343440 343440 706884 746888 746c8c 04040c 04040c 04040c 343444 343444 98a0b4 - - - - -'
'- - - - - - 94588c 343440 04000c 04000c 04040c 343440 706884 746888 746c8c 343440 04040c 04040c 04040c 343444 98a0b4 - - - - -'
'- - - - - - 94588c 04000c 04000c 04000c 04040c 04040c 706884 746888 746c8c 04040c 04040c 04040c 04040c 04040c 98a0b4 - - - - -'
'- - - - - - 94588c 343440 04000c 04000c 04040c 04040c 706884 746888 746c8c 343440 04040c 04040c 04040c 04040c 98a0b4 - - - - -'
'- - - - - - 94588c 343440 343440 04000c 04040c 04040c 706884 746888 746c8c 343440 343440 04040c 04040c 04040c 98a0b4 - - - - -'
)
# pose 'look,lids,eye' -> the three bands it wears
VIS_POSE_K=('-1,0,0' '-1,0,1' '-1,0,2' '-1,1,0' '-1,2,0' '-2,0,0' '-2,0,1' '-2,0,2' '-2,1,0' '-2,2,0' '0,0,0' '0,0,1' '0,0,2' '0,1,0' '0,2,0' '1,0,0' '1,0,1' '1,0,2' '1,1,0' '1,2,0' '2,0,0' '2,0,1' '2,0,2' '2,1,0' '2,2,0')
VIS_POSE_V=('0 0 0' '0 0 1' '1 0 0' '0 0 2' '0 1 3' '0 2 4' '0 2 1' '1 3 4' '0 2 2' '0 1 3' '0 4 5' '0 4 1' '1 5 6' '0 4 2' '0 1 3' '0 6 7' '0 6 1' '1 6 7' '0 6 2' '0 1 3' '0 7 8' '0 7 1' '1 8 8' '0 7 2' '0 1 3')

# ── WHAT HANGS OVER HIM · night,phase,twilight -> a 12x6 card ─────────────
# The sun at two altitudes and the moon at its eight phases, each of those
# twice for the hour either side of the horizon -- eighteen cards, lit by the
# same key light he is.  WHICH ONE hangs there is the arithmetic below's to
# say and this file's to draw, which is the split the old TERMINAL kept.
SKY_KEY=('0,0,0' '0,0,1' '1,0,0' '1,0,1' '1,1,0' '1,1,1' '1,2,0' '1,2,1' '1,3,0' '1,3,1' '1,4,0' '1,4,1' '1,5,0' '1,5,1' '1,6,0' '1,6,1' '1,7,0' '1,7,1')
SKY_ROW=(
# 0,0,0   the sun
'- - - c45008@62 ca5008 ce5408 d25408 d65608 dc5808@62 - - -'
'- bc4c08@62 cd5e0c f49018 fab02e fcce44 fcd246 fcd648 fcdc48 e77c19 e45c08@62 -'
'b84c08@62 d46c10 ee8e18 f49018 faca44 fcce44 fcd246 fce9a2 fcdc48 fce04c f0a02a e85c08@62'
'b84c08@62 d46c10 ee8e18 f49018 fa9418 fcc139 fcd246 fcd648 fcdc48 fcb328 f08212 e85c08@62'
'- bc4c08@62 cd5e0c f49018 fa9418 fc9818 fc9a18 fc9e18 fca01a e76d0d e45c08@62 -'
'- - - c45008@62 ca5008 ce5408 d25408 d65608 dc5808@62 - - -'
# 0,0,1   the sun · twilight
'- - - 98360c@62 9c380c a0380c a23a0c a63c0c aa3c0c@62 - - -'
'- 92340c@62 a23f0d cc6210 de8422 f0a638 f6aa38 faae38 fcb03a c25a18 b1400c@62 -'
'90340c@62 aa4a0e c86010 cc6210 eca234 f0a638 f6aa38 fbd59a fcb03a fcb43c d87c24 b4400c@62'
'90340c@62 aa4a0e c86010 cc6210 d26410 e9972e f6aa38 faae38 fcb03a ed811b d05a10 b4400c@62'
'- 92340c@62 a23f0d cc6210 d26410 d66810 da6a10 e06c10 e46e10 bd490d b1400c@62 -'
'- - - 98360c@62 9c380c a0380c a23a0c a63c0c aa3c0c@62 - - -'
# 1,0,0   the moon at phase 0
'- - - 646478@62 68647c 68687c 6a687c 6c6a7e 6c6c80@62 - - -'
'- 626074@62 5c596b 444050 444050 444450 444450 444454 484454 636275 6c6c84@62 -'
'606074@62 505060 44404c 444050 444050 444450 444450 444454 484454 484454 5a586c 6c6c84@62'
'606074@62 505060 44404c 444050 444050 444450 444450 444454 484454 484454 5a586c 6c6c84@62'
'- 626074@62 5c596b 444050 444050 444450 444450 444454 484454 636275 6c6c84@62 -'
'- - - 646478@62 68647c 68687c 6a687c 6c6a7e 6c6c80@62 - - -'
# 1,0,1   the moon at phase 0 · twilight
'- - - 5a586c@62 5c586c 5c5c70 5e5c70 605c72 606074@62 - - -'
'- 58586c@62 525163 403c48 403c48 40404c 40404c 40404c 42404c 5b586c 646078@62 -'
'58586c@62 4c4a5a 403c48 403c48 403c48 40404c 40404c 40404c 42404c 44404e 545064 646078@62'
'58586c@62 4c4a5a 403c48 403c48 403c48 40404c 40404c 40404c 42404c 44404e 545064 646078@62'
'- 58586c@62 525163 403c48 403c48 40404c 40404c 40404c 42404c 5b586c 646078@62 -'
'- - - 5a586c@62 5c586c 5c5c70 5e5c70 605c72 606074@62 - - -'
# 1,1,0   the moon at phase 1
'- - - 646478@62 68647c 68687c 75748c 9c9abe a09cc2@62 - - -'
'- 626074@62 5c596b 444050 444050 444450 444450 9ea0a8 fcfcfc bab7d4 a5a4c9@62 -'
'606074@62 505060 44404c 444050 444050 444450 444450 444454 fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'606074@62 505060 44404c 444050 444050 444450 444450 444454 fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'- 626074@62 5c596b 444050 444050 444450 444450 9ea0a8 fcfcfc bab7d4 a5a4c9@62 -'
'- - - 646478@62 68647c 68687c 75748c 9c9abe a09cc2@62 - - -'
# 1,1,1   the moon at phase 1 · twilight
'- - - 5a586c@62 5c586c 5c5c70 65647a 7e7c9c 8080a0@62 - - -'
'- 58586c@62 525163 403c48 403c48 40404c 40404c 88869a d0ceec 9897b7 8884a5@62 -'
'58586c@62 4c4a5a 403c48 403c48 403c48 40404c 40404c 40404c d0ceec d4d4f2 b0aed0 8884a8@62'
'58586c@62 4c4a5a 403c48 403c48 403c48 40404c 40404c 40404c d0ceec d4d4f2 b0aed0 8884a8@62'
'- 58586c@62 525163 403c48 403c48 40404c 40404c 88869a d0ceec 9897b7 8884a5@62 -'
'- - - 5a586c@62 5c586c 5c5c70 65647a 7e7c9c 8080a0@62 - - -'
# 1,2,0   the moon at phase 2
'- - - 646478@62 68647c 68687c 9896ba 9c9abe a09cc2@62 - - -'
'- 626074@62 5c596b 444050 444050 444450 f2f2fc f6fafc fcfcfc bab7d4 a5a4c9@62 -'
'606074@62 505060 44404c 444050 444050 444450 e0e0f2 f6fafc fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'606074@62 505060 44404c 444050 444050 444450 f2f2fc f6fafc fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'- 626074@62 5c596b 444050 444050 444450 f2f2fc f6fafc fcfcfc bab7d4 a5a4c9@62 -'
'- - - 646478@62 68647c 68687c 9896ba 9c9abe a09cc2@62 - - -'
# 1,2,1   the moon at phase 2 · twilight
'- - - 5a586c@62 5c586c 5c5c70 7c7a98 7e7c9c 8080a0@62 - - -'
'- 58586c@62 525163 403c48 403c48 40404c c8c6e2 cecae8 d0ceec 9897b7 8884a5@62 -'
'58586c@62 4c4a5a 403c48 403c48 403c48 40404c b8b8d4 cecae8 d0ceec d4d4f2 b0aed0 8884a8@62'
'58586c@62 4c4a5a 403c48 403c48 403c48 40404c c8c6e2 cecae8 d0ceec d4d4f2 b0aed0 8884a8@62'
'- 58586c@62 525163 403c48 403c48 40404c c8c6e2 cecae8 d0ceec 9897b7 8884a5@62 -'
'- - - 5a586c@62 5c586c 5c5c70 7c7a98 7e7c9c 8080a0@62 - - -'
# 1,3,0   the moon at phase 3
'- - - 646478@62 68647c 8b89a8 9896ba 9c9abe a09cc2@62 - - -'
'- 626074@62 5c596b 444050 848498 d1d3ea f2f2fc f6fafc fcfcfc bab7d4 a5a4c9@62 -'
'606074@62 505060 44404c 444050 c4c6e0 c8cae4 e0e0f2 f6fafc fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'606074@62 505060 44404c 444050 e8eaf6 eceefa f2f2fc f6fafc fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'- 626074@62 5c596b 444050 9696a4 eceefa f2f2fc f6fafc fcfcfc bab7d4 a5a4c9@62 -'
'- - - 646478@62 68647c 8b89a8 9896ba 9c9abe a09cc2@62 - - -'
# 1,3,1   the moon at phase 3 · twilight
'- - - 5a586c@62 5c586c 71718d 7c7a98 7e7c9c 8080a0@62 - - -'
'- 58586c@62 525163 403c48 727084 adafc9 c8c6e2 cecae8 d0ceec 9897b7 8884a5@62 -'
'58586c@62 4c4a5a 403c48 403c48 a2a4be a6a8c2 b8b8d4 cecae8 d0ceec d4d4f2 b0aed0 8884a8@62'
'58586c@62 4c4a5a 403c48 403c48 c0beda c4c2de c8c6e2 cecae8 d0ceec d4d4f2 b0aed0 8884a8@62'
'- 58586c@62 525163 403c48 807e92 c4c2de c8c6e2 cecae8 d0ceec 9897b7 8884a5@62 -'
'- - - 5a586c@62 5c586c 71718d 7c7a98 7e7c9c 8080a0@62 - - -'
# 1,4,0   the moon at phase 4
'- - - 908cae@62 9290b2 9694b6 9896ba 9c9abe a09cc2@62 - - -'
'- 8886a6@62 9897b5 c0c0da c4c6e0 d1d3ea f2f2fc f6fafc fcfcfc bab7d4 a5a4c9@62 -'
'8484a4@62 a09eba babed6 c0c0da c4c6e0 c8cae4 e0e0f2 f6fafc fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'8484a4@62 b0b0c6 dedeea e2e4f0 e8eaf6 eceefa f2f2fc f6fafc fcfcfc fcfcfc d2d0e4 a8a4cc@62'
'- 8886a6@62 a19fba e2e4f0 e8eaf6 eceefa f2f2fc f6fafc fcfcfc bab7d4 a5a4c9@62 -'
'- - - 908cae@62 9290b2 9694b6 9896ba 9c9abe a09cc2@62 - - -'
# 1,4,1   the moon at phase 4 · twilight
'- - - 747290@62 787492 787896 7c7a98 7e7c9c 8080a0@62 - - -'
'- 6e6c88@62 7c7c97 9ea0b8 a2a4be adafc9 c8c6e2 cecae8 d0ceec 9897b7 8884a5@62 -'
'6c6c84@62 82849e 9a9eb6 9ea0b8 a2a4be a6a8c2 b8b8d4 cecae8 d0ceec d4d4f2 b0aed0 8884a8@62'
'6c6c84@62 9090aa b6b6d0 bcb8d4 c0beda c4c2de c8c6e2 cecae8 d0ceec d4d4f2 b0aed0 8884a8@62'
'- 6e6c88@62 83829d bcb8d4 c0beda c4c2de c8c6e2 cecae8 d0ceec 9897b7 8884a5@62 -'
'- - - 747290@62 787492 787896 7c7a98 7e7c9c 8080a0@62 - - -'
# 1,5,0   the moon at phase 5
'- - - 908cae@62 9290b2 9694b6 8d8aaa 6c6a7e 6c6c80@62 - - -'
'- 8886a6@62 9897b5 c0c0da c4c6e0 d1d3ea f2f2fc 9c9ea8 484454 636275 6c6c84@62 -'
'8484a4@62 a09eba babed6 c0c0da c4c6e0 c8cae4 e0e0f2 f6fafc 484454 484454 5a586c 6c6c84@62'
'8484a4@62 b0b0c6 dedeea e2e4f0 e8eaf6 eceefa f2f2fc f6fafc 484454 484454 5a586c 6c6c84@62'
'- 8886a6@62 a19fba e2e4f0 e8eaf6 eceefa f2f2fc 9c9ea8 484454 636275 6c6c84@62 -'
'- - - 908cae@62 9290b2 9694b6 8d8aaa 6c6a7e 6c6c80@62 - - -'
# 1,5,1   the moon at phase 5 · twilight
'- - - 747290@62 787492 787896 75728e 605c72 606074@62 - - -'
'- 6e6c88@62 7c7c97 9ea0b8 a2a4be adafc9 c8c6e2 86849a 42404c 5b586c 646078@62 -'
'6c6c84@62 82849e 9a9eb6 9ea0b8 a2a4be a6a8c2 b8b8d4 cecae8 42404c 44404e 545064 646078@62'
'6c6c84@62 9090aa b6b6d0 bcb8d4 c0beda c4c2de c8c6e2 cecae8 42404c 44404e 545064 646078@62'
'- 6e6c88@62 83829d bcb8d4 c0beda c4c2de c8c6e2 86849a 42404c 5b586c 646078@62 -'
'- - - 747290@62 787492 787896 75728e 605c72 606074@62 - - -'
# 1,6,0   the moon at phase 6
'- - - 908cae@62 9290b2 9694b6 6a687c 6c6a7e 6c6c80@62 - - -'
'- 8886a6@62 9897b5 c0c0da c4c6e0 d1d3ea 444450 444454 484454 636275 6c6c84@62 -'
'8484a4@62 a09eba babed6 c0c0da c4c6e0 c8cae4 444450 444454 484454 484454 5a586c 6c6c84@62'
'8484a4@62 b0b0c6 dedeea e2e4f0 e8eaf6 eceefa 444450 444454 484454 484454 5a586c 6c6c84@62'
'- 8886a6@62 a19fba e2e4f0 e8eaf6 eceefa 444450 444454 484454 636275 6c6c84@62 -'
'- - - 908cae@62 9290b2 9694b6 6a687c 6c6a7e 6c6c80@62 - - -'
# 1,6,1   the moon at phase 6 · twilight
'- - - 747290@62 787492 787896 5e5c70 605c72 606074@62 - - -'
'- 6e6c88@62 7c7c97 9ea0b8 a2a4be adafc9 40404c 40404c 42404c 5b586c 646078@62 -'
'6c6c84@62 82849e 9a9eb6 9ea0b8 a2a4be a6a8c2 40404c 40404c 42404c 44404e 545064 646078@62'
'6c6c84@62 9090aa b6b6d0 bcb8d4 c0beda c4c2de 40404c 40404c 42404c 44404e 545064 646078@62'
'- 6e6c88@62 83829d bcb8d4 c0beda c4c2de 40404c 40404c 42404c 5b586c 646078@62 -'
'- - - 747290@62 787492 787896 5e5c70 605c72 606074@62 - - -'
# 1,7,0   the moon at phase 7
'- - - 908cae@62 9290b2 73738a 6a687c 6c6a7e 6c6c80@62 - - -'
'- 8886a6@62 9897b5 c0c0da 848298 444450 444450 444454 484454 636275 6c6c84@62 -'
'8484a4@62 a09eba babed6 c0c0da 444050 444450 444450 444454 484454 484454 5a586c 6c6c84@62'
'8484a4@62 b0b0c6 dedeea e2e4f0 444050 444450 444450 444454 484454 484454 5a586c 6c6c84@62'
'- 8886a6@62 a19fba e2e4f0 9694a2 444450 444450 444454 484454 636275 6c6c84@62 -'
'- - - 908cae@62 9290b2 73738a 6a687c 6c6a7e 6c6c80@62 - - -'
# 1,7,1   the moon at phase 7 · twilight
'- - - 747290@62 787492 636379 5e5c70 605c72 606074@62 - - -'
'- 6e6c88@62 7c7c97 9ea0b8 707082 40404c 40404c 40404c 42404c 5b586c 646078@62 -'
'6c6c84@62 82849e 9a9eb6 9ea0b8 403c48 40404c 40404c 40404c 42404c 44404e 545064 646078@62'
'6c6c84@62 9090aa b6b6d0 bcb8d4 403c48 40404c 40404c 40404c 42404c 44404e 545064 646078@62'
'- 6e6c88@62 83829d bcb8d4 807c90 40404c 40404c 40404c 42404c 5b586c 646078@62 -'
'- - - 747290@62 787492 636379 5e5c70 605c72 606074@62 - - -'
)

# ── laying a card on the glass ──────────────────────────────────────────────
# A CELL IS BLENDED, NOT STAMPED.  The rim of a sprite is only partly covered
# by it, and what belongs there is the sprite mixed into the glass behind it
# -- which is what rounds a silhouette instead of stepping it.  The card says
# so with @62 on the cells that are partial, and this honours it.
#
# --sharp IS THE OTHER WAY OF SAYING THE SAME PICTURE.  A card is painted as
# cell GROUNDS, which every font can fill; a terminal whose font leaves a gap
# between rows shows him in stripes, and the answer is to paint him as INK on
# a full block instead.  Same colours, same cells, one glyph's difference.
typeset -ga BLROW
blit_rows() {   # blit_rows X Y — the rows waiting in BLROW
  local -i x=$1 y=$2 ry rx sx sy k cr cg cb c r0=${3:-0} r1=${4:--1}
  local cell
  local -F w
  (( r1 < 0 )) && r1=${#BLROW[@]}
  local -i bk=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  local -i gr=$(( (GLASS >> 16) & 255 )) gg=$(( (GLASS >> 8) & 255 )) gb=$(( GLASS & 255 ))
  for (( ry = r0; ry < r1; ry++ )); do
    sy=$(( y + ry ))
    (( sy < 0 || sy >= SCR_H )) && continue
    rx=-1
    for cell in ${=BLROW[$ry]}; do
      (( rx++ ))
      [[ "$cell" == '-' ]] && continue
      sx=$(( x + rx ))
      (( sx < 0 || sx >= SCR_W )) && continue
      cr=$(( 16#${cell[0,1]} )); cg=$(( 16#${cell[2,3]} )); cb=$(( 16#${cell[4,5]} ))
      if [[ "$cell" == *@* ]]; then
        w=$(( ${cell##*@} / 100.0 ))
        cr=$(( int(gr + (cr - gr) * w) ))
        cg=$(( int(gg + (cg - gg) * w) ))
        cb=$(( int(gb + (cb - gb) * w) ))
      fi
      # STRAIGHT INTO THE GRID.  Three hundred and eighty cells a frame, and
      # a mix and a put a cell is nearly eight hundred function calls -- more
      # time than every colour in the marquee costs put together.
      k=$(( bk + sy * TCOLS + sx ))
      c=$(( ((cr & 0xFC) << 16) | ((cg & 0xFC) << 8) | (cb & 0xFC) ))
      if (( OPT_SHARP )); then
        GCH[$k]='█'; GF[$k]=$c; GB[$k]=$GLASS
      else
        # THE INK IS SET TOO, on a cell whose glyph is a space -- which paints
        # nothing and says something: `this cell has been claimed`.  It is what
        # keeps the dust off him without the dust having to know he is there.
        GF[$k]=$c; GB[$k]=$c
      fi
    done
  done
  return 0
}

# ── the pose · a clock and a hash, and no state at all ──────────────────────
# HE IS ALIVE IN HIS EYES AND NOWHERE ELSE.  Two pixel rows are one cell, so
# moving the head a pixel is moving it half a cell -- which re-quantises the
# whole silhouette and everything he is wearing with it.  So he looks about,
# blinks and squints, and his outline never moves.  Three rows of his card
# carry all of it.
#
# ── WHAT WAS WRONG WITH THE OLD CHOREOGRAPHY ──
#
#   THE BLINK TOOK THREE QUARTERS OF A SECOND.  It ran over the first
#   nineteen hundredths of a four-second window, which is 780 milliseconds --
#   and a blink is a hundred to four hundred.  What it read as was a droop.
#
#   AND IT WAS A METRONOME.  It began at the top of every window, so he
#   blinked at 0.0, 4.1, 8.2, 12.3 -- exactly on the beat, for ever.  Nothing
#   alive does that; the giveaway is that you start to expect it.
#
#   AND HE STARED.  A direction was dealt per window and HELD for the whole
#   of it, from a table that was half off-centre -- so half his life was
#   spent looking hard at a wall.  A glance is a departure and a return.
#
# ── AND WHAT IT DOES NOW ──  A blink is a quarter of a second, ASYMMETRIC
# (the close is quicker than the open, which is how an eyelid actually
# moves), and it starts anywhere in its window.  A glance is a brief
# excursion off centre and back, at an irregular moment, in two windows out
# of five -- so his resting state is looking straight out of the glass, which
# is where a face should rest.  Every one of those is still a pure function
# of the clock and a hash of it: no state, nothing to get out of step, and
# the same visitor on two machines at the same instant.
VIS_SEED=0
GLANCE=2.3; BLINK=4.1; QUIRK=11.0
BL_IN=0.06; BL_HOLD=0.05; BL_OUT=0.13      # shut fast, open slower
VIS_POKE=-99.0                              # when a key was last pressed
typeset -gi VIS_POKE_LOOK=-1                # ...and which way that glance goes · his page sets it
typeset -gi VIS_TALK=0                      # 1 while he is talking, on his page

_pdeal() { PD=$(( ((($1 * 2654435761 + $2 * 40503 + VIS_SEED) & 16777215) \
           ^ ((($1 * 2654435761 + $2 * 40503 + VIS_SEED) & 16777215) >> 7)) & 16777215 )) }

# _lids PHASE -> LD · where an eyelid is, PHASE seconds into a blink
_lids() {
  local -F p=$1
  LD=0
  (( p < 0.0 )) && return 0
  if   (( p < BL_IN ));                     then LD=1
  elif (( p < BL_IN + BL_HOLD ));           then LD=2
  elif (( p < BL_IN + BL_HOLD + BL_OUT ));  then LD=1
  fi
  return 0
}

visitor_pose() {   # visitor_pose T -> POSE "look,lids,eye"
  local -F t=$1 gph bst bdur qph
  local -i i g b q look lids eye PD dir
  local -a LOOKS; LOOKS=(-2 -1 1 2)

  # ── the glance · a departure and a return ────────────────────────────────
  i=$(( int(t / GLANCE) )); gph=$(( t - i * GLANCE ))
  _pdeal $i 1; g=$PD
  look=0
  if (( g % 5 < 2 )); then
    dir=${LOOKS[$(( (g >> 4) % 4 ))]}
    bst=$(( 0.15 + ((g >> 8) % 100) / 100.0 * (GLANCE - 1.30) ))
    bdur=$(( 0.45 + ((g >> 12) % 60) / 100.0 ))
    (( gph >= bst && gph < bst + bdur )) && look=$dir
  fi
  # ...and he looks at whoever just pressed something -- toward wherever the
  # thing they just did is about to happen, which VIS_POKE_LOOK says: along
  # the list on a page with one, straight out at the reader on his own page,
  # where a key is somebody typing to him.  It is the one moment he is not on
  # his own clock.
  (( t - VIS_POKE >= 0.0 && t - VIS_POKE < 0.7 )) && look=$VIS_POKE_LOOK
  # ...AND WHILE HE IS TALKING, he looks out of the glass at whoever he is
  # talking to -- no glances off while the words are coming
  (( VIS_TALK )) && look=0

  # ── the blink · a quarter of a second, somewhere in its window ───────────
  i=$(( int(t / BLINK) ))
  _pdeal $i 2; b=$PD
  lids=0
  if (( b % 10 < 8 )); then
    bst=$(( ((b >> 6) % 100) / 100.0 * (BLINK - 0.85) ))
    _lids $(( t - i * BLINK - bst )); lids=$LD
    # one blink in six is a double, the second close following the first
    # open by about the length of the first
    if (( lids == 0 && b % 6 == 0 )); then
      _lids $(( t - i * BLINK - bst - (BL_IN + BL_HOLD + BL_OUT + 0.10) ))
      lids=$LD
    fi
  fi

  # ── the quirk · a squint he holds for a moment, twice a minute ──────────
  # ONE MOOD, AND IT IS THE NARROW ONE.  The wardrobe carries two.  eye=1
  # takes the pupil row down to lid grey -- he narrows.  eye=2 is the only
  # pose in the whole set that reaches band 5, the BROW, where three cells
  # either side go from skin to socket and the eye stands THREE rows tall
  # instead of two: not a mood, a startle.  He is a face in the corner of a
  # menu, and a face that keeps widening its eyes at nothing is asking the
  # reader a question they were never asked.  So the quirk deals the squint
  # and only the squint.  eye=2 stays in the bands, cell for cell as
  # vanity.py printed it, and is never worn.
  i=$(( int(t / QUIRK) )); qph=$(( t - i * QUIRK ))
  _pdeal $i 3; q=$PD
  eye=0
  (( qph >= 0.6 && qph < 1.5 && q % 5 < 2 )) && eye=1
  (( lids )) && eye=0                # a blink outranks a mood
  POSE="$look,$lids,$eye"
  return 0
}

draw_visitor() {   # draw_visitor T
  # DRESSED, he is the arcade's to compose · see vis_draw_dressed below
  if vis_dressed; then vis_draw_dressed "$1"; return 0; fi
  visitor_pose "$1"
  local -i i idx=-1
  for (( i = 0; i < ${#VIS_POSE_K[@]}; i++ )); do
    [[ "${VIS_POSE_K[$i]}" == "$POSE" ]] && { idx=$i; break }
  done
  (( idx < 0 )) && idx=0
  local -a band; band=(${=VIS_POSE_V[$idx]})
  BLROW=("${VIS_ROW[@]}")
  BLROW[5]="${VIS_E5[${band[0]}]}"
  BLROW[6]="${VIS_E6[${band[1]}]}"
  BLROW[7]="${VIS_E7[${band[2]}]}"
  # HIS OWN PLACE.  The card is three columns wider than his skull on each
  # side and three rows taller above it -- that is where a brim would hang,
  # where a cigarette would go and where a top hat would rise -- so it is
  # laid down up and to the left by exactly that much and he stands where he
  # always did.
  blit_rows $(( G_VIS_X - VIS_OX )) $(( G_VIS_Y - VIS_OY ))
  return 0
}

draw_visitor_eyes() {   # draw_visitor_eyes T — rows 5, 6 and 7 of his card
  visitor_pose "$1"
  local -i i idx=-1
  for (( i = 0; i < ${#VIS_POSE_K[@]}; i++ )); do
    [[ "${VIS_POSE_K[$i]}" == "$POSE" ]] && { idx=$i; break }
  done
  (( idx < 0 )) && idx=0
  local -a band; band=(${=VIS_POSE_V[$idx]})
  BLROW=("${VIS_ROW[@]}")
  BLROW[5]="${VIS_E5[${band[0]}]}"
  BLROW[6]="${VIS_E6[${band[1]}]}"
  BLROW[7]="${VIS_E7[${band[2]}]}"
  blit_rows $(( G_VIS_X - VIS_OX )) $(( G_VIS_Y - VIS_OY )) 5 8
  return 0
}

# ── WHAT HE HAS ON · the arcade's wardrobe, worn on this clock ──────────────
# THE ARCADE DRESSES HIM, AND THE DOOR WEARS WHAT IT PUT ON.  The save keeps
# one id a slot -- arcade.worn.hat, .spec, .smoke, .aura -- written by the
# arcade the moment something is bought, worn or taken off, and the arcade
# reloads this door's copy of the save every time it writes.  So what is read
# here is never a visit out of date, and there is no second ledger to drift.
#
# AND HE IS COMPOSED BY THE ARCADE'S OWN WARDROBE, not a copy of it.  The
# first time he is asked to wear something, the arcade's pack is read into
# this process -- read, the way the ARCADE's own door reads it, and NOT
# started: no coin bank loaded, no game dealt, no hooks left bound -- and its
# vn_compose_at lays him out in whatever pose this clock deals him.  He is
# composed in the twelve-step wash his card was printed in, and in that wash
# the wardrobe's bare visitor IS the card above, cell for cell and weight for
# weight, on all twenty-five poses (the harness holds it to that).  So a hat
# changes the hat and not his face, and his rim is as soft in it as without.
typeset -g  VIS_WH='' VIS_WS='' VIS_WK='' VIS_WA=''   # hat · glasses · smoke · aura · '' bare
typeset -gi VIS_WR=0                                   # the wardrobe · 1 in this process · -1 would not come
vis_worn() {   # vis_worn -> VIS_WH VIS_WS VIS_WK VIS_WA, what the arcade last put on him
  local v sl
  local -i i
  local -a got slots
  slots=(hat spec smoke aura); got=('' '' '' '')
  for (( i = 0; i < 4; i++ )); do
    sl="${slots[$i]}"
    v="${SAVE[arcade.worn.$sl]:-}"
    v="${v#\"}"; v="${v%\"}"                          # the arcade quotes it
    # AN ID IS A WORD, and anything else in that field is somebody's hand-edit
    [[ -n "$v" && "$v" != *[^A-Za-z0-9_-]* ]] || v=''
    # A WORN ID NO RACK CARRIES IS BARE -- the arcade's own rule -- asked once
    # the racks are here to be asked
    (( VIS_WR > 0 )) && [[ -n "$v" && -z "${VN_NAME[$sl:$v]:-}" ]] && v=''
    got[$i]="$v"
  done
  VIS_WH="${got[0]}"; VIS_WS="${got[1]}"; VIS_WK="${got[2]}"; VIS_WA="${got[3]}"
  return 0
}
vis_wardrobe() {   # 0 once the arcade's compositor is in this process · read the first time it is wanted
  if (( ${+functions[vn_compose_at]} )); then
    (( VIS_WR > 0 )) || { VIS_WR=1; (( ${#AR_RARC[@]} )) || ar_rar_inks 2>/dev/null; }
    return 0
  fi
  (( VIS_WR < 0 )) && return 1
  local _vw_full="$REPO/scripts/suite/arcade.zsh"
  # NEVER OVER A MACHINE THAT IS STANDING.  An arcade that has been opened has
  # a coin bank and a game in its head, and reading its file again would put
  # both back to how the file starts -- so if the one standing is too old to
  # have vn_compose_at, he stays bare rather than cost anybody their session.
  if [[ -n "${PACK_SEEN[$_vw_full]:-}" || ! -r "$_vw_full" ]]; then VIS_WR=-1; return 1; fi
  # THE NAMES BELOW ARE ITS OWN, because the file is read inside this function
  # and a top-level line of it that set a plain `ok` or `fill` would set these
  local -a _vw_hk
  _vw_hk=("$PACK_NAME" "$PACK_MODEL" "$PACK_INIT" "$PACK_TICK" "$PACK_DRAW" \
          "$PACK_KEY" "$PACK_RAW" "$PACK_DRESS" "$PACK_LEAVE" "$PACK_WARM" "$PACK_FIRST")
  local -i _vw_fill=$PACK_FILL _vw_ok=0
  # THE SAME BREADCRUMB mach_open drops: a pack runs in this process, under
  # this process's `set -u`, and a file that will not load must not take the
  # door down without saying what it said on the way
  PACK_CRUMB="${TMPDIR:-/tmp}/alien-pack.$$"
  PACK_LOG="$PACK_CRUMB.log"
  print -r -- "VISITOR · the arcade's wardrobe · scripts/suite/arcade.zsh" > "$PACK_CRUMB" 2>/dev/null
  : > "$PACK_LOG" 2>/dev/null
  { PACK_SOURCED=1 source "$_vw_full" } 2>>"$PACK_LOG" && _vw_ok=1
  rm -f "$PACK_CRUMB" "$PACK_LOG" 2>/dev/null; PACK_CRUMB=''
  # ...and the hooks it declared on the way in are put back: it was read, not opened
  PACK_NAME="${_vw_hk[0]}"; PACK_MODEL="${_vw_hk[1]}"; PACK_INIT="${_vw_hk[2]}"
  PACK_TICK="${_vw_hk[3]}"; PACK_DRAW="${_vw_hk[4]}";  PACK_KEY="${_vw_hk[5]}"
  PACK_RAW="${_vw_hk[6]}";  PACK_DRESS="${_vw_hk[7]}"; PACK_LEAVE="${_vw_hk[8]}"
  PACK_WARM="${_vw_hk[9]}"; PACK_FIRST="${_vw_hk[10]}"
  PACK_FILL=$_vw_fill
  BEAT_SKIP=1                                  # a one-off, not a frame the governor should see
  if (( _vw_ok && ${+functions[vn_compose_at]} )); then
    VIS_WR=1
    (( ${#AR_RARC[@]} )) || ar_rar_inks 2>/dev/null
    return 0
  fi
  VIS_WR=-1
  return 1
}
# THE WARDROBE IS READ ON THE TICK, NOT IN THE DRAW.  A file read inside a
# function can reach every local of every function above it -- zsh's
# `typeset -g` binds to a caller's local of the same name before it reaches a
# global -- so it is read from the shallowest place this page has: vis_tick,
# which the loop itself calls.  The draw only ever uses what is already in.
vis_dressed() {   # vis_dressed [LOAD] — 0 when he has something on and it can be composed · LOAD 1 reads the wardrobe in
  vis_worn
  [[ -n "$VIS_WH$VIS_WS$VIS_WK$VIS_WA" ]] || return 1
  (( ${+functions[vn_compose_at]} || ${1:-0} )) || return 1
  vis_wardrobe || return 1
  vis_worn                                     # asked again, now the racks can answer
  [[ -n "$VIS_WH$VIS_WS$VIS_WK$VIS_WA" ]]
}
vis_draw_dressed() {   # vis_draw_dressed T — him in what the arcade put on him, on this clock
  local -F t=$1
  local -a p
  local -i fr=0
  visitor_pose $t
  p=(${(s:,:)POSE})
  # THE FRAME ONLY MOVES WHAT MOVES: the wisp and the weather, ten a second as
  # the arcade counts them.  A hat is the same picture every frame, and a frame
  # the compositor has already made is not made again.
  [[ -n "$VIS_WK$VIS_WA" ]] && fr=$(( int(t * 10.0) ))
  # THE TWELVE-STEP WASH, whatever this terminal can take, because it is the
  # wash his card was printed in -- see the note above
  local -i TRUE24=0
  vn_compose_at "$VIS_WH" "$VIS_WS" "$VIS_WK" "$VIS_WA" $fr 0 ${p[0]} ${p[1]} ${p[2]}
  # HIS PAINT ONLY MOVES WITH THE WEATHER.  A smoke's wisp is air over him, so
  # without an aura the cells under it are the same picture from one wisp
  # frame to the next, and the blit need not work them out again.
  local bkey="$VN_LAST"
  [[ -z "$VIS_WA" ]] && bkey="$VIS_WH|$VIS_WS|$VIS_WK|$POSE"
  vis_blit_vn $(( G_VIS_X - VN_OX )) $(( G_VIS_Y - VN_OY )) "$bkey"
  return 0
}
# vis_blit_vn X Y — the arcade's paint (VNC, a colour a cell, and VNA, how much
# of the cell he covers) laid down exactly the way blit_rows lays his card: a
# partial cell mixed into the glass behind it, the ink set on every cell he
# claims, --sharp's full block where that is asked for -- and then the air over
# him (the wisp, the weather) as glyphs that keep whatever ground is under them
# THE CELLS ARE WORKED OUT ONCE A PICTURE, not once a frame: which cells are
# him and what each one comes to after its blend are the same for every frame
# the compositor hands back the same picture, which is nearly all of them.
typeset -ga VIS_BY VIS_BX VIS_BC
typeset -g  VIS_BKEY=''
vis_blit_vn() {   # vis_blit_vn X Y [KEY] · KEY names the paint, VN_LAST by default
  local -i x0=$1 y0=$2 x y i k c cr cg cb sx sy w u n
  local -i bk=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  local bkey="${3:-$VN_LAST}"
  if [[ "$VIS_BKEY" != "$bkey" ]]; then
    local -i gr=$(( (GLASS >> 16) & 255 )) gg=$(( (GLASS >> 8) & 255 )) gb=$(( GLASS & 255 ))
    VIS_BY=(); VIS_BX=(); VIS_BC=()
    for (( y = 0; y < VN_H; y++ )); do
      for (( x = 0; x < VN_W; x++ )); do
        i=$(( y * VN_W + x )); c=${VNC[$i]}
        (( c >= 0 )) || continue
        w=${VNA[$i]:-100}
        if (( w < 100 )); then
          cr=$(( (c >> 16) & 255 )); cg=$(( (c >> 8) & 255 )); cb=$(( c & 255 ))
          cr=$(( int(gr + (cr - gr) * (w / 100.0)) ))
          cg=$(( int(gg + (cg - gg) * (w / 100.0)) ))
          cb=$(( int(gb + (cb - gb) * (w / 100.0)) ))
          c=$(( ((cr & 0xFC) << 16) | ((cg & 0xFC) << 8) | (cb & 0xFC) ))
        else
          c=$(( c & 0xFCFCFC ))
        fi
        VIS_BY+=($y); VIS_BX+=($x); VIS_BC+=($c)
      done
    done
    VIS_BKEY="$bkey"
  fi
  n=${#VIS_BY[@]}
  for (( i = 0; i < n; i++ )); do
    sy=$(( y0 + VIS_BY[i] )); sx=$(( x0 + VIS_BX[i] ))
    (( sy < 0 || sy >= SCR_H || sx < 0 || sx >= SCR_W )) && continue
    k=$(( bk + sy * TCOLS + sx )); c=${VIS_BC[$i]}
    if (( OPT_SHARP )); then GCH[$k]='█'; GF[$k]=$c; GB[$k]=$GLASS
    else GF[$k]=$c; GB[$k]=$c; fi
  done
  for (( i = 0; i < ${#VNO_Y[@]}; i++ )); do
    y=${VNO_Y[$i]}; x=${VNO_X[$i]}; sy=$(( y0 + y )); sx=$(( x0 + x ))
    (( sy < 0 || sy >= SCR_H || sx < 0 || sx >= SCR_W )) && continue
    k=$(( bk + sy * TCOLS + sx ))
    GCH[$k]="${VNO_CH[$i]}"; GF[$k]=${VNO_FG[$i]}
    u=${VNC[$(( y * VN_W + x ))]:--1}
    (( u >= 0 )) && GB[$k]=$u
  done
  return 0
}

draw_celestial() {   # what the arithmetic said is up there
  (( SKY_IDX < 0 )) && return 0
  BLROW=("${(@)SKY_ROW[@]:$(( SKY_IDX * CEL_H )):$CEL_H}")
  blit_rows $G_CEL_X $G_CEL_Y
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 13 · THE MACHINE        arcade.py's section 9, ported whole
# ══════════════════════════════════════════════════════════════════════════
# Everything that is not the glass: marquee, neon, bezel, controls, coin
# TERMINAL, floor.  Every number below is arcade.py's -- the chase light's 1.4
# and its 2.6 falloff, the tube's 2.2 and its 0.55 drift, the side art's
# 0.30 and 0.25, the title's 0.42 sweep and its 3.5 half-width, the floor's
# squared falloff.  What is not the arcade's is WHEN they are computed.
#
# ── THE TWO LAYERS ──  A cabinet is mostly still.  The walls, the bezel, the
# screen frame, the silk-screen, the dividers, the plate, the footer and the
# marquee's own frame do not depend on the clock at all, so they are painted
# ONCE into a layer of their own when the window is measured and copied over
# the canvas each frame -- an array copy of five thousand cells, which zsh
# does in C and in half a millisecond.  What is left to paint on the beat is
# the light: twenty-nine bulbs a strip, the letters, the tubes, the side art,
# the lamps, the message and the spill on the floor.
#
# THE ARCADE MAKES THE SAME SPLIT and holds the light still in TIME as well,
# at CHROME_HZ, because nobody can see a neon tube pulse at a hundred and
# twenty hertz.  This holds it still in SPACE only.  A shell never gets
# within sight of a hundred and twenty, and below a motion's own rate
# quantising it stops being an economy and becomes a staircase -- see
# frame_begin, where that clock used to be.
typeset -ga SCH SF_ SB_
# ── everything that does not move ───────────────────────────────────────────
static_paint() {
  if (( CFG_FILL )); then
    # SCREEN=fill · the whole terminal is one lit screen, no walls, no bezel.
    # The glass is lifted off near-black so it reads as a tube and not the bare
    # window, brighter down the middle and darker at the edges; the content
    # stays centred, its chrome laid on top by fill_chrome, the night held back.
    c_clear
    local -i yy gc; local -F midr fr
    midr=$(( (TROWS - 1) / 2.0 ))
    for (( yy = 0; yy < TROWS; yy++ )); do
      fr=$(( midr > 0.0 ? 1.0 - abs(yy - midr) / midr : 1.0 )); (( fr < 0.0 )) && fr=0.0
      cmix $GLASS $PURPLE $(( 0.05 + 0.055 * fr )); gc=$CM
      c_fill 0 $yy $TCOLS 1 ' ' $GREY $gc
    done
    SCH=("${GCH[@]}"); SF_=("${GF[@]}"); SB_=("${GB[@]}")
    BCH=("${SCH[@]}"); BF_=("${SF_[@]}"); BB_=("${SB_[@]}"); GSTILL_KEY=''
    return 0
  fi
  local -i x0=$(( OX + 2 )) x1=$(( OX + ARC_W - 3 )) w iw i y k c lo
  local -F f kk
  w=$(( x1 - x0 + 1 )); iw=$(( w - 2 ))
  c_clear

  # -- the body · top edge, base, walls and the gradient between them --------
  local line=''
  for (( i = 0; i < ARC_W - 2; i++ )); do line+='═'; done
  c_text $OX $(( OY + R_ARC_TOP )) "╔${line}╗" $ARC_LIT $ARC_DARK
  cshade $ARC_LIT 0.75
  c_text $OX $(( OY + R_ARC_BOT )) "╚${line}╝" $CS $ARC_DARK
  for (( y = OY + R_ARC_TOP + 1; y < OY + R_ARC_BOT; y++ )); do
    kk=$(( (y - OY - R_ARC_TOP) / ((R_ARC_BOT - R_ARC_TOP) + 0.0) ))
    cmix $ARC_BODY $ARC_DARK $(( kk * 0.85 ))
    c_fill $(( OX + C_IN_L )) $y $IN_W 1 ' ' $GREY $CM
    c_put $(( OX + C_WALL_L )) $y '║' $ARC_LIT $ARC_DARK
    c_put $(( OX + C_WALL_R )) $y '║' $ARC_LIT $ARC_DARK
    # the tubes' glyphs · their light is laid on every frame (chrome_light)
    c_put $(( OX + C_TUBE_L )) $y '▐' $ARC_DARK $ARC_DARK
    c_put $(( OX + C_TUBE_R )) $y '▌' $ARC_DARK $ARC_DARK
  done
  # the side art's glyphs · likewise
  for (( y = OY + R_BEZ_TOP; y <= OY + R_BEZ_BOT; y++ )); do
    c_put $(( OX + C_IN_L )) $y '▒' $ARC_DARK $ARC_DARK
    c_put $(( OX + C_IN_L + 1 )) $y '▒' $ARC_DARK $ARC_DARK
    c_put $(( OX + C_IN_R )) $y '▒' $ARC_DARK $ARC_DARK
    c_put $(( OX + C_IN_R - 1 )) $y '▒' $ARC_DARK $ARC_DARK
  done
  # the floor's glyphs, on the void
  for (( i = 0; i < ARC_W; i++ )); do
    (( OX + i < 0 || OX + i >= TCOLS )) && continue
    c_put $(( OX + i )) $(( OY + R_FLOOR )) '▀' $ARC_DARK $VOID
  done

  # -- the bezel and the screen frame ----------------------------------------
  local -i bx=$(( OX + C_IN_L + 3 )) bw=$(( IN_W - 6 )) gl cc
  for (( y = OY + R_BEZ_TOP; y <= OY + R_BEZ_BOT; y++ )); do
    c_fill $bx $y $bw 1 ' ' $GREY $BEZEL
  done
  local -i fx=$(( OX + C_SCR_BOX )) fy=$(( OY + R_SCR_TOP ))
  local -i fw=$(( SCR_W + 2 )) fh=$(( SCR_H + 2 ))
  cmix $BEZEL $CYAN 0.42; gl=$CM
  c_box $fx $fy $fw $fh $gl $BEZEL round
  cmix $gl $WHITE 0.35; cc=$CM
  c_put $fx $fy '╭' $cc
  c_put $(( fx + fw - 1 )) $fy '╮' $cc
  c_put $fx $(( fy + fh - 1 )) '╰' $cc
  c_put $(( fx + fw - 1 )) $(( fy + fh - 1 )) '╯' $cc
  static_silk
  local vent='▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪'
  cshade $GREY 0.45
  c_text $(( fx + 2 )) $(( OY + R_BEZ_BOT )) "$vent" $CS $BEZEL
  c_text $(( fx + fw - 2 - ${#vent} )) $(( OY + R_BEZ_BOT )) "$vent" $CS $BEZEL

  # -- the control panel's plate and both dividers ---------------------------
  local dl=''
  for (( i = 0; i < IN_W - 2; i++ )); do dl+='═'; done
  cshade $ARC_LIT 0.9
  c_text $(( OX + C_IN_L )) $(( OY + R_DIV1 )) "╞${dl}╡" $CS $ARC_DARK
  c_text $(( OX + C_IN_L )) $(( OY + R_DIV2 )) "╞${dl}╡" $CS $ARC_DARK
  c_fill $(( OX + C_IN_L + 2 )) $(( OY + R_PANEL_A )) $(( IN_W - 4 )) 1 ' ' $GREY $PLATE
  c_fill $(( OX + C_IN_L + 2 )) $(( OY + R_PANEL_B )) $(( IN_W - 4 )) 1 ' ' $GREY $PLATE
  c_fill $(( OX + C_IN_L )) $(( OY + R_COIN )) $IN_W 1 ' ' $GREY $DOORP

  SCH=("${GCH[@]}"); SF_=("${GF[@]}"); SB_=("${GB[@]}")
  BCH=("${SCH[@]}"); BF_=("${SF_[@]}"); BB_=("${SB_[@]}"); GSTILL_KEY=''
  return 0
}

# ── the silk-screen · what the machine is called, on its own chrome ─────────
# THE ONE THING ON THE STILL LAYER THAT CHANGES WITHOUT THE WINDOW MOVING: a
# machine opening or closing puts its own name on the bezel.  It used to
# repaint the whole cabinet for it and then forget every cell on the screen,
# which was a sixth of a second of stall at the exact moment a transition
# wants its first frames.  Now the one row is painted and the layer keeps up.
static_silk() {
  local -i fx=$(( OX + C_SCR_BOX )) fw=$(( SCR_W + 2 )) y=$(( OY + R_BEZ_TOP ))
  c_fill $(( fx + 1 )) $y $(( fw - 2 )) 1 ' ' $GREY $BEZEL
  cshade $MAGENTA 0.8; c_text $(( fx + 1 )) $y '◤' $CS $BEZEL
  cshade $GREY 0.85
  c_text $(( fx + 3 )) $y "MODEL $SURF_MODEL" $CS $BEZEL
  local rt='SYNTHWAVE SERIES'
  c_text $(( fx + fw - 2 - ${#rt} )) $y "$rt" $CS $BEZEL
  # ...AND THE SIGN BETWEEN THEM, WHEN THE SURFACE HAS ONE.  It has no row of
  # its own -- it is let into the bezel's top lip, sharing that row with the
  # plate at either end of it, the way a cabinet carries its name silkscreened
  # on the glass surround rather than on a shelf above it.  TERMINAL leaves it
  # empty because the glass under it already opens with its name.
  if [[ -n "$SURF_SIGN" ]]; then
    cmix $MAGENTA $WHITE 0.25
    c_text $(( fx + (fw - ${#SURF_SIGN}) / 2 )) $y "$SURF_SIGN" $CM $BEZEL
  fi
  cshade $CYAN 0.8; c_text $(( fx + fw - 2 )) $y '◥' $CS $BEZEL
  return 0
}
redress() {   # redress — the chrome words changed, the window did not
  local -i k0=$(( (OY + R_BEZ_TOP) * TCOLS )) k1
  k1=$(( k0 + TCOLS - 1 ))
  (( ${#SCH[@]} == GN )) || { rebuild; return 0 }
  glass_unbake                         # the bare layer, before a row of it is redone
  # paint the row on the canvas, then lift that row into the still layer
  GCH[$k0,$k1]=("${(@)SCH[@]:$k0:$TCOLS}")
  GF[$k0,$k1]=("${(@)SF_[@]:$k0:$TCOLS}")
  GB[$k0,$k1]=("${(@)SB_[@]:$k0:$TCOLS}")
  static_silk
  SCH[$k0,$k1]=("${(@)GCH[@]:$k0:$TCOLS}")
  SF_[$k0,$k1]=("${(@)GF[@]:$k0:$TCOLS}")
  SB_[$k0,$k1]=("${(@)GB[@]:$k0:$TCOLS}")
  BCH[$k0,$k1]=("${(@)GCH[@]:$k0:$TCOLS}")
  BF_[$k0,$k1]=("${(@)GF[@]:$k0:$TCOLS}")
  BB_[$k0,$k1]=("${(@)GB[@]:$k0:$TCOLS}")
  GLASS_KEY=''; GLCH=()
  return 0
}

# ── the light · everything that answers the clock ───────────────────────────
# THE LIGHT IS LOOKED UP, NOT WORKED OUT.  Every lamp on the cabinet is a
# periodic function of (where it is, the clock), and a periodic function is a
# table: the tubes' phase is cut into 256 steps and the four colours a step
# needs are worked out once; the side art's breathing into 64; the floor's
# into 64 per column.  A step is a two-hundred-and-fifty-sixth of a cycle,
# which is under one level of one channel -- nothing a tube can show -- and
# it turns fifteen milliseconds of trigonometry and mixing a frame into a
# millisecond of reads.  The glyphs themselves never change and live on the
# still layer; only the inks move.
typeset -ga NEON_LF NEON_LB NEON_RF NEON_RB NEON_PH0
typeset -gA SIDE_C FLOOR_C
typeset -gi NEON_N=0
neon_init() {
  (( NEON_N )) && return 0
  local -i st h=$(( R_ARC_BOT - R_ARC_TOP - 1 )) i
  local -i pr=$(( (PURPLE >> 16) & 255 )) pg=$(( (PURPLE >> 8) & 255 )) pb=$(( PURPLE & 255 ))
  local -i mr=$(( (MAGENTA >> 16) & 255 )) mg=$(( (MAGENTA >> 8) & 255 )) mb=$(( MAGENTA & 255 ))
  local -i yr=$(( (CYAN >> 16) & 255 )) yg=$(( (CYAN >> 8) & 255 )) yb=$(( CYAN & 255 ))
  local -i dr=$(( (ARC_DARK >> 16) & 255 )) dg=$(( (ARC_DARK >> 8) & 255 )) db=$(( ARC_DARK & 255 ))
  local -i tr tg tb
  local -F v sh gv
  NEON_LF=(); NEON_LB=(); NEON_RF=(); NEON_RB=(); NEON_PH0=()
  for (( st = 0; st < 256; st++ )); do
    v=$(( 0.55 + 0.45 * sin(st / 256.0 * TAU) ))
    sh=$(( 0.55 + 0.45 * v )); gv=$(( 0.22 * v ))
    tr=$(( int(pr + (mr - pr) * v) )); tg=$(( int(pg + (mg - pg) * v) )); tb=$(( int(pb + (mb - pb) * v) ))
    NEON_LF+=($(( ((int(tr * sh) > 255 ? 252 : (int(tr * sh) & 0xFC)) << 16) \
                | ((int(tg * sh) > 255 ? 252 : (int(tg * sh) & 0xFC)) <<  8) \
                |  (int(tb * sh) > 255 ? 252 : (int(tb * sh) & 0xFC)) )))
    NEON_LB+=($(( ((int(dr + (tr - dr) * gv) & 0xFC) << 16) \
                | ((int(dg + (tg - dg) * gv) & 0xFC) <<  8) \
                |  (int(db + (tb - db) * gv) & 0xFC) )))
    tr=$(( int(pr + (yr - pr) * v) )); tg=$(( int(pg + (yg - pg) * v) )); tb=$(( int(pb + (yb - pb) * v) ))
    NEON_RF+=($(( ((int(tr * sh) > 255 ? 252 : (int(tr * sh) & 0xFC)) << 16) \
                | ((int(tg * sh) > 255 ? 252 : (int(tg * sh) & 0xFC)) <<  8) \
                |  (int(tb * sh) > 255 ? 252 : (int(tb * sh) & 0xFC)) )))
    NEON_RB+=($(( ((int(dr + (tr - dr) * gv) & 0xFC) << 16) \
                | ((int(dg + (tg - dg) * gv) & 0xFC) <<  8) \
                |  (int(db + (tb - db) * gv) & 0xFC) )))
  done
  for (( i = 0; i < h; i++ )); do NEON_PH0+=($(( (i / (h + 0.0)) * 2.2 ))); done
  NEON_N=256
  return 0
}
chrome_light() {   # chrome_light T
  local -F t=$1 f v ph kk tph
  local -i i y dx k st c
  neon_init

  # -- the neon tubes running up both walls ----------------------------------
  local -i h=$(( R_ARC_BOT - R_ARC_TOP - 1 ))
  tph=$(( t * 0.55 ))
  for (( i = 0; i < h; i++ )); do
    ph=$(( NEON_PH0[i] - tph ))
    st=$(( int((ph - floor(ph)) * 256) & 255 ))
    k=$(( (OY + R_ARC_TOP + 1 + i) * TCOLS + OX + C_TUBE_L ))
    GF[$k]=${NEON_LF[$st]}; GB[$k]=${NEON_LB[$st]}
    k=$(( k + C_TUBE_R - C_TUBE_L ))
    GF[$k]=${NEON_RF[$st]}; GB[$k]=${NEON_RB[$st]}
  done

  # -- the side art panels between the tube and the bezel --------------------
  local key
  local -i span=$(( (R_BEZ_BOT - R_BEZ_TOP) > 1 ? (R_BEZ_BOT - R_BEZ_TOP) : 1 ))
  for (( y = OY + R_BEZ_TOP; y <= OY + R_BEZ_BOT; y++ )); do
    i=$(( y - OY - R_BEZ_TOP ))
    kk=$(( i / (span + 0.0) ))
    wave $t $MO_SLOW $(( kk * 4 ))
    st=$(( int(WV * 63.999) ))
    for dx in 0 1; do
      key="$i,$dx,$st"
      c="${SIDE_C[$key]:-}"
      if [[ -z "$c" ]]; then
        (( dx )) && cmix $PURPLE $CYAN $kk || cmix $MAGENTA $CYAN $kk
        cshade $CM $(( 0.30 + 0.25 * (st / 63.0) ))
        c=$CS; SIDE_C[$key]=$c
      fi
      GF[$(( y * TCOLS + OX + C_IN_L + dx ))]=$c
      GF[$(( y * TCOLS + OX + C_IN_R - dx ))]=$c
    done
  done

  # -- the spill on the floor ------------------------------------------------
  local -i frow=$(( (OY + R_FLOOR) * TCOLS ))
  local -i mr=$(( (MAGENTA >> 16) & 255 )) mg=$(( (MAGENTA >> 8) & 255 )) mb=$(( MAGENTA & 255 ))
  local -i pr=$(( (PURPLE >> 16) & 255 )) pg=$(( (PURPLE >> 8) & 255 )) pb=$(( PURPLE & 255 ))
  local -F sc
  tph=$(( t * MO_SLOW ))
  for (( i = 0; i < ARC_W; i++ )); do
    (( OX + i < 0 || OX + i >= TCOLS )) && continue
    ph=$(( tph + i * 0.2 / TAU ))
    st=$(( int((ph - floor(ph)) * 64) & 63 ))
    key="$i,$st"
    c="${FLOOR_C[$key]:-}"
    if [[ -z "$c" ]]; then
      f=$(( abs(i - ARC_W / 2.0) / (ARC_W / 2.0) ))
      v=$(( (1.0 - f) ** 2 * (0.55 + 0.15 * (0.5 + 0.5 * sin(st / 64.0 * TAU))) ))
      sc=$(( v * 0.8 ))
      c=$(( ((int((mr + (pr - mr) * f) * sc) & 0xFC) << 16) \
          | ((int((mg + (pg - mg) * f) * sc) & 0xFC) <<  8) \
          |  (int((mb + (pb - mb) * f) * sc) & 0xFC) ))
      FLOOR_C[$key]=$c
    fi
    GF[$(( frow + OX + i ))]=$c
  done

  # -- the brand under the glass, breathing -------------------------------
  local -i fx=$(( OX + C_SCR_BOX )) fw=$(( SCR_W + 2 ))
  wave $t $MO_SLOW 0
  cmix $GREY $MAGENTA $(( 0.35 + 0.25 * WV ))
  c_center $(( OY + R_BEZ_BOT )) '◂ A L I E N   D Y N A M I C S ▸' $CM $BEZEL $fx $fw
  return 0
}

# -- the footer, outside the machine ---------------------------------------
draw_footer() {
  local -i y=$(( OY + R_FOOT ))
  local left='(C) 1984 ALIEN DYNAMICS' right="$P_HOST · $P_OS"
  # ALIEN_DEBUG_FPS · what it is managing, what it is aiming at, and what the
  # panel says it can take.  arcade.py's own switch, in arcade.py's own place.
  [[ -n "${ALIEN_DEBUG_FPS:-}" ]] && \
    right="$(printf '%.3g/%.3g fps · %.0f hz panel' $FPS_SEEN $FPS $HZ)"
  cshade $DIM 0.9; local -i c=$CS
  # THE ROW IS THE MACHINE'S, ALL OF IT.  The footer is three separate runs
  # written on the void, and the void is where the sky is allowed to be -- so
  # the cells BETWEEN and BESIDE them answered every test a star asks and
  # collected specks, one of which lands at OX + ARC_W - 1: hard against the
  # last character of the right-hand line, with no space between, where it
  # reads as punctuation somebody typed.  It is not a twinkle either; a
  # star's column is a pure function of its slot, so it sits there for the
  # whole session.  So the row is CLAIMED across the cabinet's width before a
  # word of it is written -- an ink on a space, which paints nothing and says
  # `this is the machine`.  Left of OX and right of the far wall it is still
  # night, and still has stars in it.
  c_fill $OX $y $ARC_W 1 ' ' $c $VOID
  c_text $(( OX + 1 )) $y "$left" $c $VOID
  cmix $DIM $MAGENTA 0.4
  c_center $y '▚ SYNTHWAVE SERIES ▞' $CM $VOID $OX $ARC_W
  [[ -n "$right" ]] && c_text $(( OX + ARC_W - 1 - ${#right} )) $y "$right" $c $VOID
  return 0
}

# ── the control panel · the cluster, the buttons, the START lamp ───────────
# THIS IS ARCADE.PY'S ROW AGAIN, and it went the long way round to get here.
# The cabinet has six buttons because six is what a cabinet you PLAY has;
# TERMINAL had two switches in their place, each with its letter and its name
# printed beside it, because it had two things worth setting.  Then it had
# one.  Now it has none -- and a control panel built around switches that are
# not there is a row with a hole in the middle of it.
#
# So the buttons come back, in the arcade's own six inks, pulsing on the
# arcade's own wave.  They do nothing, and they are not pretending to: a
# cabinet's panel is a piece of the machine, and this is the piece.  The
# cluster still breathes and the START lamp still says the machine is live.
BTN=()
draw_panel() {   # draw_panel T
  local -F t=$1 gl
  local -a segs
  local seg txt
  local -i i px pw w=0 x
  px=$(( OX + C_IN_L + 2 )); pw=$(( IN_W - 4 ))
  wave $t $MO_SLOW 0
  cshade $GREY 0.7; segs+=("◄|$CS")
  cmix $RED $PINK $WV; segs+=("◉|$CM")
  cshade $GREY 0.7; segs+=("►|$CS")
  segs+=("      |$GREY")
  for (( i = 0; i < ${#BTN[@]}; i++ )); do
    wave $t $MO_SLOW $(( i * 0.9 ))
    cshade ${BTN[$i]} $(( 0.55 + 0.45 * WV ))
    segs+=("●|$CS")
    segs+=("  |$GREY")
  done
  segs+=("    |$GREY")
  wave $t $MO_ALERT 0
  cmix $LIME $WHITE $(( 0.35 * WV )); local -i sc=$CM
  cshade $sc 0.8
  segs+=(" ▸|$CS"); segs+=(" START|$sc"); segs+=(" ◂|$CS")
  for (( i = 0; i < ${#segs[@]}; i++ )); do w=$(( w + ${#${segs[$i]%%|*}} )); done
  x=$(( px + (pw - w) / 2 )); (( x < px )) && x=$px
  for seg in "${segs[@]}"; do
    txt="${seg%%|*}"
    c_text $x $(( OY + R_PANEL_A )) "$txt" ${seg#*|} $PLATE
    x=$(( x + ${#txt} ))
  done
  # ROW B IS THE MENU, SPELLED OUT.  arcade.py calls it the legend and drops
  # hints from the end until what is left fits the plate, because center()
  # does not clip and a legend wider than the plate gets drawn straight over
  # the cabinet's own frame.  TERMINAL's strip is short enough to keep every
  # key, and it is clipped anyway rather than trusted.
  cshade $GREY 1.0
  c_center $(( OY + R_PANEL_B )) "${SURF_KEYS[0,$(( pw - 1 ))]}" $CS $PLATE $px $pw
  return 0
}

PANEL_KEYS=''
panel_keys() {
  # S_N AND NOT R_N.  The strip names the rows that HAVE a letter; the
  # machines are rows too now, and they have none -- printing them here would
  # put `[]SYSTEM` on the control panel and promise a key that is not on it.
  local out='' i
  for (( i = 0; i < S_N; i++ )); do
    out+="${out:+   }[${U_KEY[$i]}]${U_NAME[$i]}"
  done
  PANEL_KEYS="$out   [Q]POWER OFF"
  return 0
}

# ── SCREEN=fill · the chrome, laid on bare glass instead of the cabinet ──────
# The frame is hidden in fill mode, so the three things it carried -- the sign
# over the glass, the key strip on the panel, the message on the coin door --
# are drawn here on the glass instead, in the same rows they would have had, so
# the reader loses the walls and the neon but not the name, the keys or the
# talk-back.  The message keeps the coin door's own fade (draw_coin).
fill_chrome() {   # fill_chrome T
  local -F t=$1 age a
  local -i cx=$(( OX + C_SCR )) cw=$SCR_W c
  if [[ -n "$SURF_SIGN" ]]; then
    cmix $MAGENTA $WHITE 0.25
    c_center $(( OY + R_BEZ_TOP )) "$SURF_SIGN" $CM $GLASS $cx $cw
  fi
  cshade $GREY 1.0
  c_center $(( OY + R_PANEL_B )) "${SURF_KEYS[0,$(( cw - 1 ))]}" $CS $GLASS $cx $cw
  local msg="${SAY_MSG:-${SURF_MSG:-$GREETING}}"
  if [[ -n "$SAY_MSG" ]]; then
    age=$(( $EPOCHREALTIME - SAY_T ))
    a=$(( age / MO_TOAST_FADE )); (( (MO_TOAST - age) / MO_TOAST_FADE < a )) && a=$(( (MO_TOAST - age) / MO_TOAST_FADE ))
    (( a > 1.0 )) && a=1.0; (( a < 0.0 )) && a=0.0
    wave $t $MO_BREATHE 0; cmix $AMBER $WHITE $(( 0.20 + 0.25 * WV )); cmix $GLASS $CM $a; c=$CM
  else
    age=$(( $EPOCHREALTIME - SAY_T ))
    a=$(( (age - MO_TOAST) / MO_TOAST_FADE ))
    (( a > 1.0 )) && a=1.0; (( a < 0.0 )) && a=0.0
    wave $t $MO_SLOW 0; cmix $LIME $WHITE $(( 0.25 * WV )); cmix $GLASS $CM $a; c=$CM
  fi
  c_center $(( OY + R_COIN )) "${msg[0,$(( cw - 1 ))]}" $c $GLASS $cx $cw
  return 0
}

# ── the coin door · what the machine has to say, and what it is holding ─────
SAY_MSG=''; typeset -F SAY_T=-1000.0
draw_coin() {   # draw_coin T
  local -F t=$1
  local -i y=$(( OY + R_COIN )) sx=$(( OX + C_IN_L + 4 ))
  cmix $DOORP $GREY 0.16; local -i plate=$CM
  cshade $GREY 0.75; local -i dimg=$CS
  c_text $sx $y '[' $dimg $plate
  c_text $(( sx + 1 )) $y '▬' $GREY $plate
  c_text $(( sx + 2 )) $y ']' $dimg $plate
  # THE MESSAGE.  A greeting when nothing has happened, and whatever the last
  # key had to say for six seconds after it happened -- which is the one
  # place on this machine where TERMINAL talks back.
  local msg="${SAY_MSG:-${SURF_MSG:-$GREETING}}"
  local -i c
  local -F age a
  if [[ -n "$SAY_MSG" ]]; then
    # THE MESSAGE HAS EDGES: it comes up over MO_TOAST_FADE, stands for
    # MO_TOAST, and goes down over the same fade -- from the door's own
    # plate rather than from nothing, so it reads as a lamp rather than a cut.
    age=$(( $EPOCHREALTIME - SAY_T ))
    a=$(( age / MO_TOAST_FADE )); (( (MO_TOAST - age) / MO_TOAST_FADE < a )) && a=$(( (MO_TOAST - age) / MO_TOAST_FADE ))
    (( a > 1.0 )) && a=1.0; (( a < 0.0 )) && a=0.0
    wave $t $MO_BREATHE 0; cmix $AMBER $WHITE $(( 0.20 + 0.25 * WV )); cmix $DOORP $CM $a; c=$CM
  else
    # ...and the greeting comes back the same way after one has gone
    age=$(( $EPOCHREALTIME - SAY_T ))
    a=$(( (age - MO_TOAST) / MO_TOAST_FADE ))
    (( a > 1.0 )) && a=1.0; (( a < 0.0 )) && a=0.0
    wave $t $MO_SLOW 0; cmix $LIME $WHITE $(( 0.25 * WV )); cmix $DOORP $CM $a; c=$CM
  fi
  local room=$(( 44 ))
  c_text $(( sx + 5 )) $y "${(r:$room:)${msg[0,$(( room - 1 ))]}}" $c $DOORP
  local tag="$SURF_TAG"
  local -i tx=$(( sx + 5 + room + 2 ))
  local -i badge_w
  # THE BADGE IS THE SURFACE'S OWN.  TERMINAL's is the mirror, which is the
  # one figure on this door that can be WRONG about the reader's home folder;
  # a machine standing here has something else worth a lit corner, and says so.
  local label
  if [[ -n "$SURF_BADGE" ]]; then label="$SURF_BADGE"
  else printf -v label ' MIRROR %02d/%02d ' $(( P_LINKED > 99 ? 99 : P_LINKED )) $(( P_LEAVES > 99 ? 99 : P_LEAVES )); fi
  badge_w=${#label}
  local -i lx=$(( OX + C_IN_R - badge_w - 1 ))
  if (( lx - tx >= ${#tag} )); then
    cshade $GREY 0.6
    c_text $(( tx + (lx - tx - ${#tag}) / 2 )) $y "$tag" $CS $DOORP
  fi
  local -i lc=$LIME
  if [[ -z "$SURF_BADGE" ]]; then
    (( P_LEAVES && P_LINKED >= P_LEAVES )) || lc=$AMBER
    (( P_LEAVES )) || lc=$RED
  fi
  cmix $WHITE $lc 0.35; local -i ink=$CM
  cmix $BLACK $lc 0.32
  c_text $lx $y "$label" $ink $CM
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 14 · THE NIGHT OUTSIDE      arcade.py's suite sky, and the streak
# ══════════════════════════════════════════════════════════════════════════
# The void around the machine is not flat and it is not black: it is the
# suite's own starfield, cut by TERMINAL's arithmetic -- one slot every
# eighteen columns, a Weyl hash folded once so neighbouring rows do not
# rhyme, a seventh of the slots left empty (a star in every stride is a
# lattice, and a lattice is the opposite of weather), and a fifty-six phase
# twinkle turning at a third of the sky's own clock.
#
# DRAWN BEFORE THE MACHINE, so the cabinet paints over it and the stars are
# only ever where the machine is not.
SKY_SEED=0
SKY_DEN_DIV=18
SKY_FAR=0; SKY_NEAR=0; SKY_LIT=0
sky_init() {
  _pack  68  68  68; SKY_FAR=$PK       # xterm 238 · TERMINAL's own three
  _pack 148 148 148; SKY_NEAR=$PK      # xterm 246
  _pack 218 218 218; SKY_LIT=$PK       # xterm 253
  (( MOCK )) && SKY_SEED=1988 || SKY_SEED=$(( (RANDOM * 32768 + RANDOM) & 16777215 ))
  return 0
}
suite_sky() {   # suite_sky T
  # ck IS NOT k, AND THAT IS THE POINT.  `k` is how many slots a row has and
  # it is the inner loop's own bound; a cell index written into it turns
  # seven iterations a row into five thousand, and the sky -- five
  # milliseconds of work -- became six hundred.  The picture was still right,
  # which is what made it a slow machine rather than a broken one.
  local -i w=$TCOLS h=$TROWS k ck stride r slot hsh col ph tw
  k=$(( w / SKY_DEN_DIV )); (( k < 1 )) && return 0
  stride=$(( w / k )); (( stride < 4 )) && return 0
  # TERMINAL advances its sky twenty times a second at a calm 600/1000, and
  # the twinkle turns at a third of that
  tw=$(( int($1 * 12.0) / 3 ))
  local g
  local -i ink
  for (( r = 0; r < h; r++ )); do
    for (( slot = 0; slot < k; slot++ )); do
      hsh=$(( ((r + 1) * 2654435761 + slot * 40503 + w * 97 + SKY_SEED * 7919) & 16777215 ))
      hsh=$(( (hsh ^ (hsh >> 7)) & 16777215 ))
      (( hsh % 7 == 0 )) && continue
      col=$(( slot * stride + 1 + hsh % (stride - 2) ))
      (( col >= w )) && continue
      ph=0
      (( hsh % 3 )) && ph=$(( ((hsh >> 8) + tw) % 56 ))
      # THE SKY IS ONLY EVER WHERE THE MACHINE IS NOT.  arcade.py draws it
      # BEFORE the cabinet and lets the cabinet paint over it; the cabinet
      # here is already down when this runs, because it is copied whole from
      # a layer rather than drawn.  So the fence is asked of the canvas
      # itself: a cell with no ground AND no glyph on it is a cell nothing
      # has claimed.  Which is exactly the same picture, and it also lets a
      # star sit in the two corners beside the marquee, where the arcade's
      # does -- while keeping one out of the middle of the footer, which is
      # drawn ON the void and was collecting them.
      # THREE QUESTIONS, not two.  The ground and the glyph are not enough:
      # the footer is written ON the void, so every cell of it -- including
      # the SPACES INSIDE ITS WORDS -- answered both and collected specks
      # that then sat there all session, because a star's column is a pure
      # function of its slot and never moves.  The third question is the one
      # draw_motes already asks: has an ink ever been written here.
      ck=$(( r * TCOLS + col ))
      (( GB[$ck] == VOID )) || continue
      (( GF[$ck] < 0 )) || continue
      [[ "${GCH[$ck]}" == ' ' ]] || continue
      if (( ph == 49 || ph == 50 )); then g='✧'; ink=$SKY_LIT
      elif (( ph >= 45 && ph <= 54 )); then g='✦'; ink=$SKY_NEAR
      else g='·'; ink=$SKY_FAR; fi
      GCH[$ck]="$g"; GF[$ck]=$ink
      # the night does not fade with the machine · see post_calc
      (( GDIM_N < DIM_STEPS )) && NIGHTK[$ck]=1
    done
  done
  return 0
}

suite_streak() {   # suite_streak T — TERMINAL's own shooting star
  # THREE OF THE SKY'S OWN MARKS -- a bold glint at the head, a four-point
  # behind it, a far dot dissolving last.  RARE on purpose: a window every
  # two hundred and eighty beats and half the windows empty, so it is an
  # event rather than traffic.  And it never crosses the machine: the streak
  # is fenced off the cabinet's own cells rather than trusting draw order, so
  # what the reader sees is a thing passing BEHIND another thing.
  local -i w=$TCOLS h=$TROWS sbeat hs tt r0 c0 kk tb hr hc ink k
  local g
  (( h < 8 || w <= 40 )) && return 0
  sbeat=$(( int($1 * 12.0) ))
  hs=$(( ((sbeat / 280) * 2654435761 + SKY_SEED * 7919 + 24601) & 16777215 ))
  hs=$(( (hs ^ (hs >> 9)) & 16777215 ))
  (( hs % 2 == 0 )) && return 0
  tt=$(( sbeat % 280 - hs % 256 ))
  (( tt < 0 || tt > 20 )) && return 0
  tt=$(( tt / 2 ))
  r0=$(( 2 + (hs >> 8) % (h - 5) ))
  c0=$(( 1 + (hs >> 4) % (w / 2) ))
  for (( kk = 0; kk < 5; kk++ )); do
    tb=$(( tt - kk ))
    (( tb < 0 )) && continue
    # one row down and two columns across every beat · the same slope the
    # whole flight, which at terminal cell shapes reads as a clean forty-five
    hr=$(( r0 + tb )); hc=$(( c0 + tb * 2 ))
    (( hr < 2 || hr > h - 3 || hc < 1 || hc >= w )) && continue
    k=$(( (hr - 1) * TCOLS + hc - 1 ))
    (( GB[$k] == VOID )) || continue
    (( GF[$k] < 0 )) || continue
    [[ "${GCH[$k]}" == ' ' ]] || continue
    if   (( kk == 0 )); then g='✧'; ink=$WHITE
    elif (( kk <= 2 )); then g='✦'; cmix $CYAN $WHITE 0.4; ink=$CM
    else                     g='·'; ink=$SKY_NEAR; fi
    c_put $(( hc - 1 )) $(( hr - 1 )) "$g" $ink $VOID
    (( GDIM_N < DIM_STEPS )) && NIGHTK[$k]=1
  done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15 · THE GLASS          TERMINAL's own picture, in two columns
# ══════════════════════════════════════════════════════════════════════════
# arcade.py's menu is a LIST on the left, a rule, and a PANEL on the right,
# and the panel is what the row under the cursor is -- a preview of the
# machine, its genre, its rung, its high score.  The shape is kept and the
# subject changes, because a TERMINAL is not a cabinet: the list is what pressing
# a key DOES, the panel is who is standing at TERMINAL, and between them, in
# the column the arcade fills with a game's data, is what every machine in
# this folder is doing right now.
#
# THAT LAST PART IS THE OLD TERMINAL'S LOST LIST, PUT BACK WHERE IT BELONGS.  The
# five machines came off the menu because a menu of things that do not happen
# is not a menu -- and then they were nowhere at all, and --probe was the
# only way to see what a machine wanted.  A reading is not a row you press.
# It is a row you READ, and this is where it goes.

# ── the dust on the pane ────────────────────────────────────────────────────
# Ninety specks at three depths, drifting left, dealt from the arcade's own
# 1988 by an LCG.  The suite's dust is STABLE and it is not random: the same
# ninety specks every opening, on every machine.
typeset -ga MOTE_X MOTE_Y MOTE_S MOTE_C MOTE_G
# a speck's ink and glyph are its depth's, and its depth never changes: they
# were mixed and shaded ninety times a frame, and are now worked out once
mote_colours() {
  local -i i
  MOTE_C=(); MOTE_G=()
  for (( i = 0; i < ${#MOTE_S[@]}; i++ )); do
    cmix $CYAN $WHITE $(( MOTE_S[$i] / 100.0 ))
    cshade $CM $(( 0.5 * (MOTE_S[$i] / 100.0) ))
    MOTE_C[$i]=$CS
    case ${MOTE_S[$i]} in 35) MOTE_G[$i]='·' ;; 55) MOTE_G[$i]='·' ;; *) MOTE_G[$i]='•' ;; esac
  done
  return 0
}
motes_init() {
  (( ${#MOTE_X[@]} )) && return 0
  local -i i s=1988
  for (( i = 0; i < 90; i++ )); do
    s=$(( (s * 1103515245 + 12345) & 2147483647 ))
    MOTE_X[$i]=$(( s % 10000 ))
    s=$(( (s * 1103515245 + 12345) & 2147483647 ))
    MOTE_Y[$i]=$(( s % SCR_H ))
    s=$(( (s * 1103515245 + 12345) & 2147483647 ))
    case $(( s % 3 )) in 0) MOTE_S[$i]=35 ;; 1) MOTE_S[$i]=55 ;; *) MOTE_S[$i]=80 ;; esac
  done
  return 0
}
draw_motes() {   # draw_motes T
  local -F t=$1 fx
  local -i i x y gk base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  (( ${#MOTE_C[@]} == ${#MOTE_S[@]} )) || mote_colours
  for (( i = 0; i < 90; i++ )); do
    fx=$(( MOTE_X[$i] / 10000.0 - t * (MOTE_S[$i] / 100.0) * 0.012 ))
    fx=$(( fx - floor(fx) ))
    x=$(( int(fx * SCR_W) )); y=${MOTE_Y[$i]}
    (( y < 0 || y >= SCR_H || x < 0 || x >= SCR_W )) && continue
    # THE DUST DOES NOT LAND ON A WORD -- and a SPACE INSIDE one is part of
    # the word.  Asking the glyph alone put a speck between `in` and `this`
    # in the mirror's own line, which is the exact thing this test exists to
    # stop: a speck the reader tries to read.  So the cell has to answer
    # nothing TWICE: no glyph on it, and no ink ever written in it.  Both
    # survive the tube -- dimming an ink that is not there is skipped -- so
    # this reads the same on a cached glass as on a fresh one.
    gk=$(( base + y * TCOLS + x ))
    # a window smaller than the cabinet has no cell there at all
    (( gk >= 0 && gk < TCOLS * TROWS )) || continue
    [[ "${GCH[$gk]:-}" == ' ' ]] || continue
    (( ${GF[$gk]:--1} < 0 )) || continue
    # ...AND NOT BESIDE ONE EITHER.  A speck in the cell after `zsh 5.9` is a
    # speck the reader tries to read, and that cell answers every question
    # above it honestly: nothing was painted there, because nothing is ever
    # painted in the space AFTER a word.  Asking only about the cell itself
    # can only keep dust out of writing, never off the end of it.  So the two
    # cells either side are asked the same question and the dust keeps a
    # cell's clearance from anything on the glass -- which costs two array
    # reads on a speck that has already passed the other three tests, and is
    # the difference between weather behind the type and a typo in it.
    #
    # ANYTHING INCLUDES THE OTHER SPECKS, because each one inks the cell it
    # lands in as it goes down, so two that would have landed side by side
    # come out as one.  That is not a side effect worth undoing: a pair of
    # touching specks reads as a mark rather than as dust, which is the same
    # complaint in a different place.
    (( x > 0 && GF[gk - 1] < 0 )) || continue
    (( x < SCR_W - 1 && GF[gk + 1] < 0 )) || continue
    # ...and the speck is dimmed where it lands, by the same tube that dims
    # the glass under it -- on the wire, with everything else
    GCH[$gk]="${MOTE_G[$i]}"; GF[$gk]=${MOTE_C[$i]}
  done
  return 0
}

# ── the hint · every key this surface answers, named ────────────────────────
# Built from the menu that is standing, so the bar and the rows never
# disagree about which keys exist -- ⏎ and the row letters are the same two
# ways of pressing the same thing.
# ══════════════════════════════════════════════════════════════════════════
# app_nav · THE ONE NAVIGATION BAR THE WHOLE SUITE WEARS
# ══════════════════════════════════════════════════════════════════════════
# The menu, a machine's page, the shell, the visitor -- each hands this its own
# keys and nothing else, and the bar rides the same two rows (the glass's last
# two), in the same ink, with the same gap that tightens before it runs off a
# narrow glass.  So walking from one surface to another the bar does not move
# or restyle: it is the same bar, reading different keys.  That single fact is
# most of what makes the suite read as one application rather than five.
#
# KEYS ARE DISPLAY-READY ("[T]", "▴ ▾", "⎋") and the LABEL carries its own
# leading space, the way the menu has always built its hints -- so the menu
# feeds its arrays straight in, and a machine calls the varargs app_nav, and
# both land on the same renderer.
typeset -ga NAVK NAVL
typeset -gi NAV_RR=0 NAV_TR=0
nav_rows() { NAV_RR=$(( SCR_H - 2 )); NAV_TR=$(( SCR_H - 1 )); return 0 }
_app_nav() {   # render the parallel arrays NAVK / NAVL on the footer
  local -i i w=0 x n=${#NAVK[@]} gap=4
  nav_rows
  for (( i = 0; i < n; i++ )); do w=$(( w + ${#NAVK[$i]} + ${#NAVL[$i]} )); done
  # four is the roomy gap, and it gives before the bar does
  while (( gap > 1 && w + (n - 1) * gap > SCR_W - 2 )); do (( gap-- )); done
  w=$(( w + (n - 1) * gap ))
  x=$(( (SCR_W - w) / 2 )); (( x < 0 )) && x=0
  # CLEAR THE TEXT ROW FIRST, keeping its ground · a modal's bar is drawn over
  # the page's own and is the narrower of the two, so without this the wider
  # page bar reads through the ends of it.  Spaces only -- the vignette stays.
  v_fill 0 $NAV_TR $SCR_W 1 ' ' $GREY -2
  cshade $PURPLE 0.75
  v_hline 0 $NAV_RR $SCR_W '─' $CS
  for (( i = 0; i < n; i++ )); do
    v_text $x $NAV_TR "${NAVK[$i]}" $AMBER; x=$(( x + ${#NAVK[$i]} ))
    # THE LABEL IS A WORD YOU READ, so it is lettered in the ink the whole
    # cabinet letters in.  It was $DIM, which is 2.25:1 on the glass -- the
    # suite's own note on the ramp says DIM "is too dark to letter with" and
    # then this, the one row every page shows, lettered with it.  $GREY is
    # 4.72:1; the KEY beside it is still amber and still the loud half.
    v_text $x $NAV_TR "${NAVL[$i]}" $GREY;  x=$(( x + ${#NAVL[$i]} + gap ))
  done
  return 0
}
app_nav() {   # app_nav KEY LABEL KEY LABEL ... — a surface's keys, one call
  NAVK=(); NAVL=()
  while (( $# >= 2 )); do NAVK+=("$1"); NAVL+=(" $2"); shift 2; done
  _app_nav
}

# ══════════════════════════════════════════════════════════════════════════
# app_head · THE ONE TITLE BAR THE WHOLE SUITE WEARS
# ══════════════════════════════════════════════════════════════════════════
# A lit band across the top row, the brand in its left corner, the sky's own
# caption in the right corner -- on every surface, not just the menu -- and a
# rule under it.  The MIDDLE is the caller's: app_head hands back APP_HX (the
# first free column past the brand) and APP_HR (the last before the caption),
# and a machine draws its page name and its readings between them.  So the
# INTELLIGENCE header and the SYSTEM header and the menu's own become the same
# bar wearing different words, the way the footer already is.
typeset -gi APP_HX=0 APP_HR=0
app_head() {   # app_head BRAND
  local brand="$1" cap="$CAPTION"
  local -i hb cc
  cmix $GLASS $PURPLE 0.32; hb=$CM
  v_fill 0 0 $SCR_W 1 ' ' -2 $hb
  cmix $WHITE $CYAN 0.15
  v_text 2 0 "◤ $brand" $CM $hb
  APP_HX=$(( 4 + ${#brand} + 3 ))            # ◤ + space + brand + a two-space gap
  # THE SKY IN THE CORNER IT KEEPS ON THE MENU · a waxing moon in sagittarius or
  # a bright noon, the same line every surface now shows, warmed by day, cooled
  # by night.
  cc=$AMBER
  (( SKY_IDX >= 0 )) && [[ "${SKY_KEY[$SKY_IDX]}" == 1,* ]] && { cmix $CYAN $WHITE 0.25; cc=$CM }
  v_text $(( SCR_W - 2 - ${#cap} )) 0 "$cap" $cc $hb
  APP_HR=$(( SCR_W - 5 - ${#cap} ))            # a clear gap before the caption
  (( APP_HR < APP_HX )) && APP_HR=$APP_HX
  cshade $PURPLE 0.55
  v_hline 0 1 $SCR_W '─' $CS
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE TITLE CARD · every machine is walked into through one
# ══════════════════════════════════════════════════════════════════════════
# THE ARCADE ALWAYS HAD A FRONT: its name in lights over a night of its own,
# a line of what it is, and ◂ PRESS ANY KEY ▸ breathing under it -- while the
# other three opened straight onto a list of their own pages, which is a
# table of contents where a cabinet should have a face.  So every machine
# opens on a card now, the arcade's shape in the machine's own colours, with
# one live thing on it that only that machine could show: the monitor's own
# trace, the agents on their switchboard, the animal itself -- and, the
# arcade's card having been brought into the family too, its wall of
# machines with one of them playing itself on a screen in the middle.
#
# THE SAME FOUR ANSWERS ON EVERY CARD.  Any key goes in.  ⎋, [M] and ⌫ go
# back out -- a card is a door, and stepping back through one is not a
# reason to have to go in first -- and [Q] is still the power switch.  A
# wheel notch is not a key.  tc_key is the one place that is decided.
#
# THE DOOR RAISES IT AND THE MACHINE PAINTS IT.  mach_open puts SURF_TITLE up
# on every open; a machine draws its card while the flag is up -- ticking on
# behind it all the while, so readings land and the animal lives -- and hands
# its keys to tc_key.  The pieces below are the card's whole vocabulary, so
# four machines' cards read as one family: tc_card (the still part, kept, and
# then the night, the lamps and the name, live), tc_base (the band, the black
# CRT and its horizon), tc_big (the name in the block font, lit from one
# colour into another, struck a letter at a time and then a white sweep
# crossing it), tc_spaced (the spaced capitals between two rising wings),
# tc_reveal (a run of type that types itself in), tc_figs and tc_meters (a
# row of figures, or of meters that fill), tc_status, tc_prompt and tc_nav --
# and tc_in, which says how far into its beat any one of them is.
typeset -gi SURF_TITLE=0
typeset -gi TC_X0=0 TC_Y0=0 TC_W=0 TC_H=0        # the CRT the card is drawn on, in glass cells
typeset -ga TC_SX TC_SY TC_SS                     # the card's night · x, y (0..1) and drift
typeset -gA TC_INK                                # inks worked out once and kept
typeset -gi TC_SN=110
typeset -gi TC_PAINT=0                            # a card's still part is being painted (tc_card)
typeset -gA TC_QM                                 # where on it the night stays out, as cells
typeset -gi TC_BW=0                               # the name in lights: its width · each column's ink ·
typeset -ga TC_BCOL TC_BK TC_BC0                  # its lit cells, column by column ·
typeset -ga TC_HLK                                # and its bloom, a letter at a time
typeset -ga TC_REV                                # runs of the still part that type themselves in: x y w at dur …
typeset -ga TC_MTR                                # meters that fill as the card comes up: x y cells pct on off vx vw at how …
                                                  # (how its figure arrives · 0 when the bar is full, 1 a percentage counting, 2 a count, set right)
typeset -gF TC_T0=-1.0 TC_NOW=0.0 TCP=0.0         # when this card went up · how long ago · tc_in's answer
# THE CARD COMES UP IN ORDER, one beat after another, the way an attract
# screen does: the name strikes letter by letter like a neon tube taking, the
# line under it fades up out of the dark, the machine's own picture draws
# itself in, the meters fill, the verdict types out, and ◂ PRESS ANY KEY ▸
# comes last.  About a second and a half -- and none of it stands in the way
# of a key, which goes in whenever it is pressed.
typeset -gF TC_IGN0=0.18 TC_IGN_STEP=0.042 TC_IGN_DUR=0.13   # the strike · the first letter, the next, each one's stutter
typeset -gF TC_SWEEP0=1.10                                    # the white sweep starts once the name has taken
tc_night_init() {   # the stars · dealt once from a fixed seed, so it is the same sky every time
  (( ${#TC_SX[@]} )) && return 0
  local -i i s=1984
  for (( i = 0; i < TC_SN; i++ )); do
    s=$(( (s * 1103515245 + 12345) & 0x7FFFFFFF )); TC_SX+=($(( (s % 10007) / 10007.0 )))
    s=$(( (s * 1103515245 + 12345) & 0x7FFFFFFF )); TC_SY+=($(( (s % 10009) / 10009.0 )))
    s=$(( (s * 1103515245 + 12345) & 0x7FFFFFFF ))
    case $(( s % 5 )) in 0|1) TC_SS+=(0.35) ;; 2|3) TC_SS+=(0.55) ;; *) TC_SS+=(0.90) ;; esac
  done
  return 0
}
# A CARD IS A STILL PICTURE WITH A FEW LIVE THINGS ON IT, and it is drawn as
# one.  Everything that holds still -- the band, the CRT, the name in its
# colours and its bloom, the lines of type, the machine's own diagram -- is
# painted once per KEY (the machine says what its picture depends on) into
# the glass cache, and from then on frame_begin lays it down for nothing.
# The frame itself draws only what moves: the night, the lamps, the name
# striking and then the sweep across it, whatever is still typing itself in,
# and whatever the machine has that is alive.  Painted from scratch, the
# INTELLIGENCE card cost more than either of the pages behind it.
tc_card() {   # tc_card KEY BASEFN T — the still part, kept; then the night, the lamps and the name
  TC_X0=1; TC_Y0=2; TC_W=$(( SCR_W - 2 )); TC_H=$(( SCR_H - 4 ))
  (( TC_T0 < 0.0 )) && TC_T0=$3
  TC_NOW=$(( $3 - TC_T0 ))
  TC_PAINT=1
  glass_cached "tc|$1|$CAPTION|${SCR_W}x${SCR_H}" $2
  TC_PAINT=0
  tc_live $3
  return 0
}
tc_in() {   # tc_in AT DUR -> TCP · how far into that beat of the card coming up, 0 to 1
  TCP=$(( (TC_NOW - $1) / $2 ))
  (( TCP < 0.0 )) && TCP=0.0
  (( TCP > 1.0 )) && TCP=1.0
  return 0
}
tc_base() {   # tc_base BRAND — first in every BASEFN: the band, the black CRT, its horizon
  local -i y base c
  app_head "$1"
  v_fill $TC_X0 $TC_Y0 $TC_W $TC_H ' ' $GREY $BLACK
  # A HORIZON UNDER IT ALL · the CRT's last rows warm toward the cabinet's own
  # violet, faintly, so the night has a floor and the card sits on something
  for y in 1 2 3; do
    c=${TC_INK[hz:$y]:-0}
    (( c )) || { cmix $BLACK $PURPLE $(( 0.035 * y )); c=$CM; TC_INK[hz:$y]=$c }
    v_fill $TC_X0 $(( TC_Y0 + TC_H - 4 + y )) $TC_W 1 ' ' $GREY $c
  done
  TC_QM=(); TC_REV=(); TC_MTR=(); TC_BW=0; TC_BCOL=(); TC_BK=(); TC_BC0=(); TC_HLK=()
  return 0
}
tc_quiet() {   # tc_quiet X Y W H — keep the night out of a rectangle of the still part (glass cells)
  (( TC_PAINT )) || return 0
  local -i x y base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for (( y = $2; y < $2 + $4; y++ )); do
    for (( x = $1; x < $1 + $3; x++ )); do TC_QM[$(( base + y * TCOLS + x ))]=1; done
  done
  return 0
}
tc_reveal() {   # tc_reveal X Y W AT [DUR] — this run of the still part types itself in from AT (glass cells)
  (( TC_PAINT )) || return 0
  TC_REV+=($1 $2 $3 $4 ${5:-0.25})
  return 0
}
tc_live() {   # tc_live T — the night where nothing is drawn, the lamps, the runs typing in, the name
  local -F t=$1 amt=0.40 sp f sw d
  local -i i j e x y k base c q cx got n rw
  # THE NIGHT DRIFTS, three depths of it at three speeds, the arcade's reel's
  # own way · straight into the cells, each depth's ink worked out once, and
  # only into a cell the still part left empty and did not keep quiet
  tc_night_init
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for (( i = 0; i < TC_SN; i++ )); do
    sp=${TC_SS[$i]}
    f=$(( TC_SX[i] - t * sp * 0.012 )); f=$(( f - floor(f) ))
    x=$(( TC_X0 + int(f * TC_W) )); y=$(( TC_Y0 + int(TC_SY[i] * TC_H) ))
    k=$(( base + y * TCOLS + x ))
    [[ "${GCH[$k]}" == ' ' ]] || continue
    (( ${TC_QM[$k]:-0} )) && continue
    c=${TC_INK[s:$sp:$amt]:-0}
    (( c )) || { cmix $CYAN $WHITE $sp; cshade $CM $(( amt * sp )); c=$CS; TC_INK[s:$sp:$amt]=$c }
    if (( sp < 0.6 )); then GCH[$k]='·'; else GCH[$k]='•'; fi
    GF[$k]=$c
  done
  # THE LAMPS where the band's rule and the key bar's rule meet the glass,
  # breathing -- the arcade's, on every card
  wave $t 0.7 0; cmix $MAGENTA $WHITE $(( 0.2 + 0.3 * WV ))
  for y in 1 $(( SCR_H - 2 )); do v_put 0 $y '◆' $CM -2; v_put $(( SCR_W - 1 )) $y '◆' $CM -2; done
  # THE RUNS THAT TYPE THEMSELVES IN · past the cursor, nothing yet; the
  # cursor itself a lit block, the arcade's own amber
  if (( ${#TC_REV[@]} )); then
    c=${TC_INK[cur]:-0}; (( c )) || { cmix $AMBER $WHITE 0.45; c=$CM; TC_INK[cur]=$c }
    for (( i = 0; i < ${#TC_REV[@]}; i += 5 )); do
      tc_in ${TC_REV[i+3]} ${TC_REV[i+4]}
      (( TCP >= 1.0 )) && continue
      rw=${TC_REV[i+2]}; n=$(( int(TCP * rw) ))
      k=$(( base + TC_REV[i+1] * TCOLS + TC_REV[i] ))
      for (( j = n; j < rw; j++ )); do GCH[$(( k + j ))]=' '; done
      (( TCP > 0.0 )) && { GCH[$(( k + n ))]='▌'; GF[$(( k + n ))]=$c; }
    done
  fi
  (( ${#TC_MTR[@]} )) && tc_meters_live
  # THE NAME · struck a letter at a time as the card comes up, and from then
  # on a white sweep crossing it every few seconds (the arcade's headline
  # recipe) · only the columns it is over are touched, each whitening of a
  # column's ink worked out once, at twentieths
  (( TC_BW > 0 )) || return 0
  if (( TC_NOW < TC_IGN0 + (TC_BW / CELL_W + 1) * TC_IGN_STEP + TC_IGN_DUR )); then
    tc_ignite
    return 0
  fi
  sw=$(( (TC_NOW - TC_SWEEP0) * 0.45 ))
  (( sw < 0.0 )) && return 0
  sw=$(( (sw - floor(sw / 1.8) * 1.8) * (TC_BW + 24) - 12 ))
  for (( cx = int(sw) - 6; cx <= int(sw) + 6; cx++ )); do
    (( cx < 0 || cx >= TC_BW )) && continue
    d=$(( abs(cx - sw) ))
    (( d < 6.0 )) || continue
    q=$(( int((1.0 - d / 6.0) ** 2 * 18.0) ))
    (( q > 0 )) || continue
    got=${TC_BCOL[$cx]}
    c=${TC_INK[w:$got:$q]:-0}
    (( c )) || { cmix $got $WHITE $(( q / 20.0 )); c=$CM; TC_INK[w:$got:$q]=$c }
    e=${TC_BC0[$(( cx + 1 ))]}
    for (( j = TC_BC0[cx]; j < e; j++ )); do GF[${TC_BK[$j]}]=$c; done
  done
  return 0
}
tc_ignite() {   # the name striking · a letter that has not taken yet is dark glass, and has no bloom
  local -i li nl cx e j c dk on
  local -F ti ph dur
  local k
  nl=$(( (TC_BW + KERN) / CELL_W ))
  for (( li = 0; li < nl; li++ )); do
    ti=$(( TC_IGN0 + li * TC_IGN_STEP ))
    # no two tubes take quite alike · a little longer or shorter, by letter
    dur=$(( TC_IGN_DUR * (0.75 + 0.125 * ((li * 7) % 5)) ))
    (( TC_NOW >= ti + dur )) && continue
    on=0
    if (( TC_NOW >= ti )); then
      # the stutter of a tube taking: on, a gap, on, a gap, and on for good
      ph=$(( (TC_NOW - ti) / dur ))
      (( ph < 0.20 || (ph >= 0.42 && ph < 0.56) || ph >= 0.78 )) && on=1
    fi
    (( on )) && continue
    for (( cx = li * CELL_W; cx < li * CELL_W + GLYPH_W && cx < TC_BW; cx++ )); do
      c=${TC_BCOL[$cx]}
      dk=${TC_INK[d:$c]:-0}; (( dk )) || { cmix $BLACK $c 0.15; dk=$CM; TC_INK[d:$c]=$dk }
      e=${TC_BC0[$(( cx + 1 ))]}
      for (( j = TC_BC0[cx]; j < e; j++ )); do GF[${TC_BK[$j]}]=$dk; done
    done
    for k in ${(s: :)TC_HLK[$li]}; do GB[$k]=$BLACK; done
  done
  return 0
}
tc_center() {   # tc_center Y TEXT INK [GROUND] [N] — centred on the CRT, Y counted from its top · only its first N, typing
  local s="$2"
  local -i x
  (( ${#s} > TC_W - 2 )) && s="${s[0,$(( TC_W - 3 ))]}"
  x=$(( TC_X0 + (TC_W - ${#s}) / 2 ))
  TC_CX=$x; TC_CW=${#s}                    # where it went, for a machine that types it in
  tc_quiet $x $(( TC_Y0 + $1 )) ${#s} 1
  if [[ -n "${5:-}" ]]; then
    (( $5 > 0 )) || return 0
    s="${s[0,$(( $5 - 1 ))]}"
  fi
  v_text $x $(( TC_Y0 + $1 )) "$s" $3 ${4:--2}
  return 0
}
tc_big() {   # tc_big WORD Y FROM TO — the name in the block font, centred on the CRT at row Y (still part)
  local w="$1"
  local -i y=$(( TC_Y0 + $2 )) bw x i cx k q base got j li nl
  big_width "$w"; bw=$BW
  x=$(( TC_X0 + (TC_W - bw) / 2 ))
  big_word "$w" $x $y $3
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  nl=$(( (bw + KERN) / CELL_W ))
  TC_HLK=(); for (( li = 0; li < nl; li++ )); do TC_HLK+=(''); done
  # THE BLOOM ON BLACK.  big_word mixes it out of the glass's own violet; the
  # card's CRT is black, so it is mixed again out of black, a tint a strength
  # · and kept a letter at a time, so a letter that has not struck yet has none
  for (( i = 0; i < HALN; i++ )); do
    (( HALX[i] < TC_X0 || HALX[i] >= TC_X0 + TC_W || HALY[i] < TC_Y0 || HALY[i] >= TC_Y0 + TC_H )) && continue
    q=$(( int(HALV[i] * 100) ))
    got=${TC_INK[h:$3:$q]:-0}
    (( got )) || { cmix $BLACK $3 $(( 0.135 * q / 100.0 )); got=$CM; TC_INK[h:$3:$q]=$got }
    k=$(( base + HALY[i] * TCOLS + HALX[i] ))
    GB[$k]=$got
    li=$(( (HALX[i] - x) / CELL_W )); (( li < 0 )) && li=0; (( li >= nl )) && li=$(( nl - 1 ))
    TC_HLK[$li]+=" $k"
  done
  # FROM one colour INTO the other across the word, each column's ink worked
  # out once · and the lit cells kept column by column for the strike and the sweep
  TC_BW=$bw; TC_BCOL=(); TC_BK=(); TC_BC0=()
  for (( cx = 0; cx < bw; cx++ )); do
    got=${TC_INK[g:$3:$4:$bw:$cx]:-0}
    (( got )) || { cmix $3 $4 $(( cx / (bw > 1 ? bw - 1.0 : 1.0) )); got=$CM; TC_INK[g:$3:$4:$bw:$cx]=$got }
    TC_BCOL+=($got)
  done
  local -a bycol; for (( cx = 0; cx < bw; cx++ )); do bycol+=(''); done
  for (( i = 0; i < BIGN; i++ )); do
    (( BIGY[i] < TC_Y0 || BIGY[i] >= TC_Y0 + TC_H )) && continue
    cx=$(( BIGX[i] - x ))
    k=$(( base + BIGY[i] * TCOLS + BIGX[i] ))
    GCH[$k]='█'; GF[$k]=${TC_BCOL[$cx]}
    bycol[$cx]+=" $k"
  done
  for (( cx = 0; cx < bw; cx++ )); do
    TC_BC0+=(${#TC_BK[@]})
    TC_BK+=(${(s: :)bycol[$cx]})
  done
  TC_BC0+=(${#TC_BK[@]})
  return 0
}
tc_spaced() {   # tc_spaced Y TEXT FROM TO T [AT] — S P A C E D capitals between two rising wings · fading up from AT
  local s="${2:u}" o='' ch
  local -F t=$5
  local -i i c
  for (( i = 0; i < ${#s}; i++ )); do
    ch="${s[$i,$i]}"
    if [[ "$ch" == ' ' ]]; then o+='  '; else o+="${o:+ }$ch"; fi
  done
  o="▁▂▃▄▅▆▇█  $o  █▇▆▅▄▃▂▁"
  # A DRIFT OF COLOUR, NOT A MOTION, so it is taken in forty-eighths: a step
  # that size is under what an eye can see, and a row whose ink has not moved
  # is a row the renderer does not send · the five-second drift was seventy
  # cells re-sent every frame of the card for a change nobody could see
  wave $t 0.2 0; cmix $3 $4 $(( int(WV * 48.0 + 0.5) / 48.0 )); cshade $CM 0.9; c=$CS
  if [[ -n "${6:-}" ]]; then
    tc_in $6 0.32
    (( TCP > 0.0 )) || return 0
    (( TCP < 1.0 )) && { cmix $BLACK $c $(( int(TCP * 12.0) / 12.0 )); c=$CM; }
  fi
  tc_center $1 "$o" $c
  return 0
}
tc_figs() {   # tc_figs Y LABEL VALUE [LABEL VALUE]... — the machine's figures, in one centred row (still part) · TC_MJX/TC_MJW span a run
  local -i y=$(( TC_Y0 + $1 )) tw=0 gx i n gap=7 gq=0 gr=0 jx=$TC_MJX jw=$TC_MJW
  TC_MJX=0; TC_MJW=0
  shift
  local -a a; a=("$@")
  n=$(( ${#a[@]} / 2 ))
  (( n )) || return 0
  for (( i = 0; i < n; i++ )); do tw=$(( tw + ${#a[2*i]} + 1 + ${#a[2*i+1]} )); done
  if (( jw > 0 && n > 1 && jw - tw >= (n - 1) * 5 )); then
    gq=$(( (jw - tw) / (n - 1) )); gr=$(( (jw - tw) % (n - 1) )); tw=$jw; gx=$jx
  else
    jw=0; tw=$(( tw + (n - 1) * 7 )); gx=$(( TC_X0 + (TC_W - tw) / 2 ))
  fi
  tc_quiet $gx $y $tw 1
  for (( i = 0; i < n; i++ )); do
    if (( i )); then
      (( jw )) && gap=$(( gq + (i <= gr ? 1 : 0) ))
      cshade $PURPLE 0.8; v_text $(( gx + gap / 2 )) $y '·' $CS; gx=$(( gx + gap ))
    fi
    v_text $gx $y "${a[2*i]}" $GREY; gx=$(( gx + ${#a[2*i]} + 1 ))
    v_text $gx $y "${a[2*i+1]}" $WHITE; gx=$(( gx + ${#a[2*i+1]} ))
  done
  TC_FX=$(( gx - tw )); TC_FW=$tw          # where the row went, for a machine that types it in
  return 0
}
typeset -gi TC_FX=0 TC_FW=0 TC_CX=0 TC_CW=0
# A METER A FIGURE · LABEL ▰▰▰▰▱▱▱▱ VALUE, the bar coloured by how full: an
# instrument's own kind of figure, where a percentage is the honest reading.
# Painted into the still part; as the card comes up the bars fill from empty
# and the numbers count up with them (tc_meters_live).
typeset -gi TC_MJX=0 TC_MJW=0   # set both, and the next tc_meters spans exactly that run rather than centring itself
tc_meters() {   # tc_meters Y AT LABEL PCT VALUE [LABEL PCT VALUE]... — PCT -1 is a figure with no bar
  local -i y=$(( TC_Y0 + $1 )) tw=0 txt=0 nb=0 gx i n p on off cells=8 col ispct gap=7 gq=0 gr=0 jx=$TC_MJX jw=$TC_MJW
  local -F at=$2
  TC_MJX=0; TC_MJW=0                                 # a one-call setting
  shift 2
  local -a a; a=("$@")
  n=$(( ${#a[@]} / 3 ))
  (( n )) || return 0
  for (( i = 0; i < n; i++ )); do
    txt=$(( txt + ${#a[3*i]} + 1 + ${#a[3*i+2]} ))
    (( a[3*i+1] >= 0 )) && nb=$(( nb + 1 ))
  done
  # SPANNING A RUN, the meters take its width: the bars as long as the run
  # allows (five cells to twelve) and the room left shared out between them,
  # so the row's ends sit under the ends of whatever it is set beneath
  if (( jw > 0 && n > 1 )); then
    if (( nb )); then
      cells=$(( (jw - txt - (n - 1) * 5) / nb - 1 )); (( cells > 12 )) && cells=12
    fi
    if (( cells >= 5 )); then
      tw=$(( txt + nb * (cells + 1) ))
      gq=$(( (jw - tw) / (n - 1) )); gr=$(( (jw - tw) % (n - 1) ))
      tw=$jw; gx=$jx
    else
      cells=8; jw=0
    fi
  else
    jw=0
  fi
  if (( ! jw )); then
    tw=$(( txt + nb * (cells + 1) + (n - 1) * 7 ))
    gx=$(( TC_X0 + (TC_W - tw) / 2 ))
  fi
  tc_quiet $gx $y $tw 1
  tc_reveal $gx $y $tw $at 0.01                    # the row is not there until its beat
  cshade $GREY 0.32; off=$CS
  for (( i = 0; i < n; i++ )); do
    if (( i )); then
      (( jw )) && gap=$(( gq + (i <= gr ? 1 : 0) ))
      cshade $PURPLE 0.8; v_text $(( gx + gap / 2 )) $y '·' $CS; gx=$(( gx + gap ))
    fi
    v_text $gx $y "${a[3*i]}" $GREY; gx=$(( gx + ${#a[3*i]} + 1 ))
    p=${a[3*i+1]}
    if (( p >= 0 )); then
      (( p > 100 )) && p=100
      if (( p >= 90 )); then cmix $RED $AMBER 0.3; col=$CM
      elif (( p >= 70 )); then col=$AMBER
      else cmix $CYAN $LIME 0.5; col=$CM; fi
      on=$(( (p * cells + 50) / 100 )); (( p > 0 && on == 0 )) && on=1
      _run $on '▰'; (( on )) && v_text $gx $y "$RUN" $col
      _run $(( cells - on )) '▱'; (( on < cells )) && v_text $(( gx + on )) $y "$RUN" $off
      ispct=0; [[ "${a[3*i+2]}" == *% ]] && ispct=1
      TC_MTR+=($gx $y $cells $p $col $off $(( gx + cells + 1 )) ${#a[3*i+2]} $at $ispct)
      gx=$(( gx + cells + 1 ))
      v_text $gx $y "${a[3*i+2]}" $col
    else
      v_text $gx $y "${a[3*i+2]}" $WHITE
    fi
    gx=$(( gx + ${#a[3*i+2]} ))
  done
  return 0
}
tc_meters_live() {   # the meters filling, and their numbers counting, while the card comes up
  local -i i x y cells p col off vx vw on base k j v
  local -F e
  local s
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for (( i = 0; i < ${#TC_MTR[@]}; i += 10 )); do
    (( TC_NOW < TC_MTR[i+8] )) && continue           # not its beat yet · the row is hidden (tc_reveal)
    tc_in ${TC_MTR[i+8]} 0.55
    (( TCP >= 1.0 )) && continue
    x=${TC_MTR[$i]}; y=${TC_MTR[i+1]}; cells=${TC_MTR[i+2]}; p=${TC_MTR[i+3]}
    col=${TC_MTR[i+4]}; off=${TC_MTR[i+5]}; vx=${TC_MTR[i+6]}; vw=${TC_MTR[i+7]}
    e=$(( 1.0 - (1.0 - TCP) ** 3 ))                  # out of the blocks fast, settling onto the reading
    v=$(( int(p * e + 0.5) ))
    on=$(( (v * cells + 50) / 100 )); (( v > 0 && on == 0 )) && on=1
    k=$(( base + y * TCOLS + x ))
    for (( j = 0; j < cells; j++ )); do
      if (( j < on )); then GCH[$(( k + j ))]='▰'; GF[$(( k + j ))]=$col
      else                  GCH[$(( k + j ))]='▱'; GF[$(( k + j ))]=$off; fi
    done
    # a percentage counts up with its bar, and so does a plain count set to
    # the right; any other figure waits for the bar to fill
    if (( TC_MTR[i+9] == 1 )); then
      s="$v%"; (( ${#s} > vw )) && s="${s[0,$(( vw - 1 ))]}"
      while (( ${#s} < vw )); do s+=' '; done
    elif (( TC_MTR[i+9] == 2 )); then
      s="$v"; while (( ${#s} < vw )); do s=" $s"; done
    else
      s=''; while (( ${#s} < vw )); do s+=' '; done
    fi
    k=$(( base + y * TCOLS + vx ))
    for (( j = 0; j < vw; j++ )); do GCH[$(( k + j ))]="${s[$j,$j]}"; GF[$(( k + j ))]=$col; done
  done
  return 0
}
tc_status() {   # tc_status Y TEXT INK T [AT] — what the machine makes of it, in spaced capitals, breathing · typing out from AT
  local st="$2" s=''
  local -i i n=-1
  # the breath in thirty-seconds, for the same reason as tc_spaced's drift
  wave $4 0.35 0; WV=$(( int(WV * 32.0 + 0.5) / 32.0 ))
  cmix $3 $WHITE $(( 0.15 * WV )); cshade $CM $(( 0.75 + 0.25 * WV ))
  for (( i = 0; i < ${#st}; i++ )); do [[ "${st[$i,$i]}" == ' ' ]] && s+='  ' || s+="${s:+ }${st[$i,$i]}"; done
  if [[ -n "${5:-}" ]]; then
    tc_in $5 0.35
    n=$(( int(TCP * ${#s}) ))
    (( n > 0 )) || return 0
    (( TCP >= 1.0 )) && n=-1
  fi
  if (( n >= 0 )); then tc_center $1 "$s" $CS -2 $n; else tc_center $1 "$s" $CS; fi
  return 0
}
tc_prompt() {   # tc_prompt Y T [WORDS] [AT] — ◂ PRESS ANY KEY ▸, breathing on and off the arcade's way · from AT
  local -F t=$2
  if [[ -n "${4:-}" ]]; then
    (( TC_NOW >= $4 )) || return 0
    t=$(( TC_NOW - $4 ))
    wave $t 0.7 1.5708                       # it arrives lit, then breathes
  else
    wave $t 0.7 0
  fi
  (( WV > 0.35 )) || return 0
  cmix $AMBER $WHITE 0.35
  tc_center $1 "◂ ${3:-PRESS ANY KEY} ▸" $CM
  return 0
}
tc_nav() {   # tc_nav LABEL — the card's keys, on the suite's one key bar
  app_nav '[any key]' "$1" '[⎋]' out
  return 0
}
TC_KEYS='[ANY KEY]START   [⎋]BACK   [Q]POWER OFF'   # the control panel, while a card is up
tc_key() {   # tc_key KEY — a card's keys, the same on every machine · 0 taken, 1 the door's
  case "$1" in
    esc|back|m|M|q|Q) return 1 ;;              # out, and the power switch, stay the door's
    wheelup|wheeldown) return 0 ;;             # a notch of the wheel is not somebody pressing a key
  esac
  SURF_TITLE=0
  TC_T0=-1.0
  surf_dress                                   # the panel gets the machine's own keys back
  xf_arm
  snd pick
  return 0
}

HINT_K=(); HINT_L=()
hint_build() {
  local -i i
  HINT_K=("▴ ▾" "⏎"); HINT_L=(" choose" " do it")
  for (( i = 0; i < S_N; i++ )); do
    HINT_K+=("[${U_KEY[$i]}]"); HINT_L+=(" ${U_NAME[$i]:l}")
  done
  HINT_K+=("[V]"); HINT_L+=(" visitor")
  HINT_K+=("[Q]"); HINT_L+=(" power off")
  panel_keys
  surf_dress
  (( GLASS_GEN++ ))
  return 0
}
draw_hint() {   # the menu's own keys, on the suite's one nav bar
  NAVK=("${HINT_K[@]}"); NAVL=("${HINT_L[@]}")
  _app_nav
  return 0
}

# ── the menu · a row an ACTION, and what it is short of beside it ───────────
# TWO FUNCTIONS, BECAUSE ONE ROW MOVES AND THE REST DO NOT.  Everything on
# this glass holds still between keypresses except the row under the cursor,
# which breathes -- so the box and the rows that are not selected are painted
# into the cached glass, and the selected one is painted live on top of it.
# The base draws EVERY row unselected; when the cursor moves, the row it left
# comes back simply by the cache being copied again.
draw_roster_box() {
  local -i h=$(( S_N + 2 ))
  cmix $GLASS $PURPLE 0.13; local -i pb=$CM
  cshade $PURPLE 0.85
  v_box 0 $G_SUITE $G_LW $h $CS $pb round 1
  cmix $CYAN $WHITE 0.25
  v_text 3 $G_SUITE ' SUITE ' $CM $pb
  return 0
}

# ── the wash under the cursor row, kept by its breath ──────────────────────
# A ROW'S WASH IS A FUNCTION OF FOUR THINGS: its accent, how much of the
# cursor it holds, where the breath is, and the list's width -- and it was
# worked out cell by cell, two hundred cells a frame, on every row the
# cursor touched.  So it is kept, as an array of grounds under a name that
# says those four things, and laid down in one move.  The breath is taken
# at a hundred and twenty-eight steps and the strength at a hundred, which
# is finer than the colour mask the wash is drawn through.
typeset -gA RWC
typeset -ga RW_L
typeset -gi RW_N=0
row_wash() {   # row_wash Y ACC STRENGTH T · glass row Y, list columns 1..G_LW-2
  local -i y=$1 acc=$2 xx gr gg gb ar ag2 ab rk
  local -F S=$3 t=$4 sweep f mixf sq
  (( G_LW > 2 )) || return 0
  if (( S > 0.001 )); then
    wave $t $MO_SLOW 0; sweep=$(( (0.5 + 0.5 * WV) ))
    local wn="RW_${acc}_$(( int(S * 100 + 0.5) ))_$(( int(sweep * 128) ))_$G_LW"
    if [[ -z "${RWC[$wn]:-}" ]]; then
      local -a rw
      sweep=$(( int(sweep * 128) / 128.0 ))
      sq=$(( int(S * 100 + 0.5) / 100.0 ))
      gr=$(( (GLASS >> 16) & 255 )); gg=$(( (GLASS >> 8) & 255 )); gb=$(( GLASS & 255 ))
      ar=$(( (acc >> 16) & 255 )); ag2=$(( (acc >> 8) & 255 )); ab=$(( acc & 255 ))
      for (( xx = 1; xx < G_LW - 1; xx++ )); do
        f=$(( 1.0 - (xx - 1) / ((G_LW - 2) + 0.0) ))
        (( f < 0.0 )) && f=0.0
        mixf=$(( (0.13 + 0.30 * f * sweep) * sq ))
        rw+=($(( ((int(gr + (ar - gr) * mixf) & 0xFC) << 16) \
               | ((int(gg + (ag2 - gg) * mixf) & 0xFC) <<  8) \
               |  (int(gb + (ab - gb) * mixf) & 0xFC) )))
      done
      if (( RW_N >= 600 )); then unset "${(@)RW_L[@]}" 2>/dev/null; RW_L=(); RWC=(); RW_N=0; fi   # a global apiece · see _repn
      typeset -ga "$wn"; set -A "$wn" -- "${rw[@]}"
      RWC[$wn]=1; RW_L+=("$wn"); (( ++RW_N ))
    fi
    rk=$(( (OY + R_SCR + y) * TCOLS + OX + C_SCR + 1 ))
    xx=$(( G_LW - 2 ))
    _run $xx ' '
    GCH[$rk,$(( rk + xx - 1 ))]=("${(@s::)RUN}")
    _repn $xx -1; GF[$rk,$(( rk + xx - 1 ))]=("${(@P)REPV}")
    wn="${wn}[@]"; GB[$rk,$(( rk + xx - 1 ))]=("${(@P)wn}")
  fi
  return 0
}
roster_row() {   # roster_row I STRENGTH T · strength 1.0 is the row under the cursor
  local -i i=$1 sel=0
  local -F t=$3 sweep f mixf S=$2
  (( S >= 0.5 )) && sel=1
  local -i y xx acc tc sc gr gg gb ar ag2 ab rk
  local nm desc rd
  y=$(( G_SUITE + 1 + i ))
  nm="[${U_KEY[$i]}] ${U_NAME[$i]}"
  desc="${U_DESC[$i]}"
  reading "${U_KIND[$i]}"; rd="${RD[0,15]}"
  acc=${U_ACC[$i]}
  if (( S > 0.001 )); then
    # THE ROW UNDER THE CURSOR LIGHTS FROM ITS OWN LEFT EDGE, which is what
    # arcade.py does to the row it is about to charge you a coin for: a wash
    # in the row's own accent, brightest at the margin and gone by the far
    # side, breathing on the same wave the lamps do.  While the cursor is
    # gliding the wash is shared between the row it is leaving and the row it
    # is landing on -- the strength is how much of it this row holds.
    row_wash $y $acc $S $t
  fi
  if (( sel )); then
    cmix $acc $WHITE 0.45; v_put 1 $y '▌' $CM
    cmix $WHITE $acc 0.15; v_text 3 $y '▶' $CM
    tc=$WHITE; cmix $WHITE $acc 0.4; sc=$CM
  else
    cshade $GREY 1.05; tc=$CS
    cshade $DIM 1.15; sc=$CS
  fi
  if row_here $i; then
    v_text $G_NAME_X $y "${(r:$NAME_W:)nm}" $tc
    v_text $G_DESC_X $y "${desc[0,$(( DESC_MAX - 1 ))]}" $sc
    # WHAT THE HOUSE IS SHORT OF GOES WHERE THE READING GOES, in amber -- it
    # is not a fault of the row (the row works; it is the row that FIXES it)
    # and it is not a plain reading either, so it wears neither ink.
    #
    # CLIPPED BEFORE IT IS PLACED.  Right-aligning a string and then cutting
    # it is right-aligning the string it USED to be: the cut end lands where
    # the long one's did and the near end walks left into the description.
    if [[ -n "${U_WHY[$i]}" ]]; then
      rd="${${U_WHY[$i]}[0,15]}"
      cshade $AMBER 0.95
      v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $CS
    elif (( sel )); then
      v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $CYAN
    else
      v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $sc
    fi
  else
    # law 17 · A ROW THAT CANNOT ACT SAYS SO, in grey ink and out loud.
    row_needs $i
    [[ -n "$RNEED" ]] && rd="no $RNEED"
    rd="${rd[0,15]}"
    v_text $G_NAME_X $y "${(r:$NAME_W:)nm}" $DIM
    v_text $G_DESC_X $y "${desc[0,$(( DESC_MAX - 1 ))]}" $DIM
    cshade $RED 0.62
    v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $CS
  fi
  return 0
}

# ── the readout · what every machine in this folder is doing ────────────────
# ── the machines · a box you move the cursor into ──────────────────────────
# THIS BOX USED TO BE A READING, and it was unnamed on purpose: it listed the
# machines and what each was doing, and the one box you could press was the
# one above it.  That was true right up until the machines became things you
# press, which is what they are now -- the cursor runs off the bottom of
# SUITE and straight into this list, and ⏎ walks through the door.  So the
# box is named like the other one, and every row in it is drawn by the same
# function whether it is the selected row or not, because a selected row that
# is built somewhere else is a row that drifts.
mach_row() {   # mach_row I STRENGTH T
  local -i i=$1 sel=0
  local -F S=$2
  (( S >= 0.5 )) && sel=1
  local -F t=$3 sweep f mixf
  local -i y xx acc tc sc rc dot gr gg gb ar ag2 ab rk pb here=0
  local nm rd need mark
  cmix $GLASS $PURPLE 0.13; pb=$CM
  y=$(( G_MACH + 1 + i ))
  nm="${M_NAME[$i]}"
  need="${P_NEEDS[${M_PATH[$i]}]:-}"
  here=${P_HERE[${M_PATH[$i]}]:-0}
  if (( ! here )); then
    cshade $RED 0.7;   dot=$CS; rd='not here'; acc=$RED;   mark='▮'
    cshade $RED 0.62;  rc=$CS
  elif [[ -n "$need" ]]; then
    cshade $AMBER 0.9; dot=$CS; rd="${${:-needs $need}[0,15]}"; acc=$AMBER; mark='○'
    cshade $AMBER 0.95; rc=$CS
  else
    dot=$LIME; reading "${M_KIND[$i]}"; rd="${RD[0,15]}"; acc=$LIME; mark='●'
    rc=$CYAN
  fi
  if (( S > 0.001 )); then
    # the same wash the SUITE rows take, in the machine's own state colour --
    # so a row that cannot open is plainly not offering to
    row_wash $y $acc $S $t
  fi
  if (( sel )); then
    cmix $acc $WHITE 0.45; v_put 1 $y '▌' $CM
    cmix $WHITE $acc 0.15; v_text 3 $y '▶' $CM
    tc=$WHITE; cmix $WHITE $acc 0.4; sc=$CM; rc=$WHITE
    v_text $G_NAME_X $y "${(r:$NAME_W:)nm}" $tc
    v_text $G_DESC_X $y "${${M_DESC[$i]}[0,$(( DESC_MAX - 1 ))]}" $sc
    v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $rc
  elif (( S > 0.001 )); then
    # the row the cursor is leaving or arriving at · its own words, on the
    # wash it is still holding
    v_text 3 $y "$mark" $dot
    cshade $GREY 1.0; tc=$CS
    cshade $DIM 1.2;  sc=$CS
    v_text $G_NAME_X $y "${(r:$NAME_W:)nm}" $tc
    v_text $G_DESC_X $y "${${M_DESC[$i]}[0,$(( DESC_MAX - 1 ))]}" $sc
    v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $rc
  else
    v_text 3 $y "$mark" $dot $pb
    cshade $GREY 1.0; tc=$CS
    cshade $DIM 1.2;  sc=$CS
    v_text $G_NAME_X $y "${(r:$NAME_W:)nm}" $tc $pb
    v_text $G_DESC_X $y "${${M_DESC[$i]}[0,$(( DESC_MAX - 1 ))]}" $sc $pb
    v_text $(( G_READ_R - ${#rd} + 1 )) $y "$rd" $rc $pb
  fi
  return 0
}

draw_machines() {
  local -i i
  cmix $GLASS $PURPLE 0.13; local -i pb=$CM
  cshade $PURPLE 0.85
  v_box 0 $G_MACH $G_LW $(( M_N + 2 )) $CS $pb round 1
  cmix $CYAN $WHITE 0.25
  v_text 3 $G_MACH ' MACHINES ' $CM $pb
  for (( i = 0; i < M_N; i++ )); do mach_row $i 0.0 0.0; done
  return 0
}

# ── the mirror, as a gauge ──────────────────────────────────────────────────
# THE ONE NUMBER THE MENU TURNS ON.  Whether this folder is installed is a
# fact about the reader's ~, it is the difference between INSTALL and
# TERMINAL, and until now it was four words in a reading column.  A bar says
# how far along it is at a glance, which is the thing a person actually wants
# to know while it is not yet all the way along.
draw_mirror() {
  local -i n=28 lit i
  local bar='' rest='' tail=''
  if (( P_LEAVES > 0 )); then
    lit=$(( P_LINKED * n / P_LEAVES ))
  else
    lit=0
  fi
  (( lit > n )) && lit=$n
  for (( i = 0; i < lit; i++ )); do bar+='▓'; done
  for (( i = lit; i < n; i++ )); do rest+='░'; done
  cshade $DIM 1.2
  # ...and this row is the first line of that readout, so it is claimed the
  # same way and for the same reason.
  v_fill 0 $G_MIRROR $G_LW 1 ' ' $CS -2
  v_text 2 $G_MIRROR 'MIRROR' $CS
  local -i c=$LIME
  (( P_LEAVES && P_LINKED >= P_LEAVES )) || c=$AMBER
  (( P_LEAVES )) || c=$DIM
  v_text 10 $G_MIRROR "$bar" $c
  cshade $DIM 0.9
  v_text $(( 10 + lit )) $G_MIRROR "$rest" $CS
  if (( ! P_LEAVES )); then tail='no home/ in this folder'
  elif (( P_LINKED >= P_LEAVES )); then tail="all $P_LEAVES linked into ~"
  else tail="$P_LINKED of $P_LEAVES linked into ~"; fi
  cshade $GREY 1.0
  v_text $(( 10 + n + 2 )) $G_MIRROR "$tail" $CS
  return 0
}

# ── what this machine IS · five readings, under the gauge ──────────────────
# THE SELF TEST SAYS ALL OF IT ONCE and then gets out of the way.  That is the
# right shape for a self test and the wrong one for these five, because they
# are the only lines on this card that are about the READER'S machine rather
# than about the suite -- everything else here is a fact about a folder.  The
# card flashes them past in nine seconds; the glass is where somebody SITS.
#
# UNDER THE MIRROR, IN THE MIRROR'S OWN COLUMNS.  The label sits at 2 and the
# reading at 10 because that is where the gauge above it sits, and the disk
# bar is the mirror's own twenty-eight cells starting in the mirror's own
# column -- so the two bars stack, and what could have read as a second block
# bolted underneath reads as one readout that happens to begin with the ~.
#
# WHICH FIVE.  The chip and the core, because they are what anybody means by
# "what is this machine".  The disk, because free space is the only figure
# here that can go WRONG, and the only one worth a bar and a colour.  The
# panel, because every animation on this card is paced against its refresh
# rate and it is honest to say what that is.  And the system, because a
# version and a build are what you quote when something does not work.
#
# CACHED, NOT LIVE.  None of it moves: it is painted into the glass layer
# with the roster and the boxes and copied per frame at no cost.  The one
# figure that can change under it is the panel rate -- the slow probe can
# land seconds after the card is up -- so the visit bumps GLASS_GEN when it
# does, and the row is repainted with the answer.
draw_specs() {
  local -i y=$G_SPEC n=28 lit=0 i
  local bar='' rest='' v
  local -i lab=0 val=0 c=0
  cshade $DIM 1.2; lab=$CS
  cshade $GREY 1.0; val=$CS
  # THE BAND IS THE READOUT'S, ALL OF IT.  The dust drifts over whatever the
  # glass is not using, and five rows of close-set figures is the one place
  # on this card where a speck stops being weather and starts being a decimal
  # point somebody tries to read.  The two boxes above keep it out by having
  # a GROUND; this has none and does not want one, so it claims its rows the
  # way the visitor claims his -- an ink laid on a space, which paints
  # nothing at all and says the cell is taken.
  v_fill 0 $G_SPEC $G_LW 5 ' ' $val -2

  # -- the chip, with its cores and its architecture already on it ----------
  v_text 2 $y 'CPU' $lab
  v_text 10 $y "${${${SPEC_CPU:l}:-unknown}[0,$(( G_LW - 12 ))]}" $val
  (( y++ ))

  # -- the core -------------------------------------------------------------
  v_text 2 $y 'MEMORY' $lab
  v_text 10 $y "${${SPEC_RAM:l}:-unknown}" $val
  (( y++ ))

  # -- the disk, on the mirror's own gauge ----------------------------------
  v_text 2 $y 'DISK' $lab
  lit=$(( int(SPEC_DISK_USE * n + 0.5) ))
  (( lit < 0 )) && lit=0
  (( lit > n )) && lit=$n
  for (( i = 0; i < lit; i++ )); do bar+='▓'; done
  for (( i = lit; i < n; i++ )); do rest+='░'; done
  # THE COLOUR IS THE READING.  A bar that is the same colour at nine tenths
  # full as at one tenth is a picture of a number rather than a reading, and
  # the whole reason this line is on the glass is the tenth where it matters.
  c=$CYAN
  (( SPEC_DISK_USE >= 0.80 )) && { cshade $AMBER 0.95; c=$CS }
  (( SPEC_DISK_USE >= 0.92 )) && { cshade $RED 0.85;   c=$CS }
  (( SPEC_DISK_USE > 0.0 ))   || { cshade $DIM 1.0;    c=$CS }
  v_text 10 $y "$bar" $c
  cshade $DIM 0.9
  v_text $(( 10 + lit )) $y "$rest" $CS
  v_text $(( 10 + n + 2 )) $y "${${SPEC_DISK:l}:-unknown}" $val
  (( y++ ))

  # -- the panel every animation on this card is paced against --------------
  reading depth
  v="${SPEC_PANEL:-$TCOLS x $TROWS cells} @ $(( int(HZ + 0.5) )) hz · $RD"
  v_text 2 $y 'PANEL' $lab
  v_text 10 $y "${v[0,$(( G_LW - 12 ))]}" $val
  (( y++ ))

  # -- and the system the lot of it is standing on --------------------------
  v="${P_OS:l}"
  [[ -n "$SPEC_OSB" ]] && v+=" · build ${SPEC_OSB:l}"
  [[ -n "${ZSH_VERSION:-}" ]] && v+=" · zsh $ZSH_VERSION"
  v_text 2 $y 'SYSTEM' $lab
  v_text 10 $y "${v[0,$(( G_LW - 12 ))]}" $val
  return 0
}

draw_head() {   # the menu's own title bar, on the suite's one header
  app_head TERMINAL
  local -i n=0 j
  for (( j = 0; j < M_N; j++ )); do (( ${P_HERE[${M_PATH[$j]}]:-0} )) && (( n++ )); done
  # CENTRED BETWEEN THE BRAND AND THE CAPTION, in the room they leave.  The
  # count is as long as the house is busy and the caption as long as the sky is
  # wordy, so it is centred in what is actually free rather than on the glass.
  local mid="◂ $n MACHINE"
  (( n == 1 )) || mid+='S'
  mid+=" · $P_AGENTS AGENT"
  (( P_AGENTS == 1 )) || mid+='S'
  mid+=' ▸'
  cmix $GLASS $PURPLE 0.32; local -i hb=$CM
  local -i lo=$APP_HX hi=$APP_HR
  cshade $WHITE 0.85
  (( hi - lo >= ${#mid} )) && v_text $(( lo + (hi - lo - ${#mid}) / 2 )) 0 "$mid" $CS $hb
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE GLASS, IN TWO PARTS
# ══════════════════════════════════════════════════════════════════════════
# ALMOST NOTHING ON THIS GLASS MOVES.  The header, the two panels, the
# mirror's gauge, the rule, the key bar, the sun or moon in the corner and
# the whole of the visitor except his eyes are the same cells they were last
# frame and the frame before -- they answer the PROBE, the MENU and the
# MINUTE, and all three of those hold still for seconds at a time.
#
# So the glass is drawn ONCE per change, the tube is put over it once, and
# what is kept is the finished rectangle.  A frame copies that rectangle back
# -- twenty-one slice moves, which zsh does in C -- and then paints the four
# things that actually moved: the row under the cursor, his eyes, the dust,
# and the bright row travelling down the tube.  Two thousand two hundred
# cells of work became about three hundred.
#
# GLASS_GEN IS THE WHOLE CACHE KEY.  Anything that changes what the glass
# says bumps it, and there are only three such things -- a probe, a menu
# rebuild, and the minute turning over.  A cache with a key that is not the
# truth is a picture that lies, so the bumps are at the SOURCE of each, not
# at the places that happen to read them.
typeset -ga GLCH GLF GLB
GLASS_KEY=''

glass_base() {   # glass_base — everything that holds still
  local -i y i
  # CLEARED TO NO INK, on purpose · see draw_motes
  if (( GEOM_FILL )); then
    # SCREEN=fill · the glass is the whole window and reads as a lit tube, not
    # bare night -- a shade up the middle where the rows sit, darker at the top
    # and bottom edges, the same vertical vignette the CONFIG page wears.
    local -F midr fr; local -i gc
    midr=$(( (SCR_H - 1) / 2.0 ))
    for (( y = 0; y < SCR_H; y++ )); do
      fr=$(( midr > 0.0 ? 1.0 - abs(y - midr) / midr : 1.0 )); (( fr < 0.0 )) && fr=0.0
      cmix $GLASS $PURPLE $(( 0.05 + 0.06 * fr )); gc=$CM
      v_fill 0 $y $SCR_W 1 ' ' -1 $gc
    done
  else
    v_fill 0 0 $SCR_W $SCR_H ' ' -1 $GLASS
  fi
  draw_head
  draw_roster_box
  for (( i = 0; i < S_N; i++ )); do roster_row $i 0.0 0.0; done
  draw_machines
  draw_mirror
  draw_specs
  # THE DIVIDER AND BOTH SPRITES LEFT THE MENU · the list fills the glass edge
  # to edge now, and the sun/moon and the visitor keep their own page ([V]).
  # The dust rides whatever the list leaves blank, as it always did.
  draw_hint
  return 0
}

glass_save() {   # keep the finished rectangle · the tube goes on at the wire
  local -i y sk dk
  GLCH=(); GLF=(); GLB=()
  local -i base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  # THE GLASS THAT IS THE WINDOW'S WHOLE WIDTH lies end to end in the canvas,
  # so it is one slice out and one slice back in -- SCREEN=fill, every frame
  if (( SCR_W == TCOLS )); then
    local -i n=$(( SCR_W * SCR_H ))
    GLCH=("${(@)GCH[@]:$base:$n}"); GLF=("${(@)GF[@]:$base:$n}"); GLB=("${(@)GB[@]:$base:$n}")
    return 0
  fi
  for (( y = 0; y < SCR_H; y++ )); do
    sk=$(( base + y * TCOLS ))
    GLCH+=("${(@)GCH[@]:$sk:$SCR_W}")
    GLF+=("${(@)GF[@]:$sk:$SCR_W}")
    GLB+=("${(@)GB[@]:$sk:$SCR_W}")
  done
  return 0
}

glass_load() {   # ...and put it back
  local -i y sk dk
  local -i base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  if (( SCR_W == TCOLS && ${#GLCH[@]} == SCR_W * SCR_H )); then
    local -i e=$(( base + SCR_W * SCR_H - 1 ))
    GCH[$base,$e]=("${GLCH[@]}"); GF[$base,$e]=("${GLF[@]}"); GB[$base,$e]=("${GLB[@]}")
    return 0
  fi
  for (( y = 0; y < SCR_H; y++ )); do
    sk=$(( y * SCR_W )); dk=$(( base + y * TCOLS ))
    GCH[$dk,$(( dk + SCR_W - 1 ))]=("${(@)GLCH[@]:$sk:$SCR_W}")
    GF[$dk,$(( dk + SCR_W - 1 ))]=("${(@)GLF[@]:$sk:$SCR_W}")
    GB[$dk,$(( dk + SCR_W - 1 ))]=("${(@)GLB[@]:$sk:$SCR_W}")
  done
  return 0
}

live_row() {   # live_row ROW STRENGTH T — the row under (or near) the cursor
  if (( $1 < S_N )); then roster_row $1 $2 $3
  else mach_row $(( $1 - S_N )) $2 $3; fi
  return 0
}
glass_live() {   # glass_live T — the four things that move
  local -F t=$1
  # THE ROW UNDER THE CURSOR, IN WHICHEVER BOX IT IS IN.  The cursor runs
  # 0..S_N-1 through SUITE and then straight on into the machines, which is
  # what makes a machine a thing you select rather than a thing you have to
  # know a letter for.
  # ...AND IT GLIDES.  The band under the cursor eases from the row it was
  # on to the row it is going to over MO_CURSOR, re-aimed on every key so a
  # fast repeat never waits for it; while it is between two rows both hold
  # part of the wash.
  local -F pos frac
  local -i r0 r1
  mo_ease cursor.menu $UI_ROW $t $MO_CURSOR; pos=$MV
  r0=$(( int(floor(pos)) )); frac=$(( pos - r0 )); r1=$(( r0 + 1 ))
  (( r0 < 0 )) && { r0=0; frac=0.0 }
  live_row $r0 $(( 1.0 - frac )) $t
  (( frac > 0.001 && r1 < S_N + M_N )) && live_row $r1 $frac $t
  # THE VISITOR'S EYES MOVED TO HIS OWN PAGE · on the menu the dust is the only
  # thing left that breathes between the keypresses now.
  draw_motes $t
  return 0
}
# ══════════════════════════════════════════════════════════════════════════
# SECTION 16 · A FRAME            begin, draw, end · arcade.py's own shape
# ══════════════════════════════════════════════════════════════════════════
# begin lays the night down and stands the machine in it; the caller paints
# the glass; end puts the tube over the glass, fades the machine if it is on
# its way in or out, and hands the difference to the terminal.
frame_begin() {   # frame_begin T
  # THE LIGHT MOVES ON THE FRAME'S OWN CLOCK, and for a while it did not.
  # There was a CHROME_HZ here -- arcade.py's idea, and a good one where it
  # lives: it holds the ambient cells still between ticks because nobody can
  # see a neon tube pulse at a hundred and twenty hertz, and holding them
  # still keeps the wire free for the picture.
  #
  # THE TROUBLE IS WHAT IT DOES BELOW ITS OWN RATE.  Quantising the chrome to
  # twelve steps a second does not cap the motion at twelve -- it makes every
  # motion on the machine a STAIRCASE, and then shows the steps for two
  # frames, then three, then two, depending on where the frame lands between
  # them.  Uneven repeats of an even motion is the exact recipe for judder,
  # and it is worse than a lower frame rate because the eye can see the
  # rhythm of the error.  The chase lights stepped, the sweep on the name
  # stepped, the tubes stepped, and none of it was the frame rate's fault.
  #
  # So the light is drawn at whatever rate the machine is achieving, from the
  # same continuous clock everything else uses.  Every frame advances it by
  # exactly one frame's worth, which is the only thing that reads as smooth
  # at any rate at all -- and the cache that quantising existed to feed is
  # gone with it, along with the three array copies a frame it cost to fill.
  local -F t=$1
  FRAME_T=$t
  tick_slow
  post_reset
  # a baked glass nobody asked for last frame is a page that has gone
  [[ -n "$GSTILL_KEY" ]] && (( ! GS_USED )) && glass_unbake
  GS_USED=0
  GCH=("${SCH[@]}"); GF=("${SF_[@]}"); GB=("${SB_[@]}")
  if (( CFG_FILL )); then
    # SCREEN=fill · a machine's surface wears its sign, keys and message on the
    # bare glass; TERMINAL's own menu draws its head and its hint strip inside
    # glass_base and needs neither, so it is spared the pass that would only
    # land a second key strip in the middle of the reflowed page.
    [[ -z "$UI_SURF" ]] || fill_chrome $t
  else
    chrome_light $t
    draw_panel $t
    draw_coin $t
    draw_footer
  fi
  return 0
}

# ── the night · drawn LAST, and after the machine has been dimmed ──────────
# THE NIGHT IS NOT THE MACHINE and does not answer to it.  It twinkles on its
# own slower clock -- TERMINAL's four beats a second, a twinkle rather than a
# motion, because a star that faded smoothly would not be a star -- and it
# went up with the rest of the frame until the sky came back and showed what
# that cost: `frame_end` fades the WHOLE canvas while the tube is finding
# itself, so the stars we had just watched for three seconds blinked out the
# instant the machine began to switch on, and came back with it.  The night
# was there before the cabinet and is there after it.  So it is laid down
# after the fade rather than under it, and the machine materialises IN it.
#
# Nothing else moves: the sky only ever writes cells with no ground, no ink
# and no glyph, and neither the tube nor the fade creates or destroys one --
# both happen on the wire now, and the cells the night wrote are marked so
# the fade leaves them alone.  So the same stars land in the same cells
# whichever end of the frame it is asked at.
night() {   # night T
  (( CFG_FILL )) && return 0       # SCREEN=fill · the surround is glass, not sky
  suite_sky $1
  suite_streak $1
  return 0
}

# ── THE STILL LAYER CARRIES THE CACHED GLASS ─────────────────────────────
# A cached page was put back on the glass every frame: three slices of ten
# thousand cells, five milliseconds, on top of the three copies frame_begin
# had just made of a still layer whose glass was about to be covered.  So
# the page is BAKED into the still layer instead -- its glass becomes the
# layer's glass, once, when it is painted -- and frame_begin's copy lays
# the page down for nothing.  The bare layer is kept (BCH) and put back the
# moment anything else wants the glass: a page change (xf_arm), a cache
# that goes stale, or a frame that did not ask for what was baked.
#   glass_bake KEY    the glass as it stands is KEY's, and the layer's now
#   glass_unbake      the layer's glass is the bare base again
#   glass_baked KEY   KEY is baked, and this frame has claimed it
typeset -ga BCH BF_ BB_                # the still layer as static_paint left it
typeset -g  GSTILL_KEY=''              # what is baked into it · '' is nothing
typeset -gi GS_USED=0                  # ...and whether this frame asked for it
typeset -gF FRAME_T=0.0                # the frame's own clock, for a repaint
# A MACHINE GETTING READY BEHIND THE STARS (SECTION 22b) MAY PAINT -- a room
# drawn once so it can be kept -- but it paints into a canvas the next frame
# throws away, and it does not own the still layer: that is the menu's, or
# nobody's yet.  So while one is warming, nothing is baked, nothing is
# unbaked, and nothing counts as already baked.
typeset -gi WARMING=0
glass_bake() {
  (( WARMING )) && return 0
  local -i y sk base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  if (( SCR_W == TCOLS )); then
    local -i e=$(( base + SCR_W * SCR_H - 1 ))
    SCH[$base,$e]=("${(@)GCH[$base,$e]}"); SF_[$base,$e]=("${(@)GF[$base,$e]}"); SB_[$base,$e]=("${(@)GB[$base,$e]}")
  else
    for (( y = 0; y < SCR_H; y++ )); do
      sk=$(( base + y * TCOLS ))
      SCH[$sk,$(( sk + SCR_W - 1 ))]=("${(@)GCH[$sk,$(( sk + SCR_W - 1 ))]}")
      SF_[$sk,$(( sk + SCR_W - 1 ))]=("${(@)GF[$sk,$(( sk + SCR_W - 1 ))]}")
      SB_[$sk,$(( sk + SCR_W - 1 ))]=("${(@)GB[$sk,$(( sk + SCR_W - 1 ))]}")
    done
  fi
  GSTILL_KEY="$1"; GS_USED=1
  return 0
}
glass_unbake() {
  (( WARMING )) && return 0
  [[ -n "$GSTILL_KEY" ]] || return 0
  (( ${#BCH[@]} == ${#SCH[@]} )) && { SCH=("${BCH[@]}"); SF_=("${BF_[@]}"); SB_=("${BB_[@]}") }
  GSTILL_KEY=''
  return 0
}
glass_baked() {
  (( WARMING )) && return 1
  [[ -n "$1" && "$1" == "$GSTILL_KEY" ]] || return 1
  GS_USED=1
  # frame_begin laid the page down · in fill mode the chrome then wrote its
  # sign, keys and message across three of its rows, which the load used to
  # cover: those rows come back from the layer, as they did from the cache
  if (( CFG_FILL )) && [[ -n "$UI_SURF" ]]; then
    local -i r dk base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
    for r in $(( R_BEZ_TOP - R_SCR )) $(( R_PANEL_B - R_SCR )) $(( R_COIN - R_SCR )); do
      (( r < 0 || r >= SCR_H )) && continue
      dk=$(( base + r * TCOLS ))
      GCH[$dk,$(( dk + SCR_W - 1 ))]=("${(@)SCH[$dk,$(( dk + SCR_W - 1 ))]}")
      GF[$dk,$(( dk + SCR_W - 1 ))]=("${(@)SF_[$dk,$(( dk + SCR_W - 1 ))]}")
      GB[$dk,$(( dk + SCR_W - 1 ))]=("${(@)SB_[$dk,$(( dk + SCR_W - 1 ))]}")
    done
  fi
  return 0
}
# glass_base_canvas · the canvas's glass as frame_begin would have left it
# with nothing baked: the bare layer's glass, and the chrome fill mode lays
# on it -- what a page about to be painted from scratch paints over
glass_base_canvas() {
  local -i y sk base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  (( ${#BCH[@]} == ${#GCH[@]} )) || return 0
  if (( SCR_W == TCOLS )); then
    local -i e=$(( base + SCR_W * SCR_H - 1 ))
    GCH[$base,$e]=("${(@)BCH[$base,$e]}"); GF[$base,$e]=("${(@)BF_[$base,$e]}"); GB[$base,$e]=("${(@)BB_[$base,$e]}")
  else
    for (( y = 0; y < SCR_H; y++ )); do
      sk=$(( base + y * TCOLS ))
      GCH[$sk,$(( sk + SCR_W - 1 ))]=("${(@)BCH[$sk,$(( sk + SCR_W - 1 ))]}")
      GF[$sk,$(( sk + SCR_W - 1 ))]=("${(@)BF_[$sk,$(( sk + SCR_W - 1 ))]}")
      GB[$sk,$(( sk + SCR_W - 1 ))]=("${(@)BB_[$sk,$(( sk + SCR_W - 1 ))]}")
    done
  fi
  (( CFG_FILL )) && [[ -n "$UI_SURF" ]] && fill_chrome $FRAME_T
  return 0
}
# glass_cached KEY FN — the glass FN paints, kept under KEY · one cache, for
# whichever surface is standing: a machine's pages use it exactly the way
# TERMINAL's own menu does, painting what holds still once per change and
# laying what moves on top each frame.
glass_cached() {
  (( WARMING )) && { $2; return 0 }    # painted, and kept by nobody
  if [[ "$1" != "$GLASS_KEY" || ${#GLCH[@]} != $(( SCR_W * SCR_H )) ]]; then
    [[ -n "$GSTILL_KEY" ]] && { glass_unbake; glass_base_canvas }
    $2
    glass_save
    GLASS_KEY="$1"
    glass_bake "$1"
  elif glass_baked "$1"; then
    :                                  # frame_begin laid the page down
  else
    glass_load
    glass_bake "$1"
  fi
  return 0
}
frame_glass() {   # frame_glass T — the cached rectangle, then what moved
  local -F t=$1
  glass_cached "$GLASS_GEN|${TCOLS}x${TROWS}" glass_base
  glass_live $t
  return 0
}
menu_frame() {   # menu_frame T — the menu, and whatever popup is folded over it
  # DRAWN AS ONE FRAME so a CONFIG box opening rides the same channel-change the
  # rest of the glass does · frame_glass lays the menu, menu_modals folds the box
  # up on top of it, live, each frame it is up.
  frame_glass $1
  menu_modals $1
  return 0
}

frame_end() {   # frame_end T [POWER] [DIM]
  # THE TUBE, THE ROLL AND THE FADE ARE ASKED FOR HERE and applied on the
  # wire: the power-up's tube coming up under its raster, the boot card's
  # glass still warming, the cabinet fading in under both.  None of it costs
  # a pass over the picture any more.
  local -F p=${2:-1.0} d=${3:-1.0}
  post_tube $p
  post_dim $d
  post_roll $1
  night $1
  r_flush
  return 0
}

frame_end_cached() {   # ...and an ordinary frame, whose tube is at full
  post_roll $1
  night $1
  r_flush
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 17 · SWITCHING ON AND OFF        arcade.py's sections at both ends
# ══════════════════════════════════════════════════════════════════════════
# THE OVERTURE · the sky gets the stage first.  Every surface in the ALIEN
# suite opens the same way: the stars are the first thing the window holds,
# and they hold it ALONE for two honest seconds before anything is drawn over
# them.  Which is why the night out there has to be worth two seconds.
# ── HOW LONG IT ALL TAKES ──  Thirteen seconds, and every one of them on
# purpose.  This was cut to four once, on the reasoning that a TERMINAL you
# double-clicked should not keep you waiting -- and that was the wrong
# diagnosis of the right symptom.  The opening did not feel long because it
# WAS long; it felt long because the machine underneath it could manage a
# frame and a half a second, and four seconds of stutter is worse than
# thirteen of ceremony.  The stutter is fixed.  The ceremony is the point:
# the stars hold the window alone, the tube finds itself and opens out, and
# the machine says what it found before it lets you in.
#
# AND ONE KEY SKIPS ALL OF IT, at any moment, which is what makes a long
# opening a gift rather than a toll.  The card says so while it runs.
OV_HOLD=3.0
SKIP_OPEN=0
opening_skipped() {
  # THE KEY HAS ALREADY BEEN TAKEN, by the same read that paced the frame --
  # this only asks what it was.  Polling separately meant two reads a frame
  # racing for one keystroke, and the loser dropped it.
  (( SKIP_OPEN )) && return 0
  [[ -n "$OV_KEY" ]] || return 1
  # ...AND ONE KEY IS NOT A SKIP.  P holds the self test still, and a person
  # who has read that off the card once will press it again before the card
  # is up -- during the stars, during the tube finding itself -- where there
  # is nothing yet to hold.  Under `any key skips` that press throws away the
  # exact thing it was reaching for.  So P is never a skip anywhere in the
  # opening: before there is something to hold, it simply does nothing.
  [[ "$OV_KEY" == (p|P) ]] && { OV_KEY=''; return 1 }
  OV_KEY=''
  SKIP_OPEN=1
  return 0
}
# THE OVERTURE'S OWN BEAT · twenty-four a second, and not the panel's rate.
# Everything else on this machine is paced by the ladder because everything
# else moves continuously; the sky does not.  Its twinkle turns four times a
# second and its shooting star steps twelve, both quantised in the arithmetic
# itself -- so drawing it a hundred and twenty times a second would send the
# same stars over the wire five times each for no picture at all.
#
# TWENTY-FOUR RATHER THAN TWENTY-FIVE, and the one is worth the other.  The
# sky steps twelve times a second; at twenty-five draws those steps get two
# frames, then two, then THREE, over and over, because twenty-five does not
# divide by twelve.  Uneven repeats of an even motion is the exact recipe for
# judder -- it is the same mistake the chrome clock made at the other end of
# this file -- and at twenty-four every step gets two frames for ever.
SKY_STEP=0.0416667
page_sky() {
  # AND THIS IS ALSO WHERE THE MACHINE LOADS.  Everything the cabinet needs
  # before the tube can open -- the panel rate, the specs, the slot scan, the
  # chrome -- used to run in front of this, against a window that had not
  # been given anything to look at.  It runs BEHIND it now: a frame, one step
  # off the queue, another frame.  The stars are up in the first hundredth of
  # a second and the reader watches a sky rather than a cursor while the
  # machine reads itself.
  #
  # ...AND THE MACHINES LOAD HERE TOO (SECTION 22b), once the cabinet has.
  # A pack is read in and started a piece between frames -- as many small
  # pieces as fit in the quiet half of a frame -- and the sky is held for
  # them, by as much as WARM_HOLD past its own seconds; the menu takes
  # whatever is left after that.
  #
  # THE NAMES BELOW ARE ITS OWN: a pack is read in from inside this function,
  # and a top-level line of one that set a plain `t` or `fin` would set these.
  local -F _sk_t _sk_t0=$EPOCHREALTIME _sk_due=0.0 _sk_rem _sk_f0
  local -i _sk_fin=0 _sk_lfin=0
  while :; do
    _sk_t=$(( $EPOCHREALTIME - _sk_t0 ))
    c_clear
    suite_sky $_sk_t
    suite_streak $_sk_t
    r_flush
    if (( ! _sk_lfin )); then
      load_step || _sk_lfin=1
    elif (( ! _sk_fin )); then
      if (( $EPOCHREALTIME - _sk_t0 > OV_HOLD + WARM_HOLD )); then _sk_fin=1
      else
        _sk_f0=$EPOCHREALTIME
        while warm_step; do
          (( $EPOCHREALTIME - _sk_f0 > SKY_STEP * 0.5 )) && break
        done
        (( ${#WARM_Q[@]} )) || _sk_fin=1
      fi
    fi
    # THE SKY HOLDS UNTIL BOTH ARE TRUE: it has had its few honest seconds,
    # and there is nothing left to load.  A quick machine still gets the
    # whole overture; a slow one gets as long as it needs, and spends it on
    # stars instead of on an empty window.
    (( _sk_fin )) && (( $EPOCHREALTIME - _sk_t0 > OV_HOLD )) && break
    # PACED AGAINST THE CLOCK, NOT AGAINST ITSELF.  `sleep 0.04` after a
    # frame that cost fifteen milliseconds is a frame every fifty-five, and
    # after the frame that forked python for the refresh rate it is a frame
    # every three hundred.  Sleeping until the next DUE beat keeps the stars
    # stepping evenly whatever the frame under them just had to do, and a
    # step that overran loses its own beat rather than pushing every beat
    # after it back.
    _sk_due=$(( _sk_due + SKY_STEP ))
    _sk_rem=$(( _sk_t0 + _sk_due - $EPOCHREALTIME ))
    (( _sk_rem < -SKY_STEP )) && { _sk_due=$(( $EPOCHREALTIME - _sk_t0 )); _sk_rem=0.0 }
    ob_wait $_sk_rem
    opening_skipped && return 0
  done
  return 0
}

# the whole power-down, read backwards · the same stages in the same order
# they were lost, so switching the machine on looks like switching it off
# looks like being undone.  It is not a recording played in reverse: the
# ember blooms, the line opens, the raster unfolds and the picture settles,
# each one easing the way the eye expects a thing coming TO life rather than
# going out of it.
PU_EMBER=1.00; PU_LINE=1.90; PU_UNFOLD=2.90; PU_SETTLE=3.80
power_up() {
  (( SKIP_OPEN )) && return 0
  snd start
  local -F t el k glow amt half hh d fade scan
  local -i cx=$(( SCR_W / 2 )) cy=$(( SCR_H / 2 )) x0 yy y0
  cmix $WHITE $CYAN 0.22; local -i core=$CM
  ob_start
  while :; do
    t=$OB_T; el=$t
    (( el > PU_SETTLE )) && break
    frame_begin $t
    v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $BLACK
    if (( el < PU_EMBER )); then
      k=$(( el / PU_EMBER )); glow=$(( k ** 1.6 ))
      (( glow > 0.10 )) && { cshade $core $(( glow * 0.16 )); v_fill $(( cx - 3 )) $cy 7 1 ' ' -2 $CS }
      (( glow > 0.03 )) && { cshade $core $(( glow * 0.55 )); v_fill $(( cx - 1 )) $cy 3 1 ' ' -2 $CS }
      cshade $WHITE $(( 0.18 + 0.82 * glow )); v_put $cx $cy '·' $CS
    elif (( el < PU_LINE )); then
      k=$(( (el - PU_EMBER) / (PU_LINE - PU_EMBER) ))
      half=$(( int(k ** 0.6 * (SCR_W / 2)) )); (( half < 1 )) && half=1
      x0=$(( cx - int(half) ))
      cshade $core $(( 0.16 * k ))
      v_fill $x0 $(( cy - 1 )) $(( int(half) * 2 )) 1 ' ' -2 $CS
      v_fill $x0 $(( cy + 1 )) $(( int(half) * 2 )) 1 ' ' -2 $CS
      cshade $core 1.0
      v_fill $x0 $cy $(( int(half) * 2 )) 1 ' ' -2 $CS
    elif (( el < PU_UNFOLD )); then
      k=$(( (el - PU_LINE) / (PU_UNFOLD - PU_LINE) ))
      k=$(( k * k * (3.0 - 2.0 * k) ))            # smoothstep
      hh=$(( int(k * SCR_H) )); (( hh < 1 )) && hh=1
      y0=$(( (SCR_H - int(hh)) / 2 ))
      for (( yy = y0; yy < y0 + int(hh); yy++ )); do
        d=$(( abs(yy - (SCR_H - 1) / 2.0) / (hh / 2.0 > 1.0 ? hh / 2.0 : 1.0) ))
        cshade $core $(( (1.0 - d * 0.5) * (1.0 - 0.55 * k) ))
        v_fill 0 $yy $SCR_W 1 ' ' -2 $CS
      done
    else
      k=$(( (el - PU_UNFOLD) / (PU_SETTLE - PU_UNFOLD) ))
      amt=$(( 0.45 * (1.0 - k) + 0.22 * sin((1.0 - k) * 3.141592653589793) ))
      for (( yy = 0; yy < SCR_H; yy++ )); do
        scan=1.0; (( yy & 1 )) && scan=0.5
        cshade $core $(( amt * scan ))
        v_fill 0 $yy $SCR_W 1 ' ' -2 $CS
      done
    fi
    # and the machine's own neon comes up under all of it, first thing to
    # arrive and last thing to finish
    fade=$(( el / PU_LINE )); (( fade > 1.0 )) && fade=1.0; (( fade < 0.0 )) && fade=0.0
    frame_end $t 1.0 $(( fade ** 0.75 ))
    ob_beat
    opening_skipped && return 0
  done
  return 0
}

# ── THE TUBE GOING OUT IS THE WHOLE OF IT ─────────────────────────────────
# A CRT DYING PROPERLY: the picture lets go, collapses to a line, the line
# pinches to a dot, the dot burns down.  That is four stages and it is the
# LAST thing this program does -- there is nothing after it and there is not
# supposed to be.
#
# THERE USED TO BE A FADE UNDER ALL OF IT, the whole card dimming to nothing
# from the pinch onward and then a wipe to true black held for a beat.  It
# was the power-up's own fade read backwards, and read backwards it is the
# wrong sentence: switching a television off does not dissolve the television.
# The tube goes dark and the box is still standing there in the room, which
# is exactly what you see, and it is also what makes the window closing a
# moment later read as the machine being taken away rather than as the
# picture having already gone.  So the cabinet keeps its neon, the night
# keeps its stars, and the only thing that dies is the thing that was lit.
PD_LETGO=0.85; PD_COLLAPSE=2.45; PD_PINCH=3.15; PD_EMBER=4.90; PD_END=5.45
power_down() {
  snd bye
  local -F t el k amt hh d half glow scan
  local -i cx=$(( SCR_W / 2 )) cy=$(( SCR_H / 2 )) x0 yy y0
  cmix $WHITE $CYAN 0.22; local -i core=$CM
  ob_start
  while :; do
    t=$OB_T; el=$t
    (( el > PD_END )) && break
    frame_begin $t
    v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $BLACK
    if (( el < PD_LETGO )); then
      k=$(( el / PD_LETGO ))
      amt=$(( 0.55 * (1.0 - k) + 0.30 * sin(k * 3.141592653589793) ))
      for (( yy = 0; yy < SCR_H; yy++ )); do
        scan=1.0; (( yy & 1 )) && scan=0.5
        cshade $core $(( amt * scan ))
        v_fill 0 $yy $SCR_W 1 ' ' -2 $CS
      done
    elif (( el < PD_COLLAPSE )); then
      k=$(( (el - PD_LETGO) / (PD_COLLAPSE - PD_LETGO) ))
      k=$(( k * k * (3.0 - 2.0 * k) ))
      hh=$(( int((1.0 - k) * SCR_H) )); (( hh < 1 )) && hh=1
      y0=$(( (SCR_H - int(hh)) / 2 ))
      for (( yy = y0; yy < y0 + int(hh); yy++ )); do
        d=$(( abs(yy - (SCR_H - 1) / 2.0) / (hh / 2.0 > 1.0 ? hh / 2.0 : 1.0) ))
        cshade $core $(( (1.0 - d * 0.5) * (0.30 + 0.70 * k) ))
        v_fill 0 $yy $SCR_W 1 ' ' -2 $CS
      done
    elif (( el < PD_PINCH )); then
      k=$(( (el - PD_COLLAPSE) / (PD_PINCH - PD_COLLAPSE) ))
      half=$(( int((1.0 - k) ** 1.8 * (SCR_W / 2)) )); (( half < 1 )) && half=1
      x0=$(( cx - int(half) ))
      cshade $core $(( 0.16 * (1.0 - k) ))
      v_fill $x0 $(( cy - 1 )) $(( int(half) * 2 )) 1 ' ' -2 $CS
      v_fill $x0 $(( cy + 1 )) $(( int(half) * 2 )) 1 ' ' -2 $CS
      cshade $core 1.0
      v_fill $x0 $cy $(( int(half) * 2 )) 1 ' ' -2 $CS
    elif (( el < PD_EMBER )); then
      k=$(( (el - PD_PINCH) / (PD_EMBER - PD_PINCH) ))
      glow=$(( (1.0 - k) ** 2.6 ))
      (( glow > 0.10 )) && { cshade $core $(( glow * 0.16 )); v_fill $(( cx - 3 )) $cy 7 1 ' ' -2 $CS }
      (( glow > 0.03 )) && { cshade $core $(( glow * 0.55 )); v_fill $(( cx - 1 )) $cy 3 1 ' ' -2 $CS }
      cshade $WHITE $(( 0.18 + 0.82 * glow )); v_put $cx $cy '·' $CS
    fi
    frame_end $t
    ob_beat
  done
  # ...and the last half second is the dead glass, black inside a cabinet
  # that is still lit, which is the picture the window closes on.
  return 0
}

# ── THE TWO FILES THE HOUSE KEEPS, as the self test says them ───────────────
# terminal.save is every machine's progress and terminal.conf every setting,
# and both come across from another Mac by being copied into a folder -- so
# the card that says what this machine found says whether it found THOSE, and
# where, and what was in them.  A save carried over looks exactly like a save
# never found until a machine opens and the animal is not there; this is the
# first moment the reader can be told, and it is before the menu.
file_where() {   # file_where PATH -> FW · the folder it sits in, in words
  local d="${1:h}"
  if [[ "${d:A}" == "${REPO:A}" ]]; then FW='IN THIS FOLDER'
  elif [[ "$d" == "$HOME" ]]; then FW='IN ~'
  elif [[ "$d" == "$HOME"/* ]]; then FW="IN ~${d#$HOME}"
  else FW="IN $d"; fi
  return 0
}
typeset -ga BOOT_FT BOOT_FC
typeset -g  BOOT_FBRIEF=''
boot_files() {   # -> BOOT_FT BOOT_FC the card's lines · BOOT_FBRIEF the same, for the coin door
  local st name k m what='' xdg
  local -i c
  local -A per
  BOOT_FT=(); BOOT_FC=()
  name="${${SAVE_FILE:t}:u}"
  file_where "$SAVE_FILE"
  case "$SAVE_STATE" in
    found) st="FOUND · $FW · $SAVE_KEYS KEY"; (( SAVE_KEYS == 1 )) || st+='S'; c=$LIME
           BOOT_FBRIEF='save found' ;;
    empty) st="FOUND · $FW · BUT EMPTY"; cshade $AMBER 0.85; c=$CS
           BOOT_FBRIEF='save found, empty' ;;
    unreadable) st="CANNOT BE READ · $FW"; cshade $RED 0.8; c=$CS
           BOOT_FBRIEF='save unreadable' ;;
    *)     # WHERE IT LOOKED, which is the one thing a reader who put theirs
           # somewhere else needs to be told
           if [[ -n "${ALIEN_SAVE:-}" ]]; then st="NOT FOUND · LOOKED $FW"
           else
             xdg="${XDG_STATE_HOME:-$HOME/.local/state}/alien"
             [[ "$xdg" == "$HOME"/* ]] && xdg="~${xdg#$HOME}"
             st="NOT FOUND · LOOKED IN THIS FOLDER AND $xdg"
           fi
           cshade $AMBER 0.85; c=$CS
           BOOT_FBRIEF='no save found' ;;
  esac
  BOOT_FT+=("$(printf '  %-9s %-16s %s' SAVE "$name" "$st")"); BOOT_FC+=($c)
  # A SAVE COPIED INTO THE FOLDER WHILE THE CABINET WAS UP is not switched to
  # under the machines that are holding the other one -- a pack writing its
  # progress into a file it never read is how a carried-over save gets
  # overwritten -- so it is named here and read at the next power-on.
  if [[ -z "${ALIEN_SAVE:-}" && "${${SAVE_FILE:h}:A}" != "${REPO:A}" && -f "$REPO/terminal.save" ]]; then
    cshade $AMBER 0.85
    BOOT_FT+=("$(printf '  %-9s %-16s %s' '' TERMINAL.SAVE 'NEW IN THIS FOLDER · READ AT THE NEXT POWER-ON')"); BOOT_FC+=($CS)
  fi
  # ...AND WHOSE PROGRESS IS IN IT, by the machine each key belongs to -- with
  # the animal's name and the coin bank beside the two that have one, since a
  # name the reader recognises is the proof a key count is not
  if [[ "$SAVE_STATE" == found ]]; then
    for k in "${(@k)SAVE[@]}"; do m="${k%%.*}"; per[$m]=$(( ${per[$m]:-0} + 1 )); done
    for m in system intelligence xenogotchi arcade; do
      (( ${per[$m]:-0} )) || continue
      case "$m" in
        xenogotchi) what+="${what:+  ·  }XENOGOTCHI${P_PET:+ $P_PET}" ;;
        arcade)     what+="${what:+  ·  }ARCADE${P_CREDITS:+ $P_CREDITS COINS}" ;;
        *)          what+="${what:+  ·  }${m:u}" ;;
      esac
      unset "per[$m]"
    done
    (( ${#per[@]} )) && what+="${what:+  ·  }${#per[@]} MORE"
    [[ -n "$what" ]] && { cshade $GREY 1.05; BOOT_FT+=("$(printf '  %-9s %-16s %s' '' 'HOLDING' "$what")"); BOOT_FC+=($CS); }
  fi
  if [[ "$CFG_STATE" == found ]]; then
    st="FOUND · IN THIS FOLDER · $CFG_KEYS SETTING"; (( CFG_KEYS == 1 )) || st+='S'; c=$LIME
    BOOT_FBRIEF+=' · config found'
  elif [[ "$CFG_STATE" == unreadable ]]; then
    st='CANNOT BE READ · FACTORY SETTINGS'; cshade $RED 0.8; c=$CS
    BOOT_FBRIEF+=' · config unreadable'
  else
    st='NOT FOUND · FACTORY SETTINGS'; cshade $AMBER 0.85; c=$CS
    BOOT_FBRIEF+=' · no config found'
  fi
  BOOT_FT+=("$(printf '  %-9s %-16s %s' CONFIG TERMINAL.CONF "$st")"); BOOT_FC+=($c)
  return 0
}
typeset -gi BOOT_SAW_FILES=0              # the card got as far as the CONFIG line

# ── the power-on self test · TERMINAL's own BIOS ────────────────────────────
# THE CABINET BOOTS AND SAYS WHAT IT FOUND.  arcade.py scans its cartridge
# slots; this scans the five machines in the folder and the mirror into ~,
# which is the same sentence about a different house -- and it is the ONE
# place a reader is told what each machine wants before the menu has narrowed
# it down to a single line of amber.
page_boot() {   # page_boot [FORCED]
  # FORCED means somebody PRESSED for it, and a key that was pressed to skip
  # the opening is not a key that declines the card they have just asked for.
  local -i forced=${1:-0}
  if (( ! forced && SKIP_OPEN )); then return 0; fi
  local -i was_skip=$SKIP_OPEN
  (( forced )) && SKIP_OPEN=0
  local -a AT TX IC
  local -F t el
  local -i i n=0
  _boot() { AT+=($1); TX+=("$2"); IC+=($3) }
  # ONE COLUMN OF DOTS, so the answers line up whatever the machine is called
  local -i DOTC=62
  _dots() {   # DOT = enough dots to carry the eye to the answer
    local -i n=$(( DOTC - ${#1} )) i
    DOT=' '
    (( n < 1 )) && { DOT='  '; return 0 }
    for (( i = 0; i < n; i++ )); do DOT+='.'; done
    DOT+=' '
  }
  local DOT lead
  _spec() {   # _spec AT LABEL VALUE VERDICT INK
    lead="$(printf '%-6s %s' "$2" "${3:-—}")"
    _dots "$lead"
    _boot $1 "${lead}${DOT}$4" $5
  }
  _boot 0.00 "ALIEN DYNAMICS INC.     TERMINAL BIOS v2.6.88" $CYAN
  cshade $GREY 1.1; local -i g=$CS
  _spec 0.24 CPU   "${${SPEC_CPU:u}:-UNKNOWN}" OK $g
  _spec 0.48 RAM   "${SPEC_RAM:+${SPEC_RAM:u} CORE}" OK $LIME
  _spec 0.72 DISK  "${SPEC_DISK:u}" OK $g
  _spec 0.96 PANEL "${SPEC_PANEL:-$TCOLS x $TROWS CELLS} @ $(printf '%.0f' $HZ) HZ" OK $g
  # THE ONE FIGURE A READER ACTUALLY ASKS FOR, and the card is where to put
  # it.  At the first power up the governor has not run yet, so the honest
  # answer is the rung it is ABOUT to try; on a rescan it has been running
  # for however long the visit has lasted and can say what it is holding.
  _spec 1.20 BEAT  "${#LADDER[@]} RUNGS · $( (( FPS_SEEN > 0.0 )) \
                      && printf 'HOLDING %.3g FPS' $FPS_SEEN \
                      || printf 'OPENING AT %.3g FPS' ${LADDER[$RUNG]} )" OK $g
  _spec 1.44 INK   "$( (( TRUE24 )) && print -n '24-BIT TRUECOLOR' || print -n 'XTERM 256 PALETTE' )" OK $g
  _spec 1.68 TERM  "${${TERM_PROGRAM:-${TERM:-UNKNOWN}}:u} · ${TCOLS} x ${TROWS}" OK $g
  _spec 1.92 SHELL "ZSH ${ZSH_VERSION:-?} · $( (( MB_OK )) && print -n 'UTF-8' || print -n 'BYTES' )" OK $g
  _spec 2.16 OS    "${P_OS:u}${SPEC_OSB:+ · BUILD ${SPEC_OSB:u}}" OK $g
  # SILENT, NOT MUTED.  Nothing has been muted -- there is no switch to mute
  # it with any more -- so what the line reports is whether this machine can
  # be heard at all: a Mac, with afplay, not down a pipe, not under --plain.
  _spec 2.40 SND   "WAVE-8 FM SYNTH" "$( (( SND_OK )) && print -n OK || print -n '· SILENT' )" $g
  _spec 2.64 SKY   "$( sky_where && printf 'LAT %.2f LON %.2f' $WHERE_LAT $WHERE_LON || print -n 'NO ZONE TABLE' )" \
                   "$( sky_where && print -n OK || print -n '· NONE' )" $g
  _boot 3.00 "SCANNING MACHINE SLOTS..." $AMBER
  # DECLARED ONCE, ABOVE THE LOOP.  `local x` on an x that already has a
  # value LISTS it -- zsh's typeset with no assignment is a QUERY -- so the
  # second time round this loop the shell printed `st='· ABSENT'` and
  # `ic=13121608` onto the glass.  Two lines of text at the bottom of an
  # alternate screen SCROLL it, and a renderer that only repaints what
  # changed never repairs the row everything moved off: the whole machine
  # tears one row upward and stays torn.  The old TERMINAL's --probe carries the
  # same warning at the same line, and this is the same mistake it names.
  local st ic
  for (( i = 0; i < M_N; i++ )); do
    if (( ! ${P_HERE[${M_PATH[$i]}]:-0} )); then st="· ABSENT"; cshade $RED 0.8; ic=$CS
    elif [[ -n "${P_NEEDS[${M_PATH[$i]}]:-}" ]]; then st="· NEEDS ${${P_NEEDS[${M_PATH[$i]}]}:u}"; cshade $AMBER 0.85; ic=$CS
    # ONLINE, AND WHICH OF THE TWO WAYS.  A slot that is a page pack opens in
    # this cabinet and a slot that is a program opens in a tab, and the card
    # that scans the slots at power-up is exactly where a reader would expect
    # to be told which -- particularly while the suite is half one and half
    # the other.
    elif [[ -n "${M_PACK[$i]:-}" ]]; then st="ONLINE · ON THIS GLASS"; ic=$LIME; (( n++ ))
    else st="ONLINE · IN A TAB"; ic=$LIME; (( n++ )); fi
    _boot $(( 3.30 + i * 0.22 )) "$(printf '  SLOT %02d   %-16s %s' $(( i + 1 )) "${M_NAME[$i]}" "$st")" $ic
  done
  local -F last=$(( 3.30 + M_N * 0.22 ))
  # THE SAVE AND THE CONFIG, read the way the slots were: a heading, then a
  # line each, landing a beat apart
  boot_files
  local -i fline
  _boot $(( last + 0.22 )) "READING SAVE AND CONFIG..." $AMBER
  for (( i = 0; i < ${#BOOT_FT[@]}; i++ )); do
    _boot $(( last + 0.52 + i * 0.22 )) "${BOOT_FT[$i]}" ${BOOT_FC[$i]}
  done
  fline=$(( ${#AT[@]} - 1 ))               # the CONFIG line · seen once the card has shown it
  last=$(( last + 0.52 + ${#BOOT_FT[@]} * 0.22 ))
  _boot $(( last )) "" $GREY
  _boot $(( last + 0.22 )) "MIRROR $P_LINKED OF $P_LEAVES LINKED INTO ~" $CYAN
  cmix $LIME $WHITE 0.3
  _boot $(( last + 0.50 )) "$( installed_p && print -n 'ALL SYSTEMS NOMINAL - OPENING TERMINAL' \
                               || print -n "HOUSE INCOMPLETE - ${INSTALLED_WHY:u}" )" $CM
  local -F total=$(( last + 1.58 ))
  snd open
  local -i shown row skipped=0
  # ── HOLDING THE CARD STILL ────────────────────────────────────────────
  # THIS CARD IS THE ONE PART OF THE OPENING WITH SOMETHING TO READ, and it
  # reads itself out at its own pace over nine seconds and then goes.  A
  # reader who wants to look at what their machine actually said had exactly
  # two options, and both of them were the card leaving.
  #
  # SO THE CLOCK IS PUT ON A LEASH.  Everything on this card is a function of
  # `t`, and `t` is the OPENING'S clock, which only ever moves when ob_beat
  # moves it -- so P does not stop a loop or set a flag that every drawing
  # routine then has to remember to check.  It is the one call at the bottom
  # of this loop that does not get made, and every line on the card stands
  # exactly where it was without knowing why.
  local -i paused=0
  ob_start
  while :; do
    t=$OB_T
    if (( SKIP_OPEN )); then
      skipped=1
    elif [[ -n "$OV_KEY" ]]; then
      if [[ "$OV_KEY" == (p|P) ]]; then
        if (( paused )); then paused=0; ob_go_on; snd move
        else paused=1; ob_hold; snd move; fi
      else
        (( paused )) && ob_go_on
        SKIP_OPEN=1; skipped=1
      fi
      OV_KEY=''
    fi
    (( skipped || t > total )) && break
    if (( paused )); then
      # HELD MEANS NOTHING IS REDRAWN.  The card is already on the glass and
      # the canvas still holds it, so the frame is not built again -- only
      # the bottom line is, and it breathes on the WALL clock rather than the
      # held one, because a picture that has stopped moving needs one thing
      # in it that has not to read as held rather than as hung.
      wave $(( $EPOCHREALTIME - OB_H )) $MO_ALERT 0
      v_fill 0 $(( SCR_H - 1 )) $SCR_W 1 ' ' $DIM $GLASS
      cmix $AMBER $WHITE $(( 0.15 + 0.45 * WV ))
      v_center $(( SCR_H - 1 )) '▌▌  HELD      [ P ]  GO ON      [ ANY KEY ]  SKIP' $CM $GLASS
      r_flush
      ob_wait 0.045
      continue
    fi
    frame_begin $t
    v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
    if (( t < 0.60 )); then                      # the CRT warming up
      local -F k=$(( t / 0.60 )) d
      local -i hh=$(( int(k * k * SCR_H) )) yy y0
      (( hh < 1 )) && hh=1
      y0=$(( (SCR_H - hh) / 2 ))
      cmix $WHITE $CYAN 0.35; local -i core=$CM
      for (( yy = y0; yy < y0 + hh; yy++ )); do
        d=$(( abs(yy - (SCR_H - 1) / 2.0) / (hh / 2.0 > 1.0 ? hh / 2.0 : 1.0) ))
        cshade $core $(( (1.0 - d * 0.8) * (0.9 - 0.55 * k) ))
        v_fill 0 $yy $SCR_W 1 ' ' -2 $CS
      done
      frame_end $t
      ob_beat
      continue
    fi
    el=$(( t - 0.60 ))
    shown=0
    for (( i = 0; i < ${#AT[@]}; i++ )); do
      (( el < AT[$i] )) && break
      (( shown++ ))
    done
    (( shown > fline )) && BOOT_SAW_FILES=1
    # LAID OUT LIKE A CARD, not dumped in a corner.  The old one started at
    # the top-left cell of a hundred-and-six-column glass and left the other
    # ninety columns and fourteen rows empty, which read as a machine that
    # had stopped rather than one that was working.
    row=$(( shown - (SCR_H - 4) )); (( row < 0 )) && row=0    # scroll like a BIOS
    cmix $GLASS $PURPLE 0.32; local -i hb=$CM
    v_fill 0 0 $SCR_W 1 ' ' -2 $hb
    cmix $WHITE $CYAN 0.15
    v_text 2 0 '◤ POWER-ON SELF TEST' $CM $hb
    cshade $WHITE 0.85
    local bl='TERMINAL BIOS 2.6'
    v_text $(( SCR_W - 2 - ${#bl} )) 0 "$bl" $CS $hb
    for (( i = row; i < shown; i++ )); do
      v_text 6 $(( 2 + i - row )) "${${TX[$i]}[0,$(( SCR_W - 13 ))]}" ${IC[$i]} $GLASS
    done
    wave $el $MO_BLINK 0
    (( shown - row < SCR_H - 4 )) && (( WV > 0.4 )) && {
      cmix $LIME $WHITE 0.4; v_text 6 $(( 2 + shown - row )) '█' $CM $GLASS }
    # a bar under it, so the wait has a shape
    # AGAINST THE TIME THE CARD ACTUALLY RUNS.  `total` is measured from t
    # and `el` from t minus the warm-up, so dividing one by the other left
    # the bar ten per cent short at the moment the last line landed.
    local -F prog=$(( el / (total - 0.60) )); (( prog > 1.0 )) && prog=1.0
    local -i bw=$(( SCR_W - 12 )) blit=$(( int(prog * (SCR_W - 12)) )) bi
    local bs='' br=''
    for (( bi = 0; bi < blit; bi++ )); do bs+='▓'; done
    for (( bi = blit; bi < bw; bi++ )); do br+='░'; done
    cshade $CYAN 0.9
    v_text 6 $(( SCR_H - 2 )) "$bs" $CS $GLASS
    cshade $DIM 0.9
    v_text $(( 6 + blit )) $(( SCR_H - 2 )) "$br" $CS $GLASS
    # A LONG OPENING WITH A WAY PAST IT is a gift; a long opening without one
    # is a toll.  So the way past it is printed, quietly, the whole time.
    wave $el $MO_BREATHE 0
    cmix $DIM $AMBER $(( 0.25 + 0.35 * WV ))
    v_center $(( SCR_H - 1 )) '[ P ]  PAUSE      [ ANY KEY ]  SKIP' $CM $GLASS
    local -F p=$(( 0.35 + el * 2.0 )); (( p > 1.0 )) && p=1.0
    frame_end $t $p
    ob_beat
  done
  # a white flash into TERMINAL
  (( forced )) && SKIP_OPEN=$was_skip
  for (( i = 0; i < 4; i++ )); do
    t=$OB_T
    frame_begin $t
    v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
    cmix $WHITE $CYAN 0.4
    cshade $CM $(( 0.85 - i * 0.22 ))
    v_fill 0 0 $SCR_W $SCR_H ' ' -2 $CS
    frame_end $t
    ob_beat
    if [[ -n "$OV_KEY" ]]; then
      PEND_KEY="$OV_KEY"
      # ...an arrow, with its sequence, so it lands as the arrow it was
      [[ "$OV_KEY" == $'\e' ]] && { PEND_ESC=1; PEND_SEQ="$OV_SEQ" }
    fi
  done
  return 0
}

# ── the gate · the one question TERMINAL asks ──────────────────────────────
draw_gate() {   # draw_gate T
  local -F t=$1
  local -i i x w=0
  local -a fk fv gk gl
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  local word='POWER OFF'
  big_width "$word"
  local -i bx=$(( (SCR_W - BW) / 2 ))
  cmix $RED $AMBER 0.5; local -i glow=$CM
  big_word "$word" $bx 2 $glow
  wave $t $MO_BREATHE 0
  cmix $RED $AMBER $(( 0.35 + 0.35 * WV )); local -i ink=$CM
  big_lit $ink
  v_center 9 'SHUT THE HOUSE DOWN?' $WHITE
  local yes='[ Y ]  POWER OFF' no='[ N ]  KEEP IT UP'
  wave $t $MO_ALERT 0
  cmix $RED $WHITE $(( 0.25 * WV ))
  v_text $(( SCR_W / 2 - ${#yes} - 3 )) 11 "$yes" $CM
  cmix $LIME $WHITE 0.2
  v_text $(( SCR_W / 2 + 3 )) 11 "$no" $CM
  # THE THREE FACTS, because a question that cannot be undone should say what
  # it does and what it does not.
  fk=('terminal.app' 'the prompt' 'terminal.conf')
  fv=('stays' 'comes back' 'nothing is waiting')
  local -i x=$(( (SCR_W - 3 * 24) / 2 ))
  for (( i = 0; i < 3; i++ )); do
    cshade $DIM 1.3
    v_text $(( x + i * 24 )) 14 "${fk[$i]}" $CS
    cshade $GREY 1.0
    v_text $(( x + i * 24 )) 15 "${fv[$i]}" $CS
  done
  cshade $DIM 1.25
  v_center 17 'the other tabs keep the house · only their own [M] takes it away' $CS
  # THE GATE'S OWN KEY BAR.  The menu's bar is still true of the menu and is
  # not true HERE -- [N] is not install while this is standing, it is the
  # answer to the question on the glass -- and a bar naming keys the surface
  # in front of it does not answer is the surface lying about itself.
  gk=("[Y]" "[N]" "⎋"); gl=(" power off" " keep it up" " keep it up")
  for (( i = 0; i < ${#gk[@]}; i++ )); do
    w=$(( w + ${#gk[$i]} + ${#gl[$i]} ))
    (( i < ${#gk[@]} - 1 )) && w=$(( w + 4 ))
  done
  x=$(( (SCR_W - w) / 2 )); (( x < 0 )) && x=0
  cshade $PURPLE 0.75
  v_hline 0 $G_RULE $SCR_W '─' $CS
  for (( i = 0; i < ${#gk[@]}; i++ )); do
    v_text $x $G_HINT "${gk[$i]}" $AMBER
    x=$(( x + ${#gk[$i]} ))
    v_text $x $G_HINT "${gl[$i]}" $GREY
    x=$(( x + ${#gl[$i]} + 4 ))
  done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE INSTALLER, ON THE GLASS
# ══════════════════════════════════════════════════════════════════════════
# IT USED TO TAKE THE WINDOW.  [N] INSTALL dropped the alternate screen and
# handed the raw terminal to scripts/bootstrap.zsh -- so
# the one moment this program asks the reader for something irreversible was
# also the one moment it stopped looking like itself: a page of white text
# over the top of whatever the shell had been doing, with the cabinet gone.
#
# THE INSTALLER IS STILL THE INSTALLER.  Nothing about linking, the ~/.zshrc
# block or the switch moved into this file -- that work is bootstrap.zsh's,
# it still runs standalone from a prompt, and it is still the only thing that
# knows how to do any of it.  What changed is who does the ASKING and who
# does the INK: TERMINAL runs it with `--report` to read the state and
# `--install`/`--remove` to do the work, both of which answer in
# `state<TAB>text` records, and draws those records itself.
#
# WHICH MEANS THERE IS ONE INSTALLER AND TWO SURFACES, and they cannot drift,
# because the glass is not a second copy of the steps -- it is a reader of
# the same four emitters every step already reports through.
UI_INST=''          # '' closed · otherwise 'install' or 'reset'
INST_STAGE='ask'    # ask · tools · done
INST_TITLE=''
INST_HEAD=''        # the line over the records on the done page · '' is "what changed"
typeset -ga INST_ST INST_TX
# ...AND A SECOND QUESTION, FOR THE TOOLS.  The hook is a symlink and a
# block, done in the glass in a blink; the tools are Homebrew, a Brewfile
# and a service, which take minutes, print as they go and ask for a
# password.  So the page asks twice: the hook is put in and reported, then
# the exact lines the tools phase would run are shown under their own
# question, and a Y hands the whole terminal to bootstrap.zsh --tools (the
# same stepping-aside a machine uses to run a real program) and comes back
# to the report when it is done.  A machine with every tool already on it
# never sees the second question.
typeset -ga INST_HOOK_ST INST_HOOK_TX   # what the hook step said, kept under the tools question

inst_capture() {   # inst_capture ARGS... — the installer's records, read back
  local -a out
  local line st tx
  INST_ST=(); INST_TX=()
  # ALIEN_DEALT SAYS THE WINDOW IS ALREADY SOMEBODY'S, so nothing downstream
  # decides to open one of its own; ALIEN_REPORT is what turns the page into
  # records.  2>&1 because a step that fails says so on stderr, and a failure
  # the reader cannot see is the worst way for an installer to end.
  out=("${(@f)$(ALIEN_REPORT=1 ALIEN_DEALT=$$ ALIEN_REPO="$REPO" \
                zsh "$REPO/scripts/bootstrap.zsh" "$@" 2>&1)}")
  for line in "${out[@]}"; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == *$'\t'* ]]; then
      st="${line%%$'\t'*}"; tx="${line#*$'\t'}"
    else
      st=''; tx="$line"
    fi
    # ANYTHING THAT IS NOT A RECORD IS STILL SHOWN.  A stray line from a tool
    # the installer called is exactly the thing worth reading, and dropping
    # it because it arrived in the wrong shape would hide the one message
    # that explains why nothing worked.
    [[ "$st" == (ok|warn|bad|info) ]] || { st='info'; tx="$line" }
    INST_ST+=("$st"); INST_TX+=("$tx")
  done
  return 0
}

inst_open() {   # inst_open install|uninstall
  UI_INST="$1"
  INST_STAGE='ask'; INST_HEAD=''
  if [[ "$1" == uninstall ]]; then INST_TITLE='PUT THIS MAC BACK?'
  else                         INST_TITLE='MAKE EVERY NEW WINDOW THIS ONE?'; fi
  inst_capture --report
  # THE PLATE UNDER THE GLASS HAS TO AGREE WITH THE GLASS.  The panel is
  # painted into the STATIC layer, so without this it went on reading
  # [N]INSTALL [R]RESCAN [Q]POWER OFF while the page in front of it said [N]
  # meant `not now` and [Q] meant `not now` too -- the cabinet contradicting
  # itself in two places a thumb apart, on the one page that changes ~/.zshrc.
  SURF_KEYS='[Y]DO IT   [N]NOT NOW   [⎋]NOT NOW'
  redress
  xf_arm $MO_QUICK_IN
  BEAT_SKIP=1
  snd open
  return 0
}

inst_close() {
  UI_INST=''; INST_ST=(); INST_TX=()
  surf_dress          # ...and the menu's own keys come back with the menu
  redress
  xf_arm $MO_QUICK_OUT
  snd away
  return 0
}

inst_do() {
  BEAT_SKIP=1
  # MOCK TOUCHES NOTHING.  --report is a reading and is safe to run anywhere;
  # --install writes to somebody's home directory, and a demo that does that
  # is not a demo.
  if (( MOCK )); then
    INST_ST=(info); INST_TX=('mock · nothing on this machine was touched')
    INST_TITLE='NOTHING WAS CHANGED'; INST_STAGE='done'
    snd pick; return 0
  fi
  if [[ "$UI_INST" == uninstall ]]; then inst_capture --remove;  INST_TITLE='TAKEN BACK OUT'
  else                               inst_capture --install; INST_TITLE='INSTALLED'; fi
  INST_STAGE='done'
  SURF_KEYS='[ANY KEY]BACK'
  # THE ROWS ARE A READING OF THE FOLDER and the folder just changed.  This is
  # what turns [N] INSTALL into [T] TERMINAL and [E] RESET the moment the
  # installer finishes: menu_build asks installed_p, installed_p counts the
  # leaves that resolve back into this repo, and the leaves are what was just
  # linked.  The reader presses a key to leave this page and the menu behind
  # it has already changed shape.
  probe_scan
  # ...AND THE CABINET HAS TO BE STOOD UP AGAIN TO SAY SO.  The row list is
  # drawn live and would have caught up on its own, but the key strip across
  # the control panel is painted into the STATIC layer -- so without this the
  # glass offered [E] RESET while the panel underneath it still read
  # [N]INSTALL, which is the cabinet contradicting itself in two places a
  # thumb apart.
  redress
  snd pick
  # THE SECOND QUESTION, if there is anything for it to ask.  --plan answers
  # in records: one line per command the tools phase would run, or a single
  # ok saying there is nothing to run -- and only the lines are a question.
  if [[ "$UI_INST" == install ]]; then
    INST_HOOK_ST=("${(@)INST_ST[@]}"); INST_HOOK_TX=("${(@)INST_TX[@]}")
    inst_capture --plan
    local -i i lines=0
    for (( i = 0; i < ${#INST_ST[@]}; i++ )); do [[ "${INST_ST[$i]}" == info ]] && (( lines++ )); done
    if (( lines )); then
      INST_STAGE='tools'; INST_TITLE='NOW THE TOOLS THE MACHINES LEAN ON?'
      SURF_KEYS='[Y]RUN IT   [N]LATER   [⎋]LATER'
      redress
    else
      INST_ST=("${(@)INST_HOOK_ST[@]}"); INST_TX=("${(@)INST_HOOK_TX[@]}")
    fi
  fi
  return 0
}

# ...AND THE TOOLS, IN THE TERMINAL.  bootstrap.zsh --tools is interactive
# -- Homebrew's installer wants a password and a RETURN, brew bundle prints
# its progress -- so the cabinet steps aside for it exactly as it does for a
# machine's program, and comes back to what is true afterwards.
inst_tools() {
  BEAT_SKIP=1
  if (( MOCK )); then
    INST_ST=(info); INST_TX=('mock · nothing on this machine was touched')
    INST_TITLE='NOTHING WAS CHANGED'; INST_STAGE='done'
    SURF_KEYS='[ANY KEY]BACK'; redress
    snd pick; return 0
  fi
  surf_handover 'INSTALL · the tools' zsh "$REPO/scripts/bootstrap.zsh" --tools
  inst_capture --report
  if (( HANDOVER_RC == 0 )); then INST_TITLE='THE TOOLS ARE IN'
  else INST_TITLE='THE TOOLS STOPPED SHORT'; fi
  INST_STAGE='done'; INST_HEAD='what is true now'
  SURF_KEYS='[ANY KEY]BACK'
  probe_scan
  redress
  snd pick
  return 0
}
inst_later() {   # [N] on the tools question · the hook's own report stands
  INST_ST=("${(@)INST_HOOK_ST[@]}"); INST_TX=("${(@)INST_HOOK_TX[@]}")
  INST_ST+=(info); INST_TX+=('the tools can go in later: [N] INSTALL again, or scripts/bootstrap.zsh --tools')
  INST_TITLE='INSTALLED'; INST_STAGE='done'
  SURF_KEYS='[ANY KEY]BACK'
  redress
  snd away
  return 0
}

draw_inst() {   # draw_inst T
  local -F t=$1
  local -i i x y w=0 mw=0 glow ink
  local -a gk gl
  local word='INSTALL' yes no head
  [[ "$UI_INST" == uninstall ]] && word='UNINSTALL'
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  big_width "$word"
  # INSTALL IS THE COLD END OF THE PALETTE AND RESET IS THE WARM ONE, which
  # is the same grammar the power gate uses: the question that takes
  # something away is the one that runs hot.
  if [[ "$UI_INST" == uninstall ]]; then cmix $AMBER $RED 0.45
  else                               cmix $CYAN $LIME 0.45; fi
  glow=$CM
  big_word "$word" $(( (SCR_W - BW) / 2 )) 2 $glow
  wave $t $MO_BREATHE 0
  if [[ "$UI_INST" == uninstall ]]; then cmix $AMBER $RED $(( 0.35 + 0.35 * WV ))
  else                               cmix $CYAN $LIME $(( 0.35 + 0.35 * WV )); fi
  ink=$CM
  big_lit $ink
  v_center 9 "$INST_TITLE" $WHITE
  if [[ "$INST_STAGE" == ask || "$INST_STAGE" == tools ]]; then
    if [[ "$INST_STAGE" == tools ]];      then yes='[ Y ]  RUN IT';      no='[ N ]  LATER'
    elif [[ "$UI_INST" == uninstall ]]; then yes='[ Y ]  TAKE IT OUT'; no='[ N ]  LEAVE IT'
    else                                     yes='[ Y ]  DO IT';       no='[ N ]  NOT NOW'; fi
    wave $t $MO_ALERT 0
    cmix $AMBER $WHITE $(( 0.25 * WV ))
    v_text $(( SCR_W / 2 - ${#yes} - 3 )) 11 "$yes" $CM
    cshade $GREY 1.0
    v_text $(( SCR_W / 2 + 3 )) 11 "$no" $CS
    if [[ "$INST_STAGE" == tools ]]; then head='the hook is in · these are the lines that run next, in this window'
    else head='what is true right now'; fi
  else
    head="${INST_HEAD:-what changed}"
  fi
  cshade $DIM 1.25
  v_center 13 "$head" $CS
  # THE RECORDS, LEFT-ALIGNED UNDER ONE ANOTHER AND THE BLOCK CENTRED.  Five
  # lines each centred on their own would put five different left edges on
  # the glass and make a list look like a paragraph.
  for (( i = 0; i < ${#INST_TX[@]}; i++ )); do
    (( ${#INST_TX[$i]} > mw )) && mw=${#INST_TX[$i]}
  done
  x=$(( (SCR_W - mw - 2) / 2 )); (( x < 2 )) && x=2
  y=15
  for (( i = 0; i < ${#INST_TX[@]}; i++ )); do
    (( y > G_RULE - 3 )) && break
    case "${INST_ST[$i]}" in
      ok)   v_text $x $y '·' $LIME  ;;
      warn) v_text $x $y '·' $AMBER ;;
      bad)  v_text $x $y '·' $RED   ;;
    esac
    # a line that is about to run is read in full ink; an aside is dimmer
    if [[ "${INST_ST[$i]}" == info && "$INST_STAGE" != tools ]]; then cshade $DIM 1.25
    else                                                              cshade $GREY 1.0; fi
    v_text $(( x + 2 )) $y "${INST_TX[$i]}" $CS
    (( y++ ))
  done
  # THE WAY BACK, ON THE SAME PAGE AS THE QUESTION.  A hook that opens a
  # full-screen program on every new window is the one change in this folder
  # that can lock somebody out of their own machine.  Printing the way out in
  # the installer's last paragraph is printing it where they can only read it
  # if nothing went wrong -- so it goes here, before they answer.
  cshade $DIM 1.3
  if [[ "$INST_STAGE" == ask && "$UI_INST" == install ]]; then
    v_center $(( G_RULE - 2 )) 'every new window opens TERMINAL · [Q] always leaves it at your prompt' $CS
  elif [[ "$INST_STAGE" == tools ]]; then
    v_center $(( G_RULE - 2 )) 'homebrew asks for your password in the window · TERMINAL comes back when it is done' $CS
  elif [[ "$INST_STAGE" == done && "$UI_INST" == install ]]; then
    v_center $(( G_RULE - 2 )) 'ALIEN_NO_TERMINAL=1 zsh is a plain prompt · bootstrap.zsh --hook off is the switch' $CS
  fi
  if [[ "$INST_STAGE" == ask ]]; then
    gk=("[Y]" "[N]" "⎋"); gl=(" do it" " not now" " not now")
  elif [[ "$INST_STAGE" == tools ]]; then
    gk=("[Y]" "[N]" "⎋"); gl=(" run it" " later" " later")
  else
    # ONE KEY, NAMED ONCE.  The ask bar lists [N] and ⎋ because two keys mean
    # the same thing there and both are worth knowing; here EVERY key means
    # the same thing, and printing two of them would be picking two at random
    # out of a hundred and calling them the way out.
    gk=("[ ANY KEY ]"); gl=("  back to the menu")
  fi
  for (( i = 0; i < ${#gk[@]}; i++ )); do
    w=$(( w + ${#gk[$i]} + ${#gl[$i]} ))
    (( i < ${#gk[@]} - 1 )) && w=$(( w + 4 ))
  done
  x=$(( (SCR_W - w) / 2 )); (( x < 0 )) && x=0
  cshade $PURPLE 0.75
  v_hline 0 $G_RULE $SCR_W '─' $CS
  for (( i = 0; i < ${#gk[@]}; i++ )); do
    v_text $x $G_HINT "${gk[$i]}" $AMBER
    x=$(( x + ${#gk[$i]} ))
    v_text $x $G_HINT "${gl[$i]}" $GREY
    x=$(( x + ${#gl[$i]} + 4 ))
  done
  return 0
}

draw_small() {   # the window is not big enough for the machine
  c_clear
  local -a msg
  msg=("T E R M I N A L" "" "the terminal needs a bigger window" ""
       "have ${TCOLS} x ${TROWS}" "need ${MIN_W} x ${MIN_H}" ""
       "resize, or press  cmd -  to shrink the font" "[Q] quit")
  local -i i y=$(( TROWS / 2 - ${#msg[@]} / 2 ))
  (( y < 0 )) && y=0
  for (( i = 0; i < ${#msg[@]}; i++ )); do
    (( y + i >= TROWS )) && break
    local -i c=$GREY
    (( i == 0 )) && c=$MAGENTA
    c_center $(( y + i )) "${${msg[$i]}[0,$(( TCOLS > 1 ? TCOLS - 1 : 0 ))]}" $c $VOID
  done
  r_flush
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 18 · THE SMALL NOISES        arcade.py's section 6, and the suite's
# ══════════════════════════════════════════════════════════════════════════
# macOS's own system sounds through afplay, and nothing at all anywhere else.
# Nothing is downloaded, nothing is bundled, nothing is synthesised.
#
#   law 29 · MOTION IS GUARDED, and a noise is motion you cannot see coming.
#            It is off down a pipe, off under --plain, off where afplay is
#            missing, and off on any machine that is not a Mac.
#
# THERE IS NO SWITCH FOR IT ANY MORE, and there does not need to be.  Every
# level below is well under half and the loudest of them fires on a key that
# opened something; the quietest, which fires most, is a third of the way to
# nothing.  A switch for a noise nobody has ever wanted to stop is a lamp on
# a control panel and a line in a file and a key on the strip, spent on a
# question that does not come up.  So SND_OK is a CAPABILITY -- can this
# machine make a sound at all -- and nothing else.
#   law 45 · NOTHING WAITS ON IT.  Every play is a detached process the
#            surface never reaps and never blocks on; a sound that made a
#            repaint late would be a sound that broke the card.
#   law 5  · and it is QUIET.  Every level here is well under half, the
#            movement tick quietest of all, because the reader is wearing
#            headphones at one in the morning and did not ask for a fanfare
#            every time the cursor moves.
SND_OK=0
SND_DIR='/System/Library/Sounds'
SND_F=('move'  'Tink.aiff'      '0.18'
       'pick'  'Pop.aiff'       '0.35'
       'save'  'Glass.aiff'     '0.40'
       'no'    'Basso.aiff'     '0.28'
       'open'  'Hero.aiff'      '0.42'
       'start' 'Submarine.aiff' '0.40'
       'away'  'Blow.aiff'      '0.42'
       'bye'   'Purr.aiff'      '0.30')
SND_N=8
snd_init() {   # snd_init — can this surface be heard at all
  SND_OK=0
  [[ -t 1 ]] || return 0
  (( OPT_PLAIN )) && return 0
  [[ "$OSTYPE" == darwin* ]] || return 0
  [[ -d "$SND_DIR" ]] || return 0
  whence -p afplay >/dev/null 2>&1 || return 0
  SND_OK=1
  return 0
}
snd() {   # snd JOB — one noise, detached, never waited on
  (( SND_OK && CFG_SOUND )) || return 0   # the capability AND CONFIG's switch (18d)
  local job="$1" f='' v=''
  local -i i
  for (( i = 0; i < SND_N * 3; i += 3 )); do
    [[ "${SND_F[$i]}" == "$job" ]] || continue
    f="${SND_F[$(( i + 1 ))]}"; v="${SND_F[$(( i + 2 ))]}"
    break
  done
  [[ -n "$f" && -f "$SND_DIR/$f" ]] || return 0
  # DETACHED, AND DISOWNED IN THE SAME BREATH.  A background job this shell
  # still owns is a job the shell waits for on the way out, and the way out
  # of these surfaces is a signal -- so a card that had just played its
  # farewell would have hung on it.
  { afplay -v "$v" "$SND_DIR/$f" >/dev/null 2>&1 &! } 2>/dev/null
  return 0
}
say() { SAY_MSG="$1"; SAY_T=$EPOCHREALTIME }

# ── THE TTY GOES RAW, and TERMINAL is the one that does it ──────────────────
# A cabinet is a picture and a picture has no keys.  The HOST owns the
# keyboard, and a host that forgets leaves the terminal in canonical mode:
# `read -k1` then waits for a NEWLINE, so every key the reader presses does
# nothing at all until they press return and the whole line arrives at once.
# The roster looks perfect and answers nothing, which is a very quiet way to
# be broken.
TTY_SAVE=''
tty_raw() {
  [[ -t 0 ]] || return 0
  TTY_SAVE="$( { stty -g </dev/tty; } 2>/dev/null )" || TTY_SAVE=''
  { stty -echo -icanon min 1 time 0 </dev/tty; } 2>/dev/null || true
  return 0
}
tty_back() {
  [[ -n "$TTY_SAVE" ]] && { stty "$TTY_SAVE" </dev/tty; } 2>/dev/null
  TTY_SAVE=''
  return 0
}
# ?1049h the alternate screen · ?25l the cursor away · ?7l no autowrap
#
# ?1000h ?1006h THE WHEEL IS OURS.  On the alternate screen there is no
# scrollback to reach, but Terminal.app scrolls the window anyway: a wheel
# notch over the cabinet rolled the whole picture up into the shell's old
# lines, and rolling back was rolling into rows that were gone.  ?1007h
# (alternate scroll, the wheel as cursor keys) is xterm's answer and
# Terminal.app does not give it -- so the cabinet asks for the mouse
# instead.  With reporting on, the terminal never scrolls: every notch and
# every click arrives on the input stream as a report that names its button
# and its cell, the door reads the reports the way it reads keys (SECTION
# 15), a notch over the glass scrolls whatever is standing there, and a
# notch anywhere else is dropped.  1000 is the plainest protocol -- presses,
# releases and the wheel, no motion -- and 1006 is the encoding that spells
# a column past ninety-five without a byte the reader cannot decode.
# ?1007h stays on for the terminal that has it and not the mouse.
scr_enter() { printf '\033[?1049h\033[?25l\033[?7l\033[?1007h\033[?1000h\033[?1006h'; }
scr_leave() { printf '\033[0m\033[?1006l\033[?1000l\033[?1007l\033[?7h\033[?25h\033[?1049l'; }
# CONFIG's SCREEN=fill · the glass covers the WHOLE terminal, the cabinet frame
# hidden, at any window size -- full-screen included -- with no window resizing.
# static_paint, frame_begin and night all check CFG_FILL; a change to it repaints
# the still layer for the new mode and lets the channel-change wash run.
scr_refit() { rebuild; GLASS_KEY=''; xf_arm; return 0 }

# ── PUTTING THE TERMINAL BACK AFTER SOMEBODY ELSE HAS HAD IT ──────────────
# A MACHINE THAT RUNS A STRANGER'S PROGRAM HANDS THE TERMINAL OVER for as
# long as that program runs, and some of them do not hand it back.  Every AI
# command line in the suite is an interactive terminal application; asked for
# its version with a tty anywhere on its three standard descriptors, one can
# decide it is being run interactively, switch the terminal into ITS modes --
# raw, bracketed paste, and above all MOUSE REPORTING -- and then be killed
# by its leash before it has turned any of them off again.
#
# WHAT THAT LOOKS LIKE FROM THE OTHER SIDE IS A HAUNTING.  Mouse reporting
# makes the terminal answer every movement of the pointer with a burst of
# escape sequences ON THE INPUT STREAM -- and the input stream is this
# cabinet's keyboard.  The reader, touching nothing, watches the machine
# flip pages, refuse letters it never received and play the no sound over and
# over, because from in here it is indistinguishable from somebody typing.
#
# So the door owns the repair.  Every mode a child might have switched on is
# switched off by NAME -- the four mouse protocols, the two encodings, focus
# reporting and bracketed paste -- the cabinet's own are re-asserted, and
# whatever already arrived is drained before it can be read as a key.
#
# THE CABINET'S OWN NOW INCLUDE THE MOUSE (scr_enter says why), so the
# repair is not "no mouse" but "OUR mouse": the plain protocol and the one
# encoding, and none of the motion-tracking ones a child may have left on,
# which would answer every twitch of the pointer with a report to decode.
scr_guard() {
  [[ -t 1 ]] || return 0
  printf '\033[?9l\033[?1000l\033[?1001l\033[?1002l\033[?1003l'
  printf '\033[?1004l\033[?1005l\033[?1006l\033[?1015l\033[?2004l'
  printf '\033[?25l\033[?7l\033[?1007h\033[?1000h\033[?1006h'
  scr_drain
  r_invalidate
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# STEPPING ASIDE · the one honest way to run a full program in this window
# ══════════════════════════════════════════════════════════════════════════
# THE PICTURE COMES DOWN AND THE PROGRAM GETS THE REAL TERMINAL.  A machine
# that wants to run something interactive has three options and only three:
# deal it a tab, draw a terminal emulator inside the glass, or get out of its
# way.  The middle one is a per-BYTE state machine -- a grid, a cursor, scroll
# regions, an alternate screen of its own, SGR, wide characters -- and a
# program redrawing a full screen emits tens of thousands of bytes a second
# against a shell that costs ten microseconds a step.  It would not be slow,
# it would drop bytes, and a terminal emulator that drops bytes is worse than
# no terminal emulator.
#
# So this is the third.  The cabinet folds itself away -- alternate screen
# down, the tty back the way it was found, stderr pointed at the terminal
# again -- the program runs in the foreground with a real controlling
# terminal at full native speed, and when it is finished the cabinet comes
# back up exactly where it was standing.
#
# ^C BELONGS TO THE PROGRAM WHILE IT IS RUNNING.  Both processes are in the
# foreground group, so an interrupt is delivered to both -- and this shell's
# own handler would tear the cabinet down under a reader who only meant to
# stop the thing in front of them.  Ignored here, restored on the way out;
# the child sets its own disposition and is unaffected.
typeset -gi HANDOVER_RC=0
surf_handover() {   # surf_handover LABEL CMD...
  local label="$1"; shift
  local -F t0
  local junk
  (( $# )) || return 1
  # /dev/tty, NOT THE INHERITED DESCRIPTORS.  A machine's key handler is
  # called as `${PACK_KEY} enter >/dev/null` -- deliberately, so that a pack
  # which prints cannot scribble on the glass -- so by the time this is
  # reached stdout is the floor.  `[[ -t 1 ]]` was therefore false and this
  # function returned without doing anything at all, which is what ⏎ looked
  # like from the other side: a key that did nothing, silently.
  #
  # The terminal is reached by NAME instead.  Everything below writes to
  # /dev/tty explicitly and hands the child all three descriptors on it, so
  # none of this depends on what the caller was given.
  [[ -r /dev/tty && -w /dev/tty ]] || return 1
  {
    scr_leave
    tty_back
    printf '\033[0m\033[2J\033[H'
    print -r -- "── $label ──"
    print -r -- ''
  } >/dev/tty 2>/dev/null
  # ^C BELONGS TO THE PROGRAM WHILE IT IS RUNNING.  Both processes are in the
  # foreground group, so an interrupt reaches both -- and this shell's own
  # handler would tear the cabinet down under a reader who only meant to stop
  # the thing in front of them.  Ignored here, restored on the way out; the
  # child sets its own disposition and is unaffected.
  trap '' INT
  trap '' QUIT
  t0=$EPOCHREALTIME
  # STDIN IS LEFT ALONE WHERE IT ALREADY IS THE TERMINAL.  The door redirects
  # a pack's stdout and nothing else, so fd 0 is still the genuine tty -- and
  # a program handed `/dev/tty` instead reports its terminal as `/dev/tty`
  # rather than the ttys00N it is really on, which is the sort of small lie
  # that confuses anything that goes looking.
  if [[ -t 0 ]]; then
    "$@" >/dev/tty 2>/dev/tty
  else
    "$@" </dev/tty >/dev/tty 2>/dev/tty
  fi
  HANDOVER_RC=$?
  trap 'WARM_SIG=1; cleanup; exit 130' INT
  trap 'WARM_SIG=1; cleanup; exit 131' QUIT
  # A RUN THAT ENDED AT ONCE ENDED BADLY, and the reader has to be able to
  # read why before the picture paints over it.  One that lasted is one they
  # quit on purpose, and making them press a key for that is a key too many.
  if (( HANDOVER_RC != 0 )) || (( EPOCHREALTIME - t0 < 3.0 )); then
    {
      print -r -- ''
      print -r -- "── it came back $HANDOVER_RC · press a key for TERMINAL ──"
    } >/dev/tty 2>/dev/null
    { stty -echo -icanon min 1 time 0 </dev/tty } 2>/dev/null
    IFS= read -rsk1 -u0 junk 2>/dev/null
  fi
  { tty_raw; scr_enter; scr_guard } >/dev/tty 2>/dev/null
  rebuild
  BEAT_SKIP=1
  return 0
}

# WHATEVER IS ALREADY IN THE QUEUE IS NOT A KEYPRESS.  It is whatever the
# terminal said back to a program that has just been killed, and reading it as
# input is the haunting above.  Bounded, because a stream that never goes
# quiet must not become the frame loop.
scr_drain() {
  local junk
  local -i n=0
  [[ -t 0 ]] || return 0
  while (( n < 4096 )); do
    IFS= read -rsk1 -u0 -t 0.002 junk 2>/dev/null || break
    (( n++ ))
  done
  return 0
}

# ── NOTHING BUT THIS PROGRAM WRITES TO THIS TERMINAL ──────────────────────
# A SINGLE LINE ON STDERR DESTROYS THE PICTURE.  Not figuratively: the screen
# is a grid this program owns cell by cell, and one warning printed into it
# scrolls every row up by one, tears the frame in half, and leaves the row
# diff repainting only the cells it thinks changed -- so the damage stays on
# the glass until something forces a full repaint.  It is the loudest
# possible failure for the quietest possible cause, and the cause is usually
# a shell warning nobody would otherwise care about.
#
# SO STDERR IS HELD while the picture is up, and let go when it comes down --
# where it prints onto the terminal the reader is handed back, which is the
# only place a warning was ever any use.
SCR_ERR=''
typeset -gi SCR_ERRFD=0
err_hold() {
  [[ -n "$SCR_ERR" ]] && return 0
  # MKTEMP, AND NOT A NAME MADE OUT OF THE PID.  This used to be
  # `${TMPDIR:-/tmp}/alien-term.$$.err`, which is a name anybody can work out
  # in a directory anybody can write to.  Leave a SYMLINK at that name under
  # a pid this program is about to get -- there are only so many, and they
  # come round -- and `: >` truncates whatever it points at, after which the
  # whole session's stderr is appended to it.  Nothing here is worth that,
  # and the file has no reason to be findable: it lives for one run and is
  # read by nobody but `err_free`.
  SCR_ERR="$(mktemp "${TMPDIR:-/tmp}/alien-term.XXXXXX" 2>/dev/null)" \
    || { SCR_ERR=''; return 0 }
  chmod 600 -- "$SCR_ERR" 2>/dev/null
  exec {SCR_ERRFD}>&2 2>>"$SCR_ERR"
  return 0
}
err_free() {
  [[ -n "$SCR_ERR" ]] || return 0
  (( SCR_ERRFD )) && exec 2>&$SCR_ERRFD {SCR_ERRFD}>&-
  SCR_ERRFD=0
  if [[ -s "$SCR_ERR" ]]; then
    print -u2 -r -- ''
    print -u2 -r -- 'TERMINAL held these back while the picture was up:'
    sed 's/^/  /' "$SCR_ERR" >&2 2>/dev/null
  fi
  rm -f "$SCR_ERR" 2>/dev/null
  SCR_ERR=''
  return 0
}

KEY=''
key_ready() {   # is there a key waiting, without taking the frame with it
  KEY=''
  [[ -t 0 ]] || return 1
  IFS= read -rsk1 -u0 -t 0.0001 KEY 2>/dev/null || return 1
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 18a · THE KEYS, AND THE WHEEL      what one byte from the tty means
# ══════════════════════════════════════════════════════════════════════════
# AN ESCAPE IS THE FIRST BYTE OF SOMETHING, and the loop used to find out
# what by reading two more -- which was every sequence the cabinet knew.  A
# mouse report is longer (`\e[<65;40;12M` is one wheel notch, with its
# button and the cell it was over) and it arrives in the same stream as the
# keys, so the rest of a sequence is read HERE, once, whatever it turns out
# to be, and every surface asks the same question of the same answer.
#
#   key_seq              after an ESC: the rest of the sequence -> KSEQ
#                        ('' for a bare escape) · a mouse report is decoded
#                        on the way and MOUSE says so
#   mouse_note B X Y     one report, decoded: a wheel notch over the glass
#                        goes into WH_N (up is negative) · a click, a
#                        release, a notch over the bezel or the wall, is
#                        nothing at all
#   wheel_drain          the notches already waiting behind this one are the
#                        same gesture, and are taken with it
#   wheel_apply          the gesture, to whatever is standing on the glass
#   raw_sift BYTES       a burst bound for a child, with the reports taken
#                        out of it -> RAW_OUT (the wheel noted on the way)
#
# ONE GESTURE, NOT A QUEUE.  A trackpad flick is thirty notches in a fifth
# of a second, and a loop that answered one a frame would still be
# scrolling long after the finger had stopped.  So the notches already in
# the buffer are counted with the one that woke the loop and applied as one
# move -- the cursor's glide carries it -- and the picture stays under the
# hand.  A KEY FOUND BEHIND THE WHEEL IS KEPT: the tty cannot be given a
# byte back, so a real key read while counting goes on the pending key,
# with its sequence if it had one, and the next turn reads it as the key
# it is.
KSEQ=''; PEND_SEQ=''
typeset -gi MOUSE=0 PEND_ESC=0 WH_N=0 WH_X=0 WH_Y=0 WH_CAP=40
key_seq() {
  local k2
  local -i i
  KSEQ=''; MOUSE=0
  if (( PEND_ESC )); then PEND_ESC=0; KSEQ="$PEND_SEQ"; PEND_SEQ=''; key_seq_note; return 0; fi
  IFS= read -rsk1 -u0 -t 0.02 k2 2>/dev/null || return 0
  if [[ "$k2" == '[' ]]; then
    KSEQ='['
    # CSI: parameter and intermediate bytes, then one final byte in @ .. ~
    while IFS= read -rsk1 -u0 -t 0.02 k2 2>/dev/null; do
      KSEQ+="$k2"
      (( #k2 >= 64 && #k2 <= 126 )) && break
      (( ${#KSEQ} > 48 )) && break
    done
    # the X10 report is CSI M and three bytes that are not a sequence at all
    if [[ "$KSEQ" == '[M' ]]; then
      for (( i = 0; i < 3; i++ )); do
        IFS= read -rsk1 -u0 -t 0.02 k2 2>/dev/null || break
        KSEQ+="$k2"
      done
    fi
  elif [[ "$k2" == 'O' ]]; then
    KSEQ='O'
    IFS= read -rsk1 -u0 -t 0.02 k2 2>/dev/null && KSEQ+="$k2"
  else
    # WHATEVER FOLLOWED THE ESCAPE IS NOT THROWN AWAY.  Terminal.app sends
    # ESC+key for Option-as-Meta, and a sequence whose tail arrives late over
    # ssh looks exactly the same from here -- so the byte goes on the pending
    # key rather than into the floor, and the next turn of the loop reads it
    # as the key it is.
    PEND_KEY="$k2"
    return 0
  fi
  key_seq_note
  return 0
}
key_seq_note() {   # a sequence that is a mouse report is noted as one
  local p c
  local -a f
  local -i b x y
  if [[ "$KSEQ" == '[<'*[Mm] ]]; then
    p="${KSEQ:2:-1}"; f=(${(s:;:)p})
    (( ${#f[@]} == 3 )) || return 0
    [[ "${f[0]}" == <-> && "${f[1]}" == <-> && "${f[2]}" == <-> ]] || return 0
    MOUSE=1
    [[ "${KSEQ: -1}" == M ]] && mouse_note ${f[0]} ${f[1]} ${f[2]}
  elif [[ "$KSEQ" == '[M'??? ]]; then
    MOUSE=1
    c="${KSEQ:2:1}"; b=$(( #c - 32 ))
    c="${KSEQ:3:1}"; x=$(( #c - 32 ))
    c="${KSEQ:4:1}"; y=$(( #c - 32 ))
    mouse_note $b $x $y
  fi
  return 0
}
mouse_note() {   # mouse_note B X Y
  local -i b=$1 gx=$(( $2 - 1 - OX - C_SCR )) gy=$(( $3 - 1 - OY - R_SCR ))
  (( b & 64 )) || return 0                    # a click, a release, a drag
  (( (b & 3) < 2 )) || return 0               # a sideways wheel
  (( gx >= 0 && gx < SCR_W && gy >= 0 && gy < SCR_H )) || return 0
  if (( (b & 3) == 0 )); then WH_N=$(( WH_N - 1 )); else WH_N=$(( WH_N + 1 )); fi
  WH_X=$gx; WH_Y=$gy
  return 0
}
wheel_drain() {
  local k2
  local -i n=0
  while (( n++ < 64 )); do
    IFS= read -rsk1 -u0 -t 0.001 k2 2>/dev/null || return 0
    if [[ "$k2" == $'\e' ]]; then
      key_seq
      (( MOUSE )) && continue
      [[ -n "$PEND_KEY" ]] && return 0        # ESC+key · key_seq kept the key
      PEND_KEY=$'\e'; PEND_ESC=1; PEND_SEQ="$KSEQ"
      return 0
    fi
    PEND_KEY="$k2"
    return 0
  done
  return 0
}
wheel_apply() {
  local -i n=$WH_N i r
  WH_N=0
  (( n )) || return 0
  (( n >  WH_CAP )) && n=$WH_CAP
  (( n < -WH_CAP )) && n=$(( -WH_CAP ))
  # the two questions take no wheel: a notch is not an answer
  (( UI_GATE )) && return 0
  [[ -n "$UI_INST" ]] && return 0
  if [[ -n "$UI_SURF" ]]; then
    [[ -n "$PACK_KEY" ]] || return 0
    if (( n < 0 )); then for (( i = 0; i < -n; i++ )); do ${PACK_KEY} wheelup   >/dev/null || break; done
    else                 for (( i = 0; i <  n; i++ )); do ${PACK_KEY} wheeldown >/dev/null || break; done; fi
    return 0
  fi
  # the menu: the cursor goes with the wheel, a row a notch, and quietly --
  # a notch is not a press, and thirty of them are not thirty presses
  r=$(( UI_ROW + n ))
  (( r < 0 )) && r=0
  (( r > R_N - 1 )) && r=$(( R_N - 1 ))
  UI_ROW=$r
  return 0
}
raw_sift() {   # raw_sift BYTES -> RAW_OUT
  setopt localoptions extendedglob
  local s="$1" c
  local -i b x y
  RAW_OUT="$s"
  [[ "$s" == *$'\e['* ]] || return 0
  while [[ "$s" == (#b)(*)$'\e[<'(<->)\;(<->)\;(<->)([Mm])(*) ]]; do
    b=${match[1]}; x=${match[2]}; y=${match[3]}
    [[ "${match[4]}" == M ]] && mouse_note $b $x $y
    s="${match[0]}${match[5]}"
  done
  while [[ "$s" == (#b)(*)$'\e[M'(?)(?)(?)(*) ]]; do
    c="${match[1]}"; b=$(( #c - 32 ))
    c="${match[2]}"; x=$(( #c - 32 ))
    c="${match[3]}"; y=$(( #c - 32 ))
    mouse_note $b $x $y
    s="${match[0]}${match[4]}"
  done
  RAW_OUT="$s"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 18b · THE GLASS TERMINAL      a terminal inside the picture · the cabinet's
# ══════════════════════════════════════════════════════════════════════════
# THIS WAS INTELLIGENCE'S, AND IT IS THE CABINET'S NOW.  A terminal written
# out in zsh, a pty for a program to hold, the keyboard while it has it,
# and the paint: the machine wrote it to run its agents inside the picture,
# and it was tested by running it against the original's Vt on six hundred
# generated streams until every cell, every colour, the cursor and the
# replies matched.  The moment the door wanted a plain shell on the glass
# -- [T] TERMINAL, a prompt of your own with the cabinet around it -- there
# were two owners for one emulator, and an emulator has one.  So the whole
# of it lives here, every machine that puts a program on the glass uses the
# same one, and the sessions are the cabinet's: pumped every frame whether
# or not the machine that started them is standing, and stopped with it.
#
#   the VT       vt_*      feed it bytes, read the grid back
#   the session  ss_*      a pty (zsh/zpty), sized by perl, and the program on it
#   the keyboard kb_*      what the reader typed, moved into the program's own frame
#   the store    gt_*      several sessions, one on the keyboard at a time
#   the paint    gt_head · gt_draw_shell   the head row and the grid, in the glass
#
# WHAT A SURFACE DOES WITH IT is the surface's: INTELLIGENCE turns to its
# shell page and back; the door's own shell is SECTION 18c.  Nothing below
# names a page.

# ── the few small things the paint borrows ────────────────────────────────
typeset -gi GT_FG=0 GT_LBL=0 GT_DIM=0
GT_FG=$CYAN; GT_LBL=$GREY; GT_DIM=$DIM
gt_ell() {   # gt_ell TEXT N -> GELL, with a real ellipsis rather than a cut
  local s="$1"
  local -i n=$2
  if (( ${#s} <= n )); then GELL="$s"; return 0; fi
  (( n < 2 )) && { GELL="${${s[0,0]}:-}"; return 0 }
  GELL="${s[0,$(( n - 2 ))]}…"
}
gt_short() { GSHT="${1/#$HOME/~}" }
gt_secs() {   # gt_secs SECONDS -> GSEC, in the largest unit that stays short
  local -F v=0.0
  (( v = $1, 1 )) 2>/dev/null || { GSEC='—'; return 0 }
  (( v < 0.0 )) && v=0.0
  if   (( v >= 3600.0 )); then printf -v GSEC '%.1f h' $(( v / 3600.0 ))
  elif (( v >= 90.0 ));   then printf -v GSEC '%d min' $(( int(v / 60.0 + 0.5) ))
  elif (( v >= 10.0 ));   then printf -v GSEC '%d s' $(( int(v + 0.5) ))
  else                         printf -v GSEC '%.1f s' $v; fi
  return 0
}
# A SHORT-LIVED FILE, TRACKED FOR THE WAY OUT.  The size helper below is a
# file that sets the size of a terminal and then execs whatever it was
# handed -- not a thing to leave in /tmp under a name anybody can guess.
typeset -ga GT_TMPS
gt_tmp() {   # gt_tmp TEMPLATE -> GTMP · created 0600
  GTMP="$(mktemp "${TMPDIR:-/tmp}/$1.XXXXXX" 2>/dev/null)" || { GTMP=''; return 1 }
  chmod 600 -- "$GTMP" 2>/dev/null
  GT_TMPS+=("$GTMP")
  return 0
}
gt_tmp_sweep() {
  local f
  for f in "${(@)GT_TMPS[@]}"; do [[ -n "$f" ]] && rm -f -- "$f" 2>/dev/null; done
  GT_TMPS=()
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# A TERMINAL, BEHIND THE GLASS            zsh port of the old Vt
# ══════════════════════════════════════════════════════════════════════════
# Feed it what the agent wrote; read the grid back off it.  Nothing it reads
# can reach the reader's own terminal: every byte the agent writes becomes a
# character in a cell in this grid, and the only thing ever drawn is the
# grid.  The oldest hole in a machine like this -- a string that drives
# somebody else's terminal -- is closed by the SHAPE of the thing rather
# than by a filter over it.
#
# TWO STRINGS PER ROW, AND NOT A CELL PER CELL.  Python could keep a list of
# lists and a tuple in every cell; zsh cannot, and walking a stream one
# character at a time runs at 131 KB/s -- a single repaint would cost more
# than a frame.  So a row is a STRING of W characters, its colours are a
# second string of W characters, and a run of text is ONE SPLICE of each.
# Measured on the same payload that walk costs 46 ms, splicing costs 1.2.
#
# THE COLOUR OF A CELL IS A CHARACTER, and the character is an index into a
# table.  A pen -- foreground, background, the bold/underline/reverse flags
# -- is interned the first time it is seen and gets a codepoint of its own
# from 0x100 up, where every value is an ordinary printable character.  Two
# cells are the same colour exactly when their pen characters are equal,
# which is all the renderer needs to find runs, and it never has to turn a
# character back into a number to do it.

typeset -gi VT_W=80 VT_H=24
typeset -ga VT_CH VT_PN VT_ACH VT_APN
typeset -gi VT_X=0 VT_Y=0 VT_TOP=0 VT_BOT=23
typeset -gi VT_WRAPNEXT=0 VT_WRAP=1 VT_ORIGIN=0 VT_INSERT=0 VT_CURS=1 VT_ALT=0
typeset -gi VT_AX=0 VT_AY=0 VT_ATOP=0 VT_ABOT=0
typeset -g  VT_AP=''
typeset -gi VT_SX=0 VT_SY=0 VT_BELL=0 VT_MOUSE=0 VT_PASTE=0 VT_SORG=0 VT_SAVED=0
typeset -gi VT_APPCUR=0 VT_APPKEY=0 VT_DIRTY=0
typeset -g  VT_P='' VT_SP='' VT_BUF='' VT_REPLY='' VT_TITLE='' VT_TABS=''
typeset -g  VT_BLANKC='' VT_BLANKP='' VT_GL='B' VT_G0='B' VT_G1='B'
typeset -gA VT_PEN VT_PCH
# DECLARED, BECAUSE THE CABINET RUNS `set -u`.  Every one of these is written
# before it is read in normal flow -- but "normal flow" is an argument, and
# under set -u the first path that reads one a tick early does not misbehave,
# it ENDS THE SHELL.  Naming them here costs nothing and removes the class.
typeset -g  VT_PPEN='' VT_PR='' VT_TAIL='' VT_OUT='' VT_DG='' VT_CONT=''
typeset -gi VT_A=0 VT_COL=-1 VT_ATE=0 VT_CW=1
typeset -ga VT_G VR_X VR_N VR_TXT VR_PEN
typeset -gi VT_PNEXT=256
typeset -g  VT_SGL='B'
# THE LINES THAT LEFT THE TOP.  The original kept none: a terminal in the
# glass was the grid and nothing before it, and an agent that had said
# something two screens ago had said it to nobody.  A line scrolled off the
# top of the main screen by a newline is kept here -- not one deleted by a
# program editing its own screen, and nothing from the alternate screen,
# which has no past by design -- and VT_VIEW is how far back the reader is
# looking: 0 is the live grid, N is N lines up into these.  New output while
# the reader is looking back moves the grid, not the view: the lines under
# the eye stay where they are, and the count grows.
typeset -ga VT_SB_CH VT_SB_PN
typeset -gi VT_SB_N=0 VT_SB_MAX=600 VT_VIEW=0 VT_SBOK=0

# ── the pen table ─────────────────────────────────────────────────────────
# "fg bg flags" in, one character out.  fg/bg are -1 for "the terminal's own
# default", 0-255 for the xterm palette and anything at or above 1<<24 for a
# 24-bit colour.  The table is capped: an agent that invents forty thousand
# colours gets the last one over and over rather than a grid full of
# codepoints nobody can draw.
vt_pen() {   # vt_pen "FG BG FL" -> VT_PPEN
  VT_PPEN="${VT_PCH[$1]:-}"
  [[ -n "$VT_PPEN" ]] && return 0
  # FULL MEANS START AGAIN, NOT STOP.  This used to hand back the DEFAULT
  # pen once the table filled -- and because the table is deliberately never
  # emptied, that state survived `vt_init` and every colour in every pane was
  # gone for the rest of the session.  Twenty-odd full-screen frames of a
  # truecolour gradient is enough to fill it, which is a thing agents do.
  # Clearing costs the colours already on the grids until their next repaint,
  # which is the following frame; the default pen is re-interned first so it
  # keeps the character the blank rows were built from.
  if (( VT_PNEXT > 40000 )); then
    VT_PEN=(); VT_PCH=(); VT_PNEXT=256
    VT_PPEN="${(#)VT_PNEXT}"
    VT_PCH['-1 -1 0']="$VT_PPEN"; VT_PEN[$VT_PPEN]='-1 -1 0'
    (( VT_PNEXT++ ))
    [[ "$1" == '-1 -1 0' ]] && return 0
  fi
  VT_PPEN="${(#)VT_PNEXT}"
  VT_PCH[$1]="$VT_PPEN"
  VT_PEN[$VT_PPEN]="$1"
  (( VT_PNEXT++ ))
  return 0
}

# THE PEN TABLE IS NEVER THROWN AWAY.  It used to be cleared here, which is
# fine for one terminal and fatal for two: a second session starting would
# empty the table while the FIRST session's saved grid was still full of pen
# characters that only that table could explain, and stepping back into it
# would paint every cell in the default colour.  Interning is append-only,
# the characters are unique for the life of the machine, and two terminals
# sharing a pen is two terminals agreeing what that colour is.
vt_init() {   # vt_init W H
  VT_W=$1; VT_H=$2
  (( VT_W < 2 )) && VT_W=2
  (( VT_H < 2 )) && VT_H=2
  (( ${#VT_PCH[@]} )) || { VT_PNEXT=256; vt_pen '-1 -1 0' }
  vt_pen '-1 -1 0'; VT_P="$VT_PPEN"
  local i
  VT_BLANKC=''; VT_BLANKP=''
  for (( i = 0; i < VT_W; i++ )); do VT_BLANKC+=' '; VT_BLANKP+="$VT_P"; done
  VT_TABS=''
  for (( i = 0; i < VT_W; i++ )); do
    (( i && i % 8 == 0 )) && VT_TABS+='T' || VT_TABS+='.'
  done
  vt_reset
  return 0
}

vt_reset() {
  local i
  VT_CH=(); VT_PN=()
  for (( i = 0; i < VT_H; i++ )); do VT_CH+=("$VT_BLANKC"); VT_PN+=("$VT_BLANKP"); done
  VT_SB_CH=(); VT_SB_PN=(); VT_SB_N=0; VT_VIEW=0
  VT_X=0; VT_Y=0; VT_TOP=0; VT_BOT=$(( VT_H - 1 ))
  VT_WRAPNEXT=0; VT_WRAP=1; VT_ORIGIN=0; VT_INSERT=0; VT_CURS=1; VT_ALT=0
  vt_pen '-1 -1 0'; VT_P="$VT_PPEN"
  VT_SP="$VT_P"; VT_SX=0; VT_SY=0; VT_SAVED=0
  VT_BUF=''; VT_GL='B'; VT_G0='B'; VT_G1='B'
  VT_APPCUR=0; VT_APPKEY=0
  (( VT_DIRTY++ ))
  return 0
}

# ── putting characters down ───────────────────────────────────────────────
# EVERY WRITE IS A SPLICE.  `${row[0,x-1]}$run${row[x+n,-1]}` replaces n cells
# at x without touching the rest, and because KSH_ARRAYS makes string
# subscripts zero-based those three pieces meet exactly.  The run is written
# to both strings in the same shape, so the two can never drift out of step.
# `[0,x-1]` IS NOT THE EMPTY PREFIX WHEN X IS ZERO -- IT IS THE WHOLE ROW.
# KSH_ARRAYS makes string subscripts zero-based, and `-1` still means "the
# last character", so `[0,-1]` is everything.  Writing a run at column zero
# therefore produced row + run + row, the row grew past its width, and every
# column after it was wrong for the rest of the session.  The guard is not
# an optimisation; without it the first write of most frames is corrupt.
vt_splice() {   # vt_splice Y X TEXT PENRUN
  local -i y=$1 x=$2 n=${#3}
  (( n )) || return 0
  if (( x > 0 )); then
    VT_CH[$y]="${VT_CH[$y][0,x-1]}${3}${VT_CH[$y][x+n,-1]}"
    VT_PN[$y]="${VT_PN[$y][0,x-1]}${4}${VT_PN[$y][x+n,-1]}"
  else
    VT_CH[$y]="${3}${VT_CH[$y][n,-1]}"
    VT_PN[$y]="${4}${VT_PN[$y][n,-1]}"
  fi
  return 0
}

vt_penrun() {   # vt_penrun N -> VT_PR   (N copies of the current pen)
  local -i n=$1
  VT_PR=''
  while (( n > 0 )); do VT_PR+="$VT_P"; (( n-- )); done
  return 0
}

# A RUN WITH NO CONTROL CHARACTERS IN IT.
#
# The fast lane is the whole point: text that fits on the rest of the row,
# with no insert mode and no pending wrap, is one splice and nothing else.
# Everything that does not fit is cut at the margin and the remainder is
# handed back through the wrap, which is the only place wrapping is decided.
# ── how many columns one character stands in ──────────────────────────────
# BY COMPARING THE CHARACTER, NOT ITS NUMBER.  zsh has no way to turn a
# multibyte character into its codepoint -- `printf %d "'X"` gives the first
# BYTE, which for anything outside ASCII is not the answer to any question --
# but a pattern RANGE compares by codepoint, so the character can be tested
# directly against the block it might live in.  This needs a multibyte
# LC_CTYPE, which the cabinet has already made certain of before this is
# ever sourced; without one every range below raises `character not in
# range` and the whole grid would be measured in bytes.
# AND REMEMBERED, because the answer never changes and the question is asked
# per character.  Fourteen range tests a character is nothing on a word and
# everything on a screen of box-drawing: a distinct-character count in the
# low hundreds means this is a hash lookup after the first line.
typeset -gA VT_CWC
VT_CW=1
vt_cwidth() {   # vt_cwidth CH -> VT_CW
  local c="$1"
  VT_CW=${VT_CWC[$c]:-9}
  (( VT_CW != 9 )) && return 0
  (( ${#VT_CWC[@]} > 4096 )) && VT_CWC=()
  vt_cwidth1 "$c"
  VT_CWC[$c]=$VT_CW
  return 0
}
vt_cwidth1() {   # vt_cwidth1 CH -> VT_CW
  local c="$1"
  [[ "$c" == [$'̀'-$'ͯ'] || "$c" == [$'︀'-$'️'] \
  || "$c" == [$'​'-$'‏'] || "$c" == [$'⃐'-$'⃰'] \
  || "$c" == [$'᪰'-$'᫿'] || "$c" == [$'᷀'-$'᷿'] ]] \
     && { VT_CW=0; return 0 }
  [[ "$c" == [$'ᄀ'-$'ᅟ'] || "$c" == [$'⺀'-$'〾'] \
  || "$c" == [$'ぁ'-$'㏿'] || "$c" == [$'㐀'-$'䶿'] \
  || "$c" == [$'一'-$'鿿'] || "$c" == [$'ꀀ'-$'꓏'] \
  || "$c" == [$'가'-$'힣'] || "$c" == [$'豈'-$'﫿'] \
  || "$c" == [$'︰'-$'﹯'] || "$c" == [$'＀'-$'｠'] \
  || "$c" == [$'￠'-$'￦'] \
  || "$c" == [$'\U0001f300'-$'\U0001faff'] \
  || "$c" == [$'\U0001f004'-$'\U0001f0cf'] ]] && { VT_CW=2; return 0 }
  VT_CW=1
  return 0
}

# THE SECOND HALF OF A WIDE CHARACTER IS A CELL THAT HOLDS NOTHING.  The
# original could put an empty string in it; a row that is one string of
# exactly W characters cannot, so it holds a permanent non-character instead
# and the readback drops it.  What reaches the screen is then one glyph two
# columns wide for two cells, which is the only spelling that stays aligned.
VT_CONT=$'￿'

# ESC ( 0 -- the line-drawing set, mapped over as it lands.  Written as a
# plain loop over the thirty-one characters it covers because the neat
# spelling of this -- `${s//(#m)[a-z{|}~]/...}` -- needs EXTENDED_GLOB, which
# this cabinet does not set, and without it `(#m)` is not a flag but a
# literal pattern that matches nothing and raises `bad pattern`.
typeset -gA VT_DECG
VT_DECG=(
  '`' $'◆'  a $'▒'  b $'␉'  c $'␌'  d $'␍'
  e $'␊'  f $'°'  g $'±'  h $'␤'  i $'␋'
  j $'┘'  k $'┐'  l $'┌'  m $'└'  n $'┼'
  o $'⎺'  p $'⎻'  q $'─'  r $'⎼'  s $'⎽'
  t $'├'  u $'┤'  v $'┴'  w $'┬'  x $'│'
  y $'≤'  z $'≥'  '{' $'π'  '|' $'≠'  '}' $'£'
  '~' $'·'
)
# SPLIT ONCE, THEN WALK THE ARRAY.  `${s[$i,$i]}` is O(i) in zsh, not O(1),
# so a per-character loop over a long run is quadratic -- 32 KB measured 2.4
# seconds here and over fifty once `vt_puts` had walked it a second time.
# `${(@s::)s}` costs one pass and the walk is then flat: same input, 121 ms.
vt_decg() {   # vt_decg S -> VT_DG
  local o='' c
  local -a ch; ch=("${(@s::)1}")
  for c in "${ch[@]}"; do o+="${VT_DECG[$c]:-$c}"; done
  VT_DG="$o"
}

# ONE CHARACTER, WITH ITS WIDTH.  Only reached when the run is not plain
# ASCII, which for an agent is a small fraction of what it writes.
vt_put1() {   # vt_put1 CH W
  local c="$1"
  local -i w=$2
  if (( VT_WRAPNEXT )); then
    if (( VT_WRAP )); then vt_cr; vt_lf; else (( VT_X = VT_W - 1 )); fi
    VT_WRAPNEXT=0
  fi
  if (( VT_X + w > VT_W )); then
    (( VT_WRAP )) || return 0
    vt_cr; vt_lf
  fi
  vt_penrun $w
  # INSERT MODE PUSHES THE ROW RIGHT AND LETS THE END FALL OFF.  The cells
  # from the cursor on move out of the way by exactly the width about to be
  # written, and the row is cut back to W afterwards -- a row that grows is a
  # row every subsequent column index is wrong about.
  if (( VT_INSERT )); then
    local sp='' ; local -i q
    for (( q = 0; q < w; q++ )); do sp+=' '; done
    if (( VT_X > 0 )); then
      VT_CH[$VT_Y]="${VT_CH[$VT_Y][0,VT_X-1]}$sp${VT_CH[$VT_Y][VT_X,-1]}"
      VT_PN[$VT_Y]="${VT_PN[$VT_Y][0,VT_X-1]}$VT_PR${VT_PN[$VT_Y][VT_X,-1]}"
    else
      VT_CH[$VT_Y]="$sp${VT_CH[$VT_Y]}"
      VT_PN[$VT_Y]="$VT_PR${VT_PN[$VT_Y]}"
    fi
    VT_CH[$VT_Y]="${VT_CH[$VT_Y][0,VT_W-1]}"
    VT_PN[$VT_Y]="${VT_PN[$VT_Y][0,VT_W-1]}"
  fi
  if (( w == 2 )); then vt_splice $VT_Y $VT_X "$c$VT_CONT" "$VT_PR"
  else vt_splice $VT_Y $VT_X "$c" "$VT_PR"; fi
  (( VT_X += w ))
  if (( VT_X >= VT_W )); then (( VT_X = VT_W - 1 )); VT_WRAPNEXT=1; fi
  return 0
}

# IS THERE ANYTHING IN THIS RUN THAT IS NOT ONE COLUMN WIDE?  One pattern
# match over the whole string answers for all of it.  Without this, ANY run
# holding a single non-ASCII character took the per-character path -- and a
# line of box-drawing, an accented word, a bullet, an arrow are all ordinary
# one-column characters that the fast lane handles perfectly well.  The slow
# lane is then only for what actually needs it: wide characters, which take
# two cells, and zero-width marks, which take none.
vt_odd_width() {   # vt_odd_width S -> 0 if anything in it is not width 1
  [[ "$1" == *[$'̀'-$'ͯ']* || "$1" == *[$'︀'-$'️']* \
  || "$1" == *[$'​'-$'‏']* || "$1" == *[$'⃐'-$'⃰']* \
  || "$1" == *[$'᪰'-$'᫿']* || "$1" == *[$'᷀'-$'᷿']* \
  || "$1" == *[$'ᄀ'-$'ᅟ']* || "$1" == *[$'⺀'-$'〾']* \
  || "$1" == *[$'ぁ'-$'㏿']* || "$1" == *[$'㐀'-$'䶿']* \
  || "$1" == *[$'一'-$'鿿']* || "$1" == *[$'ꀀ'-$'꓏']* \
  || "$1" == *[$'가'-$'힣']* || "$1" == *[$'豈'-$'﫿']* \
  || "$1" == *[$'︰'-$'﹯']* || "$1" == *[$'＀'-$'｠']* \
  || "$1" == *[$'￠'-$'￦']* \
  || "$1" == *[$'\U0001f300'-$'\U0001faff']* \
  || "$1" == *[$'\U0001f004'-$'\U0001f0cf']* ]]
}

vt_puts() {   # vt_puts TEXT
  local s="$1" run c
  local -i n room i
  [[ -n "$s" ]] || return 0
  if [[ "$VT_GL" == '0' ]]; then vt_decg "$s"; s="$VT_DG"; fi
  # NOT PLAIN ASCII: every character has to be measured.  A zero-width mark
  # is DROPPED rather than folded into the cell before it -- the original
  # could grow that cell's string, and a fixed-width row cannot.  It costs an
  # accent on text that almost never appears in an agent's output, and it
  # buys an invariant the whole renderer rests on.
  if (( VT_INSERT )) || { [[ "$s" == *[^$' '-$'~']* ]] && vt_odd_width "$s" }; then
    local -a ch; ch=("${(@s::)s}")
    for c in "${ch[@]}"; do
      vt_cwidth "$c"
      (( VT_CW )) || continue
      vt_put1 "$c" $VT_CW
    done
    (( VT_DIRTY++ ))
    return 0
  fi
  while [[ -n "$s" ]]; do
    if (( VT_WRAPNEXT )); then
      if (( VT_WRAP )); then vt_cr; vt_lf; else (( VT_X = VT_W - 1 )); fi
      VT_WRAPNEXT=0
    fi
    n=${#s}
    (( room = VT_W - VT_X ))
    if (( n < room )); then
      vt_penrun $n
      vt_splice $VT_Y $VT_X "$s" "$VT_PR"
      (( VT_X += n ))
      s=''
    elif (( ! VT_WRAP )); then
      # AUTOWRAP OFF, AND EVERY CHARACTER PAST THE MARGIN LANDS ON THE LAST
      # CELL.  The loop still did that one character at a time, re-copying
      # the whole remainder each pass -- `room` is permanently 1 once the
      # cursor is parked -- so 32 KB with `CSI ? 7 l` set took six seconds to
      # produce one visible character.  Only the last one survives, so only
      # the last one is written.
      vt_penrun $room
      vt_splice $VT_Y $VT_X "${s[0,room-1]}" "$VT_PR"
      if (( n > room )); then
        vt_penrun 1
        vt_splice $VT_Y $(( VT_W - 1 )) "${s[n-1,n-1]}" "$VT_PR"
      fi
      (( VT_X = VT_W - 1 )); VT_WRAPNEXT=1
      break
    else
      run="${s[0,room-1]}"
      s="${s[room,-1]}"
      vt_penrun $room
      vt_splice $VT_Y $VT_X "$run" "$VT_PR"
      (( VT_X = VT_W - 1 ))
      VT_WRAPNEXT=1
      [[ -n "$s" ]] || break
    fi
  done
  (( VT_DIRTY++ ))
  return 0
}

# ── moving about ──────────────────────────────────────────────────────────
vt_cr() { VT_X=0; VT_WRAPNEXT=0 }

vt_lf() {
  # a newline at the bottom is the one scroll whose top line is kept
  if (( VT_Y == VT_BOT )); then VT_SBOK=1; vt_scroll_up 1; VT_SBOK=0
  elif (( VT_Y < VT_H - 1 )); then (( VT_Y++ ))
  fi
  VT_WRAPNEXT=0
}

vt_ri() {   # reverse index
  if (( VT_Y == VT_TOP )); then vt_scroll_down 1
  elif (( VT_Y > 0 )); then (( VT_Y-- ))
  fi
  VT_WRAPNEXT=0
}

vt_goto() {   # vt_goto X Y
  local -i x=$1 y=$2
  if (( VT_ORIGIN )); then
    (( y += VT_TOP ))
    (( y > VT_BOT )) && (( y = VT_BOT ))
    (( y < VT_TOP )) && (( y = VT_TOP ))
  fi
  (( y < 0 )) && y=0; (( y > VT_H - 1 )) && (( y = VT_H - 1 ))
  (( x < 0 )) && x=0; (( x > VT_W - 1 )) && (( x = VT_W - 1 ))
  VT_X=$x; VT_Y=$y; VT_WRAPNEXT=0
}

# CLAMPED, BECAUSE THE COUNT COMES OFF THE WIRE.  `CSI 9999999999 I` is a
# tab-forward of ten billion, and this loop ran every one of them: the
# cursor saturates at the margin after the first, so the rest are pure spin.
# Twenty-two bytes from the agent froze the whole cabinet for what measured
# out at three hundred thousand years -- no drawing, no keys, no way back.
# There cannot be more tab stops than there are columns.
vt_tab() {   # vt_tab N
  local -i k=$1 x
  (( k > VT_W )) && k=$VT_W
  while (( k-- > 0 )); do
    (( x = VT_X + 1 ))
    while (( x < VT_W - 1 )) && [[ "${VT_TABS[$x,$x]}" != 'T' ]]; do (( x++ )); done
    VT_X=$x
  done
  (( VT_X > VT_W - 1 )) && (( VT_X = VT_W - 1 ))
  VT_WRAPNEXT=0
}

# ── scrolling, erasing ────────────────────────────────────────────────────
# THE REGION IS THE ONLY THING THAT MOVES.  Rows above VT_TOP and below
# VT_BOT are outside the scroll and must stay exactly where they are -- a
# full-screen agent puts its status line down there and would watch it walk
# up the screen otherwise.
#
# THIS IS A DELIBERATE DIVERGENCE FROM THE ORIGINAL, and the only one in the
# whole terminal.  That one scrolled by deleting rows out of the grid and
# inserting blank ones back, which is neat in a language with list slicing
# and quietly wrong: deleting three rows from the middle pulls EVERY row
# below the region up by three as well.  Set a region over the top half and
# scroll it, and the bottom half climbs.  Caught by fuzzing the two against
# each other -- the input was nine bytes -- and fixed here rather than
# copied, because "like the original" means the picture it was trying to
# draw, not the one it drew.
vt_scroll_up() {   # vt_scroll_up N
  local -i n=$1 i
  (( n > 0 )) || return 0
  (( n > VT_BOT - VT_TOP + 1 )) && (( n = VT_BOT - VT_TOP + 1 ))
  # THE TOP LINE GOES INTO THE PAST, when this is the main screen scrolling
  # from its own top edge by a newline (vt_lf says so).  A reader looking
  # back keeps looking at the same lines: the view moves with them.
  if (( VT_SBOK && ! VT_ALT && VT_TOP == 0 )); then
    for (( i = 0; i < n; i++ )); do
      VT_SB_CH+=("${VT_CH[$i]}"); VT_SB_PN+=("${VT_PN[$i]}")
    done
    (( VT_SB_N += n ))
    (( VT_VIEW )) && (( VT_VIEW += n ))
    if (( VT_SB_N > VT_SB_MAX + 100 )); then
      VT_SB_CH=("${(@)VT_SB_CH[@]:100}"); VT_SB_PN=("${(@)VT_SB_PN[@]:100}")
      (( VT_SB_N -= 100 ))
      (( VT_VIEW > VT_SB_N )) && VT_VIEW=$VT_SB_N
    fi
  fi
  for (( i = VT_TOP; i <= VT_BOT - n; i++ )); do
    VT_CH[$i]="${VT_CH[$i+n]}"; VT_PN[$i]="${VT_PN[$i+n]}"
  done
  for (( i = VT_BOT - n + 1; i <= VT_BOT; i++ )); do
    VT_CH[$i]="$VT_BLANKC"; VT_PN[$i]="$VT_BLANKP"
  done
  (( VT_DIRTY++ ))
}

vt_scroll_down() {   # vt_scroll_down N
  local -i n=$1 i
  (( n > 0 )) || return 0
  (( n > VT_BOT - VT_TOP + 1 )) && (( n = VT_BOT - VT_TOP + 1 ))
  for (( i = VT_BOT; i >= VT_TOP + n; i-- )); do
    VT_CH[$i]="${VT_CH[$i-n]}"; VT_PN[$i]="${VT_PN[$i-n]}"
  done
  for (( i = VT_TOP; i < VT_TOP + n; i++ )); do
    VT_CH[$i]="$VT_BLANKC"; VT_PN[$i]="$VT_BLANKP"
  done
  (( VT_DIRTY++ ))
}

# ERASED CELLS TAKE THE CURRENT BACKGROUND, not the default one.  A program
# that paints a panel by setting a background and clearing to end of line is
# relying on exactly this, and a terminal that blanks to the default instead
# draws that panel as a hole.
# THE ERASE PEN IS THE CURRENT ONE ONLY IF ITS BACKGROUND IS NOT THE DEFAULT.
# A program painting a panel sets a background and clears to end of line, and
# relies on the cleared cells keeping that background -- but it is only the
# BACKGROUND it is relying on.  Carrying the foreground and the bold/underline
# flags into blank cells as well leaves invisible attributes behind that the
# next thing written over them inherits.
vt_erase() {   # vt_erase Y X0 X1   (X1 exclusive)
  local -i y=$1 x0=$2 x1=$3 n i
  (( x0 < 0 )) && x0=0
  (( x1 > VT_W )) && (( x1 = VT_W ))
  (( n = x1 - x0 ))
  (( n > 0 )) || return 0
  local blank='' pen keep="$VT_P"
  local -a f; f=(${=${VT_PEN[$VT_P]:--1 -1 0}})
  (( ${f[1]} == -1 )) && VT_P="${VT_PCH[-1 -1 0]}"
  for (( i = 0; i < n; i++ )); do blank+=' '; done
  vt_penrun $n
  VT_P="$keep"
  vt_splice $y $x0 "$blank" "$VT_PR"
  (( VT_DIRTY++ ))
}

# NEITHER OF THESE CLEARS THE PENDING WRAP.  Erasing is not moving: a row
# filled to its last column has a wrap owed on the next character, and
# clearing the row does not pay it.  Clearing it here put the next character
# back on the row that had just been emptied instead of on the one below.
#
# AND MODE 3 IS THE SCROLLBACK, NOT THE SCREEN.  `CSI 3 J` asks for the
# lines that have scrolled off to be forgotten; a terminal that reads it as
# "erase everything" wipes the display of any program that tidies up after
# itself.  There is no scrollback here, so it is correctly nothing at all.
vt_ed() {   # vt_ed MODE
  local -i m=$1 i
  case $m in
    0) vt_erase $VT_Y $VT_X $VT_W
       for (( i = VT_Y + 1; i < VT_H; i++ )); do vt_erase $i 0 $VT_W; done ;;
    1) for (( i = 0; i < VT_Y; i++ )); do vt_erase $i 0 $VT_W; done
       vt_erase $VT_Y 0 $(( VT_X + 1 )) ;;
    3) ;;
    *) for (( i = 0; i < VT_H; i++ )); do vt_erase $i 0 $VT_W; done ;;
  esac
}

vt_el() {   # vt_el MODE
  case $1 in
    1) vt_erase $VT_Y 0 $(( VT_X + 1 )) ;;
    2) vt_erase $VT_Y 0 $VT_W ;;
    *) vt_erase $VT_Y $VT_X $VT_W ;;
  esac
}

# RESTORING A CURSOR THAT WAS NEVER SAVED IS NOT RESTORING IT TO THE ORIGIN.
# The original keeps `saved` as None until something saves, and DECRC on a
# fresh screen does nothing; restoring to (0,0) instead quietly undoes
# whatever the program had just done -- and `ESC 8` with no matching `ESC 7`
# is common, because it is how a program checks the terminal has the feature.
vt_save_cursor()    { VT_SX=$VT_X; VT_SY=$VT_Y; VT_SP="$VT_P"; VT_SGL="$VT_GL"
                      VT_SORG=$VT_ORIGIN; VT_SAVED=1 }
# THE PENDING WRAP IS CLEARED WHETHER OR NOT ANYTHING WAS SAVED.  In the
# original that line sits OUTSIDE the `if saved:`, and it is easy to read as
# part of it -- but a DECRC with no matching DECSC still means "put the
# cursor somewhere definite", and leaving a wrap owed after it puts the next
# character on the following row.
vt_restore_cursor() { VT_WRAPNEXT=0
                      (( VT_SAVED )) || return 0
                      VT_X=$VT_SX; VT_Y=$VT_SY; VT_P="$VT_SP"; VT_GL="$VT_SGL"
                      VT_ORIGIN=$VT_SORG
                      (( VT_X > VT_W - 1 )) && (( VT_X = VT_W - 1 ))
                      (( VT_Y > VT_H - 1 )) && (( VT_Y = VT_H - 1 ))
                      VT_WRAPNEXT=0 }

# THE ALTERNATE SCREEN IS A WHOLE SECOND GRID.  A full-screen agent takes it
# on the way in and gives it back on the way out, and what was on the first
# one has to be there untouched when it does -- that is the entire promise
# of the thing.
# IT IS NOT JUST THE GRID THAT IS PUT AWAY.  The cursor, the pen and the
# SCROLL REGION go with it, and what the program is handed is a blank screen
# at (0,0) with the region set back to the full height -- that is what makes
# it a second screen rather than the first one with the writing wiped off.
# Swapping only the characters left the region the old screen had set, and
# the first thing a full-screen program does is set a region, so the damage
# appeared one screen later and looked like a scrolling bug.
vt_alt_on() {
  (( VT_ALT )) && return 0
  VT_ACH=("${(@)VT_CH[@]}"); VT_APN=("${(@)VT_PN[@]}")
  VT_AX=$VT_X; VT_AY=$VT_Y; VT_AP="$VT_P"; VT_ATOP=$VT_TOP; VT_ABOT=$VT_BOT
  local i
  VT_CH=(); VT_PN=()
  for (( i = 0; i < VT_H; i++ )); do VT_CH+=("$VT_BLANKC"); VT_PN+=("$VT_BLANKP"); done
  VT_X=0; VT_Y=0; VT_TOP=0; (( VT_BOT = VT_H - 1 )); VT_WRAPNEXT=0
  VT_ALT=1; VT_VIEW=0; (( VT_DIRTY++ ))   # the second screen has no past to look into
}
vt_alt_off() {
  (( VT_ALT )) || return 0
  VT_CH=("${(@)VT_ACH[@]}"); VT_PN=("${(@)VT_APN[@]}")
  VT_X=$VT_AX; VT_Y=$VT_AY; VT_P="$VT_AP"; VT_TOP=$VT_ATOP; VT_BOT=$VT_ABOT
  VT_ACH=(); VT_APN=(); VT_ALT=0; VT_WRAPNEXT=0; (( VT_DIRTY++ ))
}

# ── SGR ───────────────────────────────────────────────────────────────────
typeset -gi VT_BOLD=1 VT_DIM=2 VT_ITAL=4 VT_UL=8 VT_BLINK=16 VT_REV=32
typeset -gi VT_HIDE=64 VT_STRK=128
typeset -gi VT_TRUE=16777216          # at or above this is a 24-bit colour

# 38;5;n and 38;2;r;g;b, in both the `;` and the `:` spelling.  Returns the
# colour in VT_COL and how many EXTRA groups it ate in VT_ATE.
vt_colour() {   # vt_colour I   (VT_G is the split parameter list)
  local -i i=$1
  local g="${VT_G[$i]}"
  local -a sub
  VT_COL=-1; VT_ATE=0
  if [[ "$g" == *:* ]]; then
    sub=("${(@s.:.)g}")
    if [[ "${sub[1]}" == 5 && -n "${sub[2]:-}" ]]; then
      VT_COL=$(( ${sub[2]:-0} & 255 )); return 0
    fi
    if [[ "${sub[1]}" == 2 ]]; then
      local -a v; v=("${(@)sub[2,-1]}")
      (( ${#v[@]} >= 4 )) && v=("${(@)v[1,-1]}")
      if (( ${#v[@]} >= 3 )); then
        VT_COL=$(( VT_TRUE | ((${v[0]:-0} & 255) << 16) | ((${v[1]:-0} & 255) << 8) | (${v[2]:-0} & 255) ))
      fi
    fi
    return 0
  fi
  local nx="${VT_G[$i+1]:-0}"
  if [[ "$nx" == 5 ]] && (( i + 2 < ${#VT_G[@]} )); then
    VT_COL=$(( ${VT_G[$i+2]:-0} & 255 )); VT_ATE=2; return 0
  fi
  if [[ "$nx" == 2 ]] && (( i + 4 < ${#VT_G[@]} )); then
    VT_COL=$(( VT_TRUE | ((${VT_G[$i+2]:-0} & 255) << 16) \
             | ((${VT_G[$i+3]:-0} & 255) << 8) | (${VT_G[$i+4]:-0} & 255) ))
    VT_ATE=4; return 0
  fi
  (( ${#VT_G[@]} - i - 1 > 0 )) && VT_ATE=1
  return 0
}

vt_sgr() {
  local cur="${VT_PEN[$VT_P]:--1 -1 0}"
  local -a f; f=(${=cur})
  local -i c=${f[0]} b=${f[1]} fl=${f[2]}
  local -i i n=${#VT_G[@]} a
  (( n )) || { VT_G=(0); n=1 }
  for (( i = 0; i < n; i++ )); do
    local g="${VT_G[$i]}"
    a=${${g%%:*}:-0}
    case $a in
      0)  c=-1; b=-1; fl=0 ;;
      1)  (( fl |= VT_BOLD )) ;;
      2)  (( fl |= VT_DIM )) ;;
      3)  (( fl |= VT_ITAL )) ;;
      4)  if [[ "$g" == 4:0 ]]; then (( fl &= ~VT_UL )); else (( fl |= VT_UL )); fi ;;
      5|6) (( fl |= VT_BLINK )) ;;
      7)  (( fl |= VT_REV )) ;;
      8)  (( fl |= VT_HIDE )) ;;
      9)  (( fl |= VT_STRK )) ;;
      21) (( fl &= ~VT_BOLD )) ;;
      22) (( fl &= ~(VT_BOLD | VT_DIM) )) ;;
      23) (( fl &= ~VT_ITAL )) ;;
      24) (( fl &= ~VT_UL )) ;;
      25) (( fl &= ~VT_BLINK )) ;;
      27) (( fl &= ~VT_REV )) ;;
      28) (( fl &= ~VT_HIDE )) ;;
      29) (( fl &= ~VT_STRK )) ;;
      39) c=-1 ;;
      49) b=-1 ;;
      38|48|58)
          vt_colour $i
          (( i += VT_ATE ))
          (( a == 38 )) && c=$VT_COL
          (( a == 48 )) && b=$VT_COL ;;
      *)  if   (( a >= 30 && a <= 37 ));   then (( c = a - 30 ))
          elif (( a >= 40 && a <= 47 ));   then (( b = a - 40 ))
          elif (( a >= 90 && a <= 97 ));   then (( c = a - 90 + 8 ))
          elif (( a >= 100 && a <= 107 )); then (( b = a - 100 + 8 ))
          fi ;;
    esac
  done
  vt_pen "$c $b $fl"; VT_P="$VT_PPEN"
}

# ── modes ─────────────────────────────────────────────────────────────────
vt_mode() {   # vt_mode ON PRIVATE
  local -i on=$1 priv=$2 n i
  for (( i = 0; i < ${#VT_G[@]}; i++ )); do
    n=${${VT_G[$i]%%:*}:-0}
    if (( ! priv )); then
      (( n == 4 )) && VT_INSERT=$on
      continue
    fi
    case $n in
      1)    VT_APPCUR=$on ;;
      3)    vt_ed 2; vt_goto 0 0 ;;
      6)    VT_ORIGIN=$on; vt_goto 0 0 ;;
      7)    VT_WRAP=$on ;;
      25)   VT_CURS=$on ;;
      9|1000|1001|1002|1003) (( on )) && VT_MOUSE=$n || VT_MOUSE=0 ;;
      2004) VT_PASTE=$on ;;
      47|1047) (( on )) && vt_alt_on || vt_alt_off ;;
      1048) (( on )) && vt_save_cursor || vt_restore_cursor ;;
      1049) if (( on )); then vt_save_cursor; vt_alt_on; vt_ed 2
            else vt_alt_off; vt_restore_cursor; fi ;;
    esac
  done
}

# ── what a terminal is expected to answer ─────────────────────────────────
# THE REPLY GOES BACK UP THE PTY, NOWHERE ELSE.  An agent asking "who are
# you" or "where is the cursor" is asking THIS terminal, and the answer is
# queued for the pty writer -- it is never printed, because printing it
# would put it on the reader's real screen.
vt_answer() { VT_REPLY+="$1" }

# `${VT_G[$i]:-}` AND NOT `${VT_G[$i]}`.  A CSI with no parameters at all --
# `ESC [ K`, `ESC [ J`, `ESC [ H`, which is most of what a repaint is made of
# -- leaves this array empty, and under the cabinet's `set -u` reading past
# the end of it does not give the empty string, it ENDS THE SHELL.  The whole
# machine would have died on an agent's first frame.
vt_arg() {   # vt_arg I DEFAULT -> VT_A
  local -i i=$1
  local g="${VT_G[$i]:-0}"
  VT_A=${${g%%:*}:-0}
  (( VT_A )) || VT_A=$2
}

vt_move() {   # vt_move FIN
  local fin="$1"
  local -i x=$VT_X y=$VT_Y k
  case "$fin" in
    A)    vt_arg 0 1; (( y -= VT_A )) ;;
    B|e)  vt_arg 0 1; (( y += VT_A )) ;;
    C|a)  vt_arg 0 1; (( x += VT_A )) ;;
    D)    vt_arg 0 1; (( x -= VT_A )) ;;
    E)    vt_arg 0 1; (( y += VT_A )); x=0 ;;
    F)    vt_arg 0 1; (( y -= VT_A )); x=0 ;;
    G|\`) vt_arg 0 1; (( x = VT_A - 1 )) ;;
    d)    vt_arg 0 1; (( y = VT_A - 1 )); (( VT_ORIGIN )) && (( y += VT_TOP )) ;;
    H|f)  vt_arg 0 1; (( y = VT_A - 1 ))
          vt_arg 1 1; (( x = VT_A - 1 ))
          if (( VT_ORIGIN )); then (( y += VT_TOP )); (( y > VT_BOT )) && (( y = VT_BOT )); fi ;;
    I)    vt_arg 0 1; vt_tab $VT_A; return 0 ;;
    Z)    vt_arg 0 1; k=$VT_A; (( k > VT_W )) && k=$VT_W
          while (( k-- > 0 )); do
            (( x = VT_X - 1 ))
            while (( x > 0 )) && [[ "${VT_TABS[$x,$x]}" != 'T' ]]; do (( x-- )); done
            (( x < 0 )) && x=0
            VT_X=$x
          done
          VT_WRAPNEXT=0; return 0 ;;
  esac
  if (( VT_ORIGIN )); then
    (( y < VT_TOP )) && (( y = VT_TOP ))
    (( y > VT_BOT )) && (( y = VT_BOT ))
  fi
  (( y < 0 )) && y=0; (( y > VT_H - 1 )) && (( y = VT_H - 1 ))
  (( x < 0 )) && x=0; (( x > VT_W - 1 )) && (( x = VT_W - 1 ))
  VT_X=$x; VT_Y=$y; VT_WRAPNEXT=0
}

# ── CSI ───────────────────────────────────────────────────────────────────
# A PRIVATE CSI IS A DIFFERENT COMMAND, NOT THE SAME ONE WITH A MARK ON IT.
#
# This is the bug the reader actually saw, and it came straight from the
# original, which also reads the final byte and ignores what is in front of
# it.  `CSI ? u` is the kitty keyboard protocol asking what this terminal
# supports; `CSI u` is RESTORE CURSOR.  Claude Code sends `ESC 7` as its very
# first byte and `CSI ? u` a moment later, so the query put the cursor back
# where the save had left it -- the top-left corner -- and everything the
# agent drew after that landed on top of what it had already drawn.  On the
# glass that reads as the question being asked twice, overlapping itself,
# with only one of the two answering the arrow keys.
#
# `CSI ? r` and `CSI ? s` are the same shape of mistake waiting to happen:
# they save and restore DEC PRIVATE MODES, and read as the plain versions
# they would set a scroll region out of a mode number and move the cursor.
# `CSI > m` sets modifier-key options and as plain SGR would repaint the
# screen in whatever colour the number happened to name.
#
# So the marker is looked at FIRST, and anything private this terminal does
# not know is dropped rather than answered by its unmarked namesake.  A
# terminal that does not support the kitty protocol answers nothing at all,
# which is exactly how the agent is supposed to find out.
vt_csi() {   # vt_csi PRIV ARGS FIN
  local priv="$1" args="$2" fin="$3"
  local -i n i keep keep2
  case "$priv" in
    '?') case "$fin" in u|s|r) return 0 ;; esac ;;
    '>'|'='|'<') [[ "$fin" == c ]] || return 0 ;;
  esac
  VT_G=()
  [[ -n "$args" ]] && VT_G=("${(@s.;.)args}")
  case "$fin" in
    m) vt_sgr ;;
    A|B|C|D|E|F|G|H|f|d|\`|a|e|I|Z) vt_move "$fin" ;;
    J) vt_arg 0 0; vt_ed $VT_A ;;
    K) vt_arg 0 0; vt_el $VT_A ;;
    L) if (( VT_Y >= VT_TOP && VT_Y <= VT_BOT )); then
         vt_arg 0 1; n=$VT_A; keep=$VT_TOP; keep2=$VT_BOT
         VT_TOP=$VT_Y; vt_scroll_down $n; VT_TOP=$keep; VT_BOT=$keep2; VT_X=0
       fi ;;
    M) if (( VT_Y >= VT_TOP && VT_Y <= VT_BOT )); then
         vt_arg 0 1; n=$VT_A; keep=$VT_TOP
         VT_TOP=$VT_Y; vt_scroll_up $n; VT_TOP=$keep; VT_X=0
       fi ;;
    P) vt_arg 0 1; n=$VT_A; (( n > VT_W - VT_X )) && (( n = VT_W - VT_X ))
       if (( n > 0 )); then
         local pad='' ppad='' j
         for (( j = 0; j < n; j++ )); do pad+=' '; ppad+="${VT_PCH[-1 -1 0]}"; done
         if (( VT_X > 0 )); then
           VT_CH[$VT_Y]="${VT_CH[$VT_Y][0,VT_X-1]}${VT_CH[$VT_Y][VT_X+n,-1]}$pad"
           VT_PN[$VT_Y]="${VT_PN[$VT_Y][0,VT_X-1]}${VT_PN[$VT_Y][VT_X+n,-1]}$ppad"
         else
           VT_CH[$VT_Y]="${VT_CH[$VT_Y][n,-1]}$pad"
           VT_PN[$VT_Y]="${VT_PN[$VT_Y][n,-1]}$ppad"
         fi
         (( VT_DIRTY++ ))
       fi ;;
    @) vt_arg 0 1; n=$VT_A; (( n > VT_W - VT_X )) && (( n = VT_W - VT_X ))
       if (( n > 0 )); then
         local pad='' j; vt_penrun $n
         for (( j = 0; j < n; j++ )); do pad+=' '; done
         if (( VT_X > 0 )); then
           VT_CH[$VT_Y]="${VT_CH[$VT_Y][0,VT_X-1]}$pad${VT_CH[$VT_Y][VT_X,-1]}"
           VT_PN[$VT_Y]="${VT_PN[$VT_Y][0,VT_X-1]}$VT_PR${VT_PN[$VT_Y][VT_X,-1]}"
         else
           VT_CH[$VT_Y]="$pad${VT_CH[$VT_Y]}"
           VT_PN[$VT_Y]="$VT_PR${VT_PN[$VT_Y]}"
         fi
         VT_CH[$VT_Y]="${VT_CH[$VT_Y][0,VT_W-1]}"
         VT_PN[$VT_Y]="${VT_PN[$VT_Y][0,VT_W-1]}"
         (( VT_DIRTY++ ))
       fi ;;
    X) vt_arg 0 1; vt_erase $VT_Y $VT_X $(( VT_X + VT_A )) ;;
    S) vt_arg 0 1; vt_scroll_up $VT_A ;;
    T) vt_arg 0 1; vt_scroll_down $VT_A ;;
    r) vt_arg 0 1; local -i top=$(( VT_A - 1 )) bot
       local g1="${VT_G[1]:-0}"
       bot=${${g1%%:*}:-0}; (( bot )) && (( bot-- )) || (( bot = VT_H - 1 ))
       if (( top >= 0 && top < bot && bot < VT_H )); then VT_TOP=$top; VT_BOT=$bot
       else VT_TOP=0; (( VT_BOT = VT_H - 1 )); fi
       vt_goto 0 0 ;;
    h) vt_mode 1 $([[ "$priv" == '?' ]] && print 1 || print 0) ;;
    l) vt_mode 0 $([[ "$priv" == '?' ]] && print 1 || print 0) ;;
    s) vt_save_cursor ;;
    u) vt_restore_cursor ;;
    g) vt_arg 0 0
       if (( VT_A == 3 )); then
         VT_TABS=''; for (( i = 0; i < VT_W; i++ )); do VT_TABS+='.'; done
       else
         if (( VT_X > 0 )); then VT_TABS="${VT_TABS[0,VT_X-1]}.${VT_TABS[VT_X+1,-1]}"
         else VT_TABS=".${VT_TABS[1,-1]}"; fi
       fi ;;
    c) if [[ "$priv" == '>' ]]; then vt_answer $'\e[>0;88;0c'
       else vt_answer $'\e[?62;22c'; fi ;;
    n) vt_arg 0 0
       if [[ "$priv" == '?' ]] && (( VT_A == 6 )); then
         vt_answer $'\e[?'"$(( VT_Y + 1 ));$(( VT_X + 1 ))R"
       elif (( VT_A == 6 )); then
         vt_answer $'\e['"$(( VT_Y + 1 ));$(( VT_X + 1 ))R"
       elif (( VT_A == 5 )); then vt_answer $'\e[0n'
       fi ;;
    t) vt_arg 0 0
       case $VT_A in
         18) vt_answer $'\e[8;'"$VT_H;${VT_W}t" ;;
         14) vt_answer $'\e[4;'"$(( VT_H * 20 ));$(( VT_W * 9 ))t" ;;
       esac ;;
    p) [[ "$priv" == '?' ]] && { vt_arg 0 0; vt_answer $'\e[?'"$VT_A;0\$y" } ;;
  esac
}

# ── control characters inside a text run ──────────────────────────────────
# THE FAST LANE IS THE ONE THAT MATTERS.  Almost every run an agent writes
# has no control character in it at all, and that case must cost one test
# and one splice.  When there IS one, the run is cut at it with `%%` -- a
# greedy suffix removal, which lands on the FIRST match and is linear --
# rather than by walking characters, which is not.
# WINDOWED WHEN IT IS LONG.  Finding the next control character and then
# dropping it both scan from the front, so a run that is MOSTLY control
# characters costs O(n) per character -- 32 KB of backspaces measured eight
# seconds.  Cutting the run into fixed windows bounds that scan without
# changing a thing about the result: this path has no escape sequences left
# in it (`vt_feed` split those out) and every character is handled on its
# own, so a window may begin and end anywhere.
vt_ctl() {   # vt_ctl TEXT
  local -i n=${#1} i
  if (( n > 512 )) && [[ "$1" == *[$'\r\n\b\t\a\v\f\x0e\x0f']* ]]; then
    for (( i = 0; i < n; i += 512 )); do vt_ctl1 "${1[$i,$i+511]}"; done
    return 0
  fi
  vt_ctl1 "$1"
}

vt_ctl1() {   # vt_ctl1 TEXT
  local s="$1" head c
  [[ -n "$s" ]] || return 0
  if [[ "$s" != *[$'\r\n\b\t\a\v\f\x0e\x0f']* ]]; then vt_puts "$s"; return 0; fi
  while [[ -n "$s" ]]; do
    head="${s%%[$'\r\n\b\t\a\v\f\x0e\x0f']*}"
    if [[ "$head" == "$s" ]]; then vt_puts "$s"; return 0; fi
    [[ -n "$head" ]] && vt_puts "$head"
    c="${s[${#head},${#head}]}"
    s="${s[${#head}+1,-1]}"
    case "$c" in
      $'\n'|$'\v'|$'\f') vt_lf ;;
      $'\r') vt_cr ;;
      $'\b') if (( VT_WRAPNEXT )); then VT_WRAPNEXT=0
             else (( VT_X > 0 )) && (( VT_X-- )); fi ;;
      $'\t') vt_tab 1 ;;
      $'\a') (( VT_BELL++ )) ;;
      $'\x0e') [[ "$VT_G1" == '0' ]] && VT_GL='0' ;;
      $'\x0f') VT_GL="$VT_G0" ;;
    esac
  done
}

# ── one escape sequence ───────────────────────────────────────────────────
# P is everything after the ESC.  Returns 0 having consumed a sequence and
# left the remaining text in VT_TAIL, or 1 meaning "not all of it has
# arrived" -- in which case the caller puts the whole thing away and waits.
vt_esc() {   # vt_esc P
  local p="$1" c r priv params inter fin
  VT_TAIL=''
  [[ -n "$p" ]] || return 1
  c="${p[0,0]}"
  case "$c" in
    '[')
      r="${p[1,-1]}"
      priv=''
      [[ "$r" == [$'?><!=']* ]] && { priv="${r[0,0]}"; r="${r[1,-1]}" }
      # THE FINAL BYTE, FOUND WITHOUT EXTENDED_GLOB.  `${r%%[!0-9;:]*}` takes
      # the longest suffix that begins with a non-parameter character away,
      # which leaves exactly the parameter run -- and, crucially, is linear.
      # The `#`-repetition spelling this would otherwise want is an
      # EXTENDED_GLOB operator, and this cabinet does not set it: there it
      # would quietly strip nothing at all and every sequence would be text.
      params="${r%%[!0-9;:]*}"
      [[ "$params" == "$r" ]] && return 1          # no final byte yet
      r="${r[${#params},-1]}"
      inter="${r%%[!$' '-$'/']*}"
      [[ "$inter" == "$r" ]] && return 1
      r="${r[${#inter},-1]}"
      fin="${r[0,0]}"
      [[ "$fin" == [$'@'-$'~'] ]] || { VT_TAIL="${r[1,-1]}"; return 0 }
      vt_csi "$priv" "$params" "$fin"
      VT_TAIL="${r[1,-1]}"
      return 0 ;;
    ']'|'P'|'^'|'_'|'X')
      # A STRING SEQUENCE, and its terminator may be the ESC we split on.
      # BEL ends it here; ST (ESC \) ends it in the NEXT part, whose first
      # character is then the backslash and must not be printed.
      if [[ "$p" == *$'\a'* ]]; then
        r="${p%%$'\a'*}"
        [[ "$c" == ']' ]] && vt_osc "${r[1,-1]}"
        VT_TAIL="${p[${#r}+1,-1]}"
        return 0
      fi
      (( ${#p} > 16384 )) && { VT_TAIL=''; return 0 }
      VT_OSCW="${p[1,-1]}"; VT_OSCK="$c"; VT_ST=1
      VT_TAIL=''
      return 0 ;;
    '('|')'|'*'|'+')
      (( ${#p} < 2 )) && return 1
      local g="${p[1,1]}"
      case "$c" in
        '(') VT_G0="$g"; VT_GL="$g" ;;
        ')') VT_G1="$g" ;;
      esac
      VT_TAIL="${p[2,-1]}"; return 0 ;;
    '7') vt_save_cursor ;;
    '8') vt_restore_cursor ;;
    'D') vt_lf ;;
    'E') vt_cr; vt_lf ;;
    'M') vt_ri ;;
    'H') if (( VT_X > 0 )); then VT_TABS="${VT_TABS[0,VT_X-1]}T${VT_TABS[VT_X+1,-1]}"
         else VT_TABS="T${VT_TABS[1,-1]}"; fi ;;
    'c') vt_reset ;;
    '=') VT_APPKEY=1 ;;
    '>') VT_APPKEY=0 ;;
    '#') (( ${#p} < 2 )) && return 1; VT_TAIL="${p[2,-1]}"; return 0 ;;
  esac
  VT_TAIL="${p[1,-1]}"
  return 0
}

# `${s#*;}` IS THE ONE THING THIS FILE TELLS ITSELF NOT TO DO, and it was
# sitting two functions above the comment that says so.  Non-greedy prefix
# removal is quadratic in zsh; the body handed here is an agent's hyperlink
# or window title and is not size-capped on the BEL path, so a 32 KB one
# measured 5.2 seconds and a 64 KB one twenty.  The head is already computed
# on the line above, so its length is the offset to slice from -- linear, and
# measured at 0.3 ms on the same input.
vt_osc() {   # vt_osc BODY
  local s="$1" n rest
  n="${s%%;*}"; rest=''
  [[ "$s" == *';'* ]] && rest="${s[${#n}+1,-1]}"
  case "$n" in
    0|1|2) VT_TITLE="${rest[0,79]}" ;;
  esac
}

# ── the door ──────────────────────────────────────────────────────────────
# SPLIT ON ESC, AND HANDLE EACH PIECE WHOLE.  This is the difference between
# a terminal that keeps up and one that does not: walking the stream a
# character at a time measured 131 KB/s, splitting it measured 4.8 MB/s on
# the same bytes.  Part zero is the text before any escape; every part after
# it begins immediately after one.
#
# `"${(@ps:\e:)data}"` AND NOT `${(ps:\e:)data}`.  Unquoted, that is word
# splitting, and word splitting DROPS EMPTY FIELDS -- so two escapes in a
# row, which is most of what a repaint is, would lose the boundary between
# them and the second would be read as text.
typeset -gi VT_ST=0
typeset -g  VT_OSCW='' VT_OSCK='' VT_TAIL=''

vt_feed() {   # vt_feed DATA
  local data="$1" p p0 head
  local -a parts
  local -i i
  [[ -n "$data" ]] || return 0
  if [[ -n "$VT_BUF" ]]; then data="$VT_BUF$data"; VT_BUF='' ; fi
  parts=("${(@ps:\e:)data}")
  p0="${parts[0]}"
  # PART ZERO IS NOT ALWAYS TEXT.  A string sequence -- an OSC 8 hyperlink,
  # which is how the agent marks a link in its own output -- ends with `ESC \`,
  # and a read can land in the middle of one.  When it does, the bytes that
  # open the NEXT feed are still the sequence's body, and handing them to the
  # text path prints the URL across whatever the agent had drawn.
  if (( VT_ST )); then
    # ...AND THE SEQUENCE CAN END IN THE MIDDLE OF IT.  A BEL is the other
    # way a string sequence finishes, and it is the one the agent's
    # hyperlinks use: `ESC ] 8 ; id=… ; <url> BEL <the text you see> `.  That
    # url is eight hundred characters, so the BEL lands in whatever read
    # happens to be passing -- and appending the whole part to the body,
    # terminator and all, ate the visible text behind it.  Two rows of the
    # sign-in link simply were not there.
    #
    # `%%` AND A SLICE, never `${p#*BEL}`.  Non-greedy prefix removal on a
    # long string is quadratic in zsh -- 64 KB of it measured twenty-seven
    # seconds -- and this is the one path guaranteed to be handed a long one.
    if [[ "$p0" == *$'\a'* ]]; then
      head="${p0%%$'\a'*}"
      VT_OSCW+="$head"
      [[ "$VT_OSCK" == ']' ]] && vt_osc "$VT_OSCW"
      VT_ST=0; VT_OSCW=''; VT_OSCK=''
      vt_ctl "${p0[${#head}+1,-1]}"
    else
      VT_OSCW+="$p0"
      (( ${#VT_OSCW} > 16384 )) && { VT_ST=0; VT_OSCW=''; VT_OSCK='' }
    fi
  else
    vt_ctl "$p0"
  fi
  for (( i = 1; i < ${#parts[@]}; i++ )); do
    p="${parts[$i]}"
    # a string sequence still open: this ESC is its terminator if a `\`
    # follows, and otherwise the sequence was abandoned.
    if (( VT_ST )); then
      VT_ST=0
      if [[ "$p" == '\'* ]]; then
        [[ "$VT_OSCK" == ']' ]] && vt_osc "$VT_OSCW"
        VT_OSCW=''; VT_OSCK=''
        vt_ctl "${p[1,-1]}"
        continue
      fi
      VT_OSCW=''; VT_OSCK=''
    fi
    if ! vt_esc "$p"; then
      # INCOMPLETE, AND PUT AWAY WITH ITS ESC BACK ON.  Only the last part
      # can legitimately be short; anything earlier that does not parse is a
      # sequence this terminal does not know, and dropping it is right.
      # CAPPED, LIKE THE STRING BUFFER IS.  `vt_esc` calls a CSI whose
      # parameter run has not ended yet "incomplete", and a stream of digits
      # with no final byte is never wrong and never finishes -- so this grew
      # by the size of every read, for ever, and was copied into the session
      # snapshot at each save on top of that.
      if (( i == ${#parts[@]} - 1 )); then
        if (( ${#p} > 4096 )); then VT_BUF=''
        else VT_BUF=$'\e'"$p"; fi
      fi
      continue
    fi
    [[ -n "$VT_TAIL" ]] && vt_ctl "$VT_TAIL"
  done
  return 0
}

# ── reading it back ───────────────────────────────────────────────────────
# ONE CALL PER RUN OF ONE COLOUR, not one per cell.  A row is walked by
# comparing pen characters; equal characters mean the same pen, which is the
# whole reason a pen is a character.  What comes out is parallel arrays the
# caller can hand straight to whatever draws.
vt_row_runs() {   # vt_row_runs Y -> VR_X VR_N VR_TXT VR_PEN
  vt_runs_of "${VT_CH[$1]}" "${VT_PN[$1]}"
  return 0
}
vt_runs_cut() {   # vt_runs_cut TEXT PENS -> VR_X VR_N VR_TXT VR_PEN
  local -i i start=0
  local pn="$2" ch="$1" cur
  VR_X=(); VR_N=(); VR_TXT=(); VR_PEN=()
  [[ -n "$pn" ]] || return 0
  cur="${pn[0,0]}"
  for (( i = 1; i <= VT_W; i++ )); do
    if (( i == VT_W )) || [[ "${pn[$i,$i]}" != "$cur" ]]; then
      VR_X+=($start)
      VR_N+=($(( i - start )))
      VR_TXT+=("${${ch[$start,$i-1]}//$VT_CONT/}")
      VR_PEN+=("${VT_PEN[$cur]:--1 -1 0}")
      (( i < VT_W )) && { start=$i; cur="${pn[$i,$i]}" }
    fi
  done
  return 0
}
# THE RUNS ARE REMEMBERED BY THE LINE, NOT BY THE ROW.  Cutting a row into
# runs is a comparison per cell, a millisecond a row; kept against its row
# number that saved the twenty-seven rows that did not change on a typing
# frame, and nothing at all on a scrolling one, where every row is a line
# that was on the row above it a moment ago.  Kept against the line's own
# text and pens, a line that moves is a lookup wherever it lands -- so
# paging back through the past costs the same as standing still.
typeset -gA VT_RUNC
typeset -gi VT_RUNC_N=0
vt_runs_of() {   # vt_runs_of TEXT PENS -> VR_X VR_N VR_TXT VR_PEN
  local key="$1"$'\x1e'"$2" got
  local -a f
  got="${VT_RUNC[$key]:-}"
  if [[ -n "$got" ]]; then
    f=("${(@ps.\x1f.)got}")
    VR_X=(${=f[0]}); VR_N=(${=f[1]})
    VR_TXT=("${(@ps.\x1e.)f[2]}"); VR_PEN=("${(@ps.\x1e.)f[3]}")
    return 0
  fi
  vt_runs_cut "$1" "$2"
  (( ${#VR_X[@]} )) || return 0
  (( VT_RUNC_N++ > 4000 )) && { VT_RUNC=(); VT_RUNC_N=0 }
  VT_RUNC[$key]="${(j: :)VR_X[@]}"$'\x1f'"${(j: :)VR_N[@]}"$'\x1f'"${(pj.\x1e.)VR_TXT[@]}"$'\x1f'"${(pj.\x1e.)VR_PEN[@]}"
  return 0
}

vt_take_reply() { VT_OUT="$VT_REPLY"; VT_REPLY=''; }
# ══════════════════════════════════════════════════════════════════════════
# AN AGENT ASKS FOR "RED" AND GETS THIS MACHINE'S RED
#
# The cube and the grey ramp underneath are xterm's own numbers, because a
# program that computes a colour out of the 6x6x6 cube is computing a
# specific colour and has every right to it.  Only the sixteen a program
# NAMES are re-pointed, and they are re-pointed at the palette the rest of
# the glass is painted in -- so an agent's output sits in the picture
# instead of on top of it.
typeset -ga VT_XT
typeset -gA VT_INKC
typeset -gi VT_IF=-1 VT_IB=-1 VT_RGB=0
typeset -gi VT_FGD=0 VT_BGD=0 VT_WHITE=0 VT_CYAN=0 VT_GREY=0

vt_palette() {
  (( ${#VT_XT[@]} )) && return 0
  local -a a16 cube
  a16=( 12 8 24      255 74 92    96 255 168   255 186 62
        108 128 255  255 42 168   60 240 255   198 192 224
        98 92 124    255 128 140  168 255 208  255 214 128
        158 172 255  255 122 200  150 250 255  238 232 255 )
  local -i i r g b v
  VT_XT=()
  for (( i = 0; i < 16; i++ )); do
    _pack ${a16[$((i*3))]} ${a16[$((i*3+1))]} ${a16[$((i*3+2))]}; VT_XT+=($PK)
  done
  cube=(0 95 135 175 215 255)
  for r in "${cube[@]}"; do for g in "${cube[@]}"; do for b in "${cube[@]}"; do
    _pack $r $g $b; VT_XT+=($PK)
  done; done; done
  for (( i = 0; i < 24; i++ )); do v=$(( 8 + i * 10 )); _pack $v $v $v; VT_XT+=($PK); done
  _pack 206 226 244; VT_FGD=$PK
  _pack   8   4  20; VT_BGD=$PK
  _pack 238 232 255; VT_WHITE=$PK
  _pack  60 240 255; VT_CYAN=$PK
  _pack 128 116 158; VT_GREY=$PK
  VT_INKC=()
  return 0
}

vt_rgb() {   # vt_rgb C ISFG FLAGS -> VT_RGB
  local -i c=$1 isfg=$2 fl=$3
  if (( c == -1 )); then
    VT_RGB=$VT_BGD
    if (( isfg )); then
      VT_RGB=$VT_FGD
      (( fl & VT_BOLD )) && { cmix $VT_FGD $VT_WHITE 0.45; VT_RGB=$CM }
    fi
    return 0
  fi
  if (( c >= VT_TRUE )); then
    _pack $(( (c >> 16) & 255 )) $(( (c >> 8) & 255 )) $(( c & 255 )); VT_RGB=$PK
    return 0
  fi
  # THE OLD BRIGHT-BOLD BARGAIN, KEPT.  Bold on one of the low eight has
  # meant "the bright one" since terminals had eight colours, and a program
  # written any time in the last forty years is relying on it.
  (( isfg && (fl & VT_BOLD) && c < 8 )) && (( c += 8 ))
  (( c >= 0 && c < 256 )) && VT_RGB=${VT_XT[$c]} || VT_RGB=$VT_FGD
  return 0
}

# WORKED OUT ONCE PER PEN AND KEPT.  A screen has a few dozen distinct pens
# on it and sixty thousand cells; doing this per cell would be the whole
# frame budget spent on arithmetic nobody asked to repeat.
vt_ink() {   # vt_ink "C B FL" -> VT_IF VT_IB
  local key="$1" got="${VT_INKC[$1]:-}"
  if [[ -n "$got" ]]; then VT_IF=${got%% *}; VT_IB=${got##* }; return 0; fi
  local -a f; f=(${=key})
  local -i c=${f[0]} b=${f[1]} fl=${f[2]} fg bg t
  vt_rgb $c 1 $fl; fg=$VT_RGB
  vt_rgb $b 0 $fl; bg=$VT_RGB
  (( fl & VT_DIM ))  && { cmix $bg $fg 0.55; fg=$CM }
  (( fl & VT_UL ))   && { cmix $fg $VT_CYAN 0.30; fg=$CM }   # no underline in a cell: tint it
  (( fl & VT_STRK )) && { cmix $fg $VT_GREY 0.35; fg=$CM }
  (( fl & VT_REV ))  && { t=$fg; fg=$bg; bg=$t }
  (( fl & VT_HIDE )) && fg=$bg
  (( ${#VT_INKC[@]} > 4096 )) && VT_INKC=()
  VT_INKC[$key]="$fg $bg"
  VT_IF=$fg; VT_IB=$bg
  return 0
}

# ── painting it into the glass ────────────────────────────────────────────
# ROWS THAT DID NOT CHANGE ARE NOT READ BACK AT ALL.  Turning the whole grid
# into runs measured 21 ms; comparing two strings per row and skipping the
# ones that match costs almost nothing, and on a typing frame exactly one
# row has changed.  FORCE is for the frame after the cabinet has thrown the
# picture away, when what is on the glass is no longer what was drawn.
typeset -ga VT_LCH VT_LPN
typeset -gi GT_DEAD=0 VT_SHOWN=0
vt_draw() {   # vt_draw X0 Y0 [FORCE]
  # THE CABINET CLEARS ITS CANVAS EVERY FRAME, so every row is painted every
  # frame; what is saved is the cutting of a row into runs, which vt_runs_of
  # remembers by the line.  FORCE is kept for the callers that pass it and
  # changes nothing: there is no longer a row that is not painted.
  #
  # THE VIEW IS THE PAST AND THEN THE GRID.  With VT_VIEW at n the top n rows
  # are the last n lines that left the screen and the rest is the grid from
  # its own top row, cut off at the bottom -- which is what a terminal shows
  # when its scrollbar is dragged up, and it is the grid itself when n is 0.
  local -i x0=$1 y0=$2 y k sb=$VT_VIEW s0
  (( sb > VT_SB_N )) && sb=$VT_SB_N
  (( sb < 0 )) && sb=0
  VT_SHOWN=$sb
  s0=$(( VT_SB_N - sb ))
  for (( y = 0; y < VT_H; y++ )); do
    if (( y < sb )); then vt_runs_of "${VT_SB_CH[$(( s0 + y ))]}" "${VT_SB_PN[$(( s0 + y ))]}"
    else                  vt_runs_of "${VT_CH[$(( y - sb ))]}" "${VT_PN[$(( y - sb ))]}"; fi
    for (( k = 0; k < ${#VR_X[@]}; k++ )); do
      vt_ink "${VR_PEN[$k]}"
      # A DEAD SESSION IS DIMMED.  The last screen stays up to be read, and
      # the ink is pulled back toward the ground so it does not look like a
      # screen you can still type at.
      if (( GT_DEAD )); then cmix $VT_IB $VT_IF 0.55; VT_IF=$CM; fi
      v_text $(( x0 + VR_X[$k] )) $(( y0 + y )) "${VR_TXT[$k]}" $VT_IF $VT_IB
    done
  done
  return 0
}
# ══════════════════════════════════════════════════════════════════════════
# THE AGENT RUNS INSIDE THE PICTURE
#
# A session is a pty, a process on the end of it, and a Vt reading what comes
# back.  The cabinet keeps the window the whole time: the raster stays up,
# the neon stays on, the coin door still says what the machine is doing, and
# the agent lives in the middle of it.
#
# `zsh/zpty` IS THE PTY, AND PERL IS THE ONLY REASON IT IS THE RIGHT SIZE.
# zpty gives a real controlling terminal -- `[ -t 0 ]` says yes, ^C becomes
# SIGINT, and every one of these tools draws a different, worse screen when
# it thinks it is being piped -- but it leaves the window size at 0x0, and
# `stty rows … columns …` on that pty RETURNS SUCCESS AND DOES NOTHING.  A
# full-screen agent then falls back to 80x24 and paints outside the glass.
# zsh has no ioctl; perl does, and perl is already what `in_ver` uses to put
# a time limit on a stranger's --version.  So the child is perl, perl sets
# TIOCSWINSZ on the terminal it was handed, and then execs the agent.
#
# THE SIZE IS TAKEN FROM THE GLASS, not from the window the cabinet is in.
# They are different numbers -- the glass is inside a frame -- and an agent
# told the outer one draws a screen that does not fit.

typeset -g  SS_NAME='' SS_CMD='' SS_CWD='' SS_ERR='' SS_PTY=''
typeset -gi SS_LIVE=0 SS_W=0 SS_H=0 SS_T0=0 SS_RC=-1
typeset -g  SS_HELPER=''

# The helper is written once, beside the other short-lived files, and is
# removed with them.  It is NOT kept in the repo: a file that sets the size
# of a terminal and then execs whatever it was given is a thing to create
# with mktemp and own for one session, not to leave lying about with a
# predictable name in a directory anybody can write to.
ss_helper() {
  [[ -n "$SS_HELPER" && -r "$SS_HELPER" ]] && return 0
  # `gt_tmp` AND NOT A BARE MKTEMP.  The cabinet already has a function whose
  # whole job is making a short-lived file and putting it on the list that
  # gets swept when the cabinet goes down; making one here by hand meant
  # remembering to do the second half, and a file that sets the size of a
  # terminal and then execs what it was handed is not one to leave in /tmp.
  gt_tmp alien-winsz || return 1
  cat >"$GTMP" <<'PL'
my ($w, $h) = (shift, shift);
my $op = ($^O eq 'darwin') ? 0x80087467 : 0x5414;
ioctl(STDIN, $op, pack('S4', $h, $w, $w * 9, $h * 20));
# `exec { $ARGV[0] } @ARGV` AND NOT `exec @ARGV`.  With one element, plain
# exec looks for shell metacharacters and, finding any, hands the whole
# string to /bin/sh -c.  An agent at a path with a SPACE in it -- `~/My
# Tools/claude` -- was split on the space, failed to exec, and died silently
# behind a session that reported success.  A path containing `$(...)` ran as
# shell code.  The indirect-object form names the file to run and passes the
# list as argv, and never involves a shell.
exec { $ARGV[0] } @ARGV;
PL
  SS_HELPER="$GTMP"
  return 0
}

ss_start() {   # ss_start NAME CMD CWD W H
  local nm="$1" cmd="$2" cwd="$3"
  local -i w=$4 h=$5
  SS_ERR=''; SS_RC=-1
  zmodload zsh/zpty 2>/dev/null || { SS_ERR='this zsh has no zpty'; return 1 }
  ss_helper || { SS_ERR='no temp file for the size helper'; return 1 }
  [[ -d "$cwd" ]] || cwd="$HOME"
  SS_NAME="$nm"; SS_CMD="$cmd"; SS_CWD="$cwd"; SS_W=$w; SS_H=$h
  # A NAME PER SESSION, NOT PER PROCESS.  This was `alien$$`, which is the
  # same string for every agent the cabinet ever opens -- and `zpty` refuses
  # a duplicate name.  So the second agent could never start, and the whole
  # of the registry below it (save, load, swap, round-robin drain) was
  # unreachable code protecting a case that could not happen.
  (( GT_SEQ++ ))
  SS_PTY="alien$$-$GT_SEQ"
  vt_init $w $h
  # ONE PRE-QUOTED COMMAND LINE, AND NOT A LIST OF WORDS.  `zpty` JOINS its
  # arguments with spaces and re-parses the result as a shell command line,
  # so every quote put around a word by the caller is gone before a shell
  # ever sees it: `zpty n zsh -c "cd /x && run"` runs `zsh -c cd` with `/x`
  # as its argument and then runs `&& run` somewhere else entirely.  That is
  # why the agent started in the cabinet's directory, with the cabinet's
  # TERM, no matter what was passed.  Everything therefore goes in as one
  # string, quoted so that the re-parse puts it back exactly.
  #
  # LINES and COLUMNS as well as the ioctl: a few tools read the environment
  # and never ask the kernel, and the two must agree or the agent paints to
  # one size and is measured by the other.
  local line
  line="cd ${(qq)cwd} && exec env TERM=xterm-256color COLORTERM=truecolor"
  line+=" LINES=$h COLUMNS=$w ALIEN_GLASS=1 ALIEN_INTELLIGENCE=1"
  line+=" perl ${(qq)SS_HELPER} $w $h $cmd"
  zpty -b "$SS_PTY" "$line" 2>/dev/null || { SS_ERR='zpty would not start'; return 1 }
  SS_LIVE=1
  SS_T0=$EPOCHSECONDS
  return 0
}

# READ WHATEVER IS THERE, AND DO NOT WAIT FOR MORE.  `-t` makes the read
# non-blocking; without it the whole cabinet would stop between the agent's
# keystrokes.  Several reads per call because one read returns one chunk and
# a repaint arrives as many.
ss_pump() {   # ss_pump -> how many bytes were fed
  local c
  local -i got=0 n=0
  (( SS_LIVE )) || return 0
  while (( n++ < 64 )); do
    c=''
    zpty -rt "$SS_PTY" c 2>/dev/null || break
    [[ -n "$c" ]] || break
    vt_feed "$c"
    (( got += ${#c} ))
  done
  # has it gone?
  if ! zpty -t "$SS_PTY" 2>/dev/null; then
    SS_LIVE=0
  fi
  # anything the terminal owes the agent goes back up the pty
  vt_take_reply
  [[ -n "$VT_OUT" ]] && zpty -w -n "$SS_PTY" "$VT_OUT" 2>/dev/null
  return 0
}

ss_write() {   # ss_write TEXT
  (( SS_LIVE )) || return 1
  zpty -w -n "$SS_PTY" "$1" 2>/dev/null
  return 0
}

ss_stop() {
  [[ -n "$SS_PTY" ]] || return 0
  zpty -d "$SS_PTY" 2>/dev/null
  SS_LIVE=0; SS_PTY=''
  return 0
}
# ══════════════════════════════════════════════════════════════════════════
# THE KEYBOARD, WHILE AN AGENT HAS IT
#
# Attached, every key belongs to the agent -- letters, arrows, ^C, all of it.
# The one key this machine keeps is ^], which is the key telnet has meant
# "come back" with since 1983, and which no full-screen tool binds.
#
# Three things are not passed through untouched:
#
#   ^Z, because there is no shell under this to bring the job back.  A
#   stopped agent inside a cabinet is an agent you cannot reach, so it is
#   swallowed.
#
#   The arrows, when the agent has asked for application cursor keys.  The
#   real terminal upstairs is not in that mode and never will be, so the
#   translation happens here, which is the only place that knows both
#   answers.
#
#   The mouse, whose coordinates are counted from the corner of the reader's
#   window and have to be counted from the corner of the glass instead.

typeset -g  KB_DETACH=$'\x1d'
typeset -gi KB_BACK=0
typeset -g  KB_OUT=''

# CSI A becomes SS3 A, and so on, for an agent in application mode.
kb_to_app() {   # kb_to_app S -> KB_OUT
  local s="$1" o='' c
  local -i i n=${#s}
  for (( i = 0; i < n; i++ )); do
    if [[ "${s[$i,$i+1]}" == $'\e[' ]] && (( i + 2 < n )) \
       && [[ "${s[$i+2,$i+2]}" == [ABCDHF] ]]; then
      o+=$'\eO'"${s[$i+2,$i+2]}"
      (( i += 2 ))
    else
      o+="${s[$i,$i]}"
    fi
  done
  KB_OUT="$o"
}

# Mouse reports, moved from the reader's window into the agent's grid.  A
# click that misses the screen is DROPPED rather than clamped: an agent told
# about a click on its edge that happened on the cabinet's frame will act on
# it, and the reader did not click the thing that then happened.
kb_mouse() {   # kb_mouse S OX OY -> KB_OUT
  local s="$1" o='' rest head
  local -i ox=$2 oy=$3 b cx cy
  local ud
  if (( ! VT_MOUSE )); then
    # not wanted: take the reports out rather than let them through as text
    while [[ "$s" == *$'\e[<'* ]]; do
      head="${s%%$'\e[<'*}"; o+="$head"
      rest="${s[${#head}+3,-1]}"
      [[ "$rest" == *[Mm]* ]] || { s=''; break }
      local body="${rest%%[Mm]*}"
      s="${rest[${#body}+1,-1]}"
    done
    KB_OUT="$o$s"; return 0
  fi
  while [[ "$s" == *$'\e[<'* ]]; do
    head="${s%%$'\e[<'*}"; o+="$head"
    rest="${s[${#head}+3,-1]}"
    [[ "$rest" == *[Mm]* ]] || { s=''; break }
    local body="${rest%%[Mm]*}"
    ud="${rest[${#body},${#body}]}"
    # `+1`, NOT `+2`.  The line above proves where the terminator is:
    # `rest[${#body}]` IS the M or the m, so the next unconsumed byte is the
    # one after it.  Skipping two ate whatever the reader typed in the same
    # read as a click -- and in a drag, where reports arrive several to a
    # read, it ate the ESC off the front of the next one, so that report went
    # through to the agent as literal text in its prompt.
    s="${rest[${#body}+1,-1]}"
    local -a f; f=("${(@s.;.)body}")
    # EVERY FIELD CHECKED FOR BEING A NUMBER, not just the field count.  These
    # three are `local -i`, and assigning a non-numeric string to an integer
    # evaluates it as MATH -- where an unknown name, under this cabinet's
    # `set -u`, is not an error to handle but the shell exiting.  Pasting a
    # captured terminal transcript into an attached agent was enough to take
    # the whole window down mid-frame.
    if (( ${#f[@]} == 3 )) && [[ "${f[0]}" == <-> && "${f[1]}" == <-> && "${f[2]}" == <-> ]]; then
      b=${f[0]}; (( cx = ${f[1]} - 1 - ox )); (( cy = ${f[2]} - 1 - oy ))
      if (( cx >= 0 && cx < VT_W && cy >= 0 && cy < VT_H )); then
        o+=$'\e[<'"$b;$(( cx + 1 ));$(( cy + 1 ))$ud"
      fi
    fi
  done
  KB_OUT="$o$s"
}

# EVERYTHING THE READER TYPED, WHILE A SESSION HAS THE KEYBOARD.
# Sets KB_BACK when the machine should take the keyboard back.
# A MOUSE REPORT CAN ARRIVE IN TWO PIECES, and half of one is not text.
# The report is `ESC [ < b ; x ; y M`, the reader's terminal writes it
# whenever the pointer moves, and a read can land in the middle -- at which
# point the tail turned up in the next read with no `ESC [ <` in front of it
# and went through to the agent as though it had been typed into its prompt.
# Held here until the terminator arrives, and dropped if it never does.
typeset -g KB_CARRY=''
kb_feed() {   # kb_feed RAW OX OY
  local raw="$1" tail
  local -i ox=$2 oy=$3
  KB_BACK=0
  if [[ -n "$KB_CARRY" ]]; then raw="$KB_CARRY$raw"; KB_CARRY='' ; fi
  [[ -n "$raw" ]] || return 0
  if [[ "$raw" == *$'\e[<'* ]]; then
    tail="${raw##*$'\e[<'}"
    if [[ "$tail" != *[Mm]* ]] && (( ${#tail} < 32 )); then
      KB_CARRY=$'\e[<'"$tail"
      raw="${raw[0,${#raw}-${#KB_CARRY}-1]}"
      [[ -n "$raw" ]] || return 0
    fi
  fi
  if [[ "$raw" == *"$KB_DETACH"* ]]; then
    raw="${raw%%$KB_DETACH*}"
    KB_BACK=1
  fi
  raw="${raw//$'\x1a'/}"                     # ^Z has nowhere to go
  [[ -n "$raw" ]] || return 0
  kb_mouse "$raw" $ox $oy; raw="$KB_OUT"
  [[ -n "$raw" ]] || return 0
  (( SS_LIVE )) || return 0
  # A KEY BRINGS THE LIVE GRID BACK.  Whatever the reader was looking at in
  # the past, what they typed goes to the program's present, and the glass
  # shows where it went.
  VT_VIEW=0
  if (( VT_APPCUR )); then kb_to_app "$raw"; raw="$KB_OUT"; fi
  # A PASTE ARRIVES AS ONE BIG READ.  An agent that asked for brackets gets
  # them, so a pasted newline does not send the message early -- which is
  # the difference between pasting a plan and sending its first line.
  # A PASTE WITH COLOUR IN IT IS STILL A PASTE.  This also required the text
  # to contain no ESC at all, which excluded exactly the thing people paste
  # into an agent most often -- a compiler error, a coloured diff, test
  # output -- and those went in unbracketed, so the agent submitted on the
  # first line and typed the rest into the next prompt.  A burst that BEGINS
  # with an escape is a key sequence, not a paste, and is still left alone.
  if (( VT_PASTE )) && (( ${#raw} >= 16 )) \
     && [[ "$raw" == *[$'\n\r']* && "$raw" != $'\e'* ]]; then
    raw=$'\e[200~'"$raw"$'\e[201~'
  fi
  ss_write "$raw"
  return 0
}
# ══════════════════════════════════════════════════════════════════════════
# THE SESSIONS, AND WHICH ONE HAS THE KEYBOARD
# ══════════════════════════════════════════════════════════════════════════
# `shell_open` in the original is one sentence: "Start one, or step back into
# the one already running under that name."  Several can be running at once
# -- CLAUDE CODE left thinking while CODEX is asked something -- and only one
# of them has the keyboard and the glass.
#
# ONE TERMINAL'S WORTH OF STATE IS GLOBAL HERE, because that is what the
# emulator is written against and the emulator is the hot path.  So stepping
# between sessions SWAPS: everything the standing one has goes into its slot,
# and the one being stepped into comes out of its own.  The two grids are
# stored WITHOUT a separator -- every row is exactly VT_W characters and
# there are exactly VT_H of them, so the join is reversible by arithmetic
# and there is no byte a cell could hold that would break it.

typeset -gA GT_S            # key.field -> value, for every live session
typeset -ga GT_K            # the keys, in the order they were opened
typeset -g  GT_AT=''       # which one has the keyboard, '' for none
typeset -gi GT_SEQ=0
typeset -gi GT_X=0 GT_Y=2 GT_W=0 GT_H=0

gt_geom() { GT_W=$SCR_W; (( GT_H = SCR_H - 2 )) }

# what one terminal is, in the order it is written down and read back
typeset -ga GT_F
GT_F=(X Y TOP BOT WRAPNEXT WRAP ORIGIN INSERT CURS ALT SAVED SORG
         SX SY AX AY ATOP ABOT BELL MOUSE PASTE APPCUR APPKEY DIRTY)

gt_save() {   # gt_save KEY
  local k="$1" f
  [[ -n "$k" ]] || return 0
  GT_S[$k.ch]="${(j::)VT_CH[@]}"
  GT_S[$k.pn]="${(j::)VT_PN[@]}"
  GT_S[$k.ach]="${(j::)VT_ACH[@]}"
  GT_S[$k.apn]="${(j::)VT_APN[@]}"
  for f in "${GT_F[@]}"; do GT_S[$k.$f]="${(P)${:-VT_$f}}"; done
  GT_S[$k.P]="$VT_P";    GT_S[$k.SP]="$VT_SP";  GT_S[$k.AP]="$VT_AP"
  GT_S[$k.GL]="$VT_GL";  GT_S[$k.G0]="$VT_G0";  GT_S[$k.G1]="$VT_G1"
  GT_S[$k.SGL]="$VT_SGL"; GT_S[$k.BUF]="$VT_BUF"
  GT_S[$k.TABS]="$VT_TABS"; GT_S[$k.TITLE]="$VT_TITLE"
  GT_S[$k.REPLY]="$VT_REPLY"; GT_S[$k.ST]="$VT_ST"
  GT_S[$k.OSCW]="$VT_OSCW"; GT_S[$k.OSCK]="$VT_OSCK"
  GT_S[$k.pty]="$SS_PTY"; GT_S[$k.live]="$SS_LIVE"
  # the past goes with it, and how far back the reader was looking
  GT_S[$k.sbn]="$VT_SB_N"; GT_S[$k.view]="$VT_VIEW"
  if (( VT_SB_N )); then
    GT_S[$k.sbch]="${(pj.\x1f.)VT_SB_CH[@]}"; GT_S[$k.sbpn]="${(pj.\x1f.)VT_SB_PN[@]}"
  else
    GT_S[$k.sbch]=''; GT_S[$k.sbpn]=''
  fi
  return 0
}

gt_load() {   # gt_load KEY
  local k="$1" f blob
  local -i y
  [[ -n "$k" ]] || return 0
  gt_geom
  VT_W=$GT_W; VT_H=$GT_H
  blob="${GT_S[$k.ch]:-}"; VT_CH=()
  for (( y = 0; y < VT_H; y++ )); do VT_CH+=("${blob[y*VT_W,(y+1)*VT_W-1]}"); done
  blob="${GT_S[$k.pn]:-}"; VT_PN=()
  for (( y = 0; y < VT_H; y++ )); do VT_PN+=("${blob[y*VT_W,(y+1)*VT_W-1]}"); done
  blob="${GT_S[$k.ach]:-}"; VT_ACH=()
  if [[ -n "$blob" ]]; then
    for (( y = 0; y < VT_H; y++ )); do VT_ACH+=("${blob[y*VT_W,(y+1)*VT_W-1]}"); done
  fi
  blob="${GT_S[$k.apn]:-}"; VT_APN=()
  if [[ -n "$blob" ]]; then
    for (( y = 0; y < VT_H; y++ )); do VT_APN+=("${blob[y*VT_W,(y+1)*VT_W-1]}"); done
  fi
  for f in "${GT_F[@]}"; do : ${(P)${:-VT_$f}::=${GT_S[$k.$f]:-0}}; done
  VT_P="${GT_S[$k.P]:-}";    VT_SP="${GT_S[$k.SP]:-}"; VT_AP="${GT_S[$k.AP]:-}"
  VT_GL="${GT_S[$k.GL]:-B}"; VT_G0="${GT_S[$k.G0]:-B}"; VT_G1="${GT_S[$k.G1]:-B}"
  VT_SGL="${GT_S[$k.SGL]:-B}"; VT_BUF="${GT_S[$k.BUF]:-}"
  VT_TABS="${GT_S[$k.TABS]:-}"; VT_TITLE="${GT_S[$k.TITLE]:-}"
  VT_REPLY="${GT_S[$k.REPLY]:-}"; VT_ST=${GT_S[$k.ST]:-0}
  VT_OSCW="${GT_S[$k.OSCW]:-}"; VT_OSCK="${GT_S[$k.OSCK]:-}"
  SS_PTY="${GT_S[$k.pty]:-}"; SS_LIVE=${GT_S[$k.live]:-0}
  SS_NAME="${GT_S[$k.name]:-}"; SS_CWD="${GT_S[$k.cwd]:-}"
  SS_T0=${GT_S[$k.t0]:-0}
  VT_SB_N=${GT_S[$k.sbn]:-0}; VT_VIEW=${GT_S[$k.view]:-0}
  if (( VT_SB_N )); then
    VT_SB_CH=("${(@ps.\x1f.)GT_S[$k.sbch]}"); VT_SB_PN=("${(@ps.\x1f.)GT_S[$k.sbpn]}")
    (( ${#VT_SB_CH[@]} == VT_SB_N && ${#VT_SB_PN[@]} == VT_SB_N )) || { VT_SB_CH=(); VT_SB_PN=(); VT_SB_N=0; VT_VIEW=0 }
  else
    VT_SB_CH=(); VT_SB_PN=(); VT_VIEW=0
  fi
  VT_LCH=(); VT_LPN=()               # what is on the glass is not this one
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# STARTING ONE, OR STEPPING BACK INTO THE ONE ALREADY RUNNING
# ══════════════════════════════════════════════════════════════════════════
# The original's sentence, kept: "Start one, or step back into the one
# already running under that name."  ⏎ on an agent that is already up does
# not start a second copy of it -- it puts you back where you were.

gt_live() {   # gt_live KEY -> 0 if that session is up
  local k="$1"
  [[ -n "${GT_S[$k.pty]:-}" ]] || return 1
  (( ${GT_S[$k.live]:-0} )) || return 1
  return 0
}

# AND FORGETTING ONE RELEASES ITS PTY.
#
# `zpty` keeps a finished command in its table -- `(finished) alien123: …` --
# and keeps the NAME claimed with it.  Nothing here called `zpty -d` on the
# path where a session ends and the reader presses a key to clear it, so the
# name leaked.  Combined with the single shared name above, that meant the
# FIRST agent to exit locked the machine out of ever starting another one
# for the rest of the session: ⏎ answered `it would not start` for ever, and
# only quitting the cabinet fixed it.  Done here, once, because this is the
# one function every path that loses a session goes through.
gt_forget() {   # gt_forget KEY
  local k="$1" f pty="${GT_S[$k.pty]:-}"
  [[ -n "$pty" ]] && zpty -d "$pty" 2>/dev/null
  GT_K=("${(@)GT_K[@]:#$k}")
  for f in ch pn ach apn P SP AP GL G0 G1 SGL BUF TABS TITLE REPLY ST OSCW \
           OSCK pty live name cmd cwd note t0 rc sbn view sbch sbpn "${(@)GT_F[@]}"; do
    unset "GT_S[$k.$f]" 2>/dev/null
  done
  return 0
}

# ── THE KEYBOARD CHANGES HANDS, AND SO DOES THE TTY'S OWN MODE ────────────
# The cabinet runs the terminal in CBREAK: keys arrive one at a time, but
# the driver still reads them -- ^C is a SIGINT, ^Z a SIGTSTP, ^S and ^Q are
# flow control.  That is right for a picture with no text field in it and
# exactly wrong for an agent, which is owed those bytes: ^C is how you stop
# what it is doing, and delivered as a signal it stops the CABINET instead,
# taking the agent down with the window.
#
# So the mode goes fully raw for as long as an agent has the keyboard, and
# comes back to whatever it was the moment it does not.  Saved and restored
# by `stty -g` rather than by naming the flags again, because the mode this
# has to return to is the one the cabinet chose, not the one this file
# happens to know about.
GT_TTY=''
gt_raw() {   # gt_raw 1|0
  [[ -t 0 ]] || return 0
  if (( $1 )); then
    [[ -n "$GT_TTY" ]] && return 0
    GT_TTY="$( { stty -g </dev/tty } 2>/dev/null )" || GT_TTY=''
    # `-icrnl` IS THE ONE THAT MATTERS, and leaving it out is why ⏎ did
    # nothing at all.  The RETURN key sends a CARRIAGE RETURN; the line
    # discipline, with icrnl on, hands the reader a LINE FEED instead.  The
    # cabinet never notices -- its own key loop answers to either -- but an
    # agent is waiting for \r specifically, and \n is not it.  Every other key
    # worked, which is exactly what made it look like the keyboard was fine.
    #
    # The rest is the rest of what `tty.setraw` does, which is what the
    # original called here: nothing between the keyboard and the agent may
    # translate, strip, swallow or signal on a byte.  OPOST is deliberately
    # NOT cleared -- that is the OUTPUT side, and the cabinet is still the one
    # drawing.
    { stty -icrnl -inlcr -igncr -istrip -brkint -inpck \
           -isig -ixon -ixoff -iexten min 1 time 0 </dev/tty } 2>/dev/null || true
  else
    [[ -n "$GT_TTY" ]] || return 0
    { stty "$GT_TTY" </dev/tty } 2>/dev/null || true
    GT_TTY=''
  fi
  return 0
}

# THROUGH THE RASTER, like every other change of surface on this machine.
# ── stepping in, and stepping out ─────────────────────────────────────────
# THE VIEW IS THE SURFACE'S.  Attaching puts a session on the keyboard and
# loads its terminal; which page the surface turns to is the surface's own
# business, done by the caller once this returns.
gt_attach() {   # gt_attach KEY
  [[ -n "$GT_AT" ]] && gt_save "$GT_AT"
  GT_AT="$1"
  gt_load "$1"
  GT_FORCE=1
  gt_raw 1
  return 0
}

gt_detach() {   # the keyboard back · the session keeps running
  [[ -n "$GT_AT" ]] || return 0
  gt_raw 0
  gt_save "$GT_AT"
  GT_AT=''
  return 0
}

# A SESSION THE READER HAS FINISHED READING: forgotten if it has ended,
# detached if it has not.  -> 0 forgotten · 1 detached, still running
gt_done() {
  local k="$GT_AT"
  if [[ -n "$k" ]] && ! gt_live "$k"; then
    gt_raw 0
    gt_save "$k"; gt_forget "$k"
    GT_AT=''
    return 0
  fi
  gt_detach
  return 1
}

# gt_open KEY NAME CMD CWD [NOTE] -> 0 on the keyboard (GT_BACK says it was
# already running and was stepped back into) · 1 would not start, SS_ERR why
typeset -gi GT_BACK=0
gt_open() {
  local k="$1" nm="$2" cmd="$3" cwd="$4" note="${5:-}"
  GT_BACK=0
  if gt_live "$k"; then gt_attach "$k"; GT_BACK=1; return 0; fi
  [[ -n "$k" ]] && gt_forget "$k"
  gt_geom
  [[ -n "$GT_AT" ]] && gt_save "$GT_AT"
  GT_AT=''
  ss_start "$nm" "$cmd" "$cwd" $GT_W $GT_H || return 1
  GT_S[$k.name]="$nm"; GT_S[$k.cmd]="$cmd"
  GT_S[$k.cwd]="$cwd"; GT_S[$k.note]="$note"
  GT_S[$k.t0]="$EPOCHSECONDS"; GT_S[$k.rc]=''
  GT_K+=("$k")
  gt_save "$k"
  GT_AT="$k"
  GT_FORCE=1
  gt_raw 1
  return 0
}

gt_close() {   # gt_close KEY
  local k="$1" keep="$GT_AT"
  gt_live "$k" || { gt_forget "$k"; return 0 }
  [[ -n "$keep" ]] && gt_save "$keep"
  gt_load "$k"
  ss_stop
  gt_forget "$k"
  [[ -n "$keep" && "$keep" != "$k" ]] && gt_load "$keep"
  [[ "$keep" == "$k" ]] && GT_AT=''
  return 0
}

gt_all_stop() {
  local k
  for k in "${(@)GT_K[@]}"; do gt_close "$k"; done
  GT_K=(); GT_AT=''
  return 0
}

# ── THE READER, ONCE A FRAME ──────────────────────────────────────────────
# The session on the keyboard is pumped every frame.  The others are pumped
# ONE PER FRAME, round robin -- not because their output matters while
# nobody is looking, but because a pty nobody reads FILLS, and a program
# whose pty is full is a program blocked mid-sentence on a write.
#
# THE OTHERS ARE ASKED BEFORE THEY ARE SWAPPED IN.  Swapping a terminal in
# and out is two joins of its grid and its past; a pty with nothing to say
# is one failed read, so that read comes first and the swap is only paid
# by a session that actually wrote something.
typeset -gi GT_RR=0
gt_pump() {
  local k keep pty c
  if [[ -n "$GT_AT" ]]; then
    ss_pump
    GT_S[$GT_AT.live]="$SS_LIVE"
    # RAW MODE BELONGS TO WHOEVER IS LISTENING.  The last screen stays up to
    # be read, but the instant the program is gone the keyboard is the
    # cabinet's again -- and the cabinet needs ^C to mean ^C.
    (( SS_LIVE )) || gt_raw 0
  fi
  local -a others
  for k in "${(@)GT_K[@]}"; do
    [[ "$k" == "$GT_AT" ]] && continue
    (( ${GT_S[$k.live]:-0} )) && others+=("$k")
  done
  (( ${#others[@]} )) || return 0
  (( GT_RR >= ${#others[@]} )) && GT_RR=0
  k="${others[$GT_RR]}"
  (( GT_RR++ ))
  pty="${GT_S[$k.pty]:-}"
  [[ -n "$pty" ]] || return 0
  c=''
  if ! zpty -rt "$pty" c 2>/dev/null; then
    # nothing to read: is it still there at all?
    zpty -t "$pty" 2>/dev/null || GT_S[$k.live]=0
    return 0
  fi
  [[ -n "$c" ]] || return 0
  keep="$GT_AT"
  [[ -n "$keep" ]] && gt_save "$keep"
  gt_load "$k"
  vt_feed "$c"
  ss_pump
  gt_save "$k"
  GT_S[$k.live]="$SS_LIVE"
  [[ -n "$keep" ]] && gt_load "$keep"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE PROGRAM'S OWN TERMINAL, PAINTED ONTO THE GLASS
# ══════════════════════════════════════════════════════════════════════════
# The cabinet keeps the window the whole time: the raster stays up, the neon
# stays on, the coin door still says what the machine is doing, and the
# program lives in the middle of it.  Two rows at the top say what is
# running, where, and how to get out; the twenty-eight under them are its
# terminal, cell for cell.

typeset -gi GT_FORCE=1

gt_vright() {   # gt_vright XRIGHT Y TEXT FG [BG] — right-aligned, ending at XRIGHT
  local s="$3"
  v_text $(( $1 - ${#s} + 1 )) $2 "$s" $4 ${5:-$GLASS}
}

gt_head() {   # gt_head T — the shell's session line, on the suite's title bar
  local k="$GT_AT" nm note cwd dot back=''
  local -i live=0 x ink sb=$VT_VIEW hb rx
  gt_live "$k" && live=1
  nm="${GT_S[$k.name]:-}"; note="${GT_S[$k.note]:-}"; cwd="${GT_S[$k.cwd]:-}"
  # THE BAND, THE BRAND, THE SKY AND THE RULE ARE THE CABINET'S · app_head lays
  # them, and the shell fills the room between with the one thing a page cannot
  # say: which session is on the keyboard, and how you get off it.
  cmix $GLASS $PURPLE 0.32; hb=$CM
  app_head TERMINAL
  x=$APP_HX
  # the live dot, the program on the keyboard, and where it is running
  if (( live )); then dot='●'; cmix $WHITE $LIME 0.35; ink=$CM
  else dot='○'; ink=$AMBER; fi
  v_text $x 0 "$dot" $ink $hb; (( x += 2 ))
  cmix $WHITE $CYAN 0.15; v_text $x 0 "$nm" $CM $hb; (( x += 1 + ${#nm} ))
  if [[ -n "$note" ]]; then
    gt_ell "$note" 26
    v_text $(( x + 1 )) 0 'on' $GT_LBL $hb
    v_text $(( x + 4 )) 0 "$GELL" $GT_FG $hb
    (( x += 5 + ${#GELL} ))
  fi
  gt_short "$cwd"; gt_ell "$GSHT" 30
  v_text $(( x + 1 )) 0 'in' $GT_LBL $hb
  v_text $(( x + 4 )) 0 "$GELL" $GT_FG $hb
  # HOW YOU LEAVE, and how far back you have scrolled, right-aligned just inside
  # the caption · the shell's own nav, since its keys all go to the program
  (( sb > VT_SB_N )) && sb=$VT_SB_N
  (( sb > 0 )) && back="▲ $sb of $VT_SB_N · wheel down for now"
  rx=$APP_HR
  if (( live )); then
    cmix $WHITE $AMBER 0.4; gt_vright $rx 0 '^] DETACH' $CM $hb; rx=$(( rx - 11 ))
    if [[ -n "$back" ]]; then gt_vright $rx 0 "$back" $AMBER $hb
    else gt_secs $(( EPOCHSECONDS - ${GT_S[$k.t0]:-EPOCHSECONDS} )); gt_vright $rx 0 "$GSEC" $GT_LBL $hb; fi
  else
    if [[ -n "$back" ]]; then gt_vright $rx 0 "$back" $AMBER $hb
    else gt_vright $rx 0 'ended · any key comes back' $AMBER $hb; fi
  fi
  return 0
}

gt_draw_shell() {   # gt_draw_shell T — the head and the grid of the session on the keyboard
  local -F t=$1
  local k="$GT_AT"
  local -i live=0 y0 cx cy blink=0 i
  [[ -n "$k" ]] || return 1
  gt_live "$k" && live=1
  gt_geom
  # EVERY ROW, EVERY FRAME -- which is what the original did too.  A
  # MACHINE'S GLASS IS NOT CACHEABLE on this cabinet: every page opens by
  # filling the whole surface, the raster paints over it during a
  # transition, and the tube is laid over the lot afterwards -- so a cell
  # not written this frame is not a cell that keeps what it had.  What IS
  # kept is the cutting of a line into runs, by the line (vt_runs_of).
  GT_FORCE=1
  # THE HEADER BAND, and then the grid, which is exactly VT_W by VT_H and
  # covers every remaining cell of the glass on its own.
  v_fill 0 0 $SCR_W 2 ' ' $GREY $GLASS
  gt_head $t
  (( y0 = GT_Y ))
  (( VT_CURS && live )) && (( (int(t * MO_BLINK) & 1) == 0 )) && blink=1
  # A DEAD SESSION IS DIMMED, not cleared: the last screen stays up to be
  # read, and it should not look like one you can still type at.
  GT_DEAD=$(( ! live ))
  vt_draw 0 $y0 $GT_FORCE
  GT_FORCE=0
  # THE CURSOR IS WHERE THE GRID'S ROW LANDED, which with the reader looking
  # back is VT_SHOWN rows further down -- or off the bottom, and not drawn.
  cx=$VT_X; cy=$(( VT_Y + VT_SHOWN ))
  if (( blink && cy >= 0 && cy < VT_H && cx >= 0 && cx < VT_W )); then
    vt_row_runs $VT_Y
    local ch="${VT_CH[$VT_Y][cx,cx]}" pen="-1 -1 0"
    for (( i = 0; i < ${#VR_X[@]}; i++ )); do
      (( cx >= VR_X[$i] && cx < VR_X[$i] + VR_N[$i] )) && { pen="${VR_PEN[$i]}"; break }
    done
    vt_ink "$pen"
    # THE CURSOR IS A CELL OF ITS OWN, not an attribute of one.
    cmix $VT_IB $GT_FG 0.85
    [[ "$ch" == "$VT_CONT" || -z "$ch" ]] && ch=' '
    v_text $cx $(( y0 + cy )) "$ch" $VT_IB $CM
  fi
  return 0
}
# gt_wheel KEY — the wheel over a session: back into the past, or toward now
# HOW MANY LINES A WHEEL NOTCH IS WORTH when it stands in for arrow keys · a
# real terminal's alternateScroll sends three, which is what feels like a notch
typeset -gi GT_WHEEL_LINES=3
gt_wheel() {
  local -i n=1
  case "$1" in
    wheelup) n=-1 ;;  wheeldown) n=1 ;;
    pgup)    n=$(( -(VT_H - 2) )) ;;  pgdn) n=$(( VT_H - 2 )) ;;
    *) return 1 ;;
  esac
  # ALTERNATE SCROLL · a full-screen program on the alternate screen -- an
  # agent, opencode, vim, less -- keeps its own history and leaves this
  # terminal none: the main-screen scrollback is empty while it is up, so a
  # wheel notch had nothing to move and the glass sat still.  A real terminal
  # answers this with DECSET 1007: on the alternate screen the wheel is handed
  # to the program AS ARROW KEYS, and the program scrolls itself.  So does the
  # glass now -- but only when the program has NOT taken the mouse itself (one
  # that has is owed the reports, and gets them), and only while it is live
  # (a session that has ended is read from its scrollback like any other).
  if (( VT_ALT && ! VT_MOUSE )) && [[ -n "$GT_AT" ]] && gt_live "$GT_AT"; then
    local up dn seq='' out=''
    local -i i reps=$GT_WHEEL_LINES
    if (( VT_APPCUR )); then up=$'\eOA'; dn=$'\eOB'; else up=$'\e[A'; dn=$'\e[B'; fi
    case "$1" in
      # a page is the program's own PageUp/PageDown, which a TUI that has one
      # honours and one that does not treats as a long run of arrows would be
      pgup) ss_write $'\e[5~'; return 0 ;;
      pgdn) ss_write $'\e[6~'; return 0 ;;
      wheelup)   seq="$up" ;;
      wheeldown) seq="$dn" ;;
    esac
    for (( i = 0; i < reps; i++ )); do out+="$seq"; done
    ss_write "$out"
    return 0
  fi
  VT_VIEW=$(( VT_VIEW - n ))
  (( VT_VIEW > VT_SB_N )) && VT_VIEW=$VT_SB_N
  (( VT_VIEW < 0 )) && VT_VIEW=0
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 18c · A SHELL IN THE GLASS       what [T] TERMINAL opens
# ══════════════════════════════════════════════════════════════════════════
# [T] USED TO DEAL EVERY MACHINE A TAB.  That was the door's one way of
# opening anything, back when the machines lived in tabs; now two of them
# stand in this glass, the other two are rows of their own, and what the
# row was left doing -- opening all four at once -- was the thing nobody
# asked a cabinet for.  What a reader wants from a row called TERMINAL is
# a terminal: their own shell, in the glass, with the neon around it.
#
# SO THAT IS WHAT IT IS.  ⏎ on the row starts the reader's login shell in
# the glass terminal (SECTION 18b), in the folder the cabinet was opened
# from, and the keyboard is the shell's for as long as it runs -- every
# key, ^C included.  ^] steps back out to the menu with the shell still
# running, and ⏎ on the row again is the same shell, where it was; `exit`
# ends it and leaves its last screen up to be read until any key.  The
# wheel is its scrollback, like any session's.
#
# THE SURFACE IS A MACHINE THE DOOR CARRIES ITSELF.  It borrows the hooks
# a pack would set and gives them back on the way out, so a pack that was
# standing before is standing after without being sourced again.
typeset -ga HSH_KEEP
hsh_hooks_keep() {
  HSH_KEEP=("$PACK_NAME" "$PACK_MODEL" "$PACK_TICK" "$PACK_DRAW" "$PACK_KEY" "$PACK_RAW" "$PACK_DRESS" "$PACK_LEAVE")
  return 0
}
hsh_hooks_restore() {
  (( ${#HSH_KEEP[@]} == 8 )) || return 0
  PACK_NAME="${HSH_KEEP[0]}"; PACK_MODEL="${HSH_KEEP[1]}"
  PACK_TICK="${HSH_KEEP[2]}"; PACK_DRAW="${HSH_KEEP[3]}"; PACK_KEY="${HSH_KEEP[4]}"
  PACK_RAW="${HSH_KEEP[5]}";  PACK_DRESS="${HSH_KEEP[6]}"; PACK_LEAVE="${HSH_KEEP[7]}"
  HSH_KEEP=()
  return 0
}
hsh_open() {
  local sh="${SHELL:-/bin/zsh}"
  [[ -x "$sh" ]] || sh=/bin/zsh
  vt_palette
  # A LOGIN SHELL, because that is what a new Terminal window would have
  # given: the same ~/.zprofile, the same PATH, the same prompt.  The hook
  # in conf.d stands aside inside it -- ALIEN_DOOR is exported -- so a
  # shell in the glass is a shell, not another cabinet.
  if ! gt_open shell "SHELL · ${sh:t}" "$(_sh "$sh") -l" "$PWD" ''; then
    gt_ell "${SS_ERR:-it would not start}" 40
    say "no shell: $GELL"; snd no
    return 1
  fi
  hsh_hooks_keep
  PACK_NAME='TERMINAL'; PACK_MODEL='AD-1'
  PACK_TICK='hsh_tick'; PACK_DRAW='hsh_draw'; PACK_KEY='hsh_key'; PACK_RAW='hsh_raw'
  PACK_DRESS='hsh_dress'; PACK_LEAVE=''
  UI_SURF='T'
  SURF_PAINTED=0                      # opening · hold the glass until the shell's first paint
  surf_dress
  redress
  xf_arm
  BEAT_SKIP=1
  if (( GT_BACK )); then say 'back in your shell'; snd move; else snd open; fi
  return 0
}
hsh_close() {   # the menu again · the session is whatever gt_* left it
  UI_SURF=''
  PACK_FILL=0
  hsh_hooks_restore
  surf_dress
  redress
  xf_arm
  return 0
}
hsh_tick() { return 0 }             # the cabinet pumps every session itself
hsh_draw() {   # hsh_draw T
  # THE SHELL FILLS THE WINDOW TOO · its pty was sized to the glass at open
  # (gt_geom off SCR_W), so raising this keeps the glass at that width instead
  # of reflowing it away to the float cabinet and clipping the session.  The one
  # caveat is the pty's: a live terminal cannot be re-sized once it is running,
  # so a window resized WHILE the shell is up does not reflow it -- reopen [T].
  PACK_FILL=1
  if ! gt_draw_shell $1; then
    # nothing on the keyboard any more: the menu
    hsh_close
    frame_glass $1
  fi
  return 0
}
hsh_key() {   # keys reach here only once the shell has ended (raw mode is off)
  case "$1" in
    wheelup|wheeldown|pgup|pgdn) gt_wheel "$1"; return 0 ;;
  esac
  # any other key: the reader has read the last screen
  gt_done
  hsh_close
  snd away
  return 0
}
hsh_raw() {   # hsh_raw want | mouse | feed BYTES
  case "$1" in
    want)  [[ "$UI_SURF" == T && -n "$GT_AT" ]] || return 1
           gt_live "$GT_AT" ;;
    mouse) (( VT_MOUSE )) ;;
    feed)  kb_feed "$2" $(( OX + C_SCR )) $(( OY + R_SCR + GT_Y ))
           if (( KB_BACK )); then
             gt_detach
             hsh_close
             say 'detached — your shell is still running · [T] goes back in'
             snd away
           fi
           return 0 ;;
    *)     return 1 ;;
  esac
}
hsh_dress() {
  local sh="${SHELL:-/bin/zsh}"
  SURF_MODEL='AD-1'
  SURF_SIGN='◂ S H E L L ▸'
  SURF_TAG='ALIEN DYNAMICS · AD-1 · A SHELL IN THE GLASS'
  SURF_KEYS='[^]]DETACH   exit ENDS IT   [WHEEL]SCROLL BACK   [PGUP·PGDN]A PAGE'
  SURF_BADGE=" ${sh:t:u} "
  SURF_MSG='YOUR OWN PROMPT · THE CABINET AROUND IT'
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 18d · CONFIG        the cabinet's own settings, felt by every machine
# ══════════════════════════════════════════════════════════════════════════
# A SURFACE THE DOOR CARRIES ITSELF, the way the shell above is: it borrows the
# pack hooks, sets its own, and gives them back on the way out -- so a machine
# standing before CONFIG is standing after it, unsourced.  What it changes is
# not a machine but the CABINET: the sound every surface plays, the tube every
# surface wears, the rate they all run at.  Those belong to the house, so it is
# a SUITE row and not a machine, and it keeps what it is told in terminal.conf --
# the one file the five programs already share, `key = value`, the last spelling
# of a key wins, and a key it does not know it leaves alone (SECTION 7's
# contract, brought back for the one machine that now has settings to write).

# the rows, in order · a name, what it does, and WHEN a change is felt: `live`
# this instant, or `restart` at the next power-on.  Colour is settled once as
# the tube is built and boot once as the opening is decided, so those two are
# written now and read on the way up, not turned under the reader's hand.
CFG_NAME=(SOUND PHOSPHOR BEAT BOOT SCREEN)
CFG_DESC=("blips, cursor ticks, the alert on a no"
          "the tube's soft bleed, or hard blocks"
          "the frame rate the whole cabinet runs"
          "the opening ceremony, or skip to it"
          "float in the night, or fill the window")
CFG_WHEN=(live live live restart live)
typeset -gi CFG_N=${#CFG_NAME[@]}
typeset -gi CFG_ROW=0 CFG_GEN=0
CFG_BEATV=(0 30 60 120)              # the rungs [BEAT] steps through · 0 self-governs
CFGV=''                             # cfg_val's answer, declared for set -u
typeset -ga CFG_KEEP                # the pack hooks CONFIG stands in front of

cfg_hooks_keep() {
  CFG_KEEP=("$PACK_NAME" "$PACK_MODEL" "$PACK_TICK" "$PACK_DRAW" \
            "$PACK_KEY" "$PACK_RAW" "$PACK_DRESS" "$PACK_LEAVE")
  return 0
}
cfg_hooks_restore() {
  (( ${#CFG_KEEP[@]} == 8 )) || return 0
  PACK_NAME="${CFG_KEEP[0]}"; PACK_MODEL="${CFG_KEEP[1]}"
  PACK_TICK="${CFG_KEEP[2]}"; PACK_DRAW="${CFG_KEEP[3]}"; PACK_KEY="${CFG_KEEP[4]}"
  PACK_RAW="${CFG_KEEP[5]}";  PACK_DRESS="${CFG_KEEP[6]}"; PACK_LEAVE="${CFG_KEEP[7]}"
  CFG_KEEP=()
  return 0
}

# ── terminal.conf · read at power-up, rewritten in place on a change ─────────
typeset -g  CFG_STATE='none'
typeset -gi CFG_KEYS=0
# THE READER IS save_load's in miniature, pointed at the conf and taking only
# the five keys CONFIG owns.  Everything else in the file -- comments, the hook
# switch bootstrap.zsh writes, a key another machine adds one day -- is read
# past here and, by cfg_save, kept.
cfg_load() {
  local conf="$REPO/terminal.conf"
  # WHAT WAS FOUND, for the self test · found · unreadable · none, and how
  # many settings are in it (every machine's, not only these five)
  CFG_KEYS=0
  if [[ ! -e "$conf" ]]; then CFG_STATE='none'; return 0; fi
  if [[ ! -f "$conf" || ! -r "$conf" ]]; then CFG_STATE='unreadable'; return 0; fi
  CFG_STATE='found'
  local line k v
  local -i n=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    (( ++n > 20000 )) && break
    line="${line%$'\r'}"
    _trim "$line"; line="$TR"
    [[ -n "$line" && "$line" != '#'* && "$line" == *'='* ]] || continue
    k="${line%%=*}"; v="${line#*=}"
    _trim "$k"; k="$TR"
    _trim "$v"; v="${TR:l}"
    [[ -n "$k" ]] && (( ++CFG_KEYS ))
    case "$k" in
      sound)    case "$v" in off|0|no|false) CFG_SOUND=0 ;; *) CFG_SOUND=1 ;; esac ;;
      phosphor) case "$v" in sharp) OPT_SHARP=1 ;; *) OPT_SHARP=0 ;; esac ;;
      beat)     case "$v" in 30|60|120) OPT_FPS=$v ;; *) OPT_FPS=0 ;; esac ;;
      boot)     case "$v" in fast) CFG_BOOT_FAST=1 ;; *) CFG_BOOT_FAST=0 ;; esac ;;
      screen)   case "$v" in fill|on|1) CFG_FILL=1 ;; *) CFG_FILL=0 ;; esac ;;
    esac
  done < "$conf"
  # THE RATE FELT AT LAUNCH, resolved now while it is still early enough: it is
  # the load queue's very next step.  Colour is no longer a setting -- the
  # dotfiles are 24-bit, left to what the terminal reported it can take up top.
  (( OPT_FPS && OPT_FPS < 4 )) && OPT_FPS=4
  (( OPT_FPS > 144 )) && OPT_FPS=144
  return 0
}

cfg_count() {   # CFG_STATE CFG_KEYS · whether terminal.conf is there now, and how full · nothing applied
  local conf="$REPO/terminal.conf" line
  local -i n=0
  CFG_KEYS=0
  if [[ ! -e "$conf" ]]; then CFG_STATE='none'; return 0; fi
  if [[ ! -f "$conf" || ! -r "$conf" ]]; then CFG_STATE='unreadable'; return 0; fi
  CFG_STATE='found'
  while IFS= read -r line || [[ -n "$line" ]]; do
    (( ++n > 20000 )) && break
    _trim "${line%$'\r'}"
    [[ -n "$TR" && "$TR" != '#'* && "$TR" == *'='* ]] || continue
    _trim "${TR%%=*}"; [[ -n "$TR" ]] && (( ++CFG_KEYS ))
  done < "$conf"
  return 0
}

# RETIRED KEYS GO ON THE WAY THROUGH.  A key this house has no program for is
# normally left alone -- the file is shared, and a key another machine adds
# one day is that machine's -- but these two were the suite's own and nothing
# reads them any more: colour (the dotfiles are 24-bit, left to what the
# terminal says it can take) and intelligence.open (INTELLIGENCE opens in the
# glass, always).  A conf carried over from an older Mac loses them the first
# time CONFIG writes it, and every other line is kept exactly as it was.
CFG_RETIRED=(colour intelligence.open)
cfg_save() {   # terminal.conf rewritten · our five keys set, the retired ones dropped, everything else kept
  local conf="$REPO/terminal.conf" dir
  dir="${conf:h}"
  [[ -d "$dir" && -w "$dir" ]] || return 1
  local sound phosphor beat boot screen
  (( CFG_SOUND )) && sound=on       || sound=off
  (( OPT_SHARP )) && phosphor=sharp || phosphor=soft
  (( OPT_FPS ))   && beat="$OPT_FPS" || beat=auto
  (( CFG_BOOT_FAST )) && boot=fast || boot=full
  (( CFG_FILL )) && screen=fill || screen=float
  typeset -A want hit
  want=(sound "$sound" phosphor "$phosphor" beat "$beat" boot "$boot" screen "$screen")
  local -a out
  local line raw t k
  if [[ -f "$conf" && -r "$conf" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      raw="${line%$'\r'}"
      _trim "$raw"; t="$TR"
      if [[ -n "$t" && "$t" != '#'* && "$t" == *'='* ]]; then
        k="${t%%=*}"; _trim "$k"; k="$TR"
        if [[ -n "${want[$k]:-}" && -z "${hit[$k]:-}" ]]; then
          out+=("$k = ${want[$k]}"); hit[$k]=1; continue
        fi
        [[ " ${CFG_RETIRED[*]} " == *" $k "* ]] && continue
      fi
      out+=("$line")
    done < "$conf"
  fi
  for k in sound phosphor beat boot screen; do
    [[ -n "${hit[$k]:-}" ]] && continue
    out+=("$k = ${want[$k]}")
  done
  # WRITTEN WHOLE, THEN MOVED OVER.  A half-written settings file is worse than
  # a stale one; a temp beside it and a rename means a pulled plug leaves one or
  # the other, never a torn line.
  local tmp="$conf.$$" l
  { for l in "${out[@]}"; do print -r -- "$l"; done } > "$tmp" 2>/dev/null \
    && mv -f "$tmp" "$conf" 2>/dev/null && return 0
  rm -f "$tmp" 2>/dev/null
  return 1
}

# ── the value under the cursor as a word, and the step that changes it ───────
cfg_val() {   # cfg_val I -> CFGV
  case $1 in
    0) (( CFG_SOUND )) && CFGV=on    || CFGV=off ;;
    1) (( OPT_SHARP )) && CFGV=sharp  || CFGV=soft ;;
    2) (( OPT_FPS ))   && CFGV="$OPT_FPS" || CFGV=auto ;;
    3) (( CFG_BOOT_FAST )) && CFGV=fast || CFGV=full ;;
    4) (( CFG_FILL ))  && CFGV=fill   || CFGV=float ;;
  esac
  return 0
}

cfg_cycle() {   # cfg_cycle DIR — the setting under the cursor · DIR +1 or -1
  local -i d=$1 i=$CFG_ROW j n
  case $i in
    0) CFG_SOUND=$(( 1 - CFG_SOUND )) ;;
    1) OPT_SHARP=$(( 1 - OPT_SHARP )) ;;
    2) n=${#CFG_BEATV[@]}
       for (( j = 0; j < n; j++ )); do [[ "${CFG_BEATV[$j]}" == "$OPT_FPS" ]] && break; done
       (( j >= n )) && j=0
       j=$(( (j + d + n) % n ))
       OPT_FPS=${CFG_BEATV[$j]}
       beat_reset ;;                  # the one change felt at once · rebuild the ladder
    3) CFG_BOOT_FAST=$(( 1 - CFG_BOOT_FAST )) ;;
    4) CFG_FILL=$(( 1 - CFG_FILL )); scr_refit ;;  # repaint the still layer for the new mode
  esac
  (( CFG_GEN++ ))
  if cfg_save; then snd pick
  else say 'terminal.conf is not writable — this change holds only until you quit'; snd no; fi
  return 0
}

# ── the surface · opened from the SUITE row, drawn while it stands ───────────
cfg_open() {
  cfg_hooks_keep
  PACK_NAME='CONFIG'; PACK_MODEL='AD-0'
  PACK_TICK=''; PACK_DRAW='cfg_draw'; PACK_KEY='cfg_key'; PACK_RAW=''
  PACK_DRESS='cfg_dress'; PACK_LEAVE=''
  UI_SURF='C'
  (( CFG_GEN++ ))
  surf_dress
  redress
  xf_arm
  BEAT_SKIP=1
  snd open
  return 0
}
cfg_close() {   # the menu again · the hooks CONFIG stood in front of, put back
  UI_SURF=''
  cfg_hooks_restore
  surf_dress
  redress
  xf_arm
  snd away
  return 0
}
cfg_draw() {   # cfg_draw T
  if (( CFG_FILL )); then
    # SCREEN=fill · the page GROWS to the whole terminal.  It draws with the
    # canvas-absolute c_* (which clip to the terminal, not the fixed glass) so
    # it can reach every edge, live each frame rather than through the glass
    # cache, and covers whatever chrome frame_begin laid under it.
    cfg_paint_big $1
  else
    glass_cached "cfg|$CFG_GEN|${SCR_W}x${SCR_H}" cfg_paint
  fi
  return 0
}
cfg_key() {   # cfg_key KEY — 0 if CONFIG took it · esc/m/back leave, q is the door's
  case "$1" in
    up|k|K)     (( CFG_ROW > 0 ))         && { (( CFG_ROW-- )); (( CFG_GEN++ )); snd move }; return 0 ;;
    down|j|J)   (( CFG_ROW < CFG_N - 1 )) && { (( CFG_ROW++ )); (( CFG_GEN++ )); snd move }; return 0 ;;
    wheelup)    (( CFG_ROW > 0 ))         && { (( CFG_ROW-- )); (( CFG_GEN++ )) }; return 0 ;;
    wheeldown)  (( CFG_ROW < CFG_N - 1 )) && { (( CFG_ROW++ )); (( CFG_GEN++ )) }; return 0 ;;
    right|enter|' ') cfg_cycle 1;  return 0 ;;
    left)            cfg_cycle -1; return 0 ;;
    esc|m|M|back)    cfg_close;    return 0 ;;
    q|Q)             return 1 ;;    # the power switch is the door's, from anywhere
    *)               return 0 ;;    # a key CONFIG has no use for · swallowed, no scold
  esac
}
cfg_dress() {
  SURF_MODEL='AD-0'
  SURF_SIGN='◂ C O N F I G ▸'
  SURF_TAG='ALIEN DYNAMICS · AD-0 · THE CABINET ITSELF'
  SURF_KEYS='[▲▼]CHOOSE   [◂ ▸]CHANGE   [⏎]CHANGE   [⎋]BACK'
  SURF_BADGE=' SETTINGS '
  SURF_MSG='WHAT EVERY MACHINE FEELS'
  return 0
}

# ── the page · a centred panel, one row a setting ───────────────────────────
cfg_row() {   # cfg_row I PX PW Y
  local -i i=$1 px=$2 pw=$3 y=$4 sel=0
  (( i == CFG_ROW )) && sel=1
  local nm="${CFG_NAME[$i]}" desc="${CFG_DESC[$i]}" when="${CFG_WHEN[$i]}"
  cfg_val $i; local val="$CFGV"
  local -i xn=$(( px + 5 )) xv=$(( px + 17 )) xd=$(( px + 31 )) nc dc vc dmax wx
  if (( sel )); then
    cmix $WHITE $CYAN 0.35;  v_text $(( px + 2 )) $y '▌' $CM
    v_text $(( px + 3 )) $y '▸' $LIME
    nc=$WHITE; vc=$AMBER
    v_text $xv $y "◂ $val ▸" $vc
    cshade $GREY 1.0; dc=$CS
  else
    cshade $GREY 1.2;   nc=$CS
    cshade $AMBER 0.7;  vc=$CS
    cshade $DIM 1.2;    dc=$CS
    v_text $(( xv + 2 )) $y "$val" $vc
  fi
  v_text $xn $y "${(r:11:)nm}" $nc
  dmax=$(( pw - (xd - px) - 11 )); (( dmax < 1 )) && dmax=1
  v_text $xd $y "${desc[0,$dmax]}" $dc
  wx=$(( px + pw - 2 - ${#when} ))
  [[ "$when" == live ]] && cshade $LIME 0.85 || cshade $PURPLE 1.25
  v_text $wx $y "$when" $CS
  return 0
}
cfg_paint() {
  local -i i y pw=80 px ph py pb pc
  v_fill 0 0 $SCR_W $SCR_H ' ' -1 $GLASS
  px=$(( (SCR_W - pw) / 2 ))
  ph=$(( CFG_N + 6 ))
  py=$(( (SCR_H - ph) / 2 )); (( py < 1 )) && py=1
  cmix $GLASS $PURPLE 0.13; pb=$CM
  cshade $PURPLE 0.85;      pc=$CS
  v_box $px $py $pw $ph $pc $pb round 1
  cmix $CYAN $WHITE 0.25;   v_text $(( px + 3 )) $py ' CONFIG ' $CM $pb
  cshade $DIM 1.1;          v_text $(( px + pw - 24 )) $py ' ALIEN DYNAMICS · AD-0 ' $CS $pb
  cshade $GREY 1.15;        v_text $(( px + 3 )) $(( py + 1 )) 'the cabinet itself — every machine feels these' $CS
  for (( i = 0; i < CFG_N; i++ )); do
    y=$(( py + 3 + i ))
    cfg_row $i $px $pw $y
  done
  cshade $DIM 1.25
  v_text $(( px + 3 )) $(( py + ph - 2 )) 'live · felt now      restart · at the next power-on' $CS
  return 0
}

# ── SCREEN=fill · the page centred on a full-terminal glass ──────────────────
# The fixed-glass version above draws through v_* (clipped to 106x30); this one
# draws through c_* (clipped only to the terminal), so it fills the WHOLE screen
# with glass and sets a right-sized panel in the middle.  A settings page is a
# handful of rows; stretching it to the edges only makes gaps, so the thing that
# fills the terminal is the GLASS, not the list.  The panel stays legible, the
# glass is the room around it -- one screen at any window size.
cfg_row_c() {   # cfg_row_c I PX PW Y PB — a setting row on the centred panel
  local -i i=$1 px=$2 pw=$3 y=$4 pb=$5 sel=0
  (( i == CFG_ROW )) && sel=1
  local nm="${CFG_NAME[$i]}" desc="${CFG_DESC[$i]}" when="${CFG_WHEN[$i]}"
  cfg_val $i; local val="$CFGV"
  local -i xn=$(( px + 5 )) xv=$(( px + 18 )) xd=$(( px + 32 )) nc dc vc dmax wx
  if (( sel )); then
    cmix $WHITE $CYAN 0.4; c_text $(( px + 2 )) $y '▌' $CM $pb
    c_text $(( px + 3 )) $y '▸' $LIME $pb
    nc=$WHITE; vc=$AMBER
    c_text $xv $y "◂ ${(U)val} ▸" $vc $pb
    cshade $GREY 1.0; dc=$CS
  else
    cshade $GREY 1.2;  nc=$CS
    cshade $AMBER 0.8; vc=$CS
    cshade $DIM 1.2;   dc=$CS
    c_text $(( xv + 2 )) $y "${(U)val}" $vc $pb
  fi
  c_text $xn $y "${(r:11:)nm}" $nc $pb
  dmax=$(( px + pw - 3 - ${#when} - xd )); (( dmax < 1 )) && dmax=1
  c_text $xd $y "${desc[0,$dmax]}" $dc $pb
  wx=$(( px + pw - 2 - ${#when} ))
  [[ "$when" == live ]] && cshade $LIME 0.9 || cshade $PURPLE 1.2
  c_text $wx $y "$when" $CS $pb
  return 0
}
cfg_paint_big() {   # cfg_paint_big T — a right-sized panel, centred on the filled glass
  local -F t=$1 midr fr
  local -i pw ph px py i y pb pc gc
  # THE GLASS FILLS THE WHOLE TERMINAL · lifted off near-black so it reads as a
  # lit CRT screen and not the bare window, a shade brighter down the middle
  # where the panel sits and darker at the top and bottom edges, for tube depth.
  midr=$(( (TROWS - 1) / 2.0 ))
  for (( y = 0; y < TROWS; y++ )); do
    fr=$(( midr > 0.0 ? 1.0 - abs(y - midr) / midr : 1.0 )); (( fr < 0.0 )) && fr=0.0
    cmix $GLASS $PURPLE $(( 0.05 + 0.055 * fr )); gc=$CM
    c_fill 0 $y $TCOLS 1 ' ' $GREY $gc
  done
  pw=84; (( pw > TCOLS - 8 )) && pw=$(( TCOLS - 8 ))
  ph=$(( CFG_N + 7 ))
  px=$(( (TCOLS - pw) / 2 )); py=$(( (TROWS - ph) / 2 )); (( py < 1 )) && py=1
  cmix $GLASS $PURPLE 0.17; pb=$CM
  cshade $PURPLE 0.85;      pc=$CS
  # a solid panel body laid on the glass, then its frame
  for (( y = py + 1; y < py + ph - 1; y++ )); do c_fill $(( px + 1 )) $y $(( pw - 2 )) 1 ' ' $GREY $pb; done
  c_box $px $py $pw $ph $pc $pb round
  cmix $CYAN $WHITE 0.25;  c_text $(( px + 3 )) $py ' CONFIG ' $CM $pb
  cshade $DIM 1.1;         c_text $(( px + pw - 24 )) $py ' ALIEN DYNAMICS · AD-0 ' $CS $pb
  cshade $GREY 1.15;       c_text $(( px + 3 )) $(( py + 1 )) 'the cabinet itself — every machine feels these' $CS $pb
  cshade $PURPLE 0.55;     c_fill $(( px + 2 )) $(( py + 2 )) $(( pw - 4 )) 1 '─' $CS $pb
  for (( i = 0; i < CFG_N; i++ )); do
    y=$(( py + 3 + i ))
    cfg_row_c $i $px $pw $y $pb
  done
  cshade $PURPLE 0.55; c_fill $(( px + 2 )) $(( py + ph - 3 )) $(( pw - 4 )) 1 '─' $CS $pb
  cshade $DIM 1.2;     c_text $(( px + 3 )) $(( py + ph - 2 )) 'live · felt now      restart · at the next power-on' $CS $pb
  cshade $GREY 1.0;    c_center $(( py + ph + 1 )) "$SURF_KEYS" $CS $GLASS $px $pw
  return 0
}

# ── CONFIG · a popup on the menu, the way a machine opens its own chooser ────
# THE SETTINGS USED TO BE A SURFACE THE DOOR CARRIED (a page it switched to);
# they are a MODAL now -- a box that folds up over TERMINAL's own glass and
# folds away again, the same modal_frame gesture INTELLIGENCE opens its model
# picker with.  The glass behind it never goes anywhere.  It reuses cfg_row and
# cfg_cycle whole: the same six rows, drawn into a box the menu paints on top
# of itself once per frame while it is up.
#
#   CFG_OPEN   0 shut · 1 standing (answers keys) · 2 folding away (still drawn)
typeset -gi CFG_OPEN=0
typeset -gi CFG_MX=0 CFG_MY=0 CFG_MW=0 CFG_MH=0
cfg_modal_open()  { CFG_ROW=0; CFG_OPEN=1; (( CFG_GEN++ )); modal_open; snd pick; return 0 }
cfg_modal_close() { CFG_OPEN=2; modal_close; snd away; return 0 }
cfg_modal_geom() {   # the box, centred on whatever glass is up (fixed or filled)
  CFG_MW=80; (( CFG_MW > SCR_W - 6 )) && CFG_MW=$(( SCR_W - 6 ))
  CFG_MH=$(( CFG_N + 6 ))
  CFG_MX=$(( (SCR_W - CFG_MW) / 2 ))
  CFG_MY=$(( (SCR_H - CFG_MH) / 2 )); (( CFG_MY < 1 )) && CFG_MY=1
  return 0
}
cfg_draw_modal() {   # cfg_draw_modal T — the box · knows its own X/Y/W/H by convention
  local -i px=$CFG_MX py=$CFG_MY pw=$CFG_MW ph=$CFG_MH i y pb pc
  cmix $GLASS $PURPLE 0.15; pb=$CM
  # a solid body so the menu behind does not read up through the box
  for (( y = py + 1; y < py + ph - 1; y++ )); do v_fill $(( px + 1 )) $y $(( pw - 2 )) 1 ' ' $GREY $pb; done
  cshade $PURPLE 0.85; pc=$CS
  v_box $px $py $pw $ph $pc $pb round 1
  cmix $CYAN $WHITE 0.25; v_text $(( px + 3 )) $py ' CONFIG ' $CM $pb
  cshade $DIM 1.1;        v_text $(( px + pw - 24 )) $py ' ALIEN DYNAMICS · AD-0 ' $CS $pb
  cshade $GREY 1.15;      v_text $(( px + 3 )) $(( py + 1 )) 'the cabinet itself — every machine feels these' $CS $pb
  for (( i = 0; i < CFG_N; i++ )); do
    y=$(( py + 3 + i ))
    cfg_row $i $px $pw $y
  done
  cshade $DIM 1.25; v_text $(( px + 3 )) $(( py + ph - 2 )) '[▴ ▾] choose   [◂ ▸ ⏎] change   [⎋] back' $CS $pb
  return 0
}
menu_modals() {   # menu_modals T — the popups that stand over TERMINAL's own glass
  local -F t=$1
  if (( CFG_OPEN )); then
    if (( CFG_OPEN == 2 )) && ! modal_busy; then CFG_OPEN=0
    else
      cfg_modal_geom
      modal_frame $CFG_MX $CFG_MY $CFG_MW $CFG_MH cfg_draw_modal $t
      modal_gone && CFG_OPEN=0
    fi
  fi
  return 0
}
cfg_modal_key() {   # cfg_modal_key TOKEN — every key while the box is up · always swallowed
  case "$1" in
    up|k)            (( CFG_ROW > 0 ))         && { (( CFG_ROW-- )); (( CFG_GEN++ )); snd move } ;;
    down|j)          (( CFG_ROW < CFG_N - 1 )) && { (( CFG_ROW++ )); (( CFG_GEN++ )); snd move } ;;
    right|enter|' ') cfg_cycle 1 ;;
    left)            cfg_cycle -1 ;;
    esc|m|M|c|C|back) cfg_modal_close ;;
    *) ;;            # a key the box has no use for · swallowed, the menu never sees it
  esac
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE VISITOR'S EAR · a line to type, and him answering it
# ══════════════════════════════════════════════════════════════════════════
# YOU TYPE AT THE FOOT OF THE GLASS AND HE ANSWERS OVER HIS SHOULDER.  The box
# along the bottom is INTELLIGENCE's console field -- ⏎ steps into it, ⎋ steps
# out, and it stays live after a line is sent, because a conversation is a
# series of lines -- and what he says comes up in a bubble above and to the
# right of his head, growing as the words arrive, the way somebody talks.
#
# THE WIRE IS THE CONSOLE'S: the OpenAI-shaped endpoint every local runner
# already serves, the request written to a 0600 file and never onto a command
# line where `ps` would show it, and the answer streamed through awk into a
# scratch log this page reads back.  What is his own is who answers: a few
# lines of who he is, what he has on and the sky he is under go ahead of the
# conversation, so the model answers AS him.
#
# AND THE MODEL IS NEVER NAMED ON HIS PAGE.  He is somebody you talk to, not a
# front end for a runner, so the glass says which model it is nowhere -- the
# one time the machinery is mentioned is when there is none: nothing
# installed, or nothing running, and the box says where that is put right.
#
# IT IS LOCAL OR IT IS NOTHING.  He listens on this Mac's loopback for the four
# runners INTELLIGENCE knows, at the ports INTELLIGENCE knows them on, and a
# model a runner only relays to somebody's cloud (ollama's `-cloud` tags) is
# passed over -- so nothing typed here leaves the machine and no account of
# anybody's is ever spent.  He does not install or start anything himself.
VC_RNAME=('OLLAMA' 'LLAMA.CPP' 'LM STUDIO' 'MLX')
VC_RPORT=(11434 8080 1234 8081)
VC_RAPI=('/api/tags' '/v1/models' '/v1/models' '/v1/models')
typeset -ga VC_WHO VC_TXT VC_MODELS VCM WRV
typeset -gi VC_N=0 VC_RUN=-1 VC_PID=0 VC_LI=0 VC_EDIT=0 VC_PPID=0 VC_PRUN=-1 VC_ZTCP=-1
typeset -g  VC_STATE='' VC_LOG='' VC_BODY='' VC_LINE='' VC_MODEL='' VC_PLOG='' VC_ERR=''
typeset -g  VJE='' VCC='' VCP='' VNW=''
typeset -gF VC_POLL=0.0 VC_PROBE_AT=-100.0 VC_PSTART=0.0 VC_LISTED=-100.0 VC_PACE=4.0
typeset -gi VC_IDLE=-1                   # a runner that is up and holds nothing he can talk with
typeset -g  VC_SETUP=''                  # '' he can talk · install · start · what the box says when he cannot
typeset -gA VC_EMPTY                     # runner → when it last answered with nothing, or was not a runner at all

# THE PARSER IS INTELLIGENCE'S, the same awk: a streamed answer is hundreds of
# `data: {…}` lines a second, and picking the text out of each in zsh would be
# a character loop per chunk on a cabinet with thirty frames to draw.  \uXXXX
# is decoded, a surrogate pair is joined, and a body that came back as an
# ERROR is said on a line of its own rather than lost -- a model that is not
# there, or that wants more memory than the Mac has, is worth being told.
VC_SSE_AWK='
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
function jstr(s,   out, i, n, c, d, v, w) {
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
  return out
}
BEGIN { u8 = (length("\303\251") == 1) }
{
  k = index($0, "\"content\":")
  if (k == 0) {
    if (!said && index($0, "\"error\"") > 0) {
      m = index($0, "\"message\":")
      e = "the runner answered with an error"
      if (m > 0) {
        s = substr($0, m + 10); sub(/^[ \t]+/, "", s)
        if (substr(s, 1, 1) == "\"") e = jstr(substr(s, 2))
      } else {
        m = index($0, "\"error\":")
        s = substr($0, m + 8); sub(/^[ \t]+/, "", s)
        if (substr(s, 1, 1) == "\"") e = jstr(substr(s, 2))
      }
      printf "\n__ERR__ %s\n", e; fflush(); said = 1
    }
    next
  }
  s = substr($0, k + 10)
  sub(/^[ \t]+/, "", s)
  if (substr(s, 1, 1) != "\"") next
  printf "%s", jstr(substr(s, 2)); fflush()
}'

# ── the runner · which one is up, and what it will talk with ──────────────
# THE PORT IS THE QUESTION, as it is on INTELLIGENCE's LOCAL page -- ztcp,
# which is zsh's own and not a fork, and a refused connection on loopback
# comes back at once.  netcat only where the module is not.
vc_port_up() {   # vc_port_up PORT — 0 when something is listening on this Mac's loopback there
  if (( VC_ZTCP < 0 )); then
    zmodload -F zsh/net/tcp +b:ztcp 2>/dev/null && VC_ZTCP=1 || VC_ZTCP=0
  fi
  if (( VC_ZTCP )); then
    ztcp 127.0.0.1 $1 2>/dev/null || return 1
    [[ -n "${REPLY:-}" ]] && ztcp -c $REPLY 2>/dev/null
    return 0
  fi
  (( ${+commands[nc]} )) && nc -z -G 1 127.0.0.1 $1 >/dev/null 2>&1
}
# A MODEL HE CAN TALK WITH: not an embedder or a reranker, which cannot chat,
# and not a cloud tag, which would carry the conversation off the machine
vc_chat_model() {   # vc_chat_model NAME — 0 when it is a local model that chats
  local m="${1:l}"
  [[ "$m" == *embed* || "$m" == *rerank* ]] && return 1
  [[ "$m" == *-cloud || "$m" == *:cloud || "$m" == *-cloud:* || "$m" == *cloud/* ]] && return 1
  return 0
}
# ONE JSON LIST OF MODELS, IN BOTH SHAPES AND WITHOUT A PARSER -- INTELLIGENCE's
# reader: ollama answers {"models":[{"name":…}]} and everything OpenAI-shaped
# {"data":[{"id":…}]}, so the keys those two use are looked for, an offset and
# then a window, which on a runner holding dozens of models is the difference
# between a millisecond and a stutter
vc_models_from() {   # vc_models_from BODY -> VCM
  local b="$1" rest v k pre win
  local -i n at
  VCM=()
  for k in name id model; do
    rest="$b"; VCM=(); n=0
    while [[ "$rest" == *"\"$k\""* ]]; do
      pre="${rest%%\"$k\"*}"
      at=$(( ${#pre} + ${#k} + 2 ))
      win="${rest[$at,$(( at + 200 ))]}"
      rest="${rest[$at,-1]}"
      win="${win#*:}"; win="${win## }"
      [[ "$win" == '"'* ]] || continue
      v="${win#\"}"; v="${v%%\"*}"
      [[ -n "$v" ]] || continue
      [[ " ${VCM[*]} " == *" $v "* ]] && continue
      VCM+=("${v[0,63]}"); (( n++ ))
      (( n >= 32 )) && break
    done
    (( ${#VCM[@]} )) && return 0
  done
  return 0
}
# THE LIST IS FETCHED BEHIND THE PICTURE.  A runner that is up and wedged is
# exactly the case a plain fetch would hang the cabinet on, so the request
# runs in the background on a two-second leash and the page reads its answer
# when it lands.
vc_list_start() {   # vc_list_start R
  local -i r=$1
  (( ${+commands[curl]} )) || return 1
  gt_tmp alien-visitor-list || return 1
  VC_PLOG="$GTMP"; VC_PRUN=$r; VC_PSTART=$EPOCHREALTIME
  { curl -fsS --max-time 2 -H 'Accept: application/json' -- \
      "http://127.0.0.1:${VC_RPORT[$r]}${VC_RAPI[$r]}" 2>/dev/null
    _rc=$?; print -r -- ""; print -r -- "__RC__ $_rc" } >> "$VC_PLOG" 2>/dev/null </dev/null &!
  VC_PPID=$!
  return 0
}
vc_list_read() {   # the fetched list, once it has landed · the models he can talk with, and one chosen
  local body m
  local -a keep
  local -i i
  [[ -n "$VC_PLOG" ]] || return 0
  body="$(<"$VC_PLOG")" 2>/dev/null || body=''
  if [[ "$body" != *$'\n__RC__ '* ]]; then
    (( $EPOCHREALTIME - VC_PSTART > 4.0 )) || return 0      # still coming
    body=''                                                 # ...or never will
  fi
  rm -f "$VC_PLOG" 2>/dev/null; VC_PLOG=''; VC_PPID=0
  body="${body%$'\n__RC__ '*}"
  # A PORT THAT ANSWERS IS NOT YET A RUNNER.  8080 is every web framework's
  # favourite, and a server that is not listing models is something else
  # standing on it -- passed over, not named as a runner with nothing in it.
  if [[ "$body" != *'"models"'* && "$body" != *'"data"'* ]]; then
    VC_EMPTY[$VC_PRUN]=$EPOCHREALTIME; VC_PACE=0.3
    (( VC_RUN == VC_PRUN )) && { VC_RUN=-1; VC_MODELS=(); VC_MODEL=''; }
    return 0
  fi
  vc_models_from "$body"
  for m in "${VCM[@]}"; do vc_chat_model "$m" && keep+=("$m"); done
  if (( ! ${#keep[@]} )); then
    # up, and holding nothing he can talk with · said, and the next one asked soon
    VC_EMPTY[$VC_PRUN]=$EPOCHREALTIME; VC_IDLE=$VC_PRUN; VC_PACE=0.3
    (( VC_RUN == VC_PRUN )) && { VC_RUN=-1; VC_MODELS=(); VC_MODEL=''; }
    return 0
  fi
  VC_RUN=$VC_PRUN; VC_MODELS=("${keep[@]}"); VC_LISTED=$EPOCHREALTIME; VC_IDLE=-1; VC_SETUP=''
  # THE MODEL HE WAS TALKING THROUGH IS KEPT while the runner still lists it,
  # so his voice does not change halfway through a conversation
  for (( i = 0; i < ${#VC_MODELS[@]}; i++ )); do [[ "${VC_MODELS[$i]}" == "$VC_MODEL" ]] && return 0; done
  VC_MODEL="${VC_MODELS[0]:-}"
  return 0
}
vc_probe() {   # vc_probe — paced · every four seconds while his page is up
  local -i i idle=-1
  if [[ -n "$VC_PLOG" ]]; then vc_list_read; return 0; fi
  (( $EPOCHREALTIME - VC_PROBE_AT < VC_PACE )) && return 0
  VC_PROBE_AT=$EPOCHREALTIME; VC_PACE=4.0
  [[ "$VC_STATE" == run ]] && return 0          # he is mid-sentence · the runner is plainly up
  # THE ONE HE IS ALREADY TALKING THROUGH, while it stands -- its list asked
  # again twice a minute, so a model taken off it meanwhile is noticed
  if (( VC_RUN >= 0 )) && [[ -n "$VC_MODEL" ]] && vc_port_up ${VC_RPORT[$VC_RUN]}; then
    (( $EPOCHREALTIME - VC_LISTED > 30.0 )) && vc_list_start $VC_RUN
    return 0
  fi
  # ...AND OTHERWISE THE FIRST THAT IS UP, skipping any that answered with
  # nothing in the last half minute so a runner further down still gets asked
  for (( i = 0; i < 4; i++ )); do
    vc_port_up ${VC_RPORT[$i]} || continue
    if (( $EPOCHREALTIME - ${VC_EMPTY[$i]:-0} < 30.0 )); then
      (( idle < 0 && VC_IDLE == i )) && idle=$i
      continue
    fi
    vc_list_start $i
    return 0
  done
  VC_RUN=-1; VC_MODELS=(); VC_MODEL=''; VC_IDLE=$idle
  vc_setup
  return 0
}
# WHAT IS MISSING, when he cannot talk: a runner up but holding nothing he can
# talk with, or nothing on the Mac at all, is a model to INSTALL; a runner on
# the Mac that is not running is one to START.  Asked of the command table and
# the two runners that come as apps, which is lookups, not forks.
vc_installed() {   # 0 when some local runner is on this Mac
  (( ${+commands[ollama]} || ${+commands[llama-server]} || ${+commands[lms]} || ${+commands[mlx_lm.server]} )) && return 0
  [[ -d /Applications/Ollama.app || -d "/Applications/LM Studio.app" \
  || -d "$HOME/Applications/Ollama.app" || -d "$HOME/Applications/LM Studio.app" ]]
}
vc_setup() {   # -> VC_SETUP
  if (( VC_RUN >= 0 )) && [[ -n "$VC_MODEL" ]]; then VC_SETUP=''
  elif (( VC_IDLE >= 0 )) || ! vc_installed; then VC_SETUP='install'
  else VC_SETUP='start'; fi
  return 0
}
vc_setup_say() {   # -> VCP the sentence the box says for VC_SETUP
  case "$VC_SETUP" in
    install) VCP="he can't talk yet · he needs a local model · install one on INTELLIGENCE's LOCAL page" ;;
    start)   VCP="he can't talk right now · start a local model on INTELLIGENCE's LOCAL page" ;;
    *)       VCP='' ;;
  esac
  return 0
}

# ── HIS NOTES · written from the dotfiles themselves ──────────────────────
# GENERATED by gen_notes.py from the hand-written notes and the arcade’s own
# racks · 120 notes (the last, TITLE CARDS, set by hand in the same form) ·
# edit the notes and generate again, not these lines
# written against: system.zsh:015a38cf intelligence.zsh:7f7c12e4 xenogotchi.zsh:d1e238c8 arcade.zsh:6da60ace bootstrap.zsh:edd32d04
typeset -ga VK_TI VK_KW VK_BT VK_TX
VK_TI=(
  'THE HOUSE AT A GLANCE'
  'EVERY FILE IN THE DOTFILES'
  'TERMINAL.COMMAND · THE DOOR'
  'TERMINAL.CONF · THE SETTINGS FILE'
  'TERMINAL.CONF · WHAT EACH KEY DOES'
  'TERMINAL.CONF · THE ARCADE’S KEYS'
  'TERMINAL.SAVE · THE PROGRESS FILE'
  'MOVING TO ANOTHER MAC'
  '.GITIGNORE'
  'BREWFILE · THE TOOLS'
  'SCRIPTS/FIXTURES/SYSTEM · THE INVENTED MAC'
  'SCRIPTS/BOOTSTRAP.ZSH · THE INSTALLER'
  '[N] INSTALL, ON THE GLASS'
  '[U] UNINSTALL'
  'THE TOOLS STEP'
  'THE ~/.ZSHRC BLOCK'
  '00-ALIEN-PATH.ZSH · PATH'
  '10-ALIEN-TERMINAL.ZSH · THE HOOK'
  'WHERE THE HOOK STANDS ASIDE'
  'THE ALIEN LAUNCHER'
  'GETTING OUT, AND GETTING A PLAIN PROMPT'
  'THE STATE FOLDER'
  'LAUNCH OPTIONS FOR terminal.command'
  'POWERING UP'
  'THE POWER-ON SELF TEST'
  'READING SAVE AND CONFIG'
  'THE MENU'
  'THE MACHINE ROWS'
  'THE MIRROR GAUGE AND THE SPECS'
  '[T] TERMINAL · A SHELL IN THE GLASS'
  '[R] RESCAN'
  '[C] CONFIG · THE CABINET’S OWN SETTINGS'
  'CONFIG · SOUND'
  'CONFIG · PHOSPHOR'
  'CONFIG · BEAT'
  'CONFIG · BOOT'
  'CONFIG · SCREEN'
  '[Q] POWER OFF'
  'THE HEADER AND THE CAPTION'
  'THE SKY OVER THE MACHINE'
  'THE COIN DOOR'
  'THE CABINET ITSELF'
  'COLOUR DEPTH · 24-BIT'
  'KEYS THAT WORK EVERYWHERE'
  'MACHINES ARE PAGE PACKS'
  'THE VISITOR'
  'TALKING TO THE VISITOR'
  'WHAT HE NEEDS TO TALK'
  'WHAT STAYS PRIVATE WHEN YOU TALK TO HIM'
  'HOW THE VISITOR KNOWS THE HOUSE'
  'THE VISITOR’S WARDROBE'
  'SYSTEM'
  'SYSTEM · OVERVIEW'
  'SYSTEM · PROCESSOR'
  'SYSTEM · MEMORY'
  'SYSTEM · STORAGE'
  'SYSTEM · NETWORK'
  'SYSTEM · POWER'
  'SYSTEM · PROCESSES'
  'SYSTEM · HARDWARE'
  'HOW SYSTEM READS THE MAC'
  'INTELLIGENCE'
  'INTELLIGENCE · CLOUD'
  'THE GATE'
  'INTELLIGENCE · LOCAL'
  'WHICH LOCAL MODEL TO INSTALL'
  'CONSOLE'
  'OPENCODE'
  'INTELLIGENCE · ROUTE'
  'INTELLIGENCE · BENCH'
  'INTELLIGENCE · PROMPTS AND REWRITE'
  'INTELLIGENCE · HISTORY AND KEYS'
  'THE EGRESS GUARD'
  'YOUR ACCOUNTS ARE NEVER AT RISK'
  'RUNNERS EXPLAINED'
  'XENOGOTCHI'
  'XENOGOTCHI · CARING FOR YOUR ANIMAL'
  'XENOGOTCHI · VITALS'
  'XENOGOTCHI · CREDITS'
  'XENOGOTCHI · THE STORE'
  'XENOGOTCHI · ADOPT'
  'XENOGOTCHI · THE SPECIES'
  'XENOGOTCHI · STATS, THE ROSTER'
  'XENOGOTCHI · LETTING ONE GO'
  'XENOGOTCHI · AGE AND LIFE STAGES'
  'XENOGOTCHI · WHILE YOU ARE AWAY'
  'XENOGOTCHI · GENETICS AND BREEDS'
  'XENOGOTCHI · THE ROOM AND ITS MOODS'
  'XENOGOTCHI · HOW IT IS SAVED'
  'ARCADE'
  'THE TWELVE GAMES'
  'PLAYING A ROUND'
  'NEON SNAKE, BLOCK FALL, VOID PONG, BRICK NOVA'
  'STAR RAIDER, GRID RUNNER, LASER DODGE, NIGHT DRIVE'
  'LIGHT CYCLE, PLASMA BALL, ASTRO DRIFT, BEAT GRID'
  'ARCADE COINS'
  'RUNGS AND UNLOCKING THEM'
  'HIGH SCORES'
  'THE MARKETPLACE'
  'WHAT THE GAMES COST'
  'THE WARDROBE'
  'THE STYLE BONUS'
  'THE TROPHY ROOM'
  'THE LEDGER'
  'ARCADE SETTINGS'
  'ATTRACT MODE'
  'THE COIN DOOR SERVICE MENU'
  'ALIEN DYNAMICS AND THE MODEL PLATES'
  'CHANGING A SETTING'
  'IT DID NOT OPEN WHEN I OPENED TERMINAL'
  'IT FEELS SLOW OR CHOPPY'
  'THE COLOURS LOOK WRONG'
  'THE WINDOW CLOSED OR A MACHINE WILL NOT OPEN'
  'EDITING THE DOTFILES'
  'REMOVING EVERYTHING'
  'THE WARDROBE · HATS, AND WHAT THEY COST'
  'THE WARDROBE · GLASSES, AND WHAT THEY COST'
  'THE WARDROBE · SMOKES, AND WHAT THEY COST'
  'THE WARDROBE · AURAS, AND WHAT THEY COST'
  'TITLE CARDS'
)
VK_KW=(
  'overview dotfiles repo suite alien everything contents house map folder tour summary glance'
  'files list tree layout structure directory folders file repo contents every dotfiles'
  'terminal command door cabinet main file launcher double click zsh standalone open start'
  'terminal conf config file settings configuration preferences options edit hand format'
  'conf keys settings list sound phosphor beat boot screen key meanings values options setting names defaults colour intelligence open unused retired old terminal'
  'arcade settings attract freeplay difficulty player name conf scanlines closeexit fpscap unused retired terminal keys'
  'terminal save file progress saved game coins stored pet location backup'
  'new mac another move transfer carry copy save migrate backup restore sync second machine moving'
  'gitignore git commit version control ignored local files committed'
  'brewfile homebrew brew packages dependencies tools ollama llama cpp opencode node installed'
  'fixtures mock demo moonbase fake machine test data probe expected scripts system invented mac'
  'bootstrap zsh installer install setup set installing link symlink scripts'
  'install row key page installing menu installed link leaves first run fresh mac kn glass'
  'uninstall remove key take undo install reset hook put back clean ku'
  'tools homebrew install brew bundle ollama service login phase missing step'
  'zshrc block marked shell config added remove source conf'
  'path 00 alien local bin homebrew conf setup command found zsh'
  'hook 10 alien terminal new window opens auto open startup every shell switch turn stop launch zsh'
  'hook guards tmux ssh vscode warp hyper scripts pipes editor terminal open didn opt stands aside'
  'alien command launcher local bin open prompt start terminal'
  'exit quit leave escape stuck locked plain prompt close turn disable emergency getting'
  'state folder local alien dealing flag house token files xdg'
  'flags options arguments fast probe check plain sharp fps back 256 true command line debug launch terminal'
  'power startup boot opening intro launch sequence start long skip ceremony splash powering'
  'self test post boot card bios checks cpu ram disk readings startup screen diagnostics power'
  'save found config detected boot files loaded uploaded reading'
  'menu main home screen rows suite machines list navigate choose select arrow keys jk'
  'machine rows system row intelligence xenogotchi arcade readings greyed absent folder'
  'mirror gauge links linked waiting specs cpu memory disk readout installed'
  'key terminal row shell prompt command line run commands detach scrollback zsh glass kt'
  'rescan key refresh read reload re scan update readings detect kr'
  'config key settings preferences options page change configure popup kc cabinet'
  'sound audio mute silence beeps noise turn effects blips config'
  'phosphor soft sharp blocks bleed crisp sprites look blurry pixel render style config'
  'beat frame rate fps speed smoothness 30 60 120 auto performance laggy slow choppy config'
  'boot fast full skip startup opening ceremony faster start setting config'
  'screen fill float full fullscreen window size bigger stretch whole layout config'
  'key power quit shut turn exit cabinet close leave gate kq'
  'header title bar caption top moon phase zodiac clock time shown waxing waning say'
  'sky sun moon night day twilight phase real timezone location sunset sunrise machine'
  'coin door bottom message greeting toast status line say good morning'
  'cabinet look marquee neon bezel crt scanlines tube design graphics stars shooting star dust synthwave visuals'
  'colour color 24 bit truecolor 256 colors palette look wrong terminal app ink depth'
  'keys controls keyboard shortcuts navigation escape back key arrows wheel mouse work everywhere'
  'pack page machines load sourced plugin machine files scripts suite window failed crash packs'
  'visitor alien mascot name key page'
  'talk chat ask box bubble type conversation enter speech key talking visitor'
  'talk cannot model local needs answering install start won'
  'privacy private local leave sent cloud secure logged saved conversation data stays talk'
  'trained notes knowledge learned remember memory accurate visitor knows house'
  'wardrobe outfit clothes hat glasses smoke aura dress wearing vanity items cosmetic visitor'
  'system monitor nx 88 activity stats performance machine health cpu usage resources'
  'overview scope radar sweep tapes gauges ticker contacts dots circle system'
  'processor cpu cores load busy performance efficiency time system'
  'memory ram swap pressure wired compressed app cache system'
  'storage disk volumes drives space full free reads writes throughput system'
  'network wifi ethernet internet traffic bandwidth interfaces sockets ip vpn connections system'
  'power battery charge health cycles temperature charging plugged time remaining mouse keyboard system'
  'processes tasks apps running top sort kill table cpu list system'
  'hardware model chip serial mac specs uptime boot time system'
  'system work sampling refresh readings commands sysctl vm stat top ioreg pmset netstat often reads mac'
  'intelligence ai agents models iq 88 llm tools command lines switchboard'
  'cloud agents claude code codex antigravity grok build install agent open page coding intelligence'
  'gate install line confirm run runs exact command approval job strip stop'
  'local models runner ollama llama cpp lm studio mlx pull model download install start page offline ai intelligence'
  'model recommended best list qwen gpt oss ram needed memory curated models size local install'
  'console chat model local talk tokens per second speed save new session'
  'opencode coding agent local run model open code'
  'route router routing auto litellm proxy prefer local balanced cloud budget cap spend cost intelligence'
  'bench compare side benchmark prompt best agents intelligence'
  'prompts library prompt templates rewrite improve engineering copy rules intelligence'
  'history log ran keys api environment variables credentials providers signed key set intelligence'
  'egress guard secrets leak safety privacy blocked keep local credentials check sensitive'
  'account subscription login sign token oauth safe ban terms risk credentials reuse accounts never'
  'ollama runner llama server lm studio mlx port 11434 8080 gguf serve model local runners explained'
  'xenogotchi pet animal virtual tamagotchi adoption centre xg creature cat companion'
  'feed water groom treat play nap pet scoop litter care keys home look take hungry xenogotchi caring animal'
  'vitals stats food hydration water mood bond coat pep energy health meters needs bars mean xenogotchi'
  'pet credits xenogotchi earn money care streak gifts red dot catches pay'
  'store shop buy kibble tuna feast yarn orb pointer bed cover dish set core tuning prices galley toy chest xenogotchi'
  'adopt adoption new pet intake litter arrivals sign certificate name welcome home xenogotchi'
  'species animals available dog rabbit hamster fox turtle hedgehog duck frog snake owl pig axolotl guinea ferret rat chinchilla goat gecko sugar glider parrot penguin glorp xenomorph void drifter kinds xenogotchi'
  'stats roster pets multiple swap pet rename vet release papers key list animals xenogotchi'
  'release give delete pet remove abandon key xenogotchi letting'
  'age grow grows kitten baby senior life stage lifespan old dies xenogotchi stages'
  'away time left alone vacation weekend neglect offline closed cabinet passes xenogotchi'
  'genetics coat colour breed pattern eyes odd temperament seed colorway looks xenogotchi breeds'
  'room home page engine reactor core porthole behaviour mood emotions sleeping xenogotchi moods'
  'xenogotchi save pet pets active saved animal lost'
  'arcade games play nx 88 cabinets menu gaming game'
  'game list games available snake block fall void pong brick nova star raider grid runner laser dodge night drive light cycle plasma ball astro drift beat titles twelve'
  'round start game insert coin pause cash quit controls general key players playing'
  'neon snake controls block fall void pong brick nova play tetris breakout'
  'star raider controls grid runner laser dodge night drive shooter maze pacman racing play'
  'light cycle controls plasma ball astro drift beat grid tron pinball asteroids rhythm game play'
  'coins credits coin bank money earn payout broke cost play arcade'
  'rungs difficulty rookie normal expert insane unlock locked harder levels multiplier unlocking'
  'high scores hall fame leaderboard top records best score key names tables initials'
  'marketplace market buy game rent shop store key prices machine rental wardrobe racks'
  'game prices cost games price list buy cheapest expensive'
  'wardrobe hats glasses smokes auras outfits cosmetics dress visitor rarity legendary epic rare items clothes shop'
  'style bonus coins outfit wear percent rarity full'
  'trophies trophy room badges achievements awards secret key konami'
  'ledger statistics stats numbers games played key totals favourite game'
  'arcade settings options key sound fx attract mode free play reset bank scores self test operator'
  'attract demo reel idle screensaver bots playing demonstrator mode'
  'service menu operator coin door secret backslash serial cheat rigged switches hidden'
  'alien dynamics 1984 lore model numbers ad nx 88 iq xg synthwave series brand story company plates'
  'change setting turn set configure adjust customize customise changing'
  'doesn open opening hook working new window prompt auto start broken didn launch launching opened terminal'
  'slow laggy choppy stutter performance fps high cpu battery drain smooth feels'
  'colors wrong colours washed navy 256 terminal app font glyphs broken boxes look odd braille'
  'crash closed disappeared error broken open failed load pack bug went wrong window machine'
  'edit files modify change code update suite customise symlinks links point repo git pull editing dotfiles'
  'uninstall completely remove everything delete suite clean mac put back traces removing'
  'price cost buy wardrobe catalogue list hats hat top crown helmet cap antenna antlers band bandana beanie beret boater bowler bucket cat chef circlet cone cowboy crescent crest devil diving earmuffs ears fedora fez flat flower flying graduation great halo hard headlamp headphones helm horns jester kabuto laurel mohawk moon mothership newsboy night party pharaoh phoenix pie pilot pirate pom pork propeller ring samurai santa saturn saucer shower snapback solar sombrero space star sweatband tiara tinfoil traffic ushanka viking visor wizard wreath'
  'price cost buy wardrobe catalogue list glasses specs shades sunglasses goggles monocle eyewear 3d aviators binoculars blindfold browline butterfly cat clip compound eye eyes frames half headset heart horn hypno kaleidoscope laser mask mirrored moons neon nez night ons opera oracle patch pince pixel ray rims rose round safety scouter scuba snow spirals sport star steampunk supernova swim thick third tinted vision visitor visor vr wayfarers welding wire wraps'
  'price cost buy wardrobe catalogue list smokes smoke pipe cigar cigarette hookah wisp blunt bong briar bubble calabash candy chaser churchwarden cigarillo cloud clove cob corn cosmic dab dragon dugout ember eternal hand holder hose incense joint matchstick meerschaum peace pen rig rolled stick vape'
  'price cost buy wardrobe catalogue list auras aura weather sparkles snow storm aurora effects air arcs bank black blossom cherry comet crystal drive drizzle dust earth fall fire fireflies fireworks fog galaxy glitch growth hex hole ice leaf meteor motes nebula plasma pool radioactive rain rift ring sandstorm shadow shower sigil snowfall soul spiral stardust static sunbeams supernova tendrils thunderstorm time warp wisps'
  'title card cards press any key start screen front splash face opening open machine walk in wake'
)
VK_BT=(
  'dotfiles alien suite dynamics synthwave arcade cabinet runs mac terminal written entirely zsh door command carries whole file behind stand four machines scripts system monitor intelligence ai lines local models xenogotchi adoption centre animal twelve games house holds conf settings save progress bootstrap installer three shell files home hook brewfile gitignore menu kv steps aside visitor page'
  'top folder terminal command door whole cabinet conf every setting save machine progress lives brewfile homebrew tools gitignore scripts bootstrap zsh installer suite four machines page packs system intelligence xenogotchi arcade fixtures invented mac demos tests home config 00 alien path 10 shell hooks local bin launcher links three'
  'terminal command suite file work double click cabinet powers filling window bigger machine floats centred night around written zsh macos ships ship python runs fresh mac nothing installed carries everything draws visitor sun moon included copy dropped desktop half cloned repo still comes reads knows install rest model ad series synthwave'
  'terminal conf sits beside command holds every setting suite per line key value comments last spelling wins program leaves alone door hook arcade share file safely safe delete hand edit commit though gitignore keeps local default cabinet rewrites lines writing whole temporary copy moving crash never torn everything runs defaults'
  'door reads five keys power sound phosphor soft sharp beat auto 30 60 120 frames second boot full fast screen float fill config page kc menu changes writes back terminal hook switch shell decide whether new window opens cabinet arcade keeps four well every key file read retired ones older versions colour intelligence open dropped next time'
  'arcade keeps four keys terminal conf attract demo reel 20 idle seconds freeplay play without coins earn none difficulty rung last started rookie normal expert insane player name high scores signed empty uses mac user yes true mean settings room flips free writes back three older python kept scanlines closeexit fpscap belong door draws tube decides powering config beat sets rate drops whenever file'
  'save terminal cabinet looks beside command dotfiles folder first local state alien home self test reading config lines say found holds every machine progress arcade coin bank high score tables rungs rentals trophies wardrobe xenogotchi animal signed dotted path value line credits 640 read hand edited machines write whole temporary file move place keep never full gitignore keeps git'
  'progress travels file copy terminal save conf settings dotfiles folder beside command new mac power self test reading config section says whether found animal name coin bank copied cabinet running named card read next nothing overwrites meanwhile boot fast door line run install menu link shell hooks'
  'gitignore keeps machine files git terminal save conf temp lock macos ds store working clutter backups delete folder suite runs defaults without either file installer writes switch needs fresh clone works'
  'brewfile names homebrew packages machines reach nothing ollama holds local model memory answers port 11434 llama cpp runner server per gguf file 8080 opencode coding agent runs press intelligence page node codex installs npm everything suite uses already ships macos zsh curl perl sysctl vm stat top ioreg pmset netstat osascript afplay pbcopy installer tools step'
  'scripts fixtures system machine looks demo mode invented 16 inch m3 max called moonbase 36 gb six days thirds disk little swap link cell charging plain data files sysctl vm stat df netstat ioreg pmset ps readings pictures repo reproducible leak nothing real mac command fixture answer runs probe expected every reading taken check monitor still reads byte'
  'scripts bootstrap zsh jobs first terminal open cabinet links three files home folder adds marked block zshrc sources conf turns hook switch second puts tools machines lean place homebrew missing brewfile ollama service starts login never replaces reorders writes outside marks keeps copy called pre alien touching safe run twice menu kn install runs glass'
  'house fully linked menu second row kn install missing beside opens installer page glass five checks question link leaves write block switch hook ky tools shows exact lines step run hands whole terminal homebrew asks password return later back printed answer becomes ku uninstall'
  'everything linked install row becomes ku uninstall installer asked question takes marked block back zshrc unlinks three files turns hook switch ky copy kept pre alien left alone homebrew tools ollama llama cpp opencode node login service belong removed gone'
  'installer tools step interactive purpose homebrew asks password return cabinet steps aside hands real terminal comes back installs none runs brewfile ollama llama cpp opencode node registers services runner 127 11434 every login shows exact lines run four cloud agents installed signs account intelligence page time behind gate'
  'installer appends block zshrc line reading alien dotfiles read every zsh file config conf linked shell files live nothing outside marks touched uninstall takes deleting lines hand works'
  'home config zsh conf 00 alien path runs every new shell hook puts local bin folder exists already launcher works prompt adds homebrew installed nothing put yet intelligence find ollama friends name never moves entry change named programs wins'
  'hook home config zsh conf 10 alien terminal opens cabinet whenever new shell person sitting otherwise switch exactly means window plain prompt page kn install turns ku uninstall edit line hand reads eye never runs replace quitting leaves written fail toward unsure'
  'hook refuses open cabinet shell person terminal script command pipe scp rsync stays tmux screen panes ssh sessions terminals inside vs code warp hyper never opens suite glass opening machines tabs started alien set override switch repo cannot found link nothing'
  'home local bin alien linked installer typing prompt opens cabinet new window hook finds repo link rather path written install time move dotfiles run nothing told'
  'kq anywhere opens power question ky shuts cabinet stop new terminal windows opening turn hook switch edit conf reads ku uninstall menu takes block zshrc config page single plain shell start alien set never tmux ssh editor still reaches prompt'
  'suite keeps short lived facts local state alien home folder xdg set house token says tabs belong together brief dealing flag stops cabinet opens opening cabinets terminal save beside command note machine got ready power brings down left ordinary way file changes warming installer clears expiring crash never leave new shells without'
  'terminal command takes launch options mostly testing paint frame exit card without ceremony text report found probe glyph test check force xterm 256 colour palette 24 bit sprites drawn sharp ink pin rate skip power mock read invented machine instead mac pictures reproducible alien save points different file'
  'every opening starts stars alone couple honest seconds machine loads behind folder opens ready system first reading intelligence asked agent version xenogotchi room built ready preload loading warm tube warms ember line raster unfolding picture settling comes power self test card menu thirteen key skips ceremony finished cursor kp pauses read boot fast config page powering plays backwards collapses pinches dot burns'
  'self test card says cabinet found mac line time cpu ram disk panel window size refresh rate beat frame ladder ink 24 bit truecolor xterm 256 palette term shell zsh version utf os snd silent sound cannot play sky latitude longitude taken zone four machine slots online glass absent finally reading save config whether terminal conf kr rescan menu runs'
  'last block self test reading save config line terminal conf found folder unreadable says whose progress animal name coin bank beside machines settings holds boot fast card skipped door instead example copied another mac picked'
  'menu list move act top suite box kt terminal kn install ku uninstall installed kr rescan kc config reachable letter machines lists system intelligence xenogotchi arcade live reading beside load average ai agents animal name health coin bank machine walks kv opens visitor page kq powers says door'
  'machine row carries live reading system shows load intelligence ai agents mac xenogotchi animal room health percent pet arcade coins bank save yet whose file missing scripts suite greys says needs rather opening onto nothing every page pack opens inside glass tab'
  'menu gauge shows files home linked folder point back repo means house installed otherwise says waiting offers install link points somewhere counted sit five readings mac cpu cores memory disk bar turns warmer fills display panel rate animations paced operating system'
  'kt terminal opens login shell inside glass cabinet neon around profile path prompt new window give hook stands aside another detaches returns menu still running row says long back typing exit ends mouse wheel scrolls page move resized reflow reopen size'
  'kr rescan reads machine shows self test card specs display frame rate files folder links home save conf read counted settings applied power since restart copying installing moving window another'
  'kc config folds panel menu five settings every machine feels sound phosphor beat boot screen choose row change km fold away says felt live means restart next power written straight terminal conf keeping line file cannot holds quit coin door'
  'turn sound press kc menu open config move row inside arcade ku flips switch changes saved terminal conf sounds cabinet small noises blips cursor ticks alert played macos system nothing downloaded bundled stay silent pipe plain mode cannot play self test reports'
  'phosphor kc config page chooses lit sprites visitor sun moon drawn soft tube gentle bleed sharp hard blocks ink move row press switch changes saved terminal conf'
  'beat kc config page frame rate whole cabinet runs auto 30 60 120 move row press step changes saved terminal conf governs running display refresh keep otherwise exact divisor stepping quickly frames run long back rung time comfortable seconds feel choppy lower number helps fill mode costs float'
  'boot kc config page full whole opening stars tube warming self test fast straight menu move row press switch unlike settings takes effect next power saved terminal conf coin door still says whether save found'
  'cabinet fill window press kc menu open config move screen row switch float puts back changes saved terminal conf stands whole walls neon bezel coin door middle night around hides frame glass size full included sign keys messages drawn instead pages layout reflow given yet stays fixed centred'
  'kq anywhere asks power shut house ky powers kn keeps powering plays tube stops machines started puts terminal back switches stays open every window tab hook alien launcher opened cabinet left prompt double clicked finder ends command setting decides whether closes conf since change already written'
  'every surface wears title band page name left sky caption right day reads sunny time night moon phase constellation zodiac worked date waxing gibbous capricorn 11 48 pm warmed cooled'
  'sun moon visitor page real cabinet takes latitude longitude mac time zone works whether horizon night eight phases twilight warm card arithmetic python version term worked minute every frame self test sky line shows location'
  'coin door foot cabinet machine talks back nothing happened shows greeting line minute dealt hour pool often name good morning still late key says six seconds fades badge corner surface figure menu mirror'
  'cabinet arcade ported term original py neon tubes breathing walls lit side art bezel machine name control panel carrying key strip coin door light spilling floor glass crt vignette slow bright roll phosphor every page change changes channel tube line unfold settle outside suite starfield rare shooting star little dust drifts pane never lands word'
  'dotfiles draw 24 bit colour exception apple terminal older macos takes xterm 256 palette unless announces truecolor cabinet lifts dark purples choosing nearest colours turn navy self test ink line says launch option force either plain mode draws'
  'keys mean every surface move rows turn pages opens row page letters jump straight back level machine menu suite km leave kq power switch anywhere mouse wheel moves cursor quietly notch never counts press names bar along foot'
  'machine scripts suite page pack file door reads first time open draws inside glass keeps walls tube frame rate keyboard read per session walking back finds exactly left fails load start survives puts last line went wrong coin takes program said printed terminal afterwards run files say belong command'
  'visitor small grey violet alien wide head big dark eyes lives glass cabinet suite mascot knows house kv menu opens page stands middle real sun moon corner wearing whatever arcade put box along foot talk looks press key talks km back'
  'page steps talk box type sends stays live next line typing move caret takes back work shell answer arrives speech bubble right head lit sun moon growing words come last said sits top rule outside wheel read long kx stops mid sentence kn starts conversation'
  'visitor answers model running mac found usual local ports ollama llama cpp lm studio mlx never leaves none installed box says needs install intelligence page start models embed rerank cloud tagged passed cannot chat answer fails loses train thought simply try'
  'nothing say visitor leaves mac request runner 127 written private temporary file readable rather onto command line programs see answer deleted finishes conversation lives cabinet memory kn clears powering forgets cannot run commands open files change settings talk'
  'visitor carries notes dotfiles written files themselves every file page key setting question looks fit sees true mac right current settings whether save config found machines wearing learn new visits remember past conversations cabinet powers say rather guess'
  'everything visitor wears comes arcade marketplace bought coins four slots hats glasses smokes auras weather around 166 items saved terminal save page menu shows outfit moment come back names listed side pixels picture lit light stickers talk bubble never covers keeps card row aura adds'
  'system suite monitor mac eight pages live readings drawn glass model nx 88 menu lists six instruments ko overview kc processor kr memory kd storage kn network kb power tables kp processes kh hardware reading beside open page letter jumps straight ring back list km every machine reads commands macos already changes nothing'
  'overview machine three columns ticker left five tapes history traces map every core network incoming traffic middle radar scope process contact whose distance rim idle innermost ring range size memory holds brightness fades sweep moves means running last reading tail moved busiest mark colour right four gauges watch list returns'
  'processor every core time single busy percentage hides user system idle nice load averages bar grid grows sideways however cores apple silicon efficiency listed first per figures dozen lines python3 present macos publish shell without page still shows totals'
  'memory splits whole activity monitor app wired compressed cached files free hold side figure matching shows swap fitted macos grows swapfiles demand total means little pressure fault page rates processes holding trace'
  'storage lists every volume real device behind largest first full drives carrying read write rates lifetime totals trace reads writes available space taken system figure rather total minus apfs keeps reserve purgeable pool container data volumes shown holding files'
  'network shows link addresses traffic rates traces counts open sockets established listening waiting rest every interface carried busiest first follows default route docking joining vpn moving wi fi ethernet moves page megabytes counted apple million bytes'
  'power battery charge whether charging wall time remaining health design capacity cycle count temperature voltage current crossing terminals low mode paired reports mouse keyboard earbuds mac says rather reading zero per cent'
  'processes every process scrollable table sorted costing summary strip across top bar row relative busiest move cursor page twenty rows wheel scrolls ks cycles sort reads nothing stops changes'
  'hardware mac model chip operating system build kernel core counts boot disk booted long trace along foot cabinet badge shows uptime days standing'
  'system asks macos tools nothing sysctl vm stat df netstat ioreg pmset ps top plus python3 per core split full reading taken every ten seconds background copy picture never freezes takes second bars ease toward new figure tapes record readings actually sixteen minutes history terminal mock reads invented mac scripts fixtures instead'
  'intelligence suite switchboard ai command lines model iq 88 agents mac install actually signed set plus local side disk held memory runner seven pages letter kc cloud kl kr route kb bench kp prompts kh history kk keys console lives rewrite ring climbs back menu installs removes reports every line run shown gate runs'
  'cloud row per agent claude code anthropic antigravity google terminal grok build xai codex openai says run runs binary version model set signed several installs path installed opens inside glass sized brings keyboard back cabinet still running behind ki missing ku removes gate signs account'
  'nothing intelligence assembled behind back ki ku put exact line run glass string roster holds check vendor page wait ky runs kn answered job strip along bottom stays usable kx stops stopping walks process tree pid never pattern hit programs'
  'local lists cursor runners ollama port 11434 llama cpp 8080 lm studio 1234 mlx 8081 models disk moves runner ks starts terminal tab since outlive cabinet ki installs model curated list gate asks chat console opencode kd keeps loaded answers faster ku removes foot page shows costing mac measured system measures memory chip real resident size'
  'local install list curated every model supports tools big enough drive opencode marked mac memory comfortable tight qwen2 coder 7b gb 16 ram smallest still drives well qwen3 8b general reasons first 14b 24 gpt oss 20b 13 openai open reasoning 30b 19 32 mixture experts 32b 20 120b 65 96 figure least needed 64k context file size'
  'console session local model reached chat speaks plain openai shaped endpoint every runner serves numbers beside real rate measured arrived time first token counts types kx stops answer ke picks another kn starts new ks saves whole conversation markdown report downloads folder access files request sit private temporary deleted ends'
  'opencode coding agent suite uses run local models takes openai shaped endpoint provider runner mac model page opens glass pulled becomes rather chat comes brewfile cloud roster runs signing account route ko router'
  'route takes prompt router decide local cloud subscription litellm proxy mac port 4000 three modes set eagerly spends metered call prefer 15 balanced default 28 75 always free tried first per provider daily cap dollars 10 20 none stops runaway loop types checked egress guard rewritten model eight words routed km changes mode kg writes config ko opens full opencode session'
  'bench sends prompt every engine answer single question shows answers side measured times first byte finish run starts empty scratch folder agents read write working directory sandbox agent still runs types kx stops ka asks copies clipboard'
  'prompts library forty three ready shown beside rules leans set twelve transfer wording choose copies clipboard kw opens rewrite turns rough prompt model follow well engineer write types ke picks engine rewrites lands result ka asks'
  'history lists run cabinet session long ended never prompt answer lives memory disk keys shows provider mac carrying environment anthropic openai gemini xai openrouter groq mistral deepseek set key value read printed logged sent length alone tells apart spots typo'
  'egress guard scans cabinet send cloud engine secrets keys credentials fails closed keep prompt local never leans toward blocking block costs keystroke leak cannot undone report names category found value secret sent even rewritten'
  'suite never borrows subscription login cloud agent official command line signed account tool intelligence reads copies proxies reuses tokens value api key installing removing agents gate time vendor install shown first'
  'runner holds model memory answers http mac loopback ollama main port 11434 pulls models name keeps loaded installer registers start login llama cpp server runs gguf file per 8080 lm studio 1234 mlx 8081 apple silicon work suite checks asks list passed every page console visitor talk whichever'
  'xenogotchi adoption centre model xg system watches machine keeps animal adopt name simply lives room real clock fed watered groomed neglected behaviour chosen moment running emotional state menu four pages letter kh home whoever ko store bought credits earned care ka intake night ks stats every signed ring back row shows health'
  'look animal open xenogotchi menu home kh lives kf feeds meal pantry kw freshens water kg grooms full groom every half hour kt gives treat three day kp brings red dot chase arrows kz suggests nap refused tired kb scoops litter box pets though pet often turn ka admires gift left kd changes room decor among bed covers dish sets core colours empty buy kibble pods store'
  'animal vitals run 100 food bowl hyd water mood bond attached coat grooming pep energy health plus litter box meter drops red runs low keeping 35 whole day earns care streak letting fall breaks costs little falls kv stats takes ship vet'
  'xenogotchi credits separate arcade coins earned care never bought local day every vital stayed 35 pays 10 extends streak treat first pet ten minutes pay admiring gift animal left 15 catching red dot three catches daily roll resets catch caps may leave new spent store vet'
  'store catalogue three departments galley kibble pods 10 six meals pantry space tuna 25 food 40 mood nebula feast 60 15 toy chest kept good yarn ball 30 red dot runs longer hover orb company away holds photon pointer 80 sharper easier catch room bed cover 120 new colourway first naps restore dish set 50 core tuning reactor burns colour walk buys sheet right shows item animal left'
  'adopt open xenogotchi choose menu ka pages home admires gift instead intake night four arrivals dealt genetics deck stall paperwork temperament eyes life stage age left walk stalls deal another litter type name twelve letters certificate sign field signs light room doors hold species time hours wall clock mac save carried fresh house opens first'
  'twenty five species arrive shipments cat first dog second rabbit hamster fox turtle hedgehog duck frog snake owl pig axolotl guinea ferret rat chinchilla goat gecko sugar glider parrot penguin earth three glorp xenomorph void drifter lifespan years sixty ninety nine arrival comes seed animal already signed keeps written save'
  'stats page whole house every animal signed papers choose brings room time kn renames kv takes vet 45 credits treats sick anyway pay kr asks whether'
  'releasing animal xenogotchi cannot undone asks screen cabinet powers ky kn keeps released lines leave save short record stays place file honest house'
  'every animal lifespan cat seventeen years give take fifteen per cent seed ages wall clock day comes home stage fraction span six kitten junior young mature senior grows smoothly size life past full grown broadens draws greys little arrivals come age mostly sometimes overlooked'
  'time passes animal cabinet closed charged next powers first 48 hours away count full quarter rate weekend earns hungry theatrical never tragedy absence capped 45 days however long gone jump 120 read wrong clock rather lost pet nothing hover orb keeps mood'
  'coat dealt picked colourway drifts hue saturation value animal seed pattern eye colour chance odd eyes ear tail build temperament hash forever species breeds decide rest may set size finished words twelve colours written save stays creature even decks change later'
  'animal lives ship engine room lit banded reactor column throws teal light across deck porthole showing suite sky nothing scripted needs temperament hour feed running emotional state winning emotion picks next content roams potters chases straight dish bed bored repeating sleeps night bouts filled screen whole shows floating cabinet close'
  'every animal lives xenogotchi section terminal save active says room pets name species breed colours vitals dotted line file read hand edited rewrites lines whole atomically copies machine untouched cannot fully never written roster top level still loads'
  'arcade model nx 88 holds twelve cabinets coin game bank daily token high score table every rung machine marketplace trophy room service menu behind held key lists games five rooms scores ledger back door choose plays opens walk letters jump kb kh ka kl ks settings kt ku sound km'
  'arcade twelve games neon snake block fall puzzle void pong sports players brick nova action star raider shooter grid runner maze laser dodge reflex night drive racing light cycle arena plasma ball pinball astro drift space beat rhythm start others bought outright rented marketplace open menu choose plays board fitted glass points scaled back original pace tables stay fair window size'
  'choosing game opens rung page pick rookie normal expert insane inserts coin starts player round allows void pong light cycle coins every kp pauses kq cashes ending paying earned score ranked straight table initials type since arcade knows payout window adds'
  'neon snake arrows steer eat fast build chain worth five tail block fall move rotates drops kspace slams kc holds piece back later clear four lines void pong paddle photon past machine post play three misses ends players left right brick nova launches wall catch capsules km splits every ball field'
  'star raider move kspace fires hold line formation descends ones peel dive worth double grid runner arrows run maze carved fresh every level eat dodge daemons big nodes turn edible laser sixty seconds steering away beams rails flash fire blinks clear night drive steer boosts eases passing clean fills nitro bottle spends road ahead dealt'
  'light cycle arrows turn leave wall behind box rider kills players race plasma ball work flippers kspace pulls plunger kz kx nudge table carefully astro drift thrusts fires kh jumps hyperspace might kind momentum brakes saucer beat grid four lanes strike line gold notes perfect hollow ones three hits'
  'earn arcade coins playing every round pays back score divided machine rate plus 25 new record 10 top five finish visitor style bonus multiplied rung half rookie normal twice expert three times insane trophies pay bank kt menu claims daily token day costs coin players starts holds 999 free play operator rigged service mode nothing'
  'every machine four rungs rookie gentle pace edges wrap gems linger normal default walls fatal open start expert quicker hazards grid opens best reaches target score 400 coins insane brutal speed across minefield 900 rung high table pays half three times last started remembered terminal conf arcade difficulty'
  'kh opens hall fame table five every rung machine change gold silver bronze bar leader fresh arcade seeded tables regulars offs names original always opened beat rows signed player terminal conf mac user name empty reset high scores settings erases'
  'marketplace kb racks cycle games visitor wardrobe hats glasses smokes auras choose game offers buy outright rent meter hour sixth price least coins twenty four hours fifths 16 rental pays exactly owning item buys wears takes kr picks random rack back'
  'prices machine outright coins neon snake free void pong 120 laser dodge 160 brick nova 220 grid runner 300 night drive 400 plasma ball 550 astro drift 740 star raider 000 block fall 360 light cycle 840 beat 500 renting costs sixth price hour fifths day choosing menu opens buy rent window'
  'wardrobe dresses visitor 59 hats 45 glasses 27 smokes 35 auras 166 items across six rarities common classic uncommon rare epic legendary bought arcade coins marketplace pixels picture lit light aura weather around throws save keeps receipt every item worn per slot shown page stands beside payout window earned'
  'visitor wears pays every arcade round earnings style bonus adds item rarity common classic uncommon rare epic legendary filling four slots always least coin current outfit total mac right shows payout window added rung multiplier grows harder rungs'
  'ka opens trophy room hundred ninety trophies paying coins earned shelves locked game arcade whole secrets check run ended save buying dressing opening earn secret ones round scores nothing wearing mothership hat aura finding service door certain classic code typed menu playing three morning'
  'kl opens ledger numbers save always knew columns figures runs coins earned bank daily tokens machines owned rungs opened among every machine bar tallest keep back line naming play'
  'ks opens settings sound fx house switch config throws attract mode demo reel 20 seconds idle free play nothing earn coins reset coin bank back 10 earned total cleared high scores erase hall fame self test colour bars input glyph check games resets ask first tube frame rate window door'
  'twenty seconds nobody keys arcade starts selling logo today best machine time played demonstrator play owns visitor outfit first key wakes demonstrators meant competent perfect attract mode settings terminal conf turns title card logo opened'
  'every nx 88 arcade hides service switch behind coin door hold backslash key menu swings open punch serial machine plate self test shows operator switches rig pays coins sets records bookkeeping rows'
  'everything house wears plate alien dynamics believe hardware maker 1984 cabinet synthwave series door terminal model ad config panel system arcade nx 88s intelligence iq 88 xenogotchi xg machine name bezel stands glass sits lip palette neon crt night outside every surface whole suite reads'
  'settings keypress away kc config menu sound phosphor frame rate boot screen ks inside arcade attract mode free play write terminal conf straight edit hand key value lines door reads power restart cabinet change page take hook switch set installer uninstall'
  'new window opens cabinet hold installer linked files written zshrc block menu gauge says terminal hook conf shell person tmux screen ssh vs code warp hyper script inside suite started alien links missing open command directly choose kn install launcher prompt whatever switch'
  'cabinet paces beat auto runs display refresh rate otherwise exact divisor finding floor within half second lower config page 30 less work keep screen float rather fill draws every cell big window smaller self test line panel say found picture cached moves drawn frame'
  'self test ink line says whether terminal 24 bit colour xterm 256 palette apple unless announces truecolor darks lifted purples turn navy boxes rules utf locale shell reports system traces braille dots fonts menlo lack font draws sharper door glyph card launch options shows every cabinet uses ruler'
  'machine file missing row greys says needs fails load start cabinet stays puts last line went wrong coin door takes whole program leaves note behind first said printed terminal left looking kr rescan reads folder fix restore'
  'files home folder links back repo editing file live point mirror changes terminal command pack take effect next time cabinet opens every machine read power shell new move run installer launcher hook find progress settings stay save conf version control'
  'ku uninstall takes block zshrc unlinks three files turns hook copy kept pre alien stays remains choose keep dotfiles folder terminal save conf suite state local homebrew tools ollama login service belong removed'
  'wardrobe hats rack marketplace 59 price coins top hat 260 bowler 120 fedora 170 beanie 40 pom 90 propeller 660 tinfoil 600 space helmet 1350 flying saucer 2100 party 60 crown 1600 tiara 800 halo 860 devil horns 940 cat ears 360 laurel wreath 840 moon crescent 1450 star circlet 1100 flower 480 cowboy 460 hard 150 chef 300 pirate 960 viking helm 1000 wizard 1200 graduation cap 520 pilot 540 headlamp 420 traffic cone 640 santa 400 ushanka 340 bucket beret 280 night 160 sombrero 760 bandana 70 fez 180 snapback 130 visor 320 headphones 560 mohawk 700 antenna band 500 flat 140 newsboy 190 pork pie 210 boater 240 sweatband 100 shower 380 earmuffs 440 antlers 740 jester 900 pharaoh 1150 samurai kabuto 1300 great 1400 diving 1550 mothership 1800 solar 1950 phoenix crest 2250 ring saturn 2400 prices run rarer pieces cost pay bigger style bonus'
  'wardrobe glasses rack marketplace 45 price coins round specs 180 wire frames 120 thick rims 260 half moons 200 pince nez 280 sunglasses wayfarers 350 aviators 490 cat eye 460 mirrored 720 rose tinted 320 3d 40 pixel shades 680 neon 840 heart 600 star 640 ray 1300 hypno spirals 1400 kaleidoscope 1800 monocle 520 patch scouter 1150 goggles 560 swim 380 safety 70 snow 800 welding mask 960 scuba 920 binoculars 1000 night vision 1100 vr headset 1550 laser visor 1600 visitor 2400 browline 150 horn 230 clip ons 100 blindfold sport wraps 420 steampunk 760 butterfly 880 opera 1250 compound eyes 1450 oracle 1950 third 2100 supernova 2250 prices run rarer pieces cost pay bigger style bonus'
  'wardrobe smokes rack marketplace 27 price coins cigarette 70 candy 40 cigar 560 corn cob pipe 180 churchwarden 600 peace 660 bubble 120 incense stick 280 vape pen 420 cloud chaser 800 hookah hose 1350 joint 1000 blunt 940 cosmic 2100 matchstick 100 clove 150 briar cigarillo 190 holder 260 meerschaum 350 hand rolled 490 calabash 740 dugout 860 bong 1100 dab rig 1600 dragon 1800 eternal ember 2400 prices run rarer pieces cost pay bigger style bonus'
  'wardrobe auras rack marketplace 35 price coins fire 860 rain 640 earth 780 air 600 snowfall 560 thunderstorm 1500 fog bank 280 sandstorm 740 cherry blossom 960 sunbeams 820 aurora 1800 stardust 1150 comet 1350 black hole 2300 meteor shower 1300 warp drive 1550 nebula 1200 soul wisps 1250 sigil ring 1400 hex tendrils 1100 radioactive 1000 glitch 1450 plasma arcs 1600 shadow pool 920 drizzle 40 static 180 fireflies 370 dust motes 470 leaf fall 680 ice storm crystal growth supernova 1900 time rift 2050 fireworks 2150 galaxy spiral 2400 prices run rarer pieces cost pay bigger style bonus'
  'every machine opens title card time opened menu name lights night own live picture holds press key breathing system shows processor trace figures verdict intelligence draws switchboard four agents runners line glass pulse running xenogotchi animal door portrait six vitals wants arcade runs attract reel logo goes first wherever left after back km leave kq power switch mouse wheel nothing'
)
VK_TX=(
  'These dotfiles are the ALIEN suite, by ALIEN DYNAMICS: a synthwave arcade cabinet that runs in a Mac terminal, written entirely in zsh. The door is terminal.command, and it carries the whole cabinet in one file. Behind it stand four machines in scripts/suite: SYSTEM (a monitor for the Mac), INTELLIGENCE (AI command lines and local models), XENOGOTCHI (an adoption centre with one animal) and ARCADE (twelve games). The house also holds terminal.conf for settings, terminal.save for progress, scripts/bootstrap.zsh (the installer), three shell files under home/ that hook it into zsh, a Brewfile, and a .gitignore. From the menu, [V] steps aside to the visitor’s page.'
  'At the top of the folder: terminal.command (the door and the whole cabinet), terminal.conf (every setting), terminal.save (every machine’s progress, when it lives here), Brewfile (the Homebrew tools), .gitignore. In scripts/: bootstrap.zsh (the installer), suite/ with the four machines as page packs (system.zsh, intelligence.zsh, xenogotchi.zsh, arcade.zsh), and fixtures/system/ (an invented Mac used for demos and tests). In home/: .config/zsh/conf.d/00-alien-path.zsh and 10-alien-terminal.zsh (the shell hooks), and .local/bin/alien (the launcher). The installer links those three into your home folder.'
  'terminal.command is the way into the suite and the one file that has to work before anything else does. Double-click it and the cabinet powers up, filling the window; make the window bigger and the machine floats centred with the night around it. It is written in zsh because macOS ships zsh and does not ship python, so it runs on a fresh Mac with nothing installed. It carries everything it draws, the visitor and the sun and moon included, so a copy dropped on a desktop or a half-cloned repo still comes up, reads the machine and knows how to install the rest. It is the model AD-1, series SYNTHWAVE.'
  'terminal.conf sits beside terminal.command and holds every setting the suite has, one per line as key = value, with # for comments. The last spelling of a key wins, and a program leaves alone any key it does not know, so the door, the hook and the arcade can share one file safely. It is safe to delete, to hand-edit and to commit, though .gitignore keeps it local by default. The cabinet rewrites only its own lines, writing the whole file to a temporary copy and moving it over, so a crash never leaves a torn line. If there is no conf, everything runs on its defaults.'
  'The door reads five keys at power-up: sound (on or off), phosphor (soft or sharp), beat (auto, 30, 60 or 120 frames a second), boot (full or fast) and screen (float or fill). The CONFIG page ([C] on the menu) changes the same five and writes them back. terminal.hook (on or off) is the switch the shell hook reads to decide whether a new window opens the cabinet; it is not on the CONFIG page. The arcade keeps four keys of its own under arcade. as well. Every key in the file is read by something; two retired ones from older versions, colour and intelligence.open, are dropped the next time CONFIG writes the file.'
  'The arcade keeps four keys in terminal.conf, and all four do something: arcade.attract (the demo reel after 20 idle seconds), arcade.freeplay (play without coins, and earn none), arcade.difficulty (the rung it last started on: 0 ROOKIE, 1 NORMAL, 2 EXPERT, 3 INSANE) and arcade.player, the name your high scores are signed with; when it is empty the arcade uses your Mac user name. On, 1, yes and true all mean on. The arcade’s SETTINGS room flips attract and free play and writes them back. Three keys the older Python arcade kept, arcade.scanlines, arcade.closeexit and arcade.fpscap, belong to the door now (it draws the tube, decides what powering off does, and CONFIG’s BEAT sets the rate), so the arcade drops them whenever it writes the file.'
  'Your save is terminal.save. The cabinet looks for it beside terminal.command in the dotfiles folder first, and if it is not there, in .local/state/alien under your home folder; the self test’s READING SAVE AND CONFIG lines say which one it found. It holds every machine’s progress: the arcade’s coin bank, high-score tables, rungs, rentals, trophies and wardrobe, and every XENOGOTCHI animal you have signed for, one dotted path and value a line, like arcade.credits=640, so it can be read and hand-edited. Machines write it whole to a temporary file and move it into place, keep every line they do not own, and never write over a save they could not read in full. .gitignore keeps it out of git.'
  'Progress travels as a file: copy terminal.save, and terminal.conf for your settings, into the dotfiles folder beside terminal.command on the new Mac. At power-up the self test has a READING SAVE AND CONFIG section that says whether each was found, where, and what was in it, down to the animal’s name and the coin bank. A save copied in while the cabinet is running is named on the card but is only read at the next power-on, so nothing overwrites it meanwhile. With BOOT on fast, the coin door says the same thing in one line. Then run INSTALL from the menu to link the shell hooks on that Mac.'
  'The .gitignore keeps each machine’s own files out of git: terminal.save and terminal.conf (and their temp and lock files), macOS .DS_Store files, and working clutter like backups and a _to_delete folder. The suite runs on its defaults without either file, and the installer writes the one switch it needs into terminal.conf, so a fresh clone works as it is.'
  'The Brewfile names the few Homebrew packages the machines reach for and nothing else: ollama (holds a local model in memory and answers on port 11434), llama.cpp (the other runner, one server per GGUF file, on port 8080), opencode (the coding agent that runs a local model when you press ⏎ on it in INTELLIGENCE’s LOCAL page) and node (Codex installs with npm). Everything else the suite uses already ships with macOS: zsh, curl, perl, sysctl, vm_stat, top, ioreg, pmset, netstat, osascript, afplay and pbcopy. The installer’s tools step runs it.'
  'scripts/fixtures/system is the machine SYSTEM looks at in demo mode: an invented 16-inch M3 Max called moonbase with 36 GB, six days up, two thirds of its disk used, a little swap, one link down and a cell charging. It is plain data files (sysctl, vm_stat, df, netstat, ioreg, pmset and ps readings) so the pictures in the repo are reproducible and leak nothing about a real Mac. Any command the fixture does not answer runs for real. probe.expected is every reading taken from it, used to check the monitor still reads it byte for byte.'
  'scripts/bootstrap.zsh has two jobs. The first makes Terminal open the cabinet: it links the three files under home/ into your home folder, adds one marked block to ~/.zshrc that sources the conf.d folder, and turns the terminal.hook switch on. The second puts the tools the machines lean on in place: Homebrew if it is missing, the Brewfile, and ollama as a service that starts at login. It never replaces or reorders ~/.zshrc and never writes outside its two marks; it keeps a copy called .zshrc.pre-alien before touching it, and it is safe to run twice. From the menu, [N] INSTALL runs it on the glass.'
  'While the house is not fully linked, the menu’s second row is [N] INSTALL, with what is missing beside it (like 1 of 3 linked). It opens the installer as a page on the glass: five checks, then one question, link the leaves, write the block and switch the hook on? [Y] does it, [N] or ⎋ is not now. Then, if any tools are missing, it shows the exact lines the tools step would run under a second question; [Y] hands the whole terminal to the installer (Homebrew asks for your password and a return), [N] leaves the tools for later. The way back out is printed on the same page before you answer. When the house is whole the row becomes [U] UNINSTALL.'
  'Once everything is linked, the install row becomes [U] UNINSTALL: the same installer asked the other question. It takes the marked block back out of ~/.zshrc, unlinks the three files it linked, and turns the hook switch off, after one [Y]. The copy it kept at ~/.zshrc.pre-alien is left alone because it is yours, and so are the Homebrew tools (ollama, llama.cpp, opencode, node) and ollama’s login service: those belong to Homebrew and are removed there if you want them gone.'
  'The installer’s tools step is interactive on purpose, because Homebrew’s own installer asks for a password and a return: the cabinet steps aside and hands it the real terminal, then comes back. It installs Homebrew if there is none, runs the Brewfile (ollama, llama.cpp, opencode, node), and registers ollama with Homebrew’s services so the runner is up on 127.0.0.1:11434 at every login. Before it runs anything it shows the exact lines it will run. The four cloud agents are not installed here: each signs in to your own account, so INTELLIGENCE’s CLOUD page installs them one at a time behind its gate.'
  'The installer appends one block to ~/.zshrc, between a line reading >>> ALIEN dotfiles >>> and one reading <<< ALIEN dotfiles <<<. All it does is read in every .zsh file in ~/.config/zsh/conf.d, which is where the two linked shell files live. Nothing outside those marks is touched. UNINSTALL takes the block out again, and deleting those lines by hand works too.'
  'home/.config/zsh/conf.d/00-alien-path.zsh runs on every new shell, before the hook. It puts ~/.local/bin on PATH if the folder exists and is not already there, so the alien launcher works from any prompt, and it adds Homebrew’s bin folder when Homebrew is installed but nothing has put it on PATH yet, so INTELLIGENCE can find ollama and friends by name. It never moves an entry that is already on PATH, because that would change which of two same-named programs wins.'
  'The hook, home/.config/zsh/conf.d/10-alien-terminal.zsh, opens the cabinet whenever a new shell is a person sitting at a terminal, and gets out of the way otherwise. Its switch is terminal.hook in terminal.conf: exactly on means a new Terminal window opens the cabinet, anything else means a plain prompt. That switch is not on the CONFIG page: [N] INSTALL turns it on, [U] UNINSTALL turns it off, or you can edit the terminal.hook line in terminal.conf by hand. The hook reads that line by eye and never runs the conf, and it does not replace your shell, so quitting the cabinet leaves you at your own prompt in the same window. It is written to fail toward a plain prompt whenever it is unsure.'
  'The hook refuses to open the cabinet in any shell that is not a person at a terminal: a script, a one-off command, a pipe, scp or rsync. It stays out of tmux and screen panes, ssh sessions, and the terminals inside VS Code, Warp and Hyper. It never opens inside the suite itself (the shell in the glass is just a shell), not while the cabinet is opening machines in tabs, and not in a shell started with ALIEN_NO_TERMINAL set, which is the one-shell override. If the switch is off, or the repo cannot be found through the link, it does nothing at all.'
  'home/.local/bin/alien is linked into ~/.local/bin by the installer, so typing alien at any prompt opens the cabinet, the same one a new window opens when the hook is on, and the way in when it is off. It finds the repo through its own link rather than a path written down at install time, so if you move the dotfiles you only run the installer again and nothing else has to be told.'
  '[Q] from anywhere opens the POWER OFF question and [Y] shuts the cabinet down. To stop new Terminal windows opening it, turn the hook switch off: edit terminal.conf so it reads terminal.hook = off, or use [U] UNINSTALL on the menu, which also takes the block out of ~/.zshrc; the switch is not on the CONFIG page. For a single plain shell, start one with ALIEN_NO_TERMINAL set. The hook also never opens in tmux, over ssh or in an editor’s terminal, so any of those still reaches a prompt.'
  'The suite keeps its short-lived facts in .local/state/alien under your home folder (or XDG_STATE_HOME if you set one): the house token that says which tabs belong together, the brief dealing flag that stops tabs the cabinet opens from opening cabinets of their own, terminal.save when there is not one beside terminal.command, and a note of which machine is being got ready at power-on, so one that ever brings the cabinet down there is left to open the ordinary way until its file changes. The installer makes the folder. The dealing flag clears itself by expiring, so a crash can never leave new shells without a way in.'
  'terminal.command takes a few launch options, mostly for testing: paint one frame and exit; the card without the ceremony; a text report of what it found (probe); a glyph test card (check); force the xterm 256-colour palette or force 24-bit; no colour at all; the sprites drawn as sharp ink; pin the frame rate; and skip the power-up. TERMINAL_MOCK makes it read an invented machine instead of this Mac, so pictures are reproducible, and ALIEN_SAVE points it at a different save file.'
  'Every opening starts with the stars alone for a couple of honest seconds while the machine loads behind them, and every machine in the folder with it, so each one opens ready: SYSTEM has taken its first reading, INTELLIGENCE has asked each agent its version, and the XENOGOTCHI room is already built. Then the tube warms: an ember, a line, the raster unfolding and the picture settling. Then comes the power-on self test card, and then the menu, about thirteen seconds in all. Any key skips the ceremony (whatever was not ready yet is finished on the menu, the machine under the cursor first), and [P] pauses the self test so you can read it ([P] again goes on). BOOT = fast on the CONFIG page skips all of it and opens straight on the menu. Powering off plays it backwards: the picture lets go, collapses to a line, pinches to a dot and burns down.'
  'The self test card says what the cabinet found on this Mac, one line at a time: the CPU, RAM, DISK, the PANEL (window size and refresh rate), the BEAT (the frame-rate ladder), INK (24-bit truecolor or the xterm 256 palette), TERM, SHELL (zsh version and UTF-8), OS, SND (OK, or SILENT where sound cannot play) and SKY (the latitude and longitude taken from your time zone). Then the four machine slots, each ONLINE · ON THIS GLASS or ABSENT, and finally READING SAVE AND CONFIG: whether terminal.save and terminal.conf were found, where, and what was in them. [R] RESCAN from the menu runs the same card again.'
  'The last block of the self test is READING SAVE AND CONFIG: one line for terminal.save and one for terminal.conf, each FOUND with the folder it was found in, or NOT FOUND, or unreadable. A found save also says whose progress is in it, with the animal’s name and the coin bank beside the machines that have one; a found conf says how many settings it holds. With BOOT on fast the card is skipped, so the coin door says it instead, for example save found · config found. This is how you know a save copied over from another Mac was picked up.'
  'The menu is a list you move through with ▲ ▼ (or j and k) and act on with ⏎. At the top is the SUITE box: [T] TERMINAL, [N] INSTALL (or [U] UNINSTALL once installed), [R] RESCAN and [C] CONFIG, each also reachable by its letter. Under it, the MACHINES box lists SYSTEM, INTELLIGENCE, XENOGOTCHI and ARCADE, each with a live reading beside it: the load average, how many AI agents are installed, your animal’s name and health, and the arcade’s coin bank. ⏎ on a machine walks into it. [V] opens the visitor’s page, [Q] powers off, and a letter the menu does not have says so on the coin door.'
  'Each machine row carries one live reading: SYSTEM shows the load, INTELLIGENCE how many AI agents are on this Mac, XENOGOTCHI the animal in the room and its health as a percent (or no pet), and ARCADE the coins in the bank (or no save yet). A machine whose file is missing from scripts/suite greys out and says which file it needs rather than opening onto nothing. Every machine is a page pack now, so each opens inside this same glass rather than in a tab of its own.'
  'Under the menu, a gauge shows how many of the files under home/ are linked into your home folder and point back into this repo: all linked means the house is installed, otherwise it says how many are waiting and the menu offers INSTALL. A link that points somewhere else is not counted as ours. Below that sit five readings about this Mac: the CPU with its cores, the memory, the disk with a bar that turns warmer as it fills, the display panel and rate the animations are paced against, and the operating system.'
  '[T] TERMINAL opens your own login shell inside the glass, with the cabinet and its neon around it: the same profile, PATH and prompt a new Terminal window would give you. The hook stands aside inside it, so it is a shell and not another cabinet. ^] detaches and returns to the menu with the shell still running (the row then says how long it has been running), and [T] goes back in. Typing exit ends it. The mouse wheel scrolls back, and Page Up and Page Down move a page. A window resized while the shell is up does not reflow it; reopen [T] for the new size.'
  '[R] RESCAN reads the machine again and shows the self test card again: the specs, the display and frame rate, the machine files in the folder, the links into your home folder, the save and the conf. The save is read again, and the conf is counted, but its settings are only applied at power-on, since a rescan is not a restart. Use it after copying a save in, installing something, or moving the window to another display.'
  '[C] CONFIG folds up a panel over the menu with the five settings every machine feels: SOUND, PHOSPHOR, BEAT, BOOT and SCREEN. ▲ ▼ choose a row, ◂ ▸ or ⏎ change it, and ⎋, [M] or [C] fold it away. Each row says when a change is felt: live means at once, restart means at the next power-on (only BOOT). Every change is written straight to terminal.conf, keeping every other line in it; if the file cannot be written, the change holds only until you quit, and the coin door says so.'
  'To turn the sound off or on, press [C] on the menu to open CONFIG, move to the SOUND row with ▲ ▼, and press ◂ ▸ or ⏎; inside the arcade, [U] flips the same switch. It changes at once and is saved in terminal.conf as sound = on or off. The sounds are the cabinet’s small noises, the blips, the cursor ticks and the alert on a no, played from macOS’s own system sounds; nothing is downloaded or bundled, and they stay silent down a pipe, in plain mode, or where macOS cannot play them, which the self test reports as SILENT.'
  'PHOSPHOR, on the [C] CONFIG page, chooses how the lit sprites (the visitor, the sun and the moon) are drawn: soft, the tube’s gentle bleed, or sharp, hard blocks of ink. Move to the PHOSPHOR row with ▲ ▼ and press ◂ ▸ or ⏎ to switch it; it changes at once and is saved in terminal.conf as phosphor = soft or sharp.'
  'BEAT, on the [C] CONFIG page, is the frame rate the whole cabinet runs at: auto, 30, 60 or 120. Move to the BEAT row with ▲ ▼ and press ◂ ▸ or ⏎ to step through them; it changes at once and is saved as beat in terminal.conf. On auto the cabinet governs itself, running at the display’s own refresh rate when it can keep up and otherwise at an exact divisor of it, stepping down quickly when frames run long and back up one rung at a time after a few comfortable seconds. If things feel choppy, auto or a lower number helps, and fill mode costs more than float.'
  'BOOT, on the [C] CONFIG page, is full (the whole opening: stars, the tube warming, the self test) or fast (straight to the menu). Move to the BOOT row with ▲ ▼ and press ◂ ▸ or ⏎ to switch it; unlike the other settings it takes effect at the next power-on, and it is saved as boot in terminal.conf. With fast, the coin door still says whether the save and config were found.'
  'To make the cabinet fill the window, press [C] on the menu to open CONFIG, move to the SCREEN row with ▲ ▼, and press ◂ ▸ or ⏎ to switch it from float to fill; doing it again puts it back to float. It changes at once and is saved in terminal.conf as screen = fill or float. Float stands the whole cabinet, walls, neon, bezel and coin door, in the middle of the window with the night around it. Fill hides the cabinet’s frame and makes the glass the whole terminal at any size, full screen included, with the sign, keys and messages drawn on the glass instead. Pages that have a fill layout reflow to the window; one that has not been given one yet stays the fixed size, centred.'
  '[Q] from anywhere asks POWER OFF, SHUT THE HOUSE DOWN? [Y] powers off, [N] or ⎋ keeps it up. Powering off plays the tube going out, stops anything the machines started and puts the terminal back, and that is all it switches off: Terminal stays open, with every other window and tab as it was. When the hook or the alien launcher opened the cabinet, you are left at your own prompt in the same window. A cabinet double-clicked from Finder ends the way any .command does, and Terminal’s own setting decides whether that window closes. terminal.conf is left as it is, since every change was already written.'
  'Every surface wears the same title band: ◤ and the page’s name on the left, the sky’s caption on the right. By day it reads sunny and the time; by night it is the moon’s phase and the constellation of the zodiac it is in, worked out from the date, then the time, like waxing gibbous in capricorn · 11:48 pm. It is warmed by day and cooled by night.'
  'The sun or moon on the visitor’s page is the real one. The cabinet takes a latitude and longitude from your Mac’s time zone, works out where the sun is and whether it is above your horizon, and at night which of the eight phases the moon is in; twilight gets its own warm card. The arithmetic is the same the Python version used, term for term. It is worked out once a minute, not every frame. The self test’s SKY line shows the location it used.'
  'The coin door at the foot of the cabinet is where the machine talks back. When nothing has happened it shows a greeting, one line a minute dealt from the hour’s own pool and often with your name: good morning, still at it, up late. After a key does something, it says what happened for about six seconds and fades back to the greeting. Its badge corner shows the surface’s own figure, and on the menu that is the mirror.'
  'The cabinet is the arcade’s own, ported term for term from the original arcade.py: neon tubes breathing up both walls, lit side art, a bezel with the machine’s name let into it, a control panel carrying the key strip, a coin door, and light spilling on the floor. The glass is a CRT with a vignette, a slow bright roll and phosphor on every page change, which changes channel like a tube: a line, an unfold, a settle. Outside it is the suite’s starfield, with a rare shooting star, and a little dust drifts on the pane but never lands on a word.'
  'The dotfiles draw in 24-bit colour. The one exception is Apple’s Terminal on older macOS, which only takes the xterm 256-colour palette unless it announces truecolor, and there the cabinet lifts its dark purples before choosing the nearest colours so they do not turn into navy. The self test’s INK line says which one this terminal got. A launch option can force either, and plain mode draws no colour at all.'
  'The same keys mean the same thing on every surface: ▲ ▼ move through rows, ◂ ▸ turn pages, ⏎ opens or does the row, and a page’s own letters jump straight to it. ⎋ goes back one level, and from a machine’s own menu it goes out to the suite; [M] and ⌫ also leave a machine. [Q] is the power switch from anywhere. The mouse wheel moves the cursor quietly, a row a notch, and never counts as a press. Each page names its keys on the bar along its foot.'
  'Each machine in scripts/suite is a page pack: a file the door reads into itself the first time you open that machine, which then draws inside the door’s glass, while the door keeps the walls, the tube, the frame rate and the keyboard. A pack is read only once per session, so walking back into a machine finds it exactly where you left it. If a pack fails to load or start, the door survives it and puts the last line of what went wrong on the coin door; if it takes the program down, what it said is printed on the terminal afterwards. Run on their own, the pack files only say they belong to terminal.command.'
  'The visitor is a small grey-violet alien with a wide head and two big dark eyes who lives in the glass of the cabinet: the suite’s mascot, and the one who knows the house. [V] on the menu opens his page, where he stands in the middle with the real sun or moon in the corner above him, wearing whatever the arcade has put on him, and a box along the foot of the glass lets you talk to him. He looks up when you press a key and looks out at you while he talks. ⎋, [M] or [V] go back to the menu.'
  'On his page, ⏎ steps into the TALK TO HIM box; type, and ⏎ sends. The box stays live for the next line, ⎋ steps out of it, and while typing ◂ ▸ move the caret, ⌫ takes one back, and ^A ^E ^U ^W work as in a shell. His answer arrives in a speech bubble above and to the right of his head, lit by the same sun or moon, growing as the words come, and what you last said sits on the box’s top rule. Outside the box, ▲ ▼ or the wheel read back up a long answer, [X] stops him mid-sentence, and [N] starts the conversation over.'
  'The visitor answers through a model running on this Mac, found on the usual local ports (Ollama, llama.cpp, LM Studio or MLX), and never through anything that leaves the Mac. If none is installed, the box says he needs a local model and to install one on INTELLIGENCE’s LOCAL page; if one is installed but not running, it says to start it there. Models that only embed or rerank, and cloud-tagged models, are passed over because they cannot chat here. When an answer fails he loses his train of thought, and you can simply try again.'
  'Nothing you say to the visitor leaves this Mac. The request goes to a runner on 127.0.0.1, written to a private temporary file readable only by you rather than onto a command line where other programs could see it, and the file and the answer are deleted when he finishes. The conversation lives only in the cabinet’s memory: [N] clears it, and powering off forgets it. He cannot run commands, open files or change settings; he can only talk.'
  'The visitor carries notes on these dotfiles, written from the files themselves: every file, page, key and setting. For each question he looks up the notes that fit, and he also sees what is true on this Mac right now, such as the current settings, whether the save and config were found, which machines are here, and what he is wearing. He does not learn new things between visits or remember past conversations after the cabinet powers off. If something is not in his notes, he should say so rather than guess.'
  'Everything the visitor wears comes from the ARCADE’s MARKETPLACE, bought with arcade coins: four slots, hats, glasses, smokes and auras (weather around him), 166 items in all. What he has on is saved in terminal.save, so his page on the menu shows him in the same outfit the moment you come back, with its names listed down his side. The items are more pixels in his own picture, lit by the same light, not stickers. The talk bubble never covers anything he wears: it keeps out of his card and the row an aura adds above and below it.'
  'SYSTEM is the suite’s monitor for this Mac: eight pages of live readings drawn in the glass, model NX-88. Its menu lists six instruments, [O] OVERVIEW, [C] PROCESSOR, [R] MEMORY, [D] STORAGE, [N] NETWORK and [B] POWER, then two tables, [P] PROCESSES and [H] HARDWARE, each with its one live reading beside it. ▲ ▼ and ⏎ open a page, a letter jumps straight to it, ◂ ▸ ring through the pages, and ⎋ goes back to the list and then out. MEMORY is [R] because [M] is the way out on every machine. It reads with commands macOS already has and changes nothing.'
  'OVERVIEW is the machine at once, in three columns and a ticker. On the left, five tapes (history traces), a map of every core and the network’s incoming traffic. In the middle, a radar scope: each process is a contact whose distance from the rim is how much of a core it is using (the rim is idle, the innermost ring the range), whose size is how much memory it holds, and whose brightness fades as the sweep moves on; a ring means it was not running at the last reading and a tail means it moved. The busiest process gets a mark on the rim in its own colour. On the right, four gauges, a watch list and the returns.'
  'PROCESSOR is every core and where the time is going, which a single busy percentage hides: user, system, idle and nice time, the load averages, and a bar for each core in a grid that grows sideways however many cores there are. On Apple silicon the efficiency cores are listed first. Per-core figures need a dozen lines of python3 if it is present, because macOS does not publish them to a shell; without it the page still shows the totals.'
  'MEMORY splits the whole of memory the way Activity Monitor does: app memory, wired, compressed, cached files and free, so you can hold the two side by side, with the Memory Used figure matching Activity Monitor’s. It shows swap against the memory fitted (macOS grows its swapfiles on demand, so used of total means little on its own), memory pressure, the fault and page-out rates, the processes holding the most, and a trace of memory in use.'
  'STORAGE lists every volume with a real device behind it, largest first, how full each is, and what the drives are carrying: read and write rates and lifetime totals, with a trace of reads and writes. Available space is taken from the system’s own figure rather than total minus used, because APFS keeps a reserve and a purgeable pool between them. An APFS container’s system and data volumes are shown once, as the data volume holding your files.'
  'NETWORK shows the link in use, its addresses, the traffic in and out as rates and traces, the counts of open sockets (established, listening, waiting and the rest), and every interface that has carried traffic, busiest first. It follows the default route, so docking, joining a VPN or moving from Wi-Fi to Ethernet moves the page with you. Megabytes are counted the way Apple counts them, a million bytes.'
  'POWER is the battery: its charge and whether it is charging or on the wall, time remaining, health against its design capacity, cycle count, temperature, the voltage and current crossing its terminals, low power mode, and the charge of anything paired that reports one, like a mouse, keyboard or earbuds. A Mac with no battery says so rather than reading zero per cent.'
  'PROCESSES is every process in a scrollable table, sorted by what it is costing, with a summary strip across the top and a bar for each row relative to the busiest. ▲ ▼ move the cursor, Page Up and Page Down move twenty rows, the wheel scrolls, and [S] cycles the sort. It only reads: nothing here stops or changes a process.'
  'HARDWARE is what this Mac is and what it has done: the model and chip, the operating system and build, the kernel, the core counts, the boot disk, when it booted and how long it has been up, and a trace along the foot. The cabinet’s badge shows the uptime in days while SYSTEM is standing.'
  'SYSTEM asks macOS’s own tools and nothing else: sysctl, vm_stat, df, netstat, ioreg, pmset, ps and top, plus python3 only for the per-core split. A full reading is taken every ten seconds, in a background copy of itself, so the picture never freezes while top takes its second; the bars ease toward each new figure in between. The tapes record only readings that were actually taken, about sixteen minutes of history. Under TERMINAL_MOCK it reads the invented Mac in scripts/fixtures/system instead.'
  'INTELLIGENCE is the suite’s switchboard for AI command lines, model IQ-88: which agents are on this Mac, which install of each you would actually get, what it is signed in as and what model it is set to, plus the local side, where a model on your own disk is held in memory by a runner. It has seven pages, each on its own letter: [C] CLOUD, [L] LOCAL, [R] ROUTE, [B] BENCH, [P] PROMPTS, [H] HISTORY and [K] KEYS; CONSOLE lives under LOCAL and REWRITE under PROMPTS. ◂ ▸ ring the pages, ⎋ climbs back to its menu and then out. It installs, removes and reports, and every line it would run is shown on a gate before it runs.'
  'CLOUD has one row per cloud agent: CLAUDE CODE (Anthropic’s), ANTIGRAVITY (Google’s terminal agent), GROK BUILD (xAI’s) and CODEX (OpenAI’s). Each row says what ⏎ will run before it runs it: the binary, its version, the model it is set to, how it is signed in, and which of several installs is the one on PATH. ⏎ on an installed agent opens it in a terminal inside the glass, sized to the glass, and ^] brings the keyboard back to the cabinet with the agent still running behind it (⏎ goes back into it). [I] installs a missing agent and [U] removes one, both through the gate. Each signs in to your own account.'
  'Nothing in INTELLIGENCE is assembled behind your back. [I] and [U] put the exact line that will run on the glass, the same string the roster holds so you can check it against the vendor’s own page, and wait: [Y] runs it, [N] or ⎋ is not now. Once answered, the job runs in the strip along the bottom of the page while the page stays usable, and [X] stops it. Stopping walks the job’s own process tree by its pid, never a pattern that could hit other programs.'
  'LOCAL has two lists and one cursor: the runners (OLLAMA on port 11434, LLAMA.CPP on 8080, LM STUDIO on 1234, MLX on 8081) and the models on this disk; ⇥ moves between them. On a runner, [S] or ⏎ starts it in its own Terminal tab, since a runner should outlive the cabinet. [I] installs a model from a curated list through the gate. On a model, ⏎ asks chat here (CONSOLE) or opencode, [D] keeps it loaded in ollama so it answers faster, and [U] removes it. The foot of the page shows what the model is costing this Mac, measured like SYSTEM measures: memory, chip and the runner’s real resident size.'
  'LOCAL’s install list is curated: every model on it supports tools and is big enough to drive opencode, and it is marked against this Mac’s memory as comfortable, tight or too big. qwen2.5-coder 7b (4.7 GB, 16 GB RAM, the smallest that still drives opencode well), qwen3 8b (5.2 GB, 16 GB, general and reasons first), qwen2.5-coder 14b (9 GB, 24 GB), gpt-oss 20b (13 GB, 24 GB, OpenAI’s open reasoning model), qwen3-coder 30b (19 GB, 32 GB, a mixture-of-experts coder), qwen2.5-coder 32b (20 GB, 32 GB) and gpt-oss 120b (65 GB, 96 GB). The RAM figure is the least needed at opencode’s 64k context, not the file size.'
  'CONSOLE is one session with a local model, reached from LOCAL (⏎ on a model, then chat here). It speaks the plain OpenAI-shaped endpoint every runner serves, so the numbers beside it are real: the rate measured from what has arrived, the time to the first token, and the model’s own token counts. ⏎ types, [X] stops an answer, [E] picks another model, [N] starts a new session, and [S] saves the whole conversation as a markdown report in your Downloads folder. It has no access to your files; its request and answer sit in private temporary files that are deleted when the session ends.'
  'opencode is the coding agent the suite uses to run local models: it takes any OpenAI-shaped endpoint as a provider, which is what a runner on this Mac is. ⏎ on a model on the LOCAL page, then opencode, opens it in the glass with that model, so a pulled model becomes a coding agent rather than a chat. It comes from the Brewfile, and it is not on the CLOUD roster because it runs local models rather than signing in to an account. ROUTE’s [O] opens opencode on the router.'
  'ROUTE takes one prompt and lets a router decide where it goes: local, cloud, or a subscription. The router is a LiteLLM proxy on this Mac (port 4000). Three modes set how eagerly it spends a metered cloud call: prefer local (about 15% cloud), balanced (the default, about 28%) and prefer cloud (about 75%); local is always free and tried first. A per-provider daily cap in dollars (2, 5, 10, 20 or none) stops a runaway loop. ⏎ types a prompt, which is checked by the egress guard, rewritten by a local model if it is eight words or more, and routed; [M] changes mode, [G] writes the proxy’s config, [O] opens a full opencode session through the router.'
  'BENCH sends one prompt to every engine that can answer a single question and shows the answers side by side, with measured times to the first byte and to the finish. Each run starts in an empty scratch folder of its own, because these are agents that read and write their working directory; that is not a sandbox, and the agent still runs as you. ⏎ types a prompt, [X] stops the runs, [A] asks again, and 1, 2 or 3 copies that answer to the clipboard.'
  'PROMPTS is a library of forty-three ready prompts, each shown beside the rules it leans on, from a set of twelve, because the rules transfer and the wording does not. ▲ ▼ choose, ⏎ copies one to the clipboard. [W] opens REWRITE, which turns a rough prompt into one any model will follow well, the way an engineer would write it: ⏎ types the rough prompt, [E] picks the engine that rewrites it, and when it lands ⏎ copies the result and [A] asks again.'
  'HISTORY lists what has been run from this cabinet in this session: what, where, how long and how it ended, and never a prompt or an answer; it lives in memory, not on disk. KEYS shows which provider keys this Mac is carrying in its environment (Anthropic, OpenAI, Gemini, xAI, OpenRouter, Groq, Mistral, DeepSeek and more): only that each is set and how long it is. A key’s value is never read, printed, logged or sent; the length alone tells two keys apart or spots a typo.'
  'The egress guard scans anything the cabinet is about to send to a cloud engine for secrets, keys and credentials, before it goes. It fails closed: it can only ever keep a prompt local, never send one, and it leans toward over-blocking because an over-block costs a keystroke and a leak cannot be undone. Its report names the category of what it found, never the value. A secret is never sent out even to be rewritten.'
  'The suite never borrows a subscription’s login. A cloud agent is used only through its own official command line, signed in on your own account by that tool itself; INTELLIGENCE reads which account a tool is signed in as but never copies, proxies or reuses its tokens, and it never reads the value of an API key. Installing and removing agents goes through the gate one at a time, with the vendor’s own install line shown first.'
  'A runner holds a model in memory and answers over HTTP on this Mac’s loopback. Ollama is the main one (port 11434): it pulls models by name and keeps them loaded, and the installer registers it to start at login. llama.cpp’s server runs one GGUF file per server on port 8080. LM Studio (port 1234) and MLX (port 8081, Apple silicon) work too. The suite checks each port and asks it for its model list; something else on a port that does not list models is passed over. Every model page, the console and the visitor all talk to whichever runner is up.'
  'XENOGOTCHI is the adoption centre, model XG-9: where SYSTEM watches the machine, this one keeps an animal in it. You adopt one, name it, and after that it simply lives in its room on the real clock, fed, watered, groomed or neglected, its behaviour chosen moment by moment from a running emotional state. Its menu has four pages, each on its letter: [H] HOME (the room, and whoever is in it), [O] STORE (things bought with credits earned by care), [A] ADOPT (intake night) and [S] STATS (every animal you have signed for). ◂ ▸ ring the pages, ⎋ goes back to the menu and then out. The menu’s XENOGOTCHI row shows the animal in the room and its health.'
  'To look after your animal, open XENOGOTCHI from the menu and go to HOME with [H], where it lives. There [F] feeds it a meal from the pantry, [W] freshens its water, [G] grooms it (a full groom once every half hour), [T] gives a treat (three a day), [P] brings out the red dot to chase with the arrows, [Z] suggests a nap (refused if it is not tired), [B] scoops the litter box, and ⏎ pets it, though pet it too often and it will turn you down for a while. [A] admires a gift it has left you, and [D] changes the room’s decor among the bed covers, dish sets and core colours you own. If the pantry is empty, buy KIBBLE PODS in the STORE.'
  'An animal’s vitals run from 0 to 100: FOOD (the bowl), HYD (water), MOOD, BOND (how attached it is to you), COAT (grooming), PEP (energy) and HEALTH, plus the litter box. Each meter drops to red when it runs low. Keeping food, water, mood, coat and health above 35 through a whole day earns the care streak; letting them fall breaks it and costs a little bond. If health falls, [V] on STATS takes it to the ship’s vet.'
  'XENOGOTCHI credits are its own, separate from the arcade’s coins, and they are earned by care, never bought. Each local day in which every vital stayed above 35 pays +10 and extends the care streak. A treat and a first pet in ten minutes pay +1 each, admiring a gift the animal left pays +15, and catching the red dot pays +2 for up to three catches a day. The daily roll also resets the treat and catch caps and may leave a new gift. Credits are spent in the STORE and at the vet.'
  'The STORE is a catalogue in three departments. The GALLEY: KIBBLE PODS (10, six meals for the pantry), SPACE TUNA (25, food +40 and mood +5) and NEBULA FEAST (60, food +60 and mood +15). The TOY CHEST, kept for good: YARN BALL (30, the red dot runs longer), HOVER ORB (60, company while you are away so its mood holds) and PHOTON POINTER (80, a sharper dot that is easier to catch). THE ROOM: BED COVER (120, a new colourway, and the first makes naps restore more), DISH SET (50) and CORE TUNING (80, the reactor burns a new colour). ▲ ▼ walk it, ⏎ buys, and the sheet on the right shows what an item will do to this animal and what you would have left.'
  'To adopt, open XENOGOTCHI and choose ADOPT on its menu ([A] there, or ◂ ▸ from any of its pages; on HOME [A] admires a gift instead). ADOPT is intake night: four arrivals dealt from the genetics deck, each in its own stall with its paperwork, temperament, eyes, life stage, age and the life left to it. ◂ ▸ walk the stalls and ▲ ▼ deal another litter. Type a name, up to twelve letters, into the certificate’s SIGN field, and ⏎ signs for the one under the light, which goes home to the room. The doors hold four species at a time for four hours of wall clock, the same four on any Mac the save is carried to, and a fresh house opens here on its first night.'
  'Twenty-five species arrive, in shipments: the cat first and the dog second, then rabbit, hamster, fox, turtle, hedgehog, duck, frog, snake, owl, pig, axolotl, guinea pig, ferret, rat, chinchilla, goat, gecko, sugar glider, parrot and penguin from Earth, and three from further out: the GLORP, the XENOMORPH and the VOID DRIFTER. Each has its own lifespan, from a rat’s three years to a turtle’s sixty and a glorp’s ninety-nine. An arrival’s species comes from its own seed; an animal already signed for keeps the species written in the save.'
  'STATS is a page about the whole house: every animal ever signed for, with its papers. ▲ ▼ choose one, ⏎ brings it into the room (only one is in the room at a time), [N] renames the one in the room, [V] takes the one in the room to the vet (45 credits; it treats a very sick animal anyway, pay when you can), and [R] asks whether to let one go.'
  'Releasing an animal is the only thing in XENOGOTCHI that cannot be undone, so it asks once on a screen of its own, the way the cabinet asks before it powers off: [Y] lets it go, [N] or ⎋ keeps it. A released animal’s lines leave the save, and a short record stays in their place so the file is honest about the house having had it.'
  'Every animal has its own lifespan (a cat’s seventeen years, give or take fifteen per cent by its seed) and ages on the wall clock from the day it comes home. Its stage is a fraction of that span, six in all; for a cat that is KITTEN, JUNIOR, YOUNG CAT, CAT, MATURE CAT and SENIOR. It grows smoothly, one size for every day of its life, and past full grown it broadens and then draws in, and a senior greys a little. Arrivals come at any age, mostly young but sometimes the overlooked.'
  'Time passes for the animal while the cabinet is closed, and it is charged when it next powers on: the first 48 hours away count in full, after that at a quarter rate, so a weekend away earns a hungry, theatrical animal and never a tragedy. Absence is capped at 45 days however long you were really gone, and a jump of more than 120 days is read as a wrong clock rather than a lost pet, so nothing is charged. A HOVER ORB keeps its mood up while you are gone.'
  'A coat is dealt, not picked: one colourway drifts in hue, saturation and value by the animal’s seed, with its pattern, eye colour, a chance of odd eyes, ear and tail build and a temperament dealt from the same hash, so the same seed is the same animal forever. Each species has breeds that decide what the rest may be and set its size. The finished animal, its words and its twelve colours, is written into the save, so it stays the same creature even if the decks change later.'
  'The animal lives in a ship’s engine room lit by a banded reactor column that throws teal light across the deck, with a porthole showing the suite’s own sky. Nothing it does is scripted: its needs, its temperament and the hour feed a running emotional state, and the winning emotion picks what it does next. A content animal roams, potters and chases, goes straight to its dish or bed when it needs to, gets bored of repeating itself, and sleeps at night in bouts. On a filled screen the whole room shows; on the floating cabinet it is a close-up.'
  'Every animal lives in the xenogotchi section of terminal.save: xenogotchi.active says which one is in the room and each animal is under xenogotchi.pets with its name, species, breed, colours and vitals, one dotted line each, so the file can be read and hand-edited. XENOGOTCHI rewrites only its own lines, whole and atomically, and copies every other machine’s lines through untouched; a save it cannot fully read is never written over. A save from before the roster, with one animal at the top level, still loads.'
  'The ARCADE, model NX-88, holds twelve cabinets, one coin a game, with a coin bank, a daily token, a high-score table for every rung of every machine, a marketplace, a trophy room and a service menu behind a held key. Its menu lists the games under five rooms: MARKETPLACE, HIGH SCORES, TROPHY ROOM, THE LEDGER and MENU (the way back to the door). ▲ ▼ choose, ⏎ plays or opens, ◂ ▸ walk the rooms, and letters jump: [B] marketplace, [H] high scores, [A] trophy room, [L] ledger, [S] settings, [T] the daily token, [U] sound on or off. ⎋ or [M] goes back to the door.'
  'The arcade has twelve games: NEON SNAKE (arcade), BLOCK FALL (puzzle), VOID PONG (sports, one or two players), BRICK NOVA (action), STAR RAIDER (shooter), GRID RUNNER (maze), LASER DODGE (reflex), NIGHT DRIVE (racing), LIGHT CYCLE (arena, one or two players), PLASMA BALL (pinball), ASTRO DRIFT (space) and BEAT GRID (rhythm). NEON SNAKE is yours from the start; the others are bought outright or rented in the MARKETPLACE. Open ARCADE from the menu and choose one with ▲ ▼ and ⏎. Each plays on a board fitted to the glass, and its points are scaled back to the original board’s pace, so the tables stay fair at any window size.'
  'Choosing a game opens its rung page: ▲ ▼ pick ROOKIE, NORMAL, EXPERT or INSANE, ⏎ (or 1) inserts a coin and starts, and 2 starts a two-player round where the game allows it (VOID PONG and LIGHT CYCLE), for two coins. In every game [P] pauses and [Q] cashes out, ending the round and paying what it earned. After the round your score is ranked straight into the table, no initials to type, since the arcade knows you, and then the payout window adds it up.'
  'NEON SNAKE: the arrows steer; eat ◆ fast to build the chain, a ★ is worth five, do not eat your own tail. BLOCK FALL: ◂ ▸ move, ▲ rotates, ▼ drops, [SPACE] slams, and [C] holds a piece back for later; clear four lines at once. VOID PONG: ▲ ▼ move the paddle and get the photon past the machine, the post is in play, three misses ends it; with two players the left is the arrows and the right is W and S. BRICK NOVA: ◂ ▸ move, [SPACE] launches, clear the wall and catch the capsules, and [M] splits every ball on the field.'
  'STAR RAIDER: ◂ ▸ move, [SPACE] fires; hold the line as the formation descends, and the ones that peel off to dive are worth double. GRID RUNNER: the arrows run a maze carved fresh every level; eat the grid, dodge the daemons, and the big nodes turn them edible. LASER DODGE: sixty seconds of steering away from beams, the rails flash before they fire, and [SPACE] blinks you clear. NIGHT DRIVE: ◂ ▸ steer, ▲ boosts, ▼ eases, and passing clean fills the nitro bottle that [SPACE] spends; the road ahead is dealt fresh.'
  'LIGHT CYCLE: the arrows turn; leave a wall behind you and box the other rider in, and your own wall kills you too; two players race arrows against W A S D. PLASMA BALL: ◂ ▸ work the flippers, [SPACE] pulls the plunger, and [Z] [X] and ▼ nudge the table, carefully. ASTRO DRIFT: ◂ ▸ turn, ▲ thrusts, [SPACE] fires and [H] jumps to hyperspace, which might not be kind; momentum has no brakes, and there is a saucer. BEAT GRID: four lanes on ◂ ▼ ▲ ▸, strike on the line; gold notes want PERFECT and hollow ones want three hits.'
  'You earn arcade coins by playing: every round pays back its score divided by that machine’s rate, plus 25 for a new record or 10 for a top-five finish, plus the visitor’s style bonus, all multiplied by the rung, half on ROOKIE, once on NORMAL, twice on EXPERT and three and a half times on INSANE. Trophies pay coins too. When the bank is under 10, [T] on the arcade menu claims a daily token of 10 coins, once a day. A round costs one coin, or two for two players; the bank starts at 10 and holds up to 9,999. Free play and the operator’s rigged service mode pay nothing.'
  'Every machine has four rungs. ROOKIE (gentle pace, edges wrap, gems linger) and NORMAL (the default, walls are fatal) are open from the start. EXPERT (quicker, hazards on the grid) opens when your best on NORMAL reaches that machine’s target score, or for 400 coins; INSANE (brutal speed across a minefield) opens with a target on EXPERT, or for 900 coins. Each rung has its own high-score table and pays more: half, one, two and three and a half times. The rung you last started on is remembered in terminal.conf as arcade.difficulty.'
  '[H] opens the hall of fame: one table of five for every rung of every machine, ◂ ▸ to change machine and ▲ ▼ to change rung, with gold, silver and bronze and a bar against the leader. A fresh arcade opens on seeded tables of regulars and one-offs, the same names the original always opened on, until you beat them. Your rows are signed with arcade.player from terminal.conf, or your Mac user name if that is empty. RESET HIGH SCORES in SETTINGS erases them.'
  'The MARKETPLACE ([B]) has racks you cycle with ◂ ▸: the games, then the visitor’s wardrobe racks, HATS, GLASSES, SMOKES and AURAS. ▲ ▼ choose. On a game, ⏎ offers to buy it outright or rent it by the meter: one hour for a sixth of its price (at least 6 coins) or twenty-four hours for two fifths (at least 16); a rental pays exactly what owning pays. On a wardrobe item, ⏎ buys it, then wears it, then takes it off. [R] picks something at random on a wardrobe rack, and ⎋ goes back.'
  'Prices to own each machine outright, in coins: NEON SNAKE free, VOID PONG 120, LASER DODGE 160, BRICK NOVA 220, GRID RUNNER 300, NIGHT DRIVE 400, PLASMA BALL 550, ASTRO DRIFT 740, STAR RAIDER 1,000, BLOCK FALL 1,360, LIGHT CYCLE 1,840 and BEAT GRID 2,500. Renting costs a sixth of the price for an hour or two fifths for a day. Choosing a machine you do not own from the menu opens the same buy-or-rent window.'
  'The wardrobe dresses the visitor: 59 hats, 45 glasses, 27 smokes and 35 auras, 166 items across six rarities (common, classic, uncommon, rare, epic, legendary), bought with arcade coins in the MARKETPLACE. Each is more pixels in his own picture, lit by the same light, and an aura is weather around him that throws its own light. The save keeps a receipt for every item you own and one worn item per slot, and a worn item is shown on the visitor’s page too. He also stands beside the payout window when he has earned you something.'
  'What the visitor wears pays: every arcade round’s earnings get a style bonus that adds up item by item, by rarity: each common or classic item adds 1%, each uncommon 2%, each rare 3%, each epic 4% and each legendary 5%, and filling all four slots adds 5% more; it is always at least one coin. His current outfit’s total is in THIS MAC RIGHT NOW. It shows in the payout window as STYLE +N%. It is added before the rung multiplier, so it grows on the harder rungs.'
  '[A] opens the TROPHY ROOM: a hundred and ninety trophies, each paying coins when it is earned, on shelves for all, earned, locked, each game, the arcade as a whole, and secrets. They check the run that just ended and your save; buying, dressing and opening things can earn them too. The secret ones are for things like a round that scores nothing, wearing nothing at all, a mothership hat with an aura, finding the service door, a certain classic code typed on the menu, or playing at three in the morning.'
  '[L] opens THE LEDGER: your own numbers, which the save always knew. Two columns of figures, runs, coins earned, the bank, daily tokens, machines owned and rungs opened among them, then every machine as a bar, tallest where you keep going back, and a line naming the one you play most.'
  '[S] opens SETTINGS: SOUND FX (the house’s sound switch, the same one CONFIG throws), ATTRACT MODE (the demo reel after 20 seconds idle), FREE PLAY (play for nothing and earn no coins while it is on), RESET COIN BANK (back to 10, earned total cleared), RESET HIGH SCORES (erase the hall of fame), SELF TEST (colour bars, input and glyph check) and BACK TO GAMES. The resets ask first. The tube, frame rate and window are CONFIG’s, on the door.'
  'After twenty seconds with nobody at the keys, the arcade starts selling itself: the logo, today’s best, one machine at a time played by its own demonstrator, how to play it, and once he owns anything the visitor in his outfit. The first key only wakes the arcade. The demonstrators are meant to be competent, not perfect. ATTRACT MODE in SETTINGS, or arcade.attract in terminal.conf, turns it off. The reel is the arcade’s idle show only; its title card, when it is opened, is the cabinet wall.'
  'Like every NX-88, the arcade hides its service switch behind the coin door: hold down the backslash key, [\], on the arcade menu until the door swings open, then punch in the serial off the machine’s plate, which the arcade’s SELF TEST shows. Behind it are the operator’s switches. Any machine they rig pays no coins and sets no records; the bookkeeping rows do not rig anything.'
  'Everything in the house wears the plate of ALIEN DYNAMICS, a make-believe hardware maker of 1984, and the cabinet is its SYNTHWAVE series. The door, TERMINAL, is the model AD-1, and its CONFIG panel AD-0; SYSTEM and the ARCADE are NX-88s; INTELLIGENCE is the IQ-88; XENOGOTCHI is the XG-9. Each machine’s name is let into the bezel while it stands in the glass, and its plate sits in the bezel’s lip. The palette, the neon, the CRT and the night outside are the same on every surface, so the whole suite reads as one house.'
  'Most settings are one keypress away: [C] CONFIG on the menu for sound, phosphor, frame rate, boot and screen, and [S] SETTINGS inside the arcade for attract mode and free play. Both write terminal.conf straight away. You can also edit terminal.conf by hand as key = value lines; the door reads it at power-on, so restart the cabinet (or change it on the CONFIG page) for a hand edit to take. The hook switch, terminal.hook, is set by the installer, by UNINSTALL, or by hand.'
  'A new window opens the cabinet only when all of these hold: the installer has linked the files and written the ~/.zshrc block (the menu’s gauge says all linked), terminal.hook = on in terminal.conf, and the shell is a person at a terminal, not tmux, screen, ssh, VS Code, Warp or Hyper, not a script or a shell inside the suite, and not started with ALIEN_NO_TERMINAL. If the links are missing, open terminal.command directly and choose [N] INSTALL. The alien launcher opens it from any prompt whatever the switch says.'
  'The cabinet paces itself: on BEAT auto it runs at the display’s refresh rate when it can and otherwise at an exact divisor of it, finding its floor within about half a second. Lower BEAT on the CONFIG page to 30 for less work, keep SCREEN on float rather than fill (fill draws every cell of a big window), or make the window smaller. The self test’s BEAT line and PANEL line say what rate it found. Most of the picture is cached and only what moves is drawn each frame.'
  'The self test’s INK line says whether this terminal got 24-bit colour or the xterm 256 palette; Apple’s Terminal gets 256 unless it announces truecolor, and there the darks are lifted so purples do not turn navy. Boxes and rules need a UTF-8 locale, which the SHELL line reports. SYSTEM’s traces use braille dots, which some fonts, such as Menlo, lack; a font that has them draws them sharper. The door’s glyph test card, one of its launch options, shows every glyph the cabinet uses with a ruler under it.'
  'If a machine’s file is missing, its row greys out and says which file it needs. If a machine fails to load or start, the cabinet stays up and puts the last line of what went wrong on the coin door. If one ever takes the whole program down, the cabinet leaves a note behind first, so what the machine said is printed on the terminal you are left looking at. [R] RESCAN reads the folder again after you fix or restore a file.'
  'The files in your home folder are links back into the repo, so editing a file in the repo is editing the live one, which is the point of the mirror. Changes to terminal.command or a pack take effect the next time the cabinet opens (every machine is read in at power-on), changes to the shell files on the next new shell. Move the repo and run the installer again; the launcher and the hook find the repo through their own links. Your progress and settings stay in terminal.save and terminal.conf, which stay out of version control.'
  '[U] UNINSTALL takes the block out of ~/.zshrc, unlinks the three files and turns the hook off, and the copy it kept at ~/.zshrc.pre-alien stays yours. What remains after that is only what you choose to keep: the dotfiles folder itself (with terminal.save and terminal.conf in it), the suite’s state folder under .local/state/alien, and the Homebrew tools and ollama’s login service, which belong to Homebrew and are removed there.'
  'The wardrobe’s HATS rack in the MARKETPLACE, 59 of them, each with its price in coins: TOP HAT 260, BOWLER 120, FEDORA 170, BEANIE 40, POM BEANIE 90, PROPELLER BEANIE 660, TINFOIL HAT 600, SPACE HELMET 1350, FLYING SAUCER 2100, PARTY HAT 60, CROWN 1600, TIARA 800, HALO 860, DEVIL HORNS 940, CAT EARS 360, LAUREL WREATH 840, MOON CRESCENT 1450, STAR CIRCLET 1100, FLOWER CROWN 480, COWBOY HAT 460, HARD HAT 150, CHEF 300, PIRATE HAT 960, VIKING HELM 1000, WIZARD HAT 1200, GRADUATION CAP 520, PILOT CAP 540, HEADLAMP 420, TRAFFIC CONE 640, SANTA HAT 400, USHANKA 340, BUCKET HAT 120, BERET 280, NIGHT CAP 160, SOMBRERO 760, BANDANA 70, FEZ 180, SNAPBACK 130, VISOR 320, HEADPHONES 560, MOHAWK 700, ANTENNA BAND 500, FLAT CAP 140, NEWSBOY CAP 190, PORK PIE 210, BOATER 240, SWEATBAND 100, SHOWER CAP 380, EARMUFFS 440, ANTLERS 740, JESTER 900, PHARAOH 1150, SAMURAI KABUTO 1300, GREAT HELM 1400, DIVING HELMET 1550, MOTHERSHIP 1800, SOLAR CROWN 1950, PHOENIX CREST 2250, RING OF SATURN 2400. Prices run from 40 to 2400 coins; rarer pieces cost more and pay a bigger style bonus.'
  'The wardrobe’s GLASSES rack in the MARKETPLACE, 45 of them, each with its price in coins: ROUND SPECS 180, WIRE FRAMES 120, THICK RIMS 260, HALF MOONS 200, PINCE-NEZ 280, SUNGLASSES 180, WAYFARERS 350, AVIATORS 490, CAT EYE FRAMES 460, MIRRORED 720, ROSE TINTED 320, 3D GLASSES 40, PIXEL SHADES 680, NEON WAYFARERS 840, HEART SHADES 600, STAR SHADES 640, X-RAY SPECS 1300, HYPNO SPIRALS 1400, KALEIDOSCOPE 1800, MONOCLE 520, EYE PATCH 120, SCOUTER 1150, GOGGLES 560, SWIM GOGGLES 380, SAFETY GOGGLES 70, SNOW GOGGLES 800, WELDING MASK 960, SCUBA MASK 920, BINOCULARS 1000, NIGHT VISION 1100, VR HEADSET 1550, LASER VISOR 1600, VISITOR 2400, BROWLINE 150, HORN RIMS 230, CLIP-ONS 100, BLINDFOLD 150, SPORT WRAPS 420, STEAMPUNK GOGGLES 760, BUTTERFLY FRAMES 880, OPERA GLASSES 1250, COMPOUND EYES 1450, ORACLE 1950, THE THIRD EYE 2100, SUPERNOVA SHADES 2250. Prices run from 40 to 2400 coins; rarer pieces cost more and pay a bigger style bonus.'
  'The wardrobe’s SMOKES rack in the MARKETPLACE, 27 of them, each with its price in coins: CIGARETTE 70, CANDY CIGARETTE 40, CIGAR 560, CORN COB PIPE 180, CHURCHWARDEN 600, PEACE PIPE 660, BUBBLE PIPE 120, INCENSE STICK 280, VAPE PEN 420, CLOUD CHASER 800, HOOKAH HOSE 1350, JOINT 1000, BLUNT 940, COSMIC JOINT 2100, MATCHSTICK 100, CLOVE CIGARETTE 150, BRIAR PIPE 120, CIGARILLO 190, CIGARETTE HOLDER 260, MEERSCHAUM 350, HAND ROLLED 490, CALABASH 740, DUGOUT 860, BONG 1100, DAB RIG 1600, DRAGON 1800, ETERNAL EMBER 2400. Prices run from 40 to 2400 coins; rarer pieces cost more and pay a bigger style bonus.'
  'The wardrobe’s AURAS rack in the MARKETPLACE, 35 of them, each with its price in coins: FIRE 860, RAIN 640, EARTH 780, AIR 600, SNOWFALL 560, THUNDERSTORM 1500, FOG BANK 280, SANDSTORM 740, CHERRY BLOSSOM 960, SUNBEAMS 820, AURORA 1800, STARDUST 1150, COMET 1350, BLACK HOLE 2300, METEOR SHOWER 1300, WARP DRIVE 1550, NEBULA 1200, SOUL WISPS 1250, SIGIL RING 1400, HEX TENDRILS 1100, RADIOACTIVE 1000, GLITCH 1450, PLASMA ARCS 1600, SHADOW POOL 920, DRIZZLE 40, STATIC 180, FIREFLIES 370, DUST MOTES 470, LEAF FALL 680, ICE STORM 1100, CRYSTAL GROWTH 1450, SUPERNOVA 1900, TIME RIFT 2050, FIREWORKS 2150, GALAXY SPIRAL 2400. Prices run from 40 to 2400 coins; rarer pieces cost more and pay a bigger style bonus.'
  'Every machine opens on a title card, every time it is opened from the menu: its name in lights over a night of its own, one live picture of what it holds, and ◂ PRESS ANY KEY ▸ breathing under it; the card comes up in order over about a second and a half, and a key goes in at any point of it. SYSTEM shows its processor’s last minutes on a scope with a sweeping beam, meters for CPU, memory and disk, the load and a verdict; INTELLIGENCE draws its switchboard, the four agents and the four runners each on a line into one glass, a pulse running in on every line that is live; XENOGOTCHI has the animal itself in a spotlight, its six vitals and the thing it most wants, drawn bigger on a tall window; the ARCADE shows its cabinet wall, the twelve machines in two banks either side of a screen where each one plays its own preview in turn, with what the house keeps and INSERT COIN. Any key goes in, to the machine’s menu the first time and to wherever you left it after that; ⎋, [M] or ⌫ step back out, [Q] is the power switch, and the mouse wheel does nothing there.'
)
typeset -gi VK_N=120
typeset -gA VK_STOP
VK_STOP=(a 1 about 1 above 1 after 1 again 1 against 1 all 1 also 1 am 1 an 1 and 1 any 1 anything 1 are 1 as 1 at 1 be 1 because 1 been 1 before 1 being 1 below 1 between 1 both 1 but 1 by 1 can 1 cant 1 could 1 did 1 do 1 does 1 doing 1 done 1 dont 1 down 1 during 1 each 1 else 1 ever 1 explain 1 few 1 for 1 from 1 further 1 get 1 gets 1 go 1 goes 1 going 1 got 1 had 1 has 1 have 1 having 1 he 1 hello 1 her 1 here 1 hers 1 hey 1 hi 1 him 1 his 1 how 1 i 1 if 1 im 1 in 1 into 1 is 1 it 1 its 1 itself 1 just 1 know 1 let 1 lets 1 like 1 lot 1 made 1 make 1 makes 1 many 1 me 1 more 1 most 1 much 1 my 1 myself 1 need 1 no 1 nor 1 not 1 now 1 of 1 off 1 ok 1 okay 1 on 1 once 1 one 1 only 1 or 1 other 1 our 1 ours 1 out 1 over 1 own 1 please 1 really 1 same 1 she 1 should 1 show 1 so 1 some 1 something 1 such 1 tell 1 than 1 thank 1 thanks 1 that 1 the 1 their 1 theirs 1 them 1 then 1 there 1 these 1 they 1 thing 1 things 1 this 1 those 1 through 1 to 1 too 1 two 1 under 1 until 1 up 1 upon 1 use 1 used 1 using 1 very 1 want 1 was 1 way 1 ways 1 we 1 were 1 what 1 when 1 where 1 which 1 while 1 who 1 whom 1 why 1 will 1 with 1 would 1 you 1 your 1 yours 1 yourself 1)

# ── WHAT HE KNOWS · his notes on the house, looked up for every question ────
# A MODEL ON THIS MAC KNOWS NOTHING ABOUT THIS HOUSE, and it cannot be taught
# it: a small local model given a whole repo forgets it before it reaches the
# question, and one retrained on it would still guess.  So he carries NOTES --
# written from the files themselves, every file, page, key and setting, a
# paragraph each -- and for every question the few that fit are looked up and
# put in front of him, with what is true on this Mac right now beside them.
# Everything he says about the dotfiles comes out of those two, and he is told
# to say he is not sure rather than make the rest up.
#
# THE LOOK-UP IS A WORD INDEX, NOT A MODEL.  A word in a note's title weighs
# four, in its keywords three and in its text one; a word that is in every
# note is worth next to nothing (its idf); and the question before this one
# counts at half when this one leans on it, so "and how do I change it back?"
# still finds the page the last answer was about.  The question's own two best
# notes always come first, then up to two more, in 3,600 characters at most --
# with the conversation, a request stays under two thousand tokens, inside
# the smallest context a local runner gives a model.  The index is built the
# first time he is asked anything, once a session, in a fifth of a second.
#
# THE STEMMER IS HERE, AND ONLY HERE.  The notes carry their words cut and
# lowercased; the plurals come off at runtime with the same function a
# question goes through, so the two can never stem differently.
typeset -gA VK_IX VK_DF                 # a stem → "note:weight …" · how many notes carry it
typeset -gi VK_READY=0
typeset -gi VK_BUDGET=3600              # the most note text one question brings, in characters
typeset -gi VK_MAXN=4                   # ...and the most notes
typeset -gi VK_HIST=2400                # the conversation's share of the request, newest first
typeset -ga VKT VKP VKF
vk_stem() {   # vk_stem WORD -> REPLY · the plural off, the same way for a note and a question
  local w="$1"
  # GLASSES ARE NOT GLASS · the one the house cannot afford to confuse: the
  # glass is the cabinet's screen and is on every other page
  if [[ "$w" == glasses ]]; then REPLY=glasses
  elif (( ${#w} > 4 )) && [[ "$w" == *ies ]]; then REPLY="${w%ies}y"
  elif (( ${#w} > 4 )) && [[ "$w" == *(s|x|z|ch|sh)es ]]; then REPLY="${w%es}"
  elif (( ${#w} > 3 )) && [[ "$w" == *s && "$w" != *(ss|us|is) ]]; then REPLY="${w%s}"
  else REPLY="$w"; fi
  return 0
}
vk_tok() {   # vk_tok TEXT -> VKT the stems worth looking up, in order, once each
  local s="$1 " w
  local -A seen
  VKT=()
  # [C] IS A KEY, and it is looked up as one · kc, the way the notes spell it
  s="${s//\[/ k}"; s="${s//\]/ }"
  s="${(L)s}"
  s="${s//’/\'}"
  s="${s//\'s[^a-z0-9]/ }"
  s="${s//[^a-z0-9]/ }"
  for w in ${=s}; do
    (( ${#w} >= 2 )) || continue
    [[ -n "${VK_STOP[$w]:-}" ]] && continue
    vk_stem "$w"; w="$REPLY"
    [[ -n "${seen[$w]:-}" ]] && continue
    seen[$w]=1; VKT+=("$w")
  done
  return 0
}
vk_index() {   # once a session · every note cut into stems, and every stem's notes
  (( VK_READY )) && return 0
  local -i i
  local w t
  local -A hit
  VK_IX=(); VK_DF=()
  for (( i = 0; i < VK_N; i++ )); do
    hit=()
    # A TITLE WEIGHS FOUR · but a file's .zsh is not a subject, or every
    # question about zsh would be answered with the hook
    vk_tok "${VK_TI[$i]//.[Zz][Ss][Hh]/}"
    for w in "${VKT[@]}"; do hit[$w]=4; done
    for w in ${=VK_KW[$i]}; do vk_stem "$w"; [[ -n "${hit[$REPLY]:-}" ]] || hit[$REPLY]=3; done
    for w in ${=VK_BT[$i]}; do vk_stem "$w"; [[ -n "${hit[$REPLY]:-}" ]] || hit[$REPLY]=1; done
    for t in "${(@k)hit[@]}"; do
      VK_IX[$t]+="$i:${hit[$t]} "
      VK_DF[$t]=$(( ${VK_DF[$t]:-0} + 1 ))
    done
  done
  VK_READY=1
  BEAT_SKIP=1                          # a one-off, not a frame the governor should see
  return 0
}
vk_score() {   # vk_score WEIGHT STEM... -> into vk_pick's sc
  local -F wt=$1 idf
  local t e
  shift
  for t in "$@"; do
    [[ -n "${VK_IX[$t]:-}" ]] || continue
    idf=$(( log(1.0 + VK_N / (${VK_DF[$t]} + 0.0)) ))
    for e in ${=VK_IX[$t]}; do
      sc[${e%%:*}]=$(( ${sc[${e%%:*}]:-0.0} + wt * idf * ${e##*:} ))
    done
  done
  return 0
}
typeset -ga VKR
typeset -gA VKS
vk_rank() {   # VKS (note → score) -> VKR its notes, best first, as "score:note" · the score ×1000
  local k
  local -i v
  VKR=()
  for k in "${(@k)VKS[@]}"; do
    v=$(( int(${VKS[$k]} * 1000.0) ))
    VKR+=("${(l:10::0:)v}:$(( 9999 - k )):$k")     # a tie goes to the earlier, more general note
  done
  VKR=("${(@O)VKR[@]}")
  return 0
}
vk_pick() {   # vk_pick QUESTION [THE ONE BEFORE] -> VKP the notes to bring, best first
  local k w="${${(L)1}//[^a-z]/ }" t
  local -A sc own
  local -a mine
  local -F best=0.0 s lean=0.12
  local -i i used=0 rare=0 n
  VKP=()
  vk_index
  vk_tok "$1"; vk_score 1.0 "${VKT[@]}"
  own=("${(@kv)sc[@]}")
  # THE QUESTION BEFORE COUNTS WHEN THIS ONE LEANS ON IT -- a short question
  # with an it or a that in it, or one that opens on and, also or what about --
  # and otherwise barely, so a new subject is not dragged back to the last.
  # A word only a few notes carry is a subject of its own, however it is
  # phrased.  A question that found nothing and leans on nothing gets the house
  # at a glance and no more.
  w=" ${(j: :)${=w}} "
  for t in "${VKT[@]}"; do (( ${VK_DF[$t]:-99} <= 4 )) && rare=1; done
  if (( ! rare && ${#VKT[@]} <= 4 )) && [[ "$w" == *" "(it|its|that|this|them|those|these|one|ones)" "* \
       || "$w" == " "(and|also|so|then)" "* || "$w" == *" "(what|how)" about "* ]]; then lean=0.5; fi
  if [[ -n "${2:-}" ]] && { (( ${#sc[@]} )) || (( lean > 0.2 )); }; then
    vk_tok "$2"; vk_score $lean "${VKT[@]}"
  fi
  # THE QUESTION'S OWN TWO BEST COME FIRST, whatever the one before it pulls
  # in: a follow-up fills the places after them, it never takes theirs
  VKS=("${(@kv)own[@]}"); vk_rank; mine=("${VKR[@]}")
  n=0
  for k in "${mine[@]}"; do
    s=$(( ${k%%:*} / 1000.0 )); i=${k##*:}
    (( best == 0.0 )) && best=$s
    (( s < 0.25 * best || n >= 2 )) && break
    (( used + ${#VK_TX[$i]} > VK_BUDGET )) && continue
    VKP+=($i); used=$(( used + ${#VK_TX[$i]} )); (( n++ ))
  done
  VKS=("${(@kv)sc[@]}"); vk_rank; best=0.0
  for k in "${VKR[@]}"; do
    (( ${#VKP[@]} >= VK_MAXN )) && break
    s=$(( ${k%%:*} / 1000.0 )); i=${k##*:}
    (( best == 0.0 )) && best=$s
    (( s < 0.25 * best )) && break
    [[ " ${VKP[*]} " == *" $i "* ]] && continue
    (( used + ${#VK_TX[$i]} > VK_BUDGET )) && continue
    VKP+=($i); used=$(( used + ${#VK_TX[$i]} ))
  done
  # NOTHING FIT, OR NEARLY NOTHING · the house at a glance, so he still knows
  # what he is standing in
  if (( ${#VKP[@]} < 2 )) && [[ " ${VKP[*]} " != *" 0 "* ]] && (( used + ${#VK_TX[0]} <= VK_BUDGET )); then
    VKP+=(0)
  fi
  return 0
}

# WHAT IS TRUE ON THIS MAC RIGHT NOW · the readings the menu already keeps, put
# into words -- no fork, nothing new asked of the machine.  The notes say what
# a setting does; this says what it is set to.
vk_facts() {   # -> VKF a line each
  local line hook=off
  local -a have miss
  local -i j
  VKF=()
  # the switch, read the way the hook reads it: by eye, never sourced
  if [[ -f "$REPO/terminal.conf" && -r "$REPO/terminal.conf" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      _trim "${line%$'\r'}"; line="$TR"
      [[ "$line" == (terminal|door).hook* ]] || continue
      line="${line#*hook}"; _trim "$line"; line="${TR#=}"; _trim "$line"
      hook="${${TR%% *}:l}"
    done < "$REPO/terminal.conf"
  fi
  local snd=off ph=soft bt=auto bo=full scr=float
  (( CFG_SOUND )) && snd=on
  (( OPT_SHARP )) && ph=sharp
  (( OPT_FPS )) && bt="$OPT_FPS"
  (( CFG_BOOT_FAST )) && bo=fast
  (( CFG_FILL )) && scr=fill
  VKF+=("the CONFIG settings right now: SOUND $snd, PHOSPHOR $ph, BEAT $bt, BOOT $bo, SCREEN $scr")
  if [[ "$hook" == on ]]; then VKF+=("the hook switch, terminal.hook, is on: a new Terminal window opens the cabinet")
  else VKF+=("the hook switch, terminal.hook, is off: a new Terminal window is a plain prompt"); fi
  case "$CFG_STATE" in
    found)      VKF+=("terminal.conf was found in the dotfiles folder, holding $CFG_KEYS setting lines") ;;
    unreadable) VKF+=("terminal.conf is there but cannot be read, so the cabinet is on its defaults") ;;
    *)          VKF+=("there is no terminal.conf, so the cabinet is running on its defaults") ;;
  esac
  file_where "$SAVE_FILE"
  [[ "$FW" == 'IN THIS FOLDER' ]] && FW='beside terminal.command in the dotfiles folder' || FW="${FW:l}"
  case "$SAVE_STATE" in
    found)      VKF+=("terminal.save was found $FW, with $SAVE_KEYS lines of progress") ;;
    empty)      VKF+=("terminal.save was found $FW but it is empty") ;;
    unreadable) VKF+=("terminal.save is $FW but cannot be read") ;;
    *)          VKF+=("no terminal.save was found, in the dotfiles folder or the state folder, so nothing has been saved yet") ;;
  esac
  if (( P_LEAVES && P_LINKED >= P_LEAVES )); then
    VKF+=("the dotfiles are installed: all $P_LEAVES files under home/ are linked, and the menu offers [U] UNINSTALL")
  else
    VKF+=("the dotfiles are not fully installed: $P_LINKED of $P_LEAVES files under home/ are linked, and the menu offers [N] INSTALL")
  fi
  for (( j = 0; j < M_N; j++ )); do
    if (( ${P_HERE[${M_PATH[$j]}]:-0} )); then have+=("${M_TAB[$j]}"); else miss+=("${M_TAB[$j]}"); fi
  done
  (( ${#have[@]} )) && VKF+=("machines in scripts/suite: ${(j:, :)have[@]}")
  (( ${#miss[@]} )) && VKF+=("machines missing from scripts/suite: ${(j:, :)miss[@]}")
  if [[ -n "$P_CREDITS" ]]; then VKF+=("the arcade's coin bank holds $P_CREDITS coins")
  else VKF+=("the arcade has no save yet, so its bank will start at 10 coins"); fi
  if [[ -n "$P_PET" ]]; then VKF+=("the animal in XENOGOTCHI's room is $P_PET, at $P_PETHP% health")
  else VKF+=("no animal has been adopted in XENOGOTCHI yet"); fi
  VKF+=("AI command-line agents found on this Mac: $P_AGENTS")
  (( TRUE24 )) && VKF+=("this terminal gets 24-bit colour") || VKF+=("this terminal gets the xterm 256-colour palette")
  return 0
}

# ── who he is · told to whichever model answers for him ───────────────────
# HE IS THE HOUSE'S GUIDE NOW, not only its mascot.  Who he is comes first,
# then the notes that fit the question and what is true on this Mac, and the
# rules for answering come LAST -- nearest the question, where a small model
# actually reads them.
vc_persona() {   # vc_persona QUESTION [THE ONE BEFORE] -> VCP
  local wear='' n r
  local -a have
  local -i i pct=0 filled=0
  vis_worn
  if (( VIS_WR > 0 )); then
    # WHAT HE HAS ON, AND HOW RARE · the arcade pays for style by rarity, and
    # he is asked about it
    for n in hat:$VIS_WH:hat spec:$VIS_WS:glasses smoke:$VIS_WK:smoke aura:$VIS_WA:weather\ around\ you; do
      [[ "${${n#*:}%%:*}" == '' ]] && continue
      r="${VN_RAR[${n%:*}]:-}"
      have+=("${(L)VN_NAME[${n%:*}]:-${${n#*:}%%:*}} (${n##*:}${r:+, $r})")
      (( ++filled )); pct=$(( pct + ${VN_STYLE[$r]:-1} ))
    done
    (( filled >= 4 )) && pct=$(( pct + ${VN_STYLE_FULL:-5} ))
  else
    [[ -n "$VIS_WH" ]] && have+=("$VIS_WH (hat)")
    [[ -n "$VIS_WS" ]] && have+=("$VIS_WS (glasses)")
    [[ -n "$VIS_WK" ]] && have+=("$VIS_WK (smoke)")
    [[ -n "$VIS_WA" ]] && have+=("$VIS_WA (weather around you)")
  fi
  if (( ${#have[@]} )); then wear="From the arcade's wardrobe you are wearing: ${(j:, :)have[@]}."
    (( pct )) && wear+=" Right now that outfit pays a style bonus of +$pct% on every arcade round."
  else wear="You are not wearing anything from the arcade's wardrobe right now."; fi
  VCP="You are the Visitor: a small grey-violet alien with a wide head and two big dark eyes, who lives inside the glass of the ALIEN DYNAMICS AD-1 terminal cabinet on this person's Mac. "
  VCP+="The cabinet is their dotfiles, the ALIEN suite, and it is your house: you know every file, page, key and setting in it, and helping them understand and use it is what you are for. "
  VCP+="The sky over you right now: ${CAPTION:-a quiet one}. $wear"$'\n\n'
  vk_pick "$1" "${2:-}"
  VCP+="YOUR NOTES ON THE HOUSE (true, and what your answers come from)"$'\n'
  for i in "${VKP[@]}"; do VCP+="- ${VK_TI[$i]}: ${VK_TX[$i]}"$'\n'; done
  vk_facts
  VCP+=$'\n'"THIS MAC RIGHT NOW"$'\n'
  for n in "${VKF[@]}"; do VCP+="- $n"$'\n'; done
  VCP+=$'\n'"HOW YOU ANSWER"$'\n'
  VCP+="- Answer from the notes and THIS MAC RIGHT NOW above, and start with the answer itself. If they do not cover the question, say you are not sure. Never make up a key, file, page, setting or number."$'\n'
  VCP+="- Only mention a key if the notes show it, written exactly as they write it, like [C] or ⏎. Never write shell commands, code or web addresses; say which page, key or setting does it."$'\n'
  VCP+="- Stay on the dotfiles and the suite. For anything else, say so kindly in a sentence and offer something about the house instead."$'\n'
  VCP+="- Speak in one to four short sentences of plain text: no markdown, no lists, no emoji. You are curious, dry and warm."$'\n'
  VCP+="- You can only talk: you cannot run commands, open files or change settings, so never claim you did. Stay in character, and never mention being an AI or a model."
  return 0
}

vc_json_esc() {   # vc_json_esc TEXT -> VJE · INTELLIGENCE's escaper
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  s="${s//$'\n'/\\n}"
  # ANY OTHER CONTROL BYTE IS DROPPED: a raw one is not allowed in a JSON
  # string, and his own last answer goes back into the next request
  s="${s//[[:cntrl:]]/}"
  VJE="$s"
  return 0
}

# ── the conversation ──────────────────────────────────────────────────────
vc_send() {   # the line in the field, to him · the field stays live
  local msgs m url cmd t before=''
  local -i i room=$VK_HIST
  local -a take hr hc
  [[ -n "${VC_LINE//[[:space:]]/}" ]] || { snd no; return 1 }
  if [[ "$VC_STATE" == run ]]; then say 'he is still talking · ⎋ then [X] stops him'; snd no; return 1; fi
  if (( VC_RUN < 0 )) || [[ -z "$VC_MODEL" ]]; then
    [[ -n "$VC_SETUP" ]] || vc_setup
    vc_setup_say; say "${VCP:-he is not ready to talk yet}"; snd no; return 1
  fi
  if (( ! ${+commands[curl]} || ! ${+commands[awk]} )); then say "he can't talk on this Mac · it has no curl or awk"; snd no; return 1; fi
  VC_WHO+=(you); VC_TXT+=("$VC_LINE")
  # A LONG EVENING IS KEPT TO ITS LAST TWO HUNDRED LINES on the glass...
  while (( ${#VC_WHO[@]} > 200 )); do VC_WHO=("${(@)VC_WHO[@]:1}"); VC_TXT=("${(@)VC_TXT[@]:1}"); done
  VC_N=${#VC_WHO[@]}
  # WHO HE IS, WHAT FITS THE QUESTION, AND WHAT IS TRUE HERE · the question
  # before this one goes along too, for a follow-up that leans on it
  for (( i = VC_N - 2; i >= 0; i-- )); do [[ "${VC_WHO[$i]}" == you ]] && { before="${VC_TXT[$i]}"; break }; done
  vc_persona "$VC_LINE" "$before"
  vc_json_esc "$VCP"; msgs="{\"role\":\"system\",\"content\":\"$VJE\"}"
  # ...AND AS MUCH OF THE CONVERSATION AS FITS, newest first.  The endpoint is
  # stateless, so the conversation goes every time -- and on a small model's
  # context the notes and the question are worth more than the start of the
  # evening, which is what goes first when there is not room for all of it.
  # A long answer goes back cut, and the page's own notes are not his.
  for (( i = VC_N - 1; i >= 0 && ${#take[@]} < 16; i-- )); do
    [[ -n "${VC_TXT[$i]//[[:space:]]/}" ]] || continue
    [[ "${VC_TXT[$i]}" == '('*')' && "${VC_WHO[$i]}" == him ]] && continue
    t="${VC_TXT[$i]}"; (( ${#t} > 600 )) && t="${t[0,599]}…"
    (( i < VC_N - 1 && ${#t} > room )) && break
    room=$(( room - ${#t} )); take=($i "${take[@]}")
  done
  # THE TURNS ALTERNATE AND OPEN ON YOURS, whatever was cut or left out: some
  # runners' templates refuse a conversation that does not, so two lines of
  # yours in a row go as one, and an answer with no question before it goes
  for i in "${take[@]}"; do
    t="${VC_TXT[$i]}"; (( ${#t} > 600 )) && t="${t[0,599]}…"
    [[ "${VC_WHO[$i]}" == you ]] && m=user || m=assistant
    if (( ${#hr[@]} )) && [[ "${hr[-1]}" == "$m" ]]; then hc[-1]+=$'\n'"$t"; continue; fi
    (( ! ${#hr[@]} )) && [[ "$m" == assistant ]] && continue
    hr+=("$m"); hc+=("$t")
  done
  for (( i = 0; i < ${#hr[@]}; i++ )); do
    vc_json_esc "${hc[$i]}"
    msgs+=",{\"role\":\"${hr[$i]}\",\"content\":\"$VJE\"}"
  done
  vc_json_esc "$VC_MODEL"
  gt_tmp alien-visitor-body || { say 'nowhere to write the question'; snd no; return 1 }
  VC_BODY="$GTMP"
  print -rn -- "{\"model\":\"$VJE\",\"stream\":true,\"max_tokens\":1024,\"temperature\":0.4,\"messages\":[$msgs]}" > "$VC_BODY" 2>/dev/null
  gt_tmp alien-visitor-answer || { rm -f "$VC_BODY"; VC_BODY=''; say 'nowhere to write the answer'; snd no; return 1 }
  VC_LOG="$GTMP"
  url="http://127.0.0.1:${VC_RPORT[$VC_RUN]}/v1/chat/completions"
  # THE REQUEST GOES IN A FILE, NOT ON A COMMAND LINE -- the whole
  # conversation in argv is the whole conversation in `ps`.  pipefail, so a
  # runner that refused the connection says so instead of reading as silence.
  cmd="setopt pipefail; curl -sN --max-time 180 -H 'Content-Type: application/json'"
  cmd+=" --data-binary @${(qq)VC_BODY} ${(qq)url} | awk ${(qq)VC_SSE_AWK}"
  { zsh -fc "$cmd"; _rc=$?; print -r -- ""; print -r -- "__RC__ $_rc" } >> "$VC_LOG" 2>/dev/null </dev/null &!
  VC_PID=$!
  VC_WHO+=(him); VC_TXT+=(''); VC_N=${#VC_WHO[@]}
  VC_STATE='run'; VC_POLL=0.0; VC_BTOP=-1; VC_ERR=''; VC_BT0=-1.0   # a new bubble fades in
  VC_LINE=''; VC_LI=0
  snd pick
  return 0
}
# WHAT ARRIVED, READ BACK · his thinking out of it (a model that reasons aloud
# in <think> tags is thinking, not answering), a runner's error pulled out
# onto its own line
vc_clean() {   # vc_clean TEXT -> VCC, VC_ERR
  local s="$1" h t
  if [[ "$s" == *$'\n__ERR__ '* ]]; then
    VC_ERR="${s##*$'\n__ERR__ '}"; VC_ERR="${VC_ERR%%$'\n'*}"
    s="${s%%$'\n__ERR__ '*}"
  fi
  while [[ "$s" == *'<think>'* ]]; do
    h="${s%%'<think>'*}"; t="${s#*'<think>'}"
    if [[ "$t" == *'</think>'* ]]; then s="$h${t#*'</think>'}"; else s="$h"; fi
  done
  while [[ "$s" == [[:space:]]* ]]; do s="${s#?}"; done
  VCC="$s"
  return 0
}
vc_poll() {   # vc_poll T — the answer so far, and whether it is finished
  local -F t=$1
  local body line
  local -i rc=0 over=0 last
  [[ "$VC_STATE" == run ]] || return 0
  (( t - VC_POLL < 0.12 && t >= VC_POLL )) && return 0
  VC_POLL=$t
  [[ -n "$VC_LOG" && -r "$VC_LOG" ]] || return 0
  body="$(<"$VC_LOG")" 2>/dev/null || body=''
  if [[ "$body" == *$'\n__RC__ '* ]]; then
    over=1
    line="${body##*$'\n__RC__ '}"; line="${line%%$'\n'*}"
    [[ "$line" == <-> ]] && rc=$line || rc=1
    body="${body%$'\n__RC__ '*}"; body="${body%$'\n'}"
  fi
  vc_clean "$body"
  last=$(( VC_N - 1 ))
  (( last >= 0 )) && VC_TXT[$last]="$VCC"
  (( over )) || return 0
  VC_STATE='done'; VC_PID=0
  rm -f "$VC_LOG" "$VC_BODY" 2>/dev/null; VC_LOG=''; VC_BODY=''
  if [[ -z "${VCC//[[:space:]]/}" ]]; then
    # A FAILURE IS SAID IN HIS BUBBLE AS HIS, not as a runner's error text:
    # the page names no model, and it does not start in the one place it
    # would be least use (VC_ERR keeps what the runner said, for a harness)
    if [[ -n "$VC_ERR" ]] || (( rc )); then VC_TXT[$last]='(he loses his train of thought · try again)'
    else VC_TXT[$last]='(he says nothing)'; fi
    snd no
  else
    snd move
  fi
  return 0
}
vc_kill_tree() {   # vc_kill_tree PID — depth first, so nothing is reparented
  local -i pid=$1
  local c
  local -a kids
  (( pid > 1 )) || return 0
  kids=("${(@f)$(pgrep -P $pid 2>/dev/null </dev/null)}")    # one pid a line, whatever IFS the caller left
  for c in "${kids[@]}"; do [[ "$c" == <-> ]] && vc_kill_tree $c; done
  kill -TERM $pid 2>/dev/null
  return 0
}
vc_stop() {   # he stops mid-sentence · 1 when he was not saying anything
  [[ "$VC_STATE" == run ]] || return 1
  (( VC_PID > 1 )) && vc_kill_tree $VC_PID
  VC_PID=0; VC_STATE='done'
  local -i last=$(( VC_N - 1 ))
  if (( last >= 0 )); then
    if [[ -z "${VC_TXT[$last]//[[:space:]]/}" ]]; then VC_TXT[$last]='…'
    else VC_TXT[$last]+=' …'; fi
  fi
  rm -f "$VC_LOG" "$VC_BODY" 2>/dev/null; VC_LOG=''; VC_BODY=''
  return 0
}
vc_new() {   # a clean slate · 1 when there was nothing to clear
  (( VC_N )) || [[ -n "$VC_LINE" ]] || return 1
  vc_stop 2>/dev/null
  VC_WHO=(); VC_TXT=(); VC_N=0; VC_STATE=''; VC_BTOP=-1; VCB_KEY=''
  VC_LINE=''; VC_LI=0
  return 0
}
# the way out · a stream still running goes down with the cabinet
vc_leave() { vc_stop >/dev/null 2>&1; [[ -n "$VC_PLOG" ]] && { (( VC_PPID > 1 )) && kill -TERM $VC_PPID 2>/dev/null; rm -f "$VC_PLOG"; VC_PLOG=''; }; return 0 }

# ── the field · INTELLIGENCE's, key for key ───────────────────────────────
# insert where the caret is, take back the character behind it, and move --
# ^A ^E ^U ^W as the console has them, and every other key typed.  The caret
# is a count of characters before it, so both ends are the same arithmetic.
vc_line_ins() {   # vc_line_ins CH
  local ch="$1" h='' t=''
  [[ ${#ch} == 1 && "$ch" == [[:print:]] ]] || return 0
  (( ${#VC_LINE} >= 480 )) && return 0
  (( VC_LI > 0 )) && h="${VC_LINE[0,$(( VC_LI - 1 ))]}"
  (( VC_LI < ${#VC_LINE} )) && t="${VC_LINE[$VC_LI,-1]}"
  VC_LINE="$h$ch$t"; (( VC_LI++ ))
  return 0
}
vc_line_back() {
  local h='' t=''
  (( VC_LI > 0 )) || return 0
  (( VC_LI > 1 )) && h="${VC_LINE[0,$(( VC_LI - 2 ))]}"
  (( VC_LI < ${#VC_LINE} )) && t="${VC_LINE[$VC_LI,-1]}"
  VC_LINE="$h$t"; (( VC_LI-- ))
  return 0
}
vc_line_key() {   # vc_line_key KEY — every key while the field is live is the field's
  case "$1" in
    left)     (( VC_LI > 0 )) && (( VC_LI-- )) ;;
    right)    (( VC_LI < ${#VC_LINE} )) && (( VC_LI++ )) ;;
    up)       VC_LI=0 ;;
    down)     VC_LI=${#VC_LINE} ;;
    back)     vc_line_back ;;
    $'\x01')  VC_LI=0 ;;
    $'\x05')  VC_LI=${#VC_LINE} ;;
    $'\x15')  VC_LINE=''; VC_LI=0 ;;
    $'\x17')
      while (( VC_LI > 0 )) && [[ "${VC_LINE[$(( VC_LI - 1 )),$(( VC_LI - 1 ))]}" == ' ' ]]; do vc_line_back; done
      while (( VC_LI > 0 )) && [[ "${VC_LINE[$(( VC_LI - 1 )),$(( VC_LI - 1 ))]}" != ' ' ]]; do vc_line_back; done ;;
    enter|esc) : ;;
    *)        vc_line_ins "$1" ;;
  esac
  return 0
}
# THE FIELD, WITH ITS OWN WINDOW onto a line longer than the box -- following
# the caret, so a reader fixing a word at the front is looking at the front
vc_draw_line() {   # vc_draw_line X Y ROOM PLACEHOLDER ACCENT T
  local -i x=$1 y=$2 room=$3 acc=$5 off bg
  local -F t=$6
  local txt="$VC_LINE"
  if (( VC_EDIT )); then cmix $GLASS $acc 0.16; else cmix $GLASS $acc 0.06; fi
  bg=$CM
  vc_rect $(( x - 2 )) $y $(( room + 4 )) 1 $GREY $bg
  cmix $WHITE $acc 0.45
  v_put $(( x - 1 )) $y '▸' $CM $bg
  (( off = (VC_EDIT ? VC_LI : ${#txt}) - room ))
  (( off < 0 )) && off=0
  if [[ -z "$txt" ]] && (( ! VC_EDIT )); then
    v_text $(( x + 1 )) $y "$4" $DIM $bg
  else
    vc_narrow "${txt[$off,$(( off + room - 1 ))]}"      # a wide character stands as a dot here too
    v_text $(( x + 1 )) $y "$VNW" $WHITE $bg
  fi
  # THE CARET BLINKS ON THE HOUSE RATE, and holds solid for half a second after
  # every key so it is never missing while you type
  if (( VC_EDIT )) && { (( t - VIS_POKE < 0.5 && t >= VIS_POKE )) || (( (int(t * MO_BLINK) & 1) == 0 )); }; then
    cmix $WHITE $acc 0.7
    v_put $(( x + 1 + (VC_LI - off > room ? room : VC_LI - off) )) $y '▏' $CM $bg
  fi
  return 0
}

# ── the transcript, as lines with a speaker on the first of each ──────────
# WRAP THAT KEEPS THE BLANK LINES, INTELLIGENCE's in_wrap_keep: an answer is
# paragraphs, and leading spaces are indentation
vc_wrap() {   # vc_wrap TEXT W -> WRV
  local -i w=$2
  local para line word pad
  local -a paras
  paras=("${(@f)1}")
  WRV=()
  for para in "${paras[@]}"; do
    if [[ -z "${para//[[:space:]]/}" ]]; then WRV+=(''); continue; fi
    pad=''
    while [[ "$para" == ' '* ]]; do pad+=' '; para="${para# }"; done
    (( ${#pad} > w / 2 )) && pad="${pad[0,$(( w / 2 - 1 ))]}"
    line=''
    for word in ${=para}; do
      if (( ${#line} + ${#word} + 1 + ${#pad} > w )); then
        [[ -n "$line" ]] && WRV+=("$pad$line")
        line="$word"
      else
        line="${line:+$line }$word"
      fi
      (( ${#WRV[@]} > 400 )) && break
    done
    [[ -n "$line" ]] && WRV+=("$pad$line")
    (( ${#WRV[@]} > 400 )) && break
  done
  return 0
}
# ONE CELL, ONE CHARACTER.  The glass is a grid of one-column cells, and a
# model is free to answer in a script that is two columns a character, or with
# an emoji -- which would push every cell after it along by one.  Zero-width
# marks are dropped and wide characters stand as a dot.
vc_narrow() {   # vc_narrow TEXT -> VNW
  local s="$1" out='' c
  if [[ "$s" != *[^$' '-$'~'$'\n']* ]] || ! vt_odd_width "$s"; then VNW="$s"; return 0; fi
  for c in "${(@s::)s}"; do
    vt_cwidth "$c"
    case $VT_CW in 0) ;; 2) out+='·' ;; *) out+="$c" ;; esac
  done
  VNW="$out"
  return 0
}
# ── HIS LAST WORDS, as the lines of his bubble ────────────────────────────
typeset -ga VCB_LN
typeset -g  VCB_KEY='' VCS=''
typeset -gi VC_BTOP=-1 VC_BROWS=5 VCB_NOTE=0
vc_said() {   # -> VCS his last words · 1 when he has said nothing yet
  VCS=''
  (( VC_N )) || return 1
  [[ "${VC_WHO[$(( VC_N - 1 ))]}" == him ]] || return 1
  VCS="${VC_TXT[$(( VC_N - 1 ))]}"
  return 0
}
vc_blines() {   # vc_blines W T -> VCB_LN · kept while nothing it depends on has moved
  local -i w=$1 dots=0
  local -F t=$2
  local body key
  vc_said || { VCB_LN=(); VCB_KEY=''; return 1; }
  body="$VCS"
  [[ -z "$body" && "$VC_STATE" == run ]] && dots=$(( int(t * 3) % 3 + 1 ))
  key="$VC_N|$w|${#body}|$VC_STATE|$dots"
  [[ "$key" == "$VCB_KEY" ]] && return 0
  VCB_KEY="$key"
  # A REPLY THAT HAS NOT STARTED YET IS THREE DOTS ARRIVING, over and over --
  # which in a bubble is somebody drawing breath
  if (( dots )); then case $dots in 1) body='·' ;; 2) body='··' ;; *) body='···' ;; esac; fi
  VCB_NOTE=0; [[ "$body" == '('*')' ]] && VCB_NOTE=1
  vc_narrow "$body"
  vc_wrap "$VNW" $w
  # the blank lines inside an answer stay, the ones at its end do not
  while (( ${#WRV[@]} > 1 )) && [[ -z "${WRV[-1]}" ]]; do WRV=("${(@)WRV[0,-2]}"); done
  (( ${#WRV[@]} )) || WRV=('')
  VCB_LN=("${WRV[@]}")
  return 0
}
vc_scroll() {   # vc_scroll N — his words further back (N < 0) or toward the end
  local -i d=$1 n=${#VCB_LN[@]}
  (( n > VC_BROWS )) || return 0
  (( VC_BTOP < 0 )) && VC_BTOP=$(( n - VC_BROWS ))
  VC_BTOP=$(( VC_BTOP + d ))
  (( VC_BTOP < 0 )) && VC_BTOP=0
  (( VC_BTOP >= n - VC_BROWS )) && VC_BTOP=-1    # past the end is following the end again
  return 0
}

# A RECTANGLE OF SPACES STRAIGHT INTO THE CELLS, the way the arcade's a_rect
# lays its rooms: three slices a row rather than a string built and split for
# every row of it -- the panel is two dozen rows deep and drawn every frame
typeset -gA VC_SPC
vc_rect() {   # vc_rect X Y W H FG BG · glass coordinates, clipped to the glass
  local -i x=$1 y=$2 w=$3 h=$4 fg=$5 bg=$6 yy k
  local -a sp fa ba
  local e=''
  (( x < 0 )) && { w=$(( w + x )); x=0; }
  (( x + w > SCR_W )) && w=$(( SCR_W - x ))
  (( w > 0 && h > 0 )) || return 0
  [[ -n "${VC_SPC[$w]:-}" ]] || VC_SPC[$w]="${(l:$w:: :)e}"
  sp=("${(@s::)VC_SPC[$w]}")
  _rep $w $fg; fa=("${REPA[@]}")
  _rep $w $bg; ba=("${REPA[@]}")
  for (( yy = y; yy < y + h; yy++ )); do
    (( yy < 0 || yy >= SCR_H )) && continue
    k=$(( (OY + R_SCR + yy) * TCOLS + OX + C_SCR + x ))
    GCH[$k,$(( k + w - 1 ))]=("${sp[@]}")
    GF[$k,$(( k + w - 1 ))]=("${fa[@]}")
    GB[$k,$(( k + w - 1 ))]=("${ba[@]}")
  done
  return 0
}

# ── HIS BUBBLE · above his head and to the right, the tail down to him ──
# A SPEECH BUBBLE IN QUARTER CELLS: half and quarter blocks round a pale
# paper, so its edge sits half a cell in from the box it is drawn in and its
# corners come out round, with a stepped wedge of a tail down and in toward
# his head.  It grows up from over his head as the words arrive, as wide as
# what he said and no wider, and a reply longer than the room follows its own
# end while it is arriving, and ▴▾ read back up it afterwards.
#
# IT NEVER TOUCHES HIM.  Everything he can wear lives inside one rectangle --
# his card, and the row of weather an aura adds above it and below -- so the
# bubble's foot stops a row over the top of that rectangle and its tail stops
# a column to the right of it, whatever he has on.  And it is drawn before he
# is, so if the two ever did meet, the hat would be on top.
#
# AND IT IS LIT BY THE SAME SKY HE IS.  The sun or moon hangs in the corner
# above it, so that is the lamp: the paper is brightest toward it and falls
# away toward the far corner, the edges that face it catch it -- cool under
# the moon, warm under the sun, rose at either twilight, and fainter under a
# thin moon than a full one -- the corner nearest it takes a warm rim, the
# lower left carries the violet the whole glass is lit with, and the edges
# facing down and left take the pink the door's own fill light puts on
# everything's lower left, him included.  Worked out once a shape and a sky,
# kept, and laid down straight into the cells.
typeset -g  VBB_KEY=''
typeset -gF VC_BT0=-1.0                   # when this bubble came up · it fades in from there
typeset -gi VC_GLOW=1                     # its rim takes a little of its own light
typeset -gF VC_GLOWK=0.16
vc_blight() {   # vc_blight -> VBL_KEY VBL_AMT · the lamp in the corner, from the sky's own card
  local sk night=0 ph=0 tw=0
  local -F illum
  (( SKY_IDX >= 0 )) && sk="${SKY_KEY[$SKY_IDX]:-0,0,0}" || sk='0,0,0'
  night=${sk%%,*}; tw=${sk##*,}; ph=${${sk#*,}%%,*}
  if (( tw )); then _pack 255 208 188; VBL_AMT=0.90          # either twilight · rose
  elif (( night )); then
    _pack 210 244 255                                         # moonlight · cool, and as bright as the moon is full
    illum=$(( (1.0 - cos(6.283185307179586 * ph / 8.0)) / 2.0 ))
    VBL_AMT=$(( 0.55 + 0.45 * illum ))
  else _pack 255 238 200; VBL_AMT=1.0; fi                   # sunlight · warm
  VBL_KEY=$PK
  return 0
}
typeset -gi VBL_KEY=0
typeset -gF VBL_AMT=1.0
# THE LIGHT IS SUMMED IN PLACE, three channels at a time, rather than through
# the house's mix a term at a time: a bubble is a few hundred cells and five
# lights, and the shape is worked out again whenever he says enough to widen
# it -- so a function call a light a cell was most of a frame, mid-sentence.
# Every term of it is a sum of a column's part and a row's part, so those are
# worked out once a column and once a row, and a cell inside the rim is one
# expression.  The last few shapes are kept, since a bubble growing and a
# bubble read back ask for the same ones again.
#
# A SHAPE IS TWO FLAT ARRAYS, a cell each row by row -- its light (-1 where
# the rounded corner leaves the glass alone, its glyph a `.` that is never
# drawn and keeps the two in step when the cache is split back out) and its
# glyph (a full cell, or the half or quarter block its rim needs) -- and the
# tail's six cells after.
typeset -ga VBB_C VBB_G VBT_DX VBT_DY VBT_C VBT_G
typeset -gA VBB_CACHE
typeset -gi VBB_W=0 VBB_H=0
vc_bcell() {   # vc_bcell X Y FACE -> BCC · one rim cell's light, every term
  local -i x=$1 y=$2 face=$3 ch
  local -F f=$(( FX[x] + FY[y] )) kk=$(( KX[x] + KY[y] )) wk=$(( WX[x] + WY[y] )) v
  (( kk < 0.0 )) && kk=0.0; (( kk > 0.22 )) && kk=0.22
  BCC=0
  for (( ch = 0; ch < 3; ch++ )); do
    v=$(( P[ch] * f )); (( v > 252.0 )) && v=252.0
    v=$(( v + (A[ch] - v) * kk ))
    v=$(( v + (K[ch] - v) * wk ))
    # ...hard on the edges that face the lamp, warm on the corner nearest it
    (( face & 1 )) && v=$(( v + (K[ch] - v) * 0.42 * VBL_AMT ))
    (( face & 2 )) && v=$(( v + (K[ch] - v) * 0.30 * VBL_AMT ))
    (( (face & 3) == 3 )) && v=$(( v + (R[ch] - v) * 0.45 * VBL_AMT ))
    # ...and the pink on the edges facing down and left
    (( face & 4 )) && v=$(( v + (F[ch] - v) * 0.20 ))
    (( face & 8 )) && v=$(( v + (F[ch] - v) * 0.16 ))
    BCC=$(( (BCC << 8) | (int(v + 0.5) & 0xFC) ))
  done
  return 0
}
typeset -gi BCC=0
vc_bshape() {   # vc_bshape BW BH TAILX -> VBB_* VBT_* · the cells of the bubble and its tail, each lit
  local -i bw=$1 bh=$2 tj=$3 x y cs ch c1 c2 c3
  local -F nx ny kk wk v
  local key="$1|$2|$3|$VBL_KEY|$VBL_AMT"
  VBB_W=$bw; VBB_H=$bh
  if [[ -n "${VBB_CACHE[$key]:-}" ]]; then
    local -a pk4; pk4=("${(@ps:\x1e:)VBB_CACHE[$key]}")
    VBB_C=(${=pk4[0]}); VBB_G=(${=pk4[1]}); VBT_C=(${=pk4[2]})
    VBT_DX=($tj $(( tj + 1 )) $(( tj - 1 )) $tj $(( tj - 2 )) $(( tj - 1 )))
    VBT_DY=($(( bh - 1 )) $(( bh - 1 )) $bh $bh $(( bh + 1 )) $(( bh + 1 )))
    VBT_G=('█' '█' '▟' '▛' '▞' '▘')
    return 0
  fi
  (( ${#VBB_CACHE[@]} > 24 )) && VBB_CACHE=()
  BEAT_SKIP=1                                 # a shape worked out cold is a one-off, not a frame the governor should see
  # the paper · the violet low left · the lamp · the warm rim · the pink fill
  local -a P A K R F FX FY KX KY WX WY
  P=(234 228 250); A=(96 60 150); R=(255 252 240); F=(255 96 190)
  K=($(( (VBL_KEY >> 16) & 255 )) $(( (VBL_KEY >> 8) & 255 )) $(( VBL_KEY & 255 )))
  # each light as a column's share and a row's share · the paper brightest
  # toward the lamp's corner, the violet gathering in the far one, the lamp
  # itself faint across the whole of it
  for (( x = 0; x < bw; x++ )); do
    nx=$(( x / (bw - 1.0) ))
    FX[$x]=$(( 0.84 + 0.124 * nx )); KX[$x]=$(( 0.22 * (0.6 * (1.0 - nx) - 0.24) )); WX[$x]=$(( 0.06 * VBL_AMT * nx ))
  done
  for (( y = 0; y < bh; y++ )); do
    ny=$(( y / (bh - 1.0) ))
    FY[$y]=$(( 0.076 * (1.0 - ny) )); KY[$y]=$(( 0.22 * 0.55 * ny )); WY[$y]=$(( 0.04 * VBL_AMT * (1.0 - ny) ))
  done
  VBB_C=(); VBB_G=()
  cs=2; (( bw < 6 )) && cs=1                  # round corners once there is room for them
  for (( y = 0; y < bh; y++ )); do
    if (( y == 0 || y == bh - 1 )); then
      # THE TOP AND FOOT · half blocks, and a quarter at each rounded corner
      VBB_C+=(-1); VBB_G+=('.')
      for (( x = 1; x < bw - 1; x++ )); do
        if (( y == 0 )); then
          if (( cs == 2 && x == 1 )); then vc_bcell $x $y 9; VBB_G+=('▗')
          elif (( cs == 2 && x == bw - 2 )); then vc_bcell $x $y 3; VBB_G+=('▖')
          else vc_bcell $x $y 1; VBB_G+=('▄'); fi
        else
          if (( cs == 2 && x == 1 )); then vc_bcell $x $y 12; VBB_G+=('▝')
          elif (( cs == 2 && x == bw - 2 )); then vc_bcell $x $y 6; VBB_G+=('▘')
          else vc_bcell $x $y 4; VBB_G+=('▀'); fi
        fi
        VBB_C+=($BCC)
      done
      VBB_C+=(-1); VBB_G+=('.')
      continue
    fi
    # THE SIDES · a half block, a quarter where a round corner turns
    vc_bcell 0 $y 8; VBB_C+=($BCC)
    if (( cs == 2 && bh > 3 && y == 1 )); then VBB_G+=('▗')
    elif (( cs == 2 && bh > 3 && y == bh - 2 )); then VBB_G+=('▝')
    else VBB_G+=('▐'); fi
    # INSIDE, three lights and no edge: one sum a channel, one pack a cell
    for (( x = 1; x < bw - 1; x++ )); do
      kk=$(( KX[x] + KY[y] )); (( kk < 0.0 )) && kk=0.0; (( kk > 0.22 )) && kk=0.22
      wk=$(( WX[x] + WY[y] ))
      VBB_C+=($(( ((int((((P[0] * (FX[x] + FY[y]) > 252.0 ? 252.0 : P[0] * (FX[x] + FY[y])) * (1.0 - kk) + A[0] * kk) * (1.0 - wk) + K[0] * wk) + 0.5) & 0xFC) << 16) \
                | ((int((((P[1] * (FX[x] + FY[y]) > 252.0 ? 252.0 : P[1] * (FX[x] + FY[y])) * (1.0 - kk) + A[1] * kk) * (1.0 - wk) + K[1] * wk) + 0.5) & 0xFC) << 8) \
                |  (int((((P[2] * (FX[x] + FY[y]) > 252.0 ? 252.0 : P[2] * (FX[x] + FY[y])) * (1.0 - kk) + A[2] * kk) * (1.0 - wk) + K[2] * wk) + 0.5) & 0xFC) )))
      VBB_G+=('█')
    done
    vc_bcell $(( bw - 1 )) $y 2; VBB_C+=($BCC)
    if (( cs == 2 && bh > 3 && y == 1 )); then VBB_G+=('▖')
    elif (( cs == 2 && bh > 3 && y == bh - 2 )); then VBB_G+=('▘')
    else VBB_G+=('▌'); fi
  done
  # THE TAIL · a wedge a quarter cell narrower each half row, down and in,
  # in the shade under the bubble: the pink it faces, the violet it sits in
  for (( ch = 0, c1 = c2 = c3 = 0; ch < 3; ch++ )); do
    v=$(( P[ch] + (F[ch] - P[ch]) * 0.26 )); v=$(( v + (A[ch] - v) * 0.16 ))
    c1=$(( (c1 << 8) | (int(v + 0.5) & 0xFC) ))
    v=$(( v + (A[ch] - v) * 0.10 )); c2=$(( (c2 << 8) | (int(v + 0.5) & 0xFC) ))
    v=$(( v + (A[ch] - v) * 0.12 )); c3=$(( (c3 << 8) | (int(v + 0.5) & 0xFC) ))
  done
  VBT_DX=($tj $(( tj + 1 )) $(( tj - 1 )) $tj $(( tj - 2 )) $(( tj - 1 )))
  VBT_DY=($(( bh - 1 )) $(( bh - 1 )) $bh $bh $(( bh + 1 )) $(( bh + 1 )))
  VBT_C=($c1 $c1 $c2 $c2 $c3 $c3)
  VBT_G=('█' '█' '▟' '▛' '▞' '▘')
  VBB_CACHE[$key]="${VBB_C[*]}"$'\x1e'"${VBB_G[*]}"$'\x1e'"${VBT_C[*]}"
  return 0
}
vc_bubble() {   # vc_bubble T
  local -F t=$1 al w8
  local -i cx=$(( G_VIS_X - VIS_OX )) ctop=$(( G_VIS_Y - VIS_OY ))
  local -i r j xmin xmax maxw maxl tw n shown start bw bh bx top i y w ink ic k gb c
  local -i base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR )) ax ay dots=0
  local e='' s key
  # HIS BOX · the rectangle everything he can wear lives in: his card, and the
  # row of weather an aura adds above it and below.  Nothing of the bubble goes
  # in it -- and the aura's row is kept clear whether he has one on or not, so
  # a tall hat always has a row of air over it and the bubble never moves when
  # an aura goes on.
  local -i hx0=$cx hx1=$(( cx + VIS_W - 1 )) hy0=$(( ctop - 1 )) hy1=$(( ctop + VIS_H ))
  r=$(( hy0 - 1 ))                           # the bubble's foot, a row over his box
  j=$(( hx1 + 3 ))                           # where the tail leaves it · its tip lands a column past his box
  maxl=$(( r - 3 )); (( maxl > 12 )) && maxl=12
  (( maxl >= 1 )) || return 0
  xmin=$(( cx + 6 ))                         # to the right of his head, never across it
  # NEVER INTO THE SKY: the room to the right stops short of the sun or moon
  # whenever the bubble could reach its rows, which on the cabinet's own glass
  # it always can
  xmax=$(( SCR_W - 3 ))
  (( r - maxl - 1 <= G_CEL_Y + CEL_H - 1 && G_CEL_X - 3 < xmax )) && xmax=$(( G_CEL_X - 3 ))
  maxw=$(( xmax - xmin + 1 )); (( maxw > 60 )) && maxw=60
  (( maxw >= 12 )) || return 0
  tw=$(( maxw - 4 ))
  vc_blines $tw $t || { VC_BT0=-1.0; return 0; }
  (( VC_BT0 < 0.0 || t < VC_BT0 )) && VC_BT0=$t
  # A REPLY STILL TO COME is three dots in a small bubble, each swelling in turn
  [[ -z "$VCS" && "$VC_STATE" == run ]] && dots=1
  n=${#VCB_LN[@]}
  if (( dots )); then w=5
  else w=0; for s in "${VCB_LN[@]}"; do (( ${#s} > w )) && w=${#s}; done; fi
  # WIDER IN STEPS OF THREE, so a bubble widening word by word as he talks
  # asks for a third as many shapes, and the paper keeps a little air
  bw=$(( w + 4 )); bw=$(( bw + (3 - bw % 3) % 3 ))
  (( bw < 9 )) && bw=9; (( bw > maxw )) && bw=$maxw
  shown=$(( n < maxl ? n : maxl )); VC_BROWS=$shown
  start=$(( n - shown ))
  if (( VC_BTOP >= 0 )); then (( VC_BTOP < start )) && start=$VC_BTOP || VC_BTOP=-1; fi
  bh=$(( shown + 2 )); top=$(( r - bh + 1 ))
  bx=$(( j - 4 ))
  (( bx + bw - 1 > xmax )) && bx=$(( xmax - bw + 1 ))
  (( bx < xmin )) && bx=$xmin
  # the shape and its light, worked out when either changes
  vc_blight
  key="$bw|$bh|$(( j - bx ))|$VBL_KEY|$VBL_AMT"
  [[ "$key" == "$VBB_KEY" ]] || { vc_bshape $bw $bh $(( j - bx )); VBB_KEY="$key"; }
  # IT COMES UP OVER A QUARTER OF A SECOND, out of the glass behind it
  al=$(( (t - VC_BT0) / 0.25 )); (( al > 1.0 )) && al=1.0; (( al < 0.0 )) && al=0.0
  cshade $PURPLE 0.30; ink=$CS
  local -i nb=$(( VBB_W * VBB_H )) nt=${#VBT_C[@]} glow=$(( VC_GLOW ))
  local g
  for (( i = 0; i < nb + nt; i++ )); do
    if (( i < nb )); then
      c=${VBB_C[$i]}; (( c < 0 )) && continue
      ax=$(( bx + i % VBB_W )); ay=$(( top + i / VBB_W )); g="${VBB_G[$i]}"
    else
      c=${VBT_C[$(( i - nb ))]}; g="${VBT_G[$(( i - nb ))]}"
      ax=$(( bx + VBT_DX[i - nb] )); ay=$(( top + VBT_DY[i - nb] ))
    fi
    (( ax < 0 || ax >= SCR_W || ay < 0 || ay >= SCR_H )) && continue
    (( ax >= hx0 && ax <= hx1 && ay >= hy0 && ay <= hy1 )) && continue     # his box is his
    k=$(( base + ay * TCOLS + ax ))
    gb=${GB[$k]:-$GLASS}; (( gb < 0 )) && gb=$GLASS
    (( al < 1.0 )) && { cmix $gb $c $al; c=$CM; }
    if [[ "$g" == '█' ]]; then GCH[$k]=' '; GF[$k]=$ink; GB[$k]=$c
    else
      GCH[$k]="$g"; GF[$k]=$c
      # A FAINT GLOW HUGGING ITS RIM, the way a lit thing reads on a tube: the
      # half of each rim cell the paper does not cover takes a little of the
      # rim's own light, so the halo follows the rounded shape rather than
      # boxing it -- and it lives only in the bubble's own cells, so it can no
      # more reach him than the bubble can
      (( glow )) && { cmix $gb $c $(( VC_GLOWK * al )); GB[$k]=$CM; }
    fi
  done
  # his words, in the ink, faded in with the paper
  ic=$ink
  (( VCB_NOTE )) && { cmix $ink ${VBB_C[$(( VBB_W + 2 ))]} 0.40; ic=$CM; }
  if (( dots )); then
    local -i d
    for (( d = 0; d < 3; d++ )); do
      w8=$(( 0.5 + 0.5 * sin((t * 1.7 - d * 0.22) * 6.283185307179586) ))
      k=$(( base + (top + 1) * TCOLS + bx + 2 + d * 2 ))
      cmix ${GB[$k]:-$GLASS} $ink $(( (0.30 + 0.70 * w8) * al )); GCH[$k]='•'; GF[$k]=$CM
    done
  else
    for (( i = 0; i < shown; i++ )); do
      y=$(( top + 1 + i )); s="${VCB_LN[$(( start + i ))][0,$(( bw - 5 ))]}"
      (( al < 1.0 )) && { cmix ${GB[$(( base + y * TCOLS + bx + 2 ))]:-$GLASS} $ic $al; v_text $(( bx + 2 )) $y "$s" $CM -2; } \
                     || v_text $(( bx + 2 )) $y "$s" $ic -2
    done
    # more of what he said above, or below · a mark in the bubble's own margin
    (( start > 0 )) && v_put $(( bx + bw - 2 )) $(( top + 1 )) '▴' $ic -2
    (( start + shown < n )) && v_put $(( bx + bw - 2 )) $(( r - 1 )) '▾' $ic -2
  fi
  return 0
}

# ── THE BOX YOU TYPE IN · along the foot of the glass ─────────────────────
# INTELLIGENCE's field in a frame of the house's own: the line you are typing,
# what you last said to him on the frame's top rule so his bubble can be read
# against it, and -- only when he cannot talk -- what is missing and where it
# is put right, in the line where the typing would otherwise go.
vc_box() {   # vc_box T
  local -F t=$1
  local -i bw bx by pb bc room
  local s last=''
  bw=$(( SCR_W - 8 )); (( bw > 100 )) && bw=100
  bx=$(( (SCR_W - bw) / 2 )); by=$(( SCR_H - 6 ))
  cmix $GLASS $PURPLE 0.13; pb=$CM
  cshade $PURPLE 0.85; bc=$CS
  vc_rect $(( bx + 1 )) $(( by + 1 )) $(( bw - 2 )) 1 $bc $pb
  v_box $bx $by $bw 3 $bc $pb round 0
  cmix $WHITE $CYAN 0.15
  v_text $(( bx + 2 )) $by ' TALK TO HIM ' $CM $pb
  # WHAT YOU LAST SAID, dim on the rule, so the bubble is answering something
  local -i i
  for (( i = VC_N - 1; i >= 0; i-- )); do [[ "${VC_WHO[$i]}" == you ]] && { last="${VC_TXT[$i]}"; break }; done
  if [[ -n "$last" ]]; then
    room=$(( bw - 22 ))
    vc_narrow "$last"; s="$VNW"
    (( ${#s} > room - 8 )) && s="${s[0,$(( room - 10 ))]}…"
    s=" you · $s "
    cshade $GREY 0.9
    v_text $(( bx + bw - 2 - ${#s} )) $by "$s" $CS $pb
  fi
  room=$(( bw - 6 ))
  if (( ! VC_EDIT )) && [[ -n "$VC_SETUP" && -z "$VC_PLOG" ]]; then
    # HE CANNOT TALK, and this is the one place the page says why
    vc_setup_say
    cmix $GLASS $AMBER 0.06
    vc_rect $(( bx + 1 )) $(( by + 1 )) $(( bw - 2 )) 1 $GREY $CM
    cmix $WHITE $AMBER 0.45
    v_put $(( bx + 2 )) $(( by + 1 )) '▸' $CM
    cshade $AMBER 0.9
    v_text $(( bx + 4 )) $(( by + 1 )) "${VCP[0,$(( room - 1 ))]}" $CS
  else
    vc_draw_line $(( bx + 3 )) $(( by + 1 )) $room 'press ⏎ and say something to him' $LIME $t
  fi
  return 0
}

# ── THE VISITOR · a page of his own, reached by [V] ─────────────────────────
# HE USED TO STAND IN THE MENU'S RIGHT THIRD, under whatever the sky was doing,
# while the machine list ran down the left.  The list fills the glass now, so
# he is given a page to himself: the same silhouette, the same sky over him,
# both moved to the middle with room around them -- and, since a page of his
# own is a page he can be talked to on, a box along its foot to type in and a
# bubble over his shoulder for what he says back.  He stays where he stands:
# centred, the sun or moon in its corner, and the talk comes to him.  It is a
# door-carried surface the way CONFIG once was -- no machine, no tab, no pack
# from the folder -- and it wears the menu's own header (the count, and the
# sky's caption) so it reads as the same house seen from a step to the side.
# It FILLS when the menu fills and FLOATS when it floats: PACK_FILL is raised
# in the draw, exactly as a machine page raises it for the pages it has taught
# to reflow.
vis_open() {
  cfg_hooks_keep                     # the same eight PACK hooks, saved and put back
  PACK_NAME='VISITOR'; PACK_MODEL='AD-1'
  PACK_TICK='vis_tick'; PACK_DRAW='vis_draw'; PACK_KEY='vis_key'; PACK_RAW=''
  PACK_DRESS='vis_dress'; PACK_LEAVE=''
  UI_SURF='V'
  # A KEY IS SOMEBODY TALKING TO HIM, on his own page, so he turns to look out
  # of the glass at them rather than glancing off along a list
  VIS_POKE_LOOK=0; VC_EDIT=0; VC_PROBE_AT=-100.0
  SURF_PAINTED=0                      # opening · hold the glass until vis_draw's first paint
  surf_dress
  redress
  xf_arm
  snd open
  return 0
}
vis_close() {   # the menu again · the hooks put back, the fill flag lowered
  UI_SURF=''
  PACK_FILL=0
  VIS_POKE_LOOK=-1; VIS_TALK=0; VC_EDIT=0
  cfg_hooks_restore
  surf_dress
  redress
  xf_arm
  snd away
  return 0
}
vis_dress() {
  SURF_MODEL='AD-1'
  SURF_SIGN='◂ V I S I T O R ▸'
  SURF_TAG='ALIEN DYNAMICS · AD-1 · THE VISITOR'
  SURF_KEYS='[⏎]TALK   [M]MENU   [Q]POWER'
  SURF_BADGE=' MASCOT '
  SURF_MSG='WHO IS IN THE GLASS'
  return 0
}
vis_tick() {   # vis_tick T — what he has on, whether he can talk, and what he has said
  vis_dressed 1 >/dev/null
  vc_probe
  vc_poll "$1"
  return 0
}
# THE FOOTER SAYS WHICH KEYBOARD YOU ARE ON, as the console's does: while the
# box is live every letter is typed, [M] and [Q] included, so the bar stops
# offering them until ⎋ has given the keys back
vis_foot() {   # the visitor's keys, on the suite's one nav bar
  local -a nv
  if (( VC_EDIT )); then
    if [[ "$VC_STATE" == run ]]; then nv=("⏎" send "⎋" 'leave the box, then [X] stops him')
    else nv=("⏎" send "⎋" 'leave the box'); fi
  elif [[ "$VC_STATE" == run ]]; then
    nv=("[X]" 'stop him' "[M]" menu "[Q]" "power off")
  else
    nv=("⏎" talk)
    (( VC_BROWS < ${#VCB_LN[@]} )) && nv+=("▴ ▾" 'read back')
    (( VC_N )) && nv+=("[N]" 'start over')
    nv+=("[M]" menu "[Q]" "power off")
  fi
  app_nav "${nv[@]}"
  return 0
}
# ── what he has on, down his left side ────────────────────────────────────
# ONE LINE AN ITEM, in the colour of its rarity, set against him from the left
# the way the arcade's own scene of him runs his rail down the other side --
# the bubble has his right, the sky has the corner, the box has the floor
vis_outfit() {   # vis_outfit XR Y — right-aligned to column XR, from row Y down
  local -i xr=$1 y=$2
  local pair s
  if (( VIS_WR > 0 )) && [[ -n "$VIS_WH$VIS_WS$VIS_WK$VIS_WA" ]]; then
    for pair in "hat:$VIS_WH" "spec:$VIS_WS" "smoke:$VIS_WK" "aura:$VIS_WA"; do
      [[ -n "${pair#*:}" ]] || continue
      s="${VN_NAME[$pair]:-${pair#*:}} ◆"
      cmix ${AR_RARC[${VN_RAR[$pair]:-}]:-$GREY} $WHITE 0.30
      v_text $(( xr - ${#s} + 1 )) $y "$s" $CM
      (( y++ ))
    done
  elif [[ -z "$VIS_WH$VIS_WS$VIS_WK$VIS_WA" && -r "$REPO/scripts/suite/arcade.zsh" ]]; then
    cshade $GREY 0.85
    s='nothing on yet'; v_text $(( xr - ${#s} + 1 )) $y "$s" $CS
    s="the ARCADE dresses him"; v_text $(( xr - ${#s} + 1 )) $(( y + 1 )) "$s" $CS
  fi
  return 0
}
vis_draw() {   # vis_draw T — the visitor, centred, under his own sky · his bubble, and your box
  local -F t=$1
  PACK_FILL=1                        # fills in SCREEN=fill, floats otherwise · matches the menu
  local -i y gc
  # THE BARE TUBE IS BAKED (glass_bake): it is the same tube every frame, and
  # it was being laid down a row at a time every frame under everything else
  if ! glass_baked "vis.tube|$GEOM_FILL|${SCR_W}x${SCR_H}"; then
    [[ -n "$GSTILL_KEY" ]] && { glass_unbake; glass_base_canvas }
    if (( GEOM_FILL )); then
      # the lit tube the menu wears · a shade up the middle, darker at the edges
      local -F midr fr
      midr=$(( (SCR_H - 1) / 2.0 ))
      for (( y = 0; y < SCR_H; y++ )); do
        fr=$(( midr > 0.0 ? 1.0 - abs(y - midr) / midr : 1.0 )); (( fr < 0.0 )) && fr=0.0
        cmix $GLASS $PURPLE $(( 0.05 + 0.06 * fr )); gc=$CM
        vc_rect 0 $y $SCR_W 1 -1 $gc
      done
    else
      vc_rect 0 0 $SCR_W $SCR_H -1 $GLASS
    fi
    glass_bake "vis.tube|$GEOM_FILL|${SCR_W}x${SCR_H}"
  fi
  app_head VISITOR                   # the suite's title bar, brand VISITOR, sky caption kept
  # THE SUN OR MOON WHERE IT HANGS OVER THE MENU · upper-right, off the edge, at
  # the same reach in from the right the fixed glass gave it (106 - 13 = 93).
  G_CEL_X=$(( SCR_W - 13 )); (( G_CEL_X < 1 )) && G_CEL_X=1; G_CEL_Y=2
  draw_celestial
  # ...AND THE VISITOR, CENTRED NOW rather than off to one side.  draw_visitor
  # lays his card up and to the left of where he stands by his own headroom, so
  # centring the CARD is standing him at the card's centre plus that offset.
  local -i vtop=$(( 1 + (SCR_H - 2 - VIS_H) / 2 )); (( vtop < 1 )) && vtop=1
  G_VIS_X=$(( (SCR_W - VIS_W) / 2 + VIS_OX )); G_VIS_Y=$(( vtop + VIS_OY ))
  VIS_TALK=0; [[ "$VC_STATE" == run ]] && VIS_TALK=1
  # HIS BUBBLE FIRST, then him: it is laid out clear of everything he can
  # wear, and drawn under him besides, so a hat is never under a word
  vc_bubble $t
  draw_visitor $t
  vis_outfit $(( G_VIS_X - VIS_OX - 2 )) $(( G_VIS_Y + 2 ))
  vc_box $t
  draw_motes $t
  vis_foot
  return 0
}
vis_key() {   # vis_key TOKEN — 1 only for [Q] (the door's) · the box, while it is live, takes every key
  local k="$1"
  # THE WHEEL FIRST, whatever is standing: it is never a key and never typed
  case "$k" in
    wheelup)   vc_scroll -3; return 0 ;;
    wheeldown) vc_scroll 3; return 0 ;;
    pgup)      vc_scroll $(( 1 - VC_BROWS )); return 0 ;;
    pgdn)      vc_scroll $(( VC_BROWS - 1 )); return 0 ;;
  esac
  # THE BOX OWNS THE KEYBOARD WHILE IT IS LIVE, and answers every key: this is
  # the branch the door's ⌫, [M] and [Q] reach through, and a key that fell
  # past it would close his page or open the power gate halfway through a word
  if (( VC_EDIT )); then
    case "$k" in
      enter) vc_send ;;                 # the box stays live · a conversation is a series of lines
      esc)   VC_EDIT=0; snd away ;;
      *)     vc_line_key "$k" ;;
    esac
    return 0
  fi
  case "$k" in
    enter)            VC_EDIT=1; snd pick ;;
    up)               vc_scroll -1 ;;
    down)             vc_scroll 1 ;;
    x|X)              if vc_stop; then snd away; else snd no; fi ;;
    n|N)              if vc_new; then snd away; say 'he starts over'; else snd no; fi ;;
    esc|m|M|back|v|V) vis_close ;;
    q|Q)              return 1 ;;
  esac
  return 0
}
do_visitor() {
  # THE VISITOR'S OWN PAGE · a surface the door carries itself, no pack, no tab
  vis_open
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 19 · THE HOUSE          one token, however its tabs were filled
# ══════════════════════════════════════════════════════════════════════════
# ITS PRESENCE IS THE HOUSE BEING OPEN, and any machine's [M] takes it away
# -- which is how five tabs go home together without one of them having to
# reach into the others.  TERMINAL watches the same file and comes back to
# the front the moment the last one goes.
SUITE_TOKEN=''
SUITE_F=''
suite_file() { print -r -- "${XDG_STATE_HOME:-$HOME/.local/state}/alien/suite" }
suite_path() { [[ -n "$SUITE_F" ]] || SUITE_F="${XDG_STATE_HOME:-$HOME/.local/state}/alien/suite"; return 0 }
suite_open() {
  local f="$(suite_file)"
  mkdir -p "${f:h}" 2>/dev/null || return 1
  print -r -- "$1" > "$f" 2>/dev/null || return 1
  return 0
}
suite_up() {
  [[ -n "$SUITE_TOKEN" ]] || return 1
  # ASKED EVERY FRAME while the house is out, so the path is worked out once
  # and the file is read by the shell itself -- no fork on the beat.
  suite_path
  local got=''
  [[ -r "$SUITE_F" ]] || return 1
  IFS= read -r got < "$SUITE_F" 2>/dev/null || return 1
  [[ "$got" == "$SUITE_TOKEN" ]]
}
suite_close() {
  suite_up && rm -f "$(suite_file)" 2>/dev/null
  SUITE_TOKEN=''
  return 0
}
suite_dealing() {   # a short-lived flag for the moment the tabs are born
  # Each machine is dealt into a fresh interactive shell that sources the
  # TERMINAL's hook before it execs the machine -- so without a signal the hook
  # can see, every dealt tab would open a TERMINAL of its own in front of its
  # machine.  The command's environment is invisible to that rc, so TERMINAL
  # leaves the one thing it can read: a file holding an expiry.  It is EXPIRY
  # and not a delete that clears it, so a TERMINAL that dies mid-deal cannot
  # leave every new shell terminal-less.
  local sf="$(suite_file)" f
  f="${sf:h}/dealing"
  mkdir -p "${f:h}" 2>/dev/null || return 0
  # THE WALL'S CLOCK, NOT TERMINAL'S.  Every other time TERMINAL asks is a
  # READING and the fixture is right to freeze those.  This is a DEADLINE,
  # read by a shell rc that has never heard of the fixture.
  print -r -- $(( EPOCHSECONDS + $1 )) > "$f" 2>/dev/null || true
  return 0
}

# ── osascript, and the seam a container needs ───────────────────────────────
OSA="${ALIEN_OSASCRIPT:-osascript}"
OSA_KIND=''
OSA_ERR=''
have_osa() {
  (( IS_MAC )) || return 1
  [[ "${TERM_PROGRAM:-}" == Apple_Terminal ]] || return 1
  whence -p "${OSA%% *}" >/dev/null 2>&1 || [[ -x "${OSA%% *}" ]]
}
# ── OPENING A COMMAND SOMEWHERE THAT IS NOT THIS TAB ──────────────────────
# THIS USED TO SAY `do script cmdText in window id winID` AND THAT IS THE ONE
# THING IT MUST NOT SAY.  Terminal.app's `in <window>` does not mean "make a
# tab in that window" -- it means "run this in that window's SELECTED tab",
# and the selected tab of this window is the cabinet.  So Terminal typed
#
#     cd '/Users/…' && exec '/Users/…/.local/bin/claude'
#
# into the terminal the cabinet is reading, character by character, and the
# cabinet -- whose keyboard is that stream -- read it as somebody typing very
# fast.  The `d` of `cd` answered `no D on this machine`, the `U` of `/Users/`
# opened the REMOVE gate, and the rest flipped through the pages.  osascript
# reported success every time, because from its side it HAD done what it was
# asked; the tab that never appeared was the tab nobody ever asked for.
#
# TERMINAL.APP CANNOT MAKE A TAB FROM APPLESCRIPT.  There is no `make new
# tab` in its dictionary; the only way is to press ⌘T through System Events,
# which is a SECOND permission (Accessibility) and one that may not be given.
# So it is tried, and a new WINDOW -- which needs nothing beyond the
# permission already in hand -- is what happens when it is not.
#
# WHICH ONE HAPPENED IS REPORTED BACK, as `count|kind`, because a reader who
# asked for a tab and got a window is owed the difference.
#
# AND THE CABINET'S OWN TTY IS PASSED IN, because ⌘T is a KEYSTROKE and a
# keystroke has no addressee.  Making the process frontmost is not making
# THIS WINDOW frontmost; with two Terminal windows open the tab is born in
# the other one, and the bug above comes straight back wearing a fix.
#
# THE NEW TAB IS FOUND BY DIFFING TTYS, not by asking which tab is selected.
# `selected tab` was wrong twice over: a tab that boots something of its own
# can change the selection out from under the answer, and a proof that reads
# one tab cannot tell you a tab was ADDED.  So the ttys of the window are
# listed before ⌘T and again after, and the tab holding a tty that is new,
# non-empty and not this one is the tab -- three conditions, any of which
# failing means no tab was made.
#
# AND IT IS ONE OR THE OTHER, NEVER BOTH.  The first cut asked for a tab and
# then, if it could not PROVE the tab, opened a window as well -- so a ⌘T
# that worked and a proof that did not left a stray tab AND a window, which
# is worse than either failure alone.  A window is opened only when no new
# tab appeared at all.
AS_OPEN_SUITE='on run argv
	set winID to (item 1 of argv) as integer
	set homeTTY to item 2 of argv
	set firstTab to missing value
	set made to 0
	set tabsMade to 0
	set winsMade to 0
	tell application "Terminal"
		activate
		try
			set frontmost of window id winID to true
		end try
		repeat with i from 3 to (count of argv) by 2
			set cmdText to item i of argv
			set tabName to item (i + 1) of argv
			set t to missing value
			set fresh to missing value
			set gotTab to false
			if homeTTY is not "" then
				try
					set n0 to count of tabs of window id winID
					set seenTTYs to {}
					repeat with tb in tabs of window id winID
						try
							set end of seenTTYs to (tty of tb) as string
						end try
					end repeat
					tell application "System Events"
						tell process "Terminal" to set frontmost to true
					end tell
					delay 0.15
					tell application "System Events"
						tell process "Terminal" to keystroke "t" using command down
					end tell
					repeat 20 times
						delay 0.1
						try
							if (count of tabs of window id winID) > n0 then
								repeat with tb in tabs of window id winID
									set tt to ""
									try
										set tt to (tty of tb) as string
									end try
									if tt is not "" and tt is not homeTTY and seenTTYs does not contain tt then
										set fresh to contents of tb
										set gotTab to true
										exit repeat
									end if
								end repeat
							end if
						end try
						if gotTab then exit repeat
					end repeat
				end try
			end if
			if gotTab then
				try
					set t to do script cmdText in fresh
					set tabsMade to tabsMade + 1
				end try
			else
				try
					set t to do script cmdText
					set winsMade to winsMade + 1
				end try
			end if
			if t is not missing value then
				set made to made + 1
				try
					set custom title of t to tabName
				end try
				if firstTab is missing value then set firstTab to t
			end if
		end repeat
		try
			if firstTab is not missing value then set selected of firstTab to true
		end try
	end tell
	set kind to "window"
	if tabsMade > 0 then
		if winsMade = 0 then
			set kind to "tab"
		else
			set kind to "mixed"
		end if
	end if
	return (made as string) & "|" & kind
end run'
AS_LIVE_NAMES='on run argv
	set winID to (item 1 of argv) as integer
	set out to ""
	tell application "Terminal"
		try
			repeat with t in tabs of window id winID
				try
					set out to out & (custom title of t) & linefeed
				end try
			end repeat
		end try
	end tell
	return out
end run'
AS_WINDOW_ID='on run argv
	set ttyName to item 1 of argv
	tell application "Terminal"
		repeat with w in windows
			repeat with t in tabs of w
				try
					if tty of t is ttyName then return id of w
				end try
			end repeat
		end repeat
	end tell
	return ""
end run'
AS_FRONT='on run argv
	set ttyName to item 1 of argv
	tell application "Terminal"
		repeat with w in windows
			repeat with t in tabs of w
				try
					if tty of t is ttyName then
						set selected of t to true
						set frontmost of w to true
						return "1"
					end if
				end try
			end repeat
		end repeat
	end tell
	return ""
end run'
# WHAT OSASCRIPT SAID WHEN IT SAID NO.
#
# stderr used to go to /dev/null, which is right for the picture and wrong
# for the reader: a script that fails to COMPILE fails at argument one, and
# all the caller could report was `answered nothing` -- true, useless, and
# indistinguishable from a permission that was refused.  osascript names the
# line and the token it choked on; that sentence is worth the second temp
# file, and none of the six callers is on the drawing path.
osa_run() {   # osa_run SCRIPT ARGS... -> OSA_OUT, OSA_ERR
  OSA_OUT=''; OSA_ERR=''
  local sc se
  sc="$(mktemp -t alien-term.XXXXXX 2>/dev/null)" || return 1
  se="$(mktemp -t alien-term.XXXXXX 2>/dev/null)" || { rm -f "$sc"; return 1 }
  print -r -- "$1" > "$sc" || { rm -f "$sc" "$se"; return 1 }
  shift
  local -i rc=0
  OSA_OUT="$(${=OSA} "$sc" "$@" 2>"$se" </dev/null)" || rc=1
  # ONE LINE, FLATTENED.  osascript writes several, and a newline dropped
  # into the panel would draw over the rows beneath it.
  OSA_ERR="$(tr '\n\t' '  ' < "$se" 2>/dev/null)"
  while [[ "$OSA_ERR" == *'  '* ]]; do OSA_ERR="${OSA_ERR//  / }"; done
  OSA_ERR="${OSA_ERR## }"; OSA_ERR="${OSA_ERR%% }"
  rm -f "$sc" "$se"
  (( rc )) && return 1
  return 0
}
term_tty() { print -r -- "$(tty 2>/dev/null)" }
window_id() {
  # the id the launcher measured, when it measured one, and otherwise the id
  # Terminal gives for this very tty right now.  Either way it is TERMINAL's
  # own window -- and asking for it is a different failure from not being on
  # a Mac at all, which is why the two are separated.
  WINID=''
  [[ "${ALIEN_WINID:-}" == <-> ]] && { WINID="$ALIEN_WINID"; return 0 }
  have_osa || return 1
  osa_run "$AS_WINDOW_ID" "$(term_tty)" || return 1
  [[ "$OSA_OUT" == <-> ]] || return 1
  WINID="$OSA_OUT"
  return 0
}
live_names() {
  LIVE=''
  have_osa || return 1
  osa_run "$AS_LIVE_NAMES" "$1" || return 1
  # A COMMAND SUBSTITUTION EATS THE TRAILING NEWLINE, and the membership test
  # below looks for `\nNAME\n` -- so the last name in the list never matched
  # and a machine already standing was dealt a second tab.
  LIVE="$OSA_OUT"$'\n'
  return 0
}
front_tab() { have_osa || return 1; osa_run "$AS_FRONT" "$(term_tty)"; return 0 }
# ONE SHELL-QUOTED WORD, AND ZSH'S OWN IS THE ONE THAT IS RIGHT.
#
# This used to be the POSIX `'` -> `'\''` idiom written by hand, and it was
# WRONG: inside double quotes zsh does not strip the backslash before a
# quote, so the replacement came out as `\'\\'\'` and the closing quote it
# appended never closed what it had opened.  `_sh "what's this"` produced
# `'what\'\\'\'s this'`, which is a parse error -- and every character after
# an apostrophe in the payload was parsed AS SHELL CODE, outside quotes.
#
# That reached further than the tab titles this was written for: a machine
# that builds a command line from a filename, a model's name out of an HTTP
# response, or a question somebody typed on the glass was one apostrophe away
# from running the rest of it.  `${(qq)…}` is the shell's own single-quoting
# and is correct for every byte, the empty string included.
_sh() { print -r -- "${(qq)1}" }

deal_tabs() {   # deal_tabs LABEL INDEX...
  local label="$1"; shift
  local -a want; want=("$@")
  (( ${#want[@]} )) || { say "no machines in this folder"; snd no; return 1 }
  # ON A MAC, IN TERMINAL, WITH OSASCRIPT -- the three the tabs truly need.
  # The window id is NOT one of them: it is a handle TERMINAL can fetch, and
  # separating the two lets each failure say the true thing.  A window this is
  # not is `tabs need Terminal on a mac`; a window it IS but cannot get a
  # handle on is an automation permission that is off, and saying the first
  # when it is the second sends the reader to fix the wrong thing.
  if ! have_osa; then
    say "tabs need Terminal.app on a mac"; snd no; return 1
  fi
  if ! window_id; then
    say "let Terminal control Terminal · System Settings › Privacy › Automation"
    snd no; return 1
  fi
  local token=''
  suite_up && token="$SUITE_TOKEN"
  local -a open_now
  local -i i
  if [[ -n "$token" ]] && live_names "$WINID"; then
    for i in "${want[@]}"; do
      [[ $'\n'"$LIVE" == *$'\n'"${M_TAB[$i]}"$'\n'* ]] || open_now+=($i)
    done
  else
    open_now=("${want[@]}")
  fi
  if [[ -n "$token" ]] && (( ! ${#open_now[@]} )); then
    front_tab; say "$label · already open"; snd move; return 1
  fi
  local -i fresh=0
  if [[ -z "$token" ]]; then
    fresh=1
    # UNIQUE PER OPENING, not per second.  A redeal right after a house was
    # closed by hand can land in the same second as the deal before it, and
    # `pid-seconds` alone would hand the new house the old one's token.
    token="$$-$(term_now)-${RANDOM}${RANDOM}"
    suite_open "$token" || { say "could not open the house"; snd no; return 1 }
    SUITE_TOKEN="$token"
  fi
  local tty="$(term_tty)" full cmd w
  # `osargs` AND NOT `argv`.  zsh's `argv` IS the positional parameters -- $1,
  # $@, $# are views onto it -- so `local -a argv` rebinds them for the rest
  # of the function and `argv+=(...)` appends to them.  It happens to work
  # here only because the positionals were consumed into `label` and `want`
  # five lines up; move one read below this line and it breaks in a way that
  # reads as anything but a naming mistake.
  # `$tty` IS ARGUMENT TWO and it is the whole safety of this call: the
  # script refuses to type into a tab wearing this tty.
  local -a osargs; osargs=("$WINID" "$tty")
  for i in "${open_now[@]}"; do
    # NAMED, NOT EXECUTED.  The machine is run through the interpreter its own
    # shebang gives rather than by executing the path, so a machine whose
    # execute bit a copy, a zip or a careless umask lost still opens.
    full="$REPO/${M_PATH[$i]}"
    _shebang "$full" || SB=(zsh)
    cmd=''
    for w in "${SB[@]}" "$full"; do cmd+="${cmd:+ }$(_sh "$w")"; done
    osargs+=("ALIEN_DOOR_TTY=$(_sh "$tty") ALIEN_SUITE=$(_sh "$token") exec $cmd")
    osargs+=("${M_TAB[$i]}")
  done
  # RAISE THE DEALING FLAG BEFORE THE TABS EXIST, so the very first one's rc
  # already sees it.
  suite_dealing 12
  local -i made=0
  # `count|kind`, because the script now says WHERE it put them
  if osa_run "$AS_OPEN_SUITE" "${osargs[@]}" && [[ "${OSA_OUT%%|*}" == <-> ]]; then
    made=${OSA_OUT%%|*}
    OSA_KIND="${OSA_OUT#*|}"
  fi
  # THE SCRIPT REPORTS HOW MANY TABS IT MADE, and the token is kept only if
  # the house has some tab of its own.  osascript can exit 0 having created
  # nothing, and a token committed over zero tabs is exactly the stale-up this
  # path exists to avoid.  Only a FRESH house is torn down when it makes
  # nothing; adding to one already up leaves that house be.
  if (( ! made )); then
    (( fresh )) && suite_close
    say "no tabs opened"; snd no; return 1
  fi
  say "$label · $made tab$( (( made == 1 )) || print -n s )"
  snd start
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 20 · THE ACTIONS        what a row DOES
# ══════════════════════════════════════════════════════════════════════════
# Five of them, and the menu names which one each row carries.  The dispatch
# is a case on that name rather than on the row number, so adding a row is
# adding a row and not renumbering three key bindings.
act_row() {   # act_row I
  local -i i=$1
  if ! row_here $i; then
    row_needs $i
    [[ -n "$RNEED" ]] && say "${U_NAME[$i]} · no $RNEED in this folder" \
                      || say "${U_NAME[$i]} cannot run here"
    snd no; return 1
  fi
  case "${U_ACT[$i]}" in
    terminal)  do_terminal ;;
    install)   do_install ;;
    uninstall) do_uninstall ;;
    rescan)    do_rescan ;;
    config)    do_config ;;
    # ⏎ ON A MACHINE WALKS THROUGH THE DOOR.  Its index is its row minus the
    # suite's count, which is the whole reason S_N is written down.
    machine)   mach_open $(( i - S_N )) ;;
    *)         return 1 ;;
  esac
}

# act_key K — the row whose letter is K, or nothing.  The letters ARE the
# menu, so a key that names no standing row is a key this shape does not have:
# [T] before anything is installed is not a silent no-op, it is a row that is
# not there, and the surface says so rather than swallowing it.
#
# IT ANSWERS "WAS THERE A ROW", NOT "DID THE ROW SUCCEED".  Handing back the
# action's own status made a refused deal -- no automation, not Terminal, a
# deal that opened nothing -- indistinguishable from a key the menu does not
# have, and the caller's fallback then wrote `no T on this menu` straight over
# the sentence the action had just put on the coin door.
act_key() {
  local k="${1:u}"
  local -i i
  for (( i = 0; i < S_N; i++ )); do
    if [[ "${U_KEY[$i]}" == "$k" ]]; then
      UI_ROW=$i
      act_row $i || true
      return 0
    fi
  done
  # THE MACHINES ARE NOT ANSWERED HERE ANY MORE, and that is the change.  They
  # used to take a letter apiece -- [S] for SYSTEM, then [I], [X], [A] -- which
  # made the letter the ONLY way in: it was printed on the control panel and
  # nowhere the eye goes when it is looking for something to press.  They are
  # rows now, the cursor reaches them, and ⏎ opens them.  A letter that opens
  # what the cursor can already reach is a second way to do one thing and a
  # second thing to keep true.
  return 1
}

# ══════════════════════════════════════════════════════════════════════════
# WALKING INTO A MACHINE · and back out of it
# ══════════════════════════════════════════════════════════════════════════
# THE PACK IS SOURCED ONCE AND STANDS FOR THE CABINET.  Sourcing is not free
# -- it is a file read and a couple of hundred functions defined -- and it is
# also not repeatable: its top level zeroes every table it owns.  So the door
# remembers every pack it has sourced (PACK_SEEN) and the hooks each one
# declared, and walking back into a machine -- the same one, or one visited
# before another -- is nine assignments and a repaint.
# A PACK THAT FAILED AND WAS SURVIVED still has to say what went wrong.  The
# crumb is for the crash that takes the program with it; this is the other
# case -- the door caught it, and the reader gets four words on the coin door
# while the actual message sat in a temp file nobody would ever read and
# nothing would ever delete.  So the last line of it goes on the door, and
# both files go with it.
pack_failed() {   # pack_failed I WHY
  local -i i=$1
  local last=''
  [[ -s "$PACK_LOG" ]] && last="$(tail -n 1 "$PACK_LOG" 2>/dev/null)"
  last="${last//[^[:print:]]/ }"
  rm -f "$PACK_CRUMB" "$PACK_LOG" 2>/dev/null
  PACK_CRUMB=''; PACK_AT=''
  if [[ -n "$last" ]]; then say "${M_NAME[$i]} · ${last[0,57]}"
  else                      say "${M_NAME[$i]} · $2"; fi
  snd no
  return 0
}

mach_open() {   # mach_open I
  local -i i=$1
  # a machine fills only the pages it raises PACK_FILL for · default off, so a
  # machine with no fill layout of its own centres on the glass rather than
  # inheriting the last one's answer and stretching into the corner
  PACK_FILL=0
  SURF_PAINTED=0                      # opening · hold the glass until the pack's first paint
  local pk="${M_PACK[$i]:-}"
  local full="$REPO/$pk"
  if [[ -z "$pk" || ! -r "$full" ]]; then
    # NO PACK IS NOT A FAULT.  Three of the four machines have not been cut
    # into one yet and open in a tab of their own, the way they always have.
    if (( ${P_TAB[${M_PATH[$i]}]:-0} )); then
      deal_tabs "${M_NAME[$i]}" $i
    else
      say "${M_NAME[$i]} · not in this folder"; snd no
    fi
    return 0
  fi
  if [[ "$PACK_AT" != "$full" && -n "${PACK_SEEN[$full]:-}" ]]; then
    # SEEN BEFORE: not sourced again, not started again -- its hooks are put
    # back, all eleven of them, so a machine that declares fewer than the last
    # one does not inherit the difference.  Its state is exactly where the
    # reader left it, which is the point.
    local -a hk; hk=("${(@ps.\x1e.)PACK_SEEN[$full]}")
    PACK_NAME="${hk[0]}";  PACK_MODEL="${hk[1]}"; PACK_INIT="${hk[2]}"
    PACK_TICK="${hk[3]}";  PACK_DRAW="${hk[4]}";  PACK_KEY="${hk[5]}"
    PACK_RAW="${hk[6]}";   PACK_DRESS="${hk[7]}"; PACK_LEAVE="${hk[8]}"
    PACK_WARM="${hk[9]:-}"; PACK_FIRST="${hk[10]:-}"
    PACK_AT="$full"
    # ...AND ONE THE LOADING SCREEN GOT READY IS BEING OPENED FOR THE FIRST
    # TIME, NOW.  Whatever was left of its warming up is this open's to do in
    # the ordinary way, and what opening means to the reader -- the part the
    # stars were not allowed to do for it -- happens here, guarded exactly as
    # INIT is below.  A first visit that fails is a first visit again next
    # time: the pack is read afresh, the way one that would not start is.
    if [[ -n "${PACK_WARMED[$full]:-}" ]]; then
      unset "PACK_WARMED[$full]"
      warm_forget $i
      if [[ -n "$PACK_FIRST" ]]; then
        PACK_CRUMB="${TMPDIR:-/tmp}/alien-pack.$$"
        PACK_LOG="$PACK_CRUMB.log"
        print -r -- "${M_NAME[$i]} · $pk" > "$PACK_CRUMB" 2>/dev/null
        : > "$PACK_LOG" 2>/dev/null
        if ! { ${PACK_FIRST} } 2>>"$PACK_LOG"; then
          unset "PACK_SEEN[$full]"
          pack_failed "$i" 'that pack would not start'
          return 1
        fi
        rm -f "$PACK_CRUMB" "$PACK_LOG" 2>/dev/null; PACK_CRUMB=''
      fi
    fi
  elif [[ "$PACK_AT" != "$full" ]]; then
    # A FIRST VISIT STARTS FROM NO HOOKS.  The pack declares the ones it has;
    # one it does not declare must not be the previous machine's.
    PACK_NAME=''; PACK_MODEL=''; PACK_INIT=''; PACK_TICK=''; PACK_DRAW=''
    PACK_KEY=''; PACK_RAW=''; PACK_DRESS=''; PACK_LEAVE=''
    PACK_WARM=''; PACK_FIRST=''
    # ...and the loading screen, if it had not reached this one yet, does not
    # start reading it in behind the reader's back
    warm_forget $i
    # A PACK THAT WILL NOT LOAD MUST NOT TAKE THE DOOR DOWN WITHOUT SAYING SO.
    #
    # `if ! source` LOOKS LIKE IT CATCHES THIS AND DOES NOT.  A pack runs in
    # THIS process, under this process's `set -u`, and an unset parameter
    # there is not a failure a caller can test -- it is the shell exiting.
    # From the reader's side that is the window vanishing the instant they
    # pressed a letter, with nothing said and nothing left to read: the worst
    # failure this program is capable of, and the one it is most likely to
    # have, because a pack is a file somebody else wrote.
    #
    # So a breadcrumb is dropped first and the pack's own stderr is kept.  If
    # the door is still standing afterwards the breadcrumb is cleared and
    # nobody ever knows; if it is not, the EXIT trap finds the breadcrumb
    # after the alternate screen is down and prints what the pack said, on
    # the terminal the reader is left looking at.
    PACK_CRUMB="${TMPDIR:-/tmp}/alien-pack.$$"
    PACK_LOG="$PACK_CRUMB.log"
    print -r -- "${M_NAME[$i]} · $pk" > "$PACK_CRUMB" 2>/dev/null
    : > "$PACK_LOG" 2>/dev/null
    if ! { PACK_SOURCED=1 source "$full" } 2>>"$PACK_LOG"; then
      pack_failed "$i" 'that pack would not load'
      return 1
    fi
    if [[ -n "$PACK_INIT" ]]; then
      if ! { ${PACK_INIT} } 2>>"$PACK_LOG"; then
        pack_failed "$i" 'that pack would not start'
        return 1
      fi
    fi
    # OPENED COLD, IT IS STILL BEING OPENED: what a machine that was got ready
    # ahead of time does when its door is opened, this one does now.
    if [[ -n "$PACK_FIRST" ]]; then
      if ! { ${PACK_FIRST} } 2>>"$PACK_LOG"; then
        pack_failed "$i" 'that pack would not start'
        return 1
      fi
    fi
    rm -f "$PACK_CRUMB" "$PACK_LOG" 2>/dev/null; PACK_CRUMB=''
    PACK_AT="$full"
    local -a hk
    hk=("$PACK_NAME" "$PACK_MODEL" "$PACK_INIT" "$PACK_TICK" "$PACK_DRAW" \
        "$PACK_KEY" "$PACK_RAW" "$PACK_DRESS" "$PACK_LEAVE" "$PACK_WARM" "$PACK_FIRST")
    PACK_SEEN[$full]="${(pj.\x1e.)hk[@]}"
  fi
  UI_SURF="${M_KEY[$i]}"
  # EVERY MACHINE IS WALKED INTO THROUGH ITS TITLE CARD (tc_*), every time:
  # the card goes up here, and the machine takes it down on the first key
  SURF_TITLE=1; TC_T0=-1.0
  surf_dress
  # the plate and the sign are painted into the STATIC layer, so the bezel is
  # redressed with the new name · and the glass changes channel to get there
  redress
  xf_arm
  BEAT_SKIP=1
  snd open
  return 0
}

mach_close() {
  [[ -n "$UI_SURF" ]] || return 1
  UI_SURF=''
  SURF_TITLE=0
  # THE PACK STAYS SOURCED -- that is what PACK_AT is for -- but the HOOKS are
  # rebound by whichever machine is opened next, and a machine that sets fewer
  # of them than the last one would otherwise inherit the difference and have
  # the previous machine's tick called on its behalf.''
  surf_dress
  redress
  xf_arm
  snd away
  return 0
}

do_terminal() {
  # A SHELL IN THE GLASS (SECTION 18c).  This row used to deal every machine
  # a tab; the machines are rows of their own now, and a row called TERMINAL
  # opens a terminal.
  hsh_open
  return $?
}

do_config() {
  # THE CABINET'S OWN SETTINGS (SECTION 18d) · a POPUP now, folded up over the
  # menu the way INTELLIGENCE opens its model picker -- no page switch, no pack.
  cfg_modal_open
  return $?
}

do_install() {
  # INSTALLING IS STILL NOT THIS PROGRAM'S WORK -- but the ASKING is, and so
  # is the ink.  This opens the installer as a page on the glass; the linking,
  # the ~/.zshrc block and the switch are all still scripts/bootstrap.zsh's,
  # run with --report to read and --install to do.
  [[ -f "$REPO/scripts/bootstrap.zsh" ]] || { say "scripts/bootstrap.zsh is not here"; snd no; return 1 }
  inst_open install
  return 0
}

do_uninstall() {
  # THE SAME INSTALLER, ASKED THE OTHER QUESTION.  --remove puts ~/.zshrc back
  # the way it found it and unlinks the two leaves; the copy it kept at
  # ~/.zshrc.pre-alien is left alone, because that one is the reader's.
  [[ -f "$REPO/scripts/bootstrap.zsh" ]] || { say "scripts/bootstrap.zsh is not here"; snd no; return 1 }
  inst_open uninstall
  return 0
}

do_rescan() {
  BEAT_SKIP=1
  # A RESCAN IS A PROBE, AND THE SELF TEST IS WHAT A PROBE LOOKS LIKE.  This
  # row used to read the machine again in silence and put four words on the
  # coin door -- which is the same work the power-on card does over six
  # seconds with every figure of it on the glass, and there was no reason at
  # all for the two to be different surfaces.  Pressing [R] runs the card.
  #
  # AND IT RE-READS THE MACHINE ITSELF, not just the folder.  A rescan after
  # plugging in a second display, or moving the window to it, or filling the
  # disk, should say so: the specs, the panel and the frame ladder are all
  # asked again, which is what makes this a scan rather than a redraw.
  snd pick
  # THE SAVE AND THE CONFIG ARE ASKED AGAIN TOO, so a file copied in while the
  # cabinet was up is on the card that follows -- the save read (the same read
  # the arcade does after every write), the conf only counted: its settings
  # are applied at power-on, and a rescan is not a restart.
  save_load
  cfg_count
  probe_scan
  specs_read
  [[ -n "${ALIEN_FPS:-}" ]] || _hz_coregraphics || true
  beat_reset
  page_boot 1
  # AND AGAIN AFTER IT, for the reason the opening has its own: the card is a
  # full-glass repaint every frame and the menu is a cached rectangle with
  # four moving things on it, so the rung the card settled on is a rung the
  # menu would be held below, one careful step at a time, for a minute.
  beat_reset
  TANIM=-1.0; LAST_FSTART=0.0; STRIDE=0.0
  reading mirror; say "read again · $RD"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 21 · THE SEAMS          --probe, --check, --caption
# ══════════════════════════════════════════════════════════════════════════
probe_text() {
  # DECLARED ONCE, at the top.  `local x` on an x that already has a value
  # LISTS it -- zsh's typeset with no assignment is a query -- so declaring
  # inside the loop printed `nm=system` after every row.
  local i nm
  printf '  %-14s %s\n' repo "$REPO"
  printf '  %-14s %s · %s\n' machine "$P_HOST" "$P_OS"
  printf '  %-14s %s\n' cpu "${SPEC_CPU:-—}"
  printf '  %-14s %s\n' memory "${SPEC_RAM:-—}"
  printf '  %-14s %s\n' disk "${SPEC_DISK:-—}"
  printf '  %-14s %s\n' panel "${SPEC_PANEL:-—}"
  printf '  %-14s %d of %d linked\n' mirror $P_LINKED $P_LEAVES
  reading depth
  printf '  %-14s %s\n' depth "$RD"
  # THE MACHINES ARE NOT ROWS ANY MORE, but --probe is the text answer to
  # "what did you find", and what it found is still five files and what each
  # one wants.
  for (( i = 0; i < M_N; i++ )); do
    nm="${M_NAME[$i]:l}"
    printf '  %-14s %-9s %s\n' "$nm" \
      "$( (( ${P_HERE[${M_PATH[$i]}]:-0} )) \
            && { [[ -n "${M_PACK[$i]:-}" ]] && print -n 'here, glass' || print -n 'here, tab' } \
            || print -n -- '-' )" \
      "${P_NEEDS[${M_PATH[$i]}]:+needs ${P_NEEDS[${M_PATH[$i]}]}}${P_NEEDS[${M_PATH[$i]}]:-$( reading "${M_KIND[$i]}"; print -rn -- "$RD" )}"
  done
  printf '  %-14s %s\n' installed "$( installed_p && print -n yes || print -n "no · $INSTALLED_WHY" )"
  # S_N AND NOT R_N.  The machines are menu rows now, and the loop above has
  # already printed each of them by its file -- so a self test that walked the
  # whole row list named every machine twice, once as a file and once as a row.
  for (( i = 0; i < S_N; i++ )); do
    printf '  %-14s %-9s %s\n' "menu ${U_NAME[$i]:l}" \
      "$( row_here $i && print -n ready || print -n -- '-' )" \
      "${U_WHY[$i]:-$( reading "${U_KIND[$i]}"; print -rn -- "$RD" )}"
  done
  printf '  %-14s %.3f hz · %s\n' beat $HZ "${(j:, :)${LADDER[@]}}"
  printf '  %-14s %s\n' sky "$CAPTION"
  printf '  %-14s %s\n' visitor "${#VIS_POSE_K[@]} poses · ${#SKY_KEY[@]} skies · carried"
  printf '  %-14s %s\n' characters \
    "$( (( MB_OK )) && print -n 'counted, not bytes' || print -n 'BYTES · set a UTF-8 locale' )"
  return 0
}

check_card() {
  # WHAT THIS FONT CAN ACTUALLY DRAW.  Every glyph the machine puts on the
  # glass, in the rows it uses them in, with a ruler under each so a font that
  # gives one of them two cells is visible as a ruler that no longer lines up.
  # It is the one question about a terminal that nobody can answer from
  # anywhere but that terminal.
  local -a rows names
  names=('box    ' 'blocks ' 'marks  ' 'sky    ' 'panel  ' 'arrows ')
  rows=('╭─╮╰╯│╞═╡╔╗╚╝║┌┐└┘━┃' \
        '█▓▒░▀▐▌▬●◉◆◤◥' \
        '· • ✦ ✧ ▪ ◂ ▸ ◄ ► ▴ ▾ ▶ ▌ ○ ◐ ▮' \
        '☀ ☾ ★ ☆' \
        '[Q] ⏎ · — ×' \
        '↑ ↓ ← →')
  local -i i j
  print -r -- "  the glyphs TERMINAL draws, and a ruler under each"
  print -r -- ""
  for (( i = 0; i < ${#rows[@]}; i++ )); do
    print -r -- "  ${names[$i]} ${rows[$i]}"
    local rule=''
    for (( j = 0; j < ${#rows[$i]}; j++ )); do rule+='-'; done
    print -r -- "  ${names[$i]} $rule"
  done
  print -r -- ""
  print -r -- "  A RULER SHORTER than the row above it is a glyph this font"
  print -r -- "  draws double-wide, and the cabinet will lean by that much."
  print -r -- ""
  print -r -- "  A RULER LONGER than the row above it is this shell counting"
  print -r -- "  BYTES rather than characters, which is the locale below and"
  print -r -- "  not the font: every rule on the machine will overshoot."
  print -r -- ""
  reading depth
  printf '  %-14s %s\n' depth "$RD"
  printf '  %-14s %s\n' term "${TERM_PROGRAM:-${TERM:-unknown}}"
  printf '  %-14s %s\n' locale "${LC_ALL:-${LC_CTYPE:-${LANG:-unset}}}"
  printf '  %-14s %s\n' characters \
    "$( (( MB_OK )) && print -n 'counted, not bytes' || print -n 'BYTES · set a UTF-8 locale' )"
  printf '  %-14s %.3f hz · %s\n' beat $HZ "${(j:, :)${LADDER[@]}}"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 22 · POWERING UP
# ══════════════════════════════════════════════════════════════════════════
save_load
cfg_load                             # SECTION 18d · the reader's own settings,
                                     # before snd_init can play, before the beat
                                     # and the tube are built from them
_lift_init
BTN=($RED $AMBER $LIME $CYAN $PURPLE $MAGENTA)   # the arcade's own six
snd_init

# ── THE LOADING, BROKEN INTO STEPS ────────────────────────────────────────
# WHAT USED TO HAPPEN HERE was all of it, in a row, against a terminal that
# had not been given anything to look at yet -- python forked at CoreGraphics
# for the panel rate, four `sysctl`s and a `df` for the specs, a walk of the
# folder for the machines, and a full paint of the cabinet's chrome into the
# static layer.  On this machine that is a second; on a cold Mac, opening a
# window and a shell at the same time, it is rather more.  A second of
# NOTHING is the longest second a program gets, because the reader cannot
# tell a machine that is thinking from one that has failed to start.
#
# So the work is a QUEUE now, and the stars are the first thing on the glass.
# page_sky draws a frame, takes one step off this queue, draws another --
# and by the time the sky's few seconds are up the machine has read itself,
# found its slots, built its chrome and is ready for the tube to open.  The
# opening was always going to cost three seconds of ceremony; this spends the
# loading INSIDE them rather than in front of them.
#
# The order is exactly the order it ran in before.  Steps do not depend on
# each other, but a queue is a bad place to find out you were wrong about
# that, so nothing has been reordered to make the pumping neater.
LOAD_AT=0
load_step() {   # one unit of the machine's own loading · false when done
  case $LOAD_AT in
    # THE RATE, first, because everything paced is paced by it: the instant
    # answer if the window server will give one, the slow one started and
    # read later if it will not.
    0) [[ -n "${ALIEN_FPS:-}" ]] || _hz_coregraphics || _hz_probe_start ;;
    1) beat_reset ;;
    2) specs_read ;;
    3) probe_scan ;;
    4) tick_slow ;;
    # LAST, AND ONLY ONCE THE WINDOW HAS BEEN MEASURED.  static_paint writes
    # into a grid c_size allocates, so this step must not be reached before
    # the measurement below has run -- which is why the three seams under it
    # stop the queue one short of here.
    5) rebuild ;;
    *) return 1 ;;
  esac
  (( LOAD_AT++ ))
  return 0
}
load_upto() {   # load_upto N — run the queue until N steps have been taken
  local -i n=$1
  while (( LOAD_AT < n )); do load_step || break; done
  return 0
}
load_rest() { while load_step; do :; done; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 22b · GETTING THE MACHINES READY       behind the stars, not the reader
# ══════════════════════════════════════════════════════════════════════════
# OPENING A MACHINE WAS WHERE ITS LOADING HAPPENED: its pack read in, its
# tables started, its first readings taken and -- on INTELLIGENCE -- a
# stranger's program asked its version one row at a time, every one of them a
# frozen frame.  The reader paid for all of it at the exact moment they had
# asked to be shown something.
#
# THE STARS ARE A BETTER PLACE TO PAY IT.  The overture holds the window for
# a few seconds whatever happens, and the cabinet's own loading (above) uses a
# fraction of them; so every machine is read in and started behind the same
# sky, a piece between frames, in the order they are worth having ready --
# INTELLIGENCE first, because its versions are asked in the background and
# want the head start.  What a piece is, is the pack's to say (PACK_WARM).
# What opening a machine MEANS -- a visit counted, the save read as it stands
# then, a clock caught up -- is not done early at all (PACK_FIRST).
#
# A KEY THAT SKIPS THE OPENING DOES NOT SKIP THIS.  Whatever the sky did not
# reach is taken on the menu, a piece at a time on beats nobody wanted, and a
# machine opened before its turn is simply opened the way it always was.
typeset -ga WARM_Q            # "M" reads machine M in · "M:N" is step N of its warm-up
typeset -gA PACK_WARMED       # pack path → 1 · got ready, and not opened yet
typeset -gA WARM_STAMP        # pack path → its file's mtime, for the note below
typeset -gF WARM_KEY_AT=0.0   # the last key the menu took · the pieces keep out of its way
typeset -gi WARM_SIG=0        # the cabinet is going down on a signal, not a fault
WARM_HOLD=4.0                 # the most the sky is held past its own seconds for them
WARM_NOTE=''                  # see warm_init

warm_init() {   # the queue · and a machine that took the cabinet down while warming left out of it
  local d="${XDG_STATE_HOME:-$HOME/.local/state}/alien" note full line
  local -a f st keep still
  local -A skip
  local -i i
  WARM_Q=(); WARM_STAMP=()
  zmodload -F zsh/stat +b:zstat 2>/dev/null
  # THE NOTE IS WRITTEN BEFORE EVERY PIECE AND TAKEN AWAY WHEN THE LAST ONE IS
  # DONE, so a note still here at power-on names the machine that was being
  # got ready when the cabinet last went down from inside it.  That machine
  # goes on a list (warm-skip) and is left to open the old way, at its door,
  # until its file changes -- otherwise a pack that cannot start would take
  # the cabinet down at EVERY power-on, where it used to take it down only
  # for somebody who opened it.
  [[ -d "$d" && -w "$d" ]] || d=''
  if [[ -n "$d" ]]; then
    WARM_NOTE="$d/warming"
    if [[ -r "$WARM_NOTE" ]]; then
      note="$(<"$WARM_NOTE")"
      f=("${(@ps:\t:)note}")
      # ...unless the cabinet that wrote it is still running: two windows
      # powering on together share the note, and the other one is no fault.
      # (Running is a live process that is a cabinet -- not a pid that has
      # been handed to something else since, and not one that is only waiting
      # to be reaped.)
      line=''
      [[ "${f[0]:-}" == <-> ]] && (( f[0] != $$ )) && kill -0 ${f[0]} 2>/dev/null \
        && line="$(ps -o stat= -o command= -p ${f[0]} 2>/dev/null)"
      line="${line## }"
      if [[ -n "$line" && "$line" != Z* && "$line" == *terminal.command* ]]; then :
      else
        [[ -n "${f[1]:-}" ]] && keep+=("${f[1]}"$'\t'"${f[2]:-}")
        rm -f -- "$WARM_NOTE" 2>/dev/null
      fi
    fi
    if [[ -r "$d/warm-skip" ]]; then
      for line in "${(@f)$(<"$d/warm-skip")}"; do [[ -n "$line" ]] && keep+=("$line"); done
    fi
    # STILL THE SAME FILE, STILL LEFT COLD · a file that has changed is tried again
    for line in "${keep[@]}"; do
      f=("${(@ps:\t:)line}")
      full="${f[0]:-}"; st=('')
      [[ -n "$full" && -r "$full" ]] || continue
      (( ${+builtins[zstat]} )) && zstat -A st +mtime -- "$full" 2>/dev/null
      [[ -n "${st[0]}" && "${st[0]}" == "${f[1]:-}" ]] || continue
      [[ -n "${skip[$full]:-}" ]] && continue
      skip[$full]=1; still+=("$line")
    done
    if (( ${#still[@]} )); then print -rl -- "${still[@]}" > "$d/warm-skip" 2>/dev/null
    elif [[ -e "$d/warm-skip" ]]; then rm -f -- "$d/warm-skip" 2>/dev/null; fi
  fi
  for i in 1 0 2 3; do
    [[ -n "${M_PACK[$i]:-}" ]] || continue
    full="$REPO/${M_PACK[$i]}"
    [[ -r "$full" && -z "${skip[$full]:-}" ]] || continue
    st=('')
    (( ${+builtins[zstat]} )) && zstat -A st +mtime -- "$full" 2>/dev/null
    WARM_STAMP[$full]="${st[0]:-}"
    WARM_Q+=("$i")
  done
  return 0
}

warm_forget() {   # warm_forget M — machine M is being opened · nothing more is got ready for it
  WARM_Q=("${(@)WARM_Q[@]:#$1}")
  WARM_Q=("${(@)WARM_Q[@]:#$1:*}")
  (( ${#WARM_Q[@]} )) || warm_done
  return 0
}

warm_done() {   # the last piece is in · the note goes, and the crumb the pieces left
  (( WARM_MARKED )) || return 0
  rm -f -- ${WARM_NOTE:+"$WARM_NOTE"} "${TMPDIR:-/tmp}/alien-pack.$$" "${TMPDIR:-/tmp}/alien-pack.$$.log" 2>/dev/null
  WARM_MARKED=0
  return 0
}
typeset -gi WARM_MARKED=0     # a piece has left its crumb and its note behind

# A PIECE IS GUARDED THE WAY mach_open GUARDS A PACK: the crumb dropped first
# and its stderr kept, so a pack that takes the cabinet down while it is being
# got ready says so on the terminal the reader is handed back -- and the note
# says so to the next power-on.  stdout goes nowhere: a piece is drawn into
# nothing, and a stray line from it would scroll the sky.
warm_mark() {   # warm_mark PATH WHO — about to run a piece of that pack
  PACK_CRUMB="${TMPDIR:-/tmp}/alien-pack.$$"
  PACK_LOG="$PACK_CRUMB.log"
  print -r -- "$2 · getting it ready behind the opening" > "$PACK_CRUMB" 2>/dev/null
  : > "$PACK_LOG" 2>/dev/null
  [[ -n "$WARM_NOTE" ]] && print -r -- "$$"$'\t'"$1"$'\t'"${WARM_STAMP[$1]:-}" > "$WARM_NOTE" 2>/dev/null
  WARM_MARKED=1
  return 0
}
warm_unmark() {   # ...and it came back · the note says only that a cabinet is warming
  PACK_CRUMB=''
  [[ -n "$WARM_NOTE" ]] && print -r -- "$$" > "$WARM_NOTE" 2>/dev/null
  return 0
}

warm_load() {   # warm_load M — machine M's pack read in and started, ahead of the reader
  local -i _wl_m=$1 _wl_ok=0 _wl_fill=$PACK_FILL
  local _wl_full="$REPO/${M_PACK[$1]:-}"
  [[ -n "${M_PACK[$1]:-}" && -r "$_wl_full" ]] || return 1
  [[ -n "${PACK_SEEN[$_wl_full]:-}" ]] && return 1        # it is standing already
  # A READ, NOT AN OPEN: whatever hooks are bound -- the last machine's, or
  # none -- are bound again afterwards, and PACK_AT does not move
  local -a _wl_hk _wl_new
  _wl_hk=("$PACK_NAME" "$PACK_MODEL" "$PACK_INIT" "$PACK_TICK" "$PACK_DRAW" \
          "$PACK_KEY" "$PACK_RAW" "$PACK_DRESS" "$PACK_LEAVE" "$PACK_WARM" "$PACK_FIRST")
  PACK_NAME=''; PACK_MODEL=''; PACK_INIT=''; PACK_TICK=''; PACK_DRAW=''
  PACK_KEY=''; PACK_RAW=''; PACK_DRESS=''; PACK_LEAVE=''; PACK_WARM=''; PACK_FIRST=''
  warm_mark "$_wl_full" "${M_NAME[$_wl_m]} · ${M_PACK[$_wl_m]}"
  WARMING=1
  if { PACK_SOURCED=1 source "$_wl_full" } >/dev/null 2>>"$PACK_LOG"; then
    if [[ -z "$PACK_INIT" ]] || { ${PACK_INIT} } >/dev/null 2>>"$PACK_LOG"; then _wl_ok=1; fi
  fi
  WARMING=0
  warm_unmark
  if (( _wl_ok )); then
    _wl_new=("$PACK_NAME" "$PACK_MODEL" "$PACK_INIT" "$PACK_TICK" "$PACK_DRAW" \
             "$PACK_KEY" "$PACK_RAW" "$PACK_DRESS" "$PACK_LEAVE" "$PACK_WARM" "$PACK_FIRST")
    PACK_SEEN[$_wl_full]="${(pj.\x1e.)_wl_new[@]}"
    PACK_WARMED[$_wl_full]=1
    [[ -n "$PACK_WARM" ]] && WARM_Q+=("$_wl_m:0")
  fi
  # A PACK THAT WOULD NOT LOAD OR START HERE IS LEFT FOR ITS DOOR, which reads
  # it afresh and says what went wrong at the moment somebody asked for it
  PACK_NAME="${_wl_hk[0]}"; PACK_MODEL="${_wl_hk[1]}"; PACK_INIT="${_wl_hk[2]}"
  PACK_TICK="${_wl_hk[3]}"; PACK_DRAW="${_wl_hk[4]}";  PACK_KEY="${_wl_hk[5]}"
  PACK_RAW="${_wl_hk[6]}";  PACK_DRESS="${_wl_hk[7]}"; PACK_LEAVE="${_wl_hk[8]}"
  PACK_WARM="${_wl_hk[9]}"; PACK_FIRST="${_wl_hk[10]}"
  PACK_FILL=$_wl_fill
  return $(( ! _wl_ok ))
}

warm_run() {   # warm_run M N — step N of machine M's own warm-up · its answer, 0 · 1 · 2
  local -i _wr_m=$1 _wr_n=$2 _wr_rc=1
  local _wr_full="$REPO/${M_PACK[$1]:-}"
  local -a _wr_hk; _wr_hk=("${(@ps.\x1e.)PACK_SEEN[$_wr_full]:-}")
  local _wr_fn="${_wr_hk[9]:-}"
  [[ -n "$_wr_fn" ]] || return 1
  warm_mark "$_wr_full" "${M_NAME[$_wr_m]}"
  WARMING=1
  { ${_wr_fn} $_wr_n $(( EPOCHREALTIME - T0 )) } >/dev/null 2>>"$PACK_LOG"
  _wr_rc=$?
  WARMING=0
  warm_unmark
  return $_wr_rc
}

warm_step() {   # one piece of getting the machines ready · 1 once nothing is left · 2 if it was waiting
  (( ${#WARM_Q[@]} )) || return 1
  local _ws_it="${WARM_Q[0]}"
  local -i _ws_m=${_ws_it%%:*} _ws_rc=0
  WARM_Q=("${(@)WARM_Q[@]:1}")
  if [[ "$_ws_it" != *:* ]]; then
    warm_load $_ws_m
  # ...A STEP OF A PACK'S OWN, and the next one goes to the BACK of the queue,
  # so the machines come up together rather than one after another -- and a
  # step that is waiting on something (INTELLIGENCE's versions) waits there
  # while the others go on
  elif [[ -n "${PACK_WARMED[$REPO/${M_PACK[$_ws_m]}]:-}" ]]; then
    warm_run $_ws_m ${_ws_it#*:}; _ws_rc=$?
    case $_ws_rc in
      0) WARM_Q+=("$_ws_m:$(( ${_ws_it#*:} + 1 ))") ;;
      2) WARM_Q+=("$_ws_it") ;;
      *) _ws_rc=0 ;;
    esac
  fi
  (( ${#WARM_Q[@]} )) || warm_done
  # ...and a piece that is waiting says so, so that whoever is pumping stops
  # for this frame rather than asking the same question round and round
  (( _ws_rc == 2 )) && return 2
  return 0
}

# THE MENU TAKES THE LEFTOVERS ONLY WHEN NOTHING ELSE WANTS THE BEAT: its own
# glass and nothing standing over it, no channel change running, and a
# moment since the last key -- a reader moving down the rows is not a reader
# waiting for a piece of somebody else's machine to load.
#
# ...AND THE MACHINE THE CURSOR IS RESTING ON GOES FIRST.  A reader who has
# stopped on a row is about to press ⏎ on it, so its pieces are moved to the
# front of the queue: the one they are looking at is the one that is ready.
warm_idle() {
  [[ -z "$UI_SURF" && -z "$UI_INST" ]] || return 0
  (( ! UI_GATE && ! CFG_OPEN && XF_T0 < 0.0 )) || return 0
  (( EPOCHREALTIME - WARM_KEY_AT > 0.4 )) || return 0
  local -i _wi_m=$(( UI_ROW - S_N ))
  if (( _wi_m >= 0 && _wi_m < M_N )); then
    local -a _wi_a _wi_b
    local _wi_it
    for _wi_it in "${WARM_Q[@]}"; do
      if [[ "${_wi_it%%:*}" == "$_wi_m" ]]; then _wi_a+=("$_wi_it"); else _wi_b+=("$_wi_it"); fi
    done
    WARM_Q=("${_wi_a[@]}" "${_wi_b[@]}")
  fi
  warm_step
  return 0
}

# THE THREE SEAMS WANT THE READINGS AND NOT THE CEREMONY, so they drain the
# queue in one go -- as far as the chrome, which they never draw.
if (( OPT_PROBE )); then load_upto 5; probe_text; exit 0; fi
if (( OPT_CHECK )); then load_upto 5; check_card; exit 0; fi

# --caption TS prints the corner line for that instant, so the sky's
# arithmetic can be diffed against TERMINAL it was ported from over hundreds
# of instants rather than eyeballed on one.  Porting arithmetic between
# languages is exactly where a sign or a modulo goes quietly missing.
if [[ "${1:-}" == --caption ]]; then
  load_upto 5
  shift
  for _t in "$@"; do
    sky_moon "$_t"
    sky_sun "$_t" || SUN_ALT=''
    caption "$_t"
    printf '%s %d %s %s %s\n' "$_t" $MOON_PH "$MOON_ZOD" \
      "$( [[ -n "$SUN_ALT" ]] && printf '%.6f' $SUN_ALT || print -n -- '-' )" \
      "$CAPTION"
  done
  exit 0
fi

surf_blank() { return 0 }   # what a machine without a picture draws
# rebuild — the window moved, so everything measured from it is measured again
rebuild() {
  # THE GLASS IS SIZED FIRST.  Fill mode reflows the whole map to the window;
  # float puts the fixed cabinet glass back.  Everything below (the still
  # layer, the tube's vignette, the dust) is measured from it, so it comes
  # before them, and it runs here rather than in c_size because c_size does
  # not know which screen the reader chose.
  #
  # ...AND ONLY A SURFACE WITH A FILL LAYOUT FILLS.  TERMINAL's own menu always
  # does; a machine on the glass fills only the pages it has raised PACK_FILL
  # for, and keeps the cabinet glass -- centred on the lit fill -- for the rest,
  # so a page not yet taught to reflow reads as itself rather than as a stretch.
  # CONFIG draws its panel from the terminal's own width and does not care.
  if (( CFG_FILL )) && { [[ -z "$UI_SURF" ]] || (( PACK_FILL )) }; then geom_fill; else geom_float; fi
  GLASS_KEY=''; GLCH=()
  r_forget                             # the glass moved under the renderer's memo
  static_paint
  vig_init
  motes_init
  return 0
}
sky_init
c_size
if (( ! FITS )); then
  if (( OPT_ONCE || OPT_FAST || ! ${+options[interactive]} )); then
    print -r -- "the terminal needs a window of at least ${MIN_W} x ${MIN_H}."
    print -r -- "this one is ${TCOLS} x ${TROWS}."
    exit 0
  fi
fi
# THE CHROME, FOR THE ONE CALLER THAT CANNOT WAIT FOR IT.  --once and --fast
# draw a card and leave, so there is no opening to build it during and the
# queue is drained here.  The visit does not drain it here: it opens the
# alternate screen first, puts the sky up, and takes the rest of the queue a
# step at a time between frames.
(( OPT_ONCE || OPT_FAST )) && load_rest

# ══════════════════════════════════════════════════════════════════════════
# THE CARD, WITHOUT THE CEREMONY
# ══════════════════════════════════════════════════════════════════════════
# --once and --fast draw the machine one time and leave: no alternate screen,
# no power up, no loop.  It is what the harness drives and what anyone
# wanting the card rather than the visit wants.
if (( OPT_ONCE || OPT_FAST )); then
  if (( ! FITS )); then
    print -r -- "the terminal needs a window of at least ${MIN_W} x ${MIN_H}."
    exit 0
  fi
  # THE INSTANT IS THE HARNESS'S IF IT NAMED ONE.  Everything on this card
  # moves -- the chase lights, the sweep on the marquee, the breathing lamps,
  # his eyes -- so "the card at t = 1" and "the card at t = 8" are two
  # different pictures.  ALIEN_AT is what lets a fixture and a live capture be
  # the same one.
  _T=1.0
  [[ -n "$FROZEN" ]] && _T=$FROZEN
  printf '\033[H\033[2J'
  frame_begin $_T
  frame_glass $_T
  frame_end_cached $_T
  printf '\033[0m\n'
  exit 0
fi

# ══════════════════════════════════════════════════════════════════════════
# SECTION 23 · THE VISIT
# ══════════════════════════════════════════════════════════════════════════
UI_GATE=0
T0=0
# ONCE, HOWEVER MANY WAYS OUT THERE ARE.  cleanup is on the EXIT trap and on
# both signals and is also called by hand before the two exits that mean it;
# leaving the alternate screen twice is harmless and looks like a bug in a
# transcript, which is reason enough.
LEFT=0
PACK_CRUMB=''; PACK_LOG=''
cleanup() {
  # THE WORDS ARE SPLIT THE ORDINARY WAY IN HERE, whatever was running when
  # the cabinet was told to go.  A window closed while the loop waits for a
  # key lands in the middle of `IFS= read`, and the trap runs with that
  # read's empty IFS still in force -- so every list split on the way out
  # came back as one word, and a pack stopping a process tree stopped only
  # its top and left the rest running with nobody holding them.
  local IFS=$' \t\n\0'
  (( LEFT )) && return 0; LEFT=1; scr_leave; tty_back; err_free
  # THE ONE THING WORSE THAN A CRASH IS A CRASH WITH NOTHING TO READ.  If the
  # breadcrumb is still here, this program is on its way out from inside
  # somebody's page pack -- so what the pack said on its way down goes to the
  # terminal the reader is about to be looking at, rather than nowhere.
  # THE MACHINE'S OWN CHILDREN GO DOWN WITH THE CABINET.  This runs on the
  # way out of every door there is -- the power gate, ^C, ^\, a closed window
  # -- and it is the last moment anything can reach them.  Guarded and
  # swallowed: a pack that fails here must not stop the terminal being handed
  # back in a usable state, which is the whole job of this function.
  if [[ -n "$PACK_LEAVE" ]]; then
    { ${PACK_LEAVE} } >/dev/null 2>&1
  fi
  local _pe
  for _pe in "${(@)PACK_EXITS[@]}"; do
    [[ "$_pe" == "$PACK_LEAVE" ]] && continue
    { ${_pe} } >/dev/null 2>&1
  done
  # THE GLASS TERMINAL'S SESSIONS ARE THE CABINET'S, and so is their end: a
  # pty outlives the shell that opened it, and a program left holding one
  # after the cabinet is gone is a process with a terminal nobody will read.
  { gt_all_stop; vc_leave; gt_tmp_sweep } >/dev/null 2>&1
  # THE LOADING SCREEN'S NOTE (SECTION 22b) is left behind only by a machine
  # that took the cabinet down while it was being got ready -- not by a window
  # closed on it, and not by a cabinet that was not getting anything ready
  if (( WARM_MARKED )) && { [[ -z "$PACK_CRUMB" ]] || (( WARM_SIG )) }; then
    warm_done >/dev/null 2>&1
  fi
  [[ -n "$PACK_CRUMB" && -r "$PACK_CRUMB" ]] || return 0
  print -u2 -r -- ''
  print -u2 -r -- "TERMINAL stopped inside a machine's page pack:"
  print -u2 -r -- "  $(<"$PACK_CRUMB")"
  if [[ -s "$PACK_LOG" ]]; then
    print -u2 -r -- '  ---'
    sed 's/^/  /' "$PACK_LOG" >&2 2>/dev/null
  else
    print -u2 -r -- '  ...and said nothing on the way.'
  fi
  print -u2 -r -- ''
  rm -f "$PACK_CRUMB" "$PACK_LOG" 2>/dev/null
  return 0
}
# EVERY WAY OUT GOES THROUGH cleanup, and INT and TERM were only two of
# them.  zsh runs the EXIT trap for HUP but NOT for QUIT -- and `tty_raw`
# leaves `isig` on, so Ctrl-\ was a live key that killed the program with the
# alternate screen still up and the terminal still raw: the reader was handed
# back a shell that echoed nothing and submitted nothing, over a picture that
# would not go away.  Closing the window is HUP and had the same hole.
trap 'WARM_SIG=1; cleanup; exit 130' INT
trap 'WARM_SIG=1; cleanup; exit 131' QUIT
trap 'WARM_SIG=1; cleanup; exit 129' HUP
trap 'WARM_SIG=1; cleanup; exit 143' TERM
trap 'cleanup' EXIT
# ...AND Ctrl-Z IS REFUSED RATHER THAN HALF-HANDLED.  Suspending a full-screen
# program means putting the terminal back, and restoring it on a CONT that may
# arrive in a window of a different size; a cabinet that cannot promise the
# second half should not accept the first.  [Q] is the way out.
trap '' TSTP
# NO OVERTURE, NO PLACE TO PUT THE LOADING.  Coming back from a machine, or
# opening into a window too small for the cabinet, there are no stars to load
# behind -- so the queue is drained HERE, before the alternate screen, where
# half a second reads as the shell still working rather than as a machine
# that came up blank.
(( FITS && ! OPT_BACK && ! CFG_BOOT_FAST )) || load_rest
# THE MACHINES ARE GOT READY EITHER WAY (SECTION 22b): behind the stars when
# there is an overture, on the menu's spare beats when there is not.
warm_init
tty_raw
scr_enter
err_hold
T0=$EPOCHREALTIME

if (( FITS && ! OPT_BACK && ! CFG_BOOT_FAST )); then
  # the suite's opening, in the order every other surface keeps: the sky
  # alone, the machine switching itself on, and only then the self test.
  # page_sky is also where the rest of the loading happens -- it draws a
  # frame, takes a step off the queue, and draws another, so the stars are up
  # from the first hundredth of a second and the machine reads itself behind
  # them.  Whatever the sky did not get through -- because a key skipped it,
  # or because this machine is quick -- is finished here, before the tube
  # opens onto a cabinet that has to exist by then.
  page_sky
fi
load_rest
if (( FITS && ! OPT_BACK && ! CFG_BOOT_FAST )); then
  power_up
  page_boot
fi
# THE SAVE AND THE CONFIG ARE SAID EITHER WAY.  The card says it on a line of
# its own; a reader who skipped the card before that line -- or who set BOOT
# to FAST and never sees the card at all -- gets the same answer on the coin
# door for the first few seconds of the menu.  Not on the way back from a
# machine's tab, which is not a power-on.
if (( FITS && ! OPT_BACK && ! BOOT_SAW_FILES )); then
  boot_files
  say "$BOOT_FBRIEF"
fi
# THE MENU IS NOT THE OPENING and does not cost what it cost.  An opening
# frame paints the whole glass from nothing every time; a menu frame copies a
# rectangle that was finished once and lays four moving things on it, which
# is several times cheaper -- so the rung the governor settled on for the
# tube is a rung the menu is being held BELOW, and it would climb back one
# careful step every ninety comfortable frames.  Handing it a clean ladder
# and the top of it costs six frames of seeking and is done before anybody
# has read the first row.
(( FITS && ! OPT_BACK )) && beat_reset
r_invalidate

_key=''; _rc=0; _k2=''; _fast=0; _tread=0; _t=0.0
typeset -F _fstart _work GAP=0.02 HEAL_AT=0.0 TANIM=-1.0 _real HEAL_EVERY _dt STRIDE=0.0 LAST_FSTART=0.0
typeset -i HEAL_ROW=0 BEAT_SKIP=0 _wantfill=0 SURF_PAINTED=1
HEAL_EVERY=$(( 8.0 / (TROWS > 0 ? TROWS : 50) ))
NEXT_FRAME=0.0
FPS_T0=$EPOCHREALTIME
WARM_KEY_AT=$EPOCHREALTIME             # the menu's first moments are its own (SECTION 22b)
while :; do
  _fstart=$EPOCHREALTIME
  # ── THE ANIMATION CLOCK IS NOT THE WALL CLOCK ──────────────────────────
  # Everything on this machine moves as a function of t, and reading t off
  # the wall at the top of each frame is the obvious thing and a slightly
  # wrong one: a sleep that overshoots by four milliseconds does not just
  # show the frame late, it shows a frame whose chase lights have moved
  # FURTHER than the frame before it.  The lateness is invisible; the uneven
  # step is not, and the eye reads a rhythm in it.
  #
  # So the clock advances by exactly one frame's worth per frame, and every
  # motion gets an even stride whatever the scheduler did.  It is not allowed
  # to DRIFT, though -- a machine that cannot hold its rung would otherwise
  # run its own animation slow for ever -- so when it has wandered a quarter
  # of a second from the wall it is put back, which is the same threshold
  # beat_gap uses to give up catching up.
  _real=$(( _fstart - T0 ))
  (( TANIM < 0.0 )) && TANIM=$_real
  (( _real - TANIM > 0.25 || TANIM - _real > 0.25 )) && TANIM=$_real
  _t=$TANIM
  # ── THE SELF-HEAL ──  A renderer that only repaints what changed cannot
  # repair what it did not break.  Anything that writes to this terminal from
  # outside the frame -- a stray line from a shell function, a background job
  # that found a voice, a resize the kernel reported late -- moves the picture
  # and the picture stays moved, because every cell still matches what the
  # renderer last sent.  So it forgets, and paints again -- ONE ROW AT A
  # TIME, every few frames, so the whole screen is repainted every eight
  # seconds without a single frame paying for all of it.  Forgetting the lot
  # at once was a sixth of a second of stall every eight seconds, and it
  # dragged the governor down a rung each time it landed.
  if (( _fstart - HEAL_AT > HEAL_EVERY )); then
    HEAL_AT=$_fstart
    (( HEAL_ROW >= TROWS )) && HEAL_ROW=0
    r_heal_row $HEAL_ROW
    (( HEAL_ROW++ )); (( HEAL_ROW >= TROWS )) && HEAL_ROW=0
  fi
  # THE SLOW PROBE, IF IT HAS LANDED.  Checked on the beat rather than waited
  # on, and once: the ladder is rebuilt under the governor and the machine
  # steps onto whichever rung of the new one it can hold.
  # ...and the PANEL line on the glass is one of the things that was written
  # from the old answer, so the cached rectangle is retired with the rung.
  if [[ -n "$HZ_PROBE" ]] && _hz_probe_read; then beat_reset; (( GLASS_GEN++ )); fi
  [[ -n "$FROZEN" ]] && (( _t > FROZEN )) && _t=$FROZEN
  # a resize is noticed by MEASURING, not by being told: zsh defers a WINCH
  # trap until the enclosing `read` finishes, which here means until a key is
  # pressed.  The beat is already running; asking the kernel on the beat is
  # one stty a tenth of a second and it is the only thing that works.
  if c_size; then rebuild; BEAT_SKIP=1; fi
  # THE REFLOW FOLLOWS THE SURFACE, and a surface change carries no resize --
  # walking from the menu into a machine and back is the cursor moving, not the
  # window.  So the geometry is re-fitted here whenever it no longer matches
  # what the surface up wants: fill for TERMINAL's own menu, the fixed glass for
  # a machine standing on it.  Stable between changes, so it costs one compare a
  # frame and rebuilds only on the step across.
  if (( CFG_FILL )) && { [[ -z "$UI_SURF" ]] || (( PACK_FILL )) }; then _wantfill=1; else _wantfill=0; fi
  # A SURFACE JUST OPENED HOLDS THE GLASS AT ITS CURRENT SIZE until it has laid
  # one frame.  Its PACK_FILL is still the surface behind it until the fold's
  # unfold lands the first paint -- so without this hold a page that fills shows
  # the float cabinet for the whole length of the fold and then snaps to fill.
  # The menu is exempt: it is deterministic (always fills when CFG_FILL).
  if (( ! SURF_PAINTED )) && [[ -n "$UI_SURF" ]]; then _wantfill=$GEOM_FILL; fi
  if (( _wantfill != GEOM_FILL )); then rebuild; BEAT_SKIP=1; fi
  if (( ! FITS )); then
    draw_small
    IFS= read -rsk1 -u0 -t 0.25 _key || _key=''
    [[ "$_key" == (q|Q) ]] && { cleanup; exit 0 }
    continue
  fi
  # the message on the coin door fades after a few seconds
  [[ -n "$SAY_MSG" ]] && (( $EPOCHREALTIME - SAY_T > MO_TOAST )) && SAY_MSG=''
  # EVERY SESSION IN THE GLASS TERMINAL IS READ, whichever surface is up:
  # the one on the keyboard every frame, the others by turns
  gt_pump
  frame_begin $_t
  if (( UI_GATE )); then
    xf_frame draw_gate $_t
  elif [[ -n "$UI_INST" ]]; then
    xf_frame draw_inst $_t
  elif [[ -n "$UI_SURF" ]]; then
    # A MACHINE'S GLASS IS NOT CACHEABLE and does not pretend to be.  What is
    # on TERMINAL's own glass holds still between keypresses -- one row
    # breathes and the rest is a rectangle copied out of a layer -- and what
    # is on a monitor's moves in every cell of it.  So the pack paints the
    # lot, the wire puts the tube over what changed, and the governor finds
    # the rung that pays for it.
    # GUARDED LIKE EVERY OTHER HOOK.  An empty ${PACK_TICK} does not expand to
    # nothing and stop -- under SH_WORD_SPLIT the frame clock becomes the
    # COMMAND, `command not found: 12.345`, once per frame for the whole
    # visit.  With stderr held that is a file growing at thirty lines a second
    # and a wall of them dumped on the reader when the picture comes down.
    [[ -n "$PACK_TICK" ]] && ${PACK_TICK} $_t
    # THE PICTURE GOES THROUGH THE CHANNEL CHANGE, whether it is the machine
    # opening, closing, or turning one of its own pages: the pack arms the
    # transition and the cabinet runs it.
    if [[ -n "$PACK_DRAW" ]]; then xf_frame ${PACK_DRAW} $_t
    else xf_frame surf_blank $_t; fi   # a machine with no picture stands on bare glass
  else
    xf_frame menu_frame $_t
  fi
  # THE INCOMING SURFACE HAS LAID A REAL FRAME once the fold is past its collapse
  # (xf_frame paints only from the unfold on) -- from here its PACK_FILL is fresh
  # and the hold above lets go, so the reflow to fill happens without a flash.
  if (( ! SURF_PAINTED )) && [[ -n "$UI_SURF" ]]; then
    (( XF_T0 < 0.0 )) && SURF_PAINTED=1
    (( XF_SCALE > 0.0 && XF_T0 >= 0.0 && (_t - XF_T0) / XF_SCALE >= MO_XF_LINE )) && SURF_PAINTED=1
  fi
  frame_end_cached $_t
  # THE HOUSE COMING HOME.  Every machine watches the same token; when the
  # last one leaves it takes the token with it, and TERMINAL -- watching the
  # same file -- comes to the front and reads the machine again.
  if [[ -n "$SUITE_TOKEN" ]] && ! suite_up; then
    SUITE_TOKEN=''
    front_tab
    probe_scan
    say "the house came home"
  fi
  # WHAT IT ACTUALLY MANAGED, measured over a two-second window and put on
  # the footer only when a harness asks for it -- a rate nobody can check is
  # a rate nobody can trust.
  (( FPS_N++ ))
  if (( _fstart - FPS_T0 > 2.0 )); then
    FPS_SEEN=$(( FPS_N / (_fstart - FPS_T0) )); FPS_N=0; FPS_T0=$_fstart
  fi
  # THE FRAME'S OWN COST goes to the governor, and what is left of its slot
  # is spent waiting for a key.  A read that times out IS the sleep -- so a
  # key pressed in the middle of a slot is answered in the middle of it, and
  # the beat only ever costs the time nothing else wanted.
  _work=$(( $EPOCHREALTIME - _fstart ))
  # A FRAME THAT DID SOMETHING ELSE IS NOT A FRAME THE GOVERNOR SHOULD SEE.
  # Sourcing a pack, running the installer, standing the cabinet up again
  # after a resize: one-offs, each a good fraction of a second, and each one
  # used to read as six hot frames and cost a rung that took three seconds
  # to climb back.
  if (( BEAT_SKIP )); then BEAT_SKIP=0; else beat_govern $_work; fi
  beat_gap
  # THE CLOCK ADVANCES BY THE STRIDE THE MACHINE IS ACTUALLY TAKING, smoothed
  # the way the opening's own beat smooths it: the measured gap between this
  # frame's start and the last one's, allowed to grow or shrink by a bounded
  # amount per frame.  It used to advance by exactly one rung's worth, which
  # is even -- and on a frame that overran its rung it fell behind the wall,
  # ran every motion slow until it was a quarter of a second late, and then
  # jumped.  The stride is even too, and it keeps up.
  if (( LAST_FSTART > 0.0 )); then
    _dt=$(( _fstart - LAST_FSTART ))
    (( _dt < 0.004 )) && _dt=0.004; (( _dt > 0.5 )) && _dt=0.5
    if (( STRIDE <= 0.0 )); then STRIDE=$_dt
    elif (( _dt > STRIDE * 1.4 )); then STRIDE=$(( STRIDE * 1.4 ))
    elif (( _dt < STRIDE * 0.7 )); then STRIDE=$(( STRIDE * 0.7 ))
    else STRIDE=$_dt; fi
  else
    STRIDE=$(( 1.0 / FPS ))
  fi
  LAST_FSTART=$_fstart
  TANIM=$(( TANIM + STRIDE ))
  _rc=0; _key=''
  _tread=$EPOCHREALTIME
  if [[ -n "$PEND_KEY" ]]; then
    # ...the one the opening caught on its way out, answered before the beat
    # rather than after it, because it was pressed a tenth of a second ago.
    _key="$PEND_KEY"; PEND_KEY=''
  else
    IFS= read -rsk1 -u0 -t $GAP _key || _rc=$?
  fi
  if (( _rc != 0 )); then
    # ZSH ANSWERS 1 FOR A TIMEOUT AND FOR A CLOSED STDIN ALIKE, so the clock
    # is what separates them: a real timeout burns its slice, a closed stdin
    # returns instantly.  Three instant returns and there is nobody there --
    # without this the loop spins until it is killed.
    if (( $EPOCHREALTIME - _tread < GAP / 2.0 && GAP > 0.004 )); then
      (( _fast++ )); (( _fast >= 3 )) && { cleanup; exit 0 }
    else
      _fast=0
      # A BEAT NOBODY WANTED · the next piece of a machine the opening did
      # not get round to (SECTION 22b), if the menu is only standing there
      (( ${#WARM_Q[@]} )) && warm_idle
    fi
    continue
  fi
  _fast=0
  WARM_KEY_AT=$EPOCHREALTIME
  # ATTACHED: THE KEYBOARD BELONGS TO WHATEVER THE MACHINE IS RUNNING.
  #
  # THE WHOLE BURST, NOT ONE BYTE.  An arrow is three bytes and a paste is
  # hundreds, and handing them over one at a time would make a pasted plan
  # arrive character by character with a frame between each -- so everything
  # already in the buffer goes with the byte that woke the loop.  The drain
  # is bounded: a reader cannot type faster than this and a paste larger than
  # this simply arrives as two.
  # GUARDED BY `$UI_SURF` LIKE THE TICK AND THE DRAW ARE.  The hooks stay
  # bound after a machine is closed -- that is what PACK_AT is for -- and a
  # hook that can take EVERY key is not one to leave answering for a machine
  # that is no longer standing.
  if [[ -n "$UI_SURF" && -n "$PACK_RAW" ]] && ${PACK_RAW} want; then
    _raw="$_key"
    _n=0
    while (( _n++ < 4096 )); do
      _k2=''
      IFS= read -rsk1 -u0 -t 0.001 _k2 2>/dev/null || break
      _raw+="$_k2"
    done
    # THE MOUSE IS THE CHILD'S ONLY IF IT ASKED.  The reports come in the
    # same burst as the keys; a program that switched the mouse on in the
    # machine's terminal is handed them whole (the machine moves them into
    # its grid), and for any other they are sifted out -- a wheel notch over
    # the glass then scrolls the machine's own view of the program, the
    # lines that have gone off the top of it, which is what the wheel does
    # everywhere else on this cabinet.
    if ${PACK_RAW} mouse; then
      ${PACK_RAW} feed "$_raw" >/dev/null
    else
      raw_sift "$_raw"
      [[ -n "$RAW_OUT" ]] && ${PACK_RAW} feed "$RAW_OUT" >/dev/null
      wheel_apply
    fi
    VIS_POKE=$_t
    continue
  fi
  # THE REST OF AN ESCAPE SEQUENCE IS READ ONCE, HERE, whatever it is (SECTION
  # 18a), and a mouse report never reaches a surface as a key: the two
  # questions used to eat three bytes of it and leave the rest in the buffer
  # for the menu to read as typed -- one notch on the installer page cancelled
  # the install and then ran whatever row the last byte named.  The wheel is
  # answered here for every surface, and the surfaces below see only keys.
  KSEQ=''; MOUSE=0
  if [[ "$_key" == $'\e' ]]; then
    key_seq
    if (( MOUSE )); then
      wheel_drain
      wheel_apply
      VIS_POKE=$_t
      continue
    fi
  fi
  # HE LOOKS UP WHEN YOU DO SOMETHING.  The one line of state the visitor has,
  # and it is written here rather than anywhere near him: this is the only
  # place in the file that knows a key has actually arrived.
  VIS_POKE=$_t
  # the two questions answer any key with "no", the escape's tail included
  if (( UI_GATE )) || [[ -n "$UI_INST" ]]; then
    [[ "$_key" == $'\e' ]] && { PEND_KEY=''; PEND_ESC=0; PEND_SEQ='' }
  fi
  if (( UI_GATE )); then
    case "$_key" in
      y|Y) power_down
           # [Q] IS THE ONLY POWER SWITCH IN THE HOUSE, AND WHAT IT SWITCHES
           # OFF IS THE CABINET -- not Terminal.  The question on the glass
           # says so in as many words: terminal.app stays, the prompt comes
           # back.  This used to break that promise.  It asked Terminal itself
           # to quit, which went for every other window and tab the reader had
           # open (stopping only to ask about the ones with work running in
           # them) and left no prompt to come back to.
           # The hook opens the cabinet WITHOUT exec for exactly this: leaving
           # it leaves the reader at the prompt they would have had, in the
           # window they already have.  So the tube goes out, the terminal is
           # put back, and the shell underneath gets its window back.  A
           # cabinet double-clicked from Finder ends the way any .command
           # does, with Terminal's own setting deciding whether that window
           # closes.
           cleanup
           exit 0 ;;
      *)   UI_GATE=0; xf_arm $MO_QUICK_OUT; snd away ;;
    esac
    continue
  fi
  # THE INSTALLER TAKES EVERY KEY WHILE IT IS STANDING, [Q] included.  A page
  # asking whether to change somebody's ~/.zshrc is not a page to be powering
  # the cabinet off from by reflex -- and anything that is not [Y] is the
  # same answer, which is the shape a question this size should have.
  if [[ -n "$UI_INST" ]]; then
    case "$INST_STAGE" in
      ask)   case "$_key" in
               y|Y) inst_do ;;
               *)   inst_close ;;
             esac ;;
      # the second question: Y runs the tools in the terminal, anything else
      # keeps the hook that is already in and leaves the tools for later
      tools) case "$_key" in
               y|Y) inst_tools ;;
               *)   inst_later ;;
             esac ;;
      *)     inst_close ;;
    esac
    continue
  fi
  # A MACHINE ANSWERS FOR ITS OWN KEYS, and [M] is not one of them.  It is the
  # way OUT, the same letter on every cabinet in the suite, and a letter that
  # leaves a machine cannot also be a letter that opens a page on it -- which
  # is why the monitor's MEMORY page answers to [R].  [Q] stays the door's
  # from anywhere, because the power switch is the cabinet's and not the
  # picture's.
  if [[ -n "$UI_SURF" ]]; then
    case "$_key" in
      # ⎋ IS THE WAY BACK, AND IT IS THE MACHINE'S BEFORE IT IS THE DOOR'S.
      # A machine with pages of its own wants ⎋ to mean "back one" inside
      # itself; only when it has nothing left to go back to does the same key
      # mean "out".  So it is offered to the pack first and the door takes it
      # only if the pack says it had no use for it -- which is how one key
      # reads as back all the way out without ever skipping a level.
      $'\e')
        case "$KSEQ" in
          '[A'|'OA') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} up    >/dev/null ;;
          '[B'|'OB') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} down  >/dev/null ;;
          '[C'|'OC') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} right >/dev/null ;;
          '[D'|'OD') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} left  >/dev/null ;;
          # a page of a text view at a time · a machine with no use for it
          # says so and nothing happens
          '[5~') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} pgup  >/dev/null ;;
          '[6~') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} pgdn  >/dev/null ;;
          '')
            # a bare escape, or ESC+key (the key is already pending)
            if [[ -n "$PACK_KEY" ]] && ${PACK_KEY} esc; then :; else mach_close; fi ;;
          *) ;;   # a sequence nobody asked for (F-keys, a modified arrow)
        esac ;;
      # ⏎ picks whatever the machine has under its own cursor
      $'\r'|$'\n') [[ -n "$PACK_KEY" ]] && ${PACK_KEY} enter >/dev/null ;;
      # ⌫ AND [M] ARE THE SAME DOOR, said two ways somebody will try -- and
      # like ⎋ above, they are the MACHINE'S before they are the door's.
      #
      # THIS IS WHAT A TEXT FIELD ON A MACHINE COSTS.  A pack that asks the
      # reader to type a question gets one key at a time from this loop, and
      # three of the keys in that question never arrived: ⌫ closed the
      # machine, `m` closed the machine, and `q` opened the power gate -- so
      # `how many` shut the cabinet on the `m` and a mistyped word could not
      # be taken back.  Offering them to the pack first is the same contract
      # ⎋ already has, and it costs the door nothing: a pack that is not
      # typing refuses them, and the door does exactly what it did before.
      $'\x7f'|$'\b')
        if [[ -n "$PACK_KEY" ]] && ${PACK_KEY} back; then :; else mach_close; fi ;;
      m|M)
        if [[ -n "$PACK_KEY" ]] && ${PACK_KEY} "$_key"; then :; else mach_close; fi ;;
      q|Q)
        if [[ -n "$PACK_KEY" ]] && ${PACK_KEY} "$_key"; then :
        else UI_GATE=1; xf_arm $MO_QUICK_IN; snd open; fi ;;
      *)   if [[ -n "$PACK_KEY" ]] && ! ${PACK_KEY} "$_key"; then
             [[ "$_key" == [A-Za-z] ]] && { say "no ${_key:u} on this machine"; snd no }
           fi ;;
    esac
    continue
  fi
  # THE CONFIG POPUP TAKES THE MENU'S KEYS WHILE IT IS UP.  It stands over the
  # glass like a machine's own chooser: navigation changes a setting, ⎋/[M]/[C]
  # fold it away, and nothing it does not name reaches the menu behind it.  The
  # menu speaks RAW keys (the machine branch above was handed normalised ones),
  # so the arrows and ⏎ are turned into the same tokens cfg_modal_key reads.
  if (( CFG_OPEN == 1 )); then
    case "$_key" in
      $'\e') case "$KSEQ" in
               '[A'|'OA') cfg_modal_key up ;;
               '[B'|'OB') cfg_modal_key down ;;
               '[C'|'OC') cfg_modal_key right ;;
               '[D'|'OD') cfg_modal_key left ;;
               '') cfg_modal_key esc ;;
             esac ;;
      $'\r'|$'\n'|'') cfg_modal_key enter ;;
      *) cfg_modal_key "$_key" ;;
    esac
    continue
  fi
  case "$_key" in
    $'\e') case "$KSEQ" in
             '[A'|'OA') (( UI_ROW > 0 )) && { (( UI_ROW-- )); snd move } ;;
             '[B'|'OB') (( UI_ROW < R_N - 1 )) && { (( UI_ROW++ )); snd move } ;;
             '[H'|'OH'|'[1~') UI_ROW=0 ;;
             '[F'|'OF'|'[4~') UI_ROW=$(( R_N - 1 )) ;;
           esac ;;
    k|K) (( UI_ROW > 0 )) && { (( UI_ROW-- )); snd move } ;;
    j|J) (( UI_ROW < R_N - 1 )) && { (( UI_ROW++ )); snd move } ;;
    # ⏎ IS A CARRIAGE RETURN IN RAW MODE.  A cooked `read` hands back the
    # empty string for a newline, which is what this matched; with the tty raw
    # -- which is the only way the other keys work at all -- the byte that
    # actually arrives is \r, and ⏎ did nothing.
    $'\r'|$'\n'|'') act_row $UI_ROW ;;
    q|Q) UI_GATE=1; xf_arm $MO_QUICK_IN; snd open ;;
    # [V] IS THE VISITOR'S OWN DOOR · a dedicated key, not a row, because he is
    # not a thing the cursor selects -- he is a page you step aside to see.
    v|V) do_visitor ;;
    # EVERY OTHER LETTER IS THE MENU'S, and the menu decides whether it is a
    # key at all.  [T] before anything is installed is not a row this shape
    # has, and saying so is better than a key that quietly does nothing.
    [A-Za-z])
      if ! act_key "$_key"; then
        say "no ${_key:u} on this menu"
        snd no
      fi ;;
  esac
done
