{
  pkgs,
  inputs,
  isWork ? false,
}:

with pkgs;
[
  # melt - TUI for managing Nix flake inputs
  inputs.melt.packages.${pkgs.stdenv.hostPlatform.system}.default
  # difftui - A TUI diff tool (disabled: bun2nix dependency broken)
  # inputs.difftui.packages.${pkgs.stdenv.hostPlatform.system}.default
  # ugh - CLI tool for managing Nix configurations
  inputs.ugh.packages.${pkgs.stdenv.hostPlatform.system}.default
  # today - CLI tool
  inputs.today.packages.${pkgs.stdenv.hostPlatform.system}.default
  google-cloud-sdk
  nodejs_24
  lua
  zig
]
++ lib.optionals (!isWork) [

]
++ [
  buf
  cachix
  cookiecutter
  cruft
  codesnap
  diffnav
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
