-- VIM OPTIONS
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.inccommand = "split"
-- vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
-- vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "> ", trail = "·", nbsp = "␣", lead = "·", eol = "¬" }
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.clipboard = "unnamedplus"
-- vim.opt.hlsearch = true

vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldenable = false

vim.o.winblend = 20
vim.o.cc = "120"
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4

vim.g.zig_fmt_autosave = false
vim.g.tex_flavor = "latex"
vim.g.netrw_liststyle = 3

-- LOCAL FUNCTIONS
local function settabspace4()
	vim.o.tabstop = 4
	vim.o.softtabstop = 4
	vim.o.shiftwidth = 4
end

local function settabspace2()
	vim.o.tabstop = 2
	vim.o.softtabstop = 2
	vim.o.shiftwidth = 2
end

-- AUTO COMMANDS (NON-LSP)
-- Make the cursorline "move" with the focused window
vim.api.nvim_create_autocmd("WinLeave", {
	pattern = { "*" },
	command = "set nocursorline",
})

vim.api.nvim_create_autocmd("WinEnter", {
	pattern = { "*" },
	command = "set cursorline",
})

-- KEYMAPS
vim.keymap.set({ "n", "i", "v" }, "fd", "<ESC>", { desc = "Exit modes" })
vim.keymap.set("n", "<leader>f", function()
	Snacks.picker.files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>/", function()
	Snacks.picker.grep()
end, { desc = "Global search" })
vim.keymap.set("n", "<leader>bf", function()
	Snacks.picker.buffers()
end, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>bd", function()
	Snacks.bufdelete()
end, { desc = "Delete buffer" })
vim.keymap.set("n", "<leader>g", function()
	Snacks.picker.git_files()
end, { desc = "Git files" })
vim.keymap.set("n", "<leader>d", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>D", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer diagnostics" })
vim.keymap.set("n", "gd", function()
	Snacks.picker.lsp_definitions()
end, { desc = "Go to definition" })
vim.keymap.set("n", "gr", function()
	Snacks.picker.lsp_references()
end, { desc = "Go to references" })
vim.keymap.set("n", "gi", function()
	Snacks.picker.lsp_implementations()
end, { desc = "Go to implementations" })
vim.keymap.set("n", "gy", function()
	Snacks.picker.lsp_type_definitions()
end, { desc = "Go to type definition" })
vim.keymap.set("n", "<leader>ss", function()
	Snacks.picker.lsp_symbols()
end, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP Rename" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>rf", function()
	Snacks.rename.rename_file()
end, { desc = "Rename file" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Window management (LazyVim style)
vim.keymap.set("n", "<C-Up>", "<CMD>resize +2<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-Down>", "<CMD>resize -2<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-Left>", "<CMD>vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-Right>", "<CMD>vertical resize +2<CR>", { desc = "Increase window width" })
vim.keymap.set("n", "<leader>-", "<CMD>split<CR>", { desc = "Split window below" })
vim.keymap.set("n", "<leader>|", "<CMD>vsplit<CR>", { desc = "Split window right" })
vim.keymap.set("n", "<leader>wd", "<CMD>close<CR>", { desc = "Delete window" })

vim.keymap.set({ "n", "i", "v" }, "<C-s>", "<CMD>w<CR>", { desc = "Save buffer" })

vim.pack.add({
	"https://github.com/catppuccin/nvim", -- catppuccin theme
	"https://github.com/stevearc/oil.nvim", -- file explorer
	"https://github.com/sebdah/vim-delve", -- Go debugging
	"https://github.com/folke/snacks.nvim", -- picker, notifications, and more
	"https://github.com/numToStr/Comment.nvim", -- 'gc' to auto comment
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/leoluz/nvim-dap-go",
	"https://github.com/MagicDuck/grug-far.nvim", -- search and replace

	"https://github.com/stevearc/conform.nvim",
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/folke/todo-comments.nvim",
})

vim.cmd("colorscheme catppuccin-mocha")

-- PLUGIN SETUP
require("snacks").setup({
	picker = { enabled = true },
	lazygit = { enabled = true },
	words = { enabled = true },
	scroll = { enabled = true },
	notifier = { enabled = true },
	indent = { enabled = true },
	git = { enabled = true },
	bufdelete = { enabled = true },
	gitbrowse = { enabled = true },
	rename = { enabled = true },
})
vim.keymap.set("n", "<leader>gg", function()
	Snacks.lazygit()
end, { desc = "Lazygit" })
vim.keymap.set("n", "<leader>gB", function()
	Snacks.gitbrowse()
end, { desc = "Open in GitHub" })
vim.keymap.set("n", "<leader>gb", function()
	Snacks.git.blame_line()
end, { desc = "Git blame line" })
require("dap-go").setup()
require("oil").setup()
vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open file explorer" })
require("Comment").setup()
require("todo-comments").setup()
vim.keymap.set("n", "<leader>st", function()
	Snacks.picker.todo_comments()
end, { desc = "Search TODOs" })

require("grug-far").setup()
vim.keymap.set("n", "<leader>sr", function()
	require("grug-far").open()
end, { desc = "Search and replace" })
vim.keymap.set("x", "<leader>sr", function()
	require("grug-far").open({ startCursorRow = 4, prefills = { search = vim.fn.expand("<cword>") } })
end, { desc = "Search and replace (word)" })
require("conform").setup({
	notify_on_error = false,
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	formatters_by_ft = {
		lua = { "stylua" },
		nix = { "nixfmt" },
		go = { "gofmt" },
		python = { "ruff_format" },
		terraform = { "terraform_fmt" },
		zig = { "zigfmt" },
		kdl = { "kdlfmt" },
		toml = { "taplo" },
		bash = { "shfmt" },
		sh = { "shfmt" },
		-- Biome for JS/TS, prettier for other web files
		javascript = { "biome" },
		typescript = { "biome" },
		javascriptreact = { "biome" },
		typescriptreact = { "biome" },
		json = { "biome" },
		css = { "prettier" },
		html = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
	},
})

-- DAP Config
local dap, dapui = require("dap"), require("dapui")
dapui.setup()
dap.listeners.before.attach.dapui_config = function()
	dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
	dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
	dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
	dapui.close()
end

-- LSP Config
vim.lsp.enable({
	"rust_analyzer",
	"gopls",
	"ty",
	"zls",
	"ruff",
	"terraformls",
	"lua_ls",
	"dockerls",
	"docker_compose_language_service",
	"yamlls",
	"marksman",
	"golangci_lint_ls",
	"nil_ls",
	"bashls",
	"taplo",
	"ts_ls",
	"jsonls",
	"html",
	"cssls",
	"eslint",
})

vim.cmd([[set completeopt=fuzzy,menuone,noinsert,popup]])

vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)
		if client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
		end
	end,
})

-- lua_ls VIM support
vim.lsp.config("lua_ls", {
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if
				path ~= vim.fn.stdpath("config")
				and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc"))
			then
				return
			end
		end

		client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
			runtime = {
				version = "LuaJIT",
				path = {
					"lua/?.lua",
					"lua/?/init.lua",
				},
			},
			workspace = {
				checkThirdParty = false,
				library = {
					vim.env.VIMRUNTIME,
				},
			},
		})
	end,
	settings = {
		Lua = {},
	},
})
