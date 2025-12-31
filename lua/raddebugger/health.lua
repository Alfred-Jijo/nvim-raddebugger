local M = {}
local IPC = require("raddebugger.core.ipc")

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error

function M.check()
	start("RAD Debugger Integration")

	if vim.fn.has("win32") == 1 then
		ok("Running on Windows")
	else
		warn("Not running on Windows. RadDebugger is currently Windows-only; functionality may be limited.")
	end

	if IPC.validate_bin() then
		ok("Found 'raddbg' executable in PATH")

		-- Optional: Check version if raddbg supports --version
		local obj = vim.system({ "raddbg", "--version" }, { text = true }):wait()
		if obj.code == 0 then
			ok("Version: " .. vim.trim(obj.stdout))
		end
	else
		error("Could not find 'raddbg' in PATH.")
		vim.health.info("Please add the folder containing raddbg.exe to your System PATH environment variable.")
	end

	-- Check Neovim Version
	if vim.fn.has("nvim-0.10") == 1 then
		ok("Neovim version >= 0.10 (Supports vim.system)")
	else
		error("Neovim version < 0.10. This plugin requires modern async APIs.")
	end
end

return M
