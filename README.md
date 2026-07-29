<!--
title: '&#x1F680; DOTFILES'
description: 'My machine configuration, versioned and symlinked by a bootstrap script.'
tags: [macos, configuration, developer-experience, environment-setup]
category: root
-->

<!-- markdownlint-disable MD041 -->
<div align="center">

# &#x1F680; DOTFILES

<a name="top"></a>

**My machine configuration, versioned and symlinked by a bootstrap script.**

_A fresh machine reaches a working setup in one command._

<a href="./"><img src="https://img.shields.io/badge/Status-Active-2EA043?style=for-the-badge&logoColor=white" alt="Status: Active" /></a>
<a href="./"><img src="https://img.shields.io/badge/Role-Configuration-FE5196?style=for-the-badge&logoColor=white" alt="Role: Configuration" /></a>
<a href="./"><img src="https://img.shields.io/badge/Context-Environment-9C27B0?style=for-the-badge&logoColor=white" alt="Context: Environment" /></a>
<a href="./LICENSE"><img src="https://img.shields.io/badge/License-MIT-F1E05A?style=for-the-badge&logoColor=white" alt="License: MIT" /></a>

</div>

---

## &#x1F4A1; About

Dotfiles are hidden configuration files (files beginning with a dot, like `.zshrc` or `.gitconfig`) that customize how a Unix-based system behaves. This repository centralizes those files so they can be tracked, versioned, and backed up in Git.

Instead of manually configuring a new macOS environment from scratch, this repository uses a bootstrap script to automatically symlink these configurations into place. This ensures that shell setups, editor preferences, and git settings are predictable, consistent, and immediately productive on any new machine.

---

## &#x1F4E6; Structure & Manifest

The repository will be structured to keep configurations isolated by tool, making it easy to track changes and remove deprecated tools.

```bash
.
├── bin/                   # &#x1F4E6; Custom executables and scripts
├── config/                # &#x2699;&#xFE0F; Tool-specific configurations (e.g., git, zsh)
├── macOS/                 # &#x2699;&#xFE0F; macOS defaults and system preferences
├── bootstrap.sh           # &#x1F680; Deployment script
└── README.md              # &#x1F4DD; Documentation
```

---

## &#x1F680; Quick Start

> [!IMPORTANT]
> Review the scripts before executing them on a new machine to ensure compatibility with your environment.

### 1. Pre-requisites

Ensure that `git` is installed on the target machine. On a fresh macOS install, running `git` in the terminal will prompt you to install the Xcode Command Line Tools.

### 2. Installation

- [ ] Clone the repository
- [ ] Navigate to the directory
- [ ] Run the bootstrap script

```bash
# Clone the repository
git clone https://github.com/tannergolden/dotfiles ~/.dotfiles

# Navigate to the directory
cd ~/.dotfiles

# Run the bootstrap script
./bootstrap.sh
```

---

<div align="center">

**Read it, copy what is useful, ignore the rest.**

[↑ Back to Top](#top)

<br />

Built with &#x2764;&#xFE0F; by [@tannergolden](https://github.com/tannergolden).

</div>
