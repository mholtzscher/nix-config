{ pkgs, ... }:
let
  zitree = pkgs.pkgsCross.wasi32.callPackage ../../../pkgs/zitree { };
in
{
  programs.zellij = {
    enable = true;
  };

  # Use the KDL config file directly since home-manager's zellij module
  # doesn't properly escape attribute names with spaces in plugin configs
  xdg.configFile."zellij/config.kdl".text =
    builtins.replaceStrings [ "@zitreeWasm@" ] [ "${zitree}/lib/zellij/plugins/zitree.wasm" ]
      (builtins.readFile ../files/zellij.kdl);
}
