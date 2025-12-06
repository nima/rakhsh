--= Top-Level Runtime Orchestrator
local t = require("core.types")
global vim: t.vim.Vim


-- -=[
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local line = vim.fn.line("'\"")
    local last = vim.fn.line("$")
    if line > 0 and line <= last then
      pcall(vim.cmd, "normal! g`\"")
    end
  end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()

    -- only real listed buffers
    if not vim.api.nvim_buf_is_loaded(buf) then return end
    if not vim.bo[buf].buflisted then return end
    if vim.bo[buf].buftype ~= "" then return end

    local dirty = vim.b[buf].dirty
    if dirty == nil then dirty = true end
    vim.b[buf].dirty = dirty
    if not dirty then return end

    -- 3. if true, run any per-buffer bootstrap once and mark clean
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      --vim.cmd("RakhshOpen " .. vim.fn.fnameescape(name))
      vim.b[buf].dirty = false
    end
  end,
})

local record FilePosition
  f: string
  l: integer
  c: integer
end

local function parse_cursor_position(token: string): FilePosition
  local fpos: FilePosition = { f = token, l = 0, c = 0 }

  --+ token: <file>[:<ln>[:<col>]]
  local file, _ln, _cn = token:match("^(.-):(%d*):?(%d*)$")
  if file == nil then return fpos end

  fpos.f = file
  fpos.l = (tonumber(_ln) as integer | nil) or 0
  fpos.c = (tonumber(_cn) as integer | nil) or 1
  return fpos
end
-- ]=-

--= 0. The Socket
local sock = os.getenv("NVIM_LISTEN_ADDRESS")
if sock and sock ~= "" then vim.fn.serverstart(sock) end

--= 1. The API -=[
vim.api.nvim_create_user_command(
  "RakhshOpen",
  function(opts: t.vim.VimUserCommandOpts)
    local token = opts.args
    if token == "" then return end

    local p = parse_cursor_position(token)
    vim.cmd("edit " .. vim.fn.fnameescape(p.f))
    --+ BufReadPost runs to completion here
    if p.l == 0 then return end

    --+ Cursor position is 0-based internally
    local cpos: t.vim.VimCursorPosition = { p.l, p.c - 1 }
    pcall(vim.api.nvim_win_set_cursor, 0, cpos)
  end,
  { nargs = 1 }
)

vim.api.nvim_create_user_command(
  "RakhshStatus",
  function(_: t.vim.VimUserCommandOpts)
    print(require("core.status").status_summary())
  end,
  {}
)
-- ]=-
