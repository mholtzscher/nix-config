{ pkgs, ... }:
{
  # NixOS Desktop-specific home-manager configuration
  # This file contains programs and settings unique to the NixOS desktop

  # Desktop-specific imports
  imports = [
    ../programs/hyprland.nix
    ../programs/waybar.nix
  ];

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    discord  # Personal communication (cross-platform)
    
    # Linux desktop-specific GUI tools
    nautilus  # File manager
    imv       # Image viewer
    zathura   # PDF viewer
    swaylock-effects  # Screen locker with effects
    brightnessctl     # Brightness control
    pavucontrol       # Audio control GUI
  ];
}
