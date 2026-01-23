# Multi-Platform Nix Configuration

A comprehensive, multi-platform Nix flake managing both macOS (Darwin) and NixOS systems with shared and host-specific configurations.

## Prerequisites

- **Nix**: Installed with flakes support enabled
  - macOS: Install via `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
  - NixOS: Included by default
  - Enable flakes in `~/.config/nix/nix.conf`: `experimental-features = nix-command flakes`
- **Git**: For cloning and managing the configuration
- **Nix-Darwin** (macOS only): Automatically managed as a flake input
- **Home-Manager**: Automatically managed as a flake input

## Managed Systems

### macOS (Darwin)
- **Personal M1 Max** (`Michaels-M1-Max`) - Personal development machine
- **Work Mac** (`Michael-Holtzscher-Work`) - Work machine

### NixOS
- **Desktop** (`nixos-desktop`) - Gaming and development workstation with Niri compositor

## Features

- **Multi-Platform Support** - Single flake manages both macOS and NixOS
- **Host-Specific Configs** - Per-host customization (git email, programs, etc.)
- **Platform Guards** - Conditional config for macOS-only or Linux-only features
- **Comprehensive Programs** - Extensive program modules and utilities via home-manager
- **Niri Compositor** - Scrollable tiling Wayland compositor with shared configs
- **Gaming Optimized** - Steam, gamemode, performance tuning, NVIDIA support
- **Security Hardened** - SSH key-only auth, fail2ban, restricted firewall
- **Shared Modules** - DRY principle with reusable cross-platform modules
- **Automatic GC** - Weekly garbage collection (Sundays 2AM, 30-day retention)

## Structure

```
├── flake.nix                    # Root flake defining all hosts
├── lib/
│   └── default.nix              # Helper functions for system creation
├── hosts/
│   ├── darwin/                  # macOS-specific hosts
│   │   ├── personal-mac.nix
│   │   └── work-mac.nix
│   └── nixos/                   # NixOS-specific hosts
│       ├── nixos-desktop.nix
│       └── hardware-configuration.nix
├── modules/
│   ├── darwin/                  # macOS system defaults
│   │   ├── default.nix          # Entry point
│   │   └── darwin.nix           # System defaults (dock, finder, etc.)
│   ├── homebrew/                # Homebrew package management (macOS only)
│   │   ├── default.nix          # Common packages across all macOS hosts
│   │   └── hosts/               # Host-specific Homebrew packages
│   │       ├── personal-mac.nix
│   │       └── work-mac.nix
│   ├── nixos/                   # NixOS-only modules
│   │   ├── default.nix
│   │   ├── fonts.nix            # Fonts (cross-NixOS)
│   │   ├── nixos.nix            # System config (boot, services, etc.)
│   │   └── hosts/               # Host-specific NixOS system config
│   │       └── nixos-desktop/   # Desktop environment modules
│   │           ├── default.nix  # Entry point
│   │           ├── composition.nix # Niri + Waybar
│   │           ├── launcher.nix # Vicinae app launcher
│   │           ├── gaming.nix   # Gaming (Steam, MangoHud, etc.)
│   │           ├── theme.nix    # GTK/Qt theming & dark mode
│   │           ├── wallpaper.nix # Wallpaper daemon (swaybg)
│   │           └── webapps.nix  # Web apps as native apps
│   ├── shared/                  # Cross-platform modules
│   │   ├── default.nix
│   │   ├── nix-settings.nix     # Nix config (flakes, gc, etc.)
│   │   └── users.nix
│   └── home-manager/            # Cross-platform home-manager
│       ├── home.nix             # Main config with platform guards
│       ├── packages.nix         # Platform-aware package list
│       ├── shared-aliases.nix   # Shared shell aliases
│       ├── programs/            # 34 cross-platform program modules
│       │   ├── git.nix
│       │   ├── zsh.nix
│       │   ├── firefox.nix
│       │   └── [31 more...]
│       ├── hosts/               # Host-specific user configs
│       │   ├── personal-mac.nix
│       │   ├── work-mac.nix
│       │   └── nixos-desktop/   # Desktop user packages & config
│       │       └── default.nix
│       └── files/               # Dotfiles
```

## Quick Start

### macOS (Darwin)

```bash
# Validate configuration
darwin-rebuild build --flake ~/.config/nix-config

# Using aliases
nb   # Validate
nup  # Apply (preferred; do not use switch directly)
```

### NixOS

```bash
# Validate configuration
nix flake check

# Build configuration
nixos-rebuild build --flake ~/.config/nix-config#nixos-desktop

