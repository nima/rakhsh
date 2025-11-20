local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type PluginSpec = t.plugins.PluginSpec
function M.lazy() : PluginSpec
  return {
    "tanvirtin/monokai.nvim",
    priority = 1000,
    lazy = false,
    keymaps = {},
    dependencies = {
      "catppuccin/nvim",
      "folke/tokyonight.nvim",
      "EdenEast/nightfox.nvim",
      "rebelot/kanagawa.nvim",
      "rose-pine/neovim",
    },
    config = function()
      local theme = vim.g.colorscheme or "monokai"
      local ok, _ = pcall(vim.cmd, "colorscheme " .. theme)
      if not ok then
        vim.notify(
          "colorscheme: '" .. theme .. "' not found (install theme plugin and restart)",
          vim.log.levels.WARN,
          nil
        )
      end
    end
  } as PluginSpec
end

return M
