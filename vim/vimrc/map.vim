scriptencoding utf-8
"---------------------------------------------------------------------------
" キーマップ追加
"---------------------------------------------------------------------------
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

