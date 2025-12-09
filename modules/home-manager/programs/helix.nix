{ pkgs, ... }:
{
  programs = {
    helix = {
      enable = true;
      extraPackages = [
        pkgs.terraform-ls
        pkgs.dockerfile-language-server-nodejs
        pkgs.docker-compose-language-service
        pkgs.yaml-language-server
        pkgs.typescript-language-server
        pkgs.marksman
        pkgs.gopls
        pkgs.golangci-lint-langserver
        pkgs.nil
        pkgs.buf
        pkgs.bash-language-server
        pkgs.just-lsp
        pkgs.lua-language-server
        pkgs.ruff
        pkgs.kdlfmt
        pkgs.taplo
        pkgs.prettier

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
    };
  };
}
