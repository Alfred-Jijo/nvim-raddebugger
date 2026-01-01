local Exec = require("raddebugger.features.execution")
local Breakpoints = require("raddebugger.features.breakpoints")
local Targets = require("raddebugger.features.targets")
local M = {}

---Helper: Try to find a valid executable in CWD
local function find_target_exe()
	-- Look for Executable (.exe) in build/
	local exes = vim.fn.glob("build/*.exe", false, true)
	if #exes > 0 then return exes[1] end

	-- Look for Executable (.exe) in root
	exes = vim.fn.glob("*.exe", false, true)
	if #exes > 0 then return exes[1] end

	return nil
end

function M.setup(opts)
	opts = opts or {}

	-- Version
	vim.api.nvim_create_user_command("RaddebuggerVersion", function()
		local ver = opts.version or "unknown"
		vim.notify("nvim-raddebugger v" .. ver, vim.log.levels.INFO)
	end, {})

	-- Just opens the GUI (or focuses it). No target changes.
	vim.api.nvim_create_user_command("RaddebuggerGUI", function()
		Exec.ensure_gui_open(function()
			vim.notify("RAD Debugger is ready.", vim.log.levels.INFO)
		end)
	end, {})

	-- Opens GUI -> Selects Target EXE -> Loads Breakpoints
	vim.api.nvim_create_user_command("RaddebuggerInit", function(cmd_opts)
		local target = cmd_opts.args

		-- Auto-Discovery
		if target == "" or target == nil then
			target = find_target_exe()
		end

		if not target then
			vim.notify("No target exe found. Opening empty GUI.", vim.log.levels.WARN)
			Exec.ensure_gui_open()
		else
			-- Launch and Attach via IPC
			Exec.launch_and_attach(target)
		end
	end, { nargs = "?", complete = "file" })

	-- Standard Commands
	vim.api.nvim_create_user_command("RaddebuggerToggleBreakpoint", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		Breakpoints.toggle(file, line)
	end, {})

	vim.api.nvim_create_user_command("RaddebuggerTargetMenu", Targets.show_menu, {})
	vim.api.nvim_create_user_command("RaddebuggerContinue", Exec.continue, {})
	vim.api.nvim_create_user_command("RaddebuggerRun", Exec.run, {})
	vim.api.nvim_create_user_command("RaddebuggerKill", Exec.kill, {})
	vim.api.nvim_create_user_command("RaddebuggerStepOver", Exec.step_over, {})
	vim.api.nvim_create_user_command("RaddebuggerStepInto", Exec.step_into, {})
	vim.api.nvim_create_user_command("RaddebuggerStepOut", Exec.step_out, {})
end

return M
