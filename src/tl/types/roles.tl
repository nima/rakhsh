local _tags = require("types.tags")
local T = _tags.Tag
local Ts = _tags.Tags

local record Role
  name: string
  tag: string
  desc: string
end

local record RoleSet
  Naked:   Role
  Power:   Role
  TUI:     Role
  Go:      Role
  GoVia:   Role
  Window:  Role
  Toggle:  Role
  Info:    Role
  Select:  Role
  View:    Role
  Edit:    Role
  System:  Role
  Layout:  Role
  ForRent: Role
  Rakhsh:  Role
  AI:      Role
  SCM:     Role
  LSP:     Role
  LSPGoto: Role
  LSPInfo: Role
  LSPEdit: Role
  LSPDiag: Role
end
setmetatable(RoleSet, { __newindex = function() error("Cannot add new enum values to RoleSet") end })

local Roles: RoleSet = {
    Naked   = { name = "Naked", tag = "r/naked", desc = "These are not protected by any preceding keystrokes" },
    Power   = { name = "PowerTool", tag = "r/power", desc = "Power moves to charm" },
    TUI     = { name = "TextualUserInterface", tag = "r/tui", desc = "The Rakhsh IDE" },
    Go      = { name = "NavigationGo", tag = "r/go", desc = "Immediate navigation: single-step jumps with no UI" },
    GoVia   = { name = "NavigationVia", tag = "r/go", desc = "Navigation via an intermediate UI (pickers, lists, dialogs)" },
    Window  = { name = "WindowManagement", tag = "r/native/w", desc = "TUI Window management" },
    Toggle  = { name = "Toggle", tag = "r/toggle", desc = "It goes on... it goes off" },
    Info    = { name = "Information", tag = "r/info", desc = "" },
    Select  = { name = "Select", tag = "r/info", desc = "TUI pane selection" },
    View    = { name = "View", tag = "r/info", desc = "View related" },
    Edit    = { name = "Editor", tag = "r/edit", desc = "Editor commands" },
    System  = { name = "System", tag = "r/edit", desc = "System related" },
    Layout  = { name = "Layout", tag = "r/edit", desc = "Layout related" },
    ForRent = { name = "ThisSpaceForRent", tag = "r/edit", desc = "This space for rent" },
    Rakhsh  = { name = "RakhshIDE", tag = "r/ide", desc = "The Rakhsh IDE" },
    AI      = { name = "ArtificialIntelligence", tag = "r/ai", desc = "Anything involving AI or LLM API calls" },
    SCM     = { name = "SourceControlManagement", tag = "r/git", desc = "Anything related to Git" },
    LSP     = { name = "LanguageServerProtocol", tag = "r/lsp", desc = "All LSP-related hotkeys" },
    LSPGoto = { name = "LSPGoto", tag = "r/lsp", desc = "LSP goto" },
    LSPInfo = { name = "LSPInfo", tag = "r/lsp", desc = "LSP inspection / info" },
    LSPEdit = { name = "LSPEdit", tag = "r/lsp", desc = "LSP edits / refactors" },
    LSPDiag = { name = "LSPDiagnostics", tag = "r/lsp", desc = "LSP diagnostics" },
}
setmetatable(Roles, { __newindex = function() error("Cannot add new enum values to Roles") end })

local ActivationPrefix: {string: {Role: string}} = {
    n = {
        [Roles.Naked]   = "",
        [Roles.Power]   = "\\",
        [Roles.TUI]     = "<Tab>", --+ AKA <C-i>
        [Roles.Go]      = "g",
        [Roles.GoVia]   = "<C-g>",
        [Roles.Window]  = "<C-w>",
        [Roles.Toggle]  = "<Esc>",
        [Roles.Info]    = "<F2>",
        [Roles.Select]  = "<S-*>",
        [Roles.View]    = "<A-*>",
        [Roles.Edit]    = "<C-*>",
        [Roles.System]  = "<C-S-*>",
        [Roles.Layout]  = "<A-S-*>",
        [Roles.ForRent] = "<C-A-*>",
        [Roles.Rakhsh]  = "<C-A-S-*>",
        [Roles.AI]      = "<F5>",
        [Roles.SCM]     = "<F10>",
        [Roles.LSPInfo] = "<F12>",
        [Roles.LSPEdit] = "<C-F12>",
        [Roles.LSPDiag] = "<A-F12>",
        [Roles.LSPGoto] = "<S-F12>",
    },
    v = { [Roles.AI] = "<F5>", },
    i = {},
}
setmetatable(ActivationPrefix, { __newindex = function() error("Cannot add new enum values to Roles") end })

local function complete(role: Role, tags: {T}, external: boolean): {T}
  local out: {T} = {}
  table.move(tags, 1, #tags, 1, out)
  out[#out + 1] = { tid = role.tag } as T
  if external then out[#out + 1] = Ts.External end
  return out
end

local M = {
    Role             = Role,
    Roles            = Roles,
    ActivationPrefix = ActivationPrefix,
    complete         = complete,
}

return M
