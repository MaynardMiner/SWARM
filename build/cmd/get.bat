@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
set arg1=%1
set arg2=%2
set arg3=%3
set arg4=%4
set arg5=%5
set arg6=%6
powershell -executionpolicy bypass -command "%CMDDIR%/build/powershell/get.ps1 %arg1% %arg2% %arg3% %arg4% %arg5% %arg6%"