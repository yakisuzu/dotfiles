scriptencoding utf-8
"---------------------------------------------------------------------------
function! g:Is_windows() abort
  let s:is_windows = has('win16') || has('win32') || has('win64')
  let s:is_cygwin = has('win32unix')
  return s:is_windows || s:is_cygwin
endfunction

"---------------------------------------------------------------------------
function! g:Is_mac() abort
  return !g:Is_windows()
        \ && (
        \   has('mac')
        \   || has('macunix')
        \   || has('gui_macvim')
        \   || (
        \     !executable('xdg-open')
        \     && system('uname') =~? '^darwin'
        \   )
        \ )
endfunction

"---------------------------------------------------------------------------
" vimrc_local init
if has('vim_starting')
  let local_file = fnamemodify('~/_vimrc_local', ':p')
  if empty(glob(local_file))
    call writefile([''], local_file)
  endif
endif

