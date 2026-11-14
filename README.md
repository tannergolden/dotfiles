<!--
title: '👽 DOTFILES'
description: 'A synthwave arcade cabinet that runs inside macOS Terminal, written entirely in zsh: one door, four machines, and the three shell files that hook it in.'
type: index
-->

<div align="center">

# 👽 DOTFILES

<a name="top"></a>

**A synthwave arcade cabinet that runs inside macOS Terminal, written entirely in zsh.**

_One door. Four machines. Nothing to install first._

</div>

---

## 💡 What It Is

**Dotfiles that are one program.** Open a new Terminal window and a cabinet
powers up in it, with every machine in the suite on its glass and what each
one is doing right now. It is zsh from end to end, on purpose: macOS ships zsh
and not python3, so the cabinet and its installer come up on a fresh Mac with
nothing installed.

![The cabinet powering up: stars alone, the cabinet lighting around a dark tube, the glass warming, the self test card finding no save and no config and running on factory settings, then the picture opening onto the menu, with every machine beside its live reading](assets/screenshots/terminal-power-up.gif)

| Machine          | What it is                                                                                     |
| :--------------- | :--------------------------------------------------------------------------------------------- |
| **TERMINAL**     | The door: [`terminal.command`](terminal.command), the whole cabinet in one self-contained file |
| **SYSTEM**       | A monitor for the Mac: eight pages of live readings. It only reads                             |
| **INTELLIGENCE** | A switchboard for AI command lines, local models and their runners                             |
| **XENOGOTCHI**   | An adoption centre: an animal that lives in its room on the real clock                         |
| **ARCADE**       | Twelve cabinets, with a high-score table for every rung and a trophy room                      |

- **Status**: Active.

---

## 🚀 Quick Start

### 📥 Install

You need a Mac and its Terminal; zsh ships with macOS.

```zsh
git clone https://github.com/tannergolden/dotfiles.git ~/dotfiles
cd ~/dotfiles
zsh scripts/bootstrap.zsh --install
```

`--install` asks nothing and is safe to run twice. It links three files into
your home folder, each a symlink back into this repository (a real file in the
way is moved aside as `*.pre-alien`), adds one marked block to `~/.zshrc`
(after keeping a copy as `~/.zshrc.pre-alien`), and turns the hook switch on.
Open a new window and the cabinet powers up.

| Command                                 | What it does                                                                        |
| :-------------------------------------- | :---------------------------------------------------------------------------------- |
| `zsh scripts/bootstrap.zsh --status`    | What is linked and where it points, and whether the switch is on. Changes nothing   |
| `zsh scripts/bootstrap.zsh --tools`     | Homebrew and the [`Brewfile`](Brewfile): ollama, llama.cpp, opencode and node       |
| `zsh scripts/bootstrap.zsh --remove`    | Takes the block out of `~/.zshrc`, unlinks the three files and turns the switch off |
| `zsh scripts/bootstrap.zsh --uninstall` | Copies your progress and settings to `~/Downloads`, then takes everything else out  |

**Looking needs no install**: double-click `terminal.command`, or run
`zsh terminal.command`. [New Machine Setup](docs/introduction/New-Machine-Setup.md)
puts a whole machine in order, the agent rules included.

---

## 📖 Using It

### 🕹️ The Cabinet

Open it from a new Terminal window when the switch is on, with `alien` at any
prompt, or with a double-click on `terminal.command`. Any key skips the
power-up. The same keys mean the same thing everywhere: ▲ ▼ and ⏎ to move and
act, ⎋ to go back one level, **[C]** for CONFIG and **[Q]** to power off.

**It keeps itself up to date**: at power-on the clone fast-forwards to its
branch's new commits, as `git pull --ff-only` would, and leaves a clone with
commits or edits of its own as it is. **UPDATE** on the CONFIG page turns this
off.

Settings live in `terminal.conf` and progress in `terminal.save`, both beside
`terminal.command`, both kept out of git. To carry your progress to another
Mac, copy both there, then install.
[Machine Footprint](docs/references/Machine-Footprint.md) lists every file the
suite leaves on a Mac.

