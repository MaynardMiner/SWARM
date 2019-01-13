#!/usr/bin/env bash
screen -S NVIDIA2 -d -m
sleep .1
screen -S NVIDIA2 -X stuff $"export LD_LIBRARY_PATH=/hive/miners/custom/SWARM/build/export\n"
sleep .1
screen -S NVIDIA2 -X stuff $"cd\n"
sleep .1
screen -S NVIDIA2 -X stuff $"cd /hive/miners/custom/SWARM/bin/cryptodredge-2\n"
sleep .1
screen -S NVIDIA2 -X stuff $"$(< /hive/miners/custom/SWARM/build/bash/config.sh)\n"
