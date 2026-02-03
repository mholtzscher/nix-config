# Debug Report: Duplicate Home-Manager Configuration Definitions

## Issue Summary
Both dendritic feature modules and legacy modules are trying to configure the same programs (bat, eza, fzf, git, ripgrep, zoxide), causing Nix evaluation errors.

## Root Cause Analysis

### Import Chain Architecture

The configuration system has **two separate import chains** that can both load conflicting modules:

#### Chain 1: Dendritic Pattern (NEW - Active)
- **Entry**: `flake.nix` imports `./modules/features` via `inputs.import-tree`
- **Target Host Files**: `hosts/*-dendritic.nix` (personal-mac-dendritic.nix, work-mac-dendritic.nix, etc.)
- **Home-Manager Modules**: Explicitly imported from `inputs.self.modules.homeManager.*`
- **Location**: `modules/features/` → exported to `flake.modules.homeManager`
- **Status**: ✅ Currently active in flake.nix

#### Chain 2: Legacy Pattern (OLD - Still Present)
- **Entry**: `lib/default.nix` mkSystem function
- **Target Host Files**: `hosts/darwin/personal-mac.nix`, `hosts/darwin/work-mac.nix`, etc.
- **Home-Manager Modules**: Imported from `modules-legacy/home-manager/`
- **Location**: `modules-legacy/home-manager/home.nix` and its imports
- **Status**: ⚠️ Still in codebase but not active in flake.nix

### Why Duplicates Occur

The conflicting programs are defined in:

**Dendritic (modules/features/)**
- `modules/features/bat.nix`
- `modules/features/eza.nix`
- `modules/features/fzf.nix`
- `modules/features/git.nix`
- `modules/features/ripgrep.nix`
- `modules/features/zoxide.nix`

**Legacy (modules-legacy/home-manager/programs/)**
- `modules-legacy/home-manager/programs/bat.nix`
- `modules-legacy/home-manager/programs/eza.nix`
- `modules-legacy/home-manager/programs/fzf.nix`
- `modules-legacy/home-manager/programs/git.nix`
- `modules-legacy/home-manager/programs/ripgrep.nix`
- `modules-legacy/home-manager/programs/zoxide.nix`

### Current Active Configuration

**In flake.nix:**
```nix
darwinConfigurations = {
  "Michaels-M1-Max" = import ./hosts/personal-mac-dendritic.nix { inherit inputs; };
  "Michael-Holtzscher-Work" = import ./hosts/work-mac-dendritic.nix { inherit inputs; };
};
```

The dendritic files correctly import ONLY dendritic modules:
```nix
# hosts/personal-mac-dendritic.nix
imports = [
  inputs.self.modules.homeManager.bat
  inputs.self.modules.homeManager.eza
  inputs.self.modules.homeManager.fzf
  inputs.self.modules.homeManager.ripgrep
  inputs.self.modules.homeManager.zoxide
  inputs.self.modules.homeManager.fd
  inputs.self.modules.homeManager.git
  inputs.catppuccin.homeModules.catppuccin
];
```

### Where the Duplicate Comes From

The issue likely stems from **indirect import chains**. Potential sources:

1. **lib/default.nix mkSystem Function** (Line 41):
   - Still imports `../modules-legacy/shared` unconditionally
   - This is used by other host configurations that may still reference it

2. **modules-legacy/shared/default.nix** → includes modules that might cascade import home-manager configs

3. **Legacy host files still exist** in the codebase:
   - `hosts/darwin/personal-mac.nix` ← IMPORTS legacy home-manager!
   - `hosts/darwin/work-mac.nix` ← IMPORTS legacy home-manager!
   - These are NOT used by flake.nix (dendritic versions are used instead)
   - But they could be imported by other evaluation paths

4. **mkSystem in lib/default.nix** (Lines 38-101):
   - While not used by personal-mac config anymore, it still contains:
     ```nix
     commonModules = [
       hostPath
       ../modules-legacy/shared
       homeManagerModule
       ...
     ];
     ```
   - This means any configuration using mkSystem (NixOS, Ubuntu) gets legacy modules

## Impact Analysis

### Currently Affected Systems
- **nixos-desktop** (uses mkSystem)
- **wanda** (Ubuntu, uses mkHome)

