# nixCats-based Neovim configuration with LazyVim
# Uses Nix for dependency management, Lua for configuration
#
# Key concepts:
# - categoryDefinitions: Define WHAT dependencies are available (grouped by category)
# - packageDefinitions: Define WHICH categories are enabled per-package
# - nixCats() in Lua: Check if a category is enabled
#
# Usage:
# - Add plugins to startupPlugins/optionalPlugins categories
# - Add LSPs/tools to lspsAndRuntimeDeps
# - Enable categories per-package in packageDefinitions
# - Check categories in Lua: if nixCats('categoryName') then ... end
{ inputs, ... }:
let
  utils = inputs.nixCats.utils;
in
{
  imports = [ inputs.nixCats.homeModule ];

  config.nixCats = {
    enable = true;
    packageNames = [ "nvim" ];
    luaPath = "${./nvim}";

    # Add plugin overlay for any plugins not on nixpkgs
    # Use inputs named "plugins-<name>" and they'll be available as pkgs.neovimPlugins.<name>
    addOverlays = [
      (utils.standardPluginOverlay inputs)
    ];

    # Define available dependencies grouped by category
    categoryDefinitions.replace =
      { pkgs, ... }:
      {
        # LSPs and runtime dependencies (added to PATH)
        lspsAndRuntimeDeps = {
          general = with pkgs; [
            # Core tools
            ripgrep
            fd
            git

            # Lua
            lua-language-server
            stylua

            # Nix
            nixd
            nixfmt-rfc-style
          ];

          # Additional language servers (enable via categories)
          python = with pkgs; [
            basedpyright
            ruff
          ];

          go = with pkgs; [
            gopls
            gofumpt
            gotools # goimports
          ];

          typescript = with pkgs; [
            typescript-language-server
            nodePackages.prettier
          ];

          rust = with pkgs; [
            rust-analyzer
            rustfmt
          ];

          web = with pkgs; [
            tailwindcss-language-server
            vscode-langservers-extracted # html, css, json, eslint
          ];

          yaml = with pkgs; [
            yaml-language-server
          ];

          markdown = with pkgs; [
            marksman
            markdownlint-cli2
          ];
        };

        # Plugins loaded at startup
        startupPlugins = {
          # LazyVim core + dependencies
          lazyvim = with pkgs.vimPlugins; [
            lazy-nvim
            LazyVim

            # UI
            bufferline-nvim
            lualine-nvim
            mini-icons
            noice-nvim
            nui-nvim
            nvim-notify
            nvim-web-devicons
            snacks-nvim
            which-key-nvim

            # Editor
            flash-nvim
            gitsigns-nvim
            neo-tree-nvim
            # nvim-spectre # Disabled: Rust build fails on macOS
            persistence-nvim
            todo-comments-nvim
            trouble-nvim

            # Coding
            nvim-ts-autotag
            ts-comments-nvim

            # Treesitter
            nvim-treesitter.withAllGrammars
            nvim-treesitter-textobjects

            # LSP
            nvim-lspconfig
            lazydev-nvim
            neoconf-nvim

            # Formatting
            conform-nvim

            # Completion
            blink-cmp

            # Snippets
            friendly-snippets

            # Telescope
            telescope-nvim
            telescope-fzf-native-nvim
            plenary-nvim
            dressing-nvim

            # Colorschemes
            tokyonight-nvim
            {
              plugin = catppuccin-nvim;
              name = "catppuccin";
            }
          ];

          # Additional plugins
          general = with pkgs.vimPlugins; [
            vim-sleuth # Auto-detect indentation
            nvim-surround
            {
              plugin = mini-ai;
              name = "mini.ai";
            }
            {
              plugin = mini-pairs;
              name = "mini.pairs";
            }
          ];
        };

        # Optional plugins (loaded via packadd or lazy)
        optionalPlugins = {
          debug = with pkgs.vimPlugins; [
            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
          ];

          git = with pkgs.vimPlugins; [
            lazygit-nvim
            diffview-nvim
          ];

          ai = with pkgs.vimPlugins; [
            copilot-lua
            copilot-cmp
          ];
        };

        # Environment variables
        environmentVariables = {
          general = {
            # Ensure proper locale for nvim
            LANG = "en_US.UTF-8";
          };
        };

        # Extra Lua packages
        extraLuaPackages = {
          general = [ (_: [ ]) ];
        };
      };

    # Define packages and which categories they include
    packageDefinitions.replace = {
      nvim =
        { pkgs, ... }:
        {
          settings = {
            wrapRc = true;
            aliases = [
              "vim"
              "vi"
            ];
            # Neovim appname (for separate configs)
            configDirName = "nvim";
            # Host providers
            hosts.python3.enable = false;
            hosts.node.enable = false;
          };

          # Enable categories
          categories = {
            # Core
            lazyvim = true;
            general = true;

            # LSPs - enable based on your needs
            python = true;
            go = true;
            typescript = true;
            rust = false; # Enable if needed
            web = true;
            yaml = true;
            markdown = true;

            # Optional features
            debug = false; # Enable if you want DAP
            git = true;
            ai = false; # Enable for Copilot

            # Platform detection (accessible in Lua)
            isDarwin = pkgs.stdenv.isDarwin;
            isLinux = pkgs.stdenv.isLinux;
          };

          # Extra data accessible via nixCats.extra()
          extra = {
            # Add any extra data you want to pass to Lua
          };
        };
    };
  };
}
