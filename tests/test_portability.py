#!/usr/bin/env python3
"""No dependencies. Runs only under the restrictive macOS test sandbox.

For real Linux coverage run in an isolated disposable container/VM. The local
suite simulates platform branches; it does not emulate a different kernel.
"""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
ROOT = Path(os.environ['DOTFILES_TEST_ROOT']).resolve()
SHELLS = ['/bin/bash', '/bin/zsh']

class Portability(unittest.TestCase):
    def setUp(self):
        self.work = Path(tempfile.mkdtemp(prefix='case-', dir=ROOT))
        self.home = self.work / 'home with spaces'
        self.home.mkdir()
        self.bin = self.work / 'bin'
        self.bin.mkdir()
        self.env = dict(HOME=str(self.home), ZDOTDIR=str(self.home),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        PATH=f'{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin',
                        TERM='dumb', LANG='C', LC_ALL='C',
                        HISTFILE='/dev/null', HISTSIZE='0', SAVEHIST='0',
                        SCENARIO_OS='Linux', SCENARIO_ARCH='x86_64')
        self.stub('uname', 'case "$1" in -s) echo "$SCENARIO_OS";; -m) echo "$SCENARIO_ARCH";; *) echo "$SCENARIO_OS";; esac')
        for name in ['.zshrc', '.zshenv', '.profile', '.bashrc', '.bash_profile', '.aliases', '.functions', '.shell-common.sh']:
            src = {'.functions': 'functions', '.shell-common.sh': 'lib/shell.sh'}.get(name, name)
            (self.home / name).symlink_to(REPO / src)
        # A fixture verifies secret sourcing without using any real secret.
        (self.home / '.secret').write_text('export DOTFILES_FIXTURE_SECRET=loaded\n')

    def stub(self, name, body):
        p = self.bin / name
        p.write_text('#!/bin/sh\n' + body + '\n')
        p.chmod(0o755)

    def shell(self, shell, code, check=True, env=None):
        args = [shell, '--noprofile', '--norc', '-c'] if shell.endswith('bash') else [shell, '-f', '-c']
        p = subprocess.run(args + [code], env=env or self.env, cwd=self.work,
                           capture_output=True, text=True, timeout=25)
        if check:
            self.assertEqual(p.returncode, 0, p.stderr)
            self.assertEqual(p.stderr, '', p.stderr)
        return p

    def source(self, shell):
        return '. "$HOME/.bashrc"\n' if shell.endswith('bash') else '. "$HOME/.zshrc"\n'

    def test_sandbox_blocks_real_home_network_and_external_writes(self):
        p = self.shell('/bin/bash', 'cat /Users/vitalii/.secret', check=False)
        self.assertNotEqual(p.returncode, 0)
        denied = str(ROOT.parent / ('dotfiles-denied-' + self.work.name))
        p = self.shell('/bin/bash', f'printf x > {denied}', check=False)
        self.assertNotEqual(p.returncode, 0)
        self.assertFalse(Path(denied).exists())
        p = self.shell('/bin/bash', '/usr/bin/curl --noproxy "*" --connect-timeout 1 http://127.0.0.1:9', check=False)
        self.assertNotEqual(p.returncode, 0)

    def test_syntax(self):
        bash_files = ['.zshenv', '.profile', '.bashrc', '.bash_profile', '.aliases', 'functions', 'lib/shell.sh',
                      'lib/archive.sh', 'install', 'backup', 'remote-install.sh', 'code.sh', 'tests/run-sandboxed.sh']
        for name in bash_files:
            with self.subTest(name=name):
                p = subprocess.run(['/bin/bash', '-n', str(REPO / name)], capture_output=True, text=True)
                self.assertEqual(p.returncode, 0, p.stderr)
        p = subprocess.run(['/bin/zsh', '-n', str(REPO / '.zshrc')], capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)

    def test_startup_without_optional_tools_and_repeated_source(self):
        for osname, arch in [('Darwin', 'x86_64'), ('Darwin', 'arm64'), ('Linux', 'x86_64'), ('Linux', 'aarch64')]:
            for shell in SHELLS:
                with self.subTest(os=osname, arch=arch, shell=shell):
                    env = dict(self.env, SCENARIO_OS=osname, SCENARIO_ARCH=arch)
                    env['PATH'] = f':{self.bin}:/usr/bin::/bin:/usr/bin:/tmp/literal[*]:'
                    code = self.source(shell) * 2 + 'printf "PATH=%s\\nSECRET=%s\\n" "$PATH" "$DOTFILES_FIXTURE_SECRET"\n'
                    p = self.shell(shell, code, env=env)
                    paths = next(l[5:] for l in p.stdout.splitlines() if l.startswith('PATH=')).split(':')
                    self.assertNotIn('', paths)
                    self.assertEqual(len(paths), len(set(paths)))
                    self.assertIn('/tmp/literal[*]', paths)
                    self.assertIn('SECRET=loaded', p.stdout)

    def test_platform_aliases(self):
        for shell in SHELLS:
            p = self.shell(shell, self.source(shell) + 'alias ls; alias o; alias lip; if alias ip >/dev/null 2>&1; then exit 9; fi\n')
            self.assertIn('--color=auto', p.stdout)
            self.assertIn('xdg-open', p.stdout)
            env = dict(self.env, SCENARIO_OS='Darwin')
            p = self.shell(shell, self.source(shell) + 'alias ls; alias o; alias ip; alias flushdns\n', env=env)
            self.assertIn('ls -G', p.stdout)
            self.assertIn('open .', p.stdout)
            self.assertIn('public-ip', p.stdout)

    def test_brew_prefix_selection(self):
        for shell in SHELLS:
            for osname, arch, present, expected in [
                ('Darwin', 'x86_64', ['/usr/local','/opt/homebrew'], '/usr/local'),
                ('Darwin', 'arm64', ['/usr/local','/opt/homebrew'], '/opt/homebrew'),
                ('Darwin', 'arm64', ['/usr/local'], ''),
                ('Darwin', 'x86_64', ['/opt/homebrew'], ''),
                ('Linux', 'x86_64', ['/home/linuxbrew/.linuxbrew','/usr/local'], '/home/linuxbrew/.linuxbrew'),
                ('Linux', 'aarch64', [], ''),
            ]:
                with self.subTest(shell=shell, os=osname, arch=arch):
                    cases = '|'.join('"'+p+'"' for p in present) or '"/not-present"'
                    code = '. "$HOME/.shell-common.sh"\n_dt_is_brew_prefix() { case "$1" in '+cases+') return 0;; *) return 1;; esac; }\n'
                    code += f'_dt_brew_prefix {osname} {arch}\n'
                    self.assertEqual(self.shell(shell, code).stdout, expected)

    def test_nvm_default_resolution_and_lazy_loading(self):
        nvm = self.home / '.nvm'
        (nvm / 'alias/lts').mkdir(parents=True)
        for v in ['v9.11.2', 'v20.9.0', 'v20.12.1', 'v24.21.0']:
            (nvm / 'versions/node' / v / 'bin').mkdir(parents=True)
        (nvm / 'nvm.sh').write_text('nvm() { printf "lazy:%s\\n" "$*"; }\n')
        for want, expected in [('20', 'v20.12.1'), ('v9.11.2', 'v9.11.2'), ('node', 'v24.21.0'), ('lts/test', 'v20.12.1')]:
            (nvm / 'alias/default').write_text(want + '\n')
            (nvm / 'alias/lts/test').write_text('v20.12.1\n')
            for shell in SHELLS:
                with self.subTest(default=want, shell=shell):
                    p = self.shell(shell, self.source(shell) + 'printf "PATH=%s\\n" "$PATH"; nvm --version\n')
                    self.assertIn(str(nvm / 'versions/node' / expected / 'bin'), p.stdout)
                    self.assertIn('lazy:--version', p.stdout)

    def test_optional_oh_my_zsh_and_cargo(self):
        omz = self.home / '.oh-my-zsh'
        omz.mkdir()
        (omz / 'oh-my-zsh.sh').write_text('printf "OMZ_PLUGINS=%s\\n" "${plugins[*]}"\n')
        cargo = self.home / '.cargo'
        cargo.mkdir()
        (cargo / 'env').write_text('export DOTFILES_CARGO_FIXTURE=loaded\n')
        for osname in ['Darwin', 'Linux']:
            env = dict(self.env, SCENARIO_OS=osname)
            p = self.shell('/bin/zsh', self.source('/bin/zsh') + 'printf "CARGO=%s\\n" "$DOTFILES_CARGO_FIXTURE"\n', env=env)
            self.assertIn('CARGO=loaded', p.stdout)
            plugins = next(l for l in p.stdout.splitlines() if l.startswith('OMZ_PLUGINS='))
            self.assertEqual('macos' in plugins, osname == 'Darwin')

    def test_missing_nvm_does_not_define_broken_stub(self):
        for shell in SHELLS:
            self.shell(shell, self.source(shell) + 'if command -v nvm >/dev/null 2>&1; then exit 8; fi\n')

    def test_optional_cargo_login_files(self):
        for shell, name in [('/bin/zsh', '.zshenv'), ('/bin/bash', '.profile'), ('/bin/bash', '.bash_profile')]:
            self.shell(shell, '. "$HOME/' + name + '"\n:')

    def test_functions_help_and_tag_helpers(self):
        for shell in SHELLS:
            p = self.shell(shell, '. "$HOME/.functions"\n_dt_track_num 08/12; printf "\\n"; pdf-compress --help; pdf-merge --help; flac-to-tracks --help; flac-to-alac --help\n')
            self.assertTrue(p.stdout.startswith('8\n'))
            self.assertEqual(p.stdout.count('usage:'), 4)

    def test_link_only_install_repeat_and_backup(self):
        for osname in ['Darwin', 'Linux']:
            env = dict(self.env, SCENARIO_OS=osname)
            # Only a fake, non-sensitive input is replaced and backed up.
            (self.home / '.aliases').unlink(missing_ok=True)
            (self.home / '.aliases').write_text('# original fixture\n')
            for _ in range(2):
                p = subprocess.run(['/bin/bash', str(REPO/'install'), '--link-only', '--no-zip'], env=env, cwd=self.work, capture_output=True, text=True, timeout=25)
                self.assertEqual(p.returncode, 0, p.stderr)
            support = self.home/'Library/Application Support' if osname=='Darwin' else self.home/'.config'
            self.assertTrue((support/'Code/User/settings.json').is_symlink())
            self.assertTrue((self.home/'.shell-common.sh').is_symlink())
            self.assertEqual((self.home/'.secret').read_text(), 'export DOTFILES_FIXTURE_SECRET=loaded\n')
            originals = list((self.home/'dotfiles-backup').glob('*/.aliases'))
            self.assertTrue(any(p.read_text()=='# original fixture\n' for p in originals))

    def test_installer_full_flow_uses_mock_tools_only(self):
        self.stub('brew', 'printf "brew:%s\\n" "$*" >> "$HOME/calls"')
        self.stub('code', 'printf "code:%s\\n" "$*" >> "$HOME/calls"')
        # Simulate the downloaded installer; PROFILE must suppress rc edits.
        payload = self.work / 'fake-nvm-installer'
        payload.write_text('''[ "$PROFILE" = /dev/null ] || exit 91
mkdir -p "$HOME/.nvm"
cat > "$HOME/.nvm/nvm.sh" <<'NVM'
nvm() { printf 'nvm:%s\\n' "$*" >> "$HOME/calls"; }
NVM
''')
        self.stub('curl', 'cat "$DOTFILES_NVM_INSTALLER_FIXTURE"')
        env = dict(self.env, DOTFILES_NVM_INSTALLER_FIXTURE=str(payload))
        p = subprocess.run(['/bin/bash', str(REPO/'install'), '--no-zip'], env=env, cwd=self.work, capture_output=True, text=True, timeout=25)
        self.assertEqual(p.returncode, 0, p.stderr)
        calls = (self.home / 'calls').read_text()
        self.assertIn('brew:bundle --file=', calls)
        self.assertIn('nvm:install --lts', calls)
        self.assertIn('nvm:alias default lts/*', calls)
        self.assertIn('code:--install-extension ', calls)
        self.assertEqual((self.home / '.zshrc').resolve(), REPO / '.zshrc')

    def test_install_zip_preserves_dangling_link_and_original(self):
        import stat
        import zipfile
        (self.home / '.aliases').unlink()
        (self.home / '.aliases').write_text('# fixture original\n')
        (self.home / '.npmrc').symlink_to('missing-fixture')
        p = subprocess.run(['/bin/bash', str(REPO/'install'), '--link-only'], env=self.env, cwd=self.work, capture_output=True, text=True, timeout=25)
        self.assertEqual(p.returncode, 0, p.stderr)
        archives = list((self.home / 'dotfiles-backup').glob('*.zip'))
        self.assertEqual(len(archives), 1)
        with zipfile.ZipFile(archives[0]) as archive:
            aliases = next(n for n in archive.namelist() if n.endswith('/.aliases'))
            npmrc = next(n for n in archive.namelist() if n.endswith('/.npmrc'))
            self.assertEqual(archive.read(aliases), b'# fixture original\n')
            self.assertTrue(stat.S_ISLNK(archive.getinfo(npmrc).external_attr >> 16))
            self.assertEqual(archive.read(npmrc), b'missing-fixture')

    def test_audio_linux_cuetag_name(self):
        for name in ['cuebreakpoints', 'shnsplit', 'metaflac']:
            self.stub(name, ':')
        self.stub('cuetag', ':')
        for shell in SHELLS:
            p = self.shell(shell, '. "$HOME/.functions"\nflac-to-tracks\n', check=False)
            self.assertNotEqual(p.returncode, 0)
            self.assertIn('need a .cue and a .flac', p.stderr)
            self.assertNotIn('missing required command', p.stderr)

    def test_brewfile_platform_gating(self):
        for osname in ['Darwin','Linux']:
            code = '''module OS
  def self.mac?; ENV['SCENARIO_OS'] == 'Darwin'; end
  def self.linux?; !mac?; end
end
$items=[]
def brew(name,*); $items << ['brew', name]; end
def cask(name,*); $items << ['cask', name]; end
def tap(name,*); $items << ['tap', name]; end
load ARGV[0]
$items.each { |item| puts item.join(':') }
'''
            p = subprocess.run(['/usr/bin/ruby','-e',code,str(REPO/'Brewfile')], env=dict(self.env,SCENARIO_OS=osname), capture_output=True,text=True,timeout=25)
            self.assertEqual(p.returncode,0,p.stderr)
            self.assertNotIn('miniconda',p.stdout)
            self.assertNotIn('diffusionbee',p.stdout)
            if osname=='Linux':
                self.assertNotIn('cask:',p.stdout)
                for package in ['pinentry-mac','blueutil','molten-vk','swiftlint','xcodegen']:
                    self.assertNotIn('brew:'+package+'\n',p.stdout)
                self.assertIn('brew:pinentry\n',p.stdout)
            else:
                self.assertIn('cask:iterm2\n',p.stdout)

if __name__ == '__main__':
    unittest.main(verbosity=2)
