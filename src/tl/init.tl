--= 0. Core wiring (no plugin assumptions)
require("core.rakhsh")
require("core.options")

local terminal = require("core.terminal")
terminal.init()

local cursor = require("core.cursor")
cursor.init()

require("core.plugins").init({
  "plugins.lsp",        -- LSP
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
  "plugins.hotkeys",    -- Hotkeys (Ad-Hoc shortcuts and WhichKey cheatsheets)
  "plugins.folds",      -- Special Comment Folds
  "plugins.lint",       -- Lint
  "plugins.observer",   -- Observer
  "plugins.dialogues",  -- Pop-up dialogues
  --"plugins.odbc",     -- Database connections
})
