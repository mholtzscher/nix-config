{ inputs, pkgs, ... }:
let
  zellminPlugins = inputs.zellmin.packages.${pkgs.stdenv.hostPlatform.system}.zellminPlugins;
  treeminWasm = "${zellminPlugins}/treemin.wasm";
  seshminWasm = "${zellminPlugins}/seshmin.wasm";
in
{
  programs.zellij = {
    enable = true;
  };

  # Use the KDL config file directly since home-manager's zellij module
  # doesn't properly escape attribute names with spaces in plugin configs
  xdg.configFile."zellij/config.kdl".text =
    builtins.replaceStrings [ "@treeminWasm@" "@seshminWasm@" ] [ treeminWasm seshminWasm ]
      (builtins.readFile ../files/zellij.kdl);
}
