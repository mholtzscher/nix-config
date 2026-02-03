# Zoxide - A smarter cd command
{ config, lib, ... }:
let
  cfg = config.myFeatures.zoxide;
in
{
  options.myFeatures.zoxide = {
    enable = lib.mkEnableOption "zoxide configuration" // {
      default = true;
      description = "Enable zoxide (smarter cd command)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.zoxide = {
      programs.zoxide = {
        enable = true;
      };
    };
  };
}
