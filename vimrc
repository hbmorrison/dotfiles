" install plugins
call plug#begin()
Plug 'airblade/vim-gitgutter'
Plug 'airblade/vim-rooter'
Plug 'godlygeek/tabular'
Plug 'kien/ctrlp.vim'
Plug 'ojroques/vim-oscyank'
Plug 'pedrohdz/vim-yaml-folds'
Plug 'puppetlabs/puppet-syntax-vim'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-vinegar'
call plug#end()

" enable syntax highlighting and indenting
syntax on
filetype plugin indent on

" autoformat comments by default
set textwidth=80
set formatoptions=croqj/
set nojoinspaces

" make sure the formatoptions are applied to new buffers properly
autocmd BufRead,BufNewFile * setlocal formatoptions=croqj/

" enable search highlighting and clear with return
set hlsearch
nnoremap <silent> <cr> :let @/ = ""<cr><cr>

" set encoding and colour range for modern terminals
set encoding=utf8
set t_Co=256

" set sensible values for the viminfo file
set nocompatible
set viminfo='20,<500,/50,:50,h

" shorten warning messages and hide startup banner
set shortmess=aI

" set leader key
let mapleader=","

" enable line numbers
set number
set cursorline

" disable bell
set visualbell
set t_vb=

" convert tabs to two spaces
set softtabstop=2
set shiftwidth=2
set smarttab
set expandtab

" use shift-tab to insert a literal tab character
inoremap <s-tab> <c-q><tab>

" mark tabs and trailing whitepace
set listchars=tab:▸·,trail:×
set list

" turn off trailing whitespace mark in insert mode
autocmd InsertEnter * setlocal listchars=tab:▸·
autocmd InsertLeave * setlocal listchars=tab:▸·,trail:×

" enable mouse
set mouse=nv

" toggle the expanded paste mode for mouse selections
nnoremap <silent> <leader>v :call TogglePastemode()<cr>

" use space to fold, unfold and set a visual fold
nnoremap <silent> <space> @=(foldlevel('.')?'za':"\<space>")<cr>
vnoremap <space> zf

" set tab completion menu
set wildmenu
set wildignorecase
set wildignore+=*.so,*.swp,*.zip
set wildmode=longest:full,full
set wildcharm=<tab>
set path=.,**

" set the status line
let g:space = ' '
set laststatus=2
set statusline=
set statusline+=%{get(b:,'git_branch','')}
set statusline+=%{g:space}
set statusline+=%t
set statusline+=%{g:space}
set statusline+=%{&ff}
set statusline+=%{g:space}
set statusline+=[%{&fileencoding?&fileencoding:&encoding}]
set statusline+=%{&paste?'\ [paste]':''}
set statusline+=%{g:space}
set statusline+=%m%r%h
set statusline+=%=
set statusline+=%<%{get(b:,'git_root','')}
set statusline+=%{g:space}
set statusline+=%c
set statusline+=%{g:space}

" set highlighting common to light and dark backgrounds
highlight Constant term=NONE cterm=NONE ctermfg=37
highlight Noise term=NONE cterm=NONE ctermfg=245
highlight NonText term=NONE cterm=NONE ctermfg=203
highlight Number term=NONE cterm=NONE ctermfg=37
highlight SpecialKey term=NONE cterm=NONE ctermfg=203
highlight Special term=NONE cterm=NONE ctermfg=245
highlight String term=NONE cterm=NONE ctermfg=37
highlight vimSynType term=NONE cterm=NONE ctermfg=37

