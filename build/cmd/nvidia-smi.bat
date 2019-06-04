@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -executionpolicy bypass -command "Set-Location '%CMDDIR%'; invoke-expression "".\build\apps\nvidia-smi.exe %*"" | Tee-Object -Variable NVSMI | Out-Null; $NVSMI | Out-Host"