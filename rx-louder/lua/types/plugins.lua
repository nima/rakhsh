local roles = require("types.roles")
local tags = require("types.tags")




local KeymapEvent = {}
local KeymapEvents = {
   Attach = { id = "attach" },
   Cmd = { id = "cmd" },
   Lazy = { id = "lazy" },
   Immediate = { id = "immediate" },
}
setmetatable(KeymapEvents, { __newindex = function() error("Cannot add new values to KeymapEvents") end })

local PluginKeymap = {}








setmetatable(PluginKeymap, { __newindex = function() error("Cannot add new fields to PluginKeymap") end })

local PluginSpec = {}




local PluginModule = {}





local M = {
   PluginSpec = PluginSpec,
   PluginKeymap = PluginKeymap,
   PluginModule = PluginModule,
   KeymapEvent = KeymapEvent,
   KeymapEvents = KeymapEvents,
}

return M
