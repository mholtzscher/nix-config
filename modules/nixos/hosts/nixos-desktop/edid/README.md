# EDID Override for KVM Monitor Resolution Issues

This directory contains EDID (Extended Display Identification Data) files that can be used to override monitor detection when your KVM doesn't properly pass through EDID data.

## Files

- `dp1.bin` - Captured EDID data for your monitor (5120x1440@240Hz)
- `capture-edid.sh` - Script to capture EDID data from your monitor

## Quick Setup

The EDID override is configured in `hosts/nixos/nixos-desktop.nix`.

To enable/disable it:

1. Set `enableEdidOverride = true` (or `false`) in `hosts/nixos/nixos-desktop.nix` (line 18)
2. Rebuild your system: `nb` to validate, then `nup` to apply
3. Reboot to apply the kernel parameter

## How It Works

When enabled, the kernel will use the captured EDID file instead of trying to read it from the monitor through the KVM. This ensures your monitor is always detected with the correct resolution and refresh rate, even when the KVM doesn't pass through EDID data properly.

The configuration adds:
- Kernel parameter: `drm.edid_firmware=DP-1:edid/dp1.bin`
- Firmware package containing the EDID file at `/lib/firmware/edid/dp1.bin`
- Logind settings to prevent screen blanking on KVM switch

## Capturing New EDID

If you need to recapture your monitor's EDID data:

1. Connect your monitor directly (not through KVM) or ensure KVM is working properly
2. Run: `./modules/nixos/hosts/nixos-desktop/edid/capture-edid.sh`
3. The script will save the EDID to `~/.config/hypr/edid/dp1.bin`
4. Copy it to this directory: `cp ~/.config/hypr/edid/dp1.bin modules/nixos/hosts/nixos-desktop/edid/dp1.bin`
5. Commit the changes to git
