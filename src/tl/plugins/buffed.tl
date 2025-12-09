local t = require("core.types")
local keymaps = require("core.keymaps")
local T = keymaps.Tags
local R = keymaps.Roles
local On = t.plugins.KeymapEvents

global vim: t.vim.Vim

local record BufferlineModule
  setup: function(config: { string: any }): nil
end

local record BufferinModule
  setup: function(config: { string: any }): nil
end

local M: t.plugins.PluginModule = {}

function M.lazy(): t.plugins.PluginSpec
  return {
    "wasabeef/bufferin.nvim",
    lazy = false,

    dependencies = {
      "akinsho/bufferline.nvim",
      "nvim-tree/nvim-web-devicons",
    },

    keymaps = {
      {
        mode = "n",
        role = R.GoVia,
        key = "b",
        rhs = "<cmd>Bufferin<CR>",
        desc = "Buffers: open buffer manager",
        tags = { T.ActionInfo, T.TargetBuffer },
        on = On.Immediate,
      },
      {
        mode = "n",
        role = R.Go,
        key = "n",
        rhs = "<cmd>BufferLineCycleNext<CR>",
        desc = "Buffers: next buffer (bufferline)",
        tags = { T.ActionInfo, T.TargetBuffer },
        on = On.Immediate,
      },
      {
        mode = "n",
        role = R.Go,
        key = "p",
        rhs = "<cmd>BufferLineCyclePrev<CR>",
        desc = "Buffers: previous buffer (bufferline)",
        tags = { T.ActionInfo, T.TargetBuffer },
        on = On.Immediate,
      },
    },

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

      local _mod = "bufferin"
      local bufferin = (require(_mod) as BufferinModule)
      bufferin.setup({ show_window_layout = true, })

      --+ bufferline needs termguicolors
      vim.opt.termguicolors = true
    end,
  } as t.plugins.PluginSpec
end

return M
