" enable syntax highlighting and indenting
syntax on
filetype plugin indent on

" set encoding and colour range for modern terminals
set encoding=utf8
set t_Co=256

" set sensible values for the viminfo file
set nocompatible
set viminfo='20,<500,/50,:50,h

" shorten warning messages and hide startup banner
set shortmess=aI

" set leader key and timeout
let mapleader=","
set timeoutlen=300

" enable line numbers
set number
set cursorline
set cursorlineopt=number

" convert tabs to two spaces
set softtabstop=2
set shiftwidth=2
set smarttab
set expandtab

" disable bell
set visualbell
set t_vb=

" autoformat comments by default
set textwidth=80
set formatoptions=cqj
set nojoinspaces

" make sure the formatoptions are applied to new buffers properly
autocmd BufRead,BufNewFile * setlocal formatoptions=cqj

" enable search highlighting and clear with return
set hlsearch
nnoremap <silent> <cr> :let @/ = ""<cr><cr>

" use shift-tab to insert a literal tab character
inoremap <s-tab> <c-q><tab>

" turn off vertical split and end of buffer markers
set fillchars+=vert:\ ,eob:\ 

" mark tabs and trailing whitepace
set listchars=tab:▸·,trail:×
set list

" turn off trailing whitespace mark in insert mode
autocmd InsertEnter * setlocal listchars=tab:▸·
autocmd InsertLeave * setlocal listchars=tab:▸·,trail:×

" partially enable mouse
set mouse=nv

" enter visual block mode without needing ctrl-v, which terminals capture
nnoremap <leader>v <c-v>

" set tab completion menu
set wildmenu
set wildignorecase
set wildignore+=.git,*.swp,*.zip
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
set statusline+=[%{&ff}]
set statusline+=%{g:space}
set statusline+=[%{&fileencoding?&fileencoding:&encoding}]
set statusline+=%{&paste?'\ [paste]':''}
set statusline+=%{g:space}
set statusline+=%m%r%h
set statusline+=%=
set statusline+=%<%{get(b:,'git_root','')}
set statusline+=%{g:space}
set statusline+=c%c
set statusline+=%{g:space}

" turn off bold and underlines
highlight CursorLine term=NONE cterm=NONE
highlight CursorLineNr term=NONE cterm=NONE
highlight FoldColumn term=NONE cterm=NONE
highlight StatusLine term=NONE cterm=NONE
highlight StatusLineTerm term=NONE cterm=NONE

" reverse background for visual mode and search
highlight Visual ctermbg=111 ctermfg=0
highlight Search ctermbg=115 ctermfg=0

" common highlighting
highlight Constant ctermfg=37
highlight Noise ctermfg=245
highlight NonText ctermfg=203
highlight Number ctermfg=37
highlight SpecialKey ctermfg=203
highlight Special ctermfg=245
highlight String ctermfg=37
highlight vimSynType ctermfg=37
highlight netrwDir ctermfg=68
highlight Error ctermfg=196
highlight MatchParen ctermfg=196
highlight CursorLineNr ctermfg=111

" set additional highlighting based on light or dark background
function SetHighlight()
  " apply highlights for light or dark backgrounds
  if &background == "light"
    " set light background where needed
    highlight Normal ctermbg=0 ctermfg=15
    highlight SignColumn ctermbg=0
    highlight VertSplit ctermfg=0
    highlight GitGutterDelete ctermbg=0 ctermfg=160
    highlight GitGutterAdd ctermbg=0 ctermfg=70
    highlight GitGutterChange ctermbg=0 ctermfg=178
    " custom highlights to suit light background
    highlight Folded ctermfg=166
    highlight qfFileName ctermfg=136
    highlight Identifier cterm=NONE ctermfg=32
    highlight Type ctermfg=32
    highlight PreProc ctermfg=166
    highlight Statement ctermfg=136
    " grey things
    highlight Comment ctermfg=248
    highlight CursorLine ctermbg=248 ctermfg=15
    highlight StatusLine ctermbg=248 ctermfg=0
    highlight StatusLineTerm ctermbg=248 ctermfg=0
    highlight CtrlPMode1 ctermbg=248 ctermfg=0
    highlight CtrlPMode2 ctermbg=248 ctermfg=0
    highlight StatusLineNC ctermbg=248 ctermfg=248
    highlight StatusLineTermNC ctermbg=248 ctermfg=248
    highlight netrwPlain ctermfg=248
    highlight netrwClassify ctermfg=248
    highlight netrwLink ctermfg=248
    highlight LineNr ctermfg=248
    " set comment here to override syntax highlighting
    highlight Comment ctermfg=248
  else
    " set dark background where needed
    highlight Normal ctermbg=15 ctermfg=0
    highlight SignColumn ctermbg=15
    highlight VertSplit ctermfg=15
    highlight GitGutterDelete ctermbg=15 ctermfg=1
    highlight GitGutterAdd ctermbg=15 ctermfg=2
    highlight GitGutterChange ctermbg=15 ctermfg=3
    " custom highlights to suit dark background
    highlight Folded ctermfg=214
    highlight qfFileName ctermfg=214
    highlight Identifier cterm=NONE ctermfg=39
    highlight Type ctermfg=39
    highlight PreProc ctermfg=202
    highlight Statement ctermfg=214
    " grey things
    highlight CursorLine ctermbg=242 ctermfg=0
    highlight StatusLine ctermbg=242 ctermfg=15
    highlight StatusLineTerm ctermbg=242 ctermfg=15
    highlight CtrlPMode1 ctermbg=242 ctermfg=15
    highlight CtrlPMode2 ctermbg=242 ctermfg=15
    highlight StatusLineNC ctermbg=242 ctermfg=242
    highlight StatusLineTermNC ctermbg=242 ctermfg=242
    highlight netrwPlain ctermfg=242
    highlight netrwClassify ctermfg=242
    highlight netrwLink ctermfg=242
    highlight LineNr ctermfg=242
    " set comment here to override syntax highlighting
    highlight Comment ctermfg=242
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

