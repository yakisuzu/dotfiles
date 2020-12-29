scriptencoding utf-8
"---------------------------------------------------------------------------
" 検索の挙動に関する設定:"{{{
" 検索時に大文字小文字を無視 (noignorecase:無視しない)
set ignorecase
" 大文字小文字の両方が含まれている場合は大文字小文字を区別
set smartcase
"}}}

"---------------------------------------------------------------------------
" 編集に関する設定:"{{{
" タブの画面上での幅 ts
set tabstop=2
" タブをスペースに展開する (noexpandtab:展開しない)
set expandtab
" 自動的にインデントする (noautoindent:インデントしない)
set autoindent
" バックスペースでインデントや改行を削除できるようにする
set backspace=indent,eol,start
" 検索時にファイルの最後まで行ったら最初に戻らない (wrapscan:戻る) ws
set nowrapscan
" 括弧入力時に対応する括弧を表示 (noshowmatch:表示しない)
set showmatch
" コマンドライン補完するときに強化されたものを使う(参照 :help wildmenu)
set wildmenu
" テキスト挿入中の自動折り返しを日本語に対応させる
set formatoptions+=mM
"}}}

"---------------------------------------------------------------------------
" GUI固有ではない画面表示の設定:"{{{
" 行番号を非表示 (number:表示) nu
set nonumber
" ルーラーを表示 (noruler:非表示)
set ruler
" タブや改行を表示 (list:表示)
set list
" どの文字でタブや改行を表示するかを設定 lcs
set listchars=tab:>\ ,extends:<,trail:-,eol:@
" 長い行を折り返して表示 (nowrap:折り返さない)
set wrap
" 常にステータス行を表示 (詳細は:he laststatus)
set laststatus=2
" コマンドラインの高さ (Windows用gvim使用時はgvimrcを編集すること)
set cmdheight=2
" コマンドをステータス行に表示
set showcmd
" タイトルを表示
set title
"}}}

"---------------------------------------------------------------------------
" ファイル操作に関する設定:"{{{
" バックアップファイルを作成しない (次行の先頭の " を削除すれば有効になる)
set nobackup
" undoファイルを作成しない
set noundofile
" swapファイルを作成しない
set noswapfile
"}}}

"---------------------------------------------------------------------------
" プラットホーム依存の特別な設定:"{{{
" WinではPATHに$VIMが含まれていないときにexeを見つけ出せないので修正
if g:Is_mac()
  " Macではデフォルトの'iskeyword'がcp932に対応しきれていないので修正
  set iskeyword=@,48-57,_,128-167,224-235
endif
"}}}

"---------------------------------------------------------------------------
" 追加:"{{{
" 無名レジスタのかわりにクリップボードレジスタ '*' を使用 cb
set clipboard+=unnamed
" カーソルがある画面上の行をCursorLineで強調する|hl-CursorLine| cul
set cursorline
" タブページのラベルを表示 stal
set showtabline=2
" 隠れ状態にする hid
set hidden
" コマンドと検索の履歴数 hi
set history=500
" インデントに使われる空白の数 sw
set shiftwidth=2
" 折り畳みの種類 fdm
set foldmethod=marker
" 自動的に読み直す ar
set autoread
" 進数 nf
set nrformats=
" Vim内部で使われる文字エンコーディングを設定する enc
if g:Is_windows() && !has('gui')
  set encoding=cp932
else
  set encoding=utf8
endif
" ファイル編集時に考慮される文字エンコーディングリスト fencs
set fileencodings+=cp932
" <EOL> を、カレントバッファについて設定する ff
if &modifiable
  set fileformat=unix
endif
" ステータス行の表示内容を設定する stl
" < 先頭
" f 相対パス
" F フルパス
" m 修正フラグ
" r 読み込み専用フラグ
" h ヘルプバッファフラグ
" w プレビューウィンドウフラグ
" = 左寄せ項目と右寄せ項目の区切り
" l 何行目にカーソルがあるか
" L バッファ内の総行数
" c 何列目にカーソルがあるか
" V 実際に何列目にカーソルがあるか
" P 現在表示されているウィンドウ内のテキストが、ファイル内の何％の位置か
set statusline=%<%F%=%m%r%h%w%{'[enc='.&enc.']\ [fenc='.&fenc.'][ft='.&ft.'][ff='.&ff.']\ [et='.(&et?'space':'tab').'][sw='.&sw.'][ts='.&ts.']'}\ [col=%-7(%c%V%)][row=%l/%L(%4P)]
" 'wildchar' で指定されたキーで開始する補完モード
" full          次のマッチを完全に補完する。最後のマッチの次には元の文字列が使われ、その次は再び最初のマッチが補完される。
" longest       共通する最長の文字列までが補完される。それ以上長い文字列を補完できないときは、次の候補に移る。
" longest:full  "longest" と似ているが、'wildmenu' が有効ならばそれを開始する。
" list          複数のマッチがあるときは、全てのマッチを羅列する。
" list:full     複数のマッチがあるときは、全てのマッチを羅列し、最初のマッチを補完する。
" list:longest  複数のマッチがあるときは、全てのマッチを羅列し、共通する最長の文字列までが補完される。
set wildmode=longest:full,full
" ワイルドカードの展開時と、ファイル／ディレクトリ名の補完時に無視される wig
set wildignore+=tags
" テキスト表示の方法を変える dy
set display=lastline
" 前回の検索パターンを強調表示 hls
set hlsearch
"}}}

"---------------------------------------------------------------------------
" キーマップ追加"{{{
" ノーマル、ビジュアル、選択、演算待ち状態
map <C-j> <Esc>
map <Space> [space]
noremap [space]h ^
noremap [space]j <C-f>zz
noremap [space]k <C-b>zz
noremap [space]l $
noremap j gj
noremap k gk
noremap <Leader>p "0p
noremap <Leader>P "0P
" ビジュアル、選択
vnoremap * y/<C-r>0<CR>N
vnoremap [space]/ :s///g<Left><Left>
vnoremap <Leader>h y:tab<Space>help<Space><C-r>0
" 挿入、コマンドライン
noremap! <C-j> <Esc>
" ノーマル
nnoremap Y y$
nnoremap n nzz
nnoremap N Nzz
nnoremap tg gT
nnoremap zl 20zl
nnoremap zh 20zh
nnoremap * yiw/<C-r>0<CR>N
"TODO nnoremap <Esc>をマッピングすると、CLIのvimでバグる
nnoremap <C-l> :nohlsearch<CR>:checktime<CR><C-l>
nnoremap [space]<Tab> <C-w><C-w>
nnoremap [space]/ :%s///g<Left><Left>
nnoremap [space]o o<Esc>
nnoremap [space]d :bd<CR>
nnoremap <Leader>h yiw:tab<Space>help<Space><C-r>0
nnoremap <C-]> g<C-]>
"}}}

"---------------------------------------------------------------------------
" コマンド追加"{{{
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
"}}}

"---------------------------------------------------------------------------
" vim script"{{{
cd ~
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
"}}}

