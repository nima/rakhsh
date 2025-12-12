local t = require("core.types")
local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local OnEvents = t.plugins.KeymapEvents
local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local type NvimTreeToggleOpts = { string: any }
local record NvimTreeToggle
  setup: function(NvimTreeToggleOpts): nil
  load_extension: function(string): nil
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.Toggle,
      key = "t",
      rhs = function() vim.cmd("NvimTreeToggle") end,
      desc = "File tree toggle",
      tags = { T.ActionView, T.TargetDialogue },
      on = OnEvents.Immediate,
    },
  }
end

function M.lazy(): {PluginSpec}
  local spec = ({
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    config = function()
      local _ = "nvim-tree"
      local mod = (require(_) as NvimTreeToggle)
      mod.setup({ view = { width = 40 } })
    end,
  } as PluginSpec)

  return { spec }
end

return M