### 🚪 Ways Out

| Way out                                | What you get                              |
| :------------------------------------- | :---------------------------------------- |
| `ALIEN_NO_TERMINAL=1 zsh`              | A plain prompt in this window, right now. |
| **[Q]** then **[Y]** in the cabinet    | Your own prompt, in the same window.      |
| `zsh scripts/bootstrap.zsh --hook off` | The switch off, with nothing uninstalled. |
| `zsh scripts/bootstrap.zsh --remove`   | The hook taken back out entirely.         |

The hook opens nothing in a script, a pipe, tmux, screen, ssh or an editor's
terminal, and whenever it is unsure it fails toward a plain prompt.
[Troubleshooting](docs/operations/Troubleshooting.md) has every message and its
fix.

### 🧪 Testing

Three checks prove the suite still works, and none of them reads the real
machine:

```zsh
# Every file parses.
for f in terminal.command home/.local/bin/alien **/*.zsh; do zsh -n "$f"; done

# SYSTEM reads the invented Mac byte for byte: no output means all 1,108 lines match.
SYSTEM_MOCK=1 zsh scripts/suite/system.zsh --probe | diff - scripts/fixtures/system/probe.expected

# The door comes up, finds all four machines, and reports what it found.
TERMINAL_MOCK=1 zsh terminal.command --probe
```

[Checking A Change](docs/distribution/Checking-A-Change.md) lists every launch
flag and test seam, and what CI cannot check for you.

### Changing the code

- **The door opens with `emulate -L zsh`,
  `setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH` and `set -u`**, and the packs
  run under the same options: arrays are 0-based, an unset variable is an
  error, and a bare `$arr` is the first element, so write `"${arr[@]}"`.
- **The packs share the door's namespace**, each with its own prefix (`sy_`,
  `in_`, `xg_` and `ar_`).
- **Test against copies.** Point `ALIEN_SAVE` at a copy of a save, never your
  own.
- **Read the contracts first**: [Page Packs](docs/technical/Page-Packs.md) and
  [Shell Hook & Installer](docs/technical/Shell-Hook-&-Installer.md).

---

## 📦 What's Inside

**Paths are contracts.** The door finds `scripts/suite/<name>.zsh`,
`scripts/bootstrap.zsh`, `scripts/fixtures/system/`, `terminal.conf` and
`terminal.save` by these exact relative paths, and the launcher and the hook
find the repository by climbing back up from their own link, so `home/` has to
keep exactly this shape.

```text
terminal.command                                the door: the whole cabinet, in one file
terminal.conf                                   settings: this Mac's own, never committed
Brewfile                                        ollama, llama.cpp, opencode and node
home/.config/zsh/conf.d/00-alien-path.zsh       ~/.local/bin, and Homebrew's bin if missing, on PATH
home/.config/zsh/conf.d/10-alien-terminal.zsh   the hook: opens the cabinet in a new interactive shell
home/.local/bin/alien                           the launcher behind `alien`
scripts/bootstrap.zsh                           the installer
scripts/suite/system.zsh                        SYSTEM
scripts/suite/intelligence.zsh                  INTELLIGENCE
scripts/suite/xenogotchi.zsh                    XENOGOTCHI
scripts/suite/arcade.zsh                        ARCADE
scripts/fixtures/system/                        moonbase, the invented Mac, and its golden probe output
```

<!-- AUTO-INDEX:BEGIN dir=. style=log -->

