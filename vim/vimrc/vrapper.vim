scriptencoding utf-8
function! s:vrapperrc_write()
  let st_file = fnamemodify('~/_vrapperrc', ':p')
  let li_line = [
        \   '"update:' . strftime('%Y%m%d_%H%M')
        \ , 'set clipboard=unnamed'
        \ , 'set ignorecase'
        \ , 'set hlsearch'
        \ , 'set list'
        \ , ''
        \ , 'set gvimpath=' . (g:Is_mac() ? '/Applications/MacVim.app/Contents/MacOS/gvim' : 'gvim')
        \ , 'set gvimargs=+{line} --servername vrapper --remote-tab-silent {file}'
        \ , 'set contentassistmode'
        \ , ''
        \ , 'map <C-j> <Esc>'
        \ , 'noremap <Space>h ^'
        \ , 'noremap <Space>j <C-f>zz'
        \ , 'noremap <Space>k <C-b>zz'
        \ , 'noremap <Space>l $'
        \ , 'noremap \p "0p'
        \ , 'noremap \P "0P'
        \ , 'vnoremap * y/<C-r>0<CR>N'
        \ , 'vnoremap <Space>/ :s///g<Left><Left>'
        \ , 'inoremap <C-j> <Esc>'
        \ , 'nnoremap Y y$'
        \ , 'nnoremap n nzz'
        \ , 'nnoremap N Nzz'
        \ , 'nnoremap tg gT'
        \ , 'nnoremap zl 20zl'
        \ , 'nnoremap zh 20zh'
        \ , 'nnoremap * yiw/<C-r>0<CR>N'
        \ , 'nnoremap <Space>/ :%s///g<Left><Left>'
        \ , 'nnoremap <Space>o o<Esc>'
        \ , 'nnoremap <Space>d :bd<CR>'
        \ , ''
        \ , 'command So source ' . st_file
        \ , ''
        \ , '"http://help.eclipse.org/luna/topic/org.eclipse.platform.doc.isv/reference/api/org/eclipse/ui/IWorkbenchCommandConstants.html'
        \ , '"http://help.eclipse.org/luna/topic/org.eclipse.platform.doc.isv/reference/api/org/eclipse/ui/texteditor/IWorkbenchActionDefinitionIds.html'
        \ , '"http://help.eclipse.org/luna/topic/org.eclipse.platform.doc.isv/reference/api/org/eclipse/ui/texteditor/ITextEditorActionDefinitionIds.html'
        \ , '"http://help.eclipse.org/luna/topic/org.eclipse.jdt.doc.isv/reference/api/org/eclipse/jdt/ui/actions/IJavaEditorActionDefinitionIds.html'
        \ ]
  call writefile(li_line, st_file)
endfunction
call s:vrapperrc_write()

command! Vrapperrc tabe +set\ ft=vim ~/_vrapperrc

