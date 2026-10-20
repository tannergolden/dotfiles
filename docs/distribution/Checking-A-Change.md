<!--
title: '🧪 CHECKING A CHANGE'
description: 'What 🚦 Checks runs on every pull request here, why none of it runs zsh, and the checks a change to the suite, the hook, the installer or the agent kit needs on a Mac before it is pushed. Read it before pushing any change to these dotfiles.'
type: guide
keywords: [ci, tests, zsh, probe, fixtures, pull request, validation]
-->

<div align="center">

# 🧪 CHECKING A CHANGE

<a name="top"></a>

**What CI proves on every pull request, and what only a Mac with zsh can prove.**

_CI reads the Python. You run the zsh._

</div>

---

## 💡 What CI Checks Here

[`checks.yml`](../../.github/workflows/checks.yml) runs the standards' shared
checks with this repository's own commands:

| Job       | What it runs here                                                                                                                                                                                   |
| :-------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ci`      | `validate-repository.py` as the linter, the tests in `.github/scripts/` and `agents/`, the frontmatter check set to `enforce`, spelling with [`_typos.toml`](../../_typos.toml), and the link check |
| `secrets` | The gitleaks secret scan                                                                                                                                                                            |
| `codeql`  | CodeQL's analysis                                                                                                                                                                                   |
| `lint`    | actionlint and zizmor over the workflows                                                                                                                                                            |

**None of it runs zsh.** The validator holds every tracked file, the zsh ones
included, to LF line endings, a final newline and no trailing whitespace, and
the secret scan reads them, but nothing parses or runs them: whether the
suite, the installer and the hook still work is checked by the person who
changed them. The spell check leaves out `terminal.command` and
`scripts/suite/*.zsh` as well, so the comments in those five files go unread.
`_typos.toml` says why: their short names and encoded sprites read as about
1,400 misspellings, none of them real.

---

## 🚀 Before You Push

From the root of the clone, on a Mac with zsh, by what you changed:

| You changed                    | Run                                                                                                   |
| :----------------------------- | :---------------------------------------------------------------------------------------------------- |
| Any zsh file                   | `zsh -n` on it; the README's loop covers every one                                                    |
| SYSTEM, or its fixture         | `SYSTEM_MOCK=1 zsh scripts/suite/system.zsh --probe \| diff - scripts/fixtures/system/probe.expected` |
| The door, or any pack          | `TERMINAL_MOCK=1 zsh terminal.command --probe`, then open the machine in a real window                |
| The installer                  | `zsh scripts/bootstrap.zsh --status` and `--plan`, which change nothing                               |
| The hook, or a file in `home/` | `zsh -n`, a new window, then `--status`                                                               |
| `agents/`                      | `python3 -m unittest discover -s agents -p 'test_*.py'`                                               |
| Anything                       | The validator and the tests in `.github/scripts/`, as below                                           |

```zsh
python3 .github/scripts/validate-repository.py
python3 -m unittest discover -s .github/scripts -p 'test_*.py'
```

The three zsh checks the [README](../../README.md#-testing) gives read none of
the real machine. The agent kit's tests run the real `home-kit.sh` against a
release served from a temporary folder, and touch neither the network, your
home folder nor the real pin file.

---

## 📦 When probe.expected Has To Change

`scripts/fixtures/system/probe.expected` is every reading SYSTEM takes from
moonbase, the invented Mac, flat and sorted. The diff above prints nothing
while all 1,108 lines match.

**A number changed in the fixture** changes the file on purpose. Write it
again from the probe, and commit both in the same change:

```zsh
SYSTEM_MOCK=1 zsh scripts/suite/system.zsh --probe > scripts/fixtures/system/probe.expected
```

**A diff after a change to SYSTEM itself** is what the file is for. It is the
output of the Python monitor SYSTEM was ported from, kept after that program
was retired, so a line that moves is a reading that no longer matches the
original. Find out why before writing the file again.

---

## 🛡️ Testing Without Touching Your Own

- **`TERMINAL_MOCK=1`** reads an invented machine, and the installer's pages
  on the glass run `--report` and nothing else: they say nothing was touched.
  `ALIEN_MIRROR=0/3` beside it shows the menu a fresh Mac gets, with INSTALL
  standing.
- **`ALIEN_SAVE=<file>`** points the cabinet at a copy of a save. Never test
  against your own, and never change an animal somebody already owns.
- **`ALIEN_AT=<seconds>`** stops the animation clock at that instant, so
  `TERMINAL_MOCK=1 ALIEN_AT=8 zsh terminal.command --once` paints the same
  frame on any machine. A window under 122 x 43 cells gets a line saying so
  instead of a frame.
- **`--install` is never a test.** It writes your real home folder and the
  switch in this clone's `terminal.conf`.

---

## 🌿 How It Lands

Work reaches `Development` through pull requests, squash-merged, so each pull
request's title becomes one Conventional Commit, and ⚖️ Governance holds the
title to that. Branching, commits and reviews are written down once, in the
standards'
[Distribution & Workflow](https://github.com/tannergolden/standards/blob/Development/docs/distribution/README.md).
After the merge, 🗂️ Machined Indexes redraws every folder log and proposes the
change as a pull request of its own.

---

## 🔗 See Also

- [README: Testing](../../README.md#-testing): the launch flags and the test
  seams
- [Page Packs](../technical/Page-Packs.md): the rules a pack keeps, which no
  check enforces
- [Shell Hook & Installer](../technical/Shell-Hook-&-Installer.md): the
  promises the installer keeps to the door

---

<div align="center">

**Green in CI is half the answer. The other half runs on a Mac.**

[↑ Back to Top](#top)

<br />

Built with ❤️ by the Engineering Team. Distributed under the terms in [LICENSE](../../LICENSE).

</div>
