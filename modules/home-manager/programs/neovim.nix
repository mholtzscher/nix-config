{
  pkgs,
  inputs,
  ...
}:
let
  tree-sitter-txtar-grammar = pkgs.tree-sitter.buildGrammar {
    language = "txtar";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "FollowTheProcess";
      repo = "tree-sitter-txtar";
      rev = "v0.1.0";
      hash = "sha256-7ZyBeYYwonEbxjJKlOzoFqIh7zVV+JJQEHzw11WcO1E=";
    };
  };
  tree-sitter-txtar = pkgs.runCommand "nvim-treesitter-txtar" { } ''
    mkdir -p $out/parser
    mkdir -p $out/queries/txtar
    ln -s ${tree-sitter-txtar-grammar}/parser $out/parser/txtar.so
    ln -s ${tree-sitter-txtar-grammar}/queries/* $out/queries/txtar/
  '';
in
{
  programs.neovim = {
    enable = true;
    package = inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.default;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraLuaConfig = builtins.readFile ../files/neovim/init.lua;
    plugins = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
      tree-sitter-txtar
    ];
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
      pkgs.harper # grammar checker

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
