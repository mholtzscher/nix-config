{
  lib,
  isWork,
  config,
  ...
}:
let
  personalOpenCodeModelProfile = {
    default = "openai/gpt-6-sol";
    build = "openai/gpt-5.6-sol#high";
    plan = "openai/gpt-5.6-sol#high";
    explore = "opencode-go/deepseek-v4.1-flash";
    general = "opencode-go/deepseek-v4.1-flash";
  };

  openCodeSettings = {
    "$schema" = "https://opencode.ai/config.json";
    model = personalOpenCodeModelProfile.default;
    plugins = [ "@plannotator/opencode" ];
    username = "mholtzscher";
    permissions = [
      {
        action = "external_directory";
        resource = "/nix/store/*";
        effect = "allow";
      }
      {
        action = "read";
        resource = "/nix/store/*";
        effect = "allow";
      }
      {
        action = "external_directory";
        resource = "~/code/*";
        effect = "allow";
      }
      {
        action = "read";
        resource = "~/code/*";
        effect = "allow";
      }
      {
        action = "external_directory";
        resource = "~/nix-config/*";
        effect = "allow";
      }
      {
        action = "read";
        resource = "~/nix-config/*";
        effect = "allow";
      }
      {
        action = "external_directory";
        resource = "~/.config/nix-config/*";
        effect = "allow";
      }
      {
        action = "read";
        resource = "~/.config/nix-config/*";
        effect = "allow";
      }
    ];
    agents = {
      build.model = personalOpenCodeModelProfile.build;
      plan.model = personalOpenCodeModelProfile.plan;
      explore.model = personalOpenCodeModelProfile.explore;
      general.model = personalOpenCodeModelProfile.general;
    };
    mcp.servers = {
      home-assistant = {
        type = "remote";
        url = "https://home.holtzscher.com/api/webhook/mcp_d658f368f407b84c193f22eec56dbb44";
        oauth = {
          client_id = "http://localhost:19876";
          callback_port = 19876;
          redirect_uri = "http://localhost:19876/callback";
        };
      };

      railway = {
        type = "remote";
        url = "https://mcp.railway.com";
      };

      sideshow = {
        type = "remote";
        url = "https://sideshow.sh/mcp";
      };

      honeycomb = {
        type = "remote";
        url = "https://mcp.honeycomb.io/mcp";
      };

      unifi-network = {
        type = "local";
        command = [
          "uvx"
          "unifi-network-mcp@latest"
        ];
        environment = {
          UNIFI_HOST = "10.69.69.1";
          UNIFI_USERNAME = "michael-mcp";
          UNIFI_PASSWORD = "{file:${config.home.homeDirectory}/.local/share/agenix/unifi-password}";
          UNIFI_VERIFY_SSL = "false";
        };
      };

      komodo = {
        type = "local";
        command = [
          "docker"
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
        environment = {
          KOMODO_API_KEY = "{file:${config.home.homeDirectory}/.local/share/agenix/komodo-api-key}";
          KOMODO_API_SECRET = "{file:${config.home.homeDirectory}/.local/share/agenix/komodo-api-secret}";
        };
      };
    };
  };
in
{
  home.sessionVariables = {
    OPENCODE_ENABLE_EXPERIMENTAL_MODELS = "true";
  };

  home.file = {
    "${config.xdg.configHome}/opencode/opencode.json" = lib.mkIf (!isWork) {
      text = builtins.toJSON openCodeSettings;
    };
    "${config.xdg.configHome}/opencode/cli.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/v2/cli.json";
      theme.name = "opencode";
      tabs.mode = "on";
      tabs.layout = "vertical";
      plugins = [ "./herdr-opencode" ];
    };
  };

  home.activation.openCodeQuotaUsagePlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    legacy_plugin_dir=${lib.escapeShellArg "${config.xdg.configHome}/opencode/plugins/codex-usage"}
    plugin_dir=${lib.escapeShellArg "${config.xdg.configHome}/opencode/plugins/quota-usage"}
    if [[ -d "$legacy_plugin_dir" && ! -e "$plugin_dir" ]]; then
      run mv "$legacy_plugin_dir" "$plugin_dir"
    elif [[ -e "$legacy_plugin_dir" || -L "$legacy_plugin_dir" ]]; then
      run rm -rf "$legacy_plugin_dir"
    fi
    if [[ -L "$plugin_dir" ]]; then
      run rm "$plugin_dir"
    fi
    run mkdir -p "$plugin_dir"
    run chmod -R u+w "$plugin_dir"
    run cp -R ${./files/opencode/plugins/quota-usage}/. "$plugin_dir/"

    install_local_plugin() {
      plugin_name=$1
      plugin_source=$2
      plugin_dir=${lib.escapeShellArg "${config.xdg.configHome}/opencode/plugins"}/$plugin_name
      if [[ -e "$plugin_dir" || -L "$plugin_dir" ]]; then
        run rm -rf "$plugin_dir"
      fi
      run mkdir -p "$plugin_dir"
      run cp -R "$plugin_source"/. "$plugin_dir/"
    }

    install_local_plugin spec-tools ${./files/opencode/plugins/spec-tools}
    install_local_plugin github-tools ${./files/opencode/plugins/github-tools}
  '';

}
