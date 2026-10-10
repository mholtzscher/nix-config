{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  cachix
  # Retain FFprobe for Yazi while FFmpeg's Mise version remains pinned.
  ffmpeg-headless
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  kdlfmt
  nil
  nixfmt
  statix
  vim
]
++ pkgs.lib.optionals (!isWork) [
  bruno
  tailscale
]
