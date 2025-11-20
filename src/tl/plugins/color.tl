local t = require("core.types")

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

local M: t.plugins.PluginModule = {}

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  return {
    "norcalli/nvim-colorizer.lua",
    lazy = false,
    keymaps = {},
    config = function()
      local _ = "colorizer"
      local mod = (require(_) as Colorizer)
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
  } as PluginSpec
end

return M
