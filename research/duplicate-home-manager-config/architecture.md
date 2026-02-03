# Architecture Diagram: Duplicate Module Import Problem

## Current System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          flake.nix (ROOT)                              │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                ┌───────────────────┼───────────────────┐
                │                   │                   │
                ▼                   ▼                   ▼
    ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
    │ darwinConfigs    │  │ nixosConfigs     │  │ homeConfigs      │
    └──────────────────┘  └──────────────────┘  └──────────────────┘
                │                   │                   │
        ┌───────┴────────┐          │                   │
        │                │          │                   │
        ▼                ▼          ▼                   ▼
    personal-mac    work-mac   nixos-desktop        wanda
    -dendritic      -dendritic  -dendritic          -dendritic
        .nix           .nix        .nix                .nix
```

## Import Tree: nixos-desktop-dendritic.nix (THE PROBLEM)

```
nixos-desktop-dendritic.nix
│
├─ [DENDRITIC] inputs.self.modules.homeManager.bat
├─ [DENDRITIC] inputs.self.modules.homeManager.eza
├─ [DENDRITIC] inputs.self.modules.homeManager.fzf
├─ [DENDRITIC] inputs.self.modules.homeManager.git
├─ [DENDRITIC] inputs.self.modules.homeManager.ripgrep
├─ [DENDRITIC] inputs.self.modules.homeManager.zoxide
├─ [DENDRITIC] inputs.self.modules.homeManager.fd
├─ inputs.catppuccin.homeModules.catppuccin
│
└─ [LEGACY BRIDGE] ../hosts/nixos/nixos-desktop
   │
   └─ hosts/nixos/nixos-desktop/default.nix
      │
      └─ home-manager.users.michael = {
         │
         └─ imports = [
            │
            ├─ ../../../modules-legacy/home-manager/home.nix
            │  │
            │  └─ imports = [ ./programs ]
            │     │
            │     └─ modules-legacy/home-manager/programs/default.nix
            │        │
            │        └─ imports = [
            │           ├─ [LEGACY] ./bat.nix           ← DUPLICATE ✗
            │           ├─ [LEGACY] ./eza.nix           ← DUPLICATE ✗
            │           ├─ [LEGACY] ./fzf.nix           ← DUPLICATE ✗
            │           ├─ [LEGACY] ./git.nix           ← DUPLICATE ✗
            │           ├─ [LEGACY] ./ripgrep.nix       ← DUPLICATE ✗
            │           ├─ [LEGACY] ./zoxide.nix        ← DUPLICATE ✗
            │           └─ ... (other programs)
            │           ]
            │
            └─ ../../../modules-legacy/home-manager/hosts/nixos-desktop/default.nix
         ]
      }
```

## Import Tree: wanda-dendritic.nix (THE PROBLEM)

```
wanda-dendritic.nix
│
├─ [DENDRITIC] inputs.self.modules.homeManager.bat
├─ [DENDRITIC] inputs.self.modules.homeManager.eza
├─ [DENDRITIC] inputs.self.modules.homeManager.fzf
├─ [DENDRITIC] inputs.self.modules.homeManager.git
├─ [DENDRITIC] inputs.self.modules.homeManager.ripgrep
├─ [DENDRITIC] inputs.self.modules.homeManager.zoxide
├─ [DENDRITIC] inputs.self.modules.homeManager.fd
├─ inputs.catppuccin.homeModules.catppuccin
│
└─ [LEGACY BRIDGE] ../hosts/ubuntu/wanda.nix
   │
   └─ imports = [
      │
      ├─ ../../modules-legacy/home-manager/home.nix
      │  │
      │  └─ imports = [ ./programs ]
      │     │
      │     └─ modules-legacy/home-manager/programs/default.nix
      │        │
      │        └─ imports = [
      │           ├─ [LEGACY] ./bat.nix           ← DUPLICATE ✗
      │           ├─ [LEGACY] ./eza.nix           ← DUPLICATE ✗
      │           ├─ [LEGACY] ./fzf.nix           ← DUPLICATE ✗
      │           ├─ [LEGACY] ./git.nix           ← DUPLICATE ✗
      │           ├─ [LEGACY] ./ripgrep.nix       ← DUPLICATE ✗
      │           ├─ [LEGACY] ./zoxide.nix        ← DUPLICATE ✗
      │           └─ ... (other programs)
      │           ]
      │
      └─ ../../modules-legacy/home-manager/hosts/wanda
   ]
