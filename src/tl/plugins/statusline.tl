local t = require("types")

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local type LualineOpts = { string: any }

local record Lualine
  setup: function(LualineOpts | nil): nil
  load_extension: function(string): nil
end

-- Minimal LSP typing shim for extern neovim types.
-- (Extern `vim.d.tl` in teal-types does not currently expose all `vim.lsp.*` keys.)
local record LspClient
  name: string
end

local record LspUtil
  get_progress_messages: function(): {any}
end

local record LspApi
  get_clients: function({ string: any } | nil): {LspClient}
  util: LspUtil
end

local function lsp(): LspApi
  return (vim.lsp as LspApi)
end

local function lsp_name(): string
  local clients = lsp().get_clients({ bufnr = 0 })
  if not clients or #clients == 0 then return "" end
  return clients[1].name
end

local function lsp_status(): string
  local ok, result = pcall(function(): {any} return lsp().util.get_progress_messages() end)
  if not ok then return "" end
  local progress = (result or {}) as {any}
  if #progress == 0 then return "" end
  return ""
end

local function recording_status(): string
  --+ Show current recording macro/register if any (e.g. @q)
  local rec = (vim.fn.reg_recording() as string)
  if rec ~= "" then return "@" .. rec end
  local exec = (vim.fn.reg_executing() as string)
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

--------------------------------------------------------------------------------

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {}
end

function M.lazy(): {PluginSpec}
  local spec = ({
    "nvim-lualine/lualine.nvim",
    lazy = false,
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
    end,
  } as PluginSpec)

  return { spec }
end

return M
