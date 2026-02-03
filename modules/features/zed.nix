# Zed - editor
{ config, lib, ... }:
let
  cfg = config.myFeatures.zed;
in
{
  options.myFeatures.zed = {
    enable = lib.mkEnableOption "zed configuration" // {
      default = true;
      description = "Export zed module (disabled by default)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.zed =
      { lib, ... }:
      {
        programs.zed-editor = {
          enable = lib.mkDefault false;
          userSettings = {
            vim_mode = true;
          };
        };
      };
  };
}
