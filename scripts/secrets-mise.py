"""User-run migration/editing of Mac credentials; never log resolved values."""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path

SECRETS = {
    "github-pat": "GITHUB_PERSONAL_ACCESS_TOKEN",
    "agent-artifacts-write-key": "AGENT_ARTIFACTS_WRITE_KEY",
    "typesafe-api-key": "TYPESAFE_API_KEY",
    "atuin-key": "ATUIN_ENCRYPTION_KEY",
    "hearth-openai-api-key": "HEARTH_OPENAI_API_KEY",
    "hearth-discord-webhook": "HEARTH_DISCORD_WEBHOOK",
    "cloudflare-workers-ai-key": "CLOUDFLARE_WORKERS_AI_KEY",
    "unifi-password": "UNIFI_PASSWORD",
    "komodo-api-key": "KOMODO_API_KEY",
    "komodo-api-secret": "KOMODO_API_SECRET",
}
PROFILE = "personal-mac"


class SecretError(Exception):
    pass


def read_config(path):
    if path.is_symlink():
        raise SecretError(f"Expected a writable regular config: {path}")
    try:
        return tomllib.loads(path.read_text())
    except (OSError, ValueError):
        raise SecretError(f"Cannot read TOML configuration: {path}") from None


def run_mise(mise, args, home, *, value=None, resolve=False, interactive=False):
    env = os.environ.copy()
    env["MISE_ENV"] = f"personal,{PROFILE}" if resolve else "personal"
    # Avoid inherited debug/tracing flags printing sensitive child-process data.
    for key in (
        "MISE_VERBOSE",
        "MISE_DEBUG",
        "MISE_TRACE",
        "MISE_LOG_LEVEL",
        "MISE_AGE_KEY",
        "MISE_AGE_KEY_FILE",
        "MISE_AGE_IDENTITY_FILES",
        "MISE_AGE_SSH_IDENTITY_FILES",
        "MISE_AGE_STRICT",
    ):
        env.pop(key, None)
    env["MISE_LOG_LEVEL"] = "error"
    if resolve:
        env.pop("MISE_NO_ENV", None)
    else:
        env["MISE_NO_ENV"] = "1"
    try:
        result = subprocess.run(
            [mise, *args],
            input=value,
            cwd=home,
            env=env,
            check=False,
            stdout=None if interactive else subprocess.PIPE,
            stderr=None if interactive else subprocess.PIPE,
        )
    except OSError:
        raise SecretError("Could not start Mise.") from None
    if result.returncode:
        # Do not include subprocess output: environment/template errors may
        # contain decrypted input. A generic error is safer than a traceback.
        raise SecretError(f"Mise {args[0]} failed; no credential output was printed.")
    return result.stdout


def recipients(config):
    variables = config.get("vars", {})
    values = [
        variables.get("mac_secret_recipient"),
        variables.get("mac_secret_recovery_recipient"),
    ]
    if not all(isinstance(v, str) and v.startswith("ssh-ed25519 ") for v in values):
        raise SecretError(
            "Configure the personal Mac and recovery public recipients first."
        )
    return values


def sources(home, runtime):
    stable = home / ".local/share/agenix"
    return {
        variable: (
            runtime if name in ("github-pat", "agent-artifacts-write-key") else stable
        )
        / name
        for name, variable in SECRETS.items()
    }


def resolved(mise, home):
    raw = run_mise(mise, ["env", "--json"], home, resolve=True)
    try:
        return json.loads(raw)
    except ValueError:
        raise SecretError("Mise did not return a valid environment.") from None


def validate_encrypted(config):
    env = config.get("env", {})
    for name in SECRETS.values():
        entry = env.get(name)
        if not isinstance(entry, dict) or not isinstance(entry.get("age"), (str, dict)):
            raise SecretError(f"Missing age-encrypted entry: {name}")
        if set(entry) - {"age", "redact"} or entry.get("redact") is False:
            raise SecretError(f"Unexpected or unredacted secret definition: {name}")


def default_profile_update(config_dir):
    local = config_dir / "miserc.local.toml"
    config = read_config(local) if local.exists() else {}
    profiles = config.get("env", ["personal"])
    if (
        not isinstance(profiles, list)
        or "work" in profiles
        or "personal" not in profiles
        or not all(
            isinstance(p, str) and re.fullmatch(r"[A-Za-z0-9_-]+", p) for p in profiles
        )
    ):
        raise SecretError(
            "Expected a personal default profile; review miserc.local.toml first."
        )
    profiles = list(dict.fromkeys([*profiles, PROFILE]))
    original = local.read_bytes() if local.exists() else b""
    text = original.decode("utf-8")
    declaration = "env = " + json.dumps(profiles)
    if "env" in config:
        text = re.sub(
            r"(?m)^env[ \t]*=[ \t]*\[[^\]]*\]", lambda _: declaration, text, count=1
        )
    else:
        text = declaration + "\n" + text
    try:
        if tomllib.loads(text) != {**config, "env": profiles}:
            raise ValueError
    except ValueError:
        raise SecretError(
            "Could not safely update miserc.local.toml; review its env declaration."
        ) from None
    return local, original, text.encode("utf-8")


