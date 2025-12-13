local t = require("types")
local cfg = require("core.config")

global vim: t.vim.Vim

--+ vim.o is the global default for all future actions
--+ vim.wo is the current window
--+ vim.opt is the smart API that sets BOTH vim.o and vim.wo correctly

--= 1. Disable legacy built-in plugins
vim.g.loaded_matchit = 1
vim.opt.shortmess:append("I")
vim.opt.swapfile = false

--= 2. Pure Core State
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.cmdheight = 0

--= 3. User Settings
vim.opt.updatetime = 500
vim.opt.termguicolors = true
vim.opt.numberwidth = 3
vim.opt.signcolumn = "yes:2"
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.more = false
vim.opt.wrap = false
vim.opt.scrolloff = cfg.scrolloff
vim.opt.number = true
vim.opt.relativenumber = true

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

local line_group = api.nvim_create_augroup("rakhsh_line_numbers", { clear = true })
api.nvim_create_autocmd("BufWinEnter", {
  group = line_group,
  pattern = "*",
  callback = function(): nil
    if vim.bo[0].buftype ~= "" then return end 
    if vim.bo[0].filetype == "rakhsh-splash" then return end
    vim.wo[0].number = true
    vim.wo[0].relativenumber = true
    vim.wo[0].fillchars = "eob:~"
    vim.api.nvim_set_hl(0, "EndOfBuffer", { link = "NonText" })
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr   = "v:lua.require('core.foldexpr').expr()"
  end,
})

vim.notify("[core.options] LOADED", vim.log.levels.INFO, {})
