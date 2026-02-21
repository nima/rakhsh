local languages: { string: boolean } = {
  c      = true,
  cpp    = true,
  python = true,
  go     = true,
  lua    = true,
  bash   = true,
}

local function filetypes(): {string}
  local out = {} as {string}
  for name, enabled in pairs(languages) do
    if enabled then table.insert(out, name) end
  end
  return out
end


local record VimWithTs
  treesitter: Ts | nil
end

-- Neovim built-in Tree-sitter API (not a plugin/module you `require`).
-- Our teal-types externs don't declare `vim.treesitter`, so we add a tiny local type.
local record Ts
  start: function(buf: integer): nil
end

vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev: vim.AutocmdCallbackData): nil
    -- Only attach to normal file buffers.
    if (vim.api.nvim_get_option_value("buftype", { buf = ev.buf }) as string) ~= "" then return end

    -- Access built-in `vim.treesitter` via a typed cast (no `any`).
    local ts = (vim as VimWithTs).treesitter
    if ts == nil then return end

    -- Teal: narrowing doesn't flow into closures; capture as non-nil.
    local ts0 = (ts as Ts)

    -- Neovim 0.10+: highlighter doesn't auto-start; do it explicitly.
    pcall(function(): nil
      ts0.start(ev.buf)
    end)
  end,
})

local M = {
  languages = languages,
  filetypes = filetypes,
  colorschema = "monokai", -- "default", "elflord"
  scrolloff = 5,
}

return M
