{
  pkgs,
  lib,
  ...
}:
{
  # Enable Catppuccin Mocha theme for NixOS system-level components
  # This themes:
  # - TTY/Console colors (fallback terminal)
  # - Boot loaders (GRUB, Limine - if enabled)
  # - Plymouth boot splash (if enabled)
  # - Display managers like SDDM (if used instead of greetd)
  # Note: User-level apps (terminals, editors, etc.) are themed via home-manager
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  programs = {
    # NixOS-specific system configuration
    # This module contains settings that apply to all NixOS hosts

    # Enable nix-command and flakes (inherited from shared/nix-settings.nix)
    # Additional NixOS-specific nix settings can go here

    # Enable zsh shell system-wide
    zsh.enable = true;
  };

  # Common system packages for all NixOS hosts
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    curl
    tree
    unzip

    # System utilities
    lshw
    pciutils
    usbutils
  ];

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # Security settings
  security.sudo.wheelNeedsPassword = true;

  # Fail2ban for brute-force protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8" # Localhost
      "10.69.69.0/24" # Local network
    ];
  };

  # Enable zram swap
  zramSwap.enable = lib.mkDefault true;

  # Documentation settings
  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = false;
  };

  # Nix settings for download performance
  nix.settings.download-buffer-size = 512 * 1024 * 1024; # 512 MB
}
