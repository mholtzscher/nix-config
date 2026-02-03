# Yazi - terminal file manager
{ config, lib, ... }:
let
  cfg = config.myFeatures.yazi;
in
{
  options.myFeatures.yazi = {
    enable = lib.mkEnableOption "yazi configuration" // {
      default = true;
      description = "Enable yazi";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.yazi = {
      programs.yazi = {
        enable = true;
        settings.mgr.show_hidden = true;
      };
    };
  };
}
