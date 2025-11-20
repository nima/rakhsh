local t = require("core.types")
global vim: t.vim.Vim
local vimbo = vim.bo[0]

-- Makefile
vimbo.expandtab   = false
vimbo.shiftwidth  = 4
vimbo.tabstop     = 4
vimbo.softtabstop = 4

vim.opt_local.iskeyword:append("-")