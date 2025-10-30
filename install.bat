@echo off
pushd %~dp0

echo --------------------
echo init bash
call .\script\bash.bat

echo --------------------
echo init git
call .\script\git.bat

echo --------------------
echo init vim
call .\script\vim.bat

echo --------------------
echo init claude
call .\script\claude.bat

popd
pause
