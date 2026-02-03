# Homebrew host-specific config: work mac
{ config, lib, ... }:
let
  cfg = config.myFeatures.homebrewWorkMac;
in
{
  options.myFeatures.homebrewWorkMac = {
    enable = lib.mkEnableOption "homebrew work mac" // {
      default = true;
      description = "Work mac homebrew packages";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.darwin.homebrewWorkMac = {
      homebrew = {
        brews = [ ];
        casks = [
          "intellij-idea"
        ];
        masApps = { };
      };
    };
  };
}
