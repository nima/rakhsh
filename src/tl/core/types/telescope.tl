-- Module minimal typedefs (only what we use)
local record PickersModule
  new: function(opts: any, spec: any): any
end

local record FindersModule
  new_table: function(opts: any): any
end

local record EntryDisplayModule
  create: function(opts: any): function(any): string
end

local record ConfigValues
  generic_sorter: function(opts: any): any
end

local record ConfigModule
  generic_sorter: function(opts: any): any
  values: ConfigValues
end

local record ActionsModule
  close: function(bufnr: integer): nil
end

local record ActionStateModule
  get_selected_entry: function(): any
end

local M = {
    Pickers      = PickersModule,
    Finders      = FindersModule,
    EntryDisplay = EntryDisplayModule,
    Config       = ConfigModule,
    Actions      = ActionsModule,
    ActionState  = ActionStateModule,
}

return M
