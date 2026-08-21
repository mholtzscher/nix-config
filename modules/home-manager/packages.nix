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
  buf
  cachix
  codesnap
  cookiecutter
  cruft
  dive
  doggo
  duckdb
  dust
  glow
  google-cloud-sdk
  grpcurl
  gum
  hey
  httpie
  inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  inputs.sem.packages.${pkgs.stdenv.hostPlatform.system}.default
  inputs.today.packages.${pkgs.stdenv.hostPlatform.system}.default
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
  statix
  tldr
  topiary
  tree-sitter
  tree-sitter-grammars.tree-sitter-nu
  vim
  websocat
  wget
  yq
  yt-dlp
  zig
]
++ pkgs.lib.optionals (!isWork) [
  (pkgs.callPackage ../../pkgs/railway-cli { })
  bruno
  (pkgs.callPackage ../../pkgs/otel-desktop-viewer { })
  tailscale
]
