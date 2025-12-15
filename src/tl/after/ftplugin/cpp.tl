local t = require("types")
global vim: t.vim.Vim
local vimbo = vim.bo[0]
local R = t.roles.Roles
local T = t.tags.Tags

-- C / C++
vimbo.expandtab   = true
vimbo.shiftwidth  = 4
vimbo.tabstop     = 4
vimbo.softtabstop = 4
vimbo.cindent     = true
vimbo.cinoptions  = "g0,h2,t0"

vim.opt_local.iskeyword:append("$")

local km = require("core.keymaps")
local bufnr = vim.api.nvim_get_current_buf()

km.safemap_buf(bufnr, "n", R.Toggle, "c", function()
  local file = vim.api.nvim_buf_get_name(0)
  local base, ext = file:match("^(.*)%.([^%.]+)$")
  if not base then return end

  if ext == "cpp" then
    vim.api.nvim_command("edit " .. base .. ".hpp")
  elseif ext == "hpp" then
    vim.api.nvim_command("edit " .. base .. ".cpp")
  end
end, km.opts("Switch between .cpp and .hpp", { T.ActionEdit, T.TargetFile } ))
