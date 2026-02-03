# Carapace - shell completion
{ config, lib, ... }:
let
  cfg = config.myFeatures.carapace;
in
{
  options.myFeatures.carapace = {
    enable = lib.mkEnableOption "carapace configuration" // {
      default = true;
      description = "Enable carapace completions";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.carapace = {
      programs.carapace.enable = true;
    };
  };
}
