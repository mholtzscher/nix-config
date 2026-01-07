{ pkgs, inputs }:

with pkgs;
[
  # melt - TUI for managing Nix flake inputs
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  # difftui - A TUI diff tool
  inputs.difftui.packages.${pkgs.stdenv.hostPlatform.system}.default
  google-cloud-sdk
  nodejs_24
  lua
  bun
  zig
]
++ [
  buf
  cachix
  codesnap
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
  nixfmt
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
