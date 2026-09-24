{
  lib,
  isWork,
  config,
  ...
}:
let
  personalOpenCodeModelProfile = {
    build = "openai/gpt-6-sol#low";
    plan = "openai/gpt-6-sol";
    explore = "opencode-go/deepseek-v4.1-flash";
    general = "openai/gpt-6-luna#high";
  };

  openCodeSettings = {
    "$schema" = "https://opencode.ai/config.json";
    plugins = [
      "@plannotator/opencode"
      "github:mholtzscher/opencode-plugins#main::path:quota-usage"
      "github:mholtzscher/opencode-plugins#main::path:spec-tools"
      "github:mholtzscher/opencode-plugins#main::path:github-tools"
    ];
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
        action = "edit";
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
      {
        action = "edit";
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
      tabs.layout = "horizontal";
      plugins = [ "./herdr-opencode" ];
    };
  };

  home.activation.removeBundledOpenCodePlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for plugin_name in codex-usage quota-usage spec-tools github-tools; do
      plugin_dir=${lib.escapeShellArg "${config.xdg.configHome}/opencode/plugins"}/$plugin_name
      if [[ -e "$plugin_dir" || -L "$plugin_dir" ]]; then
        run rm -rf "$plugin_dir"
      fi
    done
  '';

}
