#!/usr/bin/env bash

screen -S $1 -X stuff $"pwsh -command ./LogData.ps1 -DeviceCall $2 -Type $3 -GPUS '"$4"' -WorkingDir $5 -Miner_Algo $6 -API $7 -Port $8\n"

