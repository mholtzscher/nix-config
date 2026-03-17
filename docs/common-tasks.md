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
