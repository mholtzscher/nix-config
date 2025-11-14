# Steam on NixOS with Niri Window Manager

## Overview

This research documents proper Steam configuration on NixOS with the Niri Wayland compositor. The "Unable to open a connection to X" error occurs because Steam's launcher and many games expect X11/XWayland support, which requires careful environment setup.

## Quick Fix Summary

The issue occurs when:
1. **XWayland is not properly configured** in the Niri session
2. **Environment variables are not set correctly** for Steam to find X11 display
3. **Gamescope session is enabled but not properly integrated** with Niri
4. **Missing DBUS session** for XWayland communication

**Required changes:**
1. ✅ Enable XWayland support in Niri compositor
2. ✅ Ensure `programs.steam.gamescopeSession.enable = true` at system level
3. ✅ Set `DISPLAY`, `SDL_VIDEODRIVER`, and `DBUS_SESSION_BUS_ADDRESS` environment variables
4. ✅ Install `xwayland` package in environment
5. ✅ Configure Niri to accept X11 windows via XWayland

## Current Configuration Analysis

### Current Status ✓
Your configuration already has most components:

**In `hosts/nixos/nixos-desktop.nix`:**
```nix
programs.steam = {
  enable = true;
  gamescopeSession.enable = true;  # ✓ Correct
};
```

**In `modules/nixos/hosts/nixos-desktop/gaming.nix`:**
```nix
sessionVariables = {
  SDL_VIDEODRIVER = "wayland";      # ✓ Set for Wayland
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";  # ✓ Set
  DISPLAY = ":0";                   # ⚠️ Problem: hardcoded, may be wrong
};
```

### Known Issues

1. **DISPLAY hardcoded to `:0`** - This may not match actual XWayland display
2. **No XWayland package in environment** - XWayland not explicitly included
3. **SDL_VIDEODRIVER=wayland may conflict with Steam UI** - Steam needs X11 for launcher
4. **Missing XWayland window class rules** in Niri - XWayland windows not properly managed

## Architecture

### Steam Launch Flow on Niri
```
Steam Launcher (X11)
    ↓
XWayland (bridges X11 to Wayland)
    ↓
Niri Window Manager
    ↓
Game (may use X11 or native Vulkan)
```

### Component Requirements
- **Niri**: Must have XWayland support
- **Steam**: System library
- **XWayland**: X11 server implementation for Wayland
- **Gamescope**: Optional SteamOS-compatible compositor layer
- **Proton**: Wine-based compatibility layer for Windows games
- **DBUS**: Inter-process communication

## Documentation Files

- **[TECHNICAL_REFERENCE.md](./TECHNICAL_REFERENCE.md)** - Detailed technical implementation
- **[CONFIGURATION_FIX.md](./CONFIGURATION_FIX.md)** - Step-by-step fixes for current setup
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common errors and solutions
- **[QUICK_START.md](./QUICK_START.md)** - Fast implementation guide

## Related Topics

- **Niri Window Manager**: Wayland compositor with XWayland support built-in
- **Gamescope**: SteamOS-compatible Wayland compositor (alternative to fullscreen)
- **Proton**: Compatibility layer (handled by Steam automatically)
- **MangoHud**: Performance overlay (already configured)
- **GameMode**: CPU governor optimization (already configured)

## Key References

- NixOS Steam module: `programs.steam`
- Niri upstream: https://github.com/YaLTeR/niri
- Steam Proton: https://github.com/ValveSoftware/Proton
- XWayland protocol: https://wayland.freedesktop.org/

## See Also

For Discord on Niri, see: `../discord-niri/` - Similar Wayland integration patterns
