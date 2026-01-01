local IPC = require("raddebugger.core.ipc")
local State = require("raddebugger.core.state")
local Path = require("raddebugger.utils.path")
local M = {}

-- Helper to send simple IPC commands
local function cmd(action, args)
	if not State.can_execute(action) then
		vim.notify("Cannot execute '" .. action .. "' in state: " .. State.get(), vim.log.levels.WARN)
		return
	end

	local ipc_args = { action }
	if args then
		for _, v in ipairs(args) do table.insert(ipc_args, v) end
	end

	IPC.exec(ipc_args, function(ok, msg)
		if not ok then
			vim.notify("Command failed: " .. msg, vim.log.levels.ERROR)
		else
			-- Speculative state updates for smoother UI
			if action == "run" or action == "continue" then State.set_running() end
			if action == "pause" then State.set_paused() end
			if action == "kill_all" then State.set_idle() end
			if action:match("^step") then State.set_paused() end
		end
	end)
end

---Launch the RadDebugger GUI Process
---@param path string|nil Path to executable or .raddbg project
function M.launch_gui(path)
	local exe = vim.fn.exepath("raddbg")
	if exe == "" then
		vim.notify("Critical Error: 'raddbg' not found in PATH.", vim.log.levels.ERROR)
		return
	end

	-- Build the command using the absolute path
	local cmd_args = { exe }

	if path and path ~= "" then
		local norm_path = Path.normalize(path)
		table.insert(cmd_args, norm_path)
	end

	vim.notify("Spawning: " .. table.concat(cmd_args, " "), vim.log.levels.INFO)

	vim.system(cmd_args, {
		detach = true,
		text = true,
		stdout = false,
		stderr = false
	}, function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				vim.notify("Exit Code: " .. obj.code .. " | Error: " .. (obj.stderr or ""),
					vim.log.levels.ERROR)
			end)
		end
	end)

	State.set_idle()
end

-- IPC Commands
function M.continue() cmd("continue") end

function M.run() cmd("run") end

function M.kill() cmd("kill_all") end -- raddbg command is kill_all

function M.pause() cmd("pause") end

function M.step_over() cmd("step_over") end

function M.step_into() cmd("step_into") end

function M.step_out() cmd("step_out") end

function M.step_over_line() cmd("step_over_line") end

function M.step_into_line() cmd("step_into_line") end

return M
