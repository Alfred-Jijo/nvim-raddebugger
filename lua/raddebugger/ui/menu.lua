local M = {}

---@param title string
---@param items string[]
---@param keymaps table<string, function(index: number): boolean> -- Return true to close menu
function M.open(title, items, keymaps)
	local buf = vim.api.nvim_create_buf(false, true)

	-- Calculate size
	local width = 60
	local height = #items + 2
	-- Limit height if too many items
	if height > 20 then height = 20 end

	local ui = vim.api.nvim_list_uis()[1]
	local row = (ui.height - height) / 2
	local col = (ui.width - width) / 2

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
		title = title
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, items)
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "raddebugger_menu"

	-- Highlight the current line
	vim.api.nvim_win_set_option(win, "cursorline", true)

	-- Keymaps
	for key, fn in pairs(keymaps) do
		vim.keymap.set("n", key, function()
			local cursor_row = vim.api.nvim_win_get_cursor(win)[1]

			-- Execute callback
			local should_close = fn(cursor_row)

			-- Close if the callback returned true
			if should_close then
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			end
		end, { buffer = buf, nowait = true, silent = true })
	end

	-- Close with q or Esc
	local function close()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "q", close, { buffer = buf })
	vim.keymap.set("n", "<Esc>", close, { buffer = buf })
end

return M
