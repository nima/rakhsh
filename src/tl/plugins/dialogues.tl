local t = require("types")
local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local function open_popup_for_buffer(buf: integer)
  -- Same floating-window code you already have
  local width  = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines   * 0.6)
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style    = "minimal",
    border   = "rounded",
    row      = row,
    col      = col,
    width    = width,
    height   = height,
  })

  -- Hide cursor inside this popup window
  vim.api.nvim_set_hl(0, "CursorNone", { blend = 100 })
  vim.api.nvim_set_option_value("winhighlight", "Cursor:CursorNone", { win = win })

  -- Position cursor at the top; treat this as a read-only viewer
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  -- Scroll mappings: make j/k and arrows scroll the window instead of moving cursor
  local function map_scroll(lhs: string, rhs: string)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, remap = false })
  end

  map_scroll("j", "<C-e>")
  map_scroll("k", "<C-y>")
  map_scroll("<Down>", "<C-e>")
  map_scroll("<Up>", "<C-y>")
  map_scroll("<PageDown>", "<C-d>")
  map_scroll("<PageUp>", "<C-u>")

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
end

local function open_popup_with_lines(lines: {string})
  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Treat it like a markdown-ish, read-only scratch buffer
  vim.api.nvim_set_option_value("filetype",   "markdown", { buf = buf })
  vim.api.nvim_set_option_value("buftype",    "nofile",   { buf = buf })
  vim.api.nvim_set_option_value("bufhidden",  "wipe",     { buf = buf })
  vim.api.nvim_set_option_value("swapfile",   false,      { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false,      { buf = buf })
  vim.api.nvim_set_option_value("readonly",   true,       { buf = buf })

  open_popup_for_buffer(buf)
end

local record DialoguesModule
  init: function(): nil
  lazy: function(): {PluginSpec}
  keymaps: function(): {PluginKeymap}

  open_popup_with_file: function(path: string): nil
  open_popup_with_cmd: function(cmd: string): nil
  open_popup_with_cmd_sandboxed: function(cmd: string): nil
end

local M: DialoguesModule = {}

function M.init(): nil
  return nil
end

function M.open_popup_with_file(path: string): nil
  local full = (vim.fn.fnamemodify(path, ":p") as string)  -- resolve relative → absolute
  local ok, lines_any = pcall(vim.fn.readfile, full)
  if not ok then
    vim.notify("[rakhsh/ui] readfile failed for: " .. full, vim.log.levels.ERROR, nil)
    return
  end
  open_popup_with_lines(lines_any as {string})
end

function M.open_popup_with_cmd(cmd: string): nil
  -- Capture command output (Neovim 0.8+)
  local ok_exec, res = pcall(vim.api.nvim_exec2, cmd, { output = true })
  if not ok_exec or res == nil then
    vim.notify("[rakhsh/ui] exec failed for: " .. cmd, vim.log.levels.ERROR, nil)
    return
  end

  local out = (res.output as string) or ""
  if out == "" then
    vim.notify("[rakhsh/ui] no output for: " .. cmd, vim.log.levels.INFO, nil)
    return
  end

  local lines_any = vim.split(out, "\n", true)
  open_popup_with_lines(lines_any as {string})
end

function M.open_popup_with_cmd_sandboxed(cmd: string): nil
  -- run command isolated in a temporary tabpage to avoid UI destruction
  local api = vim.api
  local orig_tab = api.nvim_get_current_tabpage()

  -- open temp tab (new empty buffer becomes current)
  vim.cmd("tabnew")

  -- try running the command; it may change windows/buffers inside this tab
  local _ok = pcall(vim.api.nvim_command, cmd)

  -- capture the buffer that the command left us in this tab
  local buf = api.nvim_get_current_buf()

  -- close the temp tab, return to original
  vim.cmd("tabclose")
  api.nvim_set_current_tabpage(orig_tab)

  -- open a popup on the same buffer to preserve highlights/colors
  open_popup_for_buffer(buf)
end

function M.keymaps(): {PluginKeymap}
  return {
    {
      mode = "n",
      role = R.Info,
      key = "R",
      rhs = function() M.open_popup_with_file("README.md") end,
      desc = "README",
      tags = { T.ActionView, T.TargetBuffer },
      on = On.Immediate,
    },
    {
      mode = "n",
      role = R.Info,
      key = "H",
      rhs = "<Cmd>Telescope help_tags<CR>",
      desc = "RTFM",
      tags = { T.ActionView, T.TargetBuffer },
      on = On.Immediate,
    },
  }
end

function M.lazy(): {PluginSpec}
  return {}
end

return M
