# Wanda host-specific Home Manager config
{ config, lib, ... }:
let
  cfg = config.myFeatures.hostWanda;
in
{
  options.myFeatures.hostWanda = {
    enable = lib.mkEnableOption "wanda host config" // {
      default = true;
      description = "Host-specific home-manager settings for wanda";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.hostWanda =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        imports = [
          ../../modules-legacy/home-manager/hosts/wanda/containers.nix
        ];

        home.packages = with pkgs; [
          bandwhich
          mtr
          tmux
        ];

        programs.ssh.matchBlocks.nas = {
          host = "nas nas-a nas-b";
          hostname = "nas-a.internal";
          user = "storage";
        };

        programs.firefox.enable = lib.mkForce false;
        programs.ghostty.enable = lib.mkForce false;
        programs.zed-editor.enable = lib.mkForce false;

        # catppuccin module may not be imported on headless hosts
        config = lib.mkIf (config ? catppuccin) {
          catppuccin.firefox.enable = lib.mkForce false;
        };
      };
  };
}
