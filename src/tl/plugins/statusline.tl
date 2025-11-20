local t = require("core.types")
global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

local type LualineOpts = { string: any }
local record Lualine
  setup: function(LualineOpts | nil): nil
  load_extension: function(string): nil
end

local function lsp_name(): string
  local vlspcf: t.vim.VimLSPClientFilter = { bufnr = 0 }
  local clients = vim.lsp.get_clients(vlspcf)
  if not clients or #clients == 0 then return "" end
  return clients[1].name
end

local function lsp_status(): string
  local ok, result = pcall(function(): {any} return vim.lsp.util.get_progress_messages() end)
  if not ok then return "" end
  local progress = (result or {}) as {any}
  if #progress == 0 then return "" end
  return ""
end

local function recording_status(): string
  --+ Show current recording macro/register if any (e.g. @q)
  local rec = vim.fn.reg_recording()
  if rec ~= "" then return "@" .. rec end
  local exec = vim.fn.reg_executing()
  if exec ~= "" then return "@" .. exec end
  return ""
end

local alphasoup = { "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z" }
local function used_registers(): string
  local used: {string} = {}
  for _, r in ipairs(alphasoup) do
    local contents = vim.fn.getreg(r) as string
    if contents ~= "" then table.insert(used, r) end
  end
  if #used == 0 then return "" end
  return '\"' .. table.concat(used, "")
end

local function used_marks(): string
  local used: {string} = {}
  for _, m in ipairs(alphasoup) do
    local pos = vim.api.nvim_buf_get_mark(0, m) as {integer, integer}
    if pos[1] ~= 0 then table.insert(used, m) end
  end
  if #used == 0 then return "" end
  return "'" .. table.concat(used, "")
end

local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  return {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    keymaps = {},
    dependencies = {},
    config = function()
      local _mod = "lualine"
      local mod = (require(_mod) as Lualine)
      mod.setup({
        options = {
          theme = "auto",
          icons_enabled = true,
          globalstatus = true,
          section_separators   = "",
          component_separators = "",
        },
        sections = {
          lualine_a = { "mode", recording_status },
          lualine_b = {
            "branch",
            {
              "diff", symbols = { added = "+", modified = "~", removed = "-" },
            },
          },
          lualine_c = {
            "filename",
            {
              "diagnostics",
              sources = { "nvim_diagnostic" },
              sections = { "error", "warn", "info", "hint" },
              symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" },
              update_in_insert = true,
            },
          },
          lualine_x = { lsp_name, lsp_status, "filetype" },
          lualine_y = { used_registers, used_marks, "progress" },
          lualine_z = { "location" },
        },
      })
    end
  } as PluginSpec
end

return M
