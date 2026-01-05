local Exec = require("raddebugger.features.execution")
local Breakpoints = require("raddebugger.features.breakpoints")
local Targets = require("raddebugger.features.targets")
local IPC = require("raddebugger.core.ipc")
local Path = require("raddebugger.utils.path")
local Project = require("raddebugger.core.project")
local M = {}

function M.setup(opts)
	opts = opts or {}

	-- Version
	vim.api.nvim_create_user_command("RaddebuggerVersion", function()
		local ver = opts.version or "unknown"
		vim.notify("nvim-raddebugger v" .. ver, vim.log.levels.INFO)
	end, {})

	-- Just opens the GUI
	vim.api.nvim_create_user_command("RaddebuggerGUI", function()
		Exec.ensure_gui_open(function()
			vim.notify("RAD Debugger is ready.", vim.log.levels.INFO)
		end)
	end, {})

	-- MAIN INIT: Uses Project Parser
	vim.api.nvim_create_user_command("RaddebuggerInit", function(cmd_opts)
		local arg = cmd_opts.args
		local project_file = nil
		local exe_file = nil

		-- Determine Input
		if arg ~= "" and arg ~= nil then
			-- User provided an argument
			if arg:match("%.raddbg$") then
				project_file = arg
			elseif arg:match("%.exe$") then
				exe_file = arg
			end
		else
			-- Auto-discovery
			project_file = Project:find_raddbg(vim.fn.getcwd())
			if not project_file then
				-- Fallback to finding an exe if no project file
				local exes = vim.fn.glob("build/*.exe", false, true)
				if #exes > 0 then exe_file = exes[1] end
			end
		end

		-- Handle Project File
		if project_file then
			vim.notify("Loading project: " .. project_file, vim.log.levels.INFO)
			local ok, data = Project:init(project_file, function(new_data)
				vim.notify("Project file changed on disk.", vim.log.levels.INFO)
			end)

			if ok then
				-- Import Breakpoints from Project
				Breakpoints.load_from_project(Project:get_breakpoints())

				local targets = Project:get_targets()
				if #targets > 0 then
					Exec.launch_and_attach(targets[1].executable)
				else
					Exec.ensure_gui_open()
				end
			else
				vim.notify("Failed to parse project: " .. tostring(data), vim.log.levels.ERROR)
			end
			return
		end

		-- Handle Raw Executable
		if exe_file then
			Exec.launch_and_attach(exe_file)
			return
		end

		-- Fallback
		vim.notify("No .raddbg project or .exe found.", vim.log.levels.WARN)
		Exec.ensure_gui_open()
	end, { nargs = "?", complete = "file" })

	-- Standard Controls (Unchanged)
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

	vim.api.nvim_create_user_command("RaddebuggerWatch", function()
		local word = vim.fn.expand("<cword>")
		if word and word ~= "" then
			IPC.exec({ "toggle_watch_expr", word })
		end
	end, {})

	vim.api.nvim_create_user_command("RaddebuggerFocus", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local loc = Path.format_for_raddbg(file, line)
		IPC.exec({ "open_file", loc })
	end, {})

	vim.api.nvim_create_user_command("RaddebuggerRunToCursor", function()
		local file = vim.api.nvim_buf_get_name(0)
		local line = vim.api.nvim_win_get_cursor(0)[1]
		local loc = Path.format_for_raddbg(file, line)
		IPC.exec({ "run_to_line", loc })
	end, {})

	vim.api.nvim_create_user_command("RaddebuggerSave", function()
		IPC.exec({ "save_project" }, function(ok)
			if ok then IPC.exec({ "save_user" }) end
		end)
	end, {})
end

return M
