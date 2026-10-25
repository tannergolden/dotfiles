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

## 💡 What This Is

**Dotfiles that are one program.** Open a new Terminal window and a cabinet
powers up in it: neon breathing up both walls, a CRT that warms, rolls and
flickers, a starfield outside, and on the glass every machine in the suite with
what each one is doing right now. Everything wears the plate of ALIEN DYNAMICS,
a make-believe hardware maker of 1984, and the cabinet is its SYNTHWAVE series.

**It is zsh from end to end, on purpose.** macOS ships zsh and does not ship
python3, so the cabinet comes up on a fresh Mac with nothing installed, and so
does the installer that sets up the rest. No Python or Node sits in the path
between a double-click and the menu.

| Machine          | Model | What it is                                                                                                                                                                                                       |
| :--------------- | :---- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **TERMINAL**     | AD-1  | The door: [`terminal.command`](terminal.command), one self-contained file holding the whole cabinet, from the renderer and the power-up to the menu, the CONFIG panel and the sky. A copy on its own still runs. |
| **SYSTEM**       | NX-88 | A monitor for the Mac: eight pages of live readings, from a radar scope of every process to the battery's cycle count. It only reads.                                                                            |
| **INTELLIGENCE** | IQ-88 | A switchboard for AI command lines: the cloud agents on this Mac, the local models and the runners that hold them, a router, a bench and a prompt library.                                                       |
| **XENOGOTCHI**   | XG-9  | An adoption centre. You sign for one animal, name it, and it lives in its room on the real clock.                                                                                                                |
| **ARCADE**       | NX-88 | Twelve cabinets, one coin a game, with a high-score table for every rung, a trophy room and a marketplace.                                                                                                       |

The four machines live in [`scripts/suite/`](scripts/suite) as **page packs**:
the door reads each one into itself the first time you open it, and it draws
inside the door's own glass. [`scripts/bootstrap.zsh`](scripts/bootstrap.zsh) is
the installer, and three small files under [`home/`](home) hook the cabinet into
zsh.

---

## 🚀 Install

You need a Mac and its Terminal. zsh ships with macOS, and the cabinet needs
nothing else.

```zsh
git clone https://github.com/tannergolden/dotfiles.git ~/dotfiles
cd ~/dotfiles
zsh scripts/bootstrap.zsh --install
```

`--install` does three things and asks nothing:

1. **Links three files into your home folder**, each a symlink back into this
   repository: `~/.config/zsh/conf.d/00-alien-path.zsh`,
   `~/.config/zsh/conf.d/10-alien-terminal.zsh` and `~/.local/bin/alien`. A link
   that points somewhere else is replaced. A real file in the way is moved aside
   as `*.pre-alien`, never overwritten.
2. **Adds one marked block to `~/.zshrc`**, between `# >>> ALIEN dotfiles >>>`
   and `# <<< ALIEN dotfiles <<<`. All it does is source every `.zsh` file in
   `~/.config/zsh/conf.d`. A copy of the file is kept at `~/.zshrc.pre-alien`
   first, and nothing outside the marks is ever touched.
3. **Turns the hook switch on**, by writing `terminal.hook = on` into
   `terminal.conf`.

It is safe to run twice. Open a new window and the cabinet powers up.

| Command                                          | What it does                                                                                                                                          |
| :----------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `zsh scripts/bootstrap.zsh`                      | The same install as a page: five checks, then one question before anything changes.                                                                   |
| `zsh scripts/bootstrap.zsh --status`             | What is linked and where it points, whether the switch is on, and which tools are here. Changes nothing.                                              |
| `zsh scripts/bootstrap.zsh --tools`              | Homebrew if it is missing, the [`Brewfile`](Brewfile) if a tool in it is, then ollama started at login. Interactive: Homebrew asks for a password.    |
| `zsh scripts/bootstrap.zsh --plan`               | The exact lines `--tools` would run, with nothing run.                                                                                                |
| `zsh scripts/bootstrap.zsh --hook on` (or `off`) | The switch alone.                                                                                                                                     |
| `zsh scripts/bootstrap.zsh --remove`             | Takes the block out of `~/.zshrc`, unlinks the three files and turns the switch off. `~/.zshrc.pre-alien` and the Homebrew tools are left alone.      |
| `zsh scripts/bootstrap.zsh --uninstall`          | What **[U]** UNINSTALL runs: your progress and settings copied to `~/Downloads`, then everything else out, this clone last. Asks nothing.             |
| `zsh scripts/bootstrap.zsh --uninstall --plan`   | What `--uninstall` would take out, with nothing taken out.                                                                                            |

**Looking needs no install.** Double-click `terminal.command`, or run
`zsh terminal.command`, and the cabinet comes up anyway. **[N] INSTALL** on its
menu runs the same installer on the glass, and asks before it changes anything.

