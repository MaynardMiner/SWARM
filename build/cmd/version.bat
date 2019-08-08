@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
set arg1=%1
set arg2=%2
set arg3=%3
set arg4=%4
pwsh -ExecutionPolicy Bypass -command "set-location ""%CMDDIR%\build\powershell\scripts""; .\version.ps1 -command !%arg1% -name !%arg2% -version !%arg3% -uri !%arg4%"