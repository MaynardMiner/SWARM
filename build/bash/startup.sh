#!/usr/bin/env bash
screen -S NVIDIA2 -d -m
sleep .1
screen -S NVIDIA2 -X logfile /hive/custom/SWARM/logs/NVIDIA2.log
sleep .1
screen -S NVIDIA2 -X logfile flush 5
sleep .1
screen -S NVIDIA2 -X log
sleep .1
screen -S NVIDIA2 -X stuff $"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/hive/custom/SWARM/build/export\n"
sleep .1
screen -S NVIDIA2 -X stuff $"cd\n"
sleep .1
screen -S NVIDIA2 -X stuff $"cd /hive/custom/SWARM/bin/trex-2\n"
sleep .1
screen -S NVIDIA2 -X stuff $"$(< /hive/custom/SWARM/build/bash/config.sh)\n"
