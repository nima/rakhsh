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

local M = {
  languages = languages,
  filetypes = filetypes,
  colorschema = "default" -- "monokai", "elflord"
}

return M

