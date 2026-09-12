{
  config,
  pkgs,
  lib,
  inputs,
  isWork,
  currentSystemName,
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
    defaultModel = if isWork then "claude-opus-5" else "gpt-5.6-sol";
    defaultThinkingLevel = "high";
    showCacheMissNotices = true;
    tuiMode = "fullscreen";
    # pi-subagents-lite gates every subagent's tools to `registeredTools`
    # (agent frontmatter `tools:`) union the tools it discovers from loaded
    # extensions, and falls back to this list for agents without `tools:`.
    # pi-fff registers grep/find lazily on session_start, after that
    # discovery already ran, so the names must be present here or subagents
    # (general-purpose, reviewer) get no FFF-backed grep/find at all.
    # Explore is unaffected: its built-in config supplies registeredTools.
    # Note these must match pi-fff's names for the active mode; in
    # PI_FFF_MODE=override they are the built-in names `grep` and `find`.
    defaultTools = [
      "read"
      "bash"
      "edit"
      "write"
      "grep"
      "find"
    ];
    enabledModels =
      if isWork then
        [
          "litellm/kimi-k2.5"
          "litellm/claude-sonnet-5"
          "litellm/claude-opus-5"
          "litellm/claude-sonnet-4-6"
        ]
      else
        [
          "openai-codex/gpt-6-astra"
          "opencode-go/muse-spark-1.3-contributor"
          "openai-codex/gpt-5.6-*"
          "opencode-go/deepseek-v4.1-flash"
        ];
    theme = "dark";
    workingVibe = "parks_and_rec";
    workingVibeMode = "file";
    packages = [
      "npm:@ff-labs/pi-fff"
      "npm:@juicesharp/rpiv-ask-user-question"
      "npm:@juicesharp/rpiv-todo"
      "npm:@plannotator/pi-extension"
      "npm:pi-context-view"
      "npm:pi-mcp-adapter"
      "npm:pi-powerline-footer"
      "npm:pi-subagents-lite"
      "npm:pi-web-access"
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
      # opencode-go.models = [
      #   {
      #     id = "muse-spark-1.3-contributor";
      #     name = "Muse Spark 1.3 Contributor";
      #     api = "openai-responses";
      #     baseUrl = "https://opencode.ai/zen/go/v1";
      #     reasoning = true;
      #     input = [
      #       "text"
      #       "image"
      #     ];
      #     cost = {
      #       input = 0.1;
      #       output = 0.2;
      #       cacheRead = 0.002;
      #       cacheWrite = 0;
      #     };
      #     compat.sessionAffinityFormat = "openai-nosession";
      #     contextWindow = 1048576;
      #     maxTokens = 131072;
      #     thinkingLevelMap = {
      #       off = null;
      #       minimal = "minimal";
      #       low = "low";
      #       medium = "medium";
      #       high = "high";
      #       xhigh = "xhigh";
      #       max = null;
      #     };
      #   }
      # ];
    };
  };
  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON settings);
  modelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON models);

  piAgentTemplates = {
    Explore = ./files/pi/agents/Explore.md;
    general-purpose = ./files/pi/agents/general-purpose.md;
    reviewer = ./files/pi/agents/reviewer.md;
  };

  # Defaults preserve the current hardcoded frontmatter models.
  defaultPiAgentModels = {
    Explore = "opencode-go/deepseek-v4.1-flash";
    general-purpose = "opencode-go/deepseek-v4.1-flash";
    reviewer = "openai-codex/gpt-6-astra";
  };

  # Host-specific per-agent model overrides, e.g. work-mac must use the
  # enterprise AI gateway (litellm/* from settings.enabledModels).
  piAgentModelOverrides = {
    work-mac = {
      Explore = "litellm/kimi-k2.5";
      general-purpose = "litellm/claude-sonnet-4-6";
      reviewer = "litellm/claude-opus-5";
    };
  };

  currentPiAgentModelOverrides = piAgentModelOverrides.${currentSystemName} or { };

  currentPiAgentModels = defaultPiAgentModels // currentPiAgentModelOverrides;

  # pi-subagents-lite (and pi's agent loader) skip symlinked agent files for
  # security, and home.file (both source and text) installs symlinks to the
  # Nix store. So render templated models to store files here and copy them
  # as regular files in home.activation.piAgents below.
  renderedPiAgentSources = lib.mapAttrs (
    agentName: template:
    pkgs.replaceVars template {
      piAgentModel = currentPiAgentModels.${agentName};
    }
  ) piAgentTemplates;

  copyRenderedPiAgents = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (agentName: src: ''
      $DRY_RUN_CMD cp ${src} "$HOME/.pi/agent/agents/${agentName}.md"
      $DRY_RUN_CMD chmod 644 "$HOME/.pi/agent/agents/${agentName}.md"'') renderedPiAgentSources
  );
in
{
  home.packages = [
    (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi.override {
      useBun = false;
    })
  ];

  home.file = {
    # ".pi/agent/AGENTS.md".source = ./files/karpathy-agents.md;

    ".pi/agent/settings.json" = lib.mkIf (!isWork) {
      source = settingsFile;
    };

    ".pi/agent/models.json" = lib.mkIf (!isWork) {
      force = true;
      source = modelsFile;
    };

    # ctrl+g is the Herdr prefix, so move Pi's external editor off the default.
    ".pi/agent/keybindings.json".text = builtins.toJSON {
      "app.editor.external" = "alt+e";
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

          # Komodo MCP (ghcr.io/mp-tool/komodo-mcp-server). Same !cat pattern
          # as unifi above: stdout becomes the env value, so the API key and
          # secret stay agenix-only and never enter the Nix store. Bare `-e
          # NAME` forwards the adapter-provided value into the container.
          # KOMODO_URL uses wanda's MagicDNS name so the MCP works on and
          # off the LAN (plain HTTP is fine — Tailscale already encrypts it).
          # The FQDN avoids depending on DNS search domains. Note the Docker
          # port binding in modules/home-manager/hosts/wanda/komodo.nix must
          # stay a literal IP (Docker doesn't resolve hostnames there) — if
          # wanda is ever reinstalled and gets a new tailnet IP, update it
          # there; this name keeps working.
          komodo = {
            command = "docker";
            args = [
              "run"
              "-i"
              "--rm"
              "-e"
              "KOMODO_URL=http://tailscale-wanda.tailea9b59.ts.net:9120"
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

  # Copy (not symlink) so pi-subagents-lite loads the agent roles.
  home.activation.piAgents = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD rm -rf "$HOME/.pi/agent/agents"
    $DRY_RUN_CMD mkdir -p "$HOME/.pi/agent/agents"
    ${copyRenderedPiAgents}
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
