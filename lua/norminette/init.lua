local M = {}

M.version = "0.5"

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

local function diagnostics_exist(namespace, bufnr)
	local diagnostics = vim.diagnostic.get(bufnr, { namespace = namespace })
	return #diagnostics > 0
end

local function run_norminette_check(bufnr, namespace)
	if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
		vim.api.nvim_command("silent update")
	end
	-- vim.cmd("write")
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

local function update_function_sizes(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
	local parser = vim.treesitter.get_parser(bufnr, "c")
	if not parser then
		print("Failed Parsing")
		return
	end
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = vim.treesitter.query.parse(
		"c",
		[[
        (function_definition) @declaration
    ]]
	)
	for _, node in query:iter_captures(root, bufnr, 0, -1) do
		local start_row, _, end_row, _ = node:range()
		local size = end_row - start_row - 2

		vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, 0, {
			virt_text = { { "Size: " .. size .. " lines", "Comment" } },
			virt_text_pos = "eol",
		})
	end
end

local function setup_autocmds_and_run(bufnr)
	if M.show_size then
		update_function_sizes(bufnr)
		run_norminette_check(bufnr, M.namespace)
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
			pattern = { "*.c", ".h" },
			callback = function()
				update_function_sizes(bufnr)
			end,
			group = vim.api.nvim_create_augroup("NorminetteFunctionSize", { clear = true }),
		})
	end
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufEnter", "BufWritePost" }, {
		pattern = { "*.c", "*.h" },
		callback = function()
			run_norminette_check(bufnr, M.namespace)
		end,
		group = vim.api.nvim_create_augroup("NorminetteAutoCheck", { clear = true }),
	})
end

local function clear_autocmds_and_messages(bufnr)
	vim.api.nvim_clear_autocmds({ group = "NorminetteFunctionSize" })
	vim.api.nvim_clear_autocmds({ group = "NorminetteAutoCheck" })
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
	clear_diagnostics(M.namespace, bufnr)
end

local function toggle_norminette()
	local bufnr = vim.api.nvim_get_current_buf()
	M.toggle_state = not M.toggle_state
	if M.toggle_state then
		setup_autocmds_and_run(bufnr)
		print("NorminetteAutoCheck enable")
	else
		clear_autocmds_and_messages(bufnr)
		print("NorminetteAutoCheck disable")
	end
	update_status()
end

M.run_norminette = async.void(function()
	local bufnr = vim.api.nvim_get_current_buf()
	local namespace = vim.api.nvim_create_namespace("norminette")
	if M.toggle_state then
		run_norminette_check(bufnr, namespace)
	else
		if diagnostics_exist(namespace, bufnr) then
			clear_diagnostics(namespace, bufnr)
		else
			run_norminette_check(bufnr, namespace)
		end
	end
end)

function M.setup(opts)
	opts = opts or {}
	local default_opts = {
		keybind = "<leader>n",
		diagnostic_color = "#00ff00",
		show_size = true,
	}
	for key, value in pairs(default_opts) do
		if opts[key] == nil then
			opts[key] = value
		end
	end

	M.show_size = opts.show_size
	if opts.keybind then
		vim.keymap.set("n", opts.keybind, toggle_norminette, { noremap = true, silent = true })
	end

	vim.api.nvim_set_hl(0, "NorminetteDiagnostic", { fg = opts.diagnostic_color })
	vim.api.nvim_create_user_command("Norminette", M.run_norminette, {})

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

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.c", "*.h" },
		callback = function()
			if M.toggle_state then
				M.run_norminette()
			end
		end,
		group = vim.api.nvim_create_augroup("NorminetteInitialUpdate", { clear = true }),
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = { "*.c", "*.h" },
		callback = function(ev)
			if M.toggle_state and M.show_size then
				update_function_sizes(ev.buf)
			end
		end,
		group = vim.api.nvim_create_augroup("NorminetteInitialUpdate", { clear = true }),
	})
end

return M
