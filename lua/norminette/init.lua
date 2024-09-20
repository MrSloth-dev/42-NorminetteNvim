local M = {}

M.version = "0.4"

M.dependencies = { "nvim-lua/plenary.nvim", "echasnovski/mini.icons" }
M.namespace = vim.api.nvim_create_namespace("norminette")
M.toggle_state = false

local has_plenary, async = pcall(require, "plenary.async")
if not has_plenary then
	error("This plugin requires plenary.nvim. Please install it to use this plugin.")
end

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

local function clear_diagnostics(namespace, bufnr)
	vim.diagnostic.reset(namespace, bufnr)
end

local function run_norminette_check(bufnr, namespace)
	vim.cmd("write")
	local filename = vim.api.nvim_buf_get_name(bufnr)
	async.run(function()
		local output = vim.fn.system("norminette " .. vim.fn.shellescape(filename))
		return output
	end, function(output)
		local diagnostics = parse_norminette_output(output)
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
	return file_type == "c" or file_type == "cpp" -- h is identified with cpp... idk why
end

local function get_function_size(bufnr, lnum)
	local start_line = lnum
	local end_line = lnum
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local brace_count = 0
	local in_function = false

	for i = lnum, 1, -1 do
		if lines[i]:match("{$") then
			brace_count = 1
			start_line = i
			in_function = true
			break
		end
	end

	if in_function then
		for i = start_line - 1, #lines do
			local line = lines[i]
			brace_count = brace_count + select(2, line:gsub("{", "")) - select(2, line:gsub("}", ""))
			if brace_count == -1 then
				end_line = i
				break
			end
		end
	end
	return end_line - start_line
end

local function update_function_sizes(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		if line:match("^%w+%s+[%w_*]+%s*%b()$") then
			local size = get_function_size(bufnr, i)
			vim.api.nvim_buf_set_extmark(bufnr, M.namespace, i - 1, 0, {
				virt_text = { { "Size :" .. size .. "lines", "Comment" } },
				virt_text_pos = "eol",
			})
		end
	end
end

local function toggle_norminette()
	if not correct_filetype() then
		print("Norminette only runs in .c or .h files")
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	M.toggle_state = not M.toggle_state
	if M.toggle_state then
		update_function_sizes(bufnr)
		vim.api.nvim_create_autocmd("CursorHold", {
			pattern = { "*.c", "*.h" },
			callback = function()
				run_norminette_check(bufnr, M.namespace)
			end,
			group = vim.api.nvim_create_augroup("NorminetteAutoCheck", { clear = true }),
		})
		print("NorminetteAutoCheck enable")
	else
		vim.api.nvim_clear_autocmds({ group = "NorminetteAutoCheck" })
		vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
		print("autocmd clear")
		clear_diagnostics(M.namespace, bufnr)
		print("NorminetteAutoCheck disable")
	end
	update_status()
end

function M.setup(opts)
	opts = opts or {}
	local default_opts = {
		keybind = "<leader>n",
		diagnostic_color = "#00ff00",
	}
	for k, v in pairs(default_opts) do
		if opts[k] == nil then
			opts[k] = v
		end
	end

	vim.api.nvim_set_hl(0, "NorminetteDiagnostic", { fg = opts.diagnostic_color })

	vim.api.nvim_create_user_command("Norminette", toggle_norminette, {})

	if opts.keybind then
		vim.keymap.set("n", opts.keybind, toggle_norminette, { noremap = true, silent = true })
	end
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
end

return M
