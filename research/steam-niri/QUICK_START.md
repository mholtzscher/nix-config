# Steam on Niri: Quick Start Guide

## For the Impatient 🚀

**TL;DR**: Your Steam errors are likely due to missing XWayland package and conflicting SDL driver settings. Three quick fixes:

### Fix 1: Add XWayland Package (REQUIRED)

**File**: `hosts/nixos/nixos-desktop.nix`

```nix
environment.systemPackages = with pkgs; [
  xwayland      # ← ADD THIS
  xorg.xhost
  xorg.xdpyinfo
  wl-clipboard
  chromium
];
```

### Fix 2: Remove SDL Driver Conflict

**File**: `modules/nixos/hosts/nixos-desktop/gaming.nix`

```nix
sessionVariables = {
  # REMOVE: SDL_VIDEODRIVER = "wayland";  ← DELETE THIS LINE
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
  # REMOVE: DISPLAY = ":0";  ← ALSO DELETE THIS (let Niri set it)
};
```

### Fix 3: Add Steam Window Rules

**File**: `modules/nixos/hosts/nixos-desktop/composition.nix`

Find the `window-rules` section and add:

```nix
{
  matches = [
    { class = "steam"; }
    { class = "steamapps"; }
  ];
  allow-fullscreen = true;
}
```

## Apply Changes

```bash
# Validate
nix flake check

# Build (don't apply)
nb

# If that works, apply (user runs this)
nup
```

## Test It

```bash
# New terminal session, verify installation
which xwayland
echo $DISPLAY
xdpyinfo
steam
```

## Still Not Working?

```bash
# Start with diagnostics
echo $DISPLAY
echo $WAYLAND_DISPLAY
ps aux | grep xwayland

# Try manual workaround
export DISPLAY=:0
export SDL_VIDEODRIVER=x11
steam

# Check logs
cat ~/.steam/steam/logs/bootstrap.log
```

## Configuration Reference

### What Each File Does

| File | Purpose |
|------|---------|
| `hosts/nixos/nixos-desktop.nix` | System-wide packages (XWayland goes here) |
| `modules/nixos/hosts/nixos-desktop/gaming.nix` | Gaming environment variables & user packages |
| `modules/nixos/hosts/nixos-desktop/composition.nix` | Niri window manager settings (window rules) |

### What Each Setting Does

| Setting | What it does | Current | Should be |
|---------|-------------|---------|-----------|
| `xwayland` in systemPackages | Enables X11 apps in Wayland | ❌ Missing | ✅ Add it |
| `SDL_VIDEODRIVER = "wayland"` | Forces SDL to use Wayland | ⚠️ Breaks Steam | Remove or set to "x11" |
| `DISPLAY = ":0"` | Hardcodes X11 display | ⚠️ Overrides Niri | Remove (let Niri set) |
| `DBUS_SESSION_BUS_ADDRESS` | D-Bus communication | ✅ Correct | ✅ Keep it |
| Steam window rules | Tells Niri how to manage Steam | ❌ Missing | ✅ Add it |

## Common Errors & Quick Fixes

### "Unable to open a connection to X"
```bash
# Fix 1: Install XWayland (see Fix 1 above)
# Fix 2: Manually set DISPLAY
export DISPLAY=:0
steam
```

### "SDL_VideoModeOK failed"
```bash
# Fix: Remove SDL_VIDEODRIVER = "wayland" from gaming.nix
# (see Fix 2 above)
```

### Steam window is black
```bash
# Verify GPU is working:
glxinfo | grep "Direct Rendering"  # Should say "Yes"
vulkaninfo | grep "Device Type"    # Should show GPU

# If not, check NVIDIA config in nixos-desktop.nix:
# boot.kernelParams = ["nvidia-drm.modeset=1"]
# hardware.graphics.enable32Bit = true
```

### Fullscreen games won't go fullscreen
```bash
# Fix: Add window rules (see Fix 3 above)
# The rules tell Niri: allow-fullscreen = true
```

## Performance Tips

```bash
# Show FPS overlay while gaming
export MANGOHUD=1
steam

# Force Steam to use X11 (if Wayland has issues)
export SDL_VIDEODRIVER=x11
steam

# Enable CPU performance mode
export PROTON_USE_WINESERVER64=1

# Monitor real-time performance
# (while game is running in another terminal)
top -p $(pgrep -f "proton\|wine")
```

## Advanced: Using Gamescope

Gamescope is a gaming-optimized compositor:

```bash
# At login, choose "Steam" or "Gamescope" session
# (instead of standard Niri)

# Pros:
# ✅ Better fullscreen handling
# ✅ Resolution scaling
# ✅ Isolated from desktop

# Cons:
# ⚠️ Extra performance overhead
# ⚠️ Can't switch between gaming/desktop easily

# Back to normal:
# Log out and select "Niri" at login
```

## File Editing Quick Reference

### To edit a file:

```bash
# Open in your favorite editor (vim, helix, nano, etc.)
nano /home/michael/nix-config/hosts/nixos/nixos-desktop.nix

# Or use your IDE
code /home/michael/nix-config
```

### Common editing patterns:

```nix
# Adding a package
environment.systemPackages = with pkgs; [
  existing_package
  new_package    # ← Add here
];

# Removing a variable
sessionVariables = {
  # KEEP_THIS = "value";
  # REMOVE_THIS = "value";  # ← Delete this line
  KEEP_THIS_TOO = "value";
};

# Adding window rules
window-rules = [
  # Existing rules...
  {
    matches = [
      { class = "steam"; }
    ];
    allow-fullscreen = true;
  }  # ← Add new rule
];
```

## Command Reference

```bash
# Validate configuration without applying
nix flake check

# Build system (doesn't apply)
nb

# Apply system (requires user confirmation)
nup

# Check if package is installed
which xwayland

# Check if service is running
ps aux | grep xwayland

# Check environment variable
echo $DISPLAY

# Test X11 connection
xdpyinfo

# Rebuild just the gaming module
nixos-rebuild switch -I ~/.config/nix-darwin flake .

# Rollback to previous generation
sudo nixos-rebuild switch --rollback
```

## Minimal Reproducible Setup

If you want to test from scratch:

```nix
# Minimal steam-niri configuration

# In hosts/nixos/nixos-desktop.nix:
programs.steam.enable = true;

environment.systemPackages = with pkgs; [
  xwayland
];

# In gaming.nix:
sessionVariables = {
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
};

# In composition.nix:
window-rules = [
  {
    matches = [
      { class = "steam"; }
    ];
  }
];
```

## Verification Checklist

After applying changes:

- [ ] `which xwayland` - returns `/run/current-system/sw/bin/xwayland`
- [ ] `ps aux | grep xwayland` - shows XWayland process in Niri
- [ ] `echo $DISPLAY` - shows something like `:0`
- [ ] `xdpyinfo` - runs without errors
- [ ] `steam` - launches and shows window
- [ ] Games can launch (test with a simple game)

## Support

If still stuck:

1. Check **TECHNICAL_REFERENCE.md** for deeper understanding
2. Check **TROUBLESHOOTING.md** for your specific error
3. Run diagnostic script:
   ```bash
   which steam && steam --version
   ps aux | grep -E "niri|xwayland"
   cat ~/.steam/steam/logs/bootstrap.log | tail -20
   ```
4. Share the output with your support request

---

**Next Steps**: After basic fixes, read **CONFIGURATION_FIX.md** for complete setup details.
