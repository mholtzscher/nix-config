# GitHub CLI
{ config, lib, ... }:
let
  cfg = config.myFeatures.gh;
in
{
  options.myFeatures.gh = {
    enable = lib.mkEnableOption "gh configuration" // {
      default = true;
      description = "Enable GitHub CLI";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.gh =
      { pkgs, ... }:
      {
        programs.gh = {
          enable = true;
          extensions = [ pkgs.gh-notify ];
        };
      };
  };
}
