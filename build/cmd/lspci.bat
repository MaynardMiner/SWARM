@echo off
cd %SWARM_DIR%

pwsh-preview -command ".\build\powershell\scripts\lspci.ps1 %*"