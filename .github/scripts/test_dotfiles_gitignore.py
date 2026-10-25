#!/usr/bin/env python3
"""Tests for the dotfiles rules in this repository's .gitignore.

WHY THIS EXISTS. This repository is public, and it holds a home directory's
configuration: the one place a machine keeps its private keys, its tokens
and a record of everything typed into a shell. The rules at the end of
.gitignore keep those out, and an ignore rule fails silently in both
directions. Too narrow, and a key is pushed to the world. Too broad, and a
config file is simply not there, with no warning from `git add`.

So every rule is held to both halves: what it must catch, and the file
beside it that it must leave alone. Each path is checked at the top of the
tree and nested under home/, because the rules must hold wherever a file
lands, and each check runs the real .gitignore through `git check-ignore`,
the only authority on what git will do.

Run it:

    python3 .github/scripts/test_dotfiles_gitignore.py
"""

from __future__ import annotations

import pathlib
import shutil
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
GITIGNORE = ROOT / '.gitignore'


class DotfilesIgnoreTestCase(unittest.TestCase):
    """A throwaway repository carrying nothing but the real .gitignore."""

    @classmethod
    def setUpClass(cls) -> None:
        cls.root = pathlib.Path(tempfile.mkdtemp(prefix='dotfiles-ignore-test-'))
        subprocess.run(['git', 'init', '-q', '.'], cwd=cls.root, check=True)
        shutil.copy(GITIGNORE, cls.root / '.gitignore')

    @classmethod
    def tearDownClass(cls) -> None:
        shutil.rmtree(cls.root, ignore_errors=True)

    def ignored(self, path: str) -> bool:
        return subprocess.run(
            ['git', 'check-ignore', '-q', '--no-index', path],
            cwd=self.root, capture_output=True,
        ).returncode == 0

    def assertIgnored(self, *paths: str) -> None:
        for p in paths:
            for where in (p, f'home/{p}'):
                self.assertTrue(
                    self.ignored(where),
                    f'{where} is tracked, so `git add` would publish it',
                )

    def assertTracked(self, *paths: str) -> None:
        for p in paths:
            for where in (p, f'home/{p}'):
                self.assertFalse(
                    self.ignored(where),
                    f'{where} is IGNORED - `git add` would silently drop it',
                )


class TestSshAndGnupg(DotfilesIgnoreTestCase):
    """Everything in the folder stays out but its configuration."""

    def test_private_keys_are_ignored_under_any_name(self) -> None:
        self.assertIgnored(
            '.ssh/id_rsa',
            '.ssh/id_ed25519',
            '.ssh/github',               # a key named for its host
            '.ssh/work_key.pub',         # public halves too: machine-local
            '.ssh/known_hosts',
            '.ssh/authorized_keys',
            '.ssh/sockets/git@github.com:22',
        )

    def test_the_client_configuration_is_tracked(self) -> None:
        self.assertTracked('.ssh/config', '.ssh/config.d/work')

    def test_the_keyrings_and_agent_are_ignored(self) -> None:
        self.assertIgnored(
            '.gnupg/private-keys-v1.d/0123ABCD.key',
            '.gnupg/pubring.kbx',
            '.gnupg/trustdb.gpg',
            '.gnupg/S.gpg-agent',
            '.gnupg/sshcontrol',
        )

    def test_the_gnupg_configuration_is_tracked(self) -> None:
        self.assertTracked('.gnupg/gpg.conf', '.gnupg/gpg-agent.conf')


class TestCredentialFiles(DotfilesIgnoreTestCase):
    """A file that holds a token or a password in plain text."""

    def test_credential_stores_are_ignored(self) -> None:
        self.assertIgnored(
            '.netrc',
            '.git-credentials',
            '.config/git/credentials',
            '.gem/credentials',
            '.cargo/credentials',
            '.cargo/credentials.toml',
            '.terraform.d/credentials.tfrc.json',
            '.pypirc',
            '.vault-token',
            '.config/gh/hosts.yml',
            '.docker/config.json',
            'certs/me.p12',
            'certs/me.pfx',
        )

    def test_the_settings_beside_them_are_tracked(self) -> None:
        self.assertTracked(
            '.gitconfig',
            '.config/git/config',
            '.config/git/ignore',
            '.config/gh/config.yml',
            '.cargo/config.toml',
            '.docker/daemon.json',
            '.npmrc',                    # tokens in it are the scan's job
        )


