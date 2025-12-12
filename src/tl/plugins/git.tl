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
  stage_hunk: function(any | nil): nil
  reset_hunk: function(any | nil): nil
  undo_stage_hunk: function(): nil
  diffthis: function(any | nil): nil
  toggle_word_diff: function(): nil
  toggle_linehl: function(): nil
  toggle_deleted: function(): nil
end

local record Neogit
  setup: function(any): nil
  open: function(any | nil): nil
end

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local OnEvents = t.plugins.KeymapEvents

local function gs(): GitSigns
  local _mod = "gitsigns"
  return (require(_mod) as GitSigns)
end

local function ng(): Neogit
  local _mod = "neogit"
  return (require(_mod) as Neogit)
end

function M.keymaps(): {PluginKeymap}
  return {
    -- gitsigns (buffer-attached)
    { mode = "n", role = R.Go,    key = "]", on = OnEvents.Attach, rhs = function() gs().next_hunk() end,                  tags = { T.ActionView, T.TargetBuffer },   desc = "Next git hunk"             },
    { mode = "n", role = R.Go,    key = "[", on = OnEvents.Attach, rhs = function() gs().prev_hunk() end,                  tags = { T.ActionView, T.TargetBuffer },   desc = "Prev git hunk"             },
    { mode = "n", role = R.GoVia, key = "p", on = OnEvents.Attach, rhs = function() gs().preview_hunk() end,               tags = { T.ActionView, T.TargetBuffer },   desc = "Preview git hunk"          },
    { mode = "n", role = R.SCM,   key = "b", on = OnEvents.Attach, rhs = function() gs().blame_line() end,                 tags = { T.ActionView, T.TargetBuffer },   desc = "Git blame line"            },
    { mode = "n", role = R.SCM,   key = "B", on = OnEvents.Attach, rhs = function() gs().toggle_current_line_blame() end,  tags = { T.ActionLaunch, T.TargetBuffer }, desc = "Toggle current line blame" },

    -- gitsigns (stage/reset)
    { mode = "n", role = R.SCM,   key = "S",  on = OnEvents.Attach, rhs = function() gs().stage_hunk(nil) end,      tags = { T.ActionEdit,   T.TargetBuffer }, desc = "Stage hunk" },
    { mode = "n", role = R.SCM,   key = "X",  on = OnEvents.Attach, rhs = function() gs().reset_hunk(nil) end,      tags = { T.ActionEdit,   T.TargetBuffer }, desc = "Reset hunk" },
    { mode = "n", role = R.SCM,   key = "U",  on = OnEvents.Attach, rhs = function() gs().undo_stage_hunk() end,    tags = { T.ActionEdit,   T.TargetBuffer }, desc = "Undo stage hunk" },

    -- gitsigns (visual range)
    { mode = "v", role = R.SCM,   key = "S",  on = OnEvents.Attach, rhs = function() gs().stage_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, tags = { T.ActionEdit, T.TargetBuffer }, desc = "Stage selected hunk" },
    { mode = "v", role = R.SCM,   key = "X",  on = OnEvents.Attach, rhs = function() gs().reset_hunk({ vim.fn.line('.'), vim.fn.line('v') }) end, tags = { T.ActionEdit, T.TargetBuffer }, desc = "Reset selected hunk" },

    -- gitsigns (diff + visuals)
    { mode = "n", role = R.GoVia, key = "D",  on = OnEvents.Attach, rhs = function() gs().diffthis(nil) end,        tags = { T.ActionView,   T.TargetBuffer }, desc = "Diff this buffer" },
    { mode = "n", role = R.Toggle,key = "gw", on = OnEvents.Attach, rhs = function() gs().toggle_word_diff() end,    tags = { T.ActionToggle, T.TargetBuffer }, desc = "Toggle word diff" },
    { mode = "n", role = R.Toggle,key = "gh", on = OnEvents.Attach, rhs = function() gs().toggle_linehl() end,       tags = { T.ActionToggle, T.TargetBuffer }, desc = "Toggle line highlight" },
    { mode = "n", role = R.Toggle,key = "gd", on = OnEvents.Attach, rhs = function() gs().toggle_deleted() end,      tags = { T.ActionToggle, T.TargetBuffer }, desc = "Toggle deleted lines" },

    -- neogit (global)
    { mode = "n", role = R.SCM,   key = "s", on = OnEvents.Immediate, rhs = function() ng().open(nil) end,                  tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit status"             },
    { mode = "n", role = R.SCM,   key = "c", on = OnEvents.Immediate, rhs = function() ng().open({ "commit" }) end,        tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit commit"             },
    { mode = "n", role = R.SCM,   key = "gb", on = OnEvents.Immediate, rhs = function() ng().open({ "branch" }) end, tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit branch" },
    { mode = "n", role = R.SCM,   key = "gl", on = OnEvents.Immediate, rhs = function() ng().open({ "log" }) end,    tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit log" },
    { mode = "n", role = R.SCM,   key = "gt", on = OnEvents.Immediate, rhs = function() ng().open({ "stash" }) end,  tags = { T.ActionLaunch, T.TargetProject }, desc = "Neogit stash" },
  }
end

function M.lazy(): {PluginSpec}
  local gitsigns_spec = ({
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    lazy = false,
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
  } as PluginSpec)

  local neogit_spec = ({
    "NeogitOrg/neogit",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      ng().setup({})
    end,
  } as PluginSpec)

  return {
    gitsigns_spec,
    neogit_spec,
  }
end

return M