| Entry                                              | Purpose                                                                                                                                                                                            |
| :------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`.devcontainer/`](.devcontainer/README.md)        | The language-neutral development container this repository ships, and how to give it the toolchain your project needs.                                                                             |
| [`.github/`](.github/)                             | Community health files, forms, CODEOWNERS, Dependabot, actions, scripts and workflows - logged below                                                                                               |
| [`.vscode/`](.vscode/README.md)                    | The VS Code settings and extension recommendations this repository shares, and why every other file in this folder stays out of git.                                                               |
| [`agents/`](agents/README.md)                      | Installs one pinned release of the universal rules and their kit from tannergolden/intelligence into every AI coding app on this machine.                                                          |
| [`assets/`](assets/README.md)                      | Where this project keeps what presents it: four folders to start, a name ready for every other kind, and the rules every file follows.                                                             |
| [`docs/`](docs/README.md)                          | Where this project keeps its own documents, and where the engineering standards it follows actually live.                                                                                          |
| [`home/`](home/)                                   | The three files the installer links into your home folder: the PATH leaf, the hook and the alien launcher.                                                                                         |
| [`scripts/`](scripts/README.md)                    | The installer, the four machines as page packs, and moonbase, the invented Mac that SYSTEM reads in demo mode.                                                                                     |
| [`.editorconfig`](.editorconfig)                   | Editor defaults every editor honours: UTF-8, LF, a final newline, and indentation per language                                                                                                     |
| [`.env.example`](.env.example)                     | Environment variable template for this project.                                                                                                                                                    |
| [`.git-blame-ignore-revs`](.git-blame-ignore-revs) | Commits that changed only formatting, which `git blame` should look through.                                                                                                                       |
| [`.gitattributes`](.gitattributes)                 | Git attributes - line endings, diffs, and what counts as binary                                                                                                                                    |
| [`.gitignore`](.gitignore)                         | &#x1F5C4;&#xFE0F; Universal Ignore Patterns                                                                                                                                                        |
| [`.markdownlint.json`](.markdownlint.json)         | Repository-wide markdownlint rules. Discovered by mechanism, which is why this lives at the root.                                                                                                  |
| [`_typos.toml`](_typos.toml)                       | The spell check's accepted words and exclusions for this repository, passed to CI as `typos-config` in .github/workflows/checks.yml.                                                               |
| [`AGENTS.md`](AGENTS.md)                           | How AI agents work on the dotfiles, tannergolden/dotfiles: the universal rules first, then the rules for the zsh suite, its installer and hook, and the agent kit. Read it before any change here. |
| [`Brewfile`](Brewfile)                             | B R E W F I L E what this suite needs from homebrew (c) ALIEN DYNAMICS 1984 &#xB7; read by scripts/bootstrap.zsh --tools                                                                           |
| [`install.sh`](install.sh)                         | Set up a new machine or codespace from these dotfiles.                                                                                                                                             |
| [`LICENSE`](LICENSE)                               | MIT License                                                                                                                                                                                        |
| [`Makefile`](Makefile)                             | Dotfiles commands. The agents targets install the universal rules from tannergolden/intelligence into every AI app's home folder; docs/technical/AI-Agent-Rules.md explains them.                  |
| [`README.md`](README.md)                           | This file.                                                                                                                                                                                         |
| [`terminal.command`](terminal.command)             | T E R M I N A L the way into the ALIEN suite (c) ALIEN DYNAMICS 1984 &#xB7; model AD-1 "SYNTHWAVE"                                                                                                 |

<!-- AUTO-INDEX:END -->

The folders that came with the template each carry a `README.md` that logs the
files inside them. GitHub shows a README in `.github/` in place of this page, so
that folder's own files are logged here instead. 🗂️ Machined Indexes redraws
both tables after every push:

<!-- AUTO-INDEX:BEGIN dir=./.github style=log -->

