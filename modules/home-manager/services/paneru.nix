{
  lib,
  pkgs,
  inputs,
  isWork,
  ...
}:
{
  imports = [
    inputs.paneru.homeModules.paneru
  ];

  # Paneru - sliding, tiling window manager for macOS (Niri-like)
  # Only enabled on macOS
  config = lib.mkIf pkgs.stdenv.isDarwin {
    # Add paneru to PATH for CLI access (install, start, stop commands)
    # home.packages = [ inputs.paneru.packages.${pkgs.system}.paneru ];

    services.paneru = {
      enable = true;
      settings = {
        options = {
          focus_follows_mouse = true;
          preset_column_widths = [
            0.25
            0.5
            0.66
            0.75
            1
          ];
          # 4-finger swipe to move windows (doesn't clash with 3-finger workspace switching)
          swipe_gesture_fingers = 4;
          animation_speed = 4000;
        };
        bindings = {
          # Window focus navigation (using alt-ctrl-cmd like your Aerospace config)
          window_focus_west = "alt + ctrl + cmd - h";
          window_focus_east = "alt + ctrl + cmd - l";
          window_focus_north = "alt + ctrl + cmd - k";
          window_focus_south = "alt + ctrl + cmd - j";

          # Window swapping
          window_swap_west = "alt + shift - h";
          window_swap_east = "alt + shift - l";

          # Jump to first/last windows
          window_focus_first = "alt + ctrl + cmd + shift - h";
          window_focus_last = "alt + ctrl + cmd + shift - l";

          # Move window to first/last position
          window_swap_first = "alt + shift + ctrl - h";
          window_swap_last = "alt + shift + ctrl - l";

          # Center current window on screen
          window_center = "alt + ctrl + cmd - c";

          # Cycle window sizes
          window_resize = "alt + ctrl + cmd - r";

          # Toggle floating/tiling
          window_manage = "alt + ctrl + cmd - minus";

          # Stack/unstack windows
          window_stack = "alt - bracketright";
          window_unstack = "alt + shift - bracketright";

          # Quit paneru
          quit = "ctrl + alt - q";
        };
      };
    };
  };
}
