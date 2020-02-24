@echo off

:: ************Reset HiveOS**************************************************
::
::
:: This will reset all saved settings with HiveOS.
:: If you experience issues connecting, or other reasons
:: That require resetting HiveOS connections (such as deleting working, reinstalling windows, etc.)
:: Run this script to reset all saved settings. This will ::ove newarguments.json (current user parameters)
:: as well.

pwsh-preview -noexit -executionpolicy bypass -windowstyle maximized -command ".\build\powershell\scripts\reset.ps1"