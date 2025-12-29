# AGENTS.md

Agent guidelines for this multi-platform Nix flake configuration managing:
- **macOS**: Personal M1 Max (`Michaels-M1-Max`) and Work Mac (`Michael-Holtzscher-Work`)
- **NixOS**: Desktop (`nixos-desktop`) - Gaming and development workstation with Niri
- **NixOS**: Headless (`wanda`) - Services + NAS gateway

**Architecture**: Dendritic Pattern with Flake-Parts

## Critical Safety Rules

**NEVER apply nix changes directly.** Only validate configurations using build commands.

### Allowed Commands

- ✅ `nix flake check` - Check syntax
- ✅ `darwin-rebuild build --flake ~/.config/nix-config` - Validate macOS config
- ✅ `nixos-rebuild build --flake ~/.config/nix-config` - Validate NixOS config

### Forbidden Commands

- ❌ `darwin-rebuild switch` - NEVER apply changes without explicit user approval
- ❌ `sudo darwin-rebuild switch` - NEVER
- ❌ `nixos-rebuild switch` - NEVER apply NixOS changes without approval

### Workflow

1. Make changes
2. Validate with `nix flake check` and/or `darwin-rebuild build`
3. Report errors if build fails
4. Wait for user to run `nup` or `nixos-rebuild switch` to apply

## Quick Reference

### Commands

```bash
nix flake check                         # Check syntax
darwin-rebuild build --flake .         # Validate macOS config
nixos-rebuild build --flake .          # Validate NixOS config
nf <file>.nix                           # Format nix files
```

### File Structure (Dendritic)

```
flake.nix                                    # Auto-imports all features via import-tree
modules/                                     # All features (auto-imported)
├── nix/                                     # Nix infrastructure
│   ├── flake-parts [FP]                     # Flake-parts setup + lib
│   │   ├── default.nix                      # Main setup
│   │   └── lib.nix                          # mkNixos, mkDarwin helpers
│   └── tools/
│       ├── home-manager [NDnd]              # HM integration
│       ├── homebrew [D]                     # Darwin homebrew
│       └── catppuccin [NDnd]                # Theming
│
├── system/                                  # System-level features
│   ├── types/
│   │   ├── system-default [NDnd]            # Base defaults
│   │   ├── system-cli [NDnd]                # CLI-focused (inherits default)
│   │   └── system-desktop [Nnd]             # Desktop (inherits cli)
│   └── settings/
│       ├── constants [NDnd]                 # Constants (isWork, etc.)
│       ├── nix-settings [NDnd]              # Nix gc, flakes, cachix
│       └── security [N]                     # fail2ban, sudo
│
├── programs/                                # Application features (grouped)
│   ├── shell [NDnd]                         # Shell environment
│   ├── git [NDnd]                           # Version control
│   ├── editor [nd]                          # Code editors
│   ├── terminal [nd]                        # Terminal emulators
│   ├── cli-tools [nd]                       # CLI utilities
│   ├── dev-tools [nd]                       # Development
│   ├── devops [nd]                          # DevOps tools
│   ├── browser [nd]                         # Browsers
│   ├── ai-tools [nd]                        # AI/coding assistants
│   └── ssh [nd]                             # SSH configuration
│
├── desktop/                                 # Desktop environment (NixOS)
│   ├── niri [N]                             # Niri window manager
│   ├── waybar [n]                           # Status bar
│   ├── vicinae [N]                          # App launcher
│   ├── wallpaper [N]                        # Wallpaper daemon
│   ├── webapps [n]                          # Web apps as native
│   └── aerospace [D]                        # macOS window manager
│
├── services/                                # System services
│   ├── 1password [ND]                       # 1Password
│   └── gaming [N]                           # Gaming (Steam, etc.)
│
├── hosts/                                   # Host features
│   ├── personal-mac [D]                     # Personal Darwin
│   ├── work-mac [D]                         # Work Darwin
│   ├── nixos-desktop [N]                    # NixOS desktop
│   └── wanda [N]                            # NixOS headless
│
└── users/                                   # User features
    └── michael [NDnd]                       # Primary user
```

**Module naming convention**: `[N]ixOS, [D]arwin, [n] Home-Manager-NixOS, [d] Home-Manager-Darwin, [NDnd] = All

## Key Concepts

- **Dendritic Pattern**: Features define themselves across multiple contexts (NixOS, Darwin, Home-Manager)
- **Bottom-up composition**: Hosts import system types, which import features
- **Auto-import**: All `modules/` automatically imported via `import-tree`
- **Feature modules**: Self-contained in feature directories with all related config and files
- **Module classes**: `flake.modules.nixos`, `flake.modules.darwin`, `flake.modules.homeManager`, `flake.modules.generic`
- **Helper functions**: `inputs.self.lib.mkNixos` and `inputs.self.lib.mkDarwin` for creating configs

### System Type Hierarchy

```
system-default (base Nix/Darwin + HM)
    ↓ (inherits)
