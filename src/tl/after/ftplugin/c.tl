local vimbo = vim.bo

-- C / C++
vimbo.expandtab   = true
vimbo.shiftwidth  = 4
vimbo.tabstop     = 4
vimbo.softtabstop = 4
vimbo.cindent     = true
vimbo.cinoptions  = "g0,h2,t0"

vim.opt_local.iskeyword:append("$")
