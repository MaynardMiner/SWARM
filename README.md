**SWARM**

**Previously known as MM.Hash**

Note: This github wiki and repo is under construction. To see previous versions & wiki on how to use: please navigate to former github repository:

https://github.com/MaynardMiner/MM.Hash

**Hybrid Profit Switching Miner For HiveOS & Windows.**

**Important Note:**

Version information:

a - Windows version.

b - HiveOS version.

c - Soon to be Ubuntu version.

Depending on which OS you use- Use the latest version release of that version.

SWARM is a powershell/bash hyrbid miner that is meant to work in both windows and HiveOS mining systems. It has the capability of switching between mutliple pools, multiple algorithms based on the most profitable calucation. It can also perform coin profit switching as well, on pools that can do so. SWARM fully integrates with HiveOS, sending stats directly to HiveOS with little/no issues. It accepts remote commands, and can be updated remotely as well. The HiveOS version means you can use all the features of HiveOS, including hashrate monitoring, possible GPU failure detection, miner configuration, all while doing it remotely.

I am a sole developer, and have multiple versions to operate in different OS's. I prioritize them by requests and activity, if you would like me to develop/improve a particular version- Just notify me, and I will prioritize it. Currently, the most popular, most used, and most recommended is the HiveOS version.

**Features**

-Algorithm specific OC Tuning (HIVEOS version).

-Backs up initial benchmarks, making updating or recovery a charm.

-Shows real time hashrates from miners, along with previous hashrates.

-HiveOS full integration.

-Displays close to real-time monitoring, directly from miners to HiveOS website. Allows for HiveOS monitoring and graph data.

-Every part of the code has a double-checking feature, to ensure real time monitoring.

-More hard drive integration, less storage on RAM.

-Latest miners, updated frequently.

-Windows Miners Cuda 9.2

-HiveOS Miners Cuda 9.1 or 9.2.

-HiveOS commands to open new windows to view stats, miner history, real-time data.

-Coin profit switching. Can be used with algorithm profit switching.

-Algorithm profit switching.

-Miner notifies users of benchmarking timeouts

-Easy to setup.

-HiveOS version is dedicated to creating a solid environment that corrects itself if mistakes are made.

-Hashrates monitoring via logging for miners that require it.

-New miners than HiveOS.

-Strong support via discord. Users with rig setups of 100s of GPU's are using and troubleshooting as updates are released.



**Algorithms** (As defined by poola and translation required by miners)

```
    "aergo": "aergo",
    "aeon": "aeon",
    "allium": "allium",
    "balloon": "balloon",
    "bitcore": "bitcore",
    "blake": "blakecoin",
    "blakecoin": "blakecoin",
    "blake2s": "blake2s",
    "c11": "c11",
    "cryptonight": "cryptonight",
    "cryptonightheavy": "cryptonightheavy",
    "cryptonightmonero": "cryptonight",
    "cryptonightv7": "cryptonightv7",
    "daggerhashimoto": "daggerhashimoto",
    "equihash": "equihash",
    "equihash96": "equihash96",
    "equihash144": "equihash144",
    "equihash192": "equihash192",
    "equihash200": "equihash200",
    "equihash210": "equihash210",
    "equihash-btg": "equihash-btg",
    "ethash": "ethash",
    "groestl": "groestl",
    "hex": "hex",
    "hmq1725": "hmq1725",
    "hodl": "hodl",
    "hsr": "hsr",
    "jackpot": "jackpot",
    "keccak": "keccak",
    "keccakc": "keccakc",
    "lbk3": "lbk3",
    "lyra2re": "lyra2re",
    "lyra2rev2": "lyra2rev2",
    "lyra2v2": "lyra2v2",
    "lyra2z": "lyra2z",
    "m7m": "m7m",
    "masari": "masari",
    "myr-gr": "myr-gr",
    "neoscrypt": "neoscrypt",
    "nist5": "nist5",
    "phi": "phi",
    "phi2": "phi2",
    "polytimos": "polytimos",
    "qubit": "qubit",
    "renesis": "renesis",
    "sib": "sib",
    "skein": "skein",
    "skunk": "skunk",
    "sonoa": "sonoa",
    "stellite": "stellite",
    "timetravel": "timetravel",
    "tribus": "tribus",
    "x11": "x11",
    "x16r": "x16r",
    "x16s": "x16s",
    "x17": "x17",
    "xevan": "xevan",
    "xmr": "xmr",
    "yespower": "yespower",
    "yescrypt": "yescrypt",
    "yescryptR16": "yescryptR16"

```


**Pools**
```
nicehash
miningpoolhub (mph)
zergpool_coin
zergpool_algo
blockmasters_algo
blockmasters_coin
starpool
ahashpool
blazepool
hashrefinery
phiphipool
zpool
```

**Miners**
```
Avermore (AMD)
Bubalisk (CPU)
CryptoDredge (NVIDIA)
Tpruvot (NVIDIA)
T-rex (NVIDIA)
Z-Enemy (NVIDIA) 
Claymore (NVIDIA) (AMD)
Dstm (NVIDIA)
EWBF (NVIDIA)
JayDDee (CPU)
SGminer-Phi2 (AMD)
Cryptozeny (ARM Support)(CPU
LyclMiner (expirmental) (AMD)
Sgminer-kl (AMD)
Sgminer-Hex (AMD)
tdxminer (AMD)
```

Simple Install Instructions (HIVEOS):

This is an example of how to remote install/update miner. It is the fastest way to get going. Insert link for tar.gz. Enter 'blah' in the fields required just like the photo below. Lastly, your setup arguments go in the last box, labeled extra config <a href="https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration)">arguments</a>. After that, you are are good to go! See wiki on proper argument use. Here is a photo of setup:

**Note** These photos are a little old, the arguments shown like -GPU_Count are no longer needed, and is MM.Hash (previous version). I will change photo soon, but shows the process.

https://raw.githubusercontent.com/MaynardMiner/SWARM/master/Build/Data/First_Step.png


https://raw.githubusercontent.com/MaynardMiner/SWARM/master/Build/Data/Second_Step.png

**Note**

You may need to Rocket Launch/Reboot in order to have Agent restart and start recieving data from SWARM

**Known Issues**

-Algorithms: Since HiveOS 2.0 update, algorithms are slow to show on HiveOS website. ```agent``` is clearly sending the algo, but it registers on HiveOS at a severe delay, messing up the stats on HiveOS. This is has been occurring since HiveOS 2.0, and it is website related. It cannot be fixed on my end.

-AMD: AMD miner are new to SWARM as of 1.4.0b. The dev isn't familiar with AMD, but is trying to learn quickly to get more miners and settings correct. Currently AMD is at a beta-level. If you use AMD or are familiar with AMD and want to see more developed- Please beta-test, join discord, and offer suggestions on miners/settings/improvements.

**CONTACT**

Discord Channel For SWARM- 
https://discord.gg/5YXE6cu

**DONATE TO SUPPORT!**

BTC 1DRxiWx6yuZfN9hrEJa3BDXWVJ9yyJU36i

RVN RKirUe978mBoa2MRWqeMGqDzVAKTafKh8H

Special Thanks To Discord Users:
Alexander
Stoogie
GravityMaster
Zirillian

For their help pointing out bugs and issues, and helping to keep program running well.

Thanks To:

Sniffdog

Nemosminer

Uselessguru

Aaronsace

They were the pioneers to powershell scriptmining. Their scripts helped me to piece together a buggy but workable linux miner, which was the original purpose of SWARM, since none of them did so at the time. Since then it has grown to what it is today.





