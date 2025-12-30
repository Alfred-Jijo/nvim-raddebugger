local Path = require("raddebugger.utils.path")
local Debounce = require("raddebugger.utils.debounce")
local State = require("raddebugger.core.state")

local M = {}
M.data = { targets = {}, breakpoints = {}, path = nil }
local watcher = nil

---Parse a text-based .raddbg file
---@param content string
---@return table
local function parse_raddbg_content(content)
	-- Simplified parser for C-struct like raddbg files
	local data = { targets = {}, breakpoints = {} }

	for target in content:gmatch('target%s*=%s*"(.-)"') do
		table.insert(data.targets, target)
	end
	-- Support array syntax if raddbg uses it: targets = { "a", "b" }

	-- Extract breakpoints
	for file, line in content:gmatch('breakpoint%s*=%s*"(.-):(.-)"') do
		table.insert(data.breakpoints, { file = file, line = tonumber(line) })
	end

	return data
end

---Load project file
---@param path string
function M.load(path)
	path = Path.normalize(path)
	local f = io.open(path, "r")
	if not f then
		vim.notify("Could not open project file: " .. path, vim.log.levels.ERROR)
		return
	end

	local content = f:read("*a")
	f:close()

	M.data.path = path
	local parsed = parse_raddbg_content(content)
	M.data.targets = parsed.targets
	M.data.breakpoints = parsed.breakpoints -- Used for sync logic

	State.set_idle()
	vim.notify("RAD Debugger project loaded: " .. path, vim.log.levels.INFO)
end

---Start watching the project file
function M.start_watching()
	if not M.data.path then return end
	if watcher then M.stop_watching() end

	local on_change, _ = Debounce.create(function()
		vim.schedule(function()
			vim.notify("Project file changed, reloading...", vim.log.levels.INFO)
			M.load(M.data.path)
			-- Trigger UI refresh callbacks here if needed
		end)
	end, 500)

	watcher = vim.uv.new_fs_event()
	watcher:start(M.data.path, {}, function(err, _, _)
		if err then
			vim.notify("File watcher error: " .. err, vim.log.levels.ERROR)
		else
			on_change()
		end
	end)
end

function M.stop_watching()
	if watcher then
		watcher:stop()
		watcher:close()
		watcher = nil
	end
end

return M
