# 42-NorminetteNvim
This plugin allows to show the norminette errors inside your buffer, through diagnostics and it's compatible with quickfixlist!
It only works for `.c` and `.h` files.

![Demo](https://github.com/MrSloth-dev/42-NorminetteNvim/blob/main/Showcase/Showcase.gif?raw=true)
<br>
## Install

<details>
	
<summary> <b>📦 Packer 📦</b></summary>

```
use {
    "MrSloth-dev/42-NorminetteNvim",
    requires = { "nvim-lua/plenary.nvim", "echasnovski/mini.icons" },
    config = function()
        require("norminette").setup({
            keybind = "<leader>n",
            diagnostic_color = "#00ff00",
	    show_size = true,
        })
    end,
}
```

</details>
<details>
<summary><b>💤 Lazy.nvim 💤</b></summary>

```
{
	"MrSloth-dev/42-NorminetteNvim",
	dependencies = { "nvim-lua/plenary.nvim" , "echasnovski/mini.icons"},
	config = function()
		require("norminette").setup({
			keybind = "<leader>n",
			diagnost_color = "#00ff00",
			show_size = true,
		})
	end,
},
```
</details>

## Dependecies

- [Neovim >= 0.10](https://neovim.io/)
- [Norminette](https://github.com/42School/norminette)
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for async.
- [mini.icons](https://github.com/echasnovski/mini.icons) for toggle icon.

## Usage

You can activate the toggle two ways : `:Norminette` or using the `<leader>n`, notice that you can change the keybind to your liking.

By default the plugin is running on a asynchronous process to prevent slowdowns. But if you find the constant errors popping up or notice a slowdown, try to disable it.

Tip: To open a split with the quickfix list you can use a functionality of neovim and assign it to a keybind like
```
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
```
This way you only need to press `<leader>q` and the split opens automatically.
<br>

## Known Issues

- This plugin isn't working on 42's PCs through the flatpak.

To report a bug or ask for a feature, please open a [Github issue](https://github.com/MrSloth-dev/42-NorminetteNvim/issues/new)
<br>

## Roadmap

- [ ] Auto-formatter
- [ ] Improve performance
- [ ] Detect functions through tree-sitter

## Changelog
All notable changes to this project will be documented in this file.

### [0.5] - 2024-09-25

#### Added
- Now it can show Function size as messages

#### Changed
- The way that the plugin runs while the toggle in on to improve performance and reduce latency.
- The way that the plugin saves, to improve performance and reduce disk usage.

#### BugFix
- There was an error when the plugin was called through `:Norminette` that was calling an old function.

### [0.4] - 2024-09-19

#### Changed
- Reworked the way that the plugin works, now it's a toggle that you can turn on and [off](https://www.youtube.com/watch?v=p85xwZ_OLX0).
- Changed the bullet point in errors.

#### Added
- Symbol  in statusline to see if the toggle is on or off.
- Added diagnostic_color, not working (yet).

### [0.3] - 2024-09-07
  
In this version I added asynchronous task for the norminette so there won't be a slowdown
 
#### Fixed
On the previous version the toggle wasn't working properly because it wasn't clearning the diagnostics after running the command.
Still doesn't Work in 42 yet.

### [0.2] - 2024-09-06
  
In this version I added asynchronous task for the norminette so there won't be a slowdown
 
#### Changed
- Added [Plenary](https://github.com/nvim-lua/plenary.nvim) for async task for norminette. 

### [0.1] - 2024-08-28
 
### Added
   
- This is the first Version, it's working outside the 42's Computers.

## License
MIT
