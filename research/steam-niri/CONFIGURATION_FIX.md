# Steam on Niri: Configuration Fix Guide

## Problem Summary

Your NixOS system is configured for Steam + Niri, but the "Unable to open a connection to X" error indicates that:
1. **XWayland package is not installed** - Essential for X11 clients
2. **Environment variables may have conflicts** - SDL_VIDEODRIVER set to wayland conflicts with Steam launcher
3. **Niri lacks XWayland window rules** - Windows not managed properly
4. **DISPLAY is hardcoded** - May not match actual XWayland display

## Current Configuration Issues

### Issue 1: Missing XWayland Package ❌

**File**: `hosts/nixos/nixos-desktop.nix`

**Current**:
```nix
environment.systemPackages = with pkgs; [
  wl-clipboard
  chromium
];
```

**Problem**: XWayland not included, so X11 clients can't connect.

**Fix**: Add xwayland package

```nix
environment.systemPackages = with pkgs; [
  xwayland      # ADD THIS LINE
  xorg.xhost    # X11 host access control
  xorg.xdpyinfo # X11 display info utility
  wl-clipboard
  chromium
];
```

### Issue 2: SDL_VIDEODRIVER Conflict ⚠️

**File**: `modules/nixos/hosts/nixos-desktop/gaming.nix`

**Current**:
```nix
sessionVariables = {
  SDL_VIDEODRIVER = "wayland";  # ⚠️ Problem
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
  DISPLAY = ":0";
};
```

**Problem**: Steam launcher uses X11 and doesn't support pure Wayland SDL driver.

**Fix Option A** (Recommended): Remove SDL_VIDEODRIVER to let it auto-detect
```nix
sessionVariables = {
  # SDL_VIDEODRIVER = "wayland"; # REMOVE THIS LINE
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
  DISPLAY = ":0";
};
```

**Fix Option B**: Explicitly set to X11 for Steam
```nix
sessionVariables = {
  SDL_VIDEODRIVER = "x11";      # Use X11 for Steam compatibility
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
  DISPLAY = ":0";
};
```

**Why**: 
- Steam launcher requires X11 (via XWayland)
- Games can override SDL_VIDEODRIVER if they need native Wayland
- Auto-detect provides best compatibility

### Issue 3: Hardcoded DISPLAY Variable ⚠️

**File**: `modules/nixos/hosts/nixos-desktop/gaming.nix`

**Current**:
```nix
DISPLAY = ":0";  # Hardcoded
```

**Problem**: While `:0` is usually correct for XWayland, hardcoding can cause issues.