> [!NOTE]
> A `terminal.command` that arrives inside a downloaded zip carries macOS's
> quarantine flag, and Gatekeeper may refuse to open it with a double-click. A
> `git clone` does not have this problem.

**Moving the repository** leaves the three links pointing at nothing, and that
fails safe: the hook does nothing and `alien` says it cannot find the door. Run
`--install` again from the new place. Nothing else records where the repository
is, because the door, the launcher and the hook each find it from their own
resolved path.

A whole machine in order, with the agent rules and what a codespace gets
instead, is in [New Machine Setup](docs/introduction/New-Machine-Setup.md).

---

## 🕹️ Using It

Three ways in, all to the same cabinet:

- **A new Terminal window**, when the switch is on.
- **`alien`** at any prompt, whatever the switch says.
- **A double-click** on `terminal.command`.

The power-up takes about thirteen seconds: the stars alone while every machine
loads behind them, the tube warming, then the self test card saying what the
cabinet found on this Mac. Any key skips it, and **BOOT** set to fast on the
CONFIG page skips it for good.

**It keeps itself up to date.** While the stars are up, the clone your home
folder links to fetches its branch's upstream and fast-forwards to any new
commits, as `git pull --ff-only` would. When they change `terminal.command`,
the cabinet starts again as the new version. Commits of its own, or local
edits the new commits would overwrite, leave the clone as it is, and the self
test's ORIGIN line says which. A fetch slower than two seconds, or any fetch
with BOOT set to fast, is taken at the next power-on, and **UPDATE** on the
CONFIG page turns updating off.

| Key                                 | On the menu                                                                                       |
| :---------------------------------- | :------------------------------------------------------------------------------------------------ |
| ▲ ▼ or `j` `k`, then ⏎              | Move through the rows and act on one. ⏎ on a machine walks into it.                               |
| **[T]** TERMINAL                    | Your own login shell, inside the glass. `^]` steps back to the menu with the shell still running. |
| **[N]** INSTALL / **[U]** UNINSTALL | The installer, on the glass: INSTALL until all three files are linked, and UNINSTALL always.      |
| **[R]** RESCAN                      | Reads the machine again and shows the self test card.                                             |
| **[C]** CONFIG                      | Sound, frame rate, boot, screen and update, written straight to `terminal.conf`.                  |
| **[Q]**                             | Power off, from anywhere. **[Y]** confirms.                                                       |

The same keys mean the same thing on every surface: ◂ ▸ turn pages, ⎋ goes back
one level, **[M]** or ⌫ leave a machine, and each page names its own keys along
its foot.

---

## 🖥️ The Machines

**SYSTEM** reads the Mac with the commands macOS already has (`sysctl`,
`vm_stat`, `df`, `netstat`, `ioreg`, `pmset`, `ps` and `top`) and changes
nothing. It has six instruments, [O] OVERVIEW, [C] PROCESSOR, [R] MEMORY,
[D] STORAGE, [N] NETWORK and [B] POWER, then two tables, [P] PROCESSES and
[H] HARDWARE. The per-core split is the one figure macOS does not publish to a
shell, so SYSTEM asks python3 for it when python3 is present, and shows the
totals when it is not.

**INTELLIGENCE** has seven pages. [C] CLOUD holds Claude Code, Antigravity, Grok
Build and Codex, each used only through its own official command line and signed
in on your own account. [L] LOCAL holds the runners (ollama, llama.cpp,
LM Studio and MLX) and the models on this disk. [R] ROUTE puts a LiteLLM proxy
between local and cloud, and [B] BENCH, [P] PROMPTS, [H] HISTORY and [K] KEYS
round it out. Every install or removal shows the exact line it will run and
waits for a **[Y]**. An egress guard checks anything bound for a cloud engine for
secrets and fails closed, and the suite never reads, copies or proxies a token,
or the value of an API key.

**XENOGOTCHI** has four pages: [H] HOME, where the animal lives, [O] STORE,
[A] ADOPT and [S] STATS. Twenty-five species arrive in shipments, three of them
from further out than Earth. An animal ages on the wall clock, picks what to do
next from a running emotional state, and keeps living while the cabinet is
closed, gently: time away is capped, and a wrong clock is never read as a lost
pet.

**ARCADE** holds twelve games: NEON SNAKE, BLOCK FALL, VOID PONG, BRICK NOVA,
STAR RAIDER, GRID RUNNER, LASER DODGE, NIGHT DRIVE, LIGHT CYCLE, PLASMA BALL,
ASTRO DRIFT and BEAT GRID. Each has four rungs, ROOKIE to INSANE, with a
high-score table for every one. Coins come from playing. The MARKETPLACE sells
the machines, and the TROPHY ROOM holds 172 trophies.

---

## 🚪 Ways Out

