local t = require("core.types")
global vim: t.vim.Vim
local vimbo = vim.bo[0]

-- Python
vimbo.expandtab   = true
vimbo.shiftwidth  = 4
vimbo.tabstop     = 4
vimbo.softtabstop = 4
