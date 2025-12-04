--= Top-Level Runtime Orchestrator

local t = require("core.types")
global vim: t.vim.Vim

local buffman = require("core.buffman")

if vim.fn.has("nvim") == 1 then
  local sock = os.getenv("NVIM_LISTEN_ADDRESS")
  if sock and sock ~= "" then
    vim.fn.serverstart(sock)
  end
end

--[[
When rx ui is launched after the socket has already been thrust
into life via cc (command-clicks), then they will be there in
the form of headless buffers.  Convert them to tabs.
vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    local bufs = vim.fn.getbufinfo({ buflisted = 1 })
    if #bufs == 0 then return end
    local cur = vim.api.nvim_get_current_buf()
    for _, info in ipairs(bufs) do
      if info.bufnr ~= cur then
        vim.cmd(("tab sbuffer %d"):format(info.bufnr))
      end
    end
  end,
})
]]--

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

vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    -- When a UI attaches, ensure all existing listed file buffers
    -- are registered with buffman so they each get a tab.
    local infos = vim.fn.getbufinfo({ buflisted = 1 })
    for _, info in ipairs(infos) do
      local buf = info.bufnr
      if buf and buf > 0 and not buffman.is_managed(buf) then
        local name = vim.fn.bufname(buf)
        if name ~= "" then
          buffman.mark_file(buf, name)
        end
      end
    end

    buffman.sync_tabs()
  end,
})

vim.api.nvim_create_user_command("RakhshSyncTabs", function()
  buffman.sync_tabs()
end, {})

vim.api.nvim_create_user_command("RakhshStatus", function()
  print(require("core.status").status_summary())
end, {})