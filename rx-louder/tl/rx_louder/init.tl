local NS_MARKERS = "louder.markers"
local NS_TAGS    = "louder.tags"

-- Force namespace registration at module-load time.
--
-- We still re-fetch IDs at use sites (and we do NOT rely on a cached ID), but
-- calling nvim_create_namespace here guarantees that:
--   1) `vim.api.nvim_get_namespaces()[name]` is non-nil immediately after `require()`
--   2) our debug probes can reliably observe the namespace
vim.api.nvim_create_namespace(NS_MARKERS)
vim.api.nvim_create_namespace(NS_TAGS)

-- NOTE: `nvim_create_namespace(name)` is idempotent; calling it again returns
-- the same id for the same name.
--
-- IMPORTANT: do not cache these IDs at module-load time. This plugin must be
-- robust against load-order/timing weirdness; we can always re-fetch the IDs
-- immediately before applying extmarks.
local function ns_markers_id(): integer
  return vim.api.nvim_create_namespace(NS_MARKERS)
end

local function ns_tags_id(): integer
  return vim.api.nvim_create_namespace(NS_TAGS)
end

local GROUP_NAME = "louder"
vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })

--------------------------------------------------------------------------------
--= Private Interface -=[

local tagdefs: { {string, string} } = {
  { "=", "CommentTagTitle" },       --= Reasoning / rationale
  { "-", "CommentTagNotice" },      --- Notice/Warning or sub-heading
  { "?", "CommentTagProbing" },     --? Question / explanatory note
  { "+", "CommentTagFYI" },         --+ For Your Information
  { "&", "CommentTagStaged" },      --& Staged/Example code and commands
  { "<", "CommentTagUpstream" },    --< Input or Upstream
  { ">", "CommentTagDownstream" },  --> Output or Downstream
  { "!", "CommentTagAttention" },   --! Attention / important
  { "@", "CommentTagReference" },   --@ Reference / link
  { "$", "CommentTagCost" },        --$ Cost / perf / memory
  { "O", "CommentTagONotation" },   --O Big-O / complexity
  { "~", "CommentTagDeprecation" }, --~ Deprecated / to be removed
  { "/", "CommentTagDoc" },         --/ Deprecated / to be removed
  { "|", "CommentTagRestriction" }, --| Restrictions, ranges, validations
}

local function redefine_comment_tag_highlights(): nil
  local defs: { {string, {string:any}} } = {
    { "CommentTagTitle",       { fg = "#FFFFFF", bold = true } },

    -- warn / hot
    { "CommentTagAttention",   { fg = "#FF3333", bold = true } },                 -- critical red
    { "CommentTagDeprecation", { fg = "#9CA3AF", strikethrough = true } },        -- deprecated greyed out
    { "CommentTagNotice",      { fg = "#FFD23F" } },                              -- warning yellow

    -- info / meta
    { "CommentTagFYI",         { fg = "#3EA8FF" } },                              -- info blue
    { "CommentTagReference",   { fg = "#00CEC9", italic = true } },               -- link/refs teal
    { "CommentTagDoc",         { fg = "#7C4DFF" } },                              -- documentation purple

    -- flow / direction
    { "CommentTagUpstream",    { fg = "#FF7F50" } },                              -- coral
    { "CommentTagDownstream",  { fg = "#FF9F1C" } },                              -- orange
    { "CommentTagStaged",      { fg = "#87C830" } },                              -- green (good/ready)

    -- intent / constraints / misc
    { "CommentTagCost",        { fg = "#FFA600" } },                              -- money/gold
    { "CommentTagRestriction", { fg = "#FF3366" } },                              -- “no/blocked” magenta
    { "CommentTagProbing",     { fg = "#FC59A3" } },                              -- probing pink
    { "CommentTagONotation",   { fg = "#FF6F61" } },                              -- salmon
  }

  for _, d in ipairs(defs) do
    vim.api.nvim_set_hl(0, d[1], d[2])
  end
end

local function get_comment_leader(buf: integer): (string | nil)
  local cs = (vim.api.nvim_get_option_value("commentstring", { buf = buf }) or "") as string
  if cs == "" or not cs:find("%%s") then return nil end

  local leader = cs:match("^%s*(.-)%s*%%s")
  if leader == nil or leader == "" then return nil end
  return leader
end

local function apply_comment_tag_extmarks(bufnr: integer): nil
  local ns_tags = ns_tags_id()

  --+ Highlights are (re)defined in setup() and on ColorScheme; avoid doing it
  --+ on every redraw.
  local leader0 = get_comment_leader(bufnr)
  if leader0 == nil then return end
  local leader = (leader0 as string)

  --+ Only clear when we can also repopulate (e.g. after FileType sets commentstring).
  vim.api.nvim_buf_clear_namespace(bufnr, ns_tags, 0, -1)

  local leader_idx = leader
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for linenr, line in ipairs(lines) do
    -- Only consider the *first* comment leader on the line.
    local c0 = line:find(leader_idx, 1, true)
    if c0 == nil then goto continue end

    local s0 = c0 + #leader
    if s0 > #line then goto continue end

    -- If this is a doc-comment continuation leader (e.g. `///` in C++ or `---` in Lua), skip it
    -- only when the extra leader character is NOT one of our tag characters.
    if #leader >= 2 then
      local last_leader_ch = leader:sub(#leader, #leader)
      local next_ch = line:sub(s0, s0)

      if next_ch == last_leader_ch then
        local is_tag = false
        for _, d in ipairs(tagdefs) do
          if d[1] == next_ch then
            is_tag = true
            break
          end
        end
        if not is_tag then goto continue end
      end
    end

    -- Find the first tag that matches immediately after the comment leader, and
    -- apply exactly one highlight per line.
    for _, d in ipairs(tagdefs) do
      local ch, hl = d[1], d[2]
      if line:sub(s0, s0) == ch then
        -- Require whitespace (or EOL) after the tag marker so we don't match cases like `---+`.
        local after = line:sub(s0 + 1, s0 + 1)
        if after ~= "" and not after:match("%s") then goto continue_tag end

        -- Highlight everything after the tag marker (skipping whitespace).
        local content_start = s0
        while content_start < #line and line:sub(content_start + 1, content_start + 1):match("%s") do
          content_start = content_start + 1
        end

        if content_start < #line then
          vim.api.nvim_buf_set_extmark(bufnr, ns_tags, linenr - 1, content_start, {
            end_col  = #line,
            hl_group = hl,
            hl_mode  = "combine",
            priority = 200,
          })
        end

        break --+ Only one tag highlight per line.
      end

      ::continue_tag::
    end

    ::continue::
  end
end

local function define_fold_marker_highlights(): nil
  vim.api.nvim_set_hl(0, "FoldMarkerRed",    { fg = "#ff5555", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerOrange", { fg = "#ffb86c", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerBlue",   { fg = "#8be9fd", bold = true })
  vim.api.nvim_set_hl(0, "FoldMarkerPurple", { fg = "#bd93f9", bold = true })
end

local function apply_markers(buf: integer): nil
  local ns_markers = ns_markers_id()

  if not vim.api.nvim_buf_is_valid(buf) then return end
  if (vim.api.nvim_get_option_value("buftype", { buf = buf }) as string) ~= "" then return end

  local leader = get_comment_leader(buf)
  if leader == nil then return end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_clear_namespace(buf, ns_markers, 0, -1)

  local markers = {
    { pat = "%-=%{",  hl = "FoldMarkerRed"    }, -- -={
    { pat = "%}%=%-", hl = "FoldMarkerRed"    }, -- }=-
    { pat = "%-=%[",  hl = "FoldMarkerOrange" }, -- -=[
    { pat = "%]%=%-", hl = "FoldMarkerOrange" }, -- ]=-
    { pat = "%-=%(",  hl = "FoldMarkerBlue"   }, -- -=(
    { pat = "%)%=%-", hl = "FoldMarkerBlue"   }, -- )=-
    { pat = "%-=%<",  hl = "FoldMarkerPurple" }, -- -=<
    { pat = ">%=%-",  hl = "FoldMarkerPurple" }, -- >=-
  }

  for i = 1, #lines do
    local line = lines[i]

    local c0 = line:find(leader, 1, true)
    if c0 == nil then goto continue_line end
    local s0 = c0 + #leader

    for _, m in ipairs(markers) do
      local s = s0
      while true do
        local a, b = line:find(m.pat, s)
        if not a then break end
        vim.api.nvim_buf_set_extmark(buf, ns_markers, i - 1, a - 1, {
          end_col  = b,
          hl_group = m.hl,
          hl_mode  = "combine",
          priority = 700,
        })
        s = b + 1
      end
    end

    ::continue_line::
  end
end

-- ]=-
--------------------------------------------------------------------------------
--= Public Interface -={

local M = {
  _ns_markers = nil as (integer | nil),
  _ns_tags = nil as (integer | nil),
}

function M.setup(): nil
  -- Capture for debugging/visibility only; the extmark code always re-fetches ids.
  M._ns_markers = ns_markers_id()
  M._ns_tags = ns_tags_id()

  vim.api.nvim_create_autocmd({ "ColorScheme" }, {
    group = GROUP_NAME,
    pattern = "*",
    callback = function(): nil
      --+ ColorScheme resets highlight groups. Re-define them once...
      define_fold_marker_highlights()
      redefine_comment_tag_highlights()

      --+ Next, refresh extmarks for all loaded normal buffers...
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if not vim.api.nvim_buf_is_valid(buf) then goto continue end
        if not vim.api.nvim_buf_is_loaded(buf) then goto continue end
        if (vim.api.nvim_get_option_value("buftype", { buf = buf }) as string) ~= "" then goto continue end

        apply_markers(buf)
        apply_comment_tag_extmarks(buf)

        ::continue::
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "TextChanged", "TextChangedI" }, {
    group = GROUP_NAME,
    pattern = "*",
    callback = function(ev: vim.AutocmdCallbackData): any
      apply_markers(ev.buf)
      apply_comment_tag_extmarks(ev.buf)
    end,
  })

  define_fold_marker_highlights()
  redefine_comment_tag_highlights()

  local buf = vim.api.nvim_get_current_buf()
  apply_markers(buf)
  apply_comment_tag_extmarks(buf)
end

-- }=-

return M
