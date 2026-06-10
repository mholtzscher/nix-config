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

  home.file = {
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
            model = "openai-codex/gpt-5.4";
            thinking = "high";
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
      showHardwareCursor = true;
      workingVibe = "Bruce Schneier";
      workingVibeMode = "file";
      "pi-agent-sources" = {
        sources = { };
      };
      packages = [
        "git:github.com/nicobailon/visual-explainer"
        "npm:@ifi/oh-pi-themes"
        "npm:@plannotator/pi-extension"
        "npm:glimpseui"
        "npm:pi-boomerang"
        "npm:pi-fff"
        "npm:pi-powerline-footer"
        "npm:pi-subagents"
        "npm:pi-web-access"
      ];
    };

    ".pi/agent/prompts" = {
      source = ./files/pi/prompts;
      recursive = true;
    };

    ".pi/web-search.json".text = builtins.toJSON {
      workflow = "none";
    };

    ".pi/agent/extensions" = {
      source = filteredExtensionsSource;
      recursive = true;
    };

    ".pi/agent/vibes" = {
      source = ./files/pi/vibes;
      recursive = true;
    };
  };
}
