# Jujutsu - Git-compatible VCS (jj)
{ config, lib, ... }:
let
  cfg = config.myFeatures.jujutsu;
in
{
  options.myFeatures.jujutsu = {
    enable = lib.mkEnableOption "jujutsu configuration" // {
      default = true;
      description = "Enable jujutsu (jj)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.jujutsu = {
      programs.jujutsu = {
        enable = true;
        settings.user = {
          name = "Michael Holtzscher";
          email = "michael@holtzscher.com";
        };
      };
    };
  };
}
