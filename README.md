<!--
title: '🚀 DOTFILES'
description: 'Machine configuration for macOS, native Windows and Codespaces, applied by a single command.'
tags: [chezmoi, cross-platform, developer-environment, codespaces]
category: root
-->

<!-- markdownlint-disable MD041 -->
<div align="center">

# 🚀 DOTFILES

<a name="top"></a>

**Machine configuration for macOS, native Windows and Codespaces, in one command.**

_Real files, never symlinks. Nothing secret, ever._

</div>

---

## 💡 About

Dotfiles are the hidden configuration files that decide how a machine behaves: what the shell does, how Git identifies you, which tools exist on your `PATH`. This repository holds mine, so a new machine reaches a working state without an afternoon of remembering.

It is managed by [chezmoi](https://www.chezmoi.io), which **renders real files into `$HOME`** rather than symlinking them. That choice is load-bearing rather than aesthetic: creating a symbolic link on Windows requires an elevated process or Developer Mode, so a symlink-based layout is privilege-dependent on one of the three supported platforms. Rendering files needs no privilege anywhere.

> [!IMPORTANT]
> Bootstrap **snapshots every file it is about to touch** before writing anything, because `chezmoi apply` overwrites existing configuration silently and offers no undo of its own. The snapshot is the undo.

---

## 🖥️ Supported Platforms

| Platform                   | Shell         | Packages       | Terminal                    |
| :------------------------- | :------------ | :------------- | :-------------------------- |
| **macOS**                  | zsh           | Homebrew       | Terminal.app, `Pro` profile |
| **Windows**                | PowerShell 7+ | winget · scoop | Windows Terminal            |
| **Codespaces and Linux**   | zsh           | apt            | provided by the platform    |

Native Windows, not WSL. Linux is supported because a codespace is a Linux container, and this repository is wired into that flow directly.

---

## 🚀 Quick Start

> [!WARNING]
> Read a bootstrap script before running it. That is generic advice, and it is also GitHub's own guidance for dotfiles repositories, which are able to run arbitrary code during codespace creation.

### macOS and Linux

- [ ] Clone the repository
- [ ] Run the bootstrap script
- [ ] Complete the interactive steps it prints at the end

```bash
git clone https://github.com/tannergolden/dotfiles ~/.dotfiles
~/.dotfiles/scripts/bootstrap.sh
```

### Windows

Run from PowerShell 7 or later.

```powershell
git clone https://github.com/tannergolden/dotfiles $HOME\.dotfiles
& $HOME\.dotfiles\scripts\bootstrap.ps1
```

### GitHub Codespaces

Nothing to run. Enable **Automatically install dotfiles** in your [Codespaces settings](https://github.com/settings/codespaces) and select this repository. Every new codespace clones it and executes `install.sh` during creation.

---

## 📦 Structure

```bash
.
├── home/                  # 🏠 chezmoi source state, and nothing else
│   ├── .chezmoiignore     # 🔀 the one file deciding what applies where
│   ├── dot_config/        # ⚙️ shared configuration
│   └── .chezmoiscripts/   # 📦 package provisioning
├── packages/              # 📋 one manifest per platform
├── scripts/               # 🔧 bootstrap, backup, restore, guards
├── docs/                  # 📚 recovery and design notes
├── install.sh             # ☁️ Codespaces entrypoint
└── .chezmoiroot           # 📍 scopes chezmoi to home/
```

`.chezmoiroot` keeps the two worlds apart. It scopes chezmoi to `home/`, so `README.md`, `Makefile` and `.github/` stay repository infrastructure and never land in a home directory.

---

## 🧭 Divergence Between Machines

Configuration is split by **whole files**, not by conditionals scattered through them. A single `.chezmoiignore` names which files belong to which platform; everything else is a plain file that its own editor can highlight and a human can grep.

Templating is used sparingly and deliberately. Across a survey of real cross-platform dotfiles repositories, the genuinely shared, OS-conditional surface came to well under one percent of configuration by line. The honest shape is two mostly independent sets of files sharing a small core: Git, SSH, and the choice of which tools to install.

---

## 🔐 What This Repository Will Never Contain

This repository is public. Nothing sensitive belongs in it, and the protection is mechanical rather than a matter of discipline.

| Never committed                    | Why                                              |
| :--------------------------------- | :----------------------------------------------- |
| Private keys of any kind           | A leak is permanent; history is not redactable   |
| `known_hosts`                      | An inventory of every host you connect to        |
| Cloud, registry or CLI credentials | Scanners find committed tokens within minutes    |
| Shell history                      | Routinely captures secrets typed inline          |
| Editor user settings               | They accrete hostnames and account state         |

> [!CAUTION]
> Do not treat chezmoi's `private_` attribute as a security control. It applies no permissions at all on Windows, it is silently ignored when prefixes are written in the wrong order, and `encrypted_` does not imply it. Exclusion is the control, and `.gitignore` is where it lives.

Editor configuration is owned by **VS Code Settings Sync**, not by this repository. That is not a workaround: Codespaces explicitly does not support personalizing user-scoped editor settings through a dotfiles repository, and VS Code's atomic writes make an externally managed settings file unreliable.

---

## 🔄 Everyday Use

```bash
chezmoi diff            # what would change, without changing it
chezmoi apply           # bring this machine into line
chezmoi verify          # exit non-zero when the machine has drifted
chezmoi edit ~/.zshrc   # edit the source, not the rendered copy
```

`make lint` and `make test` run what continuous integration runs, so a green local run means a green pipeline.

---

## ↩️ Undoing It

Every bootstrap writes a timestamped snapshot to `~/.dotfiles-backup-<timestamp>/`, holding an archive of everything that existed beforehand and a manifest of everything that did not.

```bash
scripts/restore-backup.sh ~/.dotfiles-backup-20260731T060000Z
```

The manifest matters as much as the archive. Restoring has to **delete** the files bootstrap created, and an archive alone cannot know which those were.

---

### 🔗 See also

> [!TIP]
> Conventions, workflows and the automation that enforces them live in [📐 Engineering Standards](https://github.com/tannergolden/standards). Follow them by link rather than copying them, so nothing here goes stale.

---

<div align="center">

**Read it, take what is useful, leave the rest.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by [@tannergolden](https://github.com/tannergolden).

</div>
