local c = require("core.config")
local t = require("core.types")

global vim: t.vim.Vim

local record TSHighlightOpts
  enable: boolean
  disable: {string}
  additional_vim_regex_highlighting: {string} | boolean
end

local record TSIndentOpts
  enable: boolean
end

local record TreeSitterOpts
  ensure_installed: {string}
  ignore_install: {string}
  highlight: TSHighlightOpts
  indent: TSIndentOpts
end

local record TreeSitter
  setup: function(TreeSitterOpts): nil
end

local M: t.plugins.PluginModule = {}

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    keymaps = {},
    dependencies = {
      "teal-language/vim-teal",
    },
    build = function()
      vim.notify("[treesitter] Updating parsers…", vim.log.levels.INFO, { timeout = 8000, title = "treesitter" })

      vim.fn.jobstart(
        { "nvim", "--headless", "+TSUpdateSync", "+qa" },
        {
          on_exit = function(_, code, _)
            if code == 0 then
              vim.notify("[treesitter] Parsers up to date ✔", vim.log.levels.INFO, { timeout = 8000, title = "treesitter" })
            else
              vim.notify(
                "[treesitter] TSUpdate failed (exit " .. tostring(code) .. ")",
                vim.log.levels.ERROR,
                { timeout = 10000, title = "treesitter" }
              )
            end
          end,
        }
      )
    end,
    config = function()
      local _cfg = "nvim-treesitter.configs"
      local cfg = (require(_cfg) as TreeSitter)
      cfg.setup({
        ensure_installed = c.filetypes(),
        ignore_install   = { "teal" },
        highlight        = { enable = true, additional_vim_regex_highlighting = { "teal" } },
        indent           = { enable = true },
      })
    end
  } as PluginSpec
end

return M
