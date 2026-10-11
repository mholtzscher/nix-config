{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.terminal-browser
  (pkgs.callPackage ../../pkgs/vimhjkl { })
  cachix
  codesnap
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  nil
  nixfmt
  statix
  vim
  wget
  yq
  yt-dlp
]
++ pkgs.lib.optionals (!isWork) [
  bruno
  (pkgs.callPackage ../../pkgs/otel-desktop-viewer { })
  tailscale
]
