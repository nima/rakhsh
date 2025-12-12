local t = require("core.types")
local plugins = require("core.plugins")
local keymaps = require("core.keymaps")
local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local OnEvents = t.plugins.KeymapEvents

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.GoVia,   key = "i",  rhs = "<cmd>Telescope lsp_incoming_calls<CR>", on = OnEvents.Attach, desc = "[LSP] incoming calls",           tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.GoVia,   key = "o",  rhs = "<cmd>Telescope lsp_outgoing_calls<CR>", on = OnEvents.Attach, desc = "[LSP] outgoing calls",           tags = { T.ActionView, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "f",  rhs = function() vim.lsp.buf.format({ async = true }) end, on = OnEvents.Attach, desc = "[LSP] format",                  tags = { T.ActionEdit, T.TargetBuffer } },
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

          local b = e.buf

          -- Neovim LSP defaults (vim/_defaults.lua) - document only.
          keymaps.docmap_buf(b, "n", "gd",  keymaps.opts("[LSP] Goto definition",        { T.ActionView, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "gD",  keymaps.opts("[LSP] Goto declaration",       { T.ActionView, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "gi",  keymaps.opts("[LSP] Goto implementation",    { T.ActionNavigate, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "grr", keymaps.opts("[LSP] References",             { T.ActionList, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "grt", keymaps.opts("[LSP] goto type definition",   { T.ActionView, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "grn", keymaps.opts("[LSP] rename symbol",          { T.ActionEdit, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "gra", keymaps.opts("[LSP] code action",            { T.ActionEdit, T.TargetBuffer }))

          -- Common Neovim LSP defaults for info/help.
          keymaps.docmap_buf(b, "n", "K",     keymaps.opts("[LSP] hover",                { T.ActionHelp, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "<C-k>", keymaps.opts("[LSP] signature help",       { T.ActionHelp, T.TargetBuffer }))

          -- Neovim diagnostic defaults.
          keymaps.docmap_buf(b, "n", "gl", keymaps.opts("[LSP] line diagnostics",        { T.ActionHelp, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "[d", keymaps.opts("[LSP] previous diagnostic",      { T.ActionView, T.TargetBuffer }))
          keymaps.docmap_buf(b, "n", "]d", keymaps.opts("[LSP] next diagnostic",          { T.ActionView, T.TargetBuffer }))
        end,
      })
    end,
  } as PluginSpec)

  return { lsp_spec }
end

return M
