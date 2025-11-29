local t = require("core.types")
local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents

global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

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

function M.lazy(): t.plugins.PluginSpec
  return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    keymaps = {
      {
        mode = "n",
        role = R.TUI,
        key = "i",
        rhs = install_here,
        desc = "TS: install parsers for this buffer",
        tags = { T.ActionInstall, T.TargetBuffer },
        on = On.Immediate,
      },
      {
        mode = "n",
        role = R.TUI,
        key = "?",
        rhs = "<cmd>split | TSModuleInfo<CR>",
        desc = "TS: module info",
        tags = { T.ActionInfo, T.TargetBuffer },
        on = On.Immediate,
      },
    },
    config = function(): ()
      local _cfg = "nvim-treesitter.configs"
      local cfg = (require(_cfg) as TreeSitterConfigsModule)
      cfg.setup({
        highlight = { enable = true, },
        indent = { enable = true, },
      })
    end,
    dependencies = {
      "teal-language/vim-teal",
    },
  } as t.plugins.PluginSpec
end

return M
