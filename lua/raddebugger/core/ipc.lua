local State = require("raddebugger.core.state")
local M = {}

local RADDGB_BIN = "raddbg"
local DEFAULT_TIMEOUT = 5000

---Check if raddbg is in path
---@return boolean
function M.validate_bin()
	return vim.fn.executable(RADDGB_BIN) == 1
end

---Execute IPC command asynchronously
---@param args table List of arguments
---@param callback function(success, output)
function M.exec(args, callback)
	if not M.validate_bin() then
		vim.schedule(function()
			vim.notify("raddbg binary not found in PATH", vim.log.levels.ERROR)
			if callback then callback(false, "Binary not found") end
		end)
		return
	end

	local cmd_args = { RADDGB_BIN, "--ipc" }
	for _, v in ipairs(args) do table.insert(cmd_args, v) end

	local completed = false

	local job = vim.system(cmd_args, { text = true }, function(obj)
		if completed then return end
		completed = true

		vim.schedule(function()
			if obj.code ~= 0 then
				local err = obj.stderr or "Unknown IPC error"
				-- Simple heuristic for state detection from stderr if useful
				if callback then callback(false, err) end
			else
				if callback then callback(true, obj.stdout) end
			end
		end)
	end)

	-- Timeout safeguard
	vim.defer_fn(function()
		if not completed then
			completed = true
			job:kill(9)
			vim.schedule(function()
				vim.notify("raddbg IPC timed out", vim.log.levels.WARN)
				if callback then callback(false, "Timeout") end
			end)
		end
	end, DEFAULT_TIMEOUT)
end

return M
