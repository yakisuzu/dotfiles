scriptencoding utf-8
"---------------------------------------------------------------------------
" ウインドウに関する設定:
"---------------------------------------------------------------------------
" ウインドウの幅
set columns=200
" ウインドウの高さ
set lines=50
" 画面を黒地に白にする (次行の先頭の " を削除すれば有効になる)
" colorscheme evening
colorscheme desert

if g:Is_windows()
  " 透過度
  autocmd GUIenter * set transparency=220
  " フォントサイズ
  autocmd GUIenter * set guifont=MS_Gothic:h14:cSHIFTJIS
endif
if g:Is_mac()
  " 透過度
  set transparency=15
  " フォントサイズ
  set guifont=Ricty-Bold:h18
endif

" guiの挙動を変更 go
set guioptions-=m
set guioptions-=T
set guioptions+=b
set guioptions+=h

"augroup highlightCr
"  autocmd!
"  autocmd ColorScheme * highlight HiCr term=underline ctermbg=DarkGreen guibg=DarkGreen
"  autocmd BufWinEnter * match HiCr /\r/
"augroup END

