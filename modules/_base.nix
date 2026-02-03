{ lib, config, ... }:
{
  # Make flake.modules mergeable across multiple flake-parts modules.
  # Each feature module contributes one key under flake.modules.*
  options.flake.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.raw);
    default = { };
    description = "Exported modules (merged from dendritic feature modules)";
  };

  # Export standard flake module outputs from flake.modules.*
  # This eliminates the "unknown flake output 'modules'" warning
  config.flake = {
    # Standard home-manager module export
    homeManagerModules = config.flake.modules.homeManager or { };

    # Standard nix-darwin module export
    darwinModules = config.flake.modules.darwin or { };

    # Standard NixOS module export
    nixosModules = config.flake.modules.nixos or { };
  };
}
