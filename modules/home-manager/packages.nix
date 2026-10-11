{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.terminal-browser
  (pkgs.callPackage ../../pkgs/vimhjkl { })
  bottom
  cachix
  codesnap
  cookiecutter
  cruft
  glow
  httpie
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  kdlfmt
  lua
  nil
  nixfmt
  nodejs_24
  pnpm
  procs
  rm-improved
  slides
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
