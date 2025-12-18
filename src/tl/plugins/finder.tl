local t = require("types")
local keymaps = require("core.keymaps")

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
    { mode="n", role=R.Info,   key="?",  on=On.Immediate, rhs="<Cmd>Telescope keymaps<CR>", desc="[Telescope] Walk keymap listing",                    tags={ T.ActionHelp, T.TargetBuffer } },
    { mode="n", role=R.GoVia,  key="ff", on=On.Immediate, rhs="<Cmd>Telescope find_files<CR>", desc="[Telescope] Walk find files listing",             tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="fb", on=On.Immediate, rhs="<Cmd>Telescope file_browser<CR>", desc="[Telescope] File browser",                      tags={ T.ActionList, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="fr", on=On.Immediate, rhs="<Cmd>Telescope oldfiles<CR>", desc="[Telescope] Search Recent Files (MRU)",             tags={ T.ActionList, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="gg", on=On.Immediate, rhs="<Cmd>Telescope live_grep<CR>", desc="[Telescope] Search via grep",                      tags={ T.ActionSearch, T.TargetFile, T.ViaContent } },
    { mode="n", role=R.GoVia,  key="gw", on=On.Immediate, rhs="<Cmd>Telescope grep_string<CR>", desc="[Telescope] Search current word",                tags={ T.ActionSearch, T.TargetFile, T.ViaContent } },
    { mode="n", role=R.GoVia,  key="bb", on=On.Immediate, rhs="<Cmd>Telescope buffers<CR>", desc="[Telescope] Walk extant buffers",                    tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="bc", on=On.Immediate, rhs="<Cmd>Telescope current_buffer_fuzzy_find<CR>", desc="[Telescope] Search active buffer", tags={ T.ActionSearch, T.TargetBuffer, T.ViaContent } },
    { mode="n", role=R.SCM,    key="f",  on=On.Immediate, rhs="<Cmd>Telescope git_files<CR>", desc="[Telescope] Find files (git)",                     tags={ T.ActionSearch, T.TargetFile, T.ViaGit } },
    { mode="n", role=R.SCM,    key="m",  on=On.Immediate, rhs="<Cmd>Telescope git_status<CR>", desc="[Telescope] Repo modified files",                 tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.Select, key="h",  on=On.Immediate, rhs="<C-w><C-h>", desc="[Telescope] Move focus to the left window",                          tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.Select, key="l",  on=On.Immediate, rhs="<C-w><C-l>", desc="[Telescope] Move focus to the right window",                         tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.Select, key="j",  on=On.Immediate, rhs="<C-w><C-j>", desc="[Telescope] Move focus to the lower window",                         tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.Select, key="k",  on=On.Immediate, rhs="<C-w><C-k>", desc="[Telescope] Move focus to the upper window",                         tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="s",  on=On.Immediate, rhs="<Cmd>Telescope builtin<CR>", desc="[Telescope] [S]earch [S]elect Telescope",            tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="d",  on=On.Immediate, rhs="<Cmd>Telescope diagnostics<CR>", desc="[Telescope] Search diagnostics",                 tags={ T.ActionView, T.TargetFile } },
    { mode="n", role=R.GoVia,  key="r",  on=On.Immediate, rhs="<Cmd>Telescope resume<CR>", desc="[Telescope] Search resume",                           tags={ T.ActionView, T.TargetFile } },
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

  local ctrlp_spec = ({
    "ctrlpvim/ctrlp.vim",
    name = "ctrlp",
    lazy = false,
    config = function()
      keymaps.docmap("n", "<C-P>",  keymaps.opts("[CtrlP]", { T.ActionNavigate, T.TargetBuffer }))
    end,
  } as PluginSpec)

  return {
    telescope_spec,
    fzf_native_spec,
    ctrlp_spec,
  }
end

return M
