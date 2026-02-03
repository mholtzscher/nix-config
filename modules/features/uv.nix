# uv - Python package manager
{ config, lib, ... }:
let
  cfg = config.myFeatures.uv;
in
{
  options.myFeatures.uv = {
    enable = lib.mkEnableOption "uv configuration" // {
      default = true;
      description = "Enable uv";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.uv = {
      programs.uv.enable = true;
    };
  };
}
