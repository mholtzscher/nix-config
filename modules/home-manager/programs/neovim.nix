{
  pkgs,
  inputs,
  ...
}:
let
  # Shared LSP packages used by multiple editors
  lspPackages = import ../lsp-packages.nix { inherit pkgs; };

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
    initLua = builtins.readFile ../files/neovim/init.lua;
    plugins = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
      tree-sitter-txtar
    ];
    extraPackages = lspPackages ++ [
      # Neovim-specific extras (not needed by Helix)
      pkgs.rust-analyzer
      pkgs.rustfmt
      pkgs.stylua # lua formatter
      pkgs.shfmt # bash/sh formatter
      # pkgs.harper # grammar checker
    ];
  };
}
