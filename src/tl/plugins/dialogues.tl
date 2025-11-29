local t = require("core.types")
local keymaps = require("core.keymaps")
local T = keymaps.Tags
local R = keymaps.Roles
local On = t.plugins.KeymapEvents

global vim: t.vim.Vim

local function open_popup_with_lines(lines: {string})
  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Optional: treat it like a markdown buffer
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })
  vim.api.nvim_set_option_value("buftype",  "nofile",   { buf = buf })
  vim.api.nvim_set_option_value("bufhidden","wipe",     { buf = buf })
  vim.api.nvim_set_option_value("swapfile", false,      { buf = buf })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("readonly",   true,  { buf = buf })

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
    --+ No need for safgemap here.
    vim.keymap.set("n", lhs, rhs, { buffer = buf, nowait = true, silent = true, noremap = true })
  end

  map_scroll("j", "<C-e>")
  map_scroll("k", "<C-y>")
  map_scroll("<Down>", "<C-e>")
  map_scroll("<Up>", "<C-y>")
  map_scroll("<PageDown>", "<C-d>")
  map_scroll("<PageUp>", "<C-u>")

  --+ No need for safgemap here.
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, nowait = true, silent = true })
end

local function open_popup_with_file(path: string)
  local full = vim.fn.fnamemodify(path, ":p")  -- resolve relative → absolute
  local ok, lines_any = pcall(vim.fn.readfile, full)
  if not ok then
    vim.notify("[rakhsh/ui] readfile failed for: " .. full, vim.log.levels.ERROR, nil)
    return
  end
  open_popup_with_lines(lines_any as {string})
end

global function open_popup_with_command_output(cmd: string)
  -- Capture command output (Neovim 0.8+)
  local ok_exec, res = pcall(vim.api.nvim_exec2, cmd, { output = true })
  if not ok_exec or res == nil then
    vim.notify("[rakhsh/ui] exec failed for: " .. cmd, vim.log.levels.ERROR, nil)
    return
  end

  local out = res.output or ""
  if out == "" then
    vim.notify("[rakhsh/ui] no output for: " .. cmd, vim.log.levels.INFO, nil)
    return
  end

  local lines_any = vim.split(out, "\n", { plain = true })
  open_popup_with_lines(lines_any as {string})
end

local M: t.plugins.PluginModule = {}

function M.lazy(): t.plugins.PluginSpec
  return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    keymaps = {
      {
        mode = "n",
        role = R.TUI,
        key = "r",
        rhs = function() open_popup_with_file("README.md") end,
        desc = "RTFM",
        tags = { T.ActionInfo, T.TargetBuffer },
        on = On.Immediate,
      }
    },
  } as t.plugins.PluginSpec
end

return M
