# Shared Linux Home Manager configuration (NixOS desktop and Wanda).
# Legacy platform arguments remain available for existing Linux modules.

{
  pkgs,
  inputs,
  isWork,
  isDarwin,
  ...
}:
{
  imports = [
    ./agents
    ./programs
    inputs.catppuccin.homeModules.catppuccin
  ];

  # Enable Catppuccin Mocha theme globally
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    # Disable for programs with custom configs
    opencode.enable = false;
  };

  home = {
    stateVersion = "25.05";
    packages = import ./packages.nix {
      inherit
        pkgs
        inputs
        isWork
        isDarwin
        ;
    };

    sessionVariables = {
      NH_OS_FLAKE = "/home/michael/nix-config";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
