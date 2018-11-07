#!/usr/bin/env bash
nvidia-settings -a [gpu:0]/GPUGraphicsClockOffset[3]=100 -a [gpu:2]/GPUGraphicsClockOffset[2]=100 -a [gpu:4]/GPUGraphicsClockOffset[3]=100 -a [gpu:9]/GPUGraphicsClockOffset[2]=100 -a [gpu:10]/GPUGraphicsClockOffset[3]=100 -a [gpu:12]/GPUGraphicsClockOffset[2]=100 -a [gpu:1]/GPUGraphicsClockOffset[3]=100 -a [gpu:3]/GPUGraphicsClockOffset[2]=100 -a [gpu:5]/GPUGraphicsClockOffset[3]=100 -a [gpu:6]/GPUGraphicsClockOffset[2]=100 -a [gpu:7]/GPUGraphicsClockOffset[3]=100 -a [gpu:8]/GPUGraphicsClockOffset[2]=100 -a [gpu:11]/GPUGraphicsClockOffset[2]=100 -a [gpu:0]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:2]/GPUMemoryTransferRateOffset[2]=1000 -a [gpu:4]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:9]/GPUMemoryTransferRateOffset[2]=1000 -a [gpu:10]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:12]/GPUMemoryTransferRateOffset[2]=1000 -a [gpu:1]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:3]/GPUMemoryTransferRateOffset[2]=1000 -a [gpu:5]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:6]/GPUMemoryTransferRateOffset[2]=1000 -a [gpu:7]/GPUMemoryTransferRateOffset[3]=1000 -a [gpu:8]/GPUMemoryTransferRateOffset[2]=1000 -a [gpu:11]/GPUMemoryTransferRateOffset[2]=1000
nvidia-smi -i 0 -pl 150
sleep .1
nvidia-smi -i 2 -pl 150
sleep .1
nvidia-smi -i 4 -pl 150
sleep .1
nvidia-smi -i 9 -pl 150
sleep .1
nvidia-smi -i 10 -pl 150
sleep .1
nvidia-smi -i 12 -pl 150
sleep .1
nvidia-smi -i 1 -pl 75
sleep .1
nvidia-smi -i 3 -pl 75
sleep .1
nvidia-smi -i 5 -pl 75
sleep .1
nvidia-smi -i 6 -pl 75
sleep .1
nvidia-smi -i 7 -pl 75
sleep .1
nvidia-smi -i 8 -pl 75
sleep .1
nvidia-smi -i 11 -pl 75
sleep .1
