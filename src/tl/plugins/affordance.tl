local t = require("types")
local cfg = require("core.config")

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
  return {}
end

function M.init(): nil
end

function M.lazy(): {PluginSpec}
  local rx_louder_spec = ({
    dir = "/opt/github/rakhsh/rx-louder",
    name = "rx-louder",
    lazy = true,
    event = "VeryLazy",
    dependencies = { "norcalli/nvim-colorizer.lua", "tanvirtin/monokai.nvim" },
    config = function()
      require("rx_louder").setup()
    end
  } as PluginSpec)

  local devicons_spec = ({ "nvim-tree/nvim-web-devicons" } as PluginSpec)

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

  local catppuccin_spec = ({ "catppuccin/nvim" } as PluginSpec)
  local tokyonight_spec = ({ "folke/tokyonight.nvim" } as PluginSpec)
  local nightfox_spec   = ({ "EdenEast/nightfox.nvim" } as PluginSpec)
  local kanagawa_spec   = ({ "rebelot/kanagawa.nvim" } as PluginSpec)
  local rosepine_spec   = ({ "rose-pine/neovim" } as PluginSpec)
  local monokai_spec = ({
    "tanvirtin/monokai.nvim",
    priority = 1000,
    lazy = false,
    config = function()
      local theme = cfg.colorschema
      if theme == nil or theme == "" then return end

      local applied = false
      local function apply_once(): nil
        if applied then return end
        applied = true
        pcall(vim.api.nvim_command, "colorscheme " .. theme)
      end

      --+ If already have UI, apply immediately...
      if #vim.api.nvim_list_uis() ~= 0 then apply_once() end

      --+ Register via UIEnter hook so headless server startup still gets theme
      --+ once UI attaches...
      local GROUP_NAME = "rakhsh_colorscheme"
      vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
      vim.api.nvim_create_autocmd("UIEnter", {
        group = GROUP_NAME,
        callback = function(_: vim.AutocmdCallbackData): any
          if #vim.api.nvim_list_uis() == 0 then return end
          apply_once()
        end,
        once = true,
      })
    end,
  } as PluginSpec)

  return {
    rx_louder_spec,
    colorizer_spec,
    devicons_spec,

    monokai_spec,
    catppuccin_spec,
    tokyonight_spec,
    nightfox_spec,
    kanagawa_spec,
    rosepine_spec,
  }
end

return M
