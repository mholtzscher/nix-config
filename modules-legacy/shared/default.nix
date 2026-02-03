{ ... }:
{
  # Import all shared modules that work across macOS and NixOS
  imports = [
    ./nix-settings.nix
  ];
}