def import_existing(mise, home, config_dir, runtime):
    target = config_dir / f"config.{PROFILE}.toml"
    original = target.read_bytes()
    config = read_config(target)
    if any(name in config.get("env", {}) for name in SECRETS.values()):
        raise SecretError(
            "Encrypted entries already exist; use edit instead of importing again."
        )
    local, local_original, local_updated = default_profile_update(config_dir)
    keys = recipients(config)
    identity = home / ".ssh/id_ed25519_agenix_personal-mac"
    if not identity.is_file() or identity.is_symlink():
        raise SecretError(
            "The personal Mac's existing Agenix identity must be a regular file."
        )
    # Read all values before changing any configuration. Files remain under
    # Agenix ownership; only ciphertext is written into the new profile.
    values = {}
    for name, path in sources(home, runtime).items():
        try:
            with path.open("rb") as source:
                value = source.read(16385)
            if len(value) > 16384:
                raise SecretError(f"Credential is too large: {name}")
            value = value.rstrip(b"\r\n")
            value.decode("utf-8")
        except (OSError, UnicodeError):
            raise SecretError(
                f"Cannot import the existing credential: {name}"
            ) from None
        if not value or b"\0" in value:
            raise SecretError(f"Credential is empty or contains NUL: {name}")
        values[name] = value

    fd, temporary = tempfile.mkstemp(
        prefix=".mise-secrets-", suffix=".toml", dir=config_dir
    )
    temporary = Path(temporary)
    replaced = False
    verified = False
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(original)
        run_mise(mise, ["trust", str(temporary)], home)
        for name, value in values.items():
            args = ["set", "--file", str(temporary), "--age-encrypt", "--stdin"]
            for key in keys:
                args.extend(["--age-ssh-recipient", key])
            run_mise(mise, [*args, name], home, value=value)
        validate_encrypted(read_config(temporary))
        if target.read_bytes() != original:
            raise SecretError(
                "Profile changed during import; refusing to overwrite it."
            )
        temporary.replace(target)
        replaced = True
        actual = resolved(mise, home)
        if any(
            actual.get(name) != value.decode("utf-8") for name, value in values.items()
        ):
            raise SecretError(
                "Credential round-trip mismatch; the original profile was restored."
            )
        verified = True
    finally:
        temporary.unlink(missing_ok=True)
        if replaced and not verified:
            target.write_bytes(original)
            target.chmod(0o600)

    # Enable the new profile only after all values have round-tripped exactly.
    if (local.read_bytes() if local.exists() else b"") != local_original:
        raise SecretError(
            "Local profile selection changed during import; enable personal-mac after review."
        )
    fd, temporary = tempfile.mkstemp(prefix=".miserc-", suffix=".toml", dir=config_dir)
    with os.fdopen(fd, "wb") as output:
        output.write(local_updated)
    Path(temporary).replace(local)
    run_mise(
        mise,
        [
            "dot",
            "save",
            str(target),
            "--description",
            "Import personal Mac credentials as native age environment values",
        ],
        home,
    )
    run_mise(mise, ["dot", "sync"], home)
    print(
        f"Imported and verified {len(values)} encrypted variables; enabled personal,personal-mac."
    )
    print(
        "Agenix files and Nix configuration are unchanged. Open a fresh terminal to test consumers."
    )


def status(mise, home, config_dir):
    validate_encrypted(read_config(config_dir / f"config.{PROFILE}.toml"))
    actual = resolved(mise, home)
    missing = [name for name in SECRETS.values() if not actual.get(name)]
    if missing:
        raise SecretError("Missing environment variables: " + ", ".join(missing))
    print(
        f"All {len(SECRETS)} encrypted environment variables resolve; no values printed."
    )


def edit(mise, home, config_dir):
    target = config_dir / f"config.{PROFILE}.toml"
    config = read_config(target)
    validate_encrypted(config)
    names = list(SECRETS.values())
    for index, name in enumerate(names, 1):
        print(f"{index}. {name}")
    try:
        choice = int(input("Which Mac environment secret? "))
    except ValueError:
        raise SecretError("Enter a listed number.") from None
    if choice < 1 or choice > len(names):
        raise SecretError("Enter a listed number.")
    args = ["set", "--file", str(target), "--age-encrypt", "--prompt"]
    for key in recipients(config):
        args.extend(["--age-ssh-recipient", key])
    run_mise(mise, [*args, names[choice - 1]], home, interactive=True)
    validate_encrypted(read_config(target))
    run_mise(mise, ["dot", "save", str(target)], home)
    run_mise(mise, ["dot", "sync"], home)
    print("Saved encrypted Mac value. Linux Agenix values were not changed.")


def main():
    if sys.platform != "darwin":
        raise SecretError(
            "Mac environment-secret commands run only on the personal Mac."
        )
    home = Path.home()
    config_dir = Path(os.environ.get("MISE_CONFIG_DIR", home / ".config/mise"))
    local = config_dir / "miserc.local.toml"
    default = read_config(local).get("env", []) if local.exists() else []
    selected = os.environ.get("MISE_ENV", ",".join(default)).split(",")
    if "work" in selected or "personal" not in selected:
        raise SecretError(
            "Select the personal profile, never work, for Mac secret migration."
        )
    mise = shutil.which("mise")
    if not mise:
        raise SecretError("Mise must be installed first.")
    action = sys.argv[1]
    if action == "import":
        runtime = subprocess.run(
            ["/usr/bin/getconf", "DARWIN_USER_TEMP_DIR"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        import_existing(mise, home, config_dir, Path(runtime) / "agenix")
    elif action == "status":
        status(mise, home, config_dir)
    elif action == "edit":
        edit(mise, home, config_dir)


if __name__ == "__main__":
    try:
        main()
    except (SecretError, OSError, subprocess.SubprocessError):
        # Avoid tracebacks, which can include values in exception messages.
        error = sys.exception()
        print(
            f"Error: {error}"
            if isinstance(error, SecretError)
            else "Error: secret operation failed; no values printed.",
            file=sys.stderr,
        )
        sys.exit(1)
