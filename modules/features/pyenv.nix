# Pyenv - Python version manager
{ config, lib, ... }:
let
  cfg = config.myFeatures.pyenv;
in
{
  options.myFeatures.pyenv = {
    enable = lib.mkEnableOption "pyenv configuration" // {
      default = true;
      description = "Export pyenv module (disabled by default)";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.pyenv =
      { lib, ... }:
      {
        programs.pyenv.enable = lib.mkDefault false;
      };
  };
}
