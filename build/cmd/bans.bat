@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
set arg1=%1
set arg2=%2
powershell -executionpolicy bypass -command "%CMDDIR%/build/powershell/bans.ps1 %arg1% %arg2%"