# Base Home Manager configuration (packages, dotfiles, theme)
{
  flake.modules.homeManager.base =
    {
      pkgs,
      config,
      lib,
      inputs,
      isWork ? false,
      ...
    }:
    let
      lazyIdeaVim = pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/mikeslattery/d2f2562e5bbaa7ef036cf9f5a13deff5/raw/31278677c945d5f7be6f9c1e37a9779542ff1376/.idea-lazy.vim";
        sha256 = "sha256-WC8jzKir2LRMVOgyNJwDYH26mpIf9UCVTi6wOHdfDXo=";
      };
    in
    {
      home = {
        file = {
          "${config.xdg.configHome}/kafkactl/config.yml".source = ../../files/kafkactl.yaml;
          ".ideavimrc".source = ../../files/ideavimrc;
          ".idea-lazy.vim".source = lazyIdeaVim;

          "${config.xdg.configHome}/topiary/languages.ncl".text =
            builtins.replaceStrings [ "TREE_SITTER_NU_PATH" ] [ "${pkgs.tree-sitter-grammars.tree-sitter-nu}" ]
              (builtins.readFile ../../files/topiary/languages.ncl);

          "${config.xdg.configHome}/topiary/languages/nu.scm".source =
            "${inputs.topiaryNushell}/languages/nu.scm";

          "${config.xdg.configHome}/1Password/ssh/agent.toml".source = ../../files/1password-agent.toml;
        }
        // lib.optionalAttrs pkgs.stdenv.isDarwin {
          "${config.xdg.configHome}/raycast/scripts/toggle-aerospace.sh" = {
            source = ../../files/raycast/toggle-aerospace.sh;
            executable = true;
          };
          "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size.sh" = {
            source = ../../files/raycast/aerospace-workspace-size.sh;
            executable = true;
          };
          "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size-increment.sh" = {
            source = ../../files/raycast/aerospace-workspace-size-increment.sh;
            executable = true;
          };
          "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size-decrement.sh" = {
            source = ../../files/raycast/aerospace-workspace-size-decrement.sh;
            executable = true;
          };
          "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-shift-left.sh" = {
            source = ../../files/raycast/aerospace-workspace-shift-left.sh;
            executable = true;
          };
          "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-shift-right.sh" = {
            source = ../../files/raycast/aerospace-workspace-shift-right.sh;
            executable = true;
          };
          "${config.xdg.configHome}/raycast/scripts/aerospace-workspace-shift-reset.sh" = {
            source = ../../files/raycast/aerospace-workspace-shift-reset.sh;
            executable = true;
          };
        };

        activation = lib.mkIf pkgs.stdenv.isDarwin {
          aerospaceConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            run mkdir -p "${config.xdg.configHome}/aerospace"
            run cp -f ${../../files/aerospace.toml} "${config.xdg.configHome}/aerospace/aerospace.toml"
            run chmod u+w "${config.xdg.configHome}/aerospace/aerospace.toml"
          '';
        };

        sessionVariables = {
          COMPOSE_PROFILES = "default";

          TOPIARY_CONFIG_FILE = "${config.xdg.configHome}/topiary/languages.ncl";
          TOPIARY_LANGUAGE_DIR = "${config.xdg.configHome}/topiary/languages";
        }
        // lib.optionalAttrs (!isWork) {
          OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
        };
      };

      programs.home-manager.enable = lib.mkDefault true;
    };
}
