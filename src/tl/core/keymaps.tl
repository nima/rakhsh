local t = require("types")
local hotkeys = require("core.hotkeys")

--= Types -={ 
local record RakhshMapOpts
  vim_opts: t.vim.VimMapOpts
  tags: {t.tags.Tag}
end

-- Minimal Telescope entry type used by our picker.
local record TelescopeEntry
  value: hotkeys.RakhshKeymap
  display: string
  ordinal: string
end

global vim: t.vim.Vim

local record KeymapModule
  Roles: {string : t.roles.Role}
  Tags:  {string : t.tags.Tag}
  safemap: function(
    mode: string,
    role: t.roles.Role,
    key: string,
    rhs: any,
    opts: RakhshMapOpts
  ): nil

  docmap: function(
    mode: string,
    lhs: string,
    opts: RakhshMapOpts
  ): nil

  docmap_buf: function(
    bufnr: integer,
    mode: string,
    lhs: string,
    opts: RakhshMapOpts
  ): nil

  safemap_buf: function(
    bufnr: integer,
    mode: string,
    role: t.roles.Role,
    key: string,
    rhs: any,
    opts: RakhshMapOpts
  ): nil

  opts: function(desc: string, tags: {t.tags.Tag}): RakhshMapOpts

  make_entry: function(keymap: hotkeys.RakhshKeymap): TelescopeEntry
end
-- }=-

