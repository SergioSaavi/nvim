-- Keymaps
vim.keymap.set('i', 'jk', '<Esc>', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Open Oil file explorer" })
vim.keymap.set("n", "<leader>O", function()
	require("oil").toggle_float()
end, { desc = "Toggle Oil floating view" })

-- Diagnostics
vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float, { desc = "[D]iagnostic [D]etails (float)" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous [D]iagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next [D]iagnostic" })
vim.keymap.set("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "[D]iagnostics to [Q]uickfix" })

-- LSP Info
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover info (type/methods)" })
vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover, { desc = "Hover info (type/methods)" })
vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, { desc = "[L]SP [S]ignature help" })
