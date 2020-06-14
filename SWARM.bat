@echo off
cd /D %~dp0
:: ************QUICK ARGUMENTS CHEAT SHEET**************************************************
::
::
:: NOTE: YOU CAN RUN ".\startup.ps1 -Help" for a guided configuration
::
::
:: Rigname: Name of your rig
:: Currency: Preferred Fiat Currency
:: CoinExchange: AltCoin Coin Pricing (Besides BTC).
:: Location: EUROPE ASIA US JAPAN (Choose one).
:: Poolname: Remove Pools As You See Fit. Add Custom Pools If You Like.
:: Type: NVIDIA1 or AMD1 or AMD1,NVIDIA2 or NVIDIA1,NVIDIA2,NVIDIA3 (maximum of three)
:: Type: CPU can be added, but -CPUThreads must be used (see help on arguments)
:: Type: ASIC can be used, compatible with cgminer & bfgminer (most asics)
:: Type: -ASIC_IP and -ASIC_ALGO must be used with -Type ASIC (see help on arguments)
:: Wallet1: Your BTC Wallet. Add -Wallet2 or -Wallet3 if using -Type NVIDIA2 or NVIDIA3
:: Donate: Donation in percent
:: WattOMeter: Use Watt Calculations (Default is 0.10 / kwh). Can be modified. See Wiki
:: Hive_Hash: HiveOS Farm Hash

:: ************NOTE***********************
:: If you do not intend to use HiveOS, add -HiveOS No
:: FOR ALL ARGUMENTS: SEE help folder. Explanation on how to use -Type NVIDIA1,NVIDIA2,NVIDIA3 is provided.
:: HERE is an example of basic arguments:
::
:: pwsh -executionpolicy Bypass -command ".\startup.ps1 -RigName1 SWARM -Location US -PoolName nlpool,blockmasters,zergpool,nicehash,fairpool,ahashpool,blazepool,hashrefinery,zpool -Type AMD1 -Wallet1 1RVNsdO6iuwEHfoiuwe123hsdfljk -Donate .5"

:: If using HiveOS, you may want to just add hive_hash just so you will always connect
:: pwsh -executionpolicy Bypass -command ".\startup.ps1 -hive_hash aera123144asithgsd123kgh32fglsdkjhgw"


pwsh -executionpolicy Bypass -command ".\startup.ps1 -Hive_hash ab1172091a9de3006185116f29aa32a7814796b7"
