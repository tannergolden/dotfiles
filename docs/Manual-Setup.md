<!--
title: '🙋 MANUAL SETUP'
description: 'The short list of steps no script can take for you, and why each one resists automation.'
tags: [onboarding, manual, security, setup]
category: docs
-->

<!-- markdownlint-disable MD041 -->
<div align="center">

# 🙋 MANUAL SETUP

<a name="top"></a>

**Everything bootstrap deliberately leaves to a person, and the reason for each.**

_A short list, kept short on purpose — and shorter than it used to be._

</div>

---

## 🎯 Why This List Exists

Every item here fails one of two tests: it needs a **credential** no fresh machine holds, or it needs a **decision** no file can make. Automating those anyway produces something worse than a manual step, which is a step that **looks** automated and quietly does nothing.

Everything else is automated. Bootstrap generates the SSH keys and adds the signing key to the local trust list, imports the Terminal.app profile and applies the macOS defaults, sets the per-user Windows execution policy, selects the Windows Terminal colour scheme, and installs Homebrew, scoop and PowerShell 7 when the machine lacks them. None of those appear below any more, because none of them need you.

---

## 1️⃣ Tell GitHub About This Machine's Keys

Bootstrap generated the keypairs; registering the **public** halves needs your GitHub credential, which is exactly the thing a script from a public repository must never hold. Two ways, pick one:

**Sign in once, then let bootstrap do it** — it registers both keys on any run where `gh` is authenticated:

```bash
gh auth login
~/.dotfiles/scripts/bootstrap.sh
```

**Or paste them yourself** at [github.com/settings/keys](https://github.com/settings/keys):

- [ ] `~/.ssh/id_auth_ed25519.pub` under **Authentication keys**
- [ ] `~/.ssh/id_signing_ed25519.pub` under **Signing keys**

> [!CAUTION]
> Authentication and signing are **two separate registrations**. A key registered only under _Authentication keys_ will sign commits that GitHub then displays as **Unverified**, with no error anywhere to explain it.

> [!NOTE]
> The generated keys carry no passphrase — that is the price of an install that asks nothing, stated rather than hidden. They never leave the machine, and FileVault or BitLocker (below) is the disk-level control. Want passphrased keys instead? Generate them under the same filenames and re-run bootstrap; it only ever fills absence, never replaces what you made.

---

## 2️⃣ Security Settings, On Purpose Not Scripted

None of these are in a `defaults write` script, and that is a deliberate refusal rather than an omission.

| Setting             | Do it here                                             |
| :------------------ | :----------------------------------------------------- |
| Firewall            | System Settings → Network → Firewall                   |
| FileVault           | System Settings → Privacy & Security → FileVault       |
| Screen lock delay   | System Settings → Lock Screen                          |
| Touch ID for `sudo` | Uncomment the relevant line in `/etc/pam.d/sudo_local` |

> [!WARNING]
> The `defaults` domain for the macOS application firewall **no longer exists** as of Sequoia. A script that writes it exits 0 and does nothing. A security setting that silently fails is strictly worse than no setting at all, because you believe you have it.

---

## 3️⃣ Codespaces

- [ ] Enable **Automatically install dotfiles** in [Codespaces settings](https://github.com/settings/codespaces)
- [ ] Select this repository from the dropdown

A settings toggle on github.com is a credentialed decision about your account, which is why it cannot be a script here. Each new codespace then clones the repository and runs `install.sh` during creation with nothing to do by hand. If it seems not to have run, check `/workspaces/.codespaces/.persistedshare/EnvironmentLog.txt`.

---

## 🚫 What You Never Do By Hand

- **Edit a file in `$HOME` that chezmoi manages.** The next `chezmoi apply` silently reverts it. Edit the source with `chezmoi edit`, or adopt the change with `chezmoi re-add`.
- **Add a secret to this repository**, encrypted or otherwise. It is public, and history is not redactable.
- **Trust `private_` to protect a file.** It applies nothing on Windows, is silently discarded when prefixes are misordered, and is not implied by `encrypted_`.

---

<div align="center">

**Automate what a machine can decide. Write down what it cannot.**

[↑ Back to Top](#top)

</div>
