<!--
title: '🤖 AGENT HOME KIT'
description: 'Installs one pinned release of the universal rules and their kit from tannergolden/intelligence into every AI coding app on this machine.'
tags: [ai-agents, home-kit, dotfiles, intelligence]
category: docs
-->

<div align="center">

# 🤖 AGENT HOME KIT

<a name="top"></a>

**The universal rules for every AI coding agent, installed on this machine from one pinned release.**

_Pinned, verified, and reversible to the byte._

</div>

---

## 💡 What This Folder Is For

[tannergolden/intelligence](https://github.com/tannergolden/intelligence)
publishes one set of rules for every AI coding agent. This kit installs one
release of it into each app's own home folder: Claude Code, Codex,
Antigravity CLI and Copilot, plus the master copy in `~/.agents/AGENTS.md`.
Grok Build reads Claude Code's copy, and Cursor's User Rules take a paste by
hand.

A release also serves the hub's kit, and this installs it too: the guard
hook that denies force-pushes, merges and other irreversible commands before
they run, the `building-skills` skill, the Worker and Reviewer subagents,
and the public knowledge facts.

**Nothing is installed unless every downloaded file matches its pin.** The
pin file names a release and the SHA-256 of the home file, the installer and
the kit it serves, and the installer never runs if any of them differs. A
release from before the kit pins no kit, and installs the rules alone.

---

## 🚀 Using It

```bash
make agents                     # install the pinned rules
make agents-check               # compare every installed copy with the release
make agents-uninstall           # put back what was there before
make agents-pin VERSION=v0.1.0  # pin a release
```

`install.sh` at the root runs `make agents`' work on every new codespace,
and a failure there never stops the rest of the setup.

To move to a new release:

1. Run `make agents-pin VERSION=vX.Y.Z`.
2. Compare the three hashes it wrote with `make pins VERSION=vX.Y.Z` in the
   hub, which reads them from the tag in git rather than from a download.
3. Commit the pin file, then run `make agents` on each machine.

> [!NOTE]
> **Codex asks once to trust the guard hook.** It trusts a hook by its
> declaration, so the next `codex` session shows it for review; trust it
> once, and it stays trusted while its command stays the same.

---

## 📝 File Log

<!-- AUTO-INDEX:BEGIN dir=. style=log -->

| Entry                                  | Purpose                                                                                     |
| :------------------------------------- | :------------------------------------------------------------------------------------------ |
| [`home-kit.sh`](home-kit.sh)           | Install the universal rules from tannergolden/intelligence into every AI app's home folder. |
| [`intelligence.pin`](intelligence.pin) | The intelligence release this machine installs, and the SHA-256 of each file it downloads.  |
| [`README.md`](README.md)               | This file.                                                                                  |
| [`test_home_kit.py`](test_home_kit.py) | Tests for the agent home kit.                                                               |

<!-- AUTO-INDEX:END -->

---

<div align="center">

**One release, every app, every byte accounted for.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](../LICENSE).

</div>
