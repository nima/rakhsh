local roles     = require("core.types.roles")
local tags      = require("core.types.tags")
local vim       = require("core.types.vim")
local plugins   = require("core.types.plugins")
local events    = require("core.types.events")
local telescope = require("core.types.telescope")

local M = {
  roles     = roles,
  tags      = tags,
  vim       = vim,
  plugins   = plugins,
  events    = events,
  telescope = telescope,
}

return M
