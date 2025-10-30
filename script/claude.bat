call :MAIN
exit /b

rem ------------------------------
:MAIN
  rem mkdir .claude
  if not exist "%USERPROFILE%\.claude" ( mkdir "%USERPROFILE%\.claude" )

  rem mklink settings.json
  call :MKLINK .\claude\settings.json .claude\settings.json
exit /b

rem ------------------------------
:MKLINK
  set f_link=%USERPROFILE%\%~2
  set f_file=%~dpnx1

  if exist "%f_link%" ( del "%f_link%" )
  mklink "%f_link%" "%f_file%"

  set f_link=
  set f_file=
exit /b
