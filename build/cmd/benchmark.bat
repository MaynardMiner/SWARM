@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
set arg1=%1
set arg2=%2
set arg3=%3
powershell -executionpolicy bypass -command "%CMDDIR%/build/powershell/benchmark.ps1 %arg1% %arg2% %arg3%"