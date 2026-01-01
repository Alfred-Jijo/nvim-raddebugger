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
---@param path string|nil Path to .raddbg project (or .exe to auto-convert)
function M.launch_gui(path)
	local exe = vim.fn.exepath("raddbg")
	if exe == "" then
		vim.notify("Critical Error: 'raddbg' not found in PATH.", vim.log.levels.ERROR)
		return
	end

	local cmd_args = { exe }

	if path and path ~= "" then
		local project_path = path

		-- If user passed an .exe, swap it to .raddbg
		-- RadDebugger will create the project file
		if project_path:match("%.exe$") then
			project_path = project_path:gsub("%.exe$", ".raddbg")
			vim.notify("Auto-creating project file: " .. project_path, vim.log.levels.INFO)
		end

		local norm_path = Path.normalize(project_path)

		table.insert(cmd_args, "--project")
		table.insert(cmd_args, ":" .. norm_path)
	end

	vim.notify("Spawning: " .. table.concat(cmd_args, " "), vim.log.levels.INFO)

	-- Launch
	-- disable stdout/stderr capturing because Windows GUI apps
	-- often hang if a console tries to read their output pipes.
	vim.system(cmd_args, {
		detach = true,
		stdout = false,
		stderr = false
	}, function(obj)
		if obj.code ~= 0 then
			vim.schedule(function()
				-- If it fails immediately, notify user
				vim.notify("RadDebugger Launch Error: Code " .. obj.code, vim.log.levels.ERROR)
			end)
		end
	end)

	State.set_idle()
end

-- IPC Command Exports
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
