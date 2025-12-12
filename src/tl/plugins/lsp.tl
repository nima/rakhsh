local t = require("core.types")
local plugins = require("core.plugins")
local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local OnEvents = t.plugins.KeymapEvents

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.Go,      key = "d",  rhs = vim.lsp.buf.definition,                 on = OnEvents.Attach, desc = "[LSP] Goto definition",          tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.Go,      key = "D",  rhs = vim.lsp.buf.declaration,                on = OnEvents.Attach, desc = "[LSP] Goto declaration",         tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.Go,      key = "I",  rhs = vim.lsp.buf.implementation,             on = OnEvents.Attach, desc = "[LSP] Goto implementation",      tags = { T.ActionNavigate, T.TargetBuffer } },
    { mode = "n", role = R.Go,      key = "r",  rhs = vim.lsp.buf.references,                 on = OnEvents.Attach, desc = "[LSP] References",               tags = { T.ActionList, T.TargetBuffer } },
    { mode = "n", role = R.Go,      key = "t",  rhs = vim.lsp.buf.type_definition,            on = OnEvents.Attach, desc = "[LSP] goto type definition",     tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.GoVia,   key = "i",  rhs = "<cmd>Telescope lsp_incoming_calls<CR>", on = OnEvents.Attach, desc = "[LSP] incoming calls",           tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.GoVia,   key = "o",  rhs = "<cmd>Telescope lsp_outgoing_calls<CR>", on = OnEvents.Attach, desc = "[LSP] outgoing calls",           tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.LSPInfo, key = "H",  rhs = vim.lsp.buf.hover,                       on = OnEvents.Attach, desc = "[LSP] hover",                   tags = { T.ActionHelp, T.TargetBuffer } },
    { mode = "n", role = R.LSPInfo, key = "s",  rhs = vim.lsp.buf.signature_help,              on = OnEvents.Attach, desc = "[LSP] signature help",          tags = { T.ActionHelp, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "f",  rhs = function() vim.lsp.buf.format({ async = true }) end, on = OnEvents.Attach, desc = "[LSP] format",                  tags = { T.ActionEdit, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "rn", rhs = vim.lsp.buf.rename,                      on = OnEvents.Attach, desc = "[LSP] rename symbol",           tags = { T.ActionEdit, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "ca", rhs = vim.lsp.buf.code_action,                 on = OnEvents.Attach, desc = "[LSP] code action",             tags = { T.ActionEdit, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "e",  rhs = function() vim.diagnostic.open_float() end, on = OnEvents.Attach, desc = "[LSP] line diagnostics",        tags = { T.ActionHelp, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "[d", rhs = vim.diagnostic.goto_prev,                on = OnEvents.Attach, desc = "[LSP] previous diagnostic",      tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "]d", rhs = vim.diagnostic.goto_next,                on = OnEvents.Attach, desc = "[LSP] next diagnostic",          tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "q",  rhs = function() vim.diagnostic.setloclist() end, on = OnEvents.Attach, desc = "[LSP] diagnostics loclist",      tags = { T.ActionView, T.TargetWorkspace } },
  }
end

local record LspAttachEvent
  buf: integer
end

local record LspAttachOpts
  callback: function(e: LspAttachEvent): ()
end

local record LspAttachApi
  nvim_create_autocmd: function(event: string, opts: LspAttachOpts): integer
end

local record CmpNvimLsp
  default_capabilities: function(any): any
end

function M.lazy(): {PluginSpec}
  local lsp_spec = ({
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()

      --+ Augment capabilities via cmp-nvim-lsp (expected to be installed by plugins/cmp).
      local _mod = "cmp_nvim_lsp"
      local cmp_lsp = (require(_mod) as CmpNvimLsp)
      capabilities = cmp_lsp.default_capabilities(capabilities)

      local lsp = vim.lsp

      local luaCfg = { Lua = { diagnostics = { globals = { "vim" } } } }
      local clangCfg = { "clangd", "--compile-commands-dir=build" }
      lsp.config("bashls", { capabilities = capabilities })
      lsp.config("clangd", { capabilities = capabilities, cmd = clangCfg })
      lsp.config("pyright", { capabilities = capabilities })
      lsp.config("gopls",   { capabilities = capabilities })
      lsp.config("lua_ls", { capabilities = capabilities, settings = luaCfg })
      lsp.enable({ "bashls", "clangd", "pyright", "gopls", "lua_ls" })

      local api = vim.api as LspAttachApi
      api.nvim_create_autocmd("LspAttach", {
        callback = function(e: LspAttachEvent)
          plugins.apply_plugin_attach_keymaps("plugins.lsp", e.buf)
        end,
      })
    end,
  } as PluginSpec)

  return { lsp_spec }
end

return M
