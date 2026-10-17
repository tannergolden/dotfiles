#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════
# scripts/suite/system.zsh · THE MONITOR, as a page pack
# ══════════════════════════════════════════════════════════════════════════
# EIGHT INSTRUMENTS AND NO CABINET.  The original was system.py, a Python
# program that stood a cabinet of its own -- what it carried that this file
# does not was a hundred and twenty rows of walls, neon, bezel, coin door and
# floor, drawn in Python because at the time nothing else was going to draw
# them.  Something else is now.  terminal.command already
# stands a 122 x 43 cabinet with a 106 x 30 glass in it, at the same row map
# and the same column map, and it is already running when a reader asks for
# this machine.  So this file is the part that was ever really SYSTEM's: the
# readings, and the eight pictures made of them.
#
# TWO WAYS IN.
#   sourced   terminal.command sources it when [S] is pressed, calls
#             sys_tick for the readings and sys_draw for the glass, and
#             keeps its own beat, its own cabinet and its own governor.
#   --probe   run on its own it prints every reading, flat and sorted, and
#             draws nothing.  Which is the point:
#
# THE ORIGINAL WAS THE ORACLE.  system.py --probe printed the same hundred
# and twenty keys in the same order in the same format, and SYSTEM_MOCK=1
# pointed both files at scripts/fixtures/system/ instead of at this Mac, so
# the two implementations of these numbers were diffed key by key on a
# machine that does not exist, and 1:1 was a thing with a number on it
# rather than a claim.  The original has since been retired from the repo;
# scripts/fixtures/system/probe.expected is its output, committed, and this
# file's --probe still prints it byte for byte.
#
# WHAT ZSH CANNOT REACH is one reading and it is named where it is taken:
# per-core load comes from host_processor_info, which is a Mach call and not
# a command.  See sy_ticks.
emulate -L zsh
setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH
set -u
zmodload zsh/datetime 2>/dev/null || true
zmodload zsh/mathfunc 2>/dev/null || true

# WHERE THE FIXTURE IS, ASKED TWO WAYS.  Run on its own, $0 is this file and
# the fixture is beside it; SOURCED by the door, $0 depends on an option the
# door is free to set, and the door already knows where the repo is.  Ask the
# door first and fall back to the file, rather than trusting either alone.
if [[ -n "${REPO:-}" && -d "$REPO/scripts/fixtures/system" ]]; then
  SY_FIX="$REPO/scripts/fixtures/system"
else
  SY_HERE="${0:A:h}"
  SY_FIX="${SY_HERE:h}/fixtures/system"
fi
SY_MOCK=0
[[ -n "${SYSTEM_MOCK:-}" ]] && SY_MOCK=1
SY_IS_MAC=0
[[ "$OSTYPE" == darwin* ]] && SY_IS_MAC=1
(( SY_MOCK )) && SY_IS_MAC=1     # the fixture IS a Mac · system.py's own rule

# ══════════════════════════════════════════════════════════════════════════
# THE FIXTURE · one MacBook Pro, invented, and read off disk
# ══════════════════════════════════════════════════════════════════════════
# THE SAME FILES system.py READ, not a copy of them.  A second fixture is a
# second machine to disagree about, which is the whole failure this harness
# exists to catch -- so scripts/fixtures/system/ is read here byte for byte
# as it was read there, and the seam is the same seam: an unknown command
# falls through to the real one, so the paths that walk their own parent
# stay honest even in demo mode.
typeset -gA SY_SYSCTL SY_SEED
# NAMESPACED, AND THE NAME IS THE REASON.  These were SY_PS, SY_DF and so
# on, and SY_PS is ALSO the array holding the previous reading's system ticks
# -- so ps.txt was silently replaced by core zero's tick count, the process
# table came back with one row reading `17`, and nothing said a word.
SY_FX_VMSTAT=''; SY_FX_DF=''; SY_FX_NSIB=''; SY_FX_NSTCP=''
SY_FX_IOREG_DISK=''; SY_FX_IOREG_BATT=''; SY_FX_IOREG_HID=''; SY_FX_PMSET=''; SY_FX_PS=''

sy_fix() {   # sy_fix NAME -> the fixture's text, or nothing
  # A MISSING FIXTURE IS A DEMO WITH LESS IN IT, never a failure: this is a
  # monitor, and its whole manner is to say what it could not read.
  [[ -r "$SY_FIX/$1" ]] || { FIXT=''; return 0 }
  FIXT="$(<"$SY_FIX/$1")"
  return 0
}
sy_fix_tab() {   # sy_fix_tab NAME ASSOC — a name<TAB>value fixture, as a map
  local line k v
  sy_fix "$1"
  for line in ${(f)FIXT}; do
    [[ -z "$line" || "$line" == '#'* || "$line" != *$'\t'* ]] && continue
    k="${line%%$'\t'*}"; v="${line#*$'\t'}"
    eval "${2}[\${k}]=\${v}"
  done
  return 0
}

sy_fix_load() {
  (( SY_MOCK )) || return 0
  sy_fix_tab sysctl.tab SY_SYSCTL
  sy_fix_tab seed.tab   SY_SEED
  sy_fix vm_stat.txt;     SY_FX_VMSTAT="$FIXT"
  sy_fix df.txt;          SY_FX_DF="$FIXT"
  sy_fix netstat-ib.txt;  SY_FX_NSIB="$FIXT"
  sy_fix netstat-tcp.txt; SY_FX_NSTCP="$FIXT"
  sy_fix ioreg-disk.txt;  SY_FX_IOREG_DISK="$FIXT"
  sy_fix ioreg-batt.txt;  SY_FX_IOREG_BATT="$FIXT"
  sy_fix ioreg-hid.txt;   SY_FX_IOREG_HID="$FIXT"
  sy_fix pmset-batt.txt;  SY_FX_PMSET="$FIXT"
  sy_fix ps.txt;          SY_FX_PS="$FIXT"
  return 0
}

sy_seed() {   # sy_seed NAME DEFAULT -> SD, one number from seed.tab
  SD="${SY_SEED[$1]:-}"
  [[ "$SD" == (-|)<->(|.<->) ]] || SD="$2"
  return 0
}
sy_seed_run() {   # sy_seed_run NAME -> SDL, a row of numbers from seed.tab
  SDL=(${=SY_SEED[$1]:-})
  return 0
}

# ── the one seam · a command, or the fixture standing in for it ────────────
sy_run() {   # sy_run CMD... -> ROUT
  ROUT=''
  if (( SY_MOCK )); then
    case "$1" in
      sysctl)   if [[ "${2:-}" == -n ]]; then
                  if [[ "${3:-}" == kern.boottime ]]; then
                    sy_seed boot 1788259680
                    ROUT="{ sec = ${SD%.*}, usec = 0 }"
                  else
                    ROUT="${SY_SYSCTL[${3:-}]:-}"
                  fi
                fi
                return 0 ;;
      sw_vers)  case "${2:-}" in
                  -productVersion) ROUT='15.5' ;;
                  -productName)    ROUT='macOS' ;;
                  -buildVersion)   ROUT='24F74' ;;
                esac
                return 0 ;;
      scutil)   ROUT='moonbase'; return 0 ;;
      vm_stat)  ROUT="$SY_FX_VMSTAT"; return 0 ;;
      df)       ROUT="$SY_FX_DF"; return 0 ;;
      netstat)  if [[ " $* " == *' tcp '* ]]; then ROUT="$SY_FX_NSTCP"
                else ROUT="$SY_FX_NSIB"; fi
                return 0 ;;
      ipconfig) ROUT='192.168.1.24'; return 0 ;;
      route)    ROUT=$'   route to: default\ninterface: en0'; return 0 ;;
      ioreg)    if [[ " $* " == *IOBlockStorageDriver* ]]; then ROUT="$SY_FX_IOREG_DISK"
                elif [[ " $* " == *AppleSmartBattery* ]]; then ROUT="$SY_FX_IOREG_BATT"
                elif [[ " $* " == *BatteryPercent* ]];    then ROUT="$SY_FX_IOREG_HID"
                fi
                return 0 ;;
      pmset)    if [[ " $* " == *' batt '* ]]; then ROUT="$SY_FX_PMSET"
                elif [[ " $* " == *therm* ]]; then
                  ROUT=$'CPU_Scheduler_Limit \t= 100\nCPU_Speed_Limit \t= 100'
                else ROUT='lowpowermode         0'; fi
                return 0 ;;
      top)      ROUT='Processes: 412 total, 3 running, 409 sleeping, 2914 threads'
                return 0 ;;
      ps)       [[ " $* " == *' -Ao '* ]] && { ROUT="$SY_FX_PS"; return 0 } ;;
    esac
  fi
  whence -p "$1" >/dev/null 2>&1 || return 0
  # </dev/null, AND IT IS NOT DECORATION.  These children are inherited into a
  # terminal that the door has put in RAW MODE, and a reading command has no
  # business with the reader's keyboard: one that reads stdin eats a keystroke
  # meant for the glass, and one that reaches for termios can hand the tty
  # back in a state the door never asked for.  `top` and `ps` are the ones to
  # worry about and neither of them needs a word from anybody.
  ROUT="$("$@" </dev/null 2>/dev/null)" || ROUT=''
  return 0
}

sy_sysctl() {   # sy_sysctl NAME [DEFAULT] -> SCT
  sy_run sysctl -n "$1"
  SCT="${ROUT%%$'\n'*}"
  [[ -n "$SCT" ]] || SCT="${2:-}"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE READINGS · one flat map, keyed by the probe's own dotted path
# ══════════════════════════════════════════════════════════════════════════
# THE CONTRACT IS THE DATA MODEL.  system.py keeps a dict of scalars, lists
# and dicts and flattens it for --probe; this keeps the flattened form and
# never has anything to flatten.  The glass reads ${SY[cpu]} and
# ${SY[procs.4.cmd]} directly, the probe prints the map, and there is no
# second shape for the two to disagree about.
typeset -gA SY
# BUMPED ONCE PER READING OF THE PROCESS LIST, so the glass can tell one
# reading from the next.  The scope needs it: a contact only glides when the
# rows it is drawn from have actually changed, and without a serial every
# reading looked like the same reading and nothing ever moved.
typeset -gi SY_SERIAL=0
typeset -gi SY_N_CORES=0 SY_N_PROCS=0 SY_N_VOLS=0 SY_N_IFACES=0 SY_N_DEVICES=0

# ...and how each one is printed.  Anything not named here is a float at
# three decimals, which is system.py's own default.
SY_STR=' arch batt_health batt_state boot_disk build cpu_model disk_mount host kernel model_id net_if net_ip net_mac osname therm devices.name ifaces.ip ifaces.mac ifaces.name procs.cmd procs.path procs.state procs.time procs.user vols.dev vols.mount vols.name '
SY_BOOL=' ac batt_charging lowpower '
SY_INT=' batt_cyc_max batt_cycles batt_design batt_max batt_mins batt_now batt_pct boot conn_est conn_listen conn_wait disks mem_press ncpu ncpu_e ncpu_p net_ierr net_ipkt net_oerr net_opkt nphys nproc nthread uptime devices.pct ifaces.ierr ifaces.oerr ifaces.rxb ifaces.rxp ifaces.txb ifaces.txp procs.pid procs.rss '

# THE ORDER IS system.py's, WRITTEN DOWN.  It sorts its top-level keys once
# and then expands each in place, so a flat map sorted as strings comes out
# in a different order -- `cores.10` before `cores.2`, and `cores.n` last
# rather than first.  Sorting is not the contract; this list is.
SY_ORDER=(ac arch batt_amp batt_charging batt_cyc_max batt_cycles batt_design
          batt_health batt_max batt_mins batt_now batt_pct batt_state batt_volt
          boot boot_disk build compressions conn_est conn_listen conn_wait
          cores cows cpu cpu_hz cpu_idle cpu_model cpu_nice cpu_sys cpu_user
          decompressions devices disk_free disk_mount disk_total disk_used
          disks faults host ifaces io_r io_rops io_rtot io_w io_wops io_wtot
          kernel load lowpower mem_active mem_app mem_compressed mem_file
          mem_free mem_inactive mem_pct mem_press mem_purge mem_spec mem_total
          mem_used mem_wired model_id ncpu ncpu_e ncpu_p net_ierr net_if net_ip
          net_ipkt net_mac net_oerr net_opkt net_rx net_rxtot net_tx net_txtot
          nphys nproc nthread osname pageins pageouts procs swap_total
          swap_used swapins swapouts temp therm uptime vols watts)
# the list families, and the sorted subkeys system.py prints for each
SY_LIST=(devices ifaces procs vols)
SY_SUB_devices=(name pct)
SY_SUB_ifaces=(ierr ip mac name oerr rxb rxp txb txp)
SY_SUB_procs=(cmd cpu mem path pid rss state time user)
SY_SUB_vols=(avail dev mount name total used)

sy_line() {   # sy_line KEY TYPEKEY — one probe line for the key
  local k="$1" tk="$2" v="${SY[$1]:-}"
  if [[ "$SY_BOOL" == *" $tk "* ]]; then
    [[ "$v" == (1|true) ]] && print -r -- "$k=true" || print -r -- "$k=false"
  elif [[ "$v" == null ]]; then
    print -r -- "$k=null"
  elif [[ "$SY_STR" == *" $tk "* ]]; then
    v="${v//\\/\\\\}"; v="${v//\"/\\\"}"
    print -r -- "$k=\"$v\""
  elif [[ "$SY_INT" == *" $tk "* ]]; then
    printf '%s=%d\n' "$k" "${v:-0}"
  else
    printf '%s=%.3f\n' "$k" "${v:-0}"
  fi
  return 0
}

sy_probe() {   # every reading, flat and sorted · nothing drawn
  local k f sub
  local -i i n
  for k in "${SY_ORDER[@]}"; do
    case "$k" in
      load)  for (( i = 0; i < 3; i++ )); do sy_line "load.$i" load; done ;;
      cores) printf 'cores.n=%d\n' $SY_N_CORES
             for (( i = 0; i < SY_N_CORES; i++ )); do sy_line "cores.$i" cores; done ;;
      devices|ifaces|procs|vols)
             eval "n=\$SY_N_${k:u}"
             printf '%s.n=%d\n' "$k" $n
             eval "local -a subs; subs=(\${SY_SUB_${k}[@]})"
             for (( i = 0; i < n; i++ )); do
               for sub in "${subs[@]}"; do sy_line "$k.$i.$sub" "$k.$sub"; done
             done ;;
      *)     sy_line "$k" "$k" ;;
    esac
  done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# ONE-TIME FACTS · what this machine IS, asked once
# ══════════════════════════════════════════════════════════════════════════
sy_tidy_cpu() {   # the marketing comes off a processor name
  local s="$1"
  s="${s//\(R\)/}"; s="${s//\(TM\)/}"
  s="${s// CPU / }"; s="${s// Processor/}"
  while [[ "$s" == *'  '* ]]; do s="${s//  / }"; done
  TCPU="${s## }"; TCPU="${TCPU%% }"
  return 0
}

sy_identify() {
  local v nm ver name
  if (( SY_IS_MAC )); then
    sy_sysctl machdep.cpu.brand_string; v="$SCT"
    [[ -n "$v" ]] || { sy_sysctl hw.model; v="$SCT" }
    [[ -n "$v" ]] || v='unknown'
    sy_tidy_cpu "$v"; SY[cpu_model]="$TCPU"
    # NOT sysctl(..., "0") -- that default is the STRING "0", which is
    # truthy, so the fallback chain never ran and a machine without sysctl
    # reported no cores at all.
    sy_sysctl hw.logicalcpu;  SY[ncpu]="${SCT:-$(sy_ncpu_guess)}"
    sy_sysctl hw.physicalcpu; SY[nphys]="${SCT:-${SY[ncpu]}}"
    sy_run sw_vers -productVersion; ver="${ROUT%%$'\n'*}"
    sy_run sw_vers -productName;    nm="${ROUT%%$'\n'*}"; [[ -n "$nm" ]] || nm='macOS'
    sy_trim "$nm $ver"; SY[osname]="$TR"
    # ComputerName is a DISPLAY name -- "J. Smith's MacBook" -- and not a
    # hostname, so splitting it on a dot left "J".
    sy_run scutil --get ComputerName; name="${ROUT%%$'\n'*}"
    [[ -n "$name" ]] && SY[host]="$name"
    # `{ sec = 1788259680, usec = 0 }` · EXTENDED_GLOB is not set and must
    # not be (see terminal.command's conf reader), so the number comes out
    # by trimming rather than by matching.
    sy_sysctl kern.boottime
    if [[ "$SCT" == *sec* ]]; then
      v="${SCT#*sec}"; v="${v#*=}"; sy_trim "$v"; v="${TR%%[^0-9]*}"
      [[ "$v" == <-> ]] && SY[boot]="$v"
    fi
    sy_sysctl hw.model;  SY[model_id]="$SCT"
    sy_run sw_vers -buildVersion; SY[build]="${ROUT%%$'\n'*}"
    # Apple silicon splits its cores into performance and efficiency levels,
    # and which is which is worth saying
    sy_sysctl hw.perflevel0.logicalcpu 0; SY[ncpu_p]="$SCT"
    sy_sysctl hw.perflevel1.logicalcpu 0; SY[ncpu_e]="$SCT"
    sy_sysctl hw.cpufrequency_max 0
    SY[cpu_hz]=$(( ${SCT:-0} / 1000000000.0 ))
  fi
  SY_N_CORES=${SY[ncpu]}
  local -i i
  for (( i = 0; i < SY_N_CORES; i++ )); do SY[cores.$i]=0.0; done
  return 0
}

sy_ncpu_guess() {
  local n
  n="$(getconf _NPROCESSORS_ONLN 2>/dev/null)" || n=''
  [[ "$n" == <-> ]] || n=1
  print -r -- "$n"
}

