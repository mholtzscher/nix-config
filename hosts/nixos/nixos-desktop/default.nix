{
  pkgs,
  inputs,
  config,
  user,
  ...
}:
let
  # SSH Public Keys - Get your key with: ssh-add -L
  sshPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwjFs5j8xyYI+p3ckPU0nUYyJ9S2Y753DYUEPRbyGqX"
    # Add additional keys as needed
  ];

  # KVM EDID Override Configuration
  # Fixes monitor resolution issues when switching between KVM inputs
  # Set to true after capturing EDID file with capture-edid script
  enableEdidOverride = true; # EDID override enabled for KVM resolution fix
  edidBinPath = ../../../modules-legacy/nixos/hosts/nixos-desktop/edid/dp1.bin;
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
    # SSH authorized keys for remote access
    openssh.authorizedKeys.keys = sshPublicKeys;
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
          ../../../modules-legacy/home-manager/home.nix
          ../../../modules-legacy/home-manager/hosts/nixos-desktop/default.nix
        ];
      };
  };

  # Enable NetworkManager for easy network management
  networking = {
    hostName = "nixos-desktop";
    networkmanager.enable = true;

    # Firewall configuration
    firewall = {
      enable = true;
      # Only allow SSH from local network (10.69.69.0/24)
      # This prevents external SSH access while allowing local network connections
      extraCommands = ''
        iptables -A nixos-fw -p tcp --dport 22 -s 10.69.69.0/24 -j nixos-fw-accept
      '';
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

    # Enable sound with pipewire
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

    # Enable CUPS for printing
    printing.enable = true;

    # SSH server configuration
    openssh = {
      enable = true;

      # Security settings - key-based authentication only
      settings = {
        PasswordAuthentication = false; # Disable password login
        PermitRootLogin = "no"; # Disable root login
        KbdInteractiveAuthentication = false; # Disable keyboard-interactive auth

        # Disable X11 forwarding (not needed for Wayland)
        X11Forwarding = false;

        # Only allow specific user
        AllowUsers = [ "michael" ];
      };

      # Port configuration - using standard port 22
      # Change to custom port (e.g., 2222) for additional security if desired
      ports = [ 22 ];
    };

  };

  # DMS (Dank Material Shell) greeter via greetd
  # Runs the login screen under Niri with an explicit greeter-time config.
  programs.dank-material-shell.greeter = {
    enable = true;

    compositor = {
      name = "niri";

      # This runs before the user session (no home-manager), so keep outputs deterministic.
      customConfig = ''
        hotkey-overlay {
          skip-at-startup
        }

        environment {
          DMS_RUN_GREETER "1"
        }

        gestures {
          hot-corners {
            off
          }
        }

        output "DP-1" {
          mode "5120x1440@120"
          scale 1
          position x=0 y=0
        }

        layout {
          background-color "#000000"
        }
      '';
    };

    # Copy the user's DMS config into /var/lib/dms-greeter for theme/wallpaper sync.
    configHome = "/home/michael";

    logs = {
      save = false;
      path = "/var/log/dms-greeter.log";
    };
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

  security.rtkit.enable = true;

  # Enable mouse/touchpad input support
  services.libinput.enable = true;

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
    xorg.xhost
    xorg.xdpyinfo
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
    steam = {

      # Gaming configuration

      enable = true;
      remotePlay.openFirewall = false; # Open ports for Steam Remote Play
      dedicatedServer.openFirewall = false; # Open ports for Source Dedicated Server
      localNetworkGameTransfers.openFirewall = false; # Open ports for Steam Local Network Game Transfers
      gamescopeSession.enable = true;
    }; # Enable gamescope compositor option

    # Enable gamemode for performance optimizations during gaming
    gamemode.enable = true;
  };

  hardware = {

    # NVIDIA GPU support
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Graphics drivers for gaming (Vulkan, OpenGL with 32-bit support)
    graphics = {
      enable = true;
      enable32Bit = true; # Required for 32-bit games
    };

    # EDID override for KVM - forces kernel to use captured EDID
    # instead of relying on KVM to pass through monitor capabilities
    firmware = pkgs.lib.optionals enableEdidOverride [
      (pkgs.runCommand "edid-firmware" { } ''
        mkdir -p $out/lib/firmware/edid
        cp ${edidBinPath} $out/lib/firmware/edid/dp1.bin
      '')
    ];
  };

  # Performance tuning for gaming
  powerManagement.cpuFreqGovernor = "performance";

  boot = {

    # Bootloader configuration
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Kernel parameters for NVIDIA + Wayland
    kernelParams = [
      "nvidia-drm.modeset=1"
    ]
    ++ pkgs.lib.optional enableEdidOverride "drm.edid_firmware=DP-1:edid/dp1.bin";

    # Increase vm.max_map_count for games that need it (some Proton games)
    kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
  };

  # This value determines the NixOS release compatibility.
  # Don't change this without reading the release notes.
  system.stateVersion = "25.05";
}
