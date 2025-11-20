-- Editor-side linting helpers: trailing whitespace, etc.
local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

function M.init(): nil
  local group = vim.api.nvim_create_augroup("RakhshTrailingWhitespace", { clear = true })

  local function enable_trailing_ws_match(_ev): nil
    -- ensure our highlight survives colorscheme changes
    vim.api.nvim_set_hl(0, "RakhshExtraWhitespace", { bg = "#991111" })
    -- highlight trailing whitespace at end of line
    vim.fn.matchadd("RakhshExtraWhitespace", [[\s\+$]], 10, -1)
  end

  -- Re-apply match when entering a window or leaving insert mode
  vim.api.nvim_create_autocmd({ "BufWinEnter", "InsertLeave" }, {
    group = group,
    callback = enable_trailing_ws_match,
  })

  -- Clear matches when leaving the window
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = group,
    callback = function(_ev): nil
      vim.fn.clearmatches()
    end,
  })

  -- <leader>w: strip trailing whitespace but keep cursor position
  vim.keymap.set("n", "<leader>w", [[mz:%s/\s\+$//e<CR>`z]], {
    silent = true,
    desc = "Strip trailing whitespace",
  })

  -- Apply match immediately in the current window
  enable_trailing_ws_match(nil)                         
end

return M
