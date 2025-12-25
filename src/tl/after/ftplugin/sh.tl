local vimbo = vim.bo

-- Shell scripts
vimbo.expandtab   = true
vimbo.shiftwidth  = 2
vimbo.tabstop     = 2
vimbo.softtabstop = 2

vim.opt_local.iskeyword:append("-")
vim.opt_local.iskeyword:append(":")
