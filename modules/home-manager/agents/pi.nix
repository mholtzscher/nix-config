{
  config,
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
          "opencode-go/glm-5.3-flash"
          "opencode-go/muse-spark-1.3-contributor"
          "opencode/muse-spark-1.3-contributor-free"
        ];
    theme = "dark";
    workingVibe = "parks_and_rec";
    workingVibeMode = "file";
    packages = [
      "npm:@ff-labs/pi-fff"
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:@plannotator/pi-extension"
      "npm:pi-context-view"
      "npm:pi-mcp-adapter"
      "npm:pi-powerline-footer"
      "npm:pi-web-access"
      "npm:pi-subagents-lite"
    ];
    powerline = {
      welcome = false;
      disabledSegments = [ "git" ];
      placement = "below";
    };
  };
  # Muse Spark 1.3 is missing from pi's bundled catalog, and OpenCode serves it
  # over the Responses API. https://opencode.ai/docs/go/#endpoints
  models = {
    providers = {
      opencode.models = [
        {
          id = "muse-spark-1.3-contributor-free";
          name = "Muse Spark 1.3 Contributor Free";
          api = "openai-responses";
          baseUrl = "https://opencode.ai/zen/v1";
          reasoning = true;
          input = [
            "text"
            "image"
          ];
          cost = {
            input = 0;
            output = 0;
            cacheRead = 0;
            cacheWrite = 0;
          };
          compat.sessionAffinityFormat = "openai-nosession";
          contextWindow = 1048576;
          maxTokens = 131072;
          thinkingLevelMap = {
            off = null;
            minimal = "minimal";
            low = "low";
            medium = "medium";
            high = "high";
            xhigh = "xhigh";
            max = null;
          };
        }
      ];
      opencode-go.models = [
        {
          id = "muse-spark-1.3-contributor";
          name = "Muse Spark 1.3 Contributor";
          api = "openai-responses";
          baseUrl = "https://opencode.ai/zen/go/v1";
          reasoning = true;
          input = [
            "text"
            "image"
          ];
          cost = {
            input = 0.1;
            output = 0.2;
            cacheRead = 0.002;
            cacheWrite = 0;
          };
          compat.sessionAffinityFormat = "openai-nosession";
          contextWindow = 1048576;
          maxTokens = 131072;
          thinkingLevelMap = {
            off = null;
            minimal = "minimal";
            low = "low";
            medium = "medium";
            high = "high";
            xhigh = "xhigh";
            max = null;
          };
        }
      ];
    };
  };
  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON settings);
  modelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON models);
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

    ".pi/agent/models.json" = lib.mkIf (!isWork) {
      force = true;
      source = modelsFile;
    };

    ".pi/agent/subagents-lite.json" = lib.mkIf (!isWork) {
      force = true;
      text = builtins.toJSON {
        agent.showCost = true;
      };
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

          # UniFi Network controller MCP (https://github.com/sirkirby/unifi-mcp).
          # The ! prefix makes pi-mcp-adapter run the command at connect time;
          # stdout becomes the env value, so the password stays agenix-only.
          "unifi-network" = {
            command = "uvx";
            args = [ "unifi-network-mcp@latest" ];
            env = {
              UNIFI_HOST = "10.69.69.1";
              UNIFI_USERNAME = "michael-mcp";
              UNIFI_PASSWORD = "!cat ${config.home.homeDirectory}/.local/share/agenix/unifi-password";
              UNIFI_VERIFY_SSL = "false";
            };
          };
        };
      };
    };
  };

  home.activation.piAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD rm -rf "$HOME/.pi/agent/agents"
    $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent/agents"
    $DRY_RUN_CMD cp -R ${./files/pi/agents}/. "$HOME/.pi/agent/agents/"
    $DRY_RUN_CMD chmod 644 "$HOME/.pi/agent/agents/"*.md
  '';

  home.activation.piWorkSettings = lib.mkIf isWork (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent"
      $DRY_RUN_CMD rm -f "$HOME/.pi/agent/settings.json"
      $DRY_RUN_CMD cp ${settingsFile} "$HOME/.pi/agent/settings.json"
      $DRY_RUN_CMD chmod 644 "$HOME/.pi/agent/settings.json"
    ''
  );
}
