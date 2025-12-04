local t = require("core.types")
global vim: t.vim.Vim

-- Rakhsh buffer manager
-- Keeps track of "owned" buffers (files, terminals, etc.) via per-buffer metadata.
-- Tabs / UI should treat this as the single source of truth.

local record BufKindTag
  _tag: string
end

local BufKind: { string : BufKindTag } = {
  File     = { _tag = "file" },
  Terminal = { _tag = "terminal" },
}
setmetatable(BufKind, { __newindex = function() error("Cannot add new enum values to BufKind") end })

local record RakhshBufMeta
  kind: BufKindTag
  path: string | nil
  label: string | nil
end

local record M
  mark_file: function(bufnr: integer, path: string): nil
  mark_terminal: function(bufnr: integer, label: string): nil
  is_managed: function(bufnr: integer): boolean
  get_meta: function(bufnr: integer): RakhshBufMeta | nil
  list_managed: function(): {integer}
  sync_tabs: function(): nil
  RakhshBufMeta: RakhshBufMeta
end

local record BufTable
  rakhsh_kind: BufKindTag | nil
  rakhsh_path: string | nil
  rakhsh_label: string | nil
end


local function ensure_buf_table(bufnr: integer): BufTable
  if vim.b[bufnr] == nil then
    vim.b[bufnr] = {}
  end
  return vim.b[bufnr] as BufTable
end

local function get_buf_table(bufnr: integer): BufTable
  return ensure_buf_table(bufnr)
end

local function set_meta(bufnr: integer, kind: BufKindTag, path: string | nil, label: string | nil)
  local b = get_buf_table(bufnr)
  b.rakhsh_kind = kind
  b.rakhsh_path = path
  b.rakhsh_label = label
end

local function tab_main_buf(tab: integer): integer | nil
  -- Choose the first window in a tab as its representative buffer.
  local wins = vim.api.nvim_tabpage_list_wins(tab)
  if #wins == 0 then
    return nil
  end
  local win = wins[1]
  return vim.api.nvim_win_get_buf(win)
end

function M.mark_file(bufnr: integer, path: string): nil
  if bufnr <= 0 then return end
  if path == "" then
    path = vim.api.nvim_buf_get_name(bufnr)
  end
  set_meta(bufnr, BufKind.File, path, nil)
end

function M.mark_terminal(bufnr: integer, label: string): nil
  if bufnr <= 0 then return end
  if label == "" then
    label = "terminal"
  end
  set_meta(bufnr, BufKind.Terminal, nil, label)
end

function M.is_managed(bufnr: integer): boolean
  if bufnr <= 0 then
    return false
  end
  local b = get_buf_table(bufnr)
  return b.rakhsh_kind ~= nil
end

function M.get_meta(bufnr: integer): RakhshBufMeta | nil
  if not M.is_managed(bufnr) then
    return nil
  end
  local b = get_buf_table(bufnr)
  local meta: RakhshBufMeta = {
    kind = (b.rakhsh_kind as BufKindTag),
    path = b.rakhsh_path,
    label = b.rakhsh_label,
  }
  return meta
end

function M.list_managed(): {integer}
  local out: {integer} = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local b = get_buf_table(buf)
    if b.rakhsh_kind ~= nil then
      table.insert(out, buf)
    end
  end
  return out
end

function M.sync_tabs(): nil
  -- Ensure every managed buffer has at least one tab whose main window shows it.
  -- This is conservative: we never close tabs, only create missing ones.
  local managed = M.list_managed()
  if #managed == 0 then
    return
  end

  -- Build a set of managed buffers that already have a tab.
  local have_tab: { integer : boolean } = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local buf = tab_main_buf(tab as integer)
    if buf ~= nil and M.is_managed(buf as integer) then
      have_tab[buf as integer] = true
    end
  end

  -- For each managed buffer without a tab, create a new tab and show it there.
  for _, buf in ipairs(managed) do
    if not have_tab[buf] then
      vim.cmd("tabnew")
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, buf)
    end
  end
end

function M.init(): nil
  vim.api.nvim_create_autocmd("TermOpen", {
    callback = function(ev: t.vim.VimAutocmdEvent)
      local bufnr = ev.buf
      M.mark_terminal(bufnr, "")  -- label optional / can be improved
    end,
  })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    callback = function(ev: t.vim.VimAutocmdEvent)
      local bufnr = ev.buf
      if bufnr <= 0 then return end

      -- only normal file buffers, listed
      if vim.api.nvim_buf_get_option(bufnr, "buftype") ~= "" then return end
      if not vim.api.nvim_buf_get_option(bufnr, "buflisted") then return end

      local name = vim.api.nvim_buf_get_name(bufnr)
      if name == "" then return end

      M.mark_file(bufnr, name)
    end,
  })
end

return M
