# Cross-platform home-manager configuration
# This module works on both macOS (darwin) and NixOS (linux)
#
# Platform Detection:
# - Use `isDarwin` / `isLinux` module arguments (preferred)
# - Use `lib.optionalAttrs` for conditional attribute sets (files)
# - Use `lib.mkIf` for conditional options (programs, activation)
#
# Examples:
# - Files: home.file = { ... } // lib.optionalAttrs isDarwin { ... };
# - Activation: activation = lib.mkIf isDarwin { ... };
# - Programs: config = lib.mkIf isDarwin { programs.foo = { ... }; };

{
  pkgs,
  config,
  inputs,
  isWork,
  isDarwin,
  ...
}:
{
  imports = [
    ./agents
    ./programs
    ./secrets.nix
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

    file = {
      "${config.xdg.configHome}/1Password/ssh/agent.toml".source = ./files/1password-agent.toml;
    };

    sessionVariables = {
      COMPOSE_PROFILES = "default";
      NH_DARWIN_FLAKE = "${config.home.homeDirectory}/.config/nix-config";
      NH_OS_FLAKE = "/home/michael/nix-config";

      PI_FFF_MODE = "override";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
