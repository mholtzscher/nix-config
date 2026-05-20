{
  pkgs,
  lib,
  inputs,
  isWork,
  ...
}:
let
  filteredExtensionsSource = builtins.path {
    path = ./files/pi/extensions;
    name = "pi-extensions";
    filter = path: type: type == "directory" || lib.hasSuffix ".ts" (builtins.baseNameOf path);
  };
in
{
  home.packages = lib.optionals (!isWork) [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = lib.optionalAttrs (!isWork) {
    ".pi/agent/AGENTS.md".source = ./files/karpathy-agents.md;

    ".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-5.5";
      defaultThinkingLevel = "medium";
      subagents = {
        agentOverrides = {
          oracle = {
            model = "openai-codex/gpt-5.5";
            thinking = "high";
          };
          reviewer = {
            model = "opencode-go/deepseek-v4-pro";
            thinking = "high";
          };
          planner = {
            model = "openai-codex/gpt-5.5";
            thinking = "medium";
          };
          researcher = {
            model = "opencode-go/deepseek-v4-flash";
            thinking = "medium";
          };
          scout = {
            model = "opencode-go/kimi-k2.6";
            thinking = "medium";
          };
        };
      };
      theme = "tokyo-night";
      workingVibe = "Bruce Schneier";
      workingVibeMode = "file";
      packages = [
        # "./packages/render-mermaid"
        "git:github.com/nicobailon/visual-explainer"
        "npm:@ifi/oh-pi-themes"
        "npm:@plannotator/pi-extension"
        "npm:pi-boomerang"
        # "npm:pi-btw"
        "npm:pi-fff"
        "npm:pi-powerline-footer"
        "npm:pi-subagents"
        "npm:pi-web-access"
      ];
      npmCommand = [
        "mise"
        "exec"
        "node@24"
        "--"
        "npm"
      ];
    };

    ".pi/agent/prompts" = {
      source = ./files/pi/prompts;
      recursive = true;
    };

    ".pi/web-search.json".text = builtins.toJSON {
      workflow = "none";
    };

    ".pi/agent/models.json".text = builtins.toJSON {
      providers = {
        llama-cpp = {
          baseUrl = "http://127.0.0.1:8081/v1";
          api = "openai-completions";
          apiKey = "llama-cpp";
          compat = {
            supportsDeveloperRole = true;
            supportsReasoningEffort = false;
          };
          models = [
            {
              id = "local";
              name = "Local Model";
              reasoning = true;
              input = [
                "text"
                "image"
              ];
              contextWindow = 131072;
              maxTokens = 81920;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };
      };
    };

    ".pi/agent/extensions" = {
      source = filteredExtensionsSource;
      recursive = true;
    };

    ".pi/agent/packages" = {
      source = ./files/pi/packages;
      recursive = true;
    };

    ".pi/agent/vibes" = {
      source = ./files/pi/vibes;
      recursive = true;
    };
  };
}
