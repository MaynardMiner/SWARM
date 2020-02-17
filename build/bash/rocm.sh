#!/usr/bin/env bash
source /etc/profile.d/SWARM.sh
cd $SWARM_DIR/debug
timeout -s9 30 rocm-smi -P > amdpower.txt
