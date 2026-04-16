local M = {}

local function is_real_file_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
		return false
	end

	if vim.bo[bufnr].buftype ~= "" then
		return false
	end

	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" or name:match("^diffview://") then
		return false
	end

	return true
end

local function capture_diffview_session()
	local ok_lib, lib = pcall(require, "diffview.lib")
	if not ok_lib then
		return nil
	end

	local view = lib.get_current_view()
	if not view then
		return nil
	end

	local session = {
		label = "Diffview",
		reopen = nil,
	}

	local ok_diff, diff_mod = pcall(require, "diffview.scene.views.diff.diff_view")
	if ok_diff and view:instanceof(diff_mod.DiffView) then
		local args = {}

		if view.rev_arg and view.rev_arg ~= "" then
			table.insert(args, view.rev_arg)
		end

		if view.path_args and #view.path_args > 0 then
			table.insert(args, "--")
			vim.list_extend(args, vim.deepcopy(view.path_args))
		end

		session.reopen = function()
			require("diffview").open(args)
		end

		return session
	end

	local ok_fh, fh_mod = pcall(require, "diffview.scene.views.file_history.file_history_view")
	if ok_fh and view:instanceof(fh_mod.FileHistoryView) then
		session.label = "Diffview file history"

		local log_options = view.panel and view.panel.get_log_options and view.panel:get_log_options() or nil
		local path_args = log_options and log_options.path_args or nil

		if view.panel and view.panel.single_file and path_args and #path_args > 0 then
			local args = vim.deepcopy(path_args)

			if log_options.rev_range and log_options.rev_range ~= "" then
				table.insert(args, 1, "--range=" .. log_options.rev_range)
			end

			session.reopen = function()
				require("diffview").file_history(nil, args)
			end
		end

		return session
	end

	return session
end

local function close_diffview_session(session)
	if not session then
		return
	end

	local ok, diffview = pcall(require, "diffview")
	if ok then
		diffview.close()
	end
end

local function refresh_buffers()
	local stats = {
		reloaded = 0,
		skipped_modified = 0,
	}

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if is_real_file_buffer(bufnr) then
			if vim.bo[bufnr].modified then
				stats.skipped_modified = stats.skipped_modified + 1
			else
				pcall(vim.api.nvim_buf_call, bufnr, function()
					vim.cmd("silent! checktime")
				end)
				vim.diagnostic.reset(nil, bufnr)
				stats.reloaded = stats.reloaded + 1
			end
		end
	end

	return stats
end

local function restart_lsp_clients()
	local client_count = #vim.lsp.get_clients()

	if client_count > 0 then
		pcall(vim.cmd, "silent! LspRestart")
	end

	return client_count
end

function M.recover()
	local session = capture_diffview_session()

	close_diffview_session(session)

	local buffer_stats = refresh_buffers()
	local lsp_count = restart_lsp_clients()

	vim.defer_fn(function()
		if session and session.reopen then
			session.reopen()
		end

		vim.cmd("redraw!")

		local parts = {
			string.format("reloaded %d buffer(s)", buffer_stats.reloaded),
			string.format("skipped %d modified buffer(s)", buffer_stats.skipped_modified),
			string.format("restarted %d LSP client(s)", lsp_count),
		}

		if session then
			if session.reopen then
				table.insert(parts, "rebuilt " .. session.label)
			else
				table.insert(parts, "closed " .. session.label)
			end
		end

		vim.notify("Recovery complete: " .. table.concat(parts, ", "), vim.log.levels.INFO)
	end, session and session.reopen and 200 or 0)
end

return M
