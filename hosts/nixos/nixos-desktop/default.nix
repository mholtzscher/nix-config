{
  pkgs,
  inputs,
  user,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./users.nix
    ./networking.nix
    ./audio.nix
    ./gpu.nix
    ./boot.nix
    ./greeter.nix
  ];

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
          ../../../modules/home-manager/home.nix
          ../../../modules/home-manager/hosts/nixos-desktop/default.nix
        ];
      };
  };

  # Set correct ownership for Steam games partition
  # Using tmpfiles.d is the idiomatic NixOS way for declarative directory permissions
  systemd.tmpfiles.rules = [
    "d /home/${user}/games 0755 ${user} users -"
  ];

  # Logitech MX Master 3 via Bolt receiver - fix scroll wheel breaking after KVM switch
  # Use Solaar to manage the device - it properly handles HID++ protocol
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

  services = {
    # Disable DPMS to prevent screen blanking issues with KVM switching
    logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandleLidSwitch = "ignore";
    };

    # Enable CUPS for printing
    printing.enable = true;

    # Enable mouse/touchpad input support
    libinput.enable = true;
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome # For Niri screencasting support
      pkgs.xdg-desktop-portal-gtk # For better GTK/GNOME app compatibility
    ];
  };

  # System packages specific to this host
  environment.systemPackages = with pkgs; [
    # Clipboard utility for Wayland
    wl-clipboard

    # Browsers
    chromium

    # XWayland integration via xwayland-satellite (recommended by Niri)
    # xwayland-satellite handles X11 app support automatically
    # Niri spawns it on-demand when X11 apps connect (no config needed)
    xwayland-satellite
    xwayland # Still needed as dependency for satellite
    xhost
    xdpyinfo
  ];

  programs = {
    # Niri window manager (scrollable tiling Wayland compositor)
    # Configuration via programs.niri.settings in modules/nixos/hosts/nixos-desktop/composition.nix
    niri.enable = true;

    # DankMaterialShell (Wayland desktop shell) - from flake for IdleMonitor support
    dank-material-shell = {
      enable = true;
      systemd.enable = true;
      systemd.target = "niri.service";
    };

    # Enable browsers
    firefox.enable = true;

    # Gaming configuration
    steam = {
      enable = true;
      remotePlay.openFirewall = false; # Open ports for Steam Remote Play
      dedicatedServer.openFirewall = false; # Open ports for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = false; # Open ports for Steam Local Network Game Transfers
      gamescopeSession.enable = true;
    }; # Enable gamescope compositor option

    # Enable gamemode for performance optimizations during gaming
    gamemode.enable = true;
  };

  # Performance tuning for gaming
  powerManagement.cpuFreqGovernor = "performance";

  # This value determines the NixOS release compatibility.
  # Don't change this without reading the release notes.
  system.stateVersion = "25.05";
}
