local IPC = require("raddebugger.core.ipc")
local State = require("raddebugger.core.state")

local M = {}

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
			-- Update state speculatively, ideally raddbg sends status updates
			if action == "run" or action == "continue" then State.set_running() end
			if action == "pause" then State.set_paused() end
			if action == "kill" then State.set_idle() end
			if action:match("^step") then State.set_paused() end
		end
	end)
end

function M.continue() cmd("continue") end

function M.run() cmd("run") end

function M.kill() cmd("kill_all") end -- raddbg command is kill_all based on spec

function M.pause() cmd("pause") end

function M.step_over() cmd("step_over") end

function M.step_into() cmd("step_into") end

function M.step_out() cmd("step_out") end

function M.step_over_line() cmd("step_over_line") end

function M.step_into_line() cmd("step_into_line") end

function M.launch_gui(path)
	if not path or path == "" then
		vim.notify("Please specify an executable path", vim.log.levels.ERROR)
		return
	end

	local Path = require("raddebugger.utils.path")
	local normalized = Path.normalize(path)

	vim.notify("Launching RadDebugger: " .. normalized, vim.log.levels.INFO)

	-- Spawn the process detached
	vim.system({ "raddbg", normalized }, {
		detach = true,
		text = true
	}, function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				vim.notify("Failed to open GUI: " .. (obj.stderr or ""), vim.log.levels.ERROR)
			end)
		end
	end)
end

return M
