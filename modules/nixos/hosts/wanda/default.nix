{ pkgs, currentSystemUser, ... }:
{
  # NFS mounts
  fileSystems."/srv/media" = {
    device = "nas-a.internal:/volume1/media";
    fsType = "nfs";
    options = [
      "hard"
      "intr"
      "nofail"
      "noatime"
      "nfsvers=4.1"
      "rsize=262144"
      "wsize=262144"
      "nconnect=4"
      "x-systemd.automount"
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };

  fileSystems."/srv/automation" = {
    device = "nas-b.internal:/volume1/automation";
    fsType = "nfs";
    options = [
      "hard"
      "intr"
      "nofail"
      "noatime"
      "nfsvers=4.2"
      "x-systemd.automount"
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/media 0775 root root -"
    "d /srv/automation 0775 root root -"
  ];

  # NAS hostnames
  networking.hosts = {
    "10.69.69.10" = [ "nas-a" "nas-a.internal" ];
    "10.69.69.11" = [ "nas-b" "nas-b.internal" ];
  };

  systemd.network.wait-online.enable = true;

  # Services
  services.tautulli = {
    enable = true;
    dataDir = "/srv/media/config/tautulli";
    port = 8181;
    openFirewall = false;
    user = "tautulli";
    group = "media";
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    ports = [ 22 ];
    listenAddresses = [
      { addr = "0.0.0.0"; port = 22; }
      { addr = "10.69.69.60"; port = 22; }
    ];
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      AllowUsers = [ currentSystemUser ];
      X11Forwarding = false;
      AllowAgentForwarding = true;
      AllowTcpForwarding = true;
    };
  };

  # Containers
  virtualisation.docker.enable = true;
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      plex = {
        image = "lscr.io/linuxserver/plex:latest";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        environment = {
          TZ = "America/Chicago";
          PUID = "1000";
          PGID = "100";
        };
        volumes = [
          "/srv/media/config/plex:/config"
          "/srv/media/data:/data"
        ];
      };

      automation = {
        image = "ghcr.io/example/automation-suite:latest";
        autoStart = true;
        environmentFiles = [ "/var/lib/secrets/automation.env" ];
        volumes = [
          "/srv/automation/state:/state"
          "/srv/automation/cache:/cache"
        ];
        ports = [ "9000:9000/tcp" "9443:9443/tcp" ];
      };
    };
  };

  # Users & groups
  users.groups.media.gid = 65432;
  users.users.tautulli = {
    uid = 65433;
    group = "media";
    home = "/srv/media/config/tautulli";
    createHome = true;
    isSystemUser = true;
  };

  # Packages
  environment.systemPackages = with pkgs; [
    docker-compose
    ethtool
    nfs-utils
  ];

  # Firewall
  networking.firewall.allowedTCPPorts = [ 8181 9000 9443 32400 ];
}