# ══════════════════════════════════════════════════════════════════════════
# THE DEFAULTS · what every reading is before anything has been read
# ══════════════════════════════════════════════════════════════════════════
sy_init() {
  sy_fix_load
  # ...AND THE TAPES BEFORE THE FIRST SAMPLER, because a sampler now writes to
  # one -- and they are SEEDED FROM the fixture, so they cannot be set up
  # before it is read.  Getting this pair the wrong way round left the scope
  # with a single reading on it and the header honestly saying so: "the last
  # 10 s".
  sy_tapes_init
  local k
  # every scalar starts at zero, so a reading that could not be taken prints
  # a zero rather than dying under `set -u` halfway through a repaint
  for k in "${SY_ORDER[@]}"; do SY[$k]=0; done
  SY[host]="${HOST:-localhost}"; SY[host]="${SY[host]%%.*}"
  SY[kernel]="$(uname -r 2>/dev/null)"
  SY[arch]="$(uname -m 2>/dev/null)"
  SY[osname]=''; SY[cpu_model]=''; SY[model_id]=''; SY[build]=''
  SY[boot_disk]=''; SY[net_if]=''; SY[net_ip]=''; SY[net_mac]=''
  SY[batt_health]=''; SY[batt_state]=''; SY[therm]=''; SY[disk_mount]='/'
  SY[mem_total]=1.0; SY[disk_total]=1.0; SY[cpu_idle]=100.0
  # THE THREE LOAD FIGURES ARE INDEXED KEYS and SY_ORDER carries only the
  # bare `load`, so seeding from that table leaves load.0/1/2 uncreated --
  # and sy_load writes only as many as it could parse.  A machine that hands
  # back fewer than three numbers (an empty /proc/loadavg, no sysctl on PATH,
  # a decimal comma) left them missing, and the FIRST thing drawn -- the
  # instrument list, which prints `load %.2f` on its OVERVIEW row -- read one
  # under `set -u` and ended the program before anything reached the glass.
  SY[load.0]=0; SY[load.1]=0; SY[load.2]=0
  SY[mem_press]=1; SY[batt_mins]=-1; SY[ncpu]=$(sy_ncpu_guess)
  SY[nphys]=${SY[ncpu]}
  if (( SY_MOCK )); then
    # the handful of readings that never went through a command · a fixture
    # answering every subprocess and leaving these alone would still have put
    # this container's hostname and core count on the card
    SY[host]="${SY_SEED[host]:-moonbase}"
    SY[kernel]="${SY_SEED[kernel]:-24.5.0}"
    SY[arch]="${SY_SEED[arch]:-arm64}"
    sy_seed cpu_count 16; SY[ncpu]="${SD%.*}"; SY[nphys]="${SD%.*}"
  fi
  sy_identify
  # THE FIXTURE ARRIVES HAVING ALREADY BEEN RUNNING, and the previous tick
  # table is part of that.  Per-core percentages are a difference between two
  # readings, so a fresh run's first reading has nothing to subtract and every
  # core comes out zero -- which on a one-frame capture is the only reading
  # there will ever be.  Handing the sampler a table it has already seen makes
  # the first delta a real one.  The rates below it are the same argument: the
  # net and disk samplers have no previous counter to difference on their
  # first pass either, so what they publish is what is seeded here.
  if (( SY_MOCK )); then
    sy_mock_ticks
    SY_KU=("${SY_TU[@]}"); SY_KS=("${SY_TS[@]}")
    SY_KI=("${SY_TI[@]}"); SY_KN=("${SY_TN[@]}")
    SY_HAVE_PREV=1
    sy_seed cpu 38;        SY[cpu]=$SD
    sy_seed cpu_user 24;   SY[cpu_user]=$SD
    sy_seed cpu_sys 14;    SY[cpu_sys]=$SD
    sy_seed cpu_idle 62;   SY[cpu_idle]=$SD
    sy_seed net_rx 4.21;   SY[net_rx]=$SD
    sy_seed net_tx 0.38;   SY[net_tx]=$SD
    sy_seed io_r 12.4;     SY[io_r]=$SD
    sy_seed io_w 3.1;      SY[io_w]=$SD
    sy_seed nthread 2914;  SY[nthread]=${SD%.*}
    local -a lv; sy_seed_run load; lv=("${SDL[@]}")
    local -i li
    for (( li = 0; li < 3; li++ )); do SY[load.$li]=${lv[$li]:-0} ; done
    sy_seed up 533460;     SY[uptime]=${SD%.*}
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# EVERY CHARACTER THAT COMES FROM OUTSIDE GOES THROUGH HERE FIRST
# ══════════════════════════════════════════════════════════════════════════
# A PROCESS CAN BE CALLED ANYTHING and a volume can be named in Japanese, and
# either lands in a fixed-width column on a terminal that does not agree with
# this program about how many cells that takes.  system.py asks unicodedata
# for the character's category and its east-asian width; a shell has neither,
# so what it can ask is whether the byte is printable at all -- which catches
# the control characters and the DEL that would move the cursor, and leaves a
# wide glyph to be cut by the column it is drawn in.  Named here rather than
# quietly narrower somewhere else.
sy_safe() { SAFE="${1//[^[:print:]]/·}"; return 0 }

# ...AND A TRIM THAT TRIMS.  `${v## }` removes ONE space -- the pattern is a
# single space and `##` only asks for the longest match OF THAT PATTERN -- so
# every reading behind a column of alignment padding came back with the
# padding still on it and failed the digits test that follows.  `[[:space:]]#`
# would say it, and `#` is a repetition operator only under EXTENDED_GLOB,
# which this suite does not set and must not (terminal.command reads a conf
# with `${line%%#*}` in it).  So it is done the long way, twice.
sy_trim() {   # sy_trim TEXT -> TR
  local s="$1"
  s="${s#"${s%%[! 	]*}"}"
  s="${s%"${s##*[! 	]}"}"
  TR="$s"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# PER-CORE TICKS · the one reading a shell cannot take
# ══════════════════════════════════════════════════════════════════════════
# host_processor_info IS A MACH CALL, NOT A COMMAND.  `top -l 2` gives the
# aggregate -- user, system, idle -- and macOS publishes the per-core split
# nowhere a shell can reach without root.  Sixteen core bars are the
# PROCESSOR page's whole subject and the OVERVIEW's core strip besides, and
# this is where the first attempt to cut the monitor into zsh stopped rather
# than lose them.
#
# SO IT IS BORROWED, AND ONLY THIS.  A dozen lines of ctypes through whatever
# python3 is on the machine, exactly the shape terminal.command already uses
# to ask the window server for its refresh rate: asked once, and when it is
# not there the aggregate stands in and the core grid says so rather than
# drawing sixteen invented bars.  One optional reading out of a hundred and
# twenty is a price.  A page of plausible fiction is not.
SY_CORES_PY='
import ctypes, ctypes.util, sys
try:
    libc = ctypes.CDLL(ctypes.util.find_library("c") or "libc.dylib")
    libc.mach_host_self.restype = ctypes.c_uint
    libc.host_processor_info.restype = ctypes.c_int
    libc.host_processor_info.argtypes = [ctypes.c_uint, ctypes.c_int,
        ctypes.POINTER(ctypes.c_uint),
        ctypes.POINTER(ctypes.POINTER(ctypes.c_uint)),
        ctypes.POINTER(ctypes.c_uint)]
    n = ctypes.c_uint(0)
    info = ctypes.POINTER(ctypes.c_uint)()
    cnt = ctypes.c_uint(0)
    # PROCESSOR_CPU_LOAD_INFO = 2 · the states are USER SYSTEM IDLE NICE
    if libc.host_processor_info(libc.mach_host_self(), 2, ctypes.byref(n),
                                ctypes.byref(info), ctypes.byref(cnt)) == 0:
        # derive the stride rather than trust it: a wrong guess here is an
        # out-of-bounds read of unmapped memory, which is a signal and not an
        # exception, and would take the machine down without a word
        stride = (cnt.value // n.value) if n.value else 0
        if stride >= 4:
            for i in range(n.value):
                sys.stdout.write("%d %d %d %d\n" % (
                    info[i * stride], info[i * stride + 1],
                    info[i * stride + 2], info[i * stride + 3]))
except Exception:
    pass
'
SY_PY=''
SY_PY_TRIED=0
sy_python() {
  (( SY_PY_TRIED )) && { [[ -n "$SY_PY" ]]; return }
  SY_PY_TRIED=1
  local c
  for c in python3 /usr/bin/python3; do
    whence -p "$c" >/dev/null 2>&1 && { SY_PY="$c"; break }
  done
  [[ -n "$SY_PY" ]]
}
SY_TICK_OK=0
typeset -ga SY_TU SY_TS SY_TI SY_TN     # this reading's cumulative ticks
typeset -ga SY_KU SY_KS SY_KI SY_KN     # ...and the one before it
SY_HAVE_PREV=0
typeset -gi SY_MOCK_N=0

sy_ticks() {   # -> SY_TU/TS/TI/TN, cumulative per core · SY_TICK_OK says if
  SY_TICK_OK=0
  if (( SY_MOCK )); then sy_mock_ticks; return 0; fi
  (( SY_IS_MAC )) || return 0
  sy_python || return 0
  local out line
  local -a f
  out="$("$SY_PY" -c "$SY_CORES_PY" 2>/dev/null)" || return 0
  [[ -n "$out" ]] || return 0
  SY_TU=(); SY_TS=(); SY_TI=(); SY_TN=()
  for line in ${(f)out}; do
    f=(${=line}); (( ${#f[@]} >= 4 )) || continue
    SY_TU+=(${f[0]}); SY_TS+=(${f[1]}); SY_TI+=(${f[2]}); SY_TN+=(${f[3]})
  done
  (( ${#SY_TU[@]} )) && SY_TICK_OK=1
  return 0
}

# THE FIXTURE'S OWN TICK TABLE, and the order of its four numbers matters.
# host_processor_info hands back (user, system, IDLE, nice) and the arithmetic
# below subtracts the third from the third; a fixture that put its idle count
# in the fourth slot would report every core pinned at 100% -- a plausible
# number arrived at by adding idle time to busy time.  It ACCUMULATES rather
# than multiplying a counter, so the difference between two calls is exactly
# one second of that core's load, and nothing has to be right about the
# absolute totals for the percentages to be right.
typeset -ga SY_MU SY_MS SY_MI
sy_mock_ticks() {
  local -i i n
  local -F busy pct
  local -a pcts
  sy_seed_run cores; pcts=("${SDL[@]}")
  if (( ! ${#SY_MU[@]} )); then
    for (( i = 0; i < ${#pcts[@]}; i++ )); do SY_MU+=(0); SY_MS+=(0); SY_MI+=(0); done
  fi
  (( SY_MOCK_N++ )); n=$SY_MOCK_N
  SY_TU=(); SY_TS=(); SY_TI=(); SY_TN=()
  for (( i = 0; i < ${#pcts[@]}; i++ )); do
    pct=${pcts[$i]}
    # a hundred ticks a second, split by that core's own load, with a little
    # wander so that no two readings are identical
    busy=$(( pct + 6.0 * sin(n * 0.7 + i) ))
    (( busy < 0.0 )) && busy=0.0
    (( busy > 100.0 )) && busy=100.0
    SY_MU[$i]=$(( SY_MU[i] + int(busy * 0.62) ))
    SY_MS[$i]=$(( SY_MS[i] + int(busy * 0.38) ))
    SY_MI[$i]=$(( SY_MI[i] + int(100.0 - busy) ))
    SY_TU+=(${SY_MU[$i]}); SY_TS+=(${SY_MS[$i]})
    SY_TI+=(${SY_MI[$i]}); SY_TN+=(0)
  done
  SY_TICK_OK=1
  return 0
}

sy_sample_cpu() {
  sy_ticks
  (( SY_TICK_OK )) || return 0
  local -i i n=${#SY_TU[@]}
  # THE FIRST READING HAS NOTHING TO SUBTRACT.  A percentage here is a
  # difference between two tick tables, so a fresh run's first pass keeps the
  # table and reports nothing rather than reporting zero -- which on a
  # one-frame capture would be the only reading there ever was.
  if (( ! SY_HAVE_PREV || ${#SY_KU[@]} != n )); then
    SY_KU=("${SY_TU[@]}"); SY_KS=("${SY_TS[@]}")
    SY_KI=("${SY_TI[@]}"); SY_KN=("${SY_TN[@]}")
    SY_HAVE_PREV=1
    return 0
  fi
  local -F busy idle tot sum=0.0 du=0.0 ds=0.0 di=0.0 dn=0.0 whole c
  for (( i = 0; i < n; i++ )); do
    busy=$(( (SY_TU[i] - SY_KU[i]) + (SY_TS[i] - SY_KS[i]) + (SY_TN[i] - SY_KN[i]) ))
    idle=$(( SY_TI[i] - SY_KI[i] ))
    tot=$(( busy + idle ))
    du=$(( du + SY_TU[i] - SY_KU[i] )); ds=$(( ds + SY_TS[i] - SY_KS[i] ))
    di=$(( di + SY_TI[i] - SY_KI[i] )); dn=$(( dn + SY_TN[i] - SY_KN[i] ))
    c=0.0
    if (( tot > 0 )); then
      c=$(( 100.0 * busy / tot ))
      (( c < 0.0 )) && c=0.0
      (( c > 100.0 )) && c=100.0
    fi
    SY[cores.$i]=$c
    sum=$(( sum + c ))
  done
  SY_N_CORES=$n
  if (( n )); then
    SY[cpu]=$(( sum / n ))
    sy_tape SY_CPU_HIST 96 ${SY[cpu]}
  fi
  SY_KU=("${SY_TU[@]}"); SY_KS=("${SY_TS[@]}")
  SY_KI=("${SY_TI[@]}"); SY_KN=("${SY_TN[@]}")
  # where the time actually went, which is the question "50% busy" dodges
  whole=$(( du + ds + di + dn ))
  if (( whole > 0 )); then
    SY[cpu_user]=$(( 100.0 * du / whole )); SY[cpu_sys]=$(( 100.0 * ds / whole ))
    SY[cpu_idle]=$(( 100.0 * di / whole )); SY[cpu_nice]=$(( 100.0 * dn / whole ))
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# MEMORY · vm_stat and hw.memsize, and the counters differenced into rates
# ══════════════════════════════════════════════════════════════════════════
typeset -gA SY_VM SY_VM_PREV
SY_VM_AT=0.0
sy_swap() {   # sy_swap TEXT TAG -> SWG, one figure out of vm.swapusage, in GiB
  local t="$1" tag="$2" v u
  SWG=0
  [[ "$t" == *"$tag"* ]] || return 0
  v="${t#*$tag}"; v="${v#*=}"; sy_trim "$v"; v="$TR"
  u="${v//[0-9.]/}"; u="${u:0:1}"
  v="${v%%[^0-9.]*}"
  [[ -n "$v" ]] || return 0
  case "$u" in
    K) SWG=$(( v / 1048576.0 )) ;;
    M) SWG=$(( v / 1024.0 )) ;;
    G) SWG=$(( v + 0.0 )) ;;
  esac
  return 0
}
sy_sample_mem() {
  (( SY_IS_MAC )) || return 0
  local -F total psz g=1073741824.0 app used now span
  local line k v su pair
  sy_sysctl hw.memsize 0; total=${SCT:-0}
  sy_run vm_stat
  psz=4096
  if [[ "$ROUT" == *'page size of '* ]]; then
    v="${ROUT#*page size of }"; v="${v%% *}"
    [[ "$v" == <-> ]] && psz=$v
  fi
  SY_VM=()
  for line in ${(f)ROUT}; do
    [[ "$line" != *:* ]] && continue
    k="${line%%:*}"; v="${line#*:}"
    v="${v//[[:space:]]/}"; v="${v%.}"
    # vm_stat prints exactly one of its keys with literal quote marks around
    # it -- '"Translation faults"' -- so a plain lookup for the name missed,
    # and the fault rate read zero on every Mac there has ever been
    k="${k//\"/}"
    [[ "$v" == <-> ]] && SY_VM[$k]=$v
  done
  # WHAT COUNTS AS USED.  Not the active queue -- it holds file-cache pages
  # that happen to be in use and does NOT hold anonymous pages that have aged
  # into the inactive queue, so on a machine with a big file cache this read
  # high by five gigabytes and on one whose apps had gone quiet it read low by
  # six.  Activity Monitor's "Memory Used" is app memory + wired + compressed,
  # and app memory is the anonymous pages less the ones marked purgeable.
  # That is the figure the reader can check against, so that is the figure.
  app=$(( ${SY_VM[Anonymous pages]:-0} - ${SY_VM[Pages purgeable]:-0} ))
  (( app < 0 )) && app=0
  used=$(( (app + ${SY_VM[Pages wired down]:-0} + ${SY_VM[Pages occupied by compressor]:-0}) * psz ))
  if (( total <= 0 )); then total=$used; (( total <= 0 )) && total=1.0; fi
  SY[mem_total]=$(( total / g )); SY[mem_used]=$(( used / g ))
  SY[mem_wired]=$(( ${SY_VM[Pages wired down]:-0} * psz / g ))
  SY[mem_active]=$(( ${SY_VM[Pages active]:-0} * psz / g ))
  SY[mem_inactive]=$(( ${SY_VM[Pages inactive]:-0} * psz / g ))
  SY[mem_spec]=$(( ${SY_VM[Pages speculative]:-0} * psz / g ))
  SY[mem_free]=$(( ${SY_VM[Pages free]:-0} * psz / g ))
  SY[mem_purge]=$(( ${SY_VM[Pages purgeable]:-0} * psz / g ))
  SY[mem_app]=$(( app * psz / g ))
  # NOT a peer of the queues above it: the file-backed pages are the part of
  # active + inactive + speculative that came off a disk.  Listed as a seventh
  # slice of total memory it made the breakdown add up to half as much again
  # as the machine has.
  SY[mem_file]=$(( ${SY_VM[File-backed pages]:-0} * psz / g ))
  SY[mem_compressed]=$(( ${SY_VM[Pages occupied by compressor]:-0} * psz / g ))
  # and the counters, differenced into rates per second
  now=$EPOCHREALTIME
  if (( SY_VM_AT > 0.0 && now - SY_VM_AT > 0.2 )); then
    span=$(( now - SY_VM_AT ))
    for pair in 'pageins:Pageins' 'pageouts:Pageouts' 'swapins:Swapins' \
                'swapouts:Swapouts' 'faults:Translation faults' \
                'cows:Pages copy-on-write' 'compressions:Compressions' \
                'decompressions:Decompressions'; do
      v="${pair%%:*}"; k="${pair#*:}"
      SY[$v]=$(( (${SY_VM[$k]:-0} - ${SY_VM_PREV[$k]:-0}) / span ))
      (( ${SY[$v]} < 0.0 )) && SY[$v]=0.0
    done
  fi
  for k in Pageins Pageouts Swapins Swapouts 'Translation faults' \
           'Pages copy-on-write' Compressions Decompressions; do
    SY_VM_PREV[$k]=${SY_VM[$k]:-0}
  done
  SY_VM_AT=$now
  sy_sysctl kern.memorystatus_vm_pressure_level 1
  if [[ "$SCT" == <-> ]]; then SY[mem_press]=$SCT; else SY[mem_press]=1; fi
  sy_run sysctl -n vm.swapusage; su="$ROUT"
  sy_swap "$su" total; SY[swap_total]=$SWG
  sy_swap "$su" used;  SY[swap_used]=$SWG
  SY[mem_pct]=$(( 100.0 * ${SY[mem_used]} / (${SY[mem_total]} > 0.001 ? ${SY[mem_total]} : 0.001) ))
  sy_tape SY_MEM_HIST 96 ${SY[mem_pct]}
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# STORAGE · every volume with a real device behind it, largest first
# ══════════════════════════════════════════════════════════════════════════
sy_sample_vols() {
  local line mount dev name f0 key
  local -F total used avail
  local -a f rows
  local -i i j n
  if (( SY_IS_MAC )); then sy_run df -kl; else sy_run df -k; fi
  rows=()
  n=0
  for line in ${(f)ROUT}; do
    (( n++ )); (( n == 1 )) && continue          # the header
    f=(${=line})
    (( ${#f[@]} >= 9 )) || continue
    [[ "${f[0]}" == /dev/* ]] || continue
    # the mount point is the ninth field and everything after it: a volume
    # called "Macintosh HD 2" is one mount with two spaces in it
    mount="${f[8]}"
    for (( j = 9; j < ${#f[@]}; j++ )); do mount+=" ${f[$j]}"; done
    # EVERY VOLUME IN AN APFS CONTAINER REPORTS THE CONTAINER'S SIZE, so "/"
    # (the sealed system snapshot) and "/System/Volumes/Data" both claim the
    # whole disk -- listing both made a 1 TB Mac look like it had two.
    case "$mount" in
      /System/Volumes/VM*|/System/Volumes/Preboot*|/System/Volumes/xarts*|\
      /System/Volumes/iSCPreboot*|/System/Volumes/Hardware*|/System/Volumes/Update*)
        continue ;;
    esac
    total=$(( ${f[1]} / 1048576.0 ))
    used=$(( ${f[2]} / 1048576.0 ))
    # AVAIL IS NOT total - used ON APFS.  The reserve and the purgeable pool
    # sit between them, so the subtraction overstates what a reader can
    # actually write by ten gigabytes and more.  df's own column is the figure
    # Finder shows, so it is carried rather than recomputed.
    avail=$(( ${f[3]} / 1048576.0 ))
    (( total < 0.05 )) && continue
    sy_safe "$mount"; mount="$SAFE"
    f0="${f[0]##*/}"; sy_safe "$f0"; dev="$SAFE"
    name="${mount##*/}"; [[ -n "$name" ]] || name="$mount"
    # sortable, largest first, and the row carried whole beside its key
    printf -v key '%018.4f' $(( 1000000.0 - total ))
    rows+=("$key"$'\t'"$dev"$'\t'"$mount"$'\t'"$used"$'\t'"$total"$'\t'"$avail"$'\t'"$name")
  done
  # ...so when both are present, keep the DATA volume: it is the one with the
  # reader's files on it, and the one every other storage figure here is
  # measured from.
  # ${(flags)NAME} ON A BARE ARRAY NAME IS ELEMENT ZERO under KSH_ARRAYS,
  # not the array -- the same trap the frame ladder and the glyph ruler both
  # fell into in terminal.command.  The subscript is what makes it the whole
  # of it, and without it this sort returned a one-volume machine.
  if [[ "${(j:|:)rows[@]}" == *$'\t'/System/Volumes/Data$'\t'* ]]; then
    local -a keep; keep=()
    for line in "${rows[@]}"; do
      [[ "$line" == *$'\t'/$'\t'* ]] && continue
      keep+=("$line")
    done
    rows=("${keep[@]}")
  fi
  rows=("${(@n)rows[@]}")
  SY_N_VOLS=0
  for (( i = 0; i < ${#rows[@]} && i < 8; i++ )); do
    f=("${(@s:	:)rows[$i]}")
    SY[vols.$i.dev]="${f[1]}";  SY[vols.$i.mount]="${f[2]}"
    SY[vols.$i.used]="${f[3]}"; SY[vols.$i.total]="${f[4]}"
    SY[vols.$i.avail]="${f[5]}"; SY[vols.$i.name]="${f[6]}"
    (( SY_N_VOLS++ ))
  done
  # the biggest volume is not the boot volume; an external drive can be
  # larger than the internal one
  if (( SY_N_VOLS )); then
    SY[boot_disk]="${SY[vols.0.dev]}"
    for (( i = 0; i < SY_N_VOLS; i++ )); do
      if [[ "${SY[vols.$i.mount]}" == (/System/Volumes/Data|/) ]]; then
        SY[boot_disk]="${SY[vols.$i.dev]}"; break
      fi
    done
  fi
  return 0
}

sy_sample_disk() {
  # THE ONE STORAGE FIGURE THE OVERVIEW SHOWS, from the volume the reader's
  # files are on.  It used to come from statvfs and the volume list from df,
  # and two sources for one number is one source too many: the STORAGE page
  # printed the data volume at 589G and, in the panel beside it, the boot
  # volume at 575G -- the same volume, twice, fourteen gigabytes apart, on one
  # screen.  df's data row is the number Finder shows.
  sy_sample_vols
  local -i i pick=-1
  for (( i = 0; i < SY_N_VOLS; i++ )); do
    [[ "${SY[vols.$i.mount]}" == /System/Volumes/Data ]] && { pick=$i; break }
  done
  if (( pick < 0 )); then
    for (( i = 0; i < SY_N_VOLS; i++ )); do
      [[ "${SY[vols.$i.mount]}" == / ]] && { pick=$i; break }
    done
  fi
  (( pick < 0 )) && return 0
  SY[disk_total]="${SY[vols.$pick.total]}"
  SY[disk_used]="${SY[vols.$pick.used]}"
  SY[disk_free]="${SY[vols.$pick.avail]}"
  SY[disk_mount]="${SY[vols.$pick.mount]}"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# SOCKETS · how many this machine is holding open, by state
# ══════════════════════════════════════════════════════════════════════════
sy_sample_conn() {
  local line
  local -i est=0 lis=0 wait=0
  sy_run netstat -an -p tcp
  for line in ${(f)ROUT}; do
    line="${line%%[[:space:]]#}"
    case "$line" in
      *ESTABLISHED) (( est++ )) ;;
      *LISTEN)      (( lis++ )) ;;
      # everything neither settled nor listening.  Six states were counted
      # and four silently dropped, so the total printed under "open sockets"
      # was short.
      *TIME_WAIT|*CLOSE_WAIT|*CLOSING|*FIN_WAIT_1|*FIN_WAIT_2|*LAST_ACK|\
      *SYN_SENT|*SYN_RCVD|*CLOSED) (( wait++ )) ;;
    esac
  done
  SY[conn_est]=$est; SY[conn_listen]=$lis; SY[conn_wait]=$wait
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# INTERFACES · every one that has carried a byte, with its address
# ══════════════════════════════════════════════════════════════════════════
# NOTHING HERE COUNTS FROM THE LEFT.  netstat's Address column is EMPTY on
# some rows, which shifts every field after it -- so the header says how many
# counter columns there are, those come off the RIGHT by name, and whatever
# is left at the front is Name / Mtu / Network / Address, with Address simply
# absent when there is none.
sy_is_mac_addr() {   # five colons and hex either side of each · not an IPv6
  [[ "$1" == [0-9a-fA-F]##:* ]] 2>/dev/null
  local -a p; p=("${(@s/:/)1}")
  (( ${#p[@]} == 6 )) || return 1
  local x
  for x in "${p[@]}"; do
    [[ -n "$x" && ${#x} -le 2 && "$x" != *[^0-9a-fA-F]* ]] || return 1
  done
  return 0
}
sy_sample_ifaces() {
  local line nm addr name key kk
  local -a f head names front cnt rows
  local -i ncnt i j n=0 ii ie ib oi oe ob
  typeset -A rx tx rp tp ier oer mac ip seen
  sy_run netstat -ibn
  for line in ${(f)ROUT}; do
    (( n++ ))
    f=(${=line})
    if (( n == 1 )); then
      head=("${f[@]}")
      ncnt=$(( ${#head[@]} - 4 )); (( ncnt < 6 )) && ncnt=6
      names=("${(@)head[$(( ${#head[@]} - ncnt )),-1]}")
      ii=-1; ie=-1; ib=-1; oi=-1; oe=-1; ob=-1
      for (( i = 0; i < ${#names[@]}; i++ )); do
        case "${names[$i]}" in
          Ipkts) ii=$i ;; Ierrs) ie=$i ;; Ibytes) ib=$i ;;
          Opkts) oi=$i ;; Oerrs) oe=$i ;; Obytes) ob=$i ;;
        esac
      done
      (( ii >= 0 && ie >= 0 && ib >= 0 && oi >= 0 && oe >= 0 && ob >= 0 )) || return 0
      continue
    fi
    (( ${#f[@]} >= ncnt + 3 )) || continue
    cnt=("${(@)f[$(( ${#f[@]} - ncnt )),-1]}")
    front=("${(@)f[0,$(( ${#f[@]} - ncnt - 1 ))]}")
    nm="${front[0]%\*}"; sy_safe "$nm"; name="$SAFE"
    # ...EXCEPT WHICHEVER ONE THE DEFAULT ROUTE IS ON.  Join a vpn and that
    # IS a utun, so skipping them all emptied the page -- "0 interfaces
    # carrying traffic" mid-transfer.
    if [[ "$name" != "${SY[net_if]}" ]]; then
      case "$name" in lo*|gif*|stf*|awdl*|llw*|utun*|anpi*) continue ;; esac
    fi
    addr=''; (( ${#front[@]} > 3 )) && addr="${front[3]}"
    if [[ -z "${seen[$name]:-}" ]]; then
      seen[$name]=1; mac[$name]=''; ip[$name]=''
      rx[$name]=0; tx[$name]=0; rp[$name]=0; tp[$name]=0
      ier[$name]=0; oer[$name]=0
      rows+=("$name")
    fi
    # fe80::1c9f:5aff:fe1a:2b3c has exactly five colons, the same as a
    # hardware address -- and netstat prints it AFTER the link row, so a
    # loose test overwrote the real MAC on every machine
    if [[ -n "$addr" ]] && sy_is_mac_addr "$addr" && [[ -z "${mac[$name]}" ]]; then
      mac[$name]="$addr"
    elif [[ -n "$addr" && "${#${addr//[^.]/}}" == 3 && -z "${ip[$name]}" ]]; then
      ip[$name]="$addr"
    fi
    for kk in "rp:$ii" "ier:$ie" "rx:$ib" "tp:$oi" "oer:$oe" "tx:$ob"; do
      j=${kk#*:}; nm="${kk%%:*}"
      addr="${cnt[$j]}"
      [[ "$addr" == <-> ]] || addr=0
      eval "(( ${nm}[\$name] < addr )) && ${nm}[\$name]=\$addr"
    done
  done
  # only the ones that have actually carried something, busiest first
  local -a live
  for name in "${rows[@]}"; do
    (( rx[$name] || tx[$name] )) || continue
    printf -v key '%018d' $(( 999999999999999 - (rx[$name] + tx[$name]) / 1000 ))
    live+=("$key"$'\t'"$name")
  done
  live=("${(@n)live[@]}")
  SY_N_IFACES=0
  for (( i = 0; i < ${#live[@]} && i < 6; i++ )); do
    name="${live[$i]#*$'\t'}"
    if [[ -z "${ip[$name]}" ]]; then
      sy_run ipconfig getifaddr "$name"
      sy_trim "${ROUT%%$'\n'*}"; sy_safe "$TR"; ip[$name]="$SAFE"
    fi
    SY[ifaces.$i.name]="$name"; SY[ifaces.$i.mac]="${mac[$name]}"
    SY[ifaces.$i.ip]="${ip[$name]}"
    SY[ifaces.$i.rxb]="${rx[$name]}"; SY[ifaces.$i.txb]="${tx[$name]}"
    SY[ifaces.$i.rxp]="${rp[$name]}"; SY[ifaces.$i.txp]="${tp[$name]}"
    SY[ifaces.$i.ierr]="${ier[$name]}"; SY[ifaces.$i.oerr]="${oer[$name]}"
    (( SY_N_IFACES++ ))
  done
  for (( i = 0; i < SY_N_IFACES; i++ )); do
    [[ "${SY[ifaces.$i.name]}" == "${SY[net_if]}" ]] || continue
    SY[net_ip]="${SY[ifaces.$i.ip]}"; SY[net_mac]="${SY[ifaces.$i.mac]}"
    SY[net_rxtot]=$(( ${SY[ifaces.$i.rxb]} / 1073741824.0 ))
    SY[net_txtot]=$(( ${SY[ifaces.$i.txb]} / 1073741824.0 ))
    SY[net_ipkt]="${SY[ifaces.$i.rxp]}"; SY[net_opkt]="${SY[ifaces.$i.txp]}"
    break
  done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THROUGHPUT · the network and the disk, differenced into rates
# ══════════════════════════════════════════════════════════════════════════
SY_NET_R=0; SY_NET_T=0; SY_NET_HAVE=0; SY_NET_IF_WAS=''
SY_ROUTE_AT=-99.0
sy_sample_net() {   # sy_sample_net DT
  local -F dt=$1
  local line v
  local -a f hdr nums
  local -i rx=0 tx=0 ierr=0 oerr=0 i ii=-1 ie=-1 oi=-1 oe=-1
  if (( SY_IS_MAC )); then
    # CHOSEN ONCE AND NEVER REVISITED, this pinned the whole network page to
    # a dead interface the moment anyone docked, undocked, joined a vpn or
    # moved from wi-fi to ethernet.  Re-ask now and then, and on failure
    # leave it EMPTY so it gets asked again -- falling back to a hard-coded
    # "en0" made the retry impossible.
    if [[ -z "${SY[net_if]}" ]] || (( EPOCHREALTIME - SY_ROUTE_AT > 30.0 )); then
      SY_ROUTE_AT=$EPOCHREALTIME
      sy_run route -n get default
      if [[ "$ROUT" == *interface:* ]]; then
        v="${ROUT#*interface:}"; sy_trim "${v%%$'\n'*}"
        v="${TR%%[^A-Za-z0-9_.-]*}"
        [[ -n "$v" ]] && SY[net_if]="${v[0,16]}"
      fi
    fi
    [[ -n "${SY[net_if]}" ]] || return 0    # no default route: ask again next
    sy_run netstat -ibn -I "${SY[net_if]}"
    [[ -n "$ROUT" ]] || sy_run netstat -ibn
    local -i n=0
    for line in ${(f)ROUT}; do
      (( n++ ))
      f=(${=line})
      if (( n == 1 )); then
        hdr=("${f[@]}")
        for (( i = 0; i < ${#hdr[@]}; i++ )); do
          case "${hdr[$i]}" in
            Ibytes) ii=$i ;; Ierrs) ie=$i ;; Obytes) oi=$i ;; Oerrs) oe=$i ;;
          esac
        done
        continue
      fi
      (( ${#f[@]} >= 4 )) || continue
      [[ "${f[0]%\*}" == "${SY[net_if]}" ]] || continue
      [[ "${f[2]}" == '<Link'* ]] || continue
      if (( ii >= 0 )) && (( ${#f[@]} == ${#hdr[@]} )); then
        if [[ "${f[$ii]}" == <-> && "${f[$oi]}" == <-> ]]; then
          rx=${f[$ii]}; tx=${f[$oi]}
          [[ "${f[$ie]}" == <-> ]] && ierr=${f[$ie]}
          [[ "${f[$oe]}" == <-> ]] && oerr=${f[$oe]}
          break
        fi
      fi
      # an interface with no Address column shifts everything, so fall back
      # to counting the trailing numbers instead
      nums=()
      for v in "${f[@]}"; do [[ "$v" == (-|)<-> ]] && nums+=($v); done
      if (( ${#nums[@]} >= 7 )); then
        n=${#nums[@]}
        ierr=${nums[$(( n - 6 ))]}; rx=${nums[$(( n - 5 ))]}
        oerr=${nums[$(( n - 3 ))]}; tx=${nums[$(( n - 2 ))]}
      fi
      break
    done
  fi
  # error counts came from the same read: publishing zeros for them reads as
  # "no errors", which is a different claim from "no reading"
  (( rx || tx )) && { SY[net_ierr]=$ierr; SY[net_oerr]=$oerr }
  # A FAILED READ PARSES AS ZERO.  Store that as the baseline and the next
  # reading differences bytes-since-boot against nothing, inventing a
  # multi-terabyte spike that then flattens the tape for five minutes.  No
  # reading is better than a fictional one.  ...and the counters belong to an
  # INTERFACE: dock, undock or join a vpn and the route moves, and
  # differencing the new link's total against the old link's invents the same
  # spike a failed read does.
  local -i have=$SY_NET_HAVE
  [[ "${SY[net_if]}" == "$SY_NET_IF_WAS" ]] || have=0
  SY_NET_IF_WAS="${SY[net_if]}"
  local -i pr=$SY_NET_R pt=$SY_NET_T
  if (( rx || tx )); then SY_NET_R=$rx; SY_NET_T=$tx; SY_NET_HAVE=1
  else SY_NET_HAVE=0; fi
  if (( have && dt > 0 && rx >= pr && tx >= pt )); then
    # 1e6, NOT 1048576.  Apple counts a megabyte as a million bytes in
    # Activity Monitor and the Finder, and this used to read 9.54 where that
    # reads 10.00 -- a permanent five per cent undercount against the very
    # tool the reader will check it against.
    SY[net_rx]=$(( (rx - pr) / dt / 1000000.0 ))
    SY[net_tx]=$(( (tx - pt) / dt / 1000000.0 ))
    # THE TAPE IS A RECORD OF MEASUREMENTS.  Appending the last one again
    # because this one failed puts a reading on it that nobody took.
    sy_tape SY_RX_HIST 32 ${SY[net_rx]}
    sy_tape SY_TX_HIST 32 ${SY[net_tx]}
  fi
  return 0
}

# EVERY OCCURRENCE, ADDED UP.  These counters are per block device and the
# registry prints one block per device, so the figure is a sum and not a
# lookup -- and the loop that walks them has a guard on it, because a strip
# pattern that cannot shrink the string is not a slow loop, it is an endless
# one.  (It was: the quoting made the pattern unmatchable and the reading
# never returned.)
sy_ioreg_sum() {   # sy_ioreg_sum TEXT NAME -> IOS the total, IOC how many
  local t="$1" nm="\"$2\"" v
  local -i guard=0
  IOS=0; IOC=0
  while [[ "$t" == *"$nm"* ]]; do
    (( ++guard > 4096 )) && break
    t="${t#*"$nm"}"
    v="${t#*=}"; v="${v%%[^0-9]*}"
    [[ "$v" == <-> ]] && (( IOS += v ))
    (( IOC++ ))
  done
  return 0
}

SY_IO_R=0; SY_IO_W=0; SY_IO_RO=0; SY_IO_WO=0; SY_IO_HAVE=0; SY_DISKS_WAS=-1
sy_sample_io() {   # sy_sample_io DT
  local -F dt=$1
  local -i r=0 w=0 ro=0 wo=0
  if (( SY_IS_MAC )); then
    sy_run ioreg -r -c IOBlockStorageDriver -w0
    sy_ioreg_sum "$ROUT" 'Bytes (Read)';       r=$IOS
    sy_ioreg_sum "$ROUT" 'Bytes (Write)';      w=$IOS
    sy_ioreg_sum "$ROUT" 'Operations (Read)';  ro=$IOS
    sy_ioreg_sum "$ROUT" 'Operations (Write)'; wo=$IOS
    sy_ioreg_sum "$ROUT" 'Statistics'
    [[ -n "$ROUT" ]] && SY[disks]=$IOC
  fi
  # ...and the lifetime totals come from the SAME read, so they were being
  # published as zeros whenever it failed -- which the glide then animated,
  # counting the machine's whole disk history down to nothing over a second
  # and a half and back up again.
  (( r || w )) && { SY[io_rtot]=$(( r / 1073741824.0 ))
                    SY[io_wtot]=$(( w / 1073741824.0 )) }
  local -i have=$SY_IO_HAVE
  # these counters are summed over every block device, so plugging one in
  # makes the total jump by that drive's whole lifetime.  A changed device
  # count means the sum is not comparable with the last one.
  (( SY_DISKS_WAS >= 0 && SY[disks] != SY_DISKS_WAS )) && have=0
  SY_DISKS_WAS=${SY[disks]}
  local -i pr=$SY_IO_R pw=$SY_IO_W pro=$SY_IO_RO pwo=$SY_IO_WO
  if (( r || w )); then
    SY_IO_R=$r; SY_IO_W=$w; SY_IO_RO=$ro; SY_IO_WO=$wo; SY_IO_HAVE=1
  else SY_IO_HAVE=0; fi
  if (( have && dt > 0 && r >= pr && w >= pw )); then
    SY[io_r]=$(( (r - pr) / dt / 1000000.0 ))    # decimal, as above
    SY[io_w]=$(( (w - pw) / dt / 1000000.0 ))
    if (( ro >= pro && wo >= pwo )); then
      SY[io_rops]=$(( (ro - pro) / dt )); SY[io_wops]=$(( (wo - pwo) / dt ))
    fi
    sy_tape SY_IO_HIST 32 $(( ${SY[io_r]} + ${SY[io_w]} ))
    sy_tape SY_IOW_HIST 32 ${SY[io_w]}
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# PROCESSES · every one of them, sorted by what it is costing
# ══════════════════════════════════════════════════════════════════════════
sy_sample_procs() {
  # `exe` AND NOT `path`: zsh's `path` is the array tied to $PATH, and a
  # local of that name keeps enough of the binding to make `${path[a,b]}`
  # slice the search path instead of the string.
  local line exe cmd key
  local -a f rows g
  local -i i n=0
  sy_run ps -Ao 'pid=,user=,pcpu=,pmem=,rss=,state=,time=,comm='
  for line in ${(f)ROUT}; do
    f=(${=line})
    (( ${#f[@]} >= 8 )) || continue
    [[ "${f[0]}" == <-> && "${f[4]}" == <-> ]] || continue
    # comm is the eighth field AND EVERYTHING AFTER IT: a path with a space
    # in it is one path, not two columns
    exe="${f[7]}"
    for (( i = 8; i < ${#f[@]}; i++ )); do exe+=" ${f[$i]}"; done
    sy_trim "$exe"; exe="$TR"
    cmd="${exe##*/}"; [[ -n "$cmd" ]] || cmd='?'
    # THE KEY SORTS AND THE ROW RIDES ALONG.  system.py sorts by -cpu with
    # python's stable sort, so equal loads keep the order ps gave them; a key
    # of (1000 - cpu) padded to a fixed width, then the original index, is
    # the same order out of a plain ascending sort.
    printf -v key '%011.4f %06d' $(( 1000.0 - ${f[2]} )) $n
    rows+=("$key"$'\t'"$line"$'\t'"$exe"$'\t'"$cmd")
    (( n++ ))
  done
  (( n )) || return 0
  rows=("${(@n)rows[@]}")
  SY[nproc]=$n
  SY_N_PROCS=0
  for (( i = 0; i < ${#rows[@]} && i < 512; i++ )); do
    g=("${(@s:	:)rows[$i]}")
    f=(${=g[1]})
    exe="${g[2]}"; cmd="${g[3]}"
    sy_safe "${f[1]}"; SY[procs.$i.user]="${SAFE[0,9]}"
    SY[procs.$i.pid]="${f[0]}"
    SY[procs.$i.cpu]="${f[2]}"; SY[procs.$i.mem]="${f[3]}"
    SY[procs.$i.rss]="${f[4]}"; SY[procs.$i.state]="${f[5][0,0]}"
    SY[procs.$i.time]="${f[6][0,9]}"
    sy_safe "$cmd"; SY[procs.$i.cmd]="${SAFE[0,21]}"
    sy_safe "$exe"; SY[procs.$i.path]="$SAFE"
    (( SY_N_PROCS++ ))
  done
  # ONE READING, ONE SERIAL, AND IT GOES BEFORE THE RETURN.  It sat after it
  # for one revision, which is a counter that never counts: the scope read
  # the same serial every frame, decided the rows had not changed, and never
  # moved a contact.
  (( SY_SERIAL++ ))
  return 0
}

sy_sample_threads() {
  local v
  if (( SY_IS_MAC )); then
    sy_run top -l 1 -n 0
    if [[ "$ROUT" == *threads* ]]; then
      v="${ROUT%%threads*}"; v="${v##*[!0-9]}"
      [[ "$v" == <-> ]] && SY[nthread]=$v
    fi
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE CELL · the cheap half on the ten-second clock, the dear half slower
# ══════════════════════════════════════════════════════════════════════════
sy_ioreg_num() {   # sy_ioreg_num TEXT NAME... -> ION, the first one that answers
  local t="$1" nm v
  shift
  ION=0
  for nm in "$@"; do
    [[ "$t" == *"\"$nm\""* ]] || continue
    v="${t#*\"$nm\"}"; v="${v#*=}"; sy_trim "$v"; v="$TR"
    if [[ "$v" == -* ]]; then v="-${${v#-}%%[^0-9]*}"; else v="${v%%[^0-9]*}"; fi
    [[ "$v" == (-|)<-> ]] || continue
    # TWO'S COMPLEMENT, ARRIVING AS A TWENTY-DIGIT POSITIVE.  The registry
    # reports a current flowing OUT of the cell as a negative number and
    # reports it UNSIGNED: -1510 mA comes back as 18446744073709550106.  That
    # does not fit a shell integer, so zsh says `number truncated after 19
    # digits` ON STDERR -- which, on an alternate screen, is a line of text
    # shoved through the middle of the picture and every row below it pushed
    # down one.  A discharging Mac was enough to do it; a charging one never
    # was, which is why it was not seen until a battery ran down.
    #
    # THE WRAP IS UNDONE WITHOUT EVER FORMING THE BIG NUMBER.  Taking 2^64
    # off in the last twelve digits is exact for any reading small enough to
    # be real, and twelve digits is a number a shell can hold.
    if (( ${#v} >= 20 )); then
      ION=$(( 10#${v[-12,-1]} - 73709551616 ))
    else
      ION=$v
    fi
    return 0
  done
  return 0
}

sy_sample_batt() {
  # THE CHEAP HALF: one pmset call, twenty milliseconds.  This is where the
  # charge, the state and whether the lead is in come from -- the coin door's
  # read-out and the overview's anomaly watch.  It was behind the same thirty
  # second clock as the registry walks below, which meant plugging the charger
  # in could take half a minute to show.
  (( SY_IS_MAC )) || return 0
  local out io v st
  local -i mv amps raw h m
  sy_run pmset -g batt; out="$ROUT"
  if [[ "$out" == *%\;* ]]; then
    v="${out%%\%\;*}"; v="${v##*[!0-9]}"
    st="${out#*%; }"; st="${st%%;*}"; sy_trim "$st"; st="$TR"
    [[ "$v" == <-> ]] && { SY[batt_pct]=$v; SY[batt_state]="$st" }
  elif [[ "$out" == *'AC Power'* ]]; then
    SY[batt_state]='ac power'
  fi
  [[ -n "$out" ]] && { [[ "$out" == *'AC Power'* ]] && SY[ac]=1 || SY[ac]=0 }
  SY[batt_mins]=-1
  if [[ "$out" == *remaining* ]]; then
    v="${out%% remaining*}"; v="${v##*[!0-9:]}"
    if [[ "$v" == <->:<-> ]]; then
      h=${v%%:*}; m=${v##*:}; SY[batt_mins]=$(( h * 60 + m ))
    fi
  fi
  # The cell's own registry entry is fifty milliseconds and it carries the
  # three numbers that change the instant the lead goes in: amperage, voltage,
  # temperature.  Leaving them on the slow clock put "discharging, 1500 mA out
  # of the battery" on the same screen as "charging, wall power connected" for
  # half a minute at a time.
  sy_run ioreg -rn AppleSmartBattery -w0; io="$ROUT"
  sy_ioreg_num "$io" Voltage; mv=$ION
  sy_ioreg_num "$io" InstantAmperage Amperage; amps=$ION
  if (( mv )); then
    SY[batt_volt]=$(( mv / 1000.0 ))
    SY[batt_amp]=$(( amps / 1000.0 ))
    (( amps > 0 )) && SY[batt_charging]=1 || SY[batt_charging]=0
    SY[watts]=$(( abs(mv / 1000.0 * amps / 1000.0) ))
  fi
  sy_ioreg_num "$io" Temperature; raw=$ION
  # centi-Celsius.  Read as deci-Kelvin it agrees at 30.35 C, which is roughly
  # where a battery sits on a desk -- so the wrong one looks right until the
  # machine warms up and then reads 127 C.
  if (( raw )); then
    if (( raw >= 500 && raw <= 9000 )); then SY[temp]=$(( raw / 100.0 ))
    else SY[temp]=null; fi
  fi
  return 0
}

sy_sample_batt_deep() {
  # AND THE DEAR HALF: the registry sweep for paired devices, plus the two
  # pmset calls, for things that change on a scale of minutes.
  (( SY_IS_MAC )) || return 0
  local io hid blk v nm out
  local -a blocks
  local -i i lim pct
  local -F hpct
  sy_run ioreg -rn AppleSmartBattery -w0; io="$ROUT"
  sy_ioreg_num "$io" CycleCount;                     SY[batt_cycles]=$ION
  sy_ioreg_num "$io" DesignCycleCount9C DesignCycleCount
  (( ION )) && SY[batt_cyc_max]=$ION || SY[batt_cyc_max]=1000
  sy_ioreg_num "$io" DesignCapacity;                 SY[batt_design]=$ION
  # On Apple silicon AppleSmartBattery stopped publishing AppleRawMaxCapacity,
  # and "MaxCapacity" there is a PERCENTAGE -- the literal number 100 -- while
  # the mAh figure moved to NominalChargeCapacity.  Reading them in the old
  # order told every Apple silicon laptop its battery held 100 of its designed
  # 4000 mAh: two per cent, in red, "service recommended".
  sy_ioreg_num "$io" AppleRawMaxCapacity NominalChargeCapacity MaxCapacity
  SY[batt_max]=$ION
  (( SY[batt_design] > 1000 && SY[batt_max] > 0 && SY[batt_max] <= 100 )) \
    && SY[batt_max]=0            # that was a percentage, not a charge
  sy_ioreg_num "$io" AppleRawCurrentCapacity CurrentCapacity
  SY[batt_now]=$ION
  # CurrentCapacity is a percentage on Apple silicon too -- the same trap
  # AppleRawMaxCapacity springs above, and it would print a 4381 mAh cell as
  # holding 78.
  (( SY[batt_design] > 1000 && SY[batt_now] > 0 && SY[batt_now] <= 100 )) \
    && SY[batt_now]=0
  sy_ioreg_num "$io" Voltage; SY[batt_volt]=$(( ION / 1000.0 ))
  SY[batt_health]=''
  for nm in BatteryHealth PermanentFailureStatus; do
    [[ "$io" == *"\"$nm\""* ]] || continue
    v="${io#*\"$nm\"}"; v="${v#*=}"; sy_trim "$v"; v="$TR"
    v="${v#\"}"; v="${v%%\"*}"; v="${v%%$'\n'*}"; sy_trim "$v"
    [[ -n "$TR" ]] && { SY[batt_health]="$TR"; break }
  done
  if [[ -z "${SY[batt_health]}" ]] && (( SY[batt_design] && SY[batt_max] )); then
    hpct=$(( 100.0 * ${SY[batt_max]} / ${SY[batt_design]} ))
    (( hpct >= 80 )) && SY[batt_health]='normal' \
                     || SY[batt_health]='service recommended'
  fi
  # low power mode is a thing the machine is DOING, so it gets said
  sy_run pmset -g
  SY[lowpower]=0
  if [[ "$ROUT" == *lowpowermode* ]]; then
    v="${ROUT#*lowpowermode}"; sy_trim "$v"; v="${TR%%[^0-9]*}"
    [[ "$v" == 1 ]] && SY[lowpower]=1
  fi
  # anything paired that reports its own charge -- mouse, keyboard, buds
  sy_run ioreg -r -k BatteryPercent -l -w0; hid="$ROUT"
  blocks=("${(@ps:+-o :)hid}")
  SY_N_DEVICES=0
  typeset -A dseen
  for (( i = 1; i < ${#blocks[@]}; i++ )); do
    blk="${blocks[$i]}"
    [[ "$blk" == *'"BatteryPercent"'* ]] || continue
    v="${blk#*\"BatteryPercent\"}"; v="${v#*=}"; sy_trim "$v"; v="${TR%%[^0-9]*}"
    [[ "$v" == <-> ]] || continue
    pct=$v
    nm=''
    for out in Product DeviceName; do
      [[ "$blk" == *"\"$out\""* ]] || continue
      nm="${blk#*\"$out\"}"; nm="${nm#*=}"; sy_trim "$nm"; nm="${TR#\"}"
      nm="${nm%%\"*}"; break
    done
    [[ -n "$nm" ]] || nm="${blk%% *}"
    sy_safe "$nm"; nm="${SAFE[0,23]}"
    [[ -n "${dseen[$nm]:-}" ]] && continue
    dseen[$nm]=1
    (( SY_N_DEVICES >= 5 )) && continue
    SY[devices.$SY_N_DEVICES.name]="$nm"
    SY[devices.$SY_N_DEVICES.pct]=$pct
    (( SY_N_DEVICES++ ))
  done
  sy_run pmset -g therm
  if [[ "$ROUT" == *CPU_Speed_Limit* ]]; then
    v="${ROUT#*CPU_Speed_Limit}"; v="${v#*=}"; sy_trim "$v"; v="${TR%%[^0-9]*}"
    if [[ "$v" == <-> ]]; then
      lim=$v
      (( lim >= 100 )) && SY[therm]='nominal' \
                       || SY[therm]="throttled to ${lim}%"
    fi
  fi
  # (voltage, amperage and temperature are read in sy_sample_batt, on the ten
  # second clock, because they change the instant the lead goes in)
  return 0
}

sy_uptime() {
  # ON THE FIXTURE, BOTH NUMBERS ARE FACTS OF THE INVENTED MACHINE.  boot is
  # an instant and uptime is a duration, and deriving either from the other
  # through the wall clock puts a clock in a fixture: pin boot and uptime
  # crawls, pin uptime and boot slides.  moonbase booted at a moment and has
  # been up for six days, and both are written down.
  (( SY_MOCK )) && return 0
  local -i b=${SY[boot]}
  (( b )) || return 0
  SY[uptime]=$(( int(EPOCHSECONDS - b) ))
  (( SY[uptime] < 0 )) && SY[uptime]=0
  return 0
}

sy_load() {
  (( SY_MOCK )) && return 0
  local tok
  local -a f n
  if [[ -r /proc/loadavg ]]; then
    # `0.52 0.58 0.59 1/234 5678` — three loads, then running/total and a pid
    f=(${=$(<"/proc/loadavg")})
  else
    # `sysctl -n vm.loadavg` answers `{ 1.23 4.56 7.89 }`, braces and all
    sy_run sysctl -n vm.loadavg
    f=(${=ROUT})
  fi
  # THE BRACES GO BY WHAT A NUMBER LOOKS LIKE, NEVER BY A PATTERN NAMING THEM.
  # `${ROUT//[{}]/}` cannot be written here, and the reason is worth the ink:
  # zsh finds the end of a `${...}` BY COUNTING BRACES and does not know it is
  # inside a bracket expression, so the `}` in `[{}]` closed the substitution
  # early and left `[{` as the pattern -- `bad pattern: [{`, which is fatal,
  # takes the whole shell down with it, and lives on the one branch a Mac
  # takes and a Linux box with /proc never does.  Keeping the tokens that ARE
  # numbers needs no such pattern, and drops `{`, `}` and /proc's `1/234` by
  # the same one rule.
  for tok in "${f[@]}"; do
    [[ "$tok" == (<->|<->.<->) ]] && n+=("$tok")
  done
  local -i i
  for (( i = 0; i < 3 && i < ${#n[@]}; i++ )); do SY[load.$i]="${n[$i]}"; done
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# ONE READING · the samplers, in system.py's own order
# ══════════════════════════════════════════════════════════════════════════
# THE ORDER IS system.py's tick_fast, then the four it runs beside it, then
# the two slow ones a probe can afford and a ten-second thread takes later.
sy_tick_all() {   # sy_tick_all [DT]
  local -F dt=${1:-1.0}
  sy_sample_cpu
  sy_sample_mem
  sy_sample_disk
  sy_sample_vols
  sy_sample_net $dt
  sy_sample_io $dt
  sy_load
  sy_uptime
  sy_sample_procs
  sy_sample_batt
  sy_sample_ifaces
  sy_sample_conn
  return 0
}
sy_tick_slow() {   # top -l 1 costs about a second and the battery block walks
  sy_sample_batt_deep   # the whole IO registry · neither changes in ten
  sy_sample_threads
  sy_sample_vols
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE GLASS · eight instruments, drawn into terminal.command's own rectangle
# ══════════════════════════════════════════════════════════════════════════
# THE COLOURS ARE ALREADY HERE.  system.py packs its own palette and
# terminal.command packs the same one -- same names, same RGB, down to the
# byte -- because both were cut from arcade.py.  So the pack takes the
# cabinet's, and the six roles the pages actually name are aliases over it.
sy_palette() {
  P_FG=$CYAN; P_LBL=$GREY; P_DIM=$DIM
  P_WARM=$PURPLE; P_HOT=$MAGENTA; P_WHITE=$WHITE
  cmix $WHITE $CYAN 0.22; SY_CORE=$CM    # the phosphor the raster dies into
  return 0
}
typeset -gi SY_CORE=0
typeset -gi P_FG=0 P_LBL=0 P_DIM=0 P_WARM=0 P_HOT=0 P_WHITE=0

sy_right() {   # sy_right XEND Y TEXT [FG] [BG] — ending AT that column
  v_text $(( $1 - ${#3} + 1 )) $2 "$3" ${4:--2} ${5:--2}
}

# ── words and numbers, the way the eight pages say them ────────────────────
SY_PART=('' '▏' '▎' '▍' '▌' '▋' '▊' '▉')
# ${s[$i]} IS THE SECOND CHARACTER under KSH_ARRAYS -- string subscripts go
# 0-based with the arrays -- and ${s[$i+1]} is therefore the wrong one twice
# over: it drops the first letter and adds an empty at the end.  The slice
# form says exactly which character it wants and cannot be read two ways.
sy_spaced() { local s="$1" o='' i; for (( i = 0; i < ${#s}; i++ )); do
                o+="${o:+ }${s[$i,$i]}"; done; SPD="$o" }
sy_span() {   # how far back a history of n readings reaches, in words
  local -i sec=$(( $1 * 10 ))
  if   (( sec >= 5400 )); then printf -v SPN '%.1f h' $(( sec / 3600.0 ))
  elif (( sec >= 90 ));   then printf -v SPN '%d min' $(( int(sec / 60.0 + 0.5) ))
  else                         printf -v SPN '%d s' $sec; fi
}
sy_human_b() {   # ps gives RSS in kilobytes
  local -F kb=$1
  if   (( kb >= 1048576 )); then printf -v HB '%.1fG' $(( kb / 1048576.0 ))
  elif (( kb >= 1024 ));    then printf -v HB '%.0fM' $(( kb / 1024.0 ))
  else                           printf -v HB '%dK' $(( int(kb) )); fi
}
sy_human_g() {   # GIBIBYTES, BASE 1024.  The Finder counts in decimal
  local -F v=$1  # gigabytes, so a 1 TB disk reads 926G here against its
  local u="${2:-}"   # 994.66 GB there -- which looks like sixty-eight missing
  if   (( v >= 1024.0 )); then printf -v HG '%.1fT%s' $(( v / 1024.0 )) "$u"
  elif (( v >= 100 ));    then printf -v HG '%.0fG%s' $v "$u"
  else                         printf -v HG '%.1fG%s' $v "$u"; fi
}
sy_human_n() {   # a count, at a glance: 940, 12.3K, 4.5M
  local -F v=$1
  if   (( v >= 1000000000.0 )); then printf -v HN '%.1fB' $(( v / 1000000000.0 ))
  elif (( v >= 1000000.0 ));    then printf -v HN '%.1fM' $(( v / 1000000.0 ))
  elif (( v >= 1000.0 ));       then printf -v HN '%.1fK' $(( v / 1000.0 ))
  else                               printf -v HN '%.0f' $v; fi
}
sy_up() {   # sy_up SECONDS -> UPS
  local -i s=$1 d h m
  d=$(( s / 86400 )); s=$(( s % 86400 ))
  h=$(( s / 3600 ));  s=$(( s % 3600 ))
  m=$(( s / 60 ));    s=$(( s % 60 ))
  printf -v UPS '%dd %02d:%02d:%02d' $d $h $m $s
}
# ── a reading on its way to its figure ──────────────────────────────────────
# THE BAR EASES; THE NUMBER DOES NOT.  Every gauge on these pages used to jump
# to its new length the frame a sampler wrote, once every ten seconds -- a
# panel of instruments all twitching at once.  The figure printed beside a
# bar is still the measured one, to the digit; the bar takes MO_VALUE to get
# there, on the cabinet's own curve.  sy_ease KEY FRAC -> SMF
typeset -gF SY_NOW=0.0
sy_ease() { mo_ease "sy.$1" $2 $SY_NOW; SMF=$MV; return 0 }

sy_hbar() {   # sy_hbar W FRAC -> BAR, to an eighth of a cell
  local -i w=$1 whole rem i
  local -F f=$2
  (( f < 0.0 )) && f=0.0
  (( f > 1.0 )) && f=1.0
  f=$(( f * w )); whole=$(( int(f) )); rem=$(( int((f - whole) * 8 + 0.5) ))
  (( rem == 8 )) && { (( whole++ )); rem=0 }
  BAR=''
  for (( i = 0; i < whole; i++ )); do BAR+='█'; done
  (( rem > 0 && whole < w )) && BAR+="${SY_PART[$rem]}"
  return 0
}
sy_tone() {   # the one rule for what a fraction is worth saying in
  local -F v=$1
  if   (( v > 0.85 )); then TON=$P_HOT
  elif (( v > 0.6 ));  then TON=$P_WARM
  else                      TON=$P_FG; fi
}

# ══════════════════════════════════════════════════════════════════════════
# BRAILLE · a 2 x 4 dot matrix per cell, and colour still per cell
# ══════════════════════════════════════════════════════════════════════════
# Menlo does not carry U+2800.  Neither does DejaVu Sans Mono, though DejaVu
# Sans does -- and Terminal.app has no synthetic fallback the way ghostty,
# kitty and xterm.js do, so on a font without the block macOS substitutes one
# and the glyph is squeezed into a cell it was not cut for.  [G] while running
# swaps every plot for block elements at a quarter of the vertical resolution.
SY_BLOCKS=0
SY_BLK=(' ' '▘' '▝' '▀' '▖' '▌' '▞' '▛' '▗' '▚' '▐' '▜' '▄' '▙' '▟' '█')
typeset -ga PB PC PP
typeset -gi PWC=0 PHC=0 PW=0 PH=0
# THE DOT'S BIT, BY COLUMN THEN ROW · 1 2 4 64 / 8 16 32 128 · indexed by
# ((x & 1) << 2) | (y & 3), one table for every dot instead of a two-element
# array literal built for each one.
typeset -ga SY_MSK; SY_MSK=(1 2 4 64 8 16 32 128)
# THE 256 BRAILLE GLYPHS, CUT ONCE.  Every lit cell of every plot was turning
# its bit pattern into a codepoint and the codepoint into a glyph on the way
# to the glass; here they are, by their pattern.
typeset -ga SY_BRL; SY_BRL=()
{ local -i _m; for (( _m = 0; _m < 256; _m++ )); do SY_BRL+=("${(#)$(( 10240 + _m ))}"); done; unset _m; } 2>/dev/null
sy_plot_new() {   # sy_plot_new WC HC
  PWC=$1; PHC=$2; PW=$(( PWC * 2 )); PH=$(( PHC * 4 ))
  local -i n=$(( PWC * PHC ))
  # three blank sheets, from the cabinet's run cache: one copy each instead
  # of three appends a cell, which on a wide glass was a tenth of a second
  # before a single dot was plotted
  _repn $n 0;  PB=("${(@P)REPV}"); PP=("${(@P)REPV}")
  _repn $n -1; PC=("${(@P)REPV}")
  return 0
}
# THE PRIORITY IS WHY THE TRACE IS NOT THE COLOUR OF ITS OWN SHADING.  A cell
# holds one colour and up to eight dots, and the dots under a line belong to
# the fill -- so the LAST writer would win, the fill is drawn after the line,
# and a hot trace would come out dim wherever its own shading reached it.
sy_dot() {   # sy_dot X Y COL [PRI]
  local -i x=$(( int($1 + 0.5) )) y=$(( int($2 + 0.5) )) i pri=${4:-1}
  (( x < 0 || y < 0 || x >= PW || y >= PH )) && return 0
  i=$(( (y >> 2) * PWC + (x >> 1) ))
  if (( SY_BLOCKS )); then
    # four braille rows collapse onto two block halves
    PB[$i]=$(( PB[i] | (1 << ((((y & 3) >> 1) * 2) + (x & 1))) ))
  else
    PB[$i]=$(( PB[i] | SY_MSK[((x & 1) << 2) | (y & 3)] ))
  fi
  (( pri >= PP[i] )) && { PP[$i]=$pri; PC[$i]=$3 }
  return 0
}
# THE DOT IS WRITTEN OUT IN FULL HERE, and it is the one place in this file
# that repeats itself on purpose.  A line is the plotter's hot loop -- every
# trace on every page is two hundred of them, and the scope is a thousand --
# and in zsh a FUNCTION CALL costs more than the work inside it: measured,
# sy_dot is 23.8 us called and 9.9 us inlined, so fourteen of every
# twenty-four microseconds were the calling, not the plotting.  At fourteen
# hundred dots a trace that is twenty milliseconds a page given away for
# tidiness.  sy_dot itself stays, and stays the definition: this is the same
# arithmetic, and any change to one belongs in the other.
sy_plot_line() {   # sy_plot_line X0 Y0 X1 Y1 COL [PRI]
  local -F x0=$1 y0=$2 x1=$3 y1=$4 dx dy
  local -i col=$5 k n pri=${6:-1} px py pi
  dx=$(( x1 - x0 )); dy=$(( y1 - y0 ))
  n=$(( int((abs(dx) > abs(dy) ? abs(dx) : abs(dy)) + 0.5) ))
  (( n < 1 )) && n=1
  for (( k = 0; k <= n; k++ )); do
    px=$(( int(x0 + dx * k / n + 0.5) )); py=$(( int(y0 + dy * k / n + 0.5) ))
    (( px < 0 || py < 0 || px >= PW || py >= PH )) && continue
    pi=$(( (py >> 2) * PWC + (px >> 1) ))
    if (( SY_BLOCKS )); then
      PB[$pi]=$(( PB[pi] | (1 << ((((py & 3) >> 1) * 2) + (px & 1))) ))
    else
      PB[$pi]=$(( PB[pi] | SY_MSK[((px & 1) << 2) | (py & 3)] ))
    fi
    (( pri >= PP[pi] )) && { PP[$pi]=$pri; PC[$pi]=$col }
  done
  return 0
}
sy_plot_blit() {   # sy_plot_blit X Y — onto the glass, over the bare tube
  # WRITTEN STRAIGHT INTO THE GRID, clipped as v_put clips (to the glass, then
  # to the grid), with the row's index worked out once a row and the glyph
  # taken from the table: a lit cell is three assignments, not a call.
  local -i ox=$1 oy=$2 cx cy base m k gx gy cxa cxb pi
  # the columns the glass and the grid will take are the same on every row
  cxa=0; (( ox < 0 )) && cxa=$(( -ox )); (( OX + C_SCR + ox + cxa < 0 )) && cxa=$(( -(OX + C_SCR + ox) ))
  cxb=$(( PWC - 1 )); (( ox + cxb >= SCR_W )) && cxb=$(( SCR_W - 1 - ox ))
  (( OX + C_SCR + ox + cxb >= TCOLS )) && cxb=$(( TCOLS - 1 - OX - C_SCR - ox ))
  for (( cy = 0; cy < PHC; cy++ )); do
    gy=$(( oy + cy )); (( gy < 0 || gy >= SCR_H )) && continue
    gy=$(( OY + R_SCR + gy )); (( gy < 0 || gy >= TROWS )) && continue
    base=$(( cy * PWC ))
    k=$(( gy * TCOLS + OX + C_SCR + ox + cxa )); pi=$(( base + cxa ))
    if (( SY_TR_REC )); then        # a trace being kept · the cells, as they are laid
      for (( cx = cxa; cx <= cxb; cx++, k++, pi++ )); do
        m=${PB[pi]}; (( m )) || continue
        if (( SY_BLOCKS )); then GCH[k]="${SY_BLK[m]}"; else GCH[k]="${SY_BRL[m]}"; fi
        GF[k]=${PC[pi]}; GB[k]=$GLASS
        SY_TRRK+=($k); SY_TRRC+=(${PC[pi]}); SY_TRRG+="${GCH[k]}"
      done
    elif (( SY_BLOCKS )); then
      for (( cx = cxa; cx <= cxb; cx++, k++, pi++ )); do
        m=${PB[pi]}; (( m )) || continue
        GCH[k]="${SY_BLK[m]}"; GF[k]=${PC[pi]}; GB[k]=$GLASS
      done
    else
      for (( cx = cxa; cx <= cxb; cx++, k++, pi++ )); do
        m=${PB[pi]}; (( m )) || continue
        GCH[k]="${SY_BRL[m]}"; GF[k]=${PC[pi]}; GB[k]=$GLASS
      done
    fi
  done
  return 0
}

# ── a tape of readings, plotted · the overview's own, reused everywhere ────
# A TRACE IS REMEMBERED BY EVERYTHING IT IS DRAWN FROM.  A page is painted
# again for every frame its bars are still easing, a third of a second after
# every reading, and its trace -- the same samples, at the same place, in the
# same inks -- was plotted again from nothing each time.  The cells a trace
# leaves on the glass are kept under its own arguments and the ground they
# stand on, and laid down again cell for cell; a few are kept, and let go
# together.
typeset -gA SY_TRK SY_TRG SY_TRC SY_TRX
typeset -gi SY_TRN=0 SY_TR_REC=0
typeset -ga SY_TRRK SY_TRRC
typeset -g  SY_TRRG=''
sy_trace() {   # sy_trace X Y WC HC SERIES... — so every page reads as one
  local -i x=$1 y=$2 wc=$3 hc=$4 i j n col fill=${SY_TRACE_FILL:-1}
  local -i k nn px py pi fy msk pdim=$P_DIM
  shift 4
  local -a s; s=("$@")
  n=${#s[@]}
  (( n < 2 )) && return 0
  local mk="$x|$y|$wc|$hc|$fill|$P_HOT|$P_WARM|$P_FG|$P_DIM|$SY_BLOCKS|$GLASS|$OX|$C_SCR|$OY|$R_SCR|$SCR_W|$SCR_H|$TCOLS|$TROWS|${(j:,:)s[@]}"
  if [[ -n "${SY_TRX[$mk]:-}" ]]; then
    local -a kk cc ga
    kk=(${=SY_TRK[$mk]}); cc=(${=SY_TRC[$mk]}); ga=("${(@s::)SY_TRG[$mk]}")
    local -i q nk=${#kk[@]} gl=$GLASS
    for (( q = 0; q < nk; q++ )); do
      GCH[kk[q]]="${ga[q]}"; GF[kk[q]]=${cc[q]}; GB[kk[q]]=$gl
    done
    TRMX=${SY_TRX[$mk]}
    return 0
  fi
  sy_plot_new $wc $hc
  local -F mx=0.000001 v f yy prev=-1.0 x0 y0 x1 y1 dx dy
  for v in "${s[@]}"; do (( v > mx )) && mx=$v; done
  # EVERY PAGE IN THIS MACHINE STANDS ON ONE OF THESE, and every reading
  # redraws it: four hundred line segments and a thousand dots of shading on
  # a full glass, each of them a function call that cost more than the
  # plotting inside it.  So both are written out here -- sy_plot_line's
  # arithmetic and sy_dot's, as they are, and the segment's ends handed over
  # the way an argument hands them over (a float prints at ten places), so
  # the same dots land in the same cells.
  for (( i = 0; i < PW; i++ )); do
    j=$(( int(i * (n - 1) / (PW - 1.0)) ))
    v=${s[$j]}
    f=$(( v / mx )); (( f < 0.0 )) && f=0.0; (( f > 1.0 )) && f=1.0
    yy=$(( PH - 1 - f * (PH - 2) ))
    if   (( f > 0.85 )); then col=$P_HOT
    elif (( f > 0.6 ));  then col=$P_WARM
    else                      col=$P_FG; fi
    if (( prev >= 0.0 )); then
      x0=$(( i - 1 )); y0=$prev; x1=$i; y1=$yy
      dx=$(( x1 - x0 )); dy=$(( y1 - y0 ))
      nn=$(( int((abs(dx) > abs(dy) ? abs(dx) : abs(dy)) + 0.5) ))
      (( nn < 1 )) && nn=1
      for (( k = 0; k <= nn; k++ )); do
        px=$(( int(x0 + dx * k / nn + 0.5) )); py=$(( int(y0 + dy * k / nn + 0.5) ))
        (( px < 0 || py < 0 || px >= PW || py >= PH )) && continue
        pi=$(( (py >> 2) * PWC + (px >> 1) ))
        if (( SY_BLOCKS )); then
          PB[$pi]=$(( PB[pi] | (1 << ((((py & 3) >> 1) * 2) + (px & 1))) ))
        else
          PB[$pi]=$(( PB[pi] | SY_MSK[((px & 1) << 2) | (py & 3)] ))
        fi
        (( 3 >= PP[pi] )) && { PP[$pi]=3; PC[$pi]=$col }
      done
    else
      sy_dot $i $yy $col 3
    fi
    # ...AND THE SHADING UNDER IT, every fifth column, so the trace reads as a
    # quantity standing on a floor rather than as a wire in the air.  At the
    # bottom priority, which is what keeps it out of the trace's own colour.
    # (every dot of a column's shading is the same bit of the same column of
    # cells, a row of cells further down each time, so the bit is worked out
    # once and the walk is one arithmetic statement a dot)
    if (( fill && i % 5 == 0 )); then
      fy=$(( int(yy) + 4 ))
      if (( fy < PH && fy >= 0 )); then
        if (( SY_BLOCKS )); then msk=$(( 1 << ((((fy & 3) >> 1) * 2) + (i & 1)) ))
        else msk=${SY_MSK[((i & 1) << 2) | (fy & 3)]}; fi
        for (( pi = (fy >> 2) * PWC + (i >> 1); fy < PH; fy += 4, pi += PWC )); do
          (( PB[pi] |= msk, PP[pi] <= 1 && (PP[pi] = 1, PC[pi] = pdim) ))
        done
      fi
    fi
    prev=$yy
  done
  SY_TR_REC=1; SY_TRRK=(); SY_TRRC=(); SY_TRRG=''
  sy_plot_blit $x $y
  SY_TR_REC=0
  TRMX=$mx
  (( SY_TRN++ >= 12 )) && { SY_TRK=(); SY_TRG=(); SY_TRC=(); SY_TRX=(); SY_TRN=0 }
  SY_TRK[$mk]="${SY_TRRK[*]}"; SY_TRC[$mk]="${SY_TRRC[*]}"; SY_TRG[$mk]="$SY_TRRG"; SY_TRX[$mk]=$mx
  return 0
}

# ── the furniture · so eight surfaces read as eight views of one machine ───
sy_page_head() {   # sy_page_head TITLE [RIGHT] — on the suite's title bar
  # THE BRAND, THE SKY AND THE RULE ARE THE CABINET'S NOW · app_head lays the lit
  # band, ◤ SYSTEM in its corner and the sky's caption in the other; this page
  # sets its name and its one right-hand reading in the room between.
  # THE LIST IS MENU, PLAIN, the way INTELLIGENCE's and XENOGOTCHI's read: it
  # used to say ◂ SYSTEM ▸ beside ◤ SYSTEM, one band naming the machine twice
  # under a bezel that names it a third time -- and ◂ ▸ do not turn it.
  local r="${2:-}"; local -i hb
  cmix $GLASS $PURPLE 0.32; hb=$CM
  app_head SYSTEM
  local -i x
  if [[ "$1" == MENU ]]; then
    cmix $WHITE $CYAN 0.15; v_text $APP_HX 0 "$1" $CM $hb
    x=$(( APP_HX + ${#1} ))
  else
    cshade $PURPLE 1.15;    v_text $APP_HX 0 '◂ ' $CS $hb
    cmix $WHITE $CYAN 0.15; v_text $(( APP_HX + 2 )) 0 "$1" $CM $hb
    cshade $PURPLE 1.15;    v_text $(( APP_HX + 2 + ${#1} )) 0 ' ▸' $CS $hb
    x=$(( APP_HX + 4 + ${#1} ))
  fi
  if [[ -z "$r" ]]; then sy_up ${SY[uptime]}; r="UP $UPS"; fi
  # THE READING ENDS AT THE CAPTION AND STARTS CLEAR OF THE NAME · under a
  # night caption on the cabinet's glass PROCESSES' count used to be laid
  # over its own title (◂ PR108 PROCESSES · 2914 THREADS …); it is cut to the
  # room there is, and left off when that is too little to say anything
  local -i room=$(( APP_HR - x - 2 ))
  if (( ${#r} > room )); then
    if (( room >= 10 )); then r="${r[0,$(( room - 2 ))]}…"; else r=''; fi
  fi
  [[ -n "$r" ]] && sy_right $APP_HR 0 "$r" $P_LBL $hb
  return 0
}
sy_panel() {   # sy_panel X Y W H TITLE — a box with its name in the top rule
  v_box $1 $2 $3 $4 $P_DIM $GLASS round
  v_text $(( $1 + 2 )) $2 " $5 " $AMBER $GLASS
  return 0
}
sy_panel_rule() {   # sy_panel_rule X Y W TITLE — a rule across a panel's inside
  local l='' i
  for (( i = 0; i < $3 - 2; i++ )); do l+='─'; done
  v_text $1 $2 "├${l}┤" $P_DIM $GLASS
  v_text $(( $1 + 2 )) $2 " $4 " $AMBER $GLASS
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE MENU · six instruments and two tables, grouped
# ══════════════════════════════════════════════════════════════════════════
# NINE THINGS IN ONE FLAT LIST WAS NINE THINGS TO READ.  There are really two
# kinds here: six INSTRUMENTS, which are pictures of a machine running, and
# two TABLES, which are lists you go down.  They are grouped, and each group
# is named on the rule above it.  The way out is a third kind again -- a verb,
# not a place -- so it is not in the list at all: it sits on the footer and on
# the cabinet's panel, where it cannot be arrived at by leaning on a cursor.
#
# WHICH IS WHY MEMORY ANSWERS TO [R] AND NOT [M].  [M] is the way out, the
# same key on every cabinet in the suite, and a letter that leaves a machine
# cannot also be a letter that opens a page on it.  The list has always taken
# the letter that FITS over the letter that starts the word -- PROCESSOR is
# [C] for the cpu, STORAGE is [D] for the disk, POWER is [B] for the battery
# -- so memory is [R], for the ram it is a picture of.
SY_MK=(O C R D N B P H)
SY_MN=(OVERVIEW PROCESSOR MEMORY STORAGE NETWORK POWER PROCESSES HARDWARE)
SY_MV=(scope cpu mem disk net pwr procs hw)
SY_MD=('scope, tapes and gauges — the machine at once'
       'every core, the load, where the time goes'
       'wired, active, compressed, swap and pressure'
       'volumes, throughput, reads and writes'
       'links, addresses, traffic, open sockets'
       'charge, health, temperature, what is drawing'
       'every process, sorted and scrollable'
       'what this machine is, and what it has done')
SY_GROUP_AT=6            # ...and the rule that says TABLES goes above this one
SY_MENU_DESC=50          # the widest a description may be before it is cut
SY_MENU_READ=16          # ...and the reading beside it, which must never reach it
# what the cabinet's own panel calls each surface, in the space it has
SY_SHORT=(SCOPE CPU MEM DISK NET POWER PROCS HW)
# THE PAGES TURN WITH ◂ ▸, on every surface in the suite alike.  The menu is
# the first page and the ring closes on it, so ▸ from the last instrument is
# the menu again and ◂ from the menu is the last instrument.
SYS_VIEW='menu'
typeset -gi SYS_ROW=0
# the landing page's instrument box · sy_draw_menu sizes it, sy_menu_rows fills
# it, so both must read the same left and width.  Fixed on the cabinet glass;
# stretched when the glass is the whole window (SCREEN=fill).
typeset -gi SY_LPX=8 SY_LPW=90

sy_reading() {   # sy_reading I -> RD, what the row is worth saying right now
  local -F d
  case "${SY_MV[$1]}" in
    scope) printf -v RD 'load %.2f' ${SY[load.0]} ;;
    cpu)   printf -v RD '%.1f%% busy' ${SY[cpu]} ;;
    mem)   printf -v RD '%.0f%% used' ${SY[mem_pct]} ;;
    disk)  d=$(( ${SY[disk_total]} > 0.001 ? ${SY[disk_total]} : 0.001 ))
           printf -v RD '%.0f%% full' $(( 100.0 * ${SY[disk_used]} / d )) ;;
    net)   printf -v RD '%.1f MB/s' $(( ${SY[net_rx]} + ${SY[net_tx]} )) ;;
    pwr)   if [[ "${SY[batt_pct]}" == null || "${SY[batt_pct]}" == 0 ]]; then
             RD='no cell'
           else printf -v RD '%d%%' ${SY[batt_pct]}; fi
           [[ "${SY[temp]}" != null ]] && (( ${SY[temp]} )) && \
             printf -v RD '%s · %.0f°C' "$RD" ${SY[temp]} ;;
    procs) printf -v RD '%d tasks' ${SY[nproc]} ;;
    hw)    RD="${SY[model_id]:-${SY[arch]}}" ;;
    *)     RD='' ;;
  esac
  return 0
}

# ── the marquee · the one line of the list page that answers the clock ────
# ── the instrument rows · the band under the cursor glides, so they are live ─
sy_menu_rows() {
  local -i i y on bg px=$SY_LPX pw=$SY_LPW ry idx col xr vx dw
  local read
  local -F pos sk
  sy_menu_inks
  mo_ease cursor.sys.menu $SYS_ROW $SY_NOW $MO_CURSOR; pos=$MV
  ry=$(( SY_MENU_PY + 1 )); idx=0
  # THE COLUMNS · the reading ends three in from the box's right edge, its
  # picture in a ten-cell column just before it, and the description has the
  # rest of the row to itself
  xr=$(( px + pw - 3 )); vx=$(( xr - SY_MENU_READ - 10 )); dw=$(( vx - 2 - (px + 20) ))
  for (( i = 0; i < ${#SY_MK[@]}; i++ )); do
    if (( i == SY_GROUP_AT )); then
      (( ry++ ))
    fi
    y=$ry; on=0
    sk=$(( 1.0 - abs(idx - pos) )); (( sk < 0.0 )) && sk=0.0
    (( sk >= 0.5 )) && on=1
    if (( sk > 0.001 )); then cmix $GLASS $P_DIM $(( 0.55 * sk )); bg=$CM; else bg=$GLASS; fi
    v_fill $(( px + 1 )) $y $(( pw - 2 )) 1 ' ' $GREY $bg
    if (( on )); then v_text $(( px + 2 )) $y '▸' $LIME $bg
    else              v_text $(( px + 2 )) $y ' ' $P_DIM $bg; fi
    if (( on )); then col=$AMBER; else cshade $AMBER 0.62; col=$CS; fi
    v_text $(( px + 4 )) $y "[${SY_MK[$i]}]" $col $bg
    if (( on )); then col=$P_WHITE; else col=$P_LBL; fi
    v_text $(( px + 8 )) $y "${(r:10:)SY_MN[$i]}" $col $bg
    # the line under each name readable from across the room, not only
    # under the cursor
    if (( on )); then col=$SY_MI_DON; else col=$SY_MI_DOFF; fi
    v_text $(( px + 20 )) $y "${SY_MD[$i][0,$(( dw - 1 ))]}" $col $bg
    sy_menu_vis $i $on
    if [[ -n "$MV1$MV2" ]]; then
      v_text $(( vx + 10 - ${#MV1} - ${#MV2} )) $y "$MV1" $MV1C $bg
      [[ -n "$MV2" ]] && v_text $(( vx + 10 - ${#MV2} )) $y "$MV2" $MV2C $bg
    fi
    sy_reading $i; read="$RD"
    (( ${#read} > SY_MENU_READ )) && read="${read[0,$(( SY_MENU_READ - 1 ))]}…"
    if (( on )); then col=$P_FG; else col=$SY_MI_ROFF; fi
    sy_right $xr $y "$read" $col $bg
    (( ry++ )); (( idx++ ))
  done
  return 0
}
typeset -g  SY_MI_KEY=''
typeset -gi SY_MI_DON=0 SY_MI_DOFF=0 SY_MI_ROFF=0 SY_MI_OFF=0 SY_MI_OK=0 SY_MI_MID=0 SY_MI_BAD=0 SY_MI_SPK=0 SY_MI_SPKD=0
sy_menu_inks() {   # the list's inks, worked out when the palette is new
  local key="$P_LBL|$P_WHITE|$P_FG|$GREY"
  [[ "$key" == "$SY_MI_KEY" ]] && return 0
  SY_MI_KEY="$key"
  cmix $P_LBL $P_WHITE 0.35; SY_MI_DON=$CM
  cshade $P_LBL 0.82; SY_MI_DOFF=$CS
  cshade $P_FG 0.72; SY_MI_ROFF=$CS
  cshade $GREY 0.36; SY_MI_OFF=$CS
  cmix $CYAN $LIME 0.5; SY_MI_OK=$CM
  SY_MI_MID=$AMBER
  cmix $RED $AMBER 0.3; SY_MI_BAD=$CM
  SY_MI_SPK=$P_FG; cshade $P_FG 0.70; SY_MI_SPKD=$CS
  return 0
}
typeset -g  MV1='' MV2=''; typeset -gi MV1C=0 MV2C=0
typeset -gA SY_MVC; typeset -g SY_MVC_GEN=''
sy_menu_vis() {   # sy_menu_vis I ON -> MV1 MV1C MV2 MV2C · the row's reading as a picture: a meter, or its last ten readings
  # worked out once a reading, a row and a state: the rows are redrawn every
  # frame for the cursor's band, and the picture only changes with the reading
  local -i i=$1 on=$2 p n s0 k j
  local -F v mx
  local -a a
  local mk="$1|$2" got
  [[ "$SY_MVC_GEN" == "$SY_GEN|$SY_MI_KEY" ]] || { SY_MVC=(); SY_MVC_GEN="$SY_GEN|$SY_MI_KEY"; }
  got="${SY_MVC[$mk]:-}"
  if [[ -n "$got" ]]; then
    a=("${(@ps:\t:)got}"); MV1="${a[0]}"; MV1C=${a[1]}; MV2="${a[2]}"; MV2C=${a[3]}
    return 0
  fi
  sy_menu_vis_work $1 $2
  SY_MVC[$mk]="${MV1}"$'\t'"${MV1C}"$'\t'"${MV2}"$'\t'"${MV2C}"
  return 0
}
sy_menu_vis_work() {
  local -i i=$1 on=$2 p n s0 k j
  local -F v mx
  local -a a
  MV1=''; MV2=''; MV1C=0; MV2C=0
  case "${SY_MV[$i]}" in
    cpu|net)
      if [[ "${SY_MV[$i]}" == cpu ]]; then
        a=("${SY_CPU_HIST[@]}"); s0=$(( ${#a[@]} - ${SY_SEEN[SY_CPU_HIST]:-0} )); mx=100.0
      else
        n=${#SY_RX_HIST[@]}; a=()
        for (( k = 0; k < n; k++ )); do a+=($(( ${SY_RX_HIST[$k]} + ${SY_TX_HIST[$k]:-0} ))); done
        s0=$(( n - ${SY_SEEN[SY_RX_HIST]:-0} )); mx=0.05
      fi
      n=${#a[@]}; (( s0 < 0 )) && s0=0
      k=$(( n - 10 )); (( k < s0 )) && k=$s0
      (( n - k >= 2 )) || return 0
      if [[ "${SY_MV[$i]}" == net ]]; then for (( j = k; j < n; j++ )); do (( a[j] > mx )) && mx=${a[$j]}; done; fi
      for (( j = k; j < n; j++ )); do
        v=${a[$j]}; p=$(( int(v / mx * 8.0 + 0.5) )); (( p < 1 )) && p=1; (( p > 8 )) && p=8
        MV1+="${SY_LVL[$p]}"
      done
      if (( on )); then MV1C=$SY_MI_SPK; else MV1C=$SY_MI_SPKD; fi
      ;;
    mem|disk|pwr)
      case "${SY_MV[$i]}" in
        mem)  p=$(( int(${SY[mem_pct]:-0} + 0.5) )) ;;
        disk) (( ${SY[disk_total]:-0} > 0.001 )) || return 0
              p=$(( int(100.0 * ${SY[disk_used]} / ${SY[disk_total]} + 0.5) )) ;;
        pwr)  [[ "${SY[batt_pct]:-null}" == (null|0) ]] && return 0
              p=${SY[batt_pct]} ;;
      esac
      (( p < 0 )) && p=0; (( p > 100 )) && p=100
      n=$(( (p * 8 + 50) / 100 )); (( p > 0 && n == 0 )) && n=1
      _run $n '▰'; MV1="$RUN"; _run $(( 8 - n )) '▱'; MV2="$RUN"
      # how full is good news for a battery and bad news for everything else
      if [[ "${SY_MV[$i]}" == pwr ]]; then
        if (( p > 50 )); then MV1C=$SY_MI_OK; elif (( p > 20 )); then MV1C=$SY_MI_MID; else MV1C=$SY_MI_BAD; fi
      else
        if (( p >= 90 )); then MV1C=$SY_MI_BAD; elif (( p >= 70 )); then MV1C=$SY_MI_MID; else MV1C=$SY_MI_OK; fi
      fi
      (( on )) || { cshade $MV1C 0.78; MV1C=$CS; }
      # the empty part of the meter, a shade lighter on the cursor's band so it still shows there
      if (( on )); then cshade $GREY 0.62; MV2C=$CS; else MV2C=$SY_MI_OFF; fi
      ;;
  esac
  return 0
}
typeset -gi SY_MENU_PY=3            # the INSTRUMENTS panel's top row · the band, its rule and one row of air above
sy_draw_menu() {   # sy_draw_menu T — everything on the list page that holds still
  local -F t=$1
  local -i i y ry col
  # ── THE MAP · fixed for the cabinet glass, stretched for the whole window ──
  # THE LIST, THE SCOPE, THE READINGS.  The instruments up top; under them
  # the processor on the card's own scope -- the same frame, the same ruled
  # screen, the same trace on the processor's own scale -- reaching from one
  # side of the glass to the other; and the machine's particulars along the
  # foot.  A tall glass gives the scope more rows (to a point: past it, a
  # quarter-busy machine is a lot of empty screen) and, under it, the three
  # tapes beside the processor's: memory, the network and the disks.
  local -i px pw c1l c1v v1w c2l c2v v2w r1 infy sx sy cw ch avail tb gap tw tx lead
  local v
  if (( SCR_W > 120 )); then
    px=3;  pw=$(( SCR_W - 6 ))
    c1l=2; c1v=11; v1w=25; c2l=$(( SCR_W / 2 )); c2v=$(( c2l + 9 )); v2w=$(( SCR_W - c2v - 2 ))
    infy=$(( SCR_H - 5 )); r1=$(( SCR_H - 6 ))
  else
    px=2;  pw=$(( SCR_W - 4 ))                   # as wide as the scope under it
    c1l=2; c1v=11; v1w=25; c2l=56; c2v=65; v2w=37
    r1=23; infy=24
  fi
  SY_LPX=$px; SY_LPW=$pw
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  # NO NAME ON THE GLASS UNDER THE NAME ON THE BAND.  The list used to open
  # under S Y S T E M and A L I E N   D Y N A M I C S · M O D E L   N X - 8 8,
  # which the bezel's sign, its plate and the coin door were already saying a
  # few rows away; the rows they took are the trace's now.
  sy_page_head MENU

  # THE LETTER THAT REACHES A SURFACE BELONGS BESIDE IT.  It used to live only
  # on the cabinet's panel, with a footer line telling you to go and look for
  # it down there -- so choosing anything meant reading the name here, dropping
  # eleven rows to find its key, and coming back up.
  sy_panel $px $SY_MENU_PY $pw $(( ${#SY_MK[@]} + 3 )) INSTRUMENTS
  ry=$(( SY_MENU_PY + 1 ))
  for (( i = 0; i < ${#SY_MK[@]}; i++ )); do
    if (( i == SY_GROUP_AT )); then
      sy_panel_rule $px $ry $pw TABLES; (( ry++ ))
    fi
    (( ry++ ))
  done
  sy_menu_rows

  # ── the scope, and on a tall glass the tapes under it ──
  sx=2; cw=$(( SCR_W - 6 ))
  sy=$(( SY_MENU_PY + ${#SY_MK[@]} + 4 ))
  avail=$(( r1 - 1 - sy ))                       # rows from the scope's top rule to the readings' rule
  tb=0; gap=0
  if (( SCR_W > 120 && avail >= 24 )); then tb=8; gap=1; fi
  ch=$(( avail - (tb ? tb + gap : 0) - 2 )); (( ch > 18 )) && ch=18; (( ch < 3 )) && ch=3
  lead=$(( (avail - (ch + 2) - (tb ? tb + gap : 0)) / 2 )); (( lead < 0 )) && lead=0
  sy=$(( sy + lead ))
  sy_peak SY_CPU_HIST; sy_scope_span
  printf -v v 'PEAK %.0f%%' $SYPK
  sy_scope_frame $sx $sy $cw $ch "PROCESSOR · THE LAST ${SPN:u}" "$v"
  cshade $GREY 0.62; col=$CS
  v_text $(( sx + 2 )) $(( sy + ch + 1 )) ' older ' $col $BLACK
  v_text $(( sx + cw - 5 )) $(( sy + ch + 1 )) ' now ' $col $BLACK
  sy_tc_scope $(( sx + 1 )) $(( sy + 1 )) $cw $ch
  sy_scope_rest $(( sx + 1 )) $(( sy + 1 )) $cw $ch
  SY_MS_SX=$sx; SY_MS_SY=$sy; SY_MS_CW=$cw; SY_MS_CH=$ch
  if (( tb )); then
    y=$(( sy + ch + 2 + gap )); tw=$(( (cw + 2 - 4) / 3 )); tx=$sx
    sy_menu_tape $tx $y $tw $tb MEMORY mem
    sy_menu_tape $(( tx + tw + 2 )) $y $tw $tb NETWORK net
    sy_menu_tape $(( tx + 2 * (tw + 2) )) $y $(( cw + 2 - 2 * (tw + 2) )) $tb 'DISK I/O' io
  fi

  v_hline 0 $r1 $SCR_W '─' $P_DIM
  sy_human_g ${SY[mem_used]};  local m1="$HG"
  sy_human_g ${SY[mem_total]}; local m2="$HG"
  sy_human_g ${SY[disk_used]};  local d1="$HG"
  sy_human_g ${SY[disk_total]}; local d2="$HG"
  local -a k1 v1 k2 v2
  k1=(HOST SYSTEM CPU)
  v1=("${SY[host]}" "${SY[osname]}" "${SY[cpu_model]:-${SY[arch]}}")
  # not UP: the title bar of this very page is already showing it
  k2=(MEMORY VOLUME LINK)
  v2=("$m1 of $m2" "$d1 of $d2" "${SY[net_if]:--} · ${SY[net_ip]:-no address}")
  for (( i = 0; i < 3; i++ )); do
    y=$(( infy + i ))
    v_text $c1l $y "${(r:8:)k1[$i]}" $P_LBL
    v_text $c1v $y "${v1[$i][0,$v1w]}" $P_FG
    v_text $c2l $y "${(r:8:)k2[$i]}" $P_LBL
    v_text $c2v $y "${v2[$i][0,$v2w]}" $P_FG
  done
  # THE LIST PAGE'S KEYS, on the suite's one nav bar.  app_nav draws the rule
  # under the readings block itself, on the glass's last two rows -- so the
  # separate r2 rule this used to lay is the nav's now.  The letter beside each
  # instrument is printed in the list above, so the bar need not spell it out.
  app_nav '▴ ▾' choose '⏎' open '[⎋]' out
  return 0
}
typeset -gi SY_MS_SX=0 SY_MS_SY=0 SY_MS_CW=0 SY_MS_CH=0   # where the list page put its scope, for the beam
sy_menu_beam() {   # the list page's scope, live · the beam going round, and the trace bright where it has just been
  (( SY_MS_CW > 0 )) || return 0
  local -i cw=$SY_MS_CW ch=$SY_MS_CH i q k bk y top c
  local -F bx d per
  sy_tc_scope $(( SY_MS_SX + 1 )) $(( SY_MS_SY + 1 )) $cw $ch
  # A SWEEP ABOUT THIRTY CELLS A SECOND, the card's own pace, however wide ·
  # moved fifteen times a second and not every frame, and with a shorter
  # glow behind it than the card's: on a page that stands for minutes it is
  # every frame's cost, and a frame that has not moved is a frame not sent
  per=$(( (cw + 20) / 30.0 )); (( per < 4.0 )) && per=4.0
  bx=$(( floor(SY_NOW * 15.0) / 15.0 / per )); bx=$(( (bx - floor(bx)) * (cw + 20) - 4 ))
  for (( i = int(bx) - 12; i <= int(bx); i++ )); do
    (( i < 0 || i >= cw )) && continue
    d=$(( bx - i )); (( d < 0.0 )) && continue
    q=$(( 2 + int((1.0 - d / 12.0) ** 2 * 6.0) ))
    sy_scope_col $i $q
  done
  i=$(( int(bx) ))
  if (( i >= 0 && i < cw )); then
    c=${SY_TC_INK_BEAM:-0}; (( c )) || { cmix $BLACK $CYAN 0.34; c=$CM; SY_TC_INK_BEAM=$c }
    top=${SY_TC_TOP[$i]:-0}
    bk=$(( (OY + R_SCR) * TCOLS + OX + C_SCR + SY_MS_SX + 1 + i ))
    for (( y = 0; y < ch - top; y++ )); do
      k=$(( bk + (SY_MS_SY + 1 + y) * TCOLS )); GCH[$k]='│'; GF[$k]=$c
    done
  fi
  return 0
}
sy_menu_tape() {   # sy_menu_tape X Y W H TITLE KIND — one of the three small tapes under the scope (still part)
  # MEMORY ON ITS OWN SCALE, the share of the machine's memory in use; THE
  # NETWORK AND THE DISKS ON THEIRS, the busiest moment on the tape, said on
  # the frame, at the top -- a rate has no ceiling to be drawn against
  local -i x=$1 y=$2 w=$3 h=$4 iw ih n s0 i j e8 full rem r k base lit dim deep un
  local kind=$6 rt
  local -F v mx=0.0 cur=0.0
  local -a a b
  case $kind in
    mem) a=("${SY_MEM_HIST[@]}"); n=${#a[@]}; s0=$(( n - ${SY_SEEN[SY_MEM_HIST]:-0} )); mx=100.0; lit=$P_WARM
         printf -v rt '%.0f%% USED' ${SY[mem_pct]:-0} ;;
    net) b=("${SY_TX_HIST[@]}"); a=()
         for (( i = 0; i < ${#SY_RX_HIST[@]}; i++ )); do a+=($(( ${SY_RX_HIST[$i]} + ${b[$i]:-0} ))); done
         n=${#a[@]}; s0=$(( n - ${SY_SEEN[SY_RX_HIST]:-0} )); lit=$P_FG
         printf -v rt '%.1f MB/S' $(( ${SY[net_rx]:-0} + ${SY[net_tx]:-0} )) ;;
    io)  a=("${SY_IO_HIST[@]}"); n=${#a[@]}; s0=$(( n - ${SY_SEEN[SY_IO_HIST]:-0} )); lit=$AMBER
         printf -v rt '%.1f MB/S' $(( ${SY[io_r]:-0} + ${SY[io_w]:-0} )) ;;
  esac
  (( s0 < 0 )) && s0=0
  if [[ $kind != mem ]]; then
    for (( i = s0; i < n; i++ )); do (( a[i] > mx )) && mx=${a[$i]}; done
    (( mx < 0.1 )) && mx=0.1
  fi
  sy_scope_frame $x $y $(( w - 2 )) $(( h - 2 )) "$5" "$rt"
  iw=$(( w - 2 )); ih=$(( h - 2 ))
  cshade $lit 0.46; dim=$CS; cshade $lit 0.26; deep=$CS
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for (( i = 0; i < iw; i++ )); do
    if (( n > 1 )); then j=$(( int(i * (n - 1) / (iw > 1 ? iw - 1.0 : 1.0)) )); else j=0; fi
    k=$(( base + (y + ih) * TCOLS + x + 1 + i ))
    if (( ! n || j < s0 )); then
      cshade $lit 0.30; GCH[$k]='┄'; GF[$k]=$CS; continue
    fi
    v=${a[$j]}
    e8=$(( int(v / mx * ih * 8.0 + 0.5) )); (( e8 < 1 )) && e8=1; (( e8 > ih * 8 )) && e8=$(( ih * 8 ))
    full=$(( e8 / 8 )); rem=$(( e8 % 8 ))
    for (( r = 0; r < full; r++ )); do
      k=$(( base + (y + ih - r) * TCOLS + x + 1 + i )); GCH[$k]=' '
      if (( ! rem && r == full - 1 )); then GB[$k]=$lit
      elif (( (rem ? full - r : full - 1 - r) == 1 )); then GB[$k]=$dim
      else GB[$k]=$deep; fi
    done
    if (( rem )); then
      k=$(( base + (y + ih - full) * TCOLS + x + 1 + i )); GCH[$k]="${SY_TC_EIGHTHS[$rem]}"; GF[$k]=$lit
    fi
  done
  return 0
}
sy_draw_menu_base() { sy_draw_menu $SY_NOW }

# ══════════════════════════════════════════════════════════════════════════
# OVERVIEW · the machine at once
# ══════════════════════════════════════════════════════════════════════════
# THE PAGE IS THREE COLUMNS AND A TICKER, and the two rules between them are
# the whole layout: twenty-six cells of tapes on the left, a forty-four cell
# scope in the middle, thirty cells of gauges and lists on the right.  The
# numbers below are system.py's own and are not adjustable -- a column that
# moved would put the scope's braille on a half-cell and blur every dot in it.
typeset -gi SY_LW=26 SY_RULE1=27 SY_SC0=29 SY_SCW=44 SY_RULE2=74 SY_R0=76 SY_RW=30
# THE THREE COLUMNS FOLLOW THE GLASS.  On the cabinet's fixed screen they carry
# the exact numbers above, to the cell.  On the whole window (SCREEN=fill) they
# scale by the same ratios -- the scope keeps the widest share -- so OVERVIEW
# reads as the same page, wider.  Recomputed each frame; integer, so cheap.
typeset -gi SY_L=2 SY_R=54 SY_W=50   # the two-column pages · left, right, width
sy_geom() {
  if (( SCR_W > 120 )); then
    SY_LW=$(( SCR_W * 26 / 106 )); (( SY_LW < 26 )) && SY_LW=26
    SY_RULE1=$(( SY_LW + 1 )); SY_SC0=$(( SY_RULE1 + 2 ))
    SY_R0=$(( SCR_W - SCR_W * 30 / 106 )); SY_RW=$(( SCR_W - SY_R0 ))
    SY_RULE2=$(( SY_R0 - 2 )); SY_SCW=$(( SY_RULE2 - 1 - SY_SC0 ))
    (( SY_SCW < 8 )) && SY_SCW=8
    # the two even columns · a gutter of two between them and one at each edge
    SY_L=2; SY_W=$(( (SCR_W - 6) / 2 )); SY_R=$(( SY_L + SY_W + 2 ))
    # PROCESSES fills its glass · the table takes every row between the header
    # (four) and the footer (two), and its last column runs to the right edge
    SY_PROW=$(( SCR_H - 6 )); (( SY_PROW < 4 )) && SY_PROW=4
    SY_PC_W[8]=$(( SCR_W - 70 )); (( SY_PC_W[8] < 20 )) && SY_PC_W[8]=20
  else
    SY_LW=26; SY_RULE1=27; SY_SC0=29; SY_SCW=44; SY_RULE2=74; SY_R0=76; SY_RW=30
    SY_L=2; SY_W=50; SY_R=54
    SY_PROW=23; SY_PC_W[8]=36
  fi
  return 0
}
SY_LVL=(' ' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
SY_RANGES=(20 40 80 100)
typeset -gi SY_RANGE=1        # which ring the scale ends on
typeset -gi SY_SORT=0         # 0 CPU · 1 MEM · 2 PID · 3 NAME
SY_SORTN=(CPU MEM PID NAME)
typeset -gi SC_R1=11 SC_R2=21 SC_R3=31 SC_RIM=41 SC_CORE=7
# THE SCOPE'S CENTRE AND SIZE FOLLOW THE GLASS.  On the cabinet screen the
# centre sits at braille (44,44) with a rim of 41 -- the exact numbers the
# whole radar was drawn to -- and on the whole window the circle grows to
# fill the wider, taller middle column, still round because a braille dot is
# as wide as it is tall on this tube.  sy_scope_dims sets them each frame.
typeset -gi SC_CX=44 SC_CY=44 SC_SPH=22 SC_GEOM_SIG=-1
SC_SWEEP=0.24                 # how far the phosphor trails the beam, in radians
SC_GLIDE=1.50
SY_PI=3.14159265358979323846
SY_TAU=6.28318530717958647692

# ── the scope's geometry, worked out once ─────────────────────────────────
# ONLY THE COLOURS MOVE.  Every ring dot and every bearing tick sits where it
# sat last frame; what the sweep changes is how brightly each one is lit.  So
# the trigonometry is done on the first frame and never again -- which in a
# shell is the difference between a page that draws and a page that does not.
typeset -ga SGX SGY SGA STX STY STA
typeset -gi SGN=0 STN=0
sy_scope_geom() {
  # rebuilt only when the centre or the rim actually moves · a resize does,
  # a frame does not, so the trigonometry stays a first-frame cost
  local -i sig=$(( SC_CX * 1000000 + SC_CY * 1000 + SC_RIM ))
  (( SGN && SC_GEOM_SIG == sig )) && return 0
  SC_GEOM_SIG=$sig
  local -F a ba
  local -i r n k i rr dk solid t0 t1 tup
  local -a rs sl
  rs=($SC_R1 $SC_R2 $SC_R3 $SC_RIM); sl=(1 0 0 1)
  SGX=(); SGY=(); SGA=()
  for (( i = 0; i < 4; i++ )); do
    r=${rs[$i]}; solid=${sl[$i]}
    n=$(( int(SY_TAU * r * 1.6) )); (( n < 24 )) && n=24
    for (( k = 0; k <= n; k++ )); do
      if (( ! solid )); then
        dk=$(( int(k * 18.0 / n) ))
        (( dk % 2 )) && continue
      fi
      a=$(( SY_TAU * k / n ))
      SGX+=($(( SC_CX + cos(a) * r ))); SGY+=($(( SC_CY + sin(a) * r ))); SGA+=($a)
    done
  done
  SGN=${#SGX[@]}
  STX=(); STY=(); STA=()
  t0=$(( SC_RIM * 37 / 41 )); t1=$(( SC_RIM * 42 / 41 )); tup=$(( SC_RIM + 3 ))
  for (( i = 0; i < 12; i++ )); do          # bearing ticks, cardinals longer
    ba=$(( i * SY_PI / 6 - SY_PI / 2 ))
    for (( rr = (i % 3 == 0 ? t0 : t1); rr < tup; rr++ )); do
      STX+=($(( SC_CX + cos(ba) * rr ))); STY+=($(( SC_CY + sin(ba) * rr ))); STA+=($ba)
    done
  done
  STN=${#STX[@]}
  return 0
}

sy_scope_dims() {   # centre, plot height and ring radii for the current glass
  local -i sph srim
  # rows 2 down to the caption (5) and the ticker (2) below it
  if (( SCR_W > 120 )); then sph=$(( SCR_H - 8 )); else sph=22; fi
  (( sph < 10 )) && sph=10
  SC_SPH=$sph
  SC_CX=$SY_SCW                 # the middle of a plot 2·SY_SCW braille wide
  SC_CY=$(( 2 * sph ))          # the middle of a plot 4·sph braille tall
  srim=$(( (SY_SCW < 2 * sph ? SY_SCW : 2 * sph) - 3 ))
  (( srim < 8 )) && srim=8
  SC_RIM=$srim
  SC_R3=$(( srim * 31 / 41 )); SC_R2=$(( srim * 21 / 41 ))
  SC_R1=$(( srim * 11 / 41 )); SC_CORE=$(( srim * 7 / 41 ))
  return 0
}

sy_arc() {   # sy_arc CX CY R A0 A1 COL [PRI]
  local -F cx=$1 cy=$2 r=$3 a0=$4 a1=$5 a
  local -i col=$6 pri=${7:-1} n k
  local -i px py pi
  n=$(( int(abs(a1 - a0) * r * 1.6) )); (( n < 24 )) && n=24
  for (( k = 0; k <= n; k++ )); do
    a=$(( a0 + (a1 - a0) * k / n ))
    # sy_dot, written out (see sy_plot_line for why)
    px=$(( int(cx + cos(a) * r + 0.5) )); py=$(( int(cy + sin(a) * r + 0.5) ))
    (( px < 0 || py < 0 || px >= PW || py >= PH )) && continue
    pi=$(( (py >> 2) * PWC + (px >> 1) ))
    if (( SY_BLOCKS )); then PB[$pi]=$(( PB[pi] | (1 << ((((py & 3) >> 1) * 2) + (px & 1))) ))
    else PB[$pi]=$(( PB[pi] | SY_MSK[((px & 1) << 2) | (py & 3)] )); fi
    (( pri >= PP[pi] )) && { PP[$pi]=$pri; PC[$pi]=$col }
  done
  return 0
}

# ── the ordering · which process is nearest, and which six are listed ──────
# A SORT IN A SHELL IS A SORT OF STRINGS, so the key is built to sort right
# as text: the number padded to a fixed width so lexical order is numeric
# order, and the index carried INVERTED behind it so that two processes on
# the same reading come out in the order they were read.  Without that last
# part a reverse sort would put ties in backwards order and the six names
# under RETURNS would shuffle every time two of them levelled off.
typeset -ga SY_ORD
typeset -gA SY_ORD_MEMO
sy_order() {   # sy_order KEY — cpu | mem | pid | name
  # ...AND SORTED ONCE PER READING.  The order can only change when ps has
  # been read again, so the answer is kept against the reading's serial and
  # the four pages that ask for it every frame get it for the price of a
  # lookup.
  local memo="$SY_SERIAL|$SY_N_PROCS"
  if [[ "${SY_ORD_MEMO[key.$1]:-}" == "$memo" ]]; then
    SY_ORD=(${=SY_ORD_MEMO[ord.$1]})
    return 0
  fi
  # THE KEYS ARE BUILT WITH THE SHELL'S OWN printf -v.  A `$(printf …)` is a
  # fork, and this ran one per process per frame on four of the nine pages:
  # a hundred forks to sort a hundred processes, five hundred on a busy Mac,
  # every frame -- the whole of the PROCESSES page's frame budget and then
  # some, spent on a sort whose answer changes once every ten seconds.
  local -a k
  local -i i n=$SY_N_PROCS j
  local e
  k=()
  case "$1" in
    pid)  for (( i = 0; i < n; i++ )); do
            printf -v e '%012d%03d' ${SY[procs.$i.pid]} $i; k+=("$e"); done
          SY_ORD=("${(@o)k[@]}") ;;
    name) for (( i = 0; i < n; i++ )); do
            printf -v e '%03d' $i; k+=("${SY[procs.$i.cmd]}"$'\t'"$e"); done
          SY_ORD=("${(@o)k[@]}") ;;
    rss)  for (( i = 0; i < n; i++ )); do
            printf -v e '%015d%03d' ${SY[procs.$i.rss]} $(( 999 - i )); k+=("$e"); done
          SY_ORD=("${(@O)k[@]}") ;;
    mem)  for (( i = 0; i < n; i++ )); do
            printf -v e '%09d%03d' $(( int(${SY[procs.$i.mem]} * 1000) )) $(( 999 - i )); k+=("$e"); done
          SY_ORD=("${(@O)k[@]}") ;;
    *)    for (( i = 0; i < n; i++ )); do
            printf -v e '%09d%03d' $(( int(${SY[procs.$i.cpu]} * 1000) )) $(( 999 - i )); k+=("$e"); done
          SY_ORD=("${(@O)k[@]}") ;;
  esac
  # back to plain indices
  for (( i = 0; i < ${#SY_ORD[@]}; i++ )); do
    e="${SY_ORD[$i]}"
    case "$1" in
      pid)  SY_ORD[$i]=$(( 10#${e[-3,-1]} )) ;;
      rss)  SY_ORD[$i]=$(( 999 - 10#${e[-3,-1]} )) ;;
      name) SY_ORD[$i]=$(( 10#${e#*$'\t'} )) ;;
      *)    SY_ORD[$i]=$(( 999 - 10#${e[-3,-1]} )) ;;
    esac
  done
  SY_ORD_MEMO[key.$1]="$memo"; SY_ORD_MEMO[ord.$1]="${(j: :)SY_ORD[@]}"
  return 0
}

# ── one tape · a label, a reading, a bar and the scale under it ────────────
sy_draw_tape() {   # sy_draw_tape Y LABEL FRAC VAL S0 S1 S2
  local -i y=$1
  local -F f=$3
  sy_ease "tape.$2" $f; f=$SMF
  v_text 0 $y "$2" $P_LBL
  sy_right $(( SY_LW - 1 )) $y "$4" $P_FG
  local d='' i
  for (( i = 0; i < SY_LW; i++ )); do d+='░'; done
  v_text 0 $(( y + 1 )) "$d" $P_DIM
  sy_hbar $SY_LW $f; sy_tone $f
  v_text 0 $(( y + 1 )) "$BAR" $TON
  v_text 0  $(( y + 2 )) "$5" $P_DIM
  v_text 12 $(( y + 2 )) "$6" $P_DIM
  sy_right $(( SY_LW - 1 )) $(( y + 2 )) "$7" $P_DIM
  return 0
}

# ── one gauge · a dial with a redline and a needle ────────────────────────
sy_draw_gauge() {   # sy_draw_gauge GX GY GW FRAC VAL UNIT LABEL HOT
  local -i gx=$1 gy=$2 gw=$3 hot=$8 i ink mid
  local -F f=$4 a0 span cx cy ta na
  local val="$5" unit="$6" lab="$7" cap
  a0=$(( SY_PI * 0.75 )); span=$(( SY_PI * 1.5 )); cx=$gw; cy=10
  (( f < 0.0 )) && f=0.0
  (( f > 1.0 )) && f=1.0
  sy_ease "gauge.$lab" $f; f=$SMF
  sy_plot_new $gw 5
  sy_arc $cx $cy 7 $a0 $(( a0 + span )) $P_DIM 1
  sy_arc $cx $cy 7 $(( a0 + span * 0.85 )) $(( a0 + span )) $RED 2
  (( hot )) && ink=$P_HOT || ink=$P_FG
  sy_arc $cx $cy 7 $a0 $(( a0 + span * f )) $ink 3
  for (( i = 0; i < 11; i++ )); do
    ta=$(( a0 + span * (i / 10.0) ))
    sy_dot $(( cx + cos(ta) * 9.5 )) $(( cy + sin(ta) * 9.5 )) \
           $(( i >= 9 ? RED : P_DIM )) 1
  done
  na=$(( a0 + span * f ))
  (( hot )) && ink=$P_HOT || ink=$P_WHITE
  sy_plot_line $(( cx + cos(na) * 4 )) $(( cy + sin(na) * 4 )) \
               $(( cx + cos(na) * 7 )) $(( cy + sin(na) * 7 )) $ink 6
  sy_plot_blit $gx $gy
  mid=$(( gx + gw / 2 ))
  (( hot )) && ink=$P_HOT || ink=$P_WHITE
  v_text $(( mid - ${#val} / 2 )) $(( gy + 2 )) "$val" $ink
  cap="$lab $unit"
  v_text $(( mid - ${#cap} / 2 )) $(( gy + 5 )) "$cap" $P_LBL
  return 0
}

# ── how far out a process sits · its share of one core ────────────────────
# IDLE IS THE RIM AND THE RANGE IS THE INNERMOST RING.  Past the range it
# keeps closing, into the dead space inside that ring, so a runaway reads as
# a runaway instead of being pinned in a heap with everything else maxed.
sy_scope_radius() {   # sy_scope_radius CPU FS -> SR
  local -F c=$1 fs=$2 f
  f=$(( c / fs ))
  if (( f <= 1.0 )); then
    (( f < 0.0 )) && f=0.0
    SR=$(( SC_RIM - (SC_RIM - SC_R1) * f ))
  else
    f=$(( (f - 1.0) * 0.5 )); (( f > 1.0 )) && f=1.0
    SR=$(( SC_R1 - (SC_R1 - SC_CORE) * f ))
  fi
  return 0
}

# ── where each contact sat at the LAST reading ────────────────────────────
# A RADAR THAT ONLY EVER SHOWS NOW CANNOT SHOW A THING CLOSING.  The process
# list is one of the readings that cannot interpolate -- the rows are
# different rows -- so without a reading of history every contact jumped once
# every ten seconds.  Keyed on the range as well, because changing the range
# moves every contact at once and that is not motion.
typeset -gA SC_WAS SC_NOW
SC_KEY=''
SC_T0=0.0
SC_KG=0.0
sy_scope_tracks() {   # sy_scope_tracks FS T
  local -F fs=$1 t=$2 k
  local key="$SY_SERIAL/$fs"
  local -i i n=$SY_N_PROCS same=0
  if [[ "$key" != "$SC_KEY" ]]; then
    [[ -n "$SC_KEY" && "${SC_KEY#*/}" == "$fs" ]] && same=1
    SC_KEY="$key"
    SC_WAS=()
    if (( same )); then
      # `${(k)SC_NOW}` IS ELEMENT ZERO, NOT THE KEYS -- the same trap the
      # sort sites carry a note about, and worse here: the one thing it does
      # hand back is a VALUE, `i` is an integer so the radius truncates to
      # 7..41, and `${SC_NOW[$i]}` on a table keyed by PID is then an unset
      # key under `set -u`, which ends the whole program.  It could not fire
      # on the opening frame -- SC_KEY is empty, so `same` is 0 -- so the
      # page ran for one reading and then took the window with it.
      for i in ${(k)SC_NOW[@]}; do SC_WAS[$i]="${SC_NOW[$i]:-}"; done
    fi
    SC_NOW=()
    for (( i = 0; i < n; i++ )); do
      sy_scope_radius ${SY[procs.$i.cpu]} $fs
      SC_NOW[${SY[procs.$i.pid]}]=$SR
    done
    SC_T0=$t
  fi
  k=$(( (t - SC_T0) / SC_GLIDE ))
  (( k < 0.0 )) && k=0.0
  (( k > 1.0 )) && k=1.0
  SC_KG=$(( k * k * (3.0 - 2.0 * k) ))
  return 0
}


# ── an angle, brought back into one turn ──────────────────────────────────
# `%` IS AN INTEGER OPERATOR IN A SHELL and these are radians, so the modulo
# every bearing on the scope depends on has to be written out.  Python's `%`
# on floats already answers in [0, tau); this is that, and the second line is
# what makes it true for the negative case as well.
sy_wrap() { WR=$(( $1 - int($1 / SY_TAU) * SY_TAU )); (( WR < 0.0 )) && WR=$(( WR + SY_TAU )); }

# a size of blip, as offsets from its middle · a contact has to survive being
# one dot in a field of ring dots, so the steps are solid clusters rather than
# a dot growing a cross
SY_SIZES=(
  '0,0'
  '0,0 1,0 0,1 1,1'
  '0,0 1,0 -1,0 0,1 0,-1 1,1 -1,1 1,-1 -1,-1'
  '0,0 1,0 -1,0 0,1 0,-1 1,1 -1,1 1,-1 -1,-1 2,0 -2,0 0,2 0,-2'
)
SY_TICK_TXT=''
SY_TICK_AT=-99.0

sy_draw_scope() {   # sy_draw_scope T — OVERVIEW · the machine at once
  local -F t=$1
  local -i i j k n y x col gi rw sz pri nshow topid has_was
  local -F v f e mx pk cpu rx tx io mt dt_ net_fs io_fs
  local -a by_cpu ordered hist
  local s s2 nm

  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  sy_scope_dims
  local -i np=$SY_N_PROCS ncpu=${SY[ncpu]:-1}
  (( ncpu < 1 )) && ncpu=1
  sy_order cpu; by_cpu=("${SY_ORD[@]}")
  case $SY_SORT in
    0) ordered=("${by_cpu[@]}") ;;
    *) sy_order "${SY_SORTN[$SY_SORT]:l}"; ordered=("${SY_ORD[@]}") ;;
  esac

  # ── the header · on the suite's title bar, like every other page ─────────
  # OVERVIEW used to wear a dense identity line of its own (HOST/CPU/PROC/THR).
  # The brand and the sky's caption take the ends of the bar now, and on the
  # fixed cabinet there is no room left for all four -- so the line is shown
  # only where the glass is wide enough to hold it, and yields to the title,
  # the uptime and the caption where it is not.  (HOST and CPU are on the list
  # page's readings besides.)
  sy_page_head OVERVIEW
  local -i hb hx=$(( APP_HX + 13 ))
  cmix $GLASS $PURPLE 0.32; hb=$CM
  if (( APP_HR - hx >= 82 )); then
    v_text $hx 0 'HOST' $P_LBL $hb;            v_text $(( hx + 5 )) 0 "${SY[host][0,13]}" $P_FG $hb
    v_text $(( hx + 21 )) 0 'CPU' $P_LBL $hb;  v_text $(( hx + 25 )) 0 "${${SY[cpu_model]:-?}[0,21]}" $P_FG $hb
    v_text $(( hx + 49 )) 0 'PROC' $P_LBL $hb; v_text $(( hx + 54 )) 0 "${SY[nproc]}" $P_FG $hb
    if (( ${SY[nthread]:-0} )); then
      v_text $(( hx + 60 )) 0 'THR' $P_LBL $hb; v_text $(( hx + 64 )) 0 "${SY[nthread]}" $P_FG $hb
    fi
  fi
  local -i rulend=$(( SCR_W > 120 ? SCR_H - 2 : 28 ))
  for (( y = 2; y < rulend; y++ )); do
    v_put $SY_RULE1 $y '│' $P_DIM
    v_put $SY_RULE2 $y '│' $P_DIM
  done

  # ── left · five tapes, the core map, the ingress trace ──────────────────
  cpu=${SY[cpu]}; rx=${SY[net_rx]}; tx=${SY[net_tx]}
  io=$(( ${SY[io_r]} + ${SY[io_w]} ))
  mt=${SY[mem_total]};  (( mt < 0.001 ))  && mt=0.001
  dt_=${SY[disk_total]}; (( dt_ < 0.001 )) && dt_=0.001
  # THE SCALE IS THE TAPE'S OWN PEAK AND NOT A FIXED CEILING.  A link that has
  # never carried more than two megabytes a second should read full at two,
  # not at a hundredth of a gigabit nobody has ever seen out of it.
  mx=0.0; for v in "${SY_RX_HIST[@]}"; do (( v > mx )) && mx=$v; done
  net_fs=$(( mx * 1.25 )); (( net_fs < 1.0 )) && net_fs=1.0
  mx=0.0; for v in "${SY_IO_HIST[@]}"; do (( v > mx )) && mx=$v; done
  io_fs=$(( mx * 1.25 )); (( io_fs < 1.0 )) && io_fs=1.0

  printf -v s '%.1f%%' $cpu
  sy_draw_tape 2 PROCESSOR $(( cpu / 100.0 )) "$s" '0' '50' '100'
  sy_human_g ${SY[mem_used]}; s="$HG"
  sy_human_g $(( mt / 2 ));   s2="$HG"
  sy_human_g $mt;             nm="$HG"
  sy_draw_tape 5 MEMORY $(( ${SY[mem_used]} / mt )) "$s" '0' "$s2" "$nm"
  printf -v s  '%.1fM' $rx
  printf -v s2 '%.0fM' $(( net_fs / 2 ))
  printf -v nm '%.0fM' $net_fs
  sy_draw_tape 8 INGRESS $(( rx / net_fs )) "$s" '0' "$s2" "$nm"
  sy_human_g ${SY[disk_used]}; s="$HG"
  sy_human_g $(( dt_ / 2 ));   s2="$HG"
  sy_human_g $dt_;             nm="$HG"
  sy_draw_tape 11 'VOLUME /' $(( ${SY[disk_used]} / dt_ )) "$s" '0' "$s2" "$nm"
  printf -v s  '%.1fM' $io
  printf -v s2 '%.0fM' $(( io_fs / 2 ))
  printf -v nm '%.0fM' $io_fs
  sy_draw_tape 14 'DISK I/O' $(( io / io_fs )) "$s" '0' "$s2" "$nm"

  # ── the core map · one column a core, or the hottest of its bin ─────────
  local -i ncore=$SY_N_CORES cw ncol lo hi
  (( ncore < 1 )) && ncore=1
  mx=0.0
  for (( i = 0; i < ncore; i++ )); do v=${SY[cores.$i]}; (( v > mx )) && mx=$v; done
  v_text 0 18 'CORE MAP' $P_LBL
  printf -v s '%d × %.0f%%' $ncore $mx
  sy_right $(( SY_LW - 1 )) 18 "$s" $P_FG
  cw=$(( 24 / ncore )); (( cw < 1 )) && cw=1
  ncol=$(( 24 / cw )); (( ncol > ncore )) && ncol=$ncore
  for (( i = 0; i < ncol; i++ )); do
    lo=$(( i * ncore / ncol )); hi=$(( (i + 1) * ncore / ncol ))
    (( hi <= lo )) && hi=$(( lo + 1 ))
    v=0.0
    for (( j = lo; j < hi; j++ )); do (( ${SY[cores.$j]} > v )) && v=${SY[cores.$j]}; done
    if   (( v > 85 )); then col=$P_HOT
    elif (( v > 60 )); then col=$P_WARM
    else                    col=$P_FG; fi
    e=$(( v / 100.0 * 24 ))
    for (( rw = 0; rw < 3; rw++ )); do
      gi=$(( int(e - (2 - rw) * 8 + 0.5) ))
      (( gi < 0 )) && gi=0; (( gi > 8 )) && gi=8
      for (( k = 0; k < cw; k++ )); do
        v_put $(( 1 + i * cw + k )) $(( 19 + rw )) "${SY_LVL[$gi]}" $col
      done
    done
  done
  v_text 1 22 '01' $P_DIM
  printf -v s '%02d' $ncore
  sy_right $(( 1 + ncol * cw - 1 )) 22 "$s" $P_DIM

  # ── the link, as two rows of blocks ────────────────────────────────────
  nm="${SY[net_if]:-}"; [[ -n "$nm" ]] || nm='-'
  v_text 0 24 "NET ${nm[0,5]}" $P_LBL
  printf -v s 'rx %.1f MB/s' $rx
  sy_right $(( SY_LW - 1 )) 24 "$s" $P_FG
  n=${#SY_RX_HIST[@]}; i=$(( n - SY_LW )); (( i < 0 )) && i=0
  hist=("${SY_RX_HIST[@]:$i}")
  pk=0.000001
  for v in "${hist[@]}"; do (( v > pk )) && pk=$v; done
  # two rows of blocks on the cabinet, a tall waterfall on the whole window
  local -i nb=$(( SCR_H - 4 )) nR hh
  nR=$(( nb - 24 ))
  for (( i = 0; i < ${#hist[@]}; i++ )); do
    v=${hist[$i]}; f=$(( v / pk )); e=$(( f * 8 * nR ))
    sy_tone $(( f * 0.7 )); col=$TON
    for (( hh = 0; hh < nR; hh++ )); do
      gi=$(( int(e - 8 * hh + 0.5) )); (( gi < 0 )) && gi=0; (( gi > 8 )) && gi=8
      v_put $i $(( nb - hh )) "${SY_LVL[$gi]}" $col
    done
  done
  printf -v s 'tx %.1f' $tx;    v_text 0 $(( SCR_H - 3 )) "$s" $P_LBL
  printf -v s 'peak %.0f' $pk;  sy_right $(( SY_LW - 1 )) $(( SCR_H - 3 )) "$s" $P_DIM

  # ── centre · the scope ─────────────────────────────────────────────────
  sy_scope_geom
  sy_plot_new $SY_SCW $SC_SPH
  local -F a aa g d kk rad r0 r1 r bx by cs_ sn_ mm dth
  local had
  local -i rr nn ti warm hc moved px py pi
  a=$(( (t - int(t / 4.6) * 4.6) / 4.6 * SY_TAU - SY_PI / 2 ))

  # THE AFTERGLOW, LAID DOWN BY RADIUS AND NOT BY ANGLE.  Hairlines three
  # degrees apart read as three lines and leave a gap at the rim, because
  # lines from a common centre pile up near it; one dot's worth of arc at
  # every radius is even the whole way out and costs a couple of hundred dots
  # instead of a full line at every angle.
  local -a trail
  for (( j = 0; j < 6; j++ )); do
    cmix $P_DIM $P_FG $(( 0.5 * (1.0 - j / 6.0) ** 2.0 ))
    trail+=($CM)
  done
  for (( rr = SC_CORE; rr <= SC_RIM; rr++ )); do
    nn=$(( int(SC_SWEEP * rr * 1.2) + 1 ))
    for (( j = 1; j <= nn; j++ )); do
      g=$(( 1.0 - j / (nn + 0.0) ))
      # an ordered stipple keyed on the dot's own coordinates, so the glow
      # thins into the dark instead of ending in a wall, and the pattern
      # turns with the beam rather than crawling under it
      if (( g < 0.8 )); then
        (( (rr * 3 + j * 5) % 8 > int(g * 9) )) && continue
      fi
      aa=$(( a - SC_SWEEP * j / nn ))
      ti=$(( int((1.0 - g) * 6) & 5 ))
      # sy_dot, written out (see sy_plot_line for why): two thousand of these
      # a frame, and the call was two thirds of each
      px=$(( int(SC_CX + cos(aa) * rr + 0.5) )); py=$(( int(SC_CY + sin(aa) * rr + 0.5) ))
      (( px < 0 || py < 0 || px >= PW || py >= PH )) && continue
      pi=$(( (py >> 2) * PWC + (px >> 1) ))
      if (( SY_BLOCKS )); then PB[$pi]=$(( PB[pi] | (1 << ((((py & 3) >> 1) * 2) + (px & 1))) ))
      else PB[$pi]=$(( PB[pi] | SY_MSK[((px & 1) << 2) | (py & 3)] )); fi
      (( 1 >= PP[pi] )) && { PP[$pi]=1; PC[$pi]=${trail[$ti]} }
    done
  done
  # the rings and the bearing ticks, lit by how lately the beam passed them
  # (sy_wrap and sy_dot, written out · a few hundred of each a frame)
  for (( i = 0; i < SGN; i++ )); do
    d=$(( a - SGA[i] )); d=$(( d - int(d / SY_TAU) * SY_TAU )); (( d < 0.0 )) && d=$(( d + SY_TAU ))
    if   (( d < 0.10 )); then col=$P_WHITE
    elif (( d < 0.36 )); then col=$P_FG
    elif (( d < 0.85 )); then col=$P_LBL
    else                      col=$P_DIM; fi
    px=$(( int(SGX[i] + 0.5) )); py=$(( int(SGY[i] + 0.5) ))
    (( px < 0 || py < 0 || px >= PW || py >= PH )) && continue
    pi=$(( (py >> 2) * PWC + (px >> 1) ))
    if (( SY_BLOCKS )); then PB[$pi]=$(( PB[pi] | (1 << ((((py & 3) >> 1) * 2) + (px & 1))) ))
    else PB[$pi]=$(( PB[pi] | SY_MSK[((px & 1) << 2) | (py & 3)] )); fi
    (( 1 >= PP[pi] )) && { PP[$pi]=1; PC[$pi]=$col }
  done
  for (( i = 0; i < STN; i++ )); do
    d=$(( a - STA[i] )); d=$(( d - int(d / SY_TAU) * SY_TAU )); (( d < 0.0 )) && d=$(( d + SY_TAU ))
    if   (( d < 0.10 )); then col=$P_WHITE
    elif (( d < 0.36 )); then col=$P_FG
    elif (( d < 0.85 )); then col=$P_LBL
    else                      col=$P_DIM; fi
    px=$(( int(STX[i] + 0.5) )); py=$(( int(STY[i] + 0.5) ))
    (( px < 0 || py < 0 || px >= PW || py >= PH )) && continue
    pi=$(( (py >> 2) * PWC + (px >> 1) ))
    if (( SY_BLOCKS )); then PB[$pi]=$(( PB[pi] | (1 << ((((py & 3) >> 1) * 2) + (px & 1))) ))
    else PB[$pi]=$(( PB[pi] | SY_MSK[((px & 1) << 2) | (py & 3)] )); fi
    (( 2 >= PP[pi] )) && { PP[$pi]=2; PC[$pi]=$col }
  done
  sy_plot_line $(( SC_CX + cos(a) * 3 )) $(( SC_CY + sin(a) * 3 )) \
               $(( SC_CX + cos(a) * SC_RIM )) $(( SC_CY + sin(a) * SC_RIM )) $P_WHITE 14

  # ── the contacts · three things about a process, in one mark ───────────
  # DISTANCE is its share of a core -- the rim is idle, the innermost ring is
  # the range, and the dead space inside that ring is past it.  SIZE is how
  # much memory it holds.  BRIGHTNESS is how long since the sweep painted it,
  # decaying the whole way round the way phosphor does.  A RING round it means
  # it was not running at the last reading; a TAIL means it has moved.  The
  # BEARING is a hash of the pid and means nothing on its own -- what it buys
  # is that a contact keeps the same bearing between readings, so it can be
  # watched closing.
  local -F fs=${SY_RANGES[$SY_RANGE]}
  sy_scope_tracks $fs $t
  has_was=${#SC_WAS[@]}
  nshow=${#by_cpu[@]}; (( nshow > 28 )) && nshow=28
  topid=-1; (( nshow )) && topid=${SY[procs.${by_cpu[0]}.pid]}
  local off
  for (( k = 0; k < nshow; k++ )); do
    i=${by_cpu[$k]}
    j=${SY[procs.$i.pid]}
    rad=$(( ((j * 37) % 360) * SY_PI / 180.0 - SY_PI / 2 ))
    sy_scope_radius ${SY[procs.$i.cpu]} $fs; r1=$SR
    r0=${SC_WAS[$j]:-$r1}
    moved=0; (( (r1 - r0 > 3.0) || (r0 - r1 > 3.0) )) && moved=1
    if (( moved )); then r=$(( r0 + (r1 - r0) * SC_KG )); else r=$r1; fi
    cs_=$(( cos(rad) )); sn_=$(( sin(rad) ))
    bx=$(( SC_CX + cs_ * r )); by=$(( SC_CY + sn_ * r ))
    v=${SY[procs.$i.cpu]}
    if   (( v > 20 )); then warm=$P_HOT
    elif (( v > 8 ));  then warm=$P_WARM
    else                    warm=$P_FG; fi
    sy_wrap $(( a - rad )); d=$WR
    kk=$(( (1.0 - d / SY_TAU) ** 2.2 ))
    if (( d < 0.18 )); then
      col=$P_WHITE; pri=24
    else
      # FROM THE DARK RATHER THAN FROM THE LABEL GREY.  A return the sweep has
      # not touched for a while should still be plainly a CONTACT, and what
      # separates it from the ring dots it is sitting among is hue, not
      # brightness -- those are all the same dim violet.
      cmix $P_DIM $warm $(( 0.45 + 0.55 * kk )); col=$CM; pri=$(( 19 + int(kk * 4) ))
    fi
    if (( moved && kk > 0.12 )) && (( (r - r0 > 1.0) || (r0 - r > 1.0) )); then
      cmix $P_DIM $warm $(( 0.35 * kk ))
      sy_plot_line $(( SC_CX + cs_ * r0 )) $(( SC_CY + sn_ * r0 )) $bx $by $CM 17
    fi
    mm=${SY[procs.$i.mem]}
    if   (( mm > 8.0 )); then sz=3
    elif (( mm > 2.5 )); then sz=2
    elif (( mm > 0.6 )); then sz=1
    else                      sz=0; fi
    for off in ${=SY_SIZES[$sz]}; do
      sy_dot $(( bx + ${off%%,*} )) $(( by + ${off##*,} )) $col $pri
    done
    if (( has_was )) && [[ -z "${SC_WAS[$j]:-}" ]] && (( kk > 0.15 )); then
      cmix $P_DIM $warm $(( 0.4 + 0.6 * kk ))
      sy_arc $bx $by 5 0.0 $SY_TAU $CM 18
    fi
    if (( j == topid )); then
      # the busiest gets a mark out on the rim, on its own bearing, in the
      # colour its name is printed in underneath.  Brackets round the blip
      # itself only crowded the middle, which is where the busiest always is.
      cmix $P_DIM $P_HOT $(( 0.4 + 0.6 * kk )); hc=$CM
      for rr in $(( SC_RIM + 1 )) $(( SC_RIM + 2 )); do
        for dth in -0.024 0.0 0.024; do
          sy_dot $(( SC_CX + cos(rad + dth) * rr )) $(( SC_CY + sin(rad + dth) * rr )) $hc 22
        done
      done
    fi
  done
  sy_dot $SC_CX $SC_CY $PINK 30
  sy_dot $(( SC_CX + 1 )) $SC_CY $PINK 30
  sy_plot_blit $SY_SC0 2

  # ── what the picture is, and what it means ─────────────────────────────
  local -i lb=$(( SC_SPH + 1 ))    # the five-line caption rides the scope's foot
  v_text $SY_SC0 2 'SCOPE' $P_DIM
  printf -v s 'RANGE %d%%' ${SY_RANGES[$SY_RANGE]}
  sy_right $(( SY_SC0 + SY_SCW - 1 )) 2 "$s" $P_DIM
  v_text $SY_SC0 $lb 'SWEEP 4.6s' $P_DIM
  # WHAT A RING IS WORTH, READ FROM THE RIM INWARDS.  Written on the rings it
  # landed among the contacts and read as noise; here it is a scale, which is
  # what it is.
  printf -v s 'RINGS 0·%d·%d·%d%%' $(( int(fs / 3.0 + 0.5) )) \
                                   $(( int(fs * 2 / 3.0 + 0.5) )) $(( int(fs) ))
  v_text $(( SY_SC0 + 10 + (29 - ${#s}) / 2 )) $lb "$s" $P_DIM
  if (( SCR_W > 120 )); then printf -v s '%d×%d' $(( 2 * SY_SCW )) $(( SY_BLOCKS ? 2 * SC_SPH : 4 * SC_SPH ))
  elif (( SY_BLOCKS )); then s='44×88'; else s='88×88'; fi
  sy_right $(( SY_SC0 + SY_SCW - 1 )) $lb "$s" $P_DIM
  printf -v s 'LOAD  %.2f  /  %.2f  /  %.2f' ${SY[load.0]} ${SY[load.1]} ${SY[load.2]}
  v_text $(( SY_SC0 + (SY_SCW - ${#s}) / 2 )) $(( lb + 1 )) "$s" $P_WHITE
  v_text $SY_SC0 $(( lb + 2 )) 'INBOARD' $P_LBL
  v_text $(( SY_SC0 + 8 ))  $(( lb + 2 )) '= busier' $P_DIM
  v_text $(( SY_SC0 + 19 )) $(( lb + 2 )) '●' $P_FG
  v_text $(( SY_SC0 + 21 )) $(( lb + 2 )) '= memory' $P_DIM
  v_text $(( SY_SC0 + 32 )) $(( lb + 2 )) '○' $P_WARM
  v_text $(( SY_SC0 + 34 )) $(( lb + 2 )) '= new' $P_DIM
  v_text $SY_SC0 $(( lb + 3 )) 'NEAREST' $P_LBL
  if (( nshow )); then
    i=${by_cpu[0]}
    sy_scope_radius ${SY[procs.$i.cpu]} $fs; r1=$SR
    # THE TEST IS ON THE RAW EXPANSION, NOT ON A TYPED COPY.  `r0` is
    # declared -F, and assigning the empty string to a float stores 0.0 --
    # so `[[ -n "$r0" ]]` was true even when there was no previous reading,
    # every radius beat the three-dot threshold against a phantom zero, and
    # NEAREST printed `▼ opening` about a contact nothing had measured twice.
    had="${SC_WAS[${SY[procs.$i.pid]}]:-}"
    r0=${had:-0.0}
    nm=''
    if [[ -n "$had" ]] && (( (r0 - r1 > 3.0) || (r1 - r0 > 3.0) )); then
      (( r1 < r0 )) && nm='  ▲ closing' || nm='  ▼ opening'
    fi
    printf -v s '%s  %.1f%%%s' "${SY[procs.$i.cmd]}" ${SY[procs.$i.cpu]} "$nm"
    v_text $(( SY_SC0 + 9 )) $(( lb + 3 )) "${s[0,33]}" $P_HOT
  fi
  v_text $SY_SC0 $(( lb + 4 )) 'TRACKED' $P_LBL
  printf -v s '%d of %d processes · %d cores' $nshow ${SY[nproc]} $ncpu
  v_text $(( SY_SC0 + 9 )) $(( lb + 4 )) "$s" $P_DIM

  # ── right · four gauges, the watch, the returns ────────────────────────
  local -i GW=14
  local -F lavg=$(( ${SY[load.0]} / ncpu ))
  printf -v s '%.2f' ${SY[load.0]}
  sy_draw_gauge $SY_R0 2 $GW $lavg "$s" '1m' 'LOAD' $(( lavg > 0.9 ))
  printf -v s '%.0f' ${SY[mem_pct]}
  sy_draw_gauge $(( SY_R0 + GW + 1 )) 2 $GW $(( ${SY[mem_pct]} / 100.0 )) "$s" '%' 'MEMORY' \
                $(( ${SY[mem_pct]} > 85 ))
  printf -v s '%.0f' $io
  sy_draw_gauge $SY_R0 8 $GW $(( io / io_fs )) "$s" 'MB/s' 'DISK' $(( io > io_fs * 0.85 ))
  printf -v s '%.1f' $(( rx + tx ))
  sy_draw_gauge $(( SY_R0 + GW + 1 )) 8 $GW $(( (rx + tx) / net_fs )) "$s" 'MB/s' 'NET' \
                $(( (rx + tx) > net_fs * 0.85 ))

  v_hline $SY_R0 14 $SY_RW '─' $P_DIM
  v_text $SY_R0 15 'ANOMALY WATCH' $P_LBL
  local -a fl fv
  local -a fh
  local -F sw=${SY[swap_used]}
  if (( sw > 0.01 )); then printf -v s '%.2f GiB' $sw; else s='none'; fi
  fl+=('swap in use'); fv+=("$s"); fh+=($(( sw > 1.0 )))
  sy_human_g ${SY[disk_free]} iB
  fl+=('volume free'); fv+=("$HG")
  fh+=($(( ${SY[disk_free]} < ${SY[disk_total]} * 0.10 )))
  nm="${SY[net_if]:-}"; [[ -n "$nm" ]] || nm='net'
  printf -v s '%d / %d since up' ${SY[net_ierr]} ${SY[net_oerr]}
  # CUMULATIVE SINCE THE LINK CAME UP.  Three CRC errors in three weeks are
  # not an anomaly, and colouring them red forever said they were.
  fl+=("${nm[0,7]} errors"); fv+=("$s")
  fh+=($(( ${SY[net_ierr]} + ${SY[net_oerr]} > 1000 )))
  if [[ "${SY[batt_pct]}" != null && -n "${SY[batt_pct]}" ]]; then
    printf -v s '%d%% %s' ${SY[batt_pct]} "${SY[batt_state][0,10]}"
  elif [[ -n "${SY[batt_state]}" && "${SY[batt_state]}" != null ]]; then
    s="${SY[batt_state][0,15]}"
  else
    s='no battery'
  fi
  i=0
  if [[ "${SY[temp]}" != null && -n "${SY[temp]}" ]]; then
    printf -v s '%.0f°C · %s' ${SY[temp]} "$s"
    (( ${SY[temp]} > 45 )) && i=1
  fi
  fl+=('power'); fv+=("$s"); fh+=($i)
  for (( k = 0; k < ${#fl[@]} && k < 4; k++ )); do
    v_text $SY_R0 $(( 16 + k )) "${fl[$k]}" $P_LBL
    (( fh[k] )) && col=$P_HOT || col=$P_FG
    sy_right $(( SCR_W - 1 )) $(( 16 + k )) "${fv[$k][0,23]}" $col
  done

  v_hline $SY_R0 20 $SY_RW '─' $P_DIM
  v_text $SY_R0 21 "RETURNS BY ${SY_SORTN[$SY_SORT]}" $P_LBL
  local -i rN=$(( SCR_H - 24 ))   # returns fill down to the ticker · six narrow
  for (( k = 0; k < rN && k < ${#ordered[@]}; k++ )); do
    i=${ordered[$k]}
    nm="${SY[procs.$i.cmd][0,19]}"
    while (( ${#nm} < 20 )); do nm+=' '; done
    v_text $SY_R0 $(( 22 + k )) "$nm" $P_LBL
    case $SY_SORT in
      1) printf -v s '%.1f%%' ${SY[procs.$i.mem]} ;;
      2) s="${SY[procs.$i.pid]}" ;;
      *) printf -v s '%.1f%%' ${SY[procs.$i.cpu]} ;;
    esac
    (( ${SY[procs.$i.cpu]} > 20 )) && col=$P_HOT || col=$P_FG
    sy_right $(( SCR_W - 1 )) $(( 22 + k )) "$s" $col
  done

  # ── the ticker · rebuilt on its own clock, read on the frame's ─────────
  v_hline 0 $(( SCR_H - 2 )) $SCR_W '─' $P_DIM
  if (( t - SY_TICK_AT > 2.0 )) || [[ -z "$SY_TICK_TXT" ]]; then
    SY_TICK_AT=$t
    local -a parts
    parts=()
    for (( k = 0; k < 6 && k < ${#by_cpu[@]}; k++ )); do
      i=${by_cpu[$k]}
      printf -v s 'PID %d %s %.1f%%   ' ${SY[procs.$i.pid]} "${SY[procs.$i.cmd]}" ${SY[procs.$i.cpu]}
      parts+=("$s")
    done
    printf -v s 'SWAP %.2f/%.2f GiB   ' ${SY[swap_used]} ${SY[swap_total]}; parts+=("$s")
    sy_human_g ${SY[disk_used]}; s="$HG"; sy_human_g ${SY[disk_total]}
    parts+=("VOLUME $s / $HG   ")
    parts+=("${SY[osname]}   ")
    parts+=("KERNEL ${SY[kernel]}   ")
    SY_TICK_TXT="${(j:·  :)parts[@]}"
    [[ -n "$SY_TICK_TXT" ]] || SY_TICK_TXT='no process data   '
  fi
  n=${#SY_TICK_TXT}; (( n < 1 )) && n=1
  i=$(( int(t * 11) % n ))
  s="$SY_TICK_TXT$SY_TICK_TXT"
  s="${s[$i,$(( i + SCR_W - 1 ))]}"
  while (( ${#s} < SCR_W )); do s+=' '; done
  v_text 0 $(( SCR_H - 1 )) "$s" $P_LBL
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE TAPES · a record of measurements, and only of measurements
# ══════════════════════════════════════════════════════════════════════════
# APPENDED ON SUCCESS AND NEVER OTHERWISE.  A tape is a record of readings
# TAKEN; putting the last one on again because this one failed writes a
# measurement nobody made, and the eye cannot tell the difference between a
# flat trace and a flat machine.  They are left out of --probe for the same
# reason system.py leaves them out: they are a record of when the sampler
# happened to start, not a reading of anything.
typeset -ga SY_CPU_HIST SY_MEM_HIST SY_RX_HIST SY_TX_HIST SY_IO_HIST SY_IOW_HIST
# AND HOW MUCH OF EACH TAPE WAS READ.  A tape starts as a row of zeros the
# length it will be; a picture of it that cannot tell those from readings
# draws a machine idle for a quarter of an hour it was not even watching
# (and says THE LAST 16 MIN of three minutes' sampling).  So each push is
# counted, up to the tape's length, and the pictures draw only what was read.
typeset -gA SY_SEEN
sy_tape() {   # sy_tape NAME CAP VALUE — push one reading, keep the last CAP
  local nm="$1"
  local -i cap=$2 seen=${SY_SEEN[$1]:-0}
  eval "$nm+=(\$3); (( \${#$nm[@]} > cap )) && $nm=(\"\${(@)$nm[\$(( \${#$nm[@]} - cap )),-1]}\")"
  (( seen < cap )) && SY_SEEN[$nm]=$(( seen + 1 ))
  return 0
}
sy_tapes_init() {
  local -i i
  SY_CPU_HIST=(); SY_MEM_HIST=(); SY_RX_HIST=(); SY_TX_HIST=()
  SY_IO_HIST=(); SY_IOW_HIST=(); SY_SEEN=()
  if (( SY_MOCK )); then
    # SIXTEEN MINUTES OF PAST, which is a reading like any other.  The scope
    # draws ninety-six samples and the card fills them over a quarter of an
    # hour; a preview taken at frame one would show an empty trace, which is a
    # true picture of a machine just switched on and a useless one of a
    # machine at work.  So demo mode arrives having already been running.
    sy_seed_run cpu_hist; SY_CPU_HIST=("${SDL[@]}")
    sy_seed_run mem_hist; SY_MEM_HIST=("${SDL[@]}")
    sy_seed_run rx_hist;  SY_RX_HIST=("${SDL[@]}")
    sy_seed_run tx_hist;  SY_TX_HIST=("${SDL[@]}")
    sy_seed_run io_hist;  SY_IO_HIST=("${SDL[@]}")
    for (( i = 0; i < ${#SY_IO_HIST[@]}; i++ )); do
      SY_IOW_HIST+=($(( ${SY_IO_HIST[$i]} * 0.28 )))
    done
    # a demo arrives having been watched all along
    SY_SEEN=(SY_CPU_HIST ${#SY_CPU_HIST[@]} SY_MEM_HIST ${#SY_MEM_HIST[@]} SY_RX_HIST ${#SY_RX_HIST[@]}
             SY_TX_HIST ${#SY_TX_HIST[@]} SY_IO_HIST ${#SY_IO_HIST[@]} SY_IOW_HIST ${#SY_IOW_HIST[@]})
  else
    for (( i = 0; i < 96; i++ )); do SY_CPU_HIST+=(0.0); SY_MEM_HIST+=(0.0); done
    for (( i = 0; i < 32; i++ )); do
      SY_RX_HIST+=(0.0); SY_TX_HIST+=(0.0); SY_IO_HIST+=(0.0); SY_IOW_HIST+=(0.0)
    done
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE PACK · what terminal.command asks of a machine, and nothing more
# ══════════════════════════════════════════════════════════════════════════
# A SURFACE IS FIVE FUNCTIONS AND FIVE STRINGS.  The cabinet stays where it
# is -- one process, one beat, one governor, one set of walls -- and a machine
# hands it the readings, the picture, the key map and the words that go on its
# own chrome.  Naming them through variables rather than by convention is what
# lets the next machine be written without touching the door.
# ══════════════════════════════════════════════════════════════════════════
# THE TITLE CARD · the monitor's face, at its door (terminal.command's tc_*)
# ══════════════════════════════════════════════════════════════════════════
# THE NAME IN LIGHTS, AND UNDER IT THE MACHINE'S OWN PULSE: the processor's
# last quarter of an hour on a scope -- a ruled screen, and a beam sweeping
# it that leaves the trace bright where it has just been and fading back to
# its own glow, the way phosphor does.  As the card comes up the beam's first
# pass is the one that draws the trace onto the empty screen.  Under it the
# meters anybody opens a monitor to read, and the load.  Nothing on it is
# made up: the trace is SY_CPU_HIST and the figures are this reading's.
typeset -g  SY_TC_KEY=''                        # the reading the scope's cells were worked out for
typeset -ga SY_TC_K SY_TC_G SY_TC_R SY_TC_D SY_TC_CS   # each lit cell: where, its glyph, its row, how far under the line · each column's first
typeset -ga SY_TC_UN                             # each column: 1 while the time it stands for has not been read yet
typeset -ga SY_TC_TOP                            # each column's highest lit row, for the beam's own line
typeset -ga SY_TC_INK                            # per row, thirty-two inks · see sy_tc_inks
SY_TC_EIGHTHS=(' ' '▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
sy_tc_scope() {   # sy_tc_scope X Y W H — work the trace into cells, once a reading
  # IN EIGHTHS OF A CELL, so the trace has the shape the readings had rather
  # than a staircase of half rows.  THE SCALE IS THE PROCESSOR'S OWN: the
  # floor is idle and the top of the screen is every core flat out, so a
  # quarter-busy machine draws a quarter of the way up (scaled to its own
  # peak, a steady quarter hour at a quarter load stood the full height of
  # the screen, a slab saying nothing) -- and the inks keep their meaning:
  # the processor's cyan low down, the warm violet halfway, the hot magenta
  # only when it is really working.  Each column is the reading it stands
  # for: its top lit like the line on a scope, the glow under it falling
  # away below the line, and an idle second the scope's floor, lit.
  local -i x=$1 y=$2 w=$3 h=$4 n i j r e8 full rem base k q d s0
  local -F v
  local key="$SY_GEN|$x|$y|$w|$h|$OX|$OY|$C_SCR|$R_SCR|$TCOLS|${#SY_CPU_HIST[@]}|${SY_CPU_HIST[-1]:-0}|${SY_SEEN[SY_CPU_HIST]:-0}"
  [[ "$key" == "$SY_TC_KEY" ]] && return 0
  SY_TC_KEY="$key"; SY_TC_K=(); SY_TC_G=(); SY_TC_R=(); SY_TC_D=(); SY_TC_CS=(); SY_TC_TOP=(); SY_TC_UN=()
  sy_tc_inks $h
  n=${#SY_CPU_HIST[@]}
  # the readings the tape started with, before anything was read, are not
  # drawn as a machine at rest · they are the part of the screen still to fill
  s0=$(( n - ${SY_SEEN[SY_CPU_HIST]:-0} )); (( s0 < 0 )) && s0=0
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for (( i = 0; i < w; i++ )); do
    SY_TC_CS+=(${#SY_TC_K[@]})
    if (( ! n )); then SY_TC_TOP+=(0); SY_TC_UN+=(1); continue; fi
    if (( n > 1 )); then j=$(( int(i * (n - 1) / (w > 1 ? w - 1.0 : 1.0)) )); else j=0; fi
    if (( j < s0 )); then SY_TC_TOP+=(0); SY_TC_UN+=(1); continue; fi
    SY_TC_UN+=(0)
    v=${SY_CPU_HIST[$j]}
    e8=$(( int(v / 100.0 * h * 8.0 + 0.5) )); (( e8 < 1 )) && e8=1; (( e8 > h * 8 )) && e8=$(( h * 8 ))
    full=$(( e8 / 8 )); rem=$(( e8 % 8 ))
    for (( r = 0; r < full; r++ )); do
      k=$(( base + (y + h - 1 - r) * TCOLS + x + i ))
      # how far under the line · 0 the line itself, 3 and on the glow's floor
      if (( rem )); then d=$(( full - r )); else d=$(( full - 1 - r )); fi
      (( d > 3 )) && d=3
      SY_TC_K+=($k); SY_TC_R+=($r); SY_TC_G+=('█'); SY_TC_D+=($d)
    done
    if (( rem )); then
      k=$(( base + (y + h - 1 - full) * TCOLS + x + i ))
      SY_TC_K+=($k); SY_TC_R+=($full); SY_TC_G+=("${SY_TC_EIGHTHS[$rem]}"); SY_TC_D+=(0)
    fi
    SY_TC_TOP+=($(( full + (rem ? 1 : 0) )))
  done
  SY_TC_CS+=(${#SY_TC_K[@]})
  return 0
}
typeset -g  SY_TC_INKKEY=''
sy_tc_inks() {   # sy_tc_inks H — the trace's inks for a scope H rows tall, worked out once
  # PER ROW, from the processor's cyan at the floor through the warm violet
  # to the hot magenta at the top (the tapes' own ramp); in each row the line
  # itself and three depths of glow under it; and each of those in eight
  # steps -- dim, its own, and whitened six ways as the beam goes over
  local -i h=$1 r dl q lit c
  local -F f
  local -a fd; fd=(1.0 0.50 0.32 0.20)
  local key="$h|$P_FG|$P_WARM|$P_HOT|$WHITE"
  [[ "$key" == "$SY_TC_INKKEY" ]] && return 0
  SY_TC_INKKEY="$key"; SY_TC_INK=()
  for (( r = 0; r < h; r++ )); do
    f=$(( (r + 0.5) / h ))
    if (( f < 0.5 )); then cmix $P_FG $P_WARM $(( f * 2.0 )); else cmix $P_WARM $P_HOT $(( (f - 0.5) * 2.0 )); fi
    lit=$CM
    for (( dl = 0; dl < 4; dl++ )); do
      if (( dl )); then cshade $lit ${fd[$dl]}; c=$CS; else c=$lit; fi
      cshade $c 0.30; SY_TC_INK+=($CS $c)
      for q in 1 2 3 4 5 6; do
        if (( dl )); then cmix $c $WHITE $(( q / 14.0 )); else cmix $c $WHITE $(( q / 9.0 )); fi
        SY_TC_INK+=($CM)
      done
    done
  done
  return 0
}
# THE SCOPE'S PIECES, the card's and the list page's alike · a column of
# the trace at a glow, the frame and its ruled screen, the trace at rest
sy_scope_col() {   # sy_scope_col I Q — the trace's column I at glow Q (1 its own · 2..7 whitened by the beam)
  local -i c e r q=$2
  (( q > 7 )) && q=7
  e=${SY_TC_CS[$(( $1 + 1 ))]}
  for (( c = SY_TC_CS[$1]; c < e; c++ )); do
    r=$(( SY_TC_R[c] * 32 + SY_TC_D[c] * 8 + q ))
    # a whole cell is lit as its ground, so a column is one piece of light
    # rather than a stack of tiles (a font's block glyph leaves a seam round
    # itself); the part cell on top is its eighth's glyph
    if [[ "${SY_TC_G[$c]}" == '█' ]]; then GCH[${SY_TC_K[$c]}]=' '; GB[${SY_TC_K[$c]}]=${SY_TC_INK[$r]}
    else GCH[${SY_TC_K[$c]}]="${SY_TC_G[$c]}"; GF[${SY_TC_K[$c]}]=${SY_TC_INK[$r]}; fi
  done
  return 0
}
sy_scope_frame() {   # sy_scope_frame X Y CW CH TITLE [RIGHT] — the box (CW × CH inside), its graticule, its ticks, its labels
  # THE GRATICULE, faint enough to read a trace against and no more: a dot
  # at every crossing of the divisions, eight across, and the ticks where
  # the divisions meet the frame
  local -i sx=$1 sy=$2 cw=$3 ch=$4 x y r dx k gc base
  local t="$5" rt="${6:-}"
  cshade $CYAN 0.30; v_box $sx $sy $(( cw + 2 )) $(( ch + 2 )) $CS $BLACK round
  v_fill $(( sx + 1 )) $(( sy + 1 )) $cw $ch ' ' $GREY $BLACK
  dx=$(( cw / 8 )); (( dx < 2 )) && dx=2
  cshade $CYAN 0.16; gc=$CS
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  for (( r = 1; r < ch; r += 2 )); do
    y=$(( sy + 1 + r ))
    for (( x = 2; x < cw; x += 3 )); do
      k=$(( base + y * TCOLS + sx + 1 + x ))
      if (( x % dx == 0 )); then GCH[$k]='┼'; else GCH[$k]='·'; fi
      GF[$k]=$gc
    done
  done
  for (( x = dx; x < cw; x += dx )); do
    for (( r = 0; r < ch; r += 2 )); do
      k=$(( base + (sy + 1 + r) * TCOLS + sx + 1 + x )); GCH[$k]='┊'; GF[$k]=$gc
    done
    cshade $CYAN 0.30; v_put $(( sx + 1 + x )) $(( sy + ch + 1 )) '┴' $CS $BLACK
  done
  v_text $(( sx + 2 )) $sy " $t " $AMBER $BLACK
  if [[ -n "$rt" ]]; then cshade $GREY 1.0; v_text $(( sx + cw - ${#rt} - 2 )) $sy " $rt " $CS $BLACK; fi
  return 0
}
sy_scope_rest() {   # sy_scope_rest X Y CW CH — the trace at rest (sy_tc_scope's cells), and the part still to be read
  local -i x=$1 y=$2 cw=$3 ch=$4 i k c u0=-1 u1=-1 base n
  local s
  for (( i = 0; i < cw; i++ )); do
    if (( ${SY_TC_UN[$i]:-0} )); then (( u0 < 0 )) && u0=$i; u1=$i; continue; fi
    sy_scope_col $i 1
  done
  (( u0 >= 0 )) || return 0
  # STILL TO BE READ · a dashed floor where the trace will run, and, where
  # there is room, how long until it does
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  cshade $CYAN 0.34; c=$CS
  k=$(( base + (y + ch - 1) * TCOLS + x ))
  for (( i = u0; i <= u1; i++ )); do GCH[$(( k + i ))]='┄'; GF[$(( k + i ))]=$c; done
  n=$(( ${#SY_CPU_HIST[@]} - ${SY_SEEN[SY_CPU_HIST]:-0} ))
  if (( n > 0 && u1 - u0 + 1 >= 34 && ch >= 3 )); then
    sy_span $n; s="reading · a full trace in ${SPN}"
    cshade $GREY 0.85; v_text $(( x + u0 + (u1 - u0 + 1 - ${#s}) / 2 )) $(( y + (ch - 1) / 2 )) "$s" $CS $BLACK
  fi
  return 0
}
typeset -gF SYPK=0.0
sy_peak() {   # sy_peak NAME -> SYPK · the highest reading on the part of tape NAME that was read
  local -i n s0 i
  local -F v=0.0
  local ref="$1[@]"                              # the whole tape · a bare name is its first reading under KSH_ARRAYS
  local -a a; a=("${(@P)ref}")
  n=${#a[@]}; s0=$(( n - ${SY_SEEN[$1]:-0} )); (( s0 < 0 )) && s0=0
  for (( i = s0; i < n; i++ )); do (( a[i] > v )) && v=${a[$i]}; done
  SYPK=$v
  return 0
}
sy_scope_span() {   # sy_scope_span -> SPN · how far back the trace really reaches
  local -i n=${SY_SEEN[SY_CPU_HIST]:-0}
  (( n < 1 )) && n=1
  sy_span $n
  return 0
}
typeset -gi SY_TC_OY=0 SY_TC_CH=5 SY_TC_CW=84 SY_TC_SX=0 SY_TC_SY=0   # where the still part put things
typeset -gF SY_TC_BEAM0=0.62 SY_TC_FIRST=1.15   # the beam's first pass starts here, in the card's own time, and takes this long
sy_title_base() {   # the card's still part, painted once a reading and kept (tc_card)
  local -F peak=0 v
  local -i oy cw ch sx sy x y r ndiv dx c base k gc
  local s
  tc_base SYSTEM
  # the band's right-hand reading, the pages' own, so walking in moves nothing
  sy_up ${SY[uptime]}; cmix $GLASS $PURPLE 0.32; sy_right $APP_HR 0 "UP $UPS" $P_LBL $CM
  # a taller glass, a taller scope; a wider one, more of the quarter hour in it
  ch=5; (( TC_H >= 34 )) && ch=7; (( TC_H >= 40 )) && ch=9
  cw=$(( TC_W - 20 )); (( cw > 120 )) && cw=120
  oy=$(( (TC_H - (ch + 19)) / 2 )); (( oy < 0 )) && oy=0
  tc_big SYSTEM $(( oy + 1 )) $CYAN $LIME
  # the silicon · the host and the system are under the cabinet already
  s="${SY[cpu_model]:-${SY[arch]}}"; (( ${SY[ncpu]:-0} > 0 )) && s+="  ·  ${SY[ncpu]} cores"
  cshade $GREY 1.05; tc_center $(( oy + 8 )) "$s" $CS
  tc_reveal $TC_CX $(( TC_Y0 + oy + 8 )) $TC_CW 0.58 0.26
  # ── the scope · its frame, its ruled screen, its ticks ──
  sx=$(( TC_X0 + (TC_W - cw - 2) / 2 )); sy=$(( TC_Y0 + oy + 10 ))
  sy_peak SY_CPU_HIST; peak=$SYPK
  sy_scope_span; printf -v s 'PEAK %.0f%%' $peak
  sy_scope_frame $sx $sy $cw $ch "PROCESSOR · THE LAST ${SPN:u}" "$s"
  tc_quiet $sx $sy $(( cw + 2 )) $(( ch + 2 ))
  # the part of the screen still to be read, its dashed floor (the trace
  # itself is the live part's)
  sy_tc_scope $(( sx + 1 )) $(( sy + 1 )) $cw $ch
  base=$(( (OY + R_SCR) * TCOLS + OX + C_SCR ))
  cshade $CYAN 0.34; c=$CS
  for (( x = 0; x < cw; x++ )); do
    (( ${SY_TC_UN[$x]:-0} )) || continue
    k=$(( base + (sy + ch) * TCOLS + sx + 1 + x )); GCH[$k]='┄'; GF[$k]=$c
  done
  # ── the meters ──
  local -i cp mp dp
  local cs ms ds ls
  cp=$(( int(${SY[cpu]:-0} + 0.5) )); printf -v cs '%.1f%%' ${SY[cpu]:-0}
  mp=$(( int(${SY[mem_pct]:-0} + 0.5) )); sy_human_g ${SY[mem_used]}; ms="$HG"; sy_human_g ${SY[mem_total]}; ms+=" OF $HG"
  if (( ${SY[disk_total]} > 0.001 )); then dp=$(( int(100.0 * ${SY[disk_used]} / ${SY[disk_total]} + 0.5) )); ds="$dp%"
  else dp=-1; ds='—'; fi
  printf -v ls '%.2f' ${SY[load.0]:-0}
  TC_MJX=$sx; TC_MJW=$(( cw + 2 ))                 # under the scope, end to end
  tc_meters $(( oy + ch + 13 )) 1.00 CPU $cp "$cs" MEMORY $mp "$ms" DISK $dp "$ds" LOAD -1 "$ls"
  tc_nav 'wake the monitor'
  SY_TC_OY=$oy; SY_TC_CH=$ch; SY_TC_CW=$cw; SY_TC_SX=$sx; SY_TC_SY=$sy
  return 0
}
sy_title() {   # sy_title T — the card: the still part kept, and the trace, the type and the door live over it
  local -F t=$1 bx d u
  local -i oy cw ch i q c e r col first top bk y k
  local st
  PACK_FILL=1
  tc_card "sy|$SY_GEN" sy_title_base $t
  oy=$SY_TC_OY; ch=$SY_TC_CH; cw=$SY_TC_CW
  tc_spaced $(( oy + 7 )) 'THE MACHINE AT ONCE' $CYAN $PURPLE $t 0.42
  # THE BEAM · its first pass draws the trace onto the empty screen; after
  # that it goes round every four seconds, the trace bright where it has just
  # been and settling back to its own glow behind it, and a faint column of
  # light where the beam is standing
  sy_tc_scope $(( SY_TC_SX + 1 )) $(( SY_TC_SY + 1 )) $cw $ch
  u=$(( TC_NOW - SY_TC_BEAM0 ))
  if (( u >= 0.0 )); then
    # the first pass quick, to have the trace up while the card is still
    # arriving · then the monitor's own unhurried four seconds a sweep
    if (( u < SY_TC_FIRST )); then first=1; bx=$(( u / SY_TC_FIRST ))
    else first=0; bx=$(( (u - SY_TC_FIRST) * 0.25 )); bx=$(( bx - floor(bx) )); fi
    bx=$(( bx * (cw + 20) - 4 ))
    for (( i = 0; i < cw; i++ )); do
      d=$(( bx - i ))
      if (( d < 0.0 )); then
        (( first )) && continue                  # the first pass has not reached it yet
        d=$(( d + cw + 20 ))                     # drawn on the last pass, long since
      fi
      if (( d < 16.0 )); then q=$(( 2 + int((1.0 - d / 16.0) ** 2 * 6.0) )); else q=1; fi
      sy_scope_col $i $q
    done
    # the beam itself, a hairline standing over the trace where it is
    i=$(( int(bx) ))
    if (( i >= 0 && i < cw )); then
      c=${SY_TC_INK_BEAM:-0}; (( c )) || { cmix $BLACK $CYAN 0.34; c=$CM; SY_TC_INK_BEAM=$c }
      top=${SY_TC_TOP[$i]:-0}
      bk=$(( (OY + R_SCR) * TCOLS + OX + C_SCR + SY_TC_SX + 1 + i ))
      for (( y = 0; y < ch - top; y++ )); do
        k=$(( bk + (SY_TC_SY + 1 + y) * TCOLS )); GCH[$k]='│'; GF[$k]=$c
      done
    fi
  fi
  # ── what the cabinet makes of it, and the door ──
  if (( ${SY[cpu]} >= 85.0 )); then st='RUNNING HOT'; col=$AMBER
  elif (( ${SY[mem_pct]} >= 90.0 )); then st='MEMORY TIGHT'; col=$AMBER
  elif (( ${SY[disk_total]} > 0.001 )) && (( 100.0 * ${SY[disk_used]} / ${SY[disk_total]} >= 95.0 )); then st='DISK NEARLY FULL'; col=$AMBER
  else st='ALL SYSTEMS NOMINAL'; col=$LIME; fi
  tc_status $(( oy + ch + 15 )) "$st" $col $t 1.28
  tc_prompt $(( oy + ch + 17 )) $t '' 1.55
  return 0
}
typeset -gi SY_TC_INK_BEAM=0

PACK_NAME='SYSTEM'
PACK_MODEL='NX-88'
PACK_INIT='sys_init'
PACK_WARM='sys_warm'
PACK_FIRST='sys_first'
PACK_TICK='sys_tick'
PACK_DRAW='sys_draw'
PACK_KEY='sys_key'
PACK_DRESS='sys_dress'
SY_MODEL='NX-88'

sys_init() {
  # ONE READING, AND NOT THE SLOW HALF OF IT.  `top -l 1` is the better part
  # of a second and the battery block walks the whole IO registry, and doing
  # both here means the letter that opens this machine buys a freeze before
  # anything is drawn -- on the one surface whose whole subject is that the
  # machine is responsive.  The pump takes them on its own two steps, which
  # is a dozen frames, which is under half a second at any rate this cabinet
  # holds; until then the two fields they feed read as not yet taken, which
  # is what they are.
  sy_palette
  sy_shades
  sy_init
  # STARTED BEHIND THE LOADING SCREEN (terminal.command, SECTION 22b), the
  # reading is taken a sampler at a time between the stars' frames instead
  # (sys_warm) -- twenty-odd processes in one piece would be a hitch in the
  # sky -- and the page itself is turned to its menu when the door opens.
  if (( ${WARMING:-0} )); then SY_READ=0; return 0; fi
  sy_tick_all 1.0
  SY_READ=1
  SYS_VIEW='menu'; SYS_ROW=0
  return 0
}
typeset -gi SY_READ=0                # the first reading has been taken, whole
sys_warm() {   # sys_warm N T — sy_tick_all, one sampler a piece and in its order
  case $1 in
    0) sy_sample_cpu ;;      1) sy_sample_mem ;;     2) sy_sample_disk ;;
    3) sy_sample_vols ;;     4) sy_sample_net 1.0 ;; 5) sy_sample_io 1.0 ;;
    6) sy_load; sy_uptime ;; 7) sy_sample_procs ;;   8) sy_sample_batt ;;
    9) sy_sample_ifaces ;;   10) sy_sample_conn ;;
    *) SY_READ=1; return 1 ;;
  esac
  return 0
}
sys_first() {   # the door opened · on its menu, with a whole reading under it
  (( SY_READ )) || { sy_tick_all 1.0; SY_READ=1; }   # the loading screen did not get round to all of it
  SYS_VIEW='menu'; SYS_ROW=0
  return 0
}

# ── the reading, off the beat ─────────────────────────────────────────────
# A READING SPAWNS THE BETTER PART OF TWENTY PROCESSES, and one of them --
# `top -l 1` -- takes the better part of a second to answer.  The glass draws
# thirty times a second.  system.py answers that with a thread and a lock; a
# shell has neither, and the first port of this file did the next thing it
# could think of: ONE sampler per frame, twelve frames to a reading.  That
# spread the cost, and it did not remove it -- each of those twelve frames
# was still a frame with a fork in it, the `top` frame was still a second
# with the picture stopped, and the reading landed a sampler at a time, so
# for half a second every ten the page was a picture of two moments.
#
# NOW THE READING IS TAKEN IN ANOTHER PROCESS.  Every ten seconds the pack
# forks a copy of itself -- which is what a subshell is, and it costs a
# millisecond -- and the copy takes the whole reading, the slow half
# included, with every previous counter it needs for the rates already in
# its hands.  It writes the sampler's state to a file beside itself, moves
# the file into place in one step, and exits.  The beat never waits: the
# tick checks for the file, and the frame that finds it adopts the reading
# whole and bumps the generation once.  The glass is a picture of ONE
# moment, it changes every ten seconds, and nothing else about the frame
# rate knows the reading exists.
#
# WHAT GOES IN THE FILE IS THE SAMPLER'S STATE AND NOTHING ELSE.  The map of
# readings, the tapes, the counts, and the previous counters the rates are
# differenced from -- named in SY_BG_VARS, deliberately, because the copy
# also holds the cursor, the page, the sort and the generation, and a dump
# of everything would hand the reader a cursor from ten seconds ago.
# (kept across a re-source: a reading in flight when the reader walks out
# to another machine and back is still a reading)
(( ${+SY_BG_PID} )) || typeset -gi SY_BG_PID=0
[[ -n "${SY_BG_FILE:-}" ]] || SY_BG_FILE=''
SY_BG_VARS=(SY SY_SERIAL SY_N_CORES SY_N_PROCS SY_N_VOLS SY_N_IFACES SY_N_DEVICES
            SY_CPU_HIST SY_MEM_HIST SY_RX_HIST SY_TX_HIST SY_IO_HIST SY_IOW_HIST SY_SEEN
            SY_TU SY_TS SY_TI SY_TN SY_KU SY_KS SY_KI SY_KN SY_TICK_OK SY_HAVE_PREV
            SY_MU SY_MS SY_MI SY_MOCK_N
            SY_VM SY_VM_PREV SY_VM_AT
            SY_NET_R SY_NET_T SY_NET_HAVE SY_NET_IF_WAS SY_ROUTE_AT
            SY_IO_R SY_IO_W SY_IO_RO SY_IO_WO SY_IO_HAVE SY_DISKS_WAS
            SY_PY SY_PY_TRIED)
sy_bg_file() {   # one name for the session, made once
  [[ -n "$SY_BG_FILE" ]] && return 0
  SY_BG_FILE="$(mktemp -t alien-sys.XXXXXX 2>/dev/null)" || { SY_BG_FILE=''; return 1 }
  rm -f "$SY_BG_FILE" 2>/dev/null
  return 0
}
sy_bg_start() {   # sy_bg_start DT — the whole reading, in a copy of this process
  local f dump nl=$'\n'
  local -F dt=$1
  sy_bg_file || return 1
  f="$SY_BG_FILE"
  rm -f "$f" "$f.part" 2>/dev/null
  (
    sy_tick_all $dt
    sy_tick_slow
    # EVERY LINE SAYS -g.  `typeset -p` spells a global with the flag from
    # inside a function and without it from the top level, depending on the
    # zsh; the tick that reads the file back is a function, and without the
    # flag every reading would land in a local that vanished at the end of
    # the tick.  (Not $'\n' in the pattern: ANSI quotes are not read inside
    # double quotes, and the first cut of this wrote the two characters
    # `\n` into the file between the lines.)
    dump="$(typeset -p "${SY_BG_VARS[@]}" 2>/dev/null)"
    dump="${dump//${nl}typeset -g /${nl}typeset }"
    dump="${dump//${nl}typeset /${nl}typeset -g }"
    dump="${dump#typeset -g }"; dump="${dump#typeset }"; dump="typeset -g $dump"
    print -r -- "$dump" > "$f.part" 2>/dev/null && mv -f "$f.part" "$f" 2>/dev/null
  ) >/dev/null 2>&1 &!
  SY_BG_PID=$!
  return 0
}
sy_bg_adopt() {   # the reading that landed, taken whole
  local f="$SY_BG_FILE"
  [[ -n "$f" && -s "$f" ]] || return 1
  eval "$(<"$f")" 2>/dev/null
  rm -f "$f" 2>/dev/null
  return 0
}
sy_bg_stop() {
  (( SY_BG_PID )) && kill $SY_BG_PID 2>/dev/null
  SY_BG_PID=0
  [[ -n "$SY_BG_FILE" ]] && rm -f "$SY_BG_FILE" "$SY_BG_FILE.part" 2>/dev/null
  return 0
}
SY_LAST=0.0
SY_SAMPLE=10.0
sys_tick() {   # sys_tick T
  local -F t=$1
  # THE FIRST CYCLE STARTS AT ONCE, and the arithmetic is what says so: set
  # the last-sample mark to a whole interval AGO on the opening frame, so the
  # gate below is already open -- which is how the two readings sys_init
  # leaves out (the cell's registry block and the thread count) arrive a
  # second or two after the page does, rather than ten seconds after.
  (( SY_LAST == 0.0 )) && SY_LAST=$(( t - SY_SAMPLE ))
  if (( SY_BG_PID )); then
    if [[ -s "$SY_BG_FILE" ]]; then
      sy_bg_adopt && (( SY_GEN++ ))
      SY_BG_PID=0
    elif ! kill -0 $SY_BG_PID 2>/dev/null; then
      SY_BG_PID=0                   # it went without writing · next cycle tries again
    fi
    return 0
  fi
  (( t - SY_LAST < SY_SAMPLE )) && return 0
  SY_DT=$(( t - SY_LAST )); SY_LAST=$t
  sy_bg_start $SY_DT
  return 0
}
sys_leave() { sy_bg_stop; return 0 }
(( ${+functions[pack_at_exit]} )) && pack_at_exit sys_leave
SY_DT=10.0
typeset -gi SY_GEN=0                 # bumped once per reading adopted

# ── the picture ───────────────────────────────────────────────────────────
# A PAGE THAT IS NOT FITTED YET SAYS SO, ON ITS OWN GLASS.  Falling back to
# the instrument list was worse than an empty page: the cursor moved, the
# picture did not, and from the reader's side the machine had simply refused
# to open anything.  An instrument that is not in yet is a fact about this
# cabinet and it belongs on the glass like every other reading.
sy_draw_soon() {   # sy_draw_soon TITLE
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  sy_page_head "$1"
  sy_spaced "$1"
  v_center 11 "$SPD" $P_WHITE
  v_center 14 'this instrument is not fitted yet' $P_LBL
  v_center 16 'the readings behind it are already being taken —' $P_DIM
  v_center 17 'it is the glass for them that is still being cut' $P_DIM
  v_center 21 '[⎋]  back to the instruments' $P_FG
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# THE PAGE VOCABULARY · the shapes every instrument is built out of
# ══════════════════════════════════════════════════════════════════════════
# EIGHT PAGES, ONE SET OF PARTS.  A panel, a key and its value, a meter, a
# stacked bar, a league table, a history block.  They are here rather than in
# each page for the reason every one of them looks the same on every page:
# a table that is drawn its own way on the page that happens to need it is a
# table the eye has to learn twice.
sy_page_foot() {   # SYSTEM's instrument keys, on the suite's one nav bar
  # THE FOOTER IS THE CABINET'S NOW · app_nav rides the same two rows in the same
  # ink on every surface.  An instrument pages with ◂ ▸ and leaves by ⎋; a letter
  # still jumps straight to any instrument (taught on the list page, where the
  # letters are printed).  The HINT arg the pages still pass is ignored.
  app_nav "◂ ▸" pages "[⎋]" menu
  return 0
}

sy_kv() {   # sy_kv X Y LABEL VALUE [LW] [TONE] [CAP]
  local -i x=$1 y=$2 lw=${5:-12} col=${6:--2}
  local lab="$3" val="$4"
  while (( ${#lab} < lw )); do lab+=' '; done
  v_text $x $y "$lab" $P_LBL
  (( ${7:-0} )) && val="${val[0,$(( $7 - 1 ))]}"
  (( col == -2 )) && col=$P_FG
  v_text $(( x + lw + 1 )) $y "$val" $col
  return 0
}

sy_meter() {   # sy_meter X Y W FRAC LABEL VALUE [HOT]
  local -i x=$1 y=$2 w=$3 col
  local -F f=$4
  local lab="$5" val="$6" d=''
  local -i i
  sy_ease "meter.$5.$x.$y" $f; f=$SMF
  while (( ${#lab} < 9 )); do lab+=' '; done
  v_text $x $y "$lab" $P_LBL
  for (( i = 0; i < w; i++ )); do d+='░'; done
  v_text $(( x + 10 )) $y "$d" $P_DIM
  if [[ -n "${7:-}" ]]; then
    (( $7 )) && col=$P_HOT || col=$P_FG
  else
    sy_tone $f; col=$TON
  fi
  sy_hbar $w $f
  v_text $(( x + 10 )) $y "$BAR" $col
  v_text $(( x + 11 + w )) $y "$val" $P_FG
  return 0
}

# ONE BAR CARRYING SEVERAL SHARES END TO END, so a hundred per cent is always
# a hundred per cent and the reader can see what took it.
sy_stack() {   # sy_stack X Y W FRAC:COL...
  local -i x=$1 y=$2 w=$3 i a b n
  shift 3
  local d='' seg p
  local -F at=0.0 fr
  for (( i = 0; i < w; i++ )); do d+='░'; done
  v_text $x $y "$d" $P_DIM
  local -i si=0
  for p in "$@"; do
    fr="${p%%:*}"; seg=''
    sy_ease "stack.$x.$y.$si" $fr; fr=$SMF; (( si++ ))
    a=$(( int(at * w + 0.5) )); b=$(( int((at + fr) * w + 0.5) ))
    if (( b > a )); then
      n=$(( b - a )); (( n > w - a )) && n=$(( w - a ))
      for (( i = 0; i < n; i++ )); do seg+='█'; done
      [[ -n "$seg" ]] && v_text $(( x + a )) $y "$seg" ${p#*:}
    fi
    at=$(( at + fr ))
  done
  return 0
}

sy_legend() {   # sy_legend X Y COL LABEL [VALUE] — the key under a stack
  v_put $1 $2 '●' $3
  v_text $(( $1 + 2 )) $2 "$4" $P_LBL
  [[ -n "${5:-}" ]] && v_text $(( $1 + 2 + ${#4} + 1 )) $2 "$5" $P_FG
  return 0
}

sy_lpad() {   # sy_lpad TEXT W -> LP
  LP="$1"
  while (( ${#LP} < $2 )); do LP=" $LP"; done
}

# A SHORT LEAGUE TABLE · the same shape on every page that has one
sy_topn() {   # sy_topn X Y W TITLE FIELD N [KIND] — KIND pct | bytes
  local -i x=$1 y=$2 w=$3 n=$6 i j bw col h
  local title="$4" fld="$5" kind="${7:-pct}" nm
  local -F v scale
  sy_order $fld
  (( n > ${#SY_ORD[@]} )) && n=${#SY_ORD[@]}
  h=$(( n + 2 )); (( h < 3 )) && h=3
  sy_panel $x $y $w $h "$title"
  if (( ! n )); then
    v_text $(( x + 2 )) $(( y + 1 )) 'nothing to report' $P_DIM
    return 0
  fi
  scale=${SY[procs.${SY_ORD[0]}.$fld]}
  (( scale < 0.000001 )) && scale=0.000001
  bw=$(( w - 42 )); (( bw < 3 )) && bw=3
  local d=''
  for (( i = 0; i < bw; i++ )); do d+='░'; done
  for (( i = 0; i < n; i++ )); do
    j=${SY_ORD[$i]}
    v=${SY[procs.$j.$fld]}
    if   (( v > scale * 0.7 ));  then col=$P_HOT
    elif (( v > scale * 0.35 )); then col=$P_WARM
    else                              col=$P_FG; fi
    nm="${SY[procs.$j.cmd]}"
    (( ${#nm} > 20 )) && nm="${nm[0,18]}…"
    while (( ${#nm} < 20 )); do nm+=' '; done
    (( i == 0 )) && v_text $(( x + 2 )) $(( y + 1 + i )) "$nm" $P_WHITE \
                 || v_text $(( x + 2 )) $(( y + 1 + i )) "$nm" $P_FG
    sy_lpad "${SY[procs.$j.pid]}" 6
    v_text $(( x + 23 )) $(( y + 1 + i )) "$LP" $P_DIM
    v_text $(( x + 30 )) $(( y + 1 + i )) "$d" $P_DIM
    sy_hbar $bw $(( v / scale ))
    v_text $(( x + 30 )) $(( y + 1 + i )) "$BAR" $col
    if [[ "$kind" == bytes ]]; then sy_human_b $v; nm="$HB"
    else                            printf -v nm '%.1f%%' $v; fi
    sy_right $(( x + w - 2 )) $(( y + 1 + i )) "$nm" $col
  done
  return 0
}

sy_hist_block() {   # sy_hist_block Y LABEL UNITFMT ROWS SERIES...
  local -i y=$1 rows=$4
  local lab="$2" fmt="$3" s
  shift 4
  local -a ser; ser=("$@")
  local -F peak=0.0 v
  for v in "${ser[@]}"; do (( v > peak )) && peak=$v; done
  v_text 2 $y "$lab" $P_LBL
  sy_span ${#ser[@]}
  printf -v s "$fmt" $peak
  sy_right $(( SCR_W - 3 )) $y "last $SPN · peak $s" $P_DIM
  sy_trace 2 $(( y + 1 )) $(( SCR_W > 120 ? SCR_W - 4 : 102 )) $rows "${ser[@]}"
  v_text 2 $(( y + 1 + rows )) 'older' $P_DIM
  sy_right $(( SCR_W - 3 )) $(( y + 1 + rows )) 'now' $P_DIM
  return 0
}

# ── the muted shades the stacked bars use for their last slice ────────────
# Raw greys in the source, packed here once: they are the colour of the part
# of a bar that is NOT the reading -- idle time, file cache -- and they have
# to sit just far enough off the glass to be seen as a share and not as ink.
typeset -gi SY_IDLE1=0 SY_IDLE2=0 SY_FILEC=0
sy_shades() {
  _pack 40 34 62;  SY_IDLE1=$PK
  _pack 60 52 86;  SY_IDLE2=$PK
  _pack 70 60 100; SY_FILEC=$PK
  return 0
}

SY_FOOT='◂ ▸ pages   ·   the letters below reach every surface   ·   [⎋] menu'

# ══════════════════════════════════════════════════════════════════════════
# PROCESSOR · where the time went, which a single "busy" number dodges
# ══════════════════════════════════════════════════════════════════════════
sy_draw_cpu() {
  local -i L=$SY_L R=$SY_R W=$SY_W i j col ncol nrow slots binned colw bw n0 y x
  local -F u sys ni idl tot v
  local s lab d
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  printf -v s '%d CORES · %s' ${SY[ncpu]} "${${SY[cpu_model]:-?}[0,33]}"
  sy_page_head PROCESSOR "$s"

  u=${SY[cpu_user]}; sys=${SY[cpu_sys]}; ni=${SY[cpu_nice]}; idl=${SY[cpu_idle]}
  tot=$(( u + sys + ni + idl )); (( tot < 0.000001 )) && tot=0.000001
  v_text 2 2 'BUSY' $P_LBL
  printf -v s '%.1f%%' ${SY[cpu]}
  sy_tone $(( ${SY[cpu]} / 100.0 ))
  v_text 7 2 "$s" $TON
  sy_stack 16 2 $(( SCR_W > 120 ? SCR_W - 44 : 60 )) "$(( u / tot )):$CYAN" "$(( sys / tot )):$MAGENTA" \
                   "$(( ni / tot )):$PURPLE" "$(( idl / tot )):$SY_IDLE1"
  printf -v s 'of %d logical cores' ${SY[ncpu]}
  sy_right $(( SCR_W - 2 )) 2 "$s" $P_DIM
  printf -v s '%.1f%%' $u;   sy_legend 16 3 $CYAN    user   "$s"
  printf -v s '%.1f%%' $sys; sy_legend 32 3 $MAGENTA system "$s"
  printf -v s '%.1f%%' $ni;  sy_legend 50 3 $PURPLE  nice   "$s"
  printf -v s '%.1f%%' $idl; sy_legend 64 3 $SY_IDLE2 idle  "$s"

  sy_panel $L 5 $W 8 SILICON
  sy_kv $(( L + 2 )) 6 model "${SY[cpu_model]:-?}" 11 -2 33
  sy_kv $(( L + 2 )) 7 arch  "${SY[arch]}"         11 -2 33
  if (( ${SY[ncpu_p]:-0} && ${SY[ncpu_e]:-0} )); then
    printf -v s '%d performance · %d efficiency' ${SY[ncpu_p]} ${SY[ncpu_e]}
  else
    printf -v s '%d logical · %d physical' ${SY[ncpu]} ${SY[nphys]}
  fi
  sy_kv $(( L + 2 )) 8 cores "$s" 11 -2 33
  if (( ${SY[cpu_hz]:-0} )); then printf -v s '%.2f GHz' ${SY[cpu_hz]}
  else                            s='managed by the system'; fi
  sy_kv $(( L + 2 )) 9 clock "$s" 11 -2 33
  s="${SY[therm]:-}"; [[ -n "$s" && "$s" != null ]] || s='nominal'
  [[ "$s" == *throttl* ]] && col=$RED || col=$LIME
  sy_kv $(( L + 2 )) 10 thermal "$s" 11 $col 33
  printf -v s '%d processes · %d threads' ${SY[nproc]} ${SY[nthread]}
  sy_kv $(( L + 2 )) 11 scheduling "$s" 11 -2 33

  sy_panel $R 5 $W 8 'LOAD AVERAGE'
  local -a llab; llab=('1 min' '5 min' '15 min')
  for (( i = 0; i < 3; i++ )); do
    v=${SY[load.$i]}
    printf -v s '%.2f' $v
    sy_meter $(( R + 2 )) $(( 6 + i )) 18 $(( v / (${SY[ncpu]} > 1 ? ${SY[ncpu]} : 1) )) \
             "${llab[$i]}" "$s" $(( v > ${SY[ncpu]} ))
  done
  printf -v s 'a load of %d is a thread waiting per core' ${SY[ncpu]}
  v_text $(( R + 2 )) 10 "$s" $P_DIM
  local -i run=0
  for (( i = 0; i < SY_N_PROCS; i++ )); do
    [[ "${SY[procs.$i.state]}" == R ]] && (( run++ ))
  done
  printf -v s '%d of %d' $run ${SY[nproc]}
  (( run > ${SY[ncpu]} )) && col=$P_HOT || col=$P_FG
  sy_kv $(( R + 2 )) 11 runnable "$s" 11 $col

  # EVERY CORE, AND THE GRID STAYS SIX ROWS TALL however many there are -- it
  # grows sideways instead, so the page below it never moves.  A cell needs
  # four for the label, four for the read-out, a gutter and a bar: thirteen
  # columns at the very least.  Ask for more than that fits and the read-out
  # lands on the bar and the bar walks through the panel's border, so the
  # columns are bounded by what a cell needs and the surplus is BINNED -- each
  # column showing the busiest core in its share, the way the overview's core
  # map already does.
  local -a cs first
  local -i nc=$SY_N_CORES
  (( nc < 1 )) && nc=1
  ncol=$(( (nc + 5) / 6 )); (( ncol > (W - 4) / 13 )) && ncol=$(( (W - 4) / 13 ))
  (( ncol < 1 )) && ncol=1
  nrow=$(( (nc + ncol - 1) / ncol )); (( nrow > 6 )) && nrow=6
  slots=$(( ncol * nrow ))
  binned=0; (( nc > slots )) && binned=1
  cs=(); first=()
  if (( binned )); then
    for (( i = 0; i < slots; i++ )); do
      local -i lo=$(( i * nc / slots )) hi=$(( (i + 1) * nc / slots ))
      (( hi <= lo )) && hi=$(( lo + 1 ))
      v=0.0
      for (( j = lo; j < hi; j++ )); do (( ${SY[cores.$j]} > v )) && v=${SY[cores.$j]}; done
      cs+=($v); first+=($lo)
    done
  else
    for (( i = 0; i < nc; i++ )); do cs+=(${SY[cores.$i]}); first+=($i); done
  fi
  colw=$(( (W - 4) / ncol ))
  bw=$(( colw - 10 )); (( bw < 3 )) && bw=3
  if (( binned )); then
    printf -v s 'CORES · BUSIEST OF EACH %d' $(( (nc + slots - 1) / slots ))
  else
    s='EVERY CORE'
  fi
  sy_panel $L 13 $W $(( nrow + 2 )) "$s"
  d=''
  for (( i = 0; i < bw; i++ )); do d+='░'; done
  for (( i = 0; i < ${#cs[@]}; i++ )); do
    v=${cs[$i]}
    x=$(( L + 2 + (i / nrow) * colw )); y=$(( 14 + i % nrow ))
    n0=${first[$i]}
    # THE EFFICIENCY CLUSTER IS ENUMERATED FIRST on Apple silicon -- the low
    # indices are the E cores.  A binned bar spans whatever it spans, so it
    # is labelled by where it starts.
    if (( binned )); then lab="$n0"
    elif (( ${SY[ncpu_p]:-0} && ${SY[ncpu_e]:-0} )); then
      (( n0 < ${SY[ncpu_e]} )) && lab="E$n0" || lab="P$n0"
    else lab="#$n0"; fi
    while (( ${#lab} < 4 )); do lab+=' '; done
    v_text $x $y "$lab" $P_LBL
    v_text $(( x + 4 )) $y "$d" $P_DIM
    sy_ease "core.$x.$y" $(( v / 100.0 )); sy_hbar $bw $SMF; sy_tone $(( v / 100.0 ))
    v_text $(( x + 4 )) $y "$BAR" $TON
    printf -v s '%.0f%%' $v
    sy_right $(( x + colw - 2 )) $y "$s" $P_FG
  done

  sy_topn $R 13 $W 'BUSIEST · % OF ONE CORE' cpu 6
  sy_hist_block 22 PROCESSOR '%.0f%%' $(( SCR_W > 120 ? SCR_H - 26 : 3 )) "${SY_CPU_HIST[@]}"
  sy_page_foot "$SY_FOOT"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# MEMORY · one cut through the machine, all the way
# ══════════════════════════════════════════════════════════════════════════
sy_draw_mem() {
  local -i L=$SY_L R=$SY_R W=$SY_W i col
  # ON THE WHOLE WINDOW both columns widen, the resident list grows to as many
  # names as the glass is tall, and the MEMORY-IN-USE trace stands on the foot
  local -i sw=50 bw=10 mw=16 tN=9 ch=11 th=3 sumrow=26
  if (( SCR_W > 120 )); then
    sw=$(( SCR_W - 64 )); bw=$(( SY_W - 40 )); mw=$(( SY_W - 34 ))
    tN=$(( SCR_H - 20 )); ch=$(( SCR_H - 18 )); th=$(( ch - 8 )); sumrow=$(( SCR_H - 3 ))
  fi
  local -F tot wired act comp inact spec free act_q fileb tally v
  local s d note
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  sy_human_g ${SY[mem_total]}
  sy_page_head MEMORY "$HG INSTALLED"
  tot=${SY[mem_total]}; (( tot < 0.001 )) && tot=0.001
  wired=${SY[mem_wired]}; act=${SY[mem_app]}; comp=${SY[mem_compressed]}
  inact=${SY[mem_inactive]}; spec=${SY[mem_spec]}; free=${SY[mem_free]}
  act_q=${SY[mem_active]}; fileb=${SY[mem_file]}

  v_text 2 2 'IN USE' $P_LBL
  sy_human_g ${SY[mem_used]}; s="$HG"; sy_human_g $tot
  sy_tone $(( ${SY[mem_pct]} / 100.0 ))
  v_text 9 2 "$s of $HG" $TON
  sy_stack 26 2 $sw "$(( wired / tot )):$MAGENTA" "$(( act / tot )):$CYAN" \
                   "$(( comp / tot )):$PURPLE" "$(( fileb / tot )):$SY_FILEC"
  printf -v s '%.0f%% committed' ${SY[mem_pct]}
  sy_right $(( SCR_W - 2 )) 2 "$s" $P_DIM
  sy_human_g $wired; sy_legend 26 3 $MAGENTA wired "$HG"
  sy_human_g $act;   sy_legend 40 3 $CYAN    app   "$HG"
  sy_human_g $comp;  sy_legend 55 3 $PURPLE  compressed "$HG"
  sy_human_g $fileb; sy_legend 74 3 $SY_FILEC 'file cache' "$HG"

  # A PARTITION · five slices that are the whole machine, in Activity
  # Monitor's own terms, so the reader can hold the two side by side.  It is
  # ONE cut: the kernel's page queues and the anonymous/file-backed split are
  # two different cuts of the same memory, and three slices from one plus two
  # from the other do not make a whole -- which is how an earlier version of
  # this panel came to about half as much again as the Mac actually has.
  sy_panel $L 5 $W 9 'THE BREAKDOWN'
  local -a rl rv rn
  rl=('app memory' 'wired' 'compressed' 'file cache' 'free')
  rv=($act $wired $comp $fileb $free)
  rn=('programs hold' 'kernel-locked' 'kept resident' 'read from disk' 'untouched')
  d=''; for (( i = 0; i < bw; i++ )); do d+='░'; done
  tally=0.0
  for (( i = 0; i < 5; i++ )); do
    v=${rv[$i]}; tally=$(( tally + v ))
    s="${rl[$i]}"; while (( ${#s} < 12 )); do s+=' '; done
    v_text $(( L + 2 )) $(( 6 + i )) "$s" $P_LBL
    v_text $(( L + 15 )) $(( 6 + i )) "$d" $P_DIM
    sy_ease "mem.row.$i" $(( v / tot )); sy_hbar $bw $SMF
    v_text $(( L + 15 )) $(( 6 + i )) "$BAR" $P_FG
    sy_human_g $v; sy_lpad "$HG" 6
    v_text $(( L + 16 + bw )) $(( 6 + i )) "$LP" $P_FG
    v_text $(( L + 23 + bw )) $(( 6 + i )) "${rn[$i][0,14]}" $P_DIM
  done
  sy_human_g ${SY[mem_purge]}
  v_text $(( L + 2 )) 11 "purgeable  $HG, which the kernel may drop" $P_DIM
  sy_human_g $tally; s="$HG"; sy_human_g $tot
  v_text $(( L + 2 )) 12 "five slices, $s of the $HG fitted" $P_DIM

  sy_panel $R 5 $W 9 'SWAP & PRESSURE'
  # macOS GROWS THE SWAPFILES ON DEMAND, so "used of total" is a fraction
  # whose denominator chases its numerator and sits near full the moment swap
  # is touched at all.  Against the memory fitted it means something.
  sy_human_g ${SY[swap_used]}
  sy_meter $(( R + 2 )) 6 $mw $(( ${SY[swap_used]} / tot )) swap "$HG in use"
  case ${SY[mem_press]:-1} in
    2) s=warning;  col=$AMBER ;;
    4) s=critical; col=$RED ;;
    *) s=normal;   col=$LIME ;;
  esac
  sy_kv $(( R + 2 )) 7 pressure "$s" 13 $col
  sy_human_g $act_q; s="$HG"; sy_human_g $inact
  sy_kv $(( R + 2 )) 8 queues "$s active · $HG inactive" 13
  sy_human_g $spec
  sy_kv $(( R + 2 )) 9 '' "$HG speculative" 13
  v_text $(( R + 2 )) 10 'PAGES PER SECOND' $P_LBL
  sy_human_n ${SY[pageins]};  sy_kv $(( R + 2 )) 11 page-ins  "$HN" 11
  sy_human_n ${SY[pageouts]}; sy_kv $(( R + 2 )) 12 page-outs "$HN" 11
  sy_human_n ${SY[swapins]}
  (( ${SY[swapins]} > 0 )) && col=$P_HOT || col=$P_DIM
  sy_kv $(( R + 26 )) 11 swap-ins "$HN" 11 $col
  sy_human_n ${SY[swapouts]}
  (( ${SY[swapouts]} > 0 )) && col=$P_HOT || col=$P_DIM
  sy_kv $(( R + 26 )) 12 swap-outs "$HN" 11 $col

  sy_topn $L 15 $W 'LARGEST RESIDENT' rss $tN bytes
  sy_panel $R 15 $W $ch 'COMPRESSOR & FAULTS'
  sy_human_n ${SY[compressions]};   sy_kv $(( R + 2 )) 16 compressing   "$HN pages/s" 14
  sy_human_n ${SY[decompressions]}; sy_kv $(( R + 2 )) 17 decompressing "$HN pages/s" 14
  sy_human_n ${SY[faults]};         sy_kv $(( R + 2 )) 18 faults        "$HN/s" 14
  sy_human_n ${SY[cows]};           sy_kv $(( R + 2 )) 19 copy-on-write "$HN/s" 14
  v_hline $(( R + 2 )) 20 $(( W - 4 )) '─' $P_DIM
  v_text $(( R + 2 )) 21 'MEMORY IN USE' $P_LBL
  v=0.0
  for s in "${SY_MEM_HIST[@]}"; do (( s > v )) && v=$s; done
  sy_span ${#SY_MEM_HIST[@]}
  printf -v s 'last %s · peak %.0f%%' "$SPN" $v
  sy_right $(( R + W - 3 )) 21 "$s" $P_DIM
  sy_trace $(( R + 2 )) 22 $(( W - 4 )) $th "${SY_MEM_HIST[@]}"
  sy_human_g ${SY[mem_used]}; s="IN USE $HG"
  sy_human_g $free;  s+="   ·   FREE $HG"
  sy_human_g $fileb; s+="   ·   FILE CACHE $HG"
  sy_human_g ${SY[swap_used]}; s+="   ·   SWAP $HG in use"
  v_text 2 $sumrow "$s" $P_DIM
  sy_page_foot "$SY_FOOT"
  return 0
}


sy_rpad() {   # sy_rpad TEXT W -> RP
  RP="$1"
  while (( ${#RP} < $2 )); do RP+=' '; done
}

# ══════════════════════════════════════════════════════════════════════════
# STORAGE · the volumes, how full, and what the devices are carrying
# ══════════════════════════════════════════════════════════════════════════
sy_draw_disk() {
  local -i L=2 R=66 W=62 RW2=38 i y y0 h nv ink
  # ON THE WHOLE WINDOW the wide/narrow split keeps its 62:38 feel, the mount
  # column and the fill bars widen, and the READ/WRITE trace fills the foot
  local -i sw=46 mcol=26 fw=22 bmw=14 dcol=28 ucol=39 zcol=48 bot=26
  if (( SCR_W > 120 )); then
    W=$(( (SCR_W - 6) * 62 / 100 )); R=$(( W + 4 )); RW2=$(( SCR_W - 6 - W ))
    sw=$(( SCR_W - 60 )); mcol=$(( W - 36 )); fw=$(( RW2 - 16 )); bmw=$(( RW2 - 24 ))
    dcol=$(( 2 + mcol )); ucol=$(( dcol + 11 )); zcol=$(( ucol + 9 )); bot=$(( SCR_H - 3 ))
  fi
  local -F rate frac v
  local s s2 d mount
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  nv=$SY_N_VOLS; (( nv > 6 )) && nv=6
  s="${SY_N_VOLS} VOLUME"; (( SY_N_VOLS == 1 )) || s+='S'
  s+=" · ${SY[disks]} DEVICE"; (( ${SY[disks]} == 1 )) || s+='S'
  sy_page_head STORAGE "$s"

  rate=$(( ${SY[io_r]} + ${SY[io_w]} ))
  v_text 2 2 'THROUGHPUT' $P_LBL
  printf -v s '%.1f MB/s' $rate
  v=$(( rate / 500.0 )); (( v > 1.0 )) && v=1.0
  sy_tone $v; v_text 13 2 "$s" $TON
  v=$rate; (( v < 0.001 )) && v=0.001
  sy_stack 26 2 $sw "$(( ${SY[io_r]} / v )):$CYAN" "$(( ${SY[io_w]} / v )):$MAGENTA"
  printf -v s '%.1f' ${SY[io_r]}; sy_legend $(( 28 + sw )) 2 $CYAN    read  "$s"
  printf -v s '%.1f' ${SY[io_w]}; sy_legend $(( 43 + sw )) 2 $MAGENTA write "$s"

  h=$(( nv + 3 )); (( h < 4 )) && h=4
  sy_panel $L 4 $W $h VOLUMES
  sy_rpad MOUNT $mcol; s="$RP"; sy_rpad DEVICE 11; s+="$RP"
  sy_lpad USED 7; s+="$LP"; sy_lpad SIZE 7; s+="  $LP"
  v_text $(( L + 2 )) 5 "$s" $P_LBL
  (( nv )) || v_text $(( L + 2 )) 6 'no volumes are mounted' $P_DIM
  for (( i = 0; i < nv; i++ )); do
    y=$(( 6 + i ))
    v=${SY[vols.$i.total]}; (( v < 0.001 )) && v=0.001
    frac=$(( ${SY[vols.$i.used]} / v ))
    mount="${SY[vols.$i.mount]}"
    (( ${#mount} > mcol - 1 )) && mount="…${mount[-$(( mcol - 2 )),-1]}"
    sy_rpad "$mount" $mcol
    (( i == 0 )) && v_text $(( L + 2 )) $y "$RP" $P_WHITE \
                 || v_text $(( L + 2 )) $y "$RP" $P_FG
    sy_rpad "${SY[vols.$i.dev][0,9]}" 11
    v_text $(( L + dcol )) $y "$RP" $P_DIM
    sy_human_g ${SY[vols.$i.used]};  sy_lpad "$HG" 7; sy_tone $frac
    v_text $(( L + ucol )) $y "$LP" $TON
    sy_human_g ${SY[vols.$i.total]}; sy_lpad "$HG" 7
    v_text $(( L + zcol )) $y "$LP" $P_FG
  done

  sy_panel $R 4 $RW2 $h FILL
  d=''; for (( i = 0; i < fw; i++ )); do d+='░'; done
  for (( i = 0; i < nv; i++ )); do
    v=${SY[vols.$i.total]}; (( v < 0.001 )) && v=0.001
    frac=$(( ${SY[vols.$i.used]} / v ))
    v_text $(( R + 2 )) $(( 6 + i )) "$d" $P_DIM
    sy_ease "vol.$i" $frac; sy_hbar $fw $SMF; sy_tone $frac
    v_text $(( R + 2 )) $(( 6 + i )) "$BAR" $TON
    printf -v s '%3.0f%%' $(( frac * 100 ))
    sy_right $(( R + RW2 - 2 )) $(( 6 + i )) "$s" $P_FG
  done
  v_text $(( R + 2 )) 5 'how full' $P_LBL
  sy_right $(( R + RW2 - 3 )) 5 'used' $P_LBL
  (( nv )) || v_text $(( R + 2 )) 6 'nothing to measure' $P_DIM

  y0=$(( 4 + h + 1 ))
  sy_panel $L $y0 $W 6 'DEVICE ACTIVITY'
  sy_human_n ${SY[io_rops]}
  printf -v s '%.2f MB/s   ·   %s operations/s' ${SY[io_r]} "$HN"
  sy_kv $(( L + 2 )) $(( y0 + 1 )) reading "$s" 12
  sy_human_n ${SY[io_wops]}
  printf -v s '%.2f MB/s   ·   %s operations/s' ${SY[io_w]} "$HN"
  sy_kv $(( L + 2 )) $(( y0 + 2 )) writing "$s" 12
  # SUMMED OVER EVERY BLOCK DRIVER, each counting from when IT attached -- so
  # an external plugged in this morning contributes its whole lifetime.
  s2='device'; (( ${SY[disks]} == 1 )) || s2='devices'
  sy_human_g ${SY[io_rtot]} iB
  sy_kv $(( L + 2 )) $(( y0 + 3 )) 'read total'  "$HG across ${SY[disks]} $s2" 12
  sy_human_g ${SY[io_wtot]} iB
  sy_kv $(( L + 2 )) $(( y0 + 4 )) 'write total' "$HG across ${SY[disks]} $s2" 12

  sy_panel $R $y0 $RW2 6 'BOOT VOLUME'
  v=${SY[disk_total]}; (( v < 0.001 )) && v=0.001
  frac=$(( ${SY[disk_used]} / v ))
  printf -v s '%.0f%%' $(( frac * 100 ))
  sy_meter $(( R + 2 )) $(( y0 + 1 )) $bmw $frac 'in use' "$s"
  sy_human_g ${SY[disk_used]} iB; sy_kv $(( R + 2 )) $(( y0 + 2 )) used "$HG" 10
  sy_human_g ${SY[disk_free]} iB
  # a colour, in a variable that is only ever a colour · see sy_draw_pwr
  (( frac > 0.92 )) && ink=$P_HOT || ink=$P_FG
  sy_kv $(( R + 2 )) $(( y0 + 3 )) free "$HG" 10 $ink
  sy_kv $(( R + 2 )) $(( y0 + 4 )) device "${SY[boot_disk]:--}" 10

  # the trace takes whatever rows the volume list left behind — to row 26 on
  # the cabinet, to the footer on the whole window
  i=$(( bot - (y0 + 8) )); (( i < 2 )) && i=2
  sy_hist_block $(( y0 + 7 )) 'READ AND WRITE' '%.1f MB/s' $i "${SY_IO_HIST[@]}"
  sy_page_foot "$SY_FOOT"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# NETWORK · this link, the sockets, and every interface carrying traffic
# ══════════════════════════════════════════════════════════════════════════
sy_draw_net() {
  local -i L=2 R=62 W=58 RW2=42 i y y0 h nif tot col
  # ON THE WHOLE WINDOW the two panels keep their 58:42 feel, the interface
  # table's numbers ride the right edge, and the two traces split the width
  local -i sw=46 tw=14 iw=102 extra=0 bot=26 tw2=49 ox=55 ipx=50
  if (( SCR_W > 120 )); then
    W=$(( (SCR_W - 6) * 58 / 100 )); R=$(( W + 4 )); RW2=$(( SCR_W - 6 - W ))
    sw=$(( SCR_W - 62 )); tw=$(( RW2 - 28 )); iw=$(( SCR_W - 4 )); extra=$(( iw - 102 ))
    bot=$(( SCR_H - 3 )); tw2=$(( (SCR_W - 8) / 2 )); ox=$(( 2 + tw2 + 4 )); ipx=$(( tw2 + 1 ))
  fi
  local -F rate v
  local s d
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  sy_page_head NETWORK "${SY[net_if]:--} · ${SY[net_ip]:-no address}"
  rate=$(( ${SY[net_rx]} + ${SY[net_tx]} ))
  v_text 2 2 'TRAFFIC' $P_LBL
  printf -v s '%.2f MB/s' $rate
  v=$(( rate / 120.0 )); (( v > 1.0 )) && v=1.0
  sy_tone $v; v_text 10 2 "$s" $TON
  v=$rate; (( v < 0.001 )) && v=0.001
  sy_stack 24 2 $sw "$(( ${SY[net_rx]} / v )):$CYAN" "$(( ${SY[net_tx]} / v )):$MAGENTA"
  printf -v s '%.2f' ${SY[net_rx]}; sy_legend $(( 26 + sw )) 2 $CYAN    in  "$s"
  printf -v s '%.2f' ${SY[net_tx]}; sy_legend $(( 40 + sw )) 2 $MAGENTA out "$s"

  sy_panel $L 4 $W 8 'THIS LINK'
  sy_kv $(( L + 2 )) 5 interface "${SY[net_if]:--}" 12
  sy_kv $(( L + 2 )) 6 address   "${SY[net_ip]:-none assigned}" 12
  sy_kv $(( L + 2 )) 7 hardware  "${SY[net_mac]:--}" 12
  sy_human_g ${SY[net_rxtot]} iB; s="$HG"; sy_human_n ${SY[net_ipkt]}
  sy_kv $(( L + 2 )) 8 received "$s   ·   $HN packets" 12
  sy_human_g ${SY[net_txtot]} iB; s="$HG"; sy_human_n ${SY[net_opkt]}
  sy_kv $(( L + 2 )) 9 sent     "$s   ·   $HN packets" 12
  sy_human_n ${SY[net_ierr]}; s="$HN"; sy_human_n ${SY[net_oerr]}
  (( ${SY[net_ierr]} + ${SY[net_oerr]} > 1000 )) && col=$P_HOT || col=$P_FG
  sy_kv $(( L + 2 )) 10 errors "$s in · $HN out, since it came up" 12 $col 41

  sy_panel $R 4 $RW2 8 'TCP SOCKETS'
  tot=$(( ${SY[conn_est]} + ${SY[conn_listen]} + ${SY[conn_wait]} ))
  (( tot < 1 )) && tot=1
  local -a cl cv2 cc
  cl=(established listening 'winding down')
  cv2=(${SY[conn_est]} ${SY[conn_listen]} ${SY[conn_wait]})
  cc=($CYAN $LIME $PURPLE)
  d=''; for (( i = 0; i < tw; i++ )); do d+='░'; done
  for (( i = 0; i < 3; i++ )); do
    y=$(( 5 + i ))
    sy_rpad "${cl[$i]}" 13
    v_text $(( R + 2 )) $y "$RP" $P_LBL
    v_text $(( R + 16 )) $y "$d" $P_DIM
    sy_ease "tcp.$i" $(( ${cv2[$i]} / (tot + 0.0) )); sy_hbar $tw $SMF
    v_text $(( R + 16 )) $y "$BAR" ${cc[$i]}
    sy_right $(( R + RW2 - 2 )) $y "${cv2[$i]}" $P_FG
  done
  v_hline $(( R + 2 )) 8 $(( RW2 - 4 )) '─' $P_DIM
  sy_kv $(( R + 2 )) 9  'tcp sockets' "$tot, in these states" 14
  sy_kv $(( R + 2 )) 10 interfaces "$SY_N_IFACES carrying traffic" 14

  nif=$SY_N_IFACES; (( nif > 6 )) && nif=6
  h=$(( nif + 3 )); (( h < 4 )) && h=4
  sy_panel $L 12 $iw $h 'EVERY INTERFACE'
  (( nif )) || v_text $(( L + 2 )) 14 'no interface is carrying traffic' $P_DIM
  sy_rpad NAME 9; s="$RP"; sy_rpad ADDRESS 17; s+="$RP"; sy_rpad HARDWARE 19; s+="$RP"
  for (( i = 0; i < extra; i++ )); do s+=' '; done
  sy_lpad RECEIVED 10; s+="$LP"; sy_lpad SENT 11; s+="$LP"
  sy_lpad 'PACKETS IN' 12; s+="$LP"; sy_lpad OUT 11; s+="$LP"; sy_lpad ERR 8; s+="$LP"
  v_text $(( L + 2 )) 13 "$s" $P_LBL
  for (( i = 0; i < nif; i++ )); do
    y=$(( 14 + i ))
    [[ "${SY[ifaces.$i.name]}" == "${SY[net_if]}" ]] && col=$P_WHITE || col=$P_FG
    sy_rpad "${SY[ifaces.$i.name]}" 9;  v_text $(( L + 2 ))  $y "$RP" $col
    s="${SY[ifaces.$i.ip]:-}"
    if [[ -n "$s" ]]; then sy_rpad "$s" 17; v_text $(( L + 11 )) $y "$RP" $col
    else sy_rpad '—' 17; v_text $(( L + 11 )) $y "$RP" $P_DIM; fi
    sy_rpad "${SY[ifaces.$i.mac]:-—}" 19; v_text $(( L + 28 )) $y "$RP" $P_DIM
    sy_human_g $(( ${SY[ifaces.$i.rxb]} / 1073741824.0 ))
    sy_right $(( L + 56 + extra )) $y "$HG" $col
    sy_human_g $(( ${SY[ifaces.$i.txb]} / 1073741824.0 ))
    sy_right $(( L + 67 + extra )) $y "$HG" $col
    sy_human_n ${SY[ifaces.$i.rxp]}; sy_right $(( L + 79 + extra )) $y "$HN" $P_DIM
    sy_human_n ${SY[ifaces.$i.txp]}; sy_right $(( L + 90 + extra )) $y "$HN" $P_DIM
    local -i e=$(( ${SY[ifaces.$i.ierr]} + ${SY[ifaces.$i.oerr]} ))
    (( e )) && col=$P_HOT || col=$P_DIM
    sy_right $(( L + 98 + extra )) $y "$e" $col
  done

  y0=$(( 12 + h + 1 ))
  i=$(( bot - (y0 + 1) )); (( i < 2 )) && i=2
  v=0.0; for s in "${SY_RX_HIST[@]}"; do (( s > v )) && v=$s; done
  v_text 2 $y0 'INBOUND' $P_LBL
  printf -v s 'peak %.1f MB/s' $v
  sy_right $ipx $y0 "$s" $P_DIM
  sy_trace 2 $(( y0 + 1 )) $tw2 $i "${SY_RX_HIST[@]}"
  v=0.0; for s in "${SY_TX_HIST[@]}"; do (( s > v )) && v=$s; done
  v_text $ox $y0 'OUTBOUND' $P_LBL
  printf -v s 'peak %.1f MB/s' $v
  sy_right $(( SCR_W - 3 )) $y0 "$s" $P_DIM
  sy_trace $ox $(( y0 + 1 )) $tw2 $i "${SY_TX_HIST[@]}"
  sy_page_foot "$SY_FOOT"
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# PROCESSES · the table, scrollable, with one row under the cursor
# ══════════════════════════════════════════════════════════════════════════
typeset -gi SY_PROW=23           # rows the table shows at once
typeset -gi SY_SEL=0 SY_TOP=0
SY_PC_W=(7 10 6 10 6 9 1 10 36)
SY_PC_L=(PID USER 'CPU%' '' 'MEM%' RSS S TIME COMMAND)
SY_PC_A=(r l r l r r l r l)

sy_draw_procs() {
  local -i i idx y x n col bg on ctone rtone lo cmdw=${SY_PC_W[8]}
  local -F scale cpu
  # NOT `path`.  It is one of zsh's own special parameters -- the array tied
  # to $PATH -- so `local path` shadows it and keeps the array binding, and
  # `${path[-35,-1]}` slices the SEARCH PATH rather than the string in it.
  # The COMMAND column came out as a bare ellipsis on every row.
  local s head exe
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  sy_order "${SY_SORTN[$SY_SORT]:l}"
  n=${#SY_ORD[@]}
  (( SY_SEL >= n )) && SY_SEL=$(( n - 1 ))
  (( SY_SEL < 0 )) && SY_SEL=0
  # THE WINDOW FOLLOWS THE CURSOR AND NEVER THE OTHER WAY ROUND.  Clamped to
  # the list first, then to the cursor, then to the list again -- a top left
  # past the end is a table of blank rows with a selection nobody can see.
  local -i top=$SY_TOP
  (( top > n - SY_PROW )) && top=$(( n - SY_PROW ))
  (( top < SY_SEL - SY_PROW + 1 )) && top=$(( SY_SEL - SY_PROW + 1 ))
  (( top > SY_SEL )) && top=$SY_SEL
  (( top > n - SY_PROW )) && top=$(( n - SY_PROW ))
  (( top < 0 )) && top=0
  SY_TOP=$top
  # the band under the cursor glides · it is aimed at the cursor's place in
  # the list, so a window that jumps takes the band with it
  local -F pos sk
  mo_ease cursor.sys.procs $SY_SEL $SY_NOW $MO_CURSOR; pos=$MV

  printf -v s '%d PROCESSES · %d THREADS · CPU%% IS PER CORE' ${SY[nproc]} ${SY[nthread]}
  sy_page_head PROCESSES "$s"

  # a summary strip, so the table opens with the shape of the machine
  printf -v s '%.1f%%' ${SY[cpu]}
  sy_meter 1 2 10 $(( ${SY[cpu]} / 100.0 )) PROCESSOR "$s"
  sy_human_g ${SY[mem_used]}; s="$HG"; sy_human_g ${SY[mem_total]}
  sy_meter 30 2 10 $(( ${SY[mem_pct]} / 100.0 )) MEMORY "$s/$HG"
  local -i run=0 slp=0 oth
  for (( i = 0; i < SY_N_PROCS; i++ )); do
    case "${SY[procs.$i.state]}" in
      R)   (( run++ )) ;;
      S|I) (( slp++ )) ;;
    esac
  done
  oth=$(( n - run - slp )); (( oth < 0 )) && oth=0
  printf -v s '%d running · %d sleeping' $run $slp
  (( oth )) && { printf -v head ' · %d other' $oth; s+="$head" }
  sy_right $(( SCR_W - 2 )) 2 "${s[0,39]}" $P_DIM

  head=' '
  for (( i = 0; i < ${#SY_PC_W[@]}; i++ )); do
    (( i )) && head+=' '
    if [[ "${SY_PC_A[$i]}" == r ]]; then sy_lpad "${SY_PC_L[$i]}" ${SY_PC_W[$i]}; head+="$LP"
    else                                 sy_rpad "${SY_PC_L[$i]}" ${SY_PC_W[$i]}; head+="$RP"; fi
  done
  sy_rpad "$head" $SCR_W
  v_text 0 3 "$RP" $GLASS $P_LBL

  scale=8.0
  (( n )) && (( ${SY[procs.${SY_ORD[0]}.cpu]} > scale )) && scale=${SY[procs.${SY_ORD[0]}.cpu]}
  local d=''
  for (( i = 0; i < 10; i++ )); do d+='░'; done
  for (( i = 0; i < SY_PROW; i++ )); do
    idx=$(( top + i ))
    (( idx >= n )) && break
    local -i j=${SY_ORD[$idx]}
    y=$(( 4 + i ))
    sk=$(( 1.0 - abs(idx - pos) )); (( sk < 0.0 )) && sk=0.0
    on=0; (( sk >= 0.5 )) && on=1
    if (( sk > 0.001 )); then cmix $GLASS $P_DIM $(( 0.60 * sk )); bg=$CM; else bg=$GLASS; fi
    v_fill 0 $y $SCR_W 1 ' ' $GREY $bg
    cpu=${SY[procs.$j.cpu]}
    if   (( cpu > 20 )); then ctone=$P_HOT
    elif (( cpu > 8 ));  then ctone=$P_WARM
    else                      ctone=$P_FG; fi
    local -i rss=${SY[procs.$j.rss]}
    if   (( rss > 2097152 )); then rtone=$P_HOT
    elif (( rss > 524288 ));  then rtone=$P_WARM
    else                           rtone=$P_DIM; fi
    exe="${SY[procs.$j.path]}"
    (( ${#exe} > cmdw )) && exe="…${exe[-$(( cmdw - 1 )),-1]}"
    x=1
    sy_lpad "${SY[procs.$j.pid]}" 7;   v_text $x $y "$LP" $P_LBL $bg; (( x += 8 ))
    sy_rpad "${SY[procs.$j.user]}" 10; v_text $x $y "$RP" $P_DIM $bg; (( x += 11 ))
    printf -v s '%.1f' $cpu; sy_lpad "$s" 6
    v_text $x $y "$LP" $ctone $bg; (( x += 7 ))
    # the bar is relative to the busiest process, so the column reads as a
    # chart rather than as ten empty cells
    v_text $x $y "$d" $P_DIM $bg
    sy_hbar 10 $(( cpu / scale ))
    v_text $x $y "$BAR" $ctone $bg; (( x += 11 ))
    printf -v s '%.1f' ${SY[procs.$j.mem]}; sy_lpad "$s" 6
    v_text $x $y "$LP" $P_FG $bg; (( x += 7 ))
    sy_human_b $rss; sy_lpad "$HB" 9
    v_text $x $y "$LP" $rtone $bg; (( x += 10 ))
    sy_rpad "${SY[procs.$j.state]}" 1; v_text $x $y "$RP" $P_LBL $bg; (( x += 2 ))
    sy_lpad "${SY[procs.$j.time]}" 10; v_text $x $y "$LP" $P_DIM $bg; (( x += 11 ))
    sy_rpad "$exe" $cmdw
    (( on )) && v_text $x $y "$RP" $P_WHITE $bg || v_text $x $y "$RP" $P_FG $bg
  done

  lo=0; (( n )) && lo=$(( top + 1 ))
  local -i hi=$(( top + SY_PROW )); (( hi > n )) && hi=$n
  local -i hl=$(( 4 + SY_PROW )) ft=$(( 5 + SY_PROW ))   # 27 · 28 on the cabinet
  v_hline 0 $hl $SCR_W '─' $P_DIM
  printf -v s '%d-%d OF %d  ·  BY %s' $lo $hi $n "${SY_SORTN[$SY_SORT]}"
  v_text 2 $ft "$s" $P_LBL
  sy_right $(( SCR_W - 3 )) $ft '◂ ▸ pages   ▴ ▾ move   [S] sort   [⎋] menu' $P_DIM
  if (( n > SY_PROW )); then
    local -i track=$SY_PROW hh pos
    hh=$(( int(track * SY_PROW / (n + 0.0)) )); (( hh < 1 )) && hh=1
    pos=$(( int((track - hh) * top / ((n - SY_PROW) > 1 ? (n - SY_PROW) : 1.0)) ))
    for (( i = 0; i < track; i++ )); do v_put $(( SCR_W - 1 )) $(( 4 + i )) '│' $P_DIM; done
    for (( i = 0; i < hh; i++ )); do v_put $(( SCR_W - 1 )) $(( 4 + pos + i )) '┃' $P_FG; done
  fi
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# HARDWARE · what this machine is, and what it has done
# ══════════════════════════════════════════════════════════════════════════
sy_draw_hw() {
  local -i L=$SY_L R=$SY_R W=$SY_W i
  # ON THE WHOLE WINDOW the two columns and their meters widen with the glass,
  # the value fields cap wider so long names are not clipped, and the trace at
  # the foot grows to stand on the footer · exact cabinet numbers when narrow
  local -i mw=$(( SCR_W > 120 ? SY_W - 34 : 16 ))
  local -i icap=$(( SCR_W > 120 ? SY_W - 19 : 31 ))
  local s right
  local -F v
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  sy_page_head HARDWARE "${SY[model_id]:-${SY[arch]}}"
  # RIGHT FIRST, THEN GIVE THE HOST WHATEVER IS LEFT.  Both halves used to be
  # written blind and the longer one ate the other mid-word.
  right="${${SY[cpu_model]:-?}}  ·  ${SY[osname]:-}"
  right="${right[0,$(( SCR_W > 120 ? SCR_W - 45 : 61 ))]}"
  i=$(( SCR_W - 7 - ${#right} )); (( i < 8 )) && i=8
  v_text 2 2 "${SY[host][0,$(( i - 1 ))]}" $P_WHITE
  sy_right $(( SCR_W - 2 )) 2 "$right" $P_FG
  v_hline 0 3 $SCR_W '─' $P_DIM

  sy_panel $L 4 $W 9 IDENTITY
  local -a ik iv
  ik=(name model processor architecture system build kernel)
  iv=("${SY[host]}" "${SY[model_id]:-unknown}" "${SY[cpu_model]:-unknown}" \
      "${SY[arch]}" "${SY[osname]:-}" "${SY[build]:-—}" "darwin ${SY[kernel]}")
  for (( i = 0; i < 7; i++ )); do
    sy_kv $(( L + 2 )) $(( 5 + i )) "${ik[$i]}" "${iv[$i]}" 13 -2 $icap
  done

  sy_panel $R 4 $W 9 CAPACITY
  printf -v s '%d logical · %d physical' ${SY[ncpu]} ${SY[nphys]}
  sy_kv $(( R + 2 )) 5 cores "$s" 13
  if (( ${SY[ncpu_p]:-0} && ${SY[ncpu_e]:-0} )); then
    printf -v s '%d performance · %d efficiency' ${SY[ncpu_p]} ${SY[ncpu_e]}
  else s='uniform'; fi
  sy_kv $(( R + 2 )) 6 'core split' "$s" 13
  sy_human_g ${SY[mem_total]};  sy_kv $(( R + 2 )) 7 memory "$HG installed" 13
  sy_human_g ${SY[swap_used]};  sy_kv $(( R + 2 )) 8 swap   "$HG in use" 13
  sy_human_g ${SY[disk_used]}; s="$HG"; sy_human_g ${SY[disk_total]}
  sy_kv $(( R + 2 )) 9 'boot volume' "$s of $HG" 13
  right='device'; (( ${SY[disks]} == 1 )) || right='devices'
  printf -v s '%d mounted · %d %s' $SY_N_VOLS ${SY[disks]} "$right"
  sy_kv $(( R + 2 )) 10 volumes "$s" 13
  if [[ "${SY[batt_pct]}" != null && -n "${SY[batt_pct]}" ]]; then
    printf -v s '%d cycles · %s' ${SY[batt_cycles]} "${SY[batt_health]:-—}"
  else s='none fitted'; fi
  sy_kv $(( R + 2 )) 11 battery "$s" 13

  sy_panel $L 13 $W 7 'SINCE IT WAS TURNED ON'
  if (( ${SY[boot]:-0} )); then
    strftime -s s '%a %d %b %Y, %H:%M' ${SY[boot]} 2>/dev/null || s=''

    [[ -n "$s" ]] || s='unknown'
  else s='unknown'; fi
  sy_kv $(( L + 2 )) 14 booted "$s" 13 -2 $(( SCR_W > 120 ? SY_W - 17 : 33 ))
  sy_up ${SY[uptime]};            sy_kv $(( L + 2 )) 15 uptime "$UPS" 13
  sy_human_g ${SY[io_rtot]} iB;   sy_kv $(( L + 2 )) 16 read    "$HG from disk" 13
  sy_human_g ${SY[io_wtot]} iB;   sy_kv $(( L + 2 )) 17 written "$HG to disk" 13
  sy_human_g ${SY[net_rxtot]} iB
  sy_kv $(( L + 2 )) 18 received "$HG over ${SY[net_if]:--}" 13

  sy_panel $R 13 $W 7 'RIGHT NOW'
  printf -v s '%.1f%%' ${SY[cpu]}
  sy_meter $(( R + 2 )) 14 $mw $(( ${SY[cpu]} / 100.0 )) processor "$s"
  v=${SY[mem_total]}; (( v < 0.001 )) && v=0.001
  sy_human_g ${SY[mem_used]}; s="$HG"; sy_human_g ${SY[mem_total]}
  sy_meter $(( R + 2 )) 15 $mw $(( ${SY[mem_used]} / v )) memory "$s / $HG"
  v=${SY[disk_total]}; (( v < 0.001 )) && v=0.001
  printf -v s '%.0f%%' $(( 100.0 * ${SY[disk_used]} / v ))
  sy_meter $(( R + 2 )) 16 $mw $(( ${SY[disk_used]} / v )) volume "$s"
  printf -v s '%d · %d threads' ${SY[nproc]} ${SY[nthread]}
  sy_kv $(( R + 2 )) 17 processes "$s" 11
  printf -v s '%.2f  %.2f  %.2f' ${SY[load.0]} ${SY[load.1]} ${SY[load.2]}
  sy_kv $(( R + 2 )) 18 load "$s" 11

  sy_hist_block 20 PROCESSOR '%.0f%%' $(( SCR_W > 120 ? SCR_H - 24 : 4 )) "${SY_CPU_HIST[@]}"
  sy_page_foot "$SY_FOOT"
  return 0
}


# ══════════════════════════════════════════════════════════════════════════
# POWER · the cell, what is crossing its terminals, and how it has aged
# ══════════════════════════════════════════════════════════════════════════
sy_draw_pwr() {
  local -i L=$SY_L R=$SY_R W=$SY_W i y col ink has ac cyc cmax design full now pct lost
  local -F frac hpct tc amps watts v
  local s st_ d dd
  # ON THE WHOLE WINDOW the six cards become three tall rows that tile the
  # glass top to footer, each card's readings centred in its taller box, and
  # every bar widens · the exact cabinet rows (5/12/19, height 7) when narrow
  local -i pb1=5 pb2=12 pb3=19 ph1=7 ph2=7 ph3=7 cb1=6 cb2=13 cb3=20
  local -i cw=102 cpw=18 dvw=16
  if (( SCR_W > 120 )); then
    cw=$(( SCR_W - 4 )); cpw=$(( SY_W - 32 )); dvw=$(( SY_W - 34 ))
    local -i av=$(( SCR_H - 7 ))          # the rows from 5 down to the footer
    ph1=$(( av / 3 )); ph2=$ph1; ph3=$(( av - 2 * ph1 ))
    pb2=$(( pb1 + ph1 )); pb3=$(( pb2 + ph2 ))
    cb1=$(( pb1 + 1 + (ph1 - 7) / 2 ))
    cb2=$(( pb2 + 1 + (ph2 - 7) / 2 ))
    cb3=$(( pb3 + 1 + (ph3 - 7) / 2 ))
  fi
  v_fill 0 0 $SCR_W $SCR_H ' ' $GREY $GLASS
  pct=${SY[batt_pct]:-0}; design=${SY[batt_design]:-0}; full=${SY[batt_max]:-0}
  ac=${SY[ac]:-0}
  # A MACHINE WITH NO CELL IS NOT A MACHINE AT NOUGHT PER CENT.  The reading
  # starts at zero like every other, so the charge alone cannot tell the two
  # apart -- a design capacity can.
  has=0; (( pct > 0 || design > 0 )) && has=1
  if (( has )); then (( ac )) && s='ON WALL POWER' || s='ON BATTERY'
  else s='NO BATTERY IN THIS MACHINE'; fi
  sy_page_head POWER "$s"

  frac=$(( pct / 100.0 ))
  if   (( frac > 0.5 )); then col=$LIME
  elif (( frac > 0.2 )); then col=$AMBER
  else                        col=$RED; fi
  v_text 2 2 'CHARGE' $P_LBL
  (( has )) && printf -v s '%d%%' $pct || s='—'
  v_text 9 2 "$s" $col
  s="${SY[batt_state]:-}"
  [[ -n "$s" && "$s" != null ]] || { (( ac )) && s='wall power' || s='unknown' }
  v_text 15 2 "$s" $P_FG
  if (( ${SY[lowpower]:-0} )); then
    cmix $BLACK $AMBER 0.15; local -i lfg=$CM
    cmix $AMBER $WHITE 0.10
    v_text 34 2 ' LOW POWER MODE ' $lfg $CM
  fi
  # pmset SAYS "H:MM remaining" FOR THREE DIFFERENT QUANTITIES: time left on
  # the cell, time until full, and -- full and plugged in -- zero.  Taking all
  # three as runtime told a charged laptop on the wall it had none left.
  st_="${${SY[batt_state]:-}:l}"
  if (( ${SY[batt_mins]:--1} > 0 )) && [[ "$st_" == *charging* && "$st_" != *'not '* ]]; then
    printf -v s '%dh %02dm until full' $(( ${SY[batt_mins]} / 60 )) $(( ${SY[batt_mins]} % 60 ))
    sy_right $(( SCR_W - 2 )) 2 "$s" $P_FG
  elif (( ${SY[batt_mins]:--1} > 0 && ! ac )); then
    printf -v s '%dh %02dm remaining' $(( ${SY[batt_mins]} / 60 )) $(( ${SY[batt_mins]} % 60 ))
    sy_right $(( SCR_W - 2 )) 2 "$s" $P_FG
  elif (( ac )); then
    [[ "$st_" == *charged* ]] && s='full' || s='on the wall'
    sy_right $(( SCR_W - 2 )) 2 "$s" $P_DIM
  fi
  d=''; for (( i = 0; i < cw; i++ )); do d+='░'; done
  v_text 2 3 "$d" $P_DIM
  sy_ease pwr.charge $frac; sy_hbar $cw $SMF; v_text 2 3 "$BAR" $col

  # ── health ─────────────────────────────────────────────────────────────
  sy_panel $L $pb1 $W $ph1 HEALTH
  hpct=0.0; (( design )) && hpct=$(( 100.0 * full / design ))
  if   (( hpct >= 80 )); then col=$LIME
  elif (( hpct >= 60 )); then col=$AMBER
  else                        col=$RED; fi
  sy_rpad capacity 11; v_text $(( L + 2 )) $cb1 "$RP" $P_LBL
  (( design )) && printf -v s '%.0f%%' $hpct || s='—'
  v_text $(( L + 14 )) $cb1 "$s" $col
  s="${SY[batt_health]:-}"; [[ -n "$s" && "$s" != null ]] || s='unknown'
  sy_right $(( L + W - 3 )) $cb1 "${s:u}" $col
  dd=''; for (( i = 0; i < W - 6; i++ )); do dd+='░'; done
  v_text $(( L + 2 )) $(( cb1 + 1 )) "$dd" $P_DIM
  sy_ease pwr.health $(( hpct / 100.0 )); sy_hbar $(( W - 6 )) $SMF; v_text $(( L + 2 )) $(( cb1 + 1 )) "$BAR" $col
  cyc=${SY[batt_cycles]:-0}; cmax=${SY[batt_cyc_max]:-0}; (( cmax )) || cmax=1000
  sy_rpad cycles 11; v_text $(( L + 2 )) $(( cb1 + 2 )) "$RP" $P_LBL
  printf -v s '%d of %d' $cyc $cmax
  v_text $(( L + 14 )) $(( cb1 + 2 )) "$s" $P_FG
  printf -v s '%.0f%% of rated life' $(( 100.0 * cyc / cmax ))
  sy_right $(( L + W - 3 )) $(( cb1 + 2 )) "$s" $P_DIM
  v_text $(( L + 2 )) $(( cb1 + 3 )) "$dd" $P_DIM
  sy_ease pwr.cycles $(( cyc / (cmax + 0.0) )); sy_hbar $(( W - 6 )) $SMF
  (( cyc > cmax * 0.8 )) && col=$P_HOT || col=$P_WARM
  v_text $(( L + 2 )) $(( cb1 + 3 )) "$BAR" $col
  (( ac )) && { s='connected'; col=$LIME } || { s='not connected'; col=$P_DIM }
  sy_kv $(( L + 2 )) $(( cb1 + 4 )) 'wall power' "$s" 11 $col

  # ── temperature ────────────────────────────────────────────────────────
  sy_panel $R $pb1 $W $ph1 TEMPERATURE
  if [[ "${SY[temp]}" == null || -z "${SY[temp]}" ]] || (( ${SY[temp]:-0} == 0 )); then
    v_text $(( R + 2 )) $(( cb1 + 1 )) 'no battery thermistor to read' $P_DIM
  else
    tc=${SY[temp]}
    if   (( tc < 40 )); then col=$LIME;  s=normal
    elif (( tc < 50 )); then col=$AMBER; s=warm
    else                     col=$RED;   s=hot; fi
    sy_rpad battery 11; v_text $(( R + 2 )) $cb1 "$RP" $P_LBL
    printf -v dd '%.1f °C   ·   %.1f °F' $tc $(( tc * 9.0 / 5.0 + 32.0 ))
    v_text $(( R + 14 )) $cb1 "$dd" $col
    sy_right $(( R + W - 3 )) $cb1 "${s:u}" $col
    dd=''; for (( i = 0; i < W - 6; i++ )); do dd+='░'; done
    v_text $(( R + 2 )) $(( cb1 + 1 )) "$dd" $P_DIM
    v=$(( tc / 60.0 )); (( v < 0.0 )) && v=0.0; (( v > 1.0 )) && v=1.0
    sy_ease pwr.temp $v; sy_hbar $(( W - 6 )) $SMF; v_text $(( R + 2 )) $(( cb1 + 1 )) "$BAR" $col
    v_text $(( R + 2 )) $(( cb1 + 2 )) '0 °C' $P_DIM
    sy_right $(( R + W - 3 )) $(( cb1 + 2 )) '60 °C' $P_DIM
  fi
  s="${SY[therm]:-}"; [[ -n "$s" && "$s" != null ]] || s='nominal'
  [[ "$s" == *throttl* ]] && col=$RED || col=$LIME
  sy_kv $(( R + 2 )) $(( cb1 + 3 )) processor "$s" 11 $col
  [[ "$s" == *throttl* ]] && dd='clocked down to stay cool' || dd='running at full speed'
  sy_kv $(( R + 2 )) $(( cb1 + 4 )) meaning "$dd" 11 -2 34

  # ── electrical ─────────────────────────────────────────────────────────
  sy_panel $L $pb2 $W $ph2 ELECTRICAL
  amps=${SY[batt_amp]:-0.0}; watts=${SY[watts]:-0.0}
  if   (( ${SY[batt_charging]:-0} )); then s=charging;    dd='▲'; col=$LIME
  elif (( amps != 0.0 ));             then s=discharging; dd='▼'; col=$AMBER
  else                                     s=idle;        dd='·'; col=$AMBER; fi
  printf -v d '%.1f W' $watts
  # NOT `i`.  A loop index that has held a COLOUR is not the same variable it
  # was: zsh remembers the base a number was first written in, so one palette
  # entry spelled 0x60FFA8 leaves `i` printing as `16#0`, and the next
  # `${SY[devices.$i.name]}` asks for `devices.16#0.name` -- an unset key,
  # which under `set -u` ends the program.  It is masked today only because
  # _pack happens to build every colour in decimal.
  (( watts > 40 )) && ink=$P_HOT || ink=$P_FG
  sy_kv $(( L + 2 )) $cb2 drawing "$d" 11 $ink
  printf -v d '%.2f V' ${SY[batt_volt]:-0.0}
  sy_kv $(( L + 2 )) $(( cb2 + 1 )) voltage "$d" 11
  sy_rpad current 11; v_text $(( L + 2 )) $(( cb2 + 2 )) "$RP" $P_LBL
  printf -v d '%d mA' $(( int(abs(amps * 1000)) ))
  v_text $(( L + 14 )) $(( cb2 + 2 )) "$d" $P_FG
  v_text $(( L + 24 )) $(( cb2 + 2 )) "$dd" $col
  sy_right $(( L + W - 3 )) $(( cb2 + 2 )) "$s" $P_FG
  dd=''; for (( i = 0; i < W - 6; i++ )); do dd+='░'; done
  v_text $(( L + 2 )) $(( cb2 + 3 )) "$dd" $P_DIM
  v=$(( watts / 60.0 )); (( v < 0.0 )) && v=0.0; (( v > 1.0 )) && v=1.0
  sy_ease pwr.watts $v; sy_hbar $(( W - 6 )) $SMF; v_text $(( L + 2 )) $(( cb2 + 3 )) "$BAR" $col
  (( ${SY[batt_charging]:-0} )) && d='into the battery' || d='out of the battery'
  v_text $(( L + 2 )) $(( cb2 + 4 )) "$d  ·  0-60 W scale" $P_DIM

  # ── capacity ───────────────────────────────────────────────────────────
  sy_panel $R $pb2 $W $ph2 CAPACITY
  now=${SY[batt_now]:-0}
  local -a cl cvv cc
  cl=(remaining 'full charge' 'as designed'); cvv=($now $full $design)
  cc=($LIME $CYAN $P_DIM)
  dd=''; for (( i = 0; i < cpw; i++ )); do dd+='░'; done
  for (( i = 0; i < 3; i++ )); do
    y=$(( cb2 + i ))
    sy_rpad "${cl[$i]}" 12; v_text $(( R + 2 )) $y "$RP" $P_LBL
    v_text $(( R + 15 )) $y "$dd" $P_DIM
    sy_ease "pwr.cap.$i" $(( ${cvv[$i]} / ((design > 1 ? design : 1) + 0.0) )); sy_hbar $cpw $SMF
    v_text $(( R + 15 )) $y "$BAR" ${cc[$i]}
    printf -v s '%d mAh' ${cvv[$i]}
    sy_right $(( R + W - 3 )) $y "$s" ${cc[$i]}
  done
  lost=$(( design - full ))
  if (( design && full && lost > 0 )); then
    printf -v s '%d mAh of the original %d has gone with age' $lost $design
  elif (( full )); then s='this cell still holds what it was built to hold'
  else s='this machine does not report its capacity'; fi
  v_text $(( R + 2 )) $(( cb2 + 4 )) "$s" $P_DIM

  # ── what else is on the charge ─────────────────────────────────────────
  local -i nd=$SY_N_DEVICES
  (( nd > 5 )) && nd=5
  sy_panel $L $pb3 $W $ph3 'LINKED DEVICES'
  # a rule where a device would be, and the reason over the top of it
  d=''; for (( i = 0; i < W - 4; i++ )); do d+='·'; done
  cshade $P_DIM 0.35
  for (( i = nd; i < 5; i++ )); do v_text $(( L + 2 )) $(( cb3 + i )) "$d" $CS; done
  (( nd )) || v_text $(( L + 2 )) $(( cb3 + 1 )) 'nothing paired is reporting a charge' $P_DIM
  dd=''; for (( i = 0; i < dvw; i++ )); do dd+='░'; done
  for (( i = 0; i < nd; i++ )); do
    y=$(( cb3 + i ))
    local -i dp=${SY[devices.$i.pct]:-0}
    if   (( dp > 50 )); then col=$LIME
    elif (( dp > 20 )); then col=$AMBER
    else                     col=$RED; fi
    sy_rpad "${SY[devices.$i.name][0,19]}" 21
    v_text $(( L + 2 )) $y "$RP" $P_FG
    v_text $(( L + 23 )) $y "$dd" $P_DIM
    sy_ease "pwr.dev.$i" $(( dp / 100.0 )); sy_hbar $dvw $SMF
    v_text $(( L + 23 )) $y "$BAR" $col
    printf -v s '%d%%' $dp
    sy_right $(( L + W - 3 )) $y "$s" $col
  done

  sy_panel $R $pb3 $W $ph3 'THIS MACHINE'
  sy_up ${SY[uptime]}; sy_kv $(( R + 2 )) $cb3 uptime "$UPS" 11
  printf -v s '%.1f%% of %d cores' ${SY[cpu]} ${SY[ncpu]}
  sy_kv $(( R + 2 )) $(( cb3 + 1 )) processor "$s" 11
  sy_human_g ${SY[mem_used]}; s="$HG"; sy_human_g ${SY[mem_total]}
  sy_kv $(( R + 2 )) $(( cb3 + 2 )) memory "$s of $HG" 11
  # NOT THE MACHINE'S DRAW: this is the power crossing the cell's own
  # terminals, which is zero on the wall at a full charge.
  if (( watts != 0.0 )); then printf -v s '%.1f W' $watts; else s='none'; fi
  sy_kv $(( R + 2 )) $(( cb3 + 3 )) 'battery flow' "$s" 11
  (( ${SY[lowpower]:-0} )) && { s=on; col=$AMBER } || { s=off; col=$P_DIM }
  sy_kv $(( R + 2 )) $(( cb3 + 4 )) 'low power' "$s" 11 $col
  sy_page_foot "$SY_FOOT"
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# CHANGING WHAT IS ON THE GLASS · through the raster, never in place of it
# ══════════════════════════════════════════════════════════════════════════
# THIS MACHINE KNOWS ONE WAY TO CHANGE A PICTURE and it is the way it came on:
# the raster lets go, collapses to a line, and unfolds again with the new
# surface already on it.  The transition itself -- its three stages, its
# curves, its timing, the wash it lays over the new page -- is the CABINET'S
# (xf_arm / xf_frame in terminal.command), the same channel change every
# surface in the house uses, and the same one INTELLIGENCE turns its pages
# with.  This file only says WHEN: sy_go_view arms it, sys_draw paints the
# standing page, and the cabinet runs the frames between.
sy_go_view() {   # sy_go_view DEST — the only way SYS_VIEW is ever written
  [[ "$1" == "$SYS_VIEW" ]] && return 0
  SYS_VIEW="$1"
  xf_arm
  return 0
}
sy_page_go() {   # sy_page_go D — ◂ ▸ ring through the instruments, the way
                 # INTELLIGENCE's pages do · wraps, and keeps the list cursor with it
  local -i n=${#SY_MV[@]} i=0 j
  for (( j = 0; j < n; j++ )); do [[ "${SY_MV[$j]}" == "$SYS_VIEW" ]] && { i=$j; break }; done
  i=$(( ($1 + i + n) % n ))
  sy_go_view "${SY_MV[$i]}"; SYS_ROW=$i; snd move
  return 0
}

sy_surface() {   # sy_surface T — whichever page is standing
  # SEVEN OF THE NINE PAGES ARE PURE FUNCTIONS OF THE LAST READING, and they
  # were being painted from scratch every frame -- two hundred v_text calls
  # a frame to draw a table that changes once every ten seconds.  So a page
  # is painted once per reading (and once per cursor move, and once a frame
  # while a bar is still easing) into the cabinet's glass cache, and a frame
  # is a copy.  The list page keeps its marquee and its cursor rows live;
  # the scope is live through and through.
  local flight=0
  mo_moving $SY_NOW && flight=$SY_NOW
  case "$SYS_VIEW" in
    menu)  glass_cached "sys.menu|$SY_GEN|${SCR_W}x${SCR_H}" sy_draw_menu_base
           sy_menu_rows; sy_menu_beam ;;
    scope) sy_draw_scope "$1" ;;
    cpu|mem|disk|net|pwr|hw|procs)
           glass_cached "sys.$SYS_VIEW|$SY_GEN|$SY_SORT|$SY_SEL|$SY_TOP|$flight|${SCR_W}x${SCR_H}" sy_draw_$SYS_VIEW ;;
    # AN UNKNOWN VIEW SAYS SO.  This used to fall back to the instrument
    # list, which is how eight pages that were not built yet looked exactly
    # like a machine refusing to open anything.
    *)     sy_draw_soon "${SYS_VIEW:u}" ;;
  esac
  return 0
}

sys_draw() {   # sys_draw T — the standing page · the cabinet runs the channel change around it
  SY_NOW=$1
  # THE DOOR'S CARD FIRST · see sy_title
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_card]} )); then sy_title $1; return 0; fi
  sy_geom            # size the three columns to whatever glass this is, first
  # WHICH PAGES HAVE A FILL LAYOUT YET.  The rest keep the cabinet glass and
  # centre on the lit fill until they are taught to reflow, one by one.
  case "$SYS_VIEW" in
    menu|cpu|procs|hw|pwr|mem|disk|net|scope) PACK_FILL=1 ;;
    *)                                        PACK_FILL=0 ;;
  esac
  sy_surface $1
  return 0
}

# ── the key map · [M] is the way out and is not a page ────────────────────
sys_key() {   # sys_key KEY — 0 if this machine took it
  local k="$1"
  local -i i
  # ON THE CARD, ANY KEY GOES IN · the four answers are the door's (tc_key)
  if (( ${SURF_TITLE:-0} )) && (( ${+functions[tc_key]} )); then tc_key "$k"; return $?; fi
  case "$k" in
    # THE CURSOR, SAID FOUR WAYS.  The door hands arrows over as words -- it
    # has already eaten the escape and the bracket by the time it knows what
    # they were -- and j/k are here because a reader who lives in vim will
    # try them before they try anything else.
    # ▴▾ MOVE WHATEVER THE PAGE IN FRONT HAS A CURSOR IN.  On the instrument
    # list that is the list; on PROCESSES it is the table, which has its own
    # selection and its own window onto a hundred-odd rows.  Without this the
    # table's cursor sat on row zero for ever, its scrollbar never moved, and
    # only the first twenty-three processes were reachable -- on a page whose
    # footer says `▴ ▾ move`.
    down|j|J)
      if [[ "$SYS_VIEW" == procs ]]; then
        (( SY_SEL < SY_N_PROCS - 1 )) && { (( SY_SEL++ )); snd move }
      else
        (( SYS_ROW < ${#SY_MK[@]} - 1 )) && { (( SYS_ROW++ )); snd move }
      fi
      return 0 ;;
    up|k|K)
      if [[ "$SYS_VIEW" == procs ]]; then
        (( SY_SEL > 0 )) && { (( SY_SEL-- )); snd move }
      else
        (( SYS_ROW > 0 )) && { (( SYS_ROW-- )); snd move }
      fi
      return 0 ;;
    # THE WHEEL IS THE CURSOR, QUIETLY.  The door hands a wheel notch over the
    # glass to the machine as a word of its own (SECTION 18a there), one per
    # notch, so a page with a cursor moves it and a page without one -- a
    # gauge, a table that fits -- lets the notch go by.  No sound: a notch is
    # not a press, and a trackpad flick is thirty of them.
    wheeldown|wheelup)
      if [[ "$SYS_VIEW" == procs ]]; then
        if [[ "$k" == wheeldown ]]; then (( SY_SEL < SY_N_PROCS - 1 )) && SY_SEL=$(( SY_SEL + 1 ))
        else                             (( SY_SEL > 0 )) && SY_SEL=$(( SY_SEL - 1 )); fi
      elif [[ "$SYS_VIEW" == menu ]]; then
        if [[ "$k" == wheeldown ]]; then (( SYS_ROW < ${#SY_MK[@]} - 1 )) && SYS_ROW=$(( SYS_ROW + 1 ))
        else                             (( SYS_ROW > 0 )) && SYS_ROW=$(( SYS_ROW - 1 )); fi
      fi
      return 0 ;;
    pgup|pgdn)
      # a page of the table at a time · nowhere else has a page to turn
      if [[ "$SYS_VIEW" == procs ]]; then
        if [[ "$k" == pgdn ]]; then SY_SEL=$(( SY_SEL + 20 )); (( SY_SEL > SY_N_PROCS - 1 )) && SY_SEL=$(( SY_N_PROCS - 1 ))
        else                        SY_SEL=$(( SY_SEL - 20 )); (( SY_SEL < 0 )) && SY_SEL=0; fi
        (( SY_SEL < 0 )) && SY_SEL=0
        return 0
      fi
      return 1 ;;
    # [S] CYCLES THE SORT, which the footer has been promising and the door
    # has been answering `no S on this machine` to.  The cursor goes back to
    # the top with it: a selection held across a re-sort is a highlight that
    # jumps to an unrelated process.
    s|S)
      if [[ "$SYS_VIEW" == procs ]]; then
        SY_SORT=$(( (SY_SORT + 1) % ${#SY_SORTN[@]} ))
        SY_SEL=0; SY_TOP=0; snd pick
        return 0
      fi
      return 1 ;;
    enter)     sy_go_view "${SY_MV[$SYS_ROW]}"; snd pick; return 0 ;;
    # ⎋ IS BACK ONE, AND ONLY THE MACHINE KNOWS WHAT ONE IS.  On a page it is
    # the way to the instrument list; on the instrument list there is nothing
    # left to go back to, so it is REFUSED -- and the door, which offered it
    # here first, takes that as its own and closes the machine.  One key, two
    # meanings, and neither of them a level skipped.
    # ⎋ IS BACK ONE · from a page it climbs to this machine's own menu; from the
    # menu there is nothing left to climb to, so it is refused and the door takes
    # it as the way out to the suite.
    esc)
      if [[ "$SYS_VIEW" != menu ]]; then sy_go_view menu; snd away; return 0; fi
      return 1 ;;
    # ◂ ▸ RING THROUGH THE INSTRUMENTS, exactly the way INTELLIGENCE pages · on
    # the list itself there is nothing to page, so ▸ opens the row under the
    # cursor and ◂ is idle.
    left)
      [[ "$SYS_VIEW" == menu ]] && return 0
      sy_page_go -1; return 0 ;;
    right)
      if [[ "$SYS_VIEW" == menu ]]; then sy_go_view "${SY_MV[$SYS_ROW]}"; snd pick; return 0; fi
      sy_page_go 1; return 0 ;;
  esac
  for (( i = 0; i < ${#SY_MK[@]}; i++ )); do
    [[ "${k:u}" == "${SY_MK[$i]}" ]] || continue
    sy_go_view "${SY_MV[$i]}"; SYS_ROW=$i; snd pick; return 0
  done
  return 1
}

# ── what the cabinet wears while this machine is standing in it ───────────
sys_dress() {
  SURF_MODEL="$SY_MODEL"
  sy_spaced "$PACK_NAME"; SURF_SIGN="◂ $SPD ▸"
  SURF_TAG="ALIEN DYNAMICS · MODEL $SY_MODEL"
  local out='' i
  for (( i = 0; i < ${#SY_MK[@]}; i++ )); do
    out+="${out:+   }[${SY_MK[$i]}]${SY_SHORT[$i]}"
  done
  SURF_KEYS="[▲▼]CHOOSE   [⏎]OPEN   $out   [⎋]BACK"
  (( ${SURF_TITLE:-0} )) && SURF_KEYS="${TC_KEYS:-$SURF_KEYS}"
  sy_up ${SY[uptime]}; SURF_BADGE=" UPTIME ${UPS%%d *}d "
  SURF_MSG='ALL SYSTEMS NOMINAL'
  return 0
}

# ══════════════════════════════════════════════════════════════════════════
# THE SEAM · run on its own, this file is a probe and nothing else
# ══════════════════════════════════════════════════════════════════════════
# SOURCED, IT DEFINES AND RETURNS.  zsh names the sourcing file in $0 under
# the option this file sets, so "was I run or was I sourced" is asked of
# ZSH_EVAL_CONTEXT, which says `toplevel` for a script and `toplevel:file`
# for a source.
# SOURCED, IT DEFINES AND RETURNS -- AND THE DOOR SAYS SO OUT LOUD.  This
# used to be inferred from ZSH_EVAL_CONTEXT, which is right in every zsh this
# was tried in and is still an inference about somebody else's shell made by a
# file whose only other option is `exit`.  The door sets PACK_SOURCED before
# it sources; the context check stays underneath it for anyone sourcing this
# by hand.  Two ways to be sure, and the cost of being wrong is the reader's
# window closing without a word.
if [[ -z "${PACK_SOURCED:-}" ]] && [[ "${ZSH_EVAL_CONTEXT:-toplevel}" != *:file* ]]; then
  sy_init
  if [[ "${1:-}" == --probe ]]; then
    sy_tick_all 1.0
    sy_tick_slow
    sy_probe
    exit 0
  fi
  print -r -- "system.zsh is a page pack for terminal.command · try --probe"
  exit 0
fi
