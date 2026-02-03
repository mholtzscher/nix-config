{ lib, ... }:
{
  # Make flake.modules mergeable across multiple flake-parts modules.
  # Each feature module contributes one key under flake.modules.*
  options.flake.modules = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.raw);
    default = { };
    description = "Exported modules (merged from dendritic feature modules)";
  };
}
