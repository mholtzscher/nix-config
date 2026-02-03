# Bun - JavaScript runtime
{ config, lib, ... }:
let
  cfg = config.myFeatures.bun;
in
{
  options.myFeatures.bun = {
    enable = lib.mkEnableOption "bun configuration" // {
      default = true;
      description = "Enable bun";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.bun = {
      programs.bun.enable = true;
    };
  };
}
