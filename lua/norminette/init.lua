local M = {}

M.version = "0.7.0"

M.dependencies = { "nvim-lua/plenary.nvim", "echasnovski/mini.icons" }
M.namespace = vim.api.nvim_create_namespace("norminette")
M.toggle_state = false
M.show_size = true
M.has_norminette = nil
M.has_flake8 = nil
M.has_plenary = nil
M.has_async = nil

local function is_command_available(command)
	local handle = io.popen("command -v " .. command .. " 2>/dev/null")
	if not handle then
		return false
	end
	local result = handle:read("*a")
	handle:close()

	return result ~= ""
end

local function check_norminette_install()
	if not is_command_available("norminette") then
		vim.notify("norminette not installed or not in PATH. C linting is disabled")
		return false
	end
	return true
end

local function check_flake8_install()
	if not is_command_available("flake8") then
		vim.notify("flake8 not installed or not in PATH. Python linting is disabled")
		return false
	end
	return true
end

local function init_tool_check()
	M.has_plenary, M.has_async = pcall(require, "plenary.async")
	if not M.has_plenary or not M.has_async then
		vim.notify("This plugin requires plenary.nvim. Please install it to use this plugin.")
		return false
	end
	if M.has_norminette == nil then
		M.has_norminette = check_norminette_install()
	end
	if M.has_flake8 == nil then
		M.has_flake8 = check_flake8_install()
	end
	return true
end

local function parse_c_output(output)
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
					col = tonumber(col_num) - 4,
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

local function parse_python_output(output)
	local diagnostics = {}
	local current_file = nil
	for line in output:gmatch("[^\r\n]+") do
		current_file = line:match("^(.+.py):")
		print(line)
		local line_num, col_num, message = line:match("%S+%.py:(%d+):(%d+):%s+(.+)") -- This time wasn't so bad hmkay?
		if line_num and col_num and message then
			local diagnostic = {
				bufnr = vim.fn.bufnr(current_file),
				lnum = tonumber(line_num) - 1,
				col = tonumber(col_num) - 1,
				severity = vim.diagnostic.severity.ERROR,
				source = "flake8",
				message = message,
			}
			table.insert(diagnostics, diagnostic)
		else
			print("Failed to parse error line:", line)
		end
	end
	return diagnostics
end

local function clear_diagnostics(namespace, bufnr)
	vim.diagnostic.reset(namespace, bufnr)
end

local function run_norminette_check(bufnr, namespace)
	if not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
		vim.api.nvim_command("silent update")
	end
	local filename = vim.api.nvim_buf_get_name(bufnr)
	local filetype = vim.bo.filetype
	M.has_async.run(function()
		local output = nil
		if filetype == "c" or filetype == "cpp" then
			output = vim.fn.system("norminette " .. vim.fn.shellescape(filename))
		else
			output = vim.fn.system("flake8 " .. vim.fn.shellescape(filename))
			print("engaging python")
		end
		return output
	end, function(output)
		local diagnostics = nil
		if filetype == "c" or filetype == "cpp" then
			diagnostics = parse_c_output(output)
		else
			print("engaging python")
			diagnostics = parse_python_output(output)
		end
		vim.schedule(function()
			vim.diagnostic.reset(namespace, bufnr)
			vim.diagnostic.set(namespace, bufnr, diagnostics)
		end)
	end)
end

local function update_status()
	local icons_ok, icons = pcall(require, "mini.icons")
	if not icons_ok then
		error("This plugin requires mini.icons. Please install it to use this plugin.")
		return
	end

	local icon = icons.get("filetype", "nginx")
	if M.toggle_state then
		vim.api.nvim_set_hl(0, "NorminetteStatus", { fg = "#00ff00", bold = true })
		vim.opt.statusline:append("%#NorminetteStatus#")
		vim.opt.statusline:append(" " .. icon .. " ")
		vim.opt.statusline:append("%*")
	else
		vim.opt.statusline = vim.opt.statusline:get():gsub("%#NorminetteStatus#%s*%" .. icon .. "%s*%%*", "")
	end
end

local function correct_filetype()
	local file_type = vim.bo.filetype
	return file_type == "c" or file_type == "cpp" or file_type == "python" -- h is identified with cpp... idk why
end

local function update_function_sizes(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
	local parser = vim.treesitter.get_parser(bufnr, "c")
	if not parser then
		print("Failed Parsing")
		return
	end
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse("c", [[ (function_definition) @declaration ]])
	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local start_row, _, end_row, _ = node:range()
		local size = end_row - start_row - 2

		vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
			virt_text = { { "Size: " .. size .. " lines", "Comment" } },
			virt_text_pos = "eol",
		})
	end
end

local function clear_autocmds_and_messages()
	vim.api.nvim_clear_autocmds({ group = "NorminetteAutoCheck" })
	clear_diagnostics(M.namespace, vim.api.nvim_get_current_buf())
end

