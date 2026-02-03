# Dendritic Pattern Modules

This directory contains Nix configuration following the [Dendritic Pattern](https://github.com/mightyiam/dendritic).

## Pattern Overview

**Every `.nix` file is a flake-parts module.** This means each file:
- Is automatically imported by `import-tree`
- Can define options and config
- Can contribute to multiple configuration types (NixOS, Darwin, home-manager)
- Uses `flake.modules.*` to export configuration modules

## Directory Structure

```
modules/
├── hosts/           # Host-specific configurations
│   ├── personal-mac.nix
│   ├── work-mac.nix
│   ├── nixos-desktop.nix
│   └── wanda.nix
└── features/        # Feature modules (cross-cutting concerns)
    ├── git.nix
    ├── zsh.nix
    ├── bat.nix
    └── ...
```

## Writing a Feature Module

Each feature module should:

1. **Define options** for configuration under `options.myFeatures.<name>`
2. **Export to appropriate flake module types** using `flake.modules.*`
3. **Use `lib.mkIf`** to conditionally enable based on options

Example:

```nix
{ config, lib, ... }:
let
  cfg = config.myFeatures.bat;
in
{
  options.myFeatures.bat = {
    enable = lib.mkEnableOption "bat configuration";
    theme = lib.mkOption {
      type = lib.types.str;
      default = "Catppuccin-mocha";
    };
  };

  config = lib.mkIf cfg.enable {
    # Export to home-manager modules
    flake.modules.homeManager."my/bat" = {
      programs.bat = {
        enable = true;
        config = {
          theme = cfg.theme;
        };
      };
    };
  };
}
```

## Writing a Host Module

Host modules define the actual system configurations:

```nix
{ config, lib, inputs, ... }:
{
  flake.darwinConfigurations."Michaels-M1-Max" = 
    inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        # Import feature modules
        inputs.self.modules.darwin."my/bat"
        inputs.self.modules.darwin."my/git"
        # ... more features
        
        # Legacy bridge (during migration)
        ../../hosts/darwin/personal-mac.nix
      ];
    };
}
```

## Module Types

- `flake.modules.nixos.<name>` - NixOS system modules
- `flake.modules.darwin.<name>` - nix-darwin modules  
- `flake.modules.homeManager.<name>` - home-manager modules
- `flake.modules.nixvim.<name>` - NixVim modules (if used)

## Migration Status

During the migration from the legacy structure:
- Legacy configs live in `modules-legacy/`
- New dendritic configs live in `modules/`
- Both coexist until full migration is complete
- Host configs gradually transition from legacy to dendritic

## Auto-Import

Files in this directory are automatically imported by `import-tree` in `flake.nix`.
- All `.nix` files are imported
- Files/directories starting with `_` are ignored
- No manual import lists needed!
