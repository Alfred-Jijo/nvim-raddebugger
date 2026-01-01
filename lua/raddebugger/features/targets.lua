local IPC = require("raddebugger.core.ipc")
local Project = require("raddebugger.core.project")
local Menu = require("raddebugger.ui.menu")
local Exec = require("raddebugger.features.execution")

local M = {}

function M.show_menu()
	-- Safety check: Ensure project data is loaded
	if not Project.data or not Project.data.targets or #Project.data.targets == 0 then
		vim.notify("No targets found in project file", vim.log.levels.WARN)
		return
	end

	-- Prepare list for display
	local lines = {}
	for _, t in ipairs(Project.data.targets) do
		-- TODO: If we parse 'enabled' status in project.lua, we could show [x] here
		table.insert(lines, "  " .. t)
	end

	Menu.open("Select Target", lines, {
		-- SELECT: Switch to this target and close menu
		["<CR>"] = function(idx)
			local t = Project.data.targets[idx]
			if t then
				-- Use our smart launch/attach logic
				Exec.launch_and_attach(t)
				return true -- Return true to signal "Close Menu"
			end
		end,

		-- ENABLE: Send IPC command, keep menu open to see result
		["h"] = function(idx)
			local t = Project.data.targets[idx]
			IPC.exec({ "enable_target", t }, function()
				vim.notify("Enabled: " .. t)
			end)
			return false -- Keep menu open
		end,

		-- DISABLE: Send IPC command, keep menu open
		["l"] = function(idx)
			local t = Project.data.targets[idx]
			IPC.exec({ "disable_target", t }, function()
				vim.notify("Disabled: " .. t)
			end)
			return false
		end,
	})
end

return M
