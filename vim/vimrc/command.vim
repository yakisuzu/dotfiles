scriptencoding utf-8
"---------------------------------------------------------------------------
" コマンド追加
command! -nargs=1 -complete=help H tab h <args>
command! -nargs=1 -complete=command DebugProfile call g:Debug_profile(<q-args>)

command! VimrcSo so ~/_vimrc
command! GVimrcSo so ~/_gvimrc
command! Vrapperrc tabe +set\ ft=vim ~/_vrapperrc
command! -nargs=? -complete=customlist,s:vimrc_comp
      \ VimrcOpen call s:vimrc_open(<q-args>, 'vimrc_base.vim')
command! -nargs=? -complete=customlist,s:gvimrc_comp
      \ GVimrcOpen call s:vimrc_open(<q-args>, 'gvimrc_base.vim')
command! VimrcLocalOpen tabe ~/_vimrc_local

function! s:vimrc_comp(A,L,P) "{{{
  return g:File_list(g:dir_vimrc . '/vimrc_*')
endfunction "}}}
function! s:gvimrc_comp(A,L,P) "{{{
  return g:File_list(g:dir_vimrc . '/gvimrc_*')
endfunction "}}}
function! s:vimrc_open(st_file, st_default_file) "{{{
  let st_exe_file = !empty(a:st_file) ? a:st_file : a:st_default_file
  let st_path = glob(g:dir_vimrc . '/' . st_exe_file)
  if !empty(st_path)
    exe join(['tabe', st_path])
  endif
endfunction "}}}

command! -nargs=1 SetCo set columns+=<args>
command! -nargs=1 SetLines set lines+=<args>
command! -nargs=1 SetSpLinesUp normal <args>-
command! -nargs=1 SetSpLinesDown normal <args>+
command! -nargs=1 SetSpCoRight normal <args>>
command! -nargs=1 SetSpCoLeft normal <args><

command! SetWrap setl wrap | set ve=
command! SetWrapNo setl nowrap | set ve=all
command! SetExpandtab setl et sw=2 ts=2
command! SetExpandtabNo setl noet sw=4 ts=4

command! EditUtf8 set enc=utf8 | e! ++enc=utf8 ++ff=unix
command! EditCp932 set enc=cp932 | e! ++enc=cp932 ++ff=dos

command! GetYankFileName let @+ = expand('%:p:t') | echo @+
command! GetYankFileNameSimple let @+ = expand('%:p:t:r') | echo @+
command! GetYankFullPath let @+ = expand('%:p') | echo @+
command! GetYankDir let @+ = expand('%:p:h') | echo @+
command! GetYankTime let @+ = strftime('%Y%m%d_%H%M_') | echo @+

command! Bd bufdo bd!
command! -nargs=? -complete=file T tabe <args>
command! TA tab ball
command! MClear for n in range(200) | echom '' | endfor
command! CdCurrent if !empty(glob(expand('%:p:h')))|cd %:p:h|endif
command! -nargs=1 System exe 'CdCurrent'|echo system(<q-args>)

command! ClipToSlash let @+ = substitute(@+, '\\', '\/', 'g')
command! ClipToYen let @+ = substitute(@+, '\/', '\\', 'g')

if !g:Is_windows()
  command! Wsudo w !sudo tee % > /dev/null
endif

"---------------------------------------------------------------------------
" vim script
function! g:Debug_profile(cmd)
  cd ~
  profile start profile.log
  profile func *
  silent exe a:cmd
  qa!
endfunction

function! g:Git_filter_branch()
  !git filter-branch -f --env-filter "GIT_AUTHOR_NAME='yakisuzu';GIT_AUTHOR_EMAIL='yakisuzu@gmail.com';GIT_COMMITTER_NAME='yakisuzu';GIT_COMMITTER_EMAIL='yakisuzu@gmail.com';" HEAD
endfunction

function! g:Update_tags(li_args)
  for st_arg in a:li_args
    if index(split(&tags, ','), st_arg) == -1
      let &tags .= ',' . st_arg
    endif
  endfor
endfunction

function! g:File_list(st_path)
  return sort(map(
        \ split(glob(a:st_path), '\n'),
        \ 'fnamemodify(v:val, ":t")'))
endfunction

function! g:Get_current_buf()
  return getbufline(bufnr('%'), 1, '$')
endfunction

function! g:Set_current_buf(li_buf)
  %d
  return setline(1, a:li_buf)
endfunction

function! g:Open_args(st_path, ...)
  if g:Is_windows()
    silent exe join(['!start', '"' . a:st_path . '"', join(a:000)])
  else
    echom 'not support'
  endif
endfunction

function! g:Call_python3(st_pyfile, ...)
  exe 'python3 import sys; sys.argv = [' . join(a:000, ',') . ']'
  exe 'py3file ' . a:st_pyfile
endfunction

function! g:Call_cscript(st_jsfile, ...)
  return system(join(['cscript', '//NoLogo', a:st_jsfile, join(a:000), '|ruby', '-ne', '"puts $_.encode(%(UTF-8),%(Shift_JIS))"']))
endfunction

