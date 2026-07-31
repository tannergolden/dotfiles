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

```powershell
& scripts\restore-backup.ps1 $HOME\.dotfiles-backup-<timestamp>
```

**Use the one that matches the bootstrap that made the snapshot.** The two write different archive formats, `targets.tar.gz` and `targets.zip`, because each platform's bootstrap uses the archiver it can rely on being present. Each restore now refuses a snapshot written by the other and names the script you want, rather than treating an archive it cannot read as an empty one.

The restore deletes the files bootstrap **created**, extracts the originals, and re-asserts their modes. The manifest is what makes the deletions possible; an archive alone cannot know which files were absent beforehand.

> [!IMPORTANT]
> Both scripts verify the archive **before** deleting anything. A corrupt or missing archive stops the restore with nothing yet removed, so the failure costs you a message rather than the files it was meant to bring back.

---

## 2️⃣ The Configuration Applied but Nothing Changed

`chezmoi verify` reports clean, every managed file is correct, and the machine still behaves the way it did before. The cause is almost always a file this repository does not manage that outranks one it does.

| The file          | What it beats           | Why                                                     |
| :---------------- | :---------------------- | :------------------------------------------------------ |
| `~/.gitconfig`    | `~/.config/git/config`  | Git reads both; the home-directory one wins              |
| `~/.zshrc.local`  | everything in `.zshrc`  | `.zshrc` sources it last, on purpose                     |
| `Microsoft.PowerShell_profile.ps1` | the profile shim | Loads after `profile.ps1` in PowerShell's fixed order |

```bash
scripts/reset-conflicts.sh "$(command -v chezmoi)" ~/.dotfiles
```

That reports and changes nothing. To act on it, re-run bootstrap with `--reset` (`-Reset` on Windows), which preserves each file into the snapshot before removing it. The escape hatches in the middle row are always reported and never removed; if one of those is the cause, editing it is the fix.

---

## 3️⃣ A Managed File Keeps Reverting

That is chezmoi doing its job. Three honest options:

| You want                   | Do                                          |
| :------------------------- | :------------------------------------------ |
| The change on this machine | `chezmoi re-add <file>` then commit it      |
| The change everywhere      | `chezmoi edit <file>`, commit, push         |
| The file unmanaged forever | Delete its source file, commit, then delete |

There is a fourth option that looks right and is not: adding the file to `.chezmoiignore` does **not** remove the already-applied copy, and the orphan then becomes invisible to `chezmoi status`, `verify` and `managed` alike.

---

## 4️⃣ Remove the Whole Setup

```bash
chezmoi purge         # config, state AND the clone; asks first
```

One command, not two. This previously read `chezmoi purge` followed by `rm -rf ~/.dotfiles`, which was wrong in a way worth spelling out.

> [!CAUTION]
> **Purge deletes the entire clone, git history included.** Not just the source directory inside it. Verified: with `.chezmoiroot` pointing at `home/`, `sourceDir` resolves to `~/.dotfiles/home`, and purge still removes `~/.dotfiles` outright, taking `.git`, the scripts, and anything uncommitted or unpushed with it. Push your work first. Add `--binary` to remove the chezmoi executable too.

The rendered files in `$HOME` **stay**, which is usually what you want: the machine keeps working, it just stops being managed.

**If you want the pre-dotfiles state back, restore first and purge second** — the restore scripts live inside the clone that purge is about to delete.

```bash
~/.dotfiles/scripts/restore-backup.sh ~/.dotfiles-backup-<timestamp>
chezmoi purge
```

Installed packages are untouched by all of this, on purpose. [🗑️ Uninstalling](../README.md#-uninstalling) covers removing those.

---

## 5️⃣ Provisioning Ran but a Tool Is Missing

Package installation degrades per tool rather than aborting, so one dead channel costs one tool. Re-run with the manifest unchanged and nothing reruns; touch the manifest to force it:

```bash
chezmoi apply             # reruns only what changed
chezmoi state delete-bucket --bucket=entryState   # nuclear: rerun everything onchange
```

The per-machine script state lives in `~/.config/chezmoi/chezmoistate.boltdb`. Deleting it is safe; every provisioning script is written to be idempotent.

---

## 6️⃣ Signing Broke

Commits fail with a gpg error, or GitHub shows **Unverified**:

- No key yet? `commit.gpgsign` stays `false` until `~/.ssh/id_signing_ed25519.pub` exists; generate it per [Manual Setup](Manual-Setup.md), then run `chezmoi apply` to flip signing on.
- Key exists but GitHub says Unverified? The key is registered as an authentication key only. Add it again under **Signing keys**; the two registrations are separate.
- `git log --show-signature` says `No signature`? The trust list `~/.config/git/allowed_signers` has no entry for the key; add one. That file is created once and never overwritten, so your entries survive every apply.

---

## 7️⃣ Revert the Theme

The Catppuccin Mocha recolour landed as a single commit touching the terminal profile, fzf, bat, delta and starship. One revert of that commit restores the previous look; the Terminal.app profile then needs a re-import via `scripts/macos-defaults.sh`.

---

## 8️⃣ The Escape Hatch

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
