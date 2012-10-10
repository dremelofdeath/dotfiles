set nocompatible
set showcmd

" detect if we're in restricted mode before doing anything else
let RESTRICTED_MODE=0
try
  call system("echo ...")
catch /^Vim\%((\a\+)\)\=:E145/
  let RESTRICTED_MODE=1
endtry

set rtp+=~/vimfiles,~/vimfiles/after

if has("persistent_undo")
  set undofile
  set undolevels=10000
endif

if has("gui_macvim")
  sil! set gfn=ProggySquare:h11
endif

let g:dock_hidden = 0

" on Mac OS X, gets the computer name (not the host name)
if (!RESTRICTED_MODE && (has("macunix") || has("gui_macvim")))
  function MacGetComputerName()
    let computernamestring = system("scutil --get ComputerName")
    return strpart(computernamestring, 0, strlen(computernamestring)-1)
  endfunction

  " on Mac OS X, toggle hiding the dock
  function MacToggleDockHiding()
    if has("autocmd")
      if g:dock_hidden == 0
        let g:dock_hidden = 1
        " this is to make sure that the dock is unhidden on exit
        aug zcm_dock_hiding
        au zcm_dock_hiding VimLeave * call MacToggleDockHiding()
        aug END
      else
        let g:dock_hidden = 0
        " this should make sure that the dock isn't touched
        " if it's been manually unhidden
        aug zcm_dock_hiding
        au! zcm_dock_hiding
        aug END
      endif
    endif
    call system("osascript -e 'tell app \"System Events\" to keystroke \"d\" using {command down, option down}'")
  endfunction
endif

" these two functions allow the user to toggle between
" standard comments and Doxygen comments
function EnableDoxygenComments()
  let b:zcm_doxified = 1
  set syn+=.doxygen
endfunction
function DisableDoxygenComments()
  let b:zcm_doxified = 0
  set syn-=.doxygen
endfunctio

function ToggleDoxygenComments()
  if b:zcm_doxified == 0
    call EnableDoxygenComments()
    " this should be defined in the zcm_folding au group
    "if b:open_all_folds_bfbn == 1
    " silent! %foldo!
    "endif
  else
    call DisableDoxygenComments()
  endif
endfunction

" function for fullscreen maximize, at least on a 1280x800 Macintosh desktop
" NOTE: you must use a GUIEnter autocommand to make this happen on startup
function FullScreenMaximize_Harmony()
  if has("macunix") && g:dock_hidden == 0
    call MacToggleDockHiding()
  endif
  winp 1 0
  set lines=59
  set columns=210
endfunction

function FullScreenMaximize_Bliss()
  if has("macunix") && g:dock_hidden == 0
    call MacToggleDockHiding()
  endif
  winp 0 0
  set lines=90
  set columns=317
endfunction

function NotepadWindowSize(widthfactor)
  set lines=50
  let &columns=88*a:widthfactor
endfunction

function RecalculatePluginSplitWidth()
  let l:width=0
  if (&columns / 5 < 30)
    let l:width=30
  else
    let l:width=(&columns / 5)
  endif
  return l:width
endfunction

function RecalculatePluginSplitHeight()
  let l:height=0
  if &lines > 30
    let l:height=(&lines / 4 + 3)
  else
    let l:height=(&lines / 3)
  endif
  return l:height
endfunction

let MICROSOFT_CORP_SPECIFIC=0
let AMAZON_CORP_SPECIFIC=0
let GOOGLE_CORP_SPECIFIC=0

function CheckRunningAtGoogle()
  let l:domain_match=0
  if has("unix")
    let l:pattern="[a-zA-Z0-9_\\-]\\+\\.[a-zA-Z0-9_\\-]\\+\\."
    let l:domain=substitute(substitute(hostname(), l:pattern, "", ""), "[\s\n]\\+", "", "")
    let l:domain_match=(l:domain == "corp.google.com")
    if !l:domain_match && !g:RESTRICTED_MODE
      " for some reason, that didn't work... try through the shell if we can
      let l:domain=substitute(substitute(system("echo $HOSTNAME"), l:pattern, "", ""), "[\s\n]\\+", "", "")
      let l:domain_match=(l:domain == "corp.google.com")
    endif
  endif
  return l:domain_match
endfunction

if(has("unix") && substitute($HOSTNAME, "[a-zA-Z0-9_\\-]\\+\\.", "", "") == "desktop.amazon.com")
  let AMAZON_CORP_SPECIFIC=1
  if(filereadable("/apollo/env/envImprovement/var/vimrc"))
    so /apollo/env/envImprovement/var/vimrc
    set rtp+=~/vimfiles,~/vimfiles/after
  endif
