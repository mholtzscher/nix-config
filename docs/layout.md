# Repo Layout

Reference for repo structure and module flow.

## Current Hosts

- Darwin: `personal-mac`, `work-mac`
- NixOS: `nixos-desktop`
- Standalone home-manager: `wanda`

## Top-Level Layout

- `flake.nix`: flake inputs and host declarations
- `lib/default.nix`: shared builders: `mkSystem`, `mkHome`
- `hosts/`: host entrypoints and host-owned source files
- `modules/darwin/`: macOS system modules
- `modules/nixos/`: NixOS system modules
- `modules/shared/`: shared system-level modules
- `modules/home-manager/`: Linux user config; Macs use Mise
- `pkgs/`: custom packages

## Hosts

```text
hosts/
  darwin/
    personal-mac/
    work-mac/
  nixos/
    nixos-desktop/
  ubuntu/
    wanda/
```

- `hosts/darwin/<host>/default.nix`: darwin host entrypoint
- `hosts/nixos/<host>/default.nix`: NixOS host entrypoint
- `hosts/nixos/<host>/hardware-configuration.nix`: generated hardware config
- `hosts/ubuntu/<host>/default.nix`: standalone home-manager host entrypoint

## Modules

```text
modules/
  darwin/
    darwin.nix
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

- `modules/darwin/darwin.nix`: remaining Mac Nix plumbing; preferences and security policy live in Mise
- `modules/nixos/nixos.nix`: core NixOS services and system config
- `modules/nixos/hosts/<host>/`: host-specific NixOS modules
- `modules/home-manager/home.nix`: shared home-manager entrypoint
- `modules/home-manager/programs/`: reusable Linux user program modules
- `modules/home-manager/hosts/<host>/`: host-specific user config
- `modules/home-manager/files/`: managed dotfiles and assets

## Builder Model

- `mkSystem`: builds Darwin and NixOS systems
- `mkHome`: builds standalone home-manager configs for non-NixOS Linux
- Common module args: `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, `inputs`, `isWork`
- NixOS-only args: `currentSystem`, `graphical`, `gaming`

## Module Flow

- Darwin: host -> `modules/shared` -> `modules/darwin` (no Home Manager)
- NixOS: host -> `modules/shared` -> home-manager -> `modules/nixos` -> optional graphical modules
- Standalone Linux: host -> `mkHome` -> home-manager modules only

## Notes

- Mise manages Mac user tools, apps, fonts, and dotfiles outside Nix; neither Home Manager nor Homebrew is required.
- Put shared user programs in `modules/home-manager/programs/`
- Put machine-specific behavior under `modules/*/hosts/<host>/`
- Prefer platform guards for OS differences, host modules for machine differences
