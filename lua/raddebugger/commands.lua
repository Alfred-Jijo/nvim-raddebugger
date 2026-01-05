local Exec = require("raddebugger.features.execution")
local Breakpoints = require("raddebugger.features.breakpoints")
local Targets = require("raddebugger.features.targets")
local IPC = require("raddebugger.core.ipc")
local M = {}

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
		if target == "" or target == nil then
			target = find_launch_target()
		end

		if not target then
			vim.notify("No .raddbg project or .exe found. Opening empty GUI.", vim.log.levels.WARN)
			Exec.ensure_gui_open()
		else
			Exec.launch_and_attach(target)
		end
	end, { nargs = "?", complete = "file" })

	-- Standard Controls
	vim.api.nvim_create_user_command("RaddebuggerToggleBreakpoint", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		Breakpoints.toggle(file, line)
	end, {})

	vim.api.nvim_create_user_command("RaddebuggerClearBreakpoints", Breakpoints.clear_all, {})

	vim.api.nvim_create_user_command("RaddebuggerTargetMenu", Targets.show_menu, {})
	vim.api.nvim_create_user_command("RaddebuggerContinue", Exec.continue, {})
	vim.api.nvim_create_user_command("RaddebuggerRun", Exec.run, {})
	vim.api.nvim_create_user_command("RaddebuggerRestart", Exec.restart, {})
	vim.api.nvim_create_user_command("RaddebuggerKill", Exec.kill, {})
	vim.api.nvim_create_user_command("RaddebuggerStepOver", Exec.step_over, {})
	vim.api.nvim_create_user_command("RaddebuggerStepInto", Exec.step_into, {})
	vim.api.nvim_create_user_command("RaddebuggerStepOut", Exec.step_out, {})

	-- Watch the word under the cursor
	vim.api.nvim_create_user_command("RaddebuggerWatch", function()
		local word = vim.fn.expand("<cword>")
		if word and word ~= "" then
			IPC.exec({ "toggle_watch_expr", word }, function(ok)
				if ok then vim.notify("RAD: Watching '" .. word .. "'", vim.log.levels.INFO) end
			end)
		else
			vim.notify("No word under cursor to watch", vim.log.levels.WARN)
		end
	end, {})

	-- Focus RadDebugger on the current file/line
	vim.api.nvim_create_user_command("RaddebuggerFocus", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local loc = require("raddebugger.utils.path").format_for_raddbg(file, line)
		IPC.exec({ "open_file", loc })
	end, {})
end

return M
