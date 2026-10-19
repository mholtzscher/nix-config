{ ... }:
let
  nhOsFlake = "/home/michael/nix-config";
in
{
  programs.nh = {
    enable = true;
    osFlake = nhOsFlake;
  };
}
