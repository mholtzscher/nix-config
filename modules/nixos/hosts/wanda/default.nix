{ pkgs, currentSystemUser, ... }:
let
  # NAS direct link (10Gbe patch cable)
  maxNasIp = "10.0.0.20";

  # Common NFS mount options
  nfsMountOpts = [
    "nfsvers=4.2"
    "hard"
    "nofail"
    "noatime"
    "x-systemd.automount"
    "x-systemd.requires=network-online.target"
    "x-systemd.after=network-online.target"
  ];
in
{
  # NFS mounts via direct link to max-nas
  fileSystems."/mnt/max-nas/plex" = {
    device = "${maxNasIp}:/mnt/lake/plex";
    fsType = "nfs";
    options = nfsMountOpts;
  };

  fileSystems."/mnt/max-nas/books" = {
    device = "${maxNasIp}:/mnt/lake/books";
    fsType = "nfs";
    options = nfsMountOpts;
  };

  systemd.tmpfiles.rules = [
    "d /mnt/max-nas 0755 root root -"
    "d /mnt/max-nas/plex 0755 root root -"
    "d /mnt/max-nas/books 0755 root root -"
  ];

  # NAS hostname for direct link
  networking.hosts = {
    "${maxNasIp}" = [
      "max-nas"
      "max-nas.internal"
    ];
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
      {
        addr = "0.0.0.0";
        port = 22;
      }
      {
        addr = "10.69.69.60";
        port = 22;
      }
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
        ports = [
          "9000:9000/tcp"
          "9443:9443/tcp"
        ];
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
  networking.firewall.allowedTCPPorts = [
    8181
    9000
    9443
    32400
  ];
}
