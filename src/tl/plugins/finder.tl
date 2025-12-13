local t = require("types")

global vim: t.vim.Vim

local On = t.plugins.KeymapEvents

local type R = t.roles.Roles
local type T = t.tags.Tags
local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

--------------------------------------------------------------------------------

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.Power, key = "\\", rhs = "<cmd>Telescope keymaps<CR>", desc = "Show all keymaps", tags = { T.ActionView, T.TargetDoc }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "ff", rhs = "<cmd>Telescope find_files<CR>", desc = "Find files (fs)", tags = { T.ActionSearch, T.TargetFile }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "fb", rhs = "<cmd>Telescope file_browser<CR>", desc = "File browser", tags = { T.ActionList, T.TargetFile }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "fr", rhs = "<cmd>Telescope oldfiles<CR>", desc = "Recent (MRU)", tags = { T.ActionList, T.TargetFile, T.ViaMRU }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "gg", rhs = "<cmd>Telescope live_grep<CR>", desc = "Search content (fuzzy)", tags = { T.ActionSearch, T.TargetFile, T.ViaContent }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "gr", rhs = "<cmd>Telescope grep_string<CR>", desc = "Search content (regex)", tags = { T.ActionSearch, T.TargetFile, T.ViaContent }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "bb", rhs = "<cmd>Telescope buffers<CR>", desc = "Buffers", tags = { T.ActionList, T.TargetBuffer }, on = On.Immediate },
    { mode = "n", role = R.GoVia, key = "bc", rhs = "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search buffer", tags = { T.ActionSearch, T.TargetBuffer, T.ViaContent }, on = On.Immediate },
    { mode = "n", role = R.SCM,   key = "f",  rhs = "<cmd>Telescope git_files<CR>", desc = "Find files (git)", tags = { T.ActionSearch, T.TargetFile, T.ViaGit }, on = On.Immediate },
    { mode = "n", role = R.SCM,   key = "m",  rhs = "<cmd>Telescope git_status<CR>", desc = "Repo modified files", tags = { T.ActionView, T.TargetFile }, on = On.Immediate },
  }
end

function M.init(): nil
  return nil
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

      pcall(function() telescope.load_extension("file_browser") end)
      pcall(function() telescope.load_extension("fzf") end)
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
