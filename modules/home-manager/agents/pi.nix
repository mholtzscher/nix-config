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
  personalPiModelProfile = {
    defaultProvider = "openai-codex";
    defaultModel = "gpt-5.6-sol";
    enabledModels = [
      "openai-codex/gpt-5.6-sol"
      "opencode-go/deepseek-v4.1-flash"
      "openai-codex/gpt-6-astra"
      "opencode-go/muse-spark-1.3-contributor"
    ];
    agentModels = {
      scout = "opencode-go/deepseek-v4.1-flash";
      worker = "opencode-go/deepseek-v4.1-flash";
      reviewer = "opencode-go/muse-spark-1.3-contributor";
    };
  };
  workPiModelProfile = {
    defaultProvider = "litellm";
    defaultModel = "claude-opus-5";
    enabledModels = [
      "litellm/kimi-k2.5"
      "litellm/claude-sonnet-5"
      "litellm/claude-opus-5"
      "litellm/claude-sonnet-4-6"
    ];
    agentModels = {
      scout = "litellm/kimi-k2.5";
      worker = "litellm/claude-sonnet-4-6";
      reviewer = "litellm/claude-opus-5";
    };
  };
  currentPiModelProfile = if isWork then workPiModelProfile else personalPiModelProfile;

  settings = {
    inherit (currentPiModelProfile) defaultProvider defaultModel enabledModels;
    defaultThinkingLevel = "high";
    showCacheMissNotices = true;
    tuiMode = "fullscreen";
    subagents = {
      defaultThinking = "high";
      agentOverrides = {
        scout.model = currentPiModelProfile.agentModels.scout;
        worker.model = currentPiModelProfile.agentModels.worker;
        reviewer.model = currentPiModelProfile.agentModels.reviewer;
        researcher.disabled = true;
        oracle.disabled = true;
        delegate.disabled = true;
        "evidence-auditor".disabled = true;
        "claude-code".disabled = true;
        "claude-code-writer".disabled = true;
        "codex-exec".disabled = true;
        "codex-exec-writer".disabled = true;
        "cursor-agent".disabled = true;
        "cursor-agent-writer".disabled = true;
      };
    };
    theme = "dark";
    workingVibe = "parks_and_rec";
    workingVibeMode = "file";
    packages = [
      "git:github.com/earendil-works/pi-review"
      "npm:@ff-labs/pi-fff"
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:@juicesharp/rpiv-todo"
      "npm:@mholtzscher/pi-extensions"
      "npm:@plannotator/pi-extension"
      "npm:pi-context-view"
      "npm:pi-mcp-adapter"
      "npm:pi-powerline-footer"
      "npm:pi-subagents"
      "npm:pi-web-access"
    ];
    powerline = {
      welcome = false;
      disabledSegments = [ "git" ];
      placement = "below";
    };
  };
  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON settings);

  piAgentSources = {
    reviewer = ./files/pi/agents/reviewer.md;
  };

  # Copy custom agents as regular files so Pi discovers them consistently.
  copyPiAgents = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (agentName: src: ''
      $DRY_RUN_CMD cp ${src} "$HOME/.pi/agent/agents/${agentName}.md"
      $DRY_RUN_CMD chmod 644 "$HOME/.pi/agent/agents/${agentName}.md"'') piAgentSources
  );
in
{
  home.packages = [
    (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi.override {
      useBun = false;
    })
  ];

  home.file = {
    ".pi/agent/settings.json" = lib.mkIf (!isWork) {
      source = settingsFile;
    };

    # ctrl+g is the Herdr prefix, so move Pi's external editor off the default.
    ".pi/agent/keybindings.json".text = builtins.toJSON {
      "app.editor.external" = "alt+e";
    };

    ".pi/agent/prompts" = {
      source = ./files/pi/prompts;
      recursive = true;
    };

    ".pi/agent/web-search.json".text = builtins.toJSON {
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

          komodo = {
            command = "docker";
            args = [
              "run"
              "-i"
              "--rm"
              "-e"
              "KOMODO_URL=http://wanda.tailea9b59.ts.net:9120"
              "-e"
              "KOMODO_API_KEY"
              "-e"
              "KOMODO_API_SECRET"
              "-e"
              "MCP_TRANSPORT=stdio"
              "ghcr.io/mp-tool/komodo-mcp-server:latest"
            ];
            env = {
              KOMODO_API_KEY = "!cat ${config.home.homeDirectory}/.local/share/agenix/komodo-api-key";
              KOMODO_API_SECRET = "!cat ${config.home.homeDirectory}/.local/share/agenix/komodo-api-secret";
            };
          };
        };
      };
    };
  };

  # Copy the custom reviewer into Pi's user agent directory.
  home.activation.piAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD rm -rf "$HOME/.pi/agent/agents"
    $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent/agents"
    ${copyPiAgents}
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
