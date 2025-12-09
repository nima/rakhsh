local roles = require("core.types.roles")
local tags  = require("core.types.tags")

local type Role = roles.Role
local type Tag  = tags.Tag

local record KeymapOn evid: string end
local KeymapEvents: { string : KeymapOn } = {
  Attach    = { evid = "attach" },
  Cmd       = { evid = "cmd" },
  Lazy      = { evid = "lazy" },
  Immediate = { evid = "immediate" },
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
  repo: string
  lazy: boolean | nil
  keymaps: { PluginKeymap } | nil
end
local record KeymapSpec
  keymaps: { PluginKeymap }
end
local record KeymapModule
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
  KeymapModule = KeymapModule,
}

return M
