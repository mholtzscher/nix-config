# Direnv - per-directory environment loading
{ config, lib, ... }:
let
  cfg = config.myFeatures.direnv;
in
{
  options.myFeatures.direnv = {
    enable = lib.mkEnableOption "direnv configuration" // {
      default = true;
      description = "Enable direnv with nix-direnv";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.direnv = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = true;
      };
    };
  };
}
