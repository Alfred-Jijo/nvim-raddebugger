local Exec = require("raddebugger.features.execution")
local Breakpoints = require("raddebugger.features.breakpoints")
local Targets = require("raddebugger.features.targets")
local Project = require("raddebugger.core.project")

local M = {}

---Helper: Try to find a valid target in CWD
---@return string|nil
local function find_target()
	local projects = vim.fn.glob("*.raddbg", false, true)
	if #projects > 0 then return projects[1] end

	local exes = vim.fn.glob("build/*.exe", false, true)
	if #exes > 0 then return exes[1] end

	exes = vim.fn.glob("*.exe", false, true)
	if #exes > 0 then return exes[1] end

	return nil
end

function M.setup()
	vim.api.nvim_create_user_command("RaddebuggerLaunch", function(opts)
		Exec.launch_gui(opts.args)
	end, { nargs = "?", complete = "file" })

	vim.api.nvim_create_user_command("RaddebuggerInit", function(opts)
		local target = opts.args

		-- Auto-Discovery if no arg provided
		if target == "" or target == nil then
			target = find_target()
			if target then
				vim.notify("Auto-detected target: " .. target, vim.log.levels.INFO)
			else
				vim.notify("No .raddbg or .exe found in CWD. Launching empty.", vim.log.levels.WARN)
			end
		end

		Exec.launch_gui(target)

		-- Load Internal Plugin State (if it's a project file)
		-- This ensures the plugin knows about targets/breakpoints defined in the file
		if target and target:match("%.raddbg$") then
			Project.load(target)
			Project.start_watching()
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
