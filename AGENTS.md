# AGENTS.md

Agent guidelines for this multi-platform Nix flake configuration managing:
- **macOS**: Personal M1 Max (`Michaels-M1-Max`) and Work Mac (`Michael-Holtzscher-Work`)
- **NixOS**: Desktop (`nixos-desktop`) - Gaming and development workstation with Niri
- **Ubuntu**: Wanda (`wanda`) - Headless server with standalone home-manager

## Critical Safety Rules

**NEVER apply nix changes directly.** Only validate configurations using build commands.

### Allowed Commands

- ✅ `nix flake check` - Check syntax
- ✅ `nix flake update` - Update inputs (when explicitly requested)

### Forbidden Commands

- ❌ `darwin-rebuild switch` or `nup` - NEVER apply changes without explicit user approval
- ❌ `sudo darwin-rebuild switch` - NEVER

### Workflow

1. Make changes
2. Validate
3. Report errors if build fails
4. Wait for user to run `nup` to apply

## Quick Reference

### Commands

```bash
nup                                     # Apply configuration (user only)
nfu                                     # Update inputs
nix flake check                         # Check syntax
nf <file>.nix                           # Format nix files
```

### File Structure

```
flake.nix                              # Root flake, defines all hosts
lib/
  └── default.nix                      # Helper functions (mkSystem, mkHome)
hosts/
  ├── darwin/                          # macOS-specific hosts (all directories)
  │   ├── personal-mac/
  │   │   └── default.nix              # Personal M1 Max config
  │   └── work-mac/
  │       └── default.nix              # Work Mac config
  ├── nixos/                           # NixOS-specific hosts
  │   └── nixos-desktop/               # Desktop gaming/dev config
  │       ├── default.nix              # Main entry point
  │       ├── hardware-configuration.nix
  │       ├── users.nix                # User account configuration
  │       ├── networking.nix           # Network and firewall config
  │       ├── audio.nix                # PipeWire audio config
  │       ├── gpu.nix                  # NVIDIA GPU configuration
  │       ├── boot.nix                 # Boot loader configuration
  │       └── greeter.nix              # DMS login greeter
  └── ubuntu/                          # Ubuntu hosts (standalone home-manager)
      └── wanda/
          └── default.nix              # Headless server config
modules/
  ├── darwin/                          # macOS system modules
  │   ├── default.nix                  # Entry point
  │   ├── darwin.nix                   # System defaults (dock, finder, trackpad)
  │   └── homebrew/                    # Homebrew package management
  │       ├── default.nix              # Common packages across all macOS hosts
  │       └── hosts/                   # Host-specific Homebrew packages
  │           ├── personal-mac.nix
  │           └── work-mac.nix
  ├── nixos/                           # NixOS-only modules
  │   ├── default.nix
  │   ├── fonts.nix
  │   ├── nixos.nix                    # Core NixOS system config
  │   └── hosts/                       # Host-specific NixOS system config
  │       └── nixos-desktop/           # Desktop environment modules
  │           ├── default.nix
  │           ├── composition.nix      # Niri window manager + keybindings
  │           ├── gaming.nix           # Steam, MangoHud, GameMode
  │           ├── theme.nix            # GTK/Qt theming
  │           ├── wallpaper.nix        # swaybg wallpaper daemon
  │           └── webapps.nix          # Web apps as native apps
  ├── shared/                          # Cross-platform modules
  │   ├── default.nix
  │   └── nix-settings.nix             # Shared nix config (gc, flakes, etc.)
  └── home-manager/                    # Cross-platform home-manager
      ├── home.nix                     # Entry point (with platform guards)
      ├── packages.nix                 # Nix packages (platform-aware)
      ├── lsp-packages.nix             # Shared LSP servers for neovim/helix
      ├── shared-aliases.nix
      ├── programs/                    # Cross-platform program modules
      ├── hosts/                       # Host-specific user configs (all directories)
      │   ├── personal-mac/
      │   │   └── default.nix          # Personal Mac user packages/settings
      │   ├── work-mac/
      │   │   └── default.nix          # Work Mac user packages/settings
      │   ├── nixos-desktop/           # Desktop user packages/settings
      │   │   └── default.nix
      │   └── wanda/                   # Ubuntu server user packages/settings
      │       ├── default.nix
      │       └── containers.nix       # Nix-managed container definitions
      └── files/                       # Dotfiles
```

### Key Concepts

- **Flake inputs**: nixpkgs (unstable), nix-darwin, home-manager, nix-homebrew, niri, catppuccin, vicinae, etc.
- **Unified system builder**: `mkSystem` for Darwin/NixOS, `mkHome` for standalone home-manager
  - `mkSystem`: Uses `darwin = true` parameter to branch platform logic
  - `mkHome`: For non-NixOS Linux (Ubuntu, Debian, etc.) - standalone home-manager
  - Inspired by mitchellh/nixos-config unified approach
