# Steam on NixOS with Niri: Technical Reference

## 1. Understanding the "Unable to open a connection to X" Error

### Root Cause
Steam and many games use X11 libraries (even on Wayland). When the DISPLAY variable is not set correctly or XWayland is not running, applications can't connect to the X11 server.

```
Error: Unable to open a connection to the X server
  ↓
DISPLAY environment variable missing or points to wrong display
  ↓
XWayland server not running or not accessible
  ↓
Steam launcher can't initialize (it requires X11 libraries)
```

### Why This Happens
- **Steam launcher**: Uses X11/GTK UI (not native Wayland)
- **Proton**: Wine-based (has X11 dependencies)
- **Most games**: Even Vulkan games may need XWayland for compatibility
- **Window managers**: X11 windows need a bridge to Wayland (XWayland)

## 2. Niri's XWayland Support

### XWayland in Niri
**Status**: ✅ Built-in and enabled by default

```
Niri Wayland Compositor
  ├── Native Wayland clients (Firefox, Wayland apps)
  │   └── Rendered directly
  └── X11 clients (Steam, games)
      └── XWayland bridge
          └── Rendered via GPU
```

### Niri's XWayland Configuration

Niri has built-in XWayland support that:
1. **Starts XWayland automatically** when first X11 client connects
2. **Assigns DISPLAY variable** (usually `:0` but can vary)
3. **Routes X11 windows** through Wayland rendering pipeline
4. **Applies Niri window management** to X11 windows

### Checking if XWayland is Running

```bash
# Check for XWayland process
ps aux | grep -i xwayland

# Check DISPLAY variable in Niri session
echo $DISPLAY

# Test X11 connection
xdpyinfo
```

## 3. NixOS Steam Module Configuration

### Program Module Options

```nix
# Location: modules/programs/steam.nix (NixOS)
programs.steam = {
  enable = true;                          # Enable Steam
  
  # Gamescope integration
  gamescopeSession.enable = true;         # Enable Steam gamescope session
  
  # Firewall rules (set to false for most users)
  remotePlay.openFirewall = false;        # Steam Remote Play
  dedicatedServer.openFirewall = false;   # Source Dedicated Server
  localNetworkGameTransfers.openFirewall = false;  # Local network transfers
};
```

### What `gamescopeSession.enable = true` Does

1. **Installs gamescope**: SteamOS-compatible Wayland compositor
2. **Adds Steam session**: Available in login manager
3. **Creates launcher script**: `/run/current-system/sw/bin/steamos-session-launcher`
4. **Enables fullscreen optimization**: Gamescope can run games fullscreen

**Important**: Gamescope is optional but recommended. It:
- Provides better game isolation
- Handles fullscreen properly on Wayland
- Manages resolution switching
- Can run as nested compositor

### Steam Runtime

The NixOS Steam module also:
```nix
# Automatically installed packages
steam-runtime           # Compatibility libraries for older games
proton                  # Wine-based Windows game compatibility
steamtinkerlaunch       # Game launcher tweaks
```

## 4. Environment Variables for Steam

### Critical Variables

#### SDL_VIDEODRIVER
```bash
# Current configuration
SDL_VIDEODRIVER = "wayland"

# Issue: Steam launcher may not support pure Wayland
# Solution: Let SDL auto-detect or use "x11" for launcher
SDL_VIDEODRIVER = "x11"  # For Steam launcher
# Games will override this if needed
```

#### DISPLAY
```bash
# Current configuration
DISPLAY = ":0"

# Problem: Hardcoded value may not match actual XWayland display
# XWayland typically uses :0, but can vary if multiple X servers running

# Better approach: Auto-detect or use environment from Niri
DISPLAY = "$(if [ -z "$DISPLAY" ]; then echo ":0"; else echo "$DISPLAY"; fi)"

# Or let Niri/system set it automatically (don't override)
```

#### DBUS_SESSION_BUS_ADDRESS
```bash
DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus"

# This is correct and allows Steam/XWayland to communicate via D-Bus
# D-Bus needed for:
# - XWayland to talk to Wayland compositor
# - Portal communications (file dialogs, etc.)
# - Service integration
```

### Optional but Recommended

