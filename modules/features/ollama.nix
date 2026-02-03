# Ollama - local LLM runner (non-work only)
{ config, lib, ... }:
let
  cfg = config.myFeatures.ollama;
in
{
  options.myFeatures.ollama = {
    enable = lib.mkEnableOption "ollama configuration" // {
      default = true;
      description = "Install ollama on non-work hosts";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.ollama =
      {
        pkgs,
        isWork ? false,
        lib,
        ...
      }:
      {
        config = lib.mkIf (!isWork) {
          home.packages = [ pkgs.ollama ];
        };
      };
  };
}
