local t = require("core.types")
local plugins = require("core.plugins")
local T = t.tags.Tags
local R = t.roles.Roles
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type GitSignsOpts = { string: any }
local record GitSigns
  setup: function(GitSignsOpts | nil): nil
  next_hunk: function(): nil
  prev_hunk: function(): nil
  preview_hunk: function(): nil
  blame_line: function(): nil
  toggle_current_line_blame: function(): nil
end

local record Neogit
  setup: function(any): nil
  open: function(any | nil): nil
end

local type PluginKeymap = t.plugins.PluginKeymap
local On = t.plugins.KeymapEvents
local _gs = "gitsigns"
local _ng = "neogit"
function M.lazy(): t.plugins.PluginSpec
  local function gs(): GitSigns return (require(_gs) as GitSigns) end
  local function ng(): Neogit return (require(_ng) as Neogit) end
  local km : { PluginKeymap } = {
    { mode = "n", role = R.Go,    key = "]", on = On.Attach, rhs = function() gs().next_hunk() end,                 tags = { T.ActionView, T.TargetBuffer },    desc = "Next git hunk"             },
    { mode = "n", role = R.Go,    key = "[", on = On.Attach, rhs = function() gs().prev_hunk() end,                 tags = { T.ActionView, T.TargetBuffer },    desc = "Prev git hunk"             },
    { mode = "n", role = R.GoVia, key = "p", on = On.Attach, rhs = function() gs().preview_hunk() end,              tags = { T.ActionView, T.TargetBuffer },    desc = "Preview git hunk"          },
    { mode = "n", role = R.SCM,   key = "b", on = On.Attach, rhs = function() gs().blame_line() end,                tags = { T.ActionView, T.TargetBuffer },    desc = "Git blame line"            },
    { mode = "n", role = R.SCM,   key = "B", on = On.Attach, rhs = function() gs().toggle_current_line_blame() end, tags = { T.ActionLaunch, T.TargetBuffer },  desc = "Toggle current line blame" },
    { mode = "n", role = R.SCM,   key = "s", on = On.Attach, rhs = function() ng().open(nil) end,                     tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit status"             },
    { mode = "n", role = R.SCM,   key = "c", on = On.Attach, rhs = function() ng().open({ "commit" }) end,            tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit commit"             },
  }
  return {
    "lewis6991/gitsigns.nvim",
    dependencies = {
      { "NeogitOrg/neogit", config = function() ng().setup({}) end },
    },
    event = { "BufReadPre", "BufNewFile" },
    lazy = false,
    keymaps = km,
    config = function()
      gs().setup({
        signs = {
          add          = { text = "+" },
          change       = { text = "~" },
          delete       = { text = "-" },
          topdelete    = { text = "-" },
          changedelete = { text = "~" },
          untracked    = { text = "·" },
        },
        current_line_blame = false,
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        --+ position: 'eol' | 'overlay' | 'right_align'
        current_line_blame_opts = { delay = 200, virt_text_pos = 'eol' },
        on_attach = function(bufnr: integer)
          plugins.apply_plugin_attach_keymaps("plugins.git", bufnr)
        end,
      })
    end,
  } as t.plugins.PluginSpec
end

return M
