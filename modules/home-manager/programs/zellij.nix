{ ... }:
let
  enableTreemin = true;
  enableSeshmin = true;
  treeminWasm = if enableTreemin then "${../../../pkgs/treemin/treemin.wasm}" else "@treeminWasm@";
  seshminWasm = if enableSeshmin then "${../../../pkgs/seshmin/seshmin.wasm}" else "@seshminWasm@";

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
