@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -executionpolicy bypass -command "& ""%CMDDIR%/build/powershell/active.ps1"""
