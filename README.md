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

### 🧹 The config that outranks this repository

A machine can differ from this repository in a way `chezmoi verify` cannot see, because the files responsible are ones chezmoi does not manage. The clearest case: Git reads `~/.config/git/config`, which this repository owns, and it also reads `~/.gitconfig` — **and `~/.gitconfig` wins**. Every line here, the signing gate included, loses silently to a file nothing in this repository looks at.

Every bootstrap therefore **reports** what is overriding it. Passing `--reset` also removes it:

```bash
~/.dotfiles/scripts/bootstrap.sh --reset
```

```powershell
& $HOME\.dotfiles\scripts\bootstrap.ps1 -Reset
```

It is off by default because bootstrap runs unattended during codespace creation, from a public repository, with nobody present to read a prompt. The list is short and specific: files that outrank one this repository owns, and orphans left behind by a file that was once applied here and is now ignored on this platform. Documented escape hatches (`~/.zshrc.local`, `~/.config/git/config.local`) are reported and kept, and everything removed is preserved into the snapshot first, so `restore-backup.sh` brings it back.

> [!NOTE]
> It does **not** reset Terminal.app or Windows Terminal to their defaults, and that is deliberate. Those preferences hold every profile, window group and setting you have, not just the one this repository contributes. On macOS it could not work anyway: Terminal rewrites its own preferences on quit, so a bootstrap running inside Terminal is racing the process that will overwrite it.

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
│   ├── dot_config/        # ⚙️ tool configuration
│   └── dot_local/         # 🤖 ai-dash, ai-agents, ai-model
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
| **Tool set**    | The same 15 tools, whichever package manager delivers them              |
| **Prompt**      | One `starship.toml`; only the per-shell `init` line differs             |
| **ripgrep**     | One `ripgreprc`, found via `RIPGREP_CONFIG_PATH`                        |
| **bat**         | One `config`, found via `BAT_CONFIG_PATH`                               |
| **Diffs**       | delta, configured inside the Git config, so it inherits its portability |
| **Git**         | One config; the platform-specific part is four lines                    |
| **SSH**         | One config; the platform-specific part is two blocks                    |
| **Aliases**     | `g`, `gs`, `gd`, `gl`, `ll`, `la`, `..`, `...` behave the same          |
| **Keybindings** | Up and Down do prefix-aware history search in both shells               |
| **Editor**      | `code --wait`, with the same fallback chain                             |
| **System info** | One fastfetch `config.jsonc`; `<home>/.config` is searched on all three |
| **AI dashboard**| `ai-dash`, `ai-agents` and `ai-model` behave the same                   |
| **Colours**     | Catppuccin Mocha: terminal palettes, fzf, bat, delta and starship       |

Those tool configs are genuinely portable for a specific reason: ripgrep and bat both locate their config through an environment variable rather than a fixed path, so one file serves all three platforms with no templating at all.

### ⚖️ The differences, and why each one exists

None of these are choices; each is something a platform forces.

| Difference               | macOS / Linux                    | Windows          | Why                                                                                      |
| :----------------------- | :------------------------------- | :--------------- | :--------------------------------------------------------------------------------------- |
| **Shell language**       | zsh                              | PowerShell       | Unrelated languages. Aliases are written twice because `Set-Alias` cannot take arguments |
| **Package manager**      | Homebrew · apt                   | scoop · winget   | Same tools, three delivery routes                                                        |
| **Terminal**             | Terminal.app `Pro`               | Windows Terminal | The one real gap. See below                                                              |
| **Dashboard panes**      | tmux                             | `wt` split-pane  | tmux has no native Windows build; Windows Terminal's pane CLI is the platform's own      |
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

## 🤖 Local AI, Sized To The Machine

Three commands, identical on every platform, delivered as bash on macOS and Linux and as PowerShell twins on Windows:

```bash
ai-dash      # the 2x2 dashboard below
ai-agents    # every known AI agent CLI, with the version of each one installed
ai-model     # detect the hardware, pick the strongest local model, pull it, chat
```

```text
+----------------+----------------+
| fastfetch      |  (blank shell) |
+----------------+----------------+
| ai-agents      |  ai-model chat |
+----------------+----------------+
```

The panes are tmux on macOS and Linux and Windows Terminal splits on Windows, because no terminal exposes splits to a script portably and tmux has no native Windows build. The session rides your normal tmux server under the name `ai-dash`, styled Catppuccin Mocha **for that session only**, so your own tmux theming is never touched. `ai-dash kill` tears it down on macOS and Linux; on Windows closing the window is the whole teardown, because Windows Terminal has no detached session to kill.

### How the model is chosen

`chezmoi apply` runs `ai-model install --auto` after provisioning. It measures what the machine can actually serve, not what is on the box:

| Hardware                  | Budget                                                              |
| :------------------------ | :------------------------------------------------------------------ |
| Apple Silicon             | the Metal wired-memory cap: ⅔ of unified memory up to 32GiB, ¾ above, or your own `iogpu.wired_limit_mb` if you raised it |
| Discrete NVIDIA / AMD GPU | the largest single card's VRAM                                      |
| CPU only (and containers) | ¾ of system RAM, container cgroup limits respected                  |

It then pulls the most capable open-weight model whose download fits that budget with honest headroom, from a ladder verified against the Ollama library (July 2026): `qwen3.5:122b-a10b` at the top, through `gpt-oss:120b`, `qwen3.6:35b`, `glm-4.7-flash` and `gpt-oss:20b`, down to `qwen3:0.6b` on the smallest machines. Every rung supports tool calling. The chosen tag is recorded in `~/.local/state/ai-dash/model`, per machine, never in this repository — your Mac and your Linux box are supposed to disagree.

