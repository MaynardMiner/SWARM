@echo off
pushd %~dp0
pwsh-preview -executionpolicy bypass -command "& ""%SWARM_DIR%/build/powershell/scripts/active.ps1"""
