@echo off
pushd %~dp0
pwsh-preview -ExecutionPolicy Bypass -command "set-location ""%SWARM_DIR%\build\powershell\scripts""; .\clear_watts.ps1 -Name %*"