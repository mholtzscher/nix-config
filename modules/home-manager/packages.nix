{ pkgs, inputs }:

with pkgs;
[
  # bd (beads) - AI-supervised issue tracker
  inputs.beads.packages.${pkgs.system}.default

  nodejs_24
  lua
  bun
  zig
  # python3
  # python313Packages.python-lsp-server
  # python313Packages.python-lsp-ruff
  # python313Packages.python-lsp-ruff
  # terraform
]
++ [
  # asdf-vm # really out of date
  #awscli2
  buf
  dive
  dust
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
