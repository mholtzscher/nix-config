# wpaperd Troubleshooting Guide: Black Screens & Common Issues

**Research Date:** November 13, 2025  
**Focus:** Practical debugging steps and solutions

---

## Symptom: Black Screen (No Wallpaper Visible)

### Root Cause Flowchart

```
BLACK SCREEN
│
├─→ Is wpaperd service running?
│   ├─→ NO  → Start: systemctl --user start wpaperd
│   └─→ YES → Continue
│
├─→ Is config file created?
│   ├─→ NO  → Create: ~/.config/wpaperd/config.toml
│   └─→ YES → Continue
│
├─→ Does config have [path] parameter?
│   ├─→ NO  → Add path to config
│   └─→ YES → Continue
│
├─→ Does the path exist?
│   ├─→ NO  → Create directory and add images
│   └─→ YES → Continue
│
├─→ Are there images in the path?
│   ├─→ NO  → Copy images to directory
│   └─→ YES → Continue
│
├─→ Is display name correct?
│   ├─→ NO  → Run: wlr-randr, update config
│   └─→ YES → Continue
│
└─→ Is your compositor supported?
    ├─→ NO (GNOME, Xorg) → wpaperd incompatible
    └─→ YES (Niri, Sway, etc) → Check logs
```

### Step-by-Step Debugging

#### Step 1: Verify Service Status

```bash
# Check if service is running
systemctl --user status wpaperd

# Expected output:
# ● wpaperd.service - Modern wallpaper daemon
#   Loaded: loaded (/nix/store/.../wpaperd.service; enabled; vendor preset: enabled)
#   Active: active (running) since ...
#   Main PID: XXXX

# If not active, check why:
journalctl --user -u wpaperd -n 50

# Start service
systemctl --user start wpaperd

# Enable for future logins (if disabled)
systemctl --user enable wpaperd
```

#### Step 2: Check Configuration File

```bash
# Verify config exists
test -f ~/.config/wpaperd/config.toml && echo "Config exists" || echo "Config missing!"

# View current config
cat ~/.config/wpaperd/config.toml

# Expected format:
# [DP-1]
# path = "/path/to/images"
# duration = "1m"

# If missing or empty, create minimal config:
mkdir -p ~/.config/wpaperd
cat > ~/.config/wpaperd/config.toml << 'EOFCONFIG'
[DP-1]
path = "${HOME}/.config/wallpapers"
duration = "1m"
mode = "fill"
EOFCONFIG

# Reload service
systemctl --user restart wpaperd
```

#### Step 3: Verify Image Directory & Images

```bash
# Check if directory exists
ls -ld ~/.config/wallpapers 2>/dev/null || echo "Directory doesn't exist"

# Count images
find ~/.config/wallpapers -type f \( -name "*.jpg" -o -name "*.png" \) | wc -l

# List first 5 images
ls -la ~/.config/wallpapers/*.{jpg,png} 2>/dev/null | head -5

# If directory empty or missing:
mkdir -p ~/.config/wallpapers

# Copy sample images:
# Option A: From Pictures directory
cp ~/Pictures/*.jpg ~/.config/wallpapers/ 2>/dev/null || echo "No JPGs in Pictures"

# Option B: Download sample
curl -o ~/.config/wallpapers/sample.jpg https://picsum.photos/3840/2160

# Option C: Create minimal test image
convert -size 3840x2160 xc:blue ~/.config/wallpapers/test.jpg

# Verify files are readable
file ~/.config/wallpapers/test.jpg
```

#### Step 4: Get Correct Display Name

```bash
# Primary method: wpaperctl
wpaperctl status
# Expected: "Outputs: DP-1: /path/to/wallpaper (duration: 1m, sorting: random)"

# If no outputs shown, display name is wrong
# Get actual name:
wlr-randr

# Example output:
# eDP-1 "BOE 0x0a53" (Connected) (CRTC 0)
#   Preferred mode: 2160x1440 @ 165.00 Hz
#   Position: 0, 0
# DP-1 "DELL U2715H" (Connected) (CRTC 1)
#   ...

# Or alternative methods:
swaymsg -t get_outputs  # If using Sway
hyprctl monitors        # If using Hyprland

# Update config with correct name:
sed -i 's/\[.*\]/[eDP-1]/' ~/.config/wpaperd/config.toml
systemctl --user restart wpaperd
```

#### Step 5: Check Service Logs for Specific Errors

```bash
# View recent logs
journalctl --user -u wpaperd -n 50

# Follow logs in real-time
journalctl --user -u wpaperd -f

# Search for errors
journalctl --user -u wpaperd | grep -i error

# Common error patterns and meaning:

# "Failed to find output"
# → Display name mismatch. Run: wlr-randr

# "No such file or directory"
# → Path doesn't exist. Run: ls ~/.config/wallpapers/

# "Permission denied"
# → Can't read images. Run: chmod 755 ~/.config/wallpapers

# "Image format unsupported"
# → File format not supported. Convert to JPEG/PNG

# "Failed to create wl_surface"
# → Compositor doesn't support wlr_layer_shell. Check your WM
```

