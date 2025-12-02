local t = require("core.types")
local cfg = require("core.config")
global vim: t.vim.Vim

--= 0. Disable legacy built-in plugins
vim.g.loaded_matchit = 1

--= 1. Pure Core State
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.cmdheight = 0

--= 2. User Settings
vim.o.updatetime = 500
vim.o.more = false
vim.opt.wrap = false
vim.opt.scrolloff = cfg.scrolloff

--= 3. Core wiring (no plugin assumptions)
require("core.rakhsh")
require("core.options")
require("core.terminal")

--= 4. Plugin Systems (penultimate)
require("core.plugins")

--= 5. Post-Plugin Systems (ultimate)
local cursor = require("core.cursor")
cursor.init()
