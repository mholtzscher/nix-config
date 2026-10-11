{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  cachix
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  nil
  nixfmt
  statix
]
++ pkgs.lib.optionals (!isWork) [
  bruno
  tailscale
]
