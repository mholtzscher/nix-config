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
    defaultModel = if isWork then "sonnet-5" else "gpt-5.6-sol";
    defaultThinkingLevel = "high";
    showCacheMissNotices = true;
    tuiMode = "fullscreen";
    enabledModels =
      if isWork then
        [
          "cheap-but-effective--kimi-k2-5"
          "sonnet-5"
          "acceptable--sonnet-4-6"
        ]
      else
        [
          "openai-codex/gpt-5.6-*"
          "opencode-go/deepseek-v4-flash"
        ];
    theme = "dark";
    workingVibe = "parks_and_rec";
    workingVibeMode = "file";
    packages = [
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:@plannotator/pi-extension"
      "npm:pi-context-view"
      "npm:pi-mcp-adapter"
      "npm:pi-powerline-footer"
      "npm:pi-subagents"
      "npm:pi-web-access"
      # "npm:sideshow"
      # "git:github.com/mholtzscher/pi-herdr-subagents"
      # "npm:@ff-labs/pi-fff"
      # "npm:@ifi/oh-pi-themes"
      # "npm:pi-boomerang"
    ];
    subagents =
      if isWork then
        { }
      else
        {
          agentOverrides = {
            scout = {
              model = "openai-codex/gpt-5.6-terra";
              thinking = "low";
            };
            researcher = {
              model = "openai-codex/gpt-5.6-sol";
              thinking = "medium";
            };
            worker = {
              model = "openai-codex/gpt-5.6-sol";
              thinking = "high";
            };
            reviewer = {
              model = "openai-codex/gpt-5.6-sol";
              thinking = "high";
            };
            oracle = {
              model = "openai-codex/gpt-5.6-sol";
              thinking = "high";
            };
            delegate = {
              model = "openai-codex/gpt-5.6-sol";
              thinking = "medium";
            };
          };
        };
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
    (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi.override {
      useBun = false;
    })
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ./files/karpathy-agents.md;

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

    # ".pi/agent/herdr-subagents.json".text = builtins.toJSON {
    #   orchestrator.enabled = !isWork;
    #   defaults = {
    #     placement = "tab";
    #     model = "openai-codex/gpt-5.6-sol";
    #     thinking = "medium";
    #   };
    # };

    # ".pi/agent/herdr-subagents/roles" = {
    #   source = ./files/pi/herdr-subagents/roles;
    #   recursive = true;
    # };

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
        mcpServers = {
          home-assistant = {
            url = "https://home.holtzscher.com/api/webhook/mcp_d658f368f407b84c193f22eec56dbb44";
            auth = "oauth";
            oauth = {
              clientId = "http://localhost:19876";
              redirectUri = "http://localhost:19876/callback";
            };
          };

          railway = {
            url = "https://mcp.railway.com";
            auth = "oauth";
          };

          sideshow = {
            url = "https://sideshow.sh/mcp";
          };

          honeycomb = {
            url = "https://mcp.honeycomb.io/mcp";
            auth = "oauth";
          };
        };
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
