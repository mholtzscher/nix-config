# Multi-Platform Nix Configuration

A comprehensive, multi-platform Nix flake managing both macOS (Darwin) and NixOS systems with shared and host-specific configurations.

## 🖥️ Managed Systems

### macOS (Darwin)
- **Personal M1 Max** (`Michaels-M1-Max`) - Personal development machine
- **Work Mac** (`Michael-Holtzscher-Work`) - Work machine

### NixOS
- **Desktop** (`nixos`) - Gaming and development workstation with Hyprland/Niri

## ✨ Features

- **Multi-Platform Support** - Single flake manages both macOS and NixOS
- **Host-Specific Configs** - Per-host customization (git email, programs, etc.)
- **Platform Guards** - Conditional config for macOS-only or Linux-only features
- **36 Cross-Platform Programs** - Extensive home-manager program configurations
- **Dual Compositor Support** - Hyprland and Niri (scrollable tiling) with shared configs
- **Gaming Optimized** - Steam, gamemode, performance tuning, NVIDIA support
- **Security Hardened** - SSH key-only auth, fail2ban, restricted firewall
- **Shared Modules** - DRY principle with reusable cross-platform modules
- **Automatic GC** - Weekly garbage collection (Sundays 2AM, 30-day retention)

## 📁 Structure

```
├── flake.nix                    # Root flake defining all hosts
├── lib/
│   └── default.nix              # Helper functions for system creation
├── hosts/
│   ├── darwin/                  # macOS-specific hosts
│   │   ├── personal-mac.nix
│   │   └── work-mac.nix
│   └── nixos/                   # NixOS-specific hosts
│       └── desktop.nix
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
│   │   └── nixos.nix            # System config (boot, services, etc.)
│   ├── shared/                  # Cross-platform modules
│   │   ├── nix-settings.nix     # Nix config (flakes, gc, etc.)
│   │   └── users.nix
│   └── home-manager/            # Cross-platform home-manager
│       ├── home.nix             # Main config with platform guards
│       ├── packages.nix         # Platform-aware package list
│       ├── hosts/               # Host-specific configs
│       │   ├── personal-mac.nix
│       │   ├── work-mac.nix
│       │   └── desktop/         # NixOS desktop-specific configs
│       │       ├── default.nix
│       │       ├── gaming.nix    # Gaming packages & config
│       │       ├── hyprland.nix  # Hyprland compositor
│       │       ├── hyprpanel.nix # Status bar (Hyprland)
│       │       ├── niri.nix      # Niri scrollable compositor
│       │       ├── theme.nix     # Theming (GTK/Qt)
│       │       ├── vicinae.nix   # App launcher (Hyprland/Niri)
│       │       ├── waybar.nix    # Status bar (Niri)
│       │       ├── webapps.nix   # Web apps as native apps
│       │       └── wofi.nix      # Legacy app launcher
│       ├── programs/            # 36 cross-platform programs
│       └── files/               # Dotfiles
```

## 🚀 Quick Start

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
nixos-rebuild build --flake ~/.config/nix-config#nixos

# Apply changes
sudo nixos-rebuild switch --flake ~/.config/nix-config#nixos
```

## 📦 Adding Programs

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

## 🏠 Adding New Hosts

### Darwin Host

1. Create `hosts/darwin/hostname.nix`:

```nix
{ pkgs, inputs, ... }:
let
  user = "username";
