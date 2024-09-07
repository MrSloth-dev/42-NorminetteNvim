# 42-NorminetteNvim
This plugin allows to show the norminette errors inside your buffer, through diagnostics and it's compatible with quickfixlist!
It only works for .c and .h files.

![Demo](https://github.com/MrSloth-dev/42-NorminetteNvim/blob/main/Showcase/Showcase.gif?raw=true)
<br>
## Install

At the moment only possible to install with packer(not rigorly tested) and with lazy.nvim package managers. If you need another way please make the request.

### Packer

```
use {
    'MrSloth-dev/42-NorminetteNvim',
    requires = {'nvim-lua/plenary.nvim'},
    config = function() require('norminette').setup() end
}
```
### Lazy.nvim

```
{
	"MrSloth-dev/42-NorminetteNvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
	require("norminette").setup({
	auto_run = true,
	keybind = "<leader>n",
	})
	end,
},
```

## Usage

By default the plugin is running on a asynchronous process to prevent slowdowns. But if you find the constant errors popping up or notice a slowdown, you can disable by making auto_run = false.

You can also run the command `:Norminette`

Tip: To open a split with the quickfix list you can use a functionality of neovim and assign it to a keybind like
```
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
```
This way you only need to press `<leader>q` and the split opens automatically.
