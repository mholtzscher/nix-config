# Neovim
{ config, lib, ... }:
let
  cfg = config.myFeatures.neovim;
in
{
  options.myFeatures.neovim = {
    enable = lib.mkEnableOption "neovim configuration" // {
      default = true;
      description = "Enable neovim";
    };
  };

  config = lib.mkIf cfg.enable {
    flake.modules.homeManager.neovim =
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
          initLua = builtins.readFile ../../modules-legacy/home-manager/files/neovim/init.lua;
          plugins = [
            pkgs.vimPlugins.nvim-treesitter.withAllGrammars
            tree-sitter-txtar
          ];
          extraPackages = [
            pkgs.terraform-ls
            pkgs.dockerfile-language-server
            pkgs.docker-compose-language-service
            pkgs.yaml-language-server

            # Go
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
            pkgs.taplo
            pkgs.stylua
            pkgs.shfmt
            pkgs.harper

            # Typescript
            pkgs.typescript-language-server
            pkgs.prettier
            pkgs.biome

            pkgs.vscode-langservers-extracted
          ];
        };
      };
  };
}
