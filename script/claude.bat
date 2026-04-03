call :MAIN
exit /b

rem ------------------------------
:MAIN
  rem mkdir .claude
  if not exist "%USERPROFILE%\.claude" ( mkdir "%USERPROFILE%\.claude" )

  rem mklink settings.json
  call :MKLINK .\claude\settings.json .claude\settings.json

  rem mklink CLAUDE.md
  call :MKLINK .\claude\CLAUDE.md .claude\CLAUDE.md

  rem mklink hooks
  if exist "%USERPROFILE%\.claude\hooks" ( rmdir "%USERPROFILE%\.claude\hooks" )
  mklink /D "%USERPROFILE%\.claude\hooks" "%~dp0claude\hooks"

  rem copy CLAUDE.local.md
  call :COPY_NOT_EXISTS .\claude\CLAUDE.local.md .claude\CLAUDE.local.md
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

rem ------------------------------
:COPY_NOT_EXISTS
  set f_dest=%USERPROFILE%\%~2
  set f_src=%~dpnx1

  if exist "%f_dest%" ( exit /b )
  copy "%f_src%" "%f_dest%"

  set f_dest=
  set f_src=
exit /b
