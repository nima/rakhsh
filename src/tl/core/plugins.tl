local t = require("core.types")
local keymaps = require("core.keymaps")
local R = t.roles.Roles
local T = t.tags.Tags
local OnEvents = t.plugins.KeymapEvents

local plugs: {string} = {}

local type PluginSpec = t.plugins.PluginSpec

local function bare(repo: string): PluginSpec
  -- first element is the repo for lazy.nvim, extra named fields for Teal
  return { repo, repo = repo } as PluginSpec
end

local plugins: {PluginSpec} = {
  bare("L3MON4D3/LuaSnip"), -- Snippets
}

global vim: t.vim.Vim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local function setup_lazy(missing_install: boolean): boolean
  if not (vim.loop and vim.loop.fs_stat and vim.loop.fs_stat(lazypath)) then
    return false
  end

  vim.opt.rtp:prepend(lazypath)

  local modstr = "lazy"
  local record Lazy
    setup: function({PluginSpec}, {string:any} | nil): any
  end
  local lazy = (require(modstr) as Lazy)
  lazy.setup(plugins, {
    install = { missing = missing_install },
    checker = { enabled = false },
  })

  --[[
  local theme = vim.g.colorscheme as string
  local ok, _ = pcall(vim.cmd, "colorscheme " .. theme)
  if not ok then
    vim.notify("rakhsh[colorcheme]: '" .. theme .. "' not found (install themes and restart)", vim.log.levels.WARN, nil)
  end
  ]]--

  return true
end

local function RakhshLazyInstall(): nil
  if not (vim.loop and vim.loop.fs_stat and vim.loop.fs_stat(lazypath)) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
  end

  vim.api.nvim_create_autocmd("User", {
    once = true,
    pattern = { "LazyInstall", "LazySync", "LazyDone" },
    callback = function(_ev)
      vim.schedule(function()
        vim.cmd("qa")
      end)
    end,
  })

  if not setup_lazy(true) then
    vim.notify("rakhsh: lazy.nvim install failed", vim.log.levels.ERROR, nil)
    return
  end
end

local record CorePluginsModule
  init: function(plugin_modules: {string}): nil
  install: function(): nil
  apply_plugin_keymaps: function(plugin_name: string): nil
  apply_plugin_attach_keymaps: function(modname: string, bufnr: integer): nil
  validate_keymaps: function(): nil
end

local type PluginModule = t.plugins.PluginModule

-- Modules that define buffer-local (on-attach) keymaps and should be
-- validated during the post-validate step.
local validate_attach_plugins = {
  "plugins.lsp",
}

local record KeymapSpec
  keymaps: {t.plugins.PluginKeymap} | nil
end

local function validate_plugin_keymap(src: string, km: t.plugins.PluginKeymap): nil
  if km.mode == nil or km.mode == "" then
    error(("apply_plugin_keymaps[%s]: keymap missing mode (%s)"):format(src, km.key or "?"), 2)
  end
  if km.role == nil then
    error(("apply_plugin_keymaps[%s]: keymap missing role (key = %s, desc = %s)"):format(src, km.key or "?", km.desc or "?"), 2)
  end
  if type(km.role) ~= "table" or km.role._tag == nil then
    error(("apply_plugin_keymaps[%s]: invalid role for key %s (desc = %s): %s"):format(src, km.key or "?", km.desc or "?", tostring(km.role)), 2)
  end
  if km.key == nil or km.key == "" then
    error(("apply_plugin_keymaps[%s]: keymap missing key"):format(src), 2)
  end
  if km.rhs == nil then
    error(("apply_plugin_keymaps[%s]: keymap missing rhs (%s)"):format(src, km.key or "?"), 2)
  end
  if km.desc == nil or km.desc == "" then
    error(("apply_plugin_keymaps[%s]: keymap missing desc (%s)"):format(src, km.key or "?"), 2)
  end
  if km.tags == nil or #km.tags == 0 then
    error(("apply_plugin_keymaps[%s]: keymap missing tags (%s)"):format(src, km.key or "?"), 2)
  end
end

local function apply_plugin_attach_keymaps_impl(modname: string, bufnr: integer): nil
  local mod = (require(modname) as PluginModule)
  if mod.lazy == nil then return nil end

  local spec = (mod.lazy() as KeymapSpec)
  local keymapspecs = spec.keymaps as {t.plugins.PluginKeymap}
  for _, km in ipairs(keymapspecs) do
    if km.on == t.plugins.KeymapEvents.Attach then
      validate_plugin_keymap(("%s (attach)"):format(modname), km)
      keymaps.safemap_buf(bufnr, km.mode, km.role, km.key, km.rhs, keymaps.opts(km.desc, km.tags as {t.tags.Tag}))
    end
  end
end

local function apply_plugin_keymaps_impl(plugin_name: string): nil
  local mod = (require(plugin_name) as PluginModule)
  if mod.lazy == nil then return nil end

  local spec = (mod.lazy() as KeymapSpec)
  if spec == nil then
    error(("apply_plugin_keymaps[%s]: failed to load module"):format(plugin_name), 2)
  end

  local keymapspecs = spec.keymaps as {t.plugins.PluginKeymap}
  for _, km in ipairs(keymapspecs) do
    local effective_desc = km.desc

    local rendered: {string} = {}
    local taglist = km.tags as {t.tags.Tag}
    for _, tag in ipairs(taglist) do
      table.insert(rendered, "#" .. tag._tag)
    end

    if #rendered > 0 then
      effective_desc = ("%s %s"):format(effective_desc, table.concat(rendered, " "))
    end

    if km.on == nil or km.on == OnEvents.Immediate then
      local ok, err = pcall(keymaps.safemap, km.mode, km.role, km.key, km.rhs, {
        noremap = true,
        silent  = true,
        desc    = effective_desc,
      })
      if not ok then
        error(("apply_plugin_keymaps[%s]: failed to install %s (%s): %s"):format(plugin_name, km.key, km.desc, tostring(err)), 2)
      end
    end
  end
end

local function validate_keymaps_impl(): nil
  local bufnr = vim.api.nvim_create_buf(false, true)

  for _, modname in ipairs(validate_attach_plugins) do
    local ok, err = pcall(apply_plugin_attach_keymaps_impl, modname, bufnr)
    if not ok then
      error(("validate_keymaps[%s]: %s"):format(modname, tostring(err)))
    end
  end
end

local initialized = false
local function ensure_initialized(): nil
  if initialized then return end
  for _, _mod in ipairs(plugs) do
    local mod = (require(_mod) as PluginModule)
    if mod.init ~= nil then mod.init() end
    if mod.lazy ~= nil then
      local spec = mod.lazy()
      plugins[#plugins + 1] = spec
    end
    -- TODO: move to mod.setup()
    apply_plugin_keymaps_impl(_mod)
  end
  initialized = true
end

vim.api.nvim_create_autocmd("UIEnter", {
  once = true,
  callback = function()
    ensure_initialized()
    if setup_lazy(false) then return end
    RakhshLazyInstall()
  end,
})

local M: CorePluginsModule = {} as CorePluginsModule

M.install = RakhshLazyInstall
M.apply_plugin_keymaps = apply_plugin_keymaps_impl
M.apply_plugin_attach_keymaps = apply_plugin_attach_keymaps_impl
M.validate_keymaps = validate_keymaps_impl

function M.init(plugin_modules: {string}): nil
  plugs = plugin_modules
  keymaps.safemap("n", R.Toggle, "I", M.install, keymaps.opts("Install Rakhsh IDE", { T.ActionLaunch }))
  ensure_initialized()
end

return M
