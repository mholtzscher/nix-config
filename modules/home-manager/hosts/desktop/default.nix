{ pkgs, ... }:
{
  # NixOS Desktop-specific home-manager configuration
  # This file contains programs and settings unique to the NixOS desktop

  # Desktop-specific imports
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./wofi.nix
  ];
  
  # Install EDID capture script for KVM troubleshooting
  home.file.".local/bin/capture-edid" = {
    source = ../../files/hyprland/capture-edid.sh;
    executable = true;
  };

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    python314
    # python313Packages.debugpy
    gcc

    _1password-gui
    _1password-cli
    code-cursor # AI code editor (personal use only)
    discord # Personal communication (cross-platform)

    # Linux desktop-specific GUI tools
    nautilus # File manager
    imv # Image viewer
    zathura # PDF viewer
    swaylock-effects # Screen locker with effects
    brightnessctl # Brightness control
    pavucontrol # Audio control GUI
  ];
}
