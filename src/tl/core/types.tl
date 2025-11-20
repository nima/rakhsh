--local type WindowOpts = {string: any}
--local type BufferOpts = {string: any}

local roles    = require("core.types.roles")
local tags     = require("core.types.tags")
local vimtypes = require("core.types.vim")
local plugins  = require("core.types.plugins")
local events   = require("core.types.events")

local M = {
  roles   = roles,
  tags    = tags,
  vim     = vimtypes,
  plugins = plugins,
  events  = events,
}

return M
