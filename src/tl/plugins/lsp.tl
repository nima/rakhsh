local t = require("core.types")
local keymaps = require("core.keymaps")
local plugins = require("core.plugins")
local R = keymaps.Roles;
local T = keymaps.Tags;
global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap

local M: t.plugins.PluginModule = {}

local record LspAttachEvent
  buf: integer
end

local record LspAttachOpts
  callback: function(e: LspAttachEvent): ()
end

local record LspAttachApi
  nvim_create_autocmd: function(event: string, opts: LspAttachOpts): integer
end

local record CmpLspModule
  default_capabilities: function(any): any
end

local On = t.plugins.KeymapEvents
function M.lazy(): PluginSpec
  local plugin_keymaps: {PluginKeymap} = {
    { mode = "n", role = R.Go,     key = "gd", rhs = vim.lsp.buf.definition, on = On.Attach, desc = "LSP: goto definition", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.Go,     key = "gD", rhs = vim.lsp.buf.declaration, on = On.Attach, desc = "LSP: goto declaration", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.Go,     key = "gI", rhs = vim.lsp.buf.implementation, on = On.Attach, desc = "LSP: goto implementation", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.Go,     key = "gr", rhs = vim.lsp.buf.references, on = On.Attach, desc = "LSP: references", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.Go,     key = "gt", rhs = vim.lsp.buf.type_definition, on = On.Attach, desc = "LSP: goto type definition", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.GoVia,  key = "gi", rhs = "<cmd>Telescope lsp_incoming_calls<CR>", on = On.Attach, desc = "LSP: incoming calls", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.GoVia,  key = "go", rhs = "<cmd>Telescope lsp_outgoing_calls<CR>", on = On.Attach, desc = "LSP: outgoing calls", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPInfo, key = "H",  rhs = vim.lsp.buf.hover, on = On.Attach, desc = "LSP: hover", tags = { T.ActionHelp, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPInfo, key = "s",  rhs = vim.lsp.buf.signature_help, on = On.Attach, desc = "LSP: signature help", tags = { T.ActionHelp, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "f",  rhs = function() vim.lsp.buf.format({ async = true }) end, on = On.Attach, desc = "LSP: format", tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "rn", rhs = vim.lsp.buf.rename, on = On.Attach, desc = "LSP: rename symbol", tags = { T.ActionEdit, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPEdit, key = "ca", rhs = vim.lsp.buf.code_action, on = On.Attach, desc = "LSP: code action", tags = { T.ActionEdit, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "e",  rhs = function() vim.diagnostic.open_float() end, on = On.Attach, desc = "LSP: line diagnostics", tags = { T.ActionHelp, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "[d", rhs = vim.diagnostic.goto_prev, on = On.Attach, desc = "LSP: previous diagnostic", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "]d", rhs = vim.diagnostic.goto_next, on = On.Attach, desc = "LSP: next diagnostic", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer } },
    { mode = "n", role = R.LSPDiag, key = "q",  rhs = function() vim.diagnostic.setloclist() end, on = On.Attach, desc = "LSP: diagnostics loclist", tags = { T.ActionView, T.BasisContent, T.TargetWorkspace } },
  }

  return {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    lazy = false,
    keymaps = plugin_keymaps,
    config = function()
      local _ = "cmp_nvim_lsp"
      local mod = (require(_) as CmpLspModule)
      local capabilities = mod.default_capabilities(vim.lsp.protocol.make_client_capabilities())
      local lsp = vim.lsp
      
      local luaCfg = { Lua = { diagnostics = { globals = { "vim" } } } }
      local clangCfg = { "clangd", "--compile-commands-dir=build" }
      --lsp.config("make", { capabilities = capabilities })
      lsp.config("bashls", { capabilities = capabilities })
      lsp.config("clangd", { capabilities = capabilities, cmd = clangCfg })
      lsp.config("pyright", { capabilities = capabilities })
      lsp.config("gopls",   { capabilities = capabilities })
      --lsp.config("teal_ls", { capabilities = capabilities })
      lsp.config("lua_ls", { capabilities = capabilities, settings = luaCfg })
      lsp.enable({ "bashls", "clangd", "pyright", "gopls", "lua_ls" })

      local api = vim.api as LspAttachApi
      api.nvim_create_autocmd("LspAttach", {
        callback = function(e: LspAttachEvent)
          plugins.apply_plugin_attach_keymaps("plugins.lsp", e.buf)
        end,
      })
    end,
  } as PluginSpec
end

return M
