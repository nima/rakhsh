-- core/notify.tl
local t = require("core.types")

global vim: t.vim.Vim

local record NotifyOpts
  timeout: integer | nil
end

local type NotifyBackend = function(string, integer, any): nil
local record NotifyModule
  _backend: NotifyBackend
  notify: function(msg: string, level: integer | nil, opts: any): nil
end
local M: NotifyModule = {} as NotifyModule

local record NotifyItem
  msg: string
  level: integer
  opts: any
end
local queue: {NotifyItem} = {}

local busy: boolean = false
local ttl: integer = 2000 -- ms

local function show_next()
  if #queue == 0 then
    busy = false
    return
  end

  busy = true

  local item = (table.remove(queue, 1) as NotifyItem)
  local msg, level, opts = item.msg, item.level, item.opts

  -- honour per-message timeout override, if provided
  local timeout: integer = ttl
  if opts ~= nil then
    local o = (opts as NotifyOpts)
    if o.timeout ~= nil then
      timeout = o.timeout
    end
  end

  -- send to the real backend (built-in or nvim-notify)
  M._backend(msg, level, opts)

  vim.defer_fn(function()
    show_next()
  end, timeout)
end

function M.notify(msg: string, level: integer | nil, opts: any): nil
  local lvl: integer = level or vim.log.levels.INFO
  local entry: NotifyItem = { msg = msg, level = lvl, opts = opts }
  table.insert(queue, entry)

  if not busy then
    show_next()
  end

  return nil
end

-- call once at startup, choosing backend:
local original_notify = (vim.notify as NotifyBackend)
M._backend = original_notify

-- Replace global vim.notify with our queued frontend, preserving the API.
local function notify_wrapper(msg: string, level: integer | nil, opts: any): nil
  return M.notify(msg, level, opts)
end

vim.notify = notify_wrapper

return M