system-cli (adds CLI programs)
    ↓ (inherits)
system-desktop (adds desktop features)
```

### Design Patterns

- **Simple Aspect**: Feature used in multiple contexts without dependencies (e.g., `git`, `shell`)
- **Multi-Context Aspect**: System-level feature that includes Home-Manager config (e.g., `niri`, `gaming`)
- **Inheritance Aspect**: Extends another feature (e.g., `system-desktop` inherits `system-cli`)
- **Constants Aspect**: Defines shared values via `config.systemConstants.*` (e.g., `isWork`, `userName`)

## Common Tasks

### Add New Feature (Simple Aspect)

1. Create `modules/category/feature-name/default.nix`
2. Define module aspects:
   ```nix
   flake.modules.homeManager.feature-name = { ... }:
     { programs.feature-name = { ... }; };
   ```
3. Auto-imported - no manual registration needed

### Add Feature to Host

1. Edit host feature: `modules/hosts/hostname/default.nix`
2. Add to imports:
   ```nix
   imports = with inputs.self.modules.{darwin|nixos}; [
     system-desktop  # or system-cli
     new-feature
   ];
   ```
3. Validate with build command

### Add Host

1. Create `modules/hosts/hostname/default.nix` with config
2. Create `modules/hosts/hostname/flake-parts.nix` to expose to flake outputs:
   ```nix
   flake.{darwin|nixos}Configurations."hostname" =
     inputs.self.lib.mk{Darwin|Nixos} "system" "hostname";
   ```
3. Validate with build command

### Modify System Settings

**macOS** - Edit `modules/darwin/` (moved to system types in dendritic)
**NixOS** - Edit appropriate module in `modules/nixos/` (restructured)

### Add Program (Cross-Platform)

1. Find/create appropriate group in `modules/programs/group-name/`
2. Create or edit `modules/programs/group-name/feature.nix`
3. Import in `modules/programs/group-name/default.nix`
4. Validate with `nix flake check`

### Add Program (Platform-Specific)

Add platform guards or use platform-specific modules:
- Use `pkgs.lib.mkIf pkgs.stdenv.isDarwin { ... }`
- Put in `modules/desktop/aerospace/` for macOS-only features
- Put in `modules/desktop/niri/` for NixOS-only features

### Access Constants

Use `config.systemConstants.*` in any module:
```nix
{ config, ... }:
{
  # Access constants defined in host
  home.packages = pkgs.lib.mkIf (!config.systemConstants.isWork) [
    pkgs.discord
  ];
}
```

## Platform-Specific Guidelines

### Dendritic vs Old Architecture

**Old (top-down)**: Host → imports modules → manual import lists
**New (dendritic)**: Features define themselves → Hosts compose features → Auto-import

**Key differences**:
- No `lib/default.nix` with `mkSystem` helper
- No manual `imports = [...]` lists in `default.nix` files
- No `hosts/` directory at root (moved to `modules/hosts/`)
- Features are self-contained with all related files
- `import-tree` handles all module imports automatically

### Module Structure

Each feature directory contains:
- `default.nix` - Main entry point (optional for simple features)
- `flakename.nix` - Individual module files
- `files/` - Dotfiles and data specific to that feature
- `flake-parts.nix` - Exposes to flake outputs (for hosts)

### Using `import-tree`

The `import-tree` tool automatically imports all `.nix` files from `modules/` into the flake. This means:
- No manual `imports = [...]` lists needed
- All features automatically available for composition
- Adding/removing features is just file operations

### Flake Outputs

Configurations are exposed in two ways:
1. **Host features**: `modules/hosts/hostname/flake-parts.nix` defines the output
2. **Helper functions**: `inputs.self.lib.mkNixos` and `inputs.self.lib.mkDarwin`

Example:
```nix
{ inputs, ... }:
{
  flake.nixosConfigurations.nixos-desktop =
    inputs.self.lib.mkNixos "x86_64-linux" "nixos-desktop";
}
```

## Constants Aspect

The `constants` aspect defines system-wide values:
- `isWork`: Boolean (personal vs work machine)
- `userName`: String (primary user name)
- `userEmail`: String (primary user email)

Set in host features:
```nix
systemConstants = {
  isWork = false;
  userName = "michael";
  userEmail = "michael@holtzscher.com";
};
```

Accessed in any feature:
```nix
{ config, ... }:
{
  programs.ssh.includes = lib.optionals (!config.systemConstants.isWork) [ ... ];
  programs.git.settings.user.email = config.systemConstants.userEmail;
}
```
