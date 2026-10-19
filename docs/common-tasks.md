# Common Tasks

Quick routing guide for common edits.

Mac user tools and dotfiles are managed by Mise. Home Manager instructions below apply to Linux only.

## Add Shared Linux Program

1. Create `modules/home-manager/programs/<program>.nix`
2. Import it in `modules/home-manager/programs/default.nix`
3. Use host modules or capability flags for host-specific behavior
4. Validate with `./scripts/agent-validate.sh` per `docs/NIX_WORKFLOW.md`

## Add Host-Specific Program or Setting

- User-level: edit `modules/home-manager/hosts/<hostname>/default.nix`
- NixOS system-level: edit `modules/nixos/hosts/<hostname>/`
- Validate per `docs/NIX_WORKFLOW.md`

## Modify System Settings

- macOS preferences and security policy: Mise bootstrap; `mise run macos:security` applies native Touch ID sudo and disabled guest login
- Shared Nix settings: `modules/shared/nix-settings.nix`
- Core NixOS services/packages: `modules/nixos/nixos.nix`
- NixOS host-specific desktop/services: `modules/nixos/hosts/<hostname>/`
- Generated NixOS hardware config: `hosts/nixos/<hostname>/hardware-configuration.nix`

## Add Packages

- Shared Nix packages: `modules/home-manager/packages.nix`
- Host-specific user packages: `modules/home-manager/hosts/<hostname>/default.nix`
- Mac apps/fonts: `[bootstrap.packages]` in the shared or personal/work Mise config

## Add Custom Packages

For packages maintained locally under `pkgs/<name>/`:

1. Add the derivation in `pkgs/<name>/default.nix` and wire it into the shared or host-specific package list above.
2. For versioned packages, add an executable `scripts/updates/update-<name>.sh` accepting `<version|latest> [--validate]`.
   - GitHub release assets: use `scripts/updates/common.sh`.
   - GitHub source archives: use `scripts/updates/common-source.sh`.
   - Other artifact sources: follow `scripts/updates/update-terminal-control.sh`.
3. Fetch all supported platform hashes before modifying the package. Test the updater against the currently packaged version, then validate using `docs/NIX_WORKFLOW.md`.

Completion requires both the package and its executable updater. `scripts/update-all.sh` discovers `scripts/updates/update-*.sh` automatically; there is no registry to edit.

## Add Agent Skills

Agent skills are managed outside Nix by the `agent-skills` Mise bootstrap plugin
in `mholtzscher/workstation`. Declare only the selected skills in
`~/.config/mise/config.toml` under `[bootstrap.packages]`, then sync with
`mise dot sync`. Use `env = "personal"` for personal-only skills. Do not add
skill inputs or Home Manager ownership here.

## Add Mac App or Font

1. Add a `brew-cask:` entry under `[bootstrap.packages]` in the appropriate Mise config.
2. Restrict Mac-only entries with `os = "macos"`; preserve personal/work selection.
3. Use `adopt = true` for existing apps. Mise installs casks directly without Homebrew.

## Add Managed Files

- Shared dotfiles/assets: `modules/home-manager/files/`
- Wire file into home-manager from `modules/home-manager/home.nix` or a program module
- Use platform guards when the target path is OS-specific

## Validation Rule

- For config changes, follow `docs/NIX_WORKFLOW.md` and run `./scripts/agent-validate.sh`
- Do not apply changes from the agent; user runs apply commands
