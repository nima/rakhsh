local t = require("core.types")
global vim: t.vim.Vim

if vim.fn.has("nvim") == 1 then
  local sock = os.getenv("NVIM_LISTEN_ADDRESS")
  if sock and sock ~= "" then
    vim.fn.serverstart(sock)
  end
end
