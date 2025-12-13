local t = require("types")
local R = t.roles.Roles
local T = t.tags.Tags

global vim: t.vim.Vim

local OnEvents = t.plugins.KeymapEvents
local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

--------------------------------------------------------------------------------

-- Simple cursor-word highlight toggle; no cursor-position persistence.
local cursorword_enabled: boolean = true
local cursorword_match_id: integer | nil = nil

--------------------------------------------------------------------------------

local function clear_cursorword(): nil
  if cursorword_match_id ~= nil then
    local _ok, _ = pcall(vim.fn.matchdelete, cursorword_match_id)
    cursorword_match_id = nil
  end
end

local function define_cursorword_hl(): nil
  vim.api.nvim_set_hl(0, "RakhshCursorWord", {
    fg = "#ffcc00",
    underline = true,
    bold = true,
  })
end

local function update_cursorword(): nil
  if not cursorword_enabled then
    clear_cursorword()
    return
  end

  local ok, word = pcall(vim.fn.expand, "<cword>")
  if not ok or word == nil or word == "" then
    -- no word under cursor → keep existing highlight instead of killing it
    return
  end

  clear_cursorword()

  local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"
  cursorword_match_id = vim.fn.matchadd("RakhshCursorWord", pat, 10, -1)
end

local function toggle_cursorword(): nil
  cursorword_enabled = not cursorword_enabled
  if not cursorword_enabled then
    clear_cursorword()
  else
    update_cursorword()
  end
end

--------------------------------------------------------------------------------

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.Toggle,
      key = "h",
      rhs = toggle_cursorword,
      desc = "Toggle word highlight under cursor",
      tags = { T.ActionToggle },
      on = OnEvents.Immediate,
    },
  }
end

function M.lazy(): {PluginSpec}
  return {}
end

function M.init(): nil
  define_cursorword_hl()

  -- Re-apply cursor-word highlight after any colorscheme or theme change
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function(): nil
      define_cursorword_hl()
      update_cursorword()
    end,
  })

  -- Cursor-word autocmds
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    callback = function(): nil update_cursorword() end,
  })
end

return M
