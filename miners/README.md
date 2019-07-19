# Miners folder

## What is the miners folder?

These are the scripts that SWARM pull to setup the miners.

## Why is there also a miners folder in config section?

Those are merely user configuration/settings. These are the actually scripts
that SWARM runs to do things such as:
* Divide miner by devices.
* Generate initial quote for hashrate/estimate.
* Gather environment settings.
* Pull user configuration settings, and add to miner startup.

## ASIC

This folder contains the script for ASIC miners bfgminer and sgminer.

## AMD

This folder contains the scripts for the current default miners.

## NVIDIA

This folder contains the scripts for the current nvidia miners.

## CPU

This folder contains the scripts for the current cpu miners.
