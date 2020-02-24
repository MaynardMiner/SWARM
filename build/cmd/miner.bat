@echo off
pushd %~dp0
set arg1=%1
set arg2=%2
set arg3=%3
set arg4=%4
set arg5=%5
set arg6=%6
pwsh-preview -ExecutionPolicy Bypass -command "set-location ""%SWARM_DIR%\build\powershell\scripts""; .\miner.ps1 %*"