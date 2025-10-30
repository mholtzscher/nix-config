{ config, lib, pkgs, osConfig ? { }, ... }:
let
  hasNvidiaDrivers = builtins.elem "nvidia" osConfig.services.xserver.videoDrivers;
  nvidiaEnv = [
    "NVD_BACKEND,direct"
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
  ];
  hexToRgba =
    hex: alpha:
    "rgba(${hex}${alpha})";

  # Fallback colors if colorScheme is not available
  inactiveBorder = hexToRgba (config.colorScheme.palette.base09 or "ff6600") "aa";
  activeBorder = hexToRgba (config.colorScheme.palette.base0D or "00aaff") "aa";
in
lib.mkIf pkgs.stdenv.isLinux {
  # Hyprland wayland compositor configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    
    settings = {
      # Default applications
      "$terminal" = lib.mkDefault "ghostty";
      "$fileManager" = lib.mkDefault "nautilus --new-window";
      "$browser" = lib.mkDefault "chromium --new-window --ozone-platform=wayland";
      "$music" = lib.mkDefault "spotify";
      "$passwordManager" = lib.mkDefault "1password";
      "$messenger" = lib.mkDefault "signal-desktop";
      "$webapp" = lib.mkDefault "$browser --app";

      monitor = [
        ",preferred,auto,1"  # Default monitor config
      ];

      # Environment variables
      env = (lib.optionals hasNvidiaDrivers nvidiaEnv) ++ [
        # Cursor size
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"

        # Cursor theme
        "XCURSOR_THEME,Adwaita"
        "HYPRCURSOR_THEME,Adwaita"

        # Force all apps to use Wayland
        "GDK_BACKEND,wayland"
        "QT_QPA_PLATFORM,wayland"
        "QT_STYLE_OVERRIDE,kvantum"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "OZONE_PLATFORM,wayland"

        # Make Chromium use XCompose and all Wayland
        "CHROMIUM_FLAGS,\"--enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4\""

        # Make .desktop files available for wofi
        "XDG_DATA_DIRS,$XDG_DATA_DIRS:$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share"

        # Use XCompose file
        "XCOMPOSEFILE,~/.XCompose"
        "EDITOR,nvim"

        # GTK theme
        "GTK_THEME,Adwaita:dark"
      ];

      xwayland = {
        force_zero_scaling = true;
      };

      # Don't show update on first launch
      ecosystem = {
        no_update_news = true;
      };

      # Input configuration
      input = lib.mkDefault {
        kb_layout = "us";
        kb_options = "compose:caps";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad = {
          natural_scroll = false;
        };
      };

      gestures = lib.mkDefault {
        workspace_swipe = false;
      };

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = activeBorder;
        "col.inactive_border" = inactiveBorder;
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration/appearance
      decoration = {
        rounding = 4;
        shadow = {
          enabled = false;
          range = 30;
          render_power = 3;
          ignore_window = true;
          color = "rgba(00000045)";
        };
        blur = {
          enabled = true;
          size = 5;
          passes = 2;
          vibrancy = 0.1696;
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

      # Window rules
      windowrule = [
        "suppressevent maximize, class:.*"
        "tile, class:^(chromium)$"
        "float, class:^(org.pulseaudio.pavucontrol|blueberry.py)$"
        "float, class:^(steam)$"
        "fullscreen, class:^(com.libretro.RetroArch)$"
        "opacity 0.97 0.9, class:.*"
        "opacity 1 1, class:^(chromium|google-chrome|google-chrome-unstable)$, title:.*Youtube.*"
        "opacity 1 0.97, class:^(chromium|google-chrome|google-chrome-unstable)$"
        "opacity 0.97 0.9, initialClass:^(chrome-.*-Default)$"
        "opacity 1 1, initialClass:^(chrome-youtube.*-Default)$"
        "opacity 1 1, class:^(zoom|vlc|org.kde.kdenlive|com.obsproject.Studio)$"
        "opacity 1 1, class:^(com.libretro.RetroArch|steam)$"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "float, class:(clipse)"
        "size 622 652, class:(clipse)"
        "stayfocused, class:(clipse)"
      ];

      layerrule = [
        "blur,wofi"
        "blur,waybar"
      ];

      # Keybindings
      bind = [
        "SUPER, space, exec, wofi --show drun --sort-order=alphabetical"
        "SUPER SHIFT, SPACE, exec, pkill -SIGUSR1 waybar"
        "SUPER, W, killactive,"
        "SUPER, Backspace, killactive,"
        "SUPER, ESCAPE, exec, hyprlock"
        "SUPER SHIFT, ESCAPE, exit,"
        "SUPER CTRL, ESCAPE, exec, reboot"
        "SUPER SHIFT CTRL, ESCAPE, exec, systemctl poweroff"
        "SUPER, J, togglesplit, # dwindle"
        "SUPER, P, pseudo, # dwindle"
        "SUPER, V, togglefloating,"
        "SUPER SHIFT, Plus, fullscreen,"
        "SUPER, left, movefocus, l"
        "SUPER, right, movefocus, r"
        "SUPER, up, movefocus, u"
        "SUPER, down, movefocus, d"
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
        "SUPER, comma, workspace, -1"
        "SUPER, period, workspace, +1"
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
        "SUPER SHIFT, left, swapwindow, l"
        "SUPER SHIFT, right, swapwindow, r"
        "SUPER SHIFT, up, swapwindow, u"
        "SUPER SHIFT, down, swapwindow, d"
        "SUPER, minus, resizeactive, -100 0"
        "SUPER, equal, resizeactive, 100 0"
        "SUPER SHIFT, minus, resizeactive, 0 -100"
        "SUPER SHIFT, equal, resizeactive, 0 100"
        "SUPER, mouse_down, workspace, e+1"
        "SUPER, mouse_up, workspace, e-1"
        "SUPER, S, togglespecialworkspace, magic"
        "SUPER SHIFT, S, movetoworkspace, special:magic"
        ", PRINT, exec, hyprshot -m region"
        "SHIFT, PRINT, exec, hyprshot -m window"
        "CTRL, PRINT, exec, hyprshot -m output"
        "SUPER, PRINT, exec, hyprpicker -a"
        "CTRL SUPER, V, exec, ghostty --class clipse -e clipse"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
      ];

      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      # Startup applications
      exec-once = [
        "hyprsunset"
        "systemctl --user start hyprpolkitagent"
        "wl-clip-persist --clipboard regular & clipse -listen"
      ];

      exec = [
        "pkill -SIGUSR2 waybar || waybar"
      ];
    };
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
    hyprshot
    hyprpicker
    hyprsunset
    wl-clip-persist
    clipse
    
    # Volume and brightness
    wireplumber  # Provides wpctl command
    brightnessctl
    
    # Misc
    xdg-desktop-portal-hyprland
    libnotify
    blueberry  # Bluetooth GUI
    pavucontrol  # PulseAudio GUI
    playerctl  # Media control
  ];
}
