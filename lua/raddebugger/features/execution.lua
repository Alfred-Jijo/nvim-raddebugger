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

---Ensure the RadDebugger GUI is running.
---1. Checks if running via IPC.
---2. If not, uses native OS shell to launch 'raddbg' from PATH.
---3. Polls until IPC is ready.
---@param callback function Function to run once GUI is ready
function M.ensure_gui_open(callback)
	-- Check if already running by pinging "bring_to_front"
	IPC.exec({ "bring_to_front" }, function(success)
		if success then
			-- Debugger is already alive and listening
			if callback then callback() end
		else
			-- Debugger is dead. Launch it.
			vim.notify("Launching RAD Debugger...", vim.log.levels.INFO)

			-- 'start' launches a separate process and returns immediately.
			-- '""' is the window title (required argument before the command).
			-- "raddbg" relies on cmd.exe to find the executable in the system PATH.
			os.execute('start "" "raddbg"')

			-- Polling Loop: Wait for the GUI to initialize its IPC pipe.
			-- The GUI needs a moment to start the message pump.
			local attempts = 0
			local max_attempts = 15 -- ~3 seconds total (15 * 200ms)

			local function poll()
				IPC.exec({ "bring_to_front" }, function(ok)
					if ok then
						-- Success! The GUI is responding to IPC.
						if callback then callback() end
					else
						attempts = attempts + 1
						if attempts < max_attempts then
							-- Retry after 200ms
							vim.defer_fn(poll, 200)
						else
							vim.notify("Timed out waiting for RadDebugger to start.",
								vim.log.levels.WARN)
						end
					end
				end)
			end

			-- Start polling after a short initial delay to let Windows spawn the window
			vim.defer_fn(poll, 200)
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

		-- Tell window to switch targets
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
