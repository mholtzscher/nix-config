{
  pkgs,
  inputs,
  isWork,
  config,
  ...
}:
{
  home.sessionVariables = {
    OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
  };

  home.file = {
    "${config.xdg.configHome}/opencode/agents" = {
      source = ./files/opencode/agents;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/commands" = {
      source = ./files/commands;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/plugins" = {
      source = ./files/opencode/plugins;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/AGENTS.md".source = ./files/opencode/AGENTS.md;
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
      settings = {
        # share = "disabled";
        plugin = [
          "@plannotator/opencode@0.17.9"
          "@slkiser/opencode-quota"
        ];
        username = "mholtzscher";
        agent.plan = {
          model = "openai/gpt-5.4";
          reasoningEffort = "high";
        };
        # agent.explore.model = "openai/gpt-5.3-codex-spark";
        agent.explore.model = "opencode/gpt-5.4-mini";
        permission = {
          bash = { };
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
          read = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
            "*.envrc" = "deny";
            "secrets/*" = "deny";
            ".dev.vars" = "ask";
            "~/.local/share/opencode/mcp-auth.json" = "deny";
          };
          # webfetch = "ask";
        };
        # keybinds = {
        #   "session_child_cycle" = "shift+right";
        #   "session_child_cycle_reverse" = "shift+left";
        # };
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
          gh_grep = {
            enabled = !isWork;
            type = "remote";
            url = "https://mcp.grep.app/";
          };
          opensrc = {
            type = "local";
            command = [
              "npx"
              "-y"
              "opensrc-mcp"
            ];
            enabled = !isWork;
          };
        };
      };
    };
  };
}
