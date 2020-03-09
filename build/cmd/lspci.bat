@echo off
cd %SWARM_DIR%

pwsh -command ".\build\powershell\scripts\lspci.ps1 %*"