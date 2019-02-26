#!/usr/bin/env bash
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[3]=100 -a [gpu:3]/GPUGraphicsClockOffset[3]=100 -a [gpu:7]/GPUGraphicsClockOffset[3]=100 -a [gpu:1]/GPUGraphicsClockOffset[3]=100 -a [gpu:4]/GPUGraphicsClockOffset[3]=100 -a [gpu:5]/GPUGraphicsClockOffset[3]=100 -a [gpu:8]/GPUGraphicsClockOffset[3]=100 -a [gpu:2]/GPUGraphicsClockOffset[3]=100 -a [gpu:6]/GPUGraphicsClockOffset[3]=100 -a [gpu:0]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:3]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:7]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:1]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:4]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:5]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:8]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:2]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:6]/GPUMemoryTransferRateOffset[3]=1000
nvidia-smi -i 0 -pl 150
sleep .1
nvidia-smi -i 3 -pl 150
sleep .1
nvidia-smi -i 7 -pl 150
sleep .1
nvidia-smi -i 1 -pl 75
sleep .1
nvidia-smi -i 4 -pl 75
sleep .1
nvidia-smi -i 5 -pl 75
sleep .1
nvidia-smi -i 8 -pl 75
sleep .1
nvidia-smi -i 2 -pl 175
sleep .1
nvidia-smi -i 6 -pl 175
sleep .1
