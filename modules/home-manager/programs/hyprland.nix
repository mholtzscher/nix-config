{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # Hyprland wayland compositor configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    
    settings = {
      # Monitor configuration - adjust based on your display setup
      monitor = [
        ",preferred,auto,1"  # Default monitor config
      ];

      # Keyboard input configuration
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";
        numlock_by_default = false;
        repeat_rate = 25;
        repeat_delay = 600;
        accel_profile = "flat";
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
        allow_tearing = false;
      };

      # Decoration/appearance
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = [
          "myBezier, 0.05, 0.9, 0.1, 1.05"
        ];
        animation = [
          "windows, 1, 10, myBezier"
          "windowsOut, 1, 10, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Dwindle layout configuration
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
      };

      # Master layout configuration
      master = {
        new_is_master = true;
        mfact = 0.55;
      };

      # Gestures
      gestures = {
        workspace_swipe = {
          enabled = false;
        };
      };

      # Device configuration
      device = {
        name = "epic mouse V1";
        sensitivity = -0.5;
      };

      # Workspace configuration
      workspace = [
        "1, monitor:,default:true"
        "2, monitor:"
        "3, monitor:"
        "4, monitor:"
        "5, monitor:"
        "6, monitor:"
        "7, monitor:"
        "8, monitor:"
        "9, monitor:"
        "10, monitor:"
      ];

      # Window rules for specific applications
      windowrule = [
        # Force apps to float
        "float, title:^(Open File)(.*)$"
        "float, title:^(Save As)(.*)$"
        "float, class:^(pavucontrol)$"
      ];

      windowrulev2 = [
        # Force apps to specific workspaces
        "workspace 3, class:^(discord)$"
      ];

      # Startup applications
      exec-once = [
        "waybar"
        "swww init"
        "dunst"
        "wl-paste --type text/plain --watch cliphist store"
        "wl-paste --type image/png --watch cliphist store"
      ];
    };

    # Raw Hyprland configuration - all keybindings in extraConfig
    extraConfig = ''
      # Keybindings - Program launches
      bind = SUPER, Return, exec, ghostty
      bind = SUPER, D, exec, wofi --show drun
      bind = SUPER, E, exec, nautilus
      
      # Window management
      bind = SUPER, Q, killactive
      bind = SUPER SHIFT, Q, exit
      bind = SUPER, V, togglefloating
      bind = SUPER, F, fullscreen, 0
      bind = SUPER SHIFT, F, fakefullscreen
      bind = SUPER, P, pin
      
      # Focus movement
      bind = SUPER, Left, movefocus, l
      bind = SUPER, Right, movefocus, r
      bind = SUPER, Up, movefocus, u
      bind = SUPER, Down, movefocus, d
      bind = SUPER, H, movefocus, l
      bind = SUPER, L, movefocus, r
      bind = SUPER, K, movefocus, u
      bind = SUPER, J, movefocus, d
      
      # Window movement
      bind = SUPER SHIFT, Left, movewindow, l
      bind = SUPER SHIFT, Right, movewindow, r
      bind = SUPER SHIFT, Up, movewindow, u
      bind = SUPER SHIFT, Down, movewindow, d
      bind = SUPER SHIFT, H, movewindow, l
      bind = SUPER SHIFT, L, movewindow, r
      bind = SUPER SHIFT, K, movewindow, u
      bind = SUPER SHIFT, J, movewindow, d
      
      # Window resizing
      bind = SUPER CTRL, Left, resizeactive, -50 0
      bind = SUPER CTRL, Right, resizeactive, 50 0
      bind = SUPER CTRL, Up, resizeactive, 0 -50
      bind = SUPER CTRL, Down, resizeactive, 0 50
      
      # Workspace switching
      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5
      bind = SUPER, 6, workspace, 6
      bind = SUPER, 7, workspace, 7
      bind = SUPER, 8, workspace, 8
      bind = SUPER, 9, workspace, 9
      bind = SUPER, 0, workspace, 10
      
      # Move window to workspace
      bind = SUPER SHIFT, 1, movetoworkspace, 1
      bind = SUPER SHIFT, 2, movetoworkspace, 2
      bind = SUPER SHIFT, 3, movetoworkspace, 3
      bind = SUPER SHIFT, 4, movetoworkspace, 4
      bind = SUPER SHIFT, 5, movetoworkspace, 5
      bind = SUPER SHIFT, 6, movetoworkspace, 6
      bind = SUPER SHIFT, 7, movetoworkspace, 7
      bind = SUPER SHIFT, 8, movetoworkspace, 8
      bind = SUPER SHIFT, 9, movetoworkspace, 9
      bind = SUPER SHIFT, 0, movetoworkspace, 10
      
      # Workspace navigation
      bind = SUPER, Page_Down, workspace, e+1
      bind = SUPER, Page_Up, workspace, e-1
      
      # Layout switching
      bind = SUPER, S, togglesplit
      
      # Special workspace (scratchpad)
      bind = SUPER, grave, togglespecialworkspace, magic
      bind = SUPER SHIFT, grave, movetoworkspace, special:magic
      
      # Screenshots
      bind = SUPER SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
      bind = SUPER SHIFT, C, exec, grim - | wl-copy
      
      # Reload Hyprland config
      bind = SUPER CTRL, R, exec, hyprctl reload
      
      # Continuous keybindings (repeat when held)
      binde = SUPER, mouse_down, workspace, e-1
      binde = SUPER, mouse_up, workspace, e+1
      
      # Volume control (if using PipeWire)
      binde = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      binde = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      
      # Brightness control
      binde = , XF86MonBrightnessUp, exec, brightnessctl s 10%+
      binde = , XF86MonBrightnessDown, exec, brightnessctl s 10%-
      
      # Mouse bindings
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow
      bindm = SUPER, mouse:274, movewindow
    '';
  };

  # Home packages needed for Hyprland
  home.packages = with pkgs; [
    # Hyprland core
    hyprland
    
    # Display and rendering
    wayland
    libxkbcommon
    
    # Essential tools
    waybar
    wofi
    dunst
    swww
    
    # Screenshot and color picker
    grim
    slurp
    hyprpicker
    
    # Clipboard
    wl-clipboard
    cliphist
    
    # Volume and brightness
    wireplumber  # Provides wpctl command
    brightnessctl
    
    # Misc
    xdg-desktop-portal-hyprland
    libnotify
  ];
}
