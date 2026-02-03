# Ripgrep - A fast line-oriented search tool
{ config, lib, ... }:
let
  cfg = config.myFeatures.ripgrep;
in
{
  options.myFeatures.ripgrep = {
    enable = lib.mkEnableOption "ripgrep configuration" // {
      default = true;
      description = "Enable ripgrep (fast line-oriented search tool)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.ripgrep = {
      programs.ripgrep = {
        enable = true;
      };
    };
  };
}