A hook that opens a full-screen program in every new shell could lock you out
of your own terminal if the cabinet ever broke. So there are four ways out, and
every one of them works:

| Way out                                | What you get                              |
| :------------------------------------- | :---------------------------------------- |
| `ALIEN_NO_TERMINAL=1 zsh`              | A plain prompt in this window, right now. |
| **[Q]** then **[Y]** in the cabinet    | Your own prompt, in the same window.      |
| `zsh scripts/bootstrap.zsh --hook off` | The switch off, with nothing uninstalled. |
| `zsh scripts/bootstrap.zsh --remove`   | The hook taken back out entirely.         |

The hook also keeps out of the way on its own. It opens nothing in a script, a
one-off command, a pipe, `scp` or `rsync`; in tmux or screen; over ssh; in the
terminals inside VS Code, Warp or Hyper; or in a shell that is already inside
the suite. Whenever it is unsure, it fails toward a plain prompt.

Anything else that goes wrong has its message and its fix in
[Troubleshooting](docs/operations/Troubleshooting.md).

---

## ⚙️ Settings

`terminal.conf` sits beside `terminal.command` and holds every setting, one
`key = value` per line. It belongs to each Mac and is **kept out of git**: a
fresh clone runs on the defaults, and the installer writes the one switch it
needs. The last spelling of a key wins, and every program leaves alone the keys
it does not own.

| Key                 | Values                       | What it sets                                                         |
| :------------------ | :--------------------------- | :------------------------------------------------------------------- |
| `sound`             | `on` · `off`                 | The cabinet's small noises. CONFIG, or [U] in the arcade.            |
| `beat`              | `auto` · `30` · `60` · `120` | The frame rate. CONFIG.                                              |
| `boot`              | `full` · `fast`              | The whole opening, or straight to the menu. CONFIG.                  |
| `screen`            | `float` · `fill`             | The cabinet centred in the window, or the glass filling it. CONFIG.  |
| `update`            | `on` · `off`                 | Whether a power-on takes origin's new commits. CONFIG.               |
| `terminal.hook`     | `on` · `off`                 | Whether a new window opens the cabinet. Only exactly `on` opens it.  |
| `arcade.attract`    | `on` · `off`                 | The demo reel after 20 idle seconds. The arcade's SETTINGS.          |
| `arcade.freeplay`   | `on` · `off`                 | Play without coins, and earn none. The arcade's SETTINGS.            |
| `arcade.difficulty` | `0` to `3`                   | The rung last started on, ROOKIE to INSANE.                          |
| `arcade.player`     | a name                       | The name high scores are signed with. Empty uses your Mac user name. |

The door reads the file at power-on, so a hand edit takes effect at the next
one.

---

## 💾 Your Save

`terminal.save` holds every machine's progress: the arcade's coin bank, tables
and trophies, and every animal you have signed for, one dotted
`key=value` a line. The cabinet looks for it **beside `terminal.command`
first**, then in `~/.local/state/alien/`, and `ALIEN_SAVE=<file>` overrides
both. The self test's READING SAVE AND CONFIG lines say which one it found.

It is **kept out of git**, and the one in `~/.local/state/alien/` should stay
there: a copy beside `terminal.command` takes precedence over it.

**To carry your progress to another Mac**, copy `terminal.save`, and
`terminal.conf` for your settings, beside `terminal.command` there, then
install.

`~/.local/state/alien/` (or `$XDG_STATE_HOME/alien`) also holds the suite's
short-lived facts and the configs INTELLIGENCE writes. None of it belongs in
git. [Machine Footprint](docs/references/Machine-Footprint.md) lists each
file, and everything else the suite leaves on a Mac.

---

## 🧰 What It Leans On

The [`Brewfile`](Brewfile) names only what the machines reach for, and
`bootstrap.zsh --tools` installs it:

| Package     | Why                                                                                                      |
| :---------- | :------------------------------------------------------------------------------------------------------- |
| `ollama`    | Holds a local model in memory and answers on `127.0.0.1:11434`. The tools step starts it at every login. |
| `llama.cpp` | The other runner: one server per GGUF file, on port 8080.                                                |
| `opencode`  | The coding agent that runs a local model when you press ⏎ on it in INTELLIGENCE's LOCAL page.            |
| `node`      | Codex installs with npm.                                                                                 |

Everything else ships with macOS: zsh, curl, perl, sysctl, vm_stat, top, ioreg,
pmset, netstat, osascript, afplay and pbcopy. The four cloud agents are not in
the Brewfile. Each one signs in to your own account, so INTELLIGENCE installs
them one at a time, behind its gate.

---

## 🧪 Testing

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

The invented Mac is `moonbase`, a 16-inch M3 Max in
[`scripts/fixtures/system/`](scripts/fixtures/system/README.md): plain data
files, so the pictures are reproducible and leak nothing about a real machine.

