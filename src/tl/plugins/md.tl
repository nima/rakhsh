local t = require("core.types")

local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type MarkdownTableOpts = { string: any }
local record MarkdownTable
  setup: function(MarkdownTableOpts | nil): nil
end

local type PluginKeymap = t.plugins.PluginKeymap
local On = t.plugins.KeymapEvents

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  local keymaps : { PluginKeymap } = {
    { mode = "n", role = R.Toggle, key = "m", rhs = "<cmd>Mtm<CR>", on = On.Immediate,
      desc = "Toggle markdown table mode", tags = { T.ActionView, T.TargetBuffer } },
  }
  local function config(): nil
    local _mod = "markdown-table-mode"
    local mod = (require(_mod) as MarkdownTable)
    mod.setup(nil)
  end
  return {
    "Kicamon/markdown-table-mode.nvim",
    lazy = false,
    config = config,
    keymaps = keymaps,
  } as PluginSpec
end

return M
