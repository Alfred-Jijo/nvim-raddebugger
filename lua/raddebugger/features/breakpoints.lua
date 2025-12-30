local IPC = require("raddebugger.core.ipc")
local Path = require("raddebugger.utils.path")
local Signs = require("raddebugger.ui.signs")

local M = {}
local ns_id = vim.api.nvim_create_namespace("raddebugger_breakpoints")

---@class Breakpoint
---@field path string
---@field line number
---@field id number?

---@type Breakpoint[]
M.list = {}

---Toggle breakpoint at file/line
---@param file string
---@param line number
function M.toggle(file, line)
	file = Path.normalize(file)

	-- Check if exists
	local idx = nil
	for i, bp in ipairs(M.list) do
		if bp.path == file and bp.line == line then
			idx = i
			break
		end
	end

	if idx then
		-- Remove
		local bp = M.list[idx]
		IPC.exec({ "remove_breakpoint", Path.format_for_raddbg(bp.path, bp.line) }, function(ok, _)
			if ok then
				table.remove(M.list, idx)
				M.refresh_signs()
				vim.notify("Breakpoint removed", vim.log.levels.INFO)
			end
		end)
	else
		-- Add
		IPC.exec({ "toggle_breakpoint", Path.format_for_raddbg(file, line) }, function(ok, _)
			if ok then
				table.insert(M.list, { path = file, line = line })
				M.refresh_signs()
				vim.notify("Breakpoint set", vim.log.levels.INFO)
			end
		end)
	end
end

function M.refresh_signs()
	vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

	local current_buf = vim.api.nvim_get_current_buf()
	local current_file = Path.normalize(vim.api.nvim_buf_get_name(current_buf))

	for _, bp in ipairs(M.list) do
		if bp.path == current_file then
			pcall(vim.api.nvim_buf_set_extmark, current_buf, ns_id, bp.line - 1, 0, {
				sign_text = "●",
				sign_hl_group = "RadBreakpointSign",
				line_hl_group = "RadBreakpointLine",
				priority = 20
			})
		end
	end
end

-- Auto-refresh signs on buf enter
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	callback = function() M.refresh_signs() end
})

return M
