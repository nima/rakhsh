local t = require("types")
local R = t.roles.Roles
local T = t.tags.Tags

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
  local GROUP_NAME = "rakhsh_terminal"
  vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

  local function buf_setopt(buf: integer, name: string, value: any): nil
    local opts = {} as { string: any }
    opts["buf"] = buf
    vim.api.nvim_set_option_value(name, value, opts)
  end

  vim.api.nvim_create_autocmd("TermOpen", {
    group = GROUP_NAME,
    callback = function(ev: vim.AutocmdCallbackData): any
      local buf = ev.buf as integer
      buf_setopt(buf, "bufhidden", "hide")
      buf_setopt(buf, "modifiable", false)

      vim.cmd.setlocal("nospell")
      vim.cmd.setlocal("nobuflisted")
      vim.cmd.setlocal("nonumber norelativenumber")

      vim.api.nvim_create_autocmd("TermClose", {
        group = GROUP_NAME,
        buffer = buf,
        nested = true,
        once = true,
        callback = function(_: vim.AutocmdCallbackData): any
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end,
      })
    end,
  })
end

return M
