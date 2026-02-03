# Poetry - Python dependency manager
{ config, lib, ... }:
let
  cfg = config.myFeatures.poetry;
in
{
  options.myFeatures.poetry = {
    enable = lib.mkEnableOption "poetry configuration" // {
      default = true;
      description = "Export poetry module (disabled by default)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.poetry =
      { lib, ... }:
      {
        programs.poetry = {
          enable = lib.mkDefault false;
          settings = {
            virtualenvs.create = true;
            virtualenvs.in-project = true;
          };
        };
      };
  };
}
