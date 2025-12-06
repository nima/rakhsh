local t = require("core.types")
local cfg = require("core.config")

global vim: t.vim.Vim

local record ColorizerOpts
  RGB: boolean
  RRGGBB: boolean
  names: boolean
  rgb_fn: boolean
  hsl_fn: boolean
  css: boolean
  css_fn: boolean
  mode: string
end

local record Colorizer
  setup: function({string}, ColorizerOpts): nil
end

local ns = vim.api.nvim_create_namespace("RakhshCommentTagsNS")
local group = vim.api.nvim_create_augroup("RakhshCommentTags", { clear = true })
local tag_groups = {
  ["="] = "CommentTagTitle",        --= Reasoning / rationale
  ["-"] = "CommentTagNotice",       --- Notice/Warning or sub-heading
  ["?"] = "CommentTagProbing",      --? Question / explanatory note
  ["+"] = "CommentTagFYI",          --+ For Your Information
  ["&"] = "CommentTagStaged",       --& Staged/Example code and commands
  ["<"] = "CommentTagUpstream",     --< Input or Upstream
  [">"] = "CommentTagDownstream",   --> Output or Downstream
  ["!"] = "CommentTagAttention",    --! Attention / important
  ["@"] = "CommentTagReference",    --@ Reference / link
  ["$"] = "CommentTagCost",         --$ Cost / perf / memory
  ["O"] = "CommentTagONotation",    --O Big-O / complexity
  ["~"] = "CommentTagDeprecation",  --~ Deprecated / to be removed
}

local function hi(grp: string, opts: {string: any})
  vim.api.nvim_set_hl(0, grp, opts)
end

local function redefine_comment_tag_highlights(): nil
  hi("CommentTagTitle",        { fg = "#FFFFFF", bold = true })
  hi("CommentTagProbing",      { fg = "#FC59A3" })
  hi("CommentTagFYI",          { fg = "#3EA8FF" })
  hi("CommentTagUpstream",     { fg = "#FF7F50" })
  hi("CommentTagDownstream",   { fg = "#FF9F1C" })
  hi("CommentTagStaged",       { fg = "#87C830" })
  hi("CommentTagAttention",    { fg = "#FF3366" })
  hi("CommentTagNotice",       { fg = "#FFD23F" })
  hi("CommentTagReference",    { fg = "#00CEC9", italic = true })
  hi("CommentTagCost",         { fg = "#FFA600" })
  hi("CommentTagONotation",    { fg = "#FF6F61" })
  hi("CommentTagDeprecation",  { fg = "#FF3333", strikethrough = true })
end

local function ensure_comment_tag_highlights(): nil
  redefine_comment_tag_highlights()
end

local function apply_comment_tag_extmarks(bufnr: integer)

  local resolved = bufnr
  vim.api.nvim_buf_clear_namespace(resolved, ns, 0, -1)
  ensure_comment_tag_highlights()

  local cs = (vim.bo[resolved].commentstring or "") as string
  if cs == "" or not cs:find("%%s") then return end

  --+ Pluck out the comment leader
  local leader = cs:match("^%s*(.-)%s*%%s")
  if not leader or leader == "" then return end

  local esc_leader = vim.pesc(leader)

  --+ Scan all lines in the buffer once
  local lines = vim.api.nvim_buf_get_lines(resolved, 0, -1, false)

  for linenr, line in ipairs(lines) do
    --+ Try each tag mapping; stop at first match on the line.
    for ch, hl in pairs(tag_groups as {string:string}) do
      --+ Pattern: optional indent, then <leader><ch><space>, e.g. "  //+ Note" or "--= Title"
      local pat = esc_leader .. vim.pesc(ch) .. "%s*"

      local s, e = line:find(pat)
      if s then
        --+ Highlight from first content character up to (but not including)
        --+ any fold-marker tokens like "-={", "-=[" or "}=-".
        local content_start = e
        if content_start < #line then
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
              -- translate back into indices in the original line
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
          if content_end > content_start then
            vim.api.nvim_buf_set_extmark(resolved, ns, linenr - 1, content_start, {
              end_col  = content_end,
              hl_group = hl,
              priority = 500, -- stay above base comment/fold highlights
            })
          end
        end
        break --+ only one tag per line is expected
      end
    end
  end
end

local function read_splash_lines(): {string}
  local ok, datadir = pcall(vim.fn.stdpath, "data")
  if not ok then return {} end

  local path = datadir .. "/splash.txt"
  local fh = io.open(path, "r")
  if fh == nil then return {} end

  local lines = {} as {string}
  for line in fh:lines() do table.insert(lines, line) end
  fh:close()

  return lines
