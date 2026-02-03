# Duplicate Home-Manager Configuration - Debug Summary

## Executive Summary

**Root Cause**: The `nixos-desktop-dendritic.nix` and `wanda-dendritic.nix` host configuration files import both:
1. **Dendritic modules** (new pattern) - `modules/features/bat.nix`, `modules/features/eza.nix`, etc.
2. **Legacy home-manager modules** (old pattern) - `modules-legacy/home-manager/programs/bat.nix`, `modules-legacy/home-manager/programs/eza.nix`, etc.

This creates **duplicate definitions** for the same programs, causing Nix evaluation to fail with:
```
error: attribute 'bat' already defined at location1, now at location2
```

## The Problem Files

### Problem 1: nixos-desktop-dendritic.nix

**Location**: `/hosts/nixos-desktop-dendritic.nix`

**Issue**: 
- Lines 45-59: Imports dendritic modules (bat, eza, fzf, git, ripgrep, zoxide, fd)
- Line 65: Imports legacy bridge `../hosts/nixos/nixos-desktop`
  - Which imports `modules-legacy/home-manager/home.nix`
  - Which imports `modules-legacy/home-manager/programs/default.nix`
  - Which ALSO imports bat, eza, fzf, git, ripgrep, zoxide

**Result**: Both bat, eza, fzf, git, ripgrep, zoxide defined twice → ERROR

### Problem 2: wanda-dendritic.nix

**Location**: `/hosts/wanda-dendritic.nix`

**Issue**:
- Lines 20-29: Imports dendritic modules (bat, eza, fzf, git, ripgrep, zoxide, fd)
- Line 35: Imports legacy bridge `../hosts/ubuntu/wanda.nix`
  - Which imports `modules-legacy/home-manager/home.nix`
  - Which imports `modules-legacy/home-manager/programs/default.nix`
  - Which ALSO imports bat, eza, fzf, git, ripgrep, zoxide

**Result**: Both bat, eza, fzf, git, ripgrep, zoxide defined twice → ERROR

## Why personal-mac-dendritic.nix Works

**Location**: `/hosts/personal-mac-dendritic.nix`

**Why it works**:
- Lines 39-47: Imports dendritic modules (bat, eza, fzf, git, ripgrep, zoxide, fd)
- Line 69: Imports ONLY `../modules-legacy/homebrew/hosts/personal-mac.nix`
  - This file ONLY contains homebrew package definitions
  - Does NOT import home-manager modules
  - No duplicate definitions

**Result**: Only dendritic modules imported → NO ERROR ✓

## Affected Systems

| System | Status | Reason |
|--------|--------|--------|
| personal-mac | ✅ WORKING | No legacy home-manager bridge |
| work-mac | ✅ WORKING | No legacy home-manager bridge |
| nixos-desktop | ❌ BROKEN | Legacy home-manager bridge imported |
| wanda | ❌ BROKEN | Legacy home-manager bridge imported |

## Configuration Files Involved

### Conflicting Modules

| Program | Dendritic Module | Legacy Module | Status |
|---------|------------------|---------------|--------|
| bat | `modules/features/bat.nix` | `modules-legacy/home-manager/programs/bat.nix` | **DUPLICATE** |
| eza | `modules/features/eza.nix` | `modules-legacy/home-manager/programs/eza.nix` | **DUPLICATE** |
| fd | `modules/features/fd.nix` | `modules-legacy/home-manager/programs/fd.nix` | **DUPLICATE** (not in legacy default.nix imports, but fd.nix exists) |
| fzf | `modules/features/fzf.nix` | `modules-legacy/home-manager/programs/fzf.nix` | **DUPLICATE** |
| git | `modules/features/git.nix` | `modules-legacy/home-manager/programs/git.nix` | **DUPLICATE** |
| ripgrep | `modules/features/ripgrep.nix` | `modules-legacy/home-manager/programs/ripgrep.nix` | **DUPLICATE** |
| zoxide | `modules/features/zoxide.nix` | `modules-legacy/home-manager/programs/zoxide.nix` | **DUPLICATE** |

### Entry Points for Legacy Modules

**nixos-desktop**:
```
hosts/nixos/nixos-desktop/default.nix (lines 52-54)
  └─ imports = [
       ../../../modules-legacy/home-manager/home.nix (line 32)
         └─ imports = [ ./programs ]
            └─ modules-legacy/home-manager/programs/default.nix
               └─ imports = [./bat.nix, ./eza.nix, ./fzf.nix, ./git.nix, ./ripgrep.nix, ./zoxide.nix, ...]
       ../../../modules-legacy/home-manager/hosts/nixos-desktop/default.nix
     ]
```

**wanda**:
```
hosts/ubuntu/wanda.nix (lines 11-13)
  └─ imports = [
       ../../modules-legacy/home-manager/home.nix (line 32)
         └─ imports = [ ./programs ]
            └─ modules-legacy/home-manager/programs/default.nix
               └─ imports = [./bat.nix, ./eza.nix, ./fzf.nix, ./git.nix, ./ripgrep.nix, ./zoxide.nix, ...]
       ../../modules-legacy/home-manager/hosts/wanda
     ]
```

## The Fix

### Option 1: Remove Legacy Bridges (RECOMMENDED)

**nixos-desktop-dendritic.nix**:
- Delete line 64-65 (the legacy bridge comment and import)
- Port necessary system config from `hosts/nixos/nixos-desktop/default.nix` into the dendritic file
- The home-manager config is already complete

**wanda-dendritic.nix**:
- Delete line 34-35 (the legacy bridge comment and import)
- The home-manager config is already complete, nothing to port

**Result**: ✅ No more duplicate imports, clean separation

### Option 2: Remove Duplicates from Legacy (PARTIAL)

Remove conflicting programs from `modules-legacy/home-manager/programs/default.nix`:
- Remove: `./bat.nix`, `./eza.nix`, `./fzf.nix`, `./git.nix`, `./ripgrep.nix`, `./zoxide.nix`
- Keep: Everything else (36+ other programs)

**Problem**: Doesn't address the root issue; legacy bridge still exists

### Option 3: Create Conditional Imports (COMPLEX)

Make legacy bridge conditional on a flag that prevents home-manager imports.

**Problem**: Adds complexity without solving the fundamental issue

## Recommended Action

**Do Option 1**: Remove the legacy bridge imports from nixos-desktop-dendritic.nix and wanda-dendritic.nix

This is the cleanest approach because:
1. It removes the duplicate import chain
2. It maintains the separation between dendritic and legacy patterns
3. It's the least invasive (only removes imports, doesn't delete files)
4. It aligns with the pattern used by personal-mac and work-mac

## Files to Modify

1. **`hosts/nixos-desktop-dendritic.nix`** (Lines 64-65)
   - Remove legacy bridge import
   - Port system config if needed

2. **`hosts/wanda-dendritic.nix`** (Lines 34-35)
   - Remove legacy bridge import

3. **Optional cleanup** (safe to delete when ready):
   - `hosts/darwin/personal-mac.nix` (unused, dendritic version active)
   - `hosts/darwin/work-mac.nix` (unused, dendritic version active)
   - `hosts/nixos/nixos-desktop/default.nix` (if all config ported to dendritic)
   - `hosts/ubuntu/wanda.nix` (if all config ported to dendritic)

## Testing After Fix

After removing legacy bridges, run:
```bash
nix flake check                    # Check syntax
nix build .#nixos-desktop         # Build NixOS config
nix build .#wanda                 # Build Ubuntu home-manager config
```

If these succeed, the duplicate definitions are resolved!
