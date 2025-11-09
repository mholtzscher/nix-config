# Homebrew module entry point
# Imports common configuration shared across all macOS hosts
{ ... }:
{
  imports = [
    ./common.nix
  ];
}
