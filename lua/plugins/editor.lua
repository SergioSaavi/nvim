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

	-- Diff view for reviewing repo changes in one tab
	{
		"dlyongemallo/diffview.nvim",
		cmd = {
			"DiffviewOpen",
			"DiffviewClose",
			"DiffviewFileHistory",
			"DiffviewFocusFiles",
			"DiffviewToggleFiles",
		},
		init = function()
			pcall(vim.api.nvim_del_user_command, "DiffviewRecover")
			vim.api.nvim_create_user_command("DiffviewRecover", function()
				require("config.diffview_recover").recover()
			end, { desc = "Recover stale Diffview, buffer, and LSP state" })

			vim.keymap.set("n", "<leader>gF", "<cmd>DiffviewRecover<CR>", {
				desc = "[G]it [F]ix stale review state",
			})
		end,
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "[G]it [D]iff view" },
			{ "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "[G]it [D]iff view close" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "[G]it file [H]istory" },
		},
		opts = function()
			local actions = require("diffview.actions")
			local autorefresh = require("config.diffview_autorefresh")

			return {
				view = {
					default = {
						layout = "diff2_horizontal",
					},
					file_history = {
						layout = "diff2_horizontal",
					},
					cycle_layouts = {
						default = { "diff2_horizontal", "diff2_vertical", "diff1_plain" },
					},
				},
				hooks = {
					view_opened = function(view)
						autorefresh.start(view, 3000)
					end,
					view_closed = function(view)
						autorefresh.stop(view)
					end,
				},
				keymaps = {
					view = {
						{ "n", "<leader>gz", actions.set_layout("diff1_plain"), { desc = "[G]it one-pane view" } },
					},
					file_panel = {
						{ "n", "<leader>gz", actions.set_layout("diff1_plain"), { desc = "[G]it one-pane view" } },
					},
					file_history_panel = {
						{ "n", "<leader>gz", actions.set_layout("diff1_plain"), { desc = "[G]it one-pane view" } },
					},
				},
			}
		end,
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