---

## Symptom: High CPU Usage (10%+)

### Diagnosis

```bash
# Monitor CPU in real-time during wallpaper change
watch -n 0.1 'ps aux | grep wpaperd | grep -v grep | awk "{print \$3, \$11}"'

# Check if CPU spikes during transitions
for i in {1..10}; do
  echo "Check $i at $(date +%T)"
  ps aux | grep wpaperd | grep -v grep | awk '{print "CPU:", $3"%"}'
  sleep 2
done
```

### Solution: Optimize Configuration

**Option 1: Reduce queue size (fewer images cached)**

```toml
[default]
queue-size = 5    # Default is 10, reduce to 5 or lower
```

**Option 2: Faster transitions (less CPU overhead)**

```toml
[default]
transition-time = 200  # Shorter transitions = less compute
# OR
transition-time = 0    # No transition (instant)
```

**Option 3: Disable initial transition**

```toml
[default]
initial-transition = false  # No animation on startup
```

**Example: Performance-optimized config**

```toml
[default]
path = "/path/to/images"
duration = "1m"
mode = "fill"
sorting = "random"

# Performance tweaks:
queue-size = 3             # Very small queue
transition-time = 100      # Fast transitions
initial-transition = false # No startup animation
recursive = true           # Efficient subdirectory search
```

---

## Symptom: Flickering or Screen Tearing

### Solution 1: Longer Transitions

```toml
[default]
# Longer transitions are usually smoother
transition-time = 1000  # 1 second (instead of default 300ms)
```

### Solution 2: Ensure GPU Drivers Updated

```bash
# Check OpenGL support
glxinfo | grep "OpenGL version"

# Update system
sudo nixos-rebuild switch --upgrade

# Verify Wayland session
echo $XDG_SESSION_TYPE  # Should be "wayland"
```

### Solution 3: Check Compositor Configuration

```bash
# For Niri, ensure hardware acceleration enabled
cat ~/.config/niri/config.kdl | grep -i vsync

# For Sway, check for tearing prevention
cat ~/.config/sway/config | grep -i "present"
```

---

## Symptom: Wallpaper Disappears After Monitor Reconnect

### Quick Fix

```bash
systemctl --user restart wpaperd

# Verify it reappeared
wpaperctl status
```

### Permanent Fix: Use kanshi

**kanshi** is a Wayland display configuration daemon that can trigger wpaperd reload:

```nix
{
  services.kanshi = {
    enable = true;
    settings = [
      {
        output = "DP-1";
        mode = "3840x2160";
        scale = 1.0;
      }
    ];
    systemdTarget = "graphical-session.target";
  };
  
  # Ensure wpaperd reloads after kanshi reconfigures
  systemd.user.services.wpaperd.Unit.After = [
    "kanshi.service"
  ];
}
```

---

## Symptom: Memory Usage Grows Over Hours

### Root Cause

Queue accumulating old wallpapers, especially with `sorting = "random"`

### Solution 1: Disable Queue

```toml
[default]
queue-size = 0  # Disable queue entirely
```

### Solution 2: Minimal Queue

```toml
[default]
queue-size = 3  # Keep only 3 next images
```

### Solution 3: Periodic Restart (Workaround)

```nix
{
  # Restart wpaperd daily to free memory
  systemd.user.timers.wpaperd-restart = {
    Unit.Description = "Restart wpaperd daily";
    Timer = {
      OnBootSec = "30m";
      OnUnitActiveSec = "1d";  # Every 24 hours
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
  
  systemd.user.services.wpaperd-restart = {
    Unit.Description = "Restart wpaperd to free memory";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart wpaperd";
    };
  };
}
```

---

## Symptom: Wallpaper Quality Issues (Blurry, Compressed)

### Diagnosis

```bash
# Check resolution of images
identify -format "%f: %wx%h\n" ~/.config/wallpapers/*.jpg | sort

# Display resolution
wlr-randr
```

### Solution 1: Use Higher Resolution Images

For 4K (3840x2160) displays, use 4K or higher resolution images:

```bash
# Check current resolution
wlr-randr | grep "^[^ ]" -A 3

# Expected for 4K: 3840x2160 or higher
# Get high-res images from: unsplash.com, wallpaperscraft.com
```

### Solution 2: Change Display Mode

```toml
[default]
mode = "fill"  # Stretch/crop (default, may reduce quality)

# Try these alternatives:
# mode = "fit"         # Preserve quality, add black bars
# mode = "fit-border-color"  # fit + match border colors
```

---

## Symptom: Images Not Updating (New Files Not Detected)

### Solution

```bash
# Reload wpaperd to re-scan directory
systemctl --user restart wpaperd

# Verify detection
wpaperctl next  # Try to see if new image appears
```

### Enable Recursive Search (Auto-detect subdirectories)

```toml
[default]
recursive = true  # New images in subdirs auto-detected
```

---