elseif(CheckRunningAtGoogle())
  let GOOGLE_CORP_SPECIFIC=1
  if(!RESTRICTED_MODE && filereadable("/usr/share/vim/google/gtags.vim"))
    function Google_RecheckGtlistOrientationBounds()
      if (&columns > 162 || &lines < 49)
        let g:google_tags_list_orientation='vertical'
        let g:google_tags_list_height=''
        let g:google_tags_list_width=RecalculatePluginSplitWidth()
      else
        let g:google_tags_list_orientation='horizontal'
        let g:google_tags_list_width=''
        let g:google_tags_list_height=RecalculatePluginSplitHeight()
      endif
    endfunction
    aug ZCM_GoogleGtagsResize
    au ZCM_GoogleGtagsResize VimResized * call Google_RecheckGtlistOrientationBounds()
    aug END
    source /usr/share/vim/google/gtags.vim
    call Google_RecheckGtlistOrientationBounds()
    let g:google_tags_list_format='long'
    nmap <C-]> :exe 'Gtlist ' . expand('<cword>')<CR>
    nmap <C-W>] :tab split<CR>:exec("Gtjump ".expand("<cword>"))<CR>
    nmap <C-W><C-]> :tab split<CR>:exec("Gtjump ".expand("<cword>"))<CR>
    nmap <C-W>g<C-]> :vsp <CR>:exec("Gtjump ".expand("<cword>"))<CR>
  endif
elseif((has("win32") || has("win64")) && substitute($USERDNSDOMAIN, "\\w\\+\\.", "", "") == "CORP.MICROSOFT.COM")
  let MICROSOFT_CORP_SPECIFIC=1
endif

if !RESTRICTED_MODE
  colo elflord " default for if we set nothing else ever
endif

" window settings for gvim
" please only put GUI based settings in this section...
" stuff that doesn't require the GUI to be running should go
" in the block above this one
if has("gui_running")
  call NotepadWindowSize(1)

  " use desert by default, and if we have it, use zackvim
  colo desert
  sil! colo dante
  sil! colo zackvim

  set guioptions+=c
  set guioptions-=R " turn off the right scrollbar
  set guioptions-=L " turn off the left scrollbar
  if has("macunix")
    if !RESTRICTED_MODE
      let __computername = MacGetComputerName()
      if __computername == "Euphoria"
        winp 351 187
      elseif __computername == "Bliss"
        winp 461 262
      elseif __computername == "Harmony"
        "winp 1 0
        " we need to use an autocommand to make this magic happen because
        " Vim hates it when we go out of desktop bounds before it loads the
        " freaking window
        "aug zcm_windows_maximize
        "au zcm_windows_maximize GUIEnter * set lines=59
        "au zcm_windows_maximize GUIEnter * set columns=210
        "au zcm_windows_maximize GUIEnter * call FullScreenMaximize_Harmony()
        "aug END
      elseif __computername == "Tim Menzies’s Mac mini"
      endif
    endif
  elseif has("gui_win32")
    " screw it, on windows we just maximize
    " NOT TODAY! --zack, on Windows 7 (uncomment to enable automaximiz3e)
    " aug zcm_windows_maximize
    " au zcm_windows_maximize GUIEnter * simalt ~x
    " aug END

    " also, kill win32 gvim's toolbar
    set guioptions-=T
    " and the tearoff menu items
    set guioptions-=t
    " and the standard menus themselves
    set guioptions-=m
    " and start from our My Documents (or other home) directory
    cd ~

    " set a font? (I'm cool with not doing this right now in Windows.)
    " set gfn=Lucida_Console:h10:cANSI
    " OMG CONSOLAS NOM NOM NOM
    sil! set gfn=Consolas

    " If we're running on the Microsoft campus, then we want to do a few extra
    " things...
    if MICROSOFT_CORP_SPECIFIC
      " Microsoft does not obey the 80 character limit, so the window should
      " really be bigger. Double ought to do it. --zack
      call NotepadWindowSize(2)
    endif
  endif
endif

if MICROSOFT_CORP_SPECIFIC && ((has("win32") || has("win64")) && !has("win95"))
  " Saving my undofiles alongside sourcefiles breaks my cleansrc step in
  " ohome at MS, so I need to put it somewhere else in order to make sure
  " that my build doesn't break.
  if !isdirectory($APPDATA . "\\vimundodata")
    call mkdir($APPDATA . "\\vimundodata")
  endif
  set undodir="$APPDATA\vimundodata"
endif