" set additional highlighting based on light or dark background
function SetHighlight()
  if &background == "dark"
    highlight Normal term=NONE cterm=NONE ctermbg=0 ctermfg=15
    highlight Comment term=NONE cterm=NONE ctermbg=0 ctermfg=242
    highlight Folded term=NONE cterm=NONE ctermbg=0 ctermfg=214
    highlight Visual term=NONE cterm=NONE ctermbg=111 ctermfg=0
    highlight Search term=NONE cterm=NONE ctermbg=115 ctermfg=0
    highlight Error term=NONE cterm=NONE ctermbg=0 ctermfg=196
    highlight MatchParen term=NONE cterm=NONE ctermbg=0 ctermfg=196
    highlight SignColumn term=NONE cterm=NONE ctermbg=0
    highlight FoldColumn term=NONE cterm=NONE ctermbg=0
    highlight EndOfBuffer term=NONE cterm=NONE ctermbg=0 ctermfg=0
    highlight LineNr term=NONE cterm=NONE ctermbg=0 ctermfg=244
    highlight CursorLineNr term=NONE cterm=NONE ctermbg=0 ctermfg=111
    highlight CursorLine term=NONE cterm=NONE ctermbg=0
    highlight StatusLine term=NONE cterm=NONE ctermbg=242 ctermfg=0
    highlight StatusLineTerm term=NONE cterm=NONE ctermbg=242 ctermfg=0
    highlight VertSplit term=NONE cterm=NONE ctermbg=0 ctermfg=0
    highlight netrwTreeBar term=NONE cterm=NONE ctermbg=0 ctermfg=0
    highlight netrwPlain term=NONE cterm=NONE ctermbg=0 ctermfg=248
    highlight netrwClassify term=NONE cterm=NONE ctermbg=0 ctermfg=248
    highlight netrwLink term=NONE cterm=NONE ctermbg=0 ctermfg=248
    highlight netrwDir term=NONE cterm=NONE ctermbg=0 ctermfg=68
    highlight GitGutterDelete term=NONE cterm=NONE ctermbg=0 ctermfg=1
    highlight GitGutterAdd term=NONE cterm=NONE ctermbg=0 ctermfg=2
    highlight GitGutterChange term=NONE cterm=NONE ctermbg=0 ctermfg=3
    highlight CtrlPMode1 term=NONE cterm=NONE ctermbg=242 ctermfg=0
    highlight CtrlPMode2 term=NONE cterm=NONE ctermbg=242 ctermfg=0
    highlight StatusLineNC term=NONE cterm=NONE ctermbg=242 ctermfg=242
    highlight StatusLineTermNC term=NONE cterm=NONE ctermbg=242 ctermfg=242
    highlight qfFileName term=NONE cterm=NONE ctermfg=214
    highlight Identifier term=NONE cterm=NONE ctermfg=39
    highlight Type term=NONE cterm=NONE ctermfg=39
    highlight PreProc term=NONE cterm=NONE ctermfg=202
    highlight Statement term=NONE cterm=NONE ctermfg=214
  else
    highlight Normal term=NONE cterm=NONE ctermbg=15 ctermfg=0
    highlight Comment term=NONE cterm=NONE ctermbg=15 ctermfg=248
    highlight Folded term=NONE cterm=NONE ctermbg=15 ctermfg=166
    highlight Visual term=NONE cterm=NONE ctermbg=111 ctermfg=0
    highlight Search term=NONE cterm=NONE ctermbg=115 ctermfg=15
    highlight Error term=NONE cterm=NONE ctermbg=15 ctermfg=196
    highlight MatchParen term=NONE cterm=NONE ctermbg=15 ctermfg=196
    highlight SignColumn term=NONE cterm=NONE ctermbg=15
    highlight FoldColumn term=NONE cterm=NONE ctermbg=15
    highlight EndOfBuffer term=NONE cterm=NONE ctermbg=15 ctermfg=15
    highlight LineNr term=NONE cterm=NONE ctermbg=15 ctermfg=248
    highlight CursorLineNr term=NONE cterm=NONE ctermbg=15 ctermfg=111
    highlight CursorLine term=NONE cterm=NONE ctermbg=15
    highlight StatusLine term=NONE cterm=NONE ctermbg=248 ctermfg=15
    highlight StatusLineTerm term=NONE cterm=NONE ctermbg=248 ctermfg=15
    highlight VertSplit term=NONE cterm=NONE ctermbg=15 ctermfg=15
    highlight netrwTreeBar term=NONE cterm=NONE ctermbg=15 ctermfg=15
    highlight netrwPlain term=NONE cterm=NONE ctermbg=15 ctermfg=242
    highlight netrwClassify term=NONE cterm=NONE ctermbg=15 ctermfg=242
    highlight netrwLink term=NONE cterm=NONE ctermbg=15 ctermfg=242
    highlight netrwDir term=NONE cterm=NONE ctermbg=15 ctermfg=68
    highlight GitGutterDelete term=NONE cterm=NONE ctermbg=15 ctermfg=160
    highlight GitGutterAdd term=NONE cterm=NONE ctermbg=15 ctermfg=70
    highlight GitGutterChange term=NONE cterm=NONE ctermbg=15 ctermfg=178
    highlight CtrlPMode1 term=NONE cterm=NONE ctermbg=248 ctermfg=15
    highlight CtrlPMode2 term=NONE cterm=NONE ctermbg=248 ctermfg=15
    highlight StatusLineNC term=NONE cterm=NONE ctermbg=248 ctermfg=248
    highlight StatusLineTermNC term=NONE cterm=NONE ctermbg=248 ctermfg=248
    highlight qfFileName term=NONE cterm=NONE ctermfg=136
    highlight Identifier term=NONE cterm=NONE ctermfg=32
    highlight Type term=NONE cterm=NONE ctermfg=32
    highlight PreProc term=NONE cterm=NONE ctermfg=166
    highlight Statement term=NONE cterm=NONE ctermfg=136
  endif
