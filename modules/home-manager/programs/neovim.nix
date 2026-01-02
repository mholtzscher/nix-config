{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  # Prevent home-manager from managing ~/.config/nvim (use existing LazyVim config)
  xdg.configFile."nvim/init.lua".enable = lib.mkForce false;

  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultEditor = false; # helix is currently the default editor
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = [
      pkgs.terraform-ls
      pkgs.dockerfile-language-server
      pkgs.docker-compose-language-service
      pkgs.yaml-language-server
      pkgs.marksman

      # Go packages
      pkgs.gopls
      pkgs.golangci-lint
      pkgs.golangci-lint-langserver
      pkgs.delve

      pkgs.nil
      pkgs.nixfmt-rfc-style
      pkgs.buf
      pkgs.bash-language-server
      pkgs.just-lsp
      pkgs.lua-language-server
      pkgs.ruff
      pkgs.kdlfmt
      pkgs.taplo # toml

      # Typescript stuff
      pkgs.typescript-language-server
      pkgs.prettier
      pkgs.biome

      # All provided by the extracted package
      # vscode-css-language-server
      # vscode-eslint-language-server
      # vscode-html-language-server
      # vscode-json-language-server
      # vscode-markdown-language-server
      pkgs.vscode-langservers-extracted
    ];
  };
}
