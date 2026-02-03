# Mise - runtime/version manager
{ config, lib, ... }:
let
  cfg = config.myFeatures.mise;
in
{
  options.myFeatures.mise = {
    enable = lib.mkEnableOption "mise configuration" // {
      default = true;
      description = "Enable mise";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.mise = {
      programs.mise.enable = true;
    };
  };
}
