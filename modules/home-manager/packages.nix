{
  pkgs,
  inputs,
  isWork ? false,
  isDarwin,
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
  tailscale
]
++ pkgs.lib.optionals (!isWork && !isDarwin) [
  bruno
]
