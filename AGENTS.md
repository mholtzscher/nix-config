# AGENTS.md

Guidance for this multi-platform Nix flake repo.

## Safety

- Never apply Nix changes directly.
- Allowed validation: `darwin-rebuild build`, `nixos-rebuild build`, `home-manager build`
- Allowed update command only when user asks: `nix flake update`
- Forbidden: `darwin-rebuild switch`, `nixos-rebuild switch`, `home-manager switch`, `nup`, or any other apply command. The user runs these manually outside the agent.

## Workflow

1. Make minimal changes.
2. Validate with platform-specific build (dry-run, doesn't activate):
   - Darwin: `darwin-rebuild build --flake .#<hostname>`
   - NixOS: `nixos-rebuild build --flake .#<hostname>`
   - Ubuntu/standalone home-manager: `home-manager build --flake .#<user>@<hostname>`
3. Report failures clearly.
4. User runs apply commands.

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
- Use platform guards like `lib.mkIf isDarwin` for OS-specific behavior
- Use host modules for machine-specific behavior

## Key Concepts

- `mkSystem` builds Darwin and NixOS hosts
- `mkHome` builds standalone home-manager configs for non-NixOS Linux
- Common module args include `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, and `inputs`
- NixOS modules also receive `currentSystem`, `graphical`, and `gaming`

## Host Types

- Darwin hosts live under `hosts/darwin/`
- NixOS hosts live under `hosts/nixos/`
- Non-NixOS Linux hosts live under `hosts/ubuntu/` and use standalone home-manager

## Reference Docs

- `docs/layout.md`: repo structure, host inventory, module flow
- `docs/add-host.md`: Darwin, NixOS, and standalone home-manager host templates
- `docs/common-tasks.md`: common edit locations for programs, packages, and system settings
- `docs/platform-guidelines.md`: platform guards, host-vs-platform rules, module arg patterns
