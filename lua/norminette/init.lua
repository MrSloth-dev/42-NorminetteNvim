local M = {}

M.version = "0.3"

M.dependencies = { "nvim-lua/plenary.nvim" }

M.auto_run = false

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

M.run_norminette = async.void(function()
	local bufnr = vim.api.nvim_get_current_buf()
	local namespace = vim.api.nvim_create_namespace("norminette")
	if M.auto_run then
		run_norminette_check(bufnr, namespace)
	else
		if diagnostics_exist(namespace, bufnr) then
			clear_diagnostics(namespace, bufnr)
			run_norminette_check(bufnr, namespace)
		else
			run_norminette_check(bufnr, namespace)
		end
	end
end)

function M.setup(opts)
	opts = opts or {}
	local default_opts = {
		auto_run = false,
		keybind = "<leader>n",
	}
	for k, v in pairs(default_opts) do
		if opts[k] == nil then
			opts[k] = v
		end
	end
	if opts.auto_run then
		vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
			pattern = { "*.c", "*.h" },
			callback = M.run_norminette,
		})
	end
	vim.api.nvim_create_user_command("Norminette", M.run_norminette, {})
	if opts.keybind then
		vim.keymap.set("n", opts.keybind, M.run_norminette, { noremap = true, silent = true })
	end
end

M.setup()

return M
