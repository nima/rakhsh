" vim: ft=vim
" cSpell: disable
set updatetime=300

"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Keybinding Guide -={
"- <ESC> + key         → editor toggles / modes (numbers, cursor crosshair, word highlight, etc.)
"- <Space> + key       → tools & commands (global)  [<leader>]
"- <Backslash> + key   → context-aware / language-aware / git / project ops
"- g{key}              → code / semantics / LSP-style motions (don’t break gd/gD/gi/gr)
"- ]{key} / [{key}     → “next / previous” family (diagnostics, git hunks, test failures, etc.)
"- <M-key>             → pure navigation (scrolling, window move, etc.)
"- <C-key>             → mostly reserved for Vim/built-ins/plugins
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Folds -={
filetype plugin indent on
set foldmethod=marker
set foldmarker=-={,}=-
set foldenable
nnoremap ; za
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Leader Hotkeys `<Leader>[0-9], <Leader>[r=]` -={
let mapleader=' '
set timeout "+ For <Leader>
set timeoutlen=500

nnoremap <Leader>8 :Maps!<CR>
nnoremap <Leader>9 :marks<CR>
nnoremap <Leader>0 :registers<CR>
nnoremap <Leader>2 :History<CR>
nnoremap <Leader>3 :History:<CR>
nnoremap <Leader>4 :History/<CR>

" Search in files
nnoremap <Leader>r :Rg<CR>

" Misc
nnoremap <Leader>= mzgg=G`z

set ttimeout "+ For <ESC>
set ttimeoutlen=100
"= }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Trailing Whites `<Leader>w` -={
highlight ExtraWhitespace ctermbg=Red guibg=Red
match ExtraWhitespace /\s\+$/
augroup TrailingWhitespace
  autocmd!
  autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
  autocmd InsertLeave * match ExtraWhitespace /\s\+$/
  autocmd BufWinLeave * match none
augroup END
nnoremap <Leader>w mz:%s/\s\+$//e<CR>`z
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Navigation (Control) -={

" Full-screen horizontal scroll
inoremap <M-Left>  <C-o>ze
nnoremap <M-Left>  ze
vnoremap <M-Left>  ze

inoremap <M-Right> <C-o>zs
nnoremap <M-Right> zs
vnoremap <M-Right> zs

" Half-screen vertical scroll
inoremap <M-Up>    <C-o>4<C-y>
nnoremap <M-Up>    4<C-y>
vnoremap <M-Up>    4<C-y>

inoremap <M-Down>  <C-o>4<C-e>
nnoremap <M-Down>  4<C-e>
vnoremap <M-Down>  4<C-e>
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Navigation (Observer) -={

"+ Line Numbers
function! ToggleNumbers()
	if !&number && !&relativenumber
		" none -> absolute
		set number
		set norelativenumber
	elseif &number && !&relativenumber
		" absolute -> absolute + relative
		set relativenumber
	else
		" (number && relativenumber) or (only relative) -> none
		set nonumber
		set norelativenumber
	endif
endfunction
nnoremap <ESC>n :call ToggleNumbers()<CR>

"+ Crosshairs
function! CycleCursorModes()
	if &cursorline && &cursorcolumn
		" H+V → H
		set nocursorcolumn
	elseif &cursorline && !&cursorcolumn
		" H → V
		set nocursorline
		set cursorcolumn
	elseif !&cursorline && &cursorcolumn
		" V → None
		set nocursorline
		set nocursorcolumn
	else
		" None → H+V
		set cursorline
		set cursorcolumn
	endif
endfunction
nnoremap <ESC>. :call CycleCursorModes()<CR>
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Colors (NoHotKeys) -={
set t_Co=256
set termguicolors
set background=dark
colorscheme elflord
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Feedback (NoHotKeys) -={
set noeb " disable error bells
set visualbell " use visual flash instead of a sound
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Indents (NoHotKeys) -={
autocmd FileType sh setlocal et ts=2 sw=2
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Save State (NoHotKeys) -={
"+ Remember where you were; Save & Load cursor position
autocmd BufReadPost * if line("'\"") | execute 'normal! g`"' | endif
autocmd BufWinLeave *.* silent! mkview
autocmd BufWinEnter *.* silent! loadview
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Status Bar (NoHotKeys) -={
": git clone --depth=1 https://github.com/itchyny/lightline.vim  ~/.vim/pack/plugins/start/lightline"
set laststatus=2 "+ always show statusline
set showcmd
set noshowmode   "+ don't show `-- INSERT --` (lightline handles it)
let g:lightline = {
  \'colorscheme': 'wombat',
  \'active': {'left': [['mode', 'paste'], ['readonly', 'filename', 'modified']] },
  \'inactive': { 'left': [ [ 'filename' ] ], 'right': [ ] },
  \'component_function': {},
\}
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Search `<ESC><ESC>` -={
set hlsearch
set incsearch
nnoremap <ESC><ESC> :let @/ = ''<CR>

augroup SearchColorOverrides
	autocmd!
	autocmd ColorScheme * highlight Search    cterm=underline      ctermfg=208 ctermbg=NONE gui=underline      guifg=#ffaf00 guibg=NONE
	autocmd ColorScheme * highlight CurSearch cterm=bold,underline ctermfg=208 ctermbg=NONE gui=bold,underline guifg=#ffaf00 guibg=NONE
	autocmd ColorScheme * highlight IncSearch cterm=NONE           ctermfg=0   ctermbg=208 gui=NONE           guifg=#000000 guibg=#ffaf00
augroup END
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Words `<ESC>w, <ESC>h` -={
autocmd FileType sh setlocal iskeyword+=-
autocmd FileType markdown setlocal iskeyword+=-

"+ Cursor Word
let g:cursorword_strict = 1
function! ToggleCursorWordBoundaries() abort
	let g:cursorword_strict = !get(g:, 'cursorword_strict', 1)
	echo g:cursorword_strict ? 'CursorWord: Whole' : 'CursorWord: Partial'
endfunction
nnoremap <ESC>w :call ToggleCursorWordBoundaries()<CR>

let s:word_hl_timer = -1

function! s:ScheduleWordHighlight() abort
	if s:word_hl_timer != -1
		call timer_stop(s:word_hl_timer)
	endif
	" Run 200ms after the *last* cursor move
	let s:word_hl_timer = timer_start(200, {-> s:UpdateWordHighlight()})
endfunction

function! s:UpdateWordHighlight() abort
	" clear previous match
	if exists('w:cursorword_id')
		silent! call matchdelete(w:cursorword_id)
		unlet w:cursorword_id
	endif

	let l:word = expand('<cword>')
	if empty(l:word) | return | endif

	if get(g:, 'cursorword_strict', 0)
		let l:pat = '\V\<'.escape(l:word, '\').'\>'
	else
		let l:pat = '\V'.escape(l:word, '\')
	endif
	let w:cursorword_id = matchadd('CursorWord', l:pat, 10)
endfunction

augroup WordHighlight
	autocmd!
	autocmd CursorMoved,CursorMovedI * call s:ScheduleWordHighlight()
augroup END

let g:cursorwordhighlight = !get(g:, 'cursorwordhighlight', 1)
highlight clear CursorWord
highlight CursorWord cterm=bold,underline gui=bold,underline guifg=NONE guibg=NONE
function! ToggleCursorWordHighlight() abort
	highlight clear CursorWord
	let g:cursorwordhighlight = !get(g:, 'cursorwordhighlight', 0)
	echo g:cursorwordhighlight ? 'CursorWordHighlight: ON' : 'CursorWordHighlight: OFF'
	if get(g:, 'cursorwordhighlight', 0)
		highlight CursorWord cterm=bold,underline gui=bold,underline guifg=NONE guibg=NONE
		set eventignore-=CursorMoved
	else
		set eventignore+=CursorMoved
	endif
endfunction
nnoremap <ESC>h :call ToggleCursorWordHighlight()<CR>
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= FZF `<C-f>, <Leader>f*, \f*` -={
": git clone --depth=1 https://github.com/junegunn/fzf.vim ~/.vim/pack/plugins/start/fzf.vim
": git clone --depth=1 https://github.com/junegunn/fzf /opt/github/fzf
set rtp+=/opt/github/fzf

" An action can be a reference to a function that processes selected lines
function! s:build_quickfix_list(lines)
	call setqflist(map(copy(a:lines), '{ "filename": v:val, "lnum": 1 }'))
	copen
	cc
endfunction

let g:fzf_action = {
	\'ctrl-q': function('s:build_quickfix_list'),
	\'ctrl-t': 'tab split',
	\'ctrl-x': 'split',
	\'ctrl-v': 'vsplit'
\}

": git clone https://github.com/tpope/vim-fugitive ~/.vim/pack/plugins/start/vim-fugitive
function! FzfGitGrep()
	let pat = input('Pattern: ')
	if !empty(pat)
		call fzf#vim#grep('git grep -n ' . shellescape(pat), 1, fzf#vim#with_preview())
	endif
endfunction

"+ Search for files
nnoremap <C-f> :FZF --multi --layout=reverse-list --info=inline --pointer=→ --marker=♡<CR>

nnoremap <Leader>ff :Files!<CR>
nnoremap <Leader>fb :Buffers<CR>
nnoremap <Leader>f` :Tags<CR>
nnoremap <Leader>f1 :BTags<CR>
"nnoremap <silent><C-\> :Tags <C-r><C-w><CR>

"+ Search in files in Git
nnoremap \fg :GFiles<CR>
nnoremap \fz :call FzfGitGrep()<CR>
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= TableMode `\t, \r` -={
": git clone https://github.com/Kicamon/markdown-table-mode.nvim.git
nnoremap \t :TableModeToggle<CR>
nnoremap \r :TableModeRealign<CR>
"nmap <Leader>tic :call tablemode#InsertColumnAfter(v:count)<CR>
"nmap <Leader>tiC :call tablemode#InsertColumnBefore(v:count)<CR>
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Debug files with shit characters -={
"set list
"set listchars=tab:'▸'
"set listchars=trail:·
"set listchars=eol:¶
"set listchars=nbsp:·
"set listchars=precedes:«
"set listchars=extends:»
"highlight nonascii ctermbg=red guibg=red
"au BufReadPost * syntax match nonascii "[^\x00-\x7F]"
":echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
":verbose autocmd Syntax *
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Programming <C-k> -={
syntax on

set noexpandtab
set tabstop=4
set shiftwidth=4
set nowrap
set autoindent
set textwidth=120

"+ C++
autocmd FileType cpp setlocal cindent cinoptions=g0,h2,t0 shiftwidth=4 tabstop=4 expandtab
let g:ctrlp_custom_ignore = { 'dir':  'extern\|build$', }

" https://clang.llvm.org/docs/ClangFormat.html#vim-integration
if has('python')
	nnoremap <C-K> :pyf /opt/homebrew/Cellar/clang-format/21.1.5/share/clang/clang-format.py<cr>
	xnoremap <C-K> :pyf /opt/homebrew/Cellar/clang-format/21.1.5/share/clang/clang-format.py<cr>
	imap <C-K> <c-o>:pyf /opt/homebrew/Cellar/clang-format/21.1.5/share/clang/clang-format.py<cr>
elseif has('python3')
	nnoremap <C-K> :py3f /opt/homebrew/Cellar/clang-format/21.1.5/share/clang/clang-format.py<cr>
	xnoremap <C-K> :py3f /opt/homebrew/Cellar/clang-format/21.1.5/share/clang/clang-format.py<cr>
	imap <C-K> <c-o>:py3f /opt/homebrew/Cellar/clang-format/21.1.5/share/clang/clang-format.py<cr>
endif
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Comments (NoHotKeys) -={

"= Titles
"+ Explanatory
": Staged/Command
"? Reasoning
"< Upstream
"> Downstream
"& Examples
"! Attention
"- Notice
"@ Reference
"$ Cost
"% ONotation
"~ Deprecation

highlight default CommentTagTitle        ctermfg=222 gui=bold          guifg=#FFDE9E
highlight default CommentTagExplanatory  ctermfg=75  gui=none          guifg=#3EA8FF
highlight default CommentTagStaged       ctermfg=205 gui=none          guifg=#FC59A3
highlight default CommentTagReasoning    ctermfg=255 gui=none          guifg=#FFFFFF
highlight default CommentTagUpstream     ctermfg=209 gui=none          guifg=#FF7F50
highlight default CommentTagDownstream   ctermfg=214 gui=none          guifg=#FF9F1C
highlight default CommentTagExamples     ctermfg=113 gui=none          guifg=#87C830
highlight default CommentTagAttention    ctermfg=203 gui=none          guifg=#FF3366
highlight default CommentTagNotice       ctermfg=221 gui=none          guifg=#FFD23F
highlight default CommentTagReference    ctermfg=44  gui=italic        guifg=#00CEC9
highlight default CommentTagCost         ctermfg=214 gui=none          guifg=#FFA600
highlight default CommentTagONotation    ctermfg=203 gui=none          guifg=#FF6F61
highlight default CommentTagDeprecation  ctermfg=196 gui=strikethrough guifg=#FF3333

"+ Dynamic comment tags for any filetype with a sane 'commentstring'
function! CommentTagsSetup() abort
	" Need something concrete, like "// %s", "# %s", "-- %s", "/* %s */", etc.
	if &commentstring ==# '' || &commentstring !~ '%s' | return | endif

	let l:cs  = &commentstring
	let l:idx = stridx(l:cs, '%s')
	if l:idx < 0 | return | endif

	" Leader is everything before %s, strip trailing spaces
	let l:leader = strpart(l:cs, 0, l:idx)
	let l:leader = substitute(l:leader, '\s\+$', '', '')
	if l:leader ==# '' | return | endif

	" Escape for use in a \v pattern and anchor at the leader
	let l:leader_esc = escape(l:leader, '\/.^$~[]*')
	let l:prefix     = '\v' . l:leader_esc

	let l:container = 'Comment'
	if &filetype ==# 'vim'
		let l:container = 'vimLineComment,vimComment'
	elseif &filetype ==# 'cpp' || &filetype ==# 'c'
		let l:container = 'cComment,cCppComment'
	elseif &filetype ==# 'python'
		let l:container = 'pythonComment'
	elseif &filetype ==# 'sh' || &filetype ==# 'bash' || &filetype ==# 'zsh'
		let l:container = 'shComment'
	endif

	" One leader, different tag chars; all restricted to comments
	execute 'syntax match CommentTagTitle       /' . l:prefix . '\=\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagExplanatory /' . l:prefix . '\+\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagStaged      /' . l:prefix . '\:\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagReasoning   /' . l:prefix . '\?\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagUpstream    /' . l:prefix . '\<\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagDownstream  /' . l:prefix . '\>\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagExamples    /' . l:prefix . '\&\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagAttention   /' . l:prefix . '\!\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagNotice      /' . l:prefix . '\-\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagReference   /' . l:prefix . '\@\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagCost        /' . l:prefix . '\$\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagONotation   /' . l:prefix . '\%\s.*$/  containedin=' . l:container
	execute 'syntax match CommentTagDeprecation /' . l:prefix . '\~\s.*$/  containedin=' . l:container
endfunction

augroup CommentTags
	autocmd!
	autocmd FileType * call CommentTagsSetup()
augroup END
" }=-
"= """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"= Fold Special Marker Colors (NoHotKeys) -={
highlight default FoldMarkerRed ctermfg=196 guifg=#ff0000 gui=bold
augroup FoldMarkerRed
  autocmd!
  autocmd Syntax * syntax match FoldMarkerRed /\V-={/ containedin=ALL
  autocmd Syntax * syntax match FoldMarkerRed /\V}=-/ containedin=ALL
augroup END
" }=-
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" WordWrap
"function! WrapWordWithAngleBrackets()
"	let l:word = expand('<cword>')
"	execute 'normal! "_diwi<' . l:word . '>'
"endfunction
"nnoremap <Leader>w :call WrapWordWithAngleBrackets()<CR>
