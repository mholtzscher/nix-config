{ lib, ... }:
{
  # Base options namespace for all dendritic features
  # Individual feature modules will extend this
  options.myFeatures = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = "Configuration options for dendritic features";
  };
}
