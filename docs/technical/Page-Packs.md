<!--
title: '🧩 PAGE PACKS'
description: 'The contract between terminal.command and the four machines in scripts/suite: what a pack declares, when the door calls each hook, what it draws with, the rules it keeps, how a failing pack is caught, and what the door holds about each machine. Read it before changing a machine or adding one.'
type: guide
-->

<div align="center">

# 🧩 PAGE PACKS

<a name="top"></a>

**What a machine hands the door, and what the door does with it, hook by hook.**

_The door keeps the cabinet; a pack brings its pages._

</div>

---

## 💡 What A Pack Is

A machine in [`scripts/suite/`](../../scripts/suite/README.md) is a **page
pack**: a zsh file that `terminal.command` sources into its own process. The
door keeps the walls, the tube, the frame rate, the keyboard and the terminal
itself; the pack keeps its readings and draws its pages inside the rectangle of
glass it is given, 106 x 30 cells in the floating cabinet and the whole window
in fill mode.

**A pack is sourced once per cabinet.** Sourcing runs its top level, which is
where it declares and zeroes its tables, so a second source would wipe
whatever the reader had left there. The door remembers every pack it has read,
with its hooks, in `PACK_SEEN`, and walking back into a machine binds those
hooks again and repaints. From power-on the door reads every pack in ahead of
the reader, behind the stars or on the menu's spare beats, INTELLIGENCE first,
so opening one is a repaint and not a wait.

---

## ⚙️ What A Pack Declares

At its top level, a pack names itself and the functions the door may call. An
empty hook is never called:

| Variable     | Called as                              | When                                                                   |
| :----------- | :------------------------------------- | :--------------------------------------------------------------------- |
| `PACK_NAME`  | -                                      | The name the machine's glass is signed with                            |
| `PACK_MODEL` | -                                      | The model plate let into the bezel                                     |
| `PACK_INIT`  | `fn`                                   | Once, right after the pack is sourced                                  |
| `PACK_WARM`  | `fn N T`                               | Step `N` of getting ready behind the stars, at the cabinet's clock `T` |
| `PACK_FIRST` | `fn`                                   | Once, when the reader first opens the machine                          |
| `PACK_TICK`  | `fn T`                                 | Every frame the machine is standing                                    |
| `PACK_DRAW`  | `fn T`                                 | Every frame, inside the door's channel change                          |
| `PACK_KEY`   | `fn KEY`                               | Every key the machine is offered                                       |
| `PACK_RAW`   | `fn want`, `fn mouse`, `fn feed BYTES` | Before each key is parsed, while the machine is standing               |
| `PACK_DRESS` | `fn`                                   | When the chrome around the glass is drawn again                        |
| `PACK_LEAVE` | `fn`                                   | When the cabinet goes down, whatever took it down                      |

`PACK_WARM` answers **0** for a step taken (the next one is queued), **2** for
not yet (the same step is asked again later), and anything else when there is
nothing left. Its steps go to the back of the queue, so the machines come up
together. `PACK_FIRST` is for what opening a machine means to the reader, a
visit counted or the save read as it stands then, and is never done ahead of
time.

`PACK_KEY` is offered `up`, `down`, `left`, `right`, `pgup`, `pgdn`, `enter`,
`esc`, `back`, `wheelup`, `wheeldown`, or the character typed, and answers 0
when it used the key. A key it refuses falls to the door: `esc`, `back` and
`m` close the machine, `q` opens the power question, and any other letter puts
`no X on this machine` on the coin door. `enter`, the arrows and the wheel are
offered with stdout sent to `/dev/null`, so printing from a key handler draws
nothing, and `surf_handover` reaches the terminal by name for that reason.

`PACK_RAW want` is asked before anything is parsed. A yes hands the pack the
whole burst of bytes in the buffer, and `mouse` decides whether mouse reports
go with them or are sifted out first. INTELLIGENCE says yes while a live
session in its terminal on the glass has the keyboard, and the ARCADE while a
round is in play.

`PACK_DRESS` sets the words around the glass: `SURF_MODEL`, `SURF_SIGN`,
`SURF_TAG`, `SURF_KEYS`, `SURF_BADGE` and `SURF_MSG`. A page that has a layout
for the whole window sets `PACK_FILL=1` in its draw function; the door resets
it to 0 each time a machine opens.

