local record Role
  _tag: string
  desc: string
end

local record RoleSet
    Naked:   Role
    Power:   Role
    Go:      Role
    GoVia:   Role
    Win:     Role
    Toggle:  Role
    Info:    Role
    TUI:     Role
    AI:      Role
    SCM:     Role
    LSP:     Role
    LSPInfo: Role
    LSPEdit: Role
    LSPDiag: Role
end
setmetatable(RoleSet, { __newindex = function() error("Cannot add new enum values to RoleSet") end })

local Roles: RoleSet = {
    Naked   = { _tag = "Immediate", desc = "These are not protected by any preceding keystrokes" },
    Power   = { _tag = "PowerTool", desc = "Power moves to charm" },
    Go      = { _tag = "NavigationGo", desc = "Immediate navigation: single-step jumps with no UI" },
    GoVia   = { _tag = "NavigationVia", desc = "Navigation via an intermediate UI (pickers, lists, dialogs)" },
    Win     = { _tag = "WindowManagement", desc = "TUI Window management" },
    Toggle  = { _tag = "Toggle", desc = "It goes on... it goes off" },
    Info    = { _tag = "Information", desc = "Strictly non-mutating commands" },
    TUI     = { _tag = "TextualUserInterface", desc = "The Rakhsh IDE" },
    AI      = { _tag = "ArtificialIntelligence", desc = "Anything involving AI or LLM API calls" },
    SCM     = { _tag = "SourceControlManagement", desc = "Anything related to Git" },
    LSP     = { _tag = "LanguageServerProtocol", desc = "All LSP-related hotkeys" },
    LSPInfo = { _tag = "LSPInfo", desc = "LSP inspection / info" },
    LSPEdit = { _tag = "LSPEdit", desc = "LSP edits / refactors" },
    LSPDiag = { _tag = "LSPDiagnostics", desc = "LSP diagnostics" },
}
setmetatable(Roles, { __newindex = function() error("Cannot add new enum values to Roles") end })

local ActivationPrefix: {string: {Role: string}} = {
    n = {
        [Roles.Naked]   = "",
        [Roles.Power]   = "\\",
        [Roles.Go]      = "g",
        [Roles.GoVia]   = "<C-g>",
        [Roles.Win]     = "<C-w>",
        [Roles.Toggle]  = "<Esc>",
        [Roles.Info]    = "<F2>",
        [Roles.TUI]     = "<F3>",
        [Roles.AI]      = "<F5>",
        [Roles.SCM]     = "<F10>",
        [Roles.LSPInfo] = "<F12>",
        [Roles.LSPEdit] = "<C-F12>",
        [Roles.LSPDiag] = "<S-F12>",
    },
    v = { [Roles.AI] = "<Leader>i", },
    i = {},
}
setmetatable(ActivationPrefix, { __newindex = function() error("Cannot add new enum values to Roles") end })

local M = {
    Role             = Role,
    Roles            = Roles,
    ActivationPrefix = ActivationPrefix,
}

return M
