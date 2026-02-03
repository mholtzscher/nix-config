# Atuin - shell history with optional sync
{ config, lib, ... }:
let
  cfg = config.myFeatures.atuin;
in
{
  options.myFeatures.atuin = {
    enable = lib.mkEnableOption "atuin configuration" // {
      default = true;
      description = "Enable atuin shell history";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.atuin =
      {
        isWork ? false,
        ...
      }:
      {
        programs.atuin = {
          enable = true;
          settings = {
            auto_sync = !isWork;
            sync_address = if !isWork then "https://atuin.holtzscher.com" else "";
          };
        };
      };
  };
}
