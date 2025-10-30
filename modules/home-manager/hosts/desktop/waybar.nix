{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  home.file = {
    ".config/waybar/" = {
      source = ../files/waybar;
      recursive = true;
    };
  };

  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        height = 26;
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "tray"
        ];
        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "󰊢";
            active = "󱓻";
          };
        };
        clock = {
          format = "{:%H:%M}";
          tooltip = false;
        };
        tray = {
          spacing = 10;
        };
      }
    ];
  };
}
