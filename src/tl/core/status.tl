local t = require("core.types")
global vim: t.vim.Vim

local record M
  status_summary: function(): string
end

local record BuffCounts
  buffers: integer
  terminals: integer
end

local function count_buffers(): BuffCounts
  local buffers = #vim.api.nvim_list_bufs()
  return {buffers = buffers, terminals = 0}
end

function M.status_summary(): string
  local bc: BuffCounts = count_buffers()
  return string.format("%d %d %d", bc.buffers, -1, -1)
end

return M
