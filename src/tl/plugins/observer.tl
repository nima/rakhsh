local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

--= Observer -={
--- Line Numbers
local function toggle_numbers()
  local nu  = vim.wo.number
  local rnu = vim.wo.relativenumber

  if not nu and not rnu then
    -- none → absolute
    vim.wo.number = true
    vim.wo.relativenumber = false

  elseif nu and not rnu then
    -- absolute → absolute + relative
    vim.wo.relativenumber = true

  else
    -- both (or only relative) → none
    vim.wo.number = false
    vim.wo.relativenumber = false
  end
end
vim.keymap.set("n", "<Esc>n", toggle_numbers, { desc = "Cycle line numbers" })

--- Crosshairs
local function cycle_cursor_modes()
  local cl = vim.wo.cursorline
  local cc = vim.wo.cursorcolumn

  if cl and cc then
    -- H+V → H
    vim.wo.cursorcolumn = false
  elseif cl and not cc then
    -- H → V
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = true
  elseif (not cl) and cc then
    -- V → None
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
  else
    -- None → H+V
    vim.wo.cursorline = true
    vim.wo.cursorcolumn = true
  end
end

function M.init(): nil
  vim.keymap.set("n", "<Esc>.", cycle_cursor_modes, { desc = "Cycle cursor crosshair modes" })
  vim.api.nvim_set_hl(0, "CursorLine",   { bg = "#303030" })
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#383838" })
end
-- }=-

return M