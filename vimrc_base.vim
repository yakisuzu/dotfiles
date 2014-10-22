"---------------------------------------------------------------------------
" 編集に関する設定:"{{{
" タブの画面上での幅 ts
set tabstop=4
" 検索時にファイルの最後まで行ったら最初に戻る (nowrapscan:戻らない) ws
set nowrapscan
"}}}

"---------------------------------------------------------------------------
" GUI固有ではない画面表示の設定:"{{{
" 行番号を非表示 (number:表示) nu
set number
" タブや改行を表示 (list:表示)
set list
" どの文字でタブや改行を表示するかを設定 lcs
set listchars=tab:>\ ,extends:<,trail:-,eol:$
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
" 追加"{{{
" 無名レジスタのかわりにクリップボードレジスタ '*' を使用 cb
set clipboard=unnamed
" カーソルがある画面上の行をCursorLineで強調する|hl-CursorLine|。 cul
set cursorline
" タブページのラベルを表示 stal
set showtabline=2
" 隠れ状態にする hid
set hidden
" コマンドと検索の履歴数 hi
set history=500
" インデントに使われる空白の数 sw
set shiftwidth=4
" 折り畳みの種類 fdm
set foldmethod=marker
" ファイル編集時に考慮される文字エンコーディングリスト fencs
if has('vim_starting')
	set fileencodings+=cp932
endif
" 自動的に読み直す ar
set autoread
" 進数 nf
set nrformats=
"}}}

"---------------------------------------------------------------------------
" キーマップ追加"{{{
nnoremap <Esc><Esc> :nohlsearch<CR>
nnoremap <C-l> :checktime<CR><C-l>
nnoremap tg gT
nnoremap zl 20zl
nnoremap zh 20zh
"}}}

"---------------------------------------------------------------------------
" 自動コマンド追加"{{{
" ファイルタイプ更新
augroup markdown
	autocmd!
	au BufRead,BufNewFile *.md set nowrap
	au BufWritePre *.md call WritePre_md()

	function! WritePre_md()
		silent %s/\v[^ ]@<= $/  /ge

		let regexList=[]
		call add(regexList,'^')
		call add(regexList,'^---')
		call add(regexList,' {2}')
		call add(regexList,'^\|.+\|')

		let regexStr=''
		for regex in regexList
			if !empty(regexStr)
				let regexStr=regexStr.'|'
			endif
			let regexStr=regexStr.regex
		endfor
		let exeCom='v/\v('.regexStr.')$/normal A  '
		" echomsg exeCom
		silent exe exeCom
	endfunction
augroup END
"}}}

"---------------------------------------------------------------------------
" コマンド追加"{{{
command! -nargs=1 -complete=help H tab h <args>
command! -nargs=1 -complete=command RedirTab call Redir_tab(<q-args>)
command! -nargs=1 -complete=command DebugProfile call Debug_profile(<q-args>)
command! -nargs=1 ShTab call Sh_tab(<q-args>)

command! VimrcWSo w | so ~/vimrc/vimrc.vim
command! VimrcBase tabe ~/vimrc/vimrc_base.vim
command! VimrcNeoBundle tabe ~/vimrc/vimrc_neobundle.vim
command! GVimrcWSo w | so ~/vimrc/gvimrc.vim
command! GVimrcBase tabe ~/vimrc/gvimrc_base.vim

" ''(default):can move the cursor after the last character.
" all:Allow virtual editing in all modes.
command! -nargs=? SetVirtualEdit set virtualedit=<args>
command! -nargs=1 SetCo set columns+=<args>
command! -nargs=1 SetLines set lines+=<args>
command! -nargs=1 SetSpLinesUp normal <args>-
command! -nargs=1 SetSpLinesDown normal <args>+
command! -nargs=1 SetSpCoRight normal <args>>
command! -nargs=1 SetSpCoLeft normal <args><
command! SetEncUtf8 set encoding=utf-8
command! SetEncCp932 set encoding=cp932

command! GetEnc set encoding?


command! GitPull echo system("git pull")
command! GitCheckout echo system("git checkout ".expand("%:p"))
command! GitAdd echo system("git add ".expand("%:p"))
command! -nargs=* GitCommit echo system("git commit ".expand("%:p")." -m ".shellescape(<q-args>))
command! GitPush echo system("git push")

command! Bd bufdo bd!
command! -nargs=? -complete=file T tabe <args>
command! MessageClear for n in range(200) | echom "" | endfor

command! Wsudo w !sudo tee % > /dev/null
command! ShWebRootCh !. ~/.vim/sh/webroot_permission.sh
"}}}

"---------------------------------------------------------------------------
" vim script"{{{
cd ~

function! Redir_tab(cmd)
	redir @*>
	silent execute a:cmd
	redir END
	tabe | normal Pgg
endfunction

function! Debug_profile(cmd)
	cd ~
	profile start profile.log
	profile func *
	silent exe a:cmd
	qa!
endfunction

function! Sh_tab(cmd)
	exe 'tabe | r!'.a:cmd
endfunction

function! S_clip()
	%s//\=@+/ge
endfunction

function! Index_increment()
	%s/\v(^\t*)@<=\d{1,}\.@=/\=submatch(0)+1/ge
	"	for cnt in range(9,1,-1)
	"		exe '%s/\v(^\t*)@<='.cnt.'\.@=/'.expand(cnt+1).'/ge'
	"	endfo
endfunction

function! Index_decrement()
	%s/\v(^\t*)@<=\d{1,}\.@=/\=submatch(0)-1/ge
endfunction

let g:conv_md_codetype = ''
function! Conv_backlog_to_md()
	%s/\v^\*{3}\s?/### /ge
	%s/\v^\*{2}\s?/## /ge
	%s/\v^\*{1}\s?/# /ge
	%s/\v^\{code}/\='```'.g:conv_md_codetype/ge
	%s/\v^\{\/code}/```/ge
	%s/\v\s{1}$/  /ge
endfunction

function! Conv_md_to_backlog()
	%s/\v^\#{3}\s?/*** /ge
	%s/\v^\#{2}\s?/** /ge
	%s/\v^\#{1}\s?/* /ge
	exe '%s/\v^```'.g:conv_md_codetype.'/{code}/ge'
	%s/\v^```$/{\/code}/ge
	%s/\v\s{2}$/ /ge
endfunction

function! Git_filter_branch()
	!git filter-branch -f --env-filter "GIT_AUTHOR_NAME='yakisuzu';GIT_AUTHOR_EMAIL='yakisuzu@gmail.com';GIT_COMMITTER_NAME='yakisuzu';GIT_COMMITTER_EMAIL='yakisuzu@gmail.com';" HEAD
endfunction
"}}}

