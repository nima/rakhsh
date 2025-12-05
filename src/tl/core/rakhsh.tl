--= Top-Level Runtime Orchestrator

local t = require("core.types")
global vim: t.vim.Vim

if vim.fn.has("nvim") == 1 then
  local sock = os.getenv("NVIM_LISTEN_ADDRESS")
  if sock and sock ~= "" then
    vim.fn.serverstart(sock)
  end
end

vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd("doautocmd BufReadPost")
        end)
      end
    end
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  callback = function(ev: t.vim.VimAutocmdEvent)
    local win = tonumber(ev.match)
    if not win then
      vim.notify("WinClosed: no win (match=" .. tostring(ev.match) .. ")", vim.log.levels.WARN)
      return
    end

    local buf = vim.fn.winbufnr(win)
    local others = vim.fn.win_findbuf(buf)
    local visible_elsewhere = 0
    for _, w in ipairs(others) do
      if w ~= win then
        visible_elsewhere = visible_elsewhere + 1
      end
    end
    local bt = vim.bo[buf].buftype

    --[[
    local name = vim.api.nvim_buf_get_name(buf)
    vim.notify(("WinClosed: win=%g buf=%d name=%s buftype=%s others=%d visible_elsewhere=%d"):format(
      win, buf, name, bt, #others, visible_elsewhere
    ), vim.log.levels.INFO)
    ]]--

    if visible_elsewhere > 0 then return end
    if vim.api.nvim_buf_is_loaded(buf) and bt == "" then
      vim.cmd("bdelete " .. buf)
    end
  end,
})


vim.api.nvim_create_user_command(
  "RakhshOpen",
  function(opts: t.vim.VimUserCommandOpts)
    local token = opts.args
    if token == "" then
      return
    end

    local lnum: integer = 1
    local col: integer = 1

    -- token can be: file, file:ln, file:ln:col, file::, file:ln:, etc.
    local file, ln, c = token:match("^(.-):(%d*):?(%d*)$")

    if file == nil then
      -- no colons at all → plain filename
      file = token
    else
      -- ln is digits or empty
      if ln ~= "" then
        local ln_num = tonumber(ln)
        if ln_num then lnum = ln_num as integer end
      end

      -- c is digits or empty
      if c ~= "" then
        local col_num = tonumber(c)
        if col_num then col = col_num as integer end
      end
    end

    vim.cmd("edit " .. vim.fn.fnameescape(file))

    local pos: t.vim.VimCursorPosition = { lnum, col - 1 }
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  end,
  { nargs = 1 }
)

vim.api.nvim_create_user_command("RakhshStatus", function(_: t.vim.VimUserCommandOpts)
  print(require("core.status").status_summary())
end, {})
