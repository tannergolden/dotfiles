<!--
title: '🖥️ SCREENSHOTS'
description: 'Captures of the product and the terminal, still or moving, in day and night pairs, for the README and the docs.'
type: index
-->

<div align="center">

# 🖥️ SCREENSHOTS

<a name="top"></a>

**The product as it really looks, captured for the pages that describe it.**

_Crop to the sentence. Blur the secrets._

</div>

---

## 💡 What This Folder Is For

Captures of the interface and the terminal: PNG, taken at 2x and cropped to what
the sentence beside it describes, in a day and night pair (`dashboard.png`,
`dashboard-dark.png`) wherever the page shows both themes.

A GIF of the product in motion is a screenshot that moves, and lives here too:
under 5 MB, a few seconds long, showing one thing. A longer recording belongs in
a release asset or on a video host, linked from the page.

Before a capture is committed, blur or replace anything that is not public:
tokens, email addresses, hostnames, other people's names. When the output of a
command is what matters, a code block says it better and stays searchable;
capture the terminal when its look is the point.

---

## 📝 File Log

Every capture here is of moonbase, the invented Mac in
[`scripts/fixtures/system/`](../../scripts/fixtures/system/README.md), taken
with `TERMINAL_MOCK=1` and `SYSTEM_MOCK=1` so that nothing in them describes a
real machine, and on a fresh clone's defaults: no `terminal.save` and no
`terminal.conf`, which only exist once the suite is installed and in use. Each
GIF opens on a loading card, the title card a machine opens on or the
TERMINAL's own self test, walks on into the pages behind it, and plays at the
speed the cabinet drew it. The cabinet has one look, the night one, so none of
them has a day twin.

<!-- AUTO-INDEX:BEGIN dir=. style=log -->

| Entry                                                        | Purpose                                                                                                                                                                         |
| :----------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`arcade-title-card.gif`](arcade-title-card.gif)             | ARCADE's title card, then the lobby and VOID PONG's high scores. Shown under the ARCADE paragraph of The Machines in the root README.                                           |
| [`intelligence-title-card.gif`](intelligence-title-card.gif) | INTELLIGENCE's title card, then its menu, CLOUD and LOCAL. Shown under the INTELLIGENCE paragraph of The Machines in the root README.                                           |
| [`README.md`](README.md)                                     | This file.                                                                                                                                                                      |
| [`system-title-card.gif`](system-title-card.gif)             | SYSTEM's title card, then its menu, OVERVIEW and MEMORY. Shown under the SYSTEM paragraph of The Machines in the root README.                                                   |
| [`terminal-power-up.gif`](terminal-power-up.gif)             | The TERMINAL's own loading card: the power-up, from the stars alone through the self test card to the menu. Shown under the first paragraph of What This Is in the root README. |
| [`xenogotchi-title-card.gif`](xenogotchi-title-card.gif)     | XENOGOTCHI's intake night card, then three arrivals' adoption certificates. Shown under the XENOGOTCHI paragraph of The Machines in the root README.                            |

<!-- AUTO-INDEX:END -->

🗂️ Machined Indexes redraws this log after every push to the default branch. A
screenshot cannot describe itself, so name the page that shows it in its row:
regeneration keeps it, and a capture nothing shows any more is easy to find.

---

<div align="center">

**Show the screen the sentence is about, and nothing else.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](/LICENSE).

</div>
