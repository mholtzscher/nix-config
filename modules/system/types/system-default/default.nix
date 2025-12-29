{ inputs, ... }:
{
  imports = [
    ./nixos.nix
    ./darwin.nix
    ./homeManager.nix
  ];
}
