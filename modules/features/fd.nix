# FD - A simple, fast and user-friendly alternative to 'find'
{ config, lib, ... }:
let
  cfg = config.myFeatures.fd;
in
{
  options.myFeatures.fd = {
    enable = lib.mkEnableOption "fd configuration" // {
      default = true;
      description = "Enable fd (fast and user-friendly find alternative)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.fd = {
      programs.fd = {
        enable = true;
      };
    };
  };
}
