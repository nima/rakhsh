local t = require("types")
local R = t.roles.Roles
local T = t.tags.Tags

--------------------------------------------------------------------------------

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local record MiniSurroundModule
  setup: function(): nil
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.Power, key = "mq", rhs = "<Cmd>normal saiwq<CR>", desc = "Quote current word", tags = { T.ActionEdit, T.TargetCursor } },
    { mode = "n", role = R.Power, key = "mQ", rhs = "<Cmd>normal saiWq<CR>", desc = "Quote current WORD", tags = { T.ActionEdit, T.TargetCursor } },

    --! The next thre do not belong in here, move once they have a home
    { mode = "n", role = R.Power, key = "<F5>", rhs = "<Cmd>lua dofile(vim.fn.stdpath('config') .. '/init.lua')<CR>", desc = "Reload Rakhsh config", tags = { T.ActionView } },
    { mode = "n", role = R.Naked, key = "<C-Space>", rhs = "<Cmd>WhichKey<CR>", desc = "Show which-key menu", tags = { T.ActionView } },
    { mode = "n", role = R.Naked, key = "<C-c>", rhs = "<Cmd>:confirm bdelete<CR>", desc = "Quitall", tags = { T.ActionView } },
  }
end

function M.init(): nil
end

function M.lazy(): {PluginSpec}
  local _mini_surround_spec = "mini.surround"
  local mutants_spec = {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      (require(_mini_surround_spec) as MiniSurroundModule).setup()
    end,
  } as PluginSpec

  return {
    mutants_spec
  }
end

return M
