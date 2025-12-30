local Commands = require("raddebugger.commands")
local Signs = require("raddebugger.ui.signs")
local State = require("raddebugger.core.state")
local IPC = require("raddebugger.core.ipc")

local M = {}

local default_config = {
	project_file = nil, -- Auto-detect

	-- Set to 'false' to disable all default keymaps
	keymaps = {
		toggle_breakpoint = "<F9>",
		continue          = "<F5>",
		step_over         = "<F10>",
		step_into         = "<F11>",
		step_out          = "<S-F11>", -- Shift + F11
		stop              = "<S-F5>", -- Shift + F5 (Kill)
		target_menu       = nil, -- No default, to avoid Leader conflicts
		breakpoint_menu   = nil,
	},

	breakpoint_color = "#51202a",
	statusline = true,
	auto_update = true,
	debounce_ms = 500
}

---Attempt to find a .raddbg file in the current working directory
local function find_project_file()
	local cwd = vim.fn.getcwd()
	local files = vim.fn.glob(cwd .. "/*.raddbg", false, true)
	if #files > 0 then return files[1] end
	return nil
end

---Apply keymaps based on config
local function apply_keymaps(keymaps)
	if keymaps == false then return end -- User disabled all maps

	local map = function(lhs, cmd, desc)
		if lhs then
			vim.keymap.set("n", lhs, cmd, { desc = "RAD: " .. desc, silent = true })
		end
	end

	-- Map internal keys to commands
	map(keymaps.toggle_breakpoint, "<cmd>RaddebuggerToggleBreakpoint<CR>", "Toggle Breakpoint")
	map(keymaps.continue, "<cmd>RaddebuggerContinue<CR>", "Continue/Run")
	map(keymaps.step_over, "<cmd>RaddebuggerStepOver<CR>", "Step Over")
	map(keymaps.step_into, "<cmd>RaddebuggerStepInto<CR>", "Step Into")
	map(keymaps.step_out, "<cmd>RaddebuggerStepOut<CR>", "Step Out")
	map(keymaps.stop, "<cmd>RaddebuggerKill<CR>", "Stop/Kill")
	map(keymaps.target_menu, "<cmd>RaddebuggerTargetMenu<CR>", "Targets Menu")
end

---Initialize the plugin
function M.setup(opts)
	-- Merge defaults with user opts
	opts = vim.tbl_deep_extend("force", default_config, opts or {})

	Signs.setup(opts)
	Commands.setup()
	apply_keymaps(opts.keymaps)

	if not IPC.validate_bin() then
		vim.notify("RAD Debugger (raddbg) not found in PATH", vim.log.levels.WARN)
	end

	-- Project Auto-detection Logic
	local project_to_load = opts.project_file
	if not project_to_load then
		local found = find_project_file()
		if found then
			project_to_load = found
			vim.notify("Auto-detected RAD project: " .. vim.fn.fnamemodify(found, ":t"), vim.log.levels.INFO)
		end
	end

	if project_to_load then
		vim.schedule(function() vim.cmd("RaddebuggerInit " .. project_to_load) end)
	end
end

function M.statusline_component()
	local state = State.get()
	if state == State.States.DISCONNECTED then return "" end
	return string.format("[RAD: %s]", state:upper())
end

return M
