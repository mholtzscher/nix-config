"""Manage personal Mise secrets without Nix or Agenix. Never log values."""

import argparse
import base64
import getpass
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
    "komodo-database-environment": "KOMODO_DATABASE_ENVIRONMENT",
    "komodo-init-admin-password": "KOMODO_INIT_ADMIN_PASSWORD",
    "komodo-jwt-secret": "KOMODO_JWT_SECRET",
    "komodo-webhook-secret": "KOMODO_WEBHOOK_SECRET",
}
SHARED = {"cloudflare-workers-ai-key", "hearth-discord-webhook", "typesafe-api-key", "unifi-password"}
HOSTS = ("personal-mac", "nixos-desktop", "wanda")
RAW = "secret_value_"


class SecretError(Exception):
    pass


def load(path):
    if path.is_symlink():
        raise SecretError(f"Expected a regular configuration file: {path.name}")
    try:
        return tomllib.loads(path.read_text())
    except (OSError, ValueError):
        raise SecretError(f"Cannot read configuration: {path.name}") from None


def mise(args, *, stdin=None, interactive=False):
    env = os.environ.copy()
    env.update(MISE_NO_ENV="1", MISE_ENV="personal", MISE_LOG_LEVEL="error")
    for name in ("MISE_DEBUG", "MISE_TRACE", "MISE_VERBOSE"):
        env.pop(name, None)
    result = subprocess.run(["mise", *args], input=stdin, env=env, cwd=Path.home(),
                            stdout=None if interactive else subprocess.PIPE,
                            stderr=None if interactive else subprocess.PIPE, check=False)
    if result.returncode:
        raise SecretError(f"Mise {args[0]} failed; credential output suppressed.")
    return result.stdout


def atomic(path, data):
    fd, name = tempfile.mkstemp(prefix=".secrets-", suffix=".toml", dir=path.parent)
    temporary = Path(name)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def recipients(config):
    values = [value for name, value in config.get("vars", {}).items() if name.startswith("secret_recipient_")]
    if len(values) < 3 or not all(isinstance(v, str) and v.startswith("ssh-ed25519 ") for v in values):
        raise SecretError("Expected public recipients for all personal hosts.")
    return values


def names(config):
    custom = [name for name, entry in config.get('env', {}).items()
              if isinstance(entry, dict) and 'age' in entry]
    return list(dict.fromkeys([*SECRETS.values(), *custom]))


def payload(config, variable):
    entry = config.get("env", {}).get(variable, {})
    if isinstance(entry, dict) and isinstance(entry.get("age"), str):
        encoded = entry["age"]
    else:
        value = "{{ vars." + RAW + variable
        value += " }}" if variable == "KOMODO_DATABASE_ENVIRONMENT" else " | trim }}"
        if entry != {"value": value, "redact": True}:
            raise SecretError(f"Missing or unredacted encrypted variable: {variable}")
        raw = config.get("vars", {}).get(RAW + variable, {})
        encoded = raw.get("age") if isinstance(raw, dict) else None
    try:
        data = base64.b64decode(encoded + "=" * (-len(encoded) % 4), validate=True)
    except (ValueError, TypeError):
        raise SecretError(f"Invalid age payload: {variable}") from None
    if not data.startswith(b"age-encryption.org/v1\n"):
        raise SecretError(f"Invalid age payload: {variable}")
    return data


