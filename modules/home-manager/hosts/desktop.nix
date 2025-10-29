{ pkgs, ... }:
{
  # NixOS Desktop-specific home-manager configuration
  # This file contains programs and settings unique to the NixOS desktop

  # Desktop-specific programs and packages
  home.packages = with pkgs; [
    discord  # Personal communication (cross-platform)
    # Linux desktop-specific GUI tools can be added here
  ];

  # Linux-specific configurations
  # No aerospace (macOS only)
  # Can add Linux-specific window manager configs here
}
