# Catppuccin theme defaults
{ config, lib, ... }:
let
  cfg = config.myFeatures.catppuccinTheme;
in
{
  options.myFeatures.catppuccinTheme = {
    enable = lib.mkEnableOption "catppuccin theme defaults" // {
      default = true;
      description = "Enable catppuccin (mocha) theme defaults";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.catppuccinTheme =
      {
        inputs,
        ...
      }:
      {
        imports = [ inputs.catppuccin.homeModules.catppuccin ];

        catppuccin = {
          enable = true;
          flavor = "mocha";
          zellij.enable = false;
        };
      };
  };
}
