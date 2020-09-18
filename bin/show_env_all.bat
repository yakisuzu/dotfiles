@echo off
echo Process Environments
echo --------------------
powershell -ExecutionPolicy unrestricted -Command "[Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Process).GetEnumerator()|foreach{Write-Host $_.Name = $_.Value }"
echo.

echo Machine Environments
echo --------------------
powershell -ExecutionPolicy unrestricted -Command "[Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::Machine).GetEnumerator()|foreach{Write-Host $_.Name = $_.Value }"
echo.

echo User Environments
echo -----------------
powershell -ExecutionPolicy unrestricted -Command "([Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::User).GetEnumerator()|foreach{Write-Host $_.Name = $_.Value })"
