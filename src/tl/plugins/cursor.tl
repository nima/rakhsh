local t = require("core.types")
global vim: t.vim.Vim

local state_dir = vim.fn.stdpath("state") as string
local pos_file = state_dir .. "/lastpos.txt"

local function load_lastpos(): t.vim.VimCursorPositions
  local ok, lines_any = pcall(vim.fn.readfile, pos_file)
  if not ok then return {} end

  local lines = lines_any as {string}
  local acc: t.vim.VimCursorPositions = {}

  for _, line in ipairs(lines) do
    local name, row_s, col_s = line:match("^(.-)\t(%d+)\t(%d+)$")
    if name ~= nil and row_s ~= nil and col_s ~= nil then
      local row = tonumber(row_s)
      local col = tonumber(col_s)
      if row ~= nil and col ~= nil then
        acc[name] = { row, col } as t.vim.VimCursorPosition
      end
    end
  end

  return acc
end

local function save_lastpos(tbl: t.vim.VimCursorPositions): nil
  -- ensure state dir exists
  pcall(vim.fn.mkdir, state_dir, "p")

  local out = {} as {string}
  for name, pos in pairs(tbl) do
    local row = pos[1]
    local col = pos[2]
    out[#out + 1] = string.format("%s\t%d\t%d", name, row, col)
  end

  pcall(vim.fn.writefile, out, pos_file)
end

local cursorword_enabled: boolean = true
local cursorword_match_id: integer | nil = nil
local lastpos: t.vim.VimCursorPositions = {}

local function clear_cursorword(): nil
  if cursorword_match_id ~= nil then
    local _ok, _ = pcall(vim.fn.matchdelete, cursorword_match_id)
    cursorword_match_id = nil
  end
end

local function update_cursorword(): nil
  if not cursorword_enabled then
    return
  end

  clear_cursorword()

  local ok, word = pcall(vim.fn.expand, "<cword>")
  if not ok or word == nil or word == "" then
    return
  end

  -- Strict whole-word match: \<word\>
  local pat = "\\V\\<" .. vim.fn.escape(word, "\\") .. "\\>"

  -- 10 = priority, doesn't really matter unless you have a ton of matches
  cursorword_match_id = vim.fn.matchadd("CursorWord", pat, 10, -1)
end

-- Toggle mapping: <Esc>h
local function toggle_cursorword(): nil
  cursorword_enabled = not cursorword_enabled
  if not cursorword_enabled then
    clear_cursorword()
  else
    update_cursorword()
  end
end

local M: t.plugins.PluginModule = {}

function M.init(): nil
  -- Highlight group for cursor word
  vim.api.nvim_set_hl(0, "CursorWord", {
    underline = true,
    bold = true,
  })

  -- Cursor-word autocmds
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    callback = update_cursorword,
  })

  -- Toggle mapping: <Esc>h
  vim.keymap.set("n", "<Esc>h", toggle_cursorword, {
    noremap = true,
    silent = true,
    desc = "Toggle word highlight under cursor",
  })

  -- Last-position table: load from disk into vim.cfg.pos once
  if vim.g.pos == nil then
    vim.g.pos = load_lastpos()
  end

  lastpos = vim.g.pos as t.vim.VimCursorPositions

  -- Save cursor position after a short idle (debounced via 'updatetime').
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    callback = function(ev: t.vim.VimAutocmdEvent): nil
      local name = vim.api.nvim_buf_get_name(ev.buf)
      if name == nil or name == "" then
        return
      end

      -- Only track normal file buffers.
      local buftype = vim.api.nvim_buf_get_option(ev.buf, "buftype")
      if buftype ~= "" then return end

      local pos = vim.api.nvim_win_get_cursor(0)
      local row = pos[1]
      if row <= 1 then
        return
      end

      lastpos[name] = pos
      save_lastpos(lastpos)
    end,
  })

  -- On reading a buffer, restore the last remembered position for this file, if any.
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWinEnter" }, {
    callback = function(ev: t.vim.VimAutocmdEvent): nil
      local name = vim.api.nvim_buf_get_name(ev.buf)
      if name == nil or name == "" then return end

      -- Always reload from disk so server/headless usage sees the latest state
      local tbl = load_lastpos()
      lastpos = tbl
      vim.g.pos = tbl

      local pos = tbl[name]
      if pos == nil then return end

      local row = pos[1]
      local col0 = pos[2]
      local last_line = vim.api.nvim_buf_line_count(ev.buf)

      if row <= 1 or row > last_line then
        return
      end

      pcall(vim.api.nvim_win_set_cursor, 0, { row, col0 })
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function(_ev: t.vim.VimAutocmdEvent): nil
      save_lastpos(lastpos)
    end,
  })
end

return M
