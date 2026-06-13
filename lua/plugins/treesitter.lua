return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	config = function()
		local parsers = {
			"bash",
			"c",
			"diff",
			"html",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"query",
			"vim",
			"vimdoc",
			"c_sharp",
			"rust",
		}

		local treesitter = require("nvim-treesitter")
		treesitter.setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})
		if treesitter.install then
			treesitter.install(parsers)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("treesitter-start", { clear = true }),
			callback = function(event)
				local ok = pcall(vim.treesitter.start, event.buf)
				if ok and vim.bo[event.buf].filetype ~= "ruby" and treesitter.indentexpr then
					vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
