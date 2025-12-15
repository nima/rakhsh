local t = require("types")
local R = t.roles.Roles
local T = t.tags.Tags

global vim: t.vim.Vim

--+ One entry per safemap-registered keymap
local record RakhshKeymap
  mode: string
  role: t.roles.Role
  key: string
  internal: boolean
  rhs: string
  desc: string
  tags: { t.tags.Tag }
  group: string | nil  --+ logical grouping
end
local registry: {RakhshKeymap} = {}

local type RegistryMap = { string: boolean }
local registry_map: RegistryMap = {}

local function lhs_for(mode: string, role: t.roles.Role, key: string): string
  local mode_cfg = t.roles.ActivationPrefix[mode]
  if not mode_cfg then
    -- Visual/select modes can reuse normal-mode prefixes.
    if mode == "v" or mode == "x" or mode == "s" then
      mode_cfg = t.roles.ActivationPrefix["n"]
    end
  end
  if not mode_cfg then
    -- Don't crash the picker; just show the raw key.
    return key
  end

  local prefix = mode_cfg[role]

  -- If the role isn't defined for this mode, fall back to normal-mode prefixes for v/x/s.
  if not prefix and (mode == "v" or mode == "x" or mode == "s") then
    local n_cfg = t.roles.ActivationPrefix["n"]
    if n_cfg then
      prefix = n_cfg[role]
    end
  end

  -- Still unknown: don't crash; show the raw key.
  if not prefix then
    return key
  end

  -- Insert META special-case: <C-x>
  if mode == "i" and prefix == "<C-" then
    return prefix .. key .. ">"
  end

  return prefix .. key
end

local function registry_key(m: RakhshKeymap): string
  return table.concat({
    m.mode or "",
    m.role and tostring(m.role) or "",
    m.key or "",
    m.group or "",
    m.internal and "1" or "0",
  }, "\0")
end

local function format_tags(tags: { t.tags.Tag }): string
  if tags == nil or #tags == 0 then
    return ""
  end

  local rendered: {string} = {}
  for _, tag in ipairs(tags) do
    if tag.tid ~= nil then
      table.insert(rendered, "#" .. tag.tid)
    end
  end

  if #rendered == 0 then
    return ""
  end

  return "[" .. table.concat(rendered, ", ") .. "]"
end

local record TelescopeEntry
  value: RakhshKeymap
end

local record TelescopePicker
  find: function(TelescopePicker): nil
end

local type TelescopeMapFn = function(mode: string, lhs: string, fn: function(integer): nil): nil

local keymaps = {
  { mode = "n", role = R.Naked, key = "<C-F5>", internal = true, rhs = "<cmd>lua dofile(vim.fn.stdpath('config') .. '/init.lua')<CR>", desc = "Reload Rakhsh config", tags = { T.ActionView } },
  { mode = "n", role = R.Naked, key = "<C-Space>", internal = true, rhs = "<cmd>WhichKey<CR>", desc = "Show which-key menu", tags = { T.ActionView } },
  { mode = "n", role = R.Naked, key = "<C-c>", internal = true, rhs = "<cmd>:confirm quitall<CR>", desc = "Quitall", tags = { T.ActionView } },
}

--------------------------------------------------------------------------------

local record RakhshHotkeysCore
  RakhshKeymap: RakhshKeymap
  init: function(): nil
  register: function(RakhshKeymap): nil
  registry: function(): {RakhshKeymap}
  show_help: function(): nil
  keymaps: {RakhshKeymap}
  apply_initial_keymaps: function(): nil
end

local M: RakhshHotkeysCore = {
  keymaps = keymaps,
}

function M.apply_initial_keymaps(): nil
  for _, m in ipairs(keymaps) do
    vim.keymap.set(m.mode, m.key, m.rhs, {
      desc = m.desc,
      silent = true,
      noremap = true,
    })
    M.register(m)
  end
end

local hl_inited = false
local function ensure_hl(): nil
  if hl_inited then
    return
  end
  hl_inited = true
  -- Highlight groups for the RakhshKeys columns
  vim.api.nvim_set_hl(0, "RakhshKeyMode", { link = "Type" })
  vim.api.nvim_set_hl(0, "RakhshKeyKeySafe", { bold = true, link = "ErrorMsg" })
  vim.api.nvim_set_hl(0, "RakhshKeyKeyDoc",  { italic = true, link = "Comment" })
  vim.api.nvim_set_hl(0, "RakhshKeyDesc", { link = "String" })
  vim.api.nvim_set_hl(0, "RakhshKeyTags", { link = "Keyword" })
end

function M.show_help(): nil
  if #registry == 0 then
    vim.notify("No Rakhsh keymaps registered yet", vim.log.levels.INFO)
    return
  end

  ensure_hl()

  local _pickers = "telescope.pickers"
  local pickers = require(_pickers) as t.telescope.Pickers
  local _finders = "telescope.finders"
  local finders = require(_finders) as t.telescope.Finders
  local _conf = "telescope.config"
  local conf = (require(_conf) as t.telescope.Config).values
  local _entry_display = "telescope.pickers.entry_display"
  local entry_display = require(_entry_display) as t.telescope.EntryDisplay
  local _actions = "telescope.actions"
  local actions = require(_actions) as t.telescope.Actions
  local _action_state = "telescope.actions.state"
  local action_state = require(_action_state) as t.telescope.ActionState

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 2 },   -- mode
      { width = 12 },  -- key
      { remaining = true }, -- desc
      { remaining = true }, -- tags
    },
  })

  local function make_display(entry: TelescopeEntry): string
    local m = entry.value
    local desc = m.desc or ""
    local tags_suffix = format_tags(m.tags)

    return displayer({
      { m.mode,       "RakhshKeyMode" },
      { lhs_for(m.mode, m.role, m.key), (m.internal and "RakhshKeyKeySafe" or "RakhshKeyKeyDoc") },
      { desc,         "RakhshKeyDesc" },
      { tags_suffix,  "RakhshKeyTags" },
    })
  end

  local picker = pickers.new({}, {
    prompt_title = "Rakhsh keymaps",
    finder = finders.new_table({
      results = registry,
      entry_maker = function(m: RakhshKeymap): any
        local tags_suffix = format_tags(m.tags)
        local lhs = lhs_for(m.mode, m.role, m.key)
        local ordinal = table.concat({
          m.mode,
          lhs,
          (m.desc or ""),
          (m.rhs or ""),
          tags_suffix,
        }, " ")
        return {
          value = m,
          ordinal = ordinal,
          display = make_display,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map: TelescopeMapFn): boolean
      local function run_selected(prompt_bufnr: integer): nil
        local entry_any = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry_any ~= nil then
          local entry = entry_any as TelescopeEntry
          local keymap = entry.value
          local lhs = lhs_for(keymap.mode, keymap.role, keymap.key)
          local keys = vim.api.nvim_replace_termcodes(lhs, true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end
      end
      map("i", "<CR>", run_selected)
      map("n", "<CR>", run_selected)
      return true
    end,
  }) as TelescopePicker

  picker:find()
end

function M.register(map: RakhshKeymap): nil
  local key = registry_key(map)
  if registry_map[key] then
    return
  end
  registry_map[key] = true
  table.insert(registry, map)
end

function M.registry(): {RakhshKeymap}
  return registry
end

vim.api.nvim_create_user_command("RakhshKeys", function()
  M.show_help()
end, {})

function M.init(): nil
  M.apply_initial_keymaps()
end

return M
