local IPC = require("raddebugger.core.ipc")
local State = require("raddebugger.core.state")
local Path = require("raddebugger.utils.path")
local M = {}

-- Send simple IPC commands (run, step, etc.)
local function cmd(action, args)
	local ipc_args = { action }
	if args then
		for _, v in ipairs(args) do table.insert(ipc_args, v) end
	end
	IPC.exec(ipc_args, function(ok, msg)
		if not ok then
			vim.notify("RAD IPC Error: " .. (msg or "Unknown"), vim.log.levels.ERROR)
		else
			-- Speculative state updates for UI responsiveness
			if action == "run" or action == "continue" then State.set_running() end
			if action == "pause" then State.set_paused() end
			if action == "kill_all" then State.set_idle() end
		end
	end)
end

---Check if RadDebugger is running.
---If YES: Run callback.
---If NO: Notify user to launch it manually.
---@param callback function Function to run if connected
function M.ensure_gui_open(callback)
	-- We simply try to ping the window.
	IPC.exec({ "bring_to_front" }, function(success)
		if success then
			-- It's alive! Proceed.
			if callback then callback() end
		else
			-- It's dead. We do NOT try to launch it anymore.
			vim.schedule(function()
				local msg = "!! RadDebugger is not running.\n\n" ..
				    "Please launch 'raddbg.exe' manually, then run this command again."
				vim.notify(msg, vim.log.levels.ERROR)
			end)
		end
	end)
end

---Connect to existing GUI and select the target executable
---@param path_to_exe string
function M.launch_and_attach(path_to_exe)
	M.ensure_gui_open(function()
		if not path_to_exe or path_to_exe == "" then return end

		local abs_path = Path.normalize(path_to_exe)
		vim.notify("Attaching to: " .. abs_path, vim.log.levels.INFO)

		-- Tell existing window to switch targets
		IPC.exec({ "select_target", abs_path }, function(ok, msg)
			if ok then
				State.set_idle()
				vim.notify("Target selected successfully.", vim.log.levels.INFO)

				-- Sync Breakpoints from Neovim -> RadDebugger
				require("raddebugger.features.breakpoints").resend_all()
			else
				vim.notify("Failed to select target: " .. (msg or "IPC Error"), vim.log.levels.ERROR)
			end
		end)
	end)
end

-- Standard Controls
function M.continue() cmd("continue") end

function M.run() cmd("run") end

function M.kill() cmd("kill_all") end

function M.pause() cmd("pause") end

function M.step_over() cmd("step_over") end

function M.step_into() cmd("step_into") end

function M.step_out() cmd("step_out") end

function M.restart() cmd("restart") end

return M
