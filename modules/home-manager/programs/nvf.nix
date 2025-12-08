{ pkgs, ... }:

{
  programs.nvf = {
    enable = true;

    settings = {
      vim = {
        # ============================================
        # Core Settings
        # ============================================
        viAlias = true;
        vimAlias = true;
        preventJunkFiles = true;
        enableLuaLoader = true;

        # Line numbers (matches your options.lua)
        lineNumberMode = "relNumber";

        # Colorcolumn at 120 (from your options.lua)
        globals = {
          mapleader = " ";
          maplocalleader = "\\";
        };

        options = {
          colorcolumn = "120";
          scrolloff = 8;
          sidescrolloff = 8;
          shiftwidth = 2;
          tabstop = 2;
          wrap = false;
          clipboard = "unnamedplus";
        };

        # ============================================
        # Theme - Catppuccin Mocha (matching your system)
        # ============================================
        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };

        # ============================================
        # Treesitter
        # ============================================
        treesitter = {
          enable = true;
          fold = true;
          context.enable = true;
          # Add grammars for languages you use
          grammars = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
            nix
            lua
            go
            gomod
            gosum
            python
            typescript
            javascript
            tsx
            json
            yaml
            toml
            dockerfile
            sql
            terraform
            hcl
            markdown
            markdown_inline
            html
            css
            bash
            nu
            kdl
            http
            graphql
            proto
            just
            zig
            java
          ];
        };

        # ============================================
        # LSP Configuration
        # ============================================
        lsp = {
          enable = true;
          formatOnSave = true;
          lightbulb.enable = true;
          lspkind.enable = true;
          trouble.enable = true;
          lspSignature.enable = true;
          lspsaga.enable = false;
        };

        # ============================================
        # Language Support (from your LazyVim extras)
        # ============================================
        languages = {
          # Core languages
          nix = {
            enable = true;
            lsp.enable = true;
            format.enable = true;
            treesitter.enable = true;
          };

          lua = {
            enable = true;
            lsp.enable = true;
            treesitter.enable = true;
          };

          go = {
            enable = true;
            lsp.enable = true;
            format.enable = true;
            treesitter.enable = true;
            dap.enable = true;
          };

          python = {
            enable = true;
            lsp.enable = true;
            format.enable = true;
            treesitter.enable = true;
            dap.enable = true;
          };

          ts = {
            enable = true;
            lsp.enable = true;
            format.enable = true;
            treesitter.enable = true;
          };

          html = {
            enable = true;
            treesitter.enable = true;
          };

          css = {
            enable = true;
            treesitter.enable = true;
          };

          markdown = {
            enable = true;
            lsp.enable = true;
            treesitter.enable = true;
          };

          sql = {
            enable = true;
            treesitter.enable = true;
            lsp.enable = true;
          };

          terraform = {
            enable = true;
            lsp.enable = true;
            treesitter.enable = true;
          };

          zig = {
            enable = true;
            lsp.enable = true;
            treesitter.enable = true;
          };

          # Additional parsers configured via extraPlugins
          bash.enable = true;
          rust.enable = false; # Enable if you need Rust
          java.enable = false; # Your config has it lazy/disabled
        };

        # ============================================
        # Autocompletion
        # ============================================
        autocomplete = {
          nvim-cmp = {
            enable = true;
            mappings = {
              confirm = "<CR>";
              next = "<Tab>";
              previous = "<S-Tab>";
              scrollDocsUp = "<C-u>";
              scrollDocsDown = "<C-d>";
            };
          };
        };

        # ============================================
        # Snippets
        # ============================================
        snippets = {
          luasnip.enable = true;
        };

        # ============================================
        # File Navigation & Search
        # ============================================
        telescope = {
          enable = true;
        };

        filetree = {
          neo-tree = {
            enable = true;
          };
        };

        # ============================================
        # Git Integration
        # ============================================
        git = {
          enable = true;
          gitsigns = {
            enable = true;
            codeActions.enable = true;
          };
        };

        # ============================================
        # UI Enhancements
        # ============================================
        statusline = {
          lualine = {
            enable = true;
            theme = "catppuccin";
          };
        };

        tabline = {
          nvimBufferline.enable = true;
        };

        visuals = {
          nvim-web-devicons.enable = true;
          indent-blankline.enable = true;
          highlight-undo.enable = true;
        };

        notify = {
          nvim-notify.enable = true;
        };

        # ============================================
        # Editing Enhancements
        # ============================================
        autopairs.nvim-autopairs.enable = true;

        comments = {
          comment-nvim.enable = true;
        };

        utility = {
          surround.enable = true;
          motion = {
            flash-nvim.enable = true;
          };
          images = {
            image-nvim.enable = false; # Can be heavy
          };
        };

        # Which-key for keybind discovery
        binds = {
          whichKey.enable = true;
        };

        # ============================================
        # Copilot (from your LazyVim extras)
        # ============================================
        assistant = {
          copilot = {
            enable = true;
            cmp.enable = true;
          };
        };

        # ============================================
        # Debugging (DAP)
        # ============================================
        debugger = {
          nvim-dap = {
            enable = true;
            ui.enable = true;
          };
        };

        # ============================================
        # Dashboard (matching your snacks dashboard)
        # ============================================
        dashboard = {
          alpha.enable = false;
          dashboard-nvim.enable = false;
        };

        # ============================================
        # Extra Plugins (your custom LazyVim plugins)
        # ============================================
        extraPlugins = with pkgs.vimPlugins; {
          # Oil.nvim - file explorer
          oil-nvim = {
            package = oil-nvim;
            setup = ''
              require('oil').setup({
                view_options = {
                  show_hidden = true,
                },
                keymaps = {
                  ["<C-s>"] = false,
                },
              })
            '';
          };

          # Mini.icons dependency for oil
          mini-icons = {
            package = mini-icons;
            setup = "require('mini.icons').setup({})";
          };

          # Snacks.nvim - utility plugins collection
          snacks-nvim = {
            package = snacks-nvim;
            setup = ''
                          require('snacks').setup({
                            dashboard = {
                              preset = {
                                header = [[
               _ __ ___   __ _| | _____   _| |_  __      _____  _ __| | __
              | '_ ` _ \ / _` | |/ / _ \ | | __| \ \ /\ / / _ \| '__| |/ /
              | | | | | | (_| |   <  __/ | | |_   \ V  V / (_) | |  |   <
              |_| |_| |_|\__,_|_|\_\___| |_|\__|   \_/\_/ \___/|_|  |_|\_\
                                ]]
                              },
                              sections = {
                                { section = "header" },
                                { section = "keys", gap = 1, padding = 1 },
                                { section = "startup" },
                              },
                            },
                          })
            '';
          };

          # Multicursor.nvim
          multicursor-nvim = {
            package = multicursor-nvim;
            setup = ''
              local mc = require("multicursor-nvim")
              mc.setup()

              local set = vim.keymap.set

              -- Add or skip cursor above/below the main cursor
              set({ "n", "x" }, "<leader>m<up>", function() mc.lineAddCursor(-1) end, { desc = "Add cursor above" })
              set({ "n", "x" }, "<leader>m<down>", function() mc.lineAddCursor(1) end, { desc = "Add cursor below" })

              -- Add or skip adding a new cursor by matching word/selection
              set({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "Add cursor to next match" })
              set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "Skip next match" })
              set({ "n", "x" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "Add cursor to prev match" })
              set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "Skip prev match" })

              -- Toggle cursor
              set({ "n", "x" }, "<c-q>", mc.toggleCursor, { desc = "Toggle cursor" })

              -- Keymap layer for multi-cursor mode
              mc.addKeymapLayer(function(layerSet)
                layerSet("n", "<esc>", function()
                  if not mc.cursorsEnabled() then
                    mc.enableCursors()
                  else
                    mc.clearCursors()
                  end
                end)
              end)

              -- Cursor highlights
              local hl = vim.api.nvim_set_hl
              hl(0, "MultiCursorCursor", { reverse = true })
              hl(0, "MultiCursorVisual", { link = "Visual" })
              hl(0, "MultiCursorSign", { link = "SignColumn" })
              hl(0, "MultiCursorMatchPreview", { link = "Search" })
              hl(0, "MultiCursorDisabledCursor", { reverse = true })
              hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
              hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
            '';
          };

          # Kulala.nvim - HTTP client
          kulala-nvim = {
            package = kulala-nvim;
            setup = ''
              require('kulala').setup({
                global_keymaps = true,
              })
            '';
          };

          # Conform.nvim - formatting
          conform-nvim = {
            package = conform-nvim;
            setup = ''
              require('conform').setup({
                formatters_by_ft = {
                  nu = { "topiary_nu" },
                  proto = { "buf" },
                  kdl = { "kdlfmt" },
                },
                formatters = {
                  topiary_nu = {
                    command = "topiary",
                    args = { "format", "--language", "nu" },
                  },
                },
              })
            '';
          };

          # nvim-lint - linting
          nvim-lint = {
            package = nvim-lint;
            setup = ''
              require('lint').linters_by_ft = {
                proto = { "buf_lint" },
              }
            '';
          };

          # nui.nvim - UI library (dependency for various plugins)
          nui-nvim = {
            package = nui-nvim;
          };
        };

        # ============================================
        # Custom Lua Configuration
        # ============================================
        luaConfigRC = {
          # Custom keymaps (from your keymaps.lua)
          customKeymaps = ''
            -- Yank to system clipboard
            vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
            vim.keymap.set("n", "<leader>Y", '"+Y', { desc = "Yank line to clipboard" })

            -- Delete without yanking
            vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yank" })

            -- Oil file browser
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

            -- Better window navigation
            vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
            vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
            vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
            vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

            -- Resize windows
            vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
            vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
            vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
            vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

            -- Move lines up/down
            vim.keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
            vim.keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
            vim.keymap.set("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
            vim.keymap.set("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

            -- Clear search highlighting
            vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

            -- Better indenting
            vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
            vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

            -- Snacks project picker
            vim.keymap.set("n", "<leader>fp", function()
              Snacks.picker.projects({
                dev = { "~/code" },
                max_depth = 3,
              })
            end, { desc = "Projects" })
          '';

          # Autocmds (from your autocmds.lua)
          customAutocmds = ''
            -- Highlight on yank
            vim.api.nvim_create_autocmd("TextYankPost", {
              callback = function()
                vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
              end,
            })

            -- Resize splits when window is resized
            vim.api.nvim_create_autocmd("VimResized", {
              callback = function()
                vim.cmd("tabdo wincmd =")
              end,
            })

            -- Go to last location when opening a buffer
            vim.api.nvim_create_autocmd("BufReadPost", {
              callback = function()
                local mark = vim.api.nvim_buf_get_mark(0, '"')
                local lcount = vim.api.nvim_buf_line_count(0)
                if mark[1] > 0 and mark[1] <= lcount then
                  pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
              end,
            })

            -- Close some filetypes with <q>
            vim.api.nvim_create_autocmd("FileType", {
              pattern = { "help", "qf", "lspinfo", "man", "notify", "startuptime", "checkhealth" },
              callback = function(event)
                vim.bo[event.buf].buflisted = false
                vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
              end,
            })

            -- Register which-key groups
            local ok, wk = pcall(require, "which-key")
            if ok then
              wk.add({
                { "<leader>m", group = "multicursor" },
                { "<leader>f", group = "file/find" },
                { "<leader>g", group = "git" },
                { "<leader>c", group = "code" },
                { "<leader>s", group = "search" },
                { "<leader>b", group = "buffer" },
                { "<leader>w", group = "window" },
                { "<leader>x", group = "diagnostics" },
              })
            end
          '';
        };
      };
    };
  };
}
