local IPC = require("raddebugger.core.ipc")
local Project = require("raddebugger.core.project")
local Menu = require("raddebugger.ui.menu")
local Exec = require("raddebugger.features.execution")

local M = {}

function M.show_menu()
	-- Safety check: Ensure project data is loaded
	local targets = Project:get_targets()
	if not targets or #targets == 0 then
		vim.notify("No targets found in project file", vim.log.levels.WARN)
		return
	end

	-- Prepare list for display (Format: "[x] label: path")
	local lines = {}
	for _, t in ipairs(targets) do
		local state = t.enabled and "[x]" or "[ ]"
		local label = t.label or "unnamed"
		-- Truncate executable path for display
		local exe_name = vim.fn.fnamemodify(t.executable, ":t")

		table.insert(lines, string.format("%s %s (%s)", state, label, exe_name))
	end

	Menu.open("Select Target", lines, {
		-- SELECT: Switch to this target and close menu
		["<CR>"] = function(idx)
			local t = targets[idx]
			if t then
				-- Pass the actual executable path to the launcher
				Exec.launch_and_attach(t.executable)
				return true -- Return true to signal "Close Menu"
			end
		end,

		-- ENABLE: Send IPC command, keep menu open
		["h"] = function(idx)
			local t = targets[idx]
			if t then
				-- notify for now
				vim.notify("Target info: " .. t.executable)
			end
			return false
		end,
	})
end

return M
