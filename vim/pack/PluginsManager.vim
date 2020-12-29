scriptencoding utf-8

let s:hooks = {}
"---------------------------------------------------------------------------
function! s:hooks.vital() abort
  let g:VMfile = vital#vital#import('System.File')
  let g:VMran  = vital#vital#import('Random')

  command! -nargs=1 -complete=file Open call g:VMfile.open(<q-args>)
  command! OpenClipbord echom 'open ' . @+ | call g:VMfile.open(@+)
  command! OpenParenthese exe 'normal "oyi)' | echom 'open ' . @o | call g:VMfile.open(@o)
endfunction

"---------------------------------------------------------------------------
function! s:hooks.shaberu() abort
  function! g:Shaberu_say_print(st_arg) abort
    echom a:st_arg
    " TODO ちょっと動かない
    " call shaberu#say(a:st_arg)
  endfunction

  function! g:Say_random(li_str) abort
    call g:Shaberu_say_print(g:VMran.sample(a:li_str))
  endfunction

  augroup shaberu_vimrc
    autocmd!
    autocmd VimEnter * call g:Say_random(['ビムへようこそ', 'ご注文はビムですか', 'ビ、ビムなんかじゃないんだからね', 'イーマックスへようこそ', 'ビムです', 'ビムではありません'])
    autocmd MenuPopup * call g:Say_random(['そんなにマウスが好きですか'])
    autocmd VimLeavePre * call g:Say_random(['お疲れ様でした。進捗どうですか', '終了します'])
  augroup END
endfunction

"---------------------------------------------------------------------------
function! s:hooks.open_browser() abort
  command! OpenBrowserCurrent execute "OpenBrowser" "file:///" . expand('%:p:gs?\\?/?')
endfunction

"---------------------------------------------------------------------------
function! s:hooks.vim_quickrun() abort
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
endfunction

"---------------------------------------------------------------------------
function! s:hooks.syntastic() abort
  "let g:syntastic_debug = 3
  let g:syntastic_auto_jump = 1

  let g:syntastic_java_checkers = []
  "let g:syntastic_java_javac_args = '-encoding UTF-8'
  let g:syntastic_javascript_checkers = ['eslint']
  let g:syntastic_typescript_checkers = ['eslint']
  let g:syntastic_sh_checkers = []

  function! s:get_filepath(file_name) abort
    let file_list = glob(substitute(system('cd ' . expand('%:p:h') . ' && npm bin'), '\n', '', '') . '/' . a:file_name . '*' ,1 ,1)
    if empty(file_list)
      return ''
    endif
    " if exists cmd, for win
    let file_idx = match(file_list, '.cmd')
    return (file_idx == -1) ? file_list[0] : file_list[file_idx]
  endfunction

  augroup syntastic_vimrc
    autocmd!
    autocmd FileType javascript let b:syntastic_javascript_eslint_exec = s:get_filepath('eslint')
    autocmd FileType typescript let b:syntastic_typescript_eslint_exec = s:get_filepath('eslint')
  augroup END
endfunction

"---------------------------------------------------------------------------
function! s:hooks.Align() abort
  " 0:for utf-8?
  " 1(default):fastest
  " 2:Number of spacing codepoints?
  " 3:Virtual length?, multi-byte support
  command! -nargs=1 SetAlignXstrlen let g:Align_xstrlen=<args>
endfunction

"---------------------------------------------------------------------------
function! s:hooks.incsearch() abort
  map /  <Plug>(incsearch-forward)
  map ?  <Plug>(incsearch-backward)
  " for mac
  "map g/ <Plug>(incsearch-stay)
endfunction

"---------------------------------------------------------------------------
function! s:hooks.indentLine() abort
  let g:indentLine_color_gui='#808080'
endfunction

"---------------------------------------------------------------------------
function! s:hooks.unite() abort
  " init unite bookmark
  call unite#sources#bookmark#define()

  command! UBuffer Unite buffer

  function! s:unite_vimgrep(...) abort
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
  endfunction
  command! -nargs=+ UVimgrep call s:unite_vimgrep(<f-args>)

  " add unite action execute
  let di_action = {
        \ 'is_selectable' : 1,
        \ }
  function! di_action.func(li_c) abort
    for di_c in a:li_c
      call g:VMfile.open(di_c.action__path)
    endfor
  endfunction
  call unite#custom#action('jump_list', 'execute', di_action)
  function! s:filetype_unite() abort
    nnoremap <silent><buffer><expr> x unite#do_action('execute')
  endfunction

  augroup unite_vimrc
    autocmd!
    autocmd FileType unite call s:filetype_unite()
  augroup END
