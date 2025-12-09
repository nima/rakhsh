local t = require("core.types")
local R = t.roles.Roles
local T = t.tags.Tags

global vim: t.vim.Vim

-- One entry per safemap-registered keymap
local record RakhshKeymap
  mode: string
  role: t.roles.Role
  key: string
  rhs: string
  desc: string
  tags: { t.tags.Tag }
  group: string | nil  -- optional logical grouping
end
local registry: {RakhshKeymap} = {}

local record TelescopeEntry
  value: RakhshKeymap
end

local record TelescopePicker
  find: function(TelescopePicker): nil
end

local type TelescopeMapFn = function(mode: string, lhs: string, fn: function(integer): nil): nil

local keymaps = {
  { mode = "n", role = R.Naked, key = "<C-F5>", rhs = "<cmd>lua dofile(vim.fn.stdpath('config') .. '/init.lua')<CR>", desc = "Reload Rakhsh config", tags = { T.ActionView } },
  { mode = "n", role = R.Naked, key = "<C-Space>", rhs = "<cmd>WhichKey<CR>", desc = "Show which-key menu", tags = { T.ActionView } },
  { mode = "n", role = R.Naked, key = "<C-c>", rhs = "<cmd>:confirm quitall<CR>", desc = "Quitall", tags = { T.ActionView } },
}

local record RakhshHotkeysCore
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

function M.show_help(): nil
  if #registry == 0 then
    vim.notify("No Rakhsh keymaps registered yet", vim.log.levels.INFO)
    return
  end

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

  -- Highlight groups for the RakhshKeys columns
  vim.api.nvim_set_hl(0, "RakhshKeyMode", { link = "Type" })
  vim.api.nvim_set_hl(0, "RakhshKeyKey",  { link = "ErrorMsg" })
  vim.api.nvim_set_hl(0, "RakhshKeyDesc", { link = "String" })
  vim.api.nvim_set_hl(0, "RakhshKeyTags", { link = "Keyword" })

  local function make_display(entry: TelescopeEntry): string
    local m = entry.value
    local full = m.desc
    local desc = full
    local tags_suffix = ""

    -- If description already has a trailing [#tag,...] block, split it out
    local s, _e = string.find(full, "%[[^%]]+%]%s*$")
    if s ~= nil then
      desc = vim.trim(string.sub(full, 1, s - 1))
      tags_suffix = string.sub(full, s)
    end

    return displayer({
      { m.mode,       "RakhshKeyMode" },
      { m.key,        "RakhshKeyKey" },
      { desc,         "RakhshKeyDesc" },
      { tags_suffix,  "RakhshKeyTags" },
    })
  end

  local picker = pickers.new({}, {
    prompt_title = "Rakhsh keymaps",
    finder = finders.new_table({
      results = registry,
      entry_maker = function(m: RakhshKeymap): any
        local ordinal = m.mode .. " " .. m.key .. " " .. m.desc
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
          local lhs = keymap.key
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
