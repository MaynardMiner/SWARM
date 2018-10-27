**SWARM**

**Hybrid Profit Switching Miner For HiveOS & Windows.**

**Important Note:**

If you would like SWARM incorportated into an OS besides HiveOS, contact the developers, and show them this:

https://github.com/MaynardMiner/SWARM/wiki/Developer's-Corner

SWARM is a powershell/bash hyrbid miner that is meant to work in both Windows and HiveOS mining systems. It has the capability of switching between mutliple pools, multiple algorithms based on the most profitable calucation. SWARM fully integrates with HiveOS, sending stats directly to HiveOS with little/no issues. The HiveOS compatibility means you can use all the features of HiveOS, and the dilligent effort HiveOS makes to bring bleeding edge technology to gpu and cpu mining. Working with foundation of HiveOS, mostly every aspect of SWARM can be viewed and modified remotely, from profit statistics, miner runtime, individual miner updates, to even oc profiling for algorithms (nvida only, amd coming soon).

I am a sole developer, and have multiple versions to operate in different OS's. I prioritize them by requests and activity, if you would like me to develop/improve a particular version- Just notify me, and I will prioritize it. Currently, the most popular, most used, and most recommended is the HiveOS version.

SWARM focuses on quality versus quantity, from profit data, miner implementation, to user-features to ensure smooth runtime.

**Features**

-Works within HiveOS, all linux miners- AMD miners Windows cannot use.

-No Windows WDDM driver stack means faster spool up times compared to windows. Critical for profit switching.

-Limited (but fairly useful) HiveOS integration for Windows.

-Algorithm specific OC Tuning.

-Watt calculations, manual or a built in resource Watt-O-Meter.

-Backs up initial benchmarks, making updating or recovery a charm.

-Shows real time hashrates from miners, along with previous hashrates. Background Agent for Windows.

-Displays close to real-time monitoring, directly from miners to HiveOS website. Allows for HiveOS monitoring and graph data.

-Every part of the code has a double-checking feature, to ensure real time monitoring.

-Latest miners, updated frequently.

-Windows Miners Cuda 9.2 & 10.

-HiveOS Miners Cuda 9.1, 9.2, and 10.

-Additional HiveOS online commands to open new windows to view stats, miner history, real-time data.

-Algorithm profit switching.

-Miner notifies users of benchmarking timeouts. Stores relevant information of failures to file.

-Easy to setup.

-HiveOS version is dedicated to creating a solid environment that corrects itself if mistakes are made/works around zombie apps.

-Hashrates monitoring via logging for miners that require it.

-Supports miner not regularly available within HiveOS.

-Strong support via discord. Users with rig setups of 100s of GPU's are using and troubleshooting as updates are released.

**Algorithms** (As defined by poola and translation required by miners)

```
    "aergo": "aergo",
    "aeon": "aeon",
    "allium": "allium",
    "balloon": "balloon",
    "bcd": "bcd",
    "bitcore": "bitcore",
    "blake": "blakecoin",
    "blakecoin": "blakecoin",
    "blake2s": "blake2s",
    "c11": "c11",
    "cryptonight": "cryptonight",
    "cryptonightheavy": "cryptonightheavy",
    "cryptonightmonero": "cryptonight",
    "cryptonightv7": "cryptonightv7",
    "cryptonightv8": "cryptonightv8",
    "cryptonightsaber": "cryptonightsaber",
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
    "geek": "geek",
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
blockmasters
nlpool
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
LyclMiner (expirmental) (AMD)
Sgminer-kl (AMD)
Sgminer-Hex (AMD)
tdxminer (AMD)
```

Simple Install Instructions (HIVEOS):

This is an example of how to remote install/update miner. It is the fastest way to get going. Insert link for tar.gz. Enter 'blah' in the fields required just like the photo below. Lastly, your setup arguments go in the last box, labeled extra config <a href="https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration)">arguments</a>. After that, you are are good to go! See wiki on proper argument use. Here is a photo of setup:

**Note** These photos are a little old, the arguments shown like -GPU_Count are no longer needed, and is MM.Hash (previous version). I will change photo soon, but shows the process.

https://raw.githubusercontent.com/MaynardMiner/SWARM/master/build/data/First_Step.png


https://raw.githubusercontent.com/MaynardMiner/SWARM/master/build/data/Second_Step.png

**Note**

You may need to Rocket Launch/Reboot in order to have Agent restart and start recieving data from SWARM

**Known Issues**

GPU mining within linux is an efficient process, but is also load intensive on system resources. Both SWARM and HiveOS website require data from drivers and miners, which can be strenous on larger mining rigs. There can be delays to recieve stats in this situation for either SWARM or HiveOS website. I am constantly working on ways to reduce this load.

Windows version, and its ability to contact and communicate its data is a relativly new design. If you use Windows version, please report your results or issues, and ways to better improve the system.

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
JC
NLPOOL.NL
Crypto_Kp
Castillojim
Marcel

For their help pointing out bugs and issues, and their suggestions, ideas, patience that helped make SWARM what it is today.

Thanks To:

Sniffdog

Nemosminer

Uselessguru

Aaronsace

They were the pioneers to powershell scriptmining. Their scripts helped me to piece together a buggy but workable linux miner, which was the original purpose of SWARM, since none of them did so at the time. Since then it has grown to what it is today.





