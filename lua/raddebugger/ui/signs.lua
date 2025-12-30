local M = {}

function M.setup(config)
	vim.cmd("highlight default RadBreakpointLine guibg=" .. (config.breakpoint_color or "#51202a"))
	vim.cmd("highlight default link RadBreakpointSign RedSign")

	vim.fn.sign_define("RadBreakpoint", {
		text = "●",
		texthl = "RadBreakpointSign",
		linehl = "RadBreakpointLine",
		numhl = "RadBreakpointLine"
	})
end

return M
