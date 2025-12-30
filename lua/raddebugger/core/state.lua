local M = {}

M.States = {
	DISCONNECTED = "disconnected",
	IDLE = "idle",
	RUNNING = "running",
	PAUSED = "paused",
	CRASHED = "crashed",
}

local current_state = M.States.DISCONNECTED

---@param new_state string
local function set_state(new_state)
	if current_state ~= new_state then
		current_state = new_state
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "RaddebuggerStateChange",
				data = { state = new_state }
			})
		end)
	end
end

---Check if command can be executed in current state
---@param command string
---@return boolean
function M.can_execute(command)
	local s = current_state
	local S = M.States

	if command == "init" then return true end
	if s == S.DISCONNECTED then return false end

	if command == "run" or command == "continue" then
		return s == S.IDLE or s == S.PAUSED or s == S.CRASHED
	end

	if command:match("^step") then
		return s == S.PAUSED or s == S.IDLE
	end

	if command == "pause" then
		return s == S.RUNNING
	end

	if command == "kill" then
		return s ~= S.DISCONNECTED
	end

	-- Config commands usually allowed unless strictly disconnected logic
	return true
end

function M.get() return current_state end

function M.set_idle() set_state(M.States.IDLE) end

function M.set_running() set_state(M.States.RUNNING) end

function M.set_paused() set_state(M.States.PAUSED) end

function M.set_crashed() set_state(M.States.CRASHED) end

function M.set_disconnected() set_state(M.States.DISCONNECTED) end

return M
