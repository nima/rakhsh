local t = require("core.types")
local R = t.roles.Roles

local T = t.tags.Tags
local On = t.plugins.KeymapEvents


local M: t.plugins.PluginModule = {}
local type PluginKeymap = t.plugins.PluginKeymap

local type TelescopeOpts = { string: any }
local record Telescope
  setup: function(TelescopeOpts | nil): nil
  load_extension: function(string): nil
end

local type PluginSpec = t.plugins.PluginSpec
function M.lazy() : PluginSpec
  local keymaps: {PluginKeymap} = {
    { mode = "n", role = R.Power, key = "\\", rhs = "<cmd>Telescope keymaps<CR>", desc = "Show all keymaps", tags = { T.ActionHelp, T.SeekSearch, T.MethodFuzzy, T.TargetDialogue }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "ff", rhs = "<cmd>Telescope find_files<CR>", desc = "Find files (fs)", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "fg", rhs = "<cmd>Telescope git_files<CR>", desc = "Find files (git)", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile, T.FilterGit }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "fs", rhs = "<cmd>Telescope git_status<CR>", desc = "Repo modified files", tags = { T.ActionView, T.SeekActive, T.TargetFile, T.FilterGit, T.FilterGitModified }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "fb", rhs = "<cmd>Telescope file_browser<CR>", desc = "File browser", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "fr", rhs = "<cmd>Telescope oldfiles<CR>", desc = "Recent (MRU)", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile, T.PrioMRU }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "sg", rhs = "<cmd>Telescope live_grep<CR>", desc = "Search content (fuzzy)", tags = { T.ActionEdit, T.SeekSearch, T.BasisContent, T.MethodRegex, T.TargetFile }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "sr", rhs = "<cmd>Telescope grep_string<CR>", desc = "Search content (regex)", tags = { T.ActionEdit, T.SeekSearch, T.BasisContent, T.MethodRegex, T.TargetFile }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "bb", rhs = "<cmd>Telescope buffers<CR>", desc = "Buffers", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.TargetBuffer }, on = On.Immediate },
    { mode = "n", role = R.Nav,   key = "bc", rhs = "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search buffer", tags = { T.ActionEdit, T.SeekSearch, T.BasisContent, T.MethodFuzzy, T.TargetBuffer }, on = On.Immediate },
  }
  return {
    "nvim-telescope/telescope.nvim",
    lazy = false,
    cmd = "Telescope",
    keymaps = keymaps,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
    },
    config = function()
      local _mod = "telescope"
      local mod = (require(_mod) as Telescope)
      mod.setup({})
      mod.load_extension("file_browser")
    end,
  } as PluginSpec
end

return M
