{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 30;
        margin-top = 0;
        margin-bottom = 0;
        margin-left = 0;
        margin-right = 0;
        spacing = 10;
        
        modules-left = [
          "hyprland/workspaces"
        ];
        
        modules-center = [
          "hyprland/window"
        ];
        
        modules-right = [
          "tray"
          "clock"
          "battery"
          "pulseaudio"
        ];

        "hyprland/workspaces" = {
          all-outputs = true;
          warp-on-scroll = false;
          format = "{name}";
          format-icons = {
            active = "";
            default = "";
          };
        };

        "hyprland/window" = {
          format = "{}";
          rewrite = {
            "(.*) — Mozilla Firefox" = "🌐 $1";
            "(.*) - Google Chrome" = "🌐 $1";
            "(.*) - Visual Studio Code" = "󰨞 $1";
          };
          separate-outputs = false;
        };

        tray = {
          icon-size = 16;
          spacing = 10;
        };

        clock = {
          format = "󰅐 {:%H:%M}";
          format-alt = "󰃭 {:%a, %b %d, %Y}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><big>{calendar}</big></tt>";
        };

        battery = {
          states = {
            good = 80;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "󰂯 {volume}%";
          format-bluetooth-muted = "󰂯 0%";
          format-muted = "󰖁 0%";
          format-source = "󰍬 {volume}%";
          format-source-muted = "󰍭";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󰋎";
            headset = "󰋎";
            phone = "";
            portable = "";
            car = "";
            default = [
              "󰕿"
              "󰖀"
              "󰖉"
            ];
          };
          on-click = "pavucontrol";
          on-click-right = "pwvucontrol --tab=mic";
          scroll-step = 1;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "FiraCode Nerd Font", monospace;
        font-size: 13px;
        min-height: 30px;
        padding: 0;
        margin: 0;
      }

      window#waybar {
        background-color: rgba(30, 30, 46, 0.8);
        border-bottom: 1px solid rgba(166, 173, 200, 0.2);
        color: #cad3f5;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      window#waybar.solo {
        background-color: #1e1e2e;
      }

      #workspaces {
        padding: 0 10px;
        background-color: transparent;
      }

      #workspaces button {
        padding: 0 8px;
        background-color: rgba(88, 86, 214, 0.3);
        color: #cad3f5;
        border-radius: 5px;
        margin: 3px 5px;
        transition: all 300ms ease;
      }

      #workspaces button.active {
        background-color: #5856d6;
        color: #eed49f;
      }

      #workspaces button.urgent {
        background-color: #f38ba8;
        color: #1e1e2e;
      }

      #workspaces button:hover {
        background-color: rgba(100, 112, 255, 0.5);
      }

      #window {
        padding: 0 10px;
        color: #b4befe;
      }

      #window.solo {
        background-color: transparent;
      }

      #tray {
        padding-right: 10px;
        background-color: transparent;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #f38ba8;
      }

      #clock {
        padding: 0 10px;
        background-color: rgba(102, 194, 255, 0.2);
        color: #89b4fa;
        border-radius: 5px;
      }

      #clock.calendar {
        background-color: rgba(102, 194, 255, 0.3);
      }

      #battery {
        padding: 0 10px;
        background-color: rgba(166, 227, 161, 0.2);
        color: #a6e3a1;
        border-radius: 5px;
      }

      #battery.charging,
      #battery.plugged {
        color: #a6e3a1;
        background-color: rgba(166, 227, 161, 0.3);
      }

      #battery.critical:not(.charging) {
        animation: blink_critical 0.5s linear infinite;
        background-color: rgba(243, 139, 168, 0.3);
        color: #f38ba8;
      }

      @keyframes blink_critical {
        to {
          background-color: rgba(243, 139, 168, 0.2);
          color: #fab1a0;
        }
      }

      #battery.warning:not(.charging) {
        animation: blink_warning 1s linear infinite;
        background-color: rgba(249, 226, 175, 0.2);
        color: #f9e2af;
      }

      @keyframes blink_warning {
        to {
          background-color: rgba(249, 226, 175, 0.1);
          color: #f8dc8c;
        }
      }

      #pulseaudio {
        padding: 0 10px;
        background-color: rgba(245, 194, 144, 0.2);
        color: #f5c2a0;
        border-radius: 5px;
      }

      #pulseaudio.muted {
        background-color: rgba(166, 173, 200, 0.2);
        color: #a6adc8;
      }
    '';
  };

  home.packages = with pkgs; [
    waybar
    pavucontrol
  ];
}
