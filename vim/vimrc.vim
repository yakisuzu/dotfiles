scriptencoding utf-8
cd ~
let g:dir_vimrc = '~/dotfiles/vim'
let g:dir_vim_home = '~/.vim'
if has('vim_starting')
  let &runtimepath .= ',' . g:dir_vim_home
endif
let &packpath = expand(g:dir_vim_home) . ',' . &packpath

function! g:Import(path) abort
  exe 'source ' . g:dir_vimrc . '/' . a:path . '.vim'
endfunction

call g:Import('vimrc/init')
call g:Import('vimrc/minpac')
call g:Import('vimrc/set')
call g:Import('vimrc/map')
call g:Import('vimrc/command')
"call g:Import('vimrc/vrapper')
call g:Import('vimrc/ideavim')
source ~/_vimrc_local