endfunction

" set highlighting at startup
autocmd VimEnter * call SetHighlight()

" set highlighting when background changes
try
  autocmd OptionSet background call SetHighlight()
catch /:E216:/
endtry

" toggle the background from dark to light
nnoremap <silent> <leader>b :let &bg=(&bg=='light'?'dark':'light')<cr>

" parse results from ripgrep and a basic list of files for the quickfix list
set errorformat=%f:%l:%c:%m,%f

" use :make to load modified files according to git into the quickfix list
set makeprg=git\ ls-files\ -m
nnoremap <silent> <leader>m :make<cr><cr><cr>

" internal grep into the quickfix list using ripgrep
set grepprg=rg\ --vimgrep\ --smart-case\ $*
set grepformat^=%f:%l:%c:%m

" search current selection with ripgrep as above
vnoremap <silent> <leader>g y:grep! "<c-r>"" %<cr><cr>

" automatically close the quickfix window when a file is selected with Enter
:autocmd FileType qf nnoremap <buffer> <cr> <cr>:cclose<cr>

" enable navigation with control key for splits
nnoremap <c-h> <c-w><c-h>
nnoremap <c-j> <c-w><c-j>
nnoremap <c-k> <c-w><c-k>
nnoremap <c-l> <c-w><c-l>
nnoremap <c-left>  <c-w><c-h>
nnoremap <c-down>  <c-w><c-j>
nnoremap <c-up>    <c-w><c-k>
nnoremap <c-right> <c-w><c-l>

" go to previous window and close all other windows
nmap <leader>o <c-w>p<c-w>o

" prettify netrw
let g:netrw_banner = 0
let g:netrw_cursor = 5
let g:netrw_liststyle = 0
let g:netrw_browse_split = 0
let g:netrw_winsize = 25
let g:netrw_keepdir = 1
let g:netrw_sizestyle = "h"
try
  let g:netrw_list_hide= netrw_gitignore#Hide().',.*\.swp$,.*\.git$,^\.git/$,.*\.gitmodules,.*\.netrwhist'
catch /:E117:/
endtry

" toggle netrw
nnoremap <silent> <leader>e :Lexplore<cr>

" FUNCTIONS

" expanded paste mode to avoid autoformatting if needed
function! TogglePastemode()
  if !exists("b:pastemode_on") || b:pastemode_on
    set signcolumn=no
    set mouse=
    set nonumber
    set laststatus=0
    set paste
    let b:pastemode_on=0
  else
    set signcolumn=yes
    set mouse=a
    set number
    set laststatus=2
    set nopaste
    let b:pastemode_on=1
  endif
endfunction

" get the current git branch for the statusline
function! GitBranch()
  let s:branch=substitute(system("git -C " . expand("%:h") . " branch --show-current 2>/dev/null"), '\n', '', 'g')
  if s:branch != ""
    return "(" . s:branch . ")"
  else
    return ""
  end