in
{
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

  # Homebrew, nix-homebrew, system settings...
}
```

2. Create `modules/home-manager/hosts/hostname.nix` for host-specific config
3. Add to `flake.nix`:

```nix
darwinConfigurations.hostname = nixpkgs.lib.darwinSystem {
  specialArgs = { inherit inputs self; };
  modules = [
    ./hosts/darwin/hostname.nix
    ./modules/darwin
    ./modules/shared
    # ...
  ];
};
```

### NixOS Host

1. Create `hosts/nixos/hostname.nix` with hardware config
2. Create `modules/home-manager/hosts/hostname.nix`
3. Add to `flake.nix`:

```nix
nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs self; };
  modules = [
    ./hosts/nixos/hostname.nix
    ./modules/nixos
    ./modules/shared
    inputs.home-manager.nixosModules.home-manager
  ];
};
```

## 🎯 Platform Detection Patterns

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

## 🔧 Configuration

### Platform-Specific vs Host-Specific

**Platform-specific**: Different between macOS and Linux
- Use: `lib.mkIf pkgs.stdenv.isDarwin` or `lib.optionalAttrs`
- Example: Aerospace (macOS), systemd (Linux)

**Host-specific**: Different between individual machines
- Use: `modules/home-manager/hosts/*.nix`
- Example: Git email, Discord (personal only), work tools

**Both**: Can be both platform AND host-specific
- Example: Aerospace (macOS, both Macs)

### Desktop Environment vs Cross-Platform Programs

**Desktop Environment Configs** (host-specific):
- Configs specific to Wayland compositors (Hyprland, Niri)
- Located in `modules/home-manager/hosts/desktop/` for NixOS desktop
- Include compositor, status bar (Hyprpanel/Waybar), app launcher (Vicinae)
- Gaming configs, themes, and web apps
- No platform guards needed (already in host directory)

**Cross-Platform Programs** (programs/):
- Tools that work across macOS and NixOS with minimal differences
- Located in `modules/home-manager/programs/`
- Use platform guards if behavior differs significantly

### Host Differences

| Feature | Personal Mac | Work Mac | Desktop |
|---------|-------------|----------|---------|
| Aerospace (WM) | ✅ | ✅ | ❌ |
| Hyprland/Niri (WM) | ❌ | ❌ | ✅ |
| Gaming (Steam) | ❌ | ❌ | ✅ |
| Discord | ✅ | ❌ | ✅ |
| Git Email | Personal | Work | Personal |
| Platform | macOS | macOS | Linux |

## 📚 Documentation

- **[AGENTS.md](./AGENTS.md)** - Comprehensive guidelines for AI agents
- **[docs/nixos-migration-plan.md](./docs/nixos-migration-plan.md)** - Migration history and plan

## 🛠️ Common Commands

```bash
# Validate
nb                    # Darwin build
nix flake check       # Check all platforms

# Apply
nup                   # Darwin switch (user only)
sudo nixos-rebuild switch --flake .#nixos    # NixOS

# Update
nfu                   # Update flake inputs

# Format
nf <file>.nix         # Format nix file
```

## ⚠️ Important Notes

- **Never run `darwin-rebuild switch` directly** — Validate with `nb`, then apply with `nup`
- **Platform guards are critical** - Always use for platform-specific features
- **Host configs override shared** - Use `lib.mkDefault` in shared configs
- **Git tree dirty warnings** - Normal during development, commit changes for clean builds

## 🎨 Included Configurations

### Cross-Platform Programs (34 Modules + Utilities)
**Program Modules (home-manager):**
- **Shells**: zsh, nushell
- **Editors**: helix, zed
- **Git**: git, gh, gh-dash, jujutsu, lazygit, delta
- **Terminal**: ghostty, zellij, starship
- **Dev Tools**: go, poetry, pyenv, uv
- **Cloud**: opencode (CLI for Claude)
- **Utils**: atuin, bat, bottom, btop, eza, fd, fzf, jq, k9s, lazydocker, ripgrep, zoxide
- **Web**: firefox, webapps
- **System**: ssh, carapace (shell completions)

**Additional Packages:**
- **Editors**: neovim, vim
- **Languages**: node (nodejs_24), bun, zig, lua
- **Tools**: buf, dive, dust, grpcurl, gum, hey, httpie, jc, just, kdlfmt, kubernetes-helm, nil, nixfmt-rfc-style, sops, statix, tldr, topiary, tree-sitter, websocat, wget, yq
- **Special**: beads (AI-supervised issue tracker), bd CLI

**macOS Only:**
- **Window Manager**: aerospace (via Raycast scripts)

### Wayland Compositors (NixOS Desktop)
- **Hyprland**: Dynamic tiling Wayland compositor with NVIDIA optimizations
  - Hyprpanel: Modern status bar with workspace info
  - Custom keybindings and window rules
- **Niri**: Scrollable tiling Wayland compositor (flake-based)
  - Waybar: Minimalist status bar
  - Shared configs with Hyprland where applicable
- **Shared**: Vicinae app launcher, Greetd/tuigreet login

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

## 📄 License

Personal configuration - use as reference or template.

## 🤝 Contributing

This is a personal configuration, but feel free to use it as inspiration for your own setup!

## 🔌 Flake Inputs

### Core
- **nixpkgs**: NixOS/nixpkgs (unstable channel)
- **nix-darwin**: macOS system management
- **home-manager**: User environment management
- **nix-homebrew**: Declarative Homebrew on macOS

### Enhancements
- **beads**: AI-supervised issue tracking CLI
- **vicinae**: Modern Wayland app launcher
- **catppuccin**: Catppuccin color scheme integration
- **nix-colors**: Color scheme framework

### Resources (non-flake)
- **naws**: AWS CLI wrapper utilities
- **topiary-nushell**: Nushell formatter for Topiary
- **ghostty-shader-playground**: Ghostty terminal shaders

---

**Built with** [Nix](https://nixos.org/) • [nix-darwin](https://github.com/LnL7/nix-darwin) • [home-manager](https://github.com/nix-community/home-manager) • [Hyprland](https://hyprland.org/) • [Niri](https://github.com/YaLTeR/niri)
