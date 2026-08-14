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
  };

  programs = {
    opencode = {
      enable = !isWork;
      package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
      settings = {
        plugin = [
          "@plannotator/opencode@0.27.3"
        ];
        username = "mholtzscher";
        agent = {
          build = {
            model = "openai/gpt-5.6-terra";
            reasoningEffort = "high";
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
        mcp = {
        };
      };
    };
  };
}
