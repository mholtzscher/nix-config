# Wanda containers (docker-compose generation)
{ config, lib, ... }:
let
  cfg = config.myFeatures.wandaContainers;
in
{
  options.myFeatures.wandaContainers = {
    enable = lib.mkEnableOption "wanda container specs" // {
      default = true;
      description = "Wanda container definitions and optional compose generation";
    };

    generateCompose = lib.mkEnableOption "generate docker-compose.yaml" // {
      default = false;
      description = "Write containers/docker-compose.yaml from the Nix container specs";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.wandaContainers =
      {
        lib,
        pkgs,
        ...
      }:
      let
        srvDir = "/srv";
        tz = "America/Chicago";

        containers = {
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

          excalidraw = {
            image = "excalidraw/excalidraw:latest";
            ports = [ "3000:80/tcp" ];
          };

          draft-board = {
            image = "ghcr.io/mholtzscher/draft-board:latest";
            volumes = [ "${srvDir}/draft-board:/app/data" ];
            ports = [ "48083:8080/tcp" ];
          };

          cloudflare-tunnel = {
            image = "cloudflare/cloudflared:latest";
            command = [
              "tunnel"
              "--no-autoupdate"
              "run"
            ];
            envFile = "${srvDir}/cloudflare-tunnel/tunnel.env";
          };

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

        mkComposeService =
          name: c:
          {
            image = c.image;
            container_name = name;
            restart = c.restart or "unless-stopped";
          }
          // lib.optionalAttrs (c ? environment) { environment = c.environment; }
          // lib.optionalAttrs (c ? envFile) { env_file = [ c.envFile ]; }
          // lib.optionalAttrs (c ? volumes) { volumes = c.volumes; }
          // lib.optionalAttrs (c ? ports) { ports = c.ports; }
          // lib.optionalAttrs (c ? command) { command = c.command; }
          // lib.optionalAttrs (c ? capabilities) { cap_add = c.capabilities; }
          // lib.optionalAttrs (c ? resources) {
            deploy.resources.limits.memory = c.resources.memory or null;
            deploy.resources.reservations.memory = c.resources.memoryReservation or null;
          };

        composeFile = {
          version = "3.8";
          services = lib.mapAttrs mkComposeService containers;
        };

        composeYaml = (pkgs.formats.yaml { }).generate "docker-compose.yaml" composeFile;
      in
      {
        home.packages = with pkgs; [
          docker-compose
        ];

        home.file = lib.mkIf cfg.generateCompose {
          "containers/docker-compose.yaml".source = composeYaml;
        };
      };
  };
}