# Apply changes
sudo nixos-rebuild switch --flake ~/.config/nix-config#nixos-desktop
```

## Adding Programs

### Cross-Platform Program

1. Create `modules/home-manager/programs/program-name.nix`:

```nix
{ ... }:
{
  programs.program-name = {
    enable = true;
    # configuration
  };
}
```

2. Import in `modules/home-manager/programs/default.nix`
3. Validate with `darwin-rebuild build` or `nix flake check`

### macOS-Only Program

Wrap with platform guard:

```nix
{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    programs.program-name = {
      enable = true;
      # macOS-specific config
    };
  };
}
```

### Host-Specific Program

Add to appropriate `modules/home-manager/hosts/*.nix`:

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    program-name
  ];
}
```

## Adding New Hosts

This config uses a unified `lib.mkSystem` helper that handles both Darwin and NixOS with proper module loading.

### Darwin Host

1. Create `hosts/darwin/hostname.nix`:

```nix
{ pkgs, inputs, user, ... }:
{
  imports = [
    ../../modules/homebrew/hosts/hostname.nix  # Create this for host-specific packages
  ];

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${user} = { ... }: {
      imports = [
        ../../modules/home-manager/home.nix
        ../../modules/home-manager/hosts/hostname.nix
      ];
    };
  };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;  # For Apple Silicon
    inherit user;
    autoMigrate = true;
  };

  system = {
    primaryUser = user;
    defaults = {
      dock = {
        persistent-apps = [
          # Add desired apps here
        ];
      };
    };
  };
}
```

2. Create `modules/homebrew/hosts/hostname.nix` for host-specific Homebrew packages
3. Create `modules/home-manager/hosts/hostname.nix` for host-specific programs/settings
4. Add to `flake.nix`:

```nix
darwinConfigurations."System-Hostname" = lib.mkSystem {
  name = "friendly-name";              # Used in logs and module args
  system = "aarch64-darwin";           # M1/M2/M3 Macs (or x86_64-darwin for Intel)
  darwin = true;                       # Required for Darwin
  hostPath = ./hosts/darwin/hostname.nix;
  user = "username";                   # macOS username
  isWork = false;                      # Optional: true for work machine
};
```

### NixOS Host

1. Create `hosts/nixos/hostname.nix`:

```nix
{ pkgs, inputs, user, ... }:
{
  imports = [
    ./hostname-hardware.nix
  ];

  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      # Add SSH public keys here
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.${user} = { ... }: {
      imports = [
        ../../modules/home-manager/home.nix
        ../../modules/home-manager/hosts/hostname/default.nix
      ];
    };
  };
}
```

2. Create `modules/home-manager/hosts/hostname/default.nix` for host-specific user config
3. Create `modules/nixos/hosts/hostname/` directory for host-specific system config (if needed)
4. Generate hardware config: `nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos/hostname-hardware.nix`
5. Add to `flake.nix`:

```nix
nixosConfigurations.hostname = lib.mkSystem {
  name = "friendly-name";              # Used in logs and module args
  system = "x86_64-linux";             # or "aarch64-linux" for ARM
  hostPath = ./hosts/nixos/hostname.nix;
  user = "username";                   # NixOS username
  graphical = true;                    # Load GUI modules (Niri, etc.) - conditional module loading in lib/
  gaming = false;                      # Optional: true for gaming setup
};
```

**Note**: The `graphical` and `gaming` flags automatically control which modules are loaded:
- `graphical = true` → Loads `modules/nixos/hosts/hostname/` (for GUI-based hosts)
- `graphical = false` → Skips graphical modules (for headless servers)

## Platform Detection Patterns

### Conditional Files

```nix
home.file = {
  # Cross-platform files
  ".config/app/config".source = ./files/config;
}
// lib.optionalAttrs pkgs.stdenv.isDarwin {
  # macOS-only files
  "Library/Preferences/com.app.plist".source = ./files/app.plist;
};
```

### Conditional Programs

```nix
config = lib.mkIf pkgs.stdenv.isDarwin {
  programs.aerospace.enable = true;
};
```

### Conditional Packages

```nix
home.packages = with pkgs; [
  # Cross-platform
  git
  vim
]
++ lib.optionals pkgs.stdenv.isDarwin [
  # macOS-only
  aerospace
];
```

## Configuration Guidelines

### When to Use Different Module Types

**Shared Programs** (`modules/home-manager/programs/`):
- Tools that work across macOS and NixOS with minimal differences
- Use platform guards with `lib.mkIf pkgs.stdenv.isDarwin` if behavior differs
- Example: git, zsh, helix, starship

**Host-Specific Configs** (`modules/home-manager/hosts/*/`):
- Machine-specific settings (git email, Discord, work tools)
- Desktop environment configs (Niri, Waybar, Vicinae for NixOS desktop)
- Custom packages for specific hosts
- No platform guards needed (already isolated to host)

**Platform-Specific Only** (use conditional imports):
- Features only relevant to one platform
- Use `lib.mkIf pkgs.stdenv.isDarwin` for macOS-only
- Use `lib.mkIf pkgs.stdenv.isLinux` for Linux-only
- Example: Aerospace (macOS), systemd (NixOS)

### Platform-Specific vs Host-Specific

**Platform-specific**: Different between macOS and Linux
- Use: `lib.mkIf pkgs.stdenv.isDarwin` or `lib.optionalAttrs`
- Example: Aerospace (macOS), systemd (Linux)

**Host-specific**: Different between individual machines
- Use: `modules/home-manager/hosts/*.nix`
- Example: Git email, Discord (personal only), work tools

**Both**: Can be both platform AND host-specific
- Example: Aerospace (macOS, both Macs)

### Host Differences

| Feature | Personal Mac | Work Mac | Desktop |
|---------|-------------|----------|---------|
| Aerospace (WM) | Yes | Yes | No |
| Niri (WM) | No | No | Yes |
| Gaming (Steam) | No | No | Yes |
| Discord | Yes | No | Yes |
| Git Email | Personal | Work | Personal |
| Platform | macOS | macOS | Linux |

## Documentation

- **[AGENTS.md](./AGENTS.md)** - Comprehensive guidelines for AI agents
- **[docs/nixos-migration-plan.md](./docs/nixos-migration-plan.md)** - Migration history and plan

## Common Commands

```bash
# Validate
nb                                          # Darwin build
nix flake check                             # Check all platforms

# Apply
nup                                         # Darwin switch (user only)
sudo nixos-rebuild switch --flake .#nixos-desktop    # NixOS

# Update
nfu                                         # Update flake inputs

# Format
nf <file>.nix                               # Format nix file
```

## Important Notes

- **Never run `darwin-rebuild switch` directly** — Validate with `nb`, then apply with `nup`
- **Platform guards are critical** - Always use for platform-specific features
- **Host configs override shared** - Use `lib.mkDefault` in shared configs
- **Git tree dirty warnings** - Normal during development, commit changes for clean builds

## Included Configurations

### Cross-Platform Programs (34 Modules + Utilities)
**Program Modules (home-manager):**
- **Shells**: zsh, nushell
- **Editors**: helix, zed
- **Git**: git, gh, gh-dash, jujutsu, lazygit, delta
- **Terminal**: ghostty, zellij, starship
- **Dev Tools**: bun, go, poetry, pyenv, uv
- **Cloud**: opencode (CLI for Claude)
- **Utils**: atuin, bat, bottom, btop, eza, fd, fzf, jq, k9s, lazydocker, ripgrep, zoxide
- **Web**: firefox, webapps
- **System**: ssh, carapace (shell completions)

**Additional Packages:**
- **Editors**: neovim, vim
- **Browsers**: brave
- **Languages**: node (nodejs_24), zig, lua
- **Tools**: buf, dive, dust, grpcurl, gum, hey, httpie, jc, just, kdlfmt, kubernetes-helm, nil, nixfmt, sops, statix, tldr, topiary, tree-sitter, websocat, wget, yq

**macOS Only:**
- **Window Manager**: aerospace (via Raycast scripts)

### Desktop Environment (NixOS Desktop)
- **Niri**: Scrollable tiling Wayland compositor with vim-style navigation
- **Waybar**: Minimalist status bar with system metrics and window tracking
- **Vicinae**: High-performance app launcher with calculator and clipboard history
- **swaybg**: Wallpaper daemon for Wayland
- **Greetd/tuigreet**: TUI-based login manager

### Gaming Configuration (NixOS Desktop)
- **Steam**: Full Steam integration with Gamescope session
- **Performance**: Gamemode, CPU governor, vm.max_map_count tuning
- **Hardware**: NVIDIA drivers, 32-bit graphics support, Vulkan/OpenGL
- **KVM Support**: EDID override for display passthrough

### System Configs
- **macOS**: Dock, Finder, Trackpad settings, Homebrew package management
- **NixOS**: Greetd login, PipeWire audio, NetworkManager, SSH hardening, fail2ban

### Package Management
- **Homebrew** (macOS): Declarative package, cask, and app store integration via nix-homebrew
  - Common packages: taps, brews, casks, masApps across all macOS hosts
  - Host-specific: Personal and Work Mac custom packages

## License

Personal configuration - use as reference or template.

## Contributing

This is a personal configuration, but feel free to use it as inspiration for your own setup!

## Flake Inputs

### Core
- **nixpkgs**: NixOS/nixpkgs (unstable channel)
- **nix-darwin**: macOS system management
- **home-manager**: User environment management
- **nix-homebrew**: Declarative Homebrew on macOS

### Enhancements
- **vicinae**: Modern Wayland app launcher
- **catppuccin**: Catppuccin color scheme integration

### Resources (non-flake)
- **naws**: AWS CLI wrapper utilities
- **topiary-nushell**: Nushell formatter for Topiary
- **ghostty-shader-playground**: Ghostty terminal shaders

---

**Built with** [Nix](https://nixos.org/) • [nix-darwin](https://github.com/LnL7/nix-darwin) • [home-manager](https://github.com/nix-community/home-manager) • [Niri](https://github.com/YaLTeR/niri)
