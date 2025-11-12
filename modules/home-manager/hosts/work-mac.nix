{ pkgs, ... }:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac
  # Note: isWork-based configuration (atuin sync, opencode MCPs) is handled
  # in the program modules using the isWork flag

  # Work-specific programs and packages
  home.packages = with pkgs; [
    aerospace
    mkalias
    pokemon-colorscripts-mac
  ];
}
