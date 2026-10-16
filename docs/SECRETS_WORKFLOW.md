# Secrets workflow

Read the usage and relevant command implementation in `scripts/secrets` for creation, editing, auditing, host keys, or rekeying. Verify secret declaration/file changes with `./scripts/secrets audit`.

## Personal Mac: native Mise environment values

`./scripts/secrets mise-import` is a user-run handoff from the existing Agenix
files to native age-encrypted `[env]` values in
`~/.config/mise/config.personal-mac.toml`. It requires the personal Mac's existing
identity, retains the desktop as a recovery recipient, verifies every decrypted
value without printing it, and only then adds `personal-mac` alongside `personal`
in that Mac's untracked `miserc.local.toml`. It saves and syncs ciphertext only.
It does not remove Agenix or change its files. Do not run the import as an agent.

`./scripts/secrets mise-status` verifies resolution without printing values.
After import, `./scripts/secrets edit` on the personal Mac prompts for a native
Mise secret with hidden input; it does not update the Linux `.age` source.
The native helper uses Mise and Python, not Nix, so it remains usable after Nix
is retired. Back up the identity independently of the configuration repository.

Shared consumers read environment variables. `config.personal.toml` supplies an
`agenix-env.sh` bridge on hosts still using Agenix; the later `personal-mac`
profile overrides those values on the personal Mac. The work profile loads
neither source. Restart long-running agent applications after changing secret
delivery so their servers inherit the new environment.

## Build and rewrite gotchas

- If a build must pass before real values exist, use the helper to encrypt non-secret placeholder content. Do not write plaintext into `.age` files. The user replaces placeholders through the editor workflow in `AGENTS.md`; agenix decrypts at activation, so replacing values needs no rebuild.
- Run `git add` for new `.age` files before evaluation. Flakes ignore untracked files.
- Treat `secrets/secrets.nix` as script-rewritten data. For manual declaration edits, match `write_rules_from_tsv` in `scripts/secrets`; rewrites discard comments.

## pi MCP servers and containers

AI configuration now lives in `mholtzscher/workstation`. Before wiring secret-backed MCP environment variables or container forwarding, read `unifi-network` and `komodo` in that repository's `home@default/.pi/agent/mcp.json` for the native `${NAME}` substitution and bare `-e VAR` patterns. OpenCode's local MCP processes inherit credential variables directly. Also read `config/agenix-env.sh` and the declarations and Darwin runtime-path comments in `modules/home-manager/secrets.nix`. Extend script-generated entries to preserve the explicit paths the bridge requires; do not reduce them to the bare `file` form.
