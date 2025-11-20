local t = require("core.types")
local R = t.roles.Roles
local T = t.tags.Tags

local M: t.plugins.PluginModule = {}

local keymaps = {
  { mode = "n", role = R.Win, key = "<C-F5>", rhs = "<cmd>lua dofile(vim.fn.stdpath('config') .. '/init.lua')<CR>",
    desc = "Reload Rakhsh config", tags = { T.ActionView } },
  { mode = "n", role = R.Win, key = "<C-Space>", rhs = "<cmd>WhichKey<CR>",
    desc = "Show which-key menu", tags = { T.ActionView } },
}

local type WhichKeyOpts = { string: any }
local record WhichKey
  setup: function(WhichKeyOpts | nil): nil
  -- add(mappings, opts?)
  add: function(any, WhichKeyOpts | nil): nil
end

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  return {
    "folke/which-key.nvim",
    name = "which-key",
    cmd = "WhichKey",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "echasnovski/mini.icons",
    },
    config = function()
      local _mod = "which-key"
      local wk = (require(_mod) as WhichKey)
      wk.setup({
        preset = "popup",
        win = {
          border = "rounded",
          title = true,
          title_pos = "center",
        },
      } as WhichKeyOpts)

      -- Register Rakhsh-generated keymaps
      --local nm = require("core.utils").get_all_rakhsh_keymaps()
      --wk.add(nm)

      -- Add manual native bindings (new which-key v3-style spec)
      wk.add({
        { "<C-]>", desc = "Jump to definition", mode = "n" },
        { "<C-^>", desc = "Toggle previous buffer", mode = "n" },
        { "<C-t>", desc = "Jump back", mode = "n" },
      }, nil)
      wk.add({
	  { "<leader>?", group = "Built-in keys", mode = "n" },
	  { "<leader>?^", desc = "<C-^> – Toggle previous buffer", mode = "n" },
	  { "<leader>?]", desc = "<C-]> – Jump to definition",     mode = "n" },
	  { "<leader>?t", desc = "<C-t> – Jump back",               mode = "n" },
	}, nil)
    end,
    keymaps = keymaps,  -- handled in config
  } as PluginSpec
end

return M
