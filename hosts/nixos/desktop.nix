{
  pkgs,
  inputs,
  config,
  ...
}:
let
  user = "michael";

  # KVM EDID Override Configuration
  # Set to true after capturing EDID file and adding it to git
  # See modules/home-manager/files/hyprland/README-EDID-Override.md for instructions
  enableEdidOverride = true; # Set to true when dp1.bin exists
  edidBinPath = ../../modules/home-manager/files/hyprland/edid/dp1.bin;

  # SSH Public Keys - Get your key with: ssh-add -L
  # TODO: Add your SSH public key here before applying configuration
  sshPublicKeys = [
    # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your-key-comment"
    # Add additional keys as needed
  ];
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
          inputs.vicinae.homeManagerModules.default
          ../../modules/home-manager/home.nix
          ../../modules/home-manager/hosts/desktop/default.nix
        ];
      };
  };

  # Enable NetworkManager for easy network management
  networking = {
    hostName = "nixos";
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

    # Greetd display manager with tuigreet greeter
    greetd = {
      enable = true;
      settings = {
        default_session = {
          # tuigreet will show available sessions (Hyprland, Niri, etc.)
          # --remember-session saves last selected session
          # Remove --sessions flag to use system default paths
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember-session --asterisks";
          user = "greeter";
        };
      };
    };

    # Enable CUPS for printing
    printing.enable = true;

    # SSH server configuration
    openssh = {
      enable = true;
      
      # Security settings - key-based authentication only
      settings = {
        PasswordAuthentication = false;       # Disable password login
        PermitRootLogin = "no";              # Disable root login
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
    
    # Fail2ban for brute-force protection
    fail2ban = {
      enable = true;
      maxretry = 5;
      ignoreIP = [
        "127.0.0.1/8"      # Localhost
        "10.69.69.0/24"    # Local network
      ];
    };
  };

  # Environment variables for NVIDIA + Hyprland
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  services.displayManager.sessionPackages = [ pkgs.niri ];

  # XDG portals for Wayland
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
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
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  programs = {

    # Niri window manager (scrollable tiling Wayland compositor)
    niri = {
      enable = true;
    };

    # Hyprland configuration
    hyprland = {
      enable = true;
      xwayland.enable = true;
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

    # NVIDIA GPU support with Hyprland optimizations
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # EDID override for KVM - forces kernel to use captured EDID
    # instead of relying on KVM to pass through monitor capabilities
    firmware = pkgs.lib.optionals enableEdidOverride [
      (pkgs.runCommand "edid-firmware" { } ''
        mkdir -p $out/lib/firmware/edid
        cp ${edidBinPath} $out/lib/firmware/edid/dp1.bin
      '')
    ];

    # Graphics drivers for gaming (Vulkan, OpenGL with 32-bit support)
    graphics = {
      enable = true;
      enable32Bit = true; # Required for 32-bit games
    };
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
