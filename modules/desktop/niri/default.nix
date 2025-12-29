{ inputs, ... }:
{
  # Niri window manager - Multi-context (system + home-manager)

  flake.modules.nixos.niri = {
    imports = [ inputs.niri.nixosModules.niri ];

    programs.niri.enable = true;

    # Home-manager config is imported separately via homeManager.niri
  };

  flake.modules.homeManager.niri =
    { ... }:
    {
      # The niri home-manager options come from the NixOS module (inputs.niri.nixosModules.niri)
      # which includes home-manager integration when programs.niri.enable = true

      xdg.configFile."waybar/style.css".source = ../waybar/files/style.css;

      programs.niri.settings = {
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

        layout = {
          gaps = 16;
          center-focused-column = "always";
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

        binds = {
          "Mod+Space".action.spawn = [
            "vicinae"
            "toggle"
          ];
          "Mod+T".action.spawn = "ghostty";
          "Mod+E".action.spawn = "nautilus";
          "Mod+B".action.spawn = "firefox";
          "Mod+Shift+Slash".action.show-hotkey-overlay = { };
          "Mod+H".action.focus-column-left = { };
          "Mod+L".action.focus-column-right = { };
          "Mod+K".action.focus-window-up = { };
          "Mod+J".action.focus-window-down = { };
          "Mod+Shift+H".action.move-column-left = { };
          "Mod+Shift+L".action.move-column-right = { };
          "Mod+Shift+K".action.move-window-up = { };
          "Mod+Shift+J".action.move-window-down = { };
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
          "Mod+Q".action.close-window = { };
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+R".action.switch-preset-column-width = { };
          "Mod+Shift+R".action.switch-preset-window-height = { };
          "Mod+C".action.center-column = { };
          "Mod+Ctrl+C".action.center-visible-columns = { };
          "Mod+Ctrl+F".action.expand-column-to-available-width = { };
          "Mod+Home".action.focus-column-first = { };
          "Mod+End".action.focus-column-last = { };
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
          "Mod+Shift+E".action.quit = { };
        };

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
          {
            matches = [
              { app-id = "^steam_app_.*"; }
            ];
            open-fullscreen = true;
          }
          {
            matches = [
              { app-id = "^gamescope$"; }
            ];
            open-fullscreen = true;
          }
        ];

        animations.slowdown = 3.0;

        spawn-at-startup = [
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

            "niri/workspaces" = {
              format = "{icon}";
              format-icons = {
                "focused" = "";
                "active" = "";
                "default" = "";
              };
            };

            "niri/window" = {
              format = "{}";
              max-length = 50;
              rewrite = {
                "(.*) - Mozilla Firefox" = "🌎 $1";
                "(.*) - Chromium" = "🌎 $1";
                "(.*) - vim" = " $1";
                "(.*) - nvim" = " $1";
                "(.*) - zsh" = " [$1]";
              };
            };

            cpu = {
              interval = 15;
              format = "󰻠 {usage}%";
              max-length = 10;
            };

            memory = {
              interval = 30;
              format = "󰍛 {used:.1f}G";
              max-length = 10;
            };

            network = {
              interval = 2;
              format-ethernet = "󰈀 {bandwidthDownBytes}  {bandwidthUpBytes}";
              format-disconnected = "󰌙 Disconnected";
              tooltip-format = "{ifname}: {ipaddr}/{cidr}";
            };

            clock = {
              format = "󰃰 {:%I:%M %p   %d/%m/%Y}";
            };
          }
        ];
      };
    };
}
