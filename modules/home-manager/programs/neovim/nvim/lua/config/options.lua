-- Neovim options
-- LazyVim sets sensible defaults, override here as needed

local opt = vim.opt

-- Line numbers
opt.relativenumber = true
opt.number = true

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- Line wrapping
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true

-- Behavior
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Undo
opt.undofile = true
opt.undolevels = 10000

-- Performance
opt.updatetime = 200
opt.timeoutlen = 300

-- Clipboard (use system clipboard)
opt.clipboard = "unnamedplus"
