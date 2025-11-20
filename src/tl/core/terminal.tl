local u = require("core.utils")
local R = u.Roles
local T = u.Tags

local t = require("core.types")
global vim: t.vim.Vim

vim.api.nvim_create_autocmd("TermOpen", {
  callback = (function(ev: {string:any})
    local buf = ev.buf as integer
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].modifiable = false
    vim.cmd("setlocal nospell")
    vim.cmd("setlocal nobuflisted")
    vim.cmd("setlocal nonumber norelativenumber")
    vim.cmd("autocmd TermClose <buffer> ++nested silent! bwipeout!")
  end) as t.vim.VimCallback
})

--vim.keymap.set("n", "<Leader>z", ":terminal zsh<CR>", { silent = true })
--safemap: function(mode: string, role: t.roles.Role, key: string, rhs: any, opts: t.vim.VimMapOpts): nil
u.install_keymap("core.terminal", 
    { mode = "n", role = R.Power, key = "`1", rhs = ":terminal zsh<CR>a", "Terminal (zsh)",
    desc = "Zsh Terminal", tags = { T.ActionLaunch } } as t.plugins.PluginKeymap
)
u.install_keymap("core.terminal", 
    { mode = "n", role = R.Power, key = "`2", rhs = ":terminal bash<CR>a", "Terminal (bash)",
    desc = "Zsh Terminal", tags = { T.ActionLaunch } } as t.plugins.PluginKeymap
)
