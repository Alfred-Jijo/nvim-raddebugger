local IPC = require("raddebugger.core.ipc")
local Project = require("raddebugger.core.project")
local Menu = require("raddebugger.ui.menu")

local M = {}

function M.show_menu()
	if #Project.data.targets == 0 then
		vim.notify("No targets found in project file", vim.log.levels.WARN)
		return
	end

	local lines = {}
	for _, t in ipairs(Project.data.targets) do
		table.insert(lines, "  " .. t)
	end

	Menu.open("Select Target", lines, {
		["<CR>"] = function(idx)
			local t = Project.data.targets[idx]
			IPC.exec({ "select_target", t }, function(ok)
				if ok then vim.notify("Selected target: " .. t) end
			end)
		end,
		["h"] = function(idx)
			local t = Project.data.targets[idx]
			IPC.exec({ "enable_target", t }, function() vim.notify("Enabled: " .. t) end)
		end,
		["l"] = function(idx)
			local t = Project.data.targets[idx]
			IPC.exec({ "disable_target", t }, function() vim.notify("Disabled: " .. t) end)
		end,
	})
end

return M
