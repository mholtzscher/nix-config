{
  config,
  ...
}:
let
  nhDarwinFlake = "${config.home.homeDirectory}/.config/nix-config";
  nhOsFlake = "/home/michael/nix-config";
in
{
  programs.nh = {
    enable = true;
    osFlake = nhOsFlake;
    darwinFlake = nhDarwinFlake;
  };
}