" use :make to load modified files according to git into the quickfix list
set makeprg=git\ ls-files\ -m
set errorformat^=%f
nnoremap <silent> <leader>g :make<cr><cr><cr>

" internal grep into the quickfix list using ripgrep
set grepprg=rg\ --vimgrep\ --smart-case\ $*
set grepformat^=%f:%l:%c:%m
vnoremap <silent> <leader>f y:grep! "<c-r>"" %<cr><cr>

" automatically close the quickfix window when a file is selected with Enter
:autocmd FileType qf nnoremap <buffer> <cr> <cr>:cclose<cr>

" use the control key to navigate between splits
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

" toggle netrw
nnoremap <silent> <leader>e :Lexplore<cr>

" prettify netrw
let g:netrw_banner=0
let g:netrw_cursor=8
let g:netrw_liststyle=0
let g:netrw_browse_split=0
let g:netrw_winsize=25
let g:netrw_keepdir=0
let g:netrw_sizestyle="h"
let g:netrw_hide=1
let g:netrw_list_hide='\(^\|\s\s\)\zs\.\S\+'

" highlight the current line in netrw
augroup netrw_set_cursorlineopt
  autocmd!
  autocmd FileType netrw set cursorlineopt=line
augroup end

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
    set mouse=nv
    set number
    set laststatus=2
    set nopaste
    let b:pastemode_on=1
  endif
endfunction
nnoremap <silent> <leader>p :call TogglePastemode()<cr>

" get the current git branch for the statusline
function! GitBranch()
  let s:branch=substitute(system("git -C " . expand("%:h") . " branch --show-current 2>/dev/null"), '\n', '', 'g')
  if s:branch != ""
    return "[" . s:branch . "]"
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
nmap <leader>N <plug>(GitGutterPrevHunk)
nmap <leader>a <plug>(GitGutterStageHunk)
nmap <leader>hs <nop>
nmap <leader>hu <nop>

" tabular

" align on whitespace, tap space twice to only align first two columns
nmap <silent> <leader>t<space><space> :Tab /\(^\S\+\s\+\)\zs\(\S\+\)/<cr>
nmap <silent> <leader>t<space> :Tab /\S\+\zs\s/l0<cr>
vmap <silent> <leader>t<space><space> :Tab /\(^\S\+\s\+\)\zs\(\S\+\)/<cr>
vmap <silent> <leader>t<space> :Tab /\S\+\zs\s/l0<cr>

" align on various characters, can be used together, particularly = then ,
nmap <silent> <leader>t= :Tab /=<cr>
nmap <silent> <leader>t> :Tab /=><cr>
nmap <silent> <leader>t, :Tab /,\zs/l0r1<cr>
vmap <silent> <leader>t= :Tab /=<cr>
vmap <silent> <leader>t> :Tab /=><cr>
vmap <silent> <leader>t, :Tab /,\zs/l0r1<cr>

" ctrlp
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
let g:ctrlp_match_window = 'bottom,order:btt'
nnoremap f :CtrlP<cr>
nnoremap F :CtrlPMRU<cr>
nnoremap <tab> :CtrlPBuffer<cr>

" highlight the current line in ctrlp
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
nmap <leader>y <plug>OSCYankOperator
vmap <leader>y <plug>OSCYankVisual

" FIXES

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
