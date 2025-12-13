local t = require("types")
local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents

global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local record BufferlineModule
  setup: function(config: { string: any }): nil
end

local record BufferinModule
  setup: function(config: { string: any }): nil
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.GoVia,
      key = "<Tab>",
      rhs = "<cmd>Bufferin<CR>",
      desc = "Buffers: open buffer manager",
      tags = { T.ActionSelect, T.TargetBuffer, T.ViaDialogue },
      on = On.Immediate,
    },
    {
      mode = "n",
      role = R.Go,
      key = "n",
      rhs = "<cmd>BufferLineCycleNext<CR>",
      desc = "Buffers: next buffer (bufferline)",
      tags = { T.ActionNavigate, T.TargetBuffer },
      on = On.Immediate,
    },
    {
      mode = "n",
      role = R.Go,
      key = "p",
      rhs = "<cmd>BufferLineCyclePrev<CR>",
      desc = "Buffers: previous buffer (bufferline)",
      tags = { T.ActionNavigate, T.TargetBuffer },
      on = On.Immediate,
    },
  }
end

function M.lazy(): {PluginSpec}
  local bufferline_spec = ({
    "akinsho/bufferline.nvim",
    lazy = false,
    config = function(): nil
      local _mod = "bufferline"
      local bufferline = (require(_mod) as BufferlineModule)
      bufferline.setup({
        options = {
          mode = "buffers",               --+ show buffers, not tabpages
          numbers = "ordinal",            --+ true buffer ids visible
          show_buffer_close_icons = false,
          show_close_icon = false,
          diagnostics = "nvim_lsp",       --+ since using LSP
          separator_style = "thin",
        },
      })

      --+ bufferline needs termguicolors
      vim.opt.termguicolors = true
    end,
  } as PluginSpec)

  local bufferin_spec = ({
    "wasabeef/bufferin.nvim",
    lazy = false,
    config = function(): nil
      local _mod = "bufferin"
      local bufferin = (require(_mod) as BufferinModule)
      bufferin.setup({ show_window_layout = true })
    end,
  } as PluginSpec)

  return {
    bufferin_spec,
    bufferline_spec,
  }
end

return M
