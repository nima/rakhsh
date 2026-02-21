local t = require("types")
local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents
local d = require("plugins.dialogues")

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

-- Minimal TreeSitter typing shim (extern neovim types do not expose `vim.treesitter`).
local record TsLanguage
  get_lang: function(ft: string): string
end

local record Ts
  language: TsLanguage
end

local function ts(): Ts
  -- Single boundary cast: extern `vim` type doesn't include `treesitter`.
  -- Use string-key indexing so Teal doesn't require a structural type for `vim`.
  local v = (vim as { string: any })
  return (v["treesitter"] as Ts)
end

local function install_here()
  local bufnr = (vim.api.nvim_get_current_buf() as integer)
  local ft = (vim.api.nvim_get_option_value("filetype", ({ buf = bufnr } as vim.GetOptionValueOpts)) as string)
  if ft == nil or ft == "" then return end

  -- Map filetype to treesitter language (handles aliases like javascriptreact -> tsx)
  local ok, lang_any = pcall(function(): any
    return ts().language.get_lang(ft)
  end)
  if not ok then return end
  local lang = (lang_any as string)
  if lang == "" then return end

  -- Invoke the user-facing TSInstall command for this language
  ok = pcall(vim.api.nvim_command, "TSInstall " .. lang)
  --[[
  if not ok then
    vim.notify("[TreeSitter] `:TSInstall " .. lang .. "` FAILED: " .. tostring(err), vim.log.levels.ERROR, nil)
  else
    vim.notify("[Treesitter] `:TSInstall " .. lang .. "` COMPLETE", vim.log.levels.INFO, nil)
  end
  ]]
  --! TODO fix error missing from ^^
end

local record TreeSitterConfigsModule
  setup: function(config: { string: any }): nil
end

local record DocCommentTagsModule
  setup: function(cfg: { string: any } | nil): nil
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
      local _cfg = "nvim-treesitter.config"
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

  local doccomment_tags_spec = ({
    "Blackcyan30/nvim-doccomment-tags",
    lazy = false,
    config = function(): nil
      local _cfg = "nvim-doccomment-tags.doccomment-tags"
      local mod = (require(_cfg) as DocCommentTagsModule)
      mod.setup(nil)
    end,
  } as PluginSpec)

  return {
    treesitter_spec,
    teal_spec,
    doccomment_tags_spec,
  }
end

return M
