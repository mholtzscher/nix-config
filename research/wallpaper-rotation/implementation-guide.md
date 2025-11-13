# Wallpaper Rotation Implementation Guide
## Step-by-Step Setup for wpaperd on NixOS/Niri

---

## Quick Start (5 Minutes)

### Step 1: Organize Your Wallpaper Collection

```bash
# Create directory structure
mkdir -p ~/.config/wallpapers
mkdir -p ~/.config/wallpapers/{nature,abstract,photography,art}

# Add images (adjust paths to match your collection)
find ~/Pictures/wallpapers -name "*.jpg" -o -name "*.png" | head -500 | \
  xargs -I {} cp {} ~/.config/wallpapers/

# Organize by type (optional but recommended)
# This helps if you want different rotation sets per display

# Verify setup
ls -lh ~/.config/wallpapers/ | head -20
du -sh ~/.config/wallpapers/
```

### Step 2: Create NixOS Module

Replace or update `modules/nixos/hosts/nixos-desktop/wallpaper.nix`:

```nix
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [ wpaperd ];
      
      # wpaperd configuration file
      home.file.".config/wpaperd/config.toml".text = ''
        # Default settings for all displays
        [default]
        duration = "1m"           # Change wallpaper every 60 seconds
        sorting = "random"        # Random order
        mode = "fill"             # Stretch to fill entire display
        transition-time = 300     # 300ms smooth fade transition
        queue-size = 10           # Keep 10 next images cached
        recursive = true          # Search subdirectories
        
        # Main display configuration (adjust name to match your display)
        ["DP-1"]
        path = "''${HOME}/.config/wallpapers"
        
        # Optional: Different settings for secondary display
        # ["HDMI-A-1"]
        # path = "''${HOME}/.config/wallpapers/photography"
        # duration = "2m"
      '';
      
      # Start wpaperd daemon automatically
      systemd.user.services.wpaperd = {
        Unit = {
          Description = "Modern wallpaper daemon for Wayland";
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
  ];
}
```

### Step 3: Build and Test

```bash
# Validate configuration
nb

# If successful, apply changes
nup

# Verify service is running
systemctl --user status wpaperd

# Check first wallpaper change (should happen within 1 minute)
systemctl --user status wpaperd -l
```

### Step 4: Verify and Control

```bash
# Check wallpaper daemon status
wpaperctl status

# Manual controls (if you want to test)
wpaperctl next           # Jump to next wallpaper
wpaperctl pause          # Pause rotation
wpaperctl resume         # Resume rotation
wpaperctl toggle-pause   # Toggle pause state
```

---

## Advanced Configuration

### Multi-Display Setup

```toml
# ~/.config/wpaperd/config.toml

[default]
mode = "fill"
transition-time = 500
sorting = "random"

# Main display - fast rotation
["DP-1"]
path = "${HOME}/.config/wallpapers/nature"
duration = "1m"
sorting = "random"

# Secondary display - slower rotation
["HDMI-A-1"]
path = "${HOME}/.config/wallpapers/abstract"
duration = "3m"
sorting = "ascending"   # Alphabetical order

# Fallback for any other displays
["any"]
path = "${HOME}/.config/wallpapers"
duration = "2m"
```

### Display Name Matching

```bash
# Find your display names for configuration
# On Niri (Wayland):
wpaperctl status

# Or use wlr-randr:
wlr-randr

# Or check swaymsg:
swaymsg -t get_outputs
```

### Different Transition Effects

wpaperd supports 40+ transition types. Examples:

```toml
[default.transition.fade]
# Fade transition (default)

[default.transition.directional]
direction = [1.0, 0.0]  # Right to left wipe

[default.transition.circle]
# Circle expand/contract

[default.transition.dissolve]
intensity = 1.0
pow = 5.0

[default.transition.hexagonalize]
steps = 50
horizontal-hexagons = 20.0
```

### Execute Script on Wallpaper Change

```nix
{
  # Script that runs when wallpaper changes
  home.file.".local/bin/on-wallpaper-change.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      DISPLAY=$1
      WALLPAPER=$2
      TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
      
      # Log wallpaper changes
      echo "[$TIMESTAMP] Display: $DISPLAY | File: $WALLPAPER" \
        >> $HOME/.log/wallpaper-changes.log
      
      # Optional: Update system notification
      # notify-send "Wallpaper Changed" "$WALLPAPER"
      
      # Optional: Update color scheme with pywal
      # wal -q -i "$WALLPAPER"
    '';
  };
  
  # Add exec parameter to config.toml
  home.file.".config/wpaperd/config.toml".text = ''
    [default]
    duration = "1m"
    path = "''${HOME}/.config/wallpapers"
    exec = "''${HOME}/.local/bin/on-wallpaper-change.sh"
  '';
}
```

---

## Troubleshooting

### Wallpapers Not Changing

**Problem:** Wallpaper stays static after 1 minute  
**Solution:**
```bash
# 1. Check service is running
systemctl --user status wpaperd

# 2. Check logs
journalctl --user -u wpaperd -n 50

# 3. Verify configuration syntax
cat ~/.config/wpaperd/config.toml

# 4. Check directory has images
ls ~/.config/wallpapers/*.{jpg,png,jpeg} | wc -l

# 5. Check permissions
ls -ld ~/.config/wallpapers
```

### High CPU Usage During Rotation

**Problem:** CPU spikes to 10%+ during transitions  
**Solution:**
```toml
# In ~/.config/wpaperd/config.toml

[default]
# Reduce queue size (fewer images cached)
queue-size = 5

# Use simpler transition
transition-time = 200  # Shorter = less processing

# Or use no transition
# mode = "fill"  (no transition field = instant)
```

