local t = require("types")

local T = t.tags.Tags
local R = t.roles.Roles
local OnEvents = t.plugins.KeymapEvents

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

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

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.Toggle, key = "n", rhs = toggle_numbers,     desc = "Cycle line numbers",            tags = { T.TargetBuffer, T.ActionToggle }, on = OnEvents.Immediate },
    { mode = "n", role = R.Toggle, key = ".", rhs = cycle_cursor_modes, desc = "Cycle cursor crosshair modes", tags = { T.TargetBuffer, T.ActionToggle }, on = OnEvents.Immediate },
  }
end

function M.init(): nil
  vim.api.nvim_set_hl(0, "CursorLine",   { bg = "#303030" })
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#383838" })
end

function M.lazy(): {PluginSpec}
  return {}
end

return M
