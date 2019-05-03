@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -ExecutionPolicy Bypass -command "set-location ""%CMDDIR%\build\powershell""; .\clear_watts.ps1 -Name %*"