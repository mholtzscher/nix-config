{ config, ... }:
{
  programs.nh = {
    enable = true;
    osFlake = "/home/michael/nix-config";
    darwinFlake = "${config.home.homeDirectory}/.config/nix-config";
  };
}
