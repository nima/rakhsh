local t = require("types")
local vimbo = vim.bo
local R = t.roles.Roles
local T = t.tags.Tags

--+ C / C++
vimbo.expandtab   = true
vimbo.shiftwidth  = 4
vimbo.tabstop     = 4
vimbo.softtabstop = 4
vimbo.cindent     = true
vimbo.smartindent = false
vimbo.cinoptions  = "g0,h2,t0"
vimbo.indentexpr = ""

vim.opt_local.iskeyword:append("$")

--+ Make `case:` indent relative to the switch block, not line length
vim.bo.cinoptions = (vim.bo.cinoptions or "") .. ",:0,l1"

local km = require("core.keymaps")
local bufnr = vim.api.nvim_get_current_buf()

km.safemap_buf(bufnr, "n", R.Toggle, "c", function(...: any): any
  local _ = ...
  local file = vim.api.nvim_buf_get_name(0)
  local base, ext = file:match("^(.*)%.([^%.]+)$")
  if not base then return nil end

  if ext == "cpp" then
    vim.api.nvim_command("edit " .. base .. ".hpp")
  elseif ext == "hpp" then
    vim.api.nvim_command("edit " .. base .. ".cpp")
  end

  return nil
end, km.opts("Switch between .cpp and .hpp", { T.ActionEdit, T.TargetFile } ))

--+ Tree-sitter: rx-louder-style tag colors for C/C++ block comments like /*+ ... */
vim.api.nvim_set_hl(0, "@comment.tag.title",       { link = "CommentTagTitle" })
vim.api.nvim_set_hl(0, "@comment.tag.notice",      { link = "CommentTagNotice" })
vim.api.nvim_set_hl(0, "@comment.tag.probing",     { link = "CommentTagProbing" })
vim.api.nvim_set_hl(0, "@comment.tag.fyi",         { link = "CommentTagFYI" })
vim.api.nvim_set_hl(0, "@comment.tag.staged",      { link = "CommentTagStaged" })
vim.api.nvim_set_hl(0, "@comment.tag.upstream",    { link = "CommentTagUpstream" })
vim.api.nvim_set_hl(0, "@comment.tag.downstream",  { link = "CommentTagDownstream" })
vim.api.nvim_set_hl(0, "@comment.tag.attention",   { link = "CommentTagAttention" })
vim.api.nvim_set_hl(0, "@comment.tag.reference",   { link = "CommentTagReference" })
vim.api.nvim_set_hl(0, "@comment.tag.cost",        { link = "CommentTagCost" })
vim.api.nvim_set_hl(0, "@comment.tag.onotation",   { link = "CommentTagONotation" })
vim.api.nvim_set_hl(0, "@comment.tag.deprecation", { link = "CommentTagDeprecation" })
