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

-- LSP Config
vim.lsp.enable({
	"bashls",
	"cssls",
	"docker_compose_language_service",
	"dockerls",
	"emmet_language_server",
	"eslint",
	"golangci_lint_ls",
	"gopls",
	-- "harper_ls",
	"html",
	"jsonls",
	"kotlin_lsp",
	"lua_ls",
	-- "marksman",
	"nil_ls",
	"nushell",
	"oxfmt",
	"oxlint",
	"ruff",
	"rust_analyzer",
	"svelte",
	"taplo",
	"tailwindcss",
	"terraformls",
	"tsgo",
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

-- Enable native treesitter highlighting for all filetypes with available parsers
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})

-- General Plugins With No Setup
vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig", -- LSP configurations
	-- "https://github.com/esmuellert/codediff.nvim",
})

-- snacks
vim.pack.add({ "https://github.com/folke/snacks.nvim" })
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
	scratch = { enabled = true },
})

-- oil.nvim
vim.pack.add({ "https://github.com/stevearc/oil.nvim" })
require("oil").setup({
	keymaps = {
		["<C-s>"] = false, -- Disables the default preview toggle
	},
	view_options = {
		show_hidden = true,
	},
})

-- fff.nvim
vim.pack.add({ "https://github.com/dmtrKovalenko/fff.nvim" })
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == "fff.nvim" and (kind == "install" or kind == "update") then
			if not ev.data.active then vim.cmd.packadd("fff.nvim") end
			require("fff.download").download_or_build_binary()
		end
	end,
})
require("fff").setup({
	layout = {
		prompt_position = "top",
	},
})

-- catppuccin theme
vim.pack.add({ "https://github.com/catppuccin/nvim" })
vim.cmd("colorscheme catppuccin-mocha")

-- dadbod-grip.nvim
vim.pack.add({ "https://github.com/joryeugene/dadbod-grip.nvim" })
require("dadbod-grip").setup({
	picker = "snacks",
	completion = false,
})

-- codesnap.nvim
vim.pack.add({ "https://github.com/mistricky/codesnap.nvim" })
do
	local cpath = package.cpath
	require("codesnap").setup({
		show_line_number = true,
		snapshot_config = {
			code_config = {
				font_family = "Iosevka",
				breadcrumbs = {
					font_family = "Iosevka",
				},
			},
			background = {
				start = { x = 0, y = 0 },
				["end"] = { x = "max", y = "max" },
				stops = {
					{ position = 0, color = "#241b2f" },
					{ position = 0.45, color = "#5d3ea8" },
					{ position = 0.75, color = "#ff926f" },
					{ position = 1, color = "#ffe49b" },
				},
			},
		},
	})
	package.cpath = cpath
end

-- mini
vim.pack.add({
	"https://github.com/nvim-mini/mini.icons", -- file icons
	"https://github.com/nvim-mini/mini.ai", -- better text objects
})
require("mini.icons").setup()
require("mini.ai").setup()

-- flash
vim.pack.add({ "https://github.com/folke/flash.nvim" })
require("flash").setup()

-- conform
vim.pack.add({ "https://github.com/stevearc/conform.nvim" })
require("conform").setup({
	notify_on_error = true,
	format_on_save = {
		timeout_ms = 5000,
		lsp_format = "never",
	},
	formatters_by_ft = {
		bash = { "shfmt" },
		go = { "gofmt" },
		hcl = { "terraform_fmt" },
		html = { "prettier" },
		javascript = { "eslint_d" },
		javascriptreact = { "eslint_d" },
		json = { "oxfmt" },
		jsonc = { "oxfmt" },
		lua = { "stylua" },
		markdown = { "prettier_markdown" },
		nix = { "nixfmt" },
		python = { "ruff_format" },
		rust = { "rustfmt" },
		sh = { "shfmt" },
		svelte = { "prettier" },
		terraform = { "terraform_fmt" },
		typescript = { "eslint_d" },
		typescriptreact = { "eslint_d" },
		yaml = { "prettier" },
		zsh = { "shfmt" },
	},
	formatters = {
		prettier_markdown = {
			inherit = "prettier",
			append_args = { "--prose-wrap", "always" },
		},
	},
})

