call :MAIN
exit /b

rem ------------------------------
:MAIN
  rem mkdir .claude
  if not exist "%USERPROFILE%\.claude" ( mkdir "%USERPROFILE%\.claude" )

  rem copy settings.json (base をテンプレートとして初回のみコピー。jq が無いため merge はしない)
  rem 旧 symlink が残っていたら削除して実体ファイル化する
  dir /a:l "%USERPROFILE%\.claude\settings.json" >nul 2>&1 && del "%USERPROFILE%\.claude\settings.json"
  call :COPY_NOT_EXISTS .\claude\settings.base.json .claude\settings.json

  rem mklink CLAUDE.md
  call :MKLINK .\claude\CLAUDE.md .claude\CLAUDE.md

  rem mklink hooks
  if exist "%USERPROFILE%\.claude\hooks" ( rmdir "%USERPROFILE%\.claude\hooks" )
  mklink /D "%USERPROFILE%\.claude\hooks" "%~dp0claude\hooks"

  rem mklink rules
  if exist "%USERPROFILE%\.claude\rules" ( rmdir "%USERPROFILE%\.claude\rules" )
  mklink /D "%USERPROFILE%\.claude\rules" "%~dp0claude\rules"

  rem mklink skills
  if exist "%USERPROFILE%\.claude\skills" ( rmdir "%USERPROFILE%\.claude\skills" )
  mklink /D "%USERPROFILE%\.claude\skills" "%~dp0claude\skills"

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
