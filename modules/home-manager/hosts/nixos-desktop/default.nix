{ pkgs, ... }:
{
  # NixOS Desktop-specific home-manager configuration
  # Desktop environment setup is now in modules/nixos/desktop/
  # This file contains only user-specific packages and services

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    awscli2 # AWS command-line interface
    code-cursor # AI code editor (personal use only)
    vesktop # Discord client with better Wayland support

    # Linux desktop-specific GUI tools
    nautilus # File manager
    imv # Image viewer
    zathura # PDF viewer
    swaylock-effects # Screen locker with effects
    brightnessctl # Brightness control
    pavucontrol # Audio control GUI
    steam-run # Steam runtime for non-Steam applications
    qpwgraph # PipeWire graph visualizer for audio routing
  ];

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
