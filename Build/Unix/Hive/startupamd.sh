#!/usr/bin/env bash 

screen -S $2 -d -m
sleep .5
screen -S $2 -X logfile $4
sleep .5
screen -S $2 -X logfile flush 5
sleep .5
screen -S $2 -X log
sleep .5
screen -S $2 -X stuff $"export GPU_FORCE_64BIT_PTR=1\n"
sleep .5
screen -S $2 -X stuff $"export GPU_MAX_HEAP_SIZE=100\n"
sleep .5
screen -S $2 -X stuff $"export GPU_USE_SYNC_OBJECTS=1\n"
sleep .5
screen -S $2 -X stuff $"export GPU_SINGLE_ALLOC_PERCENT=100\n"
sleep .5
screen -S $2 -X stuff $"export GPU_MAX_ALLOC_PERCENT=100\n"
sleep .5
screen -S $2 -X stuff $"cd\n"
sleep .5
screen -S $2 -X stuff $"cd $1\n"
sleep .5
screen -S $2 -X stuff $"$(< $3/config.sh)\n"