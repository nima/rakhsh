local u = require("core.utils")
local t = require("core.types")

--local R = t.roles.Roles
--local T = t.tags.Tags
global vim: t.vim.Vim

local type MyModuleOpts = { string: any }
local record MyModule
  setup: function(MyModuleOpts | nil): nil
  actio: function(): nil
end

local type PluginKeymap = t.plugins.PluginKeymap
--local On = t.plugins.KeymapEvents
--local tags = { T.SeekActive, T.ActionView }

local M: t.plugins.PluginModule = {}

function M.init(): nil
end

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  local _mod = "moduleName"
  local keymaps : { PluginKeymap } = {}
  return {
    "lewis6991/gitsigns.nvim",
    lazy = false,
    keymaps = keymaps,
    config = function()
      local mod = (require(_mod) as MyModule)
      mod.setup({
        on_attach = function(bufnr: integer)
          u.apply_plugin_attach_keymaps("plugins.git", bufnr)
        end,
      })
    end,
  } as PluginSpec
end

return M