| Hook         | SYSTEM      | INTELLIGENCE  | XENOGOTCHI | ARCADE     |
| :----------- | :---------- | :------------ | :--------- | :--------- |
| `PACK_MODEL` | NX-88       | IQ-88         | XG-9       | NX-88      |
| `PACK_INIT`  | `sys_init`  | `intel_init`  | `xg_init`  | `ar_init`  |
| `PACK_WARM`  | `sys_warm`  | `intel_warm`  | `xg_warm`  | -          |
| `PACK_FIRST` | `sys_first` | -             | `xg_first` | `ar_first` |
| `PACK_RAW`   | -           | `intel_raw`   | -          | `ar_raw`   |
| `PACK_LEAVE` | -           | `intel_leave` | `xg_leave` | `ar_leave` |

Every machine declares `PACK_TICK`, `PACK_DRAW`, `PACK_KEY` and `PACK_DRESS`.
A pack whose way out must run whichever machine was opened last registers it
with `pack_at_exit FN` instead: SYSTEM stops its background reading that way,
with `sys_leave`.

---

## 📦 What The Door Lends A Pack

Everything is drawn into the door's grid in glass coordinates, `0 0` at the
glass's top left, and clipped to it. A colour is one integer, `0xRRGGBB` with
each channel a multiple of four, and the palette has names for the common
ones (`$CYAN`, `$AMBER`, `$LIME`, `$WHITE`, `$GREY`, `$GLASS` and more, in the
door's SECTION 1). `-2` leaves a cell's ink or ground as it was.

| Call                                 | What it does                                                  |
| :----------------------------------- | :------------------------------------------------------------ |
| `v_put X Y GLYPH [FG] [BG]`          | One cell                                                      |
| `v_text X Y TEXT [FG] [BG]`          | A run of text; a control character becomes a space            |
| `v_center Y TEXT [FG] [BG] [X0] [W]` | Text centred on the glass, or on a band of it                 |
| `v_fill X Y W H [GLYPH] [FG] [BG]`   | A filled rectangle                                            |
| `v_hline X Y W GLYPH [FG] [BG]`      | A horizontal rule                                             |
| `v_box X Y W H [FG] [BG] [STYLE]`    | A box, round by default                                       |
| `cmix A B T`, `cshade C F`           | Two colours blended, or one scaled, answered in `CM` and `CS` |
| `xf_arm [SCALE]`                     | The channel change, armed for the next picture                |
| `say TEXT`, `snd JOB`                | A line on the coin door, and one of the cabinet's noises      |
| `surf_handover LABEL CMD...`         | The real terminal handed to a program, then the cabinet back  |
| `pack_at_exit FN`                    | `FN` run on the way out, whichever machine is standing        |

A pack's own page vocabulary stays its own: INTELLIGENCE's `in_panel` and
`in_kv` are not for SYSTEM to call. A pack that reached into another machine's
internals would break the moment that machine was edited.

---

## 🛡️ The Rules A Pack Keeps

A pack runs inside the door, under the door's options:
`emulate -L zsh`, `setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH` and `set -u`.

- **Arrays are 0-based, and an unset read ends the program.** Every read of an
  associative array carries a default, as `${AR[credits]:-0}` does. The window
  closing with nothing said is the worst failure the cabinet has, and an unset
  name is the likeliest way to cause it.
- **A flag on a bare array name expands element zero.** `${(j:·:)NAME}` is the
  first item, not the list; `${(j:·:)NAME[@]}` is the list.
- **No fork in a frame.** Results come back in globals (`REPLY`, `CM`, `CS`,
  `TR`, `RD`) rather than through `$(...)`. Short output names are shared by
  the door and all four packs, so look in `terminal.command` before adding
  one.
- **Never write to the terminal.** Draw with the calls above; run a program
  with `surf_handover`, or in the cabinet's own terminal on the glass, as
  INTELLIGENCE runs an agent.
- **Own what you start.** A pack that starts a process stops it in
  `PACK_LEAVE` or a `pack_at_exit` function. The door calls those on every
  way out: the power question, <kbd>Ctrl</kbd> <kbd>C</kbd>,
  <kbd>Ctrl</kbd> <kbd>\\</kbd> and a closed window.
- **Prefix every name**: `sy_` and `SY_` for SYSTEM, `in_` and `IN_` for
  INTELLIGENCE, `xg_` and `XG_` for XENOGOTCHI, `ar_` and `AR_` for the ARCADE.
- **Say so when run alone.** The door sets `PACK_SOURCED=1` before it sources
  a pack. SYSTEM, INTELLIGENCE and XENOGOTCHI check that and
  `ZSH_EVAL_CONTEXT` when run as a script: SYSTEM answers `--probe`, and the
  other two print a line saying they belong to `terminal.command`.

A pack shares the two files beside the door with every other program. In
`terminal.conf` and `terminal.save` the last spelling of a key wins, and each
machine keeps its keys under its own name (`arcade.credits`,
`xenogotchi.active`). The ARCADE's and XENOGOTCHI's writers keep every line
they do not own, write the whole file to a temporary copy and move it over,
and never write a save they could not read in full.

---

## 🛡️ When A Pack Fails

Before it sources a pack or calls its first hooks, the door drops a
breadcrumb, `${TMPDIR:-/tmp}/alien-pack.<pid>`, and keeps the pack's stderr in
the same name with `.log` added:

- **The door survives it**: a pack that will not load or start puts its last
  line of stderr on the coin door, or `that pack would not load` and
  `that pack would not start` when it said nothing, and both files are
  removed.
- **The pack takes the door down**: once the screen is back, the exit trap
  finds the breadcrumb and prints
  `TERMINAL stopped inside a machine's page pack:`, the pack's name, and
  everything the pack wrote to stderr.
- **It fell while being got ready at power-on**: the note `warming`, in the
  state folder, names it at the next power-on, and the pack goes on
  `warm-skip`. From then on it is read only when the reader opens it, until
  its file changes.

---

## 🌿 What The Door Holds About Each Machine

The roster is a set of parallel arrays in SECTION 8 of `terminal.command`, one
element per machine. A machine is a row in each of them:

| Array    | Holds                                                                                                  |
| :------- | :----------------------------------------------------------------------------------------------------- |
| `M_KEY`  | `S`, `I`, `X`, `A`: the machine's key inside the door                                                  |
| `M_NAME` | The six-letter name the menu wears: `SYSTEM`, `INTELL`, `XENOGO`, `ARCADE`                             |
| `M_PATH` | The machine's old program, `scripts/suite/<name>.py`, still the key the probe files each machine under |
| `M_TAB`  | The full name, for a tab                                                                               |
| `M_DESC` | The line beside its row                                                                                |
| `M_KIND` | The reading its row carries: `load`, `agents`, `pet` or `credits`, drawn by `reading`                  |
| `M_PACK` | The pack itself, `scripts/suite/<name>.zsh`, found by that exact path                                  |

Three more places name the machines: `warm_init` reads the packs by index, in
the order `1 0 2 3`; the self test groups the save's keys under the names
`system`, `intelligence`, `xenogotchi` and `arcade`; and `reading` draws each
row's kind. A new machine is a row in every array and a place in each of
those three.

> [!NOTE]
> **The visitor's notes are generated.** The `VK_*` arrays in
> `terminal.command` are what the visitor answers from, and their header says
> they are generated by `gen_notes.py`, which is not in this repository: edit
> the notes and generate again, not those lines. The header also records the
> first eight hex digits of the MD5 of each file the notes were written
> against, so `md5 -q <file> | cut -c1-8` shows which files have changed
> since. A change to a page, a key or a setting leaves his notes describing
> the old one until they are generated again.

---

## 🔗 See Also

- [README: Changing the code](../../README.md#changing-the-code): the shell
  options and the namespaces, in brief
- [Checking A Change](../distribution/Checking-A-Change.md): the checks a
  change to a pack has to pass, and the ones CI cannot run
- [Shell Hook & Installer](Shell-Hook-&-Installer.md): the other side of the
  door, from a new shell to `terminal.command`
- [Glossary](../references/Glossary.md): the cabinet's words, one line each

---

<div align="center">

**Eleven hooks, one glass, and a door that survives what it sources.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](../../LICENSE).

</div>
