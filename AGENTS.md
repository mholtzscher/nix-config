# AGENTS.md

Agent guidelines for this multi-platform Nix flake configuration using the **dendritic pattern** with flake-parts.

## Hosts

- **macOS**: Personal M1 Max (`Michaels-M1-Max`) and Work Mac (`Michael-Holtzscher-Work`)
- **NixOS**: Desktop (`nixos-desktop`) - Gaming and development workstation with Niri + DMS
- **Ubuntu**: Wanda (`wanda`) - Headless server with standalone home-manager

## Critical Safety Rules

**NEVER apply nix changes directly.** Only validate configurations using build commands.

### Allowed Commands

- `nix flake check` - Validate configuration
- `nix flake update` - Update inputs (when explicitly requested)
- `darwin-rebuild build --flake .` - Build without applying

### Forbidden Commands

- `darwin-rebuild switch` or `nup` - NEVER apply without explicit user approval
- `sudo nixos-rebuild switch` - NEVER
- `home-manager switch` - NEVER

### Workflow

1. Make changes
2. Validate with `nix flake check` or `darwin-rebuild build --flake .`
3. Report errors if build fails
4. Wait for user to run `nup` to apply

## Architecture: Dendritic Pattern

This flake uses **flake-parts** with **import-tree** to export reusable modules via `inputs.self.modules.*`. Hosts are pure wiring that import these modules.

### Module Export Structure

```
inputs.self.modules.homeManager.*     # Home-manager modules
inputs.self.modules.darwin.*          # nix-darwin system modules  
inputs.self.modules.nixos.*           # NixOS system modules
```

### File Structure

```
flake.nix                              # Root flake with flake-parts
modules/
  ├── _base.nix                        # Declares flake.modules option + standard exports
  └── features/                        # All dendritic feature modules
      ├── profile-common.nix           # Bundle of ~40 HM modules
      ├── packages.nix                 # Shared home.packages
      ├── aliases.nix                  # Shell aliases
      ├── home-base.nix                # Dotfiles, env vars, raycast scripts
      ├── catppuccin-theme.nix         # Catppuccin theming
      │
      ├── # CLI tools
      ├── bat.nix, eza.nix, fd.nix, fzf.nix, ripgrep.nix, zoxide.nix, jq.nix
      ├── btop.nix, bottom.nix, delta.nix
      │
      ├── # Shell + prompt
      ├── zsh.nix, nushell.nix, starship.nix, direnv.nix, atuin.nix, carapace.nix
      │
      ├── # Terminal
      ├── zellij.nix, ghostty.nix
      │
      ├── # Git
      ├── git.nix, gh.nix, gh-dash.nix, lazygit.nix, jujutsu.nix
      │
      ├── # Editors
      ├── neovim.nix, helix.nix, yazi.nix, zed.nix
      │
      ├── # Languages
      ├── go.nix, uv.nix, bun.nix, mise.nix, poetry.nix, pyenv.nix
      │
      ├── # Tooling
      ├── k9s.nix, lazydocker.nix, ssh.nix, opencode.nix, ollama.nix
      │
      ├── # Linux desktop
      ├── firefox.nix, zen.nix, webapps.nix
      │
      ├── # Darwin system modules
      ├── darwin-system.nix            # Fonts, GC, TouchID, system defaults
      ├── darwin-base.nix              # stateVersion, allowUnfree, nix-homebrew
      ├── homebrew-common.nix          # Common Homebrew packages
      ├── homebrew-personal-mac.nix    # Personal Mac Homebrew
      ├── homebrew-work-mac.nix        # Work Mac Homebrew
      ├── darwin-host-personal-mac.nix # Personal Mac system (user, dock)
      ├── darwin-host-work-mac.nix     # Work Mac system
      ├── darwin-hm-personal-mac.nix   # Personal Mac HM wiring
      ├── darwin-hm-work-mac.nix       # Work Mac HM wiring
      │
      ├── # NixOS system modules
      ├── nixos-desktop-system.nix     # Base NixOS desktop config
      ├── nixos-desktop-hm.nix         # NixOS desktop HM wiring
      ├── nixos-packages.nix           # Fonts, 1Password, dev tools
      ├── nixos-gaming.nix             # MangoHud, gaming packages, ratbagd
      ├── nixos-composition.nix        # Niri settings + DMS keybinds
      ├── nixos-wallpaper.nix          # Awww wallpaper daemon
      │
      ├── # Host-specific HM modules
      ├── host-personal-mac.nix        # Personal Mac user config
      ├── host-work-mac.nix            # Work Mac user config
      ├── host-nixos-desktop.nix       # NixOS desktop user config
      ├── host-wanda.nix               # Wanda server user config
      └── wanda-containers.nix         # Wanda container definitions

hosts/
  ├── personal-mac-dendritic.nix       # Darwin host (pure wiring)
  ├── work-mac-dendritic.nix           # Darwin host (pure wiring)
  ├── nixos-desktop-dendritic.nix      # NixOS host (pure wiring)
  ├── wanda-dendritic.nix              # Ubuntu HM host (pure wiring)
  └── nixos/
      └── nixos-desktop/
          ├── default.nix              # Hardware, services, users
          └── hardware-configuration.nix

files/                                 # Static config files
  ├── edid/                            # KVM EDID override
  ├── dms/                             # DankMaterialShell themes
  ├── ghostty/shaders/                 # Ghostty shaders
  ├── neovim/                          # Neovim config
  ├── nushell/                         # Nushell functions
  ├── opencode/                        # OpenCode agents/commands/skills
  ├── raycast/                         # Raycast scripts
  ├── wallpapers/                      # Desktop wallpapers
  └── ...                              # Other dotfiles
```