local function setup_clear_diagnostics_autocmd(bufnr)
	vim.api.nvim_create_autocmd("BufLeave", {
		pattern = { "*.c", "*.h", "*.py" },
		callback = function()
			clear_diagnostics(M.namespace, bufnr)
		end,
		group = vim.api.nvim_create_augroup("NorminetteClearDiagnostics", { clear = true }),
	})
end

local function setup_autocmds_and_run()
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter", "BufEnter", "BufWritePost" }, {
		pattern = { "*.c", "*.h", "*.py" },
		callback = function()
			setup_clear_diagnostics_autocmd(vim.api.nvim_get_current_buf())
			if M.toggle_state then
				run_norminette_check(vim.api.nvim_get_current_buf(), M.namespace)
			else
				clear_autocmds_and_messages()
			end
		end,
		group = vim.api.nvim_create_augroup("NorminetteAutoCheck", { clear = true }),
	})
	setup_clear_diagnostics_autocmd(vim.api.nvim_get_current_buf())
	if M.toggle_state then
		run_norminette_check(vim.api.nvim_get_current_buf(), M.namespace)
	else
		clear_autocmds_and_messages()
	end
end

local function setup_size_autocmd(bufnr)
	update_function_sizes(bufnr)
	run_norminette_check(bufnr, M.namespace)
	vim.api.nvim_create_autocmd({ "TextChanged", "BufWinEnter", "BufEnter", "BufWritePost" }, {
		pattern = { "*.c", ".h", "*.py" },
		callback = function()
			update_function_sizes(bufnr)
		end,
		group = vim.api.nvim_create_augroup("NorminetteFunctionSize", { clear = true }),
	})
end

local function clear_function_sizes(bufnr)
	if pcall(vim.api.nvim_get_autocmds, { group = "NorminetteFunctionSize" }) then
		vim.api.nvim_clear_autocmds({ group = "NorminetteFunctionSize" })
	end
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

local function toggle_norminette()
	if not init_tool_check() then
		return
	end
	if not correct_filetype() then
		print("Norminette only runs in .c or .h or .py files")
		return
	end
	M.toggle_state = not M.toggle_state
	if M.toggle_state then
		setup_autocmds_and_run()
		print("NorminetteAutoCheck enable")
	else
		clear_autocmds_and_messages()
		print("NorminetteAutoCheck disable")
	end
	update_status()
end

local function toggle_size()
	if not init_tool_check() then
		return
	end
	if not correct_filetype() and vim.bo.file_type ~= "py" then
		print("Norminette size function only runs in .c or .h files")
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	M.show_size = not M.show_size
	if M.show_size then
		setup_size_autocmd(bufnr)
		print("Norminette show_size enable")
	else
		clear_function_sizes(bufnr)
		print("Norminette show_size disable")
	end
end

function M.setup(opts)
	if not init_tool_check() then
		return
	end
	opts = opts or {}
	local default_opts = {
		norm_keybind = "<leader>n",
		size_keybind = "<leader>ns",
		diagnostic_color = "#00ff00",
		show_size = true,
	}
	for key, value in pairs(default_opts) do
		if opts[key] == nil then
			opts[key] = value
		end
	end

	M.show_size = opts.show_size
	if opts.norm_keybind then
		vim.keymap.set("n", opts.norm_keybind, toggle_norminette, { noremap = true, silent = true })
	end

	if opts.size_keybind then
		vim.keymap.set("n", opts.size_keybind, toggle_size, { noremap = true, silent = true })
	end
	vim.api.nvim_set_hl(0, "NorminetteDiagnostic", { fg = opts.diagnostic_color })
	vim.api.nvim_create_user_command("NorminetteToggle", function()
		toggle_norminette()
	end, {})
	vim.api.nvim_create_user_command("NorminetteSizeToggle", function()
		toggle_size()
	end, {})

	vim.diagnostic.config({
		virtual_text = {
			format = function(diagnostic)
				if diagnostic.namespace == M.namespace then
					return string.format("%s", diagnostic.message)
				end
				return diagnostic.message
			end,
			prefix = "●",
			hl_group = "NorminetteDiagnostic",
		},
	}, M.namespace)

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "BufWritePost" }, {
		pattern = { "*.c", "*.h" },
		callback = function()
			if M.toggle_state then
				run_norminette_check(vim.api.nvim_get_current_buf(), M.namespace)
			else
				clear_diagnostics(M.namespace, vim.api.nvim_get_current_buf())
			end
		end,
		group = vim.api.nvim_create_augroup("NorminetteInitialUpdate", { clear = true }),
	})
	vim.api.nvim_create_autocmd({ "TextChanged", "BufWinEnter", "BufEnter", "BufWritePost" }, {
		pattern = { "*.c", "*.h" },
		callback = function(ev)
			if M.show_size then
				update_function_sizes(ev.buf)
			else
				clear_function_sizes(vim.api.nvim_get_current_buf())
			end
		end,
		group = vim.api.nvim_create_augroup("NorminetteInitialUpdate", { clear = true }),
	})
end

return M
