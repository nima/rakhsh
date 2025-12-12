local t = require("core.types")
local cfg = require("core.config")
local splash = require("plugins.affordance.splash")
local louder = require("plugins.affordance.louder")
local folds = require("plugins.affordance.folds")

local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents

global vim: t.vim.Vim

--------------------------------------------------------------------------------

local record ColorizerOpts
  RGB: boolean
  RRGGBB: boolean
  names: boolean
  rgb_fn: boolean
  hsl_fn: boolean
  css: boolean
  css_fn: boolean
  mode: string
end

local record Colorizer
  setup: function({string}, ColorizerOpts): nil
end

--------------------------------------------------------------------------------

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.Naked,
      key = ";",
      rhs = folds.toggle,
      desc = "Toggle comment fold",
      tags = { T.TargetBuffer, T.ActionToggle },
      on = On.Immediate,
    },
  }
end

function M.init(): nil
  splash.setup()
  louder.setup()
  folds.setup()
end

function M.lazy(): {PluginSpec}
  local monokai_spec = ({
    "tanvirtin/monokai.nvim",
    priority = 1000,
    lazy = false,
    event = { "VimEnter" },
    config = function()
      local theme = cfg.colorschema
      local ok, _ = pcall(vim.cmd, "colorscheme " .. theme)
      if ok then return end
      vim.notify("colorscheme: '" .. theme .. "' not found (install theme plugin and restart)", vim.log.levels.ERROR, nil)
    end,
  } as PluginSpec)

  -- Theme alternatives (not dependencies; we select one at runtime)
  local catppuccin_spec = ({ "catppuccin/nvim" } as PluginSpec)
  local tokyonight_spec = ({ "folke/tokyonight.nvim" } as PluginSpec)
  local nightfox_spec   = ({ "EdenEast/nightfox.nvim" } as PluginSpec)
  local kanagawa_spec   = ({ "rebelot/kanagawa.nvim" } as PluginSpec)
  local rosepine_spec   = ({ "rose-pine/neovim" } as PluginSpec)


  local colorizer_spec = ({
    "norcalli/nvim-colorizer.lua",
    lazy = false,
    config = function()
      local _mod = "colorizer"
      local mod = (require(_mod) as Colorizer)
      mod.setup({ "*" }, {
        RGB    = true,
        RRGGBB = true,
        names  = false,
        rgb_fn = false,
        hsl_fn = false,
        css    = false,
        css_fn = false,
        mode   = "background",
      })
    end,
  } as PluginSpec)

  local devicons_spec = ({
    "nvim-tree/nvim-web-devicons",
  } as PluginSpec)

  return {
    monokai_spec,
    catppuccin_spec,
    tokyonight_spec,
    nightfox_spec,
    kanagawa_spec,
    rosepine_spec,
    colorizer_spec,
    devicons_spec,
  }
end

return M
