local t = require("types")
local plugins = require("core.plugins")
local keymaps = require("core.keymaps")
local R = t.roles.Roles
local T = t.tags.Tags

local type PluginSpec = t.plugins.PluginSpec
local type PluginKeymap = t.plugins.PluginKeymap
local OnEvents = t.plugins.KeymapEvents

-- Boundary types: extern vim.d.tl doesn't fully model these dynamic modules yet.
local type LocListOpts = record
  winid: integer
end

local type LocListInfo = record
  winid: integer
end

local type VimLspProtocol = record
  make_client_capabilities: function(): any
end

local type VimLspBuf = record
  format: function(opts: any): any
  definition: function(): any
  declaration: function(): any
  implementation: function(): any
  references: function(): any
  type_definition: function(): any
  rename: function(): any
  code_action: function(): any
  signature_help: function(): any
end

local type VimLsp = record
  protocol: VimLspProtocol
  buf: VimLspBuf
  config: function(name: string, cfg: any): any
  enable: function(names: string | {string}): any
end


local type CmpNvimLspMod = record
  default_capabilities: function(c: any): any
end

local type VimDiagnostic = record
  config: function(opts: any, namespace: integer): any
end


local function toggle_loclist()
  local info = (vim.fn.getloclist(0, ({ winid = 0 } as LocListOpts)) as LocListInfo)
  local winid = info.winid
  if winid ~= 0 then
    vim.cmd("lclose")
    return
  end
  vim.diagnostic.setloclist({})
  vim.cmd("lopen")
  vim.cmd("wincmd p")
end

local function format_buffer(...: any): any
  select('#', ...)
  local lsp: VimLsp = vim.lsp as VimLsp
  lsp.buf.format({ async = true })
end

local function act_on_buf(...: any): any
  select('#', ...)
  local lsp: VimLsp = vim.lsp as VimLsp
  lsp.buf.code_action()
end

local M: t.plugins.PluginModule = {}

function M.keymaps(): {PluginKeymap}
  return {
    { mode="n", role=R.LSPGoto, key="gi", on=OnEvents.Attach, tags={ T.ActionView, T.TargetBuffer    }, rhs="<Cmd>Telescope hierarchy incoming_calls<CR>", desc="[LSP] incoming call hierarchy" },
    { mode="n", role=R.LSPGoto, key="go", on=OnEvents.Attach, tags={ T.ActionView, T.TargetBuffer    }, rhs="<Cmd>Telescope hierarchy outgoing_calls<CR>", desc="[LSP] outgoing call hierarchy" },
    { mode="n", role=R.LSPEdit, key="f",  on=OnEvents.Attach, tags={ T.ActionEdit, T.TargetBuffer    }, rhs=format_buffer,                                 desc="[LSP] format",                 },
    { mode="n", role=R.Toggle,  key="D",  on=OnEvents.Attach, tags={ T.ActionView, T.TargetWorkspace }, rhs=toggle_loclist,                                desc="[LSP] diagnostics loclist",    },
    { mode="x", role=R.LSPEdit, key="A",  on=OnEvents.Attach, tags={ T.ActionEdit, T.TargetBuffer    }, rhs=act_on_buf,                                    desc="[LSP] code actions",           },
  }
end

local function get_python_executable_path(): string
  local conda_prefix = os.getenv("CONDA_PREFIX")
  if conda_prefix then return conda_prefix .. "/bin/python" end

  local p3 = vim.fn.exepath("python3") as string
  if p3 ~= "" then return p3 end

  local p = vim.fn.exepath("python") as string
  if p ~= "" then return p end

  return "python"
end

local function mk_capabilities(): any
  local lsp: VimLsp = vim.lsp as VimLsp
  local capabilities = lsp.protocol.make_client_capabilities()

  --+ Augment capabilities via cmp-nvim-lsp (expected to be installed by plugins/cmp).
  local _mod = "cmp_nvim_lsp"
  local cmp_lsp = require(_mod) as CmpNvimLspMod
  capabilities = cmp_lsp.default_capabilities(capabilities)
  return capabilities
end

