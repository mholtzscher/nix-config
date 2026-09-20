{ ... }:
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
    ./bonsai.nix # Bonsai 2 27B local LLM server (CUDA)
  ];

  # MakeMKV uses the SCSI generic device to send MMC commands to the drive.
  # systemd's default udev rules restrict cdrom access to optical SCSI devices.
  boot.kernelModules = [ "sg" ];

  users.users.michael.extraGroups = [ "cdrom" ];

  # Run unpatched dynamically linked binaries built for conventional Linux systems.
  programs.nix-ld.enable = true;

  # Bonsai 2 27B local inference on the RTX 3090 (llama-server on localhost:8888).
  services.bonsai.enable = true;

}
