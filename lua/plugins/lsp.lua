return {
	-- Lazydev for Lua LSP
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	-- Main LSP Configuration
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = {
					registries = {
						"github:mason-org/mason-registry",
					},
				},
			},
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			-- LSP Attach keymaps
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("<leader>se", vim.lsp.buf.code_action, "Code Action")
					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
					map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
					map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
					map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
					map("<leader>ts", function()
						require("config.diagnostics").toggle(event.buf)
					end, "[T]oggle diagnostic [S]ignal")

					local client = vim.lsp.get_client_by_id(event.data.client_id)

					-- Document highlight
					if
						client
						and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
					then
						local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})
						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- Inlay hints toggle
					if
						client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- Diagnostic Config
			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = { severity = vim.diagnostic.severity.ERROR },
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
				virtual_text = {
					source = "if_many",
					spacing = 2,
					format = function(diagnostic)
						return diagnostic.message
					end,
				},
			})

			require("config.diagnostics").setup({
				default_mode = "quiet",
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()

			local roslyn_capabilities = vim.tbl_deep_extend("force", {}, capabilities, {
				textDocument = {
					diagnostic = {
						dynamicRegistration = true,
					},
				},
			})

			vim.lsp.config("roslyn", {
				capabilities = roslyn_capabilities,
				on_attach = function(client, bufnr)
					vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
						group = vim.api.nvim_create_augroup("roslyn-refresh-diagnostics", { clear = false }),
						buffer = bufnr,
						callback = function()
							if
								(client.is_stopped and client:is_stopped())
								or not vim.api.nvim_buf_is_loaded(bufnr)
								or not client:supports_method(vim.lsp.protocol.Methods.textDocument_diagnostic, bufnr)
							then
								return
							end

							client:request(
								vim.lsp.protocol.Methods.textDocument_diagnostic,
								{ textDocument = vim.lsp.util.make_text_document_params(bufnr) },
								nil,
								bufnr
							)
						end,
						desc = "Refresh Roslyn diagnostics",
					})
				end,
				settings = {
					["csharp|background_analysis"] = {
						dotnet_analyzer_diagnostics_scope = "fullSolution",
						dotnet_compiler_diagnostics_scope = "fullSolution",
					},
					["csharp|code_lens"] = {
						dotnet_enable_references_code_lens = true,
					},
					["csharp|completion"] = {
						dotnet_provide_regex_completions = true,
						dotnet_show_completion_items_from_unimported_namespaces = true,
						dotnet_show_name_completion_suggestions = true,
					},
					["csharp|inlay_hints"] = {
						csharp_enable_inlay_hints_for_implicit_object_creation = true,
						csharp_enable_inlay_hints_for_implicit_variable_types = true,
						csharp_enable_inlay_hints_for_lambda_parameter_types = true,
						csharp_enable_inlay_hints_for_types = true,
						dotnet_enable_inlay_hints_for_indexer_parameters = true,
						dotnet_enable_inlay_hints_for_literal_parameters = true,
						dotnet_enable_inlay_hints_for_object_creation_parameters = true,
						dotnet_enable_inlay_hints_for_other_parameters = true,
						dotnet_enable_inlay_hints_for_parameters = true,
						dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
						dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
						dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
					},
					["csharp|symbol_search"] = {
						dotnet_search_reference_assemblies = true,
					},
				},
			})

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
				rust_analyzer = {},
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
					cmd = { "vue-language-server", "--stdio" },
					filetypes = { "vue" },
					root_markers = { "package.json" },
				},
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
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
				"stylua",
				"vue-language-server",
				"roslyn-language-server",
			})

			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			local configured_servers = {}
			local function setup_server(server_name)
				if configured_servers[server_name] then
					return
				end
				local server = servers[server_name]
				if not server then
					return
				end
				server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
				vim.lsp.config(server_name, server)
				vim.lsp.enable(server_name)
				configured_servers[server_name] = true
			end

			require("mason-lspconfig").setup({
				ensure_installed = {},
				automatic_enable = false,
			})

			for server_name in pairs(servers) do
				setup_server(server_name)
			end
		end,
	},

	-- Roslyn for C#
	{
		"seblyng/roslyn.nvim",
		ft = { "cs", "razor" },
		opts = {
			broad_search = true,
			lock_target = false,
		},
	},
}
