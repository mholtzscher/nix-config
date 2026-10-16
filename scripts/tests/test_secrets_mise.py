"""Run with python3 -m unittest discover -s scripts/tests -v.

All integration data and keys are disposable, non-secret fixtures. Real user
configuration, credentials, network remotes, and Nix activation are never used.
"""

import contextlib
import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "secrets_mise", Path(__file__).parents[1] / "secrets-mise.py"
)
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)
MISE = shutil.which("mise")
BRIDGE = Path.home() / ".config/mise/agenix-env.sh"


@unittest.skipUnless(
    MISE and shutil.which("ssh-keygen") and shutil.which("git"),
    "requires mise, git, ssh-keygen",
)
class NativeAgeMigrationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(
            prefix="mise-env-test-", dir="/tmp/opencode"
        )
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.home = self.root / "personal"
        self.config = self.home / ".config/mise"
        self.config.mkdir(parents=True)
        self.env = self.environment(self.home, "personal")
        self.environment_patch = patch.dict(os.environ, self.env, clear=True)
        self.environment_patch.start()
        self.addCleanup(self.environment_patch.stop)
        self.public = []
        for name in ("personal-mac", "nixos-desktop"):
            identity = self.home / f".ssh/id_ed25519_agenix_{name}"
            identity.parent.mkdir(exist_ok=True)
            subprocess.run(
                ["ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(identity)],
                check=True,
            )
            self.public.append(Path(str(identity) + ".pub").read_text().strip())
        self.profile = self.config / "config.personal-mac.toml"
        self.profile.write_text(
            "[vars]\nmac_secret_recipient = " + json.dumps(self.public[0]) + "\n"
            "mac_secret_recovery_recipient = " + json.dumps(self.public[1]) + "\n"
            '[settings.age]\nssh_identity_files = ["~/.ssh/id_ed25519_agenix_personal-mac"]\n'
        )
        (self.config / "config.toml").write_text("""[settings]
experimental = true
[settings.self_update]
auto = false
[settings.history]
sync = "manual"
[dotfiles]
"~/.config/mise/config.toml" = { mode = "track" }
"~/.config/mise/config.personal-mac.toml" = { mode = "track" }
""")
        (self.config / "miserc.local.toml").write_text('env = ["personal"]\n')
        self.runtime = self.home / ".runtime/agenix"
        self.expected = {}
        for index, (name, path) in enumerate(
            helper.sources(self.home, self.runtime).items()
        ):
            path.parent.mkdir(parents=True, exist_ok=True)
            # Punctuation and a CRLF exercise exact secret transport and newline
            # handling without resembling a real provider credential.
            value = f"non-secret-canary-{index}-a'b\\c $literal"
            path.write_bytes(value.encode() + b"\r\n")
            self.expected[name] = value
        self.origin = self.root / "origin.git"
        subprocess.run(["git", "init", "--bare", "-q", str(self.origin)], check=True)
        helper.run_mise(MISE, ["dot", "save"], self.home)
        helper.run_mise(
            MISE,
            ["dot", "origin", "set", str(self.origin), "--sync", "manual", "--yes"],
            self.home,
        )

    def environment(self, home, profile):
        return {
            "PATH": os.environ["PATH"],
            "HOME": str(home),
            "USER": "canary",
            "LANG": "C.UTF-8",
            "XDG_CONFIG_HOME": str(home / ".config"),
            "XDG_DATA_HOME": str(home / ".local/share"),
            "XDG_STATE_HOME": str(home / ".local/state"),
            "XDG_CACHE_HOME": str(home / ".cache"),
            "MISE_CONFIG_DIR": str(home / ".config/mise"),
            "MISE_DATA_DIR": str(home / ".local/share/mise"),
            "MISE_STATE_DIR": str(home / ".local/state/mise"),
            "MISE_CACHE_DIR": str(home / ".cache/mise"),
            "MISE_SYSTEM_CONFIG_DIR": str(self.root / "system"),
            "MISE_ENV": profile,
            "MISE_SELF_UPDATE_AUTO": "false",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_AUTHOR_NAME": "Canary",
            "GIT_AUTHOR_EMAIL": "canary@example.invalid",
            "GIT_COMMITTER_NAME": "Canary",
            "GIT_COMMITTER_EMAIL": "canary@example.invalid",
        }

    def import_secrets(self):
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            helper.import_existing(MISE, self.home, self.config, self.runtime)
        for value in self.expected.values():
            self.assertNotIn(value, output.getvalue())
        return output.getvalue()

    def test_round_trip_publication_profile_isolation_and_originals(self):
        original = {
            p: p.read_bytes() for p in helper.sources(self.home, self.runtime).values()
        }
        self.assertIn("Imported and verified 10", self.import_secrets())
        for path, content in original.items():
            self.assertEqual(path.read_bytes(), content)
        config = tomllib.loads(self.profile.read_text())
        helper.validate_encrypted(config)
        self.assertEqual(self.profile.stat().st_mode & 0o777, 0o600)
        for value in self.expected.values():
            self.assertNotIn(value, self.profile.read_text())
        self.assertEqual(
            tomllib.loads((self.config / "miserc.local.toml").read_text())["env"],
            ["personal", "personal-mac"],
        )
        actual = helper.resolved(MISE, self.home)
        for key, value in self.expected.items():
            self.assertEqual(actual[key], value)
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            helper.status(MISE, self.home, self.config)
        self.assertIn("no values printed", output.getvalue())
        published = subprocess.run(
            [
                "git",
                "--git-dir",
                str(self.origin),
                "show",
                "main:config/config.personal-mac.toml",
            ],
            capture_output=True,
            check=True,
        ).stdout.decode()
        self.assertEqual(published, self.profile.read_text())
        for value in self.expected.values():
            self.assertNotIn(value, published)

        # Work and personal-Linux readers have no decryption keys. Both must
        # adopt and then sync normally, without loading the Mac-only values.
        for name, selected in (("work", "work"), ("linux", "personal")):
            home = self.root / name
            home.mkdir()
            env = self.environment(home, selected)
            result = subprocess.run(
                [MISE, "bootstrap", "--adopt", str(self.origin), "--yes"],
                env=env,
                cwd=home,
                capture_output=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr.decode())
            values = subprocess.run(
                [MISE, "env", "--json"],
                env=env,
                cwd=home,
                capture_output=True,
                check=True,
            )
            self.assertFalse(set(self.expected) & json.loads(values.stdout).keys())
            for command in (("dot", "sync"), ("dot", "pull")):
                result = subprocess.run(
                    [MISE, *command],
                    env=env,
                    cwd=home,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(result.returncode, 0, result.stderr.decode())

        # The desktop's pre-existing recipient can decrypt as a recovery key;
        # the personal Mac key is not required on the recovery machine.
        recovery = self.root / "recovery"
        rc = recovery / ".config/mise"
        rc.mkdir(parents=True)
        (rc / "config.toml").write_text((self.config / "config.toml").read_text())
        (rc / "config.personal-mac.toml").write_text(self.profile.read_text())
        identity = recovery / ".ssh/id_ed25519"
        identity.parent.mkdir()
        shutil.copyfile(self.home / ".ssh/id_ed25519_agenix_nixos-desktop", identity)
        identity.chmod(0o600)
        result = subprocess.run(
            [MISE, "env", "--json"],
            env=self.environment(recovery, "personal,personal-mac"),
            cwd=recovery,
            capture_output=True,
            check=True,
        )
        for key, value in self.expected.items():
            self.assertEqual(json.loads(result.stdout)[key], value)

    def test_missing_source_leaves_profile_and_default_unchanged(self):
        original = self.profile.read_bytes()
        defaults = (self.config / "miserc.local.toml").read_bytes()
        next(iter(helper.sources(self.home, self.runtime).values())).unlink()
        with self.assertRaises(helper.SecretError):
            self.import_secrets()
        self.assertEqual(self.profile.read_bytes(), original)
        self.assertEqual((self.config / "miserc.local.toml").read_bytes(), defaults)

    def test_mismatched_identity_rolls_back_and_does_not_enable(self):
        original = self.profile.read_bytes()
        config = original.decode().replace(self.public[0], self.public[1])
        self.profile.write_text(config)
        with self.assertRaises(helper.SecretError):
            self.import_secrets()
        self.assertEqual(self.profile.read_text(), config)
        self.assertEqual(
            tomllib.loads((self.config / "miserc.local.toml").read_text())["env"],
            ["personal"],
        )

    def test_repeat_import_refuses_to_overwrite_encrypted_values(self):
        self.import_secrets()
        encrypted = self.profile.read_bytes()
        with self.assertRaises(helper.SecretError):
            self.import_secrets()
        self.assertEqual(self.profile.read_bytes(), encrypted)

    def test_plaintext_definitions_are_rejected(self):
        with self.assertRaises(helper.SecretError):
            helper.validate_encrypted(
                {"env": {key: "non-secret" for key in self.expected}}
            )

    def test_oversized_input_is_not_silently_truncated(self):
        original = self.profile.read_bytes()
        next(iter(helper.sources(self.home, self.runtime).values())).write_bytes(
            b"x" * 16384 + b"\ntrailing-data"
        )
        with self.assertRaises(helper.SecretError):
            self.import_secrets()
        self.assertEqual(self.profile.read_bytes(), original)

    def test_local_profile_update_preserves_other_settings_and_comments(self):
        local = self.config / "miserc.local.toml"
        local.write_text(
            '# machine preferences\nenv = [\n  "personal",\n] # roles\nauto_env = false\n'
        )
        _, _, updated = helper.default_profile_update(self.config)
        self.assertEqual(
            tomllib.loads(updated.decode()),
            {"env": ["personal", "personal-mac"], "auto_env": False},
        )
        self.assertIn("# machine preferences", updated.decode())
        self.assertIn("# roles", updated.decode())

    def test_work_default_is_rejected_before_any_import(self):
        (self.config / "miserc.local.toml").write_text('env = ["work"]\n')
        original = self.profile.read_bytes()
        with self.assertRaises(helper.SecretError):
            self.import_secrets()
        self.assertEqual(self.profile.read_bytes(), original)

    @unittest.skipUnless(BRIDGE.exists(), "requires shared workstation bridge")
    def test_linux_bridge_and_native_override_without_files_after_handoff(self):
        bridge = self.config / "agenix-env.sh"
        bridge.write_bytes(BRIDGE.read_bytes())
        personal = self.config / "config.personal.toml"
        personal.write_text(
            '[env]\n_.source = { path = "{{env.HOME}}/.config/mise/agenix-env.sh", redact = true }\n'
        )
        os.environ["XDG_RUNTIME_DIR"] = str(self.runtime.parent)
        before = json.loads(
            helper.run_mise(MISE, ["env", "--json"], self.home, resolve=True)
        )
        # The bridge mirrors shell command substitution: CR is left in the
        # fixture CRLF input, unlike the deliberately normalized native import.
        self.assertTrue(before["KOMODO_API_KEY"].endswith("\r"))
        self.import_secrets()
        for path in helper.sources(self.home, self.runtime).values():
            path.unlink()
        actual = helper.resolved(MISE, self.home)
        for key, value in self.expected.items():
            self.assertEqual(actual[key], value)


if __name__ == "__main__":
    unittest.main()
