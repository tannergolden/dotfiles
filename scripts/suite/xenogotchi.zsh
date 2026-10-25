#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════
# scripts/suite/xenogotchi.zsh · THE ADOPTION CENTRE, on TERMINAL's own glass
# ══════════════════════════════════════════════════════════════════════════
# MODEL XG-9.  system's companion unit: where SYSTEM watches the machine, this
# one keeps an ANIMAL in it.  You adopt, name it, and after that it simply
# lives there on the real clock -- fed, watered, groomed or neglected -- its
# behaviour chosen frame by frame from a running emotional state, lit like the
# whole suite by one sun hanging top-right.  Ported from the OLD cabinet's
# xenogotchi.py (10,336 lines) into a page pack the door sources.
#
# ── THE PACK CONTRACT ─────────────────────────────────────────────────────
# The cabinet keeps the walls, the beat, the governor and the tube; this file
# hands it a handful of functions and draws inside the rectangle it is given.
# It NEVER writes to the terminal itself.  The primitives (v_text, v_put,
# v_box, v_fill, cmix, cshade, _pack, app_head, app_nav, mo_ease, xf_arm) are
# the cabinet's; the pages below are this pack's own furniture.
#
# ── THE ROOM FILLS · THE SPRITE DOES NOT ──────────────────────────────────
# Like SYSTEM and INTELLIGENCE, the room and its furniture -- the walls, the
# porthole, the floor, the panels -- reach the edges of whatever glass they are
# given (PACK_FILL=1).  The ANIMAL is the exception: it is pixel art, and pixel
# art stretched is pixel art ruined, so the sprite is composed at one fixed
# cell size and simply stands somewhere in the larger room.  Fill the stage,
# not the actor.
#
# ── STAGE 1 · the playable core ───────────────────────────────────────────
# Building outward from one species (the cat), end to end -- adopt, a living
# HOME, the care keys, STATS and STORE, the save on the real clock -- then the
# other fourteen shipments and ALBUM/CRYO/vet in the passes after this.

# ── the seam · sourced by the door, or run on its own to be looked at ──────
if [[ -z "${PACK_SOURCED:-}" ]] && [[ "${ZSH_EVAL_CONTEXT:-toplevel}" != *:file* ]]; then
  print -r -- 'xenogotchi.zsh is a page pack for terminal.command.'
  print -r -- 'Open TERMINAL and choose XENOGOTCHI from the menu.'
  exit 0
fi

typeset -gi XG_MOCK=0
[[ -n "${XENOGOTCHI_MOCK:-}${TERMINAL_MOCK:-}" ]] && XG_MOCK=1

# ══════════════════════════════════════════════════════════════════════════
# THE PALETTE · warm where the suite is cool · the room is a lit place
# ══════════════════════════════════════════════════════════════════════════
typeset -gi XG_FG XG_LBL XG_DIM XG_WHITE XG_WARM XG_COOL XG_OK XG_WARN
xg_palette() {
  XG_FG=$AMBER          # the machine's own ink
  XG_LBL=$GREY
  XG_DIM=$DIM
  XG_WHITE=$WHITE
  cmix $AMBER $RED 0.30;    XG_WARM=$CM      # the coin-door glow
  cmix $CYAN  $PURPLE 0.35; XG_COOL=$CM      # the porthole night
  XG_OK=$LIME
  XG_WARN=$AMBER
  return 0
}

# ── THE INK · every word in this machine is read off the glass, and the glass is
#    very nearly black.  Anything under about GREY×0.75 sinks into it and the
#    page goes unreadable in a lit room, so the PACK keeps ONE ramp and a
#    floor, rather than a shade guessed at each call site:
#      XI_HI    a thing's name, the figures you scan for
#      XI_TX    sentences, values, the house list
#      XI_LO    second lines and asides · the floor, ~3:1 on the glass
#      XI_TRK   an empty bar's track · a shape, not a word
#      XI_RULE  hairlines and rules · never words
#    DIM stays what DIM is for: the rules. It is too dark to letter with.
#
#    AND TWO FOR THE DECK.  The room is not the glass: the hull's deck under
#    the window is a LIT TEAL, up around rgb(36,112,104), and the ramp above
#    is measured against rgb(8,4,20).  The room's status line was written in
#    XI_TX's neighbourhood straight onto that teal and came out at 1.22:1 --
#    the same violet-grey on a mid-tone ground, which is to say nothing at
#    all.  Going DOWN from a mid-tone tops out near 3.6:1, so these go up.
#      XI_DECK  the line you read · 4.7:1 on the brightest deck cell
#      XI_DECKD its bullets and asides · 3.6:1 on the same
typeset -gi XI_HI=0 XI_TX=0 XI_LO=0 XI_TRK=0 XI_RULE=0 XI_DECK=0 XI_DECKD=0
xg_ink() {
  cmix $GREY $WHITE 0.32; XI_HI=$CM
  XI_TX=$GREY
  cshade $GREY 0.78; XI_LO=$CS
  cshade $GREY 0.50; XI_TRK=$CS
  cshade $DIM  0.85; XI_RULE=$CS
  cmix $GREY $WHITE 0.78; XI_DECK=$CM
  cmix $GREY $WHITE 0.58; XI_DECKD=$CM
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE SPRITE PIPELINE · the OLD Px → lit RGB → cell art, ported cell for cell
# ══════════════════════════════════════════════════════════════════════════
# A sprite is built as a MATERIAL grid (numbers, not letters, so the neighbour
# tests below are arithmetic): 1 b · 2 d · 3 w · 4 o · 5 e · 6 E · 7 k · 8 s ·
# 9 p · 10 n · 11 x.  render() lights every body pixel from the suite's one sun
# (top-right), features get a flatter shading, and render_cells folds two pixel
# rows into one painted background cell -- the wall's own technique, seamless on
# any font.  It is dear (per pixel), so a pose is rendered ONCE and the cells
# cached; the room blits the cache every frame.  ~30 ms a render, measured.
typeset -ga XG_PR XG_PG XG_PB          # the palette · r,g,b per material 1..11
typeset -ga XG_XPM                     # the material grid
typeset -gi XG_XPW=0 XG_XPH=0
typeset -ga XG_MR XG_MG XG_MB XG_MA    # rendered pixel r,g,b and painted-flag
typeset -ga XG_CC XG_CA                # cached cells · packed colour, alpha%
typeset -gi XG_CCW=0 XG_CCH=0
typeset -g  XG_CACHE_KEY=''            # what the cache currently holds

xg_px_new() { XG_XPW=$1; XG_XPH=$2; XG_XPM=(); local -i i n=$(( XG_XPW*XG_XPH )); for (( i=0;i<n;i++ )); do XG_XPM[$i]=0; done }
xg_set()    { (( $1>=0 && $1<XG_XPW && $2>=0 && $2<XG_XPH )) && XG_XPM[$(( $2*XG_XPW+$1 ))]=$3 }
xg_disk() { # cx cy rx ry m [only]
  local -F cx=$1 cy=$2 rx=$3 ry=$4 ddx ddy; local -i m=$5 x y cur; local only="${6:-}"
  local -F rxa=$(( rx<0.001?0.001:rx )) rya=$(( ry<0.001?0.001:ry ))
  local -i x0=$(( int(cx-rx-1) )) x1=$(( int(cx+rx+2) )) y0=$(( int(cy-ry-1) )) y1=$(( int(cy+ry+2) ))
  for (( y=y0;y<y1;y++ )); do for (( x=x0;x<x1;x++ )); do
    ddx=$(( (x-cx)/rxa )); ddy=$(( (y-cy)/rya )); (( ddx*ddx+ddy*ddy <= 1.0 )) || continue
    (( x<0||x>=XG_XPW||y<0||y>=XG_XPH )) && continue
    if [[ -n "$only" ]]; then cur=${XG_XPM[$(( y*XG_XPW+x ))]}; [[ " $only " == *" $cur "* ]] || continue; fi
    XG_XPM[$(( y*XG_XPW+x ))]=$m
  done; done
}
xg_tri() { # p1x p1y p2x p2y p3x p3y m [only]
  local -F ax=$1 ay=$2 bx=$3 by=$4 cx=$5 cy=$6 d1 d2 d3; local -i m=$7 x y cur neg pos; local only="${8:-}"
  local -i x0=$(( int(ax<bx?(ax<cx?ax:cx):(bx<cx?bx:cx)) )) x1=$(( int(ax>bx?(ax>cx?ax:cx):(bx>cx?bx:cx))+1 ))
  local -i y0=$(( int(ay<by?(ay<cy?ay:cy):(by<cy?by:cy)) )) y1=$(( int(ay>by?(ay>cy?ay:cy):(by>cy?by:cy))+1 ))
  for (( y=y0;y<y1;y++ )); do for (( x=x0;x<x1;x++ )); do
    d1=$(( (x-bx)*(ay-by)-(ax-bx)*(y-by) )); d2=$(( (x-cx)*(by-cy)-(bx-cx)*(y-cy) )); d3=$(( (x-ax)*(cy-ay)-(cx-ax)*(y-ay) ))
    neg=$(( d1<0||d2<0||d3<0 )); pos=$(( d1>0||d2>0||d3>0 )); (( neg&&pos )) && continue
    (( x<0||x>=XG_XPW||y<0||y>=XG_XPH )) && continue
    if [[ -n "$only" ]]; then cur=${XG_XPM[$(( y*XG_XPW+x ))]}; [[ " $only " == *" $cur "* ]] || continue; fi
    XG_XPM[$(( y*XG_XPW+x ))]=$m
  done; done
}
xg_seg() { # x0 y0 x1 y1 r m [only] — one stroked segment
  local -F x0=$1 y0=$2 x1=$3 y1=$4 r=$5 t; local -i m=$6 k n; local only="${7:-}"
  n=$(( int((abs(x1-x0)>abs(y1-y0)?abs(x1-x0):abs(y1-y0))*2)+1 ))
  for (( k=0;k<=n;k++ )); do t=$(( k/(n+0.0) )); xg_disk $(( x0+(x1-x0)*t )) $(( y0+(y1-y0)*t )) $r $r $m "$only"; done
}
xg_whrow() { local -F x0=$1 row=$2; local -i side=$3 ln=$4 i; for (( i=0;i<ln;i++ )); do xg_set $(( int(x0+side*(i+1)) )) $(( int(row) )) 11; done }

# render() · material grid → lit RGB in XG_MR/XG_MG/XG_MB, XG_MA the painted flag
xg_render() {
  local -i x y m i n=$(( XG_XPW*XG_XPH )) up rt upr dn lf r g b br bg bb
  local -F nx ny f bnd k
  local -i KLr=210 KLg=244 KLb=255 RLr=255 RLg=252 RLb=240 FLr=255 FLg=96 FLb=190 AMr=96 AMg=60 AMb=150
  XG_MR=(); XG_MG=(); XG_MB=(); XG_MA=()
  for (( i=0;i<n;i++ )); do XG_MA[$i]=0; XG_MR[$i]=0; XG_MG[$i]=0; XG_MB[$i]=0; done
  for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
    i=$(( y*XG_XPW+x )); m=${XG_XPM[$i]}; (( m==0 )) && continue
    nx=$(( x/(XG_XPW-1.0) )); ny=$(( y/(XG_XPH-1.0) ))
    if (( m==11 )); then XG_MA[$i]=1; XG_MR[$i]=204; XG_MG[$i]=200; XG_MB[$i]=226; continue; fi
    if (( m>=5 && m<=10 )); then
      br=${XG_PR[$m]}; bg=${XG_PG[$m]}; bb=${XG_PB[$m]}
      f=$(( 0.9+0.25*nx )); r=$(( int(br*f) )); g=$(( int(bg*f) )); b=$(( int(bb*f) ))
      (( m==5||m==6 )) && { r=$(( int(r+(255-r)*0.18) )); g=$(( int(g+(255-g)*0.18) )); b=$(( int(b+(255-b)*0.18) )) }
      (( r>255 ))&&r=255; (( g>255 ))&&g=255; (( b>255 ))&&b=255
      XG_MA[$i]=1; XG_MR[$i]=$r; XG_MG[$i]=$g; XG_MB[$i]=$b; continue
    fi
    br=${XG_PR[$m]}; bg=${XG_PG[$m]}; bb=${XG_PB[$m]}
    f=$(( 0.50+0.62*(0.62*nx+0.38*(1.0-ny)) )); r=$(( int(br*f) )); g=$(( int(bg*f) )); b=$(( int(bb*f) ))
    bnd=$(( (1.0-nx)*0.6+ny*0.55-0.24 )); (( bnd<0.0 ))&&bnd=0.0; (( bnd>1.0 ))&&bnd=1.0
    k=$(( 0.36*bnd )); r=$(( int(r+(AMr-r)*k) )); g=$(( int(g+(AMg-g)*k) )); b=$(( int(b+(AMb-b)*k) ))
    up=$(( y-1<0 || XG_XPM[(y-1)*XG_XPW+x]==0 )); rt=$(( x+1>=XG_XPW || XG_XPM[y*XG_XPW+x+1]==0 ))
    upr=$(( y-1<0 || x+1>=XG_XPW || XG_XPM[(y-1)*XG_XPW+x+1]==0 ))
    dn=$(( y+1>=XG_XPH || XG_XPM[(y+1)*XG_XPW+x]==0 )); lf=$(( x-1<0 || XG_XPM[y*XG_XPW+x-1]==0 ))
    if (( up||rt||upr )); then
      k=$(( (up&&rt)?0.50:(up?0.34:0.30) )); r=$(( int(r+(KLr-r)*k) )); g=$(( int(g+(KLg-g)*k) )); b=$(( int(b+(KLb-b)*k) ))
      (( upr&&up )) && { r=$(( int(r+(RLr-r)*0.36) )); g=$(( int(g+(RLg-g)*0.36) )); b=$(( int(b+(RLb-b)*0.36) )) }
    fi
    (( (dn||lf) && !(up||rt) )) && { k=$(( 0.24+0.12*ny )); r=$(( int(r+(FLr-r)*k) )); g=$(( int(g+(FLg-g)*k) )); b=$(( int(b+(FLb-b)*k) )) }
    (( r<0 ))&&r=0; (( g<0 ))&&g=0; (( b<0 ))&&b=0; (( r>255 ))&&r=255; (( g>255 ))&&g=255; (( b>255 ))&&b=255
    (( XG_SENIOR && (m==1||m==2||m==4) )) && { r=$(( int(r+(200-r)*0.22) )); g=$(( int(g+(198-g)*0.22) )); b=$(( int(b+(210-b)*0.22) )); }
    XG_MA[$i]=1; XG_MR[$i]=$r; XG_MG[$i]=$g; XG_MB[$i]=$b
  done; done
}
xg_facepri() { case $1 in 8) REPLY=6;; 7) REPLY=5;; 5|6) REPLY=4;; 10) REPLY=3;; 9) REPLY=2;; *) REPLY=0;; esac }
# render_cells() · two pixel rows → one cell, face features owning their cell
xg_render_cells() {
  xg_render
  XG_CCW=$XG_XPW; XG_CCH=$(( (XG_XPH+1)/2 )); XG_CC=(); XG_CA=()
  local -i cx cy y0 y1 i0 i1 m0 m1 a0 a1 p0 p1 wr wg wb ur ug ub owa winm ci
  for (( cy=0;cy<XG_CCH;cy++ )); do for (( cx=0;cx<XG_CCW;cx++ )); do
    ci=$(( cy*XG_CCW+cx )); XG_CC[$ci]=-1; XG_CA[$ci]=0
    y0=$(( cy*2 )); y1=$(( y0+1 )); i0=$(( y0*XG_XPW+cx )); m0=${XG_XPM[$i0]}; a0=${XG_MA[$i0]}
    if (( y1<XG_XPH )); then i1=$(( y1*XG_XPW+cx )); m1=${XG_XPM[$i1]}; a1=${XG_MA[$i1]}; else i1=$i0; m1=0; a1=0; fi
    (( a0==0 && a1==0 )) && continue
    xg_facepri $m0; p0=$REPLY; xg_facepri $m1; p1=$REPLY
    if (( p0||p1 )); then
      if (( p0>=p1 && a0 )); then wr=${XG_MR[$i0]}; wg=${XG_MG[$i0]}; wb=${XG_MB[$i0]}; ur=${XG_MR[$i1]}; ug=${XG_MG[$i1]}; ub=${XG_MB[$i1]}; owa=$a1; winm=$m0
      else wr=${XG_MR[$i1]}; wg=${XG_MG[$i1]}; wb=${XG_MB[$i1]}; ur=${XG_MR[$i0]}; ug=${XG_MG[$i0]}; ub=${XG_MB[$i0]}; owa=$a0; winm=$m1; fi
      if (( winm==8 && owa )); then
        XG_CC[$ci]=$(( ((int(ur+(wr-ur)*0.65)&0xFC)<<16)|((int(ug+(wg-ug)*0.65)&0xFC)<<8)|(int(ub+(wb-ub)*0.65)&0xFC) )); XG_CA[$ci]=100
      else XG_CC[$ci]=$(( ((wr&0xFC)<<16)|((wg&0xFC)<<8)|(wb&0xFC) )); XG_CA[$ci]=100; fi
    elif (( m0==11 || m1==11 )); then
      if (( m0==11 )); then wr=${XG_MR[$i0]}; wg=${XG_MG[$i0]}; wb=${XG_MB[$i0]}; owa=$a1; ur=${XG_MR[$i1]}; ug=${XG_MG[$i1]}; ub=${XG_MB[$i1]}
      else wr=${XG_MR[$i1]}; wg=${XG_MG[$i1]}; wb=${XG_MB[$i1]}; owa=$a0; ur=${XG_MR[$i0]}; ug=${XG_MG[$i0]}; ub=${XG_MB[$i0]}; fi
      if (( owa==0 )); then XG_CC[$ci]=$(( ((wr&0xFC)<<16)|((wg&0xFC)<<8)|(wb&0xFC) )); XG_CA[$ci]=50
      else XG_CC[$ci]=$(( ((int(ur+(wr-ur)*0.5)&0xFC)<<16)|((int(ug+(wg-ug)*0.5)&0xFC)<<8)|(int(ub+(wb-ub)*0.5)&0xFC) )); XG_CA[$ci]=100; fi
    elif (( a0 && a1 )); then
      XG_CC[$ci]=$(( ((int((XG_MR[i0]+XG_MR[i1])/2)&0xFC)<<16)|((int((XG_MG[i0]+XG_MG[i1])/2)&0xFC)<<8)|(int((XG_MB[i0]+XG_MB[i1])/2)&0xFC) )); XG_CA[$ci]=100
    else
      if (( a0 )); then XG_CC[$ci]=$(( ((XG_MR[i0]&0xFC)<<16)|((XG_MG[i0]&0xFC)<<8)|(XG_MB[i0]&0xFC) ))
      else XG_CC[$ci]=$(( ((XG_MR[i1]&0xFC)<<16)|((XG_MG[i1]&0xFC)<<8)|(XG_MB[i1]&0xFC) )); fi
      XG_CA[$ci]=62
    fi
  done; done
}

# the cat · a faithful port of cat_sit (default tabby, eyes open, ears up)
# ══════════════════════════════════════════════════════════════════════════
# GENETICS · a coat is dealt, not picked · the deck is effectively infinite
# ══════════════════════════════════════════════════════════════════════════
# One anchor colourway drifts continuously in hue, saturation and value per
# seed (the label says how far it went: pale ginger, smoke lilac, vivid cream);
# the pattern, the eye blend, the odd-eye chance, the ear/tail build and a
# two-archetype temperament are each dealt from the same stable 32-bit hash.
# Same seed, same animal, forever.  The hash's mod-2^32 multiply is split into
# 16-bit halves because zsh integers are 64-bit signed and would overflow.
typeset -ga XG_CWN XG_CWR XG_CWG XG_CWB XG_ENAME XG_EYR XG_EYG XG_EYB XG_PATN XG_TNAME XG_TDESC
XG_CWN=(ginger cream grey brown black white lilac cinnamon blue fawn)
XG_CWR=(232 238 150 122 52 240 190 198 122 216); XG_CWG=(132 212 148 88 46 230 168 112 130 178); XG_CWB=(62 168 172 66 74 224 198 70 160 140)
XG_ENAME=(chartreuse amber green ice copper moss)
XG_EYR=(150 255 110 150 216 196); XG_EYG=(232 196 238 210 158 236); XG_EYB=(96 84 140 240 74 210)
XG_PATN=(plain tabby calico tux void)
XG_TNAME=(chaotic dignified clingy nocturnal theatrical gentle)
XG_TDESC=('motivated by food' 'judges your commits' 'supervises everything' 'keeps different hours' 'everything is a lot' 'purrs at low provocation')
typeset -ga XG_TFEED XG_TBOND
XG_TFEED=(1.25 0.85 1.0 1.0 1.2 0.9)   # hunger multiplier per temperament · feeds the emotion engine
XG_TBOND=(0.9  1.1  1.3 1.0 1.2 1.0)   # social multiplier
typeset -gi XG_H; typeset -gF XG_F XG_HH XG_HS XG_HV XG_RR XG_RG XG_RB XG_VR XG_VG XG_VB
typeset -g XG_VMOD
xg_mul32() { local -i a=$1 b=$2; XG_H=$(( ((((a&0xFFFF)*b)&0xFFFFFFFF)+((((a>>16)*b)&0xFFFF)<<16))&0xFFFFFFFF )) }
xg_gh() { local -i seed=$1 salt=$2 r; xg_mul32 $seed 2654435761; r=$XG_H; xg_mul32 $salt 2246822519; r=$(( (r+XG_H+0x9E3779B9)&0xFFFFFFFF )); r=$(( r^(r>>15) )); xg_mul32 $r 2654435769; r=$XG_H; XG_H=$(( r^(r>>13) )) }
xg_gf() { xg_gh $1 $2; XG_F=$(( (XG_H%100003)/100003.0 )) }
xg_rgb2hsv() { local -F r=$(( $1/255.0 )) g=$(( $2/255.0 )) b=$(( $3/255.0 )) mx mn d
  mx=$(( r>g?(r>b?r:b):(g>b?g:b) )); mn=$(( r<g?(r<b?r:b):(g<b?g:b) )); d=$(( mx-mn )); XG_HV=$mx
  if (( d<0.00001 )); then XG_HS=0.0; XG_HH=0.0; return; fi
  XG_HS=$(( d/mx ))
  if (( mx==r )); then XG_HH=$(( (g-b)/d )); (( XG_HH<0.0 ))&&XG_HH=$(( XG_HH+6.0 ))
  elif (( mx==g )); then XG_HH=$(( (b-r)/d+2.0 )); else XG_HH=$(( (r-g)/d+4.0 )); fi
  XG_HH=$(( XG_HH/6.0 )) }
xg_hsv2rgb() { local -F h=$1 s=$2 v=$3 f p q t; local -i i
  if (( s<0.00001 )); then XG_RR=$(( int(v*255) )); XG_RG=$XG_RR; XG_RB=$XG_RR; return; fi
  h=$(( h*6.0 )); i=$(( int(h) )); f=$(( h-i )); i=$(( i%6 )); p=$(( v*(1.0-s) )); q=$(( v*(1.0-s*f) )); t=$(( v*(1.0-s*(1.0-f)) ))
  case $i in 0) XG_RR=$v; XG_RG=$t; XG_RB=$p;; 1) XG_RR=$q; XG_RG=$v; XG_RB=$p;; 2) XG_RR=$p; XG_RG=$v; XG_RB=$t;; 3) XG_RR=$p; XG_RG=$q; XG_RB=$v;; 4) XG_RR=$t; XG_RG=$p; XG_RB=$v;; *) XG_RR=$v; XG_RG=$p; XG_RB=$q;; esac
  XG_RR=$(( int(XG_RR*255) )); XG_RG=$(( int(XG_RG*255) )); XG_RB=$(( int(XG_RB*255) )) }
xg_clampf() { XG_F=$1; (( XG_F<$2 ))&&XG_F=$2; (( XG_F>$3 ))&&XG_F=$3 }
xg_vary_coat() { local -i r0=$1 g0=$2 b0=$3 seed=$4; local -F span=${5:-1.0} dh sk vk nh ns nv
  xg_rgb2hsv $r0 $g0 $b0
  xg_gf $seed 5; dh=$(( (XG_F-0.5)*0.05*span )); xg_gf $seed 6; sk=$(( 1.0+(0.70+0.60*XG_F-1.0)*span )); xg_gf $seed 7; vk=$(( 1.0+(0.84+0.30*XG_F-1.0)*span ))
  nh=$(( XG_HH+dh )); (( nh<0.0 ))&&nh=$(( nh+1.0 )); (( nh>=1.0 ))&&nh=$(( nh-1.0 ))
  xg_clampf $(( XG_HS*sk )) 0.0 0.92; ns=$XG_F; xg_clampf $(( XG_HV*vk )) 0.10 1.0; nv=$XG_F
  xg_hsv2rgb $nh $ns $nv; XG_VR=$XG_RR; XG_VG=$XG_RG; XG_VB=$XG_RB
  if (( vk<0.92 && sk<0.92 )); then XG_VMOD='smoke '
  elif (( vk<0.90 )); then XG_VMOD='deep '
  elif (( vk>1.06 && sk<0.95 )); then XG_VMOD='pale '
  elif (( sk<0.82 )); then XG_VMOD='dusty '
  elif (( sk>1.16 )); then XG_VMOD='vivid '
  else XG_VMOD=''; fi }
xg_dj() { local -i pj=$1 i=$2; local -F lo=$3 hi=$4 r; r=$(( ((pj*48271+i*30203+11213)%10007)/10007.0 )); XG_F=$(( lo+r*(hi-lo) )) }
# ══════════════════════════════════════════════════════════════════════════
# THE PAPERWORK, WRITTEN DOWN · a save that survives the deck changing
# ══════════════════════════════════════════════════════════════════════════
# An animal used to be stored as a SEED and dealt afresh every time it loaded.
# That is elegant and it is wrong for a file somebody backs up: the day a deck
# gains a colourway or a breed narrows one, every animal already signed for
# deals into somebody else.  So the save carries the finished animal -- its
# words AND its twelve colours -- and the loader wears what is written rather
# than dealing again.  A save from before this still works: no colours means
# deal, and the deal is written down on the next save.
xg_pal_str() {   # the palette in hand → REPLY · twelve colours, as hex
  local -i i; local out=''
  for (( i=0; i<12; i++ )); do
    (( i )) && out+=','
    out+="$(printf '%06x' $(( ((${XG_PR[$i]:-0})<<16)|((${XG_PG[$i]:-0})<<8)|(${XG_PB[$i]:-0}) )))"
  done
  REPLY="$out"
}
xg_pal_set() {   # xg_pal_set STR → 0 if twelve good colours went on
  local -a f; f=(${(s:,:)1}); local -i i v
  (( ${#f[@]} == 12 )) || return 1
  # NO EXTENDED_GLOB HERE.  This read `[0-9a-fA-F](#c6)`, which needs
  # EXTENDED_GLOB -- and the cabinet runs under `emulate -L zsh` with only
  # KSH_ARRAYS, SH_WORD_SPLIT and NO_NOMATCH.  So `(#c6)` was six literal
  # characters, every colour failed, xg_wear fell through to a fresh deal,
  # and the palette written into terminal.save was never once worn.  A
  # length test and a negated set say the same thing in plain zsh.
  for (( i=0; i<12; i++ )); do
    [[ ${#f[$i]} -eq 6 && "${f[$i]}" != *[^0-9a-fA-F]* ]] || return 1
  done
  XG_PR=(); XG_PG=(); XG_PB=()
  for (( i=0; i<12; i++ )); do
    v=$(( 0x${f[$i]} )); XG_PR+=($(( (v>>16)&255 ))); XG_PG+=($(( (v>>8)&255 ))); XG_PB+=($(( v&255 )))
  done
  return 0
}
xg_wear() {   # xg_wear SEED SPECIES [PALSTR] — wear what is written, or deal
  # THE BREED IS PART OF WHAT IS WRITTEN DOWN.  Dealing without it re-picks
  # the breed from the seed and throws the recorded one away, which took a
  # Norwegian Forest brown tux and made it an Abyssinian cinnamon tabby --
  # a different cat -- on the day one line went missing.
  #
  # AND THE COLOURS AND THE WORDS ARE TWO THINGS.  A save can carry a good
  # palette and no label; wearing the palette and returning left the label
  # permanently empty, so the roster showed a blank animal.  The written
  # colours always win; the words are refilled from the written breed.
  local -i worn=0
  if [[ -n "${3:-}" ]] && xg_pal_set "$3"; then XG[pal]="$3"; worn=1; fi
  # THE WORDS IT IS WEARING, if the file still has them.  The colourway is
  # stored with its intensity in front ("deep grey"); the deck knows it by
  # the last word, which is why no colourway name may contain a space.
  local cw="${XG[colorway]:-}"
  XG_FORCE_CW="${cw##* }"; XG_FORCE_PAT="${XG[pattern]:-}"
  if (( worn )); then
    [[ -n "${XG[label]:-}" ]] && { XG_FORCE_CW=''; XG_FORCE_PAT=''; return 0 }
    local -a kr kg kb; kr=("${XG_PR[@]}"); kg=("${XG_PG[@]}"); kb=("${XG_PB[@]}")
    xg_deal_coat $1 "$2" "${XG[breed]:-}"
    XG_PR=("${kr[@]}"); XG_PG=("${kg[@]}"); XG_PB=("${kb[@]}"); XG[pal]="$3"
    XG_FORCE_CW=''; XG_FORCE_PAT=''; return 0
  fi
  xg_deal_coat $1 "$2" "${XG[breed]:-}"
  XG_FORCE_CW=''; XG_FORCE_PAT=''
  xg_pal_str; XG[pal]="$REPLY"
  return 0
}

xg_deal_coat() {   # xg_deal_coat SEED [SPECIES] [BREED] — the right deck for the animal
  local sp="${2:-}"
  [[ -n "$sp" ]] || { xg_species_of $1; sp="$REPLY" }
  # THE BREED IS DEALT FIRST, because it decides what the rest may be.
  xg_breed_pick $1 "$sp" "${3:-}"
  XG[breed]="$XB_NAME"
  case "$sp" in
    cat)    xg_deal_cat $1 ;;
    dog)    xg_deal_dog $1 ;;
    rabbit) xg_deal_rabbit $1 ;;
    *)      xg_deal_generic $1 "$sp" ;;
  esac
  # AND THEN THE EYES ARE MADE TO READ · only on the breed path · see xg_eye_lift
  (( XB_I >= 0 )) && xg_eye_lift
  return 0
}
xg_deal_cat() {   # xg_deal_cat SEED — sets XG_PR/PG/PB and XG[pattern|pj|eyes|ear_s|tail_n|colorway|temper|label]
  local -i seed=$1 ci pi ei ej ti tj bR bG bB dR dG dB oR oG oB wR wG wB nR nG nB eR eG eB; local -F et w
  xg_breed_sets cat "${(j:|:)XG_CWN[@]}" "${(j:|:)XG_PATN[@]}"
  xg_gh $seed 3; ci=${XB_CWIX[$(( XG_H%${#XB_CWIX[@]} ))]}
  xg_vary_coat ${XG_CWR[$ci]} ${XG_CWG[$ci]} ${XG_CWB[$ci]} $seed; bR=$XG_VR; bG=$XG_VG; bB=$XG_VB
  xg_gh $seed 9; pi=${XB_PATIX[$(( XG_H%${#XB_PATIX[@]} ))]}; XG[pattern]=${XG_PATN[$pi]}; xg_gh $seed 33; XG[pj]=$(( XG_H%9973 ))
  xg_gh $seed 15; ei=$(( XG_H%6 )); xg_gh $seed 16; ej=$(( (ei+1+XG_H%5)%6 )); xg_gf $seed 17; et=$XG_F
  eR=$(( int(XG_EYR[ei]+(XG_EYR[ej]-XG_EYR[ei])*et*0.55) )); eG=$(( int(XG_EYG[ei]+(XG_EYG[ej]-XG_EYG[ei])*et*0.55) )); eB=$(( int(XG_EYB[ei]+(XG_EYB[ej]-XG_EYB[ei])*et*0.55) ))
  (( et<0.5 )) && XG[eyes]=${XG_ENAME[$ei]} || XG[eyes]="${XG_ENAME[$ei]}-${XG_ENAME[$ej]}"
  xg_gf $seed 21; XG[ear_s]=$(( 0.70+0.28*XG_F )); xg_gf $seed 26; XG[tail_n]=$(( 0.78+0.40*XG_F ))
  local -F bk=$(( (${XG[ear_s]}-0.70)/0.28*0.5 + (${XG[tail_n]}-0.78)/0.40*0.5 ))
  if (( bk<0.36 )); then XG[build]=neat; elif (( bk<0.68 )); then XG[build]=classic; else XG[build]=long; fi
  xg_gh $seed 11; ti=$(( XG_H%6 )); xg_gh $seed 12; tj=$(( (ti+1+XG_H%5)%6 )); xg_gf $seed 13; w=$(( 0.62+0.38*XG_F ))
  XG[tname]="${XG_TNAME[$ti]}"
  xg_an "${XG_TNAME[$tj]}"
  (( w>0.82 )) && XG[temper]="${XG_TDESC[$ti]}" || XG[temper]="${XG_TDESC[$ti]} · $REPLY ${XG_TNAME[$tj]} streak"
  xg_gf $seed 14; xg_m2 $(( int((XG_TFEED[ti]*w + XG_TFEED[tj]*(1.0-w) + (XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[hunger_m]="$REPLY"
  xg_gf $seed 18; xg_m2 $(( int((XG_TBOND[ti]*w + XG_TBOND[tj]*(1.0-w) + (XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[social_m]="$REPLY"
  XG[colorway]="${XG_VMOD}${XG_CWN[$ci]}"; (( pi>0 )) && XG[label]="${XG[colorway]} ${XG[pattern]}" || XG[label]="${XG[colorway]}"
  dR=$(( int(bR*0.66) )); dG=$(( int(bG*0.66) )); dB=$(( int(bB*0.66) ))
  xg_vary_coat 236 146 74 $(( seed*7+1 )) 0.7; oR=$XG_VR; oG=$XG_VG; oB=$XG_VB
  if [[ "${XG[pattern]}" == void ]]; then wR=$bR; wG=$bG; wB=$bB; else wR=$(( int(bR+(250-bR)*0.75) )); wG=$(( int(bG+(246-bG)*0.75) )); wB=$(( int(bB+(240-bB)*0.75) )); fi
  nR=$(( int(bR+(210-bR)*0.5) )); nG=$(( int(bG+(110-bG)*0.5) )); nB=$(( int(bB+(110-bB)*0.5) ))
  XG_PR=(0 $bR $dR $wR $oR $eR $eR 22 255 232 $nR 204); XG_PG=(0 $bG $dG $wG $oG $eG $eG 18 255 136 $nG 200); XG_PB=(0 $bB $dB $wB $oB $eB $eB 30 255 148 $nB 226) }
xg_coat_dress() {   # xg_coat_dress HX HY — paint the dealt pattern onto the coat
  local -F hx=$1 hy=$2 v thr ph a1 a2 a3 a4 a5 a6 a7 a8 a9 a10; local -i x y pj=${XG[pj]:-0} dx dyy
  case "${XG[pattern]:-tabby}" in
    plain) ;;
    tabby)
      xg_dj $pj 9 0.80 1.04; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*0.95+x*0.22+pj*0.37)+0.4*sin(x*0.9+pj*0.74) )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done
      for dx in -2 0 2; do for (( dyy=0;dyy<3;dyy++ )); do xg_set $(( int(hx)+dx )) $(( int(hy-5)+dyy+(dx?1:0) )) 2; done; done ;;
    calico)
      xg_dj $pj 1 3.4 5.6; a1=$XG_F; xg_dj $pj 2 -4.6 -2.2; a2=$XG_F; xg_dj $pj 3 3.6 5.2; a3=$XG_F
      xg_disk $(( hx+a1 )) $(( hy+a2 )) $a3 3.6 4 "1"
      xg_dj $pj 4 4.4 6.6; a4=$XG_F; xg_dj $pj 5 7.8 10.2; a5=$XG_F; xg_dj $pj 6 3.8 5.4; a6=$XG_F
      xg_disk $(( hx-a4 )) $(( hy+a5 )) $a6 3.4 4 "1"
      xg_dj $pj 7 2.4 4.6; a7=$XG_F; xg_dj $pj 8 3.4 5.6; a8=$XG_F
      xg_disk $(( hx-a7 )) $(( hy-a8 )) 3.2 2.6 2 "1"
      xg_dj $pj 9 4.4 6.6; a9=$XG_F; xg_dj $pj 10 9.8 12.2; a10=$XG_F
      xg_disk $(( hx+a9 )) $(( hy+a10 )) 3.8 3.0 2 "1" ;;
    tux)
      xg_dj $pj 1 3.6 5.2; a1=$XG_F; xg_dj $pj 2 5.2 6.8; a2=$XG_F
      xg_disk $hx $(( hy+9.5 )) $a1 $a2 3 "1 2"
      xg_dj $pj 3 2.0 3.4; a3=$XG_F
      xg_disk $hx $(( hy+3.2 )) $a3 2.4 3 "1 2" ;;
    void)
      xg_dj $pj 1 1.08 1.38; thr=$XG_F; ph=$(( pj*0.61 ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { (( sin(y*0.9+x*0.2+ph)>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
  esac }
# ── the shared body parts · every pose is built from these ──
xg_ears() {   # xg_ears HX HY S MODE(up|back|flat)
  local -F hx=$1 hy=$2 s=$3; local mode="${4:-up}"
  if [[ "$mode" == up ]]; then
    xg_tri $(( hx-6.4*s )) $(( hy-2.5*s )) $(( hx-5.4*s )) $(( hy-8.6*s )) $(( hx-1.2*s )) $(( hy-4.4*s )) 1
    xg_tri $(( hx+6.4*s )) $(( hy-2.5*s )) $(( hx+5.4*s )) $(( hy-8.6*s )) $(( hx+1.2*s )) $(( hy-4.4*s )) 1
    xg_tri $(( hx-5.4*s )) $(( hy-3.4*s )) $(( hx-4.9*s )) $(( hy-7.0*s )) $(( hx-2.6*s )) $(( hy-4.6*s )) 9 "1 2 4"
    xg_tri $(( hx+5.4*s )) $(( hy-3.4*s )) $(( hx+4.9*s )) $(( hy-7.0*s )) $(( hx+2.6*s )) $(( hy-4.6*s )) 9 "1 2 4"
  elif [[ "$mode" == back ]]; then
    xg_tri $(( hx-7.2*s )) $(( hy-2.0*s )) $(( hx-7.8*s )) $(( hy-6.8*s )) $(( hx-1.6*s )) $(( hy-4.0*s )) 1
    xg_tri $(( hx+7.2*s )) $(( hy-2.0*s )) $(( hx+7.8*s )) $(( hy-6.8*s )) $(( hx+1.6*s )) $(( hy-4.0*s )) 1
  else   # flat · displeasure
    xg_tri $(( hx-7.6*s )) $(( hy-1.5*s )) $(( hx-8.4*s )) $(( hy-4.6*s )) $(( hx-1.2*s )) $(( hy-3.6*s )) 1
    xg_tri $(( hx+7.6*s )) $(( hy-1.5*s )) $(( hx+8.4*s )) $(( hy-4.6*s )) $(( hx+1.2*s )) $(( hy-3.6*s )) 1
  fi
}
typeset -gF XG_EYE_MINCR=2.1
xg_eye_lift() {   # the eyes must not be the colour of the head
  # AN EYE THE SHADE OF THE FACE AROUND IT IS NOT AN EYE.  The coat and the
  # eye colour are dealt from separate decks and nothing ever asked whether
  # the two could be told apart, so a slate turtle got slate eyes (1.07:1), a
  # corn snake amber ones on amber (1.04:1), and the animal looked blind.
  # This keeps the HUE the deal chose -- amber eyes stay amber -- and only
  # moves its lightness, away from the coat, until the two separate.
  #
  # IT RUNS ONLY WHEN A BREED WAS DEALT.  The pre-breed path is what every
  # save older than breeds re-deals from and it is frozen, so an animal you
  # already own is never repainted by this.
  local -i i n; local -F lb le t
  xg_rel_lum ${XG_PR[1]} ${XG_PG[1]} ${XG_PB[1]}; lb=$REPLY
  for i in 5 6; do
    # IT WALKS UNTIL IT CLEARS, up to four steps.  One fixed step is enough
    # for most coats and not for the darkest, and an eye that is ALMOST
    # readable is the same as one that is not.
    for (( n=0; n<4; n++ )); do
      xg_rel_lum ${XG_PR[$i]} ${XG_PG[$i]} ${XG_PB[$i]}; le=$REPLY
      (( (le>lb ? (le+0.05)/(lb+0.05) : (lb+0.05)/(le+0.05)) >= XG_EYE_MINCR )) && break
      # A DARK HEAD TAKES A LIGHT EYE and a light head a dark one -- whichever
      # way is further to go, so a mid-tone coat still lands somewhere.
      if (( lb < 0.22 )); then
        t=0.45; XG_PR[$i]=$(( int(XG_PR[i]+(255-XG_PR[i])*t) ))
                XG_PG[$i]=$(( int(XG_PG[i]+(255-XG_PG[i])*t) ))
                XG_PB[$i]=$(( int(XG_PB[i]+(255-XG_PB[i])*t) ))
      else
        t=0.42; XG_PR[$i]=$(( int(XG_PR[i]*(1.0-t)) ))
                XG_PG[$i]=$(( int(XG_PG[i]*(1.0-t)) ))
                XG_PB[$i]=$(( int(XG_PB[i]*(1.0-t)) ))
      fi
    done
  done
  return 0
}
xg_rel_lum() {   # xg_rel_lum R G B → REPLY · WCAG relative luminance, 0..1
  local -F r=$(( $1/255.0 )) g=$(( $2/255.0 )) b=$(( $3/255.0 ))
  r=$(( r<=0.03928 ? r/12.92 : ((r+0.055)/1.055)**2.4 ))
  g=$(( g<=0.03928 ? g/12.92 : ((g+0.055)/1.055)**2.4 ))
  b=$(( b<=0.03928 ? b/12.92 : ((b+0.055)/1.055)**2.4 ))
  REPLY=$(( 0.2126*r+0.7152*g+0.0722*b ))
}

xg_eye() {   # xg_eye CX CY R MAT [ONLY] — ONE eye, in the cabinet's one eye language
  # THE CAT HAD A MODELLED EYE and seven of the others had a single pixel.
  # xg_face gives a cat a sclera, a pupil and a catchlight, which is why you
  # can tell where a cat is looking; the hamster, turtle, hedgehog, duck,
  # snake, pig and axolotl were each drawn with one or two lit pixels, which
  # at the cabinet's half-block resolution is a speck.  That is the whole of
  # the difference between an animal that looks at you and one that does not,
  # so it is written down once here and every face calls it.
  #
  # THIS IS A DEPARTURE FROM THE ORIGINAL, which drew those seven as specks.
  # The proportions are the cat's: the pupil is about half the eye across and
  # the catchlight sits up and to the right, where the room's light is.
  # IT DEGRADES WITH THE HEAD IT IS ON.  A snake's head is four pixels across
  # and cannot carry what a cat's fourteen can: above 1.3 the eye is modelled
  # in full, between 0.85 and 1.3 the catchlight is dropped (at that size it
  # would be half the eye), and below that it is a lit pixel over a dark one,
  # which is still an eye and still two parts.
  local -F cx=$1 cy=$2 r=$3; local -i mat=$4; local only="${5:-1 2 3 4}"
  if (( r >= 1.3 )); then
    xg_disk $cx $cy $r $(( r*0.88 )) $mat "$only"
    xg_disk $cx $cy $(( r*0.52 )) $(( r*0.52 )) 7 "5 6"
    xg_set $(( int(cx+r*0.62) )) $(( int(cy-r*0.62) )) 8
  elif (( r >= 0.85 )); then
    xg_disk $cx $cy $r $(( r*0.9 )) $mat "$only"
    xg_set $(( int(cx) )) $(( int(cy+0.5) )) 7
  else
    xg_set $(( int(cx) )) $(( int(cy-0.5) )) $mat
    xg_set $(( int(cx) )) $(( int(cy+0.5) )) 7
  fi
  return 0
}

xg_face() {   # xg_face HX HY EYES PUPIL MUZZLE SCALE
  local -F hx=$1 hy=$2 s=${6:-1.0} ex; local eyes="${3:-open}" pupil="${4:-slit}"; local -i muzzle=${5:-1}
  local BODY="1 2 3 4"
  local -F exl=$(( hx-3.4*s )) exr=$(( hx+3.4*s )) ey=$(( hy-0.6*s ))
  if [[ "$eyes" == open ]]; then
    xg_disk $exl $ey $(( 1.8*s )) $(( 1.5*s )) 5 "$BODY"; xg_disk $exr $ey $(( 1.8*s )) $(( 1.5*s )) 6 "$BODY"
    if [[ "$pupil" == slit ]]; then
      for ex in $exl $exr; do xg_set $(( int(ex) )) $(( int(ey-1) )) 7; xg_set $(( int(ex) )) $(( int(ey) )) 7; xg_set $(( int(ex) )) $(( int(ey+1) )) 7; done
    else   # round / dilated · a fuller pupil, both eyes
      xg_disk $exl $ey $(( 0.9*s )) $(( 0.9*s )) 7 "5 6"; xg_disk $exr $ey $(( 0.9*s )) $(( 0.9*s )) 7 "5 6"
    fi
    xg_set $(( int(exl+1) )) $(( int(ey-1) )) 8; xg_set $(( int(exr+1) )) $(( int(ey-1) )) 8
  elif [[ "$eyes" == closed ]]; then
    for ex in $exl $exr; do xg_set $(( int(ex-1) )) $(( int(ey) )) 7; xg_set $(( int(ex) )) $(( int(ey+1) )) 7; xg_set $(( int(ex+1) )) $(( int(ey) )) 7; done
  else   # narrow · a knowing squint
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  fi
  (( muzzle )) && xg_disk $hx $(( hy+2.7*s )) $(( 2.4*s )) $(( 1.7*s )) 3 "$BODY"
  xg_tri $(( hx-1.2 )) $(( hy+1.9*s )) $(( hx+1.2 )) $(( hy+1.9*s )) $hx $(( hy+2.9*s )) 10 "1 2 3 4"
  xg_set $(( int(hx) )) $(( int(hy+3.1*s) )) 2; xg_set $(( int(hx-1) )) $(( int(hy+3.7*s) )) 2; xg_set $(( int(hx+1) )) $(( int(hy+3.7*s) )) 2
}
xg_whiskers() {   # xg_whiskers HX HY SCALE
  local -F hx=$1 hy=$2 s=${3:-1.0} x0; local -i side
  for side in -1 1; do x0=$(( hx+side*4.2*s )); xg_whrow $x0 $(( hy+2.2*s )) $side $(( int(4*s) )); xg_whrow $x0 $(( hy+3.4*s )) $side $(( int(3*s) )); done
}
xg_tail_sit() {   # xg_tail_sit HX HY MODE(curl|lash|puff)
  local -F hx=$1 hy=$2; local mode="${3:-curl}"
  case "$mode" in
    lash) xg_seg $(( hx+6 )) $(( hy+14.5 )) $(( hx+11.5 )) $(( hy+12 )) 1.7 1; xg_seg $(( hx+11.5 )) $(( hy+12 )) $(( hx+13 )) $(( hy+7.5 )) 1.7 1
          xg_disk $(( hx+13.4 )) $(( hy+6.6 )) 1.6 1.9 2; xg_set $(( int(hx+15.6) )) $(( int(hy+9.5) )) 11; xg_set $(( int(hx+16.2) )) $(( int(hy+12) )) 11 ;;
    puff) xg_seg $(( hx+6 )) $(( hy+15 )) $(( hx+11 )) $(( hy+13.5 )) 2.6 1; xg_seg $(( hx+11 )) $(( hy+13.5 )) $(( hx+13 )) $(( hy+9 )) 2.6 1; xg_disk $(( hx+13.4 )) $(( hy+8 )) 2.4 2.6 2 ;;
    *)    xg_seg $(( hx+6 )) $(( hy+15 )) $(( hx+11 )) $(( hy+17.5 )) 1.8 1; xg_seg $(( hx+11 )) $(( hy+17.5 )) $(( hx+13.5 )) $(( hy+16 )) 1.8 1
          xg_seg $(( hx+13.5 )) $(( hy+16 )) $(( hx+14 )) $(( hy+12.5 )) 1.8 1; xg_disk $(( hx+14 )) $(( hy+12 )) 1.7 2.0 2 ;;
  esac
}
xg_cat_sit() {   # xg_cat_sit [EYES] [PUPIL] [EARS] [TAIL]
  local eyes="${1:-open}" pupil="${2:-slit}" ears="${3:-up}" tail="${4:-curl}"
  xg_px_new 36 31; local -F hx=17.0 hy=9.0; local -i yy
  xg_tail_sit $hx $hy "$tail"
  xg_disk $hx $(( hy+15 )) 9.6 5.8 1; xg_disk $hx $(( hy+11 )) 7.2 7.2 1; xg_disk $hx $hy 7.4 6.2 1; xg_disk $hx $(( hy+2.2 )) 8.0 4.2 1
  xg_ears $hx $hy 1.0 "$ears"
  for (( yy=int(hy+12); yy<int(hy+20); yy++ )); do xg_set $(( int(hx) )) $yy 2; done
  xg_disk $(( hx-3.4 )) $(( hy+19.4 )) 2.6 1.6 3; xg_disk $(( hx+3.2 )) $(( hy+19.4 )) 2.6 1.6 3
  xg_set $(( int(hx-3.4) )) $(( int(hy+19.9) )) 2; xg_set $(( int(hx+3.2) )) $(( int(hy+19.9) )) 2
  xg_coat_dress $hx $hy
  xg_face $hx $hy "$eyes" "$pupil" 1 1.0
  xg_whiskers $hx $hy 1.0
}
xg_cat_loaf() {   # xg_cat_loaf [EYES] — a bread loaf, paws tucked
  local eyes="${1:-open}"; xg_px_new 36 24; local -F hx=21.5 hy=8.0
  xg_disk 17 $(( hy+8.4 )) 11.5 6.2 1
  xg_seg 9 $(( hy+12 )) 5.5 $(( hy+12.8 )) 1.5 1; xg_seg 5.5 $(( hy+12.8 )) 4 $(( hy+11 )) 1.5 1; xg_disk 4 $(( hy+10.8 )) 1.4 1.6 2
  xg_disk $hx $hy 6.6 5.6 1; xg_disk $hx $(( hy+2 )) 7.2 3.8 1
  xg_ears $hx $hy 0.92 up
  xg_coat_dress $hx $hy
  xg_face $hx $hy "$eyes" slit 1 0.95
  xg_whiskers $hx $hy 0.9
}
xg_cat_sleep() {   # xg_cat_sleep — curled, eyes shut
  xg_px_new 34 19; local -F cx=16.0 cy=10.0 ex
  xg_disk $(( cx+1 )) $cy 11.0 6.0 1; xg_disk $(( cx+4.5 )) $(( cy-2.4 )) 7.2 4.2 1
  local -F hx=$(( cx-6.8 )) hy=$(( cy-0.8 ))
  xg_disk $hx $hy 5.8 5.0 1; xg_disk $hx $(( hy+1.6 )) 6.2 3.4 1
  xg_ears $hx $hy 0.8 up
  xg_seg $(( cx+10.5 )) $(( cy+2 )) $(( cx+4 )) $(( cy+5.4 )) 1.6 1; xg_seg $(( cx+4 )) $(( cy+5.4 )) $(( cx-4 )) $(( cy+5.4 )) 1.6 1; xg_seg $(( cx-4 )) $(( cy+5.4 )) $(( hx-0.5 )) $(( cy+4.2 )) 1.6 1
  xg_disk $(( hx-1.8 )) $(( cy+3.8 )) 1.7 1.5 2
  xg_coat_dress $hx $hy
  for ex in $(( hx-2.6 )) $(( hx+2.4 )); do xg_set $(( int(ex-1) )) $(( int(hy+0.4) )) 7; xg_set $(( int(ex) )) $(( int(hy+0.9) )) 7; xg_set $(( int(ex+1) )) $(( int(hy+0.4) )) 7; done
  xg_tri $(( hx-1.0 )) $(( hy+2.2 )) $(( hx+1.0 )) $(( hy+2.2 )) $hx $(( hy+3.0 )) 10 "1 2 3 4"
}
xg_cat_walk() {   # xg_cat_walk [FRAME 0|1] — mid-stride
  local -i frame=${1:-0} i; xg_px_new 32 22; local -F bx=15.0 hx=23.5 hy=8.0 x0
  xg_seg $(( bx-8.5 )) 11 $(( bx-12 )) 6.5 1.5 1; xg_seg $(( bx-12 )) 6.5 $(( bx-11.5 )) 4 1.5 1; xg_disk $(( bx-11.5 )) 3.6 1.4 1.6 2
  xg_disk $(( bx-3 )) 12.5 7.8 4.6 1; xg_disk $(( bx+3.5 )) 11.8 6.5 4.2 1
  xg_disk $hx $hy 6.0 5.2 1; xg_disk $hx $(( hy+1.8 )) 6.5 3.4 1
  xg_ears $hx $hy 0.9 up
  local -a lx ll; lx=(-8 -4 2 6); if (( frame==0 )); then ll=(0 1 0 1); else ll=(1 0 1 0); fi
  for (( i=0;i<4;i++ )); do x0=$(( bx+lx[i] )); xg_seg $x0 15.0 $(( x0+0.4 )) $(( 19.5-ll[i]*2.0 )) 1.1 1; xg_disk $(( x0+0.5 )) $(( 20.0-ll[i]*2.0 )) 1.4 0.9 3; done
  xg_coat_dress $hx $hy
  xg_face $hx $hy open slit 1 0.9
  xg_whiskers $hx $hy 0.85
}
xg_build_pose() {   # xg_build_pose POSE EYES [FRAME] [SPECIES] — the right body, at its age
  local pose="${1:-sit}" eyes="${2:-open}" sp="${4:-${XG[species]:-cat}}"
  local -i frame=${3:-0} s=${XG[stage_i]:-2}
  local -a P; P=(${=XG_POSES[$sp]:-${XG_POSES[cat]}})   # sit·baby·loaf·sleep·walk·play·flop
  if [[ "${XG_STAGE_FORM[$s]}" == baby ]]; then
    [[ "$pose" == sleep ]] && eyes=closed        # a baby does everything in a baby's body
    if [[ "$sp" == cat ]]; then xg_cat_kitten "$eyes" round; else ${P[1]} "$eyes"; fi
  else
    case "$pose" in
      loaf)  if [[ "$sp" == cat ]]; then xg_cat_loaf "$eyes"; else ${P[2]}; fi ;;
      sleep) ${P[3]} ;;
      walk)  ${P[4]} $frame ;;
      play)  ${P[5]} ;;                          # the pounce · the bow · the binky
      flop)  ${P[6]} ;;                          # on its back, paws in the air
      *)     ${P[0]} "$eyes" ;;
    esac
  fi
  # ── AND THEN IT IS GROWN ──
  #    Both drawings are taken to the SAME target height: the baby's is the
  #    shorter of the two, so it is scaled up by the ratio between them first.
  #    That is what makes the day the shape changes not also the day the size
  #    changes.  A cap keeps the tallest breed inside the room.
  local -F sc=${XG[grow]:-1.0} wf=1.0
  if [[ "${XG_STAGE_FORM[$s]}" == baby ]]; then
    sc=$(( sc * ${XG_SP_AH[$sp]:-24} * 1.0 / ${XG_SP_BH[$sp]:-16} ))
  fi
  (( s == 4 )) && wf=1.07
  (( s == 5 )) && wf=0.95
  xg_px_scale_xy $(( sc*wf )) $sc
  local -i cap=$(( (SCR_H-7)*2 )); (( cap < 16 )) && cap=16
  (( XG_XPH > cap )) && xg_px_scale $(( cap*1.0/XG_XPH ))
  return 0
}
typeset -g XG_POSE='sit' XG_POSE_EYES='open' XG_PAL_KEY=''; typeset -gi XG_POSE_FRAME=0 XG_POSE_FACE=1
xg_mirror_px() {   # flip the material grid left-right · it is lit AFTER, so the sun stays top-right
  local -i x y i j t w=$XG_XPW h=$XG_XPH hw=$(( XG_XPW/2 ))
  for (( y=0; y<h; y++ )); do for (( x=0; x<hw; x++ )); do
    i=$(( y*w+x )); j=$(( y*w+w-1-x ))
    t=${XG_XPM[$i]}; XG_XPM[$i]=${XG_XPM[$j]}; XG_XPM[$j]=$t
  done; done
}
# THE POSE SHELF · every pose rendered once is KEPT, keyed whole, so the walk
# cycle's frame flip (and the blink) is a fast array restore, never the ~30ms
# sprite re-render.  A single-slot cache thrashed exactly when the animal was
# most animated — mid-walk — which is when a dropped frame shows the most.
typeset -gA XG_PC_C XG_PC_A XG_PC_W XG_PC_H
xg_cache_pose() {   # bring the current pose's cells up · render only the first time
  local pose="${XG_POSE:-sit}" eyes="${XG_POSE_EYES:-open}"; local -i frame=${XG_POSE_FRAME:-0} face=${XG_POSE_FACE:-1}
  (( face != -1 )) && face=1
  local -i st=${XG[stage_i]:-2}
  [[ "${XG_STAGE_FORM[$st]}" == baby ]] && frame=0        # a kitten's walk is a kitten, sliding
  local pkey="${XG[species]:-cat}.${XG[seed]:-0}.${pose}.${eyes}.${frame}.${face}.${st}.${XG[grow]:-1}"
  [[ "$pkey" == "$XG_CACHE_KEY" && $XG_CCH -gt 0 ]] && return 0
  if [[ -n "${XG_PC_C[$pkey]:-}" ]]; then
    XG_CC=(${(s: :)XG_PC_C[$pkey]}); XG_CA=(${(s: :)XG_PC_A[$pkey]})
    XG_CCW=${XG_PC_W[$pkey]}; XG_CCH=${XG_PC_H[$pkey]}
    XG_CACHE_KEY="$pkey"; return 0
  fi
  local skey="${XG[species]:-cat}.${XG[seed]:-0}"          # the coat only changes with the animal
  [[ "$skey" == "$XG_PAL_KEY" ]] || { xg_wear ${XG[seed]:-61653} "${XG[species]:-cat}" "${XG[pal]:-}"; XG_PAL_KEY="$skey"; }
  local spf="${XG[species]:-cat}"
  xg_build_pose "$pose" "$eyes" $frame "$spf"
  # mirror only when the art and the direction of travel disagree · the pose's
  # own facing wins over its species' · see XG_SP_FACE above
  local -i art=${XG_SP_FACE[$spf.$pose]:-${XG_SP_FACE[$spf]:-1}}
  (( face * art < 0 )) && xg_mirror_px
  XG_SENIOR=$(( st == 5 )); xg_render_cells; XG_SENIOR=0
  XG_PC_C[$pkey]="${XG_CC[*]}"; XG_PC_A[$pkey]="${XG_CA[*]}"
  XG_PC_W[$pkey]=$XG_CCW; XG_PC_H[$pkey]=$XG_CCH
  XG_CACHE_KEY="$pkey"
  return 0
}
xg_blit_cells() {   # xg_blit_cells CX CY — paint the cached cells as backgrounds
  # A SOFT EDGE IS BLENDED INTO WHATEVER IT STANDS IN FRONT OF — the lit wall,
  # a stall's light, the deck — the original's cell_under, not the bare glass.
  local -i cx=$1 cy=$2 x y ci c c2 a X Y rr gg bb u ur ug ub k base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  for (( y=0;y<XG_CCH;y++ )); do for (( x=0;x<XG_CCW;x++ )); do
    ci=$(( y*XG_CCW+x )); c=${XG_CC[$ci]}; (( c<0 )) && continue
    X=$(( cx+x )); Y=$(( cy+y )); (( X<0||X>=SCR_W||Y<0||Y>=SCR_H )) && continue
    a=${XG_CA[$ci]}
    if (( a>=99 )); then v_put $X $Y ' ' $GREY $c
    else
      k=$(( base+Y*TCOLS+X ))
      if [[ "${GCH[$k]:- }" == '▀' ]]; then
        u=${GF[$k]:-$GREY}; c2=${GB[$k]:-$GLASS}
        u=$(( ((((((u>>16)&255)+((c2>>16)&255))/2)&0xFC)<<16)|(((((u>>8)&255)+((c2>>8)&255))/2)&0xFC)<<8|((((u&255)+(c2&255))/2)&0xFC) ))
      else u=${GB[$k]:-$GLASS}; (( u < 0 )) && u=$GLASS; fi
      ur=$(( (u>>16)&255 )); ug=$(( (u>>8)&255 )); ub=$(( u&255 ))
      rr=$(( (c>>16)&255 )); gg=$(( (c>>8)&255 )); bb=$(( c&255 ))
      v_put $X $Y ' ' $GREY $(( (((ur+(rr-ur)*a/100)&0xFC)<<16)|(((ug+(gg-ug)*a/100)&0xFC)<<8)|((ub+(bb-ub)*a/100)&0xFC) ))
    fi
  done; done
}

# ══════════════════════════════════════════════════════════════════════════
# THE PET · one animal in view, an index into the bay (Stage 1: a mock cat)
# ══════════════════════════════════════════════════════════════════════════
# The real thing is read from and written to the `xenogotchi.*` section of the
# house save; until the save glue lands, a fixture cat stands in it so the room
# has an occupant to draw and the pages have numbers to read.
typeset -gA XG                       # the animal in view · flat fields
typeset -g  XG_VIEW='menu'           # the page in front · 'menu' is the landing
typeset -gi XG_MROW=0                # the menu cursor
typeset -gF XG_NOW=0.0               # the pack clock, handed in each tick
typeset -gA XG_HOUSE                 # the house itself · toy, kibble, style, own, litter
typeset -gi XG_ACTIVE=0 XG_NPETS=1   # the roster · who is in the room, how many live here

# the page ring · HOME · STORE · ADOPT · STATS; ALBUM / CRYO follow.  STATS
# used to be a POPUP folded over whatever was up, which meant it could only
# ever be about whoever was standing in the room.  It is a page in the ring
# now, and it is about the whole house: every animal ever signed for.  It sits
# after ADOPT on purpose — the centre, then who you took home from it.
XG_PV=(home store adopt stats)
XG_PK=(H O A S)
XG_PN=(HOME STORE ADOPT STATS)
XG_PD=('the room, and whoever is in it right now' \
       'credits earned by care · the galley, the toys' \
       'intake night · four arrivals from the genetics deck' \
       'the roster · every animal signed for, and its papers')
typeset -gi XG_PAGES=4

xg_seed_pet() {   # a fixture cat, so Stage 1 has an occupant · replaced by the save
  XG=()
  XG[name]='MOCHI'
  XG[species]='cat'
  XG[seed]=61653                       # the mock litter · genetics deal the coat
  XG[stage]='YOUNG CAT'
  XG[health]=93
  XG[food]=78
  XG[water]=64
  XG[bond]=71
  XG[coat]=88
  XG[mood]=80
  XG[pep]=66
  XG[box]=30                           # litter · 0 clean, 100 needs scooping
  XG[credits]=37
  XG[day]=6
  XG[treats_today]=0
  XG[c_pets]=0; XG[c_naps]=0; XG[c_treats]=0     # lifetime counters, for the STATS card
  XG[last_groom]=0; XG[last_pet]=0; XG[overstim]=0; XG[overstim_at]=0
  XG[left]='~11 years ahead, with care'
  xg_lifespan ${XG[seed]} "${XG[species]:-cat}"          # the SAVE says what it is,
  XG[span]=$REPLY                                        # never the seed · a young one, today
  XG[born]=$(( ${EPOCHSECONDS:-0} - 0.15*REPLY*86400.0 ))
  xg_day_key; XG[last_day]="$REPLY"; XG[streak]=0; XG[catches_today]=0
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# CHANGING WHAT IS ON THE GLASS · through the raster, the suite's own way
# ══════════════════════════════════════════════════════════════════════════
xg_go_view() {   # xg_go_view DEST — the only way XG_VIEW is written
  [[ "$1" == "$XG_VIEW" ]] && return 0
  XG_VIEW="$1"
  local -i i
  for (( i = 0; i < XG_PAGES; i++ )); do
    [[ "${XG_PV[$i]}" == "$1" ]] && break
  done
  xf_arm
  return 0
}
xg_page_go() {   # xg_page_go D — ◂ ▸ ring the pages · wraps
  local -i i=0 j n=$XG_PAGES
  for (( j = 0; j < n; j++ )); do [[ "${XG_PV[$j]}" == "$XG_VIEW" ]] && { i=$j; break }; done
  i=$(( ($1 + i + n) % n ))
  xg_go_view "${XG_PV[$i]}"; snd move
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# CHROME · the title band and the footer, on the suite's own furniture
# ══════════════════════════════════════════════════════════════════════════
xg_head() {   # xg_head TITLE PAGES [LAB VAL COL]... — the page name + readings
  # THE CHIPS RIDE THE CABINET'S OWN BAND.  They used to sit on the hull's
  # teal steel, which made the title row read as a second stats bar stuck
  # over the first; they take app_head's purple now, so row 0 is one band
  # from the brand to the clock.  Values keep their caller's colour; labels
  # go stencil-dim against it.
  local t="$1"; local -i pages=$2 x hb lb
  cmix $GLASS $PURPLE 0.32; hb=$CM
  cmix $GREY $PURPLE 0.30; cshade $CM 1.05; lb=$CS
  app_head XENOGOTCHI
  x=$APP_HX
  if (( pages )); then
    cshade $CYAN 1.05;      v_text $x 0 '◂ ' $CS $hb
    cmix $WHITE $CYAN 0.30; v_text $(( x + 2 )) 0 "$t" $CM $hb
    cshade $CYAN 1.05;      v_text $(( x + 2 + ${#t} )) 0 ' ▸' $CS $hb
    x=$(( x + 5 + ${#t} ))
  else
    cmix $WHITE $CYAN 0.30; v_text $x 0 "$t" $CM $hb
    x=$(( x + 2 + ${#t} ))
  fi
  shift 2
  local -i rd=0                                  # was the last thing drawn a reading?
  while (( $# >= 3 )); do
    # the band ends where the sky's caption starts · what would run into it is left off
    if [[ "$1" == - ]]; then (( x - 2 * rd + ${#2} > APP_HR + 1 )) && break
    else                     (( x + ${#1} + 1 + ${#2} > APP_HR )) && break; fi
    if [[ "$1" == - ]]; then                     # a plain tail · tight after a reading, spaced after the title
      (( rd )) && x=$(( x-2 ))
      v_text $x 0 "$2" $3 $hb; x=$(( x + ${#2} + 3 )); rd=0
    else
      v_text $x 0 "$1" $lb $hb
      v_text $(( x + ${#1} + 1 )) 0 "$2" $3 $hb
      x=$(( x + ${#1} + ${#2} + 4 )); rd=1
    fi
    shift 3
  done
  return 0
}
xg_lift_for() {   # xg_lift_for X Y COL -> REPLY · COL, inked for the ground at X,Y
  # THE ROOM IS NOT THE SAME ROOM AT EVERY SIZE.  On the cabinet's own glass
  # the engine room is a close-up and the hull's conduit stands off-frame, so
  # everything stencilled on it is really sitting on the glass and the ramp's
  # numbers hold.  Give the terminal a few more rows and the conduit lights up
  # underneath, and a meaning-colour -- the mood's purple, the bond's warm --
  # drops to about 2:1 on lit steel.  The colour is the meaning and is not
  # given up: it is lifted toward white by as much as the ground under it is
  # bright, and by nothing at all when that ground is the glass.
  local -i x=$1 y=$2 col=$3 k base bg bs
  local -F f
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  k=$(( base+y*TCOLS+x )); bg=${GB[$k]:--1}; (( bg<0 )) && bg=$GLASS
  bs=$(( ((bg>>16)&255) + ((bg>>8)&255) + (bg&255) ))
  if (( bs > 120 )); then
    f=$(( (bs-120)/250.0 )); (( f>0.55 )) && f=0.55
    cmix $col $WHITE $f; REPLY=$CM
  else REPLY=$col; fi
  return 0
}

xg_room_vitals() {   # the four vitals, stencilled straight onto the hull band
  # (row 1 · the conduit's own steel is their ground) · label, five cells, the
  # number · each in its meter's colour, dropping to red when it runs low.
  local -i x=14 i v col fill j lbc dimc
  local -a NL NV NC
  NL=(HEALTH FOOD MOOD BOND)
  NV=(${XG[health]:-0} ${XG[food]:-0} ${XG[mood]:-0} ${XG[bond]:-0})
  NC=($XG_OK $XG_FG $PURPLE $XG_WARM)
  cmix $GREY $CYAN 0.40; cshade $CM 1.05; lbc=$CS
  cshade $GREY 0.45; dimc=$CS
  for (( i=0; i<4; i++ )); do
    v=${NV[$i]}; (( v<0 )) && v=0; (( v>100 )) && v=100
    col=${NC[$i]}; (( v<30 )) && { cshade $RED 1.2; col=$CS; }
    xg_lift_for $x 1 $col; col=$REPLY
    v_text $x 1 "${NL[$i]}" $lbc
    x=$(( x+${#NL[$i]}+1 ))
    fill=$(( (v*5+50)/100 ))
    for (( j=0; j<5; j++ )); do
      if (( j<fill )); then v_put $x 1 '▰' $col
      else v_put $x 1 '▱' $dimc; fi
      x=$(( x+1 ))
    done
    v_text $(( x+1 )) 1 "$v" $col
    x=$(( x+2+${#v}+2 ))
  done
  return 0
}

xg_panel() {   # xg_panel X Y W H TITLE [RIGHT]
  (( XI_LO )) || xg_ink
  v_box $1 $2 $3 $4 $XG_DIM $GLASS round
  v_text $(( $1 + 2 )) $2 " $5 " $AMBER $GLASS
  [[ -n "${6:-}" ]] && {
    # A RULE MAY BE FAINT · A WORD MAY NOT.  The box is furniture and keeps the
    # dim it has always had; the caption sitting in it is something to read, so
    # it comes off the ramp at the floor rather than out of the driver's DIM.
    local r=" $6 "
    v_text $(( $1 + $3 - 3 - ${#r} + 1 )) $2 "$r" $XI_LO $GLASS
  }
  return 0
}
xg_meter() {   # xg_meter X Y W LABEL VAL COL — a labelled 0..100 bar
  local -i x=$1 y=$2 w=$3 val=$5 col=$6 i fill bx; local lbl="$4"
  (( val<0 ))&&val=0; (( val>100 ))&&val=100; fill=$(( val*w/100 ))
  v_text $x $y "${(r:6:)lbl}" $XG_LBL $GLASS
  bx=$(( x + 7 ))
  cshade $GREY 0.35
  for (( i=0;i<w;i++ )); do
    if (( i<fill )); then v_put $(( bx+i )) $y '▰' $col $GLASS
    else v_put $(( bx+i )) $y '▱' $CS $GLASS; fi
  done
  v_text $(( bx+w+1 )) $y "$val" $col $GLASS
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# CARE · what the keys do to the animal · every event lands in the log
# ══════════════════════════════════════════════════════════════════════════
# A first, faithful cut of the OLD act_* verbs: the bowl and the bond move on
# the same numbers and rate-limits the original used (groom cools down, treats
# cap at three, a cat can DENY a pet when it has had enough).  The bowl/pantry
# intermediates and the emotion that consumes them arrive with the engine; for
# now a key moves its vital directly and the log speaks, which is the loop.
typeset -ga XG_LOG_T XG_LOG_G XG_LOG_C; typeset -gi XG_LOG_N=0
xg_log() {   # xg_log TEXT [TAG] [COL] — newest first
  local t="$1" g="${2:-}"; local -i c=${3:-$XG_LBL}
  XG_LOG_T=("$t" "${XG_LOG_T[@]}"); XG_LOG_G=("$g" "${XG_LOG_G[@]}"); XG_LOG_C=($c "${XG_LOG_C[@]}")
  XG_LOG_N=${#XG_LOG_T[@]}
  (( XG_LOG_N>24 )) && { XG_LOG_T=("${(@)XG_LOG_T[0,23]}"); XG_LOG_G=("${(@)XG_LOG_G[0,23]}"); XG_LOG_C=("${(@)XG_LOG_C[0,23]}"); XG_LOG_N=24; }
  return 0
}
xg_vadd() { local -i v=$(( ${XG[$1]:-0}+$2 )); (( v>100 ))&&v=100; (( v<0 ))&&v=0; XG[$1]=$v }
xg_act_feed() {
  (( ${XG[food]:-0}>=96 )) && { xg_log 'the bowl is already full' '' $GREY; snd no; return 0; }
  if (( ${XG_HOUSE[pantry]:-0} <= 0 )); then
    xg_pick 'out of kibble · the store sells it' 'the pantry is bare · see [O]' 'no kibble.  the store awaits'
    xg_log "$REPLY" '' $AMBER; snd no; return 0
  fi
  XG_HOUSE[pantry]=$(( ${XG_HOUSE[pantry]:-0}-1 ))
  if [[ "${XG_HOUSE[kibble]:-}" == fine ]]; then
    xg_vadd food 26; xg_vadd mood 2; xg_log 'the fine kibble · gone in seconds' 'FOOD +26' $CYAN
  else
    xg_vadd food 22; xg_log 'kibble from the pantry into the bowl' 'FOOD +22' $CYAN
  fi
  snd pick; return 0
}
xg_act_water() {
  (( ${XG[water]:-0}>=98 )) && { xg_log 'the water is already fresh' '' $GREY; snd no; return 0; }
  XG[water]=100; xg_log 'the water bowl, freshened' 'HYD full' $CYAN; snd pick; return 0
}
xg_act_groom() {
  if (( ${XG[last_groom]:-0}>0 && XG_NOW-${XG[last_groom]:-0}<1800 )); then
    xg_vadd coat 4; xg_log 'a few more strokes of the brush' 'COAT +4' $CYAN
  else
    xg_vadd coat 15; xg_vadd bond 1; xg_log 'groomed · a hairball prevented' 'COAT +15' $CYAN
  fi
  XG[last_groom]=$XG_NOW; snd pick; return 0
}
xg_act_treat() {
  (( ${XG[treats_today]:-0}>=3 )) && { xg_pick 'the treat economy has limits' 'no more treats today · policy' 'the treat ration is spent'; xg_log "$REPLY" '' $AMBER; snd no; return 0; }
  XG[treats_today]=$(( ${XG[treats_today]:-0}+1 )); XG[c_treats]=$(( ${XG[c_treats]:-0}+1 )); XG[credits]=$(( ${XG[credits]:-0}+1 ))
  xg_vadd bond 5; xg_vadd mood 8; xg_vadd food 4
  xg_log 'a treat · accepted with dignity' 'BOND +5' $PURPLE; snd mew; return 0
}
xg_act_play() { xg_lz_start; }    # [P] · the red dot (the house economy, below)
xg_act_scoop() { XG[box]=0; xg_log 'the box, scooped' 'CLEAN' $LIME; snd pick; return 0 }
xg_act_nap() {
  if (( ${XG[pep]:-0}<55 )); then xg_vadd pep $(( ${XG_HOUSE[nbed]:-1} >= 2 ? 37 : 30 )); XG[c_naps]=$(( ${XG[c_naps]:-0}+1 )); xg_log 'curled up · a suggestion accepted' 'PEP ++' $CYAN
  else xg_log 'a suggestion · declined, of course' '' $GREY; snd no; fi
  return 0
}
xg_act_pet() {
  if (( ${XG[overstim]:-0}>2 )); then
    xg_log 'a DENIED · that is quite enough of that' '' $AMBER; snd no
    XG[overstim]=$(( ${XG[overstim]:-0}+1 )); return 0
  fi
  if (( XG_NOW-${XG[overstim_at]:-0}<300 )); then XG[overstim]=$(( ${XG[overstim]:-0}+1 )); else XG[overstim]=1; fi
  XG[overstim_at]=$XG_NOW
  if (( ${XG[last_pet]:-0}==0 || XG_NOW-${XG[last_pet]:-0}>600 )); then
    xg_vadd bond 2; XG[c_pets]=$(( ${XG[c_pets]:-0}+1 )); XG[credits]=$(( ${XG[credits]:-0}+1 ))
    xg_log 'a slow blink · a low purr' 'BOND +2' $PURPLE
  else
    xg_log 'a nudge into your hand' '' $GREY
  fi
  XG[last_pet]=$XG_NOW; snd mew; return 0
}
xg_act_vet() {   # [V] on STATS · the ship doctor · 45 c, but never a wall
  local -i h=${XG[health]:-100} cr=${XG[credits]:-0}
  if (( h >= 82 )); then xg_log 'the vet finds nothing to fix · robust as an ox' '' $LIME; snd no; return 0; fi
  if (( cr >= 45 )); then
    XG[credits]=$(( cr-45 )); xg_vadd health 40; xg_log "the vet · 45 c · a clean bill, and ${XG[name]:-it} is mending" 'HEALTH ++' $LIME; snd pick
  elif (( h < 45 )); then
    xg_vadd health 30; xg_log "the vet treats ${XG[name]:-it} anyway · pay when you can" 'HEALTH +' $AMBER; snd pick
  else
    xg_log 'not enough credits for the vet · 45 c · good care earns them' '' $AMBER; snd no
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# MENU · the machine's own landing, the way every cabinet in the suite has one
# ══════════════════════════════════════════════════════════════════════════
xg_draw_menu() {   # the four rooms of the cabinet, the resident on its stage, and what the house has
  # THE LIST, THE STAGE, THE PARTICULARS -- SYSTEM's page, in this machine's
  # own terms.  The cabinet's four rooms up top, each with its reading and a
  # picture of it; under them the card's own stage -- the resident in its
  # spotlight, its six vitals either side, its plate and its papers -- with
  # what it most wants said on the frame; on a tall wide glass the three
  # shelves under the stage (what has happened lately, the room, the roster);
  # and along the foot the animal's particulars, or on the cabinet's glass,
  # where the stage needs the rows, the few that matter most on the stage's
  # own frame.  The still part is painted once per reading of the animal and
  # kept; the cursor's band, the blink and whatever rises off it are live.
  xg_menu_geom
  xg_tc_key
  xg_menu_key
  glass_cached "xg.menu|$XTKEY|$XG_MPK|${XG_A[behavior]:-}|$CAPTION|$XG_MN_SIG" xg_menu_base
  xg_menu_rows
  if [[ "$XG_TC_SIG" == "$XG_MN_SIG" ]]; then xg_stage_live $XG_NOW 0
  else GLASS_KEY=''; fi                          # the stage was painted somewhere else since · next frame paints it here again
  return 0
}
typeset -gi XG_MN_PX=2 XG_MN_PW=102 XG_MN_PY=3 XG_MN_PH=6 XG_MN_BY=10 XG_MN_BH=18 XG_MN_FY=24 XG_MN_SPH=11
typeset -gi XG_MN_TY=0 XG_MN_TH=0 XG_MN_R1=0 XG_MN_WIDE=0
typeset -g  XG_MN_SIG='' XG_TC_SIG=''
xg_menu_geom() {   # where the list page puts things on this glass -> XG_MN_*
  # THE MAP, SYSTEM's: the list three rows down, the particulars' rule seven
  # rows up from the foot of the cabinet's glass and six up from the whole
  # window's, the stage between them with a row of air either side -- the
  # animal at its own pixels where there are the rows for it -- and on a wide
  # glass with the rows to spare, the three shelves under the stage.  A glass
  # too short for the stage and the particulars both (the cabinet's own) gives
  # the stage every row down to the keys, and the particulars ride its frame.
  local -i top bot avail inner need lead sh
  XG_MN_WIDE=0; (( SCR_W > 120 )) && XG_MN_WIDE=1
  if (( XG_MN_WIDE )); then XG_MN_PX=3; XG_MN_PW=$(( SCR_W - 6 )); XG_MN_R1=$(( SCR_H - 6 ))
  else                      XG_MN_PX=2; XG_MN_PW=$(( SCR_W - 4 )); XG_MN_R1=$(( SCR_H - 7 )); fi
  XG_MN_PY=3; XG_MN_PH=$(( XG_PAGES + 2 ))
  top=$(( XG_MN_PY + XG_MN_PH + 1 )); bot=$(( XG_MN_R1 - 2 )); avail=$(( bot - top + 1 ))
  xg_tc_size
  XG_MN_TH=0
  if (( XG_MN_WIDE && XG_TC_PH == 17 && avail >= 23 + 1 + 8 )); then
    sh=23; XG_MN_TH=$(( avail - sh - 1 ))
  elif (( XG_MN_WIDE && avail >= 17 + 1 + 7 )); then
    XG_TC_PH=11; XG_TC_K=1.0; XG_TC_CAP=22; sh=17; XG_MN_TH=$(( avail - sh - 1 ))
  elif (( XG_TC_PH == 17 && avail >= 23 )); then
    sh=23
  elif (( avail >= 17 )); then
    XG_TC_PH=11; XG_TC_K=1.0; XG_TC_CAP=22; sh=17
  else
    # the cabinet's glass · the stage down to the keys, no particulars under it
    XG_TC_PH=11; XG_TC_K=1.0; XG_TC_CAP=22
    XG_MN_R1=0; bot=$(( SCR_H - 3 )); avail=$(( bot - top + 1 )); sh=$avail
  fi
  (( XG_MN_TH > 12 )) && XG_MN_TH=12
  # A STAGE WITHOUT SHELVES UNDER IT takes the rows there are, a few more of
  # them light coming down over the animal, rather than standing in air
  if (( XG_MN_R1 && ! XG_MN_TH )); then (( avail > sh + 6 )) && sh=$(( sh + 6 )) || sh=$avail; fi
  XG_MN_SPH=$XG_TC_PH
  lead=$(( (avail - sh - (XG_MN_TH ? XG_MN_TH + 1 : 0)) / 2 )); (( lead < 0 )) && lead=0
  XG_MN_BY=$(( top + lead )); XG_MN_BH=$sh
  XG_MN_TY=$(( XG_MN_BY + sh + 1 ))
  # THE FLOOR LOW IN THE FRAME, the plate and the papers under it · the room
  # the light comes down through is over it
  inner=$(( XG_MN_BH - 2 )); need=$(( XG_MN_SPH + 4 ))
  lead=$(( inner - need )); (( lead < 0 )) && lead=0
  XG_MN_FY=$(( XG_MN_BY + 1 + lead + 1 + XG_MN_SPH ))
  (( XG_MN_FY > XG_MN_BY + XG_MN_BH - 4 )) && XG_MN_FY=$(( XG_MN_BY + XG_MN_BH - 4 ))
  XG_MN_SIG="${SCR_W}x${SCR_H}|$XG_MN_BY|$XG_MN_BH|$XG_MN_FY|$XG_MN_SPH|$XG_MN_TH"
  return 0
}
typeset -g XG_MPK=''
xg_menu_key() {   # xg_menu_key -> XG_MPK · what the list page shows besides the animal: the house, the day, the roster, the log
  XG_MPK="${XG_NPETS}|${XG_HOUSE[own]:-}|${XG_HOUSE[pantry]:-0}|${XG_HOUSE[bed]:-0}|${XG_HOUSE[bowl]:-0}|${XG_HOUSE[style]:-}|${XG_HOUSE[litter]:-}"
  XG_MPK+="|${XG[box]:-0}|${XG[streak]:-0}|${XG[treats_today]:-0}|${XG[catches_today]:-0}|${XG[c_pets]:-0}|${XG[c_treats]:-0}|${XG[c_gifts]:-0}"
  XG_MPK+="|${XG_LOG_N:-0}|${XG_LOG_T[0]:-}|${XG[tname]:-}|${XG[eyes]:-}"
  return 0
}
xg_menu_base() {   # the list page's still part · the band, the list, the stage, the shelves, the particulars
  local -i cx bx bw x i fy tw tx
  local s o ch l r
  (( XI_LO )) || xg_ink
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  xg_head MENU 0 \
     IN "${XG[name]:-—}" $XG_WHITE \
     HEALTH "${XG[health]:-0}" $XG_OK \
     CREDITS "${XG[credits]:-0}" $XG_FG
  # NO CHOOSE ONE on the list's rule, and its rows right under it, as SYSTEM's
  xg_panel $XG_MN_PX $XG_MN_PY $XG_MN_PW $XG_MN_PH 'THE CABINET'
  xg_menu_rows
  # ── the stage, in a frame of its own, black, the way the card's CRT is ──
  bx=2; bw=$(( SCR_W - 4 )); cx=$(( SCR_W / 2 ))
  cshade $PURPLE 0.42; v_box $bx $XG_MN_BY $bw $XG_MN_BH $CS $BLACK round
  v_fill $(( bx + 1 )) $(( XG_MN_BY + 1 )) $(( bw - 2 )) $(( XG_MN_BH - 2 )) ' ' $GREY $BLACK
  if (( XG_FRESH )); then s=' INTAKE NIGHT '; else s=' THE RESIDENT '; fi
  v_text $(( bx + 2 )) $XG_MN_BY "$s" $AMBER $BLACK
  xg_tc_status
  s=" $XTS "; v_text $(( bx + bw - 2 - ${#s} )) $XG_MN_BY "$s" $XTC $BLACK
  # THE FLOOR ACROSS THE STAGE, faintly, so the dark over it is a room's
  cmix $BLACK $PURPLE 0.10; v_hline $(( bx + 1 )) $XG_MN_FY $(( bw - 2 )) ' ' $GREY $CM
  # and the light coming down from the frame's ceiling, however tall the room
  xg_stage_paint $cx $XG_MN_FY $XG_MN_SPH $(( XG_MN_BY + 1 )) $(( XG_MN_FY - XG_MN_BY - 1 ))
  XG_TC_SIG="$XG_MN_SIG"
  xg_stage_vitals $cx $XG_MN_FY $XG_MN_SPH
  # THE PLATE, spaced capitals between two rising wings, and the papers under it
  if (( XG_FRESH )); then s='INTAKE NIGHT'; else s="${XG[name]:-}"; s="${s:u}"; fi
  o=''
  for (( i = 0; i < ${#s}; i++ )); do
    ch="${s[$i,$i]}"
    if [[ "$ch" == ' ' ]]; then o+='  '; else o+="${o:+ }$ch"; fi
  done
  o="▁▂▃▄▅▆▇█  $o  █▇▆▅▄▃▂▁"
  cmix $AMBER $PINK 0.5; cshade $CM 0.9
  x=$(( cx - ${#o} / 2 )); v_text $x $(( XG_MN_FY + 1 )) "$o" $CS $BLACK
  xg_stage_papers
  cshade $GREY 1.05; v_text $(( cx - ${#REPLY} / 2 )) $(( XG_MN_FY + 2 )) "$REPLY" $CS $BLACK
  # WHERE THERE IS NO ROOM FOR THE PARTICULARS, the few that matter most ride
  # the stage's own frame, the way the scope's ends are named on SYSTEM's
  if (( ! XG_MN_R1 && ! XG_FRESH )); then
    xg_menu_today; l=" $REPLY "
    xg_menu_house_short; r=" $REPLY "
    cshade $GREY 0.86
    v_text $(( bx + 2 )) $(( XG_MN_BY + XG_MN_BH - 1 )) "$l" $CS $BLACK
    v_text $(( bx + bw - 2 - ${#r} )) $(( XG_MN_BY + XG_MN_BH - 1 )) "$r" $CS $BLACK
  fi
  if (( XG_MN_TH )); then
    tw=$(( (bw - 4) / 3 )); tx=$bx
    xg_shelf_log    $tx $XG_MN_TY $tw $XG_MN_TH
    xg_shelf_room   $(( tx + tw + 2 )) $XG_MN_TY $tw $XG_MN_TH
    xg_shelf_roster $(( tx + 2 * (tw + 2) )) $XG_MN_TY $(( bw - 2 * (tw + 2) )) $XG_MN_TH
  fi
  (( XG_MN_R1 )) && xg_menu_facts
  app_nav '▴ ▾' choose '⏎' open '[⎋]' out
  return 0
}

# ── the list ──────────────────────────────────────────────────────────────
typeset -g  XG_MI_KEY=''
typeset -gi XG_MI_DON=0 XG_MI_DOFF=0 XG_MI_ROFF=0 XG_MI_OFF=0 XG_MI_EMP=0 XG_MI_BAD=0 XG_MI_WARES=0
typeset -gi XG_MENU_READ=17                    # the readings' column, as wide as the widest of them
xg_menu_inks() {   # the list page's inks, worked out when the palette is new
  local key="$XG_LBL|$XG_WHITE|$XG_FG|$GREY|$RED|$AMBER"
  [[ "$key" == "$XG_MI_KEY" ]] && return 0
  XG_MI_KEY="$key"
  cmix $XG_LBL $XG_WHITE 0.35; XG_MI_DON=$CM
  cshade $XG_LBL 0.82;         XG_MI_DOFF=$CS
  cshade $XG_FG 0.74;          XG_MI_ROFF=$CS
  cshade $GREY 0.36;           XG_MI_OFF=$CS
  cshade $GREY 0.62;           XG_MI_EMP=$CS
  cmix $RED $AMBER 0.35;       XG_MI_BAD=$CM
  cshade $GREY 0.70;           XG_MI_WARES=$CS   # a ware the house already has
  return 0
}
xg_menu_read() {   # xg_menu_read IDX -> XMR, the one live thing that page is about
  XMR=''
  case "${XG_PV[$1]}" in
    home)  XMR="${XG[name]:-—} · ${XG[stage]:-}" ;;
    stats) XMR="$XG_NPETS signed for" ;;
    store) if (( ${XG[credits]:-0} == 1 )); then XMR='1 credit'; else XMR="${XG[credits]:-0} credits"; fi ;;
    adopt) XMR='four waiting' ;;
  esac
  return 0
}
xg_menu_rows() {   # the four rows · the band under the cursor glides, so they are live
  local -i i j n y px=$XG_MN_PX pw=$XG_MN_PW py=$XG_MN_PY on bg col xr vx dw
  local read
  local -F pos sk
  local -a xs ts ks
  xg_menu_inks
  xg_menu_pics
  # THE COLUMNS, SYSTEM's · the reading ends three in from the box's right
  # edge, its picture in a ten-cell column just before it, and the
  # description has the rest of the row
  xr=$(( px + pw - 3 )); vx=$(( xr - XG_MENU_READ - 10 )); dw=$(( vx - 2 - (px + 17) ))
  mo_ease "xg.menu" $XG_MROW $XG_NOW $MO_CURSOR; pos=$MV
  for (( i = 0; i < XG_PAGES; i++ )); do
    y=$(( py + 1 + i ))
    sk=$(( 1.0 - abs(i - pos) )); (( sk < 0.0 )) && sk=0.0
    on=0; (( sk >= 0.5 )) && on=1
    if (( sk > 0.001 )); then cmix $GLASS $XG_DIM $(( 0.55 * sk )); bg=$CM; else bg=$GLASS; fi
    v_fill $(( px + 1 )) $y $(( pw - 2 )) 1 ' ' $GREY $bg
    if (( on )); then cmix $WHITE $LIME 0.3; v_put $(( px + 2 )) $y '▸' $CM $bg
    else                                     v_put $(( px + 2 )) $y ' ' $XG_DIM $bg; fi
    if (( on )); then col=$AMBER; else cshade $AMBER 0.6; col=$CS; fi
    v_text $(( px + 4 )) $y "[${XG_PK[$i]}]" $col $bg
    (( on )) && col=$XG_WHITE || col=$XG_LBL
    v_text $(( px + 8 )) $y "${(r:8:)XG_PN[$i]}" $col $bg
    (( on )) && col=$XG_MI_DON || col=$XG_MI_DOFF
    xg_ell "${XG_PD[$i]}" $dw
    v_text $(( px + 17 )) $y "$REPLY" $col $bg
    if [[ -n "${XG_MP_X[$i]:-}" ]]; then
      xs=(${=XG_MP_X[$i]}); ts=("${(@ps:\t:)XG_MP_T[$i]}")
      if (( on )); then ks=(${=XG_MP_K1[$i]}); else ks=(${=XG_MP_K0[$i]}); fi
      n=${#xs[@]}
      for (( j = 0; j < n; j++ )); do v_text $(( vx + xs[j] )) $y "${ts[$j]}" ${ks[$j]} $bg; done
    fi
    xg_menu_read $i; read="$XMR"
    (( ${#read} > XG_MENU_READ )) && { xg_ell "$read" $XG_MENU_READ; read="$REPLY"; }
    if (( on )); then col=$XG_FG; else col=$XG_MI_ROFF; fi
    v_text $(( xr - ${#read} + 1 )) $y "$read" $col $bg
  done
  return 0
}

# ── each row's picture · the ten cells before its reading ──────────────────
# HOME the six vitals, a bar each, in the stage meters' own inks; STORE the
# nine wares, lit where the credits reach and pale where the house already
# has them; ADOPT the four waiting; STATS a mark an animal signed for, in the
# ink its health is.  Worked out again only when what they show has changed.
typeset -g  XG_MP_GEN=''
typeset -ga XG_MP_X XG_MP_T XG_MP_K0 XG_MP_K1 XMS_X XMS_T XMS_K0 XMS_K1
typeset -ga XG_LVL; XG_LVL=('' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
typeset -gi XMK0=0 XMK1=0
xg_mp_ink() { XMK1=$1; cshade $1 0.78; XMK0=$CS; return 0 }
xg_mp_seg() {   # xg_mp_seg X TEXT ON OFF — a run of a picture, joined to the last one when it carries on in the same inks
  local -i n=${#XMS_X[@]}
  if (( n )) && (( XMS_K1[n - 1] == $3 && XMS_K0[n - 1] == $4 && XMS_X[n - 1] + ${#XMS_T[n - 1]} == $1 )); then
    XMS_T[$(( n - 1 ))]+="$2"; return 0
  fi
  XMS_X+=($1); XMS_T+=("$2"); XMS_K1+=($3); XMS_K0+=($4)
  return 0
}
xg_level_ink() {   # xg_level_ink V -> XLK · a vital's ink, the stage meters' own
  if   (( $1 >= 60 )); then XLK=$LIME
  elif (( $1 >= 30 )); then XLK=$AMBER
  else                      XLK=$XG_MI_BAD; fi
  return 0
}
typeset -gi XLK=0
xg_menu_pics() {
  local gen="$XTKEY|$XG_MPK|$XG_MI_KEY"
  [[ "$XG_MP_GEN" == "$gen" ]] && return 0
  XG_MP_GEN="$gen"
  local -i i j n v p w
  local k
  local -a ink4
  XG_MP_X=(); XG_MP_T=(); XG_MP_K0=(); XG_MP_K1=()
  for (( i = 0; i < XG_PAGES; i++ )); do
    XMS_X=(); XMS_T=(); XMS_K0=(); XMS_K1=()
    case "${XG_PV[$i]}" in
      home)
        (( XG_FRESH )) || {
          j=0
          for k in health food water mood bond pep; do
            v=${XG[$k]:-0}; (( v < 0 )) && v=0; (( v > 100 )) && v=100
            p=$(( (v * 8 + 50) / 100 )); (( p < 1 )) && p=1
            xg_level_ink $v; xg_mp_ink $XLK
            xg_mp_seg $(( 4 + j )) "${XG_LVL[$p]}" $XMK1 $XMK0
            (( j++ ))
          done
        } ;;
      store)
        for (( j = 0; j < ${#XG_ST_ID[@]} && j < 10; j++ )); do
          xg_store_have $j
          if [[ "$REPLY2" != ok ]]; then xg_mp_seg $(( 1 + j )) '◆' $XG_MI_EMP $XG_MI_OFF
          elif (( ${XG[credits]:-0} >= ${XG_ST_COST[$j]:-999999} )); then xg_mp_ink $AMBER; xg_mp_seg $(( 1 + j )) '◆' $XMK1 $XMK0
          else xg_mp_seg $(( 1 + j )) '◇' $XG_MI_EMP $XG_MI_OFF; fi
        done ;;
      adopt)
        ink4=($CYAN $LIME $PINK $AMBER)
        for (( j = 0; j < 4; j++ )); do
          xg_mp_ink ${ink4[$j]}; xg_mp_seg $(( 3 + 2 * j )) '◆' $XMK1 $XMK0
        done ;;
      stats)
        xg_menu_roster; n=${#XMR_NM[@]}; (( n > 5 )) && n=5; w=$(( 2 * n - 1 ))
        for (( j = 0; j < n; j++ )); do
          xg_level_ink ${XMR_HP[$j]:-0}; xg_mp_ink $XLK
          xg_mp_seg $(( 10 - w + 2 * j )) '●' $XMK1 $XMK0
        done ;;
    esac
    XG_MP_X+=("${(j: :)XMS_X[@]}"); XG_MP_T+=("${(pj:\t:)XMS_T[@]}")
    XG_MP_K1+=("${(j: :)XMS_K1[@]}"); XG_MP_K0+=("${(j: :)XMS_K0[@]}")
  done
  return 0
}
typeset -ga XMR_NM XMR_SP XMR_ST XMR_HP
xg_menu_roster() {   # xg_menu_roster -> XMR_* · every animal signed for, the resident first: name, species, stage, health
  # READ STRAIGHT OFF THE SAVE, the resident off its own keys · nothing here
  # deals a coat or touches the paperwork (xg_roster_scan borrows the
  # resident's, which a list page has no business doing)
  local -i sl st
  local -F bnf days
  local nm sp sd bn sw v
  local -a order
  XMR_NM=(); XMR_SP=(); XMR_ST=(); XMR_HP=()
  order=($XG_ACTIVE)
  for (( sl = 0; sl < XG_NPETS; sl++ )); do (( sl != XG_ACTIVE )) && order+=($sl); done
  for sl in "${order[@]}"; do
    if (( sl == XG_ACTIVE )); then
      nm="${XG[name]:-}"; sp="${XG[species]:-cat}"; sd="${XG[seed]:-61653}"; bn="${XG[born]:-0}"; sw="${XG[span]:-}"
      XMR_HP+=(${XG[health]:-0})
    else
      nm="${SAVE[xenogotchi.pets.$sl.name]:-}"; [[ -n "$nm" ]] || continue
      sp="${SAVE[xenogotchi.pets.$sl.species]:-cat}"; sd="${SAVE[xenogotchi.pets.$sl.seed]:-61653}"
      bn="${SAVE[xenogotchi.pets.$sl.born]:-0}"; sw="${SAVE[xenogotchi.pets.$sl.span]:-}"
      v="${SAVE[xenogotchi.pets.$sl.health]:-0}"; [[ "$v" == <-> ]] || v=0
      XMR_HP+=($v)
    fi
    [[ "$sd" == <-> ]] || sd=61653
    bnf=0.0; [[ "$bn" == <->(|.<->) ]] && bnf=$bn
    if (( bnf > 0.0 )); then days=$(( (${EPOCHSECONDS:-0} - bnf) / 86400.0 )); else days=0.0; fi
    (( days < 0.0 )) && days=0.0
    xg_stage_of $days $sd "$sp" "$sw"; st=$REPLY; xg_stage_nm $st "$sp"
    XMR_NM+=("$nm"); XMR_SP+=("$sp"); XMR_ST+=("$REPLY")
  done
  return 0
}

# ── what rides the stage's frame on the cabinet's glass, and the particulars ──
xg_menu_today() {   # -> REPLY · the day, in a few words
  REPLY="DAY ${XG[day]:-1} · STREAK ${XG[streak]:-0}"
  return 0
}
xg_menu_house_short() {   # -> REPLY · the room, in a few words
  local -i b=${XG[box]:-0}
  if (( b >= 80 )); then REPLY='BOX FULL'; else REPLY="BOX ${b}%"; fi
  REPLY+=" · PANTRY ${XG_HOUSE[pantry]:-0}"
  return 0
}
xg_menu_n() { if (( $1 == 1 )); then REPLY="1 $2"; else REPLY="$1 ${2}s"; fi; return 0 }   # xg_menu_n N WORD -> REPLY · "1 pet", "9 treats"
xg_menu_facts() {   # a rule, and three rows of two · what this animal is, and how the care is going
  local -i i c1l=2 c1v=11 c2l c2v w1 w2 y
  local s
  local -a k1 v1 k2 v2
  if (( XG_MN_WIDE )); then c2l=$(( SCR_W / 2 )); else c2l=56; fi
  c2v=$(( c2l + 9 )); w1=$(( c2l - c1v - 2 )); w2=$(( SCR_W - c2v - 2 ))
  v_hline 0 $XG_MN_R1 $SCR_W '─' $XG_DIM
  if (( XG_FRESH )); then
    xg_litter_code
    k1=(INTAKE TONIGHT HOUSE); v1=("litter $REPLY" 'four arrivals · one goes home' "${XG_NPETS} signed for")
    k2=(CREDITS PANTRY ROOM); v2=("${XG[credits]:-0}" "kibble ×${XG_HOUSE[pantry]:-0}" '')
  else
    s="${XG[tname]:-}"; [[ -n "${XG[temper]:-}" ]] && s+="${s:+ · }${XG[temper]}"
    k1=(TEMPER);  v1=("${s:-—}")
    k1+=(EYES);   v1+=("${XG[eyes]:-—}")
    s='—'
    if [[ "${XG[born]:-}" == <->(|.<->) ]]; then strftime -s s '%d %b %Y' ${XG[born]%.*} 2>/dev/null || s='—'; s="${s#0}"; fi
    k1+=(BORN);   v1+=("$s · day ${XG[day]:-1} here")
    k2=(TODAY);   v2=("streak ${XG[streak]:-0} · treats ${XG[treats_today]:-0} of 3 · catches ${XG[catches_today]:-0} of 3")
    xg_menu_n ${XG[c_pets]:-0} pet; s="$REPLY"; xg_menu_n ${XG[c_treats]:-0} treat; s+=" · $REPLY"
    xg_menu_n ${XG[c_gifts]:-0} gift; s+=" · $REPLY"
    k2+=('SO FAR'); v2+=("$s")
    xg_litter_code
    k2+=(LITTER); v2+=("$REPLY · four waiting at [A]")
  fi
  for (( i = 0; i < 3; i++ )); do
    y=$(( XG_MN_R1 + 1 + i ))
    v_text $c1l $y "${(r:8:)k1[$i]}" $XG_LBL
    xg_ell "${v1[$i]}" $w1; v_text $c1v $y "$REPLY" $XG_FG
    v_text $c2l $y "${(r:8:)k2[$i]}" $XG_LBL
    xg_ell "${v2[$i]}" $w2; v_text $c2v $y "$REPLY" $XG_FG
  done
  return 0
}

# ── the shelves · three instruments under the stage, on a tall wide glass ──
xg_iframe() {   # xg_iframe X Y W H TITLE [RIGHT] — an instrument: black inside, the stage's own ink round it
  local -i x=$1 y=$2 w=$3 h=$4
  local t="$5" rt="${6:-}"
  cshade $PURPLE 0.42; v_box $x $y $w $h $CS $BLACK round 1
  v_text $(( x + 2 )) $y " $t " $AMBER $BLACK
  [[ -n "$rt" ]] && v_text $(( x + w - ${#rt} - 4 )) $y " $rt " $GREY $BLACK
  return 0
}
xg_iquiet() {   # xg_iquiet X Y W H TEXT — a shelf with nothing on it says so, in the middle
  cshade $GREY 0.80
  v_text $(( $1 + ($3 - ${#5}) / 2 )) $(( $2 + ($4 - 1) / 2 )) "$5" $CS $BLACK
  return 0
}
xg_shelf_log() {   # xg_shelf_log X Y W H — what has happened lately, newest first
  local -i x=$1 y=$2 w=$3 h=$4 i n rows tw gw
  local g
  n=${XG_LOG_N:-0}
  xg_iframe $x $y $w $h LATELY
  (( n )) || { xg_iquiet $x $y $w $h 'nothing yet tonight'; return 0 }
  rows=$(( h - 2 ))
  for (( i = 0; i < n && i < rows; i++ )); do
    g="${XG_LOG_G[$i]:-}"; gw=${#g}
    tw=$(( w - 4 - (gw ? gw + 2 : 0) ))
    xg_ell "${XG_LOG_T[$i]}" $tw
    if (( i == 0 )); then v_text $(( x + 2 )) $(( y + 1 + i )) "$REPLY" $XI_HI $BLACK
    else                  v_text $(( x + 2 )) $(( y + 1 + i )) "$REPLY" $XI_LO $BLACK; fi
    (( gw )) && v_text $(( x + w - 2 - gw )) $(( y + 1 + i )) "$g" ${XG_LOG_C[$i]:-$XG_LBL} $BLACK
  done
  return 0
}
xg_shelf_room() {   # xg_shelf_room X Y W H — the room: the box, the cupboard, the toys, the furniture
  local -i x=$1 y=$2 w=$3 h=$4 b r rows i fill vx vw
  local s t
  local -a kl kv kc
  xg_iframe $x $y $w $h 'THE ROOM'
  rows=$(( h - 2 )); vx=$(( x + 15 )); vw=$(( w - 17 ))
  b=${XG[box]:-0}; (( b < 0 )) && b=0; (( b > 100 )) && b=100
  # THE BOX FIRST, on a meter, in the ink of how much it wants doing
  if (( b >= 80 )); then xg_level_ink 0; elif (( b >= 50 )); then xg_level_ink 40; else xg_level_ink 100; fi
  v_text $(( x + 2 )) $(( y + 1 )) 'litter box' $XI_TX $BLACK
  fill=$(( (b + 5) / 10 ))
  _run $fill '▰'; s="$RUN"; _run $(( 10 - fill )) '▱'; t="$RUN"
  (( fill )) && v_text $vx $(( y + 1 )) "$s" $XLK $BLACK
  (( fill < 10 )) && v_text $(( vx + fill )) $(( y + 1 )) "$t" $XI_TRK $BLACK
  if (( b >= 80 )); then s='wants scooping'; else s="${b}%"; fi
  v_text $(( vx + 11 )) $(( y + 1 )) "$s" $XLK $BLACK
  kl=(pantry); kv=("kibble ×${XG_HOUSE[pantry]:-0}"); kc=($XI_TX)
  (( ${XG_HOUSE[pantry]:-0} <= 1 )) && kc[0]=$AMBER
  s=''
  xg_owned yarn    && s+="${s:+ · }yarn ball"
  xg_owned orb     && s+="${s:+ · }hover orb"
  xg_owned pointer && s+="${s:+ · }photon pointer"
  kl+=(toys); kv+=("${s:-none yet · [O] stocks them}"); kc+=($XI_TX)
  kl+=(bed);  kv+=("${XG_BED_NM[${XG_HOUSE[bed]:-0}]:-—}"); kc+=($XI_TX)
  kl+=(dish); kv+=("${XG_DISH_NM[${XG_HOUSE[bowl]:-0}]:-—}"); kc+=($XI_TX)
  xg_core_name "${XG_HOUSE[style]:-std}"; kl+=(core); kv+=("$REPLY · the room burns it"); kc+=($XI_TX)
  for (( i = 0; i < ${#kl[@]} && i + 1 < rows; i++ )); do
    v_text $(( x + 2 )) $(( y + 2 + i )) "${kl[$i]}" $XI_LO $BLACK
    xg_ell "${kv[$i]}" $vw; v_text $vx $(( y + 2 + i )) "$REPLY" ${kc[$i]} $BLACK
  done
  return 0
}
xg_shelf_roster() {   # xg_shelf_roster X Y W H — every animal signed for, the resident first, with its health
  local -i x=$1 y=$2 w=$3 h=$4 i n rows ny fill nw sx mx show
  local s t
  xg_menu_roster; n=${#XMR_NM[@]}
  if (( n == 1 )); then xg_iframe $x $y $w $h 'THE ROSTER' '1 SIGNED FOR'
  else                  xg_iframe $x $y $w $h 'THE ROSTER' "$n SIGNED FOR"; fi
  (( n )) || { xg_iquiet $x $y $w $h 'nobody signed for yet'; return 0 }
  rows=$(( h - 2 )); nw=$(( w - 4 - 2 - 14 - 1 - 14 ))
  (( nw > 14 )) && nw=14; (( nw < 6 )) && nw=6
  sx=$(( x + 4 + nw + 1 )); mx=$(( x + w - 2 - 14 ))
  show=$n; (( n > rows )) && show=$(( rows - 1 ))
  for (( i = 0; i < show; i++ )); do
    ny=$(( y + 1 + i ))
    if (( i == 0 )); then v_put $(( x + 2 )) $ny '⌂' $AMBER $BLACK; fi
    xg_ell "${XMR_NM[$i]}" $nw
    if (( i == 0 )); then v_text $(( x + 4 )) $ny "$REPLY" $XI_HI $BLACK
    else                  v_text $(( x + 4 )) $ny "$REPLY" $XI_TX $BLACK; fi
    xg_ell "${(L)XMR_ST[$i]}" $(( mx - 2 - sx )); v_text $sx $ny "$REPLY" $XI_LO $BLACK
    xg_level_ink ${XMR_HP[$i]:-0}
    fill=$(( (${XMR_HP[$i]:-0} + 5) / 10 ))
    _run $fill '▰'; s="$RUN"; _run $(( 10 - fill )) '▱'; t="$RUN"
    (( fill )) && v_text $mx $ny "$s" $XLK $BLACK
    (( fill < 10 )) && v_text $(( mx + fill )) $ny "$t" $XI_TRK $BLACK
    v_text $(( mx + 11 )) $ny "${(l:3:)XMR_HP[$i]}" $XLK $BLACK
  done
  (( show < n )) && { cshade $GREY 0.72; v_text $(( x + 4 )) $(( y + 1 + show )) "+ $(( n - show )) more" $CS $BLACK; }
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# HOME · THE CORE · the engine room the animal lives in
# ══════════════════════════════════════════════════════════════════════════
# The room is lit by the ship's reactor: a banded containment column at the
# left throws teal light that falls away across the deck into shadow, where an
# the deck takes the light and gives some of it back.  On the FILL screen
# the whole engine room shows; on the fixed FLOAT glass the room is a CLOSE-UP
# on the animal — the column and the ceiling stand off-frame and only their
# light sweeps in.  All of the lighting is baked into the room cache once per
# glass size; per frame only the animal, its shadow, the breathing column and
# the drifting motes are drawn.

xg_mklut() {   # xg_mklut NAME BASE LIGHT MAX — a 17-step banded light ramp
  local nm=$1; local -i base=$2 light=$3; local -F mx=$4; local -i i; local -a tmp; tmp=()
  for (( i=0; i<=16; i++ )); do cmix $base $light $(( mx*i/16.0 )); tmp+=($CM); done
  eval "typeset -ga $nm; $nm=(\"\${tmp[@]}\")"
}

typeset -gA XG_SCRIM
xg_log_scrim() {   # xg_log_scrim Y0 N — a reading band under the log
  # THE LOG IS WRITTEN ON THE DECK, AND THE DECK IS NOT THE SAME EVERYWHERE.
  # The reactor's base and its reflection sit at the deck's bottom-left, and
  # how far right they reach depends on the room's width: at the cabinet's own
  # size they stop short of the log, and on a taller glass they run underneath
  # it, putting the one line you read every visit at 2.06:1 on lit teal.  The
  # ink cannot be lifted out of that -- the brightest possible letter is 4.26:1
  # on it, and a letter mixed that far toward white has lost the colour the
  # line is carrying.  So the ground gives way instead: the two rows the log is
  # written on are tinted down to the dim the log was inked for, whatever is
  # under them, the same read-the-cell-back idiom the contact shadow uses.
  local -i y0=$1 n=$2 x y k gx gy bg tgt ts bs
  local -F t
  local d
  # the deck as it reads at the cabinet's own size, which is what was measured
  tgt=${CORE_DECK[5]:-$GLASS}
  ts=$(( ((tgt>>16)&255) + ((tgt>>8)&255) + (tgt&255) )); (( ts<1 )) && ts=1
  # THE SHADE A GROUND COMES DOWN TO IS REMEMBERED (XG_SCRIM): four hundred
  # cells a frame share a dozen grounds between them, so the mix is worked out
  # once a ground, and the cell is written where it lies (as v_tint clips)
  for (( y=y0; y<y0+n; y++ )); do
    (( y<0 || y>=SCR_H )) && continue
    gy=$(( OY+R_SCR+y )); (( gy<0 || gy>=TROWS )) && continue
    for (( x=1; x<SCR_W-1; x++ )); do
      gx=$(( OX+C_SCR+x )); (( gx<0 || gx>=TCOLS )) && continue
      k=$(( gy*TCOLS+gx ))
      bg=${GB[$k]:-$GLASS}; (( bg<0 )) && continue
      d="${XG_SCRIM[$ts,$bg]:-}"
      if [[ -z "$d" ]]; then
        bs=$(( ((bg>>16)&255) + ((bg>>8)&255) + (bg&255) ))
        if (( bs <= ts )); then d=k            # already at or below the measured dim · keep it
        else t=$(( ts*1.0/bs )); cshade $bg $t; d=$CS; fi   # bring it down to it, keeping its texture
        XG_SCRIM[$ts,$bg]="$d"
      fi
      [[ "$d" == k ]] || GB[$k]=$d
    done
  done
  return 0
}

xg_shadow() {   # xg_shadow CX Y W DARK — a contact shadow on whatever ground
  # is there: reads the cell's own colour back from the glass (the modal's
  # flat-index idiom) and tints it darker, keeping the glyph.
  local -i scx=$1 y=$2 w=$3 x k base bg half
  local -F dk=$4 t
  (( y<0 || y>=SCR_H )) && return 0
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )); half=$(( w/2 )); (( half<1 )) && half=1
  for (( x=scx-half; x<=scx+half; x++ )); do
    (( x<1 || x>=SCR_W-1 )) && continue
    k=$(( base+y*TCOLS+x ))
    bg=${GB[$k]:-$GLASS}; (( bg<0 )) && continue
    t=$(( (x-scx)*1.0/half )); t=$(( dk+(0.97-dk)*t*t ))
    cshade $bg $t; v_tint $x $y $CS
  done
  return 0
}

# ── the palette · steel, energy, warmth · computed once per ROOM STYLE ──
# The store's room styles recolour the reactor's light: the standard core burns
# lime-cyan, EMBER burns amber-red, SYNTH burns magenta.  Everything downstream
# (air, deck, column, motes) follows the glow, so a style is one swap + rebake.
typeset -gi XG_CORE_PAL=0 CR_AIR=0 CR_GLOW=0 CR_HOT=0 CR_E1=0 CR_E2=0 CR_E1B=0 \
            CR_CASE=0 CR_CASE_HI=0 CR_RING=0 CR_DECK=0 \
            CR_HAZ=0 CR_HAZD=0
typeset -gi XSG=0 XSA=0 XSD=0
xg_style_glow() {   # xg_style_glow STYLE — the light a room style burns · XSG/XSA/XSD
  # (glow, air, deck) · the one place a style's colours are written down, so
  # the room and the store's little preview stage can never disagree.
  (( ${+MAGENTA} )) || { _pack 232 72 168; typeset -gi MAGENTA=$PK; }
  case "$1" in
    ember) cmix $AMBER $RED 0.35;     XSG=$CM; _pack 26 12 16; XSA=$PK; _pack 24 12 14; XSD=$PK ;;
    synth) cmix $MAGENTA $PURPLE 0.3; XSG=$CM; _pack 20 8 30;  XSA=$PK; _pack 18 8 26;  XSD=$PK ;;
    glacier) cmix $CYAN $WHITE 0.45; XSG=$CM; _pack 8 16 30; XSA=$PK; _pack 8 14 26; XSD=$PK ;;
    *)     cmix $LIME $CYAN 0.5;      XSG=$CM; _pack 10 12 30; XSA=$PK; _pack 10 12 24; XSD=$PK ;;
  esac
  return 0
}
xg_core_pal() {
  local -i c
  xg_style_glow "${XG_HOUSE[style]:-}"
  CR_GLOW=$XSG; CR_AIR=$XSA; CR_DECK=$XSD
  cmix $CR_GLOW $WHITE 0.55; CR_HOT=$CM
  cmix $CR_GLOW $WHITE 0.20; CR_E1=$CM
  cshade $CR_GLOW 0.72;      CR_E2=$CS
  cmix $CR_HOT $CR_E1 0.55;  CR_E1B=$CM
  cmix $GREY $CYAN 0.3; c=$CM; cshade $c 0.5; CR_CASE=$CS
  cshade $CR_CASE 1.7;       CR_CASE_HI=$CS
  cshade $CR_CASE 1.2;       CR_RING=$CS
  cshade $AMBER 0.8;         CR_HAZ=$CS
  _pack 22 18 10;            CR_HAZD=$PK
  xg_mklut CORE_AIR  $CR_AIR  $CR_GLOW 0.48
  xg_mklut CORE_DECK $CR_DECK $CR_GLOW 0.58
  return 0
}

# ── PROPS · furniture drawn through the SAME sprite pipeline as the animal —
# a material grid, the top-right sun, folded cells — so the whole room speaks
# one language.  Each prop sets its own base colours for materials 1..4, and
# afterwards the animal's palette and cell cache are marked to re-deal.
xg_prop_pal() {   # xg_prop_pal r g b  r g b  r g b  r g b — materials 1..4
  XG_PR[1]=$1;  XG_PG[1]=$2;  XG_PB[1]=$3
  XG_PR[2]=$4;  XG_PG[2]=$5;  XG_PB[2]=$6
  XG_PR[3]=$7;  XG_PG[3]=$8;  XG_PB[3]=$9
  XG_PR[4]=${10}; XG_PG[4]=${11}; XG_PB[4]=${12}
}
xg_prop_done() { XG_PAL_KEY=''; XG_CACHE_KEY=''; }
xg_prop_dish() {   # xg_prop_dish KIND(food|water) [TIER] [S] — a squat lit ceramic dish
  # S scales the whole grid (the store's preview wants it bigger) · 1.0 in the room
  local kind="${1:-food}" tier="${2:-}"; local -F s=${3:-1.0}
  local -a dp; dp=(${=XG_DISH_PAL[${XG_HOUSE[bowl]:-0}]})
  if [[ "$kind" == water ]]; then xg_prop_pal 96 128 158  30 44 66  70 190 224  225 250 255
  elif [[ -n "$tier" ]]; then     xg_prop_pal ${dp[0]} ${dp[1]} ${dp[2]} ${dp[3]} ${dp[4]} ${dp[5]}  228 150 60  255 230 170
  else                            xg_prop_pal ${dp[0]} ${dp[1]} ${dp[2]} ${dp[3]} ${dp[4]} ${dp[5]}  190 118 54  240 200 140; fi
  xg_px_new $(( int(13*s+0.5) )) $(( int(9*s+0.5) ))
  xg_disk $(( 6*s )) $(( 5.4*s )) $(( 5.7*s )) $(( 2.3*s )) 1
  xg_disk $(( 6*s )) $(( 2.7*s )) $(( 5.4*s )) $(( 1.6*s )) 1
  xg_disk $(( 6*s )) $(( 2.9*s )) $(( 4.3*s )) $(( 1.05*s )) 2
  xg_disk $(( 6*s )) $(( 3.0*s )) $(( 3.7*s )) $(( 0.85*s )) 3
  if [[ "$kind" == water ]]; then xg_set $(( int(5*s) )) $(( int(3*s) )) 4; xg_set $(( int(6*s) )) $(( int(3*s) )) 4
  else xg_set $(( int(4*s) )) $(( int(3*s) )) 4; xg_set $(( int(7*s) )) $(( int(3*s) )) 4; xg_set $(( int(6*s) )) $(( int(2*s) )) 4; fi
  xg_disk $(( 6*s )) $(( 8.0*s )) $(( 3.4*s )) $(( 0.9*s )) 2
  xg_render_cells; xg_prop_done
}
xg_prop_bed() {   # a bolster basket the animal lies IN · the raised ends flank it
  xg_prop_pal ${=XG_BED_PAL[${XG_HOUSE[bed]:-0}]}
  xg_px_new 44 16
  xg_disk 21.5 9.0 21.5 6.8 1
  xg_disk 21.5 7.2 16.5 3.9 2
  xg_disk 21.5 8.6 15.5 3.0 3
  xg_disk 4.2 8.6 2.8 2.6 1
  xg_disk 39.3 8.6 2.8 2.6 1
  local -i x; local -F yy
  for (( x=6; x<=37; x++ )); do
    yy=$(( 9.0-6.3*sqrt(1.0-((x-21.5)/21.5)*((x-21.5)/21.5)) ))
    xg_set $x $(( int(yy) )) 4
  done
  for (( x=0; x<44; x++ )); do xg_set $x 15 0; done
  xg_render_cells; xg_prop_done
}
xg_prop_toy() {   # xg_prop_toy KIND(yarn|orb) [S] — the store's toys, at the play spot
  local kind="${1:-yarn}"; local -F s=${2:-1.0}
  if [[ "$kind" == orb ]]; then
    xg_prop_pal 90 130 160  30 44 66  140 236 240  235 255 255
    xg_px_new $(( int(9*s+0.5) )) $(( int(8*s+0.5) ))
    xg_disk $(( 4*s )) $(( 3.6*s )) $(( 3.6*s )) $(( 3.0*s )) 1
    xg_disk $(( 4*s )) $(( 3.4*s )) $(( 1.9*s )) $(( 1.5*s )) 3
    xg_set $(( int(3*s) )) $(( int(2*s) )) 4; xg_set $(( int(5*s) )) $(( int(5*s) )) 2
  else
    xg_prop_pal 206 84 110  92 30 48  238 150 168  250 220 228
    xg_px_new $(( int(9*s+0.5) )) $(( int(8*s+0.5) ))
    xg_disk $(( 4*s )) $(( 4.0*s )) $(( 3.6*s )) $(( 3.2*s )) 1
    xg_seg $(( 1.2*s )) $(( 3.0*s )) $(( 6.8*s )) $(( 4.6*s )) $(( 0.6*s )) 4
    xg_seg $(( 1.6*s )) $(( 5.4*s )) $(( 7.0*s )) $(( 2.8*s )) $(( 0.6*s )) 2
    xg_seg $(( 6.8*s )) $(( 6.4*s )) $(( 8.6*s )) $(( 7.4*s )) $(( 0.5*s )) 4       # the loose strand
  fi
  xg_render_cells; xg_prop_done
}

xg_draw_furniture() {   # xg_draw_furniture RX RW FY NSPAN — the props, BAKED.
  # NSPAN is the NOMINAL span (widest pose), so nothing ever moves.  The dishes
  # sit at the animal's front at the eat/drink spots, the bed sits dead on the
  # sleep spot, and the store's toy — when the house owns one — waits at the
  # play spot (the close-up hasn't the floor for it).  Every prop is a sprite
  # through the animal's own pipeline, blitted once into the shell.
  local -i rx=$1 rw=$2 fy=$3 span=$4
  local -i bowlc=$(( rx+3+int(0.22*span)+9 )) watc=$(( rx+3+int(0.30*span)+24 )) \
           bedc=$(( rx+3+int(0.84*span)+22 )) toyc=$(( rx+3+int(0.64*span)+7 ))
  xg_prop_bed
  xg_shadow $bedc $(( fy+1 )) 40 0.7
  xg_blit_cells $(( bedc-XG_CCW/2 )) $(( fy-XG_CCH+1 ))
  xg_prop_dish food "${XG_HOUSE[kibble]:-}"
  xg_shadow $bowlc $fy $(( XG_CCW+2 )) 0.6
  xg_blit_cells $(( bowlc-XG_CCW/2 )) $(( fy-XG_CCH+1 ))
  xg_prop_dish water
  xg_shadow $watc $fy $(( XG_CCW+2 )) 0.6
  xg_blit_cells $(( watc-XG_CCW/2 )) $(( fy-XG_CCH+1 ))
  if [[ -n "${XG_HOUSE[toy]:-}" ]] && (( span >= 80 )); then
    xg_prop_toy "${XG_HOUSE[toy]}"
    xg_shadow $toyc $fy $(( XG_CCW+2 )) 0.65
    xg_blit_cells $(( toyc-XG_CCW/2 )) $(( fy-XG_CCH+1 ))
  fi
  [[ -n "${XG[gift]:-}" ]] && xg_gift_bug $(( rx+3+int(0.43*span)+18 )) $(( 2*(fy+1) ))   # something was left
  return 0
}

xg_core_env() {   # xg_core_env RX RY RW RH FY CX — the static engine room:
  # the air's falloff, the conduit, the column, the deck.  Drawn once
  # into the room cache; the breathing and the motes ride the live layer.
  local -i rx=$1 ry=$2 rw=$3 rh=$4 fy=$5 cx=$6 x y lv lv2 top bot ccx midy pk pfg lx ly zoom=0
  local -i xa xb gk0 nx
  local -F df t vy dxf dyf d2 tt rair rdeck fac
  local -a rb rf rc
  top=$(( ry+1 )); bot=$(( ry+rh-1 )); midy=$(( (top+fy)/2 ))
  # A SHORT GLASS IS A CLOSE-UP · the column and ceiling stand off-frame and
  # only their light reaches in; anchored to the edges, the centre is his.
  (( rh < 30 )) && zoom=1
  if (( zoom )); then ccx=$(( rx-9 )); rair=$(( rw*0.72 )); rdeck=$(( rw*0.62 ))
  else ccx=$(( rx+36 )); rair=$(( rw*0.49 )); rdeck=$(( rw*0.46 )); fi
  # the air · light falls away from the column, shaped a little by height
  # A ROW AT A TIME, STRAIGHT INTO THE GRID.  The arithmetic is the cell's
  # own, in the order it always was; what went is the call per cell -- forty
  # thousand v_puts a bake, two thirds of the four seconds the room took to
  # stand up the first time its page was opened.  Only the columns the glass
  # can show are worked out (v_put threw the rest away), and the row's
  # grounds go in as one slice.
  xa=$(( rx+1 )); (( xa<0 )) && xa=0
  xb=$(( rx+rw-2 )); (( xb>SCR_W-1 )) && xb=$(( SCR_W-1 ))
  (( OX+C_SCR+xa<0 )) && xa=$(( -(OX+C_SCR) )); (( OX+C_SCR+xb>=TCOLS )) && xb=$(( TCOLS-1-OX-C_SCR ))
  nx=$(( xb-xa+1 ))
  if (( nx>0 )); then
    _run $nx ' '; rc=("${(@s::)RUN}")
    _repn $nx $GREY; rf=("${(@P)REPV}")
    for (( y=top; y<fy; y++ )); do
      (( y<0 || y>=SCR_H || OY+R_SCR+y<0 || OY+R_SCR+y>=TROWS )) && continue
      vy=$(( (y-midy)/((fy-top)/2.0) )); fac=$(( 1.0-0.30*vy*vy ))
      rb=()
      for (( x=xa; x<=xb; x++ )); do
        (( df=x-ccx, df=df<0.0?-df:df, t=1.0-df/rair, t=t<0.0?0.0:t, t=t*fac, t=t<0.0?0.0:t, lv=int(t*t*16.0), lv=lv>16?16:lv ))
        rb+=(${CORE_AIR[$lv]})
      done
      gk0=$(( (OY+R_SCR+y)*TCOLS+OX+C_SCR+xa ))
      GCH[$gk0,$(( gk0+nx-1 ))]=("${rc[@]}"); GF[$gk0,$(( gk0+nx-1 ))]=("${rf[@]}"); GB[$gk0,$(( gk0+nx-1 ))]=("${rb[@]}")
    done
  fi
  # the conduit along the ceiling, lit near the core · the full view only
  if (( ! zoom )); then
    v_fill $(( rx+1 )) $top $(( rw-2 )) 2 ' ' $GREY $CR_CASE
    pk=-1
    for (( x=rx+1; x<rx+rw-1; x++ )); do
      (( x<1 || x>=SCR_W )) && continue
      (( x/6 != pk )) && { pk=$(( x/6 )); df=$(( x-ccx )); (( df<0.0 )) && df=$(( -df )); t=$(( 1.0-df/rair )); (( t<0.0 )) && t=0.0; cmix $CR_CASE_HI $CR_GLOW $(( 0.55*t )); pfg=$CM; }
      if (( x%12==0 )); then v_put $x $(( top+1 )) '╬' $pfg $CR_CASE
      else v_put $x $(( top+1 )) '═' $pfg $CR_CASE; fi
    done
  fi
  # THE SERVICE LAMP IS GONE.  It hung over the bed on a cable from the
  # ceiling and threw an amber counterlight down onto it -- and the cable, a
  # column of │, came out dashed in a terminal whose box glyph is a shade
  # narrower than its cell.  The bed keeps the core's own light now.
  # the column · hot centre banded by flanged rings · the full view only
  if (( ! zoom )); then
    for (( y=top+2; y<fy; y++ )); do
      v_put $(( ccx-3 )) $y ' ' $GREY $CR_CASE; v_put $(( ccx+3 )) $y ' ' $GREY $CR_CASE
      if (( (y-top)%4==0 )); then
        for (( x=ccx-2; x<=ccx+2; x++ )); do v_put $x $y ' ' $GREY $CR_RING; done
        v_put $(( ccx-4 )) $y ' ' $GREY $CR_CASE_HI; v_put $(( ccx+4 )) $y ' ' $GREY $CR_CASE_HI
      else
        v_put $(( ccx-2 )) $y ' ' $GREY $CR_E2; v_put $(( ccx+2 )) $y ' ' $GREY $CR_E2
        v_put $(( ccx-1 )) $y ' ' $GREY $CR_E1; v_put $(( ccx+1 )) $y ' ' $GREY $CR_E1
        lv2=$(( y-midy )); (( lv2<0 )) && lv2=$(( -lv2 ))
        if (( lv2<=5 )); then v_put $ccx $y ' ' $GREY $CR_HOT; else v_put $ccx $y ' ' $GREY $CR_E1B; fi
      fi
    done
    for (( x=ccx-5; x<=ccx+5; x++ )); do v_put $x $(( top+1 )) ' ' $GREY $CR_CASE_HI; done
  fi
  # the deck · lit falloff, plating seams, the column's reflection in it
  # ITS LIGHT IS A FUNCTION OF THE COLUMN ALONE, so every row under the rim is
  # the same row: worked out once, across, and laid down a row at a time.
  if (( nx>0 )); then
    local -a db dc df2 eb ec ef
    for (( x=xa; x<=xb; x++ )); do
      (( df=x-ccx, df=df<0.0?-df:df, t=1.0-df/rdeck, t=t<0.0?0.0:t, lv=int(t*t*16.0), lv=lv>16?16:lv ))
      db+=(${CORE_DECK[$lv]})
      ec+=('━'); ef+=($CR_CASE_HI)
      if (( x%10==4 )); then lv2=$(( lv+3 )); (( lv2>16 )) && lv2=16; dc+=('¦'); df2+=(${CORE_DECK[$lv2]})
      else dc+=(' '); df2+=($GREY); fi
    done
    for (( y=fy; y<=bot; y++ )); do
      (( y<0 || y>=SCR_H || OY+R_SCR+y<0 || OY+R_SCR+y>=TROWS )) && continue
      gk0=$(( (OY+R_SCR+y)*TCOLS+OX+C_SCR+xa ))
      if (( y==fy )); then GCH[$gk0,$(( gk0+nx-1 ))]=("${ec[@]}"); GF[$gk0,$(( gk0+nx-1 ))]=("${ef[@]}")
      else GCH[$gk0,$(( gk0+nx-1 ))]=("${dc[@]}"); GF[$gk0,$(( gk0+nx-1 ))]=("${df2[@]}"); fi
      GB[$gk0,$(( gk0+nx-1 ))]=("${db[@]}")
    done
  fi
  if (( ! zoom )); then
    for (( y=fy+2; y<=bot; y++ )); do
      v_put $(( ccx-1 )) $y ' ' $GREY ${CORE_DECK[13]}; v_put $ccx $y ' ' $GREY ${CORE_DECK[15]}; v_put $(( ccx+1 )) $y ' ' $GREY ${CORE_DECK[13]}
    done
    # the base housing, striped for hazard
    for (( x=ccx-5; x<=ccx+5; x++ )); do
      v_put $x $fy ' ' $GREY $CR_CASE_HI
      if (( ((x-ccx)+60)%4<2 )); then v_put $x $(( fy+1 )) ' ' $GREY $CR_HAZ
      else v_put $x $(( fy+1 )) ' ' $GREY $CR_HAZD; fi
    done
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE PORTHOLE · a window in the hull, with the suite's own sky in it
# ══════════════════════════════════════════════════════════════════════════
# THE DOG · SHIPMENT 02 · ported from the original, geometry for geometry
# ══════════════════════════════════════════════════════════════════════════
# The original dealt eight species from the same hash; this is the second of
# them, brought across whole: its own colourways, its own eyes, its own
# temperaments, and a body that is NOT a cat with different ears -- a deeper
# chest, a snout with a nose on the end of it, ears that are pointy or floppy
# or one of each, and a tail that is straight or curls over the back.
typeset -ga XG_DCWN XG_DCWR XG_DCWG XG_DCWB XG_DPATN XG_DEARS XG_DTAILS
typeset -ga XG_DENAME XG_DEYR XG_DEYG XG_DEYB XG_DTNAME XG_DTDESC XG_DTFEED XG_DTBOND
XG_DCWN=(black chocolate golden cream red grey white fawn)
XG_DCWR=(52 104 216 234 182 142 238 206)
XG_DCWG=(48  68 166 214  96 140 232 168)
XG_DCWB=(62  48  88 180  52 154 224 122)
XG_DPATN=(plain blaze patch brindle sable)
XG_DEARS=(floppy pointy semi)
XG_DTAILS=(straight curly)
XG_DENAME=(brown amber hazel ice)
XG_DEYR=(124 210 150 150); XG_DEYG=(88 158 122 210); XG_DEYB=(56 78 66 240)
XG_DTNAME=(loyal goofy anxious dignified food-driven zoomy)
XG_DTDESC=('supervises the airlock' 'zero thoughts, all joy' 'heard something, probably' \
           'a very old soul' 'will SIT for anything' 'the room is a racetrack')
XG_DTFEED=(1.0 1.1 0.95 0.85 1.3 1.15)
XG_DTBOND=(1.2 1.1 1.3 1.0 1.0 1.0)

xg_deal_dog() {   # xg_deal_dog SEED — the dog deck, off the same stable hash
  local -i seed=$1 ci pi ei ej ti tj bR bG bB dR dG dB wR wG wB eR eG eB
  local -F et w
  xg_breed_sets dog "${(j:|:)XG_DCWN[@]}" "${(j:|:)XG_DPATN[@]}"
  xg_gh $seed 4; ci=${XB_CWIX[$(( XG_H%${#XB_CWIX[@]} ))]}
  xg_vary_coat ${XG_DCWR[$ci]} ${XG_DCWG[$ci]} ${XG_DCWB[$ci]} $seed 0.8
  bR=$XG_VR; bG=$XG_VG; bB=$XG_VB
  xg_gh $seed 9;  pi=${XB_PATIX[$(( XG_H%${#XB_PATIX[@]} ))]}; XG[pattern]=${XG_DPATN[$pi]}
  xg_gh $seed 33; XG[pj]=$(( XG_H%9973 ))
  # A BREED THAT HAS AN ANSWER GIVES IT · a pug's ears are not a coin toss
  if [[ "$XB_EAR" != '-' ]]; then XG[ears]="$XB_EAR"; else xg_gh $seed 15; XG[ears]=${XG_DEARS[$(( XG_H%3 ))]}; fi
  if [[ "$XB_TAIL" != '-' ]]; then XG[tail]="$XB_TAIL"; else xg_gh $seed 21; XG[tail]=${XG_DTAILS[$(( XG_H%2 ))]}; fi
  xg_gh $seed 26; ei=$(( XG_H%4 )); xg_gh $seed 27; ej=$(( (ei+1+XG_H%3)%4 )); xg_gf $seed 28; et=$XG_F
  eR=$(( int(XG_DEYR[ei]+(XG_DEYR[ej]-XG_DEYR[ei])*et*0.5) ))
  eG=$(( int(XG_DEYG[ei]+(XG_DEYG[ej]-XG_DEYG[ei])*et*0.5) ))
  eB=$(( int(XG_DEYB[ei]+(XG_DEYB[ej]-XG_DEYB[ei])*et*0.5) ))
  (( et<0.5 )) && XG[eyes]=${XG_DENAME[$ei]} || XG[eyes]="${XG_DENAME[$ei]}-${XG_DENAME[$ej]}"
  XG[ear_s]=0.9; XG[tail_n]=1.0
  XG[build]="${XG[ears]} ears · ${XG[tail]} tail"
  xg_gh $seed 11; ti=$(( XG_H%6 )); xg_gh $seed 12; tj=$(( (ti+1+XG_H%5)%6 )); xg_gf $seed 13; w=$(( 0.62+0.38*XG_F ))
  XG[tname]="${XG_DTNAME[$ti]}"
  xg_an "${XG_DTNAME[$tj]}"
  (( w>0.82 )) && XG[temper]="${XG_DTDESC[$ti]}" || XG[temper]="${XG_DTDESC[$ti]} · $REPLY ${XG_DTNAME[$tj]} streak"
  xg_gf $seed 14; xg_m2 $(( int((XG_DTFEED[ti]*w + XG_DTFEED[tj]*(1.0-w) + (XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[hunger_m]="$REPLY"
  xg_gf $seed 18; xg_m2 $(( int((XG_DTBOND[ti]*w + XG_DTBOND[tj]*(1.0-w) + (XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[social_m]="$REPLY"
  XG[colorway]="${XG_VMOD}${XG_DCWN[$ci]}"
  (( pi>0 )) && XG[label]="${XG[colorway]} ${XG[pattern]}" || XG[label]="${XG[colorway]}"
  dR=$(( int(bR*0.62) )); dG=$(( int(bG*0.62) )); dB=$(( int(bB*0.62) ))
  if [[ "${XG_DCWN[$ci]}" == white ]]; then wR=246; wG=242; wB=236
  else wR=$(( int(bR+(250-bR)*0.75) )); wG=$(( int(bG+(246-bG)*0.75) )); wB=$(( int(bB+(238-bB)*0.75) )); fi
  # 0 · b · d · w · o · e · E · k · s · p · n · x
  XG_PR=(0 $bR $dR $wR 214 $eR $eR 26 255 234 34 204)
  XG_PG=(0 $bG $dG $wG 156 $eG $eG 22 255 138 28 200)
  XG_PB=(0 $bB $dB $wB  96 $eB $eB 30 255 148 36 226)
  return 0
}

# ── the ears · pointy, floppy, or one of each ──
xg_dog_ear_pointy() {   # HX HY S SIDE
  local -F hx=$1 hy=$2 s=$3; local -i sd=$4
  xg_tri $(( hx+sd*6.4*s )) $(( hy-1.8*s )) $(( hx+sd*5.0*s )) $(( hy-7.2*s )) $(( hx+sd*1.0*s )) $(( hy-3.8*s )) 1
  xg_tri $(( hx+sd*5.2*s )) $(( hy-3.0*s )) $(( hx+sd*4.7*s )) $(( hy-5.8*s )) $(( hx+sd*2.6*s )) $(( hy-4.0*s )) 9 "1 2 4"
}
xg_dog_ear_floppy() {   # HX HY S SIDE
  local -F hx=$1 hy=$2 s=$3 ex; local -i sd=$4
  ex=$(( hx+sd*4.8*s ))
  xg_disk $ex $(( hy-3.0*s )) $(( 1.7*s )) $(( 1.5*s )) 2
  xg_disk $(( ex+sd*1.0*s )) $(( hy-0.6*s )) $(( 1.9*s )) $(( 2.6*s )) 2
  xg_disk $(( ex+sd*1.4*s )) $(( hy+2.4*s )) $(( 1.5*s )) $(( 2.0*s )) 2
}
xg_dog_ears() {   # xg_dog_ears HX HY KIND [S]
  local -F hx=$1 hy=$2 s=${4:-1.0}; local kind="${3:-floppy}"
  case "$kind" in
    pointy) xg_dog_ear_pointy $hx $hy $s -1; xg_dog_ear_pointy $hx $hy $s 1 ;;
    floppy) xg_dog_ear_floppy $hx $hy $s -1; xg_dog_ear_floppy $hx $hy $s 1 ;;
    *)      xg_dog_ear_pointy $hx $hy $s -1; xg_dog_ear_floppy $hx $hy $s 1 ;;   # semi · iconic
  esac
}
# ── the tail · straight and up, or curled over the back ──
xg_dog_tail() {   # xg_dog_tail RX RY KIND [up|wag|low]
  local -F rx=$1 ry=$2; local kind="${3:-straight}" mode="${4:-up}"
  if [[ "$kind" == curly ]]; then
    xg_disk $(( rx+1.5 )) $(( ry-3.0 )) 2.7 2.7 1
    xg_disk $(( rx+1.7 )) $(( ry-3.2 )) 1.1 1.1 0 "1"
    [[ "$mode" == wag ]] && { xg_set $(( int(rx+5) )) $(( int(ry-5.5) )) 11; xg_set $(( int(rx+5.5) )) $(( int(ry-2) )) 11; }
    return 0
  fi
  if [[ "$mode" == low ]]; then
    xg_seg $(( rx+1 )) $ry $(( rx+4.5 )) $(( ry+4 )) 1.4 1
    xg_seg $(( rx+4.5 )) $(( ry+4 )) $(( rx+5 )) $(( ry+7 )) 1.4 1
    xg_disk $(( rx+5 )) $(( ry+7.5 )) 1.4 1.4 2
    return 0
  fi
  xg_seg $(( rx+1 )) $ry $(( rx+5 )) $(( ry-3 )) 1.5 1
  xg_seg $(( rx+5 )) $(( ry-3 )) $(( rx+6.5 )) $(( ry-7 )) 1.5 1
  xg_disk $(( rx+6.6 )) $(( ry-7.6 )) 1.5 1.6 2
  [[ "$mode" == wag ]] && { xg_set $(( int(rx+9) )) $(( int(ry-6) )) 11
                            xg_set $(( int(rx+9.5) )) $(( int(ry-2.5) )) 11
                            xg_set $(( int(rx+8.5) )) $(( int(ry-9.5) )) 11 }
  return 0
}
# ── the face · dark round honest eyes, a snout, a nose on the end of it ──
xg_dog_face() {   # xg_dog_face HX HY [EYES] [TONGUE] [MOUTH] [SCALE]
  local -F hx=$1 hy=$2 s=${6:-1.0} exl exr ey ex
  local eyes="${3:-open}" mouth="${5:-}"; local -i tongue=${4:-0} X Y
  exl=$(( hx-3.2*s )); exr=$(( hx+3.2*s )); ey=$(( hy-1.0*s ))
  Y=$(( int(ey) ))
  if [[ "$eyes" == open ]]; then
    # a 2x2 block · iris up-left, sparkle up-right, dark below.  It lands on
    # one clean cell once the two pixel rows are folded together.
    X=$(( int(exl) )); xg_set $X $(( Y-1 )) 5; xg_set $(( X+1 )) $(( Y-1 )) 8; xg_set $X $Y 7; xg_set $(( X+1 )) $Y 7
    X=$(( int(exr) )); xg_set $X $(( Y-1 )) 6; xg_set $(( X+1 )) $(( Y-1 )) 8; xg_set $X $Y 7; xg_set $(( X+1 )) $Y 7
  elif [[ "$eyes" == closed ]]; then
    for ex in $exl $exr; do
      xg_set $(( int(ex-1) )) $Y 7; xg_set $(( int(ex) )) $(( int(ey+1) )) 7; xg_set $(( int(ex+1) )) $Y 7
    done
  else
    xg_set $(( int(exl-1) )) $Y 7; xg_set $(( int(exl) )) $Y 5; xg_set $(( int(exl+1) )) $Y 7
    xg_set $(( int(exr-1) )) $Y 7; xg_set $(( int(exr) )) $Y 6; xg_set $(( int(exr+1) )) $Y 7
  fi
  xg_disk $hx $(( hy+2.4*s )) $(( 3.5*s )) $(( 2.5*s )) 3 "1 2 3 4"
  xg_disk $hx $(( hy+1.6*s )) $(( 1.4*s )) $(( 1.0*s )) 10 "1 2 3 4"
  if [[ "$mouth" == bark ]]; then
    xg_set $(( int(hx) )) $(( int(hy+3.6*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+4.4*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+5.0*s) )) 9
  else
    xg_set $(( int(hx-1) )) $(( int(hy+3.8*s) )) 2; xg_set $(( int(hx+1) )) $(( int(hy+3.8*s) )) 2
    (( tongue )) && { xg_set $(( int(hx+1) )) $(( int(hy+4.6*s) )) 9
                      xg_set $(( int(hx+1) )) $(( int(hy+5.4*s) )) 9
                      xg_set $(( int(hx+2) )) $(( int(hy+5.0*s) )) 9 }
  fi
  return 0
}
# ── the coat · blaze, patch, brindle, sable ──
xg_dog_dress() {   # xg_dog_dress HX HY
  local -F hx=$1 hy=$2 v thr ph a1 a2 a3 a4 a5 a6; local -i x y pj=${XG[pj]:-0} yy cur
  case "${XG[pattern]:-plain}" in
    plain) ;;
    blaze)
      xg_dj $pj 1 3.6 4.8; a1=$XG_F; xg_dj $pj 2 5.4 7.0; a2=$XG_F
      xg_disk $hx $(( hy+11 )) $a1 $a2 3 "1 2"
      for (( yy=int(hy-5); yy<int(hy+1); yy++ )); do
        (( yy<0 || yy>=XG_XPH )) && continue
        cur=${XG_XPM[$(( yy*XG_XPW+int(hx) ))]:-0};   (( cur==1||cur==2 )) && xg_set $(( int(hx) )) $yy 3
        cur=${XG_XPM[$(( yy*XG_XPW+int(hx)-1 ))]:-0}; (( cur==1||cur==2 )) && xg_set $(( int(hx)-1 )) $yy 3
      done ;;
    patch)
      xg_dj $pj 1 2.6 4.2; a1=$XG_F; xg_dj $pj 2 0.6 2.2; a2=$XG_F
      xg_disk $(( hx+a1 )) $(( hy-a2 )) 2.8 2.6 2 "1"
      xg_dj $pj 3 4.5 6.5; a3=$XG_F; xg_dj $pj 4 9.0 11.0; a4=$XG_F
      xg_disk $(( hx-a3 )) $(( hy+a4 )) 4.4 3.4 2 "1"
      xg_dj $pj 5 4.0 6.0; a5=$XG_F; xg_dj $pj 6 12.0 14.0; a6=$XG_F
      xg_disk $(( hx+a5 )) $(( hy+a6 )) 3.6 2.8 4 "1" ;;
    brindle)
      xg_dj $pj 7 0.84 1.02; thr=$XG_F; ph=$(( 2.0+pj*0.29 ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && {
          v=$(( sin(y*0.95+x*0.22+ph*0.37)+0.4*sin(x*0.9+ph*0.74) ))
          (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    sable)
      # a saddle of darker coat across the back, off the face entirely
      xg_dj $pj 1 -1.2 1.2; a1=$XG_F; xg_dj $pj 2 7.4 9.0; a2=$XG_F; xg_dj $pj 3 4.0 5.2; a3=$XG_F
      xg_disk $(( hx-1+a1 )) $(( hy+13 )) $a2 $a3 2 "1"
      xg_disk $(( hx-3.5 )) $(( hy+9.5 )) 4.8 3.0 2 "1" ;;
  esac
  return 0
}
# ── the poses ──
xg_dog_sit() {   # xg_dog_sit [EYES] [TONGUE] [MOUTH] [TAILMODE]
  local eyes="${1:-open}" mouth="${3:-}" tmode="${4:-up}"; local -i tongue=${2:-0} yy
  xg_px_new 36 31; local -F hx=17.0 hy=9.0
  xg_dog_tail $(( hx+7.5 )) $(( hy+16 )) "${XG[tail]:-straight}" "$tmode"
  xg_disk $hx $(( hy+15 )) 9.8 5.8 1          # haunches
  xg_disk $hx $(( hy+10.5 )) 7.4 7.4 1        # a deep chest
  xg_disk $hx $hy 6.4 5.8 1                   # head
  xg_disk $hx $(( hy+1.8 )) 6.9 4.0 1
  xg_dog_ears $hx $hy "${XG[ears]:-floppy}" 1.0
  for (( yy=int(hy+12); yy<int(hy+20); yy++ )); do xg_set $(( int(hx) )) $yy 2; done
  xg_disk $(( hx-3.6 )) $(( hy+19.4 )) 2.8 1.7 3
  xg_disk $(( hx+3.4 )) $(( hy+19.4 )) 2.8 1.7 3
  xg_dog_dress $hx $hy
  xg_dog_face $hx $hy "$eyes" $tongue "$mouth" 1.0
}
xg_dog_puppy() {   # xg_dog_puppy [EYES] [TONGUE] [MOUTH] — mostly head, as puppies are
  local eyes="${1:-open}" mouth="${3:-}" tm=up; local -i tongue=${2:-0} yy
  (( tongue )) && tm=wag
  xg_px_new 24 21; local -F hx=11.5 hy=7.4
  xg_dog_tail $(( hx+5 )) $(( hy+10.5 )) "${XG[tail]:-straight}" "$tm"
  xg_disk $hx $(( hy+9.2 )) 6.2 4.2 1
  xg_disk $hx $(( hy+6.4 )) 5.2 4.8 1
  xg_disk $hx $hy 5.8 5.0 1
  xg_disk $hx $(( hy+1.6 )) 6.2 3.4 1
  xg_dog_ears $hx $hy "${XG[ears]:-floppy}" 0.85
  for (( yy=int(hy+8); yy<int(hy+12); yy++ )); do xg_set $(( int(hx) )) $yy 2; done
  xg_disk $(( hx-2.7 )) $(( hy+12.2 )) 2.2 1.2 3
  xg_disk $(( hx+2.6 )) $(( hy+12.2 )) 2.2 1.2 3
  xg_dog_dress $hx $hy
  xg_dog_face $hx $hy "$eyes" $tongue "$mouth" 0.9
}
xg_dog_walk() {   # xg_dog_walk [FRAME 0|1]
  local -i frame=${1:-0} i lift; local -F bx hx hy x0 dx
  xg_px_new 32 22; bx=15.0; hx=$(( bx+8.5 )); hy=8.0
  xg_dog_tail $(( bx-8.5 )) 11.5 "${XG[tail]:-straight}" wag
  xg_disk $(( bx-3 )) 12.5 8.0 4.8 1
  xg_disk $(( bx+3.5 )) 11.8 6.6 4.4 1
  xg_disk $hx $hy 5.8 5.2 1
  xg_disk $hx $(( hy+1.8 )) 6.3 3.4 1
  xg_dog_ears $hx $hy "${XG[ears]:-floppy}" 0.85
  for (( i=0; i<4; i++ )); do
    case $i in 0) dx=-8.0 ;; 1) dx=-4.0 ;; 2) dx=2.0 ;; *) dx=6.0 ;; esac
    if (( frame == 0 )); then lift=$(( i==1||i==3 )); else lift=$(( i==0||i==2 )); fi
    x0=$(( bx+dx ))
    xg_seg $x0 15.0 $(( x0+0.4 )) $(( 19.5-lift*2.0 )) 1.2 1
    xg_disk $(( x0+0.5 )) $(( 20.0-lift*2.0 )) 1.5 0.9 3
  done
  xg_dog_dress $hx $hy
  xg_dog_face $hx $hy open 1 '' 0.9
}
xg_dog_sleep() {   # xg_dog_sleep — curled, nose tucked
  local -F cx cy hx hy ex
  xg_px_new 34 19; cx=16.0; cy=10.0
  xg_disk $(( cx+1 )) $cy 11.0 6.0 1
  xg_disk $(( cx+4.5 )) $(( cy-2.4 )) 7.2 4.2 1
  hx=$(( cx-6.8 )); hy=$(( cy-0.8 ))
  xg_disk $hx $hy 5.6 4.8 1
  xg_disk $hx $(( hy+1.6 )) 6.0 3.2 1
  xg_dog_ears $hx $hy "${XG[ears]:-floppy}" 0.7
  xg_seg $(( cx+10.5 )) $(( cy+2 )) $(( cx+4 )) $(( cy+5.4 )) 1.5 1
  xg_seg $(( cx+4 )) $(( cy+5.4 )) $(( cx-4 )) $(( cy+5.4 )) 1.5 1
  xg_dog_dress $hx $hy
  for ex in $(( hx-2.4 )) $(( hx+2.4 )); do
    xg_set $(( int(ex-1) )) $(( int(hy+0.2) )) 7
    xg_set $(( int(ex) ))   $(( int(hy+0.7) )) 7
    xg_set $(( int(ex+1) )) $(( int(hy+0.2) )) 7
  done
  xg_disk $(( hx-1 )) $(( hy+2.6 )) 2.6 1.8 3 "1 2 3 4"
  xg_disk $(( hx-1.6 )) $(( hy+2.2 )) 1.2 0.9 10 "1 2 3 4"
}
xg_dog_sploot() {   # xg_dog_sploot — flat on the belly, hind legs out the back
  local -F hx hy tm2; local tm=low
  xg_px_new 36 22; hx=17.0; hy=7.0
  [[ "${XG[tail]:-straight}" == curly ]] && tm=up
  xg_dog_tail $(( hx+9.5 )) $(( hy+9 )) "${XG[tail]:-straight}" "$tm"
  xg_disk $hx $(( hy+8.5 )) 10.5 4.6 1          # the pancake
  xg_disk $hx $(( hy+1.5 )) 5.9 5.2 1           # head up, front
  xg_disk $hx $(( hy+3.2 )) 6.4 3.6 1
  xg_dog_ears $hx $(( hy+1.5 )) "${XG[ears]:-floppy}" 0.9
  xg_disk $(( hx-4.5 )) $(( hy+12.8 )) 2.4 1.3 3
  xg_disk $(( hx+4.3 )) $(( hy+12.8 )) 2.4 1.3 3
  xg_disk $(( hx-9.5 )) $(( hy+11.5 )) 1.6 1.1 3
  xg_disk $(( hx+9.3 )) $(( hy+11.5 )) 1.6 1.1 3
  xg_dog_dress $hx $(( hy+1.5 ))
  xg_dog_face $hx $(( hy+1.5 )) open 0 '' 0.9
}

# ══════════════════════════════════════════════════════════════════════════
# A heavy riveted hull ring with a seal that glows in the reactor's colour and
# a ring of running lights chasing slowly round it; deep space inside, the
# stars drifting past as the ship makes way; and hanging in it, the DOOR'S
# OWN SUN OR MOON -- the same card (SKY_ROW) the driver picks every
# minute (SKY_IDX): tonight's real moon phase, the sun by day, the dusk and
# dawn cards between.  Now and then — rarely, a pass an hour at most — the
# ship comes over EARTH and the planet's curve slides across the foot of the
# glass: city lights by night, a blue marble by day.
# The ring, the sky and the window's light are BAKED into the room; per frame
# only the stars, the running lights and (on a pass) the planet are drawn —
# the planet straight into the grid, so a pass costs a millisecond, not a frame.
# Painted as cell GROUNDS (two sub-pixels folded into one), never block glyphs:
# the suite's cards and sprites do the same, and no font leaves a seam in it.
typeset -gi XP_CX=0 XP_ROW=0 XP_R=0 XP_CARDX=0 XP_CARDY=0 XP_IDX=-1 XP_NIGHT=1 XP_TW=0
typeset -ga XP_TOK XP_SX XP_SY XP_SL XP_SP XP_FAR XP_NEAR XP_AMB XP_CYN XP_EC XP_EA XP_INX XP_INY
typeset -g  XP_STARKEY='' XP_EKEY='' XP_INKEY=''
typeset -gi XP_EW=0 XP_EH=0 XP_EOX=0 XP_EOY=0
typeset -gF XP_PASS_FORCE=-1.0            # tests and previews · a pass held at this progress
typeset -gi XP_PASS_EVERY=2700 XP_PASS_LEN=150

xg_port_sky() {   # which card hangs in the window · the driver's own answer
  local -i idx=${SKY_IDX:--1}
  if (( idx < 0 )); then                  # before the slow clock has spoken · ask the sky
    local -F now=${EPOCHSECONDS:-0}
    if is_day $now 2>/dev/null; then idx=0; else sky_moon $now; idx=$(( 2+2*MOON_PH )); fi
  fi
  XP_IDX=$idx
  local key="${SKY_KEY[$idx]}" rows
  XP_NIGHT=${key%%,*}; XP_TW=${key##*,}
  rows="${(j: :)${(@)SKY_ROW[@]:$(( idx*CEL_H )):$CEL_H}}"
  XP_TOK=(${=rows})
}
xg_port_geom() {   # xg_port_geom RX FY SPAN ZOOM — where the window hangs, in these coords
  local -i rx=$1 fy=$2 span=$3 zoom=$4
  XP_CX=$(( rx+3+int(0.47*span)+18 ))         # over the wall between the water and the toy
  if (( zoom )); then XP_R=13; XP_ROW=8
  else XP_R=16; XP_ROW=$(( fy-25 )); (( XP_ROW < 11 )) && XP_ROW=11; fi
  if (( zoom )); then XP_CARDX=$(( XP_CX-5 )); XP_CARDY=$(( XP_ROW-3 ))
  else XP_CARDX=$(( XP_CX-2 )); XP_CARDY=$(( XP_ROW-5 )); fi
}

xg_port_glass() {   # the ring, the seal, the glass, the card · baked
  local -i x y s c c0 c1 k base top0 bot0 sp0 sp1 sheen haze rivh steel steelhi seal
  local -F cxp cyp dx dy d R=$XP_R t u ang a8 rx8 ry8 rd n
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  cxp=$(( XP_CX+0.5 )); cyp=$(( 2.0*XP_ROW+1.0 ))
  top0=$(( int((cyp-R-1)/2) )); bot0=$(( int((cyp+R+1)/2) ))
  _pack 5 7 20;    sp0=$PK
  _pack 12 14 34;  sp1=$PK
  _pack 58 70 112; sheen=$PK
  _pack 44 22 66;  haze=$PK
  steel=$CR_CASE; steelhi=$CR_CASE_HI
  cmix $CR_CASE_HI $WHITE 0.35; rivh=$CM
  cmix $CR_GLOW $WHITE 0.25;    seal=$CM
  for (( y=top0; y<=bot0; y++ )); do
    (( y<0 || y>=SCR_H )) && continue
    for (( x=XP_CX-XP_R-1; x<=XP_CX+XP_R+1; x++ )); do
      (( x<0 || x>=SCR_W )) && continue
      k=$(( base+y*TCOLS+x ))
      for s in 0 1; do
        dx=$(( x+0.5-cxp )); dy=$(( 2*y+s+0.5-cyp ))
        d=$(( sqrt(dx*dx+dy*dy) ))
        if (( d > R )); then
          c=${GB[$k]:-$GLASS}                                   # the wall, as the air left it
        elif (( d > R-3.0 )); then                      # the hull ring · the top-right sun
          u=$(( d>0.01 ? (dx*0.62-dy*0.78)/d : 0.0 ))
          t=$(( 0.45+0.45*u )); (( d < R-2.0 )) && t=$(( t*0.7 ))
          cmix $steel $steelhi $t; c=$CM
          (( dx < 0.0 )) && { cmix $c $CR_GLOW $(( 0.28*(-dx/d) )); c=$CM; }   # the core's light, near side
          ang=$(( atan(dy,dx) )); a8=$(( floor(ang/0.785398+0.5)*0.785398 ))  # eight rivets
          rx8=$(( (R-1.5)*cos(a8) )); ry8=$(( (R-1.5)*sin(a8) ))
          rd=$(( sqrt((dx-rx8)*(dx-rx8)+(dy-ry8)*(dy-ry8)) ))
          (( rd < 0.8 )) && c=$rivh
        elif (( d > R-4.0 )); then
          c=$seal                                       # the seal · the reactor's own glow
        else                                            # the glass · space
          t=$(( (dy+R)/(2.0*R) )); cmix $sp0 $sp1 $t; c=$CM
          n=$(( sin(dx*0.33+1.3)*sin(dy*0.47+0.4) ))
          (( n > 0.35 )) && { cmix $c $haze $(( (n-0.35)*0.55 )); c=$CM; }
          u=$(( dx+dy*0.9 ))
          (( u > -R*0.78 && u < -R*0.52 )) && { cmix $c $sheen 0.10; c=$CM; }
          t=$(( d/(R-4.0) )); t=$(( t*t*t*t )); cshade $c $(( 1.0-0.4*t )); c=$CS
        fi
        if (( s == 0 )); then c0=$c; else c1=$c; fi
      done
      (( c0 != c1 )) && c0=$(( ((((((c0>>16)&255)+((c1>>16)&255))/2)&0xFC)<<16)|(((((c0>>8)&255)+((c1>>8)&255))/2)&0xFC)<<8|((((c0&255)+(c1&255))/2)&0xFC) ))
      v_put $x $y ' ' $GREY $c0
    done
  done
  # the card · the door's own sun or moon, its soft rim blended into THIS sky
  local -i i cr cg cb br bg2 bb kk
  local cell; local -F w
  for (( i=0; i<72; i++ )); do
    cell="${XP_TOK[$i]:--}"; [[ "$cell" == '-' ]] && continue
    x=$(( XP_CARDX+i%12 )); y=$(( XP_CARDY+i/12 ))
    (( x<0 || x>=SCR_W || y<0 || y>=SCR_H )) && continue
    kk=$(( base+y*TCOLS+x ))
    cr=$(( 16#${cell[0,1]} )); cg=$(( 16#${cell[2,3]} )); cb=$(( 16#${cell[4,5]} ))
    if [[ "$cell" == *@* ]]; then
      w=$(( ${cell##*@} / 100.0 )); c=${GB[$kk]:-$GLASS}
      br=$(( (c>>16)&255 )); bg2=$(( (c>>8)&255 )); bb=$(( c&255 ))
      cr=$(( int(br+(cr-br)*w) )); cg=$(( int(bg2+(cg-bg2)*w) )); cb=$(( int(bb+(cb-bb)*w) ))
    fi
    v_put $x $y ' ' $GREY $(( ((cr&0xFC)<<16)|((cg&0xFC)<<8)|(cb&0xFC) ))
  done
}

xg_port_spill() {   # the window's light · a halo on the wall, a pool on the deck, beams by day
  local -i fy=$1 bot=$2 x y k base lc bx
  local -F cxp cyp dx dy d R=$XP_R t str sh
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  cxp=$(( XP_CX+0.5 )); cyp=$(( 2.0*XP_ROW+1.0 ))
  if (( ! XP_NIGHT )); then _pack 255 226 168; lc=$PK; str=0.34; sh=-3.0
  elif (( XP_TW )); then _pack 236 150 112; lc=$PK; str=0.24; sh=0.0
  else _pack 150 170 226; lc=$PK; str=0.18; sh=0.0; fi
  (( ! XP_NIGHT && XP_TW )) && { _pack 244 170 110; lc=$PK; str=0.26; }
  for (( y=XP_ROW-XP_R/2-4; y<=XP_ROW+XP_R/2+4; y++ )); do      # the halo, just outside the ring
    (( y<2 || y>=fy )) && continue
    for (( x=XP_CX-XP_R-8; x<=XP_CX+XP_R+8; x++ )); do
      (( x<0 || x>=SCR_W )) && continue
      dx=$(( x+0.5-cxp )); dy=$(( 2*y+1.0-cyp )); d=$(( sqrt(dx*dx+dy*dy) ))
      (( d <= R+0.5 || d > R+8.0 )) && continue
      t=$(( 1.0-(d-R)/8.0 )); t=$(( t*t*str*0.55 ))
      k=$(( base+y*TCOLS+x )); cmix ${GB[$k]:-$GLASS} $lc $t; v_tint $x $y $CM
    done
  done
  if (( ! XP_NIGHT )); then                                      # by day · two long beams, down-left
    for (( y=XP_ROW+XP_R/2+1; y<fy; y++ )); do
      for bx in -2 7; do
        for (( x=XP_CX+bx-(y-XP_ROW)-4; x<=XP_CX+bx-(y-XP_ROW)+4; x++ )); do
          (( x<0 || x>=SCR_W )) && continue
          dx=$(( x-(XP_CX+bx-(y-XP_ROW)) )); t=$(( (1.0-abs(dx)/4.5)*str*0.30 )); (( t <= 0.0 )) && continue
          k=$(( base+y*TCOLS+x )); cmix ${GB[$k]:-$GLASS} $lc $t; v_tint $x $y $CM
        done
      done
    done
  fi
  for (( y=fy; y<=bot; y++ )); do                                # the pool on the deck
    for (( x=XP_CX-XP_R-10; x<=XP_CX+XP_R+10; x++ )); do
      (( x<0 || x>=SCR_W )) && continue
      dx=$(( (x+0.5-cxp-sh-(y-fy)*(XP_NIGHT?0.0:1.6))/(R+10.0) )); t=$(( 1.0-dx*dx )); (( t <= 0.0 )) && continue
      t=$(( t*t*str*(1.0-(y-fy)*0.14) )); (( t <= 0.0 )) && continue
      k=$(( base+y*TCOLS+x )); cmix ${GB[$k]:-$GLASS} $lc $t; v_tint $x $y $CM
    done
  done
}

xg_port_bake() {   # xg_port_bake RX FY BOT SPAN ZOOM — the window, its sky, its light
  xg_port_sky
  xg_port_geom $1 $2 $4 $5
  xg_port_glass
  xg_port_spill $2 $3
  xg_port_earth; xg_port_interior               # dealt now, so a pass never starts with a hitch
  return 0
}

xg_port_ramps() {   # five-step brightness ramps · stars, and the two running-light colours
  (( ${#XP_FAR[@]} )) && return 0
  local -i i a b
  _pack 34 42 74; a=$PK;  _pack 150 166 214; b=$PK
  for (( i=0; i<5; i++ )); do cmix $a $b $(( i/4.0 )); XP_FAR+=($CM); done
  _pack 110 122 176; a=$PK; _pack 240 244 255; b=$PK
  for (( i=0; i<5; i++ )); do cmix $a $b $(( i/4.0 )); XP_NEAR+=($CM); done
  cshade $AMBER 0.35; a=$CS; cmix $AMBER $WHITE 0.35; b=$CM
  for (( i=0; i<5; i++ )); do cmix $a $b $(( i/4.0 )); XP_AMB+=($CM); done
  cshade $CYAN 0.35; a=$CS; cmix $CYAN $WHITE 0.35; b=$CM
  for (( i=0; i<5; i++ )); do cmix $a $b $(( i/4.0 )); XP_CYN+=($CM); done
}

xg_port_pass() {   # xg_port_pass [TS] — is the ship over EARTH? → REPLY progress 0..1, or -1
  # Real time, in 45-minute slots: about half the slots hold one pass of two
  # and a half minutes, at a time dealt from the slot's own hash.  Rare, and
  # the same for everyone looking.
  (( XP_PASS_FORCE >= 0.0 )) && { REPLY=$XP_PASS_FORCE; return 0; }
  local -F now=${1:-${EPOCHREALTIME:-${EPOCHSECONDS:-0}}} st
  local -i slot=$(( int(now/XP_PASS_EVERY) ))
  xg_gh $slot 4201
  (( XG_H % 100 < 50 )) || { REPLY=-1; return 0; }
  st=$(( slot*XP_PASS_EVERY + (XG_H/100) % (XP_PASS_EVERY-XP_PASS_LEN) ))
  if (( now >= st && now < st+XP_PASS_LEN )); then REPLY=$(( (now-st)/XP_PASS_LEN )); else REPLY=-1; fi
}

xg_port_earth() {   # the planet's face, dealt once per window size and day/night
  # A texture in cells around the planet's centre · XP_EC colour, XP_EA cover
  # (0..100, the sub-pixels it owns); the limb and a thin air are in its edge.
  local key="$XP_R.$XP_NIGHT"
  [[ "$key" == "$XP_EKEY" ]] && return 0
  local -i x y s tx ty ocean land lights atm cloud oday lday c a cc ca r0 g0 b0 wsum
  local -F R=$XP_R er ey dx dy d n
  _pack 6 16 34; ocean=$PK; _pack 14 26 22; land=$PK; _pack 196 138 70; lights=$PK
  _pack 70 150 232; atm=$PK; _pack 224 230 238; cloud=$PK; _pack 32 88 170; oday=$PK; _pack 72 122 66; lday=$PK
  er=$(( R*1.3 )); ey=$(( R*1.36 ))                  # centre below the window's, in sub-pixels
  XP_EOX=$(( int(er)+3 )); XP_EW=$(( 2*XP_EOX+1 ))
  XP_EOY=$(( int(floor((ey-er-2.0)/2.0)) ))          # the texture's first row, window-relative
  XP_EH=$(( int(R/2)+1-XP_EOY+1 ))
  XP_EC=(); XP_EA=()
  for (( ty=0; ty<XP_EH; ty++ )); do
    for (( tx=0; tx<XP_EW; tx++ )); do
      r0=0; g0=0; b0=0; wsum=0
      for s in 0 1; do
        dx=$(( tx-XP_EOX )); dy=$(( 2*(ty+XP_EOY)+s-0.5-ey ))
        d=$(( sqrt(dx*dx+dy*dy) ))
        if (( d <= er )); then
          n=$(( sin(dx*0.41+dy*0.13)+sin(dy*0.58-dx*0.22) ))
          if (( XP_NIGHT )); then
            if (( n > 0.7 )); then c=$land; xg_gh $(( (tx*131+(2*ty+s)*977)&0xFFFFFF )) 5; (( XG_H % 11 == 0 )) && c=$lights
            else c=$ocean; fi
          else
            if (( n > 0.7 )); then c=$lday; else c=$oday; fi
            n=$(( sin(dx*0.9+dy*0.25+2.0)*sin(dy*0.7) )); (( n > 0.45 )) && c=$cloud
          fi
          (( d > er-0.9 )) && { cmix $c $atm 0.40; c=$CM; }     # the limb, lit
          a=100
        elif (( d <= er+1.8 )); then
          c=$atm; a=$(( int(42.0*(1.0-(d-er)/1.8)) ))          # the thin air
        else c=0; a=0; fi
        (( a > 0 )) && { r0+=$(( ((c>>16)&255)*a )); g0+=$(( ((c>>8)&255)*a )); b0+=$(( (c&255)*a )); wsum+=$a; }
      done
      if (( wsum > 0 )); then
        cc=$(( (((r0/wsum)&0xFC)<<16)|(((g0/wsum)&0xFC)<<8)|((b0/wsum)&0xFC) )); ca=$(( wsum/2 ))
      else cc=0; ca=0; fi
      XP_EC+=($cc); XP_EA+=($ca)
    done
  done
  XP_EKEY="$key"
}

xg_port_interior() {   # the glass's own cells (both sub-pixels clear of the seal), by row
  [[ "$XP_INKEY" == "$XP_R" ]] && return 0
  local -i x y; local -F dx dy R2=$(( XP_R-4.2 ))
  XP_INX=(); XP_INY=()
  for (( y=-XP_R/2-1; y<=XP_R/2+1; y++ )); do
    for (( x=-XP_R; x<=XP_R; x++ )); do
      dx=$(( x+0.5-0.5 )); dy=$(( 2*y-1.0+0.5 ))
      (( dx*dx+dy*dy <= R2*R2 && dx*dx+(dy+1.0)*(dy+1.0) <= R2*R2 )) || continue
      XP_INX+=($x); XP_INY+=($y)
    done
  done
  XP_INKEY="$XP_R"
}

xg_port_live() {   # xg_port_live RX FY SPAN ZOOM — stars drift, lights chase, Earth now and then
  local -i rx=$1 fy=$2 span=$3 zoom=$4 i n nf col row s ok lv ci base k tx ty a ecx c pr pg pb
  local -F t=$XG_NOW cxp cyp dx dy xr sp R2 b pass
  xg_port_geom $(( rx-XG_CAM )) $fy $span $zoom
  (( XP_CX+XP_R+4 < 0 || XP_CX-XP_R-4 >= SCR_W )) && return 0          # off camera
  xg_port_ramps
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  cxp=$(( XP_CX+0.5 )); cyp=$(( 2.0*XP_ROW+1.0 )); R2=$(( XP_R-4.6 ))
  # ── EARTH · a rare pass, the planet slid straight into the grid ──
  xg_port_pass; pass=$REPLY; ecx=-9999
  if (( pass >= 0.0 )); then
    xg_port_earth; xg_port_interior
    ecx=$(( XP_CX + int((1.0-2.0*pass)*(XP_R+XP_EOX+2)) ))
    n=${#XP_INX[@]}
    for (( i=0; i<n; i++ )); do
      row=$(( XP_ROW+XP_INY[i] )); ty=$(( XP_INY[i]-XP_EOY ))
      (( ty < 0 || ty >= XP_EH )) && continue
      col=$(( XP_CX+XP_INX[i] )); tx=$(( col-ecx+XP_EOX ))
      (( tx < 0 || tx >= XP_EW || col < 0 || col >= SCR_W || row < 0 || row >= SCR_H )) && continue
      a=${XP_EA[$(( ty*XP_EW+tx ))]}; (( a <= 0 )) && continue
      c=${XP_EC[$(( ty*XP_EW+tx ))]}; k=$(( base+row*TCOLS+col ))
      if (( a < 99 )); then
        pr=${GB[$k]:-$GLASS}
        c=$(( (((((pr>>16)&255)*(100-a)+((c>>16)&255)*a)/100)&0xFC)<<16 | (((((pr>>8)&255)*(100-a)+((c>>8)&255)*a)/100)&0xFC)<<8 | ((((pr&255)*(100-a)+(c&255)*a)/100)&0xFC) ))
      fi
      GCH[$k]=' '; GF[$k]=$c; GB[$k]=$c
    done
  fi
  # ── the stars · a table dealt once per window size ──
  if [[ "$XP_STARKEY" != "$XP_R" ]]; then
    XP_SX=(); XP_SY=(); XP_SL=(); XP_SP=()
    nf=$(( zoom ? 16 : 26 )); n=$(( nf + (zoom ? 6 : 9) ))
    for (( i=0; i<n; i++ )); do
      xg_gh 7919 $i;   XP_SX+=($(( XG_H % (2*XP_R) - XP_R )))
      xg_gh 104729 $i; XP_SY+=($(( XG_H % XP_R - XP_R/2 )))
      XP_SL+=($(( i >= nf ))); XP_SP+=($(( (XG_H % 628)/100.0 )))
    done
    XP_STARKEY="$XP_R"
  fi
  n=${#XP_SX[@]}
  for (( i=0; i<n; i++ )); do
    if (( XP_SL[i] )); then sp=0.9; else sp=0.35; fi
    xr=$(( XP_SX[i]-sp*t )); xr=$(( xr-2.0*XP_R*floor((xr+XP_R)/(2.0*XP_R)) ))
    col=$(( XP_CX+int(floor(xr)) )); row=$(( XP_ROW+XP_SY[i] ))
    ok=1
    for s in 0 1; do
      dx=$(( col+0.5-cxp )); dy=$(( 2*row+s+0.5-cyp ))
      (( dx*dx+dy*dy > R2*R2 )) && { ok=0; break; }
    done
    (( ok )) || continue
    if (( col >= XP_CARDX && col < XP_CARDX+12 && row >= XP_CARDY && row < XP_CARDY+6 )); then
      ci=$(( (row-XP_CARDY)*12+col-XP_CARDX ))
      [[ "${XP_TOK[$ci]:--}" != '-' ]] && continue                 # behind the sun or moon
    fi
    if (( ecx > -9999 )); then                                     # behind the planet
      ty=$(( row-XP_ROW-XP_EOY )); tx=$(( col-ecx+XP_EOX ))
      (( ty >= 0 && ty < XP_EH && tx >= 0 && tx < XP_EW )) && (( XP_EA[ty*XP_EW+tx] > 0 )) && continue
    fi
    if (( XP_SL[i] )); then
      b=$(( 0.72+0.28*sin(t*2.3+XP_SP[i]) )); lv=$(( int(b*4.0+0.5) ))
      v_put $col $row '•' ${XP_NEAR[$lv]}
    else
      b=$(( 0.55+0.45*sin(t*1.7+XP_SP[i]) )); lv=$(( int(b*4.0+0.5) ))
      v_put $col $row '·' ${XP_FAR[$lv]}
    fi
  done
  # ── the running lights, chasing slowly round the hull ring ──
  local -F ang q w; local g
  for (( i=0; i<18; i++ )); do
    ang=$(( i*0.349066 ))
    col=$(( int(floor(cxp+(XP_R+2.2)*cos(ang))) )); row=$(( int(floor((cyp+(XP_R+2.2)*sin(ang))/2.0)) ))
    (( row < 2 || row >= fy )) && continue                        # never over the header
    w=$(( ang-t*0.8 )); q=$(( cos(w) )); (( q < 0.0 )) && q=0.0
    q=$(( 0.25+0.75*q**6 )); lv=$(( int(q*4.0+0.5) ))
    g='•'; (( lv >= 3 )) && g='●'
    if (( i%2 )); then v_put $col $row "$g" ${XP_CYN[$lv]}; else v_put $col $row "$g" ${XP_AMB[$lv]}; fi
  done
  return 0
}

xg_walls() {   # xg_walls S WW TOP BOT MIDY — the hull's end walls cap the world
  # (drawn per bake pass, shifted by S) · steel jamb, a bright seam on its
  # inner face, and the three little gauges the near wall used to carry.
  local -i s=$1 ww=$2 top=$3 bot=$4 midy=$5 y x0 x1 x2 x3 gx
  x0=$(( 0-s )); x1=$(( 1-s )); x2=$(( ww-2-s )); x3=$(( ww-1-s ))
  for (( y=top; y<=bot; y++ )); do
    v_put $x0 $y ' ' $GREY $CR_CASE
    v_put $x1 $y '▏' $CR_CASE_HI
    v_put $x2 $y '▕' $CR_CASE_HI
    v_put $x3 $y ' ' $GREY $CR_CASE
  done
  gx=$(( 2-s ))
  cshade $LIME 1.0;   v_put $gx $(( midy-2 )) '●' $CS
  cshade $AMBER 0.95; v_put $gx $midy '●' $CS
  cshade $CYAN 1.0;   v_put $gx $(( midy+2 )) '●' $CS
  return 0
}

# ── the WORLD cache · the room is baked WIDER than the glass — two shifted
#    passes of the same room stitched into one world-wide image — and each
#    frame the camera's slice of it is blitted back onto the glass.
#    (the same GCH row-slice idiom the cabinet's modal uses, with an offset.)
typeset -g XG_RCK=''
typeset -ga XG_RCH XG_RCF XG_RCB
typeset -gi XG_WW=0 XG_CAM=0
typeset -gF XG_CAMF=-1.0
xg_rc_save_slice() {   # xg_rc_save_slice S — this pass's glass into world cols S..
  local -i s=$1 base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )) y k0 w0
  for (( y=0; y<SCR_H; y++ )); do
    k0=$(( base+y*TCOLS )); w0=$(( y*XG_WW+s ))
    XG_RCH[$w0,$(( w0+SCR_W-1 ))]=("${(@)GCH[@]:$k0:$SCR_W}")
    XG_RCF[$w0,$(( w0+SCR_W-1 ))]=("${(@)GF[@]:$k0:$SCR_W}")
    XG_RCB[$w0,$(( w0+SCR_W-1 ))]=("${(@)GB[@]:$k0:$SCR_W}")
  done
}
xg_rc_load() {   # xg_rc_load CAM — the camera's slice of the world, onto the glass
  local -i cam=$1 base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )) y k0 w0
  for (( y=0; y<SCR_H; y++ )); do
    k0=$(( base+y*TCOLS )); w0=$(( y*XG_WW+cam ))
    GCH[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_RCH[@]:$w0:$SCR_W}")
    GF[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_RCF[@]:$w0:$SCR_W}")
    GB[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_RCB[@]:$w0:$SCR_W}")
  done
}

# WHAT THE ROOM IS A PICTURE OF · the glass, the house, the animal's kind, the
# sky over it and a gift on the floor.  One spelling, read by xg_draw_home and
# by xg_warm, so a room built ahead of time is one HOME recognises.
typeset -g XG_RKEY=''
xg_room_key() {   # -> XG_RKEY
  XG_RKEY="${SCR_W}x${SCR_H}.${XG_HOUSE[style]:-std}.${XG_HOUSE[kibble]:-std}.${XG_HOUSE[toy]:-none}.${XG[species]:-cat}.${SKY_IDX:-x}.${XG_HOUSE[bed]:-0}.${XG_HOUSE[bowl]:-0}.${XG[gift]:+gift}"
  return 0
}
xg_draw_home() {
  local -i i lc rx ry rw rh fy cx bot catc catx caty spann k mx my pp1 zoom=0 mspan mx0
  local -i ww maxcam wccx s scx smx want camL camR
  local -F pp camd
  (( XG_CORE_PAL )) || { xg_core_pal; XG_CORE_PAL=1; }
  # FULL BLEED, AND A WIDER WORLD BEHIND IT · the room itself runs 64 cells
  # past what the glass can show; the glass is a CAMERA into it, panning
  # inside the same fixed border · nothing is ever drawn outside the frame.
  # It holds still while the animal keeps to the middle of the frame and
  # pans when a walk carries it toward an edge · walk on, and more room
  # arrives · the world is capped by real hull walls, where it turns back.
  rx=-1; ry=0; rh=$(( SCR_H-2 )); fy=$(( ry+rh-4 )); cx=$(( SCR_W/2 )); bot=$(( ry+rh-1 ))
  ww=$(( SCR_W+64 )); rw=$(( ww+2 )); maxcam=$(( ww-SCR_W ))
  spann=$(( ww-40 )); (( spann<1 )) && spann=1
  XG_SPAN_W=$(( spann*1.0 ))
  (( rh < 30 )) && zoom=1
  wccx=$(( rx+36 ))                    # the column's WORLD spot · env draws it there
  # the static room · from the world cache, or baked once for this glass size:
  # two shifted passes of the same room, stitched · right pass first, so the
  # left pass owns the seam and every prop shadow lands whole
  xg_room_key; local rck="$XG_RKEY"
  if [[ "$rck" != "$XG_RCK" ]]; then
    XG_WW=$ww; XG_RCH=(); XG_RCF=(); XG_RCB=()
    for s in $maxcam 0; do
      v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
      xg_core_env $(( rx-s )) $ry $rw $rh $fy $cx
      xg_port_bake $(( rx-s )) $fy $bot $spann $zoom
      xg_draw_furniture $(( rx-s )) $rw $fy $spann
      xg_walls $s $ww $(( ry+1 )) $bot $(( (ry+1+fy)/2 ))
      xg_rc_save_slice $s
    done
    XG_RCK="$rck"
  fi
  # the animal's spot in the WORLD, this frame
  xg_anim; xg_cache_pose
  catc=$(( rx+3+int(${XG_A[fx]:-0.5}*spann)+18 ))
  # ── the camera · still in the middle, a soft follow at the edges ──
  camL=$(( SCR_W*34/100 )); camR=$(( SCR_W*66/100 ))
  if (( XG_CAMF < -0.5 )); then
    XG_CAMF=$(( catc-SCR_W/2.0 ))                        # first sight · centred
  else
    scx=$(( catc-XG_CAM ))        # the camera follows always now · nothing stands over the room
    want=$XG_CAM
    (( scx < camL )) && want=$(( catc-camL ))
    (( scx > camR )) && want=$(( catc-camR ))
    camd=$(( (want-XG_CAMF)*0.22 ))
    (( camd >  1.8 )) && camd=1.8
    (( camd < -1.8 )) && camd=-1.8
    XG_CAMF=$(( XG_CAMF+camd ))
  fi
  (( XG_CAMF < 0.0 )) && XG_CAMF=0.0
  (( XG_CAMF > maxcam )) && XG_CAMF=$(( maxcam*1.0 ))
  XG_CAM=$(( int(XG_CAMF+0.5) ))
  # THE CAMERA'S SLICE IS BAKED INTO THE CABINET'S STILL LAYER (glass_bake):
  # the room was being put back on the glass every frame, a hundred and
  # sixty slices of it; now it goes back only when the camera or the room
  # moves, and frame_begin's own copy carries it the rest of the time
  if (( ${+functions[glass_baked]} )); then
    glass_baked "xg.room|$XG_RCK|$XG_CAM" || { xg_rc_load $XG_CAM; glass_bake "xg.room|$XG_RCK|$XG_CAM"; }
  else
    xg_rc_load $XG_CAM
  fi
  # ── the live layer, over the camera's slice, every frame ──
  xg_head HOME 1 \
     DAY "${XG[day]:-0}" $XG_WHITE \
     CREDITS "${XG[credits]:-0}" $XG_FG
  cmix $AMBER $WHITE 0.25; v_text 2 1 ' THE ROOM ' $CM
  xg_room_vitals
  local rlab="${XG[name]:-—} · ${XG[stage]:-}"
  cshade $AMBER 0.8; v_text $(( SCR_W-3-${#rlab} )) 1 "$rlab" $CS
  # the core breathes, and the motes drift up · the shell holds still
  if (( ! zoom )); then
    scx=$(( wccx-XG_CAM ))
    if (( scx >= 1 && scx < SCR_W-1 )); then
      pp=$(( 0.5+0.5*sin(XG_NOW*1.4) ))
      cmix $CR_E1B $CR_HOT $(( 0.35+0.65*pp )); pp1=$CM
      for (( k=ry+2; k<fy; k++ )); do
        (( (k-ry-1)%4==0 )) && continue
        v_put $scx $k ' ' $GREY $pp1
      done
    fi
    mx0=$(( wccx-16 )); mspan=33
  else
    mx0=2; mspan=40
  fi
  cshade $CR_GLOW 1.15
  for (( k=0; k<12; k++ )); do
    mx=$(( mx0+(k*29)%mspan ))
    my=$(( ry+3 + ( (k*13) + 1000000 - int(XG_NOW*2.0) ) % (fy-ry-5) ))
    smx=$(( mx-XG_CAM ))
    (( smx<1 || smx>=SCR_W-1 || my<2 )) && continue
    v_put $smx $my '·' $CS
  done
  xg_port_live $rx $fy $spann $zoom           # the window · stars, running lights, Earth now and then
  # the occupant · centre-anchored in the WORLD · the camera does the rest
  catx=$(( catc-XG_CAM-XG_CCW/2 )); caty=$(( fy-XG_CCH+1 ))
  (( caty < ry+2 )) && caty=$(( ry+2 ))
  xg_shadow $(( catc-XG_CAM )) $fy $(( XG_CCW-12 )) 0.45
  xg_shadow $(( catc-XG_CAM )) $(( fy+1 )) $(( XG_CCW-4 )) 0.80
  xg_blit_cells $catx $caty
  xg_lz_draw $fy                               # the red dot, when it is out
  # THE LOG · newest first, ON THE DECK -- so it is inked for the deck.  It
  # used to ride the deck's own light in the ramp measured against the GLASS,
  # which put the one line you read every visit at 1.22:1 against the hull's
  # teal.  XI_DECK and XI_DECKD are the same two voices, lifted for a lit
  # ground; a log line that carries its own colour is mixed toward white for
  # the same reason rather than shaded toward the floor.
  (( XI_DECK )) || xg_ink
  local -i ly=$(( fy+2 )) lx0=2 lend=2   # no same-statement self-reference in zsh
  xg_log_scrim $ly 2
  if (( ${XG_LZ[on]:-0} )); then
    cmix $RED $WHITE 0.55
    local dot="● the red dot · $(( int(XG_LZ[until]-XG_NOW+0.99) ))s · ${XG_LZ[catches]} caught · the arrows steer it"
    v_text $lx0 $ly "$dot" $CM; lend=$(( lx0+${#dot} ))
  fi
  for (( i=${XG_LZ[on]:-0}; i<2 && i<XG_LOG_N+${XG_LZ[on]:-0}; i++ )); do
    k=$(( i-${XG_LZ[on]:-0} ))
    lc=${XG_LOG_C[$k]}
    v_put $lx0 $(( ly+i )) '·' $XI_DECKD
    if (( i>0 )); then cmix $lc $WHITE 0.55; lc=$CM; else cmix $lc $WHITE 0.30; lc=$CM; fi
    v_text $(( lx0+2 )) $(( ly+i )) "${XG_LOG_T[$k]}" $lc
    [[ -n "${XG_LOG_G[$k]}" ]] && v_text $(( lx0+2+${#XG_LOG_T[$k]}+2 )) $(( ly+i )) "${XG_LOG_G[$k]}" $lc
    (( i == 0 )) && lend=$(( lx0+2+${#XG_LOG_T[$k]}+(${#XG_LOG_G[$k]} ? ${#XG_LOG_G[$k]}+2 : 0) ))
  done
  (( XG_LOG_N == 0 && ! ${XG_LZ[on]:-0} )) && {
    local quiet='a quiet day · [F] feed  [W] water  ⏎ pet'
    v_text $lx0 $ly "$quiet" $XI_DECK; lend=$(( lx0+${#quiet} )) }
  # ── who it is, low on the right · and NOT one column further left ──
  #    This line used to be drawn wherever its own length put it.  The wider
  #    intake brought longer tempers ("a professional at rest · a theatrical
  #    streak") and an unbounded line here walked straight through the hints
  #    on the left, so it is cut to whatever the left half has left over.
  local right="${XG[temper]:-} · ${XG[left]:-}" rt
  local -i ravail=$(( SCR_W-3-lend-3 ))
  if (( ravail > 8 )); then
    xg_ell "$right" $ravail; rt="$REPLY"
    v_text $(( SCR_W-3-${#rt} )) $ly "$rt" $XI_DECKD
  fi
  if (( ${XG_LZ[on]:-0} )); then app_nav '◂ ▸ ▴ ▾' 'steer the dot' '[⎋]' menu
  elif [[ -n "${XG[gift]:-}" ]]; then
    app_nav '[F]' feed '[W]' water '[P]' play '[G]' groom '[T]' treat '[B]' scoop '⏎' pet '[S]' stats '[A]' admire '[⎋]' menu
  else
    app_nav '[F]' feed '[W]' water '[P]' play '[G]' groom '[T]' treat '[B]' scoop '⏎' pet '[S]' stats '◂▸' pages '[⎋]' menu
  fi
  return 0
}

# the rename field's state · the STATS page owns it (see THE ROSTER, below)
typeset -gi XG_RENAME=0; typeset -g XG_RENAME_BUF=''

# ══════════════════════════════════════════════════════════════════════════
# AGE · a life on the real clock · the original's stages, dealt and grown
# ══════════════════════════════════════════════════════════════════════════
# Every animal has its own span (a cat's seventeen years, ±15% by its seed)
# and an age.  Arrivals are dealt one — mostly the young; sometimes the
# overlooked, who also deserve a home — and from the day they come home they
# age on the wall clock.  The stage is a fraction of the span: KITTEN, JUNIOR,
# YOUNG CAT, CAT, MATURE CAT, SENIOR.  A kitten does everything in a kitten's
# body, a young cat is drawn a little smaller, a senior greys a little.
typeset -ga XG_STAGE_LO XG_STAGE_NM XG_STAGE_FORM XG_STAGE_SCALE
XG_STAGE_LO=(0.0 0.04 0.10 0.22 0.60 0.78)
XG_STAGE_NM=(KITTEN JUNIOR 'YOUNG CAT' CAT 'MATURE CAT' SENIOR)
XG_STAGE_FORM=(baby baby adult adult adult adult)
typeset -gi XG_SENIOR=0                  # the render greys the coat while this is set

# ══════════════════════════════════════════════════════════════════════════
# GROWING UP · one size for every day of a life, not six sizes for six stages
# ══════════════════════════════════════════════════════════════════════════
# THE OLD WAY WAS A LADDER OF FOUR RUNGS -- baby×1.00, baby×1.22, adult×0.85,
# adult×1.00 -- and one ladder for fifteen species whose two drawings are not
# in the same proportion to each other.  A cat's adult drawing is 1.53× its
# kitten; a hedgehog's is 1.25×.  So on the rung where the drawing changes the
# cat jumped 6% bigger and THE HEDGEHOG GOT 13% SMALLER as it grew up.
#
# THE SIZE IS A FUNCTION OF THE ANIMAL'S OWN AGE now, measured against its own
# span, and the drawing that carries it is chosen separately.  Both drawings
# are scaled to the SAME target height, so on the day an animal changes shape
# it does not change size: what you see is a body filling out, not a body
# swapped.  It grows fast and then slows, the way animals do, and it is done
# growing when it reaches the stage that bears the species' plain name.
#
# THE HEIGHTS ARE THE DRAWINGS' OWN, measured off each species' sit pose with
# no genes on it.  They are written here so no render has to measure, and
# test_xenogrow re-measures every one of them so they cannot drift.
typeset -gA XG_SP_AH XG_SP_BH
XG_SP_AH=(cat 29 dog 29 rabbit 29 hamster 17 fox 30 turtle 20 hedgehog 15 glorp 20
          xeno 31 duck 20 frog 14 snake 18 owl 22 pig 22 axolotl 16
          guineapig 19 ferret 22 rat 21 chinchilla 25 goat 27 gecko 13 sugarglider 21 parrot 24 penguin 26 drifter 20)
XG_SP_BH=(cat 19 dog 19 rabbit 20 hamster 13 fox 19 turtle 15 hedgehog 12 glorp 13
          xeno 18 duck 15 frog 10 snake 13 owl 15 pig 15 axolotl 12
          guineapig 13 ferret 16 rat 15 chinchilla 19 goat 19 gecko 9 sugarglider 15 parrot 16 penguin 16 drifter 11)
# A NEWBORN IS NEVER SMALLER THAN THIS MANY PIXELS TALL.  Thirty-eight per
# cent of an adult is about right for a kitten and far too little for a frog,
# whose adult is fourteen pixels: five pixels of frog is a smudge.
typeset -gF XG_GROW_MINPX=8.0 XG_GROW_NEW=0.38 XG_GROW_EASE=0.62 XG_GROW_W=1.0

xg_breed_size() {   # xg_breed_size SPECIES [BREED] → REPLY · its size, 1.0 if unknown
  # THIS DOES NOT GO THROUGH xg_breed_pick, which writes the whole XB_* set.
  # The render wants one number and must not disturb what the dealer left.
  REPLY=1.0
  [[ -n "${2:-}" ]] || return 0
  xg_deck "$1"
  local -i i
  for (( i=0; i<${#XK_BRN[@]}; i++ )); do
    [[ "${XK_BRN[$i]}" == "$2" ]] && { REPLY=${XK_BRSZ[$i]}; return 0 }
  done
  return 0
}

xg_grow() {   # xg_grow SPECIES LIFEFRAC STAGE [BREED] → REPLY · 1.0 is full-grown
  local sp="$1"; local -F f=$2; local -i st=$3; local br="${4:-}"
  local -a lo; local -F grown u t newb ah
  if [[ -n "${XG_SP_LO[$sp]:-}" ]]; then lo=(${=XG_SP_LO[$sp]}); else lo=("${XG_STAGE_LO[@]}"); fi
  grown=${lo[3]}; (( grown <= 0.0 )) && grown=0.22
  ah=${XG_SP_AH[$sp]:-24}
  u=$(( f/grown )); (( u < 0.0 )) && u=0.0; (( u > 1.0 )) && u=1.0
  newb=$(( XG_GROW_MINPX/ah )); (( newb < XG_GROW_NEW )) && newb=$XG_GROW_NEW
  (( newb > 0.80 )) && newb=0.80
  t=$(( newb + (1.0-newb)*(u**XG_GROW_EASE) ))
  # THE TWO STAGES PAST FULL GROWN do not keep growing -- they settle.  This
  # is the height; the WIDTH is XG_GROW_W, because a mature animal broadens
  # rather than lengthens and an old one draws in.  Without that, MATURE and
  # the plain adult are the same picture and one of the six stages is a lie.
  XG_GROW_W=1.0
  (( st == 4 )) && { t=$(( t*1.02 )); XG_GROW_W=1.07 }
  (( st == 5 )) && { t=$(( t*0.97 )); XG_GROW_W=0.95 }
  # WHAT IT WAS BRED AS, at three parts in five.  A Sulcata really is two and
  # a half times a Fennec, and two and a half times would not fit the room, so
  # the spread is compressed to 0.73..1.27 -- a Great Dane still stands half
  # again over a Chihuahua, and the tallest of them still clears the ceiling.
  xg_breed_size "$sp" "$br"
  t=$(( t*(1.0+(REPLY-1.0)*0.60) ))
  REPLY=$t
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE SPECIES · shipment 01 landed the cat · shipment 02 is the dog
# ══════════════════════════════════════════════════════════════════════════
# An ARRIVAL'S species falls out of its own seed, so a litter comes up mixed
# and nothing extra has to be stored to deal one.  A RESIDENT'S species is
# whatever the save says, because a pet adopted before the dog landed is a
# cat whatever its seed would hash to now.  Every call that needs a species
# takes it as an argument: the arrival's from its seed, the resident's from
# the save.  Nothing infers it from the animal in the room.
typeset -ga XG_SPECIES XG_SP_DISP XG_SP_LATIN XG_SP_SHIP XG_SP_YEARS XG_SP_BABY
# THE INTAKE, whole.  The order is the order the shipments arrived in, and a
# seed's species falls out of it -- so widening this list re-deals what the
# ADOPT page offers, and never touches an animal already signed for: a
# resident's species is written in its save and read from there.
XG_SPECIES=(cat dog rabbit hamster fox turtle hedgehog glorp xeno duck frog snake owl pig axolotl guineapig ferret rat chinchilla goat gecko sugarglider parrot penguin drifter)
XG_SP_DISP=('EARTH CAT' 'EARTH DOG' 'EARTH RABBIT' 'EARTH HAMSTER' 'EARTH FOX' 'EARTH TURTLE' 'EARTH HEDGEHOG' 'GLORP' 'XENOMORPH' 'EARTH DUCK' 'EARTH FROG' 'EARTH SNAKE' 'EARTH OWL' 'EARTH PIG' 'EARTH AXOLOTL' 'EARTH GUINEA PIG' 'EARTH FERRET' 'EARTH RAT' 'EARTH CHINCHILLA' 'EARTH GOAT' 'EARTH GECKO' 'EARTH SUGAR GLIDER' 'EARTH PARROT' 'EARTH PENGUIN' 'VOID DRIFTER')
XG_SP_LATIN=('FELIS CATUS' 'CANIS FAMILIARIS' 'ORYCTOLAGUS CUNICULUS' 'MESOCRICETUS AURATUS' 'VULPES VULPES' 'TESTUDINES SP.' 'ATELERIX ALBIVENTRIS' 'XENOFAUNA VISCOSA' 'ORGANISMUS PERFECTUS' 'ANAS PLATYRHYNCHOS' 'ANURA SP.' 'SERPENTES SP.' 'STRIGIFORMES SP.' 'SUS DOMESTICUS' 'AMBYSTOMA MEXICANUM' 'CAVIA PORCELLUS' 'MUSTELA FURO' 'RATTUS NORVEGICUS' 'CHINCHILLA LANIGERA' 'CAPRA HIRCUS' 'GEKKOTA SP.' 'PETAURUS BREVICEPS' 'PSITTACIFORMES SP.' 'SPHENISCIDAE SP.' 'NOCTILUCA VAGANS')
XG_SP_SHIP=('01' '02' '03' '04' '05' '06' '07' 'X1' 'X2' '08' '09' '10' '11' '12' '13' '14' '15' '16' '17' '18' '19' '20' '21' '22' 'X3')
XG_SP_YEARS=(17.0 12.0 10.0 2.5 12.0 60.0 5.5 99.0 60.0 10.0 12.0 25.0 17.0 15.0 12.0 6.0 8.0 3.0 15.0 16.0 15.0 13.0 35.0 20.0 45.0)
typeset -gA XG_SP_NM
# six stages each · a bar in a name is a space, because the list is split on
# spaces and a MATURE HEDGEHOG is two words for one stage
XG_SP_NM[cat]='KITTEN JUNIOR YOUNG|CAT CAT MATURE|CAT SENIOR'
XG_SP_NM[dog]='PUPPY JUNIOR YOUNG|DOG DOG MATURE|DOG SENIOR'
XG_SP_NM[rabbit]='KIT JUNIOR YOUNG|RABBIT RABBIT MATURE SENIOR'
XG_SP_NM[hamster]='PUP WEANLING YOUNG|HAMSTER HAMSTER MATURE SENIOR'
XG_SP_NM[fox]='KIT CUB JUVENILE FOX MATURE|FOX SENIOR'
XG_SP_NM[turtle]='HATCHLING YEARLING JUVENILE TURTLE MATURE ELDER'
XG_SP_NM[hedgehog]='HOGLET WEANLING JUVENILE HEDGEHOG MATURE SENIOR'
XG_SP_NM[glorp]='BLOBLET DROPLET DEMI-GLORP GLORP GREATER|GLORP ELDER|GLORP'
XG_SP_NM[xeno]='CHESTBURSTER SERPENT YOUNG|XENO XENOMORPH APEX ELDER'
XG_SP_NM[duck]='DUCKLING FLEDGLING YOUNG|DUCK DUCK MATURE SENIOR'
XG_SP_NM[frog]='TADPOLE FROGLET YOUNG|FROG FROG MATURE ELDER'
XG_SP_NM[snake]='HATCHLING NOODLET JUVENILE SNAKE MATURE ELDER'
XG_SP_NM[owl]='OWLET FLEDGLING YOUNG|OWL OWL MATURE ELDER'
XG_SP_NM[pig]='PIGLET WEANER GROWER PIG MATURE SENIOR'
XG_SP_NM[axolotl]='HATCHLING LARVA JUVENILE AXOLOTL MATURE ELDER'

# how fast it grows · the documentation is emphatic about the last two
typeset -gA XG_SP_LO
XG_SP_LO[glorp]='0.0 0.012 0.05 0.12 0.6 0.78'
XG_SP_LO[xeno]='0.0 0.0004 0.004 0.02 0.6 0.78'

# what shipment this one came on · the genetics deck decides, not the buyer
typeset -gA XG_SP_HAPPY XG_SP_NOMINAL XG_SP_BOX
XG_SP_HAPPY[cat]='purring'; XG_SP_NOMINAL[cat]='ALL WHISKERS NOMINAL'; XG_SP_BOX[cat]='the box'
XG_SP_HAPPY[dog]='wagging'; XG_SP_NOMINAL[dog]='ALL TAILS NOMINAL'; XG_SP_BOX[dog]='the patch'
XG_SP_HAPPY[rabbit]='binkying'; XG_SP_NOMINAL[rabbit]='ALL EARS NOMINAL'; XG_SP_BOX[rabbit]='the box'
XG_SP_HAPPY[hamster]='hoarding'; XG_SP_NOMINAL[hamster]='ALL POUCHES NOMINAL'; XG_SP_BOX[hamster]='the corner'
XG_SP_HAPPY[fox]='gekkering'; XG_SP_NOMINAL[fox]='ALL FLOOF NOMINAL'; XG_SP_BOX[fox]='the den corner'
XG_SP_HAPPY[turtle]='basking'; XG_SP_NOMINAL[turtle]='ALL PLATES NOMINAL'; XG_SP_BOX[turtle]='the substrate'
XG_SP_HAPPY[hedgehog]='snuffling'; XG_SP_NOMINAL[hedgehog]='ALL QUILLS NOMINAL'; XG_SP_BOX[hedgehog]='the corner box'
XG_SP_HAPPY[glorp]='wobbling'; XG_SP_NOMINAL[glorp]='ALL MEMBRANES NOMINAL'; XG_SP_BOX[glorp]='the tray'
XG_SP_HAPPY[xeno]='hissing, fondly'; XG_SP_NOMINAL[xeno]='ALL JAWS NOMINAL'; XG_SP_BOX[xeno]='the nest'
XG_SP_HAPPY[duck]='tail-wagging'; XG_SP_NOMINAL[duck]='ALL DOWN NOMINAL'; XG_SP_BOX[duck]='the corner'
XG_SP_HAPPY[frog]='croaking softly'; XG_SP_NOMINAL[frog]='ALL CROAKS NOMINAL'; XG_SP_BOX[frog]='the moss pad'
XG_SP_HAPPY[snake]='tongue-flicking'; XG_SP_NOMINAL[snake]='ALL COILS NOMINAL'; XG_SP_BOX[snake]='the warm hide'
XG_SP_HAPPY[owl]='hooting once'; XG_SP_NOMINAL[owl]='ALL SWIVELS NOMINAL'; XG_SP_BOX[owl]='the pellet corner'
XG_SP_HAPPY[pig]='oinking'; XG_SP_NOMINAL[pig]='ALL SNOUTS NOMINAL'; XG_SP_BOX[pig]='the wallow'
XG_SP_HAPPY[axolotl]='smiling, as always'; XG_SP_NOMINAL[axolotl]='ALL GILLS NOMINAL'; XG_SP_BOX[axolotl]='the pebble bed'

xg_sp_i() {   # xg_sp_i SPECIES → REPLY its index, 0 for anything unknown
  local -i i
  for (( i=0; i<${#XG_SPECIES[@]}; i++ )); do [[ "${XG_SPECIES[$i]}" == "$1" ]] && { REPLY=$i; return 0 } done
  REPLY=0
}
xg_species_of() {   # xg_species_of SEED → REPLY · what shipment this one came on
  xg_gh $1 41; REPLY=${XG_SPECIES[$(( XG_H%${#XG_SPECIES[@]} ))]}
}
xg_stage_nm() {   # xg_stage_nm IDX [SPECIES] → REPLY · KITTEN, or PUPPY
  local -a nm; nm=(${=XG_SP_NM[${2:-cat}]:-${XG_SP_NM[cat]}})
  REPLY="${nm[$1]//|/ }"
}

xg_lifespan() {   # xg_lifespan SEED [SPECIES] [BREED] [SPANDAYS] → REPLY days · ITS number
  # A SPAN WRITTEN DOWN IS THE SPAN, and nothing recomputes it.  How long an
  # animal has is decided once, the night it is dealt, and from then on it is
  # a fact about that animal in the same way its coat is: it rides in
  # terminal.save, so a save carried to another machine -- or opened by a
  # build whose breed tables have moved on -- gives back the same creature
  # with the same years ahead of it.  Only an animal with nothing written
  # asks the tables.
  local sw="${4:-}"
  [[ "$sw" == <->* && "$sw" != *[^0-9.]* ]] && { REPLY=$(( sw+0.0 )); return 0 }
  # A SPECIES NUMBER IS AN AVERAGE OF BREEDS, and this animal is one breed.
  # A Great Dane has eight years and a Chihuahua sixteen; asking the species
  # would give them both twelve, and the certificate would be lying to you.
  local sp="${2:-}"; local -F yrs
  [[ -n "$sp" ]] || { xg_species_of $1; sp="$REPLY" }
  if [[ -n "${XG_DK_BREED[$sp]:-}" ]]; then
    xg_span_years $1 "$sp" "${3:-}"; yrs=$REPLY
  else
    xg_sp_i "$sp"; yrs=${XG_SP_YEARS[$REPLY]}
  fi
  xg_gf $1 61; REPLY=$(( yrs*365.0*(0.85+0.30*XG_F) ))
}
xg_deal_age() {   # xg_deal_age SEED [SPECIES] [SPANDAYS] → REPLY days · how old it already is
  local -F L r f
  xg_lifespan $1 "${2:-}" '' "${3:-}"; L=$REPLY
  xg_gf $1 66; r=$XG_F
  xg_gf $1 67
  if (( r < 0.45 )); then f=$(( XG_F*0.08 ))
  elif (( r < 0.75 )); then f=$(( 0.08+XG_F*0.17 ))
  else f=$(( 0.25+XG_F*0.55 )); fi
  REPLY=$(( L*f ))
}
xg_stage_of() {   # xg_stage_of DAYS SEED [SPECIES] [SPANDAYS] → REPLY stage 0..5
  local -F d=$1 L f; local -i i; local sp="${3:-}"; local -a lo
  xg_lifespan $2 "$sp" '' "${4:-}"; L=$REPLY; (( L < 1.0 )) && L=1.0
  f=$(( d/L ))
  # MOST THINGS GROW at the same pace against their own span.  Two do not:
  # the organism is an adult in a fortnight, and a glorp is a glorp sooner
  # than a cat is a cat.  Those two carry their own ladder.
  [[ -n "$sp" ]] || { xg_species_of $2; sp="$REPLY" }
  if [[ -n "${XG_SP_LO[$sp]:-}" ]]; then lo=(${=XG_SP_LO[$sp]}); else lo=("${XG_STAGE_LO[@]}"); fi
  for (( i=5; i>0; i-- )); do (( f >= lo[i] )) && break; done
  REPLY=$i
}
xg_age_str() {   # xg_age_str DAYS → REPLY · 9d · 6wk · 4mo · 3y
  local -F d=$1
  (( d < 0.0 )) && d=0.0
  if   (( d < 14.0 ));  then REPLY="$(( int(d) ))d"
  elif (( d < 75.0 ));  then REPLY="$(( int(d/7.0) ))wk"
  elif (( d < 720.0 )); then REPLY="$(( int(d/30.4) ))mo"
  else REPLY="$(( int(d/365.0+0.5) ))y"; fi
}
xg_age_days() {   # the animal in the room · its age today, in days → REPLY
  local -F born=${XG[born]:-0} now=${EPOCHSECONDS:-0}
  if (( born <= 0.0 )); then REPLY=0.0
  else REPLY=$(( (now-born)/86400.0 )); (( REPLY < 0.0 )) && REPLY=0.0; fi
}
xg_age_sync() {   # its stage, its size and its outlook, read from its age today
  local -F d L; local -i s; local sp="${XG[species]:-cat}" sw="${XG[span]:-}"
  xg_age_days; d=$REPLY
  xg_lifespan ${XG[seed]:-61653} "$sp" "${XG[breed]:-}" "$sw"; L=$REPLY
  xg_stage_of $d ${XG[seed]:-61653} "$sp" "$sw"; s=$REPLY
  xg_stage_nm $s "$sp"; XG[stage]="$REPLY"; XG[stage_i]=$s
  # HOW BIG IT IS TODAY · kept on the animal so no render has to work it out,
  # and quantised so a day's growth does not thrash the pose shelf.
  (( L < 1.0 )) && L=1.0
  xg_grow "$sp" $(( d/L )) $s "${XG[breed]:-}"
  XG[grow]=$(( int(REPLY*1000.0+0.5)/1000.0 ))
  xg_age_str $(( L-d )); XG[left]="~$REPLY ahead, with care"
}

# the kitten · the original's kitten_sit, 24x21
xg_cat_kitten() {   # xg_cat_kitten [EYES] [PUPIL]
  local eyes="${1:-open}" pupil="${2:-round}"
  xg_px_new 24 21
  local -F hx=11.5 hy=7.2 tn=${XG[tail_n]:-1.0} es=${XG[ear_s]:-0.82}
  local -i yy
  xg_seg $(( hx+4.5 )) $(( hy+9.3 )) $(( hx+4.5+3.0*tn )) $(( hy+10.8 )) 1.3 1
  xg_seg $(( hx+4.5+3.0*tn )) $(( hy+10.8 )) $(( hx+4.5+4.5*tn )) $(( hy+8.8 )) 1.3 1
  xg_disk $(( hx+4.7+4.5*tn )) $(( hy+8.4 )) 1.2 1.4 2
  xg_disk $hx $(( hy+9.0 )) 6.0 4.0 1
  xg_disk $hx $(( hy+6.3 )) 4.9 4.6 1
  xg_disk $hx $hy 5.6 4.8 1
  xg_disk $hx $(( hy+1.6 )) 6.1 3.2 1
  xg_ears $hx $hy $es up
  for (( yy=int(hy+7.8); yy<int(hy+12); yy++ )); do xg_set $(( int(hx) )) $yy 2; done
  xg_disk $(( hx-2.6 )) $(( hy+12.2 )) 2.0 1.1 3
  xg_disk $(( hx+2.5 )) $(( hy+12.2 )) 2.0 1.1 3
  xg_coat_dress $hx $hy
  xg_face $hx $hy "$eyes" "$pupil" 1 0.88
  xg_whiskers $hx $hy 0.72
}

xg_px_scale() {   # xg_px_scale F — grow or shrink the material grid · shrinking lets the eyes win their cell
  xg_px_scale_xy $1 $1
}
xg_px_scale_xy() {   # xg_px_scale_xy FX FY — the same, one axis at a time
  # A BODY BROADENS BEFORE IT LENGTHENS.  Growing wider without growing taller
  # is how a grown animal is told from a full-grown one without drawing it
  # twice, so the two axes are separate even though almost every call passes
  # the same number for both.
  local -F fx=$1 fy=$2 f=$(( ($1+$2)/2.0 ))
  (( fx > 0.99 && fx < 1.01 && fy > 0.99 && fy < 1.01 )) && return 0
  local -i w=$XG_XPW h=$XG_XPH w2 h2 x y tx ty sy m cur pm pc
  w2=$(( int(w*fx+0.5) )); (( w2 < 4 )) && w2=4
  h2=$(( int(h*fy+0.5) )); (( h2 < 4 )) && h2=4
  local -a src; src=("${XG_XPM[@]}")
  xg_px_new $w2 $h2
  if (( w2 >= w && h2 >= h )); then
    for (( ty=0; ty<h2; ty++ )); do
      sy=$(( ty*h/h2 )); (( sy > h-1 )) && sy=$(( h-1 ))
      for (( tx=0; tx<w2; tx++ )); do
        x=$(( tx*w/w2 )); (( x > w-1 )) && x=$(( w-1 ))
        XG_XPM[$(( ty*w2+tx ))]=${src[$(( sy*w+x ))]}
      done
    done
  else
    for (( y=0; y<h; y++ )); do
      ty=$(( y*h2/h )); (( ty > h2-1 )) && ty=$(( h2-1 ))
      for (( x=0; x<w; x++ )); do
        m=${src[$(( y*w+x ))]}; (( m == 0 )) && continue
        tx=$(( x*w2/w )); (( tx > w2-1 )) && tx=$(( w2-1 ))
        cur=${XG_XPM[$(( ty*w2+tx ))]}
        if (( cur == 0 )); then XG_XPM[$(( ty*w2+tx ))]=$m
        else
          xg_facepri $m; pm=$REPLY; xg_facepri $cur; pc=$REPLY
          (( pm >= pc )) && XG_XPM[$(( ty*w2+tx ))]=$m
        fi
      done
    done
  fi
}
xg_crop_cells() {   # trim the empty margins off the rendered cells · the original's crop(pad=0)
  local -i x y x0=9999 x1=-1 y0=9999 y1=-1 w=$XG_CCW h=$XG_CCH ci
  for (( y=0; y<h; y++ )); do for (( x=0; x<w; x++ )); do
    (( XG_CC[y*w+x] >= 0 )) || continue
    (( x < x0 )) && x0=$x; (( x > x1 )) && x1=$x; (( y < y0 )) && y0=$y; (( y > y1 )) && y1=$y
  done; done
  (( x1 < 0 )) && return 0
  local -a cc ca; cc=(); ca=()
  for (( y=y0; y<=y1; y++ )); do for (( x=x0; x<=x1; x++ )); do
    ci=$(( y*w+x )); cc+=(${XG_CC[$ci]}); ca+=(${XG_CA[$ci]})
  done; done
  XG_CC=("${cc[@]}"); XG_CA=("${ca[@]}"); XG_CCW=$(( x1-x0+1 )); XG_CCH=$(( y1-y0+1 ))
}

# an arrival at its actual age, stall-sized · the original's stall_px, cached
typeset -gA XG_SS_C XG_SS_A XG_SS_W XG_SS_H
# THE PORTRAIT'S SIZE, for a caller that wants it bigger than the alcove's:
# a multiple of the alcove's shrink and a tallest it may be, in pixels.  The
# defaults are the alcove's own, and only a caller that changes them -- the
# door's title card, on a tall glass -- gets a different picture (its own
# entry on the shelf); it puts them back when it has its portrait.
typeset -gF XG_SS_K=1.0; typeset -gi XG_SS_CAP=22
xg_stall_sprite() {   # xg_stall_sprite SEED DAYS [SPECIES] [EYES] [PAL] [SPANDAYS] [BREED] → cells in XG_CC · REPLY stage
  local -i seed=$1 s; local -F d=$2; local sp="${3:-}" eyes="${4:-open}" pal="${5:-}" sw="${6:-}" br="${7:-}"
  [[ -n "$sp" ]] || { xg_species_of $seed; sp="$REPLY" }
  # THE PICTURE AND THE WORDS AGREE.  The card says KITTEN off the animal's
  # written span; if the portrait asked the tables instead it could draw a
  # cat while the line beside it read kitten.
  xg_stage_of $d $seed "$sp" "$sw"; s=$REPLY
  # AND IT IS THE RIGHT SIZE FOR ITS AGE · the same curve the room uses, times
  # the portrait's own shrink, so a kitten in the roster is a small kitten and
  # a Great Dane fills its card.
  local -F L gr
  xg_lifespan $seed "$sp" "$br" "$sw"; L=$REPLY; (( L < 1.0 )) && L=1.0
  xg_grow "$sp" $(( d/L )) $s "$br"; gr=$(( int(REPLY*1000.0+0.5)/1000.0 ))
  # THE PORTRAIT WEARS WHAT THE PAPERS SAY · the key carries the colours too,
  # so two animals of one seed in different coats do not share a cache entry.
  local key="$sp.$seed.$s.$eyes.${pal:0:13}.$gr" k
  (( XG_SS_CAP != 22 )) && key+=".big$XG_SS_CAP"
  if [[ -z "${XG_SS_C[$key]:-}" ]]; then
    local -A keep                                    # the resident's paperwork, kept safe
    for k in pattern pj eyes ears tail ear_s tail_n build temper tname hunger_m social_m colorway label pal; do keep[$k]="${XG[$k]:-}"; done
    xg_wear $seed "$sp" "$pal"
    local -a P; P=(${=XG_POSES[$sp]:-${XG_POSES[cat]}})
    local -F psc=$(( gr*0.72*XG_SS_K ))              # the alcove's own shrink (a caller may ask it bigger)
    if [[ "${XG_STAGE_FORM[$s]}" == baby ]]; then
      if [[ "$sp" == cat ]]; then xg_cat_kitten "$eyes" round; else ${P[1]} "$eyes"; fi
      psc=$(( psc * ${XG_SP_AH[$sp]:-24} * 1.0 / ${XG_SP_BH[$sp]:-16} ))
    else
      ${P[0]} "$eyes"
    fi
    local -F pwf=1.0; (( s == 4 )) && pwf=1.07; (( s == 5 )) && pwf=0.95
    xg_px_scale_xy $(( psc*pwf )) $psc
    (( XG_XPH > XG_SS_CAP )) && xg_px_scale $(( XG_SS_CAP*1.0/XG_XPH ))
    XG_SENIOR=$(( s == 5 )); xg_render_cells; XG_SENIOR=0
    xg_crop_cells
    XG_SS_C[$key]="${XG_CC[*]}"; XG_SS_A[$key]="${XG_CA[*]}"; XG_SS_W[$key]=$XG_CCW; XG_SS_H[$key]=$XG_CCH
    for k in ${(k)keep[@]}; do XG[$k]="${keep[$k]}"; done
    XG_PAL_KEY=''                                    # the resident's palette re-deals on its next render
  else
    XG_CC=(${(s: :)XG_SS_C[$key]}); XG_CA=(${(s: :)XG_SS_A[$key]})
    XG_CCW=${XG_SS_W[$key]}; XG_CCH=${XG_SS_H[$key]}
  fi
  XG_CACHE_KEY=''
  REPLY=$s
}

# the original's soft shadow row under a cell sprite (blit_cells shadow=True)
xg_cell_shadow() {   # xg_cell_shadow CX CY STRENGTH — reads XG_CC/XG_CCW/XG_CCH
  local -i cx=$1 cy=$2 x y ground=-1 x0=9999 x1=-1 X Y k base sc under
  local -F st=$3 cxm half d
  local -a low; low=()
  for (( x=0; x<XG_CCW; x++ )); do
    low[$x]=-1
    for (( y=XG_CCH-1; y>=0; y-- )); do (( XG_CC[y*XG_CCW+x] >= 0 )) && { low[$x]=$y; break; }; done
    (( low[x] > ground )) && ground=${low[$x]}
  done
  (( ground < 0 )) && return 0
  for (( x=0; x<XG_CCW; x++ )); do (( low[x] >= ground-1 )) && { (( x < x0 )) && x0=$x; (( x > x1 )) && x1=$x; }; done
  cxm=$(( (x0+x1)/2.0-1.0 )); half=$(( (x1-x0)/2.0+1.5 ))
  Y=$(( cy+ground+1 )); (( Y < 0 || Y >= SCR_H )) && return 0
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  _pack 3 1 8; sc=$PK
  for (( x=int(cxm-half); x<=int(cxm+half)+1; x++ )); do
    d=$(( abs(x-cxm)/(half > 1.0 ? half : 1.0) )); (( d > 1.0 )) && continue
    X=$(( cx+x )); (( X < 0 || X >= SCR_W )) && continue
    k=$(( base+Y*TCOLS+X )); under=${GB[$k]:-$GLASS}; (( under < 0 )) && under=$GLASS
    cmix $under $sc $(( st*0.8*(1.0-d*d) )); v_put $X $Y ' ' $GREY $CM
  done
}

# ── HALF-CELL PIXELS · the original drew its icons and its light cones this
#    way (cv.pix): ▀ with the upper pixel as ink and the lower as ground.
xg_pix() {   # xg_pix X PY COLOUR — PY counts half-rows
  (( $1 < 0 || $1 >= SCR_W || $2 < 0 || $2 >= 2*SCR_H )) && return 0
  local -i k=$(( (OY+R_SCR+$2/2)*TCOLS+OX+C_SCR+$1 )) under
  if [[ "${GCH[$k]:- }" != '▀' ]]; then
    under=${GB[$k]:-$GLASS}; (( under < 0 )) && under=$GLASS
    GCH[$k]='▀'
    if (( $2 % 2 == 0 )); then GF[$k]=$3; GB[$k]=$under; else GF[$k]=$under; GB[$k]=$3; fi
  elif (( $2 % 2 == 0 )); then GF[$k]=$3
  else GB[$k]=$3; fi
}
xg_pixget() {   # xg_pixget X PY → REPLY the colour of that half-cell
  (( $1 < 0 || $1 >= SCR_W || $2 < 0 || $2 >= 2*SCR_H )) && { REPLY=$GLASS; return 1; }
  local -i k=$(( (OY+R_SCR+$2/2)*TCOLS+OX+C_SCR+$1 ))
  if [[ "${GCH[$k]:- }" == '▀' ]]; then
    if (( $2 % 2 == 0 )); then REPLY=${GF[$k]:-$GREY}; else REPLY=${GB[$k]:-$GLASS}; fi
  else REPLY=${GB[$k]:-$GLASS}; (( REPLY < 0 )) && REPLY=$GLASS; fi
  return 0
}
xg_rgb() { _pack $1 $2 $3; REPLY=$PK }            # xg_rgb R G B → REPLY packed

# ══════════════════════════════════════════════════════════════════════════
# THE HOUSE ECONOMY · the original's, whole: the pantry, the daily roll, the
# red dot, the gifts.  Credits are earned, never bought.
# ══════════════════════════════════════════════════════════════════════════
# The PANTRY holds meals ([F] spends one; the store and a new arrival's kibble
# bag fill it).  Once per local calendar day the ROLL pays a care streak (+10 c
# while every vital sits above 35), resets the treat and catch caps, counts the
# day, and may leave a GIFT from an animal that likes you ([A] admires it,
# +15 c).  [P] brings out the RED DOT: the arrows steer it, the animal gives
# chase, and a catch pays +2 c (three paid catches a day).
typeset -ga XG_GIFTS XG_GIFT_ADJ XG_GIFT_OBJ XG_GIFT_TAIL
XG_GIFTS=('a dead bug' 'a semicolon' 'one (1) sock' 'a mechanical keycap' 'a USB-A plug, the wrong way up' \
          'a shrew (regifted)' 'a bottle cap' 'a very good stick' "somebody's lanyard" 'an alien coin, denomination unknown')
XG_GIFT_ADJ=('a suspiciously warm' 'a lightly chewed' 'an heirloom' 'a decommissioned' 'a smuggled' 'a ceremonial' \
             'a gently haunted' 'a first-edition' 'an off-brand' 'a regulation' 'an artisanal' 'a backup')
XG_GIFT_OBJ=('bottle cap' 'twist tie' 'biro cap' 'receipt' 'cork' 'hair tie' 'wing nut' 'postage stamp' 'd20' \
             'zip tie' 'moth (emeritus)' 'keyring')
XG_GIFT_TAIL=('' '' '' '' ' (still beeping)' ' (do not ask)' ' (pre-loved)' ' (from space)' ' (yours now)' ' (slightly used)')

# the room's styles · the store's BED COVER, DISH SET and CORE TUNING walk these
typeset -ga XG_BED_NM XG_BED_PAL XG_DISH_NM XG_DISH_PAL XG_CORE_ST XG_CORE_NM
XG_BED_NM=('violet bolster' 'moss bolster' 'ember bolster' 'frost bolster')
XG_BED_PAL=('122 92 168  40 30 62  196 176 224  238 214 255' \
            '84 128 86  30 46 34  176 210 160  226 246 214' \
            '176 90 60  60 30 24  236 180 140  255 226 200' \
            '96 150 190  30 48 66  190 226 244  236 250 255')
XG_DISH_NM=('clay dish' 'jade dish' 'cobalt dish' 'rose dish')
XG_DISH_PAL=('148 120 96  56 38 30' '84 150 120  28 56 44' '70 100 180  24 34 70' '190 110 140  66 34 48')
XG_CORE_ST=(std ember synth glacier)
XG_CORE_NM=(teal ember synth glacier)

xg_pick() {   # xg_pick LINE... → REPLY, one of them · the original's way of never saying it twice
  local -a w; w=("$@"); REPLY="${w[$(( RANDOM % ${#w[@]} ))]}"
}
typeset -g XG_FLASH=''; typeset -gi XG_FLASH_C=0; typeset -gF XG_FLASH_T=0.0
xg_flash() { XG_FLASH="$1"; XG_FLASH_C=$2; XG_FLASH_T=$(( XG_NOW+2.5 )) }

# ── the gifts ──
xg_gift_pick() {   # → REPLY · a gift not yet admired, or one dealt forever once the pool runs dry
  local g album="|${XG[album]:-}|"; local -a pool; pool=()
  for g in "${XG_GIFTS[@]}"; do [[ "$album" == *"|$g|"* ]] || pool+=("$g"); done
  if (( ${#pool[@]} )); then REPLY="${pool[$(( RANDOM % ${#pool[@]} ))]}"; return 0; fi
  local -i n=$(( ${XG[c_gifts]:-0}+1 ))
  xg_gh $(( ${XG[seed]:-1}+n*131 )) 71
  REPLY="${XG_GIFT_ADJ[$(( XG_H % 12 ))]} ${XG_GIFT_OBJ[$(( (XG_H>>8) % 12 ))]}${XG_GIFT_TAIL[$(( (XG_H>>16) % 10 ))]}"
}
xg_act_admire() {   # [A] · the gift, admired properly
  if [[ -z "${XG[gift]:-}" ]]; then xg_log 'nothing waiting to be admired · yet' '' $GREY; snd no; return 0; fi
  local g="${XG[gift]}"; local -a al
  al=("${(@s:|:)${XG[album]:-}}"); al+=("$g")
  (( ${#al[@]} > 40 )) && al=("${(@)al[@]:$(( ${#al[@]}-40 ))}")
  XG[album]="${(j:|:)al[@]}"; XG[album]="${XG[album]#|}"
  XG[gift]=''; XG_RCK=''
  XG[credits]=$(( ${XG[credits]:-0}+15 )); XG[c_gifts]=$(( ${XG[c_gifts]:-0}+1 )); xg_vadd bond 4
  xg_pick "gift admired: $g" "$g · admired properly" "the album takes: $g"
  xg_log "$REPLY" '+15 c' $MAGENTA; snd pick
  xg_save_write
  return 0
}
xg_gift_bug() {   # xg_gift_bug X PY — what the animal left on the deck · the original's p_gift_bug
  local -i x=$1 y=$2 body legs lit dx dy
  xg_rgb 60 72 46; body=$REPLY; xg_rgb 40 48 32; legs=$REPLY; xg_rgb 150 170 120; lit=$REPLY
  for dx in 0 1; do for dy in 0 1; do xg_pix $(( x+dx )) $(( y+dy )) $body; done; done
  xg_pix $(( x-1 )) $y $legs; xg_pix $(( x+2 )) $(( y+1 )) $legs; xg_pix $(( x+1 )) $(( y-1 )) $lit
}

# ── the daily roll ──
xg_day_key() {   # xg_day_key [TS] → REPLY YYYY-MM-DD, local
  strftime -s REPLY '%Y-%m-%d' ${1:-${EPOCHSECONDS:-0}} 2>/dev/null || REPLY=''
}
xg_day_roll() {   # once per local calendar day: the streak and its pay, the caps, a gift, a hairball
  local -i ok=1; local k
  for k in food water mood coat health; do (( ${XG[$k]:-0} > 35 )) || ok=0; done
  if (( ok )); then
    XG[streak]=$(( ${XG[streak]:-0}+1 )); XG[credits]=$(( ${XG[credits]:-0}+10 ))
    xg_pick "care streak day ${XG[streak]}" "day ${XG[streak]} of good care" \
            "the streak holds · day ${XG[streak]}" "${XG[streak]} days of competence"
    xg_log "$REPLY" '+10 c' $LIME
  else
    XG[streak]=0; xg_vadd bond -3
  fi
  XG[catches_today]=0; XG[treats_today]=0
  XG[day]=$(( ${XG[day]:-1}+1 ))
  if (( ${XG[bond]:-0} >= 50 )) && [[ -z "${XG[gift]:-}" ]] && (( RANDOM < 14746 )); then     # 45%
    xg_gift_pick; XG[gift]="$REPLY"; XG_RCK=''
    xg_pick 'something was left for you' 'you have been gifted · see [A]' 'an offering awaits inspection'
    xg_log "$REPLY" '[A]' $MAGENTA
  fi
  if (( ${XG[coat]:-100} < 55 && RANDOM < 9830 )); then                                       # 30%
    xg_vadd coat -6
    xg_pick 'a hairball happened' 'a hairball.  no witnesses' 'hairball, delivered with pride'
    xg_log "$REPLY" 'COAT −6' $AMBER
  fi
  xg_age_sync
}
xg_day_catchup() {   # every calendar day since the last one counted, rolled · the save remembers which
  local today last; local -i t0 t1 n i
  xg_day_key; today="$REPLY"; [[ -n "$today" ]] || return 0
  last="${XG[last_day]:-}"
  if [[ -z "$last" ]]; then XG[last_day]="$today"; return 0; fi
  [[ "$last" == "$today" ]] && return 0
  strftime -r -s t0 '%Y-%m-%d' "$last" 2>/dev/null || { XG[last_day]="$today"; return 0; }
  strftime -r -s t1 '%Y-%m-%d' "$today" 2>/dev/null || return 0
  n=$(( (t1-t0+43200)/86400 ))
  XG[last_day]="$today"
  (( n < 1 )) && return 0                     # a clock that stepped back · nothing is owed twice
  (( n > 45 )) && n=45
  for (( i=0; i<n; i++ )); do xg_day_roll; done
  return 0
}

# ── the red dot ──
typeset -gA XG_LZ; XG_LZ=(on 0)
xg_lz_start() {   # [P] · the red dot appears · the arrows steer it, the animal gives chase
  (( ${XG_LZ[on]:-0} )) && return 0
  local -F dur=20.0 cx ww=$(( XG_WW > 60 ? XG_WW : 199 )) span=$(( XG_SPAN_W > 20.0 ? XG_SPAN_W : 159.0 ))
  xg_owned yarn && dur=30.0
  cx=$(( 20.0+${XG_A[fx]:-0.5}*span+18.0 ))
  (( cx > ww-8.0 )) && cx=$(( cx-36.0 ))
  XG_LZ=(on 1 x $cx dy 1 until $(( XG_NOW+dur )) catches 0 pounce 0.0)
  xg_pick 'the red dot appears' 'a red dot manifests' 'the dot is back.  it knows' 'red dot: deployed'
  xg_log "$REPLY" '' $CYAN; snd pick
  return 0
}
xg_lz_tick() {   # the session: the chase, the pounce, the catch, and the end of it
  (( ${XG_LZ[on]:-0} )) || return 0
  local -F now=$XG_NOW span=$(( XG_SPAN_W > 20.0 ? XG_SPAN_W : 92.0 )) catc dx odds nx ww=$(( XG_WW > 60 ? XG_WW : 199 ))
  local -i c gain
  if (( now >= XG_LZ[until] )); then
    c=${XG_LZ[catches]}; gain=$(( 3+2*c ))
    xg_vadd mood $gain; xg_vadd pep -8
    local s='es'; (( c == 1 )) && s=''
    xg_pick "play: $c catch$s" "red dot session: $c catch$s" "the dot logged $c catch$s"
    xg_log "$REPLY" "MOOD +$gain" $CYAN
    XG_LZ=(on 0); XG_A[b_until]=0.0; XG_A[behavior]=idle
    return 0
  fi
  # the chase · the animal's whole attention, at a dash
  XG_A[behavior]=chase; XG_A[target]=$(( (XG_LZ[x]-20.0)/span )); XG_A[speed]=11.0
  XG_A[b_until]=${XG_LZ[until]}; XG_A[moving]=1
  (( XG_A[target] < 0.0 )) && XG_A[target]=0.0; (( XG_A[target] > 1.0 )) && XG_A[target]=1.0
  catc=$(( 20.0+XG_A[fx]*span ))
  dx=$(( catc-XG_LZ[x] )); (( dx < 0.0 )) && dx=$(( -dx ))
  if (( dx < 7.0 && now-XG_LZ[pounce] > 1.2 )); then
    XG_LZ[pounce]=$now
    odds=0.35; xg_owned pointer && odds=0.55
    if (( RANDOM/32768.0 < odds )); then
      XG_LZ[catches]=$(( XG_LZ[catches]+1 )); XG[c_catches]=$(( ${XG[c_catches]:-0}+1 ))
      if (( ${XG[catches_today]:-0} < 3 )); then
        XG[catches_today]=$(( ${XG[catches_today]:-0}+1 )); XG[credits]=$(( ${XG[credits]:-0}+2 )); snd pick
      fi
      nx=$(( XG_LZ[x] + (RANDOM % 2 ? 18.0 : -18.0) ))           # away it goes
      (( nx < 6.0 )) && nx=$(( nx+36.0 )); (( nx > ww-6.0 )) && nx=$(( nx-36.0 ))
      XG_LZ[x]=$nx
    fi
  fi
}
xg_lz_key() {   # the arrows steer the dot while it is out → 0 handled
  (( ${XG_LZ[on]:-0} )) || return 1
  local -F ww=$(( XG_WW > 60 ? XG_WW : 199 ))
  case "$1" in
    left)  XG_LZ[x]=$(( XG_LZ[x]-3.0 )); (( XG_LZ[x] < 4.0 )) && XG_LZ[x]=4.0 ;;
    right) XG_LZ[x]=$(( XG_LZ[x]+3.0 )); (( XG_LZ[x] > ww-5.0 )) && XG_LZ[x]=$(( ww-5.0 )) ;;
    up)    (( XG_LZ[dy] > -6 )) && XG_LZ[dy]=$(( XG_LZ[dy]-1 )) ;;
    down)  (( XG_LZ[dy] < 3 )) && XG_LZ[dy]=$(( XG_LZ[dy]+1 )) ;;
    *)     return 1 ;;
  esac
  return 0
}
xg_lz_draw() {   # xg_lz_draw FY — the dot itself · the original's p_red_dot, a small glow
  (( ${XG_LZ[on]:-0} )) || return 0
  local -i x=$(( int(XG_LZ[x])-XG_CAM )) py=$(( 2*($1+XG_LZ[dy])+1 )) dx dy red core
  local -F d
  xg_rgb 255 60 70; red=$REPLY
  if xg_owned pointer; then xg_rgb 255 232 232; else xg_rgb 255 190 190; fi; core=$REPLY
  for (( dy=-2; dy<=2; dy++ )); do for (( dx=-2; dx<=2; dx++ )); do
    d=$(( sqrt(dx*dx+dy*dy) )); (( d > 2.3 )) && continue
    xg_pixget $(( x+dx )) $(( py+dy )) || continue
    cmix $REPLY $red $(( (1.0-d/2.3)*0.9 )); xg_pix $(( x+dx )) $(( py+dy )) $CM
  done; done
  xg_pix $x $py $core
}

# ── [D] · each slot with more than one style, on to the next ──
xg_core_owned() {   # → REPLY the core styles this house has, in order
  local s; local -a have; have=(std)
  for s in "${XG_CORE_ST[@]:1}"; do xg_owned "$s" && have+=("$s"); done
  REPLY="${have[*]}"
}
xg_act_decor() {
  local -a ch have; ch=(); local -i n i cur
  n=${XG_HOUSE[nbed]:-1}
  (( n > 1 )) && { XG_HOUSE[bed]=$(( (${XG_HOUSE[bed]:-0}+1) % n )); ch+=("${XG_BED_NM[${XG_HOUSE[bed]}]}"); }
  n=${XG_HOUSE[nbowl]:-1}
  (( n > 1 )) && { XG_HOUSE[bowl]=$(( (${XG_HOUSE[bowl]:-0}+1) % n )); ch+=("${XG_DISH_NM[${XG_HOUSE[bowl]}]}"); }
  xg_core_owned; have=(${=REPLY})
  if (( ${#have[@]} > 1 )); then
    cur=0; for (( i=0; i<${#have[@]}; i++ )); do [[ "${have[$i]}" == "${XG_HOUSE[style]:-std}" ]] && cur=$i; done
    cur=$(( (cur+1) % ${#have[@]} )); XG_HOUSE[style]="${have[$cur]}"; [[ "${XG_HOUSE[style]}" == std ]] && XG_HOUSE[style]=''
    XG_CORE_PAL=0
    for (( i=0; i<${#XG_CORE_ST[@]}; i++ )); do [[ "${XG_CORE_ST[$i]}" == "${have[$cur]}" ]] && ch+=("core · ${XG_CORE_NM[$i]}"); done
  fi
  if (( ${#ch[@]} )); then
    local s="${(j:, :)ch[@]}"; s="${s[0,21]}"
    XG_RCK=''
    xg_pick "rearranged: $s" "new look: $s" "the room cycles: $s"; xg_log "$REPLY" '' $GREY; snd pick
    xg_save_write
  else
    xg_pick 'one style per slot, so far' 'nothing to cycle yet · see [O]' 'one of each.  the store knows'
    xg_log "$REPLY" '' $GREY; snd no
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE ORIGINAL'S PAGE FRAME · 106 x 30, the size the old cabinet's glass was
# ══════════════════════════════════════════════════════════════════════════
# The store and the adoption centre are laid out cell for cell as the old
# machine laid them out, on its 106 x 30 screen — which is exactly the float
# glass.  On a bigger glass the frame is centred; the header and the key row
# stay the cabinet's own, top and bottom.
typeset -gi XO=0 YO=0
typeset -gi XG_AMBI=0
xg_frame() {
  XO=$(( (SCR_W-106)/2 )); (( XO < 0 )) && XO=0
  YO=$(( (SCR_H-30)/2 ));  (( YO < 0 )) && YO=0
  (( XG_AMBI )) || { _pack 96 60 150; XG_AMBI=$PK; }
}
xg_ft()      { v_text $(( XO+$1 )) $(( YO+$2 )) "$3" ${4:--2} ${5:--2} }            # text at frame coords
xg_fput()    { v_put  $(( XO+$1 )) $(( YO+$2 )) "$3" ${4:--2} ${5:--2} }
xg_fright()  { local s="$3"; v_text $(( XO+$1-${#s}+1 )) $(( YO+$2 )) "$s" ${4:--2} ${5:--2} }   # ends AT x
xg_fcenter() { local s="$2"; local -i x0=${4:-0} w=${5:-106}; v_text $(( XO+x0+(w-${#s})/2 )) $(( YO+$1 )) "$s" ${3:--2} ${6:--2} }
xg_fpanel()  {   # xg_fpanel X Y W H TITLE [TC] — the original's panel()
  v_box $(( XO+$1 )) $(( YO+$2 )) $3 $4 $DIM $GLASS round
  v_text $(( XO+$1+2 )) $(( YO+$2 )) " $5 " ${6:-$AMBER} $GLASS
}
xg_fsegs()   {   # xg_fsegs X Y [BG] -- TEXT COL ... — the original's seg_text → REPLY end x
  local -i x=$1 y=$2 bg=-2; shift 2
  [[ "${1:-}" != '--' ]] && { bg=$1; shift; }
  shift
  while (( $# >= 2 )); do v_text $(( XO+x )) $(( YO+y )) "$1" $2 $bg; x=$(( x+${#1} )); shift 2; done
  REPLY=$x
}
xg_seglen()  { local -i n=0; while (( $# >= 2 )); do n=$(( n+${#1} )); shift 2; done; REPLY=$n }
xg_an() {   # xg_an WORD → REPLY · 'a' or 'an', whichever the word wants
  # DELIBERATE, AND NOT IN THE ORIGINAL.  The Python hardcodes "a %s streak",
  # so an anxious dog had "a anxious streak" and the xenomorph's certificate
  # read "a apex streak".  Nine of the temperaments across the intake start
  # with a vowel and every one of them printed wrong.
  # KSH_ARRAYS IS ON, so a string subscript is 0-based and ${1[0,1]} is the
  # first TWO characters.  The one character wanted here is ${1[0]}.
  case "${1[0]}" in ([aeiouAEIOU]) REPLY=an ;; (*) REPLY=a ;; esac
}
xg_m2() {   # xg_m2 FLOAT → REPLY · hundredths, written the way a save should read
  # A MODIFIER IS TWO DECIMALS AND IT IS WRITTEN AS TWO.  Left to $(( )),
  # zsh renders 0.95 as 0.94999999999999996 and 1.0 as "1." -- and both of
  # those went straight into terminal.save, which is a file meant to be read,
  # carried to another machine and trusted.  The value is the same double
  # either way; only the spelling was wrong.
  #
  # LC_ALL=C, AND IT HAS TO BE LC_ALL.  printf honours LC_NUMERIC while zsh
  # arithmetic does not, so under a German or French locale this wrote
  # `0,95` into terminal.save and the next read parsed the comma as zsh's
  # COMMA OPERATOR -- `$(( 1713284092,87 ))` is 87.  A born date became 87,
  # a span became 0, and a young cat reopened as a senior with no time left.
  # Neither `local LC_NUMERIC=C` nor an exported one reaches the builtin;
  # only a command prefix does, and only LC_ALL takes.
  REPLY="$(LC_ALL=C printf '%.2f' $1)"
}
xg_ell()     { local s="$1"; local -i n=$2; if (( ${#s} <= n )); then REPLY="$s"; else REPLY="${s[0,$(( n-2 ))]}…"; fi }

# ══════════════════════════════════════════════════════════════════════════
# THE STORE · THE CATALOGUE · a list you read down, and a sheet that reads back
# ══════════════════════════════════════════════════════════════════════════
# Down the left, the shelf as a catalogue: three departments -- the GALLEY,
# the TOY CHEST, THE ROOM -- each in the colour of the meter it feeds, each
# thing with what it does and what the house has of it, and a RED DOT against
# anything the animal needs tonight.  ▴ ▾ walk it the way it reads, top to
# bottom, and ⏎ buys.  Down the right, the SPEC SHEET reads whatever the
# cursor is standing on: the thing at twice the size on a lit plinth, its
# words, what it will do to THIS animal (her own vitals as bars, before and
# after), what the house already has, and the till's own sum -- what is left
# after, or how many good days of care you are short.
#
# THE PAGE IS MEASURED OFF THE GLASS, not off a fixed frame: a filled screen
# gets a longer catalogue (three lines to a thing, then four) and a wider
# sheet, and the till stays pinned to the foot of it.
#
# NOTHING LONG IS DRAWN WITH HALF BLOCKS.  A terminal whose ▀ is a shade
# narrower than its cell turns a long run of them into a dashed line, so
# every rule, bar and plinth here is a cell's GROUND; ▀ is left to the
# pixel art, where the seams read as pixels anyway.
#
# The page is a still picture between keypresses, so it is painted ONCE into
# a cache (the room's own trick) and every other frame is an array restore
# plus the clock.  The ported page repainted nine lit icons every frame at
# ~70 ms; this one sits at ~9 ms and pays ~24 ms on a key.
typeset -gi XG_OROW=0
typeset -ga XG_ST_ID XG_ST_NAME XG_ST_COST XG_ST_DEPT XG_ST_IH XG_ST_FX XG_ST_DESC
typeset -ga XG_DEPT_NM XG_DEPT_TAG
XG_ST_ID=(pods tuna feast yarn orb pointer cover dish tuning)
XG_ST_NAME=('KIBBLE PODS' 'SPACE TUNA' 'NEBULA FEAST' 'YARN BALL' 'HOVER ORB' 'PHOTON POINTER' 'BED COVER' 'DISH SET' 'CORE TUNING')
XG_ST_COST=(10 25 60 30 60 80 120 50 80)
XG_ST_DEPT=(0 0 0 1 1 1 2 2 2)
XG_ST_IH=(7 7 7 8 8 7 6 6 8)            # each icon's height in half-rows
XG_ST_FX=('six meals for the pantry' 'FOOD +40 · MOOD +5' 'FOOD +60 · MOOD +15' 'the red dot runs longer' \
          'solo play while you are away' 'a sharper dot, easier caught' 'the next bolster · deeper naps' \
          'the next colourway' 'the core burns a new colour')
XG_ST_DESC=(
  'six sealed meals for the pantry.  [F] opens one at the dish.  she has views on the brand; none of them are binding.'
  'a tin from the galley, pull-top.  it is gone before the lid has stopped spinning.'
  'a plated dinner under a cloche.  regarded, at some length.  then gone.'
  'the classic.  it waits at the play spot, and every red dot session runs half again as long.'
  'a lit sphere that rides its own glow.  it keeps her company while you are away, so her mood holds.'
  'a photon pen.  a sharper dot is an easier catch, and a catch pays.'
  'a new bolster for the bed, in the next colourway.  the first new one makes naps restore more.'
  'the dish, re-glazed in the next colourway.  the same kibble, in a better light.'
  'the core column, retuned to burn a new colour.  the whole room takes the light.'
)
XG_DEPT_NM=('GALLEY' 'TOY CHEST' 'THE ROOM')
XG_DEPT_TAG=('eaten once' 'kept for good' 'the room, re-dressed')
xg_dept_col() {   # xg_dept_col D → REPLY · a department burns the colour of the meter it feeds
  case $1 in
    0) REPLY=$AMBER ;;                        # the galley · FOOD
    1) cmix $MAGENTA $PURPLE 0.55; REPLY=$CM ;;  # the toy chest · MOOD
    *) cmix $LIME $CYAN 0.55; REPLY=$CM ;;       # the room · the core
  esac
}
xg_owned() { [[ ",${XG_HOUSE[own]:-}," == *",$1,"* ]] }
xg_own()   { xg_owned "$1" || XG_HOUSE[own]="${XG_HOUSE[own]:+${XG_HOUSE[own]},}$1" }
xg_core_next() {   # → REPLY the next core style this house does not have yet, or ''
  local s; REPLY=''
  for s in "${XG_CORE_ST[@]:1}"; do xg_owned "$s" || { REPLY="$s"; return 0; }; done
}
xg_core_name() {   # a core style key → REPLY the word for it
  local -i j; REPLY="$1"
  for (( j=0; j<${#XG_CORE_ST[@]}; j++ )); do [[ "${XG_CORE_ST[$j]}" == "$1" ]] && REPLY="${XG_CORE_NM[$j]}"; done
}

# ── what the house already has of a thing, and what she wants tonight ──
xg_store_have() {   # xg_store_have IDX → REPLY the words · REPLY2 ok | own | max
  local id="${XG_ST_ID[$1]}"; local -i n
  REPLY2=ok
  case "$id" in
    pods)  REPLY="pantry ${XG_HOUSE[pantry]:-0}" ;;
    tuna|feast) REPLY='eaten on the spot' ;;
    yarn|orb|pointer) if xg_owned "$id"; then REPLY='owned'; REPLY2=own; else REPLY='in stock'; fi ;;
    cover) n=${XG_HOUSE[nbed]:-1};  REPLY="$n of ${#XG_BED_NM[@]} styles";  (( n >= ${#XG_BED_NM[@]} )) && REPLY2=max ;;
    dish)  n=${XG_HOUSE[nbowl]:-1}; REPLY="$n of ${#XG_DISH_NM[@]} styles"; (( n >= ${#XG_DISH_NM[@]} )) && REPLY2=max ;;
    tuning) xg_core_owned; local -a hv; hv=(${=REPLY}); n=${#hv[@]}
            REPLY="$n of ${#XG_CORE_ST[@]} styles"; (( n >= ${#XG_CORE_ST[@]} )) && REPLY2=max ;;
  esac
  return 0
}
xg_store_want() {   # xg_store_want IDX → REPLY why she needs it now, or '' · the red dot on the lip
  local nm="${XG[name]:-she}"; REPLY=''
  case "${XG_ST_ID[$1]}" in
    pods|tuna|feast)  (( ${XG[food]:-100} < 50 )) && REPLY="$nm is hungry" ;;
    yarn|orb|pointer) xg_owned "${XG_ST_ID[$1]}" || { (( ${XG[mood]:-100} < 50 )) && REPLY="$nm is bored"; } ;;
    cover)            (( ${XG[pep]:-100} < 40 )) && REPLY="$nm is tired" ;;
  esac
  return 0
}

# ── the till's arithmetic · what the balance will be, or what it is short ──
typeset -gi XG_BAL=0 XG_PRICE=0 XG_LEFT=0 XG_CAN=0
xg_store_till() {   # xg_store_till IDX → XG_BAL XG_PRICE XG_LEFT · XG_CAN 1 can · 0 short · 2 has it all
  XG_BAL=${XG[credits]:-0}; XG_PRICE=${XG_ST_COST[$1]}; XG_LEFT=$(( XG_BAL-XG_PRICE ))
  xg_store_have $1
  if [[ "$REPLY2" != ok ]]; then XG_CAN=2
  elif (( XG_LEFT >= 0 )); then XG_CAN=1
  else XG_CAN=0; fi
  return 0
}
xg_store_buy() {   # xg_store_buy IDX — the original's act_buy, with this ship's shelf
  local -i i=$1 cost=${XG_ST_COST[$1]} n
  local id="${XG_ST_ID[$i]}" nm="${XG_ST_NAME[$i]:l}" msg=''
  case "$id" in
    yarn|orb|pointer) xg_owned "$id" && { xg_flash 'already owned · it is a good one' $AMBER; snd no; return 0; } ;;
    cover)  (( ${XG_HOUSE[nbed]:-1} >= ${#XG_BED_NM[@]} )) && { xg_flash 'every cover the ship stocks · all yours' $AMBER; snd no; return 0; } ;;
    dish)   (( ${XG_HOUSE[nbowl]:-1} >= ${#XG_DISH_NM[@]} )) && { xg_flash 'every dish the galley has · all yours' $AMBER; snd no; return 0; } ;;
    tuning) xg_core_next; [[ -z "$REPLY" ]] && { xg_flash 'the core burns every colour it knows' $AMBER; snd no; return 0; } ;;
  esac
  if (( ${XG[credits]:-0} < cost )); then xg_flash 'not enough credits · care pays' $RED; snd no; return 0; fi
  XG[credits]=$(( ${XG[credits]:-0}-cost )); snd pick
  case "$id" in
    pods)   XG_HOUSE[pantry]=$(( ${XG_HOUSE[pantry]:-0}+6 )); xg_log 'kibble pods · pantry +6' "−$cost c" $AMBER
            msg='kibble: six more meals' ;;
    tuna)   xg_vadd food 40; xg_vadd mood 5; xg_log 'the space tuna went down immediately' 'FOOD +40' $CYAN
            msg='the tin went down immediately' ;;
    feast)  xg_vadd food 60; xg_vadd mood 15; xg_log 'the nebula feast · regarded, then gone' 'FOOD +60' $CYAN
            msg='dinner was regarded, then gone' ;;
    yarn|orb|pointer)
            xg_own "$id"
            [[ "$id" == pointer ]] || { [[ "$id" == orb || -z "${XG_HOUSE[toy]:-}" ]] && XG_HOUSE[toy]="$id"; XG_RCK=''; }
            xg_log "$nm · into the toy chest" '' $LIME; msg="$nm: in the toy chest" ;;
    cover)  n=${XG_HOUSE[nbed]:-1}; XG_HOUSE[nbed]=$(( n+1 )); XG_HOUSE[bed]=$n; XG_RCK=''
            xg_log "the ${XG_BED_NM[$n]}, in" '' $LIME; msg='the bed is in.  we will see' ;;
    dish)   n=${XG_HOUSE[nbowl]:-1}; XG_HOUSE[nbowl]=$(( n+1 )); XG_HOUSE[bowl]=$n; XG_RCK=''
            xg_log "the ${XG_DISH_NM[$n]}, out" '' $LIME; msg='a better bowl.  same kibble' ;;
    tuning) xg_core_next; xg_own "$REPLY"; XG_HOUSE[style]="$REPLY"; XG_CORE_PAL=0; XG_RCK=''
            xg_log "the core, retuned · $REPLY" '' $LIME; msg='the room is coming together' ;;
  esac
  xg_flash "$msg" $LIME
  xg_save_write
  return 0
}

# ── what buying it does, row by row: label · kind · before · after · colour ──
#    kinds: bar (a 0..100 vital) · txt (before → after) · note (words) ·
#           bed / dish / core (a style, with its colour as a swatch)
typeset -ga XG_SPL XG_SPK XG_SPB XG_SPA XG_SPC
xg_store_spec() {   # xg_store_spec IDX
  local -i i=$1 f=${XG[food]:-0} m=${XG[mood]:-0} n p
  local cur nxt
  XG_SPL=(); XG_SPK=(); XG_SPB=(); XG_SPA=(); XG_SPC=()
  case "${XG_ST_ID[$i]}" in
    pods)  p=${XG_HOUSE[pantry]:-0}
           XG_SPL+=(PANTRY); XG_SPK+=(txt);  XG_SPB+=("$p meals"); XG_SPA+=("$(( p+6 )) meals"); XG_SPC+=($AMBER)
           XG_SPL+=(FEED);   XG_SPK+=(note); XG_SPB+=('[F] opens one at the dish'); XG_SPA+=(''); XG_SPC+=($XG_LBL) ;;
    tuna)  XG_SPL+=(FOOD MOOD); XG_SPK+=(bar bar); XG_SPB+=($f $m)
           XG_SPA+=($(( f+40 > 100 ? 100 : f+40 )) $(( m+5 > 100 ? 100 : m+5 ))); XG_SPC+=($XG_FG $PURPLE) ;;
    feast) XG_SPL+=(FOOD MOOD); XG_SPK+=(bar bar); XG_SPB+=($f $m)
           XG_SPA+=($(( f+60 > 100 ? 100 : f+60 )) $(( m+15 > 100 ? 100 : m+15 ))); XG_SPC+=($XG_FG $PURPLE) ;;
    yarn)  XG_SPL+=('RED DOT'); XG_SPK+=(txt)
           if xg_owned yarn; then XG_SPB+=('30 s a session'); XG_SPA+=(''); else XG_SPB+=('20 s'); XG_SPA+=('30 s a session'); fi
           XG_SPC+=($RED)
           XG_SPL+=('PLAY SPOT'); XG_SPK+=(note); XG_SPB+=('the ball waits there for her'); XG_SPA+=(''); XG_SPC+=($XG_LBL) ;;
    orb)   XG_SPL+=('ALONE'); XG_SPK+=(txt); XG_SPB+=('mood falls ×1'); XG_SPA+=('×½'); XG_SPC+=($PURPLE)
           XG_SPL+=('NIGHTS'); XG_SPK+=(note); XG_SPB+=('someone to play with'); XG_SPA+=(''); XG_SPC+=($XG_LBL) ;;
    pointer) XG_SPL+=('CATCH'); XG_SPK+=(txt); XG_SPB+=('35%'); XG_SPA+=('55% a pounce'); XG_SPC+=($RED)
           XG_SPL+=('THE DOT'); XG_SPK+=(note); XG_SPB+=('sharper, whiter, pays +2 c'); XG_SPA+=(''); XG_SPC+=($XG_LBL) ;;
    cover) n=${XG_HOUSE[nbed]:-1}; (( n >= ${#XG_BED_NM[@]} )) && n=$(( ${#XG_BED_NM[@]}-1 ))
           XG_SPL+=('BED'); XG_SPK+=(bed); XG_SPB+=(${XG_HOUSE[bed]:-0}); XG_SPA+=($n); XG_SPC+=($XG_LBL)
           if (( ${XG_HOUSE[nbed]:-1} < 2 )); then XG_SPL+=('NAPS'); XG_SPK+=(txt); XG_SPB+=('+30 pep'); XG_SPA+=('+37 pep'); XG_SPC+=($CYAN)
           else XG_SPL+=('NAPS'); XG_SPK+=(note); XG_SPB+=('+37 pep · already rested'); XG_SPA+=(''); XG_SPC+=($XG_LBL); fi ;;
    dish)  n=${XG_HOUSE[nbowl]:-1}; (( n >= ${#XG_DISH_NM[@]} )) && n=$(( ${#XG_DISH_NM[@]}-1 ))
           XG_SPL+=('DISH'); XG_SPK+=(dish); XG_SPB+=(${XG_HOUSE[bowl]:-0}); XG_SPA+=($n); XG_SPC+=($XG_LBL)
           XG_SPL+=('KIBBLE'); XG_SPK+=(note); XG_SPB+=('the same, in a better light'); XG_SPA+=(''); XG_SPC+=($XG_LBL) ;;
    tuning) cur="${XG_HOUSE[style]:-std}"; xg_core_next; nxt="${REPLY:-$cur}"
           XG_SPL+=('CORE'); XG_SPK+=(core); XG_SPB+=("$cur"); XG_SPA+=("$nxt"); XG_SPC+=($XG_LBL)
           XG_SPL+=('THE ROOM'); XG_SPK+=(note); XG_SPB+=('the air and the deck, retinted'); XG_SPA+=(''); XG_SPC+=($XG_LBL) ;;
  esac
  return 0
}
xg_style_swatch() {   # xg_style_swatch KIND KEY → REPLY the colour that stands for that style
  local -a p
  case "$1" in
    bed)  p=(${=XG_BED_PAL[$2]});  _pack ${p[0]} ${p[1]} ${p[2]}; REPLY=$PK ;;
    dish) p=(${=XG_DISH_PAL[$2]}); _pack ${p[0]} ${p[1]} ${p[2]}; REPLY=$PK ;;
    core) xg_style_glow "$2"; REPLY=$XSG ;;
  esac
}
xg_store_specrow_at() {   # xg_store_specrow_at X Y W R [BG] — one row of the spec, in a width
  local -i x=$1 y=$2 w=$3 r=$4 bg=${5:--2} bw b a j col lb dimc ex
  local k="${XG_SPK[$r]}" s1 s2
  cmix $GREY $CYAN 0.25; cshade $CM 1.0; lb=$CS
  (( XI_LO )) || xg_ink; dimc=$XI_LO
  v_text $x $y "${XG_SPL[$r]}" $lb $bg
  x=$(( x+10 )); w=$(( w-10 ))
  case "$k" in
    bar)
      b=${XG_SPB[$r]}; a=${XG_SPA[$r]}; bw=$(( w-14 )); (( bw > 18 )) && bw=18; (( bw < 6 )) && bw=6
      col=${XG_SPC[$r]}
      for (( j=0; j<bw; j++ )); do
        if (( j < (b*bw+50)/100 )); then v_put $(( x+j )) $y '▰' $col $bg
        elif (( j < (a*bw+50)/100 )); then v_put $(( x+j )) $y '▰' $LIME $bg
        else v_put $(( x+j )) $y '▱' $XI_TRK $bg; fi
      done
      v_text $(( x+bw+2 )) $y "$b" $XI_TX $bg
      v_text $(( x+bw+2+${#b} )) $y ' → ' $dimc $bg
      v_text $(( x+bw+5+${#b} )) $y "$a" $XG_WHITE $bg
      (( a > b )) && v_text $(( x+w-2-${#a} )) $y "+$(( a-b ))" $LIME $bg ;;
    txt)
      v_text $x $y "${XG_SPB[$r]}" $XI_TX $bg
      if [[ -n "${XG_SPA[$r]}" ]]; then
        ex=$(( x+${#XG_SPB[$r]} ))
        v_text $ex $y ' → ' $dimc $bg
        v_text $(( ex+3 )) $y "${XG_SPA[$r]}" $LIME $bg
      fi ;;
    note)
      v_text $x $y "${XG_SPB[$r]}" $dimc $bg ;;
    bed|dish|core)
      xg_style_swatch $k "${XG_SPB[$r]}"; col=$REPLY
      case $k in bed) s1="${XG_BED_NM[${XG_SPB[$r]}]%% *}" ;; dish) s1="${XG_DISH_NM[${XG_SPB[$r]}]%% *}" ;;
                 *) xg_core_name "${XG_SPB[$r]}"; s1="$REPLY" ;; esac
      v_put $x $y '■' $col $bg; v_text $(( x+2 )) $y "$s1" $XI_TX $bg
      ex=$(( x+3+${#s1} ))
      v_text $ex $y '→ ' $dimc $bg
      xg_style_swatch $k "${XG_SPA[$r]}"; col=$REPLY
      case $k in bed) s2="${XG_BED_NM[${XG_SPA[$r]}]}" ;; dish) s2="${XG_DISH_NM[${XG_SPA[$r]}]}" ;;
                 *) xg_core_name "${XG_SPA[$r]}"; s2="$REPLY" ;; esac
      v_put $(( ex+2 )) $y '■' $col $bg; v_text $(( ex+4 )) $y "$s2" $LIME $bg ;;
  esac
  return 0
}

# ── words on the page ──
typeset -ga XG_WR
xg_wrap() {   # xg_wrap TEXT WIDTH → XG_WR, the lines
  local -i w=$2; local word cur=''
  XG_WR=()
  for word in ${=1}; do
    if [[ -z "$cur" ]]; then cur="$word"
    elif (( ${#cur}+1+${#word} <= w )); then cur="$cur $word"
    else XG_WR+=("$cur"); cur="$word"; fi
  done
  [[ -n "$cur" ]] && XG_WR+=("$cur")
  return 0
}
xg_spaced() { # "HOVER ORB" → "H O V E R   O R B"
  local s="$1" o='' c; local -i i
  for (( i=0; i<${#s}; i++ )); do c="${s[$i]}"; if [[ "$c" == ' ' ]]; then o+='  '; else o+="$c "; fi; done
  REPLY="${o% }"
}
xg_gtext() {   # xg_gtext X Y TEXT C1 C2 [BG] — each letter mixed from C1 to C2
  local s="$3"; local -i i n=${#3} x=$1
  for (( i=0; i<n; i++ )); do
    [[ "${s[$i]}" == ' ' ]] && continue
    cmix $4 $5 $(( n > 1 ? i/(n-1.0) : 0.0 )); v_put $(( x+i )) $2 "${s[$i]}" $CM ${6:--2}
  done
}
xg_rule_at() {   # xg_rule_at X Y W COLOUR [GLYPH] — a thin line, as wide as it is asked for
  local s='' g="${5:-─}"; local -i i w=$3
  (( w < 1 )) && return 0
  for (( i=0; i<w; i++ )); do s+="$g"; done
  v_text $1 $2 "$s" $4
}
v_segs() {   # v_segs X Y [BG] -- TEXT COL ... — a run of little coloured pieces, in a row
  local -i x=$1 y=$2 bg=-2; shift 2
  [[ "${1:-}" != '--' ]] && { bg=$1; shift; }
  shift
  while (( $# >= 2 )); do v_text $x $y "$1" $2 $bg; x=$(( x+${#1} )); shift 2; done
  REPLY=$x
}

# ── the icons, at any size · the painter, pointed through a scaling pen ──
# xg_store_icon draws through xg_ipix, which at scale 1 IS xg_pix.  At twice
# the size a pixel is two whole cells (the icon always starts on an even
# half-row), so the pair goes straight into the grid: four times less work
# than four half-cell writes, and a doubled icon is 250 pixels.
typeset -gi XG_IS=1 XG_IX=0 XG_IY=0
xg_ipix() {
  if (( XG_IS == 1 )); then xg_pix $1 $2 $3; return 0; fi
  local -i dx=$(( $1-XG_IX )) dy=$(( $2-XG_IY )) sx sy X Y k base
  if (( XG_IS == 2 && XG_IY % 2 == 0 )); then
    Y=$(( XG_IY/2+dy )); (( Y < 0 || Y >= SCR_H )) && return 0
    X=$(( XG_IX+dx*2 )); base=$(( (OY+R_SCR+Y)*TCOLS+OX+C_SCR ))
    if (( X >= 0 && X < SCR_W )); then k=$(( base+X )); GCH[$k]=' '; GF[$k]=$GREY; GB[$k]=$3; fi
    X=$(( X+1 ))
    if (( X >= 0 && X < SCR_W )); then k=$(( base+X )); GCH[$k]=' '; GF[$k]=$GREY; GB[$k]=$3; fi
    return 0
  fi
  for (( sy=0; sy<XG_IS; sy++ )); do for (( sx=0; sx<XG_IS; sx++ )); do
    xg_pix $(( XG_IX+dx*XG_IS+sx )) $(( XG_IY+dy*XG_IS+sy )) $3
  done; done
}
xg_ipixget() {
  if (( XG_IS == 1 )); then xg_pixget $1 $2; return $?; fi
  xg_pixget $(( XG_IX+($1-XG_IX)*XG_IS )) $(( XG_IY+($2-XG_IY)*XG_IS ))
}
xg_store_icon() {   # xg_store_icon IDX X PY [SCALE] — each item's own little lit picture (the original's _icon_for)
  XG_IX=$2; XG_IY=$3; XG_IS=${4:-1}                  # the pen: 1 is a half-cell pixel, 2 is two whole cells
  local -i i=$1 x=$2 y=$3 px py c a b rim well n
  local -F k d dx dy
  case "${XG_ST_ID[$i]}" in
    pods)     # a kibble pod · a steel capsule, the kibble behind its window, a status light
      xg_rgb 96 110 140; a=$REPLY; xg_rgb 214 224 244; b=$REPLY
      for (( py=1; py<=6; py++ )); do for (( px=1; px<=10; px++ )); do
        (( (py == 1 || py == 6) && (px < 2 || px > 9) )) && continue
        cmix $a $b $(( (px-1)/9.0 )); c=$CM
        (( py == 1 )) && { cmix $c $WHITE 0.25; c=$CM; }
        (( py == 6 )) && { cshade $c 0.7; c=$CS; }
        if (( px >= 4 && px <= 7 && py >= 2 && py <= 5 )); then
          if (( (px+py) % 3 == 0 )); then xg_rgb 228 150 60; else xg_rgb 170 104 48; fi; c=$REPLY
        fi
        xg_ipix $(( x+px )) $(( y+py )) $c
      done; done
      xg_rgb 140 240 255; xg_ipix $(( x+9 )) $(( y+2 )) $REPLY ;;
    tuna)     # a tin from the galley · the lid, the label band, the fish on it
      xg_rgb 176 196 210; a=$REPLY; xg_rgb 244 250 252; b=$REPLY
      for (( px=1; px<=10; px++ )); do cmix $a $b $(( (px-1)/9.0 )); xg_ipix $(( x+px )) $(( y+1 )) $CM; done
      for (( py=2; py<=6; py++ )); do for (( px=1; px<=10; px++ )); do
        if (( py == 3 || py == 4 )); then xg_rgb 214 104 52; a=$REPLY; xg_rgb 255 170 92; b=$REPLY
        else xg_rgb 70 92 124; a=$REPLY; xg_rgb 150 172 204; b=$REPLY; fi
        cmix $a $b $(( (px-1)/9.0 )); cshade $CM $(( 1.0-0.06*(py-2) )); xg_ipix $(( x+px )) $(( y+py )) $CS
      done; done
      xg_rgb 252 250 255; c=$REPLY
      for px in 5 6 7 9; do xg_ipix $(( x+px )) $(( y+3 )) $c; done
      for px in 4 5 6 7 8; do xg_ipix $(( x+px )) $(( y+4 )) $c; done ;;
    feast)    # a nebula feast · a cloche with a nebula sheen, on its plate
      xg_rgb 110 84 170; a=$REPLY; xg_rgb 240 228 255; b=$REPLY
      for (( py=0; py<5; py++ )); do for (( px=0; px<12; px++ )); do
        dx=$(( (px-5.5)/5.8 )); dy=$(( (py-5.0)/5.0 )); (( dx*dx+dy*dy <= 1.0 )) || continue
        k=$(( dx*0.5-dy*0.5+0.3 )); (( k < 0.0 )) && k=0.0; (( k > 1.0 )) && k=1.0
        cmix $a $b $k; c=$CM
        (( (px*7+py*3) % 11 == 0 )) && { xg_rgb 255 150 220; cmix $c $REPLY 0.45; c=$CM; }
        xg_ipix $(( x+px )) $(( y+py )) $c
      done; done
      xg_rgb 200 196 228; c=$REPLY; for (( px=0; px<12; px++ )); do xg_ipix $(( x+px )) $(( y+6 )) $c; done
      xg_rgb 255 255 255; xg_ipix $(( x+5 )) $y $REPLY ;;
    yarn)     # the yarn ball · the one that waits at the play spot
      xg_rgb 150 48 80; a=$REPLY; xg_rgb 250 176 196; b=$REPLY
      for (( py=0; py<8; py++ )); do for (( px=0; px<10; px++ )); do
        dx=$(( (px-4.5)/3.7 )); dy=$(( (py-3.8)/3.7 )); (( dx*dx+dy*dy <= 1.0 )) || continue
        k=$(( 0.5+0.5*(dx*0.6-dy*0.8) )); (( k < 0.0 )) && k=0.0; (( k > 1.0 )) && k=1.0
        cmix $a $b $k; c=$CM
        (( (px+2*py) % 4 == 0 )) && { cshade $c 0.72; c=$CS; }
        xg_ipix $(( x+px )) $(( y+py )) $c
      done; done
      xg_rgb 206 84 110; c=$REPLY; xg_ipix $(( x+9 )) $(( y+6 )) $c; xg_ipix $(( x+10 )) $(( y+7 )) $c; xg_ipix $(( x+11 )) $(( y+7 )) $c ;;
    orb)      # the hover orb · a lit sphere riding its own glow
      xg_rgb 40 110 160; a=$REPLY; xg_rgb 214 250 255; b=$REPLY
      for (( py=0; py<7; py++ )); do for (( px=1; px<10; px++ )); do
        dx=$(( (px-5.0)/3.4 )); dy=$(( (py-3.0)/3.4 )); (( dx*dx+dy*dy <= 1.0 )) || continue
        k=$(( 0.45+0.55*(dx*0.6-dy*0.8) )); (( k < 0.0 )) && k=0.0; (( k > 1.0 )) && k=1.0
        cmix $a $b $k; xg_ipix $(( x+px )) $(( y+py )) $CM
      done; done
      xg_rgb 255 255 255; xg_ipix $(( x+6 )) $(( y+1 )) $REPLY
      xg_rgb 60 200 230; c=$REPLY
      for (( px=2; px<=8; px++ )); do xg_ipixget $(( x+px )) $(( y+7 )); cmix $REPLY $c $(( 0.5*(1.0-abs(px-5)/4.0) )); xg_ipix $(( x+px )) $(( y+7 )) $CM; done ;;
    pointer)  # the photon pointer · the pen, its beam, and the dot it makes
      xg_rgb 70 66 92; a=$REPLY; xg_rgb 164 160 188; b=$REPLY
      for (( py=5; py<=6; py++ )); do for (( px=1; px<=6; px++ )); do cmix $a $b $(( (px-1)/5.0 )); xg_ipix $(( x+px )) $(( y+py )) $CM; done; done
      xg_rgb 255 80 90; c=$REPLY; xg_ipix $(( x+7 )) $(( y+5 )) $c; xg_ipix $(( x+7 )) $(( y+6 )) $c
      xg_rgb 150 40 52; c=$REPLY; xg_ipix $(( x+8 )) $(( y+4 )) $c; xg_ipix $(( x+9 )) $(( y+3 )) $c
      xg_rgb 255 60 70; c=$REPLY
      for (( py=-1; py<=1; py++ )); do for (( px=-1; px<=1; px++ )); do
        d=$(( sqrt(px*px+py*py) )); (( d > 1.5 )) && continue
        xg_ipixget $(( x+10+px )) $(( y+1+py )); cmix $REPLY $c $(( (1.0-d/1.6)*0.9 )); xg_ipix $(( x+10+px )) $(( y+1+py )) $CM
      done; done
      xg_rgb 255 200 200; xg_ipix $(( x+10 )) $(( y+1 )) $REPLY ;;
    cover)    # a bed cover · the NEXT style's colours, as a cushion (the original's bed icon)
      n=${XG_HOUSE[nbed]:-1}; (( n >= ${#XG_BED_NM[@]} )) && n=$(( ${#XG_BED_NM[@]}-1 ))
      local -a bp; bp=(${=XG_BED_PAL[$n]})
      xg_rgb ${bp[0]} ${bp[1]} ${bp[2]}; rim=$REPLY; xg_rgb ${bp[6]} ${bp[7]} ${bp[8]}; well=$REPLY
      for (( px=0; px<8; px++ )); do xg_rgb 250 248 255; cmix $rim $REPLY $(( 0.1+0.3*px/7.0 )); xg_ipix $(( x+2+px )) $y $CM; xg_ipix $(( x+2+px )) $(( y+1 )) $CM; done
      cmix $well $XG_AMBI 0.22; cshade $CM 0.85; c=$CS
      for (( px=0; px<10; px++ )); do
        if (( px == 0 || px == 9 )); then xg_ipix $(( x+1+px )) $(( y+2 )) $rim; xg_ipix $(( x+1+px )) $(( y+3 )) $rim
        else xg_ipix $(( x+1+px )) $(( y+2 )) $c; xg_ipix $(( x+1+px )) $(( y+3 )) $c; fi
      done
      cmix $rim $XG_AMBI 0.3; c=$CM
      for (( px=0; px<8; px++ )); do xg_ipix $(( x+2+px )) $(( y+4 )) $c; xg_ipix $(( x+2+px )) $(( y+5 )) $c; done ;;
    dish)     # a dish set · the NEXT colourway (the original's bowl icon)
      n=${XG_HOUSE[nbowl]:-1}; (( n >= ${#XG_DISH_NM[@]} )) && n=$(( ${#XG_DISH_NM[@]}-1 ))
      local -a dp; dp=(${=XG_DISH_PAL[$n]})
      xg_rgb ${dp[0]} ${dp[1]} ${dp[2]}; b=$REPLY
      for (( px=0; px<6; px++ )); do
        if (( px % 2 )); then xg_rgb 202 136 60; else xg_rgb 238 174 84; fi
        xg_ipix $(( x+3+px )) $y $REPLY; xg_ipix $(( x+3+px )) $(( y+1 )) $REPLY
      done
      for (( px=0; px<10; px++ )); do xg_rgb 255 252 244; cmix $b $REPLY $(( 0.25+0.3*px/9.0 )); xg_ipix $(( x+1+px )) $(( y+2 )) $CM; xg_ipix $(( x+1+px )) $(( y+3 )) $CM; done
      for (( px=0; px<8; px++ )); do cmix $b $XG_AMBI $(( 0.3*(1.0-px/7.0) )); cshade $CM 0.78; xg_ipix $(( x+2+px )) $(( y+4 )) $CS; xg_ipix $(( x+2+px )) $(( y+5 )) $CS; done ;;
    tuning)   # core tuning · a little reactor column, burning the NEXT colour
      xg_core_next; [[ -z "$REPLY" ]] && REPLY="${XG_HOUSE[style]:-std}"
      xg_style_glow "$REPLY"; c=$XSG
      for (( py=0; py<8; py++ )); do for (( px=0; px<12; px++ )); do
        dx=$(( abs(px-5.5)/6.0 )); (( dx > 1.0 )) && continue
        xg_ipixget $(( x+px )) $(( y+py )); cmix $REPLY $c $(( 0.28*(1.0-dx)*(1.0-dx) )); xg_ipix $(( x+px )) $(( y+py )) $CM
      done; done
      xg_rgb 60 70 92; a=$REPLY; xg_rgb 116 136 158; b=$REPLY
      for (( py=0; py<8; py++ )); do
        xg_ipix $(( x+3 )) $(( y+py )) $a; xg_ipix $(( x+8 )) $(( y+py )) $a
        if (( py == 2 || py == 5 )); then for (( px=4; px<=7; px++ )); do xg_ipix $(( x+px )) $(( y+py )) $b; done
        else
          cmix $c $WHITE 0.20; xg_ipix $(( x+4 )) $(( y+py )) $CM; xg_ipix $(( x+7 )) $(( y+py )) $CM
          cmix $c $WHITE 0.55; xg_ipix $(( x+5 )) $(( y+py )) $CM; xg_ipix $(( x+6 )) $(( y+py )) $CM
        fi
      done ;;
  esac
  XG_IS=1
  return 0
}

# ── THE PAGE, KEPT · the catalogue is painted once into a background cache,
#    the lit row and the sheet once per keypress into a page cache, and every
#    frame after that is three array restores.  A key, a sale, a vital
#    ticking over, the till's word or a resize changes the key and the page
#    is painted again.
typeset -ga XG_PGH XG_PGF XG_PGB XG_BGH XG_BGF XG_BGB
typeset -g  XG_PGK='' XG_BGK=''
typeset -gi XG_PG_USE=${XG_PG_USE:-1}
xg_pg_save() {
  local -i base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )) y k0 w0
  for (( y=0; y<SCR_H; y++ )); do
    k0=$(( base+y*TCOLS )); w0=$(( y*SCR_W ))
    XG_PGH[$w0,$(( w0+SCR_W-1 ))]=("${(@)GCH[@]:$k0:$SCR_W}")
    XG_PGF[$w0,$(( w0+SCR_W-1 ))]=("${(@)GF[@]:$k0:$SCR_W}")
    XG_PGB[$w0,$(( w0+SCR_W-1 ))]=("${(@)GB[@]:$k0:$SCR_W}")
  done
}
xg_pg_load() {
  local -i base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )) y k0 w0
  for (( y=0; y<SCR_H; y++ )); do
    k0=$(( base+y*TCOLS )); w0=$(( y*SCR_W ))
    GCH[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_PGH[@]:$w0:$SCR_W}")
    GF[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_PGF[@]:$w0:$SCR_W}")
    GB[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_PGB[@]:$w0:$SCR_W}")
  done
}
xg_bg_save() {
  local -i base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )) y k0 w0
  for (( y=0; y<SCR_H; y++ )); do
    k0=$(( base+y*TCOLS )); w0=$(( y*SCR_W ))
    XG_BGH[$w0,$(( w0+SCR_W-1 ))]=("${(@)GCH[@]:$k0:$SCR_W}")
    XG_BGF[$w0,$(( w0+SCR_W-1 ))]=("${(@)GF[@]:$k0:$SCR_W}")
    XG_BGB[$w0,$(( w0+SCR_W-1 ))]=("${(@)GB[@]:$k0:$SCR_W}")
  done
}
xg_bg_load() {
  local -i base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR )) y k0 w0
  for (( y=0; y<SCR_H; y++ )); do
    k0=$(( base+y*TCOLS )); w0=$(( y*SCR_W ))
    GCH[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_BGH[@]:$w0:$SCR_W}")
    GF[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_BGF[@]:$w0:$SCR_W}")
    GB[$k0,$(( k0+SCR_W-1 ))]=("${(@)XG_BGB[@]:$w0:$SCR_W}")
  done
}

# ── WHERE THE PAGE LANDS · measured off the glass, not off a 106 x 30 frame,
#    so a filled screen is a bigger catalogue and a wider sheet, not an island
#    in the middle of one.  The list takes two fifths, the sheet the rest;
#    both are capped so a very wide glass keeps its margins instead of
#    stretching a sentence to a hundred and twenty characters.
typeset -gi XS_LX=1 XS_LW=40 XS_PX=44 XS_PW=60 XS_Y0=2 XS_Y1=27 XS_IR=2 XS_GAP=1
typeset -gi XS_H=20 XS_PAD=0 XS_TOP=0 XS_SCROLL=0
xg_store_geom() {
  local -i total ir gp need
  XS_Y0=2; XS_Y1=$(( SCR_H-3 ))
  XS_LW=$(( (SCR_W-4)*40/100 )); (( XS_LW < 38 )) && XS_LW=38; (( XS_LW > 72 )) && XS_LW=72
  XS_PW=$(( SCR_W-4-XS_LW-2 ));  (( XS_PW < 46 )) && XS_PW=46; (( XS_PW > 92 )) && XS_PW=92
  total=$(( XS_LW+2+XS_PW ))
  XS_LX=$(( (SCR_W-total)/2 )); (( XS_LX < 1 )) && XS_LX=1
  XS_PX=$(( XS_LX+XS_LW+2 ))
  (( XS_PX+XS_PW > SCR_W-1 )) && XS_PW=$(( SCR_W-1-XS_PX ))
  # THE WINDOW · the wallet keeps the last two rows of the column, whatever
  # else happens; the catalogue gets the rest, and takes as many lines to a
  # thing as it can afford -- four on a tall glass, two on a short one.
  XS_H=$(( XS_Y1-2-XS_Y0+1 )); (( XS_H < 4 )) && XS_H=4
  # THREE LINES TO A THING IS THE SHAPE OF THIS PAGE -- its name, what it
  # does, and what the house already has of it -- and the page SCROLLS when
  # the glass cannot hold all of them, the way the prompts library does.  A
  # tall glass buys a fourth line of air instead of a fuller list.
  XS_IR=3; XS_GAP=1
  for ir in 4 3; do
    for gp in 4 3 2 1; do
      need=$(( 3*(1+3*ir)+2*gp ))
      if (( need <= XS_H )); then XS_IR=$ir; XS_GAP=$gp; break 2; fi
    done
  done
  xg_store_rows
  if (( XG_LR_N <= XS_H )); then XS_SCROLL=0; XS_TOP=0; XS_PAD=$(( (XS_H-XG_LR_N)/2 ))
  else XS_SCROLL=1; XS_PAD=0; fi
  return 0
}

# ── THE CATALOGUE'S ROWS · one line each, the way the prompts page keeps its
#    library: a department's name, then each thing's lines, then the air
#    before the next department.  The cursor moves by THING; the window
#    slides by LINE and follows it, and a thumb appears beside the list only
#    when there is more of it than there is room for.
typeset -ga XG_LR_KIND XG_LR_IX
typeset -gi XG_LR_N=0
xg_store_rows() {
  local -i d i k
  XG_LR_KIND=(); XG_LR_IX=()
  for (( d=0; d<3; d++ )); do
    if (( d )); then for (( k=0; k<XS_GAP; k++ )); do XG_LR_KIND+=(g); XG_LR_IX+=(-1); done; fi
    XG_LR_KIND+=(h); XG_LR_IX+=($d)
    for (( i=d*3; i<d*3+3; i++ )); do
      for (( k=0; k<XS_IR; k++ )); do XG_LR_KIND+=($k); XG_LR_IX+=($i); done
    done
  done
  XG_LR_N=${#XG_LR_KIND[@]}
  return 0
}
xg_store_rowix() {   # xg_store_rowix IDX → REPLY the row this thing's name line is on
  local -i j; REPLY=0
  for (( j=0; j<XG_LR_N; j++ )); do
    [[ "${XG_LR_KIND[$j]}" == 0 ]] && (( XG_LR_IX[j] == $1 )) && { REPLY=$j; return 0; }
  done
  return 0
}
xg_scroll_into() {   # xg_scroll_into ROW TOP SHOWN TOTAL → REPLY · the top that keeps ROW in view
  local -i row=$1 top=$2 shown=$3 total=$4
  if (( total <= shown )); then REPLY=0; return 0; fi
  (( top < 0 )) && top=0
  (( top > total-shown )) && top=$(( total-shown ))
  if   (( row < top ));        then top=$row
  elif (( row >= top+shown )); then top=$(( row-shown+1 )); fi
  (( top < 0 )) && top=0
  (( top > total-shown )) && top=$(( total-shown ))
  REPLY=$top
  return 0
}
xg_scroll_mark() {   # xg_scroll_mark X Y H TOP SHOWN TOTAL — the thumb · nothing at all when it all fits
  local -i x=$1 y=$2 h=$3 top=$4 shown=$5 total=$6 i a b
  (( total <= shown || h < 1 || total < 1 )) && return 0
  cshade $DIM 0.7
  for (( i=0; i<h; i++ )); do v_put $x $(( y+i )) '│' $CS $GLASS; done
  a=$(( int(h*top/(total+0.0)+0.5) ))
  b=$(( int(h*(top+shown)/(total+0.0)+0.5) ))
  (( b <= a )) && b=$(( a+1 ))
  cmix $GREY $CYAN 0.35
  for (( i=a; i<h && i<b; i++ )); do v_put $x $(( y+i )) '┃' $CM $GLASS; done
  return 0
}
xg_store_scroll() {   # the window follows the cursor · and brings a department's name with its first thing
  local -i row
  if (( ! XS_SCROLL )); then XS_TOP=0; return 0; fi
  xg_store_rowix $XG_OROW; row=$REPLY
  xg_scroll_into $(( row+XS_IR-1 )) $XS_TOP $XS_H $XG_LR_N; XS_TOP=$REPLY
  (( XG_OROW % 3 == 0 )) && row=$(( row-1 ))
  xg_scroll_into $row $XS_TOP $XS_H $XG_LR_N; XS_TOP=$REPLY
  return 0
}

# ── a glow made of whole cells · the sheet's plinth light.  Half-block
#    pixels are for pixel art; a terminal that draws ▀ a shade narrow than
#    its cell turns a long run of them into a dashed line, so anything that
#    is just LIGHT is painted as a cell's ground instead.
xg_cglow() {   # xg_cglow CX CY RX RY COLOUR STRENGTH — glass coords, whole cells
  local -i cx=$1 cy=$2 rx=$3 ry=$4 col=$5 x y k c base
  local -F st=$6 dx dy dd
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  for (( y=cy-ry; y<=cy+ry; y++ )); do
    (( y < 0 || y >= SCR_H )) && continue
    for (( x=cx-rx; x<=cx+rx; x++ )); do
      (( x < 0 || x >= SCR_W )) && continue
      dx=$(( (x-cx)/(rx*1.0) )); dy=$(( (y-cy)/(ry*1.0) )); dd=$(( dx*dx+dy*dy ))
      (( dd <= 1.0 )) || continue
      k=$(( base+y*TCOLS+x )); c=${GB[$k]:-$GLASS}; (( c < 0 )) && c=$GLASS
      cmix $c $col $(( (1.0-dd)*(1.0-dd)*st )); GB[$k]=$CM
    done
  done
  return 0
}

# ── the sheet's picture · the plinth light and the thing at twice the size,
#    painted once per thing and kept: a doubled icon is 250 pixels of
#    arithmetic, and it does not change while you read it.
typeset -gA XG_SHC_G XG_SHC_F XG_SHC_B
xg_sheet_art() {   # xg_sheet_art IDX X Y W H — the block is the caller's, the picture is kept
  local key="$1.$2.$3.$4.$5.${XG_HOUSE[nbed]:-1}.${XG_HOUSE[nbowl]:-1}.${XG_HOUSE[style]:-std}.${XG_HOUSE[own]:-}"
  local -i i=$1 x0=$2 y0=$3 w=$4 h=$5 x y k n=0 dcol c1 base
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  local gs=''; local -a fs bs
  if [[ -n "${XG_SHC_G[$key]:-}" ]]; then
    gs="${XG_SHC_G[$key]}"; fs=(${=XG_SHC_F[$key]}); bs=(${=XG_SHC_B[$key]})
    for (( y=y0; y<y0+h; y++ )); do for (( x=x0; x<x0+w; x++ )); do
      k=$(( base+y*TCOLS+x )); GCH[$k]="${gs[$n]}"; GF[$k]=${fs[$n]}; GB[$k]=${bs[$n]}; n=$(( n+1 ))
    done; done
    return 0
  fi
  xg_dept_col ${XG_ST_DEPT[$i]}; dcol=$REPLY
  xg_cglow $(( x0+w/2 )) $(( y0+h/2-1 )) $(( w/2 )) $(( h/2+1 )) $dcol 0.30
  cmix $GREY $dcol 0.28; cshade $CM 0.75; c1=$CS                       # the plinth it stands on
  v_fill $(( x0+2 )) $(( y0+h-1 )) $(( w-4 )) 1 ' ' $GREY $c1
  xg_store_icon $i $(( x0+(w-24)/2 )) $(( (y0+h-1)*2-2*${XG_ST_IH[$i]} )) 2
  for (( y=y0; y<y0+h; y++ )); do for (( x=x0; x<x0+w; x++ )); do
    k=$(( base+y*TCOLS+x )); gs+="${GCH[$k]:- }"; fs+=(${GF[$k]:--1}); bs+=(${GB[$k]:--1})
  done; done
  XG_SHC_G[$key]="$gs"; XG_SHC_F[$key]="${fs[*]}"; XG_SHC_B[$key]="${bs[*]}"
  return 0
}

# ── one thing in the catalogue · drawn unlit into the kept page, and again
#    lit when the cursor is on it ──
xg_store_line() {   # xg_store_line J ON — the flat row J, wherever the window has it
  local -i j=$1 on=$2 i d y col dcol sel dimc x w
  local k="${XG_LR_KIND[$j]}" st sub
  y=$(( XS_Y0+XS_PAD+j-XS_TOP ))
  (( y < XS_Y0 || y > XS_Y0+XS_H-1 )) && return 0
  w=$(( XS_LW-2 ))                                   # the last column belongs to the track
  (( XI_LO )) || xg_ink; dimc=$XI_LO
  case "$k" in
    g) v_fill $XS_LX $y $XS_LW 1 ' ' $GREY $GLASS ;;
    h) d=${XG_LR_IX[$j]}; xg_dept_col $d; dcol=$REPLY
       v_fill $XS_LX $y $XS_LW 1 ' ' $GREY $GLASS
       v_text $(( XS_LX+1 )) $y "${XG_DEPT_NM[$d]}" $dcol
       st="${XG_DEPT_TAG[$d]}"
       x=$(( XS_LX+2+${#XG_DEPT_NM[$d]} ))
       xg_rule_at $x $y $(( XS_LX+w-1-${#st}-x )) $XI_RULE '─'
       v_text $(( XS_LX+w-${#st} )) $y "$st" $XI_LO ;;
    *) i=${XG_LR_IX[$j]}; d=${XG_ST_DEPT[$i]}; xg_dept_col $d; dcol=$REPLY
       sel=-2
       if (( on )); then cmix $GLASS $dcol 0.16; sel=$CM; v_fill $XS_LX $y $XS_LW 1 ' ' $GREY $sel
       else v_fill $XS_LX $y $XS_LW 1 ' ' $GREY $GLASS; fi
       (( on )) && v_put $XS_LX $y '▌' $dcol $sel
       case "$k" in
         0) xg_store_want $i
            [[ -n "$REPLY" ]] && { cmix $RED $WHITE 0.15; v_put $(( XS_LX+2 )) $y '●' $CM $sel; }
            if (( on )); then col=$XG_WHITE; else col=$XI_HI; fi
            v_text $(( XS_LX+4 )) $y "${XG_ST_NAME[$i]}" $col $sel
            xg_store_have $i
            case "$REPLY2" in
              own) cshade $LIME 0.72; v_text $(( XS_LX+w-7 )) $y '✓ owned' $CS $sel ;;
              max) cshade $LIME 0.72; v_text $(( XS_LX+w-12 )) $y '✓ all styles' $CS $sel ;;
              *)   if (( ${XG[credits]:-0} >= ${XG_ST_COST[$i]} )); then col=$AMBER; else cshade $AMBER 0.72; col=$CS; fi
                   sub="${XG_ST_COST[$i]} c"
                   v_text $(( XS_LX+w-${#sub} )) $y "$sub" $col $sel ;;
            esac ;;
         1) if (( on )); then col=$XI_TX; else col=$dimc; fi
            xg_ell "${XG_ST_FX[$i]}" $(( w-5 ))
            v_text $(( XS_LX+4 )) $y "$REPLY" $col $sel ;;
         2) if (( on )); then col=$XI_TX; else col=$dimc; fi
            xg_store_have $i; xg_ell "$REPLY" $(( w-5 ))
            v_text $(( XS_LX+4 )) $y "$REPLY" $col $sel ;;
       esac ;;
  esac
  return 0
}

# ── the catalogue · painted once and kept: every department, every thing,
#    the wallet.  Only the lit row and the sheet are painted on a keypress.
xg_store_bg() {
  local -i j col dimc
  local st
  (( XI_LO )) || xg_ink; dimc=$XI_LO
  for (( j=XS_TOP; j<XG_LR_N && j<XS_TOP+XS_H; j++ )); do xg_store_line $j 0; done
  xg_scroll_mark $(( XS_LX+XS_LW-1 )) $XS_Y0 $XS_H $XS_TOP $XS_H $XG_LR_N
  # the wallet, at the foot of the catalogue
  cmix $GREY $CYAN 0.25; col=$CM
  v_text $(( XS_LX+1 )) $(( XS_Y1-1 )) 'WALLET' $col
  st="${XG[credits]:-0} c"
  v_text $(( XS_LX+XS_LW-3-${#st} )) $(( XS_Y1-1 )) "$st" $AMBER
  local -a lg; lg=('care ' $dimc '+10' $LIME '/day · dot ' $dimc '+2' $LIME ' ×3 · gift ' $dimc '+15' $LIME)
  v_segs $(( XS_LX+1 )) $XS_Y1 -- "${lg[@]}"
  # the sheet's own panel, empty
  xg_panel $XS_PX $XS_Y0 $XS_PW $(( XS_Y1-XS_Y0+1 )) 'SPEC SHEET'
  return 0
}

# ── the sheet · everything the cursor is standing on ──
xg_store_fg() {
  local -i i d y x ix iw tx tw ay ah col c1 dcol chip dimc
  local st nm s
  i=$XG_OROW; d=${XG_ST_DEPT[$i]}; xg_dept_col $d; dcol=$REPLY
  (( XI_LO )) || xg_ink; dimc=$XI_LO
  xg_store_rowix $i; local -i r0=$REPLY                 # the thing under the cursor, lit
  for (( x=0; x<XS_IR; x++ )); do xg_store_line $(( r0+x )) 1; done
  ix=$(( XS_PX+2 )); iw=$(( XS_PW-4 ))
  s=" $(( i+1 )) OF 9 "
  v_text $(( XS_PX+XS_PW-3-${#s} )) $XS_Y0 "$s" $XI_LO $GLASS
  # the thing itself, on its lit plinth
  ah=9; ay=$(( XS_Y0+1 ))
  xg_sheet_art $i $ix $ay 28 $ah
  tx=$(( ix+30 )); tw=$(( iw-30 ))
  if (( tw < 26 )); then tx=$ix; tw=$iw; fi            # a narrow sheet stacks instead
  xg_spaced "${XG_ST_NAME[$i]}"
  if (( ${#REPLY} > tw )); then st="${XG_ST_NAME[$i]}"; else st="$REPLY"; fi
  xg_gtext $tx $(( ay+1 )) "$st" $dcol $XG_WHITE
  cshade $dcol 0.85; v_text $tx $(( ay+2 )) "${XG_DEPT_NM[$d]}" $CS
  xg_ell "· ${XG_DEPT_TAG[$d]}" $(( tw-${#XG_DEPT_NM[$d]}-2 ))
  v_text $(( tx+1+${#XG_DEPT_NM[$d]} )) $(( ay+2 )) "$REPLY" $XI_LO
  xg_store_till $i
  if (( XG_CAN == 0 )); then cshade $AMBER 0.6; col=$CS; else col=$AMBER; fi
  v_text $tx $(( ay+4 )) "${XG_ST_COST[$i]} c" $col
  s="balance ${XG_BAL} c"
  (( tw > ${#s}+8 )) && v_text $(( tx+tw-${#s} )) $(( ay+4 )) "$s" $XI_LO
  xg_store_have $i; st=" ${(U)REPLY} "
  case "$REPLY2" in
    own|max) cshade $LIME 0.35; chip=$CS; st=" ✓${st}"; v_text $tx $(( ay+6 )) "$st" $XG_WHITE $chip ;;
    *)       cmix $GLASS $GREY 0.22; chip=$CM; v_text $tx $(( ay+6 )) "$st" $XG_LBL $chip ;;
  esac
  xg_store_want $i
  [[ -n "$REPLY" ]] && { cmix $RED $WHITE 0.15; v_text $tx $(( ay+8 )) "● ${(U)REPLY}" $CM }
  # ── its words, what it does, and what the house has.  The first blocks
  #    flow down from the picture and the house block hangs off the foot, so
  #    a taller glass opens its air BETWEEN them, not below everything.
  local -a hl hr; hl=(); hr=()
  xg_owned yarn    && { hl+=('yarn ball');      hr+=('runs long'); }
  xg_owned orb     && { hl+=('hover orb');      hr+=('works nights'); }
  xg_owned pointer && { hl+=('photon pointer'); hr+=('sharper dot'); }
  hl+=("${XG_BED_NM[${XG_HOUSE[bed]:-0}]}");    hr+=('in use')
  hl+=("${XG_DISH_NM[${XG_HOUSE[bowl]:-0}]}");  hr+=('at the galley')
  xg_core_name "${XG_HOUSE[style]:-std}"; hl+=("$REPLY core"); hr+=('the room burns it')
  hl+=("kibble ×${XG_HOUSE[pantry]:-0}");       hr+=('in the cupboard')
  local -i hn=${#hl[@]} hy g nd ns
  hy=$(( XS_Y1-5-hn ))
  xg_wrap "${XG_ST_DESC[$i]}" $iw; nd=${#XG_WR[@]}; (( nd > 3 )) && nd=3
  xg_store_spec $i; ns=${#XG_SPL[@]}; (( ns > 3 )) && ns=3
  g=$(( (hy-(ay+ah)-nd-ns-2)/3 )); (( g < 1 )) && g=1; (( g > 4 )) && g=4
  y=$(( ay+ah+g ))
  for (( x=0; x<nd; x++ )); do v_text $ix $(( y+x )) "${XG_WR[$x]}" $XI_TX; done
  y=$(( y+nd+g ))
  nm="${(U)XG[name]:-HER}"
  cshade $AMBER 0.85; v_text $ix $y "ON $nm" $CS
  xg_rule_at $(( ix+4+${#nm} )) $y $(( iw-5-${#nm} )) $XI_RULE '┄'
  for (( x=0; x<ns; x++ )); do xg_store_specrow_at $ix $(( y+1+x )) $iw $x; done
  y=$(( y+1+ns ))
  # a tall glass gets her four meters too · you are shopping FOR her, after all
  if (( hy-y >= 7 )); then
    local -i my=$(( y+(hy-y-5)/2 ))
    cshade $AMBER 0.85; v_text $ix $my 'HER NEEDS NOW' $CS
    xg_rule_at $(( ix+14 )) $my $(( iw-15 )) $XI_RULE '┄'
    local -i mw=$(( iw/2-12 )); (( mw > 16 )) && mw=16; (( mw < 8 )) && mw=8
    xg_meter $ix $(( my+1 )) $mw FOOD   ${XG[food]:-0}   $XG_FG
    xg_meter $ix $(( my+2 )) $mw MOOD   ${XG[mood]:-0}   $PURPLE
    xg_meter $(( ix+mw+13 )) $(( my+1 )) $mw PEP    ${XG[pep]:-0}    $CYAN
    xg_meter $(( ix+mw+13 )) $(( my+2 )) $mw HEALTH ${XG[health]:-0} $XG_OK
  fi
  if (( hy > y+1 )); then
    cshade $AMBER 0.85; v_text $ix $hy 'IN THE HOUSE' $CS
    xg_rule_at $(( ix+13 )) $hy $(( iw-14 )) $XI_RULE '┄'
    for (( x=0; x<hn; x++ )); do
      v_text $ix $(( hy+1+x )) "▪ ${hl[$x]}" $XI_TX
      v_text $(( ix+iw-${#hr[$x]} )) $(( hy+1+x )) "${hr[$x]}" $XI_LO
    done
  fi
  # the till, at the foot of the sheet
  y=$(( XS_Y1-3 ))
  xg_rule_at $ix $y $iw $XI_RULE '┄'
  local -a sm
  case $XG_CAN in
    1) sm=("$XG_BAL c" $XG_FG '  −  ' $dimc "$XG_PRICE c" $XG_LBL '  =  ' $dimc "$XG_LEFT c left" $LIME)
       case $d in 0) st='eaten on the spot' ;; 1) st='into the toy chest' ;; *) st='into the room' ;; esac
       [[ "${XG_ST_ID[$i]}" == pods ]] && st='into the pantry'
       v_segs $ix $(( y+1 )) -- "${sm[@]}"
       cshade $LIME 0.75; v_text $ix $(( y+2 )) "⏎ buys it · $st" $CS ;;
    0) sm=("$XG_BAL c" $XG_FG '  −  ' $dimc "$XG_PRICE c" $XG_LBL '  =  ' $dimc "short $(( -XG_LEFT )) c" $RED)
       v_segs $ix $(( y+1 )) -- "${sm[@]}"
       x=$(( (-XG_LEFT+9)/10 ))
       if (( x == 1 )); then st='one good day of care'; else st="$x good days of care"; fi
       v_text $ix $(( y+2 )) "≈ $st away" $XI_TX ;;
    2) cshade $LIME 0.8; v_text $ix $(( y+1 )) 'already yours' $CS
       v_text $ix $(( y+2 )) 'the balance stays put' $XI_TX ;;
  esac
  # the word from the till, for a moment
  (( XG_FLASH_T > XG_NOW )) && [[ -n "$XG_FLASH" ]] && {
    v_fill $ix $(( y-1 )) $iw 1 ' ' $GREY $GLASS
    v_text $(( ix+(iw-${#XG_FLASH})/2 )) $(( y-1 )) "$XG_FLASH" $XG_FLASH_C
  }
  app_nav '◂ ▸' pages '▴ ▾' browse '⏎' buy '[H]' home '[⎋]' menu
  return 0
}

xg_draw_store() {
  xg_store_geom; xg_store_scroll
  local key="store.${SCR_W}x${SCR_H}.$XG_OROW.$XS_TOP.${XG[credits]:-0}.${XG_HOUSE[own]:-}.${XG_HOUSE[pantry]:-0}.${XG_HOUSE[nbed]:-1}.${XG_HOUSE[bed]:-0}.${XG_HOUSE[nbowl]:-1}.${XG_HOUSE[bowl]:-0}.${XG_HOUSE[style]:-std}.${XG[food]:-0}.${XG[mood]:-0}.${XG[pep]:-0}.${XG[name]:-}"
  (( XG_FLASH_T > XG_NOW )) && key+=".flash:$XG_FLASH"
  local bgk="store.${SCR_W}x${SCR_H}.$XS_TOP.${XG[credits]:-0}.${XG_HOUSE[own]:-}.${XG_HOUSE[pantry]:-0}.${XG_HOUSE[nbed]:-1}.${XG_HOUSE[bed]:-0}.${XG_HOUSE[nbowl]:-1}.${XG_HOUSE[bowl]:-0}.${XG_HOUSE[style]:-std}.${XG[food]:-0}.${XG[mood]:-0}.${XG[pep]:-0}"
  if (( XG_PG_USE )) && [[ "$key" == "$XG_PGK" ]]; then
    xg_pg_load
  else
    if (( XG_PG_USE )) && [[ "$bgk" == "$XG_BGK" ]]; then xg_bg_load
    else
      v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
      xg_store_bg
      (( XG_PG_USE )) && { xg_bg_save; XG_BGK="$bgk"; }
    fi
    xg_store_fg
    (( XG_PG_USE )) && { xg_pg_save; XG_PGK="$key"; }
  fi
  xg_head 'THE STORE' 1 CREDITS "${XG[credits]:-0}" $XG_FG - '· EARNED BY GOOD CARE' $XG_LBL
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# STATS · THE ROSTER · a page, not a popup · every animal ever signed for
# ══════════════════════════════════════════════════════════════════════════
# STATS used to fold up over the room as a modal, which meant it could only
# ever be about whoever was standing in it.  It is a PAGE now, in the ◂ ▸ ring
# with the others, and it reads the whole house: the save keeps every arrival
# under xenogotchi.pets.<slot>.*, and none of them were ever shown anywhere.
# So the page takes the catalogue's shape -- a list you read down on the left,
# a card that reads back on the right -- and puts each animal's own portrait,
# needs, papers and lifetime on the card.  The resident is live out of XG; the
# rest are read out of the save exactly as they were put away.
typeset -ga XR_NM XR_SD XR_SP XR_SLOT XR_LB XR_EY XR_BD XR_TM XR_ST XR_STI XR_AGE XR_LEFT XR_PAL XR_BR XR_SPN
typeset -ga XR_DAY XR_HP XR_FD XR_WT XR_BN XR_CT XR_MD XR_PP XR_BX
typeset -ga XR_PET XR_NAP XR_TRT XR_CAT XR_GFT XR_STRK XR_ALB
typeset -gi XR_N=0 XR_ROW=0 XR_HOME=0
typeset -g  XR_KEY=''

# ══════════════════════════════════════════════════════════════════════════
# THE WIDER INTAKE · thirteen more decks, and one dealer for all of them
# ══════════════════════════════════════════════════════════════════════════
# The cat and the dog each keep their own hand-dealt deck, because each has
# something the others do not (the cat's ear-and-tail build, the dog's ears
# and tail).  Everything after them shares one dealer parameterised by its
# deck -- the original's _deal_generic, brought across whole.  A deck is one
# string per axis so that fifteen species do not become sixty global arrays;
# xg_deck splits the one being dealt and keeps it, so a litter of four costs
# four lookups, not four hundred.
typeset -gA XG_DK_CW XG_DK_PAT XG_DK_EYN XG_DK_EYC XG_DK_TMP XG_DK_BLD XG_DK_SPAN XG_DK_ODD
XG_DK_CW[rabbit]='white:242,238,232|grey:156,152,164|brown:134,96,66|black:54,48,62|fawn:214,176,134|cream:236,214,178|chocolate:110,74,54|lilac:186,168,190'
XG_DK_CW[hamster]='golden:224,158,84|white:242,238,230|grey:168,164,176|champagne:232,200,158|black:58,52,64|cinnamon:198,128,82|dove:196,186,196|sable:120,92,70'
XG_DK_CW[fox]='red:206,108,54|silver:98,94,110|cross:178,110,62|arctic:238,236,234|marble:216,208,206|amber:222,152,76|shadow:72,62,78|platinum:196,178,168'
XG_DK_CW[turtle]='forest:74,112,62|olive:128,132,66|amber:168,128,58|slate:96,104,112|moss:92,122,84|chestnut:134,92,54|jade:86,142,110|dusk:90,84,108'
XG_DK_CW[hedgehog]='salt-pepper:150,142,148|cinnamon:206,152,104|chocolate:118,86,64|cream:238,224,200|grey:132,128,140|fawn:208,176,138|charcoal:82,76,86|apricot:228,172,118'
XG_DK_CW[glorp]='plasma:232,88,164|ecto:110,224,138|ion:92,198,238|ultraviolet:152,92,235|solar:240,190,84|void:76,66,98|rose:238,134,158|mint:134,228,190'
XG_DK_CW[xeno]='obsidian:44,44,56|tar:36,34,40|void-blue:46,54,78|bruise:58,44,72|umbra:52,42,50|graphite:66,66,74|bone:196,188,172|acid-sheen:48,62,54'
XG_DK_CW[duck]='white:240,236,226|buff:222,192,148|cayuga:52,58,62|khaki:176,152,108|snowy:228,228,232|chocolate:112,80,58|blue-slate:128,138,154|apricot:226,176,128'
XG_DK_CW[frog]='leaf:96,168,74|moss:110,138,72|teal:62,148,136|golden:224,182,84|tomato:216,92,74|cobalt:72,118,208|earth:142,108,74|mint:150,216,168'
XG_DK_CW[snake]='emerald:72,152,96|corn:216,128,66|albino:238,224,198|midnight:48,46,60|copper:168,110,70|jade:110,168,128|lavender:182,162,196|sand:206,180,134'
XG_DK_CW[owl]='barn-cream:226,206,168|tawny:188,142,92|grey:152,148,158|snowy:238,236,238|umber:124,94,66|rust:186,116,72|smoke:108,104,118|moon-pale:214,210,222'
XG_DK_CW[pig]='pink:232,176,168|cream:236,216,190|black:58,52,60|ginger:206,128,76|grey:162,154,158|chestnut:150,96,66|sandy:214,178,132|rose:222,154,150'
XG_DK_CW[axolotl]='leucistic:240,198,198|wild:118,104,88|golden:230,190,110|melanoid:56,52,62|copper:192,130,92|lavender:196,172,204|pearl:232,226,224|peach:238,186,160'

XG_DK_PAT[rabbit]='plain|dutch|broken|points|agouti'
XG_DK_PAT[hamster]='plain|banded|spotted|roan'
XG_DK_PAT[fox]='plain|mask|cross|marble|socks'
XG_DK_PAT[turtle]='plain|hex|striped|spotted|painted'
XG_DK_PAT[hedgehog]='plain|banded|frosted|masked'
XG_DK_PAT[glorp]='plain|speckled|ringed|nebular|glassy'
XG_DK_PAT[xeno]='gloss|ribbed|chitin|biomech|matte'
XG_DK_PAT[duck]='plain|bibbed|penciled|capped|mallard'
XG_DK_PAT[frog]='plain|spotted|striped|darted|belly'
XG_DK_PAT[snake]='plain|banded|diamond|striped|speckled'
XG_DK_PAT[owl]='plain|barred|speckled|heart-faced|hooded'
XG_DK_PAT[pig]='plain|spotted|belted|saddleback|mud-streaked'
XG_DK_PAT[axolotl]='plain|speckled|mottled|dalmatian|glow'

XG_DK_EYN[rabbit]='brown|amber|blue|ruby'
XG_DK_EYN[hamster]='black|ruby|brown'
XG_DK_EYN[fox]='amber|gold|brown|ice'
XG_DK_EYN[turtle]='obsidian|amber|olive'
XG_DK_EYN[hedgehog]='black|brown|ruby'
XG_DK_EYN[glorp]='obsidian|gold|cyan|magenta'
XG_DK_EYN[xeno]='none'
XG_DK_EYN[duck]='black|brown|hazel'
XG_DK_EYN[frog]='gold|copper|black|red'
XG_DK_EYN[snake]='amber|garnet|olive|pearl'
XG_DK_EYN[owl]='gold|amber|black|moon'
XG_DK_EYN[pig]='black|brown|hazel'
XG_DK_EYN[axolotl]='black|navy|gold'
XG_DK_EYC[rabbit]='128,92,60|208,156,80|140,200,240|214,108,118'
XG_DK_EYC[hamster]='30,26,36|214,108,118|128,92,60'
XG_DK_EYC[fox]='226,160,70|240,196,92|134,96,60|150,210,240'
XG_DK_EYC[turtle]='30,28,34|212,158,76|140,148,74'
XG_DK_EYC[hedgehog]='28,24,34|124,90,58|210,106,116'
XG_DK_EYC[glorp]='32,28,40|238,194,88|98,214,240|232,96,190'
XG_DK_EYC[xeno]='44,44,56'
XG_DK_EYC[duck]='30,28,36|120,88,58|146,120,66'
XG_DK_EYC[frog]='234,186,78|206,128,62|32,30,38|214,88,84'
XG_DK_EYC[snake]='222,164,70|188,76,84|140,148,74|216,214,222'
XG_DK_EYC[owl]='240,196,74|222,152,64|34,32,40|222,222,234'
XG_DK_EYC[pig]='32,28,36|122,88,58|148,122,70'
XG_DK_EYC[axolotl]='30,28,38|52,62,96|226,184,92'

XG_DK_TMP[rabbit]='curious:audits the perimeter:1.05:1.0|timid:heard that.  whatever it was:0.9:1.25|bold:afraid of nothing, ever:1.1:1.1|zoomy:laps of the habitat, hourly:1.2:0.95|dignified:a very serious rabbit:0.85:1.05|mischief:the wires are not safe:1.1:1.2'
XG_DK_TMP[hamster]='nocturnal:runs the night shift:1.1:1.0|hoarder:everything is provisions:1.05:1.05|zoomy:cardio is a lifestyle:1.25:0.9|gentle:a hand-tame heart:0.9:1.0|escape-artist:checks the seams, nightly:1.1:1.2|sleepy:professionally cosy:0.8:0.95'
XG_DK_TMP[fox]='sly:three plans at all times:1.1:1.2|theatrical:everything is a heist:1.2:1.15|aloof:affection on its own terms:0.85:1.1|zoomy:the room is a getaway:1.2:0.95|curious:screams politely at things:1.05:1.1|nocturnal:works the late shift:1.0:1.05'
XG_DK_TMP[turtle]='ancient:has seen things.  slowly:0.6:1.0|determined:gets there.  eventually:0.75:0.95|bold:surprisingly fast, once:0.9:1.05|sleepy:hibernation-curious:0.6:0.9|curious:investigates at leisure:0.8:1.0|stoic:unmoved by drama:0.7:0.85'
XG_DK_TMP[hedgehog]='nocturnal:the night is a buffet:1.05:1.0|huffy:opinions, expressed in huffs:0.9:1.25|explorer:must see behind everything:1.1:1.0|gentle:quills down for you:0.9:0.95|snacky:motivated by mealworms:1.15:1.0|tidy:self-anoints on schedule:1.0:1.1'
XG_DK_TMP[glorp]='curious:tastes everything, once:1.1:1.0|placid:at one with the floor:0.8:0.9|jiggly:vibrating with purpose:1.25:1.0|eldritch:hums in n dimensions:0.95:1.2|clingy:currently on your shoe:1.0:1.3|sunny:photosynthesizing joy:1.05:0.95'
XG_DK_TMP[xeno]='apex:the perfect organism, resting:1.05:1.1|broody:keeps to the vents (the shelf):0.9:1.15|curious:studies you, professionally:1.0:1.05|clingy:imprinted.  no refunds:1.05:1.3|nocturnal:the night shift is hers:1.0:1.05|theatrical:hisses at own reflection:1.15:1.2'
XG_DK_TMP[duck]='boisterous:quacks the news, hourly:1.15:1.1|serene:glides through life:0.85:0.95|bossy:runs the pond (the bowl):1.05:1.25|snacky:peas are a love language:1.15:1.0|zoomy:runs like the ground owes it:1.2:0.95|broody:sits on everything round:0.9:1.1'
XG_DK_TMP[frog]='zen:one with the moss pad:0.8:0.9|vocal:croaks at 3 a.m., beautifully:1.05:1.15|jumpy:startles into orbit:1.2:1.1|sticky:everything is a perch:1.0:1.05|nocturnal:the night chorus lead:1.0:1.0|hungry-eyed:watches flies that are not:1.1:1.0'
XG_DK_TMP[snake]='cozy:seeks the warm spot, always:0.85:0.95|curious:tastes the air about you:1.0:1.05|dramatic:hides for days, returns famous:0.95:1.2|chill:a professional at rest:0.75:0.9|nocturnal:patrols after lights-out:1.0:1.0|food-motivated:the bowl is a ritual:1.1:1.0'
XG_DK_TMP[owl]='nocturnal:the night is a library:1.0:1.05|scholarly:watches.  takes notes:0.9:1.1|aloof:affection by appointment:0.85:1.15|swivel-happy:the head does the rounds:1.05:1.0|stern:disapproves, fondly:0.9:1.2|mousy-minded:hears crumbs move:1.1:1.0'
XG_DK_TMP[pig]='clever:solves the pantry, twice:1.05:1.1|food-driven:breakfast is a worldview:1.25:1.0|cuddly:a one hundred percent lean rate:1.0:1.2|zoomy:piglet mode, permanent:1.2:0.95|tidy:the wallow?  curated:0.95:1.05|operatic:screams melodically:1.1:1.25'
XG_DK_TMP[axolotl]='smiley:the face is permanent, the joy real:1.0:1.0|placid:regenerates.  relaxes:0.85:0.9|derpy:walks into the bowl.  again:1.05:1.0|gentle:soft in all respects:0.9:0.95|curious:investigates with the face:1.0:1.05|nocturnal:night wiggles:1.0:1.0'

XG_DK_BLD[rabbit]='dainty|cobby|long-bodied'
XG_DK_BLD[hamster]='pocket|round|extra round'
XG_DK_BLD[fox]='lithe|brush-tailed|winter-coated'
XG_DK_BLD[turtle]='low dome|high dome|broad shell'
XG_DK_BLD[hedgehog]='compact|classic|extra quilled'
XG_DK_BLD[glorp]='amorphous|semi-cohesive|confident'
XG_DK_BLD[xeno]='lurker|runner|broad-crested'
XG_DK_BLD[duck]='trim|broad-beamed|deep-keeled'
XG_DK_BLD[frog]='slim|stout|long-legged'
XG_DK_BLD[snake]='slender|stocky|long'
XG_DK_BLD[owl]='slight|round-faced|broad-winged'
XG_DK_BLD[pig]='compact|barrel|long-backed'
XG_DK_BLD[axolotl]='fine-frilled|full-frilled|broad-headed'

# how far the coat may drift from its anchor, and how often the eyes differ
XG_DK_SPAN[rabbit]=0.8; XG_DK_ODD[rabbit]=0.05
XG_DK_SPAN[hamster]=0.7; XG_DK_ODD[hamster]=0.03
XG_DK_SPAN[fox]=0.9; XG_DK_ODD[fox]=0.06
XG_DK_SPAN[turtle]=0.7; XG_DK_ODD[turtle]=0.02
XG_DK_SPAN[hedgehog]=0.7; XG_DK_ODD[hedgehog]=0.04
XG_DK_SPAN[glorp]=1.3; XG_DK_ODD[glorp]=0.5
XG_DK_SPAN[xeno]=0.6; XG_DK_ODD[xeno]=0.0
XG_DK_SPAN[duck]=0.7; XG_DK_ODD[duck]=0.02
XG_DK_SPAN[frog]=0.9; XG_DK_ODD[frog]=0.04
XG_DK_SPAN[snake]=0.8; XG_DK_ODD[snake]=0.03
XG_DK_SPAN[owl]=0.7; XG_DK_ODD[owl]=0.04
XG_DK_SPAN[pig]=0.7; XG_DK_ODD[pig]=0.03
XG_DK_SPAN[axolotl]=0.8; XG_DK_ODD[axolotl]=0.05

# ══════════════════════════════════════════════════════════════════════════
# THE BREEDS · what it was bred as, and what that means for it
# ══════════════════════════════════════════════════════════════════════════
# A colourway alone never said enough.  A breed is the other half: it decides
# how big the animal gets, how long it can expect to live, and -- the part
# that matters most on the card -- WHICH COATS IT CAN ACTUALLY WEAR.  A
# Siamese is not calico.  A Bombay is black, and only black.  A Great Dane
# lives eight years and a Chihuahua sixteen, and now the papers say so.
#
# A row is  name : size : span : coats : patterns : ears : tail
#   size     what it multiplies its species' body by
#   span     years, for THIS breed, before the seed's own ±15% is dealt
#   coats    which of its deck's colourways it carries, or * for all
#   patterns likewise, or *
#   ears     forced, where a breed decides them (a lop is a lop), or - to deal
#   tail     likewise
typeset -gA XG_DK_BREED
XG_DK_BREED[cat]='Domestic Shorthair:1:15:*:*:-:-|Maine Coon:1.22:12.5:brown,black,grey,cream,blue:tabby,plain:-:-|Siamese:0.95:16:cream,lilac,fawn:plain:-:-|Persian:1.06:13:white,cream,blue,black,lilac:plain,calico:-:-|Russian Blue:1:16:blue,grey:plain:-:-|Bengal:1.08:14:ginger,brown,cinnamon:tabby:-:-|British Shorthair:1.1:14:blue,grey,cream,white,black:plain,tabby:-:-|Ragdoll:1.18:13:cream,lilac,blue,white:plain,tux:-:-|Sphynx:0.95:13:cream,grey,lilac,fawn:plain:-:-|Abyssinian:0.95:14:ginger,cinnamon,brown:tabby:-:-|Norwegian Forest:1.2:14:brown,grey,black,white:tabby,tux:-:-|Scottish Fold:1:13:grey,blue,cream,white:plain,tabby:-:-|Turkish Van:1.1:15:white,ginger:tux:-:-|Bombay:1:14:black:void,plain:-:-|Calico Moggy:1.02:15:ginger,white,black,cream:calico:-:-'
XG_DK_BREED[dog]='Labrador Retriever:1.15:12:black,chocolate,golden,cream:plain:floppy:straight|German Shepherd:1.2:11:black,golden,red,grey:sable,patch:pointy:straight|Golden Retriever:1.15:12:golden,cream:plain:floppy:straight|French Bulldog:0.82:11:cream,fawn,grey,white:plain,brindle,patch:pointy:straight|Beagle:0.92:13.5:white,chocolate,black,red:patch:floppy:straight|Poodle:1:14:white,black,chocolate,cream,red,grey:plain:floppy:curly|Dachshund:0.78:14:red,chocolate,black,cream:plain,brindle:floppy:straight|Border Collie:1.05:13:black,white,red,grey:patch,blaze:semi:straight|Siberian Husky:1.12:13:grey,black,white,red:patch,blaze:pointy:curly|Chihuahua:0.7:16:cream,fawn,chocolate,black,white:plain,patch:pointy:curly|Great Dane:1.35:8:fawn,black,grey:plain,brindle,patch:floppy:straight|Shiba Inu:0.95:14:red,cream,black:sable,plain:pointy:curly|Boxer:1.12:10.5:fawn,chocolate,white:brindle,patch:semi:straight|Corgi:0.84:13:red,fawn,black,cream:patch,plain:pointy:straight|Pug:0.76:13:fawn,black,cream:plain:floppy:curly|Rottweiler:1.25:9.5:black:patch,plain:floppy:straight|Whippet:1:13.5:grey,fawn,white,black:patch,brindle,plain:semi:straight|Saint Bernard:1.38:8.5:chocolate,white,red:patch:floppy:straight'
XG_DK_BREED[rabbit]='Netherland Dwarf:0.7:10:*:plain,agouti:up:-|Holland Lop:0.8:9:fawn,cream,chocolate,white:plain,broken:lop:-|Flemish Giant:1.42:7:grey,fawn,white,black:plain,agouti:up:-|Dutch:0.88:9:black,chocolate,grey:dutch:up:-|Mini Rex:0.8:9:brown,black,lilac,white,cream:plain:up:-|Lionhead:0.78:8.5:cream,fawn,white,chocolate:plain,broken:up:-|English Lop:1.12:7.5:fawn,white,brown:broken,plain:lop:-|Californian:1:9:white:points:up:-|Rex:1:8.5:grey,brown,black,lilac:plain,broken:up:-|English Angora:0.95:9:white,fawn,cream,lilac:plain:up:-|Himalayan:0.86:9.5:white,cream:points:up:-|New Zealand:1.15:8:white,brown,black:plain:up:-'
XG_DK_BREED[hamster]='Syrian:1.15:2.6:golden,champagne,cinnamon,black,sable:*:-:-|Winter White Dwarf:0.7:2:white,dove,grey:plain,banded:-:-|Roborovski:0.55:3.2:champagne,white:plain:-:-|Campbell'\''s Dwarf:0.72:2:golden,dove,grey,black:plain,banded,spotted:-:-|Chinese:0.76:2.6:champagne,cinnamon,dove:banded:-:-|Black Bear Syrian:1.16:2.6:black,sable:plain:-:-|Banded Syrian:1.15:2.6:golden,cinnamon,black:banded:-:-|Rex Syrian:1.12:2.5:cinnamon,champagne,golden:roan,plain:-:-|Dominant Spot:1.1:2.4:white,golden,dove:spotted:-:-'
XG_DK_BREED[fox]='Red Fox:1:12:red,amber:mask,plain,socks:-:-|Silver Fox:1:13:silver,shadow:plain,socks:-:-|Cross Fox:1:12:cross,red,amber:cross:-:-|Arctic Fox:0.85:14:arctic,platinum:plain:-:-|Marble Fox:1:13:marble,platinum:marble,mask:-:-|Fennec:0.55:12:amber,platinum,arctic:plain,mask:-:-|Grey Fox:0.92:13:shadow,silver,cross:mask,socks:-:-|Corsac:0.82:13:amber,platinum,marble:plain:-:-|Swift Fox:0.72:13:amber,cross,shadow:mask,socks:-:-'
XG_DK_BREED[turtle]='Red-eared Slider:1:32:forest,olive,moss:striped:-:-|Russian Tortoise:0.85:45:chestnut,olive,amber:plain,hex:-:-|Hermann'\''s Tortoise:0.88:60:amber,olive,chestnut:hex,painted:-:-|Sulcata Tortoise:1.45:70:amber,chestnut,dusk:hex:-:-|Box Turtle:0.82:45:chestnut,amber,forest:painted,spotted:-:-|Painted Turtle:0.85:35:forest,jade,slate:painted,striped:-:-|Leopard Tortoise:1.3:75:amber,chestnut,dusk:spotted,hex:-:-|Musk Turtle:0.62:30:dusk,slate,moss:plain,striped:-:-|Map Turtle:0.8:32:moss,jade,slate:striped,painted:-:-'
XG_DK_BREED[hedgehog]='Salt and Pepper:1:5:salt-pepper:plain,masked:-:-|Cinnamon:1:5:cinnamon,apricot:plain,frosted:-:-|Chocolate:1.02:5:chocolate,charcoal:masked,plain:-:-|Algerian Grey:1:5:grey,salt-pepper:banded,plain:-:-|Apricot:0.98:5:apricot,cream,fawn:frosted,plain:-:-|Pinto:1:5:cream,fawn,chocolate:banded:-:-|Snowflake:0.98:5:cream,salt-pepper:frosted:-:-|Albino:0.96:4.5:cream:plain:-:-'
XG_DK_BREED[glorp]='Common Glorp:1:99:*:*:-:-|Deep-Vent Strain:1.15:140:void,ultraviolet,ion:nebular,ringed:-:-|Solar Strain:0.95:80:solar,plasma,rose:glassy,speckled:-:-|Nursery Strain:0.86:60:mint,ecto,rose:speckled,plain:-:-|Vacuum-Hardened:1.1:160:void,ion,ultraviolet:glassy:-:-|Lantern Glorp:0.92:95:solar,ecto,mint:ringed,glassy:-:-|Cathedral Glorp:1.3:210:ultraviolet,rose,plasma:nebular:-:-|Rill Glorp:0.8:70:ion,mint,ecto:plain,ringed:-:-'
XG_DK_BREED[xeno]='Drone:1:45:obsidian,tar,graphite:ribbed,chitin:-:-|Warrior:1.2:40:obsidian,umbra,bruise:chitin,biomech:-:-|Runner:0.92:35:tar,acid-sheen,graphite:gloss,ribbed:-:-|Praetorian:1.45:80:bruise,void-blue,umbra:biomech,chitin:-:-|Sentinel:1.1:60:void-blue,graphite,obsidian:matte,ribbed:-:-|Carrier:1.3:70:umbra,bone,tar:matte,chitin:-:-|Pale Morph:0.95:50:bone,acid-sheen:gloss,matte:-:-|Queen'\''s Line:1.35:200:bruise,void-blue,obsidian:biomech,gloss:-:-'
XG_DK_BREED[duck]='Pekin:1.15:11:white,snowy:plain:-:-|Rouen:1.2:10:khaki,chocolate,blue-slate:mallard,penciled:-:-|Khaki Campbell:0.95:11:khaki,buff:plain:-:-|Indian Runner:0.92:12:white,buff,chocolate,blue-slate:plain,bibbed:-:-|Cayuga:1.05:11:cayuga:plain,capped:-:-|Call Duck:0.62:10:white,snowy,apricot,khaki:bibbed,mallard:-:-|Swedish Blue:1.08:11:blue-slate:bibbed:-:-|Muscovy:1.3:12:white,chocolate,cayuga:capped,bibbed:-:-|Welsh Harlequin:0.98:11:buff,apricot,white:penciled,mallard:-:-'
XG_DK_BREED[frog]='White'\''s Tree Frog:1.05:16:leaf,mint,teal:plain,belly:-:-|Red-eyed Tree Frog:0.72:8:leaf,mint,cobalt:striped,belly:-:-|Pacman Frog:1.25:12:earth,moss,golden,tomato:spotted,striped:-:-|Dart Frog:0.45:10:cobalt,golden,tomato,mint:darted,spotted:-:-|American Bullfrog:1.35:9:moss,earth,leaf:spotted,plain:-:-|Tomato Frog:0.95:10:tomato,golden:plain,belly:-:-|Gray Tree Frog:0.68:8:moss,earth,mint:spotted,striped:-:-|African Bullfrog:1.42:22:moss,earth,leaf:plain,striped:-:-'
XG_DK_BREED[snake]='Corn Snake:1:20:corn,albino,lavender,sand:banded,speckled,plain:-:-|Ball Python:1.15:28:midnight,copper,sand:banded,speckled:-:-|California Kingsnake:0.95:22:midnight,albino,sand:banded,striped:-:-|Green Tree Python:0.98:20:emerald,jade:plain,speckled:-:-|Milk Snake:0.9:20:corn,copper,midnight:banded:-:-|Boa Constrictor:1.45:28:copper,sand,midnight:diamond,banded:-:-|Rosy Boa:0.78:25:sand,copper,lavender:striped:-:-|Garter Snake:0.7:10:emerald,jade,midnight:striped:-:-|Hognose:0.72:18:sand,corn,albino:diamond,speckled:-:-'
XG_DK_BREED[owl]='Barn Owl:1:20:barn-cream,snowy,moon-pale:heart-faced,speckled:-:-|Tawny Owl:1.05:21:tawny,umber,rust:barred,speckled:-:-|Snowy Owl:1.25:25:snowy,moon-pale:speckled,plain:-:-|Great Horned Owl:1.3:22:umber,tawny,rust:barred,hooded:-:-|Little Owl:0.6:15:grey,tawny,smoke:speckled:-:-|Barred Owl:1.12:20:grey,smoke,umber:barred:-:-|Screech Owl:0.62:14:rust,grey,smoke:barred,speckled:-:-|Long-eared Owl:0.95:18:tawny,umber,smoke:barred,hooded:-:-'
XG_DK_BREED[pig]='Pot-bellied Pig:0.88:16:black,grey,pink,rose:spotted,plain,belted:-:-|Kunekune:0.95:18:ginger,cream,black,sandy:spotted,belted:-:-|Berkshire:1.2:14:black:belted,plain:-:-|Tamworth:1.15:14:ginger,chestnut:plain:-:-|Gloucestershire Old Spot:1.25:14:pink,cream,rose:spotted:-:-|Hampshire:1.22:13:black,pink:belted:-:-|Large White:1.35:13:pink,cream:plain,mud-streaked:-:-|Saddleback:1.25:14:black,pink:saddleback:-:-|Mangalitsa:1.18:15:sandy,cream,chestnut:plain,mud-streaked:-:-'
XG_DK_BREED[axolotl]='Leucistic:1:13:leucistic,peach:plain,dalmatian:-:-|Wild Type:1:14:wild,copper:mottled,speckled:-:-|Golden Albino:0.98:13:golden,peach:plain,glow:-:-|Melanoid:1.02:14:melanoid:plain,mottled:-:-|Copper:0.98:13:copper,wild:speckled,mottled:-:-|Lavender:1:12:lavender,pearl:mottled,speckled:-:-|Piebald:1:13:leucistic,pearl:dalmatian:-:-|GFP:1:12:pearl,golden,leucistic:glow:-:-|Firefly:0.96:11:melanoid,golden:glow,dalmatian:-:-'

# ── the breed in hand · split once per breed, not once per deal ───────────
typeset -ga XK_BRN XK_BRSZ XK_BRSP XK_BRCW XK_BRPT XK_BREAR XK_BRTAIL
typeset -g  XB_NAME='' XB_CW='*' XB_PAT='*' XB_EAR='-' XB_TAIL='-' XB_KEY=''
typeset -gF XB_SIZE=1.0 XB_SPAN=15.0
typeset -gi XB_I=0
typeset -ga XB_ALLOW XB_CWIX XB_PATIX

xg_allow_ix() {   # xg_allow_ix ALLOWED "name|name|…" → XB_ALLOW · which are allowed
  # IT IS XB_ALLOW AND NOT XB_ALLOW.  XB_ALLOW is the certificate's inner left edge,
  # and an array landing on it silently moved every word on the card.
  # THE CALLER MUST JOIN WITH [@].  Under KSH_ARRAYS ${(j:|:)arr} joins the
  # FIRST ELEMENT and nothing else, so a list built without it arrives here as
  # one name, matches nothing, and every breed silently gets the whole deck.
  local allowed="$1"; local -a all; all=(${(s:|:)2})
  local -i i n=${#all[@]}
  XB_ALLOW=()
  if [[ "$allowed" == '*' ]]; then for (( i=0; i<n; i++ )); do XB_ALLOW+=($i); done; return 0; fi
  local -a want; want=(${(s:,:)allowed}); local w
  for (( i=0; i<n; i++ )); do
    for w in ${want[@]}; do [[ "${all[$i]}" == "$w" ]] && { XB_ALLOW+=($i); break } done
  done
  # A BREED THAT NAMES NOTHING THIS DECK HAS gets the whole deck rather than
  # nothing at all: a missing name is a bug in a table, not a bald animal.
  (( ${#XB_ALLOW[@]} )) || for (( i=0; i<n; i++ )); do XB_ALLOW+=($i); done
  return 0
}

xg_breed_split() {   # xg_breed_split SPECIES — its breeds, in hand
  local sp="$1" f; local -a p
  XK_BRN=(); XK_BRSZ=(); XK_BRSP=(); XK_BRCW=(); XK_BRPT=(); XK_BREAR=(); XK_BRTAIL=()
  for f in ${(s:|:)XG_DK_BREED[$sp]}; do
    p=(${(s,:,)f})
    XK_BRN+=("${p[0]}"); XK_BRSZ+=(${p[1]}); XK_BRSP+=(${p[2]})
    XK_BRCW+=("${p[3]}"); XK_BRPT+=("${p[4]}"); XK_BREAR+=("${p[5]}"); XK_BRTAIL+=("${p[6]}")
  done
  return 0
}

xg_breed_ix() {   # xg_breed_ix SPECIES NAME → REPLY · that breed's place, or -1
  local sp="$1" nm="$2"; local -i i
  xg_deck "$sp"
  for (( i=0; i<${#XK_BRN[@]}; i++ )); do [[ "${XK_BRN[$i]}" == "$nm" ]] && { REPLY=$i; return 0 } done
  REPLY=-1; return 1
}

xg_breed_pick() {   # xg_breed_pick SEED SPECIES [NAME] — XB_* · what it was bred as
  # A NAME WINS OVER A SEED.  An animal already signed for carries its breed
  # in the save and keeps it; only an arrival has one dealt.
  local sp="$2" nm="${3:-}"; local -i i=-1
  xg_deck "$sp"
  # A STAR MEANS NO BREED AT ALL · what a save older than breeds was dealt, so
  # an animal you already know does not change colour the day this lands.
  if [[ "$nm" == '*' ]]; then
    XB_I=-1; XB_NAME=''; XB_SIZE=1.0; XB_CW='*'; XB_PAT='*'; XB_EAR='-'; XB_TAIL='-'
    xg_sp_i "$sp"; XB_SPAN=${XG_SP_YEARS[$REPLY]}
    return 0
  fi
  (( ${#XK_BRN[@]} )) || { XB_NAME=''; XB_SIZE=1.0; XB_SPAN=${XG_SP_YEARS[0]}; XB_CW='*'; XB_PAT='*'
                           XB_EAR='-'; XB_TAIL='-'; XB_I=0; XB_KEY="$sp."; XB_CWIX=(); XB_PATIX=(); return 0 }
  [[ -n "$nm" ]] && { xg_breed_ix "$sp" "$nm" && i=$REPLY }
  (( i < 0 )) && { xg_gh $1 71; i=$(( XG_H % ${#XK_BRN[@]} )) }
  XB_I=$i
  XB_NAME="${XK_BRN[$i]}"; XB_SIZE=${XK_BRSZ[$i]}; XB_SPAN=${XK_BRSP[$i]}
  XB_CW="${XK_BRCW[$i]}"; XB_PAT="${XK_BRPT[$i]}"; XB_EAR="${XK_BREAR[$i]}"; XB_TAIL="${XK_BRTAIL[$i]}"
  return 0
}

typeset -g XG_FORCE_CW='' XG_FORCE_PAT=''
xg_breed_sets() {   # the coats and patterns THIS breed may wear · XB_CWIX/XB_PATIX
  # Kept per breed, because a litter of four asks the same question forty times.
  #
  # AND A COAT ALREADY ON THE ANIMAL IS A SET OF ONE.  A save records what it
  # is wearing in WORDS as well as in colours, and the words outlive a lost
  # palette line.  Narrowing the allowed set to exactly those words makes the
  # dealer land on them -- one candidate, one outcome -- so an animal rebuilt
  # from a damaged file comes back in its own coat instead of the one its
  # seed would deal against today's deck.  See xg_wear.
  local sp="$1" cwn="$2" ptn="$3"
  local key="$1.$XB_I.${XG_FORCE_CW}.${XG_FORCE_PAT}"
  [[ "$key" == "$XB_KEY" ]] && return 0
  xg_allow_ix "${XG_FORCE_CW:-$XB_CW}"  "$cwn"; XB_CWIX=("${XB_ALLOW[@]}")
  xg_allow_ix "${XG_FORCE_PAT:-$XB_PAT}" "$ptn"; XB_PATIX=("${XB_ALLOW[@]}")
  XB_KEY="$key"
  return 0
}

xg_breed_infer() {   # xg_breed_infer SPECIES COLORWAY PATTERN SEED → REPLY
  # AN ANIMAL FROM BEFORE BREEDS still has to be something.  Rather than deal
  # it one at random -- which would put a calico coat on a Siamese -- this
  # asks which breeds COULD have produced the coat it is already wearing, and
  # picks among those by the same seed that made it.
  local sp="$1" cw="$2" pt="$3"; local -i sd=$4 i
  local anchor="${cw##* }"
  xg_deck "$sp"
  local -a fit; fit=()
  for (( i=0; i<${#XK_BRN[@]}; i++ )); do
    [[ "${XK_BRCW[$i]}" == '*' || ",${XK_BRCW[$i]}," == *",$anchor,"* ]] || continue
    [[ "${XK_BRPT[$i]}" == '*' || ",${XK_BRPT[$i]}," == *",$pt,"*     ]] || continue
    fit+=($i)
  done
  (( ${#fit[@]} )) || { REPLY="${XK_BRN[0]:-}"; return 0 }
  xg_gh $sd 71; REPLY="${XK_BRN[${fit[$(( XG_H%${#fit[@]} ))]}]}"
  return 0
}

xg_span_years() {   # xg_span_years SEED SPECIES [BREED] → REPLY years, this breed's
  xg_breed_pick $1 "$2" "${3:-}"
  REPLY=$XB_SPAN
  return 0
}

# ── the deck in hand · one species' tables, split once and kept ───────────
#    Fifteen species would be sixty global arrays if each kept its own.  They
#    keep one string per axis instead, and this splits whichever is being
#    dealt.  A litter of four is one split, not four.
typeset -g  XG_DKK=''
typeset -ga XK_CWN XK_CWR XK_CWG XK_CWB XK_PAT XK_EYN XK_EYR XK_EYG XK_EYB
typeset -ga XK_TN XK_TD XK_TF XK_TB XK_BLD
typeset -gF XK_SPAN XK_ODD
xg_deck() {   # xg_deck SPECIES — its deck, in hand
  [[ "$XG_DKK" == "$1" ]] && return 0
  local sp="$1" f; local -a p
  # EVERY SPECIES HAS BREEDS, including the two that keep their own hand-dealt
  # colour tables; only the wider intake keeps its colourways here as well.
  xg_breed_split "$sp"; XB_KEY=''
  [[ -n "${XG_DK_CW[$sp]:-}" ]] || { XG_DKK="$sp"; return 0 }
  XK_CWN=(); XK_CWR=(); XK_CWG=(); XK_CWB=()
  for f in ${(s:|:)XG_DK_CW[$sp]}; do
    XK_CWN+=("${f%%:*}"); p=(${(s:,:)f#*:})
    XK_CWR+=(${p[0]}); XK_CWG+=(${p[1]}); XK_CWB+=(${p[2]})
  done
  XK_PAT=(${(s:|:)XG_DK_PAT[$sp]})
  XK_EYN=(${(s:|:)XG_DK_EYN[$sp]})
  XK_EYR=(); XK_EYG=(); XK_EYB=()
  for f in ${(s:|:)XG_DK_EYC[$sp]}; do
    p=(${(s:,:)f}); XK_EYR+=(${p[0]}); XK_EYG+=(${p[1]}); XK_EYB+=(${p[2]})
  done
  XK_TN=(); XK_TD=(); XK_TF=(); XK_TB=()
  for f in ${(s:|:)XG_DK_TMP[$sp]}; do
    p=(${(s,:,)f}); XK_TN+=("${p[0]}"); XK_TD+=("${p[1]}"); XK_TF+=(${p[2]}); XK_TB+=(${p[3]})
  done
  XK_BLD=(${(s:|:)XG_DK_BLD[$sp]})
  XK_SPAN=${XG_DK_SPAN[$sp]}; XK_ODD=${XG_DK_ODD[$sp]}
  xg_breed_split "$sp"; XB_KEY=''
  XG_DKK="$sp"
  return 0
}

# ── mixing paint · the original quantizes every mixed colour to six bits ──
#    (it is the same glass everywhere in this cabinet) and a colour that is
#    not quantized here would sit one step off the one the deck intended.
typeset -gi XQ_R XQ_G XQ_B
xg_q() {   # xg_q R G B → XQ_* · clamped, and snapped to the glass
  local -i i; local -a v; v=($1 $2 $3)
  for i in 0 1 2; do
    (( v[i] < 0 )) && v[i]=0
    if (( v[i] > 255 )); then v[i]=252; else v[i]=$(( v[i] & 0xFC )); fi
  done
  XQ_R=${v[0]}; XQ_G=${v[1]}; XQ_B=${v[2]}
}
xg_mixq() {   # xg_mixq aR aG aB bR bG bB T → XQ_* · A toward B, then snapped
  local -F t=$7
  (( t < 0.0 )) && t=0.0; (( t > 1.0 )) && t=1.0
  xg_q $(( int($1+($4-$1)*t) )) $(( int($2+($5-$2)*t) )) $(( int($3+($6-$3)*t) ))
}

xg_deal_generic() {   # xg_deal_generic SEED SPECIES — the wider intake's one dealer
  # The original's _deal_generic, brought across: one anchor colourway drifts
  # continuously per seed, a pattern and a jitter, an eye blend that is
  # sometimes two eyes that do not match, a build, and a temperament made of
  # two archetypes weighed against each other.  Same seed, same animal,
  # forever.  What each species adds to that is at the foot of the function.
  local -i seed=$1 ci pi ei ej ej2 ti tj odd bR bG bB dR dG dB wR wG wB eR eG eB
  local -i e2R e2G e2B oR oG oB pR pG pB nn
  local -F et w
  local sp="$2"
  xg_deck "$sp"
  xg_breed_sets "$sp" "${(j:|:)XK_CWN[@]}" "${(j:|:)XK_PAT[@]}"
  nn=${#XB_CWIX[@]}; xg_gh $seed 4; ci=${XB_CWIX[$(( XG_H%nn ))]}
  xg_vary_coat ${XK_CWR[$ci]} ${XK_CWG[$ci]} ${XK_CWB[$ci]} $seed $XK_SPAN
  bR=$XG_VR; bG=$XG_VG; bB=$XG_VB
  nn=${#XB_PATIX[@]}; xg_gh $seed 9; pi=${XB_PATIX[$(( XG_H%nn ))]}; XG[pattern]="${XK_PAT[$pi]}"
  xg_gh $seed 33; XG[pj]=$(( XG_H%9973 ))
  # ── the eyes · a blend, and now and then two that do not match ──
  nn=${#XK_EYN[@]}; xg_gh $seed 26; ei=$(( XG_H%nn ))
  if (( nn < 2 )); then ej=$ei; else xg_gh $seed 27; ej=$(( (ei+1+XG_H%(nn-1))%nn )); fi
  xg_gf $seed 28; et=$XG_F
  xg_mixq ${XK_EYR[$ei]} ${XK_EYG[$ei]} ${XK_EYB[$ei]} ${XK_EYR[$ej]} ${XK_EYG[$ej]} ${XK_EYB[$ej]} $(( et*0.5 ))
  eR=$XQ_R; eG=$XQ_G; eB=$XQ_B
  if (( et < 0.5 )); then XG[eyes]="${XK_EYN[$ei]}"; else XG[eyes]="${XK_EYN[$ei]}-${XK_EYN[$ej]}"; fi
  xg_gf $seed 29; odd=$(( XG_F < XK_ODD ))
  e2R=$eR; e2G=$eG; e2B=$eB
  if (( odd )); then
    ej2=$(( (ei+2)%nn )); XG[eyes]="${XK_EYN[$ei]} / ${XK_EYN[$ej2]} · odd"
    e2R=${XK_EYR[$ej2]}; e2G=${XK_EYG[$ej2]}; e2B=${XK_EYB[$ej2]}
  fi
  # ── the temperament · two archetypes, one leaning on the other ──
  nn=${#XK_TN[@]}; xg_gh $seed 11; ti=$(( XG_H%nn )); xg_gh $seed 12; tj=$(( (ti+1+XG_H%(nn-1))%nn ))
  xg_gf $seed 13; w=$(( 0.62+0.38*XG_F ))
  XG[tname]="${XK_TN[$ti]}"
  if (( w > 0.82 )); then XG[temper]="${XK_TD[$ti]}"
  else xg_an "${XK_TN[$tj]}"; XG[temper]="${XK_TD[$ti]} · $REPLY ${XK_TN[$tj]} streak"; fi
  xg_gf $seed 14; xg_m2 $(( int((XK_TF[ti]*w+XK_TF[tj]*(1.0-w)+(XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[hunger_m]="$REPLY"
  xg_gf $seed 18; xg_m2 $(( int((XK_TB[ti]*w+XK_TB[tj]*(1.0-w)+(XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[social_m]="$REPLY"
  nn=${#XK_BLD[@]}; xg_gh $seed 21; XG[build]="${XK_BLD[$(( XG_H%nn ))]}"
  XG[ear_s]=1.0; XG[tail_n]=1.0; XG[ears]=up; XG[ear_l]=1.0
  XG[colorway]="${XG_VMOD}${XK_CWN[$ci]}"
  # A PATTERN IS PART OF THE NAME unless it is plain -- and the organism has
  # no plain: every one of its five finishes is worth saying out loud, so
  # this asks the pattern's name, not its place in the list.
  if [[ "${XG[pattern]}" == plain ]]; then XG[label]="${XG[colorway]}"
  else XG[label]="${XG[colorway]} ${XG[pattern]}"; fi
  # ── the palette · the coat, a shadow of it, a gloss on it, and the face ──
  dR=$(( int(bR*0.62) )); dG=$(( int(bG*0.62) )); dB=$(( int(bB*0.62) ))
  xg_mixq $bR $bG $bB 250 246 240 0.78; wR=$XQ_R; wG=$XQ_G; wB=$XQ_B
  oR=206; oG=160; oB=110; pR=236; pG=152; pB=160
  # ── and what each one keeps for itself · bills, trotters, gills, gloss ──
  case "$sp" in
    turtle)   xg_mixq 150 168 96 $bR $bG $bB 0.35; oR=$XQ_R; oG=$XQ_G; oB=$XQ_B ;;
    hedgehog) oR=198; oG=150; oB=120 ;;                      # little pink-tan legs
    glorp)    xg_mixq 255 255 255 $bG $bB $bR 0.75; oR=$XQ_R; oG=$XQ_G; oB=$XQ_B
              xg_mixq $bR $bG $bB 255 255 255 0.55; wR=$XQ_R; wG=$XQ_G; wB=$XQ_B ;;
    xeno)     xg_mixq $bR $bG $bB 218 232 244 0.72; wR=$XQ_R; wG=$XQ_G; wB=$XQ_B
              pR=188; pG=92; pB=104
              dR=$(( int(bR*0.55) )); dG=$(( int(bG*0.55) )); dB=$(( int(bB*0.55) ))
              XG[eyes]='none · it sees you anyway' ;;
    duck)     oR=232; oG=158; oB=62 ;;                       # bill and feet
    frog)     xg_mixq $bR $bG $bB 250 248 236 0.66; wR=$XQ_R; wG=$XQ_G; wB=$XQ_B ;;
    snake)    pR=222; pG=96;  pB=104 ;;                      # the tongue
    owl)      oR=222; oG=176; oB=96 ;;                       # beak and talons
    pig)      pR=238; pG=158; pB=150; oR=150; oG=110; oB=90 ;;   # snout · trotters
    axolotl)  pR=240; pG=128; pB=148
              xg_mixq $bR $bG $bB 250 246 244 0.55; wR=$XQ_R; wG=$XQ_G; wB=$XQ_B ;;
  esac
  # 0 · b · d · w · o · e · E · k · s · p · n · x
  XG_PR=(0 $bR $dR $wR $oR $eR $e2R 26 255 $pR 48 204)
  XG_PG=(0 $bG $dG $wG $oG $eG $e2G 22 255 $pG 40 200)
  XG_PB=(0 $bB $dB $wB $oB $eB $e2B 32 255 $pB 52 226)
  return 0
}

xg_deal_rabbit() {   # xg_deal_rabbit SEED — the rabbit keeps its own deck
  # Its ears are the whole silhouette, so they are genetic (lop or up) and
  # they have a length; and ruby eyes ride the pale coats, mostly.
  local -i seed=$1 ci pi ei ej ej2 ti tj odd bR bG bB dR dG dB wR wG wB eR eG eB
  local -i e2R e2G e2B
  local -F et w el
  local ears
  xg_deck rabbit
  xg_breed_sets rabbit "${(j:|:)XK_CWN[@]}" "${(j:|:)XK_PAT[@]}"
  xg_gh $seed 4; ci=${XB_CWIX[$(( XG_H%${#XB_CWIX[@]} ))]}
  xg_vary_coat ${XK_CWR[$ci]} ${XK_CWG[$ci]} ${XK_CWB[$ci]} $seed 0.8
  bR=$XG_VR; bG=$XG_VG; bB=$XG_VB
  xg_gh $seed 9; pi=${XB_PATIX[$(( XG_H%${#XB_PATIX[@]} ))]}; XG[pattern]="${XK_PAT[$pi]}"
  xg_gh $seed 33; XG[pj]=$(( XG_H%9973 ))
  if [[ "$XB_EAR" != '-' ]]; then ears="$XB_EAR"
  else xg_gf $seed 15; if (( XG_F < 0.3 )); then ears=lop; else ears=up; fi; fi
  xg_gf $seed 16; el=$(( int((0.85+0.3*XG_F)*100.0+0.5)/100.0 ))
  XG[ears]="$ears"; XG[ear_l]=$el
  if (( el > 1.0 )); then XG[build]="$ears ears · tall"; else XG[build]="$ears ears · tidy"; fi
  xg_gh $seed 26; ei=$(( XG_H%${#XK_EYN[@]} ))
  xg_gf $seed 30
  [[ "${XK_EYN[$ei]}" == ruby ]] && (( bR+bG+bB < 540 )) && (( XG_F < 0.8 )) && ei=0
  xg_gh $seed 27; ej=$(( (ei+1+XG_H%(${#XK_EYN[@]}-1))%${#XK_EYN[@]} ))
  xg_gf $seed 28; et=$XG_F
  xg_mixq ${XK_EYR[$ei]} ${XK_EYG[$ei]} ${XK_EYB[$ei]} ${XK_EYR[$ej]} ${XK_EYG[$ej]} ${XK_EYB[$ej]} $(( et*0.5 ))
  eR=$XQ_R; eG=$XQ_G; eB=$XQ_B; e2R=$eR; e2G=$eG; e2B=$eB
  if (( et < 0.5 )); then XG[eyes]="${XK_EYN[$ei]}"; else XG[eyes]="${XK_EYN[$ei]}-${XK_EYN[$ej]}"; fi
  xg_gf $seed 29; odd=$(( XG_F < 0.05 ))
  if (( odd )); then
    ej2=$(( (ei+2)%${#XK_EYN[@]} )); XG[eyes]="${XK_EYN[$ei]} / ${XK_EYN[$ej2]} · odd"
    e2R=${XK_EYR[$ej2]}; e2G=${XK_EYG[$ej2]}; e2B=${XK_EYB[$ej2]}
  fi
  xg_gh $seed 11; ti=$(( XG_H%${#XK_TN[@]} )); xg_gh $seed 12; tj=$(( (ti+1+XG_H%(${#XK_TN[@]}-1))%${#XK_TN[@]} ))
  xg_gf $seed 13; w=$(( 0.62+0.38*XG_F ))
  XG[tname]="${XK_TN[$ti]}"
  if (( w > 0.82 )); then XG[temper]="${XK_TD[$ti]}"
  else xg_an "${XK_TN[$tj]}"; XG[temper]="${XK_TD[$ti]} · $REPLY ${XK_TN[$tj]} streak"; fi
  xg_gf $seed 14; xg_m2 $(( int((XK_TF[ti]*w+XK_TF[tj]*(1.0-w)+(XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[hunger_m]="$REPLY"
  xg_gf $seed 18; xg_m2 $(( int((XK_TB[ti]*w+XK_TB[tj]*(1.0-w)+(XG_F-0.5)*0.08)*100.0+0.5)/100.0 )); XG[social_m]="$REPLY"
  XG[colorway]="${XG_VMOD}${XK_CWN[$ci]}"
  if [[ "${XG[pattern]}" == plain ]]; then XG[label]="${XG[colorway]}"
  else XG[label]="${XG[colorway]} ${XG[pattern]}"; fi
  XG[ear_s]=0.85; XG[tail_n]=1.0
  dR=$(( int(bR*0.64) )); dG=$(( int(bG*0.64) )); dB=$(( int(bB*0.64) ))
  if [[ "${XK_CWN[$ci]}" == white ]]; then wR=246; wG=242; wB=236
  else xg_mixq $bR $bG $bB 250 246 240 0.8; wR=$XQ_R; wG=$XQ_G; wB=$XQ_B; fi
  # 0 · b · d · w · o · e · E · k · s · p · n · x
  XG_PR=(0 $bR $dR $wR 206 $eR $e2R 26 255 238 196 204)
  XG_PG=(0 $bG $dG $wG 148 $eG $e2G 22 255 158 120 200)
  XG_PB=(0 $bB $dB $wB  92 $eB $e2B 30 255 168 130 226)
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE WIDER INTAKE · their bodies · translated from the original whole and
# checked against it cell for cell, every pattern, every pose, every eye
# ══════════════════════════════════════════════════════════════════════════
xg_tabby() {
  local -F seed=${1:-0.0}
  local -F thr=${2:-0.92}
  local -F v
  local -i x y
  for (( y=int(0); y<int(XG_XPH); y++ )); do
    for (( x=int(0); x<int(XG_XPW); x++ )); do
      if (( XG_XPM[y*XG_XPW+x]==1 )); then
        v=$(( sin(y*0.95+x*0.22+seed)+0.4*sin(x*0.9+seed*2.0) ))
        if (( v>thr )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      fi
    done
  done
  return 0
}

xg_rabbit_ears() {   # The whole silhouette lives here.  kind is genetic (up or lop);
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local mode="${3:-up}"
  local -i _mode=0
  [[ "$mode" == 'back' ]] && _mode=1
  local kind="${4:-up}"
  local -i _kind=0
  [[ "$kind" == 'lop' ]] && _kind=1
  local -F s=${5:-1.0}
  local -F el=${6:-1.0}
  local -F ex x0
  if (( _kind==1 )); then
    x0=$(( hx+-1.0*5.2*s ))
    xg_disk $(( x0 )) $(( hy+1.2*s )) $(( 1.6*s )) $(( 4.4*s )) 1
    xg_disk $(( x0 )) $(( hy+2.0*s )) $(( 0.8*s )) $(( 2.6*s )) 9 "1 2 4"
    x0=$(( hx+1.0*5.2*s ))
    xg_disk $(( x0 )) $(( hy+1.2*s )) $(( 1.6*s )) $(( 4.4*s )) 1
    xg_disk $(( x0 )) $(( hy+2.0*s )) $(( 0.8*s )) $(( 2.6*s )) 9 "1 2 4"
    return 0
  fi
  if (( _mode==1 )); then
    xg_seg $(( hx+-1.0*2.0*s )) $(( hy-3.0*s )) $(( hx+-1.0*5.2*s )) $(( hy-7.6*s*el )) $(( 1.6*s )) 1
    xg_seg $(( hx+1.0*2.0*s )) $(( hy-3.0*s )) $(( hx+1.0*5.2*s )) $(( hy-7.6*s*el )) $(( 1.6*s )) 1
    return 0
  fi
  ex=$(( hx+-1.0*3.0*s ))
  xg_disk $(( ex )) $(( hy-7.4*s*el )) $(( 1.7*s )) $(( 5.2*s*el )) 1
  xg_disk $(( ex )) $(( hy-7.0*s*el )) $(( 0.8*s )) $(( 3.4*s*el )) 9 "1 2 4"
  ex=$(( hx+1.0*3.0*s ))
  xg_disk $(( ex )) $(( hy-7.4*s*el )) $(( 1.7*s )) $(( 5.2*s*el )) 1
  xg_disk $(( ex )) $(( hy-7.0*s*el )) $(( 0.8*s )) $(( 3.4*s*el )) 9 "1 2 4"
  return 0
}

xg_rabbit_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'agouti' ]] && _pattern=1
  [[ "$pattern" == 'broken' ]] && _pattern=2
  [[ "$pattern" == 'dutch' ]] && _pattern=3
  [[ "$pattern" == 'points' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y yy
  if (( _pattern==3 )); then
    xg_disk $(( hx )) $(( hy+5.4+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(7.0-5.4) )) $(( 4.6+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(5.6-4.6) )) $(( 5.2 )) 3 "1 2"
    for (( yy=int(int(hy-4.0)); yy<int(int(hy+2.0)); yy++ )); do
      if (( ((int(hx)>=0&&int(hx)<XG_XPW&&yy>=0&&yy<XG_XPH?XG_XPM[yy*XG_XPW+int(hx)]:0)==1||(int(hx)>=0&&int(hx)<XG_XPW&&yy>=0&&yy<XG_XPH?XG_XPM[yy*XG_XPW+int(hx)]:0)==2) )); then
        xg_set $(( int(int(hx)) )) $(( int(yy) )) 3
      fi
    done
  elif (( _pattern==2 )); then
    xg_disk $(( hx+2.5+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(5.0-2.5) )) $(( hy+8.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(11.0-8.0) )) $(( 2.6+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(4.2-2.6) )) $(( 2.8 )) 2 "1"
    xg_disk $(( hx-(3.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(5.5-3.0)) )) $(( hy+10.0+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(13.0-10.0) )) $(( 3.2 )) $(( 2.6 )) 2 "1"
    xg_disk $(( hx+1.0+((int(pj)*48271+int(6.0)*30203+11213)%10007)/10007.0*(3.0-1.0) )) $(( hy-(2.0+((int(pj)*48271+int(7.0)*30203+11213)%10007)/10007.0*(4.0-2.0)) )) $(( 2.2 )) $(( 1.8 )) 2 "1"
  elif (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&(y<hy-4.0||abs(x-hx)>4.8&&y<hy+4.0) )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==1 )); then
    xg_tabby $(( pj*0.41 )) $(( 1.02+((int(pj)*48271+int(8.0)*30203+11213)%10007)/10007.0*(1.2-1.02) ))
  fi
  return 0
}

xg_rabbit_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  [[ "$eyes" == 'narrow' ]] && _eyes=2
  [[ "$eyes" == 'open' ]] && _eyes=3
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-3.6*s ))
  exr=$(( hx+3.6*s ))
  ey=$(( hy-0.4*s ))
  if (( _eyes==3 )); then
    xg_disk $(( exl )) $(( ey )) $(( 1.4*s )) $(( 1.3*s )) 5 "1 2 3 4"
    xg_disk $(( exl )) $(( ey )) $(( 0.7*s )) $(( 0.7*s )) 7 "5 6"
    xg_disk $(( exr )) $(( ey )) $(( 1.4*s )) $(( 1.3*s )) 6 "1 2 3 4"
    xg_disk $(( exr )) $(( ey )) $(( 0.7*s )) $(( 0.7*s )) 7 "5 6"
    xg_set $(( int(int(exl+1.0)) )) $(( int(int(ey-1.0)) )) 8
    xg_set $(( int(int(exr+1.0)) )) $(( int(int(ey-1.0)) )) 8
  elif (( _eyes==1 )); then
    xg_set $(( int(int(exl-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exl)) )) $(( int(int(ey+1.0)) )) 7
    xg_set $(( int(int(exl+1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr)) )) $(( int(int(ey+1.0)) )) 7
    xg_set $(( int(int(exr+1.0)) )) $(( int(int(ey)) )) 7
  elif (( _eyes==2 )); then
    xg_set $(( int(int(exl-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exl)) )) $(( int(int(ey)) )) 5
    xg_set $(( int(int(exl+1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr)) )) $(( int(int(ey)) )) 6
    xg_set $(( int(int(exr+1.0)) )) $(( int(int(ey)) )) 7
  fi
  xg_disk $(( hx )) $(( hy+2.6*s )) $(( 2.6*s )) $(( 1.9*s )) 3 "1 2 3 4"
  xg_tri $(( hx-1.0 )) $(( hy+1.6*s )) $(( hx+1.0 )) $(( hy+1.6*s )) $(( hx )) $(( hy+2.6*s )) 10 "1 2 3 4 3"
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+3.4*s)) )) 7
    xg_set $(( int(int(hx)) )) $(( int(int(hy+4.0*s)) )) 7
  else
    xg_set $(( int(int(hx)) )) $(( int(int(hy+3.2*s)) )) 2
    xg_set $(( int(int(hx-1.0)) )) $(( int(int(hy+3.8*s)) )) 2
    xg_set $(( int(int(hx+1.0)) )) $(( int(int(hy+3.8*s)) )) 2
  fi
  return 0
}

xg_rabbit_sit() {
  local eyes="${1:-open}"
  local ears="${2:-up}"
  local mouth="${3:-}"
  local -F w=${4:-36.0}
  local -F h=${5:-31.0}
  local -F el hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=$(( 13.0 ))
  el=$(( ${XG[ear_l]:-1.0} ))
  xg_disk $(( hx )) $(( hy+11.5 )) $(( 8.6 )) $(( 6.2 )) 1
  xg_disk $(( hx+8.4 )) $(( hy+8.6 )) $(( 2.4 )) $(( 2.6 )) 3
  xg_disk $(( hx )) $(( hy+6.6 )) $(( 5.6 )) $(( 4.4 )) 1
  xg_rabbit_ears $(( hx )) $(( hy )) "$ears" "${XG[ears]:-up}" 1.0 $(( el ))
  xg_disk $(( hx )) $(( hy )) $(( 6.0 )) $(( 5.2 )) 1
  xg_rabbit_dress $(( hx )) $(( hy ))
  xg_rabbit_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_disk $(( hx-2.6 )) $(( hy+16.2 )) $(( 2.2 )) $(( 1.3 )) 1
  xg_disk $(( hx+2.6 )) $(( hy+16.2 )) $(( 2.2 )) $(( 1.3 )) 1
  return 0
}

xg_bunny_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.5 ))
  hy=$(( 9.6 ))
  xg_disk $(( hx )) $(( hy+7.2 )) $(( 6.0 )) $(( 4.4 )) 1
  xg_disk $(( hx+5.8 )) $(( hy+5.6 )) $(( 1.8 )) $(( 1.9 )) 3
  xg_rabbit_ears $(( hx )) $(( hy )) 'up' "${XG[ears]:-up}" $(( 0.8 )) $(( ${XG[ear_l]:-1.0} ))
  xg_disk $(( hx )) $(( hy )) $(( 5.0 )) $(( 4.4 )) 1
  xg_rabbit_dress $(( hx )) $(( hy ))
  xg_rabbit_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.85 ))
  xg_disk $(( hx-2.0 )) $(( hy+10.8 )) $(( 1.8 )) $(( 1.1 )) 1
  xg_disk $(( hx+2.0 )) $(( hy+10.8 )) $(( 1.8 )) $(( 1.1 )) 1
  return 0
}

xg_rabbit_loaf() {
  local -F w=${1:-34.0}
  local -F h=${2:-19.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 11.0 ))
  xg_disk $(( cx )) $(( cy+2.0 )) $(( 10.2 )) $(( 5.4 )) 1
  xg_disk $(( cx-7.0 )) $(( cy-0.5 )) $(( 4.4 )) $(( 3.9 )) 1
  xg_seg $(( cx-7.0 )) $(( cy-3.6 )) $(( cx-1.0 )) $(( cy-5.2 )) $(( 1.6 )) 1
  xg_seg $(( cx-5.2 )) $(( cy-3.0 )) $(( cx+0.8 )) $(( cy-4.4 )) $(( 1.1 )) 2
  xg_rabbit_dress $(( cx-7.0 )) $(( cy-0.5 ))
  xg_rabbit_face $(( cx-7.0 )) $(( cy-0.5 )) 'narrow' '' $(( 0.8 ))
  xg_disk $(( cx+8.4 )) $(( cy+1.2 )) $(( 2.0 )) $(( 2.1 )) 3
  return 0
}

xg_rabbit_sleep() {
  local -F w=${1:-34.0}
  local -F h=${2:-19.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-1.0 ))
  cy=$(( 11.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 10.4 )) $(( 5.2 )) 1
  xg_disk $(( cx-7.4 )) $(( cy-0.6 )) $(( 4.3 )) $(( 3.7 )) 1
  xg_seg $(( cx-8.4 )) $(( cy-3.2 )) $(( cx-12.2 )) $(( cy-1.0 )) $(( 1.4 )) 1
  xg_seg $(( cx-6.4 )) $(( cy-3.6 )) $(( cx-9.8 )) $(( cy-5.8 )) $(( 1.4 )) 1
  xg_rabbit_dress $(( cx-7.4 )) $(( cy-0.6 ))
  xg_set $(( int(int(cx-8.4)) )) $(( int(int(cy-0.6)) )) 7
  xg_set $(( int(int(cx-7.2)) )) $(( int(int(cy+0.2)) )) 7
  xg_disk $(( cx+9.4 )) $(( cy-1.2 )) $(( 2.1 )) $(( 2.1 )) 3
  return 0
}

xg_rabbit_hop() {
  local -F frame=${1:-0.0}
  local -F w=${2:-44.0}
  local -F h=${3:-26.0}
  local -F hx hy
  local -i stretch
  xg_px_new $(( int(w) )) $(( int(h) ))
  stretch=$(( (frame%2.0+2.0)%2.0==0.0 ))
  hx=$(( 10.0 ))
  hy=$(( stretch?8.0:10.0 ))
  if (( stretch )); then
    xg_disk $(( hx+12.0 )) $(( hy+8.5 )) $(( 10.0 )) $(( 5.0 )) 1
    xg_disk $(( hx+20.0 )) $(( hy+12.4 )) $(( 3.0 )) $(( 1.5 )) 1
    xg_disk $(( hx-2.0 )) $(( hy+11.8 )) $(( 2.4 )) $(( 1.3 )) 1
    xg_disk $(( hx+20.5 )) $(( hy+4.6 )) $(( 2.2 )) $(( 2.2 )) 3
  else
    xg_disk $(( hx+10.0 )) $(( hy+8.0 )) $(( 8.4 )) $(( 5.8 )) 1
    xg_disk $(( hx+16.5 )) $(( hy+12.0 )) $(( 3.2 )) $(( 1.7 )) 1
    xg_disk $(( hx+1.0 )) $(( hy+12.4 )) $(( 2.2 )) $(( 1.2 )) 1
    xg_disk $(( hx+17.0 )) $(( hy+4.2 )) $(( 2.2 )) $(( 2.2 )) 3
  fi
  xg_rabbit_ears $(( hx )) $(( hy )) "$( (( stretch )) && print -n 'back' || print -n 'up' )" "${XG[ears]:-up}" $(( 0.9 )) $(( ${XG[ear_l]:-1.0} ))
  xg_disk $(( hx )) $(( hy )) $(( 5.2 )) $(( 4.6 )) 1
  xg_rabbit_dress $(( hx )) $(( hy ))
  xg_rabbit_face $(( hx )) $(( hy )) 'open' '' $(( 0.85 ))
  return 0
}

xg_ham_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( hx+-1.0*3.4*s )) $(( hy-3.8*s )) $(( 1.8*s )) $(( 1.6*s )) 1
  xg_disk $(( hx+-1.0*3.5*s )) $(( hy-3.6*s )) $(( 0.8*s )) $(( 0.7*s )) 9 "1 2 4"
  xg_disk $(( hx+1.0*3.4*s )) $(( hy-3.8*s )) $(( 1.8*s )) $(( 1.6*s )) 1
  xg_disk $(( hx+1.0*3.5*s )) $(( hy-3.6*s )) $(( 0.8*s )) $(( 0.7*s )) 9 "1 2 4"
  return 0
}

xg_hamster_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'banded' ]] && _pattern=1
  [[ "$pattern" == 'roan' ]] && _pattern=2
  [[ "$pattern" == 'spotted' ]] && _pattern=3
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F x0
  local -i x y
  if (( _pattern==1 )); then
    x0=$(( hx-(1.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(2.5-1.0)) ))
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&x0<=x&&x<=x0+3.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(4.5-3.0) )); then
          XG_XPM[$(( y*XG_XPW+x ))]=3
        fi
      done
    done
  elif (( _pattern==3 )); then
    xg_disk $(( hx+1.5+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(3.5-1.5) )) $(( hy+2.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(4.0-2.0) )) $(( 2.0 )) $(( 1.6 )) 2 "1"
    xg_disk $(( hx-(2.0+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(4.0-2.0)) )) $(( hy+4.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(6.0-4.0) )) $(( 1.8 )) $(( 1.5 )) 2 "1"
  elif (( _pattern==2 )); then
    xg_tabby $(( pj*0.53 )) $(( 1.05+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(1.25-1.05) ))
  fi
  return 0
}

xg_ham_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  [[ "$eyes" == 'open' ]] && _eyes=2
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F X exl exr ey
  exl=$(( hx-2.6*s ))
  exr=$(( hx+2.6*s ))
  ey=$(( int(floor(int(hy-1.2*s)/2.0))*2.0 ))
  # MIND THE ENUM.  The transliterator numbers each function's string
  # literals in the order IT meets them, so in this one _eyes==2 is OPEN --
  # it is 3 in the rabbit's and there is no rule but to look.  The eyes went
  # into the wrong branch once and the hamster squinted its way through life.
  if (( _eyes==2 )); then
    xg_eye $(( exl )) $(( ey+0.5 )) $(( 1.0*s )) 5
    xg_eye $(( exr )) $(( ey+0.5 )) $(( 1.0*s )) 6
  elif (( _eyes==1 )); then
    xg_set $(( int(int(exl)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(exr)) )) $(( int(ey+1.0) )) 7
  else
    xg_set $(( int(int(exl)) )) $(( int(ey+1.0) )) 5
    xg_set $(( int(int(exr)) )) $(( int(ey+1.0) )) 6
  fi
  xg_disk $(( hx )) $(( hy+1.8*s )) $(( 3.4*s )) $(( 2.2*s )) 3 "1 2 3 4"
  xg_set $(( int(int(hx)) )) $(( int(int(hy+0.8*s)) )) 10
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+2.2*s)) )) 7
  else
    xg_set $(( int(int(hx-1.0)) )) $(( int(int(hy+2.4*s)) )) 2
    xg_set $(( int(int(hx+1.0)) )) $(( int(int(hy+2.4*s)) )) 2
  fi
  return 0
}

xg_hamster_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-26.0}
  local -F h=${4:-20.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=$(( 7.0 ))
  xg_disk $(( hx )) $(( hy+6.0 )) $(( 6.8 )) $(( 5.4 )) 1
  xg_disk $(( hx )) $(( hy+8.2 )) $(( 4.6 )) $(( 2.8 )) 3 "1 2"
  xg_ham_ears $(( hx )) $(( hy )) 1.0
  xg_disk $(( hx )) $(( hy )) $(( 5.2 )) $(( 4.4 )) 1
  xg_hamster_dress $(( hx )) $(( hy ))
  xg_ham_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_disk $(( hx-2.2 )) $(( hy+10.8 )) $(( 1.6 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.2 )) $(( hy+10.8 )) $(( 1.6 )) $(( 1.0 )) 4
  return 0
}

xg_hamster_sleep() {
  local -F w=${1:-26.0}
  local -F h=${2:-14.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 7.6 )) $(( 4.6 )) 1
  xg_disk $(( cx-4.0 )) $(( cy+0.4 )) $(( 3.0 )) $(( 2.6 )) 1
  xg_hamster_dress $(( cx-4.0 )) $(( cy ))
  xg_set $(( int(int(cx-5.0)) )) $(( int(int(cy-0.4)) )) 7
  xg_set $(( int(int(cx-3.6)) )) $(( int(int(cy-0.6)) )) 7
  xg_disk $(( cx-4.4 )) $(( cy+1.6 )) $(( 2.0 )) $(( 1.2 )) 3 "1 2"
  return 0
}

xg_hamster_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-30.0}
  local -F h=${3:-16.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 9.0 ))
  hy=$(( 6.0 ))
  xg_disk $(( hx+7.0 )) $(( hy+4.0 )) $(( 8.0 )) $(( 4.4 )) 1
  xg_disk $(( hx+7.0 )) $(( hy+6.0 )) $(( 5.2 )) $(( 2.0 )) 3 "1 2"
  xg_ham_ears $(( hx )) $(( hy )) $(( 0.9 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 4.0 )) 1
  xg_hamster_dress $(( hx )) $(( hy ))
  xg_ham_face $(( hx )) $(( hy )) 'open' '' $(( 0.9 ))
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( hx+2.5 )) $(( hy+8.4 )) $(( 1.6 )) $(( 1.0 )) 4
    xg_disk $(( hx+11.5 )) $(( hy+8.4 )) $(( 1.6 )) $(( 1.0 )) 4
  else
    xg_disk $(( hx+5.0 )) $(( hy+8.4 )) $(( 1.6 )) $(( 1.0 )) 4
    xg_disk $(( hx+9.0 )) $(( hy+8.4 )) $(( 1.6 )) $(( 1.0 )) 4
  fi
  return 0
}

xg_fox_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_tri $(( hx+-1.0*6.8*s )) $(( hy-2.0*s )) $(( hx+-1.0*5.0*s )) $(( hy-9.8*s )) $(( hx+-1.0*1.0*s )) $(( hy-4.2*s )) 1
  xg_tri $(( hx+-1.0*5.6*s )) $(( hy-3.2*s )) $(( hx+-1.0*4.8*s )) $(( hy-8.0*s )) $(( hx+-1.0*2.4*s )) $(( hy-4.4*s )) 7 "1 2 4"
  xg_tri $(( hx+1.0*6.8*s )) $(( hy-2.0*s )) $(( hx+1.0*5.0*s )) $(( hy-9.8*s )) $(( hx+1.0*1.0*s )) $(( hy-4.2*s )) 1
  xg_tri $(( hx+1.0*5.6*s )) $(( hy-3.2*s )) $(( hx+1.0*4.8*s )) $(( hy-8.0*s )) $(( hx+1.0*2.4*s )) $(( hy-4.4*s )) 7 "1 2 4"
  return 0
}

xg_fox_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'cross' ]] && _pattern=1
  [[ "$pattern" == 'marble' ]] && _pattern=2
  [[ "$pattern" == 'mask' ]] && _pattern=3
  [[ "$pattern" == 'socks' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F wdt
  local -i x y
  if (( _pattern==3 )); then
    xg_disk $(( hx-4.2 )) $(( hy-1.5 )) $(( 2.2 )) $(( 1.8 )) 2 "1"
    xg_disk $(( hx+4.2 )) $(( hy-1.5 )) $(( 2.2 )) $(( 1.8 )) 2 "1"
  elif (( _pattern==1 )); then
    wdt=$(( 1.2+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(2.0-1.2) ))
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&abs(x-hx)<wdt&&y>hy+4.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
    xg_disk $(( hx )) $(( hy+8.0 )) $(( 6.0 )) $(( 1.4 )) 2 "1"
  elif (( _pattern==2 )); then
    xg_disk $(( hx+2.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(4.5-2.0) )) $(( hy+6.0+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(10.0-6.0) )) $(( 3.2 )) $(( 2.6 )) 2 "1"
    xg_disk $(( hx-(3.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(5.0-3.0)) )) $(( hy-(1.0+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(3.0-1.0)) )) $(( 2.4 )) $(( 1.8 )) 2 "1"
  elif (( _pattern==4 )); then
    xg_disk $(( hx-(3.5+((int(pj)*48271+int(6.0)*30203+11213)%10007)/10007.0*(4.5-3.5)) )) $(( hy-5.5 )) $(( 1.8 )) $(( 2.2 )) 2 "1"
    xg_disk $(( hx+3.5+((int(pj)*48271+int(7.0)*30203+11213)%10007)/10007.0*(4.5-3.5) )) $(( hy-5.5 )) $(( 1.8 )) $(( 2.2 )) 2 "1"
  fi
  return 0
}

xg_fox_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  [[ "$eyes" == 'open' ]] && _eyes=2
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F exl exr ey
  xg_tri $(( hx-6.0*s )) $(( hy+0.5 )) $(( hx-1.0 )) $(( hy+4.6*s )) $(( hx-5.0*s )) $(( hy+4.6*s )) 3 "1 2 3 4"
  xg_tri $(( hx+6.0*s )) $(( hy+0.5 )) $(( hx+1.0 )) $(( hy+4.6*s )) $(( hx+5.0*s )) $(( hy+4.6*s )) 3 "1 2 3 4"
  exl=$(( hx-3.2*s ))
  exr=$(( hx+3.2*s ))
  ey=$(( hy-0.8*s ))
  if (( _eyes==2 )); then
    xg_disk $(( exl )) $(( ey )) $(( 1.5*s )) $(( 1.2*s )) 5 "1 2 3 4"
    xg_set $(( int(int(exl)) )) $(( int(int(ey)) )) 7
    xg_disk $(( exr )) $(( ey )) $(( 1.5*s )) $(( 1.2*s )) 6 "1 2 3 4"
    xg_set $(( int(int(exr)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exl+1.0)) )) $(( int(int(ey-1.0)) )) 8
    xg_set $(( int(int(exr+1.0)) )) $(( int(int(ey-1.0)) )) 8
  elif (( _eyes==1 )); then
    xg_set $(( int(int(exl-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exl)) )) $(( int(int(ey+1.0)) )) 7
    xg_set $(( int(int(exl+1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr)) )) $(( int(int(ey+1.0)) )) 7
    xg_set $(( int(int(exr+1.0)) )) $(( int(int(ey)) )) 7
  else
    xg_set $(( int(int(exl-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exl)) )) $(( int(int(ey)) )) 5
    xg_set $(( int(int(exl+1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr-1.0)) )) $(( int(int(ey)) )) 7
    xg_set $(( int(int(exr)) )) $(( int(int(ey)) )) 6
    xg_set $(( int(int(exr+1.0)) )) $(( int(int(ey)) )) 7
  fi
  xg_disk $(( hx )) $(( hy+3.0*s )) $(( 2.0*s )) $(( 2.0*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+3.8*s )) $(( 1.0*s )) $(( 0.8*s )) 7
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+5.0*s)) )) 7
  else
    xg_set $(( int(int(hx-1.0)) )) $(( int(int(hy+5.0*s)) )) 2
    xg_set $(( int(int(hx+1.0)) )) $(( int(int(hy+5.0*s)) )) 2
  fi
  return 0
}

xg_fox_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-38.0}
  local -F h=${4:-31.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-2.0 ))
  hy=$(( 9.0 ))
  xg_disk $(( hx+8.5 )) $(( hy+15.5 )) $(( 6.4 )) $(( 4.2 )) 1
  xg_disk $(( hx+12.5 )) $(( hy+14.0 )) $(( 3.0 )) $(( 2.6 )) 3
  xg_disk $(( hx )) $(( hy+13.0 )) $(( 7.6 )) $(( 6.6 )) 1
  xg_disk $(( hx )) $(( hy+7.0 )) $(( 5.2 )) $(( 5.0 )) 1
  xg_disk $(( hx )) $(( hy+11.0 )) $(( 3.6 )) $(( 4.4 )) 3 "1 2"
  xg_fox_ears $(( hx )) $(( hy )) 1.0
  xg_disk $(( hx )) $(( hy )) $(( 6.0 )) $(( 5.0 )) 1
  xg_fox_dress $(( hx )) $(( hy ))
  xg_fox_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_disk $(( hx-2.8 )) $(( hy+19.2 )) $(( 2.2 )) $(( 1.3 )) 7
  xg_disk $(( hx+2.8 )) $(( hy+19.2 )) $(( 2.2 )) $(( 1.3 )) 7
  return 0
}

xg_fox_sleep() {
  local -F w=${1:-34.0}
  local -F h=${2:-19.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-1.0 ))
  cy=$(( 10.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 10.0 )) $(( 5.2 )) 1
  xg_disk $(( cx-6.8 )) $(( cy-0.8 )) $(( 4.6 )) $(( 4.0 )) 1
  xg_disk $(( cx-1.0 )) $(( cy+3.2 )) $(( 9.4 )) $(( 2.6 )) 1
  xg_disk $(( cx-8.6 )) $(( cy+1.8 )) $(( 3.0 )) $(( 2.4 )) 3
  xg_fox_ears $(( cx-6.8 )) $(( cy-0.8 )) $(( 0.62 ))
  xg_fox_dress $(( cx-6.8 )) $(( cy-0.8 ))
  xg_set $(( int(int(cx-8.2)) )) $(( int(int(cy-1.4)) )) 7
  xg_set $(( int(int(cx-6.6)) )) $(( int(int(cy-1.7)) )) 7
  return 0
}

xg_fox_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-46.0}
  local -F h=${3:-26.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.0 ))
  hy=$(( 7.0 ))
  xg_disk $(( hx+12.0 )) $(( hy+9.0 )) $(( 9.4 )) $(( 4.8 )) 1
  xg_disk $(( hx+21.5 )) $(( hy+7.2 )) $(( 5.2 )) $(( 2.6 )) 1
  xg_disk $(( hx+25.5 )) $(( hy+6.6 )) $(( 2.6 )) $(( 2.2 )) 3
  xg_fox_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.8 )) $(( 4.8 )) 1
  xg_disk $(( hx )) $(( hy+6.5 )) $(( 4.2 )) $(( 3.4 )) 1
  xg_fox_dress $(( hx )) $(( hy ))
  xg_fox_face $(( hx )) $(( hy )) 'open' '' $(( 0.92 ))
  ys=$(( hy+13.2 ))
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( hx+3.0 )) $(( ys )) $(( 1.6 )) $(( 1.6 )) 7
    xg_disk $(( hx+10.0 )) $(( ys )) $(( 1.6 )) $(( 1.6 )) 7
    xg_disk $(( hx+16.0 )) $(( ys )) $(( 1.6 )) $(( 1.6 )) 7
  else
    xg_disk $(( hx+6.0 )) $(( ys )) $(( 1.6 )) $(( 1.6 )) 7
    xg_disk $(( hx+13.0 )) $(( ys )) $(( 1.6 )) $(( 1.6 )) 7
    xg_disk $(( hx+19.0 )) $(( ys )) $(( 1.6 )) $(( 1.6 )) 7
  fi
  return 0
}

xg_turtle_head() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  xg_disk $(( hx )) $(( hy )) $(( 3.2*s )) $(( 2.8*s )) 4
  if (( _eyes==1 )); then
    xg_set $(( int(int(hx-1.5*s)) )) $(( int(int(hy-0.6)) )) 7
    xg_set $(( int(int(hx+1.5*s)) )) $(( int(int(hy-0.6)) )) 7
  else
    xg_eye $(( hx-1.5*s )) $(( hy-0.6 )) $(( 0.92*s )) 5
    xg_eye $(( hx+1.5*s )) $(( hy-0.6 )) $(( 0.92*s )) 6
  fi
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+1.2)) )) 7
  else
    xg_set $(( int(int(hx-1.0)) )) $(( int(int(hy+1.4)) )) 7
    xg_set $(( int(int(hx)) )) $(( int(int(hy+1.5)) )) 7
  fi
  return 0
}

xg_turtle_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'hex' ]] && _pattern=1
  [[ "$pattern" == 'painted' ]] && _pattern=2
  [[ "$pattern" == 'spotted' ]] && _pattern=3
  [[ "$pattern" == 'striped' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==1 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*2.0+y*3.0+pj)%int(5.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(7.0-5.0))+int(5.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(7.0-5.0)))%int(5.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(7.0-5.0))==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&(int(abs(x-hx)*0.9+pj)%4.0+4.0)%4.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==3 )); then
    xg_disk $(( hx+2.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(5.0-2.0) )) $(( hy-(0.5+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(2.5-0.5)) )) $(( 2.0 )) $(( 1.5 )) 4 "1"
    xg_disk $(( hx-(2.5+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(5.5-2.5)) )) $(( hy+0.0+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(2.0-0.0) )) $(( 1.8 )) $(( 1.4 )) 4 "1"
  elif (( _pattern==2 )); then
    xg_disk $(( hx )) $(( hy )) $(( 9.4 )) $(( 6.0 )) 4 "1"
    xg_disk $(( hx )) $(( hy )) $(( 8.2 )) $(( 5.2 )) 1 "4"
  fi
  return 0
}

xg_turtle_dome() {
  local -F cx=${1:-0.0}
  local -F cy=${2:-0.0}
  local -F rx=${3:-9.8}
  local -F ry=${4:-5.2}
  local -F pat=${5:-0.0}
  xg_disk $(( cx )) $(( cy+0.8 )) $(( rx )) $(( ry )) 1
  xg_disk $(( cx )) $(( cy-1.2 )) $(( rx*0.72 )) $(( ry*1.05 )) 1
  if (( pat!=0 )); then
    xg_turtle_dress $(( cx )) $(( cy ))
  fi
  xg_disk $(( cx+rx*0.34 )) $(( cy-2.6 )) $(( 2.8 )) $(( 1.7 )) 3 "1"
  xg_disk $(( cx )) $(( cy+ry-1.4 )) $(( rx*0.94 )) $(( 1.0 )) 2 "1"
  xg_disk $(( cx )) $(( cy+ry-0.2 )) $(( rx*0.9 )) $(( 1.5 )) 4
  return 0
}

xg_turtle_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-34.0}
  local -F h=${4:-24.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 14.0 ))
  xg_turtle_head $(( cx )) $(( cy-9.0 )) "$eyes" "$mouth" 1.0
  xg_disk $(( cx )) $(( cy-5.6 )) $(( 1.8 )) $(( 2.4 )) 4
  xg_turtle_dome $(( cx )) $(( cy )) 9.8 5.2 1
  xg_disk $(( cx-6.5 )) $(( cy+6.4 )) $(( 2.2 )) $(( 1.5 )) 4
  xg_disk $(( cx+6.5 )) $(( cy+6.4 )) $(( 2.2 )) $(( 1.5 )) 4
  xg_disk $(( cx-2.5 )) $(( cy+6.8 )) $(( 2.0 )) $(( 1.3 )) 4
  xg_disk $(( cx+2.5 )) $(( cy+6.8 )) $(( 2.0 )) $(( 1.3 )) 4
  return 0
}

xg_turtle_sleep() {
  local -F w=${1:-30.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_turtle_dome $(( cx )) $(( cy )) $(( 9.6 )) $(( 4.8 )) 1
  xg_disk $(( cx-9.0 )) $(( cy+3.4 )) $(( 1.9 )) $(( 1.5 )) 4
  xg_set $(( int(int(cx-9.6)) )) $(( int(int(cy+2.8)) )) 7
  return 0
}

xg_turtle_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-38.0}
  local -F h=${3:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0+2.0 ))
  cy=$(( 10.0 ))
  xg_turtle_head $(( cx-11.0 )) $(( cy-3.5 )) 'open' '' $(( 0.9 ))
  xg_disk $(( cx-8.5 )) $(( cy-1.0 )) $(( 2.0 )) $(( 1.8 )) 4
  xg_turtle_dome $(( cx )) $(( cy )) $(( 9.6 )) $(( 4.8 )) 1
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( cx-6.0 )) $(( cy+6.0 )) $(( 2.2 )) $(( 1.5 )) 4
    xg_disk $(( cx+4.0 )) $(( cy+6.2 )) $(( 2.0 )) $(( 1.4 )) 4
  else
    xg_disk $(( cx-3.0 )) $(( cy+6.2 )) $(( 2.0 )) $(( 1.4 )) 4
    xg_disk $(( cx+6.5 )) $(( cy+6.0 )) $(( 2.2 )) $(( 1.5 )) 4
  fi
  return 0
}

xg_hog_spikes() {
  local -F pj=${1:-0.0}
  local -F belly_y=${2:-0.0}
  local -F r
  local -i x y
  for (( y=int(0); y<int(XG_XPH); y++ )); do
    for (( x=int(0); x<int(XG_XPW); x++ )); do
      if (( XG_XPM[y*XG_XPW+x]==1&&y<belly_y )); then
        r=$(( ((x*7.0+y*13.0+pj)%11.0+11.0)%11.0 ))
        if (( r<2.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        elif (( r==10.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=3
        fi
      fi
    done
  done
  return 0
}

xg_hedgehog_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'banded' ]] && _pattern=1
  [[ "$pattern" == 'frosted' ]] && _pattern=2
  [[ "$pattern" == 'masked' ]] && _pattern=3
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==1 )); then
    xg_disk $(( hx )) $(( hy-2.0 )) $(( 8.0 )) $(( 1.6 )) 2 "1 3"
  elif (( _pattern==2 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==2&&((x+y+pj)%3.0+3.0)%3.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=3
        fi
      done
    done
  elif (( _pattern==3 )); then
    xg_disk $(( hx-2.6 )) $(( hy+3.0 )) $(( 1.6 )) $(( 1.2 )) 2 "3 1"
    xg_disk $(( hx+2.6 )) $(( hy+3.0 )) $(( 1.6 )) $(( 1.2 )) 2 "3 1"
  fi
  return 0
}

xg_hog_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F X exl exr ey
  xg_disk $(( hx )) $(( hy+3.0*s )) $(( 5.4*s )) $(( 3.2*s )) 3
  xg_disk $(( hx+-1.0*4.6*s )) $(( hy+0.4*s )) $(( 1.3*s )) $(( 1.2*s )) 3
  xg_disk $(( hx+1.0*4.6*s )) $(( hy+0.4*s )) $(( 1.3*s )) $(( 1.2*s )) 3
  exl=$(( hx-3.0*s ))
  exr=$(( hx+1.6*s ))
  ey=$(( int(floor(int(hy+2.0*s)/2.0))*2.0 ))
  if (( _eyes==1 )); then
    xg_set $(( int(int(exl)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(exl)+1.0) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(exr)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(exr)+1.0) )) $(( int(ey+1.0) )) 7
  else
    xg_eye $(( exl+0.5 )) $(( ey+0.5 )) $(( 1.15*s )) 5
    xg_eye $(( exr+0.5 )) $(( ey+0.5 )) $(( 1.15*s )) 6
  fi
  xg_tri $(( hx-1.6*s )) $(( hy+4.0*s )) $(( hx+1.6*s )) $(( hy+4.0*s )) $(( hx )) $(( hy+6.2*s )) 3
  xg_set $(( int(int(hx)) )) $(( int(int(hy+5.8*s)) )) 10
  xg_set $(( int(int(hx)) )) $(( int(int(hy+6.4*s)) )) 10
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+4.8*s)) )) 7
  fi
  return 0
}

xg_hedgehog_sit() {
  local -i pj=${XG[pj]:-0}
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-30.0}
  local -F h=${4:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 9.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 9.2 )) $(( 6.6 )) 1
  xg_hog_spikes $(( pj )) $(( cy+1.0 ))
  xg_hedgehog_dress $(( cx )) $(( cy ))
  xg_hog_face $(( cx )) $(( cy )) "$eyes" "$mouth" 1.0
  xg_disk $(( cx-3.0 )) $(( cy+7.4 )) $(( 1.8 )) $(( 1.1 )) 4
  xg_disk $(( cx+3.0 )) $(( cy+7.4 )) $(( 1.8 )) $(( 1.1 )) 4
  return 0
}

xg_hedgehog_sleep() {
  local -i pj=${XG[pj]:-0}
  local -F w=${1:-26.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 8.2 )) $(( 5.6 )) 1
  xg_hog_spikes $(( pj )) $(( XG_XPH ))
  xg_hedgehog_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-5.2 )) $(( cy+3.2 )) $(( 2.6 )) $(( 1.7 )) 3
  xg_set $(( int(int(cx-6.4)) )) $(( int(int(cy+2.8)) )) 7
  return 0
}

xg_hedgehog_walk() {
  local -i pj=${XG[pj]:-0}
  local -F frame=${1:-0.0}
  local -F w=${2:-32.0}
  local -F h=${3:-16.0}
  local -F cx cy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0+1.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 8.6 )) $(( 5.4 )) 1
  xg_hog_spikes $(( pj )) $(( cy+2.0 ))
  xg_hedgehog_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-7.5 )) $(( cy+2.2 )) $(( 3.4 )) $(( 2.4 )) 3
  xg_set $(( int(int(cx-8.0)) )) $(( int(int(cy+1.2)) )) 5
  xg_set $(( int(int(cx-10.2)) )) $(( int(int(cy+3.0)) )) 10
  ys=$(( cy+6.4 ))
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( cx-4.0 )) $(( ys )) $(( 1.6 )) $(( 1.0 )) 4
    xg_disk $(( cx+4.5 )) $(( ys )) $(( 1.6 )) $(( 1.0 )) 4
  else
    xg_disk $(( cx-1.0 )) $(( ys )) $(( 1.6 )) $(( 1.0 )) 4
    xg_disk $(( cx+7.0 )) $(( ys )) $(( 1.6 )) $(( 1.0 )) 4
  fi
  return 0
}

xg_glorp_stalks() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local -F droop=${4:-0.0}
  local -F s=${5:-1.0}
  local -F sx_ tipx tipy
  sx_=$(( hx+-1.0*3.6*s ))
  tipx=$(( sx_+-1.0*(1.5+droop*2.5)*s ))
  tipy=$(( int(floor(int(hy-(9.5-droop*6.0)*s)/2.0))*2.0 ))
  xg_seg $(( sx_ )) $(( hy-4.0*s )) $(( tipx )) $(( tipy+1.0 )) $(( 1.1*s )) 1
  if (( _eyes==1 )); then
    xg_set $(( int(int(tipx-1.0)) )) $(( int(tipy+1.0) )) 7
    xg_set $(( int(int(tipx+1.0)) )) $(( int(tipy+1.0) )) 7
  else
    xg_disk $(( tipx )) $(( tipy+0.5 )) $(( 1.9*s )) $(( 1.7*s )) 5
    xg_set $(( int(int(tipx)) )) $(( int(tipy) )) 7
    xg_set $(( int(int(tipx)) )) $(( int(tipy+1.0) )) 7
  fi
  sx_=$(( hx+1.0*3.6*s ))
  tipx=$(( sx_+1.0*(1.5+droop*2.5)*s ))
  tipy=$(( int(floor(int(hy-(9.5-droop*6.0)*s)/2.0))*2.0 ))
  xg_seg $(( sx_ )) $(( hy-4.0*s )) $(( tipx )) $(( tipy+1.0 )) $(( 1.1*s )) 1
  if (( _eyes==1 )); then
    xg_set $(( int(int(tipx-1.0)) )) $(( int(tipy+1.0) )) 7
    xg_set $(( int(int(tipx+1.0)) )) $(( int(tipy+1.0) )) 7
  else
    xg_disk $(( tipx )) $(( tipy+0.5 )) $(( 1.9*s )) $(( 1.7*s )) 6
    xg_set $(( int(int(tipx)) )) $(( int(tipy) )) 7
    xg_set $(( int(int(tipx)) )) $(( int(tipy+1.0) )) 7
  fi
  return 0
}

xg_glorp_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'glassy' ]] && _pattern=1
  [[ "$pattern" == 'nebular' ]] && _pattern=2
  [[ "$pattern" == 'ringed' ]] && _pattern=3
  [[ "$pattern" == 'speckled' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*5.0+y*11.0+pj)%11.0+11.0)%11.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==3 )); then
    xg_disk $(( hx )) $(( hy+0.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(2.0-0.0) )) $(( 7.4 )) $(( 4.6 )) 2 "1"
    xg_disk $(( hx )) $(( hy+0.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(2.0-0.0) )) $(( 6.2 )) $(( 3.7 )) 1 "2"
  elif (( _pattern==2 )); then
    xg_disk $(( hx+1.5+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(4.0-1.5) )) $(( hy+(-2.0)+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(1.0-(-2.0)) )) $(( 3.0 )) $(( 2.2 )) 4 "1"
    xg_disk $(( hx-(2.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(4.5-2.0)) )) $(( hy+1.0+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(3.5-1.0) )) $(( 2.4 )) $(( 1.8 )) 4 "1"
  elif (( _pattern==1 )); then
    xg_disk $(( hx-3.2 )) $(( hy-2.6 )) $(( 3.2 )) $(( 2.2 )) 3 "1 2"
  fi
  return 0
}

xg_glorp_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F w=${3:-30.0}
  local -F h=${4:-24.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 15.0 ))
  xg_glorp_stalks $(( cx )) $(( cy )) "$eyes" 0.0 1.0
  xg_disk $(( cx )) $(( cy )) $(( 9.0 )) $(( 6.8 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-3.0 )) $(( cy-3.2 )) $(( 2.6 )) $(( 1.8 )) 3 "1 2"
  xg_disk $(( cx+3.4 )) $(( cy+3.4 )) $(( 1.5 )) $(( 1.2 )) 2 "1"
  if (( _mouth==1 )); then
    xg_set $(( int(int(cx)) )) $(( int(int(cy+0.5)) )) 7
    xg_set $(( int(int(cx)) )) $(( int(int(cy+1.5)) )) 7
  else
    xg_set $(( int(int(cx-1.0)) )) $(( int(int(cy+1.0)) )) 7
    xg_set $(( int(int(cx)) )) $(( int(int(cy+1.4)) )) 7
    xg_set $(( int(int(cx+1.0)) )) $(( int(int(cy+1.0)) )) 7
  fi
  xg_disk $(( cx-5.0 )) $(( cy+6.4 )) $(( 2.4 )) $(( 1.2 )) 1
  xg_disk $(( cx+5.0 )) $(( cy+6.4 )) $(( 2.4 )) $(( 1.2 )) 1
  return 0
}

xg_glorp_sleep() {
  local -F w=${1:-32.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 11.0 )) $(( 3.6 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_seg $(( cx-3.6 )) $(( cy-2.6 )) $(( cx-7.0 )) $(( cy-3.2 )) $(( 1.0 )) 1
  xg_seg $(( cx+3.6 )) $(( cy-2.6 )) $(( cx+7.0 )) $(( cy-3.2 )) $(( 1.0 )) 1
  xg_set $(( int(int(cx-8.0)) )) $(( int(int(cy-3.4)) )) 7
  xg_set $(( int(int(cx+8.0)) )) $(( int(int(cy-3.4)) )) 7
  return 0
}

xg_glorp_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-32.0}
  local -F h=${3:-22.0}
  local -F cx cy lean
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 14.0 ))
  lean=$(( (frame%2.0+2.0)%2.0==0.0?2.0:-2.0 ))
  xg_glorp_stalks $(( cx+lean*0.8 )) $(( cy )) 'open' 0.0 $(( 0.95 ))
  xg_disk $(( cx+lean*0.4 )) $(( cy )) $(( 8.6 )) $(( 6.2 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_disk $(( cx+lean*0.4-3.0 )) $(( cy-3.0 )) $(( 2.4 )) $(( 1.6 )) 3 "1 2"
  xg_disk $(( cx+lean+3.5 )) $(( cy+5.8 )) $(( 2.6 )) $(( 1.3 )) 1
  xg_disk $(( cx+lean-4.5 )) $(( cy+5.6 )) $(( 2.2 )) $(( 1.2 )) 1
  return 0
}

xg_xeno_tail() {
  local -F x0=${1:-0.0}
  local -F y0=${2:-0.0}
  local -F sweep=${3:-1.0}
  local -i blade=${4:-1}
  xg_seg $(( x0 )) $(( y0 )) $(( x0+3.6*sweep )) $(( y0+1.8 )) $(( 1.4 )) 1
  xg_seg $(( x0+3.6*sweep )) $(( y0+1.8 )) $(( x0+7.2*sweep )) $(( y0+0.6 )) $(( 1.4 )) 1
  xg_seg $(( x0+7.2*sweep )) $(( y0+0.6 )) $(( x0+9.6*sweep )) $(( y0-2.4 )) $(( 1.4 )) 1
  if (( blade )); then
    xg_tri $(( x0+9.2*sweep )) $(( y0-2.0 )) $(( x0+12.0*sweep )) $(( y0-5.2 )) $(( x0+10.8*sweep )) $(( y0-1.4 )) 2
  fi
  return 0
}

xg_xeno_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'biomech' ]] && _pattern=1
  [[ "$pattern" == 'chitin' ]] && _pattern=2
  [[ "$pattern" == 'gloss' ]] && _pattern=3
  [[ "$pattern" == 'ribbed' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&y>hy+4.0&&((y+pj)%3.0+3.0)%3.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==2 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*3.0+y*5.0+pj)%int(6.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(8.0-6.0))+int(6.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(8.0-6.0)))%int(6.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(8.0-6.0))==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==1 )); then
    xg_tabby $(( pj*0.47 )) $(( 0.95+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(1.15-0.95) ))
  elif (( _pattern==3 )); then
    xg_disk $(( hx-(2.0+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(4.0-2.0)) )) $(( hy+5.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(8.0-5.0) )) $(( 2.6 )) $(( 3.4 )) 3 "1"
  fi
  return 0
}

xg_xeno_head() {   # The dome, swept back.  No eyes; it sees you anyway.
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local mouth="${3:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${4:-1.0}
  local -F my
  local -i i
  xg_disk $(( hx )) $(( hy-3.0*s )) $(( 3.6*s )) $(( 6.8*s )) 1
  xg_disk $(( hx+1.2*s )) $(( hy-7.6*s )) $(( 2.4*s )) $(( 3.0*s )) 1
  xg_disk $(( hx+2.6*s )) $(( hy-9.2*s )) $(( 1.6*s )) $(( 1.8*s )) 1
  xg_disk $(( hx-0.6*s )) $(( hy-4.8*s )) $(( 1.9*s )) $(( 3.8*s )) 3 "1 2"
  # A GLEAM ON THE CARAPACE · NOT AN EYE.  The organism has none and is not
  # being given any; this is the room's light finding the dome, so you can
  # tell which way the head is turned -- which is the thing that was actually
  # hard to read.  A DEPARTURE from the original, which leaves the dome matte.
  xg_disk $(( hx-0.9*s )) $(( hy-6.4*s )) $(( 0.7*s )) $(( 2.0*s )) 8 "1 2 3"
  xg_disk $(( hx )) $(( hy+1.8*s )) $(( 3.4*s )) $(( 2.2*s )) 1
  my=$(( int(floor(int(hy+2.4*s)/2.0))*2.0 ))
  for (( i=int(-2.0); i<int(3.0); i++ )); do
    xg_set $(( int(int(hx+i*s)) )) $(( int(my) )) 7
    xg_set $(( int(int(hx+i*s)) )) $(( int(my+1.0) )) $(( ((i%2.0+2.0)%2.0==0.0)?3:7 ))
  done
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(my+2.0) )) 7
    xg_set $(( int(int(hx)) )) $(( int(my+3.0) )) 9
    xg_set $(( int(int(hx)) )) $(( int(my+4.0) )) 3
  fi
  return 0
}

xg_xeno_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-38.0}
  local -F h=${4:-32.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-3.0 ))
  hy=$(( 9.0 ))
  xg_disk $(( hx-6.4 )) $(( hy+4.6 )) $(( 1.6 )) $(( 3.0 )) 1
  xg_disk $(( hx+6.4 )) $(( hy+4.6 )) $(( 1.6 )) $(( 3.0 )) 1
  xg_disk $(( hx-6.4 )) $(( hy+2.4 )) $(( 1.1 )) $(( 1.1 )) 3
  xg_disk $(( hx+6.4 )) $(( hy+2.4 )) $(( 1.1 )) $(( 1.1 )) 3
  xg_disk $(( hx-4.0 )) $(( hy+3.6 )) $(( 1.4 )) $(( 2.6 )) 1
  xg_disk $(( hx+4.0 )) $(( hy+3.6 )) $(( 1.4 )) $(( 2.6 )) 1
  xg_disk $(( hx-4.0 )) $(( hy+1.8 )) $(( 1.0 )) $(( 1.0 )) 3
  xg_disk $(( hx+4.0 )) $(( hy+1.8 )) $(( 1.0 )) $(( 1.0 )) 3
  xg_disk $(( hx )) $(( hy+14.0 )) $(( 7.4 )) $(( 6.6 )) 1
  xg_disk $(( hx )) $(( hy+8.0 )) $(( 4.8 )) $(( 4.6 )) 1
  xg_xeno_tail $(( hx+4.0 )) $(( hy+18.5 )) 1.0 1
  xg_xeno_dress $(( hx )) $(( hy ))
  xg_xeno_head $(( hx )) $(( hy )) "$mouth" 1.0
  xg_disk $(( hx-2.8 )) $(( hy+20.2 )) $(( 2.3 )) $(( 1.3 )) 2
  xg_disk $(( hx+2.8 )) $(( hy+20.2 )) $(( 2.3 )) $(( 1.3 )) 2
  xg_set $(( int(int(hx-4.4)) )) $(( int(int(hy+20.6)) )) 7
  xg_set $(( int(int(hx+4.4)) )) $(( int(int(hy+20.6)) )) 7
  return 0
}

xg_xeno_sleep() {
  local -F w=${1:-34.0}
  local -F h=${2:-18.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-1.0 ))
  cy=$(( 10.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 9.8 )) $(( 5.0 )) 1
  xg_disk $(( cx-7.0 )) $(( cy-1.6 )) $(( 4.0 )) $(( 5.2 )) 1
  xg_disk $(( cx-7.8 )) $(( cy-3.4 )) $(( 2.4 )) $(( 2.6 )) 3 "1 2"
  xg_xeno_tail $(( cx+2.0 )) $(( cy+3.6 )) $(( 0.9 )) $(( 1 ))
  xg_xeno_dress $(( cx-7.0 )) $(( cy-1.6 ))
  xg_set $(( int(int(cx-7.0+-1.0)) )) $(( int(int(cy+1.4)) )) $(( (-1.0)?7:3 ))
  xg_set $(( int(int(cx-7.0+0.0)) )) $(( int(int(cy+1.4)) )) $(( (0.0)?7:3 ))
  xg_set $(( int(int(cx-7.0+1.0)) )) $(( int(int(cy+1.4)) )) $(( (1.0)?7:3 ))
  return 0
}

xg_xeno_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-46.0}
  local -F h=${3:-24.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.0 ))
  hy=$(( 7.0 ))
  xg_disk $(( hx+11.0 )) $(( hy+9.0 )) $(( 9.6 )) $(( 4.6 )) 1
  xg_disk $(( hx+6.0 )) $(( hy+6.2 )) $(( 1.5 )) $(( 2.4 )) 2
  xg_disk $(( hx+10.0 )) $(( hy+6.0 )) $(( 1.5 )) $(( 2.4 )) 2
  xg_xeno_tail $(( hx+19.0 )) $(( hy+9.0 )) $(( 1.1 )) 1
  xg_disk $(( hx )) $(( hy+4.0 )) $(( 3.8 )) $(( 3.6 )) 1
  xg_xeno_dress $(( hx )) $(( hy+2.0 ))
  xg_xeno_head $(( hx )) $(( hy+2.0 )) '' $(( 0.85 ))
  ys=$(( hy+13.0 ))
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( hx+4.0 )) $(( ys )) $(( 1.7 )) $(( 1.4 )) 2
    xg_disk $(( hx+12.0 )) $(( ys )) $(( 1.7 )) $(( 1.4 )) 2
    xg_disk $(( hx+18.0 )) $(( ys )) $(( 1.7 )) $(( 1.4 )) 2
  else
    xg_disk $(( hx+7.0 )) $(( ys )) $(( 1.7 )) $(( 1.4 )) 2
    xg_disk $(( hx+15.0 )) $(( ys )) $(( 1.7 )) $(( 1.4 )) 2
    xg_disk $(( hx+21.0 )) $(( ys )) $(( 1.7 )) $(( 1.4 )) 2
  fi
  return 0
}

xg_duck_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'bibbed' ]] && _pattern=1
  [[ "$pattern" == 'capped' ]] && _pattern=2
  [[ "$pattern" == 'mallard' ]] && _pattern=3
  [[ "$pattern" == 'penciled' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==1 )); then
    xg_disk $(( hx )) $(( hy+4.5+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(6.0-4.5) )) $(( 2.8 )) $(( 3.0 )) 3 "1 2"
  elif (( _pattern==4 )); then
    xg_tabby $(( pj*0.43 )) $(( 1.02+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(1.2-1.02) ))
  elif (( _pattern==2 )); then
    xg_disk $(( hx )) $(( hy-2.0 )) $(( 3.2 )) $(( 1.6 )) 2 "1"
  elif (( _pattern==3 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&y<hy+3.2 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
    xg_disk $(( hx-0.4 )) $(( hy+3.4 )) $(( 2.2 )) $(( 0.8 )) 3 "1 2"
  fi
  return 0
}

xg_duck_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F ey
  ey=$(( int(floor(int(hy-1.0*s)/2.0))*2.0 ))
  if (( _eyes==1 )); then
    xg_set $(( int(int(hx-2.2*s)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx+2.2*s)) )) $(( int(ey+1.0) )) 7
  else
    xg_eye $(( hx-2.2*s )) $(( ey+0.5 )) $(( 0.95*s )) 5
    xg_eye $(( hx+2.2*s )) $(( ey+0.5 )) $(( 0.95*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+1.8*s )) $(( 2.6*s )) $(( 1.1*s )) 4
  xg_set $(( int(int(hx-2.0)) )) $(( int(int(hy+1.8*s)) )) 2
  if (( _mouth==1 )); then
    xg_disk $(( hx )) $(( hy+3.0*s )) $(( 1.7*s )) $(( 0.7*s )) 4
  fi
  return 0
}

xg_duck_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-30.0}
  local -F h=${4:-24.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-2.0 ))
  hy=$(( 6.0 ))
  xg_disk $(( hx+1.5 )) $(( hy+10.0 )) $(( 7.6 )) $(( 5.4 )) 1
  xg_disk $(( hx+8.0 )) $(( hy+6.6 )) $(( 2.6 )) $(( 2.0 )) 1
  xg_disk $(( hx+3.0 )) $(( hy+9.6 )) $(( 4.4 )) $(( 3.2 )) 2 "1"
  xg_disk $(( hx-0.5 )) $(( hy+4.5 )) $(( 2.0 )) $(( 3.0 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 3.8 )) $(( 3.4 )) 1
  xg_duck_dress $(( hx )) $(( hy ))
  xg_duck_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_disk $(( hx-0.5 )) $(( hy+15.4 )) $(( 1.8 )) $(( 1.0 )) 4
  xg_disk $(( hx+3.5 )) $(( hy+15.4 )) $(( 1.8 )) $(( 1.0 )) 4
  return 0
}

xg_duck_sleep() {
  local -F w=${1:-28.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 9.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 8.0 )) $(( 4.8 )) 1
  xg_disk $(( cx+2.5 )) $(( cy-3.4 )) $(( 3.2 )) $(( 2.6 )) 1
  xg_disk $(( cx+0.5 )) $(( cy-2.6 )) $(( 2.0 )) $(( 1.0 )) 4
  xg_duck_dress $(( cx+2.5 )) $(( cy-3.4 ))
  xg_set $(( int(int(cx+3.5)) )) $(( int(int(cy-4.0)) )) 7
  return 0
}

xg_duck_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-32.0}
  local -F h=${3:-22.0}
  local -F hx hy lean
  xg_px_new $(( int(w) )) $(( int(h) ))
  lean=$(( (frame%2.0+2.0)%2.0==0.0?1.2:-1.2 ))
  hx=$(( w/2.0-3.0+lean*0.5 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx+2.5 )) $(( hy+9.0 )) $(( 7.4 )) $(( 5.0 )) 1
  xg_disk $(( hx+8.8 )) $(( hy+5.8 )) $(( 2.4 )) $(( 1.9 )) 1
  xg_disk $(( hx+3.5 )) $(( hy+8.6 )) $(( 4.2 )) $(( 3.0 )) 2 "1"
  xg_disk $(( hx-0.5 )) $(( hy+4.0 )) $(( 2.0 )) $(( 2.8 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 3.7 )) $(( 3.3 )) 1
  xg_duck_dress $(( hx )) $(( hy ))
  xg_duck_face $(( hx )) $(( hy )) 'open' '' 1.0
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( hx )) $(( hy+14.6 )) $(( 1.9 )) $(( 1.1 )) 4
    xg_disk $(( hx+5.0 )) $(( hy+13.8 )) $(( 1.6 )) $(( 0.9 )) 4
  else
    xg_disk $(( hx+1.0 )) $(( hy+13.8 )) $(( 1.6 )) $(( 0.9 )) 4
    xg_disk $(( hx+4.0 )) $(( hy+14.6 )) $(( 1.9 )) $(( 1.1 )) 4
  fi
  return 0
}

xg_frog_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'belly' ]] && _pattern=1
  [[ "$pattern" == 'darted' ]] && _pattern=2
  [[ "$pattern" == 'spotted' ]] && _pattern=3
  [[ "$pattern" == 'striped' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i k x y
  if (( _pattern==3 )); then
    xg_disk $(( hx+2.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(4.5-2.0) )) $(( hy+2.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(4.0-2.0) )) $(( 1.9 )) $(( 1.5 )) 2 "1"
    xg_disk $(( hx-(2.5+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(5.0-2.5)) )) $(( hy+3.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(5.5-3.0) )) $(( 1.7 )) $(( 1.4 )) 2 "1"
  elif (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x+pj)%5.0+5.0)%5.0<1.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==2 )); then
    for (( k=int(0); k<int(4.0); k++ )); do
      xg_disk $(( hx+(-6.0)+((int(pj)*48271+int((k*2.0))*30203+11213)%10007)/10007.0*(6.0-(-6.0)) )) $(( hy+1.0+((int(pj)*48271+int((k*2.0+1.0))*30203+11213)%10007)/10007.0*(6.5-1.0) )) $(( 1.4 )) $(( 1.1 )) 7 "1"
    done
  elif (( _pattern==1 )); then
    xg_disk $(( hx )) $(( hy+4.5+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(6.0-4.5) )) $(( 4.6 )) $(( 2.6 )) 3 "1 2"
  fi
  return 0
}

xg_frog_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F bx_ my
  local -i i
  bx_=$(( hx+-1.0*3.0*s ))
  xg_disk $(( bx_ )) $(( hy-2.4*s )) $(( 1.8*s )) $(( 1.7*s )) 1
  if (( _eyes==1 )); then
    xg_set $(( int(int(bx_)-1.0) )) $(( int(int(hy-2.6*s)) )) 7
    xg_set $(( int(int(bx_)) )) $(( int(int(hy-2.6*s)) )) 7
  else
    xg_disk $(( bx_ )) $(( hy-2.6*s )) $(( 1.1*s )) $(( 1.0*s )) 5
    xg_set $(( int(int(bx_)) )) $(( int(int(hy-2.8*s)) )) 7
  fi
  bx_=$(( hx+1.0*3.0*s ))
  xg_disk $(( bx_ )) $(( hy-2.4*s )) $(( 1.8*s )) $(( 1.7*s )) 1
  if (( _eyes==1 )); then
    xg_set $(( int(int(bx_)-1.0) )) $(( int(int(hy-2.6*s)) )) 7
    xg_set $(( int(int(bx_)) )) $(( int(int(hy-2.6*s)) )) 7
  else
    xg_disk $(( bx_ )) $(( hy-2.6*s )) $(( 1.1*s )) $(( 1.0*s )) 6
    xg_set $(( int(int(bx_)) )) $(( int(int(hy-2.8*s)) )) 7
  fi
  my=$(( int(hy+1.6*s) ))
  for (( i=int(int(-3.0*s)); i<int(int(3.0*s)+1.0); i++ )); do
    xg_set $(( int(int(hx+i)) )) $(( int(my+(abs(i)>1.6*s?1.0:0.0)) )) 7
  done
  if (( _mouth==1 )); then
    xg_disk $(( hx )) $(( hy+2.6*s )) $(( 1.6*s )) $(( 0.9*s )) 9
  fi
  return 0
}

xg_frog_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-30.0}
  local -F h=${4:-18.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0 ))
  hy=$(( 6.0 ))
  xg_disk $(( hx )) $(( hy+4.5 )) $(( 7.4 )) $(( 4.8 )) 1
  xg_disk $(( hx )) $(( hy+0.5 )) $(( 5.2 )) $(( 3.4 )) 1
  xg_disk $(( hx-6.4 )) $(( hy+6.4 )) $(( 2.6 )) $(( 2.4 )) 1
  xg_disk $(( hx+6.4 )) $(( hy+6.4 )) $(( 2.6 )) $(( 2.4 )) 1
  xg_frog_dress $(( hx )) $(( hy ))
  xg_disk $(( hx )) $(( hy+6.8 )) $(( 4.0 )) $(( 1.8 )) 3 "1 2"
  xg_frog_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_set $(( int(int(hx-3.0)) )) $(( int(int(hy+8.6)) )) 4
  xg_set $(( int(int(hx+3.0)) )) $(( int(int(hy+8.6)) )) 4
  return 0
}

xg_frog_sleep() {
  local -F w=${1:-28.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy+1.0 )) $(( 7.8 )) $(( 4.0 )) 1
  xg_disk $(( cx )) $(( cy-1.5 )) $(( 5.0 )) $(( 2.6 )) 1
  xg_disk $(( cx+-1.0*2.8 )) $(( cy-3.0 )) $(( 1.6 )) $(( 1.4 )) 1
  xg_set $(( int(int(cx+-1.0*2.8)-1.0) )) $(( int(int(cy-3.2)) )) 7
  xg_set $(( int(int(cx+-1.0*2.8)) )) $(( int(int(cy-3.2)) )) 7
  xg_disk $(( cx+1.0*2.8 )) $(( cy-3.0 )) $(( 1.6 )) $(( 1.4 )) 1
  xg_set $(( int(int(cx+1.0*2.8)-1.0) )) $(( int(int(cy-3.2)) )) 7
  xg_set $(( int(int(cx+1.0*2.8)) )) $(( int(int(cy-3.2)) )) 7
  xg_frog_dress $(( cx )) $(( cy ))
  return 0
}

xg_frog_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-36.0}
  local -F h=${3:-20.0}
  local -F hx hy
  local -i stretch
  xg_px_new $(( int(w) )) $(( int(h) ))
  stretch=$(( (frame%2.0+2.0)%2.0==0.0 ))
  hx=$(( 10.0 ))
  hy=$(( stretch?6.0:9.0 ))
  if (( stretch )); then
    xg_disk $(( hx+8.0 )) $(( hy+4.0 )) $(( 8.0 )) $(( 4.0 )) 1
    xg_seg $(( hx+13.0 )) $(( hy+6.5 )) $(( hx+19.0 )) $(( hy+9.5 )) $(( 1.8 )) 1
    xg_seg $(( hx-2.0 )) $(( hy+7.0 )) $(( hx-5.5 )) $(( hy+10.0 )) $(( 1.5 )) 1
  else
    xg_disk $(( hx+5.0 )) $(( hy+3.5 )) $(( 6.8 )) $(( 4.4 )) 1
    xg_disk $(( hx+10.5 )) $(( hy+5.5 )) $(( 2.6 )) $(( 2.3 )) 1
    xg_disk $(( hx-3.5 )) $(( hy+5.8 )) $(( 2.2 )) $(( 2.0 )) 1
  fi
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 3.0 )) 1
  xg_frog_dress $(( hx )) $(( hy ))
  xg_frog_face $(( hx )) $(( hy )) 'open' '' $(( 0.9 ))
  return 0
}

xg_snake_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'banded' ]] && _pattern=1
  [[ "$pattern" == 'diamond' ]] && _pattern=2
  [[ "$pattern" == 'speckled' ]] && _pattern=3
  [[ "$pattern" == 'striped' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==1 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x+pj)%6.0+6.0)%6.0<2.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==2 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x+y+pj)%5.0+5.0)%5.0==0.0&&((x-y+pj)%4.0+4.0)%4.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((y+pj)%4.0+4.0)%4.0<1.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==3 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*5.0+y*7.0+pj)%9.0+9.0)%9.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  fi
  return 0
}

xg_snake_head() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local -i tongue=${4:-1}
  local -F s=${5:-1.0}
  xg_disk $(( hx )) $(( hy )) $(( 2.3*s )) $(( 1.8*s )) 1
  if (( _eyes==1 )); then
    xg_set $(( int(int(hx-1.2*s)) )) $(( int(int(hy-0.6)) )) 7
    xg_set $(( int(int(hx+1.2*s)) )) $(( int(int(hy-0.6)) )) 7
  else
    xg_eye $(( hx-1.3*s )) $(( hy-0.6 )) $(( 0.7*s )) 5
    xg_eye $(( hx+1.3*s )) $(( hy-0.6 )) $(( 0.7*s )) 6
  fi
  if (( tongue )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+2.2*s)) )) 9
    xg_set $(( int(int(hx-1.0)) )) $(( int(int(hy+3.0*s)) )) 9
    xg_set $(( int(int(hx+1.0)) )) $(( int(int(hy+3.0*s)) )) 9
  fi
  return 0
}

xg_snake_sit() {
  local eyes="${1:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'open' ]] && _eyes=1
  local mouth="${2:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F w=${3:-30.0}
  local -F h=${4:-24.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 15.0 ))
  xg_disk $(( cx )) $(( cy+4.0 )) $(( 9.0 )) $(( 3.2 )) 1
  xg_disk $(( cx )) $(( cy+1.0 )) $(( 7.0 )) $(( 2.6 )) 1
  xg_disk $(( cx )) $(( cy-1.4 )) $(( 5.0 )) $(( 2.0 )) 1
  xg_snake_dress $(( cx )) $(( cy ))
  xg_seg $(( cx+1.8 )) $(( cy-2.0 )) $(( cx+2.4 )) $(( cy-7.0 )) $(( 1.7 )) 1
  xg_snake_head $(( cx+2.4 )) $(( cy-8.8 )) "$eyes" $(( _mouth==1||_eyes==1 )) 1.0
  return 0
}

xg_snake_sleep() {
  local -F w=${1:-28.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy+1.0 )) $(( 8.6 )) $(( 3.4 )) 1
  xg_disk $(( cx )) $(( cy-0.8 )) $(( 6.2 )) $(( 2.4 )) 1
  xg_snake_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-1.0 )) $(( cy-2.4 )) $(( 2.2 )) $(( 1.5 )) 1
  xg_set $(( int(int(cx-2.0)) )) $(( int(int(cy-2.8)) )) 7
  xg_set $(( int(int(cx-0.2)) )) $(( int(int(cy-2.8)) )) 7
  return 0
}

xg_snake_walk() {   # the body is one sine drawn along · the head rides its end
  local -F frame=${1:-0.0}
  local -F w=${2:-44.0}
  local -F h=${3:-14.0}
  local -F ph t x0 y0 x1 y1 hx hy
  local -i i
  xg_px_new $(( int(w) )) $(( int(h) ))
  ph=$(( int(frame)%2==0 ? 0.0 : 3.141592653589793 ))
  for (( i=0; i<8; i++ )); do
    t=$(( i/8.0 ));     x0=$(( 4.0+t*30.0 )); y0=$(( 8.0+sin(t*6.0+ph)*3.2 ))
    t=$(( (i+1)/8.0 )); x1=$(( 4.0+t*30.0 )); y1=$(( 8.0+sin(t*6.0+ph)*3.2 ))
    xg_seg $x0 $y0 $x1 $y1 2.1 1
  done
  xg_snake_dress 20.0 8.0
  hx=$(( 36.0 )); hy=$(( 8.0+sin(6.0+ph)*3.2-1.0 ))
  xg_snake_head $hx $hy 'open' 1 0.95
  return 0
}

xg_owl_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'barred' ]] && _pattern=1
  [[ "$pattern" == 'hooded' ]] && _pattern=2
  [[ "$pattern" == 'speckled' ]] && _pattern=3
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i x y
  if (( _pattern==1 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((y+pj)%4.0+4.0)%4.0<1.0&&y>hy+3.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==3 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*3.0+y*7.0+pj)%8.0+8.0)%8.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==2 )); then
    xg_disk $(( hx )) $(( hy-2.2 )) $(( 4.8 )) $(( 2.2 )) 2 "1"
  fi
  return 0
}

xg_owl_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -i heart=${6:-0}
  local -F ey
  xg_disk $(( hx )) $(( hy )) $(( 4.6*s )) $(( 3.4*s )) 3 "1 2"
  if (( heart )); then
    xg_disk $(( hx )) $(( hy-0.4 )) $(( 4.8*s )) $(( 3.6*s )) 3 "1 2"
  fi
  ey=$(( int(floor(int(hy-0.8*s)/2.0))*2.0 ))
  if (( _eyes==1 )); then
    xg_set $(( int(int(hx-2.2*s)-1.0) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx-2.2*s)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx-2.2*s)+1.0) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx+2.2*s)-1.0) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx+2.2*s)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx+2.2*s)+1.0) )) $(( int(ey+1.0) )) 7
  else
    xg_disk $(( hx-2.2*s )) $(( ey+0.5 )) $(( 1.8*s )) $(( 1.5*s )) 5
    xg_set $(( int(int(hx-2.2*s)) )) $(( int(ey) )) 7
    xg_set $(( int(int(hx-2.2*s)) )) $(( int(ey+1.0) )) 7
    xg_disk $(( hx+2.2*s )) $(( ey+0.5 )) $(( 1.8*s )) $(( 1.5*s )) 6
    xg_set $(( int(int(hx+2.2*s)) )) $(( int(ey) )) 7
    xg_set $(( int(int(hx+2.2*s)) )) $(( int(ey+1.0) )) 7
  fi
  xg_tri $(( hx-0.9 )) $(( hy+1.6*s )) $(( hx+0.9 )) $(( hy+1.6*s )) $(( hx )) $(( hy+3.0*s )) 4
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+3.6*s)) )) 7
  fi
  return 0
}

xg_owl_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-28.0}
  local -F h=${4:-26.0}
  local -F hx hy
  local -i heart
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0 ))
  hy=$(( 6.0 ))
  heart=0; [[ "${XG[pattern]}" == heart* ]] && heart=1
  xg_disk $(( hx )) $(( hy+9.0 )) $(( 6.6 )) $(( 7.6 )) 1
  xg_disk $(( hx-4.8 )) $(( hy+8.5 )) $(( 1.9 )) $(( 5.6 )) 2 "1"
  xg_disk $(( hx+4.8 )) $(( hy+8.5 )) $(( 1.9 )) $(( 5.6 )) 2 "1"
  xg_disk $(( hx )) $(( hy+11.5 )) $(( 3.6 )) $(( 3.8 )) 3 "1 2"
  xg_tri $(( hx-4.0 )) $(( hy-2.2 )) $(( hx-5.2 )) $(( hy-5.6 )) $(( hx-1.6 )) $(( hy-3.2 )) 1
  xg_tri $(( hx+4.0 )) $(( hy-2.2 )) $(( hx+5.2 )) $(( hy-5.6 )) $(( hx+1.6 )) $(( hy-3.2 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 5.4 )) $(( 4.4 )) 1
  xg_owl_dress $(( hx )) $(( hy ))
  xg_owl_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0 $(( heart ))
  xg_set $(( int(int(hx-2.2)) )) $(( int(int(hy+16.6)) )) 4
  xg_set $(( int(int(hx-2.2)-1.0) )) $(( int(int(hy+17.2)) )) 4
  xg_set $(( int(int(hx-2.2)+1.0) )) $(( int(int(hy+17.2)) )) 4
  xg_set $(( int(int(hx+2.2)) )) $(( int(int(hy+16.6)) )) 4
  xg_set $(( int(int(hx+2.2)-1.0) )) $(( int(int(hy+17.2)) )) 4
  xg_set $(( int(int(hx+2.2)+1.0) )) $(( int(int(hy+17.2)) )) 4
  return 0
}

xg_owl_sleep() {
  local -F w=${1:-24.0}
  local -F h=${2:-20.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0 ))
  hy=$(( 7.0 ))
  xg_disk $(( hx )) $(( hy+5.0 )) $(( 6.4 )) $(( 6.4 )) 1
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 5.0 )) $(( 3.8 )) 1
  xg_owl_dress $(( hx )) $(( hy ))
  xg_owl_face $(( hx )) $(( hy+1.0 )) 'closed' '' $(( 0.9 )) 0
  return 0
}

xg_owl_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-28.0}
  local -F h=${3:-24.0}
  local -F hx hy lean
  xg_px_new $(( int(w) )) $(( int(h) ))
  lean=$(( (frame%2.0+2.0)%2.0==0.0?1.0:-1.0 ))
  hx=$(( w/2.0+lean*0.6 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx )) $(( hy+8.5 )) $(( 6.2 )) $(( 7.0 )) 1
  xg_disk $(( hx )) $(( hy+10.5 )) $(( 3.4 )) $(( 3.4 )) 3 "1 2"
  xg_disk $(( hx )) $(( hy )) $(( 5.2 )) $(( 4.2 )) 1
  xg_owl_dress $(( hx )) $(( hy ))
  xg_owl_face $(( hx )) $(( hy )) 'open' '' $(( 0.95 )) 0
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_set $(( int(int(hx-2.5)) )) $(( int(int(hy+15.8)) )) 4
    xg_set $(( int(int(hx+1.5)) )) $(( int(int(hy+15.2)) )) 4
  else
    xg_set $(( int(int(hx-1.5)) )) $(( int(int(hy+15.2)) )) 4
    xg_set $(( int(int(hx+2.5)) )) $(( int(int(hy+15.8)) )) 4
  fi
  return 0
}

xg_pig_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  xg_set $(( int(int(x)) )) $(( int(int(y)) )) 1
  xg_set $(( int(int(x+1.0)) )) $(( int(int(y-1.0)) )) 1
  xg_set $(( int(int(x+2.0)) )) $(( int(int(y)) )) 1
  xg_set $(( int(int(x+1.0)) )) $(( int(int(y+1.0)) )) 1
  return 0
}

xg_pig_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_tri $(( hx-4.6*s )) $(( hy-1.6*s )) $(( hx-3.4*s )) $(( hy-4.8*s )) $(( hx-0.8*s )) $(( hy-2.6*s )) 1
  xg_tri $(( hx+4.6*s )) $(( hy-1.6*s )) $(( hx+3.4*s )) $(( hy-4.8*s )) $(( hx+0.8*s )) $(( hy-2.6*s )) 1
  xg_set $(( int(int(hx-3.4*s)) )) $(( int(int(hy-3.4*s)) )) 2
  xg_set $(( int(int(hx+3.4*s)) )) $(( int(int(hy-3.4*s)) )) 2
  return 0
}

xg_pig_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'belted' ]] && _pattern=1
  [[ "$pattern" == 'mud-streaked' ]] && _pattern=2
  [[ "$pattern" == 'saddleback' ]] && _pattern=3
  [[ "$pattern" == 'spotted' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F x0
  local -i x y
  if (( _pattern==4 )); then
    xg_disk $(( hx+2.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(5.0-2.0) )) $(( hy+4.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(7.0-4.0) )) $(( 2.4 )) $(( 1.9 )) 2 "1"
    xg_disk $(( hx-(3.0+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(6.0-3.0)) )) $(( hy+6.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(9.0-6.0) )) $(( 2.1 )) $(( 1.7 )) 2 "1"
  elif (( _pattern==1 )); then
    x0=$(( hx-(0.5+((int(pj)*48271+int(5.0)*30203+11213)%10007)/10007.0*(2.0-0.5)) ))
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&x0<=x&&x<=x0+3.5 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=3
        fi
      done
    done
  elif (( _pattern==3 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&x>hx+2.0&&y>hy+3.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==2 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&y>hy+9.0&&((x*3.0+pj)%5.0+5.0)%5.0<2.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  fi
  return 0
}

xg_pig_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F ey
  ey=$(( int(floor(int(hy-1.6*s)/2.0))*2.0 ))
  if (( _eyes==1 )); then
    xg_set $(( int(int(hx-2.6*s)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx+2.6*s)) )) $(( int(ey+1.0) )) 7
  else
    xg_eye $(( hx-2.6*s )) $(( ey+0.5 )) $(( 1.0*s )) 5
    xg_eye $(( hx+2.6*s )) $(( ey+0.5 )) $(( 1.0*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+1.6*s )) $(( 2.4*s )) $(( 1.7*s )) 9
  xg_set $(( int(int(hx-1.0)) )) $(( int(int(hy+1.6*s)) )) 2
  xg_set $(( int(int(hx+1.0)) )) $(( int(int(hy+1.6*s)) )) 2
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(int(hy+3.6*s)) )) 7
  fi
  return 0
}

xg_pig_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-34.0}
  local -F h=${4:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=$(( 8.0 ))
  xg_disk $(( hx )) $(( hy+10.5 )) $(( 8.6 )) $(( 6.8 )) 1
  xg_pig_tail $(( hx+8.6 )) $(( hy+9.0 ))
  xg_disk $(( hx )) $(( hy+13.5 )) $(( 5.0 )) $(( 3.4 )) 3 "1 2"
  xg_pig_ears $(( hx )) $(( hy )) 1.0
  xg_disk $(( hx )) $(( hy )) $(( 5.8 )) $(( 4.8 )) 1
  xg_pig_dress $(( hx )) $(( hy ))
  xg_pig_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_disk $(( hx-3.0 )) $(( hy+16.8 )) $(( 2.0 )) $(( 1.2 )) 4
  xg_disk $(( hx+3.0 )) $(( hy+16.8 )) $(( 2.0 )) $(( 1.2 )) 4
  return 0
}

xg_pig_sleep() {
  local -F w=${1:-34.0}
  local -F h=${2:-16.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 9.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 10.0 )) $(( 5.0 )) 1
  xg_disk $(( cx-7.5 )) $(( cy-0.5 )) $(( 4.2 )) $(( 3.6 )) 1
  xg_pig_ears $(( cx-7.5 )) $(( cy-0.5 )) $(( 0.7 ))
  xg_pig_dress $(( cx-7.5 )) $(( cy-0.5 ))
  xg_disk $(( cx-10.5 )) $(( cy+1.0 )) $(( 1.9 )) $(( 1.4 )) 9
  xg_set $(( int(int(cx-8.5)) )) $(( int(int(cy-1.4)) )) 7
  xg_pig_tail $(( cx+10.0 )) $(( cy-1.0 ))
  return 0
}

xg_pig_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-40.0}
  local -F h=${3:-22.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 10.0 ))
  hy=$(( 6.0 ))
  xg_disk $(( hx+9.0 )) $(( hy+7.0 )) $(( 9.4 )) $(( 5.4 )) 1
  xg_pig_tail $(( hx+18.5 )) $(( hy+4.5 ))
  xg_pig_ears $(( hx )) $(( hy )) $(( 0.9 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 5.2 )) $(( 4.4 )) 1
  xg_pig_dress $(( hx )) $(( hy ))
  xg_pig_face $(( hx )) $(( hy+1.0 )) 'open' '' $(( 0.9 ))
  ys=$(( hy+11.6 ))
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( hx+3.0 )) $(( ys )) $(( 1.7 )) $(( 1.3 )) 4
    xg_disk $(( hx+9.0 )) $(( ys )) $(( 1.7 )) $(( 1.3 )) 4
    xg_disk $(( hx+15.0 )) $(( ys )) $(( 1.7 )) $(( 1.3 )) 4
  else
    xg_disk $(( hx+6.0 )) $(( ys )) $(( 1.7 )) $(( 1.3 )) 4
    xg_disk $(( hx+12.0 )) $(( ys )) $(( 1.7 )) $(( 1.3 )) 4
    xg_disk $(( hx+17.0 )) $(( ys )) $(( 1.7 )) $(( 1.3 )) 4
  fi
  return 0
}

xg_axo_gills() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  local -F droop=${4:-0.0}
  local -F x0 x1 y1
  x0=$(( hx+-1.0*2.6*s ))
  x1=$(( hx+-1.0*(3.0+2.0)*s ))
  y1=$(( hy+(-2.8+droop*2.5)*s ))
  xg_seg $(( x0 )) $(( hy+-2.8*0.35*s )) $(( x1 )) $(( y1 )) $(( 1.0 )) 9
  xg_set $(( int(int(x1+-1.0)) )) $(( int(int(y1)) )) 9
  x0=$(( hx+-1.0*2.6*s ))
  x1=$(( hx+-1.0*(3.8+2.0)*s ))
  y1=$(( hy+(-1.0+droop*2.5)*s ))
  xg_seg $(( x0 )) $(( hy+-1.0*0.35*s )) $(( x1 )) $(( y1 )) $(( 1.0 )) 9
  xg_set $(( int(int(x1+-1.0)) )) $(( int(int(y1)) )) 9
  x0=$(( hx+-1.0*2.6*s ))
  x1=$(( hx+-1.0*(4.0+2.0)*s ))
  y1=$(( hy+(0.8+droop*2.5)*s ))
  xg_seg $(( x0 )) $(( hy+0.8*0.35*s )) $(( x1 )) $(( y1 )) $(( 1.0 )) 9
  xg_set $(( int(int(x1+-1.0)) )) $(( int(int(y1)) )) 9
  x0=$(( hx+1.0*2.6*s ))
  x1=$(( hx+1.0*(3.0+2.0)*s ))
  y1=$(( hy+(-2.8+droop*2.5)*s ))
  xg_seg $(( x0 )) $(( hy+-2.8*0.35*s )) $(( x1 )) $(( y1 )) $(( 1.0 )) 9
  xg_set $(( int(int(x1+1.0)) )) $(( int(int(y1)) )) 9
  x0=$(( hx+1.0*2.6*s ))
  x1=$(( hx+1.0*(3.8+2.0)*s ))
  y1=$(( hy+(-1.0+droop*2.5)*s ))
  xg_seg $(( x0 )) $(( hy+-1.0*0.35*s )) $(( x1 )) $(( y1 )) $(( 1.0 )) 9
  xg_set $(( int(int(x1+1.0)) )) $(( int(int(y1)) )) 9
  x0=$(( hx+1.0*2.6*s ))
  x1=$(( hx+1.0*(4.0+2.0)*s ))
  y1=$(( hy+(0.8+droop*2.5)*s ))
  xg_seg $(( x0 )) $(( hy+0.8*0.35*s )) $(( x1 )) $(( y1 )) $(( 1.0 )) 9
  xg_set $(( int(int(x1+1.0)) )) $(( int(int(y1)) )) 9
  return 0
}

xg_axo_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -i _pattern=0
  [[ "$pattern" == 'dalmatian' ]] && _pattern=1
  [[ "$pattern" == 'glow' ]] && _pattern=2
  [[ "$pattern" == 'mottled' ]] && _pattern=3
  [[ "$pattern" == 'speckled' ]] && _pattern=4
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -i k x y
  if (( _pattern==4 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*5.0+y*9.0+pj)%10.0+10.0)%10.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=2
        fi
      done
    done
  elif (( _pattern==3 )); then
    xg_disk $(( hx+2.0+((int(pj)*48271+int(1.0)*30203+11213)%10007)/10007.0*(5.0-2.0) )) $(( hy+2.0+((int(pj)*48271+int(2.0)*30203+11213)%10007)/10007.0*(5.0-2.0) )) $(( 2.6 )) $(( 2.0 )) 2 "1"
    xg_disk $(( hx-(3.0+((int(pj)*48271+int(3.0)*30203+11213)%10007)/10007.0*(6.0-3.0)) )) $(( hy+4.0+((int(pj)*48271+int(4.0)*30203+11213)%10007)/10007.0*(7.0-4.0) )) $(( 2.2 )) $(( 1.7 )) 2 "1"
  elif (( _pattern==1 )); then
    for (( k=int(0); k<int(5.0); k++ )); do
      xg_disk $(( hx+(-7.0)+((int(pj)*48271+int((k*2.0))*30203+11213)%10007)/10007.0*(7.0-(-7.0)) )) $(( hy+0.0+((int(pj)*48271+int((k*2.0+1.0))*30203+11213)%10007)/10007.0*(8.0-0.0) )) $(( 1.3 )) $(( 1.0 )) 7 "1"
    done
  elif (( _pattern==2 )); then
    for (( y=int(0); y<int(XG_XPH); y++ )); do
      for (( x=int(0); x<int(XG_XPW); x++ )); do
        if (( XG_XPM[y*XG_XPW+x]==1&&((x*3.0+y*5.0+pj)%11.0+11.0)%11.0==0.0 )); then
          XG_XPM[$(( y*XG_XPW+x ))]=3
        fi
      done
    done
  fi
  return 0
}

xg_axo_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local -i _eyes=0
  [[ "$eyes" == 'closed' ]] && _eyes=1
  local mouth="${4:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F s=${5:-1.0}
  local -F ey my
  ey=$(( int(floor(int(hy-1.0*s)/2.0))*2.0 ))
  if (( _eyes==1 )); then
    xg_set $(( int(int(hx-2.2*s)) )) $(( int(ey+1.0) )) 7
    xg_set $(( int(int(hx+2.2*s)) )) $(( int(ey+1.0) )) 7
  else
    xg_eye $(( hx-2.2*s )) $(( ey+0.5 )) $(( 1.0*s )) 5
    xg_eye $(( hx+2.2*s )) $(( ey+0.5 )) $(( 1.0*s )) 6
  fi
  my=$(( int(hy+1.8*s) ))
  xg_set $(( int(int(hx-2.0*s)) )) $(( int(my) )) 7
  xg_set $(( int(int(hx-1.0)) )) $(( int(my+1.0) )) 7
  xg_set $(( int(int(hx)) )) $(( int(my+1.0) )) 7
  xg_set $(( int(int(hx+1.0)) )) $(( int(my+1.0) )) 7
  xg_set $(( int(int(hx+2.0*s)) )) $(( int(my) )) 7
  if (( _mouth==1 )); then
    xg_set $(( int(int(hx)) )) $(( int(my+2.0) )) 9
  fi
  return 0
}

xg_axolotl_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-32.0}
  local -F h=${4:-20.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-3.0 ))
  hy=$(( 7.0 ))
  xg_disk $(( hx+4.0 )) $(( hy+7.0 )) $(( 7.8 )) $(( 4.6 )) 1
  xg_disk $(( hx+11.5 )) $(( hy+5.0 )) $(( 3.0 )) $(( 3.8 )) 1
  xg_disk $(( hx+12.3 )) $(( hy+3.4 )) $(( 1.8 )) $(( 1.8 )) 3 "1 2"
  xg_axo_gills $(( hx )) $(( hy )) 1.0 0.0
  xg_disk $(( hx )) $(( hy )) $(( 5.0 )) $(( 4.2 )) 1
  xg_axo_dress $(( hx )) $(( hy ))
  xg_axo_face $(( hx )) $(( hy )) "$eyes" "$mouth" 1.0
  xg_disk $(( hx-1.0 )) $(( hy+10.6 )) $(( 1.6 )) $(( 1.0 )) 1
  xg_disk $(( hx+6.0 )) $(( hy+10.8 )) $(( 1.6 )) $(( 1.0 )) 1
  return 0
}

xg_axolotl_sleep() {
  local -F w=${1:-30.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 8.6 )) $(( 3.8 )) 1
  xg_disk $(( cx-6.5 )) $(( cy-0.5 )) $(( 3.8 )) $(( 3.2 )) 1
  xg_axo_gills $(( cx-6.5 )) $(( cy-0.5 )) $(( 0.8 )) $(( 0.6 ))
  xg_axo_dress $(( cx-6.5 )) $(( cy-0.5 ))
  xg_axo_face $(( cx-6.5 )) $(( cy-0.5 )) 'closed' '' $(( 0.8 ))
  xg_disk $(( cx+9.0 )) $(( cy-0.6 )) $(( 2.0 )) $(( 2.4 )) 1
  return 0
}

xg_axolotl_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-36.0}
  local -F h=${3:-17.0}
  local -F hx hy sway ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  sway=$(( (frame%2.0+2.0)%2.0==0.0?1.4:-1.4 ))
  hx=$(( 9.0 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx+8.0 )) $(( hy+5.5 )) $(( 8.2 )) $(( 4.2 )) 1
  xg_disk $(( hx+16.0 )) $(( hy+4.0+sway )) $(( 3.0 )) $(( 3.2 )) 1
  xg_disk $(( hx+16.8 )) $(( hy+2.6+sway )) $(( 1.7 )) $(( 1.6 )) 3 "1 2"
  xg_axo_gills $(( hx )) $(( hy )) $(( 0.9 )) 0.0
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 3.9 )) 1
  xg_axo_dress $(( hx )) $(( hy ))
  xg_axo_face $(( hx )) $(( hy )) 'open' '' $(( 0.9 ))
  ys=$(( hy+9.2 ))
  if (( (frame%2.0+2.0)%2.0==0.0 )); then
    xg_disk $(( hx+3.0 )) $(( ys )) $(( 1.5 )) $(( 1.0 )) 1
    xg_disk $(( hx+11.0 )) $(( ys )) $(( 1.5 )) $(( 1.0 )) 1
  else
    xg_disk $(( hx+6.0 )) $(( ys )) $(( 1.5 )) $(( 1.0 )) 1
    xg_disk $(( hx+14.0 )) $(( ys )) $(( 1.5 )) $(( 1.0 )) 1
  fi
  return 0
}

xg_hamster_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.5 ))
  hy=$(( 10.0 ))
  xg_disk $(( hx )) $(( hy+4.6 )) $(( 5.2 )) $(( 4.2 )) 1
  xg_disk $(( hx )) $(( hy+6.2 )) $(( 3.4 )) $(( 2.2 )) 3 "1 2"
  xg_ham_ears $(( hx )) $(( hy )) $(( 0.8 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2 )) $(( 3.6 )) 1
  xg_hamster_dress $(( hx )) $(( hy ))
  xg_ham_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.8 ))
  return 0
}

xg_hamster_loaf() {
  xg_hamster_sit 'narrow' '' 26.0 20.0
  return 0
}

xg_fox_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.0 ))
  hy=$(( 8.0 ))
  xg_disk $(( hx+5.5 )) $(( hy+9.5 )) $(( 4.2 )) $(( 2.8 )) 1
  xg_disk $(( hx+8.5 )) $(( hy+8.6 )) $(( 2.2 )) $(( 1.9 )) 3
  xg_disk $(( hx )) $(( hy+8.6 )) $(( 5.2 )) $(( 4.6 )) 1
  xg_disk $(( hx )) $(( hy+10.0 )) $(( 3.0 )) $(( 2.8 )) 3 "1 2"
  xg_fox_ears $(( hx )) $(( hy )) $(( 0.72 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 3.9 )) 1
  xg_fox_dress $(( hx )) $(( hy ))
  xg_fox_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.78 ))
  return 0
}

xg_fox_loaf() {
  local -F w=${1:-34.0}
  local -F h=${2:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-1.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy+6.0 )) $(( 9.0 )) $(( 4.6 )) 1
  xg_disk $(( cx+6.5 )) $(( cy+8.0 )) $(( 4.6 )) $(( 2.4 )) 1
  xg_disk $(( cx+10.0 )) $(( cy+7.4 )) $(( 2.4 )) $(( 2.0 )) 3
  xg_fox_ears $(( cx )) $(( cy )) $(( 0.8 ))
  xg_disk $(( cx )) $(( cy )) $(( 5.2 )) $(( 4.4 )) 1
  xg_fox_dress $(( cx )) $(( cy ))
  xg_fox_face $(( cx )) $(( cy )) 'narrow' '' $(( 0.8 ))
  return 0
}

xg_turtle_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( 11.5 ))
  cy=$(( 13.0 ))
  xg_turtle_head $(( cx )) $(( cy-6.6 )) "$eyes" "$mouth" $(( 0.8 ))
  xg_disk $(( cx )) $(( cy-4.0 )) $(( 1.4 )) $(( 2.0 )) 4
  xg_turtle_dome $(( cx )) $(( cy )) $(( 7.0 )) $(( 4.0 )) 1
  xg_disk $(( cx-4.5 )) $(( cy+4.8 )) $(( 1.8 )) $(( 1.2 )) 4
  xg_disk $(( cx+4.5 )) $(( cy+4.8 )) $(( 1.8 )) $(( 1.2 )) 4
  return 0
}

xg_turtle_loaf() {
  local -F w=${1:-30.0}
  local -F h=${2:-14.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_turtle_dome $(( cx )) $(( cy )) $(( 9.6 )) $(( 4.6 )) 1
  return 0
}

xg_hedgehog_baby() {
  local -i pj=${XG[pj]:-0}
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( 11.5 ))
  cy=$(( 11.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 7.0 )) $(( 5.2 )) 1
  xg_hog_spikes $(( pj+3.0 )) $(( cy ))
  xg_hedgehog_dress $(( cx )) $(( cy ))
  xg_hog_face $(( cx )) $(( cy )) "$eyes" "$mouth" $(( 0.85 ))
  xg_disk $(( cx-2.4 )) $(( cy+5.8 )) $(( 1.5 )) $(( 1.0 )) 4
  xg_disk $(( cx+2.4 )) $(( cy+5.8 )) $(( 1.5 )) $(( 1.0 )) 4
  return 0
}

xg_hedgehog_loaf() {
  xg_hedgehog_sleep 26.0 15.0
  return 0
}

xg_glorp_baby() {
  local eyes="${1:-open}"
  local -F mouth=${2:-0.0}
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( 11.5 ))
  cy=$(( 14.0 ))
  xg_glorp_stalks $(( cx )) $(( cy )) "$eyes" 0.0 $(( 0.8 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6 )) $(( 5.0 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-2.2 )) $(( cy-2.2 )) $(( 2.0 )) $(( 1.4 )) 3 "1 2"
  xg_set $(( int(int(cx-1.0)) )) $(( int(int(cy+1.0)) )) 7
  xg_set $(( int(int(cx)) )) $(( int(int(cy+1.3)) )) 7
  xg_set $(( int(int(cx+1.0)) )) $(( int(int(cy+1.0)) )) 7
  return 0
}

xg_glorp_loaf() {
  local -F w=${1:-28.0}
  local -F h=${2:-17.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 10.0 ))
  xg_glorp_stalks $(( cx )) $(( cy )) 'open' $(( 0.5 )) $(( 0.9 ))
  xg_disk $(( cx )) $(( cy )) $(( 9.6 )) $(( 5.6 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-3.0 )) $(( cy-2.4 )) $(( 2.4 )) $(( 1.6 )) 3 "1 2"
  return 0
}

xg_xeno_baby() {   # The serpent stage.  Do not tell it it is small.
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -i _mouth=0
  [[ "$mouth" == 'wail' ]] && _mouth=1
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F cx cy
  local -i i
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( 11.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy-0.6 )) $(( 2.9 )) $(( 3.8 )) 1
  xg_disk $(( cx-0.4 )) $(( cy-2.0 )) $(( 1.9 )) $(( 2.0 )) 3 "1 2"
  for (( i=int(-1.0); i<int(2.0); i++ )); do
    xg_set $(( int(int(cx+i)) )) $(( int(int(cy+2.0)) )) $(( ((i%2.0+2.0)%2.0==0.0)?3:7 ))
  done
  xg_seg $(( cx )) $(( cy+3.0 )) $(( cx-3.4 )) $(( cy+6.0 )) $(( 2.2 )) 1
  xg_seg $(( cx-3.4 )) $(( cy+6.0 )) $(( cx+2.6 )) $(( cy+9.0 )) $(( 2.2 )) 1
  xg_seg $(( cx+2.6 )) $(( cy+9.0 )) $(( cx-2.2 )) $(( cy+12.0 )) $(( 2.2 )) 1
  xg_seg $(( cx-2.2 )) $(( cy+12.0 )) $(( cx+3.8 )) $(( cy+13.0 )) $(( 1.5 )) 1
  xg_set $(( int(int(cx+4.6)) )) $(( int(int(cy+13.2)) )) 2
  xg_set $(( int(int(cx+4.0)) )) $(( int(int(cy+12.4)) )) 2
  xg_set $(( int(int(cx-3.0)) )) $(( int(int(cy+4.0)) )) 2
  xg_set $(( int(int(cx+3.0)) )) $(( int(int(cy+4.4)) )) 2
  xg_xeno_dress $(( cx )) $(( cy ))
  if (( _mouth==1 )); then
    xg_set $(( int(int(cx)) )) $(( int(int(cy+3.0)) )) 9
  fi
  return 0
}

xg_xeno_loaf() {   # The vent crouch, domestic edition.
  local -F w=${1:-32.0}
  local -F h=${2:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy+7.0 )) $(( 8.0 )) $(( 5.4 )) 1
  xg_disk $(( cx-4.6 )) $(( cy+3.6 )) $(( 1.5 )) $(( 2.4 )) 2
  xg_disk $(( cx+4.6 )) $(( cy+3.6 )) $(( 1.5 )) $(( 2.4 )) 2
  xg_xeno_tail $(( cx+5.0 )) $(( cy+10.5 )) $(( 0.8 )) 1
  xg_xeno_dress $(( cx )) $(( cy ))
  xg_xeno_head $(( cx )) $(( cy )) '' $(( 0.9 ))
  return 0
}

xg_duck_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.5 ))
  hy=$(( 9.0 ))
  xg_disk $(( hx+0.5 )) $(( hy+6.6 )) $(( 5.4 )) $(( 4.2 )) 1
  xg_disk $(( hx+5.0 )) $(( hy+4.6 )) $(( 1.9 )) $(( 1.5 )) 1
  xg_disk $(( hx-0.5 )) $(( hy )) $(( 3.4 )) $(( 3.0 )) 1
  xg_duck_dress $(( hx-0.5 )) $(( hy ))
  xg_duck_face $(( hx-0.5 )) $(( hy )) "$eyes" "$mouth" $(( 0.85 ))
  xg_disk $(( hx-1.0 )) $(( hy+10.8 )) $(( 1.5 )) $(( 0.9 )) 4
  xg_disk $(( hx+2.0 )) $(( hy+10.8 )) $(( 1.5 )) $(( 0.9 )) 4
  return 0
}

xg_duck_loaf() {
  local -F w=${1:-28.0}
  local -F h=${2:-16.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-2.0 ))
  hy=$(( 4.0 ))
  xg_disk $(( hx+1.5 )) $(( hy+7.5 )) $(( 8.2 )) $(( 4.6 )) 1
  xg_disk $(( hx+8.0 )) $(( hy+4.8 )) $(( 2.4 )) $(( 1.8 )) 1
  xg_disk $(( hx-0.5 )) $(( hy+3.0 )) $(( 1.9 )) $(( 2.4 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 3.6 )) $(( 3.2 )) 1
  xg_duck_dress $(( hx )) $(( hy ))
  xg_duck_face $(( hx )) $(( hy )) 'narrow' '' 1.0
  return 0
}

xg_frog_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.5 ))
  hy=$(( 11.0 ))
  xg_disk $(( hx )) $(( hy+3.0 )) $(( 5.4 )) $(( 3.6 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 4.0 )) $(( 2.8 )) 1
  xg_seg $(( hx+4.5 )) $(( hy+4.5 )) $(( hx+8.0 )) $(( hy+3.0 )) $(( 1.2 )) 1
  xg_disk $(( hx-4.6 )) $(( hy+4.6 )) $(( 2.0 )) $(( 1.9 )) 1
  xg_disk $(( hx+4.6 )) $(( hy+4.6 )) $(( 2.0 )) $(( 1.9 )) 1
  xg_frog_dress $(( hx )) $(( hy ))
  xg_frog_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.8 ))
  return 0
}

xg_frog_loaf() {
  xg_frog_sleep 28.0 13.0
  return 0
}

xg_snake_baby() {
  local eyes="${1:-open}"
  local -F mouth=${2:-0.0}
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( 11.5 ))
  cy=$(( 13.0 ))
  xg_disk $(( cx )) $(( cy+2.0 )) $(( 6.0 )) $(( 2.6 )) 1
  xg_disk $(( cx )) $(( cy )) $(( 4.4 )) $(( 2.0 )) 1
  xg_snake_dress $(( cx )) $(( cy ))
  xg_seg $(( cx+1.2 )) $(( cy-1.0 )) $(( cx+1.8 )) $(( cy-4.5 )) $(( 1.4 )) 1
  xg_snake_head $(( cx+1.8 )) $(( cy-6.0 )) "$eyes" 1 $(( 0.9 ))
  return 0
}

xg_snake_loaf() {
  local -F w=${1:-26.0}
  local -F h=${2:-14.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 7.6 )) $(( 4.6 )) 1
  xg_snake_dress $(( cx )) $(( cy ))
  xg_disk $(( cx+1.5 )) $(( cy-2.6 )) $(( 2.1 )) $(( 1.5 )) 1
  xg_set $(( int(int(cx+0.6)) )) $(( int(int(cy-3.0)) )) 7
  xg_set $(( int(int(cx+2.4)) )) $(( int(int(cy-3.0)) )) 7
  return 0
}

xg_owl_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.5 ))
  hy=$(( 7.0 ))
  xg_disk $(( hx )) $(( hy+5.5 )) $(( 5.6 )) $(( 5.6 )) 1
  xg_disk $(( hx )) $(( hy+7.0 )) $(( 3.2 )) $(( 3.0 )) 3 "1 2"
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 3.8 )) 1
  xg_owl_dress $(( hx )) $(( hy ))
  xg_owl_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.9 )) 0
  return 0
}

xg_owl_loaf() {
  local -F w=${1:-24.0}
  local -F h=${2:-18.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0 ))
  hy=$(( 8.0 ))
  xg_disk $(( hx )) $(( hy+2.0 )) $(( 7.2 )) $(( 6.8 )) 1
  xg_owl_dress $(( hx )) $(( hy ))
  xg_owl_face $(( hx )) $(( hy-1.0 )) 'narrow' '' $(( 0.9 )) 0
  return 0
}

xg_pig_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.5 ))
  hy=$(( 9.0 ))
  xg_disk $(( hx )) $(( hy+6.5 )) $(( 5.8 )) $(( 4.6 )) 1
  xg_pig_tail $(( hx+5.8 )) $(( hy+5.5 ))
  xg_pig_ears $(( hx )) $(( hy )) $(( 0.8 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 3.9 )) 1
  xg_pig_dress $(( hx )) $(( hy ))
  xg_pig_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.85 ))
  xg_disk $(( hx-2.2 )) $(( hy+10.6 )) $(( 1.6 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.2 )) $(( hy+10.6 )) $(( 1.6 )) $(( 1.0 )) 4
  return 0
}

xg_pig_loaf() {
  local -F w=${1:-32.0}
  local -F h=${2:-17.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx )) $(( hy+7.0 )) $(( 8.8 )) $(( 5.0 )) 1
  xg_pig_tail $(( hx+8.6 )) $(( hy+5.5 ))
  xg_pig_ears $(( hx )) $(( hy )) $(( 0.9 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.2 )) $(( 4.3 )) 1
  xg_pig_dress $(( hx )) $(( hy ))
  xg_pig_face $(( hx )) $(( hy )) 'narrow' '' $(( 0.9 ))
  return 0
}

xg_axolotl_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 10.5 ))
  hy=$(( 10.0 ))
  xg_disk $(( hx+3.0 )) $(( hy+5.0 )) $(( 5.6 )) $(( 3.6 )) 1
  xg_disk $(( hx+8.5 )) $(( hy+3.6 )) $(( 2.2 )) $(( 2.8 )) 1
  xg_axo_gills $(( hx )) $(( hy )) $(( 0.8 )) 0.0
  xg_disk $(( hx )) $(( hy )) $(( 4.2 )) $(( 3.6 )) 1
  xg_axo_dress $(( hx )) $(( hy ))
  xg_axo_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.85 ))
  return 0
}

xg_axolotl_loaf() {
  local -F w=${1:-28.0}
  local -F h=${2:-15.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-2.0 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx+2.0 )) $(( hy+5.5 )) $(( 7.2 )) $(( 4.0 )) 1
  xg_disk $(( hx+8.0 )) $(( hy+6.5 )) $(( 3.4 )) $(( 2.0 )) 1
  xg_axo_gills $(( hx )) $(( hy )) $(( 0.9 )) $(( 0.3 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6 )) $(( 3.9 )) 1
  xg_axo_dress $(( hx )) $(( hy ))
  xg_axo_face $(( hx )) $(( hy )) 'narrow' '' $(( 0.9 ))
  return 0
}

xg_forehead_m() {
  local -F hx=${1:-0.0}
  local -F top=${2:-0.0}
  local -i dy
  for (( dy=int(0); dy<int(3.0); dy++ )); do
    xg_set $(( int(int(hx+-2.0)) )) $(( int(int(top+dy+(-2.0?1.0:0.0))) )) 2
  done
  for (( dy=int(0); dy<int(3.0); dy++ )); do
    xg_set $(( int(int(hx+0.0)) )) $(( int(int(top+dy+(0.0?1.0:0.0))) )) 2
  done
  for (( dy=int(0); dy<int(3.0); dy++ )); do
    xg_set $(( int(int(hx+2.0)) )) $(( int(int(top+dy+(2.0?1.0:0.0))) )) 2
  done
  return 0
}

xg_cat_play() {
  local -F w=${1:-38.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 13.0 ))
  hy=$(( 10.0 ))
  xg_disk $(( 24.0 )) $(( 13.5 )) $(( 7.0 )) $(( 6.4 )) 1
  xg_seg $(( 29.0 )) $(( 9.0 )) $(( 32.5 )) $(( 5.5 )) $(( 1.6 )) 1
  xg_seg $(( 32.5 )) $(( 5.5 )) $(( 34.5 )) $(( 7.5 )) $(( 1.6 )) 1
  xg_disk $(( 34.5 )) $(( 8.0 )) $(( 1.5 )) $(( 1.7 )) 2
  xg_disk $(( 18.0 )) $(( 16.5 )) $(( 8.0 )) $(( 4.8 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 6.8 )) $(( 5.8 )) 1
  xg_disk $(( hx )) $(( hy+2.0 )) $(( 7.4 )) $(( 3.8 )) 1
  xg_ears $(( hx )) $(( hy )) $(( 0.95 )) 'up'
  xg_seg $(( hx-4.0 )) $(( hy+11.0 )) $(( hx-8.5 )) $(( hy+5.5 )) $(( 1.5 )) 1
  xg_disk $(( hx-9.0 )) $(( hy+4.6 )) $(( 2.0 )) $(( 1.5 )) 3
  xg_disk $(( 20.0 )) $(( 21.2 )) $(( 2.4 )) $(( 1.5 )) 3
  xg_coat_dress $(( hx )) $(( hy ))
  xg_face $(( hx )) $(( hy )) 'open' 'round' 1 1.0
  xg_whiskers $(( hx )) $(( hy )) $(( 0.9 ))
  return 0
}

xg_cat_flop() {   # On its back, paws in the air.  A trap, and everyone knows it.
  local -F w=${1:-34.0}
  local -F h=${2:-18.0}
  local -F cx cy hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-1.0 ))
  cy=$(( 10.5 ))
  xg_disk $(( cx )) $(( cy )) $(( 11.0 )) $(( 5.6 )) 1
  xg_disk $(( cx )) $(( cy-1.0 )) $(( 8.0 )) $(( 3.4 )) 3 "1"
  hx=$(( cx-9.5 ))
  hy=$(( cy-2.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.0 )) $(( 4.4 )) 1
  xg_ears $(( hx )) $(( hy-0.5 )) $(( 0.72 )) 'up'
  xg_seg $(( cx+-3.0 )) $(( cy-3.5 )) $(( cx+-3.0+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+-3.0+0.6 )) $(( cy-7.0 )) $(( 1.2 )) $(( 0.9 )) 3
  xg_seg $(( cx+0.5 )) $(( cy-3.5 )) $(( cx+0.5+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+0.5+0.6 )) $(( cy-7.0 )) $(( 1.2 )) $(( 0.9 )) 3
  xg_seg $(( cx+4.0 )) $(( cy-3.5 )) $(( cx+4.0+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+4.0+0.6 )) $(( cy-7.0 )) $(( 1.2 )) $(( 0.9 )) 3
  xg_seg $(( cx+7.5 )) $(( cy-3.5 )) $(( cx+7.5+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+7.5+0.6 )) $(( cy-7.0 )) $(( 1.2 )) $(( 0.9 )) 3
  xg_seg $(( cx+10.0 )) $(( cy+2.0 )) $(( cx+14.0 )) $(( cy-1.0 )) $(( 1.4 )) 1
  xg_disk $(( cx+14.2 )) $(( cy-1.6 )) $(( 1.3 )) $(( 1.5 )) 2
  xg_coat_dress $(( hx )) $(( hy ))
  xg_face $(( hx )) $(( hy )) 'closed' 'slit' $(( 0 )) $(( 0.75 ))
  return 0
}

xg_dog_bow() {   # The play bow.  Dogs invented it; this one means it.
  local -F w=${1:-38.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 13.0 ))
  hy=$(( 12.0 ))
  xg_disk $(( 24.0 )) $(( 12.5 )) $(( 7.2 )) $(( 6.6 )) 1
  xg_dog_tail $(( 28.0 )) $(( 8.0 )) "${XG[tail]}" 'wag'
  xg_disk $(( 17.0 )) $(( 18.0 )) $(( 8.0 )) $(( 4.6 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 6.2 )) $(( 5.4 )) 1
  xg_disk $(( hx )) $(( hy+1.8 )) $(( 6.7 )) $(( 3.6 )) 1
  xg_dog_ears $(( hx )) $(( hy )) "${XG[ears]}" $(( 0.9 ))
  xg_seg $(( hx-3.0 )) $(( hy+8.5 )) $(( hx-7.5 )) $(( hy+9.5 )) $(( 1.2 )) 1
  xg_disk $(( hx-8.2 )) $(( hy+9.6 )) $(( 1.8 )) $(( 1.2 )) 3
  xg_disk $(( 20.0 )) $(( 21.4 )) $(( 2.5 )) $(( 1.5 )) 3
  xg_dog_dress $(( hx )) $(( hy ))
  xg_dog_face $(( hx )) $(( hy )) 'open' $(( 1 )) '' $(( 0.95 ))
  return 0
}

xg_dog_flop() {   # On the back, paws up, tongue out.  Not a trap.  Dogs mean it.
  local -F w=${1:-34.0}
  local -F h=${2:-18.0}
  local -F cx cy hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-1.0 ))
  cy=$(( 10.5 ))
  xg_disk $(( cx )) $(( cy )) $(( 11.0 )) $(( 5.6 )) 1
  xg_disk $(( cx )) $(( cy-1.0 )) $(( 8.0 )) $(( 3.4 )) 3 "1"
  hx=$(( cx-9.5 ))
  hy=$(( cy-1.6 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.0 )) $(( 4.4 )) 1
  xg_dog_ears $(( hx )) $(( hy-0.5 )) "${XG[ears]}" $(( 0.65 ))
  xg_seg $(( cx+-3.0 )) $(( cy-3.5 )) $(( cx+-3.0+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+-3.0+0.6 )) $(( cy-7.0 )) $(( 1.3 )) $(( 0.9 )) 3
  xg_seg $(( cx+0.5 )) $(( cy-3.5 )) $(( cx+0.5+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+0.5+0.6 )) $(( cy-7.0 )) $(( 1.3 )) $(( 0.9 )) 3
  xg_seg $(( cx+4.0 )) $(( cy-3.5 )) $(( cx+4.0+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+4.0+0.6 )) $(( cy-7.0 )) $(( 1.3 )) $(( 0.9 )) 3
  xg_seg $(( cx+7.5 )) $(( cy-3.5 )) $(( cx+7.5+0.5 )) $(( cy-6.5 )) $(( 1.0 )) 1
  xg_disk $(( cx+7.5+0.6 )) $(( cy-7.0 )) $(( 1.3 )) $(( 0.9 )) 3
  xg_dog_tail $(( cx+10.5 )) $(( cy+1.0 )) "${XG[tail]}" 'wag'
  xg_dog_dress $(( hx )) $(( hy ))
  xg_disk $(( hx-1.2 )) $(( hy+2.0 )) $(( 2.4 )) $(( 1.6 )) 3 "1 2 3 4"
  xg_disk $(( hx-1.8 )) $(( hy+1.6 )) $(( 1.1 )) $(( 0.8 )) 10 "1 2 3 4 3"
  xg_set $(( int(int(hx+0.5)) )) $(( int(int(hy+3.4)) )) 9
  xg_set $(( int(int(hx+1.0)) )) $(( int(int(hy+4.0)) )) 9
  return 0
}

xg_rabbit_binky() {   # Airborne joy, mid-twist.  There is no mistaking a binky.
  local -F w=${1:-36.0}
  local -F h=${2:-28.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 14.0 ))
  hy=$(( 9.0 ))
  xg_disk $(( hx+5.0 )) $(( hy+7.6 )) $(( 8.0 )) $(( 5.0 )) 1
  xg_disk $(( hx+11.5 )) $(( hy+3.8 )) $(( 2.3 )) $(( 2.3 )) 3
  xg_disk $(( hx+10.0 )) $(( hy+11.8 )) $(( 2.8 )) $(( 1.5 )) 1
  xg_disk $(( hx+13.0 )) $(( hy+9.8 )) $(( 2.4 )) $(( 1.3 )) 1
  xg_rabbit_ears $(( hx-2.0 )) $(( hy )) 'up' "${XG[ears]:-up}" $(( 0.9 )) $(( ${XG[ear_l]:-1.0} ))
  xg_disk $(( hx-2.0 )) $(( hy )) $(( 5.4 )) $(( 4.8 )) 1
  xg_rabbit_dress $(( hx-2.0 )) $(( hy ))
  xg_rabbit_face $(( hx-2.0 )) $(( hy )) 'open' '' $(( 0.85 ))
  return 0
}

xg_rabbit_flop() {   # The full sideways collapse of a rabbit at peace.
  local -F w=${1:-38.0}
  local -F h=${2:-18.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 10.0 ))
  xg_disk $(( cx+2.0 )) $(( cy+1.0 )) $(( 11.0 )) $(( 4.4 )) 1
  xg_disk $(( cx+12.0 )) $(( cy-0.6 )) $(( 2.1 )) $(( 2.0 )) 3
  xg_disk $(( cx-8.5 )) $(( cy-0.4 )) $(( 4.3 )) $(( 3.7 )) 1
  xg_seg $(( cx-9.5 )) $(( cy-3.0 )) $(( cx-13.8 )) $(( cy-5.2 )) $(( 1.4 )) 1
  xg_seg $(( cx-7.0 )) $(( cy-3.4 )) $(( cx-10.3 )) $(( cy-6.6 )) $(( 1.4 )) 1
  xg_rabbit_dress $(( cx-8.5 )) $(( cy-0.4 ))
  xg_rabbit_face $(( cx-8.5 )) $(( cy-0.4 )) 'narrow' '' $(( 0.8 ))
  xg_disk $(( cx+4.0 )) $(( cy+4.4 )) $(( 3.0 )) $(( 1.1 )) 2
  return 0
}

xg_hamster_play() {
  local -F hx hy
  xg_px_new $(( int(26.0) )) $(( int(21.0) ))
  hx=$(( 12.0 ))
  hy=$(( 6.0 ))
  xg_disk $(( hx )) $(( hy+7.0 )) $(( 5.8 )) $(( 6.2 )) 1
  xg_disk $(( hx )) $(( hy+8.4 )) $(( 3.8 )) $(( 3.8 )) 3 "1 2"
  xg_ham_ears $(( hx )) $(( hy )) 1.0
  xg_disk $(( hx )) $(( hy )) $(( 5.0 )) $(( 4.2 )) 1
  xg_hamster_dress $(( hx )) $(( hy ))
  xg_ham_face $(( hx )) $(( hy )) 'open' '' 1.0
  xg_disk $(( hx-5.6 )) $(( hy+4.4 )) $(( 1.6 )) $(( 1.1 )) 4
  xg_disk $(( hx+5.6 )) $(( hy+4.4 )) $(( 1.6 )) $(( 1.1 )) 4
  xg_disk $(( hx-2.0 )) $(( hy+12.6 )) $(( 1.7 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.0 )) $(( hy+12.6 )) $(( 1.7 )) $(( 1.0 )) 4
  return 0
}

xg_hamster_flop() {
  local -F w=${1:-28.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 8.2 )) $(( 4.4 )) 1
  xg_disk $(( cx )) $(( cy-0.8 )) $(( 5.2 )) $(( 2.2 )) 3 "1 2"
  xg_disk $(( cx+-1.0*3.0 )) $(( cy-4.0 )) $(( 1.4 )) $(( 0.9 )) 4
  xg_disk $(( cx+-1.0*6.0 )) $(( cy-3.2 )) $(( 1.4 )) $(( 0.9 )) 4
  xg_disk $(( cx+1.0*3.0 )) $(( cy-4.0 )) $(( 1.4 )) $(( 0.9 )) 4
  xg_disk $(( cx+1.0*6.0 )) $(( cy-3.2 )) $(( 1.4 )) $(( 0.9 )) 4
  xg_set $(( int(int(cx-8.0)) )) $(( int(int(cy-1.2)) )) 7
  xg_set $(( int(int(cx-6.8)) )) $(( int(int(cy-1.5)) )) 7
  return 0
}

xg_fox_play() {
  local -F w=${1:-40.0}
  local -F h=${2:-24.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 12.0 ))
  hy=$(( 10.0 ))
  xg_disk $(( hx+10.0 )) $(( hy+4.0 )) $(( 8.0 )) $(( 4.6 )) 1
  xg_disk $(( hx+17.5 )) $(( hy-2.0 )) $(( 4.6 )) $(( 3.4 )) 1
  xg_disk $(( hx+20.0 )) $(( hy-4.2 )) $(( 2.6 )) $(( 2.2 )) 3
  xg_fox_ears $(( hx )) $(( hy )) $(( 0.9 ))
  xg_disk $(( hx )) $(( hy+2.0 )) $(( 5.4 )) $(( 4.6 )) 1
  xg_disk $(( hx )) $(( hy+4.4 )) $(( 3.4 )) $(( 2.8 )) 3 "1 2"
  xg_fox_dress $(( hx )) $(( hy+2.0 ))
  xg_fox_face $(( hx )) $(( hy+2.0 )) 'open' '' $(( 0.85 ))
  xg_disk $(( hx-2.0 )) $(( hy+8.8 )) $(( 1.8 )) $(( 1.2 )) 7
  xg_disk $(( hx+2.6 )) $(( hy+8.8 )) $(( 1.8 )) $(( 1.2 )) 7
  return 0
}

xg_fox_flop() {
  local -F w=${1:-40.0}
  local -F h=${2:-17.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 9.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 11.0 )) $(( 4.4 )) 1
  xg_disk $(( cx-8.8 )) $(( cy-0.6 )) $(( 4.4 )) $(( 3.6 )) 1
  xg_disk $(( cx+10.0 )) $(( cy+1.0 )) $(( 5.2 )) $(( 2.4 )) 1
  xg_disk $(( cx+14.5 )) $(( cy+0.6 )) $(( 2.6 )) $(( 2.0 )) 3
  xg_fox_ears $(( cx-8.8 )) $(( cy-0.6 )) $(( 0.55 ))
  xg_fox_dress $(( cx-8.8 )) $(( cy-0.6 ))
  xg_set $(( int(int(cx-10.2)) )) $(( int(int(cy-1.2)) )) 7
  xg_set $(( int(int(cx-8.6)) )) $(( int(int(cy-1.5)) )) 7
  return 0
}

xg_turtle_play() {
  local -F w=${1:-34.0}
  local -F h=${2:-24.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 12.0 ))
  xg_turtle_head $(( cx-2.0 )) $(( cy-9.4 )) 'open' '' $(( 1.0 ))
  xg_disk $(( cx-1.0 )) $(( cy-5.8 )) $(( 1.9 )) $(( 2.4 )) 4
  xg_turtle_dome $(( cx )) $(( cy )) $(( 9.6 )) $(( 4.8 )) 1
  xg_disk $(( cx-6.5 )) $(( cy+6.6 )) $(( 2.3 )) $(( 1.9 )) 4
  xg_disk $(( cx+6.5 )) $(( cy+6.6 )) $(( 2.3 )) $(( 1.9 )) 4
  xg_disk $(( cx-2.5 )) $(( cy+7.0 )) $(( 2.1 )) $(( 1.7 )) 4
  xg_disk $(( cx+2.5 )) $(( cy+7.0 )) $(( 2.1 )) $(( 1.7 )) 4
  return 0
}

xg_turtle_flop() {
  local -F w=${1:-36.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_turtle_head $(( cx-11.5 )) $(( cy+2.0 )) 'narrow' '' $(( 0.9 ))
  xg_turtle_dome $(( cx )) $(( cy )) $(( 9.6 )) $(( 4.4 )) 1
  xg_disk $(( cx-8.5 )) $(( cy+4.6 )) $(( 2.6 )) $(( 1.2 )) 4
  xg_disk $(( cx+8.5 )) $(( cy+4.6 )) $(( 2.6 )) $(( 1.2 )) 4
  xg_disk $(( cx+9.6 )) $(( cy-1.0 )) $(( 1.4 )) $(( 1.0 )) 4
  return 0
}

xg_hedgehog_play() {
  xg_hedgehog_walk $(( 0.0 )) 32.0 16.0
  return 0
}

xg_hedgehog_flop() {   # The full ball.  Nobody is home.
  local -i pj=${XG[pj]:-0}
  local -F w=${1:-22.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 7.2 )) $(( 5.8 )) 1
  xg_hog_spikes $(( pj )) $(( XG_XPH ))
  xg_hedgehog_dress $(( cx )) $(( cy ))
  return 0
}

xg_glorp_play() {   # Airborne: a delighted column of gel.
  local -F w=${1:-28.0}
  local -F h=${2:-26.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 14.0 ))
  xg_glorp_stalks $(( cx )) $(( cy-3.0 )) 'open' 0.0 $(( 1.05 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6 )) $(( 9.0 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_disk $(( cx-2.4 )) $(( cy-4.6 )) $(( 2.2 )) $(( 1.8 )) 3 "1 2"
  xg_set $(( int(int(cx-1.0)) )) $(( int(int(cy+1.0)) )) 7
  xg_set $(( int(int(cx)) )) $(( int(int(cy+1.4)) )) 7
  xg_set $(( int(int(cx+1.0)) )) $(( int(int(cy+1.0)) )) 7
  return 0
}

xg_glorp_flop() {
  local -F w=${1:-36.0}
  local -F h=${2:-11.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 13.0 )) $(( 3.2 )) 1
  xg_glorp_dress $(( cx )) $(( cy ))
  xg_set $(( int(int(cx-3.0)) )) $(( int(int(cy-2.8)) )) 7
  xg_set $(( int(int(cx+3.0)) )) $(( int(int(cy-2.8)) )) 7
  return 0
}

xg_xeno_play() {   # The pounce posture.  It is playing.  It is definitely playing.
  local -F w=${1:-40.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 12.0 ))
  hy=$(( 11.0 ))
  xg_disk $(( hx+9.0 )) $(( hy+5.0 )) $(( 8.2 )) $(( 4.8 )) 1
  xg_xeno_tail $(( hx+15.0 )) $(( hy+1.0 )) $(( 1.0 )) 1
  xg_disk $(( hx+3.0 )) $(( hy+3.2 )) $(( 1.5 )) $(( 2.4 )) 2
  xg_disk $(( hx+6.6 )) $(( hy+2.6 )) $(( 1.5 )) $(( 2.4 )) 2
  xg_disk $(( hx )) $(( hy+3.0 )) $(( 4.2 )) $(( 3.8 )) 1
  xg_xeno_dress $(( hx )) $(( hy+1.0 ))
  xg_xeno_head $(( hx )) $(( hy+1.0 )) 'wail' $(( 0.9 ))
  xg_disk $(( hx-2.2 )) $(( hy+9.6 )) $(( 2.0 )) $(( 1.2 )) 2
  xg_disk $(( hx+2.6 )) $(( hy+9.6 )) $(( 2.0 )) $(( 1.2 )) 2
  return 0
}

xg_xeno_flop() {   # Belly up.  The crew of the Nostromo would not believe this.
  local -F w=${1:-42.0}
  local -F h=${2:-16.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 9.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 11.0 )) $(( 4.4 )) 1
  xg_disk $(( cx )) $(( cy-1.2 )) $(( 6.6 )) $(( 2.2 )) 2 "1"
  xg_disk $(( cx-9.5 )) $(( cy-1.0 )) $(( 3.6 )) $(( 4.4 )) 1
  xg_disk $(( cx-10.3 )) $(( cy-2.6 )) $(( 2.0 )) $(( 2.2 )) 3 "1 2"
  xg_disk $(( cx+-1.0*3.4 )) $(( cy-4.4 )) $(( 1.5 )) $(( 1.6 )) 2
  xg_disk $(( cx+-1.0*6.6 )) $(( cy-3.6 )) $(( 1.5 )) $(( 1.4 )) 2
  xg_disk $(( cx+1.0*3.4 )) $(( cy-4.4 )) $(( 1.5 )) $(( 1.6 )) 2
  xg_disk $(( cx+1.0*6.6 )) $(( cy-3.6 )) $(( 1.5 )) $(( 1.4 )) 2
  xg_xeno_tail $(( cx+9.0 )) $(( cy+2.0 )) $(( 0.9 )) 1
  xg_xeno_dress $(( cx-9.5 )) $(( cy-1.0 ))
  xg_set $(( int(int(cx-9.5+-1.0)) )) $(( int(int(cy+1.2)) )) $(( ((-1.0%2.0+2.0)%2.0==0.0)?3:7 ))
  xg_set $(( int(int(cx-9.5+0.0)) )) $(( int(int(cy+1.2)) )) $(( ((0.0%2.0+2.0)%2.0==0.0)?3:7 ))
  xg_set $(( int(int(cx-9.5+1.0)) )) $(( int(int(cy+1.2)) )) $(( ((1.0%2.0+2.0)%2.0==0.0)?3:7 ))
  return 0
}

xg_duck_play() {   # Wings OUT.  Everyone will hear about this.
  local -F w=${1:-34.0}
  local -F h=${2:-22.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx )) $(( hy+9.5 )) $(( 6.6 )) $(( 5.0 )) 1
  xg_disk $(( hx-8.5 )) $(( hy+7.0 )) $(( 4.2 )) $(( 2.2 )) 2
  xg_disk $(( hx+8.5 )) $(( hy+7.0 )) $(( 4.2 )) $(( 2.2 )) 2
  xg_disk $(( hx-10.5 )) $(( hy+6.4 )) $(( 2.0 )) $(( 1.4 )) 3
  xg_disk $(( hx+10.5 )) $(( hy+6.4 )) $(( 2.0 )) $(( 1.4 )) 3
  xg_disk $(( hx )) $(( hy+3.5 )) $(( 2.0 )) $(( 2.6 )) 1
  xg_disk $(( hx )) $(( hy )) $(( 3.7 )) $(( 3.3 )) 1
  xg_duck_dress $(( hx )) $(( hy ))
  xg_duck_face $(( hx )) $(( hy )) 'open' 'wail' 1.0
  xg_disk $(( hx-1.5 )) $(( hy+14.6 )) $(( 1.7 )) $(( 1.0 )) 4
  xg_disk $(( hx+1.5 )) $(( hy+14.6 )) $(( 1.7 )) $(( 1.0 )) 4
  return 0
}

xg_duck_flop() {
  local -F w=${1:-30.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 9.0 )) $(( 4.0 )) 1
  xg_disk $(( cx-8.0 )) $(( cy-1.0 )) $(( 3.0 )) $(( 2.4 )) 1
  xg_disk $(( cx-10.4 )) $(( cy-0.6 )) $(( 2.2 )) $(( 0.9 )) 4
  xg_duck_dress $(( cx-8.0 )) $(( cy-1.0 ))
  xg_set $(( int(int(cx-8.5)) )) $(( int(int(cy-2.0)) )) 7
  xg_disk $(( cx+7.0 )) $(( cy+2.6 )) $(( 1.7 )) $(( 0.9 )) 4
  xg_disk $(( cx+4.0 )) $(( cy+3.0 )) $(( 1.7 )) $(( 0.9 )) 4
  return 0
}

xg_frog_play() {   # Mid-leap.  Physics is a suggestion.
  local -F w=${1:-34.0}
  local -F h=${2:-24.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 12.0 ))
  hy=$(( 8.0 ))
  xg_disk $(( hx+6.0 )) $(( hy+3.0 )) $(( 7.0 )) $(( 3.8 )) 1
  xg_seg $(( hx+11.0 )) $(( hy+5.5 )) $(( hx+17.5 )) $(( hy+11.0 )) $(( 1.9 )) 1
  xg_seg $(( hx-2.0 )) $(( hy+6.0 )) $(( hx-6.0 )) $(( hy+11.5 )) $(( 1.6 )) 1
  xg_set $(( int(int(hx+18.5)) )) $(( int(int(hy+12.0)) )) 4
  xg_set $(( int(int(hx-7.0)) )) $(( int(int(hy+12.5)) )) 4
  xg_disk $(( hx )) $(( hy )) $(( 4.8 )) $(( 3.2 )) 1
  xg_frog_dress $(( hx )) $(( hy ))
  xg_frog_face $(( hx )) $(( hy )) 'open' 'wail' $(( 0.9 ))
  return 0
}

xg_frog_flop() {
  local -F w=${1:-32.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 6.0 ))
  xg_disk $(( cx )) $(( cy+1.0 )) $(( 8.4 )) $(( 3.6 )) 1
  xg_disk $(( cx )) $(( cy-1.5 )) $(( 5.2 )) $(( 2.4 )) 1
  xg_disk $(( cx+-1.0*2.8 )) $(( cy-2.8 )) $(( 1.5 )) $(( 1.3 )) 1
  xg_set $(( int(int(cx+-1.0*2.8)) )) $(( int(int(cy-3.0)) )) 7
  xg_disk $(( cx+1.0*2.8 )) $(( cy-2.8 )) $(( 1.5 )) $(( 1.3 )) 1
  xg_set $(( int(int(cx+1.0*2.8)) )) $(( int(int(cy-3.0)) )) 7
  xg_seg $(( cx+7.5 )) $(( cy+2.5 )) $(( cx+12.5 )) $(( cy+3.5 )) $(( 1.4 )) 1
  xg_seg $(( cx-7.5 )) $(( cy+2.5 )) $(( cx-12.5 )) $(( cy+3.5 )) $(( 1.4 )) 1
  xg_frog_dress $(( cx )) $(( cy ))
  return 0
}

xg_snake_play() {   # The raised S: play-striking at nothing in particular.
  local -F w=${1:-32.0}
  local -F h=${2:-24.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0-2.0 ))
  cy=$(( 14.0 ))
  xg_disk $(( cx )) $(( cy+5.0 )) $(( 8.0 )) $(( 3.0 )) 1
  xg_seg $(( cx-2.0 )) $(( cy+3.0 )) $(( cx+4.0 )) $(( cy-1.0 )) $(( 2.0 )) 1
  xg_seg $(( cx+4.0 )) $(( cy-1.0 )) $(( cx-1.0 )) $(( cy-5.0 )) $(( 2.0 )) 1
  xg_seg $(( cx-1.0 )) $(( cy-5.0 )) $(( cx+3.0 )) $(( cy-8.5 )) $(( 2.0 )) 1
  xg_snake_dress $(( cx )) $(( cy ))
  xg_snake_head $(( cx+3.6 )) $(( cy-10.4 )) 'open' $(( 1 )) 1.0
  return 0
}

xg_snake_flop() {   # Longboi mode: the full length, published.
  local -F w=${1:-46.0}
  local -F h=${2:-10.0}
  xg_px_new $(( int(w) )) $(( int(h) ))
  xg_seg $(( 3.0 )) $(( 6.0 )) $(( 14.0 )) $(( 5.2 )) $(( 2.2 )) 1
  xg_seg $(( 14.0 )) $(( 5.2 )) $(( 26.0 )) $(( 6.4 )) $(( 2.2 )) 1
  xg_seg $(( 26.0 )) $(( 6.4 )) $(( 38.0 )) $(( 5.4 )) $(( 2.2 )) 1
  xg_snake_dress $(( 22.0 )) $(( 5.0 ))
  xg_snake_head $(( 41.5 )) $(( 4.4 )) 'narrow' $(( 0 )) $(( 0.95 ))
  return 0
}

xg_owl_play() {   # Wings out: either joy or a very strong opinion.
  local -F w=${1:-36.0}
  local -F h=${2:-22.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0 ))
  hy=$(( 5.0 ))
  xg_disk $(( hx )) $(( hy+8.5 )) $(( 5.8 )) $(( 6.0 )) 1
  xg_disk $(( hx-9.0 )) $(( hy+6.0 )) $(( 4.6 )) $(( 2.2 )) 1
  xg_disk $(( hx+9.0 )) $(( hy+6.0 )) $(( 4.6 )) $(( 2.2 )) 1
  xg_disk $(( hx-11.5 )) $(( hy+5.4 )) $(( 2.2 )) $(( 1.5 )) 2
  xg_disk $(( hx+11.5 )) $(( hy+5.4 )) $(( 2.2 )) $(( 1.5 )) 2
  xg_disk $(( hx )) $(( hy )) $(( 5.2 )) $(( 4.2 )) 1
  xg_owl_dress $(( hx )) $(( hy ))
  xg_owl_face $(( hx )) $(( hy )) 'open' 'wail' $(( 0.95 )) 0
  return 0
}

xg_owl_flop() {
  local -F w=${1:-32.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 8.0 )) $(( 4.6 )) 1
  xg_disk $(( cx )) $(( cy-1.0 )) $(( 4.6 )) $(( 2.6 )) 3 "1 2"
  xg_disk $(( cx-9.5 )) $(( cy-1.5 )) $(( 3.4 )) $(( 1.8 )) 2
  xg_disk $(( cx+9.5 )) $(( cy-1.5 )) $(( 3.4 )) $(( 1.8 )) 2
  xg_disk $(( cx-1.0 )) $(( cy-3.6 )) $(( 3.6 )) $(( 2.4 )) 1
  xg_set $(( int(int(cx-2.2)) )) $(( int(int(cy-4.0)) )) 7
  xg_set $(( int(int(cx+0.2)) )) $(( int(int(cy-4.0)) )) 7
  xg_owl_dress $(( cx )) $(( cy ))
  return 0
}

xg_pig_play() {   # Zoomies, full size: front down, everything else airborne.
  local -F w=${1:-34.0}
  local -F h=${2:-24.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( 11.0 ))
  hy=$(( 11.0 ))
  xg_disk $(( hx+8.0 )) $(( hy+3.0 )) $(( 8.2 )) $(( 5.2 )) 1
  xg_pig_tail $(( hx+16.0 )) $(( hy-0.5 ))
  xg_pig_ears $(( hx )) $(( hy )) $(( 0.9 ))
  xg_disk $(( hx )) $(( hy+2.0 )) $(( 5.2 )) $(( 4.4 )) 1
  xg_pig_dress $(( hx )) $(( hy+2.0 ))
  xg_pig_face $(( hx )) $(( hy+2.0 )) 'open' 'wail' $(( 0.9 ))
  xg_disk $(( hx-1.5 )) $(( hy+8.4 )) $(( 1.8 )) $(( 1.2 )) 4
  xg_disk $(( hx+3.0 )) $(( hy+8.4 )) $(( 1.8 )) $(( 1.2 )) 4
  xg_disk $(( hx+12.5 )) $(( hy+8.0 )) $(( 1.8 )) $(( 1.2 )) 4
  return 0
}

xg_pig_flop() {   # The mud flop, belly up, hooves to the stars.
  local -F w=${1:-36.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 8.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 10.0 )) $(( 4.6 )) 1
  xg_disk $(( cx )) $(( cy-1.0 )) $(( 6.2 )) $(( 2.6 )) 3 "1 2"
  xg_disk $(( cx+-1.0*3.4 )) $(( cy-4.6 )) $(( 1.6 )) $(( 1.2 )) 4
  xg_disk $(( cx+-1.0*6.8 )) $(( cy-3.8 )) $(( 1.6 )) $(( 1.2 )) 4
  xg_disk $(( cx+1.0*3.4 )) $(( cy-4.6 )) $(( 1.6 )) $(( 1.2 )) 4
  xg_disk $(( cx+1.0*6.8 )) $(( cy-3.8 )) $(( 1.6 )) $(( 1.2 )) 4
  xg_disk $(( cx-9.5 )) $(( cy+0.5 )) $(( 3.4 )) $(( 2.8 )) 1
  xg_pig_ears $(( cx-9.5 )) $(( cy+0.5 )) $(( 0.6 ))
  xg_disk $(( cx-11.5 )) $(( cy+1.5 )) $(( 1.7 )) $(( 1.3 )) 9
  xg_pig_dress $(( cx-9.5 )) $(( cy ))
  xg_pig_tail $(( cx+9.8 )) $(( cy-1.0 ))
  return 0
}

xg_axolotl_play() {   # The wiggle, mid-frame.  Joy has a shape and it is this.
  local -F w=${1:-30.0}
  local -F h=${2:-20.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-2.0 ))
  hy=$(( 6.0 ))
  xg_disk $(( hx+3.0 )) $(( hy+6.0 )) $(( 7.0 )) $(( 4.0 )) 1
  xg_disk $(( hx+9.5 )) $(( hy+2.5 )) $(( 3.2 )) $(( 3.6 )) 1
  xg_disk $(( hx+10.3 )) $(( hy+0.8 )) $(( 1.8 )) $(( 1.8 )) 3 "1 2"
  xg_axo_gills $(( hx )) $(( hy )) $(( 1.05 )) 0.0
  xg_disk $(( hx )) $(( hy )) $(( 5.0 )) $(( 4.2 )) 1
  xg_axo_dress $(( hx )) $(( hy ))
  xg_axo_face $(( hx )) $(( hy )) 'open' 'wail' 1.0
  return 0
}

xg_axolotl_flop() {
  local -F w=${1:-32.0}
  local -F h=${2:-13.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( 7.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 9.2 )) $(( 3.8 )) 1
  xg_disk $(( cx )) $(( cy-1.2 )) $(( 5.6 )) $(( 2.0 )) 3 "1 2"
  xg_disk $(( cx-8.0 )) $(( cy-1.0 )) $(( 3.6 )) $(( 3.0 )) 1
  xg_axo_gills $(( cx-8.0 )) $(( cy-1.0 )) $(( 0.75 )) $(( 0.2 ))
  xg_axo_dress $(( cx-8.0 )) $(( cy-1.0 ))
  xg_axo_face $(( cx-8.0 )) $(( cy-1.0 )) 'open' '' $(( 0.75 ))
  xg_disk $(( cx+9.5 )) $(( cy-0.5 )) $(( 2.0 )) $(( 2.2 )) 1
  return 0
}

# ── WHICH WAY THE ART FACES ──────────────────────────────────────────────
# The cabinet mirrors a body when it is walking left.  That is only correct
# if the body was DRAWN facing right -- and most of this intake was not.  The
# cat, the dog and the snake were drawn nose-right; the fox, the rabbit, the
# duck and eight others were drawn nose-LEFT, and mirroring those on the way
# left made them moonwalk the room.  So each species says which way its own
# art faces, and the mirror happens only when the art and the direction of
# travel disagree.  A glorp is a blob with two stalks and an owl looks
# straight at you: neither has a front, so both are called right-facing and
# neither can look wrong.
typeset -gA XG_SP_FACE
XG_SP_FACE[cat]=1   XG_SP_FACE[dog]=1     XG_SP_FACE[snake]=1   XG_SP_FACE[glorp]=1
XG_SP_FACE[owl]=1   XG_SP_FACE[rabbit]=-1 XG_SP_FACE[hamster]=-1 XG_SP_FACE[fox]=-1
XG_SP_FACE[turtle]=-1 XG_SP_FACE[hedgehog]=-1 XG_SP_FACE[xeno]=-1 XG_SP_FACE[duck]=-1
XG_SP_FACE[frog]=-1 XG_SP_FACE[pig]=-1    XG_SP_FACE[axolotl]=-1
# AND WHERE ONE POSE DISAGREES WITH ITS OWN SPECIES.  The eleven left-drawn
# animals are left-drawn in every pose, so one value covers them.  The cat and
# the dog are not: only their WALK was drawn nose-right, and their pounce, bow
# and flop all face the other way.  Those are named here, species.pose first.
XG_SP_FACE[cat.play]=-1  XG_SP_FACE[cat.flop]=-1
XG_SP_FACE[dog.play]=-1  XG_SP_FACE[dog.flop]=-1
# An owl has no front standing up, so its walk is called right-facing on a
# coin toss -- but on its back it plainly has one, and it is the other way.
XG_SP_FACE[owl.flop]=-1

# ── which body · sit · baby · loaf · sleep · walk · play · flop ───────────
#    The cat and the dog answer to their own names here (a dog does not loaf,
#    it sploots; a rabbit does not walk, it hops); the rest are regular.
# ══ TEN MORE BODIES · sd/newspec.py ══
# ── EARTH GUINEA PIG · CAVIA PORCELLUS ──
xg_guineapig_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( hx-2.4*s )) $(( hy+0.75*s )) $(( 1.05*s )) $(( 2.25*s )) 1
  xg_disk $(( hx+2.4*s )) $(( hy+0.75*s )) $(( 1.05*s )) $(( 2.25*s )) 1
  return 0
}
xg_guineapig_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  return 0
}
xg_guineapig_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.8*s ))
  exr=$(( hx+2.8*s ))
  ey=$(( hy+-0.6*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.25*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.25*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+2.4*s )) $(( 2.6*s )) $(( 1.7*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+1.9*s )) $(( 0.85*s )) $(( 0.62*s )) 10 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+3.3*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+4.1*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+3.3*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+3.3*s) )) 2
  fi
  return 0
}
xg_guineapig_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    agouti)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    roan)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    broken)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    crested)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
  esac
  return 0
}
xg_guineapig_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-28.0}
  local -F h=${4:-31.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=7.0
  xg_disk $(( hx )) $(( hy+7.0 )) $(( 7.4 )) $(( 6.2 )) 1
  xg_disk $(( hx )) $(( hy+10.0 )) $(( 4.2 )) $(( 2.4 )) 3 "1 2"
  xg_guineapig_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.4*1.0 )) $(( 4.0*1.0 )) 1
  xg_guineapig_dress $(( hx )) $(( hy ))
  xg_guineapig_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-2.8 )) $(( hy+13.58 )) $(( 1.7 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.8 )) $(( hy+13.58 )) $(( 1.7 )) $(( 1.0 )) 4
  return 0
}
xg_guineapig_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=7.24
  xg_disk $(( hx )) $(( hy+4.44 )) $(( 5.33 )) $(( 4.46 )) 1
  xg_guineapig_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.4*0.94 )) $(( 4.0*0.94 )) 1
  xg_guineapig_dress $(( hx )) $(( hy ))
  xg_guineapig_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-2.02 )) $(( hy+8.80 )) $(( 1.22 )) $(( 0.72 )) 4
  xg_disk $(( hx+2.02 )) $(( hy+8.80 )) $(( 1.22 )) $(( 0.72 )) 4
  return 0
}
xg_guineapig_loaf() {
  local -F w=${1:-26.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.0
  xg_disk $(( hx )) $(( hy+7.7 )) $(( 7.77 )) $(( 4.46 )) 1
  xg_guineapig_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 5.4*0.92 )) $(( 4.0*0.92 )) 1
  xg_guineapig_dress $(( hx )) $(( hy ))
  xg_guineapig_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_guineapig_sleep() {
  local -F w=${1:-30.0}
  local -F h=${2:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 8.29 )) $(( 4.84 )) 1
  xg_disk $(( cx-6.36 )) $(( cy-0.5 )) $(( 4.97 )) $(( 3.68 )) 1
  xg_guineapig_ears $(( cx-6.36 )) $(( cy-0.5 )) 0.8
  xg_guineapig_dress $(( cx-6.36 )) $(( cy-0.5 ))
  xg_guineapig_face $(( cx-6.36 )) $(( cy-0.5 )) closed "" 0.9
  return 0
}
xg_guineapig_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-39.0}
  local -F h=${3:-28.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=8.4
  hy=7.0
  xg_disk $(( hx+7.03 )) $(( hy+4.65 )) $(( 7.4 )) $(( 4.96 )) 1
  xg_guineapig_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 5.4*0.94 )) $(( 4.0*0.94 )) 1
  xg_guineapig_dress $(( hx )) $(( hy+1.0 ))
  xg_guineapig_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+9.61 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+2.59 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+7.77 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+11.84 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  else
    xg_disk $(( hx+4.07 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+9.62 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+13.69 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  fi
  return 0
}
xg_guineapig_play() {
  local -F w=${1:-37.0}
  local -F h=${2:-28.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=8.4
  hy=9.0
  xg_disk $(( hx+8.51 )) $(( hy-1.55 )) $(( 7.03 )) $(( 5.33 )) 1
  xg_guineapig_ears $(( hx )) $(( hy+3.41 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+3.41 )) $(( 5.4*0.96 )) $(( 4.0*0.96 )) 1
  xg_guineapig_dress $(( hx )) $(( hy+3.41 ))
  xg_guineapig_face $(( hx )) $(( hy+3.41 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+2.59 )) $(( hy+6.51 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+5.92 )) $(( hy+6.51 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+12.95 )) $(( hy+3.41 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+15.17 )) $(( hy+3.41 )) $(( 1.44 )) $(( 0.85 )) 4
  return 0
}
xg_guineapig_flop() {
  local -F w=${1:-30.0}
  local -F h=${2:-28.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-9.2 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 7.99 )) $(( 4.96 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.86 )) $(( 4.83 )) $(( 2.16 )) 3 "1 2"
  xg_disk $(( cx-6.81 )) $(( cy-0.5 )) $(( 5.08 )) $(( 3.76 )) 1
  xg_guineapig_ears $(( cx-6.81 )) $(( cy-0.5 )) 0.85
  xg_guineapig_dress $(( cx-6.81 )) $(( cy-0.5 ))
  xg_guineapig_face $(( cx-6.81 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-1.85 )) $(( cy-5.89 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+2.22 )) $(( cy-5.89 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+7.03 )) $(( cy-5.89 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+9.99 )) $(( cy-5.89 )) $(( 1.36 )) $(( 0.8 )) 4
  return 0
}
# ── EARTH FERRET · MUSTELA FURO ──
xg_ferret_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( hx-1.45*s )) $(( hy-0.95*s )) $(( 0.85*s )) $(( 0.85*s )) 1
  xg_disk $(( hx-1.45*s )) $(( hy-0.85*s )) $(( 0.42*s )) $(( 0.42*s )) 9 "1 2"
  xg_disk $(( hx+1.45*s )) $(( hy-0.95*s )) $(( 0.85*s )) $(( 0.85*s )) 1
  xg_disk $(( hx+1.45*s )) $(( hy-0.85*s )) $(( 0.42*s )) $(( 0.42*s )) 9 "1 2"
  return 0
}
xg_ferret_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  xg_seg $(( x )) $(( y )) $(( x+4.4*s )) $(( y-0.96*s )) $(( 2.32*s )) 1
  xg_seg $(( x+4.4*s )) $(( y-0.96*s )) $(( x+7.2*s )) $(( y-3.36*s )) $(( 1.6*s )) 1
  return 0
}
xg_ferret_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.0*s ))
  exr=$(( hx+2.0*s ))
  ey=$(( hy+-0.6*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.05*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.05*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+1.9*s )) $(( 1.9*s )) $(( 1.6*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+1.7*s )) $(( 0.85*s )) $(( 0.62*s )) 10 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+3.0*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+3.8*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+3.0*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+3.0*s) )) 2
  fi
  return 0
}
xg_ferret_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    mitted)
      xg_dj $pj 3 0.62 0.90; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.3+x*1.9+pj*0.53)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    roan)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    blaze)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
  esac
  return 0
}
xg_ferret_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-32.0}
  local -F h=${4:-36.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.4
  xg_disk $(( hx )) $(( hy+11.6 )) $(( 5.2 )) $(( 6.6 )) 1
  xg_ferret_tail $(( hx+4.58 )) $(( hy+10.61 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy+12.6 )) $(( 2.8 )) $(( 3.0 )) 3 "1 2"
  xg_seg $(( hx )) $(( hy+1.87*1.0 )) $(( hx )) $(( hy+6.38 )) $(( 2.42*1.0 )) 1
  xg_ferret_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 3.9*1.0 )) $(( 3.4*1.0 )) 1
  xg_ferret_dress $(( hx )) $(( hy ))
  xg_ferret_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-2.9 )) $(( hy+18.57 )) $(( 1.7 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.9 )) $(( hy+18.57 )) $(( 1.7 )) $(( 1.0 )) 4
  return 0
}
xg_ferret_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=6.68
  xg_disk $(( hx )) $(( hy+7.35 )) $(( 3.74 )) $(( 4.75 )) 1
  xg_ferret_tail $(( hx+3.29 )) $(( hy+6.72 )) $(( 0.72 ))
  xg_seg $(( hx )) $(( hy+1.87*0.94 )) $(( hx )) $(( hy+4.18 )) $(( 2.42*0.94 )) 1
  xg_ferret_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 3.9*0.94 )) $(( 3.4*0.94 )) 1
  xg_ferret_dress $(( hx )) $(( hy ))
  xg_ferret_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-2.09 )) $(( hy+12.03 )) $(( 1.22 )) $(( 0.72 )) 4
  xg_disk $(( hx+2.09 )) $(( hy+12.03 )) $(( 1.22 )) $(( 0.72 )) 4
  return 0
}
xg_ferret_loaf() {
  local -F w=${1:-27.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=5.4
  xg_disk $(( hx )) $(( hy+8.1 )) $(( 5.46 )) $(( 4.75 )) 1
  xg_ferret_tail $(( hx+4.58 )) $(( hy+8.91 )) $(( 0.9 ))
  xg_seg $(( hx )) $(( hy+1.87*0.92 )) $(( hx )) $(( hy+6.27 )) $(( 2.42*0.92 )) 1
  xg_ferret_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 3.9*0.92 )) $(( 3.4*0.92 )) 1
  xg_ferret_dress $(( hx )) $(( hy ))
  xg_ferret_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_ferret_sleep() {
  local -F w=${1:-30.0}
  local -F h=${2:-21.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 5.82 )) $(( 5.15 )) 1
  xg_disk $(( cx-4.47 )) $(( cy-0.5 )) $(( 3.59 )) $(( 3.13 )) 1
  xg_ferret_ears $(( cx-4.47 )) $(( cy-0.5 )) 0.8
  xg_ferret_dress $(( cx-4.47 )) $(( cy-0.5 ))
  xg_ferret_face $(( cx-4.47 )) $(( cy-0.5 )) closed "" 0.9
  xg_ferret_tail $(( cx+5.46 )) $(( cy-1.0 )) $(( 0.9 ))
  return 0
}
xg_ferret_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-38.0}
  local -F h=${3:-28.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=6.9
  hy=6.4
  xg_disk $(( hx+4.94 )) $(( hy+4.95 )) $(( 5.2 )) $(( 5.28 )) 1
  xg_ferret_tail $(( hx+10.14 )) $(( hy+1.65 )) $(( 1.0 ))
  xg_seg $(( hx )) $(( hy+1.0+1.87*0.94 )) $(( hx )) $(( hy+1.0+3.3 )) $(( 2.42*0.94 )) 1
  xg_ferret_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 3.9*0.94 )) $(( 3.4*0.94 )) 1
  xg_ferret_dress $(( hx )) $(( hy+1.0 ))
  xg_ferret_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+10.23 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+1.82 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+5.46 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+8.32 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  else
    xg_disk $(( hx+2.86 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+6.76 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+9.62 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  fi
  return 0
}
xg_ferret_play() {
  local -F w=${1:-36.0}
  local -F h=${2:-28.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=6.9
  hy=8.4
  xg_disk $(( hx+5.98 )) $(( hy-1.65 )) $(( 4.94 )) $(( 5.68 )) 1
  xg_ferret_tail $(( hx+10.4 )) $(( hy-6.93 )) $(( 1.0 ))
  xg_seg $(( hx )) $(( hy+3.63+1.87*0.96 )) $(( hx )) $(( hy+3.63+2.97 )) $(( 2.42*0.96 )) 1
  xg_ferret_ears $(( hx )) $(( hy+3.63 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+3.63 )) $(( 3.9*0.96 )) $(( 3.4*0.96 )) 1
  xg_ferret_dress $(( hx )) $(( hy+3.63 ))
  xg_ferret_face $(( hx )) $(( hy+3.63 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+1.82 )) $(( hy+6.93 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+4.16 )) $(( hy+6.93 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+9.1 )) $(( hy+3.63 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+10.66 )) $(( hy+3.63 )) $(( 1.44 )) $(( 0.85 )) 4
  return 0
}
xg_ferret_flop() {
  local -F w=${1:-30.0}
  local -F h=${2:-28.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-9.6 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 5.62 )) $(( 5.28 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.98 )) $(( 3.22 )) $(( 2.7 )) 3 "1 2"
  xg_disk $(( cx-4.78 )) $(( cy-0.5 )) $(( 3.67 )) $(( 3.20 )) 1
  xg_ferret_ears $(( cx-4.78 )) $(( cy-0.5 )) 0.85
  xg_ferret_dress $(( cx-4.78 )) $(( cy-0.5 ))
  xg_ferret_face $(( cx-4.78 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-1.3 )) $(( cy-6.27 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+1.56 )) $(( cy-6.27 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+4.94 )) $(( cy-6.27 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+7.02 )) $(( cy-6.27 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_ferret_tail $(( cx+5.46 )) $(( cy+1.0 )) $(( 0.9 ))
  return 0
}
# ── EARTH RAT · RATTUS NORVEGICUS ──
xg_rat_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( hx-2.6*s )) $(( hy-3.1*s )) $(( 2.1*s )) $(( 2.7*s )) 1
  xg_disk $(( hx-2.6*s )) $(( hy-3.0*s )) $(( 1.04*s )) $(( 1.56*s )) 9 "1 2"
  xg_disk $(( hx+2.6*s )) $(( hy-3.1*s )) $(( 2.1*s )) $(( 2.7*s )) 1
  xg_disk $(( hx+2.6*s )) $(( hy-3.0*s )) $(( 1.04*s )) $(( 1.56*s )) 9 "1 2"
  return 0
}
xg_rat_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  xg_seg $(( x )) $(( y )) $(( x+6.3*s )) $(( y+3.9*s )) $(( 0.99*s )) 4
  xg_seg $(( x+6.3*s )) $(( y+3.9*s )) $(( x+10.8*s )) $(( y-1.5*s )) $(( 0.77*s )) 4
  return 0
}
xg_rat_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.2*s ))
  exr=$(( hx+2.2*s ))
  ey=$(( hy+-0.6*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.1*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.1*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+2.0*s )) $(( 1.7*s )) $(( 1.9*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+2.4*s )) $(( 0.85*s )) $(( 0.62*s )) 10 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+3.4*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+4.2*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+3.4*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+3.4*s) )) 2
  fi
  return 0
}
xg_rat_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    hooded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    roan)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    broken)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
  esac
  return 0
}
xg_rat_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-41.0}
  local -F h=${4:-31.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.4
  xg_disk $(( hx )) $(( hy+8.8 )) $(( 6.6 )) $(( 5.2 )) 1
  xg_rat_tail $(( hx+5.81 )) $(( hy+8.02 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy+11.2 )) $(( 3.4 )) $(( 2.0 )) 3 "1 2"
  xg_rat_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*1.0 )) $(( 3.4*1.0 )) 1
  xg_rat_dress $(( hx )) $(( hy ))
  xg_rat_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-3.0 )) $(( hy+14.40 )) $(( 1.7 )) $(( 1.0 )) 4
  xg_disk $(( hx+3.0 )) $(( hy+14.40 )) $(( 1.7 )) $(( 1.0 )) 4
  return 0
}
xg_rat_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=6.68
  xg_disk $(( hx )) $(( hy+5.58 )) $(( 4.75 )) $(( 3.74 )) 1
  xg_rat_tail $(( hx+4.18 )) $(( hy+5.08 )) $(( 0.72 ))
  xg_rat_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*0.94 )) $(( 3.4*0.94 )) 1
  xg_rat_dress $(( hx )) $(( hy ))
  xg_rat_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-2.16 )) $(( hy+9.33 )) $(( 1.22 )) $(( 0.72 )) 4
  xg_disk $(( hx+2.16 )) $(( hy+9.33 )) $(( 1.22 )) $(( 0.72 )) 4
  return 0
}
xg_rat_loaf() {
  local -F w=${1:-35.0}
  local -F h=${2:-23.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=5.4
  xg_disk $(( hx )) $(( hy+6.7 )) $(( 6.93 )) $(( 3.74 )) 1
  xg_rat_tail $(( hx+5.81 )) $(( hy+7.02 )) $(( 0.9 ))
  xg_rat_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*0.92 )) $(( 3.4*0.92 )) 1
  xg_rat_dress $(( hx )) $(( hy ))
  xg_rat_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_rat_sleep() {
  local -F w=${1:-37.0}
  local -F h=${2:-18.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 7.39 )) $(( 4.06 )) 1
  xg_disk $(( cx-5.68 )) $(( cy-0.5 )) $(( 3.86 )) $(( 3.13 )) 1
  xg_rat_ears $(( cx-5.68 )) $(( cy-0.5 )) 0.8
  xg_rat_dress $(( cx-5.68 )) $(( cy-0.5 ))
  xg_rat_face $(( cx-5.68 )) $(( cy-0.5 )) closed "" 0.9
  xg_rat_tail $(( cx+6.93 )) $(( cy-1.0 )) $(( 0.9 ))
  return 0
}
xg_rat_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-47.0}
  local -F h=${3:-25.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.2
  hy=6.4
  xg_disk $(( hx+6.27 )) $(( hy+3.9 )) $(( 6.6 )) $(( 4.16 )) 1
  xg_rat_tail $(( hx+12.87 )) $(( hy+1.3 )) $(( 1.0 ))
  xg_rat_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 4.2*0.94 )) $(( 3.4*0.94 )) 1
  xg_rat_dress $(( hx )) $(( hy+1.0 ))
  xg_rat_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+8.06 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+2.31 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+6.93 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+10.56 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  else
    xg_disk $(( hx+3.63 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+8.58 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+12.21 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  fi
  return 0
}
xg_rat_play() {
  local -F w=${1:-45.0}
  local -F h=${2:-25.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.2
  hy=8.4
  xg_disk $(( hx+7.59 )) $(( hy-1.3 )) $(( 6.27 )) $(( 4.47 )) 1
  xg_rat_tail $(( hx+13.2 )) $(( hy-5.46 )) $(( 1.0 ))
  xg_rat_ears $(( hx )) $(( hy+2.86 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+2.86 )) $(( 4.2*0.96 )) $(( 3.4*0.96 )) 1
  xg_rat_dress $(( hx )) $(( hy+2.86 ))
  xg_rat_face $(( hx )) $(( hy+2.86 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+2.31 )) $(( hy+5.46 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+5.28 )) $(( hy+5.46 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+11.55 )) $(( hy+2.86 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+13.53 )) $(( hy+2.86 )) $(( 1.44 )) $(( 0.85 )) 4
  return 0
}
xg_rat_flop() {
  local -F w=${1:-37.0}
  local -F h=${2:-25.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-8.2 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 7.13 )) $(( 4.16 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.56 )) $(( 3.91 )) $(( 1.8 )) 3 "1 2"
  xg_disk $(( cx-6.07 )) $(( cy-0.5 )) $(( 3.95 )) $(( 3.20 )) 1
  xg_rat_ears $(( cx-6.07 )) $(( cy-0.5 )) 0.85
  xg_rat_dress $(( cx-6.07 )) $(( cy-0.5 ))
  xg_rat_face $(( cx-6.07 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-1.65 )) $(( cy-4.94 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+1.98 )) $(( cy-4.94 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+6.27 )) $(( cy-4.94 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+8.91 )) $(( cy-4.94 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_rat_tail $(( cx+6.93 )) $(( cy+1.0 )) $(( 0.9 ))
  return 0
}
# ── EARTH CHINCHILLA · CHINCHILLA LANIGERA ──
xg_chinchilla_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( hx-3.12*s )) $(( hy-3.72*s )) $(( 2.52*s )) $(( 3.24*s )) 1
  xg_disk $(( hx-3.12*s )) $(( hy-3.6*s )) $(( 1.25*s )) $(( 1.87*s )) 9 "1 2"
  xg_disk $(( hx+3.12*s )) $(( hy-3.72*s )) $(( 2.52*s )) $(( 3.24*s )) 1
  xg_disk $(( hx+3.12*s )) $(( hy-3.6*s )) $(( 1.25*s )) $(( 1.87*s )) 9 "1 2"
  return 0
}
xg_chinchilla_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  xg_seg $(( x )) $(( y )) $(( x+2.55*s )) $(( y-2.89*s )) $(( 2.29*s )) 1
  xg_seg $(( x+2.55*s )) $(( y-2.89*s )) $(( x+3.74*s )) $(( y-6.8*s )) $(( 2.72*s )) 1
  xg_disk $(( x+3.91*s )) $(( y-7.82*s )) $(( 2.63*s )) $(( 2.98*s )) 1
  return 0
}
xg_chinchilla_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.4*s ))
  exr=$(( hx+2.4*s ))
  ey=$(( hy+-0.6*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.2*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.2*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+2.2*s )) $(( 2.2*s )) $(( 1.5*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+1.8*s )) $(( 0.85*s )) $(( 0.62*s )) 10 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+3.2*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+4.0*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+3.2*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+3.2*s) )) 2
  fi
  return 0
}
xg_chinchilla_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    roan)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    mottled)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    frosted)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
  esac
  return 0
}
xg_chinchilla_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-35.0}
  local -F h=${4:-35.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=7.0
  xg_disk $(( hx )) $(( hy+10.6 )) $(( 6.8 )) $(( 6.4 )) 1
  xg_chinchilla_tail $(( hx+5.98 )) $(( hy+9.64 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy+13.4 )) $(( 3.4 )) $(( 2.6 )) 3 "1 2"
  xg_chinchilla_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6*1.0 )) $(( 4.0*1.0 )) 1
  xg_chinchilla_dress $(( hx )) $(( hy ))
  xg_chinchilla_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-2.8 )) $(( hy+17.42 )) $(( 1.9 )) $(( 1.1 )) 4
  xg_disk $(( hx+2.8 )) $(( hy+17.42 )) $(( 1.9 )) $(( 1.1 )) 4
  return 0
}
xg_chinchilla_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=7.24
  xg_disk $(( hx )) $(( hy+6.72 )) $(( 4.90 )) $(( 4.61 )) 1
  xg_chinchilla_tail $(( hx+4.31 )) $(( hy+6.11 )) $(( 0.72 ))
  xg_chinchilla_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6*0.94 )) $(( 4.0*0.94 )) 1
  xg_chinchilla_dress $(( hx )) $(( hy ))
  xg_chinchilla_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-2.02 )) $(( hy+11.29 )) $(( 1.37 )) $(( 0.79 )) 4
  xg_disk $(( hx+2.02 )) $(( hy+11.29 )) $(( 1.37 )) $(( 0.79 )) 4
  return 0
}
xg_chinchilla_loaf() {
  local -F w=${1:-31.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.0
  xg_disk $(( hx )) $(( hy+7.9 )) $(( 7.14 )) $(( 4.61 )) 1
  xg_chinchilla_tail $(( hx+5.98 )) $(( hy+8.64 )) $(( 0.9 ))
  xg_chinchilla_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6*0.92 )) $(( 4.0*0.92 )) 1
  xg_chinchilla_dress $(( hx )) $(( hy ))
  xg_chinchilla_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_chinchilla_sleep() {
  local -F w=${1:-34.0}
  local -F h=${2:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 7.62 )) $(( 4.99 )) 1
  xg_disk $(( cx-5.85 )) $(( cy-0.5 )) $(( 4.23 )) $(( 3.68 )) 1
  xg_chinchilla_ears $(( cx-5.85 )) $(( cy-0.5 )) 0.8
  xg_chinchilla_dress $(( cx-5.85 )) $(( cy-0.5 ))
  xg_chinchilla_face $(( cx-5.85 )) $(( cy-0.5 )) closed "" 0.9
  xg_chinchilla_tail $(( cx+7.14 )) $(( cy-1.0 )) $(( 0.9 ))
  return 0
}
xg_chinchilla_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-43.0}
  local -F h=${3:-28.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.6
  hy=7.0
  xg_disk $(( hx+6.46 )) $(( hy+4.8 )) $(( 6.8 )) $(( 5.12 )) 1
  xg_chinchilla_tail $(( hx+13.26 )) $(( hy+1.6 )) $(( 1.0 ))
  xg_chinchilla_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 4.6*0.94 )) $(( 4.0*0.94 )) 1
  xg_chinchilla_dress $(( hx )) $(( hy+1.0 ))
  xg_chinchilla_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+9.92 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+2.38 )) $(( ys )) $(( 1.71 )) $(( 0.99 )) 4
    xg_disk $(( hx+7.14 )) $(( ys )) $(( 1.71 )) $(( 0.99 )) 4
    xg_disk $(( hx+10.88 )) $(( ys )) $(( 1.71 )) $(( 0.99 )) 4
  else
    xg_disk $(( hx+3.74 )) $(( ys )) $(( 1.71 )) $(( 0.99 )) 4
    xg_disk $(( hx+8.84 )) $(( ys )) $(( 1.71 )) $(( 0.99 )) 4
    xg_disk $(( hx+12.58 )) $(( ys )) $(( 1.71 )) $(( 0.99 )) 4
  fi
  return 0
}
xg_chinchilla_play() {
  local -F w=${1:-41.0}
  local -F h=${2:-28.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.6
  hy=9.0
  xg_disk $(( hx+7.82 )) $(( hy-1.6 )) $(( 6.46 )) $(( 5.50 )) 1
  xg_chinchilla_tail $(( hx+13.6 )) $(( hy-6.72 )) $(( 1.0 ))
  xg_chinchilla_ears $(( hx )) $(( hy+3.52 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+3.52 )) $(( 4.6*0.96 )) $(( 4.0*0.96 )) 1
  xg_chinchilla_dress $(( hx )) $(( hy+3.52 ))
  xg_chinchilla_face $(( hx )) $(( hy+3.52 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+2.38 )) $(( hy+6.72 )) $(( 1.61 )) $(( 0.94 )) 4
  xg_disk $(( hx+5.44 )) $(( hy+6.72 )) $(( 1.61 )) $(( 0.94 )) 4
  xg_disk $(( hx+11.9 )) $(( hy+3.52 )) $(( 1.61 )) $(( 0.94 )) 4
  xg_disk $(( hx+13.94 )) $(( hy+3.52 )) $(( 1.61 )) $(( 0.94 )) 4
  return 0
}
xg_chinchilla_flop() {
  local -F w=${1:-34.0}
  local -F h=${2:-28.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-9.4 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 7.34 )) $(( 5.12 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.92 )) $(( 3.91 )) $(( 2.34 )) 3 "1 2"
  xg_disk $(( cx-6.26 )) $(( cy-0.5 )) $(( 4.32 )) $(( 3.76 )) 1
  xg_chinchilla_ears $(( cx-6.26 )) $(( cy-0.5 )) 0.85
  xg_chinchilla_dress $(( cx-6.26 )) $(( cy-0.5 ))
  xg_chinchilla_face $(( cx-6.26 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-1.7 )) $(( cy-6.08 )) $(( 1.52 )) $(( 0.88 )) 4
  xg_disk $(( cx+2.04 )) $(( cy-6.08 )) $(( 1.52 )) $(( 0.88 )) 4
  xg_disk $(( cx+6.46 )) $(( cy-6.08 )) $(( 1.52 )) $(( 0.88 )) 4
  xg_disk $(( cx+9.18 )) $(( cy-6.08 )) $(( 1.52 )) $(( 0.88 )) 4
  xg_chinchilla_tail $(( cx+7.14 )) $(( cy+1.0 )) $(( 0.9 ))
  return 0
}
# ── EARTH GOAT · CAPRA HIRCUS ──
xg_goat_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_seg $(( hx-1.04*s )) $(( hy-2.56*s )) $(( hx-1.61*s )) $(( hy-4.66*s )) $(( 0.76*s )) 2
  xg_seg $(( hx-1.61*s )) $(( hy-4.66*s )) $(( hx-3.32*s )) $(( hy-5.42*s )) $(( 0.61*s )) 2
  xg_disk $(( hx-2.94*s )) $(( hy+0.47*s )) $(( 1.52*s )) $(( 0.99*s )) 1
  xg_seg $(( hx+1.04*s )) $(( hy-2.56*s )) $(( hx+1.61*s )) $(( hy-4.66*s )) $(( 0.76*s )) 2
  xg_seg $(( hx+1.61*s )) $(( hy-4.66*s )) $(( hx+3.32*s )) $(( hy-5.42*s )) $(( 0.61*s )) 2
  xg_disk $(( hx+2.94*s )) $(( hy+0.47*s )) $(( 1.52*s )) $(( 0.99*s )) 1
  return 0
}
xg_goat_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( x )) $(( y )) $(( 1.56*s )) $(( 1.32*s )) 1
  return 0
}
xg_goat_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.6*s ))
  exr=$(( hx+2.6*s ))
  ey=$(( hy+-0.9*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.15*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.15*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+2.8*s )) $(( 2.0*s )) $(( 2.4*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+3.4*s )) $(( 0.85*s )) $(( 0.62*s )) 10 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+4.4*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+5.2*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+4.4*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+4.4*s) )) 2
  fi
  return 0
}
xg_goat_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    belted)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    spotted)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    roan)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
  esac
  return 0
}
xg_goat_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-30.0}
  local -F h=${4:-36.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=7.2
  xg_disk $(( hx )) $(( hy+11.8 )) $(( 7.2 )) $(( 6.4 )) 1
  xg_goat_tail $(( hx+6.34 )) $(( hy+10.84 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy+14.6 )) $(( 3.6 )) $(( 2.4 )) 3 "1 2"
  xg_seg $(( hx )) $(( hy+2.31*1.0 )) $(( hx )) $(( hy+6.49 )) $(( 2.60*1.0 )) 1
  xg_goat_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*1.0 )) $(( 4.2*1.0 )) 1
  xg_goat_dress $(( hx )) $(( hy ))
  xg_goat_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-3.6 )) $(( hy+19.02 )) $(( 1.5 )) $(( 1.9 )) 4
  xg_disk $(( hx+3.6 )) $(( hy+19.02 )) $(( 1.5 )) $(( 1.9 )) 4
  return 0
}
xg_goat_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=7.43
  xg_disk $(( hx )) $(( hy+7.48 )) $(( 5.18 )) $(( 4.61 )) 1
  xg_goat_tail $(( hx+4.56 )) $(( hy+6.87 )) $(( 0.72 ))
  xg_seg $(( hx )) $(( hy+2.31*0.94 )) $(( hx )) $(( hy+4.25 )) $(( 2.60*0.94 )) 1
  xg_goat_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*0.94 )) $(( 4.2*0.94 )) 1
  xg_goat_dress $(( hx )) $(( hy ))
  xg_goat_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-2.59 )) $(( hy+12.33 )) $(( 1.08 )) $(( 1.37 )) 4
  xg_disk $(( hx+2.59 )) $(( hy+12.33 )) $(( 1.08 )) $(( 1.37 )) 4
  return 0
}
xg_goat_loaf() {
  local -F w=${1:-27.0}
  local -F h=${2:-27.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.2
  xg_disk $(( hx )) $(( hy+7.9 )) $(( 7.56 )) $(( 4.61 )) 1
  xg_goat_tail $(( hx+6.34 )) $(( hy+8.64 )) $(( 0.9 ))
  xg_seg $(( hx )) $(( hy+2.31*0.92 )) $(( hx )) $(( hy+6.08 )) $(( 2.60*0.92 )) 1
  xg_goat_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*0.92 )) $(( 4.2*0.92 )) 1
  xg_goat_dress $(( hx )) $(( hy ))
  xg_goat_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_goat_sleep() {
  local -F w=${1:-31.0}
  local -F h=${2:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 8.06 )) $(( 4.99 )) 1
  xg_disk $(( cx-6.19 )) $(( cy-0.5 )) $(( 3.86 )) $(( 3.86 )) 1
  xg_goat_ears $(( cx-6.19 )) $(( cy-0.5 )) 0.8
  xg_goat_dress $(( cx-6.19 )) $(( cy-0.5 ))
  xg_goat_face $(( cx-6.19 )) $(( cy-0.5 )) closed "" 0.9
  xg_goat_tail $(( cx+7.56 )) $(( cy-1.0 )) $(( 0.9 ))
  return 0
}
xg_goat_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-38.0}
  local -F h=${3:-29.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.2
  hy=7.2
  xg_disk $(( hx+6.84 )) $(( hy+4.8 )) $(( 7.2 )) $(( 5.12 )) 1
  xg_goat_tail $(( hx+14.04 )) $(( hy+1.6 )) $(( 1.0 ))
  xg_seg $(( hx )) $(( hy+1.0+2.31*0.94 )) $(( hx )) $(( hy+1.0+3.2 )) $(( 2.60*0.94 )) 1
  xg_goat_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 4.2*0.94 )) $(( 4.2*0.94 )) 1
  xg_goat_dress $(( hx )) $(( hy+1.0 ))
  xg_goat_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+9.92 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+2.52 )) $(( ys )) $(( 1.35 )) $(( 1.71 )) 4
    xg_disk $(( hx+7.56 )) $(( ys )) $(( 1.35 )) $(( 1.71 )) 4
    xg_disk $(( hx+11.52 )) $(( ys )) $(( 1.35 )) $(( 1.71 )) 4
  else
    xg_disk $(( hx+3.96 )) $(( ys )) $(( 1.35 )) $(( 1.71 )) 4
    xg_disk $(( hx+9.36 )) $(( ys )) $(( 1.35 )) $(( 1.71 )) 4
    xg_disk $(( hx+13.32 )) $(( ys )) $(( 1.35 )) $(( 1.71 )) 4
  fi
  return 0
}
xg_goat_play() {
  local -F w=${1:-36.0}
  local -F h=${2:-29.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.2
  hy=9.2
  xg_disk $(( hx+8.28 )) $(( hy-1.6 )) $(( 6.84 )) $(( 5.50 )) 1
  xg_goat_tail $(( hx+14.4 )) $(( hy-6.72 )) $(( 1.0 ))
  xg_seg $(( hx )) $(( hy+3.52+2.31*0.96 )) $(( hx )) $(( hy+3.52+2.88 )) $(( 2.60*0.96 )) 1
  xg_goat_ears $(( hx )) $(( hy+3.52 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+3.52 )) $(( 4.2*0.96 )) $(( 4.2*0.96 )) 1
  xg_goat_dress $(( hx )) $(( hy+3.52 ))
  xg_goat_face $(( hx )) $(( hy+3.52 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+2.52 )) $(( hy+6.72 )) $(( 1.27 )) $(( 1.61 )) 4
  xg_disk $(( hx+5.76 )) $(( hy+6.72 )) $(( 1.27 )) $(( 1.61 )) 4
  xg_disk $(( hx+12.6 )) $(( hy+3.52 )) $(( 1.27 )) $(( 1.61 )) 4
  xg_disk $(( hx+14.76 )) $(( hy+3.52 )) $(( 1.27 )) $(( 1.61 )) 4
  return 0
}
xg_goat_flop() {
  local -F w=${1:-31.0}
  local -F h=${2:-29.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-9.4 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 7.78 )) $(( 5.12 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.92 )) $(( 4.14 )) $(( 2.16 )) 3 "1 2"
  xg_disk $(( cx-6.62 )) $(( cy-0.5 )) $(( 3.95 )) $(( 3.95 )) 1
  xg_goat_ears $(( cx-6.62 )) $(( cy-0.5 )) 0.85
  xg_goat_dress $(( cx-6.62 )) $(( cy-0.5 ))
  xg_goat_face $(( cx-6.62 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-1.8 )) $(( cy-6.08 )) $(( 1.2 )) $(( 1.52 )) 4
  xg_disk $(( cx+2.16 )) $(( cy-6.08 )) $(( 1.2 )) $(( 1.52 )) 4
  xg_disk $(( cx+6.84 )) $(( cy-6.08 )) $(( 1.2 )) $(( 1.52 )) 4
  xg_disk $(( cx+9.72 )) $(( cy-6.08 )) $(( 1.2 )) $(( 1.52 )) 4
  xg_goat_tail $(( cx+7.56 )) $(( cy+1.0 )) $(( 0.9 ))
  return 0
}
# ── EARTH GECKO · GEKKOTA SP. ──
xg_gecko_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_set $(( int(hx-2.28*s) )) $(( int(hy+0.36*s) )) 2
  xg_set $(( int(hx+2.28*s) )) $(( int(hy+0.36*s) )) 2
  xg_disk $(( hx )) $(( hy-1.68*s )) $(( 2.04*s )) $(( 0.48*s )) 2 "1"
  return 0
}
xg_gecko_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  xg_seg $(( x )) $(( y )) $(( x+5.04*s )) $(( y+3.12*s )) $(( 1.76*s )) 4
  xg_seg $(( x+5.04*s )) $(( y+3.12*s )) $(( x+8.64*s )) $(( y-1.2*s )) $(( 1.36*s )) 4
  return 0
}
xg_gecko_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.6*s ))
  exr=$(( hx+2.6*s ))
  ey=$(( hy+-0.5*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.35*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.35*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+1.6*s )) $(( 2.6*s )) $(( 1.2*s )) 3 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+2.4*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+3.2*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+2.4*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+2.4*s) )) 2
  fi
  return 0
}
xg_gecko_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    spotted)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    striped)
      xg_dj $pj 9 0.70 1.00; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*0.90+x*0.26+pj*0.37)+0.4*sin(x*0.85+pj*0.71) )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    mottled)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
  esac
  return 0
}
xg_gecko_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-41.0}
  local -F h=${4:-24.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=5.8
  xg_disk $(( hx )) $(( hy+5.4 )) $(( 8.0 )) $(( 3.6 )) 1
  xg_gecko_tail $(( hx+7.04 )) $(( hy+4.86 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy+6.8 )) $(( 4.0 )) $(( 1.4 )) 3 "1 2"
  xg_gecko_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6*1.0 )) $(( 2.8*1.0 )) 1
  xg_gecko_dress $(( hx )) $(( hy ))
  xg_gecko_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-4.6 )) $(( hy+9.43 )) $(( 2.2 )) $(( 1.0 )) 4
  xg_disk $(( hx+4.6 )) $(( hy+9.43 )) $(( 2.2 )) $(( 1.0 )) 4
  return 0
}
xg_gecko_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=6.12
  xg_disk $(( hx )) $(( hy+3.42 )) $(( 5.76 )) $(( 2.59 )) 1
  xg_gecko_tail $(( hx+5.07 )) $(( hy+3.08 )) $(( 0.72 ))
  xg_gecko_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6*0.94 )) $(( 2.8*0.94 )) 1
  xg_gecko_dress $(( hx )) $(( hy ))
  xg_gecko_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-3.31 )) $(( hy+6.11 )) $(( 1.58 )) $(( 0.72 )) 4
  xg_disk $(( hx+3.31 )) $(( hy+6.11 )) $(( 1.58 )) $(( 0.72 )) 4
  return 0
}
xg_gecko_loaf() {
  local -F w=${1:-35.0}
  local -F h=${2:-18.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=4.8
  xg_disk $(( hx )) $(( hy+5.1 )) $(( 8.4 )) $(( 2.59 )) 1
  xg_gecko_tail $(( hx+7.04 )) $(( hy+4.86 )) $(( 0.9 ))
  xg_gecko_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.6*0.92 )) $(( 2.8*0.92 )) 1
  xg_gecko_dress $(( hx )) $(( hy ))
  xg_gecko_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_gecko_sleep() {
  local -F w=${1:-38.0}
  local -F h=${2:-15.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 8.96 )) $(( 2.81 )) 1
  xg_disk $(( cx-6.88 )) $(( cy-0.5 )) $(( 4.23 )) $(( 2.58 )) 1
  xg_gecko_ears $(( cx-6.88 )) $(( cy-0.5 )) 0.8
  xg_gecko_dress $(( cx-6.88 )) $(( cy-0.5 ))
  xg_gecko_face $(( cx-6.88 )) $(( cy-0.5 )) closed "" 0.9
  xg_gecko_tail $(( cx+8.4 )) $(( cy-1.0 )) $(( 0.9 ))
  return 0
}
xg_gecko_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-48.0}
  local -F h=${3:-20.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.6
  hy=5.8
  xg_disk $(( hx+7.6 )) $(( hy+2.7 )) $(( 8.0 )) $(( 2.88 )) 1
  xg_gecko_tail $(( hx+15.6 )) $(( hy+0.9 )) $(( 1.0 ))
  xg_gecko_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 4.6*0.94 )) $(( 2.8*0.94 )) 1
  xg_gecko_dress $(( hx )) $(( hy+1.0 ))
  xg_gecko_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+5.58 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+2.8 )) $(( ys )) $(( 1.98 )) $(( 0.9 )) 4
    xg_disk $(( hx+8.4 )) $(( ys )) $(( 1.98 )) $(( 0.9 )) 4
    xg_disk $(( hx+12.8 )) $(( ys )) $(( 1.98 )) $(( 0.9 )) 4
  else
    xg_disk $(( hx+4.4 )) $(( ys )) $(( 1.98 )) $(( 0.9 )) 4
    xg_disk $(( hx+10.4 )) $(( ys )) $(( 1.98 )) $(( 0.9 )) 4
    xg_disk $(( hx+14.8 )) $(( ys )) $(( 1.98 )) $(( 0.9 )) 4
  fi
  return 0
}
xg_gecko_play() {
  local -F w=${1:-46.0}
  local -F h=${2:-20.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.6
  hy=7.8
  xg_disk $(( hx+9.2 )) $(( hy-0.9 )) $(( 7.6 )) $(( 3.10 )) 1
  xg_gecko_tail $(( hx+16.0 )) $(( hy-3.78 )) $(( 1.0 ))
  xg_gecko_ears $(( hx )) $(( hy+1.98 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+1.98 )) $(( 4.6*0.96 )) $(( 2.8*0.96 )) 1
  xg_gecko_dress $(( hx )) $(( hy+1.98 ))
  xg_gecko_face $(( hx )) $(( hy+1.98 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+2.8 )) $(( hy+3.78 )) $(( 1.87 )) $(( 0.85 )) 4
  xg_disk $(( hx+6.4 )) $(( hy+3.78 )) $(( 1.87 )) $(( 0.85 )) 4
  xg_disk $(( hx+14.0 )) $(( hy+1.98 )) $(( 1.87 )) $(( 0.85 )) 4
  xg_disk $(( hx+16.4 )) $(( hy+1.98 )) $(( 1.87 )) $(( 0.85 )) 4
  return 0
}
xg_gecko_flop() {
  local -F w=${1:-38.0}
  local -F h=${2:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-6.6 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 8.64 )) $(( 2.88 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.08 )) $(( 4.6 )) $(( 1.26 )) 3 "1 2"
  xg_disk $(( cx-7.36 )) $(( cy-0.5 )) $(( 4.32 )) $(( 2.63 )) 1
  xg_gecko_ears $(( cx-7.36 )) $(( cy-0.5 )) 0.85
  xg_gecko_dress $(( cx-7.36 )) $(( cy-0.5 ))
  xg_gecko_face $(( cx-7.36 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-2.0 )) $(( cy-3.42 )) $(( 1.76 )) $(( 0.8 )) 4
  xg_disk $(( cx+2.4 )) $(( cy-3.42 )) $(( 1.76 )) $(( 0.8 )) 4
  xg_disk $(( cx+7.6 )) $(( cy-3.42 )) $(( 1.76 )) $(( 0.8 )) 4
  xg_disk $(( cx+10.8 )) $(( cy-3.42 )) $(( 1.76 )) $(( 0.8 )) 4
  xg_gecko_tail $(( cx+8.4 )) $(( cy+1.0 )) $(( 0.9 ))
  return 0
}
# ── EARTH SUGAR GLIDER · PETAURUS BREVICEPS ──
xg_sugarglider_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_disk $(( hx-2.34*s )) $(( hy-2.79*s )) $(( 1.89*s )) $(( 2.43*s )) 1
  xg_disk $(( hx-2.34*s )) $(( hy-2.7*s )) $(( 0.94*s )) $(( 1.40*s )) 9 "1 2"
  xg_disk $(( hx+2.34*s )) $(( hy-2.79*s )) $(( 1.89*s )) $(( 2.43*s )) 1
  xg_disk $(( hx+2.34*s )) $(( hy-2.7*s )) $(( 0.94*s )) $(( 1.40*s )) 9 "1 2"
  return 0
}
xg_sugarglider_tail() {
  local -F x=${1:-0.0}
  local -F y=${2:-0.0}
  local -F s=${3:-1.0}
  xg_seg $(( x )) $(( y )) $(( x+2.7*s )) $(( y-3.06*s )) $(( 1.76*s )) 1
  xg_seg $(( x+2.7*s )) $(( y-3.06*s )) $(( x+3.96*s )) $(( y-7.2*s )) $(( 2.08*s )) 1
  xg_disk $(( x+4.14*s )) $(( y-8.28*s )) $(( 2.02*s )) $(( 2.27*s )) 1
  return 0
}
xg_sugarglider_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.5*s ))
  exr=$(( hx+2.5*s ))
  ey=$(( hy+-0.5*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.4*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.4*s )) 6
  fi
  xg_disk $(( hx )) $(( hy+2.0*s )) $(( 1.9*s )) $(( 1.4*s )) 3 "1 2 3 4"
  xg_disk $(( hx )) $(( hy+1.6*s )) $(( 0.85*s )) $(( 0.62*s )) 10 "1 2 3 4"
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+3.0*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+3.8*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+3.0*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+3.0*s) )) 2
  fi
  return 0
}
xg_sugarglider_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    striped)
      xg_dj $pj 9 0.70 1.00; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*0.90+x*0.26+pj*0.37)+0.4*sin(x*0.85+pj*0.71) )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    mottled)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    frosted)
      xg_dj $pj 3 0.55 0.85; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.7+x*2.3+pj*0.41)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
  esac
  return 0
}
xg_sugarglider_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-34.0}
  local -F h=${4:-32.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  xg_disk $(( hx )) $(( hy+9.4 )) $(( 6.2 )) $(( 5.4 )) 1
  xg_sugarglider_tail $(( hx+5.46 )) $(( hy+8.59 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy+11.8 )) $(( 3.2 )) $(( 2.4 )) 3 "1 2"
  xg_sugarglider_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.4*1.0 )) $(( 3.8*1.0 )) 1
  xg_sugarglider_dress $(( hx )) $(( hy ))
  xg_sugarglider_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 1.0 ))
  xg_disk $(( hx-2.7 )) $(( hy+15.19 )) $(( 1.7 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.7 )) $(( hy+15.19 )) $(( 1.7 )) $(( 1.0 )) 4
  return 0
}
xg_sugarglider_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=7.06
  xg_disk $(( hx )) $(( hy+5.96 )) $(( 4.46 )) $(( 3.89 )) 1
  xg_sugarglider_tail $(( hx+3.93 )) $(( hy+5.44 )) $(( 0.72 ))
  xg_sugarglider_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.4*0.94 )) $(( 3.8*0.94 )) 1
  xg_sugarglider_dress $(( hx )) $(( hy ))
  xg_sugarglider_face $(( hx )) $(( hy )) $eyes "$mouth" $(( 0.94 ))
  xg_disk $(( hx-1.94 )) $(( hy+9.84 )) $(( 1.22 )) $(( 0.72 )) 4
  xg_disk $(( hx+1.94 )) $(( hy+9.84 )) $(( 1.22 )) $(( 0.72 )) 4
  return 0
}
xg_sugarglider_loaf() {
  local -F w=${1:-30.0}
  local -F h=${2:-24.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=5.8
  xg_disk $(( hx )) $(( hy+6.9 )) $(( 6.51 )) $(( 3.89 )) 1
  xg_sugarglider_tail $(( hx+5.46 )) $(( hy+7.29 )) $(( 0.9 ))
  xg_sugarglider_ears $(( hx )) $(( hy )) $(( 0.92 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.4*0.92 )) $(( 3.8*0.92 )) 1
  xg_sugarglider_dress $(( hx )) $(( hy ))
  xg_sugarglider_face $(( hx )) $(( hy )) "narrow" "" $(( 0.92 ))
  return 0
}
xg_sugarglider_sleep() {
  local -F w=${1:-33.0}
  local -F h=${2:-18.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 6.94 )) $(( 4.21 )) 1
  xg_disk $(( cx-5.33 )) $(( cy-0.5 )) $(( 4.05 )) $(( 3.50 )) 1
  xg_sugarglider_ears $(( cx-5.33 )) $(( cy-0.5 )) 0.8
  xg_sugarglider_dress $(( cx-5.33 )) $(( cy-0.5 ))
  xg_sugarglider_face $(( cx-5.33 )) $(( cy-0.5 )) closed "" 0.9
  xg_sugarglider_tail $(( cx+6.51 )) $(( cy-1.0 )) $(( 0.9 ))
  return 0
}
xg_sugarglider_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-42.0}
  local -F h=${3:-26.0}
  local -F hx hy ys
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.4
  hy=6.8
  xg_disk $(( hx+5.89 )) $(( hy+4.05 )) $(( 6.2 )) $(( 4.32 )) 1
  xg_sugarglider_tail $(( hx+12.09 )) $(( hy+1.35 )) $(( 1.0 ))
  xg_sugarglider_ears $(( hx )) $(( hy+1.0 )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy+1.0 )) $(( 4.4*0.94 )) $(( 3.8*0.94 )) 1
  xg_sugarglider_dress $(( hx )) $(( hy+1.0 ))
  xg_sugarglider_face $(( hx )) $(( hy+1.0 )) "open" "" $(( 0.94 ))
  ys=$(( hy+8.37 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx+2.17 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+6.51 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+9.92 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  else
    xg_disk $(( hx+3.41 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+8.06 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
    xg_disk $(( hx+11.47 )) $(( ys )) $(( 1.53 )) $(( 0.9 )) 4
  fi
  return 0
}
xg_sugarglider_play() {
  local -F w=${1:-40.0}
  local -F h=${2:-26.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=7.4
  hy=8.8
  xg_disk $(( hx+7.13 )) $(( hy-1.35 )) $(( 5.89 )) $(( 4.64 )) 1
  xg_sugarglider_tail $(( hx+12.4 )) $(( hy-5.67 )) $(( 1.0 ))
  xg_sugarglider_ears $(( hx )) $(( hy+2.97 )) $(( 0.96 ))
  xg_disk $(( hx )) $(( hy+2.97 )) $(( 4.4*0.96 )) $(( 3.8*0.96 )) 1
  xg_sugarglider_dress $(( hx )) $(( hy+2.97 ))
  xg_sugarglider_face $(( hx )) $(( hy+2.97 )) "open" "" $(( 0.96 ))
  xg_disk $(( hx+2.17 )) $(( hy+5.67 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+4.96 )) $(( hy+5.67 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+10.85 )) $(( hy+2.97 )) $(( 1.44 )) $(( 0.85 )) 4
  xg_disk $(( hx+12.71 )) $(( hy+2.97 )) $(( 1.44 )) $(( 0.85 )) 4
  return 0
}
xg_sugarglider_flop() {
  local -F w=${1:-33.0}
  local -F h=${2:-26.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-8.4 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 6.70 )) $(( 4.32 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.62 )) $(( 3.68 )) $(( 2.16 )) 3 "1 2"
  xg_disk $(( cx-5.70 )) $(( cy-0.5 )) $(( 4.14 )) $(( 3.57 )) 1
  xg_sugarglider_ears $(( cx-5.70 )) $(( cy-0.5 )) 0.85
  xg_sugarglider_dress $(( cx-5.70 )) $(( cy-0.5 ))
  xg_sugarglider_face $(( cx-5.70 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx-1.55 )) $(( cy-5.13 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+1.86 )) $(( cy-5.13 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+5.89 )) $(( cy-5.13 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_disk $(( cx+8.37 )) $(( cy-5.13 )) $(( 1.36 )) $(( 0.8 )) 4
  xg_sugarglider_tail $(( cx+6.51 )) $(( cy+1.0 )) $(( 0.9 ))
  return 0
}
# ── EARTH PARROT · PSITTACIFORMES SP. ──
xg_parrot_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  xg_tri $(( hx-2.0*s )) $(( hy-2.66*s )) $(( hx+0.6*s )) $(( hy-2.66*s )) $(( hx-0.4*s )) $(( hy-6.06*s )) 2
  xg_tri $(( hx-0.4*s )) $(( hy-2.66*s )) $(( hx+1.8*s )) $(( hy-2.66*s )) $(( hx+0.5*s )) $(( hy-5.11*s )) 2
  return 0
}
xg_parrot_beak() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  local -F d=${4:-0.0}
  xg_disk $(( hx+d )) $(( hy+0.7*s )) $(( 1.43*s )) $(( 1.05*s )) 10
  xg_tri $(( hx+d-1.09*s )) $(( hy+0.77*s )) $(( hx+d+1.09*s )) $(( hy+0.77*s )) $(( hx+d-0.26*s )) $(( hy+2.59*s )) 10
  return 0
}
xg_parrot_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.4*s ))
  exr=$(( hx+2.4*s ))
  ey=$(( hy+-0.8*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.25*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.25*s )) 6
  fi
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+2.6*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+3.4*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+2.6*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+2.6*s) )) 2
  fi
  return 0
}
xg_parrot_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    barred)
      xg_dj $pj 9 0.70 1.00; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*0.90+x*0.26+pj*0.37)+0.4*sin(x*0.85+pj*0.71) )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    tipped)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
    capped)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    spotted)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
  esac
  return 0
}
xg_parrot_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-36.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  xg_disk $(( hx )) $(( hy+10.9 )) $(( 5.4 )) $(( 7.0 )) 1
  xg_disk $(( hx )) $(( hy+12.5 )) $(( 3.0 )) $(( 3.4 )) 3 "1 2"
  xg_disk $(( hx-(4.2+0.0)*1.0 )) $(( hy+10.9+0.6*1.0 )) $(( 2.2*1.0 )) $(( 4.4*1.0 )) 2 "1"
  xg_disk $(( hx+(4.2+0.0)*1.0 )) $(( hy+10.9+0.6*1.0 )) $(( 2.2*1.0 )) $(( 4.4*1.0 )) 2 "1"
  xg_seg $(( hx )) $(( hy+2.28*1.0 )) $(( hx )) $(( hy+5.7 )) $(( 2.31*1.0 )) 1
  xg_parrot_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*1.0 )) $(( 3.8*1.0 )) 1
  xg_parrot_dress $(( hx )) $(( hy ))
  xg_parrot_beak $(( hx )) $(( hy )) $(( 1.0 )) $(( -0.6 ))
  xg_parrot_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 1.0 ))
  xg_disk $(( hx-2.4 )) $(( hy+18.26 )) $(( 1.5 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.4 )) $(( hy+18.26 )) $(( 1.5 )) $(( 1.0 )) 4
  return 0
}
xg_parrot_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=7.32
  xg_disk $(( hx )) $(( hy+6.10 )) $(( 3.97 )) $(( 5.14 )) 1
  xg_seg $(( hx )) $(( hy+2.28*0.88 )) $(( hx )) $(( hy+5.7 )) $(( 2.31*0.88 )) 1
  xg_parrot_ears $(( hx )) $(( hy )) $(( 0.88 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*0.88 )) $(( 3.8*0.88 )) 1
  xg_parrot_dress $(( hx )) $(( hy ))
  xg_parrot_beak $(( hx )) $(( hy )) $(( 0.88 )) $(( -0.6 ))
  xg_parrot_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.88 ))
  xg_disk $(( hx-1.68 )) $(( hy+10.99 )) $(( 1.05 )) $(( 0.7 )) 4
  xg_disk $(( hx+1.68 )) $(( hy+10.99 )) $(( 1.05 )) $(( 0.7 )) 4
  return 0
}
xg_parrot_loaf() {
  local -F w=${1:-22.8}
  local -F h=${2:-27.6}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=5.8
  xg_disk $(( hx )) $(( hy+8.0 )) $(( 5.72 )) $(( 5.6 )) 1
  xg_disk $(( hx-(4.2+0.0)*0.92 )) $(( hy+8.0+0.6*0.92 )) $(( 2.2*0.92 )) $(( 4.4*0.92 )) 2 "1"
  xg_disk $(( hx+(4.2+0.0)*0.92 )) $(( hy+8.0+0.6*0.92 )) $(( 2.2*0.92 )) $(( 4.4*0.92 )) 2 "1"
  xg_seg $(( hx )) $(( hy+2.28*0.94 )) $(( hx )) $(( hy+5.7 )) $(( 2.31*0.94 )) 1
  xg_parrot_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.2*0.94 )) $(( 3.8*0.94 )) 1
  xg_parrot_dress $(( hx )) $(( hy ))
  xg_parrot_beak $(( hx )) $(( hy )) $(( 0.94 )) $(( -0.6 ))
  xg_parrot_face $(( hx )) $(( hy )) narrow "" $(( 0.94 ))
  return 0
}
xg_parrot_sleep() {
  local -F w=${1:-24.8}
  local -F h=${2:-25.8}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx )) $(( cy+1.0 )) $(( 5.67 )) $(( 6.44 )) 1
  xg_disk $(( cx-2.97 )) $(( cy-3.85 )) $(( 3.95 )) $(( 3.57 )) 1
  xg_parrot_dress $(( cx-2.97 )) $(( cy-3.85 ))
  xg_parrot_face $(( cx-2.97 )) $(( cy-3.85 )) closed "" 0.9
  xg_disk $(( cx+1.08 )) $(( cy+1.0 )) $(( 2.53 )) $(( 4.62 )) 2 "1"
  return 0
}
xg_parrot_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-26.8}
  local -F h=${3:-36.9}
  local -F hx hy tilt
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  if (( (int(frame)%2+2)%2 == 0 )); then tilt=-0.8; else tilt=0.8; fi
  xg_disk $(( hx+tilt )) $(( hy+10.9 )) $(( 5.4 )) $(( 7.0 )) 1
  xg_disk $(( hx+tilt )) $(( hy+12.5 )) $(( 3.0 )) $(( 3.4 )) 3 "1 2"
  xg_disk $(( hx+tilt-(4.2+0.5)*1.0 )) $(( hy+10.9+0.6*1.0 )) $(( 2.2*1.0 )) $(( 4.4*1.0 )) 2 "1"
  xg_disk $(( hx+tilt+(4.2+0.5)*1.0 )) $(( hy+10.9+0.6*1.0 )) $(( 2.2*1.0 )) $(( 4.4*1.0 )) 2 "1"
  xg_seg $(( hx+tilt )) $(( hy+2.28*1.0 )) $(( hx+tilt )) $(( hy+5.7 )) $(( 2.31*1.0 )) 1
  xg_parrot_ears $(( hx+tilt )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx+tilt )) $(( hy )) $(( 4.2*1.0 )) $(( 3.8*1.0 )) 1
  xg_parrot_dress $(( hx+tilt )) $(( hy ))
  xg_parrot_beak $(( hx+tilt )) $(( hy )) $(( 1.0 )) $(( -0.6 ))
  xg_parrot_face $(( hx+tilt )) $(( hy )) open "" $(( 1.0 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx-3.24 )) $(( hy+18.26 )) $(( 1.5 )) $(( 1.0 )) 4
    xg_disk $(( hx+1.2 )) $(( hy+17.66 )) $(( 1.5 )) $(( 1.0 )) 4
  else
    xg_disk $(( hx-1.2 )) $(( hy+17.66 )) $(( 1.5 )) $(( 1.0 )) 4
    xg_disk $(( hx+3.24 )) $(( hy+18.26 )) $(( 1.5 )) $(( 1.0 )) 4
  fi
  return 0
}
xg_parrot_play() {
  local -F w=${1:-31.6}
  local -F h=${2:-36.9}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  xg_disk $(( hx )) $(( hy+10.9 )) $(( 5.4 )) $(( 7.0 )) 1
  xg_disk $(( hx )) $(( hy+12.5 )) $(( 3.0 )) $(( 3.4 )) 3 "1 2"
  xg_seg $(( hx-3.89 )) $(( hy+8.8 )) $(( hx-7.63 )) $(( hy+2.85 )) $(( 4.18 )) 2
  xg_seg $(( hx+3.89 )) $(( hy+8.8 )) $(( hx+7.63 )) $(( hy+2.85 )) $(( 4.18 )) 2
  xg_seg $(( hx )) $(( hy-1.0+2.28*1.0 )) $(( hx )) $(( hy-1.0+5.7 )) $(( 2.31*1.0 )) 1
  xg_parrot_ears $(( hx )) $(( hy-1.0 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy-1.0 )) $(( 4.2*1.0 )) $(( 3.8*1.0 )) 1
  xg_parrot_dress $(( hx )) $(( hy-1.0 ))
  xg_parrot_beak $(( hx )) $(( hy-1.0 )) $(( 1.0 )) $(( -0.6 ))
  xg_parrot_face $(( hx )) $(( hy-1.0 )) open "" $(( 1.0 ))
  xg_disk $(( hx-2.4 )) $(( hy+18.26 )) $(( 1.5 )) $(( 1.0 )) 4
  xg_disk $(( hx+2.4 )) $(( hy+18.26 )) $(( 1.5 )) $(( 1.0 )) 4
  return 0
}
xg_parrot_flop() {
  local -F w=${1:-26.8}
  local -F h=${2:-29.6}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-10.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 5.72 )) $(( 5.74 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-1.96 )) $(( 3.45 )) $(( 3.13 )) 3 "1 2"
  xg_disk $(( cx+1.89 )) $(( cy+2.8 )) $(( 2.64 )) $(( 3.96 )) 2 "1"
  xg_disk $(( cx-4.97 )) $(( cy-0.5 )) $(( 3.95 )) $(( 3.57 )) 1
  xg_parrot_dress $(( cx-4.97 )) $(( cy-0.5 ))
  xg_parrot_beak $(( cx-4.97 )) $(( cy-0.5 )) 0.9 0.0
  xg_parrot_face $(( cx-4.97 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx+1.08 )) $(( cy-6.86 )) $(( 1.35 )) $(( 0.9 )) 4
  xg_disk $(( cx+3.78 )) $(( cy-6.86 )) $(( 1.35 )) $(( 0.9 )) 4
  return 0
}
# ── EARTH PENGUIN · SPHENISCIDAE SP. ──
xg_penguin_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  return 0
}
xg_penguin_beak() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  local -F d=${4:-0.0}
  xg_tri $(( hx+d-0.70*s )) $(( hy+0.12*s )) $(( hx+d-0.70*s )) $(( hy+1.32*s )) $(( hx+d-4.64*s )) $(( hy+0.84*s )) 4
  return 0
}
xg_penguin_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.4*s ))
  exr=$(( hx+2.4*s ))
  ey=$(( hy+-0.6*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.2*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.2*s )) 6
  fi
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+2.4*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+3.2*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+2.4*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+2.4*s) )) 2
  fi
  return 0
}
xg_penguin_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    bibbed)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    banded)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    capped)
      xg_dj $pj 4 -1.2 1.2; x0=$(( hx+XG_F ))
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 && x>=x0-2 && x<=x0+2 )) && XG_XPM[$(( y*XG_XPW+x ))]=3
      done; done ;;
    spotted)
      xg_dj $pj 1 2.0 4.5; v=$XG_F; xg_dj $pj 2 3.0 7.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy+thr )) 2.2 1.7 2 "1"
      xg_dj $pj 5 2.4 5.0; v=$XG_F; xg_dj $pj 6 5.0 9.0; thr=$XG_F
      xg_disk $(( hx-v )) $(( hy+thr )) 1.9 1.5 2 "1"
      xg_dj $pj 7 1.6 3.6; v=$XG_F; xg_dj $pj 8 1.0 4.0; thr=$XG_F
      xg_disk $(( hx+v )) $(( hy-thr )) 1.5 1.2 2 "1" ;;
    masked)
      xg_disk $(( hx )) $(( hy )) 4.0 3.4 2 "1"
      xg_disk $(( hx )) $(( hy-1.0 )) 2.4 2.0 1 "2" ;;
  esac
  return 0
}
xg_penguin_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-26.0}
  local -F h=${4:-39.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  xg_disk $(( hx )) $(( hy+11.9 )) $(( 6.0 )) $(( 8.0 )) 1
  xg_disk $(( hx )) $(( hy+13.3 )) $(( 3.6 )) $(( 4.4 )) 3 "1 2"
  xg_disk $(( hx-(5.0+0.0)*1.0 )) $(( hy+11.9+0.8*1.0 )) $(( 1.8*1.0 )) $(( 5.2*1.0 )) 2 "1"
  xg_disk $(( hx+(5.0+0.0)*1.0 )) $(( hy+11.9+0.8*1.0 )) $(( 1.8*1.0 )) $(( 5.2*1.0 )) 2 "1"
  xg_seg $(( hx )) $(( hy+2.28*1.0 )) $(( hx )) $(( hy+5.7 )) $(( 2.42*1.0 )) 1
  xg_penguin_ears $(( hx )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.4*1.0 )) $(( 3.8*1.0 )) 1
  xg_penguin_dress $(( hx )) $(( hy ))
  xg_penguin_beak $(( hx )) $(( hy )) $(( 1.0 )) $(( -0.8 ))
  xg_penguin_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 1.0 ))
  xg_disk $(( hx-2.6 )) $(( hy+20.34 )) $(( 2.4 )) $(( 1.2 )) 4
  xg_disk $(( hx+2.6 )) $(( hy+20.34 )) $(( 2.4 )) $(( 1.2 )) 4
  return 0
}
xg_penguin_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-24.0}
  local -F h=${4:-21.0}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-0.5 ))
  hy=7.32
  xg_disk $(( hx )) $(( hy+6.66 )) $(( 4.41 )) $(( 5.88 )) 1
  xg_seg $(( hx )) $(( hy+2.28*0.88 )) $(( hx )) $(( hy+5.7 )) $(( 2.42*0.88 )) 1
  xg_penguin_ears $(( hx )) $(( hy )) $(( 0.88 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.4*0.88 )) $(( 3.8*0.88 )) 1
  xg_penguin_dress $(( hx )) $(( hy ))
  xg_penguin_beak $(( hx )) $(( hy )) $(( 0.88 )) $(( -0.8 ))
  xg_penguin_face $(( hx )) $(( hy )) "$eyes" "$mouth" $(( 0.88 ))
  xg_disk $(( hx-1.82 )) $(( hy+12.24 )) $(( 1.68 )) $(( 0.84 )) 4
  xg_disk $(( hx+1.82 )) $(( hy+12.24 )) $(( 1.68 )) $(( 0.84 )) 4
  return 0
}
xg_penguin_loaf() {
  local -F w=${1:-24.0}
  local -F h=${2:-29.6}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=5.8
  xg_disk $(( hx )) $(( hy+9.0 )) $(( 6.36 )) $(( 6.4 )) 1
  xg_disk $(( hx-(5.0+0.0)*0.92 )) $(( hy+9.0+0.8*0.92 )) $(( 1.8*0.92 )) $(( 5.2*0.92 )) 2 "1"
  xg_disk $(( hx+(5.0+0.0)*0.92 )) $(( hy+9.0+0.8*0.92 )) $(( 1.8*0.92 )) $(( 5.2*0.92 )) 2 "1"
  xg_seg $(( hx )) $(( hy+2.28*0.94 )) $(( hx )) $(( hy+5.7 )) $(( 2.42*0.94 )) 1
  xg_penguin_ears $(( hx )) $(( hy )) $(( 0.94 ))
  xg_disk $(( hx )) $(( hy )) $(( 4.4*0.94 )) $(( 3.8*0.94 )) 1
  xg_penguin_dress $(( hx )) $(( hy ))
  xg_penguin_beak $(( hx )) $(( hy )) $(( 0.94 )) $(( -0.8 ))
  xg_penguin_face $(( hx )) $(( hy )) narrow "" $(( 0.94 ))
  return 0
}
xg_penguin_sleep() {
  local -F w=${1:-26.0}
  local -F h=${2:-27.8}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h/2.0+1.0 ))
  xg_disk $(( cx )) $(( cy+1.0 )) $(( 6.3 )) $(( 7.36 )) 1
  xg_disk $(( cx-3.3 )) $(( cy-4.4 )) $(( 4.14 )) $(( 3.57 )) 1
  xg_penguin_dress $(( cx-3.3 )) $(( cy-4.4 ))
  xg_penguin_face $(( cx-3.3 )) $(( cy-4.4 )) closed "" 0.9
  xg_disk $(( cx+1.2 )) $(( cy+1.0 )) $(( 2.07 )) $(( 5.46 )) 2 "1"
  return 0
}
xg_penguin_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-28.0}
  local -F h=${3:-39.9}
  local -F hx hy tilt
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  if (( (int(frame)%2+2)%2 == 0 )); then tilt=-0.8; else tilt=0.8; fi
  xg_disk $(( hx+tilt )) $(( hy+11.9 )) $(( 6.0 )) $(( 8.0 )) 1
  xg_disk $(( hx+tilt )) $(( hy+13.3 )) $(( 3.6 )) $(( 4.4 )) 3 "1 2"
  xg_disk $(( hx+tilt-(5.0+0.5)*1.0 )) $(( hy+11.9+0.8*1.0 )) $(( 1.8*1.0 )) $(( 5.2*1.0 )) 2 "1"
  xg_disk $(( hx+tilt+(5.0+0.5)*1.0 )) $(( hy+11.9+0.8*1.0 )) $(( 1.8*1.0 )) $(( 5.2*1.0 )) 2 "1"
  xg_seg $(( hx+tilt )) $(( hy+2.28*1.0 )) $(( hx+tilt )) $(( hy+5.7 )) $(( 2.42*1.0 )) 1
  xg_penguin_ears $(( hx+tilt )) $(( hy )) $(( 1.0 ))
  xg_disk $(( hx+tilt )) $(( hy )) $(( 4.4*1.0 )) $(( 3.8*1.0 )) 1
  xg_penguin_dress $(( hx+tilt )) $(( hy ))
  xg_penguin_beak $(( hx+tilt )) $(( hy )) $(( 1.0 )) $(( -0.8 ))
  xg_penguin_face $(( hx+tilt )) $(( hy )) open "" $(( 1.0 ))
  if (( (int(frame)%2+2)%2 == 0 )); then
    xg_disk $(( hx-3.51 )) $(( hy+20.34 )) $(( 2.4 )) $(( 1.2 )) 4
    xg_disk $(( hx+1.3 )) $(( hy+19.74 )) $(( 2.4 )) $(( 1.2 )) 4
  else
    xg_disk $(( hx-1.3 )) $(( hy+19.74 )) $(( 2.4 )) $(( 1.2 )) 4
    xg_disk $(( hx+3.51 )) $(( hy+20.34 )) $(( 2.4 )) $(( 1.2 )) 4
  fi
  return 0
}
xg_penguin_play() {
  local -F w=${1:-31.2}
  local -F h=${2:-39.9}
  local -F hx hy
  xg_px_new $(( int(w) )) $(( int(h) ))
  hx=$(( w/2.0-1.0 ))
  hy=6.8
  xg_disk $(( hx )) $(( hy+11.9 )) $(( 6.0 )) $(( 8.0 )) 1
  xg_disk $(( hx )) $(( hy+13.3 )) $(( 3.6 )) $(( 4.4 )) 3 "1 2"
  xg_seg $(( hx-4.32 )) $(( hy+9.5 )) $(( hx-7.38 )) $(( hy+2.7 )) $(( 4.94 )) 2
  xg_seg $(( hx+4.32 )) $(( hy+9.5 )) $(( hx+7.38 )) $(( hy+2.7 )) $(( 4.94 )) 2
  xg_seg $(( hx )) $(( hy-1.0+2.28*1.0 )) $(( hx )) $(( hy-1.0+5.7 )) $(( 2.42*1.0 )) 1
  xg_penguin_ears $(( hx )) $(( hy-1.0 )) $(( 1.0 ))
  xg_disk $(( hx )) $(( hy-1.0 )) $(( 4.4*1.0 )) $(( 3.8*1.0 )) 1
  xg_penguin_dress $(( hx )) $(( hy-1.0 ))
  xg_penguin_beak $(( hx )) $(( hy-1.0 )) $(( 1.0 )) $(( -0.8 ))
  xg_penguin_face $(( hx )) $(( hy-1.0 )) open "" $(( 1.0 ))
  xg_disk $(( hx-2.6 )) $(( hy+20.34 )) $(( 2.4 )) $(( 1.2 )) 4
  xg_disk $(( hx+2.6 )) $(( hy+20.34 )) $(( 2.4 )) $(( 1.2 )) 4
  return 0
}
xg_penguin_flop() {
  local -F w=${1:-28.0}
  local -F h=${2:-31.6}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=$(( h-11.0 ))
  xg_disk $(( cx+1.0 )) $(( cy )) $(( 6.36 )) $(( 6.56 )) 1
  xg_disk $(( cx+1.0 )) $(( cy-2.24 )) $(( 4.14 )) $(( 4.05 )) 3 "1 2"
  xg_disk $(( cx+2.1 )) $(( cy+3.2 )) $(( 2.16 )) $(( 4.68 )) 2 "1"
  xg_disk $(( cx-5.52 )) $(( cy-0.5 )) $(( 4.14 )) $(( 3.57 )) 1
  xg_penguin_dress $(( cx-5.52 )) $(( cy-0.5 ))
  xg_penguin_beak $(( cx-5.52 )) $(( cy-0.5 )) 0.9 0.0
  xg_penguin_face $(( cx-5.52 )) $(( cy-0.5 )) narrow "" 0.9
  xg_disk $(( cx+1.2 )) $(( cy-7.84 )) $(( 2.16 )) $(( 1.08 )) 4
  xg_disk $(( cx+4.2 )) $(( cy-7.84 )) $(( 2.16 )) $(( 1.08 )) 4
  return 0
}
# ── VOID DRIFTER · NOCTILUCA VAGANS ──
xg_drifter_ears() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F s=${3:-1.0}
  return 0
}
xg_drifter_fil() {
  local -F cx=${1:-0.0}
  local -F cy=${2:-0.0}
  local -F s=${3:-1.0}
  local -F sw=${4:-0.0}
  local -F ln=${5:-1.0}
  local -i i
  local -F fx
  for (( i=0; i<5; i++ )); do
    fx=$(( cx+(i-2.0)*2.80*s ))
    xg_seg $fx $cy $(( fx+sw*s )) $(( cy+6.05*s*ln )) $(( 0.85*s )) 1
    xg_seg $(( fx+sw*s )) $(( cy+6.05*s*ln )) $(( fx+sw*1.9*s )) $(( cy+11.0*s*ln )) $(( 0.61*s )) 2
  done
  return 0
}
xg_drifter_face() {
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local eyes="${3:-open}"
  local mouth="${4:-}"
  local -F s=${5:-1.0}
  local -F exl exr ey
  exl=$(( hx-2.8*s ))
  exr=$(( hx+2.8*s ))
  ey=$(( hy+-0.6*s ))
  if [[ "$eyes" == closed ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey+1) )) 7
    xg_set $(( int(exr+1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey+1) )) 7
  elif [[ "$eyes" == narrow ]]; then
    xg_set $(( int(exl-1) )) $(( int(ey) )) 7; xg_set $(( int(exl) )) $(( int(ey) )) 5; xg_set $(( int(exl+1) )) $(( int(ey) )) 7
    xg_set $(( int(exr-1) )) $(( int(ey) )) 7; xg_set $(( int(exr) )) $(( int(ey) )) 6; xg_set $(( int(exr+1) )) $(( int(ey) )) 7
  else
    xg_eye $(( exl )) $(( ey )) $(( 1.35*s )) 5
    xg_eye $(( exr )) $(( ey )) $(( 1.35*s )) 6
  fi
  if [[ "$mouth" == wail ]]; then
    xg_set $(( int(hx) )) $(( int(hy+2.2*s) )) 7
    xg_set $(( int(hx) )) $(( int(hy+3.0*s) )) 7
  else
    xg_set $(( int(hx-1) )) $(( int(hy+2.2*s) )) 2
    xg_set $(( int(hx+1) )) $(( int(hy+2.2*s) )) 2
  fi
  return 0
}
xg_drifter_dress() {
  local pattern="${XG[pattern]}"
  local -i pj=${XG[pj]:-0}
  local -F hx=${1:-0.0}
  local -F hy=${2:-0.0}
  local -F v thr x0
  local -i x y
  case "$pattern" in
    plain)
      ;;
    ringed)
      xg_dj $pj 3 0.62 0.90; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.3+x*1.9+pj*0.53)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    speckled)
      xg_dj $pj 3 0.62 0.90; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.3+x*1.9+pj*0.53)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    nebular)
      xg_dj $pj 3 0.62 0.90; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.3+x*1.9+pj*0.53)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    glassy)
      xg_dj $pj 3 0.62 0.90; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.3+x*1.9+pj*0.53)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
    veined)
      xg_dj $pj 3 0.62 0.90; thr=$XG_F
      for (( y=0;y<XG_XPH;y++ )); do for (( x=0;x<XG_XPW;x++ )); do
        (( XG_XPM[y*XG_XPW+x]==1 )) && { v=$(( sin(y*1.3+x*1.9+pj*0.53)*0.5+0.5 )); (( v>thr )) && XG_XPM[$(( y*XG_XPW+x ))]=2; }
      done; done ;;
  esac
  return 0
}
xg_drifter_sit() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-25.0}
  local -F h=${4:-31.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=8.2
  xg_drifter_fil $(( cx )) $(( cy+3.9 )) $(( 1.0 )) $(( 0.0 )) $(( 1.0 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6*1.0 )) $(( 5.2*1.0*1.0 )) 1
  xg_disk $(( cx )) $(( cy-1.82*1.0 )) $(( 3.63*1.0 )) $(( 2.08*1.0 )) 3 "1"
  xg_drifter_dress $(( cx )) $(( cy ))
  xg_drifter_face $(( cx )) $(( cy )) "$eyes" "" $(( 1.0 ))
  return 0
}
xg_drifter_baby() {
  local eyes="${1:-open}"
  local mouth="${2:-}"
  local -F w=${3:-22.0}
  local -F h=${4:-20.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=8.22
  xg_drifter_fil $(( cx )) $(( cy+2.42 )) $(( 0.62 )) $(( 0.0 )) $(( 0.7 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6*0.62 )) $(( 5.2*0.62*1.0 )) 1
  xg_disk $(( cx )) $(( cy-1.82*0.62 )) $(( 3.63*0.62 )) $(( 2.08*0.62 )) 3 "1"
  xg_drifter_dress $(( cx )) $(( cy ))
  xg_drifter_face $(( cx )) $(( cy )) "$eyes" "" $(( 0.62 ))
  return 0
}
xg_drifter_loaf() {
  local -F w=${1:-25.0}
  local -F h=${2:-31.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=10.49
  xg_drifter_fil $(( cx )) $(( cy+3.74 )) $(( 0.96 )) $(( 0.0 )) $(( 0.55 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6*0.96 )) $(( 5.2*0.96*0.78 )) 1
  xg_disk $(( cx )) $(( cy-1.82*0.96 )) $(( 3.63*0.96 )) $(( 2.08*0.96 )) 3 "1"
  xg_drifter_dress $(( cx )) $(( cy ))
  xg_drifter_face $(( cx )) $(( cy )) narrow "" $(( 0.96 ))
  return 0
}
xg_drifter_sleep() {
  local -F w=${1:-25.0}
  local -F h=${2:-31.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=11.28
  xg_drifter_fil $(( cx )) $(( cy+3.59 )) $(( 0.92 )) $(( 0.0 )) $(( 0.45 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6*0.92 )) $(( 5.2*0.92*0.62 )) 1
  xg_disk $(( cx )) $(( cy-1.82*0.92 )) $(( 3.63*0.92 )) $(( 2.08*0.92 )) 3 "1"
  xg_drifter_dress $(( cx )) $(( cy ))
  xg_drifter_face $(( cx )) $(( cy )) closed "" $(( 0.92 ))
  return 0
}
xg_drifter_walk() {
  local -F frame=${1:-0.0}
  local -F w=${2:-25.0}
  local -F h=${3:-31.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=8.7
  xg_drifter_fil $(( cx )) $(( cy+3.9 )) $(( 1.0 )) $(( -2.6 )) $(( 0.95 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6*1.0 )) $(( 5.2*1.0*0.92 )) 1
  xg_disk $(( cx )) $(( cy-1.82*1.0 )) $(( 3.63*1.0 )) $(( 2.08*1.0 )) 3 "1"
  xg_drifter_dress $(( cx )) $(( cy ))
  xg_drifter_face $(( cx )) $(( cy )) open "" $(( 1.0 ))
  return 0
}
xg_drifter_play() {
  local -F w=${1:-25.0}
  local -F h=${2:-31.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=7.51
  xg_drifter_fil $(( cx )) $(( cy+4.13 )) $(( 1.06 )) $(( 0.0 )) $(( 1.12 ))
  xg_disk $(( cx )) $(( cy )) $(( 6.6*1.06 )) $(( 5.2*1.06*1.22 )) 1
  xg_disk $(( cx )) $(( cy-1.82*1.06 )) $(( 3.63*1.06 )) $(( 2.08*1.06 )) 3 "1"
  xg_drifter_dress $(( cx )) $(( cy ))
  xg_drifter_face $(( cx )) $(( cy )) open "" $(( 1.06 ))
  return 0
}
xg_drifter_flop() {
  local -F w=${1:-25.0}
  local -F h=${2:-31.0}
  local -F cx cy
  xg_px_new $(( int(w) )) $(( int(h) ))
  cx=$(( w/2.0 ))
  cy=12.2
  xg_drifter_fil $(( cx-1.2 )) $(( cy-3.9 )) $(( 1.0 )) $(( 1.8 )) $(( -0.95 ))
  xg_disk $(( cx+0.9 )) $(( cy )) $(( 6.6*1.0 )) $(( 5.2*1.0*0.86 )) 1
  xg_disk $(( cx+0.9 )) $(( cy-1.82*1.0 )) $(( 3.63*1.0 )) $(( 2.08*1.0 )) 3 "1"
  xg_drifter_dress $(( cx+0.9 )) $(( cy ))
  xg_drifter_face $(( cx+0.9 )) $(( cy )) narrow "" $(( 1.0 ))
  return 0
}

typeset -gA XG_POSES
XG_POSES[cat]='xg_cat_sit xg_cat_kitten xg_cat_loaf xg_cat_sleep xg_cat_walk xg_cat_play xg_cat_flop'
XG_POSES[dog]='xg_dog_sit xg_dog_puppy xg_dog_sploot xg_dog_sleep xg_dog_walk xg_dog_bow xg_dog_flop'
XG_POSES[rabbit]='xg_rabbit_sit xg_bunny_sit xg_rabbit_loaf xg_rabbit_sleep xg_rabbit_hop xg_rabbit_binky xg_rabbit_flop'
XG_POSES[hamster]='xg_hamster_sit xg_hamster_baby xg_hamster_loaf xg_hamster_sleep xg_hamster_walk xg_hamster_play xg_hamster_flop'
XG_POSES[fox]='xg_fox_sit xg_fox_baby xg_fox_loaf xg_fox_sleep xg_fox_walk xg_fox_play xg_fox_flop'
XG_POSES[turtle]='xg_turtle_sit xg_turtle_baby xg_turtle_loaf xg_turtle_sleep xg_turtle_walk xg_turtle_play xg_turtle_flop'
XG_POSES[hedgehog]='xg_hedgehog_sit xg_hedgehog_baby xg_hedgehog_loaf xg_hedgehog_sleep xg_hedgehog_walk xg_hedgehog_play xg_hedgehog_flop'
XG_POSES[glorp]='xg_glorp_sit xg_glorp_baby xg_glorp_loaf xg_glorp_sleep xg_glorp_walk xg_glorp_play xg_glorp_flop'
XG_POSES[xeno]='xg_xeno_sit xg_xeno_baby xg_xeno_loaf xg_xeno_sleep xg_xeno_walk xg_xeno_play xg_xeno_flop'
XG_POSES[duck]='xg_duck_sit xg_duck_baby xg_duck_loaf xg_duck_sleep xg_duck_walk xg_duck_play xg_duck_flop'
XG_POSES[frog]='xg_frog_sit xg_frog_baby xg_frog_loaf xg_frog_sleep xg_frog_walk xg_frog_play xg_frog_flop'
XG_POSES[snake]='xg_snake_sit xg_snake_baby xg_snake_loaf xg_snake_sleep xg_snake_walk xg_snake_play xg_snake_flop'
XG_POSES[owl]='xg_owl_sit xg_owl_baby xg_owl_loaf xg_owl_sleep xg_owl_walk xg_owl_play xg_owl_flop'
XG_POSES[pig]='xg_pig_sit xg_pig_baby xg_pig_loaf xg_pig_sleep xg_pig_walk xg_pig_play xg_pig_flop'
XG_POSES[axolotl]='xg_axolotl_sit xg_axolotl_baby xg_axolotl_loaf xg_axolotl_sleep xg_axolotl_walk xg_axolotl_play xg_axolotl_flop'

# ── TEN MORE · generated by sd/newspec.py, see the header there ──
XG_DK_CW[guineapig]='chestnut:150,96,60|cream:236,220,188|black:54,50,58|white:242,238,232|golden:214,166,86|slate:126,126,138|buff:214,180,132|red:176,92,56'
XG_DK_PAT[guineapig]='plain|agouti|roan|broken|banded|crested'
XG_DK_EYN[guineapig]='ruby|garnet|ink|amber'
XG_DK_EYC[guineapig]='196,64,72|150,52,60|36,30,40|208,150,64'
XG_DK_TMP[guineapig]='chatty:announces the bowl before you reach it:1.16:1.12|placid:has never once been in a hurry:0.98:1.02|popcorny:goes straight up, for no reason:1.06:1.08|watchful:knows the sound of the fridge:1.0:0.96|affable:glad of company, loudly:1.04:1.18|grumbly:complains, then accepts:0.94:0.92'
XG_DK_BLD[guineapig]='dainty|cobby|barrel'
XG_DK_SPAN[guineapig]=0.75; XG_DK_ODD[guineapig]=0.04
XG_DK_BREED[guineapig]='American:1:6:*:plain,agouti:-:-|Abyssinian:1:6:chestnut,golden,cream,black:agouti,broken:-:-|Peruvian:1.05:6:cream,golden,white,chestnut:broken,plain:-:-|Silkie:1.05:6:cream,buff,white,slate:plain,roan:-:-|Teddy:0.98:6:golden,buff,chestnut:plain,agouti:-:-|Texel:1.02:6:cream,red,chestnut:broken,plain:-:-|Skinny Pig:0.9:5:slate,white,chestnut:plain:-:-|Rex:0.98:6:chestnut,black,slate:roan,plain:-:-|Coronet:1.02:6:white,cream,golden:crested,broken:-:-|Sheba:1:6:red,golden,buff:agouti,broken:-:-|Himalayan:0.96:6:white,cream:banded,plain:-:-|Alpaca:1.05:6:chestnut,cream,red:broken,plain:-:-'
XG_SP_NM[guineapig]='PUP WEANLING YOUNG|CAVY CAVY MATURE SENIOR'
XG_SP_HAPPY[guineapig]='popcorned, twice|wheeked at the door|settled in the hay'
XG_SP_NOMINAL[guineapig]='chewing, contentedly'
XG_SP_BOX[guineapig]='the hay wants changing'
XG_SP_FACE[guineapig]=-1
XG_POSES[guineapig]='xg_guineapig_sit xg_guineapig_baby xg_guineapig_loaf xg_guineapig_sleep xg_guineapig_walk xg_guineapig_play xg_guineapig_flop'
XG_DK_CW[ferret]='sable:96,72,56|champagne:216,190,152|albino:246,242,234|chocolate:112,76,52|cinnamon:188,124,76|silver:176,176,186|panda:236,230,220|black:52,48,56'
XG_DK_PAT[ferret]='plain|masked|mitted|roan|blaze|banded'
XG_DK_EYN[ferret]='ruby|ink|garnet|pale'
XG_DK_EYC[ferret]='200,72,78|34,28,38|148,56,62|216,206,214'
XG_DK_TMP[ferret]='larcenous:has already hidden something of yours:1.08:1.02|noodly:pours rather than walks:1.0:1.06|busy:investigates everything, twice:1.12:1.0|dozy:asleep eighteen hours, feral for six:0.9:0.94|bouncy:war-dances at the smallest excuse:1.14:1.16|sly:knows which door is not quite shut:1.02:0.92'
XG_DK_BLD[ferret]='slinky|long-bodied|stout'
XG_DK_SPAN[ferret]=0.72; XG_DK_ODD[ferret]=0.03
XG_DK_BREED[ferret]='Sable:1:8:sable,chocolate:plain,masked:-:-|Albino:0.98:8:albino:plain:-:-|Champagne:1:8:champagne,cinnamon:plain,mitted:-:-|Black Sable:1.04:8:black,sable:masked,mitted:-:-|Chocolate:1:8:chocolate,cinnamon:masked,plain:-:-|Cinnamon:1:8:cinnamon,champagne:plain,roan:-:-|Silver Mitt:1:8.5:silver,sable:mitted,roan:-:-|Panda:1.02:7.5:panda,albino,silver:blaze,plain:-:-|Blaze:1:8:sable,chocolate,silver:blaze:-:-|Dark-Eyed White:0.98:8:albino,panda:plain:-:-|Angora:1.05:8:champagne,silver,sable:roan,plain:-:-'
XG_SP_NM[ferret]='KIT JILL YOUNG|FERRET FERRET MATURE SENIOR'
XG_SP_HAPPY[ferret]='war-danced into the wall|stole a sock, triumphantly|poured off the shelf'
XG_SP_NOMINAL[ferret]='plotting, quietly'
XG_SP_BOX[ferret]='the corner needs seeing to'
XG_SP_FACE[ferret]=-1
XG_POSES[ferret]='xg_ferret_sit xg_ferret_baby xg_ferret_loaf xg_ferret_sleep xg_ferret_walk xg_ferret_play xg_ferret_flop'
XG_DK_CW[rat]='agouti:142,112,72|black:50,46,54|russian-blue:120,124,140|champagne:226,204,176|mink:140,118,104|white:244,240,234|fawn:216,176,120|chocolate:104,72,52'
XG_DK_PAT[rat]='plain|hooded|banded|masked|roan|broken'
XG_DK_EYN[rat]='ink|ruby|garnet|pale'
XG_DK_EYC[rat]='32,28,38|198,70,76|146,54,60|214,204,212'
XG_DK_TMP[rat]='brainy:solves the latch, then waits:1.04:1.08|snuggly:wants a pocket, any pocket:1.02:1.22|bold:first out, every time:1.08:1.0|tidy:grooms you whether you asked or not:0.96:1.14|hoardy:the bed is full of things:1.16:0.98|gentle:has never once used its teeth:0.94:1.1'
XG_DK_BLD[rat]='neat|barrel|long-bodied'
XG_DK_SPAN[rat]=0.78; XG_DK_ODD[rat]=0.05
XG_DK_BREED[rat]='Standard:1:3:*:*:-:-|Rex:0.98:3:agouti,black,mink:roan,plain:-:-|Dumbo:1:3:agouti,champagne,black,white:hooded,banded:-:-|Hairless:0.9:2.5:champagne,white:plain:-:-|Satin:1:3:black,chocolate,fawn:plain,roan:-:-|Manx:0.95:2.8:agouti,mink,black:hooded,masked:-:-|Berkshire:1:3:black,chocolate,russian-blue:banded,broken:-:-|Blazed Hooded:1:3:agouti,fawn,champagne:hooded,masked:-:-|Russian Blue:1:3.2:russian-blue,mink:plain,roan:-:-|Siamese:0.98:3:champagne,fawn:masked,plain:-:-'
XG_SP_NM[rat]='PINKIE KITTEN YOUNG|RAT RAT MATURE SENIOR'
XG_SP_HAPPY[rat]='bruxed until it boggled|took the whole thing to bed|climbed you, entirely'
XG_SP_NOMINAL[rat]='working on something'
XG_SP_BOX[rat]='the corner is a problem'
XG_SP_FACE[rat]=-1
XG_POSES[rat]='xg_rat_sit xg_rat_baby xg_rat_loaf xg_rat_sleep xg_rat_walk xg_rat_play xg_rat_flop'
XG_DK_CW[chinchilla]='standard-grey:150,150,158|black-velvet:56,54,62|beige:214,188,152|mosaic:232,228,222|ebony:40,38,46|violet:162,150,172|sapphire:146,158,180|white:244,242,238'
XG_DK_PAT[chinchilla]='plain|roan|mottled|masked|frosted|banded'
XG_DK_EYN[chinchilla]='ink|ruby|garnet|sapphire'
XG_DK_EYC[chinchilla]='30,26,36|194,68,74|144,52,58|104,126,182'
XG_DK_TMP[chinchilla]='springy:is on the shelf before you look up:1.06:1.0|dust-mad:would bathe all day if you let it:1.0:0.98|particular:has opinions about the hay:0.94:0.96|nocturnal:comes alive at exactly midnight:1.02:1.04|velvet:the softest thing in the cabinet:0.98:1.16|stoic:will not be hurried by anyone:0.96:0.9'
XG_DK_BLD[chinchilla]='compact|round|plush'
XG_DK_SPAN[chinchilla]=0.7; XG_DK_ODD[chinchilla]=0.03
XG_DK_BREED[chinchilla]='Standard Grey:1:15:standard-grey:plain,roan:-:-|Black Velvet:1:15:black-velvet,ebony:masked,plain:-:-|Beige:1:15:beige:plain,frosted:-:-|White Mosaic:1:15:mosaic,white:mottled,plain:-:-|Ebony:1.02:16:ebony,black-velvet:plain:-:-|Violet:1:15:violet,standard-grey:plain,frosted:-:-|Sapphire:1:15:sapphire,standard-grey:plain,roan:-:-|Charcoal:1.02:15:ebony,black-velvet:roan,plain:-:-|Goldbar:0.98:14:beige,mosaic:frosted,banded:-:-|Pink White:0.98:14:white,beige:mottled,plain:-:-'
XG_SP_NM[chinchilla]='KIT WEANLING YOUNG|CHINCHILLA CHINCHILLA MATURE ELDER'
XG_SP_HAPPY[chinchilla]='took a dust bath, thoroughly|sprang the length of the room|sat very still, being soft'
XG_SP_NOMINAL[chinchilla]='dozing, at altitude'
XG_SP_BOX[chinchilla]='the dust wants changing'
XG_SP_FACE[chinchilla]=-1
XG_POSES[chinchilla]='xg_chinchilla_sit xg_chinchilla_baby xg_chinchilla_loaf xg_chinchilla_sleep xg_chinchilla_walk xg_chinchilla_play xg_chinchilla_flop'
XG_DK_CW[goat]='chamois:206,162,104|black:52,48,56|white:244,240,232|chocolate:110,76,54|red:174,96,58|grey:144,142,150|cream:232,218,186|gold:216,172,84'
XG_DK_PAT[goat]='plain|belted|spotted|masked|roan|banded'
XG_DK_EYN[goat]='amber|gold|slate|ink'
XG_DK_EYC[goat]='214,158,66|226,184,72|128,130,142|36,32,42'
XG_DK_TMP[goat]='climby:is on top of something already:1.08:0.98|nosy:has tasted your sleeve:1.14:1.06|bossy:runs the room, thank you:1.02:0.94|affable:leans on you, companionably:1.0:1.2|screamy:has one volume:1.06:1.1|stubborn:will consider it tomorrow:0.96:0.9'
XG_DK_BLD[goat]='fine-boned|square|deep-chested'
XG_DK_SPAN[goat]=0.8; XG_DK_ODD[goat]=0.06
XG_DK_BREED[goat]='Nigerian Dwarf:0.72:16:chamois,black,gold,chocolate:spotted,belted:-:-|Pygmy:0.7:14:grey,chamois,black:banded,roan:-:-|Nubian:1.1:16:chocolate,black,red,cream:spotted,masked:-:-|Alpine:1.05:16:chamois,grey,black,white:belted,masked:-:-|LaMancha:1:16:black,chocolate,cream:plain,roan:-:-|Boer:1.15:14:white,red,chamois:masked,belted:-:-|Saanen:1.12:16:white,cream:plain:-:-|Toggenburg:1.02:16:chocolate,chamois:belted,masked:-:-|Kiko:1.08:15:white,grey,cream:plain,roan:-:-|Angora:0.95:14:white,cream,gold:plain:-:-|Kinder:0.85:16:chamois,gold,black:spotted,banded:-:-'
XG_SP_NM[goat]='KID YEARLING YOUNG|GOAT GOAT MATURE SENIOR'
XG_SP_HAPPY[goat]='climbed the shelf, again|headbutted the bowl, gently|ate something it should not have'
XG_SP_NOMINAL[goat]='chewing, thoughtfully'
XG_SP_BOX[goat]='the pen wants raking'
XG_SP_FACE[goat]=-1
XG_POSES[goat]='xg_goat_sit xg_goat_baby xg_goat_loaf xg_goat_sleep xg_goat_walk xg_goat_play xg_goat_flop'
XG_DK_CW[gecko]='sand:226,198,148|tangerine:232,150,70|midnight:44,42,56|moss:122,140,92|blizzard:238,236,230|chocolate:102,72,52|lavender:186,166,196|emerald:88,150,104'
XG_DK_PAT[gecko]='plain|spotted|banded|striped|mottled|masked'
XG_DK_EYN[gecko]='gold|copper|ink|silver'
XG_DK_EYC[gecko]='226,182,72|200,128,60|34,30,40|202,202,212'
XG_DK_TMP[gecko]='unhurried:moves twice a day, on principle:0.88:0.9|sticky:is on the glass again:1.0:0.96|grinny:was born looking pleased:0.96:1.14|crepuscular:comes out exactly at dusk:0.94:0.94|bold:walked straight onto your hand:1.04:1.1|twitchy:drops the tail first, asks later:1.02:0.88'
XG_DK_BLD[gecko]='slender|stout|thick-tailed'
XG_DK_SPAN[gecko]=0.85; XG_DK_ODD[gecko]=0.07
XG_DK_BREED[gecko]='Leopard Gecko:1:15:sand,tangerine,blizzard,chocolate:spotted,banded:-:-|Crested Gecko:0.92:16:tangerine,chocolate,moss,lavender:striped,mottled:-:-|Tokay Gecko:1.15:12:emerald,midnight,lavender:spotted,mottled:-:-|Day Gecko:0.85:10:emerald,moss:plain,spotted:-:-|African Fat-tailed:1.02:18:chocolate,sand,tangerine:banded,striped:-:-|House Gecko:0.7:8:sand,blizzard,chocolate:mottled,plain:-:-|Gargoyle Gecko:0.95:16:moss,lavender,chocolate:mottled,masked:-:-|Blizzard Morph:1:15:blizzard:plain:-:-|Giant Day Gecko:1.05:12:emerald,moss:spotted,plain:-:-|Chahoua:1:18:moss,chocolate,lavender:mottled,banded:-:-'
XG_SP_NM[gecko]='HATCHLING JUVENILE YOUNG|GECKO GECKO MATURE ELDER'
XG_SP_HAPPY[gecko]='walked up the glass, upside down|caught the light and held it|grinned, professionally'
XG_SP_NOMINAL[gecko]='warming, slowly'
XG_SP_BOX[gecko]='the substrate wants turning'
XG_SP_FACE[gecko]=-1
XG_POSES[gecko]='xg_gecko_sit xg_gecko_baby xg_gecko_loaf xg_gecko_sleep xg_gecko_walk xg_gecko_play xg_gecko_flop'
XG_DK_CW[sugarglider]='classic-grey:150,150,162|platinum:198,198,206|leucistic:242,240,236|mosaic:216,214,210|cremeino:236,214,178|black-beauty:56,54,64|caramel:196,152,102|white-face:228,226,222'
XG_DK_PAT[sugarglider]='plain|masked|striped|mottled|frosted|banded'
XG_DK_EYN[sugarglider]='ink|ruby|garnet|sable'
XG_DK_EYC[sugarglider]='30,26,36|196,68,74|146,52,58|72,56,48'
XG_DK_TMP[sugarglider]='crabby:protests, then climbs into your pocket:0.98:1.12|gliding:has already crossed the room, airborne:1.06:1.0|sweet:would eat only fruit if allowed:1.18:1.08|nocturnal:asleep all day, electric all night:0.96:0.98|bonded:will not be put down, thank you:1.0:1.24|chittery:talks the whole time:1.04:1.06'
XG_DK_BLD[sugarglider]='pocket|neat|full-caped'
XG_DK_SPAN[sugarglider]=0.72; XG_DK_ODD[sugarglider]=0.04
XG_DK_BREED[sugarglider]='Classic Grey:1:13:classic-grey:plain,striped:-:-|Leucistic:1:12:leucistic:plain:-:-|Mosaic:1:13:mosaic,platinum,classic-grey:mottled,frosted:-:-|Platinum:1:13:platinum,classic-grey:plain,striped:-:-|White Face:1:13:white-face,classic-grey:masked,plain:-:-|Cremeino:0.98:12:cremeino:plain,frosted:-:-|Black Beauty:1.02:13:black-beauty,classic-grey:striped,masked:-:-|Caramel:1:13:caramel,cremeino:banded,plain:-:-|Ringtail Mosaic:1:13:mosaic,platinum:banded,mottled:-:-|Champagne:0.98:12:cremeino,white-face:frosted,plain:-:-'
XG_SP_NM[sugarglider]='JOEY WEANLING YOUNG|GLIDER GLIDER MATURE ELDER'
XG_SP_HAPPY[sugarglider]='glided the length of the room|chittered at nothing, happily|went to sleep in a pocket'
XG_SP_NOMINAL[sugarglider]='folded up, asleep'
XG_SP_BOX[sugarglider]='the pouch wants washing'
XG_SP_FACE[sugarglider]=-1
XG_POSES[sugarglider]='xg_sugarglider_sit xg_sugarglider_baby xg_sugarglider_loaf xg_sugarglider_sleep xg_sugarglider_walk xg_sugarglider_play xg_sugarglider_flop'
XG_DK_CW[parrot]='emerald:60,164,92|scarlet:214,66,58|cobalt:56,96,204|saffron:238,196,60|slate:132,136,150|peach:238,176,136|lime:162,206,72|ash:210,206,200'
XG_DK_PAT[parrot]='plain|masked|barred|tipped|capped|spotted'
XG_DK_EYN[parrot]='amber|ink|pearl|orange'
XG_DK_EYC[parrot]='226,172,64|34,30,40|226,222,216|232,138,52'
XG_DK_TMP[parrot]='talkative:repeats the one word you regret:1.04:1.18|clever:has worked out the latch:1.0:1.06|velcro:wants to be on your shoulder, now:1.02:1.26|dramatic:screams at exactly six:1.08:1.02|shreddy:everything is confetti eventually:1.14:0.98|watchful:misses nothing in this room:0.96:0.94'
XG_DK_BLD[parrot]='pocket|trim|broad-shouldered'
XG_DK_SPAN[parrot]=0.9; XG_DK_ODD[parrot]=0.03
XG_DK_BREED[parrot]='Budgerigar:0.55:8:emerald,cobalt,saffron,ash:barred,masked:-:-|Cockatiel:0.7:18:ash,saffron,peach,slate:capped,masked:-:-|African Grey:1:50:slate,ash:plain,tipped:-:-|Blue-and-Gold Macaw:1.35:50:cobalt,saffron:masked,tipped:-:-|Scarlet Macaw:1.38:50:scarlet,cobalt,saffron:tipped,barred:-:-|Lovebird:0.6:15:emerald,peach,saffron:masked,capped:-:-|Green-Cheek Conure:0.72:25:emerald,lime,scarlet:capped,tipped:-:-|Amazon:1.1:50:emerald,lime,saffron:capped,spotted:-:-|Caique:0.78:30:lime,saffron,ash:capped,masked:-:-|Cockatoo:1.25:60:ash,peach,saffron:plain,capped:-:-|Eclectus:1.05:30:emerald,scarlet,cobalt:plain,tipped:-:-|Senegal:0.75:25:emerald,saffron,slate:masked,capped:-:-'
XG_SP_NM[parrot]='CHICK FLEDGLING YOUNG|PARROT PARROT MATURE ELDER'
XG_SP_HAPPY[parrot]='said the word, perfectly|shredded the whole thing|climbed onto your shoulder'
XG_SP_NOMINAL[parrot]='muttering, to itself'
XG_SP_BOX[parrot]='the papers want changing'
XG_SP_FACE[parrot]=-1
XG_POSES[parrot]='xg_parrot_sit xg_parrot_baby xg_parrot_loaf xg_parrot_sleep xg_parrot_walk xg_parrot_play xg_parrot_flop'
XG_DK_CW[penguin]='ink:40,42,56|slate:104,112,132|charcoal:62,62,72|steel:140,150,172|snow:242,242,246|midnight:30,32,46|dusk:82,88,112|pewter:168,172,184'
XG_DK_PAT[penguin]='plain|bibbed|banded|capped|spotted|masked'
XG_DK_EYN[penguin]='ink|amber|pearl|garnet'
XG_DK_EYC[penguin]='30,28,38|220,168,64|228,226,222|148,54,60'
XG_DK_TMP[penguin]='waddly:commits fully to every step:0.98:1.04|huddly:wants to stand very close:1.0:1.22|bossy:has opinions about the queue:1.02:0.94|tobogganny:would rather slide:1.06:1.0|formal:dressed for something:0.96:0.98|shouty:announces itself, at length:1.08:1.1'
XG_DK_BLD[penguin]='compact|upright|barrel-chested'
XG_DK_SPAN[penguin]=0.6; XG_DK_ODD[penguin]=0.02
XG_DK_BREED[penguin]='Emperor:1.35:20:ink,midnight,snow:bibbed,capped:-:-|King:1.25:26:charcoal,slate,snow:bibbed,banded:-:-|Gentoo:1.05:20:ink,steel,snow:capped,masked:-:-|Adelie:0.95:20:midnight,ink,snow:capped,plain:-:-|Chinstrap:0.95:20:ink,pewter,snow:banded,bibbed:-:-|Macaroni:0.92:20:charcoal,dusk,snow:capped,masked:-:-|Little Blue:0.6:6:steel,dusk,pewter:plain,bibbed:-:-|Rockhopper:0.8:10:midnight,charcoal,snow:capped,spotted:-:-|Magellanic:0.9:25:slate,ink,snow:banded,bibbed:-:-|Humboldt:0.9:20:charcoal,pewter,snow:banded,spotted:-:-'
XG_SP_NM[penguin]='CHICK FLEDGLING YOUNG|PENGUIN PENGUIN MATURE ELDER'
XG_SP_HAPPY[penguin]='tobogganed across the deck|stood extremely close to you|shouted at the window'
XG_SP_NOMINAL[penguin]='standing, formally'
XG_SP_BOX[penguin]='the floor wants a mop'
XG_SP_FACE[penguin]=-1
XG_POSES[penguin]='xg_penguin_sit xg_penguin_baby xg_penguin_loaf xg_penguin_sleep xg_penguin_walk xg_penguin_play xg_penguin_flop'
XG_DK_CW[drifter]='aurora:110,226,206|ember:236,142,96|amethyst:176,124,230|abyss:44,54,96|pearl:228,232,240|cobalt:70,110,226|rose-quartz:236,168,196|verdigris:96,190,164'
XG_DK_PAT[drifter]='plain|ringed|speckled|nebular|glassy|veined'
XG_DK_EYN[drifter]='starlit|ember|void|opal'
XG_DK_EYC[drifter]='226,232,246|238,150,86|38,34,56|206,222,230'
XG_DK_TMP[drifter]='placid:has never once hurried:0.86:0.96|curious:drifts to whatever is new:0.98:1.1|luminous:brightens when you come in:0.94:1.24|tidal:rises and falls on nothing:0.92:0.94|shy:folds up if you look straight at it:0.9:0.86|ancient:was here before the cabinet:0.88:1.0'
XG_DK_BLD[drifter]='slight|full-belled|deep-trailing'
XG_DK_SPAN[drifter]=1.1; XG_DK_ODD[drifter]=0.12
XG_DK_BREED[drifter]='Common Drifter:1:45:*:*:-:-|Shoal Strain:0.88:38:aurora,verdigris,pearl:speckled,ringed:-:-|Deep-Abyss Strain:1.18:80:abyss,cobalt,amethyst:nebular,veined:-:-|Ember Strain:0.96:40:ember,rose-quartz:glassy,speckled:-:-|Lantern Drifter:1.05:55:aurora,pearl,cobalt:ringed,glassy:-:-|Cathedral Bell:1.35:120:amethyst,abyss,cobalt:nebular:-:-|Rill Drifter:0.78:30:verdigris,aurora:plain,ringed:-:-|Glass Strain:0.92:42:pearl,rose-quartz,opal:glassy,veined:-:-|Tide Strain:1.1:60:cobalt,abyss,verdigris:veined,nebular:-:-'
XG_SP_NM[drifter]='SPORE BELL YOUNG|DRIFTER DRIFTER GREATER|DRIFTER ELDER|DRIFTER'
XG_SP_HAPPY[drifter]='brightened, all at once|drifted a slow circuit of the room|pulsed, twice, for no reason'
XG_SP_NOMINAL[drifter]='hanging, luminous'
XG_SP_BOX[drifter]='the tank wants topping up'
XG_SP_FACE[drifter]=1
XG_POSES[drifter]='xg_drifter_sit xg_drifter_baby xg_drifter_loaf xg_drifter_sleep xg_drifter_walk xg_drifter_play xg_drifter_flop'


xg_roster_scan() {   # every slot the save knows, read once and kept
  local k="$XG_NPETS.$XG_ACTIVE.${XG[species]:-}.${XG[name]:-}.${XG[day]:-}.${XG[health]:-}.${XG[food]:-}.${XG[water]:-}.${XG[bond]:-}.${XG[coat]:-}.${XG[mood]:-}.${XG[pep]:-}.${XG[box]:-}.${XG[c_pets]:-}"
  [[ "$k" == "$XR_KEY" ]] && return 0
  XR_KEY="$k"
  XR_NM=(); XR_SD=(); XR_SP=(); XR_SLOT=(); XR_LB=(); XR_EY=(); XR_BD=(); XR_TM=(); XR_ST=(); XR_STI=(); XR_AGE=(); XR_LEFT=(); XR_PAL=(); XR_BR=(); XR_SPN=()
  XR_DAY=(); XR_HP=(); XR_FD=(); XR_WT=(); XR_BN=(); XR_CT=(); XR_MD=(); XR_PP=(); XR_BX=()
  XR_PET=(); XR_NAP=(); XR_TRT=(); XR_CAT=(); XR_GFT=(); XR_STRK=(); XR_ALB=()
  # THE RESIDENT'S PAPERWORK IS BORROWED, NOT SPENT · xg_deal_coat writes its
  # findings into XG, so the animal in the room has its own keys lifted out
  # first and put back at the end, the way xg_stall_sprite does it.
  local -A keep; local kk
  for kk in pattern pj eyes ear_s tail_n build temper tname hunger_m social_m colorway label; do keep[$kk]="${XG[$kk]:-}"; done
  local -i i sl st; local -F days bnf L
  local nm sd bn spc sw brw                    # declared ONCE · a `local` re-run
  local -a order; order=($XG_ACTIVE)           # in the same scope prints itself
  for (( i=0; i<XG_NPETS; i++ )); do (( i != XG_ACTIVE )) && order+=($i); done
  XR_HOME=0
  for sl in "${order[@]}"; do
    if (( sl == XG_ACTIVE )); then nm="${XG[name]:-}"; else nm="${SAVE[xenogotchi.pets.$sl.name]:-}"; fi
    [[ -n "$nm" ]] || continue
    if (( sl == XG_ACTIVE )); then
      sd="${XG[seed]:-61653}"; bn="${XG[born]:-0}"; spc="${XG[species]:-cat}"
      XR_DAY+=("${XG[day]:-1}");   XR_HP+=("${XG[health]:-0}"); XR_FD+=("${XG[food]:-0}")
      XR_WT+=("${XG[water]:-0}");  XR_BN+=("${XG[bond]:-0}");   XR_CT+=("${XG[coat]:-0}")
      XR_MD+=("${XG[mood]:-0}");   XR_PP+=("${XG[pep]:-0}");    XR_BX+=("${XG[box]:-0}")
      XR_PET+=("${XG[c_pets]:-0}"); XR_NAP+=("${XG[c_naps]:-0}"); XR_TRT+=("${XG[c_treats]:-0}")
      XR_CAT+=("${XG[c_catches]:-0}"); XR_GFT+=("${XG[c_gifts]:-0}"); XR_STRK+=("${XG[streak]:-0}")
      XR_ALB+=("${XG[album]:-}")
    else
      sd="${SAVE[xenogotchi.pets.$sl.seed]:-61653}"; bn="${SAVE[xenogotchi.pets.$sl.born]:-0}"
      spc="${SAVE[xenogotchi.pets.$sl.species]:-cat}"
      XR_DAY+=("${SAVE[xenogotchi.pets.$sl.day]:-1}");    XR_HP+=("${SAVE[xenogotchi.pets.$sl.health]:-0}")
      XR_FD+=("${SAVE[xenogotchi.pets.$sl.food]:-0}");    XR_WT+=("${SAVE[xenogotchi.pets.$sl.water]:-0}")
      XR_BN+=("${SAVE[xenogotchi.pets.$sl.bond]:-0}");    XR_CT+=("${SAVE[xenogotchi.pets.$sl.coat]:-0}")
      XR_MD+=("${SAVE[xenogotchi.pets.$sl.mood]:-0}");    XR_PP+=("${SAVE[xenogotchi.pets.$sl.pep]:-0}")
      XR_BX+=("${SAVE[xenogotchi.pets.$sl.box]:-0}")
      XR_PET+=("${SAVE[xenogotchi.pets.$sl.c_pets]:-0}"); XR_NAP+=("${SAVE[xenogotchi.pets.$sl.c_naps]:-0}")
      XR_TRT+=("${SAVE[xenogotchi.pets.$sl.c_treats]:-0}"); XR_CAT+=("${SAVE[xenogotchi.pets.$sl.c_catches]:-0}")
      XR_GFT+=("${SAVE[xenogotchi.pets.$sl.c_gifts]:-0}"); XR_STRK+=("${SAVE[xenogotchi.pets.$sl.streak]:-0}")
      XR_ALB+=("${SAVE[xenogotchi.pets.$sl.album]:-}")
    fi
    [[ "$sd" == <-> ]] || sd=61653
    XR_NM+=("$nm"); XR_SD+=($sd); XR_SP+=("$spc"); XR_SLOT+=($sl)
    (( sl == XG_ACTIVE )) && XR_HOME=$(( ${#XR_NM[@]}-1 ))
    # its age today, off the same wall clock the room runs on
    bnf=0.0; [[ "$bn" == <->* ]] && bnf=$bn
    if (( bnf > 0.0 )); then days=$(( (${EPOCHSECONDS:-0}-bnf)/86400.0 )); else days=0.0; fi
    (( days < 0.0 )) && days=0.0
    XR_AGE+=($days)
    # EACH ROW'S OWN SPAN · what the save says, not what the tables say today
    if (( sl == XG_ACTIVE )); then sw="${XG[span]:-}"; brw="${XG[breed]:-}"
    else sw="${SAVE[xenogotchi.pets.$sl.span]:-}"; brw="${SAVE[xenogotchi.pets.$sl.breed]:-}"; fi
    XR_SPN+=("$sw")
    xg_stage_of $days $sd "$spc" "$sw"; st=$REPLY
    XR_STI+=($st); xg_stage_nm $st "$spc"; XR_ST+=("$REPLY")
    xg_lifespan $sd "$spc" "$brw" "$sw"; L=$REPLY
    xg_age_str $(( L-days > 0.0 ? L-days : 0.0 )); XR_LEFT+=("~$REPLY ahead, with care")
    # EACH ROW SHOWS ITS OWN ANIMAL.  A pet put away carries its paperwork in
    # the save, so the roster reads that rather than dealing the seed again --
    # which is what keeps a coat from changing under a pet you already own.
    if (( sl == XG_ACTIVE )); then
      XR_LB+=("${keep[label]:-}"); XR_EY+=("${keep[eyes]:-}"); XR_BD+=("${keep[build]:-}"); XR_TM+=("${keep[temper]:-}")
      XR_PAL+=("${XG[pal]:-}"); XR_BR+=("${XG[breed]:-}")
      [[ -n "${keep[label]:-}" ]] || { xg_wear $sd "$spc" "${XG[pal]:-}"
        XR_LB[-1]="${XG[label]}"; XR_EY[-1]="${XG[eyes]}"; XR_BD[-1]="${XG[build]}"; XR_TM[-1]="${XG[temper]}" }
    else
      local lb="${SAVE[xenogotchi.pets.$sl.label]:-}" pl="${SAVE[xenogotchi.pets.$sl.pal]:-}"
      if [[ -n "$lb" ]]; then
        XR_LB+=("$lb");                                    XR_EY+=("${SAVE[xenogotchi.pets.$sl.eyes]:-}")
        XR_BD+=("${SAVE[xenogotchi.pets.$sl.build]:-}");   XR_TM+=("${SAVE[xenogotchi.pets.$sl.temper]:-}")
        XR_BR+=("${SAVE[xenogotchi.pets.$sl.breed]:-}")
      else
        # A ROW FROM BEFORE BREEDS · dealt the old way, then named
        xg_deal_coat $sd "$spc" '*'
        XR_LB+=("${XG[label]}"); XR_EY+=("${XG[eyes]}"); XR_BD+=("${XG[build]}"); XR_TM+=("${XG[temper]}")
        xg_breed_infer "$spc" "${XG[colorway]}" "${XG[pattern]}" $sd; XR_BR+=("$REPLY")
      fi
      XR_PAL+=("$pl")
    fi
  done
  for kk in ${(k)keep[@]}; do XG[$kk]="${keep[$kk]}"; done
  XG_PAL_KEY=''                              # the resident re-deals its own palette next render
  XR_N=${#XR_NM[@]}
  (( XR_ROW >= XR_N )) && XR_ROW=$(( XR_N > 0 ? XR_N-1 : 0 ))
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# LETTING ONE GO · the only thing in here that cannot be undone
# ══════════════════════════════════════════════════════════════════════════
# The house asks once, in the same language the cabinet asks before it powers
# down: the word large on the glass, the question under it, and the two
# answers where the hands already are.  A thing that cannot be taken back is
# worth a screen of its own.
typeset -gi XG_REL_SLOT=-1
typeset -g  XG_REL_NAME='' XG_REL_LABEL='' XG_REL_SP=''
typeset -gi XG_REL_DAYS=0

xg_release_ask() {   # xg_release_ask SLOT — stand the gate up for that animal
  local -i slot=$1
  (( slot < 0 || slot >= XG_NPETS )) && return 1
  # THE HOUSE IS NEVER EMPTY.  Releasing the last animal would leave a room
  # with nothing in it and every page asking after somebody who is not there,
  # so the last one stays until another has been signed for.
  local -i alive=0 i
  for (( i=0; i<XG_NPETS; i++ )); do
    if (( i == XG_ACTIVE )); then [[ -n "${XG[name]:-}" ]] && (( alive++ ))
    else [[ -n "${SAVE[xenogotchi.pets.$i.name]:-}" ]] && (( alive++ )); fi
  done
  (( alive < 2 )) && { xg_log 'the house cannot be empty · sign for another first' '' $AMBER; return 1 }
  if (( slot == XG_ACTIVE )); then
    XG_REL_NAME="${XG[name]:-}"; XG_REL_LABEL="${XG[label]:-}"; XG_REL_SP="${XG[species]:-}"
    XG_REL_DAYS=${XG[day]:-1}
  else
    XG_REL_NAME="${SAVE[xenogotchi.pets.$slot.name]:-}"
    XG_REL_LABEL="${SAVE[xenogotchi.pets.$slot.label]:-}"
    XG_REL_SP="${SAVE[xenogotchi.pets.$slot.species]:-}"
    XG_REL_DAYS=${SAVE[xenogotchi.pets.$slot.day]:-1}
  fi
  [[ -n "$XG_REL_NAME" ]] || return 1
  XG_REL_SLOT=$slot
  xg_go_view release
  return 0
}

xg_draw_release() {   # the gate · the word, the question, and what it costs
  local -F t=$XG_NOW
  local -i i x y0 glow ink
  local -a fk fv
  (( XI_LO )) || xg_ink                     # the ramp, if nothing has asked yet
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  local word='RELEASE'
  big_width "$word"
  y0=$(( (SCR_H-16)/2 )); (( y0 < 1 )) && y0=1
  cmix $RED $AMBER 0.5; glow=$CM
  big_word "$word" $(( (SCR_W-BW)/2 )) $y0 $glow
  wave $t $MO_BREATHE 0
  cmix $RED $AMBER $(( 0.35+0.35*WV )); ink=$CM
  big_lit $ink
  local q="LET ${XG_REL_NAME} GO?"
  v_center $(( y0+7 )) "$q" $XG_WHITE
  local yes='[ Y ]  RELEASE' no='[ N ]  KEEP IT'
  wave $t $MO_ALERT 0
  cmix $RED $WHITE $(( 0.25*WV ))
  v_text $(( SCR_W/2-${#yes}-3 )) $(( y0+9 )) "$yes" $CM
  cmix $LIME $WHITE 0.2
  v_text $(( SCR_W/2+3 )) $(( y0+9 )) "$no" $CM
  # THE THREE FACTS · a question that cannot be undone should say what it does
  local -i days=$XG_REL_DAYS
  fk=('the animal' 'your days with it' 'this')
  xg_ell "${XG_REL_NAME} · ${XG_REL_LABEL}" 23; local f0="$REPLY"
  fv=("$f0" "$days, ending today" 'cannot be undone')
  x=$(( (SCR_W-3*24)/2 )); (( x < 0 )) && x=0
  for (( i=0; i<3; i++ )); do
    cshade $DIM 1.3;  v_text $(( x+i*24 )) $(( y0+12 )) "${fk[$i]}" $CS
    cshade $GREY 1.0; v_text $(( x+i*24 )) $(( y0+13 )) "${fv[$i]}" $CS
  done
  # the ramp's own floor rather than the driver's · 2.9:1 is under it
  v_center $(( y0+15 )) 'the house keeps everything else · only this one leaves' $XI_LO
  app_nav '[Y]' release '[N]' 'keep it' '[⎋]' 'keep it'
  return 0
}

xg_release_do() {   # let the animal at XG_REL_SLOT go, and mind the room
  local -i slot=$XG_REL_SLOT
  (( slot < 0 )) && return 1
  local nm="$XG_REL_NAME" sp="$XG_REL_SP"
  local -i i nxt=-1
  # whoever is in the room is put away first, so nothing in flight is lost
  xg_save_write; save_load
  if (( slot == XG_ACTIVE )); then
    # SOMEBODY ELSE TAKES THE ROOM · the first slot that still has a name
    for (( i=0; i<XG_NPETS; i++ )); do
      (( i == slot )) && continue
      [[ -n "${SAVE[xenogotchi.pets.$i.name]:-}" ]] && { nxt=$i; break }
    done
    (( nxt < 0 )) && return 1
    XG_ACTIVE=$nxt
    xg_pet_read $nxt
    xg_age_sync; xg_apply_clock; xg_day_catchup
    XG_FRESH=0
    xg_wear ${XG[seed]} "${XG[species]}" "${XG[pal]:-}"
    xg_actor_init
    XG_CACHE_KEY=''; XG_PAL_KEY=''; XG_CAMF=-1.0
  fi
  XG_DROP=$slot                                   # its lines go on the next write
  XG_FREED+=("$slot|$nm|$sp|${EPOCHSECONDS:-0}")  # and the file remembers it left
  XG_RCK=''; XR_KEY=''; XG_PGK=''; XG_SS_C=(); XG_SS_A=()
  XG_REL_SLOT=-1
  xg_save_write
  XG_DROP=-1
  xg_log "$nm was released · the house keeps its thanks" '' $AMBER
  xg_go_view stats
  return 0
}

# ── the page's own geometry · the same split the catalogue uses, so the two
#    pages read as one machine, and the same window when the list outruns it ──
typeset -gi XR_LX=1 XR_LW=40 XR_PX=44 XR_PW=60 XR_Y0=2 XR_Y1=27
typeset -gi XR_H=20 XR_PAD=0 XR_TOP=0 XR_SCROLL=0
typeset -ga XR_LR_KIND XR_LR_IX; typeset -gi XR_LR_N=0

xg_stats_geom() {
  local -i lw
  XR_Y0=2; XR_Y1=$(( SCR_H-3 ))
  lw=$(( SCR_W*40/100 )); (( lw > 44 )) && lw=44; (( lw < 26 )) && lw=26
  XR_LX=1; XR_LW=$lw
  XR_PX=$(( XR_LX+XR_LW+3 )); XR_PW=$(( SCR_W-1-XR_PX ))
  XR_H=$(( XR_Y1-2-XR_Y0+1 ))
  xg_stats_rows
  if (( XR_LR_N <= XR_H )); then XR_SCROLL=0; XR_TOP=0; XR_PAD=$(( (XR_H-XR_LR_N)/2 ))
  else XR_SCROLL=1; XR_PAD=0; fi
  return 0
}
xg_stats_rows() {   # the flat list · a header, then three lines an animal
  XR_LR_KIND=(); XR_LR_IX=()
  local -i i
  for (( i=0; i<XR_N; i++ )); do
    if (( i == 0 )); then XR_LR_KIND+=(h); XR_LR_IX+=(0)
    elif (( i == 1 )); then XR_LR_KIND+=(g); XR_LR_IX+=(0); XR_LR_KIND+=(h); XR_LR_IX+=(1)
    else XR_LR_KIND+=(g); XR_LR_IX+=(0); fi
    XR_LR_KIND+=(0 1 2); XR_LR_IX+=($i $i $i)
  done
  XR_LR_N=${#XR_LR_KIND[@]}
  return 0
}
xg_stats_rowix() {   # xg_stats_rowix I → REPLY the row holding that animal's name
  local -i j
  for (( j=0; j<XR_LR_N; j++ )); do
    [[ "${XR_LR_KIND[$j]}" == 0 ]] && (( XR_LR_IX[j] == $1 )) && { REPLY=$j; return 0 }
  done
  REPLY=0
}
xg_stats_scroll() {   # keep the one under the cursor (and its header) in view
  (( XR_SCROLL )) || { XR_TOP=0; return 0 }
  xg_stats_rowix $XR_ROW; local -i r=$REPLY t=$XR_TOP
  (( r > 0 )) && [[ "${XR_LR_KIND[$(( r-1 ))]}" == h ]] && r=$(( r-1 ))
  xg_scroll_into $r $t $XR_H $XR_LR_N; t=$REPLY
  xg_scroll_into $(( r+2 )) $t $XR_H $XR_LR_N; XR_TOP=$REPLY
  return 0
}

xg_stats_line() {   # xg_stats_line J ON — one flat row, wherever the window has it
  local -i j=$1 on=$2 i y col sel w x hp
  local k="${XR_LR_KIND[$j]}" st
  y=$(( XR_Y0+XR_PAD+j-XR_TOP ))
  (( y < XR_Y0 || y > XR_Y0+XR_H-1 )) && return 0
  (( XI_LO )) || xg_ink
  w=$(( XR_LW-2 ))
  case "$k" in
    g) v_fill $XR_LX $y $XR_LW 1 ' ' $GREY $GLASS ;;
    h) v_fill $XR_LX $y $XR_LW 1 ' ' $GREY $GLASS
       if (( XR_LR_IX[j] == 0 )); then st='IN THE ROOM'; col=$AMBER; else st='ALSO SIGNED FOR'; cshade $CYAN 0.9; col=$CS; fi
       v_text $(( XR_LX+1 )) $y "$st" $col
       x=$(( XR_LX+2+${#st} ))
       if (( XR_LR_IX[j] == 0 )); then st='today'; else st="$(( XR_N-1 )) more"; fi
       xg_rule_at $x $y $(( XR_LX+w-1-${#st}-x )) $XI_RULE '─'
       v_text $(( XR_LX+w-${#st} )) $y "$st" $XI_LO ;;
    *) i=${XR_LR_IX[$j]}
       sel=-2
       if (( on )); then cmix $GLASS $PURPLE 0.18; sel=$CM; v_fill $XR_LX $y $XR_LW 1 ' ' $GREY $sel
       else v_fill $XR_LX $y $XR_LW 1 ' ' $GREY $GLASS; fi
       (( on )) && { cmix $CYAN $WHITE 0.2; v_put $XR_LX $y '▌' $CM $sel; }
       case "$k" in
         0) if (( on )); then col=$XG_WHITE; else col=$XI_HI; fi
            xg_ell "${(U)XR_NM[$i]}" $(( w-14 ))
            v_text $(( XR_LX+4 )) $y "$REPLY" $col $sel
            if (( i == XR_HOME )); then cshade $LIME 0.8; v_text $(( XR_LX+w-6 )) $y '· home' $CS $sel
            else
              # the lit row's ground is a purple wash, which is LIGHTER than
              # the glass · the floor ink reads 2.6:1 on it, so a lit row's
              # asides step up to the body ink to stay over 3:1
              (( on )) && col=$XI_TX || col=$XI_LO
              xg_ell "${(L)XR_ST[$i]}" 11; v_text $(( XR_LX+w-${#REPLY} )) $y "$REPLY" $col $sel
            fi ;;
         1) (( on )) && col=$XI_TX || col=$XI_LO
            xg_ell "${XR_LB[$i]}" $(( w-5 ))
            v_text $(( XR_LX+4 )) $y "$REPLY" $col $sel ;;
         2) (( on )) && col=$XI_TX || col=$XI_LO
            xg_age_str ${XR_AGE[$i]}
            st="day ${XR_DAY[$i]} · $REPLY"
            v_text $(( XR_LX+4 )) $y "$st" $col $sel
            hp=${XR_HP[$i]}
            if (( hp < 45 )); then cshade $RED 1.1; col=$CS; elif (( hp < 80 )); then cshade $AMBER 0.85; col=$CS; else cshade $LIME 0.7; col=$CS; fi
            st="health $hp"
            v_text $(( XR_LX+w-${#st} )) $y "$st" $col $sel ;;
       esac ;;
  esac
  return 0
}

xg_stats_bg() {   # the list, painted once and kept
  local -i j
  (( XI_LO )) || xg_ink
  for (( j=XR_TOP; j<XR_LR_N && j<XR_TOP+XR_H; j++ )); do xg_stats_line $j 0; done
  xg_scroll_mark $(( XR_LX+XR_LW-1 )) $XR_Y0 $XR_H $XR_TOP $XR_H $XR_LR_N
  # the house, at the foot of the roster · what the whole place adds up to
  local st; local -i col
  cmix $GREY $CYAN 0.25; col=$CM
  v_text $(( XR_LX+1 )) $(( XR_Y1-1 )) 'THE HOUSE' $col
  if (( XR_N == 1 )); then st='1 adopted'; else st="$XR_N adopted"; fi
  v_text $(( XR_LX+XR_LW-3-${#st} )) $(( XR_Y1-1 )) "$st" $AMBER
  xg_litter_code; local lc="$REPLY"
  local -a lg; lg=('intake ' $XI_LO "$lc" $CYAN ' · pantry ' $XI_LO "${XG_HOUSE[pantry]:-0}" $LIME)
  v_segs $(( XR_LX+1 )) $XR_Y1 -- "${lg[@]}"
  xg_panel $XR_PX $XR_Y0 $XR_PW $(( XR_Y1-XR_Y0+1 )) 'THE PAPERS'
  return 0
}

xg_stats_fg() {   # the card · everything about the one under the cursor
  local -i i=$XR_ROW y x ix iw tx tw ay ah col chip home hp r0 n mw g
  local st nm s
  (( XI_LO )) || xg_ink
  xg_stats_rowix $i; r0=$REPLY
  for (( x=0; x<3; x++ )); do xg_stats_line $(( r0+x )) 1; done
  home=$(( i == XR_HOME ))
  ix=$(( XR_PX+2 )); iw=$(( XR_PW-4 ))
  s=" $(( i+1 )) OF $XR_N "
  v_text $(( XR_PX+XR_PW-3-${#s} )) $XR_Y0 "$s" $XI_LO $GLASS
  # ── the animal itself · its own portrait at its own age.  The picture
  #    takes a COLUMN, not a strip across the top: its width is measured off
  #    the card so the words beside it always have somewhere to go, and only
  #    a card too narrow for both stacks them.
  local -i aw stack=0
  ah=11; ay=$(( XR_Y0+1 ))
  aw=26; (( aw > iw-28 )) && aw=$(( iw-28 ))
  if (( aw < 16 )); then aw=$iw; stack=1; fi
  xg_stats_art $i $ix $ay $aw $ah
  if (( stack )); then tx=$ix; tw=$iw; ay=$(( ay+ah-8 ))
  else tx=$(( ix+aw+2 )); tw=$(( iw-aw-2 )); fi
  nm="${(U)XR_NM[$i]}"
  xg_spaced "$nm"
  (( ${#REPLY} > tw )) && st="$nm" || st="$REPLY"
  if (( home )); then cmix $AMBER $WHITE 0.1; col=$CM; else cmix $CYAN $WHITE 0.15; col=$CM; fi
  xg_gtext $tx $(( ay+1 )) "$st" $col $XG_WHITE
  xg_age_str ${XR_AGE[$i]}; local ag="$REPLY"
  cshade $AMBER 0.9; v_text $tx $(( ay+2 )) "${XR_ST[$i]}" $CS
  xg_ell "· $ag old · day ${XR_DAY[$i]}" $(( tw-${#XR_ST[$i]}-2 ))
  v_text $(( tx+1+${#XR_ST[$i]} )) $(( ay+2 )) "$REPLY" $XI_LO
  if (( home )); then cshade $LIME 0.35; chip=$CS; v_text $tx $(( ay+3 )) ' ✦ IN THE ROOM ' $XG_WHITE $chip
  else cmix $GLASS $GREY 0.22; chip=$CM; v_text $tx $(( ay+3 )) ' SIGNED FOR ' $XI_HI $chip; fi
  # THE PAPERS RIDE BESIDE THE NAME.  They were a block of their own under the
  # meters, which on the float glass was the first thing to fall off the
  # bottom -- and the genetics card belongs with the animal's name anyway.
  local -a kl kv; kl=(BREED COAT EYES BUILD); kv=("${XR_BR[$i]:-}" "${XR_LB[$i]}" "${XR_EY[$i]}" "${XR_BD[$i]}")
  # FOUR KEYS DEEP NOW, so the block starts a line higher: the air it used
  # to have above it goes BELOW it instead, where it separates a table from
  # two lines of prose.  Above it the chip is a filled chip and holds its
  # own edge without help.
  for (( x=0; x<4; x++ )); do
    v_text $tx $(( ay+4+x )) "${(r:7:)kl[x]}" $XI_LO
    xg_ell "${kv[$x]}" $(( tw-8 ))
    v_text $(( tx+8 )) $(( ay+4+x )) "$REPLY" $XI_TX
  done
  xg_ell "${XR_TM[$i]}" $tw
  v_text $tx $(( ay+9 )) "$REPLY" $XI_TX
  xg_ell "${XR_LEFT[$i]}" $tw
  v_text $tx $(( ay+10 )) "$REPLY" $XI_LO
  # ── the blocks below.  ITS NEEDS flows DOWN from the portrait and LIFETIME
  #    hangs off the FOOT -- the catalogue's own trick -- so a taller glass
  #    opens its air BETWEEN them rather than leaving a hole under everything.
  #    Whatever room that leaves in the middle goes to the album, if it has one.
  local -i fy=$(( XR_Y1-3 ))                 # the foot, where the doctor stands
  local -i ny=$(( XR_Y0+1+ah )) ly my an
  (( stack )) && ny=$(( ay+9 ))
  mw=$(( iw/2-12 )); (( mw > 14 )) && mw=14; (( mw < 7 )) && mw=7
  g=$(( (fy-ny-5)/3 )); (( g < 1 )) && g=1; (( g > 3 )) && g=3
  y=$(( ny+g ))
  cshade $AMBER 0.85; v_text $ix $y 'ITS NEEDS' $CS
  xg_rule_at $(( ix+10 )) $y $(( iw-11 )) $XI_RULE '┄'
  local -i c2=$(( ix+mw+13 ))
  xg_meter_on $ix $(( y+1 )) $mw FOOD   ${XR_FD[$i]} $XG_FG  -2
  xg_meter_on $ix $(( y+2 )) $mw WATER  ${XR_WT[$i]} $XG_COOL -2
  xg_meter_on $ix $(( y+3 )) $mw HEALTH ${XR_HP[$i]} $XG_OK  -2
  xg_meter_on $ix $(( y+4 )) $mw BOND   ${XR_BN[$i]} $XG_WARM -2
  if (( c2+mw+11 <= ix+iw )); then
    xg_meter_on $c2 $(( y+1 )) $mw COAT   ${XR_CT[$i]} $AMBER  -2
    xg_meter_on $c2 $(( y+2 )) $mw MOOD   ${XR_MD[$i]} $PURPLE -2
    xg_meter_on $c2 $(( y+3 )) $mw PEP    ${XR_PP[$i]} $CYAN   -2
    xg_meter_on $c2 $(( y+4 )) $mw LITTER ${XR_BX[$i]} $XG_WARN -2
    y=$(( y+5 ))
  else
    xg_meter_on $ix $(( y+5 )) $mw COAT   ${XR_CT[$i]} $AMBER  -2
    xg_meter_on $ix $(( y+6 )) $mw MOOD   ${XR_MD[$i]} $PURPLE -2
    xg_meter_on $ix $(( y+7 )) $mw PEP    ${XR_PP[$i]} $CYAN   -2
    y=$(( y+8 ))
  fi
  # what it has done with its days · anchored to the foot
  ly=$(( fy-4 )); (( ly < y+1 )) && ly=$(( y+1 ))   # never shoulder-to-shoulder with the meters
  if (( ly+2 <= fy-1 )); then
    cshade $AMBER 0.85; v_text $ix $ly 'LIFETIME' $CS
    xg_rule_at $(( ix+9 )) $ly $(( iw-10 )) $XI_RULE '┄'
    local -a lf add
    lf=("${XR_DAY[$i]}" $XG_FG ' days · ' $XI_LO "${XR_PET[$i]}" $XG_WHITE ' petted · ' $XI_LO \
        "${XR_NAP[$i]}" $XG_WHITE ' naps · ' $XI_LO "${XR_TRT[$i]}" $XG_WHITE ' treats' $XI_LO)
    # the tail gives before the panel's border does
    add=(' · ' $XI_LO "${XR_CAT[$i]}" $XG_WHITE ' caught' $XI_LO)
    xg_seglen "${lf[@]}" "${add[@]}"; (( REPLY <= iw )) && lf+=("${add[@]}")
    add=(' · ' $XI_LO "${XR_GFT[$i]}" $XG_WHITE ' gifts' $XI_LO)
    xg_seglen "${lf[@]}" "${add[@]}"; (( REPLY <= iw )) && lf+=("${add[@]}")
    v_segs $ix $(( ly+1 )) -- "${lf[@]}"
    if (( XR_STRK[i] > 0 )); then st="a ${XR_STRK[$i]} day streak of good care"
    else st='no streak yet · care two days running'; fi
    v_text $ix $(( ly+2 )) "$st" $XI_LO
  else ly=$fy; fi
  # the album · what it has brought you, when the card has the air for it
  local -a ab; ab=(${(s:|:)XR_ALB[$i]})
  an=${#ab[@]}
  if (( an > 0 && ly-y >= 4 )); then
    # a gift's name is a sentence ("a USB-A plug, the wrong way up"), so the
    # columns are measured off the card rather than fixed at three
    local -i ncol=$(( iw/30 )); (( ncol < 1 )) && ncol=1; (( ncol > 3 )) && ncol=3
    local -i cwn=$(( iw/ncol )) rows=$(( (an+ncol-1)/ncol )) room=$(( ly-y-2 ))
    (( rows > room )) && rows=$room; (( rows > 4 )) && rows=4
    my=$(( y+(ly-y-1-rows)/2 )); (( my < y+1 )) && my=$(( y+1 ))
    cshade $AMBER 0.85; v_text $ix $my 'BROUGHT TO YOU' $CS
    xg_rule_at $(( ix+15 )) $my $(( iw-16 )) $XI_RULE '┄'
    for (( x=0; x<an && x<rows*ncol; x++ )); do
      xg_ell "${ab[$x]}" $(( cwn-3 ))
      v_text $(( ix+(x%ncol)*cwn )) $(( my+1+x/ncol )) "▪ $REPLY" $XI_TX
    done
    (( an > rows*ncol )) && v_text $(( ix+iw-12 )) $my "+$(( an-rows*ncol )) more" $XI_LO
  fi
  # ── the doctor, and the keys that only the resident answers to ──
  y=$fy
  xg_rule_at $ix $y $iw $XI_RULE '┄'
  hp=${XR_HP[$i]}
  if (( ! home )); then
    v_text $ix $(( y+1 )) "put away · ${XR_NM[$i]} is not the one in the room" $XI_LO
    # THE OFFER, where the eye already is · the footer says it too
    v_text $ix $(( y+2 )) '⏎ brings it in · ▴ ▾ the roster' $XI_TX
  elif (( XG_RENAME )); then
    local -i rb; cmix $GLASS $CYAN 0.12; rb=$CM
    v_fill $ix $(( y+1 )) $iw 1 ' ' $GREY $rb
    cshade $CYAN 1.1; v_text $ix $(( y+1 )) 'NEW NAME' $CS $rb
    cmix $WHITE $AMBER 0.3; v_text $(( ix+9 )) $(( y+1 )) "▸ ${XG_RENAME_BUF}" $CM $rb
    (( (int(XG_NOW*2))%2 )) && v_put $(( ix+11+${#XG_RENAME_BUF} )) $(( y+1 )) '_' $CYAN $rb
    v_text $ix $(( y+2 )) '[⏎] save the name   [⎋] leave it' $XI_TX
  else
    if   (( hp < 45 )); then cshade $AMBER 1.1; v_text $ix $(( y+1 )) 'unwell · the log has been coughing' $CS
    elif (( hp < 80 )); then cshade $AMBER 0.9; v_text $ix $(( y+1 )) 'a little run down lately' $CS
    else                     v_text $ix $(( y+1 )) 'healthy, on paper' $XG_OK; fi
    if (( ${XG[credits]:-0} >= 45 )); then st="the vet, 45 c · ${XG[credits]:-0} on hand"
    else st="the vet, 45 c · short by $(( 45-${XG[credits]:-0} ))"; fi
    v_segs $ix $(( y+2 )) -- '[N]' $AMBER ' rename · ' $XI_LO '[V]' $AMBER " $st" $XI_LO
  fi
  if (( XG_RENAME )); then app_nav 'type' 'a new name' '⏎' 'and it is hers' '[⎋]' 'leave it'
  elif (( home )); then    app_nav '▴ ▾' 'the roster' '[N]' rename '[V]' vet '[R]' release '[H]' home '[⎋]' menu
  else                     app_nav '▴ ▾' 'the roster' '⏎' 'into the room' '[R]' release '[H]' home '[⎋]' menu; fi
  return 0
}

# ── the portrait · the animal at its own age, on a lit plinth, cached ──
typeset -gA XR_ART_G XR_ART_F XR_ART_B
xg_stats_art() {   # xg_stats_art I X0 Y0 W H
  local -i i=$1 x0=$2 y0=$3 w=$4 h=$5 x y k n=0 c1 col
  local -i base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  local key="${XR_SP[$i]}.${XR_SD[$i]}.${XR_STI[$i]}.$w.$h" gs=''
  local -a fs bs
  if [[ -n "${XR_ART_G[$key]:-}" ]]; then
    gs="${XR_ART_G[$key]}"; fs=(${=XR_ART_F[$key]}); bs=(${=XR_ART_B[$key]}); n=0
    for (( y=y0; y<y0+h; y++ )); do for (( x=x0; x<x0+w; x++ )); do
      k=$(( base+y*TCOLS+x )); GCH[$k]="${gs[$n]}"; GF[$k]=${fs[$n]}; GB[$k]=${bs[$n]}; n=$(( n+1 ))
    done; done
    return 0
  fi
  v_fill $x0 $y0 $w $h ' ' $GREY $GLASS
  if (( i == XR_HOME )); then col=$AMBER; else cshade $CYAN 0.9; col=$CS; fi
  xg_cglow $(( x0+w/2 )) $(( y0+h/2-1 )) $(( w/2 )) $(( h/2+1 )) $col 0.26
  cmix $GREY $col 0.28; cshade $CM 0.75; c1=$CS
  v_fill $(( x0+2 )) $(( y0+h-1 )) $(( w-4 )) 1 ' ' $GREY $c1
  xg_stall_sprite ${XR_SD[$i]} ${XR_AGE[$i]} "${XR_SP[$i]}" open "${XR_PAL[$i]:-}" "${XR_SPN[$i]:-}" "${XR_BR[$i]:-}"
  local -i px=$(( x0+(w-XG_CCW)/2 )) py=$(( y0+h-1-XG_CCH ))
  (( py < y0 )) && py=$y0
  xg_cell_shadow $px $py 0.40
  xg_blit_cells $px $py
  fs=(); bs=()
  for (( y=y0; y<y0+h; y++ )); do for (( x=x0; x<x0+w; x++ )); do
    k=$(( base+y*TCOLS+x )); gs+="${GCH[$k]:- }"; fs+=(${GF[$k]:--1}); bs+=(${GB[$k]:--1})
  done; done
  XR_ART_G[$key]="$gs"; XR_ART_F[$key]="${fs[*]}"; XR_ART_B[$key]="${bs[*]}"
  return 0
}

xg_draw_stats() {
  xg_roster_scan; xg_stats_geom; xg_stats_scroll
  if (( XR_N == 0 )); then                     # a house with nobody in it yet
    v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
    (( XI_LO )) || xg_ink
    xg_head STATS 1 - 'NOBODY SIGNED FOR YET' $XG_LBL
    v_text $(( (SCR_W-38)/2 )) $(( SCR_H/2 )) 'the roster is empty · [A] the centre' $XI_TX
    app_nav '◂ ▸' pages '[A]' 'the centre' '[⎋]' menu
    return 0
  fi
  local key="stats.${SCR_W}x${SCR_H}.$XR_ROW.$XR_TOP.$XR_KEY.$XG_RENAME.$XG_RENAME_BUF"
  (( XG_RENAME )) && key+=".$(( int(XG_NOW*2)%2 ))"
  local bgk="stats.${SCR_W}x${SCR_H}.$XR_TOP.$XR_KEY"
  if (( XG_PG_USE )) && [[ "$key" == "$XG_PGK" ]]; then
    xg_pg_load
  else
    if (( XG_PG_USE )) && [[ "$bgk" == "$XG_BGK" ]]; then xg_bg_load
    else
      v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
      xg_stats_bg
      (( XG_PG_USE )) && { xg_bg_save; XG_BGK="$bgk"; }
    fi
    xg_stats_fg
    (( XG_PG_USE )) && { xg_pg_save; XG_PGK="$key"; }
  fi
  xg_head STATS 1 \
     HEALTH "${XG[health]:-0}" $XG_OK \
     CREDITS "${XG[credits]:-0}" $XG_FG \
     - "· ${XR_N} SIGNED FOR" $XG_LBL
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# ADOPT · the adoption centre, as the original drew it · and WELCOME HOME
# ══════════════════════════════════════════════════════════════════════════
# Intake night: four arrivals dealt from the genetics deck (base = litter x 977,
# s = base + k x 131 + 7, unique by label — the original's dealing), each at
# the age it arrives at, in its own stall: the animal, its paperwork name, its
# temperament and eyes, its stage, its age and the life left to it, and two
# little bars for PEP and SASS.  ◂ ▸ walks the stalls, [R] deals another
# litter, ⏎ takes the one under the light to WELCOME HOME, where it waits for
# a name to be typed.  A fresh house opens HERE, on its first intake night.
typeset -gi XG_ASEL=0 XG_ASCAN=0 XG_WSEED=0; typeset -g XG_WSP='cat'
# ── THE INTAKE WINDOW · the doors only open on four species at a time ───────
# An adoption centre with all twenty-five species behind the door every night
# is a catalogue, not an intake: there is nothing to come back for.  So the
# house takes four of them at a time and holds them for four hours of WALL
# clock -- not of play time, and not of how many litters you have dealt, so
# it turns while the cabinet is closed and is the same four on every machine
# the save is carried to.  Inside a window ▴ ▾ still deals: the animals
# change, the species do not, and the card says when they will.
typeset -gi XG_WIN_SECS=14400          # four hours
typeset -gi XG_CLOCK_SET=-1            # a test pins the wall clock here
typeset -ga XG_WIN_SP; XG_WIN_SP=()    # the four on offer
typeset -gi XG_WIN_N=-1 XG_AWIN=-1     # which window they were drawn for

xg_wall() {   # → REPLY the wall clock · pinned when a test needs it to hold still
  REPLY=$(( XG_CLOCK_SET >= 0 ? XG_CLOCK_SET : ${EPOCHSECONDS:-0} ))
}
xg_intake_win() {   # → REPLY which four-hour window we are in
  local -i t; xg_wall; t=$REPLY; REPLY=$(( t / XG_WIN_SECS ))
}
xg_intake_left() {  # → REPLY seconds until the doors change
  local -i t; xg_wall; t=$REPLY; REPLY=$(( XG_WIN_SECS - t % XG_WIN_SECS ))
}
xg_intake_pool() {   # xg_intake_pool WINDOW — the four species this one offers
  local -i w=$1 i n pick
  (( w == XG_WIN_N && ${#XG_WIN_SP[@]} == 4 )) && return 0
  # drawn WITHOUT replacement, so the four are always four different animals
  local -a pool; pool=("${XG_SPECIES[@]}"); n=${#pool[@]}
  XG_WIN_SP=()
  for (( i=0; i<4 && n>0; i++ )); do
    xg_gh $w $(( 300+i )); pick=$(( XG_H % n ))
    XG_WIN_SP+=("${pool[$pick]}")
    pool[$pick]="${pool[$(( n-1 ))]}"
    pool=("${pool[@]:0:$(( n-1 ))}")
    n=$(( n-1 ))
  done
  XG_WIN_N=$w
  return 0
}
typeset -g  XG_WBUF=''                 # the name being written on the card
typeset -ga XG_ADS XG_ADSP XG_ADL XG_ADE XG_ADT XG_ADP XG_ADSS XG_ADAGE XG_ADBR XG_ADSPN
typeset -ga XG_ADTM XG_ADBD XG_ADBS XG_ADAP XG_ADAS XG_ADCO XG_ADCS XG_ADST XG_ADSI XG_ADAG XG_ADLF
xg_litter_code() {   # xg_litter_code [N] → REPLY · the night's manifest number
  # A LITTER IS A SHIPMENT, and a shipment carries a number, not a tally.
  # There are a billion possible nights now; a decimal count of one runs to
  # ten digits and shoulders the register line off the card.  Base 36 says
  # the same thing in six characters, always the same six, and reads like
  # something stamped on the side of a crate.
  local -i n=${1:-${XG_HOUSE[litter]:-1}} i d
  local -a D; D=(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)
  local out=''
  (( n < 0 )) && n=0
  while (( 1 )); do d=$(( n%36 )); out="${D[$d]}$out"; n=$(( n/36 )); (( n )) || break; done
  REPLY="$out"
}

xg_litter_deal() {   # four seeds for house litter N, unique by label
  # WHERE THE ARRIVALS COME FROM.  This used to walk a ruler -- litter*977,
  # then steps of 131 -- which is tidy and which quietly caps the whole
  # intake: a million litters on a fixed stride only ever reach a few
  # million of the seeds that exist.  A seed is now the hash of (litter, k),
  # so the four cards on any given night are drawn from the entire space and
  # two litters share an animal only by coincidence.  Nothing already signed
  # for moves: a resident's seed is written in its save and read from there.
  # AND WHAT SPECIES THEY ARE IS NO LONGER THE SEED'S TO SAY.  One card per
  # species the window is offering, so the four you cycle through are the
  # four on the door; the seed still decides everything else about them.
  local -i litter=${XG_HOUSE[litter]:-1} k s i n dup try np
  xg_intake_win; xg_intake_pool $REPLY
  np=${#XG_WIN_SP[@]}
  XG_ADS=(); XG_ADSP=(); n=0
  local -a labels; labels=(); local sp
  for (( k=0; k<4; k++ )); do
    if (( np )); then sp="${XG_WIN_SP[$(( k%np ))]}"; else xg_gh $litter $(( 70+k )); xg_species_of $(( XG_H & 0xFFFFFFFF )); sp="$REPLY"; fi
    s=1
    for (( try=0; try<10; try++ )); do
      xg_gh $litter $(( 70+k*10+try )); s=$(( XG_H & 0xFFFFFFFF )); (( s == 0 )) && s=1
      xg_deal_coat $s "$sp"
      dup=0; for (( i=0; i<n; i++ )); do [[ "${labels[$i]}" == "${XG[label]}" ]] && { dup=1; break }; done
      (( dup )) || break
    done
    labels+=("${XG[label]}"); XG_ADS+=($s); XG_ADSP+=("$sp"); (( n++ ))
  done
  return 0
}
xg_adopt_scan() {   # deal the litter and keep each arrival's card · the resident's paperwork untouched
  local -i i s pep sas; local k
  local -A keep
  for k in pattern pj eyes ears tail ear_s tail_n build temper tname hunger_m social_m colorway label; do keep[$k]="${XG[$k]:-}"; done
  xg_litter_deal
  XG_ADL=(); XG_ADE=(); XG_ADT=(); XG_ADP=(); XG_ADSS=(); XG_ADAGE=(); XG_ADBR=(); XG_ADSPN=()
  XG_ADTM=(); XG_ADBD=(); XG_ADBS=(); XG_ADAP=(); XG_ADAS=(); XG_ADCO=(); XG_ADCS=()
  XG_ADST=(); XG_ADSI=(); XG_ADAG=(); XG_ADLF=()
  local sp; local -F lf spn
  for (( i=0; i<4; i++ )); do
    s=${XG_ADS[$i]}; sp="${XG_ADSP[$i]}"
    xg_deal_coat $s "$sp"
    XG_ADL+=("${XG[label]}"); XG_ADE+=("${XG[eyes]}"); XG_ADT+=("${XG[tname]}"); XG_ADTM+=("${XG[temper]}")
    XG_ADBR+=("${XG[breed]:-}")
    # WHAT ITS BODY IS.  The cat's build is three words the card spells out;
    # the dog's is its ears and its tail; everything after them was dealt a
    # build that already reads as English ("brush-tailed", "broad-winged"),
    # so the card says the word it was given rather than inventing one.
    case "$sp" in
      dog) XG_ADBD+=("${XG[ears]} ears, a ${XG[tail]} tail"); XG_ADBS+=("${XG[ears]}") ;;
      cat) case "${XG[build]}" in
             neat) XG_ADBD+=('small ears, a short tail'); XG_ADBS+=(neat) ;;
             long) XG_ADBD+=('big ears, a long tail');    XG_ADBS+=(long) ;;
             *)    XG_ADBD+=('ordinary ears and tail');   XG_ADBS+=(classic) ;;
           esac ;;
      *)   XG_ADBD+=("${XG[build]}"); XG_ADBS+=("${XG[build]%% *}") ;;
    esac
    if   (( ${XG[hunger_m]:-1.0} > 1.1 ));  then XG_ADAP+=('eats like the galley is closing'); XG_ADAS+=('always hungry')
    elif (( ${XG[hunger_m]:-1.0} < 0.92 )); then XG_ADAP+=('picks at it, then wants it later'); XG_ADAS+=('picks at it')
    else XG_ADAP+=('eats what it is given'); XG_ADAS+=('no trouble'); fi
    if   (( ${XG[social_m]:-1.0} > 1.15 )); then XG_ADCO+=('wants you in the room'); XG_ADCS+=('wants you close')
    elif (( ${XG[social_m]:-1.0} < 0.95 )); then XG_ADCO+=('takes company or leaves it'); XG_ADCS+=('self-contained')
    else XG_ADCO+=('glad of company, not desperate'); XG_ADCS+=('glad of company'); fi
    pep=$(( int(${XG[hunger_m]:-1.0}*3.4) )); (( pep<1 ))&&pep=1; (( pep>5 ))&&pep=5
    sas=$(( int(${XG[social_m]:-1.0}*3.4) )); (( sas<1 ))&&sas=1; (( sas>5 ))&&sas=5
    XG_ADP+=($pep); XG_ADSS+=($sas)
    # ITS SPAN IS DEALT ONCE, HERE, off the breed the card is about to print,
    # and every line on that card -- the age, the years left, the stage, the
    # portrait -- is measured against that one number.  It goes into the save
    # the moment the certificate is signed.
    xg_lifespan $s "$sp" "${XG[breed]:-}"; spn=$REPLY; XG_ADSPN+=($spn)
    xg_deal_age $s "$sp" $spn; XG_ADAGE+=($REPLY)
    lf=$(( spn-${XG_ADAGE[$i]} )); (( lf < 0.0 )) && lf=0.0
    xg_age_str ${XG_ADAGE[$i]}; XG_ADAG+=("$REPLY"); xg_age_str $lf; XG_ADLF+=("$REPLY")
    xg_stage_of ${XG_ADAGE[$i]} $s "$sp" $spn; XG_ADSI+=($REPLY)
    xg_stage_nm $REPLY "$sp"; XG_ADST+=("$REPLY")
  done
  for k in ${(k)keep[@]}; do XG[$k]="${keep[$k]}"; done
  XG_PAL_KEY=''; XG_CACHE_KEY=''
  XG_ASCAN=${XG_HOUSE[litter]:-1}
  xg_intake_win; XG_AWIN=$REPLY
  return 0
}
xg_bars() {   # xg_bars N ON_COLOUR → REPLY the lit run, REPLY2 the rest (of five)
  local -i n=$1 j; REPLY=''; REPLY2=''
  for (( j=0; j<5; j++ )); do if (( j<n )); then REPLY+='▄'; else REPLY2+='▄'; fi; done
}
typeset -g REPLY2=''
xg_ad_papers() {   # xg_ad_papers IDX — everything this one is, read off the scan
  # NOTHING IS DEALT HERE.  The litter's genetics were run once, on the scan,
  # and every field a card can print was kept then; a page that walks four
  # cards must not re-run the deck four times a frame to do it.
  local -i i=$1
  AD_SEED=${XG_ADS[$i]};     AD_SP="${XG_ADSP[$i]:-cat}"
  AD_LABEL="${XG_ADL[$i]}";  AD_EYES="${XG_ADE[$i]}";   AD_TNAME="${XG_ADT[$i]}"
  AD_BREED="${XG_ADBR[$i]}"
  AD_TEMPER="${XG_ADTM[$i]}"; AD_BUILD="${XG_ADBD[$i]}"; AD_BUILD_S="${XG_ADBS[$i]}"
  AD_APPETITE="${XG_ADAP[$i]}"; AD_APPETITE_S="${XG_ADAS[$i]}"
  AD_COMPANY="${XG_ADCO[$i]}";  AD_COMPANY_S="${XG_ADCS[$i]}"
  AD_AGED=${XG_ADAGE[$i]};   AD_AGE="${XG_ADAG[$i]}";   AD_LEFT="${XG_ADLF[$i]}"
  AD_SPAN=${XG_ADSPN[$i]}
  AD_STAGE="${XG_ADST[$i]}"; AD_STAGE_I=${XG_ADSI[$i]}
  AD_PEP=${XG_ADP[$i]};      AD_SASS=${XG_ADSS[$i]}
  AD_NAME="${(U)XG_ADL[$i]}"
  return 0
}
xg_ad_meter() {   # xg_ad_meter X Y W LABEL N5 COLOUR [BG] — five notches, the suite's own bar
  local -i x=$1 y=$2 w=$3 n=$5 col=$6 bg=${7:--2} i fill
  local lb="$4"; (( XI_LO )) || xg_ink
  v_text $x $y "${(r:5:)lb}" $XI_TX $bg
  fill=$(( n*w/5 ))
  for (( i=0; i<w; i++ )); do
    if (( i < fill )); then v_put $(( x+6+i )) $y '▰' $col $bg
    else v_put $(( x+6+i )) $y '▱' $XI_TRK $bg; fi
  done
  return 0
}
xg_ad_terms() {   # the one line every design carries · X Y W
  local -a tm
  (( XI_LO )) || xg_ink
  tm=('every arrival comes home with ' $XI_LO 'a kibble bag' $XI_TX ' · ' $XI_LO 'a yarn ball' $XI_TX \
      ' · ' $XI_LO '50 starter credits' $AMBER ' · ' $XI_LO 'naming happens at home' $XI_TX)
  xg_seglen "${tm[@]}"
  v_segs $(( $1+($3-REPLY)/2 )) $2 -- "${tm[@]}"
  return 0
}
xg_ad_rivets() {   # xg_ad_rivets X Y W COLOUR [STEP]
  local -i x=$1 y=$2 w=$3 col=$4 step=${5:-6} i
  for (( i=2; i<w-1; i+=step )); do v_put $(( x+i )) $y '·' $col; done
  return 0
}
xg_ad_sunf() {   # xg_ad_sunf I J W H → REPLY 0..1 · how much sun that cell sees
  local -F nx ny
  nx=$(( $3 > 1 ? $1/($3-1.0) : 0.5 )); ny=$(( $4 > 1 ? $2/($4-1.0) : 0.5 ))
  REPLY=$(( 0.5+0.5*(nx-ny)*0.98 ))
}
xg_ad_lit_box() {   # xg_ad_lit_box X Y W H DARK LIT [STYLE] — a drawn frame, lit
  local -i x=$1 y=$2 w=$3 h=$4 cd=$5 cl=$6 i j k base
  local st="${7:-round}"
  v_box $x $y $w $h $cd -2 "$st" 1
  (( w < 3 || h < 3 )) && return 0
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  for (( i=0; i<w; i++ )); do
    xg_ad_sunf $i 0 $w $h; cmix $cd $cl $REPLY
    k=$(( base+y*TCOLS+x+i )); GF[$k]=$CM
    xg_ad_sunf $i $(( h-1 )) $w $h; cmix $cd $cl $REPLY
    k=$(( base+(y+h-1)*TCOLS+x+i )); GF[$k]=$CM
  done
  for (( j=1; j<h-1; j++ )); do
    xg_ad_sunf 0 $j $w $h; cmix $cd $cl $REPLY
    k=$(( base+(y+j)*TCOLS+x )); GF[$k]=$CM
    xg_ad_sunf $(( w-1 )) $j $w $h; cmix $cd $cl $REPLY
    k=$(( base+(y+j)*TCOLS+x+w-1 )); GF[$k]=$CM
  done
  return 0
}
xg_ad_ladder() {   # xg_ad_ladder COLOUR MAX → XG_LAD[0..16] over the glass
  local -i i; local -F mx=$2
  XG_LAD=()
  for (( i=0; i<=16; i++ )); do cmix $GLASS $1 $(( mx*i/16.0 )); XG_LAD+=($CM); done
}
xg_ad_band() {   # xg_ad_band X Y W H COLOUR MAX — a light from above, falling off
  local -i x=$1 y=$2 w=$3 h=$4 col=$5 i j k c base lv
  local -F mx=$6 t u
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  xg_ad_ladder $col $mx
  for (( j=0; j<h; j++ )); do
    (( y+j < 0 || y+j >= SCR_H )) && continue
    t=$(( h > 1 ? 1.0-j/(h-1.0) : 1.0 )); t=$(( t*t ))
    for (( i=0; i<w; i++ )); do
      (( x+i < 0 || x+i >= SCR_W )) && continue
      u=$(( w > 1 ? (i-(w-1)/2.0)/((w-1)/2.0) : 0.0 ))
      u=$(( 1.0-u*u )); (( u < 0.0 )) && u=0.0
      lv=$(( int(t*u*u*16.0+0.5) )); (( lv < 1 )) && continue
      k=$(( base+(y+j)*TCOLS+x+i )); c=${GB[$k]:-$GLASS}
      if (( c == GLASS || c < 0 )); then GB[$k]=${XG_LAD[$lv]}
      else cmix $c $col $(( mx*t*u*u )); GB[$k]=$CM; fi
    done
  done
  return 0
}
xg_ad_wash() {   # xg_ad_wash X Y W H COLOUR MAX — the ground, lifted toward the sun
  # THE WASH IS A DIAGONAL, and a diagonal is ONE RAMP READ AT AN OFFSET.
  # Its strength depends only on (nx - ny), so every row of the card is the
  # same one-dimensional ramp shifted by a constant: build the ramp once and
  # each row becomes a single slice assignment instead of a hundred writes.
  # 2200 cell writes a frame cost 100 ms here; 23 slice assignments cost 2.
  #
  # IT MUST RUN FIRST, before anything else is put on the card: the rows are
  # written whole, so whatever was under them is gone.
  local -i x=$1 y=$2 w=$3 h=$4 col=$5 i j k0 base lv sh off
  local -F mx=$6 f
  local -a ramp
  (( w < 2 || h < 1 )) && return 0
  base=$(( (OY+R_SCR)*TCOLS+OX+C_SCR ))
  xg_ad_ladder $col $mx
  for (( i=0; i<2*w-1; i++ )); do
    f=$(( 0.5+0.49*(i-(w-1.0))/(w-1.0) )); f=$(( f*f ))
    lv=$(( int(f*16.0+0.5) )); (( lv < 0 )) && lv=0; (( lv > 16 )) && lv=16
    ramp+=(${XG_LAD[$lv]})
  done
  for (( j=0; j<h; j++ )); do
    (( y+j < 0 || y+j >= SCR_H )) && continue
    sh=$(( h > 1 ? int(j*(w-1.0)/(h-1.0)+0.5) : (w-1)/2 ))
    off=$(( w-1-sh ))
    k0=$(( base+(y+j)*TCOLS+x ))
    GB[$k0,$(( k0+w-1 ))]=("${(@)ramp[@]:$off:$w}")
  done
  return 0
}
xg_ad_seal() {   # xg_ad_seal CX CY RX RY
  local -i cx=$1 cy=$2 x y boss rim ink bosd bosl rimd riml
  local -F rx=$3 ry=$4 dx dy d f
  cmix $AMBER $RED 0.18; cshade $CM 0.60; boss=$CS        # the wax
  cshade $boss 0.72; bosd=$CS; cshade $boss 1.34; bosl=$CS
  cshade $boss 1.45; rim=$CS                              # the rim it was pressed against
  cshade $rim 0.66; rimd=$CS;  cshade $rim 1.30; riml=$CS
  cmix $GLASS $BLACK 0.35; ink=$CM                        # the die, struck into it
  for (( y=cy-int(ry)-1; y<=cy+int(ry)+1; y++ )); do
    (( y < 1 || y >= SCR_H )) && continue
    for (( x=cx-int(rx)-1; x<=cx+int(rx)+1; x++ )); do
      (( x < 0 || x >= SCR_W )) && continue
      dx=$(( (x-cx)/rx )); dy=$(( (y-cy)/ry )); d=$(( dx*dx+dy*dy ))
      # the same sun as everything else: up and to the right
      f=$(( 0.5+0.34*(dx-dy) )); (( f < 0.0 )) && f=0.0; (( f > 1.0 )) && f=1.0
      if   (( d <= 0.58 )); then cmix $bosd $bosl $f; v_put $x $y ' ' $GREY $CM
      elif (( d <= 1.02 )); then cmix $rimd $riml $f; v_put $x $y ' ' $GREY $CM
      fi
    done
  done
  v_text $(( cx-2 )) $cy 'A·D' $ink $boss
  (( ry >= 3 )) && { v_text $(( cx-2 )) $(( cy-1 )) 'XG·9' $ink $boss
                     v_text $(( cx-2 )) $(( cy+1 )) 'SEAL' $ink $boss }
  return 0
}
xg_ad_leader() {   # xg_ad_leader X Y W LABEL VALUE LCOL VCOL DCOL [BG]
  local -i x=$1 y=$2 w=$3 lc=$6 vc=$7 dc=$8 bg=${9:--2} i vx lw
  local lb="$4" vl
  lw=${#lb}
  xg_ell "$5" $(( w-lw-3 )); vl="$REPLY"
  v_text $x $y "$lb" $lc $bg
  vx=$(( x+w-${#vl} ))
  for (( i=x+lw+1; i<vx-1; i+=2 )); do v_put $i $y '·' $dc $bg; done
  v_text $vx $y "$vl" $vc $bg
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# ADOPT · THE CERTIFICATE · the whole page is one document, and ⏎ signs it
# ══════════════════════════════════════════════════════════════════════════
# Intake night: four arrivals dealt from the genetics deck (base = litter x
# 977, s = base + k x 131 + 7, unique by label -- the original's dealing),
# each at the age it arrives at and on the shipment its own seed puts it on.
# ◂ ▸ turns to the next card; ⏎ signs for whoever is on this one.
#
# THE FRAME IS DRAWN, the ground is LIT, and the animal is LIVE:
#   · the rules are box glyphs, the way a certificate's border reads, and
#     they are re-inked cell by cell along a gradient toward the top right,
#     because the suite has one sun and it is up and to the right.
#   · the card's ground is lifted the same way.  A lift raises the floor
#     under every word on it -- the ink ramp is measured against the GLASS --
#     so NOTHING on this card sits at XI_LO; it all steps up a rung.
#   · everything above is the same between keypresses, so it is painted once
#     into the page cache.  Only the ANIMAL is drawn every frame, so it can
#     blink and breathe in its window without repainting the document.
typeset -g  AD_NAME='' AD_LABEL='' AD_TEMPER='' AD_TNAME='' AD_EYES='' AD_AGE='' AD_LEFT='' AD_BREED=''
typeset -g  AD_STAGE='' AD_BUILD='' AD_PATTERN='' AD_APPETITE='' AD_COMPANY='' AD_SP='cat'
typeset -g  AD_BUILD_S='' AD_APPETITE_S='' AD_COMPANY_S=''
typeset -gi AD_PEP=0 AD_SASS=0 AD_SEED=0 AD_STAGE_I=0
typeset -gF AD_AGED=0.0 AD_LIFE=0.0 AD_LEFTD=0.0 AD_SPAN=0.0
# the card's geometry, measured off the glass once a frame
typeset -gi XA_PX=0 XA_PY=0 XA_PW=0 XA_PH=0 XA_IX=0 XA_IW=0 XA_MX=0 XA_MW=0
typeset -gi XA_SX=0 XA_SW=0 XA_CY=0 XA_CN=0 XA_WX=0 XA_WY=0 XA_WW=0 XA_WH=0 XA_TH=0
typeset -gi XA_SIGNY=0 XA_SIGNW=22
typeset -ga XA_SIGL

xg_adopt_geom() {   # the card, and the window cut in it · both paths need this
  local -i n y1 i
  local -F u
  y1=$(( SCR_H-3 )); XA_TH=$(( y1-1 ))
  XA_PW=$(( SCR_W-10 )); (( XA_PW > 112 )) && XA_PW=112
  XA_PX=$(( (SCR_W-XA_PW)/2 ))
  n=$(( XA_TH-3 )); XA_PH=$n; (( XA_PH > 30 )) && XA_PH=30   # a card is a card · it
  XA_PY=$(( 2+(n-XA_PH)/2 ))                                 # does not fill the glass
  XA_IX=$(( XA_PX+4 )); XA_IW=$(( XA_PW-8 ))
  XA_SW=17; (( XA_IW < 80 )) && XA_SW=0
  XA_WW=$(( XA_IW*26/100 )); (( XA_WW > 26 )) && XA_WW=26; (( XA_WW < 21 )) && XA_WW=21
  XA_MX=$(( XA_IX+XA_WW+3 )); XA_MW=$(( XA_IW-XA_WW-3-(XA_SW ? XA_SW+2 : 0) ))
  XA_SX=$(( XA_IX+XA_IW-XA_SW ))
  XA_CY=$(( XA_PY+7 ))                                       # the tall part of the card
  XA_CN=$(( XA_PY+XA_PH-6-XA_CY )); (( XA_CN < 8 )) && XA_CN=8
  XA_WH=13; (( XA_WH > XA_CN )) && XA_WH=$XA_CN
  XA_WX=$XA_IX; XA_WY=$(( XA_CY+(XA_CN-XA_WH)/2 ))
  XA_TH=$(( XA_PY+XA_PH+1 )); (( XA_TH > SCR_H-4 )) && XA_TH=$(( SCR_H-4 ))
  XA_SIGNY=$(( XA_PY+XA_PH-4 ))
  XA_SIGNW=$(( XA_IW/3 )); (( XA_SIGNW > 24 )) && XA_SIGNW=24; (( XA_SIGNW < 14 )) && XA_SIGNW=14
  # THE SIGNATURE SLIP is paper laid on the card, and it takes the light the
  # rest of the room takes: from up and to the right.  Its ramp is worked out
  # here, once per size, because the live layer repaints it every frame and a
  # cmix per cell per frame is how you lose a page.  The dark end is 7.4:1
  # against the pencil, so the whole strip reads, not just the lit half.
  XA_SIGL=()
  for (( i=0; i<XA_SIGNW; i++ )); do
    u=$(( XA_SIGNW > 1 ? i/(XA_SIGNW-1.0) : 1.0 ))
    cmix $AMBER $WHITE 0.45; cshade $CM $(( 0.74+0.16*u )); XA_SIGL+=($CS)
  done
  return 0
}

xg_adopt_lit() {   # THE LIT STOCK · frame, wash, window · the same for every
  # card in the litter, so it is painted once per glass size and kept.  The
  # light is the expensive part of this page and none of it changes when you
  # turn to the next card.
  local -i i c1 c2 gold
  (( XI_LO )) || xg_ink
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  cmix $AMBER $WHITE 0.25; gold=$CM
  cmix $AMBER $PURPLE 0.35; c1=$CM
  xg_ad_wash $XA_PX $XA_PY $XA_PW $XA_PH $c1 0.26
  # ── the frame · the double rule, drawn, and lit from the top right ──
  cshade $gold 0.55; c1=$CS; cshade $gold 1.20; c2=$CS
  xg_ad_lit_box $XA_PX $XA_PY $XA_PW $XA_PH $c1 $c2 round
  cshade $AMBER 0.32; c1=$CS; cshade $AMBER 0.78; c2=$CS
  xg_ad_lit_box $(( XA_PX+2 )) $(( XA_PY+1 )) $(( XA_PW-4 )) $(( XA_PH-2 )) $c1 $c2 thin
  cmix $AMBER $WHITE 0.75; c1=$CM
  for (( i=0; i<5; i++ )); do
    cmix $gold $c1 $(( 0.85-0.17*i ))
    GF[$(( (OY+R_SCR+XA_PY)*TCOLS+OX+C_SCR+XA_PX+XA_PW-3-i ))]=$CM   # the glint, top right
  done
  # ── the window the animal stands in · a recess, left at the bare glass
  #    while the card around it is lit, with the pool up and right of centre
  #    so the animal is modelled rather than evenly floodlit.  NO BARS down
  #    its sides: a mount does not need edges when the light gives it depth.
  v_fill $XA_WX $XA_WY $XA_WW $XA_WH ' ' $GREY $GLASS
  cmix $AMBER $RED 0.12; c1=$CM
  xg_cglow $(( XA_WX+XA_WW*3/5 )) $(( XA_WY+XA_WH/3 )) $(( XA_WW*3/4 )) $(( XA_WH/2+2 )) $c1 0.55
  cshade $AMBER 0.52; c1=$CS; cshade $AMBER 0.22; c2=$CS
  xg_ad_rivets $XA_WX $XA_WY $XA_WW $c1 5                    # the lit lip
  xg_ad_rivets $XA_WX $(( XA_WY+XA_WH-1 )) $XA_WW $c2 5      # and the one in shadow
  cmix $AMBER $WHITE 0.20; c1=$CM                            # the light over the plate
  xg_ad_band $(( XA_PX+1 )) $(( XA_PY+2 )) $(( XA_PW-2 )) 5 $c1 0.16
  (( XA_SW )) && xg_ad_seal $(( XA_SX+XA_SW/2 )) $(( XA_CY+XA_CN-4 )) 6 3.2
  return 0
}

xg_adopt_card() {   # THE WORDS · whoever is under the cursor, over the lit stock
  local -i i x y col c1 gold dim rows n bw
  local s br
  cmix $AMBER $WHITE 0.25; gold=$CM
  cshade $gold 0.34; dim=$CS
  xg_ad_papers $XG_ASEL
  # ── what this is, one line above what it is for ──
  #    A heading, not an aside: it crosses the card's lit ground, where the
  #    ramp is measured a rung up, so 0.62 sank to 2.8:1 and had to come up.
  #    At 0.86 it holds 5.1:1 at the brightest cell it crosses, and still
  #    sits well under the nameplate's gold, which is the loud line here.
  s='CERTIFICATE OF ADOPTION'
  cshade $AMBER 0.86; v_text $(( XA_IX+(XA_IW-${#s})/2 )) $(( XA_PY+2 )) "$s" $CS
  # ── the nameplate, under a light from above ──
  y=$(( XA_PY+3 ))
  xg_spaced "$AD_NAME"
  if (( ${#REPLY} > XA_IW )); then s="$AD_NAME"; else s="$REPLY"; fi
  xg_gtext $(( XA_IX+(XA_IW-${#s})/2 )) $y "$s" $AMBER $XG_WHITE
  # ── WHAT IT IS, under what it is called ──
  #    THE BREED RIDES WITH THE NAME, not down among the papers.  It is not
  #    one property of seven: it is the line that decides what the other six
  #    may say, and on a pedigree it is read in the same breath as the name.
  #    The tail drops off a piece at a time rather than ellipsising, so a
  #    narrow card loses the model number before it loses what the animal is.
  xg_sp_i "$AD_SP"; i=$REPLY
  br=''; [[ -n "$AD_BREED" ]] && br=" · ${(U)AD_BREED}"
  s="${XG_SP_DISP[$i]}$br · ${XG_SP_LATIN[$i]} · MODEL XG-9"
  (( ${#s} > XA_IW )) && s="${XG_SP_DISP[$i]}$br · ${XG_SP_LATIN[$i]}"
  (( ${#s} > XA_IW )) && s="${XG_SP_DISP[$i]}$br"
  xg_ell "$s" $XA_IW; s="$REPLY"
  v_text $(( XA_IX+(XA_IW-${#s})/2 )) $(( y+1 )) "$s" $XI_TX
  xg_rule_at $XA_IX $(( y+2 )) $XA_IW $dim '┄'
  # ── the clause · it must not be cut mid-sentence, and its length moves
  #    with the animal's own stage, age and span, so a long one gives way
  #    to a short one rather than trailing off.
  y=$XA_CY
  xg_litter_code; local lc="$REPLY"
  xg_wrap "This is to certify that the animal shown here was dealt from litter $lc, is a ${(L)AD_STAGE} of $AD_AGE with some $AD_LEFT ahead of it, and passes entire into your keeping." $XA_MW
  (( ${#XG_WR[@]} > 4 )) && xg_wrap "This is to certify that the animal shown, of litter $lc, passes entire into your keeping." $XA_MW
  rows=${#XG_WR[@]}; (( rows > 4 )) && rows=4
  for (( i=0; i<rows; i++ )); do v_text $XA_MX $(( y+i )) "${XG_WR[$i]}" $XI_TX; done
  # ── the papers, on printed leaders ──
  local -a fl fv
  # SIX, AND THE CARD HOLDS SIX · the breed is on the line under the name
  fl=(COLOURWAY EYES BUILD TEMPER APPETITE COMPANY)
  fv=("$AD_LABEL" "$AD_EYES" "$AD_BUILD" "$AD_TEMPER" "$AD_APPETITE" "$AD_COMPANY")
  cshade $AMBER 0.75; c1=$CS
  for (( i=0; i<6 && y+rows+1+i <= XA_PY+XA_PH-6; i++ )); do
    xg_ad_leader $XA_MX $(( y+rows+1+i )) $XA_MW "${fl[$i]}" "${fv[$i]}" $c1 $XI_HI $XI_TRK
  done
  # ── the register, and the seal struck under it ──
  if (( XA_SW )); then
    s="No. $(printf '%05d' $(( AD_SEED % 100000 )))"
    cmix $WHITE $AMBER 0.35; v_text $(( XA_SX+XA_SW-${#s} )) $y "$s" $CM
    s="DAY ${XG[day]:-1} · LITTER $lc"
    # THE DAY AND THE NIGHT'S MANIFEST are two facts, not one line: a
    # manifest code is six characters and "DAY 6 · LITTER JXK2QP" does not
    # fit a seventeen-column register, so each gets a line of its own.
    xg_ell "DAY ${XG[day]:-1}" $XA_SW; s="$REPLY"
    v_text $(( XA_SX+XA_SW-${#s} )) $(( y+1 )) "$s" $XI_TX
    xg_ell "LITTER $lc" $XA_SW; s="$REPLY"
    v_text $(( XA_SX+XA_SW-${#s} )) $(( y+2 )) "$s" $XI_TX
  fi
  # ── the foot · what you sign, and what you are signing for ──
  y=$(( XA_PY+XA_PH-4 ))
  xg_rule_at $XA_IX $(( y-1 )) $XA_IW $dim '┄'
  cshade $AMBER 0.95; v_text $XA_IX $y 'SIGN' $CS
  v_text $(( XA_IX+8+XA_SIGNW )) $y 'write it a name, then sign' $XI_TX
  cshade $AMBER 0.75; v_text $XA_IX $(( y+1 )) 'DISPOSITION' $CS
  xg_ad_meter $(( XA_IX+13 )) $(( y+1 )) 10 PEP  $AD_PEP  $CYAN
  xg_ad_meter $(( XA_IX+33 )) $(( y+1 )) 10 SASS $AD_SASS $MAGENTA
  s="countersigned · ${(U)AD_TNAME}"
  xg_ell "$s" $(( XA_IW-56 ))
  v_text $(( XA_IX+XA_IW-${#REPLY} )) $(( y+1 )) "$REPLY" $XI_TX
  # ── the rest of the litter · three card backs, gold-edged, waiting ──
  bw=$(( (SCR_W-4)/3 )); n=0
  for (( i=0; i<4; i++ )); do
    (( i == XG_ASEL )) && continue
    x=$(( 2+n*bw )); n=$(( n+1 ))
    xg_ad_papers $i
    cmix $GLASS $AMBER 0.055; col=$CM
    v_fill $x $XA_TH $(( bw-3 )) 1 ' ' $GREY $col
    cshade $gold 0.5; v_fill $x $XA_TH 1 1 ' ' $GREY $CS
    xg_ell "${(L)AD_NAME} · ${(L)AD_STAGE} · $AD_AGE" $(( bw-7 ))
    v_text $(( x+2 )) $XA_TH "$REPLY" $XI_TX $col
  done
  xg_ad_papers $XG_ASEL
  return 0
}

xg_adopt_live() {   # the animal and the signature · drawn every frame
  local -i kx ky c1
  local -F ph br
  local eyes=open
  # IT IS ALIVE WHILE IT SITS THERE.  The blink runs off the wall clock and
  # the animal's own seed, the same rule the room uses, so no two arrivals
  # blink together; and the light in the alcove breathes under it.  Neither
  # touches the document, so neither costs a repaint.
  ph=$(( XG_NOW*0.25+(AD_SEED%997)*0.013 )); ph=$(( ph-floor(ph) ))
  (( ph < 0.048 )) && eyes=closed
  br=$(( 0.5+0.5*sin(XG_NOW*0.7+(AD_SEED%613)*0.011) ))
  cmix $AMBER $WHITE 0.45; c1=$CM
  xg_cglow $(( XA_WX+XA_WW*3/5 )) $(( XA_WY+XA_WH/3 )) $(( XA_WW/3 )) $(( XA_WH/4+1 )) $c1 $(( 0.18+0.12*br ))
  xg_stall_sprite $AD_SEED $AD_AGED "$AD_SP" "$eyes" "" $AD_SPAN "$AD_BREED"
  kx=$(( XA_WX+(XA_WW-XG_CCW)/2 )); (( kx < XA_WX )) && kx=$XA_WX
  if (( XG_CCH <= XA_WH-2 )); then
    ky=$(( XA_WY+1+(XA_WH-2-XG_CCH)/2 ))
    xg_cell_shadow $kx $ky 0.35
  else
    ky=$(( XA_WY+(XA_WH-XG_CCH)/2 ))
  fi
  xg_blit_cells $kx $ky
  # ── the signature · the slip, and what you have written on it ──
  #    Pencil on paper: the ink is one colour and the paper carries the
  #    light, so the name reads the same at both ends of the strip.
  local nm="$XG_WBUF" s
  local -i sx=$(( XA_IX+6 )) i n ink car
  cmix $GLASS $BLACK 0.35; ink=$CM
  n=${#nm}; car=$(( (int(XG_NOW*2))%2 ? n+1 : -1 ))
  for (( i=0; i<XA_SIGNW; i++ )); do
    if (( i >= 1 && i-1 < n )); then v_put $(( sx+i )) $XA_SIGNY "${nm[$(( i-1 ))]}" $ink ${XA_SIGL[$i]}
    elif (( i == car ));         then v_put $(( sx+i )) $XA_SIGNY '_' $ink ${XA_SIGL[$i]}
    else                              v_put $(( sx+i )) $XA_SIGNY ' ' $GREY ${XA_SIGL[$i]}; fi
  done
  # ── and what the foot of the card says about it ──
  if (( ${#nm} )); then s=" ⏎  SIGNS FOR ${nm} "; cshade $LIME 0.85; c1=$CS
  else s=" IT IS NOT SIGNED FOR UNTIL IT HAS A NAME "; cshade $AMBER 0.62; c1=$CS; fi
  (( ${#s} < XA_PW-6 )) && v_text $(( XA_PX+(XA_PW-${#s})/2 )) $(( XA_PY+XA_PH-1 )) "$s" $c1 $GLASS
  # ── WHEN THE DOORS CHANGE · under the rest of the litter, the four species
  #    on offer and what is left of their window.  It is built by hand rather
  #    than by printf because this runs every frame and a fork a frame is how
  #    you lose a page; it is also why there is no locale in it to get wrong.
  local -i lft hh mm ss cy
  xg_intake_left; lft=$REPLY
  hh=$(( lft/3600 )); mm=$(( (lft%3600)/60 )); ss=$(( lft%60 ))
  cy=$(( XA_TH+1 ))
  if (( cy <= SCR_H-3 && ${#XG_WIN_SP[@]} )); then
    (( XI_LO )) || xg_ink
    local clk sp1 names='' line
    clk="$hh:"; (( mm < 10 )) && clk+=0; clk+="$mm:"; (( ss < 10 )) && clk+=0; clk+="$ss"
    for sp1 in "${XG_WIN_SP[@]}"; do names+="${(U)sp1} · "; done
    line="ON OFFER · ${names}THE DOORS CHANGE IN $clk"
    (( ${#line} > SCR_W-4 )) && line="THE DOORS CHANGE IN $clk"
    (( ${#line} <= SCR_W-2 )) && v_text $(( (SCR_W-${#line})/2 )) $cy "$line" $XI_TX $GLASS
  fi
  return 0
}

xg_draw_adopt() {
  local -i awin; xg_intake_win; awin=$REPLY
  (( XG_ASCAN != ${XG_HOUSE[litter]:-1} || XG_AWIN != awin )) && xg_adopt_scan
  xg_adopt_geom
  local bgk="adopt.${SCR_W}x${SCR_H}"
  local key="$bgk.${XG_HOUSE[litter]:-1}.$XG_ASEL.${XG[day]:-1}.$awin"
  if (( XG_PG_USE )) && [[ "$key" == "$XG_PGK" ]]; then
    xg_pg_load
  else
    if (( XG_PG_USE )) && [[ "$bgk" == "$XG_BGK" ]]; then xg_bg_load
    else xg_adopt_lit; (( XG_PG_USE )) && { xg_bg_save; XG_BGK="$bgk"; }
    fi
    xg_adopt_card
    (( XG_PG_USE )) && { xg_pg_save; XG_PGK="$key"; }
  fi
  xg_adopt_live
  xg_head 'ADOPTION CENTER' 1 - 'INTAKE NIGHT · NO PAPERWORK' $XG_LBL
  app_nav 'type' 'a name' '⏎' sign '◂ ▸' 'the next card' '▴ ▾' 'new litter' '[⎋]' menu
  return 0
}

xg_adopt_take() {   # ⏎ on the certificate — the animal you signed for comes home and takes the room
  local -i s=$XG_WSEED slot first=$XG_FRESH i
  local nm="$XG_WBUF"
  local -F now=${EPOCHSECONDS:-0} age
  xg_save_write                          # the resident is put away first, whole
  if (( XG_FRESH )); then slot=$XG_ACTIVE; XG_FRESH=0
  else
    # THE COUNTER IS A HINT, NOT AN ADDRESS.  Taking the slot npets names
    # overwrote a living pet whenever the count had drifted low -- and a
    # released slot, a stale second cabinet or one hand-edit is enough to
    # drift it.  Take the first slot that genuinely has nobody in it.
    slot=-1
    for (( i=0; i<256; i++ )); do
      [[ -n "${SAVE[xenogotchi.pets.$i.name]:-}" ]] || { slot=$i; break }
    done
    (( slot < 0 )) && slot=$XG_NPETS
    (( slot >= XG_NPETS )) && XG_NPETS=$(( slot+1 ))
  fi
  XG_ACTIVE=$slot
  local sp="${XG_WSP:-cat}"
  local -F span; xg_lifespan $s "$sp"; span=$REPLY      # dealt once, kept forever
  xg_deal_age $s "$sp" $span; age=$REPLY
  XG=()
  XG[species]="$sp"; XG[seed]=$s; XG[name]="$nm"
  XG[health]=100; XG[food]=80; XG[water]=85; XG[pep]=75; XG[mood]=70; XG[coat]=92; XG[bond]=12   # the original's
  XG[box]=10; XG[credits]=50; XG[day]=1; XG[streak]=0
  XG[treats_today]=0; XG[catches_today]=0; XG[c_pets]=0; XG[c_naps]=0; XG[c_treats]=0; XG[c_catches]=0; XG[c_gifts]=0
  XG[last_groom]=0; XG[last_pet]=0; XG[overstim]=0; XG[overstim_at]=0
  XG[born]=$(( now-age*86400.0 )); XG[span]=$span
  xg_day_key; XG[last_day]="$REPLY"
  xg_deal_coat $s "$sp"                  # the paperwork · label, temper, eyes
  xg_age_sync                            # its stage and the years ahead of it
  # the house · a kibble bag and a yarn ball come along (a second arrival brings two more meals)
  if (( first )); then (( ${XG_HOUSE[pantry]:-0} < 6 )) && XG_HOUSE[pantry]=6
  else XG_HOUSE[pantry]=$(( ${XG_HOUSE[pantry]:-0}+2 )); fi
  xg_own yarn; [[ -n "${XG_HOUSE[toy]:-}" ]] || XG_HOUSE[toy]=yarn
  XG_HOUSE[litter]=$(( (RANDOM*32768+RANDOM) + 1 ))   # the next intake night is someone else's
  XG_ASEL=0; XG_WBUF=''; XG_RCK=''; XG_PAL_KEY=''; XG_CACHE_KEY=''; XG_CAMF=-1.0
  xg_actor_init
  xg_pick "adopted $nm · ${XG[label]}" "$nm came home · ${XG[label]}" "one ${XG[label]}, answering to $nm" "$nm, signed for · a ${XG[label]}"
  xg_log "$REPLY" '' $GREY
  xg_log 'a kibble bag, a yarn ball and 50 credits came along' '+50 c' $LIME
  xg_save_write
  xg_go_view home; snd mew
  return 0
}

xg_meter_on() {   # xg_meter_on X Y W LABEL VAL COL BG — a meter on a given ground
  local -i x=$1 y=$2 w=$3 val=$5 col=$6 bg=$7 i fill bx; local lbl="$4"
  (( val<0 ))&&val=0; (( val>100 ))&&val=100; fill=$(( val*w/100 ))
  v_text $x $y "${(r:6:)lbl}" $XG_LBL $bg
  bx=$(( x+7 ))
  for (( i=0;i<w;i++ )); do
    if (( i<fill )); then v_put $(( bx+i )) $y '▰' $col $bg
    else cshade $GREY 0.4; v_put $(( bx+i )) $y '▱' $CS $bg; fi
  done
  v_text $(( bx+w+1 )) $y "$val" $col $bg
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE STANDING PAGE · the cabinet runs the channel change around it
# ══════════════════════════════════════════════════════════════════════════
# ══════════════════════════════════════════════════════════════════════════
# THE EMOTION ENGINE · nothing is scripted · needs, temperament and the hour
# feed a running emotional state; the winning emotion picks the behaviour;
# the animation is that emotion made visible.
# ══════════════════════════════════════════════════════════════════════════
typeset -gA XG_A XG_E; typeset -gF XG_A_LAST=0.0 XG_SPAN_W=92.0
xg_actor_init() {
  XG_A=(); XG_A[fx]=0.5; XG_A[target]=0.5; XG_A[facing]=1
  XG_A[pose]=sit; XG_A[eyes]=open; XG_A[behavior]=idle; XG_A[b_until]=0.0; XG_A[dominant]=content
  XG_A[speed]=6.0; XG_A[moving]=0; XG_A[pause_until]=0.0; XG_A[turn_at]=-1.0
  XG_A[last]=''; XG_A[woke_at]=-999.0; XG_A[crouch]=0
  XG_A_LAST=$XG_NOW
}
xg_night() { local h; strftime -s h '%H' ${EPOCHSECONDS:-0} 2>/dev/null || h=12; (( h>=23 || h<7 )) && REPLY=1 || REPLY=0 }
xg_emotions() {   # xg_emotions NIGHT — fill XG_E from vitals, temperament, the hour
  local -F fed=${XG[food]:-70} water=${XG[water]:-70} pep=${XG[pep]:-70} mood=${XG[mood]:-70} bond=${XG[bond]:-70} box=${XG[box]:-0}
  local -F hm=${XG[hunger_m]:-1.0} sm=${XG[social_m]:-1.0} night=$1 b
  b=$(( (62.0-fed)/62.0 ));   b=$(( b<0?0:(b>1?1:b) )); XG_E[hungry]=$(( (b**1.4)*hm ))
  b=$(( (66.0-water)/66.0 )); b=$(( b<0?0:(b>1?1:b) )); XG_E[thirsty]=$(( b**1.3 ))
  b=$(( (55.0-pep)/55.0 ));   b=$(( b<0?0:(b>1?1:b) )); XG_E[sleepy]=$(( b*0.8+(night>0.5?0.55:0.0) ))
  b=$(( (pep/100.0)*(mood/100.0) )); b=$(( b<0?0:(b>1?1:b) )); XG_E[playful]=$(( b*0.7 ))
  b=$(( bond/100.0 ));        b=$(( b<0?0:(b>1?1:b) )); XG_E[social]=$(( b*0.5*sm ))
  local -F g1=$(( (box-60.0)/40.0 )); g1=$(( g1<0?0:(g1>1?1:g1) )); local -F g2=$(( (25.0-mood)/25.0 )); g2=$(( g2<0?0:g2 ))
  XG_E[grumpy]=$(( g1*1.6+g2*0.5 ))
  local -F worst=${XG_E[hungry]}
  (( XG_E[thirsty]>worst ))&&worst=${XG_E[thirsty]}; (( XG_E[sleepy]>worst ))&&worst=${XG_E[sleepy]}; (( XG_E[grumpy]>worst ))&&worst=${XG_E[grumpy]}
  b=$(( 1.0-worst )); b=$(( b<0?0:(b>1?1:b) )); XG_E[content]=$(( b*0.62 ))
}
# ── WHAT IT DOES NEXT · every pastime bids, and a content animal is mostly on
# its FEET: it roams the room in legs, potters, chases, and only sometimes
# settles.  The same pastime twice running is marked down (boredom), and a
# nap that has just ended keeps it up a while before it will sleep again —
# so even the night is sleep in bouts, with rounds of the room between.
# Roaming pastimes are a string of legs: walk, stop a moment, look round,
# walk on.  Needs (the dishes, the bed) go straight there and stay.
xg_think() {   # xg_think NIGHT — the winning pastime, where it heads, its gait, how long
  local -F night=${1:-0} r1=$(( RANDOM/32768.0 )) r2=$(( RANDOM/32768.0 )) r3=$(( RANDOM/32768.0 )) r4=$(( RANDOM/32768.0 ))
  local -F r5=$(( RANDOM/32768.0 ))            # the flop's own die · see below
  local -F cur=${XG_A[fx]:-0.5} lazy=1.0 coat=${XG[coat]:-80} pep=${XG[pep]:-70} best=-1.0 ct=0.5 cd=10.0 spd=6.0 spw=$XG_SPAN_W trav
  local -F bond=${XG[bond]:-70} trust
  local k choice=idle last="${XG_A[last]:-}"
  local -A U
  (( night > 0.5 )) && lazy=0.5
  U[eat]=$(( XG_E[hungry]*1.3 ))
  U[drink]=$(( XG_E[thirsty]*1.35 ))
  U[sleep]=$(( XG_E[sleepy]*1.2 ))
  U[groom]=$(( coat<80.0 ? (80.0-coat)/80.0 : 0.0 ))
  U[play]=$(( XG_E[playful]*1.0*lazy+r1*0.06 ))
  U[wander]=$(( (0.10+XG_E[social]*0.45+XG_E[playful]*0.25+r2*0.16)*lazy ))
  U[loaf]=$(( XG_E[content]*0.44+r3*0.20 ))
  U[idle]=$(( (0.26+r4*0.14)*(night>0.5?0.7:1.0) ))
  # THE FLOP · on its back, paws in the air.  This is not a rival to playing
  # or to a round of the room -- an animal with that much pep is on its feet.
  # It is a rival to the LOAF: when a settled animal settles, a well-bonded
  # one sometimes goes all the way over.  Under 55 bond it never occurs to it
  # at all, and because it is priced off the loaf it never outbids a need.
  # It needs a die of its OWN: sharing idle's would tie the two together, and
  # a flop that only happens when idling is a flop that never happens.
  trust=$(( bond<55.0 ? 0.0 : (bond-55.0)/45.0 ))
  U[flop]=$(( (XG_E[content]*0.44+r5*0.20)*trust ))
  # just woken · it stays up a while, unless it is truly spent
  (( XG_NOW-(${XG_A[woke_at]:--999}) < 40.0 && pep > 30.0 )) && U[sleep]=$(( U[sleep]*0.4 ))
  # boredom · the same pastime twice running is marked down · needs never are
  case "$last" in loaf|idle|wander|play|groom|flop) U[$last]=$(( U[$last]*0.6 )) ;; esac
  for k in eat drink sleep groom play wander loaf flop idle; do
    (( U[$k] > best )) && { best=${U[$k]}; choice=$k; }
  done
  case $choice in
    eat)    ct=0.22; cd=$(( 9.0+r1*4.0 )); spd=$(( XG_E[hungry]>0.6 ? 9.0 : 7.5 )) ;;
    drink)  ct=0.30; cd=$(( 7.0+r1*3.0 )); spd=$(( XG_E[thirsty]>0.6 ? 9.0 : 7.5 )) ;;
    sleep)  ct=0.84; spd=5.0                                    # the bed, under the lamp
            if (( night > 0.5 )); then cd=$(( 60.0+r1*90.0 )); else cd=$(( 90.0+r1*120.0 )); fi ;;
    groom)  ct=$cur; cd=$(( 12.0+r1*12.0 )); spd=5.0 ;;
    play)   ct=0.64; cd=$(( 12.0+r1*14.0 )); spd=11.0            # the toy · or the red dot, anywhere
            [[ -z "${XG_HOUSE[toy]:-}" ]] && ct=$(( 0.1+r2*0.8 )) ;;
    wander) ct=$(( 0.08+0.24*r2 )); (( r3 < 0.5 )) && ct=$(( -ct ))   # a stretch, either way
            ct=$(( cur+ct )); (( ct < 0.06 || ct > 0.94 )) && ct=$(( 2.0*cur-ct ))
            cd=$(( 18.0+r1*18.0 )); spd=6.0 ;;
    loaf)   ct=$(( cur+(r2-0.5)*0.24 )); cd=$(( 14.0+r1*16.0 )); spd=5.0 ;;
    flop)   ct=$(( cur+(r2-0.5)*0.20 )); cd=$(( 16.0+r1*18.0 )); spd=5.0 ;;   # it stays down a while
    *)      ct=$(( cur+(r2-0.5)*0.5 )); cd=$(( 8.0+r1*10.0 )); spd=4.5 ;;
  esac
  (( ct<0.05 )) && ct=0.05; (( ct>0.95 )) && ct=0.95
  (( spw < 20.0 )) && spw=92.0
  trav=$(( abs(ct-cur)*spw/spd ))                  # the clock starts once it gets there
  XG_A[behavior]="$choice"; XG_A[target]=$ct; XG_A[speed]=$spd; XG_A[moving]=1
  XG_A[b_until]=$(( XG_NOW+cd+trav )); XG_A[pause_until]=0.0; XG_A[turn_at]=-1.0; XG_A[crouch]=0
}
xg_next_leg() {   # a fresh waypoint for the roaming pastimes
  local -F r=$(( RANDOM/32768.0 )) r2=$(( RANDOM/32768.0 )) cur=${XG_A[fx]:-0.5} t
  case "${XG_A[behavior]}" in
    wander) t=$(( 0.08+0.24*r2 ))                                  # a stretch of room, either way
            (( r < 0.5 )) && t=$(( -t ))
            t=$(( cur+t ))
            (( t < 0.06 )) && t=$(( cur+abs(t-cur) ))               # a wall ahead · the other way
            (( t > 0.94 )) && t=$(( cur-abs(t-cur) )) ;;
    play)   if [[ -n "${XG_HOUSE[toy]:-}" ]]; then t=$(( 0.64+(r-0.5)*0.18 ))   # batting the toy about
            else t=$(( 0.15+0.30*r2 )); (( r < 0.5 )) && t=$(( -t )); t=$(( cur+t ))   # the dot
                 (( t < 0.06 || t > 0.94 )) && t=$(( 2.0*cur-t )); fi ;;
    *)      t=$(( cur+(r-0.5)*0.36 )) ;;                           # a potter
  esac
  (( t<0.05 )) && t=0.05; (( t>0.95 )) && t=0.95
  XG_A[target]=$t; XG_A[moving]=1
}
xg_arrive() {   # a leg is done · how long it stops, and whether it looks round
  local -F r=$(( RANDOM/32768.0 )) r2=$(( RANDOM/32768.0 )) p=0.0
  XG_A[crouch]=0
  case "${XG_A[behavior]}" in
    wander) p=$(( 3.0+r*5.0 )) ;;                                  # a sniff about, a look round
    play)   p=$(( 0.6+r*1.0 )); XG_A[crouch]=1 ;;                  # low, then the pounce
    idle)   p=$(( 3.0+r*5.0 )); (( r2 > 0.7 )) && XG_A[crouch]=1 ;;
    eat)    XG_A[facing]=1 ;;                                      # the tail kept out of the bowl
    drink)  XG_A[facing]=-1 ;;                                     # …and out of the water
  esac
  XG_A[pause_until]=$(( XG_NOW+p ))
  if (( p > 1.8 && r2 < 0.45 )); then XG_A[turn_at]=$(( XG_NOW+p*(0.35+0.3*r) ))
  else XG_A[turn_at]=-1.0; fi
}
xg_actor_update() {   # xg_actor_update — one beat of the sim
  local -F dt=$(( XG_NOW-XG_A_LAST )); (( dt<0.0 ))&&dt=0.0; (( dt>2.0 ))&&dt=2.0; XG_A_LAST=$XG_NOW
  xg_night; local -F night=$REPLY; xg_emotions $night
  local k dom=content; local -F dv=-1.0
  for k in hungry thirsty sleepy playful social grumpy content; do (( XG_E[$k]>dv )) && { dv=${XG_E[$k]}; dom=$k; }; done
  XG_A[dominant]="$dom"
  [[ "$dom" == grumpy ]] && XG_A[eyes]=narrow || XG_A[eyes]=open
  if (( XG_NOW >= ${XG_A[b_until]:-0} )); then
    [[ "${XG_A[behavior]:-}" == sleep && "${XG_A[pose]:-}" == sleep ]] && XG_A[woke_at]=$XG_NOW
    XG_A[last]="${XG_A[behavior]:-}"
    xg_think $night
  fi
  local -F fx=${XG_A[fx]:-0.5} tgt=${XG_A[target]:-0.5} spd=${XG_A[speed]:-6.0} spw=$XG_SPAN_W d ad step
  (( spw < 20.0 )) && spw=92.0
  d=$(( tgt-fx )); ad=$(( d<0?-d:d ))
  if (( ad*spw > 0.3 )); then                      # on its way · in cells a second, any glass
    step=$(( spd/spw*dt )); (( step>ad )) && step=$ad
    XG_A[fx]=$(( fx+(d>0?step:-step) )); XG_A[facing]=$(( d>0?1:-1 )); XG_A[pose]=walk
    xg_vaddf pep $(( -0.0067*spd*dt ))             # the rounds tire it, a little · naps follow
    return 0
  fi
  (( ${XG_A[moving]:-0} )) && { XG_A[moving]=0; xg_arrive; }
  case "${XG_A[behavior]}" in
    sleep) XG_A[pose]=sleep; xg_vaddf pep $(( 5.0*dt*(${XG_HOUSE[nbed]:-1} >= 2 ? 1.25 : 1.0) )) ;;
    chase) XG_A[pose]=play ;;                     # the bow · low, eyes on the dot
    groom) XG_A[pose]=loaf;  xg_vaddf coat $(( 3.0*dt )) ;;
    loaf)  XG_A[pose]=loaf; xg_vaddf pep $(( 0.02*dt )) ;;
    flop)  XG_A[pose]=flop; xg_vaddf pep $(( 0.03*dt )) ;;   # on its back, recovering
    idle|wander|play)
      # THE POUNCE · xg_arrive crouches it at the end of a play leg.  A crouch
      # at the toy is the play body; a crouch while pottering is still a loaf.
      if (( ${XG_A[crouch]:-0} )); then
        [[ "${XG_A[behavior]}" == play ]] && XG_A[pose]=play || XG_A[pose]=loaf
      else XG_A[pose]=sit; fi
      if (( XG_A[turn_at] > 0.0 && XG_NOW >= XG_A[turn_at] )); then   # a look the other way
        XG_A[facing]=$(( -(${XG_A[facing]:-1}) )); XG_A[turn_at]=-1.0
      fi
      (( XG_NOW >= XG_A[pause_until] )) && xg_next_leg ;;
    *)     XG_A[pose]=sit ;;
  esac
  return 0
}
xg_anim() {   # xg_anim — per-frame: the blink, the facing, the walk cycle at the gait's pace
  XG_POSE="${XG_A[pose]:-sit}"
  if [[ "$XG_POSE" == sleep ]]; then XG_POSE_EYES=closed; XG_POSE_FACE=1   # the head on the pillow, always
  elif [[ "$XG_POSE" == walk ]]; then XG_POSE_EYES=open; XG_POSE_FACE=${XG_A[facing]:-1}
  else
    local -F ph=$(( XG_NOW*0.25+(${XG[seed]:-0}%997)*0.013 )); ph=$(( ph-floor(ph) ))
    (( ph<0.045 )) && XG_POSE_EYES=closed || XG_POSE_EYES="${XG_A[eyes]:-open}"
    XG_POSE_FACE=${XG_A[facing]:-1}
  fi
  (( XG_POSE_FACE != -1 )) && XG_POSE_FACE=1
  [[ "$XG_POSE" == walk ]] && XG_POSE_FRAME=$(( int(XG_NOW*${XG_A[speed]:-6.0})%2 )) || XG_POSE_FRAME=0
}

xg_draw_toosmall() {   # the glass does not fit the window · say so, plainly
  # THE CABINET HAS A SIZE.  Below it the driver's geom_fill clamps the glass
  # UP to the cabinet's minimum and leaves the terminal where it is, so every
  # page is drawing at coordinates the window has not got.  Nothing dies any
  # more -- every grid read carries a default now -- but half a room drawn off
  # the edge is not a room, and a person who cannot see why deserves telling.
  local -i cw ch y
  local s
  (( XI_LO )) || xg_ink
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  cw=$(( SCR_W < TCOLS ? SCR_W : TCOLS )); ch=$(( SCR_H < TROWS ? SCR_H : TROWS ))
  y=$(( ch/2-3 )); (( y < 1 )) && y=1
  s='THE WINDOW IS TOO SMALL'
  (( ${#s} <= cw-2 )) && { cshade $AMBER 0.95; v_text $(( (cw-${#s})/2 )) $y "$s" $CS }
  s="this one is ${TCOLS}x${TROWS}"
  (( ${#s} <= cw-2 )) && v_text $(( (cw-${#s})/2 )) $(( y+2 )) "$s" $XI_HI
  s="the cabinet needs ${XG_MIN_W}x${XG_MIN_H}"
  (( ${#s} <= cw-2 )) && v_text $(( (cw-${#s})/2 )) $(( y+3 )) "$s" $XI_TX
  s='drag it wider, or use a smaller font'
  (( ${#s} <= cw-2 )) && v_text $(( (cw-${#s})/2 )) $(( y+5 )) "$s" $XI_LO
  return 0
}
typeset -gi XG_MIN_W=106 XG_MIN_H=30

xg_draw() {   # xg_draw T
  XG_NOW=$1
  PACK_FILL=1                        # the room fills the glass · the sprite stays fixed
  # A GLASS BIGGER THAN THE WINDOW IS NOT A GLASS · see xg_draw_toosmall
  XG_MIN_W=$SCR_W; XG_MIN_H=$SCR_H
  if (( SCR_W > TCOLS || SCR_H > TROWS )); then xg_draw_toosmall; return 0; fi
  # THE TITLE CARD, while the door has it up (tc_*, terminal.command)
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_card]} )); then xg_title $1; return 0; fi
  case "$XG_VIEW" in
    menu)  xg_draw_menu ;;
    home)  xg_draw_home ;;
    store) xg_draw_store ;;
    adopt) xg_draw_adopt ;;
    stats) xg_draw_stats ;;
    release) xg_draw_release ;;
    *)     xg_draw_menu ;;
  esac
  return 0
}

xg_tick() {   # xg_tick T — the beat · the sim, live decay and autosave ride it
  XG_NOW=$1
  xg_lz_tick                         # the red dot, when it is out · the chase outranks the brain
  xg_actor_update                    # one beat of the emotion sim · she thinks, moves, feels
  (( XG_NOW - XG_LAST_DAYCHK > 30.0 )) && { xg_day_catchup; XG_LAST_DAYCHK=$XG_NOW; }   # midnight, while open
  # a gentle decay while the window is open · needs move down as time passes
  if (( XG_NOW - XG_LAST_DECAY > 20.0 )); then
    xg_vaddf food -0.0167; xg_vaddf water -0.0222; xg_vaddf mood -0.0056; xg_vaddf box 0.0111
    (( ${XG[food]:-100} < 15 || ${XG[water]:-100} < 15 )) && xg_vaddf health -0.0083
    XG_LAST_DECAY=$XG_NOW
  fi
  (( XG_NOW - XG_LAST_SAVE > 30.0 )) && { xg_save_write; XG_LAST_SAVE=$XG_NOW; }
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE KEYBOARD · the unified model · menu → ◂▸ rings pages → ⎋ back → out
# ══════════════════════════════════════════════════════════════════════════
xg_key() {   # xg_key KEY -> 0 handled · 1 the door's
  local k="$1"; local -i i
  # THE TITLE CARD ANSWERS FIRST: its keys are the door's, on every machine
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_key]} )); then tc_key "$k"; return $?; fi
  # ── THE GATE OWNS THE KEYBOARD while it is up · one question, two answers ──
  if [[ "$XG_VIEW" == release ]]; then
    case "$k" in
      y|Y)       xg_release_do; snd away ;;
      n|N|esc)   XG_REL_SLOT=-1; xg_go_view stats; snd move ;;
      *)         snd no ;;
    esac
    return 0
  fi
  # ── THE ROSTER · the stats page's own keys.  Renaming owns the keyboard
  #    while it is up, the way the certificate does: every letter is a letter.
  if [[ "$XG_VIEW" == stats ]]; then
    if (( XG_RENAME )); then
      case "$k" in
        enter) [[ -n "$XG_RENAME_BUF" ]] && { XG[name]="$XG_RENAME_BUF"; XR_KEY=''; xg_log "renamed · now ${XG[name]}" '' $CYAN; xg_save_write; }; XG_RENAME=0; snd pick ;;
        esc)   XG_RENAME=0; snd away ;;
        back)  XG_RENAME_BUF="${XG_RENAME_BUF%?}" ;;
        space) (( ${#XG_RENAME_BUF} < 16 )) && XG_RENAME_BUF+=' ' ;;
        *)     [[ ${#k} -eq 1 && "$k" == [A-Za-z0-9] ]] && { (( ${#XG_RENAME_BUF} < 16 )) && XG_RENAME_BUF+="$k"; } ;;
      esac
      return 0
    fi
    local -i rn=$XR_N; (( rn < 1 )) && rn=1
    case "$k" in
      up)    XR_ROW=$(( (XR_ROW+rn-1)%rn )); snd move; return 0 ;;
      down)  XR_ROW=$(( (XR_ROW+1)%rn )); snd move; return 0 ;;
      wheelup)   (( XR_ROW > 0 )) && { XR_ROW=$(( XR_ROW-1 )); snd move; }; return 0 ;;
      wheeldown) (( XR_ROW < rn-1 )) && { XR_ROW=$(( XR_ROW+1 )); snd move; }; return 0 ;;
      pgup)      XR_ROW=0; snd move; return 0 ;;
      pgdn)      XR_ROW=$(( rn-1 )); snd move; return 0 ;;
      enter) # ⏎ · THE ONE YOU ARE LOOKING AT COMES INTO THE ROOM.  [H] is
             # already the HOME page's letter, so the swap lives on enter,
             # which is the same gesture that signs for an arrival.
             if (( XR_ROW == XR_HOME )); then
               xg_log "${XG[name]} is already in the room" '' $AMBER; snd no
             elif xg_pet_enter ${XR_SLOT[$XR_ROW]:--1}; then
               xg_log "${XG[name]} is in the room · ${XG[label]}" '' $CYAN
               XR_ROW=0; snd mew
             else snd no; fi
             return 0 ;;
      r|R)   xg_release_ask ${XR_SLOT[$XR_ROW]:--1} && snd pick || snd no; return 0 ;;
      n|N)   if (( XR_ROW == XR_HOME )); then XG_RENAME=1; XG_RENAME_BUF="${XG[name]:-}"; snd pick
             else xg_log 'only the one in the room answers to a new name' '' $AMBER; snd no; fi; return 0 ;;
      v|V)   if (( XR_ROW == XR_HOME )); then xg_act_vet; XR_KEY=''
             else xg_log 'the vet sees whoever is in the room' '' $AMBER; snd no; fi; return 0 ;;
    esac
  fi
  # ── THE CERTIFICATE owns the keyboard · every letter is part of a name ──
  #    You sign for an animal by writing it one, on the card, in the SIGN
  #    field.  That is why a new litter is on ▴ ▾ and not on [R]: a page
  #    that takes letters cannot also spend one of them on a command.
  if [[ "$XG_VIEW" == adopt ]]; then
    case "$k" in
      left)  XG_ASEL=$(( (XG_ASEL+3)%4 )); snd move; return 0 ;;
      right) XG_ASEL=$(( (XG_ASEL+1)%4 )); snd move; return 0 ;;
      up|down|wheelup|wheeldown)
             XG_HOUSE[litter]=$(( (RANDOM*32768+RANDOM) + 1 ))
             xg_adopt_scan; XG_PGK=''; snd pick; return 0 ;;
      back)  if [[ -n "$XG_WBUF" ]]; then XG_WBUF="${XG_WBUF%?}"; snd move; else snd no; fi; return 0 ;;
      enter) if [[ -n "$XG_WBUF" ]]; then
               XG_WSEED=${XG_ADS[$XG_ASEL]}; XG_WSP="${XG_ADSP[$XG_ASEL]}"
               xg_adopt_take
             else snd no; fi
             return 0 ;;
      *)     if [[ ${#k} -eq 1 && "$k" == [A-Za-z] ]] && (( ${#XG_WBUF} < 12 )); then
               XG_WBUF+="${(U)k}"; snd move; return 0
             fi ;;
    esac
  fi
  # ── THE SHELVES · the store's own keys ──
  if [[ "$XG_VIEW" == store ]]; then
    local -i sn=${#XG_ST_ID[@]}
    case "$k" in
      up)    XG_OROW=$(( (XG_OROW+sn-1)%sn )); snd move; return 0 ;;   # the catalogue, in reading order
      down)  XG_OROW=$(( (XG_OROW+1)%sn )); snd move; return 0 ;;
      # THE WHEEL IS THE SUITE'S, and it is quiet: a notch moves the cursor a
      # thing and the window follows it, a page key moves a department, and
      # neither of them ever buys anything.  They clamp where ▴▾ wrap.
      wheelup)   (( XG_OROW > 0 )) && { XG_OROW=$(( XG_OROW-1 )); snd move; }; return 0 ;;
      wheeldown) (( XG_OROW < sn-1 )) && { XG_OROW=$(( XG_OROW+1 )); snd move; }; return 0 ;;
      pgup)      XG_OROW=$(( XG_OROW-3 )); (( XG_OROW < 0 )) && XG_OROW=0; snd move; return 0 ;;
      pgdn)      XG_OROW=$(( XG_OROW+3 )); (( XG_OROW > sn-1 )) && XG_OROW=$(( sn-1 )); snd move; return 0 ;;
      enter) xg_store_buy $XG_OROW; return 0 ;;
    esac
  fi
  # ── THE CARE KEYS · only in the room, where the animal is ──
  if [[ "$XG_VIEW" == home ]]; then
    xg_lz_key "$k" && return 0                    # the arrows steer the dot while it is out
    [[ "$k" == esc ]] && (( ${XG_LZ[on]:-0} )) && XG_LZ=(on 0)
    case "$k" in
      a|A) xg_act_admire; return 0 ;;
      d|D) xg_act_decor;  return 0 ;;
      f|F) xg_act_feed;  return 0 ;;
      w|W) xg_act_water; return 0 ;;
      p|P) xg_act_play;  return 0 ;;
      g|G) xg_act_groom; return 0 ;;
      t|T) xg_act_treat; return 0 ;;
      b|B) xg_act_scoop; return 0 ;;
      z|Z) xg_act_nap;   return 0 ;;
      enter) xg_act_pet; return 0 ;;
    esac
  fi
  # ── the unified navigation · menu → ◂▸ rings pages → ⎋ back → out ──
  case "$k" in
    down)  [[ "$XG_VIEW" == menu ]] && { (( XG_MROW < XG_PAGES - 1 )) && { (( XG_MROW++ )); snd move }; return 0 }; return 1 ;;
    up)    [[ "$XG_VIEW" == menu ]] && { (( XG_MROW > 0 )) && { (( XG_MROW-- )); snd move }; return 0 }; return 1 ;;
    left)  [[ "$XG_VIEW" == menu ]] && return 0; xg_page_go -1; return 0 ;;
    right) [[ "$XG_VIEW" == menu ]] && return 0; xg_page_go  1; return 0 ;;
    enter) [[ "$XG_VIEW" == menu ]] && { xg_go_view "${XG_PV[$XG_MROW]}"; snd pick; return 0 }; return 1 ;;
    esc)   [[ "$XG_VIEW" == menu ]] && return 1; xg_go_view menu; snd move; return 0 ;;
    *)
      for (( i = 0; i < XG_PAGES; i++ )); do
        [[ "${k:u}" == "${XG_PK[$i]}" ]] && { xg_go_view "${XG_PV[$i]}"; snd pick; return 0 }
      done
      return 1 ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════════
# THE SAVE · the animal lives in terminal.save, written whole and atomically
# ══════════════════════════════════════════════════════════════════════════
# The pet is one section of the house save (xenogotchi.*), flat — one dotted
# path a line — so it is hand-editable and travels with the repo.  Only this
# machine's own lines are rewritten; every other section is copied through
# untouched.  It is written to a neighbouring temp file and moved into place,
# so a crash mid-write costs the last autosave and never the pet.  Read
# defensively: a missing field falls back to a default rather than a new animal.
typeset -gi XG_FRESH=0; typeset -gF XG_LAST_SAVE=0.0; typeset -g XG_SAVE_ERR=''
typeset -ga XG_SAVE_KEYS
# EVERYTHING THAT MAKES THIS ANIMAL THIS ANIMAL.  The first three rows are
# who it is and how it is doing; the fourth is its paperwork, written out so a
# save restored on another machine is the same creature even if the decks have
# moved on since; `pal` is its twelve colours, and `breed` what it was bred as.
# WHICH OF THEM ARE NUMBERS · checked on the way in, see xg_pet_read
typeset -ga XG_NUM_KEYS
XG_NUM_KEYS=(seed born span saved_at health food water bond coat mood pep box
             credits day streak treats_today catches_today
             last_groom last_pet overstim overstim_at
             c_pets c_naps c_treats c_catches c_gifts
             pj ear_l ear_s tail_n hunger_m social_m)
XG_SAVE_KEYS=(name species breed seed stage born span saved_at \
              health food water bond coat mood pep box \
              credits day streak last_day treats_today catches_today gift album \
              last_groom last_pet overstim overstim_at \
              c_pets c_naps c_treats c_catches c_gifts \
              colorway pattern pj label eyes build ears ear_l ear_s tail tail_n \
              temper tname hunger_m social_m pal)
typeset -ga XG_HOUSE_KEYS; XG_HOUSE_KEYS=(toy kibble style own litter pantry nbed bed nbowl bowl)
# A SLOT THE WRITER IS TO FORGET, and the animals that have been let go.  A
# released pet's lines are dropped rather than blanked, and a short record is
# left in its place so the file is honest about the house having had it.
typeset -gi XG_READONLY=0     # the save held pets we could not read · do not write
typeset -gi XG_DROP=-1
typeset -ga XG_FREED

# ── THE CLOCK · wall-clock time, applied at power-on to the awake animal ──
# The first 48 absent hours count in full; past that, mercy damping drops the
# rest to a quarter rate, so a weekend away earns a hungry, theatrical animal
# and never a tragedy.  Absence is capped at 45 days however long you were
# really gone, and a jump over 120 days is read as a wrong clock, not a lost
# pet — the mark is reset and nothing is charged.
typeset -gF XG_LAST_DECAY=0.0 XG_LAST_DAYCHK=0.0
typeset -gA XG_FR                     # each vital's fractional part, carried between beats
xg_vaddf() {   # xg_vaddf KEY DELTA — a fractional nudge, CARRIED until it makes a whole point.
  # (It used to round each nudge on its own, so anything under half a point a
  # beat — a frame's sleep, a frame's grooming, the live decay — rounded away.)
  local -F acc=$(( ${XG_FR[$1]:-0.0} + $2 ))
  local -i whole=$(( int(acc) )) v
  if (( whole != 0 )); then
    v=$(( ${XG[$1]:-0} + whole )); (( v>100 ))&&v=100; (( v<0 ))&&v=0; XG[$1]=$v
    acc=$(( acc - whole ))
  fi
  XG_FR[$1]=$acc
}
xg_apply_clock() {
  local -F now=${EPOCHSECONDS:-0} saved=${XG[saved_at]:-0} elapsed hours eff
  (( saved <= 0 || now <= saved )) && return 0
  elapsed=$(( now - saved ))
  if (( elapsed > 120*86400 )); then xg_log 'the ship clock had jumped — mark reset, nothing owed' '' $GREY; return 0; fi
  (( elapsed > 45*86400 )) && elapsed=$(( 45*86400 ))
  hours=$(( elapsed / 3600.0 ))
  if (( hours <= 48.0 )); then eff=$hours; else eff=$(( 48.0 + (hours-48.0)*0.25 )); fi
  xg_vaddf food $(( -3.0*eff )); xg_vaddf water $(( -4.0*eff )); local -F solo=1.0; xg_owned orb && solo=0.5          # the hover orb plays with it while you're gone
  xg_vaddf mood $(( -1.0*eff*solo ))
  xg_vaddf pep $(( 3.0*eff )); xg_vaddf box $(( 2.0*eff ))           # rested, and the box fills on its own
  (( ${XG[food]:-100} < 15 || ${XG[water]:-100} < 15 )) && xg_vaddf health $(( -1.5*eff ))
  # (the days themselves are counted by the daily roll, one calendar day at a time)
  if (( hours >= 3.0 )); then
    local -i h=$(( int(hours) ))
    if (( h >= 48 )); then xg_log "back after $(( h/24 )) days · ${XG[name]:-it} is theatrically starving" 'FOOD --' $AMBER
    elif (( h >= 12 )); then xg_log "back after $h hours · a pointed look toward the bowl" '' $AMBER
    else xg_log "back after $h hours · ${XG[name]:-it} noticed" '' $GREY; fi
  fi
  return 0
}
# THE HOUSE'S save_get, READ THE SAME WAY AND WITHOUT THE FORK.  save_get
# answers on stdout, so every field read through it was a subshell -- an
# animal is fifty-odd fields, and a house with no animal in its first slot
# looked through two hundred and fifty-six of them -- which made reading the
# animal the slowest thing about opening this machine.  The arcade learned
# the same lesson (ar_unq); this is the same answer, to the character.
xg_sv() {   # xg_sv PATH [DEFAULT] -> REPLY
  REPLY="${SAVE[$1]:-}"
  [[ -n "$REPLY" ]] || { REPLY="${2:-}"; return 1 }
  if [[ "$REPLY" == '"'*'"' ]]; then
    REPLY="${REPLY[1,-2]}"
    REPLY="${REPLY//\\\"/\"}"; REPLY="${REPLY//\\\\/\\}"; REPLY="${REPLY//\\n/ }"
  fi
  return 0
}
xg_pet_read() {   # xg_pet_read SLOT — that slot's animal, out of the save and into XG
  # Reading an animal used to be half of xg_save_load.  It is its own thing
  # now because the STATS page can put a DIFFERENT one in the room, and that
  # wants exactly this and nothing else around it.
  local -i slot=$1; local k v
  XG=()
  for k in "${XG_SAVE_KEYS[@]}"; do xg_sv xenogotchi.pets.$slot.$k ''; v="$REPLY"; [[ -n "$v" ]] && XG[$k]="$v"; done
  # EVERY NUMBER OUT OF THE FILE IS CHECKED BEFORE ANYTHING DOES ARITHMETIC
  # ON IT.  terminal.save is a text file the user may hand-edit, and these
  # values go straight into (( )) and `local -i`: a field reading
  # `333,XG_ACTIVE=9` is not a seed, it is an assignment, and it reassigned
  # the active slot and wrote a duplicate block into the file.  (Nothing is
  # ever executed -- zsh arithmetic does not substitute commands -- but a
  # number that is not a number has no business being one.)  xg_roster_scan
  # has always checked its seed this way; the resident's read never did.
  for k in "${XG_NUM_KEYS[@]}"; do
    v="${XG[$k]:-}"
    [[ -z "$v" ]] && continue
    [[ "$v" == <->(|.<->) ]] || unset "XG[$k]"
  done
  # FOOD was FED, before it had its name · read the old key once, before any default can land
  [[ -z "${XG[food]:-}" ]] && { xg_sv xenogotchi.pets.$slot.fed ''; v="$REPLY"; [[ -n "$v" ]] && XG[food]="$v"; }
  : ${XG[species]:=cat} ${XG[seed]:=61653} ${XG[stage]:=YOUNG CAT} ${XG[health]:=80} ${XG[food]:=70} ${XG[water]:=70} \
    ${XG[bond]:=50} ${XG[coat]:=80} ${XG[mood]:=70} ${XG[pep]:=70} ${XG[box]:=20} ${XG[credits]:=0} ${XG[day]:=1} \
    ${XG[treats_today]:=0} ${XG[last_groom]:=0} ${XG[last_pet]:=0} ${XG[overstim]:=0} ${XG[overstim_at]:=0}
  : ${XG[food]:=70}
  # AN ANIMAL ARRIVES DRESSED.  A save written by this build carries its coat
  # and wears it; one written before it is dealt one here, at load, rather
  # than whenever some cache happens to miss -- the roster and the stats card
  # ask for a label long before anything asks for a body.
  #
  # THE ORDER MATTERS AND IT IS THIS: what it was bred as, then what it is
  # wearing, then how long it has -- because the span comes off the breed and
  # the birthday comes off the span.  A save older than breeds is worked out
  # in the other direction: it kept no breed, so it is dealt the OLD way, the
  # coat it has always had is read back, and the breed is inferred FROM that
  # coat.  Such an animal keeps its SPECIES span, not the inferred breed's:
  # the breed is a name put to a creature you already own, and naming it must
  # not shorten its life.
  local prebreed=0
  [[ -n "${XG[breed]:-}" ]] || prebreed=1
  if [[ -z "${XG[label]:-}" || -z "${XG[pal]:-}" ]]; then
    if (( prebreed )); then
      xg_deal_coat ${XG[seed]} "${XG[species]}" '*'
      xg_breed_infer "${XG[species]}" "${XG[colorway]}" "${XG[pattern]}" ${XG[seed]}
      XG[breed]="$REPLY"
      xg_pal_str; XG[pal]="$REPLY"
    else
      xg_wear ${XG[seed]} "${XG[species]}" "${XG[pal]:-}"
    fi
  fi
  # A SAVE FROM BEFORE SPANS WERE KEPT has one worked out once, here, and
  # written down from then on -- off the species if it is also older than
  # breeds, off its own breed if it is not.
  if [[ -z "${XG[span]:-}" ]]; then
    if (( prebreed )); then xg_lifespan ${XG[seed]} "${XG[species]:-cat}" '*'
    else                    xg_lifespan ${XG[seed]} "${XG[species]:-cat}" "${XG[breed]:-}"; fi
    XG[span]=$REPLY
  fi
  # A SAVE FROM BEFORE AGES WERE KEPT gets a birthday worked back from that
  # span -- its own, which the save now records.
  [[ -n "${XG[born]:-}" ]] || XG[born]=$(( ${EPOCHSECONDS:-0} - 0.15*${XG[span]}*86400.0 ))
  return 0
}

xg_pet_enter() {   # xg_pet_enter SLOT — whoever is in the room goes to their papers, and this one comes in
  # NOTHING IS LOST IN THE SWAP.  The resident is written out whole first and
  # the file read back, so the animal coming in is chosen against what was
  # just saved; then it gets the clock it slept through, like any arrival.
  local -i slot=$1
  (( slot == XG_ACTIVE )) && return 1
  (( slot < 0 || slot >= XG_NPETS )) && return 1
  [[ -n "${SAVE[xenogotchi.pets.$slot.name]:-}" ]] || return 1
  xg_save_write
  save_load
  XG_ACTIVE=$slot
  xg_pet_read $slot
  xg_age_sync
  xg_apply_clock                               # the time it spent on the roster
  xg_day_catchup                               # and every calendar day in it
  XG_FRESH=0
  xg_wear ${XG[seed]} "${XG[species]}" "${XG[pal]:-}"
  xg_actor_init
  XG_CACHE_KEY=''; XG_PAL_KEY=''; XG_RCK=''; XR_KEY=''; XG_CAMF=-1.0; XG_PGK=''; XG_SS_C=(); XG_SS_A=()
  xg_save_write                                # the house records who is in the room now
  return 0
}

xg_save_load() {   # read the ACTIVE pet + the house, or mark the house fresh
  local n v av
  # the house first · roster index, count, and what the store has sold it
  xg_sv xenogotchi.active 0; av="$REPLY"; [[ "$av" == <-> ]] && XG_ACTIVE=$av || XG_ACTIVE=0
  xg_sv xenogotchi.npets 1;  av="$REPLY"; [[ "$av" == <-> ]] && XG_NPETS=$av  || XG_NPETS=1
  (( XG_NPETS < 1 )) && XG_NPETS=1
  XG_HOUSE=()
  for n in "${XG_HOUSE_KEYS[@]}"; do
    xg_sv xenogotchi.house.$n ''; v="$REPLY"; [[ -n "$v" ]] && XG_HOUSE[$n]="$v"
  done
  # A COUNT IS A COUNT AND AN INDEX POINTS AT SOMETHING THAT IS THERE.  The
  # house comes out of a file the owner is invited to carry between machines,
  # so a merged, truncated or hand-edited line can put a word where a count
  # goes, or a 99 where there are four beds.  Reading past the end of the bed
  # list is not a wrong bed -- under `set -u` it ends the cabinet.  So the
  # counts are made to be numbers, and the two that choose furniture are held
  # inside the furniture that exists.  The named things -- the toy, the
  # kibble, the core's style, the list of what is owned -- are words, and are
  # left as words.
  for n in litter pantry nbed bed nbowl bowl; do
    v="${XG_HOUSE[$n]:-}"
    [[ -z "$v" ]] && continue
    [[ "$v" == <-> ]] || { unset "XG_HOUSE[$n]"; continue }
    (( v > 999999 )) && XG_HOUSE[$n]=999999
  done
  (( ${XG_HOUSE[bed]:-0}  >= ${#XG_BED_NM[@]}  )) && XG_HOUSE[bed]=0
  (( ${XG_HOUSE[bowl]:-0} >= ${#XG_DISH_NM[@]} )) && XG_HOUSE[bowl]=0
  xg_sv xenogotchi.pets.$XG_ACTIVE.name ''; n="$REPLY"
  [[ -n "${XG_HOUSE[pantry]:-}" ]] || XG_HOUSE[pantry]=6          # a house that never had a pantry starts with a bag
  # AN INDEX THAT MISSES IS NOT AN EMPTY HOUSE.  `active` pointing at a slot
  # with no name -- because a released slot left a hole and the line was then
  # damaged, or because the file was truncated -- used to seed the demo pet
  # INTO that slot, set npets to 1, and write it immediately: the animal there
  # destroyed and every other one orphaned in place.  Look for a real one first.
  local -i sc
  if [[ -z "$n" ]]; then
    for (( sc=0; sc<256; sc++ )); do
      xg_sv xenogotchi.pets.$sc.name ''; v="$REPLY"
      [[ -n "$v" ]] && { XG_ACTIVE=$sc; n="$v"; break }
    done
  fi
  # AND IF THE FILE PLAINLY HOLDS PETS WE STILL COULD NOT READ ONE, the read
  # itself failed -- the driver stops at twenty thousand lines and the writer
  # has no such cap, so a long enough file simply never reaches us.  Refuse to
  # write rather than start a fresh house on top of it.
  XG_READONLY=0
  if [[ -z "$n" ]] && [[ -f "$SAVE_FILE" ]] && grep -q '^xenogotchi\.pets\.[0-9][0-9]*\.name=.' "$SAVE_FILE" 2>/dev/null; then
    XG_READONLY=1
    XG_SAVE_ERR='the save could not be read in full · nothing will be written'
  fi
  if [[ -z "$n" ]]; then xg_seed_pet; xg_age_sync; XG_FRESH=1; (( XG_READONLY )) || { XG_ACTIVE=0; XG_NPETS=1 }; return 0; fi
  xg_pet_read $XG_ACTIVE
  xg_age_sync
  xg_apply_clock                               # the time you were away, applied
  xg_day_catchup                               # and every calendar day in it, rolled
  XG_FRESH=0
  return 0
}
typeset -ga XG_TIDY_KEYS
# ONLY THESE.  This used to re-spell any value that looked like a decimal,
# which swept up ear_s and tail_n -- genes dealt at full precision, not
# modifiers already rounded to hundredths -- and quietly moved them.  These
# six are clock marks and day counts, where hundredths are all that is real.
XG_TIDY_KEYS=(born saved_at span last_groom last_pet overstim_at)
xg_save_tidy() {   # every number in the file is a number a person can read
  # TERMINAL.SAVE IS A FILE YOU BACK UP.  You carry it to another machine,
  # you diff it, you hand-edit it -- so what goes in it is spelled properly.
  # Left to $(( )), zsh writes 0.95 as 0.94999999999999996, 1.0 as "1." and a
  # clock mark as 83.7574289370, and all three went in verbatim.  Rounding to
  # hundredths changes the spelling and not the value: the modifiers are
  # already dealt to two places, and an epoch second keeps every digit that
  # matters (a double holds fifteen; an epoch second to 1/100 needs twelve).
  local k v f
  for k in "${XG_TIDY_KEYS[@]}"; do
    v="${XG[$k]:-}"
    [[ "$v" == <->.* ]] || continue              # a decimal number, and nothing else
    f="${v#*.}"; [[ "$f" == *[^0-9]* ]] && continue
    (( ${#f} > 2 )) && XG[$k]="$(LC_ALL=C printf '%.2f' $v)"
  done
  return 0
}
xg_save_write() {   # rewrite terminal.save · OUR lines fresh, everyone else's
  # kept — including the OTHER pets in the roster, whose sections pass through
  # untouched; only the house keys and the ACTIVE pet's section are rewritten.
  # A NAMELESS ANIMAL MEANT `return 0` · the whole write, house and credits
  # included, was dropped and the caller told it had succeeded.
  [[ -n "${XG[name]:-}" ]] || { XG_SAVE_ERR='nothing to save · the animal has no name'; return 1 }
  XG[saved_at]=${EPOCHSECONDS:-0}                # the mark the clock is measured from
  # AN ANIMAL IS NEVER WRITTEN WITHOUT ITS COLOURS.  One that came from a save
  # older than this already wore them; one just dealt has them in hand.
  [[ -n "${XG[pal]:-}" ]] || { xg_wear ${XG[seed]:-61653} "${XG[species]:-cat}" ''; }
  # A SAVE WE COULD NOT READ IN FULL IS NOT A SAVE WE MAY OVERWRITE · see
  # xg_save_load, which raises this when the file plainly holds pets that
  # never reached us.
  (( XG_READONLY )) && { XG_SAVE_ERR='the save could not be read in full · nothing written'; return 1 }
  xg_save_tidy
  # THE LINK IS NOT THE FILE.  `mv` over a symlink replaces the LINK, so a
  # save symlinked into a synced folder quietly stopped being the save after
  # the first write.  :A resolves it in the shell, with no readlink -f (which
  # older BSD userlands do not have).
  local dest="${SAVE_FILE:A}"
  local dir="${dest:h}"; [[ -d "$dir" ]] || mkdir -p "$dir" 2>/dev/null
  # AND THE TEMP NAME IS NOT GUESSABLE.  It was ${SAVE_FILE}.xg.$$ — pre-create
  # that as a symlink and the redirect follows it straight onto whatever it
  # points at.  Removing it first also clears a corpse from a killed run.
  local tmp="${dest}.xg.$$.${RANDOM}${RANDOM}" line k
  rm -f "$tmp" 2>/dev/null
  # EVERY LINE IS COUNTED ON THE WAY OUT, and the count is checked against the
  # file before anything is committed.  The group's own status is NOT the
  # write's status: a brace group returns its LAST command, and the last one
  # here is the freed-ledger loop, which is empty on an ordinary save and so
  # returns 0 however badly the prints went.  On a full disk this reported
  # success and moved a 0-byte file over a save holding every pet the user had.
  local -i want=0 got=0 hi=-1 sl
  # THE FREED LEDGER IS KEYED BY SLOT, and a slot can be released more than
  # once -- so the old lines were passed through AND the new ones appended,
  # three more lines every time, forever.  Past twenty thousand lines the
  # driver's reader stops and the house looks empty.  Drop any record we are
  # about to rewrite, exactly as the active pet's own block is dropped.
  local frdrop='' fr0 fs
  for fr0 in "${XG_FREED[@]}"; do frdrop+=" ${fr0%%|*} "; done
  {
    if [[ -f "$SAVE_FILE" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
          xenogotchi.schema=*|xenogotchi.active=*|xenogotchi.npets=*|xenogotchi.house.*) continue ;;
          xenogotchi.pets.${XG_ACTIVE}.*) continue ;;
        esac
        (( XG_DROP >= 0 )) && [[ "$line" == xenogotchi.pets.${XG_DROP}.* ]] && continue
        # ANOTHER CABINET MAY HAVE ADOPTED WHILE WE HELD AN OLD COUNT.  The
        # file is the authority on how many slots are in use; writing npets
        # from stale memory made the other instance's new pet unreachable and
        # the next adoption then took its slot.
        if [[ -n "$frdrop" && "$line" == xenogotchi.freed.<->.* ]]; then
          fs="${${line#xenogotchi.freed.}%%.*}"
          [[ "$frdrop" == *" $fs "* ]] && continue
        fi
        if [[ "$line" == xenogotchi.pets.<->.name=?* ]]; then
          sl="${${line#xenogotchi.pets.}%%.name=*}"
          (( sl > hi )) && hi=$sl
        fi
        print -r -- "$line"; (( want++ ))
      done < "$SAVE_FILE"
    fi
    (( hi >= XG_NPETS )) && XG_NPETS=$(( hi+1 ))
    print -r -- "xenogotchi.schema=2"; (( want++ ))
    print -r -- "xenogotchi.active=$XG_ACTIVE"; (( want++ ))
    print -r -- "xenogotchi.npets=$XG_NPETS"; (( want++ ))
    for k in "${XG_HOUSE_KEYS[@]}"; do
      [[ -n "${XG_HOUSE[$k]:-}" ]] && { print -r -- "xenogotchi.house.$k=${XG_HOUSE[$k]}"; (( want++ )) }
    done
    for k in "${XG_SAVE_KEYS[@]}"; do print -r -- "xenogotchi.pets.$XG_ACTIVE.$k=${XG[$k]:-}"; (( want++ )); done
    # WHO WAS LET GO · name, species and the day, once each, kept for good
    local fr; local -a fp
    for fr in "${XG_FREED[@]}"; do
      fp=(${(s:|:)fr})
      print -r -- "xenogotchi.freed.${fp[0]}.name=${fp[1]}"; (( want++ ))
      print -r -- "xenogotchi.freed.${fp[0]}.species=${fp[2]}"; (( want++ ))
      print -r -- "xenogotchi.freed.${fp[0]}.at=${fp[3]}"; (( want++ ))
    done
  } > "$tmp"
  # THE COUNT IS THE PROOF.  Short means a print failed -- no space, no quota,
  # an I/O error -- and the old file is left exactly as it was.
  got=$(wc -l < "$tmp" 2>/dev/null) || got=-1
  if (( got < want )); then
    XG_SAVE_ERR="save failed · wrote $got of $want lines · the old save is untouched"
    rm -f "$tmp" 2>/dev/null; return 1
  fi
  if mv -f "$tmp" "$dest" 2>/dev/null; then
    XG_SAVE_ERR=''
    SAVE[xenogotchi.schema]=2; SAVE[xenogotchi.active]=$XG_ACTIVE; SAVE[xenogotchi.npets]=$XG_NPETS
    for k in "${XG_HOUSE_KEYS[@]}"; do [[ -n "${XG_HOUSE[$k]:-}" ]] && SAVE[xenogotchi.house.$k]="${XG_HOUSE[$k]}"; done
    for k in "${XG_SAVE_KEYS[@]}"; do SAVE[xenogotchi.pets.$XG_ACTIVE.$k]="${XG[$k]:-}"; done
    if (( XG_DROP >= 0 )); then for k in "${XG_SAVE_KEYS[@]}"; do unset "SAVE[xenogotchi.pets.$XG_DROP.$k]"; done; fi
    local fr2; local -a fp2
    for fr2 in "${XG_FREED[@]}"; do
      fp2=(${(s:|:)fr2})
      SAVE[xenogotchi.freed.${fp2[0]}.name]="${fp2[1]}"; SAVE[xenogotchi.freed.${fp2[0]}.species]="${fp2[2]}"
      SAVE[xenogotchi.freed.${fp2[0]}.at]="${fp2[3]}"
    done
    XG_FREED=()
    return 0
  fi
  XG_SAVE_ERR='cannot write'; rm -f "$tmp" 2>/dev/null; return 1
}

# ══════════════════════════════════════════════════════════════════════════
# THE TITLE CARD · the animal, at the door
# ══════════════════════════════════════════════════════════════════════════
# What the door puts up every time this machine is walked into (the tc_*
# vocabulary is terminal.command's, so the four machines' cards read as one
# family): the name in lights, and under it the animal itself -- the portrait
# its papers carry, standing in a spotlight on a lit floor, its six vitals
# either side of it, its name on a plate and the thing it most wants said
# underneath.  It blinks on the room's own clock and shuts its eyes for good
# while it is asleep in there (and the sleep rises off it, z by z); glad to
# see you, it shows it.  The card only ever reads it.  A fresh house has
# signed for nobody yet, so its card shows the shape of somebody and says
# who is waiting.
#
# AS THE CARD COMES UP the stage light comes on, the animal arrives in it a
# row at a time from the floor up -- the genetics deck's own delivery -- and
# its vitals fill and count.
#
# ON A TALL GLASS THE PORTRAIT IS BIGGER: the alcove's picture drawn at its
# own pixels rather than shrunk to fit a stall (xg_tc_size).
typeset -gi XG_TC_OY=0 XG_TC_PH=11 XG_TC_CAP=22
typeset -gF XG_TC_K=1.0
typeset -g  XG_TC_GLK=''; typeset -ga XG_TC_GLV   # the stage's light, kept for the glass it was mixed for
typeset -ga XG_TC_BK XG_TC_BC                 # the blink · each cell it changes, and to what
typeset -ga XG_TC_LK XG_TC_LC                 # the light where it shows (not under the animal) · cell, ink
typeset -ga XG_TC_PK XG_TC_PC XG_TC_PG XG_TC_PR   # the animal · cell, its ink, the ground under it · each row's first, from the floor up
typeset -gA XG_TC_PM XG_TC_INK                # the animal's cells, to keep the air off them · the card's inks, kept
typeset -gi XG_TC_PX=0 XG_TC_PY=0 XG_TC_PW=0 XG_TC_PHH=0 XG_TC_TOP=0 XG_TC_HL=0 XG_TC_HR=0   # … and its head's either side
typeset -gF XG_TC_L0=0.40 XG_TC_M0=0.58       # the beats · the light comes up · the animal arrives
typeset -g  XTKEY='' XTS=''; typeset -gi XTC=0
xg_tc_size() {   # xg_tc_size -> XG_TC_PH XG_TC_K XG_TC_CAP · the portrait for this glass
  # A TALL GLASS GETS THE ANIMAL AT ITS OWN PIXELS: the alcove shrinks its
  # pictures by 0.72 to fit a stall, and the card on a glass with the rows
  # for it asks for the picture unshrunk (to thirty-four pixels, seventeen
  # rows, at the most)
  if (( SCR_H - 4 >= 38 )); then XG_TC_PH=17; XG_TC_K=1.3889; XG_TC_CAP=34
  else XG_TC_PH=11; XG_TC_K=1.0; XG_TC_CAP=22; fi
  return 0
}
xg_tc_portrait() {   # xg_tc_portrait DAYS EYES — the card's portrait, at the card's size, into XG_CC
  XG_SS_K=$XG_TC_K; XG_SS_CAP=$XG_TC_CAP
  xg_stall_sprite ${XG[seed]:-61653} $1 "${XG[species]:-cat}" $2 "${XG[pal]:-}" "${XG[span]:-}" "${XG[breed]:-}"
  XG_SS_K=1.0; XG_SS_CAP=22
  return 0
}
xg_tc_key() {   # xg_tc_key -> XTKEY · everything the still part is a picture of
  local -i h=${XG[health]:-0} f=${XG[food]:-0} w=${XG[water]:-0} m=${XG[mood]:-0} b=${XG[bond]:-0} p=${XG[pep]:-0}
  XTKEY="xg|$XG_FRESH|$XG_ACTIVE|${XG[seed]:-}|${XG[name]:-}|${XG[species]:-}|${XG[breed]:-}|${XG[stage_i]:-}|${XG[stage]:-}"
  XTKEY+="|${XG[grow]:-}|${XG[pal]:-}|${XG[label]:-}|${XG[day]:-}|${XG[credits]:-}|$h|$f|$w|$m|$b|$p"
  return 0
}
xg_tc_status() {   # xg_tc_status -> XTS XTC · the one thing it most wants said
  local nm="${XG[name]:-IT}"
  local -i h=${XG[health]:-100} f=${XG[food]:-100} w=${XG[water]:-100} m=${XG[mood]:-0} bx=${XG[box]:-0}
  if   (( XG_FRESH )); then XTS='FOUR ARRIVALS ARE WAITING'; XTC=$CYAN
  elif (( h < 25 ));   then XTS="$nm IS UNWELL"; cmix $RED $AMBER 0.35; XTC=$CM
  elif (( f < 20 ));   then XTS="$nm IS HUNGRY"; XTC=$AMBER
  elif (( w < 20 ));   then XTS="$nm IS THIRSTY"; XTC=$AMBER
  elif (( bx >= 80 )); then XTS='THE BOX WANTS SCOOPING'; XTC=$AMBER
  elif [[ "${XG_A[behavior]:-}" == sleep ]]; then XTS="$nm IS ASLEEP"; cmix $CYAN $PURPLE 0.35; XTC=$CM
  elif (( m >= 70 ));  then XTS="$nm IS GLAD YOU CAME"; XTC=$LIME
  else                      XTS="$nm IS WAITING FOR YOU"; XTC=$LIME; fi
  return 0
}
xg_tc_meter() {   # xg_tc_meter X Y LABEL VALUE [AT] — one vital, LABEL ▰▰▰▱▱ VALUE, twenty-one cells from X · filling from AT
  local -i x=$1 y=$2 v=$4 i fill col off
  (( v < 0 )) && v=0; (( v > 100 )) && v=100
  if   (( v >= 60 )); then col=$LIME
  elif (( v >= 30 )); then col=$AMBER
  else cmix $RED $AMBER 0.35; col=$CM; fi
  v_text $x $y "${(r:6:)3}" $XG_LBL
  fill=$(( (v + 5) / 10 ))
  local on='' offs=''
  for (( i = 0; i < 10; i++ )); do if (( i < fill )); then on+='▰'; else offs+='▱'; fi; done
  v_text $(( x + 7 )) $y "$on" $col
  cshade $GREY 0.35; off=$CS; v_text $(( x + 7 + fill )) $y "$offs" $off
  v_text $(( x + 18 )) $y "${(l:3:)v}" $col
  if [[ -n "${5:-}" ]]; then
    tc_reveal $x $y 21 $5 0.01
    (( TC_PAINT )) && TC_MTR+=($(( x + 7 )) $y 10 $v $col $off $(( x + 18 )) 3 $5 2)
  fi
  return 0
}
xg_tc_silhouette() {   # the portrait as a shape only · nobody signed for yet
  local -i i n=${#XG_CC[@]} c
  cmix $BLACK $PURPLE 0.30; c=$CM
  for (( i = 0; i < n; i++ )); do (( XG_CC[i] >= 0 )) && XG_CC[$i]=$c; done
  return 0
}
xg_tc_cone() {   # xg_tc_cone CX FY PH — the stage light: a cone from above the glass, and its pool on the floor
  # A SPOTLIGHT, NOT A GLOW: narrow where it comes in at the top of the
  # stage, widening to the floor, brighter as it nears the floor, its edges
  # soft; and on the floor itself a wide warm pool.  The animal stands in it.
  local -i cx=$1 fy=$2 ph=$3 y yt x k hw0 hw1 c lc fl base
  local -F t hw I0 I u e
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  cmix $PINK $AMBER 0.38; lc=$CM
  cmix $AMBER $PINK 0.40; fl=$CM
  yt=$(( fy - ph )); hw0=5; hw1=$(( ph >= 15 ? 17 : 15 ))
  for (( y = yt; y < fy; y++ )); do
    t=$(( (y - yt) / (fy - 1.0 - yt) ))
    hw=$(( hw0 + (hw1 - hw0) * t )); I0=$(( 0.040 + 0.085 * t ))
    for (( x = cx - int(hw) - 3; x <= cx + int(hw) + 3; x++ )); do
      u=$(( abs(x - cx) / hw ))
      e=$(( (1.18 - u) / 0.40 )); (( e <= 0.0 )) && continue; (( e > 1.0 )) && e=1.0
      e=$(( e * e * (3.0 - 2.0 * e) ))
      I=$(( I0 * e * (1.0 - 0.22 * u * u) ))
      (( I > 0.006 )) || continue
      I=$(( int(I * 200.0 + 0.5) / 200.0 ))       # two-hundredths · the same few inks over and over
      c=${XG_TC_INK[c:$I]:-0}; (( c )) || { cmix $BLACK $lc $I; c=$CM; XG_TC_INK[c:$I]=$c }
      k=$(( base + y * TCOLS + x )); GB[$k]=$c; XG_TC_GLV+=($k $c)
    done
  done
  # the pool, a little wider than the cone's foot
  hw=$(( hw1 + 5.0 ))
  for (( x = cx - int(hw); x <= cx + int(hw); x++ )); do
    u=$(( abs(x - cx) / hw )); (( u < 1.0 )) || continue
    I=$(( 0.32 * (1.0 - u * u) ** 1.3 )); I=$(( int(I * 200.0 + 0.5) / 200.0 ))
    (( I > 0.006 )) || continue
    c=${XG_TC_INK[f:$I]:-0}; (( c )) || { cmix $BLACK $fl $I; c=$CM; XG_TC_INK[f:$I]=$c }
    k=$(( base + fy * TCOLS + x )); GB[$k]=$c; XG_TC_GLV+=($k $c)
  done
  return 0
}
xg_title_base() {   # the card's still part, painted once per reading of the animal and kept (tc_card)
  local -i oy r0 ph cx fy
  local s
  (( XI_LO )) || xg_ink
  tc_base XENOGOTCHI
  # the band's right-hand reading, the home page's own
  s="CREDITS ${XG[credits]:-0}"
  cmix $GLASS $PURPLE 0.32; v_text $(( APP_HR - ${#s} + 1 )) 0 "$s" $XG_LBL $CM
  # the name where every card has it (two rows into the CRT on the cabinet's
  # glass), the portrait, the plinth with its plate, the papers, the verdict
  # and the door: thirteen rows and the portrait's
  xg_tc_size; ph=$XG_TC_PH
  oy=$(( (TC_H - (ph + 13)) / 2 )); (( oy < 0 )) && oy=0
  r0=$(( oy + 1 ))
  tc_big XENOGOTCHI $r0 $AMBER $PINK
  cx=$(( TC_X0 + TC_W / 2 ))
  fy=$(( TC_Y0 + r0 + 6 + ph ))
  xg_stage_paint $cx $fy $ph $(( TC_Y0 + r0 + 6 ))
  XG_TC_SIG='card'
  tc_quiet $(( cx - 38 )) $(( fy - ph - 1 )) 77 $(( ph + 2 ))
  # ── its vitals, three a side, filling as the card comes up ──
  xg_stage_vitals $cx $fy $ph 0.95
  # ── the papers, under the nameplate (the plate itself is live) ──
  xg_stage_papers
  cshade $GREY 1.05; tc_center $(( r0 + 8 + ph )) "$REPLY" $CS
  tc_reveal $TC_CX $(( TC_Y0 + r0 + 8 + ph )) $TC_CW 1.00 0.32
  if (( XG_FRESH )); then tc_nav 'meet them'; else tc_nav "visit ${XG[name]:-}"; fi
  XG_TC_OY=$oy
  return 0
}
xg_stage_papers() {   # -> REPLY · the papers, the line under the plate
  # NOT THE PLATE, NOT THE BADGE · XG-9 is on the bezel and the day on the
  # coin door, so the papers say what the animal is, its coat and its age
  if (( XG_FRESH )); then REPLY='the genetics deck sent four tonight  ·  one goes home with you'
  else xg_age_str $XG_TC_DAYS; REPLY="${(L)XG[stage]:-}  ·  ${XG[label]:-}  ·  $REPLY old"; fi
  return 0
}
xg_stage_vitals() {   # xg_stage_vitals CX FY PH [AT] — the six vitals, three a side of the portrait · filling from AT on the card
  local -i cx=$1 fy=$2 ph=$3 y
  local at="${4:-}" a1='' a2='' a3=''
  (( XG_FRESH )) && return 0
  [[ -n "$at" ]] && { a1=$at; a2=$(( at + 0.07 )); a3=$(( at + 0.14 )); }
  y=$(( fy - ph / 2 - 2 ))
  xg_tc_meter $(( cx - 38 )) $y       HEALTH ${XG[health]:-0} $a1
  xg_tc_meter $(( cx - 38 )) $(( y + 2 )) FOOD   ${XG[food]:-0}   $a2
  xg_tc_meter $(( cx - 38 )) $(( y + 4 )) WATER  ${XG[water]:-0}  $a3
  xg_tc_meter $(( cx + 18 )) $y       MOOD   ${XG[mood]:-0}   $a1
  xg_tc_meter $(( cx + 18 )) $(( y + 2 )) BOND   ${XG[bond]:-0}   $a2
  xg_tc_meter $(( cx + 18 )) $(( y + 4 )) ENERGY ${XG[pep]:-0}    $a3
  return 0
}
typeset -gF XG_TC_DAYS=0.0 XG_SNOW=0.0            # the animal's age the stage was painted at · the stage's clock this frame
xg_stage_paint() {   # xg_stage_paint CX FY PH TOP [CONE] — the stage: its light, the animal on its floor, and what the live part needs (the card's and the list page's) · CONE rows of light over the floor, if not PH
  local -i cx=$1 fy=$2 ph=$3 px py x y k i w0 h0 base ci cone=${5:-$3}
  local -F d
  local -a clean shut
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  # the same light on the same ground every time this glass is this size, so
  # it is mixed once and kept
  local gk="$cx|$fy|$cone|$SCR_W|$SCR_H|$OX|$OY|$C_SCR|$R_SCR|$TCOLS|cone"
  if [[ "$gk" == "$XG_TC_GLK" ]]; then
    for (( i = 0; i < ${#XG_TC_GLV[@]}; i += 2 )); do GB[${XG_TC_GLV[$i]}]=${XG_TC_GLV[$(( i + 1 ))]}; done
  else
    XG_TC_GLV=()
    xg_tc_cone $cx $fy $cone
    XG_TC_GLK="$gk"
  fi
  # ── the portrait · its papers' own, at its age, standing on the floor ──
  xg_age_days; d=$REPLY; XG_TC_DAYS=$d
  xg_tc_portrait $d open
  # an animal too long for the stage between its vitals at its own pixels
  # (a lizard, a long breed) is drawn at the stall's size instead
  if (( XG_CCW > 34 && XG_TC_CAP != 22 )); then
    XG_TC_K=1.0; XG_TC_CAP=22; xg_tc_portrait $d open
  fi
  (( XG_FRESH )) && xg_tc_silhouette
  w0=$XG_CCW; h0=$XG_CCH
  px=$(( cx - w0 / 2 )); py=$(( fy - h0 ))
  # the ground under it, before it is there · the card's arrival lays the
  # animal down a row at a time over exactly this
  clean=()
  for (( y = py; y < py + h0; y++ )); do for (( x = px; x < px + w0; x++ )); do
    clean+=(${GB[$(( base + y * TCOLS + x ))]:-$BLACK})
  done; done
  xg_cell_shadow $px $py 0.45
  XG_TC_BK=(); XG_TC_BC=()
  if (( ! XG_FRESH )); then
    # THE BLINK, WORKED OUT HERE · the eyes-shut portrait is laid on the same
    # ground first and read back, so the live part has only the cells that
    # differ to put down -- soft edges and all, each blended as it will be
    local -a ocs; ocs=("${XG_CC[@]}"); local -a oca; oca=("${XG_CA[@]}")
    xg_tc_portrait $d closed
    if (( XG_CCW == w0 && XG_CCH == h0 )); then
      xg_blit_cells $px $py
      shut=()
      for (( y = py; y < py + h0; y++ )); do for (( x = px; x < px + w0; x++ )); do
        shut+=(${GB[$(( base + y * TCOLS + x ))]:-$BLACK})
      done; done
      i=0
      for (( y = py; y < py + h0; y++ )); do for (( x = px; x < px + w0; x++ )); do
        GB[$(( base + y * TCOLS + x ))]=${clean[$i]}; (( i++ ))
      done; done
    fi
    XG_CC=("${ocs[@]}"); XG_CA=("${oca[@]}"); XG_CCW=$w0; XG_CCH=$h0
  fi
  xg_blit_cells $px $py
  if (( ${#shut[@]} )); then
    i=0
    for (( y = py; y < py + h0; y++ )); do for (( x = px; x < px + w0; x++ )); do
      k=$(( base + y * TCOLS + x ))
      (( ${shut[$i]} != ${GB[$k]:-$BLACK} )) && { XG_TC_BK+=($k); XG_TC_BC+=(${shut[$i]}) }
      (( i++ ))
    done; done
  fi
  # THE ANIMAL, CELL BY CELL, FROM THE FLOOR UP · its ink and the ground it
  # covers, for the arrival · and where it is, to keep the air off it
  XG_TC_PK=(); XG_TC_PC=(); XG_TC_PG=(); XG_TC_PR=(); XG_TC_PM=()
  for (( y = h0 - 1; y >= 0; y-- )); do
    XG_TC_PR+=(${#XG_TC_PK[@]})
    for (( x = 0; x < w0; x++ )); do
      ci=$(( y * w0 + x ))
      (( XG_CC[ci] >= 0 )) || continue
      k=$(( base + (py + y) * TCOLS + px + x ))
      XG_TC_PK+=($k); XG_TC_PC+=(${GB[$k]:-$BLACK}); XG_TC_PG+=(${clean[$ci]}); XG_TC_PM[$k]=1
    done
  done
  XG_TC_PR+=(${#XG_TC_PK[@]})
  # its head, either side · the widest of its top third
  XG_TC_HL=$(( px + w0 )); XG_TC_HR=$(( px - 1 ))
  for (( y = 0; y < (h0 + 2) / 3; y++ )); do
    for (( x = 0; x < w0; x++ )); do
      (( XG_CC[y * w0 + x] >= 0 )) || continue
      (( px + x < XG_TC_HL )) && XG_TC_HL=$(( px + x )); (( px + x > XG_TC_HR )) && XG_TC_HR=$(( px + x ))
    done
  done
  # the light where it shows, as it finally is (the shadow on the floor in it)
  XG_TC_LK=(); XG_TC_LC=()
  for (( i = 0; i < ${#XG_TC_GLV[@]}; i += 2 )); do
    k=${XG_TC_GLV[$i]}
    (( ${XG_TC_PM[$k]:-0} )) && continue
    XG_TC_LK+=($k); XG_TC_LC+=(${GB[$k]:-$BLACK})
  done
  XG_TC_PX=$px; XG_TC_PY=$py; XG_TC_PW=$w0; XG_TC_PHH=$h0; XG_TC_TOP=$4
  XG_CACHE_KEY=''                              # the room asks the pose shelf afresh
  return 0
}
xg_tc_air() {   # xg_tc_air N PERIOD GLYPHS INK — what rises off the animal: N at a time, each PERIOD seconds from beside its head to gone
  local -i n=$1 i x y k c q dir
  local -F per=$2 a al fx
  local g
  local -a gs; gs=(${(s: :)3})
  for (( i = 0; i < n; i++ )); do
    a=$(( XG_SNOW / per + i * 1.0 / n )); a=$(( a - floor(a) ))
    # off the side of its head, drifting out as it rises · two of them take
    # a side each, the right first
    dir=1; (( n == 2 && i == 1 )) && dir=-1
    if (( dir > 0 )); then fx=$(( XG_TC_HR + 1.0 + a * 3.5 + 0.5 * sin(a * 6.2832) ))
    else                   fx=$(( XG_TC_HL - 1.0 - a * 3.5 - 0.5 * sin(a * 6.2832) )); fi
    x=$(( int(fx + 0.5) )); y=$(( XG_TC_PY + 2 - int(a * 4.6) ))
    (( y >= XG_TC_TOP )) || continue           # the air above the stage is the name's
    k=$(( (OY + R_SCR) * TCOLS + OX + C_SCR + y * TCOLS + x ))
    (( ${XG_TC_PM[$k]:-0} )) && continue        # never on the animal
    [[ "${GCH[$k]}" == ' ' ]] || continue
    # in over the first fifth, out over the last third, in eighths
    al=1.0; (( a < 0.2 )) && al=$(( a / 0.2 )); (( a > 0.67 )) && al=$(( (1.0 - a) / 0.33 ))
    q=$(( int(al * 8.0 + 0.5) )); (( q > 0 )) || continue
    c=${XG_TC_INK[a:$4:$q]:-0}; (( c )) || { cmix $BLACK $4 $(( q / 8.0 )); c=$CM; XG_TC_INK[a:$4:$q]=$c }
    g=${gs[0]}; (( ${#gs[@]} > 1 && a > 0.42 )) && g=${gs[1]}
    GCH[$k]="$g"; GF[$k]=$c
  done
  return 0
}
xg_stage_live() {   # xg_stage_live NOW INTRO — the stage's live part: (coming up on the card) the light and the arrival; the blink, and what rises off it
  local -F now=$1 ph fr
  local -i intro=$2 i shut=0 q=8 n c k e j front r
  XG_SNOW=$now
  TCP=1.0
  if (( intro )); then
    # THE LIGHT COMES UP · in eighths, the pool and the cone together
    tc_in $XG_TC_L0 0.36; q=$(( int(TCP * 8.0) ))
    if (( q < 8 )); then
      n=${#XG_TC_LK[@]}
      for (( i = 0; i < n; i++ )); do
        c=${XG_TC_LC[$i]}
        if (( q == 0 )); then GB[${XG_TC_LK[$i]}]=$BLACK
        else
          e=${XG_TC_INK[l:$c:$q]:-0}; (( e )) || { cmix $BLACK $c $(( q / 8.0 )); e=$CM; XG_TC_INK[l:$c:$q]=$e }
          GB[${XG_TC_LK[$i]}]=$e
        fi
      done
    fi
    # THE ANIMAL ARRIVES, from the floor up · the row arriving lit white, the
    # rows above it still the stage (under the light as far as it has come up)
    tc_in $XG_TC_M0 0.46
    if (( TCP < 1.0 )); then
      fr=$(( TCP * (XG_TC_PHH + 1.0) ))            # how many rows are down, and some of the next
      front=$(( int(fr) ))
      for (( r = 0; r < XG_TC_PHH; r++ )); do
        e=${XG_TC_PR[$(( r + 1 ))]}
        for (( j = XG_TC_PR[r]; j < e; j++ )); do
          k=${XG_TC_PK[$j]}
          if (( r < front )); then
            continue                               # down, and as it is
          elif (( r == front )); then
            c=${XG_TC_PC[$j]}
            n=${XG_TC_INK[w:$c]:-0}; (( n )) || { cmix $c $WHITE 0.55; n=$CM; XG_TC_INK[w:$c]=$n }
            GB[$k]=$n
          else
            c=${XG_TC_PG[$j]}
            if (( q >= 8 )); then GB[$k]=$c
            elif (( q == 0 )); then GB[$k]=$BLACK
            else n=${XG_TC_INK[l:$c:$q]:-0}; (( n )) || { cmix $BLACK $c $(( q / 8.0 )); n=$CM; XG_TC_INK[l:$c:$q]=$n }; GB[$k]=$n; fi
          fi
        done
      done
    fi

  fi
  # THE BLINK · the room's own clock and phase (xg_anim), and shut for good
  # while it is asleep in there · once it is all here
  if (( ${#XG_TC_BK[@]} && TCP >= 1.0 )); then
    [[ "${XG_A[behavior]:-}" == sleep ]] && shut=1
    ph=$(( XG_NOW * 0.25 + (${XG[seed]:-0} % 997) * 0.013 )); ph=$(( ph - floor(ph) ))
    (( ph < 0.045 )) && shut=1
    (( shut )) && for (( i = 0; i < ${#XG_TC_BK[@]}; i++ )); do GB[${XG_TC_BK[$i]}]=${XG_TC_BC[$i]}; done
  fi
  # WHAT RISES OFF IT · asleep, its sleep; glad you came, that
  if (( ! XG_FRESH && ( ! intro || now > 1.35 ) )); then
    if [[ "${XG_A[behavior]:-}" == sleep ]]; then
      c=${XG_TC_INK[zz]:-0}; (( c )) || { cmix $CYAN $PURPLE 0.35; cmix $CM $WHITE 0.25; c=$CM; XG_TC_INK[zz]=$c }
      xg_tc_air 3 2.7 'z Z' $c
    elif (( ${XG[mood]:-0} >= 70 && ${XG[health]:-100} >= 25 )); then
      xg_tc_air 2 3.3 '♥' $PINK
    fi
  fi
  return 0
}
xg_title() {   # xg_title T — the card: the still part kept, and the light, the arrival, the blink and the type live over it
  local -F t=$1
  local -i r0
  PACK_FILL=1
  xg_tc_key
  tc_card "$XTKEY" xg_title_base $t
  r0=$(( XG_TC_OY + 1 ))
  xg_stage_live $TC_NOW 1
  # the plate on the plinth, right under the floor
  if (( XG_FRESH )); then tc_spaced $(( r0 + 7 + XG_TC_PH )) 'INTAKE NIGHT' $AMBER $PINK $t 0.80
  else tc_spaced $(( r0 + 7 + XG_TC_PH )) "${XG[name]:-}" $AMBER $PINK $t 0.80; fi
  xg_tc_status
  tc_status $(( r0 + 10 + XG_TC_PH )) "$XTS" $XTC $t 1.28
  tc_prompt $(( r0 + 12 + XG_TC_PH )) $t '' 1.55
  return 0
}

xg_dress() {   # the cabinet's chrome, the XG-9's own
  local -i i
  local n="$PACK_NAME" sp='' out=''
  for (( i = 0; i < ${#n}; i++ )); do sp+="${sp:+ }${n[$i,$i]}"; done
  SURF_MODEL='XG-9'
  SURF_SIGN="◂ $sp ▸"
  SURF_TAG='ALIEN DYNAMICS · MODEL XG-9'
  for (( i = 0; i < XG_PAGES; i++ )); do out+="${out:+   }[${XG_PK[$i]}]${XG_PN[$i]}"; done
  SURF_KEYS="[◂▸]PAGE   [▲▼]ROW   $out   [⎋]BACK"
  (( ${SURF_TITLE:-0} )) && SURF_KEYS="${TC_KEYS:-$SURF_KEYS}"
  SURF_BADGE=" DAY ${XG[day]:-1} "
  SURF_MSG='ONE ANIMAL · ONE ROOM'
  return 0
}
xg_leave() { xg_save_write; return 0 }        # save on the way out, always

# STARTED IS NOT OPENED.  The pack can be started at power-on, behind the
# loading screen (terminal.command, SECTION 22b), and the animal is not read
# for keeps until its door is opened: reading it applies the clock it slept
# through and rolls the days it missed, and that clock is the one on the wall
# when somebody comes in -- not the one at power-on.  So xg_init only starts
# the pack, and xg_first (the door's PACK_FIRST, run on the first open either
# way) reads the animal the way this function always did.
#
# AHEAD OF TIME, the animal IS read -- but only so that the pictures it will
# need can be drawn early: its first pose, then the room (xg_warm).  Nothing
# else read then survives; xg_first reads it all again from the save.
xg_init() {   # xg_init — the pack started
  xg_palette
  return 0
}
typeset -g XG_WARM_ID=''                      # whose pictures were drawn ahead of time
xg_first() {   # xg_first — the door opened · the animal read, for keeps
  # A READ AHEAD OF TIME SAID NOTHING TO ANYBODY: its log goes, and so does
  # anything it drew if the animal standing in the save now is not the one it
  # drew (another window may have changed it since) -- the shelf is keyed on
  # the seed, not on the coat a save may have since given it
  XG_LOG_T=(); XG_LOG_G=(); XG_LOG_C=(); XG_LOG_N=0
  XG_SAVE_ERR=''
  local _xf_rck="$XG_RCK"
  xg_save_load                               # the saved animal, or a fixture on a fresh house
  # ...AND THE ROOM IS KEPT ACROSS IT.  Reading the animal again rolls its
  # missed days again, and a day that leaves a gift lets go of the room --
  # but the room's key already says whether a gift is on the floor (and a
  # gift is drawn the same whichever it is), so HOME's own comparison is the
  # judge: the same key is the same room, and any other key builds afresh.
  XG_RCK="$_xf_rck"
  if [[ -n "$XG_WARM_ID" && "$XG_WARM_ID" != "${XG[species]:-cat}.${XG[seed]:-0}.${XG[pal]:-}" ]]; then
    XG_PC_C=(); XG_PC_A=(); XG_PC_W=(); XG_PC_H=(); XG_RCK=''
  fi
  XG_WARM_ID=''; XG_CORE_PAL=0
  (( XG_FRESH )) && xg_save_write             # persist the fixture so care sticks from the first open
  xg_actor_init                               # the animal, standing somewhere, feeling some way
  XG_CACHE_KEY=''; XG_PAL_KEY=''; xg_anim; xg_cache_pose   # render the animal's first pose up front
  # A FRESH HOUSE OPENS ON INTAKE NIGHT · the fixture only stays if the reader
  # walks out of the centre without choosing anyone.
  if (( XG_FRESH )); then XG_VIEW='adopt'; XG_ASEL=0; else XG_VIEW='menu'; fi
  XG_MROW=0
  XG_CAMF=-1.0                                # the camera finds the animal fresh
  XG_LAST_SAVE=$XG_NOW
  return 0
}

# THE ROOM, BUILT AHEAD OF TIME AND A PIECE AT A TIME.  The world xg_draw_home
# stitches out of two shifted passes is the dearest picture in the house --
# the better part of a second, the first time HOME is opened -- and none of
# it depends on anything that moves.  So the loading screen builds it, cut at
# the joins each pass already has (the core · the porthole's ring and glass ·
# its light, its planet and its interior · the furniture · the walls).
# Between pieces the half-built pass waits in the very world cache it is
# going into and is put back on the glass to be finished; each pass starts
# from a cleared glass, which is what the second one always covered whole.
# The key is xg_draw_home's own, so HOME opens on a room it recognises -- and
# on any other (another glass, another gift, another sky) builds as it did.
# Step 0, before any of it, is the animal read ahead and its first pose drawn;
# step 1 is its portrait for the door's title card.
typeset -g XG_RW_KEY=''                       # the room the pieces are building
xg_warm() {   # xg_warm N T
  local -i n=$1 rx=-1 ry=0 rh fy cx bot ww rw maxcam spann zoom=0 s
  if (( n == 0 )); then
    xg_save_load
    xg_actor_init
    XG_CACHE_KEY=''; XG_PAL_KEY=''; xg_anim; xg_cache_pose
    XG_WARM_ID="${XG[species]:-cat}.${XG[seed]:-0}.${XG[pal]:-}"
    return 0
  fi
  # STEP 1 IS THE PORTRAIT the door's title card hangs (xg_title_base), eyes
  # open and eyes shut, into the stall sprites' own shelf · the dearest thing
  # on the card, and the first thing anybody walking in sees.  The room's
  # pieces are counted from the step after it.
  if (( n == 1 )); then
    local -F wd
    xg_age_days; wd=$REPLY
    xg_tc_size                                 # the size this glass's card will ask for
    xg_tc_portrait $wd open
    (( XG_FRESH )) || xg_tc_portrait $wd closed
    return 0
  fi
  n=$(( n - 1 ))
  (( SCR_W > TCOLS || SCR_H > TROWS )) && return 1      # a glass HOME would not draw
  rh=$(( SCR_H-2 )); fy=$(( ry+rh-4 )); cx=$(( SCR_W/2 )); bot=$(( ry+rh-1 ))
  ww=$(( SCR_W+64 )); rw=$(( ww+2 )); maxcam=$(( ww-SCR_W ))
  spann=$(( ww-40 )); (( spann<1 )) && spann=1
  (( rh < 30 )) && zoom=1
  xg_room_key
  if (( n == 1 )); then
    [[ "$XG_RKEY" == "$XG_RCK" ]] && return 1
    (( XG_CORE_PAL )) || { xg_core_pal; XG_CORE_PAL=1; }
    XG_WW=$ww; XG_RCH=(); XG_RCF=(); XG_RCB=(); XG_RW_KEY="$XG_RKEY"
  elif [[ "$XG_RKEY" != "$XG_RW_KEY" ]]; then
    XG_RW_KEY=''; return 1                    # the glass or the house moved under it · HOME builds its own
  fi
  if (( n > 10 )); then XG_RCK="$XG_RW_KEY"; XG_RW_KEY=''; return 1; fi
  (( n <= 5 )) && s=$maxcam || s=0
  case $(( (n-1) % 5 )) in
    0) v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
       xg_core_env $(( rx-s )) $ry $rw $rh $fy $cx ;;
    1) xg_rc_load $s
       xg_port_sky; xg_port_geom $(( rx-s )) $fy $spann $zoom; xg_port_glass ;;
    2) xg_rc_load $s
       xg_port_sky; xg_port_geom $(( rx-s )) $fy $spann $zoom
       xg_port_spill $fy $bot; xg_port_earth; xg_port_interior ;;
    3) xg_rc_load $s; xg_draw_furniture $(( rx-s )) $rw $fy $spann ;;
    4) xg_rc_load $s; xg_walls $s $ww $(( ry+1 )) $bot $(( (ry+1+fy)/2 )) ;;
  esac
  xg_rc_save_slice $s
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE PACK · what terminal.command asks of a machine, and nothing more
# ══════════════════════════════════════════════════════════════════════════
PACK_NAME='XENOGOTCHI'
PACK_MODEL='XG-9'
PACK_INIT='xg_init'
PACK_FIRST='xg_first'
PACK_WARM='xg_warm'
PACK_TICK='xg_tick'
PACK_DRAW='xg_draw'
PACK_KEY='xg_key'
PACK_DRESS='xg_dress'
PACK_LEAVE='xg_leave'
