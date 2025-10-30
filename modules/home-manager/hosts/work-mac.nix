{ pkgs, ... }:
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

  # Work-specific environment or configurations
  # No Discord on work Mac (not in packages)
}
