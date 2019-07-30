@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -executionpolicy bypass -command "Set-Location '%CMDDIR%'; invoke-expression "".\build\apps\features-win\features-win.exe"" | Tee-Object -Variable features | Out-Null; $features | Out-Host"