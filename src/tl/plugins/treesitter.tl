local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type TreeSitterOpts = { string: any }
local record TreeSitterMod
  setup: function(TreeSitterOpts): nil
  load_extension: function(string): nil
end

local type PluginSpec = t.plugins.PluginSpec
function M.lazy() : PluginSpec
  return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    keymaps = {},
    build = ":TSUpdate",
    opts = { ensure_installed = { "teal" }, },
    config = function()
      local _ = "nvim-treesitter.configs"
      local ts = (require(_) as TreeSitterMod)
      ts.setup({
        ensure_installed = { "c", "cpp", "python", "go", "lua", "bash" },
        highlight = { enable = true, disable = { "teal" } },
        indent    = { enable = true },
      })
    end
  } as PluginSpec
end

return M
