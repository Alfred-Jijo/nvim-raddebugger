local IPC = require("raddebugger.core.ipc")
local Path = require("raddebugger.utils.path")
local M = {}
local ns_id = vim.api.nvim_create_namespace("raddebugger_breakpoints")

-- Internal list of breakpoints
-- Format: { { path = "C:/...", line = 10 }, ... }
M.list = {}

---Re-send all active breakpoints to the debugger via IPC
---Useful after a fresh launch or attach.
function M.resend_all()
	if #M.list == 0 then return end

	-- We don't notify here to avoid spamming the user
	for _, bp in ipairs(M.list) do
		local loc = Path.format_for_raddbg(bp.path, bp.line)
		IPC.exec({ "add_breakpoint", loc }, function(ok)
			-- Silently fail or succeed
		end)
	end
end

function M.toggle(file, line)
	file = Path.normalize(file)

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
		IPC.exec({ "remove_breakpoint", Path.format_for_raddbg(bp.path, bp.line) }, function(ok)
			if ok then
				table.remove(M.list, idx)
				M.refresh_signs()
				vim.notify("Breakpoint removed", vim.log.levels.INFO)
			end
		end)
	else
		-- Add
		IPC.exec({ "toggle_breakpoint", Path.format_for_raddbg(file, line) }, function(ok)
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

vim.api.nvim_create_autocmd({ "BufEnter" }, { callback = function() M.refresh_signs() end })

return M
