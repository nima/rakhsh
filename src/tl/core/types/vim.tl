--= Layer 0

local record Vim
  api: VimApi
  fn: VimFn
  keymap: VimKeymap
  loop: VimLoop
  opt: VimOptRuntime
  o: VimOptGlobal
  wo: VimWo
  g: VimGlobal
  opt_local: VimOptLocal
  bo: {VimBo}
  cmd: VimCmd
  lsp: VimLSP
  log: VimLog
  env: VimEnv
  diagnostic: VimDiagnostic
  tbl_extend: function(behavior: string, dst: {string:any}, src: {string:any}...): {string:any}
  notify: function(msg: string, level: any | nil, opts: { string: any } | nil | nil...): any
  pesc: function(str: string): string
  schedule: function(callback: function): nil
  defer_fn: function(callback: function, delay: integer): nil
  treesitter: VimTreesitter
  --- add optional lua-level split if desired
  split: function(str: string, sep: string, opts: VimSplitOpts | nil): {string}
end

--= Layer 1

local record VimSplitOpts
  plain: boolean
end

local record VimExec2Result
  output: string
end

local record VimFn
  argc: function(): integer
  maparg: function(lhs: string, mode: string, abbr: boolean, dict: boolean): any
  stdpath: function(kind: string): string
  system: function(cmd: {string}): string
  expand: function(expr: string): string
  escape: function(str: string, chars: string): string
  fnamemodify: function(fname: string, mods: string): string
  matchadd: function(group: string, pattern: string, priority: integer | nil, id: integer | nil): integer
  matchdelete: function(id: integer): integer
  has: function(string): integer
  serverstart: function(string): any
  reg_recording: function(): string
  reg_executing: function(): string
  getreg: function(string): any
  getpos: function(string): {integer}
  getbufinfo: function(opts: any | nil): { VimBufInfo }
  winbufnr: function(win: number): integer
  win_findbuf: function(bufnr: integer): { integer }
  line: function(expr: string): integer
  foldlevel: function(lnum: integer): integer
  readfile: function(fname: string): {string}
  writefile: function(lines: {string}, fname: string): any
  mkdir: function(path: string, mode: string): any
  clearmatches: function(): any
  jobstart: function(cmd: {string} | string, opts: {string: any}): integer
  hlexists: function(name: string): integer
  split: function(str: string, sep: string, opts: VimSplitOpts | nil): {string}
end

local record VimApi
  nvim_set_hl: function(ns_id: integer, name: string, opts: { string: any }): nil
  nvim_create_autocmd: function(events: {string} | string, opts: VimAutocmdOpts): integer
  nvim_buf_get_keymap: function(bufnr: integer, mode: string): { VimRawMapInfo }
  nvim_buf_get_name: function(bufnr: integer): string
  nvim_list_uis: function(): {NvimUI}
  nvim_create_buf: function(listed: boolean, scratch: boolean): integer
  nvim_buf_line_count: function(bufnr: integer): integer
  nvim_buf_get_lines: function(bufnr: integer, start: integer, stop: integer, strict_indexing: boolean): {string}
  nvim_buf_set_lines: function(bufnr: integer, start: integer, stop: integer, strict_indexing: boolean, replacement: {string}): nil
  nvim_buf_set_extmark: function(bufnr: integer, ns_id: integer, line: integer, col: integer, opts: {string:any}): integer
  nvim_win_set_cursor: function(win: integer, pos: VimCursorPosition): nil
  nvim_buf_get_mark: function(bufnr: integer, mark: string): VimCursorPosition
  nvim_win_get_cursor: function(win: integer): VimCursorPosition
  nvim_buf_get_option: function(bufnr: integer, name: string): any
  nvim_buf_is_loaded: function(bufnr: integer): boolean
  nvim_create_namespace: function(name: string): integer
  nvim_create_augroup: function(name: string, opts: {string:any}): integer
  nvim_buf_clear_namespace: function(bufnr: integer, ns_id: integer, line_start: integer, line_end: integer): nil
  nvim_get_current_buf: function(): integer
  nvim_exec2: function(cmd: string, opts: {string:any}): VimExec2Result
  nvim_set_option_value: function(name: string, value: any, opts: {string:any}): nil
  nvim_open_win: function(bufnr: integer, enter: boolean, opts: {string:any}): integer
  nvim_win_close: function(win: integer, force: boolean): nil
  nvim_win_is_valid: function(win: integer): boolean
  nvim_create_user_command: function(name: string, command: VimCallback | string, opts: {string:any}): nil
  nvim_buf_is_valid: function(bufnr: integer): boolean
  nvim_get_current_win: function(): integer
  nvim_win_get_width: function(win: integer): integer
  nvim_win_get_height: function(win: integer): integer
end

local record VimBo
  filetype: string
  bufnr: integer
  buftype: string
  bufhidden: string
  commentstring: string
  bufmodified: boolean
  expandtab: boolean
  shiftwidth: integer
  tabstop: integer
  softtabstop: integer
  modifiable: boolean
  cindent: boolean
  cinoptions: string
  modified: boolean
  swapfile: boolean
end

local record VimTreesitter
  get_parser: function(bufnr: integer, lang: string | nil, opts: any | nil): any
  language: VimTreesitterLanguage
end

local record VimKeymap
  set: function(mode: string | {string}, lhs: string, rhs: any, opts: VimMapOpts): nil
  get: function(mode: string | {string}, lhs: string, opts: any | nil): { VimRawMapInfo }
end

--= Layers 3+