```

## Import Tree: personal-mac-dendritic.nix (WORKING - NO DUPLICATES)

```
personal-mac-dendritic.nix
│
├─ [DENDRITIC] inputs.self.modules.homeManager.bat
├─ [DENDRITIC] inputs.self.modules.homeManager.eza
├─ [DENDRITIC] inputs.self.modules.homeManager.fzf
├─ [DENDRITIC] inputs.self.modules.homeManager.git
├─ [DENDRITIC] inputs.self.modules.homeManager.ripgrep
├─ [DENDRITIC] inputs.self.modules.homeManager.zoxide
├─ [DENDRITIC] inputs.self.modules.homeManager.fd
├─ inputs.catppuccin.homeModules.catppuccin
│
└─ [SYSTEM ONLY - NO HOME-MANAGER] ../modules-legacy/homebrew/hosts/personal-mac.nix
   │
   └─ Only homebrew packages, NO home-manager modules ✓
```

## Module Export: inputs.self.modules.homeManager

```
┌──────────────────────────────────────────────────────────┐
│ flake-parts/import-tree modules/features/                │
└──────────────────────────────────────────────────────────┘
          │
          ├─ modules/features/bat.nix
          ├─ modules/features/eza.nix
          ├─ modules/features/fzf.nix
          ├─ modules/features/fd.nix
          ├─ modules/features/git.nix
          ├─ modules/features/ripgrep.nix
          └─ modules/features/zoxide.nix
                      │
                      ▼
          Exported as:
          inputs.self.modules.homeManager.bat
          inputs.self.modules.homeManager.eza
          inputs.self.modules.homeManager.fzf
          inputs.self.modules.homeManager.fd
          inputs.self.modules.homeManager.git
          inputs.self.modules.homeManager.ripgrep
          inputs.self.modules.homeManager.zoxide
```

## Module Export: modules-legacy/home-manager/programs

```
┌──────────────────────────────────────────────────────────┐
│ modules-legacy/home-manager/programs/default.nix         │
└──────────────────────────────────────────────────────────┘
          │
          └─ imports = [
             ├─ ./bat.nix
             ├─ ./eza.nix
             ├─ ./fzf.nix
             ├─ ./fd.nix        (NOT migrated to dendritic)
             ├─ ./git.nix
             ├─ ./ripgrep.nix
             ├─ ./zoxide.nix
             └─ ... (36 other programs)
             ]
                      │
                      ▼
          Loaded by:
          home-manager.users.michael = {
            imports = [
              modules-legacy/home-manager/home.nix
            ]
          }
```

## The Fix: Remove Legacy Bridge

```
BEFORE (BROKEN):
─────────────────
nixos-desktop-dendritic.nix
├─ DENDRITIC modules        ← imports bat, eza, fzf, etc.
└─ Legacy bridge            ← ALSO imports bat, eza, fzf, etc.
   └─ DUPLICATE ERROR ✗


AFTER (FIXED):
──────────────
nixos-desktop-dendritic.nix
├─ DENDRITIC modules        ← imports bat, eza, fzf, etc. ONLY
├─ NixOS system config      ← moved from legacy bridge
└─ No legacy bridge         ✓ NO DUPLICATES
```

## File Modification Requirements

### Change 1: nixos-desktop-dendritic.nix
```nix
# REMOVE (lines 64-65):
    # Legacy bridge - brings in all the NixOS system config
    ../hosts/nixos/nixos-desktop

# ADD (into modules list):
    {
      # User configuration (from hosts/nixos/nixos-desktop/default.nix line 26-39)
      users.users.${user} = {
        isNormalUser = true;
        home = "/home/${user}";
        description = "Michael Holtzscher";
        extraGroups = ["wheel" "networkmanager" "docker"];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = sshPublicKeys;
      };
      
      # ... (rest of system config from default.nix)
    }
```

### Change 2: wanda-dendritic.nix
```nix
# REMOVE (lines 34-35):
    # Legacy bridge
    ../hosts/ubuntu/wanda.nix

# The home-manager config is already complete, nothing to port
```

### Change 3: Keep for Cleanup
- Delete `hosts/darwin/personal-mac.nix` (unused)
- Delete `hosts/darwin/work-mac.nix` (unused)
- Can keep legacy modules for reference but they won't be imported
