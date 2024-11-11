local M = {}

local norminette_rules = {}
local M = {}

-- Custom clang-format options for Norme V4
local clang_format_options = [[
BasedOnStyle: Google
IndentWidth: 4
UseTab: Always              # Use tabs for indentation
ColumnLimit: 80
BreakBeforeBraces: Allman
AllowShortIfStatementsOnASingleLine: false
IndentPPDirectives: AfterHash
SpacesInParentheses: false
SpaceAfterCStyleCast: false
DerivePointerAlignment: false
PointerAlignment: Right
AlignConsecutiveAssignments: true
AllowShortFunctionsOnASingleLine: false
AlignTrailingComments: true
SpaceBeforeParens: ControlStatements
IndentCaseLabels: false
]]

-- Check if the current file is a C or C++ file
local function is_c_file()
	local file_type = vim.bo.filetype
	return file_type == "c" or file_type == "cpp"
end

-- Run clang-format with the custom options
local function run_clang_format()
	local bufnr = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(bufnr)

	-- Construct the clang-format command with inline options
	local clang_cmd = string.format('clang-format -i --style="%s" %s', clang_format_options, file_path)

	-- Run the clang-format command
	vim.fn.system(clang_cmd)

	-- Reload the buffer to reflect the changes made by clang-format
	vim.cmd("edit!")
end

-- Main function to format the current buffer
function M.format_file(preview)
	if not is_c_file() then
		print("Error: Formatting is only available for C or C++ files")
		return
	end

	if preview then
		print("Preview not implemented in this direct invocation approach.")
	else
		-- Directly format the file using clang-format
		run_clang_format()
		print("File formatted successfully.")
	end
end

return M
