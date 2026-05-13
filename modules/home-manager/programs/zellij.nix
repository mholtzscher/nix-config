{ pkgs, ... }:
let
  enableZitree = false;
  zitree = pkgs.pkgsCross.wasi32.callPackage ../../../pkgs/zitree { };
  zitreeWasm = if enableZitree then "${zitree}/lib/zellij/plugins/zitree.wasm" else "@zitreeWasm@";
in
{
  programs.zellij = {
    enable = true;
  };

  # Use the KDL config file directly since home-manager's zellij module
  # doesn't properly escape attribute names with spaces in plugin configs
  xdg.configFile."zellij/config.kdl".text =
    builtins.replaceStrings [ "@zitreeWasm@" ] [ zitreeWasm ]
      (builtins.readFile ../files/zellij.kdl);
}
