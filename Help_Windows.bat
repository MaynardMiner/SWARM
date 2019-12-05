@echo off

REM ************swarm_help**************************************************
REM
REM
REM This will start swarm with -help command.
REM This will run through a guided setup to start SWARM.
REM When finished it will save your settings.

pwsh -executionpolicy Bypass -command ".\startup.ps1 -help"

REM Once you have first ran SWARM, you can run this guided help again
REM through command prompt with the commmand ``swarm_help``
REM This command can be ran at anytime, and will allow you to change arguments
REM and settings within SWARM, and give you the arguments you wish to use for
REM HiveOS flight sheet.