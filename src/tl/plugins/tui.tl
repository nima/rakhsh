local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  return {
    "stevearc/dressing.nvim",
    lazy = false,
    keymaps = {},
    opts = {
      select = { backend = { "builtin" } },
      input = { enabled = true },
    },
  } as PluginSpec
end

return M
