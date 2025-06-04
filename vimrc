silent! call pathogen#infect()

" enable syntax highlighting and indenting
syntax on
filetype plugin indent on

" set colour range for modern terminals
set t_Co=256

" set sensible values for the viminfo file
set nocompatible
set viminfo='20,<500,/50,:50,h

" set default base colours
let g:darkbg=8
let g:darkfg=15
let g:lightbg=8
let g:lightfg=15

" set base colours properly for ChromeOS
let g:proc_version = substitute(system("cat /proc/version | grep 'Chromium OS' 2>/dev/null"), '\n', '', 'g')
if g:proc_version == ""
  let g:darkbg=0
  let g:darkfg=15
  let g:lightbg=15
  let g:lightfg=0
end

" set colours based on light or dark background
function SetHighlight()
  if &background == "dark"
    execute "highlight Normal term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=" . g:darkfg
    execute "highlight Comment term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=242"
    execute "highlight Visual term=NONE cterm=NONE ctermbg=111 ctermfg=" . g:darkbg
    execute "highlight Error term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=196"
    execute "highlight MatchParen term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=196"
    execute "highlight SignColumn term=NONE cterm=NONE ctermbg=" . g:darkbg
    execute "highlight EndOfBuffer term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=" . g:darkbg
    execute "highlight LineNr term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=244"
    execute "highlight CursorLineNr term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=111"
    execute "highlight CursorLine term=NONE cterm=NONE ctermbg=" . g:darkbg
    execute "highlight StatusLine term=NONE cterm=NONE ctermbg=242 ctermfg=" . g:darkbg
    execute "highlight StatusLineTerm term=NONE cterm=NONE ctermbg=242 ctermfg=" . g:darkbg
    execute "highlight VertSplit term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=" . g:darkbg
    highlight StatusLineNC term=NONE cterm=NONE ctermbg=242 ctermfg=242
    highlight StatusLineTermNC term=NONE cterm=NONE ctermbg=242 ctermfg=242
    execute "highlight netrwTreeBar term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=" . g:darkbg
    execute "highlight netrwPlain term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=248"
    execute "highlight netrwClassify term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=248"
    execute "highlight netrwLink term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=248"
    execute "highlight netrwDir term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=68"
    highlight qfFileName term=NONE cterm=NONE ctermfg=214
    " syntax highlighting for plugins
    execute "highlight GitGutterDelete term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=1"
    execute "highlight GitGutterAdd term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=2"
    execute "highlight GitGutterChange term=NONE cterm=NONE ctermbg=" . g:darkbg . " ctermfg=3"
    execute "highlight CtrlPMode1 term=NONE cterm=NONE ctermbg=242 ctermfg=" . g:darkbg
    execute "highlight CtrlPMode2 term=NONE cterm=NONE ctermbg=242 ctermfg=" . g:darkbg
    " syntax highlighting for code
    highlight Identifier term=NONE cterm=NONE ctermfg=39
    highlight Type term=NONE cterm=NONE ctermfg=39
    highlight PreProc term=NONE cterm=NONE ctermfg=202
    highlight Statement term=NONE cterm=NONE ctermfg=214
    highlight Constant term=NONE cterm=NONE ctermfg=37
    highlight String term=NONE cterm=NONE ctermfg=37
    highlight Number term=NONE cterm=NONE ctermfg=37
    highlight vimSynType term=NONE cterm=NONE ctermfg=37
    highlight Special term=NONE cterm=NONE ctermfg=245
    highlight Noise term=NONE cterm=NONE ctermfg=245
    highlight SpecialKey term=NONE cterm=NONE ctermfg=203
    highlight NonText term=NONE cterm=NONE ctermfg=203
  else
    execute "highlight Normal term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=" . g:lightfg
    execute "highlight Comment term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=248"
    execute "highlight Visual term=NONE cterm=NONE ctermbg=111 ctermfg=" . g:lightfg
    execute "highlight Error term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=196"
    execute "highlight MatchParen term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=196"
    execute "highlight SignColumn term=NONE cterm=NONE ctermbg=" . g:lightbg
    execute "highlight EndOfBuffer term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=" . g:lightbg
    execute "highlight LineNr term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=248"
    execute "highlight CursorLineNr term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=111"
    execute "highlight CursorLine term=NONE cterm=NONE ctermbg=" . g:lightbg
    execute "highlight StatusLine term=NONE cterm=NONE ctermbg=248 ctermfg=" . g:lightbg
    execute "highlight StatusLineTerm term=NONE cterm=NONE ctermbg=248 ctermfg=" . g:lightbg
    execute "highlight VertSplit term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=" . g:lightbg
    highlight StatusLineNC term=NONE cterm=NONE ctermbg=248 ctermfg=248
    highlight StatusLineTermNC term=NONE cterm=NONE ctermbg=248 ctermfg=248
    execute "highlight netrwTreeBar term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=" . g:lightbg
    execute "highlight netrwPlain term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=242"
    execute "highlight netrwClassify term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=242"
    execute "highlight netrwLink term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=242"
    execute "highlight netrwDir term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=68"
    highlight qfFileName term=NONE cterm=NONE ctermfg=136
    " syntax highlighting for plugins
    execute "highlight GitGutterDelete term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=160"
    execute "highlight GitGutterAdd term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=70"
    execute "highlight GitGutterChange term=NONE cterm=NONE ctermbg=" . g:lightbg . " ctermfg=178"
    execute "highlight CtrlPMode1 term=NONE cterm=NONE ctermbg=248 ctermfg=" . g:lightbg
    execute "highlight CtrlPMode2 term=NONE cterm=NONE ctermbg=248 ctermfg=" . g:lightbg
    " syntax highlighting for code
    highlight Identifier term=NONE cterm=NONE ctermfg=32
    highlight Type term=NONE cterm=NONE ctermfg=32
    highlight PreProc term=NONE cterm=NONE ctermfg=166
    highlight Statement term=NONE cterm=NONE ctermfg=136
    highlight Constant term=NONE cterm=NONE ctermfg=37
    highlight String term=NONE cterm=NONE ctermfg=37
    highlight Number term=NONE cterm=NONE ctermfg=37
    highlight vimSynType term=NONE cterm=NONE ctermfg=37
    highlight Special term=NONE cterm=NONE ctermfg=245
    highlight Noise term=NONE cterm=NONE ctermfg=245
    highlight SpecialKey term=NONE cterm=NONE ctermfg=203
    highlight NonText term=NONE cterm=NONE ctermfg=203
  endif
