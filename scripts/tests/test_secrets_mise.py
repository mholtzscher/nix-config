"""Integration checks use disposable age keys and non-secret canary values only."""

import contextlib
import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("secrets_mise", Path(__file__).parents[1] / "secrets-mise.py")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
MISE = shutil.which("mise")
AGE = subprocess.run([MISE, "which", "age"], capture_output=True, text=True, check=True).stdout.strip() if MISE else None


@unittest.skipUnless(MISE and AGE and shutil.which('ssh-keygen'), 'requires Mise, age, ssh-keygen')
class PersonalSecrets(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='personal-secrets-', dir='/tmp/opencode')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / 'desktop'
        self.config = self.home / '.config/mise'
        self.config.mkdir(parents=True)
        self.source = self.root / 'sources'
        self.source.mkdir()
        self.keys = {}
        for host in helper.HOSTS:
            key = self.home / f'.ssh/id_ed25519_agenix_{host}'
            key.parent.mkdir(exist_ok=True)
            subprocess.run(['ssh-keygen', '-q', '-t', 'ed25519', '-N', '', '-f', str(key)], check=True)
            self.keys[host] = Path(str(key) + '.pub').read_text().strip()
        self.identity = self.home / '.ssh/id_ed25519_agenix_nixos-desktop'
        (self.source / 'recipients.nix').write_text('{\n' + '\n'.join(f'"{host}" = {json.dumps(key)};' for host, key in self.keys.items()) + '\n}\n')
        self.values = {}
        self.originals = {}
        for name, variable in helper.SECRETS.items():
            raw = ('non-secret-canary-' + name + "-a'b\\c\n").encode()
            if variable == 'KOMODO_DATABASE_ENVIRONMENT':
                raw = b'POSTGRES_PASSWORD=non-secret-db-fixture\nKOMODO_DATABASE_PASSWORD=non-secret-db-fixture\n'
            self.values[variable] = raw.decode() if variable == 'KOMODO_DATABASE_ENVIRONMENT' else raw.decode().strip()
            args = [AGE, '--encrypt']
            for host, public in self.keys.items():
                if name not in helper.SHARED or host != 'wanda':
                    args.extend(['--recipient', public])
            encrypted = subprocess.run(args, input=raw, capture_output=True, check=True).stdout
            (self.source / (name + '.age')).write_bytes(encrypted)
            self.originals[name] = encrypted
        self.target = self.config / 'config.personal.toml'
        self.target.write_text('[tools]\n# keep unrelated settings\n[env]\n# Linux keeps Agenix. Native age values in personal-mac override this bridge.\n_.source = { path = "{{env.HOME}}/.config/mise/agenix-env.sh", redact = true }\n')
        (self.config / 'config.toml').write_text('''[settings]
experimental = true
[settings.self_update]
auto = false
[settings.history]
sync = "manual"
[dotfiles]
"~/.config/mise/config.toml" = { mode = "track" }
"~/.config/mise/config.personal.toml" = { mode = "track" }
''')
        self.env = self.environment(self.home, 'personal')
        self.environment_patch = patch.dict(os.environ, self.env, clear=True)
        self.environment_patch.start()
        self.addCleanup(self.environment_patch.stop)

    def environment(self, home, profile):
        return {
            'PATH': str(Path(AGE).parent) + ':' + os.environ['PATH'], 'HOME': str(home), 'USER': 'canary', 'LANG': 'C.UTF-8',
            'XDG_CONFIG_HOME': str(home / '.config'), 'XDG_DATA_HOME': str(home / '.local/share'),
            'XDG_STATE_HOME': str(home / '.local/state'), 'XDG_CACHE_HOME': str(home / '.cache'),
            'MISE_CONFIG_DIR': str(home / '.config/mise'), 'MISE_DATA_DIR': str(home / '.local/share/mise'),
            'MISE_STATE_DIR': str(home / '.local/state/mise'), 'MISE_CACHE_DIR': str(home / '.cache/mise'),
            'MISE_SYSTEM_CONFIG_DIR': str(self.root / 'system'), 'MISE_ENV': profile,
            'MISE_SELF_UPDATE_AUTO': 'false', 'GIT_CONFIG_NOSYSTEM': '1',
            'GIT_AUTHOR_NAME': 'Canary', 'GIT_AUTHOR_EMAIL': 'canary@example.invalid',
            'GIT_COMMITTER_NAME': 'Canary', 'GIT_COMMITTER_EMAIL': 'canary@example.invalid',
        }

    def stage(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            helper.stage(self.target, self.source, self.identity, True)
        for value in self.values.values():
            self.assertNotIn(value, output.getvalue())

    def test_stage_preserves_payloads_and_grants_only_approved_wanda_access(self):
        self.stage()
        config = helper.load(self.target)
        self.assertEqual(len(helper.recipients(config)), 3)
        self.assertNotIn('_.source', self.target.read_text())
        self.assertIn('# keep unrelated settings', self.target.read_text())
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o600)
        for name, variable in helper.SECRETS.items():
            encrypted = helper.payload(config, variable)
            self.assertEqual((self.source / (name + '.age')).read_bytes(), self.originals[name])
            if name not in helper.SHARED:
                self.assertEqual(encrypted, self.originals[name])
            else:
                self.assertNotEqual(encrypted, self.originals[name])
                before = subprocess.run([AGE, '-d', '-i', str(self.home / '.ssh/id_ed25519_agenix_wanda')], input=self.originals[name], capture_output=True, check=False)
                self.assertNotEqual(before.returncode, 0)
            for host in helper.HOSTS:
                decrypted = subprocess.run([AGE, '-d', '-i', str(self.home / f'.ssh/id_ed25519_agenix_{host}')], input=encrypted, capture_output=True, check=True).stdout.decode()
                actual = decrypted if variable == 'KOMODO_DATABASE_ENVIRONMENT' else decrypted.strip()
                self.assertEqual(actual, self.values[variable])
            self.assertNotIn(self.values[variable], self.target.read_text())

    def test_all_personal_hosts_decrypt_and_keyless_work_adopts_and_syncs(self):
        self.stage()
        origin = self.root / 'origin.git'
        subprocess.run(['git', 'init', '--bare', '-q', str(origin)], check=True)
        helper.mise(['dot', 'save'])
        helper.mise(['dot', 'origin', 'set', str(origin), '--sync', 'manual', '--yes'])
        for host, profile in [(h, 'personal') for h in helper.HOSTS] + [('work', 'work')]:
            home = self.root / ('reader-' + host)
            home.mkdir()
            if host != 'work':
                key = home / f'.ssh/id_ed25519_agenix_{host}'
                key.parent.mkdir()
                shutil.copyfile(self.home / f'.ssh/id_ed25519_agenix_{host}', key)
                key.chmod(0o600)
            env = self.environment(home, profile)
            for command in [('bootstrap', '--adopt', str(origin), '--yes'), ('dot', 'sync'), ('dot', 'pull')]:
                result = subprocess.run([MISE, *command], env=env, cwd=home, capture_output=True, check=False)
                self.assertEqual(result.returncode, 0, result.stderr.decode())
            result = subprocess.run([MISE, 'env', '--json'], env=env, cwd=home, capture_output=True, check=True)
            values = json.loads(result.stdout)
            if host == 'work':
                self.assertFalse(set(self.values) & values.keys())
            else:
                for name, expected in self.values.items():
                    self.assertEqual(values[name], expected)
                    self.assertNotIn(helper.RAW + name, values)

    def test_sharing_requires_explicit_flag_and_failures_preserve_original_config(self):
        original = self.target.read_bytes()
        with self.assertRaises(helper.SecretError):
            helper.stage(self.target, self.source, self.identity, False)
        self.assertEqual(self.target.read_bytes(), original)
        with self.assertRaises(helper.SecretError):
            helper.stage(self.target, self.source, self.root / 'missing-identity', True)
        self.assertEqual(self.target.read_bytes(), original)

    def test_direct_native_edit_and_raw_alias_removal(self):
        self.stage()
        args = [AGE, '--encrypt']
        for key in helper.recipients(helper.load(self.target)):
            args.extend(['--recipient', key])
        # Large values remain ordinary age ciphertext, not a compressed format
        # that the helper could not later rekey.
        value = b'non-secret-large-rotation-fixture' * 100
        encrypted = subprocess.run(args, input=value, capture_output=True, check=True).stdout
        helper.replace_env_payload(self.target, 'KOMODO_API_KEY', encrypted)
        config = helper.load(self.target)
        self.assertEqual(helper.payload(config, 'KOMODO_API_KEY'), encrypted)
        self.assertNotIn(helper.RAW + 'KOMODO_API_KEY', config['vars'])
        helper.replace_env_payload(self.target, 'NEW_PERSONAL_KEY', encrypted)
        self.assertIn('NEW_PERSONAL_KEY', helper.names(helper.load(self.target)))

if __name__ == '__main__':
    unittest.main()
