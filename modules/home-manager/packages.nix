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
  # atlas - Atlassian CLI
  inputs.atlas.packages.${pkgs.stdenv.hostPlatform.system}.default
  # plannotator - interactive plan review CLI
  (pkgs.callPackage ../../pkgs/plannotator { })
  # ghui - GitHub TUI
  (pkgs.callPackage ../../pkgs/ghui { })
  google-cloud-sdk
  nodejs_24
  pnpm
  lua
  zig
]
++ [
  buf
  cachix
  cookiecutter
  cruft
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
  nil
  nixfmt
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
]
++ pkgs.lib.optionals (!isWork) [
  tailscale
]
