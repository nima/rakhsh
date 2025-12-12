local t = require("core.types")
local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local type NvimTreeToggleOpts = { string: any }
local record NvimTreeToggle
  setup: function(NvimTreeToggleOpts): nil
  load_extension: function(string): nil
end

local M: t.plugins.PluginModule = {}

local type PluginKeymap = t.plugins.PluginKeymap
local On = t.plugins.KeymapEvents
local tags = { T.ActionView, T.TargetDialogue }
function M.lazy(): t.plugins.PluginSpec
  local keymaps : { PluginKeymap } = {
    { mode = "n", role = R.Toggle, key = "t", rhs = function() vim.cmd("NvimTreeToggle") end,
      desc = "File tree toggle", tags = tags, on = On.Immediate },
  }
  return {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    keymaps = keymaps,
    config = function()
      local _ = "nvim-tree"
      local mod = (require(_) as NvimTreeToggle)
      mod.setup({ view = { width = 40 } })
    end,
  } as t.plugins.PluginSpec
end

return M
