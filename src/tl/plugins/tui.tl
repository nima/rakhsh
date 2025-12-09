local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

function M.lazy(): t.plugins.PluginSpec
  return {
    "stevearc/dressing.nvim",
    lazy = false,
    keymaps = {},
    opts = {
      select = { backend = { "builtin" } },
      input = { enabled = true },
    },
  } as t.plugins.PluginSpec
end

return M
