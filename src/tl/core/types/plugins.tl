local roles = require("core.types.roles")
local tags  = require("core.types.tags")

local type Role = roles.Role
local type Tag  = tags.Tag

local record KeymapOn _tag: string end
local KeymapEvents: { string : KeymapOn } = {
  Attach    = { _tag = "attach" },
  Cmd       = { _tag = "cmd" },
  Lazy      = { _tag = "lazy" },
  Immediate = { _tag = "immediate" },
}
setmetatable(KeymapEvents, { __newindex = function() error("Cannot add new enum values to KeymapEvents") end })

local record PluginKeymap
  mode: string
  role: Role
  key:  string
  rhs:  any
  desc: string
  tags: { Tag }
  on:   KeymapOn | nil
end
setmetatable(PluginKeymap, { __newindex = function() error("Cannot add new enum values to PluginKeymap") end })

local record PluginSpec
  repo: string                -- the plugin name / repo
  lazy: boolean | nil
  keymaps: { PluginKeymap } | nil
end
local record KeymapSpec
  keymaps: { PluginKeymap }
end
local record PluginModule
  init: function(): nil
  lazy: function(): PluginSpec
end

local M = {
  PluginSpec   = PluginSpec,
  PluginKeymap = PluginKeymap,
  PluginModule = PluginModule,
  KeymapOn     = KeymapOn,
  KeymapEvents = KeymapEvents,
  KeymapSpec   = KeymapSpec,
}

return M
