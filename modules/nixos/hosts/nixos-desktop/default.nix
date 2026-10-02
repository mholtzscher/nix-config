{ pkgs, ... }:
{
  # NixOS Desktop Environment Configuration
  # This module provides a complete desktop environment setup including:
  # - Niri window manager + Noctalia integration
  # - Gaming tools and configuration
  # - Theming (GTK, Qt, dark mode)
  # - Web applications as native apps

  imports = [
    ./packages.nix # Desktop packages, fonts, 1Password
    ./composition.nix # Niri window manager + Noctalia integration
    ./gaming.nix # Gaming tools (Steam, MangoHud, etc.)
    ./webapps.nix # Web applications as native apps
  ];

  # MakeMKV uses the SCSI generic device to send MMC commands to the drive.
  # systemd's default udev rules restrict cdrom access to optical SCSI devices.
  boot.kernelModules = [ "sg" ];

  users.users.michael.extraGroups = [ "cdrom" ];

  # Run unpatched dynamically linked binaries built for conventional Linux systems.
  programs.nix-ld.enable = true;

  services.ollama = {
    enable = true;
    # Keep this override until nixpkgs provides Ollama 0.35 or newer.
    package = pkgs.ollama-cuda.overrideAttrs {
      version = "0.35.0";
      src = pkgs.fetchFromGitHub {
        owner = "ollama";
        repo = "ollama";
        tag = "v0.35.0";
        hash = "sha256-J/4wqiQKVnGYaeFMb1n2lp5seGfCdScJQj3SgOhZLog=";
      };
      vendorHash = "sha256-45FfI47tNHBPYOBLRrwuhADCUtkjAhlFrExlEy9piMI=";
    };
  };
}