Three deliberate guard rails, because model pulls are measured in tens of gigabytes:

- **Unattended pulls are capped at 32GB** (`AI_MODEL_AUTO_MAX_GB`). A 128GB machine's first `chezmoi apply` will not silently start an 81GB download; it says what the machine could hold and lets you run `ai-model install` once, on purpose.
- **Disk is checked before pulling**, with 20% headroom, because Ollama itself has no free-space preflight and fails mid-download without one. Interrupted pulls resume.
- **Codespaces skip the ollama runtime entirely** (~1.4GB down, ~4GB unpacked, on a 32GB throwaway disk); everything else in the dashboard still works there. To opt in, set `AI_LOCAL_MODELS=1` as a [Codespaces secret](https://github.com/settings/codespaces) so it exists when a **new** codespace bootstraps — provisioning only re-runs when its content changes, so exporting the variable inside an existing codespace does nothing. In an existing one, install by hand instead:

  ```bash
  curl -fsSL https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64.tar.zst \
    | zstd -d | tar -x -C ~/.local && ai-model install
  ```

`AI_MODEL=<tag>` overrides the ladder outright, and `AI_MODEL_MAX_GB` caps what it may choose. `ai-model status` shows the detection, the ladder's verdict and what is installed, without changing anything.

> [!NOTE]
> The server side is the ollama **CLI**, not the menu-bar app: the brew formula on macOS and the scoop main-bucket package on Windows, which install no login items. The scripts start `ollama serve` on demand and log it to `~/.local/state/ai-dash/`. If you want it always-on on macOS, `brew services start ollama` is one command away.

The agent roster in `ai-agents` is curated, not discovered — there is no registry of agent CLIs, and the landscape renames itself yearly (`q` became `kiro-cli`, `gh copilot` died in favour of a standalone `copilot`, Charm's opencode became `crush`). Versions are printed raw because their formats are not contractual.

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

---

## 🗑️ Uninstalling

There are three different things people mean by this, and only you know which one you want. They are listed cheapest first, and each is independent of the others.

### 1. Stop managing this machine, keep the configuration

```bash
chezmoi purge          # asks first; --force skips the prompt
```

The rendered files in `$HOME` **stay**, which is usually what you want: the machine keeps working exactly as it does now, it just stops being managed. Nothing will overwrite your edits again.

> [!CAUTION]
> `chezmoi purge` **deletes the whole clone, `.git` and all**, not just the source directory inside it. Verified: with `sourceDir` resolved to `~/.dotfiles/home`, purge removes `~/.dotfiles` entirely, taking the git history and any uncommitted or unpushed work with it. Push anything you care about first. `chezmoi purge --binary` also removes the chezmoi binary.

### 2. Put the machine back the way it was

Restore the snapshot from the bootstrap you want to undo, **then** purge. In that order: purge deletes the clone, and the restore scripts live in it.

```bash
~/.dotfiles/scripts/restore-backup.sh ~/.dotfiles-backup-<timestamp>
chezmoi purge
```

That returns every file bootstrap overwrote, deletes every file it created, and puts back anything `--reset` cleared.

### 3. Remove the tools as well

No step above touches the installed packages, deliberately: a tool you also use outside this setup should not vanish because you stopped managing your dotfiles. Remove them by hand if you want them gone.

```bash
brew uninstall bat eza fastfetch fd fzf gh git-delta jq ollama ripgrep starship tmux zoxide
brew uninstall --cask claude-code antigravity-cli
```

```powershell
scoop uninstall bat delta eza fastfetch fd fzf gh jq ollama ripgrep starship zoxide claude-code antigravity-cli
```

**`git` is missing from both lines on purpose.** It is in the manifest, and removing it would take your version control with it. Uninstall it deliberately or not at all.

> [!IMPORTANT]
> Uninstalling ollama does **not** remove the models, and the models are the part measured in tens of gigabytes. They live in `~/.ollama/models` (or wherever `OLLAMA_MODELS` points); delete `~/.ollama` to reclaim the space. On Linux the runtime itself was unpacked to `~/.local/bin/ollama` and `~/.local/lib/ollama`, and fastfetch to `~/.local/bin/fastfetch` and `~/.local/share/fastfetch` — remove those by hand too, since no package manager owns them.

> [!WARNING]
> Never `brew bundle cleanup --force` to do this. It removes everything **not** in the Brewfile, which is every unrelated package on the machine, and it is not what "cleanup" sounds like.

### Keeping the files without the tool

If chezmoi itself is the only thing you want gone, take the rendered state with you first:

```bash
chezmoi archive --output=dotfiles.tar   # real files, correct modes, no chezmoi anywhere
```

Every other way back, from reverting a single file to diagnosing why a change keeps disappearing, is in [↩️ Recovery](docs/Recovery.md).

---

### 🔗 See also

> [!TIP]
> Conventions live in [📐 Engineering Standards](https://github.com/tannergolden/standards) and are followed here by link rather than by copying, so nothing goes stale. Commit format, sign-off, branch naming and the `make` interface all come from there.

This repository takes **the conventions and not the automation**, which is the account's rule for its core repositories. It calls none of the published gate workflows and holds no trigger stubs for them; the checks that run here are its own, in [`.github/workflows/bootstrap.yaml`](.github/workflows/bootstrap.yaml), and they are the ones worth running on a dotfiles repository: ShellCheck, a PowerShell parse, every template rendered for every platform, and the full bootstrap and restore proof on macOS, Windows and Linux.

---

<div align="center">

**Read it, take what is useful, leave the rest.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by [@tannergolden](https://github.com/tannergolden).

</div>
