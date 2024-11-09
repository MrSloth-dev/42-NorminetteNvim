# 42-NorminetteNvim
This plugin allows to show the norminette errors inside your buffer, through diagnostics and it's compatible with quickfixlist!
It only works for `.c` and `.h` files.

![Demo](https://github.com/MrSloth-dev/42-NorminetteNvim/blob/main/Showcase/Showcase.gif?raw=true)
<br>
## Install

<details>
	
<summary> <b>📦 Packer 📦</b></summary>

``` lua
use {
    "MrSloth-dev/42-NorminetteNvim",
    requires = { "nvim-lua/plenary.nvim", "echasnovski/mini.icons" },
    config = function()
        require("norminette").setup({
	    norm_keybind = "<leader>n",
	    size_keybind = "<leader>ns",
            diagnostic_color = "#00ff00",
            show_size = true,
        })
    end,
}
```

</details>
<details>
<summary><b>💤 Lazy.nvim 💤</b></summary>

``` lua
{
	"MrSloth-dev/42-NorminetteNvim",
	dependencies = { "nvim-lua/plenary.nvim" , "echasnovski/mini.icons"},
	config = function()
		require("norminette").setup({
			norm_keybind = "<leader>n",
			size_keybind = "<leader>ns",
			diagnost_color = "#00ff00",
			show_size = true,
		})
	end,
},
```
</details>

## Dependecies

- [Neovim >= 0.10](https://neovim.io/)
- [Norminette (doh)](https://github.com/42School/norminette)
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for async.
- [mini.icons](https://github.com/echasnovski/mini.icons) for toggle icon.

## Usage

You can activate the toggle for Norm Errors in two ways : `:NorminetteToggle` or using the `<leader>n`, notice that you can change the keybind to your liking.

Along with the Norm you can also check function sizes with `:NorminetteSizeToggle` using the `<leader>ns`.

By default the plugin is running on a asynchronous process to prevent slowdowns. But if you find the constant errors popping up or notice a slowdown, try to disable it.

### Tip
To open a split with the quickfix list you can use a functionality of neovim and assign it to a keybind like
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

- [x] Detect functions through tree-sitter
- [x] Improve performance
- [ ] Auto-formatter for some of the errors.

## Changelog
All notable changes to this project will be documented in this file.

### [0.6] - 2024-11-09

#### Added
- Now you can toggle Function Sizes with `:NorminetteSizeToggle` or keybind (default `<leader>ns`)

#### Changed
- Showing Function size doesn't not depend if the Norminette diagnostics are turned on
- Turned Norminette and Function Sizes into two separate Toggles so that you can choose which you want to turn on and off.
- User Command `:Norminette` changed to `:NorminetteToggle`

#### BugFix
- There was an issue when Calling `:Norminette` that was calling a deprecated function

### [0.5.5] - 2024-09-30

#### BugFix
- Remade the function to calculate size, instead of Regex, now it uses [Neovim's TreeSitter](https://tree-sitter.github.io/tree-sitter/)
- Plugin wasn't showing the errors when activated, as pretended.

### [0.5] - 2024-09-25

#### Added
- Now it can show Function size as messages
- An icon in right side of status bar to know if the plugin is activated or not. May not work with other status line other than the default, if requested, I'll make it work.

#### Changed
- To reduce the workload the event that activated the functions were altered from "CursorHold" to "{ "TextChanged", "TextChangedI" }", so the diagnostics update when it detect changes is text.

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
