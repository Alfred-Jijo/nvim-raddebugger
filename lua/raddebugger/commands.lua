local Exec = require("raddebugger.features.execution")
local Breakpoints = require("raddebugger.features.breakpoints")
local Targets = require("raddebugger.features.targets")
local Project = require("raddebugger.core.project")

local M = {}

---Helper: Try to find a valid target in CWD
---@return string|nil
local function find_target()
	-- Existing Project
	local projects = vim.fn.glob("*.raddbg", false, true)
	if #projects > 0 then return projects[1] end

	-- Executable
	local exes = vim.fn.glob("build/*.exe", false, true)
	if #exes > 0 then return exes[1] end

	-- Executable in root
	exes = vim.fn.glob("*.exe", false, true)
	if #exes > 0 then return exes[1] end

	return nil
end

function M.setup()
	-- DUMB LAUNCH
	vim.api.nvim_create_user_command("RaddebuggerLaunch", function(opts)
		Exec.launch_gui(opts.args)
	end, { nargs = "?", complete = "file" })

	-- SMART LAUNCH: Finds file, Launches, Loads State
	vim.api.nvim_create_user_command("RaddebuggerInit", function(opts)
		local target = opts.args

		-- Auto-Discovery if no arg provided
		if target == "" or target == nil then
			target = find_target()
			if target then
				vim.notify("Target found: " .. target, vim.log.levels.INFO)
			end
		end

		-- Launch the GUI
		Exec.launch_gui(target)

		-- If we ended up with a project file, start watching it
		if target then
			local proj_file = target:gsub("%.exe$", ".raddbg")

			-- Slight delay to let Raddbg create the file if it doesn't exist
			vim.defer_fn(function()
				Project.load(proj_file)
				Project.start_watching()
			end, 1000)
		end
	end, { nargs = "?", complete = "file" })

	-- Other Commands
	vim.api.nvim_create_user_command("RaddebuggerToggleBreakpoint", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		Breakpoints.toggle(file, line)
	end, {})

	vim.api.nvim_create_user_command("RaddebuggerTargetMenu", Targets.show_menu, {})

	-- Execution Control
	vim.api.nvim_create_user_command("RaddebuggerContinue", Exec.continue, {})
	vim.api.nvim_create_user_command("RaddebuggerRun", Exec.run, {})
	vim.api.nvim_create_user_command("RaddebuggerKill", Exec.kill, {})
	vim.api.nvim_create_user_command("RaddebuggerStepOver", Exec.step_over, {})
	vim.api.nvim_create_user_command("RaddebuggerStepInto", Exec.step_into, {})
	vim.api.nvim_create_user_command("RaddebuggerStepOut", Exec.step_out, {})
end

return M
