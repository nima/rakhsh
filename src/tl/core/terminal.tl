local keymaps = require("core.keymaps")
local R = keymaps.Roles
local T = keymaps.Tags

local t = require("core.types")
global vim: t.vim.Vim

local M = {}

function M.init(): nil
  vim.api.nvim_create_autocmd("TermOpen", {
    callback = (function(ev: {string:any})
      local buf = ev.buf as integer
      vim.bo[buf].bufhidden = "hide"
      vim.bo[buf].modifiable = false
      vim.cmd("setlocal nospell")
      vim.cmd("setlocal nobuflisted")
      vim.cmd("setlocal nonumber norelativenumber")
      vim.cmd("autocmd TermClose <buffer> ++nested silent! bwipeout!")
    end) as t.vim.VimCallback
  })

  keymaps.safemap(
    "n",
    R.Power,
    "`1",
    ":terminal zsh<CR>a",
    keymaps.opts("Zsh Terminal", { T.ActionLaunch })
  )

  keymaps.safemap(
    "n",
    R.Power,
    "`2",
    ":terminal bash<CR>a",
    keymaps.opts("Bash Terminal", { T.ActionLaunch })
  )
end

return M
