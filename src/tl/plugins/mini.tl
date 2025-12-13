local t = require("types")

global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local record MiniPairs
  setup: function({ string: any } | nil): nil
end

local record MiniSurround
  setup: function({ string: any } | nil): nil
end

local record MiniAI
  setup: function({ string: any } | nil): nil
end

local record MiniComment
  setup: function({ string: any } | nil): nil
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {}
end

function M.lazy(): {PluginSpec}
  local spec = ({
    "echasnovski/mini.nvim",
    lazy = false,
    config = function()
      local _mod: string
      _mod = "mini.pairs"
      (require(_mod) as MiniPairs).setup(nil)
      _mod = "mini.surround"
      (require(_mod) as MiniSurround).setup(nil)
      _mod = "mini.ai"
      (require(_mod) as MiniAI).setup(nil)
      _mod = "mini.comment"
      (require(_mod) as MiniComment).setup(nil)
    end,
  } as PluginSpec)

  return { spec }
end

return M
