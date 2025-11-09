{ ... }:

{
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
            "(.*) - Chromium" = "🌎 $1";
            "(.*) - vim" = " $1";
            "(.*) - nvim" = " $1";
            "(.*) - zsh" = " [$1]";
          };
        };

        # CPU module
        cpu = {
          interval = 15;
          format = "󰻠 {usage}%";
          max-length = 10;
        };

        # Memory module
        memory = {
          interval = 30;
          format = "󰍛 {used:.1f}G";
          max-length = 10;
        };

        # Network module
        network = {
          interval = 2;
          format-ethernet = "󰈀 {bandwidthDownBytes}  {bandwidthUpBytes}";
          format-disconnected = "󰌙 Disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        # Clock module
        clock = {
          format = "󰃰 {:%I:%M %p   %d/%m/%Y}";
        };

        # Backlight module
        # backlight = {
        #   tooltip = false;
        #   format = " {percent}%";
        #   interval = 1;
        #   on-scroll-up = "brightnessctl set +5%";
        #   on-scroll-down = "brightnessctl set 5%-";
        # };
        #
        # Pulseaudio module
        # pulseaudio = {
        #   tooltip = false;
        #   scroll-step = 5;
        #   format = "{icon} {volume}%";
        #   format-muted = "{icon} {volume}%";
        #   on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        #   format-icons = {
        #     default = [
        #       ""
        #       ""
        #       ""
        #     ];
        #   };
        # };

        # System tray
        # tray = {
        #   icon-size = 18;
        #   spacing = 10;
        # };

        # Custom launcher (using vicinae)
        # "custom/launcher" = {
        #   format = " ";
        #   on-click = "vicinae toggle";
        #   on-click-right = "killall vicinae";
        # };

        # Custom power menu
        # "custom/power" = {
        #   format = " ";
        #   on-click = "wlogout";
        # };
      }
    ];

    style = builtins.readFile ../../files/waybar/style.css;
  };

  # Ensure waybar dependencies are available
  #   home.packages = with pkgs; [
  #     brightnessctl
  #     wlogout
  #   ];
}