end

local function show_rakhsh_splash(): nil
  local buf = vim.api.nvim_get_current_buf()
  local _win = vim.api.nvim_get_current_win()

  local lines = read_splash_lines()
  if #lines == 0 then return end

  -- Center relative to the current window's text region.
  local width  = vim.api.nvim_win_get_width(0)
  local height = vim.api.nvim_win_get_height(0)

  local padded = {} as {string}

  -- vertical centering: prepend empty lines based on the full splash height.
  local top_pad = 0
  if height > #lines then
    top_pad = math.floor((height - #lines) / 2)
  end
  for _ = 1, top_pad do
    table.insert(padded, "")
  end

  -- horizontal centering for every splash line
  for _, l in ipairs(lines) do
    local pad = 0
    if #l < width then
      pad = math.floor((width - #l) / 2)
    end
    table.insert(padded, string.rep(" ", pad) .. l)
  end

  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].swapfile   = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype   = "rakhsh-splash"

  vim.wo.number         = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn     = "no"
  vim.wo.foldcolumn     = "0"
  vim.wo.list           = false
  vim.wo.cursorline     = false

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, padded)

  vim.bo[buf].modified = false

  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = buf,
    once = true,
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      -- turn this into a normal empty buffer and let the user start typing
      vim.bo[buf].buftype   = ""
      vim.bo[buf].bufhidden = ""
      vim.bo[buf].swapfile  = true
      vim.bo[buf].filetype  = ""
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.bo[buf].modified = false
    end,
  })

  vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = buf, nowait = true, silent = true })
end

local M: t.plugins.PluginModule = {}

function M.init(): nil
  vim.g.colorscheme = cfg.colorschema

  local argc = vim.fn.argc()
  local buf = vim.api.nvim_get_current_buf()
  local bt = vim.bo[buf].buftype
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Rakhsh startup splash (only when no files are passed and the
  -- initial buffer is still an empty, normal buffer). Some setups
  -- report 0 lines at this point, others report a single empty line,
  -- so we treat both as "empty". We schedule the actual splash render
  -- on VimEnter so the final window size is known for centering.
  local want_splash = false
  if argc == 0 and bt == "" then
    if line_count == 0 then
      want_splash = true
    elseif line_count == 1 then
      local first = (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
      if first == "" then
        want_splash = true
      end
    end
  end

  if want_splash then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        -- Draw the splash once Neovim has entered the UI; we use the current
        -- window size for centering and don't try to outsmart the launcher.
        vim.schedule(function()
          show_rakhsh_splash()
        end)
      end,
    })
  end

  vim.api.nvim_create_autocmd({"VimEnter", "BufWinEnter", "BufWritePost", "TextChanged", "TextChangedI"}, {
    group = group,
    callback = function(ev): nil
      local _ = ev -- ev is a generic autocmd event table; not required here
      apply_comment_tag_extmarks(vim.api.nvim_get_current_buf())
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function(ev): nil
      local _ = ev -- ignore; we only need to re-define our groups
      ensure_comment_tag_highlights()
    end,
  })

  vim.cmd("syntax on")

  redefine_comment_tag_highlights()
end

function M.lazy() : t.plugins.PluginSpec
  return {
    "tanvirtin/monokai.nvim",
    priority = 1000,
    lazy = false,
    keymaps = {},
    event = { "VimEnter" },
    config = function()
      local theme = cfg.colorschema
      local ok, _ = pcall(vim.cmd, "colorscheme " .. theme)
      if ok then return end
      vim.notify("colorscheme: '" .. theme .. "' not found (install theme plugin and restart)", vim.log.levels.ERROR, nil)
    end,
    dependencies = {
      "catppuccin/nvim",
      "folke/tokyonight.nvim",
      "EdenEast/nightfox.nvim",
      "rebelot/kanagawa.nvim",
      "rose-pine/neovim",
      {
        "norcalli/nvim-colorizer.lua",
        lazy = false,
        config = function()
          local _mod = "colorizer"
          local mod = (require(_mod) as Colorizer)
          mod.setup({ "*" }, {
            RGB    = true,
            RRGGBB = true,
            names  = false,
            rgb_fn = false,
            hsl_fn = false,
            css    = false,
            css_fn = false,
            mode   = "background",
          })
        end
      }
    },
  } as t.plugins.PluginSpec
end

return M
