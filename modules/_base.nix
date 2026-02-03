{ lib, ... }:
{
  # Base options namespace for all dendritic features
  # Individual feature modules will extend this
  options.myFeatures = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Configuration options for dendritic features";
  };

  # Declare flake.modules namespace to allow merging from multiple modules
  # This enables each feature module to export to flake.modules.homeManager.*
  options.flake = lib.mkOption {
    type = lib.types.submodule {
      freeformType = lib.types.attrsOf (lib.types.attrsOf lib.types.raw);
    };
    default = { };
    description = "Flake module exports (auto-populated by dendritic modules)";
  };
}
