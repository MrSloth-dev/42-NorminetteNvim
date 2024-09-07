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

You have 2 two ways of working with the plugin, with a toggle `<leader>n` or with auto_run enable `auto_run = true`
Notice that you can change the keybind to your liking.

By default the plugin is running on a asynchronous process to prevent slowdowns. But if you find the constant errors popping up or notice a slowdown, you can disable by making auto_run = false.

You can also run the command `:Norminette`

Tip: To open a split with the quickfix list you can use a functionality of neovim and assign it to a keybind like
```
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
```
This way you only need to press `<leader>q` and the split opens automatically.
## Issues

At the moment this plugin isn't working on 42's PCs maybe due to the location of the norminette binary. I will fix this ASAP.
If you find more issues or have sugestions you can open open an issue.
## [0.3] - 2024-08-07
  
In this version I added asynchronous task for the norminette so there won't be a slowdown
 
### Fixed
On the previous version the toggle wasn't working properly because it wasn't clearning the diagnostics after running the command.
Still doesn't Work in 42 yet.

## [0.2] - 2024-08-06
  
In this version I added asynchronous task for the norminette so there won't be a slowdown
 
### Changed
- Added [Plenary](https://github.com/nvim-lua/plenary.nvim) for async task for norminette. 

## [0.1] - 2024-08-28
 
### Added
   
This is the first Version, it's working outside the 42's Computers.
