{
  pkgs,
  ...
}:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac
  # Work-specific shell aliases and environment are handled by shared modules.

  home = {

    # Work-specific programs and packages
    packages = with pkgs; [
      mkalias
    ];
  };
}