def stream_rekey(data, keys, identity):
    """Plaintext travels only in an OS pipe between two age processes."""
    age = shutil.which("age")
    if not age:
        raise SecretError("Install the personal Mise age tool before rekeying.")
    args = [age, "--encrypt"]
    for key in keys:
        args.extend(["--recipient", key])
    # Ciphertext may use temporary files; plaintext is never stored on disk or
    # read into this Python process, printed, or placed on a command line.
    with tempfile.TemporaryFile() as source, tempfile.TemporaryFile() as encrypted:
        source.write(data)
        source.seek(0)
        decrypt = subprocess.Popen([age, "--decrypt", "--identity", str(identity)],
                                   stdin=source, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        try:
            encrypt = subprocess.Popen(args, stdin=decrypt.stdout, stdout=encrypted, stderr=subprocess.DEVNULL)
            decrypt.stdout.close()
            encrypt_code = encrypt.wait()
            decrypt_code = decrypt.wait()
        finally:
            if decrypt.poll() is None:
                decrypt.kill()
                decrypt.wait()
        if encrypt_code or decrypt_code:
            raise SecretError("Age rekey failed; originals unchanged and no values printed.")
        encrypted.seek(0)
        return encrypted.read()


def stage(target, sources, identity, share):
    """One-time move of encrypted sources into the existing personal profile."""
    original = target.read_bytes()
    config = load(target)
    if any(name in config.get("env", {}) for name in SECRETS.values()):
        raise SecretError("Personal secrets are already staged; use edit or rekey.")
    text = (sources / "recipients.nix").read_text()
    public = dict(re.findall(r'"([a-z-]+)"\s*=\s*"(ssh-ed25519 [^"]+)"', text))
    if set(public) != set(HOSTS):
        raise SecretError("Unexpected migration recipient inventory.")
    keys = [public[host] for host in HOSTS]
    data = {}
    for name in SECRETS:
        path = sources / f"{name}.age"
        encrypted = path.read_bytes()
        if not encrypted.startswith(b"age-encryption.org/v1\n"):
            raise SecretError(f"Invalid encrypted migration source: {name}")
        if name in SHARED:
            if not share:
                raise SecretError("Sharing the four additional credentials with Wanda requires --share-personal.")
            encrypted = stream_rekey(encrypted, keys, identity)
        data[name] = encrypted
    # Preserve all unrelated personal tools, casks, and Dock settings. The only
    # replaced environment directive is the obsolete Agenix bridge we added.
    text = original.decode().replace('# Linux keeps Agenix. Native age values in personal-mac override this bridge.\n', '')
    text = text.replace('_.source = { path = "{{env.HOME}}/.config/mise/agenix-env.sh", redact = true }\n', '')
    text += '\n# Personal secrets: native Mise age, shared by desktop, Mac, and Wanda.\n[vars]\n'
    for host in HOSTS:
        text += f'secret_recipient_{host.replace("-", "_")} = {json.dumps(public[host])}\n'
    text += '\n[settings.age]\nstrict = true\nssh_identity_files = ' + json.dumps([f'~/.ssh/id_ed25519_agenix_{host}' for host in HOSTS]) + '\n'
    for name, variable in SECRETS.items():
        encoded = base64.b64encode(data[name]).decode().rstrip('=')
        text += f'\n[vars.{RAW}{variable}]\nage = {json.dumps(encoded)}\n'
        value = '{{ vars.' + RAW + variable
        value += ' }}' if variable == 'KOMODO_DATABASE_ENVIRONMENT' else ' | trim }}'
        text += f'\n[env.{variable}]\nvalue = {json.dumps(value)}\nredact = true\n'
    candidate = tomllib.loads(text)
    for variable in SECRETS.values():
        payload(candidate, variable)
    if target.read_bytes() != original:
        raise SecretError("Personal config changed during staging; nothing replaced.")
    atomic(target, text.encode())
    print("Staged 14 encrypted personal variables; Wanda is a recipient of all fourteen.")


def replace_env_payload(target, name, data):
    """Change only ciphertext metadata and preserve unrelated personal settings."""
    original = target.read_text()
    config = load(target)
    encoded = base64.b64encode(data).decode().rstrip('=')
    declaration = f'[env.{name}]\nage = {json.dumps(encoded)}\n'
    pattern = r'(?ms)^\[env\.' + re.escape(name) + r'\]\n.*?(?=^\[|\Z)'
    if name in config.get('env', {}):
        updated = re.sub(pattern, lambda _: declaration + '\n', original, count=1)
    else:
        updated = original.rstrip() + '\n\n' + declaration
    config.setdefault('env', {})[name] = {'age': encoded}
    key = RAW + name
    if key in config.get('vars', {}):
        del config['vars'][key]
        updated = re.sub(r'(?ms)^\[vars\.' + re.escape(key) + r'\]\n.*?(?=^\[|\Z)', '', updated, count=1)
    if tomllib.loads(updated) != config:
        raise SecretError('Could not safely update encrypted metadata; config unchanged.')
    atomic(target, updated.encode())


def edit(target, name, source):
    config = load(target)
    choices = names(config)
    if not name:
        for index, value in enumerate(choices, 1):
            print(f"{index}. {value}")
        try:
            choice = int(input("Secret number: "))
            if not 1 <= choice <= len(choices):
                raise ValueError
            name = choices[choice - 1]
        except ValueError:
            raise SecretError("Enter a listed number.") from None
    if not re.fullmatch(r"[A-Z][A-Z0-9_]*", name):
        raise SecretError("Use an uppercase environment-variable name.")
    age = shutil.which('age')
    if not age:
        raise SecretError('Install the personal Mise age tool first.')
    args = [age, '--encrypt']
    for key in recipients(config):
        args.extend(['--recipient', key])
    if source:
        value = source.read_bytes()
    else:
        if not sys.stdin.isatty():
            raise SecretError('Run interactively for hidden input, or use --from-file.')
        value = getpass.getpass(f'{name}: ').encode()
    try:
        value.decode('utf-8')
    except UnicodeError:
        raise SecretError('Secret input must be UTF-8.') from None
    if not value or b'\0' in value or len(value) > 1048576:
        raise SecretError('Secret input must be nonempty, at most 1 MiB, and contain no NUL.')
    encrypted = subprocess.run(args, input=value, stdout=subprocess.PIPE,
                               stderr=subprocess.DEVNULL, check=False)
    if encrypted.returncode:
        raise SecretError('Age encryption failed; configuration unchanged.')
    replace_env_payload(target, name, encrypted.stdout)
    mise(["dot", "save", str(target)])
    mise(["dot", "sync"])
    print("Saved encrypted personal value. Restart long-running consumers after rotation.")


def rekey(target, identity):
    config = load(target)
    original = target.read_bytes()
    keys = recipients(config)
    fd, temporary = tempfile.mkstemp(prefix=".secrets-rekey-", suffix=".toml", dir=target.parent)
    temporary = Path(temporary)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(original)
        mise(["trust", str(temporary)])
        for name in names(config):
            encoded = base64.b64encode(stream_rekey(payload(config, name), keys, identity)).decode().rstrip('=')
            branch = f'env.{name}.age' if 'age' in config['env'][name] else f'vars.{RAW}{name}.age'
            mise(["config", "set", "--file", str(temporary), branch, encoded])
        if target.read_bytes() != original:
            raise SecretError('Personal config changed during rekey; nothing replaced.')
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)
    mise(["dot", "save", str(target)])
    mise(["dot", "sync"])
    print("Rekeyed personal ciphertext; no secret values printed.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['list', 'audit', 'edit', 'create', 'stage', 'rekey'], nargs='?', default='list')
    parser.add_argument('name', nargs='?')
    parser.add_argument('--from-file', type=Path)
    parser.add_argument('--identity', type=Path)
    parser.add_argument('--share-personal', action='store_true')
    args = parser.parse_args()
    directory = Path(os.environ.get('MISE_CONFIG_DIR', Path.home() / '.config/mise'))
    target = directory / 'config.personal.toml'
    identity = args.identity
    if identity is None:
        identity = next((Path.home() / f'.ssh/id_ed25519_agenix_{host}' for host in HOSTS
                         if (Path.home() / f'.ssh/id_ed25519_agenix_{host}').is_file()), None)
    if args.command == 'stage':
        if identity is None:
            raise SecretError('An existing personal identity is required to share the four credentials with Wanda.')
        stage(target, Path(__file__).resolve().parent.parent / 'secrets', identity, args.share_personal)
        mise(['dot', 'save', str(target), '--description', 'Use native age secrets for all personal hosts'])
        mise(['dot', 'sync'])
    elif args.command in ('edit', 'create'):
        edit(target, args.name, args.from_file)
    elif args.command == 'rekey':
        if identity is None:
            raise SecretError('Select an existing identity with --identity.')
        rekey(target, identity)
    else:
        config = load(target)
        recipients(config)
        for name in names(config):
            payload(config, name)
            if args.command == 'list':
                print(name)
        if args.command == 'audit':
            print(f'{len(names(config))} native age payloads and all personal public recipients verified; no values decrypted or printed.')


if __name__ == '__main__':
    try:
        main()
    except (SecretError, OSError, ValueError, subprocess.SubprocessError) as error:
        print('Error: ' + (str(error) if isinstance(error, SecretError) else 'secret operation failed; output suppressed.'), file=sys.stderr)
        sys.exit(1)
