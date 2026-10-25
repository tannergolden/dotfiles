<!--
title: '🔤 GLOSSARY'
description: 'The words the suite''s code, comments and README coin for its parts, from the door and the glass to leaves, the mirror and the gate, one line each with where it lives. Consult it when a comment or a page uses a word this repository made up.'
type: reference
-->

<div align="center">

# 🔤 GLOSSARY

<a name="top"></a>

**The cabinet's own words, each in one line, with the place it lives.**

_A word made up here is defined here._

</div>

---

## 💡 How To Read It

The suite's comments speak the language of a 1984 arcade cabinet, and so do
its pages. Each term below is what the code means by it, with the file or the
setting that holds it. Terms everyone shares, such as a symlink or a pull
request, are left to the
[standards' glossary](https://github.com/tannergolden/standards/blob/Development/docs/references/Glossary.md).

---

## 🔤 The Terms

| Term               | Means                                                                                                     | Lives in                                        |
| :----------------- | :-------------------------------------------------------------------------------------------------------- | :---------------------------------------------- |
| **ALIEN DYNAMICS** | The make-believe hardware maker of 1984 whose plate everything wears; the cabinet is its SYNTHWAVE series | Every banner and bezel                          |
| **Beat**           | The frame rate the whole cabinet runs at: auto, 30, 60 or 120                                             | `beat` in `terminal.conf`                       |
| **Block**          | The lines the installer adds to `~/.zshrc`, between `# >>> ALIEN dotfiles >>>` and its closing mark       | `ZLINES` in `scripts/bootstrap.zsh`             |
| **Cabinet**        | The whole drawing that powers up in the window: walls, neon, bezel, control panel, coin door and glass    | `terminal.command`                              |
| **Channel change** | How the glass goes from one picture to the next, like a tube: a line, an unfold, a settle                 | `xf_arm` and `xf_frame` in the door             |
| **Coin door**      | The strip at the cabinet's foot where it talks back: a greeting, or what a key just did                   | `say` in the door                               |
| **Dealing**        | Opening machines or runners in tabs of Terminal's own window                                              | `deal_tabs`, and the `dealing` flag             |
| **Door**           | `terminal.command`, model AD-1, called TERMINAL on its own glass: the one file that holds the cabinet     | The repository root                             |
| **Fill, float**    | The two values of SCREEN: the glass filling the window, or the cabinet standing in the middle of it       | `screen` in `terminal.conf`                     |
| **Gate**           | The question put before anything runs: the exact line on the glass, waiting for **[Y]**                   | INTELLIGENCE, and the door's power question     |
| **Glass**          | The screen inside the cabinet, 106 x 30 cells when it floats, where the menu and every machine draw       | `SCR_W` and `SCR_H` in the door                 |
| **Governor**       | What steps the beat down when frames run long and back up a rung at a time, when BEAT is auto             | SECTION 5b of the door                          |
| **Handover**       | The cabinet stepping aside to give a program the real terminal, and coming back when it ends              | `surf_handover` in the door                     |
| **Hook**           | The shell file that opens the cabinet in a new interactive shell, or stands aside                         | `home/.config/zsh/conf.d/10-alien-terminal.zsh` |
| **House**          | The suite as this Mac has it; its token ties together the tabs of one opening                             | `suite` in the state folder                     |
| **Leaf**           | One file under `home/` that the installer links into `~`                                                  | `LEAVES` in `scripts/bootstrap.zsh`             |
| **Machine**        | SYSTEM, INTELLIGENCE, XENOGOTCHI or the ARCADE, each with a model plate of its own                        | `scripts/suite/`                                |
| **Mirror**         | `home/` as linked into `~`; its gauge counts the leaves that resolve back into the clone                  | `_mirror` in the door                           |
| **moonbase**       | The invented Mac, a 16-inch M3 Max, that SYSTEM reads when it runs mocked                                 | `scripts/fixtures/system/`                      |
| **Page pack**      | A machine's file, sourced into the door, which draws inside the door's glass                              | [Page Packs](../technical/Page-Packs.md)        |
| **Power-up**       | The opening: the stars alone while every machine loads, the tube warming, then the self test card         | SECTION 22 of the door                          |
| **Records**        | The installer's output for the glass, `state<TAB>text` a line                                             | `ALIEN_REPORT=1`                                |
| **Rung**           | One of the ARCADE's four difficulty levels, ROOKIE, NORMAL, EXPERT and INSANE; also a step of the beat    | `arcade.difficulty`                             |
| **Self test card** | What the cabinet found on this Mac, a line at a time, ending with READING SAVE AND CONFIG                 | `page_boot` in the door; **[R]** runs it again  |
| **State folder**   | Where the suite keeps its short-lived facts and INTELLIGENCE's configs                                    | `~/.local/state/alien/`                         |
| **Switch**         | Whether a new window opens the cabinet: only `on` lets it                                                 | `terminal.hook` in `terminal.conf`              |
| **Title card**     | The card a machine opens on, its name in lights over one live picture, until a key goes in                | `tc_*` in the door and the packs                |
| **Tube**           | The CRT the glass is drawn as: a vignette, a slow bright roll, phosphor on every change                   | SECTION 5 of the door                           |
| **Visitor**        | The small grey-violet alien in the glass, who answers through a model on this Mac                         | SECTION 12 of the door; **[V]** on the menu     |
| **Warm-up**        | The door reading every pack in and starting it ahead of the reader, a step at a time                      | `PACK_WARM`, and `warm-skip`                    |

---

## 🔗 See Also

- [Page Packs](../technical/Page-Packs.md): the door, the glass and the hooks,
  as a contract
- [Shell Hook & Installer](../technical/Shell-Hook-&-Installer.md): leaves,
  the block, the switch and the records, at work
- [Machine Footprint](Machine-Footprint.md): the state folder, file by file

---

<div align="center">

**Thirty words, and the cabinet's comments read plainly.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](/LICENSE).

</div>
