{
  pkgs,
  lib,
  inputs,
  isWork,
  config,
  ...
}:
{
  home.sessionVariables = lib.mkIf (!isWork) {
    OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
  };

  home.file = lib.mkIf (!isWork) {
    "${config.xdg.configHome}/opencode/skills" = {
      source = ../files/opencode/skills;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/agents" = {
      source = ../files/opencode/agents;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/commands" = {
      source = ../files/opencode/commands;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/AGENTS.md".source = ../files/opencode/AGENTS.md;
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        # share = "disabled";
        username = "mholtzscher";
        plugin = [ "@mohak34/opencode-notifier@latest" ];
        permission = {
          external_directory = {
            "~/go/pkg/mod/**" = "allow";
            "~/.cache/go-build/**" = "allow";
            "~/Library/Caches/go-build/**" = "allow";
          };
          edit = {
            "~/go/pkg/mod/**" = "deny";
            "~/.cache/go-build/**" = "deny";
            "~/Library/Caches/go-build/**" = "deny";
          };
        };
        keybinds = {
          "session_child_cycle" = "shift+right";
          "session_child_cycle_reverse" = "shift+left";
        };
        lsp = {
          nushell = {
            command = [
              "nu"
              "--lsp"
            ];
            extensions = [ ".nu" ];
          };
          nix = {
            command = [
              "nil"
            ];
            extensions = [ ".nix" ];
          };
        };

        formatter = {
          nix = {
            command = [
              "nixfmt"
              "$FILE"
            ];
            extensions = [ ".nix" ];
          };
        };
        tools = {
          # "gh_grep*" = false;
          # "exa*" = false;
        };
        mcp = {
          # gh_grep = {
          #   enabled = false;
          #   type = "remote";
          #   url = "https://mcp.grep.app/";
          # };
          # exa = {
          #   enabled = false;
          #   type = "local";
          #   command = [
          #     "bunx"
          #     "exa-mcp-server"
          #   ];
          # };
        };
      };
    };
  };
}
