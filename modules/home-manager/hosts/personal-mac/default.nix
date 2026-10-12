{ pkgs, ... }:
{
  # Personal Mac-specific home-manager configuration
  # This file contains programs and settings unique to the personal M1 Max
  home = {
    # Personal Mac-specific programs and packages
    packages = with pkgs; [
      discord # Personal communication
      # macOS-only packages
      mkalias
      # ollama
    ];
  };
}
