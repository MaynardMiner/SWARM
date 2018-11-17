#!/usr/bin/env bash
screen -S NVIDIA1 -d -m
sleep .1
screen -S NVIDIA1 -X logfile /hive/custom/SWARM/logs/NVIDIA1.log
sleep .1
screen -S NVIDIA1 -X logfile flush 5
sleep .1
screen -S NVIDIA1 -X log
sleep .1
screen -S NVIDIA1 -X stuff $"export LD_LIBRARY_PATH=/hive/custom/SWARM/build/export\n"
sleep .1
screen -S NVIDIA1 -X stuff $"cd\n"
sleep .1
screen -S NVIDIA1 -X stuff $"cd /hive/custom/SWARM/bin/trex-1\n"
sleep .1
screen -S NVIDIA1 -X stuff $"$(< /hive/custom/SWARM/build/bash/config.sh)\n"
