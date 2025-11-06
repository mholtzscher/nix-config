{ pkgs, ... }:

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
          # "custom/launcher"
          # "tray"
          "hyprland/workspaces"
          # "backlight"
          # "pulseaudio"
          # "custom/power"
        ];
        modules-right = [ "clock" ];

        # Hyprland workspaces
        "hyprland/workspaces" = {
          format = "{name}";
          persistent-workspaces = {
            "DP-1" = [
              1
              2
              3
              4
              5
            ];
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

        # Clock module
        clock = {
          format = "󰃰 {:%I:%M %p   %d/%m/%Y}";
        };

        # System tray
        tray = {
          icon-size = 18;
          spacing = 10;
        };

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

    # style = ../../files/waybar/style.css;
  };

  # Ensure waybar dependencies are available
  #   home.packages = with pkgs; [
  #     brightnessctl
  #     wlogout
  #   ];
}
