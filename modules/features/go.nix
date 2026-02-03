# Go - programming language toolchain helpers
{ config, lib, ... }:
let
  cfg = config.myFeatures.go;
in
{
  options.myFeatures.go = {
    enable = lib.mkEnableOption "go configuration" // {
      default = true;
      description = "Enable go tooling";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.go = {
      programs.go.enable = true;
    };
  };
}
