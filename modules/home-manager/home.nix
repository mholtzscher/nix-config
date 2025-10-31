# Cross-platform home-manager configuration
# This module works on both macOS (darwin) and NixOS (linux)
#
# Platform Detection:
# - Use `pkgs.stdenv.isDarwin` for macOS-specific config
# - Use `pkgs.stdenv.isLinux` for Linux-specific config
# - Use `lib.optionalAttrs` for conditional attribute sets (files)
# - Use `lib.mkIf` for conditional options (programs, activation)
#
# Examples:
# - Files: home.file = { ... } // lib.optionalAttrs pkgs.stdenv.isDarwin { ... };
# - Activation: activation = lib.mkIf pkgs.stdenv.isDarwin { ... };
# - Programs: config = lib.mkIf pkgs.stdenv.isDarwin { programs.foo = { ... }; };

{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  # starship = pkgs.fetchFromGitHub {
  #   owner = "starship";
  #   repo = "starship";
  #   rev = "ed87dc5750338d37bfc2c17568ae3a9b589a8e8e";
  #   sha256 = "sha256-kPvyCKf62x+hXAxL5+sdWHLVoUx/n96EFEBOTpXnQhw=";
  # };
  lazyIdeaVim = pkgs.fetchurl {
    url = "https://gist.githubusercontent.com/mikeslattery/d2f2562e5bbaa7ef036cf9f5a13deff5/raw/31278677c945d5f7be6f9c1e37a9779542ff1376/.idea-lazy.vim";
    # Replace with the actual SHA256 hash of the file
    sha256 = "sha256-WC8jzKir2LRMVOgyNJwDYH26mpIf9UCVTi6wOHdfDXo=";
  };
in
{
  imports = [
    ./programs
  ];
  home = {
    stateVersion = "24.11";
    # xdg.enable = true;
    packages = import ./packages.nix { inherit pkgs; };

    file = {
      # Cross-platform config files
      "${config.xdg.configHome}/zellij/config.kdl".source = ./files/zellij.kdl;
      ".asdfrc".source = ./files/asdfrc;
      "${config.xdg.configHome}/kafkactl/config.yml".source = ./files/kafkactl.yaml;
      "${config.xdg.configHome}/fish/functions/update.fish".source = ./files/fish/functions/update.fish;
      ".ideavimrc".source = ./files/ideavimrc;
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
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      "Library/Application Support/eza/theme.yml".source =
        "${inputs.tokyonight}/extras/eza/tokyonight.yml";

      "${config.xdg.configHome}/borders/bordersrc" = {
        source = ./files/bordersrc;
        executable = true;
      };

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
    };

    # macOS-only activation scripts
    activation = lib.mkIf pkgs.stdenv.isDarwin {
      aerospaceConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${config.xdg.configHome}/aerospace"
        run cp -f ${./files/aerospace.toml} "${config.xdg.configHome}/aerospace/aerospace.toml"
        run chmod u+w "${config.xdg.configHome}/aerospace/aerospace.toml"
      '';
    };

    sessionVariables = {
      EDITOR = "nvim";
      COMPOSE_PROFILES = "default";

      TOPIARY_CONFIG_FILE = "${config.xdg.configHome}/topiary/languages.ncl";
      TOPIARY_LANGUAGE_DIR = "${config.xdg.configHome}/topiary/languages";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
