local M = {}

local DEFAULT_INTERVAL_MS = 3000
local timers = setmetatable({}, { __mode = "k" })

local function is_view_alive(view)
	return view
		and view.tabpage
		and vim.api.nvim_tabpage_is_valid(view.tabpage)
		and view.closing
		and not view.closing:check()
end

local function refresh_view(view)
	if not is_view_alive(view) or not view.is_cur_tabpage or not view:is_cur_tabpage() then
		return
	end

	local ok_diffview, diffview = pcall(require, "diffview")
	if ok_diffview and diffview and type(diffview.nore_emit) == "function" then
		pcall(diffview.nore_emit, "refresh_files")
		return
	end

	if type(view.update_files) == "function" then
		pcall(view.update_files, view)
		return
	end

	if view.panel and type(view.panel.update_entries) == "function" then
		pcall(view.panel.update_entries, view.panel, function() end)
	end
end

function M.stop(view)
	local timer = timers[view]
	if not timer then
		return
	end

	timers[view] = nil
	timer:stop()
	timer:close()
end

function M.start(view, interval_ms)
	if not is_view_alive(view) then
		return
	end

	M.stop(view)

	local timer = vim.uv.new_timer()
	timers[view] = timer

	timer:start(interval_ms or DEFAULT_INTERVAL_MS, interval_ms or DEFAULT_INTERVAL_MS, vim.schedule_wrap(function()
		if not is_view_alive(view) then
			M.stop(view)
			return
		end

		refresh_view(view)
	end))
end

return M
