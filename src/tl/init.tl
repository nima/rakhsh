require("core.rakhsh")
require("core.options")

local telescope = require("core.telescope")
telescope.init()

local cursor = require("core.cursor")
cursor.init()

local hotkeys = require("core.hotkeys")
hotkeys.init()

local terminal = require("core.terminal")
terminal.init()

require("core.plugins").init({
  "plugins.lsp",        -- LSP
  "plugins.buffed",     -- Buffers (bufferin,buffferline,nvim-web-devicons)
  "plugins.navigation", -- Navigation (which-key)
  "plugins.visuals",    -- Colorschemes, special comments, syntax highlighting
  "plugins.cmp",        -- Autocomplete
  "plugins.telescope",  -- Telescope
  "plugins.statusline", -- Statusline
  "plugins.git",        -- Git
  "plugins.illiterate", -- Syntax Highlighting
  "plugins.tui",        -- Dialogue Windows & Panels
  "plugins.fsh",        -- Filesyste Hierarchy
  "plugins.llm",        -- Large Language Models (DeepSeek, etc.)
  "plugins.md",         -- Markdown
  "plugins.folds",      -- Special Comment Folds
  "plugins.lint",       -- Lint
  "plugins.observer",   -- Observer
  "plugins.dialogues",  -- Pop-up dialogues
})
