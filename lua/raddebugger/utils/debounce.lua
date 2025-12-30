local M = {}

---Create a debounced function
---@param fn function The function to debounce
---@param delay_ms number Delay in milliseconds
---@return function debounced_fn, function cancel_fn
function M.create(fn, delay_ms)
	local timer = vim.uv.new_timer()
	local pending = false

	local function debounced(...)
		local args = { ... }
		pending = true
		timer:stop()
		timer:start(delay_ms, 0, vim.schedule_wrap(function()
			if pending then
				fn(unpack(args))
				pending = false
			end
		end))
	end

	local function cancel()
		pending = false
		timer:stop()
	end

	return debounced, cancel
end

return M
