# Repo Layout

Reference for repo structure and module flow.

## Current Hosts

- NixOS: `nixos-desktop`
- Standalone home-manager: `wanda`
- Macs are managed by `mholtzscher/workstation` through Mise, not this flake.

## Top-Level Layout

- `flake.nix`: flake inputs and host declarations
- `lib/default.nix`: shared builders: `mkSystem`, `mkHome`
- `hosts/`: host entrypoints and host-owned source files
- `modules/nixos/`: NixOS system modules
- `modules/shared/`: shared system-level modules
- `modules/home-manager/`: Linux user config; Macs use Mise
- `pkgs/`: custom packages

## Hosts

```text
hosts/
  nixos/
    nixos-desktop/
  ubuntu/
    wanda/
```

- `hosts/nixos/<host>/default.nix`: NixOS host entrypoint
- `hosts/nixos/<host>/hardware-configuration.nix`: generated hardware config
- `hosts/ubuntu/<host>/default.nix`: standalone home-manager host entrypoint

## Modules

```text
modules/
  nixos/
    nixos.nix
    hosts/nixos-desktop/
  shared/
    nix-settings.nix
  home-manager/
    home.nix
    packages.nix
    programs/
    hosts/
    files/
```

- `modules/nixos/nixos.nix`: core NixOS services and system config
- `modules/nixos/hosts/<host>/`: host-specific NixOS modules
- `modules/home-manager/home.nix`: shared home-manager entrypoint
- `modules/home-manager/programs/`: reusable Linux user program modules
- `modules/home-manager/hosts/<host>/`: host-specific user config
- `modules/home-manager/files/`: managed dotfiles and assets

## Builder Model

- `mkSystem`: builds NixOS systems
- `mkHome`: builds standalone home-manager configs for non-NixOS Linux
- Common module args: `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, `inputs`, `isWork`
- Legacy platform args remain compatible: `isDarwin = false`, `isLinux = true` for all Nix hosts.
- NixOS-only args: `currentSystem`, `graphical`, `gaming`

## Module Flow

- NixOS: host -> `modules/shared` -> home-manager -> `modules/nixos` -> optional graphical modules
- Standalone Linux: host -> `mkHome` -> home-manager modules only

## Notes

- Mise manages Mac tools, apps, fonts, preferences, security policy, and dotfiles. Neither Nix nor Homebrew is required on the Macs.
- Put shared user programs in `modules/home-manager/programs/`
- Put machine-specific behavior under `modules/*/hosts/<host>/`
- Prefer platform guards for OS differences, host modules for machine differences
