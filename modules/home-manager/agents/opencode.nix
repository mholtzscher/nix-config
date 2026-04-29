{
  pkgs,
  lib,
  inputs,
  isWork,
  config,
  currentSystemName,
  ...
}:
let
  agentTemplates = {
    dwight = ./files/opencode/agents/dwight.md;
    librarian = ./files/opencode/agents/librarian.md;
    oracle = ./files/opencode/agents/oracle.md;
    sensei = ./files/opencode/agents/sensei.md;
  };

  agentModelDefaults = {
    dwight = "opencode/glm-5.1";
    librarian = "openai/gpt-5.4-mini";
    oracle = "opencode/gpt-5.4";
  };

  # Host-specific agent model overrides.
  agentModelOverrides = {
    personal-mac = { };
    work-mac = {
      dwight = "github-copilot/gemini-3.1-pro-preview";
      librarian = "github-copilot/gpt-5.4-mini";
      oracle = "github-copilot/gpt-5.4-mini";
      sensei = "github-copilot/gpt-5.4-mini";
    };
    nixos-desktop = { };
    wanda = { };
  };

  currentAgentModelOverrides = agentModelOverrides.${currentSystemName} or { };

  renderedAgentFiles = lib.mapAttrs' (
    agentName: template:
    let
      model = currentAgentModelOverrides.${agentName} or (agentModelDefaults.${agentName} or null);
    in
    lib.nameValuePair "${config.xdg.configHome}/opencode/agents/${agentName}.md" {
      source = pkgs.replaceVars template {
        modelHeader = if model == null then "" else "model: ${model}";
      };
    }
  ) agentTemplates;
in
{
  home.sessionVariables = {
    OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
  };

  home.file = renderedAgentFiles // {
    "${config.xdg.configHome}/opencode/commands" = {
      source = ./files/commands;
      recursive = true;
    };

    "${config.xdg.configHome}/opencode/plugins" = {
      source = ./files/opencode/plugins;
      recursive = true;
    };

    # "${config.xdg.configHome}/opencode/AGENTS.md".source = ./files/opencode/AGENTS.md;
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
      settings = {
        # share = "disabled";
        plugin = [
          "@plannotator/opencode@0.19.2"
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
