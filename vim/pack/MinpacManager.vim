scriptencoding utf-8

function! g:MinpacManager(vim_home) abort
  let s:mm = {}
  let s:dir_minpac_opt = a:vim_home . '/pack/minpac/opt'

  "---------------------------------------------------------------------------
  function! s:mm.has_not_minpac() abort
    return empty(glob(s:dir_minpac_opt))
  endfunction

  "---------------------------------------------------------------------------
  function! s:mm.install_minpac() abort
    echom 'Start install minpac.'
    let dir_minpac = expand(s:dir_minpac_opt . '/minpac')
    call system('git clone https://github.com/k-takata/minpac.git ' . dir_minpac)
    echom 'Finish install minpac !!!'
  endfunction

  "---------------------------------------------------------------------------
  function! s:mm.init_minpac() abort
    packadd minpac
    call minpac#init()
    call minpac#add('k-takata/minpac', {'type': 'opt'})
    " 初期化成功
    return exists('g:loaded_minpac')
  endfunction

  "---------------------------------------------------------------------------
  function! s:mm.init_plugins() abort
    let op = {'type': 'opt'}
    " for utility
    call minpac#add('vim-jp/vital.vim', op)
    call minpac#add('tyru/open-browser.vim', op)
    call minpac#add('yakisuzu/previm', op)
    call minpac#add('thinca/vim-quickrun', op)
    call minpac#add('scrooloose/nerdtree', op)
    call minpac#add('scrooloose/syntastic', op)
    call minpac#add('vim-scripts/Align', op)
    call minpac#add('rhysd/clever-f.vim', op)
    call minpac#add('haya14busa/incsearch.vim', op)
    call minpac#add('Yggdroot/indentLine', op)
    call minpac#add('tyru/restart.vim', op)

    " for unite
    call minpac#add('Shougo/unite.vim', op)
    call minpac#add('osyo-manga/unite-quickfix', op)
    call minpac#add('yakisuzu/unite-bookmarkamazing', op)
    call minpac#add('Shougo/vimfiler.vim', op)
    " for operator
    call minpac#add('kana/vim-operator-user', op)
    call minpac#add('rhysd/vim-operator-surround', op)
    call minpac#add('tyru/operator-camelize.vim', op)
    " for textobj
    call minpac#add('kana/vim-textobj-user', op)
    call minpac#add('kana/vim-textobj-function', op)
    " for typescript
    call minpac#add('leafgarland/typescript-vim', op)
    " for python
    call minpac#add('davidhalter/jedi-vim', op)
    call minpac#add('andviro/flake8-vim', op)
    call minpac#add('hynek/vim-python-pep8-indent', op)
    " for go
    call minpac#add('fatih/vim-go', op)
  endfunction

  "---------------------------------------------------------------------------
  function! s:mm.update() abort
    " 重いので任意のタイミングで実行 + 初回だけ実行
    call minpac#update('', {'do': 'echom "Finish plugins update. do :qa and restart"'})
  endfunction

  return s:mm
endfunction

