# Zellij - terminal multiplexer
{ config, lib, ... }:
let
  cfg = config.myFeatures.zellij;
in
{
  options.myFeatures.zellij = {
    enable = lib.mkEnableOption "zellij configuration" // {
      default = true;
      description = "Enable zellij";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.zellij =
      { ... }:
      {
        programs.zellij.enable = true;

        # Use the KDL config file directly since home-manager's zellij module
        # doesn't properly escape attribute names with spaces in plugin configs.
        xdg.configFile."zellij/config.kdl".source = ../../files/zellij.kdl;
      };
  };
}
