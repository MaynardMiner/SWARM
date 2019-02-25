#!/usr/bin/env bash
screen -S NVIDIA3 -d -m
sleep .1
screen -S NVIDIA3 -X stuff $"export LD_LIBRARY_PATH=/home/mkvito/miners/SWARM/build/export\n"
sleep .1
screen -S NVIDIA3 -X stuff $"cd\n"
sleep .1
screen -S NVIDIA3 -X stuff $"cd /home/mkvito/miners/SWARM/bin/cryptodredge-3\n"
sleep .1
screen -S NVIDIA3 -X stuff $"$(< /home/mkvito/miners/SWARM/build/bash/config.sh)\n"
