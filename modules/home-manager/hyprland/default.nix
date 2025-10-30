{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  imports = [
    ./autostart.nix
    ./bindings.nix
    ./configuration.nix
    ./envs.nix
    ./input.nix
    ./looknfeel.nix
    ./windows.nix
  ];

  # Home packages needed for Hyprland
  home.packages = with pkgs; [
    # Essential tools
    hyprshot
    hyprpicker
    hyprsunset
    wl-clip-persist
    clipse
    
    # Volume and brightness
    blueberry  # Bluetooth GUI
    pavucontrol  # PulseAudio GUI
    playerctl  # Media control
  ];
}