local record VimMapOpts
  noremap: boolean
  silent: boolean
  desc: string
  buffer: integer
  nowait: boolean | nil
end

local record VimMapInfo
  lhs: string
  rhs: any
  script: string
  lnum: integer
end

local record VimBufInfo
  bufnr: integer
end

local record VimOptionList
  append: function(self: VimOptionList, value: string): nil
  remove: function(self: VimOptionList, value: string): nil
end

local record VimOptLocal
  formatoptions: any
  iskeyword: VimOptionList
end

local record VimOptGlobal
  number: boolean
  relativenumber: boolean
  termguicolors: boolean
  numberwidth: integer
  signcolumn: string
  clipboard: string
  mouse: string
  laststatus: integer
  showmode: boolean
  cmdheight: integer
  updatetime: integer
  viewoptions: string
  viewdir: string
  more: boolean
  columns: integer
  lines: integer
end

local record VimLoop
  fs_stat: function(path: string): any | nil
end

local record VimOptRuntimeRtp
  prepend: function(self: any, path: string): nil
end

local record VimViewOptions
  append: function(self: VimViewOptions, value: string): nil
end

local record VimOptRuntime
  rtp: VimOptRuntimeRtp
  modeline: boolean
  modelines: integer
  modelineexpr: boolean
  viewoptions: VimViewOptions
  scrolloff: integer
  wrap: boolean
  shortmess: VimOptionList
end

local type VimCallback = function(ev: {string:any} | nil)

local record VimAutocmdEvent
  buf: integer
  match: string
end

local record VimAutocmdOpts
  once: boolean | nil
  callback: VimCallback
  buffer: integer | nil
  command: string | nil
  group: integer | nil
  pattern: string | {string} | nil
end

local type VimCmd = function(string): nil

local record VimLSPProtocol
  make_client_capabilities: function(): any
end

local record VimLSPBuf
  definition: function(): nil
  declaration: function(): nil
  implementation: function(): nil
  references: function(): nil
  hover: function(): nil
  signature_help: function(): nil
  rename: function(): nil
  code_action: function(): nil
  format: function(opts: any | nil): nil
  type_definition: function(): nil
end

local record VimLSPClient
  name: string
end

local record VimLSPClientFilter
  id: integer | nil
  bufnr: integer | nil
  name: string | nil
end

local record LSPUtil
  get_progress_messages: function(): {any}
end

local record VimLSP
  protocol: VimLSPProtocol
  config: function(server: string, opts: any): nil
  enable: function(servers: {string}): nil
  get_clients: function(filters: VimLSPClientFilter | nil): { VimLSPClient }
  buf: VimLSPBuf
  util: LSPUtil
end

local record VimDiagnostic
  open_float: function(): nil
  goto_prev: function(opts: any | nil): nil
  goto_next: function(opts: any | nil): nil
  setloclist: function(): nil
end

local record NvimUI
  chan: integer
  width: integer
  height: integer
  rgb: boolean
  ext_popupmenu: boolean
end

local type VimCursorPosition = { integer, integer }
local type VimCursorPositions = {string: VimCursorPosition }

local record VimRawMapInfo
  lhs: string
  rhs: any
  script: string
  lnum: integer
  desc: string
  callback: function | nil
end

local record VimWo
  number: boolean
  relativenumber: boolean
  cursorline: boolean
  cursorcolumn: boolean
  foldmethod: string
  signcolumn: string
  foldcolumn: string
  list: boolean
end

local record VimGlobal
  mapleader: string
  colorscheme: string | nil
  string: any
  pos: VimCursorPositions
  loaded_matchit: integer | nil
end

local record VimLogLevels
  TRACE: integer
  DEBUG: integer
  INFO: integer
  WARN: integer
  ERROR: integer
end

local record VimTreesitterLanguage
  register: function(lang: string, ft: string): nil
  get_lang: function(ft: string): string
end

local record VimLog
  levels: VimLogLevels
end

local record VimEnv
  OPENAI_API_KEY: string | nil
end

local record VimNotify
  notify: function(msg: string, level: integer | nil, opts: any): nil
end

local type AnyFunction = function(...: any): any

local M = {
  VimMapOpts          = VimMapOpts,
  VimMapInfo          = VimMapInfo,
  VimBufInfo          = VimBufInfo,
  VimFn               = VimFn,
  VimKeymap           = VimKeymap,
  VimLoop             = VimLoop,
  VimOptLocal         = VimOptLocal,
  VimOptGlobal        = VimOptGlobal,
  VimOptRuntime       = VimOptRuntime,
  VimOptRuntimeRtp    = VimOptRuntimeRtp,
  VimCmd              = VimCmd,
  VimLSPProtocol      = VimLSPProtocol,
  VimLSPBuf           = VimLSPBuf,
  VimLSP              = VimLSP,
  VimDiagnostic       = VimDiagnostic,
  VimCallback         = VimCallback,
  VimAutocmdOpts      = VimAutocmdOpts,
  VimApi              = VimApi,
  Vim                 = Vim,
  VimNotify           = VimNotify,
  VimEnv              = VimEnv,
  VimLog              = VimLog,
  VimRawMapInfo       = VimRawMapInfo,
  VimLSPClientFilter  = VimLSPClientFilter,
  VimAutocmdEvent     = VimAutocmdEvent,
  VimCursorPosition   = VimCursorPosition,
  VimCursorPositions  = VimCursorPositions,
  VimWo               = VimWo,
  AnyFunction         = AnyFunction,
}

return M
