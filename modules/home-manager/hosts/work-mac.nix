{ pkgs, lib, ... }:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac

  # Work-specific programs and packages
  home.packages = with pkgs; [
    # macOS-only packages
    aerospace
    mkalias
    pokemon-colorscripts-mac

    # Work-specific tools can be added here
  ];

  # Disable atuin sync on work Mac
  programs.atuin.settings = {
    auto_sync = lib.mkForce false;
    sync_address = lib.mkForce "";
  };

  # Work-specific environment or configurations
  # No Discord on work Mac (not in packages)
}
