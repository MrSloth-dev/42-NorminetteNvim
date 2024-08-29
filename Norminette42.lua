local M = {}

-- Function to parse the output of norminette
local function parse_norminette_output(output)
	local diagnostics = {}
	local current_file = nil
	for line in output:gmatch("[^\r\n]+") do
		if line:match(": Error!$") then
			current_file = line:match("^(.+): Error!$")
		elseif line:match("^Error:") then
			local error_type, line_num, col_num, message =
				line:match("^Error:%s+([A-Z_]*)%s*%pline:%s*(%d+), col:%s+(%d+)%p:(.*)") -- FUCK REGEX
			if error_type and line_num and col_num and message then
				local diagnostic = {
					bufnr = vim.fn.bufnr(current_file),
					lnum = tonumber(line_num) - 1,
					col = tonumber(col_num) - 1,
					severity = vim.diagnostic.severity.ERROR,
					source = "norminette",
					message = error_type .. " : " .. message:gsub("^%s*", ""),
				}
				table.insert(diagnostics, diagnostic)
			else
				print("Failed to parse error line:", line)
			end
		end
	end
	return diagnostics
end

-- Function to run norminette and update diagnostics
function M.run_norminette()
	local bufnr = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local namespace = vim.api.nvim_create_namespace("norminette")
	-- Run norminette command
	local output = vim.fn.system("norminette " .. vim.fn.shellescape(filename))
	-- Parse the output
	local diagnostics = parse_norminette_output(output)
	-- Clear existing diagnostics for this buffer and namespace
	vim.diagnostic.reset(namespace, bufnr)
	-- Set new diagnostics
	vim.diagnostic.set(namespace, bufnr, diagnostics)
end

-- Function to setup the plugin
function M.setup()
	-- Create an autocommand to run norminette on file save and when cursor is held
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "CursorHold" }, {
		pattern = { "*.c", "*.h" },
		callback = M.run_norminette,
	})
	-- Create a command to manually run norminette
	vim.api.nvim_create_user_command("Norminette", M.run_norminette, {})
end

return M