endfunction

augroup GitBranch
  autocmd!
  autocmd BufWinEnter * let b:git_branch = GitBranch()
augroup END

" get the current git root for the statusline
function! GitRoot()
  let s:root=substitute(system("git -C " . expand("%:h") . " rev-parse --show-toplevel 2>/dev/null"), '\n', '', 'g')
  if s:root != ""
    return s:root
  else
    return expand("%:p:h")
  end
endfunction

augroup GitRoot
  autocmd!
  autocmd BufWinEnter * let b:git_root = GitRoot()
augroup END

" toggle quickfix window
function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction
nnoremap <silent> <leader>q :call ToggleQuickFix()<cr>

" PLUGINS

" vim rooter
let g:rooter_cd_cmd = 'lcd'
let g:rooter_silent_chdir = 1

" git gutter
try
  set signcolumn=yes
catch /:E518:/
endtry
set updatetime=100
nmap <leader>n <plug>(GitGutterNextHunk)
nmap <leader>p <plug>(GitGutterPrevHunk)
nmap <leader>a <plug>(GitGutterStageHunk)
nmap <leader>hs <nop>
nmap <leader>hu <nop>

" tabular
nmap <leader>t= :Tab /=<cr>
nmap <leader>t> :Tab /=><cr>
nmap <leader>t, :Tab /,\zs/l0r1<cr>
vmap <leader>t= :Tab /=<cr>
vmap <leader>t> :Tab /=><cr>
vmap <leader>t, :Tab /,\zs/l0r1<cr>

" ctrlp
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_match_window = 'bottom,order:btt,min:1,max:10,results:0'
if &rtp =~ '/ctrlp.vim'
  nnoremap f :CtrlP<cr>
  nnoremap F :CtrlPMRU<cr>
  nnoremap <tab> :CtrlPBuffer<cr>
else
  " use internal vim replacements if ctrlp is not available
  nnoremap f :Explore<cr>
  nnoremap F :browse old<cr>
  nnoremap <tab> :buffer<space><tab><tab><tab>
endif

" turn on the cursorline when in ctrlp
function! CtrlPSetCursorLine()
  set cursorlineopt=line
endfunction
function! CtrlPUnsetCursorLine()
  set cursorlineopt=number
endfunction
let g:ctrlp_buffer_func = { 'enter': 'CtrlPSetCursorLine', 'exit':  'CtrlPUnsetCursorLine', }

" osc yank
let g:oscyank_silent = 0
let g:oscyank_trim = 0
nmap <leader>c <plug>OSCYankOperator
nmap <leader>cc <leader>c_
vmap <leader>c <plug>OSCYankVisual

" FIXES

" fix vim starting with light background in git bash.

if $MSYSTEM =~? 'MSYS'
  set background=dark
endif

" fix vi starting in replace mode in WSL
nnoremap <esc>^[ <esc>^[

" fix search misbehaviour after search pattern has been cleared
function! ExecuteSearch(command)
  if strlen(@/) > 0
    try
      execute "normal! " .. a:command
    catch /:E486:/
    endtry
  endif
endfunction

nnoremap <silent> n :call ExecuteSearch("n")<cr>
nnoremap <silent> N :call ExecuteSearch("N")<cr>

" stop netrw from leaving [No Name] buffers and make sure other buffers continue
" to be hidden to avoid save warnings
set nohidden
autocmd FileType netrw setl bufhidden=wipe
augroup netrw_bufhidden_fix
  autocmd!
  autocmd BufWinEnter * if &ft != 'netrw' | set bufhidden=hide | endif
augroup END

" exit vim if netrw is the only window or tab remaining
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "netrw" | quit | endif
autocmd BufEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "netrw" | quit | endif

" exit vim if quickfix is the only window or tab remaining
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" | quit | endif
autocmd BufEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" | quit | endif

" fix git commit buffers not working with paragraph formatting
augroup gitcommit_fo_fix
  autocmd!
  autocmd BufWinEnter * if &ft == 'gitcommit' | setlocal formatoptions-=a | endif
augroup END
