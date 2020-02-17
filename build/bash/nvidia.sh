#!/usr/bin/env bash
source /etc/profile.d/SWARM.sh
cd $SWARM_DIR/debug
sudo screen -S power -d -m
sleep .5
sudo screen -S power -X stuff $"timeout -s9 30 nvidia-smi --query-gpu=power.draw --format=csv > nvidiapower.txt\n"
