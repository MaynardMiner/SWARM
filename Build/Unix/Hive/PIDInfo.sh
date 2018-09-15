#!/usr/bin/env bash
screen -S $1 -X stuff $"pwsh -command ./PID.ps1 -Name $2\n"
