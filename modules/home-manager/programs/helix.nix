{ pkgs, ... }:
{
  programs = {
    helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = [
        pkgs.terraform-ls
        pkgs.dockerfile-language-server
        pkgs.docker-compose-language-service
        pkgs.yaml-language-server
        pkgs.marksman
        pkgs.kotlin-language-server

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
      settings = {
        # Theme is managed by catppuccin
        editor = {
          line-number = "relative";
          scrolloff = 10;
          text-width = 120;
          bufferline = "multiple";
          completion-trigger-len = 1;
          auto-format = true;

          end-of-line-diagnostics = "hint";
          inline-diagnostics = {
            cursor-line = "hint";
            other-lines = "disable";
          };

          cursor-shape = {
            insert = "bar";
            select = "underline";
          };

          auto-save = {
            focus-lost = true;
          };

          file-picker = {
            hidden = false;
          };
        };
        keys.normal = {
          H = "goto_previous_buffer";
          L = "goto_next_buffer";
          space.space = "file_picker";
          space.w = ":w";
          space.q = ":q";
          space.l = ":reload-all";
          A-g = [
            ":write-all"
            ":insert-output lazygit >/dev/tty"
            ":redraw"
            ":reload-all"
          ];
          A-y = [
            ":sh rm -f /tmp/unique-file-h21a434"
            ":insert-output yazi '%{buffer_name}' --chooser-file=/tmp/unique-file-h21a434"
            ":insert-output echo \"x1b[?1049h\" > /dev/tty"
            ":open %sh{cat /tmp/unique-file-h21a434}"
            ":redraw"
          ];
          A-w = [
            ":buffer-close"
          ];
          # esc = [
          #   "collapse_selection"
          #   "keep_primary_selection"
          # ];
        };
      };
      languages = {
        language = [
          {
            name = "nix";
            auto-format = true;
          }
          {
            name = "nu";
            auto-format = true;
            formatter = {
              command = "topiary";
              args = [
                "format"
                "--language"
                "nu"
              ];
            };
          }
        ];
      };
    };
  };
}
