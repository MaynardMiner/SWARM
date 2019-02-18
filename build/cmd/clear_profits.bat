@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
set arg1=%1
powershell -executionpolicy bypass -command "%CMDDIR%/build/powershell/clear_profits.ps1 -Name %arg1%"
