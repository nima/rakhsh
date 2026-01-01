local roles = require("types.roles")
local tags  = require("types.tags")

local type Role = roles.Role
local type Tag  = tags.Tag

local record KeymapEvent id: string end
local KeymapEvents: { string : KeymapEvent } = {
  Attach    = { id = "attach" },
  Cmd       = { id = "cmd" },
  Lazy      = { id = "lazy" },
  Immediate = { id = "immediate" },
}
setmetatable(KeymapEvents, { __newindex = function() error("Cannot add new values to KeymapEvents") end })

local record PluginKeymap
  mode: string
  path: string
  role: Role
  key:  string
  rhs:  any
  desc: string
  tags: { Tag }
  on:   KeymapEvent
end
setmetatable(PluginKeymap, { __newindex = function() error("Cannot add new fields to PluginKeymap") end })

local record PluginSpec
  repo: string
  lazy: boolean | nil
end

local record PluginModule
  init: function(): nil
  lazy: function(): { PluginSpec }
  keymaps: function(): { PluginKeymap }
end

local M = {
  PluginSpec   = PluginSpec,
  PluginKeymap = PluginKeymap,
  PluginModule = PluginModule,
  KeymapEvent  = KeymapEvent,
  KeymapEvents = KeymapEvents,
}

return M
