local Commands = require("raddebugger.commands")
local Signs = require("raddebugger.ui.signs")
local State = require("raddebugger.core.state")
local IPC = require("raddebugger.core.ipc")
local Project = require("raddebugger.core.project")

local M = {}

-- Plugin Version
M._VERSION = "0.16.2"

local default_config = {
	project_file = nil, -- Auto-detect

	-- Keymaps (Visual Studio Style Defaults)
	keymaps = {
		toggle_breakpoint = "<F9>",
		continue          = "<F5>",
		step_over         = "<F10>",
		step_into         = "<F11>",
		step_out          = "<S-F11>",
		run_to_cursor     = "<C-F10>",
		stop              = "<S-F5>",
		target_menu       = nil,
	},

	breakpoint_color = "#51202a",
	statusline = true,
	auto_update = true,
	debounce_ms = 500
}

---Apply keymaps based on config
local function apply_keymaps(keymaps)
	if keymaps == false then return end

	local map = function(lhs, cmd, desc)
		if lhs then
			vim.keymap.set("n", lhs, cmd, { desc = "RAD: " .. desc, silent = true })
		end
	end

	map(keymaps.toggle_breakpoint, 	"<cmd>RaddebuggerToggleBreakpoint<CR>", "Toggle Breakpoint")
	map(keymaps.continue,		"<cmd>RaddebuggerContinue<CR>", 	"Continue/Run")
	map(keymaps.step_over, 		"<cmd>RaddebuggerStepOver<CR>", 	"Step Over")
	map(keymaps.step_into, 		"<cmd>RaddebuggerStepInto<CR>", 	"Step Into")
	map(keymaps.step_out, 		"<cmd>RaddebuggerStepOut<CR>", 		"Step Out")
	map(keymaps.run_to_cursor, 	"<cmd>RaddebuggerRunToCursor<CR>", 	"Run to Cursor")
	map(keymaps.stop, 		"<cmd>RaddebuggerKill<CR>", 		"Stop/Kill")
	map(keymaps.target_menu, 	"<cmd>RaddebuggerTargetMenu<CR>", 	"Targets Menu")
end

---Initialize the plugin
function M.setup(opts)
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	Signs.setup(opts)

	Commands.setup({ version = M._VERSION })

	apply_keymaps(opts.keymaps)

	if not IPC.validate_bin() then
		vim.notify("RAD Debugger (raddbg) not found in PATH", vim.log.levels.WARN)
	end

	-- Auto-load project if found
	local project_to_load = opts.project_file or Project:find_raddbg(vim.fn.getcwd())

	if project_to_load then
		-- Schedule init to run after startup so UI is ready
		vim.schedule(function()
			-- Pass the full path to our smart Init command
			vim.cmd("RaddebuggerInit " .. vim.fn.fnameescape(project_to_load))
		end)
	end
end

function M.statusline_component()
	local state = State.get()
	if state == State.States.DISCONNECTED then return "" end
	return string.format("[RAD: %s]", state:upper())
end

return M
