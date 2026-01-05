-- VIM OPTIONS
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true -- Show line numbers (default: off)
vim.opt.relativenumber = true -- Show relative line numbers (default: off)
vim.opt.undofile = true -- Persist undo history to file (default: off)
vim.opt.updatetime = 250 -- ms before swap write and CursorHold event (default: 4000)
vim.opt.inccommand = "split" -- Live preview of :substitute in split window (default: "nosplit")
vim.opt.ignorecase = true -- Ignore case in search patterns (default: off)
vim.opt.smartcase = true -- Override ignorecase if pattern has uppercase (default: off)
vim.opt.signcolumn = "yes" -- Always show sign column (default: "auto")
vim.opt.splitright = true -- Vertical splits open to the right (default: off)
vim.opt.splitbelow = true -- Horizontal splits open below (default: off)
vim.opt.cursorline = true -- Highlight the current line (default: off)
vim.opt.scrolloff = 10 -- Min lines above/below cursor (default: 0)
vim.opt.clipboard = "unnamedplus" -- Use system clipboard for all operations (default: "")

vim.opt.foldlevel = 99 -- Start with all folds open (default: 0)
vim.opt.foldmethod = "indent" -- Use indentation for folding (default: "manual")
vim.opt.foldtext = "" -- Show first line of fold (default: "foldtext()")

vim.o.winblend = 20 -- Floating window transparency percentage (default: 0)
vim.o.expandtab = true -- Use spaces instead of tabs (default: off)
vim.o.tabstop = 2 -- Number of spaces tabs count for (default: 8)
vim.o.shiftwidth = 2 -- Size of an indent (default: 8)

vim.diagnostic.config({
	virtual_lines = { current_line = true },
})

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

vim.pack.add({
	"https://github.com/catppuccin/nvim", -- catppuccin theme
	"https://github.com/stevearc/oil.nvim", -- file explorer
	"https://github.com/sebdah/vim-delve", -- Go debugging
	"https://github.com/folke/snacks.nvim", -- picker, notifications, and more
	"https://github.com/rcarriga/nvim-dap-ui", -- DAP UI
	"https://github.com/mfussenegger/nvim-dap", -- Debug Adapter Protocol
	"https://github.com/nvim-neotest/nvim-nio", -- Required by nvim-dap-ui
	"https://github.com/leoluz/nvim-dap-go", -- Go debugging
	"https://github.com/MagicDuck/grug-far.nvim", -- search and replace
	"https://github.com/stevearc/conform.nvim", -- formatter
	"https://github.com/neovim/nvim-lspconfig", -- LSP configurations
	"https://github.com/folke/todo-comments.nvim", -- highlight TODO comments
	"https://github.com/folke/which-key.nvim", -- keybinding hints
	"https://github.com/nvim-mini/mini.icons", -- file icons
	"https://github.com/nvim-mini/mini.ai", -- better text objects
	"https://github.com/folke/flash.nvim", -- jump navigation
	{ src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("*") }, -- completion
	"https://github.com/nvim-treesitter/nvim-treesitter",
})

vim.cmd("colorscheme catppuccin-mocha")

-- PLUGIN SETUP
require("snacks").setup({
	bigfile = { enabled = true },
	bufdelete = { enabled = true },
	gh = { enabled = true },
	git = { enabled = true },
	gitbrowse = { enabled = true },
	indent = { enabled = true },
	input = { enabled = true },
	lazygit = { enabled = true },
	notifier = { enabled = true },
	picker = { enabled = true },
	rename = { enabled = true },
	scroll = { enabled = true },
	statuscolumn = { enabled = true },
	words = { enabled = true },
})

