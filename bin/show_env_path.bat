@echo off
echo Machine setting
echo ---------------
powershell -ExecutionPolicy unrestricted -Command "[Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine) -split \";\""
echo.

echo User setting
echo ------------
powershell -ExecutionPolicy unrestricted -Command "[Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::User) -split \";\""
