# Bottom - resource monitor (btm)
{ config, lib, ... }:
let
  cfg = config.myFeatures.bottom;
in
{
  options.myFeatures.bottom = {
    enable = lib.mkEnableOption "bottom configuration" // {
      default = true;
      description = "Enable bottom (btm)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.bottom = {
      programs.bottom.enable = true;
    };
  };
}
