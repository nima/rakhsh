local t = require("core.types")

global vim: t.vim.Vim

local ns = vim.api.nvim_create_namespace("RakhshCommentTagsNS")
local group = vim.api.nvim_create_augroup("RakhshCommentTags", { clear = true })
local tag_defs: { {string, string} } = {
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

local function get_comment_leader(buf: integer): (string | nil)
  local cs = (vim.bo[buf].commentstring or "") as string
  if cs == "" or not cs:find("%%s") then return nil end

  local leader = cs:match("^%s*(.-)%s*%%s")
  if leader == nil or leader == "" then return nil end
  return leader
end

local function content_end_before_fold_tokens(line: string, content_start: integer): integer
  local cut: integer | nil = nil

  local function consider(idx: integer | nil)
    if idx ~= nil and idx > content_start then
      if cut == nil or idx < cut then
        cut = idx
      end
    end
  end

  local function consider_token(token: string)
    local tail = line:sub(content_start + 1)
    local rel = tail:find(vim.pesc(token))
    if rel ~= nil then
      consider(content_start + rel)
    end
  end

  consider_token("-={")
  consider_token("-=[")
  consider_token("]=-")
  consider_token("}=-")

  local content_end = #line
  if cut ~= nil and cut > content_start then
    content_end = cut - 1
  end
  return content_end
end

local function hi(grp: string, opts: {string: any})
  vim.api.nvim_set_hl(0, grp, opts)
end

local function redefine_comment_tag_highlights(): nil
  local defs: { {string, {string:any}} } = {
    { "CommentTagTitle",       { fg = "#FFFFFF", bold = true } },
    { "CommentTagProbing",     { fg = "#FC59A3" } },
    { "CommentTagFYI",         { fg = "#3EA8FF" } },
    { "CommentTagUpstream",    { fg = "#FF7F50" } },
    { "CommentTagDownstream",  { fg = "#FF9F1C" } },
    { "CommentTagStaged",      { fg = "#87C830" } },
    { "CommentTagAttention",   { fg = "#FF3366" } },
    { "CommentTagNotice",      { fg = "#FFD23F" } },
    { "CommentTagReference",   { fg = "#00CEC9", italic = true } },
    { "CommentTagCost",        { fg = "#FFA600" } },
    { "CommentTagONotation",   { fg = "#FF6F61" } },
    { "CommentTagDeprecation", { fg = "#FF3333", strikethrough = true } },
  }
  for _, d in ipairs(defs) do
    hi(d[1], d[2])
  end
end

local function apply_comment_tag_extmarks(bufnr: integer): nil
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  redefine_comment_tag_highlights()

  local leader = get_comment_leader(bufnr)
  if leader == nil then return end

  local esc_leader = vim.pesc(leader)
  local leader_idx = leader
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for linenr, line in ipairs(lines) do
    if not line:find(leader_idx, 1, true) then goto continue end
    for _, d in ipairs(tag_defs) do
      local ch, hl = d[1], d[2]
      local pat = esc_leader .. vim.pesc(ch) .. "%s*"
      local s, e = line:find(pat)
      if s then
        local content_start = e
        if content_start < #line then
          local content_end = content_end_before_fold_tokens(line, content_start)
          if content_end > content_start then
            vim.api.nvim_buf_set_extmark(bufnr, ns, linenr - 1, content_start, {
              end_col  = content_end,
              hl_group = hl,
              priority = 500,
            })
          end
        end
        break
      end
    end
    ::continue::
  end
end

local M = {}

function M.setup(): nil
  vim.api.nvim_create_autocmd({"VimEnter", "BufWinEnter", "BufWritePost", "TextChanged", "TextChangedI"}, {
    group = group,
    callback = function(_): nil
      apply_comment_tag_extmarks(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function(_): nil
      redefine_comment_tag_highlights()
    end,
  })

  vim.cmd("syntax on")

  redefine_comment_tag_highlights()
end

return M