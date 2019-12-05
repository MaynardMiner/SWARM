@echo off

REM ************Reset HiveOS**************************************************
REM
REM
REM This will reset all saved settings with HiveOS.
REM If you experience issues connecting, or other reasons
REM That require resetting HiveOS connections (such as deleting working, reinstalling windows, etc.)
REM Run this script to reset all saved settings. This will remove newarguments.json (current user parameters)
REM as well.

pwsh -noexit -executionpolicy bypass -windowstyle maximized -command ".\build\powershell\scripts\reset.ps1"