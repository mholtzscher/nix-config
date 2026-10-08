# Common Tasks

Quick routing guide for common edits.

## Add Cross-Platform Program

1. Create `modules/home-manager/programs/<program>.nix`
2. Import it in `modules/home-manager/programs/default.nix`
3. Use platform guards if only one OS should receive it
4. Validate with `nix flake check`

## Add Host-Specific Program or Setting

- User-level: edit `modules/home-manager/hosts/<hostname>/default.nix`
- NixOS system-level: edit `modules/nixos/hosts/<hostname>/`
- Validate with `nix flake check`

## Modify System Settings

- macOS defaults: `modules/darwin/darwin.nix`
- Shared Nix settings: `modules/shared/nix-settings.nix`
- Core NixOS services/packages: `modules/nixos/nixos.nix`
- NixOS host-specific desktop/services: `modules/nixos/hosts/<hostname>/`
- Generated NixOS hardware config: `hosts/nixos/<hostname>/hardware-configuration.nix`

## Add Packages

- Shared Nix packages: `modules/home-manager/packages.nix`
- Host-specific user packages: `modules/home-manager/hosts/<hostname>/default.nix`
- Shared Homebrew packages: `modules/darwin/homebrew/default.nix`
- Host-specific Homebrew packages: `modules/darwin/homebrew/hosts/<hostname>.nix`

## Add Custom Packages

For packages maintained locally under `pkgs/<name>/`:

1. Add the derivation in `pkgs/<name>/default.nix` and wire it into the shared or host-specific package list above.
2. For versioned packages, add an executable `scripts/updates/update-<name>.sh` accepting `<version|latest> [--validate]`.
   - GitHub release assets: use `scripts/updates/common.sh`; see `update-otel-desktop-viewer.sh`.
   - GitHub source archives: use `scripts/updates/common-source.sh`; see `update-vimhjkl.sh`.
   - Other artifact sources: follow `scripts/updates/update-terminal-control.sh` or `update-railway-cli.sh`.
3. Fetch all supported platform hashes before modifying the package. Test the updater against the currently packaged version, then validate using `docs/NIX_WORKFLOW.md`.

Completion requires both the package and its executable updater. `scripts/update-all.sh` discovers `scripts/updates/update-*.sh` automatically; there is no registry to edit.

## Add Agent Skills

1. Add the upstream repository as a `flake = false` input in `flake.nix`.
2. Add its source and enabled skill ID in `modules/home-manager/agents/agent-skills.nix`, using the existing target setup.
3. Validate using `docs/NIX_WORKFLOW.md`.

Skill input URLs follow upstream's default branch unless the user explicitly requests a release tag or revision. `flake.lock` records the resolved revision for reproducibility; the binary package's version does not determine the skill input's URL.

## Add Homebrew Package

1. Edit shared or host-specific Homebrew module
2. Add package to `taps`, `brews`, `casks`, or `masApps`
3. Validate with `nix flake check`

## Add Managed Files

- Shared dotfiles/assets: `modules/home-manager/files/`
- Wire file into home-manager from `modules/home-manager/home.nix` or a program module
- Use platform guards when the target path is OS-specific

## Validation Rule

- For config changes, use `nix flake check`
- Do not apply changes from the agent; user runs apply commands
