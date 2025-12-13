local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table; local _tags = require("types.tags")
local T = _tags.Tag
local Ts = _tags.Tags

local Role = {}





local RoleSet = {}















setmetatable(RoleSet, { __newindex = function() error("Cannot add new enum values to RoleSet") end })

local Roles = {
   Naked = { name = "Immediate", tag = "r/naked", desc = "These are not protected by any preceding keystrokes" },
   Power = { name = "PowerTool", tag = "r/power", desc = "Power moves to charm" },
   TUI = { name = "TextualUserInterface", tag = "r/tui", desc = "The Rakhsh IDE" },
   Go = { name = "NavigationGo", tag = "r/go", desc = "Immediate navigation: single-step jumps with no UI" },
   GoVia = { name = "NavigationVia", tag = "r/go", desc = "Navigation via an intermediate UI (pickers, lists, dialogs)" },
   Window = { name = "WindowManagement", tag = "r/native/w", desc = "TUI Window management" },
   Toggle = { name = "Toggle", tag = "r/toggle", desc = "It goes on... it goes off" },
   Info = { name = "Information", tag = "r/info", desc = "Strictly non-mutating commands" },
   AI = { name = "ArtificialIntelligence", tag = "r/ai", desc = "Anything involving AI or LLM API calls" },
   SCM = { name = "SourceControlManagement", tag = "r/git", desc = "Anything related to Git" },
   LSP = { name = "LanguageServerProtocol", tag = "r/lsp", desc = "All LSP-related hotkeys" },
   LSPInfo = { name = "LSPInfo", tag = "r/lsp", desc = "LSP inspection / info" },
   LSPEdit = { name = "LSPEdit", tag = "r/lsp", desc = "LSP edits / refactors" },
   LSPDiag = { name = "LSPDiagnostics", tag = "r/lsp", desc = "LSP diagnostics" },
}
setmetatable(Roles, { __newindex = function() error("Cannot add new enum values to Roles") end })

local ActivationPrefix = {
   n = {
      [Roles.Naked] = "",
      [Roles.Power] = "\\",
      [Roles.TUI] = "<Tab>",
      [Roles.Go] = "g",
      [Roles.GoVia] = "<C-g>",
      [Roles.Window] = "<C-w>",
      [Roles.Toggle] = "<Esc>",
      [Roles.Info] = "<F2>",
      [Roles.AI] = "<F5>",
      [Roles.SCM] = "<F10>",
      [Roles.LSPInfo] = "<F12>",
      [Roles.LSPEdit] = "<C-F12>",
      [Roles.LSPDiag] = "<S-F12>",
   },
   v = { [Roles.AI] = "<F5>" },
   i = {},
}
setmetatable(ActivationPrefix, { __newindex = function() error("Cannot add new enum values to Roles") end })

local function complete(role, tags, external)
   local out = {}
   table.move(tags, 1, #tags, 1, out)
   out[#out + 1] = { tid = role.tag }
   if external then out[#out + 1] = Ts.External end
   return out
end

local M = {
   Role = Role,
   Roles = Roles,
   ActivationPrefix = ActivationPrefix,
   complete = complete,
}

return M
