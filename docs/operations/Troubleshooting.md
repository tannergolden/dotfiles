<!--
title: '🔧 TROUBLESHOOTING'
description: 'What each message and symptom from the hook, the cabinet, the installer and the agent kit means, and what to do about it, from a window that opens no cabinet to a pin that does not match. Read it when something on a machine does not do what the README says.'
type: guide
-->

<div align="center">

# 🔧 TROUBLESHOOTING

<a name="top"></a>

**What each message from the suite means, and the one thing to do about it.**

_Read the message first. It usually names the fix._

</div>

---

## 🚪 Locked Out, Or Stuck

A plain prompt in this window, now, whatever the switch says:

```zsh
ALIEN_NO_TERMINAL=1 zsh
```

Then `zsh scripts/bootstrap.zsh --hook off` keeps the cabinet out of new
windows with nothing uninstalled, and `--remove` takes the hook out entirely.
The [README](../../README.md#-ways-out) lists every way out. A shell in tmux,
over ssh, or in VS Code's terminal never opens the cabinet either, so any of
those still reaches a prompt.

Inside the cabinet, **[Q]** then **[Y]** powers off from any page.
<kbd>Ctrl</kbd> <kbd>Z</kbd> is refused on purpose: the cabinet cannot
promise to restore the terminal on the way back.

---

## 🐚 A New Window Is A Plain Prompt

Start with `zsh scripts/bootstrap.zsh --status`, which changes nothing:

| It says                                              | Why                                                   | Do                                               |
| :--------------------------------------------------- | :---------------------------------------------------- | :----------------------------------------------- |
| `the switch is off`                                  | `terminal.hook` in `terminal.conf` does not read `on` | `zsh scripts/bootstrap.zsh --hook on`            |
| `no block in ~/.zshrc`                               | The block was never written, or was taken out         | `zsh scripts/bootstrap.zsh --install`            |
| `~/<leaf> is not there`                              | The link was never made, or was removed               | `--install`                                      |
| `~/<leaf> links here, but nothing is at the far end` | The file it points at is gone from the clone          | Restore it in the clone; the link works again    |
| `~/<leaf> is a link somewhere else`                  | Another clone, or other dotfiles, own that path       | `--install` from this clone replaces the link    |
| `~/<leaf> is a real file, not a link`                | A file of your own is in the way                      | `--install` moves it aside to `<leaf>.pre-alien` |

**When every line is good** and a new window still opens no cabinet, the
shell is one the hook stands aside in:

- tmux, screen, ssh, or the terminal inside VS Code, Warp or Hyper;
- `ALIEN_NO_TERMINAL` or `ALIEN_NO_DOOR` exported by something your shell
  sources, or `TERM` set to `dumb`;
- `XDG_CONFIG_HOME` pointing somewhere other than `~/.config`, where the block
  looks for `conf.d` and finds none of the links;
- a `.zshrc` that is not the one the installer wrote to: it writes
  `${ZDOTDIR:-$HOME}/.zshrc`, so run it with the same `ZDOTDIR` your new
  windows have.

`alien` at a prompt opens the cabinet whatever the switch says, which tells a
switch or a guard apart from a broken door. The hook's whole list, in order,
is in [Shell Hook & Installer](../technical/Shell-Hook-&-Installer.md).

---

## 📺 The Cabinet

| You see                                                                    | Why                                                                                            | Do                                                                                        |
| :------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------- |
| `the terminal needs a bigger window`, with `have` and `need` sizes         | The window is under 122 x 43 cells                                                             | Resize it, or <kbd>⌘</kbd> <kbd>-</kbd> to shrink the font                                |
| `alien: no terminal.command above` its own path                            | The launcher's link no longer leads into a clone                                               | `--install` from the clone                                                                |
| A double-click that macOS refuses to open                                  | A `terminal.command` from a downloaded zip carries the quarantine flag                         | `zsh terminal.command`, or clone with git                                                 |
| `<MACHINE> · no <name>.zsh in this folder`                                 | That machine's pack is missing from `scripts/suite/`                                           | Restore it, then **[R]** RESCAN                                                           |
| `<MACHINE> ·` and a line of the pack's own, on opening it                  | The pack would not load or start, and the door survived it                                     | Fix the line it names, check it with `zsh -n`, then open it again                         |
| `TERMINAL stopped inside a machine's page pack:`, after the screen cleared | A pack took the whole cabinet down; what it wrote follows                                      | Fix the pack. One that fell while being got ready waits to be opened at the next power-on |
| A machine that opens slowly, as if never got ready                         | It has been on `warm-skip` since it took a power-on down                                       | It comes off when its file changes, or delete `~/.local/state/alien/warm-skip`            |
| `tabs need Terminal.app on a mac`                                          | Tabs need Apple's Terminal and `osascript`                                                     | Run the cabinet in Terminal                                                               |
| `let Terminal control Terminal · System Settings › Privacy › Automation`   | macOS has not let Terminal script itself                                                       | Allow it in that pane                                                                     |
| A tab that opens as a new window                                           | A tab needs <kbd>⌘</kbd> <kbd>T</kbd> pressed through System Events, which needs Accessibility | Allow Accessibility for Terminal, or keep the window                                      |
| `run <command> in a terminal`, for a runner                                | INTELLIGENCE could not open a tab here                                                         | Run that line yourself                                                                    |
| `he can't talk yet` or `he can't talk right now`, from the visitor         | No local runner holds a model, or none is running                                              | Install or start one on INTELLIGENCE's LOCAL page                                         |
| `the router is not running · start litellm on :4000`                       | ROUTE's LiteLLM proxy is not up, and nothing here installs it                                  | **[G]** on ROUTE, then start it with the line the page shows                              |

**The glyphs do not line up.** `zsh terminal.command --check` draws every
glyph the cabinet uses with a ruler under each row. A ruler shorter than its
row is a glyph the font draws two cells wide. A ruler longer than its row is
the shell counting bytes, not characters, and the card says
`BYTES · set a UTF-8 locale`: set `LANG` or `LC_ALL` to a UTF-8 locale.

---

## 💾 Your Save And Settings

The self test's READING SAVE AND CONFIG lines say what was found at power-on,
and where.

| You see                                                            | Why                                                                             | Do                                                         |
| :----------------------------------------------------------------- | :------------------------------------------------------------------------------ | :--------------------------------------------------------- |
| `NOT FOUND · LOOKED IN THIS FOLDER AND ~/.local/state/alien`       | There is no save in either place                                                | Copy `terminal.save` beside `terminal.command`             |
| `NEW IN THIS FOLDER · READ AT THE NEXT POWER-ON`                   | A save was copied in while the cabinet was up                                   | Power off and on                                           |
| Older progress than you expected                                   | A save beside `terminal.command` wins over the state folder's                   | Keep one save, in one place                                |
| `CANNOT BE READ`, on the save or the config                        | The file is there and this account cannot read it                               | Fix its permissions                                        |
| `terminal.conf is not writable`, from CONFIG                       | The clone's folder is not writable                                              | Fix the folder; until then a change lasts until you quit   |
| A CONFIG setting back as it was after a power-on                   | The key is written twice: CONFIG rewrites the first, the last one wins          | Delete the extra line                                      |
| `the save could not be read in full · nothing will be written`     | The door reads at most 20,000 lines of the save, and the ARCADE's are past them | Nothing was written; look at the file before anything else |
| `save failed · wrote <n> of <m> lines · the old save is untouched` | The new copy came out short, so it was thrown away                              | Nothing to undo: the ARCADE tries again at its next save   |

`ALIEN_SAVE=<file>` points the cabinet at another save for one run. Test
against a copy, never against your own save.

---

## 🔄 Updates

The self test's ORIGIN line says what this power-on took from the branch's
upstream, and `git -C <clone> pull --ff-only` shows git's own reason for any
line that is not `UPDATED` or `UP TO DATE`.

| The ORIGIN line says                         | Why                                                         | Do                                                           |
| :------------------------------------------- | :---------------------------------------------------------- | :----------------------------------------------------------- |
| `NOT REACHED`                                | No network, or a remote that wanted a password or a key     | Fetch once by hand, so git can ask                           |
| `STILL ASKING`, `TAKEN AT THE NEXT POWER-ON` | The fetch outlasted the two seconds the machines wait       | Nothing: the next power-on takes it                          |
| `GIT WOULD NOT FAST-FORWARD`                 | A local edit the new commits would overwrite                | Commit, stash or drop the edit                               |
| `HAS COMMITS OF ITS OWN`                     | The branch and its upstream have both moved                 | Merge or rebase by hand                                      |
| `NO UPSTREAM BRANCH`                         | A detached HEAD, or a branch that tracks nothing            | `git switch Development`, or `git branch -u origin/<branch>` |
| `NOT THE INSTALLED CLONE`                    | Your home folder links to another clone                     | Nothing: only that one updates itself                        |
| `NO GIT ON THIS MAC`                         | No git, or only the stub that offers the Command Line Tools | `xcode-select --install`                                     |

An update that broke the cabinet comes back out with `update = off` in
`terminal.conf`, then `git -C <clone> reset --keep ORIG_HEAD`.

---

## 🧰 The Tools

| `--status` or `--tools` says           | Why                                                   | Do                                                        |
| :------------------------------------- | :---------------------------------------------------- | :-------------------------------------------------------- |
| `no homebrew`                          | There is no `brew` on `PATH` or in Homebrew's folders | `zsh scripts/bootstrap.zsh --tools`                       |
| `homebrew's installer stopped`         | Homebrew's own installer failed or was cancelled      | Run `--tools` again; nothing after it ran                 |
| `brew bundle stopped`                  | A formula in the Brewfile did not install             | `brew bundle check --file Brewfile`, then `--tools` again |
| `brew services could not start ollama` | The login service would not start                     | `brew services start ollama`, to see Homebrew's reason    |
| `ollama is here`, without `and up`     | ollama is installed and not answering on port 11434   | `brew services start ollama`                              |

`--plan` lists the exact lines `--tools` would run, and runs none of them.

---

## 🤖 The Agent Rules

Every message from `make agents` starts with `agents:`:

| Message                                                          | Why                                              | Do                                                            |
| :--------------------------------------------------------------- | :----------------------------------------------- | :------------------------------------------------------------ |
| `no release is pinned in <pin> yet`                              | `agents/intelligence.pin` names no release       | `make agents-pin VERSION=vX.Y.Z`, compare, commit             |
| `curl is not installed`, `python3 is not installed`              | The kit needs both                               | Install it; on a Mac, the Command Line Tools bring `python3`  |
| `could not download release <v>`                                 | The network, or a version the hub never released | Check the tag exists in tannergolden/intelligence             |
| `the home file of <v> does not match its pin`                    | What the release serves is not what was pinned   | Pin again and compare with `make pins VERSION=<v>` in the hub |
| `the installer of <v> does not match its pin, so it was not run` | The same, for the installer                      | The same                                                      |
| `the kit of <v> does not match its pin`                          | The same, for the kit                            | The same                                                      |
| `<v> serves no kit, so only the rules are pinned`                | A release from before the kit                    | Nothing: the rules install alone                              |
| `usage: make agents-pin VERSION=vX.Y.Z`                          | The version did not look like `vX.Y.Z`           | Give it one that does                                         |

On a codespace, `install.sh` adds one line after any of these,
`dotfiles: the agent rules were not installed; run make agents to retry`, and
the codespace starts anyway. Run `make agents` there to see the message again.
The first `codex` session after an install asks you to trust the guard hook,
once: [AI Agent Rules](../technical/AI-Agent-Rules.md) says why.

---

## 🔗 See Also

- [New Machine Setup](../introduction/New-Machine-Setup.md): every step, in
  the order that avoids most of the above
- [Machine Footprint](../references/Machine-Footprint.md): where each file
  named here lives
- [Page Packs](../technical/Page-Packs.md): how the door catches a pack that
  fails

---

<div align="center">

**Every message here names its fix. This page only says where to look.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](../../LICENSE).

</div>
