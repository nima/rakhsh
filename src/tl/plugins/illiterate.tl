local t = require("types")
local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents
local d = require("plugins.dialogues")

global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local function install_here()
  local bufnr = vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  if ft == nil or ft == "" then return end

  -- Map filetype to treesitter language (handles aliases like javascriptreact -> tsx)
  local ok, lang = pcall(vim.treesitter.language.get_lang, ft)
  if not ok or lang == nil or lang == "" then return end

  -- Invoke the user-facing TSInstall command for this language
  local ok_cmd, err = pcall(vim.cmd, "TSInstall " .. lang)
  if not ok_cmd then
    vim.notify("[TreeSitter] `:TSInstall " .. lang .. "` FAILED: " .. tostring(err), vim.log.levels.ERROR, nil)
  else
    vim.notify("[Treesitter] `:TSInstall " .. lang .. "` COMPLETE", vim.log.levels.INFO, nil)
  end
end

local record TreeSitterConfigsModule
  setup: function(config: { string: any }): nil
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.TUI,
      key = "i",
      rhs = install_here,
      desc = "[TreeSitter] Install parsers for this buffer",
      tags = { T.ActionLaunch, T.TargetBuffer },
      on = On.Immediate,
    },
    {
      mode = "n",
      role = R.TUI,
      key = "?",
      rhs = function() d.open_popup_with_cmd_sandboxed("TSModuleInfo") end,
      desc = "[TreeSitter]: Module info",
      tags = { T.ActionView, T.TargetBuffer },
      on = On.Immediate,
    },
  }
end

function M.lazy(): {PluginSpec}
  local treesitter_spec = ({
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function(): nil
      local _cfg = "nvim-treesitter.configs"
      local cfg = (require(_cfg) as TreeSitterConfigsModule)
      cfg.setup({
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  } as PluginSpec)

  local teal_spec = ({
    "teal-language/vim-teal",
    lazy = false,
  } as PluginSpec)

  return {
    treesitter_spec,
    teal_spec,
  }
end

return M
