local t = require("core.types")

global vim: t.vim.Vim

local ns = vim.api.nvim_create_namespace("rakhsh_folds")

local function define_fold_marker_highlights(): nil
  vim.api.nvim_set_hl(0, "FoldMarkerRed",    { fg = "#ff5555", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerOrange", { fg = "#ffb86c", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerBlue",   { fg = "#8be9fd", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerPurple", { fg = "#bd93f9", bold = true })
end

local function apply_markers(buf: integer): nil
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then return end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local markers = {
    { pat = "%-=%s*%{",  hl = "FoldMarkerRed" },    -- -={
    { pat = "%}%=%-",    hl = "FoldMarkerRed" },    -- }=-
    { pat = "%-=%s*%[",  hl = "FoldMarkerBlue" },   -- -=[
    { pat = "%]%=%-",    hl = "FoldMarkerBlue" },   -- ]=-
    { pat = "%-=%s*%(" , hl = "FoldMarkerOrange" }, -- -=(
    { pat = "%)%=%-",    hl = "FoldMarkerOrange" }, -- )=-
    { pat = "%-=%s*%<",  hl = "FoldMarkerPurple" }, -- -=<
    { pat = ">%=%-",     hl = "FoldMarkerPurple" }, -- >=-
  }

  for i = 1, #lines do
    local line = lines[i]
    for _, m in ipairs(markers) do
      local s = 1
      while true do
        local a, b = line:find(m.pat, s)
        if not a then break end
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, a - 1, {
          end_col = b,
          hl_group = m.hl,
          hl_mode = "combine",
        })
        s = b + 1
      end
    end
  end
end

local record FoldsModule
  toggle: function(): nil
  setup: function(): nil
end

local M: FoldsModule = {}

function M.toggle(): nil
  local buf = vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then return end
  if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then return end

  -- Deterministic toggle: if cursor is on a closed fold, open it; otherwise close the fold under cursor.
  if vim.fn.foldclosed(".") ~= -1 then
    vim.cmd("silent! normal! zo")
  else
    vim.cmd("silent! normal! zc")
  end
end

function M.setup(): nil
  define_fold_marker_highlights()
  apply_markers(vim.api.nvim_get_current_buf())

  local group = vim.api.nvim_create_augroup("rakhsh_folds_markers", { clear = true })

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = group,
    pattern = "*",
    callback = function(_: any)
      define_fold_marker_highlights()
      apply_markers(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = "*",
    callback = function(ev: t.vim.VimAutocmdEvent)
      apply_markers(ev.buf)

      -- Ensure folds are usable: start unfolded in normal file buffers.
      if vim.api.nvim_buf_get_option(ev.buf, "buftype") == "" then
        vim.opt_local.foldenable = true
        vim.opt_local.foldlevel = 99
        vim.opt_local.foldlevelstart = 99
      end
    end,
  })
end

return M
