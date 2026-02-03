{
  pkgs,
  config,
  user,
  ...
}:
let
  # SSH Public Keys - Get your key with: ssh-add -L
  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwjFs5j8xyYI+p3ckPU0nUYyJ9S2Y753DYUEPRbyGqX"
  ];

  # KVM EDID Override Configuration
  # Fixes monitor resolution issues when switching between KVM inputs
  enableEdidOverride = true;
  edidBinPath = ../../../files/edid/dp1.bin;
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # User configuration
  users.users.${user} = {
    isNormalUser = true;
    home = "/home/${user}";
    description = "Michael Holtzscher";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = sshPublicKeys;
  };

  # Networking
  networking = {
    hostName = "nixos-desktop";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      # Only allow SSH from local network
      extraCommands = ''
        iptables -A nixos-fw -p tcp --dport 22 -s 10.69.69.0/24 -j nixos-fw-accept
      '';
    };
  };

  # Steam games partition
  systemd.tmpfiles.rules = [
    "d /home/${user}/games 0755 ${user} users -"
  ];

  # Logitech MX Master 3 via Bolt receiver
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  # Time zone and locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Keyboard layout
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # EDID override for KVM
  hardware.firmware = pkgs.lib.optionals enableEdidOverride [
    (pkgs.runCommand "edid-firmware" { } ''
      mkdir -p $out/lib/firmware/edid
      cp ${edidBinPath} $out/lib/firmware/edid/dp1.bin
    '')
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # EDID kernel parameter
    kernelParams = pkgs.lib.optional enableEdidOverride "drm.edid_firmware=DP-1:edid/dp1.bin";
  };

  system.stateVersion = "25.05";
}
