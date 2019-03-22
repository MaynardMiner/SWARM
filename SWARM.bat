@echo off

REM ************QUICK ARGUMENTS CHEAT SHEET**************************************************
REM Rigname: Name of your rig
REM Currency: Preferred Fiat Current
REM CoinExchange: AltCoin Coin Pricing (Besides BTC).
REM Location: EUROPE ASIA US (Choose one).
REM Poolname: Remove Pools As You See Fit. Add Custom Pools If You Like.
REM Type: NVIDIA1 or AMD1 or AMD1,NVIDIA2 or NVIDIA1,NVIDIA2,NVIDIA3 (maximum of three)
REM Wallet1: Your BTC Wallet. Add -Wallet2 or -Wallet3 if using -Type NVIDIA2 or NVIDIA3
REM Donate: Donation in percent
REM WattOMeter: Use Watt Calculations (Default is 0.10 / kwh). Can be modified. See Wiki
REM Farm_Hash: HiveOS Farm Hash

REM ************NOTE***********************
REM If you do not intend to use HiveOS, add -HiveOS No
REM FOR ALL ARGUMENTS: SEE help folder. Explanation on how to use -Type NVIDIA1,NVIDIA2,NVIDIA3 is provided.

powershell -executionpolicy Bypass -command ".\startup.ps1 -RigName1 SWARM1 -Currency USD -CoinExchange LTC -Location US -PoolName hashrefinery,zergpool,fairpool,nicehash,nlpool,blockmasters,phiphipool,zpool,blazepool,ahashpool -Type NVIDIA1 -Wallet1 1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i -Donate .5 -WattOMeter Yes -Farm_Hash xxxxxxxxxxxxxxxxxxxxxxxxxxxx"