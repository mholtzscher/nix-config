# Bat - A cat clone with syntax highlighting and Git integration
{ config, lib, ... }:
let
  cfg = config.myFeatures.bat;
in
{
  options.myFeatures.bat = {
    enable = lib.mkEnableOption "bat configuration" // {
      default = true;
      description = "Enable bat (cat clone with syntax highlighting)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.bat = {
      programs.bat = {
        enable = true;
        # Theme is managed by catppuccin globally
      };
    };
  };
}
