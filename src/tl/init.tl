require("core.rakhsh")
require("core.options")

local hotkeys = require("core.hotkeys")
hotkeys.init()

require("core.plugins").init({
  "plugins.mini",           -- Mini.nvim
  "plugins.finder",         -- Telescope, fzf, etc.
  "plugins.cursor",         -- Cursor highlight
  "plugins.lsp",            -- LSP
  "plugins.buffed",         -- Buffers (bufferin,buffferline,nvim-web-devicons)
  "plugins.navigation",     -- Navigation (which-key)
  "plugins.cmp",            -- Autocomplete
  "plugins.statusline",     -- Statusline
  "plugins.git",            -- Git
  "plugins.illiterate",     -- Syntax Highlighting
  "plugins.tui",            -- Dialogue Windows & Panels
  "plugins.fsh",            -- Filesyste Hierarchy
  "plugins.md",             -- Markdown
  "plugins.lint",           -- Lint
  "plugins.observer",       -- Observer
  "plugins.dialogues",      -- Pop-up dialogues
  "plugins.terminal",       -- Terminal integration
  "plugins.affordance",     -- Affordance (themes, colors, icons)
  "plugins.splash",         -- Splash screen
})
