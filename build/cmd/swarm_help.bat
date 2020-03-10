@echo off
pwsh -ExecutionPolicy Bypass -command "set-location ""%SWARM_DIR%""; .\build\powershell\scripts\help.ps1"
