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

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    python314
    # python313Packages.debugpy
    gcc

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
