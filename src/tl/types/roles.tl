local _tags = require("types.tags")
local T = _tags.Tag
local Ts = _tags.Tags

--- Keyboard atlas
---
--- A KbRegion is a *curated* set of well-known Vim key neighborhoods (HomeRow, WASD, etc.).
--- We intentionally do NOT support arbitrary / user-defined regions.
---
--- IMPORTANT INVARIANT:
---   - `KbAtlas.All` is a sentinel meaning "no filtering".
---   - i.e. an empty region means "accept any suffix key".
---
--- Non-empty regions are used when a role leader contains a wildcard (e.g. `<C-*>`) and we want
--- to restrict expansion to a familiar neighborhood.
local type KbKeys = {string}
local record KbRegion
  Alpha:       KbKeys
  HomeRow:     KbKeys
  HomeBlob:    KbKeys
  CommaDot:    KbKeys
  Numeric:     KbKeys
  Arrows:      KbKeys
  WASD:        KbKeys
  Function:    KbKeys
  Punctuation: KbKeys
  Brackets:    KbKeys
  Symbols:     KbKeys
  Functional:  KbKeys
  All:         KbKeys
end

local KbAtlas<total>: KbRegion = {
  Alpha       = { "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" },
  HomeRow     = { "h", "j", "k", "l" },
  HomeBlob    = { "h", "j", "k", "l", "y", "u", "i", "o", "p", "n", "m" },
  CommaDot    = { ",", "." },
  Numeric     = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
  Arrows      = { "<Up>", "<Down>", "<Left>", "<Right>" },
  WASD        = { "w", "a", "s", "d" },
  Function    = { "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12" },
  Punctuation = { ";", ".", "/", ",", "[", "]", "\\", "'", "-", "=" },
  Brackets    = { "[", "]" },
  Symbols     = { "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+" },
  Functional  = { "<Tab>", "<CR>", "<Esc>", "<BS>", "<Space>" },
  All         = {} --- Sentinel for ALL keys, not a bug
}
--+ <Tab> == <C-i>
--+ <Esc> == <C-[>

local function leader(key: string): string
  --+ Shift: F12 →  F24
  --+ Ctrl:  F12 →  F36
  --+ Alt:   F12 →  F60

  local mod, num = key:match("^<([CSA])%-F(%d+)>$")
  if not mod then return key end

  local n: integer = math.floor(tonumber(num))
  if not n then return key end

  local offset: integer = 0
  if     mod == "S" then offset = 12
  elseif mod == "C" then offset = 24
  elseif mod == "A" then offset = 48
  else return key end

  return string.format("<F%d>", n + offset)
end

local enum Mode
   "n" -- Normal
   "i" -- Insert
   "v" -- Visual (inclusive)
   "x" -- Visual (strict)
   "s" -- Select (substitute)
end

--= superset(regions)
--
--+ This merges multiple key-neighborhoods into a deduped list.
--+ This is useful when you want one role to expand across several *specific* regions.
--
--- NOTE: This must NOT be used to build `KbAtlas.All` because `All` is a sentinel meaning
--- "no filtering" (empty list).
local function superset(regions: {KbKeys}): KbKeys
  local seen: {string:boolean} = {}
  local out: KbKeys = {}

  local function add(keys: KbKeys)
    for i = 1, #keys do
      local k = keys[i]
      if not seen[k] then
        seen[k] = true
        out[#out + 1] = k
      end
    end
  end

  for i = 1, #regions do
    add(regions[i])
  end

  return out
end
-- ]=-

--= RoleDatum
--
--+ `leader` may be a literal key sequence (e.g. "g", "<F12>") or may include a wildcard
--+ expansion marker like `<C-*>` / `<A-*>` / `<S-*>`.
--
--- NOTE: When `leader` includes `*`, callers are expected to expand `*` over `region`.
--- If `region` is empty (KbAtlas.All sentinel), expansion should NOT filter at all.
local record RoleDatum
  name:    string
  tag:     string
  desc:    string
  leader:  string
  region:  KbKeys
end

local record RoleData
  Naked:     RoleDatum
  Tradition: RoleDatum
  Power:     RoleDatum
  TUI:       RoleDatum
  Go:        RoleDatum
  GoVia:     RoleDatum
  Window:    RoleDatum
  Toggle:    RoleDatum
  Info:      RoleDatum
  Select:    RoleDatum
  View:      RoleDatum
  Edit:      RoleDatum
  System:    RoleDatum
  Layout:    RoleDatum
  ForRent:   RoleDatum
  Rakhsh:    RoleDatum
  AI:        RoleDatum
  SCM:       RoleDatum
  LSPInfo:   RoleDatum
  LSPEdit:   RoleDatum
  LSPDiag:   RoleDatum
  LSPGoto:   RoleDatum
end

local Roles<total>: RoleData = {
  Naked     = { leader=leader(""),          region=KbAtlas.All, name="Naked", tag="r/naked", desc="These are not protected by any preceding keystrokes" },
  Tradition = { leader=leader(""),          region=KbAtlas.All, name="Tradition", tag="r/trad", desc="Traditional muscle-memory vim keymaps" },
  Power     = { leader=leader("\\"),        region=KbAtlas.All, name="PowerTool", tag="r/power", desc="Power moves to charm" },
  TUI       = { leader=leader("<Tab>"),     region=KbAtlas.All, name="TextualUserInterface", tag="r/tui", desc="The Rakhsh IDE" },
  Go        = { leader=leader("g"),         region=KbAtlas.All, name="NavigationGo", tag="r/go", desc="Immediate navigation: single-step jumps with no UI" },
  GoVia     = { leader=leader("<C-g>"),     region=KbAtlas.All, name="NavigationVia", tag="r/go", desc="Navigation via an intermediate UI (pickers, lists, dialogs)" },
  Window    = { leader=leader("<C-w>"),     region=KbAtlas.All, name="WindowManagement", tag="r/native/w", desc="TUI Window management" },
  Toggle    = { leader=leader("<Esc>"),     region=KbAtlas.All, name="Toggle", tag="r/toggle", desc="It goes on... it goes off" },
  Info      = { leader=leader("<F2>"),      region=KbAtlas.All, name="Information", tag="r/info", desc="" },
  Select    = { leader=leader("<A-*>"),     region=KbAtlas.HomeRow, name="Select", tag="r/info", desc="TUI pane selection" },
  View      = { leader=leader("<S-*>"),     region=KbAtlas.Function, name="View", tag="r/info", desc="View related" },
  Edit      = { leader=leader("<C-*>"),     region=KbAtlas.All, name="Editor", tag="r/edit", desc="Editor commands" },
  System    = { leader=leader("<C-S-*>"),   region=KbAtlas.All, name="System", tag="r/edit", desc="System related" },
  Layout    = { leader=leader("<A-S-*>"),   region=KbAtlas.All, name="Layout", tag="r/edit", desc="Layout related" },
  ForRent   = { leader=leader("<C-A-*>"),   region=KbAtlas.All, name="ThisSpaceForRent", tag="r/edit", desc="This space for rent" },
  Rakhsh    = { leader=leader("<C-A-S-*>"), region=KbAtlas.All, name="RakhshIDE", tag="r/ide", desc="The Rakhsh IDE" },
  AI        = { leader=leader("<F5>"),      region=KbAtlas.All, name="ArtificialIntelligence", tag="r/ai", desc="Anything involving AI or LLM API calls" },
  SCM       = { leader=leader("<F10>"),     region=KbAtlas.All, name="SourceControlManagement", tag="r/git", desc="Anything related to Git" },
  LSPGoto   = { leader=leader("<F12>"),     region=KbAtlas.All, name="LSPGoto", tag="r/lsp", desc="LSP goto" },
  LSPInfo   = { leader=leader("<S-F12>"),   region=KbAtlas.All, name="LSPInfo", tag="r/lsp", desc="LSP inspection / info" },
  LSPEdit   = { leader=leader("<C-F12>"),   region=KbAtlas.All, name="LSPEdit", tag="r/lsp", desc="LSP edits / refactors" },
  LSPDiag   = { leader=leader("<A-F12>"),   region=KbAtlas.All, name="LSPDiagnostics", tag="r/lsp", desc="LSP diagnostics" },
}

setmetatable(Roles, { 
  __newindex = function(_: RoleData, k: any, _: any) 
    error("Cannot add new value '" .. (k as string) .. "' to Roles") 
  end 
})

local function complete(role: RoleDatum, tags: {T}, external: boolean): {T}
  local out: {T} = {}
  table.move(tags, 1, #tags, 1, out)
  out[#out + 1] = { tid = role.tag } as T
  if external then out[#out + 1] = Ts.External end
  return out
end

local M = {
  complete  = complete,
  superset  = superset,
  Mode      = Mode,
  Role      = RoleDatum,
  Roles     = Roles,
}

return M
