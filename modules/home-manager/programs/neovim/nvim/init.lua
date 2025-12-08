-- Neovim configuration with nixCats + LazyVim
-- Entry point for Neovim initialization

-- Setup nixCatsUtils (provides compatibility for non-Nix usage)
require("nixCatsUtils").setup({
  non_nix_value = true,
})

-- Bootstrap and configure lazy.nvim with LazyVim
require("nixCatsUtils.lazyCat").setup(
  -- Path to lazy.nvim (nil = auto-detect based on Nix/non-Nix)
  nixCats.pawsible({ "allPlugins", "start", "lazy.nvim" }),
  -- Plugin specifications
  {
    -- LazyVim base distribution
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = "catppuccin",
      },
    },

    -- Disable Mason (Nix handles LSP/tool installation)
    {
      "williamboman/mason.nvim",
      enabled = require("nixCatsUtils").lazyAdd(true, false),
    },
    {
      "williamboman/mason-lspconfig.nvim",
      enabled = require("nixCatsUtils").lazyAdd(true, false),
    },

    -- Treesitter: disable auto_install on Nix (grammars from Nix)
    {
      "nvim-treesitter/nvim-treesitter",
      build = require("nixCatsUtils").lazyAdd(":TSUpdate", false),
      opts = {
        ensure_installed = require("nixCatsUtils").lazyAdd({
          "bash",
          "c",
          "diff",
          "html",
          "javascript",
          "jsdoc",
          "json",
          "jsonc",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "nix",
          "printf",
          "python",
          "query",
          "regex",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "xml",
          "yaml",
        }, {}),
        auto_install = require("nixCatsUtils").lazyAdd(true, false),
      },
    },

    -- Import custom plugins
    { import = "plugins" },
  },
  -- Lazy.nvim options
  {
    defaults = {
      lazy = false,
      version = false, -- Use latest commit
    },
    checker = {
      enabled = not require("nixCatsUtils").isNixCats, -- Disable update checker on Nix
    },
    change_detection = {
      notify = false, -- Don't notify on config changes
    },
  }
)
