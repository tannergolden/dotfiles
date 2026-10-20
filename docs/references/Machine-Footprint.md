<!--
title: '📦 MACHINE FOOTPRINT'
description: 'Every file, folder, service and environment variable these dotfiles put on a Mac or read from it: what writes each one, whether it travels in git, and what takes it off again. Consult it when moving to another machine, cleaning one up, or looking for where something lives.'
type: reference
keywords: [state folder, xdg, environment variables, paths, cleanup, migration, gitignore]
-->

<div align="center">

# 📦 MACHINE FOOTPRINT

<a name="top"></a>

**Everything the suite leaves on a Mac, where it lives, and what takes it off.**

_Git carries the clone. The machine keeps the rest._

</div>

---

## 💡 What Travels

Git carries the clone and nothing else on this page. Two files are worth
carrying to another Mac by hand, `terminal.save` for progress and
`terminal.conf` for settings; everything else is rebuilt there by the
installer, Homebrew and the machines. Paths below use the defaults: the state
folder moves with `XDG_STATE_HOME`, `.zshrc` with `ZDOTDIR`, and temporary
files with `TMPDIR`.

---

## 📁 In The Clone, Never Committed

`.gitignore` keeps all four patterns out, so a fresh clone runs on defaults.

| Path              | Written by                                                | Holds                                   |
| :---------------- | :-------------------------------------------------------- | :-------------------------------------- |
| `terminal.conf`   | CONFIG, the ARCADE's SETTINGS, and the installer's switch | Every setting, one `key = value` a line |
| `terminal.save`   | The machines, when this is the save they found            | Every machine's progress                |
| `terminal.conf.*` | CONFIG and the ARCADE, for a moment as they write         | The whole file, before it is moved over |
| `terminal.save.*` | The ARCADE and XENOGOTCHI, for a moment as they write     | The same, for the save                  |

What each key of `terminal.conf` does is in the Settings section of the
[README](../../README.md). A save beside `terminal.command` wins over the one
in the state folder, which is why a committed one would take over every
machine that cloned it.

---

## 🏠 In The Home Folder

| Path                                         | Put there by                                 | Comes off with |
| :------------------------------------------- | :------------------------------------------- | :------------- |
| `~/.config/zsh/conf.d/00-alien-path.zsh`     | `--install`, as a link into the clone        | `--remove`     |
| `~/.config/zsh/conf.d/10-alien-terminal.zsh` | `--install`, as a link into the clone        | `--remove`     |
| `~/.local/bin/alien`                         | `--install`, as a link into the clone        | `--remove`     |
| `~/<leaf>.pre-alien`                         | `--install`, for a real file in a link's way | By hand        |
| The block in `~/.zshrc`                      | `--install`, between its two marks           | `--remove`     |
| `~/.zshrc.pre-alien`                         | `--install`, once, before the first block    | By hand        |

`--remove` unlinks only links that still point into this clone, so a link
somebody pointed elsewhere is left alone.

---

## 🗂️ The State Folder

`~/.local/state/alien/` holds the suite's short-lived facts and the configs
INTELLIGENCE writes. The installer makes it, and every writer makes it again
on the way if it is missing. Nothing takes it off: delete it by hand once the
suite is gone, keeping `terminal.save` if your progress lives there.

| File                  | Written by                                                | Holds                                                                   |
| :-------------------- | :-------------------------------------------------------- | :---------------------------------------------------------------------- |
| `terminal.save`       | The machines, when no save sits beside `terminal.command` | Every machine's progress                                                |
| `dealing`             | The door, and INTELLIGENCE, while they open tabs          | An expiry in epoch seconds; the hook stands aside until it passes       |
| `suite`               | The door, while it has machines open in tabs of their own | The house token those tabs share                                        |
| `warming`             | The door, while it gets a pack ready at power-on          | The cabinet's pid, and the pack's path and modification time            |
| `warm-skip`           | The door, at power-on                                     | Packs that took the cabinet down while being got ready                  |
| `opencode.json`       | INTELLIGENCE, when ⏎ opens a local model in opencode      | The local runners and their models, as opencode providers               |
| `opencode-route.json` | **[G]** on ROUTE, and ROUTE when it opens opencode        | One opencode provider, the router on port 4000                          |
| `litellm.yaml`        | **[G]** on ROUTE                                          | The router's config; keys go in as environment references, never values |
| `alien_guard.py`      | **[G]** on ROUTE                                          | The egress guard, as a LiteLLM pre-call guardrail                       |

The four configs are written readable by you alone (mode 600). A pack named
in `warm-skip` is read only when you open it, until its file changes; delete
`warm-skip` to have every pack got ready at power-on again.

---

## 🍺 Homebrew, Runners And Agents