## Symptom: "No Images Available" Error

### Causes & Solutions

```bash
# Check if images are in supported format
file ~/.config/wallpapers/*

# Supported formats: JPEG, PNG, WebP, GIF, BMP, TIFF, ICO, AVIF

# Convert unsupported files:
for f in *.bmp; do convert "$f" "${f%.bmp}.jpg"; done
for f in *.tga; do convert "$f" "${f%.tga}.png"; done

# Verify files have correct extension
# (Sometimes .jpg files are actually PNG)
for f in *.jpg; do
  if ! file "$f" | grep -q "JPEG"; then
    mv "$f" "$(basename "$f" .jpg).png"
  fi
done
```

---

## Symptom: Service Won't Start

### Check Service Status

```bash
# See why it failed
systemctl --user status wpaperd

# Get error details
journalctl --user -u wpaperd -n 100

# Try starting manually with output
~/.nix-profile/bin/wpaperd

# Check if wpaperd binary exists
which wpaperd
ls -la ~/.nix-profile/bin/wpaperd
```

### Common Causes

**Missing packages:**
```bash
# Ensure wpaperd is in home.packages
# In your nix config:
home.packages = with pkgs; [ wpaperd ];

# Rebuild
home-manager switch
```

**Syntax error in config:**
```bash
# Validate TOML
nix-shell -p toml-cli --run "toml ~/.config/wpaperd/config.toml"

# Or manually check for syntax issues
cat ~/.config/wpaperd/config.toml
```

**File permissions:**
```bash
# Fix permissions on config file
chmod 644 ~/.config/wpaperd/config.toml

# Fix directory permissions
chmod 755 ~/.config/wpaperd/
chmod 755 ~/.config/wallpapers/
chmod 644 ~/.config/wallpapers/*
```

---

## Symptom: Wrong Compositor (GNOME, Xorg)

### Check Session Type

```bash
# Verify Wayland
echo $XDG_SESSION_TYPE
# Should output: "wayland"

# If output is "x11", you're on Xorg
# wpaperd only works on Wayland
```

### Solutions

**For GNOME (not supported by wpaperd):**
- Use GNOME Settings > Background
- Or use alternative: `swww` (if compatible)

**For Xorg:**
- Use `swaybg` for static wallpaper
- Switch to Wayland if available

---

## Advanced Debugging

### Enable Debug Logging

```bash
# Stop service
systemctl --user stop wpaperd

# Run with debug output
RUST_LOG=debug,wpaperd=trace ~/.nix-profile/bin/wpaperd

# Watch for detailed error messages
```

### Monitor Real-Time Wallpaper Changes

```bash
# Every 2 seconds, show: status, last modified image
watch -n 2 'wpaperctl status; echo "---"; ls -lt ~/.config/wallpapers | head -2'
```

### Test with Minimal Config

```bash
# Create test config
mkdir -p /tmp/wpaperd-test
cat > /tmp/wpaperd-test/config.toml << 'EOFTEST'
[DP-1]
path = "/home/michael/Pictures/wallpapers"
duration = "10s"
mode = "fill"
EOFTEST

# Run wpaperd with test config
XDG_CONFIG_HOME=/tmp/wpaperd-test ~/.nix-profile/bin/wpaperd

# In another terminal, check if it works
watch -n 1 wpaperctl status
```

### Check File Descriptor Limits

```bash
# If wallpaper directory has many files:
ulimit -n  # Should be at least 1024

# Increase if needed:
# Add to ~/.bashrc or systemd service:
# ulimit -n 4096
```

---

## Support Resources

### Finding Help

```bash
# Check official GitHub issues
# https://github.com/danyspin97/wpaperd/issues

# Search NixOS Discourse
# https://discourse.nixos.org (search: "wpaperd")

# View home-manager module source
# man home-configuration.nix (search for wpaperd)

# Check nixpkgs package
nix-shell -p nix-info --run "nix-info"
```

### Reporting Issues

When reporting wpaperd issues, include:

```bash
# System info
uname -a
nix-shell -p nix-info --run "nix-info"

# Current configuration
cat ~/.config/wpaperd/config.toml

# Service status
systemctl --user status wpaperd

# Recent logs (last 100 lines)
journalctl --user -u wpaperd -n 100

# Display information
wlr-randr

# Running processes
ps aux | grep wpaperd
```

---

## Quick Troubleshooting Commands

```bash
# All diagnostics in one go:
echo "=== Service Status ===" && \
systemctl --user status wpaperd && \
echo -e "\n=== Config ===" && \
cat ~/.config/wpaperd/config.toml && \
echo -e "\n=== Images ===" && \
ls ~/.config/wallpapers/*.{jpg,png} 2>/dev/null | wc -l && \
echo -e "\n=== Display ===" && \
wpaperctl status && \
echo -e "\n=== Last Logs ===" && \
journalctl --user -u wpaperd -n 10
```

---

**Document Version:** 1.0  
**Last Updated:** November 13, 2025  
**Status:** Complete
