local t = require("core.types")

local type TreeSitterOpts = { string : any }
local record TreeSitter
  setup: function(TreeSitterOpts): nil
end

local M: t.plugins.PluginModule = {}

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  local options: TreeSitterOpts = {
    highlight = { enable = true },
    ensure_installed = { "lua" },
    ignore_install = { "teal" },
  }
  return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    keymaps = {},
    dependencies = {
      "teal-language/vim-teal",
    },
    build = ":TSUpdate",
    opts = options,
    config = function(_, opts: TreeSitterOpts)
      local mod = "nvim-treesitter.configs"
      (require(mod) as TreeSitter).setup(opts)
    end,
  } as PluginSpec
end

return M
