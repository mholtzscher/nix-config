# NixOS Desktop Niri composition module
# Wayland composition stack: Niri window manager + DankMaterialShell
{
  flake.modules.homeManager.nixosComposition = {
    # Niri window manager settings
    programs.niri.settings = {
      # Monitor configuration
      outputs."DP-1" = {
        mode = {
          width = 5120;
          height = 1440;
          refresh = 120.0;
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

        # DMS integrates wallpapers into the overview; keep layout background transparent.
        background-color = "transparent";

        default-column-width = {
          proportion = 0.5;
        };

        preset-column-widths = [
          { proportion = 0.25; }
          { proportion = 0.5; }
          { proportion = 0.75; }
        ];

        focus-ring = {
          width = 2;
        };

        border = {
          width = 0;
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
        # DankMaterialShell
        "Mod+Space".action.spawn = [
          "dms"
          "ipc"
          "call"
          "spotlight"
          "toggle"
        ];
        "Mod+V".action.spawn = [
          "dms"
          "ipc"
          "call"
          "clipboard"
          "toggle"
        ];
        "Mod+M".action.spawn = [
          "dms"
          "ipc"
          "call"
          "processlist"
          "focusOrToggle"
        ];
        "Mod+Comma".action.spawn = [
          "dms"
          "ipc"
          "call"
          "settings"
          "focusOrToggle"
        ];
        "Mod+N".action.spawn = [
          "dms"
          "ipc"
          "call"
          "notifications"
          "toggle"
        ];
        "Mod+Y".action.spawn = [
          "dms"
          "ipc"
          "call"
          "dankdash"
          "wallpaper"
        ];
        "Mod+Alt+L".action.spawn = [
          "dms"
          "ipc"
          "call"
          "lock"
          "lock"
        ];

        # Restart DMS shell (workaround for IPC issues after KVM/sleep)
        "Mod+Shift+D".action.spawn = [
          "systemctl"
          "--user"
          "restart"
          "dms.service"
        ];

        # Applications
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

        # Move to workspace and follow
        "Mod+Shift+1".action.move-window-to-workspace = 1;
        "Mod+Shift+2".action.move-window-to-workspace = 2;
        "Mod+Shift+3".action.move-window-to-workspace = 3;
        "Mod+Shift+4".action.move-window-to-workspace = 4;
        "Mod+Shift+5".action.move-window-to-workspace = 5;
        "Mod+Shift+6".action.move-window-to-workspace = 6;
        "Mod+Shift+7".action.move-window-to-workspace = 7;
        "Mod+Shift+8".action.move-window-to-workspace = 8;
        "Mod+Shift+9".action.move-window-to-workspace = 9;
        "Mod+Shift+0".action.move-window-to-workspace = 10;

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

        # Screenshots
        "Mod+Shift+S".action.spawn = [
          "bash"
          "-c"
          "grim -g \"$(slurp)\" - | wl-copy"
        ];
        "Mod+Shift+A".action.spawn = [
          "bash"
          "-c"
          "grim - | wl-copy"
        ];

        # Exit
        "Mod+Shift+E".action.quit = { };
      };

      # Window rules
      window-rules = [
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
        # Steam windows - main interface and friends list
        {
          matches = [
            { app-id = "^steam$"; }
            { title = "^Steam$"; }
            { title = "^Friends List$"; }
          ];
          default-column-width = {
            proportion = 0.5;
          };
        }
        # Steam game windows - allow fullscreen
        {
          matches = [
            { app-id = "^steam_app_.*"; }
          ];
          open-fullscreen = true;
        }
        # Gamescope - Steam's gaming compositor
        {
          matches = [
            { app-id = "^gamescope$"; }
          ];
          open-fullscreen = true;
        }

        # DMS / Quickshell windows - float by default
        {
          matches = [
            { app-id = "^org\\.quickshell$"; }
          ];
          open-floating = true;
        }
      ];

      layer-rules = [
        # Let DMS place wallpapers/blur layers into the Overview/backdrop.
        {
          matches = [
            { namespace = "^quickshell$"; }
          ];
          place-within-backdrop = true;
        }
        {
          matches = [
            { namespace = "dms:blurwallpaper"; }
          ];
          place-within-backdrop = true;
        }
      ];

      # Animations
      animations = {
        slowdown = 3.0;
      };

      # Startup programs
      # Note: wallpaper is managed by DankMaterialShell
      spawn-at-startup = [
        # Solaar applies saved Logitech mouse settings (scroll diversion off)
        # This fixes scroll wheel after KVM switch
        {
          command = [
            "solaar"
            "-w"
            "hide"
          ];
        }
      ];

      prefer-no-csd = true;
    };
  };
}
