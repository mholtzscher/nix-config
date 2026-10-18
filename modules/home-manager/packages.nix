{
  pkgs,
  inputs,
  isWork ? false,
  isDarwin,
}:

with pkgs;
# Nix-managed user tools stay on Linux; Macs do not need replacements.
pkgs.lib.optionals (!isDarwin) [
  cachix
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  nil
  nixfmt
  statix
]
++ pkgs.lib.optionals (!isWork && !isDarwin) [
  tailscale
]
++ pkgs.lib.optionals (!isWork && !isDarwin) [
  bruno
]
