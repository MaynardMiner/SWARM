@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -executionpolicy bypass -command "Set-Location '%CMDDIR%'; invoke-expression ""C:\PROGRA~1\NVIDIA~1\NVSMI\nvidia-smi.exe %*"" | Tee-Object -Variable NVSMI | Out-Null; $NVSMI | Out-Host"