local t = require("core.types")
local cfg = require("core.config")

global vim: t.vim.Vim

--= 1. Disable legacy built-in plugins
vim.g.loaded_matchit = 1
vim.opt.shortmess:append("I")
vim.opt.swapfile = false

--= 2. Pure Core State
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.cmdheight = 0

--= 3. User Settings
vim.o.updatetime = 500
vim.o.more = false
vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.o.numberwidth = 3
vim.o.signcolumn = "yes:2"
vim.o.clipboard = "unnamedplus"
vim.o.mouse = "a"
vim.o.more = false

vim.opt.wrap = false
vim.opt.scrolloff = cfg.scrolloff

vim.g.mapleader = " "

local record AutocmdOpts
    group: integer
    pattern: string
    callback: function(): nil
end

local record AugroupOpts
    clear: boolean
end

local record NvimApi
    nvim_create_augroup: function(name: string, opts: AugroupOpts): integer
    nvim_create_autocmd: function(event: string, opts: AutocmdOpts): integer
end

local record FormatOptions
    remove: function(self: FormatOptions, items: {string}): nil
end

local api: NvimApi = vim.api as NvimApi

--Comment defaults
local group = api.nvim_create_augroup("rakhsh_auto_comments", { clear = true })
api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "*",
    callback = function(): nil
        local fo: FormatOptions = vim.opt_local.formatoptions as FormatOptions
        fo:remove({ "c", "r", "o" })
    end,
})
