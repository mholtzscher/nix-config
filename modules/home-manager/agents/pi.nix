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
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ./files/karpathy-agents.md;

    ".pi/agent/settings.json".text = builtins.toJSON {
      defaultProvider = if isWork then "litellm" else "openai-codex";
      defaultModel = if isWork then "cheap-but-effective--kimi-k2-5" else "gpt-5.5";
      defaultThinkingLevel = "medium";
      enabledModels =
        if isWork then
          [
            "cheap-but-effective--kimi-k2-5"
            "acceptable--sonnet-4-6"
          ]
        else
          [
            "openai-codex/gpt-5.5"
            "opencode-go/deepseek*"
            "opencode-go/kimi-k2.7-code"
            "opencode-go/glm-5.2"
          ];
      theme = "tokyo-night";
      showHardwareCursor = true;
      workingVibe = "Bruce Schneier";
      workingVibeMode = "file";
      "pi-agent-sources" = {
        sources = { };
      };
      packages = [
        # "git:github.com/nicobailon/visual-explainer"
        "npm:@ifi/oh-pi-themes"
        "npm:@plannotator/pi-extension"
        "npm:glimpseui"
        "npm:pi-boomerang"
        "npm:@ff-labs/pi-fff"
        "npm:pi-mcp-adapter"
        "npm:pi-powerline-footer"
        "npm:pi-web-access"
      ];
    };

    ".pi/agent/prompts" = {
      source = ./files/pi/prompts;
      recursive = true;
    };

    # ".pi/agent/models.json" = lib.mkIf (!isWork) {
    #   text = builtins.toJSON {
    #     providers = {
    #       "opencode-go" = {
    #         models = [
    #           {
    #             id = "glm-5.2";
    #             name = "GLM-5.2";
    #             reasoning = true;
    #             input = [ "text" ];
    #             contextWindow = 1000000;
    #             maxTokens = 131072;
    #             thinkingLevelMap = {
    #               off = null;
    #               minimal = null;
    #               low = null;
    #               medium = null;
    #               high = "high";
    #               xhigh = "max";
    #             };
    #           }
    #         ];
    #       };
    #     };
    #   };
    # };

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

    ".pi/agent/mcp.json" = lib.mkIf (!isWork) {
      text = builtins.toJSON {
        sideshow = {
          command = "npx";
          args = [
            "-y"
            "sideshow"
            "mcp"
          ];
          lifecycle = "lazy";
        };
      };
    };
  };
}
