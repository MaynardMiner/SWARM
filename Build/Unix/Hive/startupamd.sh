#!/usr/bin/env bash 

[[ -e /usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0 ]] && export LD_PRELOAD=libcurl-compat.so.3.0.0

screen -S $2 -d -m
sleep .25
screen -S $2 -X logfile $4
sleep .25
screen -S $2 -X logfile flush 5
sleep .25
screen -S $2 -X log
sleep .25
screen -S $2 -X stuff $"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$5\n"
screen -S $2 -X stuff $"export GPU_MAX_HEAP_SIZE=100\n"
screen -S $2 -X stuff $"export GPU_USE_SYNC_OBJECTS=1\n"
screen -S $2 -X stuff $"export GPU_SINGLE_ALLOC_PERCENT=100\n"
screen -S $2 -X stuff $"export GPU_MAX_ALLOC_PERCENT=100\n"
sleep .25
screen -S $2 -X stuff $"cd\n"
sleep .25
screen -S $2 -X stuff $"cd $1\n"
sleep .25
screen -S $2 -X stuff $"$(< $3/config.sh)\n"