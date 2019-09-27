@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -ExecutionPolicy Bypass -command "set-location ""%CMDDIR%\build\powershell\scripts""; .\bench.ps1 %*"