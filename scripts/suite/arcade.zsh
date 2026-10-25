#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════
# scripts/suite/arcade.zsh · THE ARCADE, on TERMINAL's own glass
# ══════════════════════════════════════════════════════════════════════════
# ALIEN DYNAMICS 1984 · arcade model NX-88 "SYNTHWAVE".  Twelve cabinets, one
# coin a game, a coin bank, a daily token, a high-score table for every rung
# of every machine, a market, a trophy wall and a service menu behind a held
# key.  Ported from the OLD cabinet's arcade.py (14,388 lines) and its
# wardrobe (scripts/vanity, 5,386 lines) into a page pack the door sources.
#
# ── WHAT THE DOOR ALREADY HAS ────────────────────────────────────────────
# The cabinet around this picture IS the arcade's -- the door ported its
# marquee, its tubes, its bezel, its CRT and its beat term for term, and
# says so at the top of terminal.command.  So the first 2,800 lines of the
# original are not in here: the colour, the canvas, the renderer, the tube
# and the chrome are the door's, and this file draws inside the rectangle it
# is handed with the door's own v_put / v_text / v_box / cmix / cshade / wave.
#
# ── THE CRT IS 72 × 18, AND STAYS 72 × 18 ───────────────────────────────
# Every one of the twelve was built for a 72 × 17 playfield, and the whole
# economy -- what a competent minute scores, what a machine costs, what a
# rung is worth -- was MEASURED on it.  A field that stretched with the
# window would be a different game with the same name, paying the wrong
# coins.  So the arcade's picture is its own screen, exactly the original's
# size, framed and centred on whatever glass the door offers; the glass
# around it carries the marquee and the readings, the way the cabinet's own
# bezel carried them.  On a large window it is a CRT in a cabinet, which is
# what it is.
#
# ── THE KEYBOARD, TWO WAYS ────────────────────────────────────────────────
# Menus take the door's named keys one a frame, like every machine.  A ROUND
# takes the RAW burst: a held arrow arrives as thirty repeats a second, and a
# shell frame can cost more than the gap between two of them, so a game fed
# one key a frame would fall a little further behind the reader's thumb every
# second.  `ar_raw want` says yes while a round is in play, the door hands
# over everything in the buffer, and the whole burst is answered in the one
# frame it arrived in.  The impulse-and-damping Steer that turns the burst
# into a joystick is arcade.py's, integrated exactly.
#
# ── ZSH, AND THE THINGS IT PUNISHES ──────────────────────────────────────
# KSH_ARRAYS: every array and every string subscript is 0-based.  set -u: an
# unset read ENDS THE SHELL, so every assoc read is defaulted.  No printf in
# a frame: a fork a frame is how you lose a page, and a locale in a number is
# how you lose a save.  A set is an assoc keyed "x,y".  A deque is a ring.
# ══════════════════════════════════════════════════════════════════════════
zmodload zsh/mathfunc 2>/dev/null
zmodload zsh/datetime 2>/dev/null

# ══════════════════════════════════════════════════════════════════════════
# SECTION 1 · THE SCREEN AND THE MONEY          arcade.py's section 1, what is left of it
# ══════════════════════════════════════════════════════════════════════════
# THE CRT IS THE GLASS.  arcade.py stood a 72 x 18 tube inside its own
# cabinet; in this house the cabinet is the door's, so the picture takes the
# whole glass under the head band and over the key bar -- 104 x 26 on the
# standard glass, more in fill mode -- and every room and every board is laid
# out to whatever AR_W x AR_H it is handed.  A round holds the board it was
# dealt (AR_RW x AR_RH) until it is over, so a window dragged mid-game never
# moves a wall under a player.
typeset -gi AR_W=104 AR_H=26           # the CRT interior · set each frame from the glass
typeset -gi AR_FT=1                    # FIELD_TOP · row 0 is the HUD
typeset -gi AR_FH=25                   # FIELD_H · AR_H - AR_FT
typeset -gi AX=0 AY=0                  # where the CRT sits on the glass · set each frame
typeset -gi AR_RW=0 AR_RH=0            # the board a round was dealt · 0 when no round is standing
typeset -gi AR_GMAX_W=320 AR_GMAX_H=96 # a board as big as any real glass · only a freakish one is centred
typeset -gi AR_OW=72 AR_OH=18          # arcade.py's own tube · the unit the boards grow from

typeset -gi AR_START_COINS=10 AR_MAX_COINS=9999 AR_PLAY_COST=1
typeset -gi AR_BONUS_TOP5=10 AR_BONUS_RECORD=25
typeset -gi AR_DAILY_COINS=10 AR_DAILY_MIN=10
typeset -gi AR_BOARD_LO=1000 AR_BOARD_HI=99999
typeset -gi AR_OPEN_RUNGS=2
typeset -gi AR_NAME_MAX=14

# ── THE FOUR RUNGS · the seeded-table scale and the worth are measurements ──
typeset -ga  AR_DK AR_DN AR_DB                       # key · name · blurb
typeset -ga AR_DM                                   # coin multiplier
typeset -ga  AR_DC                                   # accent (set once the palette is up)
typeset -ga AR_DCOST                                # coins to unlock, 0 = open
typeset -ga AR_DFRAC AR_DSEED AR_DWORTH
AR_DK=(rookie normal expert insane)
AR_DN=(ROOKIE NORMAL EXPERT INSANE)
AR_DB=('gentle pace, the edges wrap around, gems linger' \
       'the arcade default -- the walls are fatal' \
       'quicker, hazards on the grid, gems decay fast' \
       'brutal speed across a minefield. good luck.')
AR_DM=(0.5 1.0 2.0 3.5)
AR_DCOST=(0 0 400 900)
AR_DFRAC=(0.0 0.0 0.30 0.55)
AR_DSEED=(1.30 1.00 0.85 0.62)
AR_DWORTH=(1.00 1.63 3.25 6.69)
typeset -gi AR_DEFAULT_DIFF=1

# ── THE LINEUP · one place that knows which rules belong to which slot ───
# id · title · genre · year · players · stars · seed top · payout · price · pace
typeset -ga  AR_GID AR_GTITLE AR_GGENRE AR_GYEAR AR_GPLAYERS AR_GBLURB AR_GHOWTO
typeset -ga AR_GSTARS AR_GTOP AR_GPAYOUT AR_GPRICE AR_GPACE AR_GACC
AR_GID=(snake blockfall voidpong bricknova starraid gridrunner laserdodge nightdrive lightcycle plasmaball astrodrift beatgrid)
AR_GTITLE=('NEON SNAKE' 'BLOCK FALL' 'VOID PONG' 'BRICK NOVA' 'STAR RAIDER' 'GRID RUNNER' \
           'LASER DODGE' 'NIGHT DRIVE' 'LIGHT CYCLE' 'PLASMA BALL' 'ASTRO DRIFT' 'BEAT GRID')
AR_GGENRE=(ARCADE PUZZLE SPORTS ACTION SHOOTER MAZE REFLEX RACING ARENA PINBALL SPACE RHYTHM)
AR_GYEAR=(1988 1989 1985 1986 1987 1990 1991 1992 1993 1994 1995 1996)
AR_GPLAYERS=(1P 1P 1-2P 1P 1P 1P 1P 1P 1-2P 1P 1P 1P)
AR_GSTARS=(5 5 3 4 5 4 3 4 5 4 4 5)
AR_GTOP=(19000 620000 7500 53000 535000 17000 176000 15000 45000 260000 70000 652000)
AR_GPAYOUT=(202 2994 70 441 2953 330 1506 465 649 3506 639 2635)
# HOW FAST EACH MACHINE SCORES ON A BIGGER BOARD, against arcade.py's 72 × 18 ·
# the same demonstrator's own points a minute on a board of arcade.py's size,
# on the float glass's 104 × 26 and on a full 198 × 50, two to four runs of two
# and a half minutes a size · GPR1 and GPR2 are the two bigger boards' rates
# over the first.  The machines whose rules are the board's shape at any size -- pong,
# the drive, the pinball, the beat, the well -- are 1 by construction (pong
# was checked with a perfect paddle, the well measured 1.05 and 0.98).  Snake
# falls hardest and is meant to: a bite pays by the level, the level comes
# every five bites, and on a big floor the bites are three times as far apart.
# See ar_rate_ratio: every point a machine awards is scaled back by this.
typeset -ga AR_GPR1 AR_GPR2
AR_GPR1=(0.69 1.00 1.00 1.29 0.74 0.73 1.24 1.00 1.26 1.00 0.52 1.00)
AR_GPR2=(0.14 1.00 1.00 1.17 0.23 0.85 1.44 1.00 1.50 1.00 0.34 1.00)
typeset -gF AR_PA1=2.0864 AR_PA2=7.6389     # those two boards' areas over arcade.py's
AR_GPRICE=(0 1360 120 220 1000 300 160 400 1840 550 740 2500)
AR_GPACE=(4450 137711 1676 12361 124043 9906 39167 15349 32468 126200 24921 144920)
AR_GBLURB=('Devour the datastream. Grab the star gems before they decay. Do not eat your own tail.' \
 'Seven shapes fall forever. Clear four lines at once and the arcade screams.' \
 'The original. Two paddles, one photon, zero mercy.' \
 'Detonate the wall. Catch the falling power cells. Do not lose the photon.' \
 'They descend in formation and they get faster every wave. Hold the line.' \
 'Eat the grid, dodge the daemons, grab the power node and turn the tables.' \
 'Sixty seconds. Rising beam density. Your reflexes are the only upgrade.' \
 'Chrome, palm trees and an endless purple highway. Beat the clock to the next checkpoint.' \
 'Leave a wall behind you and box the other rider in before they do it to you.' \
 'Bumpers, ramps and a ball made of light. Keep it off the drain for as long as you can.' \
 'Momentum has no brakes out here. Split the rocks, mind the fragments, watch your fuel.' \
 'Four lanes, one metronome. Hit the line clean and the whole arcade lights up with you.')
typeset -gi AR_NG=12
# WHICH ONES ARE WIRED.  A slot with no rules yet reads COMING SOON on the
# menu and opens the cartridge screen, the way the original shipped its
# empty slots -- an honest ○ rather than a row that does nothing.
typeset -gA AR_READY; AR_READY=(snake 1)

# THE LIST IS arcade.py's: four system rows over the twelve, and the way out
# under them.  SETTINGS was never a row -- [S] and the ◂ ▸ walk are its doors.
typeset -ga AR_SID AR_STITLE AR_SGLYPH AR_SBLURB AR_SACC
typeset -gi AR_FIRST=4                   # where the lineup starts · the cursor boots here
AR_SID=(market scores badges ledger menu)
AR_STITLE=('MARKETPLACE' 'HIGH SCORES' 'TROPHY ROOM' 'THE LEDGER' 'MENU')
AR_SGLYPH=('◈' '◆' '✦' '▤' '◉')
AR_SBLURB=('Buy an arcade outright, or rent one by the hour.' \
           'The hall of fame, one table per difficulty rung.' \
           'Everything the machines will give you for playing well.' \
           'Everything you have done here, added up.' \
           'Back to the door -- and the rest of the house with you.')

# the rent tiers: label · seconds · price = ceil(price*num/den), never under floor
typeset -ga  AR_RLAB; AR_RLAB=('1 HOUR' '24 HOURS')
typeset -ga AR_RSEC AR_RNUM AR_RDEN AR_RFLOOR
AR_RSEC=(3600 86400); AR_RNUM=(1 2); AR_RDEN=(6 5); AR_RFLOOR=(6 16)

typeset -ga AR_SEED_NAMES
AR_SEED_NAMES=(AAA NEO ZAP RGB VHS SYN TRN CRT MAX JET ACE KAT ORB XYZ 808 DRK LUX NVA \
               HAL JMP MEG PXL RAD TKO VIC WVE ZED DJG RJM SLK TMB AMY BOB DAN JOE LIZ \
               SUE PAT RAY GUS IVY MO KC JP)

# ══════════════════════════════════════════════════════════════════════════
# SECTION 2 · THE VIEW          arcade.py's View, as four functions with an offset
# ══════════════════════════════════════════════════════════════════════════
# Everything the arcade draws is in CRT coordinates, 0..AR_W-1 × 0..AR_H-1.  These
# add where the CRT stands on the glass and clip to it, the way the door's
# v_* add where the glass stands in the window.  -2 leaves a colour alone.
a_put()    { (( $1 < 0 || $1 >= AR_W || $2 < 0 || $2 >= AR_H )) && return 0
             v_put $(( AX + $1 )) $(( AY + $2 )) "$3" ${4:--2} ${5:--2} }
a_tint()   { (( $1 < 0 || $1 >= AR_W || $2 < 0 || $2 >= AR_H )) && return 0
             v_tint $(( AX + $1 )) $(( AY + $2 )) $3 }
a_text()   { local -i x=$1; local s="$3"
             (( $2 < 0 || $2 >= AR_H )) && return 0
             (( x >= AR_W )) && return 0
             if (( x < 0 )); then (( -x >= ${#s} )) && return 0; s="${s[$(( -x )),-1]}"; x=0; fi
             (( x + ${#s} > AR_W )) && s="${s[0,$(( AR_W - x - 1 ))]}"
             [[ -n "$s" ]] || return 0
             v_text $(( AX + x )) $(( AY + $2 )) "$s" ${4:--2} ${5:--2} }
a_center() { local -i w=${6:-$AR_W} x0=${5:-0}
             a_text $(( x0 + (w - ${#2}) / 2 )) $1 "$2" ${3:--2} ${4:--2} }
# A RUN OF ONE GLYPH comes from the cabinet's _run (zsh pads in C) where the
# cabinet has one, and is appended glyph by glyph where it has not.
a_run()    { if (( ${+functions[_run]} )); then _run $1 "$2"; else local -i i; RUN=''; for (( i = 0; i < $1; i++ )); do RUN+="$2"; done; fi }
a_fill()   { local -i y yy=$2 h=$4
             (( $3 > 0 )) || return 0
             a_run $3 "${5:- }"; local s="$RUN"
             for (( y = yy; y < yy + h; y++ )); do a_text $1 $y "$s" ${6:--2} ${7:--2}; done }
a_hline()  { (( $3 > 0 )) || return 0
             a_run $3 "$4"; local s="$RUN"
             a_text $1 $2 "$s" ${5:--2} ${6:--2} }
a_box()    { # a_box X Y W H FG BG STYLE FILL — clipped by the v_* underneath
             local -i x=$1 y=$2 w=$3 h=$4 yy i; local st="${7:-round}" tl tr bl br hz vt line=''
             case "$st" in
               double) tl='╔'; tr='╗'; bl='╚'; br='╝'; hz='═'; vt='║' ;;
               heavy)  tl='┏'; tr='┓'; bl='┗'; br='┛'; hz='━'; vt='┃' ;;
               light)  tl='┌'; tr='┐'; bl='└'; br='┘'; hz='─'; vt='│' ;;
               *)      tl='╭'; tr='╮'; bl='╰'; br='╯'; hz='─'; vt='│' ;;
             esac
             (( w > 2 )) && { a_run $(( w - 2 )) "$hz"; line="$RUN"; }
             a_text $x $y "$tl$line$tr" ${5:--2} ${6:--2}
             a_text $x $(( y + h - 1 )) "$bl$line$br" ${5:--2} ${6:--2}
             if (( ${8:-0} )); then        # filled · the sides and the fill are one text a row
               local mid=''; (( w > 2 )) && { a_run $(( w - 2 )) ' '; mid="$RUN"; }
               for (( yy = y + 1; yy < y + h - 1; yy++ )); do a_text $x $yy "$vt$mid$vt" ${5:--2} ${6:--2}; done
             elif (( AR_DIRECT )); then    # the sides as two rails, straight into the cells
               a_rect $x $(( y + 1 )) 1 $(( h - 2 )) "$vt" ${5:--2} ${6:--2}
               a_rect $(( x + w - 1 )) $(( y + 1 )) 1 $(( h - 2 )) "$vt" ${5:--2} ${6:--2}
             else
               for (( yy = y + 1; yy < y + h - 1; yy++ )); do
                 a_put $x $yy "$vt" ${5:--2} ${6:--2}; a_put $(( x + w - 1 )) $yy "$vt" ${5:--2} ${6:--2}
               done
             fi }
# a_tintr X Y W H COL AMT — arcade.py's tint(): wash a rectangle's ground
# THE WASH IS REMEMBERED.  A tint touches every cell of a field, and nearly
# every cell of a field has the same ground, so the mix is worked out once a
# ground and kept (the amount to a hundredth, which no eye can split): a
# thousand-cell wash was a thousand colour mixes and is now a handful.
typeset -gA AR_TMEMO
a_tintr()  { local -i x=$1 y=$2 w=$3 h=$4 col=$5 xx yy k base bg q=$(( int($6 * 100 + 0.5) )) got
             (( ${#AR_TMEMO[@]} > 4096 )) && AR_TMEMO=()
             base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
             for (( yy = y; yy < y + h; yy++ )); do
               (( yy < 0 || yy >= AR_H )) && continue
               for (( xx = x; xx < x + w; xx++ )); do
                 (( xx < 0 || xx >= AR_W )) && continue
                 k=$(( base + (AY + yy) * TCOLS + AX + xx ))
                 bg=${GB[$k]:-$GLASS}; (( bg < 0 )) && bg=$GLASS
                 got=${AR_TMEMO[$bg:$col:$q]:--1}
                 if (( got < 0 )); then cmix $bg $col $(( q / 100.0 )); got=$CM; AR_TMEMO[$bg:$col:$q]=$got; fi
                 GB[$k]=$got
               done
             done }
# a_power P — the whole CRT at P of its gain, ink and ground alike · arcade.py's
# end(t, power), which the ledger and the hall of fame opened at 0.4 and brought
# up to full in a sixth of a second.  The house owns the tube, so the pack turns
# its own picture down instead · remembered by colour, like the wash above.
# A ROW AT A TIME, A COLOUR AT A TIME.  The field was turned down a cell at a
# time -- ten thousand cells, two lookups each, the better part of a second a
# frame for the frames the rooms take to warm up -- when a row holds a handful
# of colours between its two hundred cells.  So each colour in the row is
# turned down once and put back over every cell that holds it in one C-level
# pass (tagged on the way, so a colour that lands on another colour of the same
# row is not turned down twice), and the row goes back as two slices.
a_power()  { local -i x y k e base q=$(( int($1 * 100 + 0.5) )) c got
             (( q >= 100 )) && return 0
             (( ${#AR_TMEMO[@]} > 4096 )) && AR_TMEMO=()
             base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
             local -a pf pb pu; local pc
             for (( y = 0; y < AR_H; y++ )); do
               k=$(( base + y * TCOLS )); e=$(( k + AR_W - 1 ))
               if (( AR_W > 0 && k >= 0 && e < ${#GF[@]} && e < ${#GB[@]} )); then
                 pf=("${(@)GF[k,e]}"); pb=("${(@)GB[k,e]}")
                 pu=("${(@u)pf[@]}" "${(@u)pb[@]}"); pu=("${(@u)pu[@]}")
                 for pc in "${pu[@]}"; do
                   [[ "$pc" == <-> ]] || continue
                   got=${AR_TMEMO[p:$pc:$q]:--1}; (( got < 0 )) && { cshade $pc $(( q / 100.0 )); got=$CS; AR_TMEMO[p:$pc:$q]=$got; }
                   pf=("${(@)pf[@]/#%$pc/x$got}"); pb=("${(@)pb[@]/#%$pc/x$got}")
                 done
                 GF[k,e]=("${(@)pf[@]#x}"); GB[k,e]=("${(@)pb[@]#x}")
                 continue
               fi
               for (( x = 0; x < AR_W; x++, k++ )); do
                 c=${GF[$k]:--1}
                 if (( c >= 0 )); then got=${AR_TMEMO[p:$c:$q]:--1}; (( got < 0 )) && { cshade $c $(( q / 100.0 )); got=$CS; AR_TMEMO[p:$c:$q]=$got; }; GF[$k]=$got; fi
                 c=${GB[$k]:--1}
                 if (( c >= 0 )); then got=${AR_TMEMO[p:$c:$q]:--1}; (( got < 0 )) && { cshade $c $(( q / 100.0 )); got=$CS; AR_TMEMO[p:$c:$q]=$got; }; GB[$k]=$got; fi
               done
             done; return 0 }
# a_rect X Y W H CH FG BG — a block of one glyph, straight into the cells ·
# a lane of a deck is a hundred cells, and a text call a row was most of the
# cost of drawing it.  Clipped to the CRT; -2 leaves a colour alone.
# A ROW IS ONE SLICE · on a big board a deck's lane is a thousand cells, and
# three assignments a cell was most of a frame.  The row of glyphs is kept by
# width and glyph, the inks come from the door's own run cache, and each row
# is then three C-level moves.  A rail one cell wide has nothing to slice.
typeset -gA AR_RCH AR_SWROW              # runs of a glyph · a selected row's grounds, a row at a time
typeset -ga AR_RUN
ar_run() {   # ar_run W GLYPH → AR_RUN · W copies of GLYPH, kept by width and glyph
  local key="$1"$'\x1f'"$2" s; local -i i
  s=${AR_RCH[$key]:-}
  if [[ -z "$s" ]]; then
    for (( i = 0; i < $1; i++ )); do s+="$2"$'\x1f'; done; s=${s%$'\x1f'}
    (( ${#AR_RCH[@]} > 512 )) && AR_RCH=(); AR_RCH[$key]=$s
  fi
  AR_RUN=("${(@ps:\x1f:)s}"); return 0 }
a_rect()   { local -i y i x0=$1 y0=$2 w=$3 h=$4 fg=${6:--2} bg=${7:--2} k base; local ch="${5:- }" s key
             (( x0 < 0 )) && { w=$(( w + x0 )); x0=0; }; (( y0 < 0 )) && { h=$(( h + y0 )); y0=0; }
             (( x0 + w > AR_W )) && w=$(( AR_W - x0 )); (( y0 + h > AR_H )) && h=$(( AR_H - y0 ))
             (( w > 0 && h > 0 )) || return 0
             base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
             if (( w == 1 )); then
               for (( y = y0; y < y0 + h; y++ )); do
                 k=$(( base + y * TCOLS + x0 )); GCH[$k]=$ch; (( fg != -2 )) && GF[$k]=$fg; (( bg != -2 )) && GB[$k]=$bg
               done; return 0
             fi
             local -a cs fs bs; ar_run $w "$ch"; cs=("${AR_RUN[@]}")
             (( fg != -2 )) && { _rep $w $fg; fs=("${REPA[@]}"); }
             (( bg != -2 )) && { _rep $w $bg; bs=("${REPA[@]}"); }
             for (( y = y0; y < y0 + h; y++ )); do
               k=$(( base + y * TCOLS + x0 ))
               GCH[$k,$(( k + w - 1 ))]=("${cs[@]}")
               (( fg != -2 )) && GF[$k,$(( k + w - 1 ))]=("${fs[@]}")
               (( bg != -2 )) && GB[$k,$(( k + w - 1 ))]=("${bs[@]}")
             done; return 0 }
# ar_bar X Y W FRAC ON [OFF] — arcade.py's bar(): a little meter, █ lit and ░ not
ar_bar()   { local -i n w=$3; local -F f=$4; local on='' off=''
             (( f < 0.0 )) && f=0.0; (( f > 1.0 )) && f=1.0; n=$(( int(f * w + 0.5) ))
             local -i i; for (( i = 0; i < w; i++ )); do if (( i < n )); then on+='█'; else off+='░'; fi; done
             [[ -n "$on" ]] && a_text $1 $2 "$on" $5 -2
             if [[ -n "$off" ]]; then if (( ${6:--1} >= 0 )); then a_text $(( $1 + n )) $2 "$off" $6 -2; else cshade $GREY 0.35; a_text $(( $1 + n )) $2 "$off" $CS -2; fi; fi
             return 0 }
# a_big STR X Y GLOW INK — the door's block font, in CRT coordinates
a_big()    { big_word "$1" $(( AX + $2 )) $(( AY + $3 )) $4; big_lit $5 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 3 · RANDOM            the board's own generator · one seed, one layout
# ══════════════════════════════════════════════════════════════════════════
# A 64-bit LCG in shell arithmetic, taking its bits from the top.  It is not
# Python's Mersenne Twister and does not have to be: no save in the house
# holds a board dealt by the original, so a board number here names a layout
# here.  Twelve microseconds a draw; a maze is a few thousand of them.
typeset -gi RS=1 RN=0
typeset -gF RF=0.0
rnd_seed() { RS=$(( ($1 * 0x9E3779B97F4A7C1) ^ 0x5DEECE66D )); (( RS == 0 )) && RS=1; return 0 }
rnd_next() { RS=$(( RS * 6364136223846793005 + 1442695040888963407 )); RN=$(( (RS >> 33) & 0x7FFFFFFF )); return 0 }
rnd_int()  { rnd_next; REPLY=$(( $1 + RN % ($2 - $1 + 1) )); return 0 }         # LO..HI inclusive
rnd_range(){ rnd_next; REPLY=$(( $1 + RN % ($2 - $1) )); return 0 }              # LO..HI-1 · randrange
rnd_f()    { rnd_next; RF=$(( RN / 2147483648.0 )); return 0 }                   # [0,1)
rnd_uni()  { rnd_next; RF=$(( $1 + (RN / 2147483648.0) * ($2 - $1) )); return 0 } # uniform LO..HI
rnd_pick() { rnd_next; REPLY=$(( RN % $1 )); return 0 }                          # an index of N
# stable_seed · arcade.py's, exactly · djb2 masked to 31 bits
ar_stable() { local s="$1"; local -i n=5381 i c
  for (( i = 0; i < ${#s}; i++ )); do c=$(( #s[i] )); n=$(( (n * 33 + c) & 0x7FFFFFFF )); done
  REPLY=$n; return 0 }
# a wall-clock generator for the boards themselves: two rounds in a sitting
# are never the same board, and the sequence still differs between sittings
typeset -gi AR_ENT=0
ar_entropy() { (( AR_ENT )) || AR_ENT=$(( (${EPOCHSECONDS:-1} * 2654435761) ^ (RANDOM * 32768 + RANDOM) ))
  AR_ENT=$(( AR_ENT * 6364136223846793005 + 1442695040888963407 )); REPLY=$(( (AR_ENT >> 33) & 0x7FFFFFFF )); return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 3b · SMALL HANDS      what every page reaches for
# ══════════════════════════════════════════════════════════════════════════
ar_wave() { WV=$(( 0.5 + 0.5 * sin($1 * $2 * TAU + ${3:-0.0}) )) }   # _wave(t, speed, phase)
ar_commify() {   # ar_commify N → REPLY "1,234,567" · no fork, no locale
  local s="$1" out=''; local -i n=${#s} i
  [[ "$s" == -* ]] && { s="${s#-}"; n=${#s}; }
  for (( i = 0; i < n; i++ )); do
    (( i && (n - i) % 3 == 0 )) && out+=','
    out+="${s[$i]}"
  done
  [[ "$1" == -* ]] && out="-$out"
  REPLY="$out"; return 0 }
ar_pad() {   # ar_pad N WIDTH → REPLY zero-padded · "%07d" without printf
  local s="$1"; while (( ${#s} < $2 )); do s="0$s"; done; REPLY="$s"; return 0 }
ar_rpad() {  # ar_rpad STR WIDTH → REPLY right-padded with spaces
  local s="$1"; while (( ${#s} < $2 )); do s+=' '; done; REPLY="$s"; return 0 }
ar_lpad() {  # ar_lpad STR WIDTH → REPLY left-padded with spaces · "%5s", and never cut short the way ${(l:N:)} is
  local s="$1"; while (( ${#s} < $2 )); do s=" $s"; done; REPLY="$s"; return 0 }
ar_stars() { local -i n=$1 i; REPLY=''; for (( i = 0; i < 5; i++ )); do (( i < n )) && REPLY+='★' || REPLY+='☆'; done; return 0 }
ar_dur()   { local -i s=$1; (( s < 0 )) && s=0
  if (( s >= 3600 )); then ar_pad $(( (s % 3600) / 60 )) 2; REPLY="$(( s / 3600 ))h ${REPLY}m"
  elif (( s >= 60 )); then ar_pad $(( s % 60 )) 2; REPLY="$(( s / 60 ))m ${REPLY}s"
  else REPLY="${s}s"; fi; return 0 }
ar_today() {   # → REPLY YYYY-MM-DD, local time, no fork
  strftime -s REPLY '%Y-%m-%d' ${EPOCHSECONDS:-0} 2>/dev/null || REPLY="$(( ${EPOCHSECONDS:-0} / 86400 ))"
  return 0 }
ar_scrub() {   # ar_scrub RAW → REPLY · upper, A-Z 0-9 space . - _ only (arcade.py's _NAME_OK), cut to NAME_MAX
  local s="${1:u}" out='' c; local -i i
  # already clean · every name a table was dealt, and every one it was written with
  if [[ -z "${s//[A-Z0-9 ._-]/}" && "$s" != ' '* && "$s" != *' ' && "$s" != *'  '* ]] && (( ${#s} <= AR_NAME_MAX )); then
    REPLY="$s"; return 0
  fi
  for (( i = 0; i < ${#s}; i++ )); do c="${s[$i]}"; [[ "$c" == [A-Z0-9\ ._-] ]] && out+="$c"; done
  while [[ "$out" == ' '* ]]; do out="${out#?}"; done
  while [[ "$out" == *' ' ]]; do out="${out%?}"; done
  while [[ "$out" == *'  '* ]]; do out="${out//  / }"; done
  REPLY="${out[0,$(( AR_NAME_MAX - 1 ))]}"; return 0 }
ar_short() {   # ar_short NAME WIDTH → REPLY cut with a middle dot
  ar_scrub "$1"; local n="${REPLY:-PLAYER}"; local -i w=$2
  if (( ${#n} <= w )); then REPLY="$n"; else (( w < 2 )) && w=2; REPLY="${n[0,$(( w - 2 ))]}·"; fi; return 0 }
ar_nkeys() {   # ar_nkeys PATTERN → REPLY how many keys of the save match it
  # COUNTED AS AN ARRAY.  ${#${(M)${(k)AR[@]}:#pat}} reads right for none and for
  # two, and for exactly one it is that one key's LENGTH -- a lone seen.snake
  # counted ten machines tried, and paid HALF THE ROW after the first round.
  local -a m; m=(${(M)${(k)AR[@]}:#$~1}); REPLY=${#m[@]}; return 0 }
ar_gix() {   # ar_gix GID → REPLY its index in the lineup, -1 if none
  local -i i; for (( i = 0; i < AR_NG; i++ )); do [[ "${AR_GID[$i]}" == "$1" ]] && { REPLY=$i; return 0 }; done
  REPLY=-1; return 1 }
ar_snd() {   # the arcade's noises, on the house's speaker
  case "$1" in
    select) snd pick ;;  coin) snd save ;;  error) snd no ;;  move) snd move ;;
    start)  snd start ;; open) snd open ;;  away) snd away ;;
  esac; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 4 · THE STATE         arcade.* in terminal.save · arcade.* in terminal.conf
# ══════════════════════════════════════════════════════════════════════════
# THE SAVE IS FLAT AND SO IS THIS.  One assoc, AR, keyed by the dotted path
# under `arcade.` -- credits, scores.snake.normal.0.name, owned.voidpong --
# so a key in the file is a key in memory and nothing is packed or parsed
# twice.  Progress lives in the save (the bank, the tables, the wall, the
# wardrobe) and settings in the conf (arcade.difficulty, arcade.player, the
# switches), which is where the original put them and where a reader with
# an editor will look.
typeset -gA AR AR_CF
typeset -g  AR_SAVE_ERR=''
typeset -gi AR_READONLY=0 AR_DIRTY=0

# what a number may run to · arcade.py's ceiling on every ledger, 2^40
typeset -gi AR_NUM_CEIL=1099511627776

ar_unq() {   # ar_unq TEXT → REPLY · a save's value, read exactly as the house's save_get reads it
  # ...WITHOUT THE FORK.  save_get answers on stdout, so every key read
  # through it was a subshell: a save with every table dealt is six hundred
  # of them, and the cabinet took a second to open.
  REPLY="$1"
  if [[ "$REPLY" == '"'*'"' ]]; then
    REPLY="${REPLY[1,-2]}"
    REPLY="${REPLY//\\\"/\"}"; REPLY="${REPLY//\\\\/\\}"; REPLY="${REPLY//\\n/ }"
  fi
  return 0 }

ar_save_load() {
  AR=(); AR_READONLY=0
  local k v
  # A KEY WITH A SPACE IN IT IS NOT ONE THIS PACK EVER WROTE, and the options
  # it runs under split a key list on spaces: such a line is left out of AR
  # and written back exactly as it was (ar_save_write keeps it).
  for k in "${(@k)SAVE[@]}"; do
    [[ "$k" == arcade.* && "$k" != *[[:space:]]* ]] || continue
    ar_unq "${SAVE[$k]}"; AR[${k#arcade.}]="$REPLY"
  done
  ar_save_adopt
  # NUMBERS ARE NUMBERS.  A hand-edited line can put a word where the bank
  # goes; under set -u that is not a wrong balance, it is arithmetic that
  # ends the cabinet.  Anything that is read in arithmetic is held to digits,
  # and to arcade.py's ceiling -- past nineteen digits zsh cannot even read
  # the number, and says so on the terminal every time it is asked.
  for k in "${(@k)AR[@]}"; do
    case "$k" in
      credits|coins|boots|dailies|visits|runs|difficulty|plays.*|best.*|owned.*|rentals.*|unlocked.*|seen.*|badges.*|svc.*|wardrobe.*|scores.*.score)
        v="${AR[$k]}"
        if [[ "$v" != <-> ]]; then unset "AR[$k]"; continue; fi
        while [[ "$v" == 0?* ]]; do v="${v#0}"; done
        if (( ${#v} > 13 )) || (( v > AR_NUM_CEIL )); then AR[$k]=$AR_NUM_CEIL; else AR[$k]=$v; fi ;;
    esac
  done
  ar_save_tables
  [[ -n "${AR[credits]:-}" ]] || AR[credits]=$AR_START_COINS
  (( ${AR[credits]} > AR_MAX_COINS )) && AR[credits]=$AR_MAX_COINS
  # A SAVE WE COULD NOT READ IN FULL IS NOT ONE WE MAY REWRITE.  The door's
  # reader stops at twenty thousand lines; a file with an arcade section past
  # that would come back empty and be written back empty.
  if (( ${#AR[@]} <= 1 )) && [[ -f "$SAVE_FILE" ]] && grep -q '^arcade\.credits=' "$SAVE_FILE" 2>/dev/null; then
    AR_READONLY=1; AR_SAVE_ERR='the save could not be read in full · nothing will be written'
  fi
  return 0
}

# THE PYTHON CABINET'S SPELLING.  arcade.py kept a table, a best and a play
# count under "gid#rung" and a wardrobe receipt under "slot:id", which the
# house's flat save writes quoted -- scores."snake#normal".0.1 -- and its
# score rows were [name, score] pairs, so a row is .0 and .1 where ours is
# .name and .score.  A save that cabinet wrote is read into this one's
# spelling here: where both spellings are present ours wins, and the old one
# is gone the next time the save is written.  Its empty-container markers
# (owned={}, worn={}) mean nothing to a flat reader and go with them.
ar_save_adopt() {
  local k sect inner rest nk gid dk; local -a ks
  ks=("${(@k)AR[@]}")
  for k in "${ks[@]}"; do
    case "$k" in
      scores|best|plays|owned|rentals|unlocked|svc|wardrobe|worn|badges|seen)
        [[ "${AR[$k]}" == '{}' || "${AR[$k]}" == '[]' ]] && unset "AR[$k]"
        continue ;;
    esac
    [[ "$k" == (scores|best|plays|wardrobe).\"* ]] || continue
    sect="${k%%.*}"; rest="${k#*.}"; inner="${rest#\"}"
    [[ "$inner" == *\"* ]] || continue
    inner="${inner%%\"*}"; rest="${rest:$(( ${#inner} + 2 ))}"
    nk=''
    case "$sect" in
      wardrobe) [[ -z "$rest" && "$inner" == ?*:?* && "$inner" != *.* ]] && nk="wardrobe.$inner" ;;
      *)
        gid="${inner%%\#*}"; dk="${inner#*\#}"
        if [[ "$inner" == ?*\#?* && "$gid" != *.* && "$dk" != *.* ]]; then
          if [[ "$sect" != scores ]]; then [[ -z "$rest" ]] && nk="$sect.$gid.$dk"
          elif [[ "$rest" == .<->.0 ]]; then rest="${rest#.}"; nk="scores.$gid.$dk.${rest%.0}.name"
          elif [[ "$rest" == .<->.1 ]]; then rest="${rest#.}"; nk="scores.$gid.$dk.${rest%.1}.score"
          fi
        fi ;;
    esac
    [[ -n "$nk" ]] || continue            # a spelling we cannot place is left as it was
    [[ -n "${AR[$nk]+x}" ]] || AR[$nk]="${AR[$k]}"
    unset "AR[$k]"
  done
  return 0 }

# THE TABLES ARE CLEANED THE WAY arcade.py CLEANED THEM, once, as they are
# read: a row is a name and a whole number, the name held to the characters a
# marquee has (a hand-edited save is text, and text can carry an escape the
# terminal would act on the moment the table was drawn), and the rows best
# first, five at most.  A table with no row left is dealt again when it is
# next looked at, as it always was.
ar_save_tables() {
  local t nm; local -a ns ss; local -i gi di i j sc have
  for (( gi = 0; gi < AR_NG; gi++ )); do
    for (( di = 0; di < 4; di++ )); do
      t="scores.${AR_GID[$gi]}.${AR_DK[$di]}"
      ns=(); ss=(); have=0
      for (( i = 0; i < 10; i++ )); do
        [[ -n "${AR[$t.$i.score]+x}${AR[$t.$i.name]+x}" ]] || continue
        have=1
        if [[ "${AR[$t.$i.score]:-}" == <-> ]]; then
          ar_scrub "${AR[$t.$i.name]:-}"; ns+=("${REPLY:-PLAYER}"); ss+=(${AR[$t.$i.score]})
        fi
        unset "AR[$t.$i.score]" "AR[$t.$i.name]"
      done
      (( have )) || continue
      for (( i = 1; i < ${#ss[@]}; i++ )); do   # best first · a stable insertion, ten rows at most
        sc=${ss[$i]}; nm="${ns[$i]}"; j=$(( i - 1 ))
        while (( j >= 0 && ss[j] < sc )); do ss[$(( j + 1 ))]=${ss[$j]}; ns[$(( j + 1 ))]="${ns[$j]}"; j=$(( j - 1 )); done
        ss[$(( j + 1 ))]=$sc; ns[$(( j + 1 ))]="$nm"
      done
      for (( i = 0; i < ${#ss[@]} && i < 5; i++ )); do AR[$t.$i.name]="${ns[$i]}"; AR[$t.$i.score]=${ss[$i]}; done
    done
  done
  return 0 }

ar_save_write() {   # rewrite terminal.save · OUR lines fresh, everyone else's kept
  (( AR_READONLY )) && { AR_SAVE_ERR='the save could not be read in full · nothing written'; return 1 }
  local dest="${SAVE_FILE:A}" dir line k v
  dir="${dest:h}"; [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null
  local tmp="${dest}.ar.$$.${RANDOM}${RANDOM}"
  rm -f "$tmp" 2>/dev/null
  local -i want=0 got=0
  {
    if [[ -f "$dest" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        # (trimmed only where there is something to trim · see the door's save_load)
        if [[ "$line" == [[:space:]]* || "$line" == *[[:space:]] ]]; then _trim "$line"; else TR="$line"; fi
        if [[ "$TR" == arcade.*=* ]]; then   # ours, and rewritten below · all but a key ar_save_load never read
          k="${TR%%=*}"
          if [[ "$k" == [[:space:]]* || "$k" == *[[:space:]] ]]; then _trim "$k"; else TR="$k"; fi
          [[ "$TR" == *[[:space:]]* ]] || continue
        fi
        print -r -- "$line"; (( want++ ))
      done < "$dest"
    fi
    for k in "${(@ok)AR[@]}"; do
      v="${AR[$k]}"
      case "$k" in
        scores.*.name|player|worn.*) v="\"${v//\"/\\\"}\"" ;;
      esac
      print -r -- "arcade.$k=$v"; (( want++ ))
    done
  } > "$tmp"
  got=$(wc -l < "$tmp" 2>/dev/null) || got=-1
  if (( got < want )); then
    AR_SAVE_ERR="save failed · wrote $got of $want lines · the old save is untouched"
    rm -f "$tmp" 2>/dev/null; return 1
  fi
  if mv -f "$tmp" "$dest" 2>/dev/null; then AR_SAVE_ERR=''; AR_DIRTY=0; save_load; return 0; fi
  AR_SAVE_ERR='save failed · could not replace the file'; rm -f "$tmp" 2>/dev/null; return 1
}

# ── terminal.conf · the arcade's own keys, read at open and rewritten in place ──
# FOUR KEYS, AND ALL FOUR DO SOMETHING: attract, freeplay, difficulty and
# player.  arcade.py kept three more -- scanlines, closeexit and fpscap -- for
# the tube, the window and the frame rate, and all three are the door's now:
# it draws the tube for every machine, it decides what powering off does to
# the window, and CONFIG's BEAT sets the rate.  So they are not read here, and
# not written either: ar_conf_save drops every arcade. line that is not one of
# the four, so a conf carried over from the Python cabinet loses those three
# the first time the arcade writes it.
ar_conf_load() {
  AR_CF=(attract 1 freeplay 0 difficulty $AR_DEFAULT_DIFF player '')
  local conf="$REPO/terminal.conf" line k v
  [[ -f "$conf" && -r "$conf" ]] || return 0
  local -i n=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    (( ++n > 20000 )) && break
    line="${line%$'\r'}"; _trim "$line"; line="$TR"
    [[ "$line" == arcade.*=* ]] || continue
    k="${line%%=*}"; v="${line#*=}"; _trim "$k"; k="${TR#arcade.}"; _trim "$v"; v="$TR"
    case "$k" in
      attract|freeplay) case "${v:l}" in on|1|yes|true) AR_CF[$k]=1 ;; *) AR_CF[$k]=0 ;; esac ;;
      difficulty) [[ "$v" == <-> ]] && (( v >= 0 && v <= 3 )) && AR_CF[difficulty]=$v ;;
      player)     [[ "$v" == '"'*'"' ]] && v="${v[1,-2]}"; ar_scrub "$v"; AR_CF[player]="$REPLY" ;;
    esac
  done < "$conf"
  return 0
}
ar_conf_save() {   # terminal.conf rewritten · our four keys set, any other arcade. line dropped, everything else kept
  local conf="$REPO/terminal.conf" dir line k v
  dir="${conf:h}"; [[ -d "$dir" && -w "$dir" ]] || return 1
  local -a out; local -A hit
  if [[ -f "$conf" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == arcade.*=* ]]; then
        k="${line%%=*}"; k="${k#arcade.}"; _trim "$k"; k="$TR"
        [[ -n "${AR_CF[$k]+x}" ]] || continue
        ar_conf_line "$k"; out+=("$REPLY"); hit[$k]=1
      else out+=("$line"); fi
    done < "$conf"
  fi
  for k in attract freeplay difficulty player; do
    [[ -n "${hit[$k]:-}" ]] && continue
    ar_conf_line "$k"; out+=("$REPLY")
  done
  local tmp="$conf.ar.$$"
  print -rl -- "${out[@]}" > "$tmp" 2>/dev/null || { rm -f "$tmp"; return 1 }
  mv -f "$tmp" "$conf" 2>/dev/null || { rm -f "$tmp"; return 1 }
  return 0
}
ar_conf_line() { local k="$1" v="${AR_CF[$1]:-}"
  case "$k" in
    attract|freeplay) (( v )) && v=on || v=off ;;
    player) v="\"$v\"" ;;
  esac
  REPLY="arcade.$k=$v"; return 0 }

# ── the bank ─────────────────────────────────────────────────────────────
ar_credits() { REPLY=${AR[credits]:-0}; return 0 }
ar_free()    { (( ${AR_CF[freeplay]:-0} || ${AR[svc.free]:-0} )) }
ar_take_coin() {   # one coin to start a game · 1 if the bank is empty
  ar_free && return 0
  local -i have=${AR[credits]:-0}
  (( have >= AR_PLAY_COST )) || return 1
  AR[credits]=$(( have - AR_PLAY_COST )); AR_DIRTY=1
  return 0 }
ar_award() {   # ar_award N [EARNED=1] → REPLY what actually went in (the bank has a ceiling)
  local -i n=$1 have=${AR[credits]:-0} room
  (( n > 0 )) || { REPLY=0; return 0 }
  room=$(( AR_MAX_COINS - have )); (( n > room )) && n=$room; (( n < 0 )) && n=0
  AR[credits]=$(( have + n ))
  (( ${2:-1} )) && AR[coins]=$(( ${AR[coins]:-0} + n ))
  AR_DIRTY=1; REPLY=$n; return 0 }
ar_spend() {   # ar_spend N · 1 if short
  local -i n=$1 have=${AR[credits]:-0}
  (( n > 0 && have >= n )) || return 1
  AR[credits]=$(( have - n )); AR_DIRTY=1; return 0 }
ar_daily_ready() { ar_free && return 1
  (( ${AR[credits]:-0} < AR_DAILY_MIN )) || return 1
  ar_today; [[ "${AR[daily]:-}" != "$REPLY" ]] }
ar_claim_daily() { ar_award $AR_DAILY_COINS 0; ar_today; AR[daily]="$REPLY"
  AR[dailies]=$(( ${AR[dailies]:-0} + 1 )); ar_save_write; return 0 }

# ── ownership ────────────────────────────────────────────────────────────
ar_owns()      { (( ${AR_GPRICE[$1]} <= 0 )) && return 0; [[ -n "${AR[owned.${AR_GID[$1]}]:-}" ]] }
ar_rent_left() { local -i e=${AR[rentals.${AR_GID[$1]}]:-0} n=${EPOCHSECONDS:-0}; REPLY=$(( e > n ? e - n : 0 )); return 0 }
ar_playable()  { ar_owns $1 && return 0; ar_rent_left $1; (( REPLY > 0 )) }
ar_rung_cap()  { # → REPLY the highest rung open on this machine
  local -i c=${AR[unlocked.${AR_GID[$1]}]:-0}; (( c < AR_OPEN_RUNGS - 1 )) && c=$(( AR_OPEN_RUNGS - 1 )); (( c > 3 )) && c=3; REPLY=$c; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 5 · THE TABLES        five names a rung, seeded until somebody beats them
# ══════════════════════════════════════════════════════════════════════════
ar_score_step() { local -i b=$1
  if (( b >= 500000 )); then REPLY=1000; elif (( b >= 50000 )); then REPLY=100
  elif (( b >= 2000 )); then REPLY=10; elif (( b >= 300 )); then REPLY=5; else REPLY=1; fi; return 0 }
typeset -ga AR_TN AR_TS     # the table in hand · names and scores, best first
ar_table() {   # ar_table GI DI → AR_TN / AR_TS · dealt on first sight and written down
  local -i gi=$1 di=$2 i v step base; local key="scores.${AR_GID[$gi]}.${AR_DK[$di]}" nm
  local -F val g1 g2 g3 g4
  AR_TN=(); AR_TS=()
  if [[ -n "${AR[$key.0.score]:-}" ]]; then
    for (( i = 0; i < 5; i++ )); do
      [[ -n "${AR[$key.$i.score]:-}" ]] || break
      AR_TN+=("${AR[$key.$i.name]:-AAA}"); AR_TS+=(${AR[$key.$i.score]})
    done
    (( ${#AR_TS[@]} )) && return 0
  fi
  # THE FACTORY TABLE, AS arcade.py DEALT IT · its own twister seeded from the
  # table's name, carried here as data (s_seed_tables) so a fresh arcade opens
  # on exactly the names and scores the original always opened on
  local sd="${AR_SEEDT[${AR_GID[$gi]}.${AR_DK[$di]}]:-}" cell
  if [[ -n "$sd" ]]; then
    i=0
    for cell in ${=sd}; do
      AR_TN+=("${cell%%:*}"); AR_TS+=(${cell##*:})
      AR[$key.$i.name]="${cell%%:*}"; AR[$key.$i.score]=${cell##*:}; i=$(( i + 1 ))
    done
    AR_DIRTY=1; return 0
  fi
  # A REAL HALL OF FAME IS A FEW REGULARS AND SOME ONE-OFFS: the leader sits
  # clear of the pack, the gaps tighten, and a name can hold two slots.
  ar_stable "${AR_GID[$gi]}#${AR_DK[$di]}"; rnd_seed $(( REPLY & 0xFFFF ))
  base=$(( int(${AR_GTOP[$gi]} * AR_DSEED[$di]) )); (( base < 20 )) && base=20
  ar_score_step $base; step=$REPLY
  rnd_uni 0.11 0.31; g1=$RF; rnd_uni 0.05 0.17; g2=$RF; rnd_uni 0.05 0.19; g3=$RF; rnd_uni 0.07 0.23; g4=$RF
  rnd_uni 0.93 1.07; val=$(( base * RF ))
  local -a seen pool; seen=(); local s2; local -i cnt
  for (( i = 0; i < 5; i++ )); do
    case $i in 1) val=$(( val * (1.0 - g1) )) ;; 2) val=$(( val * (1.0 - g2) )) ;; 3) val=$(( val * (1.0 - g3) )) ;; 4) val=$(( val * (1.0 - g4) )) ;; esac
    v=$(( int(val / step + 0.5) * step ))
    (( i && v >= AR_TS[i-1] )) && v=$(( AR_TS[i-1] - step ))
    (( v < step )) && v=$step
    pool=()
    for s2 in "${seen[@]}"; do cnt=0; for nm in "${seen[@]}"; do [[ "$nm" == "$s2" ]] && (( cnt++ )); done; (( cnt < 2 )) && pool+=("$s2"); done
    rnd_f
    if (( ${#pool[@]} && RF < 0.34 )); then rnd_pick ${#pool[@]}; nm="${pool[$REPLY]}"
    else rnd_pick ${#AR_SEED_NAMES[@]}; nm="${AR_SEED_NAMES[$REPLY]}"; fi
    seen+=("$nm"); AR_TN+=("$nm"); AR_TS+=($v)
    AR[$key.$i.name]="$nm"; AR[$key.$i.score]=$v
  done
  AR_DIRTY=1
  return 0
}
ar_high() { ar_table $1 $2; REPLY=${AR_TS[0]:-0}; return 0 }
ar_submit() {   # ar_submit GI DI NAME SCORE → REPLY rank 0..4, or -1 if it missed
  local -i gi=$1 di=$2 sc=$4 i rank=-1 n; local key="scores.${AR_GID[$gi]}.${AR_DK[$di]}"
  ar_scrub "$3"; local nm="${REPLY:-PLAYER}"
  ar_table $gi $di
  n=${#AR_TS[@]}
  for (( i = 0; i < n; i++ )); do (( sc > AR_TS[i] )) && { rank=$i; break }; done
  if (( rank >= 0 )); then
    AR_TN=("${AR_TN[@]:0:$rank}" "$nm" "${AR_TN[@]:$rank}"); AR_TS=("${AR_TS[@]:0:$rank}" $sc "${AR_TS[@]:$rank}")
    AR_TN=("${AR_TN[@]:0:5}"); AR_TS=("${AR_TS[@]:0:5}")
    for (( i = 0; i < 5; i++ )); do AR[$key.$i.name]="${AR_TN[$i]}"; AR[$key.$i.score]=${AR_TS[$i]}; done
  fi
  local bk="best.${AR_GID[$gi]}.${AR_DK[$di]}"
  (( sc > ${AR[$bk]:-0} )) && AR[$bk]=$sc
  AR[plays.${AR_GID[$gi]}.${AR_DK[$di]}]=$(( ${AR[plays.${AR_GID[$gi]}.${AR_DK[$di]}]:-0} + 1 ))
  AR[seen.${AR_GID[$gi]}]=1
  AR[runs]=$(( ${AR[runs]:-0} + 1 ))
  AR_DIRTY=1
  REPLY=$rank; return 0
}
ar_count_play() { AR[plays.${AR_GID[$1]}.${AR_DK[$2]}]=$(( ${AR[plays.${AR_GID[$1]}.${AR_DK[$2]}]:-0} + 1 )); AR[runs]=$(( ${AR[runs]:-0} + 1 )); AR_DIRTY=1; return 0 }

# ── the payout window's arithmetic · arcade.py's payout_for, line for line ──
typeset -ga  AR_PL AR_PN      # the line items: label · coins
typeset -gi  AR_PSUB=0 AR_PTOT=0
# THE POINTS ARE arcade.py'S ON ANY BOARD · a bigger board changes how fast some
# machines score -- a snake's food is further off, a light cycle has more
# riders to derezz -- and the tables, the rungs, the trophies that count points
# and the coin all read arcade.py's numbers.  So each machine's points a minute
# were measured by its own demonstrator on arcade.py's 72 × 18 and on two
# bigger boards (AR_GPR1, AR_GPR2 are those over the first), and every point a
# machine awards on the board in play is scaled back by that rate, drawn
# straight between the two on the log of the board's area and held past the
# bigger one.  A run reads in arcade.py's points whatever the glass: the
# factory tables and the rung targets are as far off as they ever were, and a
# coin is still AR_GPAYOUT of them.  The round's own board is the one asked.
typeset -gF AR_PTSM=1.0                 # this round's points for each of the machine's own
ar_rate_ratio() {   # ar_rate_ratio GI [W H] → RF how fast the machine scores on that board, over arcade.py's
  local -i gi=$1 w=${2:-$AR_RW} h=${3:-$AR_RH}; local -F a la l1 l2 lr r1 r2
  (( w > 0 && h > 0 )) || { w=$AR_W; h=$AR_H; }
  a=$(( (w * h) / (AR_OW * AR_OH * 1.0) )); (( a < 1.0 )) && a=1.0
  r1=${AR_GPR1[$gi]:-1.0}; r2=${AR_GPR2[$gi]:-1.0}
  la=$(( log(a) )); l1=$(( log(AR_PA1) )); l2=$(( log(AR_PA2) ))
  if (( la <= l1 )); then lr=$(( log(r1) * la / l1 ))
  elif (( la <= l2 )); then lr=$(( log(r1) + (log(r2) - log(r1)) * (la - l1) / (l2 - l1) ))
  else lr=$(( log(r2) )); fi
  RF=$(( exp(lr) )); return 0 }
ar_pts_set() { ar_rate_ratio $AR_GI; AR_PTSM=$(( 1.0 / (RF > 0.01 ? RF : 0.01) )); return 0 }   # at the deal
ar_shown() { REPLY=$(( int($1 * AR_PTSM + 0.5) )); return 0 }   # ar_shown POINTS → REPLY what the board credits for them
ar_paydiv() { REPLY=${AR_GPAYOUT[$1]:-1}; (( REPLY < 1 )) && REPLY=1; return 0 }   # ar_paydiv GI → REPLY points to the coin
ar_payout_for() {   # ar_payout_for GI SCORE RANK DI → AR_PL/AR_PN, AR_PSUB, AR_PTOT
  local -i gi=$1 sc=$2 rank=$3 di=$4 base earned=0 pct style
  AR_PL=(); AR_PN=(); AR_PSUB=0; AR_PTOT=0
  (( ${AR_CF[freeplay]:-0} )) && return 0            # free play costs nothing and pays nothing
  ar_paydiv $gi; base=$(( sc / REPLY ))
  (( base )) && { AR_PL+=('BASE PAYOUT'); AR_PN+=($base); earned=$(( earned + base )); }
  if (( rank == 0 )); then AR_PL+=('NEW RECORD'); AR_PN+=($AR_BONUS_RECORD); earned=$(( earned + AR_BONUS_RECORD ))
  elif (( rank > 0 && rank < 5 )); then AR_PL+=('TOP 5 FINISH'); AR_PN+=($AR_BONUS_TOP5); earned=$(( earned + AR_BONUS_TOP5 )); fi
  # WHAT HE HAS ON · a percent of what the round earned, at least a coin of it
  ar_style_pct; pct=$REPLY
  if (( pct && earned )); then
    style=$(( int(earned * pct / 100.0) )); (( style < 1 )) && style=1
    AR_PL+=("STYLE +${pct}%"); AR_PN+=($style); earned=$(( earned + style ))
  fi
  AR_PSUB=$earned
  AR_PTOT=$(( int(earned * AR_DM[$di]) ))
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SECTION 6 · THE VIEWS         what is on the CRT, and the clock behind it
# ══════════════════════════════════════════════════════════════════════════
typeset -g  AR_VIEW='menu'          # menu · diff · play · ranked · payout · scores · soon
typeset -gF AR_T=0.0 AR_DT=0.016 AR_LAST=-1.0 AR_VIEW_T0=0.0
typeset -gF AR_FPS=0.0              # frames a second, as they actually arrive · the settings and the self test read it
typeset -gF AR_FLASH=0.0            # >0 · the marquee is popping (a coin, a record, a big moment)
typeset -gi AR_SEL=4 AR_SCROLL=0    # the menu cursor · 0..3 system, 4..15 the twelve, 16 the way out
typeset -gi AR_GI=0 AR_DI=1 AR_PLAYERS=1 AR_DSEL=1
typeset -g  AR_NOTE=''; typeset -gF AR_NOTE_T=-99.0
typeset -gF AR_DAILY_NOTE=-99.0 AR_BROKE_NOTE=-99.0
typeset -ga AR_ROOMS; AR_ROOMS=(market badges ledger scores options)
typeset -gi AR_NOPEN=0              # how many of the twelve are playable · for the header

ar_go() {   # ar_go VIEW — turn the page, remembering when
  AR_VIEW="$1"; AR_VIEW_T0=$AR_T; AR_NOTE=''
  return 0 }
ar_note() { AR_NOTE="$1"; AR_NOTE_T=$AR_T; return 0 }
ar_flash() { AR_FLASH=${1:-1.0}; return 0 }   # arcade.py's ctx.flash() · the bezel's lamps go hot for a second

# ── the four accents, resolved once the door's palette is up ─────────────
typeset -gi AR_LO=0 AR_LOP=0            # the dimmest readable ink · on the glass, and on a lit panel
ar_palette() {
  AR_DC=($LIME $CYAN $AMBER $RED)
  # THE ORIGINAL'S shade(DIM, 1.3) CAPTIONS READ AT 2:1 ON THIS GLASS, and the
  # house holds every word to ~3:1 -- the same floor the adoption centre's ink
  # ramp keeps.  So the arcade's asides come off two inks measured for it: one
  # for the glass, one lifted for the violet panels the rooms are boxed in.
  cshade $GREY 0.78; AR_LO=$CS
  cmix $GREY $WHITE 0.40; AR_LOP=$CM
  local -i c
  _pack 148 208 255; c=$PK
  AR_GACC=($LIME $CYAN $c $MAGENTA $PURPLE $AMBER $RED $PINK $CYAN $AMBER $BLUE $MAGENTA)
  AR_SACC=($LIME $AMBER $MAGENTA $CYAN $RED)
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 7 · THE MENU          twelve rows and five, a panel, and a line to say things
# ══════════════════════════════════════════════════════════════════════════
# THE SPLIT EVERY ROOM SHARES · a list on the left, a panel on the right, cut
# where arcade.py cut its 72 columns (41 | 31) and scaled to the CRT in hand.
typeset -gi AR_LIST_W=59 AR_MENU_ROWS=21
ar_list_geom() {
  AR_LIST_W=$(( AR_W * 41 / 72 )); (( AR_LIST_W < 41 )) && AR_LIST_W=41
  AR_MENU_ROWS=$(( AR_H - 5 )); (( AR_MENU_ROWS < 13 )) && AR_MENU_ROWS=13
  return 0 }
typeset -gA AR_SWEEP                    # the selected row's gradient, mixed once per accent and phase
ar_items_n() { REPLY=$(( AR_NG + ${#AR_SID[@]} )); return 0 }
typeset -gi AR_IG=-1 AR_IS=-1
ar_item() {   # ar_item ROW → REPLY g (AR_IG the machine) or s (AR_IS the system row)
  local -i r=$1
  if (( r >= AR_FIRST && r < AR_FIRST + AR_NG )); then REPLY=g; AR_IG=$(( r - AR_FIRST )); AR_IS=-1
  elif (( r < AR_FIRST )); then REPLY=s; AR_IS=$r; AR_IG=-1
  else REPLY=s; AR_IS=$(( r - AR_NG )); AR_IG=-1; fi
  return 0 }

ar_draw_menu() {
  local -F t=$AR_T; local -i hb i idx y sel acc tc sc x n rows=$AR_MENU_ROWS top=2 gi spaced=0 lc di
  local cr s kind lab
  :   # the glass was cleared by ar_draw · the CRT with it
  cmix $GLASS $PURPLE 0.32; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $CYAN 0.15; a_text 2 0 '◤ SELECT YOUR GAME' $CM $hb
  cshade $WHITE 0.85; a_center 0 "◂ $AR_NG ARCADES · $AR_NOPEN UNLOCKED ▸" $CS $hb
  # THE COINS ARE THE HOUSE BAND'S, one row up (ar_head), on every page of the
  # arcade · this band used to count them a second time
  ar_items_n; n=$REPLY
  # THE WHOLE LIST ON ONE PAGE when the glass has the rows for it, with a
  # breath between the house's rows, the twelve, and the way out · a glass
  # too short for that scrolls it the way arcade.py always did
  # …and on a glass with rows to spare, a row of air under every item, the
  # list standing level with the panel beside it rather than hanging from the top
  # …AND THE GROUPS NAMED, the way SYSTEM's list names its TABLES: a rule over
  # the house's rooms and one over the cabinets, a breath before the way out.
  # A row of air under every item is gone: on a tall glass the list stands at
  # the top and two shelves take the rows under it.
  local -i pitch=1 y0=$top hh ruled=0 yb di0 mb mt mf
  AR_MN_PANELS=0
  if (( n + 3 <= rows )); then spaced=1; ruled=1; AR_SCROLL=0
    hh=$(( n + 3 ))
    if (( AR_LIST_W >= 84 && rows - hh >= 10 )); then AR_MN_PANELS=1; y0=$top
    else y0=$(( top + (rows - hh) / 2 )); fi
  elif (( n + 2 <= rows )); then spaced=1; AR_SCROLL=0
    hh=$(( n + 2 )); y0=$(( top + (rows - hh) / 2 ))
  else
    (( AR_SEL < AR_SCROLL )) && AR_SCROLL=$AR_SEL
    (( AR_SEL >= AR_SCROLL + rows )) && AR_SCROLL=$(( AR_SEL - rows + 1 ))
    (( AR_SCROLL > n - rows )) && AR_SCROLL=$(( n - rows )); (( AR_SCROLL < 0 )) && AR_SCROLL=0
  fi
  local -F sweep f
  local -i xx sb k; local mk
  for (( i = 0; i < rows; i++ )); do
    idx=$(( AR_SCROLL + i )); (( idx >= n )) && break
    y=$(( y0 + i * pitch ))
    if (( ruled )); then y=$(( y0 + 1 + idx + (idx >= AR_FIRST) + (idx >= AR_FIRST + AR_NG) ))
    elif (( spaced )); then y=$(( y + (idx >= AR_FIRST) + (idx >= AR_FIRST + AR_NG) )); fi
    sel=$(( idx == AR_SEL ))
    ar_item $idx; kind=$REPLY
    if [[ $kind == g ]]; then gi=$AR_IG; acc=${AR_GACC[$gi]}; else gi=$AR_IS; acc=${AR_SACC[$gi]}; fi
    if (( sel )); then
      ar_wave $t 0.35; sweep=$(( 0.5 + 0.5 * WV )); sb=$(( int(sweep * 7.99) ))
      # the sweep's grounds, a whole row of them kept per accent, phase and width
      mk="m.$acc.$sb.$AR_LIST_W"
      if [[ -z "${AR_SWROW[$mk]:-}" ]]; then
        s=''
        for (( xx = 0; xx < AR_LIST_W; xx++ )); do
          f=$(( 1.0 - xx / (AR_LIST_W + 0.0) )); (( f < 0.0 )) && f=0.0
          cmix $GLASS $acc $(( 0.07 + 0.30 * f * (sb + 0.5) / 8.0 + 0.06 )); s+="$CM "
        done
        (( ${#AR_SWROW[@]} > 256 )) && AR_SWROW=(); AR_SWROW[$mk]="$s"
      fi
      if (( AR_DIRECT )); then       # the row is still the clear's blanks · only its ground changes
        k=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX ))
        GB[$k,$(( k + AR_LIST_W - 1 ))]=(${=AR_SWROW[$mk]})
      else
        local -a swp; swp=(${=AR_SWROW[$mk]})
        for (( xx = 0; xx < AR_LIST_W; xx++ )); do a_put $xx $y ' ' -2 ${swp[$xx]}; done
      fi
      cmix $acc $WHITE 0.45; a_put 0 $y '▌' $CM -2
      cmix $WHITE $acc 0.15; a_text 2 $y '▶' $CM -2
      tc=$WHITE; cmix $WHITE $acc 0.4; sc=$CM
    else
      cshade $GREY 1.05; tc=$CS; sc=$AR_LO
    fi
    # the columns · arcade.py's 4 / 7 / 24 / 32 / 38, given the room a wider list has
    if [[ $kind == s ]]; then
      (( sel )) || { cmix $GLASS $PURPLE 0.13; a_fill 0 $y $AR_LIST_W 1 ' ' -2 $CM; sc=$AR_LOP; }
      cshade $acc $(( sel ? 0.95 : 0.7 )); a_text 4 $y "${AR_SGLYPH[$gi]}" $CS
      a_text 8 $y "${AR_STITLE[$gi][0,17]}" $tc
      # WHAT THE ROOM IS FOR, where every row of the house used to say SYSTEM
      ar_sdesc $gi; a_text 27 $y "${REPLY[0,$(( AR_LIST_W - 29 ))]}" $sc
    else
      ar_pad $(( gi + 1 )) 2; a_text 4 $y "$REPLY" $sc
      a_text 8 $y "${AR_GTITLE[$gi][0,17]}" $tc
      a_text 27 $y "${AR_GGENRE[$gi][0,8]}" $sc
      ar_stars ${AR_GSTARS[$gi]}
      if (( sel )); then cmix $AMBER $WHITE 0.25; a_text 37 $y "$REPLY" $CM; else cshade $AMBER 0.55; a_text 37 $y "$REPLY" $CS; fi
      # THE LIGHT, AND NOW ITS WORD · the one glyph arcade.py had room for, and
      # beside it what it means for this machine: owned, the meter, the price
      if [[ -z "${AR_READY[${AR_GID[$gi]}]:-}" ]]; then cshade $AMBER 0.65; lc=$CS; a_put 45 $y '○' $lc; lab='SOON'
      elif ar_owns $gi; then lc=$LIME; a_put 45 $y '●' $lc; lab='OWNED'
      else ar_rent_left $gi
        if (( REPLY > 0 )); then lc=$CYAN; a_put 45 $y '◐' $lc; ar_dur $REPLY; lab="$REPLY"
        else cshade $AMBER $(( sel ? 0.8 : 0.55 )); lc=$CS; a_put 45 $y '▮' $lc; ar_commify ${AR_GPRICE[$gi]}; lab="$REPLY ◉"; fi
      fi
      if (( sel )); then cmix $lc $WHITE 0.2; else cshade $lc 0.75; fi
      if (( AR_LIST_W >= 84 )); then a_text 47 $y "${lab[0,$(( AR_LIST_W - 74 ))]}" $CS
      else a_text 47 $y "${lab[0,$(( AR_LIST_W - 49 ))]}" $CS; fi
      # THE TABLE'S BEST, at the rung the arcade is set to · where a wide
      # list has the room, so a row says what there is to beat as well as
      # what it costs
      if (( AR_LIST_W >= 84 )); then
        ar_rung_cap $gi; di=${AR_CF[difficulty]:-1}; (( di > REPLY )) && di=$REPLY
        ar_table $gi $di; ar_commify ${AR_TS[0]:-0}; s="$REPLY"
        if (( sel )); then cmix $AMBER $WHITE 0.30; else cshade $AMBER 0.62; fi
        a_text $(( AR_LIST_W - 7 - ${#s} )) $y "$s" $CS      # the score to the right, the initials after it
        ar_short "${AR_TN[0]:-AAA}" 3; a_text $(( AR_LIST_W - 5 )) $y "$REPLY" $CS
        # YOUR BEST AGAINST IT, on SYSTEM's meter: the table's top is the whole
        # bar · a machine you have not played at this rung has a track and no bar
        mb=${AR[best.${AR_GID[$gi]}.${AR_DK[$di]}]:-0}; mt=${AR_TS[0]:-0}; mf=0
        (( mb > 0 && mt > 0 )) && { mf=$(( (mb * 8 + mt / 2) / mt )); (( mf < 1 )) && mf=1; (( mf > 8 )) && mf=8; }
        if (( mf )); then
          a_run $mf '▰'
          if (( sel )); then cmix $acc $WHITE 0.15; else cshade $acc 0.80; fi
          a_text $(( AR_LIST_W - 25 )) $y "$RUN" $CS
        fi
        if (( mf < 8 )); then
          a_run $(( 8 - mf )) '▱'
          if (( sel )); then cshade $GREY 0.62; else cshade $GREY 0.36; fi
          a_text $(( AR_LIST_W - 25 + mf )) $y "$RUN" $CS
        fi
      fi
    fi
  done
  # the coin door creaking open · no label, because a label would give away
  # that there is anything here to find
  ar_hold_len
  if (( RF > 0.4 )); then
    local -F hk=$(( RF / AR_HOLD_NEED )); (( hk > 1.0 )) && hk=1.0
    local -i wide=$(( int(2 + hk * (AR_LIST_W - 11)) )) x0; x0=$(( AR_LIST_W / 2 - wide / 2 )); (( x0 < 0 )) && x0=0
    (( wide > AR_LIST_W - x0 )) && wide=$(( AR_LIST_W - x0 ))
    local bar=''; repeat $wide bar+='▁'
    cmix $AMBER $WHITE $(( 0.10 + 0.55 * hk )); a_text $x0 1 "$bar" $CM
  fi
  if (( ! spaced )); then
    cshade $CYAN 0.9
    (( AR_SCROLL > 0 )) && a_text $(( AR_LIST_W - 3 )) $(( top - 1 )) '▲' $CS
    (( AR_SCROLL + rows < n )) && a_text $(( AR_LIST_W - 3 )) $(( top + rows )) '▼' $CS
  fi
  if (( ruled )); then
    di0=${AR_CF[difficulty]:-1}
    ar_menu_rule $y0 'THE HOUSE'
    ar_menu_rule $(( y0 + 1 + AR_FIRST )) 'THE CABINETS' "AT ${AR_DN[$di0]}"
    # over the meter, whose it is · the table's best is the rule's own word
    (( AR_LIST_W >= 84 )) && { cshade $GREY 0.80; a_text $(( AR_LIST_W - 26 )) $(( y0 + 1 + AR_FIRST )) ' YOURS ' $CS; }
    yb=$(( y0 + hh - 1 ))
    (( AR_MN_PANELS )) && ar_menu_shelves $(( yb + 2 ))
  fi
  cshade $PURPLE 0.55; a_rect $AR_LIST_W 1 1 $(( AR_H - 3 )) '│' $CS
  ar_info_panel
  cshade $PURPLE 0.75; a_hline 0 $(( AR_H - 2 )) $AR_W '─' $CS
  # ── the message line · one thing at a time, the most urgent first ──
  local -i broke=0 bi rc my=$(( AR_H - 1 )); ar_free || (( ${AR[credits]:-0} < AR_PLAY_COST )) && broke=1
  if ar_daily_ready; then
    ar_wave $t 1.0; if (( WV > 0.35 )); then cmix $AMBER $WHITE 0.35; else cshade $AMBER 0.85; CM=$CS; fi
    a_center $my "◆  DAILY TOKEN READY  ·  PRESS [T] FOR $AR_DAILY_COINS FREE COINS  ◆" $CM $GLASS
  elif (( t - AR_DAILY_NOTE < 3.0 )); then
    cshade $GREY 1.05; a_center $my "NO TOKEN TODAY  ·  ONE PER DAY, AND ONLY UNDER $AR_DAILY_MIN COINS" $CS $GLASS
  elif (( broke || t - AR_BROKE_NOTE < 3.5 )); then
    ar_wave $t 1.2; if (( WV > 0.35 )); then cmix $RED $WHITE 0.25; else cshade $RED 0.9; CM=$CS; fi
    a_center $my 'OUT OF COINS  ·  WIN THEM BACK, OR RESET THE BANK IN THE SETTINGS [S]' $CM $GLASS
  elif (( t - AR_BWON_T < 6.0 && ${#AR_BWON[@]} )); then
    bi=${AR_BWON[0]}; rc=${AR_RARC[${BW_RAR[$bi]}]:-$GREY}
    if (( BW_COINS[bi] )); then s="+${BW_COINS[$bi]} ◉"; else s='for the wall'; fi
    (( ${#AR_BWON[@]} > 1 )) && s+="  ·  +$(( ${#AR_BWON[@]} - 1 )) more"
    ar_wave $t 1.2; if (( WV > 0.35 )); then cmix $rc $WHITE 0.35; else cshade $rc 0.95; CM=$CS; fi
    a_center $my "✦  ${BW_NAME[$bi]}  ·  $s" $CM $GLASS
  elif (( t - AR_SVC_NOTE < 4.0 )); then
    ar_wave $t 1.2; if (( WV > 0.35 )); then cmix $MAGENTA $WHITE 0.35; else cshade $MAGENTA 0.9; CM=$CS; fi
    a_center $my '◆  NICE TRY  ·  THAT ONE IS NOT WIRED UP ON AN NX-88  ◆' $CM $GLASS
  elif (( t - AR_NOTE_T < 3.0 )) && [[ -n "$AR_NOTE" ]]; then
    cshade $GREY 1.05; a_center $my "$AR_NOTE" $CS $GLASS
  else
    # the ticker tape · the selected row's blurb, running right to left, as
    # many times over as it takes to cross whatever width the glass has
    ar_item $AR_SEL; if [[ $REPLY == g ]]; then s="${AR_GBLURB[$AR_IG]}"; else s="${AR_SBLURB[$AR_IS]}"; fi
    local unit="  ◆  ${s:u}  " tape; local -i off=$(( int(t * 7) % ${#unit} ))
    tape="$unit"; while (( ${#tape} < AR_W + ${#unit} )); do tape+="$unit"; done
    cshade $GREY 1.0; a_text 0 $my "${tape:$off:$AR_W}" $CS $GLASS
  fi
  return 0
}

typeset -g  AR_PNL_KEY='' AR_PNL_WANT=''
typeset -gi AR_PNL_X=0 AR_PNL_W=0 AR_PNL_H=0 AR_PNL_SYS=0 AR_PNL_GI=0 AR_PNL_BX=0 AR_PNL_BY=0 AR_PNL_BW=0 AR_PNL_BH=0
ar_info_panel() {
  # THE PANEL HOLDS STILL WHILE THE SCREEN ON IT PLAYS.  Everything on it but
  # the screen is painted once for the machine under the cursor and the save
  # as it stands, kept, and put back every frame after that in a few row
  # moves; only the screen is drawn again.  A rental's clock is part of what
  # it is a picture of, to the minute (to the second in its last hour).
  local key acl=''
  local -i gi
  ar_item $AR_SEL
  if [[ $REPLY == g ]]; then
    gi=$AR_IG
    ar_owns $gi || { ar_rent_left $gi; if (( REPLY < 3600 )); then acl=$REPLY; else acl=$(( REPLY / 60 )); fi; }
  fi
  key="$AR_SEL|$acl|${#AR[@]}|${AR[credits]:-0}|${AR[coins]:-0}|${AR[runs]:-0}|${AR_CF[difficulty]:-1}"
  key+="|$AR_W|$AR_H|$AX|$AY|$AR_LIST_W|$TCOLS|$OX|$OY|$C_SCR|$R_SCR|$PURPLE|$AMBER|$GREY|$BLACK|$WHITE"
  if (( AR_DIRECT )) && [[ "$key" == "$AR_PNL_KEY" ]]; then
    ar_snap put P $AR_PNL_X 1 $AR_PNL_W $AR_PNL_H
    if (( AR_PNL_SYS )); then
      ar_sys_preview $(( AR_PNL_BX + 1 )) $(( AR_PNL_BY + 1 )) $(( AR_PNL_BW - 2 )) $(( AR_PNL_BH - 2 )) "${AR_SGLYPH[$AR_PNL_GI]}" ${AR_SACC[$AR_PNL_GI]}
    else
      ar_preview $AR_PNL_GI $(( AR_PNL_BX + 1 )) $(( AR_PNL_BY + 1 )) $(( AR_PNL_BW - 2 )) $(( AR_PNL_BH - 2 ))
    fi
    return 0
  fi
  AR_PNL_WANT="$key"
  ar_info_panel_paint
  return 0
}
typeset -ga AR_SNP_CH AR_SNP_F AR_SNP_B AR_SNS_CH AR_SNS_F AR_SNS_B
ar_snap() {   # ar_snap take|put P|S X Y W H — a rectangle of the CRT kept, or put back (the whole glass on the terminal only: AR_DIRECT)
  local -i x=$3 y=$4 w=$5 h=$6 r k o
  local -a ch f b
  (( w > 0 && h > 0 )) || return 0
  if [[ $1 == take ]]; then
    for (( r = 0; r < h; r++ )); do
      k=$(( (OY + R_SCR + AY + y + r) * TCOLS + OX + C_SCR + AX + x ))
      ch+=("${(@)GCH[@]:$k:$w}"); f+=("${(@)GF[@]:$k:$w}"); b+=("${(@)GB[@]:$k:$w}")
    done
    if [[ $2 == P ]]; then AR_SNP_CH=("${ch[@]}"); AR_SNP_F=("${f[@]}"); AR_SNP_B=("${b[@]}")
    else                   AR_SNS_CH=("${ch[@]}"); AR_SNS_F=("${f[@]}"); AR_SNS_B=("${b[@]}"); fi
    return 0
  fi
  for (( r = 0; r < h; r++ )); do
    k=$(( (OY + R_SCR + AY + y + r) * TCOLS + OX + C_SCR + AX + x )); o=$(( r * w ))
    if [[ $2 == P ]]; then
      GCH[$k,$(( k + w - 1 ))]=("${(@)AR_SNP_CH[@]:$o:$w}"); GF[$k,$(( k + w - 1 ))]=("${(@)AR_SNP_F[@]:$o:$w}"); GB[$k,$(( k + w - 1 ))]=("${(@)AR_SNP_B[@]:$o:$w}")
    else
      GCH[$k,$(( k + w - 1 ))]=("${(@)AR_SNS_CH[@]:$o:$w}"); GF[$k,$(( k + w - 1 ))]=("${(@)AR_SNS_F[@]:$o:$w}"); GB[$k,$(( k + w - 1 ))]=("${(@)AR_SNS_B[@]:$o:$w}")
    fi
  done
  return 0
}
ar_info_panel_paint() {
  # THE PANEL IS THE SELECTED MACHINE, the way SYSTEM's scope is its
  # processor: black inside, the house's violet round it, the machine's name
  # on its rule and its genre at the other end.  Its screen takes most of it --
  # the machine playing itself, as wide as the panel and as tall as what is
  # under it allows -- and under the screen the table it keeps at the rung the
  # arcade is set to, beside the figures that are yours; on a tall glass, the
  # whole ladder, every rung's best and yours, and the machine in its own words.
  local -F t=$AR_T
  local -i px=$(( AR_LIST_W + 1 )) pw ph inner bx by bw bh ky lead tall=0 gi di acc i y c dk fk lw rx vw sysrow=0 need mb np cap r
  local k val title rt pk
  local -a KL VL KC
  pw=$(( AR_W - px )); ph=$(( AR_H - 3 )); inner=$(( ph - 2 ))
  _pack 10 5 22; dk=$PK
  cshade $PURPLE 0.70; fk=$CS
  a_box $px 1 $pw $ph $fk $BLACK round 1
  ar_item $AR_SEL
  if [[ $REPLY == s ]]; then sysrow=1; gi=$AR_IS; acc=${AR_SACC[$gi]}; title="${AR_STITLE[$gi]}"; rt='THE HOUSE'
  else gi=$AR_IG; acc=${AR_GACC[$gi]}; title="${AR_GTITLE[$gi]}"; rt="${AR_GGENRE[$gi]}"; fi
  a_text $(( px + 2 )) 1 " $title " $AMBER $BLACK
  (( ${#title} + ${#rt} + 10 <= pw )) && { cshade $GREY 0.95; a_text $(( px + pw - ${#rt} - 4 )) 1 " $rt " $CS $BLACK; }
  # HOW TALL THE SCREEN CAN BE · six rows of figures under it always; on a
  # glass with the rows, the ladder (five) and the blurb (three) as well
  bw=$(( pw - 4 )); bx=$(( px + 2 ))
  # (the same for a room of the house as for a machine, so the screen does
  # not jump as the cursor crosses from one to the other)
  need=$(( 1 + 6 ))
  (( inner - 10 >= need + 1 + 5 + 1 + 3 + 12 )) && { tall=1; need=$(( need + 1 + 5 + 1 + 3 )); }
  bh=$(( inner - need )); (( bh > 22 )) && bh=22; (( bh < 6 )) && bh=6
  lead=$(( (inner - bh - need) / 2 )); (( lead < 0 )) && lead=0
  by=$(( 2 + lead ))
  AR_PNL_X=$px; AR_PNL_W=$pw; AR_PNL_H=$ph; AR_PNL_SYS=$sysrow; AR_PNL_GI=$gi
  AR_PNL_BX=$bx; AR_PNL_BY=$by; AR_PNL_BW=$bw; AR_PNL_BH=$bh
  # ── the screen ──
  cshade $GREY 0.40; a_box $bx $by $bw $bh $CS $dk light 1
  # (its picture goes on last, once what holds still has been kept: the kept
  # part is the screen dark, exactly as a fresh paint finds it every frame)
  ky=$(( by + bh + 1 ))
  # ── under it, two columns: the table (or the room's words), and the figures ──
  if (( bw < 50 )); then lw=16; else lw=$(( (bw - 2) / 2 )); (( lw > 26 )) && lw=26; fi
  rx=$(( bx + lw + 2 )); vw=$(( px + pw - 2 - (rx + 9) ))
  if (( sysrow )); then
    ar_wrap "${AR_SBLURB[$gi]:l}" $lw 6
    cshade $GREY 0.95
    for (( i = 0; i < 6; i++ )); do a_text $bx $(( ky + i )) "${AR_WL[$i]:-}" $CS $BLACK; done
    ar_commify ${AR[credits]:-0}; VL=("$REPLY"); KL=(COINS); KC=($AMBER)
    ar_commify ${AR[coins]:-0}; VL+=("$REPLY"); KL+=(EARNED); KC+=($LIME)
    KL+=(ROUNDS); VL+=("${AR[runs]:-0}"); KC+=($WHITE)
    ar_nkeys 'badges.*'; KL+=(TROPHIES); VL+=("$REPLY of ${#BW_ID[@]}"); KC+=($WHITE)
    KL+=(STATUS); VL+=('● OPEN'); KC+=($LIME)
  else
    ar_rung_cap $gi; di=${AR_CF[difficulty]:-1}; (( di > REPLY )) && di=$REPLY
    ar_table $gi $di
    mb=${AR[best.${AR_GID[$gi]}.${AR_DK[$di]}]:-0}
    cshade $AMBER 0.85; a_text $bx $ky "TABLE · ${AR_DN[$di]}" $CS $BLACK
    for (( i = 0; i < 5; i++ )); do
      y=$(( ky + 1 + i ))
      [[ -n "${AR_TS[$i]:-}" ]] || break
      ar_commify ${AR_TS[$i]}; val="$REPLY"
      # YOUR OWN SCORE ON THE TABLE, in the colour of having done it
      if (( mb > 0 && AR_TS[i] == mb )); then c=$LIME; elif (( i == 0 )); then cmix $AMBER $WHITE 0.25; c=$CM; else cshade $GREY 1.0; c=$CS; fi
      cshade $GREY 0.70; a_text $bx $y "$(( i + 1 ))" $CS $BLACK
      ar_short "${AR_TN[$i]:-AAA}" 3; a_text $(( bx + 3 )) $y "$REPLY" $c $BLACK
      a_text $(( bx + lw - ${#val} )) $y "$val" $c $BLACK
    done
    KL=(RUNG); VL=("${AR_DN[$di]} ×${AR_DM[$di]}"); KC=(${AR_DC[$di]})
    if ar_playable $gi; then
      if ar_owns $gi; then VL+=(OWNED); KC+=($LIME)
      else ar_rent_left $gi; ar_dur $REPLY; VL+=("◐ $REPLY"); KC+=($CYAN); fi
    else ar_commify ${AR_GPRICE[$gi]}; VL+=("▮ $REPLY ◉"); cshade $AMBER 0.95; KC+=($CS); fi
    KL+=(ACCESS)
    if (( mb > 0 )); then ar_commify $mb; VL+=("$REPLY"); KC+=($WHITE); else VL+=('—'); cshade $GREY 0.7; KC+=($CS); fi
    KL+=('YOUR BEST')
    np=0
    for pk in ${(M)${(k)AR[@]}:#plays.${AR_GID[$gi]}.*}; do np=$(( np + ${AR[$pk]:-0} )); done
    KL+=(PLAYED); VL+=("$np"); KC+=($WHITE)
    if [[ -n "${AR_READY[${AR_GID[$gi]}]:-}" ]]; then VL+=('● ONLINE'); KC+=($LIME)
    else VL+=('○ COMING SOON'); cshade $AMBER 0.95; KC+=($CS); fi
    KL+=(STATUS)
  fi
  for (( i = 0; i < 5; i++ )); do
    y=$(( ky + 1 + i )); (( sysrow )) && y=$(( ky + i ))
    a_text $rx $y "${KL[$i]}" $AR_LOP $BLACK
    a_text $(( rx + 10 )) $y "${VL[$i][0,$(( vw - 2 ))]}" ${KC[$i]} $BLACK
  done
  # ── the ladder · every rung, the table's best and yours ──
  y=$(( ky + 7 ))
  if (( tall )); then
  if (( ! sysrow )); then
    ar_rung_cap $gi; cap=$REPLY
    cshade $AMBER 0.85; a_text $bx $y 'THE LADDER' $CS $BLACK
    cshade $GREY 0.70; a_text $(( bx + 12 )) $y 'THE TABLE' $CS $BLACK; a_text $(( bx + lw + 2 )) $y 'YOURS' $CS $BLACK
    a_text $(( px + pw - 9 )) $y 'PLAYED' $CS $BLACK
    for (( r = 0; r < 4; r++ )); do
      y=$(( ky + 8 + r ))
      if (( r <= cap )); then c=${AR_DC[$r]}; else cshade ${AR_DC[$r]} 0.45; c=$CS; fi
      a_text $bx $y "${AR_DN[$r]}" $c $BLACK
      ar_table $gi $r; ar_commify ${AR_TS[0]:-0}; val="$REPLY"; ar_short "${AR_TN[0]:-AAA}" 3
      if (( r <= cap )); then cshade $GREY 1.0; else cshade $GREY 0.55; fi
      a_text $(( bx + 12 )) $y "$val $REPLY" $CS $BLACK
      mb=${AR[best.${AR_GID[$gi]}.${AR_DK[$r]}]:-0}
      if (( r > cap )); then cshade $GREY 0.55; a_text $(( bx + lw + 2 )) $y 'locked' $CS $BLACK
      elif (( mb > 0 )); then ar_commify $mb; a_text $(( bx + lw + 2 )) $y "$REPLY" $WHITE $BLACK
      else cshade $GREY 0.62; a_text $(( bx + lw + 2 )) $y '—' $CS $BLACK; fi
      val="${AR[plays.${AR_GID[$gi]}.${AR_DK[$r]}]:-0}"
      if (( val )); then c=$WHITE; else cshade $GREY 0.62; c=$CS; fi
      a_text $(( px + pw - 3 - ${#val} )) $y "$val" $c $BLACK
    done
    y=$(( ky + 13 ))
  fi
  # ── the machine in its own words ──
  if (( sysrow )); then val=''; else val="${AR_GBLURB[$gi]}"; fi
  if [[ -n "$val" ]]; then
    ar_wrap "${val:l}" $(( pw - 4 )) 3
    cshade $GREY 0.95
    for (( i = 0; i < 3; i++ )); do a_text $bx $(( y + 1 + i )) "${AR_WL[$i]:-}" $CS $BLACK; done
  fi
  fi
  # ── kept, and then the screen ──
  if (( AR_DIRECT )); then ar_snap take P $px 1 $pw $ph; AR_PNL_KEY="$AR_PNL_WANT"; else AR_PNL_KEY=''; fi
  if (( sysrow )); then ar_sys_preview $(( bx + 1 )) $(( by + 1 )) $(( bw - 2 )) $(( bh - 2 )) "${AR_SGLYPH[$gi]}" $acc
  else ar_preview $gi $(( bx + 1 )) $(( by + 1 )) $(( bw - 2 )) $(( bh - 2 )); fi
  return 0
}
ar_sdesc() {   # ar_sdesc I -> REPLY · what a room of the house is for, in a few words, for its row
  case "${AR_SID[$1]}" in
    market) REPLY='buy · rent · wear' ;;
    scores) REPLY='every table, every rung' ;;
    badges) ar_nkeys 'badges.*'; REPLY="$REPLY of ${#BW_ID[@]} on the wall" ;;
    ledger) REPLY='every coin, added up' ;;
    menu)   REPLY='back to the door' ;;
    *)      REPLY='' ;;
  esac
  return 0
}
ar_menu_rule() {   # ar_menu_rule Y LABEL [RIGHT] — a group's rule across the list, SYSTEM's TABLES rule
  local -i y=$1
  cshade $PURPLE 0.50; a_hline 0 $y $AR_LIST_W '─' $CS
  cshade $AMBER 0.85; a_text 2 $y " $2 " $CS
  # the right-hand word ends where the table's initials do
  [[ -n "${3:-}" ]] && { cshade $GREY 0.80; a_text $(( AR_LIST_W - ${#3} - 3 )) $y " $3 " $CS; }
  return 0
}
typeset -gi AR_MN_PANELS=0
# ── the shelves under the list, on a tall glass ───────────────────────────
# THE BANK and THE TROPHY WALL, in frames like the panel's.  What is on them
# is worked out once per change to the save (the wall's names are looked up
# in a table of a hundred and ninety) and drawn every frame from the result.
typeset -g  AR_SH_KEY=''
typeset -ga AR_SHB_L AR_SHB_V AR_SHG_N AR_SHG_P AR_SHG_C AR_SHW_N AR_SHW_T AR_SHW_C
ar_menu_shelf_data() {
  local key="${AR[credits]:-0}|${AR[coins]:-0}|${AR[runs]:-0}|${AR[dailies]:-0}|${AR[visits]:-0}"
  local -i i j n p
  local k id
  local -a ks srt
  ar_nkeys 'badges.*'; key+="|$REPLY"; ar_nkeys 'plays.*'; key+="|$REPLY"
  [[ "$key" == "$AR_SH_KEY" ]] && return 0
  AR_SH_KEY="$key"
  ar_commify ${AR[credits]:-0}; AR_SHB_L=('coins in the bank'); AR_SHB_V=("$REPLY")
  ar_commify ${AR[coins]:-0};   AR_SHB_L+=('earned, all time'); AR_SHB_V+=("$REPLY")
  AR_SHB_L+=('rounds played');   AR_SHB_V+=("${AR[runs]:-0}")
  AR_SHB_L+=('daily tokens');    AR_SHB_V+=("${AR[dailies]:-0}")
  AR_SHB_L+=('visits');          AR_SHB_V+=("${AR[visits]:-0}")
  # THE ROUNDS EACH MACHINE HAS HAD, most first, and the ones it has not had
  # after them in the lineup's order
  AR_SHG_N=(); AR_SHG_P=(); AR_SHG_C=(); srt=()
  for (( i = 0; i < AR_NG; i++ )); do
    p=0; for k in ${(M)${(k)AR[@]}:#plays.${AR_GID[$i]}.*}; do p=$(( p + ${AR[$k]:-0} )); done
    srt+=("$(( 100000 + p ))|$(( 100 - i ))")
  done
  for k in "${(@O)srt[@]}"; do
    i=$(( 100 - ${k#*|} )); p=$(( ${k%%|*} - 100000 ))
    AR_SHG_N+=("${AR_GTITLE[$i]}"); AR_SHG_P+=($p); AR_SHG_C+=(${AR_GACC[$i]})
  done
  # THE WALL, the newest first · a badge's key holds the moment it was won
  AR_SHW_N=(); AR_SHW_T=(); AR_SHW_C=(); srt=()
  for k in ${(M)${(k)AR[@]}:#badges.*}; do
    [[ "${AR[$k]}" == <-> ]] || continue
    srt+=("${(l:12::0:)AR[$k]}|${k#badges.}")
  done
  for k in "${(@O)srt[@]}"; do
    id="${k#*|}"
    for (( j = 0; j < ${#BW_ID[@]}; j++ )); do [[ "${BW_ID[$j]}" == "$id" ]] && break; done
    (( j < ${#BW_ID[@]} )) || continue
    AR_SHW_N+=("${BW_NAME[$j]}"); AR_SHW_T+=($(( 10#${k%%|*} ))); AR_SHW_C+=(${AR_RARC[${BW_RAR[$j]}]:-$GREY})
  done
  return 0
}
ar_ago() {   # ar_ago EPOCH -> REPLY · how long ago, in the largest unit that reads
  local -i d=$(( ${EPOCHSECONDS:-0} - $1 ))
  (( d < 0 )) && d=0
  if   (( d < 3600 ));   then REPLY="$(( d / 60 ))m ago"
  elif (( d < 86400 ));  then REPLY="$(( d / 3600 ))h ago"
  elif (( d < 86400 * 60 )); then REPLY="$(( d / 86400 ))d ago"
  else REPLY="$(( d / (86400 * 30) ))mo ago"; fi
  return 0
}
typeset -g AR_SHS_KEY=''
ar_menu_shelves() {   # ar_menu_shelves Y — the two shelves from row Y down to the panel's foot · painted once, put back after
  local -i y0=$1 h
  local key
  h=$(( AR_H - 2 - y0 )); (( h >= 5 )) || return 0
  key="$y0|${#AR[@]}|${AR[credits]:-0}|${AR[coins]:-0}|${AR[runs]:-0}|${AR[dailies]:-0}|${AR[visits]:-0}|$(( ${EPOCHSECONDS:-0} / 60 ))"
  key+="|$AR_W|$AR_H|$AX|$AY|$AR_LIST_W|$TCOLS|$OX|$OY|$C_SCR|$R_SCR|$PURPLE|$AMBER|$GREY|$BLACK|$WHITE"
  if (( AR_DIRECT )) && [[ "$key" == "$AR_SHS_KEY" ]]; then ar_snap put S 1 $y0 $(( AR_LIST_W - 2 )) $h; return 0; fi
  ar_menu_shelves_paint $y0
  if (( AR_DIRECT )); then ar_snap take S 1 $y0 $(( AR_LIST_W - 2 )) $h; AR_SHS_KEY="$key"
  else AR_SHS_KEY=''; fi
  return 0
}
ar_menu_shelves_paint() {   # ar_menu_shelves_paint Y
  local -i y0=$1 h w1 w2 x1 x2 i n y rows fk mx f c tot
  local s
  h=$(( AR_H - 2 - y0 )); (( h >= 5 )) || return 0
  w1=$(( (AR_LIST_W - 3) / 2 )); w2=$(( AR_LIST_W - 3 - w1 ))
  x1=1; x2=$(( 1 + w1 + 1 ))
  ar_menu_shelf_data
  cshade $PURPLE 0.70; fk=$CS
  # ── THE BANK ──
  a_box $x1 $y0 $w1 $h $fk $BLACK round 1
  a_text $(( x1 + 2 )) $y0 ' THE BANK ' $AMBER $BLACK
  ar_commify ${AR[credits]:-0}; s=" $REPLY COINS "; cshade $GREY 0.95; a_text $(( x1 + w1 - 2 - ${#s} )) $y0 "$s" $CS $BLACK
  rows=$(( h - 2 ))
  for (( i = 0; i < ${#AR_SHB_L[@]} && i < rows; i++ )); do
    y=$(( y0 + 1 + i ))
    a_text $(( x1 + 2 )) $y "${AR_SHB_L[$i]}" $AR_LOP $BLACK
    case $i in 0) c=$AMBER ;; 1) c=$LIME ;; *) c=$WHITE ;; esac
    a_text $(( x1 + w1 - 3 - ${#AR_SHB_V[$i]} )) $y "${AR_SHB_V[$i]}" $c $BLACK
  done
  # the rounds each machine has had, under a rule, as many as there are rows for
  y=$(( y0 + 1 + ${#AR_SHB_L[@]} + 1 ))
  if (( y + 1 < y0 + h - 1 )); then
    cshade $PURPLE 0.45; a_hline $(( x1 + 1 )) $(( y - 1 )) $(( w1 - 2 )) '─' $CS
    cshade $AMBER 0.85; a_text $(( x1 + 2 )) $(( y - 1 )) ' PLAYED MOST ' $CS $BLACK
    n=${#AR_SHG_N[@]}
    if (( ! n )); then
      cshade $GREY 0.75; a_text $(( x1 + 2 )) $y 'no machines yet' $CS $BLACK
    else
      mx=${AR_SHG_P[0]}; (( mx < 1 )) && mx=1
      for (( i = 0; i < n && y + i < y0 + h - 1; i++ )); do
        if (( AR_SHG_P[i] )); then
          a_text $(( x1 + 2 )) $(( y + i )) "${AR_SHG_N[$i][0,13]}" $GREY $BLACK
          f=$(( (AR_SHG_P[i] * (w1 - 26) + mx - 1) / mx )); (( f < 1 )) && f=1
          a_run $f '━'; a_text $(( x1 + 17 )) $(( y + i )) "$RUN" ${AR_SHG_C[$i]} $BLACK
          s="${AR_SHG_P[$i]}"; a_text $(( x1 + w1 - 3 - ${#s} )) $(( y + i )) "$s" $WHITE $BLACK
        else
          cshade $GREY 0.55; a_text $(( x1 + 2 )) $(( y + i )) "${AR_SHG_N[$i][0,13]}" $CS $BLACK
          cshade $GREY 0.22; a_run $(( w1 - 26 )) '─'; a_text $(( x1 + 17 )) $(( y + i )) "$RUN" $CS $BLACK
          cshade $GREY 0.55; a_text $(( x1 + w1 - 4 )) $(( y + i )) '0' $CS $BLACK
        fi
      done
    fi
  fi
  # ── THE TROPHY WALL ──
  a_box $x2 $y0 $w2 $h $fk $BLACK round 1
  a_text $(( x2 + 2 )) $y0 ' THE TROPHY WALL ' $AMBER $BLACK
  n=${#AR_SHW_N[@]}; tot=${#BW_ID[@]}
  s=" $n OF $tot "; cshade $GREY 0.95; a_text $(( x2 + w2 - 2 - ${#s} )) $y0 "$s" $CS $BLACK
  # how far along the wall, the house's own heavy line
  f=$(( tot ? (n * (w2 - 10) * 2 + tot / 2) / tot : 0 )); (( n && f < 1 )) && f=1
  cshade $GREY 0.24; a_run $(( w2 - 10 )) '─'; a_text $(( x2 + 2 )) $(( y0 + 1 )) "$RUN" $CS $BLACK
  (( f / 2 )) && { a_run $(( f / 2 )) '━'; a_text $(( x2 + 2 )) $(( y0 + 1 )) "$RUN" $AMBER $BLACK; }
  (( f % 2 )) && a_put $(( x2 + 2 + f / 2 )) $(( y0 + 1 )) '╸' $AMBER $BLACK
  s="$(( tot ? n * 100 / tot : 0 ))%"; a_text $(( x2 + w2 - 3 - ${#s} )) $(( y0 + 1 )) "$s" $AMBER $BLACK
  if (( ! n )); then
    cshade $GREY 0.75; a_text $(( x2 + 2 )) $(( y0 + 3 )) 'nothing on the wall yet' $CS $BLACK
  else
    for (( i = 0; i < n && y0 + 3 + i < y0 + h - 1; i++ )); do
      y=$(( y0 + 3 + i ))
      a_put $(( x2 + 2 )) $y '✦' ${AR_SHW_C[$i]} $BLACK
      a_text $(( x2 + 4 )) $y "${AR_SHW_N[$i][0,$(( w2 - 18 ))]}" ${AR_SHW_C[$i]} $BLACK
      ar_ago ${AR_SHW_T[$i]}; cshade $GREY 0.75
      a_text $(( x2 + w2 - 3 - ${#REPLY} )) $y "$REPLY" $CS $BLACK
    done
  fi
  return 0
}
ar_sys_preview() {   # ar_sys_preview X Y W H GLYPH ACCENT — rings, and the glyph in the middle
  local -i x=$1 y=$2 w=$3 h=$4 acc=$6 dk cx cy r a ax ay step
  local -F k rad reach
  _pack 10 5 22; dk=$PK
  a_fill $x $y $w $h ' ' -2 $dk
  cx=$(( x + w / 2 )); cy=$(( y + h / 2 ))
  # the rings reach as far as the box does · arcade.py's eight cells on its 24, a third of any width
  reach=$(( w / 3.0 )); (( reach < 8.0 )) && reach=8.0
  step=$(( int(15 * 24 / (w > 24 ? w : 24)) )); (( step < 6 )) && step=6
  for (( r = 0; r < 3; r++ )); do
    k=$(( AR_T * 0.6 + r / 3.0 )); k=$(( k - floor(k) )); rad=$(( 1 + k * reach ))
    cshade $acc $(( (1.0 - k) * 0.9 ))
    for (( a = 0; a < 360; a += step )); do
      ax=$(( int(cx + cos(a * TAU / 360.0) * rad) )); ay=$(( int(cy + sin(a * TAU / 360.0) * rad * 0.45) ))
      (( ax >= x && ax < x + w && ay >= y && ay < y + h )) && a_put $ax $ay '·' $CS -2
    done
  done
  cmix $acc $WHITE 0.4; local -i fg=$CM; cmix $dk $acc 0.2; a_put $cx $cy "$5" $fg $CM
  return 0 }

# ── the previews · one animated picture a machine, 24 × 6 ────────────────
typeset -gi AR_PVBG=0
ar_preview() {   # ar_preview GI X Y W H
  (( AR_PVBG )) || { _pack 12 6 26; AR_PVBG=$PK; }   # arcade.py PV_BG
  a_fill $2 $3 $4 $5 ' ' -2 $AR_PVBG
  local fn="pv_${AR_GID[$1]}"
  if (( ${+functions[$fn]} )); then $fn $2 $3 $4 $5; else ar_sys_preview $2 $3 $4 $5 '○' ${AR_GACC[$1]}; fi
  return 0 }
# ── the menu's keys ──────────────────────────────────────────────────────
# THE PAGES TURN WITH ◂ ▸, on every surface in the suite alike · this
# cabinet's pages are its rooms, in the order the panel prints them, and the
# walk remembers where it was, so ▸ ⎋ ▸ keeps going round.  The old code is
# fed one key at a time, and the letters it is building are swallowed so B
# cannot open the shop halfway through it.
typeset -gi AR_ROOM=-1
ar_menu_key() {   # → 0 handled · 1 the door's
  local k="$1"; local -i n
  if ar_attract_on; then AR_IDLE_T=$AR_T; return 0; fi          # the first key only wakes the arcade
  AR_IDLE_T=$AR_T
  if [[ "$k" == '\' ]]; then ar_hold_feed; return 0; fi
  ar_hold_len; (( RF > 0.0 )) && return 0                       # the coin door is creaking · nothing else while it does
  ar_konami_key "$k"
  if [[ "$REPLY" == hit ]]; then AR_SVC_NOTE=$AR_T; AR_KONAMI=1; ar_badges_check; ar_snd error; return 0; fi
  if [[ "$REPLY" == part ]]; then
    [[ "$k" == [A-Za-z] ]] && return 0
    [[ "$k" == left || "$k" == right ]] && (( AR_KONAMI_AT > 4 )) && return 0
  fi
  ar_items_n; n=$REPLY
  case "$k" in
    up)    AR_SEL=$(( (AR_SEL + n - 1) % n )); ar_snd move ;;
    down)  AR_SEL=$(( (AR_SEL + 1) % n )); ar_snd move ;;
    wheelup)   (( AR_SEL > 0 )) && { AR_SEL=$(( AR_SEL - 1 )); ar_snd move; } ;;
    wheeldown) (( AR_SEL < n - 1 )) && { AR_SEL=$(( AR_SEL + 1 )); ar_snd move; } ;;
    pgup)  AR_SEL=0; ar_snd move ;;
    pgdn)  AR_SEL=$(( n - 1 )); ar_snd move ;;
    left)  if (( AR_ROOM < 0 )); then AR_ROOM=4; else AR_ROOM=$(( (AR_ROOM + 4) % 5 )); fi; ar_open_room "${AR_ROOMS[$AR_ROOM]}" ;;
    right) if (( AR_ROOM < 0 )); then AR_ROOM=0; else AR_ROOM=$(( (AR_ROOM + 1) % 5 )); fi; ar_open_room "${AR_ROOMS[$AR_ROOM]}" ;;
    enter|space|' '|1) ar_activate ;;
    t|T)   if ar_daily_ready; then ar_open_daily; else AR_DAILY_NOTE=$AR_T; ar_snd error; fi ;;
    u|U)   ar_mute ;;
    b|B)   AR_ROOM=0; ar_open_room market ;;
    a|A)   AR_ROOM=1; ar_open_room badges ;;
    l|L)   AR_ROOM=2; ar_open_room ledger ;;
    h|H)   AR_ROOM=3; ar_open_room scores ;;
    s|S)   AR_ROOM=4; ar_open_room options ;;
    *)     return 1 ;;              # ⎋ and [M] are the door's · it closes the machine
  esac
  return 0 }
ar_mute() {   # [U] · the house's own switch, the one CONFIG throws
  CFG_SOUND=$(( 1 - ${CFG_SOUND:-1} )); (( ${+functions[cfg_save]} )) && cfg_save
  if (( CFG_SOUND )); then ar_note 'SOUND ON'; ar_snd select; else ar_note 'SOUND OFF'; fi
  return 0 }
ar_open_room() {   # the five rooms off the menu
  case "$1" in
    market)  ar_open_market ;;
    badges)  ar_open_badges ;;
    ledger)  ar_open_ledger ;;
    scores)  ar_item $AR_SEL; if [[ $REPLY == g ]]; then AR_HS_G=$AR_IG; else AR_HS_G=0; fi
             AR_HS_D=${AR_CF[difficulty]:-1}; ar_snd select; ar_go scores ;;
    menu)    ar_snd away; (( ${+functions[mach_close]} )) && mach_close ;;   # the row is [M] said with ⏎ · the door's way out
    options) ar_open_options ;;
  esac
  return 0 }
ar_activate() {
  local -i gi
  ar_item $AR_SEL
  if [[ $REPLY == s ]]; then ar_open_room "${AR_SID[$AR_IS]}"; return 0; fi
  gi=$AR_IG; AR_GI=$gi
  if [[ -z "${AR_READY[${AR_GID[$gi]}]:-}" ]]; then ar_snd select; ar_go soon; return 0; fi
  if ! ar_playable $gi; then ar_snd error; ar_flash 0.5; ar_open_buy $gi menu; return 0; fi
  ar_rung_cap $gi; AR_DSEL=${AR_CF[difficulty]:-1}; (( AR_DSEL > REPLY )) && AR_DSEL=$REPLY
  AR_PLAYERS=1; ar_snd select; ar_go diff
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 7b · THE DIFFICULTY PAGE      ▴▾ choose · ⏎ insert coin
# ══════════════════════════════════════════════════════════════════════════
ar_rung_target() {   # ar_rung_target GI DI → REPLY score needed on the rung below
  local -i gi=$1 di=$2 step; local -F base
  (( di < AR_OPEN_RUNGS || di > 3 )) && { REPLY=0; return 0 }
  base=$(( ${AR_GTOP[$gi]} * AR_DSEED[di-1] * AR_DFRAC[$di] ))
  ar_score_step $(( int(base) )); step=$REPLY
  REPLY=$(( int(base / step + 0.5) * step )); (( REPLY < step )) && REPLY=$step; return 0 }
ar_rung_earned() { local -i gi=$1 di=$2; ar_rung_target $gi $di; local -i tgt=$REPLY
  (( tgt )) || return 1; (( ${AR[best.${AR_GID[$gi]}.${AR_DK[$(( di - 1 ))]}]:-0} >= tgt )) }
ar_rung_note() {   # → REPLY '' open · EARNED · LOCKED
  ar_rung_cap $1; (( $2 <= REPLY )) && { REPLY=''; return 0 }
  ar_rung_earned $1 $2 && { REPLY=EARNED; return 0 }; REPLY=LOCKED; return 0 }
ar_open_rung() { ar_rung_cap $1; (( $2 > REPLY )) || return 1; AR[unlocked.${AR_GID[$1]}]=$2; AR_DIRTY=1; return 0 }
ar_try_unlock() {   # → 0 open · 1 with REPLY the reason it is not
  local -i gi=$1 di=$2 cap; ar_rung_cap $gi; cap=$REPLY
  (( di <= cap )) && return 0
  (( di > cap + 1 )) && { REPLY="CLEAR ${AR_DN[$(( cap + 1 ))]} FIRST"; return 1 }
  if ar_rung_earned $gi $di; then ar_open_rung $gi $di; ar_snd start; return 0; fi
  ar_rung_target $gi $di; ar_commify $REPLY
  if (( ${AR[credits]:-0} < AR_DCOST[$di] )); then REPLY="NEED ${AR_DCOST[$di]} COINS, OR $REPLY ON ${AR_DN[$(( di - 1 ))]}"; return 1; fi
  # THE PURCHASE ASKS FIRST · a gate is stage 3's; until then the coins are
  # spent on ⏎ and the note says what just happened
  ar_spend ${AR_DCOST[$di]}; ar_open_rung $gi $di; ar_snd coin; ar_save_write
  return 0 }

# THE RUNGS, ON ANY GLASS · arcade.py stacked its four rungs three rows apart
# from row 4 and wrote its notes on rows 16 and 17.  Here the rungs are a block
# no wider than 96, centred, four rows apart once there is room, the notes sit
# on the CRT's last two rows, and a glass tall enough to spare the rows shows
# the machine itself above the rungs, in the same box the menu's panel uses.
typeset -ga AR_DFB0 AR_DFB1; typeset -g AR_DFAT=''
ar_diff_band() {   # ar_diff_band ACC W → AR_DFB0 AR_DFB1 · the hot rung's two rows of glow, mixed once a colour and width
  [[ "$AR_DFAT" == "$1:$2:$GLASS" ]] && return 0
  local -i xx acc=$1 w=$2; local -F f
  AR_DFB0=(); AR_DFB1=()
  for (( xx = 0; xx < w; xx++ )); do
    f=$(( xx + 0.5 - w / 2.0 )); (( f < 0.0 )) && f=$(( -f )); f=$(( 1.0 - f / (w / 2.0 + 3.0) ))
    cmix $GLASS $acc $(( 0.06 + 0.22 * f )); AR_DFB0+=($CM)
    cmix $GLASS $acc $(( 0.03 + 0.10 * f )); AR_DFB1+=($CM)
  done
  AR_DFAT="$1:$2:$GLASS"; return 0 }
ar_draw_diff() {
  local -F t=$AR_T f frac; local -i gi=$AR_GI hb i y hot xx acc open_now w n x0 tgt
  local -i rx rw p blk top bot avail pvh pvw pvx pvy ry0 bn k dk
  local state sub bst pips mult rt
  :   # the glass was cleared by ar_draw · the CRT with it
  cmix $GLASS ${AR_GACC[$gi]} 0.24; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE ${AR_GACC[$gi]} 0.2; a_text 2 0 "◤ ${AR_GTITLE[$gi]}" $CM $hb
  if ar_free; then rt='FREE PLAY'; else ar_pad ${AR[credits]:-0} 4; rt="COINS $REPLY"; fi
  a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $AMBER $hb
  cmix $CYAN $WHITE 0.2; a_center 2 '╴ ╴ ╴   S E L E C T   D I F F I C U L T Y   ╴ ╴ ╴' $CM $GLASS
  rw=$(( AR_W < 96 ? AR_W : 96 )); rx=$(( (AR_W - rw) / 2 ))
  top=4; bot=$(( AR_H - 4 )); avail=$(( bot - top + 1 ))
  if (( avail >= 20 )); then p=4; else p=3; fi
  blk=$(( 3 * p + 2 ))
  pvh=0; (( avail - blk >= 14 )) && { pvh=$(( avail - blk - 3 )); (( pvh > 20 )) && pvh=20; }
  if (( pvh )); then
    pvw=$(( 4 * pvh )); (( pvw > rw - 8 )) && pvw=$(( rw - 8 )); pvx=$(( (AR_W - pvw) / 2 ))
    pvy=$(( top + (avail - pvh - 3 - blk) / 2 )); ry0=$(( pvy + pvh + 3 ))
    _pack 10 5 22; dk=$PK
    cshade $GREY 0.55; a_box $pvx $pvy $pvw $pvh $CS $dk light 1
    ar_preview $gi $(( pvx + 1 )) $(( pvy + 1 )) $(( pvw - 2 )) $(( pvh - 2 ))
  else
    ry0=$(( top + (avail - blk) / 2 ))
  fi
  for (( i = 0; i < 4; i++ )); do
    y=$(( ry0 + i * p )); hot=$(( i == AR_DSEL )); acc=${AR_DC[$i]}
    if (( hot )); then
      bn=$(( rw - 6 )); ar_diff_band $acc $bn
      if (( AR_DIRECT )); then     # the band's cells are still the clear's blanks · only their ground changes
        k=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX + rx + 3 ))
        GB[$k,$(( k + bn - 1 ))]=("${AR_DFB0[@]}"); k=$(( k + TCOLS )); GB[$k,$(( k + bn - 1 ))]=("${AR_DFB1[@]}")
      else
        for (( xx = 0; xx < bn; xx++ )); do a_put $(( rx + 3 + xx )) $y ' ' -2 ${AR_DFB0[$xx]}; a_put $(( rx + 3 + xx )) $(( y + 1 )) ' ' -2 ${AR_DFB1[$xx]}; done
      fi
      cmix $acc $WHITE 0.45; a_put $(( rx + 3 )) $y '▌' $CM -2
      cmix $WHITE $acc 0.2; a_text $(( rx + 5 )) $y '▶' $CM -2
    fi
    ar_rung_note $gi $i; state="$REPLY"
    if [[ -z "$state" || "$state" == EARNED ]]; then open_now=1; else open_now=0; fi
    cshade $AMBER $(( hot ? 0.9 : 0.6 ))
    if (( open_now )); then a_text $(( rx + 6 )) $y ' ' $CS; else a_text $(( rx + 6 )) $y '▮' $CS; fi
    if (( open_now )); then
      if (( hot )); then cmix $acc $WHITE 0.45; a_text $(( rx + 8 )) $y "${AR_DN[$i]}" $CM; else cshade $acc 0.8; a_text $(( rx + 8 )) $y "${AR_DN[$i]}" $CS; fi
    else if (( hot )); then a_text $(( rx + 8 )) $y "${AR_DN[$i]}" $GREY; else a_text $(( rx + 8 )) $y "${AR_DN[$i]}" $AR_LO; fi; fi
    pips=''; for (( xx = 0; xx < 4; xx++ )); do (( xx <= i )) && pips+='◆' || pips+='·'; done
    cshade $acc $(( hot ? 0.95 : 0.5 )); a_text $(( rx + 17 )) $y "$pips" $CS
    mult="COINS ×${AR_DM[$i]}"
    if (( hot )); then cmix $AMBER $WHITE 0.3; a_text $(( rx + 24 )) $y "$mult" $CM; else cshade $AMBER 0.65; a_text $(( rx + 24 )) $y "$mult" $CS; fi
    if (( open_now )); then
      ar_table $gi $i; ar_commify ${AR_TS[0]:-0}; bst="BEST $REPLY  "; ar_short "${AR_TN[0]:-AAA}" 10; bst+="$REPLY"
      if (( hot )); then a_text $(( rx + rw - 6 - ${#bst} )) $y "$bst" $WHITE; else cshade $GREY 0.95; a_text $(( rx + rw - 6 - ${#bst} )) $y "$bst" $CS; fi
    else
      bst="${AR_DCOST[$i]} ◉  TO UNLOCK"
      if (( hot )); then cmix $AMBER $WHITE 0.3; a_text $(( rx + rw - 6 - ${#bst} )) $y "$bst" $CM; else cshade $AMBER 0.65; a_text $(( rx + rw - 6 - ${#bst} )) $y "$bst" $CS; fi
    fi
    if [[ -z "$state" ]]; then sub="${AR_DB[$i]}"
    elif [[ "$state" == EARNED ]]; then sub='you earned this rung -- press ↵ to take it'
    else ar_rung_target $gi $i; ar_commify $REPLY; sub="pay ${AR_DCOST[$i]} coins, or beat $REPLY on ${AR_DN[$(( i - 1 ))]}"; fi
    if (( hot )); then if [[ "$state" == EARNED ]]; then cshade $LIME 1.0; else cshade $GREY 1.05; fi; else CS=$AR_LO; fi
    a_text $(( rx + 8 )) $(( y + 1 )) "${sub[0,$(( rw - 31 ))]}" $CS
    if [[ "$state" == LOCKED ]]; then
      ar_rung_target $gi $i; tgt=$REPLY; (( tgt < 1 )) && tgt=1
      frac=$(( ${AR[best.${AR_GID[$gi]}.${AR_DK[$(( i - 1 ))]}]:-0} / (tgt + 0.0) )); (( frac > 1.0 )) && frac=1.0
      w=10; n=$(( int(frac * w + 0.5) )); x0=$(( rx + rw - 6 - w - 5 ))
      for (( xx = 0; xx < w; xx++ )); do cshade $acc $(( xx < n ? 0.95 : 0.4 )); if (( xx < n )); then a_put $(( x0 + xx )) $(( y + 1 )) '▰' $CS; else a_put $(( x0 + xx )) $(( y + 1 )) '▱' $CS; fi; done
      ar_lpad $(( int(frac * 100) )) 3; if (( hot )); then cmix $acc $WHITE 0.3; a_text $(( x0 + w + 1 )) $(( y + 1 )) "${REPLY}%" $CM; else cshade $acc 0.7; a_text $(( x0 + w + 1 )) $(( y + 1 )) "${REPLY}%" $CS; fi
    fi
  done
  if (( t - AR_NOTE_T < 2.8 )) && [[ -n "$AR_NOTE" ]]; then
    ar_wave $t 1.2; if (( WV > 0.35 )); then cmix $RED $WHITE 0.25; else cshade $RED 0.9; CM=$CS; fi
    a_center $(( AR_H - 2 )) "$AR_NOTE" $CM $GLASS
    a_center $(( AR_H - 1 )) 'harder rungs open with coins, or by out-scoring the rung below' $AR_LO $GLASS
  elif (( ${AR_CF[freeplay]:-0} )); then
    ar_wave $t 0.9; if (( WV > 0.35 )); then cmix $LIME $WHITE 0.3; else cshade $LIME 0.85; CM=$CS; fi
    a_center $(( AR_H - 2 )) '◆ FREE PLAY IS ON -- PLAYS ARE FREE AND EARN NO COINS ◆' $CM $GLASS
    a_center $(( AR_H - 1 )) 'turn it off in the settings to play for coins' $AR_LO $GLASS
  elif [[ "${AR_GPLAYERS[$gi]}" == 1-2P ]]; then
    ar_wave $t 0.9; if (( WV > 0.35 )); then cmix $MAGENTA $WHITE 0.35; else cshade $MAGENTA 0.85; CM=$CS; fi
    a_center $(( AR_H - 2 )) '◆  T W O   U P  ·  [2] PUTS A SECOND PLAYER ON THE OTHER SIDE  ◆' $CM $GLASS
    cshade $GREY 1.0; a_center $(( AR_H - 1 )) 'arrows are one, W A S D is two  ·  two coins  ·  no place on the table' $CS $GLASS
  else
    a_center $(( AR_H - 2 )) "a harder rung pays ${AR_DM[3]}x more coins and keeps its own score table" $AR_LO $GLASS
    cshade $GREY 1.0; a_center $(( AR_H - 1 )) "one play costs $AR_PLAY_COST coin" $CS $GLASS
  fi
  return 0
}
ar_diff_key() {
  local k="$1"; local -i gi=$AR_GI two=0 p
  case "$k" in
    up)   AR_DSEL=$(( (AR_DSEL + 3) % 4 )); ar_snd move ;;
    down) AR_DSEL=$(( (AR_DSEL + 1) % 4 )); ar_snd move ;;
    enter|space|1|2)
      [[ "$k" == 2 ]] && two=1
      if (( two )) && [[ "${AR_GPLAYERS[$gi]}" != 1-2P ]]; then ar_note "${AR_GTITLE[$gi]} TAKES ONE PLAYER"; ar_snd error; return 0; fi
      if ! ar_try_unlock $gi $AR_DSEL; then ar_note "$REPLY"; ar_snd error; return 0; fi
      AR_PLAYERS=$(( two ? 2 : 1 ))
      if (( AR_PLAYERS == 2 )) && ! ar_free && (( ${AR[credits]:-0} < AR_PLAY_COST * 2 )); then
        ar_note "TWO UP TAKES $(( AR_PLAY_COST * 2 )) COINS"; AR_PLAYERS=1; ar_snd error; return 0; fi
      AR_CF[difficulty]=$AR_DSEL; ar_conf_save
      for (( p = 0; p < AR_PLAYERS; p++ )); do
        ar_take_coin || { ar_snd error; AR_BROKE_NOTE=$AR_T; ar_go menu; return 0; }
      done
      ar_snd start; ar_round_open $gi $AR_DSEL $AR_PLAYERS ;;
    esc|q|Q|back) ar_snd move; ar_go menu ;;
    u|U) ar_mute ;;
    *) return 1 ;;
  esac
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 8 · THE ROUND SHELL           READY · PLAY · DIE · OVER, and the harness
# ══════════════════════════════════════════════════════════════════════════
# THE SHELL OWNS THE SCORE; A GAME JUST ADDS TO IT.  A game is five functions
# on a prefix -- sn_begin, sn_update DT, sn_paint T, sn_hud, sn_stats -- and
# a handful of words it sets in begin (its legend, its howto, its accent).
# The original ran each game in its own loop; here the door owns the loop,
# so the same states are a machine the tick advances and the draw reads.
typeset -gi AR_RS=0                 # 0 READY · 1 PLAY · 2 DIE · 3 OVER
typeset -gF AR_RST=0.0 AR_RT=0.0 AR_NOCOIN=-99.0
typeset -gi AR_SCORE=0 AR_LEVEL=1 AR_LIVES=0 AR_ALIVE=1 AR_BOARD=0 AR_ROUNDS=0 AR_BEST=0 AR_PAUSED=0
typeset -gF AR_FRAC=0.0
typeset -g  AR_GP='sn'              # the game in play · its function prefix
typeset -g  AR_G_LEGEND='' AR_G_HOWTO='' AR_G_OVER='GAME OVER' AR_G_READY='' AR_G_HEART='♥'
typeset -gi AR_G_ACC=0 AR_G_TWOUP=0 AR_TWO=0 AR_SVC_MULT=1
typeset -ga AR_KEYS                 # this frame's keys, as names
typeset -ga AR_HL AR_HV AR_HC       # the game's HUD fields · label value colour
typeset -ga AR_SL AR_SV             # the game's stats rows · label value
typeset -gA AR_PREFIX; AR_PREFIX=(snake sn)

ar_add() {   # ar_add POINTS — the fractional bank · a game that scores by the frame
  # …and the board's rate taken out of every point on its way in (AR_PTSM), so
  # a run on any glass reads in arcade.py's points · the bank keeps the crumbs
  local -F p=$1; local -i whole
  AR_FRAC=$(( AR_FRAC + p * AR_SVC_MULT * AR_PTSM )); whole=$(( int(AR_FRAC) ))
  if (( whole )); then AR_FRAC=$(( AR_FRAC - whole )); AR_SCORE=$(( AR_SCORE + whole )); (( AR_SCORE < 0 )) && AR_SCORE=0; (( AR_SCORE > 1073741824 )) && AR_SCORE=1073741824; fi
  return 0 }
ar_pick() {   # ar_pick A B C D → REPLY the one for this rung
  local -i di=$AR_DI; (( di > $# - 1 )) && di=$(( $# - 1 )); REPLY="${@[$di]}"; return 0 }   # KSH_ARRAYS: ${@[0]} is $1
ar_next_board() { if [[ -n "${ALIEN_ARCADE_BOARD:-}" && "${ALIEN_ARCADE_BOARD}" == <-> ]]; then REPLY=${ALIEN_ARCADE_BOARD}
  else ar_entropy; REPLY=$(( AR_BOARD_LO + REPLY % (AR_BOARD_HI - AR_BOARD_LO + 1) )); fi; return 0 }

ar_round_new() {   # a fresh Round · the board dealt, the game begun
  ar_deal_board                     # the size of it, from the glass as it stands at the coin
  ar_pts_set                        # …and what a point of this machine's is worth on it
  ar_next_board; AR_BOARD=$REPLY; rnd_seed $AR_BOARD
  AR_SCORE=0; AR_FRAC=0.0; AR_LEVEL=1; AR_LIVES=0; AR_ALIVE=1; AR_RT=0.0
  AR_G_LEGEND='▲▼◄► MOVE       [P] PAUSE       [Q] CASH OUT'; AR_G_HOWTO=''; AR_G_OVER='GAME OVER'; AR_G_READY=''; AR_G_HEART='♥'
  AR_G_ACC=$CYAN; AR_G_TWOUP=0
  ${AR_GP}_begin
  AR_TWO=$(( AR_G_TWOUP && AR_PLAYERS == 2 ))
  AR_RS=0; AR_RST=0.0; AR_PAUSED=0
  return 0 }
ar_round_open() {   # ar_round_open GI DI PLAYERS — the coin is already in
  AR_GI=$1; AR_DI=$2; AR_PLAYERS=$3
  AR_GP="${AR_PREFIX[${AR_GID[$1]}]:-sn}"
  AR_ROUNDS=0; AR_BEST=0; AR_NOCOIN=-99.0
  ar_svc_round
  ar_round_new
  ar_go play
  return 0 }
ar_round_stats() {   # → AR_SL/AR_SV, the game's rows
  AR_SL=(); AR_SV=()
  (( ${+functions[${AR_GP}_stats]} )) && ${AR_GP}_stats
  return 0 }

# ── the tick ──────────────────────────────────────────────────────────────
ar_round_tick() {
  local -F dt=$AR_DT gdt
  local k; local -i god
  AR_RST=$(( AR_RST + dt ))
  # ------------------------------------------------------------ input
  local -a play; play=()
  for k in "${AR_KEYS[@]}"; do
    if [[ "$k" == P ]] && (( AR_RS == 1 )); then AR_PAUSED=$(( ! AR_PAUSED )); ar_snd move
    elif [[ "$k" == ENTER || "$k" == SPACE ]] && (( AR_RS == 3 )); then
      if ar_take_coin; then AR_ROUNDS=$(( AR_ROUNDS + 1 )); ar_round_new; ar_snd start
      else AR_NOCOIN=$AR_T; ar_snd error; fi
    elif [[ "$k" == ENTER || "$k" == SPACE ]] && (( AR_RS == 0 )); then (( AR_RST < 1.8 )) && AR_RST=1.8
    elif [[ "$k" == Q || "$k" == ESC ]]; then ar_round_leave; return 0     # [M] is a game's own key in play · BRICK NOVA's multiball
    elif [[ "$k" == U ]]; then ar_mute                                      # no machine uses [U] · the switch works in play, as it always did
    elif (( AR_RS == 1 && ! AR_PAUSED )); then play+=("$k"); fi
  done
  AR_KEYS=("${play[@]}")
  # ----------------------------------------------------------- update
  if (( AR_RS == 0 )); then
    (( AR_RST >= 2.0 )) && { AR_RS=1; AR_RST=0.0; ar_snd select; }
  elif (( AR_RS == 1 )); then
    if (( ! AR_PAUSED )); then
      ar_svc time; gdt=$(( dt * AR_SVTIME[REPLY] )); AR_RT=$(( AR_RT + gdt ))
      ar_svc auto; (( REPLY )) && { ar_demo_keys; AR_KEYS+=("${AR_DKEYS[@]}"); }
      ar_svc rewind; (( REPLY && AR_T - AR_SNAP_T > 0.5 )) && { AR_SNAP_T=$AR_T; ar_svc_snap; }
      ${AR_GP}_update $gdt
      if (( ! AR_ALIVE )); then
        ar_svc god; god=$REPLY; ar_svc rewind
        if (( god )); then AR_ALIVE=1; (( AR_LIVES <= 0 )) && AR_LIVES=1      # the operator does not die
        elif (( REPLY )) && [[ -n "$AR_SNAP" ]]; then ar_svc_restore; AR_ALIVE=1; AR_REWOUND=$AR_T; ar_snd select; fi
      fi
      if (( ! AR_ALIVE )); then AR_RS=2; AR_RST=0.0; ar_snd error
      elif (( AR_T - AR_WALL_T > 0.5 )); then
        # THE WALL, LIVE · twice a second, with the round's own numbers as they stand
        AR_WALL_T=$AR_T; ar_round_stats; ar_run_set $AR_GI $AR_DI $AR_SCORE $AR_PLAYERS 99 -1 0; ar_badges_check; ar_run_clear
      fi
    fi
  elif (( AR_RS == 2 )); then
    if (( AR_RST > 1.05 )); then
      AR_RS=3; AR_RST=0.0; (( AR_SCORE > AR_BEST )) && AR_BEST=$AR_SCORE
      ar_high $AR_GI $AR_DI; (( AR_SCORE > 0 && AR_SCORE > REPLY )) && { ar_flash; ar_snd coin; }
    fi
  fi
  return 0 }
ar_round_leave() {   # [Q] · the round is cashed out at its best
  (( AR_SCORE > AR_BEST )) && AR_BEST=$AR_SCORE
  AR_ROUNDS=$(( AR_ROUNDS + 1 ))
  ar_round_stats
  ar_after_round
  return 0 }

# ── the draw ──────────────────────────────────────────────────────────────
ar_round_draw() {
  local -F t=$AR_T left k; local -i bw acc=$AR_G_ACC fg
  local word ban
  :   # the glass was cleared by ar_draw · the CRT with it
  ${AR_GP}_paint $t
  ar_hud_bar
  if (( AR_RIG )); then ar_wave $t 1.1; cmix $AMBER $WHITE $(( 0.25 + 0.25 * WV )); a_text $(( AR_W - 10 )) $AR_FT ' SERVICE ' $BLACK $CM; fi
  (( t - AR_REWOUND < 1.1 )) && { cmix $CYAN $WHITE 0.45; a_center $(( AR_FT + 2 )) '◂ R E W O U N D ▸' $CM -2; }
  ar_svc debug; (( REPLY )) && ar_svc_overlay
  if (( AR_RS == 2 )); then
    k=$(( AR_RST / 1.05 )); (( k > 1.0 )) && k=1.0; k=$(( 1.0 - k ))
    (( int(AR_RST * 11) % 2 == 0 )) && a_tintr 0 $AR_FT $AR_W $AR_FH $RED $(( 0.30 * k + 0.10 ))
  fi
  if (( AR_RS == 0 )); then
    local -i oy=$(( (AR_H - AR_OH) / 2 ))   # the countdown's block, centred on whatever board was dealt
    left=$(( 2.0 - AR_RST ))
    word="$AR_G_READY"
    [[ -n "$word" ]] || { if (( left <= 0.55 )); then word=GO; else word=$(( int(left) + 1 )); fi; }
    big_width "$word"; bw=$BW
    ar_wave $t 2.0; cmix $acc $WHITE $(( 0.3 + 0.35 * WV ))
    a_big "$word" $(( (AR_W - bw) / 2 )) $(( oy + 4 )) $acc $CM
    if (( left > 0.55 )); then if (( AR_TWO )); then ban='T W O   U P'; else ban='G E T   R E A D Y'; fi; else ban='◆ ◆ ◆'; fi
    if (( AR_TWO )); then cmix $MAGENTA $WHITE 0.3; else cmix $CYAN $WHITE 0.3; fi; ar_banner $(( oy + 11 )) "$ban" $CM
    cmix ${AR_DC[$AR_DI]} $WHITE 0.25; ar_banner $(( oy + 12 )) "${AR_DN[$AR_DI]}  ·  pays ×${AR_DM[$AR_DI]}  ·  ${AR_DB[$AR_DI]}" $CM
    (( AR_ROUNDS == 0 )) && [[ -n "$AR_G_HOWTO" ]] && { cshade $GREY 1.1; ar_banner $(( oy + 13 )) "$AR_G_HOWTO" $CS; }
    (( AR_TWO )) && { cmix $MAGENTA $WHITE 0.4; cshade $CM 1.05; ar_banner $(( oy + 14 )) '1P ▲▼◄►        2P W A S D' $CS; }
    ar_pad $AR_BOARD 5; cmix $acc $WHITE 0.30; ar_banner $(( oy + 16 )) "B O A R D   # $REPLY" $CM
  fi
  if (( AR_PAUSED && AR_RS == 1 )); then
    local -i ppx=$(( (AR_W - 32) / 2 )) ppy=$(( AR_FT + (AR_FH - 4) / 2 ))
    cmix $CYAN $WHITE 0.3; fg=$CM; cmix $GLASS $PURPLE 0.38
    a_box $ppx $ppy 32 4 $fg $CM double 1
    a_center $(( ppy + 1 )) 'P A U S E D' $WHITE -2 $ppx 32
    cshade $GREY 1.1; a_center $(( ppy + 2 )) '[P] to resume' $CS -2 $ppx 32
  fi
  (( AR_RS == 3 )) && ar_over_panel
  return 0 }
ar_banner() {   # ar_banner Y TEXT FG — a centred line with its own strip behind it
  [[ -n "$2" ]] || return 0
  local pad=" $2 "; local -i x=$(( (AR_W - ${#pad}) / 2 )); (( x < 0 )) && x=0
  cmix $GLASS $VOID_MIX 0.72
  a_text $x $1 "${pad[0,$(( AR_W - 1 ))]}" $3 $CM; return 0 }
ar_plate() {   # ar_plate X Y TEXT FG BG → REPLY the x past it · a label let INTO a frame
  local s=" $3 "; a_text $1 $2 "$s" $4 ${5:--2}; REPLY=$(( $1 + ${#s} )); return 0 }
ar_hud_bar() {
  local -i hb x lb i best budget; local rung chunk hearts=''
  cmix $GLASS $AR_G_ACC 0.16; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cshade $GREY 1.15; lb=$CS
  a_text 1 0 SCORE $lb $hb; ar_pad $(( AR_SCORE > 9999999 ? 9999999 : AR_SCORE )) 7; a_text 7 0 "$REPLY" $WHITE $hb
  a_text 15 0 BEST $lb $hb; ar_high $AR_GI $AR_DI; best=$REPLY; (( AR_SCORE > best )) && best=$AR_SCORE
  ar_pad $(( best > 9999999 ? 9999999 : best )) 7; a_text 20 0 "$REPLY" $AMBER $hb
  x=28
  if (( AR_LIVES )); then
    for (( i = 0; i < AR_LIVES && i < 5; i++ )); do hearts+="$AR_G_HEART"; done
    cmix $RED $WHITE 0.25; a_text $x 0 "$hearts" $CM $hb; x=$(( x + 6 ))
  else
    a_text $x 0 LVL $lb $hb; ar_pad $(( AR_LEVEL > 99 ? 99 : AR_LEVEL )) 2; cmix $CYAN $WHITE 0.25; a_text $(( x + 4 )) 0 "$REPLY" $CM $hb; x=$(( x + 7 ))
  fi
  rung="${AR_DN[$AR_DI]} ×${AR_DM[$AR_DI]}"
  budget=$(( AR_W - 3 - ${#rung} ))
  AR_HL=(); AR_HV=(); AR_HC=()
  (( ${+functions[${AR_GP}_hud]} )) && ${AR_GP}_hud
  for (( i = 0; i < ${#AR_HL[@]} && i < 2; i++ )); do
    chunk="${AR_HL[$i]} ${AR_HV[$i]}"
    (( x + ${#chunk} > budget )) && break
    a_text $x 0 "${AR_HL[$i]}" $lb $hb; a_text $(( x + ${#AR_HL[$i]} + 1 )) 0 "${AR_HV[$i]}" ${AR_HC[$i]} $hb
    x=$(( x + ${#chunk} + 2 ))
  done
  cmix ${AR_DC[$AR_DI]} $WHITE 0.35; a_text $(( AR_W - 1 - ${#rung} )) 0 "$rung" $CM $hb
  return 0 }
ar_over_panel() {
  local -F t=$AR_T; local -i pw=58 ph=14 px py pbg bw i worth need pay
  local bits='' pl='s'
  px=$(( (AR_W - pw) / 2 )); py=$(( AR_FT + (AR_FH - ph) / 2 )); _pack 14 6 30; pbg=$PK
  cmix $MAGENTA $WHITE 0.25; a_box $px $py $pw $ph $CM $pbg double 1
  big_width "$AR_G_OVER"; bw=$BW
  AR_BCOL=(); for (( i = 0; i < bw; i++ )); do cmix $RED $AMBER $(( 0.25 + 0.5 * (i / (bw > 1 ? bw * 1.0 : 1.0)) )); AR_BCOL[$i]=$CM; done
  ar_big_cols "$AR_G_OVER" $(( px + (pw - bw) / 2 )) $(( py + 1 )) $RED $pbg
  cshade $GREY 1.15; a_text $(( px + 8 )) $(( py + 7 )) SCORE $CS $pbg
  ar_commify $AR_SCORE; a_text $(( px + pw - 8 - ${#REPLY} )) $(( py + 7 )) "$REPLY" $WHITE $pbg
  ar_round_stats
  for (( i = 0; i < ${#AR_SL[@]} && i < 3; i++ )); do [[ -n "$bits" ]] && bits+='      '; bits+="${AR_SL[$i]} ${AR_SV[$i]}"; done
  [[ -n "$bits" ]] && { cshade $GREY 1.1; a_center $(( py + 8 )) "${bits[0,$(( pw - 5 ))]}" $CS $pbg $px $pw; }
  ar_pad $AR_BOARD 5; cshade $GREY 1.0; ar_plate $(( px + pw - 3 - 12 )) $py "BOARD #$REPLY" $CS $pbg
  ar_paydiv $AR_GI; pay=$REPLY
  if ar_free; then worth=0; else worth=$(( int((AR_SCORE / pay) * AR_DM[$AR_DI]) )); fi
  need=$(( int(ceil(pay / AR_DM[$AR_DI])) ))
  (( worth == 1 )) && pl=''
  ar_high $AR_GI $AR_DI
  if ar_free; then cshade $LIME 1.0; a_center $(( py + 9 )) 'free play -- this run earns no coins' $CS $pbg $px $pw
  elif (( AR_SCORE > 0 && AR_SCORE > REPLY )); then ar_wave $t 1.4; (( WV > 0.35 )) && { cmix $AMBER $WHITE 0.4; a_center $(( py + 9 )) '◆ NEW ARCADE RECORD ◆' $CM $pbg $px $pw; }
  elif (( worth <= 0 )); then ar_commify $need; cshade $RED 1.05; a_center $(( py + 9 )) "no payout below $REPLY points on ${AR_DN[$AR_DI]}" $CS $pbg $px $pw
  else cshade $LIME 1.0; a_center $(( py + 9 )) "worth $worth coin$pl on ${AR_DN[$AR_DI]}" $CS $pbg $px $pw; fi
  if (( t - AR_NOCOIN < 2.2 )); then cmix $RED $WHITE 0.25; a_center $(( py + 11 )) 'COIN BANK EMPTY  ·  [Q] TO CASH OUT' $CM $pbg $px $pw
  else ar_wave $t 0.8; (( WV > 0.35 )) && { cmix $LIME $WHITE 0.3; a_center $(( py + 11 )) '[↵] PLAY AGAIN (1 COIN)    [Q] CASH OUT' $CM $pbg $px $pw; }; fi
  return 0 }

# ── the keyboard, raw · a burst of bytes becomes this frame's key list ────
ar_raw() {   # ar_raw want | mouse | feed BYTES
  case "$1" in
    want)  (( ${SURF_TITLE:-0} )) && return 1      # a title card up takes keys, not bytes
           [[ "$AR_VIEW" == play ]]; return $? ;;
    mouse) return 1 ;;
    feed)  ar_parse_keys "$2"; return 0 ;;
  esac
  return 1 }
ar_parse_keys() {   # bytes → AR_KEYS appended · arrows, letters, space, enter, esc
  local s="$1" c; local -i i n=${#1}
  for (( i = 0; i < n; i++ )); do
    c="${s[$i]}"
    case "$c" in
      $'\e')
        if [[ "${s[$(( i + 1 ))]:-}" == '[' || "${s[$(( i + 1 ))]:-}" == 'O' ]]; then
          case "${s[$(( i + 2 ))]:-}" in
            A) AR_KEYS+=(UP); i=$(( i + 2 )) ;; B) AR_KEYS+=(DOWN); i=$(( i + 2 )) ;;
            C) AR_KEYS+=(RIGHT); i=$(( i + 2 )) ;; D) AR_KEYS+=(LEFT); i=$(( i + 2 )) ;;
            [0-9]) i=$(( i + 2 )); while (( i < n )) && [[ "${s[$i]}" == [0-9\;] ]]; do i=$(( i + 1 )); done ;;   # a ~-sequence nobody asked for
            *) AR_KEYS+=(ESC) ;;
          esac
        else AR_KEYS+=(ESC); fi ;;
      $'\r'|$'\n') AR_KEYS+=(ENTER) ;;
      ' ')  AR_KEYS+=(SPACE) ;;
      $'\x7f'|$'\b') AR_KEYS+=(BACK) ;;
      [a-zA-Z0-9]) AR_KEYS+=("${c:u}") ;;
    esac
  done
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 9 · AFTER THE ROUND         ranked · the payout window · back to the floor
# ══════════════════════════════════════════════════════════════════════════
typeset -gi AR_RANK=99 AR_FINAL=0 AR_PAY_START=0 AR_PAY_END=0 AR_PAY_GOT=0 AR_OPENED=-1
typeset -g  AR_PNAME=''
typeset -ga AR_ROMAN; AR_ROMAN=(1ST 2ND 3RD 4TH 5TH)
typeset -gi AR_PAY_CX=26 AR_PAY_CW=46          # the payout window's left gutter is his · set each frame from the tube
typeset -ga AR_CHIMED

# ── A PAGE STANDS IN THE MIDDLE OF WHATEVER TUBE IT IS HANDED ────────────
# ar_vstack TOP BOTTOM GROW  H0 G0 H1 G1 … Hn  → AR_VSY, the top row of each block.
# The blocks are what a page drew on the 18-row tube and the gaps are the rows
# it left between them.  A taller tube shares its spare rows out: every gap
# takes an equal share, up to GROW more (a gap written =N keeps N), and what
# is left over is split above and below, so the page stands centred between
# its band and its footer rather than hanging off the top of the glass.
typeset -ga AR_VSY
ar_vstack() {
  local -i top=$1 bot=$2 grow=$3 n i tot=0 sp add slots=2 y g; shift 3
  local -a hs gs fx
  while (( $# )); do
    hs+=($1); shift
    (( $# )) || break
    if [[ "$1" == =* ]]; then gs+=(${1#=}); fx+=(1); else gs+=($1); fx+=(0); slots=$(( slots + 1 )); fi
    shift
  done
  n=${#hs[@]}
  for (( i = 0; i < n; i++ )); do tot=$(( tot + hs[i] )); done
  for (( i = 0; i < n - 1; i++ )); do tot=$(( tot + gs[i] )); done
  sp=$(( bot - top + 1 - tot )); (( sp < 0 )) && sp=0
  add=$(( sp / slots )); (( add > grow )) && add=$grow
  for (( i = 0; i < n - 1; i++ )); do (( fx[i] )) || sp=$(( sp - add )); done
  y=$(( top + sp / 2 )); AR_VSY=()
  for (( i = 0; i < n; i++ )); do
    AR_VSY+=($y); g=${gs[$i]:-0}; (( ${fx[$i]:-1} )) || g=$(( g + add ))
    y=$(( y + hs[i] + g ))
  done
  return 0 }

ar_player_name() {   # whoever owns this Mac · override with arcade.player in the conf
  ar_scrub "${AR_CF[player]:-}"; [[ -n "$REPLY" ]] && return 0
  ar_scrub "${USER:-${LOGNAME:-}}"; [[ -n "$REPLY" ]] || REPLY=PLAYER; return 0 }

ar_after_round() {   # the coin's worth, worked out and written down
  local -i gi=$AR_GI di=$AR_DI sc=$AR_BEST i rank=99 two=0 nxt rig=0 b4
  (( sc < 0 )) && sc=0
  AR_FINAL=$sc
  (( AR_PLAYERS == 2 )) && two=1
  ar_rigged && rig=1; AR_PAY_RIG=$rig
  ar_player_name; AR_PNAME="$REPLY"
  ar_table $gi $di
  if (( sc > 0 )); then rank=0; for (( i = 0; i < ${#AR_TS[@]}; i++ )); do (( AR_TS[i] >= sc )) && (( rank++ )); done; fi
  (( two || rig )) && rank=99           # rigged, or shared · neither takes a place
  AR_RANK=$rank
  # THE TABLE FIRST, THEN THE MONEY · so the payout can name the finish
  if (( rig || two )); then ar_count_play $gi $di      # the operator was testing it · or two hands played it
  elif (( sc > 0 )); then ar_submit $gi $di "$AR_PNAME" $sc
  else ar_count_play $gi $di; fi
  AR[seen.${AR_GID[$gi]}]=1
  ar_payout_for $gi $sc $rank $di
  (( rig )) && { AR_PL=(); AR_PN=(); AR_PSUB=0; AR_PTOT=0; }
  AR_OPENED=-1; nxt=$(( di + 1 ))
  if (( nxt <= 3 )); then ar_rung_cap $gi; if (( REPLY < nxt )) && ar_rung_earned $gi $nxt; then ar_open_rung $gi $nxt; AR_OPENED=$nxt; fi; fi
  # THE WALL · the run as it ended, the rank it took and the rung it opened
  ar_run_set $gi $di $sc $AR_PLAYERS $rank $AR_OPENED 1
  b4=${AR[credits]:-0}; ar_badges_check; ar_run_clear
  AR_PAY_WON=("${AR_BWON[@]}"); (( REPLY )) || AR_PAY_WON=()
  AR_PAY_START=${AR[credits]:-0}
  ar_award $AR_PTOT; AR_PAY_GOT=$REPLY
  AR_PAY_END=$(( AR_PAY_START + AR_PAY_GOT ))
  AR_DIRTY=1; ar_save_write
  AR_CHIMED=()
  if (( sc > 0 && rank < 5 )); then ar_snd start; ar_go ranked; else ar_go payout; fi
  return 0 }
typeset -gi AR_PAY_RIG=0
typeset -ga AR_PAY_WON

# ── RANKED IN · no initials to type, the arcade knows you ────────────────
ar_draw_ranked() {
  local -F t=$AR_T el=$(( AR_T - AR_VIEW_T0 )) grow; local -i bw pw px pbg gi=$AR_GI di=$AR_DI hy ly py
  local plate='' c; local -i i
  :   # the glass was cleared by ar_draw · the CRT with it
  # THE CARD STANDS IN THE MIDDLE OF THE TUBE · the headline, its line and the
  # plate as one block, the prompt keeping its place a row off the bottom
  ar_vstack 1 $(( AR_H - 3 )) 2  5 1 1 2 5; hy=${AR_VSY[0]}; ly=${AR_VSY[1]}; py=${AR_VSY[2]}
  AR_TOAST_FLOOR=$hy                                   # a trophy card waits rather than land on the headline
  big_width 'RANKED IN'; bw=$BW
  ar_big_sweep $bw $AMBER $MAGENTA 0.8 0.5 1.8 22 4.0 0.75
  AR_BROW=(); for (( i = 0; i < 5; i++ )); do ar_wave $t 0.6 $i; AR_BROW[$i]=$(( 0.12 * WV )); done
  ar_big_cols 'RANKED IN' $(( (AR_W - bw) / 2 )) $hy $AMBER
  AR_BROW=()
  ar_commify $AR_FINAL; cmix ${AR_DC[$di]} $WHITE 0.35
  a_center $ly "${AR_ROMAN[$AR_RANK]:-—} PLACE   ·   ${AR_GTITLE[$gi]} ${AR_DN[$di]}   ·   $REPLY POINTS" $CM $GLASS
  ar_short "$AR_PNAME" $AR_NAME_MAX
  for (( i = 0; i < ${#REPLY}; i++ )); do [[ -n "$plate" ]] && plate+=' '; plate+="${REPLY[$i]}"; done
  pw=$(( ${#plate} + 8 )); (( pw < 26 )) && pw=26; px=$(( (AR_W - pw) / 2 ))
  grow=$(( el / 0.45 )); (( grow > 1.0 )) && grow=1.0
  cmix $GLASS $AMBER $(( 0.10 + 0.14 * grow )); pbg=$CM
  ar_wave $t 0.7; cmix $AMBER $WHITE $(( 0.35 + 0.3 * WV )); a_box $px $py $pw 5 $CM $pbg double 1
  cshade $AMBER 0.9; a_center $(( py + 1 )) '◆  P L A Y E R  ◆' $CS $pbg $px $pw
  ar_wave $t 0.9; cmix $WHITE $AMBER $(( 0.15 * WV )); a_center $(( py + 2 )) "$plate" $CM $pbg $px $pw
  a_center $(( py + 3 )) 'signed in on this Mac' $AR_LOP $pbg $px $pw
  ar_wave $t 0.8; (( el > 1.2 && WV > 0.35 )) && { cmix $AMBER $WHITE 0.3; a_center $(( AR_H - 2 )) '◂ PRESS ANY KEY ▸' $CM $GLASS; }
  (( el > 0.9 && ${#AR_CHIMED[@]} == 0 )) && { AR_CHIMED=(1); ar_snd coin; }
  (( el > 4.0 )) && { AR_CHIMED=(); ar_go payout; }
  return 0 }
ar_ranked_key() { (( AR_T - AR_VIEW_T0 > 0.8 )) && { AR_CHIMED=(); ar_go payout; }; return 0 }

# ── THE PAYOUT WINDOW · the lines, the subtotal, the rung, and the bank ───
ar_draw_payout() {
  local -F t=$AR_T el=$(( AR_T - AR_VIEW_T0 )) rows_at=0.7 per_row=0.55 count_at k
  local -i gi=$AR_GI di=$AR_DI hb bw i n=${#AR_PL[@]} lx rx y by c shown fg y0 lw
  local rt s
  (( n < 1 )) && n=1
  count_at=$(( rows_at + per_row * n + 0.25 ))
  :   # the glass was cleared by ar_draw · the CRT with it
  # THE GUTTER AND THE WINDOW SPLIT THE TUBE WHERE arcade.py SPLIT ITS 72 (26 | 46),
  # scaled to the tube in hand · he stands centred in the gutter, and the window's
  # tally is a column of its own width in the middle of the window.  A run he is
  # not going to stand beside (free play, service mode, nothing earned) leaves no
  # gutter to keep empty, and its window takes the whole tube
  local -i him=0
  (( ${#AR_PL[@]} && ! AR_PAY_RIG )) && ! ar_free && him=1
  if (( him )); then AR_PAY_CX=$(( AR_W * 26 / AR_OW )); else AR_PAY_CX=0; fi
  AR_PAY_CW=$(( AR_W - AR_PAY_CX ))
  lw=$(( 34 + (AR_W - AR_OW) * 3 / 10 ))
  lx=$(( AR_PAY_CX + (AR_PAY_CW - lw) / 2 )); rx=$(( lx + lw )); (( rx > AR_W - 10 )) && rx=$(( AR_W - 10 ))
  # the window's block · the trophy line, FINAL SCORE, the big score, the rule, three
  # lines, the five under them, a breath and the rung it opened · centred like he is
  ar_vstack 1 $(( AR_H - 2 )) 0  18; y0=${AR_VSY[0]}
  cmix $GLASS $AMBER 0.20; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $AMBER 0.2; a_text 2 0 '◤ ROUND COMPLETE' $CM $hb
  rt="${AR_GTITLE[$gi]}  ·  ${AR_DN[$di]}"; cshade $WHITE 0.8; a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $CS $hb
  # anything the run just took off the wall, over the score · one gets the headline, the rest are counted below
  if (( ${#AR_PAY_WON[@]} && el > 0.5 )); then
    local -i wb=${AR_PAY_WON[0]} rc=${AR_RARC[${BW_RAR[${AR_PAY_WON[0]}]}]:-$GREY}; local wl
    if (( BW_COINS[wb] )); then wl="✦  ${BW_NAME[$wb]}  ·  +${BW_COINS[$wb]} ◉"; else wl="✦  ${BW_NAME[$wb]}  ·  for the wall"; fi
    ar_wave $t 1.1; cmix $rc $WHITE $(( 0.3 + 0.25 * WV )); a_center $y0 "${wl[0,$(( AR_PAY_CW - 1 ))]}" $CM $GLASS $AR_PAY_CX $AR_PAY_CW
  fi
  # HE STANDS IN THE GUTTER WHEN HE EARNED YOU SOMETHING · never on free play, service mode, or a run that scored nothing
  (( him && el > rows_at - 0.2 )) && ar_vn_gutter
  cshade $GREY 1.1; a_center $(( y0 + 1 )) 'FINAL SCORE' $CS $GLASS $AR_PAY_CX $AR_PAY_CW
  ar_commify $AR_FINAL; s="$REPLY"; big_width "$s"; bw=$BW
  (( bw > AR_PAY_CW )) && { s="$AR_FINAL"; big_width "$s"; bw=$BW; }
  local -i cx; AR_BCOL=(); for (( cx = 0; cx < bw; cx++ )); do cmix $CYAN $LIME $(( cx / (bw > 1 ? bw * 1.0 : 1.0) )); AR_BCOL[$cx]=$CM; done
  AR_BROW=(); for (( cx = 0; cx < 5; cx++ )); do ar_wave $t 0.5 $cx; AR_BROW[$cx]=$(( 0.2 * WV )); done
  cx=$(( AR_PAY_CX + (AR_PAY_CW - bw) / 2 )); (( cx < AR_PAY_CX )) && cx=$AR_PAY_CX
  ar_big_cols "$s" $cx $(( y0 + 2 )) $CYAN
  AR_BROW=()
  y=$(( y0 + 8 ))
  cshade $PURPLE 0.7; a_hline $lx $(( y - 1 )) $(( rx - lx )) '─' $CS
  if (( AR_PAY_RIG && el > rows_at )); then
    cmix $AMBER $WHITE 0.4; a_center $y '◆ SERVICE MODE -- NO COINS, NO RECORD ◆' $CM $GLASS
    a_center $(( y + 1 )) 'switch the operator settings back to play for the table' $AR_LO $GLASS
  elif ar_free && (( el > rows_at )); then
    ar_wave $t 0.8; cmix $LIME $WHITE $(( 0.25 + 0.2 * WV )); a_center $y '◆ FREE PLAY -- NO COINS EARNED ◆' $CM $GLASS
    a_center $(( y + 1 )) 'turn FREE PLAY off in the settings to earn again' $AR_LO $GLASS
  elif (( ${#AR_PL[@]} == 0 && el > rows_at )); then
    ar_paydiv $gi; ar_commify $REPLY; cshade $RED 1.0; a_center $y "NO PAYOUT -- SCORE UNDER $REPLY POINTS" $CS $GLASS
  fi
  for (( i = 0; i < ${#AR_PL[@]}; i++ )); do
    (( el < rows_at + i * per_row )) && continue
    [[ -z "${AR_CHIMED[$i]:-}" ]] && { AR_CHIMED[$i]=1; ar_snd select; }
    if [[ "${AR_PL[$i]}" == BASE* ]]; then c=$AMBER; else cmix $MAGENTA $WHITE 0.3; c=$CM; fi
    a_text $lx $(( y + i )) "${AR_PL[$i]}" $c $GLASS
    s="${AR_PN[$i]}"; cmix $c $WHITE 0.4; a_text $(( rx - ${#s} )) $(( y + i )) "$s" $CM $GLASS
  done
  by=$(( y + n ))
  if (( ${#AR_PL[@]} && el > count_at - 0.3 )); then
    cshade $GREY 1.15; a_text $lx $by SUBTOTAL $CS $GLASS
    s="$AR_PSUB"; cshade $WHITE 0.9; a_text $(( rx - ${#s} )) $by "$s" $CS $GLASS
    by=$(( by + 1 ))
    cshade $PURPLE 0.7; a_hline $lx $by $(( rx - lx )) '─' $CS
    cmix ${AR_DC[$di]} $WHITE 0.35; a_text $lx $(( by + 1 )) "${AR_DN[$di]} BONUS" $CM $GLASS
    s="×${AR_DM[$di]}"; cmix ${AR_DC[$di]} $WHITE 0.5; a_text $(( rx - ${#s} )) $(( by + 1 )) "$s" $CM $GLASS
  fi
  if (( el > count_at )); then
    k=$(( (el - count_at) / 1.1 )); (( k > 1.0 )) && k=1.0
    shown=$(( AR_PAY_START + int((AR_PAY_END - AR_PAY_START) * k) ))
    [[ -z "${AR_CHIMED[9]:-}" ]] && { AR_CHIMED[9]=1; (( AR_PAY_GOT )) && ar_snd coin; }
    if ! ar_free && (( ${#AR_PL[@]} )); then
      cmix $LIME $WHITE 0.2; a_text $lx $(( by + 2 )) 'COINS EARNED' $CM $GLASS
      s="+$AR_PAY_GOT"; cmix $LIME $WHITE 0.45; a_text $(( rx - ${#s} )) $(( by + 2 )) "$s" $CM $GLASS
      (( AR_PAY_GOT < AR_PTOT )) && { cshade $RED 1.0; a_text $(( rx + 2 )) $(( by + 2 )) "of $AR_PTOT" $CS $GLASS; }
    fi
    cshade $GREY 1.15; a_text $lx $(( by + 3 )) 'COIN BANK' $CS $GLASS
    ar_pad $(( shown > AR_MAX_COINS ? AR_MAX_COINS : shown )) 4; s="$REPLY"
    if (( k < 1.0 )); then fg=$WHITE; else cmix $AMBER $WHITE 0.3; fg=$CM; fi
    a_text $(( rx - ${#s} )) $(( by + 3 )) "$s" $fg $GLASS
    (( AR_PAY_END >= AR_MAX_COINS )) && a_text $(( rx + 2 )) $(( by + 3 )) MAX $RED $GLASS
    # the rung it opened, or the rest of the wall · a breath under the bank now
    # that there is room for one (on the old tube it shared the bank's row)
    if (( AR_OPENED >= 0 )); then
      ar_wave $t 1.3; if (( WV > 0.35 )); then cmix ${AR_DC[$AR_OPENED]} $WHITE 0.45; else cshade ${AR_DC[$AR_OPENED]} 0.9; CM=$CS; fi
      a_center $(( by + 5 )) "◆  ${AR_DN[$AR_OPENED]} UNLOCKED ON ${AR_GTITLE[$gi]}  ◆" $CM $GLASS $AR_PAY_CX $AR_PAY_CW
    elif (( ${#AR_PAY_WON[@]} > 1 )); then
      a_center $(( by + 5 )) "and $(( ${#AR_PAY_WON[@]} - 1 )) more on the wall  ·  [A] to read them" $AR_LO $GLASS $AR_PAY_CX $AR_PAY_CW
    fi
    ar_wave $t 0.8; (( k >= 1.0 && WV > 0.4 )) && { cmix $AMBER $WHITE 0.3; a_center $(( AR_H - 1 )) '◂ PRESS ANY KEY ▸' $CM $GLASS $AR_PAY_CX $AR_PAY_CW; }
    (( el > count_at + 3.4 )) && { AR_CHIMED=(); AR_TQ=(); ar_go menu; }
  fi
  return 0 }
ar_payout_key() { (( AR_T - AR_VIEW_T0 > 0.8 )) && { AR_CHIMED=(); AR_TQ=(); ar_go menu; }; return 0 }   # they were all just read out on this page
(( ${+functions[ar_vn_gutter]} )) || ar_vn_gutter() { return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 10 · HIGH SCORES        every rung of every machine · ◂ ▸ the machine, ▴ ▾ the rung
# ══════════════════════════════════════════════════════════════════════════
typeset -gi AR_HS_G=0 AR_HS_D=1
ar_draw_scores() {   # THE HALL OF FAME · arcade.py's page_scores, cell for cell, on whatever tube it is handed
  local -F t=$AR_T sweep d f; local -i gi=$AR_HS_G di=$AR_HS_D hb bw cx cy i y c pulse tabw tx0 bx bgc hot mine xx dots bar top acc n
  local -i ex tw tx se bwid rp hy gy ty j
  local word='HI SCORES' s shown lab me rt ds bars='▁▂▃▄▅▆▇' mk; local -a medal
  acc=${AR_GACC[$gi]}
  # THE TABLE WIDENS WITH THE TUBE, ITS BARS WITH IT, AND ITS ROWS BREATHE when
  # there are rows to spare · arcade.py's table ran rank to bar across 55 of 72
  # columns; it takes half of every column the glass adds, the bar an eighth
  ex=$(( AR_W - AR_OW ))
  tw=$(( 55 + ex / 2 )); (( tw > 80 )) && tw=80; (( tw > AR_W - 8 )) && tw=$(( AR_W - 8 ))
  bwid=$(( 6 + ex / 8 )); (( bwid > 14 )) && bwid=14
  tabw=$(( (tw + 5) / 4 )); tx=$(( (AR_W - tw + 3) / 2 )); se=$(( tx + tw - bwid - 2 ))
  rp=1; (( AR_H >= 24 )) && rp=2
  # the headline, the machine and its rungs, the table · centred between the band and the footer
  ar_vstack 1 $(( AR_H - 2 )) $(( 1 + (AR_H - AR_OH) / 16 ))  5 1 2 1 $(( 1 + 4 * rp )); hy=${AR_VSY[0]}; gy=${AR_VSY[1]}; ty=${AR_VSY[2]}
  # the headline first · its glow reaches two rows up, and the band goes over it
  big_width "$word"; bw=$BW
  sweep=$(( t * 0.5 )); sweep=$(( (sweep - floor(sweep / 1.8) * 1.8) * (bw + 22) - 11 ))
  AR_BCOL=()
  for (( cx = 0; cx < bw; cx++ )); do
    f=$(( cx / (bw > 1 ? bw * 1.0 : 1.0) )); cmix $AMBER $MAGENTA $(( f * 0.8 ))
    d=$(( abs(cx - sweep) )); (( d < 4.0 )) && cmix $CM $WHITE $(( (1.0 - d / 4.0) ** 2 * 0.75 ))
    AR_BCOL[$cx]=$CM
  done
  AR_BROW=(); for (( cy = 0; cy < 5; cy++ )); do AR_BROW[$cy]=$(( 0.10 * (1.0 - cy / 4.0) )); done
  ar_big_cols "$word" $(( (AR_W - bw) / 2 )) $hy $AMBER
  AR_BROW=()
  cmix $GLASS $AMBER 0.22; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $AMBER 0.2; a_text 2 0 '◤ HALL OF FAME' $CM $hb
  rt="ARCADE $(( gi + 1 ))/$AR_NG"; cshade $WHITE 0.8; a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $CS $hb
  cmix $acc $WHITE 0.3; a_center $gy "◂   ${AR_GTITLE[$gi]}   ▸   ${AR_GGENRE[$gi]} · ${AR_GYEAR[$gi]}" $CM $GLASS
  # the rungs, as tabs · as wide between them as the table under them
  tx0=$(( (AR_W - tabw * 4) / 2 )); y=$(( gy + 1 ))
  for (( i = 0; i < 4; i++ )); do
    hot=$(( i == di )); bx=$(( tx0 + i * tabw ))
    cmix $GLASS ${AR_DC[$i]} $(( hot ? 0.28 : 0.06 )); bgc=$CM
    a_rect $bx $y $(( tabw - 1 )) 1 ' ' -2 $bgc
    if (( hot )); then lab="▸ ${AR_DN[$i]} ◂"; cmix ${AR_DC[$i]} $WHITE 0.5; c=$CM; else lab="${AR_DN[$i]}"; cshade ${AR_DC[$i]} 0.55; c=$CS; fi
    a_center $y "$lab" $c $bgc $bx $(( tabw - 1 ))
  done
  cshade $CYAN 0.9; a_text $(( tx0 - 2 )) $y '▲' $CS $GLASS; a_text $(( tx0 + tabw * 4 )) $y '▼' $CS $GLASS
  # the table · gold, silver, bronze, and two greys
  ar_table $gi $di; ar_player_name; me="$REPLY"
  _pack 200 200 214; local -i silver=$PK; _pack 188 118 70; local -i bronze=$PK
  cshade $GREY 0.9; local -i g4=$CS; cshade $GREY 0.75; local -i g5=$CS
  medal=($AMBER $silver $bronze $g4 $g5)
  top=${AR_TS[0]:-1}; (( top < 1 )) && top=1
  cshade $DIM 1.15; local -i dotc=$CS
  n=${#AR_TS[@]}; (( n > 5 )) && n=5
  local -i base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX )) k
  for (( i = 0; i < n; i++ )); do
    y=$(( ty + i * rp )); c=${medal[$i]}
    ar_scrub "${AR_TN[$i]}"; [[ "$REPLY" == "$me" ]] && mine=1 || mine=0
    if (( i == 0 )); then ar_wave $t 0.5 $(( i * 0.8 )); cmix $c $WHITE $(( 0.30 * WV )); pulse=$CM; else pulse=$c; fi
    if (( mine && y < AR_H )); then   # your own row, lit from its middle · the wash mixed once a column and kept
      k=$(( base + y * TCOLS + tx - 1 ))
      for (( xx = 0; xx < tw; xx++, k++ )); do
        mk="hs.$c.$xx.$tw"
        [[ -z "${AR_SWEEP[$mk]:-}" ]] && { f=$(( 1.0 - abs(xx - (tw - 1) / 2.0) / ((tw - 1) / 2.0) )); cmix $GLASS $c $(( 0.05 + 0.11 * f )); AR_SWEEP[$mk]=$CM; }
        GCH[$k]=' '; GB[$k]=${AR_SWEEP[$mk]}
      done
    fi
    a_text $tx $y "${AR_ROMAN[$i]}" $pulse -2
    cshade $c 0.9; if (( i == 0 )); then a_text $(( tx + 5 )) $y '█ ' $CS -2; else a_text $(( tx + 5 )) $y '▌ ' $CS -2; fi
    ar_short "${AR_TN[$i]}" $AR_NAME_MAX; shown="$REPLY"
    cmix $c $WHITE $(( mine ? 0.45 : 0.3 )); a_text $(( tx + 8 )) $y "$shown" $CM -2
    ar_commify ${AR_TS[$i]}; s="$REPLY"
    dots=$(( se - ${#s} - (tx + 9 + ${#shown}) ))
    if (( dots > 0 )); then ds=''; repeat $dots ds+='·'; a_text $(( tx + 9 + ${#shown} )) $y "$ds" $dotc -2; fi
    a_text $(( se - ${#s} )) $y "$s" $pulse -2
    # the bar · as long as the score is against the leader's, rising as it goes
    bar=$(( int(AR_TS[i] * 1.0 * bwid / top) )); (( bar < 0 )) && bar=0; (( bar > bwid )) && bar=$bwid
    if (( bar )); then ds=''; for (( j = 0; j < bar; j++ )); do ds+="${bars[$(( j * 6 / bwid ))]}"; done; cshade $c 0.75; a_text $(( se + 2 )) $y "$ds" $CS -2; fi
  done
  local -i plays=${AR[plays.${AR_GID[$gi]}.${AR_DK[$di]}]:-0}; local pl=S; (( plays == 1 )) && pl=''
  a_center $(( AR_H - 1 )) "${AR_DN[$di]} RUNG  ·  PAYS ×${AR_DM[$di]}  ·  ${AR_GTITLE[$gi]} PLAYED $plays TIME$pl" $AR_LO $GLASS
  return 0 }
ar_scores_key() {
  case "$1" in
    left)  AR_HS_G=$(( (AR_HS_G + AR_NG - 1) % AR_NG )); ar_snd move ;;
    right) AR_HS_G=$(( (AR_HS_G + 1) % AR_NG )); ar_snd move ;;
    up)    AR_HS_D=$(( (AR_HS_D + 3) % 4 )); ar_snd move ;;
    down|tab|$'\t') AR_HS_D=$(( (AR_HS_D + 1) % 4 )); ar_snd move ;;
    esc|back|enter|' '|space|h|H) ar_snd select; ar_go menu ;;
    u|U) ar_mute ;;
    *) return 1 ;;
  esac
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 11 · COMING SOON        a cartridge for a slot that is wired and waiting
# ══════════════════════════════════════════════════════════════════════════
ar_draw_soon() {
  local -F t=$AR_T el=$(( AR_T - AR_VIEW_T0 )); local -i gi=$AR_GI bw hb acc pct cw cx0 cy0 dk sc dy i bx done_
  local -i ex ch dw hy by ty k base; local rt label mk
  acc=${AR_GACC[$gi]}
  :   # the glass was cleared by ar_draw · the CRT with it
  ar_stable "${AR_GID[$gi]}"; pct=$(( 12 + REPLY % 74 ))
  # THE CARTRIDGE AND THE METER GROW WITH THE TUBE · half of every column the
  # glass adds, and two rows more of cartridge for every eight rows it adds
  ex=$(( AR_W - AR_OW ))
  cw=$(( 34 + ex / 2 )); (( cw > AR_W - 10 )) && cw=$(( AR_W - 10 ))
  ch=$(( (AR_H - AR_OH) / 8 )); (( ch > 2 )) && ch=2; ch=$(( 3 + 2 * ch ))
  dw=$(( 40 + ex / 2 )); (( dw > AR_W - 32 )) && dw=$(( AR_W - 32 ))
  # the headline, the cartridge, the meter, the two lines · centred over the prompt
  ar_vstack 1 $(( AR_H - 2 )) 2  5 1 $ch 1 1 1 2; hy=${AR_VSY[0]}; cy0=${AR_VSY[1]}; by=${AR_VSY[2]}; ty=${AR_VSY[3]}
  big_width 'COMING SOON'; bw=$BW
  local -F sw d; local -i cx
  sw=$(( t * 0.5 )); sw=$(( (sw - floor(sw / 1.7) * 1.7) * (bw + 20) - 10 ))
  AR_BCOL=()
  for (( cx = 0; cx < bw; cx++ )); do
    cmix $MAGENTA $CYAN $(( cx / (bw > 1 ? bw * 1.0 : 1.0) )); cmix $CM $acc 0.35
    d=$(( abs(cx - sw) )); (( d < 5.0 )) && cmix $CM $WHITE $(( (1.0 - d / 5.0) ** 2 * 0.75 ))
    AR_BCOL[$cx]=$CM
  done
  AR_BRSH=(); for (( cx = 0; cx < 5; cx++ )); do ar_wave $t 0.5 $cx; AR_BRSH[$cx]=$(( 0.84 + 0.16 * WV )); done
  ar_big_cols 'COMING SOON' $(( (AR_W - bw) / 2 )) $hy $acc
  AR_BRSH=()
  cmix $GLASS $acc 0.22; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $acc 0.25; a_text 2 0 "◤ ${AR_GTITLE[$gi]}" $CM $hb
  rt="ROM SLOT ${${AR_GID[$gi]}:u}"; cshade $WHITE 0.75; a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $CS $hb
  # the cartridge · its label on the middle row, its teeth along the bottom one
  cx0=$(( (AR_W - cw) / 2 )); _pack 18 10 32; dk=$PK
  local -i ly=$(( cy0 + ch / 2 ))
  cshade $GREY 0.9; a_box $cx0 $cy0 $cw $ch $CS $dk double 1
  cshade $acc 1.0; a_text $(( cx0 + 2 )) $ly '▓▓' $CS $dk
  label="${AR_GTITLE[$gi]}"; cshade $WHITE 0.8; a_text $(( cx0 + 5 + (cw - 10 - ${#label}) / 2 )) $ly "$label" $CS $dk
  cshade $GREY 0.8; a_text $(( cx0 + cw - 5 )) $ly ROM $CS $dk
  local teeth=''; for (( i = 0; i < cw - 2; i++ )); do teeth+='╤'; done
  cshade $AMBER 0.85; a_text $(( cx0 + 1 )) $(( cy0 + ch - 1 )) "$teeth" $CS -2
  sc=$(( int((t * 0.7 - floor(t * 0.7)) * cw) ))
  cmix $CYAN $WHITE 0.5; local -i fg=$CM; cmix $dk $CYAN 0.25
  for (( dy = 0; dy < ch; dy++ )); do a_put $(( cx0 + sc )) $(( cy0 + dy )) '│' $fg $CM; done
  # the meter · its inks mixed once a cell and kept, the cells written straight in
  bx=$(( (AR_W - dw) / 2 )); done_=$(( dw * pct / 100 ))
  cshade $GREY 0.9; a_text $(( bx - 12 )) $by DEVELOPMENT $CS $GLASS
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX )); k=$(( base + by * TCOLS + bx ))
  for (( i = 0; i < dw; i++, k++ )); do
    if (( i < done_ )); then
      mk="soon.$acc.$i.$dw"
      [[ -z "${AR_SWEEP[$mk]:-}" ]] && { cmix $MAGENTA $CYAN $(( i / (dw * 1.0) )); cmix $CM $acc 0.3; cshade $CM 0.95; AR_SWEEP[$mk]=$CS; }
      GCH[$k]='█'; GF[$k]=${AR_SWEEP[$mk]}; GB[$k]=$GLASS
    else
      [[ -z "${AR_SWEEP[soon.off]:-}" ]] && { cshade $GREY 0.35; AR_SWEEP[soon.off]=$CS; }
      GCH[$k]='░'; GF[$k]=${AR_SWEEP[soon.off]}; GB[$k]=$GLASS
    fi
  done
  a_text $(( bx + dw + 2 )) $by "${pct}%" $AMBER $GLASS
  cshade $GREY 1.0; a_center $ty 'THIS ARCADE SLOT IS WIRED AND WAITING' $CS $GLASS
  a_center $(( ty + 1 )) 'this cabinet arrives in a later build of the pack' $AR_LO $GLASS
  ar_wave $t 0.8; (( WV > 0.4 )) && { cmix $AMBER $WHITE 0.3; a_center $(( AR_H - 1 )) '◂ PRESS ANY KEY ▸' $CM $GLASS; }
  return 0 }
ar_soon_key() { (( AR_T - AR_VIEW_T0 > 0.3 )) && { ar_snd away; ar_go menu; }; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15d · N E O N   S N A K E        the house game, and the reference Round
# ══════════════════════════════════════════════════════════════════════════
# Grid cells are two characters wide so the playfield reads as square on a
# terminal's 1:2 character cell.  THE CHAIN pays for taking the next ◆
# quickly -- bite inside the window and the bite is worth that many times
# more, to five; let it lapse and you are back to one.  The window is counted
# in MOVES and not in seconds, so the hardest rung is not the one where the
# chain is easiest to hold.  THE CRAWL is what the two hard rungs do to the
# mines: one takes a step every few moves, never onto you and never onto the
# food, so a board you had read once has to be read again on the way past.
typeset -gi SNAKE_GW=35 SNAKE_GH=15 SNAKE_OX=1 SNAKE_OY=2 SNK_CHAIN_MAX=5 SN_TAIL=0
#                          ROOKIE NORMAL EXPERT INSANE
typeset -ga SNK_START_STEP; SNK_START_STEP=(0.170 0.140 0.115 0.092)   # seconds a move
typeset -ga SNK_RAMP;       SNK_RAMP=(0.0045 0.0065 0.0080 0.0095)     # faster each level
typeset -ga SNK_FLOOR;      SNK_FLOOR=(0.080 0.055 0.045 0.038)        # speed cap
typeset -ga SNK_GEM_LIFE;   SNK_GEM_LIFE=(13.0 9.0 7.0 5.5)            # gem decay
typeset -ga SNK_HAZARDS;    SNK_HAZARDS=(0 0 6 14)                     # grid mines
typeset -ga SNK_WRAP;       SNK_WRAP=(1 0 0 0)                         # do the edges roll over
typeset -ga SNK_CHAIN;      SNK_CHAIN=(34 28 23 19)                    # chain window, MOVES
typeset -ga SNK_CREEP;      SNK_CREEP=(0 0 9 5)                        # steps a mine crawl
typeset -ga SNK_ARENAS;     SNK_ARENAS=(0 1 2 3)                       # blocks the rung lays

# the round's state · a set is an assoc keyed "x,y" · the body is a ring
typeset -gF SN_STEP0 SN_RAMP SN_FLOOR SN_GEMLIFE SN_STEPACC
typeset -gi SN_NMINES SN_WRAP SN_CHAINW SN_CREEP SN_NBLOCKS
typeset -gi SN_CHAIN SN_CHAINL SN_BESTCHAIN SN_STEPS SN_EATEN SN_GEMS
typeset -gi SN_HD SN_LN SN_N SN_HX SN_HY SN_DEAD SN_DX SN_DY
typeset -ga SN_BX SN_BY SN_TURNS SN_PX SN_PY SN_PT SN_PTXT SN_PCOL
typeset -gA SN_FILLED SN_MINES SN_BLOCKS
typeset -g  SN_FOOD='' SN_GEM=''        # "x,y" or empty
typeset -gF SN_GEMT=0.0

sn_begin() {
  AR_G_LEGEND='▲▼◄► STEER      [P] PAUSE      [Q] CASH OUT'
  AR_G_HOWTO='eat ◆ fast to build the chain  ·  ★ is worth five  ·  mind the ▚▞'
  AR_G_ACC=$LIME
  (( SN_TAIL )) || { _pack 16 74 96; SN_TAIL=$PK; }
  ar_pick "${SNK_START_STEP[@]}"; SN_STEP0=$REPLY
  ar_pick "${SNK_RAMP[@]}";       SN_RAMP=$REPLY
  ar_pick "${SNK_FLOOR[@]}";      SN_FLOOR=$REPLY
  ar_pick "${SNK_GEM_LIFE[@]}";   SN_GEMLIFE=$REPLY
  ar_pick "${SNK_HAZARDS[@]}";    SN_NMINES=$REPLY
  ar_pick "${SNK_WRAP[@]}";       SN_WRAP=$REPLY
  ar_pick "${SNK_CHAIN[@]}";      SN_CHAINW=$REPLY
  ar_pick "${SNK_CREEP[@]}";      SN_CREEP=$REPLY
  ar_pick "${SNK_ARENAS[@]}";     SN_NBLOCKS=$REPLY
  # THE GRID IS THE BOARD IT WAS DEALT · two columns a cell, framed, arcade.py's
  # 35 × 15 on its 72 × 18 and whatever the glass gives here.  The step rate
  # stays in cells a second -- the grid is the game -- while what fills the grid
  # grows with it: mines and floor-plan blocks by area, and the two clocks a
  # player races across it (the gem's life, the chain's window) by its reach.
  SNAKE_GW=$(( (AR_W - 2) / 2 )); SNAKE_GH=$(( AR_H - 3 ))
  SNAKE_OX=$(( (AR_W - 2 * SNAKE_GW) / 2 )); SNAKE_OY=2
  local -F area=$(( SNAKE_GW * SNAKE_GH / 525.0 )) reach=$(( (SNAKE_GW + SNAKE_GH) / 50.0 ))
  SN_NMINES=$(( int(SN_NMINES * area + 0.5) ))
  (( SN_NBLOCKS )) && SN_NBLOCKS=$(( int(SN_NBLOCKS * area + 0.5) ))
  SN_CHAINW=$(( int(SN_CHAINW * reach + 0.5) )); SN_GEMLIFE=$(( SN_GEMLIFE * reach ))
  SN_CHAIN=0; SN_CHAINL=0; SN_BESTCHAIN=0; SN_STEPS=0; SN_EATEN=0; SN_GEMS=0; SN_STEPACC=0.0
  SN_N=$(( SNAKE_GW * SNAKE_GH )); SN_BX=(); SN_BY=(); SN_FILLED=(); SN_MINES=(); SN_BLOCKS=()
  SN_TURNS=(); SN_PX=(); SN_PY=(); SN_PT=(); SN_PTXT=(); SN_PCOL=()
  SN_FOOD=''; SN_GEM=''; SN_DEAD=0; SN_HX=1; SN_HY=0
  local -i cy=$(( SNAKE_GH / 2 )) i
  # four cells, head at x=6, laid into the ring head-first
  SN_HD=0; SN_LN=4
  for (( i = 0; i < 4; i++ )); do SN_BX[$i]=$(( 6 - i )); SN_BY[$i]=$cy; SN_FILLED[$(( 6 - i )),$cy]=1; done
  # THE GRID IS NOT AN EMPTY RECTANGLE ANY MORE · ROOKIE keeps one, because a
  # beginner wants room; every rung above it is dealt a floor plan
  if (( SN_NBLOCKS )); then sn_arena $SN_NBLOCKS $cy; fi
  sn_lay_mines
  sn_spawn; SN_FOOD="$REPLY"
  return 0 }

# ── the floor plan · mirrored blocks, flood-filled so they cannot strand you ──
sn_arena() {   # sn_arena WANT CY — into SN_BLOCKS · dealt until it passes, else empty
  local -i want=$1 cy=$2 try n i k bx by ln cx mx x y qh qt nx ny nfree nseen ok
  local kind; local -a shapes; shapes=(bar bar block ell tee cross dot dash)
  local -A put seen; local -a qx qy cells keepx
  for (( try = 0; try < 24; try++ )); do
    put=()
    rnd_int $(( want - 1 > 1 ? want - 1 : 1 )) $(( want + 1 )); n=$REPLY
    for (( i = 0; i < n; i++ )); do
      rnd_pick 8; kind="${shapes[$REPLY]}"
      rnd_range 3 $(( SNAKE_GW / 2 - 2 > 4 ? SNAKE_GW / 2 - 2 : 4 )); bx=$REPLY
      rnd_range 2 $(( SNAKE_GH - 2 > 3 ? SNAKE_GH - 2 : 3 )); by=$REPLY
      rnd_pick 5; case $REPLY in 0) ln=2 ;; 1|2) ln=3 ;; 3) ln=4 ;; *) ln=5 ;; esac
      cells=()
      case "$kind" in
        bar)   for (( k = 0; k < ln; k++ )); do cells+=("$(( bx + k )),$by"); done ;;
        block) for (( k = 0; k < 2; k++ )); do cells+=("$(( bx + k )),$by"); (( ln >= 2 )) && cells+=("$(( bx + k )),$(( by + 1 ))"); done ;;
        ell)   for (( k = 0; k < ln; k++ )); do cells+=("$bx,$(( by + k ))"); cells+=("$(( bx + k )),$(( by + ln - 1 ))"); done ;;
        tee)   for (( k = 0; k < ln; k++ )); do cells+=("$(( bx + k )),$by"); cells+=("$(( bx + ln / 2 )),$(( by + k ))"); done ;;
        cross) for (( k = 0; k < 3; k++ )); do cells+=("$(( bx + k )),$(( by + 1 ))"); cells+=("$(( bx + 1 )),$(( by + k ))"); done ;;
        dash)  for (( k = 0; k < ln; k++ )); do cells+=("$bx,$(( by + k ))"); done ;;
        *)     cells+=("$bx,$by") ;;
      esac
      for c in "${cells[@]}"; do
        cx=${c%%,*}; y=${c#*,}
        for mx in $cx $(( SNAKE_GW - 1 - cx )); do
          (( mx >= 1 && mx < SNAKE_GW - 1 && y >= 1 && y < SNAKE_GH - 1 )) && put[$mx,$y]=1
        done
      done
    done
    # the starting lanes stay open, and so do their mirrors
    for (( x = 3; x < 20; x++ )); do unset "put[$x,$cy]"; unset "put[$(( SNAKE_GW - 1 - x )),$cy]"; done
    (( ${#put[@]} )) || continue
    nfree=$(( SN_N - ${#put[@]} ))
    (( nfree < SN_N * 0.62 )) && continue
    # flood from the lane · every free cell must be reached
    seen=(); qx=(3); qy=($cy); seen[3,$cy]=1; qh=0; qt=1
    while (( qh < qt )); do
      x=${qx[$qh]}; y=${qy[$qh]}; qh=$(( qh + 1 ))
      for k in 0 1 2 3; do
        case $k in 0) nx=$(( x + 1 )); ny=$y ;; 1) nx=$(( x - 1 )); ny=$y ;; 2) nx=$x; ny=$(( y + 1 )) ;; *) nx=$x; ny=$(( y - 1 )) ;; esac
        (( nx < 0 || nx >= SNAKE_GW || ny < 0 || ny >= SNAKE_GH )) && continue
        [[ -n "${put[$nx,$ny]:-}" || -n "${seen[$nx,$ny]:-}" ]] && continue
        seen[$nx,$ny]=1; qx[$qt]=$nx; qy[$qt]=$ny; qt=$(( qt + 1 ))
      done
    done
    (( ${#seen[@]} == nfree )) || continue
    ok=1; for (( x = 3; x < 20; x++ )); do [[ -n "${seen[$x,$cy]:-}" && -n "${seen[$(( SNAKE_GW - 1 - x )),$cy]:-}" ]] || { ok=0; break; }; done
    (( ok )) || continue
    for c in ${(k)put[@]}; do SN_BLOCKS[$c]=1; done
    return 0
  done
  SN_BLOCKS=()          # the fallback · an open floor, checked by hand
  return 0 }

sn_lay_mines() {   # static hazards, kept clear of the spawn lane and the far edges
  local -i guard=0 mx my cy=$(( SNAKE_GH / 2 ))
  SN_MINES=()
  while (( ${#SN_MINES[@]} < SN_NMINES && guard < 400 )); do
    guard=$(( guard + 1 ))
    rnd_range 2 $(( SNAKE_GW - 2 )); mx=$REPLY; rnd_range 1 $(( SNAKE_GH - 1 )); my=$REPLY
    (( my == cy && mx < 18 )) && continue
    [[ -n "${SN_FILLED[$mx,$my]:-}" || -n "${SN_BLOCKS[$mx,$my]:-}" ]] && continue
    SN_MINES[$mx,$my]=1
  done
  return 0 }
sn_spawn() {   # → REPLY a free cell "x,y", or '' when the board is full
  local -a free; free=(); local -i x y
  for (( y = 0; y < SNAKE_GH; y++ )); do for (( x = 0; x < SNAKE_GW; x++ )); do
    [[ -n "${SN_FILLED[$x,$y]:-}" || -n "${SN_MINES[$x,$y]:-}" || -n "${SN_BLOCKS[$x,$y]:-}" ]] && continue
    [[ "$x,$y" == "$SN_FOOD" || "$x,$y" == "$SN_GEM" ]] && continue
    free+=("$x,$y")
  done; done
  (( ${#free[@]} )) || { REPLY=''; return 0 }
  rnd_pick ${#free[@]}; REPLY="${free[$REPLY]}"; return 0 }
sn_pop() {   # sn_pop X Y TEXT COLOUR [DELAY]
  SN_PX+=($1); SN_PY+=($2); SN_PT+=($(( AR_RT + ${5:-0.0} ))); SN_PTXT+=("$3"); SN_PCOL+=($4); return 0 }

# ── the simulation ───────────────────────────────────────────────────────
sn_update() {   # sn_update DT
  local -F dt=$1 interval; local k d last; local -i guard=0 ndx ndy ldx ldy
  for k in "${AR_KEYS[@]}"; do
    d=''
    case "$k" in UP|W) d='0,-1' ;; DOWN|S) d='0,1' ;; LEFT|A) d='-1,0' ;; RIGHT|D) d='1,0' ;; esac
    [[ -n "$d" ]] || continue
    if (( ${#SN_TURNS[@]} )); then last="${SN_TURNS[-1]}"; else last="$SN_HX,$SN_HY"; fi
    ndx=${d%%,*}; ndy=${d#*,}; ldx=${last%%,*}; ldy=${last#*,}
    if [[ "$d" != "$last" ]] && (( ndx != -ldx || ndy != -ldy )) && (( ${#SN_TURNS[@]} < 2 )); then SN_TURNS+=("$d"); fi
  done
  AR_LEVEL=$(( 1 + SN_EATEN / 5 )); (( AR_LEVEL > 15 )) && AR_LEVEL=15
  interval=$(( SN_STEP0 - (AR_LEVEL - 1) * SN_RAMP )); (( interval < SN_FLOOR )) && interval=$SN_FLOOR
  [[ -n "$SN_GEM" ]] && (( AR_RT - SN_GEMT > SN_GEMLIFE )) && SN_GEM=''
  # never bank a stall · a long frame must not fire a burst of moves
  SN_STEPACC=$(( SN_STEPACC + dt )); (( SN_STEPACC > interval * 4 )) && SN_STEPACC=$(( interval * 4 ))
  while (( SN_STEPACC >= interval && AR_ALIVE && guard < 4 )); do
    SN_STEPACC=$(( SN_STEPACC - interval )); guard=$(( guard + 1 ))
    sn_step
    SN_STEPS=$(( SN_STEPS + 1 ))
    if (( SN_CHAIN )); then SN_CHAINL=$(( SN_CHAINL - 1 )); (( SN_CHAINL <= 0 )) && SN_CHAIN=0; fi
    (( SN_CREEP && SN_STEPS % SN_CREEP == 0 )) && sn_crawl
  done
  return 0 }
sn_step() {
  local nd; local -i ndx ndy hx hy nx ny grow=0 tx ty ti mult gain
  if (( ${#SN_TURNS[@]} )); then
    nd="${SN_TURNS[0]}"; SN_TURNS=("${SN_TURNS[@]:1}")
    ndx=${nd%%,*}; ndy=${nd#*,}
    (( ndx != -SN_HX || ndy != -SN_HY )) && { SN_HX=$ndx; SN_HY=$ndy; }
  fi
  hx=${SN_BX[$SN_HD]}; hy=${SN_BY[$SN_HD]}
  nx=$(( hx + SN_HX )); ny=$(( hy + SN_HY ))
  if (( SN_WRAP )); then nx=$(( (nx + SNAKE_GW) % SNAKE_GW )); ny=$(( (ny + SNAKE_GH) % SNAKE_GH )); fi
  [[ -n "$SN_FOOD" && "$nx,$ny" == "$SN_FOOD" ]] && grow=1
  ti=$(( (SN_HD + SN_LN - 1) % SN_N )); tx=${SN_BX[$ti]}; ty=${SN_BY[$ti]}
  # walking into the cell your tail is vacating is legal
  if (( nx < 0 || ny < 0 || nx >= SNAKE_GW || ny >= SNAKE_GH )) || [[ -n "${SN_MINES[$nx,$ny]:-}" || -n "${SN_BLOCKS[$nx,$ny]:-}" ]] \
     || { [[ -n "${SN_FILLED[$nx,$ny]:-}" ]] && ! (( ! grow && nx == tx && ny == ty )); }; then
    SN_DEAD=1; SN_DX=$nx; SN_DY=$ny; AR_ALIVE=0; return 0
  fi
  if (( ! grow )); then SN_LN=$(( SN_LN - 1 )); unset "SN_FILLED[$tx,$ty]"; fi
  SN_HD=$(( (SN_HD - 1 + SN_N) % SN_N )); SN_BX[$SN_HD]=$nx; SN_BY[$SN_HD]=$ny; SN_LN=$(( SN_LN + 1 ))
  SN_FILLED[$nx,$ny]=1
  if (( grow )); then
    SN_EATEN=$(( SN_EATEN + 1 ))
    # THE LINK, OR THE BREAK · the window is only refilled by a bite
    if (( SN_CHAINL > 0 )); then SN_CHAIN=$(( SN_CHAIN + 1 )); else SN_CHAIN=1; fi
    SN_CHAINL=$SN_CHAINW
    (( SN_CHAIN > SN_BESTCHAIN )) && SN_BESTCHAIN=$SN_CHAIN
    mult=$SN_CHAIN; (( mult > SNK_CHAIN_MAX )) && mult=$SNK_CHAIN_MAX
    gain=$(( 10 * AR_LEVEL * mult ))
    ar_add $gain; ar_shown $gain; gain=$REPLY          # the pop says what the board credited
    if (( mult < 2 )); then sn_pop $nx $ny "+$gain" $LIME
    else cmix $AMBER $WHITE 0.3; if (( mult < 3 )); then sn_pop $nx $ny "+$gain  ×$mult" $LIME; else sn_pop $nx $ny "+$gain  ×$mult" $CM; fi; fi
    if (( mult < SNK_CHAIN_MAX )); then ar_snd select; else ar_snd coin; fi
    sn_spawn; SN_FOOD="$REPLY"
    [[ -n "$SN_FOOD" ]] || { SN_DEAD=0; AR_ALIVE=0; return 0 }        # board full · a perfect game
    (( SN_EATEN % 5 == 0 )) && sn_pop $nx $ny 'LEVEL UP' $CYAN 0.3
    if [[ -z "$SN_GEM" ]] && (( SN_EATEN % 4 == 0 )); then sn_spawn; [[ -n "$REPLY" ]] && { SN_GEM="$REPLY"; SN_GEMT=$AR_RT; }; fi
  fi
  if [[ -n "$SN_GEM" && "$nx,$ny" == "$SN_GEM" ]]; then
    mult=$SN_CHAIN; (( mult < 1 )) && mult=1; (( mult > SNK_CHAIN_MAX )) && mult=$SNK_CHAIN_MAX
    gain=$(( 50 * AR_LEVEL * mult )); ar_add $gain; SN_GEMS=$(( SN_GEMS + 1 ))
    ar_shown $gain; sn_pop $nx $ny "+$REPLY" $MAGENTA; SN_GEM=''; ar_snd coin
  fi
  return 0 }
sn_crawl() {   # one mine takes one step · never onto the snake, the food, the gem, or the cell ahead
  (( ${#SN_MINES[@]} )) || return 0
  local -i hx=${SN_BX[$SN_HD]} hy=${SN_BY[$SN_HD]} ax ay px py nx ny
  local pick; local -a ks
  ax=$(( hx + SN_HX )); ay=$(( hy + SN_HY ))
  ks=(${(ok)SN_MINES[@]}); rnd_pick ${#ks[@]}; pick="${ks[$REPLY]}"
  px=${pick%%,*}; py=${pick#*,}
  rnd_pick 4; case $REPLY in 0) nx=$(( px + 1 )); ny=$py ;; 1) nx=$(( px - 1 )); ny=$py ;; 2) nx=$px; ny=$(( py + 1 )) ;; *) nx=$px; ny=$(( py - 1 )) ;; esac
  (( nx >= 1 && nx < SNAKE_GW - 1 && ny >= 1 && ny < SNAKE_GH - 1 )) || return 0
  [[ -n "${SN_FILLED[$nx,$ny]:-}" || -n "${SN_MINES[$nx,$ny]:-}" || -n "${SN_BLOCKS[$nx,$ny]:-}" ]] && return 0
  (( nx == ax && ny == ay )) && return 0
  [[ "$nx,$ny" == "$SN_FOOD" || "$nx,$ny" == "$SN_GEM" ]] && return 0
  unset "SN_MINES[$pick]"; SN_MINES[$nx,$ny]=1
  return 0 }

# ── the drawing · the body's gradient and shimmer come out of two tables ──
typeset -ga SN_GRAD SN_GRADBG; typeset -gi SN_GRADN=0
sn_grad_build() {   # 32 steps LIME→tail, each at 8 shimmer phases · 512 colours, once
  local -i g p col; local -F f
  SN_GRAD=(); SN_GRADBG=()
  for (( g = 0; g < 32; g++ )); do
    f=$(( g / 31.0 ))
    for (( p = 0; p < 8; p++ )); do
      cmix $LIME $SN_TAIL $f; cmix $CM $CYAN $(( 0.22 * (0.5 + 0.5 * sin(p * TAU / 8.0)) )); col=$CM
      SN_GRAD+=($col); cmix $GLASS $col 0.09; SN_GRADBG+=($CM)
    done
  done
  SN_GRADN=1; return 0 }
sn_paint() {   # sn_paint T
  local -F t=$1 p f k; local -i ox=$SNAKE_OX oy=$SNAKE_OY edge cy cx i n idx g ph col bg x y hy lit age py px
  local c grid row s
  (( SN_GRADN )) || sn_grad_build
  if (( SN_WRAP )); then edge=$LIME; else edge=${AR_DC[$AR_DI]}; fi
  ar_wave $t 0.25; cmix $edge $CYAN $(( 0.30 + 0.15 * WV ))
  if (( SN_WRAP )); then a_box 0 $AR_FT $AR_W $(( AR_H - AR_FT )) $CM $GLASS double 0; else a_box 0 $AR_FT $AR_W $(( AR_H - AR_FT )) $CM $GLASS heavy 0; fi
  cshade $PURPLE 0.32; grid=$CS
  for (( cy = 0; cy < SNAKE_GH; cy++ )); do
    row=''; for (( cx = 0; cx < SNAKE_GW; cx++ )); do if (( (cx + cy) % 2 == 0 )); then row+='· '; else row+='  '; fi; done
    a_text $ox $(( oy + cy )) "${row%?}" $grid -2
  done
  cmix $PURPLE $CYAN 0.35; cshade $CM 0.55; col=$CS; cmix $GLASS $PURPLE 0.16; bg=$CM
  for c in ${(k)SN_BLOCKS[@]}; do a_text $(( ox + ${c%%,*} * 2 )) $(( oy + ${c#*,} )) '██' $col $bg; done
  cmix $GLASS $RED 0.14; bg=$CM
  for c in ${(k)SN_MINES[@]}; do
    x=${c%%,*}; ar_wave $t 0.4 $(( x * 0.3 )); cshade $RED $(( 0.75 + 0.2 * WV ))
    if (( SN_CREEP )); then a_text $(( ox + x * 2 )) $(( oy + ${c#*,} )) '▞▚' $CS $bg; else a_text $(( ox + x * 2 )) $(( oy + ${c#*,} )) '▚▞' $CS $bg; fi
  done
  n=$SN_LN
  local -i blink=0; (( ! AR_ALIVE && int(t * 12) % 2 == 0 )) && blink=1
  cmix $RED $WHITE 0.45; local -i bl=$CM; cmix $GLASS $bl 0.09; local -i blbg=$CM
  cmix $WHITE $LIME 0.30; local -i hc=$CM; cmix $GLASS $hc 0.09; local -i hbg=$CM
  for (( i = 0; i < n; i++ )); do
    idx=$(( (SN_HD + i) % SN_N )); cx=${SN_BX[$idx]}; cy=${SN_BY[$idx]}
    if (( blink )); then a_text $(( ox + cx * 2 )) $(( oy + cy )) '██' $bl $blbg
    elif (( i == 0 )); then a_text $(( ox + cx * 2 )) $(( oy + cy )) '██' $hc $hbg
    else
      f=$(( (i / (n - 1.0 > 1.0 ? n - 1.0 : 1.0)) * 1.15 )); (( f > 1.0 )) && f=1.0
      g=$(( int(f * 31) ))
      p=$(( t * 0.55 - i * 0.32 / TAU )); p=$(( p - floor(p) )); ph=$(( int(p * 8) % 8 ))
      a_text $(( ox + cx * 2 )) $(( oy + cy )) '██' ${SN_GRAD[$(( g * 8 + ph ))]} ${SN_GRADBG[$(( g * 8 + ph ))]}
    fi
  done
  if [[ -n "$SN_FOOD" ]]; then
    ar_wave $t 1.7; p=$(( 0.55 + 0.45 * WV ))
    cmix $AMBER $WHITE $(( 0.35 * p )); col=$CM; cmix $GLASS $AMBER $(( 0.16 * p ))
    a_text $(( ox + ${SN_FOOD%%,*} * 2 )) $(( oy + ${SN_FOOD#*,} )) '◆◆' $col $CM
  fi
  if [[ -n "$SN_GEM" ]]; then
    ar_wave $t 3.2; p=$(( 0.5 + 0.5 * WV ))
    cmix $MAGENTA $WHITE $(( 0.5 * p )); col=$CM; cmix $GLASS $MAGENTA $(( 0.2 * p ))
    a_text $(( ox + ${SN_GEM%%,*} * 2 )) $(( oy + ${SN_GEM#*,} )) '★★' $col $CM
    k=$(( (SN_GEMLIFE - (AR_RT - SN_GEMT)) / SN_GEMLIFE )); (( k < 0.0 )) && k=0.0; (( k > 1.0 )) && k=1.0
    lit=$(( int(8 * k + 0.5) )); s='★ '; for (( i = 0; i < 8; i++ )); do (( i < lit )) && s+='▮' || s+='▯'; done
    cmix $MAGENTA $WHITE 0.3; ar_plate $(( AR_W - 14 )) $AR_FT "$s" $CM $GLASS
  fi
  if (( ! AR_ALIVE && SN_DEAD && SN_DX >= 0 && SN_DX < SNAKE_GW && SN_DY >= 0 && SN_DY < SNAKE_GH )); then
    cmix $RED $WHITE 0.4; col=$CM; cmix $GLASS $RED 0.30; a_text $(( ox + SN_DX * 2 )) $(( oy + SN_DY )) '▚▞' $col $CM
  fi
  # THE CHAIN, WHERE YOU CAN SEE IT DYING · the bar is the whole point
  if (( SN_CHAIN )); then
    k=$(( SN_CHAINL / (SN_CHAINW > 0 ? SN_CHAINW + 0.0 : 1.0) )); (( k > 1.0 )) && k=1.0; (( k < 0.0 )) && k=0.0
    local -i mult=$SN_CHAIN; (( mult > SNK_CHAIN_MAX )) && mult=$SNK_CHAIN_MAX
    cmix $AMBER $MAGENTA $(( (mult - 1) / 4.0 > 1.0 ? 1.0 : (mult - 1) / 4.0 )); col=$CM
    lit=$(( int(8 * k + 0.5) )); s="CHAIN ×$mult "; for (( i = 0; i < 8; i++ )); do (( i < lit )) && s+='▮' || s+='▯'; done
    cmix $col $WHITE 0.35; ar_plate 3 $AR_FT "$s" $CM $GLASS
  fi
  hy=${SN_BY[$SN_HD]}
  local -a kx ky kt ktx kc; kx=(); ky=(); kt=(); ktx=(); kc=()
  for (( i = 0; i < ${#SN_PT[@]}; i++ )); do
    age=$(( AR_RT - SN_PT[i] ))
    (( age > 0.75 )) && continue
    kx+=(${SN_PX[$i]}); ky+=(${SN_PY[$i]}); kt+=(${SN_PT[$i]}); ktx+=("${SN_PTXT[$i]}"); kc+=(${SN_PCOL[$i]})
    (( age < 0.0 )) && continue
    py=$(( oy + SN_PY[i] - 1 - int(age * 5.5) ))
    (( py >= AR_FT + 1 && py <= AR_H - 2 && py != oy + hy )) || continue
    px=$(( ox + SN_PX[i] * 2 - ${#SN_PTXT[$i]} / 2 )); (( px < 1 )) && px=1; (( px > AR_W - 1 - ${#SN_PTXT[$i]} )) && px=$(( AR_W - 1 - ${#SN_PTXT[$i]} ))
    cshade ${SN_PCOL[$i]} $(( 1.0 - age / 0.75 )); a_text $px $py "${SN_PTXT[$i]}" $CS -2
  done
  SN_PX=("${kx[@]}"); SN_PY=("${ky[@]}"); SN_PT=("${kt[@]}"); SN_PTXT=("${ktx[@]}"); SN_PCOL=("${kc[@]}")
  return 0 }
sn_hud() {
  ar_pad $SN_LN 3; AR_HL=(LEN); AR_HV=("$REPLY"); AR_HC=($LIME)
  if (( SN_CHAIN > 1 )); then local -i m=$SN_CHAIN; (( m > SNK_CHAIN_MAX )) && m=$SNK_CHAIN_MAX; cmix $AMBER $WHITE 0.3; AR_HL+=(CHAIN); AR_HV+=("×$m"); AR_HC+=($CM); fi
  return 0 }
sn_stats() { AR_SL=(LENGTH LEVEL GEMS 'BEST CHAIN'); AR_SV=($SN_LN $AR_LEVEL $SN_GEMS $SN_BESTCHAIN); return 0 }

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# NEON SNAKE · breadth-first to the nearest prize, the tail cell counted free
typeset -g SN_BOT_KEY='' ; typeset -g SN_BOT_AT=''
sn_demo() {
  local target="${SN_GEM:-$SN_FOOD}" cell nxt; local -i hx=${SN_BX[$SN_HD]} hy=${SN_BY[$SN_HD]} ti tx ty qh qt x y d nx ny
  [[ -n "$target" ]] || return 0
  # the plan holds while the head and the prize stay where they were
  if [[ "$SN_BOT_AT" == "$hx,$hy>$target" && -n "$SN_BOT_KEY" ]]; then AR_DKEYS+=($SN_BOT_KEY); return 0; fi
  ti=$(( (SN_HD + SN_LN - 1) % SN_N )); tx=${SN_BX[$ti]}; ty=${SN_BY[$ti]}
  local -A seen; local -a qx qy; seen=(); seen[$hx,$hy]=S; qx=($hx); qy=($hy); qh=0; qt=1
  while (( qh < qt )); do
    x=${qx[$qh]}; y=${qy[$qh]}; qh=$(( qh + 1 ))
    [[ "$x,$y" == "$target" ]] && break
    for d in 0 1 2 3; do
      case $d in 0) nx=$x; ny=$(( y - 1 )) ;; 1) nx=$x; ny=$(( y + 1 )) ;; 2) nx=$(( x - 1 )); ny=$y ;; *) nx=$(( x + 1 )); ny=$y ;; esac
      if (( SN_WRAP )); then nx=$(( (nx + SNAKE_GW) % SNAKE_GW )); ny=$(( (ny + SNAKE_GH) % SNAKE_GH )); fi
      (( nx < 0 || ny < 0 || nx >= SNAKE_GW || ny >= SNAKE_GH )) && continue
      nxt="$nx,$ny"
      [[ -n "${seen[$nxt]:-}" || -n "${SN_MINES[$nxt]:-}" || -n "${SN_BLOCKS[$nxt]:-}" ]] && continue
      [[ -n "${SN_FILLED[$nxt]:-}" ]] && ! (( nx == tx && ny == ty )) && continue
      seen[$nxt]="$x,$y"; qx[$qt]=$nx; qy[$qt]=$ny; qt=$(( qt + 1 ))
    done
  done
  [[ -n "${seen[$target]:-}" ]] || { SN_BOT_KEY=''; SN_BOT_AT=''; return 0; }
  cell="$target"
  while [[ "${seen[$cell]}" != S && "${seen[$cell]}" != "$hx,$hy" ]]; do cell="${seen[$cell]}"; done
  x=$(( ${cell%%,*} - hx )); y=$(( ${cell#*,} - hy ))
  if (( SN_WRAP )); then (( x > 1 )) && x=-1; (( x < -1 )) && x=1; (( y > 1 )) && y=-1; (( y < -1 )) && y=1; fi
  if (( y < 0 )); then SN_BOT_KEY=UP; elif (( y > 0 )); then SN_BOT_KEY=DOWN; elif (( x < 0 )); then SN_BOT_KEY=LEFT; else SN_BOT_KEY=RIGHT; fi
  SN_BOT_AT="$hx,$hy>$target"; AR_DKEYS+=($SN_BOT_KEY)
  return 0 }

# ── the preview · the menu's ARCADE DATA picture of this machine (moved here from c_shell) ──
typeset -ga PVS_F PVS_B; typeset -g PVS_AT=''
pv_snake() {   # the datastream, eating itself round a serpentine
  # A BIG PREVIEW IS HUNDREDS OF CELLS · the body's fade is mixed once, in 24
  # steps, and each cell goes straight into the grid when the glass is whole
  local -i x=$1 y=$2 w=$3 h=$4 head body i r c idx j off n q base px
  n=$(( w * h ))
  head=$(( int(AR_T * 13) % n ))
  body=$(( int(w * h * 0.30) )); (( body < 8 )) && body=8; (( body > n - 6 )) && body=$(( n - 6 ))
  (( body > 240 )) && body=240                  # a big box gets a long snake, not a slow one
  if [[ "$PVS_AT" != "$AR_PVBG:$LIME" ]]; then
    local -i dk; _pack 18 82 64; dk=$PK; PVS_F=(); PVS_B=()
    for (( q = 0; q < 24; q++ )); do cmix $LIME $dk $(( q / 23.0 )); PVS_F+=($CM); cmix $AR_PVBG $LIME $(( 0.12 * (1.0 - q / 23.0) )); PVS_B+=($CM); done
    PVS_AT="$AR_PVBG:$LIME"
  fi
  base=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX + x ))
  for (( i = 0; i < body; i++ )); do
    idx=$(( (head - i + n) % n )); r=$(( idx / w )); c=$(( idx % w ))
    (( r % 2 )) && c=$(( w - 1 - c ))
    q=$(( i * 24 / body ))
    if (( AR_DIRECT )); then
      px=$(( base + r * TCOLS + c ))
      if (( i == 0 )); then GCH[$px]='█'; elif (( i * 20 < body * 9 )); then GCH[$px]='▓'; else GCH[$px]='▒'; fi
      GF[$px]=${PVS_F[$q]}; GB[$px]=${PVS_B[$q]}
    elif (( i == 0 )); then a_put $(( x + c )) $(( y + r )) '█' ${PVS_F[$q]} ${PVS_B[$q]}
    elif (( i * 20 < body * 9 )); then a_put $(( x + c )) $(( y + r )) '▓' ${PVS_F[$q]} ${PVS_B[$q]}
    else a_put $(( x + c )) $(( y + r )) '▒' ${PVS_F[$q]} ${PVS_B[$q]}; fi
  done
  local -a offs; offs=(17 41 73)
  for (( j = 0; j < 3; j++ )); do
    off=${offs[$j]}; idx=$(( (head + off) % n )); r=$(( idx / w )); c=$(( idx % w )); (( r % 2 )) && c=$(( w - 1 - c ))
    ar_wave $AR_T 1.6 $(( j * 2.0 ))
    (( WV > 0.2 )) && { cmix $AR_PVBG $AMBER 0.18; a_put $(( x + c )) $(( y + r )) '◆' $AMBER $CM; }
  done
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15c · THE STEER          arcade.py's impulse-and-damping stick, for every paddle
# ══════════════════════════════════════════════════════════════════════════
# Terminals never say when a key is released, only that it repeated, so
# holding a direction arrives as a burst of presses.  An impulse and an
# exponential decay integrated EXACTLY turn that into a joystick that
# travels the same distance for the same held key at twenty frames a second
# or a hundred and forty.  Four sticks, by index; a game claims what it needs.
typeset -ga ST_V ST_ACC ST_DAMP ST_MAX
st_set() {   # st_set I ACCEL DAMP VMAX
  ST_V[$1]=0.0; ST_ACC[$1]=$2; ST_DAMP[$1]=$3; ST_MAX[$1]=$4; return 0 }
st_push() {  # st_push I DIR
  local -i i=$1; local -F v
  v=$(( ST_V[i] + $2 * ST_ACC[i] * 0.055 ))
  (( v > ST_MAX[i] )) && v=${ST_MAX[$i]}; (( v < -ST_MAX[i] )) && v=$(( -ST_MAX[i] ))
  ST_V[$i]=$v; return 0 }
st_glide() { # st_glide I DT → RF the distance moved this frame
  local -i i=$1; local -F dt=$2 decay
  if (( ST_V[i] == 0.0 )); then RF=0.0; return 0; fi
  decay=$(( exp(-ST_DAMP[i] * dt) ))
  RF=$(( ST_V[i] * (1.0 - decay) / ST_DAMP[i] ))
  ST_V[$i]=$(( ST_V[i] * decay ))
  (( ST_V[i] < 0.02 && ST_V[i] > -0.02 )) && ST_V[$i]=0.0
  return 0 }
st_stop() { ST_V[$1]=0.0; return 0 }
ar_tri() {   # ar_tri U → RF · a triangle wave 0..1..0 with period 1
  local -F u=$1; u=$(( u - floor(u) )); if (( u < 0.5 )); then RF=$(( u * 2.0 )); else RF=$(( 2.0 - u * 2.0 )); fi; return 0 }
ar_split_keys() {   # two-up · WASD is player two and nothing else, the arrows player one
  # → AR_K1 / AR_K2 · in a one-up round both sets drive the only player there is
  AR_K1=(); AR_K2=(); local k
  if (( AR_TWO )); then
    for k in "${AR_KEYS[@]}"; do case "$k" in W) AR_K2+=(UP) ;; S) AR_K2+=(DOWN) ;; A) AR_K2+=(LEFT) ;; D) AR_K2+=(RIGHT) ;; *) AR_K1+=("$k") ;; esac; done
  else AR_K1=("${AR_KEYS[@]}"); fi
  return 0 }
typeset -ga AR_K1 AR_K2
ar_f1() {   # ar_f1 X → REPLY "x.d" · one decimal, no printf
  local -i t=$(( int($1 * 10 + 0.5) )); (( t < 0 )) && t=0; REPLY="$(( t / 10 )).$(( t % 10 ))"; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15f · V O I D   P O N G        (sports) · the original · two paddles, one photon
# ══════════════════════════════════════════════════════════════════════════
# The machine reads the ball perfectly, so its weakness has to be deliberate:
# it re-aims only every `react` seconds and commits to a point that is wrong
# by up to `slop` rows, and its top speed is under the ball's.  THE POST is
# Atari's block on the centre line, dealt as one, two or three in MIRRORED
# pairs, so no end of the court is the good end.  A second player takes the
# other paddle with the same physics the first has, not the machine's.
#
# THE COURT IS THE BOARD.  arcade.py's court ran between paddles at columns
# 3 and 68 and rails at rows 2 and 16 of a 72 × 18 tube; here it runs between
# whatever the round was dealt, and VP_KX × VP_KY is how much bigger that is.
# The rally is timed, not measured: the photon's pace is kept in the
# original's cells and scaled onto this court as it flies, so a return
# crosses a wide court in the time it crossed the old one and climbs a tall
# one at the angle it climbed the old one.  Everything that answers it
# scales the same way -- the paddles' reach, the machine's speed and its
# slop, the stick, the posts -- and nothing that is a time (the machine's
# react, the serve's wait) moves at all.
typeset -gi VP_TOP VP_BOT VP_LX VP_RX VP_POSTX VP_POSTH VP_SET=11 VP_SCX
typeset -gi VP_PH VP_POST VP_YOU VP_THEM VP_SETS VP_RALLY VP_BEST VP_HITS VP_PAID VP_NP
typeset -gF VP_KX=1.0 VP_KY=1.0 VP_REACH=2.0 VP_SWEET=0.0 VP_EDGE=0.5   # the court over the original's 65 × 14 · the save's reach · the sweet spot's drop · the paddle's half-row
typeset -gF VP_REACT VP_AISPD VP_SLOP VP_SPD0 VP_SPDMAX VP_PY VP_AY VP_AIM VP_AIMT VP_AIVY VP_FLASH
typeset -gF VP_BX VP_BY VP_VX VP_VY VP_WAIT
typeset -ga VP_PX VP_PHT VP_PYY VP_PV        # the posts · column height row drift
typeset -ga VP_SX VP_SY VP_ST                # sparks
typeset -g  VP_RAILT='' VP_RAILB=''          # the two rails, built once a board
vp_board() {   # the court, from the board this round was dealt
  local -i i
  VP_TOP=$(( AR_FT + 1 )); VP_BOT=$(( AR_H - 2 ))          # inside the rails
  # the paddles stand in from the ends by the court's own measure (three
  # columns of the original's), so the reach behind them fits on the glass
  VP_LX=$(( int(3 * (AR_W - 7) / 65.0 + 0.5) )); (( VP_LX < 3 )) && VP_LX=3
  VP_RX=$(( AR_W - 1 - VP_LX )); VP_POSTX=$(( AR_W / 2 ))
  VP_KX=$(( (VP_RX - VP_LX) / 65.0 )); VP_KY=$(( (VP_BOT - VP_TOP) / 14.0 ))
  (( VP_KX < 0.5 )) && VP_KX=0.5; (( VP_KY < 0.5 )) && VP_KY=0.5
  # A LATE PADDLE STILL SAVES IT while the photon is within two of the
  # original's cells past its face -- a time, not a distance, so it scales:
  # a fixed two cells at this court's pace is crossed inside one frame, and
  # the save a player earned by arriving late never gets a frame to happen
  VP_REACH=$(( 2.0 * VP_KX ))
  # THE SWEET SPOT IS A ROW OF THE ORIGINAL'S.  arcade.py drew and stopped the
  # photon with a paddle's rows from int(y), and reckoned the return from y,
  # so the middle of a return sat -- on average -- one of its rows below the
  # middle of the rows that stopped it.  That row is what put the machine's
  # paddle a row off its own aim, and what bent a dead-centre hit upward; on
  # a court of finer rows it would shrink to a fraction of a row and the
  # machine would stop missing.  So it is kept a row of the ORIGINAL's: the
  # return is reckoned VP_SWEET cells further down, and the machine (and
  # the demonstrator) aim that much higher to meet it.
  VP_SWEET=$(( VP_KY - 1.0 ))
  vp_rows 3; VP_POSTH=$REPLY
  VP_SCX=$(( int(6 * VP_KX + 0.5) ))                      # the scores stand off the net by the court's width
  VP_RAILT=''; VP_RAILB=''; for (( i = 0; i < AR_W; i++ )); do VP_RAILT+='▁'; VP_RAILB+='▔'; done
  return 0 }
vp_rows() {   # vp_rows N → REPLY · N rows of the original's court on this one
  # a block of N rows stops the photon over N rows (half a row over its top,
  # half a row short of its bottom), so the block scales as it stands
  REPLY=$(( int($1 * VP_KY + 0.5) )); (( REPLY < $1 )) && REPLY=$1; return 0 }
vp_begin() {
  AR_G_LEGEND='▲▼ MOVE PADDLE       [P] PAUSE       [Q] CASH OUT'
  AR_G_HOWTO='get it past the machine  ·  the post is in play  ·  three misses'
  AR_G_TWOUP=1; _pack 148 208 255; AR_G_ACC=$PK
  vp_board
  ar_pick 5 4 3 2; local -i ph0=$REPLY; vp_rows $REPLY; VP_PH=$REPLY
  # the rows are whole and the reach is not: what rounding took off (or put
  # on) the paddle is given back as a sliver of tolerance at each end, too
  # thin to see, so the machine misses as often as it did on the old tube
  VP_EDGE=$(( 0.5 + (ph0 * VP_KY - VP_PH) * 0.5 ))
  ar_pick 0.60 0.44 0.30 0.20; VP_REACT=$REPLY
  ar_pick 13.0 18.0 23.0 28.0; VP_AISPD=$(( REPLY * VP_KY ))
  ar_pick 3.8 2.8 2.0 1.5; VP_SLOP=$(( REPLY * VP_KY ))
  ar_pick 20.0 26.0 32.0 38.0; VP_SPD0=$REPLY        # the photon's pace is in the ORIGINAL's cells a second
  ar_pick 38.0 48.0 58.0 68.0; VP_SPDMAX=$REPLY      # ...and VP_KX × VP_KY puts it on this court
  ar_pick 0 0 1 2; VP_POST=$REPLY
  VP_PX=(); VP_PHT=(); VP_PYY=(); VP_PV=(); VP_NP=0
  (( VP_POST )) && vp_court
  VP_HITS=0; VP_PAID=-1; AR_LIVES=3; VP_YOU=0; VP_THEM=0; VP_SETS=0; VP_RALLY=0; VP_BEST=0
  st_set 0 $(( 210.0 * VP_KY )) 9.0 $(( 34.0 * VP_KY )); st_set 1 $(( 210.0 * VP_KY )) 9.0 $(( 34.0 * VP_KY ))
  if (( AR_PLAYERS == 2 )); then
    AR_G_LEGEND='▲▼ ONE     [W]/[S] TWO     [P] PAUSE     [Q] CASH OUT'
    AR_G_HOWTO='left is the arrows, right is W and S  ·  three misses ends it'
  fi
  VP_PY=$(( (VP_TOP + VP_BOT) * 0.5 - VP_PH * 0.5 )); VP_AY=$VP_PY
  VP_AIM=$(( (VP_TOP + VP_BOT) * 0.5 )); VP_AIMT=0.0; VP_AIVY=0.0; VP_FLASH=0.0
  VP_SX=(); VP_SY=(); VP_ST=()
  vp_serve 1
  return 0 }
vp_one() {   # vp_one X → appends a post · a height, a row inside the rails, a drift
  local -i x=$1 h span; local -F y v
  rnd_pick 4; case $REPLY in 0) h=2 ;; 1|2) h=3 ;; *) h=4 ;; esac
  vp_rows $h; h=$REPLY
  span=$(( VP_BOT - VP_TOP + 1 - h )); (( span < 0 )) && span=0
  rnd_uni 0.10 0.90; y=$(( VP_TOP + RF * span ))
  rnd_pick 2; rnd_uni 5.0 9.5; if (( REPLY )); then v=$(( RF * VP_KY )); else v=$(( -RF * VP_KY )); fi
  VP_PX+=($x); VP_PHT+=($h); VP_PYY+=($y); VP_PV+=($v); return 0 }
vp_court() {   # one, two or three posts, mirrored about the centre line · dealt until it fits
  local -i try n off i ok
  for (( try = 0; try < 24; try++ )); do
    VP_PX=(); VP_PHT=(); VP_PYY=(); VP_PV=()
    rnd_pick 5; case $REPLY in 0|1) n=1 ;; 2|3) n=2 ;; *) n=3 ;; esac
    if (( n == 1 )); then vp_one $VP_POSTX
    else
      rnd_pick 4; case $REPLY in 0) off=5 ;; 1) off=7 ;; 2) off=9 ;; *) off=11 ;; esac
      off=$(( int(off * VP_KX + 0.5) ))
      vp_one $(( VP_POSTX - off )); vp_one $(( VP_POSTX + off ))
      VP_PHT[1]=${VP_PHT[0]}; VP_PYY[1]=$(( VP_BOT - (VP_PYY[0] - VP_TOP) - VP_PHT[0] + 1 )); VP_PV[1]=$(( -VP_PV[0] ))
      (( n == 3 )) && vp_one $VP_POSTX
    fi
    ok=1
    for (( i = 0; i < ${#VP_PX[@]}; i++ )); do
      (( VP_PX[i] > VP_LX + 6 * VP_KX && VP_PX[i] < VP_RX - 6 * VP_KX )) || ok=0
      (( VP_PYY[i] >= VP_TOP && VP_PYY[i] <= VP_BOT - VP_PHT[i] + 1 )) || ok=0
    done
    (( ok )) && { VP_NP=${#VP_PX[@]}; return 0; }
  done
  VP_PX=($VP_POSTX); VP_PHT=($VP_POSTH); VP_PYY=($(( (VP_TOP + VP_BOT) * 0.5 - VP_POSTH * 0.5 ))); VP_PV=($(( 7.0 * VP_KY ))); VP_NP=1
  return 0 }
vp_serve() {   # vp_serve TOWARDS
  VP_BX=$(( AR_W * 0.5 )); VP_BY=$(( (VP_TOP + VP_BOT) * 0.5 ))
  rnd_uni -0.5 0.5; VP_VX=$(( VP_SPD0 * VP_KX * $1 )); VP_VY=$(( VP_SPD0 * VP_KY * RF ))
  VP_RALLY=0; VP_WAIT=0.9; return 0 }
vp_on_paddle() {   # vp_on_paddle PADDLE_Y · quantised the way the painter quantises it
  local -i top=$(( int($1) )); (( top - VP_EDGE <= VP_BY && VP_BY <= top + VP_PH - 1 + VP_EDGE )) }
vp_bounce() {   # vp_bounce PADDLE_Y DIRECTION ENGLISH · worked in the original's cells, flown in this court's
  local -F py=$1 dir=$2 eng hit swipe speed angle u w
  eng=$(( $3 / VP_KY )); u=$(( VP_VX / VP_KX )); w=$(( VP_VY / VP_KY ))
  hit=$(( (VP_BY - (py + VP_PH * 0.5 + VP_SWEET)) / (VP_PH * 0.5 > 1.0 ? VP_PH * 0.5 : 1.0) ))
  swipe=$(( (eng < 0 ? -eng : eng) / 30.0 )); (( swipe > 1.0 )) && swipe=1.0
  speed=$(( sqrt(u * u + w * w) * (1.06 + 0.05 * swipe) + 1.2 )); (( speed > VP_SPDMAX )) && speed=$VP_SPDMAX
  (( hit > 1.0 )) && hit=1.0; (( hit < -1.0 )) && hit=-1.0; angle=$(( hit * 0.85 ))
  VP_VX=$(( dir * speed * cos(angle * 0.9) * VP_KX )); VP_VY=$(( (speed * sin(angle * 0.9) + eng * 0.10) * VP_KY ))
  VP_RALLY=$(( VP_RALLY + 1 )); (( VP_RALLY > VP_BEST )) && VP_BEST=$VP_RALLY
  ar_add $(( 5 * AR_LEVEL + int(6 * swipe) ))
  VP_SX+=($VP_BX); VP_SY+=($VP_BY); VP_ST+=(0.0)
  ar_snd move; return 0 }
vp_update() {   # vp_update DT
  local -F dt=$1 prev travel target want step; local -i span i; local k
  ar_split_keys
  for k in "${AR_K1[@]}"; do case "$k" in UP|W) st_push 0 -1 ;; DOWN|S) st_push 0 1 ;; esac; done
  st_glide 0 $dt; VP_PY=$(( VP_PY + RF )); (( VP_PY < VP_TOP )) && VP_PY=$VP_TOP; (( VP_PY > VP_BOT - VP_PH + 1 )) && VP_PY=$(( VP_BOT - VP_PH + 1 ))
  if (( AR_TWO )); then
    for k in "${AR_K2[@]}"; do case "$k" in UP) st_push 1 -1 ;; DOWN) st_push 1 1 ;; esac; done
    prev=$VP_AY; st_glide 1 $dt; VP_AY=$(( VP_AY + RF )); (( VP_AY < VP_TOP )) && VP_AY=$VP_TOP; (( VP_AY > VP_BOT - VP_PH + 1 )) && VP_AY=$(( VP_BOT - VP_PH + 1 ))
    VP_AIVY=$(( (VP_AY - prev) / (dt > 0.000001 ? dt : 0.000001) ))
  fi
  local -a kx ky kt; kx=(); ky=(); kt=()
  for (( i = 0; i < ${#VP_ST[@]}; i++ )); do VP_ST[$i]=$(( VP_ST[i] + dt )); (( VP_ST[i] > 0.3 )) && continue; kx+=(${VP_SX[$i]}); ky+=(${VP_SY[$i]}); kt+=(${VP_ST[$i]}); done
  VP_SX=("${kx[@]}"); VP_SY=("${ky[@]}"); VP_ST=("${kt[@]}")
  if (( VP_WAIT > 0 )); then VP_WAIT=$(( VP_WAIT - dt )); return 0; fi
  if (( AR_TWO )); then vp_advance $dt; return 0; fi
  # the machine commits to an aim point and then stops looking
  VP_AIMT=$(( VP_AIMT - dt ))
  if (( VP_VX > 0 && VP_AIMT <= 0.0 )); then
    VP_AIMT=$VP_REACT
    travel=$(( (VP_RX - VP_BX) / (VP_VX > 1.0 ? VP_VX : 1.0) )); target=$(( VP_BY + VP_VY * travel ))
    span=$(( VP_BOT - VP_TOP ))
    while (( target < VP_TOP || target > VP_BOT )); do
      (( target < VP_TOP )) && target=$(( 2 * VP_TOP - target ))
      (( target > VP_BOT )) && target=$(( 2 * VP_BOT - target ))
      span=$(( span - 1 )); (( span <= 0 )) && break
    done
    rnd_uni $(( -VP_SLOP )) $VP_SLOP; VP_AIM=$(( target + RF ))
  elif (( VP_VX < 0 && VP_AIMT <= 0.0 )); then VP_AIMT=$VP_REACT; VP_AIM=$(( (VP_TOP + VP_BOT) * 0.5 )); fi
  want=$(( VP_AIM - VP_PH * 0.5 - VP_SWEET )); step=$(( want - VP_AY ))
  (( step > VP_AISPD * dt )) && step=$(( VP_AISPD * dt )); (( step < -VP_AISPD * dt )) && step=$(( -VP_AISPD * dt ))
  prev=$VP_AY; VP_AY=$(( VP_AY + step )); (( VP_AY < VP_TOP )) && VP_AY=$VP_TOP; (( VP_AY > VP_BOT - VP_PH + 1 )) && VP_AY=$(( VP_BOT - VP_PH + 1 ))
  VP_AIVY=$(( (VP_AY - prev) / (dt > 0.000001 ? dt : 0.000001) ))
  vp_advance $dt
  return 0 }
vp_post_move() { local -F dt=$1; local -i i
  (( VP_POST < 2 )) && return 0
  for (( i = 0; i < VP_NP; i++ )); do
    VP_PYY[$i]=$(( VP_PYY[i] + VP_PV[i] * dt ))
    if (( VP_PYY[i] <= VP_TOP )); then VP_PYY[$i]=$(( VP_TOP + 0.0 )); VP_PV[$i]=$(( VP_PV[i] < 0 ? -VP_PV[i] : VP_PV[i] ))
    elif (( VP_PYY[i] >= VP_BOT - VP_PHT[i] + 1 )); then VP_PYY[$i]=$(( VP_BOT - VP_PHT[i] + 1.0 )); VP_PV[$i]=$(( VP_PV[i] > 0 ? -VP_PV[i] : VP_PV[i] )); fi
  done; return 0 }
vp_hit_post() {   # vp_hit_post WAS_X → 0 if the ball crossed a post THROUGH it
  local -F was=$1; local -i i lo hi hit=-1
  for (( i = 0; i < VP_NP; i++ )); do
    (( (was - VP_PX[i]) * (VP_BX - VP_PX[i]) > 0 )) && continue
    lo=$(( int(VP_PYY[i] + 0.5) )); hi=$(( lo + (VP_PHT[i] > 1 ? int(VP_PHT[i]) : 1) - 1 ))
    (( lo - 0.5 <= VP_BY && VP_BY <= hi + 0.5 )) && { hit=$i; break; }
  done
  (( hit < 0 )) && return 1
  VP_BX=$was; VP_VX=$(( -VP_VX )); VP_HITS=$(( VP_HITS + 1 ))
  # ONCE A RALLY, AND A SMALL ONCE · it is a deflector, not a target
  (( VP_PAID != VP_RALLY )) && { VP_PAID=$VP_RALLY; ar_add $(( 5 * AR_LEVEL )); }
  VP_SX+=(${VP_PX[$hit]}); VP_SY+=($VP_BY); VP_ST+=(0.0); ar_snd move
  return 0 }
vp_advance() {   # the ball, in slices small enough that nothing tunnels
  local -F dt=$1 remain=$1 sl was avx
  vp_post_move $dt
  while (( remain > 0.0001 )); do
    avx=$(( VP_VX < 0 ? -VP_VX : VP_VX )); (( avx < 1.0 )) && avx=1.0
    sl=$(( 0.9 / avx )); (( sl > remain )) && sl=$remain; remain=$(( remain - sl ))
    was=$VP_BX; VP_BX=$(( VP_BX + VP_VX * sl )); VP_BY=$(( VP_BY + VP_VY * sl ))
    (( VP_NP )) && vp_hit_post $was
    if (( VP_BY <= VP_TOP )); then VP_BY=$(( VP_TOP + (VP_TOP - VP_BY) )); VP_VY=$(( VP_VY < 0 ? -VP_VY : VP_VY )); ar_snd move
    elif (( VP_BY >= VP_BOT )); then VP_BY=$(( VP_BOT - (VP_BY - VP_BOT) )); VP_VY=$(( VP_VY > 0 ? -VP_VY : VP_VY )); ar_snd move; fi
    if (( VP_VX < 0 && VP_BX <= VP_LX + 1 )); then
      if vp_on_paddle $VP_PY; then VP_BX=$(( VP_LX + 1.0 )); vp_bounce $VP_PY 1 ${ST_V[0]}
      elif (( VP_BX < VP_LX + 1 - VP_REACH )); then
        VP_THEM=$(( VP_THEM + 1 )); AR_LIVES=$(( AR_LIVES - 1 )); ar_snd error
        (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
        vp_serve 1; return 0
      fi
    elif (( VP_VX > 0 && VP_BX >= VP_RX - 1 )); then
      if vp_on_paddle $VP_AY; then VP_BX=$(( VP_RX - 1.0 )); vp_bounce $VP_AY -1 $VP_AIVY
      elif (( VP_BX > VP_RX - 1 + VP_REACH )); then
        VP_YOU=$(( VP_YOU + 1 )); ar_add $(( 120 * AR_LEVEL + VP_RALLY * 15 )); ar_snd coin
        if (( VP_YOU >= VP_SET )); then vp_take_set
        else AR_LEVEL=$(( 1 + VP_SETS * 4 + VP_YOU / 2 )); (( AR_LEVEL > 20 )) && AR_LEVEL=20; fi
        vp_serve -1; return 0
      fi
    fi
  done
  return 0 }
vp_take_set() {   # first to eleven · a bonus, a life back, a faster machine
  VP_SETS=$(( VP_SETS + 1 )); ar_add $(( 2500 * VP_SETS ))
  AR_LIVES=$(( AR_LIVES + 1 )); (( AR_LIVES > 3 )) && AR_LIVES=3
  VP_YOU=0; VP_THEM=0; AR_LEVEL=$(( 1 + VP_SETS * 4 )); (( AR_LEVEL > 20 )) && AR_LEVEL=20
  VP_REACT=$(( VP_REACT * 0.82 )); (( VP_REACT < 0.10 )) && VP_REACT=0.10
  VP_AISPD=$(( VP_AISPD * 1.10 )); (( VP_AISPD > 46.0 * VP_KY )) && VP_AISPD=$(( 46.0 * VP_KY ))
  VP_SLOP=$(( VP_SLOP * 0.85 )); (( VP_SLOP < 0.9 * VP_KY )) && VP_SLOP=$(( 0.9 * VP_KY ))
  VP_SPDMAX=$(( VP_SPDMAX * 1.06 )); (( VP_SPDMAX > 74.0 )) && VP_SPDMAX=74.0
  VP_FLASH=2.2; ar_snd coin; return 0 }
vp_paint() {   # vp_paint T
  # THE TALL THINGS GO STRAIGHT INTO THE CELLS.  A paddle on a forty-row
  # court is fourteen cells and the net nineteen; a put a cell was most of
  # what this cost, so the columns are written the way a_rect writes them.
  local -F t=$1 k; local -i acc=$AR_G_ACC y i lo hi px x bg base kk fg top n
  local s tally; local -a pfg
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  cshade $acc 0.55; a_text 0 $AR_FT "$VP_RAILT" $CS -2; a_text 0 $(( AR_H - 1 )) "$VP_RAILB" $CS -2
  # the net, every other row, where no post stands on it
  cshade $GREY 0.40; fg=$CS; px=$(( AR_W / 2 ))
  for (( y = VP_TOP + (VP_TOP % 2); y <= VP_BOT; y += 2 )); do
    n=0
    for (( i = 0; i < VP_NP; i++ )); do
      (( VP_PX[i] == px )) || continue
      lo=$(( int(VP_PYY[i] + 0.5) )); hi=$(( lo + (VP_PHT[i] > 1 ? int(VP_PHT[i]) : 1) - 1 ))
      (( y >= lo && y <= hi )) && { n=1; break; }
    done
    (( n )) && continue
    kk=$(( base + y * TCOLS + px )); GCH[$kk]='┃'; GF[$kk]=$fg
  done
  # the posts, breathing down their rows
  if (( VP_NP )); then
    cmix $GLASS $AMBER 0.18; bg=$CM; pfg=()
    for (( i = 0; i < VP_NP; i++ )); do
      x=$(( int(VP_PX[i]) )); lo=$(( int(VP_PYY[i] + 0.5) )); hi=$(( lo + (VP_PHT[i] > 1 ? int(VP_PHT[i]) : 1) - 1 ))
      (( x < 0 || x >= AR_W )) && continue
      for (( y = lo; y <= hi; y++ )); do
        (( y < 0 || y >= AR_H )) && continue
        if [[ -z "${pfg[$y]:-}" ]]; then ar_wave $t 0.8 $(( y * 0.4 )); cmix $AMBER $WHITE $(( 0.25 + 0.2 * WV )); pfg[$y]=$CM; fi
        kk=$(( base + y * TCOLS + x )); GCH[$kk]='█'; GF[$kk]=${pfg[$y]}; GB[$kk]=$bg
      done
    done
  fi
  cmix $LIME $WHITE 0.3; cshade $CM 0.9; a_text $(( AR_W / 2 - VP_SCX - ${#VP_YOU} )) $(( AR_FT + 1 )) "$VP_YOU" $CS -2
  cmix $RED $WHITE 0.3; cshade $CM 0.9; a_text $(( AR_W / 2 + VP_SCX )) $(( AR_FT + 1 )) "$VP_THEM" $CS -2
  if (( AR_TWO )); then cmix $LIME $WHITE 0.35; cshade $CM 0.95; a_text 2 $(( AR_FT + 1 )) '1P  ▲▼' $CS -2; cmix $MAGENTA $WHITE 0.35; cshade $CM 0.95; a_text $(( AR_W - 9 )) $(( AR_FT + 1 )) '2P  W/S' $CS -2; fi
  # the two paddles, a column each
  cmix $LIME $WHITE 0.25; local -i lc=$CM; cmix $GLASS $LIME 0.10; local -i lb=$CM
  cmix $MAGENTA $WHITE 0.2; local -i mc=$CM; cmix $GLASS $MAGENTA 0.10; local -i mb=$CM
  top=$(( int(VP_PY) ))
  for (( y = top; y < top + VP_PH; y++ )); do (( y >= VP_TOP && y <= VP_BOT )) || continue; kk=$(( base + y * TCOLS + VP_LX )); GCH[$kk]='█'; GF[$kk]=$lc; GB[$kk]=$lb; done
  top=$(( int(VP_AY) ))
  for (( y = top; y < top + VP_PH; y++ )); do (( y >= VP_TOP && y <= VP_BOT )) || continue; kk=$(( base + y * TCOLS + VP_RX )); GCH[$kk]='█'; GF[$kk]=$mc; GB[$kk]=$mb; done
  for (( i = 0; i < ${#VP_ST[@]}; i++ )); do k=$(( 1.0 - VP_ST[i] / 0.3 )); (( k < 0.0 )) && k=0.0; cshade $WHITE $k; a_put $(( int(VP_SX[i]) )) $(( int(VP_SY[i]) )) '◌' $CS -2; done
  cmix $GLASS $WHITE 0.18; a_put $(( int(VP_BX) )) $(( int(VP_BY) )) '●' $WHITE $CM
  ar_rpad "$VP_YOU" 2; s="$REPLY"; tally="SET $(( VP_SETS + 1 ))   ${(l:2:)VP_YOU} - $s  FIRST TO $VP_SET"
  (( AR_TWO )) && tally="TWO UP  ·  $tally"
  cmix $acc $WHITE 0.3; a_text $(( (AR_W - ${#tally}) / 2 )) $(( AR_H - 1 )) "$tally" $CM -2
  if (( VP_FLASH > 0 )); then
    VP_FLASH=$(( VP_FLASH - 1.0 / 60.0 )); (( VP_FLASH < 0.0 )) && VP_FLASH=0.0
    ar_wave $t 2.0; if (( WV > 0.35 )); then cmix $AMBER $WHITE 0.45; else cshade $AMBER 0.9; CM=$CS; fi
    a_center $(( AR_FT + 2 )) "◆  SET $VP_SETS  ◆" $CM -2
  elif (( VP_WAIT > 0 )); then ar_f1 $VP_WAIT; cshade $GREY 1.1; a_center $(( AR_H - 2 )) "◂ serve in $REPLY ▸" $CS -2
  elif (( VP_RALLY >= 4 )); then cmix $AMBER $WHITE 0.25; a_center $(( AR_FT + 1 )) "RALLY $VP_RALLY" $CM -2; fi
  return 0 }
vp_hud() { cmix $AMBER $WHITE 0.2; AR_HL=(RALLY); AR_HV=($VP_BEST); AR_HC=($CM); cmix $LIME $WHITE 0.25; AR_HL+=(SETS); AR_HV+=($VP_SETS); AR_HC+=($CM); return 0 }
vp_stats() { AR_SL=(SETS POINTS 'BEST RALLY' POSTS); AR_SV=($VP_SETS $VP_YOU $VP_BEST $VP_HITS); return 0 }
pv_voidpong() {   # the preview · two paddles chasing a photon, on a court as big as the box
  local -i x=$1 y=$2 w=$3 h=$4 r i px py k c top bot ph fg bx0 by0 j; local -F bx by u tt
  top=0; bot=$(( h - 1 ))
  if (( h >= 9 )); then   # room for the rails and the score, the way the cabinet draws them
    top=1; bot=$(( h - 2 ))
    local rt='' rb=''; for (( i = 0; i < w; i++ )); do rt+='▁'; rb+='▔'; done
    _pack 148 208 255; cshade $PK 0.55; a_text $x $y "$rt" $CS $AR_PVBG; a_text $x $(( y + h - 1 )) "$rb" $CS $AR_PVBG
  fi
  cshade $GREY 0.45; for (( r = top + (top % 2); r <= bot; r += 2 )); do a_put $(( x + w / 2 )) $(( y + r )) '┃' $CS $AR_PVBG; done
  ph=$(( int((bot - top + 1) * 0.35 + 0.5) )); (( ph < 3 )) && ph=3
  ar_tri $(( AR_T * 0.55 )); bx=$(( RF * (w - 5) + 2 )); ar_tri $(( AR_T * 0.41 + 0.3 )); by=$(( top + RF * (bot - top) ))
  for (( i = 0; i < 2; i++ )); do
    if (( i == 0 )); then px=1; c=$LIME; else px=$(( w - 2 )); c=$MAGENTA; fi
    if (( i == (bx < w / 2.0 ? 0 : 1) )); then py=$(( int(by) - ph / 2 )); else ar_tri $(( AR_T * 0.33 + i )); py=$(( top + int((bot - top + 1 - ph) * RF) )); fi
    (( py < top )) && py=$top; (( py > bot - ph + 1 )) && py=$(( bot - ph + 1 ))
    cmix $c $WHITE 0.25; fg=$CM; cmix $AR_PVBG $c 0.12
    for (( k = 0; k < ph; k++ )); do a_put $(( x + px )) $(( y + py + k )) '█' $fg $CM; done
  done
  if (( w >= 30 )); then   # a short wake behind the photon, where there is room for one
    for (( j = 2; j >= 1; j-- )); do
      tt=$(( AR_T - j * 0.05 ))
      ar_tri $(( tt * 0.55 )); u=$(( RF * (w - 5) + 2 )); ar_tri $(( tt * 0.41 + 0.3 ))
      bx0=$(( int(u) )); by0=$(( top + int(RF * (bot - top)) ))
      (( bx0 == int(bx) && by0 == int(by) )) && continue
      cshade $WHITE $(( 0.55 - j * 0.18 )); a_put $(( x + bx0 )) $(( y + by0 )) '·' $CS -2
    done
  fi
  cmix $AR_PVBG $WHITE 0.15; a_put $(( x + int(bx) )) $(( y + int(by) )) '●' $WHITE $CM
  return 0 }

AR_READY[voidpong]=1; AR_PREFIX[voidpong]=vp

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# VOID PONG · meet the photon where it will cross the line, not where it is ·
# chasing it worked on arcade.py's court, where the paddle is never far behind,
# and missed on a wide one, where the photon is a long way off when it turns.
# So it reads the flight the way the machine does -- where the photon crosses
# the left paddle's face, folded off the rails -- and waits there, drifting
# home while the photon is going the other way.  The sweet spot and the slack
# are the court's, like the stick.
# The reading is made again every frame, so a post that bends the flight is
# read as soon as it has.  THE STICK HAS MOMENTUM: a tap is a push, and on a
# tall court one push carries the paddle rows past where it was sent, so it
# taps only while what it is already carrying (its speed over the damping)
# leaves it short -- the difference between a paddle that waits on the line
# and one that shivers about it.
vp_demo() {
  local -F want travel target err glide slack=$(( 0.3 * VP_KY )); local -i guard=0
  if (( VP_VX < 0.0 )); then
    travel=$(( (VP_BX - VP_LX - 1.0) / (VP_VX < -1.0 ? -VP_VX : 1.0) ))
    target=$(( VP_BY + VP_VY * travel ))
    while (( (target < VP_TOP || target > VP_BOT) && guard < 8 )); do
      (( target < VP_TOP )) && target=$(( 2.0 * VP_TOP - target ))
      (( target > VP_BOT )) && target=$(( 2.0 * VP_BOT - target ))
      guard=$(( guard + 1 ))
    done
    want=$(( target - VP_PH * 0.5 - VP_SWEET ))
  else
    want=$(( (VP_TOP + VP_BOT) * 0.5 - VP_PH * 0.5 ))
  fi
  glide=$(( ST_V[0] / (ST_DAMP[0] > 0.1 ? ST_DAMP[0] : 0.1) )); err=$(( want - VP_PY - glide ))
  if (( err > slack )); then AR_DKEYS+=(DOWN); elif (( err < -slack )); then AR_DKEYS+=(UP); fi
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15g · B R I C K   N O V A        (action) · multiball, and a wall that comes to meet you
# ══════════════════════════════════════════════════════════════════════════
# [M] is the capsule the game was missing: it splits every ball on the field
# in two at a spread angle, to four, and the round only ends when the LAST
# one goes past you.  On the two hard rungs the wall CREEPS -- every twenty-
# odd seconds the whole thing drops a row, and if the bottom row reaches the
# paddle it takes a life and snaps back up.  THE WALL IS BUILT, NOT CHOSEN:
# a base shape, one or two carvings over it with generated parameters, a
# generated hard-brick rule, a per-row phase, and a mirror seven times in ten.
typeset -gi BN_TOP=2 BN_BOT=17 BN_BW=4 BN_COLS=17 BN_X0=2 BN_MAXB=4
typeset -gF BN_MINRISE=0.26 BN_HR=1.0 BN_WR=1.0   # the court's height and width over arcade.py's
typeset -ga  BN_DK_KEY BN_DK_NAME BN_DK_COL; BN_DK_KEY=(W S L P M); BN_DK_NAME=(WIDE SLOW LIFE 500 MULTI)
typeset -ga  BN_CUTS; BN_CUTS=(none gaps checker arch columns fortress diamond zigzag notch vee sparse)
typeset -gi BN_PW0 BN_PW BN_STUCK BN_CLEARED BN_MULTIS BN_MOST BN_DROPROW BN_NB BN_ROWS
typeset -gF BN_SPD0 BN_SPDMAX BN_DROPODDS BN_CREEP BN_PX BN_WIDET BN_SLOWT BN_CREEPT
typeset -gA BN_BR                        # "c,r" → hits left
typeset -ga BN_BX BN_BY BN_VX BN_VY      # the balls
typeset -ga BN_DX BN_DY BN_DKI           # the capsules · x y kind-index
typeset -ga BN_PAL
bn_begin() {
  AR_G_LEGEND='◄► MOVE      [SPACE] LAUNCH      [P] PAUSE      [Q] CASH OUT'
  AR_G_HOWTO='clear the wall  ·  catch the capsules  ·  [M] splits the ball'
  AR_G_ACC=$MAGENTA
  BN_DK_COL=($LIME $CYAN $MAGENTA $AMBER $WHITE); BN_PAL=($MAGENTA $PURPLE $BLUE $CYAN $LIME $AMBER)
  ar_pick 13 10 8 6; BN_PW0=$REPLY
  ar_pick 19.0 24.0 29.0 35.0; BN_SPD0=$REPLY
  ar_pick 34.0 42.0 50.0 60.0; BN_SPDMAX=$REPLY
  ar_pick 0.30 0.22 0.16 0.11; BN_DROPODDS=$REPLY
  ar_pick 0.0 0.0 24.0 15.0; BN_CREEP=$REPLY
  # THE WALL AND THE COURT ARE THE BOARD'S · arcade.py's 17 bricks of four from
  # column 2, rows from 2 to the paddle on 17.  Bricks stay four wide until the
  # wall would pass 31 of them, then widen; the ball and the capsules move with
  # the court's height so a rally crosses it in the original's time, and the
  # paddle and its stick grow with the width they have to cover.
  BN_COLS=$(( (AR_W - 4) / 4 )); (( BN_COLS > 31 )) && BN_COLS=31; (( BN_COLS < 17 )) && BN_COLS=17
  BN_BW=$(( (AR_W - 4) / BN_COLS )); BN_X0=$(( (AR_W - BN_COLS * BN_BW) / 2 ))
  BN_TOP=2; BN_BOT=$(( AR_H - 1 ))
  BN_HR=$(( (BN_BOT - BN_TOP) / 15.0 )); BN_WR=$(( AR_W / 72.0 ))
  BN_SPD0=$(( BN_SPD0 * BN_HR )); BN_SPDMAX=$(( BN_SPDMAX * BN_HR ))
  BN_PW0=$(( int(BN_PW0 * BN_WR + 0.5) ))
  AR_LIVES=3; BN_PW=$BN_PW0; BN_PX=$(( (AR_W - BN_PW) * 0.5 ))
  st_set 0 $(( 260.0 * BN_WR )) 10.0 $(( 52.0 * BN_WR ))
  BN_DX=(); BN_DY=(); BN_DKI=(); BN_WIDET=0.0; BN_SLOWT=0.0; BN_BR=(); BN_CLEARED=0
  BN_BX=(); BN_BY=(); BN_VX=(); BN_VY=(); BN_NB=0; BN_MULTIS=0; BN_MOST=1; BN_DROPROW=0; BN_CREEPT=0.0
  bn_wall; bn_reset_ball
  return 0 }
bn_cut() {   # bn_cut NAME C R → 0 when this cut removes the brick
  local name="$1"; local -i c=$2 r=$3
  case "$name" in
    gaps|zigzag|columns|sparse) c=$(( (c + BN_P_SHIFT + BN_P_ROWS[r % 6]) % BN_COLS )) ;;
  esac
  case "$name" in
    gaps)     (( (r + c) % BN_P_GAP == BN_P_PHASE )) ;;
    checker)  (( (r + c) % 2 && r > 0 )) ;;
    arch)     (( c < r - 1 || c > BN_COLS - r )) ;;
    columns)  (( c % BN_P_COL == BN_P_PHASE % BN_P_COL && r < BN_ROWS - 1 )) ;;
    fortress) (( BN_P_INSET <= c && c <= BN_COLS - 1 - BN_P_INSET && 1 <= r && r <= BN_ROWS - 2 )) ;;
    diamond)  local -F a=$(( c - (BN_COLS - 1) / 2.0 )) b=$(( r - (BN_ROWS - 1) / 2.0 )); (( a < 0 )) && a=$(( -a )); (( b < 0 )) && b=$(( -b ))
              (( a + b < (BN_COLS < BN_ROWS * 2 ? BN_COLS : BN_ROWS * 2) * 0.22 )) ;;
    zigzag)   (( (c + r * BN_P_NOTCH) % (BN_P_GAP + 2) < 2 )) ;;
    notch)    local -i d=$(( c - (BN_COLS - 1) / 2 )); (( d < 0 )) && d=$(( -d )); (( d < BN_P_NOTCH && r >= 1 )) ;;
    vee)      local -F e=$(( c - (BN_COLS - 1) / 2.0 )); (( e < 0 )) && e=$(( -e )); (( e * 2 < (BN_ROWS - r) * 1.6 )) ;;
    sparse)   rnd_f; (( RF < BN_P_SPARSE )) ;;
    *)        return 1 ;;
  esac }
typeset -gi BN_P_GAP BN_P_COL BN_P_PHASE BN_P_INSET BN_P_NOTCH BN_P_SHIFT BN_TOUGH; typeset -gF BN_P_SPARSE; typeset -ga BN_P_ROWS; typeset -g BN_TRULE
bn_hard() {   # bn_hard C R → 0 when the brick takes two hits
  local -i c=$1 r=$2
  (( AR_LEVEL < 3 )) && return 1
  case "$BN_TRULE" in
    top)     (( r < BN_TOUGH )) ;;
    checker) (( (c + r) % 2 == 0 )) ;;
    columns) (( c % 3 == 1 )) ;;
    *)       (( c < 2 || c >= BN_COLS - 2 )) ;;
  esac }
bn_wall() {
  local -i rows r c cc i mirror full n hit; local -a cuts; local nm
  local -A cols
  rows=$(( 3 + AR_LEVEL )); (( rows > 6 )) && rows=6
  rnd_pick 11; cuts=("${BN_CUTS[$REPLY]}")
  rnd_f; (( RF < 0.70 )) && { rnd_pick 11; cuts+=("${BN_CUTS[$REPLY]}"); }
  rnd_pick 4; case $REPLY in 0) rows=$(( rows - 1 )) ;; 3) rows=$(( rows + 1 )) ;; esac; (( rows < 3 )) && rows=3; (( rows > 6 )) && rows=6
  # a taller court stacks a deeper wall · not in proportion, or a level would take all night
  rows=$(( int(rows * (1.0 + (BN_HR - 1.0) * 0.6) + 0.5) )); (( rows > (BN_BOT - BN_TOP) * 45 / 100 )) && rows=$(( (BN_BOT - BN_TOP) * 45 / 100 ))
  BN_ROWS=$rows
  if [[ "${cuts[0]}" == none && ${#cuts[@]} == 1 ]]; then rnd_pick 10; cuts+=("${BN_CUTS[$(( REPLY + 1 ))]}"); fi
  rnd_pick 6; case $REPLY in 0) BN_P_GAP=5 ;; 1) BN_P_GAP=6 ;; 2) BN_P_GAP=7 ;; 3) BN_P_GAP=8 ;; 4) BN_P_GAP=9 ;; *) BN_P_GAP=11 ;; esac
  rnd_pick 3; BN_P_COL=$(( 3 + REPLY )); rnd_pick 4; BN_P_PHASE=$REPLY; rnd_pick 3; BN_P_INSET=$(( (3 + REPLY) * BN_COLS / 17 )); rnd_pick 3; BN_P_NOTCH=$(( (2 + REPLY) * BN_COLS / 17 ))
  rnd_pick $BN_COLS; BN_P_SHIFT=$REPLY; BN_P_ROWS=(); for (( i = 0; i < 6; i++ )); do rnd_pick $BN_COLS; BN_P_ROWS+=($REPLY); done
  rnd_uni 0.12 0.28; BN_P_SPARSE=$RF
  rnd_pick 5; case $REPLY in 0|1) BN_TRULE=top ;; 2) BN_TRULE=checker ;; 3) BN_TRULE=columns ;; *) BN_TRULE=edges ;; esac
  BN_TOUGH=$(( 1 + (AR_LEVEL - 1) / 3 )); (( BN_TOUGH > 3 )) && BN_TOUGH=3
  rnd_f; (( RF < 0.7 )) && mirror=1 || mirror=0
  BN_BR=()
  for (( r = 0; r < rows; r++ )); do for (( c = 0; c < BN_COLS; c++ )); do
    cc=$c; (( mirror && c > (BN_COLS - 1) / 2 )) && cc=$(( BN_COLS - 1 - c ))
    hit=0; for nm in "${cuts[@]}"; do bn_cut "$nm" $cc $r && { hit=1; break; }; done
    (( hit )) && continue
    if bn_hard $c $r; then BN_BR[$c,$r]=2; else BN_BR[$c,$r]=1; fi
  done; done
  # A CUT THAT CUT NOTHING IS NOT A CUT · a wall still almost whole gets a scatter
  full=$(( rows * BN_COLS ))
  if (( ${#BN_BR[@]} > full * 0.88 )); then
    rnd_uni 0.10 0.30; local -F drop=$RF; local k
    for k in ${(k)BN_BR[@]}; do (( ${k#*,} > 0 )) || continue; rnd_f; (( RF < drop )) && unset "BN_BR[$k]"; done
  fi
  cols=(); for k in ${(k)BN_BR[@]}; do cols[${k%%,*}]=1; done
  if (( ${#BN_BR[@]} < BN_COLS || ${#cols[@]} < BN_COLS - 2 )); then
    BN_BR=()
    for (( r = 0; r < rows; r++ )); do for (( c = 0; c < BN_COLS; c++ )); do
      (( r && (r + c) % 7 == 0 )) && continue
      if bn_hard $c $r; then BN_BR[$c,$r]=2; else BN_BR[$c,$r]=1; fi
    done; done
  fi
  return 0 }
bn_reset_ball() { BN_STUCK=1; BN_BX=($(( BN_PX + BN_PW * 0.5 ))); BN_BY=($(( BN_BOT - 1.0 ))); BN_VX=(0.0); BN_VY=(0.0); BN_NB=1; return 0 }
bn_launch() { local -F speed angle; local -i i
  BN_STUCK=0; speed=$(( BN_SPD0 + BN_CLEARED * 0.35 )); (( speed > BN_SPDMAX )) && speed=$BN_SPDMAX
  rnd_uni -0.55 0.55; angle=$RF
  for (( i = 0; i < BN_NB; i++ )); do BN_VX[$i]=$(( speed * sin(angle) )); BN_VY[$i]=$(( -speed * cos(angle) )); done
  ar_snd select; return 0 }
bn_steer() {   # bn_steer I · no ball is allowed to travel flat
  local -i i=$1; local -F speed rise run ay
  speed=$(( sqrt(BN_VX[i] * BN_VX[i] + BN_VY[i] * BN_VY[i]) ))
  if (( speed < 0.000001 )); then BN_VX[$i]=0.0; BN_VY[$i]=$(( -(BN_SPD0 > 6.0 ? BN_SPD0 : 6.0) )); return 0; fi
  ay=$(( BN_VY[i] < 0 ? -BN_VY[i] : BN_VY[i] ))
  (( ay >= speed * BN_MINRISE )) && return 0
  rise=$(( speed * BN_MINRISE )); (( BN_VY[i] > 0 )) && BN_VY[$i]=$rise || BN_VY[$i]=$(( -rise ))
  run=$(( speed * speed - rise * rise )); (( run < 0.0 )) && run=0.0; run=$(( sqrt(run) ))
  (( BN_VX[i] >= 0 )) && BN_VX[$i]=$run || BN_VX[$i]=$(( -run ))
  return 0 }
bn_multi() {   # split every ball on the field, to four
  local -i i n0 made=0; local -F speed base a
  if (( BN_STUCK )); then BN_VX[0]=0.0; BN_VY[0]=0.0; bn_launch; fi
  n0=$BN_NB
  for (( i = 0; i < n0; i++ )); do
    (( BN_NB >= BN_MAXB )) && break
    speed=$(( sqrt(BN_VX[i] * BN_VX[i] + BN_VY[i] * BN_VY[i]) )); (( speed < 6.0 )) && speed=6.0
    base=$(( atan(BN_VY[i], BN_VX[i]) ))
    for a in $(( base + 0.55 )) $(( base - 0.55 )); do
      (( BN_NB >= BN_MAXB )) && break
      BN_BX+=(${BN_BX[$i]}); BN_BY+=(${BN_BY[$i]}); BN_VX+=($(( speed * cos(a) ))); BN_VY+=($(( speed * sin(a) ))); BN_NB=$(( BN_NB + 1 )); made=$(( made + 1 ))
      bn_steer $(( BN_NB - 1 ))
    done
    BN_VX[$i]=$(( speed * cos(base) )); BN_VY[$i]=$(( speed * sin(base) ))
  done
  BN_MULTIS=$(( BN_MULTIS + 1 )); (( BN_NB > BN_MOST )) && BN_MOST=$BN_NB
  return 0 }
bn_brick_at() {   # bn_brick_at X Y → REPLY "c,r" or ''
  local -i r=$(( int($2) - BN_TOP - BN_DROPROW )) c=$(( int(($1 - BN_X0) / BN_BW) ))
  (( $1 < BN_X0 )) && c=-1
  if (( c >= 0 && c < BN_COLS )) && [[ -n "${BN_BR[$c,$r]:-}" ]]; then REPLY="$c,$r"; else REPLY=''; fi; return 0 }
bn_creep() {   # the whole wall down a row · at the paddle it costs a life and springs back
  local -i low=-1 r; local k
  BN_DROPROW=$(( BN_DROPROW + 1 ))
  for k in ${(k)BN_BR[@]}; do r=${k#*,}; (( r > low )) && low=$r; done
  if (( BN_TOP + low + BN_DROPROW >= BN_BOT - 1 )); then
    BN_DROPROW=0; AR_LIVES=$(( AR_LIVES - 1 )); BN_WIDET=0.0; BN_SLOWT=0.0; ar_snd error
    (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
    bn_reset_ball
  fi; return 0 }
bn_smash() {   # bn_smash "c,r"
  local key="$1"; local -i hits=${BN_BR[$key]:-0}
  (( hits )) || return 0
  hits=$(( hits - 1 ))
  if (( hits > 0 )); then BN_BR[$key]=$hits; ar_add 10; ar_snd move; return 0; fi
  unset "BN_BR[$key]"; BN_CLEARED=$(( BN_CLEARED + 1 ))
  ar_add $(( 50 * AR_LEVEL * (BN_NB > 1 ? BN_NB : 1) )); ar_snd select
  rnd_f; if (( RF < BN_DROPODDS )); then rnd_pick 5; BN_DX+=($(( BN_X0 + ${key%%,*} * BN_BW + BN_BW * 0.5 ))); BN_DY+=($(( BN_TOP + ${key#*,} + BN_DROPROW + 0.0 ))); BN_DKI+=($REPLY); fi
  if (( ${#BN_BR[@]} == 0 )); then
    AR_LEVEL=$(( AR_LEVEL + 1 )); (( AR_LEVEL > 20 )) && AR_LEVEL=20
    ar_add $(( 500 * AR_LEVEL )); ar_snd coin; BN_DROPROW=0; BN_CREEPT=0.0
    bn_wall; bn_reset_ball
  fi; return 0 }
bn_update() {   # bn_update DT
  local -F dt=$1 mid scale; local -i want i j; local k
  for k in "${AR_KEYS[@]}"; do case "$k" in LEFT|A) st_push 0 -1 ;; RIGHT|D) st_push 0 1 ;; SPACE|UP|W) (( BN_STUCK )) && bn_launch ;; M) bn_multi ;; esac; done
  st_glide 0 $dt; BN_PX=$(( BN_PX + RF )); (( BN_PX < 1 )) && BN_PX=1.0; (( BN_PX > AR_W - BN_PW - 1 )) && BN_PX=$(( AR_W - BN_PW - 1.0 ))
  (( BN_WIDET > 0 )) && { BN_WIDET=$(( BN_WIDET - dt )); (( BN_WIDET < 0.0 )) && BN_WIDET=0.0; }
  (( BN_SLOWT > 0 )) && { BN_SLOWT=$(( BN_SLOWT - dt )); (( BN_SLOWT < 0.0 )) && BN_SLOWT=0.0; }
  want=$(( BN_PW0 + (BN_WIDET > 0 ? int(6 * BN_WR + 0.5) : 0) ))
  if (( want != BN_PW )); then mid=$(( BN_PX + BN_PW * 0.5 )); BN_PW=$want; BN_PX=$(( mid - BN_PW * 0.5 )); (( BN_PX < 1 )) && BN_PX=1.0; (( BN_PX > AR_W - BN_PW - 1 )) && BN_PX=$(( AR_W - BN_PW - 1.0 )); fi
  local -a kx ky kk; kx=(); ky=(); kk=()
  for (( i = 0; i < ${#BN_DY[@]}; i++ )); do
    BN_DY[$i]=$(( BN_DY[i] + 11.0 * BN_HR * dt ))
    if (( BN_DY[i] >= BN_BOT )); then continue
    elif (( BN_DY[i] >= BN_BOT - 1 && BN_PX - 1 <= BN_DX[i] && BN_DX[i] <= BN_PX + BN_PW )); then bn_collect ${BN_DKI[$i]}; continue; fi
    kx+=(${BN_DX[$i]}); ky+=(${BN_DY[$i]}); kk+=(${BN_DKI[$i]})
  done
  BN_DX=("${kx[@]}"); BN_DY=("${ky[@]}"); BN_DKI=("${kk[@]}")
  if (( BN_STUCK )); then for (( i = 0; i < BN_NB; i++ )); do BN_BX[$i]=$(( BN_PX + BN_PW * 0.5 )); BN_BY[$i]=$(( BN_BOT - 1.0 )); done; return 0; fi
  if (( BN_CREEP > 0 )); then BN_CREEPT=$(( BN_CREEPT + dt )); if (( BN_CREEPT >= BN_CREEP )); then BN_CREEPT=0.0; bn_creep; (( ! AR_ALIVE || BN_STUCK )) && return 0; fi; fi
  scale=1.0; (( BN_SLOWT > 0 )) && scale=0.55
  typeset -ga BN_GONE; BN_GONE=()
  for (( i = 0; i < BN_NB; i++ )); do
    [[ -n "${BN_GONE[$i]:-}" ]] && continue
    bn_steer $i; bn_fly $i $(( dt * scale ))
    (( ! AR_ALIVE )) && return 0
    (( BN_STUCK )) && return 0            # the wall cleared under it · the balls were reset
  done
  # THE LAST ONE OUT TAKES THE LIFE, not the first
  local -a nx ny nvx nvy; nx=(); ny=(); nvx=(); nvy=()
  for (( i = 0; i < BN_NB; i++ )); do [[ -n "${BN_GONE[$i]:-}" ]] && continue; nx+=(${BN_BX[$i]}); ny+=(${BN_BY[$i]}); nvx+=(${BN_VX[$i]}); nvy+=(${BN_VY[$i]}); done
  BN_BX=("${nx[@]}"); BN_BY=("${ny[@]}"); BN_VX=("${nvx[@]}"); BN_VY=("${nvy[@]}"); BN_NB=${#nx[@]}
  if (( BN_NB == 0 )); then
    AR_LIVES=$(( AR_LIVES - 1 )); BN_WIDET=0.0; BN_SLOWT=0.0; ar_snd error
    (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
    bn_reset_ball
  fi
  return 0 }
typeset -ga BN_GONE
bn_fly() {   # bn_fly I DT
  local -i i=$1; local -F remain=$2 step sp hit speed angle vy
  while (( remain > 0.0001 )); do
    sp=$(( sqrt(BN_VX[i] * BN_VX[i] + BN_VY[i] * BN_VY[i]) )); (( sp < 1.0 )) && sp=1.0
    step=$(( 0.8 / sp )); (( step > remain )) && step=$remain; remain=$(( remain - step ))
    BN_BX[$i]=$(( BN_BX[i] + BN_VX[i] * step )); BN_BY[$i]=$(( BN_BY[i] + BN_VY[i] * step ))
    if (( BN_BX[i] <= 1 )); then BN_BX[$i]=1.0; BN_VX[$i]=$(( BN_VX[i] < 0 ? -BN_VX[i] : BN_VX[i] ))
    elif (( BN_BX[i] >= AR_W - 2 )); then BN_BX[$i]=$(( AR_W - 2.0 )); BN_VX[$i]=$(( BN_VX[i] > 0 ? -BN_VX[i] : BN_VX[i] )); fi
    (( BN_BY[i] <= AR_FT )) && { BN_BY[$i]=$(( AR_FT + 0.0 )); BN_VY[$i]=$(( BN_VY[i] < 0 ? -BN_VY[i] : BN_VY[i] )); }
    bn_brick_at ${BN_BX[$i]} ${BN_BY[$i]}
    if [[ -n "$REPLY" ]]; then
      BN_VY[$i]=$(( -BN_VY[i] )); BN_BY[$i]=$(( BN_BY[i] + BN_VY[i] * step ))
      bn_smash "$REPLY"
      (( BN_STUCK )) && return 0
      continue
    fi
    if (( BN_BY[i] >= BN_BOT - 1 )); then
      if (( BN_PX - 0.6 <= BN_BX[i] && BN_BX[i] <= BN_PX + BN_PW - 0.4 && BN_VY[i] > 0 )); then
        hit=$(( (BN_BX[i] - (BN_PX + BN_PW * 0.5)) / (BN_PW * 0.5 > 1.0 ? BN_PW * 0.5 : 1.0) ))
        speed=$(( sqrt(BN_VX[i] * BN_VX[i] + BN_VY[i] * BN_VY[i]) * 1.02 + 0.4 )); (( speed > BN_SPDMAX )) && speed=$BN_SPDMAX
        (( hit > 1.0 )) && hit=1.0; (( hit < -1.0 )) && hit=-1.0; angle=$(( hit * 1.05 ))
        BN_VX[$i]=$(( speed * sin(angle) )); vy=$(( speed * cos(angle) )); (( vy < 0 )) && vy=$(( -vy )); BN_VY[$i]=$(( -vy ))
        BN_BY[$i]=$(( BN_BOT - 1.1 )); ar_add 2; ar_snd move
      elif (( BN_BY[i] > BN_BOT )); then BN_GONE[$i]=1; return 0; fi
    fi
  done
  return 0 }
bn_collect() {   # bn_collect KIND-INDEX
  ar_snd coin
  case ${BN_DK_KEY[$1]} in
    W) BN_WIDET=12.0 ;; S) BN_SLOWT=9.0 ;; L) AR_LIVES=$(( AR_LIVES + 1 )); (( AR_LIVES > 5 )) && AR_LIVES=5 ;;
    M) bn_multi ;; *) ar_add 500 ;;
  esac; return 0 }
bn_paint() {   # bn_paint T
  local -F t=$1 left; local -i c r x y hits col face bg i pcol px; local k s
  for k in ${(k)BN_BR[@]}; do
    c=${k%%,*}; r=${k#*,}; x=$(( BN_X0 + c * BN_BW )); y=$(( BN_TOP + r + BN_DROPROW )); (( y >= BN_BOT )) && continue
    hits=${BN_BR[$k]}; col=${BN_PAL[$(( r % 6 ))]}
    if (( hits <= 1 )); then face=$col; else cmix $col $WHITE 0.45; face=$CM; fi
    cmix $GLASS $col $(( 0.10 + 0.07 * (c % 2) )); bg=$CM
    if (( hits > 1 )); then a_text $x $y '▗▄▄▖' $face $bg; else a_text $x $y '▖▄▄▗' $face $bg; fi
  done
  for (( i = 0; i < ${#BN_DX[@]}; i++ )); do col=${BN_DK_COL[${BN_DKI[$i]}]}; cmix $col $WHITE 0.3; face=$CM; cmix $GLASS $col 0.15; a_text $(( int(BN_DX[i]) - 1 )) $(( int(BN_DY[i]) )) "[${BN_DK_KEY[${BN_DKI[$i]}]}]" $face $CM; done
  px=$(( int(BN_PX) )); s=''; for (( i = 0; i < BN_PW; i++ )); do s+='▀'; done
  if (( BN_WIDET <= 0 )); then cmix $LIME $WHITE 0.2; else cmix $LIME $WHITE 0.5; fi; pcol=$CM; cmix $GLASS $LIME 0.12
  a_text $px $BN_BOT "$s" $pcol $CM
  if (( BN_SLOWT <= 0 )); then col=$WHITE; else cmix $CYAN $WHITE 0.4; col=$CM; fi; cmix $GLASS $WHITE 0.16; bg=$CM
  for (( i = 0; i < BN_NB; i++ )); do if (( i == 0 )); then a_put $(( int(BN_BX[i]) )) $(( int(BN_BY[i]) )) '●' $col $bg; else a_put $(( int(BN_BX[i]) )) $(( int(BN_BY[i]) )) '◍' $col $bg; fi; done
  if (( BN_STUCK )); then ar_wave $t 1.0; if (( WV > 0.35 )); then cmix $AMBER $WHITE 0.3; else cshade $AMBER 0.8; CM=$CS; fi; a_center $(( BN_BOT - 3 )) '◂ [SPACE] TO LAUNCH ▸' $CM -2; fi
  x=2
  if (( BN_WIDET > 0 )); then cmix $LIME $WHITE 0.25; a_text $x $AR_FT "WIDE $(( int(BN_WIDET + 0.5) ))s" $CM -2; x=$(( x + 14 )); fi
  if (( BN_SLOWT > 0 )); then cmix $CYAN $WHITE 0.25; a_text $x $AR_FT "SLOW $(( int(BN_SLOWT + 0.5) ))s" $CM -2; x=$(( x + 14 )); fi
  if (( BN_NB > 1 )); then cmix $WHITE $WHITE 0.25; a_text $x $AR_FT "MULTI ×$BN_NB" $WHITE -2; x=$(( x + 14 )); fi
  if (( BN_CREEP > 0 )); then left=$(( BN_CREEP - BN_CREEPT )); (( left < 0.0 )) && left=0.0; if (( left < 4.0 )); then cmix $RED $WHITE 0.25; else cmix $AMBER $WHITE 0.25; fi; a_text $x $AR_FT "WALL DOWN $(( int(left + 0.5) ))s" $CM -2; fi
  return 0 }
bn_hud() { cmix $MAGENTA $WHITE 0.25; AR_HL=(WALL); AR_HV=(${#BN_BR[@]}); AR_HC=($CM)
  if (( BN_NB > 1 )); then AR_HL+=(BALLS); AR_HV+=($BN_NB); AR_HC+=($WHITE); else ar_pad $AR_LEVEL 2; cmix $CYAN $WHITE 0.25; AR_HL+=(LVL); AR_HV+=("$REPLY"); AR_HC+=($CM); fi; return 0 }
bn_stats() { AR_SL=(BRICKS LEVEL MULTIBALLS 'MOST BALLS'); AR_SV=($BN_CLEARED $AR_LEVEL $BN_MULTIS $BN_MOST); return 0 }
pv_bricknova() {
  local -i x=$1 y=$2 w=$3 h=$4 r c px col; local -F bx by; local -a cols; cols=($MAGENTA $PURPLE $CYAN); local seg='▀▀ '
  local -i fg bg
  for (( r = 0; r < 3; r++ )); do
    col=${cols[$r]}; cshade $col 0.95; fg=$CS; cmix $AR_PVBG $col 0.16; bg=$CM   # a row's two inks, mixed once
    for (( c = 0; c < w; c += 3 )); do
      (( (c / 3 + r + int(AR_T * 0.4)) % 7 == 0 )) && continue
      if (( w - c >= 3 )); then a_text $(( x + c )) $(( y + r )) '▀▀ ' $fg $bg; else a_text $(( x + c )) $(( y + r )) "${seg[0,$(( w - c - 1 ))]}" $fg $bg; fi
    done
  done
  ar_tri $(( AR_T * 0.62 )); bx=$(( RF * (w - 1) )); ar_tri $(( AR_T * 0.48 + 0.2 )); by=$(( 1 + RF * (h - 3) ))
  px=$(( int(bx) - 2 )); (( px < 0 )) && px=0; (( px > w - 5 )) && px=$(( w - 5 ))
  cmix $AR_PVBG $LIME 0.14; a_text $(( x + px )) $(( y + h - 1 )) '▄▄▄▄▄' $LIME $CM
  cmix $AR_PVBG $WHITE 0.15; a_put $(( x + int(bx) )) $(( y + int(by) )) '●' $WHITE $CM
  return 0 }
AR_READY[bricknova]=1; AR_PREFIX[bricknova]=bn

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# BRICK NOVA · meet the ball where it can be aimed at the far columns
bn_demo() {
  (( BN_STUCK )) && { AR_DKEYS+=(SPACE); return 0; }
  local -F want tx aim; local k; local -i c r bc=-1 br=0 bd=-1 d
  (( BN_NB )) || return 0
  want=$(( BN_BX[0] - BN_PW * 0.5 ))
  if (( ${#BN_BR[@]} )) && ! (( BN_VY[0] < 0.0 )); then
    for k in ${(k)BN_BR[@]}; do
      c=${k%%,*}; r=${k#*,}; d=$(( int(abs(c - BN_COLS / 2.0) * 100) * 100 - r ))
      (( d > bd )) && { bd=$d; bc=$c; br=$r; }
    done
    tx=$(( BN_X0 + bc * BN_BW + BN_BW * 0.5 ))
    aim=$(( (tx - BN_BX[0]) / (AR_W * 0.35 > 6.0 ? AR_W * 0.35 : 6.0) )); (( aim > 0.9 )) && aim=0.9; (( aim < -0.9 )) && aim=-0.9
    want=$(( BN_BX[0] - BN_PW * 0.5 - aim * BN_PW * 0.5 ))
  fi
  (( want < 1.0 )) && want=1.0; (( want > AR_W - BN_PW - 1 )) && want=$(( AR_W - BN_PW - 1.0 ))
  ar_towards $BN_PX $want LEFT RIGHT 0.4; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15h · S T A R   R A I D E R        (shooter) · the divers, and a dealt formation
# ══════════════════════════════════════════════════════════════════════════
# The formation marched, and that was the whole of it.  From NORMAL up one
# peels off the block and comes down at you on a curve -- worth double on
# the way -- and if it gets past you it climbs back into its own slot.  On
# INSANE they drop a bomb on the way down.  THE FORMATION IS DEALT, and so
# are the shields: eleven block shapes with generated gaps, and slabs,
# arches or combs to come down on.  Every column keeps a LOWEST alien, and
# the block starts where it fits.
#
# THE BOARD IS THE ONE DEALT AT THE COIN, and sr_geom lays the machine out on
# it.  arcade.py tuned every number here on a 72 x 17 field; the board is SR_HS
# of that across and SR_VS of it down.  ACROSS: more columns at the same pitch,
# more shields, bombers and divers in proportion, and a march, a saucer and a
# shot that cross in the time they always did.  DOWN: the ship on the last row,
# the shields a scaled three rows over it, a block as deep in proportion, and a
# block that starts, drops and dies on the same count of bounces as the
# original's did -- so a wave takes as long to come down as it always has.
typeset -gi SR_COLS=9 SR_ROWS=4 SR_PITCH=5 SR_SHIPY=17 SR_SHIELDY=14
typeset -ga SR_GLYPH; SR_GLYPH=('▚▞' '▛▜' '▙▟' '▞▚')
typeset -ga SR_TINT SR_SHAPES; SR_SHAPES=(block block wedge spire arrow hourglass twin checker crescent ranks comb)
typeset -gi SR_SHIELDN SR_MAXSHOTS SR_WAVE SR_KILLED SR_UFOHITS SR_DIVED SR_ADIR SR_FRAME SR_WCOLS SR_WROWS SR_WFULL SR_DIVEARM SR_NA SR_ND
typeset -gF SR_STEP0 SR_STEPMIN SR_BOMBRATE SR_BOMBSPD SR_SX SR_AX SR_AY SR_ASTEP SR_UFOT SR_DIVEEVERY SR_DIVET SR_UFOX SR_UFOD
typeset -gi SR_UFO SR_UFOW
typeset -gA SR_AL SR_SH                          # aliens "c,r" · shields "x,y" → hp
typeset -ga SR_SHX SR_SHY SR_BMX SR_BMY SR_BX SR_BY SR_BT SR_PX SR_PY SR_PT SR_PW
typeset -ga SR_DC SR_DR SR_DX SR_DY SR_DVY SR_DSW SR_DPH SR_DSHOT    # the divers
# the board's own numbers · set by sr_geom at the coin, never at the top of the file
typeset -gF SR_HS=1.0 SR_VS=1.0 SR_RS=1.0 SR_SHOTV=34.0 SR_UFOV=7.0 SR_DROP=1.0
# how much of the extra depth goes into the block's rows (1 = all of it) · NONE:
# a wave lands in arcade.py's count of passes whatever the board, so every row
# added was a row more to kill in the same time, and on a full glass that was
# eight times the block for three times the fire.  The block keeps arcade.py's
# rows and grows only across, which SR_MAXSHOTS answers; the depth goes into
# the fall, a bigger step each bounce.
typeset -gF SR_RK=0.0
typeset -gi SR_AY0=3 SR_NDROP=0 SR_WROWS0=4 SR_DVMAX=2 SR_MINAL=12
typeset -ga SR_TFG SR_TBG SR_HPC                 # the inks, mixed once a round instead of once an alien a frame
sr_geom() {   # the board this round was dealt → every number of the machine that is a size
  SR_HS=$(( AR_W / 72.0 )); SR_VS=$(( AR_FH / 17.0 ))
  SR_RS=$(( 1.0 + (SR_VS - 1.0) * SR_RK ))
  SR_SHIPY=$(( AR_H - 1 )); SR_SHIELDY=$(( SR_SHIPY - int(3.0 * SR_VS + 0.5) ))
  SR_SHOTV=$(( 34.0 * SR_VS )); SR_UFOV=$(( 7.0 * SR_HS ))
  SR_DVMAX=$(( int(2.0 * SR_HS + 0.5) )); (( SR_DVMAX < 2 )) && SR_DVMAX=2
  SR_MINAL=$(( int(12.0 * SR_HS * SR_RS + 0.5) ))
  return 0 }
sr_inks() {
  local -i i
  SR_TFG=(); SR_TBG=(); SR_HPC=()
  for (( i = 0; i < 4; i++ )); do cmix ${SR_TINT[$i]} $WHITE 0.15; SR_TFG+=($CM); cmix $GLASS ${SR_TINT[$i]} 0.10; SR_TBG+=($CM); done
  for (( i = 0; i <= 6; i++ )); do cshade $LIME $(( 0.45 + 0.18 * i )); SR_HPC+=($CS); done
  return 0 }
sr_begin() {
  AR_G_LEGEND='◄► MOVE      [SPACE] FIRE      [P] PAUSE      [Q] CASH OUT'
  AR_G_HOWTO='hold the line  ·  the ones that peel off are worth double'
  AR_G_ACC=$PURPLE; SR_TINT=($MAGENTA $PURPLE $BLUE $CYAN)
  sr_geom; sr_inks
  # a step is a cell of march, and there are SR_HS as many cells to a pass ·
  # a bomb a second is SR_HS as many for SR_HS as many columns · a bomb falls,
  # like a shot rises, SR_VS as many rows in the same time
  ar_pick 0.72 0.55 0.40 0.30; SR_STEP0=$(( REPLY / SR_HS ))
  ar_pick 0.11 0.08 0.055 0.040; SR_STEPMIN=$(( REPLY / SR_HS ))
  ar_pick 0.55 0.95 1.45 2.10; SR_BOMBRATE=$(( REPLY * SR_HS ))
  ar_pick 11.0 14.0 18.0 22.0; SR_BOMBSPD=$(( REPLY * SR_VS ))
  ar_pick 4 3 2 1; SR_SHIELDN=$(( int(REPLY * SR_HS + 0.5) ))
  # A WAVE IS SR_HS × SR_RS AS BIG and lands in SR_VS as long · every extra row
  # goes into the block, so it is SR_HS as many to kill a second, and the only
  # lever on that is the shots in the air -- as many more as the board is wider
  ar_pick 3 2 2 1; SR_MAXSHOTS=$(( int(REPLY * SR_HS + 0.5) )); (( SR_MAXSHOTS < REPLY )) && SR_MAXSHOTS=$REPLY
  AR_LIVES=3; SR_WAVE=1; SR_KILLED=0
  # THE SHIP, BETWEEN TWO RULES · the bombs are as thick a column as arcade.py's,
  # so a ship at its old pace meets the same rain -- but on a board SR_HS as wide
  # it is a long way to the last of the block.  It goes √SR_HS as fast: faster
  # across, and a little more rain for it
  st_set 0 $(( 250.0 * sqrt(SR_HS) )) 11.0 $(( 44.0 * sqrt(SR_HS) ))
  SR_SX=$(( AR_W * 0.5 )); SR_SHX=(); SR_SHY=(); SR_BMX=(); SR_BMY=(); SR_BX=(); SR_BY=(); SR_BT=()
  SR_UFO=0; ar_pick 26.0 22.0 18.0 15.0; SR_UFOT=$REPLY; SR_UFOHITS=0; SR_PX=(); SR_PY=(); SR_PT=(); SR_PW=()
  ar_pick 0.0 6.5 4.0 2.6; SR_DIVEEVERY=$(( REPLY / SR_HS ))     # one a column-width's worth of block, as often as ever
  ar_pick 0 0 0 1; SR_DIVEARM=$REPLY
  SR_DIVET=$SR_DIVEEVERY; SR_DIVED=0
  SR_DC=(); SR_DR=(); SR_DX=(); SR_DY=(); SR_DVY=(); SR_DSW=(); SR_DPH=(); SR_DSHOT=(); SR_ND=0
  sr_wave
  return 0 }
sr_formation() {   # → SR_AL / SR_WCOLS / SR_WROWS · a shape, holes, and no column left floating
  # the original's seven to nine columns and three to five rows are dealt, then
  # grown to the board: SR_HS as many columns, SR_RS as many rows
  local shape; local -i co ro cols rows r c keep lo hi; local -F holes mid k a
  rnd_pick 11; shape="${SR_SHAPES[$REPLY]}"
  rnd_pick 4; case $REPLY in 0) co=7 ;; 1) co=8 ;; *) co=9 ;; esac
  rnd_pick 4; case $REPLY in 0) ro=3 ;; 1|2) ro=4 ;; *) ro=5 ;; esac
  cols=$(( int(co * SR_HS + 0.5) )); rows=$(( int(ro * SR_RS + 0.5) ))
  (( cols < co )) && cols=$co; (( rows < ro )) && rows=$ro
  rnd_uni 0.0 0.16; holes=$RF; mid=$(( (cols - 1) / 2.0 ))
  SR_AL=()
  for (( r = 0; r < rows; r++ )); do for (( c = 0; c < cols; c++ )); do
    keep=1; a=$(( c - mid )); (( a < 0 )) && a=$(( -a ))
    case "$shape" in
      wedge)     (( a <= mid * (r + 1) / (rows + 0.0) )) || keep=0 ;;
      spire)     (( a <= mid * (rows - r) / (rows + 0.0) )) || keep=0 ;;
      arrow)     (( a <= r + 0.5 || r == rows - 1 )) || keep=0 ;;
      hourglass) k=$(( r - (rows - 1) / 2.0 )); (( k < 0 )) && k=$(( -k )); k=$(( k / ((rows - 1) / 2.0 > 0.5 ? (rows - 1) / 2.0 : 0.5) ))
                 (( a <= mid * (0.45 + 0.55 * k) )) || keep=0 ;;
      twin)      (( a > mid * 0.22 )) || keep=0 ;;
      checker)   (( (c + r) % 2 == 0 || r == 0 )) || keep=0 ;;
      crescent)  (( a >= mid * 0.30 || r < rows - 1 )) || keep=0 ;;
      ranks)     (( r % 2 == 0 || c % 2 == 0 )) || keep=0 ;;
      comb)      (( c % 2 == 0 || r == 0 )) || keep=0 ;;
    esac
    (( keep )) || continue
    rnd_f; (( RF >= holes )) && SR_AL[$c,$r]=1
  done; done
  for (( c = 0; c < cols; c++ )); do
    lo=999; hi=-1; for (( r = 0; r < rows; r++ )); do [[ -n "${SR_AL[$c,$r]:-}" ]] && { (( r < lo )) && lo=$r; (( r > hi )) && hi=$r; }; done
    (( hi < 0 )) && continue
    for (( r = lo; r <= hi; r++ )); do SR_AL[$c,$r]=1; done
  done
  SR_WCOLS=$cols; SR_WROWS=$rows; SR_WROWS0=$ro; return 0 }
sr_shields() {   # slabs, arches or combs · however many the rung allows, and as many more as the board is wider
  local kind; local -i half thick hp gap jitter i cx dy dx y
  SR_SH=(); (( SR_SHIELDN )) || return 0
  rnd_pick 4; case $REPLY in 0|1) kind=slab ;; 2) kind=arch ;; *) kind=comb ;; esac
  rnd_pick 3; half=$(( REPLY == 2 ? 3 : 2 )); rnd_pick 3; thick=$(( REPLY == 2 ? 2 : 1 ))
  rnd_pick 4; case $REPLY in 0) hp=2 ;; 1|2) hp=3 ;; *) hp=4 ;; esac
  gap=$(( AR_W / (SR_SHIELDN + 1) )); rnd_int -2 2; jitter=$REPLY
  for (( i = 0; i < SR_SHIELDN; i++ )); do
    cx=$(( gap * (i + 1) + jitter )); (( cx < half + 2 )) && cx=$(( half + 2 )); (( cx > AR_W - half - 3 )) && cx=$(( AR_W - half - 3 ))
    for (( dy = 0; dy < thick; dy++ )); do y=$(( SR_SHIELDY - dy ))
      for (( dx = -half; dx <= half; dx++ )); do
        [[ "$kind" == arch ]] && (( dy == thick - 1 && dx > -1 && dx < 1 )) && continue
        [[ "$kind" == comb ]] && (( (dx + half) % 2 && dy == 0 )) && continue
        SR_SH[$(( cx + dx )),$y]=$hp
      done; done
  done; return 0 }
sr_wave() {
  local -i try ok=0 deep deepo r room ay ayo gapo gap c fc fr; local k
  for (( try = 0; try < 24; try++ )); do
    sr_formation
    (( ${#SR_AL[@]} >= SR_MINAL && (SR_WCOLS - 1) * SR_PITCH + 2 < AR_W - 8 )) && { ok=1; break; }
  done
  if (( ! ok )); then
    fc=$(( int(SR_COLS * SR_HS + 0.5) )); fr=$(( int(SR_ROWS * SR_RS + 0.5) ))
    SR_AL=(); for (( r = 0; r < fr; r++ )); do for (( c = 0; c < fc; c++ )); do SR_AL[$c,$r]=1; done; done
    SR_WCOLS=$fc; SR_WROWS=$fr; SR_WROWS0=$SR_ROWS
  fi
  SR_WFULL=${#SR_AL[@]}; (( SR_WFULL < 1 )) && SR_WFULL=1
  SR_AX=4.0
  deep=0; for k in ${(k)SR_AL[@]}; do r=${k#*,}; (( r > deep )) && deep=$r; done
  # THE BLOCK STARTS WHERE IT FITS, worked out on the original's own rows: a
  # row lower each wave to a floor of six, never so low it lands on its
  # shields -- and the count of bounces that left before it did is the count
  # this board gets too, each one SR_DROP rows deep
  deepo=$(( int(deep / SR_RS + 0.5) ))
  room=$(( 14 - deepo * 2 - 2 )); (( room < 2 )) && room=2
  ayo=$(( 3 + (SR_WAVE - 1) )); (( ayo > 6 )) && ayo=6; (( ayo > room )) && ayo=$room
  gapo=$(( 14 - ayo - deepo * 2 )); (( gapo < 1 )) && gapo=1
  ay=$(( AR_FT + int((ayo - AR_FT) * SR_VS + 0.5) ))
  room=$(( SR_SHIELDY - deep * 2 - 2 )); (( ay > room )) && ay=$room; (( ay < AR_FT + 1 )) && ay=$(( AR_FT + 1 ))
  gap=$(( SR_SHIELDY - ay - deep * 2 ))
  # …and the block takes √SR_HS as many bounces to come down, the time a wider
  # sweep of the block needs · the shots answer the count, this the distance
  SR_DROP=$(( gap / (gapo * sqrt(SR_HS)) )); (( SR_DROP < 1.0 )) && SR_DROP=1.0
  SR_AY0=$ay; SR_NDROP=0
  SR_AY=$(( ay + 0.0 )); SR_ADIR=1; SR_ASTEP=0.0; SR_FRAME=0
  SR_SHX=(); SR_SHY=(); SR_BMX=(); SR_BMY=()
  SR_DC=(); SR_DR=(); SR_DX=(); SR_DY=(); SR_DVY=(); SR_DSW=(); SR_DPH=(); SR_DSHOT=(); SR_ND=0
  SR_DIVET=$SR_DIVEEVERY
  sr_shields
  return 0 }
sr_worth() {   # sr_worth ROW → REPLY the row of the original's block it stands for · what an alien pays is by that
  if (( SR_WROWS > SR_WROWS0 )); then REPLY=$(( $1 * SR_WROWS0 / SR_WROWS )); else REPLY=$1; fi; return 0 }
sr_alive_cols() {   # → REPLY the columns with an alien, ascending
  local -A cs; local k; local -i c
  for k in ${(k)SR_AL[@]}; do cs[${k%%,*}]=1; done
  REPLY=''; for (( c = 0; c < SR_WCOLS; c++ )); do [[ -n "${cs[$c]:-}" ]] && REPLY+="$c "; done; return 0 }
sr_speed() {   # → RF seconds a step · the full block is THIS wave's block
  local -i left=${#SR_AL[@]} full; local -F k base
  (( left < 1 )) && left=1; full=$SR_WFULL; (( full < left )) && full=$left
  k=$(( 1.0 - left / (full + 0.0) )); base=$(( SR_STEP0 * (0.86 ** (SR_WAVE - 1)) ))
  RF=$(( base * (1.0 - 0.78 * k) )); (( RF < SR_STEPMIN )) && RF=$SR_STEPMIN; return 0 }
sr_update() {   # sr_update DT
  local -F dt=$1 sub bsub; local -i fired=0 steps i bsteps; local k
  for k in "${AR_KEYS[@]}"; do case "$k" in
    LEFT|A) st_push 0 -1 ;; RIGHT|D) st_push 0 1 ;;
    SPACE|UP|W|Z) (( fired )) && continue; fired=1; (( ${#SR_SHX[@]} < SR_MAXSHOTS )) && { SR_SHX+=($SR_SX); SR_SHY+=($(( SR_SHIPY - 1.0 ))); ar_snd move; } ;;
  esac; done
  st_glide 0 $dt; SR_SX=$(( SR_SX + RF )); (( SR_SX < 2 )) && SR_SX=2.0; (( SR_SX > AR_W - 3 )) && SR_SX=$(( AR_W - 3.0 ))
  local -a kx ky kt; kx=(); ky=(); kt=()
  for (( i = 0; i < ${#SR_BT[@]}; i++ )); do SR_BT[$i]=$(( SR_BT[i] + dt )); (( SR_BT[i] > 0.32 )) && continue; kx+=(${SR_BX[$i]}); ky+=(${SR_BY[$i]}); kt+=(${SR_BT[$i]}); done
  SR_BX=("${kx[@]}"); SR_BY=("${ky[@]}"); SR_BT=("${kt[@]}")
  # a slice is never taller than a third of a cell, whatever the shot's speed on this board
  steps=$(( int(SR_SHOTV * dt / 0.33) + 1 )); (( steps < 1 )) && steps=1; sub=$(( dt / steps ))
  for (( i = 0; i < steps; i++ )); do (( ${#SR_SHX[@]} )) || break; sr_step_shots $sub && return 0; done
  sr_step_block $dt && return 0
  sr_step_divers $dt && return 0
  sr_clear && return 0
  sr_step_ufo $dt
  bsteps=$(( int(SR_BOMBSPD * dt / 0.33) + 1 )); (( bsteps < 1 )) && bsteps=1; bsub=$(( dt / bsteps ))
  for (( i = 0; i < bsteps; i++ )); do (( ${#SR_BMX[@]} )) || break; sr_step_bombs $bsub && return 0; done
  return 0 }
sr_hit_alien() {   # sr_hit_alien X Y → REPLY "c,r" or ''
  # every alien's box is ax-0.5..ax+1.5 by ay-0.5..ay+0.5 and no two boxes meet,
  # so the one a point can be in is worked out rather than searched for
  local -F u=$(( $1 - SR_AX + 0.5 )) v=$(( $2 - SR_AY + 0.5 )); local -i c r
  REPLY=''
  (( u < 0.0 || v < 0.0 )) && return 1
  c=$(( int(u / SR_PITCH) )); r=$(( int(v / 2.0) ))
  (( u - c * SR_PITCH <= 2.0 && v - r * 2.0 <= 1.0 )) || return 1
  [[ -n "${SR_AL[$c,$r]:-}" ]] || return 1
  REPLY="$c,$r"; return 0 }
sr_step_shots() {   # one slice · 0 if the round ended
  local -F dt=$1; local -i i keep=0 kx ky j; local key; local -a nx ny; nx=(); ny=()
  for (( i = 0; i < ${#SR_SHX[@]}; i++ )); do
    SR_SHY[$i]=$(( SR_SHY[i] - SR_SHOTV * dt ))
    (( SR_SHY[i] < AR_FT )) && continue
    kx=$(( int(SR_SHX[i] + 0.5) )); ky=$(( int(SR_SHY[i] + 0.5) ))
    if [[ -n "${SR_SH[$kx,$ky]:-}" ]]; then SR_SH[$kx,$ky]=$(( SR_SH[$kx,$ky] - 1 )); (( SR_SH[$kx,$ky] <= 0 )) && unset "SR_SH[$kx,$ky]"; continue; fi
    sr_hit_ufo ${SR_SHX[$i]} ${SR_SHY[$i]} && continue
    sr_hit_diver ${SR_SHX[$i]} ${SR_SHY[$i]} && continue
    if sr_hit_alien ${SR_SHX[$i]} ${SR_SHY[$i]}; then
      key="$REPLY"; unset "SR_AL[$key]"; SR_KILLED=$(( SR_KILLED + 1 ))
      sr_worth ${key#*,}; ar_add $(( (SR_ROWS - REPLY) * 20 * SR_WAVE )); SR_BX+=(${SR_SHX[$i]}); SR_BY+=(${SR_SHY[$i]}); SR_BT+=(0.0); ar_snd select
      # the rest of this slice's shots stay in flight
      for (( j = i + 1; j < ${#SR_SHX[@]}; j++ )); do nx+=(${SR_SHX[$j]}); ny+=(${SR_SHY[$j]}); done
      SR_SHX=("${nx[@]}"); SR_SHY=("${ny[@]}")
      sr_clear && return 0
      return 1
    fi
    nx+=(${SR_SHX[$i]}); ny+=(${SR_SHY[$i]})
  done
  SR_SHX=("${nx[@]}"); SR_SHY=("${ny[@]}"); return 1 }
sr_step_block() {   # march the formation · 0 if the round ended
  local -F dt=$1 speed left right; local -a cols; local -i deep r c lo hi; local k
  SR_ASTEP=$(( SR_ASTEP + dt )); sr_speed; speed=$RF
  while (( SR_ASTEP >= speed )); do
    SR_ASTEP=$(( SR_ASTEP - speed )); SR_FRAME=$(( SR_FRAME + 1 ))
    (( ${#SR_AL[@]} )) || break
    lo=9999; hi=-1; deep=0
    for k in ${(k)SR_AL[@]}; do c=${k%%,*}; r=${k#*,}; (( c < lo )) && lo=$c; (( c > hi )) && hi=$c; (( r > deep )) && deep=$r; done
    left=$(( SR_AX + lo * SR_PITCH )); right=$(( SR_AX + hi * SR_PITCH + 1 ))
    if (( (SR_ADIR > 0 && right >= AR_W - 3) || (SR_ADIR < 0 && left <= 2) )); then
      SR_ADIR=$(( -SR_ADIR )); SR_NDROP=$(( SR_NDROP + 1 )); SR_AY=$(( SR_AY0 + int(SR_NDROP * SR_DROP + 0.001) ))
    else SR_AX=$(( SR_AX + SR_ADIR )); fi
    (( SR_AY + deep * 2 >= SR_SHIELDY )) && { AR_LIVES=0; AR_ALIVE=0; return 0; }
    rnd_f
    if (( RF < SR_BOMBRATE * speed )); then
      sr_alive_cols; cols=(${=REPLY})
      if (( ${#cols[@]} )); then rnd_pick ${#cols[@]}; c=${cols[$REPLY]}; deep=-1
        for k in ${(k)SR_AL[@]}; do (( ${k%%,*} == c )) && { r=${k#*,}; (( r > deep )) && deep=$r; }; done
        (( deep >= 0 )) && { SR_BMX+=($(( SR_AX + c * SR_PITCH ))); SR_BMY+=($(( SR_AY + deep * 2 + 1.0 ))); }
      fi
    fi
  done
  return 1 }
sr_clear() {   # is the wave over · asked every frame · 0 when a new wave was dealt
  (( ${#SR_AL[@]} || SR_ND )) && return 1
  SR_WAVE=$(( SR_WAVE + 1 )); AR_LEVEL=$SR_WAVE; ar_add $(( 750 * SR_WAVE )); ar_snd coin
  sr_wave; return 0 }
sr_launch_diver() {   # always from the bottom of a column
  local -a cols; local -i c r deep=-1; local k
  sr_alive_cols; cols=(${=REPLY}); (( ${#cols[@]} )) || return 0
  rnd_pick ${#cols[@]}; c=${cols[$REPLY]}
  for k in ${(k)SR_AL[@]}; do (( ${k%%,*} == c )) && { r=${k#*,}; (( r > deep )) && deep=$r; }; done
  (( deep < 0 )) && return 0; r=$deep
  unset "SR_AL[$c,$r]"
  SR_DC+=($c); SR_DR+=($r); SR_DX+=($(( SR_AX + c * SR_PITCH ))); SR_DY+=($(( SR_AY + r * 2 ))); SR_DVY+=($(( (9.0 + 1.5 * SR_WAVE) * SR_VS )))
  rnd_uni 3.0 6.0; SR_DSW+=($RF); rnd_uni 0.0 6.28; SR_DPH+=($RF); SR_DSHOT+=($(( SR_DIVEARM ? 0 : 1 ))); SR_ND=$(( SR_ND + 1 ))
  ar_snd move; return 0 }
sr_drop_diver() {   # sr_drop_diver I · remove one from the arrays
  local -i i=$1 j; local -a c r x y vy sw ph sh; c=(); r=(); x=(); y=(); vy=(); sw=(); ph=(); sh=()
  for (( j = 0; j < SR_ND; j++ )); do (( j == i )) && continue; c+=(${SR_DC[$j]}); r+=(${SR_DR[$j]}); x+=(${SR_DX[$j]}); y+=(${SR_DY[$j]}); vy+=(${SR_DVY[$j]}); sw+=(${SR_DSW[$j]}); ph+=(${SR_DPH[$j]}); sh+=(${SR_DSHOT[$j]}); done
  SR_DC=("${c[@]}"); SR_DR=("${r[@]}"); SR_DX=("${x[@]}"); SR_DY=("${y[@]}"); SR_DVY=("${vy[@]}"); SR_DSW=("${sw[@]}"); SR_DPH=("${ph[@]}"); SR_DSHOT=("${sh[@]}"); SR_ND=${#c[@]}; return 0 }
sr_step_divers() {   # fly the ones that peeled off · 0 if the round ended
  local -F dt=$1 wig=$(( 0.55 / SR_VS )); local -i i dxi
  if (( SR_DIVEEVERY > 0 && ${#SR_AL[@]} )); then
    SR_DIVET=$(( SR_DIVET - dt ))
    if (( SR_DIVET <= 0.0 )); then rnd_uni 0.7 1.4; SR_DIVET=$(( SR_DIVEEVERY * RF )); (( SR_ND < SR_DVMAX )) && sr_launch_diver; fi
  fi
  sr_clear && return 1
  i=0
  while (( i < SR_ND )); do
    SR_DY[$i]=$(( SR_DY[i] + SR_DVY[i] * dt ))
    # the same curve in the same time: the sway is read off the rows a diver has fallen, and it falls SR_VS as fast
    SR_DX[$i]=$(( SR_DX[i] + sin(SR_DY[i] * wig + SR_DPH[i]) * SR_DSW[i] * dt ))
    (( SR_DX[i] < 1.0 )) && SR_DX[$i]=1.0; (( SR_DX[i] > AR_W - 3.0 )) && SR_DX[$i]=$(( AR_W - 3.0 ))
    if (( ! SR_DSHOT[i] && SR_DY[i] > SR_SHIELDY - 4.0 * SR_VS )); then SR_DSHOT[$i]=1; SR_BMX+=(${SR_DX[$i]}); SR_BMY+=($(( SR_DY[i] + 1.0 ))); fi
    if (( SR_DY[i] >= SR_SHIPY )); then
      dxi=$(( int(SR_DX[i] + 0.5) - int(SR_SX) )); (( dxi < 0 )) && dxi=$(( -dxi ))
      if (( dxi <= 1 )); then
        sr_drop_diver $i; AR_LIVES=$(( AR_LIVES - 1 )); SR_BX+=($SR_SX); SR_BY+=($(( SR_SHIPY + 0.0 ))); SR_BT+=(0.0); SR_BMX=(); SR_BMY=(); ar_snd error
        (( AR_LIVES <= 0 )) && AR_ALIVE=0
        return 0
      fi
      SR_AL[${SR_DC[$i]},${SR_DR[$i]}]=1; sr_drop_diver $i; continue    # back into its own slot
    fi
    i=$(( i + 1 ))
  done
  sr_clear && return 0
  return 1 }
sr_hit_diver() {   # sr_hit_diver X Y → 0 when a diver took the shot
  local -i i
  for (( i = 0; i < SR_ND; i++ )); do
    if (( SR_DY[i] - 0.6 <= $2 && $2 <= SR_DY[i] + 0.6 && SR_DX[i] - 0.6 <= $1 && $1 <= SR_DX[i] + 1.6 )); then
      SR_KILLED=$(( SR_KILLED + 1 )); SR_DIVED=$(( SR_DIVED + 1 )); sr_worth ${SR_DR[$i]}; ar_add $(( (SR_ROWS - REPLY) * 40 * SR_WAVE ))
      SR_BX+=(${SR_DX[$i]}); SR_BY+=(${SR_DY[$i]}); SR_BT+=(0.0); sr_drop_diver $i; ar_snd coin; return 0
    fi
  done; return 1 }
sr_step_ufo() { local -F dt=$1; local -i i; local -a kx ky kt kw; kx=(); ky=(); kt=(); kw=()
  for (( i = 0; i < ${#SR_PT[@]}; i++ )); do SR_PT[$i]=$(( SR_PT[i] + dt )); (( SR_PT[i] > 0.9 )) && continue; kx+=(${SR_PX[$i]}); ky+=(${SR_PY[$i]}); kt+=(${SR_PT[$i]}); kw+=(${SR_PW[$i]}); done
  SR_PX=("${kx[@]}"); SR_PY=("${ky[@]}"); SR_PT=("${kt[@]}"); SR_PW=("${kw[@]}")
  if (( ! SR_UFO )); then
    SR_UFOT=$(( SR_UFOT - dt ))
    if (( SR_UFOT <= 0.0 )); then rnd_uni 16.0 30.0; SR_UFOT=$RF; rnd_pick 2; if (( REPLY )); then SR_UFOD=1.0; SR_UFOX=-2.0; else SR_UFOD=-1.0; SR_UFOX=$(( AR_W + 1.0 )); fi
      rnd_pick 4; case $REPLY in 0) SR_UFOW=300 ;; 1) SR_UFOW=500 ;; 2) SR_UFOW=800 ;; *) SR_UFOW=1200 ;; esac; SR_UFO=1; fi
    return 0
  fi
  SR_UFOX=$(( SR_UFOX + SR_UFOD * SR_UFOV * dt ))    # the top rail in the time it always took
  (( SR_UFOX < -3.0 || SR_UFOX > AR_W + 2 )) && SR_UFO=0
  return 0 }
sr_hit_ufo() {   # sr_hit_ufo X Y
  (( SR_UFO )) || return 1; (( int($2 + 0.5) == AR_FT )) || return 1
  local -F d=$(( $1 - SR_UFOX )); (( d < 0 )) && d=$(( -d )); (( d > 1.5 )) && return 1
  local -i worth=$(( SR_UFOW * SR_WAVE )); ar_add $worth; SR_UFOHITS=$(( SR_UFOHITS + 1 ))
  ar_shown $worth; worth=$REPLY                      # the figure that floats up is what the board credited
  SR_PX+=($SR_UFOX); SR_PY+=($(( AR_FT + 0.0 ))); SR_PT+=(0.0); SR_PW+=($worth); SR_BX+=($SR_UFOX); SR_BY+=($(( AR_FT + 0.0 ))); SR_BT+=(0.0)
  SR_UFO=0; ar_snd coin; return 0 }
sr_step_bombs() {   # one slice · 0 if the round ended · rebuilt, not removed in place
  local -F dt=$1; local -i i kx ky d; local -a nx ny; nx=(); ny=()
  for (( i = 0; i < ${#SR_BMX[@]}; i++ )); do
    SR_BMY[$i]=$(( SR_BMY[i] + SR_BOMBSPD * dt ))
    kx=$(( int(SR_BMX[i] + 0.5) )); ky=$(( int(SR_BMY[i] + 0.5) ))
    if [[ -n "${SR_SH[$kx,$ky]:-}" ]]; then SR_SH[$kx,$ky]=$(( SR_SH[$kx,$ky] - 1 )); (( SR_SH[$kx,$ky] <= 0 )) && unset "SR_SH[$kx,$ky]"; continue; fi
    if (( SR_BMY[i] >= SR_SHIPY )); then
      d=$(( kx - int(SR_SX) )); (( d < 0 )) && d=$(( -d ))
      if (( d <= 1 )); then AR_LIVES=$(( AR_LIVES - 1 )); SR_BX+=($SR_SX); SR_BY+=($(( SR_SHIPY + 0.0 ))); SR_BT+=(0.0); ar_snd error; SR_BMX=(); SR_BMY=(); (( AR_LIVES <= 0 )) && AR_ALIVE=0; return 0; fi
      continue
    fi
    (( SR_BMY[i] > AR_H )) && continue
    nx+=(${SR_BMX[$i]}); ny+=(${SR_BMY[$i]})
  done
  SR_BMX=("${nx[@]}"); SR_BMY=("${ny[@]}"); return 1 }
sr_paint() {   # sr_paint T
  # the block and the shields are most of the cells on the board, and they go
  # straight into the canvas: a text call an alien was most of a frame
  local -F t=$1 k; local -i i ux wob c r ax ay hp x y col bg base kc fg tb ri; local kk s g
  if (( SR_UFO )); then ux=$(( int(SR_UFOX + 0.5) )); ar_wave $t 4.0; cmix $AMBER $WHITE $(( 0.35 + 0.35 * WV )); col=$CM; cmix $GLASS $AMBER 0.18; a_text $(( ux - 1 )) $AR_FT '◄◙►' $col $CM; fi
  for (( i = 0; i < ${#SR_PT[@]}; i++ )); do ar_commify ${SR_PW[$i]}; s="$REPLY"; y=$(( int(SR_PY[i]) - int(SR_PT[i] * 3) )); (( y < AR_FT )) && y=$AR_FT
    cmix $AMBER $WHITE 0.5; cshade $CM $(( 1.0 - SR_PT[i] / 0.9 )); a_text $(( int(SR_PX[i]) - ${#s} / 2 )) $y "$s" $CS -2; done
  wob=$(( SR_FRAME % 2 ))
  cmix $GLASS $RED 0.16; bg=$CM
  for (( i = 0; i < SR_ND; i++ )); do (( SR_DY[i] >= AR_FT && SR_DY[i] < AR_H )) || continue; ar_wave $t 3.0; cmix $RED $WHITE $(( 0.35 + 0.25 * WV ))
    if (( wob )); then a_text $(( int(SR_DX[i]) )) $(( int(SR_DY[i]) )) '▟▙' $CM $bg; else a_text $(( int(SR_DX[i]) )) $(( int(SR_DY[i]) )) '▜▛' $CM $bg; fi; done
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  for kk in ${(k)SR_AL[@]}; do c=${kk%%,*}; r=${kk#*,}; ax=$(( int(SR_AX + c * SR_PITCH) )); ay=$(( int(SR_AY + r * 2) ))
    (( ay >= AR_FT && ay < AR_H && ax >= 0 && ax + 1 < AR_W )) || continue
    ri=$(( r % 4 )); g="${SR_GLYPH[$(( (r + wob) % 4 ))]}"; fg=${SR_TFG[$ri]}; tb=${SR_TBG[$ri]}; kc=$(( base + ay * TCOLS + ax ))
    GCH[$kc]="${g[0]}"; GF[$kc]=$fg; GB[$kc]=$tb; kc=$(( kc + 1 )); GCH[$kc]="${g[1]}"; GF[$kc]=$fg; GB[$kc]=$tb
  done
  for kk in ${(k)SR_SH[@]}; do hp=${SR_SH[$kk]}; x=${kk%%,*}; y=${kk#*,}
    (( x >= 0 && x < AR_W && y >= 0 && y < AR_H )) || continue
    kc=$(( base + y * TCOLS + x )); (( hp > 6 )) && hp=6; GF[$kc]=${SR_HPC[$hp]}
    if (( hp >= 3 )); then GCH[$kc]='█'; elif (( hp == 2 )); then GCH[$kc]='▓'; else GCH[$kc]='▒'; fi; done
  cmix $AMBER $WHITE 0.3; for (( i = 0; i < ${#SR_SHX[@]}; i++ )); do a_put $(( int(SR_SHX[i] + 0.5) )) $(( int(SR_SHY[i] + 0.5) )) '│' $CM -2; done
  cmix $RED $WHITE 0.2; for (( i = 0; i < ${#SR_BMX[@]}; i++ )); do if (( int(t * 12) % 2 )); then a_put $(( int(SR_BMX[i] + 0.5) )) $(( int(SR_BMY[i] + 0.5) )) '╿' $CM -2; else a_put $(( int(SR_BMX[i] + 0.5) )) $(( int(SR_BMY[i] + 0.5) )) '╽' $CM -2; fi; done
  for (( i = 0; i < ${#SR_BT[@]}; i++ )); do k=$(( SR_BT[i] / 0.32 )); cmix $AMBER $WHITE 0.4; cshade $CM $(( 1.0 - k )); a_text $(( int(SR_BX[i]) - 1 )) $(( int(SR_BY[i]) )) '◈◈◈' $CS -2; done
  cmix $LIME $WHITE 0.25; col=$CM; cmix $GLASS $LIME 0.12; a_text $(( int(SR_SX) - 1 )) $SR_SHIPY '◢█◣' $col $CM
  return 0 }
sr_hud() { cmix $PURPLE $WHITE 0.3; AR_HL=(WAVE); AR_HV=($SR_WAVE); AR_HC=($CM)
  if (( SR_ND )); then cmix $RED $WHITE 0.3; AR_HL+=(DIVING); AR_HV+=($SR_ND); AR_HC+=($CM); else cmix $CYAN $WHITE 0.25; AR_HL+=(LEFT); AR_HV+=(${#SR_AL[@]}); AR_HC+=($CM); fi; return 0 }
sr_stats() { AR_SL=(WAVE KILLS SAUCERS DIVERS); AR_SV=($SR_WAVE $SR_KILLED $SR_UFOHITS $SR_DIVED); return 0 }
pv_starraid() {
  local -i x=$1 y=$2 w=$3 h=$4 step dx dy r c sx by nc nr x0 fg; local glyph; local -F b; local -a cols; cols=($MAGENTA $PURPLE $CYAN)
  step=$(( int(AR_T * 2.2) )); ar_tri $(( AR_T * 0.28 )); dx=$(( int(RF * 3) )); dy=$(( (step / 12) % 2 ))
  if (( step % 2 )); then glyph='▞'; else glyph='▚'; fi
  # the formation fills the box it is given · arcade.py's six by three on its 24 × 6,
  # a column more for every three the box is wider, a row more for every four deeper
  nc=$(( (w - 6) / 3 )); (( nc < 6 )) && nc=6; (( nc > 14 )) && nc=14
  nr=$(( 3 + (h >= 12) + (h >= 16) )); x0=$(( (w - nc * 3 - 2) / 2 ))
  for (( r = 0; r < nr; r++ )); do cshade ${cols[$(( r % 3 ))]} 0.95; fg=$CS; cmix $AR_PVBG ${cols[$(( r % 3 ))]} 0.12
    for (( c = 0; c < nc; c++ )); do a_put $(( x + x0 + dx + c * 3 )) $(( y + r + dy )) "$glyph" $fg $CM; done; done
  ar_tri $(( AR_T * 0.45 )); sx=$(( int(RF * (w - 3)) + 1 )); cmix $AR_PVBG $LIME 0.15; a_put $(( x + sx )) $(( y + h - 1 )) '▲' $LIME $CM
  b=$(( AR_T * 2.6 )); b=$(( b - floor(b) )); by=$(( int(h - 2 - b * (h - 3)) ))
  (( by > 0 )) && { cmix $AR_PVBG $AMBER 0.15; a_put $(( x + sx )) $(( y + by )) '│' $AMBER $CM; }
  return 0 }
AR_READY[starraid]=1; AR_PREFIX[starraid]=sr

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# STAR RAIDER · a place to stand, then a shot from it.  THE RAIN IS READ AHEAD:
# every column the ship could reach in a third of a second is scored by the
# bombs and divers that will land on it before it could leave, and by those it
# would run under on the way there; the safest of them, then the nearest the
# target, is where it goes.  The first bomb in sight and a step away from it
# was enough on arcade.py's board and walked into the next one on a wide one.
# The target is the saucer, a diver, or the lowest of the nearest column of
# the block, led by the march -- and a shot goes up whenever the ship is
# under it, moving or not, because the wide board allows it more shots.
sr_demo() {
  local -F px=$SR_SX tx=-999.0 d bd=999.0 ax ay flight step vmax x t tl dang sc bestsc best bx lo hi
  local -i i c r j n st deep; local k
  if (( SR_UFO && SR_UFOX > 0 && SR_UFOX < AR_W )); then tx=$(( SR_UFOX + SR_UFOD * SR_UFOV * ((SR_SHIPY - AR_FT) / SR_SHOTV) ))
  elif (( SR_ND )); then for (( i = 0; i < SR_ND; i++ )); do d=$(( abs(SR_DX[i] - px) )); (( d < bd )) && { bd=$d; tx=${SR_DX[$i]}; }; done
  elif (( ${#SR_AL[@]} )); then
    c=-1; for k in ${(k)SR_AL[@]}; do ax=$(( SR_AX + ${k%%,*} * SR_PITCH )); d=$(( abs(ax - px) )); (( d < bd )) && { bd=$d; c=${k%%,*}; }; done
    deep=-1; for k in ${(k)SR_AL[@]}; do (( ${k%%,*} == c )) && { r=${k#*,}; (( r > deep )) && deep=$r; }; done
    ax=$(( SR_AX + c * SR_PITCH )); ay=$(( SR_AY + deep * 2 ))
    flight=$(( (SR_SHIPY - 1 - ay) / SR_SHOTV )); (( flight < 0.0 )) && flight=0.0
    sr_speed; step=$RF; (( step < 0.001 )) && step=0.001
    tx=$(( ax + SR_ADIR * (flight / step) ))
  fi
  (( tx < -900.0 )) && tx=$px
  (( tx < 2.0 )) && tx=2.0; (( tx > AR_W - 3.0 )) && tx=$(( AR_W - 3.0 ))
  vmax=${ST_MAX[0]:-44}; (( vmax < 1.0 )) && vmax=1.0
  n=$(( int(vmax * 0.35) )); (( n < 3 )) && n=3; st=$(( n > 16 ? n / 8 : 1 ))
  bestsc=1000000000.0; best=$px
  for (( j = -n; j <= n; j += st )); do
    x=$(( px + j )); (( x < 1.0 || x > AR_W - 3.0 )) && continue
    dang=0.0; lo=$(( px < x ? px : x )); hi=$(( px < x ? x : px ))
    for (( i = 0; i < ${#SR_BMX[@]}; i++ )); do
      t=$(( (SR_SHIPY - SR_BMY[i]) / SR_BOMBSPD )); (( t < -0.05 || t > 1.2 )) && continue
      bx=${SR_BMX[$i]}
      if (( abs(bx - x) < 2.2 )); then dang=$(( dang + 2.0 - t ))                        # it lands where the ship would stand
      elif (( bx >= lo - 1.6 && bx <= hi + 1.6 && abs(t - abs(bx - px) / vmax) < 0.2 )); then
        dang=$(( dang + 1.5 - t ))                                                        # it lands as the ship goes under it
      fi
    done
    for (( i = 0; i < SR_ND; i++ )); do
      t=$(( (SR_SHIPY - SR_DY[i]) / (SR_DVY[i] > 1.0 ? SR_DVY[i] : 1.0) )); (( t > 1.5 )) && continue
      (( abs(SR_DX[i] - x) < 3.0 )) && dang=$(( dang + 2.5 - t ))
    done
    sc=$(( dang * 1000.0 + abs(x - tx) + abs(j) * 0.2 ))
    (( sc < bestsc )) && { bestsc=$sc; best=$x; }
  done
  ar_towards $px $best LEFT RIGHT 0.6
  (( abs(px - tx) < 1.6 && ${#SR_SHX[@]} < SR_MAXSHOTS )) && AR_DKEYS+=(SPACE)
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15i · G R I D   R U N N E R        (maze) · the maze, dealt · the prize · the one that cuts ahead
# ══════════════════════════════════════════════════════════════════════════
# There was one maze.  Now it is CARVED, and a new one for every level: a
# randomised spanning tree over a lattice of every other cell, then a third
# of the walls the tree left standing knocked through so the dead ends
# become circuits.  Only the left half is carved and the right is its
# mirror; a two-by-two of open cells is refused; a row or two opens at both
# ends so the wrap goes somewhere.  Then it is CHECKED -- connected from the
# start, every pellet and spawn reachable, the pen no nearer than ten steps
# -- and carved again if the check fails.  The hand-typed maze is the
# fallback, and across four hundred carves it has never once been needed.
typeset -gi GR_W=25 GR_H=13 GR_X=11 GR_Y=2 GR_MIRROR=24 GR_MIN_OPEN=150 GR_MIN_PEN=10
typeset -gF GR_LOOPS=0.34 GR_PRIZE_LIFE=9.5
typeset -ga GR_PRIZE_AT; GR_PRIZE_AT=(40 90)
typeset -gi GR_S=1 GR_CW=2 GR_CH=1 GR_C=12   # a cell's size on the glass · the centre column
typeset -ga GR_XS GR_YS                      # the lattice the carver joins · every other cell of the left half
# THE MAZE IS AS BIG AS THE BOARD LETS IT BE · arcade.py's 25 × 13 on its 72 × 18.
# The width is a 4k+1 so the left half ends on the lattice and the centre column
# is its own mirror; the height is odd.  Past 61 × 35 a maze stops being a maze
# and starts being a chore, so a board with the room for it draws every cell
# twice the size instead -- four columns by two rows -- and keeps the maze a size
# a person can clear.  What the maze holds grows with it: the daemons with its
# reach, the pen's distance, the prize thresholds and the open floor it must
# have with its area, the hunt's and the prize's clocks with its reach.
gr_geom() {
  local -i w h i
  GR_S=1; (( AR_W >= 4 * 45 + 4 && AR_H >= 2 * 21 + 5 )) && GR_S=2
  GR_CW=$(( 2 * GR_S )); GR_CH=$GR_S
  w=$(( (AR_W - 4) / GR_CW )); (( w > 61 )) && w=61; w=$(( ((w - 1) / 4) * 4 + 1 )); (( w < 25 )) && w=25
  h=$(( (AR_H - 5) / GR_CH )); (( h > 35 )) && h=35; (( h % 2 == 0 )) && h=$(( h - 1 )); (( h < 13 )) && h=13
  GR_W=$w; GR_H=$h; GR_MIRROR=$(( w - 1 )); GR_C=$(( (w - 1) / 2 ))
  GR_X=$(( (AR_W - GR_W * GR_CW) / 2 )); GR_Y=$(( 2 + ((AR_H - 5) - GR_H * GR_CH) / 2 ))
  GR_XS=(); for (( i = 1; i < GR_C; i += 2 )); do GR_XS+=($i); done
  GR_YS=(); for (( i = 1; i < GR_H - 1; i += 2 )); do GR_YS+=($i); done
  local -F area=$(( GR_W * GR_H / 325.0 )) reach=$(( (GR_W + GR_H) / 38.0 ))
  GR_MIN_OPEN=$(( int(150 * area) )); GR_MIN_PEN=$(( int(10 * reach) ))
  GR_PRIZE_AT=($(( int(40 * area) )) $(( int(90 * area) )))
  GR_PRIZE_LIFE=$(( 9.5 * reach )); GR_SCARET=$(( GR_SCARET * reach ))
  GR_NGH=$(( int(GR_NGH * sqrt(area) + 0.5) )); (( GR_NGH > 8 )) && GR_NGH=8
  return 0 }
typeset -ga GR_PZG GR_PZW GR_PZC; GR_PZG=('❖' '✿' '✦' '◉'); GR_PZW=(300 700 1500 3000)
typeset -ga GR_FALLBACK
GR_FALLBACK=(
'#########################'
'#o.........#...........o#'
'#.####.###.#.###.#####..#'
'#......#.....#......#...#'
'#.####.#.#####.####.#.#.#'
'#....#.#.....#....#...#.#'
'##.#.#.#####.#.##.#####.#'
'#..#.......#...#........#'
'#.###.####.#.#.#.#####.##'
'#.....#......#.......#..#'
'#.###.#.####.###.###.#..#'
'#o...........#.........o#'
'#########################')
typeset -ga GR_G                       # the grid · index y*GR_W+x · 1 wall 0 floor
typeset -gA GR_WALL GR_DOTS GR_POWER GR_FAR
typeset -ga GR_SPX GR_SPY GR_ROWS_Y GR_ROWS_S
typeset -gi GR_SX GR_SY GR_NGH GR_AMBUSH GR_EATEN GR_PRIZES GR_PRIZEN GR_CHAIN GR_TOTAL
typeset -gi GR_PX GR_PY GR_PPX GR_PPY GR_DX GR_DY GR_WX GR_WY GR_PZ GR_PZX GR_PZY GR_PZI
typeset -gF GR_SPEED GR_GSPEED GR_SCARET GR_SMART GR_SCARE GR_MOVE GR_PZT
typeset -ga GR_GX GR_GY GR_GDX GR_GDY GR_GC GR_GACC GR_GHOME GR_GAHEAD

gr_put() { GR_G[$(( $2 * GR_W + $1 ))]=0; GR_G[$(( $2 * GR_W + GR_MIRROR - $1 ))]=0; return 0 }
gr_carve() {   # → GR_G · 0 on success, 1 to deal again
  local -i i n sx sy x y nx ny ax ay bx by k mx my nj fixx fixy t3; local -a xs ys ea eb wa wb joins pool
  local -A seen; local a b t1 t2
  GR_G=(); for (( i = 0; i < GR_W * GR_H; i++ )); do GR_G[$i]=1; done
  xs=("${GR_XS[@]}"); ys=("${GR_YS[@]}")
  rnd_pick ${#xs[@]}; sx=${xs[$REPLY]}; rnd_pick ${#ys[@]}; sy=${ys[$REPLY]}
  seen=(); seen[$sx,$sy]=1; gr_put $sx $sy
  ea=(); eb=(); wa=(); wb=()
  gr_offer() { local -i x=$1 y=$2 nx ny k
    for k in 0 1 2 3; do case $k in 0) nx=$(( x + 2 )); ny=$y ;; 1) nx=$(( x - 2 )); ny=$y ;; 2) nx=$x; ny=$(( y + 2 )) ;; *) nx=$x; ny=$(( y - 2 )) ;; esac
      (( nx >= 1 && nx < GR_C && nx % 2 == 1 && ny >= 1 && ny < GR_H - 1 && ny % 2 == 1 )) || continue
      [[ -n "${seen[$nx,$ny]:-}" ]] && continue
      ea+=("$x,$y"); eb+=("$nx,$ny"); done; return 0 }
  gr_offer $sx $sy
  while (( ${#ea[@]} )); do
    rnd_pick ${#ea[@]}; i=$REPLY
    a="${ea[$i]}"; b="${eb[$i]}"
    ea=("${ea[@]:0:$i}" "${ea[@]:$(( i + 1 ))}"); eb=("${eb[@]:0:$i}" "${eb[@]:$(( i + 1 ))}")
    if [[ -n "${seen[$b]:-}" ]]; then wa+=("$a"); wb+=("$b"); continue; fi
    seen[$b]=1; bx=${b%%,*}; by=${b#*,}; ax=${a%%,*}; ay=${a#*,}
    gr_put $bx $by; gr_put $(( (ax + bx) / 2 )) $(( (ay + by) / 2 ))
    gr_offer $bx $by
  done
  (( ${#seen[@]} < ${#xs[@]} * ${#ys[@]} )) && return 1
  # knock some of the remaining walls through, for loops · a shuffle first
  n=${#wa[@]}
  for (( i = n - 1; i > 0; i-- )); do rnd_pick $(( i + 1 )); k=$REPLY; t1="${wa[$i]}"; t2="${wb[$i]}"; wa[$i]="${wa[$k]}"; wb[$i]="${wb[$k]}"; wa[$k]="$t1"; wb[$k]="$t2"; done
  for (( i = 0; i < int(n * GR_LOOPS); i++ )); do ax=${wa[$i]%%,*}; ay=${wa[$i]#*,}; bx=${wb[$i]%%,*}; by=${wb[$i]#*,}; gr_put $(( (ax + bx) / 2 )) $(( (ay + by) / 2 )); done
  # the centre column, so the two halves are one maze
  joins=(); for y in "${ys[@]}"; do (( GR_G[y * GR_W + GR_C - 1] == 0 )) && joins+=($y); done
  (( ${#joins[@]} )) || return 1
  n=${#joins[@]}; for (( i = n - 1; i > 0; i-- )); do rnd_pick $(( i + 1 )); k=$REPLY; t3=${joins[$i]}; joins[$i]=${joins[$k]}; joins[$k]=$t3; done
  nj=$(( n / 2 )); (( nj < 1 )) && nj=1
  for (( i = 0; i < nj; i++ )); do y=${joins[$i]}; for (( x = GR_C - 1; x <= GR_C + 1; x++ )); do GR_G[$(( y * GR_W + x ))]=0; done; done
  # tunnels · a row or two at both ends
  rnd_pick 3; n=$(( REPLY == 2 ? 2 : 1 ))
  pool=("${ys[@]}")
  for (( i = 0; i < n; i++ )); do
    (( ${#pool[@]} )) || break
    rnd_pick ${#pool[@]}; y=${pool[$REPLY]}; pool=("${pool[@]:0:$REPLY}" "${pool[@]:$(( REPLY + 1 ))}")
    (( GR_G[y * GR_W + 1] == 0 )) && { GR_G[$(( y * GR_W ))]=0; GR_G[$(( y * GR_W + GR_MIRROR ))]=0; }
  done
  # no plazas
  for (( y = 0; y < GR_H - 1; y++ )); do for (( x = 0; x < GR_W - 1; x++ )); do
    (( GR_G[y * GR_W + x] || GR_G[y * GR_W + x + 1] || GR_G[(y + 1) * GR_W + x] || GR_G[(y + 1) * GR_W + x + 1] )) && continue
    rnd_pick 4; case $REPLY in 0) fixx=$x; fixy=$y ;; 1) fixx=$(( x + 1 )); fixy=$y ;; 2) fixx=$x; fixy=$(( y + 1 )) ;; *) fixx=$(( x + 1 )); fixy=$(( y + 1 )) ;; esac
    GR_G[$(( fixy * GR_W + fixx ))]=1; GR_G[$(( fixy * GR_W + GR_MIRROR - fixx ))]=1
  done; done
  return 0 }
gr_walk() {   # gr_walk SX SY → GR_FAR "x,y" → steps from the start, wrapping
  local -i x y nx ny qh=0 qt=1 k d; local -a qx qy
  GR_FAR=(); GR_FAR[$1,$2]=0; qx=($1); qy=($2)
  while (( qh < qt )); do
    x=${qx[$qh]}; y=${qy[$qh]}; d=${GR_FAR[$x,$y]}; qh=$(( qh + 1 ))
    for k in 0 1 2 3; do case $k in 0) nx=$(( (x + 1) % GR_W )); ny=$y ;; 1) nx=$(( (x + GR_W - 1) % GR_W )); ny=$y ;; 2) nx=$x; ny=$(( y + 1 )) ;; *) nx=$x; ny=$(( y - 1 )) ;; esac
      (( ny < 0 || ny >= GR_H )) && continue; (( GR_G[ny * GR_W + nx] )) && continue
      [[ -n "${GR_FAR[$nx,$ny]:-}" ]] && continue
      GR_FAR[$nx,$ny]=$(( d + 1 )); qx[$qt]=$nx; qy[$qt]=$ny; qt=$(( qt + 1 )); done
  done; return 0 }
gr_dress() {   # a start, a pen, four pellets and the dots on a carved maze · 1 to carve again
  local -i x y low=-1 bestd bd sx sy px py nx ny k cx cy i n; local -a floor; local c; local -A spot pw
  floor=(); for (( y = 0; y < GR_H; y++ )); do for (( x = 0; x < GR_W; x++ )); do (( GR_G[y * GR_W + x] )) || floor+=("$x,$y"); done; done
  (( ${#floor[@]} < GR_MIN_OPEN )) && return 1
  for c in "${floor[@]}"; do (( ${c#*,} > low )) && low=${c#*,}; done
  bestd=999; for c in "${floor[@]}"; do (( ${c#*,} == low )) || continue; bd=$(( ${c%%,*} - GR_W / 2 )); (( bd < 0 )) && bd=$(( -bd )); (( bd < bestd )) && { bestd=$bd; sx=${c%%,*}; }; done
  sy=$low
  gr_walk $sx $sy
  (( ${#GR_FAR[@]} != ${#floor[@]} )) && return 1          # an island somewhere
  # THE PEN IS NOT ALLOWED TO OPEN ON TOP OF YOU
  bestd=99999; px=-1
  for c in "${floor[@]}"; do (( ${GR_FAR[$c]:-0} >= GR_MIN_PEN )) || continue
    bd=$(( ${c%%,*} - GR_W / 2 )); (( bd < 0 )) && bd=$(( -bd )); k=$(( ${c#*,} - GR_H / 2 )); (( k < 0 )) && k=$(( -k )); bd=$(( bd * 2 + k * 3 ))
    (( bd < bestd )) && { bestd=$bd; px=${c%%,*}; py=${c#*,}; }; done
  (( px < 0 )) && return 1
  GR_SPX=($px); GR_SPY=($py); spot=(); spot[$px,$py]=1
  for k in 0 1 2 3 4 5; do case $k in 0) nx=$(( (px + GR_W - 1) % GR_W )); ny=$py ;; 1) nx=$(( (px + 1) % GR_W )); ny=$py ;; 2) nx=$px; ny=$(( py - 1 )) ;; 3) nx=$px; ny=$(( py + 1 )) ;; 4) nx=$(( (px + GR_W - 2) % GR_W )); ny=$py ;; *) nx=$(( (px + 2) % GR_W )); ny=$py ;; esac
    (( ny >= 0 && ny < GR_H )) || continue; (( GR_G[ny * GR_W + nx] )) && continue; [[ -n "${spot[$nx,$ny]:-}" ]] && continue
    GR_SPX+=($nx); GR_SPY+=($ny); spot[$nx,$ny]=1; done
  (( ${#GR_SPX[@]} < 4 )) && return 1
  GR_SPX=("${GR_SPX[@]:0:4}"); GR_SPY=("${GR_SPY[@]:0:4}"); spot=(); for (( i = 0; i < 4; i++ )); do spot[${GR_SPX[$i]},${GR_SPY[$i]}]=1; done
  # four pellets, one per corner, each the open cell nearest that corner
  pw=(); GR_POWER=()
  for k in 0 1 2 3; do case $k in 0) cx=1; cy=1 ;; 1) cx=$(( GR_W - 2 )); cy=1 ;; 2) cx=1; cy=$(( GR_H - 2 )) ;; *) cx=$(( GR_W - 2 )); cy=$(( GR_H - 2 )) ;; esac
    bestd=99999; nx=-1
    for c in "${floor[@]}"; do [[ -n "${pw[$c]:-}" || "$c" == "$sx,$sy" || -n "${spot[$c]:-}" ]] && continue
      bd=$(( ${c%%,*} - cx )); (( bd < 0 )) && bd=$(( -bd )); i=$(( ${c#*,} - cy )); (( i < 0 )) && i=$(( -i )); bd=$(( bd + i * 2 ))
      (( bd < bestd )) && { bestd=$bd; nx=${c%%,*}; ny=${c#*,}; }; done
    (( nx < 0 )) && return 1
    pw[$nx,$ny]=1; done
  (( ${#pw[@]} != 4 )) && return 1
  GR_POWER=(); for c in ${(k)pw[@]}; do GR_POWER[$c]=1; done
  GR_DOTS=(); n=0
  for c in "${floor[@]}"; do [[ -n "${pw[$c]:-}" || "$c" == "$sx,$sy" || -n "${spot[$c]:-}" ]] && continue; GR_DOTS[$c]=1; n=$(( n + 1 )); done
  (( n < GR_MIN_OPEN - 20 )) && return 1
  GR_WALL=(); for (( y = 0; y < GR_H; y++ )); do for (( x = 0; x < GR_W; x++ )); do (( GR_G[y * GR_W + x] )) && GR_WALL[$x,$y]=1; done; done
  GR_SX=$sx; GR_SY=$sy
  return 0 }
gr_from_rows() {   # the hand-typed fallback, in the same shape the carver answers in
  local -i x y; local row ch
  GR_W=25; GR_H=13; GR_MIRROR=24; GR_C=12
  GR_X=$(( (AR_W - GR_W * GR_CW) / 2 )); GR_Y=$(( 2 + ((AR_H - 5) - GR_H * GR_CH) / 2 ))
  GR_G=(); GR_WALL=(); GR_DOTS=(); GR_POWER=()
  for (( y = 0; y < GR_H; y++ )); do row="${GR_FALLBACK[$y]}"; for (( x = 0; x < GR_W; x++ )); do ch="${row[$x]}"
    case "$ch" in '#') GR_G[$(( y * GR_W + x ))]=1; GR_WALL[$x,$y]=1 ;; '.') GR_G[$(( y * GR_W + x ))]=0; GR_DOTS[$x,$y]=1 ;; o) GR_G[$(( y * GR_W + x ))]=0; GR_POWER[$x,$y]=1 ;; *) GR_G[$(( y * GR_W + x ))]=0 ;; esac; done; done
  GR_SX=12; GR_SY=11; GR_SPX=(12 11 10 12); GR_SPY=(5 5 5 3); return 0 }
gr_deal() {   # a maze, or the one that was checked by hand
  local -i try ok c; local k
  for (( try = 0; try < 24; try++ )); do
    gr_carve || continue
    gr_dress || continue
    # the check · every dot, pellet and spawn reachable from the start
    gr_walk $GR_SX $GR_SY; ok=1
    for k in ${(k)GR_DOTS[@]} ${(k)GR_POWER[@]}; do [[ -n "${GR_FAR[$k]:-}" ]] || { ok=0; break; }; done
    for (( c = 0; c < 4; c++ )); do [[ -n "${GR_FAR[${GR_SPX[$c]},${GR_SPY[$c]}]:-}" ]] || ok=0; done
    (( ${#GR_DOTS[@]} + ${#GR_POWER[@]} + 1 + 4 < GR_MIN_OPEN )) && ok=0
    (( ok )) && return 0
  done
  gr_from_rows; return 0 }

gr_begin() {
  AR_G_LEGEND='▲▼◄► RUN      [P] PAUSE      [Q] CASH OUT'
  AR_G_HOWTO='eat the grid  ·  the big nodes turn the daemons edible'
  AR_G_ACC=$AMBER; GR_PZC=($LIME $PINK $CYAN $AMBER)
  ar_pick 7.0 9.0 11.0 13.0; GR_SPEED=$REPLY
  ar_pick 4.6 6.4 8.4 10.4; GR_GSPEED=$REPLY
  ar_pick 2 3 3 4; GR_NGH=$REPLY
  ar_pick 9.0 7.0 5.0 3.5; GR_SCARET=$REPLY
  ar_pick 0.35 0.55 0.75 0.92; GR_SMART=$REPLY
  ar_pick 0 0 1 2; GR_AMBUSH=$REPLY
  gr_geom
  AR_LIVES=3; GR_EATEN=0; GR_PZ=0; GR_PRIZES=0; GR_PRIZEN=0; GR_CHAIN=0; GR_SCARE=0.0
  gr_maze; gr_place
  return 0 }
gr_maze() { gr_deal; GR_TOTAL=$(( ${#GR_DOTS[@]} + ${#GR_POWER[@]} )); gr_bake; return 0 }
gr_bake() {   # one string per maze row, so paint issues 13 writes, not 150
  local -i x y; local line
  GR_ROWS_Y=(); GR_ROWS_S=()
  local wall='▓▓' open='  '; (( GR_S > 1 )) && { wall='▓▓▓▓'; open='    '; }
  for (( y = 0; y < GR_H; y++ )); do line=''; for (( x = 0; x < GR_W; x++ )); do if [[ -n "${GR_WALL[$x,$y]:-}" ]]; then line+="$wall"; else line+="$open"; fi; done
    while [[ "$line" == *' ' ]]; do line="${line%?}"; done
    [[ -n "$line" ]] && { GR_ROWS_Y+=($y); GR_ROWS_S+=("$line"); }; done; return 0 }
gr_place() {
  local -i i; local -a cols; cols=($RED $PINK $CYAN $AMBER)
  GR_PX=$GR_SX; GR_PY=$GR_SY; GR_PPX=$GR_SX; GR_PPY=$GR_SY; GR_DX=0; GR_DY=0; GR_WX=0; GR_WY=0; GR_MOVE=0.0
  GR_GX=(); GR_GY=(); GR_GDX=(); GR_GDY=(); GR_GC=(); GR_GACC=(); GR_GHOME=(); GR_GAHEAD=()
  for (( i = 0; i < GR_NGH; i++ )); do
    GR_GX+=(${GR_SPX[$(( i % 4 ))]}); GR_GY+=(${GR_SPY[$(( i % 4 ))]}); GR_GDX+=(0); GR_GDY+=(-1); GR_GC+=(${cols[$(( i % 4 ))]})
    GR_GACC+=(0.0); GR_GHOME+=($(( 1.0 + 1.2 * i ))); GR_GAHEAD+=($(( i < GR_AMBUSH ? 1 : 0 )))
  done
  GR_SCARE=0.0; return 0 }
gr_open() { local -i x=$(( ($1 + GR_W) % GR_W )) y=$2; (( y >= 0 && y < GR_H )) && [[ -z "${GR_WALL[$x,$y]:-}" ]] }
gr_update() {   # gr_update DT
  local -F dt=$1 rate; local -i guard g gg wasx wasy worth; local k cell
  for k in "${AR_KEYS[@]}"; do case "$k" in UP|W) GR_WX=0; GR_WY=-1 ;; DOWN|S) GR_WX=0; GR_WY=1 ;; LEFT|A) GR_WX=-1; GR_WY=0 ;; RIGHT|D) GR_WX=1; GR_WY=0 ;; esac; done
  if (( GR_SCARE > 0 )); then GR_SCARE=$(( GR_SCARE - dt )); (( GR_SCARE <= 0.0 )) && { GR_SCARE=0.0; GR_CHAIN=0; }; fi
  (( GR_PZ )) && (( AR_RT - GR_PZT > GR_PRIZE_LIFE )) && GR_PZ=0
  GR_MOVE=$(( GR_MOVE + dt * GR_SPEED )); (( GR_MOVE > 3.0 )) && GR_MOVE=3.0
  guard=0
  while (( GR_MOVE >= 1.0 && guard < 3 )); do
    GR_MOVE=$(( GR_MOVE - 1.0 )); guard=$(( guard + 1 ))
    (( GR_WX || GR_WY )) && gr_open $(( GR_PX + GR_WX )) $(( GR_PY + GR_WY )) && { GR_DX=$GR_WX; GR_DY=$GR_WY; }
    GR_PPX=$GR_PX; GR_PPY=$GR_PY
    gr_open $(( GR_PX + GR_DX )) $(( GR_PY + GR_DY )) && { GR_PX=$(( (GR_PX + GR_DX + GR_W) % GR_W )); GR_PY=$(( GR_PY + GR_DY )); }
    cell="$GR_PX,$GR_PY"
    if (( GR_PZ && GR_PX == GR_PZX && GR_PY == GR_PZY )); then worth=$(( ${GR_PZW[$GR_PZI]} * AR_LEVEL )); ar_add $worth; GR_PRIZES=$(( GR_PRIZES + 1 )); GR_PZ=0; ar_snd coin; fi
    if [[ -n "${GR_DOTS[$cell]:-}" ]]; then unset "GR_DOTS[$cell]"; GR_EATEN=$(( GR_EATEN + 1 )); ar_add 10; gr_prize_check; ar_snd move
    elif [[ -n "${GR_POWER[$cell]:-}" ]]; then unset "GR_POWER[$cell]"; GR_EATEN=$(( GR_EATEN + 1 )); ar_add 50; GR_SCARE=$GR_SCARET; GR_CHAIN=0; ar_snd coin; fi
    if (( ${#GR_DOTS[@]} == 0 && ${#GR_POWER[@]} == 0 )); then
      AR_LEVEL=$(( AR_LEVEL + 1 )); (( AR_LEVEL > 20 )) && AR_LEVEL=20; ar_add $(( 1000 * AR_LEVEL )); ar_snd coin
      gr_next_level; return 0
    fi
    gr_touch -1 && return 0
  done
  for (( g = 0; g < GR_NGH; g++ )); do
    if (( GR_GHOME[g] > 0 )); then GR_GHOME[$g]=$(( GR_GHOME[g] - dt )); continue; fi
    rate=$GR_GSPEED; (( GR_SCARE > 0 )) && rate=$(( rate * 0.55 ))
    GR_GACC[$g]=$(( GR_GACC[g] + dt * rate )); (( GR_GACC[g] > 3.0 )) && GR_GACC[$g]=3.0
    gg=0
    while (( GR_GACC[g] >= 1.0 && gg < 3 )); do
      GR_GACC[$g]=$(( GR_GACC[g] - 1.0 )); gg=$(( gg + 1 ))
      wasx=${GR_GX[$g]}; wasy=${GR_GY[$g]}
      gr_ghost_step $g
      if (( (GR_GX[g] == GR_PX && GR_GY[g] == GR_PY) || (wasx == GR_PX && wasy == GR_PY && GR_GX[g] == GR_PPX && GR_GY[g] == GR_PPY) )); then
        gr_touch $g && return 0
        break
      fi
    done
  done
  return 0 }
gr_prize_check() {   # twice a level, at the two counts every maze game used
  local -i this pzi best=-1 d ax ay bx by s isspot; local k
  (( GR_PZ || GR_PRIZEN >= 2 )) && return 0
  this=$(( GR_TOTAL - (${#GR_DOTS[@]} + ${#GR_POWER[@]}) ))
  (( this < GR_PRIZE_AT[GR_PRIZEN] )) && return 0
  GR_PRIZEN=$(( GR_PRIZEN + 1 ))
  pzi=$(( AR_LEVEL - 1 )); (( pzi > 3 )) && pzi=3
  bx=-1
  for k in ${(k)GR_DOTS[@]}; do ax=${k%%,*}; ay=${k#*,}
    d=$(( ax - GR_PX )); (( d < 0 )) && d=$(( -d )); by=$(( ay - GR_PY )); (( by < 0 )) && by=$(( -by )); (( d + by < 4 )) && continue
    isspot=0; for (( s = 0; s < 4; s++ )); do (( GR_SPX[s] == ax && GR_SPY[s] == ay )) && isspot=1; done; (( isspot )) && continue
    d=$(( ax - GR_W / 2 )); (( d < 0 )) && d=$(( -d )); by=$(( ay - GR_H / 2 )); (( by < 0 )) && by=$(( -by )); d=$(( d * 2 + by * 3 ))
    (( best < 0 || d < best )) && { best=$d; bx=$ax; by=$ay; GR_PZY=$ay; }
  done
  (( bx < 0 )) && return 0
  GR_PZX=$bx; GR_PZ=1; GR_PZT=$AR_RT; GR_PZI=$pzi; ar_snd select; return 0 }
gr_next_level() {   # a new maze, not the same one swept
  GR_PZ=0; GR_PRIZEN=0
  GR_SPEED=$(( GR_SPEED + 0.6 )); (( GR_SPEED > 16.0 )) && GR_SPEED=16.0
  GR_GSPEED=$(( GR_GSPEED + 0.8 )); (( GR_GSPEED > 15.0 )) && GR_GSPEED=15.0
  gr_maze; gr_place; return 0 }
gr_ghost_step() {   # gr_ghost_step G
  local -i g=$1 k dx dy n i tx ty nx ny best bd flee j; local -a ox oy oc
  ox=(); oy=()
  for k in 0 1 2 3; do case $k in 0) dx=1; dy=0 ;; 1) dx=-1; dy=0 ;; 2) dx=0; dy=1 ;; *) dx=0; dy=-1 ;; esac
    (( dx == -GR_GDX[g] && dy == -GR_GDY[g] )) && continue
    gr_open $(( GR_GX[g] + dx )) $(( GR_GY[g] + dy )) && { ox+=($dx); oy+=($dy); }; done
  (( ${#ox[@]} )) || { ox=($(( -GR_GDX[g] ))); oy=($(( -GR_GDY[g] ))); }
  n=${#ox[@]}
  rnd_f
  if (( RF < GR_SMART )); then
    flee=$(( GR_SCARE > 0 )); tx=$GR_PX; ty=$GR_PY
    if (( GR_GAHEAD[g] && ! flee && (GR_DX || GR_DY) )); then tx=$(( (GR_PX + GR_DX * 4 + GR_W) % GR_W )); ty=$(( GR_PY + GR_DY * 4 )); (( ty < 0 )) && ty=0; (( ty > GR_H - 1 )) && ty=$(( GR_H - 1 )); fi
    best=0; bd=999999
    for (( i = 0; i < n; i++ )); do nx=$(( (GR_GX[g] + ox[i] + GR_W) % GR_W )); ny=$(( GR_GY[g] + oy[i] ))
      j=$(( nx - tx )); (( j < 0 )) && j=$(( -j )); k=$(( ny - ty )); (( k < 0 )) && k=$(( -k )); j=$(( j + k )); (( flee )) && j=$(( -j ))
      (( j < bd )) && { bd=$j; best=$i; }; done
  else rnd_pick $n; best=$REPLY; fi
  GR_GDX[$g]=${ox[$best]}; GR_GDY[$g]=${oy[$best]}
  GR_GX[$g]=$(( (GR_GX[g] + GR_GDX[g] + GR_W) % GR_W )); GR_GY[$g]=$(( GR_GY[g] + GR_GDY[g] )); return 0 }
gr_touch() {   # gr_touch G|-1 → 0 when the round or the life ended
  local -i only=$1 g lo hi
  if (( only >= 0 )); then lo=$only; hi=$only; else lo=0; hi=$(( GR_NGH - 1 )); fi
  for (( g = lo; g <= hi; g++ )); do
    (( GR_GHOME[g] > 0 )) && continue
    if (( only >= 0 || (GR_GX[g] == GR_PX && GR_GY[g] == GR_PY) )); then
      if (( GR_SCARE > 0 )); then
        GR_CHAIN=$(( GR_CHAIN + 1 )); ar_add $(( 200 * (GR_CHAIN < 4 ? GR_CHAIN : 4) ))
        GR_GX[$g]=${GR_SPX[0]}; GR_GY[$g]=${GR_SPY[0]}; GR_GHOME[$g]=2.0; ar_snd coin
      else
        AR_LIVES=$(( AR_LIVES - 1 )); ar_snd error
        if (( AR_LIVES <= 0 )); then AR_ALIVE=0; else gr_place; fi
        return 0
      fi
    fi
  done; return 1 }
gr_at() {   # gr_at X Y GLYPH2 FG BG · a sprite in its maze cell · on a doubled cell, centred and two rows tall
  local -i r
  for (( r = 0; r < GR_CH; r++ )); do a_text $(( GR_X + $1 * GR_CW + GR_CW / 2 - 1 )) $(( GR_Y + $2 * GR_CH + r )) "$3" $4 $5; done
  return 0 }
gr_paint() {   # gr_paint T
  local -F t=$1 pulse left fade; local -i i wc dc col face bg x y g bl; local k s right
  cmix $BLUE $PURPLE 0.4; cshade $CM 0.55; wc=$CS
  local -i r kk base
  for (( i = 0; i < ${#GR_ROWS_Y[@]}; i++ )); do for (( r = 0; r < GR_CH; r++ )); do a_text $GR_X $(( GR_Y + GR_ROWS_Y[i] * GR_CH + r )) "${GR_ROWS_S[$i]}" $wc -2; done; done
  cshade $AMBER 0.75; dc=$CS
  # the dots straight into the cells · a big maze is a thousand of them
  base=$(( (OY + R_SCR + AY + GR_Y + GR_CH / 2) * TCOLS + OX + C_SCR + AX + GR_X + GR_CW / 2 - 1 ))
  for k in "${(@k)GR_DOTS[@]}"; do kk=$(( base + ${k#*,} * GR_CH * TCOLS + ${k%%,*} * GR_CW )); GCH[$kk]='·'; GF[$kk]=$dc; done
  ar_wave $t 2.0; pulse=$(( 0.55 + 0.45 * WV )); cmix $AMBER $WHITE $(( 0.5 * pulse ))
  for k in ${(k)GR_POWER[@]}; do a_put $(( GR_X + ${k%%,*} * GR_CW + GR_CW / 2 - 1 )) $(( GR_Y + ${k#*,} * GR_CH + GR_CH / 2 )) '◆' $CM -2; done
  if (( GR_PZ )); then
    left=$(( GR_PRIZE_LIFE - (AR_RT - GR_PZT) )); if (( left > 3.0 )); then fade=1.0; else ar_wave $t 4.0; fade=$(( 0.35 + 0.65 * WV )); fi
    col=${GR_PZC[$GR_PZI]}; cmix $col $WHITE $(( 0.45 * fade )); face=$CM; cmix $GLASS $col $(( 0.20 * fade ))
    gr_at $GR_PZX $GR_PZY "${GR_PZG[$GR_PZI]} " $face $CM
  fi
  for (( g = 0; g < GR_NGH; g++ )); do
    if (( GR_GHOME[g] > 0 )); then cshade $GREY 0.55; col=$CS; s='▒▒'
    elif (( GR_GAHEAD[g] && GR_SCARE <= 0 )); then col=${GR_GC[$g]}; s='▛▜'
    elif (( GR_SCARE > 0 )); then bl=$(( GR_SCARE < 1.6 && int(t * 8) % 2 == 0 )); if (( bl )); then col=$WHITE; else cmix $BLUE $WHITE 0.25; col=$CM; fi; s='▚▞'
    else col=${GR_GC[$g]}; s='▟▙'; fi
    cmix $GLASS $col 0.12; gr_at ${GR_GX[$g]} ${GR_GY[$g]} "$s" $col $CM
  done
  cmix $AMBER $WHITE 0.35; col=$CM; cmix $GLASS $AMBER 0.16
  if (( int(t * 9) % 2 == 0 )); then gr_at $GR_PX $GR_PY '◖◗' $col $CM; else gr_at $GR_PX $GR_PY '◍◍' $col $CM; fi
  y=$(( AR_H - 1 )); cmix $BLUE $PURPLE 0.4; cshade $CM 0.45
  s=''; for (( i = 0; i < GR_W * GR_CW; i++ )); do s+='─'; done; a_text $GR_X $(( y - 1 )) "$s" $CS -2
  if (( GR_SCARE > 0 )); then
    local -i n=$(( int(12 * GR_SCARE / (GR_SCARET > 0.1 ? GR_SCARET : 0.1) + 0.5) )); (( n > 12 )) && n=12
    cmix $BLUE $WHITE 0.4; col=$CM; cshade $GREY 0.35
    for (( i = 0; i < 12; i++ )); do if (( i < n )); then a_put $(( GR_X + i )) $y '█' $col -2; else a_put $(( GR_X + i )) $y '░' $CS -2; fi; done
    ar_f1 $GR_SCARE; cmix $BLUE $WHITE 0.35; a_text $(( GR_X + 13 )) $y "HUNT ${REPLY}s" $CM -2
  elif (( GR_PZ )); then left=$(( GR_PRIZE_LIFE - (AR_RT - GR_PZT) )); (( left < 0.0 )) && left=0.0; ar_f1 $left
    local tl="$REPLY"; ar_shown $(( ${GR_PZW[$GR_PZI]} * AR_LEVEL ))     # what the board would credit for it
    cmix ${GR_PZC[$GR_PZI]} $WHITE 0.4; a_text $GR_X $y "${GR_PZG[$GR_PZI]}  $REPLY  ·  ${tl}s" $CM -2
  else cshade $AMBER 0.95; a_text $GR_X $y "$(( ${#GR_DOTS[@]} + ${#GR_POWER[@]} )) DOTS LEFT" $CS -2; fi
  right="LEVEL $AR_LEVEL   ◆ ${#GR_POWER[@]}"; cmix $BLUE $WHITE 0.2; a_text $(( GR_X + GR_W * GR_CW - ${#right} )) $y "$right" $CM -2
  return 0 }
gr_hud() { ar_pad $(( ${#GR_DOTS[@]} + ${#GR_POWER[@]} )) 3; cmix $AMBER $WHITE 0.25; AR_HL=(DOTS); AR_HV=("$REPLY"); AR_HC=($CM)
  if (( GR_PZ )); then ar_shown $(( ${GR_PZW[$GR_PZI]} * AR_LEVEL )); cmix ${GR_PZC[$GR_PZI]} $WHITE 0.3; AR_HL+=(PRIZE); AR_HV+=($REPLY); AR_HC+=($CM)
  else ar_pad $AR_LEVEL 2; cmix $CYAN $WHITE 0.25; AR_HL+=(LVL); AR_HV+=("$REPLY"); AR_HC+=($CM); fi; return 0 }
gr_stats() { AR_SL=(EATEN LEVEL PRIZES); AR_SV=($GR_EATEN $AR_LEVEL $GR_PRIZES); return 0 }
typeset -g PVG_AT=''; typeset -ga PVG_CH PVG_FG     # the preview's maze, a row at a time · kept per size
pv_gridrunner() {
  local -i x=$1 y=$2 w=$3 h=$4 r c px py gx gy k base; local -F u; local rc rf
  cmix $BLUE $PURPLE 0.4; cshade $CM 0.55; local -i wc=$CS; cshade $AMBER 0.75; local -i dc=$CS
  if (( AR_DIRECT )); then
    # THE MAZE NEVER MOVES · a big box is a thousand cells of it, so it is laid
    # out once a size, and each row goes into the grid as one slice
    if [[ "$PVG_AT" != "$w:$h:$wc:$dc" ]]; then
      PVG_CH=(); PVG_FG=()
      for (( r = 0; r < h; r++ )); do
        rc=''; rf=''
        for (( c = 0; c < w; c++ )); do
          if (( r % 2 == 0 && c % 4 != 3 && r != 0 || (r == 0 || r == h - 1) && c % 5 == 2 )); then rc+='▓'$'\x1f'; rf+="$wc "
          elif (( (r + c) % 2 )); then rc+='·'$'\x1f'; rf+="$dc "
          else rc+=' '$'\x1f'; rf+="$dc "; fi
        done
        PVG_CH+=("${rc%$'\x1f'}"); PVG_FG+=("$rf")
      done
      PVG_AT="$w:$h:$wc:$dc"
    fi
    base=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX + x ))
    for (( r = 0; r < h; r++ )); do
      k=$(( base + r * TCOLS ))
      GCH[$k,$(( k + w - 1 ))]=("${(@ps:\x1f:)PVG_CH[$r]}"); GF[$k,$(( k + w - 1 ))]=(${=PVG_FG[$r]})
    done
  else
    for (( r = 0; r < h; r++ )); do for (( c = 0; c < w; c++ )); do
      if (( r % 2 == 0 && c % 4 != 3 && r != 0 || (r == 0 || r == h - 1) && c % 5 == 2 )); then a_put $(( x + c )) $(( y + r )) '▓' $wc -2
      elif (( (r + c) % 2 )); then a_put $(( x + c )) $(( y + r )) '·' $dc -2; fi; done; done
  fi
  ar_tri $(( AR_T * 0.3 )); px=$(( int(RF * (w - 2)) )); py=$(( 1 + 2 * (int(AR_T * 0.3) % ((h - 1) / 2)) ))
  cmix $AMBER $WHITE 0.35; a_put $(( x + px )) $(( y + py )) '◗' $CM -2
  ar_tri $(( AR_T * 0.22 + 0.5 )); gx=$(( int(RF * (w - 2)) )); gy=$(( 1 + 2 * (int(AR_T * 0.22 + 1) % ((h - 1) / 2)) ))
  a_put $(( x + gx )) $(( y + gy )) '▟' $RED -2
  return 0 }
AR_READY[gridrunner]=1; AR_PREFIX[gridrunner]=gr

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# GRID RUNNER · breadth-first to the nearest thing worth having, two cells clear of any daemon that can bite
gr_demo() {
  local -A want danger seen; local -a qx qy; local k cell; local -i g dx dy x y nx ny qh qt pass d best far fx
  local goal=''
  if (( GR_PZ )); then want[$GR_PZX,$GR_PZY]=1; else for k in ${(k)GR_DOTS[@]} ${(k)GR_POWER[@]}; do want[$k]=1; done; fi
  (( ${#want[@]} )) || return 0
  if (( GR_SCARE <= 0.6 )); then
    for (( g = 0; g < ${#GR_GX[@]}; g++ )); do
      (( GR_GHOME[g] > 0 )) && continue
      for (( dx = -2; dx <= 2; dx++ )); do for (( dy = -2; dy <= 2; dy++ )); do danger[$(( (GR_GX[g] + dx + GR_W) % GR_W )),$(( GR_GY[g] + dy ))]=1; done; done
    done
  fi
  for pass in 0 1; do            # the safe route, then any route
    seen=(); seen[$GR_PX,$GR_PY]=S; qx=($GR_PX); qy=($GR_PY); qh=0; qt=1; goal=''
    while (( qh < qt )); do
      x=${qx[$qh]}; y=${qy[$qh]}; qh=$(( qh + 1 ))
      [[ -n "${want[$x,$y]:-}" ]] && { goal="$x,$y"; break; }
      for d in 0 1 2 3; do
        case $d in 0) nx=$x; ny=$(( y - 1 )) ;; 1) nx=$x; ny=$(( y + 1 )) ;; 2) nx=$(( x - 1 )); ny=$y ;; *) nx=$(( x + 1 )); ny=$y ;; esac
        nx=$(( (nx + GR_W) % GR_W ))
        gr_open $nx $ny || continue
        [[ -n "${seen[$nx,$ny]:-}" ]] && continue
        (( pass == 0 )) && [[ -n "${danger[$nx,$ny]:-}" ]] && ! (( x == GR_PX && y == GR_PY )) && continue
        seen[$nx,$ny]="$x,$y"; qx[$qt]=$nx; qy[$qt]=$ny; qt=$(( qt + 1 ))
      done
    done
    [[ -n "$goal" ]] || continue
    cell="$goal"
    while [[ "${seen[$cell]}" != S && "${seen[$cell]}" != "$GR_PX,$GR_PY" ]]; do cell="${seen[$cell]}"; done
    dx=$(( ${cell%%,*} - GR_PX )); dy=$(( ${cell#*,} - GR_PY ))
    (( dx > 1 )) && dx=-1; (( dx < -1 )) && dx=1
    if (( dy < 0 )); then AR_DKEYS+=(UP); elif (( dy > 0 )); then AR_DKEYS+=(DOWN); elif (( dx < 0 )); then AR_DKEYS+=(LEFT); elif (( dx > 0 )); then AR_DKEYS+=(RIGHT); fi
    return 0
  done
  # NO ROUTE AT ALL MEANS RUN · the open way furthest from the nearest daemon that can bite
  best=-1; local pick=''
  for d in 0 1 2 3; do
    case $d in 0) nx=$GR_PX; ny=$(( GR_PY - 1 )); k=UP ;; 1) nx=$GR_PX; ny=$(( GR_PY + 1 )); k=DOWN ;; 2) nx=$(( GR_PX - 1 )); ny=$GR_PY; k=LEFT ;; *) nx=$(( GR_PX + 1 )); ny=$GR_PY; k=RIGHT ;; esac
    nx=$(( (nx + GR_W) % GR_W )); gr_open $nx $ny || continue
    far=99; for (( g = 0; g < ${#GR_GX[@]}; g++ )); do (( GR_GHOME[g] > 0 )) && continue; fx=$(( abs(nx - GR_GX[g]) + abs(ny - GR_GY[g]) )); (( fx < far )) && far=$fx; done
    (( far > best )) && { best=$far; pick=$k; }
  done
  [[ -n "$pick" ]] && AR_DKEYS+=($pick)
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15j · L A S E R   D O D G E        (reflex) · the blink, and the crosses
# ══════════════════════════════════════════════════════════════════════════
# Sixty seconds of steering away from lines.  THE BLINK ([SPACE]) throws you
# six cells the way you were already going, instantly, then will not do it
# again for a couple of seconds: a safety net on ROOKIE, a last resort on
# INSANE.  THE CROSSES are what EXPERT and INSANE fire — a rail across and a
# rail down, lit at the same moment, and there is no gliding out of both.
# A dealt round picks three or four PHRASES out of the book and plays those,
# so the shape of the pressure is readable inside one board and different on
# the next.
typeset -gi LD_TOP=2 LD_BOT=16                  # FIELD_TOP + 1 .. SCR_H - 2
typeset -gF LD_LX=1.0 LD_LY=1.0 LD_BLX=6.0 LD_BLY=4.0   # the field over arcade.py's, each way · the blink's reach
typeset -ga LD_BOOK; LD_BOOK=(sweep comb pincer cross box rain)
typeset -gF LD_WARN LD_GRACET LD_GAP0 LD_GAPMIN LD_BURN LD_BLINKCOOL LD_CROSS
typeset -gF LD_BLINKT LD_CELLT LD_SPAWNT LD_GRACE LD_X LD_Y
typeset -gi LD_MAXLIVE LD_BLINKS LD_FX LD_FY LD_PICKED LD_DODGED LD_NB LD_NP LD_NC
typeset -ga LD_PHR                       # this board's phrases
typeset -ga LD_PW LD_PV LD_PP            # pending · when vertical pos (-1 = dealt on arrival)
typeset -ga LD_BV LD_BP LD_BT LD_BH      # beams · vertical column-or-row age hit
typeset -ga LD_CX LD_CY LD_CL            # energy cells · column row life
typeset -g  LD_ROW_WARN='' LD_ROW_FIRE=''
{ local -i _i; for (( _i = 0; _i < 70; _i++ )); do LD_ROW_WARN+='┈'; LD_ROW_FIRE+='▀'; done; }
ld_begin() {
  AR_G_LEGEND='▲▼◄► DODGE   [SPACE] BLINK   [P] PAUSE   [Q] CASH OUT'
  AR_G_HOWTO='the rails flash before they fire  ·  [SPACE] blinks you clear'
  AR_G_ACC=$RED
  ar_pick 1.15 0.85 0.60 0.42; LD_WARN=$REPLY
  ar_pick 1.40 1.10 0.85 0.65; LD_GRACET=$REPLY
  ar_pick 1.60 1.15 0.85 0.60; LD_GAP0=$REPLY
  ar_pick 0.70 0.50 0.34 0.24; LD_GAPMIN=$REPLY
  ar_pick 0.34 0.40 0.46 0.52; LD_BURN=$REPLY
  ar_pick 2 3 4 6; LD_MAXLIVE=$REPLY
  ar_pick 1.5 2.0 2.6 3.2; LD_BLINKCOOL=$REPLY
  ar_pick 0.0 0.0 0.28 0.48; LD_CROSS=$REPLY
  LD_BLINKT=0.0; LD_BLINKS=0; LD_FX=1; LD_FY=0
  # THE ROUND GETS A VOCABULARY · three or four phrases out of the book, shuffled
  local -a book cnt; local -i i j n; local tmp
  if (( LD_CROSS > 0.0 )); then book=("${LD_BOOK[@]}"); else book=(sweep comb pincer rain); fi
  n=${#book[@]}
  for (( i = n - 1; i > 0; i-- )); do rnd_int 0 $i; j=$REPLY; tmp=${book[$i]}; book[$i]=${book[$j]}; book[$j]=$tmp; done
  cnt=(3 3 4); rnd_pick 3; n=${cnt[$REPLY]}
  LD_PHR=("${book[@]:0:$n}")
  LD_PW=(); LD_PV=(); LD_PP=(); LD_NP=0
  LD_BV=(); LD_BP=(); LD_BT=(); LD_BH=(); LD_NB=0
  LD_CX=(); LD_CY=(); LD_CL=(); LD_NC=0
  AR_LIVES=3; LD_CELLT=4.0; LD_PICKED=0; LD_SPAWNT=1.2; LD_DODGED=0; LD_GRACE=0.0
  # THE FIELD IS THE BOARD · arcade.py's rows 2..16 across 72.  A rail is a whole
  # row or column, so a bigger field needs more of them live at once to be as
  # dense, and a little less wait between them; the diamond's stick and its
  # blink reach grow with the field so crossing it takes the original's time.
  LD_TOP=2; LD_BOT=$(( AR_H - 2 ))
  LD_LX=$(( AR_W / 72.0 )); LD_LY=$(( (LD_BOT - LD_TOP) / 14.0 ))
  local -F lr=$(( (LD_LX + LD_LY) / 2.0 ))
  LD_MAXLIVE=$(( int(LD_MAXLIVE * lr + 0.5) ))
  LD_GAP0=$(( LD_GAP0 / sqrt(lr) )); LD_GAPMIN=$(( LD_GAPMIN / sqrt(lr) ))
  LD_BLX=$(( 6.0 * LD_LX )); LD_BLY=$(( 4.0 * LD_LY ))
  LD_ROW_WARN=''; LD_ROW_FIRE=''; repeat $(( AR_W - 2 )) { LD_ROW_WARN+='┈'; LD_ROW_FIRE+='▀'; }
  LD_X=$(( AR_W * 0.5 )); LD_Y=$(( (LD_TOP + LD_BOT) * 0.5 ))
  st_set 0 $(( 300.0 * LD_LX )) 12.0 $(( 58.0 * LD_LX )); st_set 1 $(( 210.0 * LD_LY )) 12.0 $(( 30.0 * LD_LY ))
  return 0 }
ld_one() {   # ld_one VERT POS · POS < 0 is dealt on arrival
  local -i v=$1 p
  if (( $2 < 0 )); then if (( v )); then rnd_int 1 $(( AR_W - 2 )); else rnd_int $LD_TOP $LD_BOT; fi; p=$REPLY
  else p=$(( int($2) )); fi
  # a beam that lights up while you are still blinking from the last hit is
  # not a dodge you earned, so it never pays out
  LD_BV+=($v); LD_BP+=($p); LD_BT+=(0.0); LD_BH+=($(( LD_GRACE > 0.0 ? 1 : 0 )))
  LD_NB=${#LD_BV[@]}
  return 0 }
ld_phrase() {   # write the next few seconds of beams, as one readable figure
  local kind; local -i n i vert lo hi way x0 y0; local -F step k now
  local -a ow ov op; ow=(); ov=(); op=()
  rnd_pick ${#LD_PHR[@]}; kind=${LD_PHR[$REPLY]}
  rnd_uni 0.30 0.55; step=$(( LD_GAP0 * RF )); (( step < 0.16 )) && step=0.16
  case $kind in
    sweep)
      rnd_pick 3; n=$(( 4 + REPLY ))
      rnd_f; vert=$(( RF < 0.6 ))
      if (( vert )); then lo=2; hi=$(( AR_W - 3 )); else lo=$LD_TOP; hi=$LD_BOT; fi
      rnd_pick 2; way=$(( REPLY ? -1 : 1 ))
      for (( i = 0; i < n; i++ )); do
        k=$(( i / (n - 1.0) )); (( way < 0 )) && k=$(( 1.0 - k ))
        ow+=($(( i * step ))); ov+=($vert); op+=($(( lo + (hi - lo) * k )))
      done ;;
    comb)
      rnd_pick 2; n=$(( 3 + REPLY ))
      rnd_f; vert=$(( RF < 0.6 ))
      if (( vert )); then lo=4; hi=$(( AR_W - 5 )); else lo=$LD_TOP; hi=$LD_BOT; fi
      for (( i = 0; i < n; i++ )); do ow+=(0.0); ov+=($vert); op+=($(( lo + (hi - lo) * i / (n - 1.0) ))); done ;;
    pincer)
      rnd_pick 2; n=$(( 3 + REPLY ))
      for (( i = 0; i < n; i++ )); do
        k=$(( i / (n - 1.0) * 0.44 ))
        ow+=($(( i * step ))); ov+=(1); op+=($(( 2 + (AR_W - 5) * k )))
        ow+=($(( i * step ))); ov+=(1); op+=($(( AR_W - 3 - (AR_W - 5) * k )))
      done ;;
    cross)
      rnd_int 6 $(( AR_W - 7 )); ow+=(0.0); ov+=(1); op+=($REPLY)
      rnd_int $LD_TOP $LD_BOT; ow+=(0.0); ov+=(0); op+=($REPLY) ;;
    box)
      rnd_int 4 $(( AR_W - 24 )); x0=$REPLY; rnd_int $LD_TOP $(( LD_BOT - 3 )); y0=$REPLY
      ow+=(0.0); ov+=(1); op+=($x0)
      rnd_int 12 18; ow+=(0.0); ov+=(1); op+=($(( x0 + REPLY )))
      ow+=($step); ov+=(0); op+=($y0)
      rnd_int 2 3; ow+=($step); ov+=(0); op+=($(( y0 + REPLY ))) ;;
    *)   # rain
      rnd_pick 3; n=$(( 2 + REPLY ))
      for (( i = 0; i < n; i++ )); do rnd_f; ow+=($(( i * step * 0.7 ))); ov+=($(( RF < 0.5 ))); op+=(-1); done ;;
  esac
  now=$AR_RT
  LD_PW=(); LD_PV=(); LD_PP=()
  for (( i = 0; i < ${#ow[@]}; i++ )); do LD_PW+=($(( now + ow[i] ))); LD_PV+=(${ov[$i]}); LD_PP+=(${op[$i]}); done
  LD_NP=${#LD_PW[@]}
  return 0 }
ld_blink() {   # six cells the way you were already going, right now · it costs the cooldown and nothing else
  if (( LD_BLINKT > 0.0 )); then ar_snd error; return 0; fi
  LD_X=$(( LD_X + LD_FX * LD_BLX )); (( LD_X < 1.0 )) && LD_X=1.0; (( LD_X > AR_W - 2 )) && LD_X=$(( AR_W - 2.0 ))
  LD_Y=$(( LD_Y + LD_FY * LD_BLY )); (( LD_Y < LD_TOP )) && LD_Y=$(( LD_TOP + 0.0 )); (( LD_Y > LD_BOT )) && LD_Y=$(( LD_BOT + 0.0 ))
  st_stop 0; st_stop 1                   # it lands you STILL
  LD_BLINKT=$LD_BLINKCOOL; LD_BLINKS=$(( LD_BLINKS + 1 )); ar_snd select
  return 0 }
ld_update() {   # ld_update DT
  local -F dt=$1 gap; local k; local -i i px py struck room dead
  for k in "${AR_KEYS[@]}"; do
    case "$k" in
      LEFT|A)  st_push 0 -1; LD_FX=-1; LD_FY=0 ;;
      RIGHT|D) st_push 0 1;  LD_FX=1;  LD_FY=0 ;;
      UP|W)    st_push 1 -1; LD_FX=0;  LD_FY=-1 ;;
      DOWN|S)  st_push 1 1;  LD_FX=0;  LD_FY=1 ;;
      SPACE)   ld_blink ;;
    esac
  done
  st_glide 0 $dt; LD_X=$(( LD_X + RF )); (( LD_X < 1.0 )) && LD_X=1.0; (( LD_X > AR_W - 2 )) && LD_X=$(( AR_W - 2.0 ))
  st_glide 1 $dt; LD_Y=$(( LD_Y + RF )); (( LD_Y < LD_TOP )) && LD_Y=$(( LD_TOP + 0.0 )); (( LD_Y > LD_BOT )) && LD_Y=$(( LD_BOT + 0.0 ))
  (( LD_GRACE > 0.0 )) && { LD_GRACE=$(( LD_GRACE - dt )); (( LD_GRACE < 0.0 )) && LD_GRACE=0.0; }
  (( LD_BLINKT > 0.0 )) && { LD_BLINKT=$(( LD_BLINKT - dt )); (( LD_BLINKT < 0.0 )) && LD_BLINKT=0.0; }
  ar_add $(( int(dt * 24 * AR_LEVEL) ))
  AR_LEVEL=$(( 1 + int(AR_RT / 12) )); (( AR_LEVEL > 20 )) && AR_LEVEL=20
  gap=$(( LD_GAP0 - AR_RT * 0.02 )); (( gap < LD_GAPMIN )) && gap=$LD_GAPMIN
  LD_SPAWNT=$(( LD_SPAWNT - dt ))
  if (( LD_SPAWNT <= 0.0 && LD_NP == 0 )); then LD_SPAWNT=$gap; ld_phrase; fi
  # anything the phrase has come due for, as long as there is room
  if (( LD_NP )); then
    local -a pw pv pp; pw=(); pv=(); pp=(); room=1
    for (( i = 0; i < LD_NP; i++ )); do
      if (( room && LD_PW[i] <= AR_RT )); then
        if (( LD_NB >= LD_MAXLIVE + 2 )); then room=0
        else ld_one ${LD_PV[$i]} ${LD_PP[$i]}; continue; fi
      fi
      pw+=(${LD_PW[$i]}); pv+=(${LD_PV[$i]}); pp+=(${LD_PP[$i]})
    done
    LD_PW=("${pw[@]}"); LD_PV=("${pv[@]}"); LD_PP=("${pp[@]}"); LD_NP=${#LD_PW[@]}
  fi
  px=$(( int(LD_X + 0.5) )); py=$(( int(LD_Y + 0.5) ))
  # energy cells · a reason to move toward the middle of the grid
  LD_CELLT=$(( LD_CELLT - dt ))
  if (( LD_CELLT <= 0.0 && LD_NC < 2 )); then
    rnd_uni 5.0 9.0; LD_CELLT=$RF
    rnd_int 3 $(( AR_W - 4 )); LD_CX+=($REPLY); rnd_int $(( LD_TOP + 1 )) $(( LD_BOT - 1 )); LD_CY+=($REPLY); LD_CL+=(7.5)
    LD_NC=${#LD_CX[@]}
  fi
  if (( LD_NC )); then
    local -a cx cy cl; cx=(); cy=(); cl=()
    for (( i = 0; i < LD_NC; i++ )); do
      LD_CL[$i]=$(( LD_CL[i] - dt ))
      (( LD_CL[i] <= 0.0 )) && continue
      if (( abs(px - LD_CX[i]) <= 1 && py == LD_CY[i] )); then
        LD_PICKED=$(( LD_PICKED + 1 )); ar_add $(( 400 * AR_LEVEL ))
        (( LD_PICKED % 4 == 0 && AR_LIVES < 3 )) && AR_LIVES=$(( AR_LIVES + 1 ))
        ar_flash; ar_snd coin; continue
      fi
      cx+=(${LD_CX[$i]}); cy+=(${LD_CY[$i]}); cl+=(${LD_CL[$i]})
    done
    LD_CX=("${cx[@]}"); LD_CY=("${cy[@]}"); LD_CL=("${cl[@]}"); LD_NC=${#LD_CX[@]}
  fi
  # the beams · warn, fire, burn out · a hit while the grace is running is not a hit
  if (( LD_NB )); then
    local -a bv bp bt bh; bv=(); bp=(); bt=(); bh=(); dead=0
    for (( i = 0; i < LD_NB; i++ )); do
      if (( ! dead )); then
        LD_BT[$i]=$(( LD_BT[i] + dt ))
        if (( LD_BT[i] > LD_WARN + LD_BURN )); then
          (( LD_BH[i] )) || { LD_DODGED=$(( LD_DODGED + 1 )); ar_add $(( 25 * AR_LEVEL )); }
          continue
        fi
        if (( LD_BT[i] >= LD_WARN && ! LD_BH[i] )); then
          if (( LD_BV[i] )); then struck=$(( px == LD_BP[i] )); else struck=$(( py == LD_BP[i] )); fi
          if (( struck && LD_GRACE <= 0.0 )); then
            LD_BH[$i]=1; AR_LIVES=$(( AR_LIVES - 1 )); LD_GRACE=$LD_GRACET; ar_snd error
            (( AR_LIVES <= 0 )) && { AR_ALIVE=0; dead=1; }
          fi
        fi
      fi
      bv+=(${LD_BV[$i]}); bp+=(${LD_BP[$i]}); bt+=(${LD_BT[$i]}); bh+=(${LD_BH[$i]})
    done
    LD_BV=("${bv[@]}"); LD_BP=("${bp[@]}"); LD_BT=("${bt[@]}"); LD_BH=("${bh[@]}"); LD_NB=${#LD_BV[@]}
  fi
  return 0 }
ld_paint() {   # ld_paint T
  local -F t=$1 k fade; local -i i fg bg y lit blink ready; local s ch
  cmix $RED $PURPLE 0.5; cshade $CM 0.55; a_box 0 $AR_FT $AR_W $(( AR_H - AR_FT )) $CS $GLASS light 0
  for (( i = 0; i < LD_NB; i++ )); do
    k=$(( LD_BT[i] / (LD_WARN > 0.05 ? LD_WARN : 0.05) )); (( k > 1.0 )) && k=1.0
    if (( LD_BT[i] < LD_WARN )); then
      cmix $RED $AMBER 0.4; cshade $CM $(( 0.25 + 0.55 * k )); fg=$CS
      (( int(t * 14) % 2 && k > 0.55 )) && { cmix $fg $WHITE 0.4; fg=$CM; }
      cmix $GLASS $RED 0.06; bg=$CM
      if (( LD_BV[i] )); then ch='┊'; else s="$LD_ROW_WARN"; fi
    else
      cmix $RED $WHITE 0.45; fg=$CM; cmix $GLASS $RED 0.20; bg=$CM
      if (( LD_BV[i] )); then ch='█'; else s="$LD_ROW_FIRE"; fi
    fi
    if (( LD_BV[i] )); then for (( y = LD_TOP; y <= LD_BOT; y++ )); do a_put ${LD_BP[$i]} $y "$ch" $fg $bg; done
    else a_text 1 ${LD_BP[$i]} "$s" $fg $bg; fi
  done
  for (( i = 0; i < LD_NC; i++ )); do
    fade=$(( LD_CL[i] / 2.0 )); (( fade > 1.0 )) && fade=1.0
    if (( int(t * 6) % 2 )); then ch='✦'; else ch='✧'; fi
    cmix $LIME $WHITE $(( 0.25 + 0.4 * fade )); fg=$CM; cmix $GLASS $LIME $(( 0.18 * fade ))
    a_put ${LD_CX[$i]} ${LD_CY[$i]} "$ch" $fg $CM
  done
  blink=$(( LD_GRACE > 0.0 && int(t * 14) % 2 == 0 ))
  (( blink )) || { cmix $CYAN $WHITE 0.4; fg=$CM; cmix $GLASS $CYAN 0.20; a_put $(( int(LD_X + 0.5) )) $(( int(LD_Y + 0.5) )) '◆' $fg $CM; }
  # the blink's meter, where the decision is made
  ready=$(( LD_BLINKT <= 0.0 ))
  if (( ready )); then k=1.0; else k=$(( 1.0 - LD_BLINKT / (LD_BLINKCOOL > 0.1 ? LD_BLINKCOOL : 0.1) )); fi
  lit=$(( int(8 * k + 0.5) )); (( lit < 0 )) && lit=0; (( lit > 8 )) && lit=8
  s='BLINK '; for (( i = 0; i < lit; i++ )); do s+='▮'; done; for (( i = lit; i < 8; i++ )); do s+='▯'; done
  if (( ready )); then s+='  [SPACE]'; ar_wave $t 1.2; cmix $CYAN $WHITE $(( 0.2 + 0.3 * WV )); fg=$CM; else cshade $CYAN 0.55; fg=$CS; fi
  ar_plate 3 $AR_FT "$s" $fg $GLASS
  cshade $GREY 1.05; fg=$CS
  ar_plate 3 $(( AR_H - 1 )) "DODGED $LD_DODGED" $fg $GLASS
  ar_f1 $AR_RT; ar_lpad "$REPLY" 5; s="TIME ${REPLY}s"
  ar_plate $(( AR_W - 4 - ${#s} )) $(( AR_H - 1 )) "$s" $fg $GLASS
  return 0 }
ld_hud() { cmix $LIME $WHITE 0.25; AR_HL=(DODGED); AR_HV=($LD_DODGED); AR_HC=($CM); cmix $AMBER $WHITE 0.25; AR_HL+=(CELLS); AR_HV+=($LD_PICKED); AR_HC+=($CM); return 0 }
ld_stats() { AR_SL=(SURVIVED DODGED CELLS BLINKS); AR_SV=("$(( int(AR_RT + 0.5) ))s" $LD_DODGED $LD_PICKED $LD_BLINKS); return 0 }
pv_laserdodge() {   # three rails sweeping, a diamond dodging along the floor
  local -i x=$1 y=$2 w=$3 h=$4 i r bx px c fg bg; local -F p
  for (( i = 0; i < 3; i++ )); do
    p=$(( AR_T * 0.5 + i / 3.0 )); p=$(( p - floor(p) )); bx=$(( int(p * (w - 1)) ))
    cmix $RED $MAGENTA $(( i / 2.0 )); c=$CM; cshade $c 0.85; fg=$CS; cmix $AR_PVBG $c 0.16; bg=$CM
    for (( r = 0; r < h; r++ )); do a_put $(( x + bx )) $(( y + r )) '║' $fg $bg; done
  done
  ar_tri $(( AR_T * 0.7 )); px=$(( int(RF * (w - 1)) ))
  cmix $AR_PVBG $CYAN 0.20; a_put $(( x + px )) $(( y + h - 1 )) '◆' $CYAN $CM
  cshade $CYAN 0.7; a_put $(( x + px )) $(( y + h - 2 )) '▲' $CS $AR_PVBG
  return 0 }
AR_READY[laserdodge]=1; AR_PREFIX[laserdodge]=ld

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# LASER DODGE · run from the lit rails, take a cell if one is close, keep the blink for the cross
ld_demo() {
  local -F px=$LD_X py=$LD_Y; local -i i ux=-1 uy=-1 bc=-1; local -F bd=9999.0 d
  for (( i = 0; i < LD_NB; i++ )); do
    (( LD_BH[i] )) && continue
    (( LD_BT[i] > LD_WARN * 0.45 )) || continue
    if (( LD_BV[i] )); then (( abs(LD_BP[i] - px) < 3 && ux < 0 )) && ux=${LD_BP[$i]}
    else (( abs(LD_BP[i] - py) < 2 && uy < 0 )) && uy=${LD_BP[$i]}; fi
  done
  if (( ux >= 0 && uy >= 0 && LD_BLINKT <= 0.0 )); then AR_DKEYS+=(SPACE); return 0; fi
  if (( ux >= 0 )); then if (( ux > px )); then AR_DKEYS+=(LEFT); else AR_DKEYS+=(RIGHT); fi; return 0; fi
  if (( uy >= 0 )); then if (( uy > py )); then AR_DKEYS+=(UP); else AR_DKEYS+=(DOWN); fi; return 0; fi
  for (( i = 0; i < LD_NC; i++ )); do d=$(( abs(LD_CX[i] - px) + abs(LD_CY[i] - py) * 2 )); (( d < bd )) && { bd=$d; bc=$i; }; done
  if (( bc >= 0 )); then
    if (( abs(LD_CX[bc] - px) > 1 )); then if (( LD_CX[bc] > px )); then AR_DKEYS+=(RIGHT); else AR_DKEYS+=(LEFT); fi
    elif (( abs(LD_CY[bc] - py) > 0.4 )); then if (( LD_CY[bc] > py )); then AR_DKEYS+=(DOWN); else AR_DKEYS+=(UP); fi; fi
  fi
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15k · N I G H T   D R I V E        (racing) · nitro, and the ones coming the other way
# ══════════════════════════════════════════════════════════════════════════
# THE ROAD, DEALT.  Four to six sine terms with dealt frequency, amplitude and
# phase, under a slow amplitude ENVELOPE that opens and closes, so a long
# straight is a straight and a mountain section a mountain section.  It is a
# pure function of distance — the painter asks for it at sixteen depths every
# frame and the traffic at its own — so it is held as ONE arithmetic
# expression of ND_D, built at the deal, which zsh evaluates by name in a
# single pass: four times cheaper than a function that loops the terms.
# BOUNDED BY CONSTRUCTION: the amplitudes are scaled until the sum of them is
# inside the swing and the sum of amplitude × frequency inside the bend, so
# the check after it is a belt to that pair of braces.
# NITRO makes the passing matter: a clean pass is a quarter of the bottle, a
# full bottle is two and a half seconds over the car's own top speed scoring
# double.  ONCOMING, from EXPERT, is on the far side and closing.
typeset -gi ND_TOP=2 ND_BOT=17 ND_ROWS=16
typeset -gF ND_WR=1.0                       # the road's width over arcade.py's 72
typeset -g  ND_INKAT=''                     # the board the per-row inks were mixed for
typeset -gF ND_VIEW=90.0 ND_SWING=22.0 ND_BEND=1.9
typeset -gF ND_D=0.0                        # the distance the road is being asked about
typeset -g  ND_EXPR=''                      # this board's road · an expression of ND_D
typeset -g  ND_FALL='(sin(ND_D * 0.017 + 0.0) * 13.0 + sin(ND_D * 0.0052 + 0.0) * 7.0)'   # the road the machine shipped with
typeset -gF ND_VCRUISE ND_VMAX ND_TRAFFIC ND_ROADW ND_CLOCK0 ND_GATEEVERY ND_ONCOMING
typeset -gF ND_CHARGE ND_NITROT ND_Z ND_SPEED ND_CLOCK ND_GATE ND_EDGE ND_GATEPAY ND_X ND_SPAWN ND_SHAKE ND_GRACE ND_BESTSPD
typeset -gi ND_NITROS ND_PASSED ND_GATES ND_NC ND_FELL ND_INKS=0
typeset -ga ND_CD ND_CL ND_CV ND_CC ND_CO ND_CP ND_CF ND_CB ND_CS   # cars · distance lateral pace colour oncoming passed · three inks
typeset -ga ND_TAR ND_EDM ND_EDC ND_AMB ND_CARC                        # per-row inks, and the traffic's paint
typeset -gi ND_SKY ND_BARON ND_BARLOW ND_BAROFF ND_CLKLOW ND_NON ND_NDIM ND_NOFF ND_SPDN ND_SPD ND_GATEC ND_GATEL ND_PF ND_PB
typeset -g  ND_SP='' ND_EQ='' ND_FULL='' ND_LIGHT=''
typeset -gi ND_CW=3 ND_MW=2 ND_FW=1 ND_PW=5 ND_CR=1 ND_ROOFX=1 ND_YOUX=1   # the sprites' widths, and a roof on a tall board
typeset -g  ND_SN='◣█◢' ND_SNO='◤█◥' ND_SM='▄▄' ND_SMO='▀▀' ND_SF='▪' ND_SFO='◦' ND_ROOF='▄' ND_YOU='◢███◣' ND_YOUR='▄'
nd_inks() {   # everything the road paints in that depends on the row and nothing else · once
  (( ND_INKS )) && [[ "$ND_INKAT" == "${AR_W}x$ND_ROWS" ]] && return 0
  local -i i tb em ec; local -F k
  _pack 10 6 24; tb=$PK
  cmix $MAGENTA $WHITE 0.25; em=$CM; cmix $CYAN $WHITE 0.15; ec=$CM
  ND_TAR=(); ND_EDM=(); ND_EDC=(); ND_AMB=()
  for (( i = 0; i < ND_ROWS; i++ )); do
    k=$(( (i + 1.0) / ND_ROWS ))
    cmix $tb $PURPLE $(( 0.10 + 0.10 * k )); ND_TAR+=($CM)
    cshade $em $(( 0.5 + 0.5 * k )); ND_EDM+=($CS)
    cshade $ec $(( 0.5 + 0.5 * k )); ND_EDC+=($CS)
    cshade $AMBER $(( 0.35 + 0.55 * k )); ND_AMB+=($CS)
  done
  ND_CARC=($CYAN $AMBER $LIME $MAGENTA)
  cmix $GLASS $PURPLE 0.16; ND_SKY=$CM
  cmix $LIME $WHITE 0.3; ND_BARON=$CM; cmix $RED $WHITE 0.3; ND_BARLOW=$CM; cshade $GREY 0.35; ND_BAROFF=$CS
  cmix $WHITE $RED 0.5; ND_CLKLOW=$CM
  cmix $MAGENTA $WHITE 0.45; ND_NON=$CM; cshade $LIME 0.6; ND_NDIM=$CS; cshade $LIME 0.25; ND_NOFF=$CS
  cmix $MAGENTA $WHITE 0.4; ND_SPDN=$CM; cmix $AMBER $WHITE 0.2; ND_SPD=$CM
  cmix $LIME $WHITE 0.2; ND_GATEC=$CM; cmix $LIME $WHITE 0.4; ND_GATEL=$CM
  cmix $CYAN $WHITE 0.3; ND_PF=$CM; cmix $GLASS $CYAN 0.16; ND_PB=$CM
  ND_SP=''; ND_EQ=''; for (( i = 0; i < AR_W; i++ )); do ND_SP+=' '; ND_EQ+='═'; done
  ND_FULL=''; ND_LIGHT=''; for (( i = 0; i < 14; i++ )); do ND_FULL+='█'; ND_LIGHT+='░'; done
  # THE CARS GROW WITH THE ROAD · arcade.py drew a car three cells wide on a
  # road fifty-two wide at its near end.  The same share of a wider road is a
  # wider car -- and the hit window, a share of the road, lands where the paint
  # says it does.  A board thirty-six rows deep gives every car a roof.
  local b=''
  ND_CW=$(( 2 * int(1.5 * ND_WR) + 1 )); (( ND_CW < 3 )) && ND_CW=3
  ND_MW=$(( int(2.0 * ND_WR + 0.5) )); (( ND_MW < 2 )) && ND_MW=2
  ND_FW=$(( int(0.9 * ND_WR + 0.5) )); (( ND_FW < 1 )) && ND_FW=1
  ND_PW=$(( 2 * int(2.5 * ND_WR) + 1 )); (( ND_PW < 5 )) && ND_PW=5
  ND_CR=1; (( ND_ROWS >= 36 )) && ND_CR=2
  b=''; for (( i = 2; i < ND_CW; i++ )); do b+='█'; done; ND_SN="◣${b}◢"; ND_SNO="◤${b}◥"
  ND_ROOF=${b//█/▄}; ND_ROOFX=1
  b=''; for (( i = 0; i < ND_MW; i++ )); do b+='▄'; done; ND_SM=$b; ND_SMO=${b//▄/▀}
  if (( ND_FW > 1 )); then b=''; for (( i = 0; i < ND_FW; i++ )); do b+='▄'; done; ND_SF=$b; ND_SFO=${b//▄/▀}
  else ND_SF='▪'; ND_SFO='◦'; fi
  b=''; for (( i = 2; i < ND_PW; i++ )); do b+='█'; done; ND_YOU="◢${b}◣"
  ND_YOUX=$(( ND_PW / 4 )); b='▗'; for (( i = 2 * ND_YOUX + 2; i < ND_PW; i++ )); do b+='▄'; done; ND_YOUR="${b}▖"
  ND_INKS=1; ND_INKAT="${AR_W}x$ND_ROWS"; return 0 }
nd_road() {   # → ND_EXPR · a curve field, four to six sines under a slow envelope, scaled into bounds
  local -i n i; local -F f a total=0.0 slope=0.0 ef ep fl
  local -a F A P cnt; cnt=(4 4 5 6); F=(); A=(); P=()
  rnd_pick 4; n=${cnt[$REPLY]}
  for (( i = 0; i < n; i++ )); do
    # THE FAST TERMS HAVE TO BE THE SMALL ONES · a high frequency at a big
    # amplitude is not a corner, it is a kink
    rnd_uni 0.004 0.018; f=$(( RF * (1.0 + i * 0.30) ))
    rnd_uni 3.0 15.0; a=$(( RF / (1.0 + i * 1.05) ))
    rnd_uni 0.0 $TAU
    F+=($f); A+=($a); P+=($RF); total=$(( total + a ))
  done
  rnd_uni 0.0012 0.0035; ef=$RF; rnd_uni 0.0 $TAU; ep=$RF; rnd_uni 0.25 0.55; fl=$RF
  (( total <= 0.0 )) && total=1.0
  if (( total > ND_SWING )); then for (( i = 0; i < n; i++ )); do A[$i]=$(( A[i] * ND_SWING / total )); done; fi
  for (( i = 0; i < n; i++ )); do slope=$(( slope + A[i] * F[i] )); done; slope=$(( slope * 5.0 ))
  (( slope <= 0.0 )) && slope=0.000000001
  if (( slope > ND_BEND )); then for (( i = 0; i < n; i++ )); do A[$i]=$(( A[i] * ND_BEND / slope )); done; fi
  local s="(($fl) + (1.0 - ($fl)) * (0.5 + 0.5 * sin(ND_D * ($ef) + ($ep)))) * ("
  for (( i = 0; i < n; i++ )); do (( i )) && s+=' + '; s+="sin(ND_D * (${F[$i]}) + (${P[$i]})) * (${A[$i]})"; done
  ND_EXPR="$s)"; return 0 }
nd_road_ok() {   # the belt to the braces · checked at the step the painter samples, and it has to wander
  local -i z; local -F v lo=1000000.0 hi=-1000000.0
  for (( z = 0; z < 9000; z += 11 )); do ND_D=$z; v=$(( ND_EXPR )); (( v > ND_SWING + 0.01 || v < -ND_SWING - 0.01 )) && return 1; done
  for (( z = 0; z < 4000; z += 23 )); do ND_D=$z; v=$(( ND_EXPR )); (( v < lo )) && lo=$v; (( v > hi )) && hi=$v; done
  (( hi - lo > 3.0 )); return $? }
nd_begin() {
  AR_G_LEGEND='◄► STEER  ▲ BOOST  ▼ EASE  [SPACE] NITRO  [P] PAUSE  [Q] OUT'
  AR_G_HOWTO='pass clean to fill the bottle  ·  [SPACE] spends it'
  AR_G_ACC=$PINK
  ar_pick 38.0 48.0 60.0 72.0; ND_VCRUISE=$REPLY
  ar_pick 58.0 72.0 88.0 104.0; ND_VMAX=$REPLY
  ar_pick 0.030 0.045 0.062 0.082; ND_TRAFFIC=$REPLY
  ar_pick 0.92 0.82 0.72 0.62; ND_ROADW=$REPLY
  ar_pick 34.0 28.0 24.0 20.0; ND_CLOCK0=$REPLY
  ar_pick 420.0 480.0 540.0 600.0; ND_GATEEVERY=$REPLY
  ar_pick 0.0 0.0 0.30 0.48; ND_ONCOMING=$REPLY
  # THE ROAD IS THE BOARD · arcade.py ran sixteen rows of perspective, 2..17, on
  # a 72-wide tube.  Every row the board has is a row of road -- the far end
  # finer, not further -- and the road, its curves and its cars are as wide as
  # the board is, so the picture keeps its shape at any size.
  ND_TOP=2; ND_BOT=$(( AR_H - 1 )); ND_ROWS=$(( ND_BOT - ND_TOP + 1 )); ND_WR=$(( AR_W / 72.0 ))
  nd_inks
  local -i try; ND_FELL=0
  for (( try = 0; try < 24; try++ )); do nd_road; nd_road_ok && break; done
  (( try >= 24 )) && { ND_EXPR=$ND_FALL; ND_FELL=1; }
  ND_CHARGE=0.0; ND_NITROT=0.0; ND_NITROS=0; ND_PASSED=0; ND_Z=0.0
  ND_SPEED=$ND_VCRUISE                     # you start already rolling
  ND_CLOCK=$ND_CLOCK0; ND_GATE=$ND_GATEEVERY; ND_GATES=0
  ND_EDGE=$(( 0.55 + 0.50 * ND_ROADW ))     # how far out the tarmac runs
  ND_GATEPAY=$(( ND_GATEEVERY / 34.0 ))     # seconds a checkpoint buys
  ND_X=0.0
  st_set 0 26.0 7.0 2.6                     # the wheel
  st_set 1 9.0 4.5 1.0                      # the pedal · a throttle POSITION that springs back to cruise
  ND_CD=(); ND_CL=(); ND_CV=(); ND_CC=(); ND_CO=(); ND_CP=(); ND_CF=(); ND_CB=(); ND_CS=(); ND_NC=0
  ND_SPAWN=0.0; ND_SHAKE=0.0; ND_GRACE=0.0; ND_BESTSPD=0.0
  return 0 }
nd_car() {   # nd_car ONCOMING · one more car at the far end of the tarmac
  local -i on=$1 c
  if (( on )); then
    ND_CD+=($(( ND_Z + ND_VIEW * 1.15 )))
    rnd_f; if (( RF < 0.5 )); then rnd_uni -0.85 -0.25; else rnd_uni 0.25 0.85; fi; ND_CL+=($RF)
    rnd_uni 0.30 0.52; ND_CV+=($(( -RF ))); c=$WHITE
    cmix $c $WHITE 0.35; ND_CF+=($CM); cmix $GLASS $c 0.20; ND_CB+=($CM)
  else
    ND_CD+=($(( ND_Z + ND_VIEW )))
    rnd_uni -0.8 0.8; ND_CL+=($RF)
    rnd_uni 0.25 0.55; ND_CV+=($RF)
    rnd_pick 4; c=${ND_CARC[$REPLY]}
    cmix $c $WHITE 0.2; ND_CF+=($CM); cmix $GLASS $c 0.14; ND_CB+=($CM)
  fi
  cshade $c 0.8; ND_CS+=($CS)
  ND_CC+=($c); ND_CO+=($on); ND_CP+=(0); ND_NC=${#ND_CD[@]}
  return 0 }
nd_update() {   # nd_update DT
  local -F dt=$1 throttle want ceiling m was rel; local k; local -i i on dead
  for k in "${AR_KEYS[@]}"; do
    case "$k" in
      LEFT|A)  st_push 0 -1 ;;
      RIGHT|D) st_push 0 1 ;;
      UP|W)    st_push 1 1 ;;
      DOWN|S)  st_push 1 -1 ;;
      SPACE)   if (( ND_CHARGE >= 1.0 && ND_NITROT <= 0.0 )); then
                 ND_CHARGE=0.0; ND_NITROT=2.5; ND_NITROS=$(( ND_NITROS + 1 )); ar_flash; ar_snd coin
               else ar_snd error; fi ;;
    esac
  done
  st_glide 0 $dt; ND_X=$(( ND_X + RF )); (( ND_X < -1.35 )) && ND_X=-1.35; (( ND_X > 1.35 )) && ND_X=1.35
  throttle=${ST_V[1]}; (( throttle > 1.0 )) && throttle=1.0; (( throttle < -1.0 )) && throttle=-1.0
  st_glide 1 $dt                             # springs back toward coasting
  if (( throttle >= 0.0 )); then want=$(( ND_VCRUISE + throttle * (ND_VMAX - ND_VCRUISE) ))
  else want=$(( ND_VCRUISE + throttle * (ND_VCRUISE * 0.55) )); fi
  ceiling=$ND_VMAX
  if (( ND_NITROT > 0.0 )); then
    ND_NITROT=$(( ND_NITROT - dt )); (( ND_NITROT < 0.0 )) && ND_NITROT=0.0
    ceiling=$(( ND_VMAX * 1.38 )); want=$ceiling
  fi
  m=$(( 3.2 * dt )); (( m > 1.0 )) && m=1.0
  ND_SPEED=$(( ND_SPEED + (want - ND_SPEED) * m ))
  (( ND_SPEED < 12.0 )) && ND_SPEED=12.0; (( ND_SPEED > ceiling )) && ND_SPEED=$ceiling
  (( ND_SPEED > ND_BESTSPD )) && ND_BESTSPD=$ND_SPEED
  ND_Z=$(( ND_Z + ND_SPEED * dt ))
  if (( ND_NITROT > 0.0 )); then ar_add $(( ND_SPEED * dt * 1.8 )); else ar_add $(( ND_SPEED * dt * 0.9 )); fi
  AR_LEVEL=$(( 1 + int(ND_Z / 500) )); (( AR_LEVEL > 20 )) && AR_LEVEL=20
  (( ND_SHAKE > 0.0 )) && { ND_SHAKE=$(( ND_SHAKE - dt * 2.6 )); (( ND_SHAKE < 0.0 )) && ND_SHAKE=0.0; }
  (( ND_GRACE > 0.0 )) && { ND_GRACE=$(( ND_GRACE - dt )); (( ND_GRACE < 0.0 )) && ND_GRACE=0.0; }
  ND_CLOCK=$(( ND_CLOCK - dt ))
  if (( ND_Z >= ND_GATE )); then
    ND_GATE=$(( ND_GATE + ND_GATEEVERY )); ND_GATES=$(( ND_GATES + 1 ))
    ND_CLOCK=$(( ND_CLOCK + ND_GATEPAY )); (( ND_CLOCK > ND_CLOCK0 * 1.5 )) && ND_CLOCK=$(( ND_CLOCK0 * 1.5 ))
    ar_add $(( 600 * AR_LEVEL )); ar_snd coin
  fi
  (( ND_CLOCK <= 0.0 )) && { AR_ALIVE=0; return 0; }
  # off the tarmac costs you speed · the tarmac narrows with the rung, so road_w is a rule and not only a drawing
  if (( abs(ND_X) > ND_EDGE )); then
    ND_SPEED=$(( ND_SPEED - 46.0 * dt )); (( ND_SPEED < 12.0 )) && ND_SPEED=12.0
    (( ND_SHAKE < 0.35 )) && ND_SHAKE=0.35
  fi
  ND_SPAWN=$(( ND_SPAWN + ND_TRAFFIC * ND_SPEED * dt * 2.4 ))
  while (( ND_SPAWN >= 1.0 && ND_NC < 26 )); do
    ND_SPAWN=$(( ND_SPAWN - 1.0 ))
    # ONCOMING closes at the sum of both speeds, so it is put on the far side
    # and given a slower closing rate than a head-on would really have
    on=0; if (( ND_ONCOMING > 0.0 )); then rnd_f; (( RF < ND_ONCOMING )) && on=1; fi
    nd_car $on
  done
  (( ND_SPAWN > 2.0 )) && ND_SPAWN=2.0
  (( ND_NC )) || return 0
  local -a cd cl cv cc co cp cf cb cs; cd=(); cl=(); cv=(); cc=(); co=(); cp=(); cf=(); cb=(); cs=(); dead=0
  for (( i = 0; i < ND_NC; i++ )); do
    if (( ! dead )); then
      was=$(( ND_CD[i] - ND_Z ))
      ND_CD[$i]=$(( ND_CD[i] + ND_SPEED * ND_CV[i] * dt ))
      rel=$(( ND_CD[i] - ND_Z ))
      if (( rel < -3.0 )); then
        if (( ND_CP[i] )); then
          ND_PASSED=$(( ND_PASSED + 1 ))
          if (( ND_CO[i] )); then ar_add $(( 60 * AR_LEVEL )); ND_CHARGE=$(( ND_CHARGE + 0.34 ))
          else ar_add $(( 30 * AR_LEVEL )); ND_CHARGE=$(( ND_CHARGE + 0.25 )); fi
          (( ND_CHARGE > 1.0 )) && ND_CHARGE=1.0
        fi
        continue
      fi
      # swept · at speed a car can close more than the whole window inside one frame
      if (( rel < 2.2 && was > -1.2 && ND_GRACE <= 0.0 )); then
        ND_CP[$i]=1
        if (( abs(ND_CL[i] - ND_X) < 0.30 )); then
          ND_SPEED=$(( ND_SPEED * 0.45 )); (( ND_SPEED < 12.0 )) && ND_SPEED=12.0
          ND_CLOCK=$(( ND_CLOCK - 3.0 )); (( ND_CLOCK < 0.0 )) && ND_CLOCK=0.0
          ND_SHAKE=1.0; ND_GRACE=1.1
          ND_CHARGE=0.0; ND_NITROT=0.0              # a clean run, or no bottle
          ar_snd error
          (( ND_CLOCK <= 0.0 )) && { AR_ALIVE=0; dead=1; }
          continue
        fi
      fi
    fi
    cd+=(${ND_CD[$i]}); cl+=(${ND_CL[$i]}); cv+=(${ND_CV[$i]}); cc+=(${ND_CC[$i]}); co+=(${ND_CO[$i]}); cp+=(${ND_CP[$i]})
    cf+=(${ND_CF[$i]}); cb+=(${ND_CB[$i]}); cs+=(${ND_CS[$i]})
  done
  ND_CD=("${cd[@]}"); ND_CL=("${cl[@]}"); ND_CV=("${cv[@]}"); ND_CC=("${cc[@]}"); ND_CO=("${co[@]}"); ND_CP=("${cp[@]}")
  ND_CF=("${cf[@]}"); ND_CB=("${cb[@]}"); ND_CS=("${cs[@]}"); ND_NC=${#ND_CD[@]}
  return 0 }
nd_paint() {   # nd_paint T
  local -F t=$1 jitter=0.0 k d half cx rel; local -i i row l r x0 x1 px fg n; local s key
  local -a order
  (( ND_SHAKE > 0.0 )) && jitter=$(( sin(AR_RT * 47.0) * ND_SHAKE * 1.6 ))
  a_text 0 $AR_FT "$ND_SP" -2 $ND_SKY
  for (( i = 0; i < ND_ROWS; i++ )); do
    k=$(( (i + 1.0) / ND_ROWS )); d=$(( ND_Z + (1.0 - k) * ND_VIEW )); row=$(( ND_TOP + i ))
    half=$(( (2.0 + k * 30.0) * ND_ROADW * ND_WR ))
    ND_D=$d; cx=$(( AR_W * 0.5 + ND_EXPR * 0.75 * ND_WR + jitter - ND_X * half * 0.55 ))
    l=$(( int(cx - half) )); r=$(( int(cx + half) ))
    x0=$(( l < 0 ? 0 : l )); x1=$(( r > AR_W ? AR_W : r ))
    (( r > l && x1 > x0 )) && a_text $x0 $row "${ND_SP[0,$(( x1 - x0 - 1 ))]}" -2 ${ND_TAR[$i]}
    if (( int(d * 0.12) % 2 == 0 )); then fg=${ND_EDM[$i]}
      (( k > 0.25 )) && a_put $(( int(cx) )) $row '▮' ${ND_AMB[$i]} -2
    else fg=${ND_EDC[$i]}; fi
    # once the road is wider than the screen the rails would fall off the side
    a_put $(( l < 0 ? 0 : (l > AR_W - 1 ? AR_W - 1 : l) )) $row '▛' $fg -2
    a_put $(( r < 0 ? 0 : (r > AR_W - 1 ? AR_W - 1 : r) )) $row '▜' $fg -2
    (( ND_GATE - d < 6.0 && ND_GATE - d > 0.0 && x1 > x0 )) && a_text $x0 $row "${ND_EQ[0,$(( x1 - x0 - 1 ))]}" $ND_GATEL -2
  done
  # the traffic, the far end first so the near cars stand in front
  order=()
  for (( i = 0; i < ND_NC; i++ )); do
    rel=$(( ND_CD[i] - ND_Z )); (( rel < 0.0 || rel > ND_VIEW )) && continue
    order+=("$(( int(rel * 1000) )):$i")
  done
  for key in ${(On)order[@]}; do
    i=${key#*:}
    rel=$(( ND_CD[i] - ND_Z )); k=$(( 1.0 - rel / ND_VIEW )); row=$(( ND_TOP + int(k * (ND_ROWS - 1)) ))
    half=$(( (2.0 + (k < 0.05 ? 0.05 : k) * 30.0) * ND_ROADW * ND_WR ))
    ND_D=${ND_CD[$i]}; cx=$(( AR_W * 0.5 + ND_EXPR * 0.75 * ND_WR + jitter - ND_X * half * 0.55 ))
    px=$(( int(cx + ND_CL[i] * half) ))
    if (( k > 0.55 )); then
      if (( ND_CO[i] )); then s=$ND_SNO; else s=$ND_SN; fi
      l=$(( px - (ND_CW - 1) / 2 ))
      (( ND_CR > 1 && row > ND_TOP )) && a_text $(( l + ND_ROOFX )) $(( row - 1 )) "$ND_ROOF" ${ND_CC[$i]} -2
      a_text $l $row "$s" ${ND_CF[$i]} ${ND_CB[$i]}
    elif (( k > 0.3 )); then if (( ND_CO[i] )); then s=$ND_SMO; else s=$ND_SM; fi; a_text $(( px - (ND_MW - 1) / 2 )) $row "$s" ${ND_CC[$i]} -2
    else if (( ND_CO[i] )); then s=$ND_SFO; else s=$ND_SF; fi; a_text $(( px - (ND_FW - 1) / 2 )) $row "$s" ${ND_CS[$i]} -2; fi
  done
  # you
  half=$(( 32.0 * ND_ROADW * ND_WR )); ND_D=$ND_Z; cx=$(( AR_W * 0.5 + ND_EXPR * 0.75 * ND_WR + jitter - ND_X * half * 0.55 ))
  px=$(( int(cx + ND_X * half) - (ND_PW - 1) / 2 )); (( px < 0 )) && px=0; (( px > AR_W - ND_PW )) && px=$(( AR_W - ND_PW ))
  if (( ! (ND_GRACE > 0.0 && int(t * 14) % 2 == 0) )); then
    (( ND_CR > 1 )) && a_text $(( px + ND_YOUX )) $(( ND_BOT - 1 )) "$ND_YOUR" $ND_PF -2
    a_text $px $ND_BOT "$ND_YOU" $ND_PF $ND_PB
  fi
  # the clock, the bottle, the needle
  k=$(( ND_CLOCK / (ND_CLOCK0 * 1.5 > 1.0 ? ND_CLOCK0 * 1.5 : 1.0) )); (( k < 0.0 )) && k=0.0; (( k > 1.0 )) && k=1.0
  n=$(( int(k * 14 + 0.5) ))
  if (( ND_CLOCK > 8.0 )); then fg=$ND_BARON; else fg=$ND_BARLOW; fi
  (( n > 0 )) && a_text 2 $AR_FT "${ND_FULL[0,$(( n - 1 ))]}" $fg -2
  (( n < 14 )) && a_text $(( 2 + n )) $AR_FT "${ND_LIGHT[0,$(( 13 - n ))]}" $ND_BAROFF -2
  ar_f1 $(( ND_CLOCK > 0.0 ? ND_CLOCK : 0.0 )); s="${(l:4:)REPLY}s"
  if (( ND_CLOCK > 8.0 )); then fg=$WHITE; else fg=$ND_CLKLOW; fi
  a_text 17 $AR_FT "$s" $fg $ND_SKY
  if (( ND_NITROT > 0.0 )); then fg=$ND_NON
  elif (( ND_CHARGE >= 1.0 )); then ar_wave $t 1.4; cmix $LIME $WHITE $(( 0.35 + 0.3 * WV )); fg=$CM
  else fg=$ND_NDIM; fi
  a_text 24 $AR_FT 'NITRO' $fg $ND_SKY
  if (( ND_NITROT > 0.0 )); then n=8; else n=$(( int(8 * ND_CHARGE + 0.5) )); fi
  s=''; for (( i = 0; i < n; i++ )); do s+='▮'; done; (( n )) && a_text 30 $AR_FT "$s" $fg $ND_SKY
  s=''; for (( i = n; i < 8; i++ )); do s+='▯'; done; (( n < 8 )) && a_text $(( 30 + n )) $AR_FT "$s" $ND_NOFF $ND_SKY
  if (( ND_NITROT > 0.0 )); then ar_f1 $ND_NITROT; a_text 39 $AR_FT "${REPLY}s" $fg $ND_SKY
  elif (( ND_CHARGE >= 1.0 )); then a_text 39 $AR_FT '[SPACE]' $fg $ND_SKY; fi
  s="$(( int(ND_SPEED * 3.1 + 0.5) ))"; s="${(l:3:)s} km/h"
  if (( ND_NITROT > 0.0 )); then fg=$ND_SPDN; else fg=$ND_SPD; fi
  a_text $(( AR_W - 22 )) $AR_FT "$s" $fg $ND_SKY
  a_text $(( AR_W - 11 )) $AR_FT "GATE $ND_GATES" $ND_GATEC $ND_SKY
  return 0 }
nd_hud() { ar_pad $(( int(ND_Z) )) 5; cmix $PINK $WHITE 0.3; AR_HL=(DIST); AR_HV=("$REPLY"); AR_HC=($CM); return 0 }
nd_stats() { AR_SL=(DISTANCE GATES TOP PASSED NITROS); AR_SV=("$(( int(ND_Z) ))m" $ND_GATES $(( int(ND_BESTSPD * 3.1) )) $ND_PASSED $ND_NITROS); return 0 }
pv_nightdrive() {   # a road running away from you, the lane marks rolling
  local -i x=$1 y=$2 w=$3 h=$4 r l rr c bg; local -F cx k half
  _pack 6 4 18; bg=$PK; a_fill $x $y $w $h ' ' -2 $bg
  cx=$(( w / 2.0 + sin(AR_T * 0.6) * 3.0 ))
  for (( r = 0; r < h; r++ )); do
    k=$(( (r + 1.0) / h )); half=$(( 1.5 + k * (w * 0.42) ))
    l=$(( int(cx - half) )); rr=$(( int(cx + half) ))
    (( l < 0 )) && l=0; (( l > w - 1 )) && l=$(( w - 1 )); (( rr < 0 )) && rr=0; (( rr > w - 1 )) && rr=$(( w - 1 ))
    cmix $PURPLE $MAGENTA $k; cshade $CM $(( 0.5 + 0.5 * k )); c=$CS
    a_put $(( x + l )) $(( y + r )) '╲' $c -2; a_put $(( x + rr )) $(( y + r )) '╱' $c -2
    if (( int(k * 6 + AR_T * 3) % 2 == 0 )); then
      l=$(( int(cx) )); (( l < 0 )) && l=0; (( l > w - 1 )) && l=$(( w - 1 ))
      cshade $AMBER $(( 0.4 + 0.6 * k )); a_put $(( x + l )) $(( y + r )) '▮' $CS -2
    fi
  done
  l=$(( int(cx) - 2 )); (( l < 0 )) && l=0; (( l > w - 5 )) && l=$(( w - 5 ))
  cmix $bg $CYAN 0.15; a_text $(( x + l )) $(( y + h - 1 )) '◣███◢' $CYAN $CM
  return 0 }
AR_READY[nightdrive]=1; AR_PREFIX[nightdrive]=nd

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# NIGHT DRIVE · wide open, aim at the gap, spend the bottle the moment it is full
nd_demo() {
  local -F lane=$ND_X want rel best=999.0 cx; local -i i near=-1
  local -a out; out=(UP)
  (( ND_CHARGE >= 1.0 && ND_NITROT <= 0.0 )) && out+=(SPACE)
  for (( i = 0; i < ND_NC; i++ )); do rel=$(( ND_CD[i] - ND_Z )); (( rel > 0.0 && rel < 26.0 && rel < best )) && { best=$rel; near=$i; }; done
  if (( near >= 0 )); then
    cx=${ND_CL[$near]}
    if (( abs(cx - lane) < 0.42 )); then
      if (( cx < 0.0 )); then want=$(( cx + 0.55 )); else want=$(( cx - 0.55 )); fi
      (( want > 0.85 )) && want=0.85; (( want < -0.85 )) && want=-0.85
      if (( want > lane )); then AR_DKEYS+=(RIGHT "${out[@]}"); else AR_DKEYS+=(LEFT "${out[@]}"); fi
      return 0
    fi
  fi
  if (( abs(lane) > 0.55 )); then if (( lane > 0.0 )); then out+=(LEFT); else out+=(RIGHT); fi; fi
  AR_DKEYS+=("${out[@]}"); return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15n · THE FLOOR PLAN          arcade.py's arena_blocks, for any open floor
# ══════════════════════════════════════════════════════════════════════════
# An empty rectangle is a boring place to be chased around, and the obvious
# fix — scatter some walls — is also the obvious way to cut the floor in half
# and strand somebody in the smaller piece.  So the blocks go down in
# mirrored pairs and the whole floor is flood-filled afterwards; a layout
# that fails is thrown away and dealt again, and after twenty-four the
# answer is an open floor.  AR_KX/AR_KY is every cell that must stay open
# AND reachable, and it is mirrored before it is used: a lane protected on
# one side only would punch a hole in one half of a symmetric floor.
typeset -gA AR_BLK
typeset -ga AR_KX AR_KY
ar_blocks() {   # ar_blocks W H WANT → AR_BLK "x,y" → 1
  local -i w=$1 h=$2 want=$3 try n i k bx by ln cx mx y x qh qt nx ny nfree lim
  local kind c; local -a shapes cells qx qy kx ky; shapes=(bar bar block ell tee cross dot dash)
  local -A put seen
  kx=("${AR_KX[@]}"); ky=("${AR_KY[@]}")
  n=${#AR_KX[@]}; for (( i = 0; i < n; i++ )); do kx+=($(( w - 1 - AR_KX[i] ))); ky+=(${AR_KY[$i]}); done
  AR_BLK=()
  for (( try = 0; try < 24; try++ )); do
    put=()
    rnd_int $(( want - 1 > 1 ? want - 1 : 1 )) $(( want + 1 )); n=$REPLY
    for (( i = 0; i < n; i++ )); do
      rnd_pick 8; kind=${shapes[$REPLY]}
      rnd_range 3 $(( w / 2 - 2 > 4 ? w / 2 - 2 : 4 )); bx=$REPLY
      rnd_range 2 $(( h - 2 > 3 ? h - 2 : 3 )); by=$REPLY
      rnd_pick 5; case $REPLY in 0) ln=2 ;; 1|2) ln=3 ;; 3) ln=4 ;; *) ln=5 ;; esac
      cells=()
      case $kind in
        bar)   for (( k = 0; k < ln; k++ )); do cells+=("$(( bx + k )),$by"); done ;;
        block) lim=$(( ln < 2 ? ln : 2 )); for (( k = 0; k < 2; k++ )); do for (( y = 0; y < lim; y++ )); do cells+=("$(( bx + k )),$(( by + y ))"); done; done ;;
        ell)   for (( k = 0; k < ln; k++ )); do cells+=("$bx,$(( by + k ))"); done
               for (( k = 0; k < ln; k++ )); do cells+=("$(( bx + k )),$(( by + ln - 1 ))"); done ;;
        tee)   for (( k = 0; k < ln; k++ )); do cells+=("$(( bx + k )),$by"); done
               for (( k = 0; k < ln; k++ )); do cells+=("$(( bx + ln / 2 )),$(( by + k ))"); done ;;
        cross) for (( k = 0; k < 3; k++ )); do cells+=("$(( bx + k )),$(( by + 1 ))"); done
               for (( k = 0; k < 3; k++ )); do cells+=("$(( bx + 1 )),$(( by + k ))"); done ;;
        dash)  for (( k = 0; k < ln; k++ )); do cells+=("$bx,$(( by + k ))"); done ;;
        *)     cells+=("$bx,$by") ;;
      esac
      for c in "${cells[@]}"; do
        cx=${c%%,*}; y=${c#*,}
        (( y >= 1 && y < h - 1 )) || continue
        (( cx >= 1 && cx < w - 1 )) && put[$cx,$y]=1
        mx=$(( w - 1 - cx )); (( mx >= 1 && mx < w - 1 )) && put[$mx,$y]=1
      done
    done
    for (( i = 0; i < ${#kx[@]}; i++ )); do unset "put[${kx[$i]},${ky[$i]}]"; done
    (( ${#put[@]} )) || continue
    nfree=$(( w * h - ${#put[@]} ))
    (( nfree < w * h * 0.62 )) && continue
    seen=(); qx=(${kx[0]}); qy=(${ky[0]}); seen[${kx[0]},${ky[0]}]=1; qh=0; qt=1
    while (( qh < qt )); do
      x=${qx[$qh]}; y=${qy[$qh]}; qh=$(( qh + 1 ))
      for k in 0 1 2 3; do
        case $k in 0) nx=$(( x + 1 )); ny=$y ;; 1) nx=$(( x - 1 )); ny=$y ;; 2) nx=$x; ny=$(( y + 1 )) ;; *) nx=$x; ny=$(( y - 1 )) ;; esac
        (( nx < 0 || nx >= w || ny < 0 || ny >= h )) && continue
        [[ -n "${put[$nx,$ny]:-}" || -n "${seen[$nx,$ny]:-}" ]] && continue
        seen[$nx,$ny]=1; qx[$qt]=$nx; qy[$qt]=$ny; qt=$(( qt + 1 ))
      done
    done
    (( ${#seen[@]} == nfree )) || continue
    k=1; for (( i = 0; i < ${#kx[@]}; i++ )); do [[ -n "${seen[${kx[$i]},${ky[$i]}]:-}" ]] || { k=0; break; }; done
    (( k )) || continue
    for c in ${(k)put[@]}; do AR_BLK[$c]=1; done
    return 0
  done
  return 0 }     # the fallback · an open floor, checked by hand

# ══════════════════════════════════════════════════════════════════════════
# SECTION 15l · L I G H T   C Y C L E        (arena) · the floor, dealt · a rider who is a person
# ══════════════════════════════════════════════════════════════════════════
# Pillars change the SHAPE of the problem: an open floor is a race, a
# cluttered one is a maze you are also drawing.  The setting is not the
# count — the rung asks for shapes, and the cells they fill are reported,
# never written back over the setting.  THE FIRST RIDER IS A PERSON WHEN
# SOMEBODY IS SITTING THERE: it keeps its slot among the riders, so every
# rule that applies to a rider applies to them; only who turns it changes.
typeset -gi LC_W=35 LC_H=15 LC_X=1 LC_Y=2 LC_MAXB=4 LC_LANE=10 LC_BLANE=7
typeset -gF LC_STEP0 LC_SMART LC_HUNT LC_ACC LC_AREA=1.0 LC_PACE=1.0
typeset -gi LC_NBOTS LC_NPIL LC_PILC LC_ROUND LC_KILLS LC_PX LC_PY LC_DX LC_DY LC_WX LC_WY LC_W2X LC_W2Y LC_TWO LC_NB LC_TX LC_TY
typeset -gA LC_G                              # the floor · "x,y" → P your trail · B a rider's · W a pillar
typeset -ga LC_BX LC_BY LC_BDX LC_BDY LC_BA LC_BC LC_BW
typeset -ga LC_DIRX LC_DIRY; LC_DIRX=(1 -1 0 0); LC_DIRY=(0 0 1 -1)
typeset -gi LC_INKS=0 LC_TPF LC_TPB LC_TBF LC_TBB LC_TWF LC_TWB LC_PF LC_PB
typeset -ga LC_HF LC_HB
lc_inks() {
  (( LC_INKS )) && return 0
  local -i c i
  _pack 10 60 90; cmix $CYAN $PK 0.45; LC_TPF=$CM; cmix $GLASS $LC_TPF 0.10; LC_TPB=$CM
  _pack 70 10 50; cmix $MAGENTA $PK 0.45; LC_TBF=$CM; cmix $GLASS $LC_TBF 0.10; LC_TBB=$CM
  cshade $GREY 0.5; LC_TWF=$CS; cmix $GLASS $LC_TWF 0.10; LC_TWB=$CM
  cmix $WHITE $CYAN 0.25; LC_PF=$CM; cmix $GLASS $CYAN 0.28; LC_PB=$CM
  LC_HF=(); LC_HB=()
  for c in $MAGENTA $AMBER $LIME; do cmix $c $WHITE 0.45; LC_HF+=($CM); cmix $GLASS $c 0.22; LC_HB+=($CM); done
  LC_INKS=1; return 0 }
lc_begin() {
  AR_G_LEGEND='▲▼◄► TURN      [P] PAUSE      [Q] CASH OUT'
  AR_G_HOWTO='your wall kills you too  ·  cut them off'
  AR_G_TWOUP=1; AR_G_ACC=$CYAN; AR_G_OVER='DEREZZED'
  LC_TWO=$(( AR_PLAYERS == 2 ))
  if (( LC_TWO )); then
    AR_G_LEGEND='▲▼◄► ONE    [W][A][S][D] TWO    [P] PAUSE    [Q] CASH OUT'
    AR_G_HOWTO='arrows against WASD  ·  your own wall kills you too'
  fi
  ar_pick 0.135 0.105 0.082 0.064; LC_STEP0=$REPLY
  ar_pick 1 2 3 3; LC_NBOTS=$REPLY
  ar_pick 0.30 0.55 0.78 0.94; LC_SMART=$REPLY
  ar_pick 0.10 0.25 0.45 0.65; LC_HUNT=$REPLY
  ar_pick 0 5 10 16; LC_NPIL=$REPLY
  # THE FLOOR IS THE BOARD · arcade.py's 35 × 15 was its 72 × 18 tube less the
  # rail, and the floor is still the board less the rail.  A floor that size
  # is a different fight, so it is fought by more riders among more pillars, a
  # little faster: riders grow with the floor's side, pillars with its area,
  # the pace with a gentle power of it, and the clear lanes with its width.
  LC_W=$(( (AR_W - 2) / 2 )); LC_H=$(( AR_H - 3 ))
  LC_X=$(( (AR_W - 2 * LC_W - 2) / 2 + 1 )); LC_Y=2
  LC_AREA=$(( LC_W * LC_H / 525.0 )); (( LC_AREA < 1.0 )) && LC_AREA=1.0
  LC_PACE=$(( LC_AREA ** 0.15 ))
  LC_NBOTS=$(( int(LC_NBOTS * sqrt(LC_AREA) + 0.5) )); (( LC_NBOTS > 8 )) && LC_NBOTS=8
  LC_MAXB=$(( int(4 * sqrt(LC_AREA) + 0.5) )); (( LC_MAXB > 10 )) && LC_MAXB=10; (( LC_MAXB < LC_NBOTS )) && LC_MAXB=$LC_NBOTS
  LC_LANE=$(( 10 * LC_W / 35 )); (( LC_LANE < 10 )) && LC_LANE=10; (( LC_LANE > 22 )) && LC_LANE=22
  LC_BLANE=$(( 7 * LC_W / 35 )); (( LC_BLANE < 7 )) && LC_BLANE=7; (( LC_BLANE > 16 )) && LC_BLANE=16
  LC_PILC=0; AR_LIVES=3; LC_ROUND=1; LC_KILLS=0
  lc_inks; lc_arena
  return 0 }
lc_arena() {   # where everybody starts is worked out first, and then the floor is laid around it
  local -i i j by n; local k
  local -a sx sy; sx=(); sy=()
  LC_G=(); LC_PX=4; LC_PY=$(( LC_H / 2 )); LC_DX=1; LC_DY=0; LC_WX=1; LC_WY=0; LC_ACC=0.0
  n=$(( LC_NBOTS > 1 ? LC_NBOTS : 1 ))
  for (( i = 0; i < LC_NBOTS; i++ )); do
    by=$(( 2 + i * (LC_H - 4) / n )); (( by < 1 )) && by=1; (( by > LC_H - 2 )) && by=$(( LC_H - 2 ))
    sx+=($(( LC_W - 5 ))); sy+=($by)
  done
  if (( LC_NPIL )); then
    AR_KX=(); AR_KY=()
    for (( i = 2; i < 2 + LC_LANE; i++ )); do AR_KX+=($i); AR_KY+=($(( LC_H / 2 ))); done
    for (( i = 0; i < LC_NBOTS; i++ )); do for (( j = 0; j < LC_BLANE; j++ )); do AR_KX+=($(( sx[i] - j ))); AR_KY+=(${sy[$i]}); done; done
    ar_blocks $LC_W $LC_H $(( LC_NPIL / 3 > 1 ? int(LC_NPIL / 3 * LC_AREA) : int(LC_AREA + 0.5) ))
    for k in ${(k)AR_BLK[@]}; do LC_G[$k]=W; done
    LC_PILC=${#AR_BLK[@]}
  fi
  LC_G[$LC_PX,$LC_PY]=P
  LC_BX=(); LC_BY=(); LC_BDX=(); LC_BDY=(); LC_BA=(); LC_BC=(); LC_BW=()
  for (( i = 0; i < LC_NBOTS; i++ )); do
    LC_BX+=(${sx[$i]}); LC_BY+=(${sy[$i]}); LC_BDX+=(-1); LC_BDY+=(0); LC_BA+=(1); LC_BC+=($(( i % 3 ))); LC_BW+=($(( LC_TWO && i == 0 )))
    LC_G[${sx[$i]},${sy[$i]}]=B               # a rider's start is rider trail, not wall
  done
  LC_NB=$LC_NBOTS; LC_W2X=-1; LC_W2Y=0
  return 0 }
lc_free() { (( $1 >= 0 && $1 < LC_W && $2 >= 0 && $2 < LC_H )) && [[ -z "${LC_G[$1,$2]:-}" ]] }
lc_turn() {   # lc_turn KEY → LC_TX LC_TY · 1 when the key is not a turn
  case "$1" in
    UP|W) LC_TX=0; LC_TY=-1 ;; DOWN|S) LC_TX=0; LC_TY=1 ;; LEFT|A) LC_TX=-1; LC_TY=0 ;; RIGHT|D) LC_TX=1; LC_TY=0 ;; *) return 1 ;;
  esac; return 0 }
lc_update() {   # lc_update DT
  local -F dt=$1 step; local k; local -i guard=0
  if (( LC_TWO )); then ar_split_keys; else AR_K1=("${AR_KEYS[@]}"); AR_K2=(); fi
  for k in "${AR_K1[@]}"; do
    lc_turn "$k" || continue
    (( LC_TX != -LC_DX || LC_TY != -LC_DY )) && { LC_WX=$LC_TX; LC_WY=$LC_TY; }
  done
  if (( LC_TWO && LC_NB )); then
    for k in "${AR_K2[@]}"; do
      lc_turn "$k" || continue
      (( LC_TX != -LC_BDX[0] || LC_TY != -LC_BDY[0] )) && { LC_W2X=$LC_TX; LC_W2Y=$LC_TY; }
    done
  fi
  step=$(( (LC_STEP0 - (LC_ROUND - 1) * 0.006) / LC_PACE )); (( step < 0.035 )) && step=0.035
  LC_ACC=$(( LC_ACC + dt )); (( LC_ACC > step * 3 )) && LC_ACC=$(( step * 3 ))
  while (( LC_ACC >= step && guard < 3 )); do
    LC_ACC=$(( LC_ACC - step )); guard=$(( guard + 1 ))
    ar_add $(( 2 * AR_LEVEL ))
    lc_tick
    (( AR_ALIVE )) || return 0
  done
  return 0 }
lc_tick() {
  local -i nx ny crashed i bx by headon cleared
  LC_DX=$LC_WX; LC_DY=$LC_WY
  nx=$(( LC_PX + LC_DX )); ny=$(( LC_PY + LC_DY ))
  if lc_free $nx $ny; then crashed=0; else crashed=1; fi
  for (( i = 0; i < LC_NB; i++ )); do
    (( LC_BA[i] )) || continue
    if (( LC_BW[i] )); then LC_BDX[$i]=$LC_W2X; LC_BDY[$i]=$LC_W2Y; else lc_bot_turn $i; fi
    bx=$(( LC_BX[i] + LC_BDX[i] )); by=$(( LC_BY[i] + LC_BDY[i] ))
    headon=$(( (bx == nx && by == ny) || (bx == LC_PX && by == LC_PY && nx == LC_BX[i] && ny == LC_BY[i]) ))
    if ! lc_free $bx $by || (( headon )); then
      LC_BA[$i]=0; LC_KILLS=$(( LC_KILLS + 1 )); ar_add $(( 500 * AR_LEVEL )); ar_snd coin
      (( headon )) && crashed=1              # nobody survives driving into a rider
      continue
    fi
    LC_BX[$i]=$bx; LC_BY[$i]=$by; LC_G[$bx,$by]=B
  done
  # a clear earned on the same tick as a crash still counts
  cleared=1; for (( i = 0; i < LC_NB; i++ )); do (( LC_BA[i] )) && { cleared=0; break; }; done
  if (( crashed )); then
    if (( cleared )); then
      LC_ROUND=$(( LC_ROUND + 1 )); AR_LEVEL=$(( AR_LEVEL >= 20 ? 20 : AR_LEVEL + 1 )); ar_add $(( 1200 * AR_LEVEL ))
    fi
    AR_LIVES=$(( AR_LIVES - 1 )); ar_snd error
    (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
    lc_arena; return 0
  fi
  LC_PX=$nx; LC_PY=$ny; LC_G[$nx,$ny]=P
  if (( cleared )); then
    LC_ROUND=$(( LC_ROUND + 1 )); AR_LEVEL=$(( AR_LEVEL >= 20 ? 20 : AR_LEVEL + 1 ))
    (( LC_ROUND % 2 == 0 && LC_NBOTS < LC_MAXB )) && LC_NBOTS=$(( LC_NBOTS + 1 ))
    ar_add $(( 1200 * AR_LEVEL )); ar_snd coin
    lc_arena
  fi
  return 0 }
lc_room() {   # lc_room I DX DY → REPLY how far it can see before a wall · keeps them out of corners
  local -i n=0 x=${LC_BX[$1]} y=${LC_BY[$1]} dx=$2 dy=$3
  while (( n < 12 )) && lc_free $(( x + dx )) $(( y + dy )); do x=$(( x + dx )); y=$(( y + dy )); n=$(( n + 1 )); done
  REPLY=$n; return 0 }
lc_bot_turn() {   # lc_bot_turn I · the machine chooses a turn
  local -i i=$1 n j dx dy bi
  local -a ox oy key; ox=(); oy=(); key=()
  for j in 0 1 2 3; do
    dx=${LC_DIRX[$j]}; dy=${LC_DIRY[$j]}
    (( dx == -LC_BDX[i] && dy == -LC_BDY[i] )) && continue
    lc_free $(( LC_BX[i] + dx )) $(( LC_BY[i] + dy )) || continue
    ox+=($dx); oy+=($dy)
  done
  n=${#ox[@]}; (( n )) || return 0
  rnd_f
  if (( RF > LC_SMART )); then rnd_pick $n; LC_BDX[$i]=${ox[$REPLY]}; LC_BDY[$i]=${oy[$REPLY]}; return 0; fi
  rnd_f
  if (( RF < LC_HUNT )); then
    for (( j = 0; j < n; j++ )); do lc_room $i ${ox[$j]} ${oy[$j]}; key+=($(( (abs(LC_BX[i] + ox[j] - LC_PX) + abs(LC_BY[i] + oy[j] - LC_PY)) * 10 - REPLY * 6 ))); done
  else
    for (( j = 0; j < n; j++ )); do lc_room $i ${ox[$j]} ${oy[$j]}; key+=($(( -REPLY ))); done
  fi
  bi=0; for (( j = 1; j < n; j++ )); do (( key[j] < key[bi] )) && bi=$j; done     # a stable sort's first
  for (( j = 0; j < n; j++ )); do
    if (( ox[j] == LC_BDX[i] && oy[j] == LC_BDY[i] )); then
      lc_room $i ${LC_BDX[$i]} ${LC_BDY[$i]}
      if (( REPLY >= 3 )); then rnd_f; (( RF < 0.62 )) && return 0; fi      # keep going straight when it is safe
      break
    fi
  done
  LC_BDX[$i]=${ox[$bi]}; LC_BDY[$i]=${oy[$bi]}
  return 0 }
lc_paint() {   # lc_paint T
  local -F t=$1; local -i base i x y f b left; local k s
  ar_wave $t 0.35; cmix $CYAN $WHITE $(( 0.15 + 0.15 * WV ))
  a_box $(( LC_X - 1 )) $(( LC_Y - 1 )) $(( LC_W * 2 + 2 )) $(( LC_H + 2 )) $CM $GLASS heavy 0
  # the trails, straight into the cells · hundreds of them by the end of a
  # round, and one text call each was most of the frame
  base=$(( (OY + R_SCR + AY + LC_Y) * TCOLS + OX + C_SCR + AX + LC_X ))
  for k in ${(k)LC_G[@]}; do
    x=${k%%,*}; y=${k#*,}; i=$(( base + y * TCOLS + x * 2 ))
    case ${LC_G[$k]} in P) f=$LC_TPF; b=$LC_TPB ;; B) f=$LC_TBF; b=$LC_TBB ;; *) f=$LC_TWF; b=$LC_TWB ;; esac
    GCH[$i]='█'; GF[$i]=$f; GB[$i]=$b; i=$(( i + 1 )); GCH[$i]='█'; GF[$i]=$f; GB[$i]=$b
  done
  for (( i = 0; i < LC_NB; i++ )); do
    (( LC_BA[i] )) || continue
    if (( LC_BW[i] )); then s='◈◈'; else s='◉◉'; fi
    a_text $(( LC_X + LC_BX[i] * 2 )) $(( LC_Y + LC_BY[i] )) "$s" ${LC_HF[${LC_BC[$i]}]} ${LC_HB[${LC_BC[$i]}]}
  done
  a_text $(( LC_X + LC_PX * 2 )) $(( LC_Y + LC_PY )) '◉◉' $LC_PF $LC_PB
  if (( LC_TWO )); then
    cmix $CYAN $WHITE 0.35; ar_plate 3 $(( AR_H - 1 )) '1P ▲▼◄►' $CM $GLASS; x=$REPLY
    if (( LC_NB && LC_BA[0] )); then cmix $MAGENTA $WHITE 0.35; ar_plate $(( x + 1 )) $(( AR_H - 1 )) '2P WASD RIDING' $CM $GLASS
    else ar_plate $(( x + 1 )) $(( AR_H - 1 )) '2P WASD DEREZZED' $AR_LO $GLASS; fi
  else
    left=0; for (( i = 0; i < LC_NB; i++ )); do (( LC_BA[i] )) && left=$(( left + 1 )); done
    cshade $GREY 1.05; ar_plate 3 $(( AR_H - 1 )) "RIDERS $left" $CS $GLASS
  fi
  s="ROUND $LC_ROUND"; cshade $GREY 1.05; ar_plate $(( AR_W - 4 - ${#s} )) $(( AR_H - 1 )) "$s" $CS $GLASS
  return 0 }
lc_hud() { cmix $MAGENTA $WHITE 0.3; AR_HL=(KILLS); AR_HV=($LC_KILLS); AR_HC=($CM)
  (( LC_NPIL )) && { cshade $GREY 1.1; AR_HL+=(PILLARS); AR_HV+=($LC_PILC); AR_HC+=($CS); }; return 0 }
lc_stats() { AR_SL=(ROUNDS DEREZZED PILLARS); AR_SV=($LC_ROUND $LC_KILLS $LC_PILC); return 0 }

# the preview · two light cycles walling each other in along a spiral
typeset -ga LC_SPX LC_SPY PVC_F PVC_B; typeset -g LC_SPK=''
lc_spiral() {   # lc_spiral W H → LC_SPX LC_SPY, the rectangle walked inward
  [[ "$LC_SPK" == "$1,$2" ]] && return 0
  local -i x0=0 y0=0 x1=$(( $1 - 1 )) y1=$(( $2 - 1 )) x y
  LC_SPX=(); LC_SPY=()
  while (( x0 <= x1 && y0 <= y1 )); do
    for (( x = x0; x <= x1; x++ )); do LC_SPX+=($x); LC_SPY+=($y0); done; y0=$(( y0 + 1 ))
    for (( y = y0; y <= y1; y++ )); do LC_SPX+=($x1); LC_SPY+=($y); done; x1=$(( x1 - 1 ))
    if (( y0 <= y1 )); then for (( x = x1; x >= x0; x-- )); do LC_SPX+=($x); LC_SPY+=($y1); done; y1=$(( y1 - 1 )); fi
    if (( x0 <= x1 )); then for (( y = y1; y >= y0; y-- )); do LC_SPX+=($x0); LC_SPY+=($y); done; x0=$(( x0 + 1 )); fi
  done
  LC_SPK="$1,$2"; return 0 }
pv_lightcycle() {
  local -i x=$1 y=$2 w=$3 h=$4 n grown side i j q px py base col dk hf; local -F ff; local ch
  lc_spiral $w $h; n=${#LC_SPX[@]}
  if (( ! ${#PVC_F[@]} )); then   # sixteen steps of fade a side, dealt once
    for col in $CYAN $MAGENTA; do cshade $col 0.28; dk=$CS
      for (( q = 0; q < 16; q++ )); do cmix $col $dk $(( 1.0 - q / 15.0 )); PVC_F+=($CM); cmix $AR_PVBG $col $(( 0.10 * q / 15.0 )); PVC_B+=($CM); done
    done
  fi
  ff=$(( AR_T * 0.42 )); ff=$(( ff - floor(ff) )); grown=$(( int(ff * n * 0.85) ))
  base=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX + x ))
  for side in 0 1; do
    for (( i = 0; i < grown; i++ )); do
      if (( side )); then j=$(( n - 1 - i )); else j=$i; fi
      q=$(( int((1.0 - i / (grown > 1 ? grown * 1.0 : 1.0)) * 15.0 + 0.5) ))
      if (( i > grown - 3 )); then ch='█'; else ch='▓'; fi
      px=$(( base + LC_SPY[j] * TCOLS + LC_SPX[j] ))
      GCH[$px]=$ch; GF[$px]=${PVC_F[$(( side * 16 + q ))]}; GB[$px]=${PVC_B[$(( side * 16 + q ))]}
    done
    if (( grown )); then
      if (( side )); then j=$(( n - grown )); col=$MAGENTA; else j=$(( grown - 1 )); col=$CYAN; fi
      cmix $col $WHITE 0.5; hf=$CM; cmix $AR_PVBG $col 0.25
      a_put $(( x + LC_SPX[j] )) $(( y + LC_SPY[j] )) '◉' $hf $CM
    fi
  done
  return 0 }
AR_READY[lightcycle]=1; AR_PREFIX[lightcycle]=lc

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# LIGHT CYCLE · keep going while there is room, turn into the roomiest way when there is not
lc_demo_room() { local -i n=0 x=$LC_PX y=$LC_PY; while (( n < 14 )) && lc_free $(( x + $1 )) $(( y + $2 )); do x=$(( x + $1 )); y=$(( y + $2 )); n=$(( n + 1 )); done; REPLY=$n; return 0 }
lc_demo() {
  local -i d best=-1 r bx=0 by=0 dx dy
  lc_demo_room $LC_DX $LC_DY; (( REPLY >= 3 )) && return 0
  for d in 0 1 2 3; do
    dx=${LC_DIRX[$d]}; dy=${LC_DIRY[$d]}
    (( dx == -LC_DX && dy == -LC_DY )) && continue
    lc_demo_room $dx $dy; r=$REPLY; (( r > 0 )) || continue
    (( r > best )) && { best=$r; bx=$dx; by=$dy; }
  done
  (( best < 0 )) && return 0
  if (( by < 0 )); then AR_DKEYS+=(UP); elif (( by > 0 )); then AR_DKEYS+=(DOWN); elif (( bx < 0 )); then AR_DKEYS+=(LEFT); else AR_DKEYS+=(RIGHT); fi
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15m · A S T R O   D R I F T        (space) · hyperspace, and the saucer
# ══════════════════════════════════════════════════════════════════════════
# HYPERSPACE ([H]) takes you somewhere else on the field at once, and it might
# put you inside a rock: when the field has closed around you there is no
# move left except a gamble.  Three jumps a life, so it cannot become a habit.
# THE SAUCER is what EXPERT and INSANE add: across the field every half
# minute, worth a thousand a wave, firing where you are on EXPERT and where
# you are GOING on INSANE.  A dealt field has a SHAPE — a belt, a cluster,
# a ring you are inside, a scatter of shards — and a CURRENT every rock in it
# shares, so the whole field moves as one thing and reading it is a skill.
# The field stops a row short of the status line, which has a row of its own.
typeset -gi AD_TOP=1 AD_BOT=16 AD_H=16
typeset -gi AD_STC1=0 AD_STC2=0
typeset -gF AD_LX=1.0 AD_LY=1.0 AD_L=1.0 AD_AREA=1.0   # the field over arcade.py's 72 × 16, each way, on average, and by area
typeset -ga AD_SHIP; AD_SHIP=('▲' '◥' '▶' '◢' '▼' '◣' '◀' '◤')
typeset -ga AD_RAD; AD_RAD=(0 1.05 1.7 2.6)          # a rock's reach, by size
typeset -ga AD_PAY; AD_PAY=(0 100 50 20)               # a rock's worth, by size
typeset -ga AD_FIELDS; AD_FIELDS=(scatter scatter belt cluster ring shards)
typeset -gF AD_TURN AD_THRUST AD_DRAG AD_ROCKV AD_SEVERY AD_SAIM AD_ST AD_X AD_Y AD_VX AD_VY AD_ANG AD_GRACE
typeset -gF AD_UX AD_UY AD_UD AD_UFIRE
typeset -gi AD_START AD_WAVE AD_SMASHED AD_JUMPS AD_SAUCERS AD_UON AD_HELD AD_HYPER
typeset -g  AD_FIELD=''
typeset -ga AD_RX AD_RY AD_RVX AD_RVY AD_RS AD_RSP      # rocks · where, how fast, how big, how fast it turns
typeset -ga AD_SX AD_SY AD_SVX AD_SVY AD_SL             # your shots
typeset -ga AD_FX AD_FY AD_FVX AD_FVY AD_FL             # the saucer's
typeset -ga AD_DX AD_DY AD_DT                           # debris
typeset -ga AD_STARX AD_STARY AD_STARC
typeset -gi AD_INKS=0 AD_RK3 AD_RK2 AD_RK1 AD_SHOTC AD_FOEC AD_SHIPF AD_SHIPB AD_GREYT AD_JUMPC
ad_inks() {
  (( AD_INKS )) && return 0
  cshade $GREY 0.34; AD_STC1=$CS; cshade $GREY 0.22; AD_STC2=$CS
  cshade $GREY 0.75; AD_RK3=$CS; cshade $GREY 0.95; AD_RK2=$CS; cmix $AD_RK2 $WHITE 0.2; AD_RK1=$CM
  cmix $AMBER $WHITE 0.4; AD_SHOTC=$CM; cmix $RED $WHITE 0.35; AD_FOEC=$CM
  cmix $CYAN $WHITE 0.35; AD_SHIPF=$CM; cmix $GLASS $CYAN 0.18; AD_SHIPB=$CM
  cshade $GREY 1.05; AD_GREYT=$CS; cmix $CYAN $WHITE 0.3; AD_JUMPC=$CM
  AD_INKS=1; return 0 }
ad_wy() { RF=$(( ($1 - AD_TOP) % AD_H )); (( RF < 0.0 )) && RF=$(( RF + AD_H )); RF=$(( RF + AD_TOP )); return 0 }   # fold a row back into the field
ad_wx() { RF=$(( $1 % AR_W )); (( RF < 0.0 )) && RF=$(( RF + AR_W )); return 0 }
ad_near() {   # ad_near AX AY BX BY RAD → 0 when near · the field wraps both ways
  local -F dx=$(( abs($1 - $3) )) dy=$(( abs($2 - $4) ))
  (( dx > AR_W - dx )) && dx=$(( AR_W - dx )); (( dy > AD_H - dy )) && dy=$(( AD_H - dy ))
  (( dx * dx * 0.36 + dy * dy < $5 * $5 )) }
ad_begin() {
  AR_G_LEGEND='◄► TURN  ▲ THRUST  [SPACE] FIRE  [H] HYPERSPACE  [Q] OUT'
  AR_G_HOWTO='momentum has no brakes  ·  [H] jumps, and might not be kind'
  AR_G_ACC=$BLUE
  ar_pick 4.4 3.8 3.2 2.8; AD_TURN=$REPLY
  ar_pick 26.0 30.0 34.0 40.0; AD_THRUST=$REPLY
  ar_pick 0.72 0.55 0.40 0.26; AD_DRAG=$REPLY
  ar_pick 3.4 4.6 6.0 7.6; AD_ROCKV=$REPLY
  ar_pick 3 4 5 6; AD_START=$REPLY
  ar_pick 0.0 0.0 34.0 22.0; AD_SEVERY=$REPLY
  ar_pick 0.0 0.0 0.55 1.0; AD_SAIM=$REPLY          # 1.0 leads you
  ad_inks
  # THE FIELD IS THE BOARD · arcade.py's rows 1..16 across 72, wrapping both
  # ways.  Everything that crosses it -- rocks, the ship's thrust, shots, the
  # saucer -- moves with the field's size so a crossing takes the original's
  # time; the shapes a wave is dealt in, and the clear space round the ship,
  # scale with it; the stars and the rock count grow with its area.
  AD_TOP=1; AD_BOT=$(( AR_H - 2 )); AD_H=$(( AR_H - 2 ))
  AD_LX=$(( AR_W / 72.0 )); AD_LY=$(( AD_H / 16.0 )); AD_L=$(( (AD_LX + AD_LY) / 2.0 )); AD_AREA=$(( AD_LX * AD_LY ))
  AD_ROCKV=$(( AD_ROCKV * AD_L )); AD_THRUST=$(( AD_THRUST * AD_L ))
  local -i i n; n=$(( int(26 * AD_AREA) )); (( n > 140 )) && n=140
  AD_STARX=(); AD_STARY=(); AD_STARC=()
  for (( i = 0; i < n; i++ )); do AD_STARX+=($(( (i * 37) % AR_W ))); AD_STARY+=($(( AD_TOP + (i * 11) % AD_H ))); AD_STARC+=($(( i % 3 == 0 ? AD_STC1 : AD_STC2 ))); done
  AR_LIVES=3; AD_WAVE=1; AR_LEVEL=1; AD_SMASHED=0; AD_JUMPS=0; AD_SAUCERS=0; AD_UON=0; AD_ST=$AD_SEVERY
  AD_FX=(); AD_FY=(); AD_FVX=(); AD_FVY=(); AD_FL=()
  AD_RX=(); AD_RY=(); AD_RVX=(); AD_RVY=(); AD_RS=(); AD_RSP=()
  AD_DX=(); AD_DY=(); AD_DT=()
  ad_respawn; ad_wave
  return 0 }
ad_respawn() {
  AD_X=$(( AR_W * 0.5 )); AD_Y=$(( (AD_TOP + AD_BOT) * 0.5 )); AD_VX=0.0; AD_VY=0.0
  AD_ANG=$(( -TAU / 4.0 )); AD_GRACE=1.6; AD_HELD=0
  AD_SX=(); AD_SY=(); AD_SVX=(); AD_SVY=(); AD_SL=()
  AD_FX=(); AD_FY=(); AD_FVX=(); AD_FVY=(); AD_FL=()
  AD_HYPER=3                                          # three jumps a life, and no more
  return 0 }
ad_debris() { AD_DX+=($1); AD_DY+=($2); AD_DT+=(0.0); return 0 }
ad_hyper() {   # somewhere else, immediately, and it might be a bad somewhere
  if (( AD_HYPER <= 0 )); then ar_snd error; return 0; fi
  AD_HYPER=$(( AD_HYPER - 1 )); AD_JUMPS=$(( AD_JUMPS + 1 ))
  rnd_uni 2.0 $(( AR_W - 2.0 )); AD_X=$RF; rnd_uni $(( AD_TOP + 0.5 )) $(( AD_BOT - 0.5 )); AD_Y=$RF
  AD_VX=0.0; AD_VY=0.0; ad_debris $AD_X $AD_Y; ar_snd select
  AD_GRACE=0.0     # no grace · the risk IS the mechanic
  return 0 }
ad_wave() {   # a field with a character · a shape and a current
  local kind; local -i n i try placed size; local -F cura cur cx cy x y a sp
  local -i band
  AD_RX=(); AD_RY=(); AD_RVX=(); AD_RVY=(); AD_RS=(); AD_RSP=()
  rnd_pick 6; kind=${AD_FIELDS[$REPLY]}
  n=$(( AD_START + AD_WAVE - 1 )); (( n > 9 )) && n=9
  n=$(( int(n * sqrt(AD_AREA) + 0.5) ))
  rnd_uni 0.0 $TAU; cura=$RF; rnd_uni 0.0 0.45; cur=$(( AD_ROCKV * RF ))
  rnd_uni 0.0 $AR_W; cx=$RF; rnd_uni $(( AD_TOP + 1.0 )) $(( AD_BOT - 1.0 )); cy=$RF
  rnd_f; band=$(( RF < 0.5 ))
  for (( i = 0; i < n; i++ )); do
    x=0.0; y=0.0; placed=0
    for (( try = 0; try < 60; try++ )); do
      case $kind in
        belt)    if (( band )); then rnd_uni 0.0 $AR_W; x=$RF; rnd_uni -1.4 1.4; y=$(( cy + RF ))
                 else rnd_uni -3.0 3.0; x=$(( cx + RF )); rnd_uni $AD_TOP $AD_BOT; y=$RF; fi ;;
        cluster) rnd_uni $(( -9.0 * AD_LX )) $(( 9.0 * AD_LX )); ad_wx $(( cx + RF )); x=$RF; rnd_uni $(( -3.0 * AD_LY )) $(( 3.0 * AD_LY )); ad_wy $(( cy + RF )); y=$RF ;;
        ring)    a=$(( TAU * i / (n > 1 ? n : 1.0) )); ad_wx $(( cx + cos(a) * 22.0 * AD_LX )); x=$RF; ad_wy $(( cy + sin(a) * 5.0 * AD_LY )); y=$RF ;;
        *)       rnd_uni 0.0 $AR_W; x=$RF; rnd_uni $AD_TOP $AD_BOT; y=$RF ;;
      esac
      (( abs(x - AD_X) > 14 * AD_LX || abs(y - AD_Y) > 6 * AD_LY )) && { placed=1; break; }
    done
    if (( ! placed )); then ad_wx $(( AD_X + AR_W * 0.5 )); x=$RF; ad_wy $(( AD_Y + AD_H * 0.5 )); y=$RF; fi   # the shape gave no clear spot
    rnd_uni 0.0 $TAU; a=$RF; rnd_uni 0.55 1.15; sp=$(( AD_ROCKV * RF ))
    size=3; if [[ $kind == shards ]]; then rnd_pick 3; (( REPLY == 2 )) || size=2; fi
    ad_wx $x; AD_RX+=($RF); ad_wy $y; AD_RY+=($RF)
    AD_RVX+=($(( cos(a) * sp + cos(cura) * cur ))); AD_RVY+=($(( sin(a) * sp * 0.45 + sin(cura) * cur * 0.45 )))
    AD_RS+=($size); rnd_uni 0.5 2.0; AD_RSP+=($RF)
  done
  AD_FIELD=$kind; return 0 }
ad_crowded() {   # is a rock within three of the ship's reach
  local -i i
  for (( i = 0; i < ${#AD_RX[@]}; i++ )); do ad_near $AD_X $AD_Y ${AD_RX[$i]} ${AD_RY[$i]} $(( AD_RAD[AD_RS[i]] + 3.0 )) && return 0; done
  return 1 }
ad_break() {   # ad_break I · a rock split in two, or gone
  local -i i=$1 s=${AD_RS[$1]} j; local -F x=${AD_RX[$1]} y=${AD_RY[$1]} a sp
  AD_RX[$i]=(); AD_RY[$i]=(); AD_RVX[$i]=(); AD_RVY[$i]=(); AD_RS[$i]=(); AD_RSP[$i]=()
  AD_SMASHED=$(( AD_SMASHED + 1 )); ar_add $(( AD_PAY[s] * AD_WAVE )); ad_debris $x $y; ar_snd select
  if (( s > 1 )); then
    for (( j = 0; j < 2; j++ )); do
      rnd_uni 0.0 $TAU; a=$RF; rnd_uni 0.9 1.6; sp=$(( AD_ROCKV * RF ))
      AD_RX+=($x); AD_RY+=($y); AD_RVX+=($(( cos(a) * sp ))); AD_RVY+=($(( sin(a) * sp * 0.45 ))); AD_RS+=($(( s - 1 ))); rnd_uni 0.5 2.0; AD_RSP+=($RF)
    done
  fi
  return 0 }
ad_strike() {   # ad_strike X Y → 0 if the shot at X Y just hit the saucer or a rock
  local -i i
  if (( AD_UON )) && ad_near $1 $2 $AD_UX $AD_UY 2.0; then
    AD_UON=0; AD_SAUCERS=$(( AD_SAUCERS + 1 )); ar_add $(( 1000 * AD_WAVE )); ad_debris $AD_UX $AD_UY; ar_flash; ar_snd coin
    return 0
  fi
  for (( i = 0; i < ${#AD_RX[@]}; i++ )); do
    ad_near $1 $2 ${AD_RX[$i]} ${AD_RY[$i]} ${AD_RAD[${AD_RS[$i]}]} && { ad_break $i; return 0; }
  done
  return 1 }
ad_update() {   # ad_update DT
  local -F dt=$1 damp speed sx sy hops; local k; local -i i h n
  for k in "${AR_KEYS[@]}"; do
    case "$k" in
      LEFT|A)  AD_ANG=$(( AD_ANG - AD_TURN * 0.14 )) ;;
      RIGHT|D) AD_ANG=$(( AD_ANG + AD_TURN * 0.14 )) ;;
      UP|W)    AD_VX=$(( AD_VX + cos(AD_ANG) * AD_THRUST * 0.06 )); AD_VY=$(( AD_VY + sin(AD_ANG) * AD_THRUST * 0.032 )) ;;
      H)       ad_hyper ;;
      SPACE|Z) if (( ${#AD_SX[@]} < 4 )); then
                 AD_SX+=($(( AD_X + cos(AD_ANG) * 1.5 ))); AD_SY+=($(( AD_Y + sin(AD_ANG) * 0.7 )))
                 AD_SVX+=($(( cos(AD_ANG) * 46.0 * AD_LX + AD_VX ))); AD_SVY+=($(( sin(AD_ANG) * 22.0 * AD_LY + AD_VY ))); AD_SL+=(0.85)
                 ar_snd move
               fi ;;
    esac
  done
  damp=$(( exp(-AD_DRAG * dt) )); AD_VX=$(( AD_VX * damp )); AD_VY=$(( AD_VY * damp ))
  speed=$(( sqrt(AD_VX * AD_VX + 4.0 * AD_VY * AD_VY) ))
  (( speed > 34.0 )) && { AD_VX=$(( AD_VX * 34.0 / speed )); AD_VY=$(( AD_VY * 34.0 / speed )); }
  ad_wx $(( AD_X + AD_VX * dt )); AD_X=$RF; ad_wy $(( AD_Y + AD_VY * dt )); AD_Y=$RF
  if (( AD_GRACE > 0.0 )); then
    AD_GRACE=$(( AD_GRACE - dt )); (( AD_GRACE < 0.0 )) && AD_GRACE=0.0
    # never drop the shield straight onto a rock
    (( AD_GRACE <= 0.0 && AD_HELD < 8 )) && ad_crowded && { AD_GRACE=0.45; AD_HELD=$(( AD_HELD + 1 )); }
  fi
  # the shots · swept in hops, because a shot inherits the ship's speed and can out-run a small rock's window
  i=0
  while (( i < ${#AD_SX[@]} )); do
    AD_SL[$i]=$(( AD_SL[i] - dt ))
    if (( AD_SL[i] <= 0.0 )); then AD_SX[$i]=(); AD_SY[$i]=(); AD_SVX[$i]=(); AD_SVY[$i]=(); AD_SL[$i]=(); continue; fi
    hops=$(( int(sqrt(AD_SVX[i] * AD_SVX[i] + AD_SVY[i] * AD_SVY[i]) * dt / 0.6) + 1 )); (( hops < 1 )) && hops=1
    n=$(( int(hops) )); sx=${AD_SX[$i]}; sy=${AD_SY[$i]}
    for (( h = 0; h < n; h++ )); do
      ad_wx $(( sx + AD_SVX[i] * dt / n )); sx=$RF; ad_wy $(( sy + AD_SVY[i] * dt / n )); sy=$RF
      if ad_strike $sx $sy; then n=-1; break; fi
    done
    if (( n < 0 )); then AD_SX[$i]=(); AD_SY[$i]=(); AD_SVX[$i]=(); AD_SVY[$i]=(); AD_SL[$i]=(); continue; fi
    AD_SX[$i]=$sx; AD_SY[$i]=$sy; i=$(( i + 1 ))
  done
  i=0
  while (( i < ${#AD_DX[@]} )); do
    AD_DT[$i]=$(( AD_DT[i] + dt ))
    if (( AD_DT[i] > 0.35 )); then AD_DX[$i]=(); AD_DY[$i]=(); AD_DT[$i]=(); else i=$(( i + 1 )); fi
  done
  for (( i = 0; i < ${#AD_RX[@]}; i++ )); do
    ad_wx $(( AD_RX[i] + AD_RVX[i] * dt )); AD_RX[$i]=$RF; ad_wy $(( AD_RY[i] + AD_RVY[i] * dt )); AD_RY[$i]=$RF
  done
  ad_saucer $dt && return 0
  if (( AD_GRACE <= 0.0 )); then
    for (( i = 0; i < ${#AD_RX[@]}; i++ )); do
      if ad_near $AD_X $AD_Y ${AD_RX[$i]} ${AD_RY[$i]} $(( AD_RAD[AD_RS[i]] + 0.6 )); then
        AR_LIVES=$(( AR_LIVES - 1 )); ar_snd error; ad_debris $AD_X $AD_Y
        (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
        ad_respawn; return 0
      fi
    done
  fi
  if (( ! ${#AD_RX[@]} )); then
    AD_WAVE=$(( AD_WAVE + 1 )); AR_LEVEL=$AD_WAVE; ar_add $(( 900 * AD_WAVE )); ar_snd coin
    ad_respawn; ad_wave
  fi
  return 0 }
ad_saucer() {   # ad_saucer DT · fly the saucer and its shots · 0 when the round ended here
  local -F dt=$1 tx ty a; local -i i
  if (( AD_SEVERY > 0.0 && ! AD_UON )); then
    AD_ST=$(( AD_ST - dt ))
    if (( AD_ST <= 0.0 )); then
      rnd_uni 0.8 1.3; AD_ST=$(( AD_SEVERY * RF ))
      rnd_pick 2; if (( REPLY )); then AD_UD=-1.0; AD_UX=$(( AR_W + 2.0 )); else AD_UD=1.0; AD_UX=-2.0; fi
      rnd_uni $(( AD_TOP + 1.0 )) $(( AD_BOT - 1.0 )); AD_UY=$RF; AD_UFIRE=1.4; AD_UON=1
    fi
  fi
  if (( AD_UON )); then
    AD_UX=$(( AD_UX + AD_UD * 13.0 * AD_LX * dt )); ad_wy $(( AD_UY + sin(AR_RT * 1.7) * 3.0 * dt )); AD_UY=$RF
    if (( AD_UX < -4.0 || AD_UX > AR_W + 4.0 )); then AD_UON=0
    else
      AD_UFIRE=$(( AD_UFIRE - dt ))
      if (( AD_UFIRE <= 0.0 )); then
        rnd_uni 1.1 2.0; AD_UFIRE=$RF
        tx=$(( AD_X + AD_VX * 0.6 * AD_SAIM )); ty=$(( AD_Y + AD_VY * 0.6 * AD_SAIM ))
        a=$(( atan((ty - AD_UY) * 2.0, tx - AD_UX) )); rnd_uni -1.0 1.0; a=$(( a + RF * (1.0 - AD_SAIM) ))
        AD_FX+=($AD_UX); AD_FY+=($AD_UY); AD_FVX+=($(( cos(a) * 30.0 * AD_LX ))); AD_FVY+=($(( sin(a) * 15.0 * AD_LY ))); AD_FL+=(2.2)
        ar_snd move
      fi
    fi
  fi
  i=0
  while (( i < ${#AD_FX[@]} )); do
    AD_FL[$i]=$(( AD_FL[i] - dt ))
    if (( AD_FL[i] <= 0.0 )); then AD_FX[$i]=(); AD_FY[$i]=(); AD_FVX[$i]=(); AD_FVY[$i]=(); AD_FL[$i]=(); continue; fi
    ad_wx $(( AD_FX[i] + AD_FVX[i] * dt )); AD_FX[$i]=$RF; ad_wy $(( AD_FY[i] + AD_FVY[i] * dt )); AD_FY[$i]=$RF
    if (( AD_GRACE <= 0.0 )) && ad_near $AD_X $AD_Y ${AD_FX[$i]} ${AD_FY[$i]} 1.0; then
      AD_FX[$i]=(); AD_FY[$i]=(); AD_FVX[$i]=(); AD_FVY[$i]=(); AD_FL[$i]=()
      AR_LIVES=$(( AR_LIVES - 1 )); ar_snd error; ad_debris $AD_X $AD_Y
      (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
      ad_respawn; return 0
    fi
    i=$(( i + 1 ))
  done
  return 1 }
ad_blit() {   # ad_blit X Y GLYPHS FG · a wide sprite that wraps round the seam instead of clipping
  local -i x=$1 i n=${#3}; local g="$3"
  for (( i = 0; i < n; i++ )); do a_put $(( ((x + i) % AR_W + AR_W) % AR_W )) $2 "${g[$i]}" $4 -2; done; return 0 }
ad_paint() {   # ad_paint T
  local -F t=$1 k; local -i i x y y2 spin rad a px py c; local g
  for (( i = 0; i < 26; i++ )); do a_put ${AD_STARX[$i]} ${AD_STARY[$i]} '·' ${AD_STARC[$i]} -2; done
  for (( i = 0; i < ${#AD_RX[@]}; i++ )); do
    x=$(( int(AD_RX[i]) )); y=$(( int(AD_RY[i]) )); spin=$(( int(t * AD_RSP[i]) % 2 ))
    case ${AD_RS[$i]} in
      3) ad_wy $(( y + 1 )); y2=$(( int(RF) ))
         if (( spin )); then ad_blit $(( x - 1 )) $y '▛▜' $AD_RK3; ad_blit $(( x - 1 )) $y2 '▙▟' $AD_RK3
         else ad_blit $(( x - 1 )) $y '▙▟' $AD_RK3; ad_blit $(( x - 1 )) $y2 '▛▜' $AD_RK3; fi ;;
      2) if (( spin )); then ad_blit $x $y '▚▞' $AD_RK2; else ad_blit $x $y '▞▚' $AD_RK2; fi ;;
      *) a_put $(( x % AR_W )) $y '▪' $AD_RK1 -2 ;;
    esac
  done
  for (( i = 0; i < ${#AD_SX[@]}; i++ )); do a_put $(( int(AD_SX[i]) )) $(( int(AD_SY[i]) )) '·' $AD_SHOTC -2; done
  for (( i = 0; i < ${#AD_FX[@]}; i++ )); do a_put $(( int(AD_FX[i]) % AR_W )) $(( int(AD_FY[i]) )) '•' $AD_FOEC -2; done
  if (( AD_UON )); then ar_wave $t 3.0; cmix $RED $WHITE $(( 0.3 + 0.3 * WV )); ad_blit $(( int(AD_UX) - 1 )) $(( int(AD_UY) )) '◄◙►' $CM; fi
  for (( i = 0; i < ${#AD_DX[@]}; i++ )); do
    k=$(( AD_DT[i] / 0.35 )); rad=$(( 1 + int(k * 3) )); cshade $AMBER $(( 1.0 - k )); c=$CS
    for (( a = 0; a < 360; a += 45 )); do
      px=$(( int(AD_DX[i] + cos(a * TAU / 360.0) * rad) )); py=$(( int(AD_DY[i] + sin(a * TAU / 360.0) * rad * 0.5) ))
      a_put $(( ((px % AR_W) + AR_W) % AR_W )) $py '·' $c -2
    done
  done
  if ! (( AD_GRACE > 0.0 && int(t * 12) % 2 == 0 )); then
    # slot 0 of the ship points up, a heading of 0 points right · the quarter turn between them is added in
    k=$(( (AD_ANG + TAU / 4.0 + TAU / 16.0) % TAU )); (( k < 0.0 )) && k=$(( k + TAU ))
    i=$(( int(k / (TAU / 8.0)) % 8 ))
    a_put $(( int(AD_X) )) $(( int(AD_Y) )) "${AD_SHIP[$i]}" $AD_SHIPF $AD_SHIPB
  fi
  a_text 2 $(( AR_H - 1 )) "WAVE $AD_WAVE" $AD_GREYT -2
  g='JUMP '; for (( i = 0; i < AD_HYPER; i++ )); do g+='◆'; done; for (( i = AD_HYPER; i < 3; i++ )); do g+='·'; done
  if (( AD_HYPER )); then c=$AD_JUMPC; else c=$AR_LO; fi
  a_text 14 $(( AR_H - 1 )) "$g" $c -2
  a_text $(( AR_W - 15 )) $(( AR_H - 1 )) "ROCKS ${#AD_RX[@]}" $AD_GREYT -2
  return 0 }
ad_hud() { cmix $BLUE $WHITE 0.35; AR_HL=(WAVE); AR_HV=($AD_WAVE); AR_HC=($CM)
  (( AD_UON )) && { cmix $RED $WHITE 0.35; AR_HL+=(SAUCER); AR_HV+=('◙'); AR_HC+=($CM); }; return 0 }
ad_stats() { AR_SL=(WAVE ROCKS SAUCERS JUMPS); AR_SV=($AD_WAVE $AD_SMASHED $AD_SAUCERS $AD_JUMPS); return 0 }
typeset -ga PVA_X PVA_Y PVA_S; typeset -gi PVA_H=-1
pv_astrodrift() {   # rocks drifting past a ship that will not stop turning
  local -i x=$1 y=$2 w=$3 h=$4 i px bg cx cy keep; local -F f b; local g='▚▞▜▙' s='▲▶▼◀'
  _pack 6 4 18; bg=$PK; a_fill $x $y $w $h ' ' -2 $bg
  if (( PVA_H != h )); then   # the same eight rocks every time · the preview's own seed, the round's untouched
    keep=$RS; rnd_seed 31; PVA_X=(); PVA_Y=(); PVA_S=()
    for (( i = 0; i < 8; i++ )); do rnd_f; PVA_X+=($RF); rnd_pick $h; PVA_Y+=($REPLY); rnd_f; PVA_S+=($(( 0.3 + RF * 0.7 ))); done
    RS=$keep; PVA_H=$h
  fi
  for (( i = 0; i < 8; i++ )); do
    f=$(( (PVA_X[i] * w - AR_T * PVA_S[i] * 2.6) % w )); (( f < 0.0 )) && f=$(( f + w )); px=$(( int(f) ))
    cshade $GREY $(( 0.7 + 0.3 * (i % 2) )); a_put $(( x + px )) $(( y + PVA_Y[i] )) "${g[$(( i % 4 ))]}" $CS -2
  done
  cx=$(( w / 2 )); cy=$(( h / 2 ))
  cmix $CYAN $WHITE 0.35; i=$CM; cmix $bg $CYAN 0.18; a_put $(( x + cx )) $(( y + cy )) "${s[$(( int(AR_T * 1.6) % 4 ))]}" $i $CM
  b=$(( AR_T * 1.9 )); b=$(( b - floor(b) ))
  if (( b < 0.7 )); then px=$(( cx + int(b * 7) )); (( px > w - 1 )) && px=$(( w - 1 )); a_put $(( x + px )) $(( y + cy )) '·' $AMBER -2; fi
  return 0 }
AR_READY[astrodrift]=1; AR_PREFIX[astrodrift]=ad

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# ASTRO DRIFT · point at the nearest rock, shoot it, and jump when it is already too late to do either
ad_demo() {
  local -F tx ty dx dy want off close bd=9999.0 d; local -i i have=0
  if (( AD_UON )); then tx=$AD_UX; ty=$AD_UY; have=1
  else
    for (( i = 0; i < ${#AD_RX[@]}; i++ )); do
      d=$(( abs(AD_RX[i] - AD_X) )); d=$(( d - floor(d / AR_W) * AR_W )); d=$(( d + abs(AD_RY[i] - AD_Y) * 2.0 ))
      (( d < bd )) && { bd=$d; tx=${AD_RX[$i]}; ty=${AD_RY[$i]}; have=1; }
    done
  fi
  (( have )) || return 0
  dx=$(( tx - AD_X )); (( dx > AR_W * 0.5 )) && dx=$(( dx - AR_W )); (( dx < -AR_W * 0.5 )) && dx=$(( dx + AR_W ))
  dy=$(( (ty - AD_Y) * 0.5 ))
  want=$(( atan(dy, dx) ))
  off=$(( want - AD_ANG + TAU / 2.0 )); off=$(( off - floor(off / TAU) * TAU - TAU / 2.0 ))
  close=$(( sqrt(dx * dx + 4.0 * dy * dy) ))
  (( close < 4.0 && abs(off) > 1.2 && AD_HYPER > 0 && AD_GRACE <= 0.0 )) && { AR_DKEYS+=(H); return 0; }
  if (( abs(off) > 0.30 )); then if (( off > 0.0 )); then AR_DKEYS+=(RIGHT); else AR_DKEYS+=(LEFT); fi; return 0; fi
  (( ${#AD_SX[@]} < 4 )) && AR_DKEYS+=(SPACE)
  (( close > 16.0 )) && AR_DKEYS+=(UP)
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15o · P L A S M A   B A L L        (pinball) · the nudge, and the save
# ══════════════════════════════════════════════════════════════════════════
# A whole table in 72 × 17: a shooter lane down the right, pop bumpers in the
# arch, a bank of drop targets, two slingshots, and a pair of flippers over
# the drain.  The ball is integrated in sub-steps no larger than half a cell,
# so it can never tunnel through a bumper or the floor; cells are twice as
# tall as wide, so every vertical distance in the collisions is doubled.
# THE TABLE, DEALT: bumper rows, a drop bank, standups in the alleys, lanes
# across the arch — mirrored where it matters and checked before it is
# handed over.  THE NUDGE ([Z] [X] ▼) is a real shove and fills the TILT bob;
# fill it and the flippers die.  THE SAVE is the rung: eight seconds of ball
# save on ROOKIE, five, two and a half, and none at all on INSANE.
typeset -gi PB_L=1 PB_R=70 PB_TOP=2 PB_FLOOR=15 PB_DRAIN=16 PB_APRON=17 PB_DIVX=67 PB_DIV_TOP=4 PB_LANE=69 PB_PLAY_R=66 PB_REST=14 PB_MID=33 PB_GUARD=4
typeset -ga PB_SLX PB_SLP; PB_SLX=(6 61); PB_SLP=(1.0 -1.0)       # the slingshots · column and push
typeset -g  PB_TAGS='ABCDE'
typeset -gF PB_GRAV PB_FPOW PB_SAVE0 PB_BX PB_BY PB_VX PB_VY PB_TILT PB_NCOOL PB_SAVET PB_SFLASH PB_FLL PB_FLR PB_SLCOOL PB_GATE PB_SHAKE PB_SLY0 PB_SLY1
typeset -gi PB_BONUS PB_G0 PB_G1 PB_FL0 PB_FL1 PB_FR0 PB_FR1 PB_MULT PB_BESTM PB_TILTED PB_NUDGES PB_SAVES PB_COMBO PB_SWEEPS PB_SPINS PB_LSETS PB_READY PB_INLANE PB_NT PB_NL PB_FELL
typeset -ga PB_BUX PB_BUY PB_DRX PB_DRY PB_STX PB_STY PB_LAX PB_LAT   # the dealt table
typeset -ga PB_TGT PB_LIT PB_SCOOL                                     # what is down, what is lit, the standups' cool-down
typeset -ga PB_PPX PB_PPY PB_PPT PB_PPC PB_PPA                         # score pops · where, what, colour, age
typeset -gi PB_INKS=0
typeset -ga PB_BUF PB_BUB                                              # a bumper's glow, in seventeen steps
typeset -gi PB_LANEON PB_LANEOFF PB_LANEONB PB_STHOT PB_STCOLD PB_DIVC PB_DIVC2 PB_LANEAR PB_PLUNGE PB_GATEC PB_DROPC PB_DROPB PB_DOWNC PB_APRONC PB_FLIPON PB_FLIPONB PB_FLIPOFF PB_POSTC PB_BALLB PB_TRAIL
typeset -gi PB_SLHOT PB_SLHOT2 PB_SLCOLD PB_SLCOLD2 PB_APR PB_LABC PB_BANKC PB_LANESC PB_BONC PB_RIGHTC PB_TOFF PB_SAVEC
typeset -g  PB_RAILS='' PB_UNDER='' PB_OVER='' PB_LOW='' PB_SHADE=''
# THE TABLE ON THE GLASS · the ball, the flippers and every rule still live on
# arcade.py's 72 × 18 table, in its units, so the game plays exactly as it did.
# Only the paint is stretched: the table fills the board, each part is drawn
# as wide and as deep as it reaches, and the ball crosses more cells, so it
# moves more smoothly the bigger the board is.
typeset -gF PB_SX=1.0 PB_SY=1.0
typeset -g  PB_INKAT=''
typeset -gi PB_LO PB_HI PB_YAP=17 PB_BR=0 PB_BA=1 PB_BPILL=0 PB_DW=3 PB_SR=1 PB_SLW=1 PB_LWIDE=0
typeset -gi PB_YT PB_YF PB_YD PB_YS0 PB_YS1 PB_XDV PB_YDV PB_XLN PB_YRS PB_XS0 PB_XS1 PB_XMD PB_XPR
typeset -gi PB_XA0 PB_XA1 PB_XB0 PB_XB1 PB_XL0 PB_XL1 PB_XG0 PB_XG1 PB_XR0 PB_XR1 PB_XP0 PB_XP1 PB_XPL0 PB_XPL1
typeset -ga PB_BUSX PB_BUSY PB_DRSX PB_DRSY PB_STSX PB_STSY PB_LASX     # the dealt table, on the glass
typeset -ga PB_BSPT PB_BSPO PB_BSPR                                    # the bumper, row by row · text, x and y from its centre
typeset -g  PB_BODY='' PB_DROPS='' PB_DOWNS='' PB_PLG='' PB_SLL='◤' PB_SLR='◥'
typeset -gi PB_TRY=1 PB_YPLG=12 PB_YMSG=5 PB_YSAVE=14
pb_mx() { REPLY=$(( int(1 + ($1 - 1) * PB_SX + 0.5) )); return 0 }   # a table column's centre, on the glass
pb_my() { REPLY=$(( int(2 + ($1 - 2) * PB_SY + 0.5) )); return 0 }   # a table row's
pb_span() {   # pb_span A B → PB_LO PB_HI · the glass columns table cells A..B cover · neighbouring spans tile
  PB_LO=$(( int(1 + ($1 - 1) * PB_SX - (PB_SX - 1.0) / 2.0 + 0.5) ))
  PB_HI=$(( int(1 + ($2 - 1) * PB_SX + (PB_SX - 1.0) / 2.0 + 0.5) ))
  (( PB_LO < 1 )) && PB_LO=1; (( PB_HI > AR_W - 2 )) && PB_HI=$(( AR_W - 2 )); return 0 }
pb_geom() {   # the stretch, and where the fixed furniture lands · once the flippers' gap is dealt
  PB_SX=$(( (AR_W - 3) / 69.0 )); PB_SY=$(( (AR_H - 4) / 14.0 ))
  (( PB_SX < 1.0 )) && PB_SX=1.0; (( PB_SY < 1.0 )) && PB_SY=1.0
  PB_YAP=$(( AR_H - 1 ))
  pb_my $PB_TOP; PB_YT=$REPLY; pb_my $PB_FLOOR; PB_YF=$REPLY; pb_my $PB_DRAIN; PB_YD=$REPLY
  pb_my $PB_DIV_TOP; PB_YDV=$REPLY; pb_my $PB_REST; PB_YRS=$REPLY
  pb_my 12; PB_YS0=$REPLY; PB_YS1=$(( int(2 + 11.5 * PB_SY) ))        # the slings, over what were rows 12 and 13
  pb_mx $PB_DIVX; PB_XDV=$REPLY; pb_mx $PB_LANE; PB_XLN=$REPLY; pb_mx $PB_PLAY_R; PB_XPR=$REPLY
  pb_mx ${PB_SLX[0]}; PB_XS0=$REPLY; pb_mx ${PB_SLX[1]}; PB_XS1=$REPLY; pb_mx $PB_MID; PB_XMD=$REPLY
  pb_span $PB_FL0 $PB_FL1; PB_XL0=$PB_LO; PB_XL1=$PB_HI
  pb_span $PB_G0 $PB_G1; PB_XG0=$PB_LO; PB_XG1=$PB_HI
  pb_span $PB_FR0 $PB_FR1; PB_XR0=$PB_LO; PB_XR1=$PB_HI
  PB_XP0=$(( PB_XL0 - 1 )); PB_XP1=$(( PB_XR1 + 1 ))                  # the posts, hard against the flippers
  pb_span $PB_L $PB_L; PB_XA0=$PB_LO; PB_XA1=$(( PB_XP0 - 1 ))        # the apron floor either side of them
  pb_span $PB_PLAY_R $PB_PLAY_R; PB_XB0=$(( PB_XP1 + 1 )); PB_XB1=$PB_HI
  pb_span $(( PB_DIVX + 1 )) $PB_R; PB_XPL0=$PB_LO; PB_XPL1=$PB_HI    # the plunger's cap
  pb_my $(( PB_FLOOR - 3 )); PB_YPLG=$REPLY; pb_my $(( PB_TOP + 3 )); PB_YMSG=$REPLY; pb_my $(( PB_FLOOR - 1 )); PB_YSAVE=$REPLY
  return 0 }
pb_map() {   # the dealt table, on the glass
  local -i i
  PB_BUSX=(); PB_BUSY=(); for (( i = 0; i < ${#PB_BUX[@]}; i++ )); do pb_mx ${PB_BUX[$i]}; PB_BUSX+=($REPLY); pb_my ${PB_BUY[$i]}; PB_BUSY+=($REPLY); done
  PB_DRSX=(); PB_DRSY=(); for (( i = 0; i < ${#PB_DRX[@]}; i++ )); do pb_mx ${PB_DRX[$i]}; PB_DRSX+=($REPLY); pb_my ${PB_DRY[$i]}; PB_DRSY+=($REPLY); done
  PB_STSX=(); PB_STSY=(); for (( i = 0; i < ${#PB_STX[@]}; i++ )); do pb_mx ${PB_STX[$i]}; PB_STSX+=($REPLY); pb_my ${PB_STY[$i]}; PB_STSY+=($REPLY); done
  PB_LASX=(); for (( i = 0; i < ${#PB_LAX[@]}; i++ )); do pb_mx ${PB_LAX[$i]}; PB_LASX+=($REPLY); done
  return 0 }
pb_inks() {
  [[ "$PB_INKAT" == "${AR_W}x$AR_H" ]] && (( PB_INKS )) && return 0
  local -i q i r w; local s=''
  PB_BUF=(); PB_BUB=()
  for (( q = 0; q <= 16; q++ )); do cmix $AMBER $WHITE $(( 0.30 + 0.35 * q / 16.0 )); PB_BUF+=($CM); cmix $GLASS $AMBER $(( 0.10 + 0.16 * q / 16.0 )); PB_BUB+=($CM); done
  cmix $CYAN $WHITE 0.55; PB_LANEON=$CM; cshade $CYAN 0.42; PB_LANEOFF=$CS; cmix $GLASS $CYAN 0.20; PB_LANEONB=$CM
  cmix $PURPLE $WHITE 0.6; PB_STHOT=$CM; cshade $PURPLE 0.85; PB_STCOLD=$CS
  cshade $GREY 0.9; PB_DIVC=$CS; cshade $GREY 0.75; PB_DIVC2=$CS; cshade $AMBER 0.30; PB_LANEAR=$CS; cshade $AMBER 0.55; PB_PLUNGE=$CS
  cmix $LIME $WHITE 0.3; PB_GATEC=$CM; cmix $LIME $WHITE 0.30; PB_DROPC=$CM; cmix $GLASS $LIME 0.14; PB_DROPB=$CM; cshade $GREY 0.45; PB_DOWNC=$CS
  cmix $CYAN $GREY 0.5; cshade $CM 0.55; PB_APRONC=$CS
  cmix $LIME $WHITE 0.55; PB_FLIPON=$CM; cmix $GLASS $LIME 0.22; PB_FLIPONB=$CM; cshade $LIME 0.78; PB_FLIPOFF=$CS
  cshade $GREY 0.9; PB_POSTC=$CS; cmix $GLASS $WHITE 0.22; PB_BALLB=$CM; cshade $WHITE 0.35; PB_TRAIL=$CS
  cmix $CYAN $WHITE 0.5; PB_SLHOT=$CM; cshade $CM 0.7; PB_SLHOT2=$CS; cshade $CYAN 0.7; PB_SLCOLD=$CS; cshade $PB_SLCOLD 0.7; PB_SLCOLD2=$CS
  cmix $GLASS $AMBER 0.13; PB_APR=$CM; cshade $GREY 1.1; PB_LABC=$CS
  cmix $LIME $WHITE 0.35; PB_BANKC=$CM; cmix $CYAN $WHITE 0.35; PB_LANESC=$CM; cmix $MAGENTA $WHITE 0.35; PB_BONC=$CM
  PB_RIGHTC=$AMBER; cshade $AMBER 0.25; PB_TOFF=$CS; cmix $LIME $WHITE 0.3; PB_SAVEC=$CM
  PB_RAILS='┏'; for (( i = 0; i < AR_W - 2; i++ )); do PB_RAILS+='━'; done; PB_RAILS+='┓'
  PB_UNDER=''; PB_OVER=''; PB_LOW=''; PB_SHADE=''
  for (( i = 0; i < AR_W; i++ )); do PB_UNDER+='▁'; PB_OVER+='▀'; PB_LOW+='▄'; PB_SHADE+='░'; done
  # THE BUMPER, AS DEEP AS IT REACHES · arcade.py's (◉) on its own scale, a
  # glowing pill when the board is only wider, and a disc three or five rows
  # deep once it is tall enough to draw one
  PB_BR=0; (( PB_SY >= 2.0 )) && PB_BR=1; (( PB_SY >= 3.0 )) && PB_BR=2
  PB_BA=$(( int(1.5 * PB_SX + 0.5) )); (( PB_BA < PB_BR + 1 )) && PB_BA=$(( PB_BR + 1 ))
  PB_BPILL=$(( PB_BR == 0 && PB_SX >= 1.4 ))
  PB_BSPT=(); PB_BSPO=(); PB_BSPR=()
  for (( r = -PB_BR; r <= PB_BR; r++ )); do
    (( r == 0 )) && continue                                           # the middle row carries the (◉), drawn apart
    if (( abs(r) == PB_BR )); then w=$(( PB_BA - PB_BR )); else w=$(( PB_BA - abs(r) )); fi
    s=''; for (( i = 0; i < 2 * w + 1; i++ )); do if (( r == -PB_BR )); then s+='▄'; elif (( r == PB_BR )); then s+='▀'; else s+='█'; fi; done
    PB_BSPT+=("$s"); PB_BSPO+=($(( -w ))); PB_BSPR+=($r)
  done
  PB_BODY=''; for (( i = 0; i < 2 * PB_BA + 1; i++ )); do PB_BODY+='█'; done
  PB_DW=$(( 2 * int(1.25 * PB_SX) + 1 )); (( PB_DW < 3 )) && PB_DW=3
  PB_DROPS=''; PB_DOWNS=''; for (( i = 0; i < PB_DW; i++ )); do PB_DROPS+='▮'; PB_DOWNS+='·'; done
  PB_SR=$(( 2 * int(0.45 * PB_SY) + 1 ))
  PB_SLW=1; (( PB_SX >= 1.8 )) && PB_SLW=2
  PB_SLL=''; PB_SLR=''; for (( i = 0; i < PB_SLW; i++ )); do PB_SLL+='◤'; PB_SLR+='◥'; done
  PB_LWIDE=$(( PB_SX >= 1.8 ))
  PB_TRY=$(( int(0.5 * PB_SY + 0.5) )); (( PB_TRY < 1 )) && PB_TRY=1
  PB_PLG=''; for (( i = 0; i < AR_W; i++ )); do PB_PLG+='▂'; done
  PB_INKS=1; PB_INKAT="${AR_W}x$AR_H"; return 0 }
ar_round() {   # ar_round X → REPLY · Python's round(): a half goes to the even neighbour
  local -F x=$1; local -i r
  r=$(( int(floor(x + 0.5)) )); (( r - x == 0.5 && r % 2 )) && r=$(( r - 1 ))
  REPLY=$r; return 0 }
ar_sample() {   # ar_sample K V1 V2 … → AR_SMP · K distinct values, dealt, then sorted as numbers
  local -i k=$1 i j n; local tmp; local -a v; shift; v=("$@"); n=${#v[@]}
  for (( i = 0; i < k && i < n; i++ )); do rnd_int $i $(( n - 1 )); j=$REPLY; tmp=${v[$i]}; v[$i]=${v[$j]}; v[$j]=$tmp; done
  local -a pick; pick=("${v[@]:0:$k}"); AR_SMP=(${(on)pick[@]}); return 0 }
typeset -ga AR_SMP
pb_make() {   # one table · bumpers, a drop bank, standups, lanes and a sling band
  local -i lo=3 hi=64 i k n ry x y depth nl pad a b arc ny width; local -F pitch shift mid top
  local -a cnt
  PB_BUX=(); PB_BUY=(); PB_DRX=(); PB_DRY=(); PB_STX=(); PB_STY=(); PB_LAX=(); PB_LAT=()
  # bumpers · two or three rows, offset from each other so the ball rattles
  cnt=(2 2 3); rnd_pick 3; ar_sample ${cnt[$REPLY]} 3 4 5 6 7 8
  i=0
  for ry in "${AR_SMP[@]}"; do
    cnt=(3 4 4 5 5 6); rnd_pick 6; n=${cnt[$REPLY]}
    pitch=$(( (hi - lo) / (n * 1.0) )); if (( i % 2 )); then shift=$(( pitch * 0.5 )); else shift=0.0; fi
    for (( k = 0; k < n; k++ )); do
      ar_round $(( lo + shift + pitch * (k + 0.5) )); x=$REPLY
      (( x >= lo && x <= hi - PB_GUARD )) && { PB_BUX+=($x); PB_BUY+=($ry); }
    done
    i=$(( i + 1 ))
  done
  # one drop bank, level or arched
  cnt=(9 10 11); rnd_pick 3; ny=${cnt[$REPLY]}
  cnt=(4 5 5 6); rnd_pick 4; n=${cnt[$REPLY]}
  cnt=(7 8 9 10); rnd_pick 4; width=${cnt[$REPLY]}
  cnt=(0 0 1); rnd_pick 3; arc=${cnt[$REPLY]}
  mid=$(( (lo + hi - PB_GUARD) * 0.5 ))
  for (( k = 0; k < n; k++ )); do
    ar_round $(( mid + (k - (n - 1) * 0.5) * width )); x=$REPLY
    y=$(( ny - (arc && k > 0 && k < n - 1 ? 1 : 0) ))
    (( x >= lo && x <= hi - PB_GUARD )) && { PB_DRX+=($x); PB_DRY+=($y); }
  done
  # standups · mirrored into both alleys
  cnt=(3 4 5); rnd_pick 3; depth=${cnt[$REPLY]}
  cnt=(2 2 3); rnd_pick 3; ar_sample ${cnt[$REPLY]} 5 6 7 8 9
  for ry in "${AR_SMP[@]}"; do
    PB_STX+=($(( PB_L + depth ))); PB_STY+=($ry)
    PB_STX+=($(( PB_L + PB_PLAY_R - (PB_L + depth) ))); PB_STY+=($ry)
  done
  # rollover lanes across the top arch
  cnt=(3 3 4 5); rnd_pick 4; nl=${cnt[$REPLY]}
  cnt=(8 10 12); rnd_pick 3; pad=${cnt[$REPLY]}
  a=$(( lo + pad )); b=$(( hi - PB_GUARD - pad ))
  for (( k = 0; k < nl; k++ )); do
    ar_round $(( a + (b - a) * (k / (nl > 1 ? nl - 1.0 : 1.0)) )); PB_LAX+=($REPLY); PB_LAT+=("${PB_TAGS[$k]}")
  done
  # and where the slingshots sit
  cnt=(11.2 11.6 12.0); rnd_pick 3; top=${cnt[$REPLY]}; PB_SLY0=$top; PB_SLY1=$(( top + 2.0 ))
  return 0 }
pb_ok() {   # nothing in the shooter lane or the flippers, no two things on a cell, enough of each
  local -i i j n; local -A cells; local -a xs ys
  (( ${#PB_BUX[@]} >= 7 && ${#PB_DRX[@]} >= 4 && ${#PB_DRX[@]} <= 6 )) || return 1
  (( ${#PB_STX[@]} >= 2 && ${#PB_LAX[@]} >= 3 && ${#PB_LAX[@]} <= 5 )) || return 1
  xs=("${PB_BUX[@]}" "${PB_DRX[@]}" "${PB_STX[@]}"); ys=("${PB_BUY[@]}" "${PB_DRY[@]}" "${PB_STY[@]}")
  for (( i = 0; i < ${#xs[@]}; i++ )); do
    (( xs[i] >= PB_L + 1 && xs[i] <= PB_PLAY_R - 1 )) || return 1       # in the shooter lane, or in a wall
    (( ys[i] >= PB_TOP + 1 && ys[i] <= PB_FLOOR - 4 )) || return 1      # under the arch, or in the flippers
    [[ -n "${cells[${xs[$i]},${ys[$i]}]:-}" ]] && return 1              # two things on one cell
    cells[${xs[$i]},${ys[$i]}]=1
  done
  for (( i = 0; i < ${#PB_LAX[@]}; i++ )); do (( PB_LAX[i] >= PB_L + 4 && PB_LAX[i] <= PB_PLAY_R - PB_GUARD )) || return 1; done
  # a bumper directly over a drop target makes the bank unshootable
  for (( i = 0; i < ${#PB_BUX[@]}; i++ )); do for (( j = 0; j < ${#PB_DRX[@]}; j++ )); do
    (( abs(PB_BUX[i] - PB_DRX[j]) <= 1 && PB_DRY[j] - PB_BUY[i] <= 3 && PB_DRY[j] > PB_BUY[i] )) && return 1
  done; done
  # and the sling band must not swallow the drop bank
  for (( j = 0; j < ${#PB_DRY[@]}; j++ )); do (( PB_SLY0 - 0.5 <= PB_DRY[j] )) && return 1; done
  return 0 }
pb_deal() {
  local -i try; PB_FELL=0
  for (( try = 0; try < 24; try++ )); do pb_make; pb_ok && return 0; done
  PB_FELL=1   # the table the machine shipped with
  PB_BUX=(15 27 39 51 9 21 33 45 57); PB_BUY=(4 4 4 4 7 7 7 7 7)
  PB_DRX=(15 24 33 42 51); PB_DRY=(10 10 10 10 10)
  PB_STX=(4 63 4 63); PB_STY=(6 6 9 9)
  PB_LAX=(16 33 50); PB_LAT=(A B C); PB_SLY0=11.6; PB_SLY1=13.6
  return 0 }
pb_begin() {
  AR_G_LEGEND='◄► FLIPPERS  [SPACE] PLUNGER  [Z][X]▼ NUDGE  [P] PAUSE  [Q] OUT'
  AR_G_HOWTO='flip it off the drain  ·  [Z] [X] ▼ shove the table -- carefully'
  AR_G_ACC=$AMBER; AR_G_OVER='TILT'; AR_G_HEART='●'
  local -i gap i
  ar_pick 13.0 16.0 19.0 23.0; PB_GRAV=$REPLY
  ar_pick 27.0 26.0 25.0 24.0; PB_FPOW=$REPLY
  ar_pick 1 2 3 5; PB_BONUS=$REPLY
  ar_pick 8.0 5.0 2.5 0.0; PB_SAVE0=$REPLY
  ar_pick 8 10 12 14; gap=$REPLY
  PB_G0=$(( PB_MID - gap / 2 )); PB_G1=$(( PB_G0 + gap - 1 ))
  PB_FL0=$(( PB_G0 - 10 )); PB_FL1=$(( PB_G0 - 1 )); PB_FR0=$(( PB_G1 + 1 )); PB_FR1=$(( PB_G1 + 10 ))
  pb_geom; pb_inks; pb_deal; pb_map
  AR_LIVES=3; PB_MULT=1; PB_BESTM=1; PB_TILT=0.0; PB_TILTED=0; PB_NCOOL=0.0; PB_NUDGES=0; PB_SAVES=0; PB_SAVET=0.0; PB_SFLASH=0.0
  PB_COMBO=0; PB_SWEEPS=0; PB_SPINS=0; PB_LSETS=0; PB_NT=0; PB_NL=0
  PB_TGT=(); for (( i = 0; i < ${#PB_DRX[@]}; i++ )); do PB_TGT+=(0); done
  PB_LIT=(); for (( i = 0; i < ${#PB_LAX[@]}; i++ )); do PB_LIT+=(0); done
  PB_SCOOL=(); for (( i = 0; i < ${#PB_STX[@]}; i++ )); do PB_SCOOL+=(0.0); done
  PB_FLL=0.0; PB_FLR=0.0; PB_SLCOOL=0.0; PB_GATE=0.0; PB_SHAKE=0.0
  PB_PPX=(); PB_PPY=(); PB_PPT=(); PB_PPC=(); PB_PPA=()
  pb_park
  return 0 }
pb_park() {   # rack a fresh ball in the shooter lane
  PB_BX=$PB_LANE; PB_BY=$PB_REST; PB_VX=0.0; PB_VY=0.0; PB_READY=1; PB_INLANE=1; PB_GATE=0.0
  PB_MULT=1; PB_COMBO=0; PB_TILT=0.0; PB_TILTED=0; PB_SAVET=0.0       # a new ball is a fresh bob
  return 0 }
pb_nudge() {   # pb_nudge DX DY · a third of the bob, and it bleeds off at a fifth of that a second
  (( PB_NCOOL > 0.0 || PB_READY || PB_TILTED )) && return 0
  PB_NCOOL=0.22; PB_NUDGES=$(( PB_NUDGES + 1 ))
  PB_VX=$(( PB_VX + $1 * 9.5 )); PB_VY=$(( PB_VY + $2 * 7.5 ))
  (( PB_SHAKE < 0.55 )) && PB_SHAKE=0.55
  PB_TILT=$(( PB_TILT + 0.34 )); ar_snd move
  if (( PB_TILT >= 1.0 )); then PB_TILT=1.0; PB_TILTED=1; PB_SAVET=0.0; ar_snd error; fi   # no save on a tilted ball, ever
  return 0 }
pb_pop() { PB_PPX+=($1); PB_PPY+=($2); PB_PPT+=("$3"); PB_PPC+=($4); PB_PPA+=(0.0); return 0 }
pb_update() {   # pb_update DT
  local -F dt=$1 speed remain step; local k; local -i i guard
  for k in "${AR_KEYS[@]}"; do
    case "$k" in
      LEFT|A)  PB_FLL=0.15 ;;
      RIGHT|D) PB_FLR=0.15 ;;
      SPACE|UP|W) if (( PB_READY )); then PB_READY=0; PB_VX=0.0; PB_VY=$(( -(PB_GRAV * 1.05 + 22.0) )); PB_SAVET=$PB_SAVE0; ar_snd select; fi ;;
      Z) pb_nudge -1.0 0.0 ;;
      X) pb_nudge 1.0 0.0 ;;
      DOWN|S) pb_nudge 0.0 -1.0 ;;
    esac
  done
  (( PB_TILTED )) && { PB_FLL=0.0; PB_FLR=0.0; }        # dead sticks on a tilt
  PB_FLL=$(( PB_FLL > dt ? PB_FLL - dt : 0.0 )); PB_FLR=$(( PB_FLR > dt ? PB_FLR - dt : 0.0 ))
  PB_NCOOL=$(( PB_NCOOL > dt ? PB_NCOOL - dt : 0.0 )); PB_SAVET=$(( PB_SAVET > dt ? PB_SAVET - dt : 0.0 ))
  PB_SFLASH=$(( PB_SFLASH > dt ? PB_SFLASH - dt : 0.0 ))
  (( PB_TILT > 0.0 && ! PB_TILTED )) && PB_TILT=$(( PB_TILT > dt * 0.20 ? PB_TILT - dt * 0.20 : 0.0 ))
  PB_SLCOOL=$(( PB_SLCOOL > dt ? PB_SLCOOL - dt : 0.0 ))
  for (( i = 0; i < ${#PB_SCOOL[@]}; i++ )); do (( PB_SCOOL[i] > 0.0 )) && PB_SCOOL[$i]=$(( PB_SCOOL[i] > dt ? PB_SCOOL[i] - dt : 0.0 )); done
  PB_GATE=$(( PB_GATE > dt ? PB_GATE - dt : 0.0 )); PB_SHAKE=$(( PB_SHAKE > dt * 3.0 ? PB_SHAKE - dt * 3.0 : 0.0 ))
  i=0
  while (( i < ${#PB_PPA[@]} )); do
    PB_PPA[$i]=$(( PB_PPA[i] + dt ))
    if (( PB_PPA[i] > 0.65 )); then PB_PPX[$i]=(); PB_PPY[$i]=(); PB_PPT[$i]=(); PB_PPC[$i]=(); PB_PPA[$i]=(); else i=$(( i + 1 )); fi
  done
  (( PB_READY )) && return 0
  PB_VY=$(( PB_VY + PB_GRAV * dt ))
  PB_VX=$(( PB_VX - PB_VX * (0.30 * dt < 1.0 ? 0.30 * dt : 1.0) ))
  speed=$(( sqrt(PB_VX * PB_VX + PB_VY * PB_VY) ))
  (( speed > 56.0 )) && { PB_VX=$(( PB_VX * 56.0 / speed )); PB_VY=$(( PB_VY * 56.0 / speed )); }
  # sub-step, so nothing is ever crossed in a single jump
  remain=$dt; guard=0
  while (( remain > 0.0001 && guard < 200 )); do
    guard=$(( guard + 1 ))
    speed=$(( sqrt(PB_VX * PB_VX + 4.0 * PB_VY * PB_VY) )); (( speed < 1.0 )) && speed=1.0
    step=$(( 0.45 / speed )); (( step > remain )) && step=$remain
    remain=$(( remain - step ))
    PB_BX=$(( PB_BX + PB_VX * step )); PB_BY=$(( PB_BY + PB_VY * step ))
    pb_collide && return 0
  done
  (( PB_BY > PB_DRAIN + 2 )) && pb_lose       # belt and braces
  return 0 }
pb_collide() {   # one sub-step of collision · 0 when the ball is done with for this frame
  local -i lo hi i push q; local -F d2 d dx dy x
  # ---- the shooter lane's bookkeeping
  if (( PB_INLANE )); then
    if (( PB_BY < PB_DIV_TOP )); then PB_INLANE=0; PB_GATE=1.4; PB_SPINS=$(( PB_SPINS + 1 )); PB_VX=-22.0; ar_add $(( 75 * PB_MULT )); ar_snd move; fi
  elif (( PB_GATE <= 0.0 && PB_BX > PB_DIVX && PB_BY >= PB_DIV_TOP + 0.5 )); then PB_INLANE=1; fi
  # ---- walls
  if (( PB_INLANE )); then lo=$(( PB_DIVX + 1 )); hi=$PB_R; else lo=$PB_L; if (( PB_BY < PB_DIV_TOP )); then hi=$PB_R; else hi=$PB_PLAY_R; fi; fi
  if (( PB_BX <= lo )); then PB_BX=$lo; PB_VX=$(( abs(PB_VX) * 0.93 ))
  elif (( PB_BX >= hi )); then PB_BX=$hi; PB_VX=$(( -abs(PB_VX) * 0.93 )); fi
  (( PB_BY <= PB_TOP )) && { PB_BY=$PB_TOP; PB_VY=$(( abs(PB_VY) * 0.90 )); }
  if (( PB_INLANE )); then
    (( PB_BY >= PB_REST && PB_VY > 0.0 )) && { PB_BY=$PB_REST; PB_VY=0.0; PB_VX=0.0; PB_READY=1; PB_MULT=1; PB_COMBO=0; }
    return 1
  fi
  # ---- the rollover lanes across the top arch
  if (( PB_BY <= PB_TOP + 0.85 )); then
    for (( i = 0; i < ${#PB_LAX[@]}; i++ )); do
      if (( ! PB_LIT[i] && abs(PB_BX - PB_LAX[i]) < 2.2 )); then
        PB_LIT[$i]=1; PB_NL=$(( PB_NL + 1 )); ar_add $(( 800 * PB_MULT )); pb_pop ${PB_LAX[$i]} $PB_TOP LANE $CYAN; ar_snd select
        if (( PB_NL == ${#PB_LAX[@]} )); then
          for (( q = 0; q < PB_NL; q++ )); do PB_LIT[$q]=0; done; PB_NL=0
          PB_LSETS=$(( PB_LSETS + 1 )); PB_BONUS=$(( PB_BONUS >= 9 ? 9 : PB_BONUS + 1 )); ar_add 5000
          pb_pop $PB_MID $(( PB_TOP + 1 )) "BONUS ×$PB_BONUS" $MAGENTA; PB_SHAKE=0.8; ar_snd coin
        fi
        break
      fi
    done
  fi
  # ---- the standing targets in the side alleys
  for (( i = 0; i < ${#PB_STX[@]}; i++ )); do
    (( PB_SCOOL[i] > 0.0 )) && continue
    if (( abs(PB_BX - PB_STX[i]) < 1.3 && abs(PB_BY - PB_STY[i]) < 0.9 )); then
      PB_SCOOL[$i]=0.4; push=$(( PB_STX[i] < PB_MID ? 1 : -1 ))
      PB_VX=$(( push * (abs(PB_VX) * 0.9 > 9.0 ? abs(PB_VX) * 0.9 : 9.0) )); PB_BX=$(( PB_STX[i] + push * 1.4 ))
      ar_add $(( 400 * PB_MULT )); pb_pop ${PB_STX[$i]} ${PB_STY[$i]} 400 $PURPLE; ar_snd move
      break
    fi
  done
  # ---- the pop bumpers
  for (( i = 0; i < ${#PB_BUX[@]}; i++ )); do
    dx=$(( PB_BX - PB_BUX[i] )); dy=$(( (PB_BY - PB_BUY[i]) * 2.0 )); d2=$(( dx * dx + dy * dy ))
    if (( d2 < 5.5 )); then
      d=$(( sqrt(d2) )); (( d == 0.0 )) && d=0.001
      PB_VX=$(( dx / d * 27.0 )); PB_VY=$(( dy / d * 15.0 - 5.0 ))
      PB_BX=$(( PB_BUX[i] + dx / d * 2.4 )); PB_BY=$(( PB_BUY[i] + dy / d * 1.25 ))
      PB_COMBO=$(( PB_COMBO + 1 )); PB_MULT=$(( 1 + PB_COMBO / 4 )); (( PB_MULT > 9 )) && PB_MULT=9
      (( PB_MULT > PB_BESTM )) && PB_BESTM=$PB_MULT
      ar_add $(( 500 * PB_MULT )); pb_pop ${PB_BUX[$i]} ${PB_BUY[$i]} $(( 500 * PB_MULT )) $AMBER; PB_SHAKE=0.5; ar_snd move
      break
    fi
  done
  # ---- the drop targets
  for (( i = 0; i < ${#PB_DRX[@]}; i++ )); do
    (( PB_TGT[i] )) && continue
    if (( abs(PB_BX - PB_DRX[i]) < 1.9 && abs(PB_BY - PB_DRY[i]) < 0.85 )); then
      PB_TGT[$i]=1; PB_NT=$(( PB_NT + 1 ))
      if (( PB_VY > 0.0 )); then PB_BY=$(( PB_DRY[i] - 0.9 )); else PB_BY=$(( PB_DRY[i] + 0.9 )); fi
      PB_VY=$(( -abs(PB_VY) * 0.8 - 4.0 ))
      ar_add $(( 1500 * PB_MULT )); pb_pop ${PB_DRX[$i]} ${PB_DRY[$i]} 1500 $LIME; ar_snd select
      if (( PB_NT == ${#PB_DRX[@]} )); then
        PB_SWEEPS=$(( PB_SWEEPS + 1 )); for (( q = 0; q < PB_NT; q++ )); do PB_TGT[$q]=0; done; PB_NT=0
        q=$(( 25000 * PB_BONUS * PB_SWEEPS )); ar_add $q; ar_commify $q
        pb_pop $PB_MID 9 "SWEEP  $REPLY" $MAGENTA; PB_SHAKE=1.0; ar_snd coin
      fi
      break
    fi
  done
  # ---- the slingshots
  if (( PB_SLCOOL <= 0.0 )); then
    for i in 0 1; do
      if (( abs(PB_BX - PB_SLX[i]) < 2.2 && PB_BY > PB_SLY0 && PB_BY < PB_SLY1 )); then
        PB_VX=$(( PB_SLP[i] * 26.0 )); PB_VY=-15.0; PB_BX=$(( PB_SLX[i] + PB_SLP[i] * 2.3 ))
        PB_SLCOOL=0.18; ar_add $(( 120 * PB_MULT )); PB_SHAKE=0.35; ar_snd move
        break
      fi
    done
  fi
  # ---- the flippers, the apron and the drain
  if (( PB_BY >= PB_FLOOR )); then
    x=$PB_BX
    (( PB_FLL > 0.0 && x >= PB_FL0 - 0.6 && x <= PB_FL1 + 2.0 )) && { pb_flip 1.0; return 1; }
    (( PB_FLR > 0.0 && x >= PB_FR0 - 2.0 && x <= PB_FR1 + 0.6 )) && { pb_flip -1.0; return 1; }
    if (( x < PB_G0 || x > PB_G1 )); then
      # a resting flipper or an inlane: bounce, and roll toward the gap
      PB_BY=$PB_FLOOR; PB_VY=$(( -abs(PB_VY) * 0.42 )); (( abs(PB_VY) < 5.0 )) && PB_VY=-6.5
      if (( x < PB_G0 )); then PB_VX=$(( PB_VX * 0.5 + 7.0 )); else PB_VX=$(( PB_VX * 0.5 - 7.0 )); fi
    elif (( PB_BY >= PB_DRAIN )); then pb_lose; return 0; fi
  fi
  return 1 }
pb_flip() {   # pb_flip SIDE
  PB_BY=$(( PB_FLOOR - 0.8 )); PB_VY=$(( -PB_FPOW )); PB_VX=$(( $1 * (9.0 + abs(PB_VX) * 0.35) ))
  PB_COMBO=0; ar_add 50; ar_snd move; return 0 }
pb_lose() {
  # THE SAVE COMES FIRST · a ball that drains inside the window is racked again for
  # nothing, unless the table has been tilted, and then nothing saves it
  local -i keep
  if (( PB_SAVET > 0.0 && ! PB_TILTED )); then
    PB_SAVES=$(( PB_SAVES + 1 )); PB_SFLASH=1.6; ar_snd coin; keep=$AR_LIVES; pb_park; AR_LIVES=$keep; return 0
  fi
  AR_LIVES=$(( AR_LIVES - 1 )); ar_snd error
  (( AR_LIVES <= 0 )) && { AR_ALIVE=0; return 0; }
  pb_park; return 0 }
pb_paint() {   # pb_paint T · the table, drawn through the stretch
  local -F t=$1 k u v; local -i i j y rail c n bx by px py q x0 ty per mid; local s
  ar_wave $t 0.35; cmix $AMBER $WHITE $(( 0.14 + 0.14 * WV )); rail=$CM
  a_text 0 $AR_FT "$PB_RAILS" $rail -2
  for (( y = AR_FT + 1; y < PB_YAP; y++ )); do a_put 0 $y '┃' $rail -2; a_put $(( AR_W - 1 )) $y '┃' $rail -2; done
  # the rollover lanes
  for (( i = 0; i < ${#PB_LAX[@]}; i++ )); do
    if (( PB_LWIDE )); then s="‹ ${PB_LAT[$i]} ›"; else s="‹${PB_LAT[$i]}›"; fi
    x0=$(( PB_LASX[i] - ${#s} / 2 ))
    if (( PB_LIT[i] )); then a_text $x0 $PB_YT "$s" $PB_LANEON $PB_LANEONB
    else a_text $x0 $PB_YT "$s" $PB_LANEOFF -2; fi
  done
  # the standing targets
  for (( i = 0; i < ${#PB_STX[@]}; i++ )); do
    if (( PB_SCOOL[i] > 0.0 )); then c=$PB_STHOT; else c=$PB_STCOLD; fi
    for (( j = -(PB_SR / 2); j <= PB_SR / 2; j++ )); do a_put ${PB_STSX[$i]} $(( PB_STSY[i] + j )) '▮' $c -2; done
  done
  # the shooter lane
  a_put $PB_XDV $(( PB_YDV - 1 )) '╻' $PB_DIVC -2
  for (( y = PB_YDV; y < PB_YAP; y++ )); do a_put $PB_XDV $y '┃' $PB_DIVC2 -2; done
  per=$(( int(3 * PB_SY + 0.5) ))
  for (( y = PB_YDV; y <= PB_YRS; y++ )); do (( (y + int(t * 3 * PB_SY)) % per == 0 )) && a_put $PB_XLN $y '┆' $PB_LANEAR -2; done
  a_text $PB_XPL0 $PB_YF "${PB_PLG[0,$(( PB_XPL1 - PB_XPL0 ))]}" $PB_PLUNGE -2
  (( ! PB_INLANE && PB_GATE > 0.0 )) && a_put $PB_XDV $PB_YDV '╾' $PB_GATEC -2
  # the pop bumpers, breathing, and lit when the ball is near
  for (( i = 0; i < ${#PB_BUX[@]}; i++ )); do
    if (( abs(PB_BX - PB_BUX[i]) < 4 && abs(PB_BY - PB_BUY[i]) < 2.5 )); then q=16
    else ar_wave $t 1.1 $(( PB_BUX[i] * 0.7 )); q=$(( int((0.5 + 0.5 * WV) * 16 + 0.5) )); fi
    px=${PB_BUSX[$i]}; py=${PB_BUSY[$i]}
    for (( j = 0; j < ${#PB_BSPT[@]}; j++ )); do a_text $(( px + PB_BSPO[j] )) $(( py + PB_BSPR[j] )) "${PB_BSPT[$j]}" ${PB_BUB[$q]} -2; done
    if (( PB_BR )); then a_text $(( px - PB_BA )) $py "$PB_BODY" ${PB_BUB[$q]} -2
    elif (( PB_BPILL )); then a_text $(( px - 2 )) $py '     ' -2 ${PB_BUB[$q]}; fi
    a_text $(( px - 1 )) $py '(◉)' ${PB_BUF[$q]} ${PB_BUB[$q]}
  done
  # the drop targets
  for (( i = 0; i < ${#PB_DRX[@]}; i++ )); do
    x0=$(( PB_DRSX[i] - PB_DW / 2 ))
    if (( PB_TGT[i] )); then a_text $x0 ${PB_DRSY[$i]} "$PB_DOWNS" $PB_DOWNC -2
    else a_text $x0 ${PB_DRSY[$i]} "$PB_DROPS" $PB_DROPC $PB_DROPB; fi
  done
  # the slingshots
  if (( PB_SLCOOL > 0.0 )); then c=$PB_SLHOT; n=$PB_SLHOT2; else c=$PB_SLCOLD; n=$PB_SLCOLD2; fi
  mid=$(( (PB_YS0 + PB_YS1) / 2 ))
  for (( y = PB_YS0; y <= PB_YS1; y++ )); do
    if (( y <= mid )); then q=$c; else q=$n; fi
    a_text $PB_XS0 $y "${PB_SLL}" $q -2; a_text $(( PB_XS1 - PB_SLW + 1 )) $y "${PB_SLR}" $q -2
  done
  # the drain, the apron, the flippers and their posts
  ar_wave $t 0.8; cshade $RED $(( 0.55 + 0.25 * WV ))
  a_text $PB_XG0 $PB_YD "${PB_SHADE[0,$(( PB_XG1 - PB_XG0 ))]}" $CS -2
  (( PB_XA1 >= PB_XA0 )) && a_text $PB_XA0 $PB_YF "${PB_UNDER[0,$(( PB_XA1 - PB_XA0 ))]}" $PB_APRONC -2
  (( PB_XB1 >= PB_XB0 )) && a_text $PB_XB0 $PB_YF "${PB_UNDER[0,$(( PB_XB1 - PB_XB0 ))]}" $PB_APRONC -2
  n=$(( PB_XL1 - PB_XL0 ))
  if (( PB_FLL > 0.0 )); then a_text $PB_XL0 $PB_YF "${PB_OVER[0,$n]}" $PB_FLIPON $PB_FLIPONB; else a_text $PB_XL0 $PB_YF "${PB_LOW[0,$n]}" $PB_FLIPOFF -2; fi
  n=$(( PB_XR1 - PB_XR0 ))
  if (( PB_FLR > 0.0 )); then a_text $PB_XR0 $PB_YF "${PB_OVER[0,$n]}" $PB_FLIPON $PB_FLIPONB; else a_text $PB_XR0 $PB_YF "${PB_LOW[0,$n]}" $PB_FLIPOFF -2; fi
  a_put $PB_XP0 $PB_YF '◆' $PB_POSTC -2; a_put $PB_XP1 $PB_YF '◆' $PB_POSTC -2
  # the score pops, rising and fading
  for (( i = 0; i < ${#PB_PPA[@]}; i++ )); do
    k=$(( 1.0 - PB_PPA[i] / 0.65 )); (( k < 0.0 )) && k=0.0
    s="${PB_PPT[$i]}"
    v=$(( PB_PPY[i] - PB_PPA[i] * 4.0 )); (( v < PB_TOP )) && v=$PB_TOP; (( v > PB_FLOOR )) && v=$PB_FLOOR
    py=$(( int(2 + (v - 2) * PB_SY + 0.5) ))
    px=$(( int(1 + (PB_PPX[i] - 1) * PB_SX + 0.5) - ${#s} / 2 )); (( px > AR_W - ${#s} - 2 )) && px=$(( AR_W - ${#s} - 2 )); (( px < 1 )) && px=1
    cshade ${PB_PPC[$i]} $k; a_text $px $py "$s" $CS -2
  done
  # the ball, with a mote behind it
  u=$(( 1 + (PB_BX - 1) * PB_SX )); v=$(( 2 + (PB_BY - 2) * PB_SY ))
  bx=$(( int(floor(u + 0.5)) )); (( bx < 1 )) && bx=1; (( bx > AR_W - 2 )) && bx=$(( AR_W - 2 ))
  by=$(( int(floor(v + 0.5)) )); (( by < AR_FT )) && by=$AR_FT; (( by > PB_YAP - 1 )) && by=$(( PB_YAP - 1 ))
  if (( PB_VY < -6.0 )); then ty=$(( by + PB_TRY )); (( ty > PB_YAP - 1 )) && ty=$(( PB_YAP - 1 )); a_put $bx $ty '·' $PB_TRAIL -2
  elif (( PB_VY > 6.0 )); then ty=$(( by - PB_TRY )); (( ty < AR_FT )) && ty=$AR_FT; a_put $bx $ty '·' $PB_TRAIL -2; fi
  a_put $bx $by '●' $WHITE $PB_BALLB
  if (( PB_READY )); then
    ar_wave $t 1.1; if (( WV > 0.35 )); then cmix $AMBER $WHITE 0.35; c=$CM; else cshade $AMBER 0.75; c=$CS; fi
    a_center $PB_YPLG '◂ [SPACE] TO PLUNGE ▸' $c -2 1 $PB_XPR
  fi
  # the apron strip
  a_text 0 $PB_YAP "${PB_SHADE//░/ }" -2 $PB_APR
  s=''; for (( i = 0; i < ${#PB_DRX[@]}; i++ )); do if (( PB_TGT[i] )); then s+='·'; else s+='▮'; fi; done
  a_text 2 $PB_YAP BANK $PB_LABC $PB_APR; a_text 7 $PB_YAP "$s" $PB_BANKC $PB_APR
  s=''; for (( i = 0; i < ${#PB_LAX[@]}; i++ )); do if (( PB_LIT[i] )); then s+="${PB_LAT[$i]}"; else s+='·'; fi; done
  a_text 14 $PB_YAP LANES $PB_LABC $PB_APR; a_text 20 $PB_YAP "$s" $PB_LANESC $PB_APR
  a_text 25 $PB_YAP BONUS $PB_LABC $PB_APR; a_text 31 $PB_YAP "×$PB_BONUS" $PB_BONC $PB_APR
  n=$(( 4 - AR_LIVES )); (( n > 3 )) && n=3
  s="SWEEPS $PB_SWEEPS    BALL $n OF 3"; a_text $(( AR_W - 2 - ${#s} )) $PB_YAP "$s" $PB_RIGHTC $PB_APR
  # the bob, the save clock, and the word nobody wants to see
  if (( PB_TILTED )); then cmix $RED $WHITE 0.45; elif (( PB_TILT > 0.66 )); then cmix $RED $WHITE 0.25; else cmix $AMBER $WHITE 0.2; fi; c=$CM
  a_text 34 $PB_YAP TILT $c $PB_APR
  n=$(( int(6 * PB_TILT + 0.5) )); (( n > 6 )) && n=6
  s=''; for (( i = 0; i < n; i++ )); do s+='▮'; done; (( n )) && a_text 39 $PB_YAP "$s" $c $PB_APR
  s=''; for (( i = n; i < 6; i++ )); do s+='▯'; done; (( n < 6 )) && a_text $(( 39 + n )) $PB_YAP "$s" $PB_TOFF $PB_APR
  if (( PB_TILTED )); then
    ar_wave $t 3.0; if (( WV > 0.35 )); then cmix $RED $WHITE 0.5; c=$CM; else cshade $RED 0.85; c=$CS; fi
    a_center $PB_YMSG '◆  T I L T  ◆' $c -2
  elif (( PB_SFLASH > 0.0 )); then
    ar_wave $t 3.0; if (( WV > 0.35 )); then cmix $LIME $WHITE 0.45; c=$CM; else cshade $LIME 0.9; c=$CS; fi
    a_center $PB_YMSG '◆  BALL SAVED  ◆' $c -2
  elif (( PB_SAVET > 0.0 )); then ar_f1 $PB_SAVET; a_text 2 $PB_YSAVE "SAVE ${REPLY}s" $PB_SAVEC -2; fi
  (( PB_MULT > 1 )) && { ar_wave $t 2.4; cmix $AMBER $WHITE $(( 0.35 + 0.3 * WV )); a_text 2 $(( AR_FT + 1 )) "×$PB_MULT" $CM -2; }
  (( PB_SHAKE > 0.0 )) && a_tintr 1 $(( AR_FT + 1 )) $(( AR_W - 2 )) $(( PB_YAP - AR_FT - 1 )) $AMBER $(( 0.10 * (PB_SHAKE < 1.0 ? PB_SHAKE : 1.0) ))
  return 0 }
pb_hud() {
  if (( PB_TILTED )); then cmix $RED $WHITE 0.4; AR_HL=(TILT); AR_HV=(DEAD); AR_HC=($CM); cmix $MAGENTA $WHITE 0.3; AR_HL+=(BONUS); AR_HV+=("×$PB_BONUS"); AR_HC+=($CM)
  else cmix $AMBER $WHITE 0.3; AR_HL=(MULT); AR_HV=("×$PB_MULT"); AR_HC=($CM); cmix $LIME $WHITE 0.25; AR_HL+=(SWEEP); AR_HV+=($PB_SWEEPS); AR_HC+=($CM); fi
  return 0 }
pb_stats() { AR_SL=(SWEEPS 'BEST MULT' LANES NUDGES SAVES); AR_SV=($PB_SWEEPS "×$PB_BESTM" $PB_LSETS $PB_NUDGES $PB_SAVES); return 0 }
pv_plasmaball() {   # bumpers, a plasma ball and a pair of flippers
  local -i x=$1 y=$2 w=$3 h=$4 i bx by fg; local -F p; local -a px py; local s
  px=($(( w / 4 )) $(( w / 2 )) $(( 3 * w / 4 )) $(( w / 3 )) $(( 2 * w / 3 ))); py=(1 2 1 $(( h / 2 )) $(( h / 2 )))
  for (( i = 0; i < 5; i++ )); do
    ar_wave $AR_T 1.1 $(( i * 1.7 )); p=$(( 0.45 + 0.55 * WV ))
    cmix $AMBER $WHITE $(( 0.45 * p )); fg=$CM; cmix $AR_PVBG $AMBER $(( 0.16 * p ))
    a_put $(( x + px[i] )) $(( y + py[i] )) '◉' $fg $CM
  done
  ar_tri $(( AR_T * 0.5 )); bx=$(( int(RF * (w - 1)) )); ar_tri $(( AR_T * 0.73 + 0.2 )); by=$(( int(RF * (h - 2)) ))
  cmix $AR_PVBG $WHITE 0.18; a_put $(( x + bx )) $(( y + by )) '●' $WHITE $CM
  ar_wave $AR_T 1.3; if (( WV > 0.5 )); then s='▟▙'; else s='▄▄'; fi
  cshade $CYAN 0.95; a_text $(( x + 1 )) $(( y + h - 1 )) "$s" $CS -2; a_text $(( x + w - 3 )) $(( y + h - 1 )) "$s" $CS -2
  return 0 }
AR_READY[plasmaball]=1; AR_PREFIX[plasmaball]=pb

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# PLASMA BALL · plunge, then flip whenever the ball is falling into reach · it never nudges
pb_demo() {
  (( PB_READY )) && { AR_DKEYS+=(SPACE); return 0; }
  (( PB_TILTED || PB_BY < PB_FLOOR - 6 || PB_VY <= 0.0 )) && return 0
  (( PB_BX >= PB_FL0 - 1 && PB_BX <= PB_FL1 + 2 )) && { AR_DKEYS+=(LEFT); return 0; }
  (( PB_BX >= PB_FR0 - 2 && PB_BX <= PB_FR1 + 1 )) && AR_DKEYS+=(RIGHT)
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15p · B E A T   G R I D        (rhythm) · rolls, and the dark
# ══════════════════════════════════════════════════════════════════════════
# Four lanes, a metronome, and a chart that thickens as the run goes on.
# Notes are held as absolute hit times against the round clock, so the
# scroll and the judgement windows are the only things a rung changes — the
# music never drifts from the notes.  THE CHART IS WRITTEN the way music is:
# three or four MOTIFS, each a four-beat figure with its own lane shape and
# rhythm, and a STRUCTURE naming which one each bar plays, with a fill every
# fourth bar where the accents and the rolls go.  A ROLL is hollow and wants
# three strikes in its window.  THE DARK, from EXPERT, hides the last stretch
# of every fall: you strike from memory and the beat ruler.
typeset -gi BG_LANES=4 BG_ROLL_HITS=3 BG_LANE_W=9 BG_BODY=8 BG_X0=17 BG_X1=53 BG_TOP=2 BG_SPAWN=3 BG_HIT=15
typeset -gF BG_ROLL_SPAN=2.6
typeset -ga BG_ARROW BG_LETTER BG_TINT; BG_ARROW=('◄' '▼' '▲' '►'); BG_LETTER=(A S W D)
typeset -ga BG_SHAPES; BG_SHAPES=(hold step walk bounce spread pair)
typeset -ga BG_HITSETS; BG_HITSETS=('0 2' '0 1 2 3' '0 2 3' '0 1 3' '0' '0 3')
typeset -gF BG_BPM BG_LEAD BG_PERFECT BG_GOOD BG_DENSITY BG_DRAIN BG_ACCR BG_ROLLR BG_BLIND BG_HEALTH BG_BEAT BG_NEXT BG_PULSE BG_JT
typeset -gi BG_CHORDS BG_ROLLS BG_COMBO BG_BEST BG_HITS BG_MISSES BG_PERFECTS BG_ACCENTS BG_BEATNO BG_BARS BG_JC BG_FELL
typeset -g  BG_JW=''                                   # the judgement word, when, and its colour
typeset -ga BG_MOT BG_ORD BG_GLOW                      # the tune · motifs as "beat:lane …", the bars' order
typeset -ga BG_NL BG_NW BG_ND BG_NA BG_NR BG_NS        # notes · lane when done accent wanted landed
typeset -gi BG_INKS=0 BG_RULEC BG_JBG BG_DARKC BG_DARKT BG_HLOW BG_HOK BG_ACCC
typeset -g  BG_RULE='' BG_BAR='' BG_DASH='' BG_RAILT='' BG_RAILB='' BG_INKAT=''
typeset -g  BG_NOTE='▬▬▬▬▬▬▬▬' BG_NOTEA='▰▰▰▰▰▰▰▰' BG_NOTER='▢▢▢▢▢▢▢▢'
bg_geom() {   # THE DECK IS THE BOARD · arcade.py's four 9-wide lanes over twelve rows of fall,
  # grown to the board: the lanes widen with it and the fall runs to three rows
  # above its foot.  A note still takes BG_LEAD seconds to fall however far that
  # is -- the notes are held as times -- so a longer fall is a faster note and
  # the beat, the windows and the reading time are exactly arcade.py's.
  BG_LANE_W=$(( 9 * AR_W / 72 )); (( BG_LANE_W < 9 )) && BG_LANE_W=9
  BG_BODY=$(( BG_LANE_W - 1 ))
  BG_X0=$(( (AR_W - BG_LANES * BG_LANE_W - 1) / 2 )); BG_X1=$(( BG_X0 + BG_LANES * BG_LANE_W ))
  BG_TOP=2; BG_SPAWN=3; BG_HIT=$(( AR_H - 3 ))
  return 0 }
bg_inks() {
  [[ "$BG_INKAT" == "${AR_W}x$AR_H" ]] && (( BG_INKS )) && return 0
  local -i i
  BG_TINT=($MAGENTA $CYAN $LIME $AMBER)
  cshade $GREY 0.40; BG_RULEC=$CS; cmix $GLASS $VOID_MIX 0.6; BG_JBG=$CM
  cmix $RED $PURPLE 0.5; cshade $CM 0.55; BG_DARKC=$CS; cmix $RED $WHITE 0.2; BG_DARKT=$CM
  cmix $RED $WHITE 0.3; BG_HLOW=$CM; cshade $GREY 1.1; BG_HOK=$CS; cmix $CYAN $WHITE 0.25; BG_ACCC=$CM
  BG_RULE=''; BG_BAR=''; for (( i = 0; i < BG_BODY; i++ )); do BG_RULE+='┄'; BG_BAR+='▔'; done
  BG_DASH=''; for (( i = 0; i < BG_X1 - BG_X0 - 1; i++ )); do BG_DASH+='╌'; done
  BG_RAILT='┏'; BG_RAILB='┗'; for (( i = 0; i < BG_X1 - BG_X0 - 1; i++ )); do BG_RAILT+='━'; BG_RAILB+='━'; done; BG_RAILT+='┓'; BG_RAILB+='┛'
  BG_NOTE=''; BG_NOTEA=''; BG_NOTER=''; for (( i = 0; i < BG_BODY; i++ )); do BG_NOTE+='▬'; BG_NOTEA+='▰'; BG_NOTER+='▢'; done
  BG_INKS=1; BG_INKAT="${AR_W}x$AR_H"; return 0 }
bg_x() { REPLY=$(( BG_X0 + $1 * BG_LANE_W + 1 )); return 0 }   # the left-hand column of a lane's interior
bg_write() {   # the board's own tune · some motifs, and an order to play them in
  local -i n m i b ln root step bars other c; local shape fig; local -a cnt hits
  BG_MOT=(); BG_ORD=()
  cnt=(3 3 4); rnd_pick 3; n=${cnt[$REPLY]}
  for (( m = 0; m < n; m++ )); do
    rnd_pick 6; shape=${BG_SHAPES[$REPLY]}
    rnd_pick $BG_LANES; root=$REPLY
    cnt=(1 1 2 3); rnd_pick 4; step=${cnt[$REPLY]}
    rnd_pick 6; hits=(${=BG_HITSETS[$REPLY]})
    fig=''
    for (( i = 0; i < ${#hits[@]}; i++ )); do
      b=${hits[$i]}
      case $shape in
        hold)   ln=$root ;;
        step)   ln=$(( root + i * step )) ;;
        walk)   ln=$(( root + (i % 2 == 0 ? i : -i) )) ;;
        bounce) ln=$(( root + (i % 2 == 0 ? 0 : step) )) ;;
        spread) ln=$(( root + i * (BG_LANES / 2) )) ;;
        *)      ln=$(( root + (i / 2) * step )) ;;
      esac
      ln=$(( ((ln % BG_LANES) + BG_LANES) % BG_LANES ))
      fig+="${fig:+ }$b:$ln"
    done
    BG_MOT+=("$fig")
  done
  cnt=(4 8 8); rnd_pick 3; bars=${cnt[$REPLY]}
  for (( i = 0; i < bars; i++ )); do rnd_pick $n; BG_ORD+=($REPLY); done
  for (( i = 1; i < bars; i += 2 )); do rnd_f; (( RF < 0.55 )) && BG_ORD[$i]=${BG_ORD[$(( i - 1 ))]}; done   # a call and answer
  c=1; for (( i = 1; i < bars; i++ )); do (( BG_ORD[i] != BG_ORD[0] )) && { c=2; break; }; done
  if (( c < 2 )); then other=$(( (BG_ORD[0] + 1) % n )); rnd_range 1 $bars; BG_ORD[$REPLY]=$other; fi   # …but not a drone
  BG_BARS=$bars; return 0 }
bg_tune() {
  local -i try m total; local -a notes
  BG_FELL=0
  for (( try = 0; try < 24; try++ )); do
    # the notes are counted as words, into an array · ${#${=…}} of a one-note motif is its LENGTH, "0:0" three
    bg_write; total=0; for (( m = 0; m < ${#BG_MOT[@]}; m++ )); do notes=(${=BG_MOT[$m]}); total=$(( total + ${#notes[@]} )); done
    (( ${#BG_MOT[@]} >= 3 && BG_BARS >= 4 && total >= 6 )) && return 0
  done
  BG_FELL=1; BG_MOT=('0:0 2:1' '0:2 2:3' '0:1 1:2 2:3'); BG_ORD=(0 0 1 2 0 1 2 2); BG_BARS=8
  return 0 }
bg_begin() {
  AR_G_LEGEND='◄ ▼ ▲ ► ON THE LINE      [P] PAUSE      [Q] CASH OUT'
  AR_G_HOWTO='strike on the line  ·  gold wants PERFECT  ·  hollow wants three'
  AR_G_ACC=$MAGENTA; AR_G_OVER='OFF BEAT'
  ar_pick 88.0 108.0 132.0 158.0; BG_BPM=$REPLY
  ar_pick 2.10 1.75 1.45 1.15; BG_LEAD=$REPLY           # seconds of fall
  ar_pick 0.115 0.090 0.072 0.058; BG_PERFECT=$REPLY
  ar_pick 0.240 0.195 0.155 0.120; BG_GOOD=$REPLY
  ar_pick 0.40 0.54 0.68 0.82; BG_DENSITY=$REPLY
  ar_pick 6.5 9.0 12.0 15.0; BG_DRAIN=$REPLY
  ar_pick 0 0 1 1; BG_CHORDS=$REPLY
  ar_pick 0.0 0.18 0.30 0.42; BG_ACCR=$REPLY
  ar_pick 0.10 0.14 0.18 0.22; BG_ROLLR=$REPLY
  bg_geom; bg_inks; bg_tune
  ar_pick 0.0 0.0 0.22 0.38; BG_BLIND=$REPLY             # the blind share of the fall
  BG_ROLLS=0; BG_HEALTH=100.0; BG_COMBO=0; BG_BEST=0; BG_HITS=0; BG_MISSES=0; BG_PERFECTS=0; BG_ACCENTS=0
  BG_NL=(); BG_NW=(); BG_ND=(); BG_NA=(); BG_NR=(); BG_NS=()
  BG_JW=''; BG_JT=-99.0; BG_JC=$WHITE; BG_GLOW=(0.0 0.0 0.0 0.0)
  BG_BEAT=$(( 60.0 / BG_BPM )); BG_NEXT=0.9; BG_BEATNO=-1; BG_PULSE=0.0
  return 0 }
bg_chart() {   # deal out the beat that is `lead` seconds away
  local -i bar beat fill ln accent roll i; local -F heat; local -a lanes; local e
  BG_BEATNO=$(( BG_BEATNO + 1 ))
  bar=$(( (BG_BEATNO / 4) % (BG_BARS > 1 ? BG_BARS : 1) )); beat=$(( BG_BEATNO % 4 ))
  fill=$(( (bar + 1) % 4 == 0 ))
  heat=$(( BG_DENSITY + AR_RT / 240.0 )); (( heat > 0.95 )) && heat=0.95
  lanes=()
  for e in ${=BG_MOT[${BG_ORD[$bar]}]}; do (( ${e%%:*} == beat )) && lanes+=(${e#*:}); done
  if (( ! ${#lanes[@]} && fill )); then rnd_f; (( RF < heat * 0.55 )) && { rnd_pick $BG_LANES; lanes=($REPLY); }; fi   # a fill's own note
  if (( ! ${#lanes[@]} )); then rnd_f; (( RF < heat * 0.22 )) && { rnd_pick $BG_LANES; lanes=($REPLY); }; fi           # a passing note
  if (( BG_CHORDS && ${#lanes[@]} )); then rnd_f; if (( RF < heat * 0.30 )); then rnd_int 1 3; lanes+=($(( (lanes[0] + REPLY) % BG_LANES ))); fi; fi
  for ln in "${lanes[@]}"; do
    accent=0; roll=0
    if (( beat == 0 && BG_ACCR > 0.0 )); then rnd_f; (( RF < BG_ACCR )) && accent=1; fi
    if (( ! accent && fill && (beat == 2 || beat == 3) )); then rnd_f; (( RF < BG_ROLLR * 2.4 )) && roll=1; fi
    BG_NL+=($ln); BG_NW+=($(( AR_RT + BG_LEAD ))); BG_ND+=(0); BG_NA+=($accent); BG_NR+=($(( roll ? BG_ROLL_HITS : 0 ))); BG_NS+=(0)
  done
  return 0 }
bg_judge() { BG_JW="$1"; BG_JT=$AR_RT; BG_JC=$2; return 0 }
bg_hurt() {   # bg_hurt · a miss's cost · 1 when it ended the round
  BG_MISSES=$(( BG_MISSES + 1 )); BG_COMBO=0; cmix $RED $WHITE 0.3; bg_judge MISS $CM
  BG_HEALTH=$(( BG_HEALTH - BG_DRAIN )); ar_snd error
  (( BG_HEALTH <= 0.0 )) && { BG_HEALTH=0.0; AR_ALIVE=0; return 1; }
  return 0 }
bg_update() {   # bg_update DT
  local -F dt=$1 d gap; local k; local -i i lane best gain sharp roll
  local -a pressed; pressed=(0 0 0 0)
  BG_NEXT=$(( BG_NEXT - dt ))
  if (( BG_NEXT <= 0.0 )); then BG_NEXT=$(( BG_NEXT + BG_BEAT )); BG_PULSE=1.0; bg_chart; fi
  BG_PULSE=$(( BG_PULSE > dt * 4.0 ? BG_PULSE - dt * 4.0 : 0.0 ))
  for (( i = 0; i < BG_LANES; i++ )); do (( BG_GLOW[i] > 0.0 )) && BG_GLOW[$i]=$(( BG_GLOW[i] > dt ? BG_GLOW[i] - dt : 0.0 )); done
  for k in "${AR_KEYS[@]}"; do
    case "$k" in LEFT|A) pressed[0]=1 ;; DOWN|S) pressed[1]=1 ;; UP|W) pressed[2]=1 ;; RIGHT|D) pressed[3]=1 ;; esac
  done
  for (( lane = 0; lane < BG_LANES; lane++ )); do
    (( pressed[lane] )) || continue
    BG_GLOW[$lane]=0.18
    # A ROLL EATS THE PRESS FIRST · its window is wider than a single note's
    roll=-1
    for (( i = 0; i < ${#BG_NL[@]}; i++ )); do
      (( BG_NL[i] == lane && BG_NR[i] && ! BG_ND[i] && abs(BG_NW[i] - AR_RT) <= BG_GOOD * BG_ROLL_SPAN )) && { roll=$i; break; }
    done
    if (( roll >= 0 )); then
      BG_NS[$roll]=$(( BG_NS[roll] + 1 )); BG_COMBO=$(( BG_COMBO + 1 )); (( BG_COMBO > BG_BEST )) && BG_BEST=$BG_COMBO
      BG_HITS=$(( BG_HITS + 1 )); ar_add $(( 220 * (1 + (BG_COMBO < 60 ? BG_COMBO : 60) / 10) ))
      BG_HEALTH=$(( BG_HEALTH + 1.0 > 100.0 ? 100.0 : BG_HEALTH + 1.0 ))
      if (( BG_NS[roll] >= BG_NR[roll] )); then
        BG_ND[$roll]=1; BG_ROLLS=$(( BG_ROLLS + 1 )); cmix $CYAN $WHITE 0.5; bg_judge '◈ ROLL ◈' $CM; ar_add 900; ar_snd coin
      else cmix $CYAN $WHITE 0.3; bg_judge "ROLL ${BG_NS[$roll]}/${BG_NR[$roll]}" $CM; ar_snd select; fi
      continue
    fi
    best=-1; gap=1000000000.0
    for (( i = 0; i < ${#BG_NL[@]}; i++ )); do
      (( BG_NL[i] != lane || BG_ND[i] || BG_NR[i] )) && continue
      d=$(( abs(BG_NW[i] - AR_RT) )); (( d < gap )) && { best=$i; gap=$d; }
    done
    if (( best >= 0 && gap <= BG_GOOD )); then
      BG_ND[$best]=1; sharp=$(( gap <= BG_PERFECT ))
      if (( BG_NA[best] && ! sharp )); then
        cmix $RED $WHITE 0.3; bg_judge 'OFF ACCENT' $CM; BG_COMBO=0; BG_MISSES=$(( BG_MISSES + 1 ))
        BG_HEALTH=$(( BG_HEALTH - BG_DRAIN )); ar_snd error
        (( BG_HEALTH <= 0.0 )) && { BG_HEALTH=0.0; AR_ALIVE=0; return 0; }
        continue
      fi
      if (( sharp )); then
        BG_PERFECTS=$(( BG_PERFECTS + 1 ))
        if (( BG_NA[best] )); then BG_ACCENTS=$(( BG_ACCENTS + 1 )); cmix $AMBER $WHITE 0.55; bg_judge '◆ ACCENT ◆' $CM; gain=900
        else cmix $LIME $WHITE 0.45; bg_judge PERFECT $CM; gain=300; fi
      else cmix $CYAN $WHITE 0.35; bg_judge GOOD $CM; gain=150; fi
      BG_COMBO=$(( BG_COMBO + 1 )); (( BG_COMBO > BG_BEST )) && BG_BEST=$BG_COMBO; BG_HITS=$(( BG_HITS + 1 ))
      ar_add $(( gain * (1 + (BG_COMBO < 60 ? BG_COMBO : 60) / 10) ))
      BG_HEALTH=$(( BG_HEALTH + (BG_NA[best] ? 2.4 : 1.4) )); (( BG_HEALTH > 100.0 )) && BG_HEALTH=100.0
      if (( BG_NA[best] )); then ar_snd coin; else ar_snd select; fi
    else
      cshade $GREY 1.15; bg_judge EARLY $CS; BG_COMBO=0
      BG_HEALTH=$(( BG_HEALTH > 1.5 ? BG_HEALTH - 1.5 : 0.0 ))
      (( BG_HEALTH <= 0.0 )) && { AR_ALIVE=0; return 0; }
    fi
  done
  # what has fallen past the line
  i=0
  while (( i < ${#BG_NL[@]} )); do
    if (( BG_ND[i] )); then
      if (( BG_NW[i] < AR_RT - 0.45 )); then BG_NL[$i]=(); BG_NW[$i]=(); BG_ND[$i]=(); BG_NA[$i]=(); BG_NR[$i]=(); BG_NS[$i]=(); continue; fi
    elif (( BG_NR[i] )); then
      # a roll only misses once its whole window has gone by
      if (( BG_NW[i] < AR_RT - BG_GOOD * BG_ROLL_SPAN )); then BG_ND[$i]=1; (( BG_NS[i] <= 0 )) && { bg_hurt || return 0; }; fi
    elif (( BG_NW[i] < AR_RT - BG_GOOD )); then
      BG_ND[$i]=1; bg_hurt || return 0
    fi
    i=$(( i + 1 ))
  done
  AR_LEVEL=$(( 1 + BG_HITS / 25 )); (( AR_LEVEL > 99 )) && AR_LEVEL=99
  return 0 }
bg_paint() {   # bg_paint T
  local -F t=$1 bt k g; local -i span=$(( BG_HIT - BG_SPAWN )) ln lx col y edge c near fg bg i; local s word
  # the deck the lanes sit on
  for (( ln = 0; ln < BG_LANES; ln++ )); do
    bg_x $ln; lx=$REPLY; g=$(( BG_GLOW[ln] / 0.18 ))
    cmix $GLASS ${BG_TINT[$ln]} $(( 0.05 + 0.12 * g )); a_rect $lx $BG_SPAWN $BG_BODY $span ' ' -2 $CM
  done
  # the beat ruler · a faint tick where each upcoming beat will land
  bt=$BG_NEXT
  while (( bt < BG_LEAD )); do
    y=$(( BG_SPAWN + int((1.0 - bt / (BG_LEAD > 0.01 ? BG_LEAD : 0.01)) * span) ))
    if (( y >= BG_SPAWN && y < BG_HIT )); then for (( ln = 0; ln < BG_LANES; ln++ )); do bg_x $ln; a_text $REPLY $y "$BG_RULE" $BG_RULEC -2; done; fi
    bt=$(( bt + BG_BEAT ))
  done
  # the falling notes
  for (( i = 0; i < ${#BG_NL[@]}; i++ )); do
    (( BG_ND[i] )) && continue
    k=$(( 1.0 - (BG_NW[i] - AR_RT) / (BG_LEAD > 0.01 ? BG_LEAD : 0.01) )); (( k < 0.0 )) && continue
    y=$(( BG_SPAWN + int(k * span) )); (( y > BG_HIT )) && continue
    # THE DARK · past here the note is not drawn · a roll is exempt, you cannot count strikes you cannot see start
    (( BG_BLIND > 0.0 && ! BG_NR[i] && k > 1.0 - BG_BLIND )) && continue
    if (( BG_NA[i] )); then col=$AMBER; else col=${BG_TINT[${BG_NL[$i]}]}; fi
    near=$(( abs(BG_NW[i] - AR_RT) <= BG_PERFECT ))
    if (( BG_NR[i] )); then s=$BG_NOTER; elif (( BG_NA[i] )); then s=$BG_NOTEA; else s=$BG_NOTE; fi
    if (( near )); then cmix $col $WHITE 0.60; fg=$CM; cmix $GLASS $col 0.30; bg=$CM; else cmix $col $WHITE 0.18; fg=$CM; cmix $GLASS $col 0.12; bg=$CM; fi
    bg_x ${BG_NL[$i]}; lx=$REPLY
    a_text $lx $y "$s" $fg $bg
    if (( BG_NR[i] )); then word="${BG_NS[$i]}/${BG_NR[$i]}"; cmix $WHITE $col 0.2; fg=$CM; cmix $GLASS $col 0.30; a_text $(( lx + BG_BODY / 2 - 1 )) $y "${word[0,2]}" $fg $CM; fi
  done
  # the rails, the judgement line, the keycaps
  cmix $MAGENTA $WHITE $(( 0.10 + 0.16 * BG_PULSE )); edge=$CM
  a_text $BG_X0 $BG_TOP "$BG_RAILT" $edge -2
  cshade $edge 0.75; c=$CS
  a_rect $BG_X0 $BG_SPAWN 1 $(( span + 1 )) '│' $c -2; a_rect $BG_X1 $BG_SPAWN 1 $(( span + 1 )) '│' $c -2
  cshade $GREY $(( 0.5 + 0.3 * BG_PULSE )); c=$CS
  for (( ln = 1; ln < BG_LANES; ln++ )); do a_rect $(( BG_X0 + ln * BG_LANE_W )) $BG_SPAWN 1 $(( span + 1 )) '│' $c -2; done
  for (( ln = 0; ln < BG_LANES; ln++ )); do
    bg_x $ln; lx=$REPLY; col=${BG_TINT[$ln]}; g=$(( BG_GLOW[ln] / 0.18 ))
    cmix $col $WHITE $(( 0.30 + 0.55 * g )); fg=$CM; cmix $GLASS $col $(( 0.10 + 0.34 * g ))
    a_text $lx $BG_HIT "$BG_BAR" $fg $CM
  done
  cshade $edge 0.65; a_text $BG_X0 $(( BG_HIT + 1 )) "$BG_RAILB" $CS -2
  for (( ln = 0; ln < BG_LANES; ln++ )); do
    bg_x $ln; lx=$(( REPLY + BG_BODY / 2 - 1 )); col=${BG_TINT[$ln]}; g=$(( BG_GLOW[ln] / 0.18 ))
    cmix $col $WHITE $(( 0.20 + 0.6 * g )); fg=$CM; cmix $GLASS $col $(( 0.10 + 0.3 * g ))
    a_text $lx $(( BG_HIT + 1 )) " ${BG_ARROW[$ln]} " $fg $CM
    cshade $GREY $(( 0.75 + 0.6 * g )); a_put $(( lx + 1 )) $(( BG_HIT + 2 )) "${BG_LETTER[$ln]}" $CS -2
  done
  # the judgement, and the chain
  if [[ -n "$BG_JW" ]] && (( AR_RT - BG_JT < 0.5 )); then
    k=$(( 1.0 - (AR_RT - BG_JT) / 0.5 )); word=" $BG_JW "
    cshade $BG_JC $(( 0.45 + k )); a_text $(( BG_X0 + (BG_X1 - BG_X0 - ${#word}) / 2 )) $(( BG_HIT - 4 )) "$word" $CS $BG_JBG
  fi
  if (( BG_COMBO >= 5 )); then
    word=" CHAIN $BG_COMBO "; ar_wave $t 3.0; cmix $AMBER $WHITE $(( 0.20 + 0.25 * WV ))
    a_text $(( BG_X0 + (BG_X1 - BG_X0 - ${#word}) / 2 )) $(( BG_HIT - 2 )) "$word" $CM $BG_JBG
  fi
  # the meters, clear of the deck
  if (( BG_HEALTH <= 35.0 )); then ar_wave $t 3.5; cmix $RED $WHITE $(( 0.25 + 0.3 * WV )); c=$CM; fg=$BG_HLOW
  else cmix $LIME $WHITE 0.30; c=$CM; fg=$BG_HOK; fi
  ar_bar 2 $AR_FT 12 $(( BG_HEALTH / 100.0 )) $c
  ar_lpad "$(( int(BG_HEALTH + 0.5) ))" 3; a_text 15 $AR_FT "${REPLY}%" $fg -2
  k=$(( 100.0 * BG_HITS / (BG_HITS + BG_MISSES > 1 ? BG_HITS + BG_MISSES : 1) ))
  ar_f1 $k; ar_lpad "$REPLY" 5; a_text $(( AR_W - 13 )) $AR_FT "ACC ${REPLY}%" $BG_ACCC -2
  (( BG_PULSE > 0.0 )) && { cmix $MAGENTA $WHITE $(( 0.2 + 0.5 * BG_PULSE )); a_put $(( AR_W - 15 )) $AR_FT '◆' $CM -2; }
  if (( BG_BLIND > 0.0 )); then
    y=$(( BG_SPAWN + int((1.0 - BG_BLIND) * span) ))     # a rail on the deck showing where sight stops
    (( y > BG_SPAWN && y < BG_HIT )) && a_text $(( BG_X0 + 1 )) $y "$BG_DASH" $BG_DARKC -2
    a_text 20 $AR_FT "DARK $(( int(BG_BLIND * 100 + 0.0001) ))%" $BG_DARKT -2
  fi
  return 0 }
bg_hud() { cmix $AMBER $WHITE 0.3; AR_HL=(CHAIN); AR_HV=($BG_COMBO); AR_HC=($CM); return 0 }
bg_stats() {
  local -i acc=$(( int(100.0 * BG_HITS / (BG_HITS + BG_MISSES > 1 ? BG_HITS + BG_MISSES : 1) + 0.5) ))
  AR_SL=(CHAIN ACC ACCENTS ROLLS); AR_SV=($BG_BEST "${acc}%" $BG_ACCENTS $BG_ROLLS); return 0 }
pv_beatgrid() {   # notes falling onto the hit line
  local -i x=$1 y=$2 w=$3 h=$4 lane n lw lx py col fg; local -F ph; local s=''
  lw=$(( w / 4 > 1 ? w / 4 : 1 ))
  for (( n = 0; n < w; n++ )); do s+='▔'; done
  ar_wave $AR_T 2.0; cshade $WHITE $(( 0.35 + 0.4 * WV )); fg=$CS; cmix $AR_PVBG $WHITE 0.10; a_text $x $(( y + h - 1 )) "$s" $fg $CM
  (( ${#BG_TINT[@]} )) || BG_TINT=($MAGENTA $CYAN $LIME $AMBER)
  for (( lane = 0; lane < 4; lane++ )); do
    lx=$(( x + lane * lw + lw / 2 )); col=${BG_TINT[$lane]}
    for (( n = 0; n < 3; n++ )); do
      ph=$(( AR_T * 0.85 + lane * 0.31 + n * 0.37 )); ph=$(( ph - floor(ph) )); py=$(( int(ph * (h - 2)) ))
      if (( ph > 0.86 )); then cmix $col $WHITE 0.5; fg=$CM; cmix $AR_PVBG $col 0.20
      else cmix $col $WHITE $(( 0.15 + 0.5 * ph )); fg=$CM; cmix $AR_PVBG $col 0.09; fi
      a_text $(( lx - 1 )) $(( y + py )) '▬▬' $fg $CM
    done
  done
  return 0 }
AR_READY[beatgrid]=1; AR_PREFIX[beatgrid]=bg

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# BEAT GRID · strike each lane as its note arrives — a hair late on purpose, so it reads as played
bg_demo() {
  local -i i; local -F gap; local -a lk; lk=(LEFT DOWN UP RIGHT)
  for (( i = 0; i < ${#BG_NL[@]}; i++ )); do
    (( BG_ND[i] )) && continue
    gap=$(( BG_NW[i] - AR_RT ))
    (( gap >= -BG_GOOD * 0.5 && gap <= BG_PERFECT * 1.2 )) && AR_DKEYS+=(${lk[${BG_NL[$i]}]})
  done
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15e · B L O C K   F A L L        (puzzle) · the hold, and how far ahead you see
# ══════════════════════════════════════════════════════════════════════════
# HOLD ([C]) sets the falling piece aside and hands you whatever was there
# before: one swap a piece, locked until a piece lands, which is the rule
# that makes it a decision rather than a shuffle.  THE QUEUE is what the rung
# really changes: ROOKIE sees four pieces, NORMAL three, EXPERT two, INSANE
# one — speed made the hard rungs faster, this makes them BLINDER.  The two
# hard rungs start on a dealt floor whose holes overlap row to row, so the
# junk is CLEARABLE rather than a wall of buried gaps.
typeset -gi BF_W=10 BF_H=15 BF_X=26 BF_Y=2
typeset -gi BF_S=1 BF_CW=2 BF_CH=1     # a block's size on the glass · 2×1, or 4×2 on a board with the rows for it
typeset -ga BF_NAME BF_BOX BF_CELLS BF_COL BF_CLEAR
BF_NAME=(I O T S Z J L); BF_BOX=(4 2 3 3 3 3 3)
BF_CELLS=('0,1 1,1 2,1 3,1' '0,0 1,0 0,1 1,1' '1,0 0,1 1,1 2,1' '1,0 2,0 0,1 1,1' '0,0 1,0 1,1 2,1' '0,0 0,1 1,1 2,1' '2,0 0,1 1,1 2,1')
BF_CLEAR=(0 100 300 500 800)
typeset -gF BF_FALL0 BF_RAMP BF_FLOOR BF_ACC BF_FLASHT
typeset -gi BF_GARB BF_SEE BF_JUNK BF_HELD BF_SWAPPED BF_HOLDS BF_LINES BF_PIECES BF_COMBO BF_PS BF_PB BF_PX BF_PY BF_PCOL BF_ON
typeset -g  BF_PC=''                              # the piece's cells, as it is turned
typeset -ga BF_G BF_BAG BF_Q BF_FLASH             # the well (0 is empty) · the bag · the queue · rows mid-clear
typeset -gA BF_BGM                                # a block's ground, by its colour
typeset -gi BF_INKS=0 BF_DOT BF_JUNKC BF_JUNK2 BF_GREYT BF_KEYC BF_LINESC BF_LEVELC BF_COMBOC BF_JUNKT BF_FLASHA BF_FLASHB1 BF_FLASHB2
typeset -ga BF_SC
bf_inks() {
  (( BF_INKS )) && return 0
  BF_SC=($CYAN $AMBER $PURPLE $LIME $RED $BLUE $PINK)
  cshade $PURPLE 0.30; BF_DOT=$CS; cshade $GREY 0.62; BF_JUNKC=$CS; cshade $GREY 0.75; BF_JUNK2=$CS
  cshade $GREY 1.1; BF_GREYT=$CS; cshade $GREY 1.05; BF_KEYC=$CS
  cmix $LIME $WHITE 0.25; BF_LINESC=$CM; cmix $CYAN $WHITE 0.25; BF_LEVELC=$CM; cmix $AMBER $WHITE 0.3; BF_COMBOC=$CM
  BF_JUNKT=$RED; cmix $AMBER $WHITE 0.5; BF_FLASHA=$CM; cmix $GLASS $WHITE 0.25; BF_FLASHB1=$CM; cmix $GLASS $WHITE 0.10; BF_FLASHB2=$CM
  BF_INKS=1; return 0 }
bf_bgof() {   # bf_bgof COLOUR → REPLY a block's ground · remembered
  REPLY=${BF_BGM[$1]:-}
  [[ -n "$REPLY" ]] && return 0
  cmix $GLASS $1 0.10; BF_BGM[$1]=$CM; REPLY=$CM; return 0 }
bf_pull() {   # → REPLY a shape · from a shuffled bag of all seven
  local -i i j t
  if (( ! ${#BF_BAG[@]} )); then
    BF_BAG=(0 1 2 3 4 5 6)
    for (( i = 6; i > 0; i-- )); do rnd_int 0 $i; j=$REPLY; t=${BF_BAG[$i]}; BF_BAG[$i]=${BF_BAG[$j]}; BF_BAG[$j]=$t; done
  fi
  REPLY=${BF_BAG[-1]}; BF_BAG[-1]=(); return 0 }
bf_terrain() {   # the hard rungs start on a dealt floor · each row's holes overlap the row below
  local -i n=$BF_JUNK i y x width start anchor h0=-1 h1=-1; local -a opts
  (( n )) || return 0
  for (( i = 0; i < n; i++ )); do
    y=$(( BF_H - 1 - i ))
    opts=(1 1 2 2 3); rnd_pick 5; width=${opts[$REPLY]}
    if (( h0 < 0 )); then rnd_range 0 $(( BF_W - width + 1 )); start=$REPLY
    else
      rnd_int $h0 $h1; anchor=$REPLY                 # keep at least one column of the last row's hole open
      rnd_range 0 $width; start=$(( anchor - REPLY )); (( start < 0 )) && start=0; (( start > BF_W - width )) && start=$(( BF_W - width ))
    fi
    h0=$start; h1=$(( start + width - 1 ))
    for (( x = 0; x < BF_W; x++ )); do if (( x >= h0 && x <= h1 )); then BF_G[$(( y * BF_W + x ))]=0; else BF_G[$(( y * BF_W + x ))]=$BF_JUNKC; fi; done
  done
  return 0 }
bf_begin() {
  AR_G_LEGEND='◄► MOVE  ▲ ROTATE  ▼ DROP  [SPACE] SLAM  [C] HOLD  [P] PAUSE  [Q] OUT'
  AR_G_HOWTO='stack the falling shapes  ·  [C] holds one back for later'
  AR_G_ACC=$CYAN; AR_G_OVER='STACK OUT'
  local -i i
  ar_pick 0.88 0.66 0.46 0.33; BF_FALL0=$REPLY
  ar_pick 0.055 0.062 0.070 0.078; BF_RAMP=$REPLY
  ar_pick 0.16 0.11 0.075 0.055; BF_FLOOR=$REPLY
  ar_pick 0 0 14 8; BF_GARB=$REPLY                  # pieces between junk rows
  ar_pick 4 3 2 1; BF_SEE=$REPLY                    # pieces of the queue shown
  ar_pick 0 0 2 4; BF_JUNK=$REPLY                   # rows already in the well
  bf_inks
  # THE WELL IS TEN WIDE WHATEVER THE GLASS · the width is the game.  Its depth
  # is what the board gives, up to a classic twenty-two, and on a board with the
  # rows for it every block is drawn twice the size -- four columns by two rows
  # -- so a full-screen board is a big well rather than a long thin one.
  BF_S=1; (( AR_H - 3 >= 36 && AR_W >= 110 )) && BF_S=2
  BF_CW=$(( 2 * BF_S )); BF_CH=$BF_S
  BF_H=$(( (AR_H - 3) / BF_S )); (( BF_H > 22 )) && BF_H=22; (( BF_H < 15 )) && BF_H=15
  BF_X=$(( (AR_W - BF_W * BF_CW) / 2 )); BF_Y=$(( 2 + ((AR_H - 3) - BF_H * BF_CH) / 2 ))
  BF_G=(); for (( i = 0; i < BF_W * BF_H; i++ )); do BF_G+=(0); done
  BF_BAG=(); BF_ON=0; BF_HELD=-1; BF_SWAPPED=0; BF_HOLDS=0
  BF_Q=(); for (( i = 0; i < 4; i++ )); do bf_pull; BF_Q+=($REPLY); done
  bf_terrain
  BF_LINES=0; BF_PIECES=0; BF_COMBO=0; BF_ACC=0.0; BF_FLASH=(); BF_FLASHT=0.0
  bf_spawn -1
  return 0 }
bf_spawn() {   # bf_spawn SHAPE · -1 takes the next off the queue
  local -i s=$1
  if (( s < 0 )); then s=${BF_Q[0]}; BF_Q[0]=(); bf_pull; BF_Q+=($REPLY); fi
  BF_PS=$s; BF_PB=${BF_BOX[$s]}; BF_PC=${BF_CELLS[$s]}; BF_PCOL=${BF_SC[$s]}
  BF_PX=$(( (BF_W - BF_PB) / 2 )); BF_PY=0; BF_ON=1
  BF_SWAPPED=0; BF_PIECES=$(( BF_PIECES + 1 ))
  bf_hits "$BF_PC" $BF_PX $BF_PY && AR_ALIVE=0
  return 0 }
bf_hold() {   # set this one aside · the first hold takes the next off the queue, after that the two trade
  local -i was
  if (( BF_SWAPPED || ! BF_ON )); then ar_snd error; return 0; fi
  if (( BF_HELD < 0 )); then BF_HELD=$BF_PS; bf_spawn -1
  else was=$BF_HELD; BF_HELD=$BF_PS; bf_spawn $was; fi      # put back the way it was drawn
  BF_HOLDS=$(( BF_HOLDS + 1 )); BF_SWAPPED=1; BF_ACC=0.0; ar_snd move
  return 0 }
bf_hits() {   # bf_hits CELLS PX PY → 0 when the piece would touch a wall, the floor, or the stack
  local c; local -i x y
  for c in ${=1}; do
    x=$(( $2 + ${c%%,*} )); y=$(( $3 + ${c#*,} ))
    (( x < 0 || x >= BF_W || y >= BF_H )) && return 0
    (( y >= 0 && BF_G[y * BF_W + x] )) && return 0
  done
  return 1 }
bf_turn() {   # bf_turn CELLS BOX → REPLY the cells a quarter turn round inside a BOX × BOX square
  local c out=''; local -i b=$2
  for c in ${=1}; do out+="${out:+ }$(( b - 1 - ${c#*,} )),${c%%,*}"; done
  REPLY="$out"; return 0 }
bf_drop_to() { local -i py=$3; while ! bf_hits "$1" $2 $(( py + 1 )); do py=$(( py + 1 )); done; REPLY=$py; return 0 }
bf_lock() {
  local c; local -i x y n full
  for c in ${=BF_PC}; do
    x=$(( BF_PX + ${c%%,*} )); y=$(( BF_PY + ${c#*,} ))
    (( y >= 0 && y < BF_H && x >= 0 && x < BF_W )) && BF_G[$(( y * BF_W + x ))]=$BF_PCOL
  done
  BF_FLASH=()
  for (( y = 0; y < BF_H; y++ )); do
    full=1; for (( x = 0; x < BF_W; x++ )); do (( BF_G[y * BF_W + x] )) || { full=0; break; }; done
    (( full )) && BF_FLASH+=($y)
  done
  if (( ${#BF_FLASH[@]} )); then
    BF_FLASHT=0.34; n=${#BF_FLASH[@]}
    BF_LINES=$(( BF_LINES + n )); BF_COMBO=$(( BF_COMBO + 1 ))
    ar_add $(( BF_CLEAR[n > 4 ? 4 : n] * AR_LEVEL + (n == 4) * 200 + (BF_COMBO - 1) * 40 ))
    if (( n >= 4 )); then ar_snd coin; else ar_snd select; fi
  else
    BF_COMBO=0; BF_ON=0; bf_after_lock
  fi
  return 0 }
bf_after_lock() {
  (( BF_GARB && BF_PIECES && BF_PIECES % BF_GARB == 0 )) && bf_garbage
  AR_LEVEL=$(( 1 + BF_LINES / 10 )); (( AR_LEVEL > 20 )) && AR_LEVEL=20
  (( AR_ALIVE )) && bf_spawn -1
  return 0 }
bf_garbage() {   # a junk row shoves everything up · the hard rungs only
  local -i hole x
  rnd_range 0 $BF_W; hole=$REPLY
  for (( x = 0; x < BF_W; x++ )); do (( BF_G[x] )) && { AR_ALIVE=0; return 0; }; done
  BF_G=("${BF_G[@]:$BF_W}")
  for (( x = 0; x < BF_W; x++ )); do if (( x == hole )); then BF_G+=(0); else BF_G+=($BF_JUNK2); fi; done
  return 0 }
bf_settle() {   # the cleared rows go, and the stack above them comes down
  local -i y x
  for y in ${(on)BF_FLASH[@]}; do
    BF_G=("${BF_G[@]:0:$(( y * BF_W ))}" "${BF_G[@]:$(( (y + 1) * BF_W ))}")
    BF_G=(0 0 0 0 0 0 0 0 0 0 "${BF_G[@]}")
  done
  BF_FLASH=(); BF_ON=0; bf_after_lock
  return 0 }
bf_update() {   # bf_update DT
  local -F dt=$1 interval; local k; local -i guard=0 kick
  if (( ${#BF_FLASH[@]} )); then
    BF_FLASHT=$(( BF_FLASHT - dt )); (( BF_FLASHT <= 0.0 )) && bf_settle
    return 0
  fi
  (( BF_ON )) || return 0
  for k in "${AR_KEYS[@]}"; do
    case "$k" in
      LEFT|A)  bf_hits "$BF_PC" $(( BF_PX - 1 )) $BF_PY || BF_PX=$(( BF_PX - 1 )) ;;
      RIGHT|D) bf_hits "$BF_PC" $(( BF_PX + 1 )) $BF_PY || BF_PX=$(( BF_PX + 1 )) ;;
      UP|W)    bf_turn "$BF_PC" $BF_PB
               for kick in 0 -1 1 -2 2; do
                 bf_hits "$REPLY" $(( BF_PX + kick )) $BF_PY || { BF_PC="$REPLY"; BF_PX=$(( BF_PX + kick )); ar_snd move; break; }
               done ;;
      DOWN|S)  bf_hits "$BF_PC" $BF_PX $(( BF_PY + 1 )) || { BF_PY=$(( BF_PY + 1 )); ar_add 1; BF_ACC=0.0; } ;;
      SPACE)   bf_drop_to "$BF_PC" $BF_PX $BF_PY; ar_add $(( 2 * (REPLY - BF_PY) )); BF_PY=$REPLY; ar_snd select; bf_lock; return 0 ;;
      C)       bf_hold; return 0 ;;
    esac
  done
  interval=$(( BF_FALL0 - (AR_LEVEL - 1) * BF_RAMP )); (( interval < BF_FLOOR )) && interval=$BF_FLOOR
  # never bank a stall · a hitched frame used to hand the next piece a three-row head start
  BF_ACC=$(( BF_ACC + dt )); (( BF_ACC > interval * 3 )) && BF_ACC=$(( interval * 3 ))
  while (( BF_ACC >= interval && BF_ON && guard < 3 )); do
    BF_ACC=$(( BF_ACC - interval )); guard=$(( guard + 1 ))
    if bf_hits "$BF_PC" $BF_PX $(( BF_PY + 1 )); then BF_ACC=0.0; bf_lock; return 0; fi
    BF_PY=$(( BF_PY + 1 ))
  done
  return 0 }
bf_cell() {   # bf_cell X Y GLYPH2 FG BG · one block of the well at its size on the glass
  local g="$3"; local -i r; (( BF_S > 1 )) && g="$3$3"
  for (( r = 0; r < BF_CH; r++ )); do a_text $(( BF_X + $1 * BF_CW )) $(( BF_Y + $2 * BF_CH + r )) "$g" $4 $5; done
  return 0 }
bf_mino() {   # bf_mino X0 Y0 X Y GLYPH2 FG BG · a queue or hold block, the same size, anywhere
  local g="$5"; local -i r; (( BF_S > 1 )) && g="$5$5"
  for (( r = 0; r < BF_CH; r++ )); do a_text $(( $1 + $3 * BF_CW )) $(( $2 + $4 * BF_CH + r )) "$g" $6 $7; done
  return 0 }
bf_paint() {   # bf_paint T
  local -F t=$1 dim; local -i cx cy x y i k col base bg fg gy s r j lx rx bot hy; local c g row
  ar_wave $t 0.3; cmix $CYAN $WHITE $(( 0.15 + 0.15 * WV ))
  a_box $(( BF_X - 1 )) $(( BF_Y - 1 )) $(( BF_W * BF_CW + 2 )) $(( BF_H * BF_CH + 2 )) $CM $GLASS heavy 0
  # the well, straight into the cells
  base=$(( (OY + R_SCR + AY + BF_Y) * TCOLS + OX + C_SCR + AX + BF_X ))
  for (( cy = 0; cy < BF_H; cy++ )); do
    for (( cx = 0; cx < BF_W; cx++ )); do
      col=${BF_G[$(( cy * BF_W + cx ))]}
      if (( col )); then
        bf_bgof $col
        for (( r = 0; r < BF_CH; r++ )); do
          k=$(( base + (cy * BF_CH + r) * TCOLS + cx * BF_CW ))
          for (( j = 0; j < BF_CW; j++ )); do GCH[$k]='█'; GF[$k]=$col; GB[$k]=$REPLY; k=$(( k + 1 )); done
        done
      elif (( (cx + cy) % 2 == 0 )); then k=$(( base + (cy * BF_CH + BF_CH / 2) * TCOLS + cx * BF_CW + BF_CW / 2 - 1 )); GCH[$k]='·'; GF[$k]=$BF_DOT; fi
    done
  done
  if (( ${#BF_FLASH[@]} )); then
    if (( int(BF_FLASHT * 14) % 2 == 0 )); then fg=$WHITE; bg=$BF_FLASHB1; else fg=$BF_FLASHA; bg=$BF_FLASHB2; fi
    row=''; repeat $(( BF_W * BF_CW )) row+='█'
    for cy in "${BF_FLASH[@]}"; do for (( r = 0; r < BF_CH; r++ )); do a_text $BF_X $(( BF_Y + cy * BF_CH + r )) "$row" $fg $bg; done; done
  fi
  if (( BF_ON && ! ${#BF_FLASH[@]} )); then
    bf_drop_to "$BF_PC" $BF_PX $BF_PY; gy=$REPLY
    if (( gy != BF_PY )); then
      cshade $BF_PCOL 0.35; fg=$CS
      for c in ${=BF_PC}; do x=$(( BF_PX + ${c%%,*} )); y=$(( gy + ${c#*,} )); (( y >= 0 && y < BF_H && x >= 0 && x < BF_W )) && bf_cell $x $y '▒▒' $fg -2; done
    fi
    cmix $GLASS $BF_PCOL 0.14; bg=$CM
    for c in ${=BF_PC}; do x=$(( BF_PX + ${c%%,*} )); y=$(( BF_PY + ${c#*,} )); (( y >= 0 && y < BF_H && x >= 0 && x < BF_W )) && bf_cell $x $y '██' $BF_PCOL $bg; done
  fi
  # the side panels · the queue and the hold on the left, the keys and the count on
  # the right, set against the well the way arcade.py set them, at the well's size
  lx=$(( BF_X - 6 - 4 * BF_CW )); (( lx < 3 )) && lx=3
  rx=$(( BF_X + BF_W * BF_CW + 4 )); bot=$(( BF_Y + BF_H * BF_CH - 1 ))
  a_text $lx $BF_Y "NEXT $BF_SEE" $BF_GREYT -2
  for (( i = 0; i < BF_SEE && i < ${#BF_Q[@]}; i++ )); do
    s=${BF_Q[$i]}; col=${BF_SC[$s]}; if (( i == 0 )); then dim=1.0; g='██'; else dim=0.45; g='▓▓'; fi
    cshade $col $dim; fg=$CS; cmix $GLASS $col $(( 0.12 * dim )); bg=$CM
    for c in ${=BF_CELLS[$s]}; do bf_mino $(( lx + 1 )) $(( BF_Y + 1 + i * 3 * BF_CH )) ${c%%,*} ${c#*,} "$g" $fg $bg; done
  done
  # HOLD sits at the foot of the well whatever the queue is doing
  hy=$(( bot - 2 * BF_CH - 1 ))
  if (( BF_SWAPPED )); then a_text $lx $hy 'HOLD [C]' $AR_LO -2; else a_text $lx $hy 'HOLD [C]' $BF_GREYT -2; fi
  if (( BF_HELD >= 0 )); then
    col=${BF_SC[$BF_HELD]}; if (( BF_SWAPPED )); then cshade $col 0.45; else cshade $col 1.0; fi; fg=$CS; cmix $GLASS $col 0.12; bg=$CM
    for c in ${=BF_CELLS[$BF_HELD]}; do bf_mino $(( lx + 1 )) $(( hy + 1 )) ${c%%,*} ${c#*,} '██' $fg $bg; done
  else a_text $(( lx + 1 )) $(( hy + 1 )) empty $AR_LO -2; fi
  a_text $rx $(( bot - 1 )) "LINES $BF_LINES" $BF_LINESC -2
  a_text $rx $bot "LEVEL $AR_LEVEL" $BF_LEVELC -2
  (( BF_COMBO > 1 )) && a_text $rx $(( bot + 1 )) "COMBO ×$BF_COMBO" $BF_COMBOC -2
  a_text $rx $(( BF_Y + 1 )) '◄ ►' $BF_KEYC -2; a_text $(( rx + 5 )) $(( BF_Y + 1 )) move $AR_LO -2
  a_text $rx $(( BF_Y + 3 )) ' ▲ ' $BF_KEYC -2; a_text $(( rx + 5 )) $(( BF_Y + 3 )) rotate $AR_LO -2
  a_text $rx $(( BF_Y + 5 )) ' ▼ ' $BF_KEYC -2; a_text $(( rx + 5 )) $(( BF_Y + 5 )) drop $AR_LO -2
  a_text $rx $(( BF_Y + 7 )) spc $BF_KEYC -2; a_text $(( rx + 5 )) $(( BF_Y + 7 )) slam $AR_LO -2
  a_text $rx $(( BF_Y + 8 )) ' C ' $BF_KEYC -2; a_text $(( rx + 5 )) $(( BF_Y + 8 )) hold $AR_LO -2
  if (( BF_GARB )); then a_text $rx $(( BF_Y + 10 )) 'JUNK ROW' $BF_JUNKT -2; a_text $rx $(( BF_Y + 11 )) "in $(( BF_GARB - BF_PIECES % BF_GARB ))" $BF_GREYT -2; fi
  return 0 }
bf_hud() { cmix $LIME $WHITE 0.25; AR_HL=(LINES); AR_HV=($BF_LINES); AR_HC=($CM); return 0 }
bf_stats() { AR_SL=(LINES LEVEL PIECES HELD); AR_SV=($BF_LINES $AR_LEVEL $BF_PIECES $BF_HOLDS); return 0 }
typeset -ga PVB_H PVB_F PVB_B; typeset -gi PVB_W=-1
pv_blockfall() {   # a stack, and a tee falling into it
  local -i x=$1 y=$2 w=$3 h=$4 c i keep base k slot drop col; local -F kk; local -a cols
  cols=($CYAN $AMBER $MAGENTA $PURPLE $LIME $RED)
  if (( PVB_W != w )); then   # the same stack every time · the preview's own seed, the round's untouched
    keep=$RS; rnd_seed 7; PVB_H=(); for (( c = 0; c < w; c++ )); do rnd_int 0 2; PVB_H+=($REPLY); done; RS=$keep
    PVB_F=(); PVB_B=(); for (( i = 0; i < 6; i++ )); do cshade ${cols[$i]} 0.72; PVB_F+=($CS); cmix $AR_PVBG ${cols[$i]} 0.12; PVB_B+=($CM); done
    PVB_W=$w
  fi
  base=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX + x ))
  for (( c = 0; c < w; c++ )); do
    for (( i = 0; i < PVB_H[c]; i++ )); do k=$(( base + (h - 1 - i) * TCOLS + c )); GCH[$k]='█'; GF[$k]=${PVB_F[$(( (c + i) % 6 ))]}; GB[$k]=${PVB_B[$(( (c + i) % 6 ))]}; done
  done
  kk=$(( AR_T / 2.2 )); drop=$(( int((kk - floor(kk)) * (h - 2)) )); slot=$(( int(kk) % (w - 4 > 1 ? w - 4 : 1) )); col=${cols[$(( int(kk) % 6 ))]}
  cmix $AR_PVBG $col 0.20
  a_text $(( x + slot + 1 )) $(( y + drop )) '███' $col $CM; a_put $(( x + slot + 2 )) $(( y + drop + 1 )) '█' $col $CM
  cshade $PURPLE 0.55; for (( c = 0; c < w; c++ )); do (( PVB_H[c] == 0 )) && a_put $(( x + c )) $(( y + h - 1 )) '▁' $CS $AR_PVBG; done
  return 0 }
AR_READY[blockfall]=1; AR_PREFIX[blockfall]=bf

# ── the demonstrator · this machine's hand on the stick, for DEMO PLAY (moved here from x_demo) ──
# BLOCK FALL · every landing scored on height, lines, holes and bumpiness, decided once a piece
typeset -gi BF_BOT_FOR=-1 BF_BOT_X=0; typeset -g BF_BOT_C=''
bf_demo() {
  (( BF_ON && ! ${#BF_FLASH[@]} )) || return 0
  if (( BF_BOT_FOR != BF_PIECES )); then
    local spun="$BF_PC" c best_c="$BF_PC"; local -i turn x y lines holes bump sumh top gx gy i ok h0 h1 bestx=$BF_PX
    local -F score best=-1000000.0; local -a g hts
    for (( turn = 0; turn < 4; turn++ )); do
      for (( x = -2; x <= BF_W; x++ )); do
        bf_hits "$spun" $x $BF_PY && continue
        bf_drop_to "$spun" $x $BF_PY; y=$REPLY
        g=("${BF_G[@]}"); ok=1
        for c in ${=spun}; do
          gx=$(( x + ${c%%,*} )); gy=$(( y + ${c#*,} ))
          (( gx >= 0 && gx < BF_W && gy >= 0 && gy < BF_H )) || { ok=0; break; }
          g[$(( gy * BF_W + gx ))]=1
        done
        (( ok )) || continue
        lines=0; for (( gy = 0; gy < BF_H; gy++ )); do h0=1; for (( gx = 0; gx < BF_W; gx++ )); do (( g[gy * BF_W + gx] )) || { h0=0; break; }; done; lines=$(( lines + h0 )); done
        hts=(); holes=0; sumh=0
        for (( gx = 0; gx < BF_W; gx++ )); do
          top=$BF_H; for (( gy = 0; gy < BF_H; gy++ )); do (( g[gy * BF_W + gx] )) && { top=$gy; break; }; done
          hts+=($(( BF_H - top ))); sumh=$(( sumh + BF_H - top ))
          for (( gy = top + 1; gy < BF_H; gy++ )); do (( g[gy * BF_W + gx] )) || holes=$(( holes + 1 )); done
        done
        bump=0; for (( i = 0; i < BF_W - 1; i++ )); do h0=${hts[$i]}; h1=${hts[$(( i + 1 ))]}; bump=$(( bump + (h0 > h1 ? h0 - h1 : h1 - h0) )); done
        score=$(( -0.51 * sumh + 0.76 * lines - 0.36 * holes - 0.18 * bump ))
        (( score > best )) && { best=$score; best_c="$spun"; bestx=$x; }
      done
      bf_turn "$spun" $BF_PB; spun="$REPLY"
    done
    BF_BOT_FOR=$BF_PIECES; BF_BOT_C="$best_c"; BF_BOT_X=$bestx
  fi
  if [[ "$BF_PC" != "$BF_BOT_C" ]]; then AR_DKEYS+=(UP)
  elif (( BF_PX < BF_BOT_X )); then AR_DKEYS+=(RIGHT)
  elif (( BF_PX > BF_BOT_X )); then AR_DKEYS+=(LEFT)
  else AR_DKEYS+=(SPACE); fi
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 12 · THE ROOMS' FURNITURE      the tab row, the wrap, the gate, the token, the toast
# ══════════════════════════════════════════════════════════════════════════
# Every room off the menu is a list on the left and a panel on the right,
# with a row of tabs over the list when it is long enough to need them.
# These are the pieces they share, so the market and the trophy room are the
# same room wearing different stock.

# the rarities · a colour each, the one signal a shelf gives
typeset -gA AR_RARC
ar_rar_inks() {
  local c
  _pack 150 150 150; AR_RARC[common]=$PK;   _pack 200 185 138; AR_RARC[classic]=$PK
  _pack 95 215 95;   AR_RARC[uncommon]=$PK; _pack 95 215 255;  AR_RARC[rare]=$PK
  _pack 175 135 255; AR_RARC[epic]=$PK;     _pack 255 215 95;  AR_RARC[legendary]=$PK
  return 0 }

# ar_catrow X Y W SEL BG ACCENT LABEL:COUNT… — one row of tabs, windowed round the one you are on
ar_catrow() {
  local -i x=$1 y=$2 w=$3 sel=$4 bg=$5 acc=$6 n lo hi used grew cx i hb; shift 6
  local -a segs; local s
  for s in "$@"; do segs+=("${s%%:*} ${s##*:}"); done
  n=${#segs[@]}; (( n )) || return 0
  lo=$sel; hi=$(( sel + 1 )); used=$(( ${#segs[$sel]} + 2 ))
  while :; do
    grew=0
    if (( hi < n )) && (( used + ${#segs[$hi]} + 3 <= w - 4 )); then used=$(( used + ${#segs[$hi]} + 3 )); hi=$(( hi + 1 )); grew=1; fi
    if (( lo > 0 )) && (( used + ${#segs[$(( lo - 1 ))]} + 3 <= w - 4 )); then used=$(( used + ${#segs[$(( lo - 1 ))]} + 3 )); lo=$(( lo - 1 )); grew=1; fi
    (( grew )) || break
  done
  cx=$(( x + 2 ))
  if (( lo > 0 )); then cshade $acc 0.8; a_text $x $y '◂' $CS $bg; else cshade $acc 0.3; a_text $x $y ' ' $CS $bg; fi
  cmix $bg $acc 0.42; hb=$CM
  cshade $GREY 0.95
  for (( i = lo; i < hi; i++ )); do
    s="${segs[$i]}"
    if (( i == sel )); then a_fill $(( cx - 1 )) $y $(( ${#s} + 2 )) 1 ' ' -2 $hb; a_text $cx $y "$s" $WHITE $hb
    else a_text $cx $y "$s" $CS $bg; fi
    cx=$(( cx + ${#s} + 3 ))
  done
  if (( hi < n )); then cshade $acc 0.8; a_text $(( x + w - 1 )) $y '▸' $CS $bg; else cshade $acc 0.3; a_text $(( x + w - 1 )) $y ' ' $CS $bg; fi
  return 0 }

# ar_wrap TEXT WIDTH [LINES=2] → AR_WL · greedy, padded or cut to exactly LINES rows
typeset -ga AR_WL
ar_wrap() {
  local -i w=$2 lines=${3:-2}; local word cur=''
  AR_WL=()
  for word in ${=1}; do
    if [[ -z "$cur" ]]; then cur="$word"
    elif (( ${#cur} + 1 + ${#word} <= w )); then cur+=" $word"
    else AR_WL+=("$cur"); cur="$word"; fi
  done
  [[ -n "$cur" ]] && AR_WL+=("$cur")
  AR_WL=("${AR_WL[@]:0:$lines}")
  while (( ${#AR_WL[@]} < lines )); do AR_WL+=(''); done
  return 0 }

# ar_hotrow Y ACCENT [AMT=0.30] — the selected row's sweep, bright at the left and fading out
# across the list's whole width, whatever the split makes it · a cell a column, so the
# grounds go straight into the cells, mixed once a width, an accent and a phase
ar_hotrow() {
  local -i y=$1 acc=$2 xx sb base lw=$AR_LIST_W; local -F f sweep amt=${3:-0.30}; local mk s
  (( y < 0 || y >= AR_H )) && return 0
  (( lw > AR_W )) && lw=$AR_W
  ar_wave $AR_T 0.35; sweep=$(( 0.5 + 0.5 * WV )); sb=$(( int(sweep * 7.99) ))
  # the whole row of grounds is kept, not a cell of it · one slice a frame
  mk="h.$acc.$sb.$amt.$lw.$AR_LIST_W"
  if [[ -z "${AR_SWROW[$mk]:-}" ]]; then
    s=''
    for (( xx = 0; xx < lw; xx++ )); do
      f=$(( 1.0 - xx / (AR_LIST_W + 0.0) )); (( f < 0.0 )) && f=0.0
      cmix $GLASS $acc $(( 0.07 + amt * f * (sb + 0.5) / 8.0 )); s+="$CM "
    done
    (( ${#AR_SWROW[@]} > 256 )) && AR_SWROW=(); AR_SWROW[$mk]="$s"
  fi
  base=$(( (OY + R_SCR + AY + y) * TCOLS + OX + C_SCR + AX ))
  ar_run $lw ' '; GCH[$base,$(( base + lw - 1 ))]=("${AR_RUN[@]}"); GB[$base,$(( base + lw - 1 ))]=(${=AR_SWROW[$mk]})
  cmix $acc $WHITE 0.45; a_put 0 $y '▌' $CM -2
  cmix $WHITE $acc 0.15; a_text 2 $y '▶' $CM -2
  return 0 }
# THE ROOM'S FRAME, FROM THE CRT IN HAND.  A room off the menu is a tab row, a
# list under it on the menu's side of the split (AR_LIST_W), a panel on the
# other, and a rule and a message line pinned to the bottom -- arcade.py's rows
# 1 / 2..15 / 16 / 17 on its eighteen, stretched to whatever AR_H is · every frame
typeset -gi AR_RM_TOP=2 AR_RM_ROWS=14 AR_RM_PX=42 AR_RM_PW=30 AR_RM_PY=2 AR_RM_PH=14 AR_RM_FY=16 AR_RM_MY=17
ar_room_geom() {
  AR_RM_TOP=2; AR_RM_ROWS=$(( AR_H - 4 )); (( AR_RM_ROWS < 1 )) && AR_RM_ROWS=1
  AR_RM_PX=$(( AR_LIST_W + 1 )); AR_RM_PW=$(( AR_W - AR_RM_PX )); AR_RM_PY=2; AR_RM_PH=$(( AR_H - 4 ))
  AR_RM_FY=$(( AR_H - 2 )); AR_RM_MY=$(( AR_H - 1 ))
  return 0 }
ar_list_frame() {   # ar_list_frame SCROLL ROWS N [TOP=2] — the rule down the split to the footer, and the list's scroll arrows
  local -i scroll=$1 rows=$2 n=$3 top=${4:-2} bot=$(( AR_H - 3 ))
  cshade $CYAN 0.9
  (( scroll > 0 )) && a_text $(( AR_LIST_W - 1 )) $top '▲' $CS
  (( scroll + rows < n )) && a_text $(( AR_LIST_W - 1 )) $(( top + rows - 1 )) '▼' $CS
  cshade $PURPLE 0.55; a_rect $AR_LIST_W $top 1 $(( bot - top + 1 )) '│' $CS -2
  return 0 }
ar_room_head() {   # ar_room_head GLYPH-TITLE ACCENT MIDDLE [RIGHT] [AMOUNT=0.22] — a room's own band across row 0
  local -i hb; local rt="${4:-}"
  cmix $GLASS $2 ${5:-0.22}; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $2 0.2; a_text 2 0 "$1" $CM $hb
  [[ -n "$3" ]] && { cshade $WHITE 0.85; a_center 0 "$3" $CS $hb; }
  # NO RIGHT, NO BANK · the house band one row up counts the coins on every page,
  # and a room's own band used to count them again under it
  [[ -n "$rt" ]] && { cshade $WHITE 0.8; a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $CS $hb; }
  return 0 }
ar_scroll_fit() {   # ar_scroll_fit SEL SCROLL ROWS N → REPLY the scroll that keeps SEL on the page
  local -i sel=$1 sc=$2 rows=$3 n=$4
  (( sel < sc )) && sc=$sel
  (( sel >= sc + rows )) && sc=$(( sel - rows + 1 ))
  (( sc > n - rows )) && sc=$(( n - rows )); (( sc < 0 )) && sc=0
  REPLY=$sc; return 0 }

# ── ARE YOU SURE? · anything that spends or destroys goes through here ────
# Only [Y] confirms · ⏎ and ⎋ both back out, so a stray key can never wipe
# anything.  A gate is a page: what it asks, what it says under the question,
# the function [Y] runs, and the page it hands back to either way.
typeset -g  AR_CF_HEAD='' AR_CF_Q='' AR_CF_D1='' AR_CF_D2='' AR_CF_YES='YES' AR_CF_NO='KEEP' AR_CF_WARN='' AR_CF_DO='' AR_CF_BACK='menu'
typeset -gi AR_CF_ACC=0
ar_confirm() {   # ar_confirm HEAD QUESTION D1 D2 ACCENT YES NO WARN ON-YES BACK [ON-NO]
  AR_CF_HEAD="$1"; AR_CF_Q="$2"; AR_CF_D1="$3"; AR_CF_D2="$4"; AR_CF_ACC=$5
  AR_CF_YES="$6"; AR_CF_NO="$7"; AR_CF_WARN="${8:-THIS CANNOT BE UNDONE}"; AR_CF_DO="$9"; AR_CF_BACK="${10:-menu}"; AR_CF_NOPE="${11:-}"
  [[ -n "$AR_CF_WARN" ]] || AR_CF_WARN='THIS CANNOT BE UNDONE'
  ar_snd error; ar_go confirm; return 0 }
# A CENTRED PAGE ON A TALLER TUBE · the gate, the token and the purchase window
# were composed down arcade.py's eighteen rows; on more, the band stays on row 0,
# what sat on rows 16 / 17 goes to the bottom two, and the rest comes down by
# half of what the tube gained, so it stands in the middle of the glass
ar_rm_oy() { REPLY=$(( (AR_H - AR_OH) / 2 )); (( REPLY < 0 )) && REPLY=0; return 0 }
ar_draw_confirm() {
  local -F t=$AR_T; local -i hb bw acc=$AR_CF_ACC c oy; local ytxt="[ Y ]  $AR_CF_YES" ntxt="[ N ]  $AR_CF_NO"
  ar_rm_oy; oy=$REPLY
  # THE HEADLINE GOES DOWN BEFORE ITS BAND.  Its glow reaches two rows up, and
  # arcade.py drew the band first, so the glow punched a row of dark holes in
  # it over every letter · drawn the other way round the band stays whole.
  big_width "$AR_CF_HEAD"; bw=$BW
  local -i cx cy
  AR_BCOL=(); for (( cx = 0; cx < bw; cx++ )); do cmix $acc $AMBER $(( 0.20 + 0.45 * cx / (bw > 1 ? bw * 1.0 : 1.0) )); AR_BCOL[$cx]=$CM; done
  AR_BROW=(); for (( cy = 0; cy < 5; cy++ )); do ar_wave $t 0.7 $cy; AR_BROW[$cy]=$(( 0.12 * WV )); done
  ar_big_cols "$AR_CF_HEAD" $(( (AR_W - bw) / 2 )) $(( 2 + oy )) $acc
  AR_BROW=()
  cmix $GLASS $acc 0.24; hb=$CM
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $acc 0.2; a_text 2 0 '◤ CONFIRM' $CM $hb
  cshade $WHITE 0.8; a_text $(( AR_W - 2 - ${#AR_CF_WARN} )) 0 "$AR_CF_WARN" $CS $hb
  a_center $(( 8 + oy )) "$AR_CF_Q" $WHITE $GLASS
  cshade $GREY 1.05; c=$CS
  [[ -n "$AR_CF_D1" ]] && a_center $(( 10 + oy )) "$AR_CF_D1" $c $GLASS
  [[ -n "$AR_CF_D2" ]] && a_center $(( 11 + oy )) "$AR_CF_D2" $c $GLASS
  ar_wave $t 1.0; cmix $acc $WHITE $(( 0.25 * WV ))
  a_text $(( AR_W / 2 - ${#ytxt} - 3 )) $(( 13 + oy )) "$ytxt" $CM $GLASS
  cmix $LIME $WHITE 0.2; a_text $(( AR_W / 2 + 3 )) $(( 13 + oy )) "$ntxt" $CM $GLASS
  (( t - AR_VIEW_T0 > 0.4 )) && a_center $(( AR_H - 2 )) 'anything other than Y backs out' $AR_LO $GLASS
  return 0 }
ar_confirm_key() {
  local back="$AR_CF_BACK" act="$AR_CF_DO" nope="$AR_CF_NOPE"
  case "$1" in
    y|Y) AR_CF_DO=''; AR_CF_NOPE=''; ar_snd select; ar_go "$back"; [[ -n "$act" ]] && $act ;;
    n|N|esc|q|Q|enter|' '|space|back) AR_CF_DO=''; AR_CF_NOPE=''; ar_snd move; ar_go "$back"; [[ -n "$nope" ]] && $nope ;;
  esac
  return 0 }      # a gate takes every key · nothing reaches the door while it is up
typeset -g AR_CF_NOPE=''

# ── THE DAILY TOKEN · one top-up a day, only while the bank is under ten ──
typeset -gi AR_DY_BEFORE=0 AR_DY_GOT=0
typeset -gF AR_DY_TOOK=-1.0
ar_open_daily() { AR_DY_BEFORE=${AR[credits]:-0}; AR_DY_GOT=0; AR_DY_TOOK=-1.0; ar_snd select; ar_go daily; return 0 }
ar_draw_daily() {
  local -F t=$AR_T k ph; local -i hb bw i shown c oy; local rt word='FREE COINS'
  ar_rm_oy; oy=$REPLY
  ar_today; rt="$REPLY"
  big_width "$word"; bw=$BW
  local -F sweep d; local -i cx
  sweep=$(( t * 0.55 )); sweep=$(( (sweep - floor(sweep / 1.8) * 1.8) * (bw + 22) - 11 ))
  AR_BCOL=()
  for (( cx = 0; cx < bw; cx++ )); do
    cmix $AMBER $LIME $(( cx / (bw > 1 ? bw * 1.0 : 1.0) * 0.75 ))
    d=$(( abs(cx - sweep) )); (( d < 4.0 )) && cmix $CM $WHITE $(( (1.0 - d / 4.0) ** 2 * 0.8 ))
    AR_BCOL[$cx]=$CM
  done
  ar_big_cols "$word" $(( (AR_W - bw) / 2 )) $(( 2 + oy )) $AMBER
  cmix $GLASS $AMBER 0.24; hb=$CM                      # the band after the headline, as on the gate
  a_fill 0 0 $AR_W 1 ' ' -2 $hb
  cmix $WHITE $AMBER 0.25; a_text 2 0 '◤ DAILY TOKEN' $CM $hb
  cshade $WHITE 0.8; a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $CS $hb
  if (( AR_DY_TOOK < 0.0 )); then
    cshade $GREY 1.1; a_center $(( 8 + oy )) 'the arcade stakes players who are running low' $CS $GLASS
    ar_wave $t 0.9; cmix $AMBER $WHITE $(( 0.3 + 0.3 * WV )); a_center $(( 10 + oy )) "◆ $AR_DAILY_COINS COINS ◆" $CM $GLASS
    ar_pad $AR_DY_BEFORE 4; local a="$REPLY"; ar_pad $(( AR_DY_BEFORE + AR_DAILY_COINS > AR_MAX_COINS ? AR_MAX_COINS : AR_DY_BEFORE + AR_DAILY_COINS )) 4
    a_center $(( 12 + oy )) "COIN BANK  $a  ▸  $REPLY" $LIME $GLASS
    ar_wave $t 0.85; (( WV > 0.35 )) && { cmix $LIME $WHITE 0.35; a_center $(( 14 + oy )) '◂ PRESS [⏎] TO COLLECT ▸' $CM $GLASS; }
  else
    k=$(( (t - AR_DY_TOOK) / 1.2 )); (( k > 1.0 )) && k=1.0
    for (( i = 0; i < 10; i++ )); do     # coins tumbling into the slot
      ph=$(( (t - AR_DY_TOOK) * 2.4 - i * 0.13 ))
      (( ph > 0.0 && ph < 1.0 )) && { cmix $AMBER $WHITE $(( 1.0 - ph )); a_text $(( AR_W / 2 - 14 + i * 3 )) $(( 8 + oy + int(ph * 5) )) '◆' $CM $GLASS; }
    done
    cmix $LIME $WHITE 0.35; a_center $(( 8 + oy )) COLLECTED $CM $GLASS
    shown=$(( AR_DY_BEFORE + int(AR_DY_GOT * k) )); (( shown > AR_MAX_COINS )) && shown=$AR_MAX_COINS
    ar_pad $shown 4; if (( k < 1.0 )); then c=$WHITE; else cmix $LIME $WHITE 0.3; c=$CM; fi
    a_center $(( 12 + oy )) "COIN BANK  $REPLY" $c $GLASS
    (( k >= 1.0 )) && a_center $(( 14 + oy )) "come back tomorrow if you drop below $AR_DAILY_MIN" $AR_LO $GLASS
    (( t - AR_DY_TOOK > 3.2 )) && ar_go menu
  fi
  a_center $(( AR_H - 2 )) "one top-up per day, only while you hold under $AR_DAILY_MIN coins" $AR_LO $GLASS
  return 0 }
ar_daily_key() {
  if (( AR_DY_TOOK < 0.0 )); then
    case "$1" in
      enter|' '|space|t|T|1) local -i b=${AR[credits]:-0}; ar_claim_daily; AR_DY_GOT=$(( ${AR[credits]:-0} - b )); AR_DY_TOOK=$AR_T
                             ar_flash; ar_snd coin; ar_badges_check ;;
      esc|q|Q|back) ar_snd move; ar_go menu ;;
      u|U) ar_mute ;;
      *) return 1 ;;
    esac
  else (( AR_T - AR_DY_TOOK > 1.0 )) && ar_go menu; fi
  return 0 }

# ── THE WALL, TELLING YOU WHILE YOU ARE STILL PLAYING ─────────────────────
# A trophy you only hear about on the payout screen is one you hear about
# after the moment that earned it.  These slide in over whatever the CRT is
# showing, hold, and go: the menu, the shop, the middle of a round alike.
# The payout window is its own announcement, and so is the ledger, and so is
# the rung chooser whose right side they would cover.
typeset -ga AR_TQ                     # "badge-index:when" · the six most recent
typeset -gF AR_TOAST_IN=0.30 AR_TOAST_HOLD=2.9 AR_TOAST_OUT=0.50
# A PAGE WITH A HEADLINE SAYS WHERE IT STARTS · the ranked card stands in the
# middle of the tube, and on a short glass a second trophy would slide in over
# 'RANKED IN'.  The page sets the floor each frame; a card that would cross it
# waits, its clock held, and slides in when the one above it has gone.
typeset -gi AR_TOAST_FLOOR=0
ar_toast_add() { AR_TQ+=("$1:$AR_T"); (( ${#AR_TQ[@]} > 6 )) && AR_TQ=("${AR_TQ[@]: -6}"); return 0 }
ar_toast_paint() {
  (( ${#AR_TQ[@]} )) || return 0
  case "$AR_VIEW" in payout|ledger|diff) return 0 ;; esac
  local -F span=$(( AR_TOAST_IN + AR_TOAST_HOLD + AR_TOAST_OUT )) age k t=$AR_T
  local -a keep; local e s; local -i i j shown=0 x y w bi acc bg bd floor=$AR_H
  (( AR_TOAST_FLOOR > 0 && AR_TOAST_FLOOR < AR_H )) && floor=$AR_TOAST_FLOOR
  # THE CARD KEEPS ITS SHARE OF THE TUBE · thirty-four of arcade.py's seventy-two,
  # so a wider CRT slides in a wider card and more of the name and the blurb are read
  w=$(( AR_W * 34 / AR_OW )); (( w < 34 )) && w=34; (( w > AR_W - 2 )) && w=$(( AR_W - 2 ))
  keep=(); for e in "${AR_TQ[@]}"; do (( t - ${e#*:} < span )) && keep+=("$e"); done
  AR_TQ=("${keep[@]}")
  for (( i = 0; i < ${#AR_TQ[@]}; i++ )); do
    (( shown >= 3 )) && break
    e=${AR_TQ[$i]}
    if (( 1 + shown * 4 + 4 > floor )); then   # no room above the page's headline · the rest wait their turn
      for (( j = i; j < ${#AR_TQ[@]}; j++ )); do AR_TQ[$j]="${AR_TQ[$j]%%:*}:$t"; done
      break
    fi
    bi=${e%%:*}; age=$(( t - ${e#*:} ))
    k=$(( age / AR_TOAST_IN )); (( k > 1.0 )) && k=1.0
    (( age > AR_TOAST_IN + AR_TOAST_HOLD )) && { k=$(( 1.0 - (age - AR_TOAST_IN - AR_TOAST_HOLD) / AR_TOAST_OUT )); (( k < 0.0 )) && k=0.0; }
    (( k <= 0.02 )) && { shown=$(( shown + 1 )); continue; }
    k=$(( k * k * (3.0 - 2.0 * k) ))            # ease in, and back out
    x=$(( int(AR_W - 1 - w * k) )); y=$(( 1 + shown * 4 ))
    (( y + 4 > AR_H )) && break
    acc=${AR_RARC[${BW_RAR[$bi]}]:-$GREY}
    cmix $BLACK $acc 0.17; bg=$CM; cmix $acc $WHITE 0.35; bd=$CM
    a_box $x $y $w 4 $bd $bg double 1
    s="✦ ${BW_RAR[$bi]:u}"; cmix $acc $WHITE 0.5; a_text $(( x + 2 )) $y "${s[0,$(( w - 5 ))]}" $CM $bg
    s="${BW_NAME[$bi]}"; a_text $(( x + 2 )) $(( y + 1 )) "${s[0,$(( w - 13 ))]}" $WHITE $bg
    (( BW_COINS[bi] )) && { s="+${BW_COINS[$bi]} ◉"; cmix $AMBER $WHITE 0.25; a_text $(( x + w - 2 - ${#s} )) $(( y + 1 )) "$s" $CM $bg; }
    s="${BW_BLURB[$bi]}"; cshade $GREY 1.15; a_text $(( x + 2 )) $(( y + 2 )) "${s[0,$(( w - 5 ))]}" $CS $bg
    shown=$(( shown + 1 ))
  done
  return 0 }
# THE FACTORY TABLES · the five names on every rung of every machine before anyone
# has played it, exactly as arcade.py deals them (its own Mersenne twister, seeded
# from the table's name) · generated by gen_seed_tables, not typed.  A table is
# only ever read from here once; after that it lives in the save.
typeset -gA AR_SEEDT
AR_SEEDT[snake.rookie]='TMB:24270 JET:18450 SUE:16130 ORB:14590 LIZ:11420'
AR_SEEDT[snake.normal]='TRN:19080 VIC:16590 VIC:14050 XYZ:11810 TRN:10440'
AR_SEEDT[snake.expert]='DJG:15470 ORB:11610 DJG:10570 TRN:8720 PXL:7740'
AR_SEEDT[snake.insane]='MEG:11340 ZED:8230 AAA:7090 MEG:6300 AAA:5580'
AR_SEEDT[blockfall.rookie]='RGB:826000 DAN:630000 RGB:538000 DAN:440000 RAY:382000'
AR_SEEDT[blockfall.normal]='CRT:642000 CRT:557000 AMY:463000 IVY:433000 AMY:391000'
AR_SEEDT[blockfall.expert]='IVY:545000 RAD:412000 JOE:369000 IVY:336000 MO:267000'
AR_SEEDT[blockfall.insane]='AAA:379100 AAA:300500 LUX:254000 SYN:239600 LUX:208900'
AR_SEEDT[voidpong.rookie]='MO:10300 MO:8690 SYN:8200 SYN:7070 XYZ:6300'
AR_SEEDT[voidpong.normal]='LIZ:7640 ORB:5390 LIZ:4590 ORB:3990 PAT:3380'
AR_SEEDT[voidpong.expert]='LUX:6090 RAY:5060 RGB:4270 LUX:3760 RGB:3170'
AR_SEEDT[voidpong.insane]='SUE:4580 SUE:3400 XYZ:3100 HAL:2690 MO:2460'
AR_SEEDT[bricknova.rookie]='HAL:66800 MEG:54300 XYZ:46300 JMP:41800 JMP:38800'
AR_SEEDT[bricknova.normal]='PXL:51800 PXL:44500 PAT:39900 PAT:33300 DAN:28700'
AR_SEEDT[bricknova.expert]='ZAP:46530 ZAP:33500 KAT:31580 KAT:28750 ZAP:25510'
AR_SEEDT[bricknova.insane]='BOB:34400 BOB:25920 RJM:24340 TRN:21020 SLK:16720'
AR_SEEDT[starraid.rookie]='MO:721000 ZED:598000 AAA:500000 808:436000 AAA:358000'
AR_SEEDT[starraid.normal]='808:554000 808:436000 808:365000 WVE:296000 ZED:266000'
AR_SEEDT[starraid.expert]='ACE:471000 ACE:399500 MAX:356500 MAX:320800 CRT:285800'
AR_SEEDT[starraid.insane]='ZED:349800 ZED:290900 GUS:275100 NVA:241300 AMY:192000'
AR_SEEDT[gridrunner.rookie]='MEG:21380 ACE:18610 MEG:17420 ACE:16520 ZED:15190'
AR_SEEDT[gridrunner.normal]='MAX:16460 DAN:13190 MAX:12090 DAN:10650 RAY:9070'
AR_SEEDT[gridrunner.expert]='DAN:13440 DAN:10970 DAN:9580 BOB:8490 BOB:7740'
AR_SEEDT[gridrunner.insane]='ZAP:10220 ZAP:8290 RGB:7230 JET:6280 PXL:5060'
AR_SEEDT[laserdodge.rookie]='KC:243300 PAT:200400 PAT:166700 RAY:138400 KC:126200'
AR_SEEDT[laserdodge.normal]='VIC:179600 VIC:151100 JP:138800 JP:128700 ZAP:102500'
AR_SEEDT[laserdodge.expert]='VIC:140000 VIC:121400 ACE:101900 RAD:90200 TRN:74200'
AR_SEEDT[laserdodge.insane]='RAD:108100 RAD:89900 IVY:80000 LUX:74600 LUX:65300'
AR_SEEDT[nightdrive.rookie]='LUX:18390 LUX:13190 AMY:11580 GUS:10470 AMY:9270'
AR_SEEDT[nightdrive.normal]='ZAP:14970 NEO:11590 NEO:10920 ZAP:9550 CRT:7690'
AR_SEEDT[nightdrive.expert]='JOE:13010 MEG:10310 SLK:9240 JOE:7640 KAT:6580'
AR_SEEDT[nightdrive.insane]='MO:8840 MO:7170 TRN:6140 TRN:5080 KC:3950'
AR_SEEDT[lightcycle.rookie]='DRK:57800 DRK:44400 RAY:39800 PAT:33000 ORB:30300'
AR_SEEDT[lightcycle.normal]='JP:43570 LUX:33130 LUX:29070 JP:25480 ZED:19640'
AR_SEEDT[lightcycle.expert]='JMP:35890 GUS:31180 JET:27340 NVA:22150 NVA:19440'
AR_SEEDT[lightcycle.insane]='XYZ:28100 VHS:21530 VHS:19100 JP:17970 VIC:15140'
AR_SEEDT[plasmaball.rookie]='DJG:338200 IVY:282300 RJM:258100 HAL:229100 NEO:208200'
AR_SEEDT[plasmaball.normal]='JMP:254600 DRK:183700 TMB:166400 DRK:146100 TMB:133700'
AR_SEEDT[plasmaball.expert]='DAN:231800 RJM:195500 JP:165100 JP:149100 RJM:136600'
AR_SEEDT[plasmaball.insane]='DRK:159000 SYN:119800 MEG:113600 SYN:95700 BOB:89000'
AR_SEEDT[astrodrift.rookie]='AMY:88600 JP:74300 LIZ:65500 LIZ:56900 JP:49800'
AR_SEEDT[astrodrift.normal]='HAL:67700 HAL:47300 MAX:39500 VIC:33100 TKO:26300'
AR_SEEDT[astrodrift.expert]='MO:62300 BOB:45300 NVA:41600 SUE:35500 CRT:29000'
AR_SEEDT[astrodrift.insane]='DAN:44140 NEO:34920 DAN:31130 TKO:25420 NEO:21430'
AR_SEEDT[beatgrid.rookie]='MAX:860000 WVE:611000 VIC:541000 BOB:483000 ORB:379000'
AR_SEEDT[beatgrid.normal]='RAY:661000 NVA:566000 RAY:503000 NVA:456000 RAD:372000'
AR_SEEDT[beatgrid.expert]='TKO:549000 VHS:484000 TKO:403000 VHS:346000 VHS:280000'
AR_SEEDT[beatgrid.insane]='LUX:376600 ZAP:312500 ZAP:283700 LUX:241300 AAA:207500'
# THE WALL · a hundred and ninety, generated from arcade.py's BADGES in its order · id name blurb coins rarity shelf test
typeset -ga BW_ID BW_NAME BW_BLURB BW_COINS BW_RAR BW_CAT BW_T
BW_ID=(
  snake_chain snake_chain8 snake_creep block_hold block_hold20 block_blind pong_post pong_post20
  brick_multi brick_four brick_creep star_dive star_dive15 grid_prize grid_prize6 grid_ambush
  laser_blink laser_noblink laser_cross drive_nitro drive_nitro6 drive_pass drive_wrong cycle_pillar
  cycle_two pin_nudge pin_save pin_nudge30 pin_nosave astro_jump astro_saucer astro_saucer5
  astro_nojump beat_roll beat_roll12 beat_dark two_up two_up_win snake_long snake_gems
  snake_lvl snake_score block_lines block_lvl block_pieces block_score pong_set pong_rally
  pong_three pong_clean brick_100 brick_lvl brick_200 brick_score star_wave star_kills
  star_saucer star_score grid_eat grid_lvl grid_300 grid_score laser_30 laser_60
  laser_dodge laser_score drive_dist drive_gates drive_top drive_score cycle_round cycle_three
  cycle_derez cycle_score pin_sweep pin_mult pin_lanes pin_score astro_wave astro_rocks
  astro_score beat_chain beat_acc beat_accent beat_score first_coin ten_plays hundred_plays
  five_hundred tried_all own_all rich_1k rich_5k rich_max ranked number_one
  rung_up rung_top boots_10 boots_50 vn_first vn_ten vn_thirty vn_aura
  vn_full vn_legend snake_len40 snake_gem25 snake_hard block_lines60 block_lvl10 block_hard
  pong_rally30 pong_five pong_hard brick_400 brick_lvl6 brick_hard star_wave10 star_300
  star_hard grid_600 grid_lvl6 grid_hard laser_dodge150 laser_cells laser_hard drive_5k
  drive_gates50 drive_hard cycle_six cycle_15 cycle_hard plasma_mult12 plasma_sweep8 plasma_hard
  astro_rocks150 astro_wave10 astro_hard astro_wave3 beat_chain150 beat_perfect beat_hard plays_25
  plays_250 plays_1000 boots_5 boots_100 earned_1k earned_10k own_3 own_6
  own_9 rung_expert_all rung_insane_all seen_half rented daily_first daily_seven tables_10
  tables_24 first_5 first_12 first_all wall_25 wall_60 wall_100 vn_fifty
  vn_hundred vn_hats vn_specs vn_smokes vn_auras vn_rarities vn_all_legend vn_common
  secret_1984 secret_serial secret_midnight secret_420day secret_zero_hard secret_bare secret_ufo secret_broke
  secret_svc secret_konami secret_zero secret_420 secret_late secret_smoke)
BW_NAME=(
  'LINKED' 'UNBROKEN' 'THEY MOVED' 'SET ASIDE' 'THE OTHER HAND'
  'ONE AHEAD' 'OFF THE POST' 'BANK SHOT' 'SPLIT' 'FOUR IN THE AIR'
  'HELD THE LINE' 'PEELED OFF' 'NOTHING GETS THROUGH' 'TOOK THE PRIZE' 'NEVER MISSED ONE'
  'SAW IT COMING' 'GONE' 'NEVER NEEDED IT' 'BOTH RAILS' 'BOTTLED'
  'SIX BOTTLES' 'OVERTAKING' 'WRONG SIDE' 'THROUGH THE COLUMNS' 'SOMEBODY ELSE'\''S WALL'
  'A GENTLE SHOVE' 'SAVED' 'WALKING IT' 'NO NET' 'ELSEWHERE'
  'THE SAUCER' 'THEY KEEP COMING' 'STEADY HANDS' 'ROLLED' 'DRUMMER'
  'PLAYED IT BLIND' 'TWO UP' 'HOUSE RULES' 'LONG PLAYER' 'GEM HOARDER'
  'DATASTREAM' 'FIVE THOUSAND' 'LINE COOK' 'GRAVITY WELL' 'HUNDRED SHAPES'
  'STACKED' 'FIRST SET' 'LONG RALLY' 'STRAIGHT SETS' 'ZERO MERCY'
  'DEMOLITION' 'SECOND WALL' 'NOVA' 'WALL BREAKER' 'HOLD THE LINE'
  'HUNDRED DOWN' 'SAUCER HUNTER' 'FORMATION' 'GRID EATER' 'DAEMON DODGER'
  'CLEAN SWEEP' 'TABLES TURNED' 'THIRTY SECONDS' 'FULL MINUTE' 'UNTOUCHED'
  'REFLEX' 'LONG HAUL' 'THREADED' 'TOP END' 'NIGHT SHIFT'
  'FIRST ROUND' 'ARENA' 'DEREZZED' 'BLUE LINE' 'SWEEPER'
  'MULTIBALL' 'LANE RAT' 'TILT PROOF' 'DEEP FIELD' 'ROCK BREAKER'
  'DRIFTER' 'FIFTY CHAIN' 'ON THE ONE' 'ACCENTED' 'IN TIME'
  'FIRST COIN' 'REGULAR' 'LOCAL' 'FIXTURE' 'TOURIST'
  'PROPRIETOR' 'A THOUSAND' 'FIVE THOUSAND UP' 'COIN DOOR FULL' 'ON THE BOARD'
  'NUMBER ONE' 'HARDER' 'TOP RUNG' 'OPENING TIME' 'KEYHOLDER'
  'DRESSED' 'WARDROBE' 'COLLECTOR' 'WEATHERED' 'FULLY DRESSED'
  'LEGENDARY TASTE' 'FORTY LONG' 'GEM RUN' 'HARD DATASTREAM' 'SIXTY LINES'
  'TERMINAL VELOCITY' 'STACKED HARD' 'IMMOVABLE' 'FIVE SETS' 'NO MERCY EITHER'
  'SUPERNOVA' 'SIXTH WALL' 'HARD LIGHT' 'TENTH WAVE' 'THREE HUNDRED DOWN'
  'HELD THE LINE' 'GRID DEVOURED' 'DEEP MAZE' 'DAEMONS BEHIND YOU' 'UNTOUCHABLE'
  'THREADED THE GRID' 'SIXTY, HARD' 'OVERNIGHT' 'FIFTY CLEAN' 'CHROME AND NERVE'
  'SIX ROUNDS' 'DEREZZ' 'WALL OF LIGHT' 'MULTIBALL' 'TABLE SWEEP'
  'KEPT IT UP' 'BELT CLEARED' 'NO BRAKES' 'MOMENTUM' 'OUT OF THE BELT'
  'UNBROKEN' 'PERFECT PASS' 'ON THE LINE' 'SETTLING IN' 'SEASON TICKET'
  'THE FURNITURE' 'SECOND VISIT' 'THE MANAGEMENT' 'A THOUSAND EARNED' 'TEN THOUSAND EARNED'
  'THREE MACHINES' 'HALF THE FLOOR' 'NINE DOWN' 'EXPERT EVERYWHERE' 'NOTHING LEFT TO OPEN'
  'HALF THE ROW' 'BY THE HOUR' 'TOKEN' 'SEVEN DAYS' 'TEN TABLES'
  'HALF THE BOARD' 'FIVE FIRSTS' 'TWELVE FIRSTS' 'THE WHOLE BOARD' 'TWENTY-FIVE UP'
  'SIXTY UP' 'A HUNDRED UP' 'FIFTY ON THE RAIL' 'A HUNDRED ON THE RAIL' 'EVERY HAT'
  'EVERY PAIR' 'EVERY SMOKE' 'EVERY WEATHER' 'ONE OF EACH KIND' 'DRESSED IN LEGEND'
  'PLAINLY DRESSED' 'NINETEEN EIGHTY-FOUR' 'READ THE PLATE' 'MIDNIGHT SHOW' 'THE TWENTIETH OF APRIL'
  'NOTHING, THE HARD WAY' 'NOTHING TO WEAR' 'TAKE ME WITH YOU' 'DOWN TO NOTHING' 'COIN DOOR'
  'OLD CODE' 'NOTHING AT ALL' 'FOUR TWENTY' 'AFTER HOURS' 'SMOKE BREAK')
BW_BLURB=(
  'a chain of three at the snake' 'a chain of eight -- five is the cap, the other three are pride'
  'a run on a grid where the mines crawl' 'hold a piece back and take it again'
  'twenty holds in one run' 'forty lines on INSANE, where the queue shows you one'
  'come off the centre post' 'twenty off the post in one run'
  'catch the [M] capsule' 'every ball the machine has'
  'two hundred bricks with the wall coming down' 'shoot one out of a dive'
  'fifteen divers in one run' 'one of the two, before it went'
  'six prizes in a single run' 'level three with one cutting ahead of you'
  'blink out of a rail' 'sixty seconds and forty dodges without one blink'
  'ninety seconds where they come in crosses' 'spend a full bottle of nitro'
  'six of them in one drive' 'fifty cars behind you'
  'four gates with traffic coming the other way' 'a round on a floor with pillars on it'
  'derez three riders on the cluttered floor' 'nudge the table and get away with it'
  'a ball back off the drain for nothing' 'thirty nudges and never a tilt'
  'two sweeps on INSANE, where nothing saves you' 'take the jump and live'
  'shoot one down' 'five saucers in one run'
  'wave five without one jump' 'finish a roll'
  'twelve rolls in one set' 'ninety per cent accuracy where the deck goes dark'
  'put a second player on the other side' 'take a set with somebody on the other paddle'
  'twenty segments of snake' 'ten star gems in one run'
  'level five without dying' '5,000 points at the snake'
  'twenty lines cleared' 'level five of block fall'
  'a hundred pieces placed' '50,000 at block fall'
  'take a set off the machine' 'fifteen returns without a miss'
  'three sets in one run' 'eleven points on the board'
  'a hundred bricks down' 'reach level three'
  'two hundred bricks in one run' '20,000 at brick nova'
  'wave five' 'a hundred kills'
  'three of the fast ones' '30,000 at star raider'
  'a hundred and fifty nodes' 'level three of the maze'
  'three hundred nodes in one run' '50,000 at grid runner'
  'half a minute in the beams' 'the whole sixty seconds'
  'fifty beams dodged' '3,000 at laser dodge'
  'two thousand of road' 'twenty gates taken clean'
  'two hundred on the clock' '20,000 at night drive'
  'take a round off the grid' 'three rounds in one run'
  'five of them into the wall' '10,000 at light cycle'
  'three sweeps of the table' 'a five times multiplier'
  'eight lanes lit' '50,000 at plasma ball'
  'wave five adrift' 'sixty rocks'
  '25,000 at astro drift' 'fifty notes without a miss'
  'ninety-five per cent accuracy' 'twenty accents caught'
  '30,000 at beat grid' 'you played one'
  'ten runs on the machines' 'a hundred runs'
  'five hundred runs' 'every machine played once'
  'every machine unlocked' 'a thousand coins in the bank'
  'five thousand in the bank' 'the bank will hold no more'
  'a place in a top five' 'first place on any table'
  'a difficulty rung opened' 'the last rung of any machine'
  'ten visits' 'fifty visits'
  'your first vanity item' 'ten items on the rail'
  'thirty items owned' 'an aura of your own'
  'all four slots at once' 'a legendary item bought'
  'forty segments of snake' 'twenty-five gems in one run'
  '3,000 on EXPERT or past it' 'sixty lines in one stack'
  'level ten of block fall' '30,000 on EXPERT or past it'
  'thirty returns without a miss' 'five sets off one machine'
  'two sets on EXPERT or past it' 'four hundred bricks'
  'reach level six' '12,000 on EXPERT or past it'
  'wave ten and still holding' 'three hundred kills'
  'wave six on EXPERT or past it' 'six hundred nodes'
  'level six of the grid' '30,000 on EXPERT or past it'
  'a hundred and fifty beams dodged' 'forty cells crossed'
  'the full minute on EXPERT or past it' 'five thousand of road'
  'fifty gates taken clean' '12,000 on EXPERT or past it'
  'six rounds of the arena' 'fifteen riders boxed in'
  'three rounds on EXPERT or past it' 'a twelve times multiplier'
  'eight sweeps of the table' '300,000 on EXPERT or past it'
  'a hundred and fifty rocks' 'wave ten out there'
  '15,000 on EXPERT or past it' 'wave three out there'
  'a hundred and fifty in the chain' 'a hundred per cent accuracy'
  '20,000 on EXPERT or past it' 'twenty-five runs'
  'two hundred and fifty runs' 'a thousand runs'
  'five visits' 'a hundred visits'
  'a thousand coins won at the machines' 'ten thousand won'
  'three of them yours' 'six machines yours'
  'nine machines yours' 'EXPERT open on every machine'
  'INSANE open on every machine' 'six machines tried'
  'a machine rented rather than bought' 'the daily token claimed'
  'the token claimed seven times' 'a best of your own on ten tables'
  'twenty-four tables with your number on them' 'top of five tables'
  'top of twelve tables' 'top of every table in the house'
  'twenty-five trophies' 'sixty trophies'
  'a hundred trophies on the wall' 'fifty vanity items'
  'a hundred items owned' 'the whole hat rack'
  'the whole eyewear rack' 'the whole smoking rack'
  'the whole aura rack' 'an item of every rarity'
  'four legendaries at once' 'four common items at once'
  'a run worth exactly 1,984' 'exactly 1,138 coins in the bank'
  'playing on the stroke of midnight -- or long enough that it may as well be' 'you know why -- or a run worth exactly 42,000'
  'a run worth zero on INSANE' 'twenty items owned and wearing none of them'
  'the mothership, and weather to go with it' 'the bank at zero'
  'you found the service menu' 'you tried the old code'
  'a run worth zero points' 'exactly 420 coins in the bank'
  'playing at three in the morning -- or three hundred visits, whichever comes first' 'something lit, and an aura going')
BW_COINS=(
  60 220 90 40 170 320 40 150 50 200 340 50 210 50 260 190 40 280 240 50
  230 130 300 60 250 40 60 270 380 50 90 260 300 50 220 340 80 220 40 70
  110 150 60 120 90 200 40 80 160 70 50 110 180 150 90 110 160 190 60 120
  200 170 50 220 100 130 70 100 150 160 50 140 110 130 90 130 80 200 100 90
  170 110 190 90 170 0 30 150 500 250 400 0 0 0 60 200 80 300 20 120
  30 120 350 90 200 260 180 210 260 200 300 280 190 240 250 250 220 260 260 230
  280 240 230 270 210 200 320 200 230 260 220 240 280 240 250 300 230 250 270 70
  250 400 270 60 300 900 10 400 100 450 70 160 280 350 700 60 50 20 180 140
  300 220 420 1000 90 260 600 400 700 500 500 400 500 200 600 120 84 0 0 420
  60 0 150 0 0 0 0 42 0 120)
BW_RAR=(
  uncommon epic uncommon common rare epic common rare common rare
  epic common rare common epic rare common epic rare common
  rare uncommon epic common rare common common epic legendary common
  uncommon epic epic common rare epic uncommon rare common uncommon
  rare rare common uncommon uncommon rare common uncommon rare uncommon
  common uncommon rare rare uncommon uncommon rare rare common uncommon
  rare rare common epic uncommon rare common uncommon rare rare
  common rare uncommon rare uncommon rare uncommon rare uncommon uncommon
  rare uncommon epic uncommon rare common common rare legendary epic
  legendary uncommon rare legendary uncommon epic uncommon epic common rare
  common uncommon epic rare epic epic epic epic epic epic
  epic epic epic epic epic epic epic epic epic epic
  epic epic epic epic epic epic legendary epic epic epic
  epic epic epic epic epic epic epic epic epic common
  epic legendary epic common epic legendary common legendary uncommon legendary
  common uncommon rare epic legendary common common common rare uncommon
  epic rare epic legendary uncommon rare legendary epic legendary legendary
  legendary epic legendary rare legendary uncommon epic epic rare legendary
  rare rare epic common epic rare common rare epic rare)
BW_CAT=(
  snake snake snake blockfall blockfall blockfall voidpong voidpong bricknova bricknova
  bricknova starraid starraid gridrunner gridrunner gridrunner laserdodge laserdodge laserdodge nightdrive
  nightdrive nightdrive nightdrive lightcycle lightcycle plasmaball plasmaball plasmaball plasmaball astrodrift
  astrodrift astrodrift astrodrift beatgrid beatgrid beatgrid meta meta snake snake
  snake snake blockfall blockfall blockfall blockfall voidpong voidpong voidpong voidpong
  bricknova bricknova bricknova bricknova starraid starraid starraid starraid gridrunner gridrunner
  gridrunner gridrunner laserdodge laserdodge laserdodge laserdodge nightdrive nightdrive nightdrive nightdrive
  lightcycle lightcycle lightcycle lightcycle plasmaball plasmaball plasmaball plasmaball astrodrift astrodrift
  astrodrift beatgrid beatgrid beatgrid beatgrid meta meta meta meta meta
  meta meta meta meta meta meta meta meta meta meta
  meta meta meta meta meta meta snake snake snake blockfall
  blockfall blockfall voidpong voidpong voidpong bricknova bricknova bricknova starraid starraid
  starraid gridrunner gridrunner gridrunner laserdodge laserdodge laserdodge nightdrive nightdrive nightdrive
  lightcycle lightcycle lightcycle plasmaball plasmaball plasmaball astrodrift astrodrift astrodrift astrodrift
  beatgrid beatgrid beatgrid meta meta meta meta meta meta meta
  meta meta meta meta meta meta meta meta meta meta
  meta meta meta meta meta meta meta meta meta meta
  meta meta meta meta meta meta secret secret secret secret
  secret secret secret secret secret secret secret secret secret secret)
BW_T=(
  'stat|snake|BEST CHAIN|3' 'stat|snake|BEST CHAIN|8' 'rstat|snake|2|LENGTH|12'
  'stat|blockfall|HELD|2' 'stat|blockfall|HELD|20' 'rstat|blockfall|3|LINES|40'
  'stat|voidpong|POSTS|1' 'stat|voidpong|POSTS|20' 'stat|bricknova|MULTIBALLS|1'
  'stat|bricknova|MOST BALLS|4' 'rstat|bricknova|2|BRICKS|200' 'stat|starraid|DIVERS|1'
  'stat|starraid|DIVERS|15' 'stat|gridrunner|PRIZES|1' 'stat|gridrunner|PRIZES|6'
  'rstat|gridrunner|2|LEVEL|3' 'stat|laserdodge|BLINKS|1' 'x|laser_noblink'
  'rstat|laserdodge|2|SURVIVED|90' 'stat|nightdrive|NITROS|1' 'stat|nightdrive|NITROS|6'
  'stat|nightdrive|PASSED|50' 'rstat|nightdrive|2|GATES|4' 'stat|lightcycle|PILLARS|1'
  'rstat|lightcycle|2|DEREZZED|3' 'stat|plasmaball|NUDGES|1' 'stat|plasmaball|SAVES|1'
  'stat|plasmaball|NUDGES|30' 'rstat|plasmaball|3|SWEEPS|2' 'stat|astrodrift|JUMPS|1'
  'stat|astrodrift|SAUCERS|1' 'stat|astrodrift|SAUCERS|5' 'x|astro_nojump'
  'stat|beatgrid|ROLLS|1' 'stat|beatgrid|ROLLS|12' 'x|beat_dark'
  'x|two_up' 'x|two_up_win' 'stat|snake|LENGTH|20'
  'stat|snake|GEMS|10' 'stat|snake|LEVEL|5' 'score|snake|5000'
  'stat|blockfall|LINES|20' 'stat|blockfall|LEVEL|5' 'stat|blockfall|PIECES|100'
  'score|blockfall|50000' 'stat|voidpong|SETS|1' 'stat|voidpong|BEST RALLY|15'
  'stat|voidpong|SETS|3' 'stat|voidpong|POINTS|11' 'stat|bricknova|BRICKS|100'
  'stat|bricknova|LEVEL|3' 'stat|bricknova|BRICKS|200' 'score|bricknova|20000'
  'stat|starraid|WAVE|5' 'stat|starraid|KILLS|100' 'stat|starraid|SAUCERS|3'
  'score|starraid|30000' 'stat|gridrunner|EATEN|150' 'stat|gridrunner|LEVEL|3'
  'stat|gridrunner|EATEN|300' 'score|gridrunner|50000' 'stat|laserdodge|SURVIVED|30'
  'stat|laserdodge|SURVIVED|60' 'stat|laserdodge|DODGED|50' 'score|laserdodge|3000'
  'stat|nightdrive|DISTANCE|2000' 'stat|nightdrive|GATES|20' 'stat|nightdrive|TOP|200'
  'score|nightdrive|20000' 'stat|lightcycle|ROUNDS|1' 'stat|lightcycle|ROUNDS|3'
  'stat|lightcycle|DEREZZED|5' 'score|lightcycle|10000' 'stat|plasmaball|SWEEPS|3'
  'stat|plasmaball|BEST MULT|5' 'stat|plasmaball|LANES|8' 'score|plasmaball|50000'
  'stat|astrodrift|WAVE|5' 'stat|astrodrift|ROCKS|60' 'score|astrodrift|25000'
  'stat|beatgrid|CHAIN|50' 'stat|beatgrid|ACC|95' 'stat|beatgrid|ACCENTS|20'
  'score|beatgrid|30000' 'x|first_coin' 'x|ten_plays'
  'x|hundred_plays' 'x|five_hundred' 'x|tried_all'
  'x|own_all' 'x|rich_1k' 'x|rich_5k'
  'x|rich_max' 'x|ranked' 'x|number_one'
  'x|rung_up' 'x|rung_top' 'x|boots_10'
  'x|boots_50' 'x|vn_first' 'x|vn_ten'
  'x|vn_thirty' 'x|vn_aura' 'x|vn_full'
  'x|vn_legend' 'stat|snake|LENGTH|40' 'stat|snake|GEMS|25'
  'rscore|snake|2|3000' 'stat|blockfall|LINES|60' 'stat|blockfall|LEVEL|10'
  'rscore|blockfall|2|30000' 'stat|voidpong|BEST RALLY|30' 'stat|voidpong|SETS|5'
  'rstat|voidpong|2|SETS|2' 'stat|bricknova|BRICKS|400' 'stat|bricknova|LEVEL|6'
  'rscore|bricknova|2|12000' 'stat|starraid|WAVE|10' 'stat|starraid|KILLS|300'
  'rstat|starraid|2|WAVE|6' 'stat|gridrunner|EATEN|600' 'stat|gridrunner|LEVEL|6'
  'rscore|gridrunner|2|30000' 'stat|laserdodge|DODGED|150' 'stat|laserdodge|CELLS|40'
  'rstat|laserdodge|2|SURVIVED|60' 'stat|nightdrive|DISTANCE|5000' 'stat|nightdrive|GATES|50'
  'rscore|nightdrive|2|12000' 'stat|lightcycle|ROUNDS|6' 'stat|lightcycle|DEREZZED|15'
  'rstat|lightcycle|2|ROUNDS|3' 'stat|plasmaball|BEST MULT|12' 'stat|plasmaball|SWEEPS|8'
  'rscore|plasmaball|2|300000' 'stat|astrodrift|ROCKS|150' 'stat|astrodrift|WAVE|10'
  'rscore|astrodrift|2|15000' 'stat|astrodrift|WAVE|3' 'stat|beatgrid|CHAIN|150'
  'stat|beatgrid|ACC|100' 'rscore|beatgrid|2|20000' 'x|plays_25'
  'x|plays_250' 'x|plays_1000' 'x|boots_5'
  'x|boots_100' 'x|earned_1k' 'x|earned_10k'
  'x|own_3' 'x|own_6' 'x|own_9'
  'x|rung_expert_all' 'x|rung_insane_all' 'x|seen_half'
  'x|rented' 'x|daily_first' 'x|daily_seven'
  'x|tables_10' 'x|tables_24' 'x|first_5'
  'x|first_12' 'x|first_all' 'x|wall_25'
  'x|wall_60' 'x|wall_100' 'x|vn_fifty'
  'x|vn_hundred' 'x|vn_hats' 'x|vn_specs'
  'x|vn_smokes' 'x|vn_auras' 'x|vn_rarities'
  'x|vn_all_legend' 'x|vn_common' 'x|secret_1984'
  'x|secret_serial' 'x|secret_midnight' 'x|secret_420day'
  'x|secret_zero_hard' 'x|secret_bare' 'x|secret_ufo'
  'x|secret_broke' 'x|secret_svc' 'x|secret_konami'
  'x|secret_zero' 'x|secret_420' 'x|secret_late'
  'x|secret_smoke')
typeset -gi BW_N=190
# ══════════════════════════════════════════════════════════════════════════
# SECTION 21 · T H E   T R O P H Y   R O O M      a hundred and ninety, and the coins follow the ask
# ══════════════════════════════════════════════════════════════════════════
# Every test takes the run that just ended — or none, when the check is
# fired by a purchase or an open — and the save, and must survive both.  A
# test that cannot be answered is a test that failed, never a stopped shell.
#
# THE RUN, as the tests read it.  Set by whoever asks (the payout, and twice
# a second in play), cleared by everyone else.
typeset -gi AR_RUN=0 AR_RDI=0 AR_RSC=0 AR_RPL=1 AR_RRK=99 AR_ROP=-1 AR_RFIN=0 AR_RRDY=0
typeset -g  AR_RG=''
typeset -gA AR_RSTAT                   # the run's stats, as numbers · label → value
typeset -ga AR_BWON                  # what the last check took off the wall, by index
typeset -gF AR_BWON_T=-99.0
typeset -gi AR_SVC_FOUND=0 AR_KONAMI=0
# the aggregates the house's badges read · worked out once a check
typeset -gi BDX_PLAYS BDX_OWNED BDX_SEEN BDX_TABLES BDX_FIRSTS BDX_WALL BDX_VN BDX_RENTED BDX_CAP2 BDX_CAP3 BDX_CAPTOP
typeset -g  BDX_HOUR='' BDX_MD=''

ar_run_stats() {   # AR_SL/AR_SV → AR_RSTAT · THE UNITS ARE STRIPPED · "60s", "1234m", "×3", "42%" are numbers
  local -i i; local v bare
  AR_RSTAT=()
  for (( i = 0; i < ${#AR_SL[@]}; i++ )); do
    v="${AR_SV[$i]:-}"; bare="${v//[^0-9.-]/}"
    [[ "$bare" == (-|)<->(.<->|) || "$bare" == (-|)<->. ]] && AR_RSTAT[${AR_SL[$i]}]="$bare"
  done
  return 0 }
ar_run_set() {   # ar_run_set GI DI SCORE PLAYERS RANK OPENED FINAL · the stats come from AR_SL/AR_SV
  AR_RUN=1; AR_RG="${AR_GID[$1]}"; AR_RDI=$2; AR_RSC=$3; AR_RPL=$4; AR_RRK=$5; AR_ROP=$6; AR_RFIN=$7; AR_RRDY=1
  ar_run_stats; return 0 }
ar_run_clear() { AR_RUN=0; AR_RSTAT=(); return 0 }

bd_stat() { (( AR_RUN )) || return 1; local -F v=${AR_RSTAT[$1]:-0}; (( v >= $2 )) }       # bd_stat LABEL NEED
bd_game() { (( AR_RUN )) && [[ "$AR_RG" == "$1" ]] }
bd_rung() { (( AR_RUN && AR_RDI >= $1 )) }

ar_bdx() {   # the numbers the house keeps, worked out once for the whole check
  local k; local -i i v top
  BDX_PLAYS=0; for k in ${(M)${(k)AR[@]}:#plays.*}; do v=${AR[$k]:-0}; BDX_PLAYS=$(( BDX_PLAYS + v )); done
  ar_nkeys 'seen.*';     BDX_SEEN=$REPLY
  ar_nkeys 'rentals.*';  BDX_RENTED=$REPLY
  ar_nkeys 'badges.*';   BDX_WALL=$REPLY
  ar_nkeys 'wardrobe.*'; BDX_VN=$REPLY
  BDX_OWNED=0; BDX_CAP2=1; BDX_CAP3=1; BDX_CAPTOP=0
  for (( i = 0; i < AR_NG; i++ )); do
    ar_playable $i && BDX_OWNED=$(( BDX_OWNED + 1 ))
    ar_rung_cap $i; (( REPLY >= 2 )) || BDX_CAP2=0; (( REPLY >= 3 )) || BDX_CAP3=0; (( REPLY >= 3 )) && BDX_CAPTOP=1
  done
  BDX_TABLES=0; BDX_FIRSTS=0
  for k in ${(M)${(k)AR[@]}:#best.*}; do
    v=${AR[$k]:-0}; (( v > 0 )) || continue
    BDX_TABLES=$(( BDX_TABLES + 1 ))
    top=${AR[scores.${k#best.}.0.score]:--1}
    (( top >= 0 && v >= top )) && BDX_FIRSTS=$(( BDX_FIRSTS + 1 ))
  done
  strftime -s BDX_HOUR '%H' ${EPOCHSECONDS:-0} 2>/dev/null || BDX_HOUR=''
  strftime -s BDX_MD '%m-%d' ${EPOCHSECONDS:-0} 2>/dev/null || BDX_MD=''
  return 0 }

ar_badge_test() {   # ar_badge_test I → 0 when badge I is earned by what is known now
  local spec="${BW_T[$1]}"; local -a p; p=("${(@s:|:)spec}")
  case "${p[0]}" in
    stat)   bd_game "${p[1]}" && bd_stat "${p[2]}" ${p[3]} ;;
    rstat)  bd_game "${p[1]}" && bd_rung ${p[2]} && bd_stat "${p[3]}" ${p[4]} ;;
    score)  bd_game "${p[1]}" && (( AR_RSC >= ${p[2]} )) ;;
    rscore) bd_game "${p[1]}" && bd_rung ${p[2]} && (( AR_RSC >= ${p[3]} )) ;;
    x)      ar_badge_x "${p[1]}" ;;
    *)      return 1 ;;
  esac }
ar_badge_x() {   # the seventy-three that are not one number against one line of a round
  local -i bank=${AR[credits]:-0} coins=${AR[coins]:-0} boots=${AR[boots]:-0} dailies=${AR[dailies]:-0}
  case "$1" in
    laser_noblink)  bd_game laserdodge && bd_stat SURVIVED 60 && bd_stat DODGED 40 && ! bd_stat BLINKS 1 ;;
    astro_nojump)   bd_game astrodrift && bd_stat WAVE 5 && ! bd_stat JUMPS 1 ;;
    beat_dark)      bd_game beatgrid && bd_rung 2 && bd_stat ACC 90 && bd_stat CHAIN 30 ;;
    two_up)         (( AR_RUN && AR_RPL == 2 )) ;;
    two_up_win)     (( AR_RUN && AR_RPL == 2 )) && bd_game voidpong && bd_stat SETS 1 ;;
    first_coin)     (( BDX_PLAYS >= 1 )) ;;
    ten_plays)      (( BDX_PLAYS >= 10 )) ;;
    plays_25)       (( BDX_PLAYS >= 25 )) ;;
    hundred_plays)  (( BDX_PLAYS >= 100 )) ;;
    plays_250)      (( BDX_PLAYS >= 250 )) ;;
    five_hundred)   (( BDX_PLAYS >= 500 )) ;;
    plays_1000)     (( BDX_PLAYS >= 1000 )) ;;
    tried_all)      (( BDX_SEEN >= AR_NG )) ;;
    seen_half)      (( BDX_SEEN >= 6 )) ;;
    own_all)        (( BDX_OWNED >= AR_NG )) ;;
    own_3)          (( BDX_OWNED >= 3 )) ;;
    own_6)          (( BDX_OWNED >= 6 )) ;;
    own_9)          (( BDX_OWNED >= 9 )) ;;
    rich_1k)        (( bank >= 1000 )) ;;
    rich_5k)        (( bank >= 5000 )) ;;
    rich_max)       (( bank >= AR_MAX_COINS )) ;;
    secret_serial)  (( bank == 1138 )) ;;
    secret_420)     (( bank == 420 )) ;;
    secret_broke)   (( bank == 0 && BDX_PLAYS >= 5 )) ;;
    ranked)         (( AR_RUN && AR_RRK < 5 )) ;;
    number_one)     (( AR_RUN && AR_RRK == 0 )) ;;
    rung_up)        (( AR_RUN && AR_ROP >= 0 )) ;;
    rung_top)       (( BDX_CAPTOP )) ;;
    rung_expert_all) (( BDX_CAP2 )) ;;
    rung_insane_all) (( BDX_CAP3 )) ;;
    boots_5)        (( boots >= 5 )) ;;
    boots_10)       (( boots >= 10 )) ;;
    boots_50)       (( boots >= 50 )) ;;
    boots_100)      (( boots >= 100 )) ;;
    earned_1k)      (( coins >= 1000 )) ;;
    earned_10k)     (( coins >= 10000 )) ;;
    rented)         (( BDX_RENTED > 0 )) ;;
    daily_first)    (( dailies >= 1 )) ;;
    daily_seven)    (( dailies >= 7 )) ;;
    tables_10)      (( BDX_TABLES >= 10 )) ;;
    tables_24)      (( BDX_TABLES >= 24 )) ;;
    first_5)        (( BDX_FIRSTS >= 5 )) ;;
    first_12)       (( BDX_FIRSTS >= 12 )) ;;
    first_all)      (( BDX_FIRSTS >= AR_NG * 4 )) ;;
    wall_25)        (( BDX_WALL >= 25 )) ;;
    wall_60)        (( BDX_WALL >= 60 )) ;;
    wall_100)       (( BDX_WALL >= 100 )) ;;
    vn_first)       (( BDX_VN >= 1 )) ;;
    vn_ten)         (( BDX_VN >= 10 )) ;;
    vn_thirty)      (( BDX_VN >= 30 )) ;;
    vn_fifty)       (( BDX_VN >= 50 )) ;;
    vn_hundred)     (( BDX_VN >= 100 )) ;;
    vn_aura)        ar_nkeys 'wardrobe.aura:*'; (( REPLY > 0 )) ;;
    vn_full)        [[ -n "${AR[worn.hat]:-}" && -n "${AR[worn.spec]:-}" && -n "${AR[worn.smoke]:-}" && -n "${AR[worn.aura]:-}" ]] ;;
    vn_legend)      ar_vn_owned_rar legendary ;;
    vn_hats)        ar_vn_whole_rack hat ;;
    vn_specs)       ar_vn_whole_rack spec ;;
    vn_smokes)      ar_vn_whole_rack smoke ;;
    vn_auras)       ar_vn_whole_rack aura ;;
    vn_rarities)    ar_vn_rarities; (( REPLY >= 6 )) ;;
    vn_all_legend)  ar_vn_worn_rar legendary; (( REPLY >= 4 )) ;;
    vn_common)      ar_vn_worn_rar common; (( REPLY >= 4 )) ;;
    secret_1984)    (( AR_RUN && AR_RSC == 1984 )) ;;
    secret_midnight) [[ "$BDX_HOUR" == 00 ]] || (( BDX_PLAYS >= 500 )) ;;
    secret_420day)  [[ "$BDX_MD" == 04-20 ]] || (( AR_RUN && AR_RSC == 42000 )) ;;
    secret_zero_hard) (( AR_RUN && AR_RSC == 0 && AR_RDI >= 3 && AR_RRDY && AR_RFIN )) ;;
    secret_zero)    (( AR_RUN && AR_RSC == 0 && AR_RRDY && AR_RFIN )) ;;
    secret_bare)    (( BDX_VN >= 20 )) && [[ -z "${AR[worn.hat]:-}${AR[worn.spec]:-}${AR[worn.smoke]:-}${AR[worn.aura]:-}" ]] ;;
    secret_ufo)     [[ "${AR[worn.hat]:-}" == mothership && -n "${AR[worn.aura]:-}" ]] ;;
    secret_smoke)   [[ -n "${AR[worn.smoke]:-}" && -n "${AR[worn.aura]:-}" ]] ;;
    secret_svc)     (( AR_SVC_FOUND )) ;;
    secret_konami)  (( AR_KONAMI )) ;;
    secret_late)    [[ "$BDX_HOUR" == 03 ]] || (( boots >= 300 )) ;;
    *)              return 1 ;;
  esac }

ar_badges_check() {   # everything newly true, paid for and remembered · → AR_BWON
  local -i i n=0 c
  local -a got; got=()
  ar_bdx
  for (( i = 0; i < BW_N; i++ )); do
    [[ -n "${AR[badges.${BW_ID[$i]}]:-}" ]] && continue
    ar_badge_test $i 2>/dev/null || continue
    AR[badges.${BW_ID[$i]}]=${EPOCHSECONDS:-0}; BDX_WALL=$(( BDX_WALL + 1 ))
    c=${BW_COINS[$i]}
    (( c > 0 )) && { AR[credits]=$(( ${AR[credits]:-0} + c )); (( ${AR[credits]} > AR_MAX_COINS )) && AR[credits]=$AR_MAX_COINS; }
    got+=($i)
  done
  if (( ${#got[@]} )); then
    AR_DIRTY=1; ar_save_write
    AR_BWON=("${got[@]}"); AR_BWON_T=$AR_T
    ar_snd coin
    for i in "${got[@]}"; do ar_toast_add $i; done
  fi
  REPLY=${#got[@]}
  return 0 }

# the wardrobe's questions, answered once the racks are on the machine (stage 4 fills these in)
typeset -gi AR_VN_OK=0
(( ${+functions[ar_vn_owned_rar]} ))  || ar_vn_owned_rar()  { return 1 }
(( ${+functions[ar_vn_whole_rack]} )) || ar_vn_whole_rack() { return 1 }
(( ${+functions[ar_vn_rarities]} ))   || ar_vn_rarities()   { REPLY=0; return 0 }
(( ${+functions[ar_vn_worn_rar]} ))   || ar_vn_worn_rar()   { REPLY=0; return 0 }

# ── THE ROOM · shelves across the top, the wall down the left, the plaque on the right ──
typeset -ga BW_CATK BW_CATL; BW_CATK=(all earned locked games meta secret); BW_CATL=(ALL EARNED LOCKED GAMES 'THE HOUSE' SECRET)
typeset -gi AR_BD_CAT=0 AR_BD_SEL=0 AR_BD_SCROLL=0
typeset -ga AR_BD_RACK
ar_bd_rack() {   # ar_bd_rack SHELF → AR_BD_RACK indices
  local -i i; local k="$1"
  AR_BD_RACK=()
  for (( i = 0; i < BW_N; i++ )); do
    case "$k" in
      all)    AR_BD_RACK+=($i) ;;
      earned) [[ -n "${AR[badges.${BW_ID[$i]}]:-}" ]] && AR_BD_RACK+=($i) ;;
      locked) [[ -z "${AR[badges.${BW_ID[$i]}]:-}" ]] && AR_BD_RACK+=($i) ;;
      games)  [[ "${BW_CAT[$i]}" != meta && "${BW_CAT[$i]}" != secret ]] && AR_BD_RACK+=($i) ;;
      *)      [[ "${BW_CAT[$i]}" == "$k" ]] && AR_BD_RACK+=($i) ;;
    esac
  done
  return 0 }
typeset -gi BW_NGAMES=-1 BW_NMETA=0 BW_NSECRET=0
ar_bd_counts() {   # the shelves that never change size, counted once
  (( BW_NGAMES >= 0 )) && return 0
  local -i i; BW_NGAMES=0
  for (( i = 0; i < BW_N; i++ )); do
    case "${BW_CAT[$i]}" in meta) BW_NMETA=$(( BW_NMETA + 1 )) ;; secret) BW_NSECRET=$(( BW_NSECRET + 1 )) ;; *) BW_NGAMES=$(( BW_NGAMES + 1 )) ;; esac
  done; return 0 }
ar_open_badges() { AR_BD_SEL=0; AR_BD_SCROLL=0; ar_snd select; ar_go badges; return 0 }
ar_draw_badges() {
  local -F t=$AR_T; local -i i n idx y hot mine acc tc have=0 paid=0 px pw py ph pb bi c rows top nw nl rl yb yc; local s where stamp
  local -a tabs
  # the wall runs down the menu's side of the split to the footer, the plaque takes the
  # rest of the glass · AR_RM_*, worked out this frame
  ar_room_geom; rows=$AR_RM_ROWS; top=$AR_RM_TOP; px=$AR_RM_PX; pw=$AR_RM_PW; py=$AR_RM_PY; ph=$AR_RM_PH
  for (( i = 0; i < BW_N; i++ )); do [[ -n "${AR[badges.${BW_ID[$i]}]:-}" ]] && { have=$(( have + 1 )); paid=$(( paid + BW_COINS[i] )); }; done
  ar_room_head '✦ TROPHY ROOM' $MAGENTA "$have OF $BW_N EARNED" "PAID $paid ◉"
  ar_bd_counts
  tabs=("ALL:$BW_N" "EARNED:$have" "LOCKED:$(( BW_N - have ))" "GAMES:$BW_NGAMES" "THE HOUSE:$BW_NMETA" "SECRET:$BW_NSECRET")
  ar_catrow 1 1 $(( AR_W - 2 )) $AR_BD_CAT $GLASS $MAGENTA "${tabs[@]}"
  ar_bd_rack ${BW_CATK[$AR_BD_CAT]}; n=${#AR_BD_RACK[@]}
  (( AR_BD_SEL > n - 1 )) && AR_BD_SEL=$(( n > 0 ? n - 1 : 0 ))
  ar_scroll_fit $AR_BD_SEL $AR_BD_SCROLL $rows $n; AR_BD_SCROLL=$REPLY
  nw=$(( AR_LIST_W - 21 )); (( nw < 20 )) && nw=20      # arcade.py's twenty on its forty-one · a wider wall cuts no name
  for (( i = 0; i < rows; i++ )); do
    idx=$(( AR_BD_SCROLL + i )); (( idx >= n )) && break
    bi=${AR_BD_RACK[$idx]}; y=$(( top + i )); hot=$(( idx == AR_BD_SEL ))
    [[ -n "${AR[badges.${BW_ID[$bi]}]:-}" ]] && mine=1 || mine=0
    acc=${AR_RARC[${BW_RAR[$bi]}]:-$GREY}
    if (( hot )); then ar_hotrow $y $acc 0.28; tc=$WHITE
    elif (( mine )); then cshade $GREY 1.05; tc=$CS; else tc=$AR_LO; fi
    if (( mine )); then a_put 4 $y '✦' $acc -2; else a_put 4 $y '·' $AR_LO -2; fi
    if [[ "${BW_CAT[$bi]}" == secret ]] && (( ! mine )); then s='? ? ?'; else s="${BW_NAME[$bi]}"; fi
    a_text 6 $y "${s[0,$(( nw - 1 ))]}" $tc -2
    if (( mine )); then cshade $LIME $(( hot ? 0.9 : 0.65 )); a_text $(( AR_LIST_W - 8 )) $y EARNED $CS -2
    elif (( BW_COINS[bi] )); then s="${BW_COINS[$bi]} ◉"; cshade $AMBER 0.75; a_text $(( AR_LIST_W - 2 - ${#s} )) $y "$s" $CS -2; fi
  done
  ar_list_frame $AR_BD_SCROLL $rows $n $top
  # THE PLAQUE, ON WHATEVER BOX THE SPLIT LEAVES · the name, its rarity and what it asks
  # at the top, the day it was taken on the bottom row but two, where arcade.py kept
  # them, and where it lives and what it pays in the middle of what is left between ·
  # the ask wrapped to the plaque's own width, so a wider one reads it whole
  cmix $GLASS $PURPLE 0.13; pb=$CM
  cshade $PURPLE 0.85; a_box $px $py $pw $ph $CS $pb round 1
  if (( n )); then
    bi=${AR_BD_RACK[$AR_BD_SEL]}
    [[ -n "${AR[badges.${BW_ID[$bi]}]:-}" ]] && mine=1 || mine=0
    local -i hide=0; [[ "${BW_CAT[$bi]}" == secret ]] && (( ! mine )) && hide=1
    acc=${AR_RARC[${BW_RAR[$bi]}]:-$GREY}
    if (( mine )); then s=' EARNED '; cmix $LIME $WHITE 0.25; elif (( hide )); then s=' SECRET '; cmix $GREY $WHITE 0.25; else s=' LOCKED '; cmix $GREY $WHITE 0.25; fi
    a_text $(( px + (pw - ${#s}) / 2 )) $py "$s" $CM $pb
    if (( hide )); then s='? ? ?'; else s="${BW_NAME[$bi]}"; fi
    cmix $WHITE $acc 0.3; a_text $(( px + 2 )) $(( py + 2 )) "${s[0,$(( pw - 5 ))]}" $CM $pb
    cshade $acc 0.9; if (( hide )); then a_text $(( px + 2 )) $(( py + 3 )) unknown $CS $pb; else a_text $(( px + 2 )) $(( py + 3 )) "${BW_RAR[$bi]}" $CS $pb; fi
    # the ask · as many lines as it takes at this width, and room kept for the longest
    # (eighty-one letters: three lines on a plaque under fifty-three wide, two on one over)
    if (( hide )); then ar_wrap 'one of the machines is keeping this one to itself' $(( pw - 4 )) 4; else ar_wrap "${BW_BLURB[$bi]}" $(( pw - 4 )) 4; fi
    if (( pw - 4 >= 53 )); then rl=2; else rl=3; fi
    yb=$(( py + ph - 3 ))
    yc=$(( py + 5 + rl + (yb - py - 5 - rl - 2) / 2 )); (( yc < py + 6 + rl )) && yc=$(( py + 6 + rl ))
    cshade $GREY 1.05
    for (( i = 0; i < 4 && py + 5 + i < yc - 1; i++ )); do [[ -n "${AR_WL[$i]}" ]] && a_text $(( px + 2 )) $(( py + 5 + i )) "${AR_WL[$i]}" $CS $pb; done
    where='THE HOUSE'
    if [[ "${BW_CAT[$bi]}" == secret ]]; then where=SECRET
    else for (( i = 0; i < AR_NG; i++ )); do [[ "${AR_GID[$i]}" == "${BW_CAT[$bi]}" ]] && where="${AR_GTITLE[$i]}"; done; fi
    a_text $(( px + 2 )) $yc WHERE $AR_LOP $pb; cshade $CYAN 0.95; a_text $(( px + 10 )) $yc "${where[0,$(( pw - 13 ))]}" $CS $pb
    a_text $(( px + 2 )) $(( yc + 1 )) PAYS $AR_LOP $pb
    if (( BW_COINS[bi] )); then a_text $(( px + 10 )) $(( yc + 1 )) "${BW_COINS[$bi]} ◉" $AMBER $pb; else a_text $(( px + 10 )) $(( yc + 1 )) 'nothing at all' $AR_LOP $pb; fi
    if (( mine )); then
      strftime -s stamp '%d %b %Y' ${AR[badges.${BW_ID[$bi]}]:-0} 2>/dev/null || stamp='some time ago'
      a_text $(( px + 2 )) $yb TAKEN $AR_LOP $pb; cshade $LIME 0.8; a_text $(( px + 10 )) $yb "$stamp" $CS $pb
    fi
  else
    a_center $(( py + ph / 2 - 1 )) 'NOTHING ON THIS SHELF' $AR_LOP $pb $px $pw
  fi
  cshade $PURPLE 0.75; a_hline 0 $AR_RM_FY $AR_W '─' $CS
  cshade $GREY 1.0; a_center $AR_RM_MY 'some of them pay coins  ·  some of them are just for the look of it' $CS $GLASS
  return 0 }
ar_badges_key() {
  local -i n pg=$AR_RM_ROWS          # a page is what the wall showed last frame
  ar_bd_rack ${BW_CATK[$AR_BD_CAT]}; n=${#AR_BD_RACK[@]}; (( n < 1 )) && n=1
  case "$1" in
    up)    AR_BD_SEL=$(( (AR_BD_SEL + n - 1) % n )); ar_snd move ;;
    down)  AR_BD_SEL=$(( (AR_BD_SEL + 1) % n )); ar_snd move ;;
    left|'['|',')  AR_BD_CAT=$(( (AR_BD_CAT + ${#BW_CATK[@]} - 1) % ${#BW_CATK[@]} )); AR_BD_SEL=0; AR_BD_SCROLL=0; ar_snd move ;;
    right|']'|'.') AR_BD_CAT=$(( (AR_BD_CAT + 1) % ${#BW_CATK[@]} )); AR_BD_SEL=0; AR_BD_SCROLL=0; ar_snd move ;;
    pgup)  AR_BD_SEL=$(( AR_BD_SEL > pg - 1 ? AR_BD_SEL - pg : 0 )); ar_snd move ;;
    pgdn)  AR_BD_SEL=$(( AR_BD_SEL + pg < n ? AR_BD_SEL + pg : n - 1 )); ar_snd move ;;
    esc|back|b|B|a|A) ar_snd move; ar_go menu ;;
    u|U)   ar_mute ;;
    *) return 1 ;;
  esac
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 13 · THE MARKETPLACE      buy a machine outright, rent one by the meter, dress the visitor
# ══════════════════════════════════════════════════════════════════════════
# Racks, cycled with ◂ ▸ rather than poured into one list: the games, and —
# once the wardrobe is on the machine — hats, glasses, smokes and auras.  A
# rental pays exactly what owning pays; only the meter differs.
typeset -gi AR_MK_CAT=0 AR_MK_SCROLL=0 AR_MK_NOPEN=0
typeset -gA AR_MK_SEL
typeset -g  AR_MK_NOTE=''
typeset -gF AR_MK_NOTE_T=-99.0
typeset -ga AR_MK_KEYS AR_MK_LABS
ar_mk_cats() {   # → AR_MK_KEYS / AR_MK_LABS · the games always, the four racks when they are here
  AR_MK_KEYS=(games); AR_MK_LABS=(GAMES)
  if (( AR_VN_OK )); then AR_MK_KEYS+=(hat spec smoke aura); AR_MK_LABS+=(HATS GLASSES SMOKES AURAS); fi
  return 0 }
ar_mk_n() { if [[ "$1" == games ]]; then REPLY=$AR_NG; else ar_vn_rack_n "$1"; fi; return 0 }
ar_open_market() {
  ar_mk_cats
  (( AR_MK_CAT >= ${#AR_MK_KEYS[@]} )) && AR_MK_CAT=0
  ar_item $AR_SEL; [[ $REPLY == g ]] && (( AR_MK_CAT == 0 )) && AR_MK_SEL[games]=$AR_IG
  AR_MK_SCROLL=0; AR_MK_NOTE=''; ar_snd select; ar_go market
  return 0 }
ar_count_open() { local -i i; AR_NOPEN=0; for (( i = 0; i < AR_NG; i++ )); do ar_playable $i && AR_NOPEN=$(( AR_NOPEN + 1 )); done; return 0 }
ar_mk_note() { AR_MK_NOTE="$1"; AR_MK_NOTE_T=$AR_T; return 0 }
ar_mk_carry() { local k=${AR_MK_KEYS[$AR_MK_CAT]}; ar_mk_n $k; (( $1 < REPLY )) && AR_MK_SEL[$k]=$1 || AR_MK_SEL[$k]=$(( REPLY > 0 ? REPLY - 1 : 0 )); return 0 }

ar_draw_market() {
  local -F t=$AR_T; local -i i n idx y hot sel acc tc x c rows top; local key lab s mid
  # the rack runs down the menu's side of the split as far as the footer, and the
  # panel beside it takes the rest of the glass · AR_RM_*, worked out this frame
  ar_room_geom; rows=$AR_RM_ROWS; top=$AR_RM_TOP
  ar_mk_cats; (( AR_MK_CAT >= ${#AR_MK_KEYS[@]} )) && AR_MK_CAT=0
  key=${AR_MK_KEYS[$AR_MK_CAT]}; lab=${AR_MK_LABS[$AR_MK_CAT]}
  ar_mk_n $key; n=$REPLY
  sel=${AR_MK_SEL[$key]:-0}; (( sel > n - 1 )) && sel=$(( n - 1 )); (( sel < 0 )) && sel=0; AR_MK_SEL[$key]=$sel
  if [[ $key == games ]]; then ar_count_open; mid="$AR_NOPEN OF $AR_NG ARCADES UNLOCKED"
  else ar_vn_have_n $key; mid="$REPLY OF $n $lab OWNED"; fi
  ar_room_head '◈ MARKETPLACE' $LIME "$mid"
  local -a tabs; tabs=()
  for (( i = 0; i < ${#AR_MK_KEYS[@]}; i++ )); do ar_mk_n ${AR_MK_KEYS[$i]}; tabs+=("${AR_MK_LABS[$i]}:$REPLY"); done
  ar_catrow 1 1 $(( AR_W - 2 )) $AR_MK_CAT $GLASS $LIME "${tabs[@]}"
  ar_scroll_fit $sel $AR_MK_SCROLL $rows $n; AR_MK_SCROLL=$REPLY
  # a rack short enough for it gets a row of air under every line, as the menu does
  local -i pitch=1; (( 2 * n - 1 <= rows )) && { pitch=2; AR_MK_SCROLL=0; }
  for (( i = 0; i < rows; i++ )); do
    idx=$(( AR_MK_SCROLL + i )); (( idx >= n )) && break
    y=$(( top + i * pitch )); hot=$(( idx == sel ))
    if [[ $key == games ]]; then
      acc=${AR_GACC[$idx]}
      if (( hot )); then ar_hotrow $y $acc; tc=$WHITE; else cshade $GREY 1.05; tc=$CS; fi
      ar_pad $(( idx + 1 )) 2; a_text 4 $y "$REPLY" $AR_LO -2
      a_text 7 $y "${AR_GTITLE[$idx][0,15]}" $tc -2
      if ar_owns $idx; then cshade $LIME $(( hot ? 0.95 : 0.7 )); a_text 25 $y OWNED $CS -2
      else
        ar_rent_left $idx
        if (( REPLY > 0 )); then ar_dur $REPLY; s="RENTED $REPLY"; cshade $CYAN $(( hot ? 1.0 : 0.75 )); a_text 25 $y "${s[0,14]}" $CS -2
        else
          s="${AR_GPRICE[$idx]} ◉"; if (( hot )); then cmix $AMBER $WHITE 0.3; c=$CM; else cshade $AMBER 0.7; c=$CS; fi
          a_text $(( AR_LIST_W - 2 - ${#s} )) $y "$s" $c -2
          a_text 25 $y LOCKED $AR_LO -2
        fi
      fi
    else
      ar_vn_row $key $idx $y $hot
    fi
  done
  ar_list_frame $AR_MK_SCROLL $rows $n $top
  if [[ $key == games ]]; then ar_mk_panel $sel; else ar_vn_panel $key $sel; fi
  cshade $PURPLE 0.75; a_hline 0 $AR_RM_FY $AR_W '─' $CS
  if (( t - AR_MK_NOTE_T < 2.6 )) && [[ -n "$AR_MK_NOTE" ]]; then cmix $RED $WHITE 0.25; a_center $AR_RM_MY "$AR_MK_NOTE" $CM $GLASS
  elif [[ $key == games ]]; then cshade $GREY 1.0; a_center $AR_RM_MY 'a rental pays exactly what owning pays  ·  only the meter differs' $CS $GLASS
  else ar_vn_footer; fi
  return 0 }

ar_mk_opts() {   # ar_mk_opts GI → AR_OL labels, AR_OC costs, AR_OS seconds · outright, then the rent tiers
  local -i gi=$1 i price=${AR_GPRICE[$1]} cost
  AR_OL=('BUY OUTRIGHT'); AR_OC=($price); AR_OS=(0)
  for (( i = 0; i < ${#AR_RLAB[@]}; i++ )); do
    cost=$(( (price * AR_RNUM[i] + AR_RDEN[i] - 1) / AR_RDEN[i] )); (( cost < AR_RFLOOR[i] )) && cost=${AR_RFLOOR[$i]}
    AR_OL+=("RENT ${AR_RLAB[$i]}"); AR_OC+=($cost); AR_OS+=(${AR_RSEC[$i]})
  done; return 0 }
typeset -ga AR_OL AR_OC AR_OS
ar_mk_panel() {   # the price list for one machine
  # THE TAG, ON WHATEVER BOX THE SPLIT LEAVES · the machine at the top and the
  # rungs and the plays on the bottom rows, where arcade.py kept them, and the
  # prices -- its rows 8..12, three prices, a breath, the meter -- in the middle
  # of what is left between them.  A tag with the room for it also says what the
  # machine is, in the menu's own words for it (its blurb, the one the menu's
  # ticker runs), wrapped under the stars the way the trophy plaque wraps its ask
  local -i gi=$1 px=$AR_RM_PX pw=$AR_RM_PW py=$AR_RM_PY ph=$AR_RM_PH pb i y yb yt rl afford cap plays=0 left; local s pips=''
  cmix $GLASS $PURPLE 0.13; pb=$CM
  cshade $PURPLE 0.85; a_box $px $py $pw $ph $CS $pb round 1
  s=' PRICE LIST '; cmix $LIME $WHITE 0.25; a_text $(( px + (pw - ${#s}) / 2 )) $py "$s" $CM $pb
  cmix $WHITE ${AR_GACC[$gi]} 0.25; a_text $(( px + 2 )) $(( py + 2 )) "${AR_GTITLE[$gi]}" $CM $pb
  a_text $(( px + 2 )) $(( py + 3 )) "${AR_GGENRE[$gi]} · ${AR_GYEAR[$gi]}" $AR_LOP $pb
  ar_stars ${AR_GSTARS[$gi]}; cshade $AMBER 0.8; a_text $(( px + 2 )) $(( py + 4 )) "$REPLY" $CS $pb
  yb=$(( py + ph - 3 )); yt=$(( py + 5 ))
  if (( ph >= 20 )); then                  # the blurb · three lines under fifty-three wide, two over (the longest is eighty-eight)
    if (( pw - 4 >= 53 )); then rl=2; else rl=3; fi
    ar_wrap "${AR_GBLURB[$gi]}" $(( pw - 4 )) $rl
    cshade $GREY 1.05; for (( i = 0; i < rl; i++ )); do [[ -n "${AR_WL[$i]}" ]] && a_text $(( px + 2 )) $(( py + 6 + i )) "${AR_WL[$i]}" $CS $pb; done
    yt=$(( py + 6 + rl ))
  fi
  y=$(( yt + 1 + (yb - yt - 6) / 2 )); (( y < yt + 1 )) && y=$(( yt + 1 ))
  if ar_owns $gi; then
    cmix $LIME $WHITE 0.35; a_text $(( px + 2 )) $y 'IN YOUR ARCADE' $CM $pb
    a_text $(( px + 2 )) $(( y + 1 )) 'nothing left to buy' $AR_LOP $pb
  else
    ar_mk_opts $gi
    for (( i = 0; i < ${#AR_OL[@]}; i++ )); do
      afford=$(( ${AR[credits]:-0} >= AR_OC[i] ))
      if (( afford )); then cshade $GREY 1.05; a_text $(( px + 2 )) $y "${AR_OL[$i][0,17]}" $CS $pb; else a_text $(( px + 2 )) $y "${AR_OL[$i][0,17]}" $AR_LOP $pb; fi
      s="${AR_OC[$i]} ◉"; if (( afford )); then cmix $AMBER $WHITE 0.3; else cshade $RED 0.9; CM=$CS; fi
      a_text $(( px + pw - 2 - ${#s} )) $y "$s" $CM $pb
      y=$(( y + 1 ))
    done
    ar_rent_left $gi; left=$REPLY
    (( left > 0 )) && { ar_dur $left; cmix $CYAN $WHITE 0.3; a_text $(( px + 2 )) $(( y + 1 )) "METER  $REPLY" $CM $pb; }
  fi
  ar_rung_cap $gi; cap=$REPLY
  for (( i = 0; i < 4; i++ )); do (( i <= cap )) && pips+='◆' || pips+='·'; done
  a_text $(( px + 2 )) $yb RUNGS $AR_LOP $pb; cmix $CYAN $WHITE 0.25; a_text $(( px + 10 )) $yb "$pips" $CM $pb
  cshade ${AR_DC[$cap]} 0.95; a_text $(( px + 15 )) $yb "${AR_DN[$cap]}" $CS $pb
  for (( i = 0; i < 4; i++ )); do plays=$(( plays + ${AR[plays.${AR_GID[$gi]}.${AR_DK[$i]}]:-0} )); done
  a_text $(( px + 2 )) $(( yb + 1 )) PLAYED $AR_LOP $pb
  if (( plays == 1 )); then s='1 time'; else s="$plays times"; fi
  cshade $GREY 1.0; a_text $(( px + 10 )) $(( yb + 1 )) "$s" $CS $pb
  return 0 }

ar_market_key() {
  local key n sel; local -i pg=$AR_RM_ROWS          # a page is what the rack showed last frame
  ar_mk_cats; key=${AR_MK_KEYS[$AR_MK_CAT]}; ar_mk_n $key; n=$REPLY; (( n < 1 )) && n=1
  sel=${AR_MK_SEL[$key]:-0}
  case "$1" in
    up)    AR_MK_SEL[$key]=$(( (sel + n - 1) % n )); ar_snd move ;;
    down)  AR_MK_SEL[$key]=$(( (sel + 1) % n )); ar_snd move ;;
    pgup)  AR_MK_SEL[$key]=$(( sel > pg - 1 ? sel - pg : 0 )); ar_snd move ;;
    pgdn)  AR_MK_SEL[$key]=$(( sel + pg < n ? sel + pg : n - 1 )); ar_snd move ;;
    # THE CURSOR KEEPS ITS ROW ACROSS THE RACKS, the way arcade.py's carried its
    # `sel` into the next rack · tab from the third hat and the third pair is up
    left|'['|',')  AR_MK_CAT=$(( (AR_MK_CAT + ${#AR_MK_KEYS[@]} - 1) % ${#AR_MK_KEYS[@]} )); AR_MK_SCROLL=0; ar_mk_carry $sel; ar_snd move ;;
    right|']'|'.') AR_MK_CAT=$(( (AR_MK_CAT + 1) % ${#AR_MK_KEYS[@]} )); AR_MK_SCROLL=0; ar_mk_carry $sel; ar_snd move ;;
    enter|' '|space|1)
      if [[ $key == games ]]; then
        if ar_owns $sel; then ar_mk_note 'THIS ONE IS ALREADY YOURS'; ar_snd error
        else ar_snd select; ar_open_buy $sel market; fi
      else ar_vn_take $key $sel; fi ;;
    r|R)   [[ $key != games ]] && ar_vn_surprise ;;
    u|U)   ar_mute ;;
    esc|back|b|B) ar_snd move; ar_go menu ;;
    *) return 1 ;;
  esac
  return 0 }

# ── THE PURCHASE WINDOW · how will you play ───────────────────────────────
typeset -gi AR_BUY_GI=0 AR_BUY_SEL=0
typeset -g  AR_BUY_FROM='menu' AR_BUY_NOTE=''
typeset -gF AR_BUY_NOTE_T=-99.0
ar_open_buy() {   # ar_open_buy GI FROM · FROM is where a purchase goes on to (menu → its rung page, market → back)
  AR_BUY_GI=$1; AR_BUY_FROM="${2:-menu}"; AR_BUY_SEL=0; AR_BUY_NOTE=''; ar_go buy; return 0 }
ar_draw_buy() {
  local -F t=$AR_T f half; local -i gi=$AR_BUY_GI i y hot afford acc xx c bank=${AR[credits]:-0} oy bw bx k base; local s blurb mk
  # A CENTRED WINDOW · the headline and the three choices come down to the middle
  # of a taller tube, and the two lines arcade.py kept on rows 16 / 17 go to the
  # bottom two · the choices' band is arcade.py's sixty-six of seventy-two on the
  # standard glass and stops growing past it, so a wide one is not one long row
  ar_rm_oy; oy=$REPLY
  bw=$(( AR_W - 6 )); (( bw > 98 )) && bw=98; bx=$(( (AR_W - bw) / 2 )); half=$(( bw / 2.0 + 3.0 ))
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  ar_room_head "◈ ${AR_GTITLE[$gi]}" ${AR_GACC[$gi]} '' '' 0.24
  cmix $LIME $WHITE 0.2; a_center $(( 2 + oy )) '╴ ╴ ╴   H O W   W I L L   Y O U   P L A Y   ╴ ╴ ╴' $CM $GLASS
  ar_mk_opts $gi
  for (( i = 0; i < ${#AR_OL[@]}; i++ )); do
    y=$(( 4 + i * 3 + oy )); hot=$(( i == AR_BUY_SEL )); afford=$(( bank >= AR_OC[i] ))
    if (( AR_OS[i] == 0 )); then acc=$LIME; else acc=$CYAN; fi
    if (( hot )) && (( y + 1 < AR_H )); then
      for (( xx = bx; xx < bx + bw; xx++ )); do     # the sweep, two rows of it, straight into the cells
        mk="buy.$acc.$xx.$AR_W"
        if [[ -z "${AR_SWEEP[$mk]:-}" ]]; then
          f=$(( 1.0 - abs(xx - AR_W / 2.0) / half )); (( f < 0.0 )) && f=0.0
          cmix $GLASS $acc $(( 0.06 + 0.22 * f )); AR_SWEEP[$mk]=$CM; cmix $GLASS $acc $(( 0.03 + 0.10 * f )); AR_SWEEP[$mk.2]=$CM
        fi
        k=$(( base + y * TCOLS + xx )); GCH[$k]=' '; GB[$k]=${AR_SWEEP[$mk]}
        k=$(( k + TCOLS )); GCH[$k]=' '; GB[$k]=${AR_SWEEP[$mk.2]}
      done
      cmix $acc $WHITE 0.45; a_put $bx $y '▌' $CM -2
      cmix $WHITE $acc 0.2; a_text $(( bx + 2 )) $y '▶' $CM -2
      cmix $acc $WHITE 0.45; a_text $(( bx + 5 )) $y "${AR_OL[$i]}" $CM -2
    elif (( hot )); then cmix $acc $WHITE 0.45; a_text $(( bx + 5 )) $y "${AR_OL[$i]}" $CM -2
    else cshade $acc 0.8; a_text $(( bx + 5 )) $y "${AR_OL[$i]}" $CS -2; fi
    if (( AR_OC[i] == 1 )); then s='1 COIN'; else s="${AR_OC[$i]} COINS"; fi
    if (( ! afford )); then cshade $RED 0.95; c=$CS; elif (( hot )); then cmix $AMBER $WHITE 0.35; c=$CM; else cshade $AMBER 0.7; c=$CS; fi
    a_text $(( bx + bw - 5 - ${#s} )) $y "$s" $c -2
    if (( AR_OS[i] == 0 )); then blurb='yours for good -- every rung, every payout'
    else
      blurb="full rewards for ${${AR_OL[$i]#RENT }:l} of play, then it locks again"
      ar_rent_left $gi; (( REPLY > 0 )) && { ar_dur $REPLY; blurb="adds to your meter ($REPLY left)"; }
    fi
    if (( hot )); then cshade $GREY 1.05; a_text $(( bx + 5 )) $(( y + 1 )) "$blurb" $CS -2; else a_text $(( bx + 5 )) $(( y + 1 )) "$blurb" $AR_LO -2; fi
  done
  if (( t - AR_BUY_NOTE_T < 2.6 )) && [[ -n "$AR_BUY_NOTE" ]]; then
    ar_wave $t 1.2; if (( WV > 0.35 )); then cmix $RED $WHITE 0.25; else cshade $RED 0.9; CM=$CS; fi; a_center $(( AR_H - 2 )) "$AR_BUY_NOTE" $CM $GLASS
  else a_center $(( AR_H - 2 )) 'renting pays the same coins as owning -- it just runs on a meter' $AR_LO $GLASS; fi
  cshade $GREY 1.0; a_center $(( AR_H - 1 )) 'win coins in the games you already have' $CS $GLASS
  return 0 }
ar_buy_key() {
  local -i n cost have=${AR[credits]:-0} gi=$AR_BUY_GI
  ar_mk_opts $gi; n=${#AR_OL[@]}
  case "$1" in
    up)   AR_BUY_SEL=$(( (AR_BUY_SEL + n - 1) % n )); ar_snd move ;;
    down) AR_BUY_SEL=$(( (AR_BUY_SEL + 1) % n )); ar_snd move ;;
    enter|' '|space|1)
      cost=${AR_OC[$AR_BUY_SEL]}
      if (( have < cost )); then AR_BUY_NOTE="NOT ENOUGH COINS -- YOU NEED $cost"; AR_BUY_NOTE_T=$AR_T; ar_snd error
      else
        local verb=BUY; (( AR_OS[AR_BUY_SEL] )) && verb=RENT
        ar_confirm "$verb" "${AR_OL[$AR_BUY_SEL]}  ${AR_GTITLE[$gi]}?" "${AR_GTITLE[$gi]}  ·  $cost coins" "you will have $(( have - cost )) left" \
                   $LIME CONFIRM CANCEL 'COINS WILL BE SPENT' ar_buy_do buy
      fi ;;
    esc|back|q|Q) ar_snd move; ar_go "$AR_BUY_FROM" ;;
    u|U)  ar_mute ;;
    *) return 1 ;;
  esac
  return 0 }
ar_buy_do() {   # [Y] on the gate · the coins go, the machine comes
  local -i gi=$AR_BUY_GI s=$AR_BUY_SEL cost secs base now=${EPOCHSECONDS:-0}
  ar_mk_opts $gi; cost=${AR_OC[$s]}; secs=${AR_OS[$s]}
  ar_spend $cost || { AR_BUY_NOTE="NOT ENOUGH COINS -- YOU NEED $cost"; AR_BUY_NOTE_T=$AR_T; ar_snd error; return 0; }
  if (( secs == 0 )); then AR[owned.${AR_GID[$gi]}]=$now; unset "AR[rentals.${AR_GID[$gi]}]"   # ownership supersedes the meter
  else base=${AR[rentals.${AR_GID[$gi]}]:-0}; (( base < now )) && base=$now; AR[rentals.${AR_GID[$gi]}]=$(( base + secs )); fi
  AR_DIRTY=1; ar_save_write; ar_count_open
  ar_flash; ar_snd start
  ar_badges_check
  if [[ "$AR_BUY_FROM" == market ]]; then ar_go market
  else AR_GI=$gi; ar_rung_cap $gi; AR_DSEL=${AR_CF[difficulty]:-1}; (( AR_DSEL > REPLY )) && AR_DSEL=$REPLY; AR_PLAYERS=1; ar_go diff; fi
  return 0 }

# the wardrobe's hooks · stage 4 replaces these with the racks
(( ${+functions[ar_vn_rack_n]} ))  || ar_vn_rack_n()  { REPLY=0; return 0 }
(( ${+functions[ar_vn_have_n]} ))  || ar_vn_have_n()  { REPLY=0; return 0 }
(( ${+functions[ar_vn_row]} ))     || ar_vn_row()     { return 0 }
(( ${+functions[ar_vn_panel]} ))   || ar_vn_panel()   { return 0 }
(( ${+functions[ar_vn_footer]} ))  || ar_vn_footer()  { return 0 }
(( ${+functions[ar_vn_take]} ))    || ar_vn_take()    { ar_snd error; return 0 }
(( ${+functions[ar_vn_surprise]} )) || ar_vn_surprise() { ar_snd error; return 0 }
(( ${+functions[ar_vn_full_set]} )) || ar_vn_full_set() { return 1 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 14 · THE LEDGER        your own numbers, which the file always knew
# ══════════════════════════════════════════════════════════════════════════
# Every figure on this page was already in the save — runs, coins, visits,
# tables, tokens — and there was nowhere in the cabinet to read any of it
# back.  Two columns of six, then every machine as a bar, tallest where you
# keep going back, and one line naming the one you keep going back to.
ar_open_ledger() { ar_snd select; ar_go ledger; return 0 }
ar_draw_ledger() {
  local -i runs visits owned=0 rungs=0 won=0 paid=0 pct=0 filled=0 stock=0 i j x0 y top=0 bx n h fav=-1 c
  local -i ex cw x1 x2 rp hb sp bw cy yb q r xx kk base
  local -a L1 V1 C1 L2 V2 C2; local s dots='' k
  # THE TWO COLUMNS TAKE THE WIDTH AND THE MACHINES TAKE THE HEIGHT · each column
  # grows by half of every column the glass adds (arcade.py's were 33 of 72), the
  # figures breathe a row apart when the tube is tall, and the row of machines
  # stands up into bars as many rows high as the tube can spare under them
  ex=$(( AR_W - AR_OW ))
  cw=$(( 33 + ex / 2 )); (( cw > 56 )) && cw=56; (( cw > (AR_W - 7) / 2 )) && cw=$(( (AR_W - 7) / 2 ))
  x1=$(( (AR_W - 2 * cw - 3) / 2 )); x2=$(( x1 + cw + 3 ))
  rp=2; (( AR_H >= 34 )) && rp=3
  hb=$(( 1 + (AR_H - AR_OH) / 2 )); (( hb > 10 )) && hb=10
  (( hb > AR_H - 8 - (5 * rp + 2) )) && hb=$(( AR_H - 8 - (5 * rp + 2) )); (( hb < 1 )) && hb=1
  ar_vstack 1 $(( AR_H - 3 )) 1  $(( 5 * rp + 2 )) 1 $hb; cy=${AR_VSY[0]}; yb=$(( AR_VSY[1] + hb - 1 ))
  for (( i = 0; i < cw; i++ )); do dots+='·'; done
  ar_bdx
  runs=$BDX_PLAYS; visits=${AR[boots]:-0}
  for (( i = 0; i < AR_NG; i++ )); do ar_rung_cap $i; (( REPLY > AR_OPEN_RUNGS - 1 )) && rungs=$(( rungs + REPLY - (AR_OPEN_RUNGS - 1) )); done
  for (( i = 0; i < BW_N; i++ )); do [[ -n "${AR[badges.${BW_ID[$i]}]:-}" ]] && { won=$(( won + 1 )); paid=$(( paid + BW_COINS[i] )); }; done
  ar_style_pct; pct=$REPLY; filled=$AR_STYLE_FILLED
  ar_vn_stock; stock=$REPLY
  local pr=S pv=S; (( runs == 1 )) && pr=''; (( visits == 1 )) && pv=''
  ar_room_head '◈ THE LEDGER' $CYAN "$runs RUN$pr OVER $visits VISIT$pv" '' 0.24
  L1=('RUNS' 'COINS EARNED, ALL TOLD' 'IN THE BANK' 'DAILY TOKENS TAKEN' 'MACHINES YOURS' 'RUNGS BOUGHT')
  V1=("$runs" "${AR[coins]:-0}" "${AR[credits]:-0}" "${AR[dailies]:-0}" "$BDX_OWNED of $AR_NG" "$rungs of $(( AR_NG * (4 - AR_OPEN_RUNGS) ))")
  C1=($LIME $AMBER $AMBER $CYAN $LIME $AMBER)
  L2=('TABLES YOU ARE ON' '...AND TOP OF' 'TROPHIES' '...WHICH PAID' 'ON THE RAIL' 'WEARING')
  if (( filled )); then s="$filled of 4  ·  +$pct%"; else s='nothing at all'; fi
  V2=("$BDX_TABLES of $(( AR_NG * 4 ))" "$BDX_FIRSTS" "$won of $BW_N" "$paid" "$BDX_VN of $stock" "$s")
  C2=($CYAN $MAGENTA $MAGENTA $AMBER $PURPLE $PURPLE)
  cshade $DIM 0.9; local -i dc=$CS; cshade $GREY 1.0; local -i lc=$CS
  for (( j = 0; j < 6; j++ )); do
    y=$(( cy + j * rp ))
    s="${V1[$j]}"; s="${s[0,19]}"; a_text $x1 $y "${L1[$j][0,25]}" $lc -2; a_text $(( x1 + cw - ${#s} )) $y "$s" ${C1[$j]} -2; a_text $x1 $(( y + 1 )) "$dots" $dc -2
    s="${V2[$j]}"; s="${s[0,19]}"; a_text $x2 $y "${L2[$j][0,25]}" $lc -2; a_text $(( x2 + cw - ${#s} )) $y "$s" ${C2[$j]} -2; a_text $x2 $(( y + 1 )) "$dots" $dc -2
  done
  # the row of machines, tallest where you keep going back
  local -a per; per=()
  for (( i = 0; i < AR_NG; i++ )); do
    n=0; for (( j = 0; j < 4; j++ )); do n=$(( n + ${AR[plays.${AR_GID[$i]}.${AR_DK[$j]}]:-0} )); done
    per+=($n); (( n > top )) && { top=$n; fav=$i; }
  done
  a_text $x1 $yb 'EVERY MACHINE, BY HOW OFTEN' $lc -2
  # a bar a machine, in quarter rows · arcade.py's one row of ▂ ▄ ▆ █ is the
  # bottom row of it, and a machine only ever played once is still a ▂ ·
  # standing on the caption's row, the machine's number beside its foot
  sp=$(( 3 + ex / 16 ))
  # …but never back over its own caption · on the widest glass the row of
  # twelve would start under 'EVERY MACHINE', so the pitch stops where it fits
  q=$(( (x2 + cw - x1 - 30 - 2) / 11 )); (( sp > q )) && sp=$q; (( sp < 3 )) && sp=3
  bw=1; (( sp >= 5 )) && bw=2
  bx=$(( x2 + cw - 1 - (11 * sp + bw) ))
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  local bars=' ▂▄▆█' hex='123456789ABC' g
  for (( i = 0; i < AR_NG; i++ )); do
    n=${per[$i]}; q=0; x0=$(( bx + i * sp ))
    if (( n && top )); then ar_round $(( (4.0 * hb - 1.0) * n / top )); q=$(( 1 + REPLY )); (( q > 4 * hb )) && q=$(( 4 * hb )); fi
    c=${AR_GACC[$i]}
    for (( r = 0; r * 4 < q; r++ )); do
      if (( q - r * 4 >= 4 )); then g='█'; else g="${bars[$(( q - r * 4 ))]}"; fi
      (( yb - r >= 0 )) || break
      kk=$(( base + (yb - r) * TCOLS + x0 ))
      for (( xx = 0; xx < bw; xx++ )); do GCH[$(( kk + xx ))]="$g"; GF[$(( kk + xx ))]=$c; done
    done
    a_put $(( x0 + bw )) $yb "${hex[$i]}" $AR_LO -2
  done
  cshade $PURPLE 0.75; a_hline 0 $(( AR_H - 2 )) $AR_W '─' $CS
  cshade $GREY 1.0
  if (( fav >= 0 )); then s=s; (( top == 1 )) && s=''; a_center $(( AR_H - 1 )) "the one you keep coming back to  ·  ${AR_GTITLE[$fav]}  ·  $top run$s" $CS $GLASS
  else a_center $(( AR_H - 1 )) 'nothing on it yet  ·  put a coin in something' $CS $GLASS; fi
  return 0 }
ar_ledger_key() {
  case "$1" in
    esc|enter|' '|space|l|L|back) ar_snd select; ar_go menu ;;
    u|U) ar_mute ;;
    *) return 1 ;;
  esac
  return 0 }

# the wardrobe's two numbers the ledger reads · stage 4 answers them properly
typeset -gi AR_STYLE_FILLED=0
(( ${+functions[ar_style_pct]} )) || ar_style_pct() { REPLY=0; AR_STYLE_FILLED=0; return 0 }
(( ${+functions[ar_vn_stock]} ))  || ar_vn_stock()  { REPLY=0; return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 15 · SETTINGS           the cabinet's own switches, and the two operator resets
# ══════════════════════════════════════════════════════════════════════════
# SOUND is the house's switch — the one CONFIG throws on the door — so the
# cabinet flips that one rather than keeping a second.  The tube (scanlines,
# the vignette), the frame rate and the window belong to the house here as
# well, so the rows arcade.py kept for them are CONFIG's, not this page's.
typeset -ga AR_OPT_N AR_OPT_K AR_OPT_D
AR_OPT_N=('SOUND FX' 'ATTRACT MODE' 'FREE PLAY' 'RESET COIN BANK' 'RESET HIGH SCORES' 'SELF TEST' 'BACK TO GAMES')
AR_OPT_K=(sound attract freeplay bank scores test back)
AR_OPT_D=('system beeps for the arcade' \
          'demo reel after 20s idle' \
          'play for nothing -- and earn no coins while it is on' \
          "operator reset -- bank back to $AR_START_COINS, earned total cleared" \
          'erase the hall of fame' \
          'colour bars, input and glyph check' \
          'return to the arcade menu')
typeset -gi AR_OPT_SEL=0
typeset -g  AR_OPT_NOTE=''
ar_open_options() { AR_OPT_SEL=0; AR_OPT_NOTE=''; ar_snd select; ar_go options; return 0 }
ar_opt_on() {   # ar_opt_on KEY → 0 when the switch is on
  case "$1" in
    sound) (( ${CFG_SOUND:-1} )) ;;
    *)     (( ${AR_CF[$1]:-0} )) ;;
  esac }
ar_draw_options() {
  local -F t=$AR_T f nm; local -i i y hot xx on c; local k s mk
  local -i ex pw lx rx ty ly ry gap grp base kk
  ar_room_head '◤ SETTINGS' $CYAN '' 'OPERATOR ACCESS' 0.20
  # THE SWITCHES ARE A PANEL OF THEIR OWN IN THE MIDDLE OF THE TUBE · arcade.py's
  # ran 56 of its 72 columns, and it takes half of every column the glass adds.
  # Its rows keep together by kind -- the three switches, the two resets, the
  # test, the way out -- with a breath between the kinds, and the whole of it,
  # rule and line of help included, stands centred over the note at the bottom
  ex=$(( AR_W - AR_OW ))
  pw=$(( 56 + ex / 2 )); (( pw > 90 )) && pw=90; (( pw > AR_W - 16 )) && pw=$(( AR_W - 16 ))
  lx=$(( (AR_W - pw) / 2 )); rx=$(( lx + pw )); nm=$(( pw / 2.0 + 8.0 ))
  gap=0; (( AR_H >= 22 )) && gap=1
  ar_vstack 1 $(( AR_H - 2 )) 1  1 1 $(( ${#AR_OPT_N[@]} + 3 * gap )) =2 2; ty=${AR_VSY[0]}; ly=${AR_VSY[1]}; ry=${AR_VSY[2]}
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  cmix $CYAN $WHITE 0.2; a_center $ty '◈   C A B I N E T   S E T T I N G S   ◈' $CM $GLASS
  for (( i = 0; i < ${#AR_OPT_N[@]}; i++ )); do
    grp=0; (( i >= 3 )) && grp=1; (( i >= 5 )) && grp=2; (( i >= 6 )) && grp=3
    y=$(( ly + i + gap * grp )); hot=$(( i == AR_OPT_SEL )); k=${AR_OPT_K[$i]}
    if (( hot )); then
      kk=$(( base + y * TCOLS + lx ))
      for (( xx = lx; xx < rx; xx++, kk++ )); do
        mk="opt.$(( xx - lx )).$pw"
        [[ -z "${AR_SWEEP[$mk]:-}" ]] && { f=$(( 1.0 - abs(xx - lx - pw / 2.0) / nm )); cmix $GLASS $CYAN $(( 0.16 * f + 0.05 )); AR_SWEEP[$mk]=$CM; }
        GCH[$kk]=' '; GB[$kk]=${AR_SWEEP[$mk]}
      done
      cmix $WHITE $CYAN 0.2; a_text $lx $y '▶' $CM -2
      a_text $(( lx + 3 )) $y "${AR_OPT_N[$i]}" $WHITE -2
    else cshade $GREY 1.05; a_text $(( lx + 3 )) $y "${AR_OPT_N[$i]}" $CS -2; fi
    case $k in
      sound|attract|freeplay)
        if ar_opt_on $k; then a_text $(( rx - 14 )) $y '[ ON  ]' $LIME -2; a_text $(( rx - 5 )) $y '●' $LIME -2
        else cshade $GREY 0.75; a_text $(( rx - 14 )) $y '[ OFF ]' $CS -2; a_text $(( rx - 5 )) $y '○' $AR_LO -2; fi ;;
      *) if (( hot )); then cmix $AMBER $WHITE 0.2; c=$CM; else cshade $AMBER 0.6; c=$CS; fi
         a_text $(( rx - 14 )) $y '[  ▸  ]' $c -2 ;;
    esac
  done
  cshade $PURPLE 0.5; a_hline $lx $ry $pw '─' $CS
  cshade $GREY 1.05; a_center $(( ry + 1 )) "${AR_OPT_D[$AR_OPT_SEL]}" $CS $GLASS
  if [[ -n "$AR_OPT_NOTE" ]]; then ar_wave $t 1.2; cmix $LIME $WHITE $(( 0.3 * WV )); a_center $(( AR_H - 1 )) "◆ $AR_OPT_NOTE ◆" $CM $GLASS
  else a_center $(( AR_H - 1 )) "terminal.conf  ·  $(( int(${HZ:-60} + 0.5) )) Hz panel  ·  $(( int(AR_FPS + 0.5) )) fps" $AR_LO $GLASS; fi
  return 0 }
ar_options_key() {
  local -i n=${#AR_OPT_N[@]}; local k=${AR_OPT_K[$AR_OPT_SEL]}
  case "$1" in
    up)   AR_OPT_SEL=$(( (AR_OPT_SEL + n - 1) % n )); AR_OPT_NOTE=''; ar_snd move ;;
    down) AR_OPT_SEL=$(( (AR_OPT_SEL + 1) % n )); AR_OPT_NOTE=''; ar_snd move ;;
    enter|' '|space|left|right|a|A|d|D)
      case $k in
        sound)
          CFG_SOUND=$(( 1 - ${CFG_SOUND:-1} ))
          (( ${+functions[cfg_save]} )) && cfg_save
          ar_opt_on sound && AR_OPT_NOTE='SOUND FX IS NOW ON' || AR_OPT_NOTE='SOUND FX IS NOW OFF'; ar_snd select ;;
        attract|freeplay)
          AR_CF[$k]=$(( 1 - ${AR_CF[$k]:-0} )); ar_conf_save
          if ar_opt_on $k; then AR_OPT_NOTE="${AR_OPT_N[$AR_OPT_SEL]} IS NOW ON"; else AR_OPT_NOTE="${AR_OPT_N[$AR_OPT_SEL]} IS NOW OFF"; fi
          ar_snd select ;;
        bank)   ar_opt_bank ;;
        scores) ar_opt_wipe ;;
        test)   ar_snd start; AR_ST_FR=0; AR_ST_HITS=(); ar_go selftest ;;
        back)   ar_snd select; ar_go menu ;;
      esac ;;
    esc|s|S|back) ar_snd select; ar_go menu ;;
    u|U) ar_mute ;;
    *) return 1 ;;
  esac
  return 0 }
ar_opt_bank() {
  local -i have=${AR[credits]:-0} life=${AR[coins]:-0} over; local d2
  ar_pad $have 4; local a="$REPLY"; ar_pad $AR_START_COINS 4
  over=$(( have - AR_START_COINS ))
  if (( over > 0 )); then d2="you would be throwing away $over earned coin"; (( over == 1 )) || d2+=s
  else d2="this tops you back up to $AR_START_COINS"; fi
  ar_confirm RESET 'Reset the coin bank?' "COIN BANK  $a  ▸  $REPLY      EARNED  $life  ▸  0" "$d2" $AMBER RESET KEEP '' ar_opt_bank_do options ar_opt_bank_no
  return 0 }
ar_opt_bank_do() { AR[credits]=$AR_START_COINS; AR[coins]=0; AR_DIRTY=1; ar_save_write; ar_flash 0.6; ar_snd coin
  AR_OPT_NOTE="COIN BANK RESET TO $AR_START_COINS, EARNED CLEARED"; return 0 }
ar_opt_bank_no() { AR_OPT_NOTE='COIN BANK LEFT ALONE'; return 0 }
ar_opt_wipe() {
  local -A tabs; local k me; local -i mine=0 nt
  ar_player_name; me="$REPLY"
  for k in ${(M)${(k)AR[@]}:#scores.*}; do
    tabs[${${k%.*}%.*}]=1
    [[ "$k" == *.name ]] && { ar_scrub "${AR[$k]}"; [[ "$REPLY" == "$me" ]] && mine=$(( mine + 1 )); }
  done
  nt=${#tabs[@]}
  local d1="$nt table" d2; (( nt == 1 )) || d1+=s; d1+=" across $AR_NG arcades and 4 rungs"
  if (( mine )); then d2="$mine of the entries "; (( mine == 1 )) && d2+='is yours' || d2+='are yours'
  else d2='the factory scores come back instead'; fi
  ar_confirm 'ERASE ALL' 'Erase every high score?' "$d1" "$d2" $RED ERASE KEEP '' ar_opt_wipe_do options ar_opt_wipe_no
  return 0 }
ar_opt_wipe_do() {
  local k
  for k in ${(M)${(k)AR[@]}:#scores.*} ${(M)${(k)AR[@]}:#plays.*}; do unset "AR[$k]"; done
  AR_DIRTY=1; ar_save_write; ar_snd error
  AR_OPT_NOTE='ALL HIGH SCORE TABLES ERASED'; return 0 }
ar_opt_wipe_no() { AR_OPT_NOTE='HIGH SCORES KEPT'; return 0 }

# ── SELF TEST · colour bars, the input, the glyphs, the plate ──────────────
typeset -gi AR_ST_FR=0
typeset -ga AR_ST_HITS
ar_plate_no() { local -i n=$(( 1984 - 0x34E )); ar_pad $n 4; return 0 }   # the serial stamped on the plate · 1138
ar_draw_selftest() {
  local -F t=$AR_T; local -i i bw c; local s
  local -i bh dh x0 x1 gy k base; local mk
  local -a bars; bars=($RED $AMBER $LIME $CYAN $BLUE $PURPLE $MAGENTA $WHITE)
  AR_ST_FR=$(( AR_ST_FR + 1 ))
  # THE BARS TAKE THE TUBE · arcade.py's ten rows of bars (seven bright, three
  # dim) become every row but the eight its readout needs, in the same seven to
  # three, and the eight of them split the width to the last column
  bh=$(( (AR_H - 8) * 7 / 10 )); dh=$(( AR_H - 8 - bh )); gy=$(( AR_H - 7 ))
  for (( i = 0; i < 8; i++ )); do
    x0=$(( i * AR_W / 8 )); x1=$(( (i + 1) * AR_W / 8 ))
    cshade ${bars[$i]} 0.85; a_rect $x0 0 $(( x1 - x0 )) $bh ' ' -2 $CS
    cshade ${bars[$i]} 0.45; a_rect $x0 $bh $(( x1 - x0 )) $dh ' ' -2 $CS
  done
  a_center $(( bh * 4 / 7 )) ' ARCADE SELF TEST ' $BLACK $WHITE
  # the grey ramp · its inks worked out once a width, the cells written straight in
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX )); k=$(( base + gy * TCOLS ))
  for (( i = 0; i < AR_W; i++, k++ )); do
    mk="st.$i.$AR_W"
    [[ -z "${AR_SWEEP[$mk]:-}" ]] && { cshade $WHITE $(( i / (AR_W + 0.0) )); AR_SWEEP[$mk]=$CS; }
    GCH[$k]='█'; GF[$k]=${AR_SWEEP[$mk]}; GB[$k]=$GLASS
  done
  ar_plate_no; cshade $GREY 0.9; a_text 2 $(( gy + 1 )) "PLATE   ALIEN DYNAMICS NX-88  ·  SERIAL $REPLY" $CS $GLASS
  cshade $GREY 1.0; a_text 2 $(( gy + 2 )) 'INPUT ' $CS $GLASS
  s="${AR_ST_HITS[*]}"; a_text 9 $(( gy + 2 )) "${s[0,$(( AR_W - 13 ))]}" $LIME $GLASS
  if (( ${TRUE24:-1} )); then s='24-BIT TRUECOLOR'; else s='256 INDEXED'; fi
  a_text 2 $(( gy + 3 )) "COLOUR  $s" $CYAN $GLASS
  a_text 2 $(( gy + 4 )) 'GLYPHS  █ ▓ ▒ ░ ▀ ▄ ▌ ▐ ● ◆ ★ ▲ ▼ ◄ ► ╔ ═ ╗ ║ ╚ ╝' $AMBER $GLASS
  ar_f1 $AR_FPS; ar_lpad "$REPLY" 5; local fps="$REPLY"
  cshade $GREY 1.0; a_text 2 $(( gy + 5 )) "TIMING  $fps FPS  ·  $(( int(${HZ:-60} + 0.5) )) Hz PANEL  ·  frame $AR_ST_FR" $CS $GLASS
  ar_wave $t 0.8; (( WV > 0.4 )) && a_center $(( AR_H - 1 )) '◂ PRESS ANY KEY TO EXIT ▸' $WHITE $GLASS
  return 0 }
ar_selftest_key() {
  AR_ST_HITS+=("${1:u}"); (( ${#AR_ST_HITS[@]} > 8 )) && AR_ST_HITS=("${AR_ST_HITS[@]: -8}")
  (( AR_ST_FR > 6 )) && { ar_snd select; ar_go options; }
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 16 · THE COIN DOOR       a held key, a serial off the plate, and the operator's switches
# ══════════════════════════════════════════════════════════════════════════
# Every NX-88 hid its service switch behind the coin door, and the door
# wanted a key.  Hold [\] on the menu until the door swings open, then punch
# in the serial off the plate — the plate is on the self test, which is
# where an operator would have looked anyway.  A rigged machine pays no
# coins and sets no records; the bookkeeping rows are not switches and do
# not rig it.
typeset -ga AR_SVK AR_SVL AR_SVV AR_SVD AR_SVTIME AR_SVMULT
AR_SVK=(god time mult free rewind auto debug)
AR_SVL=('FREE LIFE' 'TIME DILATION' 'SCORE DIAL' 'FREE CREDITS' 'ROUND REWIND' 'DEMO PLAY' 'DIAGNOSTICS')
AR_SVV=('OFF ON' '×0.25 ×0.5 ×1 ×2 ×4' '×1 ×10 ×100' 'OFF ON' 'OFF ON' 'OFF ON' 'OFF ON')
AR_SVD=(0 2 0 0 0 0 0)
AR_SVTIME=(0.25 0.5 1.0 2.0 4.0); AR_SVMULT=(1 10 100)
ar_svc_i() { local -i i; for (( i = 0; i < ${#AR_SVK[@]}; i++ )); do [[ "${AR_SVK[$i]}" == "$1" ]] && { REPLY=$i; return 0 }; done; REPLY=-1; return 1 }
ar_svc() {   # ar_svc KEY → REPLY the switch's position, clamped · its default when unset
  local -i v; ar_svc_i "$1" || { REPLY=0; return 0 }
  v=${AR[svc.$1]:-${AR_SVD[$REPLY]}}; (( v < 0 )) && v=0; (( v > 8 )) && v=8
  local -a vals; vals=(${=AR_SVV[$REPLY]}); (( v > ${#vals[@]} - 1 )) && v=$(( ${#vals[@]} - 1 ))
  REPLY=$v; return 0 }
ar_rigged() {   # 0 when anything is set away from a straight, honest machine
  local -i i
  for (( i = 0; i < ${#AR_SVK[@]}; i++ )); do ar_svc ${AR_SVK[$i]}; (( REPLY != AR_SVD[i] )) && return 0; done
  return 1 }

# ── the held key · counted in time with the key still arriving, not in frames ──
typeset -gF AR_HOLD_SINCE=-1.0 AR_HOLD_LAST=-99.0 AR_HOLD_NEED=4.0
typeset -gF AR_HOLD_GAP=0.6          # arcade.py waited 0.4 · a Mac's first repeat can take longer than that
ar_hold_feed() { (( AR_T - AR_HOLD_LAST > AR_HOLD_GAP )) && AR_HOLD_SINCE=$AR_T; AR_HOLD_LAST=$AR_T; return 0 }
ar_hold_len() {   # → RF seconds held · 0 when the key has gone quiet
  (( AR_T - AR_HOLD_LAST > AR_HOLD_GAP )) && AR_HOLD_SINCE=-1.0
  if (( AR_HOLD_SINCE < 0.0 )); then RF=0.0; else RF=$(( AR_T - AR_HOLD_SINCE )); fi
  return 0 }
ar_hold_reset() { AR_HOLD_SINCE=-1.0; AR_HOLD_LAST=-99.0; return 0 }

# ── the famous old code · fed one key at a time, swallowing what it is building ──
typeset -ga AR_KONAMI_SEQ; AR_KONAMI_SEQ=(up up down down left right left right b a)
typeset -gi AR_KONAMI_AT=0
typeset -gF AR_SVC_NOTE=-99.0
ar_konami_key() {   # ar_konami_key KEY → REPLY hit | part | ''
  local k="${1:l}"
  if [[ "$k" == "${AR_KONAMI_SEQ[$AR_KONAMI_AT]}" ]]; then
    AR_KONAMI_AT=$(( AR_KONAMI_AT + 1 ))
    if (( AR_KONAMI_AT == ${#AR_KONAMI_SEQ[@]} )); then AR_KONAMI_AT=0; REPLY=hit; else REPLY=part; fi
    return 0
  fi
  AR_KONAMI_AT=0
  [[ "$k" == "${AR_KONAMI_SEQ[0]}" ]] && { AR_KONAMI_AT=1; REPLY=part; return 0 }
  REPLY=''; return 0 }

# ── THE KEYPAD · four digits behind the coin door ─────────────────────────
typeset -g  AR_KP_TYPED=''
typeset -gF AR_KP_WRONG=-99.0
ar_open_keypad() { AR_KP_TYPED=''; AR_KP_WRONG=-99.0; ar_snd start; ar_go keypad; return 0 }
ar_draw_keypad() {
  local -F t=$AR_T; local -i gap x0 i gx c ty dy my; local d
  ar_room_head '◈ SERVICE PANEL' $AMBER '' 'ALIEN DYNAMICS NX-88' 0.26
  # THE SERIAL STANDS IN THE MIDDLE OF THE DOOR · its four slots spread with the
  # width (ten apart on arcade.py's 72, and an eighth of every column added),
  # the title, the slots and the line under them centred over the operator's
  # notice, which keeps its place at the foot of the door
  gap=$(( 10 + (AR_W - AR_OW) / 8 ))
  ar_vstack 1 $(( AR_H - 5 )) $(( 1 + (AR_H - AR_OH) / 16 ))  1 1 6 1 1; ty=${AR_VSY[0]}; dy=${AR_VSY[1]}; my=${AR_VSY[2]}
  cmix $AMBER $WHITE 0.2; a_center $ty '╴ ╴ ╴   C A B I N E T   S E R I A L   ╴ ╴ ╴' $CM $GLASS
  x0=$(( (AR_W - (gap * 3 + 5)) / 2 ))
  for (( i = 0; i < 4; i++ )); do
    gx=$(( x0 + i * gap ))
    if (( i < ${#AR_KP_TYPED} )); then d="${AR_KP_TYPED[$i]}"; cmix $AMBER $WHITE 0.45; a_big "$d" $gx $dy $AMBER $CM
    elif (( i == ${#AR_KP_TYPED} )); then ar_wave $t 1.6; (( WV > 0.4 )) && { cshade $AMBER 0.55; a_text $gx $(( dy + 4 )) '█████' $CS -2; }; fi
    if (( i >= ${#AR_KP_TYPED} )); then cshade $GREY 0.85; else cshade $AMBER 0.7; fi
    a_text $gx $(( dy + 5 )) '▀▀▀▀▀' $CS -2
  done
  if (( t - AR_KP_WRONG < 1.8 )); then
    ar_wave $t 1.4; if (( WV > 0.35 )); then cmix $RED $WHITE 0.3; else cshade $RED 0.9; CM=$CS; fi
    a_center $my 'THAT IS NOT THIS MACHINE' $CM $GLASS
  elif (( t - AR_VIEW_T0 > 6.0 )); then a_center $my 'the serial is stamped on the plate inside' $AR_LO $GLASS; fi
  cshade $AMBER 0.75; a_center $(( AR_H - 3 )) '◈  OPERATOR USE ONLY  ◈' $CS $GLASS
  a_center $(( AR_H - 2 )) 'a rigged machine pays no coins and sets no records' $AR_LO $GLASS
  return 0 }
ar_keypad_key() {
  case "$1" in
    esc|q|Q) ar_snd move; ar_go menu ;;
    back)    AR_KP_TYPED="${AR_KP_TYPED%?}"; ar_snd move ;;
    [0-9])   (( ${#AR_KP_TYPED} < 4 )) || return 0
             AR_KP_TYPED+="$1"; ar_snd move
             if (( ${#AR_KP_TYPED} == 4 )); then
               ar_plate_no
               if [[ "$AR_KP_TYPED" == "$REPLY" ]]; then
                 ar_snd start; ar_flash; AR_SVC_FOUND=1; ar_badges_check; ar_open_service
               else AR_KP_WRONG=$AR_T; AR_KP_TYPED=''; ar_snd error; fi
             fi ;;
  esac
  return 0 }      # the door takes every key while it is open

# ── THE SERVICE PANEL · the bookkeeping, the wardrobe, the machine ────────
typeset -ga AR_SV_KIND AR_SV_KEY AR_SV_LAB AR_SV_VAL
typeset -gi AR_SV_SEL=1 AR_SV_SCROLL=0
typeset -g  AR_SV_NOTE=''
typeset -gF AR_SV_NOTE_T=-99.0
ar_open_service() { AR_SV_SEL=1; AR_SV_SCROLL=0; AR_SV_NOTE=''; ar_go service; return 0 }
ar_sv_row() { AR_SV_KIND+=("$1"); AR_SV_KEY+=("$2"); AR_SV_LAB+=("$3"); AR_SV_VAL+=("$4"); return 0 }
ar_sv_rows() {
  local -i i rungs=0 hv stock; local -a vals one slots; local s
  AR_SV_KIND=(); AR_SV_KEY=(); AR_SV_LAB=(); AR_SV_VAL=()
  ar_count_open
  for (( i = 0; i < AR_NG; i++ )); do ar_rung_cap $i; rungs=$(( rungs + REPLY )); done
  ar_sv_row head '' '── BOOKKEEPING ─────────────────────────' ''
  ar_pad $(( ${AR[credits]:-0} > AR_MAX_COINS ? AR_MAX_COINS : ${AR[credits]:-0} )) 4
  ar_sv_row bank '' 'COIN HOPPER' "$REPLY"
  ar_sv_row drain '' 'DRAIN THE BANK' '◄ empty'
  ar_sv_row games '' 'UNLOCK EVERY MACHINE' "$AR_NOPEN of $AR_NG"
  ar_sv_row relock '' 'RELOCK THE MACHINES' '◄ back to 1'
  ar_sv_row rungs '' 'OPEN EVERY RUNG' "$rungs of $(( AR_NG * 3 ))"
  ar_sv_row resetrung '' 'RESET THE RUNGS' '◄ back to NORMAL'
  ar_sv_row head '' '── THE WARDROBE ────────────────────────' ''
  if (( AR_VN_OK )); then
    ar_vn_stock; stock=$REPLY
    ar_nkeys 'wardrobe.*'; ar_sv_row vnall '' 'UNLOCK EVERY VANITY ITEM' "$REPLY of $stock"
    one=(HAT PAIR SMOKE AURA); slots=(hat spec smoke aura)
    for (( i = 0; i < 4; i++ )); do ar_vn_have_n ${slots[$i]}; hv=$REPLY; ar_vn_rack_n ${slots[$i]}; ar_sv_row vnrack ${slots[$i]} "UNLOCK EVERY ${one[$i]}" "$hv of $REPLY"; done
    ar_sv_row vnstrip '' 'EMPTY THE WARDROBE' '◄ and undress him'
    ar_sv_row vnroll '' 'DRESS HIM AT RANDOM' '◄ surprise me'
  else
    ar_sv_row dead '' 'THE RACKS ARE NOT ON THIS MACHINE' "${AR_VN_WHY:-no wardrobe}"
  fi
  ar_sv_row head '' '── THE MACHINE ─────────────────────────' ''
  for (( i = 0; i < ${#AR_SVK[@]}; i++ )); do
    ar_svc ${AR_SVK[$i]}; vals=(${=AR_SVV[$i]}); ar_sv_row svc ${AR_SVK[$i]} "${AR_SVL[$i]}" "${vals[$REPLY]}"
  done
  ar_sv_row straight '' 'ALL SWITCHES OFF' '◄ run it straight'
  return 0 }
ar_draw_service() {
  local -F t=$AR_T f nm; local -i shown top=2 slot i y hot acc on n xx d; local kind mk
  local -i sw lx rx spaced=0 nh=0 gaps=0 base kk
  ar_sv_rows; n=${#AR_SV_KIND[@]}
  if ar_rigged; then cmix $RED $WHITE 0.3; local rt=RIGGED; else cmix $LIME $WHITE 0.3; local rt=STRAIGHT; fi
  local -i rc=$CM
  ar_room_head '◈ SERVICE PANEL' $AMBER '' ' ' 0.26
  a_text $(( AR_W - 2 - ${#rt} )) 0 "$rt" $rc -2
  # THE SHEET IS AS LONG AS THE TUBE IS TALL · every row from under the band to
  # over the rule (arcade.py had fourteen of them), and when the whole panel fits
  # a row is left before each heading, the way the menu breathes between its
  # groups · and as wide as reads well: 70 of arcade.py's 72, half of every
  # column the glass adds, centred
  shown=$(( AR_H - 4 ))
  for (( i = 1; i < n; i++ )); do [[ "${AR_SV_KIND[$i]}" == head ]] && nh=$(( nh + 1 )); done
  (( n + nh <= shown )) && { spaced=1; AR_SV_SCROLL=0; }
  sw=$(( 70 + (AR_W - AR_OW) / 2 )); (( sw > 100 )) && sw=100; (( sw > AR_W - 2 )) && sw=$(( AR_W - 2 ))
  lx=$(( (AR_W - sw) / 2 )); rx=$(( lx + sw )); nm=$(( sw / 2.0 + 1.0 ))
  base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  if (( ! spaced )); then
    (( AR_SV_SEL < AR_SV_SCROLL + 1 )) && { AR_SV_SCROLL=$(( AR_SV_SEL - 1 )); (( AR_SV_SCROLL < 0 )) && AR_SV_SCROLL=0; }
    (( AR_SV_SEL >= AR_SV_SCROLL + shown - 1 )) && AR_SV_SCROLL=$(( AR_SV_SEL - shown + 2 ))
    (( AR_SV_SCROLL > n - shown )) && AR_SV_SCROLL=$(( n - shown )); (( AR_SV_SCROLL < 0 )) && AR_SV_SCROLL=0
  fi
  for (( slot = 0; slot < shown; slot++ )); do
    i=$(( AR_SV_SCROLL + slot )); (( i >= n )) && break
    kind=${AR_SV_KIND[$i]}; hot=$(( i == AR_SV_SEL ))
    (( spaced && i > 0 )) && [[ $kind == head ]] && gaps=$(( gaps + 1 ))
    y=$(( top + slot + gaps ))
    if [[ $kind == svc ]]; then acc=$AMBER; else acc=$CYAN; fi
    if (( hot )); then
      kk=$(( base + y * TCOLS + lx ))
      for (( xx = lx; xx < rx; xx++, kk++ )); do
        mk="svc.$acc.$(( xx - lx )).$sw"
        [[ -z "${AR_SWEEP[$mk]:-}" ]] && { f=$(( 1.0 - abs(xx - lx - sw / 2.0) / nm )); cmix $GLASS $acc $(( 0.06 + 0.20 * f )); AR_SWEEP[$mk]=$CM; }
        GCH[$kk]=' '; GB[$kk]=${AR_SWEEP[$mk]}
      done
      cmix $acc $WHITE 0.45; a_put $lx $y '▌' $CM -2
      cmix $WHITE $acc 0.15; a_text $(( lx + 2 )) $y '▶' $CM -2
    fi
    if [[ $kind == head ]]; then cmix $acc $WHITE 0.25; a_text $(( lx + 1 )) $y "${AR_SV_LAB[$i]}" $CM -2; continue; fi
    on=0; [[ $kind == svc ]] && { ar_svc_i ${AR_SV_KEY[$i]}; d=${AR_SVD[$REPLY]}; ar_svc ${AR_SV_KEY[$i]}; (( REPLY != d )) && on=1; }
    if (( hot )); then cmix $acc $WHITE 0.4; else cshade $acc 0.85; CM=$CS; fi
    a_text $(( lx + 4 )) $y "${AR_SV_LAB[$i]}" $CM -2
    if (( on )); then cmix $WHITE $RED 0.35; elif (( hot )); then CM=$WHITE; else cshade $GREY 1.0; CM=$CS; fi
    a_text $(( rx - 3 - ${#AR_SV_VAL[$i]} )) $y "${AR_SV_VAL[$i]}" $CM -2
  done
  cshade $PURPLE 0.7; a_hline 0 $(( AR_H - 2 )) $AR_W '─' $CS
  cshade $AMBER 0.9
  (( AR_SV_SCROLL > 0 )) && a_text $(( rx - 2 )) $(( top - 1 )) '▲' $CS -2
  (( AR_SV_SCROLL + shown < n )) && a_text $(( rx - 2 )) $(( top + shown )) '▼' $CS -2
  if (( t - AR_SV_NOTE_T < 3.0 )) && [[ -n "$AR_SV_NOTE" ]]; then cmix $LIME $WHITE 0.3; a_center $(( AR_H - 1 )) "$AR_SV_NOTE" $CM $GLASS
  elif ar_rigged; then cshade $AMBER 0.95; a_center $(( AR_H - 1 )) 'this machine is rigged  ·  it pays no coins and sets no records' $CS $GLASS
  else ar_plate_no; a_center $(( AR_H - 1 )) "serial $REPLY  ·  everything here writes to terminal.save" $AR_LO $GLASS; fi
  return 0 }
ar_sv_step() {   # ar_sv_step DIR → move the cursor, stepping over the headings
  local -i n=${#AR_SV_KIND[@]} c=$AR_SV_SEL k
  for (( k = 0; k < n; k++ )); do c=$(( (c + $1 + n) % n )); [[ "${AR_SV_KIND[$c]}" != head ]] && break; done
  AR_SV_SEL=$c; return 0 }
ar_service_key() {
  ar_sv_rows
  case "$1" in
    up)   ar_sv_step -1; ar_snd move ;;
    down) ar_sv_step 1; ar_snd move ;;
    left|right|enter|' '|space|1)
      local -i step=1; [[ "$1" == left ]] && step=-1
      ar_sv_do "${AR_SV_KIND[$AR_SV_SEL]}" "${AR_SV_KEY[$AR_SV_SEL]}" $step
      [[ -n "$REPLY" ]] && { AR_SV_NOTE="$REPLY"; AR_SV_NOTE_T=$AR_T; } ;;
    esc|q|Q) ar_snd move; ar_go menu ;;
    u|U) ar_mute ;;
  esac
  return 0 }
ar_sv_do() {   # ar_sv_do KIND KEY STEP → REPLY a line to show
  local kind="$1" key="$2" k; local -i step=$3 i v n; local -a vals
  REPLY=''
  case $kind in
    svc)    ar_svc_i $key; i=$REPLY; vals=(${=AR_SVV[$i]}); n=${#vals[@]}; ar_svc $key
            v=$(( (REPLY + step + n) % n )); AR[svc.$key]=$v; AR_DIRTY=1; ar_save_write; ar_snd select
            REPLY="${key:u} ${vals[$v]}" ;;
    bank)   if (( step > 0 )); then ar_award 1000 0; else ar_award 100 0; fi; AR_DIRTY=1; ar_save_write; ar_flash; ar_snd coin
            REPLY="HOPPER  +$REPLY COINS (not counted as earned)" ;;
    drain)  AR[credits]=0; AR_DIRTY=1; ar_save_write; ar_snd error; REPLY='BANK DRAINED' ;;
    games)  for (( i = 0; i < AR_NG; i++ )); do (( ${AR_GPRICE[$i]} > 0 )) && { AR[owned.${AR_GID[$i]}]=${EPOCHSECONDS:-0}; unset "AR[rentals.${AR_GID[$i]}]"; }; done
            AR_DIRTY=1; ar_save_write; ar_count_open; ar_snd coin; REPLY='EVERY MACHINE UNLOCKED' ;;
    relock) for k in ${(M)${(k)AR[@]}:#owned.*} ${(M)${(k)AR[@]}:#rentals.*}; do unset "AR[$k]"; done
            AR_DIRTY=1; ar_save_write; ar_count_open; ar_snd error; REPLY='MACHINES RELOCKED -- back to the house game' ;;
    rungs)  for (( i = 0; i < AR_NG; i++ )); do AR[unlocked.${AR_GID[$i]}]=3; done
            AR_DIRTY=1; ar_save_write; ar_snd coin; REPLY='EVERY RUNG OPEN' ;;
    resetrung) for k in ${(M)${(k)AR[@]}:#unlocked.*}; do unset "AR[$k]"; done
            AR_DIRTY=1; ar_save_write; ar_snd error; REPLY='RUNGS RESET -- ROOKIE and NORMAL only' ;;
    vnall)  ar_vn_stock_all ''; AR_DIRTY=1; ar_save_write; ar_snd coin; ar_badges_check; REPLY="EVERY VANITY ITEM UNLOCKED -- $AR_VN_N on the rail" ;;
    vnrack) ar_vn_stock_all $key; AR_DIRTY=1; ar_save_write; ar_snd coin; ar_badges_check; ar_vn_slot_label $key; REPLY="$REPLY UNLOCKED -- $AR_VN_N of them" ;;
    vnstrip) for k in ${(M)${(k)AR[@]}:#wardrobe.*} ${(M)${(k)AR[@]}:#worn.*}; do unset "AR[$k]"; done
            AR_DIRTY=1; ar_save_write; ar_snd error; REPLY='WARDROBE EMPTIED -- and he is wearing nothing' ;;
    vnroll) ar_vn_surprise; REPLY="$AR_VN_SAID" ;;
    dead)   ar_snd error; REPLY="NO RACKS ON THIS MACHINE -- ${AR_VN_WHY:-?}" ;;
    straight) for k in ${(M)${(k)AR[@]}:#svc.*}; do unset "AR[$k]"; done
            AR_DIRTY=1; ar_save_write; ar_snd select; REPLY='ALL SWITCHES OFF -- the machine is straight again' ;;
  esac
  return 0 }

# ── THE SWITCHES, IN A ROUND ──────────────────────────────────────────────
# Time dilation stretches the round's own clock; the score dial multiplies
# every point; FREE LIFE catches a death; ROUND REWIND winds the round back
# half a second to before it; DEMO PLAY puts the demonstrator's hand on the
# stick; DIAGNOSTICS prints what the machine is holding along the bottom.
typeset -g  AR_SNAP=''
typeset -gF AR_SNAP_T=-99.0 AR_REWOUND=-99.0 AR_WALL_T=-99.0
typeset -gi AR_RIG=0
ar_svc_round() {   # at the coin · the dial, and whether this round is rigged
  ar_svc mult; AR_SVC_MULT=${AR_SVMULT[$REPLY]}
  if ar_rigged; then AR_RIG=1; else AR_RIG=0; fi
  AR_SNAP=''; AR_SNAP_T=-99.0; AR_REWOUND=-99.0; AR_WALL_T=-99.0
  return 0 }
ar_svc_snap() {   # everything the round holds, as declarations to be read back
  local P="${AR_GP:u}_"; local -a names
  names=(${(M)${(k)parameters[@]}:#${P}*})
  names=(${names:#(LC_ALL|LC_COLLATE|LC_CTYPE|LC_MESSAGES|LC_NUMERIC|LC_TIME)})
  (( ${#names[@]} )) || { AR_SNAP=''; return 0 }
  AR_SNAP="$(typeset -p "${names[@]}" ST_V ST_ACC ST_DAMP ST_MAX AR_SCORE AR_FRAC AR_LEVEL AR_LIVES AR_RT RS RN 2>/dev/null)"
  return 0 }
ar_svc_restore() { [[ -n "$AR_SNAP" ]] || return 1; eval "$AR_SNAP" 2>/dev/null; AR_SNAP=''; return 0 }
ar_svc_overlay() {   # the diagnostics strip · what the machine is actually doing
  # five of the round's tables on arcade.py's 72 columns, and one more for every
  # eight columns a wider board has to print them on
  local P="${AR_GP:u}_" s n m; local -a names cnt; local -i most=$(( 5 + (AR_W - AR_OW) / 8 ))
  (( most < 5 )) && most=5
  names=(${(o)${(M)${(k)parameters[@]}:#${P}*}})
  for n in "${names[@]}"; do
    case "${(Pt)n}" in
      array*|association*) s="${n#$P}"; s="${s:l}"; m="$n[@]"; cnt+=("${s[0,2]}${(P)#m}") ;;
    esac
    (( ${#cnt[@]} >= most )) && break
  done
  ar_f1 $(( AR_DT * 1000.0 )); s="${REPLY}ms  t$(( int(AR_RT + 0.5) ))  lv$AR_LEVEL  ${cnt[*]}"
  cmix $LIME $WHITE 0.4; local -i fg=$CM; cmix $GLASS $VOID_MIX 0.65
  a_text 1 $(( AR_H - 1 )) "${s[0,$(( AR_W - 3 ))]}" $fg $CM
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# THE WARDROBE, AS DATA · generated by gen_vanity.py from scripts/vanity/ · do not edit
# ══════════════════════════════════════════════════════════════════════════
# 59 hats · 45 glasses · 27 smokes · 35 auras
typeset -ga VN_R_hat VN_R_spec VN_R_smoke VN_R_aura
typeset -gA VN_NAME VN_PRICE VN_RAR VN_ART VN_PAL VN_SEAT VN_BRIM VN_GLOW VN_EVERY VN_FROMH VN_RAMP VN_FAMILY VN_NOTE VN_LIT
VN_R_hat=(tophat bowler fedora beanie pom propeller tinfoil helmet saucer party crown tiara halo horns cat laurel moon circlet flowers cowboy hardhat chef pirate viking wizard grad pilot headlamp cone santa ushanka bucket beret nightcap sombrero bandana fez snapback visor cans mohawk antenna flatcap newsboy porkpie boater sweatband shower earmuffs antlers jester nemes kabuto greathelm diver mothership solar phoenix saturn)
VN_NAME[hat:tophat]='TOP HAT'; VN_PRICE[hat:tophat]=260; VN_RAR[hat:tophat]=classic
VN_ART[hat:tophat]='.........aaaaaaaaa........|.........aaaaaaaaa........|.........aaaaaaaaa........|.........aaaaaaaaa........|........aaaaaaaaaaa.......|........aaaaaaaaaaa.......|........ccccccccccc.......|........ccccccccccc.......|....bbbbbbbbbbbbbbbbbb....|....bbbbbbbbbbbbbbbbbb....'
VN_PAL[hat:tophat]='a=1e1e26 b=2a2a34 c=8c2f3f'
VN_SEAT[hat:tophat]=3
VN_BRIM[hat:tophat]=1
VN_NAME[hat:bowler]='BOWLER'; VN_PRICE[hat:bowler]=120; VN_RAR[hat:bowler]=classic
VN_ART[hat:bowler]='..........aaaaaa..........|.........aaaaaaaa.........|........aaaaaaaaaa........|........aaaaaaaaaa........|........cccccccccc........|........cccccccccc........|.....bbbbbbbbbbbbbbbb.....|.....bbbbbbbbbbbbbbbb.....'
VN_PAL[hat:bowler]='a=3a2c1f b=4a3826 c=241a12'
VN_SEAT[hat:bowler]=3
VN_BRIM[hat:bowler]=1
VN_NAME[hat:fedora]='FEDORA'; VN_PRICE[hat:fedora]=170; VN_RAR[hat:fedora]=classic
VN_ART[hat:fedora]='.........aaa..aaa.........|.........aaaaaaaa.........|........aaaaaaaaaa........|........aaaaaaaaaa........|.......cccccccccccc.......|.......cccccccccccc.......|....bbbbbbbbbbbbbbbbbb....|....bbbbbbbbbbbbbbbbbb....'
VN_PAL[hat:fedora]='a=6b4f36 b=7a5b3e c=33251a'
VN_SEAT[hat:fedora]=3
VN_BRIM[hat:fedora]=2
VN_NAME[hat:beanie]='BEANIE'; VN_PRICE[hat:beanie]=40; VN_RAR[hat:beanie]=common
VN_ART[hat:beanie]='..........aaaaaa..........|.........aaaaaaaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......bbbbbbbbbbbb.......|.......bbbbbbbbbbbb.......|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......'
VN_PAL[hat:beanie]='a=c4425e b=8e2c42'
VN_SEAT[hat:beanie]=3
VN_BRIM[hat:beanie]=0
VN_NAME[hat:pom]='POM BEANIE'; VN_PRICE[hat:pom]=90; VN_RAR[hat:pom]=common
VN_ART[hat:pom]='...........cccc...........|...........cccc...........|..........aaaaaa..........|.........aaaaaaaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......bbbbbbbbbbbb.......|.......bbbbbbbbbbbb.......|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......'
VN_PAL[hat:pom]='a=3f6fbf b=28457a c=f0f0f4'
VN_SEAT[hat:pom]=3
VN_BRIM[hat:pom]=0
VN_NAME[hat:propeller]='PROPELLER BEANIE'; VN_PRICE[hat:propeller]=660; VN_RAR[hat:propeller]=rare
VN_ART[hat:propeller]='....cccc...dddd...cccc....|.....ccc...dddd...ccc.....|............dd............|............dd............|.........aaaaaaaa.........|........aaaaaaaaaa........|.......bbbbbbbbbbbb.......|.......bbbbbbbbbbbb.......|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......'
VN_PAL[hat:propeller]='a=2f7fd6 b=c03a30 c=f2c73c d=b9c0d0'
VN_SEAT[hat:propeller]=3
VN_BRIM[hat:propeller]=0
VN_NAME[hat:tinfoil]='TINFOIL HAT'; VN_PRICE[hat:tinfoil]=600; VN_RAR[hat:tinfoil]=rare
VN_ART[hat:tinfoil]='...........aaa............|..........aaaaaa..........|.........aaaa.aaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|......aaa.aaaaaaaaaa......|.....bbbbbbbbbbbbbbbb.....|.....bbbbbbbbbbbbbbbb.....'
VN_PAL[hat:tinfoil]='a=dce6f4 b=8fa0b8'
VN_SEAT[hat:tinfoil]=3
VN_BRIM[hat:tinfoil]=1
VN_NAME[hat:helmet]='SPACE HELMET'; VN_PRICE[hat:helmet]=1350; VN_RAR[hat:helmet]=epic
VN_ART[hat:helmet]='.........aaaaaaaa.........|.......aaaaaaaaaaaa.......|......aa......hh..aa......|......aa......hh..aa......|.....aa.........hh.aa.....|.....aa.........hh.aa.....|....aa..............aa....|....aa..............aa....|....bbbbbbbbbbbbbbbbbb....|....bbbbbbbbbbbbbbbbbb....'
VN_PAL[hat:helmet]='a=cfe6f4 b=3f5f7a h=ffffff'
VN_SEAT[hat:helmet]=3
VN_BRIM[hat:helmet]=1
VN_NAME[hat:saucer]='FLYING SAUCER'; VN_PRICE[hat:saucer]=2100; VN_RAR[hat:saucer]=legendary
VN_ART[hat:saucer]='..........cccccc..........|.........cccccccc.........|......aaaaaaaaaaaaaa......|....aaaaaaaaaaaaaaaaaa....|......bb.bb.bb.bb.bb......|......bb.bb.bb.bb.bb......|..........dddddd..........|.........dddddddd.........|........dddddddddd........|.......ddddddddddddd......'
VN_PAL[hat:saucer]='a=4a5668 b=5fffd7 c=aebcd4 d=9ce8ff'
VN_SEAT[hat:saucer]=3
VN_BRIM[hat:saucer]=0
VN_NAME[hat:party]='PARTY HAT'; VN_PRICE[hat:party]=60; VN_RAR[hat:party]=common
VN_ART[hat:party]='............cc............|............cc............|...........aaaa...........|...........aaaa...........|..........bbbbbb..........|..........bbbbbb..........|.........aaaaaaaa.........|.........aaaaaaaa.........|........bbbbbbbbbb........|........bbbbbbbbbb........'
VN_PAL[hat:party]='a=ff5faf b=5fd7ff c=ffd75f'
VN_SEAT[hat:party]=3
VN_BRIM[hat:party]=0
VN_NAME[hat:crown]='CROWN'; VN_PRICE[hat:crown]=1600; VN_RAR[hat:crown]=epic
VN_ART[hat:crown]='........b...bb...b........|........b...bb...b........|.......aaa.aaaa.aaa.......|.......aaa.aaaa.aaa.......|.......aaaaaccaaaaa.......|.......aaaaaccaaaaa.......|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......'
VN_PAL[hat:crown]='a=e8b93c b=fff0b0 c=d24b5a'
VN_SEAT[hat:crown]=3
VN_BRIM[hat:crown]=0
VN_NAME[hat:tiara]='TIARA'; VN_PRICE[hat:tiara]=800; VN_RAR[hat:tiara]=rare
VN_ART[hat:tiara]='............bb............|............bb............|........a..aaaa..a........|........a..aaaa..a........|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......'
VN_PAL[hat:tiara]='a=e4e8f2 b=7fe6ff'
VN_SEAT[hat:tiara]=3
VN_BRIM[hat:tiara]=0
VN_NAME[hat:halo]='HALO'; VN_PRICE[hat:halo]=860; VN_RAR[hat:halo]=rare
VN_ART[hat:halo]='........aaaaaaaaaa........|......aaaaaaaaaaaaaa......|.....aa............aa.....|.....aa............aa.....|......aaaaaaaaaaaaaa......|........aaaaaaaaaa........|..........................|..........................|..........................|..........................'
VN_PAL[hat:halo]='a=ffe98a'
VN_SEAT[hat:halo]=3
VN_BRIM[hat:halo]=0
VN_NAME[hat:horns]='DEVIL HORNS'; VN_PRICE[hat:horns]=940; VN_RAR[hat:horns]=rare
VN_ART[hat:horns]='.....b..............b.....|.....b..............b.....|.....aa............aa.....|......aa..........aa......|......aaa........aaa......|.......aaa......aaa.......|.......aaaa....aaaa.......|.......aaaa....aaaa.......'
VN_PAL[hat:horns]='a=c8402f b=f0c8a0'
VN_SEAT[hat:horns]=3
VN_BRIM[hat:horns]=0
VN_NAME[hat:cat]='CAT EARS'; VN_PRICE[hat:cat]=360; VN_RAR[hat:cat]=uncommon
VN_ART[hat:cat]='........a........a........|.......aaa......aaa.......|......aabaa....aabaa......|......aabaa....aabaa......|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......'
VN_PAL[hat:cat]='a=5a5a66 b=e0899f'
VN_SEAT[hat:cat]=3
VN_BRIM[hat:cat]=0
VN_NAME[hat:laurel]='LAUREL WREATH'; VN_PRICE[hat:laurel]=840; VN_RAR[hat:laurel]=rare
VN_ART[hat:laurel]='.....bb............bb.....|.....bbb..........bbb.....|.....aaa..........aaa.....|......aaa........aaa......|......aaa........aaa......|.......aaa......aaa.......|.......aaaaaaaaaaaaa......|.......aaaaaaaaaaaaa......'
VN_PAL[hat:laurel]='a=7fb069 b=b8d894'
VN_SEAT[hat:laurel]=3
VN_BRIM[hat:laurel]=0
VN_NAME[hat:moon]='MOON CRESCENT'; VN_PRICE[hat:moon]=1450; VN_RAR[hat:moon]=epic
VN_ART[hat:moon]='..........aaaaaa..........|........aaaaaaaa..........|.......aaaa........bb.....|......aaaa.........bb.....|.....aaaa........bb.......|.....aaaa........bb.......|......aaaa................|.......aaaa...............|........aaaaaaaa..........|..........aaaaaa..........'
VN_PAL[hat:moon]='a=ffeaa0 b=ffffff'
VN_SEAT[hat:moon]=3
VN_BRIM[hat:moon]=0
VN_NAME[hat:circlet]='STAR CIRCLET'; VN_PRICE[hat:circlet]=1100; VN_RAR[hat:circlet]=epic
VN_ART[hat:circlet]='............bb............|............bb............|.....c.bbbbbbbbbbbb.c.....|.....c...bbbbbbbb...c.....|..........bb..bb..........|..........bb..bb..........|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......'
VN_PAL[hat:circlet]='a=8f6fd6 b=ffd75f c=ffffff'
VN_SEAT[hat:circlet]=3
VN_BRIM[hat:circlet]=0
VN_NAME[hat:flowers]='FLOWER CROWN'; VN_PRICE[hat:flowers]=480; VN_RAR[hat:flowers]=uncommon
VN_ART[hat:flowers]='......bcb.bcb.bcb.bcb.....|......bbb.bbb.bbb.bbb.....|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....'
VN_PAL[hat:flowers]='a=4f8f4f b=ff8fc0 c=ffe08a'
VN_SEAT[hat:flowers]=3
VN_BRIM[hat:flowers]=0
VN_NAME[hat:cowboy]='COWBOY HAT'; VN_PRICE[hat:cowboy]=460; VN_RAR[hat:cowboy]=uncommon
VN_ART[hat:cowboy]='.........aaa..aaa.........|.........aaaaaaaa.........|........aaaaaaaaaa........|........aaaaaaaaaa........|.......cccccccccccc.......|.......cccccccccccc.......|...aaaaaaaaaaaaaaaaaaaa...|...aaaaaaaaaaaaaaaaaaaa...'
VN_PAL[hat:cowboy]='a=b07636 c=4a3520'
VN_SEAT[hat:cowboy]=3
VN_BRIM[hat:cowboy]=2
VN_NAME[hat:hardhat]='HARD HAT'; VN_PRICE[hat:hardhat]=150; VN_RAR[hat:hardhat]=common
VN_ART[hat:hardhat]='...........cccc...........|...........cccc...........|.........aaccccaa.........|........aaaccccaaa........|.......aaaaccccaaaa.......|.......aaaaccccaaaa.......|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....'
VN_PAL[hat:hardhat]='a=f2b01e c=f2f2f6'
VN_SEAT[hat:hardhat]=3
VN_BRIM[hat:hardhat]=1
VN_NAME[hat:chef]='CHEF'\''S TOQUE'; VN_PRICE[hat:chef]=300; VN_RAR[hat:chef]=uncommon
VN_ART[hat:chef]='.........aaa..aaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......aaaaaaaaaaaa.......|........aaaaaaaaaa........|.........aaaaaaaa.........|.........bbbbbbbb.........|.........bbbbbbbb.........|.......bbbbbbbbbbbbb......|.......bbbbbbbbbbbbb......'
VN_PAL[hat:chef]='a=f8f8fc b=a8a8bc'
VN_SEAT[hat:chef]=3
VN_BRIM[hat:chef]=0
VN_NAME[hat:pirate]='PIRATE HAT'; VN_PRICE[hat:pirate]=960; VN_RAR[hat:pirate]=rare
VN_ART[hat:pirate]='.....a..............a.....|.....aa............aa.....|.....aaa..........aaa.....|.....aaaaa......aaaaa.....|.....aaaaaaccccaaaaaa.....|.....aaaaaaccccaaaaaa.....|...bbaaaaaaaaaaaaaaaabb...|...bbaaaaaaaaaaaaaaaabb...'
VN_PAL[hat:pirate]='a=2b2b34 b=c8a24a c=f0f0f4'
VN_SEAT[hat:pirate]=3
VN_BRIM[hat:pirate]=2
VN_NAME[hat:viking]='VIKING HELM'; VN_PRICE[hat:viking]=1000; VN_RAR[hat:viking]=rare
VN_ART[hat:viking]='....b................b....|....bb..............bb....|.....bb....aaaa....bb.....|......bb..aaaaaa..bb......|.......aaaaaaaaaaaa.......|.......aaaaaaaaaaaa.......|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....'
VN_PAL[hat:viking]='a=5a6474 b=e8e2d0'
VN_SEAT[hat:viking]=3
VN_BRIM[hat:viking]=1
VN_NAME[hat:wizard]='WIZARD HAT'; VN_PRICE[hat:wizard]=1200; VN_RAR[hat:wizard]=epic
VN_ART[hat:wizard]='...............aaa........|..............aaa.........|.............ada..........|............aaaa..........|...........adaaa..........|..........aaaaaaa.........|........cccccccccc........|........cccccccccc........|....aaaaaaaaaaaaaaaaaa....|....aaaaaaaaaaaaaaaaaa....'
VN_PAL[hat:wizard]='a=4b3f8f c=2a2244 d=ffd75f'
VN_SEAT[hat:wizard]=3
VN_BRIM[hat:wizard]=2
VN_NAME[hat:grad]='GRADUATION CAP'; VN_PRICE[hat:grad]=520; VN_RAR[hat:grad]=uncommon
VN_ART[hat:grad]='............cc............|............cc............|...aaaaaaaaaaaaaaaaaaaa...|...aaaaaaaaaaaaaaaaaaaa...|.......bbbbbbbbbbbb..cc...|.......bbbbbbbbbbbb..cc...'
VN_PAL[hat:grad]='a=3d3d4c b=22222b c=e8b93c'
VN_SEAT[hat:grad]=3
VN_BRIM[hat:grad]=2
VN_NAME[hat:pilot]='PILOT CAP'; VN_PRICE[hat:pilot]=540; VN_RAR[hat:pilot]=uncommon
VN_ART[hat:pilot]='.........aaaaaaaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......aaaaaaaaaaaa.......|.......ccccbbbbcccc.......|.......ccccbbbbcccc.......|....dddddddddddddddddd....|....dddddddddddddddddd....'
VN_PAL[hat:pilot]='a=6b4b32 b=e8c46a c=2a2118 d=1c1c22'
VN_SEAT[hat:pilot]=3
VN_BRIM[hat:pilot]=2
VN_NAME[hat:headlamp]='HEADLAMP'; VN_PRICE[hat:headlamp]=420; VN_RAR[hat:headlamp]=uncommon
VN_ART[hat:headlamp]='.........cccccccc.........|.........cccccccc.........|......aaacddddddcaaa......|......aaacddddddcaaa......|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....'
VN_PAL[hat:headlamp]='a=2a2a34 c=4a4a5a d=ffe98a'
VN_SEAT[hat:headlamp]=3
VN_BRIM[hat:headlamp]=0
VN_NAME[hat:cone]='TRAFFIC CONE'; VN_PRICE[hat:cone]=640; VN_RAR[hat:cone]=rare
VN_ART[hat:cone]='............aa............|...........aaaa...........|...........cccc...........|..........cccccc..........|..........aaaaaa..........|.........aaaaaaaa.........|.........cccccccc.........|........cccccccccc........|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....'
VN_PAL[hat:cone]='a=ff6b2c c=f2f2f6'
VN_SEAT[hat:cone]=3
VN_BRIM[hat:cone]=1
VN_NAME[hat:santa]='SANTA HAT'; VN_PRICE[hat:santa]=400; VN_RAR[hat:santa]=uncommon
VN_ART[hat:santa]='...................bbb....|...................bbb....|.................aabbb....|..............aaaaa.......|............aaaaaa........|.........aaaaaaaa.........|.......bbbbbbbbbbbb.......|.......bbbbbbbbbbbb.......|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......'
VN_PAL[hat:santa]='a=c0392b b=f4f4f8'
VN_SEAT[hat:santa]=3
VN_BRIM[hat:santa]=0
VN_NAME[hat:ushanka]='USHANKA'; VN_PRICE[hat:ushanka]=340; VN_RAR[hat:ushanka]=uncommon
VN_ART[hat:ushanka]='.........aaaaaaaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......aaaaaaaaaaaa.......|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......|....bbbbbbbbbbbbbbbbbb....|....bbbbbbbbbbbbbbbbbb....'
VN_PAL[hat:ushanka]='a=5a4a40 b=c9bda8'
VN_SEAT[hat:ushanka]=3
VN_BRIM[hat:ushanka]=2
VN_NAME[hat:bucket]='BUCKET HAT'; VN_PRICE[hat:bucket]=120; VN_RAR[hat:bucket]=common
VN_ART[hat:bucket]='.........aaaaaaaa.........|........aaaaaaaaaa........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......bbbbbbbbbbbb.......|.......bbbbbbbbbbbb.......|...aaaaaaaaaaaaaaaaaaaa...|...aaaaaaaaaaaaaaaaaaaa...'
VN_PAL[hat:bucket]='a=5f7f4f b=3f5a34'
VN_SEAT[hat:bucket]=3
VN_BRIM[hat:bucket]=2
VN_NAME[hat:beret]='BERET'; VN_PRICE[hat:beret]=280; VN_RAR[hat:beret]=uncommon
VN_ART[hat:beret]='...........aa.............|...........aa.............|......aaaaaaaaaaaaa.......|.....aaaaaaaaaaaaaaa......|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......'
VN_PAL[hat:beret]='a=2f3a5f b=12172c'
VN_SEAT[hat:beret]=3
VN_BRIM[hat:beret]=1
VN_NAME[hat:nightcap]='NIGHT CAP'; VN_PRICE[hat:nightcap]=160; VN_RAR[hat:nightcap]=common
VN_ART[hat:nightcap]='....bbb...................|....bbb...................|.....aaaa.................|.....aaaaaa...............|......bbbbbbbb............|.......bbbbbbbbb..........|.......aaaaaaaaaaa........|.......aaaaaaaaaaa........|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......'
VN_PAL[hat:nightcap]='a=453a80 b=f2ecdc'
VN_SEAT[hat:nightcap]=3
VN_BRIM[hat:nightcap]=0
VN_NAME[hat:sombrero]='SOMBRERO'; VN_PRICE[hat:sombrero]=760; VN_RAR[hat:sombrero]=rare
VN_ART[hat:sombrero]='...........aaaa...........|...........aaaa...........|..........aaaaaa..........|..........aaaaaa..........|.........cccccccc.........|.........cccccccc.........|...aaaaaaaaaaaaaaaaaaaa...|...aaaaaaaaaaaaaaaaaaaa...'
VN_PAL[hat:sombrero]='a=c9a227 c=8a3a2a'
VN_SEAT[hat:sombrero]=3
VN_BRIM[hat:sombrero]=2
VN_NAME[hat:bandana]='BANDANA'; VN_PRICE[hat:bandana]=70; VN_RAR[hat:bandana]=common
VN_ART[hat:bandana]='.......aaaaaaaaaaaa.......|......acaacaacaacaa.......|.....aaaaaaaaaaaaaaaa.....|.....acaacaacaacaacaa.....|....aaaaaaaaaaaaaaaaaaa...|....aaaaaaaaaaaaaaaaaaa...'
VN_PAL[hat:bandana]='a=b5423f c=e8d0c0'
VN_SEAT[hat:bandana]=3
VN_BRIM[hat:bandana]=0
VN_NAME[hat:fez]='FEZ'; VN_PRICE[hat:fez]=180; VN_RAR[hat:fez]=common
VN_ART[hat:fez]='.........aaaaaaaa.........|.........aaaaaaaac........|.........aaaaaaaa.c.......|.........aaaaaaaa.c.......|.........aaaaaaaa.c.......|.........aaaaaaaa.c.......|.......aaaaaaaaaaaccc.....|.......aaaaaaaaaaaccc.....'
VN_PAL[hat:fez]='a=a3312f c=e8b93c'
VN_SEAT[hat:fez]=3
VN_BRIM[hat:fez]=0
VN_NAME[hat:snapback]='SNAPBACK'; VN_PRICE[hat:snapback]=130; VN_RAR[hat:snapback]=common
VN_ART[hat:snapback]='.........aaaaaaaa.........|........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|.......aaaaaaaaaaaa.......|.......aaaaaaaaaaaaabb....|.......aaaaaaaaaaaaabb....'
VN_PAL[hat:snapback]='a=2f4f8f b=e8e8ee'
VN_SEAT[hat:snapback]=3
VN_BRIM[hat:snapback]=1
VN_NAME[hat:visor]='VISOR'; VN_PRICE[hat:visor]=320; VN_RAR[hat:visor]=uncommon
VN_ART[hat:visor]='.......aaaaaaaaaaaa.......|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......|...bbbbbbbbbbbbbbbbbbbb...|....bbbbbbbbbbbbbbbbbb....'
VN_PAL[hat:visor]='a=22222b b=5fd75f'
VN_SEAT[hat:visor]=3
VN_BRIM[hat:visor]=2
VN_NAME[hat:cans]='HEADPHONES'; VN_PRICE[hat:cans]=560; VN_RAR[hat:cans]=uncommon
VN_ART[hat:cans]='........aaaaaaaaaa........|........aaaaaaaaaa........|......aa..........aa......|.....aa............aa.....|...bbbbb..........bbbbb...|...bbbbb..........bbbbb...|...bbccb..........bccbb...|...bbccb..........bccbb...'
VN_PAL[hat:cans]='a=2a2a34 b=15151c c=5fd7ff'
VN_SEAT[hat:cans]=3
VN_BRIM[hat:cans]=0
VN_NAME[hat:mohawk]='MOHAWK'; VN_PRICE[hat:mohawk]=700; VN_RAR[hat:mohawk]=rare
VN_ART[hat:mohawk]='...........a.aa...........|..........aaaaaa..........|..........aaaaaa..........|.........aaaaaaaa.........|.........aaaaaaaa.........|.........aaaaaaaa.........|.......bbbbbbbbbbbbb......|.......bbbbbbbbbbbbb......'
VN_PAL[hat:mohawk]='a=c0392b b=2b2b34'
VN_SEAT[hat:mohawk]=3
VN_BRIM[hat:mohawk]=0
VN_NAME[hat:antenna]='ANTENNA BAND'; VN_PRICE[hat:antenna]=500; VN_RAR[hat:antenna]=uncommon
VN_ART[hat:antenna]='.......bbb......bbb.......|.......bbb......bbb.......|........aa......aa........|........aa......aa........|.........aa....aa.........|.........aa....aa.........|..........aa..aa..........|..........aa..aa..........|......cccccccccccccc......|......cccccccccccccc......'
VN_PAL[hat:antenna]='a=4a4a56 b=5fffd7 c=22222b'
VN_SEAT[hat:antenna]=3
VN_BRIM[hat:antenna]=0
VN_NAME[hat:flatcap]='FLAT CAP'; VN_PRICE[hat:flatcap]=140; VN_RAR[hat:flatcap]=classic
VN_ART[hat:flatcap]='........aaaaaaaaaa........|......aaaaaaaaaaaaaa......|.....aaaaaaaaaaaaaaa......|.....aaaaaaaaaaaaaaaa.....|.....bbbbbbbbbbbbbbbbbb...|.....bbbbbbbbbbbbbbbbbb...'
VN_PAL[hat:flatcap]='a=45403c b=2c2825'
VN_SEAT[hat:flatcap]=3
VN_BRIM[hat:flatcap]=1
VN_NAME[hat:newsboy]='NEWSBOY CAP'; VN_PRICE[hat:newsboy]=190; VN_RAR[hat:newsboy]=classic
VN_ART[hat:newsboy]='............bb............|............bb............|.........aaaaaaaa.........|.......aaaaaaaaaaaa.......|......aaaaaaaaaaaaaa......|.....aaaaaaaaaaaaaaaa.....|.....bbbbbbbbbbbbbbbb.....|.....bbbbbbbbbbbbbbbb.....'
VN_PAL[hat:newsboy]='a=6a5a44 b=43392c'
VN_SEAT[hat:newsboy]=3
VN_BRIM[hat:newsboy]=1
VN_NAME[hat:porkpie]='PORK PIE'; VN_PRICE[hat:porkpie]=210; VN_RAR[hat:porkpie]=classic
VN_ART[hat:porkpie]='.........aaa..aaa.........|.........aaaaaaaa.........|.........aaaaaaaa.........|.........aaaaaaaa.........|........cccccccccc........|........cccccccccc........|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....'
VN_PAL[hat:porkpie]='a=43384a c=d8b45a'
VN_SEAT[hat:porkpie]=3
VN_BRIM[hat:porkpie]=1
VN_NAME[hat:boater]='BOATER'; VN_PRICE[hat:boater]=240; VN_RAR[hat:boater]=classic
VN_ART[hat:boater]='.........aaaaaaaa.........|.........aaaaaaaa.........|.........cccccccc.........|.........cccccccc.........|.........aaaaaaaa.........|.........aaaaaaaa.........|...aaaaaaaaaaaaaaaaaaaa...|...aaaaaaaaaaaaaaaaaaaa...'
VN_PAL[hat:boater]='a=e0c483 c=2c4a8a'
VN_SEAT[hat:boater]=3
VN_BRIM[hat:boater]=2
VN_NAME[hat:sweatband]='SWEATBAND'; VN_PRICE[hat:sweatband]=100; VN_RAR[hat:sweatband]=common
VN_ART[hat:sweatband]='......aaaaaaaaaaaaaa......|.....aaaaaaaaaaaaaaaa.....|.....bbbbbbbbbbbbbbbb.....|......bbbbbbbbbbbbbb......'
VN_PAL[hat:sweatband]='a=eef0f8 b=d8354f'
VN_SEAT[hat:sweatband]=3
VN_BRIM[hat:sweatband]=0
VN_NAME[hat:shower]='SHOWER CAP'; VN_PRICE[hat:shower]=380; VN_RAR[hat:shower]=uncommon
VN_ART[hat:shower]='........aaaaaaaaaa........|......aaacaaaaacaaaa......|.....aaaaaaaaaaaaaaaa.....|.....acaaaacaaaacaaaa.....|.....aaaaaaaaaaaaaaaa.....|.....aaaacaaaaacaaaaa.....|.....bbbbbbbbbbbbbbbb.....|......bbbbbbbbbbbbbb......'
VN_PAL[hat:shower]='a=eef4fa b=8fa2b4 c=7fb8e0'
VN_SEAT[hat:shower]=3
VN_BRIM[hat:shower]=0
VN_NAME[hat:earmuffs]='EARMUFFS'; VN_PRICE[hat:earmuffs]=440; VN_RAR[hat:earmuffs]=uncommon
VN_ART[hat:earmuffs]='.........aaaaaaaa.........|.........aaaaaaaa.........|.......aa........aa.......|.....bbbb........bbbb.....|....bbbbbb......bbbbbb....|....bbbbbb......bbbbbb....|....bbbbbb......bbbbbb....|.....bbbb........bbbb.....'
VN_PAL[hat:earmuffs]='a=33333f b=e08aa0'
VN_SEAT[hat:earmuffs]=3
VN_BRIM[hat:earmuffs]=0
VN_NAME[hat:antlers]='ANTLERS'; VN_PRICE[hat:antlers]=740; VN_RAR[hat:antlers]=rare
VN_ART[hat:antlers]='.....a...a......a...a.....|.....a...a......a...a.....|.....aa.aa......aa.aa.....|......aaa........aaa......|.......aa........aa.......|........aa......aa........|.........aa....aa.........|..........aaaaaa..........|..........aaaaaa..........|..........aaaaaa..........'
VN_PAL[hat:antlers]='a=8a6a42'
VN_SEAT[hat:antlers]=3
VN_BRIM[hat:antlers]=0
VN_NAME[hat:jester]='JESTER'\''S CAP'; VN_PRICE[hat:jester]=900; VN_RAR[hat:jester]=rare
VN_ART[hat:jester]='............cc............|............cc............|.....c......bb......c.....|.....c......bb......c.....|.....aa.....bb.....aa.....|......aa....bb....aa......|.......aaa.bbbb.aaa.......|........aaabbbbaaa........|.......aaaabbbbaaaa.......|......aaaaabbbbaaaaa......'
VN_PAL[hat:jester]='a=c0304a b=2a8a6a c=ffd75f'
VN_SEAT[hat:jester]=3
VN_BRIM[hat:jester]=0
VN_NAME[hat:nemes]='PHARAOH'\''S NEMES'; VN_PRICE[hat:nemes]=1150; VN_RAR[hat:nemes]=epic
VN_ART[hat:nemes]='............cc............|............cc............|........baabbaabba........|.......bbaabbaabbaa.......|......abbaabbaabbaab......|.....aabbaabbaabbaabb.....|....baabbaabbaabbaabba....|....baabbaabbaabbaabba....'
VN_PAL[hat:nemes]='a=2a5aa8 b=e8c46a c=e8443c'
VN_SEAT[hat:nemes]=3
VN_BRIM[hat:nemes]=2
VN_NAME[hat:kabuto]='SAMURAI KABUTO'; VN_PRICE[hat:kabuto]=1300; VN_RAR[hat:kabuto]=epic
VN_ART[hat:kabuto]='.......b..........b.......|.......bb........bb.......|........bb......bb........|.........bb....bb.........|..........bbbbbb..........|..........bbbbbb..........|........aaaaaaaaaa........|........aaaaaaaaaa........|.....aaaaaaaaaaaaaaaa.....|....aaaaaaaaaaaaaaaaaa....'
VN_PAL[hat:kabuto]='a=2a2a34 b=c8a24a'
VN_SEAT[hat:kabuto]=3
VN_BRIM[hat:kabuto]=1
VN_NAME[hat:greathelm]='GREAT HELM'; VN_PRICE[hat:greathelm]=1400; VN_RAR[hat:greathelm]=epic
VN_ART[hat:greathelm]='........aaaaaaaaaa........|.......aaaaaaaaaaaa.......|......aaaaaaaaaaaaaa......|......aaaabbaabbaaaa......|......aaaabbaabbaaaa......|......aaaaaaaaaaaaaa......|......acccccaaccccca......|......acccccaaccccca......|.....bbbbbbbbbbbbbbbb.....|.....bbbbbbbbbbbbbbbb.....'
VN_PAL[hat:greathelm]='a=4e5a6e b=c08a30 c=12141c'
VN_SEAT[hat:greathelm]=3
VN_BRIM[hat:greathelm]=1
VN_NAME[hat:diver]='DIVING HELMET'; VN_PRICE[hat:diver]=1550; VN_RAR[hat:diver]=epic
VN_ART[hat:diver]='............cc............|............cc............|.........aaaaaaaa.........|.......aaaaaaaaaaaa.......|.....aaaaaaaaaaaaaaaa.....|.....aaaabbbbbbbbaaaa.....|.....aaabb...dd.bbaaa.....|.....aaabb...dd.bbaaa.....|.....aaabb......bbaaa.....|.....aaabb......bbaaa.....'
VN_PAL[hat:diver]='a=a8823c b=5e441c c=c86a3a d=f2f6ff'
VN_SEAT[hat:diver]=3
VN_BRIM[hat:diver]=1
VN_NAME[hat:mothership]='MOTHERSHIP'; VN_PRICE[hat:mothership]=1800; VN_RAR[hat:mothership]=legendary
VN_ART[hat:mothership]='..........cccccc..........|........cccccccccc........|.....aaaaaaaaaaaaaaaa.....|...aaaaaaaaaaaaaaaaaaaa...|....abaabaabaabaabaaba....|....abaabaabaabaabaaba....|..........................|..........................|..........................|..........................'
VN_PAL[hat:mothership]='a=38445c b=5fffd7 c=8fa8d0'
VN_SEAT[hat:mothership]=3
VN_BRIM[hat:mothership]=2
VN_NAME[hat:solar]='SOLAR CROWN'; VN_PRICE[hat:solar]=1950; VN_RAR[hat:solar]=legendary
VN_ART[hat:solar]='......b...b.bb.b...b......|......b...b.bb.b...b......|.....bbb.bbbbbbbb.bbb.....|.....bbbbbbbbbbbbbbbb.....|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......|......aaaaaaaaaaaaaa......|.....cccccccccccccccc.....|.....cccccccccccccccc.....'
VN_PAL[hat:solar]='a=ffb03a b=fff0a0 c=c87a18'
VN_SEAT[hat:solar]=3
VN_BRIM[hat:solar]=0
VN_NAME[hat:phoenix]='PHOENIX CREST'; VN_PRICE[hat:phoenix]=2250; VN_RAR[hat:phoenix]=legendary
VN_ART[hat:phoenix]='........c...cc...c........|.......cc...ccc..cc.......|.......bb..bbbb..bb.......|......bbb..bbbb..bbb......|......bbbbbbbbbbbbbb......|......bbbbbbbbbbbbbb......|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....|.....aaaaaaaaaaaaaaaa.....|......aaaaaaaaaaaaaa......'
VN_PAL[hat:phoenix]='a=e04a10 b=ff8c1a c=ffd75f'
VN_SEAT[hat:phoenix]=3
VN_BRIM[hat:phoenix]=0
VN_NAME[hat:saturn]='RING OF SATURN'; VN_PRICE[hat:saturn]=2400; VN_RAR[hat:saturn]=legendary
VN_ART[hat:saturn]='..........aaaaaa...cc.....|.........aaaaaaaa..cc.....|...bbbb..aaaaaaaa..bbbb...|...bbbb.aaaaaaaaaa.bbbb...|...bbbbbbbbbbbbbbbbbbbb...|...bbbbbbbbbbbbbbbbbbbb...|........aaaaaaaaaa........|.........aaaaaaaa.........|..........aaaaaa..........|..........aaaaaa..........'
VN_PAL[hat:saturn]='a=b4762e b=f0e4c0 c=e8e8f2'
VN_SEAT[hat:saturn]=3
VN_BRIM[hat:saturn]=1
VN_R_spec=(round wire rims halfmoon pincenez shades wayfarer aviator cateye mirror rose threed pixel neon heart star xray hypno kaleido monocle patch scouter goggles swim safety snow welder scuba binocs nvg vr laser visitor browline horn clipon blindfold wrap steampunk butterfly opera compound oracle thirdeye nova)
VN_NAME[spec:round]='ROUND SPECS'; VN_PRICE[spec:round]=180; VN_RAR[spec:round]=classic
VN_ART[spec:round]='..........................|.......aaaaa...aaaaa......|......a.....aaa.....a.....|......a.....aaa.....a.....|......a.....a.a.....a.....|......a.....a.a.....a.....|.......aaaaa...aaaaa......|..........................'
VN_PAL[spec:round]='a=1c1f2e'
VN_SEAT[spec:round]=11
VN_NAME[spec:wire]='WIRE FRAMES'; VN_PRICE[spec:wire]=120; VN_RAR[spec:wire]=classic
VN_ART[spec:wire]='.......aaaaa...aaaaa......|..........................|.....aa.....aaa.....aa....|......a.....a.a.....a.....|......a.....a.a.....a.....|......aaaaaaa.aaaaaaa.....'
VN_PAL[spec:wire]='a=c8ad55'
VN_SEAT[spec:wire]=9
VN_NAME[spec:rims]='THICK RIMS'; VN_PRICE[spec:rims]=260; VN_RAR[spec:rims]=classic
VN_ART[spec:rims]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aaggggaaaaaggggaa....|.....aa....aaaaa....aa....|.....aaggggaa.aaggggaa....|.....aa....aa.aa....aa....|.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....'
VN_PAL[spec:rims]='a=2c2c38 g=dde6f8'
VN_SEAT[spec:rims]=11
VN_NAME[spec:halfmoon]='HALF MOONS'; VN_PRICE[spec:halfmoon]=200; VN_RAR[spec:halfmoon]=classic
VN_ART[spec:halfmoon]='......a.....aaa.....a.....|..........................|......aggggga.aggggga.....|......aggggga.aggggga.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:halfmoon]='a=c9a53f g=cfe0ea'
VN_SEAT[spec:halfmoon]=11
VN_NAME[spec:pincenez]='PINCE-NEZ'; VN_PRICE[spec:pincenez]=280; VN_RAR[spec:pincenez]=uncommon
VN_ART[spec:pincenez]='..........................|........aaaa...aaaa.......|.......a....aaa....a......|.......a....aaa....a......|.......a....a.a....a......|.......a....a.a....a......|........aaaa...aaaa.......|..........................'
VN_PAL[spec:pincenez]='a=b8912f'
VN_SEAT[spec:pincenez]=11
VN_NAME[spec:shades]='SUNGLASSES'; VN_PRICE[spec:shades]=180; VN_RAR[spec:shades]=common
VN_ART[spec:shades]='......aaaaaaaaaaaaaaa.....|......aaaaaaaaaaaaaaa.....|......alllllaaallllla.....|......alllllaaallllla.....|......allllla.allllla.....|......allllla.allllla.....'
VN_PAL[spec:shades]='a=3a3a4a l=22222e'
VN_SEAT[spec:shades]=9
VN_NAME[spec:wayfarer]='WAYFARERS'; VN_PRICE[spec:wayfarer]=350; VN_RAR[spec:wayfarer]=uncommon
VN_ART[spec:wayfarer]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aalllllaaalllllaa....|.....aalllllaaalllllaa....|.....aallllla.alllllaa....|.....aallllla.alllllaa....'
VN_PAL[spec:wayfarer]='a=26262f l=3c3c50'
VN_SEAT[spec:wayfarer]=9
VN_NAME[spec:aviator]='AVIATORS'; VN_PRICE[spec:aviator]=490; VN_RAR[spec:aviator]=uncommon
VN_ART[spec:aviator]='......aaaaaaa.aaaaaaa.....|......aaaaaaa.aaaaaaa.....|......alllllaaallllla.....|......alllllaaallllla.....|......allllla.allllla.....|......allllla.allllla.....|.......allla...allla......|..........................'
VN_PAL[spec:aviator]='a=d8b45c l=5a4830'
VN_SEAT[spec:aviator]=11
VN_NAME[spec:cateye]='CAT EYE FRAMES'; VN_PRICE[spec:cateye]=460; VN_RAR[spec:cateye]=uncommon
VN_ART[spec:cateye]='....aaaaaaaaa.aaaaaaaaa...|.....aaaaaaaa.aaaaaaaa....|......a.....aaa.....a.....|......a.....aaa.....a.....|......a.....a.a.....a.....|......a.....a.a.....a.....|.......aaaaaa.aaaaaa......|..........................'
VN_PAL[spec:cateye]='a=e0699c'
VN_SEAT[spec:cateye]=11
VN_NAME[spec:mirror]='MIRRORED'; VN_PRICE[spec:mirror]=720; VN_RAR[spec:mirror]=rare
VN_ART[spec:mirror]='......aaaaaaaaaaaaaaa.....|......aaaaaaaaaaaaaaa.....|......allllcaaallllca.....|......allllcaaallllca.....|......allllla.allllla.....|......allllla.allllla.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:mirror]='a=2a2e3e c=eafbff l=4fc9f0'
VN_SEAT[spec:mirror]=11
VN_NAME[spec:rose]='ROSE TINTED'; VN_PRICE[spec:rose]=320; VN_RAR[spec:rose]=uncommon
VN_ART[spec:rose]='..........................|.......aaaaa...aaaaa......|......alllllaaallllla.....|......a.....aaa.....a.....|......allllla.allllla.....|......a.....a.a.....a.....|.......aaaaa...aaaaa......|..........................'
VN_PAL[spec:rose]='a=9c5348 l=ffc2dd'
VN_SEAT[spec:rose]=11
VN_NAME[spec:threed]='3D GLASSES'; VN_PRICE[spec:threed]=40; VN_RAR[spec:threed]=common
VN_ART[spec:threed]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aarrrrraaacccccaa....|.....aa.....aaa.....aa....|.....aarrrrra.acccccaa....|.....aa.....a.a.....aa....'
VN_PAL[spec:threed]='a=eceff5 c=7ae2ff r=ff7a7a'
VN_SEAT[spec:threed]=9
VN_NAME[spec:pixel]='PIXEL SHADES'; VN_PRICE[spec:pixel]=680; VN_RAR[spec:pixel]=rare
VN_ART[spec:pixel]='.....bbbbbbbbbbbbbbbbb....|.....bbbbbbbbbbbbbbbbb....|.....bbbbbbwbbbbbbbwbb....|.....bbbbbbwbbbbbbbwbb....|.....bbbbbbb...bbbbbbb....|.....bbbbbbb...bbbbbbb....'
VN_PAL[spec:pixel]='b=16161e w=f4f4fa'
VN_SEAT[spec:pixel]=9
VN_NAME[spec:neon]='NEON WAYFARERS'; VN_PRICE[spec:neon]=840; VN_RAR[spec:neon]=rare
VN_ART[spec:neon]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aalllllaaalllllaa....|.....aalllllaaalllllaa....|.....aallllla.alllllaa....|.....aallllla.alllllaa....'
VN_PAL[spec:neon]='a=ff2f9f l=2a0c22'
VN_SEAT[spec:neon]=9
VN_NAME[spec:heart]='HEART SHADES'; VN_PRICE[spec:heart]=600; VN_RAR[spec:heart]=rare
VN_ART[spec:heart]='......aaa.aaa.aaa.aaa.....|......aaa.aaa.aaa.aaa.....|......allllla.allllla.....|......allllla.allllla.....|.......allla...allla......|.......allla...allla......|.........a.......a........|.........a.......a........'
VN_PAL[spec:heart]='a=ff9fc4 l=e0246e'
VN_SEAT[spec:heart]=11
VN_NAME[spec:star]='STAR SHADES'; VN_PRICE[spec:star]=640; VN_RAR[spec:star]=rare
VN_ART[spec:star]='.........a.......a........|.........a.......a........|......aalllaa.aalllaa.....|......aalllaa.aalllaa.....|........aaa.....aaa.......|........aaa.....aaa.......|.......a...a...a...a......|.......a...a...a...a......'
VN_PAL[spec:star]='a=ffd75f l=8a5a10'
VN_SEAT[spec:star]=11
VN_NAME[spec:xray]='X-RAY SPECS'; VN_PRICE[spec:xray]=1300; VN_RAR[spec:xray]=epic
VN_ART[spec:xray]='......aaaaaaa.aaaaaaa.....|......aaaaaaa.aaaaaaa.....|......awwkwwaaawwkwwa.....|......awwkwwaaawwkwwa.....|......awwwwwa.awwwwwa.....|......awwwwwa.awwwwwa.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:xray]='a=c8a24a k=22222b w=f2f2f6'
VN_SEAT[spec:xray]=11
VN_NAME[spec:hypno]='HYPNO SPIRALS'; VN_PRICE[spec:hypno]=1400; VN_RAR[spec:hypno]=epic
VN_ART[spec:hypno]='......aaaaaaa.aaaaaaa.....|......aaaaaaa.aaaaaaa.....|......awvwvwaaawvwvwa.....|......awvwvwaaawvwvwa.....|......avwvwva.avwvwva.....|......avwvwva.avwvwva.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:hypno]='a=3a3a46 v=9f4fff w=f2f2f6'
VN_SEAT[spec:hypno]=11
VN_NAME[spec:kaleido]='KALEIDOSCOPE'; VN_PRICE[spec:kaleido]=1800; VN_RAR[spec:kaleido]=legendary
VN_ART[spec:kaleido]='......aaaaaaa.aaaaaaa.....|......aaaaaaa.aaaaaaa.....|......abcdbcaaacbdcba.....|......abcdbcaaacbdcba.....|......acdbcda.adcbdca.....|......acdbcda.adcbdca.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:kaleido]='a=eceff5 b=ff5f9f c=5fd7ff d=ffd75f'
VN_SEAT[spec:kaleido]=11
VN_NAME[spec:monocle]='MONOCLE'; VN_PRICE[spec:monocle]=520; VN_RAR[spec:monocle]=uncommon
VN_ART[spec:monocle]='...............aaaaa......|..........................|..............a....ga.....|..............a....ga.....|..............a.....ac....|..............a.....ac....|.....................c....|...............aaaaa.c....'
VN_PAL[spec:monocle]='a=e8c46a c=b8952f g=f4f8ff'
VN_SEAT[spec:monocle]=11
VN_NAME[spec:patch]='EYE PATCH'; VN_PRICE[spec:patch]=120; VN_RAR[spec:patch]=common
VN_ART[spec:patch]='.....ppppppppssssssssss...|.....ppppppppssssssssss...|.....pppppppp.............|.....pppppppp.............|.....pppppppp.............|.....pppppppp.............|......ppppppp.............|..........................'
VN_PAL[spec:patch]='p=1c1c24 s=54546a'
VN_SEAT[spec:patch]=11
VN_NAME[spec:scouter]='SCOUTER'; VN_PRICE[spec:scouter]=1150; VN_RAR[spec:scouter]=epic
VN_ART[spec:scouter]='..............aaaaaaaa....|..............aaaaaaaa....|..............agggggaaa...|..............agggggaaa...|..............arrgggaaa...|..............arrgggaaa...|..............aaaaaaaa....|..........................'
VN_PAL[spec:scouter]='a=22222b g=5fff8f r=ff5a4a'
VN_SEAT[spec:scouter]=11
VN_NAME[spec:goggles]='GOGGLES'; VN_PRICE[spec:goggles]=560; VN_RAR[spec:goggles]=uncommon
VN_ART[spec:goggles]='......aaaaaaa.aaaaaaa.....|..........................|....ssagggggaaagggggass...|....ssagggggaaagggggass...|......aggggga.aggggga.....|......aggggga.aggggga.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:goggles]='a=6a4a30 g=8fd0ff s=42301e'
VN_SEAT[spec:goggles]=11
VN_NAME[spec:swim]='SWIM GOGGLES'; VN_PRICE[spec:swim]=380; VN_RAR[spec:swim]=uncommon
VN_ART[spec:swim]='..........................|.......ggggg...ggggg......|....aaagggggaaagggggaaa...|....aaagggggaaagggggaaa...|......aggggga.aggggga.....|......aggggga.aggggga.....|.......ggggg...ggggg......|..........................'
VN_PAL[spec:swim]='a=14508c g=bfe8ff'
VN_SEAT[spec:swim]=11
VN_NAME[spec:safety]='SAFETY GOGGLES'; VN_PRICE[spec:safety]=70; VN_RAR[spec:safety]=common
VN_ART[spec:safety]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aaggggggaggggggaa....|.....aa......a......aa....|.....aaggggggaggggggaa....|.....aa......a......aa....|..........................|.....aaaaaaaaaaaaaaaaa....'
VN_PAL[spec:safety]='a=3f4557 g=f4fcff'
VN_SEAT[spec:safety]=11
VN_NAME[spec:snow]='SNOW GOGGLES'; VN_PRICE[spec:snow]=800; VN_RAR[spec:snow]=rare
VN_ART[spec:snow]='......aaaaaaaaaaaaaaa.....|......aaaaaaaaaaaaaaa.....|....ssalllllllllllllass...|....ssalllllllllllllass...|......allllllllllllla.....|......allllllllllllla.....|......aaaaaaaaaaaaaaa.....|..........................'
VN_PAL[spec:snow]='a=e85f5f l=ffb03a s=b8403c'
VN_SEAT[spec:snow]=11
VN_NAME[spec:welder]='WELDING MASK'; VN_PRICE[spec:welder]=960; VN_RAR[spec:welder]=rare
VN_ART[spec:welder]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aaawwwwwwwwwwwaaa....|.....aaawwwwwwwwwwwaaa....|.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|......aaaaaaaaaaaaaaa.....|..........................'
VN_PAL[spec:welder]='a=5a7053 w=141c14'
VN_SEAT[spec:welder]=11
VN_NAME[spec:scuba]='SCUBA MASK'; VN_PRICE[spec:scuba]=920; VN_RAR[spec:scuba]=rare
VN_ART[spec:scuba]='.....aaaaaaaaaaaaaaaaas...|.....aaaaaaaaaaaaaaaaas...|.....agggggggggggggggas...|.....agggggggggggggggas...|.....agggggggggggggggas...|.....agggggggggggggggas...|.....aaaaaaaaaaaaaaaaas...|......................s...'
VN_PAL[spec:scuba]='a=2b2b34 g=8fd0ff s=ffd75f'
VN_SEAT[spec:scuba]=11
VN_NAME[spec:binocs]='BINOCULARS'; VN_PRICE[spec:binocs]=1000; VN_RAR[spec:binocs]=rare
VN_ART[spec:binocs]='.....aaaaaaaa.aaaaaaaa....|.....aaaaaaaa.aaaaaaaa....|.....aaggggha.agggghaa....|.....aaggggha.agggghaa....|.....aaggggga.agggggaa....|.....aaggggga.agggggaa....|.....aaaaaaaa.aaaaaaaa....|..........................'
VN_PAL[spec:binocs]='a=2b2b34 g=7ac4f0 h=e8f6ff'
VN_SEAT[spec:binocs]=11
VN_NAME[spec:nvg]='NIGHT VISION'; VN_PRICE[spec:nvg]=1100; VN_RAR[spec:nvg]=epic
VN_ART[spec:nvg]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|......agghgga.agghgga.....|......agghgga.agghgga.....|......aggggga.aggggga.....|......aggggga.aggggga.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:nvg]='a=3a4a3a g=5fd76f h=d8ffd8'
VN_SEAT[spec:nvg]=11
VN_NAME[spec:vr]='VR HEADSET'; VN_PRICE[spec:vr]=1550; VN_RAR[spec:vr]=epic
VN_ART[spec:vr]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|....ssaagggggggggggaass...|....ssaagggggggggggaass...|......aagggggggggggaa.....|......aagggggggggggaa.....|.....ccccccccccccccccc....|.....ccccccccccccccccc....'
VN_PAL[spec:vr]='a=33333f c=5fd7ff g=1c1c2e s=22222c'
VN_SEAT[spec:vr]=11
VN_NAME[spec:laser]='LASER VISOR'; VN_PRICE[spec:laser]=1600; VN_RAR[spec:laser]=epic
VN_ART[spec:laser]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|....aarrrrrrhhhrrrrrraa...|....aarrrrrrhhhrrrrrraa...|.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....'
VN_PAL[spec:laser]='a=2e2e3a h=ffd6a8 r=ff3a3a'
VN_SEAT[spec:laser]=9
VN_NAME[spec:visitor]='VISITOR'\''S OWN'; VN_PRICE[spec:visitor]=2400; VN_RAR[spec:visitor]=legendary
VN_ART[spec:visitor]='..........................|.......aaaaa...aaaaa......|......abcdcbaaabcdcba.....|......abcdcbaaabcdcba.....|......acdbdca.acdbdca.....|......acdbdca.acdbdca.....|.......aaaaa...aaaaa......|..........................'
VN_PAL[spec:visitor]='a=7a5cff b=2af598 c=08f7fe d=ff6ec7'
VN_SEAT[spec:visitor]=11
VN_NAME[spec:browline]='BROWLINE'; VN_PRICE[spec:browline]=150; VN_RAR[spec:browline]=classic
VN_ART[spec:browline]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|......w.....aaa.....w.....|......w.....aaa.....w.....|......w.....w.w.....w.....|......w.....w.w.....w.....|......wwwwwww.wwwwwww.....|..........................'
VN_PAL[spec:browline]='a=2a2a30 w=dcc9a4'
VN_SEAT[spec:browline]=11
VN_NAME[spec:horn]='HORN RIMS'; VN_PRICE[spec:horn]=230; VN_RAR[spec:horn]=classic
VN_ART[spec:horn]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|.....aa....aaaaa....aa....|.....aa....aaaaa....aa....|.....bb....bb.bb....bb....|.....bb....bb.bb....bb....|.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....'
VN_PAL[spec:horn]='a=4a3020 b=a86a30'
VN_SEAT[spec:horn]=11
VN_NAME[spec:clipon]='CLIP-ONS'; VN_PRICE[spec:clipon]=100; VN_RAR[spec:clipon]=common
VN_ART[spec:clipon]='......ccccccccccccccc.....|......ccccccccccccccc.....|......a.....aaa.....a.....|......a.....aaa.....a.....|......a.....a.a.....a.....|......a.....a.a.....a.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:clipon]='a=2a2a34 c=3f6a44'
VN_SEAT[spec:clipon]=11
VN_NAME[spec:blindfold]='BLINDFOLD'; VN_PRICE[spec:blindfold]=150; VN_RAR[spec:blindfold]=common
VN_ART[spec:blindfold]='.....bbbbbbbbbbbbbbbbb....|..........................|....bbbbbbbbbbbbbbbbbbb...|....bbbbbbbbbbbbbbbbbbb...|...kkbbbbbbbbbbbbbbbbbb...|...kkbbbbbbbbbbbbbbbbbb...|......bbbbbbbbbbbbbbb.....|..........................'
VN_PAL[spec:blindfold]='b=33333f k=565670'
VN_SEAT[spec:blindfold]=11
VN_NAME[spec:wrap]='SPORT WRAPS'; VN_PRICE[spec:wrap]=420; VN_RAR[spec:wrap]=uncommon
VN_ART[spec:wrap]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|....allllllllllllllllla...|....allllllllllllllllla...|.....lllllllllllllllll....|......lllllllllllllll.....'
VN_PAL[spec:wrap]='a=2a2a34 l=ff7a2a'
VN_SEAT[spec:wrap]=9
VN_NAME[spec:steampunk]='STEAMPUNK GOGGLES'; VN_PRICE[spec:steampunk]=760; VN_RAR[spec:steampunk]=rare
VN_ART[spec:steampunk]='......aaaaaa...aaaaaa.....|..........................|.....aaggggaa.aaggggaa....|.....aaggggaa.aaggggaa....|.....ccggggcc.ccggggcc....|.....ccggggcc.ccggggcc....|.....aaaaaaaa.aaaaaaaa....|..........................'
VN_PAL[spec:steampunk]='a=b98a3a c=7a5a2a g=e0c060'
VN_SEAT[spec:steampunk]=11
VN_NAME[spec:butterfly]='BUTTERFLY FRAMES'; VN_PRICE[spec:butterfly]=880; VN_RAR[spec:butterfly]=rare
VN_ART[spec:butterfly]='....bbbaaaaaaaaaaaaabbb...|....bbb.............bbb...|....aaa....aaaaa....aaa...|....aaa....aaaaa....aaa...|.....aa....aa.aa....aa....|.....aa....aa.aa....aa....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:butterfly]='a=e04a8a b=ffd0e4'
VN_SEAT[spec:butterfly]=11
VN_NAME[spec:opera]='OPERA GLASSES'; VN_PRICE[spec:opera]=1250; VN_RAR[spec:opera]=epic
VN_ART[spec:opera]='......aaaaaaa.aaaaaaa.....|......aaaaaaa.aaaaaaa.....|......aggggga.aggggga.....|......aggggga.aggggga.....|......aggggga.aggggga.....|......aggggga.aggggga.....|......aaaaaaa.aaaaaaaa....|.....................a....'
VN_PAL[spec:opera]='a=e8c46a g=5a2a44'
VN_SEAT[spec:opera]=11
VN_NAME[spec:compound]='COMPOUND EYES'; VN_PRICE[spec:compound]=1450; VN_RAR[spec:compound]=epic
VN_ART[spec:compound]='.....kkkkkkkk.kkkkkkkk....|.....kkkkkkkk.kkkkkkkk....|.....kabababk.kbababak....|.....kabababk.kbababak....|.....kbababak.kabababk....|.....kbababak.kabababk....|......kkkkkkk.kkkkkkk.....|..........................'
VN_PAL[spec:compound]='a=7aff5f b=2f8a3a k=1e3a1e'
VN_SEAT[spec:compound]=11
VN_NAME[spec:oracle]='ORACLE'\''S LENSES'; VN_PRICE[spec:oracle]=1950; VN_RAR[spec:oracle]=legendary
VN_ART[spec:oracle]='..........................|.......aaaaa...aaaaa......|......agghggaaagghgga.....|......agghggaaagghgga.....|......aggggga.aggggga.....|......aggggga.aggggga.....|.......aaaaa...aaaaa......|..........................'
VN_PAL[spec:oracle]='a=e8c46a g=8f5cff h=fff0b0'
VN_SEAT[spec:oracle]=11
VN_NAME[spec:thirdeye]='THE THIRD EYE'; VN_PRICE[spec:thirdeye]=2100; VN_RAR[spec:thirdeye]=legendary
VN_ART[spec:thirdeye]='......aaaaaackcaaaaaa.....|............ckc...........|......a.....a.a.....a.....|......a.....a.a.....a.....|......a.....a.a.....a.....|......a.....a.a.....a.....|......aaaaaaa.aaaaaaa.....|..........................'
VN_PAL[spec:thirdeye]='a=3a3a50 c=ffd75f k=2a1a08'
VN_SEAT[spec:thirdeye]=11
VN_NAME[spec:nova]='SUPERNOVA SHADES'; VN_PRICE[spec:nova]=2250; VN_RAR[spec:nova]=legendary
VN_ART[spec:nova]='.....aaaaaaaaaaaaaaaaa....|.....aaaaaaaaaaaaaaaaa....|....caabccbaaaaabccbaac...|....caabccbaaaaabccbaac...|.....aabbbbaa.aabbbbaa....|.....aabbbbaa.aabbbbaa....|.....aaaaaaaa.aaaaaaaa....|..........................'
VN_PAL[spec:nova]='a=ff3a6a b=ffb03a c=fff4c0'
VN_SEAT[spec:nova]=11
VN_R_smoke=(cig candy cigar pipe churchwarden peace bubbles incense vape chaser hookah joint blunt cosmic match clove briar cigarillo holder meerschaum rollie calabash dugout bong rig dragon eternal)
VN_NAME[smoke:cig]='CIGARETTE'; VN_PRICE[smoke:cig]=70; VN_RAR[smoke:cig]=common
VN_ART[smoke:cig]='..............ffgaaaae....|..............ffgaaaae....'
VN_PAL[smoke:cig]='a=f4f4f8 e=ff7a3a f=5a3f22 g=c8a24a'
VN_SEAT[smoke:cig]=13
VN_GLOW[smoke:cig]=ff7a3a
VN_EVERY[smoke:cig]=2; VN_FROMH[smoke:cig]=1
VN_RAMP[smoke:cig]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:candy]='CANDY CIGARETTE'; VN_PRICE[smoke:candy]=40; VN_RAR[smoke:candy]=common
VN_ART[smoke:candy]='..............bbppppptt...|..............bbppppptt...'
VN_PAL[smoke:candy]='b=8e1f33 p=fdf6f2 t=ff5f7a'
VN_SEAT[smoke:candy]=13
VN_EVERY[smoke:candy]=4; VN_FROMH[smoke:candy]=1
VN_RAMP[smoke:candy]='fff0f6 ffdcea fbc4d9 eda8c0 d68ca6 b8728c 985c74 78485c 5a3646'
VN_NAME[smoke:cigar]='CIGAR'; VN_PRICE[smoke:cigar]=560; VN_RAR[smoke:cigar]=uncommon
VN_ART[smoke:cigar]='.................wllle....|.................wllle....|..............lllwllle....|..............lllwllle....'
VN_PAL[smoke:cigar]='e=ff7a3a l=5a3a22 w=e8dcc4'
VN_SEAT[smoke:cigar]=13
VN_GLOW[smoke:cigar]=ff7a3a
VN_EVERY[smoke:cigar]=3; VN_FROMH[smoke:cigar]=2
VN_RAMP[smoke:cigar]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:pipe]='CORN COB PIPE'; VN_PRICE[smoke:pipe]=180; VN_RAR[smoke:pipe]=common
VN_ART[smoke:pipe]='...................cec....|...................cec....|..............sssssccc....|..............sssssccc....'
VN_PAL[smoke:pipe]='c=ecd074 e=ff8a3a s=4a3420'
VN_SEAT[smoke:pipe]=13
VN_GLOW[smoke:pipe]=ff8a3a
VN_EVERY[smoke:pipe]=3; VN_FROMH[smoke:pipe]=2
VN_RAMP[smoke:pipe]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:churchwarden]='CHURCHWARDEN'; VN_PRICE[smoke:churchwarden]=600; VN_RAR[smoke:churchwarden]=rare
VN_ART[smoke:churchwarden]='....................ee....|....................ee....|..............sssssscc....|..............sssssscc....'
VN_PAL[smoke:churchwarden]='c=8a5730 e=ff7a3a s=241a12'
VN_SEAT[smoke:churchwarden]=13
VN_GLOW[smoke:churchwarden]=ff7a3a
VN_EVERY[smoke:churchwarden]=4; VN_FROMH[smoke:churchwarden]=1
VN_RAMP[smoke:churchwarden]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:peace]='PEACE PIPE'; VN_PRICE[smoke:peace]=660; VN_RAR[smoke:peace]=rare
VN_ART[smoke:peace]='....................ee....|....................ee....|..............bwbwbwrr....|..............bwbwbwrr....'
VN_PAL[smoke:peace]='b=3a2a20 e=ff8a3a r=a8452c w=c8a878'
VN_SEAT[smoke:peace]=13
VN_GLOW[smoke:peace]=ff8a3a
VN_EVERY[smoke:peace]=3; VN_FROMH[smoke:peace]=1
VN_RAMP[smoke:peace]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:bubbles]='BUBBLE PIPE'; VN_PRICE[smoke:bubbles]=120; VN_RAR[smoke:bubbles]=common
VN_ART[smoke:bubbles]='....................u.....|....................u.....|..............cccccwww....|..............cccccwww....'
VN_PAL[smoke:bubbles]='c=1e6f96 u=bfe8ff w=f4f8fc'
VN_SEAT[smoke:bubbles]=13
VN_EVERY[smoke:bubbles]=3; VN_FROMH[smoke:bubbles]=1
VN_RAMP[smoke:bubbles]='f0fcff dcf5ff c4ecff aee1fa 98d4f2 82c5e8 6eb4dc 5ca2ce 4c90be'
VN_NAME[smoke:incense]='INCENSE STICK'; VN_PRICE[smoke:incense]=280; VN_RAR[smoke:incense]=uncommon
VN_ART[smoke:incense]='..............ssssssse....|..............ssssssse....'
VN_PAL[smoke:incense]='e=ff5f3a s=3f2a1e'
VN_SEAT[smoke:incense]=13
VN_GLOW[smoke:incense]=ff5f3a
VN_EVERY[smoke:incense]=4; VN_FROMH[smoke:incense]=1
VN_RAMP[smoke:incense]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:vape]='VAPE PEN'; VN_PRICE[smoke:vape]=420; VN_RAR[smoke:vape]=uncommon
VN_ART[smoke:vape]='..............kkjjjkkl....|..............kkjjjkkl....'
VN_PAL[smoke:vape]='j=e0a83a k=1e1e26 l=5fd7ff'
VN_SEAT[smoke:vape]=13
VN_GLOW[smoke:vape]=5fd7ff
VN_EVERY[smoke:vape]=2; VN_FROMH[smoke:vape]=1
VN_RAMP[smoke:vape]='f2f7fb dde8f1 c4d4e0 a9bccb 8fa2b3 75889a 5e7082 4a5a6a 3a4653'
VN_NAME[smoke:chaser]='CLOUD CHASER'; VN_PRICE[smoke:chaser]=800; VN_RAR[smoke:chaser]=rare
VN_ART[smoke:chaser]='.................kkvvk....|.................kkvvk....|..............kkkkkvvk....|..............kkkkkvvk....'
VN_PAL[smoke:chaser]='k=16161d v=a97bff'
VN_SEAT[smoke:chaser]=13
VN_GLOW[smoke:chaser]=a97bff
VN_EVERY[smoke:chaser]=1; VN_FROMH[smoke:chaser]=2
VN_RAMP[smoke:chaser]='f2f7fb dde8f1 c4d4e0 a9bccb 8fa2b3 75889a 5e7082 4a5a6a 3a4653'
VN_NAME[smoke:hookah]='HOOKAH HOSE'; VN_PRICE[smoke:hookah]=1350; VN_RAR[smoke:hookah]=epic
VN_ART[smoke:hookah]='..............pgpgpgpgpg..|..............pgpgpgpgpg..'
VN_PAL[smoke:hookah]='g=e0b95a p=7a2050'
VN_SEAT[smoke:hookah]=13
VN_EVERY[smoke:hookah]=2; VN_FROMH[smoke:hookah]=1
VN_RAMP[smoke:hookah]='fff0f6 ffdcea fbc4d9 eda8c0 d68ca6 b8728c 985c74 78485c 5a3646'
VN_NAME[smoke:joint]='JOINT'; VN_PRICE[smoke:joint]=1000; VN_RAR[smoke:joint]=rare
VN_ART[smoke:joint]='...................ppe....|...................ppe....|..............rrpppppe....|..............rrpppppe....'
VN_PAL[smoke:joint]='e=ff5f2a p=f0e8d0 r=7a5228'
VN_SEAT[smoke:joint]=13
VN_GLOW[smoke:joint]=ff5f2a
VN_EVERY[smoke:joint]=2; VN_FROMH[smoke:joint]=2
VN_RAMP[smoke:joint]='eaf0dc d8e2c4 c0cda9 a6b48f 8c9a76 73805f 5c684c 48523c 37402f'
VN_NAME[smoke:blunt]='BLUNT'; VN_PRICE[smoke:blunt]=940; VN_RAR[smoke:blunt]=rare
VN_ART[smoke:blunt]='.................wwwe.....|.................wwwe.....|..............wwwwwwe.....|..............wwwwwwe.....'
VN_PAL[smoke:blunt]='e=ff5f2a w=2e2016'
VN_SEAT[smoke:blunt]=13
VN_GLOW[smoke:blunt]=ff5f2a
VN_EVERY[smoke:blunt]=3; VN_FROMH[smoke:blunt]=2
VN_RAMP[smoke:blunt]='eaf0dc d8e2c4 c0cda9 a6b48f 8c9a76 73805f 5c684c 48523c 37402f'
VN_NAME[smoke:cosmic]='COSMIC JOINT'; VN_PRICE[smoke:cosmic]=2100; VN_RAR[smoke:cosmic]=legendary
VN_ART[smoke:cosmic]='..............rrpspspe....|..............rrpspspe....'
VN_PAL[smoke:cosmic]='e=af87ff p=e8e2fa r=2e1a4a s=5ff5f8'
VN_SEAT[smoke:cosmic]=13
VN_GLOW[smoke:cosmic]=af87ff
VN_EVERY[smoke:cosmic]=2; VN_FROMH[smoke:cosmic]=1
VN_RAMP[smoke:cosmic]='9dffd8 6ff8f2 63d9ff 9f9cff d78dff ff92cf a97fc8 6f5f9e 4a4570'
VN_NAME[smoke:match]='MATCHSTICK'; VN_PRICE[smoke:match]=100; VN_RAR[smoke:match]=common
VN_ART[smoke:match]='..............wwwwkh......|..............wwwwkh......'
VN_PAL[smoke:match]='h=ffb03a k=1a1410 w=7a3226'
VN_SEAT[smoke:match]=13
VN_GLOW[smoke:match]=ffb03a
VN_EVERY[smoke:match]=3; VN_FROMH[smoke:match]=1
VN_RAMP[smoke:match]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:clove]='CLOVE CIGARETTE'; VN_PRICE[smoke:clove]=150; VN_RAR[smoke:clove]=common
VN_ART[smoke:clove]='..............fffkkkke....|..............fffkkkke....'
VN_PAL[smoke:clove]='e=ff7a3a f=6a4620 k=241811'
VN_SEAT[smoke:clove]=13
VN_GLOW[smoke:clove]=ff7a3a
VN_EVERY[smoke:clove]=3; VN_FROMH[smoke:clove]=1
VN_RAMP[smoke:clove]='fff0f6 ffdcea fbc4d9 eda8c0 d68ca6 b8728c 985c74 78485c 5a3646'
VN_NAME[smoke:briar]='BRIAR PIPE'; VN_PRICE[smoke:briar]=120; VN_RAR[smoke:briar]=classic
VN_ART[smoke:briar]='...................ee.....|...................ee.....|..............ssssccccc...|..............ssssccccc...'
VN_PAL[smoke:briar]='c=8a5730 e=ff7a3a s=2e2016'
VN_SEAT[smoke:briar]=13
VN_GLOW[smoke:briar]=ff7a3a
VN_EVERY[smoke:briar]=3; VN_FROMH[smoke:briar]=2
VN_RAMP[smoke:briar]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:cigarillo]='CIGARILLO'; VN_PRICE[smoke:cigarillo]=190; VN_RAR[smoke:cigarillo]=classic
VN_ART[smoke:cigarillo]='..............llllle......|..............llllle......'
VN_PAL[smoke:cigarillo]='e=ff7a3a l=3a2418'
VN_SEAT[smoke:cigarillo]=13
VN_GLOW[smoke:cigarillo]=ff7a3a
VN_EVERY[smoke:cigarillo]=2; VN_FROMH[smoke:cigarillo]=1
VN_RAMP[smoke:cigarillo]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:holder]='CIGARETTE HOLDER'; VN_PRICE[smoke:holder]=260; VN_RAR[smoke:holder]=classic
VN_ART[smoke:holder]='..................ggae....|..................ggae....|..............hhhh........|..............hhhh........'
VN_PAL[smoke:holder]='a=f4f4f8 e=ff7a3a g=d8b054 h=14141a'
VN_SEAT[smoke:holder]=13
VN_GLOW[smoke:holder]=ff7a3a
VN_EVERY[smoke:holder]=3; VN_FROMH[smoke:holder]=2
VN_RAMP[smoke:holder]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:meerschaum]='MEERSCHAUM'; VN_PRICE[smoke:meerschaum]=350; VN_RAR[smoke:meerschaum]=uncommon
VN_ART[smoke:meerschaum]='..................mmemm...|..................mmemm...|..............aaaaammmm...|..............aaaaammmm...'
VN_PAL[smoke:meerschaum]='a=5a3a1a e=ff7a3a m=f0e8d8'
VN_SEAT[smoke:meerschaum]=13
VN_GLOW[smoke:meerschaum]=ff7a3a
VN_EVERY[smoke:meerschaum]=3; VN_FROMH[smoke:meerschaum]=2
VN_RAMP[smoke:meerschaum]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:rollie]='HAND ROLLED'; VN_PRICE[smoke:rollie]=490; VN_RAR[smoke:rollie]=uncommon
VN_ART[smoke:rollie]='..................pp......|..................pp......|..............rrppppe.....|..............rrppppe.....'
VN_PAL[smoke:rollie]='e=ff5f2a p=e8dcc0 r=7a5228'
VN_SEAT[smoke:rollie]=13
VN_GLOW[smoke:rollie]=ff5f2a
VN_EVERY[smoke:rollie]=3; VN_FROMH[smoke:rollie]=2
VN_RAMP[smoke:rollie]='eaf0dc d8e2c4 c0cda9 a6b48f 8c9a76 73805f 5c684c 48523c 37402f'
VN_NAME[smoke:calabash]='CALABASH'; VN_PRICE[smoke:calabash]=740; VN_RAR[smoke:calabash]=rare
VN_ART[smoke:calabash]='..................weew....|..................weew....|..............sssssg......|..............sssssg......'
VN_PAL[smoke:calabash]='e=ff7a3a g=b8893a s=2e2016 w=f0e8d8'
VN_SEAT[smoke:calabash]=13
VN_GLOW[smoke:calabash]=ff7a3a
VN_EVERY[smoke:calabash]=4; VN_FROMH[smoke:calabash]=2
VN_RAMP[smoke:calabash]='efe8df ddd4c9 c6bcb1 aca298 948a81 7a7269 635c55 4e4843 3a3632'
VN_NAME[smoke:dugout]='DUGOUT'; VN_PRICE[smoke:dugout]=860; VN_RAR[smoke:dugout]=rare
VN_ART[smoke:dugout]='..............kbe.........|..............kbe.........'
VN_PAL[smoke:dugout]='b=c8a24a e=ff5f2a k=22222a'
VN_SEAT[smoke:dugout]=13
VN_GLOW[smoke:dugout]=ff5f2a
VN_EVERY[smoke:dugout]=4; VN_FROMH[smoke:dugout]=0
VN_RAMP[smoke:dugout]='eaf0dc d8e2c4 c0cda9 a6b48f 8c9a76 73805f 5c684c 48523c 37402f'
VN_NAME[smoke:bong]='BONG'; VN_PRICE[smoke:bong]=1100; VN_RAR[smoke:bong]=epic
VN_ART[smoke:bong]='..................gggg....|..................gggg....|..............kkkwwwww....|..............kkkwwwww....'
VN_PAL[smoke:bong]='g=8fa8bc k=1c2228 w=5fe0f8'
VN_SEAT[smoke:bong]=13
VN_GLOW[smoke:bong]=5fe0f8
VN_EVERY[smoke:bong]=2; VN_FROMH[smoke:bong]=2
VN_RAMP[smoke:bong]='f0fcff dcf5ff c4ecff aee1fa 98d4f2 82c5e8 6eb4dc 5ca2ce 4c90be'
VN_NAME[smoke:rig]='DAB RIG'; VN_PRICE[smoke:rig]=1600; VN_RAR[smoke:rig]=epic
VN_ART[smoke:rig]='...................gg.....|...................gg.....|..............kkkqgggg....|..............kkkqgggg....'
VN_PAL[smoke:rig]='g=5f8299 k=1a1a22 q=b07aff'
VN_SEAT[smoke:rig]=13
VN_GLOW[smoke:rig]=b07aff
VN_EVERY[smoke:rig]=2; VN_FROMH[smoke:rig]=2
VN_RAMP[smoke:rig]='f2f7fb dde8f1 c4d4e0 a9bccb 8fa2b3 75889a 5e7082 4a5a6a 3a4653'
VN_NAME[smoke:dragon]='DRAGON'\''S BREATH'; VN_PRICE[smoke:dragon]=1800; VN_RAR[smoke:dragon]=legendary
VN_ART[smoke:dragon]='...................fff....|...................fff....|..............ssshhhff....|..............ssshhhff....'
VN_PAL[smoke:dragon]='f=ff4a12 h=8a4a1a s=1e1410'
VN_SEAT[smoke:dragon]=13
VN_GLOW[smoke:dragon]=ff4a12
VN_EVERY[smoke:dragon]=2; VN_FROMH[smoke:dragon]=2
VN_RAMP[smoke:dragon]='ffe3ac ffb45e ff8434 e75f22 c04418 953012 6c210d 4a1608 2e0e05'
VN_NAME[smoke:eternal]='ETERNAL EMBER'; VN_PRICE[smoke:eternal]=2400; VN_RAR[smoke:eternal]=legendary
VN_ART[smoke:eternal]='..............kkkkhoh.....|..............kkkkhoh.....'
VN_PAL[smoke:eternal]='h=ffa02a k=2a2620 o=fff4c0'
VN_SEAT[smoke:eternal]=13
VN_GLOW[smoke:eternal]=ffd75f
VN_EVERY[smoke:eternal]=4; VN_FROMH[smoke:eternal]=1
VN_RAMP[smoke:eternal]='fff6cc ffe89a f8d066 ddb247 bb9235 987428 75581d 564014 3b2c0e'
VN_R_aura=(fire rain earth air snow storm fog sand blossom sunbeams aurora stardust comet blackhole meteor warp nebula souls sigil hex radioactive glitch plasma shadow drizzle static fireflies motes leaves ice crystal supernova rift fireworks galaxy)
VN_NAME[aura:fire]='FIRE'; VN_PRICE[aura:fire]=860; VN_RAR[aura:fire]=rare
VN_FAMILY[aura:fire]='classic'; VN_NOTE[aura:fire]='hottest at the floor and cooling as it climbs · four columns of it are light sources, so the flames warm each other and him'
VN_LIT[aura:fire]='0 48 ff6a12 0.3 up'
VN_NAME[aura:rain]='RAIN'; VN_PRICE[aura:rain]=640; VN_RAR[aura:rain]=rare
VN_FAMILY[aura:rain]='classic'; VN_NOTE[aura:rain]='every drop a two-cell streak, every streak lit off the same sun he is · the floor stays wet'
VN_LIT[aura:rain]='0 48 4a7fb0 0.1 all'
VN_NAME[aura:earth]='EARTH'; VN_PRICE[aura:earth]=780; VN_RAR[aura:earth]=rare
VN_FAMILY[aura:earth]='classic'; VN_NOTE[aura:earth]='stones adrift — the big ones carry a lit cap and a shadowed underside, which is the difference between a rock and a rectangle'
VN_LIT[aura:earth]='0 48 8a6a52 0.08 up'
VN_NAME[aura:air]='AIR'; VN_PRICE[aura:air]=600; VN_RAR[aura:air]=rare
VN_FAMILY[aura:air]='classic'; VN_NOTE[aura:air]='four-cell streaks fading off their own tails, and three leaves tumbling through them · all of it lit, none of it lighting'
VN_LIT[aura:air]='0 48 8fb0c0 0.08 all'
VN_NAME[aura:snow]='SNOWFALL'; VN_PRICE[aura:snow]=560; VN_RAR[aura:snow]=uncommon
VN_FAMILY[aura:snow]='weather'; VN_NOTE[aura:snow]='flakes drifting down and a line of it settled along the floor — every flake shaded by where it is under the sun, which is why the far ones read as far'
VN_LIT[aura:snow]='0 48 b8c6d4 0.12 all'
VN_NAME[aura:storm]='THUNDERSTORM'; VN_PRICE[aura:storm]=1500; VN_RAR[aura:storm]=epic
VN_FAMILY[aura:storm]='weather'; VN_NOTE[aura:storm]='a cloud lit on top and black underneath, rain out of its belly — and when the bolt falls it lights the cloud back, from below'
VN_LIT[aura:storm]='0 48 3d3d50 0.12 down;34 38 dfe8ff 0.45 all'
VN_NAME[aura:fog]='FOG BANK'; VN_PRICE[aura:fog]=280; VN_RAR[aura:fog]=uncommon
VN_FAMILY[aura:fog]='weather'; VN_NOTE[aura:fog]='four banks at four speeds, each one brighter where the sun is and grey where it is not · the thickest of it passes in front of him'
VN_LIT[aura:fog]='0 48 8a8a98 0.18 all'
VN_NAME[aura:sand]='SANDSTORM'; VN_PRICE[aura:sand]=740; VN_RAR[aura:sand]=rare
VN_FAMILY[aura:sand]='weather'; VN_NOTE[aura:sand]='grit driving across the field, thicker at his feet · lit like the grain of sand it is'
VN_LIT[aura:sand]='0 48 c9a86a 0.16 all'
VN_NAME[aura:blossom]='CHERRY BLOSSOM'; VN_PRICE[aura:blossom]=960; VN_RAR[aura:blossom]=rare
VN_FAMILY[aura:blossom]='weather'; VN_NOTE[aura:blossom]='the glyph turns as the petal falls, and the sun decides how pink it is on the way down'
VN_LIT[aura:blossom]='0 48 ff87b0 0.07 all'
VN_NAME[aura:sunbeams]='SUNBEAMS'; VN_PRICE[aura:sunbeams]=820; VN_RAR[aura:sunbeams]=rare
VN_FAMILY[aura:sunbeams]='weather'; VN_NOTE[aura:sunbeams]='rays off the suite'\''s own sun in the top right — brightest at the corner it comes from, spent by the time they reach the far one'
VN_LIT[aura:sunbeams]='0 48 e8c46a 0.16 down'
VN_NAME[aura:aurora]='AURORA'; VN_PRICE[aura:aurora]=1800; VN_RAR[aura:aurora]=legendary
VN_FAMILY[aura:aurora]='cosmic'; VN_NOTE[aura:aurora]='the house'\''s own sweep hung over him as curtains — each one bright along its bottom fringe and dim above it, the way the real ones are'
VN_LIT[aura:aurora]='0 12 2af598 0.14 down;12 24 08f7fe 0.14 down;24 36 7a5cff 0.14 down;36 48 ff6ec7 0.14 down'
VN_NAME[aura:stardust]='STARDUST'; VN_PRICE[aura:stardust]=1150; VN_RAR[aura:stardust]=epic
VN_FAMILY[aura:stardust]='cosmic'; VN_NOTE[aura:stardust]='seven specks on one orbit, each dragging a dim trail and each a little light of its own — in front of him on the near half, behind on the far'
VN_LIT[aura:stardust]='0 48 8fd0ff 0.06 all'
VN_NAME[aura:comet]='COMET'; VN_PRICE[aura:comet]=1350; VN_RAR[aura:comet]=epic
VN_FAMILY[aura:comet]='cosmic'; VN_NOTE[aura:comet]='a field of stars twinkling on their own clocks — and once a loop a head crosses it bright enough to light its own tail'
VN_LIT[aura:comet]='0 48 8fb8e8 0.06 all'
VN_NAME[aura:blackhole]='BLACK HOLE'; VN_PRICE[aura:blackhole]=2300; VN_RAR[aura:blackhole]=legendary
VN_FAMILY[aura:blackhole]='cosmic'; VN_NOTE[aura:blackhole]='an Einstein ring lensed right round him with one hot spot travelling it, and six stars falling in · the singularity is behind his head, which is the only place a black hole is ever seen from'
VN_LIT[aura:blackhole]='0 48 af87ff 0.12 all'
VN_NAME[aura:meteor]='METEOR SHOWER'; VN_PRICE[aura:meteor]=1300; VN_RAR[aura:meteor]=epic
VN_FAMILY[aura:meteor]='cosmic'; VN_NOTE[aura:meteor]='six of them out of the top right, one behind the other · each head lights the tail it is dragging'
VN_LIT[aura:meteor]='0 48 ffd0a0 0.08 down'
VN_NAME[aura:warp]='WARP DRIVE'; VN_PRICE[aura:warp]=1550; VN_RAR[aura:warp]=epic
VN_FAMILY[aura:warp]='cosmic'; VN_NOTE[aura:warp]='the field stretching away from a point behind him — the streaks widen and cool as they leave, and the point itself still glows'
VN_LIT[aura:warp]='0 48 5fd7ff 0.1 all'
VN_NAME[aura:nebula]='NEBULA'; VN_PRICE[aura:nebula]=1200; VN_RAR[aura:nebula]=epic
VN_FAMILY[aura:nebula]='cosmic'; VN_NOTE[aura:nebula]='three waves out of phase, with one young star buried in the cloud lighting everything within seven cells of itself'
VN_LIT[aura:nebula]='0 48 a04ac8 0.12 all'
VN_NAME[aura:souls]='SOUL WISPS'; VN_PRICE[aura:souls]=1250; VN_RAR[aura:souls]=epic
VN_FAMILY[aura:souls]='cursed'; VN_NOTE[aura:souls]='little flames off the floor, each one wandering on its own and each one lighting the air it passes through until it burns out'
VN_LIT[aura:souls]='0 48 7affc0 0.14 up'
VN_NAME[aura:sigil]='SIGIL RING'; VN_PRICE[aura:sigil]=1400; VN_RAR[aura:sigil]=epic
VN_FAMILY[aura:sigil]='cursed'; VN_NOTE[aura:sigil]='eight marks turning around him · the lit one and the one behind it are real light, so the ring brightens ahead of itself'
VN_LIT[aura:sigil]='0 48 ffe98a 0.1 all'
VN_NAME[aura:hex]='HEX TENDRILS'; VN_PRICE[aura:hex]=1100; VN_RAR[aura:hex]=epic
VN_FAMILY[aura:hex]='cursed'; VN_NOTE[aura:hex]='six tendrils out of the floor, each with a lit tip that carries its own glow up with it and takes it back down again'
VN_LIT[aura:hex]='0 48 8f2fd0 0.16 up'
VN_NAME[aura:radioactive]='RADIOACTIVE'; VN_PRICE[aura:radioactive]=1000; VN_RAR[aura:radioactive]=rare
VN_FAMILY[aura:radioactive]='cursed'; VN_NOTE[aura:radioactive]='a pool that bubbles and lights the drip coming down into it · once a loop the whole floor flares and the light goes with it'
VN_LIT[aura:radioactive]='0 48 7fff3a 0.16 up'
VN_NAME[aura:glitch]='GLITCH'; VN_PRICE[aura:glitch]=1450; VN_RAR[aura:glitch]=epic
VN_FAMILY[aura:glitch]='cursed'; VN_NOTE[aura:glitch]='cells failing at random — deterministically random · once a loop a row tears open and the whole field flashes through it'
VN_LIT[aura:glitch]=''
VN_NAME[aura:plasma]='PLASMA ARCS'; VN_PRICE[aura:plasma]=1600; VN_RAR[aura:plasma]=epic
VN_FAMILY[aura:plasma]='cursed'; VN_NOTE[aura:plasma]='two arcs re-struck every six frames, never the same path twice a loop · each one lights the air around its own middle'
VN_LIT[aura:plasma]='0 48 8fb8ff 0.12 all'
VN_NAME[aura:shadow]='SHADOW POOL'; VN_PRICE[aura:shadow]=920; VN_RAR[aura:shadow]=rare
VN_FAMILY[aura:shadow]='cursed'; VN_NOTE[aura:shadow]='something under him, breathing · the pool is a light source with a black colour, which is the only way a grid of glyphs can have a shadow'
VN_LIT[aura:shadow]='0 48 1a1424 0.26 up'
VN_NAME[aura:drizzle]='DRIZZLE'; VN_PRICE[aura:drizzle]=40; VN_RAR[aura:drizzle]=common
VN_FAMILY[aura:drizzle]='weather'; VN_NOTE[aura:drizzle]='four lanes and one drop in each · no pool, no light, nothing settled — the cheapest weather on the rack, and the one that shows you what a field is'
VN_LIT[aura:drizzle]='0 48 5f88a8 0.06 all'
VN_NAME[aura:static]='STATIC'; VN_PRICE[aura:static]=180; VN_RAR[aura:static]=common
VN_FAMILY[aura:static]='cursed'; VN_NOTE[aura:static]='a dozen specks that are there for a frame and gone the next, and never in the same place twice in a loop · a bad signal, drawn honestly'
VN_LIT[aura:static]='0 48 a8a8c0 0.05 all'
VN_NAME[aura:fireflies]='FIREFLIES'; VN_PRICE[aura:fireflies]=370; VN_RAR[aura:fireflies]=uncommon
VN_FAMILY[aura:fireflies]='weather'; VN_NOTE[aura:fireflies]='eight of them on their own slow wander, each one a light in its own right · they fade out and come back, which is the whole of a firefly'
VN_LIT[aura:fireflies]='0 48 ffe45f 0.1 all'
VN_NAME[aura:motes]='DUST MOTES'; VN_PRICE[aura:motes]=470; VN_RAR[aura:motes]=uncommon
VN_FAMILY[aura:motes]='weather'; VN_NOTE[aura:motes]='the air itself, made visible · nothing here falls, it hangs and turns over, and every speck is shaded by where it is under the sun'
VN_LIT[aura:motes]='0 48 c8bfa4 0.07 all'
VN_NAME[aura:leaves]='LEAF FALL'; VN_PRICE[aura:leaves]=680; VN_RAR[aura:leaves]=rare
VN_FAMILY[aura:leaves]='weather'; VN_NOTE[aura:leaves]='nine of them tipping and slipping down, one glyph per quarter turn · what reaches the floor stays there'
VN_LIT[aura:leaves]='0 48 c8702a 0.1 all'
VN_NAME[aura:ice]='ICE STORM'; VN_PRICE[aura:ice]=1100; VN_RAR[aura:ice]=epic
VN_FAMILY[aura:ice]='weather'; VN_NOTE[aura:ice]='sleet driven across him and rime creeping along the floor · it hardens for a dozen frames of every loop, then eases'
VN_LIT[aura:ice]='0 14 bfe4f4 0.1 all;14 26 eaf8ff 0.22 left;26 48 bfe4f4 0.1 all'
VN_NAME[aura:crystal]='CRYSTAL GROWTH'; VN_PRICE[aura:crystal]=1450; VN_RAR[aura:crystal]=epic
VN_FAMILY[aura:crystal]='cursed'; VN_NOTE[aura:crystal]='it climbs out of the floor for thirty frames, holds, then goes back down in eight · each shard lights the air at its own tip'
VN_LIT[aura:crystal]='0 48 c8a8ff 0.12 up'
VN_NAME[aura:supernova]='SUPERNOVA'; VN_PRICE[aura:supernova]=1900; VN_RAR[aura:supernova]=legendary
VN_FAMILY[aura:supernova]='cosmic'; VN_NOTE[aura:supernova]='one star, swelling for twenty-two frames and then not there any more · the shell rides out to the rim and the whole field goes white with it'
VN_LIT[aura:supernova]='0 22 ffb03a 0.1 all;22 30 ffffff 0.55 all;30 48 ffb03a 0.16 all'
VN_NAME[aura:rift]='TIME RIFT'; VN_PRICE[aura:rift]=2050; VN_RAR[aura:rift]=legendary
VN_FAMILY[aura:rift]='cosmic'; VN_NOTE[aura:rift]='it opens over forty frames and shuts in eight, and what runs inside it is going the other way · the only element that is a hole rather than a thing'
VN_LIT[aura:rift]='0 48 7ad8f0 0.16 all'
VN_NAME[aura:fireworks]='FIREWORKS'; VN_PRICE[aura:fireworks]=2150; VN_RAR[aura:fireworks]=legendary
VN_FAMILY[aura:fireworks]='cosmic'; VN_NOTE[aura:fireworks]='three shells a loop and never two at once · each one climbs, stops, and opens into eight sparks that fall away from where it stopped'
VN_LIT[aura:fireworks]='0 48 ffd75f 0.12 up'
VN_NAME[aura:galaxy]='GALAXY SPIRAL'; VN_PRICE[aura:galaxy]=2400; VN_RAR[aura:galaxy]=legendary
VN_FAMILY[aura:galaxy]='cosmic'; VN_NOTE[aura:galaxy]='two arms turning about him, tight at the middle and loose at the rim · the near half of every arm passes in front of the far half, and the core lights what it goes by'
VN_LIT[aura:galaxy]='0 48 d8b0ff 0.15 all'
# his head · material grids, 20x18 pixels, keyed look,lids (eye, bob and sway are never asked for)
typeset -gA VN_HEAD
VN_HEAD[-1,0]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bskkeebbbskkeeb..|...bkkkkebbbkkkkeb..|...bkkkkebbbkkkkeb..|...bbeeebbbbbeeebb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-1,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bsbbbbbbbsbbbbb..|...bkkkkebbbkkkkeb..|...bbeeebbbbbeeebb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-1,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[0,0]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...beskkebbbeskkeb..|...bekkkebbbekkkeb..|...bekkkebbbekkkeb..|...bbeeebbbbbeeebb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[0,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbsbbbbbbbsbbbb..|...bekkkebbbekkkeb..|...bbeeebbbbbeeebb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[0,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[1,0]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...beskkebbbeskkeb..|...bekkkkbbbekkkkb..|...bekkkkbbbekkkkb..|...bbeeebbbbbeeebb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[1,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbsbbbbbbbsbbbb..|...bekkkkbbbekkkkb..|...bbeeebbbbbeeebb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[1,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
# ...and the door's own · the far glances and the moods, keyed look,lids[,eye]
VN_HEAD[0,0,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbseebbbbbseebb..|...bekkkebbbekkkeb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[0,0,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbeeebbbbbeeebb..|...beskkebbbeskkeb..|...bkkkkkbbbkkkkkb..|...bkkkkkbbbkkkkkb..|...beekeebbbeekeeb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-1,0,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bseeebbbbseeebb..|...bkkkkebbbkkkkeb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-1,0,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbeeebbbbbeeebb..|...bskkkebbbskkkeb..|...bkkkkebbbkkkkeb..|...bkkkkebbbkkkkeb..|...bekkeebbbekkeeb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[1,0,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbseebbbbbseebb..|...bekkkkbbbekkkkb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[1,0,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbeeebbbbbeeebb..|...beskkkbbbeskkkb..|...bekkkkbbbekkkkb..|...bekkkkbbbekkkkb..|...beekkebbbeekkeb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-2,0]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...skkkeebbskkkeeb..|...bkkkeebbbkkkeeb..|...bkkkeebbbkkkeeb..|...bbeeebbbbbeeebb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-2,0,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...sbeeebbbsbeeebb..|...bkkkeebbbkkkeeb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-2,0,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbeeebbbbbeeebb..|...skkkeebbskkkeeb..|...bkkkkebbbkkkkeb..|...bkkkeebbbkkkeeb..|...bekeeebbbekeeeb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-2,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...sbbbbbbbsbbbbbb..|...bkkkeebbbkkkeeb..|...bbeeebbbbbeeebb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[-2,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[2,0]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...beeskkbbbeeskkb..|...beekkkbbbeekkkb..|...beekkkbbbeekkkb..|...bbeeebbbbbeeebb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[2,0,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbesebbbbbesebb..|...beekkkbbbeekkkb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[2,0,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbeeebbbbbeeebb..|...beeskkbbbeeskkb..|...bekkkkbbbekkkkb..|...beekkkbbbeekkkb..|...beeekebbbeeekeb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[2,1]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbbsbbbbbbbsbbb..|...beekkkbbbeekkkb..|...bbeeebbbbbeeebb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
VN_HEAD[2,2]='..........b.........|.......bbbbbbb......|.....bbbbbbbbbbb....|....bbbbbbbbbbbbb...|....bbbbbbbbbbbbb...|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|...beeeeebbbeeeeeb..|...bbbbbbbbbbbbbbb..|...bbbbbbbbbbbbbbb..|....bbbbbbbbbbbbb...|.....bbbbbbbbbbb....|......bdddddddb.....|.......bdnnndb......|........bdddb.......|........bbdbb.......|.........bbb........|....................'
# the wisps · rise, curl, drift, plume · a path of (cell row, column) and a glyph pair per step
typeset -ga VN_WPATH VN_WGLY
VN_WPATH+=('6,14 5,16 4,16 3,17 2,17 1,17 0,17 -1,16 -2,15'); VN_WGLY+=('▘▝ ▗▖ ▚▞ ▒▒ ▒▒ ▒░ ░░ ░░ ░░')
VN_WPATH+=('6,14 5,16 4,16 3,17 2,17 1,16 0,15 -1,14 -2,13'); VN_WGLY+=('▝▘ ▖▗ ▞▚ ▒▒ ▚▞ ▒▒ ▒░ ░▒ ░░')
VN_WPATH+=('6,15 5,16 4,17 3,17 2,18 1,19 0,19 -1,20 -2,21'); VN_WGLY+=('▖▗ ▘▝ ▚▞ ▒░ ░▒ ░░ ░░ ░░ ░░')
VN_WPATH+=('6,14 5,16 4,16 3,16 2,17 1,17 0,17 -1,17 -2,16'); VN_WGLY+=('▄▄ ▐▐ ▓▒ ▒▓ ▒▒ ▒▒ ░▒ ░░ ░░')
typeset -gi VN_SMOKE_SLOW=2 VN_SMOKE_FRAMES=24
typeset -ga VN_SMOKE_RAMP; VN_SMOKE_RAMP=(e6e6ee d2d2de b8b8c8 a8a8ba 9a9aae 7c7c90 6c6c80 5e5e72 454556)
typeset -ga VN_EMBER; VN_EMBER=(11,6,0.3 10,6,0.15 11,5,0.1)   # column,cell row,amount · the corner of his mouth
typeset -gA VN_BRIMD; VN_BRIMD=(1 "0.8 1.0" 2 "0.74 0.88")   # brim → the dusk on cell rows 3 and 4
typeset -gA VN_VPAL; VN_VPAL=(b 9c96b0 d 706a86 e 0e0a1a k 06040e n 605c74 p 785aa0)   # his own materials
typeset -gA VN_SEATS; VN_SEATS=(hat 3 smoke 13 spec 9)
typeset -ga VN_CARD VN_FIELD; VN_CARD=(26 12 3 3); VN_FIELD=(26 14 3 4)   # W H head-col head-cellrow
# the weather · a cell is five characters of base 64: column, row, glyph*2+front, colour (two)
# a light is seven: column+16, row+16 (a comet lights him from off the field), colour (two), strength x100 (two), reach
typeset -ga VN_AG; VN_AG=('█' '▄' '▂' '·' '▘' '▕' '▁' '▖' '▒' '░' '▔' '▝' '▗' '✧' '▃' '▓' '▞' '▚' '✦' '▌' '▐' '▀' '▛' '▟' '▙' '▜' '▆' '▪' '•')
typeset -gA VN_APAL VN_AF VN_AL
VN_AF[fire]='BJAAABICABCKAACCJCADDLAAEDKAAFDJCABELAAGEKEAHFMAAIFLAAGFKCAJGMAAKGLCAJHMAALHLAAGHKCAMINAANIMEACJNAAOJMAAPJLCAGKNAAQKMAAPKLCARLNAASLMAATLLAARLKCAMMNAAUMMAAPMLCABNNAAUNMCADONAAVOMAAPOLCABPNAAWPMAAPPLCABQNAAXQMAATQLAAPQKAAGQJEAYRNAAZRMCADSMAAPSLCABTMCAaUMAAbULAAPUKAADUJEAcVLCABWLAAEWKAAdWJCABXKCACYJCAeZICAfBEGAgELIAhEFGAiIJIAjIDGAkKIIAlKCGAkNIIAlNCGAkQLIAmQFGAiUJIAnUDGAkWGIAoYJIAp|AICAqBJAArCKAACCJCADDLAAsDKCAFELAAPEKAAHFMAAIFLAAGFKCAJGMAAKGLCAJHMAAPHLAAGHKEAtINAAuIMEAvJNAAwJMAAxJLAAGJKEAYKNAAyKMAAPKLCARLNAAzLMAA0LLAAPLKAA1MNAA2MMCABNNAA3NMAAPNLEA4ONAA5OMAAPOLCADPNAA6PMAA0PLAAdPKCABQNAA7QMAA0QLAA8QKEA9RNAA+RMCA/SMAAPSLCADTMAAKTLEA9UMAAbULAAPUKAADUJEBAVLEA9WLAAEWKAAdWJCABXKEBBYJAAeYICBCCJIA0CDGBDFLIAhFFGAiHIIBEHCGAkKIIAlKCGAkOHIAoOBGAkRLIBFRFGAiTIIBGTCGAkWGIAo|AIABHAHABIAGABJAFABKBJABLBIAAdBHCABCKABMCJAABCIAA9CHEAvDLAAEDKAAtELAAPEKAAMEJABNFMABOFLABCFKEAtGMAAKGLABCGKEAYHMAAPHLEBPINAAuIMCABJNABQJMAA0JLAAGJKCBCKNABRKMAAPKLCARLNABSLMABTLLAARLKCAGMNABUMMEBVNNABWNMAAPNLAA/ONABXOMAAPOLEAvPNABYPMAAnPLAAPPKAAdPJEAvQNABZQMAAPQLEA4RNABaRMAAPRLEA4SMAAPSLEA4TMAAKTLAABUMABOULAAPUKCADWLAAEWKAAdWJEBAXKCACYJAAeYIAAtBJIBbEKIBcEEGAiHIIBdHCGAkLHIAPLBGAkNHIAPNBGAkQKIBeQEGAiTIIAnTCGAkXFGAiYIIBf|AIABgAHABhAGCBJBJABLBIABiBHEAvCKABMCJAAPCIAADCHAAvCGCBjDLAAEDKAAPDJAAFDICABELAAnEKAAPEJAAPEIAAFEHABNEGEAYFMABOFLABkFKCAGGMABlGLAAFGKEBmHMCADINABnIMAAPILCABJNAAXJMAATJLAADJKEBoKNABpKMAAPKLAABKKEBVLNABqLMAAPLLAABMNABrMMEBsNNABtNMAAPNLAABNKEA4ONABuOMAAPOLCABPNABYPMAAnPLAAPPKAAdPJEAvQNABZQMCBjRNABaRMAAPRLCABSMAAPSLEA4TMABvTLAAPTKABwUMABxULAABVLEA4WLAAEWKAByXKAACXJEAvYJAAeYIAAtBIIBzFKIAnFEGAiIHIAPIBGAkKHIAoKBGAkNGIAoRKIBzREGAiUHIAPUBGB0WLIB1WFGAiZIIB2|AIEB3BJAArCKABMCJAADCICABDLAB4DKAAPDJAADDIAAcDHEAtELAB5EKAA0EJAAPEIAAPEHAAMEGAB6EFAAkEEEAkFMAAIFLAAPFKAABFJABsGMABvGLAAPGKAABGJCARHMAAPINAA+IMAA0ILAAdIKEBAJNAB7JMAAPJLAA8KNABpKMAA0KLAA8KKCABLNAB8LMAAPMNABUMMAAPNNABrNMAAPNLAADNKEA4ONAB9OMAAPOLAAdOKEA4PNAB+PMAATPLAAdPKCABQNAB7QMEA4RNAAZRMAAPRLAA8SMAAPSLEBwTMAB/TLAAPTKAABTJECAUMABxVLCAdWLACBWKCABXKAACXJABjXIECCYJACDYIECCCIIALEJIA0EDGAiHHIAPHBGAkKGIAoOGIAoQJIAnQDGAiTHIAoTBGCEWKICFWEGAiYHIAo|BJECGCKCCHDLAAEDKAAPDJAADDICARELABTEKAAPEJAAPEIAAREHACIEGECJFMABOFLAAPFKAADFJAA9GMACKGLAALGKAAPGJAADGICA/HMABfHLAAPHKCABINACLIMABfILAAPIKAAPIJAAdIICABJNACMJMABGJLAAGJKCABKNACNKMAAnKLAARKKCA/LNABXLMECAMNACOMMAAPMLAABNNABUNMAAPNLAA/ONACPOMAA0OLAABOKCAGPNABRPMAAPPLCABQNACQQMCA8RNABnRMAAPRLAADSMAAPSLCADTMACRTLAAPTKACSUMCCTVLCA8WLACBWKCABXKABMXJABjXIACCYJECDBHIAPEJIATEDGAkIGIAPLGIAPNLICUNFGAiQJICVQDGAkUGIAoXKICWXEGAiYHIAo|BJCBLCKEBBDLAAEDKAAPDJAA/DICARELAAPEKAAFEJCAFFMACXFLABCFKCARGMACYGLAAMGKCBCHMAAjHLAAPHKAAMHJCAGINACLIMACZILAAjIKAAPIJAAGIIAABIHABiJNABZJMABEJLAAPJKACaJJABPJIEAvKNABYKMACbKLAAPKKACcKJCBCLNACdLMAAPMNACeMMABGMLAAMMKCCcNNACfNMAAPNLCBCONACgOMAALOLAAPOKCCaPNAChPMCABQNABQQMAAPQLEBoRNABnRMAAPRLCARSMABTSLAARSKCAGTMAAKTLAABTKECiUMCAsVLCABWLAAEWKAAdWJEAvXKABMXJAABXIABPXHECCBHIAPFIIB5FCGAkHGIAPKLICjKFGBCNLICkNFGCcRIIBERCGAkTGIAoWJIALWDGAiZGICl|BJECGCKCCHDLACmDKAAPDJAADDIACiDHEAYELAAPEKAADEJEA9FMABxFLCARGMECnHMABfHLAAPHKAABHJECoINACLIMACVILAAPIKAABIJAByJNABZJMACpJLAAPJKAABJJAADJIEAvKNABYKMACqKLAAPKKAAFKJAABKIEAcLNACdLMAAnLLAAPLKABkLJEAHMNACeMMACrMLAAPMKAAJMJAAGMIEAtNNACfNMAAnNLAAJNKCBCONACgOMAALOLAAGOKCAMPNAChPMEAvQNABQQMAAPQLABjQKEAYRNABnRMAAPRLCAJSMACrSLAAPSKAA1TMAAKTLECAUMABxULEBmVLCAGWLAAEWKAABWJABiXKABMXJAADXICABCGIAoEIIB5ECGAkHLIAhHFGAiLLIAhLFGAiOKICsOEGAiQIIBEQCGAkTLIAhTFGAiXJIA0XDGCtYGIAP|BJECTCKAACCJCABDLACmDKAAPDJAAFDIAAtELAAPEKCA/FMABxFLCABGMCCuHMAATHLAAPHKAAGHJEAtINACvIMAAPILCABJNABQJMABzJLAAPJKAA1KNAAyKMAAPKLAABLNACgLMABzLLAAPLKAAGLJACwLIEAkMNACxMMABeMLAA0MKAAPMJACcMIAAiMHCAiNNACyNMACzNLAAPNKAAPNJACcNICAiONACgOMABzOLAAPOKAAGOJECCPNAAWPMAAPPLEBAQNAAXQMAA0QLAABQKEBoRNAAZRMAAPRLCA/SMAALSLAAPSKAC0TMEC1UMABxULCARVLEAHWLAC2WKAAPWJAAdWICABXKAACXJCADBGIAoEHIAPILIC3IFGAiKKIAhKEGAiNKIAnNEGAiQHIAPQBGAkULIC4UFGAiWIIALWCGC5YFGAi|CKAACCJAABCIEBPDLAAEDKAADDJAAcDIEAtELAAPEKABAFMABxFLEACGMAAKGLEA4HMAATHLAAPHKAAGHJEAtINABnIMAAPILEBAJNAAXJMAAPJLAADKNABpKMEACLNABqLMAA0LLAAPLKAARLJEA1MNABrMMAB5MLAAPMKAABMJCBkNNABtNMAB5NLAA0NKAAPNJAAFNICBCONABuOMACrOLAAPOKAADOJAAvPNABYPMAAnPLAAPPKAAdPJCABQNABZQMACqQLAAPQKAADQJAA4RNABaRMABfRLAAPRKAACSMAC6SLABkSKEBATMEC7UMABxULABCUKEC0VLCAMWLAC8WKAAPWJAABWIABiXKCC9YJEC+CFGAiFHIAPFBGB0HKIC/HEGAiKKIALKEGAiOJIALODGAiRHIAPRBGAkTKICFTEGAiWIIBzWCGC5ZFGDA|CKABMCJAABCIABPDLAAEDKAADDJEAcELAAPEKAA/EJEAHFMABxGMAAKGLAABGKEC0HMAATHLAABHKCAGINABnIMAAPILEBAJNAAXJMAAPJLCABKNABpKMCABLNADBLMAALLLAAPLKAARLJECAMNADCMMAAPMLCARNNADDNMAAnNLAAPNKAA/NJEAvONADEOMAAPOLCAGPNADFPMABfPLAAPPKAAPPJAAdPICABQNADGQMABdQLAAnQKAAPQJAA8QIAA4QHEA1RNADHRMABERLAAnRKAAPRJAA8RIAA4SMACbSLAAPSKAA4TMAAKTLCAGUMABxULAAJUKEA4VLAAGWLAAEWKAAPWJAAdWICABXKEDIYJCBLBFGAiEGIAoHKICrHEGAiLJIDJLDGAiNJIALNDGAkQGIAPTKIA0TEGAiXHIAPYEGAg|BJECTCKABMCJAABCIABPDLADKDKCADELAAPEKAA/EJCBkFMCCTGMACRGLAAPGKAC0HMAAPHLAABINABnIMAAPILCABJNAAXJMAAPKNABpKMAAPKLCABLNABqLMAA0LLAAPLKAAvMNABrMMAAPMLCABNNABtNMAAPNLCABONABuOMEAePNABYPMAAnPLAAPPKAAdPJCABQNABZQMAAnQLAAPQKAA8QJEA4RNABaRMAAnRLAA0RKAAPRJAABRIAA1SMADJSLAAPSKAA8SJCABTMABvTLAAPTKAA8TJAACUMABOULAAPUKAADUJCABVLAAPVKAAdVJEA4WLAAEWKAAdWJCABXKEBBYJCAeBEGAgFGIAoIJIBGIDGAiKJICqKDGAkNIIBfNCGAkRGIAoUJIA0UDGAiWHIAP|BJAArBIEAvCKAACCJAADCIEAvDLADLDKEDMELAAPEKAAFEJCAFFMABxFLECSGMABlGLAAPGKAARGJEBPHMAAPHLEAvINABnIMAAPILCABJNAAXJMCADKNABpKMAAxKLAABKKCARLNABqLMAA0LLAABLKEAvMNABrMMAAPMLCABNNABtNMAAPNLEA4ONABuOMAAPPNABYPMAAnPLAAPPKABiQNABZQMAAPQLCABRNABaRMABfRLAAPRKAADRJEA4SMAAPSLCAFTMADNTLAAPTKAAPTJAADTICABUMADOULAALUKAAPUJAADUIABAVLAAnVKAAPVJAA8VIAAvVHEBPWLAAEWKAABWJAByWIEAvXKAACXJCADYJCBLZIEDPCKIDQCEGAiELIC4EFGAiHJICpHDGAkKIIBEKCGAkOIICqOCGAkQLICFQFGAiTJIAxTDGAkWGIAPYJIBb|BJAAABICABCKAACCJEA9DLADLDKCA/ELAAPEKAAFEJEAcFMABxFLAABGMABlGLAAPGKAC0HMCADINABnIMAAPILCABJNACQJMCA8KNADRKMAATKLAAPKKAARKJEAYLNADSLMAAPLLCADMNACfMMAAPMLAADNNAA3NMCABONAB8OMAAPOLAA8PNAA6PMAA0PLAAdPKCABQNAA7QMAAPQLAADRNAA+RMAAPRLCABSMEBNTMACKTLAAPTKAARTJECSUMACXULAAPUKAARUJEBAVLACpVKAAPVJAABVIAA9VHEAvWLAC8WKAAPWJAABWIABiWHEAvXKABMXJAABXIAADXHAAvYJAAeYIAAvZIADTZHCBJBJIDUELIC4EFGAiIIIAjICGAkLIIAjLCGAkNHIAoNBGAkQLIAmQFGAiUIIALUCGAkXGIAPYJIAp|BJABLBIABiCKEDVDLAAEDKAAJDJEAcELAAPEKAAGEJEAHFMABOFLABkFKCAGGMAAKGLAAFGKEBmHMAAPINABnIMAAPILEACJNACQJMAAPJLEA9KNADRKMAATKLAAPKKAARKJEAYLNADSLMAAPLLEA9MNACfMMAAPMLCADNNAA3NMEA4ONAB8OMAA0OLAAPOKCABPNAA6PMAAPPLAAdQNAB7QMAAPQLAA8QKEA4RNAAZRMCABSMAAPSLEBwTMAB/TLAA8TKCABUMABxULAADVLAAdWLACBXKAACXJABPXIECCYJECDZIADWBJIBbFKIAhFEGAiHIIBdHCGAkKHIAoKBGAkNHIAoNBGAkRKIAmREGAiTIICbTCGAkWLIDXWFGAiZIIDY|BJAAABIEAvDLAAEDKAA/DJCABELAAPEKAAFEJEAcFMAAbFLAAPFKAARFJEA1GMAAKGLEBAHMAAPHLEAvINACvIMAAPILEAvJNABQJMABzJLAADJKEA1KNAAyKMABzKLAABKKCAJLNACgLMAAPLLEA4MNACxMMAAPMLCABNNACyNMCADONACgOMABzOLAAPOKAAGOJECCPNAAWPMAAPPLCABQNACQQMAAPQLAADQKEBoRNABnRMEBwSMAAxSLAADSKEC0TMAAKTLAADTKECSUMADZULAADUKEBAVLECoWLACBWKCABXKAACXJABPXIECCYJCBoZIEDWCIIALEKIBTEEGAiHHIAPHBGAkLHIAoLBGAkOGIAoQKIDJQEGAiTHIAoTBGCEXFGAiYIIBE|AIEDaBJCBLCKEBBDLAAEDKAADDJAAcELAAPEKAA/EJCBkFMAAbFLAAPFKADbFJEDcGMCCuHMAAPHLCABINACvIMAAPJNABQJMABzJLAAPJKABjJJECCKNAAyKMAAPKLCABLNACgLMAAPLLEA4MNACxMMAAPNNACyNMAAPNLCABONACgOMABzOLAAPOKADcPNAAWPMAAPPLEBAQNAAXQMAAPQLCADRNAAZRMEACSMAA0SLAAPSKAAvTMAAKTLCABUMAAbULAABUKEA4WLAAEWKAAdWJCABXKAACXJAAvYJAC+YIEAtBIICqEJICrEDGAiIHIAoIBGAkKGIAoNGIAoQJICpQDGAiUHIAPUBGB0WKIBeWEGAiYHIAP|AICAfCKADIDLAAEDKAA/DJCBCELAAPEKAAFEJAAtEIEDdFMADZFLAADFKEBVGMEDeHMAAPHLCABINACvIMAAPILEACJNABQJMABzJLAAPJKABjJJECCKNAAyKMAAPLNACgLMAAPLLCABMNACxMMCA8NNACyNMACzNLAABNKCAJONACgOMAAPOLAABOKEDcPNAAWPMAAPPLCABQNAAXQMAAPQLEAvRNAAZRMAAPRLEDMSMAALSLAAPSKAC0TMAAKTLCARUMABxULAARUKEBAWLAAEWKAABWJAAdWIEAvXKAACXJCADYJABLYICAFCHIAoFJICqFDGAkHGIAoKGIAoOLIAmOFGAiRJIAnRDGAkTGIAPWKIALWEGAiZHICl|AIEBKCKAACCJCBjDLAAEDKAABDJCAJELAAPEKAAPEJAAGEICB6FMABxFLEBwGMAAKHMAAPHLCAdINADfIMAAPILAAdJNADgJMAAxJLAAPJKAAvKNADhKMCADLNACPLMAAPLLCADMNADiMMAAPNNADiNMAAxNLAAPNKAARNJEAYONAAzOMAAPOLEA9PNABRPMAAPPLCABQNAAXQMCADRNAAZRMAAPRLAA/RKECiSMAALSLAAFSKCARTMAAKTLCARUMABxULEC0WLAAEWKAAPWJAAdWICABXKAACXJCADYJABLYIEAcBHIAoEIICbECGAkHGIAoLLIDjLFGAiNLIDkNFGAiQIIBEQCGAkTGIAPXJIA0XDGBDYGIAP|CKAACCJABjCIECCDLAAEDKAABDJCAJELAAPEKAAPEJAAGEICB6FMEDlGMAAKGLCADHMAAPHLCAdINADfIMAATILAAdIKCABJNADgJMAAPJLAA8KNADhKMCADLNACPLMAAPLLCADMNADiMMAAPMLCADNNADiNMAAxNLAAPNKAARNJEAYONAAzOMAAPPNABRPMAAPPLCABQNAAXQMCADRNAAZRMAALRLAAPRKACiSMAAPSLCAFTMAAKTLAARUMCDmVLCAGWLAAEWKAABWJAAdWIEAvXKAACXJCADYJCBLBGIAoFIICbFCGAkILIDnIFGAiKLIBFKFGAiNKIC4NEGAiRIICbRCGAkULIC4UFGAiWJIBzWDGAkZGICl|CKAACCJAAGCIEDoDLAAEDKAADDJCARELAAPEKAADEJAC0EIECIFMEDpGMAAKGLAABGKEDqHMAAPHLCABINADrIMAALILAAPIKAAdIJEAvJNADsJMAAPKNAB+KMAAPKLEA4LNAB9LMAAPLLEA4MNABUMMAA0MLAABMKEBsNNABUNMAAxNLAABNKCARONACPOMAAPPNABRPMAAPPLCABQNAAXQMAAPRNAAZRMAALRLAAPRKAARRJEDcSMAAPSLEAvTMAAKTLAARUMEDtVLAAGVKCABWLAAEWKAABWJABiXKAACXJAA9CGIAoEHIAPHLIC3HFGAiKKIC3KEGAiOKICrOEGAiQHIAPQBGAkTLIDuTFGAiWIIALWCGC5YFGAi|BJCBLCKACHCJAA4DLAAEDKAA8DJAA4DIEA1ELAAPEKAA8EJEA4FMCDvGMABvGLAABGKEDqHMAAPHLCABINADrIMAAnILAAPIKAByJNADsJMEBoKNAB+KMAAPKLCABLNAB9LMAAPLLEA4MNABUMMAA0MLAAPMKADbMJEDcNNABUNMAAPNLCABONACPOMAAPOLEA4PNABRPMAAPPLEBAQNAAXQMAAPQLAADRNAAZRMAAxRLAAPRKABVSMAAPSLEA4TMAAKTLCABUMCAsVLAAPVKAADVJEAvWLAAEWKAAdWJEAvXKAACXJAAvBFGAiEHIAPIKIDwIEGAiLKIA0LEGAiNJIBGNDGAiQHIAoQBGAkUKIC3UEGAiXIICqYFGAi|BJAAABICABCKAACCJCADDLAAEDKAABDJAADDIEAcELAAREKEA4FMABxFLEBAGMAAKGLAADGKEA4HMAALHLAADHKEA4INADfIMAAPILAAdIKEBAJNADgJMEA9KNADhKMAAPKLAADLNACPLMAAPLLCADMNADiMMAAxMLAAPMKAARMJEAtNNADiNMCADONAAzOMAAPOLCABPNABRPMAAPQNAAXQMAATQLAAPQKCAGRNAAZRMAAPRLAABSMAAPSLEA4TMAAKTLEACUMABxULEA4VLAAPVKAADVJEAvWLAAEWKAAdWJEAvXKAACXJCABZICAfBFGAiFGIAPHKIA0HEGAiKJIBfKDGAiNJIBfNDGAkRGIAoTKIA0TEGAiWHIAP|BJAAABICABCKAACCJEA9DLAAEDKAA/DJAAvDIEAcELAARFMABxFLAABFKEBVGMAAKGLCA/HMAA0HLAABHKCAGINACvIMAAPILEAvJNABQJMAAPKNAAyKMAAPKLAABLNACgLMAAPLLAABLKEA1MNACxMMACzMLAABMKCAGNNACyNMEDqONACgOMAAPOLCABPNAAWPMAAPPLEBAQNAAXQMAATQLAAPQKAAGQJEAYRNAAZRMAAPRLEA4SMAAPSLCABTMCAaUMAAbULAABUKEA4VLAABVKCADWLAAEWKAAdWJEAvXKAACXJEAvZICAfCKIDxCEGAiEGIAPHJICpHDGAiLJICbLDGAkOIIAlOCGAkQGIAoTJICrTDGAiXHIAPYEGAg|BJAAABICABCKAACCJCADDLAAEDKAAFDJCABELAAGEKEAHFMAAIFLAAGFKCAJGMAAKGLCAJHMAALHLAAGHKCAMINAANIMEACJNAAOJMAAPJLCAGKNAAQKMAAPKLCARLNAASLMAATLLAARLKCAMMNAAUMMAAPMLCABNNAAUNMCADONAAVOMAAPOLCABPNAAWPMAAPPLCABQNAAXQMAATQLAAPQKAAGQJEAYRNAAZRMCADSMAAPSLCABTMCAaUMAAbULAAPUKAADUJEAcVLCABWLAAEWKAAdWJCABXKCACYJCAeZICAfBEGAgELIAhEFGAiIJIAjIDGAkKIIAlKCGAkNIIAlNCGAkQLIAmQFGAiUJIAnUDGAkWGIAoYJIAp|AICAqBJAArCKAACCJCADDLAAsDKCAFELAAPEKAAHFMAAIFLAAGFKCAJGMAAKGLCAJHMAAPHLAAGHKEAtINAAuIMEAvJNAAwJMAAxJLAAGJKEAYKNAAyKMAAPKLCARLNAAzLMAA0LLAAPLKAA1MNAA2MMCABNNAA3NMAAPNLEA4ONAA5OMAAPOLCADPNAA6PMAA0PLAAdPKCABQNAA7QMAA0QLAA8QKEA9RNAA+RMCA/SMAAPSLCADTMAAKTLEA9UMAAbULAAPUKAADUJEBAVLEA9WLAAEWKAAdWJCABXKEBBYJAAeYICBCCJIA0CDGBDFLIAhFFGAiHIIBEHCGAkKIIAlKCGAkOHIAoOBGAkRLIBFRFGAiTIIBGTCGAkWGIAo|AIADaBJECTCKAACCJCABDLADKDKEAvELAAPEKAAFEJABNFMAAbFLAARFKEA1GMAAKGLAARGKEBPHMAAPHLEAHINAAuIMCABJNABQJMAA0JLAAGJKCBCKNABRKMAAPKLCARLNABSLMABTLLAARLKCAGMNABUMMEBVNNABWNMAAPNLAA/ONABXOMAAPOLEAvPNABYPMAAnPLAAPPKAAdPJEAvQNABZQMAAPQLEA4RNABaRMAAPRLEA4SMAAPSLEA4TMAAKTLAABUMABOULAAPUKCADWLAAEWKAAdWJEBAXKCACYJAAeYIAAtBJIBbEKIDyEEGAiHIIAjHCGAkLHIAPLBGAkNHIAPNBGAkQKIBeQEGAiTIIAnTCGAkXFGAiYIIBf|AIADaCKAACCJCABDLADKDKEACELAAPEKAAPEJABkEICAMFMABxFLCABGMACRGLAABGKEC0HMCADINABnIMAAPILCABJNAAXJMAATJLAADJKEBoKNABpKMAAPKLAABKKEBVLNABqLMAAPLLAABMNABrMMEBsNNABtNMAAPNLAABNKEA4ONABuOMAAPOLCABPNABYPMAAnPLAAPPKAAdPJEAvQNABZQMCBjRNABaRMAAPRLCABSMAAPSLEA4TMABvTLAAPTKABwUMABxULAABVLEA4WLAAEWKAByXKAACXJEAvYJAAeYIAAtBIICqFKIB5FEGAiIHIAoIBGAkKHIAoKBGAkNGIAoRKIBzREGAiUHIAPUBGB0WLIB1WFGAiZIIB2|AIEDaBJECTCKACHCJEAvDLADKDKCADELAATEKAAPEJAAFEIAAtFMABxFLCADGMAAKGLAADGKEA4HMEAvINAA+IMAA0ILAAdIKEACJNAB7JMAAPJLAA8KNABpKMAA0KLAA8KKCABLNAB8LMAAPMNABUMMAAPNNABrNMAAPNLAADNKEA4ONAB9OMAAPOLAAdOKEA4PNAB+PMAATPLAAdPKCABQNAB7QMEA4RNAAZRMAAPRLAA8SMAAPSLEBwTMAB/TLAAPTKAABTJECAUMABxVLCAdWLACBWKCABXKAACXJABjXIECCYJACDYIECCCIICqEJIBTEDGAiHHIAoHBGAkKGIAoOGIAoQJIAnQDGAiTHIAoTBGCEWKICFWEGAiYHIAo|BJECTCKCCHDLAAEDKAA8DJCABELAAPEKAAPEJAABEICAGFMABxFLCABGMAAKGLCABHMEDcINADrIMAAnILAAPIKAByJNADsJMAAPJLCADKNAB+KMAALKLAABKKCADLNAB9LMEAvMNABUMMAAPMLAABNNABUNMAAPNLAABONACPOMAATOLAABOKCAGPNABRPMAAPPLCABQNACQQMCA8RNABnRMAAPRLAADSMAAPSLCADTMACRTLAAPTKACSUMCCTVLCA8WLACBWKCABXKABMXJABjXIACCYJECDBHIAPEJIA0EDGAkIGIAoLGIAoNLIAmNFGAiQJICVQDGAkUGIAoXKICWXEGAiYHIAo|BJCBLCKEDzDLAAEDKAAPDJAA/DICBCELAAPEKAADEJCAFFMABxFLCADGMAAKHMAAPHLECoINAAZIMAA0ILAAPIKCABJNAAXJMAAPJLCADKNABRKMAAPKLAADLNAD0LMEA4MNAD1MMAA0MLADbMKCAJNNACxNMAAPNLCARONAASOMAA0OLAAPOKCAMPNAChPMCABQNABQQMAAPQLEBoRNABnRMAAPRLCARSMABTSLAARSKCAGTMAAKTLAABTKECiUMCAsVLCABWLAAEWKAAdWJEAvXKABMXJAABXIABPXHECCBHIAPFIICqFCGAkHGIAoKLIC3KFGAiNLIC4NFGAiRIIBERCGAkTGIAoWJIALWDGAiZGICl|BJECTCKCCHDLACmDKAAPDJAA/DIAAtDHECCELAAPEKAADEJEAvFMABxFLCADGMEBVHMAA0HLAA8HKEA9INAAZIMAA0ILAAdIKEACJNAAXJMAAPJLAADKNABRKMAAPKLEACLNAD0LMCABMNAD1MMAA0MLADbMKCAJNNACxNMAAPNLCARONAASOMAA0OLAAGOKCAMPNAChPMEBAQNABQQMAAPQLABjQKEAYRNABnRMAAPRLCAJSMACrSLAAPSKAA1TMAAKTLECAUMABxULEBmVLCAGWLAAEWKAABWJABiXKABMXJAADXICABCGIAoEIICqECGAkHLIBeHFGAiLLID2LFGAiOKICsOEGAiQIIBEQCGAkTLIAhTFGAiXJIA0XDGCtYGIAP|BJECTCKAACCJCABDLACmDKAAPDJAAFDIAAtELAAPEKCA/FMABxFLCABGMCCuHMAATHLAAPHKAAGHJEAtINAD3IMAAPILCABJNAAwJMAAPJLAABKNAD4KMCADLNAAVLMAAPLLCAFMNAD5MMAAxMLAARMKEAtNNAD5NMAAPNLAARONAD6OMAAPOLCAGPNAD7PMEACQNABQQMAALQLABjQKEAYRNABnRMAAPRLCAJSMACrSLAAPSKAA1TMECIUMABxULCAJVLEDcWLAD8WKAAPWJAAdWICABXKAACXJCADBGIAoEHIAPILICFIFGAiKKICkKEGAiNKIBfNEGAiQHIAPQBGAkULID9UFGAiWIIALWCGC5YFGAi|CKAACCJAABCIEBPDLAAEDKAADDJAAcDIEAtELAAPEKABAFMABxFLEACGMAAKGLEA4HMAATHLAAPHKAAGHJEAtINACvIMAAPILEBAJNABQJMAAPJLAADKNAAyKMEDqLNACgLMABzLLAABLKCAGMNACxMMAAPMLAABNNACyNMACzNLAABNKEBmONACgOMCAdPNAAWPMAAPPLEBAQNAAXQMAA0QLAABQKEA1RNAAZRMAAPRLAAFRKEA1SMAAnSLABkSKEA1TMED+UMABxULABCUKEBmVLCAMWLAC8WKAAPWJAABWIABiXKCC9YJEC+CFGAiFHIAPFBGB0HKIC/HEGAiKKIAnKEGAiOJIBdODGAiRHIAPRBGAkTKIAhTEGAiWIIBzWCGC5ZFGDA|CKABMCJAABCIABPDLAAEDKAADDJEAcELAAPEKAA/EJEAHFMABxGMAAKGLAABGKEC0HMAATHLAABHKCAGINABnIMAAPILEA4JNACQJMAAPJLCADKNADRKMCADLNADSLMAAxLLAAPLKAARLJECIMNACfMMAAPMLCADNNAA3NMAAxNLAADNKEBAONAB8OMEA9PNAA6PMAAPPLAAdQNAA7QMAAPQLAADRNAA+RMAAnRLAADRKCABSMAAPSLEBATMCD/UMABxULAARUKEA4VLAAGWLAAEWKAAPWJAAdWICABXKEDIYJCBLBFGAiEGIAoHKICrHEGAiLJICqLDGAiNJIBfNDGAkQGIAoTKIA0TEGAiXHIAPYEGAg|BJECTCKABMCJAABCIABPDLADKDKCADELAAPEKAA/EJCBkFMCCTGMACRGLAAPGKAC0HMAAPHLAABINABnIMAAPILCABJNACQJMAAPKNADRKMAAPKLCADLNADSLMAAxLLAAPLKAC0MNACfMMAAPMLCADNNAA3NMAAPNLCADONAB8OMEA9PNAA6PMAA0PLAAdPKCABQNAA7QMAAPQLCA8RNAA+RMAB5RLAADRKCADSMEAvTMAAKTLCADUMABxULAABVLAABVKCA8WLAAEWKAAdWJCABXKEBBYJCAeBEGAgFGIAoIJIBfIDGAiKJIBfKDGAkNIIBENCGAkRGIAoUJIB5UDGAiWHIAP|BJAArBIEAvCKAACCJAADCIEAvDLADLDKEDMELAAPEKAAFEJCAFFMABxFLECSGMABlGLAAPGKAARGJEBPHMAAPHLEAvINABnIMAAPILCABJNAAXJMCADKNABpKMAAxKLAABKKCARLNABqLMAA0LLAABLKEAvMNABrMMAAPMLCABNNABtNMAAPNLEA4ONABuOMAAPPNABYPMAALPLAAPPKABiQNAEAQMAAPQLCADRNAEBRMAALRLAADRKEBwTMAECTLAADTKEA9UMABxULCADVLAAPVKAA9WLACBWKCABXKADIYJCBoZIEDWCKIDQCEGAiELIC4EFGAiHJICpHDGAkKIIBEKCGAkOIICqOCGAkQLIDkQFGAiTJIALTDGAkWGIAoYJIED|BJAAABICABCKAACCJEA9DLADLDKCA/ELAAPEKAAFEJEAcFMABxFLAABGMABlGLAAPGKAC0HMCADINABnIMAAPILCABJNACQJMCA8KNADRKMAATKLAAPKKAARKJEAYLNADSLMAAPLLCADMNACfMMAAPMLAADNNAA3NMCABONAB8OMAAPOLAA8PNAA6PMAATPLAAdPKCABQNAB7QMAAPQLAA8RNAAZRMAAPRLCA8SMEA4TMAB/TLAA8TKCABUMABxULCADVLAAdVKCABWLACBXKAACXJCBjYJECDZICDABJIDUELIC4EFGAiIIIAjICGAkLIIAjLCGAkNHIAoNBGAkQLIBeQFGAiUIIBEUCGAkXGIAoYJIED|BJABLBIABiCKEDVDLAAEDKAAJDJEAcELAAPEKAAGEJEAHFMABOFLABkFKCAGGMAAKGLAAFGKEBmHMAAPINABnIMAAPILEACJNACQJMAAPJLEA9KNADRKMAATKLAAPKKAARKJEAYLNADSLMAAPLLEA9MNACfMMAAPMLCADNNAA3NMEA4ONAB8OMAA0OLAAPOKCABPNAA6PMAAPPLAAdQNAB7QMAAPQLAA8QKEA4RNAAZRMCABSMAAPSLEBwTMAB/TLAA8TKCABUMABxULAADVLAAdWLACBXKAACXJABPXIECCYJECDZIADWBJIBbFKIAhFEGAiHIIBdHCGAkKHIAoKBGAkNHIAoNBGAkRKIAmREGAiTIICbTCGAkWLIDXWFGAiZIIDY|BJAAABIEAvDLAAEDKAA/DJCABELAAPEKAAFEJEAcFMAAbFLAAPFKAARFJEA1GMAAKGLEBAHMAAPHLEAvINACvIMAAPILEAvJNABQJMABzJLAADJKEA1KNAAyKMABzKLAABKKCAJLNACgLMAAPLLEA4MNACxMMAAPMLCABNNACyNMCADONACgOMABzOLAAPOKAAGOJECCPNAAWPMAAPPLCABQNACQQMAAPQLAADQKEBoRNABnRMEBwSMAAxSLAADSKEC0TMAAKTLAADTKECSUMADZULAADUKEBAVLECoWLACBWKCABXKAACXJABPXIECCYJCBoZIEDWCIIALEKIBTEEGAiHHIAPHBGAkLHIAoLBGAkOGIAoQKIDJQEGAiTHIAoTBGCEXFGAiYIIBE|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'
VN_AL[fire]='RZAoA3IYdAoA3IfcAoA3ImaAoA3I|RZAoA3IYdAoA3IfbAoA3ImaAoA3I|RYAoA3IYdAoA3IfaAoA3ImaAoA3I|RYAoA3IYcAoA3IfaAoA3ImaAoA3I|RZAoA3IYbAoA3IfbAoA3ImbAoA3I|RaAoA3IYZAoA3IfcAoA3ImbAoA3I|RaAoA3IYXAoA3IfdAoA3ImaAoA3I|RaAoA3IYZAoA3IfdAoA3ImZAoA3I|RaAoA3IYcAoA3IfcAoA3ImZAoA3I|RaAoA3IYcAoA3IfaAoA3ImYAoA3I|RaAoA3IYcAoA3IfZAoA3ImZAoA3I|RaAoA3IYcAoA3IfaAoA3ImaAoA3I|RZAoA3IYcAoA3IfaAoA3ImZAoA3I|RZAoA3IYcAoA3IfbAoA3ImYAoA3I|RYAoA3IYcAoA3IfbAoA3ImbAoA3I|RZAoA3IYcAoA3IfcAoA3ImbAoA3I|RaAoA3IYcAoA3IfcAoA3ImaAoA3I|RbAoA3IYcAoA3IfcAoA3ImZAoA3I|RbAoA3IYbAoA3IfcAoA3ImZAoA3I|RbAoA3IYbAoA3IfcAoA3ImZAoA3I|RbAoA3IYaAoA3IfcAoA3ImZAoA3I|RaAoA3IYaAoA3IfcAoA3ImaAoA3I|RZAoA3IYbAoA3IfcAoA3ImaAoA3I|RZAoA3IYcAoA3IfcAoA3ImaAoA3I|RZAoA3IYdAoA3IfcAoA3ImaAoA3I|RZAoA3IYdAoA3IfbAoA3ImaAoA3I|RaAoA3IYdAoA3IfaAoA3ImaAoA3I|RaAoA3IYcAoA3IfaAoA3ImaAoA3I|RaAoA3IYbAoA3IfbAoA3ImbAoA3I|RaAoA3IYaAoA3IfcAoA3ImbAoA3I|RaAoA3IYbAoA3IfdAoA3ImaAoA3I|RaAoA3IYbAoA3IfdAoA3ImZAoA3I|RaAoA3IYcAoA3IfdAoA3ImZAoA3I|RaAoA3IYcAoA3IfcAoA3ImYAoA3I|RaAoA3IYcAoA3IfbAoA3ImZAoA3I|RaAoA3IYcAoA3IfbAoA3ImaAoA3I|RZAoA3IYcAoA3IfaAoA3ImbAoA3I|RZAoA3IYcAoA3IfbAoA3ImbAoA3I|RYAoA3IYcAoA3IfbAoA3ImbAoA3I|RZAoA3IYcAoA3IfcAoA3ImbAoA3I|RaAoA3IYcAoA3IfcAoA3ImaAoA3I|RbAoA3IYcAoA3IfcAoA3ImZAoA3I|RbAoA3IYbAoA3IfcAoA3ImZAoA3I|RbAoA3IYbAoA3IfcAoA3ImZAoA3I|RbAoA3IYaAoA3IfcAoA3ImZAoA3I|RaAoA3IYaAoA3IfcAoA3ImaAoA3I|RZAoA3IYbAoA3IfcAoA3ImaAoA3I|RZAoA3IYcAoA3IfcAoA3ImaAoA3I'
VN_APAL[fire]='b8500cec6410bc500cec681098540ce86010e85c0cb0440c946c1ce45c0cf08414fcb434e4540c705028a47840fc8c18cc9850e8600ce8ac60fcac2cf4b468e8b064cca05ca48450a03408705c38e0600894681cb4440cf06c10b0480c702804ac3808fccc84e04a0cfccc448c2206ffd24afcc070fcb838ff8c1ac08c2874300898440c883804a4380870502cb84c0ca47c44fcac30cc9c58e8b468fcb030ac4008f4bc70f4c078c0500ce8bc74cca86ca48c5cec6c10c0540c706040e86410bc4c0c984008e4580cb43808fcc844fcbc64fcbc387c440ca044089c3c084c1404b44c0cc87010ac400c946c20a83c08a47c48cca460e8bc70fcb430f4c480b44808f4c888e8c888ccb47ca4946c70684cc08828fcd494fcc840fcb864fcc03c7434087c3408c85c10e8580ce85c10f0ac30b0400c705834b04408cca46ce8c078f4c884b84c08f4cc8ce8c88cf0b034c4540c94500ccc5c10fca82c5014009874447c60205c2404986c1cfcb034e04c0ca48858e8bc78e8c07cccac74f0a82cb04008904008982c087c2804842004fcc474903c08bc540ca43804902404f0b838706850a49870ccb480f4cc88e8b870a4804cf0a42cb8480c8c3808fcc478fcc43cc89028947424f0c040fcecb4e4500cfcc440e0500ce8c484f4c880f4c074e8b068cc9450b44408fce8acfcd894ac601098681c983004c85810fcc038fcbc3cfcb834fcd898701804e0600c705830982c04f4b868f4b86cfca830b4480ca43c04987020fcc06cfcc87c541400fcc040942c04987424b84408883408fccc80702404e8c480f4d090f4d89ce8d49cccc090a8a07c706c54943c08fcb4388c3c088c3804bc480cf0b438947020542004c88c24cca060e8b86c582004c08020883004481400986c387c642094641c541c04ec640cac3c08942804bc5408705c3ca48454cca464f4bc74fcbc68fcbc6c6c2c04843404fcb0589c3008682804c4580c706048a48c60602004fcc878883404fcb45cc89c5cfccc7c9c4408e8b46cf4b870fcc470705430cc9858f4b464e8a85ccc9048987024fcd088a03804d85808a49068706044f0a830c0942c'
VN_AF[rain]='AGLAAAFLABCIKACCHKADEGLACEFLADELLADGGKACGFKAEGMKAFGLKADICLAGIBLAEIILACIHLADKCKAGKBKAEKIKACKHKAEMALAHMGLAGMFLAEMMLACMLLADOCKAIOBKAJOIKAGOHKAEQCLAIQBLAJQILAGQHLAESEKAISDKAJSKKAGSJKAEUCLAIUBLADUILAGUHLAEWGKAIWFKAJWLKAKYELAGYJLADKNMALLNMAMPNMALQNMAN|AHLAAAGLAOCDKAPCJKACCIKADEHLACEGLADGBKAQGHKACGGKADIDLAGICLAEIJLACIILADKDKAGKCKAEKJKACKIKADMBLAIMALARMHLAGMGLAEMNPASODKAGOCKAJOJKAGOIKAEQDLAIQCLAJQJLAGQILAESFKAGSEKAJSLKAGSKKAEUDLAIUCLAJUJLAGUILAEWHKAGWGKAJYFLAIYELAEKNMALLNMAMPNMALQNMAN|AILATAHLAOCEKACCDKAUCKKAVCJKADECLAGEILACEHLADGCKAGGBKAWGIKACGHKADIELAGIDLAEIKLACIJLADKEKAGKDKAEKKKACKJKADMCLAGMBLAJMILAGMHLAEOEKAGODKAEOKKAGOJKAEQELAGQDLAJQKLAGQJLAESGKAGSFKAESMKAGSLKAEUELAIUDLAJUKLAGUJLAEWCKAPWIKAGWHKAEYGLAIYFLAJKNMALONMAMPNMAL|AILABCFKACCEKADCKKAXEDLAGECLAEEJLACEILADGDKAGGCKAEGJKACGIKADIFLAGIELAEILLACIKLADKFKAGKEKAEKLKACKKKADMDLAGMCLAEMJLACMILAEOFKAGOEKAEOLKACOKKAEQFLAGQELAEQLLAGQKLAESBKAISHKAGSGKAEUFLAIUELAJULLAGUKLAEWDKAIWCKAUWJKAGWIKAEYHLAIYGLAJJNMANKNMALONMAMPNMAL|CGKACCFKADEELAGEDLAEEKLACEJLADGEKAGGDKAEGKKACGJKADIALAYIGLAGIFLAEIMLACILLADKAKAZKGKAGKFKAEKMKACKLKADMELAGMDLAEMKLACMJLADOAKAaOGKAGOFKAEOMKACOLKADQALAbQGLAGQFLAEQMLACQLLAESCKAISBKAJSIKAGSHKAEUGLAGUFLAJUMLAcULLAEWEKAIWDKAJWKKAGWJKAEYILAGYHLAJJNMANKNMALONMAM|AFLATCHKACCGKADEFLACEELAEELLACEKLADGFKAGGEKAEGLKACGKKADIBLAGIALAdIHLACIGLAEINPAeKBKAGKAKAfKHKAGKGKAEKNOAgMFLAGMELAEMLLACMKLADOBKAIOAKAhOHKAGOGKAEONOAiQBLAIQALAjQHLAGQGLAEQNPAkSDKAISCKAJSJKAGSIKAEUBLAlUHLAGUGLAEWFKAIWEKAJWLKAmWKKAEYJLAlYILAEINMABJNMANNNMAnONMAM|AGLAAAFLABCIKACCHKADEGLACEFLADELLADGGKACGFKAEGMKAFGLKADICLAGIBLAEIILACIHLADKCKAGKBKAEKIKACKHKAEMALAHMGLAGMFLAEMMLACMLLADOCKAIOBKAJOIKAGOHKAEQCLAIQBLAJQILAGQHLAESEKAISDKAJSKKAGSJKAEUCLAIUBLADUILAGUHLAEWGKAIWFKAJWLKAKYELAGYJLADINMABJNMANNNMAnONMAM|AHLAAAGLAOCDKAPCJKACCIKADEHLACEGLADGBKAQGHKACGGKADIDLAGICLAEIJLACIILADKDKAGKCKAEKJKACKIKADMBLAIMALARMHLAGMGLAEMNPASODKAGOCKAJOJKAGOIKAEQDLAIQCLAJQJLAGQILAESFKAGSEKAJSLKAGSKKAEUDLAIUCLAJUJLAGUILAEWHKAGWGKAJYFLAIYELAEINMABMNMAnNNMAnRNMAB|AILATAHLAOCEKACCDKAUCKKAVCJKADECLAGEILACEHLADGCKAGGBKAWGIKACGHKADIELAGIDLAEIKLACIJLADKEKAGKDKAEKKKACKJKADMCLAGMBLAJMILAGMHLAEOEKAGODKAEOKKAGOJKAEQELAGQDLAJQKLAGQJLAESGKAGSFKAESMKAGSLKAEUELAIUDLAJUKLAGUJLAEWCKAPWIKAGWHKAEYGLAIYFLAJINMABMNMAnNNMAnRNMAB|AILABCFKACCEKADCKKAXEDLAGECLAEEJLACEILADGDKAGGCKAEGJKACGIKADIFLAGIELAEILLACIKLADKFKAGKEKAEKLKACKKKADMDLAGMCLAEMJLACMILAEOFKAGOEKAEOLKACOKKAEQFLAGQELAEQLLAGQKLAESBKAISHKAGSGKAEUFLAIUELAJULLAGUKLAEWDKAIWCKAUWJKAGWIKAEYHLAIYGLAJINMABMNMAnQNMANRNMAB|CGKACCFKADEELAGEDLAEEKLACEJLADGEKAGGDKAEGKKACGJKADIALAYIGLAGIFLAEIMLACILLADKAKAZKGKAGKFKAEKMKACKLKADMELAGMDLAEMKLACMJLADOAKAaOGKAGOFKAEOMKACOLKADQALAbQGLAGQFLAEQMLACQLLAESCKAISBKAJSIKAGSHKAEUGLAGUFLAJUMLAcULLAEWEKAIWDKAJWKKAGWJKAEYILAGYHLAJLNMAMMNMAnQNMANRNMAB|AFLATCHKACCGKADEFLACEELAEELLACEKLADGFKAGGEKAEGLKACGKKADIBLAGIALAdIHLACIGLAEINPAeKBKAGKAKAfKHKAGKGKAEKNOAgMFLAGMELAEMLLACMKLADOBKAIOAKAhOHKAGOGKAEONOAiQBLAIQALAjQHLAGQGLAEQNPAkSDKAISCKAJSJKAGSIKAEUBLAlUHLAGUGLAEWFKAIWEKAJWLKAmWKKAEYJLAlYILAELNMAMMNMAnQNMAN|AGLAAAFLABCEKACCDKAUCIKACCHKADECLAGEGLACEFLADEKLACEJLADGCKAGGBKAWGGKACGFKAEGKKACGJKADIALAYIELAGIDLAEIILACIHLADIMLACILLADKAKAZKEKAGKDKAEKIKACKHKAEKMKACKLKADMCLAGMBLAJMGLAGMFLAEMKLACMJLADOAKAaOEKAGODKAEOIKAGOHKAEOMKACOLKADQALAbQELAGQDLAJQILAGQHLAEQMLACQLLAESCKAISBKAJSGKAGSFKAESKKAGSJKAEUELAIUDLAJUILAGUHLAEUMLAcULLAEWCKAPWGKAIWFKAJWKKAGWJKAEYGLAIYFLAJYJLADKNMALLNMAMPNMALQNMAN|AHLAAAGLAOCFKACCEKADCJKACCIKADEDLAGECLAEEHLACEGLADELLACEKLADGDKAGGCKAEGHKACGGKADGLKACGKKADIBLAGIALAdIFLAGIELAEIJLACIILADINPAeKBKAGKAKAfKFKAGKEKAEKJKACKIKADKNOAgMDLAGMCLAEMHLAGMGLAEMLLACMKLADOBKAIOAKAhOFKAGOEKAEOJKAGOIKAEONOAiQBLAIQALAjQFLAGQELAEQJLAGQILAEQNPAkSDKAISCKAJSHKAGSGKAESLKAGSKKAEUBLAlUFLAIUELAJUJLAGUILAEWDKAIWCKAUWHKAGWGKAJWLKAmWKKAEYHLAIYGLAJKNMALLNMAMPNMALQNMAN|AILATAHLAOCGKACCFKADCKKAVCJKADEELAGEDLAEEILACEHLADELLADGEKAGGDKAEGIKACGHKADGMKAFGLKADICLAGIBLAEIGLAGIFLAEIKLACIJLADKCKAGKBKAEKGKAGKFKAEKKKACKJKADMALAHMELAGMDLAEMILAGMHLAEMMLACMLLADOCKAIOBKAJOGKAGOFKAEOKKAGOJKAEQCLAIQBLAJQGLAGQFLAEQKLAGQJLAESEKAISDKAJSIKAGSHKAESMKAGSLKAEUCLAIUBLADUGLAGUFLAJUKLAGUJLAEWEKAIWDKAJWIKAGWHKAEWLKAKYELAGYILAGYHLAJKNMALONMAMPNMAL|AFLATAILABCDKAPCHKACCGKADCKKAXEFLACEELAEEJLACEILADGBKAQGFKAGGEKAEGJKACGIKADIDLAGICLAEIHLACIGLAEILLACIKLADKDKAGKCKAEKHKAGKGKAEKLKACKKKADMBLAIMALARMFLAGMELAEMJLACMILAEMNPASODKAGOCKAJOHKAGOGKAEOLKACOKKAEQDLAIQCLAJQHLAGQGLAEQLLAGQKLAESBKAISFKAGSEKAJSJKAGSIKAEUDLAIUCLAJUHLAGUGLAEULLAGUKLAEWFKAIWEKAJWJKAGWIKAEYFLAIYELAEYJLAlYILAEJNMANKNMALONMAMPNMAL|AGLAAAFLABCEKACCDKAUCIKACCHKADECLAGEGLACEFLADEKLACEJLADGCKAGGBKAWGGKACGFKAEGKKACGJKADIALAYIELAGIDLAEIILACIHLADIMLACILLADKAKAZKEKAGKDKAEKIKACKHKAEKMKACKLKADMCLAGMBLAJMGLAGMFLAEMKLACMJLADOAKAaOEKAGODKAEOIKAGOHKAEOMKACOLKADQALAbQELAGQDLAJQILAGQHLAEQMLACQLLAESCKAISBKAJSGKAGSFKAESKKAGSJKAEUELAIUDLAJUILAGUHLAEUMLAcULLAEWCKAPWGKAIWFKAJWKKAGWJKAEYGLAIYFLAJYJLADJNMANKNMALONMAM|AHLAAAGLAOCFKACCEKADCJKACCIKADEDLAGECLAEEHLACEGLADELLACEKLADGDKAGGCKAEGHKACGGKADGLKACGKKADIBLAGIALAdIFLAGIELAEIJLACIILADINPAeKBKAGKAKAfKFKAGKEKAEKJKACKIKADKNOAgMDLAGMCLAEMHLAGMGLAEMLLACMKLADOBKAIOAKAhOFKAGOEKAEOJKAGOIKAEONOAiQBLAIQALAjQFLAGQELAEQJLAGQILAEQNPAkSDKAISCKAJSHKAGSGKAESLKAGSKKAEUBLAlUFLAIUELAJUJLAGUILAEWDKAIWCKAUWHKAGWGKAJWLKAmWKKAEYHLAIYGLAJINMABJNMANNNMAnONMAM|AILATAHLAOCGKACCFKADCKKAVCJKADEELAGEDLAEEILACEHLADELLADGEKAGGDKAEGIKACGHKADGMKAFGLKADICLAGIBLAEIGLAGIFLAEIKLACIJLADKCKAGKBKAEKGKAGKFKAEKKKACKJKADMALAHMELAGMDLAEMILAGMHLAEMMLACMLLADOCKAIOBKAJOGKAGOFKAEOKKAGOJKAEQCLAIQBLAJQGLAGQFLAEQKLAGQJLAESEKAISDKAJSIKAGSHKAESMKAGSLKAEUCLAIUBLADUGLAGUFLAJUKLAGUJLAEWEKAIWDKAJWIKAGWHKAEWLKAKYELAGYILAGYHLAJINMABJNMANNNMAnONMAM|AFLATAILABCDKAPCHKACCGKADCKKAXEFLACEELAEEJLACEILADGBKAQGFKAGGEKAEGJKACGIKADIDLAGICLAEIHLACIGLAEILLACIKLADKDKAGKCKAEKHKAGKGKAEKLKACKKKADMBLAIMALARMFLAGMELAEMJLACMILAEMNPASODKAGOCKAJOHKAGOGKAEOLKACOKKAEQDLAIQCLAJQHLAGQGLAEQLLAGQKLAESBKAISFKAGSEKAJSJKAGSIKAEUDLAIUCLAJUHLAGUGLAEULLAGUKLAEWFKAIWEKAJWJKAGWIKAEYFLAIYELAEYJLAlYILAEINMABMNMAnNNMAnRNMAB|AGLAAAFLABCEKACCDKAUCIKACCHKADECLAGEGLACEFLADEKLACEJLADGCKAGGBKAWGGKACGFKAEGKKACGJKADIALAYIELAGIDLAEIILACIHLADIMLACILLADKAKAZKEKAGKDKAEKIKACKHKAEKMKACKLKADMCLAGMBLAJMGLAGMFLAEMKLACMJLADOAKAaOEKAGODKAEOIKAGOHKAEOMKACOLKADQALAbQELAGQDLAJQILAGQHLAEQMLACQLLAESCKAISBKAJSGKAGSFKAESKKAGSJKAEUELAIUDLAJUILAGUHLAEUMLAcULLAEWCKAPWGKAIWFKAJWKKAGWJKAEYGLAIYFLAJYJLADINMABMNMAnNNMAnRNMAB|AHLAAAGLAOCFKACCEKADCJKACCIKADEDLAGECLAEEHLACEGLADELLACEKLADGDKAGGCKAEGHKACGGKADGLKACGKKADIBLAGIALAdIFLAGIELAEIJLACIILADINPAeKBKAGKAKAfKFKAGKEKAEKJKACKIKADKNOAgMDLAGMCLAEMHLAGMGLAEMLLACMKLADOBKAIOAKAhOFKAGOEKAEOJKAGOIKAEONOAiQBLAIQALAjQFLAGQELAEQJLAGQILAEQNPAkSDKAISCKAJSHKAGSGKAESLKAGSKKAEUBLAlUFLAIUELAJUJLAGUILAEWDKAIWCKAUWHKAGWGKAJWLKAmWKKAEYHLAIYGLAJINMABMNMAnQNMANRNMAB|AILATAHLAOCGKACCFKADCKKAVCJKADEELAGEDLAEEILACEHLADELLADGEKAGGDKAEGIKACGHKADGMKAFGLKADICLAGIBLAEIGLAGIFLAEIKLACIJLADKCKAGKBKAEKGKAGKFKAEKKKACKJKADMALAHMELAGMDLAEMILAGMHLAEMMLACMLLADOCKAIOBKAJOGKAGOFKAEOKKAGOJKAEQCLAIQBLAJQGLAGQFLAEQKLAGQJLAESEKAISDKAJSIKAGSHKAESMKAGSLKAEUCLAIUBLADUGLAGUFLAJUKLAGUJLAEWEKAIWDKAJWIKAGWHKAEWLKAKYELAGYILAGYHLAJLNMAMMNMAnQNMANRNMAB|AFLATAILABCDKAPCHKACCGKADCKKAXEFLACEELAEEJLACEILADGBKAQGFKAGGEKAEGJKACGIKADIDLAGICLAEIHLACIGLAEILLACIKLADKDKAGKCKAEKHKAGKGKAEKLKACKKKADMBLAIMALARMFLAGMELAEMJLACMILAEMNPASODKAGOCKAJOHKAGOGKAEOLKACOKKAEQDLAIQCLAJQHLAGQGLAEQLLAGQKLAESBKAISFKAGSEKAJSJKAGSIKAEUDLAIUCLAJUHLAGUGLAEULLAGUKLAEWFKAIWEKAJWJKAGWIKAEYFLAIYELAEYJLAlYILAELNMAMMNMAnQNMAN|AGLAAAFLABCIKACCHKADEGLACEFLADELLADGGKACGFKAEGMKAFGLKADICLAGIBLAEIILACIHLADKCKAGKBKAEKIKACKHKAEMALAHMGLAGMFLAEMMLACMLLADOCKAIOBKAJOIKAGOHKAEQCLAIQBLAJQILAGQHLAESEKAISDKAJSKKAGSJKAEUCLAIUBLADUILAGUHLAEWGKAIWFKAJWLKAKYELAGYJLADKNMALLNMAMPNMALQNMAN|AHLAAAGLAOCDKAPCJKACCIKADEHLACEGLADGBKAQGHKACGGKADIDLAGICLAEIJLACIILADKDKAGKCKAEKJKACKIKADMBLAIMALARMHLAGMGLAEMNPASODKAGOCKAJOJKAGOIKAEQDLAIQCLAJQJLAGQILAESFKAGSEKAJSLKAGSKKAEUDLAIUCLAJUJLAGUILAEWHKAGWGKAJYFLAIYELAEKNMALLNMAMPNMALQNMAN|AILATAHLAOCEKACCDKAUCKKAVCJKADECLAGEILACEHLADGCKAGGBKAWGIKACGHKADIELAGIDLAEIKLACIJLADKEKAGKDKAEKKKACKJKADMCLAGMBLAJMILAGMHLAEOEKAGODKAEOKKAGOJKAEQELAGQDLAJQKLAGQJLAESGKAGSFKAESMKAGSLKAEUELAIUDLAJUKLAGUJLAEWCKAPWIKAGWHKAEYGLAIYFLAJKNMALONMAMPNMAL|AILABCFKACCEKADCKKAXEDLAGECLAEEJLACEILADGDKAGGCKAEGJKACGIKADIFLAGIELAEILLACIKLADKFKAGKEKAEKLKACKKKADMDLAGMCLAEMJLACMILAEOFKAGOEKAEOLKACOKKAEQFLAGQELAEQLLAGQKLAESBKAISHKAGSGKAEUFLAIUELAJULLAGUKLAEWDKAIWCKAUWJKAGWIKAEYHLAIYGLAJJNMANKNMALONMAMPNMAL|CGKACCFKADEELAGEDLAEEKLACEJLADGEKAGGDKAEGKKACGJKADIALAYIGLAGIFLAEIMLACILLADKAKAZKGKAGKFKAEKMKACKLKADMELAGMDLAEMKLACMJLADOAKAaOGKAGOFKAEOMKACOLKADQALAbQGLAGQFLAEQMLACQLLAESCKAISBKAJSIKAGSHKAEUGLAGUFLAJUMLAcULLAEWEKAIWDKAJWKKAGWJKAEYILAGYHLAJJNMANKNMALONMAM|AFLATCHKACCGKADEFLACEELAEELLACEKLADGFKAGGEKAEGLKACGKKADIBLAGIALAdIHLACIGLAEINPAeKBKAGKAKAfKHKAGKGKAEKNOAgMFLAGMELAEMLLACMKLADOBKAIOAKAhOHKAGOGKAEONOAiQBLAIQALAjQHLAGQGLAEQNPAkSDKAISCKAJSJKAGSIKAEUBLAlUHLAGUGLAEWFKAIWEKAJWLKAmWKKAEYJLAlYILAEINMABJNMANNNMAnONMAM|AGLAAAFLABCIKACCHKADEGLACEFLADELLADGGKACGFKAEGMKAFGLKADICLAGIBLAEIILACIHLADKCKAGKBKAEKIKACKHKAEMALAHMGLAGMFLAEMMLACMLLADOCKAIOBKAJOIKAGOHKAEQCLAIQBLAJQILAGQHLAESEKAISDKAJSKKAGSJKAEUCLAIUBLADUILAGUHLAEWGKAIWFKAJWLKAKYELAGYJLADINMABJNMANNNMAnONMAM|AHLAAAGLAOCDKAPCJKACCIKADEHLACEGLADGBKAQGHKACGGKADIDLAGICLAEIJLACIILADKDKAGKCKAEKJKACKIKADMBLAIMALARMHLAGMGLAEMNPASODKAGOCKAJOJKAGOIKAEQDLAIQCLAJQJLAGQILAESFKAGSEKAJSLKAGSKKAEUDLAIUCLAJUJLAGUILAEWHKAGWGKAJYFLAIYELAEINMABMNMAnNNMAnRNMAB|AILATAHLAOCEKACCDKAUCKKAVCJKADECLAGEILACEHLADGCKAGGBKAWGIKACGHKADIELAGIDLAEIKLACIJLADKEKAGKDKAEKKKACKJKADMCLAGMBLAJMILAGMHLAEOEKAGODKAEOKKAGOJKAEQELAGQDLAJQKLAGQJLAESGKAGSFKAESMKAGSLKAEUELAIUDLAJUKLAGUJLAEWCKAPWIKAGWHKAEYGLAIYFLAJINMABMNMAnNNMAnRNMAB|AILABCFKACCEKADCKKAXEDLAGECLAEEJLACEILADGDKAGGCKAEGJKACGIKADIFLAGIELAEILLACIKLADKFKAGKEKAEKLKACKKKADMDLAGMCLAEMJLACMILAEOFKAGOEKAEOLKACOKKAEQFLAGQELAEQLLAGQKLAESBKAISHKAGSGKAEUFLAIUELAJULLAGUKLAEWDKAIWCKAUWJKAGWIKAEYHLAIYGLAJINMABMNMAnQNMANRNMAB|CGKACCFKADEELAGEDLAEEKLACEJLADGEKAGGDKAEGKKACGJKADIALAYIGLAGIFLAEIMLACILLADKAKAZKGKAGKFKAEKMKACKLKADMELAGMDLAEMKLACMJLADOAKAaOGKAGOFKAEOMKACOLKADQALAbQGLAGQFLAEQMLACQLLAESCKAISBKAJSIKAGSHKAEUGLAGUFLAJUMLAcULLAEWEKAIWDKAJWKKAGWJKAEYILAGYHLAJLNMAMMNMAnQNMANRNMAB|AFLATCHKACCGKADEFLACEELAEELLACEKLADGFKAGGEKAEGLKACGKKADIBLAGIALAdIHLACIGLAEINPAeKBKAGKAKAfKHKAGKGKAEKNOAgMFLAGMELAEMLLACMKLADOBKAIOAKAhOHKAGOGKAEONOAiQBLAIQALAjQHLAGQGLAEQNPAkSDKAISCKAJSJKAGSIKAEUBLAlUHLAGUGLAEWFKAIWEKAJWLKAmWKKAEYJLAlYILAELNMAMMNMAnQNMAN|AGLAAAFLABCIKACCHKADEGLACEFLADELLADGGKACGFKAEGMKAFGLKADICLAGIBLAEIILACIHLADKCKAGKBKAEKIKACKHKAEMALAHMGLAGMFLAEMMLACMLLADOCKAIOBKAJOIKAGOHKAEQCLAIQBLAJQILAGQHLAESEKAISDKAJSKKAGSJKAEUCLAIUBLADUILAGUHLAEWGKAIWFKAJWLKAKYELAGYJLADKNMALLNMAMPNMALQNMAN|AHLAAAGLAOCDKAPCJKACCIKADEHLACEGLADGBKAQGHKACGGKADIDLAGICLAEIJLACIILADKDKAGKCKAEKJKACKIKADMBLAIMALARMHLAGMGLAEMNPASODKAGOCKAJOJKAGOIKAEQDLAIQCLAJQJLAGQILAESFKAGSEKAJSLKAGSKKAEUDLAIUCLAJUJLAGUILAEWHKAGWGKAJYFLAIYELAEKNMALLNMAMPNMALQNMAN|AILATAHLAOCEKACCDKAUCKKAVCJKADECLAGEILACEHLADGCKAGGBKAWGIKACGHKADIELAGIDLAEIKLACIJLADKEKAGKDKAEKKKACKJKADMCLAGMBLAJMILAGMHLAEOEKAGODKAEOKKAGOJKAEQELAGQDLAJQKLAGQJLAESGKAGSFKAESMKAGSLKAEUELAIUDLAJUKLAGUJLAEWCKAPWIKAGWHKAEYGLAIYFLAJKNMALONMAMPNMAL|AILABCFKACCEKADCKKAXEDLAGECLAEEJLACEILADGDKAGGCKAEGJKACGIKADIFLAGIELAEILLACIKLADKFKAGKEKAEKLKACKKKADMDLAGMCLAEMJLACMILAEOFKAGOEKAEOLKACOKKAEQFLAGQELAEQLLAGQKLAESBKAISHKAGSGKAEUFLAIUELAJULLAGUKLAEWDKAIWCKAUWJKAGWIKAEYHLAIYGLAJJNMANKNMALONMAMPNMAL|CGKACCFKADEELAGEDLAEEKLACEJLADGEKAGGDKAEGKKACGJKADIALAYIGLAGIFLAEIMLACILLADKAKAZKGKAGKFKAEKMKACKLKADMELAGMDLAEMKLACMJLADOAKAaOGKAGOFKAEOMKACOLKADQALAbQGLAGQFLAEQMLACQLLAESCKAISBKAJSIKAGSHKAEUGLAGUFLAJUMLAcULLAEWEKAIWDKAJWKKAGWJKAEYILAGYHLAJJNMANKNMALONMAM|AFLATCHKACCGKADEFLACEELAEELLACEKLADGFKAGGEKAEGLKACGKKADIBLAGIALAdIHLACIGLAEINPAeKBKAGKAKAfKHKAGKGKAEKNOAgMFLAGMELAEMLLACMKLADOBKAIOAKAhOHKAGOGKAEONOAiQBLAIQALAjQHLAGQGLAEQNPAkSDKAISCKAJSJKAGSIKAEUBLAlUHLAGUGLAEWFKAIWEKAJWLKAmWKKAEYJLAlYILAEINMABJNMANNNMAnONMAM|AGLAAAFLABCIKACCHKADEGLACEFLADELLADGGKACGFKAEGMKAFGLKADICLAGIBLAEIILACIHLADKCKAGKBKAEKIKACKHKAEMALAHMGLAGMFLAEMMLACMLLADOCKAIOBKAJOIKAGOHKAEQCLAIQBLAJQILAGQHLAESEKAISDKAJSKKAGSJKAEUCLAIUBLADUILAGUHLAEWGKAIWFKAJWLKAKYELAGYJLADINMABJNMANNNMAnONMAM|AHLAAAGLAOCDKAPCJKACCIKADEHLACEGLADGBKAQGHKACGGKADIDLAGICLAEIJLACIILADKDKAGKCKAEKJKACKIKADMBLAIMALARMHLAGMGLAEMNPASODKAGOCKAJOJKAGOIKAEQDLAIQCLAJQJLAGQILAESFKAGSEKAJSLKAGSKKAEUDLAIUCLAJUJLAGUILAEWHKAGWGKAJYFLAIYELAEINMABMNMAnNNMAnRNMAB|AILATAHLAOCEKACCDKAUCKKAVCJKADECLAGEILACEHLADGCKAGGBKAWGIKACGHKADIELAGIDLAEIKLACIJLADKEKAGKDKAEKKKACKJKADMCLAGMBLAJMILAGMHLAEOEKAGODKAEOKKAGOJKAEQELAGQDLAJQKLAGQJLAESGKAGSFKAESMKAGSLKAEUELAIUDLAJUKLAGUJLAEWCKAPWIKAGWHKAEYGLAIYFLAJINMABMNMAnNNMAnRNMAB|AILABCFKACCEKADCKKAXEDLAGECLAEEJLACEILADGDKAGGCKAEGJKACGIKADIFLAGIELAEILLACIKLADKFKAGKEKAEKLKACKKKADMDLAGMCLAEMJLACMILAEOFKAGOEKAEOLKACOKKAEQFLAGQELAEQLLAGQKLAESBKAISHKAGSGKAEUFLAIUELAJULLAGUKLAEWDKAIWCKAUWJKAGWIKAEYHLAIYGLAJINMABMNMAnQNMANRNMAB|CGKACCFKADEELAGEDLAEEKLACEJLADGEKAGGDKAEGKKACGJKADIALAYIGLAGIFLAEIMLACILLADKAKAZKGKAGKFKAEKMKACKLKADMELAGMDLAEMKLACMJLADOAKAaOGKAGOFKAEOMKACOLKADQALAbQGLAGQFLAEQMLACQLLAESCKAISBKAJSIKAGSHKAEUGLAGUFLAJUMLAcULLAEWEKAIWDKAJWKKAGWJKAEYILAGYHLAJLNMAMMNMAnQNMANRNMAB|AFLATCHKACCGKADEFLACEELAEELLACEKLADGFKAGGEKAEGLKACGKKADIBLAGIALAdIHLACIGLAEINPAeKBKAGKAKAfKHKAGKGKAEKNOAgMFLAGMELAEMLLACMKLADOBKAIOAKAhOHKAGOGKAEONOAiQBLAIQALAjQHLAGQGLAEQNPAkSDKAISCKAJSJKAGSIKAEUBLAlUHLAGUGLAEWFKAIWEKAJWLKAmWKKAEYJLAlYILAELNMAMMNMAnQNMAN'
VN_AL[rain]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[rain]='2034400c1820304c6018304420405c2c485c4064845080a45484ac2c5478102438182c3c1c344414243010202c3050683c607c285074485c68182430183048243c4c1c3c581024341c2c38446c8c4c789c34547024384c0c1c282028302444603c4c58284c6c4458641c344c303c44304c64243c501c3448'
VN_AF[earth]='DLCAACJCABEICABFHCABWGCACYECADYFAAEVDCAFVEAAEXDCAGUBCAHINQAILNQAJONSAJPNQAK|DLCAACJCABEICABFHCABWGCACYECADYFAAEVDCAFVEAAEXDCAGUBCAHINSAILNQAJONQAJPNSAKRNSAI|DLCAACJCABEICABFHCABWGCACYECADYFAAEVDCAFVEAAEXDCAGUBCAHKNSAKLNQAJONQAJRNQAI|DLCAACJCABEICABFHCABWGCACYECADYFAAEVDCAFVEAAEXDCAGUBCAHKNQAKLNSAJNNSALONQAJRNQAI|DKCABAICAICICABEHCABFGCABWFCACYEAAMVCCAFVDAAEUMCANKNQAKNNQALONSAJRNQAI|DKCABAICAICICABEHCABFGCABWFCACYEAAMVCCAFVDAAEUMCANJNSAOKNQAKNNQALQNSAORNQAI|DKCABAICAICICABEHCABFGCABWFCACYEAAMVCCAFVDAAEUMCANJNQAOKNSAKNNQALQNQAORNSAI|DKCABAICAICICABEHCABFGCABWFCACYEAAMVCCAFVDAAEUMCANJNQAOMNSALNNQALQNQAO|BJCAPDJCABAHCAQAIAARCHCABEGCABFFCASWECACVCAAEULCASJNQAOMNQALNNSALPNSAKQNQAO|BJCAPDJCABAHCAQAIAARCHCABEGCABFFCASWECACVCAAEULCASINSAIJNQAOMNQALPNQAKQNSAO|BJCAPDJCABAHCAQAIAARCHCABEGCABFFCASWECACVCAAEULCASINQAIJNSAOLNSAJMNQALPNQAK|BJCAPDJCABAHCAQAIAARCHCABEGCABFFCASWECACVCAAEULCASINQAILNQAJMNSALPNQAK|BICATBJAAUDICABAGCAQAHAAVCGCABEFCABFECASWDCACUKCASINQAILNQAJONSAJPNQAK|BICATBJAAUDICABAGCAQAHAAVCGCABEFCABFECASWDCACUKCASINSAILNQAJONQAJPNSAKRNSAI|BICATBJAAUDICABAGCAQAHAAVCGCABEFCABFECASWDCACUKCASKNSAKLNQAJONQAJRNQAI|BICATBJAAUDICABAGCAQAHAAVCGCABEFCABFECASWDCACUKCASKNQAKLNSAJNNSALONQAJRNQAI|BHCATBIAABDHCABAFCAIAGAAVCFCABEECASFDCASWCCAWVLCAXUJCASKNQAKNNQALONSAJRNQAI|BHCATBIAABDHCABAFCAIAGAAVCFCABEECASFDCASWCCAWVLCAXUJCASJNSAOKNQAKNNQALQNSAORNQAI|BHCATBIAABDHCABAFCAIAGAAVCFCABEECASFDCASWCCAWVLCAXUJCASJNQAOKNSAKNNQALQNQAORNSAI|BHCATBIAABDHCABAFCAIAGAAVCFCABEECASFDCASWCCAWVLCAXUJCASJNQAOMNSALNNQALQNQAO|BGCATBHAABDGCABAFAARCECABEDCASFCCASVKCAXVLAAYXKCAWUICASFMGAZINSAIJNQAOKMGATLMGATMNQALNNSALPNSAKQNQAOQMGATRMGAT|CGCATCHAABEGCABBECAPBFAABDECASFDCASGCCASWKCAXWLAAaVICASINSAIJNQAOJMGATKMGATLNSAJMNQALNNSALPNQAKPMGATQNSAOQMGAT|BGCATBHAABDGCABAFAARCECABEDCASFCCASVKCAXVLAAYXKCAWUICASINQAIIMGATJNSAOJMGATKMGATLNSAJMNQALOMGATPNQAKPMGATQNSAOQMGATUMGAb|CGCATCHAABEGCABBECAPBFAABDECASFDCASGCCASWKCAXWLAAaVICASINQAIIMGATJNSAOJMGATLNQAJMNSALONSAJOMGATPNQAKPMGATUMGAb|BFCATBGAABDFCABCDCAWECCASFBCANVJCAXVKAAYXJCASZICAcUHCASHMGATINQAIIMGATLNQAJMNSALNMGATONSAJOMGATPNQAKRNSAITMGAdUMGAb|CFCATCGAABEFCABBEAAUDDCASFCCASGBCALWJCAXWKAAYYJCAeVHCASGMGAfHMGATINSAIKNSAKLNQAJMMGATNMGATONQAJPNSAKRNSAISMGAXTMGAd|BFCATBGAABDFCABCDCAWECCASFBCANVJCAXVKAAYXJCASZICAcUHCASFMGAZGMGAfHMGATINSAIKNSAKLNQAJLMGATMMGATNNSALNMGATONQAJPNSAKRNQAIRMGATSMGAXTMGAd|CFCATCGAABEFCABBEAAUDDCASFCCASGBCALWJCAXWKAAYYJCAeVHCASFMGAZGMGAfKNQAKLNSAJLMGATMMGATNNSALONQAJRNQAIRMGATSMGAX|BECAPBFAABDECASFMCAgWLCAhYJCAiVICAXVJAAYXICASZHCAjUGCASKNQAKNNQALONSAJRNQAI|BECAPBFAABDECASFMCAgWLCAhYJCAiVICAXVJAAYXICASZHCAjUGCASJNSAOKNQAKNNQALQNSAORNQAI|BECAPBFAABDECASFMCAgWLCAhYJCAiVICAXVJAAYXICASZHCAjUGCASJNQAOKNSAKNNQALQNQAORNSAI|BECAPBFAABDECASFMCAgWLCAhYJCAiVICAXVJAAYXICASZHCAjUGCASJNQAOMNSALNNQALQNQAO|BEAAUDDCASFLCABWKCASYICAXYJAAkVHCAXVIAAYXHCASZGCAjUFCACJNQAOMNQALNNSALPNSAKQNQAO|BEAAUDDCASFLCABWKCASYICAXYJAAkVHCAXVIAAYXHCASZGCAjUFCACINSAIJNQAOMNQALPNQAKQNSAO|BEAAUDDCASFLCABWKCASYICAXYJAAkVHCAXVIAAYXHCASZGCAjUFCACINQAIJNSAOLNSAJMNQALPNQAK|BEAAUDDCASFLCABWKCASYICAXYJAAkVHCAXVIAAYXHCASZGCAjUFCACINQAILNQAJMNSALPNQAK|DCCAhELCABFKCABWJCASYHCAFYIAAYVGCAXVHAAYXGCACZFCAOUECACINQAILNQAJONSAJPNQAK|DCCAhELCABFKCABWJCASYHCAFYIAAYVGCAXVHAAYXGCACZFCAOUECACINSAILNQAJONQAJPNSAKRNSAI|DCCAhELCABFKCABWJCASYHCAFYIAAYVGCAXVHAAYXGCACZFCAOUECACKNSAKLNQAJONQAJRNQAI|DCCAhELCABFKCABWJCASYHCAFYIAAYVGCAXVHAAYXGCACZFCAOUECACKNQAKLNSAJNNSALONQAJRNQAI|EKCABFJCABWICASYGCAFYHAAEVFCAFVGAAYXFCACUDCACKNQAKNNQALONSAJRNQAI|EKCABFJCABWICASYGCAFYHAAEVFCAFVGAAYXFCACUDCACJNSAOKNQAKNNQALQNSAORNQAI|EKCABFJCABWICASYGCAFYHAAEVFCAFVGAAYXFCACUDCACJNQAOKNSAKNNQALQNQAORNSAI|EKCABFJCABWICASYGCAFYHAAEVFCAFVGAAYXFCACUDCACJNQAOMNSALNNQALQNQAO|CKCAlEJCABFICABWHCASYFCAFYGAAEVECAFVFAAEXECACUCCACJNQAOMNQALNNSALPNSAKQNQAO|CKCAlEJCABFICABWHCASYFCAFYGAAEVECAFVFAAEXECACUCCACINSAIJNQAOMNQALPNQAKQNSAO|CKCAlEJCABFICABWHCASYFCAFYGAAEVECAFVFAAEXECACUCCACINQAIJNSAOLNSAJMNQALPNQAK|CKCAlEJCABFICABWHCASYFCAFYGAAEVECAFVFAAEXECACUCCACINQAILNQAJMNSALPNQAK'
VN_AL[earth]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[earth]='2c24184c3c2c846c50786c507c6048a08c6c6854404c402c2c241c5c4c3850443460503c5c483438302440342844382c3c3428241c14645440584c3c382c2034281c5040307c6c54644c38342c203c2c204840303028207464504c40305448382c20183c30245c50405848344c38283c3020'
VN_AF[air]='FBUAARBUABQBUACPBUADOBUAEDEUAFCEUAGBEUAHPEUAFOEUAINEUAJMEUAKYEUALHGMAFGGMAGFGMAMEGMANTGMAFSGMAIRGMAJQGMAKJIUAOIIUAGHIUAMGIUANVIUAFUIUAITIUAJSIUAKELUAODLUAPQLUAFPLUAGOLUAMNLUANMMUAOLMUAGKMUAMJMUANMJPAG|GBUAQFBUARSBUABRBUACQBUADPBUAEEEUAFDEUAICEUAMBEUASQEUAFPEUAIOEUAJNEUAKIGMAFHGMAIGGMAMFGMANUGMAFTGMAISGMAJRGMAKKIUAOJIUAGIIUAMHIUANWIUAFVIUAIUIUAJTIUAKFLUAOELUAGDLUATRLUAFQLUAIPLUAMOLUANNMUAOMMUAGLMUAMKMUANMIJAI|HBUAFGBUAUFBUAVTBUAWSBUACRBUADQBUAEFEUAFEEUAIDEUAJCEUANREUAFQEUAIPEUAJOEUAKJGMAFIGMAIHGMAJGGMANVGMAFUGMAITGMAJSGMAKLIUAFKIUAGJIUAMIIUANXIUAFWIUAIVIUAJUIUAKGLUAOFLUAGELUAMDLUAXSLUAFRLUAIQLUAJPLUANOMUAONMUAGMMUAMLMUANNIXAI|IBUAFHBUAIGBUAYFBUAZUBUAaTBUAbSBUADRBUAEGEUAFFEUAIEEUAJDEUAKSEUABREUAIQEUAJPEUAKKGMAFJGMAIIGMAJHGMAKWGMABVGMAIUGMAJTGMAKAIUAcMIUAFLIUAIKIUAMJIUANYIUAFXIUAIWIUAJVIUAKHLUAOGLUAGFLUAMELUANTLUAFSLUAIRLUAJQLUAKPMUAOOMUAGNMUAMMMUANNIZAI|JBUAFIBUAIHBUAJGBUAdUBUAeTBUAfSBUAEHEUAFGEUAIFEUAJEEUAKTEUABSEUACREUAJQEUAKLGMAFKGMAIJGMAJIGMAKXGMABWGMACVGMAJUGMAKBIUAOAIUAgNIUAFMIUAILIUAJKIUANZIUAhYIUAIXIUAJWIUAKILUAOHLUAGGLUAMFLUANULUAFTLUAISLUAJRLUAKQMUAOPMUAGOMUAMNMUANOIPAI|KBUAFJBUAIIBUAJHBUAKUBUAiTBUAjIEUAFHEUAIGEUAJFEUAKUEUABTEUACSEUADREUAKAGMAhMGMAFLGMAIKGMAJJGMAKYGMABXGMACWGMADVGMAKCIUAOBIUAGAIUAkOIUAFNIUAIMIUAJLIUAKZIUAlYIUAJXIUAKJLUAOILUAGHLUAMGLUANVLUAFULUAITLUAJSLUAKFMUAmRMUAOQMUAGPMUAMOMUANOIJAI|NAMAWMAMAnLAMAoKAMApKBMAFJBMAIIBMAJHBMAKUBMAiTBMAjDDUAFCDUAqPDUAFODUAINDUAJMDUAKJEUAFIEUAIHEUAJGEUAKVEUABUEUACTEUADSEUAEEFUAODFUAGCFUAMBFUANQFUAFPFUAIOFUAJNFUAKZFUArBHMAOAHMAlNHMAFMHMAILHMAJKHMAKZHMAsYHMACXHMAJWHMAKGIMAOFIMAGEIMAMDIMANSIMAFRIMAIQIMAJPIMAKLKUAOKKUAGJKUAMIKUANXKUAtWKUAIVKUAJUKUAKILUAOHLUAGGLUAMFLUANULUAFTLUAISLUAJRLUAKOMUAONMUAGMMUAMLMUANKNUAuJNUAvINUAwPJXAI|OAMAxNAMAnMAMAyLAMAzLBMAFKBMAIJBMAJIBMAKUBMA0EDUAFDDUAICDUA1QDUABPDUAIODUAJNDUAKKEUAFJEUAIIEUAJHEUAKWEUABVEUACUEUADTEUAEFFUAFEFUAGDFUAMCFUANRFUAFQFUAIPFUAJOFUAKCHMAOBHMAGAHMA2OHMAFNHMAIMHMAJLHMAKZHMA3YHMADXHMAKHIMAOGIMAGFIMAMEIMANTIMAFSIMAIRIMAJQIMAKMKUAOLKUAGKKUAMJKUANXKUAqWKUAJVKUAKJLUAOILUAGHLUAMGLUANVLUAFULUAITLUAJSLUAKPMUAOOMUAGNMUAMMMUANLNUA4KNUARJNUA5INUA6PJZAI|PAMA7OAMA8NAMAyMAMA9MBMABLBMAIKBMAJJBMAKFDUAFEDUAIDDUAJCDUA+RDUABQDUACPDUAJODUAKLEUAFKEUAIJEUAJIEUAKXEUABWEUACVEUADUEUAEGFUAFFFUAIEFUAMDFUANSFUAFRFUAIQFUAJPFUAKDHMAOCHMAGBHMAMAHMA/PHMAFOHMAINHMAJMHMAKZHMBAYHMAEIIMAOHIMAGGIMAMFIMANUIMAFTIMAISIMAJRIMAKNKUAOMKUAGLKUAMKKUANXKUA1WKUAKKLUAOJLUAGILUAMHLUANWLUBBVLUAIULUAJTLUAKQMUAOPMUAGOMUAMNMUANMNUBCLNUBDKNUBEJNUBFQJPAI|QAMBGPAMBHOAMAoNAMA9NBMABMBMACLBMAJKBMAKGDUAFFDUAIEDUAJDDUAKSDUABRDUACQDUADPDUAKMEUAFLEUAIKEUAJJEUAKYEUBIXEUACWEUADVEUAEHFUAFGFUAIFFUAJEFUANTFUAFSFUAIRFUAJQFUAKEHMAODHMAGCHMAMBHMANQHMAFPHMAIOHMAJNHMAKZHMBJJIMAOIIMAGHIMAMGIMANVIMAFUIMAITIMAJSIMAKCKUAAOKUAFNKUAGMKUAMLKUANXKUA+LLUAOKLUAGJLUAMILUANWLUBKVLUAJULUAKFMUAmRMUAOQMUAGPMUAMOMUANNNUBCMNUBLLNUBMKNUBNQKJAI|RAMAAQAMBOPAMBPOAMAzOBMABNBMACMBMADLBMAKHDUAFGDUAIFDUAJEDUAKTDUABSDUACRDUADQDUAEBEUBQNEUAFMEUAILEUAJKEUAKYEUBRXEUADWEUAEIFUAFHFUAIGFUAJFFUAKUFUABTFUAISFUAJRFUAKFHMAOEHMAGDHMAMCHMANRHMAFQHMAIPHMAJOHMAKKIMAOJIMAGIIMAMHIMANWIMAFVIMAIUIMAJTIMAKDKUAOCKUBSPKUAFOKUAINKUAMMKUANMLUAOLLUAGKLUAMJLUANWLUAVVLUAKGMUA4FMUBTSMUAFRMUAGQMUAMPMUANONUA4NNUBLMNUBULNUArRJXAI|RAMARQAMBVPAMApPBMABOBMACNBMADMBMAEIDUAFHDUAIGDUAJFDUAKUDUABTDUACSDUADRDUAECEUAOBEUBWOEUAFNEUAIMEUAJLEUAKYEUBXXEUAEJFUAFIFUAIHFUAJGFUAKVFUABUFUACTFUAJSFUAKGHMAOFHMAGEHMAMDHMANSHMAFRHMAIQHMAJPHMAKLIMAFKIMAGJIMAMIIMANXIMAFWIMAIVIMAJUIMAKEKUAODKUAGCKUBYQKUAFPKUAIOKUAJNKUANNLUAOMLUAGLLUAMKLUANWLUBNHMUAOGMUBLFMUATTMUAQSMUAIRMUAMQMUANPNUAuONUBDNNUBUMNUBZRJZAI|RAMBaQAMBbQBMABPBMACOBMADNBMAEJDUAFIDUAIHDUAJGDUAKVDUABUDUACTDUADSDUAEDEUAFCEUAGBEUAHPEUAFOEUAINEUAJMEUAKYEUALKFUAFJFUAIIFUAJHFUAKWFUABVFUACUFUADTFUAKHHMAOGHMAGFHMAMEHMANTHMAFSHMAIRHMAJQHMAKAIMAcMIMAFLIMAIKIMAMJIMANYIMAFXIMAIWIMAJVIMAKFKUAOEKUAGDKUAMCKUBNRKUAFQKUAIPKUAJOKUAKOLUAONLUAGMLUAMLLUANIMUAOHMUAGGMUBUFMUBcUMUAATMUAUSMUAJRMUANQNUBdPNUARONUBMNNUBZECPAISJPAI|IAMBeRAMBNFBMAARBMABQBMACPBMADOBMAEKDUAFJDUAIIDUAJHDUAKWDUABVDUACUDUADTDUAEEEUAFDEUAICEUAMBEUASQEUAFPEUAIOEUAJNEUAKLFUAFKFUAIJFUAJIFUAKXFUABWFUACVFUADUFUAEIHMAOHHMAGGHMAMFHMANUHMAFTHMAISHMAJRHMAKBIMAOAIMAgNIMAFMIMAILIMAJKIMANZIMAhYIMAIXIMAJWIMAKGKUAOFKUAGEKUAMDKUANSKUAFRKUAIQKUAJPKUAKDLUBePLUAOOLUAGNLUAMMLUANJMUAOIMUAGHMUAMGMUBZUMUARTMUAYSMUAKRNUBfQNUAvPNUBEONUArECJAISIJAI|JAMBgIAMBhGBMAQFBMARSBMABRBMACQBMADPBMAELDUAFKDUAIJDUAJIDUAKXDUBiWDUACVDUADUDUAEFEUAFEEUAIDEUAJCEUANREUAFQEUAIPEUAJOEUAKAFUAcMFUAFLFUAIKFUAJJFUAKYFUABXFUACWFUADVFUAEJHMAFIHMAGHHMAMGHMANVHMAFUHMAITHMAJSHMAKCIMAOBIMAGAIMAkOIMAFNIMAIMIMAJLIMAKZIMAlYIMAJXIMAKHKUAOGKUAGFKUAMEKUANTKUAFSKUAIRKUAJQKUAKELUAODLUAPQLUAFPLUAGOLUAMNLUANKMUAOJMUAGIMUAMHMUANUMUAVTMUAdRNUBjQNUA5PNUBNFCXAITIXAI|KAMA7JAMBkIAMArHBMAFGBMAUFBMAVTBMAWSBMACRBMADQBMAEMDUAFLDUAIKDUAJJDUAKXDUBlWDUADVDUAEGEUAFFEUAIEEUAJDEUAKSEUABREUAIQEUAJPEUAKBFUAOAFUAgNFUAFMFUAILFUAJKFUAKZFUBmYFUACXFUADWFUAEKHMAFJHMAIIHMAMHHMANWHMAFVHMAIUHMAJTHMAKDIMAOCIMAGBIMAMAIMBnPIMAFOIMAINIMAJMIMAKZIMA2YIMAKIKUAOHKUAGGKUAMFKUANUKUAFTKUAISKUAJRKUAKFLUAOELUAGDLUATRLUAFQLUAIPLUAMOLUANLMUAOKMUAGJMUAMIMUANUMUAZRNUAwQNUBFFDZAITIZAI|LAMAxKAMBHJAMBMIAMBFIBMAFHBMAIGBMAYFBMAZUBMAaTBMAbSBMADRBMAENDUAFMDUAILDUAJKDUAKXDUBoWDUAEHEUAFGEUAIFEUAJEEUAKTEUABSEUACREUAJQEUAKCFUAOBFUAGAFUAkOFUAFNFUAIMFUAJLFUAKZFUBpYFUADXFUAELHMAFKHMAIJHMAJIHMANXHMAFWHMAIVHMAJUHMAKEIMAODIMAGCIMAMBIMANQIMAFPIMAIOIMAJNIMAKZIMBqJKUAOIKUAGHKUAMGKUANVKUAFUKUAITKUAJSKUAKGLUAOFLUAGELUAMDLUAXSLUAFRLUAIQLUAJPLUANMMUAOLMUAGKMUAMJMUANINUBfRNUA6GCPAIUIPAIKFPAI|MAMAWLAMA8KAMBPJAMBrJBMAFIBMAIHBMAJGBMAdUBMAeTBMAfSBMAECDUAtODUAFNDUAIMDUAJLDUAKXDUBsIEUAFHEUAIGEUAJFEUAKUEUABTEUACSEUADREUAKDFUAOCFUAGBFUAMAFUBnPFUAFOFUAINFUAJMFUAKZFUBMYFUAEAHMAhMHMAFLHMAIKHMAJJHMAKYHMABXHMAIWHMAJVHMAKFIMAOEIMAGDIMAMCIMANRIMAFQIMAIPIMAJOIMAKKKUAOJKUAGIKUAMHKUANWKUAFVKUAIUKUAJTKUAKHLUAOGLUAGFLUAMELUANTLUAFSLUAIRLUAJQLUAKNMUAOMMUAGLMUAMKMUANJNUBdINUBjGCJAIUIJAIKFJAI|NAMAWMAMAnLAMAoKAMApKBMAFJBMAIIBMAJHBMAKUBMAiTBMAjDDUAFCDUAqPDUAFODUAINDUAJMDUAKJEUAFIEUAIHEUAJGEUAKVEUABUEUACTEUADSEUAEEFUAODFUAGCFUAMBFUANQFUAFPFUAIOFUAJNFUAKZFUArBHMAOAHMAlNHMAFMHMAILHMAJKHMAKZHMAsYHMACXHMAJWHMAKGIMAOFIMAGEIMAMDIMANSIMAFRIMAIQIMAJPIMAKLKUAOKKUAGJKUAMIKUANXKUAtWKUAIVKUAJUKUAKILUAOHLUAGGLUAMFLUANULUAFTLUAISLUAJRLUAKOMUAONMUAGMMUAMLMUANKNUAuJNUAvINUAwHCXAIVJXAILFXAI|OAMAxNAMAnMAMAyLAMAzLBMAFKBMAIJBMAJIBMAKUBMA0EDUAFDDUAICDUA1QDUABPDUAIODUAJNDUAKKEUAFJEUAIIEUAJHEUAKWEUABVEUACUEUADTEUAEFFUAFEFUAGDFUAMCFUANRFUAFQFUAIPFUAJOFUAKCHMAOBHMAGAHMA2OHMAFNHMAIMHMAJLHMAKZHMA3YHMADXHMAKHIMAOGIMAGFIMAMEIMANTIMAFSIMAIRIMAJQIMAKMKUAOLKUAGKKUAMJKUANXKUAqWKUAJVKUAKJLUAOILUAGHLUAMGLUANVLUAFULUAITLUAJSLUAKPMUAOOMUAGNMUAMMMUANLNUA4KNUARJNUA5INUA6HBZAIVJZAILEZAI|NBUABMBUACLBUAJKBUAKLEUAFKEUAIJEUAJIEUAKXEUABWEUACVEUADUEUAEDGMAOCGMAGBGMAMAGMA/PGMAFOGMAINGMAJMGMAKZGMBAYGMAEFIUAOEIUAGDIUAMCIUANRIUAFQIUAIPIUAJOIUAKMLUAOLLUAGKLUAMJLUANWLUAVVLUAKIMUAOHMUAGGMUBUFMUBcUMUAATMUAUSMUAJRMUANIBPAIWJPAIMEPAI|OBUABNBUACMBUADLBUAKMEUAFLEUAIKEUAJJEUAKYEUBIXEUACWEUADVEUAEEGMAODGMAGCGMAMBGMANQGMAFPGMAIOGMAJNGMAKZGMBJGIUAOFIUAGEIUAMDIUANSIUAFRIUAIQIUAJPIUAKNLUAOMLUAGLLUAMKLUANWLUBNJMUAOIMUAGHMUAMGMUBZUMUARTMUAYSMUAKIBJAIWKJAIMEJAI|PBUABOBUACNBUADMBUAEBEUBQNEUAFMEUAILEUAJKEUAKYEUBRXEUADWEUAEFGMAOEGMAGDGMAMCGMANRGMAFQGMAIPGMAJOGMAKHIUAOGIUAGFIUAMEIUANTIUAFSIUAIRIUAJQIUAKOLUAONLUAGMLUAMLLUANKMUAOJMUAGIMUAMHMUANUMUAVTMUAdJBXAIXJXAINEXAI|QBUABPBUACOBUADNBUAECEUAOBEUBWOEUAFNEUAIMEUAJLEUAKYEUBXXEUAEGGMAOFGMAGEGMAMDGMANSGMAFRGMAIQGMAJPGMAKIIUAOHIUAGGIUAMFIUANUIUAFTIUAISIUAJRIUAKDLUBePLUAOOLUAGNLUAMMLUANLMUAOKMUAGJMUAMIMUANUMUAZJBZAIXJZAINEZAI|FBUAARBUABQBUACPBUADOBUAEDEUAFCEUAGBEUAHPEUAFOEUAINEUAJMEUAKYEUALHGMAFGGMAGFGMAMEGMANTGMAFSGMAIRGMAJQGMAKJIUAOIIUAGHIUAMGIUANVIUAFUIUAITIUAJSIUAKELUAODLUAPQLUAFPLUAGOLUAMNLUANMMUAOLMUAGKMUAMJMUANKCPAIYJPBtOFPAI|GBUAQFBUARSBUABRBUACQBUADPBUAEEEUAFDEUAICEUAMBEUASQEUAFPEUAIOEUAJNEUAKIGMAFHGMAIGGMAMFGMANUGMAFTGMAISGMAJRGMAKKIUAOJIUAGIIUAMHIUANWIUAFVIUAIUIUAJTIUAKFLUAOELUAGDLUATRLUAFQLUAIPLUAMOLUANNMUAOMMUAGLMUAMKMUANKCJAIYIJAIOFJAI|HBUAFGBUAUFBUAVTBUAWSBUACRBUADQBUAEFEUAFEEUAIDEUAJCEUANREUAFQEUAIPEUAJOEUAKJGMAFIGMAIHGMAJGGMANVGMAFUGMAITGMAJSGMAKLIUAFKIUAGJIUAMIIUANXIUAFWIUAIVIUAJUIUAKGLUAOFLUAGELUAMDLUAXSLUAFRLUAIQLUAJPLUANOMUAONMUAGMMUAMLMUANLCXAIZIXAlPFXAI|IBUAFHBUAIGBUAYFBUAZUBUAaTBUAbSBUADRBUAEGEUAFFEUAIEEUAJDEUAKSEUABREUAIQEUAJPEUAKKGMAFJGMAIIGMAJHGMAKWGMABVGMAIUGMAJTGMAKAIUAcMIUAFLIUAIKIUAMJIUANYIUAFXIUAIWIUAJVIUAKHLUAOGLUAGFLUAMELUANTLUAFSLUAIRLUAJQLUAKPMUAOOMUAGNMUAMMMUANLDZAIZIZAlPGZAI|JBUAFIBUAIHBUAJGBUAdUBUAeTBUAfSBUAEHEUAFGEUAIFEUAJEEUAKTEUABSEUACREUAJQEUAKLGMAFKGMAIJGMAJIGMAKXGMABWGMACVGMAJUGMAKBIUAOAIUAgNIUAFMIUAILIUAJKIUANZIUAhYIUAIXIUAJWIUAKILUAOHLUAGGLUAMFLUANULUAFTLUAISLUAJRLUAKQMUAOPMUAGOMUAMNMUANMCPAIQFPAI|KBUAFJBUAIIBUAJHBUAKUBUAiTBUAjIEUAFHEUAIGEUAJFEUAKUEUABTEUACSEUADREUAKAGMAhMGMAFLGMAIKGMAJJGMAKYGMABXGMACWGMADVGMAKCIUAOBIUAGAIUAkOIUAFNIUAIMIUAJLIUAKZIUAlYIUAJXIUAKJLUAOILUAGHLUAMGLUANVLUAFULUAITLUAJSLUAKFMUAmRMUAOQMUAGPMUAMOMUANMCJAIQFJAI|LBUAFKBUAIJBUAJIBUAKUBUA0JEUAFIEUAIHEUAJGEUAKVEUABUEUACTEUADSEUAEBGMAOAGMAlNGMAFMGMAILGMAJKGMAKZGMAsYGMACXGMADWGMAEDIUAOCIUAGBIUAMAIUBnPIUAFOIUAINIUAJMIUAKZIUA2YIUAKKLUAOJLUAGILUAMHLUANWLUBBVLUAIULUAJTLUAKGMUA4FMUBTSMUAFRMUAGQMUAMPMUANNCXAIRFXAI|MBUABLBUAIKBUAJJBUAKKEUAFJEUAIIEUAJHEUAKWEUABVEUACUEUADTEUAECGMAOBGMAGAGMA2OGMAFNGMAIMGMAJLGMAKZGMA3YGMADXGMAEEIUAODIUAGCIUAMBIUANQIUAFPIUAIOIUAJNIUAKZIUBqLLUAOKLUAGJLUAMILUANWLUBKVLUAJULUAKHMUAOGMUBLFMUATTMUAQSMUAIRMUAMQMUANNBZACREZAI|NBUABMBUACLBUAJKBUAKLEUAFKEUAIJEUAJIEUAKXEUABWEUACVEUADUEUAEDGMAOCGMAGBGMAMAGMA/PGMAFOGMAINGMAJMGMAKZGMBAYGMAEFIUAOEIUAGDIUAMCIUANRIUAFQIUAIPIUAJOIUAKMLUAOLLUAGKLUAMJLUANWLUAVVLUAKIMUAOHMUAGGMUBUFMUBcUMUAATMUAUSMUAJRMUANOBPACEJPAGSEPAC|OBUABNBUACMBUADLBUAKMEUAFLEUAIKEUAJJEUAKYEUBIXEUACWEUADVEUAEEGMAODGMAGCGMAMBGMANQGMAFPGMAIOGMAJNGMAKZGMBJGIUAOFIUAGEIUAMDIUANSIUAFRIUAIQIUAJPIUAKNLUAOMLUAGLLUAMKLUANWLUBNJMUAOIMUAGHMUAMGMUBZUMUARTMUAYSMUAKOBJACEKJAGSEJAC|PBUABOBUACNBUADMBUAEBEUBQNEUAFMEUAILEUAJKEUAKYEUBRXEUADWEUAEFGMAOEGMAGDGMAMCGMANRGMAFQGMAIPGMAJOGMAKHIUAOGIUAGFIUAMEIUANTIUAFSIUAIRIUAJQIUAKOLUAONLUAGMLUAMLLUANKMUAOJMUAGIMUAMHMUANUMUAVTMUAdPBXACFJXAGTEXAC|QBUABPBUACOBUADNBUAECEUAOBEUBWOEUAFNEUAIMEUAJLEUAKYEUBXXEUAEGGMAOFGMAGEGMAMDGMANSGMAFRGMAIQGMAJPGMAKIIUAOHIUAGGIUAMFIUANUIUAFTIUAISIUAJRIUAKDLUBePLUAOOLUAGNLUAMMLUANLMUAOKMUAGJMUAMIMUANUMUAZPBZACFJZAGTEZAC|FBUAARBUABQBUACPBUADOBUAEDEUAFCEUAGBEUAHPEUAFOEUAINEUAJMEUAKYEUALHGMAFGGMAGFGMAMEGMANTGMAFSGMAIRGMAJQGMAKJIUAOIIUAGHIUAMGIUANVIUAFUIUAITIUAJSIUAKELUAODLUAPQLUAFPLUAGOLUAMNLUANMMUAOLMUAGKMUAMJMUANQCPACGJPAGUFPAC|GBUAQFBUARSBUABRBUACQBUADPBUAEEEUAFDEUAICEUAMBEUASQEUAFPEUAIOEUAJNEUAKIGMAFHGMAIGGMAMFGMANUGMAFTGMAISGMAJRGMAKKIUAOJIUAGIIUAMHIUANWIUAFVIUAIUIUAJTIUAKFLUAOELUAGDLUATRLUAFQLUAIPLUAMOLUANNMUAOMMUAGLMUAMKMUANQCJACGIJAGUFJAC|HBUAFGBUAUFBUAVTBUAWSBUACRBUADQBUAEFEUAFEEUAIDEUAJCEUANREUAFQEUAIPEUAJOEUAKJGMAFIGMAIHGMAJGGMANVGMAFUGMAITGMAJSGMAKLIUAFKIUAGJIUAMIIUANXIUAFWIUAIVIUAJUIUAKGLUAOFLUAGELUAMDLUAXSLUAFRLUAIQLUAJPLUANOMUAONMUAGMMUAMLMUANRCXACHIXAGVFXAC|IBUAFHBUAIGBUAYFBUAZUBUAaTBUAbSBUADRBUAEGEUAFFEUAIEEUAJDEUAKSEUABREUAIQEUAJPEUAKKGMAFJGMAIIGMAJHGMAKWGMABVGMAIUGMAJTGMAKAIUAcMIUAFLIUAIKIUAMJIUANYIUAFXIUAIWIUAJVIUAKHLUAOGLUAGFLUAMELUANTLUAFSLUAIRLUAJQLUAKPMUAOOMUAGNMUAMMMUANRDZACHIZAGVGZAI|JBUAFIBUAIHBUAJGBUAdUBUAeTBUAfSBUAEHEUAFGEUAIFEUAJEEUAKTEUABSEUACREUAJQEUAKLGMAFKGMAIJGMAJIGMAKXGMABWGMACVGMAJUGMAKBIUAOAIUAgNIUAFMIUAILIUAJKIUANZIUAhYIUAIXIUAJWIUAKILUAOHLUAGGLUAMFLUANULUAFTLUAISLUAJRLUAKQMUAOPMUAGOMUAMNMUANSCPACIIPAGWFPAC|KBUAFJBUAIIBUAJHBUAKUBUAiTBUAjIEUAFHEUAIGEUAJFEUAKUEUABTEUACSEUADREUAKAGMAhMGMAFLGMAIKGMAJJGMAKYGMABXGMACWGMADVGMAKCIUAOBIUAGAIUAkOIUAFNIUAIMIUAJLIUAKZIUAlYIUAJXIUAKJLUAOILUAGHLUAMGLUANVLUAFULUAITLUAJSLUAKFMUAmRMUAOQMUAGPMUAMOMUANSCJACIIJAGWFJAC|LBUAFKBUAIJBUAJIBUAKUBUA0JEUAFIEUAIHEUAJGEUAKVEUABUEUACTEUADSEUAEBGMAOAGMAlNGMAFMGMAILGMAJKGMAKZGMAsYGMACXGMADWGMAEDIUAOCIUAGBIUAMAIUBnPIUAFOIUAINIUAJMIUAKZIUA2YIUAKKLUAOJLUAGILUAMHLUANWLUBBVLUAIULUAJTLUAKGMUA4FMUBTSMUAFRMUAGQMUAMPMUANTCXACJJXAGXFXAC|MBUABLBUAIKBUAJJBUAKKEUAFJEUAIIEUAJHEUAKWEUABVEUACUEUADTEUAECGMAOBGMAGAGMA2OGMAFNGMAIMGMAJLGMAKZGMA3YGMADXGMAEEIUAODIUAGCIUAMBIUANQIUAFPIUAIOIUAJNIUAKZIUBqLLUAOKLUAGJLUAMILUANWLUBKVLUAJULUAKHMUAOGMUBLFMUATTMUAQSMUAIRMUAMQMUANTBZAbJJZAGXEZAC|NBUABMBUACLBUAJKBUAKLEUAFKEUAIJEUAJIEUAKXEUABWEUACVEUADUEUAEDGMAOCGMAGBGMAMAGMA/PGMAFOGMAINGMAJMGMAKZGMBAYGMAEFIUAOEIUAGDIUAMCIUANRIUAFQIUAIPIUAJOIUAKMLUAOLLUAGKLUAMJLUANWLUAVVLUAKIMUAOHMUAGGMUBUFMUBcUMUAATMUAUSMUAJRMUANUBPAeKJPAGYEPBR|OBUABNBUACMBUADLBUAKMEUAFLEUAIKEUAJJEUAKYEUBIXEUACWEUADVEUAEEGMAODGMAGCGMAMBGMANQGMAFPGMAIOGMAJNGMAKZGMBJGIUAOFIUAGEIUAMDIUANSIUAFRIUAIQIUAJPIUAKNLUAOMLUAGLLUAMKLUANWLUBNJMUAOIMUAGHMUAMGMUBZUMUARTMUAYSMUAKUBJAeKKJAGYEJBR|PBUABOBUACNBUADMBUAEBEUBQNEUAFMEUAILEUAJKEUAKYEUBRXEUADWEUAEFGMAOEGMAGDGMAMCGMANRGMAFQGMAIPGMAJOGMAKHIUAOGIUAGFIUAMEIUANTIUAFSIUAIRIUAJQIUAKOLUAONLUAGMLUAMLLUANKMUAOJMUAGIMUAMHMUANUMUAVTMUAdLJXAG|QBUABPBUACOBUADNBUAECEUAOBEUBWOEUAFNEUAIMEUAJLEUAKYEUBXXEUAEGGMAOFGMAGEGMAMDGMANSGMAFRGMAIQGMAJPGMAKIIUAOHIUAGGIUAMFIUANUIUAFTIUAISIUAJRIUAKDLUBePLUAOOLUAGNLUAMMLUANLMUAOKMUAGJMUAMIMUANUMUAZLJZAG'
VN_AL[air]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[air]='505458b8c0c498acb4708c9848606c8c949854606430384074848c586c74384850344850404c5428343c686c7030383c848c90444c501c282c242c306c7c84344044b0b8bc181c2454646c20282c6c707490a4ac34343834444c58646868849028303044484c405058445c642024283840443c404094a4ac68808c384c585c68702430347c8484707478545858343c401c2024a8b0b46c889440586428384044545c2c3438687478606468283034101418949ca08c9ca4445c682c38401820284c606854585c64686c4c585c343c44182024787c807c8c908c9494304048445054505c6038444c20283064707458707c505054748488404c503038383c4850485c6440484c546c74303c40243038303c442c3c44141c204444483c40442c30305c606434383c94989c24282c4c545c7888905c606014181c5870784c54581c2428242c34384c5458646c'
VN_AF[snow]='AHGAACEbABCKHACEDaADEJGABGGHABGMbAEIDGADIJGABKAbAFKGHADKMHABMFGADMLGABOCHAGOIbADQFGADQLGADSCHAGSIHADUBGAHUHGADWGHAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHaAACEHABCKHACEDGADEJGABGGHABGMHAEIDaADIJGABKAHAFKGHADKMbABMFGADMLaABOCHAGOIHADQFGADQLGADSCHAGSIbADUBGAHUHaADWGbAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BIGABCFHABFEGADFKGABGBHAQGHbABJEGADJKGABKBHADKHHADKNHACNAGARNGGADNMGABODbADOJHADRAGACRGGADRMaABSDHAGSJHADVCGAGVIGADWHHADZIaAAINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BIGABCFHABFEGADFKaABGBHAQGHHABJEGADJKGABKBHADKHbADKNHACNAGARNGaADNMGABODHADOJHADRAGACRGGADRMGABSDbAGSJHADVCaAGVIGADWHHADZIGAAINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BJGASCGHABFFGADFLGABGCbADGIHABJFGADJLaABKCHADKIHABNBGAGNHGADNNGAKOEHADOKHADRBGAGRHaADRNGAISEHAGSKHADVDGAGVJGADWCHATWIHADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BJGASCGbABFFaADFLGABGCHADGIHABJFGADJLGABKCbADKIHABNBaAGNHGADNNGAKOEHADOKbADRBGAGRHGADRNGAISEHAGSKHADVDGAGVJGADWCHATWIHADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BEGASCHHABFGGABFMGAUGDHADGJHABJAGAOJGaADJMGABKDHADKJHABNCGADNIGADOFHADOLHABRCaAGRIGADSFHADSLbADVEGAGVKaADWDHAGWJbADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BEGASCHHABFGGABFMGAUGDHADGJbABJAGAOJGGADJMGABKDHADKJHABNCGADNIGADOFbADOLHABRCGAGRIGADSFHADSLHADVEGAGVKGADWDHAGWJHADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BFaABCIHABFBGAVFHGABGEHADGKHABJBaADJHGADJNGAJKEHADKKbABNDGADNJaADOAHAWOGHADOMHABRDGAGRJGADSGbADSMHADVFaAGVLGADWEbAGWKHADZFGAOINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BFGABCIHABFBGAVFHGABGEbADGKHABJBGADJHGADJNaAJKEHADKKHABNDGADNJGADOAbAWOGHADOMHABRDGAGRJaADSGHADSMHADVFGAGVLGADWEHAGWKHADZFaAOINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BGGABCDHANCJbABFCGADFIaABGFHADGLHABJCGADJIGABKFbADKLHABNEaADNKGABOBHAGOHHADONbAEREGADRKGADSBbAGSHHADVGGADWFHAGWLHAVZGGAXINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AGGAACDHANCJHABECGADEIGABGFHADGLHABICGADIIaABKFHADKLHABMEGADMKGABOBHAGOHHADONHAEQEaADQKGADSBHAGSHHADUGGADUMaAVWFHAGWLbAVYGGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHGAACEbABCKHACEDaADEJGABGGHABGMbAEIDGADIJGABKAbAFKGHADKMHABMFGADMLGABOCHAGOIbADQFGADQLGADSCHAGSIHADUBGAHUHGADWGHAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHaAACEHABCKHACEDGADEJGABGGHABGMHAEIDaADIJGABKAHAFKGHADKMbABMFGADMLaABOCHAGOIHADQFGADQLGADSCHAGSIbADUBGAHUHaADWGbAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AIGAYDFHABDLHAPEEGADEKGABHBHADHHbABIEGADIKGABLBHADLHHADLNHAEMAGARMGGADMMGABPDbADPJHADQAGAZQGGADQMaABTDHAGTJHADUCGAGUIGADXHHADYIaADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AIGAYDFHABDLbAPEEGADEKaABHBHADHHHABIEGADIKGABLBHADLHbADLNHAEMAGARMGaADMMGABPDHADPJHADQAGAZQGGADQMGABTDbAGTJHADUCaAGUIGADXHHADYIGADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DGHABEFGABELGABHCbADHIHABIFGADILaABLCHADLIHADMBGAGMHGADMNGAKPEHADPKHADQBGAGQHaADQNGAJTEHAGTKHADUDGAGUJGADXIHADYJGATINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DGbABEFaABELGABHCHADHIHABIFGADILGABLCbADLIHADMBaAGMHGADMNGAKPEHADPKbADQBGAGQHGADQNGAJTEHAGTKHADUDGAGUJGADXIHADYJGATINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DHHABEGGABHDHADHJHABIAGAPIGaADIMGABLDHADLJHABMCGADMIGADPFHADPLHABQCaAGQIGADTFHADTLbADUEGAGUKaADXDHAaXJbADYEGALINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DHHABEGGABHDHADHJbABIAGAPIGGADIMGABLDHADLJHABMCGADMIGADPFbADPLHABQCGAGQIGADTFHADTLHADUEGAGUKGADXDHAaXJHADYEGALINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AFaAYDCHAVDIHABEHGABHEHADHKHABIBaADIHGABINGAILEHADLKbABMDGADMJaABPAHAFPGHADPMHABQDGAGQJGADTGbADTMHAQUFaAGULGADXEbAGXKHANYFGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AFGAYDCHAVDIHABEHGABHEbADHKHABIBGADIHGABINaAILEHADLKHABMDGADMJGABPAbAFPGHADPMHABQDGAGQJaADTGHADTMHAQUFGAGULGADXEHAGXKHANYFaAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AGGAADDHADDJbABECGADEIaABHFHADHLHABICGADIIGABLFbADLLHABMEaADMKGABPBHAGPHHADPNbACQEGADQKGADTBbARTHHADUGGADUMGAVXFHAGYGGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AGGAACDHANCJHABECGADEIGABGFHADGLHABICGADIIaABKFHADKLHABMEGADMKGABOBHAGOHHADONHAEQEaADQKGADSBHAGSHHADUGGADUMaAVWFHAGWLbAVYGGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHGAACEbABCKHACEDaADEJGABGGHABGMbAEIDGADIJGABKAbAFKGHADKMHABMFGADMLGABOCHAGOIbADQFGADQLGADSCHAGSIHADUBGAHUHGADWGHAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHaAACEHABCKHACEDGADEJGABGGHABGMHAEIDaADIJGABKAHAFKGHADKMbABMFGADMLaABOCHAGOIHADQFGADQLGADSCHAGSIbADUBGAHUHaADWGbAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BIGABCFHABFEGADFKGABGBHAQGHbABJEGADJKGABKBHADKHHADKNHACNAGARNGGADNMGABODbADOJHADRAGACRGGADRMaABSDHAGSJHADVCGAGVIGADWHHADZIaAAINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BIGABCFHABFEGADFKaABGBHAQGHHABJEGADJKGABKBHADKHbADKNHACNAGARNGaADNMGABODHADOJHADRAGACRGGADRMGABSDbAGSJHADVCaAGVIGADWHHADZIGAAINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BJGASCGHABFFGADFLGABGCbADGIHABJFGADJLaABKCHADKIHABNBGAGNHGADNNGAKOEHADOKHADRBGAGRHaADRNGAISEHAGSKHADVDGAGVJGADWCHATWIHADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BJGASCGbABFFaADFLGABGCHADGIHABJFGADJLGABKCbADKIHABNBaAGNHGADNNGAKOEHADOKbADRBGAGRHGADRNGAISEHAGSKHADVDGAGVJGADWCHATWIHADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BEGASCHHABFGGABFMGAUGDHADGJHABJAGAOJGaADJMGABKDHADKJHABNCGADNIGADOFHADOLHABRCaAGRIGADSFHADSLbADVEGAGVKaADWDHAGWJbADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BEGASCHHABFGGABFMGAUGDHADGJbABJAGAOJGGADJMGABKDHADKJHABNCGADNIGADOFbADOLHABRCGAGRIGADSFHADSLHADVEGAGVKGADWDHAGWJHADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BFaABCIHABFBGAVFHGABGEHADGKHABJBaADJHGADJNGAJKEHADKKbABNDGADNJaADOAHAWOGHADOMHABRDGAGRJGADSGbADSMHADVFaAGVLGADWEbAGWKHADZFGAOINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BFGABCIHABFBGAVFHGABGEbADGKHABJBGADJHGADJNaAJKEHADKKHABNDGADNJGADOAbAWOGHADOMHABRDGAGRJaADSGHADSMHADVFGAGVLGADWEHAGWKHADZFaAOINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|BGGABCDHANCJbABFCGADFIaABGFHADGLHABJCGADJIGABKFbADKLHABNEaADNKGABOBHAGOHHADONbAEREGADRKGADSBbAGSHHADVGGADWFHAGWLHAVZGGAXINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AGGAACDHANCJHABECGADEIGABGFHADGLHABICGADIIaABKFHADKLHABMEGADMKGABOBHAGOHHADONHAEQEaADQKGADSBHAGSHHADUGGADUMaAVWFHAGWLbAVYGGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHGAACEbABCKHACEDaADEJGABGGHABGMbAEIDGADIJGABKAbAFKGHADKMHABMFGADMLGABOCHAGOIbADQFGADQLGADSCHAGSIHADUBGAHUHGADWGHAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AHaAACEHABCKHACEDGADEJGABGGHABGMHAEIDaADIJGABKAHAFKGHADKMbABMFGADMLaABOCHAGOIHADQFGADQLGADSCHAGSIbADUBGAHUHaADWGbAGYHGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AIGAYDFHABDLHAPEEGADEKGABHBHADHHbABIEGADIKGABLBHADLHHADLNHAEMAGARMGGADMMGABPDbADPJHADQAGAZQGGADQMaABTDHAGTJHADUCGAGUIGADXHHADYIaADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AIGAYDFHABDLbAPEEGADEKaABHBHADHHHABIEGADIKGABLBHADLHbADLNHAEMAGARMGaADMMGABPDHADPJHADQAGAZQGGADQMGABTDbAGTJHADUCaAGUIGADXHHADYIGADINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DGHABEFGABELGABHCbADHIHABIFGADILaABLCHADLIHADMBGAGMHGADMNGAKPEHADPKHADQBGAGQHaADQNGAJTEHAGTKHADUDGAGUJGADXIHADYJGATINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DGbABEFaABELGABHCHADHIHABIFGADILGABLCbADLIHADMBaAGMHGADMNGAKPEHADPKbADQBGAGQHGADQNGAJTEHAGTKHADUDGAGUJGADXIHADYJGATINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DHHABEGGABHDHADHJHABIAGAPIGaADIMGABLDHADLJHABMCGADMIGADPFHADPLHABQCaAGQIGADTFHADTLbADUEGAGUKaADXDHAaXJbADYEGALINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|DHHABEGGABHDHADHJbABIAGAPIGGADIMGABLDHADLJHABMCGADMIGADPFbADPLHABQCGAGQIGADTFHADTLHADUEGAGUKGADXDHAaXJHADYEGALINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AFaAYDCHAVDIHABEHGABHEHADHKHABIBaADIHGABINGAILEHADLKbABMDGADMJaABPAHAFPGHADPMHABQDGAGQJGADTGbADTMHAQUFaAGULGADXEbAGXKHANYFGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AFGAYDCHAVDIHABEHGABHEbADHKHABIBGADIHGABINaAILEHADLKHABMDGADMJGABPAbAFPGHADPMHABQDGAGQJaADTGHADTMHAQUFGAGULGADXEHAGXKHANYFaAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AGGAADDHADDJbABECGADEIaABHFHADHLHABICGADIIGABLFbADLLHABMEaADMKGABPBHAGPHHADPNbACQEGADQKGADTBbARTHHADUGGADUMGAVXFHAGYGGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP|AGGAACDHANCJHABECGADEIGABGFHADGLHABICGADIIaABKFHADKLHABMEGADMKGABOBHAGOHHADONHAEQEaADQKGADSBHAGSHHADUGGADUMaAVWFHAGWLbAVYGGAGINcAIJNMAJKNEACLNcAEMNMAKNNcALONEAMPNMANQNcAORNMAP'
VN_AL[snow]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[snow]='4c4c4c7070705858589c9c9c686868a4a4a4c8c8c87474743030304848486c6c6c9898989090907c7c7c646464444444949494c0c0c05454547878784040405c5c5cb8b8b8888888383838848484a0a0a0'
VN_AF[storm]='CDQAADCQABGBSACHBQADHCQADIAeAEIBQADICQADJAeAFJBQAGKAeAHLAeAIMAeAJMBSAKNAeAJNBQALNCQADOAeAMOBQALOCQALPAeANPBQAKQAeAORAeAPSBSAKTBQAQTCQALUBQAAUCQALBJKAREIKASHHKASKGKATNFKATNNKAUQEKATQMKASTDKAVTLKATWKKAT|CDQAAGBQACHBQADHCQADIAeAEIBQADICQADJAeACKAeAHLAeAIMAeAJMBQAKNAeAJNBQALNCQADOAeAMOBQALOCQALPAeAHQAeAORAeAPSBQAKTBQAQTCQALUBQAAUCQALEJKASHIKASKHKATNGKATQFKATQNKAWTEKAVTMKAXWDKAVWLKAG|GBQAYHBQADHCQADIAeAEIBQADJAeACKAeAHLAeAIMAeAJMBQALNAeAQNBQALNCQADOAeAMOBQALPAeAHQAeAORAeAPSBQALTBQAQTCQALUBQAAEKKASHJKASKIKASNHKATQGKATTFKATWEKAV|GBQAYGCQADHBQADHCQADIAeAEIBQAGJAeACKAeAHLAeAIMAeAJMBQALMCQADNAeAJNBQALNCQADOAeAMOBQAKPAeAHQAeAORAeAPSBQALSCQALTBQAQTCQALUBQAZBEKAREDKATELKASHKKASKJKASNIKATQHKATTGKATWFKAV|FBSAaGBQAYGCQADHBQADHCQADIAeAEIBQAGJAeACKAeAHLAeAMLBSAGMAeAJMBQALMCQADNAeAJNBQALNCQADOAeAMOBQAKPAeAHQAeAORAeAbRBSAKSBQALSCQALTBQAQTCQALUBQAZBFKASEEKATHDKATHLKASKKKASNJKATQIKATTHKATWGKAVZFKAc|FBQAaGBQAYGCQADHBQADHCQADIAeAFJAeACKAeAHLAeAMLBQAGMAeAJMBQALMCQADNAeAJNBQALNCQADOAeAIPAeAHQAeAORAeAbRBQAKSBQALSCQALTBQAQTCQALBGKASEFKASHEKATHMKASKDKATKLKASNKKASQJKATTIKATWHKATZGKAH|FBQABGBQAYGCQADHBQADIAeAFJAeACKAeAHLAeAMLBQADMAeAQMBQALMCQADNAeAJNBQALOAeAIPAeAHQAeAORAeAbRBQALSBQALSCQALTBQAQBHKASEGKASHFKATKEKATKMKASNDKATNLKASQKKATTJKATWIKATZHKAH|FBQABFCQADGBQAYGCQADHBQAGIAeAFJAeACKAeAHLAeAMLBQADLCQADMAeAJMBQALMCQADNAeAJNBQAKOAeAIPAeAHQAeAORAeAbRBQALRCQALSBQALSCQALTBQAJXDQADBIKASEHKASHGKATKFKATKNKAdNEKATNMKASQDKAVQLKATTKKATWJKATZIKAe|ECSADFBQABFCQADGBQAYGCQADHBQAGIAeAFJAeACKAeANKBSAGLAeAMLBQADLCQADMAeAJMBQALMCQADNAeAJNBQAKOAeAIPAeAHQAeAfQBSAKRAeAbRBQALRCQALSBQALSCQALTBQAJWCSAAXDQADBJKAREIKASHHKASKGKATNFKATNNKAUQEKATQMKASTDKAVTLKATWKKAT|ECQADFBQABFCQADGBQAYGCQADIAeAFJAeACKAeANKBQAGLAeAMLBQADLCQADMAeAJMBQALMCQADNAeAgOAeAIPAeAHQAeAfQBQAKRAeAbRBQALRCQALSBQALSCQALWCQAAXDQADEJKASHIKASKHKATNGKATQFKATQNKAWTEKAVTMKAXWDKAVWLKAG|ECQADFBQABFCQADGBQAYIAeAFJAeACKAeANKBQADLAeAQLBQADLCQADMAeAJMBQALNAeAgOAeAIPAeAHQAeAfQBQALRAeABRBQALRCQALSBQALWCQAAXDQADEKKASHJKASKIKASNHKATQGKATTFKATWEKAV|ECQADEDQADFBQABFCQADGBQACIAeAFJAeACKAeANKBQADKCQADLAeAMLBQADLCQADMAeAJMBQAKNAeAgOAeAIPAeAHQAeAfQBQALQCQALRAeAbRBQALRCQALSBQAKWCQAAWDQALXDQADBEKAREDKATELKASHKKASKJKASNIKATQHKATTGKATWFKAV|DCSABECQADEDQADFBQABFCQADGBQACIAeAFJAeAFJBSAGKAeANKBQADKCQADLAeAMLBQADLCQADMAeAJMBQAKNAeAgOAeAIPAeANPBSAKQAeAfQBQALQCQALRAeAbRBQALRCQALSBQAKWCQAAWDQALXDQADBFKASEEKATHDKATHLKASKKKASNJKATQIKATTHKATWGKAVZFKAc|DCQABECQADEDQADFBQABFCQADIAeAFJAeAFJBQAGKAeANKBQADKCQADLAeAMLBQADLCQADMAeAgNAeAgOAeAIPAeANPBQAKQAeAfQBQALQCQALRAeAbRBQALRCQALWCQAAWDQALXDQADBGKASEFKASHEKATHMKASKDKATKLKASNKKASQJKATTIKATWHKATZGKAH|DCQABECQADEDQADFBQABIAeAFJAeAFJBQADKAeADKBQADKCQADLAeAMLBQADMAeAgNAeAgOAeAIPAeANPBQALQAeAhQBQALQCQALRAeAbRBQALWCQAAWDQALBHKASEGKASHFKATKEKATKMKASNDKATNLKASQKKATTJKATWIKATZHKAH|DCQABDDQADECQADEDQADFBQAaIAeAFJAeAFJBQADJCQADKAeANKBQADKCQADLAeAMLBQAGMAeAgNAeAgOAeAIPAeANPBQALPCQALQAeAfQBQALQCQALRAeAbRBQAKVCQALWCQAAWDQALBIKASEHKASHGKATKFKATKNKAdNEKATNMKASQDKAVQLKATTKKATWJKATZIKAe|DCQABDDQADECQADEDQADFBQAaIAeAEIBSAGJAeAFJBQADJCQADKAeANKBQADKCQADLAeAMLBQAGMAeAgNAeAgOAeAMOBSAKPAeANPBQALPCQALQAeAfQBQALQCQALRAeAbRBQAKUBSAZVCQALWCQAAWDQALBJKAREIKASHHKASKGKATNFKATNNKAUQEKATQMKASTDKAVTLKATWKKAT|DCQABDDQADECQADEDQADIAeAEIBQAGJAeAFJBQADJCQADKAeANKBQADKCQADLAeAIMAeAgNAeAgOAeAMOBQAKPAeANPBQALPCQALQAeAfQBQALQCQALRAeAPUBQAZVCQALWCQAAWDQALEJKASHIKASKHKATNGKATQFKATQNKAWTEKAVTMKAXWDKAVWLKAG|DCQABDDQADECQADIAeAEIBQADJAeAiJBQADJCQADKAeANKBQADLAeAIMAeAgNAeAgOAeAMOBQALPAeADPBQALPCQALQAeAfQBQALRAeAPUBQAAVCQALWCQAAEKKASHJKASKIKASNHKATQGKATTFKATWEKAV|CDQAADCQABDDQADECQADIAeAEIBQADICQADJAeAFJBQADJCQADKAeANKBQAGLAeAIMAeAgNAeAgOAeAMOBQALOCQALPAeANPBQALPCQALQAeAfQBQAKRAeAPUBQAAUCQALVCQALWCQAABEKAREDKATELKASHKKASKJKASNIKATQHKATTGKATWFKAV|CDQAADCQABDDQADECQADHBSAGIAeAEIBQADICQADJAeAFJBQADJCQADKAeANKBQAGLAeAIMAeAgNAeAJNBSAKOAeAMOBQALOCQALPAeANPBQALPCQALQAeAfQBQAKRAeAPTBSAJUBQAAUCQALVCQALWCQAABFKASEEKATHDKATHLKASKKKASNJKATQIKATTHKATWGKAVZFKAc|CDQAADCQABDDQADHBQAGIAeAEIBQADICQADJAeAFJBQADJCQADKAeAHLAeAIMAeAgNAeAJNBQAKOAeAMOBQALOCQALPAeANPBQALPCQALQAeAORAeAPTBQAJUBQAAUCQALVCQALBGKASEFKASHEKATHMKASKDKATKLKASNKKASQJKATTIKATWHKATZGKAH|CDQAADCQABHBQADIAeAjIBQADICQADJAeAFJBQADKAeAHLAeAIMAeAgNAeAJNBQALOAeAQOBQALOCQALPAeANPBQALQAeAORAeAPTBQAQUBQAAUCQALBHKASEGKASHFKATKEKATKMKASNDKATNLKASQKKATTJKATWIKATZHKAH|CDQAADCQABHBQADHCQADIAeAEIBQADICQADJAeAFJBQAGKAeAHLAeAIMAeAgNAeAJNBQALNCQADOAeAMOBQALOCQALPAeANPBQAKQAeAORAeAPTBQAQTCQALUBQAAUCQALBIKASEHKASHGKATKFKATKNKAdNEKATNMKASQDKAVQLKATTKKATWJKATZIKAe|CDQAADCQABGBSACHBQADHCQADIAeAEIBQADICQADJAeAFJBQAGKAeAHLAeAIMAeAJMBSAKNAeAJNBQALNCQADOAeAMOBQALOCQALPAeANPBQAKQAeAORAeAPSBSAKTBQAQTCQALUBQAAUCQALBJKAREIKASHHKASKGKATNFKATNNKAUQEKATQMKASTDKAVTLKATWKKAT|CDQAAGBQACHBQADHCQADIAeAEIBQADICQADJAeACKAeAHLAeAIMAeAJMBQAKNAeAJNBQALNCQADOAeAMOBQALOCQALPAeAHQAeAORAeAPSBQAKTBQAQTCQALUBQAAUCQALEJKASHIKASKHKATNGKATQFKATQNKAWTEKAVTMKAXWDKAVWLKAG|GBQAYHBQADHCQADIAeAEIBQADJAeACKAeAHLAeAIMAeAJMBQALNAeAQNBQALNCQADOAeAMOBQALPAeAHQAeAORAeAPSBQALTBQAQTCQALUBQAAEKKASHJKASKIKASNHKATQGKATTFKATWEKAV|GBQAYGCQADHBQADHCQADIAeAEIBQAGJAeACKAeAHLAeAIMAeAJMBQALMCQADNAeAJNBQALNCQADOAeAMOBQAKPAeAHQAeAORAeAPSBQALSCQALTBQAQTCQALUBQAZBEKAREDKATELKASHKKASKJKASNIKATQHKATTGKATWFKAV|FBSAaGBQAYGCQADHBQADHCQADIAeAEIBQAGJAeACKAeAHLAeAMLBSAGMAeAJMBQALMCQADNAeAJNBQALNCQADOAeAMOBQAKPAeAHQAeAORAeAbRBSAKSBQALSCQALTBQAQTCQALUBQAZBFKASEEKATHDKATHLKASKKKASNJKATQIKATTHKATWGKAVZFKAc|FBQAaGBQAYGCQADHBQADHCQADIAeAFJAeACKAeAHLAeAMLBQAGMAeAJMBQALMCQADNAeAJNBQALNCQADOAeAIPAeAHQAeAORAeAbRBQAKSBQALSCQALTBQAQTCQALBGKASEFKASHEKATHMKASKDKATKLKASNKKASQJKATTIKATWHKATZGKAH|FBQABGBQAYGCQADHBQADIAeAFJAeACKAeAHLAeAMLBQADMAeAQMBQALMCQADNAeAJNBQALOAeAIPAeAHQAeAORAeAbRBQALSBQALSCQALTBQAQBHKASEGKASHFKATKEKATKMKASNDKATNLKASQKKATTJKATWIKATZHKAH|FBQABFCQADGBQAYGCQADHBQAGIAeAFJAeACKAeAHLAeAMLBQADLCQADMAeAJMBQALMCQADNAeAJNBQAKOAeAIPAeAHQAeAORAeAbRBQALRCQALSBQALSCQALTBQAJXDQADBIKASEHKASHGKATKFKATKNKAdNEKATNMKASQDKAVQLKATTKKATWJKATZIKAe|ECSADFBQABFCQADGBQAfGCQAkHBQAlIAeAmJAeAnKAeAoKBSApLAeAqLBQArLCQAsMAeAtMBQAuMCQAvNAeAwNBQAxOAeAyPAeAzQAeA0QBSA1RAeA2RBQA3RCQA4SBQA5SCQA6TBQA7WCSAPXDQADBJKAREIKASHHKA8KGKA9NFKA+NNKAUQEKAvQMKASTDKA/TLKATWKKATOChBAODjBANEhBA|ECQADFBQABFCQADGBQAfGCQAkIAeAmJAeAnKAeAoKBQApLAeAqLBQArLCQA+MAeAtMBQAuMCQAvNAeBCOAeAyPAeAzQAeA0QBQA1RAeA2RBQA3RCQBDSBQA5SCQBEWCQAPXDQADEJKASHIKBFKHKBGNGKBHQFKBIQNKAWTEKA/TMKAXWDKBJWLKAGOChBAODjBANEhBANFjBAMGhBA|ECQADFBQABFCQADGBQAfIAeAmJAeAnKAeAoKBQBKLAeBLLBQArLCQA+MAeAtMBQAuNAeBCOAeAyPAeAzQAeA0QBQA/RAeBMRBQA3RCQBDSBQA5WCQAPXDQADEKKBNHJKBOKIKBPNHKBQQGKBRTFKBSWEKBTOChBAODjBANEhBANFjBAMGhBAMHjBALIhBA|ECQADEDQADFBQABFCQADGBQAUIAeAmJAeAnKAeAoKBQBKKCQAuLAeAqLBQArLCQA+MAeAtMBQBUNAeBCOAeAyPAeAzQAeA0QBQA/QCQBVRAeA2RBQA3RCQBDSBQBWWCQAPWDQBXXDQADBEKAREDKATELKBFHKKBYKJKBZNIKBaQHKBbTGKBcWFKAVOChBAODjBANEhBANFjBAMGhBAMHjBALIhBALJjBdKKhBe|DCSABECQADEDQADFBQABFCQADGBQAUIAeAmJAeBfJBSBgKAeAoKBQBKKCQAuLAeAqLBQArLCQA+MAeAtMBQBUNAeBCOAeAyPAeBhPBSAxQAeA0QBQA/QCQBVRAeA2RBQA3RCQBDSBQBWWCQAPWDQBXXDQADBFKASEEKATHDKAwHLKBYKKKBiNJKBjQIKBkTHKBlWGKAVZFKAcOChBAODjBANEhBANFjBAMGhBAMHjBALIhBALJjBmKKhBnKLjBoJMhBp|DCQABECQADEDQADFBQABFCQADIAeAmJAeBfJBQBgKAeAoKBQBKKCQAuLAeAqLBQArLCQA+MAeBqNAeBCOAeAyPAeBhPBQAxQAeA0QBQA/QCQBVRAeA2RBQA3RCQBDWCQAPWDQBXXDQADBGKASEFKASHEKAwHMKBYKDKA+KLKBiNKKBrQJKBsTIKBsWHKATZGKAHOChBAODjBANEhBANFjBAMGhBAMHjBALIhBALJjBtKKhBmKLjBnJMhBuJNjBv|DCQABECQADEDQADFBQABIAeAmJAeBfJBQBwKAeBxKBQBKKCQAuLAeAqLBQArMAeBqNAeBCOAeAyPAeBhPBQByQAeBzQBQA/QCQBVRAeA2RBQA3WCQAPWDQBXBHKASEGKASHFKBaKEKB0KMKB1NDKB2NLKB3QKKATTJKATWIKATZHKAHOChBAODjBANEhBANFjBAMGhBAMHjBALIhBALJjBtKKhBmKLjBnJMhBuJNjBv|DCQABDDQADECQADEDQADFBQAaIAeAmJAeBfJBQBwJCQB4KAeAoKBQBKKCQAuLAeAqLBQB5MAeBqNAeBCOAeAyPAeBhPBQByPCQB6QAeA0QBQA/QCQBVRAeA2RBQB7VCQB8WCQAPWDQBXBIKASEHKASHGKB9KFKAxKNKB+NEKB2NMKBOQDKB6QLKB/TKKATWJKATZIKAeOChBAODjBANEhBANFjBAMGhBAMHjBALIhBALJjBtKKhBmKLjBnJMhBuJNjBv|DCQABDDQADECQADEDQADFBQAaIAeAEIBSAGJAeAFJBQADJCQADKAeANKBQADKCQADLAeAMLBQAGMAeAgNAeAgOAeAMOBSAKPAeANPBQALPCQALQAeAfQBQALQCQALRAeAbRBQAKUBSAZVCQALWCQAAWDQALBJKAREIKASHHKASKGKATNFKATNNKAUQEKATQMKASTDKAVTLKATWKKAT|DCQABDDQADECQADEDQADIAeAEIBQAGJAeAFJBQADJCQADKAeANKBQADKCQADLAeAIMAeAgNAeAgOAeAMOBQAKPAeANPBQALPCQALQAeAfQBQALQCQALRAeAPUBQAZVCQALWCQAAWDQALEJKASHIKASKHKATNGKATQFKATQNKAWTEKAVTMKAXWDKAVWLKAG|DCQABDDQADECQADIAeAEIBQADJAeAiJBQADJCQADKAeANKBQADLAeAIMAeAgNAeAgOAeAMOBQALPAeADPBQALPCQALQAeAfQBQALRAeAPUBQAAVCQALWCQAAEKKASHJKASKIKASNHKATQGKATTFKATWEKAV|CDQAADCQABDDQADECQADIAeAEIBQADICQADJAeAFJBQADJCQADKAeANKBQAGLAeAIMAeAgNAeAgOAeAMOBQALOCQALPAeANPBQALPCQALQAeAfQBQAKRAeAPUBQAAUCQALVCQALWCQAABEKAREDKATELKASHKKASKJKASNIKATQHKATTGKATWFKAV|CDQAADCQABDDQADECQADHBSAGIAeAEIBQADICQADJAeAFJBQADJCQADKAeANKBQAGLAeAIMAeAgNAeAJNBSAKOAeAMOBQALOCQALPAeANPBQALPCQALQAeAfQBQAKRAeAPTBSAJUBQAAUCQALVCQALWCQAABFKASEEKATHDKATHLKASKKKASNJKATQIKATTHKATWGKAVZFKAc|CDQAADCQABDDQADHBQAGIAeAEIBQADICQADJAeAFJBQADJCQADKAeAHLAeAIMAeAgNAeAJNBQAKOAeAMOBQALOCQALPAeANPBQALPCQALQAeAORAeAPTBQAJUBQAAUCQALVCQALBGKASEFKASHEKATHMKASKDKATKLKASNKKASQJKATTIKATWHKATZGKAH|CDQAADCQABHBQADIAeAjIBQADICQADJAeAFJBQADKAeAHLAeAIMAeAgNAeAJNBQALOAeAQOBQALOCQALPAeANPBQALQAeAORAeAPTBQAQUBQAAUCQALBHKASEGKASHFKATKEKATKMKASNDKATNLKASQKKATTJKATWIKATZHKAH|CDQAADCQABHBQADHCQADIAeAEIBQADICQADJAeAFJBQAGKAeAHLAeAIMAeAgNAeAJNBQALNCQADOAeAMOBQALOCQALPAeANPBQAKQAeAORAeAPTBQAQTCQALUBQAAUCQALBIKASEHKASHGKATKFKATKNKAdNEKATNMKASQDKAVQLKATTKKATWJKATZIKAe'
VN_AL[storm]='||||||||||||||||||||||||||||||||eSBBBVJeTBBBVJdUBBBVJ|eSBBBVJeTBBBVJdUBBBVJdVBBA8JcWBBA8J|eSBBBVJeTBBBVJdUBBBVJdVBBA8JbYBBA8J|eSBBBVJeTBBBVJdUBBBVJdVBBA8JaaBBA8J|eSBBBVJeTBBBVJdUBBBVJdVBBA8JZcBBA8J|eSBBBVJeTBBBVJdUBBBVJdVBBA8JZdBBA8J|eSBBBVJeTBBBVJdUBBBVJdVBBA8JZdBBA8J|eSBBBVJeTBBBVJdUBBBVJdVBBA8JZdBBA8J||||||||'
VN_APAL[storm]='1414201010182c2c381c1c2c1414181c1c2430303c48485850506838384c3c3c502424383434483030403838482424302020342c2c343c3c485454643838446c6c8024242c50506018182820202c1c1c2018182434344030303828283024243454546c14142410101c0c0c104448585c5c68282c344c4c5c68707ca4b0c084909cacbcccc4d4e498a0acbcc8d8ccdcec9ca4b4c4d0e09ca4b88890a4646874bcccdc3c444ca8b4c8c0cce098a4b8b0bccc8490a0404450949cacc8d8e8b8c4d4dcf0fcdff0ffa4acc0c0d0e0b0c0d0585c68acb8c8d0e0ecd0dcec7c7c90a0a8b8788090383c444444506c707ca0a8b4b4c4d4b8c8d8a0acbc747488bcd0dcc8dce8a0b0bc4040547c849088909c9098a89098a4848c9cbcdcfcc4e0fc40444c909cac808898707480686c7c6c6c7c686878a8d4fcb0d8fcb8dcfca8cceca0a8bc4c505c585868a0d0fc98c4e46c849c8c94a45c6470c0ccdc5c606cccdce8848c98d8e8f8606470a8b4c4b4c0ccd4e4f4b0bcd05c60747c8090747c885c5c6c'
VN_AF[fog]='DCQAAECSABIBSABICSABJBQACJCQADKBeACKCQACLBQACLCQADMBSAEMCSABQBSAEQCSAERBQAFRCQAGSBeAFSCQAFTBQAHTCQAGUBSAIUCSAEAFQAJBESAKBFSALFESABGEQADGFSADHEeACHFQACIEeACIFQADJESADJFSABNESABOEQADOFSADPEeACPFQACQEeACQFQADRESADRFSABVESAEWEQAGWFSAGXEeAFXFQAFYEeAMYFQAGZFSANDISAODJSALEIfAPEJQAOFIfAPFJRAPGIQAOGJSAOHISALLISADLJSALMIfACMJQAONIfACNJRACOIQADOJSADPISABTISADTJSABUIfACUJQADVIfACVJRACWIQADWJSADXISABDLQAQELSALILSALIMSALJLQAPJMQAOKLeAPKMQAPLLQAPLMQAOMLSALMMSALQLSABQMSALRLQACRMQAOSLeACSMQACTLQACTMQARULSABUMSAS|DCSAAIBSADICSABJBeACJCQADKBeACKCQACLBQADLCSADMBSAEQBSAGQCSAERBeAFRCQAGSBeAFSCQAFTBQATTCSAGUBSAIAFSAJBESASFESADFFSABGEeACGFQADHEeACHFQACIEQADIFSADJESABNESADNFSABOEeACOFQADPEeACPFQACQEQADQFSADRESABVESAGVFSAEWEeAFWFQAGXEeAFXFQAFYEQAUYFSAGCISALDIQAODJSAOEIfAPEJRAPFIfAPFJQAOGISAOGJSALKISALLIQADLJSAOMIfACMJRAPNIfACNJQADOISADOJSABSISABTIQADTJSADUIfACUJRACVIfACVJQADWISADWJSABDLSAVHLSALILQAOIMSAOJLeAPJMQAPKLeAPKMQAOLLSAOLMSALPLSALQLQADQMSAORLeACRMQAPSLeACSMQADTLSADTMSAO|DCSAWHBSABIBQADICSADJBeACJCQACKBeACKCQADLBSADLCSABPBSAEQBQAGQCSAGRBeAFRCQAFSBeAFSCQAGTBSATTCSAEAFSAXEESABEFSALFEQACFFQADGEeACGFQACHEQACHFQADIESABIFSABMESABMFSABNEQACNFQADOEeACOFQACPEQACPFQADQESABQFSABUESAEUFSAEVEQAFVFQAGWEeAFWFQAFXEQAFXFQAGYESAYYFSAECISALCJSALDIRAPDJQAOEIfAPEJRAPFIRAPFJQAOGISALGJSALKISALKJSALLIRACLJQAOMIfACMJRAPNIRACNJQADOISABOJSABSISABSJSABTIRACTJQADUIfACUJRACVIRACVJQADWISABWJSABDLSAJHLSAOHMSALILeAPIMQAOJLeAPJMQAPKLQAOKMSAOLLSALPLSAOPMSALQLeACQMQAORLeACRMQAPSLQADSMSADTLSAB|DCSAWHBSABHCSABIBQACICQADJBeACJCQACKBQACKCQADLBSABLCSABPBSAEPCSAEQBQAFQCQAGRBeAFRCQAFSBQAFSCQAGTBSAZTCSAEDESABEEQADEFSAOFEeACFFQACGEeACGFQADHESADHFSABLESABMEQADMFSADNEeACNFQACOEeACOFQADPESADPFSABTESAEUEQAGUFSAGVEeAFVFQAFWEeAFWFQAGXESAGXFSAECISAOCJSALDIfAPDJQAOEIfAPEJRAPFIQAOFJSAOGISALKISAOKJSALLIfACLJQAOMIfACMJRAPNIQADNJSADOISABSISADSJSABTIfACTJQADUIfACUJRACVIQADVJSADWISABGLSALGMSAIHLQAPHMQAOILeAPIMQAPJLQAPJMQAOKLSALKMSALOLSALOMSALPLQAPPMQAOQLeACQMQAPRLQACRMQAOSLSABSMSABWLSAW|HBSADHCSABIBeACICQADJBeACJCQACKBQADKCSADLBSABPBSAGPCSAEQBeAFQCQAGRBeAFRCQAFSBQAGSCSAGTBSAZDESADDFSALEEeACEFQAOFEeACFFQACGEQADGFSADHESABLESADLFSABMEeACMFQADNEeACNFQACOEQADOFSADPESABTESAGTFSABUEeAFUFQAGVEeAFVFQAFWEQAGWFSAGXESAEBISALCIQAOCJSAODIfAPDJRAPEIfAPEJQAOFISAOFJSALJISALKIQAOKJSAOLIfACLJRAPMIfACMJQAONISADNJSABRISABSIQADSJSADTIfACTJRACUIfACUJQADVISADVJSABZISAaFLSALGLQAOGMSAbHLeAPHMQAPILeAPIMQAOJLSAOJMSALNLSALOLQAOOMSAOPLeAPPMQAPQLeACQMQAORLSADRMSALVLSABWLQAA|GBSAOHBQADHCSADIBeACICQACJBeACJCQADKBSADKCSABOBSAEPBQAGPCSAGQBeAFQCQAFRBeAFRCQAGSBSAGSCSAECESALCFSALDEQACDFQAOEEeACEFQAPFEQACFFQADGESABGFSABKESABKFSABLEQACLFQADMEeACMFQACNEQACNFQADOESABOFSABSESAESFSABTEQAFTFQADUEeAFUFQAFVEQAFVFQAGWESAEWFSAEBISALBJSASCIRAPCJQAODIfAPDJRAPEIRAPEJQAOFISALFJSALJISALJJSALKIRAPKJQAOLIfACLJRAPMIRACMJQAONISABNJSABRISABRJSABSIRACSJQADTIfACTJRACUIRACUJQADVISABVJSABZISAaFLSAOFMSAcGLeAPGMQAbHLeAPHMQAPILQAOIMSAOJLSALNLSAONMSALOLeAPOMQAOPLeAPPMQAPQLQADQMSAORLSABVLSADWLeAd|GBSAOGCSABHBQACHCQADIBeACICQACJBQACJCQADKBSABKCSABOBSAEOCSAEPBQAFPCQAGQBeAFQCQAFRBQAFRCQAGSBSAESCSAEWCSAeBESASCEQAOCFSAODEeACDFQAPEEeACEFQAOFESADFFSABJESABKEQADKFSADLEeACLFQACMEeACMFQADNESADNFSABRESABSEQAGSFSADTEeAFTFQACUEeAFUFQAGVESAGVFSAEBISAOBJSASCIfAPCJQAODIfAPDJRAPEIQAOEJSAOFISALJISAOJJSALKIfAPKJQAOLIfACLJRAPMIQADMJSAONISABRISADRJSABSIfACSJQADTIfACTJRACUIQADUJSADVISABZISAWELSALFLQAPFMQAfGLeAPGMQAgHLQAPHMQAOILSALIMSALMLSALMMSALNLQAPNMQAOOLeAPOMQAPPLQAPPMQAOQLSABQMSALULSABUMSASVLQACWLeAd|GBSARGCSABHBeACHCQADIBeACICQACJBQADJCSADKBSABOBSAGOCSAEPBeAFPCQAGQBeAFQCQAFRBQAGRCSAGSBSAEWCSAeBESAKBFSALCEeAPCFQAODEeACDFQAPEEQADEFSAOFESABJESADJFSABKEeACKFQADLEeACLFQACMEQADMFSADNESABRESADRFSABSEeAFSFQADTEeAFTFQACUEQAGUFSAGVESAEZFSANAISAXBIQAOBJSAKCIfAPCJRAPDIfAPDJQAOEISAOEJSALIISALJIQAOJJSAOKIfAPKJRAPLIfACLJQAOMISADMJSALQISABRIQADRJSADSIfACSJRACTIfACTJQADUISADUJSABYISABZIQAWDLSAJELQAOFLeAPFMQANGLeAPGMQAbHLSAOHMSALLLSALMLQAOMMSAONLeAPNMQAPOLeAPOMQAOPLSAOPMSALTLSABULQADUMSAKVLeACWLeAd|FBSASGBQARGCSADHBeACHCQACIBeACICQADJBSADJCSABNBSAEOBQAGOCSAGPBeAFPCQAFQBeAFQCQAGRBSAGRCSAEWCSAhAFSAXBEQAdBFQAOCEeAPCFQAPDEQACDFQAOEESABEFSALIESABIFSABJEQACJFQADKEeACKFQACLEQACLFQADMESABMFSABQESABQFSABREQACRFQADSEeAFSFQACTEQAFTFQADUESAEUFSAEYESAYYFSAEZFQAiAISAXBIRAPBJQAKCIfAPCJRAPDIRAPDJQAOEISALEJSALIISALIJSALJIRAPJJQAOKIfAPKJRAPLIRACLJQAOMISABMJSALQISABQJSABRIRACRJQADSIfACSJRACTIRACTJQADUISABUJSABYISABYJSAeZIRAKDLSAVELeAPFLeAPFMQANGLQAOGMSAbHLSALLLSAOLMSALMLeAPMMQAONLeAPNMQAPOLQAOOMSAOPLSALTLSADTMSAOULeACUMQAKVLeACWLQAA|FBSASFCSABGBQAjGCQADHBeACHCQACIBQACICQADJBSABJCSABNBSAENCSABOBQAFOCQAGPBeAFPCQAFQBQAFQCQAGRBSAERCSAEVCSAEWCQAhAFSAJBEeAdBFQAPCEeAPCFQAODESADDFSALHESABIEQADIFSADJEeACJFQACKEeACKFQADLESADLFSABPESABQEQADQFSADREeACRFQACSEeAFSFQADTESAGTFSABXESAEYEQAUYFSAGZFQAkAISAJBIfAPBJQAKCIfAPCJRAPDIQAODJSAOEISALIISAOIJSALJIfAPJJQAOKIfAPKJRAPLIQADLJSAOMISABQISADQJSABRIfACRJQADSIfACSJRACTIQADTJSADUISABYISADYJSAeZIfAKDLQAQELeAPFLQAPFMQAfGLSALGMSAIKLSALKMSALLLQAPLMQAOMLeAPMMQAPNLQAPNMQAOOLSALOMSALSLSABSMSABTLQACTMQARULeACUMQAlVLQACWLSAW|FBSAKFCSABGBeAjGCQADHBeACHCQACIBQADICSADJBSABNBSAGNCSABOBeAFOCQAGPBeAFPCQAFQBQAGQCSAGRBSAEVCSAEWCQAhAFQAJBEeAdBFQAPCEQAOCFSAODESABHESADHFSABIEeACIFQADJEeACJFQACKEQADKFSADLESABPESADPFSABQEeACQFQADREeACRFQACSEQAGSFSADTESAEXESAGXFSAEYEeAMYFQAGZFQAkAIQAJBIfAPBJRAdCIfAPCJQAODISAODJSALHISALIIQAOIJSAOJIfAPJJRAPKIfAPKJQAOLISADLJSALPISABQIQADQJSADRIfACRJRACSIfACSJQADTISADTJSABXISABYIQADYJSAhZIfAKDLeAQELeAPFLSAOFMSAcJLSALKLQAOKMSAOLLeAPLMQAPMLeAPMMQAONLSAONMSALRLSABSLQADSMSADTLeACTMQAjULeACUMQAKVLSAD|FBQAKFCSADGBeAjGCQACHBeACHCQADIBSADICSABMBSAENBQAGNCSADOBeAFOCQAFPBeAFPCQAGQBSAGQCSAEUBSAIVCSAGWCQAmAFQAnBEQAdBFQAOCESALCFSALGESABGFSABHEQACHFQADIEeACIFQACJEQACJFQADKESABKFSABOESABOFSABPEQACPFQADQEeACQFQACREQACRFQADSESAESFSABWESAEWFSAEXEQAFXFQAGYEeAMYFQAFZFQAiAIRAnBIfAPBJRAdCIRAPCJQAODISALDJSALHISALHJSALIIRAPIJQAOJIfAPJJRAPKIRAPKJQAOLISABLJSALPISABPJSABQIRACQJQADRIfACRJRACSIRACSJQADTISABTJSABXISABXJSABYIRACYJQAhZIfAKDLeAQELQAOFLSALJLSAOJMSALKLeAPKMQAOLLeAPLMQAPMLQAOMMSAONLSALRLSADRMSALSLeACSMQADTLeACTMQAjULQADUMSAKVLSAB|ECSABFBQAlFCQADGBeAjGCQACHBQACHCQADIBSABICSABMBSAEMCSABNBQAFNCQADOBeAFOCQAFPBQAFPCQAGQBSAEQCSAEUBSAIUCSAEVCQAGWCQAmAFQAJBESAKBFSALFESABGEQADGFSADHEeACHFQACIEeACIFQADJESADJFSABNESABOEQADOFSADPEeACPFQACQEeACQFQADRESADRFSABVESAEWEQAGWFSAGXEeAFXFQAFYEeAMYFQAGZFSANAIfAnBIfAPBJRAdCIQAOCJSAODISALHISAOHJSALIIfAPIJQAOJIfAPJJRAPKIQAOKJSAOLISABPISADPJSABQIfACQJQADRIfACRJRACSIQADSJSADTISABXISADXJSABYIfACYJQAhZIfAKDLQAQELSALILSALIMSALJLQAPJMQAOKLeAPKMQAPLLQAPLMQAOMLSALMMSALQLSABQMSALRLQACRMQAOSLeACSMQACTLQACTMQARULSABUMSAS|ECSABFBeAlFCQADGBeAjGCQACHBQADHCSADIBSABMBSAGMCSABNBeAFNCQADOBeAFOCQAFPBQAGPCSAGQBSAEUBSAbUCSAEVCQAGWCQAmAFSAJBESASFESADFFSABGEeACGFQADHEeACHFQACIEQADIFSADJESABNESADNFSABOEeACOFQADPEeACPFQACQEQADQFSADRESABVESAGVFSAEWEeAFWFQAGXEeAFXFQAFYEQAUYFSAGAIfAnBIfAPBJQAKCISAOCJSALGISALHIQAOHJSAOIIfAPIJRAPJIfAPJJQAOKISAOKJSALOISABPIQADPJSADQIfACQJRACRIfACRJQADSISADSJSABWISABXIQADXJSADYIfACYJRAmZIfAKDLSAVHLSALILQAOIMSAOJLeAPJMQAPKLeAPKMQAOLLSAOLMSALPLSALQLQADQMSAORLeACRMQAPSLeACSMQADTLSADTMSAO|ECSADFBeAlFCQACGBeAjGCQADHBSADHCSABLBSABMBQAGMCSADNBeAFNCQACOBeAFOCQAGPBSAGPCSAETBSAZUBQAbUCSAGVCQAFWCQAhAFSAXEESABEFSALFEQACFFQADGEeACGFQACHEQACHFQADIESABIFSABMESABMFSABNEQACNFQADOEeACOFQACPEQACPFQADQESABQFSABUESAEUFSAEVEQAFVFQAGWEeAFWFQAFXEQAFXFQAGYESAYYFSAEAIfAnBIRAPBJQAKCISALCJSALGISALGJSALHIRAPHJQAOIIfAPIJRAPJIRAPJJQAOKISALKJSALOISABOJSABPIRACPJQADQIfACQJRACRIRACRJQADSISABSJSABWISABWJSABXIRACXJQADYIfACYJRAmZIRAKDLSAJHLSAOHMSALILeAPIMQAOJLeAPJMQAPKLQAOKMSAOLLSALPLSAOPMSALQLeACQMQAORLeACRMQAPSLQADSMSADTLSAB|DCSAWECQADFBeAlFCQACGBQAjGCQADHBSABHCSABLBSABLCSABMBQAFMCQADNBeAFNCQACOBQAFOCQAGPBSAEPCSAETBSAZTCSAEUBQAoUCQAGVCQAFWCQAhDESABEEQADEFSAOFEeACFFQACGEeACGFQADHESADHFSABLESABMEQADMFSADNEeACNFQACOEeACOFQADPESADPFSABTESAEUEQAGUFSAGVEeAFVFQAFWEeAFWFQAGXESAGXFSAEAIfAnBIQAOBJSAKCISALGISAOGJSALHIfAPHJQAOIIfAPIJRAPJIQAOJJSAOKISALOISADOJSABPIfACPJQADQIfACQJRACRIQADRJSADSISABWISADWJSABXIfACXJQADYIfACYJRAmZIQAWGLSALGMSAIHLQAPHMQAOILeAPIMQAPJLQAPJMQAOKLSALKMSALOLSALOMSALPLQAPPMQAOQLeACQMQAPRLQACRMQAOSLSABSMSABWLSAW|DCSAWECQADFBeAlFCQACGBQARGCSADHBSABLBSADLCSABMBeAFMCQADNBeAFNCQACOBQAGOCSAGPBSAETBSATTCSAEUBeAoUCQAGVCQAFWCSAhDESADDFSALEEeACEFQAOFEeACFFQACGEQADGFSADHESABLESADLFSABMEeACMFQADNEeACNFQACOEQADOFSADPESABTESAGTFSABUEeAFUFQAGVEeAFVFQAFWEQAGWFSAGXESAEAIfAnBISAOBJSASFISALGIQAOGJSAOHIfAPHJRAPIIfAPIJQAOJISAOJJSALNISABOIQADOJSADPIfACPJRACQIfACQJQADRISADRJSABVISABWIQADWJSADXIfACXJRACYIfACYJQAhZISAWFLSALGLQAOGMSAbHLeAPHMQAPILeAPIMQAOJLSAOJMSALNLSALOLQAOOMSAOPLeAPPMQAPQLeACQMQAORLSADRMSALVLSABWLQAA|DCSAAECQACFBeAlFCQADGBSARGCSABKBSABLBQADLCSADMBeAFMCQACNBeAFNCQADOBSAGOCSAESBSAETBQATTCSAGUBeAoUCQAFVCQAGWCSAeCESALCFSALDEQACDFQAOEEeACEFQAPFEQACFFQADGESABGFSABKESABKFSABLEQACLFQADMEeACMFQACNEQACNFQADOESABOFSABSESAESFSABTEQAFTFQADUEeAFUFQAFVEQAFVFQAGWESAEWFSAEAIRAnBISALBJSASFISALFJSALGIRAPGJQAOHIfAPHJRAPIIRAPIJQAOJISALJJSALNISABNJSABOIRACOJQADPIfACPJRACQIRACQJQADRISABRJSABVISABVJSABWIRACWJQADXIfACXJRACYIRACYJQAhZISAaFLSAOFMSAcGLeAPGMQAbHLeAPHMQAPILQAOIMSAOJLSALNLSAONMSALOLeAPOMQAOPLeAPPMQAPQLQADQMSAORLSABVLSADWLeAd|DCQAAECQACFBQAlFCQADGBSAOGCSABKBSABKCSABLBQACLCQADMBeAFMCQACNBQAFNCQADOBSAEOCSAESBSAESCSAETBQAHTCQAGUBeAoUCQAFVCQAGWCSAeBESASCEQAOCFSAODEeACDFQAPEEeACEFQAOFESADFFSABJESABKEQADKFSADLEeACLFQACMEeACMFQADNESADNFSABRESABSEQAGSFSADTEeAFTFQACUEeAFUFQAGVESAGVFSAEAIQAJBISALFISAOFJSALGIfAPGJQAOHIfAPHJRAPIIQAOIJSAOJISALNISADNJSABOIfACOJQADPIfACPJRACQIQADQJSADRISABVISADVJSABWIfACWJQADXIfACXJRACYIQADYJSAhZISAaELSALFLQAPFMQAfGLeAPGMQAgHLQAPHMQAOILSALIMSALMLSALMMSALNLQAPNMQAOOLeAPOMQAPPLQAPPMQAOQLSABQMSALULSABUMSASVLQACWLeAd|DCQAAECQACFBQAKFCSADGBSAOKBSADKCSABLBeACLCQADMBeAFMCQACNBQAGNCSADOBSAESBSAGSCSAETBeAHTCQAGUBeAoUCQAFVCSAGBESAKBFSALCEeAPCFQAODEeACDFQAPEEQADEFSAOFESABJESADJFSABKEeACKFQADLEeACLFQACMEQADMFSADNESABRESADRFSABSEeAFSFQADTEeAFTFQACUEQAGUFSAGVESAEZFSANAISAJEISALFIQAOFJSAOGIfAPGJRAPHIfAPHJQAOIISAOIJSALMISABNIQADNJSADOIfACOJRACPIfACPJQADQISADQJSABUISABVIQADVJSADWIfACWJRACXIfACXJQADYISADYJSAeDLSAJELQAOFLeAPFMQANGLeAPGMQAbHLSAOHMSALLLSALMLQAOMMSAONLeAPNMQAPOLeAPOMQAOPLSAOPMSALTLSABULQADUMSAKVLeACWLeAd|DCQAdECQADFBSAKFCSABJBSABKBQADKCSADLBeACLCQACMBeAFMCQADNBSAGNCSABRBSAESBQAGSCSAGTBeAHTCQAFUBeAoUCQAGVCSAEAFSAXBEQAdBFQAOCEeAPCFQAPDEQACDFQAOEESABEFSALIESABIFSABJEQACJFQADKEeACKFQACLEQACLFQADMESABMFSABQESABQFSABREQACRFQADSEeAFSFQACTEQAFTFQADUESAEUFSAEYESAYYFSAEZFQAiAISAXEISALEJSALFIRAPFJQAOGIfAPGJRAPHIRAPHJQAOIISALIJSALMISABMJSALNIRACNJQADOIfACOJRACPIRACPJQADQISABQJSABUISABUJSABVIRACVJQADWIfACWJRACXIRACXJQADYISABYJSAeDLSAVELeAPFLeAPFMQANGLQAOGMSAbHLSALLLSAOLMSALMLeAPMMQAONLeAPNMQAPOLQAOOMSAOPLSALTLSADTMSAOULeACUMQAKVLeACWLQAA|DCQAdECQADFBSASFCSABJBSABJCSABKBQACKCQADLBeACLCQACMBQAFMCQADNBSAENCSABRBSAERCSAESBQAFSCQAGTBeAHTCQAFUBQAoUCQAGVCSAEAFSAJBEeAdBFQAPCEeAPCFQAODESADDFSALHESABIEQADIFSADJEeACJFQACKEeACKFQADLESADLFSABPESABQEQADQFSADREeACRFQACSEeAFSFQADTESAGTFSABXESAEYEQAUYFSAGZFQAkAISAXEISAOEJSALFIfAPFJQAOGIfAPGJRAPHIQAOHJSAOIISALMISADMJSALNIfACNJQADOIfACOJRACPIQADPJSADQISABUISADUJSABVIfACVJQADWIfACWJRACXIQADXJSADYISABDLQAQELeAPFLQAPFMQAfGLSALGMSAIKLSALKMSALLLQAPLMQAOMLeAPMMQAPNLQAPNMQAOOLSALOMSALSLSABSMSABTLQACTMQARULeACUMQAlVLQACWLSAW|DCQAdECSADFBSASJBSADJCSABKBeACKCQADLBeACLCQACMBQAGMCSADNBSAERBSAGRCSAESBeAFSCQAGTBeAHTCQAFUBQAbUCSAGAFQAJBEeAdBFQAPCEQAOCFSAODESABHESADHFSABIEeACIFQADJEeACJFQACKEQADKFSADLESABPESADPFSABQEeACQFQADREeACRFQACSEQAGSFSADTESAEXESAGXFSAEYEeAMYFQAGZFQAkDISALEIQAOEJSAOFIfAPFJRAPGIfAPGJQAOHISAOHJSALLISABMIQADMJSAONIfACNJRACOIfACOJQADPISADPJSABTISABUIQADUJSADVIfACVJRACWIfACWJQADXISADXJSABDLeAQELeAPFLSAOFMSAcJLSALKLQAOKMSAOLLeAPLMQAPMLeAPMMQAONLSAONMSALRLSABSLQADSMSADTLeACTMQAjULeACUMQAKVLSAD|DCQAAECSABIBSABJBQADJCSADKBeACKCQACLBeACLCQADMBSAGMCSABQBSAERBQAGRCSAGSBeAFSCQAFTBeAHTCQAGUBSAbUCSAEAFQAnBEQAdBFQAOCESALCFSALGESABGFSABHEQACHFQADIEeACIFQACJEQACJFQADKESABKFSABOESABOFSABPEQACPFQADQEeACQFQACREQACRFQADSESAESFSABWESAEWFSAEXEQAFXFQAGYEeAMYFQAFZFQAiDISALDJSALEIRAPEJQAOFIfAPFJRAPGIRAPGJQAOHISALHJSALLISABLJSALMIRACMJQAONIfACNJRACOIRACOJQADPISABPJSABTISABTJSABUIRACUJQADVIfACVJRACWIRACWJQADXISABXJSABDLeAQELQAOFLSALJLSAOJMSALKLeAPKMQAOLLeAPLMQAPMLQAOMMSAONLSALRLSADRMSALSLeACSMQADTLeACTMQAjULQADUMSAKVLSAB|DCQAAECSABIBSABICSABJBQACJCQADKBeACKCQACLBQACLCQADMBSAEMCSABQBSAEQCSAERBQAFRCQAGSBeAFSCQAFTBQAHTCQAGUBSAIUCSAEAFQAJBESAKBFSALFESABGEQADGFSADHEeACHFQACIEeACIFQADJESADJFSABNESABOEQADOFSADPEeACPFQACQEeACQFQADRESADRFSABVESAEWEQAGWFSAGXEeAFXFQAFYEeAMYFQAGZFSANDISAODJSALEIfAPEJQAOFIfAPFJRAPGIQAOGJSAOHISALLISADLJSALMIfACMJQAONIfACNJRACOIQADOJSADPISABTISADTJSABUIfACUJQADVIfACVJRACWIQADWJSADXISABDLQAQELSALILSALIMSALJLQAPJMQAOKLeAPKMQAPLLQAPLMQAOMLSALMMSALQLSABQMSALRLQACRMQAOSLeACSMQACTLQACTMQARULSABUMSAS|DCSAAIBSADICSABJBeACJCQADKBeACKCQACLBQADLCSADMBSAEQBSAGQCSAERBeAFRCQAGSBeAFSCQAFTBQATTCSAGUBSAIAFSAJBESASFESADFFSABGEeACGFQADHEeACHFQACIEQADIFSADJESABNESADNFSABOEeACOFQADPEeACPFQACQEQADQFSADRESABVESAGVFSAEWEeAFWFQAGXEeAFXFQAFYEQAUYFSAGCISALDIQAODJSAOEIfAPEJRAPFIfAPFJQAOGISAOGJSALKISALLIQADLJSAOMIfACMJRAPNIfACNJQADOISADOJSABSISABTIQADTJSADUIfACUJRACVIfACVJQADWISADWJSABDLSAVHLSALILQAOIMSAOJLeAPJMQAPKLeAPKMQAOLLSAOLMSALPLSALQLQADQMSAORLeACRMQAPSLeACSMQADTLSADTMSAO|DCSAWHBSABIBQADICSADJBeACJCQACKBeACKCQADLBSADLCSABPBSAEQBQAGQCSAGRBeAFRCQAFSBeAFSCQAGTBSATTCSAEAFSAXEESABEFSALFEQACFFQADGEeACGFQACHEQACHFQADIESABIFSABMESABMFSABNEQACNFQADOEeACOFQACPEQACPFQADQESABQFSABUESAEUFSAEVEQAFVFQAGWEeAFWFQAFXEQAFXFQAGYESAYYFSAECISALCJSALDIRAPDJQAOEIfAPEJRAPFIRAPFJQAOGISALGJSALKISALKJSALLIRACLJQAOMIfACMJRAPNIRACNJQADOISABOJSABSISABSJSABTIRACTJQADUIfACUJRACVIRACVJQADWISABWJSABDLSAJHLSAOHMSALILeAPIMQAOJLeAPJMQAPKLQAOKMSAOLLSALPLSAOPMSALQLeACQMQAORLeACRMQAPSLQADSMSADTLSAB|DCSAWHBSABHCSABIBQACICQADJBeACJCQACKBQACKCQADLBSABLCSABPBSAEPCSAEQBQAFQCQAGRBeAFRCQAFSBQAFSCQAGTBSAZTCSAEDESABEEQADEFSAOFEeACFFQACGEeACGFQADHESADHFSABLESABMEQADMFSADNEeACNFQACOEeACOFQADPESADPFSABTESAEUEQAGUFSAGVEeAFVFQAFWEeAFWFQAGXESAGXFSAECISAOCJSALDIfAPDJQAOEIfAPEJRAPFIQAOFJSAOGISALKISAOKJSALLIfACLJQAOMIfACMJRAPNIQADNJSADOISABSISADSJSABTIfACTJQADUIfACUJRACVIQADVJSADWISABGLSALGMSAIHLQAPHMQAOILeAPIMQAPJLQAPJMQAOKLSALKMSALOLSALOMSALPLQAPPMQAOQLeACQMQAPRLQACRMQAOSLSABSMSABWLSAW|HBSADHCSABIBeACICQADJBeACJCQACKBQADKCSADLBSABPBSAGPCSAEQBeAFQCQAGRBeAFRCQAFSBQAGSCSAGTBSAZDESADDFSALEEeACEFQAOFEeACFFQACGEQADGFSADHESABLESADLFSABMEeACMFQADNEeACNFQACOEQADOFSADPESABTESAGTFSABUEeAFUFQAGVEeAFVFQAFWEQAGWFSAGXESAEBISALCIQAOCJSAODIfAPDJRAPEIfAPEJQAOFISAOFJSALJISALKIQAOKJSAOLIfACLJRAPMIfACMJQAONISADNJSABRISABSIQADSJSADTIfACTJRACUIfACUJQADVISADVJSABZISAaFLSALGLQAOGMSAbHLeAPHMQAPILeAPIMQAOJLSAOJMSALNLSALOLQAOOMSAOPLeAPPMQAPQLeACQMQAORLSADRMSALVLSABWLQAA|GBSAOHBQADHCSADIBeACICQACJBeACJCQADKBSADKCSABOBSAEPBQAGPCSAGQBeAFQCQAFRBeAFRCQAGSBSAGSCSAECESALCFSALDEQACDFQAOEEeACEFQAPFEQACFFQADGESABGFSABKESABKFSABLEQACLFQADMEeACMFQACNEQACNFQADOESABOFSABSESAESFSABTEQAFTFQADUEeAFUFQAFVEQAFVFQAGWESAEWFSAEBISALBJSASCIRAPCJQAODIfAPDJRAPEIRAPEJQAOFISALFJSALJISALJJSALKIRAPKJQAOLIfACLJRAPMIRACMJQAONISABNJSABRISABRJSABSIRACSJQADTIfACTJRACUIRACUJQADVISABVJSABZISAaFLSAOFMSAcGLeAPGMQAbHLeAPHMQAPILQAOIMSAOJLSALNLSAONMSALOLeAPOMQAOPLeAPPMQAPQLQADQMSAORLSABVLSADWLeAd|GBSAOGCSABHBQACHCQADIBeACICQACJBQACJCQADKBSABKCSABOBSAEOCSAEPBQAFPCQAGQBeAFQCQAFRBQAFRCQAGSBSAESCSAEWCSAeBESASCEQAOCFSAODEeACDFQAPEEeACEFQAOFESADFFSABJESABKEQADKFSADLEeACLFQACMEeACMFQADNESADNFSABRESABSEQAGSFSADTEeAFTFQACUEeAFUFQAGVESAGVFSAEBISAOBJSASCIfAPCJQAODIfAPDJRAPEIQAOEJSAOFISALJISAOJJSALKIfAPKJQAOLIfACLJRAPMIQADMJSAONISABRISADRJSABSIfACSJQADTIfACTJRACUIQADUJSADVISABZISAWELSALFLQAPFMQAfGLeAPGMQAgHLQAPHMQAOILSALIMSALMLSALMMSALNLQAPNMQAOOLeAPOMQAPPLQAPPMQAOQLSABQMSALULSABUMSASVLQACWLeAd|GBSARGCSABHBeACHCQADIBeACICQACJBQADJCSADKBSABOBSAGOCSAEPBeAFPCQAGQBeAFQCQAFRBQAGRCSAGSBSAEWCSAeBESAKBFSALCEeAPCFQAODEeACDFQAPEEQADEFSAOFESABJESADJFSABKEeACKFQADLEeACLFQACMEQADMFSADNESABRESADRFSABSEeAFSFQADTEeAFTFQACUEQAGUFSAGVESAEZFSANAISAXBIQAOBJSAKCIfAPCJRAPDIfAPDJQAOEISAOEJSALIISALJIQAOJJSAOKIfAPKJRAPLIfACLJQAOMISADMJSALQISABRIQADRJSADSIfACSJRACTIfACTJQADUISADUJSABYISABZIQAWDLSAJELQAOFLeAPFMQANGLeAPGMQAbHLSAOHMSALLLSALMLQAOMMSAONLeAPNMQAPOLeAPOMQAOPLSAOPMSALTLSABULQADUMSAKVLeACWLeAd|FBSASGBQARGCSADHBeACHCQACIBeACICQADJBSADJCSABNBSAEOBQAGOCSAGPBeAFPCQAFQBeAFQCQAGRBSAGRCSAEWCSAhAFSAXBEQAdBFQAOCEeAPCFQAPDEQACDFQAOEESABEFSALIESABIFSABJEQACJFQADKEeACKFQACLEQACLFQADMESABMFSABQESABQFSABREQACRFQADSEeAFSFQACTEQAFTFQADUESAEUFSAEYESAYYFSAEZFQAiAISAXBIRAPBJQAKCIfAPCJRAPDIRAPDJQAOEISALEJSALIISALIJSALJIRAPJJQAOKIfAPKJRAPLIRACLJQAOMISABMJSALQISABQJSABRIRACRJQADSIfACSJRACTIRACTJQADUISABUJSABYISABYJSAeZIRAKDLSAVELeAPFLeAPFMQANGLQAOGMSAbHLSALLLSAOLMSALMLeAPMMQAONLeAPNMQAPOLQAOOMSAOPLSALTLSADTMSAOULeACUMQAKVLeACWLQAA|FBSASFCSABGBQAjGCQADHBeACHCQACIBQACICQADJBSABJCSABNBSAENCSABOBQAFOCQAGPBeAFPCQAFQBQAFQCQAGRBSAERCSAEVCSAEWCQAhAFSAJBEeAdBFQAPCEeAPCFQAODESADDFSALHESABIEQADIFSADJEeACJFQACKEeACKFQADLESADLFSABPESABQEQADQFSADREeACRFQACSEeAFSFQADTESAGTFSABXESAEYEQAUYFSAGZFQAkAISAJBIfAPBJQAKCIfAPCJRAPDIQAODJSAOEISALIISAOIJSALJIfAPJJQAOKIfAPKJRAPLIQADLJSAOMISABQISADQJSABRIfACRJQADSIfACSJRACTIQADTJSADUISABYISADYJSAeZIfAKDLQAQELeAPFLQAPFMQAfGLSALGMSAIKLSALKMSALLLQAPLMQAOMLeAPMMQAPNLQAPNMQAOOLSALOMSALSLSABSMSABTLQACTMQARULeACUMQAlVLQACWLSAW|FBSAKFCSABGBeAjGCQADHBeACHCQACIBQADICSADJBSABNBSAGNCSABOBeAFOCQAGPBeAFPCQAFQBQAGQCSAGRBSAEVCSAEWCQAhAFQAJBEeAdBFQAPCEQAOCFSAODESABHESADHFSABIEeACIFQADJEeACJFQACKEQADKFSADLESABPESADPFSABQEeACQFQADREeACRFQACSEQAGSFSADTESAEXESAGXFSAEYEeAMYFQAGZFQAkAIQAJBIfAPBJRAdCIfAPCJQAODISAODJSALHISALIIQAOIJSAOJIfAPJJRAPKIfAPKJQAOLISADLJSALPISABQIQADQJSADRIfACRJRACSIfACSJQADTISADTJSABXISABYIQADYJSAhZIfAKDLeAQELeAPFLSAOFMSAcJLSALKLQAOKMSAOLLeAPLMQAPMLeAPMMQAONLSAONMSALRLSABSLQADSMSADTLeACTMQAjULeACUMQAKVLSAD|FBQAKFCSADGBeAjGCQACHBeACHCQADIBSADICSABMBSAENBQAGNCSADOBeAFOCQAFPBeAFPCQAGQBSAGQCSAEUBSAIVCSAGWCQAmAFQAnBEQAdBFQAOCESALCFSALGESABGFSABHEQACHFQADIEeACIFQACJEQACJFQADKESABKFSABOESABOFSABPEQACPFQADQEeACQFQACREQACRFQADSESAESFSABWESAEWFSAEXEQAFXFQAGYEeAMYFQAFZFQAiAIRAnBIfAPBJRAdCIRAPCJQAODISALDJSALHISALHJSALIIRAPIJQAOJIfAPJJRAPKIRAPKJQAOLISABLJSALPISABPJSABQIRACQJQADRIfACRJRACSIRACSJQADTISABTJSABXISABXJSABYIRACYJQAhZIfAKDLeAQELQAOFLSALJLSAOJMSALKLeAPKMQAOLLeAPLMQAPMLQAOMMSAONLSALRLSADRMSALSLeACSMQADTLeACTMQAjULQADUMSAKVLSAB|ECSABFBQAlFCQADGBeAjGCQACHBQACHCQADIBSABICSABMBSAEMCSABNBQAFNCQADOBeAFOCQAFPBQAFPCQAGQBSAEQCSAEUBSAIUCSAEVCQAGWCQAmAFQAJBESAKBFSALFESABGEQADGFSADHEeACHFQACIEeACIFQADJESADJFSABNESABOEQADOFSADPEeACPFQACQEeACQFQADRESADRFSABVESAEWEQAGWFSAGXEeAFXFQAFYEeAMYFQAGZFSANAIfAnBIfAPBJRAdCIQAOCJSAODISALHISAOHJSALIIfAPIJQAOJIfAPJJRAPKIQAOKJSAOLISABPISADPJSABQIfACQJQADRIfACRJRACSIQADSJSADTISABXISADXJSABYIfACYJQAhZIfAKDLQAQELSALILSALIMSALJLQAPJMQAOKLeAPKMQAPLLQAPLMQAOMLSALMMSALQLSABQMSALRLQACRMQAOSLeACSMQACTLQACTMQARULSABUMSAS|ECSABFBeAlFCQADGBeAjGCQACHBQADHCSADIBSABMBSAGMCSABNBeAFNCQADOBeAFOCQAFPBQAGPCSAGQBSAEUBSAbUCSAEVCQAGWCQAmAFSAJBESASFESADFFSABGEeACGFQADHEeACHFQACIEQADIFSADJESABNESADNFSABOEeACOFQADPEeACPFQACQEQADQFSADRESABVESAGVFSAEWEeAFWFQAGXEeAFXFQAFYEQAUYFSAGAIfAnBIfAPBJQAKCISAOCJSALGISALHIQAOHJSAOIIfAPIJRAPJIfAPJJQAOKISAOKJSALOISABPIQADPJSADQIfACQJRACRIfACRJQADSISADSJSABWISABXIQADXJSADYIfACYJRAmZIfAKDLSAVHLSALILQAOIMSAOJLeAPJMQAPKLeAPKMQAOLLSAOLMSALPLSALQLQADQMSAORLeACRMQAPSLeACSMQADTLSADTMSAO|ECSADFBeAlFCQACGBeAjGCQADHBSADHCSABLBSABMBQAGMCSADNBeAFNCQACOBeAFOCQAGPBSAGPCSAETBSAZUBQAbUCSAGVCQAFWCQAhAFSAXEESABEFSALFEQACFFQADGEeACGFQACHEQACHFQADIESABIFSABMESABMFSABNEQACNFQADOEeACOFQACPEQACPFQADQESABQFSABUESAEUFSAEVEQAFVFQAGWEeAFWFQAFXEQAFXFQAGYESAYYFSAEAIfAnBIRAPBJQAKCISALCJSALGISALGJSALHIRAPHJQAOIIfAPIJRAPJIRAPJJQAOKISALKJSALOISABOJSABPIRACPJQADQIfACQJRACRIRACRJQADSISABSJSABWISABWJSABXIRACXJQADYIfACYJRAmZIRAKDLSAJHLSAOHMSALILeAPIMQAOJLeAPJMQAPKLQAOKMSAOLLSALPLSAOPMSALQLeACQMQAORLeACRMQAPSLQADSMSADTLSAB|DCSAWECQADFBeAlFCQACGBQAjGCQADHBSABHCSABLBSABLCSABMBQAFMCQADNBeAFNCQACOBQAFOCQAGPBSAEPCSAETBSAZTCSAEUBQAoUCQAGVCQAFWCQAhDESABEEQADEFSAOFEeACFFQACGEeACGFQADHESADHFSABLESABMEQADMFSADNEeACNFQACOEeACOFQADPESADPFSABTESAEUEQAGUFSAGVEeAFVFQAFWEeAFWFQAGXESAGXFSAEAIfAnBIQAOBJSAKCISALGISAOGJSALHIfAPHJQAOIIfAPIJRAPJIQAOJJSAOKISALOISADOJSABPIfACPJQADQIfACQJRACRIQADRJSADSISABWISADWJSABXIfACXJQADYIfACYJRAmZIQAWGLSALGMSAIHLQAPHMQAOILeAPIMQAPJLQAPJMQAOKLSALKMSALOLSALOMSALPLQAPPMQAOQLeACQMQAPRLQACRMQAOSLSABSMSABWLSAW|DCSAWECQADFBeAlFCQACGBQARGCSADHBSABLBSADLCSABMBeAFMCQADNBeAFNCQACOBQAGOCSAGPBSAETBSATTCSAEUBeAoUCQAGVCQAFWCSAhDESADDFSALEEeACEFQAOFEeACFFQACGEQADGFSADHESABLESADLFSABMEeACMFQADNEeACNFQACOEQADOFSADPESABTESAGTFSABUEeAFUFQAGVEeAFVFQAFWEQAGWFSAGXESAEAIfAnBISAOBJSASFISALGIQAOGJSAOHIfAPHJRAPIIfAPIJQAOJISAOJJSALNISABOIQADOJSADPIfACPJRACQIfACQJQADRISADRJSABVISABWIQADWJSADXIfACXJRACYIfACYJQAhZISAWFLSALGLQAOGMSAbHLeAPHMQAPILeAPIMQAOJLSAOJMSALNLSALOLQAOOMSAOPLeAPPMQAPQLeACQMQAORLSADRMSALVLSABWLQAA|DCSAAECQACFBeAlFCQADGBSARGCSABKBSABLBQADLCSADMBeAFMCQACNBeAFNCQADOBSAGOCSAESBSAETBQATTCSAGUBeAoUCQAFVCQAGWCSAeCESALCFSALDEQACDFQAOEEeACEFQAPFEQACFFQADGESABGFSABKESABKFSABLEQACLFQADMEeACMFQACNEQACNFQADOESABOFSABSESAESFSABTEQAFTFQADUEeAFUFQAFVEQAFVFQAGWESAEWFSAEAIRAnBISALBJSASFISALFJSALGIRAPGJQAOHIfAPHJRAPIIRAPIJQAOJISALJJSALNISABNJSABOIRACOJQADPIfACPJRACQIRACQJQADRISABRJSABVISABVJSABWIRACWJQADXIfACXJRACYIRACYJQAhZISAaFLSAOFMSAcGLeAPGMQAbHLeAPHMQAPILQAOIMSAOJLSALNLSAONMSALOLeAPOMQAOPLeAPPMQAPQLQADQMSAORLSABVLSADWLeAd|DCQAAECQACFBQAlFCQADGBSAOGCSABKBSABKCSABLBQACLCQADMBeAFMCQACNBQAFNCQADOBSAEOCSAESBSAESCSAETBQAHTCQAGUBeAoUCQAFVCQAGWCSAeBESASCEQAOCFSAODEeACDFQAPEEeACEFQAOFESADFFSABJESABKEQADKFSADLEeACLFQACMEeACMFQADNESADNFSABRESABSEQAGSFSADTEeAFTFQACUEeAFUFQAGVESAGVFSAEAIQAJBISALFISAOFJSALGIfAPGJQAOHIfAPHJRAPIIQAOIJSAOJISALNISADNJSABOIfACOJQADPIfACPJRACQIQADQJSADRISABVISADVJSABWIfACWJQADXIfACXJRACYIQADYJSAhZISAaELSALFLQAPFMQAfGLeAPGMQAgHLQAPHMQAOILSALIMSALMLSALMMSALNLQAPNMQAOOLeAPOMQAPPLQAPPMQAOQLSABQMSALULSABUMSASVLQACWLeAd|DCQAAECQACFBQAKFCSADGBSAOKBSADKCSABLBeACLCQADMBeAFMCQACNBQAGNCSADOBSAESBSAGSCSAETBeAHTCQAGUBeAoUCQAFVCSAGBESAKBFSALCEeAPCFQAODEeACDFQAPEEQADEFSAOFESABJESADJFSABKEeACKFQADLEeACLFQACMEQADMFSADNESABRESADRFSABSEeAFSFQADTEeAFTFQACUEQAGUFSAGVESAEZFSANAISAJEISALFIQAOFJSAOGIfAPGJRAPHIfAPHJQAOIISAOIJSALMISABNIQADNJSADOIfACOJRACPIfACPJQADQISADQJSABUISABVIQADVJSADWIfACWJRACXIfACXJQADYISADYJSAeDLSAJELQAOFLeAPFMQANGLeAPGMQAbHLSAOHMSALLLSALMLQAOMMSAONLeAPNMQAPOLeAPOMQAOPLSAOPMSALTLSABULQADUMSAKVLeACWLeAd|DCQAdECQADFBSAKFCSABJBSABKBQADKCSADLBeACLCQACMBeAFMCQADNBSAGNCSABRBSAESBQAGSCSAGTBeAHTCQAFUBeAoUCQAGVCSAEAFSAXBEQAdBFQAOCEeAPCFQAPDEQACDFQAOEESABEFSALIESABIFSABJEQACJFQADKEeACKFQACLEQACLFQADMESABMFSABQESABQFSABREQACRFQADSEeAFSFQACTEQAFTFQADUESAEUFSAEYESAYYFSAEZFQAiAISAXEISALEJSALFIRAPFJQAOGIfAPGJRAPHIRAPHJQAOIISALIJSALMISABMJSALNIRACNJQADOIfACOJRACPIRACPJQADQISABQJSABUISABUJSABVIRACVJQADWIfACWJRACXIRACXJQADYISABYJSAeDLSAVELeAPFLeAPFMQANGLQAOGMSAbHLSALLLSAOLMSALMLeAPMMQAONLeAPNMQAPOLQAOOMSAOPLSALTLSADTMSAOULeACUMQAKVLeACWLQAA|DCQAdECQADFBSASFCSABJBSABJCSABKBQACKCQADLBeACLCQACMBQAFMCQADNBSAENCSABRBSAERCSAESBQAFSCQAGTBeAHTCQAFUBQAoUCQAGVCSAEAFSAJBEeAdBFQAPCEeAPCFQAODESADDFSALHESABIEQADIFSADJEeACJFQACKEeACKFQADLESADLFSABPESABQEQADQFSADREeACRFQACSEeAFSFQADTESAGTFSABXESAEYEQAUYFSAGZFQAkAISAXEISAOEJSALFIfAPFJQAOGIfAPGJRAPHIQAOHJSAOIISALMISADMJSALNIfACNJQADOIfACOJRACPIQADPJSADQISABUISADUJSABVIfACVJQADWIfACWJRACXIQADXJSADYISABDLQAQELeAPFLQAPFMQAfGLSALGMSAIKLSALKMSALLLQAPLMQAOMLeAPMMQAPNLQAPNMQAOOLSALOMSALSLSABSMSABTLQACTMQARULeACUMQAlVLQACWLSAW|DCQAdECSADFBSASJBSADJCSABKBeACKCQADLBeACLCQACMBQAGMCSADNBSAERBSAGRCSAESBeAFSCQAGTBeAHTCQAFUBQAbUCSAGAFQAJBEeAdBFQAPCEQAOCFSAODESABHESADHFSABIEeACIFQADJEeACJFQACKEQADKFSADLESABPESADPFSABQEeACQFQADREeACRFQACSEQAGSFSADTESAEXESAGXFSAEYEeAMYFQAGZFQAkDISALEIQAOEJSAOFIfAPFJRAPGIfAPGJQAOHISAOHJSALLISABMIQADMJSAONIfACNJRACOIfACOJQADPISADPJSABTISABUIQADUJSADVIfACVJRACWIfACWJQADXISADXJSABDLeAQELeAPFLSAOFMSAcJLSALKLQAOKMSAOLLeAPLMQAPMLeAPMMQAONLSAONMSALRLSABSLQADSMSADTLeACTMQAjULeACUMQAKVLSAD|DCQAAECSABIBSABJBQADJCSADKBeACKCQACLBeACLCQADMBSAGMCSABQBSAERBQAGRCSAGSBeAFSCQAFTBeAHTCQAGUBSAbUCSAEAFQAnBEQAdBFQAOCESALCFSALGESABGFSABHEQACHFQADIEeACIFQACJEQACJFQADKESABKFSABOESABOFSABPEQACPFQADQEeACQFQACREQACRFQADSESAESFSABWESAEWFSAEXEQAFXFQAGYEeAMYFQAFZFQAiDISALDJSALEIRAPEJQAOFIfAPFJRAPGIRAPGJQAOHISALHJSALLISABLJSALMIRACMJQAONIfACNJRACOIRACOJQADPISABPJSABTISABTJSABUIRACUJQADVIfACVJRACWIRACWJQADXISABXJSABDLeAQELQAOFLSALJLSAOJMSALKLeAPKMQAOLLeAPLMQAPMLQAOMMSAONLSALRLSADRMSALSLeACSMQADTLeACTMQAjULQADUMSAKVLSAB'
VN_AL[fog]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[fog]='5050546c6c789c9ca8848490888898c8c8d4a8a8b4c0c0c85050583030384c4c5454545c9898a044444c6464707878844848507c7c88404044a0a0ac8080883c3c4440404828282c68687480809034343c6060683030345c5c6450505c38384070707c64646c5454589494a06464685c5c607878803c3c4074747c'
VN_AF[sand]='QASAAKASABGBSACSBSADMBSADICSAEUCSADOCSADWDSAFEDSAGQDSAFVDGAGYESAHGESAGSESAFIFSAIUFSAJCFSAKKGSAEWGSADEGSALQGGAMMHSAIYHSAJGHSAKSHSAIOISAGIISAMUISAGQJSAGKJSAMWJSAGLJGANSKQAEMKQALOLRALILRALQMQAKKMQAKGMGAOMNQAP|NASAQJBSAEPBSADLCSAIFCSAIRCSAJRCGAGNDSAGHDSAGTDSAFJESAIVESAJDESAILFSAEXFSADFFSAEMFGAMBGSALNGSAEZGSARHGSAEDHSAKPHSAIJHSAIRISAGLISAGXISAGHIGANTJSAIBJSASNJSAIVKQAEDKQALPKQAEFLRALRLRAEHMQAMTMQATNMQAMJNQAUPNQAV|KASAWMBSAJGBSAXSBSAJNBGAGOCSAFICSAGUCSAFQDSAFKDSAGWDSAFSESADMESAEYESAYIEGAMCFSALOFSAEIFSAEEGSAKQGSAIKGSAIGHSAMSHSAGAHSAZMHSAGDHGANIISAKUISAICISAKOISAIWJSAEEJSALQJSAEGKQALSKQAEILQAKULQAIKMQAMMNQAa|NASAQJAGAUPBSAJJBSAIRCSAFLCSAGTDSAJNDSAIEDGAMVESADDESAEPESAEXFSADFFSAERFSAEHGSAGTGSAGBGSAMNGSAGZGGAbJHSAGVHSAGDHSAMPHSAGLISAIXISAIFISAKRISAINJSAEHJSALTJSAEUJGAMJKQAKVKQAIDKQAKLLQAMFLQAMNMQAMHMQAMPMGANPNQAcJNQAd|QASAAKASABGBSATSBSAFMBSAFICSAIUCSAJOCSAJWDSADEDSAEQDSADYESAYGESAESESADIFSAIUFSAJCFSAKVFGAGKGSAGWGSAFEGSAMMHSAIYHSAJGHSAKSHSAIOISAEIISALUISAEQIGAMQJSAEKJSALWJSAESKQAIMKQAKOLQAMILQAMLLGANQMQAKKMQAKMNQAe|NASAfJBSAGPBSAFLCSAIFCSAIRCSAJNDSAEHDSAETDSADJESAIVESAJDESAIREGAMLFSAGXFSAFFFSAGBGSAMNGSAGZGSAgHGSAGDHTALPHTAEJHTAEMHGAMRISAELISAEXISAETJSAIBJSASNJSAIVKQAGDKQAMPKQAGHKGANFLQAKRLQAIHMQALTMQACNMQALJNQAdPNQAc|KASAhMBSAJGBSAXSBSAJOCSADICSAEUCSADQDSADKDSAEWDSADNDGAMSESAJMESAIYESAiCFSAMOFSAGIFSAGEGSAKQGSAIKGSAIIGGAMGHTALSHTAEAHTAjMHTAEIISALUISAECISALOISAEWJSAGEJSAMQJSAGDJGANGKQAMSKQAGILQAKULQAIKMQALMNQAa|NASAfPBSADJBSAERCSADLCSAEJCGAMTDSAJNDSAIVESAFDESAGPESAGXFSAJFFSAIRFSAIEFGANHGSAETGSAEBGSALNGSAEJHTAEVHTAEDHTALPHTAELISAIXISAIFISAKRISAIZIGAkNJSAGHJSAMTJSAGJKQAKVKQAIDKQAKLLRALFLRALULGAMNMQALHMQALPNQAlJNQAm|QASAAKASABGBSACSBSADMBSADFBGAnICSAEUCSADOCSADWDSAFEDSAGQDSAFYESAHGESAGSESAFIFSAIUFSAJCFSAKKGSAEWGSADEGSALMHSAIYHSAJGHSAKSHSAIVHGAMOISAGIISAMUISAGQJSAGKJSAMWJSAGSKQAEMKQALQKGAMOLRALILRALQMQAKKMQAKMNQAPLNGAo|NASAQJBSAEPBSADLCSAIFCSAIRCSAJNDSAGHDSAGTDSAFWDGAGJESAIVESAJDESAILFSAEXFSADFFSAEBGSALNGSAEZGSARHGSAERGGAMDHSAKPHSAIJHSAIRISAGLISAGXISAGTJSAIBJSASNJSAIMJGANVKQAEDKQALPKQAEFLRALRLRAEHMQAMTMQATNMQAMHMGANJNQAUPNQAV|KASAWMBSAJGBSAXSBSAJOCSAFICSAGUCSAFSCGAGQDSAFKDSAGWDSAFSESADMESAEYESAYCFSALOFSAEIFSAENFGAMEGSAKQGSAIKGSAIGHSAMSHSAGAHSAZMHSAGIISAKUISAICISAKOISAIIIGANWJSAEEJSALQJSAEGKQALSKQAEILQAKULQAIDLGApKMQAMMNQAa|NASAQPBSAJJBSAIOBGAGRCSAFLCSAGTDSAJNDSAIVESADDESAEPESAEJEGAMXFSADFFSAERFSAEHGSAGTGSAGBGSAMNGSAGJHSAGVHSAGDHSAMPHSAGEHGANLISAIXISAIFISAKRISAINJSAEHJSALTJSAEJKQAKVKQAIDKQAKLLQAMFLQAMNMQAMHMQAMPNQAcJNQAd|QASAAKASABKAGAqGBSATSBSAFMBSAFICSAIUCSAJOCSAJWDSADEDSAEQDSADFDGAMYESAYGESAESESADIFSAIUFSAJCFSAKKGSAGWGSAFEGSAMAGGArMHSAIYHSAJGHSAKSHSAIOISAEIISALUISAEQJSAEKJSALWJSAEVJGAMSKQAIMKQAKOLQAMILQAMQMQAKKMQAKQMGANMNQAe|NASAfJBSAGPBSAFLCSAIFCSAIRCSAJNDSAEHDSAETDSADJESAIVESAJDESAILFSAGXFSAFFFSAGWFGAGBGSAMNGSAGZGSAgHGSAGDHTALPHTAEJHTAERISAELISAEXISAERIGAMTJSAIBJSASNJSAIVKQAGDKQAMPKQAGFLQAKRLQAIMLGANHMQALTMQACNMQALJNQAdPNQAc|KASAhMBSAJGBSAXSBSAJOCSADICSAEUCSADQDSADKDSAEWDSADSESAJMESAIYESAiSEGAGCFSAMOFSAGIFSAGEGSAKQGSAIKGSAIGHTALSHTAEAHTAjMHTAENHGAMIISALUISAECISALOISAEWJSAGEJSAMQJSAGGKQAMSKQAGIKGANILQAKULQAIKMQALMNQAa|NASAfPBSADJBSAERCSADLCSAETDSAJNDSAIODGAMVESAFDESAGPESAGXFSAJFFSAIRFSAIHGSAETGSAEBGSALNGSAEJGGAMJHTAEVHTAEDHTALPHTAELISAIXISAIFISAKRISAINJSAGHJSAMTJSAGEJGANJKQAKVKQAIDKQAKLLRALFLRALNMQALHMQALPNQAlJNQAm|QASAAKASABGBSACSBSADMBSADICSAEUCSADOCSADKCGAMWDSAFEDSAGQDSAFYESAHGESAGSESAFIFSAIUFSAJCFSAKFFGAMKGSAEWGSADEGSALMHSAIYHSAJGHSAKSHSAIOISAGIISAMUISAGAIGAsQJSAGKJSAMWJSAGSKQAEMKQALOLRALILRALVLGAMQMQAKKMQAKMNQAP|NASAQJBSAEPBSADGBGAtLCSAIFCSAIRCSAJNDSAGHDSAGTDSAFJESAIVESAJDESAIBEGAuLFSAEXFSADFFSAEBGSALNGSAEZGSARHGSAEDHSAKPHSAIJHSAIWHGAMRISAGLISAGXISAGTJSAIBJSASNJSAIVKQAEDKQALPKQAERKGAMFLRALRLRAEHMQAMTMQATNMQAMJNQAUPNQAVMNGAv|KASAWMBSAJGBSAXSBSAJOCSAFICSAGUCSAFQDSAFKDSAGWDSAFXDGAwSESADMESAEYESAYCFSALOFSAEIFSAEEGSAKQGSAIKGSAISGGAMGHSAMSHSAGAHSAZMHSAGIISAKUISAICISAKOISAIWJSAEEJSALQJSAENJGAMGKQALSKQAEILQAKULQAIKMQAMIMGANMNQAa|NASAQPBSAJJBSAIRCSAFLCSAGTCGAGTDSAJNDSAIVESADDESAEPESAEXFSADFFSAERFSAEOFGAMHGSAGTGSAGBGSAMNGSAGJHSAGVHSAGDHSAMPHSAGLISAIXISAIFISAKRISAIJIGANNJSAEHJSALTJSAEJKQAKVKQAIDKQAKLLQAMFLQAMELGANNMQAMHMQAMPNQAcJNQAd|QASAAKASABGBSATSBSAFMBSAFPBGAGICSAIUCSAJOCSAJWDSADEDSAEQDSADYESAYGESAESESADKEGAMIFSAIUFSAJCFSAKKGSAGWGSAFEGSAMMHSAIYHSAJGHSAKSHSAIFHGANOISAEIISALUISAEQJSAEKJSALWJSAESKQAIMKQAKOLQAMILQAMQMQAKKMQAKMNQAe|NASAfLAGAxJBSAGPBSAFLCSAIFCSAIRCSAJNDSAEHDSAETDSADGDGAMJESAIVESAJDESAILFSAGXFSAFFFSAGBGSAMNGSAGZGSAgHGSAGBGGANDHTALPHTAEJHTAERISAELISAEXISAETJSAIBJSASNJSAIWJGAMVKQAGDKQAMPKQAGFLQAKRLQAIHMQALTMQACNMQALRMGANJNQAdPNQAc|KASAhMBSAJGBSAXSBSAJOCSADICSAEUCSADQDSADKDSAEWDSADSESAJMESAIYESAiCFSAMOFSAGIFSAGXFGAGEGSAKQGSAIKGSAIGHTALSHTAEAHTAjMHTAEIISALUISAECISALOISAESIGAMWJSAGEJSAMQJSAGGKQAMSKQAGILQAKULQAINLGANKMQALMNQAa|NASAfPBSADJBSAERCSADLCSAETDSAJNDSAIVESAFDESAGPESAGTEGAGXFSAJFFSAIRFSAIHGSAETGSAEBGSALNGSAEJHTAEVHTAEDHTALPHTAEOHGAMLISAIXISAIFISAKRISAINJSAGHJSAMTJSAGJKQAKVKQAIDKQAKJKGANLLRALFLRALNMQALHMQALPNQAlJNQAm|QASAAKASABGBSACSBSADMBSADICSAEUCSADOCSADWDSAFEDSAGQDSAFPDGAMYESAHGESAGSESAFIFSAIUFSAJCFSAKKGSAEWGSADEGSALKGGAMMHSAIYHSAJGHSAKSHSAIOISAGIISAMUISAGQJSAGKJSAMWJSAGFJGANSKQAEMKQALOLRALILRALQMQAKKMQAKMNQAP|NASAQJBSAEPBSADLCSAIFCSAIRCSAJLCGAMNDSAGHDSAGTDSAFJESAIVESAJDESAILFSAEXFSADFFSAEGFGAMBGSALNGSAEZGSARHGSAEDHSAKPHSAIJHSAIRISAGLISAGXISAGBIGANTJSAIBJSASNJSAIVKQAEDKQALPKQAEFLRALRLRAEWLGAyHMQAMTMQATNMQAMJNQAUPNQAV|KASAWMBSAJGBSAXSBSAJHBGAMOCSAFICSAGUCSAFQDSAFKDSAGWDSAFSESADMESAEYESAYCEGANCFSALOFSAEIFSAEEGSAKQGSAIKGSAIGHSAMSHSAGAHSAZMHSAGXHGAMIISAKUISAICISAKOISAIWJSAEEJSALQJSAEGKQALSKQAESKGAMILQAKULQAIKMQAMMNQAaNNGAv|NASAQPBSAJJBSAIRCSAFLCSAGTDSAJNDSAIVESADDESAEPESAEXFSADFFSAERFSAEHGSAGTGSAGBGSAMNGSAGTGGAMJHSAGVHSAGDHSAMPHSAGLISAIXISAIFISAKRISAINJSAEHJSALTJSAEOJGAMJKQAKVKQAIDKQAKLLQAMFLQAMNMQAMHMQAMJMGANPNQAcJNQAd|QASAAKASABGBSATSBSAFMBSAFICSAIUCSAJOCSAJUCGAGWDSADEDSAEQDSADYESAYGESAESESADIFSAIUFSAJCFSAKPFGAMKGSAGWGSAFEGSAMMHSAIYHSAJGHSAKSHSAIOISAEIISALUISAEKIGANQJSAEKJSALWJSAESKQAIMKQAKOLQAMILQAMFLGANQMQAKKMQAKMNQAe|NASAfJBSAGPBSAFQBGAGLCSAIFCSAIRCSAJNDSAEHDSAETDSADJESAIVESAJDESAILEGAMLFSAGXFSAFFFSAGBGSAMNGSAGZGSAgHGSAGDHTALPHTAEJHTAEGHGANRISAELISAEXISAETJSAIBJSASNJSAIVKQAGDKQAMPKQAGFLQAKRLQAIHMQALTMQACNMQALJNQAdPNQAc|KASAhMAGAHMBSAJGBSAXSBSAJOCSADICSAEUCSADQDSADKDSAEWDSADHDGAMSESAJMESAIYESAiCFSAMOFSAGIFSAGEGSAKQGSAIKGSAICGGANGHTALSHTAEAHTAjMHTAEIISALUISAECISALOISAEWJSAGEJSAMQJSAGXJGAMGKQAMSKQAGILQAKULQAIKMQALSMGAMMNQAa|NASAfPBSADJBSAERCSADLCSAEDCGAyTDSAJNDSAIVESAFDESAGPESAGXFSAJFFSAIRFSAIYFGAGHGSAETGSAEBGSALNGSAEJHTAEVHTAEDHTALPHTAELISAIXISAIFISAKRISAITIGAMNJSAGHJSAMTJSAGJKQAKVKQAIDKQAKLLRALFLRALOLGANNMQALHMQALPNQAlJNQAm|QASAAKASABGBSACSBSADMBSADICSAEUCSADOCSADWDSAFEDSAGQDSAFYESAHGESAGSESAFUEGAGIFSAIUFSAJCFSAKKGSAEWGSADEGSALMHSAIYHSAJGHSAKSHSAIPHGAMOISAGIISAMUISAGQJSAGKJSAMWJSAGSKQAEMKQALKKGANOLRALILRALQMQAKKMQAKMNQAP|NASAQJBSAEPBSADLCSAIFCSAIRCSAJNDSAGHDSAGTDSAFQDGAGJESAIVESAJDESAILFSAEXFSADFFSAEBGSALNGSAEZGSARHGSAELGGAMDHSAKPHSAIJHSAIRISAGLISAGXISAGTJSAIBJSASNJSAIGJGANVKQAEDKQALPKQAEFLRALRLRAEHMQAMTMQATNMQAMJNQAUPNQAV|KASAWMBSAJGBSAXSBSAJOCSAFICSAGUCSAFMCGAMQDSAFKDSAGWDSAFSESADMESAEYESAYCFSALOFSAEIFSAEHFGAMEGSAKQGSAIKGSAIGHSAMSHSAGAHSAZMHSAGIISAKUISAICISAKOISAICIGANWJSAEEJSALQJSAEGKQALSKQAEILQAKULQAIKMQAMMNQAa|NASAQPBSAJJBSAIIBGAMRCSAFLCSAGTDSAJNDSAIVESADDESAEPESAEDEGAMXFSADFFSAERFSAEHGSAGTGSAGBGSAMNGSAGJHSAGVHSAGDHSAMPHSAGYHGAGLISAIXISAIFISAKRISAINJSAEHJSALTJSAEJKQAKVKQAIDKQAKTKGAMLLQAMFLQAMNMQAMHMQAMPNQAcJNQAdONGAo|QASAAKASABGBSATSBSAFMBSAFICSAIUCSAJOCSAJWDSADEDSAEQDSADYESAYGESAESESADIFSAIUFSAJCFSAKKGSAGWGSAFEGSAMUGGAMMHSAIYHSAJGHSAKSHSAIOISAEIISALUISAEQJSAEKJSALWJSAEPJGAMSKQAIMKQAKOLQAMILQAMQMQAKKMQAKKMGANMNQAe|NASAfJBSAGPBSAFLCSAIFCSAIRCSAJVCGAGNDSAEHDSAETDSADJESAIVESAJDESAILFSAGXFSAFFFSAGQFGAMBGSAMNGSAGZGSAgHGSAGDHTALPHTAEJHTAERISAELISAEXISAELIGAMTJSAIBJSASNJSAIVKQAGDKQAMPKQAGFLQAKRLQAIGLGANHMQALTMQACNMQALJNQAdPNQAc|KASAhMBSAJGBSAXSBSAJRBGAGOCSADICSAEUCSADQDSADKDSAEWDSADSESAJMESAIYESAiMEGAMCFSAMOFSAGIFSAGEGSAKQGSAIKGSAIGHTALSHTAEAHTAjMHTAEHHGANIISALUISAECISALOISAEWJSAGEJSAMQJSAGGKQAMSKQAGCKGAzILQAKULQAIKMQALMNQAa|NASAfNAGAHPBSADJBSAERCSADLCSAETDSAJNDSAIIDGAMVESAFDESAGPESAGXFSAJFFSAIRFSAIHGSAETGSAEBGSALNGSAEDGGANJHTAEVHTAEDHTALPHTAELISAIXISAIFISAKRISAINJSAGHJSAMTJSAGYJGA0JKQAKVKQAIDKQAKLLRALFLRALNMQALHMQALTMGAtPNQAlJNQAm|QASAAKASABGBSACSBSADMBSADICSAEUCSADOCSADECGAMWDSAFEDSAGQDSAFYESAHGESAGSESAFIFSAIUFSAJCFSAKZFGA1KGSAEWGSADEGSALMHSAIYHSAJGHSAKSHSAIOISAGIISAMUISAGUIGAMQJSAGKJSAMWJSAGSKQAEMKQALOLRALILRALPLGANQMQAKKMQAKMNQAP|NASAQJBSAEPBSADLCSAIFCSAIRCSAJNDSAGHDSAGTDSAFJESAIVESAJDESAIVEGAGLFSAEXFSADFFSAEBGSALNGSAEZGSARHGSAEDHSAKPHSAIJHSAIQHGAMRISAGLISAGXISAGTJSAIBJSASNJSAIVKQAEDKQALPKQAELKGANFLRALRLRAEHMQAMTMQATNMQAMJNQAUPNQAV|KASAWMBSAJGBSAXSBSAJOCSAFICSAGUCSAFQDSAFKDSAGWDSAFRDGAGSESADMESAEYESAYCFSALOFSAEIFSAEEGSAKQGSAIKGSAIMGGAMGHSAMSHSAGAHSAZMHSAGIISAKUISAICISAKOISAIWJSAEEJSALQJSAEHJGANGKQALSKQAEILQAKULQAIKMQAMMNQAa|NASAQPBSAJJBSAIRCSAFLCSAGNCGAMTDSAJNDSAIVESADDESAEPESAEXFSADFFSAERFSAEIFGAMHGSAGTGSAGBGSAMNGSAGJHSAGVHSAGDHSAMPHSAGLISAIXISAIFISAKRISAIDIGANNJSAEHJSALTJSAEJKQAKVKQAIDKQAKLLQAMFLQAMNMQAMHMQAMPNQAcJNQAd|QASAAKASABGBSATSBSAFMBSAFJBGAMICSAIUCSAJOCSAJWDSADEDSAEQDSADYESAYGESAESESADEEGAMIFSAIUFSAJCFSAKKGSAGWGSAFEGSAMMHSAIYHSAJGHSAKSHSAIZHGAbOISAEIISALUISAEQJSAEKJSALWJSAESKQAIMKQAKUKGAMOLQAMILQAMQMQAKKMQAKMNQAePNGA2|NASAfJBSAGPBSAFLCSAIFCSAIRCSAJNDSAEHDSAETDSADJESAIVESAJDESAILFSAGXFSAFFFSAGBGSAMNGSAGZGSAgHGSAGVGGAMDHTALPHTAEJHTAERISAELISAEXISAETJSAIBJSASNJSAIQJGAMVKQAGDKQAMPKQAGFLQAKRLQAIHMQALTMQACNMQALLMGANJNQAdPNQAc|KASAhMBSAJGBSAXSBSAJOCSADICSAEUCSADWCGA3QDSADKDSAEWDSADSESAJMESAIYESAiCFSAMOFSAGIFSAGRFGAMEGSAKQGSAIKGSAIGHTALSHTAEAHTAjMHTAEIISALUISAECISALOISAEMIGAMWJSAGEJSAMQJSAGGKQAMSKQAGILQAKULQAIHLGANKMQALMNQAa|NASAfPBSADJBSAESBGAGRCSADLCSAETDSAJNDSAIVESAFDESAGPESAGNEGAMXFSAJFFSAIRFSAIHGSAETGSAEBGSALNGSAEJHTAEVHTAEDHTALPHTAEIHGANLISAIXISAIFISAKRISAINJSAGHJSAMTJSAGJKQAKVKQAIDKQAKDKGANLLRALFLRALNMQALHMQALPNQAlJNQAm'
VN_AL[sand]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[sand]='846c44a488547c6034a88448846838e8d0a0b8a47cb0a078a08454c8a8687c644064502c8c8060685c48605844887c5ca480447058305c4c30b09c745c543c70684c886c38987c5080643460584078603c7c705450402440341c604c28e0c89c9c8c6cbca88098805044341c444030645034504028504c386054403c3828948464443c30342c2484785c504434645844948060a89870544c385048386c60485c503c544838706048'
VN_AF[blossom]='AGWAAEHJABEEOACGKOADHBYAEGHYABICXAEJIXADKFIACLLIADNEOACNKOADPDZACOJZAFRCWAGQIWAFTBIAHSHIACUGPACWFYAIYEWAJ|AGYAADHXABEEIACFKIADHBOAEHHOABJCZACIIZADLFWACKLWADNEIACMKIADQDPAIOJPAFSCYAIQIYAFUBWAKSHWACUGJACWFOAIYEYAJZGZAL|BHOABDCZAMCIZADFFWACELWADGCIAEHIIADKDPACIJPADKAYANMGYACKMYADOFWACMLWADQEJACOKJAFSDOAIQJOAFTCYAGSIYAFUHXACWGIAIZFOAOZGPAL|BHIABECPACCIPADGFYACELYADGCWACIIWADKDJACIJJADKAOANMGOACKMOADNFYACMLYADPEXACOKXAFRDIAIQJIAFTCOAITIOAFUBZAKVHZACXGWAIZFIAOZHJAL|CIWADEDJACCJJADGGOABGDYACHJYADJEXACIKXADKBIAELHIACKNIAPNAOAHNGOACNMOADOFZACPLZADQEWACRKWAFSDIAITJIAFUCPAGWIPAFYHYAIZHXAL|BIYADDDXACCJXADFGIABHDOACHJOADIEZACJKZADLBWAEKHWACLNWAQNAIAHMGIACNMIADOFPACQLPAFQEYACSKYAFSDWAIUJWAFUCJAIWIJAFYHOAIZGYAL|BJOARCEZABDKZADFBWASEHWABHEIACGKIADIFPACKLPADMCYAEKIYADOBWAGMHWACONWATQAJAUOGJACQMJADQFOACSLOAFSEYAITKYAFUDXAIVJXAFWCIAVXIIAFZHOAL|CEPABEKPADGBYAWEHYABIEWACGKWADIFJACKLJADMCOACKIOADNBYAGMHYACNNYAXPAXANOGXACPMXADQFIACRLIAFTEOAITKOAFVDZAIUJZAFWIWAFYHIAI|CEWABCFJABELJADGCOAEEIOADHFYACGLYADJAXAYIGXACJMXADLDIACKJIADNCOAENIOAFOBZAGPHZACONZATQAWAURGWACQMWADTFIACSLIAFWEPAIUKPAFWJYAFYIWAF|BEYAZCFXABDLXAaFCIACEIIADHFOACHLOADIAZAbJGZACIMZADKDWACLJWADMCIACNIIAFOBPAGQHPACONPAQQAYAUSGYACQMYADUFWAISLWAFWEJAIUKJAFWJOAFYIYAF|BFOABDGZABEDWACFJWADGGIABHMIADIBPAEKHPACINPAcKEYACMKYADMDWACOJWAFOCJAGQIJAFQBOAGSHOACQNOAdTGYACSMYAFVFXAIULXAFXEIAIWKIAF|AFIAeEGPABEDYACGJYADIAWAbGGWABIMWADIBJAEKHJACINJAfKEOACMKOADMDYACNJYAFOCXAIPIXAFQBIAGRHIACQNIAgTGOACTMOAhUFZAIVLZAFWEWAIXKWAi|AGWAAEHJABEEOACGKOADHBYAEGHYABICXAEJIXADKFIACLLIADNEOACNKOADPDZACOJZAFRCWAGQIWAFTBIAHSHIACUGPACWFYAIYEWAJ|AGYAADHXABEEIACFKIADHBOAEHHOABJCZACIIZADLFWACKLWADNEIACMKIADQDPAIOJPAFSCYAIQIYAFUBWAKSHWACUGJACWFOAIYEYAJZGZAL|BHOABDCZAMCIZADFFWACELWADGCIAEHIIADKDPACIJPADKAYANMGYACKMYADOFWACMLWADQEJACOKJAFSDOAIQJOAFTCYAGSIYAFUHXACWGIAIZFOAOZGPAL|BHIABECPACCIPADGFYACELYADGCWACIIWADKDJACIJJADKAOANMGOACKMOADNFYACMLYADPEXACOKXAFRDIAIQJIAFTCOAITIOAFUBZAKVHZACXGWAIZFIAOZHJAL|CIWADEDJACCJJADGGOABGDYACHJYADJEXACIKXADKBIAELHIACKNIAPNAOAHNGOACNMOADOFZACPLZADQEWACRKWAFSDIAITJIAFUCPAGWIPAFYHYAIZHXAL|BIYADDDXACCJXADFGIABHDOACHJOADIEZACJKZADLBWAEKHWACLNWAQNAIAHMGIACNMIADOFPACQLPAFQEYACSKYAFSDWAIUJWAFUCJAIWIJAFYHOAIZGYAL|BJOARCEZABDKZADFBWASEHWABHEIACGKIADIFPACKLPADMCYAEKIYADOBWAGMHWACONWATQAJAUOGJACQMJADQFOACSLOAFSEYAITKYAFUDXAIVJXAFWCIAVXIIAFZHOAL|CEPABEKPADGBYAWEHYABIEWACGKWADIFJACKLJADMCOACKIOADNBYAGMHYACNNYAXPAXANOGXACPMXADQFIACRLIAFTEOAITKOAFVDZAIUJZAFWIWAFYHIAI|CEWABCFJABELJADGCOAEEIOADHFYACGLYADJAXAYIGXACJMXADLDIACKJIADNCOAENIOAFOBZAGPHZACONZATQAWAURGWACQMWADTFIACSLIAFWEPAIUKPAFWJYAFYIWAF|BEYAZCFXABDLXAaFCIACEIIADHFOACHLOADIAZAbJGZACIMZADKDWACLJWADMCIACNIIAFOBPAGQHPACONPAQQAYAUSGYACQMYADUFWAISLWAFWEJAIUKJAFWJOAFYIYAF|BFOABDGZABEDWACFJWADGGIABHMIADIBPAEKHPACINPAcKEYACMKYADMDWACOJWAFOCJAGQIJAFQBOAGSHOACQNOAdTGYACSMYAFVFXAIULXAFXEIAIWKIAF|AFIAeEGPABEDYACGJYADIAWAbGGWABIMWADIBJAEKHJACINJAfKEOACMKOADMDYACNJYAFOCXAIPIXAFQBIAGRHIACQNIAgTGOACTMOAhUFZAIVLZAFWEWAIXKWAi|AGWAAEHJABEEOACGKOADHBYAEGHYABICXAEJIXADKFIACLLIADNEOACNKOADPDZACOJZAFRCWAGQIWAFTBIAHSHIACUGPACWFYAIYEWAJ|AGYAADHXABEEIACFKIADHBOAEHHOABJCZACIIZADLFWACKLWADNEIACMKIADQDPAIOJPAFSCYAIQIYAFUBWAKSHWACUGJACWFOAIYEYAJZGZAL|BHOABDCZAMCIZADFFWACELWADGCIAEHIIADKDPACIJPADKAYANMGYACKMYADOFWACMLWADQEJACOKJAFSDOAIQJOAFTCYAGSIYAFUHXACWGIAIZFOAOZGPAL|BHIABECPACCIPADGFYACELYADGCWACIIWADKDJACIJJADKAOANMGOACKMOADNFYACMLYADPEXACOKXAFRDIAIQJIAFTCOAITIOAFUBZAKVHZACXGWAIZFIAOZHJAL|CIWADEDJACCJJADGGOABGDYACHJYADJEXACIKXADKBIAELHIACKNIAPNAOAHNGOACNMOADOFZACPLZADQEWACRKWAFSDIAITJIAFUCPAGWIPAFYHYAIZHXAL|BIYADDDXACCJXADFGIABHDOACHJOADIEZACJKZADLBWAEKHWACLNWAQNAIAHMGIACNMIADOFPACQLPAFQEYACSKYAFSDWAIUJWAFUCJAIWIJAFYHOAIZGYAL|BJOARCEZABDKZADFBWASEHWABHEIACGKIADIFPACKLPADMCYAEKIYADOBWAGMHWACONWATQAJAUOGJACQMJADQFOACSLOAFSEYAITKYAFUDXAIVJXAFWCIAVXIIAFZHOAL|CEPABEKPADGBYAWEHYABIEWACGKWADIFJACKLJADMCOACKIOADNBYAGMHYACNNYAXPAXANOGXACPMXADQFIACRLIAFTEOAITKOAFVDZAIUJZAFWIWAFYHIAI|CEWABCFJABELJADGCOAEEIOADHFYACGLYADJAXAYIGXACJMXADLDIACKJIADNCOAENIOAFOBZAGPHZACONZATQAWAURGWACQMWADTFIACSLIAFWEPAIUKPAFWJYAFYIWAF|BEYAZCFXABDLXAaFCIACEIIADHFOACHLOADIAZAbJGZACIMZADKDWACLJWADMCIACNIIAFOBPAGQHPACONPAQQAYAUSGYACQMYADUFWAISLWAFWEJAIUKJAFWJOAFYIYAF|BFOABDGZABEDWACFJWADGGIABHMIADIBPAEKHPACINPAcKEYACMKYADMDWACOJWAFOCJAGQIJAFQBOAGSHOACQNOAdTGYACSMYAFVFXAIULXAFXEIAIWKIAF|AFIAeEGPABEDYACGJYADIAWAbGGWABIMWADIBJAEKHJACINJAfKEOACMKOADMDYACNJYAFOCXAIPIXAFQBIAGRHIACQNIAgTGOACTMOAhUFZAIVLZAFWEWAIXKWAi|AGWAAEHJABEEOACGKOADHBYAEGHYABICXAEJIXADKFIACLLIADNEOACNKOADPDZACOJZAFRCWAGQIWAFTBIAHSHIACUGPACWFYAIYEWAJ|AGYAADHXABEEIACFKIADHBOAEHHOABJCZACIIZADLFWACKLWADNEIACMKIADQDPAIOJPAFSCYAIQIYAFUBWAKSHWACUGJACWFOAIYEYAJZGZAL|BHOABDCZAMCIZADFFWACELWADGCIAEHIIADKDPACIJPADKAYANMGYACKMYADOFWACMLWADQEJACOKJAFSDOAIQJOAFTCYAGSIYAFUHXACWGIAIZFOAOZGPAL|BHIABECPACCIPADGFYACELYADGCWACIIWADKDJACIJJADKAOANMGOACKMOADNFYACMLYADPEXACOKXAFRDIAIQJIAFTCOAITIOAFUBZAKVHZACXGWAIZFIAOZHJAL|CIWADEDJACCJJADGGOABGDYACHJYADJEXACIKXADKBIAELHIACKNIAPNAOAHNGOACNMOADOFZACPLZADQEWACRKWAFSDIAITJIAFUCPAGWIPAFYHYAIZHXAL|BIYADDDXACCJXADFGIABHDOACHJOADIEZACJKZADLBWAEKHWACLNWAQNAIAHMGIACNMIADOFPACQLPAFQEYACSKYAFSDWAIUJWAFUCJAIWIJAFYHOAIZGYAL|BJOARCEZABDKZADFBWASEHWABHEIACGKIADIFPACKLPADMCYAEKIYADOBWAGMHWACONWATQAJAUOGJACQMJADQFOACSLOAFSEYAITKYAFUDXAIVJXAFWCIAVXIIAFZHOAL|CEPABEKPADGBYAWEHYABIEWACGKWADIFJACKLJADMCOACKIOADNBYAGMHYACNNYAXPAXANOGXACPMXADQFIACRLIAFTEOAITKOAFVDZAIUJZAFWIWAFYHIAI|CEWABCFJABELJADGCOAEEIOADHFYACGLYADJAXAYIGXACJMXADLDIACKJIADNCOAENIOAFOBZAGPHZACONZATQAWAURGWACQMWADTFIACSLIAFWEPAIUKPAFWJYAFYIWAF|BEYAZCFXABDLXAaFCIACEIIADHFOACHLOADIAZAbJGZACIMZADKDWACLJWADMCIACNIIAFOBPAGQHPACONPAQQAYAUSGYACQMYADUFWAISLWAFWEJAIUKJAFWJOAFYIYAF|BFOABDGZABEDWACFJWADGGIABHMIADIBPAEKHPACINPAcKEYACMKYADMDWACOJWAFOCJAGQIJAFQBOAGSHOACQNOAdTGYACSMYAFVFXAIULXAFXEIAIWKIAF|AFIAeEGPABEDYACGJYADIAWAbGGWABIMWADIBJAEKHJACINJAfKEOACMKOADMDYACNJYAFOCXAIPIXAFQBIAGRHIACQNIAgTGOACTMOAhUFZAIVLZAFWEWAIXKWAi'
VN_AL[blossom]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[blossom]='4c343c704c5c9c6c7c703c4c9c848c9c506cc8acb8c0a4b0c88ca0986c7874646c88606c5c5054a48c9464445058303c502c38542c385c4c50683444847078786870947c84542c3c64545c54384444242c44383c30182048243038242c24141c381c28944c647c4054'
VN_AF[sunbeams]='QASAARASABPBSACQBSACRBQADSBQADTBSAEUBSAFDCSAGOCSAHPCSAIQCQACRCQAJSCSADTCSAKCDSALNDSAMODSANPDQAHQDQAIRDSACSDSACBESAOMESAMNESAMOEQAMPEQAPQESAHRESAHAFSAQLFSAMMFSAMNFQAMOFQAMPFSAMQFSAMKGSARLGSAMMGQAMNGQAMOGSAMPGSAMJHSARKHSARLHQARMHQAMNHSAMOHSAMZHSASIISARJISARKIQARLIQARMISARNISAMYISATZISAUHJSARIJSARJJQARKJQARLJSARMJSARXJSATYJSAVGKSAWHKSARIKQARJKQARKKSARLKSARWKSAMXKSAXFLSAWGLSAWHLQAWILQARJLSARKLSARVLSAMWLSAYFMSAZGMQAaHMQAWIMSAWJMSARUMSAbINSAc|QASAARASABPBSACQBSACRBQADSBQADTBSAEUBSAFDCSAGOCSAHPCSAIQCQACRCQAJSCSADTCSAKCDSALNDSAMODSANPDQAHQDQAIRDSACSDSACBESAOMESAMNESAMOEQAMPEQAPQESAHRESAHAFSAQLFSAMMFSAMNFQAMOFQAMPFSAMQFSAMKGSARLGSAMMGQAMNGQAMOGSAMPGSAMJHSARKHSARLHQARMHQAMNHSAMOHSAMZHSASIISARJISARKIQARLIQARMISARNISAMYISATZISAUHJSARIJSARJJQARKJQARLJSARMJSARXJSATYJSAVGKSAWHKSARIKQARJKQARKKSARLKSARWKSAMXKSAXFLSAWGLSAWHLQAWILQARJLSARKLSARVLSAMWLSAYFMSAZGMQAaHMQAWIMSAWJMSARUMSAbINSAc|QASAARASABPBSACQBSACRBQADSBQADTBSAEUBSAFDCSAGOCSAHPCSAIQCQACRCQAJSCSADTCSAKCDSALNDSAMODSANPDQAHQDQAIRDSACSDSACBESAOMESAMNESAMOEQAMPEQAPQESAHRESAHAFSAQLFSAMMFSAMNFQAMOFQAMPFSAMQFSAMKGSARLGSAMMGQAMNGQAMOGSAMPGSAMJHSARKHSARLHQARMHQAMNHSAMOHSAMZHSASIISARJISARKIQARLIQARMISARNISAMYISATZISAUHJSARIJSARJJQARKJQARLJSARMJSARXJSATYJSAVGKSAWHKSARIKQARJKQARKKSARLKSARWKSAMXKSAXFLSAWGLSAWHLQAWILQARJLSARKLSARVLSAMWLSAYFMSAZGMQAaHMQAWIMSAWJMSARUMSAbINSAc|PASAeQASAARAQABOBSAHPBSACQBQACRBQADSBSADTBSAENCSAPOCSAHPCQAIQCQACRCSAJSCSADMDSAMNDSAMODQANPDQAHQDSAIRDSACLESAMMESAMNEQAMOEQAMPESAPQESAHKFSAMLFSAMMFQAMNFQAMOFSAMPFSAMJGSARKGSARLGQAMMGQAMNGSAMOGSAMZGSASIHSARJHSARKHQARLHQARMHSAMNHSAMYHSATZHSASHISARIISARJIQARKIQARLISARMISARXISATYISATZIQAUGJSARHJSARIJQARJJQARKJSARLJSARWJSAMXJSATYJQAVFKSAWGKSAWHKQARIKQARJKSARKKSARVKSAMWKSAMXKQAXELSAWFLSAWGLQAWHLQAWILSARJLSARULSAMVLSAMWLQAYFMQAZGMQAaHMSAWIMSAWTMSAfUMSAb|PASAeQASAARAQABOBSAHPBSACQBQACRBQADSBSADTBSAENCSAPOCSAHPCQAIQCQACRCSAJSCSADMDSAMNDSAMODQANPDQAHQDSAIRDSACLESAMMESAMNEQAMOEQAMPESAPQESAHKFSAMLFSAMMFQAMNFQAMOFSAMPFSAMJGSARKGSARLGQAMMGQAMNGSAMOGSAMZGSASIHSARJHSARKHQARLHQARMHSAMNHSAMYHSATZHSASHISARIISARJIQARKIQARLISARMISARXISATYISATZIQAUGJSARHJSARIJQARJJQARKJSARLJSARWJSAMXJSATYJQAVFKSAWGKSAWHKQARIKQARJKSARKKSARVKSAMWKSAMXKQAXELSAWFLSAWGLQAWHLQAWILSARJLSARULSAMVLSAMWLQAYFMQAZGMQAaHMSAWIMSAWTMSAfUMSAb|PASAeQASAARAQABOBSAHPBSACQBQACRBQADSBSADTBSAENCSAPOCSAHPCQAIQCQACRCSAJSCSADMDSAMNDSAMODQANPDQAHQDSAIRDSACLESAMMESAMNEQAMOEQAMPESAPQESAHKFSAMLFSAMMFQAMNFQAMOFSAMPFSAMJGSARKGSARLGQAMMGQAMNGSAMOGSAMZGSASIHSARJHSARKHQARLHQARMHSAMNHSAMYHSATZHSASHISARIISARJIQARKIQARLISARMISARXISATYISATZIQAUGJSARHJSARIJQARJJQARKJSARLJSARWJSAMXJSATYJQAVFKSAWGKSAWHKQARIKQARJKSARKKSARVKSAMWKSAMXKQAXELSAWFLSAWGLQAWHLQAWILSARJLSARULSAMVLSAMWLQAYFMQAZGMQAaHMSAWIMSAWTMSAfUMSAb|OASAgPASAeQAQAARAQABNBSAHOBSAHPBQACQBQACRBSADSBSADMCSAMNCSAPOCQAHPCQAIQCSACRCSAJLDSAMMDSAMNDQAMODQANPDSAHQDSAIKESAMLESAMMEQAMNEQAMOESAMPESAPJFSARKFSAMLFQAMMFQAMNFSAMOFSAMZFSAhIGSARJGSARKGQARLGQAMMGSAMNGSAMYGSAiZGSASHHSARIHSARJHQARKHQARLHSARMHSAMXHSATYHSATZHQASGISARHISARIIQARJIQARKISARLISARWISATXISATYIQATZIQAUFJSAWGJSARHJQARIJQARJJSARKJSARVJSAMWJSAMXJQATYJQAVEKSAWFKSAWGKQAWHKQARIKSARJKSARUKSAMVKSAMWKQAMXKQAXDLSAjELSAWFLQAWGLQAWHLSAWILSARTLSAMULSAMVLQAMWLQAYFMQAZGMSAaHMSAWSMSAMTMSAfUMQAbRNSAk|OASAgPASAeQAQAARAQABNBSAHOBSAHPBQACQBQACRBSADSBSADMCSAMNCSAPOCQAHPCQAIQCSACRCSAJLDSAMMDSAMNDQAMODQANPDSAHQDSAIKESAMLESAMMEQAMNEQAMOESAMPESAPJFSARKFSAMLFQAMMFQAMNFSAMOFSAMZFSAhIGSARJGSARKGQARLGQAMMGSAMNGSAMYGSAiZGSASHHSARIHSARJHQARKHQARLHSARMHSAMXHSATYHSATZHQASGISARHISARIIQARJIQARKISARLISARWISATXISATYIQATZIQAUFJSAWGJSARHJQARIJQARJJSARKJSARVJSAMWJSAMXJQATYJQAVEKSAWFKSAWGKQAWHKQARIKSARJKSARUKSAMVKSAMWKQAMXKQAXDLSAjELSAWFLQAWGLQAWHLSAWILSARTLSAMULSAMVLQAMWLQAYFMQAZGMSAaHMSAWSMSAMTMSAfUMQAbRNSAk|OASAgPASAeQAQAARAQABNBSAHOBSAHPBQACQBQACRBSADSBSADMCSAMNCSAPOCQAHPCQAIQCSACRCSAJLDSAMMDSAMNDQAMODQANPDSAHQDSAIKESAMLESAMMEQAMNEQAMOESAMPESAPJFSARKFSAMLFQAMMFQAMNFSAMOFSAMZFSAhIGSARJGSARKGQARLGQAMMGSAMNGSAMYGSAiZGSASHHSARIHSARJHQARKHQARLHSARMHSAMXHSATYHSATZHQASGISARHISARIIQARJIQARKISARLISARWISATXISATYIQATZIQAUFJSAWGJSARHJQARIJQARJJSARKJSARVJSAMWJSAMXJQATYJQAVEKSAWFKSAWGKQAWHKQARIKSARJKSARUKSAMVKSAMWKQAMXKQAXDLSAjELSAWFLQAWGLQAWHLSAWILSARTLSAMULSAMVLQAMWLQAYFMQAZGMSAaHMSAWSMSAMTMSAfUMQAbRNSAk|NASAlOASAgPAQAeQAQAARASABMBSAPNBSAHOBQAHPBQACQBSACRBSADLCSAMMCSAMNCQAPOCQAHPCSAIQCSACKDSAMLDSAMMDQAMNDQAMODSANPDSAHJESAMKESAMLEQAMMEQAMNESAMOESAMIFSARJFSARKFQAMLFQAMMFSAMNFSAMYFSACZFSAhHGSARIGSARJGQARKGQARLGSAMMGSAMXGSAiYGSAiZGQASGHSARHHSARIHQARJHQARKHSARLHSARWHSATXHSATYHQATZHQASFISARGISARHIQARIIQARJISARKISARVISAMWISATXIQATYIQATZISAUEJSAWFJSAWGJQARHJQARIJSARJJSARUJSAMVJSAMWJQAMXJQATYJSAVDKSAWEKSAWFKQAWGKQAWHKSARIKSARTKSAMUKSAMVKQAMWKQAMXKSAXDLSAjELQAWFLQAWGLSAWHLSAWSLSAMTLSAMULQAMVLQAMWLSAYFMSAZGMSAaRMSAMSMSAMTMQAfUMQAbQNSAmRNSAk|NASAlOASAgPAQAeQAQAARASABMBSAPNBSAHOBQAHPBQACQBSACRBSADLCSAMMCSAMNCQAPOCQAHPCSAIQCSACKDSAMLDSAMMDQAMNDQAMODSANPDSAHJESAMKESAMLEQAMMEQAMNESAMOESAMIFSARJFSARKFQAMLFQAMMFSAMNFSAMYFSACZFSAhHGSARIGSARJGQARKGQARLGSAMMGSAMXGSAiYGSAiZGQASGHSARHHSARIHQARJHQARKHSARLHSARWHSATXHSATYHQATZHQASFISARGISARHIQARIIQARJISARKISARVISAMWISATXIQATYIQATZISAUEJSAWFJSAWGJQARHJQARIJSARJJSARUJSAMVJSAMWJQAMXJQATYJSAVDKSAWEKSAWFKQAWGKQAWHKSARIKSARTKSAMUKSAMVKQAMWKQAMXKSAXDLSAjELQAWFLQAWGLSAWHLSAWSLSAMTLSAMULQAMVLQAMWLSAYFMSAZGMSAaRMSAMSMSAMTMQAfUMQAbQNSAmRNSAk|NASAlOASAgPAQAeQAQAARASABMBSAPNBSAHOBQAHPBQACQBSACRBSADLCSAMMCSAMNCQAPOCQAHPCSAIQCSACKDSAMLDSAMMDQAMNDQAMODSANPDSAHJESAMKESAMLEQAMMEQAMNESAMOESAMIFSARJFSARKFQAMLFQAMMFSAMNFSAMYFSACZFSAhHGSARIGSARJGQARKGQARLGSAMMGSAMXGSAiYGSAiZGQASGHSARHHSARIHQARJHQARKHSARLHSARWHSATXHSATYHQATZHQASFISARGISARHIQARIIQARJISARKISARVISAMWISATXIQATYIQATZISAUEJSAWFJSAWGJQARHJQARIJSARJJSARUJSAMVJSAMWJQAMXJQATYJSAVDKSAWEKSAWFKQAWGKQAWHKSARIKSARTKSAMUKSAMVKQAMWKQAMXKSAXDLSAjELQAWFLQAWGLSAWHLSAWSLSAMTLSAMULQAMVLQAMWLSAYFMSAZGMSAaRMSAMSMSAMTMQAfUMQAbQNSAmRNSAk|MASAnNASAlOAQAgPAQAeQASAARASABLBSAMMBSAPNBQAHOBQAHPBSACQBSACKCSAMLCSAMMCQAMNCQAPOCSAHPCSAIJDSAMKDSAMLDQAMMDQAMNDSAMODSANIESARJESAMKEQAMLEQAMMESAMNESAMYESAoHFSARIFSARJFQARKFQAMLFSAMMFSAMXFSACYFSACZFQAhGGSARHGSARIGQARJGQARKGSARLGSAMWGSAiXGSAiYGQAiZGQASFHSARGHSARHHQARIHQARJHSARKHSARVHSATWHSATXHQATYHQATZHSASEISAWFISARGIQARHIQARIISARJISARUISAMVISAMWIQATXIQATYISATZISAUDJSAWEJSAWFJQAWGJQARHJSARIJSARTJSAMUJSAMVJQAMWJQAMXJSATYJSAVCKSApDKSAWEKQAWFKQAWGKSAWHKSARSKSAMTKSAMUKQAMVKQAMWKSAMXKSAXDLQAjELQAWFLSAWGLSAWRLSAMSLSAMTLQAMULQAMVLSAMWLSAYFMSAZQMSARRMSAMSMQAMTMQAfUMSAbPNSAqQNSAmRNQAk|MASAnNASAlOAQAgPAQAeQASAARASABLBSAMMBSAPNBQAHOBQAHPBSACQBSACKCSAMLCSAMMCQAMNCQAPOCSAHPCSAIJDSAMKDSAMLDQAMMDQAMNDSAMODSANIESARJESAMKEQAMLEQAMMESAMNESAMYESAoHFSARIFSARJFQARKFQAMLFSAMMFSAMXFSACYFSACZFQAhGGSARHGSARIGQARJGQARKGSARLGSAMWGSAiXGSAiYGQAiZGQASFHSARGHSARHHQARIHQARJHSARKHSARVHSATWHSATXHQATYHQATZHSASEISAWFISARGIQARHIQARIISARJISARUISAMVISAMWIQATXIQATYISATZISAUDJSAWEJSAWFJQAWGJQARHJSARIJSARTJSAMUJSAMVJQAMWJQAMXJSATYJSAVCKSApDKSAWEKQAWFKQAWGKSAWHKSARSKSAMTKSAMUKQAMVKQAMWKSAMXKSAXDLQAjELQAWFLSAWGLSAWRLSAMSLSAMTLQAMULQAMVLSAMWLSAYFMSAZQMSARRMSAMSMQAMTMQAfUMSAbPNSAqQNSAmRNQAk|MASAnNASAlOAQAgPAQAeQASAARASABLBSAMMBSAPNBQAHOBQAHPBSACQBSACKCSAMLCSAMMCQAMNCQAPOCSAHPCSAIJDSAMKDSAMLDQAMMDQAMNDSAMODSANIESARJESAMKEQAMLEQAMMESAMNESAMYESAoHFSARIFSARJFQARKFQAMLFSAMMFSAMXFSACYFSACZFQAhGGSARHGSARIGQARJGQARKGSARLGSAMWGSAiXGSAiYGQAiZGQASFHSARGHSARHHQARIHQARJHSARKHSARVHSATWHSATXHQATYHQATZHSASEISAWFISARGIQARHIQARIISARJISARUISAMVISAMWIQATXIQATYISATZISAUDJSAWEJSAWFJQAWGJQARHJSARIJSARTJSAMUJSAMVJQAMWJQAMXJSATYJSAVCKSApDKSAWEKQAWFKQAWGKSAWHKSARSKSAMTKSAMUKQAMVKQAMWKSAMXKSAXDLQAjELQAWFLSAWGLSAWRLSAMSLSAMTLQAMULQAMVLSAMWLSAYFMSAZQMSARRMSAMSMQAMTMQAfUMSAbPNSAqQNSAmRNQAk|LASArMASAnNAQAlOAQAgPASAeQASAAKBSAMLBSAMMBQAPNBQAHOBSAHPBSACJCSAMKCSAMLCQAMMCQAMNCSAPOCSAHIDSAMJDSAMKDQAMLDQAMMDSAMNDSAMHESARIESARJEQAMKEQAMLESAMMESAMXESADYESAoGFSARHFSARIFQARJFQARKFSAMLFSAMWFSACXFSACYFQACZFQAhFGSARGGSARHGQARIGQARJGSARKGSARVGSAiWGSAiXGQAiYGQAiZGSASEHSARFHSARGHQARHHQARIHSARJHSARUHSAMVHSATWHQATXHQATYHSATZHSASDISAWEISAWFIQARGIQARHISARIISARTISAMUISAMVIQAMWIQATXISATYISATCJSAWDJSAWEJQAWFJQAWGJSARHJSARSJSAMTJSAMUJQAMVJQAMWJSAMXJSATCKSApDKQAWEKQAWFKSAWGKSAWRKSAMSKSAMTKQAMUKQAMVKSAMWKSAMDLQAjELSAWFLSAWQLSAMRLSAMSLQAMTLQAMULSAMVLSAMPMSARQMSARRMQAMSMQAMTMSAfUMSAbONSAsPNSAqQNQAmRNQAk|LASArMASAnNAQAlOAQAgPASAeQASAAKBSAMLBSAMMBQAPNBQAHOBSAHPBSACJCSAMKCSAMLCQAMMCQAMNCSAPOCSAHIDSAMJDSAMKDQAMLDQAMMDSAMNDSAMHESARIESARJEQAMKEQAMLESAMMESAMXESADYESAoGFSARHFSARIFQARJFQARKFSAMLFSAMWFSACXFSACYFQACZFQAhFGSARGGSARHGQARIGQARJGSARKGSARVGSAiWGSAiXGQAiYGQAiZGSASEHSARFHSARGHQARHHQARIHSARJHSARUHSAMVHSATWHQATXHQATYHSATZHSASDISAWEISAWFIQARGIQARHISARIISARTISAMUISAMVIQAMWIQATXISATYISATCJSAWDJSAWEJQAWFJQAWGJSARHJSARSJSAMTJSAMUJQAMVJQAMWJSAMXJSATCKSApDKQAWEKQAWFKSAWGKSAWRKSAMSKSAMTKQAMUKQAMVKSAMWKSAMDLQAjELSAWFLSAWQLSAMRLSAMSLQAMTLQAMULSAMVLSAMPMSARQMSARRMQAMSMQAMTMSAfUMSAbONSAsPNSAqQNQAmRNQAk|LASArMASAnNAQAlOAQAgPASAeQASAAKBSAMLBSAMMBQAPNBQAHOBSAHPBSACJCSAMKCSAMLCQAMMCQAMNCSAPOCSAHIDSAMJDSAMKDQAMLDQAMMDSAMNDSAMHESARIESARJEQAMKEQAMLESAMMESAMXESADYESAoGFSARHFSARIFQARJFQARKFSAMLFSAMWFSACXFSACYFQACZFQAhFGSARGGSARHGQARIGQARJGSARKGSARVGSAiWGSAiXGQAiYGQAiZGSASEHSARFHSARGHQARHHQARIHSARJHSARUHSAMVHSATWHQATXHQATYHSATZHSASDISAWEISAWFIQARGIQARHISARIISARTISAMUISAMVIQAMWIQATXISATYISATCJSAWDJSAWEJQAWFJQAWGJSARHJSARSJSAMTJSAMUJQAMVJQAMWJSAMXJSATCKSApDKQAWEKQAWFKSAWGKSAWRKSAMSKSAMTKQAMUKQAMVKSAMWKSAMDLQAjELSAWFLSAWQLSAMRLSAMSLQAMTLQAMULSAMVLSAMPMSARQMSARRMQAMSMQAMTMSAfUMSAbONSAsPNSAqQNQAmRNQAk|KASAtLASArMAQAnNAQAlOASAgPASAeJBSAMKBSAMLBQAMMBQAPNBSAHOBSAHICSAMJCSAMKCQAMLCQAMMCSAMNCSAPHDSARIDSAMJDQAMKDQAMLDSAMMDSAMXDSAuGESARHESARIEQARJEQAMKESAMLESAMWESADXESADYEQAoFFSARGFSARHFQARIFQARJFSARKFSAMVFSAvWFSACXFQACYFQACZFSAhEGSARFGSARGGQARHGQARIGSARJGSARUGSAwVGSAiWGQAiXGQAiYGSAiZGSASDHSAWEHSARFHQARGHQARHHSARIHSARTHSAMUHSAMVHQATWHQATXHSATYHSATCISAWDISAWEIQAWFIQARGISARHISARSISAMTISAMUIQAMVIQAMWISATXISATBJSAxCJSAWDJQAWEJQAWFJSAWGJSARRJSAMSJSAMTJQAMUJQAMVJSAMWJSAMCKQApDKQAWEKSAWFKSAWQKSAMRKSAMSKQAMTKQAMUKSAMVKSAMDLSAjELSAWPLSARQLSAMRLQAMSLQAMTLSAMULSAMOMSARPMSARQMQARRMQAMSMSAMTMSAfNNSAyONSAsPNQAqQNQAmRNSAk|KASAtLASArMAQAnNAQAlOASAgPASAeJBSAMKBSAMLBQAMMBQAPNBSAHOBSAHICSAMJCSAMKCQAMLCQAMMCSAMNCSAPHDSARIDSAMJDQAMKDQAMLDSAMMDSAMXDSAuGESARHESARIEQARJEQAMKESAMLESAMWESADXESADYEQAoFFSARGFSARHFQARIFQARJFSARKFSAMVFSAvWFSACXFQACYFQACZFSAhEGSARFGSARGGQARHGQARIGSARJGSARUGSAwVGSAiWGQAiXGQAiYGSAiZGSASDHSAWEHSARFHQARGHQARHHSARIHSARTHSAMUHSAMVHQATWHQATXHSATYHSATCISAWDISAWEIQAWFIQARGISARHISARSISAMTISAMUIQAMVIQAMWISATXISATBJSAxCJSAWDJQAWEJQAWFJSAWGJSARRJSAMSJSAMTJQAMUJQAMVJSAMWJSAMCKQApDKQAWEKSAWFKSAWQKSAMRKSAMSKQAMTKQAMUKSAMVKSAMDLSAjELSAWPLSARQLSAMRLQAMSLQAMTLSAMULSAMOMSARPMSARQMQARRMQAMSMSAMTMSAfNNSAyONSAsPNQAqQNQAmRNSAk|KASAtLASArMAQAnNAQAlOASAgPASAeJBSAMKBSAMLBQAMMBQAPNBSAHOBSAHICSAMJCSAMKCQAMLCQAMMCSAMNCSAPHDSARIDSAMJDQAMKDQAMLDSAMMDSAMXDSAuGESARHESARIEQARJEQAMKESAMLESAMWESADXESADYEQAoFFSARGFSARHFQARIFQARJFSARKFSAMVFSAvWFSACXFQACYFQACZFSAhEGSARFGSARGGQARHGQARIGSARJGSARUGSAwVGSAiWGQAiXGQAiYGSAiZGSASDHSAWEHSARFHQARGHQARHHSARIHSARTHSAMUHSAMVHQATWHQATXHSATYHSATCISAWDISAWEIQAWFIQARGISARHISARSISAMTISAMUIQAMVIQAMWISATXISATBJSAxCJSAWDJQAWEJQAWFJSAWGJSARRJSAMSJSAMTJQAMUJQAMVJSAMWJSAMCKQApDKQAWEKSAWFKSAWQKSAMRKSAMSKQAMTKQAMUKSAMVKSAMDLSAjELSAWPLSARQLSAMRLQAMSLQAMTLSAMULSAMOMSARPMSARQMQARRMQAMSMSAMTMSAfNNSAyONSAsPNQAqQNQAmRNSAk|JASAzKASAtLAQArMAQAnNASAlOASAgIBSAMJBSAMKBQAMLBQAMMBSAPNBSAHHCSAMICSAMJCQAMKCQAMLCSAMMCSAMGDSARHDSARIDQAMJDQAMKDSAMLDSAMWDSA0XDSAuFESARGESARHEQARIEQARJESAMKESAMVESAJWESADXEQADYEQAoEFSARFFSARGFQARHFQARIFSARJFSARUFSAiVFSAvWFQACXFQACYFSACZFSAhDGSAREGSARFGQARGGQARHGSARIGSARTGSAMUGSAwVGQAiWGQAiXGSAiYGSAiCHSAWDHSAWEHQARFHQARGHSARHHSARSHSAMTHSAMUHQAMVHQATWHSATXHSATBISAWCISAWDIQAWEIQAWFISARGISARRISAMSISAMTIQAMUIQAMVISAMWISATBJSAxCJQAWDJQAWEJSAWFJSAWQJSAMRJSAMSJQAMTJQAMUJSAMVJSAMCKQApDKSAWEKSAWPKSAMQKSAMRKQAMSKQAMTKSAMUKSAMDLSAjOLSARPLSARQLQAMRLQAMSLSAMTLSAMNMSAROMSARPMQARQMQARRMSAMSMSAMMNSAyNNSAyONQAsPNQAqQNSAmRNSAk|JASAzKASAtLAQArMAQAnNASAlOASAgIBSAMJBSAMKBQAMLBQAMMBSAPNBSAHHCSAMICSAMJCQAMKCQAMLCSAMMCSAMGDSARHDSARIDQAMJDQAMKDSAMLDSAMWDSA0XDSAuFESARGESARHEQARIEQARJESAMKESAMVESAJWESADXEQADYEQAoEFSARFFSARGFQARHFQARIFSARJFSARUFSAiVFSAvWFQACXFQACYFSACZFSAhDGSAREGSARFGQARGGQARHGSARIGSARTGSAMUGSAwVGQAiWGQAiXGSAiYGSAiCHSAWDHSAWEHQARFHQARGHSARHHSARSHSAMTHSAMUHQAMVHQATWHSATXHSATBISAWCISAWDIQAWEIQAWFISARGISARRISAMSISAMTIQAMUIQAMVISAMWISATBJSAxCJQAWDJQAWEJSAWFJSAWQJSAMRJSAMSJQAMTJQAMUJSAMVJSAMCKQApDKSAWEKSAWPKSAMQKSAMRKQAMSKQAMTKSAMUKSAMDLSAjOLSARPLSARQLQAMRLQAMSLSAMTLSAMNMSAROMSARPMQARQMQARRMSAMSMSAMMNSAyNNSAyONQAsPNQAqQNSAmRNSAk|JASAzKASAtLAQArMAQAnNASAlOASAgIBSAMJBSAMKBQAMLBQAMMBSAPNBSAHHCSAMICSAMJCQAMKCQAMLCSAMMCSAMGDSARHDSARIDQAMJDQAMKDSAMLDSAMWDSA0XDSAuFESARGESARHEQARIEQARJESAMKESAMVESAJWESADXEQADYEQAoEFSARFFSARGFQARHFQARIFSARJFSARUFSAiVFSAvWFQACXFQACYFSACZFSAhDGSAREGSARFGQARGGQARHGSARIGSARTGSAMUGSAwVGQAiWGQAiXGSAiYGSAiCHSAWDHSAWEHQARFHQARGHSARHHSARSHSAMTHSAMUHQAMVHQATWHSATXHSATBISAWCISAWDIQAWEIQAWFISARGISARRISAMSISAMTIQAMUIQAMVISAMWISATBJSAxCJQAWDJQAWEJSAWFJSAWQJSAMRJSAMSJQAMTJQAMUJSAMVJSAMCKQApDKSAWEKSAWPKSAMQKSAMRKQAMSKQAMTKSAMUKSAMDLSAjOLSARPLSARQLQAMRLQAMSLSAMTLSAMNMSAROMSARPMQARQMQARRMSAMSMSAMMNSAyNNSAyONQAsPNQAqQNSAmRNSAk|IASA1JASAzKAQAtLAQArMASAnNASAlHBSAMIBSAMJBQAMKBQAMLBSAMMBSAPGCSARHCSAMICQAMJCQAMKCSAMLCSAMWCSA2FDSARGDSARHDQARIDQAMJDSAMKDSAMVDSAKWDSA0XDQAuEESARFESARGEQARHEQARIESARJESAMUESACVESAJWEQADXEQADYESAoDFSAREFSARFFQARGFQARHFSARIFSARTFSAiUFSAiVFQAvWFQACXFSACYFSACCGSAWDGSAREGQARFGQARGGSARHGSARSGSAMTGSAMUGQAwVGQAiWGSAiXGSAiBHSAWCHSAWDHQAWEHQARFHSARGHSARRHSAMSHSAMTHQAMUHQAMVHSATWHSATAISAQBISAWCIQAWDIQAWEISAWFISARQISAMRISAMSIQAMTIQAMUISAMVISAMBJQAxCJQAWDJSAWEJSAWPJSAMQJSAMRJQAMSJQAMTJSAMUJSAMCKSApDKSAWOKSARPKSAMQKQAMRKQAMSKSAMTKSAMNLSAROLSARPLQARQLQAMRLSAMSLSAMMMSARNMSAROMQARPMQARQMSARRMSAMLNSAsMNSAyNNQAyONQAsPNSAqQNSAm|IASA1JASAzKAQAtLAQArMASAnNASAlHBSAMIBSAMJBQAMKBQAMLBSAMMBSAPGCSARHCSAMICQAMJCQAMKCSAMLCSAMWCSA2FDSARGDSARHDQARIDQAMJDSAMKDSAMVDSAKWDSA0XDQAuEESARFESARGEQARHEQARIESARJESAMUESACVESAJWEQADXEQADYESAoDFSAREFSARFFQARGFQARHFSARIFSARTFSAiUFSAiVFQAvWFQACXFSACYFSACCGSAWDGSAREGQARFGQARGGSARHGSARSGSAMTGSAMUGQAwVGQAiWGSAiXGSAiBHSAWCHSAWDHQAWEHQARFHSARGHSARRHSAMSHSAMTHQAMUHQAMVHSATWHSATAISAQBISAWCIQAWDIQAWEISAWFISARQISAMRISAMSIQAMTIQAMUISAMVISAMBJQAxCJQAWDJSAWEJSAWPJSAMQJSAMRJQAMSJQAMTJSAMUJSAMCKSApDKSAWOKSARPKSAMQKQAMRKQAMSKSAMTKSAMNLSAROLSARPLQARQLQAMRLSAMSLSAMMMSARNMSAROMQARPMQARQMSARRMSAMLNSAsMNSAyNNQAyONQAsPNSAqQNSAm|IASA1JASAzKAQAtLAQArMASAnNASAlHBSAMIBSAMJBQAMKBQAMLBSAMMBSAPGCSARHCSAMICQAMJCQAMKCSAMLCSAMWCSA2FDSARGDSARHDQARIDQAMJDSAMKDSAMVDSAKWDSA0XDQAuEESARFESARGEQARHEQARIESARJESAMUESACVESAJWEQADXEQADYESAoDFSAREFSARFFQARGFQARHFSARIFSARTFSAiUFSAiVFQAvWFQACXFSACYFSACCGSAWDGSAREGQARFGQARGGSARHGSARSGSAMTGSAMUGQAwVGQAiWGSAiXGSAiBHSAWCHSAWDHQAWEHQARFHSARGHSARRHSAMSHSAMTHQAMUHQAMVHSATWHSATAISAQBISAWCIQAWDIQAWEISAWFISARQISAMRISAMSIQAMTIQAMUISAMVISAMBJQAxCJQAWDJSAWEJSAWPJSAMQJSAMRJQAMSJQAMTJSAMUJSAMCKSApDKSAWOKSARPKSAMQKQAMRKQAMSKSAMTKSAMNLSAROLSARPLQARQLQAMRLSAMSLSAMMMSARNMSAROMQARPMQARQMSARRMSAMLNSAsMNSAyNNQAyONQAsPNSAqQNSAm|IASA1JAQAzKAQAtLASArMASAnGBSAfHBSAMIBQAMJBQAMKBSAMLBSAMFCSARGCSARHCQAMICQAMJCSAMKCSAMVCSA0WCSA2EDSARFDSARGDQARHDQARIDSAMJDSAMUDSADVDSAKWDQA0XDQAuDESAREESARFEQARGEQARHESARIESARTESACUESACVEQAJWEQADXESADYESAoCFSARDFSAREFQARFFQARGFSARHFSARSFSAHTFSAiUFQAiVFQAvWFSACXFSACBGSAWCGSAWDGQAREGQARFGSARGGSARRGSAMSGSAMTGQAMUGQAwVGSAiWGSAiAHSA3BHSAWCHQAWDHQAWEHSARFHSARQHSAMRHSAMSHQAMTHQAMUHSAMVHSATAISAQBIQAWCIQAWDISAWEISAWPISAMQISAMRIQAMSIQAMTISAMUISAMBJQAxCJSAWDJSAWOJSAMPJSAMQJQAMRJQAMSJSAMTJSAMCKSApNKSAROKSARPKQAMQKQAMRKSAMSKSAMMLSARNLSAROLQARPLQARQLSAMRLSAMLMSARMMSARNMQAROMQARPMSARQMSARKNSAqLNSAsMNQAyNNQAyONSAsPNSAq|IASA1JAQAzKAQAtLASArMASAnGBSAfHBSAMIBQAMJBQAMKBSAMLBSAMFCSARGCSARHCQAMICQAMJCSAMKCSAMVCSA0WCSA2EDSARFDSARGDQARHDQARIDSAMJDSAMUDSADVDSAKWDQA0XDQAuDESAREESARFEQARGEQARHESARIESARTESACUESACVEQAJWEQADXESADYESAoCFSARDFSAREFQARFFQARGFSARHFSARSFSAHTFSAiUFQAiVFQAvWFSACXFSACBGSAWCGSAWDGQAREGQARFGSARGGSARRGSAMSGSAMTGQAMUGQAwVGSAiWGSAiAHSA3BHSAWCHQAWDHQAWEHSARFHSARQHSAMRHSAMSHQAMTHQAMUHSAMVHSATAISAQBIQAWCIQAWDISAWEISAWPISAMQISAMRIQAMSIQAMTISAMUISAMBJQAxCJSAWDJSAWOJSAMPJSAMQJQAMRJQAMSJSAMTJSAMCKSApNKSAROKSARPKQAMQKQAMRKSAMSKSAMMLSARNLSAROLQARPLQARQLSAMRLSAMLMSARMMSARNMQAROMQARPMSARQMSARKNSAqLNSAsMNQAyNNQAyONSAsPNSAq|IASA1JAQAzKAQAtLASArMASAnGBSAfHBSAMIBQAMJBQAMKBSAMLBSAMFCSARGCSARHCQAMICQAMJCSAMKCSAMVCSA0WCSA2EDSARFDSARGDQARHDQARIDSAMJDSAMUDSADVDSAKWDQA0XDQAuDESAREESARFEQARGEQARHESARIESARTESACUESACVEQAJWEQADXESADYESAoCFSARDFSAREFQARFFQARGFSARHFSARSFSAHTFSAiUFQAiVFQAvWFSACXFSACBGSAWCGSAWDGQAREGQARFGSARGGSARRGSAMSGSAMTGQAMUGQAwVGSAiWGSAiAHSA3BHSAWCHQAWDHQAWEHSARFHSARQHSAMRHSAMSHQAMTHQAMUHSAMVHSATAISAQBIQAWCIQAWDISAWEISAWPISAMQISAMRIQAMSIQAMTISAMUISAMBJQAxCJSAWDJSAWOJSAMPJSAMQJQAMRJQAMSJSAMTJSAMCKSApNKSAROKSARPKQAMQKQAMRKSAMSKSAMMLSARNLSAROLQARPLQARQLSAMRLSAMLMSARMMSARNMQAROMQARPMSARQMSARKNSAqLNSAsMNQAyNNQAyONSAsPNSAq|IAQA1JAQAzKASAtLASArFBSA4GBSAfHBQAMIBQAMJBSAMKBSAMECSARFCSARGCQARHCQAMICSAMJCSAMUCSA0VCSA0WCQA2DDSAREDSARFDQARGDQARHDSARIDSAMTDSADUDSADVDQAKWDQA0XDSAuCESARDESAREEQARFEQARGESARHESARSESACTESACUEQACVEQAJWESADXESADBFSAWCFSARDFQAREFQARFFSARGFSARRFSAPSFSAHTFQAiUFQAiVFSAvWFSACAGSA3BGSAWCGQAWDGQAREGSARFGSARQGSAMRGSAMSGQAMTGQAMUGSAwVGSAiAHSA3BHQAWCHQAWDHSAWEHSARPHSAMQHSAMRHQAMSHQAMTHSAMUHSAMAIQAQBIQAWCISAWDISAWOISAMPISAMQIQAMRIQAMSISAMTISAMBJSAxCJSAWNJSAROJSAMPJQAMQJQAMRJSAMSJSAMMKSARNKSAROKQARPKQAMQKSAMRKSAMLLSARMLSARNLQAROLQARPLSARQLSAMKMSARLMSARMMQARNMQAROMSARPMSARJNSA5KNSAqLNQAsMNQAyNNSAyONSAs|IAQA1JAQAzKASAtLASArFBSA4GBSAfHBQAMIBQAMJBSAMKBSAMECSARFCSARGCQARHCQAMICSAMJCSAMUCSA0VCSA0WCQA2DDSAREDSARFDQARGDQARHDSARIDSAMTDSADUDSADVDQAKWDQA0XDSAuCESARDESAREEQARFEQARGESARHESARSESACTESACUEQACVEQAJWESADXESADBFSAWCFSARDFQAREFQARFFSARGFSARRFSAPSFSAHTFQAiUFQAiVFSAvWFSACAGSA3BGSAWCGQAWDGQAREGSARFGSARQGSAMRGSAMSGQAMTGQAMUGSAwVGSAiAHSA3BHQAWCHQAWDHSAWEHSARPHSAMQHSAMRHQAMSHQAMTHSAMUHSAMAIQAQBIQAWCISAWDISAWOISAMPISAMQIQAMRIQAMSISAMTISAMBJSAxCJSAWNJSAROJSAMPJQAMQJQAMRJSAMSJSAMMKSARNKSAROKQARPKQAMQKSAMRKSAMLLSARMLSARNLQAROLQARPLSARQLSAMKMSARLMSARMMQARNMQAROMSARPMSARJNSA5KNSAqLNQAsMNQAyNNSAyONSAs|IAQA1JAQAzKASAtLASArFBSA4GBSAfHBQAMIBQAMJBSAMKBSAMECSARFCSARGCQARHCQAMICSAMJCSAMUCSA0VCSA0WCQA2DDSAREDSARFDQARGDQARHDSARIDSAMTDSADUDSADVDQAKWDQA0XDSAuCESARDESAREEQARFEQARGESARHESARSESACTESACUEQACVEQAJWESADXESADBFSAWCFSARDFQAREFQARFFSARGFSARRFSAPSFSAHTFQAiUFQAiVFSAvWFSACAGSA3BGSAWCGQAWDGQAREGSARFGSARQGSAMRGSAMSGQAMTGQAMUGSAwVGSAiAHSA3BHQAWCHQAWDHSAWEHSARPHSAMQHSAMRHQAMSHQAMTHSAMUHSAMAIQAQBIQAWCISAWDISAWOISAMPISAMQIQAMRIQAMSISAMTISAMBJSAxCJSAWNJSAROJSAMPJQAMQJQAMRJSAMSJSAMMKSARNKSAROKQARPKQAMQKSAMRKSAMLLSARMLSARNLQAROLQARPLSARQLSAMKMSARLMSARMMQARNMQAROMSARPMSARJNSA5KNSAqLNQAsMNQAyNNSAyONSAs|IAQA1JASAzKASAtFBSA4GBQAfHBQAMIBSAMJBSAMUBSAFDCSAGECSARFCQARGCQARHCSAMICSAMTCSAKUCSA0VCQA0WCQA2CDSALDDSAREDQARFDQARGDSARHDSARSDSACTDSADUDQADVDQAKWDSA0XDSAuBESAOCESARDEQAREEQARFESARGESARRESAHSESACTEQACUEQACVESAJWESADAFSAQBFSAWCFQARDFQAREFSARFFSARQFSAMRFSAPSFQAHTFQAiUFSAiVFSAvAGSA3BGQAWCGQAWDGSAREGSARPGSAMQGSAMRGQAMSGQAMTGSAMUGSAwAHQA3BHQAWCHSAWDHSAWOHSAMPHSAMQHQAMRHQAMSHSAMTHSAMAIQAQBISAWCISAWNISAMOISAMPIQAMQIQAMRISAMSISAMBJSAxMJSARNJSAROJQAMPJQAMQJSAMRJSAMLKSARMKSARNKQAROKQARPKSAMQKSAMKLSARLLSARMLQARNLQAROLSARPLSARJMSARKMSARLMQARMMQARNMSAROMSARINSAcJNSA5KNQAqLNQAsMNSAyNNSAy|IAQA1JASAzKASAtFBSA4GBQAfHBQAMIBSAMJBSAMUBSAFDCSAGECSARFCQARGCQARHCSAMICSAMTCSAKUCSA0VCQA0WCQA2CDSALDDSAREDQARFDQARGDSARHDSARSDSACTDSADUDQADVDQAKWDSA0XDSAuBESAOCESARDEQAREEQARFESARGESARRESAHSESACTEQACUEQACVESAJWESADAFSAQBFSAWCFQARDFQAREFSARFFSARQFSAMRFSAPSFQAHTFQAiUFSAiVFSAvAGSA3BGQAWCGQAWDGSAREGSARPGSAMQGSAMRGQAMSGQAMTGSAMUGSAwAHQA3BHQAWCHSAWDHSAWOHSAMPHSAMQHQAMRHQAMSHSAMTHSAMAIQAQBISAWCISAWNISAMOISAMPIQAMQIQAMRISAMSISAMBJSAxMJSARNJSAROJQAMPJQAMQJSAMRJSAMLKSARMKSARNKQAROKQARPKSAMQKSAMKLSARLLSARMLQARNLQAROLSARPLSARJMSARKMSARLMQARMMQARNMSAROMSARINSAcJNSA5KNQAqLNQAsMNSAyNNSAy|IAQA1JASAzKASAtFBSA4GBQAfHBQAMIBSAMJBSAMUBSAFDCSAGECSARFCQARGCQARHCSAMICSAMTCSAKUCSA0VCQA0WCQA2CDSALDDSAREDQARFDQARGDSARHDSARSDSACTDSADUDQADVDQAKWDSA0XDSAuBESAOCESARDEQAREEQARFESARGESARRESAHSESACTEQACUEQACVESAJWESADAFSAQBFSAWCFQARDFQAREFSARFFSARQFSAMRFSAPSFQAHTFQAiUFSAiVFSAvAGSA3BGQAWCGQAWDGSAREGSARPGSAMQGSAMRGQAMSGQAMTGSAMUGSAwAHQA3BHQAWCHSAWDHSAWOHSAMPHSAMQHQAMRHQAMSHSAMTHSAMAIQAQBISAWCISAWNISAMOISAMPIQAMQIQAMRISAMSISAMBJSAxMJSARNJSAROJQAMPJQAMQJSAMRJSAMLKSARMKSARNKQAROKQARPKSAMQKSAMKLSARLLSARMLQARNLQAROLSARPLSARJMSARKMSARLMQARMMQARNMSAROMSARINSAcJNSA5KNQAqLNQAsMNSAyNNSAy|IASA1JASAzFBQA4GBQAfHBSAMIBSAMTBSAEUBSAFDCSAGECQARFCQARGCSARHCSAMSCSADTCSAKUCQA0VCQA0WCSA2CDSALDDQAREDQARFDSARGDSARRDSACSDSACTDQADUDQADVDSAKWDSA0BESAOCEQARDEQAREESARFESARQESAHRESAHSEQACTEQACUESACVESAJAFSAQBFQAWCFQARDFSAREFSARPFSAMQFSAMRFQAPSFQAHTFSAiUFSAiAGQA3BGQAWCGSAWDGSAROGSAMPGSAMQGQAMRGQAMSGSAMTGSAMAHQA3BHSAWCHSAWNHSAMOHSAMPHQAMQHQAMRHSAMSHSAMAISAQBISAWMISARNISAMOIQAMPIQAMQISAMRISAMLJSARMJSARNJQAROJQAMPJSAMQJSAMKKSARLKSARMKQARNKQAROKSARPKSAMJLSARKLSARLLQARMLQARNLSAROLSARIMSAWJMSARKMQARLMQARMMSARNMSARINSAcJNQA5KNQAqLNSAsMNSAy|IASA1JASAzFBQA4GBQAfHBSAMIBSAMTBSAEUBSAFDCSAGECQARFCQARGCSARHCSAMSCSADTCSAKUCQA0VCQA0WCSA2CDSALDDQAREDQARFDSARGDSARRDSACSDSACTDQADUDQADVDSAKWDSA0BESAOCEQARDEQAREESARFESARQESAHRESAHSEQACTEQACUESACVESAJAFSAQBFQAWCFQARDFSAREFSARPFSAMQFSAMRFQAPSFQAHTFSAiUFSAiAGQA3BGQAWCGSAWDGSAROGSAMPGSAMQGQAMRGQAMSGSAMTGSAMAHQA3BHSAWCHSAWNHSAMOHSAMPHQAMQHQAMRHSAMSHSAMAISAQBISAWMISARNISAMOIQAMPIQAMQISAMRISAMLJSARMJSARNJQAROJQAMPJSAMQJSAMKKSARLKSARMKQARNKQAROKSARPKSAMJLSARKLSARLLQARMLQARNLSAROLSARIMSAWJMSARKMQARLMQARMMSARNMSARINSAcJNQA5KNQAqLNSAsMNSAy|IASA1JASAzFBQA4GBQAfHBSAMIBSAMTBSAEUBSAFDCSAGECQARFCQARGCSARHCSAMSCSADTCSAKUCQA0VCQA0WCSA2CDSALDDQAREDQARFDSARGDSARRDSACSDSACTDQADUDQADVDSAKWDSA0BESAOCEQARDEQAREESARFESARQESAHRESAHSEQACTEQACUESACVESAJAFSAQBFQAWCFQARDFSAREFSARPFSAMQFSAMRFQAPSFQAHTFSAiUFSAiAGQA3BGQAWCGSAWDGSAROGSAMPGSAMQGQAMRGQAMSGSAMTGSAMAHQA3BHSAWCHSAWNHSAMOHSAMPHQAMQHQAMRHSAMSHSAMAISAQBISAWMISARNISAMOIQAMPIQAMQISAMRISAMLJSARMJSARNJQAROJQAMPJSAMQJSAMKKSARLKSARMKQARNKQAROKSARPKSAMJLSARKLSARLLQARMLQARNLSAROLSARIMSAWJMSARKMQARLMQARMMSARNMSARINSAcJNQA5KNQAqLNSAsMNSAy|IASA1FBQA4GBSAfHBSAMSBSADTBSAEUBQAFDCQAGECQARFCSARGCSARRCSAJSCSADTCQAKUCQA0VCSA0WCSA2CDQALDDQAREDSARFDSARQDSAIRDSACSDQACTDQADUDSADVDSAKBEQAOCEQARDESAREESARPESAPQESAHREQAHSEQACTESACUESACAFQAQBFQAWCFSARDFSAROFSAMPFSAMQFQAMRFQAPSFSAHTFSAiAGQA3BGSAWCGSAWNGSAMOGSAMPGQAMQGQAMRGSAMSGSAMAHSA3BHSAWMHSAMNHSAMOHQAMPHQAMQHSAMRHSAMAISAQLISARMISARNIQAMOIQAMPISAMQISAMKJSARLJSARMJQARNJQAROJSAMPJSAMJKSARKKSARLKQARMKQARNKSAROKSARILSARJLSARKLQARLLQARMLSARNLSARHMSAWIMSAWJMQARKMQARLMSARMMSARINQAcJNQA5KNSAqLNSAs|IASA1FBQA4GBSAfHBSAMSBSADTBSAEUBQAFDCQAGECQARFCSARGCSARRCSAJSCSADTCQAKUCQA0VCSA0WCSA2CDQALDDQAREDSARFDSARQDSAIRDSACSDQACTDQADUDSADVDSAKBEQAOCEQARDESAREESARPESAPQESAHREQAHSEQACTESACUESACAFQAQBFQAWCFSARDFSAROFSAMPFSAMQFQAMRFQAPSFSAHTFSAiAGQA3BGSAWCGSAWNGSAMOGSAMPGQAMQGQAMRGSAMSGSAMAHSA3BHSAWMHSAMNHSAMOHQAMPHQAMQHSAMRHSAMAISAQLISARMISARNIQAMOIQAMPISAMQISAMKJSARLJSARMJQARNJQAROJSAMPJSAMJKSARKKSARLKQARMKQARNKSAROKSARILSARJLSARKLQARLLQARMLSARNLSARHMSAWIMSAWJMQARKMQARLMSARMMSARINQAcJNQA5KNSAqLNSAs|IASA1FBQA4GBSAfHBSAMSBSADTBSAEUBQAFDCQAGECQARFCSARGCSARRCSAJSCSADTCQAKUCQA0VCSA0WCSA2CDQALDDQAREDSARFDSARQDSAIRDSACSDQACTDQADUDSADVDSAKBEQAOCEQARDESAREESARPESAPQESAHREQAHSEQACTESACUESACAFQAQBFQAWCFSARDFSAROFSAMPFSAMQFQAMRFQAPSFSAHTFSAiAGQA3BGSAWCGSAWNGSAMOGSAMPGQAMQGQAMRGSAMSGSAMAHSA3BHSAWMHSAMNHSAMOHQAMPHQAMQHSAMRHSAMAISAQLISARMISARNIQAMOIQAMPISAMQISAMKJSARLJSARMJQARNJQAROJSAMPJSAMJKSARKKSARLKQARMKQARNKSAROKSARILSARJLSARKLQARLLQARMLSARNLSARHMSAWIMSAWJMQARKMQARLMSARMMSARINQAcJNQA5KNSAqLNSAs|FBSA4GBSAfRBSADSBSADTBQAEUBQAFDCQAGECSARFCSARQCSACRCSAJSCQADTCQAKUCSA0VCSA0CDQALDDSAREDSARPDSAHQDSAIRDQACSDQACTDSADUDSADBEQAOCESARDESAROESAMPESAPQEQAHREQAHSESACTESACAFQAQBFSAWCFSARNFSAMOFSAMPFQAMQFQAMRFSAPSFSAHAGSA3BGSAWMGSAMNGSAMOGQAMPGQAMQGSAMRGSAMAHSA3LHSARMHSAMNHQAMOHQAMPHSAMQHSAMKISARLISARMIQARNIQAMOISAMPISAMJJSARKJSARLJQARMJQARNJSAROJSAMIKSARJKSARKKQARLKQARMKSARNKSARHLSAWILSARJLQARKLQARLLSARMLSARGMSAaHMSAWIMQAWJMQARKMSARLMSARINQAcJNSA5KNSAq|FBSA4GBSAfRBSADSBSADTBQAEUBQAFDCQAGECSARFCSARQCSACRCSAJSCQADTCQAKUCSA0VCSA0CDQALDDSAREDSARPDSAHQDSAIRDQACSDQACTDSADUDSADBEQAOCESARDESAROESAMPESAPQEQAHREQAHSESACTESACAFQAQBFSAWCFSARNFSAMOFSAMPFQAMQFQAMRFSAPSFSAHAGSA3BGSAWMGSAMNGSAMOGQAMPGQAMQGSAMRGSAMAHSA3LHSARMHSAMNHQAMOHQAMPHSAMQHSAMKISARLISARMIQARNIQAMOISAMPISAMJJSARKJSARLJQARMJQARNJSAROJSAMIKSARJKSARKKQARLKQARMKSARNKSARHLSAWILSARJLQARKLQARLLSARMLSARGMSAaHMSAWIMQAWJMQARKMSARLMSARINQAcJNSA5KNSAq|FBSA4GBSAfRBSADSBSADTBQAEUBQAFDCQAGECSARFCSARQCSACRCSAJSCQADTCQAKUCSA0VCSA0CDQALDDSAREDSARPDSAHQDSAIRDQACSDQACTDSADUDSADBEQAOCESARDESAROESAMPESAPQEQAHREQAHSESACTESACAFQAQBFSAWCFSARNFSAMOFSAMPFQAMQFQAMRFSAPSFSAHAGSA3BGSAWMGSAMNGSAMOGQAMPGQAMQGSAMRGSAMAHSA3LHSARMHSAMNHQAMOHQAMPHSAMQHSAMKISARLISARMIQARNIQAMOISAMPISAMJJSARKJSARLJQARMJQARNJSAROJSAMIKSARJKSARKKQARLKQARMKSARNKSARHLSAWILSARJLQARKLQARLLSARMLSARGMSAaHMSAWIMQAWJMQARKMSARLMSARINQAcJNSA5KNSAq|RASABFBSA4QBSACRBSADSBQADTBQAEUBSAFDCSAGECSARPCSAIQCSACRCQAJSCQADTCSAKUCSA0CDSALDDSARODSANPDSAHQDQAIRDQACSDSACTDSADBESAOCESARNESAMOESAMPEQAPQEQAHRESAHSESACAFSAQBFSAWMFSAMNFSAMOFQAMPFQAMQFSAMRFSAPAGSA3LGSAMMGSAMNGQAMOGQAMPGSAMQGSAMKHSARLHSARMHQAMNHQAMOHSAMPHSAMJISARKISARLIQARMIQARNISAMOISAMZISAUIJSARJJSARKJQARLJQARMJSARNJSARYJSAVHKSARIKSARJKQARKKQARLKSARMKSARXKSAXGLSAWHLSAWILQARJLQARKLSARLLSARWLSAYFMSAZGMSAaHMQAWIMQAWJMSARKMSARINSAcJNSA5|RASABFBSA4QBSACRBSADSBQADTBQAEUBSAFDCSAGECSARPCSAIQCSACRCQAJSCQADTCSAKUCSA0CDSALDDSARODSANPDSAHQDQAIRDQACSDSACTDSADBESAOCESARNESAMOESAMPEQAPQEQAHRESAHSESACAFSAQBFSAWMFSAMNFSAMOFQAMPFQAMQFSAMRFSAPAGSA3LGSAMMGSAMNGQAMOGQAMPGSAMQGSAMKHSARLHSARMHQAMNHQAMOHSAMPHSAMJISARKISARLIQARMIQARNISAMOISAMZISAUIJSARJJSARKJQARLJQARMJSARNJSARYJSAVHKSARIKSARJKQARKKQARLKSARMKSARXKSAXGLSAWHLSAWILQARJLQARKLSARLLSARWLSAYFMSAZGMSAaHMQAWIMQAWJMSARKMSARINSAcJNSA5|RASABFBSA4QBSACRBSADSBQADTBQAEUBSAFDCSAGECSARPCSAIQCSACRCQAJSCQADTCSAKUCSA0CDSALDDSARODSANPDSAHQDQAIRDQACSDSACTDSADBESAOCESARNESAMOESAMPEQAPQEQAHRESAHSESACAFSAQBFSAWMFSAMNFSAMOFQAMPFQAMQFSAMRFSAPAGSA3LGSAMMGSAMNGQAMOGQAMPGSAMQGSAMKHSARLHSARMHQAMNHQAMOHSAMPHSAMJISARKISARLIQARMIQARNISAMOISAMZISAUIJSARJJSARKJQARLJQARMJSARNJSARYJSAVHKSARIKSARJKQARKKQARLKSARMKSARXKSAXGLSAWHLSAWILQARJLQARKLSARLLSARWLSAYFMSAZGMSAaHMQAWIMQAWJMSARKMSARINSAcJNSA5'
VN_AL[sunbeams]='pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO|pQAdAtO'
VN_APAL[sunbeams]='988448685834e8c870ecc874e0c4708c7844403014ac8c40b09044e8c874eccc7454401ca8873aac883c50401ca8883c1c14086a54269c8448e8c46a746034b094503a2f14846c2c645020201808342c10605020181408ffe9a8bca458a08034d4b464746438e8c46c201c0c302410a4883c443418a48438b498582c241054441c9c7c34604c20886c2cbca460e8c470e8c4682c240c6450246c5824eccc784c3c188c7c4824200c3c3014241c0c'
VN_AF[aurora]='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'
VN_AL[aurora]='STAlAoGXQAmAoGcRAnAoGhSAoAoGmQAlAoG|STAlAoGXRAmAoGcQAnAoGhTAoAoGmQAlAoG|SSAlAoGXSAmAoGcQAnAoGhTAoAoGmQAlAoG|SRAlAoGXSAmAoGcQAnAoGhSAoAoGmRAlAoG|SQAmAoGXTAnAoGcQAoAoGhSAlAoGmSAmAoG|SQAmAoGXTAnAoGcQAoAoGhRAlAoGmTAmAoG|SQAmAoGXSAnAoGcRAoAoGhQAlAoGmTAmAoG|SQAmAoGXSAnAoGcSAoAoGhQAlAoGmTAmAoG|SQAnAoGXRAoAoGcTAlAoGhQAmAoGmSAnAoG|SRAnAoGXQAoAoGcTAlAoGhQAmAoGmRAnAoG|SSAnAoGXQAoAoGcTAlAoGhRAmAoGmQAnAoG|STAnAoGXQAoAoGcSAlAoGhSAmAoGmQAnAoG|STAoAoGXQAlAoGcRAmAoGhSAnAoGmQAoAoG|STAoAoGXRAlAoGcQAmAoGhTAnAoGmQAoAoG|SSAoAoGXSAlAoGcQAmAoGhTAnAoGmQAoAoG|SRAoAoGXSAlAoGcQAmAoGhSAnAoGmRAoAoG|SQAlAoGXTAmAoGcQAnAoGhSAoAoGmSAlAoG|SQAlAoGXTAmAoGcQAnAoGhRAoAoGmTAlAoG|SQAlAoGXSAmAoGcRAnAoGhQAoAoGmTAlAoG|SQAlAoGXSAmAoGcSAnAoGhQAoAoGmTAlAoG|SQAmAoGXRAnAoGcTAoAoGhQAlAoGmSAmAoG|SRAmAoGXQAnAoGcTAoAoGhQAlAoGmRAmAoG|SSAmAoGXQAnAoGcTAoAoGhRAlAoGmQAmAoG|STAmAoGXQAnAoGcSAoAoGhSAlAoGmQAmAoG|STAnAoGXQAoAoGcRAlAoGhSAmAoGmQAnAoG|STAnAoGXRAoAoGcQAlAoGhTAmAoGmQAnAoG|SSAnAoGXSAoAoGcQAlAoGhTAmAoGmQAnAoG|SRAnAoGXSAoAoGcQAlAoGhSAmAoGmRAnAoG|SQAoAoGXTAlAoGcQAmAoGhSAnAoGmSAoAoG|SQAoAoGXTAlAoGcQAmAoGhRAnAoGmTAoAoG|SQAoAoGXSAlAoGcRAmAoGhQAnAoGmTAoAoG|SQAoAoGXSAlAoGcSAmAoGhQAnAoGmTAoAoG|SQAlAoGXRAmAoGcTAnAoGhQAoAoGmSAlAoG|SRAlAoGXQAmAoGcTAnAoGhQAoAoGmRAlAoG|SSAlAoGXQAmAoGcTAnAoGhRAoAoGmQAlAoG|STAlAoGXQAmAoGcSAnAoGhSAoAoGmQAlAoG|STAmAoGXQAnAoGcRAoAoGhSAlAoGmQAmAoG|STAmAoGXRAnAoGcQAoAoGhTAlAoGmQAmAoG|SSAmAoGXSAnAoGcQAoAoGhTAlAoGmQAmAoG|SRAmAoGXSAnAoGcQAoAoGhSAlAoGmRAmAoG|SQAnAoGXTAoAoGcQAlAoGhSAmAoGmSAnAoG|SQAnAoGXTAoAoGcQAlAoGhRAmAoGmTAnAoG|SQAnAoGXSAoAoGcRAlAoGhQAmAoGmTAnAoG|SQAnAoGXSAoAoGcSAlAoGhQAmAoGmTAnAoG|SQAoAoGXRAlAoGcTAmAoGhQAnAoGmSAoAoG|SRAoAoGXQAlAoGcTAmAoGhQAnAoGmRAoAoG|SSAoAoGXQAlAoGcTAmAoGhRAnAoGmQAoAoG|STAoAoGXQAlAoGcSAmAoGhSAnAoGmQAoAoG'
VN_APAL[aurora]='2894c8187c94283c3840d8e42464685c64a0d880bc48508084708824a46808f4f07c687828b07410f0e020a46814f0d008ecdc5878d4a0709c0c6c4800444c346cb094a4d87468a010b09008f4fc2090880ce8fc10789408707c185c7c785cfc245c9030246cfc6cc40c643c3c2c7c7a5cffff6ec72af59808f7fe20749478bca42040344c90a49460ec2068686860a0a450883ce49c44587c906c8838947018ecf86c707c30a47420e8e828e4940cecd45c78d06c506424f4a00c684004a8a45880fc0040443c54a47470981cf4c084549410a884208878083c48503cac189cc04c38a4e868c86048c80484885488786cb8e41444303c94a08048a4106c64605ca0a8548c54d8a038547c8c68884cd89c68707434e89824ec9414a87008f4f43468b0ac98d820f0b02ccca42c205cac4884205c80443494883c6c28f498403088e460c054887c6cbce4ec74c0cc88b8a48ca408ecd4346890b098c45c586c14b0840c6c4c04b4b03078b8c090d40048483868b498a0dcb488d82018445c284818a468382874148450b850a000646884446c2494600ca09c406898a8a4b400484c3c5ca0786c80243c7078688c24f49c9874ac18e0a804ecf42c6cb4b888d86864902498901cd4fc147c6c1c94b84c48b8e068d00864744c4cb88c4ca43cccb01c1c4c90489c54acc0407088c8549c30306c84406c14606c58304c34ec9810ac985c8cdcc08cb8c48cc808e4f4306cb87468a42ce4ac68649c2898941494b02078782090bc4c48b4f06ccc145c7c504cc0d868d4202050c068dc60c4a8285064ac60e85cd0a0285c7050348c503c5024a06810b4986480e410b09c5498d4004c48548ce43c50a09870a418e0a004a4b04898f8385cb46878ac6c589c209c9408a4b46c68fc24707c1c94bc6470fc18587c3428704c34905ccca02854607c3460c050946830544c605c407c94885cf4502c70d084b824a86c0cf4e810ac9c509cd4006c6c4448a0b068a01094680498a490a8d84048a87c489008a8b8607cfc246c706074fc1c7ca428c4ec342460f46cc450847458c8e8682c5054348c7044b818744c7c507414a87808685004acac00b4b0489cf82838708458881cc8880094984050b0c870d84c389c904c902c888834b8fca4407c3888782484b43c80683488a8805cf8347084945cf06c3c9c7030585c5898345c806c305410804c08908808402804a4ac74547014ac7008684c08f4ec04e8e47c5c8c10846410e4fc00989c4448ac48409c94448c30848428ccf834d0f038a8c05860984c405020c47804706c44484c18b07408f4e84c486424e8b0109cb07060fc90489844c0b840409c388084a0407c40887838c4f444cc9030b0c4643c9c4c243c605c985440500c6c4400686c84809048404c1090644c44640c8ca04040a4903c844cc0b034cc941cb4c8583ca044203810784814c49810906844204854bcb034545c4880b48c5cf0386c907848b0ac488c6c409cb84c98a8488c7cb8a854c89834c8d46854bc6038543ce4980c483014ac9c5898d43870a0707c8064708804787c00787c686cfc008c905884fc188870c864d84420444c7c943454584080b4583cb0406c907444b09c48902ce89c78409cac489448d4a4f068bc6cc0a040c0d8583484e478bc6c2c54289c680c402c70608400444804bcc03064a4d87cc844b4c0481c404480882c80bc3054504080b05c40b4386c887044ace468ccf06cc8f468bc985484bc84c0047c803848946460f08c50a048b4c09858d468c09c3884948074e050408064385428a8700c442c2c3878b060a09c4084348c6c448ca408482c20989c7048a0046c6450589c506cb4a88ca408ac94588ce46c789020f4ac989cdc286c743c28708c3c6cac50a40c5c707474e820ec9808b09c3874a4cc88c430709c68809454687810b48c08745804bcb800504c18505064347c145c78402864a8448c64847c44d4f064c0e41440301498985864b4b480a804aca03480a0306c9c688494506c7c14b484087860006c700884941c5050703054285c6c2078a4382878ec68c8905cf0b04c9060c0e01c644414989c5c54c0804c7010a0685c98d004a4a034609c58607c10a07820dca8085c685c44c014744c483c8c90608018f0d0445098b4689814905808aca45488f40490983c58a46c70984838a4883c84249080246c6c20d0fc3c78a83c748c3c605420808c58388c48dc9838d890046c6040549414945c30d8ac30a4903828704478ac44286834b47c1864704c2860284464c08cc00494984054a8746c9c4834a028e4b8d460bc2cac8c1488a4281c503c78ac2460444ca480884cb844286078506c244864109c6800a4a03848a4cc68bc24b8840c94a424184c385c506094841430544c446c18d8fc1c84ac4844b0c068d8d464c83cbc9c24a8c83c246cf068c804787808786c6c6cec0c8c706084e06c58704c94fc1828544c3c6c4054b0ec74c8247cb04850bcd474d07058f4c864d034bca010708c845cf4a4448c4020384c54940044440cbcac38648ce07cbc1c204c5834642478ac6c64fc7458f45c40a86c6cdc0480703c488828b0e8c864cc34747c40c0f0246c8c3c286cb0489444203c2c3c70b460944044a44c1c382c5c489858d85c807840d4e410442c54648004c4c8302470843c709470a4e86cb85888783c98a07c68e8349094584854104c3040445c48607c1cf4b000787838449410546c4848b04cb0c0441c3c34886c30a8c48c58d84490743094944c505810684414905c44445c6830580c846c04a0a4284478e078c8682c5824906854349498487c2c9468189890746474106c44b884b8086040485cc010784c1880946840a8b0489080b8ac285c48248c9c7048c8983c7430986c20e8dc18906410a09c00a0a434549c5c587c206060107c943058482c889c9c3c741c906404687024908c24b0800c6074184c702c5c6c8c64e81c90600ca49c3c6c9c009ca03c60a4b494bc5c68e8a46ca814a074004c501c948c185c4c30a08c14506c285c688c5074209860049c946068e014a06c205c5c38909804504820506c20f4a80ca47c00aca85878f4b078c024b890086070241c4c107078305c705060809c60ec54408810f4d4005048204c7008aca07464f80ca88808b8b06078f404ecf05088f4ac84c4201c483080a00c404434a0b47040982444700ca48430c4e43064785838905084f42cd8b8201c4c40307000a09c20184c602c5c8c44a0481c3c385c7c3030708040709c7094006c687858f09444a048808c28d4f44874804c2c704c2040243c5c5060600874683c448888488c28a89020bce8583cac9844984c747c542c706430581084500ca08c2844682c2c70904c840c849c5038a49c408c4478706c3c988460dc4c5cb014784c188868602c60248c7010b4cc443498a0448c8c4878348c704888a8149c60049c8c34547c7864745c60840c80600490945c2c6024847444349c8c487c60788c18c4800070740868541c54542cccf88c407c4090a014985c209c9c8c6ce408e0d85464bc845c78084c34607c8c14c48c08645024545858389ca040842c88641cd4dc94507c0848300c785c10c498'
VN_AF[stardust]='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'
VN_AL[stardust]='oYATAeEkcAUAeEadAVAeETaAWAeETWATAeEaTAUAeEkUAVAeE|oYATAeEjcAUAeEZdAVAeESZAWAeETVATAeEcTAUAeElUAVAeE|oZATAeEidAUAeEYcAVAeESZAWAeEUUATAeEdTAUAeEmVAVAeE|oaATAeEgdAUAeEWcAVAeESYAWAeEVUATAeEfTAUAeEnVAVAeE|naATAeEfdAUAeEVcAVAeESXAWAeEXUATAeEgTAUAeEoWAVAeE|mbATAeEddAUAeEUbAVAeESXAWAeEYTATAeEiTAUAeEoXAVAeE|lbATAeEcdAUAeETbAVAeESWAWAeEZTATAeEjTAUAeEoXAVAeE|kcATAeEadAUAeETaAVAeETVAWAeEbTATAeEkUAUAeEoYAVAeE|jcATAeEZdAUAeESZAVAeEUVAWAeEcTATAeElUAUAeEoZAVAeE|hdATAeEXcAUAeESZAVAeEUUAWAeEeTATAeEmVAUAeEoZAVAeE|gdATAeEWcAUAeESYAVAeEWUAWAeEfTATAeEnVAUAeEnaAVAeE|edATAeEVcAUAeESXAVAeEXTAWAeEhTATAeEoWAUAeEnaAVAeE|ddATAeEUbAUAeESXAVAeEYTAWAeEiTATAeEoXAUAeEmbAVAeE|cdATAeETaAUAeESWAVAeEZTAWAeEjTATAeEoXAUAeElcAVAeE|adATAeETaAUAeETVAVAeEbTAWAeEkUATAeEoYAUAeEkcAVAeE|ZdATAeESZAUAeEUVAVAeEcTAWAeEmUATAeEoZAUAeEjcAVAeE|XcATAeESZAUAeEVUAVAeEeTAWAeEmVATAeEoZAUAeEhdAVAeE|WcATAeESYAUAeEWUAVAeEfTAWAeEnVATAeEnaAUAeEgdAVAeE|VbATAeESXAUAeEXTAVAeEhTAWAeEoWATAeEnbAUAeEedAVAeE|UbATAeESXAUAeEYTAVAeEiTAWAeEoXATAeEmbAUAeEddAVAeE|TaATAeESWAUAeEaTAVAeEjUAWAeEoXATAeElcAUAeEbdAVAeE|SaATAeETVAUAeEbTAVAeElUAWAeEoYATAeEkcAUAeEadAVAeE|SZATAeEUVAUAeEdTAVAeEmUAWAeEoZATAeEicAUAeEYdAVAeE|SYATAeEVUAUAeEeTAVAeEnVAWAeEoZATAeEhdAUAeEXcAVAeE|SYATAeEWUAUAeEgTAVAeEnWAWAeEnaATAeEgdAUAeEWcAVAeE|SXATAeEXTAUAeEhTAVAeEoWAWAeEnbATAeEedAUAeEVbAVAeE|SWATAeEYTAUAeEiTAVAeEoXAWAeEmbATAeEddAUAeEUbAVAeE|SWATAeEaTAUAeEkUAVAeEoYAWAeElcATAeEbdAUAeETaAVAeE|TVATAeEbTAUAeElUAVAeEoYAWAeEjcATAeEadAUAeESaAVAeE|UVATAeEdTAUAeEmUAVAeEoZAWAeEicATAeEYdAUAeESZAVAeE|VUATAeEeTAUAeEnVAVAeEoaAWAeEhdATAeEXcAUAeESYAVAeE|WUATAeEgTAUAeEnWAVAeEnaAWAeEfdATAeEWcAUAeESYAVAeE|XTATAeEhTAUAeEoWAVAeEmbAWAeEedATAeEVbAUAeESXAVAeE|ZTATAeEjTAUAeEoXAVAeEmbAWAeEcdATAeEUbAUAeESWAVAeE|aTATAeEkUAUAeEoYAVAeEkcAWAeEbdATAeETaAUAeETWAVAeE|cTATAeElUAUAeEoYAVAeEjcAWAeEZdATAeESaAUAeETVAVAeE|dTATAeEmVAUAeEoZAVAeEicAWAeEYcATAeESZAUAeEUVAVAeE|eTATAeEnVAUAeEoaAVAeEhdAWAeEXcATAeESYAUAeEVUAVAeE|gTATAeEnWAUAeEnaAVAeEfdAWAeEWcATAeESYAUAeEWUAVAeE|hTATAeEoWAUAeEmbAVAeEedAWAeEUbATAeESXAUAeEXTAVAeE|jTATAeEoXAUAeElbAVAeEcdAWAeEUbATAeESWAUAeEZTAVAeE|kUATAeEoYAUAeEkcAVAeEbdAWAeETaATAeETWAUAeEaTAVAeE|lUATAeEoYAUAeEjcAVAeEZdAWAeESaATAeETVAUAeEcTAVAeE|mVATAeEoZAUAeEidAVAeEYcAWAeESZATAeEUUAUAeEdTAVAeE|nVATAeEoaAUAeEgdAVAeEXcAWAeESYATAeEVUAUAeEfTAVAeE|oWATAeEnaAUAeEfdAVAeEVcAWAeESYATAeEWUAUAeEgTAVAeE|oWATAeEmbAUAeEddAVAeEUbAWAeESXATAeEYTAUAeEiTAVAeE|oXATAeElbAUAeEcdAVAeETbAWAeESWATAeEZTAUAeEjTAVAeE'
VN_APAL[stardust]='484848787878fcfcfc786428947c34243440405c7470a8cc383058503c78ac84fc606060848484544420847030fcd45c28404c4060788cd0fcffffffffd75f8fd0ffaf87ff9090902c24104c401cf0c8582438443c586c5c88a4302848483c1c78642c486c84c0c0c0706024283c4c4034604030603048585c5c5c483c18a48c3c20303844607884c4f0242038544078585858c8c8c854481cccac48101c205078944c4c4c283c4898989820180c605024f4cc587070704444445050504434186c5c28243c48547c98344c603434349494944034187460282c2c2cf0f0f050401c5454546ca0c0686868507490584820345060a4a4a430281030284c30485c70a4c8e8e8e84c3870283848202020f4f4f4443814304c608080804438185c4484243848404040747474cccccc1c28346c6c6c382c54c0a04490783414242c3854683c5c703030303830145c4c1cc8a8483c5870342c146050202c3c4c80c0e89880381c2c3488c8f42828282c445434281028405068582470602820343c182830e8c45478682c3838381420288464c018242840305c3c34143c2c5c8868c8241c3468509824242454441c705c282c2044644c942820101c182ca47cf030244434485c1c142c3c3c3c2c24448c6ccc18102448346c9c78e84c386ca480f424344434284c58408018242c7054a43c2c585c4c2024203c24183414102010182048346850441c2c2448'
VN_AF[comet]='CKGAALDGABIJGABPAGACWJGABQMGABZIGAD|BEGAECKGAALDGABEGGAFIJGAFPAGACYGGAFWJGAFQMGABZIGAD|BEGAGCKGAAJAGAHLDGAFEGGABPAGACTEGAFYGGABQMGABKLGAFZIGAI|BEGAGCKGAAJAGAJEGGABPAGACTEGABYGGABQMGABKLGAB|BEGAGFHGAFCKGAKJAGAJEGGABNBGAFPAGALTEGABYGGABULGAFQMGAFKLGAB|BEGAEFHGABJAGAJGMGAMEGGAFNBGABTEGABXDGAKYGGAFULGABKLGABAHGAN|FHGABJAGAJGMGAONBGABTEGABXDGAAULGABKLGABAHGAP|FHGABHCGAFJAGAHGMGAONBGABRCGAFTEGAFXDGAAULGABMNGAQKLGAFAHGAP|FHGAFHCGABGMGAOIJGAFNBGAFRCGABXDGAAWJGAFULGAFMNGARAHGAP|HCGABGMGAOIJGABRCGABXDGAAWJGABMNGARAHGAP|HCGABLDGAFGMGAMIJGABRCGABXDGAKWJGABMNGARZIGAIAHGAN|CKGAKHCGAFLDGABIJGABPAGALRCGAFWJGABQMGAFMNGAQZIGAD|CKGAALDGABIJGABPAGACWJGABQMGABZIGAD|BEGAECKGAALDGABEGGAFIJGAFPAGACYGGAFWJGAFQMGABZIGAD|BEGAGCKGAAJAGAHLDGAFEGGABPAGACTEGAFYGGABQMGABKLGAFZIGAI|BEGAGCKGAAJAGAJEGGABPAGACTEGABYGGABQMGABKLGAB|BEGAGFHGAFCKGAKJAGAJEGGABNBGAFPAGALTEGABYGGABULGAFQMGAFKLGAB|BEGAEFHGABJAGAJGMGAMEGGAFNBGABTEGABXDGAKYGGAFULGABKLGABAHGAN|FHGABJAGAJGMGAONBGABTEGABXDGAAULGABKLGABAHGAP|FHGABHCGAFJAGAHGMGAONBGABRCGAFTEGAFXDGAAULGABMNGAQKLGAFAHGAP|FHGAFHCGABGMGAOIJGAFNBGAFRCGABXDGAAWJGAFULGAFMNGARAHGAP|HCGABGMGAOIJGABRCGABXDGAAWJGABMNGARAHGAP|HCGABLDGAFGMGAMIJGABRCGABXDGAKWJGABMNGARZIGAIAHGAN|CKGAKHCGAFLDGABIJGABPAGALRCGAFWJGABQMGAFMNGAQZIGAD|CKGAALDGABIJGABPAGACWJGABQMGABZIGAD|BEGAECKGAALDGABEGGAFIJGAFPAGACYGGAFWJGAFQMGABZIGAD|BEGAGCKGAAJAGAHLDGAFEGGABPAGACTEGAFYGGABQMGABKLGAFZIGAI|BEGAGCKGAAJAGAJEGGABPAGACTEGABYGGABQMGABKLGAB|BEGAGFHGAFCKGAKJAGAJEGGABNBGAFPAGALTEGABYGGABULGAFQMGAFKLGAB|BEGAEFHGABJAGAJGMGAMEGGAFNBGABTEGABXDGAKYGGAFULGABKLGABAHGAN|FHGABJAGAJGMGAONBGABTEGABXDGAAULGABKLGABAHGAP|FHGABHCGASJAGATGMGAONBGABRCGAFTEGAFXDGAAULGABMNGAQKLGAFAHGAP|FHGAFHCGAUGMGAOIJGAFNBGAFRCGABXDGAAWJGAFULGAFMNGARAHGAP|HCGAVGMGAOIJGABRCGABXDGAAWJGABMNGARAHGAPFBlAW|HCGAXLDGASGMGAMIJGABRCGABXDGAKWJGABMNGARZIGAIAHGANHClAXGCIAYECIAS|CKGAKHCGASLDGAUIJGABPAGALRCGAFWJGABQMGAFMNGAQZIGADIClAXHCIAYFCIAS|CKGAALDGAYIJGABPAGACWJGABQMGABZIGADKDlAXJDIAYHDIASGCIASECGAZ|BEGAECKGAALDGAXEGGAFIJGAFPAGAaYGGAFWJGAFQMGABZIGADLDlAXKDIAYIDIASHCIASFCGAZ|BEGAGCKGAAJAGATLDGASEGGABPAGAbTEGASYGGABQMGABKLGAFZIGAINDlAXMDIAYKDIASJCIASHCGAZGBGAc|BEGAGCKGAAJAGAJEGGABPAGACTEGAdYGGABQMGABKLGABOElAXNEIAYLEIASKDIASIDGAZHCGAeFCGAfECGAf|BEGAGFHGAFCKGAKJAGAJEGGABNBGASPAGALTEGAVYGGABULGAFQMGAFKLGABQElAXPEIAYNEIASMDIASKDGAZJCGAeHCGAfGCGAf|BEGAEFHGABJAGAJGMGAMEGGAFNBGABTEGAVXDGAgYGGASULGABKLGABAHGANRFlAXQFIAYOFIASNEIASLEGAZKDGAeIDGAfHDGAf|FHGABJAGAJGMGAONBGABTEGAhXDGAiULGABKLGABAHGAPTFlAXSFIAYQFIASPEIASNEGAZMDGAeKDGAfJDGAf|FHGABHCGAFJAGAHGMGAONBGABRCGASTEGASXDGAjULGABMNGAQKLGAFAHGAPUFlAXTFIAYRFIASQEIASOEGAZNDGAeLDGAfKDGAf|FHGAFHCGABGMGAOIJGAFNBGAFRCGABXDGAiWJGASULGAFMNGARAHGAPWGlAXVGIAYTGIASSFIASQFGAZPEGAeNEGAfMEGAf|HCGABGMGAOIJGABRCGABXDGAiWJGAkMNGARAHGAPXGlAXWGIAYUGIASTFIASRFGAZQEGAeOEGAfNEGAf|HCGABLDGAFGMGAMIJGABRCGABXDGAKWJGABMNGARZIGAIAHGAN|CKGAKHCGAFLDGABIJGABPAGALRCGAFWJGABQMGAFMNGAQZIGAD'
VN_AL[comet]='||||||||||||||||||||||||||LPAFBGI|MPAFBGI|OPAFBGI|PQAFBGI|RQAFBGI|SRAFBGI|URAFBGI|VRAFBGI|XSAFBGI|YSAFBGI|aTAFBGI|bTAFBGI|dTAFBGI|eUAFBGI|gUAFBGI|hVAFBGI|jVAFBGI|kVAFBGI|mWAFBGI|nWAFBGI||'
VN_APAL[comet]='ccccccffffffd0d0d0808080a0b0c4cfe8ffc4c4c48898a8687480a8a8a8a4b8cca8bcd0c4dcf48c9cacf4f4f4acacacc8e0f8f8f8f8cce8fc8498a4ecf4fce8f4fc808c94dcecfce0f0fc98bce8c8ccccc8c8cc88b0dcf0f8fc8fb8e84a6a9aa4b8c8e4f0fcc4c4c8c0c4c8f4f8fc'
VN_AF[blackhole]='YGmAAYHnAAYIJAAXJpAAWKDABVLrABULDACTMrADSMpACRMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoACTBCADUCqACVCCABWDqAKXEoAAYFOAAYGGALDJHAMSDGANKKJAOMDIAPPJJAQ|YGmAAYHnAAYIJAAXJpAAWKDAKVLrABULDABTMrADSMpACRMDACQNrASPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCADUCqACVCCACWDqABXEoAKYFOAAYIHATDIHAMTEGANJKJAONDIAPOJJAQ|YGmAAYHnAAYIJAAXJpAAWKDAAVLrAUULDAUTMrAVSMpACRMDACQNrASPNJAWONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqACVCCACWDqACXEoABYFOAXXJHATDHHANUFGAYIJJAOOEIAPNJJAQ|YGmAKYHnAAYIJAAXJpAAWKDAAVLrAAULDAZTMrAaSMpABRMDACQNrASPNJAWONrAbNNpAcMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCACWDqACXEoABYFOABVKHAdDFGANVGIAeHJJAOPEIAPMJJAQ|YGmABYHnAKYIJAAXJpAAWKDAAVLrAAULDAATMrAfSMpAXRMDAKQNrAgPNJAWONrAbNNpAcMNnAcLNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqACXEoACYFOABULHAdEEGANVGIAOGIJAOQEIAPLJJAQ|YGmABYHnAKYIJAhXJpAAWKDAAVLrAAULDAATMrAiSMpAXRMDAKQNrAgPNJAjONrAbNNpAcMNnAcLNrAbKNXAWJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoACYFOACSMHAkFDGANUHJAlGHJAPRFIAP|YGmACYHnABYIJAUXJpAAWKDAAVLrAAULDAATMrAiSMpAARMDAhQNrAmPNJAnONrAoNNpApMNnAcLNrAbKNXAWJNrASIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoACYFOACQMHAkGDGANUIJAlGHJAPRFIAP|YGmACYHnACYIJABXJpAUWKDAAVLrAAULDAATMrAiSMpAARMDAAQNrAqPNJArONrAsNNpAtMNnAuLNrAbKNXAWJNrASIMDACHMnACGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOACOMHAkICGANTJJAvHGIAPRGIAQ|YGmACYHnACYIJACXJpABWKDAXVLrAAULDAATMrAiSMpAARMDAAQNrAqPNJAwONrAxNNpAyMNnAtLNrAzKNXAjJNrASIMDACHMnACGMrADFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAELMHA0KCGANRKJA1HFIAPRGIAQSBGAM|YGmAEYHnACYIJACXJpABWKDAKVLrAhULDAATMrAiSMpAARMDAAQNrAqPNJAwONrA2NNpA3MNnAyLNrA4KNXAnJNrAgIMDACHMnACGMrADFLDACELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEJMHAMMCGANQKJA1IFIAPRHJAQUCGAM|YGmAEYHnAEYIJACXJpACWKDABVLrAUULDAKTMrAiSMpAARMDAAQNrAqPNJAwONrA2NNpA3MNnA3LNrA5KNXA6JNrA7IMDAUHMnABGMrADFLDACELrACDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEILHANNCGANPKJAvJEIAPQHJAQVDGAM|YGmAEYHnAEYIJAEXJpACWKDACVLrABULDAUTMrA8SMpAARMDAAQNrAqPNJAwONrA2NNpA3MNnA3LNrA2KNXAwJNrA7IMDAKHMnAUGMrAVFLDACELrACDKDACCJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEGKHANPCIANNKJAlKEIAPQIJAQWEGAM|YGmAEYHnAEYIJAEXJpACWKDACVLrACULDABTMrAaSMpAKRMDAXQNrAqPNJAwONrA2NNpA3MNnA3LNrA2KNXAwJNrAqIMDAhHMnAXGMrA9FLDABELrACDKDACCJnACBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEFKHANRDIAOMKJAvLEIAPPIJAQXFGAM|YGmAEYHnAEYIJAEXJpAEWKDACVLrACULDACTMrAVSMpAURMDAKQNrA7PNJAwONrA2NNpA3MNnA3LNrA2KNXAwJNrAqIMDAAHMnAAGMrA8FLDAUELrABDKDACCJnACBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEEJHANSDIAOLKJA+MEIAPXGGAM|YGmAEYHnAEYIJAEXJpAEWKDAEVLrACULDACTMrADSMpABRMDAUQNrA7PNJA6ONrA5NNpA3MNnA3LNrA2KNXAwJNrAqIMDAAHMnAAGMrAiFLDAKELrAUDKDABCJnACBIXACBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEEIHANTEIAOJKJA+NEIAPXIHAM|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDACTMrADSMpACRMDACQNrAgPNJAnONrA4NNpAyMNnA3LNrA2KNXAwJNrAqIMDAAHMnAAGMrAiFLDAAELrAhDKDAKCJnABBIXACBHpACBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEEHHANTFIAOIJJA+OEIAQWJHAM|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrADSMpACRMDACQNrASPNJAjONrAzNNpAtMNnAyLNrAxKNXAwJNrAqIMDAAHMnAAGMrAiFLDAAELrAADKDAXCJnABBIXACBHpACBGoACBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEEFGANUGIAOIIJAPPEIAQHBGAMVKHAM|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpACRMDACQNrASPNJAWONrAbNNpAuMNnAtLNrAsKNXArJNrAqIMDAAHMnAAGMrAiFLDAAELrAADKDAACJnAUBIXABBHpACBGoACBFYACCEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEFFGANUHJAOHIJAPPFIAQJBGAMTLHAM|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrASPNJAWONrAbNNpAcMNnApLNrAoKNXAnJNrAmIMDAhHMnAAGMrAiFLDAAELrAADKDAACJnAABIXAUBHpABBGoACBFYACCEmACDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEGEGANTHJAOHHJAPQFIAQLAGA/RLHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAWONrAbNNpAcMNnAcLNrAbKNXAjJNrAgIMDAKHMnAXGMrAiFLDAAELrAADKDAACJnAABIXAhBHpAKBGoABBFYACCEmACDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEHDIANTIJAOHHJBAQGIAQOAGA/PMHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAcMNnAcLNrAbKNXAWJNrAgIMDAKHMnAXGMrAfFLDAAELrAADKDAACJnAABIXAABHpAKBGoABBFYABCEmACDDqACECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEIDIAOSJJAOHGIAPQGIAQQBGAMNMHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAcLNrAbKNXAWJNrASIMDACHMnABGMrAaFLDAZELrAADKDAACJnAABIXAABHpAABGoAKBFYABCEmABDDqACECCACFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEKCIAORJJAPIFIAPSBGAMMMHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAWJNrASIMDACHMnACGMrAVFLDAUELrAUDKDAACJnAABIXAABHpAABGoAABFYAXCEmABDDqACECCACFCqACGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEMCIAOQKJAPJFIAPTCGAMKLHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrASIMDACHMnACGMrADFLDABELrABDKDAKCJnAABIXAABHpAABGoAABFYAACEmAKDDqABECCACFCqACGBCADHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAENCIAOOKJAPJFIAQVDGAMILHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnACGMrADFLDACELrABDKDAKCJnAABIXAABHpAABGoAABFYAACEmAADDqABECCABFCqACGBCADHBmACIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEPDIAONKJAPKEIAQBHHALWEGAMHKHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrADFLDACELrACDKDABCJnAKBIXAABHpAABGoAABFYAACEmAADDqAKECCABFCqABGBCADHBmACIBqACJACASKAYAGLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEQDIAOMKJAPLEIAQBFGATWFGAMGJHAN|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDACELrACDKDACCJnABBIXAXBHpAABGoAABFYAACEmAADDqAAECCAUFCqAUGBCAVHBmACIBqACJACASKAYAWLACAHMAmAINAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAEREIAOLJJAPMEIAQCEGATWGGANFIHAY|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrACDKDACCJnABBIXABBHpAKBGoAABFYAACEmAADDqAAECCAAFCqAZGBCAaHBmABIBqACJACASKAYAWLACAbMAmAcNAoAIOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAESEIAOKJJAPNEIAQEDGAdWIHANEHJAe|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDACCJnACBIXABBHpABBGoAKBFYAACEmAADDqAAECCAAFCqAAGBCAfHBmAXIBqAKJACAgKAYAWLACAbMAmAcNAoAcOACAHPAOAGQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAETFIAOJJJAPOEIAQFCGAdVJHANEHJAO|YGmAEYHnAEYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnACBIXACBHpABBGoAKBFYAhCEmAADDqAAECCAAFCqAAGBCAiHBmAXIBqAKJACAgKAYAjLACAbMAmAcNAoAcOACAbPAOAWQACAFRBqAESBoAETBCAJUCqAEVCCAEWDqAEXEoAEYFOAETGIAPIIJAPHBGAkUKHANFGIAl|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|YGmACYHnACYIJAEXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCADHBmACIBqACJACASKAYAjLACAzMAmAtNAoAyOACAxPAOAwQACAqRBqAASBoAATBCAiUCqAAVCCAAWDqAXXEoABYFOACKJJAQSMHAMEDGAMVIHANFHJAORFIAP|YGmACYHnACYIJACXJpAEWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmACIBqACJACASKAYAWLACAbMAmAuNAoAtOACAsPAOArQACAqRBqAASBoAATBCAiUCqAAVCCAAWDqAAXEoAUYFOABKIJAQQMHAMGCGAMUIHANFHJAOSFIAP|YGmABYHnACYIJACXJpACWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACASKAYAWLACAbMAmAcNAoApOACAoPAOAnQACAmRBqAhSBoAATBCAiUCqAAVCCAAWDqAAXEoAAYFOAUJIJAQONHA/ICGANTJHANGGIAOSGIAP|YGmAKYHnABYIJACXJpACWKDAEVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAWLACAbMAmAcNAoAcOACAbPAOAjQACAgRBqAKSBoAXTBCAiUCqAAVCCAAWDqAAXEoAAYFOAhJHJAQLNHA/KBGANSKJANGFIAOSGIBA|YGmAKYHnABYIJABXJpACWKDACVLrAEULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAcNAoAcOACAbPAOAWQACAgRBqAKSBoAXTBCAfUCqAAVCCAAWDqAAXEoAAYFOAAJHJAQJMHAMMBGANRKJAOHEIAOSHJAP|YGmAAYHnAKYIJABXJpABWKDACVLrACULDAETMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAcOACAbPAOAWQACASRBqACSBoABTBCAaUCqAZVCCAAWDqAAXEoAAYFOAAHMHAMNBGANPLJAOIEIAPRIJAP|YGmAAYHnAAYIJAXXJpABWKDACVLrACULDACTMrAJSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAWQACASRBqACSBoACTBCAVUCqAUVCCAUWDqAAXEoAAYFOAAGLHAMPCGANNLJAOJDIAPQIJAP|YGmAAYHnAAYIJAAXJpAKWKDABVLrACULDACTMrADSMpAERMDAEQNrAFPNJAGONrAHNNpAIMNnAILNrAHKNXAGJNrAFIMDAEHMnAEGMrAJFLDAEELrAEDKDAECJnAEBIXAEBHpAEBGoAEBFYAECEmAEDDqAEECCAEFCqAEGBCAJHBmAEIBqAEJACAFKAYAGLACAHMAmAINAoAIOACAHPAOAGQACASRBqACSBoACTBCADUCqABVCCABWDqAKXEoAAYFOAAEKHAMRCGANMLJAOLDIAPQIJAQ'
VN_AL[blackhole]='oWARBLI|oXARBLI|oYARBLI|nZARBLI|maARBLI|maARBLI|lbARBLI|jcARBLI|icARBLI|hcARBLI|fdARBLI|edARBLI|cdARBLI|bdARBLI|adARBLI|YcARBLI|XcARBLI|WcARBLI|UbARBLI|TaARBLI|TaARBLI|SZARBLI|RYARBLI|RXARBLI|RXARBLI|RWARBLI|RVARBLI|SUARBLI|TTARBLI|TTARBLI|USARBLI|WRARBLI|XRARBLI|YRARBLI|aQARBLI|bQARBLI|cQARBLI|eQARBLI|fQARBLI|hRARBLI|iRARBLI|jRARBLI|lSARBLI|mTARBLI|mTARBLI|nUARBLI|oVARBLI|oWARBLI'
VN_APAL[blackhole]='fcf0d8ffb0e0a86ae8a064dc5a3a9a382464482c7c50348c543894543490fcb8dcfcf0e0ffffffcfe8ff8fb8e84a6a9a2a3a5afff0d86c4498fcf4e8fcb4dcf4a8d48854bcfcbcdcd0e8fcfcc0dcf0acd09c60d4a464e0fcf4ecd4e8f8f0b8d0a87494fcc4dcf0e4ccd090b4fcf8f4a0c0e4a47890cc90b4eca0d0f8a8d8a49c8ccca0b4e8acccf4b0d4f4acd4a4c0e4ccc4b0e8b4ccf4b4d4e8a4ccfcfcf8b4cce0e8dcc8f4e8d0e8a8cce8b8cccc9cb4a47c90f0b4d0f0b0d06880a4ececec54709c'
VN_AF[meteor]='UFlAAVFiABWEiACXEiACMJlAANJiABOIiACPIiACQHiADRHGADSGGAETGGAFGMiAGHMiACILiADJLGADKKGAELKGAF|TFlAAUFiABVEiACWEiACXDiAILJlAAMJiABNIiACOIiACPHiADQHGADRGGAESGGAFFMiAJGMiAGHLiADILGADJKGAEKKGAF|SGlAATGiABUFiACVFiACWEiADXEGADKKlAALKiABMJiACNJiACOIiADPIGADQHGAERHGAFGMiAKHMGADILGAEJLGAF|RGlAASGiABTFiACUFiACVEiADWEGADXDGALJKlAAKKiABLJiACMJiACNIiADOIGADPHGAEQHGAF|QHlAARHiABSGiACTGiACUFiADVFGADWEGAEXEGAFILlAAJLiABKKiACLKiACMJiADNJGADOIGAEPIGAF|XDkAMPHlAAQHiABRGiACSGiACTFiADUFGADVEGAEWEGAFHLlAAILiABJKiACKKiACLJiADMJGADNIGAEOIGAF|WEkAAXEiABOIlAAPIiABQHiACRHiACSGiADTGGADUFGAEVFGAFGMlANHMiABILiACJLiACKKiADLKGADMJGAENJGAF|VEkAAWEiABXDiAONIlAAOIiABPHiACQHiACRGiADSGGADTFGAEUFGAFFMkAPGMiAQHLiACILiACJKiADKKGADLJGAEMJGAF|UFlAAVFiABWEiACXEiACMJlAANJiABOIiACPIiACQHiADRHGADSGGAETGGAFGMiAGHMiACILiADJLGADKKGAELKGAF|TFlAAUFiABVEiACWEiACXDiAILJlAAMJiABNIiACOIiACPHiADQHGADRGGAESGGAFFMiAJGMiAGHLiADILGADJKGAEKKGAF|SGlAATGiABUFiACVFiACWEiADXEGADKKlAALKiABMJiACNJiACOIiADPIGADQHGAERHGAFGMiAKHMGADILGAEJLGAF|RGlAASGiABTFiACUFiACVEiADWEGADXDGALJKlAAKKiABLJiACMJiACNIiADOIGADPHGAEQHGAF|QHlAARHiABSGiACTGiACUFiADVFGADWEGAEXEGAFILlAAJLiABKKiACLKiACMJiADNJGADOIGAEPIGAF|PHlAAQHiABRGiACSGiACTFiADUFGADVEGAEWEGAFHLlAAILiABJKiACKKiACLJiADMJGADNIGAEOIGAFXDkAM|OIlAAPIiABQHiACRHiACSGiADTGGADUFGAEVFGAFGMlANHMiABILiACJLiACKKiADLKGADMJGAENJGAFWEkAAXEiAB|NIlAAOIiABPHiACQHiACRGiADSGGADTFGAEUFGAFFMkAPGMiAQHLiACILiACJKiADKKGADLJGAEMJGAFVEkAAWEiABXDiAO|MJlAANJiABOIiACPIiACQHiADRHGADSGGAETGGAFGMiAGHMiACILiADJLGADKKGAELKGAFUFlAAVFiABWEiACXEiAC|LJlAAMJiABNIiACOIiACPHiADQHGADRGGAESGGAFFMiAJGMiAGHLiADILGADJKGAEKKGAFTFlAAUFiABVEiACWEiACXDiAI|KKlAALKiABMJiACNJiACOIiADPIGADQHGAERHGAFGMiAKHMGADILGAEJLGAFSGlAATGiABUFiACVFiACWEiADXEGAD|JKlAAKKiABLJiACMJiACNIiADOIGADPHGAEQHGAFRGlAASGiABTFiACUFiACVEiADWEGADXDGAL|ILlAAJLiABKKiACLKiACMJiADNJGADOIGAEPIGAFQHlAARHiABSGiACTGiACUFiADVFGADWEGAEXEGAF|HLlAAILiABJKiACKKiACLJiADMJGADNIGAEOIGAFXDkAMPHlAAQHiABRGiACSGiACTFiADUFGADVEGAEWEGAF|GMlANHMiABILiACJLiACKKiADLKGADMJGAENJGAFWEkAAXEiABOIlAAPIiABQHiACRHiACSGiADTGGADUFGAEVFGAF|FMkAPGMiAQHLiACILiACJKiADKKGADLJGAEMJGAFVEkAAWEiABXDiAONIlAAOIiABPHiACQHiACRGiADSGGADTFGAEUFGAF|GMiAGHMiACILiADJLGADKKGAELKGAFUFlAAVFiABWEiACXEiACMJlAANJiABOIiACPIiACQHiADRHGADSGGAETGGAF|FMiAJGMiAGHLiADILGADJKGAEKKGAFTFlAAUFiABVEiACWEiACXDiAILJlAAMJiABNIiACOIiACPHiADQHGADRGGAESGGAF|GMiAKHMGADILGAEJLGAFSGlAATGiABUFiACVFiACWEiADXEGADKKlAALKiABMJiACNJiACOIiADPIGADQHGAERHGAF|RGlAASGiABTFiACUFiACVEiADWEGADXDGALJKlAAKKiABLJiACMJiACNIiADOIGADPHGAEQHGAF|QHlAARHiABSGiACTGiACUFiADVFGADWEGAEXEGAFILlAAJLiABKKiACLKiACMJiADNJGADOIGAEPIGAF|XDkAMPHlAAQHiABRGiACSGiACTFiADUFGADVEGAEWEGAFHLlAAILiABJKiACKKiACLJiADMJGADNIGAEOIGAF|WEkAAXEiABOIlAAPIiABQHiACRHiACSGiADTGGADUFGAEVFGAFGMlANHMiABILiACJLiACKKiADLKGADMJGAENJGAF|VEkAAWEiABXDiAONIlAAOIiABPHiACQHiACRGiADSGGADTFGAEUFGAFFMkAPGMiAQHLiACILiACJKiADKKGADLJGAEMJGAF|UFlAAVFiABWEiACXEiACMJlAANJiABOIiACPIiACQHiADRHGADSGGAETGGAFGMiAGHMiACILiADJLGADKKGAELKGAF|TFlAAUFiABVEiACWEiACXDiAILJlAAMJiABNIiACOIiACPHiADQHGADRGGAESGGAFFMiAJGMiAGHLiADILGADJKGAEKKGAF|SGlAATGiABUFiACVFiACWEiADXEGADKKlAALKiABMJiACNJiACOIiADPIGADQHGAERHGAFGMiAKHMGADILGAEJLGAF|RGlAASGiABTFiACUFiACVEiADWEGADXDGALJKlAAKKiABLJiACMJiACNIiADOIGADPHGAEQHGAF|QHlAARHiABSGiACTGiACUFiADVFGADWEGAEXEGAFILlAAJLiABKKiACLKiACMJiADNJGADOIGAEPIGAF|XDkAMPHlAAQHiABRGiACSGiACTFiADUFGADVEGAEWEGAFHLlAAILiABJKiACKKiACLJiADMJGADNIGAEOIGAF|WEkAAXEiABOIlAAPIiABQHiACRHiACSGiADTGGADUFGAEVFGAFGMlANHMiABILiACJLiACKKiADLKGADMJGAENJGAF|VEkAAWEiABXDiAONIlAAOIiABPHiACQHiACRGiADSGGADTFGAEUFGAFFMkAPGMiAQHLiACILiACJKiADKKGADLJGAEMJGAF|UFlAAVFiABWEiACXEiACMJlAANJiABOIiACPIiACQHiADRHGADSGGAETGGAFGMiAGHMiACILiADJLGADKKGAELKGAF|TFlAAUFiABVEiACWEiACXDiAILJlAAMJiABNIiACOIiACPHiADQHGADRGGAESGGAFFMiAJGMiAGHLiADILGADJKGAEKKGAF|SGlAATGiABUFiACVFiACWEiADXEGADKKlAALKiABMJiACNJiACOIiADPIGADQHGAERHGAFGMiAKHMGADILGAEJLGAF|RGlAASGiABTFiACUFiACVEiADWEGADXDGALJKlAAKKiABLJiACMJiACNIiADOIGADPHGAEQHGAF|QHlAARHiABSGiACTGiACUFiADVFGADWEGAEXEGAFILlAAJLiABKKiACLKiACMJiADNJGADOIGAEPIGAF|XDkAMPHlAAQHiABRGiACSGiACTFiADUFGADVEGAEWEGAFHLlAAILiABJKiACKKiACLJiADMJGADNIGAEOIGAF|WEkAAXEiABOIlAAPIiABQHiACRHiACSGiADTGGADUFGAEVFGAFGMlANHMiABILiACJLiACKKiADLKGADMJGAENJGAF|VEkAAWEiABXDiAONIlAAOIiABPHiACQHiACRGiADSGGADTFGAEUFGAFFMkAPGMiAQHLiACILiACJKiADKKGADLJGAEMJGAF'
VN_AL[meteor]='kVAHAtFcZAHAtFUdAHAtF|jVAHAtFbZAHAtFTdAHAtF|iWAHAtFaaAHAtF|pSAHAtFhWAHAtFZaAHAtF|oTAHAtFgXAHAtFYbAHAtF|nTAHAtFfXAHAtFXbAHAtF|mUAHAtFeYAHAtFWcAHAtF|lUAHAtFdYAHAtFVcAHAtF|kVAHAtFcZAHAtFUdAHAtF|jVAHAtFbZAHAtFTdAHAtF|iWAHAtFaaAHAtF|hWAHAtFZaAHAtFpSAHAtF|gXAHAtFYbAHAtFoTAHAtF|fXAHAtFXbAHAtFnTAHAtF|eYAHAtFWcAHAtFmUAHAtF|dYAHAtFVcAHAtFlUAHAtF|cZAHAtFUdAHAtFkVAHAtF|bZAHAtFTdAHAtFjVAHAtF|aaAHAtFiWAHAtF|ZaAHAtFpSAHAtFhWAHAtF|YbAHAtFoTAHAtFgXAHAtF|XbAHAtFnTAHAtFfXAHAtF|WcAHAtFmUAHAtFeYAHAtF|VcAHAtFlUAHAtFdYAHAtF|UdAHAtFkVAHAtFcZAHAtF|TdAHAtFjVAHAtFbZAHAtF|iWAHAtFaaAHAtF|pSAHAtFhWAHAtFZaAHAtF|oTAHAtFgXAHAtFYbAHAtF|nTAHAtFfXAHAtFXbAHAtF|mUAHAtFeYAHAtFWcAHAtF|lUAHAtFdYAHAtFVcAHAtF|kVAHAtFcZAHAtFUdAHAtF|jVAHAtFbZAHAtFTdAHAtF|iWAHAtFaaAHAtF|pSAHAtFhWAHAtFZaAHAtF|oTAHAtFgXAHAtFYbAHAtF|nTAHAtFfXAHAtFXbAHAtF|mUAHAtFeYAHAtFWcAHAtF|lUAHAtFdYAHAtFVcAHAtF|kVAHAtFcZAHAtFUdAHAtF|jVAHAtFbZAHAtFTdAHAtF|iWAHAtFaaAHAtF|pSAHAtFhWAHAtFZaAHAtF|oTAHAtFgXAHAtFYbAHAtF|nTAHAtFfXAHAtFXbAHAtF|mUAHAtFeYAHAtFWcAHAtF|lUAHAtFdYAHAtFVcAHAtF'
VN_APAL[meteor]='fce8d4fcecdcfcd0a0c98a5a906440986844f0c498ffd0a0a06c4894785cc08454705030c8b8a8f0dcc8c8a48094887cf0e0d0'
VN_AF[warp]='IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP|IAqAAJBUABRBUABKCUABQCUABECAACWCAADJDUABRDUABDDAACXDAAEMEUAFOEUAFGEqAGUEqAGHFqAGTFqAGBFAAHZFAAIIGqAJSGqAJCGAACYGAACHHqAJTHqAJBHAAHZHAAKMIUALOIUALGIqAGUIqAGAIAAIHJqAGTJqAGBJAAMIKqAGSKqAGCKAAEJLUABRLUABDLAADMMUABOMUABGMqANUMqAOLNUAPPNUAQ|IBqAGSBqAGJCUABRCUABDCAADIDqAGSDqAGCDAAELEUAFPEUAFFEqACVEqACMFUAROFUARGFqAGUFqAGAFAAIHGqAJTGqAJBGAAHZGAAKMHUASOHUASGHqAGUHqAGAHAAKLIUATPIUATFIqACVIqACMJUAROJUARGJqAGUJqAGHKqAGTKqAGILqAGSLqAGLMUABPMUABFMqAUKNUAQQNUAV|MAUAWOAUAPHBqAGTBqANICqAGSCqAGHDqAGTDqAGKEUABQEUABEEAACWEAACLFUAXPFUAXFFqACVFqACMGUALOGUALGGqAGUGqAGAGAAKLHUALPHUALFHqACVHqACKIUARQIUAREIAACWIAACLJUAXPJUAXFJqACVJqACMKUAFOKUAFGKqAGUKqAGHLqAGTLqAGKMUABQMUABJNUAVRNUAY|LAUAPPAUAQMBUABOBUABGBqANUBqAOHCqAGTCqAGMDUABODUABGDqAGUDqAGJEUABREUABDEAACXEAACKFUAZQFUAZEFAACWFAACLGUATPGUATFGqACVGqACKHUATQHUATEHAACWHAACJIUAXRIUAXDIAACXIAACKJUAZQJUAZEJAACWJAACLKUAFPKUAFFKqACVKqACMLUABOLUABGLqAGULqAGJMUABRMUABINqAA|KAUAQQAUAVLBUABPBUABFBqAUMCUABOCUABGCqAGUCqAGLDUABPDUABFDqACVDqACIEqAGSEqAGCEAACYEAAaJFUAZRFUAZDFAACXFAACKGUARQGUAREGAACWGAACJHUARRHUARDHAACXHAACIIqAJSIqAJCIAACYIAACJJUAZRJUAZDJAACXJAACKKUABQKUABEKAACWKAACLLUABPLUABFLqACVLqACIMqAGSMqAG|JAUAVRAUAYKBUABQBUABLCUABPCUABFCqACVCqACKDUABQDUABEDAACWDAACHEqAGTEqAGBEAAMIFqAJSFqAJCFAACYFAACJGUAXRGUAXDGAACXGAACIHqAJSHqAJCHAACYHAACHIqAJTIqAJBIAAHZIAAIIJqAJSJqAJCJAACYJAAaJKUABRKUABDKAACXKAAEKLUABQLUABELAACWLAADHMqAGTMqANMNUAWONUAP'
VN_AL[warp]='dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH|dXAGAjH'
VN_APAL[warp]='546870ffffff5fd7ff3880984cacccfcfcfcbfe8ff2a6a9a14344cbce8fc1c4868ecf8fc205074b4dcf4708894ecececd0d0d0f4f8fce8f8fcf0f8fc387c94a8a8a8f8f8f8f4fcfc707070f8fcfc48a4c4'
VN_AF[nebula]='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'
VN_AL[nebula]='kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H|kTArA8H'
VN_APAL[nebula]='180828441858803ca46024803c18503418546a2a8aa04ac85f8fff3a1a5a543c748050a07c549c382c4c385498685488906cb09874b88070a054206c2c14447460947c6c9c1c0c2c4c306ca864d078a0fcac70d48858a8604c80341844481c5c2cf4c834f4c838f0cca454cc7038904024603c1c5c6c30882af5c8602c78e8f0fcdfe8ff2410382c1448200c347c489c5c447c8c60acb480d8b888dc9c78bc4438587060908c80ac743c94644c8420103024103c6894fc743894ac6cd040185484a8fc8cacfc5440689068b0b88cdca488c46494fc4828687844985cf0d868f0d8b070d488acfc6090fc703490442864642884a45ccc7098fc50f0d07ca4fc6c2c8c34144430103c180c286c308c5c4878a050c8749cfc5034704060ac5024645020689844c054207068308448205840f0cc584c703048803c5ca8b074d81ca888147c643818549444b84c74d0341850a85ccc70508c44345c2840705884ec9064ac8450a09c48c06c88c89c94bcc098e494b4fc5c78c08458a45c28745888f4b09cd0a0bcfc74ecdc70ecdcc4a8e8603c7850346090b0fc68407ca468c85c88f824e0b828ecc0502864'
VN_AF[souls]='CEWAACFGABFEXAAFFGABHJIACHKGADIBIABICGABKNIAEKFIAFKGGAGOKWACOLGAHNCWABNDGABRKWACRLGAIRCWABRDGABUHIACUIGAJWLIAKYEGAL|DEWAADFGABELJANEDJAAEEGABIJIACIKGADHBIABHCGABLMWAOKEWAAKFGABPKWACPLGAPNCWABNDGABQJIACQKGAQSBIABSCGABTHIACTIGARWKWACWLGASXDGAT|DDIAADEGABFLJAOFMGASEDJABEEGABJIWACJJGAUMMWAOKEWAAKFGABPJIACPKGAVOBIABOCGABQJIACQKGAWRBIABRCGABTGWAXTHGAYWKWACWLGASWCWAZWDGAB|CDIATCEGABGKXACGLGARECXABEDGABJIWACJJGAaLLIAbLMGAcLDIAALEGABOJIACOKGAHPBIABPCGABQIWACQJGAVUGWAXUHGAdXJIACXKGAeWCGAZ|CKWAfFKXACFLGAIFCXABFDGABIHIACIIGAJKLIAbKMGAgMDIABMEGABNIWACNJGAURIWACRJGADVFIAXVGGAhYJIAiWCGAZ|DKWACDLGASEJJACEKGAQGBJAjGCGABHHIACHIGARKKWACKLGARLCWABLDGABNIWACNJGAcSHIACSIGAJVFIAFVGGAJXIWACXJGAU|DJIACDKGAVEJJACEKGAWFBJAkFCGABHGWAXHHGAYKKWACKLGARKCWABKDGABOHIACOIGADRHIACRIGAlTMWAmUEWAAUFGABWIWACWJGAJ|CJIACCKGAeDCGAZEIXACEJGAVIGWAXIHGAdLJIACLKGADKBIABKCGABPHIACPIGAnQGWAoQHGAIUMWApTEWAATFGAqWHIACWIGAJ|BIWACBJGArFIXACFJGADINIAsJFIAXJGGAhMJIACMKGADKBIABKCGABPGWAoPHGAtQGWAuQHGAtVLIAbTDIAATEGABWHIACWIGAJ|BIWACBJGAvGHJACGIGAJJFIAFJGGAJLIWACLJGAUOGWAXOHGADQFIAwQGGAtVLIAbUDIABUEGABXGWAXXHGAY|CHIACCIGADFHJACFIGAlHMWAOIEWAAIFGABKIWACKJGAJONIAxNFIAXNGGAhRNIAyRFIAXRGGAGUKWACULGARVCWABVDGABYGWAXYHGAY|DHIACDIGAnEGXAoEHGAIIMWAOHEWAAHFGAqKHIACKIGAJPNIAzNFIAFNGGAJQMWA0SEWAASFGABTKWACTLGA1VCWABVDGABXFIAXXGGAh|DGWAoDHGAtEGXAuEHGAtJLIAbJMGAcHDIAAHEGABKHIACKIGAJPMWA2OEWAAOFGABQMWA2REWAARFGABTJIACTKGADUBIAkUCGABWFIAFWGGAG|CGWAXCHGAYEFJAwEGGAtJLIAbJMGAVIDIABIEGABLGWAXLHGAYOMWA3PEWAAPFGA4QLIANQMGA5QDIAAQEGABUJIACUKGADTBIAjTCGABWEWAAWFGAB|BFIAXBGGAhFFJAXFGGAGIKWACILGARJCWABJDGABMGWAXMHGAYNLIA6NMGAaPDIAAPEGABRLIAORMGAcQDIABQEGABVIWACVJGAUWEWAAWFGAB|BFIAFBGGAGGEXAAGFGABHKWACHLGA1JCWABJDGABKNIAELFIAXLGGAhNLIAbNMGAVODIABOEGA7SKWACSLGARQCWABQDGABVIWACVJGAaXDIA8XEGAB|CEWAACFGABFEXAAFFGABHJIACHKGADIBIABICGABKNIAEKFIAFKGGAGOKWACOLGAHNCWABNDGABRKWACRLGAIRCWABRDGABUHIACUIGAJWLIAKYEGAL|DEWAADFGABELJANEDJAAEEGABIJIACIKGADHBIABHCGABLMWAOKEWAAKFGABPKWACPLGAPNCWABNDGABQJIACQKGAQSBIABSCGABTHIACTIGARWKWACWLGASXDGAT|DDIAADEGABFLJAOFMGASEDJABEEGABJIWACJJGAUMMWAOKEWAAKFGABPJIACPKGAVOBIABOCGABQJIACQKGAWRBIABRCGABTGWAXTHGAYWKWACWLGASWCWAZWDGAB|CDIATCEGABGKXACGLGARECXABEDGABJIWACJJGAaLLIAbLMGAcLDIAALEGABOJIACOKGAHPBIABPCGABQIWACQJGAVUGWAXUHGAdXJIACXKGAeWCGAZ|CKWAfFKXACFLGAIFCXABFDGABIHIACIIGAJKLIAbKMGAgMDIABMEGABNIWACNJGAURIWACRJGADVFIAXVGGAhYJIAiWCGAZ|DKWACDLGASEJJACEKGAQGBJAjGCGABHHIACHIGARKKWACKLGARLCWABLDGABNIWACNJGAcSHIACSIGAJVFIAFVGGAJXIWACXJGAU|DJIACDKGAVEJJACEKGAWFBJAkFCGABHGWAXHHGAYKKWACKLGARKCWABKDGABOHIACOIGADRHIACRIGAlTMWAmUEWAAUFGABWIWACWJGAJ|CJIACCKGAeDCGAZEIXACEJGAVIGWAXIHGAdLJIACLKGADKBIABKCGABPHIACPIGAnQGWAoQHGAIUMWApTEWAATFGAqWHIACWIGAJ|BIWACBJGArFIXACFJGADINIAsJFIAXJGGAhMJIACMKGADKBIABKCGABPGWAoPHGAtQGWAuQHGAtVLIAbTDIAATEGABWHIACWIGAJ|BIWACBJGAvGHJACGIGAJJFIAFJGGAJLIWACLJGAUOGWAXOHGADQFIAwQGGAtVLIAbUDIABUEGABXGWAXXHGAY|CHIACCIGADFHJACFIGAlHMWAOIEWAAIFGABKIWACKJGAJONIAxNFIAXNGGAhRNIAyRFIAXRGGAGUKWACULGARVCWABVDGABYGWAXYHGAY|DHIACDIGAnEGXAoEHGAIIMWAOHEWAAHFGAqKHIACKIGAJPNIAzNFIAFNGGAJQMWA0SEWAASFGABTKWACTLGA1VCWABVDGABXFIAXXGGAh|DGWAoDHGAtEGXAuEHGAtJLIAbJMGAcHDIAAHEGABKHIACKIGAJPMWA2OEWAAOFGABQMWA2REWAARFGABTJIACTKGADUBIAkUCGABWFIAFWGGAG|CGWAXCHGAYEFJAwEGGAtJLIAbJMGAVIDIABIEGABLGWAXLHGAYOMWA3PEWAAPFGA4QLIANQMGA5QDIAAQEGABUJIACUKGADTBIAjTCGABWEWAAWFGAB|BFIAXBGGAhFFJAXFGGAGIKWACILGARJCWABJDGABMGWAXMHGAYNLIA6NMGAaPDIAAPEGABRLIAORMGAcQDIABQEGABVIWACVJGAUWEWAAWFGAB|BFIAFBGGAGGEXAAGFGABHKWACHLGA1JCWABJDGABKNIAELFIAXLGGAhNLIAbNMGAVODIABOEGA7SKWACSLGARQCWABQDGABVIWACVJGAaXDIA8XEGAB|CEWAACFGABFEXAAFFGABHJIACHKGADIBIABICGABKNIAEKFIAFKGGAGOKWACOLGAHNCWABNDGABRKWACRLGAIRCWABRDGABUHIACUIGAJWLIAKYEGAL|DEWAADFGABELJANEDJAAEEGABIJIACIKGADHBIABHCGABLMWAOKEWAAKFGABPKWACPLGAPNCWABNDGABQJIACQKGAQSBIABSCGABTHIACTIGARWKWACWLGASXDGAT|DDIAADEGABFLJAOFMGASEDJABEEGABJIWACJJGAUMMWAOKEWAAKFGABPJIACPKGAVOBIABOCGABQJIACQKGAWRBIABRCGABTGWAXTHGAYWKWACWLGASWCWAZWDGAB|CDIATCEGABGKXACGLGARECXABEDGABJIWACJJGAaLLIAbLMGAcLDIAALEGABOJIACOKGAHPBIABPCGABQIWACQJGAVUGWAXUHGAdXJIACXKGAeWCGAZ|CKWAfFKXACFLGAIFCXABFDGABIHIACIIGAJKLIAbKMGAgMDIABMEGABNIWACNJGAURIWACRJGADVFIAXVGGAhYJIAiWCGAZ|DKWACDLGASEJJACEKGAQGBJAjGCGABHHIACHIGARKKWACKLGARLCWABLDGABNIWACNJGAcSHIACSIGAJVFIAFVGGAJXIWACXJGAU|DJIACDKGAVEJJACEKGAWFBJAkFCGABHGWAXHHGAYKKWACKLGARKCWABKDGABOHIACOIGADRHIACRIGAlTMWAmUEWAAUFGABWIWACWJGAJ|CJIACCKGAeDCGAZEIXACEJGAVIGWAXIHGAdLJIACLKGADKBIABKCGABPHIACPIGAnQGWAoQHGAIUMWApTEWAATFGAqWHIACWIGAJ|BIWACBJGArFIXACFJGADINIAsJFIAXJGGAhMJIACMKGADKBIABKCGABPGWAoPHGAtQGWAuQHGAtVLIAbTDIAATEGABWHIACWIGAJ|BIWACBJGAvGHJACGIGAJJFIAFJGGAJLIWACLJGAUOGWAXOHGADQFIAwQGGAtVLIAbUDIABUEGABXGWAXXHGAY|CHIACCIGADFHJACFIGAlHMWAOIEWAAIFGABKIWACKJGAJONIAxNFIAXNGGAhRNIAyRFIAXRGGAGUKWACULGARVCWABVDGABYGWAXYHGAY|DHIACDIGAnEGXAoEHGAIIMWAOHEWAAHFGAqKHIACKIGAJPNIAzNFIAFNGGAJQMWA0SEWAASFGABTKWACTLGA1VCWABVDGABXFIAXXGGAh|DGWAoDHGAtEGXAuEHGAtJLIAbJMGAcHDIAAHEGABKHIACKIGAJPMWA2OEWAAOFGABQMWA2REWAARFGABTJIACTKGADUBIAkUCGABWFIAFWGGAG|CGWAXCHGAYEFJAwEGGAtJLIAbJMGAVIDIABIEGABLGWAXLHGAYOMWA3PEWAAPFGA4QLIANQMGA5QDIAAQEGABUJIACUKGADTBIAjTCGABWEWAAWFGAB|BFIAXBGGAhFFJAXFGGAGIKWACILGARJCWABJDGABMGWAXMHGAYNLIA6NMGAaPDIAAPEGABRLIAORMGAcQDIABQEGABVIWACVJGAUWEWAAWFGAB|BFIAFBGGAGGEXAAGFGABHKWACHLGA1JCWABJDGABKNIAELFIAXLGGAhNLIAbNMGAVODIABOEGA7SKWACSLGARQCWABQDGABVIWACVJGAaXDIA8XEGAB'
VN_AL[souls]='TcAMAlFUcAMAkFXZAMAcFadAMAnFaVAMAPFeaAMAfFhaAMAeFkXAMAWFmbAMAhF|ScAMAkFUbAMAiFYZAMAbFbcAMAlFfaAMAeFgZAMAcFjXAMAVFmaAMAfF|RbAMAiFVbAMAhFZYAMAZFccAMAkFfZAMAcFgZAMAbFjWAMATFmaAMAeF|RbAMAhFWaAMAfFZYAMAYFbbAMAiFeZAMAbFgYAMAZFkWAMASFnZAMAcF|SaAMAfFVaAMAeFYXAMAWFabAMAhFdYAMAZFhYAMAYFkdAMAoFlVAMAQFoZAMAbF|TaAMAeFUZAMAcFXXAMAVFaaAMAfFdYAMAYFiXAMAWFjdAMAnFlVAMAPFnYAMAZF|TZAMAcFUZAMAbFXWAMATFaaAMAeFeXAMAWFhXAMAVFjcAMAlFmYAMAYF|SZAMAbFUYAMAZFYWAMASFbZAMAcFfXAMAVFgWAMATFkcAMAkFmXAMAWF|RYAMAZFVYAMAYFYdAMAoFZVAMAQFcZAMAbFfWAMATFgWAMASFlbAMAiFmXAMAVF|RYAMAYFWXAMAWFXdAMAnFZVAMAPFbYAMAZFeWAMASFidAMAoFgVAMAQFlbAMAhFnWAMATF|SXAMAWFVXAMAVFXcAMAlFaYAMAYFedAMAoFdVAMAQFhdAMAnFhVAMAPFkaAMAfFoWAMASF|TXAMAVFUWAMATFYcAMAkFaXAMAWFfdAMAnFdVAMAPFgcAMAlFjaAMAeFmdAMAoFnVAMAQF|TWAMATFUWAMASFZbAMAiFaXAMAVFfcAMAlFgcAMAkFjZAMAcFmdAMAnFmVAMAPF|SWAMASFWdAMAoFUVAMAQFZbAMAhFbWAMATFecAMAkFgbAMAiFkZAMAbFncAMAlF|SdAMAoFRVAMAQFVdAMAnFVVAMAPFYaAMAfFcWAMASFdbAMAiFhbAMAhFlYAMAZFocAMAkF|TdAMAnFRVAMAPFUcAMAlFXaAMAeFadAMAoFbVAMAQFdbAMAhFiaAMAfFlYAMAYFnbAMAiF|TcAMAlFUcAMAkFXZAMAcFadAMAnFaVAMAPFeaAMAfFhaAMAeFkXAMAWFmbAMAhF|ScAMAkFUbAMAiFYZAMAbFbcAMAlFfaAMAeFgZAMAcFjXAMAVFmaAMAfF|RbAMAiFVbAMAhFZYAMAZFccAMAkFfZAMAcFgZAMAbFjWAMATFmaAMAeF|RbAMAhFWaAMAfFZYAMAYFbbAMAiFeZAMAbFgYAMAZFkWAMASFnZAMAcF|SaAMAfFVaAMAeFYXAMAWFabAMAhFdYAMAZFhYAMAYFkdAMAoFlVAMAQFoZAMAbF|TaAMAeFUZAMAcFXXAMAVFaaAMAfFdYAMAYFiXAMAWFjdAMAnFlVAMAPFnYAMAZF|TZAMAcFUZAMAbFXWAMATFaaAMAeFeXAMAWFhXAMAVFjcAMAlFmYAMAYF|SZAMAbFUYAMAZFYWAMASFbZAMAcFfXAMAVFgWAMATFkcAMAkFmXAMAWF|RYAMAZFVYAMAYFYdAMAoFZVAMAQFcZAMAbFfWAMATFgWAMASFlbAMAiFmXAMAVF|RYAMAYFWXAMAWFXdAMAnFZVAMAPFbYAMAZFeWAMASFidAMAoFgVAMAQFlbAMAhFnWAMATF|SXAMAWFVXAMAVFXcAMAlFaYAMAYFedAMAoFdVAMAQFhdAMAnFhVAMAPFkaAMAfFoWAMASF|TXAMAVFUWAMATFYcAMAkFaXAMAWFfdAMAnFdVAMAPFgcAMAlFjaAMAeFmdAMAoFnVAMAQF|TWAMATFUWAMASFZbAMAiFaXAMAVFfcAMAlFgcAMAkFjZAMAcFmdAMAnFmVAMAPF|SWAMASFWdAMAoFUVAMAQFZbAMAhFbWAMATFecAMAkFgbAMAiFkZAMAbFncAMAlF|SdAMAoFRVAMAQFVdAMAnFVVAMAPFYaAMAfFcWAMASFdbAMAiFhbAMAhFlYAMAZFocAMAkF|TdAMAnFRVAMAPFUcAMAlFXaAMAeFadAMAoFbVAMAQFdbAMAhFiaAMAfFlYAMAYFnbAMAiF|TcAMAlFUcAMAkFXZAMAcFadAMAnFaVAMAPFeaAMAfFhaAMAeFkXAMAWFmbAMAhF|ScAMAkFUbAMAiFYZAMAbFbcAMAlFfaAMAeFgZAMAcFjXAMAVFmaAMAfF|RbAMAiFVbAMAhFZYAMAZFccAMAkFfZAMAcFgZAMAbFjWAMATFmaAMAeF|RbAMAhFWaAMAfFZYAMAYFbbAMAiFeZAMAbFgYAMAZFkWAMASFnZAMAcF|SaAMAfFVaAMAeFYXAMAWFabAMAhFdYAMAZFhYAMAYFkdAMAoFlVAMAQFoZAMAbF|TaAMAeFUZAMAcFXXAMAVFaaAMAfFdYAMAYFiXAMAWFjdAMAnFlVAMAPFnYAMAZF|TZAMAcFUZAMAbFXWAMATFaaAMAeFeXAMAWFhXAMAVFjcAMAlFmYAMAYF|SZAMAbFUYAMAZFYWAMASFbZAMAcFfXAMAVFgWAMATFkcAMAkFmXAMAWF|RYAMAZFVYAMAYFYdAMAoFZVAMAQFcZAMAbFfWAMATFgWAMASFlbAMAiFmXAMAVF|RYAMAYFWXAMAWFXdAMAnFZVAMAPFbYAMAZFeWAMASFidAMAoFgVAMAQFlbAMAhFnWAMATF|SXAMAWFVXAMAVFXcAMAlFaYAMAYFedAMAoFdVAMAQFhdAMAnFhVAMAPFkaAMAfFoWAMASF|TXAMAVFUWAMATFYcAMAkFaXAMAWFfdAMAnFdVAMAPFgcAMAlFjaAMAeFmdAMAoFnVAMAQF|TWAMATFUWAMASFZbAMAiFaXAMAVFfcAMAlFgcAMAkFjZAMAcFmdAMAnFmVAMAPF|SWAMASFWdAMAoFUVAMAQFZbAMAhFbWAMATFecAMAkFgbAMAiFkZAMAbFncAMAlF|SdAMAoFRVAMAQFVdAMAnFVVAMAPFYaAMAfFcWAMASFdbAMAiFhbAMAhFlYAMAZFocAMAkF|TdAMAnFRVAMAPFUcAMAlFXaAMAeFadAMAoFbVAMAQFdbAMAhFiaAMAfFlYAMAYFnbAMAiF'
VN_APAL[souls]='3ac8881a6a4a78fcc028805c90ccb040d0902074542c8c64308c64247c587098801450387affc0b0fcd4b8fcd82c88643c9c7028845c18503814543828805834906834946c44d0902478540c402c2c8c60bcfcd82c886024785820644860c8982c84602078545cc0941864440c3c2824805cb0f0cc24805848d4946c94801c70501c60445070602c845c48d898185c4444d4949ce8c44c705c88cca8a8fcd0309064a4fcd0acfcd4186c4c38a070b4fcd41c704c2ca06c'
VN_AF[sigil]='YIsAANNvABFMxACCIqADFECADNCmAEVEoAE|YJsAGUMzAHMNvABELxAFCHqADGECADOCmAEWFoAE|XJsAASMzAIKNvAJEKxAFDGqADIDCADQDmAEWFoAE|XKsAKRNzALJNvAMDKwAFDGqAFJDCADRDmADXGoAE|WKtAEQNzANIMvAIDJwAFEFqAFKDCADSDmADXGoAE|WLtAOONzAPGMvAQCJwAFEFqAFMCCADUEmADYHoAE|NNzARFMvASCIwAIFEqAFNCCAFVEmADYIoAD|UMtAOMNzARELvAACHwAIGEqAFOCCAFWFmADYJoAT|SMtAEKNzAKELvAADGwAIIDqAFQDCAFWFmADXJoAD|RNtAUJNzAVDKuAEDGwAAJDqAIRDCAFXGmAFXKoAW|QNtAXIMzAEDJuAEEFwAAKDqAISDCAFXGmAFWKpAD|ONtAYGMzAZCJuAEEFwAAMCqAIUECAFYHmAFWLpAa|NNtAbFMzAcCIuAEFEwAENCqAAVECAIYImAF|MNtAbELzADCHuAEGEwAEOCqAAWFCAIYJmAdUMpAC|KNtAeEKzADDGuAEIDwAEQDqAAWFCAIXJmAFSMpAF|JNtAfDKyADDGuADJDwAERDqAEXGCAAXKmAgRNpAh|IMtAFDJyADEFuADKDwAESDqAEXGCAAWKnAIQNpAf|GMtAiCJyADEFuADMCwAEUEqAEYHCAAWLnAjONpAk|FMtACCIyAFFEuADNCwADVEqAEYICAENNpAl|ELtAFCHyAFGEuADOCwADWFqAEYJCAmUMnASMNpAl|EKtAFDGyAFIDuADQDwADWFqAEXJCAESMnAAKNpAn|DKsAIDGyAFJDuAFRDwADXGqADXKCAKRNnAoJNpAN|DJsAIEFyAFKDuAFSDwADXGqADWKDAEQNnAVIMpAA|CJsAIEFyAFMCuAFUEwADYHqADWLDAOONnApGMpAq|CIsAAFEyAINCuAFVEwAFYIqADNNnARFMpAO|CHsAAGEyAIOCuAFWFwAFYJqATUMDAcMNnARELpAE|DGsAAIDyAIQDuAFWFwAFXJqADSMDADKNnAKELpAE|DGsAEJDyAARDuAIXGwAFXKqArRNDAUJNnAXDKoAE|EFsAEKDyAASDuAIXGwAFWLrAsQNDAXIMnADDJoAE|EFsAEMCyAAUEuAIYHwAFWLrAsONDAYGMnAtCJoAE|FEsAENCyAEVEuAAYIwAINNDABFMnAcCIoAD|GEsAEOCyAEWFuAAYJwAuUMrACMNDABELnADCHoAD|IDsAEQDyAEWFuAAXJwAISMrAFKNDAJELnADDGoAD|JDsADRDyAEXGuAEXKwAvRNrAwJNDAfDKmAFDGoAD|KDsADSDyAEXGuAEWLxAxQNrAMIMDAFDJmAFEFoAD|MCsADUEyAEYHuAEWLxAxONrAyGMDAiCJmAFEFoAD|NCsADVEyADYIuAENNrAzFMDAHCImAFFEoAF|OCsADWFyADYJuAmUMxAOMNrAzELDAICHmAFGEoAF|QDsADWFyADXJuAESMxAEKNrA0ELDAIDGmAFIDoAF|RDsAFXGyADXKuAWRNxAoJNrAVDKCAADGmAIJDoAF|SDsAFXGyADWLvAaQNxAVIMrAEDJCAAEFmAIKDoAF|UEsAFYHyADWLvAaONxApGMrAZCJCAAEFmAIMCoAF|VEsAFYIyAFNNxAbFMrAOCICAEFEmAANCoAI|WFsAFYJyAdUMvAcMNxAbELrAECHCAEGEmAAOCoAI|WFsAFXJyAFSMvADKNxAeELrAEDGCAEIDmAAQDoAI|XGsAIXKyArRNvAhJNxAXDKqADDGCAEJDmAERDoAA|XGsAIWLzAsQNvAfIMxADDJqADEFCAEKDmAESDoAA|YHsAIWLzAsONvAkGMxAtCJqADEFCAEMCmAEUEoAA'
VN_AL[sigil]='oYAFBGHlcAFAeF|oZAFBGHkcAFAeF|nZAFBGHicAFAeF|hdAFBGHZdAFAeF|gdAFBGHYcAFAeF|edAFBGHWcAFAeF|VcAFBGHSYAFAeF|UbAFBGHSXAFAeF|UbAFBGHTWAFAeF|TWAFBGHZTAFAeF|UVAFBGHaTAFAeF|UVAFBGHcSAFAeF|dSAFBGHlUAFAeF|eSAFBGHmVAFAeF|gTAFBGHmVAFAeF|nWAFBGHnaAFAeF|nWAFBGHmaAFAeF|oXAFBGHmbAFAeF|lcAFBGHddAFAeF|kcAFBGHcdAFAeF|icAFBGHadAFAeF|TaAFAeFZdAFBGH|TZAFAeFYcAFBGH|SZAFAeFWcAFBGH|SYAFBGHVUAFAeF|SXAFBGHWUAFAeF|TWAFBGHYTAFAeF|ZTAFBGHhTAFAeF|aTAFBGHiTAFAeF|cSAFBGHkUAFAeF|lUAFBGHoYAFAeF|mVAFBGHoZAFAeF|mVAFBGHnZAFAeF|naAFBGHhdAFAeF|mbAFBGHgdAFAeF|mbAFBGHedAFAeF|ddAFBGHVcAFAeF|cdAFBGHUbAFAeF|adAFBGHUbAFAeF|TaAFBGHTWAFAeF|TZAFBGHUVAFAeF|SZAFBGHUVAFAeF|VUAFBGHdSAFAeF|WUAFBGHeSAFAeF|YTAFBGHgTAFAeF|nWAFAeFhTAFBGH|nWAFAeFiTAFBGH|oXAFAeFkUAFBGH'
VN_APAL[sigil]='fcec9cf8e084948850a8873a5a4620ffe98ac0b478948c68fcf0b4d0bc70483818706844a49c74a49c64342810e8d890f0e4ac54441c948c5c80682c4c3c18382c14846c2c6c58249c7c3454401c645020a48038605020c4b468886c2ca89858c8c09070683cf4dc8498906cecd880f4e8ac443418ccc490281c0c50401cf0e094ccb86c988c54a08034c0b888c8bc7c706c50988c5ce8dca4f4e498ccc07c'
VN_AF[hex]='FMmAAFLmABFKOACINmADIMmAEILmAEIKmAFIJmAGIIOACLNOAHPNoAIPMoAJPLoAEPKoAFPJoAKPIYACSMoALSLoAMSKYACKNQANLNQAOPNQAPQNQAQ|FMmASFLmATFKmAUFJOAVINmADIMmATILmABIKOAVLNOAHPNoAWPMoAXPLoAEPKoAYPJoAZPIoAaPHYACSMYAbUMoAcULYAbKNQANLNQAOPNQAdQNQAe|FMmAfFLmATFKmAgFJmAaFIOACINmADIMmAhILOAVLNmAiLMOAVPNoAjPMoATPLoAJPKoAYPJoAZPIoAaPHYACUMoAkULoAMUKYACKNQAlLNQAmPNQAdQNQAn|FMmAfFLmAoFKmAYFJmAZFImAaFHOACINOApLNmAqLMmATLLmABLKOACPNoAWPMoAEPLoAJPKoArPJoAaPIYACUMoAsULoAJUKoAZUJoAaUIYACKNQAtLNQAuPNQAd|FMmAfFLmAoFKmAZFJmAaFIOACINOApLNmAqLMmAELLmAvLKmAGLJOAVPNoAWPMoATPLoABPKYAwUMoAsULoAJUKoAYUJoAZUIoAaUHYACKNQAtONQAxPNQAd|FMmAfFLmAyFKmAaFJOACINOApLNmAqLMmAzLLmAyLKmAZLJmAaLIOACPNoAWPMoAhPLYAVSMYAVUMoA0ULoATUKoA1UJoAZUIoAaUHYACJNQA2KNQAtONQA3PNQAd|FMmAsFLmABFKOACINOApLNmATLMmAzLLmAoLKmAYLJmAZLImAaLHOACPNYA4SMoATSLoABSKYAVUMoA5ULoATUKoAGUJoAKUIYAwJNQA2KNQAtONQA6PNQA7|FMOA8INmADIMmAhILOAVLNmA9LMmAzLLmATLKmArLJmAaLIOACPNYA4SMoAzSLoALSKoA+SJYAbUMoAAULoAMUKYAbJNQA/KNQBAONQA6PNQA7|INmADIMmATILmABIKOAVLNmA9LMmAJLLmATLKmAKLJOAVPNYA4SMoBBSLoABSKoBCSJoAaSIYACUMoA0ULYACJNQAQKNQBAONQA6|INmADIMmAEILmAEIKmAFIJmAKIIOACLNmA9LMmAvLLmABLKOACPNYA4SMoBBSLoAJSKoAYSJoAZSIoAaSHYACJNQAQNNQBDONQA6|INmBEIMmBFILmAEIKmAYIJmAZIImAaIHOACLNmAiLMOAVPNoBGPMoBHPLYAwSMoBBSLoAXSKoArSJoAaSIYACINQBIJNQBJNNQBKONQBL|FMOBMINmBEIMmABILmAEIKmAYIJmAZIImAaIHOACLNOAHPNoAIPMoAEPLoABPKYAVSMoATSLoAXSKoAKSJYAVINQBIJNQAnNNQBDONQAu|FMmAAFLmABFKOACINmADIMmAEILmAEIKmAFIJmAGIIOACLNOAHPNoAIPMoAJPLoAEPKoAFPJoAKPIYACSMoALSLoAMSKYACINQBIJNQAnNNQBDONQAu|FMmASFLmATFKmAUFJOAVINmADIMmATILmABIKOAVLNOAHPNoAWPMoAXPLoAEPKoAYPJoAZPIoAaPHYACSMYAbUMoAcULYAbINQBIJNQAnNNQBDRNQBI|FMmAfFLmATFKmAgFJmAaFIOACINmADIMmAhILOAVLNmAiLMOAVPNoAjPMoATPLoAJPKoAYPJoAZPIoAaPHYACUMoAkULoAMUKYACINQBIMNQBNNNQBKRNQBO|FMmAfFLmAoFKmAYFJmAZFImAaFHOACINOApLNmAqLMmATLLmABLKOACPNoAWPMoAEPLoAJPKoArPJoAaPIYACUMoAsULoAJUKoAZUJoAaUIYACINQBPMNQBQNNQBRRNQBO|FMmAfFLmAoFKmAZFJmAaFIOACINOApLNmAqLMmAELLmAvLKmAGLJOAVPNoAWPMoATPLoABPKYAwUMoAsULoAJUKoAYUJoAZUIoAaUHYACINQBPMNQBQNNQBRRNQBO|FMmAfFLmAyFKmAaFJOACINOApLNmAqLMmAzLLmAyLKmAZLJmAaLIOACPNoAWPMoAhPLYAVSMYAVUMoA0ULoATUKoA1UJoAZUIoAaUHYACINQBPMNQBQNNQBSRNQBI|FMmAsFLmABFKOACINOApLNmATLMmAzLLmAoLKmAYLJmAZLImAaLHOACPNYA4SMoATSLoABSKYAVUMoA5ULoATUKoAGUJoAKUIYAwINQBPMNQBNQNQA2RNQBT|FMOA8INmADIMmAhILOAVLNmA9LMmAzLLmATLKmArLJmAaLIOACPNYA4SMoAzSLoALSKoA+SJYAbUMoAAULoAMUKYAbLNQAxMNQBKQNQA2RNQBT|INmADIMmATILmABIKOAVLNmA9LMmAJLLmATLKmAKLJOAVPNYA4SMoBBSLoABSKoBCSJoAaSIYACUMoA0ULYACLNQAxMNQBKQNQA2RNQBT|INmADIMmAEILmAEIKmAFIJmAKIIOACLNmA9LMmAvLLmABLKOACPNYA4SMoBBSLoAJSKoAYSJoAZSIoAaSHYACLNQAxMNQBKQNQA2RNQBP|INmBEIMmBFILmAEIKmAYIJmAZIImAaIHOACLNmAiLMOAVPNoBGPMoBHPLYAwSMoBBSLoAXSKoArSJoAaSIYACLNQAmMNQBNQNQAe|FMOBMINmBEIMmABILmAEIKmAYIJmAZIImAaIHOACLNOAHPNoAIPMoAEPLoABPKYAVSMoATSLoAXSKoAKSJYAVLNQAOPNQAPQNQAQ|FMmAAFLmABFKOACINmADIMmAEILmAEIKmAFIJmAGIIOACLNOAHPNoAIPMoAJPLoAEPKoAFPJoAKPIYACSMoALSLoAMSKYACKNQANLNQAOPNQAPQNQAQ|FMmASFLmATFKmAUFJOAVINmADIMmATILmABIKOAVLNOAHPNoAWPMoAXPLoAEPKoAYPJoAZPIoAaPHYACSMYAbUMoAcULYAbKNQANLNQAOPNQAdQNQAe|FMmAfFLmATFKmAgFJmAaFIOACINmADIMmAhILOAVLNmAiLMOAVPNoAjPMoATPLoAJPKoAYPJoAZPIoAaPHYACUMoAkULoAMUKYACKNQAlLNQAmPNQAdQNQAn|FMmAfFLmAoFKmAYFJmAZFImAaFHOACINOApLNmAqLMmATLLmABLKOACPNoAWPMoAEPLoAJPKoArPJoAaPIYACUMoAsULoAJUKoAZUJoAaUIYACKNQAtLNQAuPNQAd|FMmAfFLmAoFKmAZFJmAaFIOACINOApLNmAqLMmAELLmAvLKmAGLJOAVPNoAWPMoATPLoABPKYAwUMoAsULoAJUKoAYUJoAZUIoAaUHYACKNQAtONQAxPNQAd|FMmAfFLmAyFKmAaFJOACINOApLNmAqLMmAzLLmAyLKmAZLJmAaLIOACPNoAWPMoAhPLYAVSMYAVUMoA0ULoATUKoA1UJoAZUIoAaUHYACJNQA2KNQAtONQA3PNQAd|FMmAsFLmABFKOACINOApLNmATLMmAzLLmAoLKmAYLJmAZLImAaLHOACPNYA4SMoATSLoABSKYAVUMoA5ULoATUKoAGUJoAKUIYAwJNQA2KNQAtONQA6PNQA7|FMOA8INmADIMmAhILOAVLNmA9LMmAzLLmATLKmArLJmAaLIOACPNYA4SMoAzSLoALSKoA+SJYAbUMoAAULoAMUKYAbJNQA/KNQBAONQA6PNQA7|INmADIMmATILmABIKOAVLNmA9LMmAJLLmATLKmAKLJOAVPNYA4SMoBBSLoABSKoBCSJoAaSIYACUMoA0ULYACJNQAQKNQBAONQA6|INmADIMmAEILmAEIKmAFIJmAKIIOACLNmA9LMmAvLLmABLKOACPNYA4SMoBBSLoAJSKoAYSJoAZSIoAaSHYACJNQAQNNQBDONQA6|INmBEIMmBFILmAEIKmAYIJmAZIImAaIHOACLNmAiLMOAVPNoBGPMoBHPLYAwSMoBBSLoAXSKoArSJoAaSIYACINQBIJNQBJNNQBKONQBL|FMOBMINmBEIMmABILmAEIKmAYIJmAZIImAaIHOACLNOAHPNoAIPMoAEPLoABPKYAVSMoATSLoAXSKoAKSJYAVINQBIJNQAnNNQBDONQAu|FMmAAFLmABFKOACINmADIMmAEILmAEIKmAFIJmAGIIOACLNOAHPNoAIPMoAJPLoAEPKoAFPJoAKPIYACSMoALSLoAMSKYACINQBIJNQAnNNQBDONQAu|FMmASFLmATFKmAUFJOAVINmADIMmATILmABIKOAVLNOAHPNoAWPMoAXPLoAEPKoAYPJoAZPIoAaPHYACSMYAbUMoAcULYAbINQBIJNQAnNNQBDRNQBI|FMmAfFLmATFKmAgFJmAaFIOACINmADIMmAhILOAVLNmAiLMOAVPNoAjPMoATPLoAJPKoAYPJoAZPIoAaPHYACUMoAkULoAMUKYACINQBIMNQBNNNQBKRNQBO|FMmAfFLmAoFKmAYFJmAZFImAaFHOACINOApLNmAqLMmATLLmABLKOACPNoAWPMoAEPLoAJPKoArPJoAaPIYACUMoAsULoAJUKoAZUJoAaUIYACINQBPMNQBQNNQBRRNQBO|FMmAfFLmAoFKmAZFJmAaFIOACINOApLNmAqLMmAELLmAvLKmAGLJOAVPNoAWPMoATPLoABPKYAwUMoAsULoAJUKoAYUJoAZUIoAaUHYACINQBPMNQBQNNQBRRNQBO|FMmAfFLmAyFKmAaFJOACINOApLNmAqLMmAzLLmAyLKmAZLJmAaLIOACPNoAWPMoAhPLYAVSMYAVUMoA0ULoATUKoA1UJoAZUIoAaUHYACINQBPMNQBQNNQBSRNQBI|FMmAsFLmABFKOACINOApLNmATLMmAzLLmAoLKmAYLJmAZLImAaLHOACPNYA4SMoATSLoABSKYAVUMoA5ULoATUKoAGUJoAKUIYAwINQBPMNQBNQNQA2RNQBT|FMOA8INmADIMmAhILOAVLNmA9LMmAzLLmATLKmArLJmAaLIOACPNYA4SMoAzSLoALSKoA+SJYAbUMoAAULoAMUKYAbLNQAxMNQBKQNQA2RNQBT|INmADIMmATILmABIKOAVLNmA9LMmAJLLmATLKmAKLJOAVPNYA4SMoBBSLoABSKoBCSJoAaSIYACUMoA0ULYACLNQAxMNQBKQNQA2RNQBT|INmADIMmAEILmAEIKmAFIJmAKIIOACLNmA9LMmAvLLmABLKOACPNYA4SMoBBSLoAJSKoAYSJoAZSIoAaSHYACLNQAxMNQBKQNQA2RNQBP|INmBEIMmBFILmAEIKmAYIJmAZIImAaIHOACLNmAiLMOAVPNoBGPMoBHPLYAwSMoBBSLoAXSKoArSJoAaSIYACLNQAmMNQBNQNQAe|FMOBMINmBEIMmABILmAEIKmAYIJmAZIImAaIHOACLNOAHPNoAIPMoAEPLoABPKYAVSMoATSLoAXSKoAKSJYAVLNQAOPNQAPQNQAQ'
VN_AL[hex]='VaARAtFYYARAtFbdARAtFfYARAtFiaARAtFkdARAtF|VZARAtFYaARAtFbdARAtFfXARAtFicARAtFkbARAtF|VYARAtFYbARAtFbcARAtFfXARAtFidARAtFkaARAtF|VXARAtFYdARAtFbaARAtFfYARAtFidARAtFkYARAtF|VYARAtFYdARAtFbZARAtFfaARAtFidARAtFkXARAtF|VZARAtFYdARAtFbYARAtFfbARAtFicARAtFkXARAtF|VaARAtFYdARAtFbXARAtFfdARAtFiaARAtFkYARAtF|VcARAtFYbARAtFbYARAtFfdARAtFiZARAtFkaARAtF|VdARAtFYaARAtFbZARAtFfdARAtFiYARAtFkbARAtF|VdARAtFYYARAtFbaARAtFfdARAtFiXARAtFkdARAtF|VdARAtFYXARAtFbcARAtFfbARAtFiYARAtFkdARAtF|VcARAtFYXARAtFbdARAtFfaARAtFiZARAtFkdARAtF|VaARAtFYYARAtFbdARAtFfYARAtFiaARAtFkdARAtF|VZARAtFYaARAtFbdARAtFfXARAtFicARAtFkbARAtF|VYARAtFYbARAtFbcARAtFfXARAtFidARAtFkaARAtF|VXARAtFYdARAtFbaARAtFfYARAtFidARAtFkYARAtF|VYARAtFYdARAtFbZARAtFfaARAtFidARAtFkXARAtF|VZARAtFYdARAtFbYARAtFfbARAtFicARAtFkXARAtF|VaARAtFYdARAtFbXARAtFfdARAtFiaARAtFkYARAtF|VcARAtFYbARAtFbYARAtFfdARAtFiZARAtFkaARAtF|VdARAtFYaARAtFbZARAtFfdARAtFiYARAtFkbARAtF|VdARAtFYYARAtFbaARAtFfdARAtFiXARAtFkdARAtF|VdARAtFYXARAtFbcARAtFfbARAtFiYARAtFkdARAtF|VcARAtFYXARAtFbdARAtFfaARAtFiZARAtFkdARAtF|VaARAtFYYARAtFbdARAtFfYARAtFiaARAtFkdARAtF|VZARAtFYaARAtFbdARAtFfXARAtFicARAtFkbARAtF|VYARAtFYbARAtFbcARAtFfXARAtFidARAtFkaARAtF|VXARAtFYdARAtFbaARAtFfYARAtFidARAtFkYARAtF|VYARAtFYdARAtFbZARAtFfaARAtFidARAtFkXARAtF|VZARAtFYdARAtFbYARAtFfbARAtFicARAtFkXARAtF|VaARAtFYdARAtFbXARAtFfdARAtFiaARAtFkYARAtF|VcARAtFYbARAtFbYARAtFfdARAtFiZARAtFkaARAtF|VdARAtFYaARAtFbZARAtFfdARAtFiYARAtFkbARAtF|VdARAtFYYARAtFbaARAtFfdARAtFiXARAtFkdARAtF|VdARAtFYXARAtFbcARAtFfbARAtFiYARAtFkdARAtF|VcARAtFYXARAtFbdARAtFfaARAtFiZARAtFkdARAtF|VaARAtFYYARAtFbdARAtFfYARAtFiaARAtFkdARAtF|VZARAtFYaARAtFbdARAtFfXARAtFicARAtFkbARAtF|VYARAtFYbARAtFbcARAtFfXARAtFidARAtFkaARAtF|VXARAtFYdARAtFbaARAtFfYARAtFidARAtFkYARAtF|VYARAtFYdARAtFbZARAtFfaARAtFidARAtFkXARAtF|VZARAtFYdARAtFbYARAtFfbARAtFicARAtFkXARAtF|VaARAtFYdARAtFbXARAtFfdARAtFiaARAtFkYARAtF|VcARAtFYbARAtFbYARAtFfdARAtFiZARAtFkaARAtF|VdARAtFYaARAtFbZARAtFfdARAtFiYARAtFkbARAtF|VdARAtFYYARAtFbaARAtFfdARAtFiXARAtFkdARAtF|VdARAtFYXARAtFbcARAtFfbARAtFiYARAtFkdARAtF|VcARAtFYXARAtFbdARAtFfaARAtFiZARAtFkdARAtF'
VN_APAL[hex]='280838602480e088fc240c304c14649c3cd8a444dcd07ce8340c4c400c58a444e05c207c6424848434b49c44d07828ac60208cd070ff200430541c70a848e0dc84fc441458581c748f2fd09434d4a040dcdc80fc48205c7c2cb064248c2c08389838d874309458207448145c3410487c30b09438cc6828903a0a52643c704c18689838d43010408034b48c34c8481464dc88fc8830c444106050186838144c9030d06c2c948830c0b46ccc240434983cd08c3cb8804c943c0c58ac4ce46020887424a86424809c3cdc9c3cd428103860247c3c10506828884418606424909434d08c34c48450949838d0481c644c20649030cc882cc88c2cc8481c60'
VN_AF[radioactive]='DFEAADKGABGFGAAGKGABJDEACJIGAAMDGACMIGAAPDGACPJEAASEEACSJGADVHEAAYHGAAIN0AEJNCAFKNCAGLN0AHMN0AINNCAJONCAHPN0AGQN0AKRNCAL|AFEAMDFGAADKGABGFGAAGLEANJDGACJIGAAMDGACMJEAAPEEACPJGADSEGACSJGADVCEACVHGAAYHGAAINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|AFGAMDFGAADLEAOGGEAAGLGANJDGACJJEAAMEEACMJGADPEGACPJGADSEGAASKEABVCGACVHGAAYIEAAINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|AFGAMDGEAADLGAOGBEAPGGGAAGLGANJEEACJJGADMEGACMJGADPEGAAPKEABSFEAASKGABVCGACVIEAAYIGAAINCALJNCAKKN0AGLN0AHMNCAJNNCAION0AHPN0AGQNCAFRNCAE|AGEAQDGGAADLGAOGBGAPGGGAAGMEARJEGACJJGADMEGAAMKEASPFEAAPKGABSFGAASKGABVDEACVIGAAYIGAAINCALJN0AKKN0AGLNCATMNCAJNN0AION0AHPNCAUQNCAFRN0AE|AGGAQDGGAAGBGAPGHEAAGMGARJEGAAJKEAVMFEAAMKGASPAEAWPFGAAPKGABSFGAASLEANVDGACVIGAAYJEAXINCALJN0AKKN0AGLNCATMNCAJNN0AION0AHPNCAUQNCAFRN0AE|AGGAQDHEAAGCEACGHGAAJFEAAJKGAVMAEAYMFGAAMKGASPAGAWPFGAAPLEAZSGEAASLGANVDGACVJEAAYEEAaYJGAbINCAEJN0AKKN0AGLNCATMNCAINN0AION0AHPNCAUQNCAKRN0AE|AHEAQDCEAcDHGAAGCGACGHGAAJAEAdJFGAAJKGAVMAGAYMFGAAMLEAePAGAWPGEAAPLGAZSBEACSGGAASLGANVEEACVJGADYEGAaYJGAbIN0AEJN0AKKNCAfLNCATMN0AINN0AIONCAgPNCAUQN0AKRN0AE|AHGAQDCGAcDHGAAGCGACGIEAAJAGAdJFGAAJLEAhMAGAYMGEAAMLGAePBEACPGGAAPLGAZSBGACSGGAASMEAiVEGACVJGADYEGAXIN0AEJN0AKKNCAfLNCATMN0AINN0AIONCAgPNCAUQN0AKRN0AE|AHGAQDCGAcDIEAAGDEACGIGAAJAGAdJGEAAJLGAhMBEACMGGAAMLGAePBGACPGGAAPMEAjSBGACSHEAASMGAiVEGAAVKEAVYFEAAIN0AEJN0AKKNCAfLNCAHMN0AINN0AIONCAgPNCAGQN0AKRN0AE|AIEAMDDEACDIGAAGDGACGIGAAJBEACJGGAAJLGAhMBGACMGGAAMMEAjPBGACPHEAAPMGAjSCEACSHGAAVFEAAVKGAVYFGAAIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|AIGAMDDGACDIGAAGDGACGJEAAJBGACJGGAAJMEAjMBGACMHEAAMMGAjPCEACPHGAASCGACSHGAAVFGAAVKGAVYFGAAIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|AIGAMDDGACDJEAAGEEACGJGADJBGACJHEAAJMGAjMCEACMHGAAPCGACPHGAASCGACSIEAAVFGAAVLEAkYGEAAIN0AEJNCAFKNCAGLN0AHMN0AINNCAJONCAHPN0AGQN0AKRNCAL|DEEACDJGADGEGACGJGADJCEACJHGAAMCGACMHGAAPCGACPIEAASDEACSIGAAVGEAAVLGAkYGGAAINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|DEGACDJGADGEGAAGKEABJCGACJHGAAMCGACMIEAAPDEACPIGAASDGACSIGAAVGGAAVLGAkYGGAAINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|DEGAADKEABGFEAAGKGABJCGACJIEAAMDEACMIGAAPDGACPIGAASDGACSJEAAVGGAAYHEAAINCALJNCAKKN0AGLN0AHMNCAJNNCAION0AHPN0AGQNCAFRNCAE|DFEAADKGABGFGAAGKGABJDEACJIGAAMDGACMIGAAPDGACPJEAASEEACSJGADVHEAAYHGAAINCALJN0AKKN0AGLNCATMNCAJNN0AION0AHPNCAUQNCAFRN0AE|AFEAMDFGAADKGABGFGAAGLEANJDGACJIGAAMDGACMJEAAPEEACPJGADSEGACSJGADVCEACVHGAAYHGAAINCALJN0AKKN0AGLNCATMNCAJNN0AION0AHPNCAUQNCAFRN0AE|AFGAMDFGAADLEAOGGEAAGLGANJDGACJJEAAMEEACMJGADPEGACPJGADSEGAASKEABVCGACVHGAAYIEAAINCAEJN0AKKN0AGLNCATMNCAINN0AION0AHPNCAUQNCAKRN0AE|AFGAMDGEAADLGAOGBEAPGGGAAGLGANJEEACJJGADMEGACMJGADPEGAAPKEABSFEAASKGABVCGACVIEAAYIGAAIN0AEJN0AKKNCAfLNCATMN0AINN0AIONCAgPNCAUQN0AKRN0AE|AGEAQDGGAADLGAOGBGAPGGGAAGMEARJEGACJJGADMEGAAMKEASPFEAAPKGABSFGAASKGABVDEACVIGAAYIGAAIN0AEJN0AKKNCAfLNCATMN0AINN0AIONCAgPNCAUQN0AKRN0AE|AGGAQDGGAAGBGAPGHEAAGMGARJEGAAJKEAVMFEAAMKGASPAEAWPFGAAPKGABSFGAASLEANVDGACVIGAAYJEAXIN0AEJN0AKKNCAfLNCAHMN0AINN0AIONCAgPNCAGQN0AKRN0AE|AGGAQDHEAAGCEACGHGAAJFEAAJKGAVMAEAYMFGAAMKGASPAGAWPFGAAPLEAZSGEAASLGANVDGACVJEAAYEEAaYJGAbIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|AHEAQDCEAcDHGAAGCGACGHGAAJAEAdJFGAAJKGAVMAGAYMFGAAMLEAePAGAWPGEAAPLGAZSBEACSGGAASLGANVEEACVJGADYEGAaYJGAbIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|AHGAQDCGAcDHGAAGCGACGIEAAJAGAdJFGAAJLEAhMAGAYMGEAAMLGAePBEACPGGAAPLGAZSBGACSGGAASMEAiVEGACVJGADYEGAXIN0AEJNCAFKNCAGLN0AHMN0AINNCAJONCAHPN0AGQN0AKRNCAL|AHGAQDCGAcDIEAAGDEACGIGAAJAGAdJGEAAJLGAhMBEACMGGAAMLGAePBGACPGGAAPMEAjSBGACSHEAASMGAiVEGAAVKEAVYFEAAINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|AIEAMDDEACDIGAAGDGACGIGAAJBEACJGGAAJLGAhMBGACMGGAAMMEAjPBGACPHEAAPMGAjSCEACSHGAAVFEAAVKGAVYFGAAINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|AIGAMDDGACDIGAAGDGACGJEAAJBGACJGGAAJMEAjMBGACMHEAAMMGAjPCEACPHGAASCGACSHGAAVFGAAVKGAVYFGAAINCALJNCAKKN0AGLN0AHMNCAJNNCAION0AHPN0AGQNCAFRNCAE|AIGAMDDGACDJEAAGEEACGJGADJBGACJHEAAJMGAjMCEACMHGAAPCGACPHGAASCGACSIEAAVFGAAVLEAkYGEAAINCALJN0AKKN0AGLNCATMNCAJNN0AION0AHPNCAUQNCAFRN0AE|DEEACDJGADGEGACGJGADJCEACJHGAAMCGACMHGAAPCGACPIEAASDEACSIGAAVGEAAVLGAkYGGAAINCALJN0AKKN0AGLNCATMNCAJNN0AION0AHPNCAUQNCAFRN0AE|DEGACDJGADGEGAAGKEABJCGACJHGAAMCGACMIEAAPDEACPIGAASDGACSIGAAVGGAAVLGAkYGGAAINCAEJN0AKKN0AGLNCATMNCAINN0AION0AHPNCAUQNCAKRN0AE|DEGAADKEABGFEAAGKGABJCGACJIEAAMDEACMIGAAPDGACPIGAASDGACSJEAAVGGAAYHEAAIN0AEJN0AKKNCAfLNCATMN0AINN0AIONCAgPNCAUQN0AKRN0AE|DFEAADKGABGFGAAGKGABJDEACJIGAAMDGACMIGAAPDGACPJEAASEEACSJGADVHEAAYHGAAIN0AEJN0AKKNCAfLNCATMN0AINN0AIONCAgPNCAUQN0AKRN0AE|AFEAMDFGAADKGABGFGAAGLEANJDGACJIGAAMDGACMJEAAPEEACPJGADSEGACSJGADVCEACVHGAAYHGAAIN0AEJN0AKKNCAfLNCAHMN0AINN0AIONCAgPNCAGQN0AKRN0AE|AFGAMDFGAADLEAOGGEAAGLGANJDGACJJEAAMEEACMJGADPEGACPJGADSEGAASKEABVCGACVHGAAYIEAAIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|AFGAMDGEAADLGAOGBEAPGGGAAGLGANJEEACJJGADMEGACMJGADPEGAAPKEABSFEAASKGABVCGACVIEAAYIGAAIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|AGEAQDGGAADLGAOGBGAPGGGAAGMEARJEGACJJGADMEGAAMKEASPFEAAPKGABSFGAASKGABVDEACVIGAAYIGAAIN0AEJNCAFKNCAGLN0AHMN0AINNCAJONCAHPN0AGQN0AKRNCAL|AGGAQDGGAAGBGAPGHEAAGMGARJEGAAJKEAVMFEAAMKGASPAEAWPFGAAPKGABSFGAASLEANVDGACVIGAAYJEAXINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|AGGAQDHEAAGCEACGHGAAJFEAAJKGAVMAEAYMFGAAMKGASPAGAWPFGAAPLEAZSGEAASLGANVDGACVJEAAYEEAaYJGAbINCALJNCAFKN0AGLN0AHMNCAJNNCAJON0AHPN0AGQNCAFRNCAL|AHEAQDCEAcDHGAAGCGACGHGAAJAEAdJFGAAJKGAVMAGAYMFGAAMLEAePAGAWPGEAAPLGAZSBEACSGGAASLGANVEEACVJGADYEGAaYJGAbINCALJNCAKKN0AGLN0AHMNCAJNNCAION0AHPN0AGQNCAFRNCAE|AHGAQDCGAcDHGAAGCGACGIEAAJAGAdJFGAAJLEAlMAGAYMGEAAMLGAmPBEACPGGAAPLGAlSBGACSGGAASMEAnVEGACVJGADYEGAXINCAoJN0ApKN0AqLNCArMNCAsNN0AtON0ArPNCAqQNCApRN0Au|AHGAQDCGAcDIEAAGDEACGIGAAJAGAdJGEAAJLGAlMBEACMGGAAMLGAmPBGACPGGAAPMEAnSBGACSHEAASMGAnVEGAAVKEAvYFEAAINCAoJN0ApKN0AqLNCArMNCAsNN0AtON0ArPNCAqQNCApRN0Au|AIEAMDDEACDIGAAGDGACGIGAAJBEACJGGAAJLGAlMBGACMGGAAMMEAnPBGACPHEAAPMGAnSCEACSHGAAVFEAAVKGAvYFGAAINCAoJN0ApKN0AqLNCArMNCAsNN0AtON0ArPNCAqQNCApRN0Au|AIGAMDDGACDIGAAGDGACGJEAAJBGACJGGAAJMEAwMBGACMHEAAMMGAnPCEACPHGAASCGACSHGAAVFGAAVKGAvYFGAAIN0AoJN0ApKNCAqLNCArMN0AsNN0AtONCArPNCAqQN0ApRN0Au|AIGAMDDGACDJEAAGEEACGJGADJBGACJHEAAJMGAwMCEACMHGAAPCGACPHGAASCGACSIEAAVFGAAVLEAxYGEAAIN0AoJN0ApKNCAqLNCArMN0AsNN0AtONCArPNCAqQN0ApRN0Au|DEEACDJGADGEGACGJGADJCEACJHGAAMCGACMHGAAPCGACPIEAASDEACSIGAAVGEAAVLGAxYGGAAIN0AoJN0ApKNCAqLNCArMN0AsNN0AtONCArPNCAqQN0ApRN0Au|DEGACDJGADGEGAAGKEABJCGACJHGAAMCGACMIEAAPDEACPIGAASDGACSIGAAVGGAAVLGAkYGGAAIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL|DEGAADKEABGFEAAGKGABJCGACJIEAAMDEACMIGAAPDGACPIGAASDGACSJEAAVGGAAYHEAAIN0AEJNCAFKNCAfLN0AHMN0AINNCAJONCAgPN0AGQN0AKRNCAL'
VN_AL[radioactive]='SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACA8IWdACA8IadACA8IedACA8IidACA8ImdACA8I|SdACA8IWdACA8IadACA8IedACA8IidACA8ImdACA8I|SdACA8IWdACA8IadACA8IedACA8IidACA8ImdACA8I|SdACA8IWdACA8IadACA8IedACA8IidACA8ImdACA8I|SdACA8IWdACA8IadACA8IedACA8IidACA8ImdACA8I|SdACA8IWdACA8IadACA8IedACA8IidACA8ImdACA8I|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI|SdACAgIWdACAgIadACAgIedACAgIidACAgImdACAgI'
VN_APAL[radioactive]='5fd71a34940ca8ff3a2a8a0a4c701854941488cc2c9ce834a4f4347cdc206ca424386410306c0c4cac1028600ca0f43440901058b01838940c70d02464b82038980c88d02c48a414a4f8384ca81480c42c2068046498206ca82448a81068bc1c74d4204ca8105cb81c5cb81848a41068c41c68c0207cd8284c702474a43490cc44a0e84ca8f450acf45050702444a01080dc2860bc1c'
VN_AF[glitch]='RATAAICiABMCTACUCQADCDgAEGDQADHEiABSFSACFGAAFDHTADLHQADCIiACOIQAFMJQACNJBADRJQACILBAFULTADKMSAB|RATAAICiABMCTACUCQADCDgAEGDQADHEiABSFSACFGAAFDHTADLHQADCIiACOIQAFMJQACNJBADRJQACILBAFULTADKMSAB|RAhAGICgAFMCQACUCAACCDiAEGDSAFHEAABPEiACSFhACFGSAFDHRACLHAADCISABOIAADMJSADNJjADRJAACULhADKMQAB|RAhAGICgAFMCQACUCAACCDiAEGDSAFHEAABPEiACSFhACFGSAFDHRACLHAADCISABOIAADMJSADNJjADRJAACULhADKMQAB|RAjAGICSAFMCAABUCiACGDgADHESAFSFBACFGgADDHjACLHiADCIQABOIiADBJRAHMJiACNJhADRJiACULjAFKMAAF|RAjAGICSAFMCAABUCiACGDgADHESAFSFBACFGgADDHjACLHiADCIQABOIiADBJRAHMJiACNJhADRJiACULjAFKMAAF|RABAGICQADMCiABUCgACGDAADHEgAFSFRADFGiAFDHgACLHgACCIAAFOISADBJjAHMJAACNJTACULBAFKMiAF|RABAGICQADMCiABUCgACGDAADHEgAFSFRADFGiAFDHgACLHgACCIAAFOISADBJjAHMJAACNJTACULBAFKMiAF|JAhAIRAgAJICAADMCRAFSCjAFUCQAFCDSAKGDQACHEiADSFTADFGAABNGiACDHSABLHSACCIiAFOIAABBJhAHILBADULRAFKMTAD|JAhAIRAgAJICAADMCRAFSCjAFUCQAFCDSAKGDQACHEiADSFTADFGAABNGiACDHSABLHSACCIiAFOIAABBJhAHILBADULRAFKMTAD|JABAIRAiAJICiADMCBADSChAFUCiAFCDgALGDSACHEAADSFhAFFGQACNGAACDHQABCIgAFOIiABBJTAMILRADKMRAC|JABAIRAiAJICiADMCBADSChAFUCiAFCDgALGDSACHEAADSFhAFFGQACNGAACDHQABCIgAFOIiABBJTAMILRADKMRAC|RAAAJICSACMCjADUCgAFCDAAEHESACSFjAFFGgABDHAAFCISADOIgABBJRAMNJTAFGKSACILhAFKMAAC|RAAAJICSACMCjADUCgAFCDAAEHESACSFjAFFGgABDHAAFCISADOIgABBJRAMNJTAFGKSACILhAFKMAAC|RAQAAICQACMChADSCBAFUCSADCDQAKHEgADSFBAFFGiABNGgACDHiAFCIQADOISAFBJBANNJRAFILjAFKMgAC|RAQAAICQACMChADSCBAFUCSADCDQAKHEgADSFBAFFGiABNGgACDHiAFCIQADOISAFBJBANNJRAFILjAFKMgAC|JAjAONATAPMCgADQCSAFUCAACCDSAQODiADEEAACHEhAFKFjACFGjADDHgAFLHBACSIQACBJjANMJAABULgAFKMRAFLMiADUMjAR|JAjAONATAPMCgADQCSAFUCAACCDSAQODiADEEAACHEhAFKFjACFGjADDHgAFLHBACSIQACBJjANMJAABULgAFKMRAFLMiADUMjAR|JABAOMCSADQCQAFUCiACCDgAQODAADEEiACHEjAFKFBACFGBADDHSADLHjACCIRAFBJgANMJQACULiAFKMBAFLMAADUMhAS|JABAOMCSADQCQAFUCiACCDgAQODAADEEiACHEjAFKFBACFGBADDHSADLHjACCIRAFBJgANMJQACULiAFKMBAFLMAADUMhAS|JARATMCQAUQCAAVUCgAWCDiAXODSAYEEgAVHEBAVKFRAVFGTAZBHgAaDHQAVLHgAbCIBAcBJSAdMJgAeULAAfKMjAfLMSAaUMRARAGDAgBGrAaCGDAhDGrAiEGDAjFGrAZGGDAkHGrAlIGDAmJGrAnKGDAoLGrApMGDAqNGrArOGDAqPGrApQGDAoRGrAnSGDAmTGrAlUGDAkVGrAZWGDAjXGrAiYGDAhZGrAs|JARAOMCQAiQCAAVUCgAtCDiALODSAUEEgAVHEBAVKFRAVFGTAUBHgAaDHQAVLHgApCIBAuBJSAvMJgAwULAAxKMjAyLMSAiUMRAzAHDAgBHrAaCHDAhDHrAiEHDAjFHrAZGHDAkHHrAlIHDAmJHrAnKHDAoLHrApMHDAqNHrArOHDAqPHrApQHDAoRHrAnSHDAmTHrAlUHDAkVHrAZWHDAjXHrAiYHDAhZHrAs|JATAIMCAAaQCiAVUCSABCDQALODgAVEESAaHERAVKFhAVFGhAVBHSAaDHAAiLHQAoCIjAuBJQA0MJiA1ULQAjKMhAVLMgAUUMBA2AIDA3BIrAaCIDAhDIrAiEIDAjFIrAZGIDAkHIrAlIIDAmJIrAnKIDAoLIrApMIDAqNIrArOIDAqPIrApQIDAoRIrAnSIDAmTIrAlUIDAkVIrAZWIDAjXIrAiYIDAhZIrA4|JATAIMCAACQCiADUCSABCDQALODgADEESACHERADKFhADFGhADBHSACDHAACLHQABCIjAFBJQA5MJiABULQABKMhADLMgACUMBAR|JAAA6RARA7KCRAFMCSABQCgADUCjAFCDRAEODiACHEhACKFjAFVGSACBHAADDHgACLHAABCIhADOIQACBJAAHMJQAFQJQACPKRADULSABLMgAFUMjA8|JAAA6RARA7KCRAFMCSABQCgADUCjAFCDRAEODiACHEhACKFjAFVGSACBHAADDHgACLHAABCIhADOIQACBJAAHMJQAFQJQACPKRADULSABLMgAFUMjA8|JAQA6RAhA7KCjAFMCQAFQCSACUChADCDTAKODAACHEjADKFBAFVGgACBHiADDHSACLHiABCITADOIAACBJiAHMJSAFQJSACPKTAFULiACLMiABUMgA8|JAQA6RAhA7KCjAFMCQAFQCSACUChADCDTAKODAACHEjADKFBAFVGgACBHiADDHSACLHiABCITADOIAACBJiAHMJSAFQJSACPKTAFULiACLMiABUMgA8|JASA9MCAAFQCQACUCTADCDiAEHEQABKFRAFFGRAFBHSAFLHgAFCIRACOIiACBJSAHMJgADPKhAFULAACLMQADUMTAS|JASA9MCAAFQCQACUCTADCDiAEHEQABKFRAFFGRAFBHSAFLHgAFCIRACOIiACBJSAHMJgADPKhAFULAACLMQADUMTAS|JAhA9MCiAFQCiACUCRACCDAAEHESACFGTAFBHQADLHSAFCIAACBJQAMMJiAFULRACLMSAFUMRA8|JAhA9MCiAFQCiACUCRACCDAAEHESACFGTAFBHQADLHSAFCIAACBJQAMMJiAFULRACLMSAFUMRA8|SCQADWCgA+PERADVGSADVHgACSIAABBJAAMDJgACGKgACPKQACILSACSLRADUMAARPNAA/|SCQADWCgA+PERADVGSADVHgACSIAABBJAAMDJgACGKgACPKQACILSACSLRADUMAARPNAA/|SCiADWCSA+PETAFVGgAFVHSABSIiABBJiAMDJSACRJhAFGKQABPKhACILgADSLTAFUMiARPNiA/|SCiADWCSA+PETAFVGgAFVHSABSIiABBJiAMDJSACRJhAFGKQABPKhACILgADSLTAFUMiARPNiA/|SCgAFWCQBAPEhADTETAFVGiADVHBACSIgAFBJgANDJAADMJRAFRJTAFGKBACPKjADILiADSLjADUMSBBPNSBC|SCgAFWCQBAPEhADTETAFVGiADVHBACSIgAFBJgANDJAADMJRAFRJTAFGKBACPKjADILiADSLjADUMSBBPNSBC|SCSAFWCiBAPEBADTEhAFVGQADVHjACBISACSIQAFBJSANDJiADMJhAFRJRADGKjACPKBADILAADSLBADULgACUMQBBPNQBC|SCSAFWCiBAPEBADTEhAFVGQADVHjACBISACSIQAFBJSANDJiADMJhAFRJRADGKjACPKBADILAADSLBADULgACUMQBBPNQBC|SCQACWChBDGDjAFSDgADPEQACVGQABVHiAFSIAADDJgAFMJjADRJBADGKTADPKSAFULiACUMQASPNiBE|SCQACWChBDGDjAFSDgADPEQACVGQABVHiAFSIAADDJgAFMJjADRJBADGKTADPKSAFULiACUMQASPNiBE|WCTBAGDBAFSDiADPETACVGSABVHgAFSIiADDJSADMJBADRJhADGKRADPKgABULAACUMAA8PNgBE|WCTBAGDBAFSDiADPETACVGSABVHgAFSIiADDJSADMJBADRJhADGKRADPKgABULAACUMAA8PNgBE|ICBAFSCgADWCBBDGDTADSDQACHEBAFPEiABSFQACVGiAFVHQABSIgADDJAAFMJTACRJTACGKjAFPKiABSLhAFULQADIMSACUMgARPNQBF|ICBAFSCgADWCBBDGDTADSDQACHEBAFPEiABSFQACVGiAFVHQABSIgADDJAAFMJTACRJTACGKjAFPKiABSLhAFULQADIMSACUMgARPNQBF|ICjAFSCSACWCjBDGDhAFSDSACPEAABSFgACVGAAFVHAAFSISACDJiAFMJhADRJQACGKhAFPKAABILQACSLBAFULSADIMQACUMSASPNABE|ICjAFSCSACWCjBDGDhAFSDSACPEAABSFgACVGAAFVHAAFSISACDJiAFMJhADRJQACGKhAFPKAABILQACSLBAFULSADIMQACUMSASPNABE'
VN_AL[glitch]='||||||||||||||||||||dWADA3O|dXADA3O|dYADA3O|||||||||||||||||||||||||'
VN_APAL[glitch]='146c70ff2f9f2ff5ffffffff24c4cc9f2fff7070707824c4681ca8701448cccccc7c24ccc4c4c424bcc4a8a8a8982cf8cc247c5c1894949494a4a4a45cf4fcfcfcfcfc48a8802cc86cf8fc60f4fc3cf4fc88f8fca440fcc02478fc6cbca43cfcac206cfc44a84cf4fcfc54b0fc68b870f8fcfc78c080f8fcfc88c890f8fcfc98d0a0f8fc28a4acfc3ca4a844fcc0287cfc7cc4a848fcac4cfc602094c02c7cfc8cc86028947c18501c787cc42478a81c684814701890941ca0a8981c60d0d0d01c949894185c8024d0989898d0248024c8d0'
VN_AF[plasma]='DFgAAEFiAAEFgABFFiACGFgADHFiAEIFhAEKHjAELHhAFMHjAFNIhAFNIjAFOIhAFPIjAERKhAESKiAETKgACUKiABVKgABVKiAAWKgAAYJiAGXIgAAWIiAAWIgABTHiADTHgADSHiAERHhAERHjAEPGhAFOFjAFMEhAFMEjAFMFhAFLFjAEKEhAEHDiAEHDgAHGDiADFCgABECiAA|DFgAAEFiAAEFgABFFiACGFgADHFiAEIFhAEKHjAELHhAFMHjAFNIhAFNIjAFOIhAFPIjAERKhAESKiAETKgACUKiABVKgABVKiAAWKgAAYJiAGXIgAAWIiAAWIgABTHiADTHgADSHiAERHhAERHjAEPGhAFOFjAFMEhAFMEjAFMFhAFLFjAEKEhAEHDiAEHDgAHGDiADFCgABECiAA|DFgAAEFiAAEFgABFFiACGFgADHFiAEIFhAEKHjAELHhAFMHjAFNIhAFNIjAFOIhAFPIjAERKhAESKiAETKgACUKiABVKgABVKiAAWKgAAYJiAGXIgAAWIiAAWIgABTHiADTHgADSHiAERHhAERHjAEPGhAFOFjAFMEhAFMEjAFMFhAFLFjAEKEhAEHDiAEHDgAHGDiADFCgABECiAA|DFgAAEFiAAEFgABFFiACGFgADHFiAEIFhAEKHjAELHhAFMHjAFNIhAFNIjAFOIhAFPIjAERKhAESKiAETKgACUKiABVKgABVKiAAWKgAAYJiAGXIgAAWIiAAWIgABTHiADTHgADSHiAERHhAERHjAEPGhAFOFjAFMEhAFMEjAFMFhAFLFjAEKEhAEHDiAEHDgAHGDiADFCgABECiAA|DFgAAEFiAAEFgABFFiACGFgADHFiAEIFhAEKHjAELHhAFMHjAFNIhAFNIjAFOIhAFPIjAERKhAESKiAETKgACUKiABVKgABVKiAAWKgAAYJiAGXIgAAWIiAAWIgABTHiADTHgADSHiAERHhAERHjAEPGhAFOFjAFMEhAFMEjAFMFhAFLFjAEKEhAEHDiAEHDgAHGDiADFCgABECiAA|DFgAAEFiAAEFgABFFiACGFgADHFiAEIFhAEKHjAELHhAFMHjAFNIhAFNIjAFOIhAFPIjAERKhAESKiAETKgACUKiABVKgABVKiAAWKgAAYJiAGXIgAAWIiAAWIgABTHiADTHgADSHiAERHhAERHjAEPGhAFOFjAFMEhAFMEjAFMFhAFLFjAEKEhAEHDiAEHDgAHGDiADFCgABECiAA|CDgAJDEiAAEEgABFFiABHGgAKIGiAEJHhAEJHjAEKGhALLHjAMMHhAMNIjANPIhAMQJjAERJhAESJiAETKgACULiABVLgABWLgAOXIiAAYJgAGXJiAAVIgABUHiADTHgAPSGiAERGhAEQGjAEOFhAFNFjAFOGhANMFjAFLEhAQKEjAEKEhAEIEiAEHDgABGDiABFCgABECgAADCiAO|CDgAJDEiAAEEgABFFiABHGgAKIGiAEJHhAEJHjAEKGhALLHjAMMHhAMNIjANPIhAMQJjAERJhAESJiAETKgACULiABVLgABWLgAOXIiAAYJgAGXJiAAVIgABUHiADTHgAPSGiAERGhAEQGjAEOFhAFNFjAFOGhANMFjAFLEhAQKEjAEKEhAEIEiAEHDgABGDiABFCgABECgAADCiAO|CDgAJDEiAAEEgABFFiABHGgAKIGiAEJHhAEJHjAEKGhALLHjAMMHhAMNIjANPIhAMQJjAERJhAESJiAETKgACULiABVLgABWLgAOXIiAAYJgAGXJiAAVIgABUHiADTHgAPSGiAERGhAEQGjAEOFhAFNFjAFOGhANMFjAFLEhAQKEjAEKEhAEIEiAEHDgABGDiABFCgABECgAADCiAO|CDgAJDEiAAEEgABFFiABHGgAKIGiAEJHhAEJHjAEKGhALLHjAMMHhAMNIjANPIhAMQJjAERJhAESJiAETKgACULiABVLgABWLgAOXIiAAYJgAGXJiAAVIgABUHiADTHgAPSGiAERGhAEQGjAEOFhAFNFjAFOGhANMFjAFLEhAQKEjAEKEhAEIEiAEHDgABGDiABFCgABECgAADCiAO|CDgAJDEiAAEEgABFFiABHGgAKIGiAEJHhAEJHjAEKGhALLHjAMMHhAMNIjANPIhAMQJjAERJhAESJiAETKgACULiABVLgABWLgAOXIiAAYJgAGXJiAAVIgABUHiADTHgAPSGiAERGhAEQGjAEOFhAFNFjAFOGhANMFjAFLEhAQKEjAEKEhAEIEiAEHDgABGDiABFCgABECgAADCiAO|CDgAJDEiAAEEgABFFiABHGgAKIGiAEJHhAEJHjAEKGhALLHjAMMHhAMNIjANPIhAMQJjAERJhAESJiAETKgACULiABVLgABWLgAOXIiAAYJgAGXJiAAVIgABUHiADTHgAPSGiAERGhAEQGjAEOFhAFNFjAFOGhANMFjAFLEhAQKEjAEKEhAEIEiAEHDgABGDiABFCgABECgAADCiAO|BEiAGEFiAAEEgABEEiABGFgAKHFiAEJHhAEKHjAEKGhAMLHjANMHhANNHjANPJhAQQJjAEQIhAERJiAETKgABTKiABVLgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUHiABTHgARTHiAERGhAEQGjAEPGhAFOGjAMNFhANMFjANMFhANJDjAEJDhAEIDiAEHDgACHDiACFDgABFDiAA|BEiAGEFiAAEEgABEEiABGFgAKHFiAEJHhAEKHjAEKGhAMLHjANMHhANNHjANPJhAQQJjAEQIhAERJiAETKgABTKiABVLgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUHiABTHgARTHiAERGhAEQGjAEPGhAFOGjAMNFhANMFjANMFhANJDjAEJDhAEIDiAEHDgACHDiACFDgABFDiAA|BEiAGEFiAAEEgABEEiABGFgAKHFiAEJHhAEKHjAEKGhAMLHjANMHhANNHjANPJhAQQJjAEQIhAERJiAETKgABTKiABVLgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUHiABTHgARTHiAERGhAEQGjAEPGhAFOGjAMNFhANMFjANMFhANJDjAEJDhAEIDiAEHDgACHDiACFDgABFDiAA|BEiAGEFiAAEEgABEEiABGFgAKHFiAEJHhAEKHjAEKGhAMLHjANMHhANNHjANPJhAQQJjAEQIhAERJiAETKgABTKiABVLgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUHiABTHgARTHiAERGhAEQGjAEPGhAFOGjAMNFhANMFjANMFhANJDjAEJDhAEIDiAEHDgACHDiACFDgABFDiAA|BEiAGEFiAAEEgABEEiABGFgAKHFiAEJHhAEKHjAEKGhAMLHjANMHhANNHjANPJhAQQJjAEQIhAERJiAETKgABTKiABVLgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUHiABTHgARTHiAERGhAEQGjAEPGhAFOGjAMNFhANMFjANMFhANJDjAEJDhAEIDiAEHDgACHDiACFDgABFDiAA|BEiAGEFiAAEEgABEEiABGFgAKHFiAEJHhAEKHjAEKGhAMLHjANMHhANNHjANPJhAQQJjAEQIhAERJiAETKgABTKiABVLgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUHiABTHgARTHiAERGhAEQGjAEPGhAFOGjAMNFhANMFjANMFhANJDjAEJDhAEIDiAEHDgACHDiACFDgABFDiAA|BEiAGCDgAJDEiAAEEgABFFiABHGgASIGiAEJGhAEKHjAEKHhAMMHjATMHhATNIjAMOHhAMPIjAEQIhAERJiAETKgABTJiABVLgABYJiAGWIgAAXJiAAUHgADTHiASTHgASSGiAERGhAEQGjAEQGhAMOGjATOGhATNFjAMLEhAUJDjAIJDhAIIDiAIHDgABGDiABFDgABECiAADCiAO|BEiAGCDgAJDEiAAEEgABFFiABHGgASIGiAEJGhAEKHjAEKHhAMMHjATMHhATNIjAMOHhAMPIjAEQIhAERJiAETKgABTJiABVLgABYJiAGWIgAAXJiAAUHgADTHiASTHgASSGiAERGhAEQGjAEQGhAMOGjATOGhATNFjAMLEhAUJDjAIJDhAIIDiAIHDgABGDiABFDgABECiAADCiAO|BEiAGCDgAJDEiAAEEgABFFiABHGgASIGiAEJGhAEKHjAEKHhAMMHjATMHhATNIjAMOHhAMPIjAEQIhAERJiAETKgABTJiABVLgABYJiAGWIgAAXJiAAUHgADTHiASTHgASSGiAERGhAEQGjAEQGhAMOGjATOGhATNFjAMLEhAUJDjAIJDhAIIDiAIHDgABGDiABFDgABECiAADCiAO|BEiAGCDgAJDEiAAEEgABFFiABHGgASIGiAEJGhAEKHjAEKHhAMMHjATMHhATNIjAMOHhAMPIjAEQIhAERJiAETKgABTJiABVLgABYJiAGWIgAAXJiAAUHgADTHiASTHgASSGiAERGhAEQGjAEQGhAMOGjATOGhATNFjAMLEhAUJDjAIJDhAIIDiAIHDgABGDiABFDgABECiAADCiAO|BEiAGCDgAJDEiAAEEgABFFiABHGgASIGiAEJGhAEKHjAEKHhAMMHjATMHhATNIjAMOHhAMPIjAEQIhAERJiAETKgABTJiABVLgABYJiAGWIgAAXJiAAUHgADTHiASTHgASSGiAERGhAEQGjAEQGhAMOGjATOGhATNFjAMLEhAUJDjAIJDhAIIDiAIHDgABGDiABFDgABECiAADCiAO|BEiAGCDgAJDEiAAEEgABFFiABHGgASIGiAEJGhAEKHjAEKHhAMMHjATMHhATNIjAMOHhAMPIjAEQIhAERJiAETKgABTJiABVLgABYJiAGWIgAAXJiAAUHgADTHiASTHgASSGiAERGhAEQGjAEQGhAMOGjATOGhATNFjAMLEhAUJDjAIJDhAIIDiAIHDgABGDiABFDgABECiAADCiAO|EFiAAFFgABGFiACGFgACHGiAEIGhAEJGjAEKGhAMLGjAMMHhATOJjALPJhAVQJjAERKhAISKiAITKgABUKiABVLgABWLiAOWLgAOYJiAGXIgAAWIiAAUHgADUHiADTHgASTHiAERGhAEQGjAEOFhAMNFjAMOGhATLEjAULFhAFKEjAEKEhAEHDiAIHDgABGDiABFCgABECiAA|EFiAAFFgABGFiACGFgACHGiAEIGhAEJGjAEKGhAMLGjAMMHhATOJjALPJhAVQJjAERKhAISKiAITKgABUKiABVLgABWLiAOWLgAOYJiAGXIgAAWIiAAUHgADUHiADTHgASTHiAERGhAEQGjAEOFhAMNFjAMOGhATLEjAULFhAFKEjAEKEhAEHDiAIHDgABGDiABFCgABECiAA|EFiAAFFgABGFiACGFgACHGiAEIGhAEJGjAEKGhAMLGjAMMHhATOJjALPJhAVQJjAERKhAISKiAITKgABUKiABVLgABWLiAOWLgAOYJiAGXIgAAWIiAAUHgADUHiADTHgASTHiAERGhAEQGjAEOFhAMNFjAMOGhATLEjAULFhAFKEjAEKEhAEHDiAIHDgABGDiABFCgABECiAA|EFiAAFFgABGFiACGFgACHGiAEIGhAEJGjAEKGhAMLGjAMMHhATOJjALPJhAVQJjAERKhAISKiAITKgABUKiABVLgABWLiAOWLgAOYJiAGXIgAAWIiAAUHgADUHiADTHgASTHiAERGhAEQGjAEOFhAMNFjAMOGhATLEjAULFhAFKEjAEKEhAEHDiAIHDgABGDiABFCgABECiAA|EFiAAFFgABGFiACGFgACHGiAEIGhAEJGjAEKGhAMLGjAMMHhATOJjALPJhAVQJjAERKhAISKiAITKgABUKiABVLgABWLiAOWLgAOYJiAGXIgAAWIiAAUHgADUHiADTHgASTHiAERGhAEQGjAEOFhAMNFjAMOGhATLEjAULFhAFKEjAEKEhAEHDiAIHDgABGDiABFCgABECiAA|EFiAAFFgABGFiACGFgACHGiAEIGhAEJGjAEKGhAMLGjAMMHhATOJjALPJhAVQJjAERKhAISKiAITKgABUKiABVLgABWLiAOWLgAOYJiAGXIgAAWIiAAUHgADUHiADTHgASTHiAERGhAEQGjAEOFhAMNFjAMOGhATLEjAULFhAFKEjAEKEhAEHDiAIHDgABGDiABFCgABECiAA|CEgAADEiAAEFgABGFiAKHGgADHFiAEIGhAEJGjAEKHhAUMHjAFNIhAFOJjAFOIhAFPIjAERJhAESKiAETKgAHULiACUKgADVKiAWXIiAAYJgAGXJiAAWIgABUIiADTHgADSHiAEQGhAERHjAEPGhAFOGjAFNFhAFMFjAFLEhAUKEjAEJEhAEIDiAEHDgACGCiABFCgABECgAA|CEgAADEiAAEFgABGFiAKHGgADHFiAEIGhAEJGjAEKHhAUMHjAFNIhAFOJjAFOIhAFPIjAERJhAESKiAETKgAHULiACUKgADVKiAWXIiAAYJgAGXJiAAWIgABUIiADTHgADSHiAEQGhAERHjAEPGhAFOGjAFNFhAFMFjAFLEhAUKEjAEJEhAEIDiAEHDgACGCiABFCgABECgAA|CEgAADEiAAEFgABGFiAKHGgADHFiAEIGhAEJGjAEKHhAUMHjAFNIhAFOJjAFOIhAFPIjAERJhAESKiAETKgAHULiACUKgADVKiAWXIiAAYJgAGXJiAAWIgABUIiADTHgADSHiAEQGhAERHjAEPGhAFOGjAFNFhAFMFjAFLEhAUKEjAEJEhAEIDiAEHDgACGCiABFCgABECgAA|CEgAADEiAAEFgABGFiAKHGgADHFiAEIGhAEJGjAEKHhAUMHjAFNIhAFOJjAFOIhAFPIjAERJhAESKiAETKgAHULiACUKgADVKiAWXIiAAYJgAGXJiAAWIgABUIiADTHgADSHiAEQGhAERHjAEPGhAFOGjAFNFhAFMFjAFLEhAUKEjAEJEhAEIDiAEHDgACGCiABFCgABECgAA|CEgAADEiAAEFgABGFiAKHGgADHFiAEIGhAEJGjAEKHhAUMHjAFNIhAFOJjAFOIhAFPIjAERJhAESKiAETKgAHULiACUKgADVKiAWXIiAAYJgAGXJiAAWIgABUIiADTHgADSHiAEQGhAERHjAEPGhAFOGjAFNFhAFMFjAFLEhAUKEjAEJEhAEIDiAEHDgACGCiABFCgABECgAA|CEgAADEiAAEFgABGFiAKHGgADHFiAEIGhAEJGjAEKHhAUMHjAFNIhAFOJjAFOIhAFPIjAERJhAESKiAETKgAHULiACUKgADVKiAWXIiAAYJgAGXJiAAWIgABUIiADTHgADSHiAEQGhAERHjAEPGhAFOGjAFNFhAFMFjAFLEhAUKEjAEJEhAEIDiAEHDgACGCiABFCgABECgAA|BEiAGEFiAAEEgABFEiABHGgAXHGiAEJGhAEJGjAELHhANMIjAFMHhANNHjANPIhALPIjAERJhAERJiAETKgABUKiABUKgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUIiABUIgABRGiAESHhAERHjAEOFhANOFjANNFhANMFjANLFhAMLFjAEJEhAEIEiAEIEgAHFCiABFCgABECiAADCgAO|BEiAGEFiAAEEgABFEiABHGgAXHGiAEJGhAEJGjAELHhANMIjAFMHhANNHjANPIhALPIjAERJhAERJiAETKgABUKiABUKgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUIiABUIgABRGiAESHhAERHjAEOFhANOFjANNFhANMFjANLFhAMLFjAEJEhAEIEiAEIEgAHFCiABFCgABECiAADCgAO|BEiAGEFiAAEEgABFEiABHGgAXHGiAEJGhAEJGjAELHhANMIjAFMHhANNHjANPIhALPIjAERJhAERJiAETKgABUKiABUKgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUIiABUIgABRGiAESHhAERHjAEOFhANOFjANNFhANMFjANLFhAMLFjAEJEhAEIEiAEIEgAHFCiABFCgABECiAADCgAO|BEiAGEFiAAEEgABFEiABHGgAXHGiAEJGhAEJGjAELHhANMIjAFMHhANNHjANPIhALPIjAERJhAERJiAETKgABUKiABUKgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUIiABUIgABRGiAESHhAERHjAEOFhANOFjANNFhANMFjANLFhAMLFjAEJEhAEIEiAEIEgAHFCiABFCgABECiAADCgAO|BEiAGEFiAAEEgABFEiABHGgAXHGiAEJGhAEJGjAELHhANMIjAFMHhANNHjANPIhALPIjAERJhAERJiAETKgABUKiABUKgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUIiABUIgABRGiAESHhAERHjAEOFhANOFjANNFhANMFjANLFhAMLFjAEJEhAEIEiAEIEgAHFCiABFCgABECiAADCgAO|BEiAGEFiAAEEgABFEiABHGgAXHGiAEJGhAEJGjAELHhANMIjAFMHhANNHjANPIhALPIjAERJhAERJiAETKgABUKiABUKgABWLiAOYIgAAXIiAAXIgAAWIiAAVIgABUIiABUIgABRGiAESHhAERHjAEOFhANOFjANNFhANMFjANLFhAMLFjAEJEhAEIEiAEIEgAHFCiABFCgABECiAADCgAO|BEiAGCDgAJDEiAAFFgABFEiABHGgAXIGiAEJGhAEKHjAEKHhAFMHjANMHhANNIjAFPJhAQQJjAERKhAIRJiAETKgABULiABVKgABWLiAOWLgAOYJiAGWIgAAXJiAAVHgABUHiABTHgARSHiAESHhAEQHjAEPFhAFNFjANNFhANMFjANMFhANKEjAEJDhAEIDiAEHDgACGDiABGDgABFDiAA|BEiAGCDgAJDEiAAFFgABFEiABHGgAXIGiAEJGhAEKHjAEKHhAFMHjANMHhANNIjAFPJhAQQJjAERKhAIRJiAETKgABULiABVKgABWLiAOWLgAOYJiAGWIgAAXJiAAVHgABUHiABTHgARSHiAESHhAEQHjAEPFhAFNFjANNFhANMFjANMFhANKEjAEJDhAEIDiAEHDgACGDiABGDgABFDiAA|BEiAGCDgAJDEiAAFFgABFEiABHGgAXIGiAEJGhAEKHjAEKHhAFMHjANMHhANNIjAFPJhAQQJjAERKhAIRJiAETKgABULiABVKgABWLiAOWLgAOYJiAGWIgAAXJiAAVHgABUHiABTHgARSHiAESHhAEQHjAEPFhAFNFjANNFhANMFjANMFhANKEjAEJDhAEIDiAEHDgACGDiABGDgABFDiAA|BEiAGCDgAJDEiAAFFgABFEiABHGgAXIGiAEJGhAEKHjAEKHhAFMHjANMHhANNIjAFPJhAQQJjAERKhAIRJiAETKgABULiABVKgABWLiAOWLgAOYJiAGWIgAAXJiAAVHgABUHiABTHgARSHiAESHhAEQHjAEPFhAFNFjANNFhANMFjANMFhANKEjAEJDhAEIDiAEHDgACGDiABGDgABFDiAA|BEiAGCDgAJDEiAAFFgABFEiABHGgAXIGiAEJGhAEKHjAEKHhAFMHjANMHhANNIjAFPJhAQQJjAERKhAIRJiAETKgABULiABVKgABWLiAOWLgAOYJiAGWIgAAXJiAAVHgABUHiABTHgARSHiAESHhAEQHjAEPFhAFNFjANNFhANMFjANMFhANKEjAEJDhAEIDiAEHDgACGDiABGDgABFDiAA|BEiAGCDgAJDEiAAFFgABFEiABHGgAXIGiAEJGhAEKHjAEKHhAFMHjANMHhANNIjAFPJhAQQJjAERKhAIRJiAETKgABULiABVKgABWLiAOWLgAOYJiAGWIgAAXJiAAVHgABUHiABTHgARSHiAESHhAEQHjAEPFhAFNFjANNFhANMFjANMFhANKEjAEJDhAEIDiAEHDgACGDiABGDgABFDiAA'
VN_AL[plasma]='dYAIA3IcUAIA3I|dYAIA3IcUAIA3I|dYAIA3IcUAIA3I|dYAIA3IcUAIA3I|dYAIA3IcUAIA3I|dYAIA3IcUAIA3I|dYAIA3IeWAIA3I|dYAIA3IeWAIA3I|dYAIA3IeWAIA3I|dYAIA3IeWAIA3I|dYAIA3IeWAIA3I|dYAIA3IeWAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|cXAIA3IeWAIA3I|eZAIA3IdVAIA3I|eZAIA3IdVAIA3I|eZAIA3IdVAIA3I|eZAIA3IdVAIA3I|eZAIA3IdVAIA3I|eZAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I|cXAIA3IdVAIA3I'
VN_APAL[plasma]='4a6ad08fb8ff90b8fc98bcfcdcecfcecf4fc3850a09cc0fcdfefff3854a494b8fcf0f4fce8f4fce8f0fc2c407ca4c4fcf8f8fc98b8fca0c0fce4f0fcf0f8fcf4f4fc5070d0a0c4fc'
VN_AF[shadow]='INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMmAGGLOAHJMOAINMmAJNLmAKNKOALUMmAMULmAHUKmANUJOAO|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQGMOAGJMmAIJLOAGNMmAJNLOAKRMOAIUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKmAQDJOARJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFUMOAM|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQJMmAIJLmAGJKmAFJJOASRMmAIRLmAGRKmAFRJOASXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMOAGJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFXKmALXJOAR|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANJMOAINMmAJNLOAKRMmAIRLOAGUMOAMXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKmANGJOAONMmAJNLmAKNKOALRMOAIUMmAMULOAH|INqAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANNMmAJNLmAKNKmALNJOASUMmAMULmAHUKOAN|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLOAFGMmAGGLOAHJMOAINMmAJNLmAKNKOALUMmAMULmAHUKmANUJOAO|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLmAFDKOAQGMOAGJMmAIJLOAGNMmAJNLOAKRMOAIUMmAMULmAHUKOAN|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLmAFDKmAQDJOARJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFUMOAM|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLmAFDKOAQJMmAIJLmAGJKmAFJJOASRMmAIRLmAGRKmAFRJOASXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMOAGJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFXKmALXJOAR|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANJMOAINMmAJNLOAKRMmAIRLOAGUMOAMXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKmANGJOAONMmAJNLmAKNKOALRMOAIUMmAMULOAH|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANNMmAJNLmAKNKmALNJOASUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMmAGGLOAHJMOAINMmAJNLmAKNKOALUMmAMULmAHUKmANUJOAO|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQGMOAGJMmAIJLOAGNMmAJNLOAKRMOAIUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKmAQDJOARJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFUMOAM|INqAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQJMmAIJLmAGJKmAFJJOASRMmAIRLmAGRKmAFRJOASXKOAL|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLOAFGMOAGJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFXKmALXJOAR|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAAGMmAGGLmAHGKOANJMOAINMmAJNLOAKRMmAIRLOAGUMOAMXKOAL|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAAGMmAGGLmAHGKmANGJOAONMmAJNLmAKNKOALRMOAIUMmAMULOAH|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAAGMmAGGLmAHGKOANNMmAJNLmAKNKmALNJOASUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMmAGGLOAHJMOAINMmAJNLmAKNKOALUMmAMULmAHUKmANUJOAO|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQGMOAGJMmAIJLOAGNMmAJNLOAKRMOAIUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKmAQDJOARJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFUMOAM|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQJMmAIJLmAGJKmAFJJOASRMmAIRLmAGRKmAFRJOASXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMOAGJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFXKmALXJOAR|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANJMOAINMmAJNLOAKRMmAIRLOAGUMOAMXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKmANGJOAONMmAJNLmAKNKOALRMOAIUMmAMULOAH|INqAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANNMmAJNLmAKNKmALNJOASUMmAMULmAHUKOAN|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLOAFGMmAGGLOAHJMOAINMmAJNLmAKNKOALUMmAMULmAHUKmANUJOAO|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLmAFDKOAQGMOAGJMmAIJLOAGNMmAJNLOAKRMOAIUMmAMULmAHUKOAN|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLmAFDKmAQDJOARJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFUMOAM|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLmAFDKOAQJMmAIJLmAGJKmAFJJOASRMmAIRLmAGRKmAFRJOASXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMOAGJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFXKmALXJOAR|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANJMOAINMmAJNLOAKRMmAIRLOAGUMOAMXKOAL|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKmANGJOAONMmAJNLmAKNKOALRMOAIUMmAMULOAH|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAAGMmAGGLmAHGKOANNMmAJNLmAKNKmALNJOASUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLOAFGMmAGGLOAHJMOAINMmAJNLmAKNKOALUMmAMULmAHUKmANUJOAO|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQGMOAGJMmAIJLOAGNMmAJNLOAKRMOAIUMmAMULmAHUKOAN|INAAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKmAQDJOARJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFUMOAM|INqAAJNAABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNAAADLmAFDKOAQJMmAIJLmAGJKmAFJJOASRMmAIRLmAGRKmAFRJOASXKOAL|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAADLOAFGMOAGJMmAIJLmAGJKOAFRMmAIRLmAGRKOAFXKmALXJOAR|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAAGMmAGGLmAHGKOANJMOAINMmAJNLOAKRMmAIRLOAGUMOAMXKOAL|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAAGMmAGGLmAHGKmANGJOAONMmAJNLmAKNKOALRMOAIUMmAMULOAH|INqAAJNqABKNAACLNAADMNAACNNAACONAACPNAAEQNAABRNqAAGMmAGGLmAHGKOANNMmAJNLmAKNKmALNJOASUMmAMULmAHUKOAN'
VN_AL[shadow]='ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM|ddAPAyM'
VN_APAL[shadow]='0c0810100c1814102018102014101c34244848346050386c44305c38285040305c3024442c203c38284c281c340a0810402f582a2038241c30'
VN_AF[drizzle]='JKKAAQGKAB|JLKAAQHKABXDKAC|JMKAAQIKABXEKAD|JNKAEQJKABXFKAD|QKKABXGKAD|CDKAFQLKABXHKAB|CEKAAJAKAGQMKAAXIKAB|CFKAAJBKABQNKAEXJKAB|CGKAAJCKABXKKAF|CHKAAJDKAB|CIKAAJEKABQAKAH|CJKAAJFKABQBKAD|CKKAIJGKABQCKAD|JHKABQDKAD|JIKAAQEKAB|JJKAAQFKAB|JKKAAQGKAB|JLKAAQHKABXDKAC|JMKAAQIKABXEKAD|JNKAEQJKABXFKAD|QKKABXGKAD|CDKAFQLKABXHKAB|CEKAAJAKAGQMKAAXIKAB|CFKAAJBKABQNKAEXJKAB|CGKAAJCKABXKKAF|CHKAAJDKAB|CIKAAJEKABQAKAH|CJKAAJFKABQBKAD|CKKAIJGKABQCKAD|JHKABQDKAD|JIKAAQEKAB|JJKAAQFKAB|JKKAAQGKAB|JLKAAQHKABXDKAC|JMKAAQIKABXEKAD|JNKAEQJKABXFKAD|QKKABXGKAD|CDKAFQLKABXHKAB|CEKAAJAKAGQMKAAXIKAB|CFKAAJBKABQNKAEXJKAB|CGKAAJCKABXKKAF|CHKAAJDKAB|CIKAAJEKABQAKAH|CJKAAJFKABQBKAD|CKKAIJGKABQCKAD|JHKABQDKAD|JIKAAQEKAB|JJKAAQFKAB'
VN_AL[drizzle]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[drizzle]='283c4c385064385468486c841824302c40502434402c445420303c'
VN_AF[static]='LN3AALIGABGB3ACGJ3ABECHADFLHAEHKHAEBI3AEAF2AF|LN3AALIGABGB3ACGJ3ABECHADFLHAEHKHAEBI3AEAF2AF|JGHAELIGAEKB3ABHF2AEEI2ADKKGADECHAEHKHADXIGADAF2AG|JGHAELIGAEKB3ABHF2AEEI2ADKKGADECHAEHKHADXIGADAF2AG|JGHABILGAEJAHAHEI2ABCG3ABHF2ADXIGAE|JGHABILGAEJAHAHEI2ABCG3ABHF2ADXIGAE|FG2AEPIGAEMD2ABJG3AECJ3ADGH2AEWEHADTIGABFJ2AD|FG2AEPIGAEMD2ABJG3AECJ3ADGH2AEWEHADTIGABFJ2AD|RB3AEAI2AGLF2ADKKGABGMHAIFDGAD|RB3AEAI2AGLF2ADKKGABGMHAIFDGAD|NB2ABELGADGB3AJOKGADLNHAKHC2AB|NB2ABELGADGB3AJOKGADLNHAKHC2AB|EC3ADHH3ABTI3ADJMGAEID2ADDKGAEYGGABSEHABEF3ABHK3AE|EC3ADHH3ABTI3ADJMGAEID2ADDKGAEYGGABSEHABEF3ABHK3AE|SK3AETI3AEPFHABNG3AEVJ3ABJD3ABPH3ABJJGAD|SK3AETI3AEPFHABNG3AEVJ3ABJD3ABPH3ABJJGAD|CJHAEQDHAERM3ABWHHAEBG2ABKBHAE|CJHAEQDHAERM3ABWHHAEBG2ABKBHAE|RB3ADNM3ADXFHADPA2ALTC3AELKHADIAGAMOC2ABRB2AEOE2ADUGGADLC3AB|RB3ADNM3ADXFHADPA2ALTC3AELKHADIAGAMOC2ABRB2AEOE2ADUGGADLC3AB|DH3ABSK3ABXJ2ADTFHAD|DH3ABSK3ABXJ2ADTFHAD|WK3ABWL2ANMIHAEQJGAE|WK3ABWL2ANMIHAEQJGAE|YJ2AOPIGABPLGABOC2AELL2ABFJ2ABKE2AERB2AB|YJ2AOPIGABPLGABOC2AELL2ABFJ2ABKE2AERB2AB|UDHABHH3AEAI2APXG2ABSC2ABDKGADBI3ADYGGAD|UDHABHH3AEAI2APXG2ABSC2ABDKGADBI3ADYGGAD|OKGABNB2AEIIHABTFGABOM3ADNE2ADMIHABJD3ADHC2ADTIGAEPHHAE|OKGABNB2AEIIHABTFGABOM3ADNE2ADMIHABJD3ADHC2ADTIGAEPHHAE|ZH3AQUJ2ABVGHADAF3AFRDHADWCHARSB3AEPF2ADTL3AEOM3AELBHADMNHASNJHAEIK3AEJI3AB|ZH3AQUJ2ABVGHADAF3AFRDHADWCHARSB3AEPF2ADTL3AEOM3AELBHADMNHASNJHAEIK3AEJI3AB|RMGADTL3ABUBGATON2AA|RMGADTL3ABUBGATON2AA|EG2ABPKHABVHGABRMGAEREGABQFHADNJGABQA2AHKG3ABPC3ABHBHADSHHAE|EG2ABPKHABVHGABRMGAEREGABQFHADNJGABQA2AHKG3ABPC3ABHBHADSHHAE|OJHADBJ2AUUD2ABPF2AEREGADQJGABMG2AD|OJHADBJ2AUUD2ABPF2AEREGADQJGABMG2AD|UM2AVYJ2AUWFGABLKGAEXGGABSHGADZF2AFINHAWMLGAEUB2AV|UM2AVYJ2AUWFGABLKGAEXGGABSHGADZF2AFINHAWMLGAEUB2AV|MCHABUDHAEWK3AEXFHABGMGAJKMHAEHH2ADIF3ADUGHADPCHAE|MCHABUDHAEWK3AEXFHABGMGAJKMHAEHH2ADIF3ADUGHADPCHAE|WCGANIGGADND3ADYJ3AOKBGADMF3ADKE2ADWIGAE|WCGANIGGADND3ADYJ3AOKBGADMF3ADKE2ADWIGAE|KGHAEXG2ADMA3ASJAGAXNJHAB|KGHAEXG2ADMA3ASJAGAXNJHAB|QLHADKN3AYLNGAAGKGABHK2AEII2ABAI3AFBG3ABWHHADXDGAZSEHAD|QLHADKN3AYLNGAAGKGABHK2AEII2ABAI3AFBG3ABWHHADXDGAZSEHAD'
VN_AL[static]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[static]='606078a8a8c0dcdce8e8e8f46a6a8454546034344044445464647ca0a0b8d4d4e0bcbcc84c4c544040505050647474787070848c8c946464803c3c4cb0b0bc8888903030386c6c7c54546cb8b8c4'
VN_AF[fireflies]='MGHAACEHABMD4ACMDHAD|NH5ABCGHAFNC4AGWL4AHLE5AICDGAJ|PJ5AKPBGABWL4AHJF5AK|QK5AKIIGALQBGAFVK4AIIH5AM|RL5AKHHGANVJGABHI5AO|SL5ABUC4AKGG4AIELHAPUHGAFGJ5AI|TMHAQTD4AKFE4AKFLHARFKHABFB4AS|ULHAPSE4AGED4AMGL5ABUDGATELHAUGB4AQ|RFGABDC4AHHL5AKVEGAAHCGAB|QHGAFIL5AKVF4ABQCGAPIEGAF|JK5AKWH4AKPBGAA|WHHALLJ5AIWI4AMNB4ABCKHAV|WGHAAMIHABWJ4AKMB4AKCJHAA|WF5ABLLGAPNGHAFWK4AILB4AKCI5AINJGAP|WD5AKJLGAAWLGAWJB4AKCH5AKPKGAA|VC5AKIL4AIDEGALVLGAFIC4AIDF5AMQL4AB|HL4AKDFGANHDGABDE5AORL4AK|UB5AXGK4AKEG4ABSBHAUGFGAYED5AISL4AK|TBHAQFJ4ACFI4AZTBHAaFCHABTL4AK|SBHAAEI4ABGJ4AMUB5ASSJGAPGBHAbUL4AI|DHGABHK4AKRIGAAVKGAB|DFGAFIL4AIQH4ABDKGAPVIGAF|JLGABWC5AHPF4AK|NFHALLLGAFWD5AINE4AMLCHAP|MGHAAWEHABMD4ACMDHAD|LH5AIWGHAPLC4AGNE5ABWDGAP|JJ5AKJBGABPF5AKWCGAc|IK5AKQIGALIBGAFDK4ABQH5AM|HL5AKRHGANDJGABRI5AO|GL5AIEC4AKSG4ABULHAPEHGAFSJ5AIUB4AS|FMHAXFD4AKTE4AKTLHARTKHABTB4Ad|ELHAFGE4AGUD4AMSL5ABEDGATULHAeSB4AI|HFGABVC4AMRL5AKDEGAARCGAB|IHGAFQL5AKDF4ABICGAPQEGAP|PK5AKCH4AKJBGAA|CHHALNJ5ABCI4AMLB4ABWKHAP|CGHAAMIHABCJ4AKMB4AKWJHAA|CF5ABNLGAPLGHAPCK4AfNB4AKWI5AILJGAP|CD5AgPLGAAPB4AKWH5AKJKGAA|DC5AHQL4ABVEGALDLGAhQC4AIVF5AMIL4AI|RL4AKVFGANRDGABVE5AOHL4AK|SK4AKUG4ABGBHAiSFGAYUD5AIGL4AK|FBHAXTJ4ACTI4AZFBHAjTCHABFL4AK|GBHAkUI4AMSJ4AMGJGAPSBHAPEL4AI|VHGABRK4AKHIGAADKGAB|VFGAFQL4AIIH4ABVKGAPDIGAP|PLGABJF4AKWLGAc|LFHALNLGAFCD5AlLE4AMWL4AWNCHAP'
VN_AL[fireflies]='cWAEARFSUAEARFcTAEAgFmcAEAgFcTAEARF|dXAEAaFmRAEAJFSWAEAJFdSAEAaFmbAEAiFbUAEAaFSTAEAJF|fZAEAgFmRAEARFfRAEARFmbAEAgFZVAEAgFSSAEARF|gaAEAiFlRAEAZFYYAEAIFgRAEAJFlaAEAaFYXAEAiFTRAEAaF|hbAEAgFlRAEAgFXXAEARFlZAEARFXYAEAgFTRAEAgF|ibAEAaFkSAEAiFWWAEAaFUbAEAIFkXAEAJFWZAEAaFURAEAiF|jcAEARFjTAEAgFVUAEAgFVbAEARFVaAEARFVRAEAgF|kbAEAIFiUAEAaFUTAEAiFWbAEAZFkTAEAIFUbAEAIFWRAEAZF|hVAEARFTSAEAgFXbAEAgFlUAEARFXSAEARF|gXAEAJFTRAEAaFYbAEAiFlVAEAZFgSAEAIFYUAEAJF|SRAEARFZaAEAgFmXAEAgFfRAEARF|mXAEAIFSRAEAJFbZAEAaFmYAEAiFdRAEAZFSaAEAIF|mWAEARFcYAEARFmZAEAgFcRAEAgFSZAEARF|mVAEAZFbbAEAIFdWAEAJFmaAEAaFbRAEAiFSYAEAaFdZAEAIF|mTAEAgFZbAEARFmbAEARFZRAEAgFSXAEAgFfaAEARF|lSAEAiFYbAEAaFTUAEAIFlbAEAJFYSAEAaFTVAEAiFgbAEAZF|lRAEAgFXbAEAgFTVAEARFXTAEARFTUAEAgFhbAEAgF|kRAEAaFWaAEAiFUWAEAZFiRAEAIFWVAEAJFUTAEAaFibAEAiF|jRAEARFVZAEAgFVYAEAgFjRAEARFVSAEARFjbAEAgF|iRAEAJFUYAEAZFWZAEAiFkRAEAaFiZAEAIFWRAEAJFkbAEAaF|TXAEARFXaAEAgFlRAEAgFhYAEARFlaAEARF|TVAEAJFYbAEAaFlRAEAiFgXAEAZFTaAEAJFlYAEAJF|ZbAEARFmSAEAgFfVAEAgFSbAEARF|dVAEAJFbbAEAJFmTAEAaFdUAEAiFSbAEAaFbSAEAIF|cWAEARFmUAEARFcTAEAgFScAEAgFcTAEARF|bXAEAaFSRAEAIFmWAEAIFbSAEAaFSbAEAiFdUAEAZFmTAEAIF|ZZAEAgFSRAEARFZRAEARFSbAEAgFfVAEAgFmSAEARF|YaAEAiFTRAEAZFgYAEAIFYRAEAJFTaAEAZFgXAEAiFlRAEAaF|XbAEAgFTRAEAgFhXAEARFTZAEARFhYAEAgFlRAEAgF|WbAEAaFUSAEAiFiWAEAZFkbAEAIFUXAEAJFiZAEAaFkRAEAiF|VcAEARFVTAEAgFjUAEAgFjbAEARFjaAEARFjRAEAgF|UbAEAJFWUAEAaFkTAEAiFibAEAZFUTAEAIFkbAEAJFiRAEAaF|XVAEARFlSAEAgFhbAEAgFTUAEARFhSAEARF|YXAEAJFlRAEAaFgbAEAiFTVAEAZFYSAEAIFgUAEAIF|mRAEARFfaAEAgFSXAEAgFZRAEARF|SXAEAIFmRAEAJFdZAEAaFSYAEAiFbRAEAZFmaAEAIF|SWAEARFcYAEARFSZAEAgFcRAEAgFmZAEARF|SVAEAZFdbAEAIFbWAEAIFSaAEAaFdRAEAiFmYAEAaFbZAEAIF|STAEAgFfbAEARFSbAEARFfRAEAgFmXAEAgFZaAEARF|TSAEAiFgbAEAZFlUAEAIFTbAEAJFgSAEAaFlVAEAiFYbAEAaF|TRAEAgFhbAEAgFlVAEARFhTAEARFlUAEAgFXbAEAgF|URAEAaFiaAEAiFkWAEAZFWRAEAIFiVAEAJFkTAEAaFWbAEAiF|VRAEARFjZAEAgFjYAEAgFVRAEARFjSAEARFVbAEAgF|WRAEAJFkYAEAaFiZAEAiFURAEAZFWZAEAIFiRAEAIFUbAEAaF|lXAEARFhaAEAgFTRAEAgFXYAEARFTaAEARF|lVAEAJFgbAEAaFTRAEAiFYXAEAZFlaAEAIFTYAEAIF|fbAEARFSSAEAgFZVAEAgFmbAEARF|bVAEAIFdbAEAJFSTAEAZFbUAEAiFmbAEAZFdSAEAIF'
VN_APAL[fireflies]='d0b840fce45cfce880dcc448ffe45fccb43cfce888988c50fcec8ca49030fcec88907c30fce884d8c044fcec84746424f0d858d4bc40948c5080702888742c5c501c988838948434d0b83cfcec80c8b440c4ac387c7024f0e080d4b83cc8bc70c8bc6c7c6c24806c287c6c28c4b03cc8b448'
VN_AF[motes]='EGHAAGL2ABNB2ACTDHADHMGAAIDGAEPF2AFKI2ABFHGAGEG3ABLJGAASMGAEUC2ADBJ2AHEE2AFHLGABGIHAAVDGACAGGAIHJGAGCKGAJKDHAFQCGACXJGAFDL3AKRDGAL|EH3AAGMGAMNCGAETD3ADJEGANID2AEKIGABFH2AGEGHABLJGAAUDGADEEGAFHL2ABGIHAAVEGACXKHAOAGGAIHJ2AGKDHAFQDGACXKGAPDLHAKRE2AF|EHHAANCGAETEHADJE2ANIDGAEKJGABFIGAGEHHABLJ2AAEEGAFHMGABGJ3AAOBGADVE2ACUBGAQXK3AOAH2AIHJGAGKE3AFXK2APKB2AEREGAF|EHHAAHCGAFTEHADJFGANIEGAEKJ2ABDCGARFIGAGEH3ABLKGAAEF2AGHMGABGJHAAOC2ADVEGACUB2AQAHGAIHKGAGKEHAFRIGANKCGAEREGAF|HCGAFTE3ADOG2AEJFGANIE2AEKJGABDC2ARFI2AGEHHABLKGAAKGGAFEFGAGHM2ABGJHAAOCGADVEGACUBGAQAHGAIHK2AGKEHAFRI2ANKCGAERE2AF|HC2AFTFHANOGGAEFMGAJJF2ANIEGAEKJGABDCGARFJGAGEIHABLK2AAKGGAFXD2ASEFGAGGJ3AAOCGADUCGALAI2ATHKGAGTBGAUKE3AFRIGANPDGANKC2AE|HCGAFMCGAFTFHANOGGAEFMGAJJFGANIFGAEKK2ABDCGARFJGAGEI3ABLLGAAKG2AFXDGASEG2AGGKHAAOC2ADUC2ALAIGATHLGAGTBGAUKFHAFRIGANWKGANPD2ANKCGAE|HDGAFMDGAFTF3ANOH2AEJGGANIF2AEPIGAFKKGABDD2ANFJ2AGEIHABLLGAAKHGAFEGGAGGKHAAODGANUCGALAIGATHL2AGKFHAFRJ2ANWL2ARPEGANKDGAE|HD2AFMD2AFTFHANOHGAEJG2ANIFGAEPIGAFKKGABDDGANFJGAGLL2AAKHGAFUFGADEGGAGGK3AAODGANUCGALHLGAGKF3AFRJGANQF2AEWLGARPEGANKD2AE|HDGAFNE2AEMDGAFOHGAEJGGANIFGAEPI2AFKL2ABDDGANFKGAGLLGAAKH2AFUF2ADEG2AGGLHAAOD2ANUD2ALHLGAGKGHAFRJGANQFGAEWLGARPE2ANKDGAE|EJ3AAHEGAFNEGAEMDGAFOI2AECDHAPJHGANIG2AEPIGAFKLGABDE2ANFK2AGLMGAAKIGAGSB2ACUFGADEHGAGGLHAAOEGANHM2AGKGHAFRK2ANQFGAEWL2ARPEGANKEGAE|EKHAAHE2AFGBGAVNFGAEME2AFOIGAEHC2AECD3APJH2ANIGGAEPJGAFKLGABDEGANLM2AAKIGAGSCGACUGGANEHGAGGL3AAOEGANVH2AEHMGAGKG3AFRKGANQG2AEPFGANKE2AERHGAF|EKHAAHEGAFGB2AVNF2AEMEGAFOIGAEHCGAECDHAPJHGANIGGAEPJ2AFKL2ABDEGANLMGAAKI2AGSCGACUG2ANEH2AGGLHAAOE2ANVHGAEHMGAGRKGANQGGAEPF2ANKEGAERHGAF|EK3AAHEGAFGBGAVNFGAEMEGAFOI2AEHCGAECEHAGJIGABIH2AAPJGAFKMGABDE2ANLNGAPKIGAGXFGADSC2ACUGGANEIGAGGMHAWXDGAXOEGANVHGAETD2ACRK2ANQGGAEPFGANKEGAERH2AF|EKHAAHF2AFGCGANNFGAEMF2AFOJGAEFBGAYHC2AECE3AGJI2ABIHGAAPKGAFDFGABEKHABLN2APKJGAGXF2ADSCGACUHGANEIGAGXD2AXOFGANVH2AETDGACRLGANQH2AEPGGANKF2AERHGAF|ELHAAHFGAFGC2ANNG2AEMFGAFTIHANOJGAEFBGAYHDGAECEHAGJIGABIHGAAPK2AFDFGABEL3ABLNGAPKJ2AGXGGADSDGACUH2ANEI2AGHCGANOF2ANVIGAETEGACRLGANQHGAEDC3AZPG2ANKFGAERIGAF|EL3AAHFGAFGCGANNGGAEMFGAFTI3ANOJ2AEFB2AYHDGAECEHAGJIGABPKGAFDF2ABYF2ACELHABLNGAPKJGAGXGGADSD2ACUHGANHC2ANOFGANVIGAEUFGALTE2ACRL2ANQHGAEDCHAZPGGANKFGAERI2AF|ELHAAHG2AFGCGANNGGAEMF2AFTIHANOKGAEFCGAFHD2AECF3AGJJ2ABPKGAFDGGABYFGACFMGAJELHABKKGAGXG2ADSDGACUHGANHCGANOGGANVI2AEUFGALTEGACRMGABQH2AEDCHAZPHGANKG2AERIGAF|HGGAFGD2ANNH2AEMGGAFTIHANOKGAEFCGAFHEGAEJJGABPL2AGWDGALDGGABYFGACFMGAJEL3ABKK2AGXGGADSEGACUI2ANHCGANOG2ANVJGAEUF2ALTEGACKIHAGRMGABQIGAEDC3AZPH2ANKGGAERJGAF|HGGAFGDGANNHGAEMGGAFTJ3ANOK2AEFC2AFHEGAEPLGAGWEGALDG2ABYG2ACKKGAGXHGANSE2ACZHHAaUIGANHD2ANOGGANVJGAEUGGAFTF2AEKJHAGRM2ABQIGAEDDHAEPHGANKGGAERJ2AF|HG2AFGDGANNHGAEMG2AFTJHANOKGAEFCGAFHE2AEPLGAGKAGASWE2ALDGGABYGGACKKGAGXH2ANSEGACZHHAaUIGANHDGANVJ2AEUGGAFTFGAEKJ3AGRMGABQI2AEDDHAEPHGANRJGAF|GE2ANNI2AEMHGAFTJHANOLGAAFDGAFHEGAEPM2AGKA2ASBF3AAWEGALYGGACKL2AGXHGANSEGACZH3AaUJ2ANHDGANXFGALVJGAEUG2AFTFGAEKJHAGQJGAEDD3AEPI2ANRJGAF|GEGANNIGAEMHGAFTK3ANFD2AFHFGAEIJ2AAPMGAGKAGASBFHAAWEGALYH2ACXIGANSF2AEZHHAaUJGANEKGAGHE2ANXFGALVKGAEUHGAFCD2AOTG2AEKJHAGQJGAEDEHAEPIGANRK2AF|GEGANNIGAEMH2AFTKHANHF2AEIKGAAPMGAGKBGANBGHAAWF2ALYHGACLC2AEXI2ANSFGAEZIHAbUJGANELGAGHEGANGB3AcXG2ALVK2AEUHGAFHCGAFCDGAOTGGAEKK3AGQJ2AEDEHAERKGAF|GE2ANNI2AETKHANHFGAECHHAGIKGAAPM2AGKB2ANBG3AAWFGALYHGACLCGAEXIGANSFGAEZI3AbUJ2ANEL2AGHEGANGBHAcXGGALVKGAEUH2AFHCGAFCDGAOTGGAEKKHAGQJGAEDE3AERKGAF|GFGANNJGAETK3ANHGGAECHHAGJLGABIK2AAKBGANBGHAAWFGALYH2ACLCGAEXJGANSG2AEZIHAbUKGANELGAGHE2ANGBHAcXGGALVLGAEUHGAFXDHASHC2AFCE2ABTH2AEKKHAGQKGAEXDGAXDEHAERL2AF|NJGAETLHANHG2AECH3AGJL2ABIKGAAKCGANBGHAAWG2ALYIGAEFBGAYLC2AEXJ2ANSGGAEELGAGHFGANGC3AEXG2ALOIGANVL2AEUIGAFXD3ASHCGAFCEGABTHGAEKL3AGXD2AXDFHAAKI2AARLGAF|HJGAGTLHANHGGAECIHAGJMGABILGAAKC2ANBH3AAWGGALDJGABYIGAEFBGAYLDGAEXJGANSGGAEHFGANGCHAEXHGAFOJ2ANVLGAEUI2AFXEHADHDGAFCEGABTHGAEKLHAGRBGADDF3AAKJGAARLGAF|HJGAGTL3ANON2APHGGAECIHAGJMGABIL2AAKCGANBHHAAWGGALDJ2ABYI2AEFB2AYLDGAEKNGAOXJGANHF2ANGCHAEXHGAFOJGANVLGAEUIGAFXEHADHD2AFCE2ABTH2AEKLHAGRB2ADDFHAAYFGALKJGAARL2AF|HJ2AGTMHAVONGAPFFGAFCI3AGJM2ABILGAAKCGANBHHAAWG2ALDJGABYJGAdFCGAFLD2AEKNGAOXK2AOHGGANGC3AEXH2AFOJGANUJGAFXE3ADHDGAFCFGABTIGAEKL3AGRBGADDGHAAYFGALPKGANKJ2AA|HJGAGMJGAGTMHAVONGAPFFGAFCJHAGJMGABIMGAAKD2ANBI3AAWHGAFDJGABYJGAdFCGAFLEGAEKN2AOXKGAOHGGANGDHAEXIGAFOJ2ANUJ2AFXEHADHEGAFTIGAEKMHAGRBGADWDGADDG3AAYF2ALPK2ANKJGAA|HKGAGMKGAGTM3AVOA2AeFG2AGAFGAfCJHAGJNGAgIM2AAPBGALKDGANBIHAAWHGAFDK2ABYJ2AdFC2AFLEGAEKAGAhHG2ANGDHAEXIGAFOKGANUJGAFXFHADHE2AFKMHAGRC2ADWE2ADDGHAAYGGALPLGABKKGAA|HK2AGGHGABMK2AGTMHAVOAGAeFGGAGAFGAfCJ3AGJN2AgIMGAAPBGALKDGANBIHAAWH2AFDKGABYJGAdFCGAFLE2AEKAGAhUMGAiHGGANGD3AEXI2AFOKGANUJGAFXF3ADHEGAFKM3AGRCGADQM2AAWEGADDGHAAYGGALPLGABKK2AA|HKGAGGH2ABNL2AAMKGAGOAGAeFGGAGAF2AfCJHAGJNGAgIMGAAPB2ALKE2ANBJ3AHWIGAFDKGABFDGAFLEGAEKA2AhUM2AiBF2AAGEHAEXJGAFOK2ANUK2AFXFHADHEGAFKNHAORCGADQMGAAXFGALWEGADYG2ALPL2ABKKGAA|EC3AEHLGAGGHGABNLGAAMKGAGOB2ACFG2AGAGGAjCKHAkJAGAlIN2AmPBGALKEGANBJHAHWIGAFDL2AnFD2AFLFGAEKBGAFSI2AEUMGAiBFGAAGEHAEXJGAFOLGABXGHADHF2AFKNHAORD2ADQMGAAXFGALWE2ADYHGALPLGABKLGAA|EDHAEHL2AGGIGABNMGAAML2AGOBGACFHGAGAGGAjHJ2AACK3AkJA2AlINGAmPCGALKEGANBJHAHWI2AFDLGAnLF2AEKBGAFSJGAEBGGAAGE3AEXJ2AFOLGABXG3ADHFGAFKN3AORDGADQN2AkXG2ALWFGADYHGALPMGABKL2AARAGAY|EDHAEHLGAGGI2ABNM2AAMLGAGOBGACFHGAGAG2AjHJGAACKHAkJAGAlINGAmPC2ALKE2ANBJ3AHDLGAnLFGAEKB2AFSJGAEBG2AAGEHAEXJGAFOL2ABXGHADHFGAFCHGABRDGADQNGAkXGGALWFGADYH2ALPM2ABKLGAARAGAY|ED3AEHLGAGGIGABNMGAAMLGAGOB2ACFH2AGAGGAjHJGAAJBGANIA2AKPCGALKFGANDL2AnLGGAEKBGAFSJ2AEBGGAAGFHAEXKGAPOLGABXHHANHG2AFCH2ABTK2AERD2ADQNGAkXGGALWF2ADYHGALPMGABKLGAARA2AY|EDHAEHM2AGGJGABNMGAAMM2AGOCGACFIGAGAHGAjHJ2AAJB2ANIAGAKPDGAFEDHANLG2AEKCGAFSJGAEBGGAAXK2APOMGABXH3ANHGGAFCHGABTKGAEREGANQA2AFXG2ALWGGADYIGAFPNGAiKM2AARAGAY|EEHAEHMGAGGJ2ABNN2AoMMGAGTBHApOCGACFIGAGAH2AjHKGAAJBGANIAGAKPD2AFEE3ANLGGAEKC2AFSKGAEBH2AAHJGABOM2ABXHHANHGGAFCIGABTLGAEREGANQAGAFXHGAFWGGADDJ3AAYI2AFPN2AiKMGAARBGAL|EE3AEHMGAGGJGABNNGAoMMGAGTB3ApOC2ACFI2AGAHGAjHKGAAJBGANPDGAFEEHANLGGAEKCGAFSK2AEBHGAAHJ2ABOMGABUMGAYXHHANHG2AFCI2ABTL2AERE2ANQAGAFXHGAFWG2ADDJHAAYIGAFPNGAiKMGAARB2AL|EEHAEGJGABNNGAoMM2AGTBHApODGAEFJGAGAIGAfHK2AAJC2ANPDGAFFFGAFEEHANKDGAFSKGAEBHGAAHJGABONGAbUMGAYXI3ANCIGABTLGAERFGANQA2AFXH2AFWGGADDJHAAYJGAQPAGASKN2AZRBGAL|EFHAAGK2ABNA2AqMNGArTBHApODGAEFJGAGAI2AfHLGAAJCGANPE2AFWKGAFFFGAFEE3ANKD2AFSLGAEUB2AkBI2AAHJGABON2AbVCGACUM2AYXIHANCJGABTLGAEKBHAFRFGANQBGACXIGAFWHGANDJ3AAYJ2AQPA2ASKNGAZRCGAL|EF3AAGKGABNAGAqMNGArTC3ADOD2AEFJ2AGAIGAfHLGAAPEGAFWLGAsFG2AGEFHABKDGAFSL2AEUBGAkBIGAAHK2ABONGAbVCGACAFGATCJ2ABTM2AcKCHAFRF2ANQBGACXIGAFWH2ANDKHAAYJGAQPAGASKNGAZRC2AL|EFHAAGKGABNAGAqMN2ArTCHADODGAEFJGAGHL2AAPEGAFKHGANWL2AsFGGAGEFHABKDGAFSLGAEUBGAkBIGAAHKGABGH3AAVC2ACAF2ATCJGABTMGAcKC3AFRFGANQB2ACXI2AFWHGANDKHAAYJGAQPAGASRCGAL|EFHAAGL2ABNB2ACMAGAtTCHADOEGAEFKGAGHLGAAPF2AFKH2ANWLGAsFGGAGEF3ABKE2AFSLGAEUC2ADBJ2AHHKGABGHHAAVCGACAFGATCJGABTMGAcKCHAFQCGACXJGAFWIGANDK3AAPB2ADRCGAL|EG3AAGLGABNBGACMAGAtTD3ADFK2AGHMGAAIC2AEPFGAFKHGANWLGAsFG2AGEGHABSM2AEUCGADBJGAHEDGAFHL2ABGHHAAVDGACAGGAICK2AJKCHAFQCGACXJGAFWI2ANDLHAKPBGADRD2AL|EGHAAGLGABNBGACMA2AtTDHADHM2AAIDGAEPFGAFKIGABFHGAGEGHABLJ2AASMGAEUCGADBJGAHEEGAFHLGABGI3AAVD2ACAG2AIHJGAGCKGAJKD3AFQC2ACXJ2AFWIGANDLHAKRDGAL'
VN_AL[motes]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[motes]='686458444034b8b09c7870608c8878787464585448504c4444443c3430283c3c349c9880403c305c5848484438605c505c584c38342860584c34302cb0a8945854446060547c78644444385450486868583c38308480706c685ca8a0902020182c28207c7c683434282c2c204440383c382c2c2c2428241c64605470685cb0a89854504448443c98947c'
VN_AF[leaves]='AHIAAHIZABGCOACJDWADQFZAESCIAFTIWACUFPAGXDIAHLNMAIONMAIRNMAJ|BHIAKGJXABFCOACKEIADPFZAETDOAFUIWACVGZADWDIALLNMAIONMAIRNMAJ|CIOAKFJXABEDYACLEIADOGXAETDOAFVJIACWGZAGWEOALLNMAIONMAIRNMAJ|DIOAKEKJABEDYACMFOADNGXAESEYAFWJIACWHXADXEOALLNMAIONMAIRNMAJ|EJYAKDKJABFEWACNFOADMHJAEREYAMWKOACYHXAGYFYALLNMAIONMAIRNMAJ|EJYAKGEWACNGYADLHJAEQFWAMVKOACYIJADZFYANLNMAIONMAIRNMAJ|DKWAKHFIACMGYADKIPAKQFWAMULYACZIJAOAGWAALNMAIONMAIRNMAJ|CKWAPHFIACLHWADKIPAKPGIAMTLYACYJPAQBGWAKLNMAIONMAIRNMAJ|JGOACKHWADLJZAKOGIAMTMWARYJPAQCHIAKLNMAIONMAIRNMAJ|HBXAMJGOACKIIASMJZAKNHOAMRMWATXKZAQCHIAKLNMAIONMAIRNMAJ|GBXAUKHYACJIIASNKXAKNHOAMUBIAVRNIAJWKZADBIOAKLNMAIONMAIRNMAJ|FCJAMJHYACIJOASNKXAKOIYAMQNIAWVLXADAIOAXLNMAIONMAIRNMAJ|ECJAMJIWATHJOASOLJAKPIYAMWCOAVULXADLNMAIONMAIRNMAJ|DDPAMIIWATHKYASPLJAKQJWAMWCOAVTMJAYLNMAIONMAIRNMAJ|ECWAECDPAZHJIATIKYASLAPAaQMPAKRJWAMVDYAbTMJAYLNMAIONMAIRNMAJ|DCWAcCEZABGJIATJLWASKAPAdQMPAKSKIAMUDYAbXKWAeLNMAIONMAIRNMAJ|CDIAeBEZAfFKOATKLWASKBZAEPNZAcSKIAMTEWAbWLIAcLNMAIONMAIRNMAJ|CFXABEKOATKAIADLMIASLBZAEONZAgTLOAMSEWAbWLIAcLNMAIONMAIRNMAJ|BEOAhCFXABELYATKAIADMMIASMCXAESLOAMRFIACLNMAIONMAIRNMAJ|EGJABFLYATIBOADNNOAiNCXAENAYAjSMYAMRFIACWDXAGLNMAIONMAIRNMAJ|ZFYANEGJABJAWAIGMWAkIBOADNNOAiNDJAEOAYAlQMYABQGOACVDXAGLNMAIONMAIRNMAJ|YFYALFHPABJAWAIHMWATHCYADODJAEPBWAFQNWAkRGOACUEJAGLNMAIONMAIRNMAJ|YGWALGHPABHBIACICYADPEPAEQBWAFPNWAmRHYACTEJAGLNMAIONMAIRNMAJ|ZGWAnHIZABHBIACJNIAWIDWADQEPAERCIAFTHYACTFPADLNMAIONMAIRNMAJ|AHIAAHIZABGCOACJDWADQFZAESCIAFTIWACUFPAGXDIAHLNMAIONMAIRNMAJ|BHIAKGJXABFCOACKEIADPFZAETDOAFUIWACVGZADWDIALLNMAIONMAIRNMAJ|CIOAKFJXABEDYACLEIADOGXAETDOAFVJIACWGZAGWEOALLNMAIONMAIRNMAJ|DIOAKEKJABEDYACMFOADNGXAESEYAFWJIACWHXADXEOALLNMAIONMAIRNMAJ|EJYAKDKJABFEWACNFOADMHJAEREYAMWKOACYHXAGYFYALLNMAIONMAIRNMAJ|EJYAKGEWACNGYADLHJAEQFWAMVKOACYIJADZFYANLNMAIONMAIRNMAJ|DKWAKHFIACMGYADKIPAKQFWAMULYACZIJAOAGWAALNMAIONMAIRNMAJ|CKWAPHFIACLHWADKIPAKPGIAMTLYACYJPAQBGWAKLNMAIONMAIRNMAJ|JGOACKHWADLJZAKOGIAMTMWARYJPAQCHIAKLNMAIONMAIRNMAJ|HBXAMJGOACKIIASMJZAKNHOAMRMWATXKZAQCHIAKLNMAIONMAIRNMAJ|GBXAUKHYACJIIASNKXAKNHOAMUBIAVRNIAJWKZADBIOAKLNMAIONMAIRNMAJ|FCJAMJHYACIJOASNKXAKOIYAMQNIAWVLXADAIOAXLNMAIONMAIRNMAJ|ECJAMJIWATHJOASOLJAKPIYAMWCOAVULXADLNMAIONMAIRNMAJ|DDPAMIIWATHKYASPLJAKQJWAMWCOAVTMJAYLNMAIONMAIRNMAJ|ECWAECDPAZHJIATIKYASLAPAaQMPAKRJWAMVDYAbTMJAYLNMAIONMAIRNMAJ|DCWAcCEZABGJIATJLWASKAPAdQMPAKSKIAMUDYAbXKWAeLNMAIONMAIRNMAJ|CDIAeBEZAfFKOATKLWASKBZAEPNZAcSKIAMTEWAbWLIAcLNMAIONMAIRNMAJ|CFXABEKOATKAIADLMIASLBZAEONZAgTLOAMSEWAbWLIAcLNMAIONMAIRNMAJ|BEOAhCFXABELYATKAIADMMIASMCXAESLOAMRFIACLNMAIONMAIRNMAJ|EGJABFLYATIBOADNNOAiNCXAENAYAjSMYAMRFIACWDXAGLNMAIONMAIRNMAJ|ZFYANEGJABJAWAIGMWAkIBOADNNOAiNDJAEOAYAlQMYABQGOACVDXAGLNMAIONMAIRNMAJ|YFYALFHPABJAWAIHMWATHCYADODJAEPBWAFQNWAkRGOACUEJAGLNMAIONMAIRNMAJ|YGWALGHPABHBIACICYADPEPAEQBWAFPNWAmRHYACTEJAGLNMAIONMAIRNMAJ|ZGWAnHIZABHBIACJNIAWIDWADQEPAERCIAFTHYACTFPADLNMAIONMAIRNMAJ'
VN_AL[leaves]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[leaves]='443410583010542c1034200c8c64209c5820442810946820341c08180c04684c18b8842c7844185c4014181004503c1028180850280c2814083c200c70401440200c24140434240c301c08603410a878286c3818543c10946c2470501844240c60441450381024100498541c381c0890501c48240c7c581c'
VN_AF[ice]='QMjAAQIiABIAiACIKiADYEiAEQKjAFQGiAFYGiAGQEjAHGMjAIGIiAAYGiAJOIiAEGMiAKOCiALOMiAMGIjADWCjANOKiAHOEiAHWEjAGWCiAOECiABECiAFMGjABMEiABEKiADUEiAPMKjAMMGiAFUGiABUCiAGMEjAHCIiAAKNMAQLNUARPNUAQQNUAS|CFhADSJgABKBgAFKLgADSLhAFSHgAFAHgATSFhAHINhAUSBgAJIJgAAAHgAVIBhAFINgAWQDgALQNgAXIJhADIHgADQLgAFQFgAHYFhAGGDgABGDgABOHhAEOFgABGBgAYGLgADOLhAMOHgAFWHgABWDgALOFhAHOBgAJEJgAAKNUAQLNUARPNUAQQNUAS|EGjADECiAHUKiAEMCiAFMMiAMUMjAZUIiAFMGiAHCIiAAUGjAHUCiAJKKiAaCIiAMKCjABKAiAbCKiAcSEiALKKjADKIiADSMiAFSGiAFAGjATSKiAHIEiABIEiABQGiAEICiAFIMiAMQMjAAQIiAFIAiACYIiABYEiAdQGjAHQCiAJGKiAaKNUAQLNUARPNUAQQNMAS|GHhAMGDgAHODgAFONgARWJgABOHgAHOBgAJEJgAAWHhAFWDgAJEJgAMEDgAFMDhABMBgALELgADUFgAPEHgADUBgAeMLhAMMJgADUHgAFCHhAACFgAAULgAHKFgAEULgAHKFgABKDgAFKNgAQSJgABKBgAHKLgADAFgAfSHhAFSDgAJKNUAQLNMARONMARPNUAQQNMAS|IIjAMIEiAFQEiABQAiAgIGjAHQIiAHQCiAJGKiAaYIjAFYEiAhGKiAAGEiAFOEjABOCiALGMiAiGIiADWCiAjOMjAMOKiAFWIiAFOAjAkEIjAAEGiAAMGiAEECjAFMEiABMAiAlEGjADUKiABMCiAHMMiADCGiAaUIjAFUEiAGJNMASKNUAQLNMARONMARPNUAQ|KJhAMKFgAFSFgABSBgALKHhAHKDgAHSJgAFSDgAJAFgAmILgAAIFgABQFhAEQDgALINgAWIJgADQNhASQLgAFYJgAnQBhAJGJhAaQNgAoGHgAAGDhAFGBgAYOFgABOBgALGHhADGDgAHWLgApODgAFONgAiWJhAFWFgAGJNMASKNUAQONUARPNUAQ|MKjAAMGiAFUGiABUCiALMIjAHMEiAHUKiAFUEiAGCKjAqCGiAMUEiAJKMiAAKGiABCKiAcSEiAPKAiAbKKiAMSMiAFKIiADSCjAJIIiAaIEjABICiAFQGiABQCiALIIjADIEiAHQEiAFQAiAgYGiAGJNUASKNUAQONUARPNUAQ|OLhAAOHgABWHgAEGJgADWDgALOJhAFOFgAHWLgArWFgAGELhAAEHgAAWFgAJMNgAsMHgABELgADMBgAGMLgAMUBhAeMJgADCDgAjMDgAHUDhAGUBgAtKFhABKDgABSHgAECJgADSDgALKJhAMKFgAHSFgAFSBgAGAHgATJNUASKNUAQONUARPNMAQ|QMjAAQIiABIAiACIKiADYEiAEQKjAFQGiAFYGiAGQEjAHGMjAIGIiAAYGiAJOIiAEGMiAKOCiALOMiAMGIjADWCjANOKiAHOEiAHWEjAGWCiAOECiABECiAFMGjABMEiABEKiADUEiAPMKjAMMGiAFUGiABUCiAGMEjAHCIiAAJNUASKNMAQNNMAuONUARPNMAQ|CFhADSJgABKBgAFKLgADSLhAFSHgAFAHgATSFhAHINhAUSBgAJIJgAAAHgAVIBhAFINgAWQDgALQNgAXIJhADIHgADQLgAFQFgAHYFhAGGDgABGDgABOHhAEOFgABGBgAYGLgADOLhAMOHgAFWHgABWDgALOFhAHOBgAJEJgAAINMAWJNUASKNMAQNNMAuONUAR|EGjADECiAHUKiAEMCiAFMMiAMUMjAZUIiAFMGiAHCIiAAUGjAHUCiAJKKiAaCIiAMKCjABKAiAbCKiAcSEiALKKjADKIiADSMiAFSGiAFAGjATSKiAHIEiABIEiABQGiAEICiAFIMiAMQMjAAQIiAFIAiACYIiABYEiAdQGjAHQCiAJGKiAaINMAWJNUASNNUAuONUAR|GHhAMGDgAHODgAFONgARWJgABOHgAHOBgAJEJgAAWHhAFWDgAJEJgAMEDgAFMDhABMBgALELgADUFgAPEHgADUBgAeMLhAMMJgADUHgAFCHhAACFgAAULgAHKFgAEULgAHKFgABKDgAFKNgAQSJgABKBgAHKLgADAFgAfSHhAFSDgAJINUAWJNUASNNUAuONUAR|IIjAMIEiAFQEiABQAiAgIGjAHQIiAHQCiAJGKiAaYIjAFYEiAhGKiAAGEiAFOEjABOCiALGMiAiGIiADWCiAjOMjAMOKiAFWIiAFOAjAkEIjAAEGiAAMGiAEECjAFMEiABMAiAlEGjADUKiABMCiAHMMiADCGiAaUIjAFUEiAGINUAWJNUASNNUAuONMARRNMAW|KJhAMKFgAFSFgABSBgALKHhAHKDgAHSJgAFSDgAJAFgAmILgAAIFgABQFhAEQDgALINgAWIJgADQNhASQLgAFYJgAnQBhAJGJhAaQNgAoGHgAAGDhAFGBgAYOFgABOBgALGHhADGDgAHWLgApODgAFONgAiWJhAFWFgAGINUAWJNMASMNMAuNNUAuONMARRNMAW|SKjABRGiAFCGiAAOIjAHNEiAHLMiAaXEiAGIKjAAHGiAFUEiAJSMiABRGiABDKiADBEiAvOAiAwNKiAMKIiADICiABHKiAAUCjAJRIiAEOEjABNCiAFYGiALKIjADJEiAHHMiAaUEiAGEKjAADGiAMINUAWJNMASMNMAuNNUAuRNUAW|VLhABUHgABFHgAaGJgADEDgABRJhAFQFgAHAFgAmLLhAAKHgABXFgAJUHgABGLgADRBgAGQLgAFNJgAHLDgAEMDgAHKLgAAXDhAxHBgAFGBgAYRFhABQDgALBHgAaCJgADNJhAFMFgAHXFgAGHLhAAGHgAAINUAWMNUAuNNUAuRNUAW|XIiABKAiAyJKiADHEiAEUKjAFTGiAFDGiAMQEjAHOMjAANIiABAGiAzXIiAEKAjAbJMiAMUCiALTMiAYGIjADECjABQKiAHPEiAHNMiAaKCiABJCiAFUGjABTEiALFKiADDEiAEQKjAFPGiAFAGiATMEjAHKMjAAJIiAAINUAWMNUAuNNUAuRNUAW|DFhADNBgAGMLgADWHgAFGHgAATFhAHRNhAUSBgAJQJgABDHgAMNBhAGMNgAuXDgA0JJhADHDhAEIHgADGBgA1TLgAFSFgAHDFhAMCDgA2NDgABMDgABXHhAEWFgALJBgAFILgADTLhAFSHgAFDHgAACDgANPFhAHNNhAsOBgAJMJgAAINUAWMNUAuNNMAuQNMASRNUAW|GGjADFCiAHDKiAaQCiAGPMiAMZIiAVMGiAHKAiA3JIiAAWGjAJVCiAJTKiAEGIiAMFCiAFQCjALPAiAbCKiAcMKjADLIiAHJCiAEVGiAFGGjAAFEiAFSKiAHQEiABPEiABZGiA4MCiAFLMiAMVIiAFIAiACGIiAAFEiABSGjAHRCiAJPKiAEINMAWLNMARMNUAuNNMAuQNMASRNUAW|JHhAFIDgAHTDgAGCJgAAPHgAHNBgAPOBgAJMJgAAZHhA5JJgAMIDgAFTDhALSBgALFLgADDFgAaEHgADPLhAMOJgAHYHgAGJHhABIFgABVLgAHTFgAEULgAHSFgABFBhA6PDgAFONgARYJgAnLBgAHJJgAaKLgADIFgABVHhAFUDgAJINMAWLNMARMNUAuQNUASRNUAW|MIjAFLEiAFWEiALIGjAHFKiAASIiAHRCiAJPKiAECIjAMBEiA7MKiAALEiAFWEjALVCiALIMiADHIiADFCiAESMjAFRKiAFBIiAMOAjAkMIjABLGiABVGiAEICjAFSEiALRAiA6EGjADOCiAJNMiADLGiAEYIjAFXEiAGLNUARMNUAuQNUASRNUAW|PJhAFOFgAFZFgA8LHhAHJBhAEKDgAHILgAAVJgAFUDgAJFJhAMEFgAMPLgAAOFgABZFhA9LNgARKJgADULgAFFBgAZEJgAARBhAJPJhAEQNgAoOHgABLDhAFKBgAFVFgALUBgAeHHhADFBhA+GDgAHELgAARDgAGQNgAoBJhA7AFgAmLNUARMNUAuQNUASRNMAW|SKjABRGiAFCGiAAOIjAHNEiAHLMiAaXEiAGIKjAAHGiAFUEiAJSMiABRGiABDKiADBEiAvOAiAwNKiAMKIiADICiABHKiAAUCjAJRIiAEOEjABNCiAFYGiALKIjADJEiAHHMiAaUEiAGEKjAADGiAMLNUARMNMAuPNMAQQNUASRNMAW|VLhABUHgABFHgAaGJgADEDgABRJhAFQFgAHAFgAmLLhAAKHgABXFgAJUHgABGLgADRBgAGQLgAFNJgAHLDgAEMDgAHKLgAAXDhAxHBgAFGBgAYRFhABQDgALBHgAaCJgADNJhAFMFgAHXFgAGHLhAAGHgAAKNMAQLNUARMNMAuPNMAQQNUAS|XIiABKAiAyJKiADHEiAEUKjAFTGiAFDGiAMQEjAHOMjAANIiABAGiAzXIiAEKAjAbJMiAMUCiALTMiAYGIjADECjABQKiAHPEiAHNMiAaKCiABJCiAFUGjABTEiALFKiADDEiAEQKjAFPGiAFAGiATMEjAHKMjAAJIiAAKNMAQLNUARPNUAQQNUAS|DFhADNBgAGMLgADWHgAFGHgAATFhAHRNhAUSBgAJQJgABDHgAMNBhAGMNgAuXDgA0JJhADHDhAEIHgADGBgA1TLgAFSFgAHDFhAMCDgA2NDgABMDgABXHhAEWFgALJBgAFILgADTLhAFSHgAFDHgAACDgANPFhAHNNhAsOBgAJMJgAAKNUAQLNUARPNUAQQNUAS|EGjADECiAHUKiAEMCiAFMMiAMUMjAZUIiAFMGiAHCIiAAUGjAHUCiAJKKiAaCIiAMKCjABKAiAbCKiAcSEiALKKjADKIiADSMiAFSGiAFAGjATSKiAHIEiABIEiABQGiAEICiAFIMiAMQMjAAQIiAFIAiACYIiABYEiAdQGjAHQCiAJGKiAaKNUAQLNUARPNUAQQNMAS|GHhAMGDgAHODgAFONgARWJgABOHgAHOBgAJEJgAAWHhAFWDgAJEJgAMEDgAFMDhABMBgALELgADUFgAPEHgADUBgAeMLhAMMJgADUHgAFCHhAACFgAAULgAHKFgAEULgAHKFgABKDgAFKNgAQSJgABKBgAHKLgADAFgAfSHhAFSDgAJKNUAQLNMARONMARPNUAQQNMAS|IIjAMIEiAFQEiABQAiAgIGjAHQIiAHQCiAJGKiAaYIjAFYEiAhGKiAAGEiAFOEjABOCiALGMiAiGIiADWCiAjOMjAMOKiAFWIiAFOAjAkEIjAAEGiAAMGiAEECjAFMEiABMAiAlEGjADUKiABMCiAHMMiADCGiAaUIjAFUEiAGJNMASKNUAQLNMARONMARPNUAQ|KJhAMKFgAFSFgABSBgALKHhAHKDgAHSJgAFSDgAJAFgAmILgAAIFgABQFhAEQDgALINgAWIJgADQNhASQLgAFYJgAnQBhAJGJhAaQNgAoGHgAAGDhAFGBgAYOFgABOBgALGHhADGDgAHWLgApODgAFONgAiWJhAFWFgAGJNMASKNUAQONUARPNUAQ|MKjAAMGiAFUGiABUCiALMIjAHMEiAHUKiAFUEiAGCKjAqCGiAMUEiAJKMiAAKGiABCKiAcSEiAPKAiAbKKiAMSMiAFKIiADSCjAJIIiAaIEjABICiAFQGiABQCiALIIjADIEiAHQEiAFQAiAgYGiAGJNUASKNUAQONUARPNUAQ|OLhAAOHgABWHgAEGJgADWDgALOJhAFOFgAHWLgArWFgAGELhAAEHgAAWFgAJMNgAsMHgABELgADMBgAGMLgAMUBhAeMJgADCDgAjMDgAHUDhAGUBgAtKFhABKDgABSHgAECJgADSDgALKJhAMKFgAHSFgAFSBgAGAHgATJNUASKNUAQONUARPNMAQ|QMjAAQIiABIAiACIKiADYEiAEQKjAFQGiAFYGiAGQEjAHGMjAIGIiAAYGiAJOIiAEGMiAKOCiALOMiAMGIjADWCjANOKiAHOEiAHWEjAGWCiAOECiABECiAFMGjABMEiABEKiADUEiAPMKjAMMGiAFUGiABUCiAGMEjAHCIiAAJNUASKNMAQNNMAuONUARPNMAQ|CFhADSJgABKBgAFKLgADSLhAFSHgAFAHgATSFhAHINhAUSBgAJIJgAAAHgAVIBhAFINgAWQDgALQNgAXIJhADIHgADQLgAFQFgAHYFhAGGDgABGDgABOHhAEOFgABGBgAYGLgADOLhAMOHgAFWHgABWDgALOFhAHOBgAJEJgAAINMAWJNUASKNMAQNNMAuONUAR|EGjADECiAHUKiAEMCiAFMMiAMUMjAZUIiAFMGiAHCIiAAUGjAHUCiAJKKiAaCIiAMKCjABKAiAbCKiAcSEiALKKjADKIiADSMiAFSGiAFAGjATSKiAHIEiABIEiABQGiAEICiAFIMiAMQMjAAQIiAFIAiACYIiABYEiAdQGjAHQCiAJGKiAaINMAWJNUASNNUAuONUAR|GHhAMGDgAHODgAFONgARWJgABOHgAHOBgAJEJgAAWHhAFWDgAJEJgAMEDgAFMDhABMBgALELgADUFgAPEHgADUBgAeMLhAMMJgADUHgAFCHhAACFgAAULgAHKFgAEULgAHKFgABKDgAFKNgAQSJgABKBgAHKLgADAFgAfSHhAFSDgAJINUAWJNUASNNUAuONUAR|IIjAMIEiAFQEiABQAiAgIGjAHQIiAHQCiAJGKiAaYIjAFYEiAhGKiAAGEiAFOEjABOCiALGMiAiGIiADWCiAjOMjAMOKiAFWIiAFOAjAkEIjAAEGiAAMGiAEECjAFMEiABMAiAlEGjADUKiABMCiAHMMiADCGiAaUIjAFUEiAGINUAWJNUASNNUAuONMARRNMAW|KJhAMKFgAFSFgABSBgALKHhAHKDgAHSJgAFSDgAJAFgAmILgAAIFgABQFhAEQDgALINgAWIJgADQNhASQLgAFYJgAnQBhAJGJhAaQNgAoGHgAAGDhAFGBgAYOFgABOBgALGHhADGDgAHWLgApODgAFONgAiWJhAFWFgAGINUAWJNMASMNMAuNNUAuONMARRNMAW|MKjAAMGiAFUGiABUCiALMIjAHMEiAHUKiAFUEiAGCKjAqCGiAMUEiAJKMiAAKGiABCKiAcSEiAPKAiAbKKiAMSMiAFKIiADSCjAJIIiAaIEjABICiAFQGiABQCiALIIjADIEiAHQEiAFQAiAgYGiAGINUAWJNMASMNMAuNNUAuRNUAW|OLhAAOHgABWHgAEGJgADWDgALOJhAFOFgAHWLgArWFgAGELhAAEHgAAWFgAJMNgAsMHgABELgADMBgAGMLgAMUBhAeMJgADCDgAjMDgAHUDhAGUBgAtKFhABKDgABSHgAECJgADSDgALKJhAMKFgAHSFgAFSBgAGAHgATINUAWMNUAuNNUAuRNUAW|QMjAAQIiABIAiACIKiADYEiAEQKjAFQGiAFYGiAGQEjAHGMjAIGIiAAYGiAJOIiAEGMiAKOCiALOMiAMGIjADWCjANOKiAHOEiAHWEjAGWCiAOECiABECiAFMGjABMEiABEKiADUEiAPMKjAMMGiAFUGiABUCiAGMEjAHCIiAAINUAWMNUAuNNUAuRNUAW|CFhADSJgABKBgAFKLgADSLhAFSHgAFAHgATSFhAHINhAUSBgAJIJgAAAHgAVIBhAFINgAWQDgALQNgAXIJhADIHgADQLgAFQFgAHYFhAGGDgABGDgABOHhAEOFgABGBgAYGLgADOLhAMOHgAFWHgABWDgALOFhAHOBgAJEJgAAINUAWMNUAuNNMAuQNMASRNUAW|EGjADECiAHUKiAEMCiAFMMiAMUMjAZUIiAFMGiAHCIiAAUGjAHUCiAJKKiAaCIiAMKCjABKAiAbCKiAcSEiALKKjADKIiADSMiAFSGiAFAGjATSKiAHIEiABIEiABQGiAEICiAFIMiAMQMjAAQIiAFIAiACYIiABYEiAdQGjAHQCiAJGKiAaINMAWLNMARMNUAuNNMAuQNMASRNUAW|GHhAMGDgAHODgAFONgARWJgABOHgAHOBgAJEJgAAWHhAFWDgAJEJgAMEDgAFMDhABMBgALELgADUFgAPEHgADUBgAeMLhAMMJgADUHgAFCHhAACFgAAULgAHKFgAEULgAHKFgABKDgAFKNgAQSJgABKBgAHKLgADAFgAfSHhAFSDgAJINMAWLNMARMNUAuQNUASRNUAW|IIjAMIEiAFQEiABQAiAgIGjAHQIiAHQCiAJGKiAaYIjAFYEiAhGKiAAGEiAFOEjABOCiALGMiAiGIiADWCiAjOMjAMOKiAFWIiAFOAjAkEIjAAEGiAAMGiAEECjAFMEiABMAiAlEGjADUKiABMCiAHMMiADCGiAaUIjAFUEiAGLNUARMNUAuQNUASRNUAW|KJhAMKFgAFSFgABSBgALKHhAHKDgAHSJgAFSDgAJAFgAmILgAAIFgABQFhAEQDgALINgAWIJgADQNhASQLgAFYJgAnQBhAJGJhAaQNgAoGHgAAGDhAFGBgAYOFgABOBgALGHhADGDgAHWLgApODgAFONgAiWJhAFWFgAGLNUARMNUAuQNUASRNMAW|MKjAAMGiAFUGiABUCiALMIjAHMEiAHUKiAFUEiAGCKjAqCGiAMUEiAJKMiAAKGiABCKiAcSEiAPKAiAbKKiAMSMiAFKIiADSCjAJIIiAaIEjABICiAFQGiABQCiALIIjADIEiAHQEiAFQAiAgYGiAGLNUARMNMAuPNMAQQNUASRNMAW|OLhAAOHgABWHgAEGJgADWDgALOJhAFOFgAHWLgArWFgAGELhAAEHgAAWFgAJMNgAsMHgABELgADMBgAGMLgAMUBhAeMJgADCDgAjMDgAHUDhAGUBgAtKFhABKDgABSHgAECJgADSDgALKJhAMKFgAHSFgAFSBgAGAHgATKNMAQLNUARMNMAuPNMAQQNUAS'
VN_AL[ice]='|||||||||||||||||||||||||||||||||||||||||||||||'
VN_APAL[ice]='405460587484404444687070344c5c748c9498b4c090989c3c505cb8c4c85060647098ac54646c445c685c6c744464784450584c5c643440442c384010181c384448242c3028343c6c848c34444c2838447c909c50585854748440586420283064747c748894606868283c48a8b4b894acb828303444586444484834445030404c4454582434406c74745060681c28348ca4b078909894a0a4444c4c587888546c7c5c7074587c8c2c4450687884445054404c50384c5420303c1c2c34'
VN_AF[crystal]='||||JNCAB|JNCACONCAD|JNCAEONCAF|JNCAEONCAF|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|JNCAB'
VN_AL[crystal]='|||VdAAADFidAAADFkdAAADF|VdAAAEFZdAAAEFidAAAEFkdAAAEF|VdAAAFFXdAAAFFZdAAAFFedAAAFFidAAAFFkdAAAFF|VdAAAGFXdAAAGFZdAAAGFedAAAGFidAAAGFkdAAAGF|VdAAAHFXdAAAHFZdAAAHFedAAAHFidAAAHFkdAAAHF|VcAAAIFXdAAAIFZdAAAIFbdAAAIFedAAAIFgdAAAIFidAAAIFkcAAAIFYdAAAIFcdAAAIF|VcAAAJFXdAAAJFZdAAAJFbdAAAJFedAAAJFgdAAAJFicAAAJFkcAAAJFYdAAAJFcdAAAJF|VcAAAKFXdAAAKFZdAAAKFbdAAAKFedAAAKFgdAAAKFicAAAKFkcAAAKFYdAAAKFcdAAAKF|VcAAALFXdAAALFZdAAALFbdAAALFedAAALFgdAAALFicAAALFkcAAALFYdAAALFcdAAALF|VcAAAMFXdAAAMFZcAAAMFbdAAAMFedAAAMFgdAAAMFicAAAMFkcAAAMFYdAAAMFcdAAAMF|VbAAANFXdAAANFZcAAANFbdAAANFedAAANFgdAAANFicAAANFkbAAANFYdAAANFcdAAANF|VbAAAOFXdAAAOFZcAAAOFbdAAAOFedAAAOFgdAAAOFicAAAOFkbAAAOFYdAAAOFcdAAAOF|VbAAAPFXcAAAPFZcAAAPFbdAAAPFecAAAPFgdAAAPFibAAAPFkbAAAPFYdAAAPFcdAAAPF|VbAAAQFXcAAAQFZcAAAQFbdAAAQFecAAAQFgdAAAQFibAAAQFkbAAAQFYdAAAQFcdAAAQF|VbAAARFXcAAARFZcAAARFbdAAARFecAAARFgdAAARFibAAARFkbAAARFYdAAARFcdAAARF|VaAAASFXcAAASFZcAAASFbdAAASFecAAASFgdAAASFibAAASFkaAAASFYdAAASFcdAAASF|VaAAATFXcAAATFZbAAATFbdAAATFecAAATFgdAAATFibAAATFkaAAATFYdAAATFcdAAATF|VaAAAUFXcAAAUFZbAAAUFbdAAAUFecAAAUFgdAAAUFibAAAUFkaAAAUFYdAAAUFcdAAAUF|VaAAAVFXcAAAVFZbAAAVFbdAAAVFecAAAVFgdAAAVFiaAAAVFkaAAAVFYdAAAVFcdAAAVF|VaAAAWFXcAAAWFZbAAAWFbdAAAWFecAAAWFgdAAAWFiaAAAWFkaAAAWFYdAAAWFcdAAAWF|VZAAAXFXcAAAXFZbAAAXFbcAAAXFecAAAXFgcAAAXFiaAAAXFkZAAAXFYcAAAXFccAAAXF|VZAAAYFXcAAAYFZbAAAYFbcAAAYFecAAAYFgcAAAYFiaAAAYFkZAAAYFYcAAAYFccAAAYF|VZAAAZFXbAAAZFZbAAAZFbcAAAZFebAAAZFgcAAAZFiaAAAZFkZAAAZFYcAAAZFccAAAZF|VZAAAaFXbAAAaFZbAAAaFbcAAAaFebAAAaFgcAAAaFiaAAAaFkZAAAaFYcAAAaFccAAAaF|VZAAAbFXbAAAbFZaAAAbFbcAAAbFebAAAbFgcAAAbFiZAAAbFkZAAAbFYcAAAbFccAAAbF|VYAAAcFXbAAAcFZaAAAcFbcAAAcFebAAAcFgcAAAcFiZAAAcFkYAAAcFYcAAAcFccAAAcF|VYAAAdFXbAAAdFZaAAAdFbcAAAdFebAAAdFgcAAAdFiZAAAdFkYAAAdFYcAAAdFccAAAdF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VYAAAeFXbAAAeFZaAAAeFbcAAAeFebAAAeFgcAAAeFiZAAAeFkYAAAeFYcAAAeFccAAAeF|VZAAAaFXbAAAaFZaAAAaFbcAAAaFebAAAaFgcAAAaFiaAAAaFkZAAAaFYcAAAaFccAAAaF|VZAAAWFXcAAAWFZbAAAWFbcAAAWFecAAAWFgcAAAWFiaAAAWFkZAAAWFYcAAAWFccAAAWF|VaAAATFXcAAATFZbAAATFbdAAATFecAAATFgdAAATFibAAATFkaAAATFYdAAATFcdAAATF|VbAAAPFXcAAAPFZcAAAPFbdAAAPFecAAAPFgdAAAPFibAAAPFkbAAAPFYdAAAPFcdAAAPF|VcAAALFXdAAALFZcAAALFbdAAALFedAAALFgdAAALFicAAALFkcAAALFYdAAALFcdAAALF|VcAAAHFXdAAAHFZdAAAHFbdAAAHFedAAAHFgdAAAHFidAAAHFkcAAAHFYdAAAHFcdAAAHF|VdAAAEFZdAAAEFidAAAEFkdAAAEF'
VN_APAL[crystal]='c8a8ff443c4c483c4c685868484050685c6c382c485044586c607c6c5c784c4054483c5c34303c74648438304c50445c6c6084705c7c8068a84c3c6054446070648870607c4c44588468ac4c40603830407868883c344c544864746480846cac3830447c68903c345050486070608c7468888870ac543c7870609474688c846cb05c4c786c54987c6c9054407870649878688c54445c8870b06c549c3834447c70944c406458448078649c74689c7c68947068887460909c84cc7454a07058a08070985c44845848647868a0746494a084cc745ca07458a03c34448470986048847c649c5c4c687868a4746498a084d0745ca47458a43c344868509c4434647c689c7c68a47c6c9874649c50485c8464bc58408088709c6c509c786498584c649074b8604c88806c9878689c544860a088d08868c05840848470a470549c483868584c689078b8644c90806c9c8474a47c68a05c4c6c9078bc684c907c689860488c5c4c74604c8c4c406848386c806ca09078c0685090846c9c806898644c8c8878a470589c4834704c3c6c8470ac9c80cc7c64a87c688c8c78b88474b0a088cc7c5cb4644c988874b08070948874b84c34704c3c705c48648068ac7868908878b06048908060b8684c988c74b08c74b8503c709478bc7c60a89c84c8786488987cc07864a44c44548c6cc0644c94684c9c806c8c785ca45040749478c0544c64886cb4987cc47c64a48c6cc48c74b4806c908c78bc5c48887860a89880c88c74bc64508c8c78b48068a48870b45040685438785038789c80c88c74c0645088786c949c80c47c64ac8468a45c448c6c50947858b058408c6854948874b4806c947058a4543c7c5038805444788064a89074c468508c7c6c947c68ac846ca85c44946c54945c408c6c54a0543c8058447c947cc0544c686854906044945c48847860a48c70bc644c885844649c7cc87c64888470b06448946048886c5c88706084342c48685c74685c78484054342c38706480'
VN_AF[supernova]='QDHAA|QDHAC|QDHAD|QDHAD|QDHAE|QDHAF|QDHAG|QDHAH|QD5AH|QD5AH|QD5AH|QD5AH|QD5AH|QD5AH|QD5AH|QD5AH|QDlAI|QDlAJ|QDlAJ|QDlAJ|QDlAK|QDlAK|QDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBALQDAALQDBAL|RDAALRDBALRDAALRDBALQDAALQEBALQEAALQEBALQDAALPDBALPDAALPDBALPDAALPDBALPDAALPDBALQDAALQCBALQCAALQCBALQDAALRDBALRDAALRDBAL|SDAALSDBALSEAALREBALREAALQEBALQEAALQEBALPEAALPEBALOEAALODBALODAALODBALOCAALPCBALPCAALQCBALQCAALQCBALRCAALRCBALSCAALSDBAL|TDAALTDBALSEAALSEBALREAALRFBALQFAALPFBALPEAALOEBALOEAALNDBALNDAALNDBALOCAALOCBALPCAALPBBALQBAALRBBALRCAALSCBALSCAALTDBAL|TDAANTEBAOTEAAOSEBANSFAAORFBAOQFAAOPFBAOOFAAOOEBANNEAAONEBAONDAANNCBAONCAAOOCBANOBAAOPBBAOQBAAORBBAOSBAAOSCBANTCAAOTCBAO|UDAAPUEBAQUEAAQTFBARSFAAQRGBARQGAARPGBAROFAAQNFBARMEAAQMEBAQMDAAPMCBAQMCAAQNBBAROBAAQPABASQAAATRABAUSBAAQTBBAVUCAAQUCBAQ|VDAARVEBAWVFAAWUFBAWTGAAWRGBAWQGAAWPGBAWNGAAWMFBAWLFAAWLEBAWLDAARLCBAWLBAAWMBBAWNAAAXPABAYQAAATRABAUUBBAZVCBAW|WDeAaWEfAaVFeAaUGfAaTGeAaSHfAbQHeAbOHfAbNGeAaMGfAaLFeAaKEfAaKDeAaKCfAaLBeAaMAfAcNAeAcOAfAdQAeAeWCfAf|XDeAgXEfAbWFeAbVGfAbTHeAbSHfAbQHeAbOHfAbNHeAbLGfAbKFeAbJEfAbJDeAbJCfAbKBeAbLAfAhNAeAiOAfAhQAeAe|YEfAjXFeAHWGfAHUHeAHSIfAHQIeAHOIfAHMHeAHKGfAHJFeAHIEfAHIDeAHICfAHJBeAHKAfAkMAeAi|YEfAlYGeAmWHfAmUIeAmSIfAmQIeAmOIfAmMIeAmKHfAmIGeAmIEfAmHDeAmICfAmIAeAnKAfAo|ZFfApYGeAmXHfAmVIeAmSJfAmQJeAmOJfAmLIeAmJHfAmIGeAmHFfAmGDeAmHBfAmIAeAnJAfAq|ZGeArXHfAmVIeAmTJfAmQJeAmNJfAmLIeAmJHfAmHGeAmGFfAmGDeAmGBfAsJAfAq|YIRAmWJQAmTKRAmQKQAmNKRAmKJQAmIIRAmGGQAmFFRAmFDQAmFBRAt|ZIRApWJQAmTKRAmQKQAmNKRAmKJQAmHIRAmFHQAmEFRAmEDQAm|XKQAuTLRAvQLQAvNLRAvJKQAvHJRAvFHQAvDFRAvDDQAv|XKQAuULRAvQLQAvMLRAvJKQAvGJRAvEHQAvCFRAvCDQAu|UMRAwQMQAvMMRAvJLQAvFJRAvDHQAvCFRAv|UMRAwQNQAxMMRAvILQAvFKRAvCIQAvBFRAv|QNQAxMNRAyIMQAvEKRAvCIQAvAGRAz|LNTA0HMSA1EKTA1BISA1AGTA2|DLTA3||||'
VN_AL[supernova]='gTABAPE|gTABARE|gTABATE|gTABAVE|gTABAXF|gTABAZF|gTABAbF|gTABAdG|gTABAfG|gTABAhG|gTABAjH|gTABAmH|gTABAoH|gTABAqI|gTABAsI|gTABAuI|gTABAwJ|gTABAyJ|gTABA0J|gTABA2K|gTABA4K|gTABA6K|gTAMBLN|gTAMBEN|gTAMA9N|gTAMA2N|gTAMAvN|gTAMAoN|gTAMAhN|gTAMAaN|gTAMATN|gTAMAMN||||||||||||||||'
VN_APAL[supernova]='fcb848fff0b0fcb84cfcbc50fcbc54fcc054fcc058fcf0b0fcf4d8fcf4d4fcf4d0fcfcfcfffffffcf4ccfcf4c8fcf4c4fcf0c4fcf0c0ccc49ca49c7c706c54f0e4b8fcf0bcf4e8b4ccc498948c6cfcf0b8fcf0b4f4e8b0e8dca8a49c78989070c8c090e8dca4f4e8acc0b888ccc490c4882cffb03a704c18d0902c80581ca87424ac7824f4a834946820b44420e0552a843018943818d8502898381c7024147a2a18501c1048180c'
VN_AF[rift]='NCfAA|NCfAA|NBfABMCfABNCBACOCfABNDfABNBXABMCJABODXABNBJABMCXABODJABNBXABMCJABODXABNBJAB|NBfABMCfAENCBAFOCfAENDfABMBXABOCJAENDXABMBJABOCXAENDJABMBXABOCJAENDXABMBJAB|NAfAGMBfAENBBAFOBfAEKCfABLCBAFMCBAFNCBAHOCBAFPCBAFQCfABMDfAENDBAFODfAENEfABLBXABQCJABODXAEMBJAEKCXABPDJABNBXAELCJAEKDXABPBJAB|NAfAGMBfAENBBAFOBfAEKCfAELCBAFMCBAHNCBAIOCBAHPCBAFQCfAEMDfAENDBAFODfAENEfABNBXAELCJAEQDXABOBJAEMCXAEKDJABPBXAENCJAEMDXAEKBJAB|MAfAJNABAKOAfALKBfAMLBBANMBBAONBBAOOBBAOPBBANQBfAMICfABJCBAPKCBAQLCBARMCBASNCBATOCBASPCBARQCBAQRCBAPSCfABKDfAMLDBANMDBAONDBAOODBAOPDBANQDfAMMEfAUNEBAOOEfAUNFfAEJBXAVOCJAWIDXAVNBJAMSCXABMDJAMRBXAVLCJAWMDXAMRBJAV|MAfAJNABAXOAfALKBfAMLBBAOMBBAYNBBAYOBBAYPBBAOQBfAMICfABJCBAZKCBANLCBAaMCBAbNCBAcOCBAbPCBAaQCBANRCBAZSCfABKDfAMLDBAOMDBAYNDBAYODBAYPDBAOQDfAMMEfAdNEBATOEfAdNFfAELBXAMQCJAWKDXAMPBJAMJCXAWODJAMIBXAVJCJAWODXAMIBJAV|KAfAeLABAfMABAXNABAOOABAgPABAhQAfAiIBfAVJBBAIKBBAXLBBAYMBBATNBBAjOBBATPBBAYQBBAXRBBAISBfAVGCfAAHCBAkICBACJCBAHKCBARLCBAlMCBAcNCBAmOCBAcPCBAlQCBARRCBAHSCBACTCBAkUCfAAIDfAVJDBAIKDBAXLDBAYMDBATNDBAjODBATPDBAYQDBAXRDBAISDfAVKEfAULEBAOMEBATNEBAnOEBATPEBAOQEfAUMFfAoNFBANOFfAoNGfAEHBXAAMCJApRDXAMHBJAAMCXApRDJAMHBXAAJCJAWODXAdTBJAG|KAfAeLABAfMABASNABAqOABArPABAhQAfAiIBfAVJBBAIKBBAOLBBATMBBAjNBBAcOBBAjPBBATQBBAORBBAISBfAVGCfAAHCBAsICBAPJCBAHKCBAtLCBAnMCBAcNCBAuOCBAcPCBAnQCBAtRCBAHSCBAPTCBAsUCfAAIDfAVJDBAIKDBAOLDBATMDBAjNDBAvODBAjPDBATQDBAORDBAISDfAVKEfAULEBAYMEBATNEBAcOEBATPEBAYQEfAUMFfAoNFBAROFfAoNGfAEJBXAMOCJAwTDXAAJBJAMOCXAwTDJAAGBXAGLCJApQDXAMGBJAG|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|KAfAeLABAfMABASNABAqOABArPABAhQAfAiIBfAVJBBAIKBBAOLBBATMBBAjNBBAcOBBAjPBBATQBBAORBBAISBfAVGCfAAHCBAsICBAPJCBAHKCBAtLCBAnMCBAcNCBAuOCBAcPCBAnQCBAtRCBAHSCBAPTCBAsUCfAAIDfAVJDBAIKDBAOLDBATMDBAjNDBAvODBAjPDBATQDBAORDBAISDfAVKEfAULEBAYMEBATNEBAcOEBATPEBAYQEfAUMFfAoNFBAROFfAoNGfAEUBXBBKCJAWPDXAMUBJBBKCXAWPDJAMUBXBBHCJABMDXAdRBJAM|KAfAeLABAfMABAXNABAOOABAgPABAhQAfAiIBfAVJBBAIKBBAXLBBAYMBBATNBBAjOBBATPBBAYQBBAXRBBAISBfAVGCfAAHCBAkICBACJCBAHKCBARLCBAlMCBAcNCBAmOCBAcPCBAlQCBARRCBAHSCBACTCBAkUCfAAIDfAVJDBAIKDBAXLDBAYMDBATNDBAjODBATPDBAYQDBAXRDBAISDfAVKEfAULEBAOMEBATNEBAnOEBATPEBAOQEfAUMFfAoNFBANOFfAoNGfAEHBXAAMCJApRDXAMHBJAAMCXApRDJAMHBXAAJCJAWODXAdTBJAG|MAfAJNABAXOAfALKBfAMLBBAOMBBAYNBBAYOBBAYPBBAOQBfAMICfABJCBAZKCBANLCBAaMCBAbNCBAcOCBAbPCBAaQCBANRCBAZSCfABKDfAMLDBAOMDBAYNDBAYODBAYPDBAOQDfAMMEfAdNEBATOEfAdNFfAEPBXAMJCJAWODXAMIBJAVNCXApSDJAVIBXAVNCJApSDXAVMBJAM|MAfAJNABAKOAfALKBfAMLBBANMBBAONBBAOOBBAOPBBANQBfAMICfABJCBAPKCBAQLCBARMCBASNCBATOCBASPCBARQCBAQRCBAPSCfABKDfAMLDBANMDBAONDBAOODBAOPDBANQDfAMMEfAUNEBAOOEfAUNFfAERBXAVLCJAWQDXAMKBJAMPCXAWJDJAVKBXAMPCJAWJDXAVOBJAM|NAfAGMBfAENBBAFOBfAEKCfAELCBAFMCBAHNCBAIOCBAHPCBAFQCfAEMDfAENDBAFODfAENEfABLBXAEQCJAEODXAEMBJAEKCXAEPDJAEOBXAEMCJAEKDXABPBJAE|NAfAGMBfAENBBAFOBfAEKCfABLCBAFMCBAFNCBAHOCBAFPCBAFQCfABMDfAENDBAFODfAENEfABNBXAELCJAEQDXABOBJAEMCXAELDJABQBXABOCJAEMDXAEKBJAB|NBfABMCfAENCBAFOCfAENDfABOBXABNCJAEMDXABOBJABNCXAEMDJABOBXABNCJAEMDXABOBJAB|NBfABMCfABNCBACOCfABNDfABNBXABMCJABODXABNBJABMCXABODJABNBXABMCJABODXABNBJAB|NCfAA|NCfAA|NCfAA|NCfAA|NCfAA|NCfAA|NCfAA|NCfAA|NCfAA'
VN_AL[rift]='||dSADADH|dSADAFH|dSADAHH|dSADAIH|dQADAKHdSADAKHdUADAKH|dQADALHdSADALHdUADALH|dQADANHdSADANHdUADANH|dQADAOHdSADAOHdUADAOH|dQADAQHdSADAQHdUADAQH|dQADARHdSADARHdUADARHdWADARH|dQADASHdSADASHdUADASHdWADASH|dQADATHdSADATHdUADATHdWADATH|dQADAUHdSADAUHdUADAUHdWADAUH|dQADAUHdSADAUHdUADAUHdWADAUH|dQADAVHdSADAVHdUADAVHdWADAVH|dQADAVHdSADAVHdUADAVHdWADAVH|dQADAWHdSADAWHdUADAWHdWADAWH|dQADAWHdSADAWHdUADAWHdWADAWH|dQADAWHdSADAWHdUADAWHdWADAWH|dQADAWHdSADAWHdUADAWHdWADAWH|dQADAWHdSADAWHdUADAWHdWADAWH|dQADAVHdSADAVHdUADAVHdWADAVH|dQADAVHdSADAVHdUADAVHdWADAVH|dQADAUHdSADAUHdUADAUHdWADAUH|dQADAUHdSADAUHdUADAUHdWADAUH|dQADATHdSADATHdUADATHdWADATH|dQADASHdSADASHdUADASHdWADASH|dQADARHdSADARHdUADARHdWADARH|dQADAQHdSADAQHdUADAQH|dQADAOHdSADAOHdUADAOH|dQADANHdSADANHdUADANH|dQADALHdSADALHdUADALH|dQADAKHdSADAKHdUADAKH|dSADAIH|dSADAHH|dSADAFH|dSADADH|||||||||'
VN_APAL[rift]='d8f8ffd4f4fc1c3c6c7ad8f0d0f4fc1c4070ccecf4204470204474c0e8f01c4874b8dce4c8f0f8204874244c781c406c20487020487824507824507cccf0f8d0f0f8c8ecf4244878244c7c204070204c78245080285480c4f0f8a4c4c820446c2444701c3c60849ca428547c1a3a6a28507c2c5484285080ccf4fcc0ecf424547c244c70183c6c2050782c5884285484bcecf4244c742044642c5c843060843060882c5880c4ecf4b8e8f45c6c70142c4c24548028588414304c0c20341c44701834648090942858803064888094982c5c88c0ecf8b8e8f0285078346490305c88203c64204468183050306490346890c0f0f820486c18345030608c3468940c1c300c203c0c204024486c34648c143864346c9430648cc4ecf8b4e4f0bce8f4c4e4ec2c60882c547c183864b0e8f4b4e8f0'
VN_AF[fireworks]='SD4AARF5AANG4ABJF5AAID4AAJB5AANA4ACRB5AA|FMPAETD4ABRG5ABNH4ABJG5ABHD4ABJB5AANA4ACRB5AA|FLZAFTE4AGRG5AGNH4AGJG5AGHE4AGJB5AGNA4AHRB5AG|FKPAFUE4AGSG5AGNI4AGIG5AGGE4AGIB5AGNA4AHSB5AG|FJZAFUE4AGSH5AGNI4AGIH5AGGE4AGIB5AGNA4AHSB5AG|FIPAFVEGAGTHHAGNJGAGHHHAIFEGAGHBHAGNAGAHTBHAJ|FHZAFWEGAKTIHAKNJGAKHIHALEEGAKHBHAKNAGAMTBHAN|FGPAFWEGAKTIHAKNKGAKHIHAKEEGAKHBHAKNAGAMTBHAN|FFZAFXFGAKUIHAKNKGAKGIHAKDFGAOGBHANNAGAMUBHAP|FEPAFXFGAKUJHAKNLGAKGJHAKDFGALGBHANNAGAMUBHAP|HCkAQGDlAQFDkAQEDlAQDCkARFBkASGBlAT|HCkAUHDlAVFEkAWDDlAVDCkAXFBkAYHBlAV|ICkAZHElAaFEkAbDElAaFBkAYHBlAc|IDkAaHElAdFFkAeDElAdCDkAfFBkAgHBlAb|JDkAAIElAAFFkAACElAAFBkAhIBlAA|KD4AAIF5AAFG4ABCF5AAIB5AA|KD4AAJF5AAFG4ABBF5AAJB5AA|LD4ABJG5ABFH4ABBG5ABJB5AAUMPAj|LE4ADJG5ADFH4ADBG5ADJB5ADULZAk|ME4ADKG5ADFI4ADAG5AlKB5ADUKPAk|ME4ADKH5ADFI4ADAH5AlKB5ADUJZAk|NEGADLHHADFJGADAHHAlLBHADUIPAk|OEGAKLIHAKFJGAKAIHAmLBHAKUHZAk|OEGAKLIHAKFKGAKAIHAmLBHAKUGPAk|PFGAKMIHAKFKGAKMBHAKUFZAk|PFGAKMJHAKFLGAKMBHAKUEPAk|WCkAnVDlAoUDkApTDlAoSCkApTBlAqUBkAr|WCkAsWDlAtUEkAuSDlAtSCkAvSBlAtUBkAw|WElAxUEkAySElAxRCkAzSBlA0UBkAw|XDkA1WElA2UFkA3SElA2RDkAxSBlAyUBkA4|XElAAUFkAARElAAQDkAARBlAAUBkAh|XF5AAUG4ABRF5AAPD4AARB5AA|YF5AAUG4ABQF5AAPD4AAQB5AANNZAJ|YG5ABUH4ABQG5ABOD4ABQB5AANMPA5|YG5AiUH4AiQG5AiOE4AiQB5AiNLZA5|ZG5A6UI4AiPG5AiNE4AiPB5AiNKPA5|ZH5A6UI4AiPH5AiNE4AiPB5AiNJZA5|UJGAiOHHA7MEGAiOBHAiNIPA5|UJGAKOIHA8LEGAKOBHAKNHZA5|UKGAKOIHAKLEGAKOBHAKNGPA5|UKGAKNIHAKKFGA9NBHAKNFZA5|ULGAKNJHAKKFGAKNBHAKNEPA5|PCkA+ODlA+NDkA+MDlA+LCkA+MBlA+NBkA+OBlA+|PCkA/PDlBANEkBBLDlBALCkA/LBlBANBkA/PBlBA|QCkBCPElBDNEkBELElBDKCkBCLBlBFNBkBAPBlBF|QDkBDPElBGNFkBHLElBGKDkBDLBlBENBkBBPBlBE|RDkAAQElAANFkAAKElAAJDkAAKBlAANBkAAQBlAA|SD4AAQF5AANG4ABKF5AAID4AAKB5AANA4ACQB5AA'
VN_AL[fireworks]='VdADASEdSABALJ|VcADASEdSABAGJ|VbADASE|VaADASE|VZADASE|VYADASE|VXADASE|VWADASE|VVADASE|VUADASE|VSABAtJ|VSABAnJ|VSABAiJ|VSABAcJ|VSABAXJ|VSABARJ|VSABALJkdAiASE|VSABAGJkcAiASE|kbAiASE|kaAiASE|kZAiASE|kYAiASE|kXAiASE|kWAiASE|kVAiASE|kUAiASE|kSABAtJ|kSABAnJ|kSABAiJ|kSABAcJ|kSABAXJ|kSABARJ|kSABALJddAGASE|kSABAGJdcAGASE|dbAGASE|daAGASE|dZAGASE|dYAGASE|dXAGASE|dWAGASE|dVAGASE|dUAGASE|dSABAtJ|dSABAnJ|dSABAiJ|dSABAcJ|dSABAXJ|dSABARJ'
VN_APAL[fireworks]='fcfcfcfffffff4f4f4ffd75f947c34fcd45c5fd7ff5cd0f864d4f458ccf43a3a4a444048383848343444484848202028fce494988858948454f0d88cfce08cfce088fcdc80988854948450fce080fcdc78fcdc7cfce084fcdc74fcd86cc8b06094804c949494ff5f9f94345cfc5c9cac90401c1c24985874fc94bcfc94c0f08cb4945470985470fc88b8fc80b0fc8cbc94506cfc78acfc7cb0fc80b4fc84b4c86088fc74acfc6ca4944c685cd4fcac406cf068a43c445838405094e4fc8ce0fc88e0fc80dcfc80e0fc78dcfc7cdcfc84e0fc74dcfc6cd8fc'
VN_AF[galaxy]='OI4AAOI5AAPJ5ABOJ5ACNKHACLKHACIKHADHJHAEGHGAFGFGADJEGAGMCGAHQCGAHVDGAIYFGAIMI5AAMH4AJLH4AJMG4ACNGGACPGGACSGGAKTHGALUJHADUKHADRMHAHONHAMKNHANFMHAOCKHAPAIGAQNCkAR|OI5AAOI5AAOJ5ATOK5ACMKHACKKHACIJHAFGIHAEGGGAEHFGAEKDGAHNCGAHSDGAHWEGAIZGGAUMI4AAMH4AJMH4AJMG4ACOGGACQGGACSGGAKUIGAEUJHADTLHADQMHAHNNHAVINHAWAHGAUNCkAR|OI5AAOI5AAOJ5ATNK5ACMKHACKKHACIJHAFGIGAEGGGAEIEGADLDGAHPDGAHTDGAHXEGAIZHGAUMI4AAMH4AJMH4AJNG4ACOGGACQGGACSHGAKUIHAEUKHADSLHADPNHANLNHAMDLHAXBJHAWAGGAUNCkAR|OI5AAOI5AAOJ5ATNK5ACLKHACJJHACHJHAEHHGALHGGAFJEGAEMDGAHQDGAHUDGAHYFGAIZIGAQMI4AAMH4AJMH4AJNG4ACPGGACRGGACTHGALTIHAFTKHADRMHADONHAMKNHANGMHAYCKHAPBIHAIBFGAINCkAR|OI5AAOI5AANJ5ATMK5ACLKHACJJHACHIHAFHHGALIFGAFKEGAFNDGAHRDGAHVEGAHYGGAIMI4AAMH4AJNH4AZOG4ACPGGACRGGACTHGALTJHAESLHADQMHADNNHAVJNHAaFMHAbCKHAPBHGAICEGAINCkAR|OI5AAOJ5ATNJ5ATMJ5ACKJHACIJHACHIGAFHGGAFIFGAFLEGAFODGAHSDGAHWFGAHYHGAIMI4AAMH4AJNH4AZOG4ACQGGACSHGACTIHAFTJHAESLHADPMHADMNHAVIMHAHELHAHCJHAIBGGAIDDGAINCkAR|OI5AAOJ5ATNJ5ATMJ5ACKJHACIIHACHHGALIGGAKJEGAEMDGADPDGAHTEGAHXFGAHZIGAQMI4AAMH4AJNH4AZOG4ACQGGACSHGACTIHAFSKHADRLHADOMHADLNHAMHMHAHDKHAHBIHAIBFGAIEDGAINCkAR|NI5AJNJ5ATNJ5ATLJ5ACKJHACIIHACIHGAKIFGAFKEGAFNDGADRDGAHUEGAHXGGAHZIHAQNH4AZNH4AZNH4AZPG4ACQHGACSHGACSJHAFSKHADQLHADNMHADJMHAHGLHAHDKHAHBHGAICFGAIFCGAINCkAR|NI5AJNJ5ATMJ5ATLJ5ACJJHACIIGACIHGAKJFGALLEGAFODGADSEGAHVFGAHYHGAHYJHAWNH4AZNH4AZOH4AJPH4ACRHGACSIHACSJHAFRKHAEPMHADMMHADIMHAHFLHAHCJHAHCGGAIDEGAIHCGAINCkAR|NI5AJNJ5ATMJ5ATLJ5ACJIHACIHGACIGGAKJFGALMEGAFPDGADTEGAHWFGAHYHGAHNH4AZNH4AZOH4AJPH4ACRHGACSIHACSJHAFRLHADOMHADLMHADHMHAHEKHAHCIHAHCGGAIEDGAIIBGAINCkAR|NI5AJNJ5ATMJ5ATKJ5ACJIHACIHGACJGGAKKFGAKNEGALQEGAFTEGAHWGGAHYIHAHNH4AZNH4AZOH4AJQH4ACRHGACSJHACRKHAEQLHADNMHADKMHADHLHAHEKHAHCHGAHDFGAIFDGAIKBGAINCkAR|NI5AJNJ5ATLJ5ABKJ5ACJIHACIHGACJGGAKLEGAFOEGAFREGAEUFGAHXHGAHYJHAcWLHAXNH4AZNH4AZPH4AJQH4ACRIGACSJHACRKHAEPLHADMMHADJMHADGLHAHDJHAHCHGAHEEGAIHCGAILBGAINCkAR|NI5AJMJ5ATLJ5ABKI5ACJIGACJGGACKFGAKMEGAFPEGAFSEGADVFGAHXHGAHXKHAdNH4AZOH4AJPH4AJQH4ACRIHACRJHACQKHAFOLHADLMHADILHADFKHAHDIHAHDGGAHFEGAIICGAINBGAINCkAR|NI5AJMJ5ATLJ5ABKI5ACJHGACJGGACKFGAKNEGALQEGAFTFGAEVGGAHXIHAHXKHAdNH4AZOH4AJPH4AJQH4ACRIHACRJHACQLHADNLHADKMHADHLHADFKHAHDIGAHDFGAHGDGAIKBGAIPBGAINCkAR|NI5AJMI5AALI5ATKI5ACJHGACKGGACLFGAKNEGALQEGAFTFGAEWHGAHXJHAHWLHAeNH4AZOH4AJPH4AJQI4ACRJHACQKHACPLHADNLHADKLHADHLHADEJHAHDHGAHEFGAHHDGAILBGAIRBGAINCkAR|NI5AJMI5AALI5ATKI4ACJHGACKGGACMFGAfOEGAFRFGALUGGAEWHGAHWJHAHNH4AZOH4AJPH4AJQI5ACRJHACQKHACOLHADMLHADJLHADGKHADEIHAHEGGAHFEGAHICGAINBGAISBGAINCkAR|NI5AJMI5AALI5ATKH4ACKGGACLFGACMFGAfPEGAFSFGAFVGGADWIHAHWKHAHUMHAbNH4AZOH4AJPI4ATQI5ACQJHACPKHACOLHADLLHADILHADFKHADEIGAHEGGAHGDGAHKCGAIOBGAIUCGAINCkAR|NI5AJMI5AALI5ATKH4ACKGGACLFGACNFGAgQFGAKTFGAEVHGADWIHAHVLHAHNH4AZOH4AJPI4ATQI5ACQJHACPKHACNLHADKLHADHKHADFJHADEHGAHFFGAHHDGAHLCGAIQBGAIVCGAINCkAR|MI5AAMI5AALI4ATKH4ACKGGACMFGACOFGAfRFGALTGGAFVHGADWJHAHVLHAHOI4AAOH4AJPI5ATQJ5ACQKHACOKHACMLHADJLHADHKHADFIHADEGGAHFEGAHIDGAHNCGAISCGAIXDGAPNCkAR|MI5AALI5ATLI4ATKH4ACLGGACMFGACPFGAKRFGALUGGAEVIGADVKHAHUMHAbQNHAaOI4AAPI4ATPI5ATQJ5ACPKHACOKHACLLHADJKHAEGJHADFIHADFGGAHGEGAHKCGAHOCGAITCGAIYEGAWNCkAR|MI5AALI5ATLH4AJLH4ACLGGACNFGACPFGAKSFGAFUHGAFVIHADVKHAHTMHAYPNHANOI4AAPI4ATPI5ATPJ5ACPKHACNKHACLLHADIKHADGJHADFHGADFFGAHHDGAHLCGAHQCGAIUCGAINCkAR|MI5AALI4ATLH4AJLG4ACMGGACOFGACQFGAKSGGAKUHGAFVJHADULHAHOI4AAPI5ATPI5ATPJ5ACOKHACMKHACKKHAFIKHADGIHAEFHGADGFGAHIDGAHMCGAHRCGAIWDGAIZFGAQNCkAR|MI5AALI4ATLH4AJLG4ACMGGACOFGACRFGALTGGAFUIGAEVJHADTLHAHQNHAaINHAhOI4AAPI5ATPJ5ABPJ5ACOKHACMKHACJKHAEHJHAEGIHAEFGGADHEGAHKDGAHOCGAHSCGAIXEGAINCkAR|MI5AALI4ATLH4AJMG4ACNGGACPFGACRGGAKTHGALUIHAEUKHADSMHAHPNHANLNHAMOI4AAPI5ATPJ5ABOJ5ACNKHACLKHACJKHAEHJHAEGHGAFGGGAEIEGAHLDGAHPCGAHUDGAIYEGAWNCkAR|MI5AAMH4AJLH4AJMG4ACNGGACPGGACSGGAKTHGALUJHADUKHADRMHAHONHAMKNHANFMHAOCKHAPAIGAQOI4AAOI5AAPJ5ABOJ5ACNKHACLKHACIKHADHJHAEGHGAFGFGADJEGAGMCGAHQCGAHVDGAIYFGAINCkAR|MI4AAMH4AJMH4AJMG4ACOGGACQGGACSGGAKUIGAEUJHADTLHADQMHAHNNHAVINHAWAHGAUOI5AAOI5AAOJ5ATOK5ACMKHACKKHACIJHAFGIHAEGGGAEHFGAEKDGAHNCGAHSDGAHWEGAIZGGAUNCkAR|MI4AAMH4AJMH4AJNG4ACOGGACQGGACSHGAKUIHAEUKHADSLHADPNHANLNHAMDLHAXBJHAWAGGAUOI5AAOI5AAOJ5ATNK5ACMKHACKKHACIJHAFGIGAEGGGAEIEGADLDGAHPDGAHTDGAHXEGAIZHGAUNCkAR|MI4AAMH4AJMH4AJNG4ACPGGACRGGACTHGALTIHAFTKHADRMHADONHAMKNHANGMHAYCKHAPBIHAIBFGAIOI5AAOI5AAOJ5ATNK5ACLKHACJJHACHJHAEHHGALHGGAFJEGAEMDGAHQDGAHUDGAHYFGAIZIGAQNCkAR|MI4AAMH4AJNH4AZOG4ACPGGACRGGACTHGALTJHAESLHADQMHADNNHAVJNHAaFMHAbCKHAPBHGAICEGAIOI5AAOI5AANJ5ATMK5ACLKHACJJHACHIHAFHHGALIFGAFKEGAFNDGAHRDGAHVEGAHYGGAINCkAR|MI4AAMH4AJNH4AZOG4ACQGGACSHGACTIHAFTJHAESLHADPMHADMNHAVIMHAHELHAHCJHAIBGGAIDDGAIOI5AAOJ5ATNJ5ATMJ5ACKJHACIJHACHIGAFHGGAFIFGAFLEGAFODGAHSDGAHWFGAHYHGAINCkAR|MI4AAMH4AJNH4AZOG4ACQGGACSHGACTIHAFSKHADRLHADOMHADLNHAMHMHAHDKHAHBIHAIBFGAIEDGAIOI5AAOJ5ATNJ5ATMJ5ACKJHACIIHACHHGALIGGAKJEGAEMDGADPDGAHTEGAHXFGAHZIGAQNCkAR|NH4AZNH4AZNH4AZPG4ACQHGACSHGACSJHAFSKHADQLHADNMHADJMHAHGLHAHDKHAHBHGAICFGAIFCGAINI5AJNJ5ATNJ5ATLJ5ACKJHACIIHACIHGAKIFGAFKEGAFNDGADRDGAHUEGAHXGGAHZIHAQNCkAR|NH4AZNH4AZOH4AJPH4ACRHGACSIHACSJHAFRKHAEPMHADMMHADIMHAHFLHAHCJHAHCGGAIDEGAIHCGAINI5AJNJ5ATMJ5ATLJ5ACJJHACIIGACIHGAKJFGALLEGAFODGADSEGAHVFGAHYHGAHYJHAWNCkAR|NH4AZNH4AZOH4AJPH4ACRHGACSIHACSJHAFRLHADOMHADLMHADHMHAHEKHAHCIHAHCGGAIEDGAIIBGAINI5AJNJ5ATMJ5ATLJ5ACJIHACIHGACIGGAKJFGALMEGAFPDGADTEGAHWFGAHYHGAHNCkAR|NH4AZNH4AZOH4AJQH4ACRHGACSJHACRKHAEQLHADNMHADKMHADHLHAHEKHAHCHGAHDFGAIFDGAIKBGAINI5AJNJ5ATMJ5ATKJ5ACJIHACIHGACJGGAKKFGAKNEGALQEGAFTEGAHWGGAHYIHAHNCkAR|NH4AZNH4AZPH4AJQH4ACRIGACSJHACRKHAEPLHADMMHADJMHADGLHAHDJHAHCHGAHEEGAIHCGAILBGAINI5AJNJ5ATLJ5ABKJ5ACJIHACIHGACJGGAKLEGAFOEGAFREGAEUFGAHXHGAHYJHAcWLHAXNCkAR|NH4AZOH4AJPH4AJQH4ACRIHACRJHACQKHAFOLHADLMHADILHADFKHAHDIHAHDGGAHFEGAIICGAINBGAINI5AJMJ5ATLJ5ABKI5ACJIGACJGGACKFGAKMEGAFPEGAFSEGADVFGAHXHGAHXKHAdNCkAR|NH4AZOH4AJPH4AJQH4ACRIHACRJHACQLHADNLHADKMHADHLHADFKHAHDIGAHDFGAHGDGAIKBGAIPBGAINI5AJMJ5ATLJ5ABKI5ACJHGACJGGACKFGAKNEGALQEGAFTFGAEVGGAHXIHAHXKHAdNCkAR|NH4AZOH4AJPH4AJQI4ACRJHACQKHACPLHADNLHADKLHADHLHADEJHAHDHGAHEFGAHHDGAILBGAIRBGAINI5AJMI5AALI5ATKI5ACJHGACKGGACLFGAKNEGALQEGAFTFGAEWHGAHXJHAHWLHAeNCkAR|NH4AZOH4AJPH4AJQI5ACRJHACQKHACOLHADMLHADJLHADGKHADEIHAHEGGAHFEGAHICGAINBGAISBGAINI5AJMI5AALI5ATKI4ACJHGACKGGACMFGAfOEGAFRFGALUGGAEWHGAHWJHAHNCkAR|NH4AZOH4AJPI4ATQI5ACQJHACPKHACOLHADLLHADILHADFKHADEIGAHEGGAHGDGAHKCGAIOBGAIUCGAINI5AJMI5AALI5ATKH4ACKGGACLFGACMFGAfPEGAFSFGAFVGGADWIHAHWKHAHUMHAbNCkAR|NH4AZOH4AJPI4ATQI5ACQJHACPKHACNLHADKLHADHKHADFJHADEHGAHFFGAHHDGAHLCGAIQBGAIVCGAINI5AJMI5AALI5ATKH4ACKGGACLFGACNFGAgQFGAKTFGAEVHGADWIHAHVLHAHNCkAR|OI4AAOH4AJPI5ATQJ5ACQKHACOKHACMLHADJLHADHKHADFIHADEGGAHFEGAHIDGAHNCGAISCGAIXDGAPMI5AAMI5AALI4ATKH4ACKGGACMFGACOFGAfRFGALTGGAFVHGADWJHAHVLHAHNCkAR|OI4AAPI4ATPI5ATQJ5ACPKHACOKHACLLHADJKHAEGJHADFIHADFGGAHGEGAHKCGAHOCGAITCGAIYEGAWMI5AALI5ATLI4ATKH4ACLGGACMFGACPFGAKRFGALUGGAEVIGADVKHAHUMHAbQNHAaNCkAR|OI4AAPI4ATPI5ATPJ5ACPKHACNKHACLLHADIKHADGJHADFHGADFFGAHHDGAHLCGAHQCGAIUCGAIMI5AALI5ATLH4AJLH4ACLGGACNFGACPFGAKSFGAFUHGAFVIHADVKHAHTMHAYPNHANNCkAR|OI4AAPI5ATPI5ATPJ5ACOKHACMKHACKKHAFIKHADGIHAEFHGADGFGAHIDGAHMCGAHRCGAIWDGAIZFGAQMI5AALI4ATLH4AJLG4ACMGGACOFGACQFGAKSGGAKUHGAFVJHADULHAHNCkAR|OI4AAPI5ATPJ5ABPJ5ACOKHACMKHACJKHAEHJHAEGIHAEFGGADHEGAHKDGAHOCGAHSCGAIXEGAIMI5AALI4ATLH4AJLG4ACMGGACOFGACRFGALTGGAFUIGAEVJHADTLHAHQNHAaINHAhNCkAR|OI4AAPI5ATPJ5ABOJ5ACNKHACLKHACJKHAEHJHAEGHGAFGGGAEIEGAHLDGAHPCGAHUDGAIYEGAWMI5AALI4ATLH4AJMG4ACNGGACPFGACRGGAKTHGALUIHAEUKHADSMHAHPNHANLNHAMNCkAR'
VN_AL[galaxy]='dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI|dXASAaI'
VN_APAL[galaxy]='f4e4fcf8e8fcd8b0fc8a70e08870e08c70e04c3c8c4a3a8a2a2050f4e0fc9074e08c74e04434803c2c7018102c201840141028fff0ffd8b0fff8e4fc1c143448388420183c181030443484f4dcfc302458282050382c68382c6c2c20549078e09478e4100c24'
# ══════════════════════════════════════════════════════════════════════════
# SECTION 19 · THE WARDROBE        four racks, and him in what he has on
# ══════════════════════════════════════════════════════════════════════════
# A hat is not a sticker over his head: it is more pixels in his grid, lit
# by the same lamp as the head under it and folded two pixel rows to a cell
# with it.  So this is scripts/vanity/vanity.py's compositor, arithmetic for
# arithmetic -- the material grid, lit(), the fold and its face priority, the
# brim's shadow, the ember, the wisp that yields, the weather that keeps to
# the air and the light it throws on him -- run on the racks s_vanity_data
# carries.  What the racks ARE is data generated from the python; what they
# DO in company is computed here, because no table can hold 2,782,080
# outfits.  Checked against vanity.compose cell for cell (test_vanity).
typeset -gi AR_VN_OK=1
typeset -g  AR_VN_WHY='ok'
typeset -ga VN_SLOTS VN_SLABS VN_ONE
VN_SLOTS=(hat spec smoke aura); VN_SLABS=(HATS GLASSES SMOKES AURAS); VN_ONE=(HAT PAIR SMOKE AURA)
typeset -gA VN_STYLE; VN_STYLE=(common 1 classic 1 uncommon 2 rare 3 epic 4 legendary 5)
typeset -gi VN_STYLE_FULL=5

# ── the colour arithmetic · the door's own, corners and all ─────────────
# mix is the house's cmix, which already masks to fours exactly as q() does.
# shade is NOT the house's: vanity.py buckets the brightness to 1/128 first
# (int(f*128)/128), and a bench that shaded exactly would draw a brim's edge
# a step apart from the one the original drew.
typeset -gi VS=0
vn_shade() {   # vn_shade C F → VS
  local -i c=$1 r g b; local -F k=$(( int($2 * 128) / 128.0 ))
  r=$(( int(((c >> 16) & 255) * k) )); g=$(( int(((c >> 8) & 255) * k) )); b=$(( int((c & 255) * k) ))
  (( r < 0 )) && r=0; (( r > 255 )) && r=252; (( g < 0 )) && g=0; (( g > 255 )) && g=252; (( b < 0 )) && b=0; (( b > 255 )) && b=252
  VS=$(( ((r & 0xFC) << 16) | ((g & 0xFC) << 8) | (b & 0xFC) )); return 0 }
# his materials come off the data as hex · as numbers once, here
() { local k; for k in ${(k)VN_VPAL[@]}; do [[ "${VN_VPAL[$k]}" == <-> ]] || VN_VPAL[$k]=$(( 16#${VN_VPAL[$k]} )); done }
typeset -gi VN_KEY=$(( 16#d2f4ff )) VN_RIM=$(( 16#fffcf0 )) VN_FILL=$(( 16#ff60be )) VN_AMBI=$(( 16#603c96 ))
typeset -gi VN_WHITE=$(( 16#ffffff ))

# ── the material grid · one token a pixel, '.' is air ────────────────────
# his own materials are single letters (b d e k s p n); a worn item's are
# "@id:letter", its own material, so the one lighting pass lights them all
typeset -ga VM VL                         # the grid, and its lit colour (-1 air)
typeset -gA VP                            # token → colour at rest
typeset -gi VM_W=0 VM_H=0
vn_stamp_head() {   # vn_stamp_head LOOK LIDS OX OY [EYE] · a mood is keyed look,lids,eye
  local k="$1,$2" row; local -a rs; local -i y x ox=$3 oy=$4 w=$VM_W; local ch
  (( ${5:-0} )) && k+=",$5"
  local rows="${VN_HEAD[$k]:-${VN_HEAD[$1,$2]:-${VN_HEAD[0,$2]}}}"
  rs=("${(@s:|:)rows}")
  for (( y = 0; y < ${#rs[@]}; y++ )); do
    row="${rs[$y]}"
    for (( x = 0; x < ${#row}; x++ )); do
      ch="${row[$x]}"; [[ "$ch" == . ]] && continue
      (( ox + x >= 0 && ox + x < w && oy + y >= 0 && oy + y < VM_H )) && VM[$(( (oy + y) * w + ox + x ))]="$ch"
    done
  done; return 0 }
vn_stamp() {   # vn_stamp SLOT ID HEAD_OY · the last art row lands on the seat; columns are the box's
  local k="$1:$2" row ch tok; local -a rs pal; local -i n r c y top w=$VM_W
  rs=("${(@s:|:)VN_ART[$k]}"); n=${#rs[@]}
  top=$(( ${VN_SEAT[$k]} - (n - 1) ))
  for ch in ${=VN_PAL[$k]}; do VP[@$1/$2:${ch%%=*}]=$(( 16#${ch#*=} )); done
  for (( r = 0; r < n; r++ )); do
    row="${rs[$r]}"; y=$(( $3 + top + r ))
    (( y < 0 || y >= VM_H )) && continue
    for (( c = 0; c < ${#row}; c++ )); do
      ch="${row[$c]}"; [[ "$ch" == . ]] && continue
      (( c < w )) && VM[$(( y * w + c ))]="@$1/$2:$ch"
    done
  done; return 0 }

# ── lit() · key light top right, violet ambient low left, rim where it meets the sky ──
vn_render() {   # the grid → VL, one lit colour a pixel (render(), senior=False)
  local -i x y i w=$VM_W h=$VM_H base c up rt upr dn lf nb=24; local m; local -F nx ny f k
  (( ${TRUE24:-1} )) || nb=12
  VL=()
  for (( y = 0; y < h; y++ )); do
    ny=$(( y / (h > 1 ? h - 1.0 : 1.0) ))
    for (( x = 0; x < w; x++ )); do
      i=$(( y * w + x )); m="${VM[$i]}"
      if [[ "$m" == . ]]; then VL[$i]=-1; continue; fi
      nx=$(( x / (w > 1 ? w - 1.0 : 1.0) ))
      case "$m" in
        x) VL[$i]=$(( 16#ccc8e2 )); continue ;;
        e|E|k|s|p|n)
          if [[ "$m" == s ]]; then base=$VN_WHITE; elif [[ "$m" == E ]]; then base=${VN_VPAL[e]}; else base=${VN_VPAL[$m]}; fi
          vn_shade $base $(( 0.9 + 0.25 * (x / (w > 1 ? w - 1.0 : 1.0)) )); c=$VS
          [[ "$m" == e || "$m" == E ]] && { cmix $c $VN_WHITE 0.18; c=$CM; }
          VL[$i]=$c; continue ;;
      esac
      if [[ "$m" == @* ]]; then base=${VP[$m]}; else base=${VN_VPAL[$m]:-${VN_VPAL[b]}}; fi
      # the five neighbours, air or not · past the edge is air
      (( y > 0 )) && [[ "${VM[$(( i - w ))]}" != . ]] && up=0 || up=1
      (( x + 1 < w )) && [[ "${VM[$(( i + 1 ))]}" != . ]] && rt=0 || rt=1
      (( y > 0 && x + 1 < w )) && [[ "${VM[$(( i - w + 1 ))]}" != . ]] && upr=0 || upr=1
      (( y + 1 < h )) && [[ "${VM[$(( i + w ))]}" != . ]] && dn=0 || dn=1
      (( x > 0 )) && [[ "${VM[$(( i - 1 ))]}" != . ]] && lf=0 || lf=1
      f=$(( 0.50 + 0.62 * (0.62 * nx + 0.38 * (1.0 - ny)) ))
      vn_shade $base $(( f )); c=$VS                       # $(( f )), not $f · a float param prints ten places, and ten places is not the double
      k=$(( (1 - nx) * 0.6 + ny * 0.55 - 0.24 )); (( k < 0.0 )) && k=0.0; (( k > 1.0 )) && k=1.0
      k=$(( int(k * nb + 0.5) / (nb * 1.0) ))
      cmix $c $VN_AMBI $(( 0.36 * k )); c=$CM
      if (( up || rt || upr )); then
        if (( up && rt )); then k=0.50; elif (( up )); then k=0.34; else k=0.30; fi
        cmix $c $VN_KEY $k; c=$CM
        (( upr && up )) && { cmix $c $VN_RIM 0.36; c=$CM; }
      fi
      if (( (dn || lf) && ! (up || rt) )); then cmix $c $VN_FILL $(( 0.24 + 0.12 * ny )); c=$CM; fi
      VL[$i]=$c
    done
  done; return 0 }
# the fold · two pixel rows to a cell, his features owning their cell against
# his own coat -- but never against a thing he is WEARING, which averages
#
# AND HOW MUCH OF THE CELL HE COVERS, which is render_cells' second number: a
# cell only one of whose two pixels is him is WEIGHT 62 (50 for the `x` that
# is half a pixel of glint), and whoever lays him down blends that cell into
# whatever is behind it -- which is what rounds a silhouette instead of
# stepping it.  The arcade's own blit paints him whole and never reads this;
# the TERMINAL's does, so his rim is as soft in a hat as it is bare.
typeset -gA VN_FPRI; VN_FPRI=(s 6 k 5 e 4 E 4 n 3 p 2)
typeset -ga VNC VNA                        # the paint · a colour a cell, -1 air · and its weight, 100 whole
vn_fold() {
  local -i x cy H=$(( (VM_H + 1) / 2 )) w=$VM_W i0 i1 c0 c1 p0 p1 win oth ci; local m0 m1 wm
  VNC=(); VNA=()
  for (( cy = 0; cy < H; cy++ )); do
    for (( x = 0; x < w; x++ )); do
      i0=$(( cy * 2 * w + x )); i1=$(( i0 + w )); ci=$(( cy * w + x ))
      m0="${VM[$i0]}"; c0=${VL[$i0]}
      if (( cy * 2 + 1 < VM_H )); then m1="${VM[$i1]}"; c1=${VL[$i1]}; else m1=.; c1=-1; fi
      if (( c0 < 0 && c1 < 0 )); then VNC[$ci]=-1; VNA[$ci]=0; continue; fi
      VNA[$ci]=100
      p0=${VN_FPRI[$m0]:-0}; p1=${VN_FPRI[$m1]:-0}
      [[ "$m0" == @* || "$m1" == @* ]] && { p0=0; p1=0; }
      if (( p0 || p1 )); then
        if (( p0 >= p1 && c0 >= 0 )); then win=$c0; wm="$m0"; oth=$c1; else win=$c1; wm="$m1"; oth=$c0; fi
        if [[ "$wm" == s ]] && (( oth >= 0 )); then cmix $oth $win 0.65; VNC[$ci]=$CM
        else VNC[$ci]=$win; fi
      elif [[ "$m0" == x || "$m1" == x ]]; then
        if [[ "$m0" == x ]]; then win=$c0; oth=$c1; else win=$c1; oth=$c0; fi
        if (( oth < 0 )); then VNC[$ci]=$win; VNA[$ci]=50; else cmix $oth $win 0.5; VNC[$ci]=$CM; fi
      elif (( c0 >= 0 && c1 >= 0 )); then cmix $c0 $c1 0.5; VNC[$ci]=$CM
      else VNC[$ci]=$(( c0 >= 0 ? c0 : c1 )); VNA[$ci]=62; fi
    done
  done; return 0 }

# ── the clock · he is alive in his eyes and nowhere else ────────────────
typeset -gi VN_LOOK=0 VN_LIDS=0
vn_pose() {   # vn_pose FRAME → VN_LOOK VN_LIDS · pose_at(), the same slot and hash
  local -i f=$1 slot ph h
  slot=$(( f / 40 )); ph=$(( f % 40 )); h=$(( (slot * 2654435761) & 0xffffffff ))
  VN_LIDS=0
  if (( h % 3 == 0 )); then
    if (( ph == 18 || ph == 21 )); then VN_LIDS=1; elif (( ph == 19 || ph == 20 )); then VN_LIDS=2; fi
  fi
  case $(( (f / 96) % 4 )) in 1) VN_LOOK=1 ;; 3) VN_LOOK=-1 ;; *) VN_LOOK=0 ;; esac
  return 0 }

# ── the paint · him and what he wears, lit, folded, shaded under the brim, warmed by the ember ──
# worked out once an outfit, a pose and a box, and kept: the arcade's clock
# asks for nine poses and the door's for twenty-five, and the racks change
# when somebody buys something.  THE DEPTH IS IN THE KEY because the wash is
# banded by it (twelve steps on a 256-colour glass, twenty-four on a true one)
# and two callers in one process may ask for him at two depths: the door
# lays him down in the twelve-step wash its own card was printed in.
typeset -gA VN_PCACHE VN_ACACHE
typeset -gi VN_W=26 VN_H=12 VN_OX=3 VN_OY=3
vn_paint() {   # vn_paint HAT SPEC SMOKE LOOK LIDS FIELD(0/1) [EYE] → VNC VNA, VN_W/H/OX/OY
  local key="$6|$1|$2|$3|$4,$5,${7:-0}|${TRUE24:-1}" d; local -i i x y cy
  if (( $6 )); then VN_W=${VN_FIELD[0]}; VN_H=${VN_FIELD[1]}; VN_OX=${VN_FIELD[2]}; VN_OY=${VN_FIELD[3]}
  else VN_W=${VN_CARD[0]}; VN_H=${VN_CARD[1]}; VN_OX=${VN_CARD[2]}; VN_OY=${VN_CARD[3]}; fi
  if [[ -n "${VN_PCACHE[$key]:-}" ]]; then VNC=(${=VN_PCACHE[$key]}); VNA=(${=VN_ACACHE[$key]}); return 0; fi
  (( ${#VN_PCACHE[@]} > 120 )) && { VN_PCACHE=(); VN_ACACHE=(); }
  VM_W=$VN_W; VM_H=$(( VN_H * 2 ))
  VM=(); for (( i = 0; i < VM_W * VM_H; i++ )); do VM[$i]=.; done
  VP=()
  vn_stamp_head $4 $5 $VN_OX $(( VN_OY * 2 )) ${7:-0}
  [[ -n "$1" ]] && vn_stamp hat "$1" $(( VN_OY * 2 ))
  [[ -n "$2" ]] && vn_stamp spec "$2" $(( VN_OY * 2 ))
  [[ -n "$3" ]] && vn_stamp smoke "$3" $(( VN_OY * 2 ))
  vn_render; vn_fold
  # 2 · the brim's shadow
  local b=${VN_BRIM[hat:$1]:-0} f3 f4; local -F fr
  if [[ -n "$1" ]] && (( b )); then
    d="${VN_BRIMD[$b]}"; f3=${d%% *}; f4=${d##* }
    for cy in 3 4; do
      if (( cy == 3 )); then fr=$f3; else fr=$f4; fi
      (( fr == 1.0 )) && continue
      y=$(( VN_OY + cy )); (( y >= 0 && y < VN_H )) || continue
      for (( x = 0; x < VN_W; x++ )); do
        i=$(( y * VN_W + x )); (( VNC[i] >= 0 )) && { vn_shade ${VNC[$i]} $(( fr )); VNC[$i]=$VS; }
      done
    done
  fi
  # 3 · the ember's light
  local g=${VN_GLOW[smoke:$3]:-} e; local -i ec er
  if [[ -n "$3" && -n "$g" ]]; then
    for e in "${VN_EMBER[@]}"; do
      ec=${e%%,*}; er=${${e#*,}%%,*}
      y=$(( VN_OY + er )); x=$(( VN_OX + ec ))
      (( y >= 0 && y < VN_H && x >= 0 && x < VN_W )) || continue
      i=$(( y * VN_W + x )); (( VNC[i] >= 0 )) && { cmix ${VNC[$i]} $(( 16#$g )) ${e##*,}; VNC[$i]=$CM; }
    done
  fi
  VN_PCACHE[$key]="${VNC[*]}"; VN_ACACHE[$key]="${VNA[*]}"
  return 0 }

# ── the hash the whole suite shares · FNV, then a mix · 32-bit, safely ──
vn_mul32() { REPLY=$(( ( ($1 * ($2 & 0xFFFF)) + ((($1 * ($2 >> 16)) & 0xFFFF) << 16) ) & 0xFFFFFFFF )); return 0 }
vn_whash() {   # vn_whash ID N → REPLY · wisp_hash()
  local s="$1" ch; local -i v=2166136261 i o
  for (( i = 0; i < ${#s}; i++ )); do ch="${s[$i]}"; o=$(( #ch )); vn_mul32 $(( v ^ o )) 16777619; v=$REPLY; done
  vn_mul32 $(( v ^ ($2 & 0xffffffff) )) 16777619; v=$REPLY
  v=$(( v ^ (v >> 15) ))
  vn_mul32 $v 2246822519; v=$REPLY
  REPLY=$(( v ^ (v >> 13) )); return 0 }

# ── 4 · the wisp · one step of its own path a frame, a puff every `every`, a lean
# that alternates puff by puff, a wisp chosen at birth · in HEAD cells
typeset -ga VNW_Y VNW_X VNW_CH VNW_FG
vn_wisp() {   # vn_wisp SMOKE FRAME → VNW_* · smoke_frames(it)[frame % 24]
  local id="$1" p g; local -i f=$(( $2 % VN_SMOKE_FRAMES )) every=${VN_EVERY[smoke:$1]:-2} h0=${VN_FROMH[smoke:$1]:-0} step h a r born wi lean nr rr cc
  local -a ramp path gly; ramp=(${=VN_RAMP[smoke:$1]:-${VN_SMOKE_RAMP[*]}}); nr=${#ramp[@]}
  step=$(( every * VN_SMOKE_SLOW )); (( step < 1 )) && step=1
  VNW_Y=(); VNW_X=(); VNW_CH=(); VNW_FG=()
  for (( h = h0; h < 9; h++ )); do
    a=$(( f - h * VN_SMOKE_SLOW ))
    r=$(( a % step )); (( r < 0 )) && r=$(( r + step ))            # python's modulo · floored
    (( r >= VN_SMOKE_SLOW )) && continue
    born=$(( (a - r) % VN_SMOKE_FRAMES )); (( born < 0 )) && born=$(( born + VN_SMOKE_FRAMES ))
    vn_whash "$id" $born; wi=$(( REPLY % 4 ))
    lean=$(( ((a - r) / step) % 2 )); (( lean < 0 )) && lean=$(( lean + 2 ))   # (a - r) is a whole number of steps
    path=(${=VN_WPATH[$wi]}); gly=(${=VN_WGLY[$wi]})
    p="${path[$h]}"; rr=${p%%,*}; cc=${p#*,}; g="${gly[$h]}"
    VNW_Y+=($rr); VNW_X+=($cc); VNW_CH+=("${g[$lean]}")
    VNW_FG+=($(( 16#${ramp[$(( h < nr - 1 ? h : nr - 1 ))]} )))
  done; return 0 }

# ── the weather · decoded once a frame and kept, since it never depends on him ──
typeset -gA VN_B64 VN_AFX VN_ALX
() { local a='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'; local -i i
     for (( i = 0; i < 64; i++ )); do VN_B64[${a[$i]}]=$i; done }
vn_aura_split() {   # the forty-eight frames of one element, split out the first time it is worn
  local id="$1"; local -a fr; local -i t
  [[ -n "${VN_AFX[$id.ok]:-}" ]] && return 0
  fr=("${(@s:|:)VN_AF[$id]}"); for (( t = 0; t < 48; t++ )); do VN_AFX[$id.$t]="${fr[$t]:-}"; done
  fr=("${(@s:|:)VN_AL[$id]}"); for (( t = 0; t < 48; t++ )); do VN_ALX[$id.$t]="${fr[$t]:-}"; done
  VN_AFX[$id.ok]=1; return 0 }

# ── compose · the rules, in order ────────────────────────────────────────
# VNC is his paint (a colour a cell, -1 air) · VNO_* is the air over it, in
# the order it is drawn: the wisp, the weather's far side, its near side
typeset -ga VNO_Y VNO_X VNO_CH VNO_FG
typeset -g  VN_LAST=''
vn_compose() {   # vn_compose HAT SPEC SMOKE AURA FRAME WIDE · the pose the arcade's own clock deals
  vn_pose $5
  vn_compose_at "$1" "$2" "$3" "$4" $5 $6 $VN_LOOK $VN_LIDS 0
}
# THE SAME COMPOSE, ON SOMEBODY ELSE'S CLOCK.  The TERMINAL keeps a clock of
# its own -- a glance at whoever pressed a key, a far look now and then, a
# squint twice a minute -- and dresses him from this wardrobe rather than a
# copy of it, so the pose is handed in and only the frame (the wisp and the
# weather) is counted here.
vn_compose_at() {   # vn_compose_at HAT SPEC SMOKE AURA FRAME WIDE LOOK LIDS [EYE]
  local hat="$1" spec="$2" smk="$3" au="$4" s c cell pal key; local -i fr=$5 wide=$6 i y x n t gi ci k0 lx ly ls lr lc
  local -F kk dx dy d
  local ckey="$1|$2|$3|$4|$fr|$wide|$7,$8,${9:-0}|${TRUE24:-1}"
  [[ "$ckey" == "$VN_LAST" ]] && return 0                  # the same frame asked for twice · a 60 Hz panel asks four times
  vn_paint "$hat" "$spec" "$smk" $7 $8 $(( wide || ${#au} )) ${9:-0}
  VNO_Y=(); VNO_X=(); VNO_CH=(); VNO_FG=()
  local -A wat
  if [[ -n "$smk" ]]; then
    vn_wisp "$smk" $fr
    for (( i = 0; i < ${#VNW_Y[@]}; i++ )); do
      y=$(( VN_OY + VNW_Y[i] )); x=$(( VN_OX + VNW_X[i] ))
      (( y >= 0 && y < VN_H && x >= 0 && x < VN_W )) || continue
      (( VNC[y * VN_W + x] >= 0 )) && continue                # the wisp yields
      VNO_Y+=($y); VNO_X+=($x); VNO_CH+=("${VNW_CH[$i]}"); VNO_FG+=(${VNW_FG[$i]}); wat[$y,$x]=1
    done
  fi
  if [[ -n "$au" ]]; then
    vn_aura_split "$au"; t=$(( fr % 48 ))
    # his outline, not his cells · every row filled from the first thing he owns on it to the last
    local -A body hide; local -i lo hi
    for (( y = 0; y < VN_H; y++ )); do
      lo=-1; hi=-1
      for (( x = 0; x < VN_W; x++ )); do (( VNC[y * VN_W + x] >= 0 )) && { body[$y,$x]=1; (( lo < 0 )) && lo=$x; hi=$x; }; done
      (( lo >= 0 )) && for (( x = lo; x <= hi; x++ )); do hide[$y,$x]=1; done
    done
    # the element's cells, back and front · a later cell at the same spot wins, in the first one's place
    local -A bk fk; local -a bo fo; pal="${VN_APAL[$au]}"; s="${VN_AFX[$au.$t]}"; n=$(( ${#s} / 5 ))
    for (( i = 0; i < n; i++ )); do
      cell="${s[$(( i * 5 )),$(( i * 5 + 4 ))]}"
      x=${VN_B64[${cell[0]}]}; y=${VN_B64[${cell[1]}]}; gi=${VN_B64[${cell[2]}]}; ci=$(( VN_B64[${cell[3]}] * 64 + VN_B64[${cell[4]}] ))
      key="$y,$x"; c="${VN_AG[$(( gi / 2 ))]}:${pal[$(( ci * 6 )),$(( ci * 6 + 5 ))]}"
      if (( gi % 2 )); then [[ -n "${fk[$key]:-}" ]] || fo+=("$key"); fk[$key]="$c"
      else [[ -n "${bk[$key]:-}" ]] || bo+=("$key"); bk[$key]="$c"; fi
    done
    for key in "${bo[@]}"; do                               # 5 · the far side, in the air he does not own
      y=${key%%,*}; x=${key#*,}
      (( y >= 0 && y < VN_H && x >= 0 && x < VN_W )) || continue
      (( VNC[y * VN_W + x] < 0 )) || continue
      [[ -n "${wat[$key]:-}${hide[$key]:-}" ]] && continue
      c="${bk[$key]}"; VNO_Y+=($y); VNO_X+=($x); VNO_CH+=("${c%%:*}"); VNO_FG+=($(( 16#${c##*:} )))
    done
    # 6 · its ambient light on him · the last window the frame falls in
    local lt='' w; local -a ww
    for w in "${(@s:;:)VN_LIT[aura:$au]}"; do
      ww=(${=w}); (( ${#ww[@]} == 5 )) || continue
      (( ww[0] <= t && t < ww[1] )) && lt="$w"
    done
    if [[ -n "$lt" ]]; then
      ww=(${=lt}); lc=$(( 16#${ww[2]} ))
      for key in "${(k)body[@]}"; do
        y=${key%%,*}; x=${key#*,}
        case "${ww[4]}" in
          up)    kk=$(( ww[3] * (y / (VN_H - 1.0)) )) ;;
          down)  kk=$(( ww[3] * (1.0 - y / (VN_H - 1.0)) )) ;;
          left)  kk=$(( ww[3] * (1.0 - x / (VN_W - 1.0)) )) ;;
          right) kk=$(( ww[3] * (x / (VN_W - 1.0)) )) ;;
          *)     kk=$(( ww[3] * 1.0 )) ;;
        esac
        (( kk > 0.01 )) && { i=$(( y * VN_W + x )); cmix ${VNC[$i]} $lc $(( kk )); VNC[$i]=$CM; }
      done
    fi
    # 7 · its local lights · every source warms what is near it, measured in the cell's own shape
    s="${VN_ALX[$au.$t]}"; n=$(( ${#s} / 7 ))
    for (( k0 = 0; k0 < n; k0++ )); do
      cell="${s[$(( k0 * 7 )),$(( k0 * 7 + 6 ))]}"
      lx=$(( VN_B64[${cell[0]}] - 16 )); ly=$(( VN_B64[${cell[1]}] - 16 ))
      ci=$(( VN_B64[${cell[2]}] * 64 + VN_B64[${cell[3]}] )); lc=$(( 16#${pal[$(( ci * 6 )),$(( ci * 6 + 5 ))]} ))
      ls=$(( VN_B64[${cell[4]}] * 64 + VN_B64[${cell[5]}] )); lr=${VN_B64[${cell[6]}]}
      for key in "${(k)body[@]}"; do
        y=${key%%,*}; x=${key#*,}
        dx=$(( x - lx )); dy=$(( (y - ly) * 2.0 )); d=$(( sqrt(dx * dx + dy * dy) ))
        (( d < lr )) || continue
        kk=$(( ls / 100.0 * (1.0 - d / lr) ))
        (( kk > 0.02 )) && { i=$(( y * VN_W + x )); cmix ${VNC[$i]} $lc $(( kk )); VNC[$i]=$CM; }
      done
    done
    for key in "${fo[@]}"; do                               # 5 · the near side · 8 · never on him
      y=${key%%,*}; x=${key#*,}
      (( y >= 0 && y < VN_H && x >= 0 && x < VN_W )) || continue
      [[ -n "${body[$key]:-}${hide[$key]:-}${wat[$key]:-}" ]] && continue
      c="${fk[$key]}"; VNO_Y+=($y); VNO_X+=($x); VNO_CH+=("${c%%:*}"); VNO_FG+=($(( 16#${c##*:} )))
    done
  fi
  VN_LAST="$ckey"
  return 0 }

# vn_blit X Y BG — his cells are PAINT (a space with a ground), the air over him glyphs
# that take whatever is under them: his paint where he is behind them, BG where not
# STRAIGHT INTO THE CELLS, the way a_rect goes · a card is three hundred and
# sixty-four of them, and three calls deep a cell was most of what he cost
vn_blit() {
  local -i x0=$1 y0=$2 bg=${3:--2} i x y u k cx cy base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  for (( y = 0; y < VN_H; y++ )); do
    cy=$(( y0 + y )); (( cy < 0 || cy >= AR_H )) && continue
    for (( x = 0; x < VN_W; x++ )); do
      cx=$(( x0 + x )); (( cx < 0 || cx >= AR_W )) && continue
      i=$(( y * VN_W + x )); (( VNC[i] >= 0 )) || continue
      k=$(( base + cy * TCOLS + cx )); GCH[$k]=' '; GB[$k]=${VNC[$i]}
    done
  done
  for (( i = 0; i < ${#VNO_Y[@]}; i++ )); do
    y=${VNO_Y[$i]}; x=${VNO_X[$i]}; cy=$(( y0 + y )); cx=$(( x0 + x ))
    (( cy < 0 || cy >= AR_H || cx < 0 || cx >= AR_W )) && continue
    u=${VNC[$(( y * VN_W + x ))]}; (( u < 0 )) && u=$bg
    k=$(( base + cy * TCOLS + cx )); GCH[$k]="${VNO_CH[$i]}"; GF[$k]=${VNO_FG[$i]}; (( u != -2 )) && GB[$k]=$u
  done
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# THE RAIL · what he owns, what he has on, and what it is worth
# ══════════════════════════════════════════════════════════════════════════
# The save keeps a receipt per item (wardrobe.slot:id = when) and one id per
# slot (worn.slot).  A worn id no rack carries is simply bare.
ar_vn_worn() {   # ar_vn_worn SLOT → REPLY the id he has on there, '' when bare
  REPLY="${AR[worn.$1]:-}"
  [[ -n "$REPLY" && -n "${VN_NAME[$1:$REPLY]:-}" ]] || REPLY=''
  return 0 }
ar_vn_owns() { [[ -n "${AR[wardrobe.$1:$2]:-}" ]] }
typeset -ga VNR
vn_rack() {   # vn_rack SLOT → VNR its ids, in rack order · "name[@]" for (P), which under KSH_ARRAYS would hand back one
  local m="VN_R_$1[@]"; VNR=(${(P)m}); return 0 }
ar_vn_rack_n() { vn_rack $1; REPLY=${#VNR[@]}; return 0 }
ar_vn_id() { vn_rack $1; REPLY="${VNR[$2]:-}"; return 0 }   # ar_vn_id SLOT INDEX
ar_vn_have_n() {   # ar_vn_have_n SLOT → REPLY how many of that rack are on the rail
  local id; local -i n=0
  vn_rack $1; for id in "${VNR[@]}"; do [[ -n "${AR[wardrobe.$1:$id]:-}" ]] && n=$(( n + 1 )); done
  REPLY=$n; return 0 }
ar_vn_stock() { local s; local -i n=0; for s in "${VN_SLOTS[@]}"; do ar_vn_rack_n $s; n=$(( n + REPLY )); done; REPLY=$n; return 0 }
ar_vn_kinds() { local s; local -i n=0; for s in "${VN_SLOTS[@]}"; do ar_vn_have_n $s; (( REPLY )) && n=$(( n + 1 )); done; REPLY=$n; return 0 }
ar_vn_full_set() { ar_vn_kinds; (( REPLY >= ${#VN_SLOTS[@]} )) }
ar_vn_slot_label() { local -i i; for (( i = 0; i < 4; i++ )); do [[ "${VN_SLOTS[$i]}" == "$1" ]] && { REPLY="${VN_SLABS[$i]}"; return 0 }; done; REPLY="$1"; return 0 }
typeset -gi AR_VN_N=0
typeset -g  AR_VN_SAID=''
ar_vn_stock_all() {   # ar_vn_stock_all [SLOT] · the rack on the rail for nothing · AR_VN_N how many are on it
  local s id; local -i now=${EPOCHSECONDS:-0}
  AR_VN_N=0
  for s in "${VN_SLOTS[@]}"; do
    [[ -n "${1:-}" && "$s" != "$1" ]] && continue
    vn_rack $s
    for id in "${VNR[@]}"; do [[ -n "${AR[wardrobe.$s:$id]:-}" ]] || AR[wardrobe.$s:$id]=$now; AR_VN_N=$(( AR_VN_N + 1 )); done
  done
  AR_DIRTY=1; return 0 }
# WHAT IT IS WORTH AT THE PAYOUT · a percent a worn slot by rarity, five more for all four
ar_style_pct() {   # → REPLY percent, AR_STYLE_FILLED slots
  local s; local -i pct=0 filled=0
  for s in "${VN_SLOTS[@]}"; do
    ar_vn_worn $s; [[ -n "$REPLY" ]] || continue
    filled=$(( filled + 1 )); pct=$(( pct + ${VN_STYLE[${VN_RAR[$s:$REPLY]}]:-1} ))
  done
  (( filled >= ${#VN_SLOTS[@]} )) && pct=$(( pct + VN_STYLE_FULL ))
  AR_STYLE_FILLED=$filled; REPLY=$pct; return 0 }
# the trophy wall's questions
ar_vn_owned_rar() { local k; for k in ${(M)${(k)AR[@]}:#wardrobe.*}; do [[ "${VN_RAR[${k#wardrobe.}]:-}" == "$1" ]] && return 0; done; return 1 }
ar_vn_whole_rack() { local -i have; ar_vn_have_n $1; have=$REPLY; ar_vn_rack_n $1; (( REPLY > 0 && have >= REPLY )) }
ar_vn_rarities() { local k; local -A seen; for k in ${(M)${(k)AR[@]}:#wardrobe.*}; do [[ -n "${VN_RAR[${k#wardrobe.}]:-}" ]] && seen[${VN_RAR[${k#wardrobe.}]}]=1; done; REPLY=${#seen[@]}; return 0 }
ar_vn_worn_rar() { local s; local -i n=0; for s in "${VN_SLOTS[@]}"; do ar_vn_worn $s; [[ -n "$REPLY" && "${VN_RAR[$s:$REPLY]}" == "$1" ]] && n=$(( n + 1 )); done; REPLY=$n; return 0 }

# ── buy it, or wear it, or take it off · whichever is next ───────────────
ar_vn_take() {   # ar_vn_take SLOT INDEX → the market's note
  local s="$1" id; local -i price have=${AR[credits]:-0}
  ar_vn_id $s $2; id="$REPLY"; [[ -n "$id" ]] || return 0
  price=${VN_PRICE[$s:$id]}
  if ! ar_vn_owns $s "$id"; then
    if (( have < price )); then ar_snd error; ar_mk_note "NOT ENOUGH COINS · $(( price - have )) SHORT"; return 0; fi
    AR[credits]=$(( have - price )); AR[wardrobe.$s:$id]=${EPOCHSECONDS:-0}; AR_DIRTY=1; ar_save_write
    ar_snd coin; ar_badges_check; ar_mk_note "BOUGHT · ${VN_NAME[$s:$id]}"; return 0
  fi
  ar_vn_worn $s
  if [[ "$REPLY" == "$id" ]]; then unset "AR[worn.$s]"; AR_DIRTY=1; ar_save_write; ar_snd move; ar_badges_check; ar_mk_note "TAKEN OFF · ${VN_NAME[$s:$id]}"
  else AR[worn.$s]="$id"; AR_DIRTY=1; ar_save_write; ar_snd select; ar_badges_check; ar_mk_note "WEARING · ${VN_NAME[$s:$id]}"; fi
  return 0 }
# ── surprise me · the one real die in the suite, rolled at wear time and written down ──
# one slot in three rolls bare, one in seven leaves two · never what he has on
ar_vn_surprise() {
  local s was='' now id; local -a slots have names bare; local -A put isbare; local -i nb i try k
  if ! ar_vn_full_set; then ar_vn_kinds; ar_snd error; AR_VN_SAID="SURPRISE ME NEEDS ONE OF EVERY KIND · $REPLY OF ${#VN_SLOTS[@]}"; ar_mk_note "$AR_VN_SAID"; return 0; fi
  slots=("${VN_SLOTS[@]}")
  for s in "${slots[@]}"; do ar_vn_worn $s; was+="$s=$REPLY;"; done
  for (( try = 0; try < 6; try++ )); do
    k=$(( RANDOM % 100 )); if (( k < 55 )); then nb=0; elif (( k < 85 )); then nb=1; else nb=2; fi
    bare=("${slots[@]}")
    for (( i = ${#bare[@]} - 1; i > 0; i-- )); do k=$(( RANDOM % (i + 1) )); id="${bare[$i]}"; bare[$i]="${bare[$k]}"; bare[$k]="$id"; done   # a shuffle · the first nb go bare
    isbare=(); for (( i = 0; i < nb; i++ )); do isbare[${bare[$i]}]=1; done
    put=(); now=''
    for s in "${slots[@]}"; do
      if [[ -n "${isbare[$s]:-}" ]]; then put[$s]=''
      else have=(); vn_rack $s; for id in "${VNR[@]}"; do [[ -n "${AR[wardrobe.$s:$id]:-}" ]] && have+=("$id"); done; put[$s]="${have[$(( RANDOM % ${#have[@]} ))]}"; fi
      now+="$s=${put[$s]};"
    done
    [[ "$now" != "$was" ]] && break
  done
  names=()
  for s in "${slots[@]}"; do
    if [[ -n "${put[$s]}" ]]; then AR[worn.$s]="${put[$s]}"; names+=("${VN_NAME[$s:${put[$s]}]}"); else unset "AR[worn.$s]"; fi
  done
  AR_DIRTY=1; ar_save_write; ar_snd select; ar_badges_check
  if (( ${#names[@]} )); then AR_VN_SAID="SURPRISE · ${(j: + :)names}"; else AR_VN_SAID='SURPRISE · NOTHING AT ALL'; fi
  ar_mk_note "$AR_VN_SAID"; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# THE MIRROR · the market's racks, his fitting room, the payout gutter, the reel
# ══════════════════════════════════════════════════════════════════════════
ar_vn_row() {   # ar_vn_row SLOT INDEX Y HOT · one line of a rack
  local s="$1" id word; local -i y=$3 hot=$4 acc tc wc c
  ar_vn_id $s $2; id="$REPLY"
  acc=${AR_RARC[${VN_RAR[$s:$id]}]:-$GREY}
  if (( hot )); then ar_hotrow $y $acc; tc=$WHITE; else cshade $GREY 1.05; tc=$CS; fi
  cshade $acc $(( hot ? 1.0 : 0.7 )); a_put 4 $y '◆' $CS -2
  a_text 6 $y "${VN_NAME[$s:$id][0,16]}" $tc -2
  ar_vn_worn $s
  if [[ "$REPLY" == "$id" ]]; then word=WORN; wc=$LIME
  elif ar_vn_owns $s "$id"; then word=OWNED; cshade $LIME 0.62; wc=$CS
  else word="${VN_PRICE[$s:$id]} ◉"; wc=$AMBER; fi
  if (( hot )); then cmix $wc $WHITE 0.25; c=$CM; else cshade $wc 0.8; c=$CS; fi
  a_text $(( AR_LIST_W - 2 - ${#word} )) $y "$word" $c -2
  return 0 }
ar_vn_outfit() {   # ar_vn_outfit [SLOT ID] → VN_OH VN_OS VN_OK VN_OA · what he has on, one slot swapped for a try-on
  ar_vn_worn hat; VN_OH="$REPLY"; ar_vn_worn spec; VN_OS="$REPLY"; ar_vn_worn smoke; VN_OK="$REPLY"; ar_vn_worn aura; VN_OA="$REPLY"
  case "${1:-}" in hat) VN_OH="$2" ;; spec) VN_OS="$2" ;; smoke) VN_OK="$2" ;; aura) VN_OA="$2" ;; esac
  return 0 }
typeset -g VN_OH='' VN_OS='' VN_OK='' VN_OA='' VN_DISCK=''
typeset -ga VN_DISC
ar_vn_panel() {   # THE ROOM IS THE MIRROR · him in what he has on, with this one tried in its slot
  local s="$1" id rr deal; local -i px=$AR_RM_PX pw=$AR_RM_PW py=$AR_RM_PY ph=$AR_RM_PH pb rc dc crown
  ar_vn_id $s $2; id="$REPLY"
  cmix $GLASS $PURPLE 0.13; pb=$CM
  cshade $PURPLE 0.85; a_box $px $py $pw $ph $CS $pb round 1
  # him first, the writing over him · his crown on one row whichever box he came in
  # (arcade.py's row six): the weather's taller field centred down the mirror, and
  # the card hung from the same crown, so trying on an aura never makes him jump
  ar_vn_outfit $s "$id"
  vn_compose "$VN_OH" "$VN_OS" "$VN_OK" "$VN_OA" $(( int(AR_T * 10.0) )) 0
  crown=$(( py + (ph - VN_FIELD[1]) / 2 + VN_FIELD[3] )); (( crown < py + 1 + VN_FIELD[3] )) && crown=$(( py + 1 + VN_FIELD[3] ))
  vn_blit $(( px + (pw - VN_W) / 2 )) $(( crown - VN_OY )) $pb
  rc=${AR_RARC[${VN_RAR[$s:$id]}]:-$GREY}
  rr=" ${VN_RAR[$s:$id]}"; cshade $rc 0.9; a_text $(( px + pw - 1 - ${#rr} )) $py "$rr" $CS $pb
  local nm="${VN_NAME[$s:$id]}"; local -i room=$(( pw - 3 - ${#rr} )); (( room < 1 )) && room=1
  cmix $WHITE $rc 0.3; a_text $(( px + 1 )) $py " ${nm[0,$(( room - 1 ))]}" $CM $pb
  ar_vn_worn $s
  if [[ "$REPLY" == "$id" ]]; then deal=' WORN · ↵ TAKES IT OFF '; cmix $LIME $WHITE 0.35; dc=$CM
  elif ar_vn_owns $s "$id"; then deal=' OWNED · ↵ TO PUT IT ON '; cshade $LIME 0.85; dc=$CS
  elif (( ${AR[credits]:-0} >= ${VN_PRICE[$s:$id]} )); then deal=" ${VN_PRICE[$s:$id]} ◉ · ↵ TO BUY "; cmix $AMBER $WHITE 0.3; dc=$CM
  else deal=" ${VN_PRICE[$s:$id]} ◉ · NOT ENOUGH COINS "; cshade $RED 0.95; dc=$CS; fi
  a_center $(( py + ph - 1 )) "${deal[0,$(( pw - 3 ))]}" $dc $pb $px $pw
  return 0 }
ar_vn_footer() {   # the market's message line, the bottom row of the CRT
  local -i my=$(( AR_H - 1 ))
  cshade $GREY 1.0
  if ar_vn_full_set; then a_center $my 'one of each, never two  ·  [R] rolls an outfit out of your own wardrobe' $CS $GLASS
  # arcade.py spaced this one like its neighbour and it ran to seventy-six on a
  # seventy-two column CRT, cut at both ends · the same words, closer together
  else ar_vn_kinds; a_center $my "one of each, never two · own one of every kind for SURPRISE ME · $REPLY OF ${#VN_SLOTS[@]}" $CS $GLASS; fi
  return 0 }
# HE STANDS IN THE GUTTER WHEN HE EARNED YOU SOMETHING · fourteen rows tall, centred in it
# ar_vn_gutter [X W Y H] — the gutter's box on the CRT · by default columns 0 .. AR_PAY_CX-1
# and every row under the band, so a payout that moves or widens its gutter keeps him in it
ar_vn_gutter() {
  local -i gx0=${1:-0} gw=${2:-$AR_PAY_CX} gy0=${3:-1} gh=${4:-$(( AR_H - 1 ))} gx gy
  ar_vn_outfit
  vn_compose "$VN_OH" "$VN_OS" "$VN_OK" "$VN_OA" $(( int(AR_T * 10.0) )) 1
  gx=$(( gx0 + (gw - VN_W) / 2 )); gy=$(( gy0 + (gh - VN_H) / 2 ))
  (( gx < 0 )) && gx=0; (( gy < 1 )) && gy=1
  vn_blit $gx $gy $GLASS
  return 0 }
# THE VISITOR GETS A SCENE OF HIS OWN · him, dressed, and what he has on down the sky beside him
# ar_at_visitor [OY] — the scene arcade.py drew on rows 0..16, brought down OY rows · by default
# half of what the tube has over its eighteen, so he stands in the middle of a taller glass (the
# reel's own ◂ PRESS ANY KEY ▸ is the caller's, on the bottom row)
ar_at_visitor() {
  local -F t=$AR_T f; local -i gx gy i x y rx0 rw pct filled acc c oy; local s
  if [[ "${1:-}" == <-> ]]; then oy=$1; else oy=$(( (AR_H - AR_OH) / 2 )); (( oy < 0 )) && oy=0; fi
  ar_wave $t 0.5; cmix $PURPLE $WHITE $(( 0.25 + 0.2 * WV )); a_center $oy '◆  T H E   V I S I T O R  ◆' $CM -2
  ar_vn_outfit
  vn_compose "$VN_OH" "$VN_OS" "$VN_OK" "$VN_OA" $(( int(t * 10.0) )) 1
  gx=$(( (AR_W - VN_W) / 2 )); gy=$(( 1 + oy ))
  # sweep the stars out of the ring first · the aura is a disc, so the hole is one too
  # (the disc is worked out once a box, and written straight into the cells)
  local -F dx dy; local -i k base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX ))
  if [[ "${VN_DISCK:-}" != "$VN_W,$VN_H" ]]; then
    VN_DISC=()
    for (( y = 0; y < VN_H; y++ )); do
      for (( x = 0; x < VN_W; x++ )); do
        dx=$(( (x + 0.5) / VN_W * 2.0 - 1.0 )); dy=$(( (y + 0.5) / VN_H * 2.0 - 1.0 ))
        (( dx * dx + dy * dy <= 1.0 )) && VN_DISC+=($(( y * 1000 + x )))
      done
    done
    VN_DISCK="$VN_W,$VN_H"
  fi
  for i in "${VN_DISC[@]}"; do
    y=$(( gy + i / 1000 )); x=$(( gx + i % 1000 ))
    (( y < 0 || y >= AR_H || x < 0 || x >= AR_W )) && continue
    k=$(( base + y * TCOLS + x )); GCH[$k]=' '; GB[$k]=$BLACK
  done
  # a floor under him, so he is standing rather than floating
  for (( i = 0; i < VN_W + 8; i++ )); do
    f=$(( 1.0 - abs(i - (VN_W + 8) / 2.0) / ((VN_W + 8) / 2.0) ))
    cshade $PURPLE $(( 0.30 + 0.55 * f )); a_put $(( gx - 4 + i )) $(( gy + VN_H )) '▁' $CS -2
  done
  vn_blit $gx $gy -2
  # the rail, down the sky to his right · one line an item, in the colour of what it cost
  rx0=$(( gx + VN_W + 1 )); rw=$(( AR_W - rx0 )); (( rw < 0 )) && rw=0
  local -a rail; rail=()
  for s in "${VN_SLOTS[@]}"; do ar_vn_worn $s; [[ -n "$REPLY" ]] && rail+=("$s:$REPLY"); done
  for (( i = 0; i < ${#rail[@]} && i < 4; i++ )); do
    acc=${AR_RARC[${VN_RAR[${rail[$i]}]}]:-$GREY}; cmix $acc $WHITE 0.30
    s="◆ ${VN_NAME[${rail[$i]}]}"; (( rw > 2 )) && s="${s[0,$(( rw - 1 ))]}"
    a_center $(( 5 + oy + i )) "$s" $CM -2 $rx0 $rw
  done
  ar_style_pct; pct=$REPLY; filled=$AR_STYLE_FILLED
  if (( ! ${#rail[@]} )); then cshade $GREY 1.0; a_center $(( 16 + oy )) 'NOTHING ON THE RAIL YET  ·  [B] OPENS THE SHOP' $CS -2
  elif (( filled )); then ar_wave $t 0.7; cmix $AMBER $WHITE $(( 0.2 + 0.25 * WV )); a_center $(( 16 + oy )) "STYLE BONUS  +$pct%  ON EVERY PAYOUT" $CM -2; fi
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# SECTION 17 · THE DEMONSTRATOR      a hand on every stick, for DEMO PLAY and the attract reel
# ══════════════════════════════════════════════════════════════════════════
# None of these are meant to be good.  They are meant to be COMPETENT: to
# clear a wall, hold a lane, take a corner, keep a ball alive — the way a
# person who has played the machine twice would.  Where a bot could trivially
# be perfect (pong, the beat grid) it is given a reaction band or plays a
# hair late on purpose, because a machine that never loses demonstrates
# nothing.  Each answers AR_DKEYS, the keys it would press this frame.
typeset -ga AR_DKEYS
ar_demo_keys() {   # → AR_DKEYS for the game in play · a bot that has nothing to say says nothing
  AR_DKEYS=()
  (( ${+functions[${AR_GP}_demo]} )) && ${AR_GP}_demo 2>/dev/null
  return 0 }
ar_towards() {   # ar_towards NOW WANT LESS MORE [SLACK=0.4] · the one-axis chase every paddle needs
  local -F now=$1 want=$2 slack=${5:-0.4}
  if (( now < want - slack )); then AR_DKEYS+=($4); elif (( now > want + slack )); then AR_DKEYS+=($3); fi
  return 0 }
# EACH MACHINE'S OWN BOT LIVES IN ITS OWN FILE, beside the rules it plays by: a
# board that grows is a board its bot has to learn, and the two change together.
# ══════════════════════════════════════════════════════════════════════════
# SECTION 18 · ATTRACT MODE       twenty seconds of nobody, and the cabinet starts selling itself
# ══════════════════════════════════════════════════════════════════════════
# The logo, today's best, a machine at a time, how to play, and — once he
# owns anything — the visitor in what he has on.  The first key only wakes
# the arcade.  Nobody watches the reel for three minutes except the sort of
# person who ought to find what it says then.
typeset -gF AR_IDLE_T=0.0 AR_IDLE_NEED=20.0
# THE REEL'S OWN NIGHT · ninety stars exactly where arcade.py's Random(1988) put
# them, carried as numbers (gen_starfield) rather than dealt again by another
# generator into another sky · x, y across the CRT, and each one's speed
typeset -ga AR_STX AR_STY AR_STS
AR_STX=(0.812438 0.148425 0.626566 0.107578 0.381583 0.157533 0.111846 0.423624 0.255730 0.841909 0.758304 0.945146 0.011249 0.375713 0.939617 0.744283 0.163166 0.070830 0.749551 0.763556 0.164473 0.555138 0.462075 0.341583 0.155483 0.188654 0.549097 0.299261 0.537820 0.460206 0.568378 0.157345 0.769041 0.043390 0.140003 0.825380 0.132851 0.276339 0.331620 0.760204 0.536903 0.952166 0.364486 0.780186 0.401711 0.618600 0.259894 0.371617 0.769762 0.431044 0.489942 0.254944 0.920750 0.465911 0.264967 0.796555 0.674989 0.617193 0.924964 0.464070 0.498492 0.867836 0.019450 0.350377 0.536474 0.725864 0.509986 0.351306 0.525363 0.421220 0.919970 0.618719 0.567882 0.498293 0.341701 0.238147 0.873635 0.619121 0.152094 0.856623 0.492260 0.320286 0.679593 0.758530 0.612406 0.193998 0.758539 0.177147 0.905457 0.810538)
AR_STY=(0.121048 0.185989 0.263220 0.537074 0.557956 0.184901 0.965866 0.199974 0.660768 0.761254 0.010029 0.079834 0.132409 0.293143 0.041742 0.122250 0.623516 0.846892 0.887331 0.876649 0.812802 0.624313 0.980224 0.614981 0.168685 0.953011 0.740489 0.188984 0.885743 0.607429 0.330922 0.410279 0.432331 0.021373 0.770124 0.345590 0.342001 0.507200 0.894217 0.774076 0.467818 0.909790 0.879047 0.647736 0.351849 0.783919 0.979223 0.372570 0.904936 0.191036 0.189079 0.369419 0.271319 0.647257 0.860066 0.006398 0.546814 0.367101 0.787191 0.399992 0.380344 0.683390 0.866222 0.306325 0.344199 0.283586 0.395359 0.725788 0.651289 0.668085 0.078377 0.318580 0.007170 0.017023 0.514979 0.832008 0.206738 0.096761 0.765712 0.942787 0.230785 0.145052 0.493824 0.871744 0.134845 0.544420 0.539940 0.338757 0.058862 0.644580)
AR_STS=(0.90 0.55 0.35 0.55 0.90 0.35 0.55 0.90 0.90 0.90 0.55 0.90 0.90 0.55 0.35 0.35 0.35 0.35 0.90 0.90 0.90 0.55 0.55 0.90 0.55 0.90 0.35 0.55 0.90 0.90 0.55 0.55 0.90 0.55 0.55 0.90 0.90 0.35 0.35 0.55 0.35 0.55 0.55 0.35 0.55 0.35 0.35 0.55 0.35 0.35 0.90 0.55 0.35 0.55 0.55 0.35 0.55 0.90 0.35 0.55 0.35 0.35 0.90 0.35 0.55 0.55 0.35 0.55 0.90 0.35 0.90 0.35 0.35 0.90 0.55 0.90 0.35 0.55 0.55 0.35 0.35 0.35 0.55 0.35 0.35 0.35 0.90 0.90 0.55 0.90)
typeset -gi AR_ST_N=90
ar_stars_init() { return 0 }
ar_attract_on() {   # 0 when the menu has stood untouched long enough
  [[ "$AR_VIEW" == menu ]] || return 1
  (( ${AR_CF[attract]:-1} )) || return 1
  local -F since=$AR_IDLE_T; (( AR_VIEW_T0 > since )) && since=$AR_VIEW_T0
  (( AR_T - since > AR_IDLE_NEED )) }
ar_attract_age() {
  local -F since=$AR_IDLE_T; (( AR_VIEW_T0 > since )) && since=$AR_VIEW_T0; RF=$(( AR_T - since - AR_IDLE_NEED )); return 0 }
ar_at_stars() {   # ar_at_stars AMOUNT · straight into the cells, the ink worked out once a brightness
  local -F t=$AR_T amt=$1 sp f; local -i i x y k base=$(( (OY + R_SCR + AY) * TCOLS + OX + C_SCR + AX )) c; local key
  ar_stars_init
  for (( i = 0; i < AR_ST_N; i++ )); do
    sp=${AR_STS[$i]}; key="$sp:$amt"
    c=${AR_STC[$key]:-0}
    if (( ! c )); then cmix $CYAN $WHITE $sp; cshade $CM $(( amt * sp )); c=$CS; AR_STC[$key]=$c; fi
    f=$(( AR_STX[i] - t * sp * 0.012 )); f=$(( f - floor(f) ))
    x=$(( int(f * AR_W) )); y=$(( int(AR_STY[i] * AR_H) ))
    (( x >= 0 && x < AR_W && y >= 0 && y < AR_H )) || continue
    k=$(( base + y * TCOLS + x ))
    if (( sp < 0.6 )); then GCH[$k]='·'; else GCH[$k]='•'; fi; GF[$k]=$c
  done
  return 0 }
typeset -gA AR_STC
ar_big_cols() {   # ar_big_cols WORD X Y GLOW [BASE] · the door's block font, inked a column at a time from AR_BCOL
  # …whitened a row at a time on top when AR_BROW holds a row's worth of amounts, and
  # shaded a row at a time when AR_BRSH does · (arcade.py's draw_big took a colour per
  # cell, and the column and the row are all any page ever used it for) · BASE is what
  # the glow is mixed out of, where the ground under the word is not the glass
  local -i i k x0=$(( AX + $2 )) y0=$(( AY + $3 )) base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR )) cx cy c q got rows=${#AR_BROW[@]} srows=${#AR_BRSH[@]} hb=${5:--1} gl=$4
  big_word "$1" $x0 $y0 $4
  if (( hb >= 0 )); then
    for (( i = 0; i < HALN; i++ )); do
      (( HALX[i] < 0 || HALX[i] >= SCR_W || HALY[i] < 0 || HALY[i] >= SCR_H )) && continue
      q=$(( int(0.135 * HALV[i] * 1000 + 0.5) )); got=${AR_TMEMO[h:$hb:$gl:$q]:--1}
      (( got < 0 )) && { cmix $hb $gl $(( 0.135 * HALV[i] )); got=$CM; AR_TMEMO[h:$hb:$gl:$q]=$got; }
      GB[$(( base + HALY[i] * TCOLS + HALX[i] ))]=$got
    done
  fi
  for (( i = 0; i < BIGN; i++ )); do
    (( BIGX[i] < 0 || BIGX[i] >= SCR_W || BIGY[i] < 0 || BIGY[i] >= SCR_H )) && continue
    cx=$(( BIGX[i] - x0 )); k=$(( base + BIGY[i] * TCOLS + BIGX[i] ))
    c=${AR_BCOL[$cx]:-$WHITE}; cy=$(( BIGY[i] - y0 ))
    if (( rows )); then
      q=$(( int(${AR_BROW[$cy]:-0} * 100 + 0.5) ))
      if (( q > 0 )); then
        got=${AR_TMEMO[w:$c:$q]:--1}
        if (( got < 0 )); then cmix $c $WHITE $(( q / 100.0 )); got=$CM; AR_TMEMO[w:$c:$q]=$got; fi
        c=$got
      fi
    fi
    if (( srows )); then
      q=$(( int(${AR_BRSH[$cy]:-1} * 100 + 0.5) ))
      if (( q != 100 )); then
        got=${AR_TMEMO[s:$c:$q]:--1}
        if (( got < 0 )); then cshade $c $(( q / 100.0 )); got=$CS; AR_TMEMO[s:$c:$q]=$got; fi
        c=$got
      fi
    fi
    GCH[$k]='█'; GF[$k]=$c
  done
  return 0 }
typeset -ga AR_BCOL AR_BROW AR_BRSH
ar_big_sweep() {   # ar_big_sweep BW FROM TO SPAN SPEED PERIOD PAD RADIUS PEAK → AR_BCOL
  # FROM into TO across SPAN of the word, and a white sweep crossing it: the
  # arcade.py headline recipe ((t·SPEED) mod PERIOD)·(bw+PAD) − PAD/2, falling off over RADIUS
  local -i bw=$1 cx; local -F sw d r=$8
  sw=$(( AR_T * $5 )); sw=$(( (sw - floor(sw / $6) * $6) * (bw + $7) - $7 / 2.0 ))
  AR_BCOL=()
  for (( cx = 0; cx < bw; cx++ )); do
    cmix $2 $3 $(( cx / (bw > 1 ? bw * 1.0 : 1.0) * $4 ))
    d=$(( abs(cx - sw) )); (( d < r )) && cmix $CM $WHITE $(( (1.0 - d / r) ** 2 * $9 ))
    AR_BCOL[$cx]=$CM
  done; return 0 }

# THE REEL IS COMPOSED ON arcade.py'S 72 × 18 · its logo and its titles are the
# block font's size, not the glass's, and its lists are set in its columns.  So
# the night sky fills the whole CRT, and each scene is drawn in a 72 × 18 box
# standing in the middle of it -- the scenes are lent that box as their CRT for
# the length of the draw, and the real one is handed back after.
typeset -gi AR_AT_SW AR_AT_SH AR_AT_SX AR_AT_SY
ar_at_box()   { AR_AT_SW=$AR_W; AR_AT_SH=$AR_H; AR_AT_SX=$AX; AR_AT_SY=$AY
                AX=$(( AX + (AR_W - AR_OW) / 2 )); AY=$(( AY + (AR_H - AR_OH) / 2 )); AR_W=$AR_OW; AR_H=$AR_OH; return 0 }
ar_at_unbox() { AR_W=$AR_AT_SW; AR_H=$AR_AT_SH; AX=$AR_AT_SX; AY=$AR_AT_SY; return 0 }
ar_draw_attract() {
  local -F t=$AR_T at amt; local -i scenes scene bw
  ar_attract_age; at=$RF
  if (( at > 180.0 )) && (( at - floor(at / 47.0) * 47.0 < 3.0 )); then
    a_rect 0 0 $AR_W $AR_H ' ' -2 $GLASS
    ar_at_box
    big_width SERVICE; bw=$BW
    ar_wave $at 0.7; cshade $AMBER $(( 0.35 + 0.3 * WV ))
    a_big SERVICE $(( (AR_W - bw) / 2 )) 4 $AMBER $CS
    cshade $AMBER 0.8; a_center 11 'M O D E   L O C K E D' $CS $GLASS
    a_center 13 'ALIEN DYNAMICS NX-88  ·  OPERATOR ACCESS REQUIRED' $AR_LO $GLASS
    ar_at_unbox
    return 0
  fi
  scenes=4; ar_nkeys 'wardrobe.*'; (( AR_VN_OK && REPLY )) && scenes=5
  scene=$(( int(at / 8.0) % scenes ))
  a_rect 0 0 $AR_W $AR_H ' ' -2 $BLACK
  case $scene in 0) amt=0.55 ;; 1|2|3) amt=0.28 ;; *) amt=0.16 ;; esac
  ar_at_stars $amt
  ar_at_box
  case $scene in
    0) ar_at_logo ;;
    1) ar_at_scores ;;
    2) ar_at_reel $at ;;
    3) ar_at_howto ;;
    *) ar_at_visitor ;;
  esac
  ar_wave $t 0.7; (( WV > 0.35 )) && { cmix $AMBER $WHITE 0.35; a_center 17 '◂ PRESS ANY KEY ▸' $CM -2; }
  ar_at_unbox
  return 0 }
ar_at_logo() {
  local -F t=$AR_T sweep d f; local -i bw x cx i; local line nxt name; local -a rows
  big_width ARCADE; bw=$BW; x=$(( (AR_W - bw) / 2 ))
  sweep=$(( t * 0.45 )); sweep=$(( (sweep - floor(sweep / 1.8) * 1.8) * (bw + 24) - 12 ))
  AR_BCOL=()
  for (( cx = 0; cx < bw; cx++ )); do
    f=$(( cx / (bw > 1 ? bw * 1.0 : 1.0) )); cmix $MAGENTA $CYAN $f
    d=$(( abs(cx - sweep) )); (( d < 6.0 )) && { f=$(( (1.0 - d / 6.0) ** 2 * 0.9 )); cmix $CM $WHITE $f; }
    AR_BCOL[$cx]=$CM
  done
  ar_big_cols ARCADE $x 3 $MAGENTA $BLACK
  ar_wave $t 0.2; cmix $PURPLE $CYAN $WV; cshade $CM 0.9
  a_center 9 '▁▂▃▄▅▆▇█  S Y N T H W A V E  S E R I E S  █▇▆▅▄▃▂▁' $CS -2
  cshade $GREY 1.1; a_center 11 "$AR_NG CLASSIC ARCADES · ONE TERMINAL" $CS -2
  line=''; rows=()
  for (( i = 0; i < AR_NG; i++ )); do
    name="${AR_GTITLE[$i]}"
    if [[ -n "$line" ]]; then nxt="$line  $name"; else nxt="$name"; fi
    if (( ${#nxt} > AR_W - 6 )) && [[ -n "$line" ]]; then rows+=("$line"); line="$name"; else line="$nxt"; fi
  done
  [[ -n "$line" ]] && rows+=("$line")
  for (( i = 0; i < ${#rows[@]} && i < 2; i++ )); do a_center $(( 13 + i )) "${rows[$i]}" $AR_LO -2; done
  ar_wave $t 0.9; (( WV > 0.4 )) && { cmix $AMBER $WHITE 0.25; a_center 15 'I N S E R T   C O I N' $CM -2; }
  return 0 }
ar_at_scores() {
  local -F t=$AR_T; local -i roll i gi y hot di=${AR_CF[difficulty]:-1} c; local s
  ar_wave $t 0.5; cmix $AMBER $WHITE $(( 0.3 * WV )); a_center 1 "◆  T O D A Y ' S   B E S T  ◆" $CM -2
  cshade $PURPLE 0.6; a_hline 10 2 $(( AR_W - 20 )) '─' $CS -2
  roll=$(( int(t / 7.0) % AR_NG ))
  for (( i = 0; i < 8 && i < AR_NG; i++ )); do
    gi=$(( (roll + i) % AR_NG )); ar_table $gi $di
    y=$(( 4 + i )); hot=$(( int(t * 1.4) % 8 == i ))
    if (( hot )); then c=$WHITE; else cshade $GREY 1.0; c=$CS; fi
    a_text 10 $y "${AR_GTITLE[$gi]}" $c -2
    ar_short "${AR_TN[0]:-AAA}" 12; cmix ${AR_GACC[$gi]} $WHITE 0.3; a_text 28 $y "$REPLY" $CM -2
    ar_commify ${AR_TS[0]:-0}; s="$REPLY"
    if (( hot )); then a_text $(( 52 - ${#s} )) $y "$s" $AMBER -2; a_put 54 $y '◂' $MAGENTA -2
    else cshade $AMBER 0.7; a_text $(( 52 - ${#s} )) $y "$s" $CS -2; fi
  done
  cmix $CYAN $WHITE 0.2; a_center 14 'CAN YOU BEAT THEM?' $CM -2
  return 0 }
ar_at_reel() {
  local -F t=$AR_T at=$1; local -i k gi bw x cx acc; local title
  k=$(( int((at - floor(at / 8.0) * 8.0) / 2.0) % AR_NG ))
  gi=$(( (int(at / 8.0) * 4 + k) % AR_NG )); acc=${AR_GACC[$gi]}
  title="${AR_GTITLE[$gi]}"; big_width "$title"; bw=$BW
  (( bw > AR_W - 2 )) && { title="${title%% *}"; big_width "$title"; bw=$BW; }
  x=$(( (AR_W - bw) / 2 ))
  AR_BCOL=(); for (( cx = 0; cx < bw; cx++ )); do ar_wave $t 0.6 $(( cx * 0.2 )); cmix $acc $WHITE $(( 0.25 * WV )); AR_BCOL[$cx]=$CM; done
  ar_big_cols "$title" $x 1 $acc $BLACK
  ar_stars ${AR_GSTARS[$gi]}; cmix $acc $WHITE 0.35; a_center 7 "${AR_GGENRE[$gi]} · ${AR_GYEAR[$gi]} · $REPLY" $CM -2
  ar_preview $gi 14 8 44 5
  ar_wrap "${AR_GBLURB[$gi]:u}" $(( AR_W - 8 )) 2
  cshade $GREY 1.05; a_center 14 "${AR_WL[0]}" $CS -2; a_center 15 "${AR_WL[1]}" $CS -2
  return 0 }
typeset -ga AR_HOWK AR_HOWD
AR_HOWK=('▲ ▼' '[ ↵ ]' '◆ ★' '[ H ]' '[ S ]' '[ T ]' '[ U ]' '[ M ]')
AR_HOWD=('move the joystick through the game list' 'press START on the highlighted arcade' \
         'eat to score, grab the gems, bank the coins' 'open the hall of fame' \
         'settings: sound, attract, free play, coin bank' 'claim the daily token when you are low on coins' \
         'mute the arcade' 'back to the menu -- and the house with it')
ar_at_howto() {
  local -F t=$AR_T; local -i i y hot; local k
  cmix $CYAN $WHITE 0.2; a_center 1 '◆  H O W   T O   P L A Y  ◆' $CM -2
  for (( i = 0; i < ${#AR_HOWK[@]}; i++ )); do
    y=$(( 4 + i )); hot=$(( int(t * 1.6) % ${#AR_HOWK[@]} == i )); k="${AR_HOWK[$i]}"
    ar_lpad "$k" 6
    if (( hot )); then cmix $MAGENTA $WHITE 0.4; a_text 14 $y "$REPLY" $CM -2; a_text 23 $y "${AR_HOWD[$i][0,$(( AR_W - 26 ))]}" $WHITE -2
    else cshade $MAGENTA 0.75; a_text 14 $y "$REPLY" $CS -2; cshade $GREY 1.0; a_text 23 $y "${AR_HOWD[$i][0,$(( AR_W - 26 ))]}" $CS -2; fi
  done
  a_center 13 'the arcade keeps your high scores between visits' $AR_LO -2
  return 0 }
(( ${+functions[ar_at_visitor]} )) || ar_at_visitor() { ar_at_howto; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 17 · THE CABINET AROUND THE CRT       what the glass carries besides the picture
# ══════════════════════════════════════════════════════════════════════════
typeset -gi AR_MIN_W=106 AR_MIN_H=30
ar_glass_crt() {   # → AR_W AR_H · all of the glass under the head band and over the key bar, a column spared each side
  AR_W=$(( SCR_W - 2 )); AR_H=$(( SCR_H - 4 )); return 0 }
ar_place() {   # the CRT this frame · the whole glass, or the board a round is being played on
  if [[ "$AR_VIEW" == play ]] && (( AR_RW )); then AR_W=$AR_RW; AR_H=$AR_RH; else ar_glass_crt; fi
  AR_FH=$(( AR_H - AR_FT ))
  AX=$(( (SCR_W - AR_W) / 2 )); (( AX < 0 )) && AX=0
  AY=$(( 2 + (SCR_H - 4 - AR_H) / 2 )); (( AY < 2 )) && AY=2
  ar_list_geom
  return 0 }
# THE GLASS, CLEARED A ROW AT A TIME · the door's v_fill builds its row a
# character at a time, every row, every frame -- four milliseconds on the float
# glass and twelve on a big fill.  A row of the CRT's ground is kept, and each
# glass row is one slice move into the grid.  That is only safe when the whole
# glass is on the terminal, which AR_DIRECT says; a pack's own direct writes
# (the previews, the light cycle's trails) ask it too.
typeset -gi AR_DIRECT=0
typeset -ga AR_CLR_CH AR_CLR_F AR_CLR_B; typeset -g AR_CLR_AT=''
ar_clear() {
  local -i y k w=$SCR_W i
  AR_DIRECT=$(( OX + C_SCR >= 0 && OY + R_SCR >= 0 && OX + C_SCR + SCR_W <= TCOLS && OY + R_SCR + SCR_H <= TROWS ))
  # A CABINET THAT BAKES A CLEARED GLASS (glass_bake) is handed the clear as
  # one fill of the whole glass, which it keeps in its still layer: the clear
  # then costs nothing a frame.  An older cabinet gets the moves below.
  if (( ${+functions[glass_baked]} )); then v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS; return 0; fi
  if (( ! AR_DIRECT )); then v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS; return 0; fi
  # a glass as wide as the terminal is one run of cells, top to bottom · one move
  (( OX + C_SCR == 0 && w == TCOLS )) && w=$(( SCR_W * SCR_H ))
  if [[ "$AR_CLR_AT" != "$w:$GREY:$GLASS" ]]; then
    AR_CLR_CH=(); AR_CLR_F=(); AR_CLR_B=()
    for (( i = 0; i < w; i++ )); do AR_CLR_CH+=(' '); AR_CLR_F+=($GREY); AR_CLR_B+=($GLASS); done
    AR_CLR_AT="$w:$GREY:$GLASS"
  fi
  if (( w > SCR_W )); then
    k=$(( (OY + R_SCR) * TCOLS ))
    GCH[$k,$(( k + w - 1 ))]=("${AR_CLR_CH[@]}"); GF[$k,$(( k + w - 1 ))]=("${AR_CLR_F[@]}"); GB[$k,$(( k + w - 1 ))]=("${AR_CLR_B[@]}")
    return 0
  fi
  for (( y = 0; y < SCR_H; y++ )); do
    k=$(( (OY + R_SCR + y) * TCOLS + OX + C_SCR ))
    GCH[$k,$(( k + w - 1 ))]=("${AR_CLR_CH[@]}"); GF[$k,$(( k + w - 1 ))]=("${AR_CLR_F[@]}"); GB[$k,$(( k + w - 1 ))]=("${AR_CLR_B[@]}")
  done
  return 0 }
ar_deal_board() {   # at the coin · the board this round is played on, held until the round is over
  ar_glass_crt
  (( AR_W > AR_GMAX_W )) && AR_W=$AR_GMAX_W; (( AR_H > AR_GMAX_H )) && AR_H=$AR_GMAX_H
  AR_RW=$AR_W; AR_RH=$AR_H; AR_FH=$(( AR_H - AR_FT ))
  AX=$(( (SCR_W - AR_W) / 2 )); (( AX < 0 )) && AX=0
  AY=$(( 2 + (SCR_H - 4 - AR_H) / 2 )); (( AY < 2 )) && AY=2
  return 0 }
ar_draw_toosmall() {   # ar_draw_toosmall [board] · the window, or the board in play, will not fit
  local -i y=$(( SCR_H / 2 - 2 ))
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  cmix $WHITE $CYAN 0.15; v_center $y 'THE WINDOW IS TOO SMALL' $CM $GLASS
  cshade $GREY 1.05; v_center $(( y + 2 )) "this one is ${TCOLS}x${TROWS}" $CS $GLASS
  if [[ "${1:-}" == board ]]; then
    v_center $(( y + 3 )) "the board in play is ${AR_RW}x${AR_RH} · the round is paused" $CS $GLASS
    v_center $(( y + 5 )) 'drag it back wider, or press [Q] to cash out' $AR_LO $GLASS
  else
    v_center $(( y + 3 )) "the cabinet needs ${AR_MIN_W}x${AR_MIN_H}" $CS $GLASS
    v_center $(( y + 5 )) 'drag it wider, or use a smaller font' $AR_LO $GLASS
  fi
  return 0 }
ar_font() {   # THE COMMA THE BIG SCORE NEEDS · the original's glyph, put into the
  # door's font if the door this pack met is older than the one that has it.
  local c=',' sp=' '
  [[ -n "${FONT5[$c]:-}" ]] || FONT5[$c]='..... ..... ..... ..#.. .#...'
  [[ -n "${FONT5[$sp]:-}" ]] || FONT5[$sp]='..... ..... ..... ..... .....'
  return 0 }
ar_head() {   # the house's own band · the brand, the bank, and what is in play
  local -i hb lb x; local s
  cmix $GLASS $PURPLE 0.32; hb=$CM
  cmix $GREY $PURPLE 0.30; cshade $CM 1.05; lb=$CS
  app_head ARCADE
  x=$APP_HX
  if ar_free; then s='FREE PLAY'; else ar_pad $(( ${AR[credits]:-0} > AR_MAX_COINS ? AR_MAX_COINS : ${AR[credits]:-0} )) 4; s="$REPLY"; fi
  v_text $x 0 'COINS' $lb $hb; v_text $(( x + 6 )) 0 "$s" $AMBER $hb; x=$(( x + 6 + ${#s} + 3 ))
  ar_commify ${AR[coins]:-0}; v_text $x 0 'EARNED' $lb $hb; v_text $(( x + 7 )) 0 "$REPLY" $LIME $hb; x=$(( x + 7 + ${#REPLY} + 3 ))
  case "$AR_VIEW" in
    play)   s="IN PLAY · ${AR_GTITLE[$AR_GI]} · ${AR_DN[$AR_DI]}" ;;
    diff)   s="${AR_GTITLE[$AR_GI]}" ;;
    scores) s='HIGH SCORES' ;;
    ranked|payout) s="${AR_GTITLE[$AR_GI]} · ${AR_DN[$AR_DI]}" ;;
    # NOT THE MAKER'S LINE · NX-88 SYNTHWAVE · ALIEN DYNAMICS 1984 is what the
    # bezel, its plate and the coin door say, and the band does not say it again
    *)      s='' ;;
  esac
  (( x + ${#s} < APP_HR )) && { cmix $CYAN $WHITE 0.25; v_text $x 0 "$s" $CM $hb; }
  return 0 }
ar_lamps() {   # the tube's four lamps, at the ends of the house's two rules · painted last
  # THE PICTURE IS THE GLASS NOW, so there is no bezel to hang them on: the
  # lamps sit where the head band's rule and the key bar's rule meet the glass,
  # breathing with the house.  The marquee's pop -- arcade.py boosted its whole
  # marquee by 1 + 1.1·|sin 18t| -- lights both rules in the arcade's violet
  # and whitens the lamps, the way the bezel used to carry it.
  local -i fg y; local -F boost=1.0
  (( AR_FLASH > 0.0 )) && boost=$(( 1.0 + 1.1 * abs(sin(AR_FLASH * 18.0)) ))
  if (( boost > 1.0 )); then
    cmix $ARC_LIT $MAGENTA 0.35; cshade $CM $boost; fg=$CS
    v_hline 0 1 $SCR_W '─' $fg; v_hline 0 $(( SCR_H - 2 )) $SCR_W '─' $fg
  fi
  ar_wave $AR_T 0.7; cmix $MAGENTA $WHITE $(( 0.2 + 0.3 * WV ))
  (( boost > 1.0 )) && { cshade $WHITE $(( 0.6 + 0.4 * (boost - 1.0) / 1.1 )); CM=$CS; }
  for y in 1 $(( SCR_H - 2 )); do v_put 0 $y '◆' $CM -2; v_put $(( SCR_W - 1 )) $y '◆' $CM -2; done
  return 0 }
ar_legend_nav() {   # the game's own legend on the house's key bar · "KEY LABEL  KEY LABEL" in, pairs out
  local s="$AR_G_LEGEND" c; local -a parts
  while [[ "$s" == *'   '* ]]; do s="${s//   /  }"; done
  parts=("${(@s:  :)s}")
  NAVK=(); NAVL=()
  for c in "${parts[@]}"; do
    c="${c## }"; c="${c%% }"; [[ -n "$c" ]] || continue
    if [[ "$c" == *' '* ]]; then NAVK+=("${c%% *}"); NAVL+=(" ${${c#* }:l}"); else NAVK+=("$c"); NAVL+=(''); fi
  done
  _app_nav; return 0 }
ar_hint_fit() {   # ar_hint_fit DROP… · NAVK/NAVL thinned, in the order given, until the bar fits at a roomy gap
  local d; local -i i w
  for d in "$@"; do
    w=0; for (( i = 0; i < ${#NAVK[@]}; i++ )); do w=$(( w + ${#NAVK[$i]} + ${#NAVL[$i]} )); done
    (( w + (${#NAVK[@]} - 1) * 3 <= SCR_W - 2 )) && break
    for (( i = 0; i < ${#NAVK[@]}; i++ )); do
      [[ "${NAVK[$i]}" == "$d" ]] && { NAVK[$i]=(); NAVL[$i]=(); break; }
    done
  done
  return 0 }
ar_nav() {   # the key bar · the legend for whatever is on the CRT, in the words arcade.py printed
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_nav]} )); then tc_nav 'wake the arcade'; return 0; fi
  case "$AR_VIEW" in
    menu)   if ar_attract_on; then app_nav '[any key]' 'wake the arcade'
            else
              # THE ONES WITH ANOTHER WAY IN ARE THE ONES THAT GO when they will not
              # all fit · scores has its own row, mute its own switch in the settings
              NAVK=('▴ ▾' '◂ ▸' '⏎'); NAVL=(' select' ' rooms' ' start')
              ar_daily_ready && { NAVK+=('[T]'); NAVL+=(' daily'); }
              NAVK+=('[B]' '[A]' '[L]' '[H]' '[S]' '[U]' '[⎋]')
              NAVL+=(' market' ' trophies' ' ledger' ' scores' ' settings' ' mute' ' menu')
              ar_hint_fit '[H]' '[U]' '[L]' '[A]' '[S]'
              _app_nav
            fi ;;
    diff)   if [[ "${AR_GPLAYERS[$AR_GI]}" == 1-2P ]]; then app_nav '▴ ▾' choose '⏎' 'one player' '[2]' 'two up' '[⎋]' back
            else app_nav '▴ ▾' choose '⏎' 'insert coin & play' '[⎋]' back; fi ;;
    play)   if (( AR_RS == 3 )); then app_nav '⏎' 'play again · 1 coin' '[Q]' 'cash out'
            else ar_legend_nav; fi ;;
    ranked) app_nav '[any key]' continue ;;
    payout) app_nav '[any key]' 'back to the arcade' ;;
    scores) app_nav '◂ ▸' arcade '▴ ▾' difficulty '⏎ ⎋' 'back to games' '[M]' menu ;;
    soon)   app_nav '[any key]' 'back to the menu' ;;
    market) ar_mk_cats
            NAVK=('▴ ▾' '◂ ▸' '⏎'); NAVL=(' browse' ' rack')
            if [[ "${AR_MK_KEYS[$AR_MK_CAT]}" == games ]]; then NAVL+=(' buy or rent'); else NAVL+=(' buy · wear'); fi
            [[ "${AR_MK_KEYS[$AR_MK_CAT]}" != games ]] && ar_vn_full_set && { NAVK+=('[R]'); NAVL+=(' surprise me'); }
            NAVK+=('[⎋]' '[M]'); NAVL+=(' back' ' menu')
            ar_hint_fit '◂ ▸'; _app_nav ;;
    buy)      app_nav '▴ ▾' choose '⏎' pay '[⎋]' back ;;
    confirm)  app_nav '[Y]' "${AR_CF_YES:l}" '[N]' "${AR_CF_NO:l}" ;;
    daily)    app_nav '⏎' collect '[⎋]' 'not now' ;;
    badges)   app_nav '▴ ▾' browse '◂ ▸' shelf '[⎋]' back '[M]' menu ;;
    ledger)   app_nav '⏎ ⎋' 'back to games' '[M]' menu ;;
    options)  app_nav '▴ ▾' select '⏎' change '[⎋]' back '[M]' menu ;;
    selftest) app_nav '[any key]' 'exit self test' ;;
    keypad)   app_nav '[0-9]' 'enter serial' '[⌫]' back '[⎋]' 'shut the door' ;;
    service)  app_nav '▴ ▾' pick '◂ ▸' change '⏎' run '[⎋]' 'close the door' ;;
    *)        app_nav '[⎋]' menu ;;
  esac
  return 0 }

# ══════════════════════════════════════════════════════════════════════════
# SECTION 18 · THE HOOKS          what terminal.command asks of a machine
# ══════════════════════════════════════════════════════════════════════════
# STARTED IS NOT OPENED.  The pack can be started at power-on, behind the
# loading screen (terminal.command, SECTION 22b): that is the palette and the
# font and nothing a reader could tell from not having happened.  The conf,
# the save, the boot and the visit it counts, the badges it checks and the
# daily token it may offer are the OPENING's -- ar_first, the door's
# PACK_FIRST, run on the first open whichever way the pack was started.
ar_init() {   # the pack started · the palette and the font
  ar_palette
  ar_font
  ar_rar_inks
  return 0 }
ar_first() {   # called on open · the conf, the save, and one more boot
  ar_conf_load
  ar_save_load
  AR[boots]=$(( ${AR[boots]:-0} + 1 )); AR[visits]=$(( ${AR[visits]:-0} + 1 )); AR_DIRTY=1
  local -i i; AR_NOPEN=0
  for (( i = 0; i < AR_NG; i++ )); do ar_playable $i && AR_NOPEN=$(( AR_NOPEN + 1 )); done
  AR_VIEW=menu; AR_SEL=$AR_FIRST; AR_SCROLL=0; AR_KEYS=()
  AR_LAST=-1.0; AR_IDLE_T=0.0; AR_ROOM=-1; AR_TQ=(); ar_hold_reset
  ar_rar_inks
  [[ -n "${AR[badges.secret_svc]:-}" ]] && AR_SVC_FOUND=1
  [[ -n "${AR[badges.secret_konami]:-}" ]] && AR_KONAMI=1
  (( ${+functions[ar_vn_init]} )) && ar_vn_init
  ar_run_clear; ar_badges_check                 # a badge for a thousand coins should not wait for a round
  ar_daily_ready && ar_open_daily               # arcade.py offered the token before the menu, when it was due
  ar_save_write
  return 0 }
ar_tick() {   # ar_tick T — the beat
  AR_T=$1
  if (( AR_LAST < 0.0 )); then AR_DT=0.016; else AR_DT=$(( AR_T - AR_LAST )); fi
  (( AR_DT < 0.001 )) && AR_DT=0.001; (( AR_DT > 0.25 )) && AR_DT=0.25
  AR_LAST=$AR_T
  AR_FPS=$(( AR_FPS > 0.0 ? AR_FPS * 0.9 + 0.1 / AR_DT : 1.0 / AR_DT ))    # the rate the frames are really arriving at, smoothed
  (( AR_FLASH > 0.0 )) && { AR_FLASH=$(( AR_FLASH - AR_DT )); (( AR_FLASH < 0.0 )) && AR_FLASH=0.0; }
  if [[ "$AR_VIEW" == play ]]; then ar_round_tick
  elif [[ "$AR_VIEW" == menu ]]; then
    ar_hold_len; (( RF >= AR_HOLD_NEED )) && { ar_hold_reset; ar_open_keypad; }
  fi
  AR_KEYS=()
  ar_badge
  return 0 }
# ══════════════════════════════════════════════════════════════════════════
# THE TITLE CARD · the arcade's face, at its door (terminal.command's tc_*)
# ══════════════════════════════════════════════════════════════════════════
# THE NAME IN LIGHTS, AND UNDER IT THE CABINET WALL: the twelve machines in
# two banks of six either side of a screen, and on the screen one of them
# playing itself -- its own preview, the one the menu shows -- the screen
# changing channel to the next machine every few seconds and the bank
# lighting the one it is showing.  Under it the figures the house keeps and
# the arcade's own call, and ◂ PRESS ANY KEY ▸.  The same four answers as
# every card (tc_key), and the same order coming up: the name strikes, the
# line under it fades up, the screen comes on and the banks type themselves
# in, the figures, the call.  (The reel this card used to be -- logo, today's
# best, a machine at a time, how to play -- is still the arcade's own attract
# mode, after twenty idle seconds on its menu.)
typeset -gi AR_TC_OY=0 AR_TC_CH=6 AR_TC_CW=96 AR_TC_SX=0 AR_TC_SY=0
typeset -gi AR_TC_PL=0 AR_TC_PW=0 AR_TC_LX=0 AR_TC_RX=0 AR_TC_R0=0 AR_TC_G0=0 AR_TC_STC=0
typeset -g  AR_TC_ST='' AR_TCKEY=''
typeset -gF AR_TC_ON=0.62 AR_TC_EACH=4.6       # the screen comes on · and shows each machine this long
typeset -gA AR_TC_INK                          # the card's inks, worked out once
ar_tc_key() {   # ar_tc_key -> AR_TCKEY · everything the still part is a picture of
  local -i i
  AR_TCKEY="ar|${AR[credits]:-0}|${AR[coins]:-0}|${AR_CF[freeplay]:-0}|${AR[svc.free]:-0}|${AR_CF[difficulty]:-1}|$AR_SEL|${AR[daily]:-}"
  for (( i = 0; i < AR_NG; i++ )); do ar_playable $i && AR_TCKEY+="|$i"; done
  ar_nkeys 'badges.*'; AR_TCKEY+="|b$REPLY"
  ar_nkeys 'plays.*'; AR_TCKEY+="|p$REPLY"
  return 0
}
ar_tc_row() {   # ar_tc_row I -> X Y of machine I's line in its bank (glass cells)
  if (( $1 < 6 )); then RX=$AR_TC_LX; else RX=$AR_TC_RX; fi
  RY=$(( AR_TC_R0 + $1 % 6 ))
  return 0
}
typeset -gi RX=0 RY=0
ar_title_base() {   # the card's still part, painted once per reading of the house and kept (tc_card)
  local -i oy cw ch sx sy i x y n plays=0 di c lk nk vk
  local s k
  tc_base ARCADE
  ar_head                                       # the house's band · the bank, as on every page of it
  # a taller glass, a taller wall; a wider one, a wider screen
  ch=6; (( TC_H >= 34 )) && ch=8; (( TC_H >= 40 )) && ch=10
  # the screen no wider than six of its rows (the previews are drawn for a
  # screen about that shape -- the menu's, the difficulty page's), and the
  # wall as wide as a bank, the screen and a bank make it
  cw=$(( TC_W - 20 )); (( cw > 39 + 6 * ch )) && cw=$(( 39 + 6 * ch ))
  oy=$(( (TC_H - (ch + 19)) / 2 )); (( oy < 0 )) && oy=0
  tc_big ARCADE $(( oy + 1 )) $MAGENTA $CYAN
  cshade $GREY 1.05; tc_center $(( oy + 8 )) "$AR_NG classic arcades  ·  one terminal" $CS
  tc_reveal $TC_CX $(( TC_Y0 + oy + 8 )) $TC_CW 0.58 0.26
  # ── the wall · a bank of six, the screen, a bank of six ──
  sx=$(( TC_X0 + (TC_W - cw - 2) / 2 )); sy=$(( TC_Y0 + oy + 10 ))
  cshade $PURPLE 0.42; c=$CS
  v_box $sx $sy $(( cw + 2 )) $(( ch + 2 )) $c $BLACK round
  tc_quiet $sx $sy $(( cw + 2 )) $(( ch + 2 ))
  AR_TC_LX=$(( sx + 3 )); AR_TC_RX=$(( sx + cw - 15 ))
  AR_TC_PL=$(( AR_TC_LX + 18 )); AR_TC_PW=$(( AR_TC_RX - 3 - AR_TC_PL ))
  AR_TC_R0=$(( sy + 1 + (ch - 6) / 2 ))
  # the screen set into the wall · its own bezel, joined to the wall's
  for x in $(( AR_TC_PL - 1 )) $(( AR_TC_PL + AR_TC_PW )); do
    v_put $x $sy '┬' $c $BLACK; v_put $x $(( sy + ch + 1 )) '┴' $c $BLACK
    for (( y = sy + 1; y <= sy + ch; y++ )); do v_put $x $y '│' $c $BLACK; done
  done
  (( AR_PVBG )) || { _pack 12 6 26; AR_PVBG=$PK; }
  v_fill $AR_TC_PL $(( sy + 1 )) $AR_TC_PW $ch ' ' $GREY $AR_PVBG
  s=' NOW SHOWING '; v_text $(( AR_TC_PL + (AR_TC_PW - ${#s}) / 2 )) $sy "$s" $AMBER $BLACK
  # THE BANKS · a machine you can play brighter than one still in the
  # market, each typing itself in a beat after the screen comes on
  cshade $PURPLE 0.75; nk=$CS; cshade $GREY 1.05; lk=$CS; cshade $GREY 0.62; vk=$CS
  for (( i = 0; i < AR_NG && i < 12; i++ )); do
    ar_tc_row $i
    printf -v s '%02d' $(( i + 1 ))
    v_text $RX $RY "$s" $nk
    if ar_playable $i; then v_text $(( RX + 4 )) $RY "${AR_GTITLE[$i]}" $lk; else v_text $(( RX + 4 )) $RY "${AR_GTITLE[$i]}" $vk; fi
    tc_reveal $RX $RY 15 $(( AR_TC_ON + 0.08 + (i % 6) * 0.05 + (i / 6) * 0.03 )) 0.16
  done
  # the machine the screen starts on · the one the menu was left on, if it was left on one
  ar_item $AR_SEL; if [[ $REPLY == g ]]; then AR_TC_G0=$AR_IG; else AR_TC_G0=0; fi
  # ── the figures the house keeps, under the wall end to end ──
  ar_count_open
  for k in ${(M)${(k)AR[@]}:#plays.*}; do plays=$(( plays + ${AR[$k]:-0} )); done
  ar_nkeys 'badges.*'; n=$REPLY
  di=${AR_CF[difficulty]:-1}
  TC_MJX=$sx; TC_MJW=$(( cw + 2 ))
  tc_figs $(( oy + ch + 13 )) UNLOCKED "$AR_NOPEN OF $AR_NG" TROPHIES "$n OF ${#BW_ID[@]}" ROUNDS "$plays" RUNG "${AR_DN[$di]:-NORMAL}"
  tc_reveal $TC_FX $(( TC_Y0 + oy + ch + 13 )) $TC_FW 1.02 0.30
  # ── the arcade's own call ──
  if ar_free;                         then AR_TC_ST='FREE PLAY'; AR_TC_STC=$CYAN
  elif ar_daily_ready;                then AR_TC_ST='A DAILY TOKEN IS WAITING'; AR_TC_STC=$AMBER
  elif (( ${AR[credits]:-0} <= 0 ));  then AR_TC_ST='OUT OF COINS'; AR_TC_STC=$AMBER
  else                                     AR_TC_ST='INSERT COIN'; AR_TC_STC=$LIME; fi
  tc_nav 'wake the arcade'
  AR_TC_OY=$oy; AR_TC_CH=$ch; AR_TC_CW=$cw; AR_TC_SX=$sx; AR_TC_SY=$sy
  return 0
}
ar_title() {   # ar_title T — the card: the still part kept, and the screen, the bank's light and the type live over it
  local -F t=$1 u p f
  local -i gi acc i k y x c w0 w1 py0 py1 hy ph base sw=$AR_W sh=$AR_H sax=$AX say=$AY
  local s
  # THE CARD IS DRAWN ON THE GLASS, whatever board a round left the arcade's
  # CRT at · the previews are placed in the arcade's own CRT, so it is the glass's for the length of the card
  ar_glass_crt
  AX=$(( (SCR_W - AR_W) / 2 )); (( AX < 0 )) && AX=0
  AY=$(( 2 + (SCR_H - 4 - AR_H) / 2 )); (( AY < 2 )) && AY=2
  AR_DIRECT=$(( OX + C_SCR >= 0 && OY + R_SCR >= 0 && OX + C_SCR + SCR_W <= TCOLS && OY + R_SCR + SCR_H <= TROWS ))
  ar_tc_key
  tc_card "$AR_TCKEY" ar_title_base $t
  tc_spaced $(( AR_TC_OY + 7 )) 'SYNTHWAVE SERIES' $PURPLE $CYAN $t 0.42
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  ph=$AR_TC_CH; py0=$(( AR_TC_SY + 1 ))
  # WHICH MACHINE IS ON · a channel each AR_TC_EACH seconds from the one it started on
  u=$(( TC_NOW - AR_TC_ON )); (( u < 0.0 )) && u=0.0
  gi=$(( (AR_TC_G0 + int(u / AR_TC_EACH)) % AR_NG )); acc=${AR_GACC[$gi]}
  f=$(( u - floor(u / AR_TC_EACH) * AR_TC_EACH ))          # how long this channel has been on
  if (( TC_NOW >= AR_TC_ON )); then
    ar_preview $gi $(( AR_TC_PL - AX )) $(( py0 - AY )) $AR_TC_PW $ph
    # THE SCREEN COMING ON, the first time · a line across the middle that
    # opens into the picture, the way a tube warms
    tc_in $AR_TC_ON 0.34; p=$TCP
    c=${AR_TC_INK[line]:-0}; (( c )) || { cmix $CYAN $WHITE 0.55; c=$CM; AR_TC_INK[line]=$c }
    if (( p < 1.0 )); then
      hy=$(( py0 + (ph - 1) / 2 ))
      if (( p < 0.45 )); then
        w1=$(( int(AR_TC_PW * p / 0.45) )); w0=$(( (AR_TC_PW - w1) / 2 ))
        for (( y = py0; y < py0 + ph; y++ )); do
          k=$(( base + y * TCOLS + AR_TC_PL ))
          for (( x = 0; x < AR_TC_PW; x++ )); do
            GCH[$(( k + x ))]=' '
            if (( y == hy && x >= w0 && x < w0 + w1 )); then GB[$(( k + x ))]=$c; else GB[$(( k + x ))]=$AR_PVBG; fi
          done
        done
      else
        i=$(( int((p - 0.45) / 0.55 * (ph / 2.0 + 1.0)) ))   # rows open either side of the middle
        for (( y = py0; y < py0 + ph; y++ )); do
          (( y >= hy - i && y <= hy + i + (ph % 2 ? 0 : 1) )) && continue
          k=$(( base + y * TCOLS + AR_TC_PL ))
          for (( x = 0; x < AR_TC_PW; x++ )); do GCH[$(( k + x ))]=' '; GB[$(( k + x ))]=$AR_PVBG; done
        done
      fi
    elif (( u >= AR_TC_EACH && f < 0.20 )); then
      # A CHANNEL CHANGING · a flicker of snow across the screen, then the next machine
      for (( y = py0; y < py0 + ph; y++ )); do
        k=$(( base + y * TCOLS + AR_TC_PL ))
        for (( x = 0; x < AR_TC_PW; x++ )); do
          # a cell's snow, hashed from where it is and which frame this is
          i=$(( (x * 374761393 + y * 668265263 + int(TC_NOW * 30.0) * 2246822519) & 0xFFFFFFFF ))
          i=$(( ((i ^ (i >> 13)) * 1274126177) & 0xFFFFFFFF )); i=$(( (i ^ (i >> 16)) % 100 ))
          if (( i < 14 )); then GCH[$(( k + x ))]='▒'; elif (( i < 38 )); then GCH[$(( k + x ))]='░'; else GCH[$(( k + x ))]=' '; fi
          GF[$(( k + x ))]=$GREY; GB[$(( k + x ))]=$AR_PVBG
        done
      done
    fi
    # THE BANK LIGHTS THE ONE ON SCREEN, once the banks are in · and the
    # wall's foot says what it is
    if (( TC_NOW >= AR_TC_ON + 0.50 )); then
      ar_tc_row $gi
      c=${AR_TC_INK[hi:$acc]:-0}; (( c )) || { cmix $acc $WHITE 0.30; c=$CM; AR_TC_INK[hi:$acc]=$c }
      v_put $(( RX - 2 )) $RY '▸' $acc
      printf -v s '%02d' $(( gi + 1 )); v_text $RX $RY "$s" $acc
      v_text $(( RX + 4 )) $RY "${AR_GTITLE[$gi]}" $c
      s=" ${AR_GTITLE[$gi]} · ${AR_GGENRE[$gi]} · ${AR_GYEAR[$gi]} "
      (( ${#s} <= AR_TC_PW )) && v_text $(( AR_TC_PL + (AR_TC_PW - ${#s}) / 2 )) $(( AR_TC_SY + ph + 1 )) "$s" $c $BLACK
    fi
  fi
  tc_status $(( AR_TC_OY + AR_TC_CH + 15 )) "$AR_TC_ST" $AR_TC_STC $t 1.28
  tc_prompt $(( AR_TC_OY + AR_TC_CH + 17 )) $t '' 1.55
  AR_W=$sw; AR_H=$sh; AX=$sax; AY=$say
  return 0
}

ar_draw() {   # ar_draw T — the picture
  AR_T=$1
  PACK_FILL=1
  if (( SCR_W > TCOLS || SCR_H > TROWS )); then ar_draw_toosmall; return 0; fi
  # THE TITLE CARD, while the door has it up (tc_*, terminal.command) · on
  # the glass, before anything clears it: its still part is the door's to lay
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_card]} )); then
    AR_TOAST_FLOOR=0
    ar_title $1
    ar_toast_paint; ar_lamps
    return 0
  fi
  ar_place
  if (( SCR_W < AR_W + 2 || SCR_H < AR_H + 4 )); then   # only a round's board can outgrow the glass
    (( AR_RS == 1 )) && AR_PAUSED=1
    ar_draw_toosmall board; app_nav '[Q]' 'cash out'; return 0
  fi
  ar_clear
  ar_head
  AR_TOAST_FLOOR=0                                      # a page with a headline sets it while it draws
  case "$AR_VIEW" in
    menu)     if ar_attract_on; then ar_draw_attract; else ar_draw_menu; fi ;;
    diff)     ar_draw_diff ;;
    play)     ar_round_draw ;;
    ranked)   ar_draw_ranked ;;
    payout)   ar_draw_payout ;;
    scores)   ar_draw_scores ;;
    soon)     ar_draw_soon ;;
    market)   ar_draw_market ;;
    buy)      ar_draw_buy ;;
    confirm)  ar_draw_confirm ;;
    daily)    ar_draw_daily ;;
    badges)   ar_draw_badges ;;
    ledger)   ar_draw_ledger ;;
    options)  ar_draw_options ;;
    selftest) ar_draw_selftest ;;
    keypad)   ar_draw_keypad ;;
    service)  ar_draw_service ;;
    *)        ar_draw_menu ;;
  esac
  case "$AR_VIEW" in ledger|scores) a_power $(( 0.4 + (AR_T - AR_VIEW_T0) * 4.0 )) ;; esac
  ar_toast_paint
  ar_nav
  ar_lamps
  return 0 }
ar_key() {   # ar_key KEY → 0 handled · 1 the door's
  [[ "$1" == ' ' ]] && set -- space        # the door hands a space over as itself
  # THE TITLE CARD ANSWERS FIRST: its keys are the door's, on every machine ·
  # and walking in starts the reel's twenty idle seconds again from here
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_key]} )); then
    tc_key "$1"; local -i _rc=$?
    AR_IDLE_T=$AR_T
    return $_rc
  fi
  if [[ "$AR_VIEW" == menu ]] && ar_attract_on; then AR_IDLE_T=$AR_T; return 0; fi   # the first key only wakes the arcade
  AR_IDLE_T=$AR_T
  case "$AR_VIEW" in
    market)   ar_market_key "$1"; return $? ;;
    buy)      ar_buy_key "$1"; return $? ;;
    confirm)  ar_confirm_key "$1"; return 0 ;;
    daily)    ar_daily_key "$1"; return $? ;;
    badges)   ar_badges_key "$1"; return $? ;;
    ledger)   ar_ledger_key "$1"; return $? ;;
    options)  ar_options_key "$1"; return $? ;;
    selftest) ar_selftest_key "$1"; return 0 ;;
    keypad)   ar_keypad_key "$1"; return 0 ;;
    service)  ar_service_key "$1"; return 0 ;;
  esac
  case "$AR_VIEW" in
    menu)   ar_menu_key "$1"; return $? ;;
    diff)   ar_diff_key "$1"; return $? ;;
    play)   # a named key reaching a round means the raw hook was not asked · answer it anyway
            case "$1" in
              up) AR_KEYS+=(UP) ;; down) AR_KEYS+=(DOWN) ;; left) AR_KEYS+=(LEFT) ;; right) AR_KEYS+=(RIGHT) ;;
              enter) AR_KEYS+=(ENTER) ;; esc) AR_KEYS+=(ESC) ;; space|' ') AR_KEYS+=(SPACE) ;;
              [A-Za-z0-9]) AR_KEYS+=("${1:u}") ;;
            esac
            return 0 ;;
    ranked) ar_ranked_key; return 0 ;;
    payout) ar_payout_key; return 0 ;;
    scores) ar_scores_key "$1"; return $? ;;
    soon)   ar_soon_key; return 0 ;;
  esac
  return 1 }
ar_badge() {   # the coin door's badge · what is in the bank
  if ar_free; then SURF_BADGE=' FREE PLAY '; else SURF_BADGE=" COINS ${AR[credits]:-0} "; fi
  return 0 }
ar_dress() {   # the cabinet's chrome, the NX-88's own
  SURF_MODEL='NX-88'
  SURF_SIGN='◂ A R C A D E ▸'
  SURF_TAG='ALIEN DYNAMICS · MODEL NX-88'
  SURF_KEYS='[▲▼]SELECT   [◂▸]ROOMS   [⏎]START   [B]MARKET   [H]SCORES   [S]SETTINGS   [⎋]BACK'
  (( ${SURF_TITLE:-0} )) && SURF_KEYS="${TC_KEYS:-$SURF_KEYS}"
  ar_badge
  SURF_MSG="${AR_NG:-12} CABINETS · ONE COIN A GAME"
  return 0 }
ar_leave() { (( AR_DIRTY )) && ar_save_write; return 0 }

# ══════════════════════════════════════════════════════════════════════════
# THE PACK · what terminal.command asks of a machine, and nothing more
# ══════════════════════════════════════════════════════════════════════════
PACK_NAME='ARCADE'
PACK_MODEL='NX-88'
PACK_INIT='ar_init'
PACK_FIRST='ar_first'
PACK_TICK='ar_tick'
PACK_DRAW='ar_draw'
PACK_KEY='ar_key'
PACK_RAW='ar_raw'
PACK_DRESS='ar_dress'
PACK_LEAVE='ar_leave'
