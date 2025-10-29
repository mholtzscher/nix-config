# AGENTS.md

Agent guidelines for this multi-platform Nix flake configuration managing:
- **macOS**: Personal M1 Max (`Michaels-M1-Max`) and Work Mac (`Michael-Holtzscher-Work`)
- **NixOS**: Desktop (`desktop`)

## Critical Safety Rules

**NEVER apply nix changes directly.** Only validate configurations using build commands.

### Allowed Commands

- ✅ `nb` or `darwin-rebuild build --flake ~/.config/nix-darwin` - Validate configuration
- ✅ `nix flake check` - Check syntax
- ✅ `nix flake update` - Update inputs (when explicitly requested)

### Forbidden Commands

- ❌ `darwin-rebuild switch` or `nup` - NEVER apply changes without explicit user approval
- ❌ `sudo darwin-rebuild switch` - NEVER

### Workflow

1. Make changes
2. Validate with `nb`
3. Report errors if build fails
4. Wait for user to run `nup` to apply

## Quick Reference

### Commands

```bash
nb                                      # Validate configuration
nup                                     # Apply configuration (user only)
nfu                                     # Update inputs
nix flake check                         # Check syntax
nf <file>.nix                           # Format nix files
```

### File Structure

```
flake.nix                              # Root flake, defines all hosts
lib/
  └── default.nix                      # Helper functions for system creation
hosts/
  ├── darwin/                          # macOS-specific hosts
  │   ├── personal-mac.nix             # Personal M1 Max config
  │   └── work-mac.nix             # Work Mac config
  └── nixos/                           # NixOS-specific hosts
      └── desktop.nix                  # NixOS desktop config
modules/
  ├── darwin/                          # macOS-only modules
  │   ├── default.nix
  │   ├── darwin.nix                   # System defaults (dock, finder, trackpad)
  │   └── homebrew.nix                 # Homebrew config
  ├── nixos/                           # NixOS-only modules
  │   ├── default.nix
  │   └── nixos.nix                    # NixOS system config
  ├── shared/                          # Cross-platform modules
  │   ├── default.nix
  │   ├── nix-settings.nix             # Shared nix config (gc, flakes, etc.)
  │   └── users.nix                    # User management patterns
  └── home-manager/                    # Cross-platform home-manager
      ├── home.nix                     # Entry point (with platform guards)
      ├── packages.nix                 # Nix packages (platform-aware)
      ├── hosts/                       # Host-specific configs
      │   ├── personal-mac.nix         # Personal Mac programs/settings
      │   ├── work-mac.nix             # Work Mac programs/settings
      │   └── desktop.nix              # NixOS desktop programs/settings
      ├── programs/                    # 41+ program configs
      └── files/                       # Dotfiles
```

### Key Concepts

- **Flake inputs**: nixpkgs (unstable), nix-darwin, home-manager, nix-homebrew
- **Module loading**:
  - **Darwin**: Host → darwin modules → shared modules → nix-homebrew → home-manager
  - **NixOS**: Host → nixos modules → shared modules → home-manager
- **Platform separation**:
  - `modules/darwin/` - macOS-only (Homebrew, system defaults)
  - `modules/nixos/` - NixOS-only (systemd, boot, services)
  - `modules/shared/` - Cross-platform (nix settings, gc)
  - `modules/home-manager/` - Mostly cross-platform (with platform guards)
- **Host-specific configs**: Each host imports its own `modules/home-manager/hosts/*.nix`
- **Platform guards**: Use `lib.mkIf pkgs.stdenv.isDarwin` or `lib.optionalAttrs` for conditional config
- **Garbage collection**: Automatic weekly on Sundays at 2:00 AM (30 day retention)

## Common Tasks

### Add Program (Cross-Platform)

1. Create `modules/home-manager/programs/program-name.nix`
2. Import in `modules/home-manager/programs/default.nix`
3. If macOS-only, wrap with `config = lib.mkIf pkgs.stdenv.isDarwin { ... }`
4. Validate with `nb` (darwin) or `nix flake check` (both platforms)

### Add Program (Host-Specific)

1. Add to appropriate `modules/home-manager/hosts/*.nix`:
   - `personal-mac.nix` - Personal Mac only
   - `work-mac.nix` - Work Mac only
   - `desktop.nix` - NixOS desktop only
2. Validate with `nb` or `nix flake check`

### Add Host (Darwin)

1. Create `hosts/darwin/hostname.nix` (copy existing)
2. Create `modules/home-manager/hosts/hostname.nix` for host-specific config
3. Add `darwinConfigurations.hostname` in `flake.nix`
4. Match system hostname with config name

### Add Host (NixOS)

1. Create `hosts/nixos/hostname.nix` (copy desktop.nix template)
2. Create `modules/home-manager/hosts/hostname.nix` for host-specific config
3. Add `nixosConfigurations.hostname` in `flake.nix`
4. Set correct `system` architecture (e.g., `x86_64-linux`)
5. Update hardware configuration (filesystems, boot, etc.)

### Modify System Settings

**macOS** - Edit `modules/darwin/darwin.nix`:
- Dock settings
- Finder preferences
- Trackpad behavior
- App-specific defaults

**NixOS** - Edit `modules/nixos/nixos.nix` or host file:
- System packages
- Services
- Boot configuration
- Desktop environment

### Add Packages

- **Cross-platform Nix**: `modules/home-manager/packages.nix` (main list)
- **macOS-only Nix**: `modules/home-manager/packages.nix` (in `lib.optionals pkgs.stdenv.isDarwin`)
- **Homebrew** (macOS only): Host files under `homebrew.brews`/`homebrew.casks`
- **Host-specific**: Add to `modules/home-manager/hosts/*.nix`

## Platform-Specific Guidelines

### macOS-Only Features

These should use platform guards or stay in darwin modules:
- Homebrew (stays in host files)
- Aerospace window manager (platform guarded in programs/aerospace.nix)
- macOS system defaults (stays in modules/darwin/darwin.nix)
- Raycast scripts (platform guarded in home.nix)
- macOS-specific paths (Library/*, platform guarded)

### NixOS-Only Features

These stay in nixos modules or use `pkgs.stdenv.isLinux`:
- systemd services
- Boot loader configuration
- Linux kernel modules
- Desktop environment configs (GDM, GNOME, etc.)

### Cross-Platform with Conditions

Use platform detection in home-manager:
```nix
# For files
home.file = { /* shared files */ }
  // lib.optionalAttrs pkgs.stdenv.isDarwin { /* macOS files */ };

# For programs
config = lib.mkIf pkgs.stdenv.isDarwin {
  programs.aerospace = { /* config */ };
};

# For activation
activation = lib.mkIf pkgs.stdenv.isDarwin { /* macOS activation */ };
```

## Host-Specific vs Platform-Specific

**Platform-specific**: Different between macOS and Linux (use platform guards)
- Example: Aerospace (macOS), systemd (Linux)

**Host-specific**: Different between individual machines (use host configs)
- Example: Git email, Discord (personal only), work tools (work only)

**Both**: Can be both platform AND host-specific
- Example: Aerospace (macOS + personal Mac only)
