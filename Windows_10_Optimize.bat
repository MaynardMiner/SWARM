@echo off

REM ************Optimizations For Windows 10**************************************************
REM
REM
REM This will run Win_Optimize.ps1.
REM This will do the following when ran:
REM    -Replace Utiliman with CMD
REM    -Disable Lock Screen Windows Feature
REM    -Disable Windows Update sharing
REM    -Disable Windows Error Reporting
REM    -Disable Automatic Updates (For now- You can never fully disable.)
REM    -Disable Hibernation
REM    -Disabling Windows Tracking Services
REM    -Disabling Windows Defender (For now- You can never fully disable.)
REM    -Removing Error And Customer Reporting Scheduled Tasks
REM    -Disable One-Drive
REM
REM Optimize AMD Cards / Reset Drivers.
REM This will update AMD registry for efficient GPU mining.
REM This will not affect cards bios directly.
REM HOWEVER THIS WILL HARM USING THIS MACHINE FOR GAMING!
REM Don't run this script if you wish to game with this machine as well!
REM
REM
REM IMPORTANT: THIS WILL HARM GAMING SETTINGS FOR WINDOWS WITH AMD CARDS.
REM THIS NEEDS TO RUN AS ADMIN.

cd %~dp0

REM DON'T RUN WITH SWARM RUNNING!

pwsh-preview -executionpolicy Bypass -command ".\build\powershell\scripts\win_optimize.ps1"

REM REBOOT advised afterwards.