if !RESTRICTED_MODE
  function CheckIsCtagsExuberant()
    let l:is_exuberant = 0
    " if cases copied from taglist.vim --zack
    if exists('g:Tlist_Ctags_Cmd')
      let l:cmd = g:Tlist_Ctags_Cmd
    elseif executable('exuberant-ctags')
      " On Debian Linux, exuberant ctags is installed
      " as exuberant-ctags
      let l:cmd = 'exuberant-ctags'
    elseif executable('exctags')
      " On Free-BSD, exuberant ctags is installed as exctags
      let l:cmd = 'exctags'
    elseif executable('ctags')
      let l:cmd = 'ctags'
    elseif executable('ctags.exe')
      let l:cmd = 'ctags.exe'
    elseif executable('tags')
      let l:cmd = 'tags'
    endif
    if exists("l:cmd")
      let l:version_output = system(l:cmd . " --version")
      let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "Exuberant") >= 0)
      let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "exuberant") >= 0)
      if !l:is_exuberant
        let l:version_output = system('"'. l:cmd . '" --version')
        let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "Exuberant") >= 0)
        let l:is_exuberant = l:is_exuberant || (stridx(l:version_output, "exuberant") >= 0)
      endif
    endif
    return l:is_exuberant
  endfunction
  function RecheckTaglistOrientationBounds()
    if (&columns > 162 || &lines < 49)
      let g:Tlist_Use_Horiz_Window=0
      let g:Tlist_WinWidth=RecalculatePluginSplitWidth()
    else
      let g:Tlist_Use_Horiz_Window=1
      let g:Tlist_WinHeight=RecalculatePluginSplitHeight()
    endif
  endfunction
endif

if (filereadable($HOME .  "/vimfiles/ipi/taglist/plugin/taglist.vim"))
  " Find the ctags command
  if (!AMAZON_CORP_SPECIFIC && !GOOGLE_CORP_SPECIFIC)
    if has("unix")
      if filereadable("/opt/local/bin/ctags") " This is the MacPorts case, I think?
        let g:Tlist_Ctags_Cmd = "/opt/local/bin/ctags"
      endif
    elseif (has("win32") || has("win64") || has("win95"))
      " find the ctags utility
      if filereadable($HOME . "\\vimfiles\\bin\\ctags.exe")
        let g:Tlist_Ctags_Cmd = '"' . $HOME . '\\vimfiles\\bin\\ctags.exe"'
      elseif filereadable("c:\\cygwin\\bin\\ctags.exe")
        let g:Tlist_Ctags_Cmd = "c:\\cygwin\\bin\\ctags.exe"
      endif
    endif
  endif
endif

if has("dos32") || has("dos16")
  set viminfo+=nC:/VIM72/_viminfo
endif

" functions to make the window just like ma used to make

" function to make the window in the original starting position
if !RESTRICTED_MODE
  function OriginalWindowPosition()
    if MacGetComputerName() == "Euphoria"
      winp 351 187
    elseif MacGetComputerName() == "Bliss"
      winp 461 262
    elseif MacGetComputerName() == "Harmony"
      winp 1 0
    else
      winp 5 25
    endif
  endfunction

  " function to make the window the original size
  function OriginalWindowSize()
    if has("macunix") && g:dock_hidden == 0
      call MacToggleDockHiding()
    endif
    winp 5 25
    set lines=50
    set columns=160
  endfunction

  " function to do both of the above
  function OriginalWindow()
    call OriginalWindowSize()
    call OriginalWindowPosition()
  endfunction
endif

if has("autocmd")
  " Disable the audible and visual bells
  au VimEnter * set vb t_vb=

  " set custom syntaxes here, before syntax enable
  au BufNewFile,BufRead *.applescript set syn+=applescript

  if MICROSOFT_CORP_SPECIFIC
    au BufWinEnter,BufNewFile,BufRead *.err set ft=err
    au BufWinEnter,BufNewFile,BufRead *.wrn set ft=wrn
    au! Syntax err
    au Syntax err runtime! syntax/err.vim
    au! Syntax wrn
    au Syntax wrn runtime! syntax/wrn.vim
  endif
endif

set backspace=2

call pathogen#infect()
call ipi#inspect()

if !RESTRICTED_MODE
  syntax enable
endif

set number
set autoindent

if has("autocmd")
  au BufNewFile,BufRead *.java compiler javac
  if(filereadable($HOME . "/vimfiles/autoload/javacomplete.vim"))
    au Filetype java setlocal omnifunc=javacomplete#Complete
  endif
endif

filetype on
filetype indent on
filetype plugin on

