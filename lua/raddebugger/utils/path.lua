local M = {}

local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

---Normalize path to forward slashes and resolve symlinks
---@param path string
---@return string
function M.normalize(path)
	if not path then return "" end
	-- Resolve relative paths and standardise separators
	local expanded = vim.fn.expand(path)
	local abs = vim.fs.normalize(expanded)

	-- Handle Windows drive letters casing if needed
	if is_windows and abs:match("^%a:") then
		abs = abs:sub(1, 1):upper() .. abs:sub(2)
	end
	return abs
end

---Convert path to be relative to a base directory
---@param path string
---@param base string
---@return string
function M.to_relative(path, base)
	local n_path = M.normalize(path)
	local n_base = M.normalize(base)

	if n_path:sub(1, #n_base) == n_base then
		local rel = n_path:sub(#n_base + 2) -- +2 for slash
		return rel
	end
	return n_path
end

---Format path for raddbg IPC (e.g., file:line:col)
---@param path string
---@param line number
---@param col number?
---@return string
function M.format_for_raddbg(path, line, col)
	-- raddbg often prefers backslashes on Windows for IPC
	local p = M.normalize(path)
	if is_windows then
		p = p:gsub("/", "\\")
	end
	col = col or 1
	return string.format("%s:%d:%d", p, line, col)
end

return M
