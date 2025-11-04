# KVM Settings Review - What to Keep vs Rollback

## Summary
After analyzing all changes since commit `93a39cc` (when KVM issues started), here's what you should **KEEP** vs what can be **REMOVED**.

---

## ✅ KEEP - Essential Settings (Solved Black Screen)

### In `hosts/nixos/desktop.nix`:

```nix
# Disable DPMS to prevent screen blanking issues with KVM switching
services.logind.settings.Login = {
  HandlePowerKey = "ignore";
  HandleLidSwitch = "ignore";
};
```

**Why:** This fixed the black screen issue when switching back from KVM. Without this, systemd's logind would put the display to sleep.

---

## ⚠️ OPTIONAL - EDID Override (If Resolution Still Broken)

### In `hosts/nixos/desktop.nix`:

```nix
# Only keep if resolution is STILL broken after KVM switch
enableEdidOverride = true;  # or false to disable

# Kernel parameters
boot.kernelParams = [
  "nvidia-drm.modeset=1"
] ++ pkgs.lib.optional enableEdidOverride "drm.edid_firmware=DP-1:edid/dp1.bin";

# EDID firmware
hardware.firmware = pkgs.lib.optionals enableEdidOverride [
  (pkgs.runCommand "edid-firmware" { } ''
    mkdir -p $out/lib/firmware/edid
    cp ${edidBin} $out/lib/firmware/edid/dp1.bin
  '')
];
```

**Test First:** Before keeping this, try switching KVM without EDID override. If the resolution is now correct after the black screen fix, you can:
1. Set `enableEdidOverride = false`
2. Remove the captured EDID file
3. Rebuild

**Keep If:** Resolution is still wrong (only shows one resolution instead of 5120x1440@240Hz)

---

## ❌ REMOVE - Probably Unnecessary

### In `hosts/nixos/desktop.nix`:

```nix
# DRM polling - probably not needed
boot.kernelModules = [ "drm_kms_helper" ];
boot.extraModprobeConfig = ''
  options drm_kms_helper poll=1
'';

# EDID tools - only needed for troubleshooting
environment.systemPackages = with pkgs; [
  edid-decode
  read-edid
];
```

**Why Remove:** 
- DRM polling doesn't help if the black screen is already fixed
- EDID tools are only needed for initial diagnosis

**When to Keep:** If you plan to continue troubleshooting or want the tools available for future issues.

---

## ❓ TEST AND DECIDE - Monitor Reset Script

### In `modules/home-manager/hosts/desktop/hyprland.nix`:

```nix
# The Super+Shift+R keybinding and resetMonitorScript
"SUPER SHIFT, R, exec, ${resetMonitorScript}"
```

**Test:** After the black screen fix, see if you still need to manually reset the monitor.

**Remove If:** 
- KVM switching now works perfectly
- Resolution is correct automatically
- You never use Super+Shift+R

**Keep If:**
- You occasionally need to manually trigger a resolution reset
- It's useful as a "just in case" troubleshooting tool

---

## ✅ DEFINITELY KEEP - Configuration Improvements

### In `modules/home-manager/hosts/desktop/hyprland.nix`:

```nix
# Monitor configuration variable (cleaner code)
monitorConfig = "DP-1,5120x1440@240,0x0,1.0,bitdepth,10";

monitor = [
  monitorConfig
  ",preferred,auto,1"  # Fallback
];
```

**Why:** This is just cleaner code organization. No harm, makes config more maintainable.

---

## 🎯 My Recommendation

**Minimal Config (Start Here):**

1. **KEEP:**
   - `services.logind.settings.Login` (HandlePowerKey/HandleLidSwitch ignore)
   - Monitor config with HDR/10-bit (`bitdepth,10`)
   - The config variable `monitorConfig` (cleaner code)

2. **SET TO FALSE (Disable but keep code):**
   - `enableEdidOverride = false`

3. **REMOVE:**
   - DRM polling (`boot.kernelModules` and `boot.extraModprobeConfig`)
   - EDID tools from `environment.systemPackages`
   - Monitor reset script and Super+Shift+R keybinding

4. **TEST:**
   - Rebuild with minimal config
   - Test KVM switching
   - If resolution is broken, re-enable `enableEdidOverride = true`

---

## Testing Plan

```bash
# 1. Set minimal config (see below)
# 2. Rebuild
sudo nixos-rebuild switch --flake .#nixos

# 3. Test KVM switching
# - Switch to another input
# - Switch back to NixOS
# - Check if screen comes back with correct resolution

# 4. If resolution is wrong:
hyprctl monitors  # Check current resolution
# Then re-enable enableEdidOverride = true and rebuild
```

---

## Minimal Config Diff

Here's exactly what to change:

### `hosts/nixos/desktop.nix`:
```nix
# Line 7: Disable EDID override to test
enableEdidOverride = false;

# Remove lines 138-143 (DRM polling):
# boot.kernelModules = [ "drm_kms_helper" ];
# boot.extraModprobeConfig = ''
#   options drm_kms_helper poll=1
# '';

# Remove lines 190-191 (EDID tools):
# edid-decode
# read-edid
```

### `modules/home-manager/hosts/desktop/hyprland.nix`:
```nix
# Remove lines 7-46 (resetMonitorScript)
# Remove line 137 (Super+Shift+R keybinding)
```

---

## What Solved Your Issue?

Based on the commit history, the **black screen was fixed by**:
- `services.logind.settings.Login` changes (commit 93a39cc)

Everything else was **trying to fix the resolution issue**, which may or may not still be a problem.

**TL;DR:** Start with just the logind settings, test thoroughly, then add EDID override only if resolution is still broken.