## Key Concepts

### Dendritic Module Pattern

Each feature module in `modules/features/` exports to `flake.modules.*`:

```nix
# modules/features/bat.nix
{ config, lib, ... }:
{
  options.myFeatures.bat.enable = lib.mkEnableOption "bat" // { default = true; };
  
  config = lib.mkIf config.myFeatures.bat.enable {
    flake.modules.homeManager.bat = {
      programs.bat.enable = true;
    };
  };
}
```

### Host Wiring

Hosts are pure wiring - they just import modules:

```nix
# hosts/personal-mac-dendritic.nix
{ inputs, ... }:
inputs.nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = { inherit inputs; self = inputs.self; /* ... */ };
  modules = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.self.modules.darwin.system
    inputs.self.modules.darwin.base
    inputs.self.modules.darwin.homebrewCommon
    inputs.self.modules.darwin.homebrewPersonalMac
    inputs.self.modules.darwin.hostPersonalMac
    inputs.self.modules.darwin.hmPersonalMac
  ];
}
```

### Module Arguments

All modules receive via `extraSpecialArgs`:
- `inputs` - Flake inputs
- `self` - `inputs.self` for accessing `self.modules.*`
- `user` - Primary username
- `isWork` - Boolean for work-specific config
- `isDarwin` / `isLinux` - Platform booleans
- `currentSystemName` / `currentSystemUser` - Host identifiers

## Common Tasks

### Add Program (Cross-Platform)

1. Create `modules/features/program-name.nix`:
```nix
{ config, lib, ... }:
let cfg = config.myFeatures.programName;
in {
  options.myFeatures.programName.enable = lib.mkEnableOption "program" // { default = true; };
  
  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.programName = {
      programs.programName.enable = true;
      # ... config
    };
  };
}
```

2. Add to `modules/features/profile-common.nix` imports:
```nix
imports = [
  # ...
  self.modules.homeManager.programName
];
```

3. Validate: `nix flake check`

### Add Host-Specific Config

Edit the appropriate host module in `modules/features/`:
- `host-personal-mac.nix` - Personal Mac user packages/settings
- `host-work-mac.nix` - Work Mac user packages/settings
- `host-nixos-desktop.nix` - NixOS desktop user packages/settings
- `host-wanda.nix` - Wanda server user packages/settings

### Add Homebrew Package

**Common** (all macOS hosts): Edit `modules/features/homebrew-common.nix`
**Personal Mac only**: Edit `modules/features/homebrew-personal-mac.nix`
**Work Mac only**: Edit `modules/features/homebrew-work-mac.nix`

### Add NixOS System Config

- **System packages/fonts/1Password**: `modules/features/nixos-packages.nix`
- **Gaming (MangoHud, ratbagd)**: `modules/features/nixos-gaming.nix`
- **Niri/DMS keybinds**: `modules/features/nixos-composition.nix`
- **Wallpaper daemon**: `modules/features/nixos-wallpaper.nix`
- **Hardware/services**: `hosts/nixos/nixos-desktop/default.nix`

### Add New Darwin Host

1. Create `hosts/new-mac-dendritic.nix`:
```nix
{ inputs, ... }:
inputs.nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = { inherit inputs; self = inputs.self; user = "username"; isWork = false; };
  modules = [
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.self.modules.darwin.system
    inputs.self.modules.darwin.base
    inputs.self.modules.darwin.homebrewCommon
    # Add host-specific modules...
  ];
}
```

2. Create host-specific modules in `modules/features/` as needed

3. Add to `flake.nix`:
```nix
darwinConfigurations."Hostname" = import ./hosts/new-mac-dendritic.nix { inherit inputs; };
```

### Add New NixOS Host

1. Create `hosts/new-host-dendritic.nix` (copy `nixos-desktop-dendritic.nix`)
2. Create `hosts/nixos/new-host/default.nix` for hardware/services
3. Generate hardware config: `nixos-generate-config --show-hardware-config`
4. Create host-specific HM module in `modules/features/`
5. Add to `flake.nix`:
```nix
nixosConfigurations.new-host = import ./hosts/new-host-dendritic.nix { inherit inputs; };
```

### Add New Ubuntu/Linux Host

1. Create `hosts/new-host-dendritic.nix`:
```nix
{ inputs, ... }:
let user = "username"; system = "x86_64-linux";
in inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs { inherit system; };
  extraSpecialArgs = { inherit inputs user; self = inputs.self; /* ... */ };
  modules = [
    inputs.self.modules.homeManager.profileCommon
    # Host-specific module...
    { home = { username = user; homeDirectory = "/home/${user}"; stateVersion = "24.11"; };
      targets.genericLinux.enable = true; }
  ];
}
```

2. Add to `flake.nix`:
```nix
homeConfigurations.new-host = import ./hosts/new-host-dendritic.nix { inherit inputs; };
```

## Platform Guards

For platform-specific config within shared modules:

```nix
# In a home-manager module
{ pkgs, lib, isDarwin, isLinux, ... }:
{
  # Using module args (cleaner)
  config = lib.mkIf isDarwin { /* macOS only */ };
  
  # Using pkgs detection (works anywhere)
  home.packages = lib.optionals pkgs.stdenv.isDarwin [ /* macOS packages */ ];
}
```

## Flake Outputs

```
darwinConfigurations.*      # nix-darwin system configs
nixosConfigurations.*       # NixOS system configs
homeConfigurations.*        # Standalone home-manager configs
modules.*                   # Custom: dendritic module exports
homeManagerModules.*        # Standard HM module exports
darwinModules.*             # Standard darwin module exports
nixosModules.*              # Standard NixOS module exports
```
