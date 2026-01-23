{ ... }:
{
  # Import all NixOS-specific modules
  # Note: Font configuration is in host-specific modules (e.g., nixos-desktop/packages.nix)
  imports = [
    ./nixos.nix
    ./brave-policies.nix
  ];
}
