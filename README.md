# NorminetteDiagnostics
This plugin allows to show the norminette errors inside your buffer!

## Install with Lazy.nvim
To install with Lazy.nvim just add the following code into your init.lua file

```
{
	"MrSloth-dev/NorminetteDiagnostics",
	config = function()
		require("norminette").setup()
		print("Norminette setup complete")
	end,
},

```

## Usage