| Launch flag        | What it does                               |
| :----------------- | :----------------------------------------- |
| `--probe`          | A text report of what it found, then exit. |
| `--once`           | Paint one frame and exit.                  |
| `--fast`           | The card, with no ceremony.                |
| `--back`           | Skip the power-up.                         |
| `--check`          | The glyph test card.                       |
| `--256` / `--true` | Force the xterm 256 palette, or 24-bit.    |
| `--plain`          | No colour at all.                          |
| `--fps N`          | Pin the frame rate.                        |

| Variable                                   | What it does                                                                                       |
| :----------------------------------------- | :------------------------------------------------------------------------------------------------- |
| `TERMINAL_MOCK=1`                          | The door reads an invented Mac. INTELLIGENCE and XENOGOTCHI follow it.                             |
| `SYSTEM_MOCK=1`                            | SYSTEM reads the fixture. Set both for a wholly invented machine.                                  |
| `INTELLIGENCE_MOCK=1`, `XENOGOTCHI_MOCK=1` | Mock one machine at a time.                                                                        |
| `ALIEN_SAVE=<file>`                        | Point the cabinet at another save. Test against a copy, never against your own save.               |
| `ALIEN_AT=<seconds>`                       | Stop the animation clock at that instant, so a captured frame is the same on any machine.          |
| `ALIEN_MIRROR=<n>/<m>`                     | Stand in for how many of the home links are in place, which decides whether INSTALL is offered.    |
| `ALIEN_OSASCRIPT=<command>`                | Stand in for osascript.                                                                            |
| `ALIEN_NO_TERMINAL=1`                      | Keep the hook out of this shell. Set it on any interactive shell your own tooling opens.           |

### Changing the code

- **The door opens with `emulate -L zsh`,
  `setopt KSH_ARRAYS SH_WORD_SPLIT NO_NOMATCH` and `set -u`**, and the packs
  are sourced into it, so they run under the same options. Arrays are 0-based,
  an unset variable is an error, and a bare `$arr` is the first element, so
  write `"${arr[@]}"`.
- **The packs share the door's namespace.** Each one prefixes its own functions
  and globals (`sy_`, `in_`, `xg_` and `ar_`, and their capitals), and short
  output names like `REPLY` are common to all of them, so check
  `terminal.command` before adding a new short name.
- **Comments explain why**, in a capitalised lead sentence.
- **Test against copies.** Point `ALIEN_SAVE` at a copy of a save, and never
  change an animal somebody already owns.
- **Read the contracts first.** [Page Packs](docs/technical/Page-Packs.md) is
  the one between the door and each machine,
  [Shell Hook & Installer](docs/technical/Shell-Hook-&-Installer.md) the one
  between a new shell, the installer and the door, and
  [Checking A Change](docs/distribution/Checking-A-Change.md) says what CI
  cannot check for you. The cabinet's own words are in the
  [Glossary](docs/references/Glossary.md).

---

## 📦 What's Inside

**Paths are contracts.** The door finds `scripts/suite/<name>.zsh`,
`scripts/bootstrap.zsh`, `scripts/fixtures/system/`, `terminal.conf` and
`terminal.save` by these exact relative paths. The launcher and the hook find
the repository by following their own link and climbing back up, four levels
from `home/.local/bin/alien` and five from the hook, so `home/` has to keep
exactly this shape.

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

## 🌿 The Repository

This repository was generated from
[`tannergolden/path`](https://github.com/tannergolden/path), a standards
template, so the machinery around the suite is the same as in every other
repository here. It keeps its own layout rather than the template's `src/` and
`tests/`, because its tree is where its files install: **📦 What's Inside**
says which paths are contracts. Work lands on `Development` through pull
requests, squash-merged, so each pull request title becomes one Conventional
Commit.

- **🚦 Checks** run on every pull request and on `Development`: the repository
  validator and its tests, a gitleaks secret scan, CodeQL, workflow lint,
  spelling and links.
- **⚖️ Governance** holds pull request titles to Conventional Commits.
- **🔄 Template Sync** brings the template's later fixes as a pull request, and
  only when you run it. The rules this repository adds to `.gitignore` and
  `.gitattributes` sit at the end of each file, where a sync keeps them. See
  [`.github/template-sync.md`](.github/template-sync.md).
- **🔁 Intelligence Sync** keeps the universal rules for AI agents in
  [`AGENTS.md`](AGENTS.md) current from tannergolden/intelligence, as one pull
  request each release.

Every workflow is described in
[`.github/workflows/README.md`](.github/workflows/README.md).

---

## 🔒 Licence

MIT. See [`LICENSE`](LICENSE).

---

<div align="center">

**Insert coin.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by [@tannergolden](https://github.com/tannergolden). Distributed under the terms in [LICENSE](/LICENSE).

</div>
