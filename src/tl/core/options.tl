local t = require("core.types")

global vim: t.vim.Vim

vim.o.number = true
vim.o.relativenumber = true
vim.o.termguicolors = true
vim.o.numberwidth = 3
vim.o.signcolumn = "yes:2"
vim.o.clipboard = "unnamedplus"
vim.o.mouse = "a"

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