-- nvim-autopairs
vim.pack.add({
	"https://github.com/windwp/nvim-autopairs", -- auto pairs and HTML tag newline
	"https://github.com/windwp/nvim-ts-autotag", -- auto close HTML tags
})
require("nvim-autopairs").setup({
	map_cr = false,
})
require("nvim-ts-autotag").setup({
	opts = {
		enable_close = true,
		enable_rename = true,
		enable_close_on_slash = false,
	},
})
vim.api.nvim_create_autocmd("FileType", {
	pattern = {
		"html",
		"xml",
		"javascriptreact",
		"typescriptreact",
		"svelte",
		"vue",
		"astro",
	},
	-- Needed so autopairs <CR> indents correctly after nvim-ts-autotag splits HTML tags.
	callback = function(args) vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end,
})

-- blink.cmp
vim.pack.add({
	{ src = "https://github.com/Saghen/blink.cmp", version = vim.version.range("*") }, -- completion
	{ src = "https://github.com/Saghen/blink.compat", version = vim.version.range("2.*") }, -- blink source compatibility
})
require("blink.cmp").setup({
	keymap = {
		preset = "enter",
		["<CR>"] = {
			function(cmp)
				if cmp.is_visible() then return cmp.accept() end
				return require("nvim-autopairs").autopairs_cr()
			end,
			"fallback",
		},
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
		providers = {
			dadbod_grip = { name = "Grip SQL", module = "dadbod-grip.completion.blink" },
		},
		default = { "lsp", "path", "buffer", "dadbod_grip" },
	},
	signature = { enabled = true },
})

-- todo-comments
vim.pack.add({ "https://github.com/folke/todo-comments.nvim" })
require("todo-comments").setup()

-- gitsigns
vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup()

-- grug-far
vim.pack.add({ "https://github.com/MagicDuck/grug-far.nvim" })
require("grug-far").setup()

-- markdown-preview
vim.pack.add({
	"https://github.com/selimacerbas/live-server.nvim", -- HTTP server for markdown preview
	"https://github.com/selimacerbas/markdown-preview.nvim", -- markdown preview in browser
})
require("markdown_preview").setup({
	port = 8421,
	open_browser = true,
	debounce_ms = 300,
	mermaid_renderer = "rust",
})

