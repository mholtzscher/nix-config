-- nixCatsUtils: Utilities for nixCats Neovim configuration
-- Provides compatibility layer for running config with or without Nix
local M = {}

-- Check if we're running under nixCats
M.isNixCats = vim.g.nixCats ~= nil

-- Setup function for non-Nix environments
-- When running without Nix, this creates a mock nixCats global
---@param v table values to use for nixCats() calls when not using Nix
function M.setup(v)
  if not M.isNixCats then
    -- Create mock nixCats function for non-Nix usage
    local nixCats_default_value = v.non_nix_value or false
    ---@type function
    _G.nixCats = function(_)
      return nixCats_default_value
    end
  end
end

-- Helper for lazy.nvim spec values
-- Returns first value when NOT using Nix, second when using Nix
---@param v any value for non-Nix
---@param o any value for Nix (optional, defaults to false)
---@return any
function M.lazyAdd(v, o)
  if M.isNixCats then
    return o ~= nil and o or false
  else
    return v
  end
end

-- Returns false if category is disabled, true if enabled (for lazy.nvim `enabled` field)
---@param cat string|table category name(s) to check
---@return boolean
function M.enableForCategory(cat)
  if type(cat) == "table" then
    for _, c in ipairs(cat) do
      if nixCats(c) then
        return true
      end
    end
    return false
  end
  return nixCats(cat) and true or false
end

-- Returns plugin spec if category is enabled, empty table otherwise
---@param cat string category name
---@param spec table lazy.nvim plugin spec
---@return table
function M.forCategory(cat, spec)
  if M.enableForCategory(cat) then
    return spec
  end
  return {}
end

return M
