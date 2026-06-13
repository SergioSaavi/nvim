local M = {}

local defaults = {
	default_mode = "quiet",
}

local state = {
	opts = vim.deepcopy(defaults),
	wrapped = false,
	original_handlers = {},
	buffer_modes = {},
}

local inline_handlers = {
	"virtual_text",
	"virtual_lines",
}

local function namespace_name(namespace)
	local ok, namespace_info = pcall(vim.diagnostic.get_namespace, namespace)
	if not ok or not namespace_info then
		return ""
	end

	return namespace_info.name or ""
end

local function normalize_message(message)
	return tostring(message or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local function diagnostic_code(diagnostic)
	if diagnostic.code == nil then
		return ""
	end

	return tostring(diagnostic.code)
end

local function diagnostic_key(diagnostic)
	return table.concat({
		diagnostic.lnum or -1,
		diagnostic.col or -1,
		diagnostic.end_lnum or -1,
		diagnostic.end_col or -1,
		diagnostic.severity or -1,
		diagnostic_code(diagnostic),
		normalize_message(diagnostic.message),
	}, "\31")
end

local function is_compiler_diagnostic(diagnostic)
	return diagnostic_code(diagnostic):match("^CS%d+") ~= nil
end

local function is_aggregate_namespace(namespace)
	local name = namespace_name(namespace)
	return name == "" or name == "nil" or name:match("%.nil$") ~= nil or name:find("%.nil%.", 1, true) ~= nil
end

local function is_guidance_diagnostic(namespace, diagnostic)
	if diagnostic.severity == vim.diagnostic.severity.INFO or diagnostic.severity == vim.diagnostic.severity.HINT then
		return true
	end

	local code = diagnostic_code(diagnostic)
	if code:match("^IDE%d+") or code:match("^CA%d+") then
		return true
	end

	local name = namespace_name(namespace)
	return not is_compiler_diagnostic(diagnostic) and name:find("Analyzer", 1, true) ~= nil
end

local function specific_diagnostic_keys(bufnr)
	local keys = {}

	for namespace in pairs(vim.diagnostic.get_namespaces()) do
		if not is_aggregate_namespace(namespace) then
			for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { namespace = namespace })) do
				keys[diagnostic_key(diagnostic)] = true
			end
		end
	end

	return keys
end

function M.mode(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	return state.buffer_modes[bufnr] or state.opts.default_mode
end

function M.filter(namespace, bufnr, diagnostics, _handler_name)
	local mode = M.mode(bufnr)
	local filtered = {}
	local aggregate = is_aggregate_namespace(namespace)
	local specific_keys = aggregate and specific_diagnostic_keys(bufnr) or {}

	for _, diagnostic in ipairs(diagnostics or {}) do
		local duplicate_aggregate = aggregate and specific_keys[diagnostic_key(diagnostic)]
		local quiet_guidance = mode == "quiet" and is_guidance_diagnostic(namespace, diagnostic)

		if not duplicate_aggregate and not quiet_guidance then
			table.insert(filtered, diagnostic)
		end
	end

	return filtered
end

local function refresh_buffer(bufnr)
	for namespace in pairs(vim.diagnostic.get_namespaces()) do
		vim.diagnostic.show(namespace, bufnr)
	end
end

function M.toggle(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local next_mode = M.mode(bufnr) == "quiet" and "verbose" or "quiet"
	state.buffer_modes[bufnr] = next_mode
	refresh_buffer(bufnr)
	vim.notify("Diagnostic inline mode: " .. next_mode, vim.log.levels.INFO)

	return next_mode
end

function M.setup(opts)
	state.opts = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

	if state.wrapped then
		return
	end

	for _, handler_name in ipairs(inline_handlers) do
		local original = vim.diagnostic.handlers[handler_name]
		if original then
			state.original_handlers[handler_name] = original
			vim.diagnostic.handlers[handler_name] = {
				show = function(namespace, bufnr, diagnostics, handler_opts)
					local filtered = M.filter(namespace, bufnr, diagnostics, handler_name)
					original.show(namespace, bufnr, filtered, handler_opts)
				end,
				hide = original.hide and function(namespace, bufnr)
					original.hide(namespace, bufnr)
				end or nil,
			}
		end
	end

	state.wrapped = true
end

return M
