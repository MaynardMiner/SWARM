@echo off
pushd %~dp0
pwsh -executionpolicy bypass -command "& ""%SWARM_DIR%/build/powershell/scripts/active.ps1"""