- **Module loading architecture**:
  - **Shared**: `modules/shared/`, `modules/home-manager/programs/`, `modules/home-manager/files/`
  - **Platform-specific**: `modules/darwin/`, `modules/darwin/homebrew/`, `modules/nixos/`
  - **Host-specific**: `modules/home-manager/hosts/{hostname}/`, `modules/nixos/hosts/{hostname}/`
  - **Darwin flow**: Host → darwin modules → homebrew module → shared modules → nix-homebrew → home-manager
  - **NixOS flow**: Host → nixos modules (including conditional host modules) → shared modules → home-manager
- **Conditional module loading** (lib/default.nix):
  - `graphical = true` → Loads `modules/nixos/hosts/nixos-desktop/` (Niri, Waybar, desktop env)
  - `graphical = false` → Skips desktop modules (for headless servers)
  - `gaming = true` → Available in module args for gaming-specific config
- **Platform separation**:
  - `modules/darwin/` - macOS system defaults (dock, finder, trackpad)
  - `modules/darwin/homebrew/` - macOS package management with host-specific overrides
  - `modules/nixos/` - Core NixOS system config + conditional host-specific modules
  - `modules/nixos/hosts/` - Host-specific system config (desktop env, services, etc.)
  - `modules/shared/` - Cross-platform (nix settings, gc)
  - `modules/home-manager/` - Cross-platform user config + host-specific configs
- **Host-specific configs**: Each host has:
  - `modules/home-manager/hosts/{hostname}/default.nix` - User packages and home settings
  - `modules/nixos/hosts/{hostname}/` - System-level config (desktop environment, services)
- **Platform guards**: Use `lib.mkIf isDarwin`, `lib.optionalAttrs isDarwin`, or similar with module args
- **Global module arguments**: All modules have access to `currentSystemName`, `currentSystemUser`, `isDarwin`, `isLinux`, `inputs`
  - NixOS modules also get `currentSystem`, `graphical`, `gaming`
  - Darwin modules also get `currentSystem`
- **Garbage collection**: Automatic weekly on Sundays at 2:00 AM (30 day retention)

## Common Tasks

### Add Program (Cross-Platform)

1. Create `modules/home-manager/programs/program-name.nix`
2. Import in `modules/home-manager/programs/default.nix`
3. If macOS-only, wrap with `config = lib.mkIf isDarwin { ... }`
4. Validate with `nb` (darwin) or `nix flake check` (both platforms)

### Add Program (Host-Specific)

1. Add to appropriate host config:
   - `modules/home-manager/hosts/personal-mac/default.nix` - Personal Mac user packages
   - `modules/home-manager/hosts/work-mac/default.nix` - Work Mac user packages
   - `modules/home-manager/hosts/nixos-desktop/default.nix` - NixOS desktop user packages
2. Validate with `nb` or `nix flake check`

### Add Host (Darwin)

1. Create `hosts/darwin/hostname/default.nix` (copy existing)
2. Create `modules/home-manager/hosts/hostname/default.nix` for host-specific config
3. Add to `flake.nix`:
```nix
darwinConfigurations."Host-Name" = lib.mkSystem {
  name = "friendly-name";           # Used in logs, module args
  system = "aarch64-darwin";        # Architecture
  darwin = true;                    # Required for Darwin
  hostPath = ./hosts/darwin/hostname;
  user = "username";                # Default: "michael"
};
```
4. Match system hostname with config name

### Add Host (NixOS)

1. Create `hosts/nixos/hostname/default.nix` (copy nixos-desktop structure)
2. Create `modules/home-manager/hosts/hostname/default.nix` for user-specific config
3. Create `modules/nixos/hosts/hostname/` directory for system-level config (optional, based on host needs)
4. Add to `flake.nix`:
```nix
nixosConfigurations.hostname = lib.mkSystem {
  name = "friendly-name";           # Used in logs, module args
  system = "x86_64-linux";          # Architecture: "x86_64-linux" or "aarch64-linux"
  hostPath = ./hosts/nixos/hostname;
  user = "username";                # Default: "michael"
  graphical = true;                 # Default: true - loads GUI modules (Niri, Waybar, etc.)
  gaming = false;                   # Default: false - available in module args
};
```
5. Generate hardware configuration:
   ```bash
   nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos/hostname/hardware-configuration.nix
   ```
6. Feature flags and module loading:
   - `graphical = true` → Conditionally loads `modules/nixos/hosts/hostname/` (for desktop environments)
   - `graphical = false` → Skips host-specific nixos modules (for headless servers)
   - `gaming = true` → Available in module args for gaming-specific configuration

### Add Host (Ubuntu / Non-NixOS Linux)

For non-NixOS Linux hosts, use standalone home-manager via `mkHome`:

