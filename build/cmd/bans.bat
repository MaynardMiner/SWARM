@echo off
pushd %~dp0
pwsh -ExecutionPolicy Bypass -command "set-location ""%SWARM_DIR%\build\powershell\scripts""; .\bans.ps1 %*"