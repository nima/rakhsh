local t = require("types")
local hotkeys = require("core.hotkeys")

-- Vim types are provided externally (extern/teal-types). We keep minimal boundary records here
-- for maparg/buf_get_keymap payloads and keymap.set opts.

local type VimMapOpts = vim.keymap.SetOpts

local record VimRawMapInfo
  lhs: string | nil
  rhs: string | nil
  desc: string | nil
  callback: any
  script: string | nil
  lnum: integer | nil
end

--= Types -={ 
local record RakhshMapOpts
  vim_opts: VimMapOpts
  tags: {t.tags.Tag}
end

-- Minimal Telescope entry type used by our picker.
local record TelescopeEntry
  value: hotkeys.RakhshKeymap
  display: string
  ordinal: string
end

local record KeymapModule
  Roles: {string : t.roles.Role}
  Tags:  {string : t.tags.Tag}
  safemap: function(
    mode: string,
    role: t.roles.Role,
    key: string,
    rhs: string | function(...: any): any,
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
    rhs: string | function(...: any): any,
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

  --& Wildcard leaders like `<C-*>` / `<A-*>` / `<S-*>`.
  local leader = role.leader
  if leader:find("%*") then
    local rplc, cnt = leader:gsub("%*", key)
    if cnt == 1 then return rplc end
    error("Expected 1 literal asterisk; received " .. tostring(cnt) .. ": " .. leader)
  end

  return leader .. key
end

--! TODO: Deprecate decode_lhs; pass in role directly
local function decode_lhs(mode: string, lhs: string): (t.roles.Role, string)
  --+ Derive decode rules from Roles[*].leader. `mode` is only used for error messages.
  local best_role: t.roles.Role | nil = nil
  local best_tail: string = ""
  local best_len: integer = -1

  for _, any_role in pairs(t.roles.Roles as {string:any}) do
    if type(any_role) == "table" and (any_role as {string:any}).name ~= nil and (any_role as {string:any}).leader ~= nil then
      local role = any_role as t.roles.Role
      local leader = role.leader

      if leader == "" and best_len < 0 then
        --+ Naked role matches anything, but only if we didn't find a more specific match.
        best_role = role
        best_tail = lhs
        best_len = 0
      elseif leader:find("%*") then
        --+ Convert leader containing `*` into a Lua pattern that captures the wildcard.
        --& `<C-*>` -> `^<C%-(.+)>$`
        local pat = "^" .. leader:gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1"):gsub("%%%*", "(.+)") .. "$"
        local cap = lhs:match(pat)
        if cap ~= nil then
          local eff_len = #leader - 1
          if eff_len > best_len then
            best_role = role
            best_tail = cap as string
            best_len = eff_len
          end
        end
      else
        if lhs:sub(1, #leader) == leader then
          local tail = lhs:sub(#leader + 1)
          local eff_len = #leader
          if eff_len > best_len then
            best_role = role
            best_tail = tail
            best_len = eff_len
          end
        end
      end
    end
  end

  if best_role == nil then
    error(("docmap: could not decode lhs '%s' for mode '%s'"):format(lhs, mode))
  end

  return best_role, best_tail
end

local function same_rhs(info: VimRawMapInfo, rhs: string | function(...: any): any): boolean
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

local function collisions(_existing: VimRawMapInfo | nil, mode: string, lhs: string, rhs: string | function(...: any): any, desc: string): nil
  if _existing == nil then return end

  local existing = _existing as VimRawMapInfo
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

local function find_buf_map(bufnr: integer, mode: string, lhs: string, fallback?: boolean): VimRawMapInfo | nil
  local maps = (vim.api.nvim_buf_get_keymap(bufnr, mode) as {VimRawMapInfo})
  for _, info in ipairs(maps) do
    if info.lhs == lhs then return info end
  end

  if not fallback then return nil end

  local any = vim.fn.maparg(lhs, mode, false, true)
  if any == nil then return nil end

  local e = any as VimRawMapInfo
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
  rhs: string | function(...: any): any,
  opts: RakhshMapOpts
): nil
  local lhs = mklhs(mode, role, key)

  local vim_opts = opts.vim_opts
  local existing = vim.fn.maparg(lhs, mode, false, true) as VimRawMapInfo
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
  local existing: VimRawMapInfo | nil = nil
  if existing_any ~= nil then
    local e = existing_any as VimRawMapInfo
    if e.lhs ~= nil then
      existing = e
    end
  end

  --! TODO: Deprecate decode_lhs; pass in role directly
  local role, tail = decode_lhs(mode, lhs)

  local rhs_str: string = "?"
  local existing_desc: string = ""
  if existing ~= nil then
    local e = existing as VimRawMapInfo
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
  rhs: string | function(...: any): any,
  opts: RakhshMapOpts
): nil
  local lhs = mklhs(mode, role, key)

  local vim_opts = opts.vim_opts
  local existing: VimRawMapInfo | nil = find_buf_map(bufnr, mode, lhs)
  collisions(existing, mode, lhs, rhs, vim_opts.desc or "")

  local merged: VimMapOpts = {
    desc   = vim_opts.desc,
    silent = vim_opts.silent,
    remap  = vim_opts.remap,
    nowait = vim_opts.nowait,
    expr   = vim_opts.expr,
    buffer = bufnr,
  }
  vim.keymap.set(mode, lhs, rhs, merged)

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
    desc = merged.desc,
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

  --! TODO: Deprecate decode_lhs; pass in role directly
  local role, tail = decode_lhs(mode, lhs)

  local rhs_str: string = "?"
  local existing_desc: string = ""
  if existing ~= nil then
    local e = existing as VimRawMapInfo
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

  local vim_opts: VimMapOpts = {
    silent  = true,
    desc    = desc,
    remap   = false,
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
  }
end

return M
-- }=-
