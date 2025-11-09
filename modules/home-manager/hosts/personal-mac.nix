{ pkgs, ... }:
{
  # Personal Mac-specific home-manager configuration
  # This file contains programs and settings unique to the personal M1 Max

  # Personal Mac-specific programs and packages
  home.packages = with pkgs; [
    code-cursor # AI code editor (personal use only)
    discord # Personal communication

    # macOS-only packages
    aerospace
    mkalias
    pokemon-colorscripts-mac
  ];
}
