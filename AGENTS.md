# AGENTS.md

Guidance for this multi-platform Nix flake repo.

**Last updated:** 2026-09-12
**Repository:** nix-config (personal NixOS/Darwin/home-manager configurations)

## Safety

- Never apply Nix changes directly.
- `nix flake update` — only run when user explicitly requests it
- Forbidden: `nh darwin switch`, `nh os switch`, `nh home switch`, `darwin-rebuild switch`, `nixos-rebuild switch`, `home-manager switch`, `nup`, or any other apply command. The user runs these manually outside the agent.

## Workflow

1. Make minimal changes.
2. Validate: run `./scripts/agent-validate.sh` (auto-detects platform and host).
3. Report failures clearly.
4. User runs apply commands.

### Example workflow

```
User: "Add ripgrep to my packages"
Agent: Edit modules/home-manager/packages.nix to add ripgrep
Agent: Run: ./scripts/agent-validate.sh
Agent: Report: "Build successful. Run 'nh os switch .#nixos-desktop' to apply."
User: Runs switch command manually
```

## Repo Map

- `flake.nix`: host definitions
- `lib/default.nix`: shared builders like `mkSystem` and `mkHome`
- `hosts/`: per-host entrypoints
- `modules/darwin/`: macOS system config
- `modules/nixos/`: NixOS system config
- `modules/shared/`: shared system config
- `modules/home-manager/`: user config
- `modules/*/hosts/{hostname}/`: host-specific overrides

## Routing Rules

- Add cross-platform programs in `modules/home-manager/programs/`
- Add shared packages in `modules/home-manager/packages.nix`
- Add macOS package-manager config in `modules/darwin/homebrew/`
- Add host-specific user config in `modules/home-manager/hosts/{hostname}/`
- Add host-specific NixOS system config in `modules/nixos/hosts/{hostname}/`
- When adding a Neovim plugin, use `vim.pack` and configure it in `init.lua`
- Use platform guards like `lib.mkIf isDarwin` for OS-specific behavior
- Use host modules for machine-specific behavior

## Secrets (agenix)

- Always use `./scripts/secrets` for secret work — never invoke `agenix` directly.
  - New secret: `./scripts/secrets create` (adds recipient rule + Home Manager entry, then opens the editor)
  - Real values: `./scripts/secrets edit` — the user pastes values there; the agent must never handle plaintext secrets
  - Verify: `./scripts/secrets audit`
- Never place secret values inline in Nix — they land world-readable in the Nix store.
  - pi MCP servers: `env = { VAR = "!cat ${config.home.homeDirectory}/.local/share/agenix/<name>"; }` with bare `-e VAR` forwarding into containers (see `unifi-network` / `komodo` in `modules/home-manager/agents/pi.nix`).
  - Secrets consumed via `!cat` need an explicit `path` under `~/.local/share/agenix/` in `modules/home-manager/secrets.nix` (the adapter cannot expand agenix's Darwin runtime-directory expression), so extend the script-generated entry — do not simplify it to the bare `file` form.
- If the build must pass before values exist, seed placeholder content in the `.age` files and have the user replace it via `./scripts/secrets edit` (agenix decrypts at activation time, so no rebuild is needed afterwards).
- `git add` new `.age` files: flakes ignore untracked files and evaluation fails without it.
- Keep `secrets/secrets.nix` entries in the script's sorted order to avoid diff noise on the next scripted rewrite (note: a scripted rewrite also drops comments).

## Key Concepts

- `mkSystem` builds Darwin and NixOS hosts
- `mkHome` builds standalone Home Manager configs for non-NixOS Linux
- Common module args include `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, and `inputs`
- NixOS modules also receive `currentSystem`, `graphical`, and `gaming`

## Troubleshooting

### Reporting build failures

Include in error reports:
- Full command that was run
- Complete error output (last 20–30 lines if verbose)
- Host being built (e.g., `.#michaels-macbook`)
- Recent changes made

## Reference Docs

- `docs/layout.md`: repo structure, host inventory, module flow
- `docs/add-host.md`: Darwin, NixOS, and standalone home-manager host templates
- `docs/common-tasks.md`: common edit locations for programs, packages, and system settings
- `docs/platform-guidelines.md`: platform guards, host-vs-platform rules, module arg patterns
