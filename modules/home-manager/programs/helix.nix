{ pkgs, ... }:
{
  programs = {
    helix = {
      enable = true;
      extraPackages = [
        pkgs.terraform-ls
        pkgs.dockerfile-language-server
        pkgs.docker-compose-language-service
        pkgs.yaml-language-server
        pkgs.marksman
        pkgs.kotlin-language-server

        # Go packages
        pkgs.gopls
        pkgs.golangci-lint-langserver
        pkgs.delve

        pkgs.nil
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
        # pkgs.biome

        # All provided by the extracted package
        # vscode-css-language-server
        # vscode-eslint-language-server
        # vscode-html-language-server
        # vscode-json-language-server
        # vscode-markdown-language-server
        pkgs.vscode-langservers-extracted
      ];
      settings = {
        # Theme is managed by catppuccin
        editor = {
          line-number = "relative";
          lsp.display-messages = true;
          cursor-shape = {
            insert = "bar";
          };
        };
        keys.normal = {
          space.space = "file_picker";
          space.w = ":w";
          space.q = ":q";
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];
        };
      };
      languages = {
        language = [
          {
            name = "json";
            formatter = {
              command = "${pkgs.prettier}/bin/prettier";
              args = [ "--parser" "json" ];
            };
          }
        ];
      };
    };
  };
}
