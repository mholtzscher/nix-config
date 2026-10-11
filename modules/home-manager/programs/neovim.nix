{
  pkgs,
  lib,
  isDarwin,
  ...
}:
{
  # Neovim, its writable config, plugins, and aliases are managed by Mise.
  # Retain the language servers that still use Nix packaging on the normal PATH.
  home.packages = import ../lsp-packages.nix { inherit pkgs; };
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
  catppuccin.nvim.enable = false;

  # The Mise launcher uses this stable path for CodeSnap's macOS generator.
  home.file.".local/share/nvim/nix-libs" = lib.mkIf isDarwin {
    source = "${lib.getLib pkgs.pcre2}/lib";
  };
}