endfunction

autocmd VimEnter * call SetHighlight()

try
  autocmd OptionSet background call SetHighlight()
catch /:E216:/
endtry

" toggle the background from dark to light with \b in normal mode
nnoremap <silent> <Leader>b :let &bg=(&bg=='light'?'dark':'light')<CR>

" autoformat comments by default
set textwidth=80
set formatoptions=croqj/
set nojoinspaces

" make sure the formatoptions are applied to new buffers properly
autocmd BufRead,BufNewFile * setlocal formatoptions=croqj/

" toggle paste mode with \v to avoid autoformatting if needed
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

nnoremap <silent> <Leader>v :call TogglePastemode()<cr>

" enable line numbers
set number
set cursorline

" disable bell
set visualbell
set t_vb=

" set tabs
set softtabstop=2
set shiftwidth=2
set smarttab
set expandtab

" use shift-tab to insert an actual tab character
inoremap <S-Tab> <C-Q><Tab>

" mark tabs and trailing whitepace
set listchars=tab:▸·,trail:×
set list

" turn off trailing whitespace mark in insert mode
autocmd InsertEnter * setlocal listchars=tab:▸·
autocmd InsertLeave * setlocal listchars=tab:▸·,trail:×

" set tab completion menu
set wildmenu
set wildignorecase
set wildignore+=*.so,*.swp,*.zip
set wildmode=longest:full,full
set wildcharm=<Tab>
set path=.,**

" enable mouse
set mouse=a

" set the errorformat to load results from ripgrep into quickfix
set errorformat^=%f:%l:%c:%m

" automatically close the quickfix window when a file is selected with Enter
:autocmd FileType qf nnoremap <buffer> <CR> <CR>:cclose<CR>

" enable navigation with control key for splits
nnoremap <C-H> <C-W><C-H>
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-Left>  <C-W><C-H>
nnoremap <C-Down>  <C-W><C-J>
nnoremap <C-Up>    <C-W><C-K>
nnoremap <C-Right> <C-W><C-L>

" go to previous window and close all other windows
nmap <leader>o <C-W>p<C-W>o

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

" set the status line
let g:space = ' '
set laststatus=2
set statusline=
set statusline+=%{b:git_branch}
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
set statusline+=%<%{b:git_root}
set statusline+=%{g:space}
set statusline+=%c
set statusline+=%{g:space}

" prettify netrw
let g:netrw_banner = 0
let g:netrw_cursor = 5
let g:netrw_liststyle = 0
let g:netrw_browse_split = 0
let g:netrw_winsize = 25
try
  let g:netrw_list_hide= netrw_gitignore#Hide().',.*\.swp$,.*\.git$,^\.git/$,.*\.gitmodules,.*\.netrwhist'
