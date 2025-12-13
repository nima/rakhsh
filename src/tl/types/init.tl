local roles     = require("types.roles")
local tags      = require("types.tags")
local vim       = require("types.vim")
local plugins   = require("types.plugins")
local events    = require("types.events")
local telescope = require("types.telescope")

local M = {
  roles     = roles,
  tags      = tags,
  vim       = vim,
  plugins   = plugins,
  events    = events,
  telescope = telescope,
}

return M
