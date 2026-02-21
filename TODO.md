```lua
vim.keymap.set("n", "<leader>fp", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Copy full file path" })
```

```lua
:messages
[core.options] LOADED
diagnostics_update_in_insert is deprecated, use vim.diagnostic.config { update_in_insert = true } instead.
Feature will be removed in bufferline 4.6.3
stack traceback:
        ...re/rakhsh/lazy/bufferline.nvim/lua/bufferline/config.lua:68: in function <...re/rakhsh/lazy/bufferline.nvim/lua/bufferline/config.lua:67>
Press ENTER or type command to continue
```