catch /:E117:/
endtry
let g:netrw_keepdir = 1
let g:netrw_sizestyle = "h"

" toggle netrw
nnoremap <silent> <Leader>e :Lexplore<CR>

" toggle quickfix window
function! ToggleQuickFix()
  if empty(filter(getwininfo(), 'v:val.quickfix'))
    copen
  else
    cclose
  endif
endfunction
nnoremap <silent> <Leader>q :call ToggleQuickFix()<cr>

" PLUGINS

" ack
let g:ackprg = 'rg --vimgrep --type-not sql --smart-case'
let g:ack_autoclose = 1
let g:ack_use_cword_for_empty_search = 1
cnoreabbrev Ack Ack!
nnoremap <Leader>s :Ack!<Space>

" vim rooter
let g:rooter_cd_cmd = 'lcd'
let g:rooter_silent_chdir = 1

" git gutter
try
  set signcolumn=yes
catch /:E518:/
endtry
set updatetime=100
nmap <Leader>n <Plug>(GitGutterNextHunk)
nmap <Leader>p <Plug>(GitGutterPrevHunk)
nmap <Leader>a <Plug>(GitGutterStageHunk)
nmap <Leader>u <Plug>(GitGutterUndoHunk)
nmap <Leader>hs <Nop>
nmap <Leader>hu <Nop>

" vim fugitive
nmap <Leader>S :Git -p status<Return>
nmap <Leader>D :Git -p diff<Return>
nmap <Leader>C :Git commit -a<Return>
nmap <Leader>P :Git -p push<Return>

" vim-ripgrep
let g:rg_derive_root=1

" tabular
nmap <Leader>t :Tabularize /=<Return>
nmap <Leader>T :Tabularize /=><Return>
nmap <Leader>, :Tabularize /,\zs<Return>
nmap <Leader>. :Tabularize /^  *[^ ]* \zs/<Return>
vmap <Leader>t :Tabularize /=<Return>
vmap <Leader>T :Tabularize /=><Return>
vmap <Leader>, :Tabularize /,\zs<Return>
vmap <Leader>. :Tabularize /^  *[^ ]* \zs/<Return>

" ctrlp
let g:ctrlp_working_path_mode = 'rwa'
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
if exists("g:loaded_pathogen")
  nnoremap f :CtrlP<CR>
  nnoremap F :CtrlPMRU<CR>
  nnoremap <Tab> :CtrlPBuffer<CR>
else
  nnoremap f :Explore<CR>
  nnoremap F :browse old<CR>
  nnoremap <Tab> :buffer<Space><Tab><Tab><Tab>
endif

" turn on the cursorline when in ctrlp
function! CtrlPSetCursorLine()
  set cursorlineopt=line
endfunction
function! CtrlPUnsetCursorLine()
  set cursorlineopt=number
endfunction
let g:ctrlp_buffer_func = { 'enter': 'CtrlPSetCursorLine', 'exit':  'CtrlPUnsetCursorLine', }

" FIXES

" WSL yank support
let s:clip = '/mnt/c/Windows/System32/clip.exe'
if executable(s:clip)
    augroup WSLYank
        autocmd!
        autocmd TextYankPost * if v:event.operator ==# 'y' | call system(s:clip, @0) | endif
    augroup END
endif

" stop vi starting in replace mode in WSL
nnoremap <Esc>^[ <Esc>^[

" shorten warning messages and hide startup banner
set shortmess=aI

" exit vim if netrw is the only window or tab remaining
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "netrw" |
      \ quit |
      \ endif
autocmd BufEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "netrw" |
      \ quit |
      \ endif

" exit vim if quickfix is the only window or tab remaining
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" |
      \ quit |
      \ endif
autocmd BufEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix" |
      \ quit |
      \ endif

" stop netrw from leaving [No Name] buffers and make sure other buffers continue
" to be hidden to avoid save warnings
set nohidden
autocmd FileType netrw setl bufhidden=wipe
augroup netrw_bufhidden_fix
    autocmd!
    autocmd BufWinEnter *
                \  if &ft != 'netrw'
                \|     set bufhidden=hide
                \| endif
augroup END

" fix git commit buffers not working with paragraph formatting
augroup gitcommit_fo_fix
    autocmd!
    autocmd BufWinEnter *
                \  if &ft == 'gitcommit'
                \|     setlocal formatoptions-=a
                \| endif
augroup END
