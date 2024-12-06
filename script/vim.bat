call :MAIN
exit /b

rem ------------------------------
:MAIN
  rem mklink file
  call :MKLINK .\vim\_vimrc.vim
  call :MKLINK .\vim\_vimrc_local.vim
  call :MKLINK .\vim\_gvimrc.vim
  call :MKLINK .\vim\.ideavimrc
  call :MKLINK .\vim\.vscodevimrc

  rem mklink dir
  for /F "usebackq" %%i in (`dir /AD /B /S .\vim\.vim\*`) do (
    call :MKLINK_DIR %%i
  )
exit /b

rem ------------------------------
:MKLINK
  set f_link=%USERPROFILE%\%~n1
  set f_file=%~dpnx1

  if exist "%f_link%" ( del "%f_link%" )
  mklink "%f_link%" "%f_file%"

  set f_link=
  set f_file=
exit /b

rem ------------------------------
:MKLINK_DIR
  set f_link=%USERPROFILE%\.vim\%~n1
  set f_dir=%~f1

  if exist "%f_link%" ( rmdir /s /q "%f_link%" )
  mklink /D "%f_link%" "%f_dir%"

  set f_link=
  set f_dir=
exit /b
