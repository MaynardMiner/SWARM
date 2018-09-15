#!/usr/bin/env bash 

screen -S $2 -d -m
sleep .5
screen -S $2 -X logfile $4
sleep .5
screen -S $2 -X logfile flush 5
sleep .5
screen -S $2 -X log
sleep .5
screen -S $2 -X stuff $"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$5\n"
sleep .5
screen -S $2 -X stuff $"cd\n"
sleep .5
screen -S $2 -X stuff $"cd $1\n"
sleep .5
screen -S $2 -X stuff $"$(< $3/config.sh)\n"