endfunction

"---------------------------------------------------------------------------
function! s:hooks.unite_bookmarkamazing() abort
  " init unite bookmarkamazing
  call unite#sources#bookmarkamazing#define()

  function! s:unite_bookmarkamazing_comp(A,L,P) abort
    return unite#sources#bookmarkamazing#get_bookmark_file_complete_list(a:A, a:L, a:P, ['*'])
  endfunction
  function! s:unite_bookmarkamazing_open(st_arg, st_default) abort
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
  endfunction
  command! -nargs=? -complete=customlist,s:unite_bookmarkamazing_comp
        \ UBookmarkA call s:unite_bookmarkamazing_open(<q-args>, 'default')
endfunction

"---------------------------------------------------------------------------
function! s:hooks.vimfiler() abort
  let g:vimfiler_as_default_explorer = 1
  call vimfiler#custom#profile('default', 'context', {
        \   'auto_cd' : 1
        \ , 'edit_action' : 'tabopen'
        \ , 'sort_type' : 'filename'
        \ })
  command! -nargs=? VFexplorer VimFiler -explorer -simple -edit-action=open <args>

  function! s:filetype_vimfiler() abort
    " change keymap t to o
    unmap <buffer> t
    unmap <buffer> T
    nmap <buffer> o <Plug>(vimfiler_expand_tree)
    nmap <buffer> O <Plug>(vimfiler_expand_tree_recursive)
  endfunction
  augroup vimfiler_vimrc
    autocmd!
    autocmd FileType vimfiler call s:filetype_vimfiler()
  augroup END
endfunction

"---------------------------------------------------------------------------
function! s:hooks.vim_operator_surround() abort
  map <silent> <Leader>sa <Plug>(operator-surround-append)
  map <silent> <Leader>sd <Plug>(operator-surround-delete)
  map <silent> <Leader>sr <Plug>(operator-surround-replace)
endfunction

"---------------------------------------------------------------------------
function! s:hooks.operator_camelize() abort
  map <silent> <Leader>c <Plug>(operator-camelize)
  map <silent> <Leader>C <Plug>(operator-decamelize)
endfunction

"---------------------------------------------------------------------------
function! s:hooks.typescript_vim() abort
  let g:typescript_compiler_binary = 'tsc'
endfunction

"---------------------------------------------------------------------------
function! s:hooks.vim_go() abort
  let g:go_highlight_functions = 1
  let g:go_highlight_methods = 1
  let g:go_highlight_structs = 1
  let g:go_highlight_interfaces = 1
  let g:go_highlight_operators = 1
  let g:go_highlight_build_constraints = 1
endfunction

"---------------------------------------------------------------------------
function! g:PluginsManager() abort
  let s:pm = {}
  "---------------------------------------------------------------------------
  function! s:pm.load_plugins() abort
    " Additional plugins.
    packadd vital.vim | call s:hooks.vital()
    if g:Is_mac()
      packadd shaberu.vim | call s:hooks.shaberu() " depends vital.vim
    endif
    packadd open-browser.vim | call s:hooks.open_browser()
    packadd previm " depends open-browser.vim
    packadd vim-quickrun | call s:hooks.vim_quickrun()
    packadd syntastic | call s:hooks.syntastic()
    packadd Align | call s:hooks.Align()
    packadd clever-f.vim
    packadd incsearch.vim | call s:hooks.incsearch()
    packadd indentLine | call s:hooks.indentLine()
    packadd restart.vim

    packadd unite.vim | call s:hooks.unite()
    packadd unite-quickfix " depends unite.vim
    packadd unite-bookmarkamazing | call s:hooks.unite_bookmarkamazing() " depends unite.vim
    packadd vimfiler.vim | call s:hooks.vimfiler() " depends unite.vim

    packadd vim-operator-user
    packadd vim-operator-surround | call s:hooks.vim_operator_surround() " depends vim-operator-user
    packadd operator-camelize.vim | call s:hooks.operator_camelize() " depends vim-operator-user

    packadd vim-textobj-user
    packadd vim-textobj-function " depends vim-textobj-user

    augroup lazy_plugins
      autocmd!
      autocmd FileType typescript packadd typescript-vim | call s:hooks.typescript_vim()
      " TODO wait 3.6
      " autocmd FileType python packadd jedi-vim
      " autocmd FileType python packadd flake8-vim
      " autocmd FileType python packadd vim-python-pep8-indent
      autocmd FileType go packadd vim-go | call s:hooks.vim_go()
    augroup END
  endfunction

  return s:pm
endfunction

