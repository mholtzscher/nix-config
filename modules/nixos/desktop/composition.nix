{ ... }:
{
  # Wayland composition stack: Niri window manager + Waybar status bar
  # This module manages the setup for the desktop environment
  # Note: Niri module is loaded from inputs in lib/default.nix when graphical=true

  # Niri and Waybar user settings via home-manager
  home-manager.sharedModules = [
    {
      # Niri window manager settings
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
          border = "off";
          focus-ring = {
            width = 2;
            # active-color = "#6699cc";
            # inactive-color = "#505050";
          };

          default-column-width = {
            proportion = 0.5;
          };

          preset-column-widths = [
            { proportion = 0.25; }
            { proportion = 0.5; }
            { proportion = 0.75; }
          ];
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
        animations.slowdown = 1.5;

        # Startup programs
        # Note: swaybg is managed via systemd service (see wallpaper module)
        spawn-at-startup = [ ];

        prefer-no-csd = true;
      };

      # Waybar status bar configuration
      programs.waybar = {
        enable = true;
        systemd.enable = true;

        settings = [
          {
            layer = "top";
            modules-left = [
              "cpu"
              "memory"
              "network"
            ];
            modules-center = [
              "niri/workspaces"
            ];
            modules-right = [
              "niri/window"
              "clock"
            ];

            # Niri workspaces
            "niri/workspaces" = {
              format = "{icon}";
              format-icons = {
                # Icons by state
                "focused" = "";
                "active" = "";
                "default" = "";
              };
            };

            # Niri window
            "niri/window" = {
              format = "{}";
              max-length = 50;
              rewrite = {
                "(.*) - Mozilla Firefox" = "🌎 $1";
                "(.*) - Zed" = "󰣇 $1";
                "(.*) - Ghostty" = " $1";
              };
            };

            # CPU
            cpu = {
              interval = 1;
              format = "CPU: {usage:>2}%";
              states = {
                "warning" = 50;
                "critical" = 80;
              };
            };

            # Memory
            memory = {
              interval = 1;
              format = "RAM: {used:>4}/{total:>4} GB";
              states = {
                "warning" = 70;
                "critical" = 90;
              };
            };

            # Network
            network = {
              interval = 5;
              format-wifi = "󰖩 {essid}";
              format-ethernet = "󰌐 Wired";
              format-disconnected = "󰌐 Offline";
              tooltip-format = "{ifname}: {ipaddr}/{cidr}";
            };

            # Clock
            clock = {
              interval = 1;
              format = "{:%H:%M:%S}";
              tooltip-format = "{:%Y-%m-%d | %A}";
            };
          }
        ];

        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: Iosevka Nerd Font;
            font-size: 12px;
            min-height: 0;
          }

          window#waybar {
            background-color: alpha(@theme_bg_color, 0.9);
            color: @theme_fg_color;
            margin: 0px;
            padding: 0px;
          }

          #cpu, #memory, #network, #niri-workspaces, #niri-window, #clock {
            padding: 10px 15px;
            margin: 0px 5px;
            background-color: alpha(@theme_bg_color, 0.5);
            border-radius: 5px;
          }

          #cpu.warning {
            color: #f1c40f;
          }

          #cpu.critical {
            color: #e74c3c;
          }

          #memory.warning {
            color: #f1c40f;
          }

          #memory.critical {
            color: #e74c3c;
          }

          #niri-workspaces button {
            padding: 5px 10px;
            color: @theme_fg_color;
            margin: 0px 2px;
          }

          #niri-workspaces button.focused {
            background-color: @theme_selected_bg_color;
            color: @theme_selected_fg_color;
            border-radius: 5px;
          }
        '';
      };
    }
  ];
}
