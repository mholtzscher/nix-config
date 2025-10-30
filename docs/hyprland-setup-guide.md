# Hyprland Setup Guide

Complete guide for getting started with Hyprland on your NixOS desktop.

## Prerequisites

Make sure you've applied the Hyprland configuration:

```bash
cd ~/.config/nix-config
nup  # or: sudo nixos-rebuild switch --flake ~/.config/nix-config#nixos
```

## Initial Boot & Login

### Step 1: Reboot
```bash
reboot
```

### Step 2: Select Hyprland at Login

1. At the GDM (GNOME Display Manager) login screen
2. Click the **gear icon ⚙️** in the bottom-right corner
3. Select **Hyprland** from the session menu
4. Log in with your user credentials

### Step 3: Hyprland Starts

After login, you'll see:
- Empty desktop with dark background
- **Waybar** status bar at the bottom (showing workspaces, clock, battery, volume)
- Ready to use!

## First Steps

### Open Your First Application

Press `Super+Return` to open **Ghostty** terminal:

```bash
Super+Return
```

You should see a terminal window open at the bottom of the screen.

### Launch Applications

Use **Wofi** (app launcher) with `Super+D`:

```bash
Super+D
```

A centered window will appear with an application search. Type to find apps:
- `firefox` - Web browser
- `nautilus` - File manager  
- `discord` - Chat application
- `ghostty` - Terminal emulator

### Navigate Windows

Use keyboard to move between windows:
- `Super+H` or `Super+Left` - Focus left
- `Super+L` or `Super+Right` - Focus right
- `Super+K` or `Super+Up` - Focus up
- `Super+J` or `Super+Down` - Focus down

### Switch Workspaces

Hyprland has 10 workspaces by default:
- `Super+1` through `Super+9` - Switch to workspace
- `Super+0` - Switch to workspace 10
- `Super+Page_Down` - Next workspace
- `Super+Page_Up` - Previous workspace

## Complete Keybinding Reference

### Window Management

| Keybinding | Action |
|------------|--------|
| `Super+Return` | Open terminal (Ghostty) |
| `Super+D` | Open app launcher (Wofi) |
| `Super+E` | Open file manager (Nautilus) |
| `Super+Q` | Close active window |
| `Super+Shift+Q` | Exit Hyprland (requires confirmation) |
| `Super+V` | Toggle floating mode |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+F` | Toggle fake fullscreen |
| `Super+P` | Pin window (always visible) |
| `Super+S` | Toggle split layout |

### Window Focus & Movement

| Keybinding | Action |
|------------|--------|
| `Super+H` / `Super+Left` | Focus window to the left |
| `Super+L` / `Super+Right` | Focus window to the right |
| `Super+K` / `Super+Up` | Focus window above |
| `Super+J` / `Super+Down` | Focus window below |
| `Super+Shift+H` / `Super+Shift+Left` | Move window left |
| `Super+Shift+L` / `Super+Shift+Right` | Move window right |
| `Super+Shift+K` / `Super+Shift+Up` | Move window up |
| `Super+Shift+J` / `Super+Shift+Down` | Move window down |
| `Super+Ctrl+H` / `Super+Ctrl+Left` | Resize: shrink width |
| `Super+Ctrl+L` / `Super+Ctrl+Right` | Resize: grow width |
| `Super+Ctrl+K` / `Super+Ctrl+Up` | Resize: shrink height |
| `Super+Ctrl+J` / `Super+Ctrl+Down` | Resize: grow height |

### Workspace Management

| Keybinding | Action |
|------------|--------|
| `Super+1` to `Super+9` | Switch to workspace 1-9 |
| `Super+0` | Switch to workspace 10 |
| `Super+Page_Down` | Go to next workspace |
| `Super+Page_Up` | Go to previous workspace |
| `Super+Shift+1` to `Super+Shift+9` | Move window to workspace 1-9 |
| `Super+Shift+0` | Move window to workspace 10 |
| `Super+`Grave`` | Toggle special workspace (scratchpad) |
| `Super+Shift+`Grave`` | Move window to special workspace |

### Screenshots & Media

| Keybinding | Action |
|------------|--------|
| `Super+Shift+S` | Screenshot selection (copies to clipboard) |
| `Super+Shift+C` | Screenshot fullscreen (copies to clipboard) |
| `XF86AudioRaiseVolume` | Increase volume by 5% |
| `XF86AudioLowerVolume` | Decrease volume by 5% |
| `XF86AudioMute` | Toggle mute |
| `XF86MonBrightnessUp` | Increase brightness by 10% |
| `XF86MonBrightnessDown` | Decrease brightness by 10% |

### Mouse Controls

| Keybinding | Action |
|------------|--------|
| `Super+Mouse Left Click` | Move window |
| `Super+Mouse Right Click` | Resize window |

## Waybar (Status Bar)

The bottom panel shows:

- **Left side:** Workspace buttons (click to switch)
  - Colored button = active workspace
  - Dark buttons = inactive workspaces
  - Hover for workspace number

- **Center:** Current window title

- **Right side:** System information
  - **Tray icons** - System app icons
  - **Clock** - Current time (click for calendar)
  - **Battery** - Battery percentage and status
  - **Volume** - Audio volume (click to open mixer)

### Waybar Interactions

- Click workspace buttons to switch
- Click clock to see calendar
- Click volume icon to open PulseAudio mixer
- Scroll on workspace buttons to navigate

## Useful Applications

### File Manager
```bash
Super+E
# or
nautilus
```

### Web Browser
```bash
firefox
```

### Text Editor (with mouse)
```bash
Super+D  # Open Wofi
# Type: zed or helix or nano
```

### System Monitor
```bash
bottom
```

### Discord
```bash
discord
```

## Customization

### Change Keybindings

Edit: `~/.config/nix-config/modules/home-manager/programs/hyprland.nix`

Look for the `extraConfig` section with `bind =` lines.

Example:
```nix
extraConfig = ''
  bind = SUPER, Return, exec, ghostty  # Super+Return opens ghostty
  bind = SUPER, D, exec, wofi --show drun  # Super+D opens wofi
  # Add your custom bindings here
