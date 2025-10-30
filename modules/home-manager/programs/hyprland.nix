{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  imports = [
    ../hyprland
  ];

  # Hyprland wayland compositor configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
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