### Why personal-mac-dendritic.nix Works (Mostly)
It bypasses lib/default.nix and uses raw `nix-darwin.lib.darwinSystem`, so it:
- ✅ Avoids mkSystem's legacy module injection
- ✅ Explicitly imports only dendritic modules
- ❌ Still might inherit legacy modules if any imported module re-imports them

## File Locations Summary

### Legacy System (Still in codebase, NOT in active flake.nix)
```
hosts/darwin/
  ├── personal-mac.nix (UNUSED - dendritic version active)
  └── work-mac.nix (UNUSED - dendritic version active)

modules-legacy/
  ├── home-manager/
  │   ├── home.nix (IMPORTS: programs/default.nix)
  │   ├── programs/default.nix (IMPORTS: bat, eza, fzf, git, ripgrep, zoxide, etc.)
  │   ├── programs/bat.nix
  │   ├── programs/eza.nix
  │   ├── programs/fzf.nix
  │   ├── programs/git.nix
  │   ├── programs/ripgrep.nix
  │   ├── programs/zoxide.nix
  │   └── hosts/
  │       ├── personal-mac.nix
  │       ├── work-mac.nix
  │       └── nixos-desktop/
  ├── shared/
  │   └── default.nix (IMPORTS: nix-settings.nix)
```

### Dendritic System (Active in flake.nix)
```
modules/features/
  ├── bat.nix
  ├── eza.nix
  ├── fzf.nix
  ├── fd.nix
  ├── git.nix
  ├── ripgrep.nix
  └── zoxide.nix

hosts/
  ├── personal-mac-dendritic.nix (ACTIVE)
  ├── work-mac-dendritic.nix (ACTIVE)
  ├── nixos-desktop-dendritic.nix (ACTIVE - but uses mkSystem!)
  └── wanda-dendritic.nix (ACTIVE - but uses mkHome!)
```

## Probable Cause of Duplicate Error

If you're seeing duplicate definition errors, it's likely because:

1. **nixos-desktop-dendritic.nix** OR **wanda-dendritic.nix** is:
   - Using a function (mkSystem or mkHome) that imports legacy modules
   - Those legacy modules include home-manager config
   - The dendritic modules are ALSO explicitly imported
   - Result: Both bat, eza, etc. are imported twice

2. **OR** there's a circular/recursive import:
   - dendritic modules → imports legacy modules
   - legacy modules → imports dendritic modules
   - Nix evaluates both during import

## Recommendations for Complete Cleanup

### Option 1: Full Dendritic Migration
Remove dependency on legacy modules entirely:

1. Update **lib/default.nix**:
   ```nix
   # Remove: ../modules-legacy/shared
   # Or: Make it conditional based on a flag
   ```

2. Update **nixos-desktop-dendritic.nix** and **wanda-dendritic.nix**:
   - Don't use mkSystem or mkHome (which pull legacy modules)
   - Use raw `nix-darwin.lib.darwinSystem` or `home-manager.lib.homeManagerConfiguration`

3. Delete old host files:
   ```
   hosts/darwin/personal-mac.nix
   hosts/darwin/work-mac.nix
   ```

### Option 2: Parallel Cleanup
Keep both patterns but ensure no overlap:

1. **Identify what's in modules-legacy/shared**:
   - Keep: Cross-platform settings that don't conflict
   - Move: Home-manager to separate legacy chain
   - Delete: Anything that duplicates dendritic

2. **Create separate home-manager imports**:
   - Dendritic: `modules/features/` (new)
   - Legacy: `modules-legacy/home-manager/` (old)
   - Ensure they're NEVER both imported for same system

3. **Update lib/default.nix**:
   - Add a `useLegacy = true/false` flag
   - Conditionally import legacy modules

## Next Steps

1. Check if nixos-desktop-dendritic.nix is using mkSystem (likely yes)
2. Check if wanda-dendritic.nix is using mkHome (likely yes)
3. Those functions pull legacy modules from lib/default.nix
4. Those legacy modules ALSO define bat, eza, etc.
5. So both dendritic AND legacy are being imported

**Solution**: Rewrite nixos-desktop-dendritic.nix and wanda-dendritic.nix to NOT use mkSystem/mkHome, or update those functions to not import legacy home-manager modules.