if has("autocmd")
  " lisp options
  aug ClojureZCM
  au ClojureZCM BufNewFile,BufRead *.clj set ft=lisp
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw <
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=catch,def,defn,defonce,doall
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=dorun,doseq,dosync,doto
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=monitor-enter,monitor-exit
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=ns,recur,throw,try,var
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw+=defn-,proxy
  au ClojureZCM BufNewFile,BufRead *.clj setlocal lw-=do
  au ClojureZCM BufNewFile,BufRead *.clj set lisp
  aug END

  " folding options
  "set foldcolumn=3
  "set fdn=2
  "aug zcm_folding
  "au zcm_folding BufNewFile,BufRead *.py,_vimrc,.vimrc set foldmethod=indent
  "au zcm_folding BufNewFile,BufRead *.java,*.[ch],*.cpp,*.hpp set foldmethod=syntax
  "au zcm_folding BufNewFile,BufRead * silent! %foldo!
  "au zcm_folding BufNewFile,BufRead * let b:open_all_folds_bfbn=1
  "au zcm_folding WinEnter __Tag_List__ set foldcolumn=0
  "au zcm_folding Syntax java* syn region myfold start="{" end="}" transparent fold
  "au zcm_folding Syntax java* syn sync fromstart
  "aug END

  " I just so happen to like Doxygen-style comments, so I'm going activate them by default here
  " (but, of course, only for compatible files with an autocommand)
  aug zcm_doxygen
  au zcm_doxygen BufNewFile,BufRead * let b:zcm_doxified = 0
  au zcm_doxygen BufNewFile,BufRead *.[ch],*.java,*.cpp,*.hpp call EnableDoxygenComments()
  aug END

  " Exclude vimrc from undofile overrides
  aug zcm_vimrc_prevent_undofile_override
  au zcm_vimrc_prevent_undofile_override BufNewFile,BufReadPre .vimrc sil! setlocal undodir=.
  au zcm_vimrc_prevent_undofile_override BufNewFile,BufReadPre _vimrc sil! setlocal undodir=.
  aug END
endif

" netrw Explore sort options...
let g:netrw_sort_sequence="[\\/]$,\\.h$,\\.c$,\\.cpp$,\\.java$,\\.class$,\\.py$,\\.pyc$,\\.[a-np-z]$,Makefile,Doxyfile,*,\\.info$,\\.swp$,\\.o$,\\.obj$,\\.bak$"

let s:cpo_save=&cpo
set cpo&vim
map! <xHome> <Home>
map! <xEnd> <End>
map! <S-xF4> <S-F4>
map! <S-xF3> <S-F3>
map! <S-xF2> <S-F2>
map! <S-xF1> <S-F1>
map! <xF4> <F4>
map! <xF3> <F3>
map! <xF2> <F2>
map! <xF1> <F1>
map <xHome> <Home>
map <xEnd> <End>
map <S-xF4> <S-F4>
map <S-xF3> <S-F3>
map <S-xF2> <S-F2>
map <S-xF1> <S-F1>
map <xF4> <F4>
map <xF3> <F3>
map <xF2> <F2>
map <xF1> <F1>
let &cpo=s:cpo_save
unlet s:cpo_save

set report=1

" custom mappings
nmap <C-C><C-N> :set invnumber<CR>
inoremap <F5> <C-R>=strftime("%x %X %Z")<CR>
nnoremap <F5> "=strftime("%x %X %Z")<CR>P
inoremap <S-F5> <C-R>=strftime("%b %d, %Y")<CR>
nnoremap <S-F5> "=strftime("%b %d, %Y")<CR>P
nnoremap <C-F7> :call ToggleDoxygenComments()<CR>

if (!RESTRICTED_MODE && filereadable($HOME . "/vimfiles/ipi/taglist/plugin/taglist.vim") && CheckIsCtagsExuberant())
  nnoremap <F7> :TlistToggle<CR>
  " taglist.vim options
  let Tlist_Compact_Format=1
  "let Tlist_Auto_Open=1
  let Tlist_Process_File_Always=1
  let Tlist_Exit_OnlyWindow=1
  aug ZCM_TaglistResize
  au ZCM_TaglistResize VimResized * call RecheckTaglistOrientationBounds()
  aug END
  call RecheckTaglistOrientationBounds()
  " we delay loading of the taglist plugin because it's slow and annoying if you
  " don't have exuberant ctags or the wrong ctags installed (throws errors every
  " time you open a file)
  IP taglist
endif
hi! link TagListFileName VisualNOS

set ut=10

" ts and sw need to be the same for << and >> to work correctly!
set ts=2
set sw=2

" always show the status line
set ls=2
set stl=%<%f\ #%{changenr()}\ %h%m%r%=%-14.(%l,%c%V%)\ %P

if MICROSOFT_CORP_SPECIFIC != 1
  set tw=80
endif

" only use spaces instead of tabs
set expandtab

let g:ZM_vimrc_did_complete_load=1

" vim:ai:et:ts=2:sw=2:tw=80
