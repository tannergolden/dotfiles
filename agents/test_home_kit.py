#!/usr/bin/env python3
"""Tests for the agent home kit.

WHY THIS EXISTS. `home-kit.sh` downloads code from the network and runs it,
so its one promise matters more than anything else it does: the installer
runs only when every downloaded file matches the pins committed here, the
kit included when one is pinned. These
run the real script against a stand-in for a release, served from a local
folder, with a stub in place of the installer that records how it was
called. They also hold `install.sh` to never failing a new codespace.

Nothing here touches the network, your home folder, or the real pin file.

Run it:

    python3 agents/test_home_kit.py
"""

from __future__ import annotations

import hashlib
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
KIT = HERE / 'home-kit.sh'
INSTALL_SH = HERE.parent / 'install.sh'

HOME_FILE = '<!-- INTELLIGENCE:BEGIN sha256:{} -->\n\n## Working rules\n\n- SEC-001: Never.\n\n<!-- INTELLIGENCE:END -->\n'
KIT_JSON = b'{"format": 1}\n'
STUB = (
    'import os, pathlib, sys\n'
    "pathlib.Path(os.environ['STUB_LOG']).write_text(' '.join(sys.argv[1:]))\n"
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class HomeKit(unittest.TestCase):
    """A copy of the kit beside its own pin file, and a fake release."""

    version = 'v1.2.3'

    def setUp(self) -> None:
        self.root = pathlib.Path(tempfile.mkdtemp(prefix='home-kit-test-'))
        self.kit_dir = self.root / 'dotfiles' / 'agents'
        self.kit_dir.mkdir(parents=True)
        shutil.copy(KIT, self.kit_dir / 'home-kit.sh')
        shutil.copy(INSTALL_SH, self.root / 'dotfiles' / 'install.sh')
        self.pin = self.kit_dir / 'intelligence.pin'
        self.pin.write_text('version=\nhome_sha256=\ninstall_sha256=\n', encoding='utf-8')
        self.home_bytes = HOME_FILE.format('0' * 64).encode()
        release = self.root / 'release' / self.version
        (release / 'home').mkdir(parents=True)
        (release / 'scripts').mkdir()
        (release / 'home' / 'intelligence.md').write_bytes(self.home_bytes)
        (release / 'home' / 'kit.json').write_bytes(KIT_JSON)
        (release / 'scripts' / 'install.py').write_text(STUB, encoding='utf-8')
        self.release = release
        self.log = self.root / 'stub.log'

    def tearDown(self) -> None:
        shutil.rmtree(self.root, ignore_errors=True)

    def pin_release(self, home: str | None = None, install: str | None = None, kit: str | None = '') -> None:
        """Pin the fake release; `kit=None` pins its kit's real hash, '' pins no kit."""
        self.pin.write_text(
            f'version={self.version}\n'
            f'home_sha256={home or sha256(self.home_bytes)}\n'
            f'install_sha256={install or sha256(STUB.encode())}\n'
            f'kit_sha256={sha256(KIT_JSON) if kit is None else kit}\n', encoding='utf-8')

    def run_kit(self, *args: str, script: pathlib.Path | None = None) -> subprocess.CompletedProcess[str]:
        env = dict(os.environ, HOME=str(self.root / 'home'), STUB_LOG=str(self.log),
                   INTELLIGENCE_BASE=(self.root / 'release').as_uri())
        (self.root / 'home').mkdir(exist_ok=True)
        return subprocess.run(['sh', str(script or self.kit_dir / 'home-kit.sh'), *args], env=env,
                              capture_output=True, text=True, timeout=120, check=False)

    def called(self) -> str | None:
        return self.log.read_text(encoding='utf-8') if self.log.exists() else None


class TestInstall(HomeKit):
    """The installer runs only on a pinned, matching release."""

    def test_a_matching_release_is_installed(self) -> None:
        self.pin_release()
        done = self.run_kit('install')
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertRegex(self.called() or '', r'^install --home-file .*/intelligence\.md$')

    def test_a_pinned_kit_reaches_the_installer(self) -> None:
        self.pin_release(kit=None)
        for command in ('install', 'check'):
            with self.subTest(command=command):
                done = self.run_kit(command)
                self.assertEqual(done.returncode, 0, done.stderr)
                self.assertRegex(self.called() or '', rf'^{command} --home-file .*/intelligence\.md --kit-file .*/kit\.json$')

    def test_a_kit_that_misses_its_pin_stops_everything(self) -> None:
        self.pin_release(kit='0' * 64)
        done = self.run_kit('install')
        self.assertEqual(done.returncode, 1)
        self.assertIn('the kit', done.stderr)
        self.assertIsNone(self.called())

    def test_check_and_uninstall_reach_the_installer(self) -> None:
        self.pin_release()
        self.run_kit('check')
        self.assertTrue((self.called() or '').startswith('check --home-file'))
        self.run_kit('uninstall')
        self.assertEqual(self.called(), 'uninstall')

    def test_nothing_pinned_means_nothing_runs(self) -> None:
        done = self.run_kit('install')
        self.assertEqual(done.returncode, 1)
        self.assertIn('no release is pinned', done.stderr)
        self.assertIsNone(self.called())

    def test_a_home_file_that_misses_its_pin_stops_everything(self) -> None:
        self.pin_release(home='0' * 64)
        done = self.run_kit('install')
        self.assertEqual(done.returncode, 1)
        self.assertIn('home file', done.stderr)
        self.assertIsNone(self.called())

    def test_an_installer_that_misses_its_pin_never_runs(self) -> None:
        self.pin_release(install='0' * 64)
        for command in ('install', 'uninstall'):
            with self.subTest(command=command):
                done = self.run_kit(command)
                self.assertEqual(done.returncode, 1)
                self.assertIn('was not run', done.stderr)
                self.assertIsNone(self.called())

    def test_a_release_that_cannot_be_downloaded_fails_cleanly(self) -> None:
        self.pin_release()
        self.pin.write_text(self.pin.read_text(encoding='utf-8').replace(self.version, 'v0.0.0'),
                            encoding='utf-8')
        done = self.run_kit('install')
        self.assertEqual(done.returncode, 1)
        self.assertIn('could not download', done.stderr)


class TestPin(HomeKit):
    """`pin` records the hashes of what a release serves."""

    def test_pinning_records_every_hash(self) -> None:
        done = self.run_kit('pin', self.version)
        self.assertEqual(done.returncode, 0, done.stderr)
        pin = self.pin.read_text(encoding='utf-8')
        self.assertIn(f'version={self.version}\n', pin)
        self.assertIn(f'home_sha256={sha256(self.home_bytes)}\n', pin)
        self.assertIn(f'install_sha256={sha256(STUB.encode())}\n', pin)
        self.assertIn(f'kit_sha256={sha256(KIT_JSON)}\n', pin)
        self.assertEqual(self.run_kit('install').returncode, 0)
        self.assertIn('--kit-file', self.called() or '')

    def test_a_release_from_before_the_kit_pins_the_rules_alone(self) -> None:
        (self.release / 'home' / 'kit.json').unlink()
        done = self.run_kit('pin', self.version)
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertIn('serves no kit', done.stderr)
        self.assertIn('kit_sha256=\n', self.pin.read_text(encoding='utf-8'))
        self.assertEqual(self.run_kit('install').returncode, 0)
        self.assertNotIn('--kit-file', self.called() or '')

    def test_a_version_must_look_like_one(self) -> None:
        done = self.run_kit('pin', 'latest')
        self.assertEqual(done.returncode, 2)
        self.assertIn('usage', done.stderr)
        self.assertNotIn('latest', self.pin.read_text(encoding='utf-8'))


class TestInstallScript(HomeKit):
    """`install.sh` never fails a new codespace."""

    def test_a_failing_kit_still_exits_zero(self) -> None:
        done = self.run_kit(script=self.root / 'dotfiles' / 'install.sh')
        self.assertEqual(done.returncode, 0)
        self.assertIn('run make agents to retry', done.stderr)

    def test_a_working_kit_installs(self) -> None:
        self.pin_release()
        done = self.run_kit(script=self.root / 'dotfiles' / 'install.sh')
        self.assertEqual(done.returncode, 0, done.stderr)
        self.assertTrue((self.called() or '').startswith('install --home-file'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
