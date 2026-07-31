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

_A short list, kept short on purpose._

</div>

---

## 🎯 Why This List Exists

Every item here fails one of three tests: it needs a credential no script should hold, it needs a decision no file can make, or it can only be done through a graphical interface that refuses to be scripted. Automating them anyway produces something worse than a manual step, which is a step that **looks** automated and quietly does nothing.

---

## 1️⃣ Register Your Signing Key

Generate the key, then register the **public** half on GitHub.

```bash
ssh-keygen -t ed25519 -C "signing" -f ~/.ssh/id_signing_ed25519
```

> [!CAUTION]
> An authentication key and a signing key are **two separate registrations of the same file**. A key registered only under _Authentication keys_ will sign commits that GitHub then displays as **Unverified**, with no error anywhere to explain it. Add it under _Signing keys_ as well.

Then add the public key to `~/.config/git/allowed_signers`, which chezmoi creates once and never overwrites. Without an entry there, `git log --show-signature` reports `No signature` on correctly signed commits rather than failing, so local verification silently degrades to nothing.

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

## 3️⃣ Windows: Execution Policy

The default execution policy on Windows 10 and 11 clients is `Restricted`, which blocks **all** script files including PowerShell profiles. Your profile will simply never load, silently.

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Per-user, no administrator rights required. Bootstrap reports this rather than changing it, because silently mutating a machine's persistent security policy from a public repository is not a script's decision to make.

---

## 4️⃣ macOS: Terminal Profile

Run `scripts/macos-interactive.sh`, then **quit Terminal completely** and reopen it.

The restart is not superstition. `defaults(1)` warns that modifying the preferences of a running application means it "won't see the change and might even overwrite the default", and Terminal rewrites its own preferences on quit. Since bootstrap is running _inside_ Terminal, the write is racing the process that will overwrite it. If the profile does not stick, that race is why; re-run the script with Terminal closed.

---

## 5️⃣ Windows Terminal: Pick the Scheme Once

The Catppuccin Mocha scheme arrives as a **fragment**, which is the one mechanism the settings UI never rewrites. Fragments can add schemes but cannot select one, so a single manual step remains:

- [ ] Windows Terminal → Settings → your profile → Appearance → Color scheme → **Catppuccin Mocha**

Windows Terminal reads fragments at launch, so restart it first if the scheme is not listed.

---

## 6️⃣ Codespaces

- [ ] Enable **Automatically install dotfiles** in [Codespaces settings](https://github.com/settings/codespaces)
- [ ] Select this repository from the dropdown

Nothing else. Each new codespace clones the repository and runs `install.sh` during creation. If it seems not to have run, check `/workspaces/.codespaces/.persistedshare/EnvironmentLog.txt`.

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
