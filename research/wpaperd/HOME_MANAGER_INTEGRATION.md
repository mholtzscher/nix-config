# home-manager wpaperd Module Integration Guide

**Research Date:** November 13, 2025  
**Focus:** home-manager `services.wpaperd` module details and limitations

---

## home-manager Module Overview

### Module Location
- **nixpkgs:** `nixpkgs/home-manager/modules/services/wpaperd.nix`
- **home-manager repo:** `home-manager/modules/services/wpaperd.nix`

### Basic Module Structure

```nix
services.wpaperd = {
  enable = bool;      # Enable/disable daemon (default: false)
  settings = attrs;   # Configuration (converted to TOML)
};
```

---

## Supported Configuration Attributes

### Top-Level Sections

Each key in `settings` becomes a `[section]` in the TOML config:

```nix
settings = {
  # Becomes [default] section
  default = { ... };
  
  # Becomes [DP-1] section
  DP-1 = { ... };
  
  # Becomes [HDMI-1] section
  HDMI-1 = { ... };
  
  # Becomes [any] section (fallback)
  any = { ... };
};
```

### Supported Parameters Per Section

```nix
{
  path = string;              # Path to image or directory (REQUIRED for at least one section)
  duration = string;          # "1m", "30s", "1h30m" (humantime format)
  mode = string;              # "fill", "fit", "fit-border-color", "center", "stretch", "tile"
  sorting = string;           # "random", "ascending", "descending"
  transition-time = number;   # Milliseconds (0-10000)
  queue-size = number;        # 0-1000 (images to cache)
  recursive = bool;           # true/false (search subdirectories)
  initial-transition = bool;  # true/false (animate at startup)
  offset = float;             # 0.0-1.0 (image offset on screen)
  group = number;             # Group ID for grouped displays (sync wallpapers)
}
```

---

