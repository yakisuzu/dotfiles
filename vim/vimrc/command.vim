scriptencoding utf-8
"---------------------------------------------------------------------------
" vimrc
command! VimrcSo so ~/_vimrc | so ~/_gvimrc

command! VimrcOpenLocal tabe ~/_vimrc_local
command! -nargs=? -complete=customlist,s:comp_vimrc_open
      \ VimrcOpen call s:exe_vimrc_open(g:dir_vimrc, <q-args>)

function! s:comp_vimrc_open(ArgLead, CmdLine, CursorPos)
  " 正規表現は^M nomagicで
  return (g:dir_vimrc . '/**')
    \ ->glob()
    \ ->split('\n')
    \ ->filter({i, path -> path =~ 'vim$' && path !~ 'local.vim$' })
    \ ->map({i, path -> path->fnamemodify(':~')->substitute('\M' . g:dir_vimrc . '/', '', '')})
    \ ->filter({i, path -> path =~ '\M' . a:ArgLead})
    \ ->sort()
endfunction

function! s:exe_vimrc_open(dir_vimrc, file)
  let path = a:dir_vimrc . '/' . a:file
  if path->glob()->empty()
    echom 'Not Found! ' . path
  else
    exe ['tabe', path]->join()
  endif
endfunction

"---------------------------------------------------------------------------
" editor
command! -nargs=1 -complete=help H tab h <args>
command! Bd bufdo bd!
command! -nargs=? -complete=file T tabe <args>
command! TA tab ball
command! MessageClear for n in range(200) | echom '' | endfor
command! CdCurrent if !expand('%:p:h')->glob()->empty() | cd %:p:h | endif
command! -nargs=1 System exe 'CdCurrent' | echo system(<q-args>)

command! SetWrap setl wrap | set ve=
command! SetWrapNo setl nowrap | set ve=all

command! EditUtf8 set enc=utf8 | e! ++enc=utf8 ++ff=unix
command! EditCp932 set enc=cp932 | e! ++enc=cp932 ++ff=dos

command! YankFileName let @+ = expand('%:p:t') | echo @+
command! YankFileNameSimple let @+ = expand('%:p:t:r') | echo @+
command! YankFullPath let @+ = expand('%:p') | echo @+
command! YankDir let @+ = expand('%:p:h') | echo @+
command! YankTime let @+ = strftime('%Y%m%d_%H%M_') | echo @+
command! YankToSlash let @+ = substitute(@+, '\\', '\/', 'g')
command! YankToYen let @+ = substitute(@+, '\/', '\\', 'g')

if !g:Is_windows()
  command! Wsudo w !sudo tee % > /dev/null
endif

"command! -nargs=1 SetCo set columns+=<args>
"command! -nargs=1 SetLines set lines+=<args>
"command! -nargs=1 SetSpLinesUp normal <args>-
"command! -nargs=1 SetSpLinesDown normal <args>+
"command! -nargs=1 SetSpCoRight normal <args>>
"command! -nargs=1 SetSpCoLeft normal <args><

"command! SetExpandtab setl et sw=2 ts=2
"command! SetExpandtabNo setl noet sw=4 ts=4

"---------------------------------------------------------------------------
" debug
command! -nargs=1 -complete=command DebugProfile call s:debug_profile(<q-args>)
function! s:debug_profile(cmd)
  cd ~
  profile start profile.log
  profile func *
  silent exe a:cmd
  qa!
endfunction

"function! g:Get_current_buf()
"  return getbufline(bufnr('%'), 1, '$')
"endfunction
"function! g:Set_current_buf(li_buf)
"  %d
"  return setline(1, a:li_buf)
"endfunction
"function! g:Open_args(st_path, ...)
"  if g:Is_windows()
"    silent exe join(['!start', '"' . a:st_path . '"', join(a:000)])
"  else
"    echom 'not support'
"  endif
"endfunction
"function! g:Call_python3(st_pyfile, ...)
"  exe 'python3 import sys; sys.argv = [' . join(a:000, ',') . ']'
"  exe 'py3file ' . a:st_pyfile
"endfunction
"function! g:Call_cscript(st_jsfile, ...)
"  return system(join(['cscript', '//NoLogo', a:st_jsfile, join(a:000), '|ruby', '-ne', '"puts $_.encode(%(UTF-8),%(Shift_JIS))"']))
"endfunction

