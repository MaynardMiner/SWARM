@echo off

REM ************QUICK ARGUMENTS CHEAT SHEET**************************************************
REM
REM
REM NOTE: YOU CAN RUN ".\startup.ps1 -Help" for a guided configuration
REM
REM
REM Rigname: Name of your rig
REM Currency: Preferred Fiat Currency
REM CoinExchange: AltCoin Coin Pricing (Besides BTC).
REM Location: EUROPE ASIA US (Choose one).
REM Poolname: Remove Pools As You See Fit. Add Custom Pools If You Like.
REM Type: NVIDIA1 or AMD1 or AMD1,NVIDIA2 or NVIDIA1,NVIDIA2,NVIDIA3 (maximum of three)
REM Type: CPU can be added, but -CPUThreads must be used (see help on arguments)
REM Type: ASIC can be used, compatible with cgminer & bfgminer (most asics)
REM Type: -ASIC_IP and -ASIC_ALGO must be used with -Type ASIC (see help on arguments)
REM Wallet1: Your BTC Wallet. Add -Wallet2 or -Wallet3 if using -Type NVIDIA2 or NVIDIA3
REM Donate: Donation in percent
REM WattOMeter: Use Watt Calculations (Default is 0.10 / kwh). Can be modified. See Wiki
REM Hive_Hash: HiveOS Farm Hash

REM ************NOTE***********************
REM If you do not intend to use HiveOS, add -HiveOS No
REM FOR ALL ARGUMENTS: SEE help folder. Explanation on how to use -Type NVIDIA1,NVIDIA2,NVIDIA3 is provided.
REM HERE is an example of basic arguments:
REM
REM pwsh -executionpolicy Bypass -command ".\startup.ps1 -RigName1 SWARM -Location US -PoolName nlpool,blockmasters,zergpool,nicehash,fairpool,ahashpool,blazepool,hashrefinery,zpool -Type AMD1 -Wallet1 1RVNsdO6iuwEHfoiuwe123hsdfljk -Donate .5"

pwsh -executionpolicy Bypass -command ".\startup.ps1"