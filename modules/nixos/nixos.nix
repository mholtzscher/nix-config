{
  pkgs,
  lib,
  ...
}:
{
  programs = {
    # NixOS-specific system configuration
    # This module contains settings that apply to all NixOS hosts

    # Enable nix-command and flakes (inherited from shared/nix-settings.nix)
    # Additional NixOS-specific nix settings can go here

    # Enable fish shell system-wide
    fish.enable = true;

    # Enable zsh shell system-wide
    zsh.enable = true;

    # Enable git system-wide
    git.enable = true;

    _1password = {
      enable = true;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "michael" ];
    };
  };

  # Common system packages for all NixOS hosts
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    vim
    wget
    curl
    htop
    tree
    unzip

    python314
    # python313Packages.debugpy
    rustc
    cargo
    gcc

    # System utilities
    lshw
    pciutils
    usbutils
  ];

  # Enable automatic login for the display manager (can be overridden per-host)
  # services.displayManager.autoLogin.enable = lib.mkDefault false;

  # Console configuration
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # Security settings
  security.sudo.wheelNeedsPassword = true;

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