## Complete Example: Single Display

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
        queue-size = 10;
        recursive = true;
        initial-transition = true;
      };
    };
  };
  
  # Optional: Add wpaperctl for runtime control
  home.packages = with pkgs; [ wpaperd ];
}
```

---

## Complete Example: Multiple Displays

```nix
{ pkgs, ... }:
{
  services.wpaperd = {
    enable = true;
    
    settings = {
      # Global defaults (inherited by all displays)
      default = {
        mode = "fill";
        sorting = "random";
        transition-time = 300;
        queue-size = 10;
        recursive = true;
      };
      
      # Primary display - fast rotation
      DP-1 = {
        path = "/home/michael/Pictures/nature";
        duration = "1m";
      };
      
      # Secondary display - slower rotation
      HDMI-1 = {
        path = "/home/michael/Pictures/abstract";
        duration = "5m";
        # Other settings inherited from [default]
      };
      
      # Optional: Fallback for unspecified displays
      any = {
        path = "/home/michael/Pictures/default";
        duration = "2m";
      };
    };
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

---

## Complete Example: Grouped Displays (Same Wallpaper)

For multiple displays that should show the same wallpaper:

```nix
{ pkgs, ... }:
{
  services.wpaperd = {
    enable = true;
    
    settings = {
      default = {
        path = "/home/michael/Pictures/wallpapers";
        duration = "1m";
        mode = "fill";
        sorting = "random";
        transition-time = 300;
        group = 0;  # All in group 0 sync together
      };
      
      # Both displays in same group (optional, inherits from default)
      DP-1 = {};
      DP-2 = {};
      
      # Alternative: use group key directly
      # DP-1.group = 0;
      # DP-2.group = 0;
    };
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

---

## Nix-to-TOML Conversion Rules

### Basic Conversion

```nix
# Nix input
settings = {
  default = {
    duration = "1m";
    transition-time = 300;
  };
  DP-1 = {
    path = "/path";
  };
}

# Becomes this TOML
# [default]
# duration = "1m"
# transition-time = 300
#
# [DP-1]
# path = "/path"
```

### Attribute Name Conversion

- Hyphens in Nix attribute names are preserved in TOML: `transition-time` → `transition-time`
- Underscores also work: `transition_time` → `transition_time`

### Data Type Conversion

```nix
# String values (require quotes in TOML)
path = "/path/to/images"      # → path = "/path/to/images"
duration = "1m"               # → duration = "1m"
mode = "fill"                 # → mode = "fill"

# Number values (no quotes in TOML)
transition-time = 300         # → transition-time = 300
queue-size = 10               # → queue-size = 10
group = 0                      # → group = 0

# Boolean values
recursive = true              # → recursive = true
initial-transition = false    # → initial-transition = false
```

---

## Module Limitations

### NOT Supported in `services.wpaperd` Module

The home-manager module has limitations for advanced features:

#### 1. Regex Patterns for Display Names

**NOT SUPPORTED:**
```nix
# This WON'T WORK in home-manager module
settings = {
  "re:DP-\\d" = {        # ❌ Regex not supported
    path = "/path";
  };
};
```

**WORKAROUND:** Use manual TOML configuration with systemd service

```nix
{
  home.file.".config/wpaperd/config.toml".text = ''
    ["re:DP-\\d"]
    path = "/path/to/images"
  '';
  
  systemd.user.services.wpaperd = {
    # ... service definition
  };
}
```

#### 2. Complex Transition Configurations

**NOT SUPPORTED:**
```nix
# Advanced transition configuration
settings = {
  DP-1 = {
    transition.fade.duration = 500;  # ❌ Nested tables not supported
  };
};
```

**WORKAROUND:** Manual TOML

```nix
{
  home.file.".config/wpaperd/config.toml".text = ''
    [DP-1]
    path = "/path"
    
    [DP-1.transition.fade]
    duration = 500
  '';
}
```

#### 3. Script Execution on Wallpaper Change

**NOT SUPPORTED:**
```nix
# exec parameter not exposed in module
settings = {
  DP-1 = {
    exec = "/path/to/script";  # ❌ Not supported
  };
};
```

**WORKAROUND:** Manual TOML

```nix
{
  home.file.".config/wallpaper-change.sh" = {
    executable = true;
    text = ''
      #!/bin/bash
      # Do something when wallpaper changes
    '';
  };
  
  home.file.".config/wpaperd/config.toml".text = ''
    [default]
    exec = "''${HOME}/.config/wallpaper-change.sh"
    path = "''${HOME}/Pictures/wallpapers"
  '';
}
```

#### 4. Split Transition Configurations Per Display

**NOT SUPPORTED:**
```nix
settings = {
  DP-1 = {
    "transition.directional".direction = [1.0, 0.0];  # ❌
  };
};
```

**WORKAROUND:** Manual TOML

```nix
{
  home.file.".config/wpaperd/config.toml".text = ''
    [DP-1]
    path = "/path"
    
    [DP-1.transition.directional]
    direction = [1.0, 0.0]
  '';
}
```

---

## When to Use Manual TOML vs Module

### Use `services.wpaperd` Module When:

✅ Single or multiple simple displays  
✅ Each display has a fixed, known name (DP-1, HDMI-A-1, etc.)  
✅ Standard transitions (fade, default)  
✅ No need for display regex matching  
✅ No custom exec scripts  
✅ Want clean, declarative config  

### Use Manual TOML + Systemd Service When:

❌ Need regex patterns for display names  
❌ Need complex transition configs  
❌ Need exec hooks for custom scripts  
❌ Laptop with variable docking setups  
❌ Advanced grouped display scenarios  

---

## Migration: swaybg to wpaperd

### Old Configuration (Static Wallpaper with swaybg)

```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [ swaybg ];
  
  systemd.user.services.swaybg = {
    Unit = {
      Description = "Wayland wallpaper";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i /path/to/wallpaper.jpg -m fill";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
```

### New Configuration (Rotating with wpaperd)

```nix
{ pkgs, ... }:
{
  # Remove swaybg
  # home.packages = with pkgs; [ swaybg ];  # DELETE THIS
  
  # Add wpaperd
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
  
  # Remove old swaybg service
  # systemd.user.services.swaybg = null;  # Or delete the entire section
}
```

---

## Service Lifecycle

### What the Module Provides

When you enable `services.wpaperd`, home-manager:

1. **Generates** `.config/wpaperd/config.toml` from `settings`
2. **Creates** a systemd user service unit
3. **Enables** automatic startup as part of graphical session
4. **Manages** service on rebuild/switch operations

### Automatic Service

```bash
# Check service status
systemctl --user status wpaperd

# View generated config
cat ~/.config/wpaperd/config.toml

# View service file
systemctl --user cat wpaperd

# Real-time logs
journalctl --user -u wpaperd -f
```

### Manual Service Control (Even with Module)

```bash
# Start/stop
systemctl --user start wpaperd
systemctl --user stop wpaperd

# Restart (reload config)
systemctl --user restart wpaperd

# View logs
journalctl --user -u wpaperd -n 50

# Check why it failed
journalctl --user -u wpaperd | grep -i error
```

---

## Debugging Module Configuration

### Check Generated Config

```bash
# After running `home-manager switch`
cat ~/.config/wpaperd/config.toml

# Should contain your settings converted to TOML format
```

### Validate TOML Syntax

```bash
# Check if TOML is valid
nix-shell -p toml-cli --run "toml ~/.config/wpaperd/config.toml"
```

### Test Service

```bash
# Stop current service
systemctl --user stop wpaperd

# Run with output to see errors
~/.nix-profile/bin/wpaperd

# In another terminal, check service status
wpaperctl status
```

### Common Module Errors

**Error: "Missing required setting"**
```nix
# Need at least one section with 'path'
settings = {
  default = {
    duration = "1m"  # ❌ ERROR - no path
  };
};

# Fix:
settings = {
  default = {
    path = "/path";  # ✅ Add path
    duration = "1m";
  };
};
```

**Error: Invalid transition-time**
```nix
# transition-time must be a number (milliseconds)
settings = {
  default = {
    transition-time = "300ms"  # ❌ String - WRONG
  };
};

# Fix:
settings = {
  default = {
    transition-time = 300  # ✅ Number in ms
  };
};
```

---

## Example: Host-Specific wpaperd Config

Using home-manager host-specific configuration:

```nix
# modules/home-manager/hosts/nixos-desktop/default.nix
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
        queue-size = 10;
        recursive = true;
      };
    };
  };
  
  home.packages = with pkgs; [
    wpaperd
    # other tools...
  ];
}
```

### In home.nix

```nix
# modules/home-manager/home.nix
{ lib, currentSystemName, ... }:
{
  imports = [
    ./programs
    (lib.mkIf (currentSystemName == "nixos-desktop") ./hosts/nixos-desktop)
  ];
}
```

---

## Performance Tips

### For Large Collections (500+)

```nix
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        path = "/home/michael/Pictures/wallpapers";
        duration = "1m";
        mode = "fill";
        sorting = "random";
        
        # Optimization: smaller queue
        queue-size = 5;
        
        # Optimization: faster transitions (less CPU)
        transition-time = 200;
        
        # Optimization: search subdirectories
        recursive = true;
      };
    };
  };
}
```

### For Very Large Collections (5000+)

```nix
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        path = "/home/michael/Pictures/wallpapers/category1";
        duration = "1m";
        mode = "fill";
        sorting = "random";
        
        # Minimal settings for performance
        queue-size = 3;
        transition-time = 100;
        recursive = true;
      };
    };
  };
}
```

---

## Quick Reference

### Minimal Configuration

```nix
{
  services.wpaperd = {
    enable = true;
    settings.DP-1.path = "/home/michael/Pictures/wallpapers";
  };
  
  home.packages = with pkgs; [ wpaperd ];
}
```

### Common Settings

```nix
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = {
        mode = "fill";
        sorting = "random";
        transition-time = 300;
      };
      DP-1.path = "/home/michael/Pictures/wallpapers";
      DP-1.duration = "1m";
    };
  };
}
```

### Multi-Display

```nix
{
  services.wpaperd = {
    enable = true;
    settings = {
      default = { mode = "fill"; sorting = "random"; };
      DP-1 = { path = "/path1"; duration = "1m"; };
      HDMI-1 = { path = "/path2"; duration = "5m"; };
    };
  };
}
```

---

**Document Version:** 1.0  
**Last Updated:** November 13, 2025  
**Status:** Complete
