local record Role
  _tag: string
  desc: string
end

local record RoleSet
    Toggle: Role
    Info:   Role
    TUI:    Role
    Nav:    Role
    AI:     Role
    LSP:    Role
    Power:  Role
    Win:    Role
    SCM:    Role
    Naked:  Role
end
setmetatable(RoleSet, { __newindex = function() error("Cannot add new enum values to RoleSet") end })

local Roles: RoleSet = {
    Toggle = { _tag = "Toggle", desc = "It goes on... it goes off" },
    Info   = { _tag = "Information", desc = "Strictly non-mutating commands" },
    TUI    = { _tag = "TextualUserInterface", desc = "The Rakhsh IDE" },
    Nav    = { _tag = "Navigation", desc = "All navigation-related hotkeys" },
    AI     = { _tag = "ArtificialIntelligence", desc = "Anything involving AI or LLM API calls" },
    LSP    = { _tag = "LanguageServerProtocol", desc = "All LSP-related hotkeys" },
    Power  = { _tag = "PowerTool", desc = "Power moves to charm" },
    Win    = { _tag = "WindowManagement", desc = "TUI Window management" },
    SCM    = { _tag = "SourceControlManagement", desc = "Anything related to Git" },
    Naked  = { _tag = "Immediate", desc = "These are not protected by any preceding keystrokes" },
}
setmetatable(Roles, { __newindex = function() error("Cannot add new enum values to Roles") end })

local ActivationPrefix: {string: {Role: string}} = {
    n = {
        [Roles.Toggle] = "<Esc>",
        [Roles.Info]   = "<F2>",
        [Roles.TUI]    = "<F3>",
        [Roles.Nav]    = "<F4>",
        [Roles.AI]     = "<F5>",
        [Roles.LSP]    = "<F12>",
        [Roles.Power]  = "\\",
        [Roles.Win]    = "<C-w>",
        [Roles.SCM]    = "<Leader>g",
        [Roles.Naked]  = "",
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