**Fix**: Let Niri/system set it (don't override)
```nix
sessionVariables = {
  # Don't set DISPLAY - let Niri handle it
  # Niri will set DISPLAY to the correct XWayland display
  DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
};
```

**Why**:
- Niri starts XWayland automatically
- Niri sets DISPLAY in the session environment
- Hardcoding can override Niri's detection
- If `:0` doesn't work, manual override in shell: `export DISPLAY=:1`

### Issue 4: Missing Niri Window Rules ❌

**File**: `modules/nixos/hosts/nixos-desktop/composition.nix`

**Current**: X11 window rules missing

**Fix**: Add Steam and game window rules

```nix
programs.niri.settings = {
  # ... existing config ...
  
  # Add this section or merge with existing window-rules
  window-rules = [
    # Existing rules (1password, vesktop) ...
    {
      matches = [
        { app-id = "1password"; }
      ];
      default-column-width = {
        proportion = 0.25;
      };
    }
    {
      matches = [
        { app-id = "vesktop"; }
      ];
      default-column-width = {
        proportion = 0.25;
      };
    }
    
    # NEW: Steam launcher (X11 window)
    {
      matches = [
        { class = "steam"; }  # X11 windows use 'class' instead of 'app-id'
        { class = "steamapps"; }
      ];
      default-column-width = {
        proportion = 0.6;
      };
    }
    
    # NEW: Gamescope window (fullscreen gaming)
    {
      matches = [
        { class = "gamescope"; }
      ];
      # Allow gamescope to go fullscreen
      allow-fullscreen = true;
    }
    
    # NEW: Proton/Wine games (X11)
    {
      matches = [
        { class = "Wine"; }
        { class = "steam_app_.*"; }  # Regex for Steam games
      ];
      allow-fullscreen = true;
      # Don't add window decoration (looks better fullscreen)
      open-maximized = false;
    }
  ];
};
```

**Why**:
- Niri needs window rules for X11 apps (Steam uses X11 via XWayland)
- Window rules control layout, fullscreen behavior, sizing
- `class` attribute is for X11 windows (Steam), `app-id` is for Wayland apps

## Complete Fixed Configuration

### Step 1: Update `hosts/nixos/nixos-desktop.nix`

Add xwayland to system packages:

```nix
environment.systemPackages = with pkgs; [
  # X11 and input handling
  xwayland      # X11 server for Wayland (CRITICAL for Steam)
  xorg.xhost    # X11 host access control
  xorg.xdpyinfo # X11 display information utility
  
  # Clipboard utility for Wayland
  wl-clipboard

  # Browsers
  chromium
];
```

### Step 2: Update `modules/nixos/hosts/nixos-desktop/gaming.nix`

Fix SDL and DISPLAY variables:

```nix
{ pkgs, ... }:
{
  home-manager.sharedModules = [
    {
      home = {
        packages = with pkgs; [
          mangohud
          gamemode
          gamescope
          protonup-qt
          steamtinkerlaunch
        ];

        file.".config/MangoHud/MangoHud.conf".text = ''
          fps
          frametime=0
          cpu_temp
          gpu_temp
          ram
          vram
          position=top-left
          background_alpha=0.5
          font_size=24
          toggle_hud=Shift_R+F12
        '';

        file.".local/bin/steam-gamemode" = {
          executable = true;
          text = ''
            #!/usr/bin/env bash
            exec gamemoderun mangohud steam "$@"
          '';
        };

        # FIXED: Session variables for Steam
        sessionVariables = {
          # Let SDL auto-detect (Wayland for Wayland apps, X11 for Steam)
          # SDL_VIDEODRIVER will auto-select best option
          
          # Essential for D-Bus/XWayland communication
          DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
          
          # Let Niri set DISPLAY - don't override
          # DISPLAY = ":0";  # REMOVED - Niri handles this
          
          # Optional Proton optimizations
          PROTON_USE_WINESERVER64 = "1";
          PROTON_NO_ESYNC = "0";
          PROTON_NO_FSYNC = "0";
        };
      };
    }
  ];
}
```

### Step 3: Update `modules/nixos/hosts/nixos-desktop/composition.nix`

Add window rules for Steam:

```nix
{ ... }:
{
  home-manager.sharedModules = [
    {
      programs.niri.settings = {
        # ... existing config (outputs, layout, input, binds, etc.) ...

        # Window rules - add this or merge with existing
        window-rules = [
          # Existing rules
          {
            matches = [
              { app-id = "1password"; }
            ];
            default-column-width = {
              proportion = 0.25;
            };
          }
          {
            matches = [
              { app-id = "vesktop"; }
            ];
            default-column-width = {
              proportion = 0.25;
            };
          }
          
          # NEW: Steam and games (X11 via XWayland)
          {
            matches = [
              { class = "steam"; }
              { class = "steamapps"; }
            ];
            default-column-width = {
              proportion = 0.6;
            };
          }
          
          {
            matches = [
              { class = "Wine"; }
            ];
            allow-fullscreen = true;
          }
          
          {
            matches = [
              { class = "gamescope"; }
            ];
            allow-fullscreen = true;
          }
        ];

        # ... rest of existing config ...
      };
      
      programs.waybar = {
        # ... existing waybar config ...
      };
    }
  ];
}
```

## Validation Steps

After making changes, validate before applying:

```bash
# 1. Check syntax
nix flake check

# 2. Build (don't apply yet)
nb  # darwin-rebuild build --flake .

# If there are errors, fix them and repeat

# 3. If build succeeds, apply changes
nup  # darwin-rebuild switch --flake . (requires user approval)
```

## Testing After Application

After running `nup`, test Steam:

```bash
# 1. Verify XWayland is installed
which xwayland    # Should show /run/current-system/sw/bin/xwayland

# 2. Start Niri session and verify XWayland starts
ps aux | grep xwayland  # Should see XWayland process

# 3. Check environment variables
env | grep DISPLAY      # Should show something like DISPLAY=:0
env | grep DBUS         # Should show DBUS_SESSION_BUS_ADDRESS

# 4. Test X11 connection
xdpyinfo                # Should work without errors
xhost                   # Should show access control list

# 5. Launch Steam
steam

# 6. If Steam still fails, check logs
cat ~/.steam/steam/logs/bootstrap.log
cat ~/.steam/steam/logs/error.log
```

## Alternative: Using Gamescope Session

If you prefer to use gamescope as the main compositor for gaming:

```bash
# At Niri login greeter (tuigreet), select:
"Steam Session" or "Gamescope"

# This runs:
Niri
  └── Gamescope (nested compositor)
      └── Steam + games

# Advantages:
# - Better fullscreen handling
# - Resolution scaling support
# - Isolated from other desktop apps

# Disadvantages:
# - Can't easily switch between gaming and desktop
# - Performance overhead of nested compositor
```

## Manual Environment Variable Override

If issues persist, you can manually set variables in shell:

```bash
# In ~/.bashrc or ~/.zshrc (add to nushell config similarly)
export DISPLAY=:0          # or try :1, :2 if :0 doesn't work
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export SDL_VIDEODRIVER=x11  # For Steam compatibility

# Then launch Steam
steam
```

## Performance Tuning Options

Optional: Add to gaming.nix sessionVariables for better performance:

```nix
sessionVariables = {
  # ... existing variables ...
  
  # Optional: Performance tuning (advanced)
  # PROTON_CPU_TOPOLOGY = "auto";     # CPU topology for Proton
  # VKD3D_SHADER_CACHE_PATH = "$HOME/.cache/vkd3d-proton";  # Shader cache
  # MANGOHUD = "1";                   # Enable MangoHud always
  # MANGOHUD_CONFIG = "fps,gpu_temp,cpu_temp";  # What to show
};
```

## Rollback If Issues Occur

If something breaks:

```bash
# View recent generations
sudo nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
```

## Summary of Changes

| File | Change | Reason |
|------|--------|--------|
| `hosts/nixos/nixos-desktop.nix` | Add `xwayland`, `xorg.xhost`, `xorg.xdpyinfo` to systemPackages | Enable X11 clients to connect |
| `modules/nixos/hosts/nixos-desktop/gaming.nix` | Remove `SDL_VIDEODRIVER = "wayland"` | Prevent conflict with Steam launcher |
| `modules/nixos/hosts/nixos-desktop/gaming.nix` | Remove `DISPLAY = ":0"` | Let Niri handle display detection |
| `modules/nixos/hosts/nixos-desktop/composition.nix` | Add Steam/game window rules | Proper Niri window management for X11 apps |

All changes are non-breaking and improve compatibility!
