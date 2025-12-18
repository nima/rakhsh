local t = require("types")
local T = t.tags.Tags
local R = t.roles.Roles
local OnEvents = t.plugins.KeymapEvents

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local type WhichKeyOpts = { string: any }

local record WhichKey
  setup: function(WhichKeyOpts | nil): nil
  add: function(any, WhichKeyOpts | nil): nil
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.Info, key = "/", rhs = "<cmd>RakhshKeys<CR>", desc = "Rakhsh Hotkeys", tags = { T.ActionView, T.TargetDialogue }, on = OnEvents.Immediate },
  }
end

function M.lazy(): {PluginSpec}
  local spec = ({
    "folke/which-key.nvim",
    name = "which-key",
    cmd = "WhichKey",
    event = "VeryLazy",

    config = function()
      local _mod = "which-key"
      local wk = (require(_mod) as WhichKey)

      wk.setup({
        preset = "popup",
        win = {
          border = "rounded",
          title = true,
          title_pos = "center",
        },
      } as WhichKeyOpts)

      -- Manual native key descriptions
      wk.add({
        { "<C-]>", mode = "n", desc = "Jump to definition" },
        { "<C-^>", mode = "n", desc = "Toggle previous buffer" },
        { "<C-t>", mode = "n", desc = "Jump back" },
      }, nil)

      wk.add({
        { "<leader>?",  mode = "n", group = "Built-in keys" },
        { "<leader>?^", mode = "n", desc = "<C-^> – Toggle previous buffer" },
        { "<leader>?]", mode = "n", desc = "<C-]> – Jump to definition" },
        { "<leader>?t", mode = "n", desc = "<C-t> – Jump back" },
      }, nil)
    end,
  } as PluginSpec)

  return { spec }
end

return M
