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
  lua
  nil
  nixfmt
  nodejs_24
  sqlite
  statix
  vim
  wget
  yq
  yt-dlp
]
++ pkgs.lib.optionals (!isWork) [
  (pkgs.callPackage ../../pkgs/railway-cli { })
  bruno
  (pkgs.callPackage ../../pkgs/otel-desktop-viewer { })
  tailscale
]
