# Duplicate Home-Manager Configuration Definitions - Research

This directory contains a comprehensive analysis of the duplicate home-manager configuration issue that affects the `nixos-desktop` and `wanda` systems.

## Quick Answer

**Root Cause**: The dendritic host configuration files (`nixos-desktop-dendritic.nix` and `wanda-dendritic.nix`) import **both** dendritic modules (new pattern) AND legacy home-manager modules (old pattern) for the same programs (bat, eza, fzf, git, ripgrep, zoxide), creating duplicate Nix attribute definitions.

**Fix**: Remove the legacy bridge imports (lines 64-65 in nixos-desktop-dendritic.nix, lines 34-35 in wanda-dendritic.nix).

## Document Guide

### 1. **SUMMARY.md** ⭐ START HERE
- Executive summary of the issue
- Why personal-mac works but others don't
- Affected systems list
- Files to modify
- Testing instructions

### 2. **findings.md**
- Confirmed root cause with exact file paths
- Import chain analysis for each broken system
- Detailed table of conflicting modules
- Multiple solution options

### 3. **architecture.md**
- Visual import tree diagrams
- Shows exactly where the duplicates come from
- Illustrates why personal-mac works
- Module export structure explanation

### 4. **debug-report.md**
- Original analysis and discovery process
- Import chain architecture overview
- Probable causes investigation
- Recommendations for complete cleanup

## The Problem in 30 Seconds

```
nixos-desktop-dendritic.nix
├─ imports dendritic bat, eza, fzf, etc.     (LINES 45-59)
└─ imports ../hosts/nixos/nixos-desktop      (LINE 65) ← THE PROBLEM
   └─ ALSO imports legacy bat, eza, fzf, etc.

Result: Nix sees bat defined twice → ERROR!
```

## The Solution

**nixos-desktop-dendritic.nix**: Remove lines 64-65
```nix
    # DELETE THESE:
    # Legacy bridge - brings in all the NixOS system config
    ../hosts/nixos/nixos-desktop
```

**wanda-dendritic.nix**: Remove lines 34-35
```nix
    # DELETE THESE:
    # Legacy bridge
    ../hosts/ubuntu/wanda.nix
```

## Status

| File | Issue | Fix Status |
|------|-------|-----------|
| nixos-desktop-dendritic.nix | Legacy bridge + dendritic imports = duplicates | ❌ NEEDS FIX |
| wanda-dendritic.nix | Legacy bridge + dendritic imports = duplicates | ❌ NEEDS FIX |
| personal-mac-dendritic.nix | No legacy bridge, only dendritic | ✅ WORKING |
| work-mac-dendritic.nix | No legacy bridge, only dendritic | ✅ WORKING |

## Conflicting Programs

These 6 programs are defined in both dendritic and legacy modules:
- bat
- eza
- fzf
- git
- ripgrep
- zoxide

When BOTH are imported, Nix throws a duplicate attribute error.

## Files Affected

**Problematic imports**:
- `hosts/nixos-desktop-dendritic.nix` (line 65)
- `hosts/wanda-dendritic.nix` (line 35)
- `hosts/nixos/nixos-desktop/default.nix` (lines 52-54) ← Legacy bridge file
- `hosts/ubuntu/wanda.nix` (lines 11-13) ← Legacy bridge file

**Conflicting modules**:
- `modules/features/` (dendritic - new)
- `modules-legacy/home-manager/programs/` (legacy - old)

## Next Steps

1. Read **SUMMARY.md** for the quick fix
2. Review **architecture.md** if you want to understand the import chains
3. Remove the legacy bridge imports as documented
4. Run: `nix flake check` to verify the fix
5. Run: `nix build .#nixos-desktop` and `nix build .#wanda` to confirm

## Why This Happened

The migration from legacy to dendritic pattern created a transition state:
- New dendritic host files import dendritic modules
- But old legacy bridge files still existed in those same dendritic files
- The legacy bridges imported the old home-manager modules
- Result: Duplicate imports during the same build

This is a **common pattern during architecture migrations** and is resolved by removing the bridge once the new pattern is fully adopted.

---

**Created**: 2026-02-02  
**Analysis Tool**: Comprehensive git/file review  
**Status**: Complete root cause identified, fix ready to implement
