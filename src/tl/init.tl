local t = require("core.types")
global vim: t.vim.Vim

--= 1. Pure Core State
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.cmdheight = 0
vim.o.updatetime = 500
vim.o.more = false

--= 2. Core wiring (no plugin assumptions)
require("core.rakhsh")
require("core.options")
require("core.terminal")

--= 3. Plugin Systems (penultimate)
require("core.plugins")

--= 4. Post-Plugin Systems (ultimate)
local cursor = require("core.cursor")
cursor.init()
