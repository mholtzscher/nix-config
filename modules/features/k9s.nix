# k9s - Kubernetes TUI
{ config, lib, ... }:
let
  cfg = config.myFeatures.k9s;
in
{
  options.myFeatures.k9s = {
    enable = lib.mkEnableOption "k9s configuration" // {
      default = true;
      description = "Enable k9s";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.k9s = {
      programs.k9s.enable = true;
    };
  };
}