function M.lazy(): {PluginSpec}
  local lsp_spec = ({
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "jmacadie/telescope-hierarchy.nvim",
    },
    config = function()
      local lsp: VimLsp = vim.lsp as VimLsp
      local capabilities = mk_capabilities()

      --+ Configure servers once. Enable them lazily on first matching FileType.
      local enabled: {string:boolean} = {}
      local function autoenable(pattern: string | {string}, server: string): any
        vim.api.nvim_create_autocmd("FileType", {
          pattern = pattern,
          callback = function(_: vim.AutocmdCallbackData): any
            if enabled[server] then return nil end
            enabled[server] = true
            lsp.enable({ server })
            return nil
          end,
        })
        return nil
      end

      lsp.config("gopls", { capabilities = capabilities })
      autoenable({ "go", "gomod", "gowork", "gotmpl" }, "gopls")

      lsp.config("bashls", { capabilities = capabilities })
      autoenable({ "sh", "bash", "zsh" }, "bashls")

      lsp.config("teal_ls", { capabilities = capabilities })
      autoenable({ "teal" }, "teal_ls")

      local luaSettings = { Lua = { diagnostics = { globals = { "vim" } } } }
      lsp.config("lua_ls", { capabilities = capabilities, settings = luaSettings })
      autoenable({ "lua" }, "lua_ls")

      local clangCfg = { "clangd", "--compile-commands-dir=build" }
      lsp.config("clangd", { capabilities = capabilities, cmd = clangCfg })
      autoenable({ "c", "cpp", "objc", "objcpp" }, "clangd")

      lsp.config("pyright", { capabilities = capabilities, settings = { python = { pythonPath = get_python_executable_path() } } })
      autoenable({ "python" }, "pyright")

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(e: vim.AutocmdCallbackData): any
          plugins.apply_plugin_attach_keymaps("plugins.lsp", e.buf)

          local b = e.buf

          -- Neovim LSP defaults (vim/_defaults.lua).
          -- Install buffer-local mappings *only if unmapped* (never clobber external managers),
          -- and keep them documented in our keymap registry.

          -- LSP navigation / actions.
          keymaps.safemap_buf(b, "n", R.LSPGoto, "gi", "<Cmd>Telescope hierarchy incoming_calls<CR>", keymaps.opts("[LSP] incoming call hierarchy", { T.ActionView, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPGoto, "go", "<Cmd>Telescope hierarchy outgoing_calls<CR>", keymaps.opts("[LSP] outgoing call hierarchy", { T.ActionView, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPGoto, "d",  function(...: any): any select('#', ...) lsp.buf.definition() end,       keymaps.opts("[LSP] Goto definition",       { T.ActionView,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPGoto, "D",  function(...: any): any select('#', ...) lsp.buf.declaration() end,      keymaps.opts("[LSP] Goto declaration",      { T.ActionView,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPGoto, "i",  function(...: any): any select('#', ...) lsp.buf.implementation() end,   keymaps.opts("[LSP] Goto implementation",   { T.ActionNavigate, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPInfo, "rr", function(...: any): any select('#', ...) lsp.buf.references() end,       keymaps.opts("[LSP] References",            { T.ActionList,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPGoto, "rt", function(...: any): any select('#', ...) lsp.buf.type_definition() end,  keymaps.opts("[LSP] Goto type definition",  { T.ActionView,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPEdit, "rn", function(...: any): any select('#', ...) lsp.buf.rename() end,           keymaps.opts("[LSP] Rename symbol",         { T.ActionEdit,     T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.LSPEdit, "ra", function(...: any): any select('#', ...) lsp.buf.code_action() end,      keymaps.opts("[LSP] code action",           { T.ActionEdit,     T.TargetBuffer }))

          -- Back-compat (common defaults): only in LSP-attached buffers.
          keymaps.safemap_buf(b, "n", R.Naked, "grn", function(...: any): any select('#', ...) lsp.buf.rename() end,           keymaps.opts("[LSP] Rename",              { T.ActionEdit, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "n", R.Naked, "gra", function(...: any): any select('#', ...) lsp.buf.code_action() end,      keymaps.opts("[LSP] Code action",         { T.ActionEdit, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "x", R.Naked, "gra", function(...: any): any select('#', ...) lsp.buf.code_action() end,      keymaps.opts("[LSP] Code action",         { T.ActionEdit, T.TargetBuffer, T.Compat }))

          keymaps.safemap_buf(b, "n", R.Naked, "grD", function(...: any): any select('#', ...) lsp.buf.declaration() end,      keymaps.opts("[LSP] Goto declaration",    { T.ActionView, T.TargetBuffer, T.Compat }))

          keymaps.safemap_buf(b, "n", R.Naked, "grr", "<Cmd>Telescope lsp_references<CR>",       keymaps.opts("[LSP] References",       { T.ActionList, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "n", R.Naked, "gri", "<Cmd>Telescope lsp_implementations<CR>",  keymaps.opts("[LSP] Implementations",  { T.ActionView, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "n", R.Naked, "grd", "<Cmd>Telescope lsp_definitions<CR>",      keymaps.opts("[LSP] Definitions",      { T.ActionView, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "n", R.Naked, "grt", "<Cmd>Telescope lsp_type_definitions<CR>", keymaps.opts("[LSP] Type definitions", { T.ActionView, T.TargetBuffer, T.Compat }))

          keymaps.safemap_buf(b, "n", R.Naked, "gO", "<Cmd>Telescope lsp_document_symbols<CR>",           keymaps.opts("[LSP] Document symbols",  { T.ActionView, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "n", R.Naked, "gW", "<Cmd>Telescope lsp_dynamic_workspace_symbols<CR>",  keymaps.opts("[LSP] Workspace symbols", { T.ActionView, T.TargetWorkspace, T.Compat }))

          -- LSP info/help.
          keymaps.docmap_buf(b, "n", "K",  keymaps.opts("[LSP] hover", { T.ActionHelp, T.TargetBuffer }))
          keymaps.docmap_buf(b, "i", "<C-x><C-o>", keymaps.opts("[LSP] omni-completion", { T.ActionEdit, T.TargetBuffer, T.Compat }))
          keymaps.safemap_buf(b, "n", R.Naked, "<C-k>", function(...: any): any select('#', ...) lsp.buf.signature_help() end,  keymaps.opts("[LSP] signature help",       { T.ActionHelp, T.TargetBuffer }))

          -- Diagnostics.
          keymaps.safemap_buf(b, "n", R.Go,    "l", function(...: any): any select('#', ...) vim.diagnostic.open_float({}) end,  keymaps.opts("[LSP] line diagnostics",        { T.ActionHelp, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Naked, "[d", function(...: any): any select('#', ...) vim.diagnostic.goto_prev({}) end,  keymaps.opts("[LSP] previous diagnostic",      { T.ActionView, T.TargetBuffer }))
          keymaps.safemap_buf(b, "n", R.Naked, "]d", function(...: any): any select('#', ...) vim.diagnostic.goto_next({}) end,  keymaps.opts("[LSP] next diagnostic",          { T.ActionView, T.TargetBuffer }))
        end,
      })

      -- Create an explicit diagnostic namespace (Neovim 0.11+ requires a real namespace id here).
      local DIAG_NS = vim.api.nvim_create_namespace("rakhsh.diagnostics")

      local diag: VimDiagnostic = vim.diagnostic as VimDiagnostic
      diag.config({
        underline = true,
        virtual_text = true,
        signs = true,
        severity_sort = true,
      }, DIAG_NS)

      vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#3a1f1f" })
      vim.api.nvim_set_hl(0, "DiagnosticLineWarn",  { bg = "#3a341f" })
      vim.api.nvim_set_hl(0, "DiagnosticLineInfo",  { bg = "#1f2a3a" })
      vim.api.nvim_set_hl(0, "DiagnosticLineHint",  { bg = "#1f2f2a" })

      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function(_: vim.AutocmdCallbackData): any
          vim.api.nvim_set_hl(0, "DiagnosticLineError", { bg = "#3a1f1f" })
          vim.api.nvim_set_hl(0, "DiagnosticLineWarn",  { bg = "#3a341f" })
          vim.api.nvim_set_hl(0, "DiagnosticLineInfo",  { bg = "#1f2a3a" })
          vim.api.nvim_set_hl(0, "DiagnosticLineHint",  { bg = "#1f2f2a" })
        end,
      })
    end,
  } as PluginSpec)

  local hierarchy_spec = ({
    "jmacadie/telescope-hierarchy.nvim",
    lazy = false,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local _mod = "telescope"
      local telescope = require(_mod) as t.telescope.Telescope

      -- Extension provides `:Telescope hierarchy incoming_calls|outgoing_calls`.
      pcall(function() telescope.load_extension("hierarchy") end)
    end,
  } as PluginSpec)

  return { lsp_spec, hierarchy_spec }
end

return M
