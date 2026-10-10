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
  lib,
  inputs,
  isWork,
  isDarwin,
  ...
}:
let
  lazyIdeaVim = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/mikeslattery/d2f2562e5bbaa7ef036cf9f5a13deff5/raw/31278677c945d5f7be6f9c1e37a9779542ff1376/.idea-lazy.vim";
    # Replace with the actual SHA256 hash of the file
    sha256 = "sha256-WC8jzKir2LRMVOgyNJwDYH26mpIf9UCVTi6wOHdfDXo=";
  };
in
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
    glamour.enable = lib.mkIf isDarwin false;
  };

  home = {
    stateVersion = "25.05";
    packages = import ./packages.nix { inherit pkgs inputs isWork; };

    # Mac user files are native Mise dotfiles. Keep the existing Linux owners.
    file = lib.optionalAttrs (!isDarwin) {
      "${config.xdg.configHome}/kafkactl/config.yml".source = ./files/kafkactl.yaml;
      ".ideavimrc".source = ./files/ideavimrc;
      "bin/pr-diff" = {
        source = ./files/pr-diff;
        executable = true;
      };
      ".idea-lazy.vim".source = lazyIdeaVim;

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
