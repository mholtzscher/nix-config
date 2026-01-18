{
  pkgs,
  lib,
  config,
  ...
}:
{
  # NixOS Desktop-specific home-manager configuration
  # Desktop environment setup is now in modules/nixos/desktop/
  # This file contains only user-specific packages and services

  # Solaar config for Logitech MX Master 3S
  # Key setting: scroll diversion OFF to fix scrolling after KVM switch
  xdg.configFile."solaar/config.yaml".text = lib.generators.toYAML { } [
    "1.1.16"
    {
      _NAME = "MX Master 3S for Mac";
      _modelId = "B03400000000";
      _serial = "6EBEDCC2";
      _unitId = "6EBEDCC2";
      _wpid = "B034";
      # Scroll diversion OFF - fixes scroll wheel after KVM switch
      hires-scroll-mode = false;
      thumb-scroll-mode = false;
      # Other scroll settings
      hires-smooth-invert = false;
      hires-smooth-resolution = false;
      thumb-scroll-invert = false;
      scroll-ratchet = 2;
      smart-shift = 12;
      # DPI
      dpi = 1000;
    }
  ];

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    awscli2 # AWS command-line interface
    vesktop # Discord client with better Wayland support

    # Linux desktop-specific GUI tools
    nautilus # File manager
    imv # Image viewer
    zathura # PDF viewer
    brightnessctl # Brightness control
    pavucontrol # Audio control GUI
    steam-run # Steam runtime for non-Steam applications
    qpwgraph # PipeWire graph visualizer for audio routing
  ];

  # DankMaterialShell theme (Catppuccin Mocha + Lavender accent)
  xdg.configFile."DankMaterialShell/themes/catppuccin-mocha-lavender.json".source =
    ../../files/dms/catppuccin-mocha-lavender.json;

  xdg.configFile."DankMaterialShell/settings.json".text = builtins.toJSON {
    currentThemeName = "custom";
    customThemeFile = "${config.xdg.configHome}/DankMaterialShell/themes/catppuccin-mocha-lavender.json";
    useFahrenheit = true;
  };

  # Audio effects processing for microphone and system audio
  services.easyeffects.enable = true;

  systemd.user.services."1password" = {
    Unit = {
      Description = "1Password";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs._1password-gui}/bin/1password --silent";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
