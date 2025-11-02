{ ... }:
{
  # Import all NixOS-specific modules
  imports = [
    ./nixos.nix
    ./fonts.nix
  ];
}
