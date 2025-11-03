{ pkgs, ... }:

let
  # Monitor configuration for KVM setup with EDID override
  monitorConfig = "DP-1,5120x1440@240,0x0,1.0,bitdepth,10";
in

{
  # Hyprland wayland compositor configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;

    settings = {
      # Default applications
      "$terminal" = "ghostty";
      "$fileManager" = "nautilus";
      "$browser" = "chromium";

      # Monitor configuration
      # monitor = ",highres,auto,1";
      # monitor = "DP1, 5120x1440@120, 0x0, 1";
      monitor = [
        monitorConfig
        # Fallback for any disconnected/reconnected monitors
        ",preferred,auto,1"
      ];
      # Environment variables - basics only
      env = [
        "XCURSOR_SIZE,24"
        "GDK_BACKEND,wayland"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        scroll_factor = 1.0;
        scroll_method = "2fa";
        touchpad = {
          natural_scroll = false;
        };
      };

      # General settings - minimal
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffff)";
        "col.inactive_border" = "rgba(595959ff)";
        layout = "master";
        # allow_tearing = false;
      };

      # Basic decoration
      decoration = {
        rounding = 0;
        blur = {
          enabled = false;
        };
      };

      # Disable animations
      animations = {
        enabled = true;
      };

      # Disable news
      ecosystem = {
        no_update_news = true;
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        single_window_aspect_ratio = "16 9";
      };

      # Master layout
      master = {
        # always_center_master = true;
        slave_count_for_center_master = 0;
        orientation = "center";
        mfact = 0.60;
      };

      misc = {
        # enable_swallow = false;
        focus_on_activate = true;
        mouse_move_focuses_monitor = true;
      };

      # Window rules
      windowrulev2 = [
        # Force webapps (Chromium app mode) to tile
        "tile, class:^(chromium-browser)$"
        "tile, title:^(.*)(WhatsApp|Gmail|Calendar|Notion|ChatGPT|Linear)(.*)$"
      ];

      # Basic keybindings
      bind = [
        "SUPER, return, exec, ghostty"
        "SUPER, space, exec, vicinae toggle"
        "SUPER, W, killactive,"
        "SUPER, ESCAPE, exec, hyprlock"
        "SUPER SHIFT, ESCAPE, exit,"
        "SUPER, R, exec, hyprctl reload"
        # Workspace switching
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        # Focus movement
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
        # Move windows
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        # Floating
        "SUPER, V, togglefloating,"
        # Master layout - set focused window as primary
        "SUPER, M, layoutmsg, swapwithmaster master"
      ];

      # Mouse bindings
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Autostart programs
      exec-once = [
        "vicinae server"
        "hyprpanel"
        "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
      ];
      
      # Layer rules for Vicinae
      layerrule = [
        "blur,vicinae"
        "ignorealpha 0,vicinae"
        "noanim,vicinae"
      ];
    };
  };

  # Minimal required packages
  home.packages = with pkgs; [
    wayland
    libxkbcommon
    xdg-desktop-portal-hyprland
    hyprpolkitagent # PolKit authentication agent for 1Password and other apps
  ];
}
