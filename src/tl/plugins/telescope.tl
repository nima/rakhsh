local t = require("core.types")
local R = t.roles.Roles

local T = t.tags.Tags
local On = t.plugins.KeymapEvents

local keymaps: {t.plugins.PluginKeymap} = {
  { mode = "n", role = R.Power, key = "\\", rhs = "<cmd>Telescope keymaps<CR>", desc = "Show all keymaps", tags = { T.ActionHelp, T.SeekSearch, T.MethodFuzzy, T.TargetDialogue }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "ff", rhs = "<cmd>Telescope find_files<CR>", desc = "Find files (fs)", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "fb", rhs = "<cmd>Telescope file_browser<CR>", desc = "File browser", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "fr", rhs = "<cmd>Telescope oldfiles<CR>", desc = "Recent (MRU)", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile, T.PrioMRU }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "gg", rhs = "<cmd>Telescope live_grep<CR>", desc = "Search content (fuzzy)", tags = { T.ActionEdit, T.SeekSearch, T.BasisContent, T.MethodRegex, T.TargetFile }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "gr", rhs = "<cmd>Telescope grep_string<CR>", desc = "Search content (regex)", tags = { T.ActionEdit, T.SeekSearch, T.BasisContent, T.MethodRegex, T.TargetFile }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "bb", rhs = "<cmd>Telescope buffers<CR>", desc = "Buffers", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.TargetBuffer }, on = On.Immediate },
  { mode = "n", role = R.GoVia, key = "bc", rhs = "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search buffer", tags = { T.ActionEdit, T.SeekSearch, T.BasisContent, T.MethodFuzzy, T.TargetBuffer }, on = On.Immediate },
  { mode = "n", role = R.SCM,   key = "f",  rhs = "<cmd>Telescope git_files<CR>", desc = "Find files (git)", tags = { T.ActionList, T.SeekSearch, T.BasisName, T.MethodFuzzy, T.TargetFile, T.FilterGit }, on = On.Immediate },
  { mode = "n", role = R.SCM,   key = "s",  rhs = "<cmd>Telescope git_status<CR>", desc = "Repo modified files", tags = { T.ActionView, T.SeekActive, T.TargetFile, T.FilterGit, T.FilterGitModified }, on = On.Immediate },
}

local M: t.plugins.PluginModule = {}

function M.init(): nil
  local keymaps_mod = require("core.keymaps")
  local km = keymaps_mod

  for _, m in ipairs(keymaps) do
    if m.on == On.Immediate then
      km.safemap(
        m.mode,
        m.role,
        m.key,
        m.rhs,
        km.opts(m.desc, m.tags)  -- desc + tags are mandatory, matches your types
      )
    end
  end
end

return M
