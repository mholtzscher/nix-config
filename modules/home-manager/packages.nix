{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  (pkgs.callPackage ../../pkgs/plannotator { })
  (pkgs.callPackage ../../pkgs/vimhjkl { })
  ast-grep
  bottom
  buf
  cachix
  codesnap
  cookiecutter
  cruft
  devenv
  dive
  dust
  glow
  google-cloud-sdk
  grpcurl
  gum
  hey
  httpie
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
  tailscale
]
