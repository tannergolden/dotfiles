<!--
title: '↩️ RECOVERY'
description: 'How to undo, repair, or entirely remove this setup, written for a reader who has forgotten how it works.'
tags: [recovery, restore, uninstall, troubleshooting]
category: docs
-->

<!-- markdownlint-disable MD041 -->
<div align="center">

# ↩️ RECOVERY

<a name="top"></a>

**Every way back, in the order you are likely to need one.**

_Written for you, twelve months from now, in a hurry._

</div>

---

## 🎯 Orientation In Thirty Seconds

This machine's shell, git, ssh and prompt configuration is **rendered** into `$HOME` by [chezmoi](https://www.chezmoi.io) from the clone of this repository. Files in `$HOME` are real files, not symlinks. Editing one directly works until the next `chezmoi apply` silently reverts it, which is the single most common "my change disappeared" report.

```bash
chezmoi diff             # what apply would change right now
chezmoi edit ~/.zshrc    # edit the SOURCE of a managed file
chezmoi re-add ~/.zshrc  # adopt a direct edit INTO the source
```

---

## 1️⃣ Undo a Bootstrap

Every bootstrap first snapshots everything it is about to touch into `~/.dotfiles-backup-<timestamp>/`, holding an archive of what existed and a manifest of what did not.

```bash
scripts/restore-backup.sh ~/.dotfiles-backup-<timestamp>
```

The restore deletes the files bootstrap **created**, extracts the originals, and re-asserts their modes. The manifest is what makes the deletions possible; an archive alone cannot know which files were absent beforehand.

---

## 2️⃣ A Managed File Keeps Reverting

That is chezmoi doing its job. Three honest options:

| You want                   | Do                                          |
| :------------------------- | :------------------------------------------ |
| The change on this machine | `chezmoi re-add <file>` then commit it      |
| The change everywhere      | `chezmoi edit <file>`, commit, push         |
| The file unmanaged forever | Delete its source file, commit, then delete |

There is a fourth option that looks right and is not: adding the file to `.chezmoiignore` does **not** remove the already-applied copy, and the orphan then becomes invisible to `chezmoi status`, `verify` and `managed` alike.

---

## 3️⃣ Remove the Whole Setup

```bash
chezmoi purge         # removes chezmoi's own config and state, asks first
rm -rf ~/.dotfiles    # the clone
```

The rendered files in `$HOME` stay, which is usually what you want: the machine keeps working, it just stops being managed. Restore a bootstrap backup first if you want the pre-dotfiles state back.

---

## 4️⃣ Provisioning Ran but a Tool Is Missing

Package installation degrades per tool rather than aborting, so one dead channel costs one tool. Re-run with the manifest unchanged and nothing reruns; touch the manifest to force it:

```bash
chezmoi apply             # reruns only what changed
chezmoi state delete-bucket --bucket=entryState   # nuclear: rerun everything onchange
```

The per-machine script state lives in `~/.config/chezmoi/chezmoistate.boltdb`. Deleting it is safe; every provisioning script is written to be idempotent.

---

## 5️⃣ Signing Broke

Commits fail with a gpg error, or GitHub shows **Unverified**:

- No key yet? `commit.gpgsign` stays `false` until `~/.ssh/id_signing_ed25519.pub` exists; generate it per [Manual Setup](Manual-Setup.md), then run `chezmoi apply` to flip signing on.
- Key exists but GitHub says Unverified? The key is registered as an authentication key only. Add it again under **Signing keys**; the two registrations are separate.
- `git log --show-signature` says `No signature`? The trust list `~/.config/git/allowed_signers` has no entry for the key; add one. That file is created once and never overwritten, so your entries survive every apply.

---

## 6️⃣ Revert the Theme

The Catppuccin Mocha recolour landed as a single commit touching the terminal profile, fzf, bat, delta and starship. One revert of that commit restores the previous look; the Terminal.app profile then needs a re-import via `scripts/macos-interactive.sh`.

---

## 7️⃣ The Escape Hatch

If chezmoi itself is the problem, the repository is still just files:

```bash
chezmoi archive --output=rendered.tar   # plain tar of the fully rendered target state
```

That tar contains real files with correct permissions and no chezmoi anywhere, which is the exit from the tool with everything kept.

---

<div align="center">

**The way back is always shorter than the way in.**

[↑ Back to Top](#top)

</div>
