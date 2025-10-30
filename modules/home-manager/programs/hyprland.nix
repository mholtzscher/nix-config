{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # Hyprland wayland compositor configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    
    settings = {
      # Default applications
      "$terminal" = "ghostty";
      "$fileManager" = "nautilus --new-window";
      "$browser" = "firefox --new-window --ozone-platform=wayland";
      "$music" = "spotify";
      "$passwordManager" = "1password";
      "$messenger" = "discord";
      "$webapp" = "$browser --app";

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
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration/appearance
      decoration = {
        rounding = 4;
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
          vibrancy = 0.1696;
        };
        shadow = {
          enabled = false;
          range = 30;
          render_power = 3;
          ignore_window = true;
          color = "rgba(00000045)";
        };
      };

      # Animations
      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 0, 0, ease"
        ];
      };

      # Dwindle layout configuration
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      # Master layout configuration
      master = {
        new_status = "master";
      };

      # Misc settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
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
      bind = SUPER, space, exec, wofi --show drun --sort-order=alphabetical
      bind = SUPER, Return, exec, ghostty
      bind = SUPER, E, exec, nautilus
      
      # Window management
      bind = SUPER, W, killactive,
      bind = SUPER, Backspace, killactive,
      
      # End active session
      bind = SUPER, ESCAPE, exec, hyprlock
      bind = SUPER SHIFT, ESCAPE, exit,
      bind = SUPER CTRL, ESCAPE, exec, reboot
      bind = SUPER SHIFT CTRL, ESCAPE, exec, systemctl poweroff
      
      # Control tiling
      bind = SUPER, J, togglesplit, # dwindle
      bind = SUPER, P, pseudo, # dwindle
      bind = SUPER, V, togglefloating,
      bind = SUPER SHIFT, Plus, fullscreen,
      
      # Move focus with mainMod + arrow keys
      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d
      
      # Switch workspaces with mainMod + [0-9]
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
      
      bind = SUPER, comma, workspace, -1
      bind = SUPER, period, workspace, +1
      
      # Move active window to a workspace with mainMod + SHIFT + [0-9]
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
      
      # Swap active window with the one next to it with mainMod + SHIFT + arrow keys
      bind = SUPER SHIFT, left, swapwindow, l
      bind = SUPER SHIFT, right, swapwindow, r
      bind = SUPER SHIFT, up, swapwindow, u
      bind = SUPER SHIFT, down, swapwindow, d
      
      # Resize active window
      bind = SUPER, minus, resizeactive, -100 0
      bind = SUPER, equal, resizeactive, 100 0
      bind = SUPER SHIFT, minus, resizeactive, 0 -100
      bind = SUPER SHIFT, equal, resizeactive, 0 100
      
      # Scroll through existing workspaces with mainMod + scroll
      bind = SUPER, mouse_down, workspace, e+1
      bind = SUPER, mouse_up, workspace, e-1
      
      # Super workspace floating layer
      bind = SUPER, S, togglespecialworkspace, magic
      bind = SUPER SHIFT, S, movetoworkspace, special:magic
      
      # Screenshots
      bind = , PRINT, exec, grim -g \"$(slurp)\" - | wl-copy
      bind = SHIFT, PRINT, exec, grim - | wl-copy
      bind = CTRL, PRINT, exec, grim - | wl-copy
      
      # Color picker
      bind = SUPER, PRINT, exec, hyprpicker -a
      
      # Clipse
      bind = CTRL SUPER, V, exec, ghostty --class clipse -e clipse
      
      # Laptop multimedia keys for volume and LCD brightness
      bindel = [
        , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        , XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+
        , XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-
      ];
      
      # Requires playerctl
      bindl = [
        , XF86AudioNext, exec, playerctl next
        , XF86AudioPause, exec, playerctl play-pause
        , XF86AudioPlay, exec, playerctl play-pause
        , XF86AudioPrev, exec, playerctl previous
      ];
      
      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        SUPER, mouse:272, movewindow
        SUPER, mouse:273, resizewindow
      ];
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
