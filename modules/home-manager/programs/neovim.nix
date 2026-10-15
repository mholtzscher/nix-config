{ pkgs, ... }:
{
  # Neovim, its writable config, plugins, and aliases are managed by Mise.
  # Retain the language servers that still use Nix packaging on the normal PATH.
  home.packages = import ../lsp-packages.nix { inherit pkgs; };
  catppuccin.nvim.enable = false;
}
