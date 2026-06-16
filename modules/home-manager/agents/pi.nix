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
      defaultProvider = if isWork then "litellm" else "openai-codex";
      defaultModel = if isWork then "cheap-but-effective--kimi-k2-5" else "gpt-5.5";
      defaultThinkingLevel = "medium";
      enabledModels = if isWork then [ "cheap-but-effective--kimi-k2-5" ] else [ ];
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
        "npm:pi-fff"
        "npm:pi-mcp-adapter"
        "npm:pi-powerline-footer"
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
