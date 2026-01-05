local Exec = require("raddebugger.features.execution")
local Breakpoints = require("raddebugger.features.breakpoints")
local Targets = require("raddebugger.features.targets")
local M = {}

---Priority:
--- 1. *.raddbg in current directory
--- 2. *.raddbg in parent directory
--- 3. *.exe in build/bin/ directory
--- 4. *.exe in build/ directory
--- 5. *.exe in current directory
local function find_launch_target()
	local projects = vim.fn.glob("*.raddbg", false, true)
	if #projects > 0 then return projects[1] end

	projects = vim.fn.glob("../*.raddbg", false, true)
	if #projects > 0 then return projects[1] end

	local exes = vim.fn.glob("build/bin/*.exe", false, true)
	if #exes > 0 then return exes[1] end

	exes = vim.fn.glob("build/*.exe", false, true)
	if #exes > 0 then return exes[1] end

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

	-- Opens GUI -> Selects Target (Project or EXE) -> Loads Breakpoints
	vim.api.nvim_create_user_command("RaddebuggerInit", function(cmd_opts)
		local target = cmd_opts.args

		-- Auto-Discovery
		if target == "" or target == nil then
			target = find_launch_target()
		end

		if not target then
			vim.notify("No .raddbg project or .exe found. Opening empty GUI.", vim.log.levels.WARN)
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

	vim.api.nvim_create_user_command("RaddebuggerWatch", function()
		-- Get word under cursor
		local word = vim.fn.expand("<cword>")
		if word and word ~= "" then
			-- Send to RAD
			IPC.exec({ "toggle_watch_expr", word }, function(ok)
				if ok then vim.notify("Added to Watch: " .. word) end
			end)
		end
	end, {})
	vim.api.nvim_create_user_command("RaddebuggerFocus", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local loc = require("raddebugger.utils.path").format_for_raddbg(file, line)

		IPC.exec({ "open_file", loc }, function(ok)
			-- This forces RadDebugger to jump to where YOU are in Neovim
		end)
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
