# Multi-Platform Nix Configuration

A comprehensive, multi-platform Nix flake managing both macOS (Darwin) and NixOS systems with shared and host-specific configurations.

## 🖥️ Managed Systems

### macOS (Darwin)
- **Personal M1 Max** (`Michaels-M1-Max`) - Personal development machine
- **Work Mac** (`Michael-Holtzscher-Work`) - Work machine

### NixOS
- **Desktop** (`desktop`) - NixOS desktop configuration

## ✨ Features

- **Multi-Platform Support** - Single flake manages both macOS and NixOS
- **Host-Specific Configs** - Per-host customization (git email, programs, etc.)
- **Platform Guards** - Conditional config for macOS-only or Linux-only features
- **41+ Program Configs** - Extensive home-manager program configurations
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
│   ├── darwin/                  # macOS-only modules
│   │   ├── darwin.nix           # System defaults (dock, finder, etc.)
│   │   └── homebrew.nix
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
│       │   └── desktop.nix
│       ├── programs/            # 41+ program configurations
│       └── files/               # Dotfiles
```

## 🚀 Quick Start

### macOS (Darwin)

```bash
# Validate configuration
darwin-rebuild build --flake ~/.config/nix-darwin

# Apply changes (after validation)
darwin-rebuild switch --flake ~/.config/nix-darwin

# Using aliases (if configured)
nb   # Validate
nup  # Apply
```

### NixOS

```bash
# Validate configuration
nix flake check

# Build configuration
nixos-rebuild build --flake ~/.config/nix-darwin#desktop

# Apply changes
sudo nixos-rebuild switch --flake ~/.config/nix-darwin#desktop
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
- Example: Aerospace (macOS + personal Mac only)

### Host Differences

| Feature | Personal Mac | Work Mac | Desktop |
|---------|-------------|----------|---------|
| Aerospace | ✅ | ❌ | ❌ |
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
sudo nixos-rebuild switch --flake .#desktop  # NixOS

# Update
nfu                   # Update flake inputs

# Format
nf <file>.nix         # Format nix file
```

## ⚠️ Important Notes

- **Never run `darwin-rebuild switch` directly** - Always validate with `build` first
- **Platform guards are critical** - Always use for platform-specific features
- **Host configs override shared** - Use `lib.mkDefault` in shared configs
- **Git tree dirty warnings** - Normal during development, commit changes for clean builds

## 🎨 Included Configurations

### Programs (41+)
- **Shells**: fish, zsh, nushell
- **Editors**: helix, neovim, vim, zed
- **Git**: git, gh, gh-dash, jujutsu, lazygit, delta
- **Terminal**: ghostty, wezterm, zellij, starship
- **Dev Tools**: go, poetry, pyenv, uv
- **Utils**: atuin, bat, bottom, eza, fd, fzf, jq, k9s, lazydocker, ripgrep, yazi, zoxide
- **macOS**: aerospace (window manager)

### System Configs
- **macOS**: Dock, Finder, Trackpad settings via nix-darwin
- **NixOS**: GNOME desktop, PipeWire audio, NetworkManager

## 📄 License

Personal configuration - use as reference or template.

## 🤝 Contributing

This is a personal configuration, but feel free to use it as inspiration for your own setup!

---

**Built with** [Nix](https://nixos.org/) • [nix-darwin](https://github.com/LnL7/nix-darwin) • [home-manager](https://github.com/nix-community/home-manager)
