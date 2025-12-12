local t = require("core.types")

global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

--------------------------------------------------------------------------------

local M: t.plugins.PluginModule = {}

function M.init(): nil
  return nil
end

function M.keymaps(): {PluginKeymap}
  return {}
end

function M.lazy(): {PluginSpec}
  local telescope_spec = ({
    "nvim-telescope/telescope.nvim",
    name = "telescope",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    config = function()
      local _mod = "telescope"
      local telescope = require(_mod) as t.telescope.Telescope

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
      } as t.telescope.TelescopeOpts)

      -- Optional: enable fzf native if installed
      pcall(telescope.load_extension, "fzf")

      -- nothing else — no keymaps here
    end,
  } as PluginSpec)

  local fzf_native_spec = ({
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  } as PluginSpec)

  return {
    telescope_spec,
    fzf_native_spec,
  }
end

return M