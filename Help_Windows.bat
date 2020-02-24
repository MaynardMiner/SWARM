@echo off

:: ************swarm_help**************************************************
::
::
:: This will start swarm with -help command.
:: This will run through a guided setup to start SWARM.
:: When finished it will save your settings.

pwsh-preview -executionpolicy Bypass -command ".\startup.ps1 -help"

:: Once you have first ran SWARM, you can run this guided help again
:: through command prompt with the commmand ``swarm_help``
:: This command can be ran at anytime, and will allow you to change arguments
:: and settings within SWARM, and give you the arguments you wish to use for
:: HiveOS flight sheet.