```bash
# Enable Wayland protocol support
WAYLAND_DISPLAY = "wayland-0"  # Set by Niri automatically

# PipeWire for audio (already configured in nixos-desktop.nix)
PIPEWIRE_RUNTIME_DIR = "$XDG_RUNTIME_DIR"

# Proton-specific optimizations
PROTON_USE_WINESERVER64 = "1"  # Use 64-bit wine server
PROTON_NO_ESYNC = "0"          # Enable esync (performance)
PROTON_NO_FSYNC = "0"          # Enable fsync (performance)

# DXVK optimization (if using DXVK)
# DXVK_ASYNC = "1"              # Async compilation (use cautiously)
# DXVK_HUD = "fps"              # Show FPS overlay

# VKD3D for DirectX 12 games
VKD3D_SHADER_CACHE_PATH = "$HOME/.cache/vkd3d-proton"
```

## 5. Graphics Stack Integration

### NVIDIA Configuration (from your setup)

```nix
hardware.nvidia = {
  modesetting.enable = true;      # Required for Wayland + NVIDIA
  open = false;                   # Using proprietary driver
  package = config.boot.kernelPackages.nvidiaPackages.stable;
};

boot.kernelParams = [
  "nvidia-drm.modeset=1"          # Required for Wayland
];
```

### 32-bit Support for Games

```nix
hardware.graphics = {
  enable = true;
  enable32Bit = true;             # CRITICAL: 32-bit games need this
};
```

### VA-API and VDPAU

```nix
# For hardware video decoding in games
hardware.graphics.extraPackages = with pkgs; [
  libva-nvidia-driver  # NVIDIA VA-API support
  nvidia-vaapi-driver  # Alternative NVIDIA VA-API
];

hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
  libva-nvidia-driver
  nvidia-vaapi-driver
];
```

## 6. System-Level Configuration

### XWayland Package Installation

```nix
environment.systemPackages = with pkgs; [
  xwayland      # X11 server for Wayland (MUST have)
  xorg.xhost    # X11 host access control
  xorg.xdpyinfo # X11 display information
];
```

### D-Bus and XDG Portals

```nix
xdg.portal = {
  enable = true;
  extraPortals = [
    pkgs.xdg-desktop-portal-gnome
    pkgs.xdg-desktop-portal-gtk
  ];
};
```

These provide:
- File dialogs in games
- Portal protocol for Wayland
- Screen capture support

## 7. Niri Window Manager Integration

### XWayland Window Rules

In Niri configuration (home.nix or composition.nix):

```nix
programs.niri.settings = {
  # Window rules for X11/XWayland applications
  window-rules = [
    # Steam launcher
    {
      matches = [
        { app-id = "steam"; }
      ];
      default-column-width = { proportion = 0.6; };
    }
    
    # Games (typically fullscreen)
    {
      matches = [
        { app-id = "steamgames"; }  # Many games use this
      ];
      # Allow fullscreen
      allow-fullscreen = true;
    }
    
    # Gamescope (if using gamescope session)
    {
      matches = [
        { app-id = "gamescope"; }
      ];
      allow-fullscreen = true;
    }
  ];
};
```

### Niri Input Methods (IME)

```nix
programs.niri.settings = {
  # Enable input method support for X11 apps
  input = {
    keyboard = {
      xkb = {
        layout = "us";
        # XWayland will use this for X11 applications
      };
    };
  };
};
```

## 8. Gamescope Compositor (Alternative Setup)

### What is Gamescope?

Gamescope is a SteamOS 3 compositor:
- Runs as a nested Wayland compositor within Niri
- Handles game fullscreen mode properly
- Provides resolution scaling
- Optimized for gaming workload

### Using Gamescope Session

```bash
# At Niri greeter, select different session:
- Niri (standard)
- Steam Session (uses gamescope + steam-session-launcher)

# With Steam session:
Niri (host)
  └── Gamescope (nested compositor)
      └── Steam launcher + games
```

### Gamescope Configuration

```nix
# In gaming.nix or similar
# Gamescope is installed via programs.steam.gamescopeSession.enable = true

# Can also be configured with environment variables
sessionVariables = {
  # Gamescope scaling options
  GAMESCOPE_SCALE_FILTER = "nearest";  # Pixel-perfect scaling
  GAMESCOPE_FSR = "ultra";             # FidelityFX Super Resolution quality
};
```

