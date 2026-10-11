# Shared LSP servers and development tools
# Used by both Neovim and Helix configurations
{ pkgs }:
with pkgs;
[
  # Nix
  nil
  nixfmt

  # Nix extracts current VSCode servers; the npm bundle is older.
  vscode-langservers-extracted
]