--= Private Interface -={
-- Hotkey registry dedupe (idempotent registration).
-- Keyed by (mode, role.name, tail/key, internal, group, bufnr?).
local _seen_hotkeys: {string : boolean} = {}

local function _hotkey_seen_key(item: hotkeys.RakhshKeymap, bufnr?: integer): string
  local b = bufnr and tostring(bufnr) or ""
  local g = item.group or ""
  local r = (item.role and item.role.name) or "?"
  local i = item.internal and "1" or "0"
  return table.concat({ item.mode, r, item.key, i, g, b }, "\0")
end

local function register_hotkey_once(item: hotkeys.RakhshKeymap, bufnr?: integer): nil
  local k = _hotkey_seen_key(item, bufnr)
  if _seen_hotkeys[k] then return end
  _seen_hotkeys[k] = true
  hotkeys.register(item)
end

local function ensure_role(mode: string, role: t.roles.Role, key: string): nil
  if type(role) ~= "table" or role.name == nil then
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

  --+ Visual/select modes typically share the same activation prefixes as normal mode.
  --+ This avoids needing to duplicate role→prefix tables across modes.
  if not prefix and (mode == "v" or mode == "x" or mode == "s") then
    local n_cfg = t.roles.ActivationPrefix["n"]
    if n_cfg then
      prefix = n_cfg[role]
    end
  end

  if not prefix then
    error(("safemap: unknown role '%s' for mode '%s'"):format(role.name, mode))
  end

  --- Special Case: <C-*>x → <C-x> 
  if prefix:find("%*") then
    local rplc, cnt = prefix:gsub("%%*", key)
    if cnt == 1 then return rplc end
    error("Expected 1 literal asterisk; received " .. tostring(cnt))
  end

  return prefix .. key
end

local function mode_cfg_for(mode: string): {t.roles.Role: string}
  local cfg = t.roles.ActivationPrefix[mode]
  if cfg then
    return cfg
  end

  -- Reuse normal-mode prefixes for visual/select modes.
  if mode == "v" or mode == "x" or mode == "s" then
    local n_cfg = t.roles.ActivationPrefix["n"]
    if n_cfg then
      return n_cfg
    end
  end

  error("keymaps: unsupported mode: " .. tostring(mode))
end

local function decode_lhs(mode: string, lhs: string): (t.roles.Role, string)
  local cfg = mode_cfg_for(mode)

  -- Choose the longest matching prefix so Roles.Naked ("") doesn't shadow everything.
  local best_role: t.roles.Role | nil = nil
  local best_prefix: string = ""

  for role, prefix in pairs(cfg) do
    if prefix ~= "" and lhs:sub(1, #prefix) == prefix then
      if #prefix > #best_prefix then
        best_prefix = prefix
        best_role = role
      end
    end
  end

  if best_role == nil then
    local naked = t.roles.Roles.Naked
    local naked_prefix = cfg[naked]
    if naked_prefix ~= nil and lhs:sub(1, #naked_prefix) == naked_prefix then
      best_role = naked
      best_prefix = naked_prefix
    else
      error(("docmap: could not decode lhs '%s' for mode '%s'"):format(lhs, mode))
    end
  end

  local tail = lhs:sub(#best_prefix + 1)
  return best_role, tail
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

local function collisions(_existing: t.vim.VimRawMapInfo | nil, mode: string, lhs: string, rhs: any, desc: string): nil
  if _existing == nil then return end

  local existing = _existing as t.vim.VimRawMapInfo
  if existing.desc == desc then return end
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

local function find_buf_map(bufnr: integer, mode: string, lhs: string, fallback?: boolean): t.vim.VimRawMapInfo | nil
  local maps = (vim.api.nvim_buf_get_keymap(bufnr, mode) as {t.vim.VimRawMapInfo})
  for _, info in ipairs(maps) do
    if info.lhs == lhs then return info end
  end

  if not fallback then return nil end

  local any = vim.fn.maparg(lhs, mode, false, true)
  if any == nil then return nil end

  local e = any as t.vim.VimRawMapInfo
  if e.lhs ~= nil then return e end
end
-- }=-

--= Public Interface -={
local M: KeymapModule = {
  Roles = t.roles.Roles,
  Tags  = t.tags.Tags,
}

function M.safemap(
  mode: string,
  role: t.roles.Role,
  key: string,
  rhs: any,
  opts: RakhshMapOpts
): nil
  local lhs = mklhs(mode, role, key)

  local vim_opts = opts.vim_opts
  local existing = vim.fn.maparg(lhs, mode, false, true) as t.vim.VimRawMapInfo
  collisions(existing, mode, lhs, rhs, vim_opts.desc or "")

  vim.keymap.set(mode, lhs, rhs, vim_opts)

  local rhs_str: string
  if type(rhs) == "string" then
    rhs_str = rhs as string
  else
    rhs_str = "<lua>"
  end

  register_hotkey_once({
    mode = mode,
    role = role,
    key = key,
    internal = true,
    rhs = rhs_str,
    desc = vim_opts.desc or "",
    tags = t.roles.complete(role, opts.tags, false),
    group = nil,
  } as hotkeys.RakhshKeymap)
end

function M.docmap(
  mode: string,
  lhs: string,
  opts: RakhshMapOpts
): nil
  -- Existing (global) mapping may or may not exist at registration time.
  local existing_any = vim.fn.maparg(lhs, mode, false, true)
  local existing: t.vim.VimRawMapInfo | nil = nil
  if existing_any ~= nil then
    local e = existing_any as t.vim.VimRawMapInfo
    if e.lhs ~= nil then
      existing = e
    end
  end

  local role, tail = decode_lhs(mode, lhs)

  local rhs_str: string = "?"
  local existing_desc: string = ""
  if existing ~= nil then
    local e = existing as t.vim.VimRawMapInfo
    if e.callback ~= nil then
      rhs_str = "<lua>"
    else
      rhs_str = e.rhs as string or "?"
    end
    existing_desc = e.desc or ""
  end

  register_hotkey_once({
    mode = mode,
    role = role,
    key = tail,
    internal = false,
    rhs = rhs_str,
    desc = (opts.vim_opts.desc or existing_desc),
    tags = t.roles.complete(role, opts.tags, false),
    group = nil,
  } as hotkeys.RakhshKeymap)
end

function M.safemap_buf(
  bufnr: integer,
  mode: string,
  role: t.roles.Role,
  key: string,
  rhs: any,
  opts: RakhshMapOpts
): nil
  local lhs = mklhs(mode, role, key)

  local vim_opts = opts.vim_opts
  local existing: t.vim.VimRawMapInfo | nil = find_buf_map(bufnr, mode, lhs)
  collisions(existing, mode, lhs, rhs, vim_opts.desc or "")

  local merged = vim.tbl_extend("force", vim_opts as {string : any}, { buffer = bufnr } as {string : any})
  vim.keymap.set(mode, lhs, rhs, merged as t.vim.VimMapOpts)

  local rhs_str: string
  if type(rhs) == "string" then
    rhs_str = rhs as string
  else
    rhs_str = "<lua>"
  end

  register_hotkey_once({
    mode = mode,
    role = role,
    key = key,
    internal = true,
    rhs = rhs_str,
    desc = (merged as t.vim.VimMapOpts).desc,
    tags = t.roles.complete(role, opts.tags, false),
    group = nil,
  } as hotkeys.RakhshKeymap, bufnr)
end

function M.docmap_buf(
  bufnr: integer,
  mode: string,
  lhs: string,
  opts: RakhshMapOpts
): nil
  -- Some mappings (notably Neovim runtime defaults) can be visible via maparg
  -- even when vim_buf_get_keymap doesn't report them the way expected. Fall
  -- back to maparg (by setting fallback to true).
  local existing = find_buf_map(bufnr, mode, lhs, true)

  local role, tail = decode_lhs(mode, lhs)

  local rhs_str: string = "?"
  local existing_desc: string = ""
  if existing ~= nil then
    local e = existing as t.vim.VimRawMapInfo
    if e.callback ~= nil then
      rhs_str = "<lua>"
    else
      rhs_str = e.rhs as string or "?"
    end
    existing_desc = e.desc or ""
  end

  register_hotkey_once({
    mode = mode,
    role = role,
    key = tail,
    internal = false,
    rhs = rhs_str,
    desc = (opts.vim_opts.desc or existing_desc),
    tags = t.roles.complete(role, opts.tags, false),
    group = nil,
  } as hotkeys.RakhshKeymap, bufnr)
end

function M.opts(desc: string, tags: {t.tags.Tag}): RakhshMapOpts
  if #tags == 0 then
    error("opts: tags must be non-empty")
  end

  local vim_opts: t.vim.VimMapOpts = {
    noremap = true,
    silent  = true,
    desc    = desc,
  }

  local out: RakhshMapOpts = {
    vim_opts = vim_opts,
    tags = tags,
  }

  return out
end


function M.make_entry(keymap: hotkeys.RakhshKeymap): TelescopeEntry
  -- `keymap.key` is the role-local tail; reconstruct the real lhs for display/search.
  local lhs = mklhs(keymap.mode, keymap.role, keymap.key)

  local tags_str = ""
  for i, tag in ipairs(keymap.tags) do
    if i == 1 then
      tags_str = tag.tid
    else
      tags_str = tags_str .. " " .. tag.tid
    end
  end

  local desc = keymap.desc or ""
  local rhs  = keymap.rhs  or ""

  return {
    value = keymap,
    display = string.format("%s  %s", lhs, desc),
    -- Search should match key sequence, description, rhs/command, and tags.
    ordinal = table.concat({ lhs, desc, rhs, tags_str }, " "),
  } as TelescopeEntry
end

return M
-- }=-
