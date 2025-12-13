local t = require("types")

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local record CmpConfirmOpts
  select: boolean
end

local type MappingHandler = function(): nil

local record CmpMappingPreset
  insert: function({string: MappingHandler}): {string: MappingHandler}
end

local record CmpMapping
  preset: CmpMappingPreset
  complete: function(): MappingHandler
  confirm: function(CmpConfirmOpts): MappingHandler
end

local record CmpSource
  name: string
end

local record CmpSetupOpts
  mapping: {string: MappingHandler}
  sources: {CmpSource}
end

local record Cmp
  setup: function(CmpSetupOpts): nil
  mapping: CmpMapping
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {}
end

function M.lazy(): {PluginSpec}
  local cmp_spec = ({
    "hrsh7th/nvim-cmp",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      local _ = "cmp"
      local mod = (require(_) as Cmp)
      mod.setup({
        mapping = mod.mapping.preset.insert({
          ["<C-Space>"] = mod.mapping.complete(),
          ["<CR>"]      = mod.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer"   },
          { name = "path"     },
        },
      })
    end,
  } as PluginSpec)

  return { cmp_spec }
end

return M
