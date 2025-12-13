local t = require("types")

global vim: t.vim.Vim

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

local group = vim.api.nvim_create_augroup("louder", { clear = true })

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
}

local function redefine_comment_tag_highlights(): nil
  local defs: { {string, {string:any}} } = {
    { "CommentTagTitle",       { fg = "#FFFFFF", bold = true } },
    { "CommentTagNotice",      { fg = "#FFD23F" } },
    { "CommentTagProbing",     { fg = "#FC59A3" } },
    { "CommentTagFYI",         { fg = "#3EA8FF" } },
    { "CommentTagStaged",      { fg = "#87C830" } },
    { "CommentTagUpstream",    { fg = "#FF7F50" } },
    { "CommentTagDownstream",  { fg = "#FF9F1C" } },
    { "CommentTagAttention",   { fg = "#FF3366" } },
    { "CommentTagReference",   { fg = "#00CEC9", italic = true } },
    { "CommentTagCost",        { fg = "#FFA600" } },
    { "CommentTagONotation",   { fg = "#FF6F61" } },
    { "CommentTagDeprecation", { fg = "#FF3333", strikethrough = true } },
  }
  for _, d in ipairs(defs) do
    vim.api.nvim_set_hl(0, d[1], d[2])
  end
end

local function get_comment_leader(buf: integer): (string | nil)
  local cs = (vim.bo[buf].commentstring or "") as string
  if cs == "" or not cs:find("%%s") then return nil end

  local leader = cs:match("^%s*(.-)%s*%%s")
  if leader == nil or leader == "" then return nil end
  return leader
end

local function apply_comment_tag_extmarks(bufnr: integer): nil
  local ns_tags = ns_tags_id()

  --+ Highlights are (re)defined in setup() and on ColorScheme; avoid doing it
  --+ on every redraw.
  local leader = get_comment_leader(bufnr)
  if leader == nil then return end

  --+ Only clear when we can also repopulate (e.g. after FileType sets commentstring).
  vim.api.nvim_buf_clear_namespace(bufnr, ns_tags, 0, -1)

  local esc_leader = vim.pesc(leader)
  local leader_idx = leader
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for linenr, line in ipairs(lines) do
    if not line:find(leader_idx, 1, true) then goto continue end

    -- Find the first tag that matches at the start of the comment leader, and
    -- apply exactly one highlight per line.
    for _, d in ipairs(tagdefs) do
      local ch, hl = d[1], d[2]
      local pat = esc_leader .. vim.pesc(ch) .. "%s*"

      local s, e = line:find(pat)
      if s then
        local content_start = e
        if content_start < #line then
          local content_end = #line
          if content_end > content_start then
            vim.api.nvim_buf_set_extmark(bufnr, ns_tags, linenr - 1, content_start, {
              end_col  = content_end,
              hl_group = hl,
              hl_mode  = "combine",
              priority = 200,
            })
          end
        end

        break --+ Only one tag highlight per line.
      end
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
  if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then return end

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
    group = group,
    pattern = "*",
    callback = function(): nil
      --+ ColorScheme resets highlight groups. Re-define them once...
      define_fold_marker_highlights()
      redefine_comment_tag_highlights()

      --+ Next, refresh extmarks for all loaded normal buffers...
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if not vim.api.nvim_buf_is_valid(buf) then goto continue end
        if not vim.api.nvim_buf_is_loaded(buf) then goto continue end
        if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then goto continue end

        apply_markers(buf)
        apply_comment_tag_extmarks(buf)

        ::continue::
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = "*",
    callback = function(ev: t.vim.VimAutocmdEvent)
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
