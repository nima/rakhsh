local record Tag tid: string end
local record TagTable
    TargetFile: Tag
    TargetBuffer: Tag
    TargetDialogue: Tag
    --
    SeekSearch: Tag
    SeekActive: Tag
    --
    InputCursor: Tag
    InputField: Tag
    --
    ActionHelp: Tag
    ActionInfo: Tag
    ActionEdit: Tag
    ActionList: Tag
    ActionView: Tag
    ActionLaunch: Tag
    ActionInstall: Tag
    ActionToggle: Tag
    --
    MethodFuzzy: Tag
    MethodRegex: Tag
    MethodSubstr: Tag
    --
    BasisContent: Tag
    BasisName: Tag
    BasisSymbol: Tag
    --
    FilterGit: Tag
    FilterGitModified: Tag
    --
    PrioMRU: Tag
end

local Tags: TagTable = {
    -- I want to search for a
    TargetFile        = { tid = "t/file" },
    TargetBuffer      = { tid = "t/buf" },
    --
    SeekSearch        = { tid = "s" },
    SeekActive        = { tid = "s/active" },
    --
    InputCursor: Tag  = { tid = "i/cursor" },
    InputField: Tag   = { tid = "i/field" },
    -- ...perform...
    ActionHelp        = { tid = "a/help" },
    ActionInfo        = { tid = "a/info" },
    ActionEdit        = { tid = "a/ed" },
    ActionList        = { tid = "a/ls" },
    ActionView        = { tid = "a/v" },
    ActionLaunch      = { tid = "a/run" },
    ActionInstall     = { tid = "a/inst" },
    ActionToggle      = { tid = "a/toggle" },
    -- ...via..
    MethodFuzzy       = { tid = "m/fz" },
    MethodRegex       = { tid = "m/rx" },
    MethodSubstr      = { tid = "m/ss" },
    -- ..by...
    BasisContent      = { tid = "b/data" },
    BasisName         = { tid = "b/name" },
    BasisSymbol       = { tid = "b/symbol" },
    -- ..filtered by...
    FilterGit         = { tid = "f/git" },
    FilterGitModified = { tid = "f/git/stat" },
    -- ..prioritize by...
    PrioMRU           = { tid = "p/mru" },
}
setmetatable(Tags, { __newindex = function() error("Cannot add new enum values to Tags") end })

local M = {
  Tag      = Tag,
  Tags     = Tags,
  TagTable = TagTable,
}

return M
