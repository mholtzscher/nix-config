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
    sensei = ./files/opencode/agents/sensei.md;
  };

  # Host-specific agent model overrides.
  agentModelOverrides = {
    personal-mac = { };
    work-mac = {
      sensei = "github-copilot/gpt-5.4-mini";
    };
    nixos-desktop = { };
    wanda = { };
  };

  currentAgentModelOverrides = agentModelOverrides.${currentSystemName} or { };

  renderedAgentFiles = lib.mapAttrs' (
    agentName: template:
    let
      model = currentAgentModelOverrides.${agentName} or null;
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

    "${config.xdg.configHome}/opencode/AGENTS.md".source = ./files/karpathy-agents.md;

    "${config.xdg.configHome}/opencode/plugins/pr-comments.ts" = {
      source = ./files/opencode/plugins/pr-comments.ts;
      force = true;
    };
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
      settings = {
        plugin = [
          "@plannotator/opencode@0.27.6"
        ];
        username = "mholtzscher";
        agent = {
          build = {
            model = "openai/gpt-5.6-sol";
            reasoningEffort = "xhigh";
          };
          plan = {
            model = "openai/gpt-5.6-sol";
            reasoningEffort = "xhigh";
          };
          explore = {
            model = "opencode-go/deepseek-v4-flash";
            reasoningEffort = "high";
          };
          general = {
            model = "openai/gpt-5.6-terra";
            reasoningEffort = "high";
          };
        };
        mcp.servers = {
          home-assistant = {
            type = "remote";
            url = "https://home.holtzscher.com/api/webhook/mcp_d658f368f407b84c193f22eec56dbb44";
            oauth = {
              client_id = "http://localhost:19876";
              callback_port = 19876;
              redirect_uri = "http://localhost:19876/callback";
            };
          };

          railway = {
            type = "remote";
            url = "https://mcp.railway.com";
          };

          sideshow = {
            type = "remote";
            url = "https://sideshow.sh/mcp";
          };

          honeycomb = {
            type = "remote";
            url = "https://mcp.honeycomb.io/mcp";
          };
        };
      };
    };
  };
}