-- which-key.nvim
vim.pack.add({ "https://github.com/folke/which-key.nvim" })
require("which-key").setup({
	-- stylua: ignore
		spec = {
		-- Group names
		{ "<leader>b", group = "Buffer" },
		{ "<leader>c", group = "Code" },
		{ "<leader>D", group = "Database" },
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
		{ "<leader>k", vim.lsp.buf.hover, desc = "Hover documentation" },
		{ "<leader>ca", vim.lsp.buf.code_action, desc = "Code actions" },
		{ "<leader>cr", vim.lsp.buf.rename, desc = "Rename" },
		{ "[d", function() vim.diagnostic.jump({ count = -1 }) end, desc = "Previous diagnostic" },
		{ "]d", function() vim.diagnostic.jump({ count = 1 }) end, desc = "Next diagnostic" },
		{ "<leader>cf", function() require("conform").format({ async = false, timeout_ms = 5000, lsp_format = "never" }) end, desc = "Format" },
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
		-- Markdown Preview
		{ "<leader>mp", "<CMD>MarkdownPreview<CR>", desc = "Markdown Preview" },
		{ "<leader>ms", "<CMD>MarkdownPreviewStop<CR>", desc = "Stop Preview" },
		-- CodeSnap
		{ "<leader>cx", ":CodeSnap<CR>", desc = "Copy CodeSnap to clipboard", mode = "x" },
		-- dadbod-grip.nvim
		{ "<leader>Dc", "<CMD>GripConnect<CR>", desc = "DB connect" },
		{ "<leader>DT", "<CMD>GripToggle<CR>", desc = "DB toggle workspace" },
		{ "<leader>Dg", "<CMD>Grip<CR>", desc = "DB open grid/query/file" },
		{ "<leader>Dt", "<CMD>GripTables<CR>", desc = "DB tables" },
		{ "<leader>Ds", "<CMD>GripSchema<CR>", desc = "DB schema" },
		{ "<leader>Dq", "<CMD>GripQuery<CR>", desc = "DB query pad" },
		{ "<leader>Dh", "<CMD>GripHistory<CR>", desc = "DB query history" },
		{ "<leader>DS", "<CMD>GripSave<CR>", desc = "DB save query" },
		{ "<leader>DL", "<CMD>GripLoad<CR>", desc = "DB load query" },
		{ "<leader>Dx", "<CMD>GripExplain<CR>", desc = "DB explain query" },
		{ "<leader>Dp", "<CMD>GripProfile<CR>", desc = "DB profile table" },
		{ "<leader>DP", "<CMD>GripProperties<CR>", desc = "DB table properties" },
		{ "<leader>Da", "<CMD>GripAsk<CR>", desc = "DB ask AI" },
		{ "<leader>DC", "<CMD>GripCreate<CR>", desc = "DB create table" },
		-- Search and replace
		{ "<leader>sr", function() require("grug-far").open() end, desc = "Search and replace" },
		{ "<leader>sr", function() require("grug-far").open({ startCursorRow = 4, prefills = { search = vim.fn.expand("<cword>") } }) end, desc = "Search and replace (word)", mode = "x" },
		-- Top Pickers & Explorer
		{ "<leader><space>", function() require("fff").find_files() end, desc = "FFF - Fuzzy Files" },
		{ "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
		{ "<leader>/", function() require("fff").live_grep() end, desc = "FFF - Grep" },
		{ "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
		{ "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
		{ "<leader>e", "<CMD>Oil<CR>", desc = "File Explorer (Oil)" },
		{ "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
		-- Find
		{ "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fc", function() require('fff').live_grep({ query = vim.fn.expand("<cword>") }) end, desc = 'Search current word'},
		-- { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
		{ "<leader>ff", function() require("fff").find_files() end, desc = "FFF - Fuzzy Files" },
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
		{ "<leader>dv", "<CMD>DiffviewToggle<CR>", desc = "Toggle Diffview" },
		{ "<leader>do", "<CMD>DiffviewOpen<CR>", desc = "Diffview open" },
		{ "<leader>dc", "<CMD>DiffviewClose<CR>", desc = "Diffview close" },
		{ "<leader>dh", "<CMD>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
		{ "<leader>dH", "<CMD>DiffviewFileHistory<CR>", desc = "File history (repo)" },
		{ "<leader>dl", "<CMD>.DiffviewFileHistory --follow<CR>", desc = "Line history" },
		{ "<leader>dh", "<Esc><CMD>'<,'>DiffviewFileHistory --follow<CR>", desc = "Range history", mode = "x" },
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
		{ "<leader>bs", function() Snacks.scratch() end, desc = "Scratch Buffer" },
		{ "<leader>bS", function() Snacks.scratch.select() end, desc = "Scratch Select" },
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

-- DAP Config
vim.pack.add({
	"https://github.com/sebdah/vim-delve", -- Go debugging
	"https://github.com/rcarriga/nvim-dap-ui", -- DAP UI
	"https://github.com/mfussenegger/nvim-dap", -- Debug Adapter Protocol
	"https://github.com/nvim-neotest/nvim-nio", -- Required by nvim-dap-ui
	"https://github.com/leoluz/nvim-dap-go", -- Go debugging
})
require("dap-go").setup()
local dap, dapui = require("dap"), require("dapui")
dapui.setup()
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end
