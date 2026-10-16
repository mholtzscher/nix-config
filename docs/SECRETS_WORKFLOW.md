# Secrets workflow

Personal credentials live as native age ciphertext in
`~/.config/mise/config.personal.toml`, shared by the desktop, personal Mac, and
Wanda. The work profile does not load them. Agenix is no longer a runtime or
editing dependency. Never print resolved values or commit plaintext credentials.

## Commands

Use `./scripts/secrets` for all secret work:

- `list`: list environment-variable names, never values.
- `audit`: check all fourteen native age payloads and public recipients without
  decrypting them. Run after declaration or encrypted-source changes.
- `edit [NAME]`: choose a secret and enter its replacement through hidden input.
  Uses age to write a native Mise ciphertext value, then saves and syncs it.
  Agents must not run interactive value edits.
- `edit NAME --from-file PATH`: user-run multiline input. File contents travel
  through stdin, never arguments/logs.
- `create NAME`: add an encrypted environment value using the same hidden input.
- `rekey [--identity PATH]`: re-encrypt current Mise payloads to the configured
  public recipients. Plaintext travels only through a pipe between age processes;
  no plaintext temporary files or values enter the helper's output.

The personal Mise profile installs `age`; the helper uses only Mise, age, and
Python, not Nix. Keep identity keys out of tracking and back them up separately.
The existing `~/.ssh/id_ed25519_agenix_<host>` names remain valid age identities;
the historical filename does not require Agenix. Do not delete or rotate those
keys as part of removing Nix/Agenix.

## Runtime environment

All personal hosts use the existing `personal` profile; there is no additional
Mac profile or enable/validator step. Strict native age decryption loads the
encrypted `[vars]`, and redacted `[env]` aliases expose the credentials. The
multiline database environment is preserved exactly; scalar credentials have
editor-added surrounding whitespace removed. Restart long-running agent
applications after changing delivery or rotating a value.

MCP configuration lives in `mholtzscher/workstation`. Pi uses `${NAME}` references;
OpenCode's local MCP processes inherit environment variables. Container commands
forward named variables with bare `-e VAR`, not inline values.

Komodo's existing configuration and persistent files are outside this migration.
They are not regenerated, moved, or deleted.

## One-time migration

`./scripts/secrets stage --share-personal` stages the fourteen archived `.age`
payloads into the existing personal config. The explicit flag authorizes adding
Wanda to the four formerly restricted credentials. Only those four payloads are
stream-re-encrypted; the other ten ciphertexts are copied unchanged. Original
encrypted files and recipient metadata in `secrets/` remain recovery material,
not the active source of truth. Do not stage again after editing live Mise values.
Agents may run this ciphertext-only/streaming operation without viewing values.

Remove Agenix through each host's normal user-run Nix switch only after the Mise
configuration has been restored. Never run a switch as an agent.