| What                                                 | Put there by                                             | Comes off with              |
| :--------------------------------------------------- | :------------------------------------------------------- | :-------------------------- |
| Homebrew                                             | `--tools`, when there is no `brew`                       | Nothing here                |
| `ollama`, `llama.cpp`, `opencode`, `node`            | `--tools`, through `brew bundle` on the Brewfile         | `brew uninstall <name>`     |
| `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist`  | `--tools`, through `brew services start ollama`          | `brew services stop ollama` |
| Claude Code, Antigravity, Grok Build, Codex          | **[I]** on INTELLIGENCE's CLOUD page, each vendor's line | **[U]** on the same page    |
| Models                                               | **[I]** on INTELLIGENCE's LOCAL page                     | **[U]** on the same page    |
| The universal agent rules, in each app's home folder | `make agents`                                            | `make agents-uninstall`     |

The cloud agents' install lines are `IN_GET` in
[`scripts/suite/intelligence.zsh`](../../scripts/suite/intelligence.zsh), and
the gate shows each one exactly as it runs it. Beside them, `IN_RGET` holds the
line the LOCAL page names for a runner it does not find. Which files the agent
rules write is the hub's to say: [AI Agent Rules](../technical/AI-Agent-Rules.md).

---

## ⏳ Temporary Files

Every temporary file the suite makes is named `alien-` and something, in
`${TMPDIR:-/tmp}`, and is taken away by the code that made it. Three are worth
knowing by name:

| Name                                       | Made by                                                                         |
| :----------------------------------------- | :------------------------------------------------------------------------------ |
| `alien-pack.<pid>`, `alien-pack.<pid>.log` | The door: its breadcrumb around a pack it sources, and the pack's stderr        |
| `alien-term.*`                             | The door: its AppleScripts, their errors, and its stderr while the screen is up |
| `alien-sys.*`                              | SYSTEM: the reading it takes in the background                                  |

INTELLIGENCE's request bodies and answers (`alien-chat`, `alien-rw` and the
rest) are made with `mktemp` and set to mode 600. When a pack takes the
cabinet down, the door prints what the pack said and removes its breadcrumb:
[Troubleshooting](../operations/Troubleshooting.md#-the-cabinet) says what to
do next.

---

## ⚙️ Environment Variables

**Read from your environment.** The test seams, `TERMINAL_MOCK`,
`SYSTEM_MOCK`, `INTELLIGENCE_MOCK`, `XENOGOTCHI_MOCK`, `ALIEN_AT`,
`ALIEN_MIRROR` and `ALIEN_OSASCRIPT`, are in the
[README](../../README.md#-testing). The rest:

| Variable                              | What it changes                                                              |
| :------------------------------------ | :--------------------------------------------------------------------------- |
| `ALIEN_NO_TERMINAL`, `ALIEN_NO_DOOR`  | The hook stands aside in this shell; the second is the older name            |
| `ALIEN_SAVE`                          | The save to use, over both usual places                                      |
| `ALIEN_REPO`                          | The repository the hook opens, over the one its own link leads to            |
| `ALIEN_FPS`                           | The frame rate, pinned and clamped, with no measuring of the display         |
| `ALIEN_DEBUG_FPS`                     | The footer shows the rate held, the rate aimed at, and the panel's refresh   |
| `ALIEN_ARCADE_BOARD`                  | The board number every ARCADE round is dealt, in place of a random one       |
| `XDG_CONFIG_HOME`, `XDG_BIN_HOME`     | Where the block looks for `conf.d`, and the folder the PATH leaf adds        |
| `XDG_STATE_HOME`, `ZDOTDIR`, `TMPDIR` | The state folder, the folder holding `.zshrc`, and the temporary files       |
| `INTELLIGENCE_BASE`                   | Where `home-kit.sh` downloads a release from; the tests point it at a folder |
| Provider keys and endpoints           | Only whether each is set, and its length, on INTELLIGENCE's KEYS page        |

The KEYS page asks after `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`,
`GEMINI_API_KEY`, `GOOGLE_API_KEY`, `XAI_API_KEY`, `OPENAI_API_KEY`,
`OPENROUTER_API_KEY`, `GROQ_API_KEY`, `MISTRAL_API_KEY`, `DEEPSEEK_API_KEY`,
`TOGETHER_API_KEY`, `OLLAMA_HOST` and `OPENAI_BASE_URL`, and never reads a
value into anything it can draw.

**Set by the suite, for what it starts.** These are contracts between its
parts, not settings:

| Variable                            | Set by                      | For                                                                            |
| :---------------------------------- | :-------------------------- | :----------------------------------------------------------------------------- |
| `ALIEN_DOOR`                        | The door, and the hook      | Every shell inside the suite, so the hook stands aside there                   |
| `ALIEN_REPO`                        | The door, the hook, `alien` | Where the clone is, for what runs inside                                       |
| `ALIEN_HOUSE`                       | The hook                    | Marks a cabinet the hook opened; nothing in the suite reads it                 |
| `ALIEN_REPORT`                      | The door                    | The installer, which then answers in records                                   |
| `PACK_SOURCED`                      | The door                    | A pack, which then knows it was sourced and not run                            |
| `ALIEN_GLASS`, `ALIEN_INTELLIGENCE` | The door                    | Every program started in the terminal on the glass, the **[T]** shell included |

---

<div align="center">

**Two files travel. Everything else is rebuilt where it lands.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](../../LICENSE).

</div>
