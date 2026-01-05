local Path = require("raddebugger.utils.path")
local M = {}

-- Internal state
M.data = nil
M.file_path = nil
M.watcher = nil
M.callback = nil

---Split "path:line:col" into table
---@param loc string e.g. "src/main.c:38:1"
---@return table|nil {path, line, column}
local function parse_source_location(loc)
	if not loc then return nil end
	-- Pattern: Any characters until last colon (path), then digits (line), then digits (col)
	-- This handles Windows drive letters (C:/...) correctly because we anchor to the end
	local path, line, col = loc:match("^(.*):(%d+):(%d+)$")
	if not path then
		-- Try "path:line" fallback
		path, line = loc:match("^(.*):(%d+)$")
		col = 1
	end

	if path and line then
		return {
			source_location = loc,
			path = Path.normalize(path), -- Ensure forward slashes
			line = tonumber(line),
			column = tonumber(col) or 1
		}
	end
	return nil
end

---Convert 1/0 integers to boolean
---@param val any
---@return boolean
local function convert_to_bool(val)
	if val == 1 or val == "1" or val == true then return true end
	return false
end

---Remove surrounding quotes from string
local function remove_quotes(str)
	if str:sub(1, 1) == '"' and str:sub(-1) == '"' then
		return str:sub(2, -2)
	end
	return str
end

---Tokenizer for .raddbg format
---Splits file content into meaningful tokens, handling quoted strings and structure symbols
local function tokenize(content)
	local tokens = {}
	local i = 1
	local len = #content

	while i <= len do
		local char = content:sub(i, i)

		-- Skip whitespace
		if char:match("%s") then
			i = i + 1
			-- Handle Comments (//)
		elseif char == "/" and content:sub(i + 1, i + 1) == "/" then
			local next_newline = content:find("\n", i)
			if next_newline then i = next_newline + 1 else break end
			-- Handle Structural Chars
		elseif char == "{" or char == "}" or char == ":" then
			table.insert(tokens, char)
			i = i + 1
			-- Handle Quoted Strings
		elseif char == '"' then
			local end_quote = content:find('"', i + 1)
			if end_quote then
				table.insert(tokens, content:sub(i, end_quote))
				i = end_quote + 1
			else
				-- Runaway string, consume rest
				table.insert(tokens, content:sub(i))
				break
			end
			-- Handle Unquoted Values (Keys, Numbers, Booleans)
		else
			local j = i
			while j <= len do
				local c = content:sub(j, j)
				if c:match("[%s{}:]") then break end
				j = j + 1
			end
			table.insert(tokens, content:sub(i, j - 1))
			i = j
		end
	end
	return tokens
end

---Main Parsing Function
---@param file_path string
---@return boolean success
---@return table|string data_or_error
function M:parse(file_path)
	local f = io.open(file_path, "r")
	if not f then return false, "File not found: " .. file_path end
	local content = f:read("*a")
	f:close()

	local tokens = tokenize(content)
	local result = {
		recent_file = nil,
		targets = {},
		debug_info = {},
		breakpoints = {}
	}

	local i = 1
	local len = #tokens

	while i <= len do
		local key = tokens[i]

		-- Expecting 'key:' pattern
		if tokens[i + 1] == ":" then
			i = i + 2 -- Skip key and colon

			-- Check for block start '{'
			if tokens[i] == "{" then
				i = i + 1 -- Enter block
				local entry = {}

				-- Parse Block Contents until '}'
				while i <= len and tokens[i] ~= "}" do
					local field = tokens[i]
					if tokens[i + 1] == ":" then
						local value = tokens[i + 2]
						if value then
							entry[field] = remove_quotes(value)
						end
						i = i + 3
					else
						-- Malformed field inside block, skip
						i = i + 1
					end
				end

				-- Store parsed entry based on key
				if key == "target" then
					table.insert(result.targets, {
						executable = Path.normalize(entry.executable or ""),
						working_directory = Path.normalize(entry.working_directory or ""),
						label = entry.label or "unnamed",
						enabled = convert_to_bool(tonumber(entry.enabled))
					})
				elseif key == "debug_info" then
					table.insert(result.debug_info, {
						path = Path.normalize(entry.path or ""),
						timestamp = tonumber(entry.timestamp) or 0
					})
				elseif key == "breakpoint" then
					local bp_data = parse_source_location(entry.source_location)
					if bp_data then
						bp_data.hit_count = tonumber(entry.hit_count) or 0
						table.insert(result.breakpoints, bp_data)
					end
				elseif key == "recent_file" then
					result.recent_file = { path = Path.normalize(entry.path or "") }
				end

				i = i + 1

				-- Handle simple key: value (not a block)
			else
				i = i + 1
			end
		else
			-- Unexpected token, skip
			i = i + 1
		end
	end

	return true, result
end

---Search for .raddbg file recursively upwards
---@param search_dir string
---@return string|nil
function M:find_raddbg(search_dir)
	local current = search_dir or vim.fn.getcwd()
	local root = Path.is_windows and current:match("^%a:\\") or "/"

	while current do
		local path = current .. "/project.raddbg" -- Check generic name
		if vim.fn.filereadable(path) == 1 then return path end

		-- Also check for ANY .raddbg file
		local files = vim.fn.glob(current .. "/*.raddbg", false, true)
		if #files > 0 then return files[1] end

		if current == root then break end
		current = vim.fn.fnamemodify(current, ":h")
	end
	return nil
end

---Initialize project monitoring
---@param file_path string
---@param callback function(data)
---@return boolean success, string|table error_or_data
function M:init(file_path, callback)
	if not file_path then return false, "No file path provided" end

	M.file_path = file_path
	M.callback = callback

	-- Initial Parse
	local success, data = M:parse(file_path)
	if not success then return false, data end

	M.data = data

	-- Set up File Watcher
	if M.watcher then M.watcher:stop() end

	M.watcher = vim.loop.new_fs_event()
	M.watcher:start(file_path, {}, function(err, _, _)
		if not err then
			-- Re-parse on change
			vim.schedule(function()
				local ok, new_data = M:parse(file_path)
				if ok then
					M.data = new_data
					if M.callback then M.callback(new_data) end
					vim.notify("RAD Project reloaded", vim.log.levels.INFO)
				end
			end)
		end
	end)

	return true, data
end

function M:get_targets() return M.data and M.data.targets or {} end

function M:get_breakpoints() return M.data and M.data.breakpoints or {} end

function M:get_debug_info() return M.data and M.data.debug_info or {} end

function M:get_recent_file() return M.data and M.data.recent_file end

return M
