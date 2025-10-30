{ pkgs }:

with pkgs;
[
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
  chezmoi
  cowsay
  discordo
  dive
  dust
  figlet
  gnused
  grpcurl
  gum
  hey
  httpie
  hugo
  jc
  just
  kdlfmt
  ko
  kubernetes-helm
  # lolcat
  nixfmt-rfc-style
  neovim
  nil
  oras
  procs
  rm-improved
  sl
  slides
  sops
  statix
  tldr
  topiary
  tree-sitter
  tree-sitter-grammars.tree-sitter-nu
  vim
  # vscode
  websocat
  wget
  yq
]