class TestToolFoldersWithTokens(DotfilesIgnoreTestCase):
    """Tools that keep tokens and account details beside their settings."""

    def test_the_whole_folder_is_ignored(self) -> None:
        self.assertIgnored(
            '.aws/credentials',
            '.aws/config',
            '.aws/sso/cache/token.json',
            '.azure/msal_token_cache.json',
            '.kube/config',
            '.config/gcloud/application_default_credentials.json',
            '.config/gcloud/configurations/config_default',
            '.config/github-copilot/hosts.json',
            '.config/configstore/firebase-tools.json',
        )

    def test_other_config_folders_are_not(self) -> None:
        self.assertTracked(
            '.config/nvim/init.lua',
            '.config/kitty/kitty.conf',
            '.config/starship.toml',
        )


class TestHistoryAndState(DotfilesIgnoreTestCase):
    """Everything typed, and the state XDG says is never portable."""

    def test_shell_and_repl_history_is_ignored(self) -> None:
        self.assertIgnored(
            '.bash_history',
            '.zsh_history',
            '.zhistory',
            '.histfile',
            '.python_history',
            '.node_repl_history',
            '.psql_history',
            '.local/share/fish/fish_history',
            '.lesshst',
            '.viminfo',
            '.wget-hsts',
            '.zsh_sessions/0F1E2D3C.session',
            '.bash_sessions/0F1E2D3C.session',
            '.local/state/nvim/shada/main.shada',
            '.local/state/nvim/undo/%home%me%.zshrc',
        )

    def test_the_rc_files_beside_it_are_tracked(self) -> None:
        self.assertTracked(
            '.bashrc',
            '.zshrc',
            '.zprofile',
            '.config/fish/config.fish',
            '.vimrc',
            '.local/share/applications/editor.desktop',
        )


class TestLocalOverrides(DotfilesIgnoreTestCase):
    """One machine's settings, sourced by a tracked file and never committed."""

    def test_local_overrides_are_ignored(self) -> None:
        self.assertIgnored('.zshrc.local', '.gitconfig.local', '.config/fish/conf.d/x.local')

    def test_the_xdg_local_folder_is_not_swallowed(self) -> None:
        # `*.local` would match `.local` itself, since `*` matches nothing,
        # and take ~/.local/bin and ~/.local/share down with it.
        self.assertTracked('.local/bin/backup', '.local/share/fonts/Mono.ttf')


class TestMachineWrittenZshFiles(DotfilesIgnoreTestCase):
    """The completion dump and compiled files zsh writes for itself."""

    def test_they_are_ignored(self) -> None:
        self.assertIgnored('.zcompdump', '.zcompdump-host-5.9', '.zshrc.zwc')


class TestNoTrackedFileIsIgnored(unittest.TestCase):
    """Every file this repository tracks is one its ignore rules let in.

    A rule that matches a tracked file changes nothing today, because git
    goes on tracking what it already tracks, and that is the danger: the
    file is dropped without a word the next time it is moved, or deleted
    and added again. A file that must be tracked against a rule gets a
    negation, which records the exception, not a `git add -f`, which hides
    it. Only the repository's own .gitignore files count, so a global
    ignore on the machine running this cannot change the answer.
    """

    def test_every_tracked_file_passes_the_ignore_rules(self) -> None:
        listed = subprocess.run(
            ['git', 'ls-files', '--cached', '--ignored',
             '--exclude-per-directory=.gitignore', '-z'],
            cwd=ROOT, capture_output=True, text=True, check=True,
        ).stdout
        offenders = [p for p in listed.split('\0') if p]
        self.assertEqual(offenders, [], 'tracked but ignored: ' + ', '.join(offenders))


if __name__ == '__main__':
    unittest.main(verbosity=2)
