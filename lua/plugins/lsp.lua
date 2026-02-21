return {
	-- Lazydev for Lua LSP
	{
		'folke/lazydev.nvim',
		ft = 'lua',
		opts = {
			library = {
				{ path = '${3rd}/luv/library', words = { 'vim%.uv' } },
			},
		},
	},

	-- Main LSP Configuration
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			{
				'mason-org/mason.nvim',
				opts = {
					registries = {
						"github:mason-org/mason-registry",
						"github:Crashdummyy/mason-registry",
					},
				},
			},
			'mason-org/mason-lspconfig.nvim',
			'WhoIsSethDaniel/mason-tool-installer.nvim',
			{ 'j-hui/fidget.nvim', opts = {} },
			'saghen/blink.cmp',
		},
		config = function()
			-- Block omnisharp - we use roslyn.nvim
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('block-omnisharp', { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.name == 'omnisharp' then
						vim.lsp.stop_client(client.id, true)
					end
				end,
			})

			-- LSP Attach keymaps
			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or 'n'
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
					end

					map("<leader>se", vim.lsp.buf.code_action, "Code Action")
					map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
					map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
					map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
					map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
					map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
					map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
					map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
					map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
					map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

					local client = vim.lsp.get_client_by_id(event.data.client_id)

					-- Document highlight
					if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
						local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
						vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})
						vim.api.nvim_create_autocmd('LspDetach', {
							group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
							end,
						})
					end

					-- Inlay hints toggle
					if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
						map('<leader>th', function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
						end, '[T]oggle Inlay [H]ints')
					end
				end,
			})

			-- Diagnostic Config
			vim.diagnostic.config {
				severity_sort = true,
				float = { border = 'rounded', source = 'if_many' },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = '󰅚 ',
						[vim.diagnostic.severity.WARN] = '󰀪 ',
						[vim.diagnostic.severity.INFO] = '󰋽 ',
						[vim.diagnostic.severity.HINT] = '󰌶 ',
					},
				} or {},
				virtual_text = {
					source = 'if_many',
					spacing = 2,
					format = function(diagnostic)
						return diagnostic.message
					end,
				},
			}

			local capabilities = require('blink.cmp').get_lsp_capabilities()

			-- Vue + TypeScript support (modern vue_ls + vtsls setup)
			local vue_language_server_path = vim.fn.stdpath("data")
				.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

			local vue_plugin = {
				name = "@vue/typescript-plugin",
				location = vue_language_server_path,
				languages = { "vue" },
				configNamespace = "typescript",
				enableForWorkspaceTypeScriptVersions = true,
			}

			local servers = {
				gopls = {},
				tinymist = {},
				vtsls = {
					filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
					init_options = {
						plugins = {
							vue_plugin,
						},
					},
					settings = {
						vtsls = {
							tsserver = {
								globalPlugins = {
									vue_plugin,
								},
							},
						},
					},
				},
				vue_ls = {
					cmd = { 'vue-language-server', '--stdio' },
					filetypes = { 'vue' },
					root_markers = { 'package.json' },
				},
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = 'Replace' },
						},
					},
				},
			}

			local ensure_installed = vim.tbl_keys(servers or {})

			for i, name in ipairs(ensure_installed) do
				if name == "vue_ls" then
					table.remove(ensure_installed, i)
					break
				end
			end

			vim.list_extend(ensure_installed, {
				'stylua',
				'vue-language-server',
				'roslyn',
			})

			require('mason-tool-installer').setup { ensure_installed = ensure_installed }

			local configured_servers = {}
			local function setup_server(server_name)
				if configured_servers[server_name] then return end
				if server_name == "omnisharp" then return end
				local server = servers[server_name]
				if not server then return end
				server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
				vim.lsp.config(server_name, server)
				vim.lsp.enable(server_name)
				configured_servers[server_name] = true
			end

			require('mason-lspconfig').setup {
				ensure_installed = {},
				automatic_installation = false,
				handlers = {
					function(server_name)
						setup_server(server_name)
					end,
				},
			}

			-- Ensure Vue pair is always configured even if mason-lspconfig handler misses them.
			setup_server("vtsls")
			setup_server("vue_ls")

		end,
	},

	-- Roslyn for C#
	{
		'seblyng/roslyn.nvim',
		ft = { 'cs' },
		opts = {
			broad_search = true,
			lock_target = false,
		},
	},
}

