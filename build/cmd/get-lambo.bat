@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
powershell -executionpolicy bypass -command "%CMDDIR%/build/data/timedata.ps1"