{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.plannotator
  (pkgs.callPackage ../../pkgs/vimhjkl { })
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
  inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  inputs.sem.packages.${pkgs.stdenv.hostPlatform.system}.default
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
  (pkgs.callPackage ../../pkgs/railway-cli { })
  bruno
  (pkgs.callPackage ../../pkgs/otel-desktop-viewer { })
  tailscale
]
