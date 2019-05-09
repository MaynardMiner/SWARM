@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
pwsh -Command "Invoke-Expression ""%CMDDIR%/build/apps/nvidia-smi.exe"""
cmd.exe