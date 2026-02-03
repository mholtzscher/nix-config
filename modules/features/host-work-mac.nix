# Work Mac host-specific Home Manager config
{ config, lib, ... }:
let
  cfg = config.myFeatures.hostWorkMac;
in
{
  options.myFeatures.hostWorkMac = {
    enable = lib.mkEnableOption "work-mac host config" // {
      default = true;
      description = "Host-specific home-manager settings for work-mac";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.hostWorkMac =
      {
        pkgs,
        inputs,
        ...
      }:
      {
        home.packages = with pkgs; [
          aerospace
          inputs.aerospace-utils.packages.${pkgs.stdenv.hostPlatform.system}.default
          mkalias
          pokemon-colorscripts-mac
        ];
      };
  };
}
