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
			-- Speculative state updates
			if action == "run" or action == "continue" then State.set_running() end
			if action == "pause" then State.set_paused() end
			if action == "kill_all" then State.set_idle() end
		end
	end)
end

---Ensure the RadDebugger GUI is running.
---Checks if running via IPC.
---If not, forces a DETACHED GUI launch via cmd start.
---@param callback function Function to run once GUI is ready
function M.ensure_gui_open(callback)
	-- Check if already running by pinging "bring_to_front"
	IPC.exec({ "bring_to_front" }, function(success)
		if success then
			-- Debugger is already alive
			if callback then callback() end
		else
			-- Debugger is dead. Launch it.
			local exe = vim.fn.exepath("raddbg")
			if exe == "" then
				vim.notify("Critical Error: 'raddbg' not found in PATH.", vim.log.levels.ERROR)
				return
			end

			vim.notify("Launching RAD Debugger GUI...", vim.log.levels.INFO)

			-- 'cmd /c start'
			vim.system({ "cmd.exe", "/c", "start", "", exe }, {
				detach = true,
			}, function()
				-- Callback ignored because 'start' exits immediately
			end)

			-- Wait for initialization
			-- Increased wait time to 2000ms to ensure the heavy GUI has time to initialize IPC
			vim.defer_fn(function()
				-- Double-check connection before proceeding
				IPC.exec({ "bring_to_front" }, function(ok)
					if ok then
						if callback then callback() end
					else
						vim.notify(
							"Launched RadDebugger, but IPC connection failed. Is it blocked?",
							vim.log.levels.WARN)
					end
				end)
			end, 2000)
		end
	end)
end

---Launch GUI (if needed) and select the target executable
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

return M
