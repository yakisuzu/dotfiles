scriptencoding utf-8
call g:Import('pack/MinpacManager')
call g:Import('pack/PluginsManager')
"---------------------------------------------------------------------------
" minpac
"---------------------------------------------------------------------------
let s:minpacManager = g:MinpacManager(g:dir_vim_home)
let s:pluginsManager = g:PluginsManager()

"---------------------------------------------------------------------------
" minpac install
let s:has_not_minpac = s:minpacManager.has_not_minpac()
if s:has_not_minpac
  call s:minpacManager.install_minpac()
endif

"---------------------------------------------------------------------------
" minpac load
if !s:minpacManager.init_minpac()
  echom 'minpac is not available.'
  finish
endif

"---------------------------------------------------------------------------
" minpac plugins load
if s:has_not_minpac
  " plugins install
  call s:minpacManager.init_plugins() | call s:minpacManager.update()
else
  " plugins load
  call s:pluginsManager.load_plugins()
endif

"---------------------------------------------------------------------------
" minpac command
command! PackUpdate call s:minpacManager.init_plugins() | call s:minpacManager.update() | call s:pluginsManager.load_plugins()
command! PackClean  call s:minpacManager.init_plugins() | call minpac#clean()
command! PackStatus call minpac#status()
command! PackLoadPlugins call s:pluginsManager.load_plugins()

