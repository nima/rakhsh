local t = require("core.types")

global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

function M.lazy(): t.plugins.PluginSpec
  return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    keymaps = {},
    dependencies = {
      "teal-language/vim-teal",
    },
  } as t.plugins.PluginSpec
end

return M
