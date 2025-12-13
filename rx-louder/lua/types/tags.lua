local Tag = {}





















































local Tags = {

   ActionSearch = { tid = "a/search" },
   ActionSelect = { tid = "a/select" },
   ActionView = { tid = "a/view" },
   ActionEdit = { tid = "a/ed" },
   ActionHelp = { tid = "a/help" },
   ActionNavigate = { tid = "a/nav" },
   ActionList = { tid = "a/ls" },
   ActionToggle = { tid = "a/toggle" },
   ActionLaunch = { tid = "a/run" },


   TargetDoc = { tid = "t/doc" },
   TargetFile = { tid = "t/file" },
   TargetBuffer = { tid = "t/buf" },
   TargetWindow = { tid = "t/win" },
   TargetTab = { tid = "t/tab" },
   TargetProject = { tid = "t/proj" },
   TargetWorkspace = { tid = "t/ws" },
   TargetSymbol = { tid = "t/sym" },
   TargetLine = { tid = "t/line" },
   TargetSelection = { tid = "t/sel" },
   TargetDiagnostic = { tid = "t/diag" },
   TargetBreakpoint = { tid = "t/bp" },
   TargetTerminal = { tid = "t/term" },
   TargetTest = { tid = "t/test" },
   TargetDialogue = { tid = "t/dialog" },
   TargetCursor = { tid = "t/cursor" },
   TargetField = { tid = "t/field" },
   TargetGit = { tid = "t/git" },
   TargetRepl = { tid = "t/repl" },
   TargetShell = { tid = "t/shell" },


   ViaFuzzy = { tid = "v/fz" },
   ViaRegex = { tid = "v/rx" },
   ViaSubstr = { tid = "v/ss" },
   ViaContent = { tid = "v/data" },
   ViaSymbol = { tid = "v/symbol" },
   ViaName = { tid = "v/name" },
   ViaPath = { tid = "v/path" },
   ViaActive = { tid = "v/active" },
   ViaGit = { tid = "v/git" },
   ViaMRU = { tid = "v/mru" },
   ViaDialogue = { tid = "v/dialog" },
   ViaDebug = { tid = "v/dbg" },


   External = { tid = "extern" },
}
setmetatable(Tags, { __newindex = function() error("Cannot add new enum values to Tags") end })






local M = {
   Tag = Tag,
   Tags = Tags,
}

return M