require("mini.icons").setup()
require("mini.ai").setup()
require("flash").setup()
require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<Tab>"] = { "select_next", "fallback" },
		["<S-Tab>"] = { "select_prev", "fallback" },
	},
	appearance = {
		nerd_font_variant = "mono",
	},
	completion = {
		accept = {
			auto_brackets = { enabled = true },
		},
		documentation = { auto_show = true },
	},
	cmdline = {
		enabled = true,
		keymap = { preset = "cmdline" },
	},
	sources = {
		default = { "lsp", "path", "buffer" },
	},
	signature = { enabled = true },
})
require("dap-go").setup()
require("oil").setup()
require("todo-comments").setup()
require("grug-far").setup()
require("which-key").setup({
	-- stylua: ignore
	spec = {
		-- Group names
		{ "<leader>b", group = "Buffer" },
		{ "<leader>c", group = "Code" },
		{ "<leader>f", group = "Find" },
		{ "<leader>g", group = "Git" },
		{ "<leader>s", group = "Search" },
		{ "<leader>u", group = "UI" },
		{ "<leader>w", group = "Window" },
		{ "g", group = "Goto" },
		{ "ga", group = "Calls" },
		{ "[", group = "Prev" },
		{ "]", group = "Next" },
		-- General
		{ "fd", "<ESC>", desc = "Exit modes", mode = { "n", "i", "v" } },
		{ "<C-s>", "<CMD>w<CR>", desc = "Save buffer", mode = { "n", "i", "v" } },
		-- LSP
		{ "K", vim.lsp.buf.hover, desc = "Hover documentation" },
		{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code actions" },
		{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
		{ "[d", function() vim.diagnostic.jump({ count = -1 }) end, desc = "Previous diagnostic" },
		{ "]d", function() vim.diagnostic.jump({ count = 1 }) end, desc = "Next diagnostic" },
		-- Window navigation
		{ "<C-h>", "<C-w>h", desc = "Move to left window" },
		{ "<C-j>", "<C-w>j", desc = "Move to lower window" },
		{ "<C-k>", "<C-w>k", desc = "Move to upper window" },
		{ "<C-l>", "<C-w>l", desc = "Move to right window" },
		-- Window management
		{ "<C-Up>", "<CMD>resize +2<CR>", desc = "Increase window height" },
		{ "<C-Down>", "<CMD>resize -2<CR>", desc = "Decrease window height" },
		{ "<C-Left>", "<CMD>vertical resize -2<CR>", desc = "Decrease window width" },
		{ "<C-Right>", "<CMD>vertical resize +2<CR>", desc = "Increase window width" },
		{ "<leader>-", "<CMD>split<CR>", desc = "Split window below" },
		{ "<leader>|", "<CMD>vsplit<CR>", desc = "Split window right" },
		{ "<leader>wd", "<CMD>close<CR>", desc = "Delete window" },
		-- Plugins
		{ "<leader>l", function() vim.pack.update() end, desc = "Update plugins" },
		-- Search and replace
		{ "<leader>sr", function() require("grug-far").open() end, desc = "Search and replace" },
		{ "<leader>sr", function() require("grug-far").open({ startCursorRow = 4, prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Search and replace (word)", mode = "x" },
		-- Top Pickers & Explorer
		{ "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
		{ "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
		{ "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
		{ "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
		{ "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
		{ "<leader>e", "<CMD>Oil<CR>", desc = "File Explorer (Oil)" },
		{ "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
		-- Find
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
		{ "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
		{ "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
		{ "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
		{ "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
		{ "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
		-- Git
		{ "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
		{ "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse", mode = { "n", "v" } },
		{ "<leader>gd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
		{ "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "Git Log File" },
		{ "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
		{ "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "GitHub Issues (open)" },
		{ "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "GitHub Issues (all)" },
		{ "<leader>gl", function() Snacks.picker.git_log() end, desc = "Git Log" },
		{ "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "Git Log Line" },
		{ "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "GitHub Pull Requests (open)" },
		{ "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "GitHub Pull Requests (all)" },
		{ "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
		{ "<leader>gS", function() Snacks.picker.git_stash() end, desc = "Git Stash" },
		-- Grep
		{ "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
		{ "<leader>sB", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
		{ "<leader>sg", function() Snacks.picker.grep() end, desc = "Grep" },
		{ "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },
		-- Search
		{ '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
		{ "<leader>s/", function() Snacks.picker.search_history() end, desc = "Search History" },
		{ "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
		{ "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
		{ "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
		{ "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
		{ "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, desc = "Buffer Diagnostics" },
		{ "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
		{ "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
		{ "<leader>si", function() Snacks.picker.icons() end, desc = "Icons" },
		{ "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
		{ "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
		{ "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
		{ "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
		{ "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
		{ "<leader>sp", function() Snacks.picker.lazy() end, desc = "Search for Plugin Spec" },
		{ "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
		{ "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
		{ "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Search TODOs" },
		{ "<leader>su", function() Snacks.picker.undo() end, desc = "Undo History" },
		-- LSP (Snacks)
		{ "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
		{ "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto Declaration" },
		{ "gr", function() Snacks.picker.lsp_references() end, desc = "References" },
		{ "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
		{ "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto Type Definition" },
		{ "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "Calls Incoming" },
		{ "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "Calls Outgoing" },
		{ "<leader>ss", function() Snacks.picker.lsp_symbols() end, desc = "LSP Symbols" },
		{ "<leader>sS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
		-- Other
		{ "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
		{ "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File" },
		{ "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
		{ "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
		{ "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference", mode = { "n", "t" } },
		{ "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference", mode = { "n", "t" } },
		-- Flash
		{ "s", function() require("flash").jump() end, desc = "Flash", mode = { "n", "x", "o" } },
		{ "S", function() require("flash").treesitter() end, desc = "Flash Treesitter", mode = { "n", "x", "o" } },
		{ "r", function() require("flash").remote() end, desc = "Remote Flash", mode = "o" },
		{ "R", function() require("flash").treesitter_search() end, desc = "Treesitter Search", mode = { "o", "x" } },
		{ "<c-s>", function() require("flash").toggle() end, desc = "Toggle Flash Search", mode = "c" },
	},
})
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
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

-- LSP Config
vim.lsp.enable({
	"bashls",
	"cssls",
	"docker_compose_language_service",
	"dockerls",
	"eslint",
	"golangci_lint_ls",
	"gopls",
	"html",
	"jsonls",
	"kotlin_lsp",
	"lua_ls",
	"marksman",
	"nil_ls",
	"nushell",
	"ruff",
	"rust_analyzer",
	"taplo",
	"terraformls",
	"ts_ls",
	"ty",
	"yamlls",
	"zls",
})

-- lua_ls VIM support
vim.lsp.config("lua_ls", {
	on_init = function(client)
		if client.workspace_folders then
			local path = client.workspace_folders[1].name
			if path ~= vim.fn.stdpath("config") and (vim.uv.fs_stat(path .. "/.luarc.json") or vim.uv.fs_stat(path .. "/.luarc.jsonc")) then
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
