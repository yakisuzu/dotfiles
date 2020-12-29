scriptencoding utf-8
"---------------------------------------------------------------------------
" minpac
"---------------------------------------------------------------------------
let g:dir_minpac = g:dir_home . '/pack/minpac'
let g:dir_minpac_opt = g:dir_minpac . '/opt'
let &packpath = expand(g:dir_home) . ',' . &packpath

function! s:PackInitMinpac() abort "{{{
  packadd minpac
  call minpac#init()
  call minpac#add('k-takata/minpac', {'type': 'opt'})
  " 初期化成功
  return exists('g:loaded_minpac')
endfunction "}}}
function! s:PackInitPlugins() abort "{{{
  let op = {'type': 'opt'}
  " for utility "{{{
  call minpac#add('vim-jp/vital.vim', op)
  call minpac#add('tyru/open-browser.vim', op)
  call minpac#add('yakisuzu/previm', op)
  call minpac#add('thinca/vim-quickrun', op)
  call minpac#add('scrooloose/syntastic', op)
  call minpac#add('vim-scripts/Align', op)
  call minpac#add('rhysd/clever-f.vim', op)
  call minpac#add('haya14busa/incsearch.vim', op)
  call minpac#add('Yggdroot/indentLine', op)
  call minpac#add('tyru/restart.vim', op)
  call minpac#add('supermomonga/shaberu.vim', op)
  "}}}
  " for unite "{{{
  call minpac#add('Shougo/unite.vim', op)
  call minpac#add('osyo-manga/unite-quickfix', op)
  call minpac#add('yakisuzu/unite-bookmarkamazing', op)
  call minpac#add('Shougo/vimfiler.vim', op)
  "}}}
  " for operator "{{{
  call minpac#add('kana/vim-operator-user', op)
  call minpac#add('rhysd/vim-operator-surround', op)
  call minpac#add('tyru/operator-camelize.vim', op)
  "}}}
  " for textobj "{{{
  call minpac#add('kana/vim-textobj-user', op)
  call minpac#add('kana/vim-textobj-function', op)
  "}}}
  " for typescript "{{{
  call minpac#add('leafgarland/typescript-vim', op)
  "}}}
  " for python "{{{
  call minpac#add('davidhalter/jedi-vim', op)
  call minpac#add('andviro/flake8-vim', op)
  call minpac#add('hynek/vim-python-pep8-indent', op)
  "}}}
  " for go "{{{
  call minpac#add('fatih/vim-go', op)
  "}}}
endfunction "}}}
function! s:PackUpdate() abort "{{{
  " 重いので任意のタイミングで実行 + 初回だけ実行
  call minpac#update('', {'do': 'echom "Finish plugins update. do :qa and restart"'})
endfunction "}}}
function! s:PackLoadPlugins() abort "{{{
  function! s:hook_vital() "{{{
    let g:VMfile = vital#vital#import('System.File')
    let g:VMran  = vital#vital#import('Random')

    command! -nargs=1 -complete=file Open call g:VMfile.open(<q-args>)
    command! OpenClipbord echom 'open ' . @+ | call g:VMfile.open(@+)
    command! OpenParenthese exe 'normal "oyi)' | echom 'open ' . @o | call g:VMfile.open(@o)
  endfunction "}}}
  function! s:hook_shaberu() "{{{
    function! g:Shaberu_say_print(st_arg)
      echom a:st_arg
      " TODO ちょっと動かない
      " call shaberu#say(a:st_arg)
    endfunction

    function! g:Say_random(li_str)
      call g:Shaberu_say_print(g:VMran.sample(a:li_str))
    endfunction

    augroup shaberu_vimrc
      autocmd!
      autocmd VimEnter * call g:Say_random(['ビムへようこそ', 'ご注文はビムですか', 'ビ、ビムなんかじゃないんだからね', 'イーマックスへようこそ', 'ビムです', 'ビムではありません'])
      autocmd MenuPopup * call g:Say_random(['そんなにマウスが好きですか'])
      autocmd VimLeavePre * call g:Say_random(['お疲れ様でした。進捗どうですか', '終了します'])
    augroup END
  endfunction "}}}
  function! s:hook_open_browser() "{{{
    command! OpenBrowserCurrent execute "OpenBrowser" "file:///" . expand('%:p:gs?\\?/?')
  endfunction "}}}
  function! s:hook_vim_quickrun() "{{{
    let g:quickrun_config = {
          \  '_': {
          \    'runner': 'job',
          \  },
          \  'java': {
          \    'exec': ['javac -encoding UTF-8 %o %s', '%c -Dfile.encoding=UTF8 %s:t:r %a'],
          \    'hook/output_encode/encoding': 'cp932',
          \  },
          \}

    if g:Is_windows()
      let g:quickrun_config = extend(g:quickrun_config, {
            \  'cs/csc': {
            \    'command': 'C:/Windows/Microsoft.NET/Framework64/v4.0.30319/csc.exe',
            \  },
            \})
    endif
  endfunction "}}}
  function! s:hook_syntastic() "{{{
    "let g:syntastic_debug = 3
    let g:syntastic_auto_jump = 1

    let g:syntastic_java_checkers = []
    "let g:syntastic_java_javac_args = '-encoding UTF-8'
    let g:syntastic_javascript_checkers = ['eslint']
    let g:syntastic_typescript_checkers = ['eslint']
    let g:syntastic_sh_checkers = []

    function! s:get_filepath(file_name) "{{{
      let file_list = glob(substitute(system('cd ' . expand('%:p:h') . ' && npm bin'), '\n', '', '') . '/' . a:file_name . '*' ,1 ,1)
      if empty(file_list)
        return ''
      endif
      " if exists cmd, for win
      let file_idx = match(file_list, '.cmd')
      return (file_idx == -1) ? file_list[0] : file_list[file_idx]
    endfunction "}}}

    augroup syntastic_vimrc "{{{
      autocmd!
      autocmd FileType javascript let b:syntastic_javascript_eslint_exec = s:get_filepath('eslint')
      autocmd FileType typescript let b:syntastic_typescript_eslint_exec = s:get_filepath('eslint')
    augroup END "}}}
  endfunction "}}}
  function! s:hook_Align() "{{{
    " 0:for utf-8?
    " 1(default):fastest
    " 2:Number of spacing codepoints?
    " 3:Virtual length?, multi-byte support
    command! -nargs=1 SetAlignXstrlen let g:Align_xstrlen=<args>
  endfunction "}}}
  function! s:hook_incsearch() "{{{
    map /  <Plug>(incsearch-forward)
    map ?  <Plug>(incsearch-backward)
    " for mac
    "map g/ <Plug>(incsearch-stay)
  endfunction "}}}
  function! s:hook_indentLine() "{{{
    let g:indentLine_color_gui='#808080'
  endfunction "}}}

  function! s:hook_unite() "{{{
    " init unite bookmark
    call unite#sources#bookmark#define()

    command! UBuffer Unite buffer

    function! s:unite_vimgrep(...) "{{{
      let li_args = []
      if a:0 == 1
        let li_args = ['*', a:1]
      elseif a:0 ==2
        let li_args = [a:1, a:2]
      else
        echomsg 'args count is fail'
        return 1
      endif

      let @/ = li_args[1]
      let li_cmd = [
            \   'Unite'
            \ , 'vimgrep:./**/*' . li_args[0] . ':' . li_args[1]
            \ , '-auto-preview'
            \ , '-vertical-preview'
            \ , '-no-quit'
            \ , '-tab'
            \ , '-default-action=tabopen'
            \ ]
      silent exe join(li_cmd)
    endfunction "}}}
    command! -nargs=+ UVimgrep call s:unite_vimgrep(<f-args>)

    " add unite action execute "{{{
    let di_action = {
          \ 'is_selectable' : 1,
          \ }
    function! di_action.func(li_c)
      for di_c in a:li_c
        call g:VMfile.open(di_c.action__path)
      endfor
    endfunction
    call unite#custom#action('jump_list', 'execute', di_action) "}}}
    function! s:filetype_unite() "{{{
      nnoremap <silent><buffer><expr> x unite#do_action('execute')
    endfunction "}}}

    augroup unite_vimrc "{{{
      autocmd!
      autocmd FileType unite call s:filetype_unite()
    augroup END "}}}
  endfunction "}}}
  function! s:hook_unite_bookmarkamazing() "{{{
    " init unite bookmarkamazing
    call unite#sources#bookmarkamazing#define()

    function! s:unite_bookmarkamazing_comp(A,L,P) "{{{
      return unite#sources#bookmarkamazing#get_bookmark_file_complete_list(a:A, a:L, a:P, ['*'])
    endfunction "}}}
    function! s:unite_bookmarkamazing_open(st_arg, st_default) "{{{
      if &ft == 'vimfiler'
        call unite#custom#default_action('directory', 'vimfiler')
      else
        call unite#custom#default_action('directory', 'tabvimfiler')
      endif

      let st_file = empty(a:st_arg) ? a:st_default : a:st_arg
      let li_cmd = [
            \   'Unite'
            \ , 'bookmarkamazing:' . st_file
            \ , '-vertical'
            \ , '-direction=leftabove'
            \ , '-winwidth=60'
            \ ]
      silent exe join(li_cmd)
    endfunction "}}}
    command! -nargs=? -complete=customlist,s:unite_bookmarkamazing_comp
          \ UBookmarkA call s:unite_bookmarkamazing_open(<q-args>, 'default')
  endfunction "}}}
  function! s:hook_vimfiler() "{{{
    let g:vimfiler_as_default_explorer = 1
    call vimfiler#custom#profile('default', 'context', {
          \   'auto_cd' : 1
          \ , 'edit_action' : 'tabopen'
          \ , 'sort_type' : 'filename'
          \ })
    command! -nargs=? VFexplorer VimFiler -explorer -simple -edit-action=open <args>

    function! s:filetype_vimfiler() "{{{
      " change keymap t to o
      unmap <buffer> t
      unmap <buffer> T
      nmap <buffer> o <Plug>(vimfiler_expand_tree)
      nmap <buffer> O <Plug>(vimfiler_expand_tree_recursive)
    endfunction "}}}
    augroup vimfiler_vimrc "{{{
      autocmd!
      autocmd FileType vimfiler call s:filetype_vimfiler()
    augroup END "}}}
  endfunction "}}}

  function! s:hook_vim_operator_surround() "{{{
    map <silent> <Leader>sa <Plug>(operator-surround-append)
    map <silent> <Leader>sd <Plug>(operator-surround-delete)
    map <silent> <Leader>sr <Plug>(operator-surround-replace)
  endfunction "}}}
  function! s:hook_operator_camelize() "{{{
    map <silent> <Leader>c <Plug>(operator-camelize)
    map <silent> <Leader>C <Plug>(operator-decamelize)
  endfunction "}}}

  function! s:hook_typescript_vim() "{{{
    let g:typescript_compiler_binary = 'tsc'
  endfunction "}}}
  function! s:hook_vim_go() "{{{
    let g:go_highlight_functions = 1
    let g:go_highlight_methods = 1
    let g:go_highlight_structs = 1
    let g:go_highlight_interfaces = 1
    let g:go_highlight_operators = 1
    let g:go_highlight_build_constraints = 1
  endfunction "}}}

  " Additional plugins.
  packadd vital.vim | call s:hook_vital()
  if g:Is_mac()
    packadd shaberu.vim | call s:hook_shaberu() " depends vital.vim
  endif
  packadd open-browser.vim | call s:hook_open_browser()
  packadd previm " depends open-browser.vim
  packadd vim-quickrun | call s:hook_vim_quickrun()
  packadd syntastic | call s:hook_syntastic()
  packadd Align | call s:hook_Align()
  packadd clever-f.vim
  packadd incsearch.vim | call s:hook_incsearch()
  packadd indentLine | call s:hook_indentLine()
  packadd restart.vim

  packadd unite.vim | call s:hook_unite()
  packadd unite-quickfix " depends unite.vim
  packadd unite-bookmarkamazing | call s:hook_unite_bookmarkamazing() " depends unite.vim
  packadd vimfiler.vim | call s:hook_vimfiler() " depends unite.vim

  packadd vim-operator-user
  packadd vim-operator-surround | call s:hook_vim_operator_surround() " depends vim-operator-user
  packadd operator-camelize.vim | call s:hook_operator_camelize() " depends vim-operator-user

  packadd vim-textobj-user
  packadd vim-textobj-function " depends vim-textobj-user

  augroup lazy_plugins
    autocmd!
    autocmd FileType typescript packadd typescript-vim | call s:hook_typescript_vim()
    " TODO wait 3.6
    " autocmd FileType python packadd jedi-vim
    " autocmd FileType python packadd flake8-vim
    " autocmd FileType python packadd vim-python-pep8-indent
    autocmd FileType go packadd vim-go | call s:hook_vim_go()
  augroup END
endfunction "}}}
" minpac install "{{{
let s:requireMinpacInitialized = empty(glob(g:dir_minpac_opt))
if s:requireMinpacInitialized
  " Not installed
  echom 'Start install minpac.'
  let dir_minpac_git = expand(g:dir_minpac_opt . '/minpac')
  call system('git clone https://github.com/k-takata/minpac.git ' . dir_minpac_git)
  echom 'Finish install minpac !!!'
endif "}}}
" minpac load "{{{
if !s:PackInitMinpac()
  echom 'minpac is not available.'
  finish
endif "}}}
" minpac plugins initialize load "{{{
if s:requireMinpacInitialized
  call s:PackInitPlugins() | call s:PackUpdate()
else
  call s:PackLoadPlugins()
endif "}}}


" minpac command
command! PackUpdate call s:PackInitPlugins() | call s:PackUpdate() | call s:PackLoadPlugins()
command! PackClean  call s:PackInitPlugins() | call minpac#clean()
command! PackStatus call minpac#status()

