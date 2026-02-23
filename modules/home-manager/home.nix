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
    ./programs
    inputs.catppuccin.homeModules.catppuccin
  ];

  # Enable Catppuccin Mocha theme globally
  catppuccin = {
    enable = true;
    flavor = "mocha";
    # Disable for programs with custom configs
    zellij.enable = false; # Has extensive custom keybindings in zellij.kdl
  };

  home = {
    stateVersion = "24.11";
    packages = import ./packages.nix { inherit pkgs inputs isWork; };

    file = {
      # Cross-platform config files
      "${config.xdg.configHome}/kafkactl/config.yml".source = ./files/kafkactl.yaml;
      ".ideavimrc".source = ./files/ideavimrc;
      "bin/pr-diff" = {
        source = ./files/pr-diff;
        executable = true;
      };
      ".idea-lazy.vim".source = lazyIdeaVim;

      ## Topiary Config
      "${config.xdg.configHome}/topiary/languages.ncl".text =
        builtins.replaceStrings [ "TREE_SITTER_NU_PATH" ] [ "${pkgs.tree-sitter-grammars.tree-sitter-nu}" ]
          (builtins.readFile ./files/topiary/languages.ncl);
      "${config.xdg.configHome}/topiary/languages/nu.scm".source =
        "${inputs.topiaryNushell}/languages/nu.scm";
      "${config.xdg.configHome}/1Password/ssh/agent.toml".source = ./files/1password-agent.toml;
    }
    # macOS-specific config files
    // lib.optionalAttrs isDarwin {
      # "${config.xdg.configHome}/borders/bordersrc" = {
      #   source = ./files/bordersrc;
      #   executable = true;
      # };

      ## Raycast Scripts (macOS only)
      "${config.xdg.configHome}/raycast/scripts/toggle-aerospace.sh" = {
        source = ./files/raycast/toggle-aerospace.sh;
        executable = true;
      };
      "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size.sh" = {
        source = ./files/raycast/aerospace-workspace-size.sh;
        executable = true;
      };
      "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size-increment.sh" = {
        source = ./files/raycast/aerospace-workspace-size-increment.sh;
        executable = true;
      };
      "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size-decrement.sh" = {
        source = ./files/raycast/aerospace-workspace-size-decrement.sh;
        executable = true;
      };
      "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-shift-left.sh" = {
        source = ./files/raycast/aerospace-workspace-shift-left.sh;
        executable = true;
      };
      "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-shift-right.sh" = {
        source = ./files/raycast/aerospace-workspace-shift-right.sh;
        executable = true;
      };
      "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-shift-reset.sh" = {
        source = ./files/raycast/aerospace-workspace-shift-reset.sh;
        executable = true;
      };
    };

    # macOS-only activation scripts
    activation = lib.mkIf isDarwin {
      aerospaceConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${config.xdg.configHome}/aerospace"
        run cp -f ${./files/aerospace.toml} "${config.xdg.configHome}/aerospace/aerospace.toml"
        run chmod u+w "${config.xdg.configHome}/aerospace/aerospace.toml"
      '';
    };

    sessionVariables = {
      COMPOSE_PROFILES = "default";

      TOPIARY_CONFIG_FILE = "${config.xdg.configHome}/topiary/languages.ncl";
      TOPIARY_LANGUAGE_DIR = "${config.xdg.configHome}/topiary/languages";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
