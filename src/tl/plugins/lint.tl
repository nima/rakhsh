-- Editor-side linting helpers: trailing whitespace, etc.
local c = require("core.config")
local t = require("types")
local T = t.tags.Tags
local R = t.roles.Roles
global vim: t.vim.Vim

local OnEvents = t.plugins.KeymapEvents
local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.Power,
      key = "w",
      rhs = [[mz:%s/\s\+$//e<CR>`z]],
      desc = "Strip trailing whitespace",
      tags = { T.TargetBuffer, T.ActionEdit },
      on = OnEvents.Immediate,
    },
  }
end

local trailing_ws_match_id: integer | nil = nil

function M.init(): nil
  local group = vim.api.nvim_create_augroup("RakhshTrailingWhitespace", { clear = true })

  local function enable_trailing_ws_match(_ev): nil
    local bufnr = vim.api.nvim_get_current_buf()
    local ft = vim.api.nvim_buf_get_option(bufnr, "filetype") as string
    if not c.languages[ft] then
      if trailing_ws_match_id ~= nil then
        local _ok, _ = pcall(vim.fn.matchdelete, trailing_ws_match_id)
        trailing_ws_match_id = nil
      end
      return
    end

    --+ ensure our highlight survives colorscheme changes
    vim.api.nvim_set_hl(0, "RakhshExtraWhitespace", { bg = "#991111" })

    --+ clear our previous trailing-whitespace match in this window, if any
    if trailing_ws_match_id ~= nil then
      local _ok, _ = pcall(vim.fn.matchdelete, trailing_ws_match_id)
      trailing_ws_match_id = nil
    end

    --+ highlight trailing whitespace at end of line and remember the match id
    trailing_ws_match_id = vim.fn.matchadd("RakhshExtraWhitespace", [[\s\+$]], 10, -1)
  end

  --+ Re-apply match when entering a window or leaving insert mode
  vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertLeave" }, {
    group = group,
    callback = enable_trailing_ws_match,
  })

  --+ Clear matches when leaving the window
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    callback = function(_ev): nil
      if trailing_ws_match_id ~= nil then
        local _ok, _ = pcall(vim.fn.matchdelete, trailing_ws_match_id)
        trailing_ws_match_id = nil
      end
    end,
  })

  --+ Apply match immediately in the current window
  enable_trailing_ws_match(nil)                         
end

function M.lazy(): {PluginSpec}
  return {}
end

return M
