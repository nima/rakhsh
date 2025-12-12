local record Tag tid: string end
local record TagTable
    --+ Verbs / actions (what)
    ActionSearch: Tag
    ActionSelect: Tag
    ActionView: Tag
    ActionEdit: Tag
    ActionHelp: Tag
    ActionNavigate: Tag
    ActionList: Tag
    ActionToggle: Tag
    ActionLaunch: Tag

    --+ Nouns / targets (to what)
    TargetDoc: Tag
    TargetFile: Tag
    TargetBuffer: Tag
    TargetWindow: Tag
    TargetTab: Tag
    TargetProject: Tag
    TargetWorkspace: Tag
    TargetSymbol: Tag
    TargetLine: Tag
    TargetSelection: Tag
    TargetDiagnostic: Tag
    TargetBreakpoint: Tag
    TargetTerminal: Tag
    TargetTest: Tag
    TargetDialogue: Tag
    TargetCursor: Tag
    TargetField: Tag
    TargetGit: Tag
    TargetRepl: Tag
    TargetShell: Tag

    --+ How / method / filter / scope (how)
    ViaFuzzy: Tag
    ViaRegex: Tag
    ViaSubstr: Tag
    ViaContent: Tag
    ViaSymbol: Tag
    ViaName: Tag
    ViaPath: Tag
    ViaActive: Tag
    ViaGit: Tag
    ViaGitModified: Tag
    ViaMRU: Tag
    ViaDialogue: Tag
    ViaDebug: Tag

    --+ Other
    External: Tag
end

local Tags: TagTable = {
    --+ Verbs / actions (what)
    ActionSearch      = { tid = "a/search" },   -- generic search/find
    ActionSelect      = { tid = "a/select" },   -- generic select
    ActionView        = { tid = "a/view" },     -- view/read-only
    ActionEdit        = { tid = "a/ed" },       -- modify/mutate
    ActionHelp        = { tid = "a/help" },     -- help/cheatsheets/docs
    ActionNavigate    = { tid = "a/nav" },      -- jump/move/go
    ActionList        = { tid = "a/ls" },       -- list things
    ActionToggle      = { tid = "a/toggle" },   -- toggle state
    ActionLaunch      = { tid = "a/run" },      -- run/build/test/launch tools

    --+ Nouns / targets (to what); ultimate prize
    TargetDoc         = { tid = "t/doc" },      -- documentation/help
    TargetFile        = { tid = "t/file" },     -- files on disk
    TargetBuffer      = { tid = "t/buf" },      -- open buffers
    TargetWindow      = { tid = "t/win" },      -- editor windows/splits
    TargetTab         = { tid = "t/tab" },      -- tabpages
    TargetProject     = { tid = "t/proj" },     -- project/root dir
    TargetWorkspace   = { tid = "t/ws" },       -- multi-project workspace
    TargetSymbol      = { tid = "t/sym" },      -- LSP/TS symbol
    TargetLine        = { tid = "t/line" },     -- line-level operations
    TargetSelection   = { tid = "t/sel" },      -- visual selection range
    TargetDiagnostic  = { tid = "t/diag" },     -- diagnostics/problems
    TargetBreakpoint  = { tid = "t/bp" },       -- debugger breakpoints
    TargetTerminal    = { tid = "t/term" },     -- terminal buffers
    TargetTest        = { tid = "t/test" },     -- tests/specs
    TargetDialogue    = { tid = "t/dialog" },   -- popups/dialogue UIs
    TargetCursor      = { tid = "t/cursor" },   -- cursor position
    TargetField       = { tid = "t/field" },    -- input fields/prompts
    TargetGit         = { tid = "t/git" },      -- repo/branch/commit objects
    TargetRepl        = { tid = "t/repl" },     -- repl (ipython)
    TargetShell       = { tid = "t/shell" },    -- shell (bash, zsh)

    --+ How / method / filter / scope (how)
    ViaFuzzy          = { tid = "v/fz" },       -- fuzzy matching
    ViaRegex          = { tid = "v/rx" },       -- regex search
    ViaSubstr         = { tid = "v/ss" },       -- substring search
    ViaContent        = { tid = "v/data" },     -- search/match by content
    ViaSymbol         = { tid = "v/symbol" },   -- search/match by symbol
    ViaName           = { tid = "v/name" },     -- search/match by name
    ViaPath           = { tid = "v/path" },     -- restricted to current file
    ViaActive         = { tid = "v/active" },   -- current/active entity only
    ViaGit            = { tid = "v/git" },      -- git-filtered view
    ViaMRU            = { tid = "v/mru" },      -- prioritize MRU
    ViaDialogue       = { tid = "v/dialog" },   -- dialogue
    ViaDebug          = { tid = "v/dbg" },      -- in debugging context

    --+ Other
    External          = { tid = "extern" },     -- External keymaps that we merely document in registry
}
setmetatable(Tags, { __newindex = function() error("Cannot add new enum values to Tags") end })

local record TagsModule
  Tag: Tag
  Tags: TagTable
end

local M: TagsModule = {
  Tag      = Tag,
  Tags     = Tags,
}

return M
