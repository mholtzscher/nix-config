{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # Minimal imports - simplified
  imports = [
    # All config now in programs/hyprland.nix
  ];
}
