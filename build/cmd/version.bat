@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
set arg1=%1
set arg2=%2
set arg3=%3
set arg4=%4
set arg5=%5
pwsh -ExecutionPolicy Bypass -command "set-location ""%CMDDIR%\build\powershell""; .\version.ps1 -command !%arg1% -name !%arg2% -exe !%arg3% -version !%arg4% -uri !%arg5% -Platform windows"