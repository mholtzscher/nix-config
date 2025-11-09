{
  # Niri window manager configuration
  # Note: wallpaper is managed by wallpaper.nix via systemd service
  programs.niri.settings = {
    # Monitor configuration
    outputs."DP-1" = {
      mode = {
        width = 5120;
        height = 1440;
        refresh = 240.0;
      };
      position = {
        x = 0;
        y = 0;
      };
      scale = 1.0;
    };

    # Layout settings
    layout = {
      gaps = 16;
      center-focused-column = "always";

      default-column-width = {
        proportion = 0.5;
      };

      preset-column-widths = [
        { proportion = 0.25; }
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
        { fixed = 1920; }
        { fixed = 2560; }
      ];

      struts = {
        left = 8;
        right = 8;
      };

      focus-ring = {
        width = 4;
        active-color = "#6699cc";
        inactive-color = "#505050";
      };

      border = {
        width = 2;
        active-color = "#6699cc";
        inactive-color = "#505050";
      };
    };

    # Input configuration
    input = {
      keyboard.xkb.layout = "us";

      touchpad = {
        tap = true;
        accel-speed = 0.2;
        accel-profile = "adaptive";
      };

      mouse = {
        accel-speed = 0.2;
        accel-profile = "adaptive";
      };
    };

    # Keybindings
    binds = {
      # Applications
      "Mod+Space".action.spawn = [
        "vicinae"
        "toggle"
      ];
      "Mod+T".action.spawn = "ghostty";
      "Mod+E".action.spawn = "nautilus";
      "Mod+B".action.spawn = "firefox";

      # Hotkey overlay
      "Mod+Shift+Slash".action.show-hotkey-overlay = { };

      # Window navigation (Vim-style)
      "Mod+H".action.focus-column-left = { };
      "Mod+L".action.focus-column-right = { };
      "Mod+K".action.focus-window-up = { };
      "Mod+J".action.focus-window-down = { };

      # Window movement
      "Mod+Shift+H".action.move-column-left = { };
      "Mod+Shift+L".action.move-column-right = { };
      "Mod+Shift+K".action.move-window-up = { };
      "Mod+Shift+J".action.move-window-down = { };

      # Workspaces
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+0".action.focus-workspace = 10;

      # Move to workspace
      "Mod+Ctrl+1".action.move-column-to-workspace = 1;
      "Mod+Ctrl+2".action.move-column-to-workspace = 2;
      "Mod+Ctrl+3".action.move-column-to-workspace = 3;
      "Mod+Ctrl+4".action.move-column-to-workspace = 4;
      "Mod+Ctrl+5".action.move-column-to-workspace = 5;
      "Mod+Ctrl+6".action.move-column-to-workspace = 6;
      "Mod+Ctrl+7".action.move-column-to-workspace = 7;
      "Mod+Ctrl+8".action.move-column-to-workspace = 8;
      "Mod+Ctrl+9".action.move-column-to-workspace = 9;
      "Mod+Ctrl+0".action.move-column-to-workspace = 10;

      # Window operations
      "Mod+Q".action.close-window = { };
      "Mod+F".action.maximize-column = { };
      "Mod+Shift+F".action.fullscreen-window = { };

      # Column width
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+R".action.switch-preset-column-width = { };
      "Mod+Shift+R".action.switch-preset-window-height = { };

      # Column positioning
      "Mod+C".action.center-column = { };
      "Mod+Ctrl+C".action.center-visible-columns = { };
      "Mod+Ctrl+F".action.expand-column-to-available-width = { };

      # Quick jumps
      "Mod+Home".action.focus-column-first = { };
      "Mod+End".action.focus-column-last = { };

      # Exit
      "Mod+Shift+E".action.quit = { };
    };

    # Animations
    animations.slowdown = 3.0;

    # Startup programs
    # Note: swaybg is managed via systemd service (see wallpaper.nix)
    spawn-at-startup = [ ];

    prefer-no-csd = true;
  };
}
