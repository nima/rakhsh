local t = require("types")

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {}
end

function M.lazy(): {PluginSpec}
  local spec = ({
    "stevearc/dressing.nvim",
    lazy = false,
    opts = {
      select = { backend = { "builtin" } },
      input = { enabled = true },
    },
  } as PluginSpec)

  return { spec }
end

return M
