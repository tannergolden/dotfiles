<!--
title: '🧰 SCRIPTS'
description: 'The installer, the four machines as page packs, and moonbase, the invented Mac that SYSTEM reads in demo mode.'
type: index
-->

<div align="center">

# 🧰 SCRIPTS

<a name="top"></a>

**The installer, the four machines, and the data they are checked against.**

_Every path here is a contract the door keeps._

</div>

---

## 💡 What This Folder Is For

[`bootstrap.zsh`](bootstrap.zsh) is the installer. It links three files from
[`home/`](../home) into `~`, appends one marked block to `~/.zshrc` and turns
the switch on, and with `--tools` installs what the [`Brewfile`](../Brewfile)
names. Every command it takes is in the [README](../README.md), and how it
works, with what the door needs of it, is in
[Shell Hook & Installer](../docs/technical/Shell-Hook-&-Installer.md).

The four machines live in [`suite/`](suite/README.md) as page packs, and
[`fixtures/system/`](fixtures/system/README.md) is `moonbase`, the invented Mac
SYSTEM reads byte for byte when it runs mocked.

`terminal.command` finds each of these by its exact path, so nothing here is
renamed or moved without the door.

---

## 📝 File Log

<!-- AUTO-INDEX:BEGIN dir=. style=log -->

| Entry                            | Purpose                                                                                                                    |
| :------------------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| [`fixtures/`](fixtures/)         | Plain data in place of a real machine: `system/` is moonbase, the invented Mac SYSTEM reads when it runs mocked.           |
| [`suite/`](suite/README.md)      | SYSTEM, INTELLIGENCE, XENOGOTCHI and ARCADE: the four page packs the door reads into itself the first time each is opened. |
| [`bootstrap.zsh`](bootstrap.zsh) | The hook, installed &#xB7; and the tools under it                                                                          |
| [`README.md`](README.md)         | This file.                                                                                                                 |

<!-- AUTO-INDEX:END -->

---

<div align="center">

**One installer, four machines, and the paths the door trusts.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](/LICENSE).

</div>
