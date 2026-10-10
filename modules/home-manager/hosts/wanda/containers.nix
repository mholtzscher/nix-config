# Container definitions for Wanda (Ubuntu)
# These can be used to generate docker-compose files via Nix
#
# Future options for Nix-managed containers on non-NixOS:
# 1. Generate docker-compose.yaml files that systemd/Docker manages
# 2. Use arion (Nix docker-compose alternative): github:hercules-ci/arion
# 3. Use podman quadlets with home-manager
#
# For now, this module defines the container specs in Nix format
# so they can be easily converted when you're ready.
{ lib, pkgs, ... }:
let
  # Container data directory
  srvDir = "/srv";

  # Timezone for containers
  tz = "America/Chicago";

  # Container definitions in a structured format
  # These can be converted to docker-compose or arion later
  containers = {
    # DNS
    pihole = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = tz;
      };
      volumes = [
        "${srvDir}/pihole/config:/etc/pihole"
        "${srvDir}/pihole/dnsmasq.d:/etc/dnsmasq.d"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "30080:80/tcp"
      ];
      capabilities = [ "NET_ADMIN" ];
    };

    # PDF tools
    stirling-pdf = {
      image = "stirlingtools/stirling-pdf:latest";
      environment = {
        TZ = tz;
        DOCKER_ENABLE_SECURITY = "false";
        LANGS = "en_GB";
      };
      volumes = [
        "${srvDir}/stirling-pdf/configs:/configs"
        "${srvDir}/stirling-pdf/customFiles:/customFiles"
        "${srvDir}/stirling-pdf/logs:/logs"
        "${srvDir}/stirling-pdf/pipeline:/pipeline"
        "${srvDir}/stirling-pdf/trainingData:/usr/share/tessdata"
      ];
      ports = [ "30081:8080/tcp" ];
    };

    # Whiteboard
    excalidraw = {
      image = "excalidraw/excalidraw:latest";
      ports = [ "3000:80/tcp" ];
    };

    # Fantasy sports
    draft-board = {
      image = "ghcr.io/mholtzscher/draft-board:latest";
      volumes = [ "${srvDir}/draft-board:/app/data" ];
      ports = [ "48083:8080/tcp" ];
    };

    # Tunnel
    cloudflare-tunnel = {
      image = "cloudflare/cloudflared:latest";
      command = [
        "tunnel"
        "--no-autoupdate"
        "run"
      ];
      envFile = "${srvDir}/cloudflare-tunnel/tunnel.env";
    };

    # Game server
    satisfactory = {
      image = "wolveix/satisfactory-server:latest";
      environment = {
        TZ = tz;
        MAXPLAYERS = "4";
        PGID = "1000";
        PUID = "1000";
        STEAMBETA = "false";
      };
      volumes = [ "${srvDir}/satisfactory:/config" ];
      ports = [
        "7777:7777/tcp"
        "7777:7777/udp"
        "8888:8888/tcp"
      ];
      resources = {
        memory = "12g";
        memoryReservation = "8g";
      };
    };

    # Pi-hole sync
    nebula-sync = {
      image = "ghcr.io/lovelaze/nebula-sync:latest";
      environment = {
        FULL_SYNC = "true";
        RUN_GRAVITY = "true";
        CRON = "0 * * * *";
        TZ = tz;
      };
      envFile = "${srvDir}/nebula-sync/config.env";
    };

    # Extract downloads
    unpackerr = {
      image = "ghcr.io/hotio/unpackerr:latest";
      environment = {
        TZ = tz;
        PUID = "1000";
        PGID = "1000";
      };
      volumes = [
        "${srvDir}/unpackerr:/config"
        "/mnt/max-nas/plex:/media"
      ];
    };
  };

  # Helper to generate docker-compose service entry
  mkComposeService =
    name: cfg:
    {
      image = cfg.image;
      container_name = name;
      restart = cfg.restart or "unless-stopped";
    }
    // lib.optionalAttrs (cfg ? environment) {
      environment = cfg.environment;
    }
    // lib.optionalAttrs (cfg ? envFile) {
      env_file = [ cfg.envFile ];
    }
    // lib.optionalAttrs (cfg ? volumes) {
      volumes = cfg.volumes;
    }
    // lib.optionalAttrs (cfg ? ports) {
      ports = cfg.ports;
    }
    // lib.optionalAttrs (cfg ? command) {
      command = cfg.command;
    }
    // lib.optionalAttrs (cfg ? capabilities) {
      cap_add = cfg.capabilities;
    }
    // lib.optionalAttrs (cfg ? resources) {
      deploy.resources.limits = {
        memory = cfg.resources.memory or null;
      };
      deploy.resources.reservations = {
        memory = cfg.resources.memoryReservation or null;
      };
    };

  # Generate full docker-compose structure
  composeFile = {
    version = "3.8";
    services = lib.mapAttrs mkComposeService containers;
  };

  # Generate YAML content
  composeYaml = (pkgs.formats.yaml { }).generate "docker-compose.yaml" composeFile;
in
{
  # Expose container definitions for future use
  # When ready, you can enable this to generate docker-compose.yaml
  #
  # To use:
  # 1. Uncomment the home.file block below
  # 2. Run: home-manager switch --flake .#wanda
  # 3. Start containers: cd ~/containers && docker-compose up -d

  # home.file."containers/docker-compose.yaml".source = composeYaml;

  # For now, just install docker tooling
  home.packages = with pkgs; [
    docker-compose
    lazydocker
  ];
}
