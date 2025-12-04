local buffman = require("core.buffman")
local t = require("core.types")
global vim: t.vim.Vim

local record M
  status_summary: function(): string
end

local record BuffCounts
  files: integer
  terminals: integer
  unmanaged: integer
end

local function count_buffers(): BuffCounts
  local files, terms, unmanaged = 0, 0, 0

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local meta = buffman.get_meta(buf) as buffman.RakhshBufMeta
    if meta then
      if meta.kind._tag == "file" then
        files = files + 1
      elseif meta.kind._tag == "terminal" then
        terms = terms + 1
      end
    else
      unmanaged = unmanaged + 1
    end
  end

  return {files = files, terminals = terms, unmanaged = unmanaged}
end

function M.status_summary(): string
  local bc: BuffCounts = count_buffers()
  return string.format("%d %d %d", bc.files, bc.terminals, bc.unmanaged)
end

return M