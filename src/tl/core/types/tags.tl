local record Tag _tag: string end
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
    TargetFile        = { _tag = "t/file" },
    TargetBuffer      = { _tag = "t/buf" },
    --
    SeekSearch        = { _tag = "s" },
    SeekActive        = { _tag = "s/active" },
    --
    InputCursor: Tag  = { _tag = "i/cursor" },
    InputField: Tag   = { _tag = "i/field" },
    -- ...perform...
    ActionHelp        = { _tag = "a/help" },
    ActionInfo        = { _tag = "a/info" },
    ActionEdit        = { _tag = "a/ed" },
    ActionList        = { _tag = "a/ls" },
    ActionView        = { _tag = "a/v" },
    ActionLaunch      = { _tag = "a/run" },
    ActionInstall     = { _tag = "a/inst" },
    -- ...via..
    MethodFuzzy       = { _tag = "m/fz" },
    MethodRegex       = { _tag = "m/rx" },
    MethodSubstr      = { _tag = "m/ss" },
    -- ..by...
    BasisContent      = { _tag = "b/data" },
    BasisName         = { _tag = "b/name" },
    BasisSymbol       = { _tag = "b/symbol" },
    -- ..filtered by...
    FilterGit         = { _tag = "f/git" },
    FilterGitModified = { _tag = "f/git/stat" },
    -- ..prioritize by...
    PrioMRU           = { _tag = "p/mru" },
}
setmetatable(Tags, { __newindex = function() error("Cannot add new enum values to Tags") end })

local M = {
  Tag      = Tag,
  Tags     = Tags,
  TagTable = TagTable,
}

return M
