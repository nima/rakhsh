local t = require("core.types")
local u = require("core.utils")
global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginModule = t.plugins.PluginModule

local plugs: {string} = {
  "plugins.lsp",        -- LSP
  "plugins.themes",     -- Themes
  "plugins.cmp",        -- Autocomplete
  "plugins.telescope",  -- Telescope
  "plugins.statusline", -- Statusline
  "plugins.git",        -- Git
  "plugins.illiterate", -- Syntax Highlighting
  "plugins.tui",        -- Dialogue Windows & Panels
  "plugins.fsh",        -- Filesyste Hierarchy
  "plugins.llm",        -- Large Language Models (DeepSeek, etc.)
  "plugins.md",         -- Markdown
  "plugins.hotkeys",    -- Hotkeys (Ad-Hoc shortcuts and WhichKey cheatsheets)
  "plugins.cursor",     -- Cursor position
  "plugins.comments",   -- Tagged Comment
  "plugins.folds",      -- Special Comment Folds
  "plugins.lint",       -- Lint
  "plugins.observer",   -- Observer
}

local function bare(repo: string): PluginSpec
  -- first element is the repo for lazy.nvim, extra named fields for Teal
  return { repo, repo = repo } as PluginSpec
end

local plugins: {PluginSpec} = {
  bare("L3MON4D3/LuaSnip"),                 -- Snippets
  --bare("Kicamon/markdown-table-mode.nvim"), -- Markdown table management
}

for _, _mod in ipairs(plugs) do
  local mod = (require(_mod) as PluginModule)
  if mod.init ~= nil then mod.init() end

  if mod.lazy ~= nil then
    local spec = mod.lazy()
    plugins[#plugins + 1] = spec
  end

  --TODO: move to mod.setup()
  u.apply_plugin_keymaps(_mod)
end

local record Lazy
  setup: function({PluginSpec}, {string:any} | nil): any
end
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

local function setup_lazy(missing_install: boolean): boolean
  if not (vim.loop and vim.loop.fs_stat and vim.loop.fs_stat(lazypath)) then
    return false
  end

  vim.opt.rtp:prepend(lazypath)

  local modstr = "lazy"
  local lazy = (require(modstr) as Lazy)
  lazy.setup(plugins, {
    install = { missing = missing_install },
    checker = { enabled = false },
  })

  local theme = vim.g.colorscheme as string
  local ok, _ = pcall(vim.cmd, "colorscheme " .. theme)
  if not ok then
    vim.notify("rakhsh[colorcheme]: '" .. theme .. "' not found (install themes and restart)", vim.log.levels.WARN, nil)
  end

  return true
end

global function RakhshLazyInstall()
  if not (vim.loop and vim.loop.fs_stat and vim.loop.fs_stat(lazypath)) then
    vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
  end

  if not setup_lazy(true) then
    vim.notify("rakhsh: lazy.nvim install failed", vim.log.levels.ERROR, nil)
    return
  end
end

if not setup_lazy(false) then
  vim.notify("rakhsh: plugins are not installed yet. Press <leader>Li to install with Lazy.", vim.log.levels.INFO, nil)
end

vim.keymap.set("n", "<leader>Li", RakhshLazyInstall, { silent = true })
