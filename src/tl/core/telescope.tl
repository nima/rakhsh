local t = require("core.types")

global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type PluginSpec = t.plugins.PluginSpec

local type TelescopeOpts = { string : any }
local record Telescope
  setup: function(TelescopeOpts | nil): nil
  load_extension: function(string): nil
end

function M.init(): nil
  return nil
end

function M.lazy(): PluginSpec
  return {
    "nvim-telescope/telescope.nvim",
    name = "telescope",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
      "nvim-tree/nvim-web-devicons",
    },

    build = "make",

    config = function()
      local _mod = "telescope"
      local telescope = require(_mod) as Telescope

      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
      } as TelescopeOpts)

      -- Optional: enable fzf native if you use it
      pcall(telescope.load_extension, "fzf")

      -- nothing else — no keymaps here
    end,
  } as PluginSpec
end

return M