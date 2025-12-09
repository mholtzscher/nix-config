# Docker containers for services without native NixOS support
# Data stored in /srv/<container>
{ ... }:
let
  # Container data directory
  srvDir = "/srv";

  # Timezone for containers
  tz = "America/Chicago";
in
{
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      # Pi-hole DNS
      pihole = {
        image = "pihole/pihole:latest";
        autoStart = true;
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
        extraOptions = [ "--cap-add=NET_ADMIN" ];
      };

      # Stirling PDF
      stirling-pdf = {
        image = "stirlingtools/stirling-pdf:latest";
        autoStart = true;
        environment = {
          TZ = tz;
          DOCKER_ENABLE_SECURITY = false;
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

      # Excalidraw (stateless)
      excalidraw = {
        image = "excalidraw/excalidraw:latest";
        autoStart = true;
        ports = [ "3000:80/tcp" ];
      };

      # Atuin sync server
      # atuin = {
      #   image = "ghcr.io/atuinsh/atuin:latest";
      #   autoStart = true;
      #   volumes = [
      #     "${srvDir}/atuin/config:/config"
      #   ];
      #   ports = [ "30082:8888/tcp" ];
      #   dependsOn = [ "atuin-db" ];
      #   environment = {
      #     ATUIN_HOST = "0.0.0.0";
      #     ATUIN_PORT = "8888";
      #     ATUIN_DB_URI = "postgres://atuin:atuin@atuin-db:5432/atuin";
      #   };
      #   extraOptions = [ "--network=atuin-net" ];
      # };
      #
      # # Atuin PostgreSQL database
      # atuin-db = {
      #   image = "postgres:14";
      #   autoStart = true;
      #   volumes = [
      #     "${srvDir}/atuin/postgres:/var/lib/postgresql/data"
      #   ];
      #   environment = {
      #     POSTGRES_USER = "atuin";
      #     POSTGRES_PASSWORD = "atuin";
      #     POSTGRES_DB = "atuin";
      #   };
      #   extraOptions = [ "--network=atuin-net" ];
      # };

      # Dufs - file server
      # dufs = {
      #   image = "sigoden/dufs:latest";
      #   autoStart = true;
      #   volumes = [
      #     "${srvDir}/dufs:/data"
      #   ];
      #   ports = [ "5003:5000/tcp" ];
      #   cmd = [
      #     "/data"
      #     "-A"
      #   ];
      # };

      # Draft Board
      draft-board = {
        image = "ghcr.io/mholtzscher/draft-board:latest";
        autoStart = true;
        volumes = [
          "${srvDir}/draft-board:/app/data"
        ];
        ports = [ "48083:8080/tcp" ];
      };

      # Cloudflare Tunnel
      cloudflare-tunnel = {
        image = "cloudflare/cloudflared:latest";
        autoStart = true;
        cmd = [
          "tunnel"
          "--no-autoupdate"
          "run"
        ];
        environmentFiles = [ "${srvDir}/cloudflare-tunnel/tunnel.env" ];
      };

      # Satisfactory dedicated server
      satisfactory = {
        image = "wolveix/satisfactory-server:latest";
        autoStart = true;
        environment = {
          TZ = tz;
          MAXPLAYERS = 4;
          PGID = 1000;
          PUID = 1000;
          STEAMBETA = false;
        };
        volumes = [
          "${srvDir}/satisfactory:/config"
        ];
        ports = [
          "7777:7777/tcp"
          "7777:7777/udp"
          "8888:8888/tcp"
        ];
        extraOptions = [
          "--memory=12g"
          "--memory-reservation=8g"
        ];
      };

      # Factorio server (currently stopped)
      # factorio = {
      #   image = "factoriotools/factorio:stable";
      #   autoStart = false;
      #   volumes = [
      #     "${srvDir}/factorio:/factorio"
      #   ];
      #   ports = [
      #     "34197:34197/udp"
      #   ];
      # };

      # Nebula sync for Pi-hole
      nebula-sync = {
        image = "ghcr.io/lovelaze/nebula-sync:latest";
        autoStart = true;
        environment = {
          FULL_SYNC = true;
          RUN_GRAVITY = true;
          CRON = "0 * * * *";
          TZ = tz;
        };
        environmentFiles = [ "${srvDir}/nebula-sync/config.env" ];
      };

      # Unpackerr - extract downloads for arr apps
      unpackerr = {
        image = "ghcr.io/hotio/unpackerr:latest";
        autoStart = true;
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
  };

  # Create Docker network for Atuin
  # systemd.services.docker-network-atuin = {
  #   description = "Create Atuin Docker network";
  #   after = [ "docker.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "/run/current-system/sw/bin/docker network create atuin-net || true";
  #     ExecStop = "/run/current-system/sw/bin/docker network rm atuin-net || true";
  #   };
  # };

  # Ensure container directories exist
  systemd.tmpfiles.rules = [
    # Pi-hole
    "d ${srvDir}/pihole/config 0755 root root -"
    "d ${srvDir}/pihole/dnsmasq.d 0755 root root -"
    # Stirling PDF
    "d ${srvDir}/stirling-pdf/configs 0755 root root -"
    "d ${srvDir}/stirling-pdf/customFiles 0755 root root -"
    "d ${srvDir}/stirling-pdf/logs 0755 root root -"
    "d ${srvDir}/stirling-pdf/pipeline 0755 root root -"
    "d ${srvDir}/stirling-pdf/trainingData 0755 root root -"
    # Atuin
    # "d ${srvDir}/atuin/config 0755 root root -"
    # "d ${srvDir}/atuin/postgres 0700 999 999 -"
    # Dufs
    # "d ${srvDir}/dufs 0755 michael michael -"
    # Draft Board
    "d ${srvDir}/draft-board 0755 root root -"
    # Cloudflare Tunnel
    "d ${srvDir}/cloudflare-tunnel 0700 root root -"
    # Game servers
    "d ${srvDir}/satisfactory 0755 root root -"
    # "d ${srvDir}/factorio 0755 root root -"
    # Nebula sync
    "d ${srvDir}/nebula-sync 0700 root root -"
    # Unpackerr
    "d ${srvDir}/unpackerr 0755 michael michael -"
  ];
}
