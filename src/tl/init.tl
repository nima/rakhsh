local t = require("core.types")
global vim: t.vim.Vim

-- Global theme selection (single source of truth)
vim.g.colorscheme = "monokai"
vim.g.colorscheme = "elflord"
vim.cmd("syntax on")
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.cmdheight = 0
vim.o.updatetime = 500

-- Core config
require("core.rakhsh")
require("core.options")
require("core.plugins")
require("core.terminal")

-- Extras
--require("extras.init")
--require("extras.linting")
--require("extras.comments")
--require("extras.folds")
--require("extras.cursor")
--require("extras.observer")
