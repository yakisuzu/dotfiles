scriptencoding utf-8
"---------------------------------------------------------------------------
" 検索の挙動に関する設定:
" 検索時に大文字小文字を無視 (noignorecase:無視しない)
set ignorecase
" 大文字小文字の両方が含まれている場合は大文字小文字を区別
set smartcase

"---------------------------------------------------------------------------
" 編集に関する設定:
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

"---------------------------------------------------------------------------
" GUI固有ではない画面表示の設定:
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

"---------------------------------------------------------------------------
" ファイル操作に関する設定:
" バックアップファイルを作成しない (次行の先頭の " を削除すれば有効になる)
set nobackup
" undoファイルを作成しない
set noundofile
" swapファイルを作成しない
set noswapfile

"---------------------------------------------------------------------------
" プラットホーム依存の特別な設定:
" WinではPATHに$VIMが含まれていないときにexeを見つけ出せないので修正
if g:Is_mac()
  " Macではデフォルトの'iskeyword'がcp932に対応しきれていないので修正
  set iskeyword=@,48-57,_,128-167,224-235
endif

"---------------------------------------------------------------------------
" 追加:
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
let &encoding=(g:Is_windows() && !has('gui')) ? 'cp932' : 'utf8'
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

