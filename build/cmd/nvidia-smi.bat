@echo off
pushd %~dp0
set /p CMDDIR=<dir.txt
start "%CMDDIR%/build/apps/nvidia-smi.exe"
cmd.exe