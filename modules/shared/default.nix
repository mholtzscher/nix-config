{ ... }:
{
  # Shared NixOS system modules; standalone Home Manager has its own entrypoint.
  imports = [
    ./nix-settings.nix
    ./tailscale.nix
  ];
}
