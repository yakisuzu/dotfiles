scriptencoding utf-8
function! s:ideavim_write()
  let st_file = fnamemodify('~/.ideavimrc', ':p')
  let li_line = [
        \   '"update:' . strftime('%Y%m%d_%H%M')
        \ , ''
        \ , 'set nowrapscan'
        \ , 'set clipboard+=unnamed'
        \ , 'set nrformats='
        \ , 'set hlsearch'
        \ , 'set ignorecase'
        \ , ''
        \ , 'map <C-j> <Esc>'
        \ , 'map <Space>h ^'
        \ , 'map <Space>j <C-f>zz'
        \ , 'map <Space>k <C-b>zz'
        \ , 'map <Space>l $'
        \ , 'map \p "0p'
        \ , 'map \P "0P'
        \ , 'map * y/<C-r>0<CR>N'
        \ , 'map <Space>/ :s///g<Left><Left>'
        \ , 'map Y y$'
        \ , 'map n nzz'
        \ , 'map N Nzz'
        \ , 'map tg gT'
        \ , 'map zl 20zl'
        \ , 'map zh 20zh'
        \ , 'map * yiw/<C-r>0<CR>N'
        \ , 'map <Space>/ :%s///g<Left><Left>'
        \ , 'map <Space>o o<Esc>'
        \ , 'map <Space>d :bd<CR>'
        \ , ''
        \ , '"https://github.com/JetBrains/ideavim'
        \ , '"https://github.com/JetBrains/ideavim/blob/master/src/com/maddyhome/idea/vim/package-info.java'
        \ ]
  call writefile(li_line, st_file)
endfunction
call s:ideavim_write()

command! Ideavimrc tabe +set\ ft=vim ~/.ideavimrc

