-- lazyCat: lazy.nvim wrapper for nixCats
-- Properly integrates lazy.nvim with Nix-installed plugins
local M = {}

local nixCatsUtils = require("nixCatsUtils")

-- Get the path to a Nix-installed plugin
-- Uses nixCats.pawsible to find plugin paths
---@param ... string path segments to plugin
---@return string|nil
local function getNixPlugin(...)
  if nixCatsUtils.isNixCats then
    return nixCats.pawsible(...)
  end
  return nil
end

-- Setup lazy.nvim with nixCats integration
---@param lazypath string|nil path to lazy.nvim (nil uses default)
---@param pluginSpec table lazy.nvim plugin specifications
---@param lazyOpts table|nil additional lazy.nvim options
function M.setup(lazypath, pluginSpec, lazyOpts)
  lazyOpts = lazyOpts or {}

  -- Determine lazy.nvim path
  if nixCatsUtils.isNixCats then
    -- Use Nix-provided lazy.nvim
    lazypath = lazypath or getNixPlugin({ "allPlugins", "start", "lazy.nvim" })
  else
    -- Bootstrap lazy.nvim for non-Nix usage
    lazypath = lazypath or vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.uv.fs_stat(lazypath) then
      vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
      })
    end
  end

  vim.opt.rtp:prepend(lazypath)

  -- Configure lazy.nvim options for nixCats
  local defaultOpts = {
    -- Use Nix lockfile path if available
    lockfile = nixCatsUtils.isNixCats and (vim.fn.stdpath("config") .. "/lazy-lock.json") or nil,

    performance = {
      reset_packpath = not nixCatsUtils.isNixCats,
      rtp = {
        reset = not nixCatsUtils.isNixCats,
      },
    },

    -- Disable git operations when using Nix (plugins managed by Nix)
    git = {
      url_format = nixCatsUtils.lazyAdd("https://github.com/%s.git", ""),
    },

    install = {
      -- Don't auto-install when using Nix
      missing = not nixCatsUtils.isNixCats,
    },

    ui = {
      -- Disable install/update buttons when using Nix
      custom_keys = nixCatsUtils.isNixCats and {} or nil,
    },
  }

  -- Merge user options
  local finalOpts = vim.tbl_deep_extend("force", defaultOpts, lazyOpts)
  finalOpts.spec = pluginSpec

  require("lazy").setup(finalOpts)
end

return M
