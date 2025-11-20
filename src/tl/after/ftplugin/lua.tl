local t = require("core.types")
global vim: t.vim.Vim
local vimbo = vim.bo[0]

-- Lua
vim.opt.modeline = false
vim.opt.modelines = 0
vim.opt.modelineexpr = false
vimbo.expandtab   = true
vimbo.shiftwidth  = 2
vimbo.tabstop     = 2
vimbo.softtabstop = 2
