@echo off
pushd %~dp0
pwsh -executionpolicy bypass -command "Set-Location '%SWARM_DIR%'; invoke-expression "".\build\apps\features-win\features-win.exe"" | Tee-Object -Variable features | Out-Null; $features | Out-Host"