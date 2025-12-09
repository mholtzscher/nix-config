{
  pkgs,
  inputs,
  user,
  ...
}:
let
  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwjFs5j8xyYI+p3ckPU0nUYyJ9S2Y753DYUEPRbyGqX"
  ];

  primaryLanInterface = "enp87s0";
  nasPatchInterface = "enp88s0";

  nasLink = {
    address = "10.0.0.10";
    prefixLength = 24;
  };

  defaultGateway = {
    address = "10.69.69.1";
    interface = primaryLanInterface;
  };

  primaryNameservers = [
    "10.69.69.1"
  ];

in
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/hosts/wanda
  ];

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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
    };
    users.${user} =
      { ... }:
      {
        imports = [
          ../../../modules/home-manager/home.nix
          ../../../modules/home-manager/hosts/wanda/default.nix
        ];
      };
  };

  networking = {
    hostName = "wanda";
    useNetworkd = true;
    nftables.enable = true;
    inherit defaultGateway;
    nameservers = primaryNameservers;

    interfaces.${primaryLanInterface} = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "10.69.69.60";
          prefixLength = 24;
        }
      ];
    };

    interfaces.${nasPatchInterface} = {
      useDHCP = false;
      ipv4.addresses = [ nasLink ];
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
      allowedUDPPorts = [ 51820 ];
      trustedInterfaces = [ nasPatchInterface ];
    };
  };
  boot = {
    loader = {
      # Boot loader - systemd-boot with separate /boot and /boot/efi
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
  };

  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.1/8"
      "10.69.69.0/24"
    ];
    maxretry = 5;
  };

  programs.zsh.enable = true;

  system.stateVersion = "25.05";
}