'';
```

After editing, rebuild:
```bash
nup
# Then press: Super+Ctrl+R to reload Hyprland
# Or reboot for full reload
```

### Change Monitor Configuration

Edit: `~/.config/nix-config/modules/home-manager/programs/hyprland.nix`

Find the `monitor` section:
```nix
monitor = [
  ",preferred,auto,1"  # Auto-detect and arrange
];
```

For manual configuration:
```nix
monitor = [
  "HDMI-1, 1920x1080@60, 0x0, 1"      # Primary monitor
  "DP-2, 1920x1080@60, 1920x0, 1"     # Secondary to the right
];
```

### Change Workspace Count

Edit the `workspace` setting to add/remove workspaces:
```nix
workspace = [
  "1, monitor:,default:true"
  "2, monitor:"
  "3, monitor:"
  # ... up to 10
];
```

### Customize Appearance

- **Colors:** Edit `settings.general.col.active_border` and `col.inactive_border`
- **Gaps:** Edit `settings.general.gaps_in` and `gaps_out`
- **Border size:** Edit `settings.general.border_size`
- **Rounded corners:** Edit `settings.decoration.rounding`

## Troubleshooting

### Hyprland Won't Start

1. Check if you're using the correct GPU drivers
2. Try GNOME session first from GDM
3. Check logs:
   ```bash
   journalctl -xe | grep -i hyprland
   ```

### Mouse cursor invisible or flickering

This should be fixed by the configuration, but if not:
- The fix is already applied: `WLR_NO_HARDWARE_CURSORS = "1"`
- Ensure NVIDIA drivers are properly loaded

### Some applications won't launch

Some X11 applications may have issues. XWayland is enabled for compatibility.

Try running in Wayland mode:
```bash
# For Electron apps
NIXOS_OZONE_WL=1 app-name
```

### Changing back to GNOME temporarily

At GDM login screen, click the gear icon and select "GNOME" to switch sessions.

To switch back: Log out, select Hyprland from gear icon, log in.

### Audio not working

Check if PulseAudio/PipeWire is running:
```bash
pactl info
# or
wpctl status
```

Open mixer with:
```bash
pavucontrol
```

## Performance Tips

### Disable animations for faster performance
```nix
# In hyprland.nix settings:
animations = {
  enabled = false;  # Set to false
};
```

### Reduce blur effect
```nix
decoration = {
  blur = {
    enabled = false;  # Or reduce passes
    passes = 1;  # Default is 1
  };
};
```

### Optimize for NVIDIA
The configuration already includes:
- Hardware cursor disabled (prevents flickering)
- Modesetting enabled
- Proper kernel parameters

## Switching Back to GNOME

If you want to temporarily use GNOME:

1. Log out (Super+Shift+Q or click power button in top-right of Waybar)
2. At GDM login, click **gear icon ⚙️**
3. Select **GNOME**
4. Log in

To switch back to Hyprland, repeat with selecting **Hyprland**.

## Advanced Configuration

### Add custom startup script

Edit `hyprland.nix` and add to `exec-once`:
```nix
exec-once = [
  "waybar"
  "swww init"
  "dunst"
  # Your custom startup commands here
  "notify-send 'Hyprland started!'"
];
```

### Create window rules

Edit the `windowrule` and `windowrulev2` sections:
```nix
windowrule = [
  "float, class:pavucontrol"
  "size 800 600, class:pavucontrol"
];

windowrulev2 = [
  "workspace 2, class:firefox"
  "maximize, class:code"
];
```

### Use different terminal

Change the terminal in keybindings:
```nix
extraConfig = ''
  bind = SUPER, Return, exec, <your-terminal-here>
  # Examples: wezterm, alacritty, kitty, foot
'';
```

## Getting Help

### View Hyprland logs
```bash
hyprctl -j monitors        # See monitor info
hyprctl -j workspaces      # See workspace info
hyprctl -j clients         # See open windows
journalctl -u "session-*" --all -n 100  # View system logs
```

### Reload configuration
```bash
# Without restarting Hyprland
Super+Ctrl+R

# Full rebuild (requires reboot)
nup
```

### Reset to default configuration
```bash
cd ~/.config/nix-config
git checkout modules/home-manager/programs/hyprland.nix
nup
```

## Next Steps

1. **Explore the window manager** - Get familiar with the tiling workflow
2. **Customize keybindings** - Make them match your muscle memory
3. **Set up workspaces** - Organize apps by workspace (e.g., workspace 1: terminals, workspace 2: browser, etc.)
4. **Explore Waybar** - Click elements to see what they do
5. **Configure monitor layout** - If using multiple monitors

Enjoy your Hyprland setup! 🎉
