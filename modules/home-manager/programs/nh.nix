{
  config,
  pkgs,
  lib,
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

  # Nushell doesn't source home.sessionVariables - set NH_* explicitly
  programs.nushell.extraConfig = lib.mkAfter ''
    $env.NH_DARWIN_FLAKE = "${nhDarwinFlake}"
    $env.NH_OS_FLAKE = "${nhOsFlake}"
  '';
}
