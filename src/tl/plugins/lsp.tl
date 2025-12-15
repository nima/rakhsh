local t = require("types")
local plugins = require("core.plugins")
local keymaps = require("core.keymaps")
local R = t.roles.Roles
local T = t.tags.Tags
global vim: t.vim.Vim

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local OnEvents = t.plugins.KeymapEvents

local function toggle_loclist()
  local info = vim.fn.getloclist(0, { winid = 0 })
  local winid = info.winid or 0
  if winid ~= 0 then
    vim.cmd.lclose()
    return
  end
  vim.diagnostic.setloclist()
  vim.cmd.lopen()
  vim.api.nvim_command("wincmd p")
end

local function format_buffer() vim.lsp.buf.format({ async = true }) end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode = "n", role = R.GoVia,   key = "i",  rhs = "<cmd>Telescope lsp_incoming_calls<CR>", on = OnEvents.Attach, desc = "[LSP] incoming calls",      tags = { T.ActionView, T.TargetBuffer    } },
    { mode = "n", role = R.GoVia,   key = "o",  rhs = "<cmd>Telescope lsp_outgoing_calls<CR>", on = OnEvents.Attach, desc = "[LSP] outgoing calls",      tags = { T.ActionView, T.TargetBuffer    } },
    { mode = "n", role = R.LSPEdit, key = "f",  rhs = format_buffer, on = OnEvents.Attach,                           desc = "[LSP] format",              tags = { T.ActionEdit, T.TargetBuffer    } },
    { mode = "n", role = R.Toggle,  key = "D",  rhs = toggle_loclist, on = OnEvents.Attach,                          desc = "[LSP] diagnostics loclist", tags = { T.ActionView, T.TargetWorkspace } },
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

local function get_python_executable_path(): string
  local conda_prefix = os.getenv("CONDA_PREFIX")
  if conda_prefix then return conda_prefix .. "/bin/python" end

  return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
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
      lsp.config("pyright", { capabilities = capabilities, settings = { python = { pythonPath = get_python_executable_path() }}})
      lsp.config("gopls",   { capabilities = capabilities })
      lsp.config("lua_ls", { capabilities = capabilities, settings = luaCfg })
      lsp.enable({ "bashls", "clangd", "pyright", "gopls", "lua_ls" })

      local api = vim.api as LspAttachApi
      api.nvim_create_autocmd("LspAttach", {
        callback = function(e: LspAttachEvent)
          plugins.apply_plugin_attach_keymaps("plugins.lsp", e.buf)

          local b = e.buf

          -- Neovim LSP defaults (vim/_defaults.lua).
          -- Install buffer-local mappings *only if unmapped* (never clobber external managers),
          -- and keep them documented in our keymap registry.

          -- LSP navigation / actions.
          keymaps.safemap_buf(b, "n", R.Go, "d",  vim.lsp.buf.definition,       keymaps.opts("[LSP] Goto definition",       { T.ActionView,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Go, "D",  vim.lsp.buf.declaration,      keymaps.opts("[LSP] Goto declaration",      { T.ActionView,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Go, "i",  vim.lsp.buf.implementation,   keymaps.opts("[LSP] Goto implementation",   { T.ActionNavigate, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Go, "rr", vim.lsp.buf.references,       keymaps.opts("[LSP] References",            { T.ActionList,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Go, "rt", vim.lsp.buf.type_definition,  keymaps.opts("[LSP] goto type definition",  { T.ActionView,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Go, "rn", vim.lsp.buf.rename,           keymaps.opts("[LSP] rename symbol",         { T.ActionEdit,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Go, "ra", vim.lsp.buf.code_action,      keymaps.opts("[LSP] code action",           { T.ActionEdit,     T.TargetBuffer }))

          -- LSP info/help.
          keymaps.docmap_buf(b, "n", "K",  keymaps.opts("[LSP] hover", { T.ActionHelp, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Naked, "<C-k>", vim.lsp.buf.signature_help,  keymaps.opts("[LSP] signature help",       { T.ActionHelp, T.TargetBuffer }))

          -- Diagnostics.
          keymaps.safemap_buf(b, "n", R.Go,    "l", vim.diagnostic.open_float,  keymaps.opts("[LSP] line diagnostics",        { T.ActionHelp, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Naked, "[d", vim.diagnostic.goto_prev,  keymaps.opts("[LSP] previous diagnostic",      { T.ActionView, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Naked, "]d", vim.diagnostic.goto_next,  keymaps.opts("[LSP] next diagnostic",          { T.ActionView, T.TargetBuffer }))
        end,
      })

      vim.diagnostic.config({
        underline = true,
        virtual_text = true,
        signs = true,
        severity_sort = true,
      })

      vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#3a1f1f" })
      vim.api.nvim_set_hl(0, "DiagnosticLineWarn",  { bg = "#3a341f" })
      vim.api.nvim_set_hl(0, "DiagnosticLineInfo",  { bg = "#1f2a3a" })
      vim.api.nvim_set_hl(0, "DiagnosticLineHint",  { bg = "#1f2f2a" })

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#3a1f1f" })
          vim.api.nvim_set_hl(0, "DiagnosticLineWarn",  { bg = "#3a341f" })
          vim.api.nvim_set_hl(0, "DiagnosticLineInfo",  { bg = "#1f2a3a" })
          vim.api.nvim_set_hl(0, "DiagnosticLineHint",  { bg = "#1f2f2a" })
        end,
      })
    end,
  } as PluginSpec)

  return { lsp_spec }
end

return M
