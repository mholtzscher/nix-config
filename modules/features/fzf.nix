# FZF - A command-line fuzzy finder
{ config, lib, ... }:
let
  cfg = config.myFeatures.fzf;
in
{
  options.myFeatures.fzf = {
    enable = lib.mkEnableOption "fzf configuration" // {
      default = true;
      description = "Enable fzf (command-line fuzzy finder)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.fzf = {
      programs.fzf = {
        enable = true;
      };
    };
  };
}
