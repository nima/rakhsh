local t = require("core.types")

global vim: t.vim.Vim

--[[
local function get_win_size(win: integer): (integer, integer)
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  return width, height
end
]]

local function get_ui_size(): (integer, integer)
  --+ In remote-ui flows, window sizing can be wrong until a UI attaches.
  --+ vim.o.columns/lines reflect the attached UI grid size.
  local width = vim.o.columns
  local height = vim.o.lines
  return width, height
end

local function center_lines(lines: {string}, width: integer, height: integer): {string}
  if #lines == 0 then return {} end

  local padded = {} as {string}

  -- vertical centering
  local top_pad = 0
  if height > #lines then
    top_pad = math.floor((height - #lines) / 2)
  end
  for _ = 1, top_pad do
    table.insert(padded, "")
  end

  -- horizontal centering (use display width, not byte length)
  for _, l in ipairs(lines) do
    local lw = vim.fn.strdisplaywidth(l)
    local pad = 0
    if lw < width then
      pad = math.floor((width - lw) / 2)
    end
    table.insert(padded, string.rep(" ", pad) .. l)
  end

  return padded
end

local function setup_splash_buffer(buf: integer): nil
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].swapfile   = false
  vim.bo[buf].modifiable = true
  vim.bo[buf].filetype   = "rakhsh-splash"
end

local function setup_splash_window(win: integer): nil
  vim.wo[win].number         = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn     = "no"
  vim.wo[win].foldcolumn     = "0"
  vim.wo[win].list           = false
  vim.wo[win].cursorline     = false
  vim.wo[win].fillchars      = "eob: "
end

local function setup_splash_exit_on_insert(buf: integer): nil
  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = buf,
    once = true,
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then return end

      -- turn this into a normal empty buffer and let the user start typing
      vim.bo[buf].buftype   = ""
      vim.bo[buf].bufhidden = ""
      vim.bo[buf].swapfile  = true
      vim.bo[buf].filetype  = ""
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      vim.bo[buf].modified = false
    end,
  })
end

local function setup_splash_keymaps(buf: integer): nil
  --+ Quit the splash buffer with 'q'; no need for safemap here.
  vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = buf, nowait = true, silent = true })
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

local function should_show_splash_now(buf: integer): boolean
  --+ Guard at time-of-use: startup state can change between M.setup() and UIEnter.
  if vim.fn.argc() > 0 then return false end

  -- If already visiting a named file, never show the splash.
  local name = vim.api.nvim_buf_get_name(buf)
  if name ~= "" then return false end

  if vim.bo[buf].buftype ~= "" then return false end

  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count == 0 then return true end

  if line_count ~= 1 then return false end

  local first = (vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "")
  return first == ""
end

local function show_rakhsh_splash(): nil
  local buf = vim.api.nvim_get_current_buf()
  if not should_show_splash_now(buf) then return end

  local lines = read_splash_lines()
  if #lines == 0 then return end

  setup_splash_buffer(buf)

  local win = vim.api.nvim_get_current_win()
  setup_splash_window(win)

  local width, height = get_ui_size()
  local padded = center_lines(lines, width, height)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, padded)
  vim.bo[buf].modified = false

  setup_splash_exit_on_insert(buf)
  setup_splash_keymaps(buf)
end

local M = {}

function M.setup(): nil
  local argc = vim.fn.argc()
  local buf = vim.api.nvim_get_current_buf()
  local bt = vim.bo[buf].buftype
  local line_count = vim.api.nvim_buf_line_count(buf)

  -- Rakhsh startup splash (only when no files are passed and the
  -- initial buffer is still an empty, normal buffer). Some setups
  -- report 0 lines at this point, others report a single empty line,
  -- so we treat both as "empty". We schedule the actual splash render
  -- on UIEnter so the final UI grid size is known for centering.
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
    vim.api.nvim_create_autocmd("UIEnter", {
      once = true,
      callback = function()
        vim.schedule(function()
          show_rakhsh_splash()
        end)
      end,
    })
  end
end

return M
