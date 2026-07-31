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

| Platform               | Shell         | Packages       | Terminal                    |
| :--------------------- | :------------ | :------------- | :-------------------------- |
| **macOS**              | zsh           | Homebrew       | Terminal.app, `Pro` profile |
| **Windows**            | PowerShell 7+ | winget · scoop | Windows Terminal            |
| **Linux & Codespaces** | zsh           | apt            | provided by the platform    |

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
│   ├── .chezmoidata/      # 📋 the package manifest, one list per platform
│   ├── .chezmoiscripts/   # 📦 provisioning, keyed to the manifest
│   └── dot_config/        # ⚙️ tool configuration
├── scripts/               # 🔧 bootstrap, backup, restore, guards
├── docs/                  # 📚 manual steps and recovery
├── install.sh             # ☁️ Codespaces entrypoint
└── .chezmoiroot           # 📍 scopes chezmoi to home/
```

`.chezmoiroot` keeps the two worlds apart. It scopes chezmoi to `home/`, so `README.md`, `Makefile` and `.github/` stay repository infrastructure and never land in a home directory.

---

## 🧭 Platform Parity

**Every machine gives you the same commands, doing the same things, configured by the same files.** What differs is the machinery underneath, and only where an operating system leaves no choice.

The useful way to think about it: parity is at the level of _what you type and what happens_, not at the level of _which file the operating system reads_. A prompt is a prompt on all three; the line that starts it is spelled differently in zsh and PowerShell.

### ✅ Identical everywhere

One file, byte for byte, read the same way on macOS, Windows and Linux.

| Surface         | How it stays identical                                                  |
| :-------------- | :---------------------------------------------------------------------- |
| **Tool set**    | The same 13 tools, whichever package manager delivers them              |
| **Prompt**      | One `starship.toml`; only the per-shell `init` line differs             |
| **ripgrep**     | One `ripgreprc`, found via `RIPGREP_CONFIG_PATH`                        |
| **bat**         | One `config`, found via `BAT_CONFIG_PATH`                               |
| **Diffs**       | delta, configured inside the Git config, so it inherits its portability |
| **Git**         | One config; the platform-specific part is four lines                    |
| **SSH**         | One config; the platform-specific part is two blocks                    |
| **Aliases**     | `g`, `gs`, `gd`, `gl`, `ll`, `la`, `..`, `...` behave the same          |
| **Keybindings** | Up and Down do prefix-aware history search in both shells               |
| **Editor**      | `code --wait`, with the same fallback chain                             |
| **Colours**     | Catppuccin Mocha: terminal palettes, fzf, bat, delta and starship       |

Those tool configs are genuinely portable for a specific reason: ripgrep and bat both locate their config through an environment variable rather than a fixed path, so one file serves all three platforms with no templating at all.

### ⚖️ The differences, and why each one exists

None of these are choices; each is something a platform forces.

| Difference               | macOS / Linux                    | Windows          | Why                                                                                      |
| :----------------------- | :------------------------------- | :--------------- | :--------------------------------------------------------------------------------------- |
| **Shell language**       | zsh                              | PowerShell       | Unrelated languages. Aliases are written twice because `Set-Alias` cannot take arguments |
| **Package manager**      | Homebrew · apt                   | scoop · winget   | Same tools, three delivery routes                                                        |
| **Terminal**             | Terminal.app `Pro`               | Windows Terminal | The one real gap. See below                                                              |
| **fzf key bindings**     | <kbd>Ctrl</kbd>+<kbd>R</kbd> etc | not available    | fzf ships no PowerShell integration upstream                                             |
| **SSH multiplexing**     | `ControlMaster` on               | unsupported      | Win32-OpenSSH has no Unix-domain-socket multiplexing                                     |
| **Keychain integration** | `UseKeychain` (macOS only)       | agent service    | An Apple-only directive; unguarded it _terminates_ ssh elsewhere                         |
| **File permissions**     | `0600` honoured                  | not applied      | NTFS uses ACLs, and chezmoi's `Chmod` is a no-op there                                   |
| **Credential helper**    | `osxkeychain`                    | `manager`        | Each platform's own secure store                                                         |

Two smaller ones worth knowing because they look like bugs:

- **Debian renames two binaries.** `fd-find` installs as `fdfind` and `bat` as `batcat`. The shell config detects this and aliases them back, so you type `fd` and `bat` everywhere.
- **The PowerShell profile is loaded through a shim.** OneDrive can relocate `Documents` by policy, so the real profile lives at a fixed path and a generated one-liner points at it.

### 🖥️ The font is the honest exception

The **colour scheme travels**: Catppuccin Mocha is applied to the Terminal.app `Pro` profile directly, delivered to Windows Terminal as a JSON fragment with one one-time selection step, and carried into fzf, bat, delta and the prompt, each taken from the theme's own licensed ports rather than copied from another repository.

The **font does not**. `Pro` specifies Monaco 12, an Apple-bundled face with no Homebrew cask and no scoop package, so it cannot legitimately be installed on Windows or in a container. Windows Terminal keeps its own default face under the same palette.

In a codespace neither question arises, because the terminal is VS Code's integrated one and its appearance comes from Settings Sync rather than from this repository.

### 🧩 How the split is implemented

Configuration is partitioned by **whole files**, not by conditionals threaded through them. A single `.chezmoiignore` decides which files belong to which platform; everything else is a plain file its own editor can highlight and a human can grep.

Templating is used sparingly on purpose. Across a survey of real cross-platform dotfiles repositories, the genuinely shared, OS-conditional surface came to well under one percent of configuration by line, so branching inside every file would buy almost nothing and cost a great deal of readability.

```bash
# See exactly what any platform would do, from any platform
chezmoi ignored --override-data '{"chezmoi":{"os":"windows"}}'
```

---

## 🔐 What This Repository Will Never Contain

This repository is public. Nothing sensitive belongs in it, and the protection is mechanical rather than a matter of discipline.

| Never committed                    | Why                                            |
| :--------------------------------- | :--------------------------------------------- |
| Private keys of any kind           | A leak is permanent; history is not redactable |
| `known_hosts`                      | An inventory of every host you connect to      |
| Cloud, registry or CLI credentials | Scanners find committed tokens within minutes  |
| Shell history                      | Routinely captures secrets typed inline        |
| Editor user settings               | They accrete hostnames and account state       |

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

```powershell
& scripts\restore-backup.ps1 $HOME\.dotfiles-backup-20260731T060000Z
```

The manifest matters as much as the archive. Restoring has to **delete** the files bootstrap created, and an archive alone cannot know which those were. Both scripts read the archive before removing anything, so a snapshot they cannot open costs you a message rather than the files.

Every other way back, from a reverting file to removing the setup entirely, is written down in [↩️ Recovery](docs/Recovery.md) for a reader who has forgotten how any of this works.

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
