local t = require("core.types")
global vim: t.vim.Vim
local vimbo = vim.bo[0]

-- JSON
vimbo.expandtab   = true
vimbo.shiftwidth  = 2
vimbo.tabstop     = 2
vimbo.softtabstop = 2
