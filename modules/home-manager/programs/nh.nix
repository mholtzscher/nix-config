{
  config,
  pkgs,
  lib,
  isDarwin,
  currentSystemName,
  ...
}:
let
  nhDarwinFlake = "${config.home.homeDirectory}/.config/nix-config";
  nhOsFlake = "/home/michael/nix-config";
  nhHomeFlake = "${config.home.homeDirectory}/.config/nix-config#${currentSystemName}";
in
{
  programs.nh = {
    enable = true;
    osFlake = nhOsFlake;
    darwinFlake = nhDarwinFlake;
    homeFlake = lib.mkIf isDarwin nhHomeFlake;
  };

  # Nushell doesn't source home.sessionVariables - set NH_* explicitly
  programs.nushell.extraConfig = lib.mkAfter (
    ''
      $env.NH_DARWIN_FLAKE = "${nhDarwinFlake}"
      $env.NH_OS_FLAKE = "${nhOsFlake}"
    ''
    + lib.optionalString isDarwin ''
      $env.NH_HOME_FLAKE = "${nhHomeFlake}"
    ''
  );
}
