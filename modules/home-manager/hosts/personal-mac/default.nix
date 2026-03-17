{ pkgs, inputs, ... }:
{
  # Personal Mac-specific home-manager configuration
  # This file contains programs and settings unique to the personal M1 Max

  # Personal Mac-specific programs and packages
  home.packages = with pkgs; [
    discord # Personal communication

    # macOS-only packages
    aerospace
    inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
    mkalias
  ];
}
