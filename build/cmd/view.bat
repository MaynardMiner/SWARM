@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
powershell -executionpolicy bypass -command "%CMDDIR%/build/powershell/view.ps1 %*"