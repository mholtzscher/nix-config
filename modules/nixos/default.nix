{ ... }:
{
  # Import all NixOS-specific modules
  imports = [
    ./nixos.nix
    ../brave/nixos.nix
  ];
}
