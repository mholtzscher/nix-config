# Duplicate Configuration - CONFIRMED ROOT CAUSE

## The Problem: Exact Import Chain

### Dendritic Files Importing Legacy Modules (The Bug)

All three active dendritic host configs have a **legacy bridge import**:

```
nixos-desktop-dendritic.nix (line 65):
  ../hosts/nixos/nixos-desktop
  └─> hosts/nixos/nixos-desktop/default.nix (lines 52-54)
      └─> imports = [
            ../../../modules-legacy/home-manager/home.nix     ← CONFLICT!
            ../../../modules-legacy/home-manager/hosts/nixos-desktop/default.nix
          ]

wanda-dendritic.nix (line 35):
  ../hosts/ubuntu/wanda.nix (lines 11-13)
  └─> imports = [
        ../../modules-legacy/home-manager/home.nix            ← CONFLICT!
        ../../modules-legacy/home-manager/hosts/wanda
      ]
```

AND those same dendritic configs ALSO explicitly import dendritic modules:

```
nixos-desktop-dendritic.nix (lines 44-60):
  inputs.self.modules.homeManager.bat
  inputs.self.modules.homeManager.eza
  inputs.self.modules.homeManager.fzf
  inputs.self.modules.homeManager.ripgrep
  inputs.self.modules.homeManager.zoxide
  inputs.self.modules.homeManager.fd
  inputs.self.modules.homeManager.git

wanda-dendritic.nix (lines 19-29):
  inputs.self.modules.homeManager.bat
  inputs.self.modules.homeManager.eza
  inputs.self.modules.homeManager.fzf
  inputs.self.modules.homeManager.ripgrep
  inputs.self.modules.homeManager.zoxide
  inputs.self.modules.homeManager.fd
  inputs.self.modules.homeManager.git
```

## The Import Chain for nixos-desktop-dendritic

```
nixos-desktop-dendritic.nix
├─ DENDRITIC IMPORTS (lines 45-59)
│  ├─ inputs.self.modules.homeManager.bat        ✓
│  ├─ inputs.self.modules.homeManager.eza        ✓
│  ├─ inputs.self.modules.homeManager.fzf        ✓
│  ├─ inputs.self.modules.homeManager.ripgrep    ✓
│  ├─ inputs.self.modules.homeManager.zoxide     ✓
│  ├─ inputs.self.modules.homeManager.fd         ✓
│  └─ inputs.self.modules.homeManager.git        ✓
│
└─ LEGACY BRIDGE (line 65)
   └─ ../hosts/nixos/nixos-desktop
      └─ hosts/nixos/nixos-desktop/default.nix (lines 52-54)
         └─ imports = [
              ../../../modules-legacy/home-manager/home.nix
              ├─ imports = [ ./programs ]  (line 32)
              │  └─ modules-legacy/home-manager/programs/default.nix
              │     └─ imports = [
              │          ./bat.nix          ✗ CONFLICT!
              │          ./eza.nix          ✗ CONFLICT!
              │          ./fzf.nix          ✗ CONFLICT!
              │          ./git.nix          ✗ CONFLICT!
              │          ./ripgrep.nix      ✗ CONFLICT!
              │          ./zoxide.nix       ✗ CONFLICT!
              │          ... (other programs)
              │        ]
              │
              ../../../modules-legacy/home-manager/hosts/nixos-desktop/default.nix
            ]
```

## The Import Chain for wanda-dendritic

