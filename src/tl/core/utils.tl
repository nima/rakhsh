local t = require("core.types")

global vim: t.vim.Vim
local type PluginModule = t.plugins.PluginModule
local On                = t.plugins.KeymapEvents

-- Modules that define buffer-local (on-attach) keymaps and should be
-- validated during the post-validate step.
local validate_attach_plugins = {
  "plugins.lsp",
}

local record KeymapSpec
  keymaps: {t.plugins.PluginKeymap} | nil
end

local record UtilsModule
  Roles: {string : t.roles.Role}
  Tags:  {string : t.tags.Tag}
  safemap: function(mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  safemap_buf: function(bufnr: integer, mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  opts: function(desc: string | nil, tags: {t.tags.Tag}): t.vim.VimMapOpts
  install_keymap: function(src: string, km: t.plugins.PluginKeymap): nil
  apply_plugin_keymaps: function(plugin_name: string): nil
  apply_plugin_attach_keymaps: function(modname: string, bufnr: integer): nil
  validate_keymaps: function(): nil
end

local M: UtilsModule = {
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
 
local function collisions(existing: t.vim.VimRawMapInfo|nil, mode: string, lhs: string, rhs: any): nil
  --+ no mapping exists → no conflict
  if existing == nil then return end

  local info = existing as t.vim.VimRawMapInfo
  if info.lhs == nil then return end

  local caller = debug.getinfo(2, "Sl")

  error((
    "Keymap conflict for [%s] in mode '%s'\n" ..
    "Existing: %s -> %s  (set in %s:%s)\n" ..
    "New:      %s -> %s  (attempted in %s:%s)\n" ..
    "Tip: :verbose %smap %s"
  ):format(
    lhs,
    mode,
    info.lhs or lhs,
    info.rhs or "?",
    info.script or "?",
    info.lnum or -1,
    lhs,
    type(rhs) == "string" and rhs or "<Lua fn>",
    caller.short_src or "?", caller.currentline or -1,
    mode,
    lhs
  ))
end

local function find_buf_map(bufnr: integer, mode: string, lhs: string): t.vim.VimRawMapInfo | nil
  local maps = (vim.api.nvim_buf_get_keymap(bufnr, mode) as {t.vim.VimRawMapInfo})

  for _, m in ipairs(maps) do
    if m.lhs == lhs then
      return m
    end
  end

  return nil
end

function M.safemap_buf(bufnr: integer, mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  local lhs = mklhs(mode, role, key)
  local existing = find_buf_map(bufnr, mode, lhs)
  collisions(existing, mode, lhs, rhs)
  local merged = vim.tbl_extend("force", (opts as {string : any}), { buffer = bufnr } as {string : any})
  vim.keymap.set(mode, lhs, rhs, merged as t.vim.VimMapOpts)
end

function M.safemap(mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
  local lhs = mklhs(mode, role, key)
  local existing = vim.fn.maparg(lhs, mode, false, true) as t.vim.VimRawMapInfo
  collisions(existing, mode, lhs, rhs)
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.apply_plugin_attach_keymaps(modname: string, bufnr: integer): nil
  local mod = (require(modname) as PluginModule)
  if mod.lazy == nil then return nil end

  local spec = (mod.lazy() as KeymapSpec)
  if not spec.keymaps then return end

  local keymaps = spec.keymaps as {t.plugins.PluginKeymap}
  for _, km in ipairs(keymaps) do
    if km.on == t.plugins.KeymapEvents.Attach then
      M.safemap_buf(bufnr, km.mode, km.role, km.key, km.rhs, M.opts(km.desc, km.tags))
    end
  end
end

function M.install_keymap(src: string, km: t.plugins.PluginKeymap): nil
  if km.mode == nil or km.mode == "" then error(("apply_plugin_keymaps[%s]: keymap missing mode (%s)"):format(src, km.key or "?"), 2) end
  if km.role == nil then error(("apply_plugin_keymaps[%s]: keymap missing role (%s)"):format(src, km.key or "?"), 2) end
  if km.key == nil or km.key == "" then error(("apply_plugin_keymaps[%s]: keymap missing key"):format(src), 2) end
  if km.rhs == nil then error(("apply_plugin_keymaps[%s]: keymap missing rhs (%s)"):format(src, km.key or "?"), 2) end
  if km.desc == nil or km.desc == "" then error(("apply_plugin_keymaps[%s]: keymap missing desc (%s)"):format(src, km.key or "?"), 2) end
  if km.tags == nil or #km.tags == 0 then error(("apply_plugin_keymaps[%s]: keymap missing tags (%s)"):format(src, km.key or "?"), 2) end
  if km.on == nil then km.on = On.Immediate end

  local effective_desc = km.desc

  local rendered: {string} = {}
  local taglist = km.tags as {t.tags.Tag}

  for _, tag in ipairs(taglist) do
    table.insert(rendered, "#" .. tag._tag)
  end

  if #rendered > 0 then
    effective_desc = ("%s %s"):format(effective_desc, table.concat(rendered, " "))
  end

  if km.on and km.on == On.Immediate then
    local ok, err = pcall(M.safemap, km.mode, km.role, km.key, km.rhs, {
      noremap = true,
      silent = true,
      desc = effective_desc
    })
    if not ok then
      error(("apply_plugin_keymaps[%s]: failed to install %s (%s): %s"):format(src, km.key, km.desc, tostring(err)), 2)
    end
  end
end

function M.apply_plugin_keymaps(plugin_name: string): nil
  local mod = (require(plugin_name) as PluginModule)
  if mod.lazy == nil then return nil end

  local spec = (mod.lazy() as KeymapSpec)
  if spec == nil then
    error(("apply_plugin_keymaps[%s]: failed to load module"):format(plugin_name), 2)
  end

  local keymaps = spec.keymaps as {t.plugins.PluginKeymap}
  for _, km in ipairs(keymaps) do
    M.install_keymap(plugin_name, km)
  end
end

function M.validate_keymaps(): nil
  -- Runtime keymap validation for CI / `make install`.
  -- We run in a headless Neovim after the config has loaded, so all
  -- global/immediate mappings are already installed. Here we simulate
  -- LspAttach-style keymaps on a scratch buffer: if any mapping would
  -- collide, safemap_buf / collisions will raise and cause the build
  -- to fail.

  -- Create an unlisted scratch buffer.
  local bufnr = vim.api.nvim_create_buf(false, true)

  for _, modname in ipairs(validate_attach_plugins) do
    local ok, err = pcall(M.apply_plugin_attach_keymaps, modname, bufnr)
    if not ok then
      error(("validate_keymaps[%s]: %s"):format(modname, tostring(err)))
    end
  end
end

function M.opts(desc: string | nil, tags: {t.tags.Tag}): t.vim.VimMapOpts
  local effective_desc = desc or ""

  if tags ~= nil then
    local rendered: {string} = {}

    for _, tag in ipairs(tags) do
      table.insert(rendered, "#" .. tag._tag)
    end

    if #rendered > 0 then
      local tag_str = table.concat(rendered, ", ")
      if effective_desc ~= "" then
        effective_desc = ("%s [%s]"):format(effective_desc, tag_str)
      else
        effective_desc = ("[%s]"):format(tag_str)
      end
    end
  end

  local out: t.vim.VimMapOpts = {
    noremap = true,
    silent  = true,
    desc    = effective_desc,
  }

  return out
end

return M
