#!/usr/bin/env bash
screen -S OC_NVIDIA -d -m
sleep .1
screen -S OC_NVIDIA -X stuff $"nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[2]=100 -a [gpu:0]/GPUMemoryTransferRateOffset[2]=1000\n"
sleep .1
screen -S OC_NVIDIA -X stuff $"nvidia-smi -i 0 -pl 75\n"
sleep .1
sleep .1