1. Create `hosts/ubuntu/hostname/default.nix`:
```nix
{ pkgs, inputs, ... }:
{
  imports = [
    ../../../modules/home-manager/home.nix
    ../../../modules/home-manager/hosts/hostname
  ];
  home = {
    username = "username";
    homeDirectory = "/home/username";
  };
  targets.genericLinux.enable = true;
}
```
2. Create `modules/home-manager/hosts/hostname/default.nix` for host-specific config
3. Disable GUI programs if headless (use `lib.mkForce false`)
4. Add to `flake.nix`:
```nix
homeConfigurations.hostname = lib.mkHome {
  name = "hostname";
  system = "x86_64-linux";
  hostPath = ./hosts/ubuntu/hostname;
  user = "username";
};
```
5. Activation on target machine:
```bash
# First time (installs home-manager)
nix run home-manager -- switch --flake .#hostname

# Subsequent updates
home-manager switch --flake .#hostname
```

### Modify System Settings

**macOS** - Edit `modules/darwin/darwin.nix`:
- Dock settings
- Finder preferences
- Trackpad behavior
- App-specific defaults

**NixOS** - Edit appropriate file:
- Core system (`modules/nixos/nixos.nix`): system packages, services, boot, audio, SSH
- Host-specific (`modules/nixos/hosts/hostname/`): desktop environment, host services
- Hardware (`hosts/nixos/hostname-hardware.nix`): filesystems, kernel modules, boot loader

### Add Packages

- **Cross-platform Nix**: `modules/home-manager/packages.nix` (main list)
- **macOS-only Nix**: `modules/home-manager/packages.nix` (in `lib.optionals pkgs.stdenv.isDarwin`)
- **Homebrew** (macOS only):
  - Common packages: `modules/darwin/homebrew/default.nix`
  - Host-specific: `modules/darwin/homebrew/hosts/{personal-mac,work-mac}.nix`
- **Host-specific**: Add to `modules/home-manager/hosts/{hostname}/default.nix`

### Add Homebrew Package (macOS)

**Common package** (all macOS hosts):
1. Edit `modules/darwin/homebrew/default.nix`
2. Add to appropriate list under `homebrew` config (`taps`, `brews`, `casks`, `masApps`)
3. Validate with `nb` or `darwin-rebuild build --flake .`

**Host-specific package**:
1. Edit `modules/darwin/homebrew/hosts/{hostname}.nix`
2. Add to appropriate list under `homebrew` config (`brews`, `casks`, `masApps`)
3. Validate with `nb` or `darwin-rebuild build --flake .`

## Platform-Specific Guidelines

### macOS-Only Features

These should use platform guards or stay in darwin modules:
- Homebrew (in `modules/darwin/homebrew/`)
- Aerospace window manager (platform guarded in programs/aerospace.nix)
- macOS system defaults (in `modules/darwin/darwin.nix`)
- Raycast scripts (platform guarded in home.nix)
- macOS-specific paths (Library/*, platform guarded)

### NixOS-Only Features

These stay in nixos modules or use `isLinux` module argument:
- systemd services (core in `modules/nixos/nixos.nix`, host-specific in `modules/nixos/hosts/hostname/`)
- Boot loader configuration (in hardware config or core nixos module)
- Linux kernel modules (in hardware config)
- Desktop environment configs (Niri, Waybar in `modules/nixos/hosts/hostname/composition.nix` etc.)

### Cross-Platform with Conditions

Use platform detection in home-manager via module arguments (preferred):
```nix
# For files
home.file = { /* shared files */ }
  // lib.optionalAttrs isDarwin { /* macOS files */ };

# For programs
config = lib.mkIf isDarwin {
  programs.aerospace = { /* config */ };
};

# For activation
activation = lib.mkIf isDarwin { /* macOS activation */ };
```

**Global module arguments** (available in any module):
```nix
{ config, lib, pkgs, isDarwin, isLinux, currentSystemName, currentSystemUser, ... }:
{
  # Platform conditionals (cleaner than pkgs.stdenv.isDarwin)
  config = lib.mkIf isDarwin {
    programs.aerospace.enable = true;
  };
  
  # System-specific config
  environment.etc."hostname".text = currentSystemName;
  
  # User-specific config
  users.users.${currentSystemUser}.shell = pkgs.zsh;
}
```

**NixOS-specific module arguments**:
```nix
{ graphical, gaming, ... }:
{
  # Conditional based on feature flags
  config = lib.mkIf gaming {
    programs.steam.enable = true;
  };
  
  services.xserver.enable = lib.mkIf graphical true;
}
```

## Host-Specific vs Platform-Specific

**Platform-specific**: Different between macOS and Linux (use platform guards or platform-specific modules)
- Example: Aerospace (macOS only), systemd services (Linux only)
- Implement in: Shared programs with `lib.mkIf isDarwin`, platform modules, or conditional imports

**Host-specific**: Different between individual machines (use `modules/{platform}/hosts/{hostname}/`)
- Example: Git email, Discord (personal only), work tools (work only), desktop environment (desktop only)
- Home-manager: `modules/home-manager/hosts/{hostname}/`
- NixOS: `modules/nixos/hosts/{hostname}/`

**Both**: Can be both platform AND host-specific
- Example: Aerospace (macOS + personal/work Macs only), Niri (NixOS + desktop only)
- Implement: Use host-specific modules with internal platform guards if needed
