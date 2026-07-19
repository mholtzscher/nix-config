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
  settings = {
    defaultProvider = if isWork then "litellm" else "openai-codex";
    defaultModel = if isWork then "cheap-but-effective--kimi-k2-5" else "gpt-5.6-sol";
    defaultThinkingLevel = "medium";
    enabledModels =
      if isWork then
        [
          "cheap-but-effective--kimi-k2-5"
          "acceptable--sonnet-4-6"
        ]
      else
        [
          "openai-codex/gpt-5.6-*"
          "opencode-go/deepseek-v4-flash"
        ];
    theme = "tokyo-night";
    workingVibe = "parks_and_rec";
    workingVibeMode = "file";
    packages = [
      # "npm:@ff-labs/pi-fff"
      "npm:@ifi/oh-pi-themes"
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:@plannotator/pi-extension"
      "npm:pi-boomerang"
      "npm:pi-mcp-adapter"
      "npm:pi-powerline-footer"
      "npm:pi-web-access"
      "npm:sideshow"
    ];
    powerline = {
      welcome = false;
      disabledSegments = [ "git" ];
      placement = "below";
    };
  };
  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON settings);
in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ./files/karpathy-agents.md;
    # ".pi/agent/AGENTS.md".source = ./files/bot-prompt.md;

    ".pi/agent/settings.json" = lib.mkIf (!isWork) {
      source = settingsFile;
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

    ".pi/agent/boomerang.json".text = builtins.toJSON {
      toolEnabled = true;
      toolGuidance = "";
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
      };
    };
  };

  home.activation.piWorkSettings = lib.mkIf isWork (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent"
      $DRY_RUN_CMD rm -f "$HOME/.pi/agent/settings.json"
      $DRY_RUN_CMD cp ${settingsFile} "$HOME/.pi/agent/settings.json"
      $DRY_RUN_CMD chmod 644 "$HOME/.pi/agent/settings.json"
    ''
  );
}
