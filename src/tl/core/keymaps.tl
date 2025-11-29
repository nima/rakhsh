local t = require("core.types")

global vim: t.vim.Vim

local record KeymapModule
  Roles: {string : t.roles.Role}
  Tags:  {string : t.tags.Tag}
  safemap: function(mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  safemap_buf: function(bufnr: integer, mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  opts: function(desc: string | nil, tags: {t.tags.Tag}): t.vim.VimMapOpts
end

local M: KeymapModule = {
  Roles = t.roles.Roles,
  Tags  = t.tags.Tags,
}

local function ensure_role(mode: string, role: t.roles.Role, key: string): nil
  if type(role) ~= "table" or role._tag == nil then
    local caller = debug.getinfo(4, "Sl")
    error((
      "safemap: invalid role for mapping\n" ..
      "  mode = %s, key tail = %s\n" ..
      "  role = %s\n" ..
      "  called from %s:%s"
    ):format(
      tostring(mode),
      tostring(key),
      tostring(role),
      caller and caller.short_src or "?",
      caller and caller.currentline or -1
    ))
  end
end

local function mklhs(mode: string, role: t.roles.Role, key: string): string
  ensure_role(mode, role, key)

  local mode_cfg = t.roles.ActivationPrefix[mode]
  if not mode_cfg then
    error("safemap: unsupported mode: " .. tostring(mode))
  end

  local prefix = mode_cfg[role]
  if not prefix then
    error(("safemap: unknown role '%s' for mode '%s'"):format(role._tag, mode))
  end

  --! Special-case: insert META → <C-x>
  if mode == "i" and prefix == "<C-" then
    return prefix .. key .. ">"
  end

  return prefix .. key
end

local function same_rhs(info: t.vim.VimRawMapInfo, rhs: any): boolean
  if type(rhs) == "string" then
    return info.rhs == rhs
  elseif type(rhs) == "function" and type(info.callback) == "function" then
    local cb = info.callback as function(...: any): any
    local fn = rhs           as function(...: any): any
    local a = debug.getinfo(cb, "S")
    local b = debug.getinfo(fn, "S")
    if a and b and a.source == b.source and a.linedefined == b.linedefined then
      return true
    end
  end
  return false
end

local function collisions(_existing: t.vim.VimRawMapInfo | nil, mode: string, lhs: string, rhs: any, opts: t.vim.VimMapOpts): nil
  if _existing == nil then return end

  local existing = _existing as t.vim.VimRawMapInfo
  if existing.desc == opts.desc then return end
  if existing.lhs == nil then return end

  -- same lhs + same rhs → fine, idempotent re-attach
  if same_rhs(existing, rhs) then return end

  local caller = debug.getinfo(2, "Sl")
  error((
    "Keymap conflict for [%s] in mode '%s'\n" ..
    "Existing: %s -> %s  (set in %s:%s)\n" ..
    "New:      %s -> %s  (attempted in %s:%s)\n" ..
    "Tip: :verbose %smap %s"
  ):format(
    lhs,
    mode,
    existing.lhs or lhs,
    existing.rhs or "?",
    existing.script or "?",
    existing.lnum or -1,
    lhs,
    type(rhs) == "string" and rhs or "<Lua fn>",
    caller.short_src or "?", caller.currentline or -1,
    mode,
    lhs
  ))
end

local function find_buf_map(bufnr: integer, mode: string, lhs: string): t.vim.VimRawMapInfo | nil
  local maps = (vim.api.nvim_buf_get_keymap(bufnr, mode) as {t.vim.VimRawMapInfo})
  for _, info in ipairs(maps) do
    if info.lhs == lhs then return info end
  end
  return nil
end

function M.safemap(mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  local lhs = mklhs(mode, role, key)
  local existing = vim.fn.maparg(lhs, mode, false, true) as t.vim.VimRawMapInfo
  collisions(existing, mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.safemap_buf(bufnr: integer, mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  local lhs = mklhs(mode, role, key)
  local existing: t.vim.VimRawMapInfo | nil = find_buf_map(bufnr, mode, lhs)
  collisions(existing, mode, lhs, rhs, opts)
  local merged = vim.tbl_extend("force", (opts as {string : any}), { buffer = bufnr } as {string : any})
  vim.keymap.set(mode, lhs, rhs, merged as t.vim.VimMapOpts)
end

function M.opts(desc: string | nil, tags: {t.tags.Tag}): t.vim.VimMapOpts
  local effective_desc = desc or ""

  local rendered: {string} = {}

  for _, tag in ipairs(tags) do
    table.insert(rendered, "#" .. tag._tag)
  end

  if #rendered == 0 then
    error("opts: tags must be non-empty")
  end

  local tag_str = table.concat(rendered, ", ")
  if effective_desc ~= "" then
    effective_desc = ("%s [%s]"):format(effective_desc, tag_str)
  else
    effective_desc = ("[%s]"):format(tag_str)
  end

  local out: t.vim.VimMapOpts = {
    noremap = true,
    silent  = true,
    desc    = effective_desc,
  }

  return out
end

return M
