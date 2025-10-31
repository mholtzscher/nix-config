# EDID Override for KVM Setup

## Quick Start

**On your NixOS desktop (when monitor is working):**

```bash
# 1. Capture EDID
capture-edid

# 2. Copy EDID to config (from your Mac or NixOS machine)
cd ~/.config/nix-config
mkdir -p modules/home-manager/files/hyprland/edid
cp ~/.config/hypr/edid/dp1.bin modules/home-manager/files/hyprland/edid/

# 3. Enable EDID override in hosts/nixos/desktop.nix
# Change: enableEdidOverride = false;
# To:     enableEdidOverride = true;

# 4. Rebuild and reboot
sudo nixos-rebuild switch --flake .#nixos
sudo reboot
```

---

## Problem
When using a KVM switch, the monitor's EDID (Extended Display Identification Data) may not be properly passed through to the computer. This causes the NVIDIA driver to only detect basic resolutions instead of the full capability (5120x1440@240Hz with 10-bit HDR).

## Solution
Force the Linux kernel to use a captured EDID file instead of relying on the KVM to pass it through.

## Steps

### 1. Capture Working EDID
Run this when your monitor is working properly (either directly connected or before switching away from the NixOS desktop on the KVM):

```bash
capture-edid
```

This will:
- Capture the EDID from `/sys/class/drm/card*/card*-DP-*/edid`
- Save it to `~/.config/hypr/edid/dp1.bin`
- Display the detected resolutions

### 2. Copy EDID to Nix Store
Create a directory in your config to store the EDID file:

```bash
# From your nix-config directory
mkdir -p modules/home-manager/files/hyprland/edid
cp ~/.config/hypr/edid/dp1.bin modules/home-manager/files/hyprland/edid/
```

### 3. Enable EDID Override in Configuration

Edit `hosts/nixos/desktop.nix` and change the `enableEdidOverride` flag (around line 7):

```nix
let
  user = "michael";
  
  # KVM EDID Override Configuration
  # Set to true after capturing EDID with capture-edid script
  enableEdidOverride = true;  # Change from false to true
  
  # Path to captured EDID file
  edidBin = ../../modules/home-manager/files/hyprland/edid/dp1.bin;
in
```

That's it! The configuration will automatically:
- Add the kernel parameter `drm.edid_firmware=DP-1:edid/dp1.bin`
- Copy the EDID file to `/nix/store/.../lib/firmware/edid/dp1.bin`

### 4. Rebuild NixOS

```bash
# From your nix-config directory
sudo nixos-rebuild switch --flake .#desktop
```

### 5. Reboot
After rebuilding, reboot your system. The kernel will now always load the captured EDID file for DP-1, regardless of what the KVM reports.

## Verification

After rebooting, check if the correct resolution is available:

```bash
# Check loaded EDID
hyprctl monitors

# Check kernel logs for EDID loading
dmesg | grep -i edid

# Should see something like:
# [drm] Got external EDID base block and 1 extension from "edid/dp1.bin" for connector "DP-1"
```

## Troubleshooting

### Wrong Connector Name
If `DP-1` doesn't match your actual connector:

1. Check available connectors:
```bash
ls /sys/class/drm/ | grep -E '^card[0-9]+-'
```

2. Update the kernel parameter and Hyprland config to match (e.g., `DP-2`, `DP-3`, etc.)

### EDID Not Loading
Check kernel logs:
```bash
dmesg | grep -i "edid"
```

If you see "firmware not found", verify:
- The file exists: `ls -la /nix/store/*/lib/firmware/edid/dp1.bin`
- The kernel parameter matches the filename

### Still Wrong Resolution
1. Try the manual reset: `Super+Shift+R`
2. Check if EDID was captured properly:
```bash
edid-decode ~/.config/hypr/edid/dp1.bin | grep -E "(DTD|Detailed)"
```
3. You should see the 5120x1440@240Hz mode listed

## Alternative: Disable EDID Checking (Nuclear Option)
If EDID override doesn't work, you can try forcing the mode without EDID validation (not recommended):

```nix
boot.kernelParams = [ 
  "nvidia-drm.modeset=1"
  "video=DP-1:5120x1440@240"
];
```

This bypasses EDID entirely and forces the mode, but may cause issues if the timing parameters don't match your monitor exactly.
