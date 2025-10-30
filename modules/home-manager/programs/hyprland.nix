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
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
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
        workspace_swipe = false;
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

      # Keybindings
      bind = [
        # Program launches
        "SUPER, Return, exec, ghostty"
        "SUPER, D, exec, wofi --show drun"
        "SUPER, E, exec, nautilus"
        
        # Window management
        "SUPER, Q, killactive"
        "SUPER SHIFT, Q, exit"
        "SUPER, V, togglefloating"
        "SUPER, F, fullscreen, 0"
        "SUPER SHIFT, F, fakefullscreen"
        "SUPER, P, pin"
        
        # Focus movement
        "SUPER, Left, movefocus, l"
        "SUPER, Right, movefocus, r"
        "SUPER, Up, movefocus, u"
        "SUPER, Down, movefocus, d"
        "SUPER, H, movefocus, l"
        "SUPER, L, movefocus, r"
        "SUPER, K, movefocus, u"
        "SUPER, J, movefocus, d"
        
        # Window movement
        "SUPER SHIFT, Left, movewindow, l"
        "SUPER SHIFT, Right, movewindow, r"
        "SUPER SHIFT, Up, movewindow, u"
        "SUPER SHIFT, Down, movewindow, d"
        "SUPER SHIFT, H, movewindow, l"
        "SUPER SHIFT, L, movewindow, r"
        "SUPER SHIFT, K, movewindow, u"
        "SUPER SHIFT, J, movewindow, d"
        
        # Window resizing
        "SUPER CTRL, Left, resizeactive, -50 0"
        "SUPER CTRL, Right, resizeactive, 50 0"
        "SUPER CTRL, Up, resizeactive, 0 -50"
        "SUPER CTRL, Down, resizeactive, 0 50"
        
        # Workspace switching
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"
        
        # Move window to workspace
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        "SUPER SHIFT, 0, movetoworkspace, 10"
        
        # Workspace navigation
        "SUPER, Page_Down, workspace, e+1"
        "SUPER, Page_Up, workspace, e-1"
        
        # Layout switching
        "SUPER, S, togglesplit"
        
        # Special workspace (scratchpad)
        "SUPER, Grave, togglespecialworkspace, magic"
        "SUPER SHIFT, Grave, movetoworkspace, special:magic"
        
        # Screenshots
        "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SUPER SHIFT, C, exec, grim - | wl-copy"
        
        # Reload Hyprland config
        "SUPER CTRL, R, exec, hyprctl reload"
      ];

      binde = [
        # Scrolling through workspaces without repeating keybinds
        "SUPER, mouse_down, workspace, e-1"
        "SUPER, mouse_up, workspace, e+1"
        
        # Volume control (if using PipeWire)
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        
        # Brightness control
        ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];

      # Mouse bindings
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
        "SUPER, mouse:274, movewindow"
      ];

      # Exec at launch
      exec-once = [
        "waybar"
        "swww init"
        "dunst"
        "wl-paste --type text/plain --watch cliphist store"
        "wl-paste --type image/png --watch cliphist store"
      ];
    };

      windowrulev2 = [
        # Force apps to specific workspaces
        "workspace 3, class:^(discord)$"
      ];

      # Keybindings
      bind = [
      # Program launches
      "SUPER, Return, exec, ghostty"
      "SUPER, D, exec, wofi --show drun"
      "SUPER, E, exec, nautilus"
      
      # Window management
      "SUPER, Q, killactive"
      "SUPER SHIFT, Q, exit"
      "SUPER, V, togglefloating"
      "SUPER, F, fullscreen, 0"
      "SUPER SHIFT, F, fakefullscreen"
      "SUPER, P, pin"
      
      # Focus movement
      "SUPER, Left, movefocus, l"
      "SUPER, Right, movefocus, r"
      "SUPER, Up, movefocus, u"
      "SUPER, Down, movefocus, d"
      "SUPER, H, movefocus, l"
      "SUPER, L, movefocus, r"
      "SUPER, K, movefocus, u"
      "SUPER, J, movefocus, d"
      
      # Window movement
      "SUPER SHIFT, Left, movewindow, l"
      "SUPER SHIFT, Right, movewindow, r"
      "SUPER SHIFT, Up, movewindow, u"
      "SUPER SHIFT, Down, movewindow, d"
      "SUPER SHIFT, H, movewindow, l"
      "SUPER SHIFT, L, movewindow, r"
      "SUPER SHIFT, K, movewindow, u"
      "SUPER SHIFT, J, movewindow, d"
      
      # Window resizing
      "SUPER CTRL, Left, resizeactive, -50 0"
      "SUPER CTRL, Right, resizeactive, 50 0"
      "SUPER CTRL, Up, resizeactive, 0 -50"
      "SUPER CTRL, Down, resizeactive, 0 50"
      
      # Workspace switching
      "SUPER, 1, workspace, 1"
      "SUPER, 2, workspace, 2"
      "SUPER, 3, workspace, 3"
      "SUPER, 4, workspace, 4"
      "SUPER, 5, workspace, 5"
      "SUPER, 6, workspace, 6"
      "SUPER, 7, workspace, 7"
      "SUPER, 8, workspace, 8"
      "SUPER, 9, workspace, 9"
      "SUPER, 0, workspace, 10"
      
      # Move window to workspace
      "SUPER SHIFT, 1, movetoworkspace, 1"
      "SUPER SHIFT, 2, movetoworkspace, 2"
      "SUPER SHIFT, 3, movetoworkspace, 3"
      "SUPER SHIFT, 4, movetoworkspace, 4"
      "SUPER SHIFT, 5, movetoworkspace, 5"
      "SUPER SHIFT, 6, movetoworkspace, 6"
      "SUPER SHIFT, 7, movetoworkspace, 7"
      "SUPER SHIFT, 8, movetoworkspace, 8"
      "SUPER SHIFT, 9, movetoworkspace, 9"
      "SUPER SHIFT, 0, movetoworkspace, 10"
      
      # Workspace navigation
      "SUPER, Page_Down, workspace, e+1"
      "SUPER, Page_Up, workspace, e-1"
      
      # Layout switching
      "SUPER, S, togglesplit"
      
      # Special workspace (scratchpad)
      "SUPER, Grave, togglespecialworkspace, magic"
      "SUPER SHIFT, Grave, movetoworkspace, special:magic"
      
      # Screenshots
      "SUPER SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
      "SUPER SHIFT, C, exec, grim - | wl-copy"
      
      # Reload Hyprland config
      "SUPER CTRL, R, exec, hyprctl reload"
    ];

    binde = [
      # Scrolling through workspaces without repeating keybinds
      "SUPER, mouse_down, workspace, e-1"
      "SUPER, mouse_up, workspace, e+1"
      
      # Volume control (if using PipeWire)
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      
      # Brightness control
      ", XF86MonBrightnessUp, exec, brightnessctl s 10%+"
      ", XF86MonBrightnessDown, exec, brightnessctl s 10%-"
    ];

    # Mouse bindings
    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
      "SUPER, mouse:274, movewindow"
    ];

    # Exec at launch
    exec-once = [
      "waybar"
      "swww init"
      "dunst"
      "wl-paste --type text/plain --watch cliphist store"
      "wl-paste --type image/png --watch cliphist store"
    ];
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
    wpctl
    brightnessctl
    
    # Misc
    xdg-desktop-portal-hyprland
    libnotify
  ];
}
