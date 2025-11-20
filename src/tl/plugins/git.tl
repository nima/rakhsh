local t = require("core.types")
local R = t.roles.Roles
local T = t.tags.Tags
local u = require("core.utils")
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

local type PluginKeymap = t.plugins.PluginKeymap
local On = t.plugins.KeymapEvents
local tags_next_prev = { T.SeekActive, T.ActionView, T.TargetBuffer, T.FilterGitModified, T.FilterGit }
local tags_preview = { T.ActionView, T.TargetBuffer, T.FilterGitModified, T.FilterGit }
local tags_blame = { T.ActionView, T.TargetBuffer, T.BasisContent, T.FilterGit }
local tags_toggle = { T.ActionLaunch, T.TargetBuffer, T.FilterGit }
local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  local _mod = "gitsigns"
  local keymaps : { PluginKeymap } = {
    { mode = "n", role = R.Nav, key = "g]", rhs = function() (require(_mod) as GitSigns).next_hunk() end,
      desc = "Next git hunk", tags = tags_next_prev, on = On.Attach },
    { mode = "n", role = R.Nav, key = "g[", rhs = function() (require(_mod) as GitSigns).prev_hunk() end,
      desc = "Prev git hunk", tags = tags_next_prev, on = On.Attach },
    { mode = "n", role = R.Nav, key = "gp", rhs = function() (require(_mod) as GitSigns).preview_hunk() end,
      desc = "Preview git hunk", tags = tags_preview, on = On.Attach },
    { mode = "n", role = R.Nav, key = "gb", rhs = function() (require(_mod) as GitSigns).blame_line() end,
      desc = "Git blame line", tags = tags_blame, on = On.Attach },
    { mode = "n", role = R.Toggle, key = "gb", rhs = function() (require(_mod) as GitSigns).toggle_current_line_blame() end,
      desc = "Toggle current line blame", tags = tags_toggle, on = On.Attach },
  }
  return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    lazy = false,
    keymaps = keymaps,
    config = function()
      local mod = (require(_mod) as GitSigns)
      mod.setup({
        signs = {
          add          = { text = "+" },
          change       = { text = "~" },
          delete       = { text = "-" },
          topdelete    = { text = "-" },
          changedelete = { text = "~" },
          untracked    = { text = "·" },
        },
        current_line_blame = true,
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        --+ position: 'eol' | 'overlay' | 'right_align'
        current_line_blame_opts = { delay = 200, virt_text_pos = 'eol' },
        on_attach = function(bufnr: integer)
          u.apply_plugin_attach_keymaps("plugins.git", bufnr)
        end,
      })
    end,
  } as PluginSpec
end

return M
