local t = require("core.types")
local T = t.tags.Tags
local R = t.roles.Roles
local On = t.plugins.KeymapEvents

global vim: t.vim.Vim

local type ChatGPTOpts = { string: any }
local record ChatGPT
  setup: function(ChatGPTOpts | nil): nil
end
 
local function guard(cmd: string): string|function
  local key = vim.env.OPENAI_API_KEY
  if key then return cmd end
  local err = function()
    vim.notify("[llm] OPENAI_API_KEY is not set", vim.log.levels.ERROR, {})
  end
  return err
end
 
local M: t.plugins.PluginModule = {}

local keymaps = {
  { mode = "n", role = R.AI, key = "c", on = On.Immediate, rhs = guard("<cmd>ChatGPT<CR>"), tags = { T.ActionLaunch, T.TargetDialogue }, desc = "ChatGPT: main chat window" },
  { mode = "v", role = R.AI, key = "e", on = On.Immediate, rhs = guard("<cmd>ChatGPTEditWithInstructions<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: edit selection with instructions (visual)" },
  { mode = "n", role = R.AI, key = "x", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun explain_code<CR>"), tags = { T.ActionHelp, T.TargetBuffer }, desc = "ChatGPT: explain code" },
  { mode = "n", role = R.AI, key = "f", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun fix_bugs<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: fix bugs" },
  { mode = "n", role = R.AI, key = "o", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun optimize_code<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: optimize code" },
  { mode = "n", role = R.AI, key = "t", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun add_tests<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: add tests" },
  { mode = "n", role = R.AI, key = "r", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun refactor<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: refactor" },
  { mode = "n", role = R.AI, key = "d", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun docstring<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: docstring" },
  { mode = "n", role = R.AI, key = "S", on = On.Immediate, rhs = guard("<cmd>ChatGPTSplit<CR>"), tags = { T.ActionLaunch, T.TargetDialogue }, desc = "ChatGPT: vertical split quick scratchpad chat" },
  { mode = "n", role = R.AI, key = "g", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun grammar_correction<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: grammar correction" },
  { mode = "v", role = R.AI, key = "l", on = On.Immediate, rhs = guard("<cmd>ChatGPTRun translate<CR>"), tags = { T.ActionEdit, T.TargetBuffer }, desc = "ChatGPT: translate selection" },
}

function M.lazy(): t.plugins.PluginSpec
  return {
    "jackMort/ChatGPT.nvim",
    lazy = false,
    keymaps = keymaps,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local key: string | nil = vim.env.OPENAI_API_KEY
      if key == nil or key == "" then return end

      local _mod = "chatgpt"
      local ok: boolean = pcall(require, _mod)
      if not ok then return end

      local chatgpt = (require(_mod) as ChatGPT)
      chatgpt.setup({ openai_params = { model = "gpt-5.1-mini", }, })
    end,
  } as t.plugins.PluginSpec
end

return M
