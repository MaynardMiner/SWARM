#!/usr/bin/env bash
mydir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
cd $(< $mydir/dir.sh)/build/txt
sudo screen -S power -d -m
sleep .5
sudo screen -S power -X stuff $"timeout -s9 30 nvidia-smi --query-gpu=power.draw --format=csv > nvidiapower.txt\n"
