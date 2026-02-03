# Eza - A modern replacement for ls
{ config, lib, ... }:
let
  cfg = config.myFeatures.eza;
in
{
  options.myFeatures.eza = {
    enable = lib.mkEnableOption "eza configuration" // {
      default = true;
      description = "Enable eza (modern ls replacement)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.eza = {
      programs.eza = {
        enable = true;
        git = true;
        extraOptions = [
          "--header"
        ];
      };
    };
  };
}
