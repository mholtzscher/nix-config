{
  pkgs,
  inputs,
  ...
}:
{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraLuaConfig = builtins.readFile ../files/neovim/init.lua;
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

      # Rust
      pkgs.rust-analyzer
      pkgs.rustfmt

      pkgs.nil
      pkgs.nixfmt
      pkgs.buf
      pkgs.bash-language-server
      pkgs.just-lsp
      pkgs.lua-language-server
      pkgs.ruff
      pkgs.kdlfmt
      pkgs.taplo # toml
      pkgs.stylua # lua formatter
      pkgs.shfmt # bash/sh formatter

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
