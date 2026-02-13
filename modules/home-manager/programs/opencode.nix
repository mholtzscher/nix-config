{
  pkgs,
  inputs,
  isWork,
  config,
  ...
}:
{
  home.file."${config.xdg.configHome}/opencode/skills" = {
    source = ../files/opencode/skills;
    recursive = true;
  };

  home.file."${config.xdg.configHome}/opencode/agents" = {
    source = ../files/opencode/agents;
    recursive = true;
  };

  home.file."${config.xdg.configHome}/opencode/commands" = {
    source = ../files/opencode/commands;
    recursive = true;
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.opencode.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        # share = "disabled";
        username = "mholtzscher";
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
