# Lazydocker - Docker TUI
{ config, lib, ... }:
let
  cfg = config.myFeatures.lazydocker;
in
{
  options.myFeatures.lazydocker = {
    enable = lib.mkEnableOption "lazydocker configuration" // {
      default = true;
      description = "Enable lazydocker";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.lazydocker = {
      programs.lazydocker.enable = true;
    };
  };
}
