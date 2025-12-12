local t = require("core.types")

local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type MarkdownTableOpts = { string: any }
local record MarkdownTable
  setup: function(MarkdownTableOpts | nil): nil
end

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local OnEvents = t.plugins.KeymapEvents

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.Toggle, key = "m", rhs = "<cmd>Mtm<CR>", on = OnEvents.Immediate,
      desc = "Toggle markdown table mode", tags = { T.ActionView, T.TargetBuffer } },
  }
end

function M.lazy(): {PluginSpec}
  local function config(): nil
    local _mod = "markdown-table-mode"
    local mod = (require(_mod) as MarkdownTable)
    mod.setup(nil)
  end

  local spec = ({
    "Kicamon/markdown-table-mode.nvim",
    lazy = false,
    config = config,
  } as PluginSpec)

  return { spec }
end

return M
