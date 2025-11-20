-- Minimal Rakhsh folds: color markers + fold toggle. No Treesitter.
local t = require("core.types")
global vim: t.vim.Vim

-- Define highlight groups
local function define_fold_marker_highlights()
  vim.api.nvim_set_hl(0, "FoldMarkerRed",    { fg = "#ff7070", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerOrange", { fg = "#ffb86c", bold = true })
end

local function is_comment_line(buf: integer, lnum: integer): boolean
  -- Very simple "is this line a comment?" detector:
  -- Just checks whether the line *starts* with comment syntax.
  local comment_prefixes: {string:string} = {
    lua = "%s*%-%-",
    python = "%s*#",
    make = "%s*#",
    sh = "%s*#",
    bash = "%s*#",
    c = "%s*//",
    cpp = "%s*//",
    go = "%s*//",
    vim = '%s*"',
  }

  local ft = vim.bo[buf].filetype
  local pref = comment_prefixes[ft]
  if not pref then return false end
  local line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1] or ""
  return line:find(pref) ~= nil
end

-- Apply extmarks for markers found inside comments.
local function apply_markers(buf: integer)
  local ns = vim.api.nvim_create_namespace("rakhsh_folds")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  -- Patterns inside comments only.
  local markers = {
    { pat = "%-=%{",  hl = "FoldMarkerRed"    }, -- -={
    { pat = "}%=%-",  hl = "FoldMarkerRed"    }, -- }=-
    { pat = "%-=%[",  hl = "FoldMarkerOrange" }, -- -=[
    { pat = "%]%=%-", hl = "FoldMarkerOrange" }, -- ]=-
  }

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    if is_comment_line(buf, i - 1) then
      for _, m in ipairs(markers) do
        local start = 1
        while true do
          local s, e = line:find(m.pat, start)
          if not s then break end
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, s - 1, {
            end_col = e,
            hl_group = m.hl,
            priority = 9000,
            hl_mode = "combine",
          })
          start = e + 1
        end
      end
    end
  end
end

-- Toggle fold delimited by comment markers
local function toggle_comment_fold()
  local buf = vim.api.nvim_get_current_buf()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Ensure manual fold mode
  if vim.wo.foldmethod ~= "manual" then
    vim.wo.foldmethod = "manual"
    vim.cmd("silent! normal! zE")
  end

  -- If already in a fold: toggle it normally.
  if vim.fn.foldlevel(cur) > 0 then
    vim.cmd("normal! za")
    return
  end

  -- Search upward for open marker on comment line
  local open_pat = "%-=%s*[{%[]"
  local open_line: integer|nil = nil
  for i = cur, 1, -1 do
    if is_comment_line(buf, i - 1) and lines[i]:find(open_pat) then
      open_line = i
      break
    end
  end
  if not open_line then
    vim.notify("No fold start marker", vim.log.levels.INFO, nil)
    return
  end

  -- Search downward for close marker on comment line
  local close_pat = "[}%]]=%-"
  local close_line: integer|nil = nil
  for i = cur, #lines do
    if is_comment_line(buf, i - 1) and lines[i]:find(close_pat) then
      close_line = i
      break
    end
  end
  if not close_line or close_line <= open_line then
    vim.notify("No fold end marker", vim.log.levels.INFO, nil)
    return
  end

  vim.cmd(string.format("%d,%dfold", open_line, close_line))
end

-- Autocmd to recolor markers on buffer events
vim.api.nvim_create_autocmd(
  { "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI", "ColorScheme" },
  {
    group = vim.api.nvim_create_augroup("rakhsh_folds_min", { clear = true }),
    callback = function(_ev): nil
      define_fold_marker_highlights()
      apply_markers(vim.api.nvim_get_current_buf())
    end,
  }
)

local M: t.plugins.PluginModule = {}

function M.init(): nil
  -- Make sure folds are included in saved views
  vim.o.viewoptions = vim.o.viewoptions .. ",folds"

  -- Auto-save folds (and other view info) when leaving a window
  vim.api.nvim_create_autocmd("BufWinLeave", {
    pattern = "*",
    callback = function(_ev): nil
      -- silent! so it doesn’t complain if it can’t write
      vim.cmd("silent! mkview")
    end,
  })

  -- Auto-restore folds when re-entering a window
  vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = "*",
    callback = function(_ev): nil
      vim.cmd("silent! loadview")
    end,
  })

  define_fold_marker_highlights()

  -- Keybind: toggle fold
  vim.keymap.set("n", ";", toggle_comment_fold, { desc = "Toggle comment fold" })
end

return M