```
wanda-dendritic.nix
├─ DENDRITIC IMPORTS (lines 20-29)
│  ├─ inputs.self.modules.homeManager.bat        ✓
│  ├─ inputs.self.modules.homeManager.eza        ✓
│  ├─ inputs.self.modules.homeManager.fzf        ✓
│  ├─ inputs.self.modules.homeManager.ripgrep    ✓
│  ├─ inputs.self.modules.homeManager.zoxide     ✓
│  ├─ inputs.self.modules.homeManager.fd         ✓
│  └─ inputs.self.modules.homeManager.git        ✓
│
└─ LEGACY BRIDGE (line 35)
   └─ ../hosts/ubuntu/wanda.nix (lines 11-13)
      └─ imports = [
           ../../modules-legacy/home-manager/home.nix
           ├─ imports = [ ./programs ]  (line 32)
           │  └─ modules-legacy/home-manager/programs/default.nix
           │     └─ imports = [
           │          ./bat.nix          ✗ CONFLICT!
           │          ./eza.nix          ✗ CONFLICT!
           │          ./fzf.nix          ✗ CONFLICT!
           │          ./git.nix          ✗ CONFLICT!
           │          ./ripgrep.nix      ✗ CONFLICT!
           │          ./zoxide.nix       ✗ CONFLICT!
           │          ... (other programs)
           │        ]
           │
           ../../modules-legacy/home-manager/hosts/wanda
         ]
```

## Files Creating Duplicates

| Conflict | Dendritic Location | Legacy Location | Status |
|----------|-------------------|-----------------|--------|
| bat | `modules/features/bat.nix` | `modules-legacy/home-manager/programs/bat.nix` | **BOTH IMPORTED** |
| eza | `modules/features/eza.nix` | `modules-legacy/home-manager/programs/eza.nix` | **BOTH IMPORTED** |
| fzf | `modules/features/fzf.nix` | `modules-legacy/home-manager/programs/fzf.nix` | **BOTH IMPORTED** |
| git | `modules/features/git.nix` | `modules-legacy/home-manager/programs/git.nix` | **BOTH IMPORTED** |
| ripgrep | `modules/features/ripgrep.nix` | `modules-legacy/home-manager/programs/ripgrep.nix` | **BOTH IMPORTED** |
| zoxide | `modules/features/zoxide.nix` | `modules-legacy/home-manager/programs/zoxide.nix` | **BOTH IMPORTED** |

## Why personal-mac-dendritic.nix Works

`personal-mac-dendritic.nix` does NOT import the legacy bridge:
- ✅ No import of `../hosts/darwin/personal-mac.nix`
- ✅ Only imports dendritic modules
- ✅ Only imports system-specific homebrew config

Result: No duplicates!

## Solutions

### Solution 1: Remove Legacy Bridges (RECOMMENDED)
The cleanest fix - delete the legacy bridge imports from dendritic files:

**nixos-desktop-dendritic.nix (line 64-65)**: Delete these lines
```nix
    # Legacy bridge - brings in all the NixOS system config
    ../hosts/nixos/nixos-desktop
```

**wanda-dendritic.nix (line 34-35)**: Delete these lines
```nix
    # Legacy bridge
    ../hosts/ubuntu/wanda.nix
```

Then move any NixOS system-level config from `hosts/nixos/nixos-desktop/default.nix` to dendritic file (lines 1-68 of nixos-desktop-dendritic.nix).

For wanda, the home config is already complete; nothing needs to be ported.

### Solution 2: Remove Duplicates from Legacy
Remove the conflicting programs from `modules-legacy/home-manager/programs/default.nix`:

In `modules-legacy/home-manager/programs/default.nix`, remove:
- `./bat.nix`
- `./eza.nix`
- `./fzf.nix`
- `./git.nix`
- `./ripgrep.nix`
- `./zoxide.nix`

But this doesn't work because those files might still be needed by other configurations.

### Solution 3: Fix the Legacy Bridge (NOT RECOMMENDED)
Make the legacy bridge "empty" by not importing home-manager modules:

In `hosts/nixos/nixos-desktop/default.nix` (lines 42-56), replace with:
```nix
home-manager = {
  # Empty - all config comes from dendritic
};
```

This leaves legacy system config but no duplicate home-manager imports.

## Why This Matters

**Nix Error**: When two modules try to define the same program config, you get:
```
error: attribute 'bat' already defined at «location1», now at «location2»
```

Because Nix doesn't allow duplicate attribute definitions in the same set.

## Status

- **personal-mac**: ✅ WORKING (no legacy bridge)
- **work-mac**: ✅ WORKING (no legacy bridge)
- **nixos-desktop**: ❌ BROKEN (legacy bridge imported)
- **wanda**: ❌ BROKEN (legacy bridge imported)
