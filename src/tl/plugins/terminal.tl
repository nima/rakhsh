local t = require("types")
local R = t.roles.Roles
local T = t.tags.Tags

global vim: t.vim.Vim

local OnEvents = t.plugins.KeymapEvents
local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.Power,
      key = "`1",
      rhs = ":terminal zsh<CR>a",
      desc = "Zsh Terminal",
      tags = { T.ActionLaunch, T.TargetShell },
      on = OnEvents.Immediate,
    },
    {
      mode = "n",
      role = R.Power,
      key = "`2",
      rhs = ":terminal bash<CR>a",
      desc = "Bash Terminal",
      tags = { T.ActionLaunch, T.TargetShell },
      on = OnEvents.Immediate,
    },
  }
end

function M.lazy(): {PluginSpec}
  return {}
end

function M.init(): nil
  local aug = vim.api.nvim_create_augroup("rakhsh_terminal", { clear = true })

  vim.api.nvim_create_autocmd("TermOpen", {
    group = aug,
    callback = (function(ev: { string: any })
      local buf = ev.buf as integer
      vim.bo[buf].bufhidden = "hide"
      vim.bo[buf].modifiable = false
      vim.cmd("setlocal nospell")
      vim.cmd("setlocal nobuflisted")
      vim.cmd("setlocal nonumber norelativenumber")

      vim.api.nvim_create_autocmd("TermClose", {
        group = aug,
        buffer = buf,
        nested = true,
        once = true,
        callback = function(): nil
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end,
      })
    end) as t.vim.VimCallback,
  })
end

return M
