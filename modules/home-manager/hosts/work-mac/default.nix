{ pkgs, inputs, ... }:
{
  # Work Mac specific home-manager configuration
  # This file contains programs and settings unique to the work Mac
  # Note: isWork-based configuration (atuin sync, opencode MCPs) is handled
  # in the program modules using the isWork flag
  home = {

    # Work-specific programs and packages
    packages = with pkgs; [
      aerospace
      inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
      mkalias
      mariadb.client
      oras
      sops
    ];

    sessionVariables = {
      ZELLIJ_SOCKET_DIR = "/tmp/zellij";
    };
  };
}