## 9. Proton and Wine Configuration

### Proton Versions

```bash
# Steam automatically manages Proton versions
# Available versions appear in Steam settings → Compatibility

# To force specific Proton version:
PROTON_VERSION=proton-9.0  # Specify version name
```

### Proton Environment Variables

```bash
# Performance optimization
PROTON_CPU_TOPOLOGY="4:2"      # Override detected CPU topology
PROTON_ENABLE_HIDEPID=0        # Required for some games

# Compatibility
PROTON_LOG=1                   # Enable logging to /tmp/proton-*.log
PROTON_USE_WINESERVER64=1      # Use 64-bit wine server (better perf)
```

### Wine/DXVK Debugging

```bash
# Enable DXVK logging
VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json

# Check Vulkan support
vulkaninfo

# Test Vulkan rendering
glxinfo | grep -i vulkan
```

## 10. Performance Tuning

### CPU Governor for Gaming

```nix
# Already configured in nixos-desktop.nix
powerManagement.cpuFreqGovernor = "performance";

# Kernel parameters for gaming
boot.kernel.sysctl = {
  "vm.max_map_count" = 2147483642;  # Required for some Proton games
};
```

### MangoHud Integration

```nix
# Already configured in gaming.nix
sessionVariables = {
  MANGOHUD = "1";                      # Enable overlay
  MANGOHUD_CONFIG = "fps,frametime";   # What to show
};
```

### GameMode Integration

```nix
# Already configured in nixos-desktop.nix
programs.gamemode.enable = true;

# Usage: gamemoderun <game-or-proton-app>
# Optimizes CPU frequency, CPU affinity, process priority
```

## 11. Troubleshooting Checklist

```bash
# 1. Verify Niri is running with XWayland
ps aux | grep niri
ps aux | grep xwayland

# 2. Check DISPLAY variable
echo $DISPLAY           # Should be something like :0
echo $WAYLAND_DISPLAY   # Should be wayland-0

# 3. Test X11 connection
xdpyinfo               # Should work
xhost                  # Should work

# 4. Check D-Bus
echo $DBUS_SESSION_BUS_ADDRESS
systemctl --user status dbus

# 5. Verify Steam package
which steam
steam --version

# 6. Check hardware support
glxinfo | grep "Direct Rendering"  # Should be Yes
vulkaninfo | grep "Device Type"    # Should show NVIDIA GPU

# 7. Review Steam logs
cat ~/.steam/steam/logs/bootstrap.log
cat ~/.steam/steam/logs/error.log

# 8. Test Proton directly
STEAM_COMPAT_TOOL_PATHS=/var/lib/steam proton run /path/to/game.exe
```

## 12. Configuration Comparison Matrix

| Setting | Current | Issue | Recommended |
|---------|---------|-------|-------------|
| `programs.steam.enable` | ✅ true | - | ✅ true |
| `programs.steam.gamescopeSession` | ✅ true | - | ✅ true |
| `SDL_VIDEODRIVER` | wayland | May not work with Steam launcher | x11 or auto-detect |
| `DISPLAY` | :0 (hardcoded) | ⚠️ May not match actual | ⚠️ Should auto-detect or not set |
| `DBUS_SESSION_BUS_ADDRESS` | ✅ Set | - | ✅ Correct |
| `xwayland` in environment | ❌ Missing | Can't run X11 apps | ✅ Add |
| Niri window rules | ❌ Missing | X11 windows not managed properly | ✅ Add steam/gamescope rules |
| 32-bit graphics | ✅ enabled | - | ✅ enabled |
| Hardware acceleration | ✅ NVIDIA | - | ✅ Working |

## References

- **XWayland**: https://wayland.freedesktop.org/
- **Niri**: https://github.com/YaLTeR/niri
- **Gamescope**: https://github.com/ValveSoftware/gamescope
- **Proton**: https://github.com/ValveSoftware/Proton
- **NixOS Steam**: https://nixos.org/manual/nixos/stable/#module-services-steam
- **NVIDIA + Wayland**: https://wiki.archlinux.org/title/NVIDIA#Wayland
