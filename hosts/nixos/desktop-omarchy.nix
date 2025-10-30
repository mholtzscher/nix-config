{ pkgs, inputs, config, lib, ... }:
let
  user = "michael";
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
      "wheel" # Enable sudo
      "networkmanager" # Network management
      "docker" # Docker access (if enabled)
    ];
    shell = pkgs.nushell;
  };

  # Home Manager configuration
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
          ../../modules/home-manager/home.nix
          ../../modules/home-manager/hosts/desktop-omarchy.nix
        ];
      };
  };

  # Enable NetworkManager for easy network management
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  # Bootloader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
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
  services = {

    # Enable sound with pipewire
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };

    # Display manager is handled by omarchy-nix (uses greetd)
    
    # Enable CUPS for printing
    printing.enable = true;
  };

  # Enable the X11 windowing system for compatibility
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # NVIDIA GPU support
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  security.rtkit.enable = true;

  # Enable touchpad support (if applicable)
  # services.xserver.libinput.enable = true;

  # System packages specific to this host (omarchy-nix handles most packages)
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable firefox
  programs.firefox.enable = true;

  # XDG portals are handled by omarchy-nix

  # This value determines the NixOS release compatibility.
  # Don't change this without reading the release notes.
  system.stateVersion = "25.05";
}
