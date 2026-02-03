# Personal Mac host-specific Home Manager config
{ config, lib, ... }:
let
  cfg = config.myFeatures.hostPersonalMac;
in
{
  options.myFeatures.hostPersonalMac = {
    enable = lib.mkEnableOption "personal-mac host config" // {
      default = true;
      description = "Host-specific home-manager settings for personal-mac";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.hostPersonalMac =
      {
        pkgs,
        inputs,
        ...
      }:
      {
        home.packages = with pkgs; [
          code-cursor
          discord

          aerospace
          inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
          mkalias
          pokemon-colorscripts-mac
        ];
      };
  };
}