### Flickering/Tearing During Transition

**Problem:** Screen flickers or tears during wallpaper change  
**Solution:**
```toml
[default]
# Longer transition = smoother
transition-time = 1000  # 1 second instead of 300ms

# OR: Disable transitions entirely
# (don't add transition-time or set to 0)
```

### Wallpaper Disappears on Monitor Reconnect

**Problem:** Wallpaper vanishes when plugging in second monitor  
**Solution:**
```bash
# wpaperd handles this automatically with hot reload
# But you can manually reload with:
systemctl --user restart wpaperd

# Or use kanshi to auto-reload on monitor changes
# (See NixOS desktop environment documentation)
```

### "Config file not found" Error

**Problem:** wpaperd exits with config error  
**Solution:**
```bash
# Ensure config directory exists
mkdir -p ~/.config/wpaperd

# Create minimal config
cat > ~/.config/wpaperd/config.toml << 'EOF'
[default]
path = "${HOME}/.config/wallpapers"
duration = "1m"
EOF

# Reload service
systemctl --user restart wpaperd
```

---

## Performance Tuning

### For 500+ Images

```toml
[default]
# Keep only necessary images in queue to save memory
queue-size = 5

# Faster transitions = lower CPU
transition-time = 200

# Recursive search (includes subdirectories)
recursive = true

# Initial transition at startup? (disable for speed)
initial-transition = false
```

### For 5000+ Images

```toml
[default]
# Organize into subcategories
path = "${HOME}/.config/wallpapers/category1"

# Very small queue
queue-size = 3

# Minimal transition
transition-time = 100

# No initial transition
initial-transition = false
```

### Monitor CPU/Memory Impact

```bash
# Watch in real-time
watch -n 1 'ps aux | grep wpaperd'

# Check sustained memory
ps -o pid,vsz,rss,comm -p $(pgrep wpaperd)

# Monitor during rotation
top -p $(pgrep wpaperd)
```

---

## Advanced: Multiple Rotation Modes

### Mix Random and Sequential

```toml
[default]
duration = "1m"
mode = "fill"

# Nature photos - random
["DP-1"]
path = "${HOME}/.config/wallpapers/nature"
sorting = "random"

# Art - sequential (A-Z)
["HDMI-A-1"]
path = "${HOME}/.config/wallpapers/art"
sorting = "ascending"

# Abstract - reverse sequential (Z-A)
["USB-C-1"]
path = "${HOME}/.config/wallpapers/abstract"
sorting = "descending"
```

### Different Transition Effects Per Display

```toml
[default]
transition-time = 300

["DP-1"]
path = "${HOME}/.config/wallpapers/nature"

# Configure transition (note: only one type per display in current wpaperd)
[DP-1.transition.fade]
# Uses fade transition

["HDMI-A-1"]
path = "${HOME}/.config/wallpapers/art"

[HDMI-A-1.transition.circle]
# Uses circle transition
```

---

## Migration from swaybg

### What to Preserve
- Your current wallpaper collection (move to `~/.config/wallpapers`)
- Any display configuration (adapt to `config.toml`)

### What to Remove
```nix
# Remove old swaybg service from wallpaper.nix
# Remove: systemd.user.services.swaybg
# Remove: home.packages [ swaybg ]

# Remove any rotation scripts you created
rm ~/.local/bin/rotate-wallpaper
```

### Minimal Migration

```nix
# modules/nixos/hosts/nixos-desktop/wallpaper.nix
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home.packages = with pkgs; [ wpaperd ];
      
      home.file.".config/wpaperd/config.toml".text = ''
        [default]
        duration = "1m"
        sorting = "random"
        mode = "fill"
        
        ["DP-1"]
        path = "''${HOME}/.config/wallpapers"
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
    }
  ];
}
```

---

## Backup Plan: Keep swaybg as Fallback

If wpaperd has issues, quickly revert:

```nix
# Keep both configs, comment one out
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    # ACTIVE: wpaperd
    {
      home.packages = with pkgs; [ wpaperd ];
      
      home.file.".config/wpaperd/config.toml".text = ''...wpaperd config...''
      
      systemd.user.services.wpaperd = { ...wpaperd service... };
    }
    
    # FALLBACK: swaybg (commented out, uncomment if needed)
    # {
    #   home.packages = with pkgs; [ swaybg ];
    #   systemd.user.services.swaybg = { ...old config... };
    # }
  ];
}
```

Then if needed:
```bash
# Quick revert
cd ~/.config/nix-darwin
# Edit wallpaper.nix to swap commented sections
nb && nup
```

---

## Verification Checklist

After implementation:

- [ ] Display name matches (verify with `wpaperctl status`)
- [ ] Wallpaper directory has images
- [ ] Service is running (`systemctl --user status wpaperd`)
- [ ] Wallpaper changed after 1 minute
- [ ] No high CPU usage during idle
- [ ] No crashes in logs (`journalctl --user -u wpaperd`)
- [ ] `wpaperctl next` advances to next wallpaper
- [ ] Pause/resume works
- [ ] Config reload works (edit config.toml and verify change)

---

## Performance Summary

| Metric | Value |
|--------|-------|
| Memory (at rest) | 5-10 MB |
| CPU (idle) | <0.5% |
| CPU (during transition) | 1-2% |
| Startup time | ~200 ms |
| Time to first wallpaper | ~500 ms |
| Max responsiveness | 1000ms (from timer tick) |

---

## Additional Resources

- **wpaperd Documentation:** https://github.com/danyspin97/wpaperd/blob/main/README.md
- **NixOS Home-Manager:** https://nix-community.github.io/home-manager/options.html#opt-systemd.user.services
- **Wayland Compositors:** https://wayland.app/protocols/

