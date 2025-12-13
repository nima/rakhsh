local t = require("types")

global vim: t.vim.Vim

--------------------------------------------------------------------------------
--= Private Interface -={
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

  --+ vertical centering
  local top_pad = 0
  if height > #lines then
    top_pad = math.floor((height - #lines) / 2)
  end
  for _ = 1, top_pad do
    table.insert(padded, "")
  end

  --+ horizontal centering (use display width, not byte length)
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
  vim.bo[buf].readonly   = false
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
  vim.b[buf].rakhsh_splash_armed = false
  vim.api.nvim_create_autocmd("InsertEnter", {
    buffer = buf,
    once = true,
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then return end

      -- turn this into a normal empty buffer and let the user start typing
            -- Disarm ASAP so CursorMoved handler stops fighting.
      vim.b[buf].rakhsh_splash_armed = false

      -- Make sure we're operating in the window that actually shows the splash.
      local winid = vim.fn.bufwinid(buf)
      if winid ~= -1 then
        vim.api.nvim_set_current_win(winid)
      end

      -- Replace splash with a fresh empty buffer, then wipe the splash buffer.
      vim.cmd("enew")
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end,
  })
  -- Keep the splash "static": allow user to press `q` or `i`, but don't let cursor roam.
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    callback = function(): nil
      if not vim.api.nvim_buf_is_valid(buf) then return end
      if vim.b[buf].rakhsh_splash_armed ~= true then return end

      -- If this buffer is no longer in the current window, don't fight other windows.
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_buf(win) ~= buf then return end

      -- Pin cursor to the first line/col.
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
    end,
  })
end

local function setup_splash_keymaps(buf: integer): nil
  --+ Quit the splash buffer with 'q'; no need for safemap here.
  vim.keymap.set("n", "q", "<cmd>bd!<CR>", { buffer = buf, nowait = true, silent = true })
end

local function read_splash_lines(): {string}
  local candidates = {
    vim.fn.stdpath("config") .. "/splash.txt",
    vim.fn.stdpath("data") .. "/splash.txt",
  }

  for _, path in ipairs(candidates) do
    local fh = io.open(path, "r")
    if fh ~= nil then
      local lines = {} as {string}
      for line in fh:lines() do table.insert(lines, line) end
      fh:close()
      return lines
    end
  end

  return {}
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

local function any_real_file_buffer_exists(): boolean
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted then
      if vim.bo[b].buftype == "" then
        local name = vim.api.nvim_buf_get_name(b)
        if name ~= "" then
          return true
        end
      end
    end
  end
  return false
end

local function show_rakhsh_splash(): nil
  -- If any real file buffer already exists (e.g. user opened a file quickly), never show.
  if any_real_file_buffer_exists() then return end

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
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly   = false

  setup_splash_exit_on_insert(buf)
  setup_splash_keymaps(buf)
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
      vim.b[buf].rakhsh_splash_armed = true
    end
  end)
end
-- }=-
--------------------------------------------------------------------------------
--= Public Interface -={

local M: t.plugins.PluginModule = {}

local type PluginKeymap = t.plugins.PluginKeymap
function M.keymaps(): {PluginKeymap}
  return {}
end

function M.init(): nil
  --+ Only ever consider splash when no files were passed on the CLI.
  if vim.fn.argc() ~= 0 then return end

  local function show(): nil
    vim.schedule(function()
      show_rakhsh_splash()
    end)
  end

  --+ If this module is loaded after the UI already attached (lazy-loading),
  --+ UIEnter already fired.  In that case, show immediately.
  if #vim.api.nvim_list_uis() > 0 then
    show()
    return
  end

  --+ Otherwise wait for a UI to attach so the final grid size is known for centering.
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function() show() end,
  })
end

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): {PluginSpec}
  return {}
end
-- }=-

return M
