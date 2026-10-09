{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  ast-grep
  bottom
  cachix
  codesnap
  cookiecutter
  cruft
  dive
  doggo
  duckdb
  dust
  glow
  grpcurl
  httpie
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  jc
  just
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
  tree-sitter
  vim
  websocat
  wget
  yq
  yt-dlp
]
++ pkgs.lib.optionals (!isWork) [
  bruno
  tailscale
]
