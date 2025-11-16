{ pkgs, inputs }:

with pkgs;
[
  # bd (beads) - AI-supervised issue tracker
  # inputs.beads.packages.${pkgs.stdenv.hostPlatform.system}.default

  nodejs_24
  lua
  bun
  zig
]
++ [
  buf
  dive
  dust
  glow
  gnused
  grpcurl
  gum
  hey
  httpie
  jc
  just
  kdlfmt
  ko
  kubernetes-helm
  nixfmt-rfc-style
  neovim
  nil
  oras
  procs
  rm-improved
  slides
  sops
  statix
  tldr
  topiary
  tree-sitter
  tree-sitter-grammars.tree-sitter-nu
  vim
  websocat
  wget
  yq
]
