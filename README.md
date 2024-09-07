# 42-NorminetteNvim
This plugin allows to show the norminette errors inside your buffer, through diagnostics and it's compatible with quickfixlist!

## Install with Lazy.nvim
To install with Lazy.nvim just add the following code into your init.lua file

```
{
	"MrSloth-dev/42-NorminetteNvim",
	config = function()
	require("norminette").setup({
	auto_run = true,
	keybind = "<leader>n",
	})
	end,
},
```

## Usage

