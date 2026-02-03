# Delta - Beautiful git diff viewer
{ config, lib, ... }:
let
  cfg = config.myFeatures.delta;
in
{
  options.myFeatures.delta = {
    enable = lib.mkEnableOption "delta" // {
      default = true;
      description = "Enable delta git diff viewer";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.delta = {
      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          # side-by-side = true;
          dark = true;
        };
      };
    };
  };
}
