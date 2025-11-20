local t = require("core.types")
local u = require("core.utils")
local R = u.Roles;
local T = u.Tags;
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
  local keymaps: {PluginKeymap} = {
    { desc = "LSP: goto definition", tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      mode = "n", role = R.Nav, key = "gd", rhs = vim.lsp.buf.definition, on = On.Attach },
    { mode = "n", role = R.Nav, key = "gD", rhs = vim.lsp.buf.declaration,
      desc = "LSP: goto declaration",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "gI", rhs = vim.lsp.buf.implementation,
      desc = "LSP: goto implementation",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "gr", rhs = vim.lsp.buf.references,
      desc = "LSP: references",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Info, key = "H", rhs = vim.lsp.buf.hover,
      desc = "LSP: hover",
      tags = { T.ActionHelp, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Rename, key = "<leader>rn", rhs = vim.lsp.buf.rename,
      desc = "LSP: rename symbol",
      tags = { T.ActionEdit, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Code, key = "<leader>ca", rhs = vim.lsp.buf.code_action,
      desc = "LSP: code action",
      tags = { T.ActionEdit, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "gi", rhs = "<cmd>Telescope lsp_incoming_calls<CR>",
      desc = "LSP: incoming calls",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "go", rhs = "<cmd>Telescope lsp_outgoing_calls<CR>",
      desc = "LSP: outgoing calls",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Info, key = "<leader>e",
      rhs = function() vim.diagnostic.open_float() end,
      desc = "LSP: line diagnostics",
      tags = { T.ActionHelp, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "[d",
      rhs = vim.diagnostic.goto_prev,
      desc = "LSP: previous diagnostic",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "]d",
      rhs = vim.diagnostic.goto_next,
      desc = "LSP: next diagnostic",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "<leader>q",
      rhs = function() vim.diagnostic.setloclist() end,
      desc = "LSP: diagnostics loclist",
      tags = { T.ActionView, T.BasisContent, T.TargetWorkspace },
      on = On.Attach },

    { mode = "n", role = R.Info, key = "<leader>s",
      rhs = vim.lsp.buf.signature_help,
      desc = "LSP: signature help",
      tags = { T.ActionHelp, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Nav, key = "gt",
      rhs = vim.lsp.buf.type_definition,
      desc = "LSP: goto type definition",
      tags = { T.ActionView, T.BasisSymbol, T.TargetBuffer },
      on = On.Attach },

    { mode = "n", role = R.Code, key = "<leader>f", rhs = function() vim.lsp.buf.format({ async = true }) end,
      desc = "LSP: format",
      tags = { T.ActionEdit, T.BasisContent, T.TargetBuffer },
      on = On.Attach },
  }

  return {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    lazy = false,
    keymaps = keymaps,
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
          u.apply_plugin_attach_keymaps("plugins.lsp", e.buf)
        end,
      })
    end,
  } as PluginSpec
end

return M
