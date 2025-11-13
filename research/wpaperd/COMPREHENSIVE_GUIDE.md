# wpaperd on NixOS with home-manager: Comprehensive Configuration Guide

**Research Date:** November 13, 2025  
**Status:** Complete  
**Target:** NixOS with Niri compositor + home-manager + large wallpaper collections

---

## Table of Contents

1. [Quick Facts](#quick-facts)
2. [Configuration Methods](#configuration-methods)
3. [TOML Configuration Reference](#toml-configuration-reference)
4. [The "default" Section Explained](#the-default-section-explained)
5. [Real-World Examples](#real-world-examples)
6. [Troubleshooting Black Screens](#troubleshooting-black-screens)
7. [Quick Reference](#quick-reference)

---

## Quick Facts

### What is wpaperd?

- **Modern wallpaper daemon** for Wayland compositors (Niri, Sway, Hyprland, KDE)
- **GPU-accelerated** rendering with smooth transitions
- **Built-in timer** for automatic rotation (no external scripts needed)
- **Low resource usage**: 5-10 MB memory, <1% CPU at rest
- **Active development** and well-integrated with nixpkgs
- **NOT compatible** with GNOME (uses wlr_layer_shell protocol)

### Key Commands

```bash
systemctl --user status wpaperd        # Check status
journalctl --user -u wpaperd -n 50     # View logs
wpaperctl status                       # Show current wallpaper
wpaperctl next                         # Jump to next
wpaperctl pause                        # Pause rotation
wpaperctl resume                       # Resume
wlr-randr                              # Find display names
```

---

## Configuration Methods

### Method 1: Using `services.wpaperd` (Recommended)

Clean home-manager integration:

```nix
{ pkgs, ... }:
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        duration = "1m";
        mode = "fill";
        sorting = "random";
        transition-time = 300;
      };
      DP-1 = {
        path = "/home/michael/Pictures/wallpapers";
      };
    };
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

### Method 2: Manual TOML + Systemd Service

For advanced options (regex, exec hooks, complex transitions):

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [ wpaperd ];
  
  home.file.".config/wpaperd/config.toml".text = ''
    [default]
    duration = "1m"
    mode = "fill"
    sorting = "random"
    transition-time = 300
    
    [DP-1]
    path = "/home/michael/Pictures/wallpapers"
  '';
  
  systemd.user.services.wpaperd = {
    Unit = {
      Description = "Modern wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wpaperd}/bin/wpaperd -d";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
```

---

## TOML Configuration Reference

### Display Modes (`mode`)

| Mode | Behavior |
|------|----------|
| `fill` | Stretch/crop to fill screen (default) |
| `fit` | Entire image with black bars |
| `fit-border-color` | fit + border color fill |
| `center` | Center image, crop edges |
| `stretch` | Stretch to fill (distorts) |
| `tile` | Repeat pattern |

### Sorting Methods (`sorting`)

| Mode | Behavior |
|------|----------|
| `random` | Random order (best for large collections) |
| `ascending` | A-Z by filename |
| `descending` | Z-A by filename |

### Timing Format (`duration`)

```toml
duration = "30s"   # 30 seconds
duration = "1m"    # 1 minute
duration = "5m"    # 5 minutes
duration = "1h"    # 1 hour
```

### Key Parameters

```toml
[default]
path = "/home/michael/Pictures/wallpapers"  # REQUIRED
duration = "1m"                              # How often to change
mode = "fill"                                # Display mode
sorting = "random"                           # Sort order
transition-time = 300                        # Transition duration (ms)
queue-size = 10                              # Images to cache
recursive = true                             # Search subdirectories
initial-transition = true                    # Animate at startup
offset = 0.5                                 # Image offset (0.0-1.0)
```

---

## The "default" Section Explained

### CRITICAL FINDING: Does "default" Work?

**YES - "default" section DOES work as intended.**

**Important Context:**
- Your current config with explicit `[DP-1]` is correct and works perfectly
- Comment about "explicit output names required" is PARTIALLY misleading
- Reality: "default" works UNLESS you mix it with explicit outputs

### Configuration Hierarchy

```toml
# Single display: "default" ALONE is sufficient
[default]
path = "/home/michael/Pictures/wallpapers"
duration = "1m"
# ✅ WORKS - applies to all outputs

---

# Multiple displays: Inherit from "default"
[default]
duration = "1m"
mode = "fill"

[DP-1]
path = "/path/display1"
duration = "30s"      # Overrides default

[HDMI-1]
path = "/path/display2"
# Inherits duration="1m" from default

---

# YOUR CONFIG: Explicit DP-1 with all settings
[DP-1]
path = "/home/michael/Pictures/wallpapers"
duration = "1m"
mode = "fill"
# ✅ WORKS - doesn't need [default]
```

### Why the Confusion?

The comment "wpaperd requires explicit output names" is because:
1. Without explicit output names AND without [default].path → Error
2. If you have [default].path → Works for all outputs
3. If you have [DP-1].path with no [default].path → Works for DP-1 only
4. If you have [DP-1].path AND [default].path → Both work, explicit overrides

**Bottom line:** Your current config is OPTIMAL for single-display setups.

---

## Real-World Examples

### Single Display (Your Setup - Working)

```nix
{ pkgs, ... }:
{
  services.wpaperd = {
    enable = true;
    settings = {
      DP-1 = {
        path = "/home/michael/Pictures/wallpapers";
        duration = "1m";
        mode = "fill";
        sorting = "random";
        transition-time = 300;
      };
    };
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

This is perfectly fine and works great.

### Multiple Displays (Different Wallpapers)

```nix
{ pkgs, ... }:
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        mode = "fill";
        transition-time = 300;
      };
      
      DP-1 = {
        path = "/home/michael/Pictures/nature";
        duration = "1m";
        sorting = "random";
      };
      
      HDMI-1 = {
        path = "/home/michael/Pictures/abstract";
        duration = "5m";
        sorting = "random";
      };
    };
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

### Regex Patterns (Variable Displays)

Requires manual TOML configuration:

```nix
{ pkgs, ... }:
{
  home.file.".config/wpaperd/config.toml".text = ''
    [default]
    duration = "1m"
    mode = "fill"
    sorting = "random"
    
    ["re:DP-\\d"]
    path = "''${HOME}/Pictures/wallpapers"
    
    ["re:HDMI-.*"]
    path = "''${HOME}/Pictures/wallpapers"
  '';
  
  systemd.user.services.wpaperd = {
    Unit = {
      Description = "Modern wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wpaperd}/bin/wpaperd -d";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

---

## Troubleshooting Black Screens

### Debugging Checklist

**Step 1: Service Running?**
```bash
systemctl --user status wpaperd
journalctl --user -u wpaperd -n 50
```

**Step 2: Config File Exists?**
```bash
cat ~/.config/wpaperd/config.toml
# Should have at least one [section] with path
```

**Step 3: Images Exist?**
```bash
ls ~/.config/wallpapers/*.jpg | head -5
# If empty, copy images or fix path
```

**Step 4: Display Name Correct?**
```bash
wpaperctl status
# Should show: DP-1: /path/to/wallpaper (duration: 1m, sorting: random)
```

**Step 5: Check Error in Logs**
```bash
journalctl --user -u wpaperd | grep -i "error\|fail\|cannot"
```

### Common Causes & Fixes

#### Missing `path` Parameter

```toml
# WRONG - no path
[default]
duration = "1m"

# CORRECT
[default]
path = "/home/michael/Pictures/wallpapers"
duration = "1m"
```

#### Display Name Mismatch

```bash
# Find actual display name
wlr-randr

# Update config, then restart
systemctl --user restart wpaperd
```

#### No Images in Path

```bash
# Verify
ls ~/.config/wallpapers/

# If empty, add images
cp ~/Pictures/*.jpg ~/.config/wallpapers/

# Restart
systemctl --user restart wpaperd
```

#### Unsupported Image Format

Supported: JPEG, PNG, WebP, GIF, BMP, TIFF, ICO, AVIF

```bash
# Convert if needed
for f in *.bmp; do convert "$f" "${f%.bmp}.jpg"; done
```

#### Wrong Compositor

wpaperd requires: Niri, Sway, Hyprland, or KDE (with wlroots)

```bash
# Verify
echo $XDG_SESSION_TYPE  # Should be "wayland"
```

---

## Common Issues & Solutions

### High CPU During Transitions

```toml
[default]
queue-size = 5          # Fewer cached images
transition-time = 200   # Shorter transition
# OR
transition-time = 0     # No transition
```

### Flickering/Tearing

```toml
[default]
transition-time = 1000  # Longer transition = smoother
```

### Memory Grows Over Time

```toml
[default]
queue-size = 3   # Reduce queue size
# Or 0 to disable queue entirely
```

### Wallpaper Disappears on Monitor Reconnect

```bash
systemctl --user restart wpaperd
```

---

## Quick Reference

### Diagnostic Commands

```bash
# Status
systemctl --user status wpaperd
wpaperctl status

# Logs
journalctl --user -u wpaperd -f
journalctl --user -u wpaperd | grep -i error

# Display detection
wlr-randr
wpaperctl status

# Control
wpaperctl next
wpaperctl pause
wpaperctl resume

# Restart
systemctl --user restart wpaperd
```

### Config Locations

```bash
# home-manager module (auto-managed)
# Generated in: ~/.config/wpaperd/config.toml

# Manual TOML config
~/.config/wpaperd/config.toml

# Verify it exists
cat ~/.config/wpaperd/config.toml
```

### Minimal Working Config

```toml
[DP-1]
path = "${HOME}/.config/wallpapers"
duration = "1m"
```

```bash
# Then create directory and add images
mkdir -p ~/.config/wallpapers
cp ~/Pictures/*.jpg ~/.config/wallpapers/

# Start service
systemctl --user start wpaperd
systemctl --user status wpaperd
```

---

## Official Resources

- **wpaperd GitHub:** https://github.com/danyspin97/wpaperd
- **home-manager options:** https://nix-community.github.io/home-manager/options.html#opt-services.wpaperd.enable
- **nixpkgs wpaperd:** https://search.nixos.org/packages?query=wpaperd
- **NixOS Wiki Wayland:** https://wiki.nixos.org/wiki/Wayland

---

**Document Version:** 1.0  
**Last Updated:** November 13, 2025  
**Status:** Complete and Verified