| Entry                                                           | Purpose                                                                                                                                              |
| :-------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`actions/`](.github/actions/README.md)                         | The composite actions this repository keeps for its own workflows, and for any other repository that calls them.                                     |
| [`DISCUSSION_TEMPLATE/`](.github/DISCUSSION_TEMPLATE/README.md) | The discussion category forms, each bound by its file name to the category it shapes.                                                                |
| [`ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/README.md)           | The issue forms a reporter chooses from, and the chooser configuration that offers them.                                                             |
| [`scripts/`](.github/scripts/README.md)                         | The checks this repository runs on its own configuration, and the tests that guard them.                                                             |
| [`workflows/`](.github/workflows/README.md)                     | Every workflow in this repository: the name it shows in the Actions tab, what triggers it, and what it does.                                         |
| [`ACCESSIBILITY.md`](.github/ACCESSIBILITY.md)                  | The accessibility this project aims for, how to report a barrier, and what happens after you do.                                                     |
| [`CODE_OF_CONDUCT.md`](.github/CODE_OF_CONDUCT.md)              | The code of conduct governing participation in this project, how to report a violation, and how harm is addressed and repaired.                      |
| [`CODEOWNERS`](.github/CODEOWNERS)                              | Folder-based ownership rules                                                                                                                         |
| [`commit-template.txt`](.github/commit-template.txt)            | &lt;type&gt;(&lt;scope&gt;): &lt;emoji&gt; &lt;subject starting lowercase, no em dash&gt;                                                            |
| [`CONTRIBUTING.md`](.github/CONTRIBUTING.md)                    | How to contribute, covering branching, commits, code style, testing, and the pull-request process.                                                   |
| [`dependabot.yml`](.github/dependabot.yml)                      | Dependabot - automated dependency updates                                                                                                            |
| [`FUNDING.yml`](.github/FUNDING.yml)                            | &#x1F496; Funding Options                                                                                                                            |
| [`GOVERNANCE.md`](.github/GOVERNANCE.md)                        | How this project is led, who decides what, how access continues, and the review and security standards every change meets.                           |
| [`pull_request_template.md`](.github/pull_request_template.md)  | This template becomes the body of your pull request.                                                                                                 |
| [`release.yml`](.github/release.yml)                            | GitHub auto-generated release notes configuration.                                                                                                   |
| [`SECURITY.md`](.github/SECURITY.md)                            | How to report a vulnerability privately, what happens after you do, which versions receive security fixes, and the protections this repository runs. |
| [`SUPPORT.md`](.github/SUPPORT.md)                              | Where to get help with this repository - the right channel for every kind of question.                                                               |
| [`template-sync`](.github/template-sync)                        | Every path tannergolden/path ships, and whether &#x1F504; Template Sync, when you run it, keeps it current in this repository.                       |
| [`template-sync.lock`](.github/template-sync.lock)              | Where each file here was last synced from.                                                                                                           |
| [`template-sync.md`](.github/template-sync.md)                  | How this repository takes its template's later fixes when you run &#x1F504; Template Sync, what you control, and what waits on you.                  |
| [`VULNERABILITY_REPORT.yml`](.github/VULNERABILITY_REPORT.yml)  | Report a suspected vulnerability privately, so the maintainers can fix it before it is made public.                                                  |

<!-- AUTO-INDEX:END -->

---

## 🤝 Getting Involved

- **Questions**: [`SUPPORT.md`](/.github/SUPPORT.md) says where to ask.
- **A bug or an idea**: open an issue from one of the forms.
- **A change**: [`CONTRIBUTING.md`](/.github/CONTRIBUTING.md) explains how.
  Work lands on `Development` through squash-merged pull requests, following
  the [standards](https://github.com/tannergolden/standards/blob/Development/docs/README.md)
  by link, and every contribution follows the
  [code of conduct](/.github/CODE_OF_CONDUCT.md).
- **Who decides**: [`GOVERNANCE.md`](/.github/GOVERNANCE.md) names the
  maintainers.

This repository was generated from
[`tannergolden/path`](https://github.com/tannergolden/path) but keeps its own
layout, because its tree is where its files install. 🔄 Template Sync brings
the template's fixes when you run it ([how](.github/template-sync.md)), and
[`.github/workflows/README.md`](.github/workflows/README.md) logs every
workflow.

---

## 🛡️ Security

Report a vulnerability privately, never in an issue:
[`SECURITY.md`](/.github/SECURITY.md) says how, and how fast a fix follows.

---

## ⚖️ Licence

The dotfiles are released under the terms in [LICENSE](/LICENSE).

---

<div align="center">

**Insert coin.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by [@tannergolden](https://github.com/tannergolden). Distributed under the terms in [LICENSE](/LICENSE).

</div>
