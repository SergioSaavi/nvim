return {
	-- Git signs + branch info
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "│" },
				change = { text = "│" },
				delete = { text = "󰍵" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = function(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
				end
				-- Navigation
				map("n", "]h", gs.next_hunk, "Next git hunk")
				map("n", "[h", gs.prev_hunk, "Previous git hunk")
				-- Actions
				map("n", "<leader>gp", gs.preview_hunk, "[G]it [P]review hunk")
				map("n", "<leader>gb", gs.blame_line, "[G]it [B]lame line")
				map("n", "<leader>gr", gs.reset_hunk, "[G]it [R]eset hunk")
				map("n", "<leader>gR", gs.reset_buffer, "[G]it [R]eset buffer")
			end,
		},
	},

	-- Indent guides
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		opts = {
			indent = {
				char = "│",
				tab_char = "│",
			},
			scope = {
				enabled = true,
				show_start = true,
				show_end = false,
			},
		},
	},

	-- Mini.nvim collection
	{
		'echasnovski/mini.nvim',
		config = function()
			require('mini.ai').setup { n_lines = 500 }
			require('mini.surround').setup()

			local statusline = require 'mini.statusline'
			statusline.setup { use_icons = vim.g.have_nerd_font }
			statusline.section_location = function()
				return '%2l:%-2v'
			end
		end,
	},

	-- Oil file explorer
	{
		'stevearc/oil.nvim',
		opts = {
			constrain_cursor = "editable",
			view_options = {
				show_hidden = true,
			},
		},
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		lazy = false,
	},

	-- Which-key
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},

	-- Showkeys
	{ "nvzone/showkeys", cmd = "ShowkeysToggle" },

	-- Typst preview
	{
		'chomosuke/typst-preview.nvim',
		lazy = false,
		version = '1.*',
		opts = {},
	},
}

