-- Module minimal typedefs (only what we use)
local record Pickers
  new: function(opts: any, spec: any): any
end

local record Finders
  new_table: function(opts: any): any
end

local record EntryDisplay
  create: function(opts: any): function(any): string
end

local record ConfigValues
  generic_sorter: function(opts: any): any
end

local record Config
  generic_sorter: function(opts: any): any
  values: ConfigValues
end

local record Actions
  close: function(bufnr: integer): nil
end

local record ActionState
  get_selected_entry: function(): any
end

local type TelescopeOpts = { string : any }

local record Telescope
  setup: function(TelescopeOpts | nil): nil
  load_extension: function(string): nil
end

local M = {
  Pickers       = Pickers,
  Finders       = Finders,
  EntryDisplay  = EntryDisplay,
  Config        = Config,
  Actions       = Actions,
  ActionState   = ActionState,
  Telescope     = Telescope,
  TelescopeOpts = TelescopeOpts,
}

return M
