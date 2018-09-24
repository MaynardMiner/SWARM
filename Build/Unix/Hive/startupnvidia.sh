#!/usr/bin/env bash 

[[ -e /usr/lib/x86_64-linux-gnu/libcurl-compat.so.3.0.0 ]] && export LD_PRELOAD=libcurl-compat.so.3.0.0

screen -S $2 -d -m
sleep .5
screen -S $2 -X logfile $4
sleep .5
screen -S $2 -X logfile flush 5
sleep .5
screen -S $2 -X log
screen -S $2 -X stuff $"export LD_PRELOAD=libcurl-compat.so.3.0.0\n"
sleep .5
screen -S $2 -X stuff $"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$5\n"
sleep .5
screen -S $2 -X stuff $"cd\n"
sleep .5
screen -S $2 -X stuff $"cd $1\n"
sleep .5
screen -S $2 -X stuff $"$(< $3/config.sh)\n"