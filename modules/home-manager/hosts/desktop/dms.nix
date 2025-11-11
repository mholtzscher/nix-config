{ inputs, ... }:
{
  # DankMaterialShell configuration
  # Modern Material Design shell for Wayland compositors
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
    inputs.dankMaterialShell.homeModules.dankMaterialShell.niri
  ];

  programs.dankMaterialShell = {
    enable = true;

    # Core features
    systemd.enable = true; # Systemd service for auto-start
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableClipboard = true; # Clipboard history manager
    enableVPN = false; # VPN management widget
    enableBrightnessControl = true; # Backlight/brightness controls
    enableColorPicker = true; # Color picker tool
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = false; # Calendar integration (khal)
    enableSystemSound = true; # System sound effects

    # Niri integration
    niri = {
      enableKeybinds = true; # Automatic keybinding configuration
      enableSpawn = true; # Auto-start DMS with niri
    };

    # Default settings (applied on first launch)
    default.settings = {
      theme = "dark";
      dynamicTheming = true;
    };
  };
}
