{ inputs, ... }:
{
  # Configure flake-parts for dendritic architecture
  imports = [
    inputs.flake-parts.flakeModules.modules
    ../../hosts/_hosts-outputs.nix
  ];

  systems = [
    "aarch64-darwin"
    "x86_64-linux"
  ];

  # Import lib helpers (mkNixos, mkDarwin)
  perSystem =
    { config, ... }:
    {
      _module.args = {
        inherit inputs;
      };
    };
}
