--= Top-Level Runtime Orchestrator

local explicit_jump: {string:boolean} = {}

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(_ev: vim.AutocmdCallbackData): any
    local buf = vim.api.nvim_get_current_buf()

    -- only real listed buffers
    if not vim.api.nvim_buf_is_loaded(buf) then return end

    local buflisted_any = vim.api.nvim_get_option_value("buflisted", { buf = buf })
    if not (buflisted_any == true) then return end

    local buftype_any = vim.api.nvim_get_option_value("buftype", { buf = buf })
    if (buftype_any as string) ~= "" then return end

    local dirty: boolean = true
    local ok_get, v = pcall(vim.api.nvim_buf_get_var, buf, "dirty")
    if ok_get and type(v) == "boolean" then
      dirty = v as boolean
    end

    pcall(vim.api.nvim_buf_set_var, buf, "dirty", dirty)
    if not dirty then return end

    -- 3. if true, run any per-buffer bootstrap once and mark clean
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      --vim.cmd("RakhshOpen " .. vim.fn.fnameescape(name))
      pcall(vim.api.nvim_buf_set_var, buf, "dirty", false)
    end
  end,
})

--= The Cursed Cursor Position -=[
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(ev: vim.AutocmdCallbackData): any
    local buf = ev.buf
    local name = vim.api.nvim_buf_get_name(buf)

    -- If this edit came from RakhshOpen with an explicit position,
    -- do not restore from shada; let RakhshOpen own the cursor.
    if name ~= "" and explicit_jump[name] then
      explicit_jump[name] = nil
      return
    end

    local line = (tonumber(vim.fn.line("'\"") as any) as integer | nil) or 0
    local last = (tonumber(vim.fn.line("$") as any) as integer | nil) or 0
    if line > 0 and line <= last then
      pcall(vim.api.nvim_command, "normal! g`\"")
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

local function set_cursor_position(p: FilePosition): nil
  if p.l == 0 then return end
  --+ Cursor position is 0-based internally
  local cpos: {integer, integer} = { p.l, p.c - 1 }
  --+ Ignore errors (e.g., invalid line/column)
  pcall(vim.api.nvim_win_set_cursor, 0, cpos)
end
-- ]=-

--= 0. The Socket -=[
local sock = os.getenv("NVIM_LISTEN_ADDRESS")
if sock and sock ~= "" then vim.fn.serverstart(sock) end
-- ]=-

--= 1. The API -=[
vim.api.nvim_create_user_command(
  "RakhshOpen",
  function(opts: vim.CommandArguments)
    local token = opts.args
    if token == "" then return end

    local p = parse_cursor_position(token)
    if p.l > 0 then
      explicit_jump[p.f] = true
    end
    vim.cmd.edit(vim.fn.fnameescape(p.f) as string)
    --+ BufReadPost runs to completion here
    if p.l == 0 then return end
    set_cursor_position(p)
  end,
  { nargs = 1 }
)

vim.api.nvim_create_user_command(
  "RakhshStatus",
  function(_opts)
    print(require("core.status").status_summary())
  end,
  {}
)
-- ]=-
