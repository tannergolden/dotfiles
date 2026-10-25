<!--
title: '🚀 NEW MACHINE SETUP'
description: 'Every step from a fresh Mac or a new codespace to a working cabinet and agent rules, in order: what to carry over first, what each step needs, how to check it, and how to take a machine back. Read it before setting up a machine.'
type: guide
-->

<div align="center">

# 🚀 NEW MACHINE SETUP

<a name="top"></a>

**From a fresh Mac or a new codespace to the suite and the agent rules, in order.**

_Carry two files over, then read what the card found._

</div>

---

## 💡 Two Kinds Of Machine

These dotfiles set up two things, and a machine gets one or both:

| What                      | Installed by                                  | Runs on              |
| :------------------------ | :-------------------------------------------- | :------------------- |
| The ALIEN suite           | `scripts/bootstrap.zsh`, run by hand          | macOS Terminal       |
| The universal agent rules | `make agents`, or `install.sh` on a codespace | A Mac or a codespace |

**A Mac** takes both, by hand, in the order below. **A codespace** takes the
agent rules alone: GitHub Codespaces runs [`install.sh`](../../install.sh) by
itself for a dotfiles repository, and that script installs the rules and
nothing else.

---

## 🚀 On A Mac

- [ ] **Clone the repository.** Any folder works: the links the installer
      makes are the only record of where it is.

  ```zsh
  git clone https://github.com/tannergolden/dotfiles.git ~/dotfiles
  cd ~/dotfiles
  ```

- [ ] **Carry your progress first, if you have any.** Copy `terminal.save`
      and `terminal.conf` from the old Mac into the clone, beside
      `terminal.command`. On the old Mac the save is beside its
      `terminal.command`, or else in `~/.local/state/alien/` (under
      `$XDG_STATE_HOME` when that is set). Copy before the first power-on: a
      save copied in while the cabinet is running is named on the self test
      but read only at the next power-on.
- [ ] **Install the hook.** `--install` links the three files from `home/`,
      writes the block into `~/.zshrc` and turns the switch on, asking
      nothing. With no flag the installer shows its checks and asks first.

  ```zsh
  zsh scripts/bootstrap.zsh --install
  ```

- [ ] **Install the tools.** `--plan` lists the exact lines `--tools` would
      run and runs none of them. `--tools` runs Homebrew's installer when
      there is no `brew`, then the [`Brewfile`](../../Brewfile) when one of
      its tools is missing, then `brew services start ollama`. Homebrew asks
      for your password, so run it where you can answer.

  ```zsh
  zsh scripts/bootstrap.zsh --plan
  zsh scripts/bootstrap.zsh --tools
  ```

- [ ] **Install the agent rules.** `make agents` runs
      `sh agents/home-kit.sh install`, which stops unless `curl` and
      `python3` are both on the machine and
      [`agents/intelligence.pin`](../../agents/intelligence.pin) names a
      release. On a Mac without the Command Line Tools, `/usr/bin/python3` is
      only a stub that offers to download them. A pin with no release in it
      is filled in once, then committed:
      [AI Agent Rules](../technical/AI-Agent-Rules.md) has the steps.

  ```zsh
  make agents
  ```

- [ ] **Open a new Terminal window.** The cabinet powers up and ends on the
      self test card. Its READING SAVE AND CONFIG lines say whether
      `terminal.save` and `terminal.conf` were found, where, and what was in
      them. The window needs at least 122 x 43 cells; a smaller one says
      `the terminal needs a bigger window` and gives both sizes. Resize it, or
      press <kbd>⌘</kbd> <kbd>-</kbd> to shrink the font.
- [ ] **Add the cloud agents you use.** None of the four is in the Brewfile.
      **[I]** on INTELLIGENCE's CLOUD page shows each vendor's own install
      line and runs it on a **[Y]**, and each agent signs in to your own
      account. The KEYS page says which provider variables are set, by their
      length alone.

