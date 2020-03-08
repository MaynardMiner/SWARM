@echo off
pushd %~dp0
pwsh-preview -executionpolicy bypass -command "Set-Location '%SWARM_DIR%'; invoke-expression ""C:\PROGRA~1\NVIDIA~1\NVSMI\nvidia-smi.exe %*"" | Tee-Object -Variable NVSMI | Out-Null; $NVSMI | Out-Host"