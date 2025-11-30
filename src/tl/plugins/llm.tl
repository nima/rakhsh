local t = require("core.types")
local u = require("core.utils")
local On = t.plugins.KeymapEvents
local R = u.Roles
local T = u.Tags

global vim: t.vim.Vim

local M: t.plugins.PluginModule = {}

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
 
local type PluginSpec = t.plugins.PluginSpec
function M.lazy(): PluginSpec
  local keymaps = {
    { mode = "n", role = R.AI, key = "c", rhs = guard("<cmd>ChatGPT<CR>"),
      desc = "ChatGPT: main chat window",
      tags = { T.ActionLaunch, T.TargetDialogue },
      on = On.Immediate },

    { mode = "v", role = R.AI, key = "e", rhs = guard("<cmd>ChatGPTEditWithInstructions<CR>"),
      desc = "ChatGPT: edit selection with instructions (visual)",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "x", rhs = guard("<cmd>ChatGPTRun explain_code<CR>"),
      desc = "ChatGPT: explain code",
      tags = { T.ActionHelp, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "f", rhs = guard("<cmd>ChatGPTRun fix_bugs<CR>"),
      desc = "ChatGPT: fix bugs",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "o", rhs = guard("<cmd>ChatGPTRun optimize_code<CR>"),
      desc = "ChatGPT: optimize code",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "t", rhs = guard("<cmd>ChatGPTRun add_tests<CR>"),
      desc = "ChatGPT: add tests",
      tags = { T.ActionEdit, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "r", rhs = guard("<cmd>ChatGPTRun refactor<CR>"),
      desc = "ChatGPT: refactor",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "d", rhs = guard("<cmd>ChatGPTRun docstring<CR>"),
      desc = "ChatGPT: docstring",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "S", rhs = guard("<cmd>ChatGPTSplit<CR>"),
      desc = "ChatGPT: vertical split quick scratchpad chat",
      tags = { T.ActionLaunch, T.TargetDialogue },
      on = On.Immediate },

    { mode = "n", role = R.AI, key = "g", rhs = guard("<cmd>ChatGPTRun grammar_correction<CR>"),
      desc = "ChatGPT: grammar correction",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },

    { mode = "v", role = R.AI, key = "l", rhs = guard("<cmd>ChatGPTRun translate<CR>"),
      desc = "ChatGPT: translate selection",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Immediate },
  }
  return {
    "jackMort/ChatGPT.nvim",
    lazy = false,
    keymaps = keymaps,
    dependencies = {
      "kiddos/gemini.nvim",
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
  } as PluginSpec
end

return M
