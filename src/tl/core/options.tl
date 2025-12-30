local M = {}

function M.init(): nil
  local cfg = require("core.config")

  --+ vim.o is the global default for all future actions
  --+ vim.wo is the current window
  --+ vim.opt is the smart API that sets BOTH vim.o and vim.wo correctly

  --+ 1. Disable legacy built-in plugins
  vim.g.loaded_matchit = 1
  do
    local sm = vim.o.shortmess
    if not string.find(sm, "I", 1, true) then
      vim.o.shortmess = sm .. "I"
    end
  end
  vim.o.swapfile = false

  --+ 2. Pure Core State
  vim.o.laststatus = 3
  vim.o.showmode = false
  vim.o.cmdheight = 0

  --+ 3. User Settings
  vim.o.updatetime = 500
  vim.o.termguicolors = true
  vim.o.numberwidth = 3
  vim.o.signcolumn = "yes:2"
  vim.o.more = false
  vim.o.wrap = false
  vim.o.scrolloff = cfg.scrolloff
  vim.o.number = true
  vim.o.relativenumber = false

  vim.g.mapleader = " "

  --+ Limited Mouse -=[
  --vim.opt.clipboard = "unnamedplus"
  vim.o.mouse = "a"

  --+ Mouse-only: on left-button release (end of mouse selection), yank selection to system clipboard
  vim.keymap.set("v", "<LeftRelease>", function(): nil
    vim.cmd('normal! "+y')
    return nil
  end, { silent = true })
  -- ]=-

  --+ Comment defaults
  vim.api.nvim_create_augroup("rakhsh_auto_comments", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = "rakhsh_auto_comments",
    pattern = "*",
    callback = function(_: any): any
      local fo = vim.opt_local.formatoptions
      fo:remove("c")
      fo:remove("r")
      fo:remove("o")
      return nil
    end,
  })

  vim.api.nvim_create_augroup("rakhsh_line_numbers", { clear = true })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = "rakhsh_line_numbers",
    pattern = "*",
    callback = function(_: any): any
      if vim.bo.buftype ~= "" then return end
      if vim.bo.filetype == "rakhsh-splash" then return end
      vim.wo.number = vim.o.number
      vim.wo.relativenumber = vim.o.relativenumber
      vim.wo.fillchars = "eob:~"
      vim.api.nvim_set_hl(0, "EndOfBuffer", { link = "NonText" })
      vim.wo.foldmethod = "expr"
      vim.wo.foldexpr   = "v:lua.require('core.foldexpr').expr()"
      return nil
    end,
  })

  vim.notify("[core.options] LOADED", vim.log.levels.INFO, {})
end

return M
