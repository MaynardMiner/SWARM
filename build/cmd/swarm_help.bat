@echo off
pwsh-preview -ExecutionPolicy Bypass -command "set-location ""%SWARM_DIR%""; .\build\powershell\scripts\help.ps1"
