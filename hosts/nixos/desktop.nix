{ pkgs, inputs, config, ... }:
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
    shell = pkgs.zsh;
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
          ../../modules/home-manager/hosts/desktop/default.nix
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
  # Disable DPMS to prevent screen blanking issues with KVM switching
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "ignore";
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

    # Enable the X11 windowing system
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us";
        variant = "";
      };
    };

     # Display manager with Wayland support
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    
    # Desktop environment
    desktopManager.gnome.enable = true;

    # Enable CUPS for printing
    printing.enable = true;
  };

  # Hyprland configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # NVIDIA GPU support with Hyprland optimizations
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Kernel parameters for NVIDIA + Wayland
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # Environment variables for NVIDIA + Hyprland
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  security.rtkit.enable = true;

  # Enable touchpad support (if applicable)
  # services.xserver.libinput.enable = true;

  # System packages specific to this host
  environment.systemPackages = with pkgs; [
    vim
    git
    
    # Hyprland ecosystem
    waybar
    wofi
    dunst
    swww
    grim
    slurp
    wl-clipboard
    xdg-desktop-portal-hyprland
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable firefox
  programs.firefox.enable = true;

  # This value determines the NixOS release compatibility.
  # Don't change this without reading the release notes.
  system.stateVersion = "25.05";
}
