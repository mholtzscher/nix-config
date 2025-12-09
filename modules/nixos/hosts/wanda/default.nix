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
  imports = [
    ./services.nix
    ./containers.nix
  ];

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

  # Create mount points
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

  # SSH server
  services.openssh = {
    enable = true;
    openFirewall = false;
    ports = [ 22 ];
    listenAddresses = [
      {
        addr = "0.0.0.0";
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

  # Docker for containers
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Users & groups - media group for shared access
  users.groups.media.gid = 1000;

  # Packages
  environment.systemPackages = with pkgs; [
    ethtool
    lazydocker
    nfs-utils
  ];

  # Firewall - container ports only (native services use openFirewall = true)
  networking.firewall = {
    allowedTCPPorts = [
      53 # Pi-hole DNS
      30080 # Pi-hole web
      30081 # Stirling PDF
      # 30082 # Atuin
      3000 # Excalidraw
      # 5003 # Dufs
      48083 # Draft Board
      7777 # Satisfactory
      8888 # Satisfactory RCON
    ];
    allowedUDPPorts = [
      53 # Pi-hole DNS
      7777 # Satisfactory
    ];
  };
}
