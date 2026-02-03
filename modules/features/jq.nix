# jq - JSON processor
{ config, lib, ... }:
let
  cfg = config.myFeatures.jq;
in
{
  options.myFeatures.jq = {
    enable = lib.mkEnableOption "jq configuration" // {
      default = true;
      description = "Enable jq";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.jq = {
      programs.jq.enable = true;
    };
  };
}
