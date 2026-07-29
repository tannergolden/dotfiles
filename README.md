<!--
title: '🚀 DOTFILES'
description: 'My machine configuration, versioned and symlinked by a bootstrap script.'
tags: [macos, configuration, developer-experience, environment-setup]
category: root
-->

<!-- markdownlint-disable MD041 -->
<div align="center">

# 🚀 DOTFILES

<a name="top"></a>

**My machine configuration, versioned.**

_A fresh machine reaches a working setup in one command._

<a href="./"><img src="https://img.shields.io/badge/Status-Active-2EA043?style=for-the-badge&logoColor=white" alt="Status: Active" /></a>
<a href="./"><img src="https://img.shields.io/badge/Role-Configuration-FE5196?style=for-the-badge&logoColor=white" alt="Role: Configuration" /></a>
<a href="./"><img src="https://img.shields.io/badge/Context-Environment-9C27B0?style=for-the-badge&logoColor=white" alt="Context: Environment" /></a>

</div>

---

## 💡 About

Dotfiles are hidden configuration files (files beginning with a dot, like `.zshrc` or `.gitconfig`) that customize how a Unix-based system behaves. This repository centralizes those files so they can be tracked, versioned, and backed up in Git.

Instead of manually configuring a new macOS environment from scratch, this repository uses a bootstrap script to automatically symlink these configurations into place. This ensures that shell setups, editor preferences, and git settings are predictable, consistent, and immediately productive on any new machine.

---

## 🚀 Quick Start

> [!IMPORTANT]
> Review the scripts before executing them on a new machine.

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

Built with ❤️ by [@tannergolden](https://github.com/tannergolden).

</div>