Some of INTELLIGENCE leans on programs nothing here installs. ROUTE's router
is a LiteLLM proxy: **[G]** on that page writes its config to
`~/.local/state/alien/litellm.yaml`, and the page shows the line that starts
it on port 4000. The LOCAL page names the line that installs each runner it
does not find, and two of them are not in the Brewfile:
`brew install --cask lm-studio` for LM Studio and `uv tool install mlx-lm` for
MLX.

> [!IMPORTANT]
> **Keep every key out of the clone.** The files under `home/` are tracked
> and public, and `.gitignore` keeps out only the files it knows by name. An
> `export` of a key in a tracked file is caught by the secret scan after it
> has been pushed. Set keys in a file outside the clone, such as your own
> `~/.zshrc` outside the marked block: the installer never writes outside its
> marks.

---

## ✅ Checking The Machine

Each of these reads and changes nothing:

```zsh
zsh scripts/bootstrap.zsh --status   # links, the block, the switch and the tools
brew bundle check --file Brewfile    # what the Brewfile names that is missing
make agents-check                    # each installed copy of the rules, against the pin
zsh terminal.command --probe         # what the cabinet finds, as text, then exit
```

The probe's `mirror` line counts the files under `home/` that resolve back
into the clone, and its `installed` line reads `yes`, or `no` with the first
thing short, such as `2 of 3 linked`.

---

## 🌿 In A Codespace

[`install.sh`](../../install.sh) changes into its own folder and runs
`sh agents/home-kit.sh install`. Whatever happens, it exits 0, so a missing
tool or an unreachable release never stops the codespace from starting. When
the rules did not go in, it prints one line on the way:

```text
dotfiles: the agent rules were not installed; run make agents to retry
```

Run `make agents` from the dotfiles clone to see why. Its messages, and what
each one means, are in [Troubleshooting](../operations/Troubleshooting.md).

---

## 📦 What Stays With Each Machine

Git carries none of what makes a machine its own: not `terminal.conf` and
`terminal.save`, which `.gitignore` keeps out, and not what the installer and
the machines write outside the clone: the links, the `~/.zshrc` block and its
`.zshrc.pre-alien` copy, the state folder, Homebrew and its login service for
ollama, and the agent rules in each app's home folder.
[Machine Footprint](../references/Machine-Footprint.md) lists every file and
folder, who writes it, and how it comes off again.

**Moving the clone** leaves the three links pointing at nothing. That fails
safe: the hook opens nothing, and `alien` says it cannot find the door. Run
`--install` again from the new folder.

---

## 🚪 Taking A Machine Back

**[U] UNINSTALL** on the cabinet's menu takes back everything the suite put
on the Mac. It copies `terminal.save` and `terminal.conf` to a new folder in
`~/Downloads`, powers the cabinet off, and then removes the hook and what it
left, the state folder, ollama's login service and the Brewfile's tools, the
agent rules, and last the clone. From a prompt in the clone:

```zsh
zsh scripts/bootstrap.zsh --uninstall --plan   # what would go, with nothing changed
zsh scripts/bootstrap.zsh --uninstall          # all of it, this clone last
```

Homebrew itself stays, and so do the cloud agents and the models. Take those
off first, with **[U]** on INTELLIGENCE's CLOUD and LOCAL pages, while the
cabinet and ollama are still here. `--remove` takes out the hook alone and
leaves the rest.

---

## 🔗 See Also

- [README: Install](../../README.md#-install): every flag the installer takes
- [AI Agent Rules](../technical/AI-Agent-Rules.md): the pin, and moving to a
  new release
- [Shell Hook & Installer](../technical/Shell-Hook-&-Installer.md): what the
  installer changes, and why the hook stands aside
- [Troubleshooting](../operations/Troubleshooting.md): when a step above does
  not do what it says

---

<div align="center">

**One clone, two kits, and a card that says what it found.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](/LICENSE).

</div>
