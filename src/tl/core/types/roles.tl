local record Role _tag: string end
local record RoleSet
    Toggle: Role
    LSP:    Role
    Nav:    Role
    Power:  Role
    Win:    Role
    AI:     Role
    SCM:    Role
    Meta:   Role
    Info:   Role
    Rename: Role
    Code:   Role
end
setmetatable(RoleSet, { __newindex = function() error("Cannot add new enum values to RoleSet") end })

local Roles: RoleSet = {
    Toggle  = { _tag = "Toggle" },
    LSP     = { _tag = "LanguageServerProtocol" },
    Nav     = { _tag = "Navigation" },
    Power   = { _tag = "PowerTool" },
    Win     = { _tag = "Window" },
    AI      = { _tag = "ArtificialIntelligence" },
    SCM     = { _tag = "SourceControlManagement" },
    Meta    = { _tag = "Metadata" },
    Info    = { _tag = "Information" },
    Rename  = { _tag = "RenameSymbol" },
    Code    = { _tag = "CodeAction" },
}
setmetatable(Roles, { __newindex = function() error("Cannot add new enum values to Roles") end })

local ActivationPrefix: {string: {Role: string}} = {
    n = {
        [Roles.Win]    = "<C-w>",
        [Roles.LSP]    = "g",
        [Roles.Power]  = "\\",
        [Roles.Toggle] = "<Esc>",
        [Roles.Nav]    = "<Leader>",
        [Roles.Meta]   = "<Leader>s",
        [Roles.AI]     = "<Leader>a",
        [Roles.SCM]    = "<Leader>g",
        [Roles.Rename] = "<Leader>",
        [Roles.Code]   = "<Leader>",
        [Roles.Info]   = "",
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
