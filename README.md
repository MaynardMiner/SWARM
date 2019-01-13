**SWARM**

 **Hybrid Profit Switching Miner For HiveOS & Windows.**

 **Important Note:**

 If you would like SWARM incorporated into an OS besides HiveOS/Windows, contact the developers, and show them this:

https://github.com/MaynardMiner/SWARM/wiki/Developer's-Corner

**IF YOU NEED HELP, OR ARE LOST AT USING SWARM- TAKE ADVANTAGE OF THE WIKI:**

https://github.com/MaynardMiner/SWARM/wiki

**What is SWARM?**

 SWARM is an collection scripts written in both powershell and bash, and is a profit switching mining system that will work within any OS. (The miners that SWARM uses may vary) SWARM, is written to be used as an all purpose/all platform mining system that can be implemented/managed on a large scale basis. It was developed for larger mining administrators, who are generally unable to interact with every mining unit/rig directly. SWARM deviates from conventional in-depth GUI interfaces, or a centralized monitoring system/screen which are a burden to mining administrators. SWARM introduces a new method of interface which is meant to assist larger mining systems, by displaying information per user command. Because SWARM's interface is command based as opposed to GUI- Users are able to create scripts of their own to micro-manage their farms/workers. This also allows minimal OS requirements to run, and therefor lends to its versatility to operate in many different environments.

 SWARM has an api layer, which is produced when ``-LITE Yes`` is specified. This ``LITE`` mode allows for the data of SWARM to be displayed in API format through HTTP. This allows both users and developers to create their own mining administration/launch script for miners, and simply use SWARM to gather data and formulate calculations on which miner/pool/algo combination is most profitable. The linux side the commands SWARM use can be used in any bash script, after they have been installed. The Widows side allow commands to be ran through HiveOS's interface, and has a feature in which you are able to run powershell or cmd commands remotely through HiveOS's website through the use of ``ps``.

 To focus solely on SWARM's project mission: SWARM was written to integrate fully with HiveOS as of version 1.4.5. The developer of SWARM recognizes the attempt to make an OS/website as sophisticated as the years of development and effort placed into HiveOS would be pointless. Therefor, knowing that SWARM was capable of operating within HiveOS- SWARM was introduced to HiveOS as an available custom miner, and can be integrated rather easily.

 SWARM is very customizable. At the base layer- It is easy to setup by simply inputting some basic user configuration at launch, and SWARM will handle the rest. However, beyond the base layer, SWARM offers a sophisticated oc tuning system, along with the ability to customize environment varibles, miner arguments, pool difficulty, and even a system for factoring power cost/calculation into profit analysis.

 SWARM was designed to make SWARM bigger than itself. All commands can be executed via bash scripts/shell commands on the linux side, and we are slowly implementing the same features to the window's side. With the ``Lite`` mode, SWARM can be easily incorporated into any current miningOS available, and users can customize/create their own launch process, independent of SWARM.

 I am a sole developer, and this is a large project. I prioritize workload by requests and activity, if you would like me to develop/improve a particular version Just notify me. Currently, the most popular, most used, and most user supported feature of SWARM is utilizing it as a custom miner in HiveOS.

 **How Does SWARM work?**

 SWARM can be broken down into 6 phases:

 ``Startup Phase``

 ``SWARM begins initial start by detecting current features/platform/devices, and automatically generating default tables in which to build calculations. Once SWARM has built to its environment, including installing possible missing libraries- It begins to gather current recorded stat information from previous launches, as well as initializing an update if it required and user has specified it.``

 ``Pool Phase``

 ``The next phase is the process of querying remote sites, and gathering their data. Depending on user specification, the type of pricing data gathered and recorded may vary. SWARM through process of elimination determines the most profitable pool/algo combinations, and selects them, and adds them to the database. The rest of the data is stored to drive, so that long term calculations can be made.``

 ``Miner Phase``

 ``The following phase can vary depending on user specification. Either SWARM will begin to detect if miners are required, and download them, or SWARM LITE will begin to initiate the http API server. As SWARM gathers miner information, through process of elimination, based on previous recorded hashrates and potential 'bans': SWARM begins to collect the most efficient miners to use based on a combination of user settings and previous stored data.``

 ``Database Phase``

 ``SWARM in this phase begins to do a comparative analysis between Pools and Miners- Determining (based on user settings) what the most optimal miner to use is, and what pool should be used. At the end of this phase: The final database is outputted to the API server, and the background agent, which controls the remote features of SWARM as well as initiates the oc settings user has specified (if it was specified)``
 
 ``Launch Phase``

 ``SWARM begins the process of launching miners, verifying they are running, and recording their stats- Outputting basic information to main screen. During this phase, SWARM is monitoring miners in background, and is acting as a "watchdog" to restart miners that crash, or stop mining if issues may occur``

 ``Benchmark Phase``

``SWARM begins taking the data it has gathered, and saving it to file. At this time, if user specified power calculations: SWARM will take a sample watt calculation. SWARM will also notate if miner had issues, and determines on a three-strike multi-tier system if the miner should be banned from use. SWARM also gathers logs, and records keywords from miner logs such as "intensity" and "difficulty", and outputs this information into the miner directory itself, allowing users to view historically how the miner operated (for fine-tuning).``

**Features**

```
                          HiveOS |  Windows  | Unix (non HiveOS)
                                 |           |
HiveOS Integration          x    |     x     |  
Fast GPU Start Times        x    |           |       
Best Hashrates              x    |           |
Lowest Watt Use             x    |           |       
NVIDIA Algo OC-Tuning       x    |     x     |       x
AMD Algo OC-Tuning          x    |           |       x
Power Calculations          x    |     x     |       x
Backs Up Benchmarks         x    |     x     |       x
Remote Updates              x    |    soon   |       x
Real Time Monitoring        x    |     x     |       x
Cuda 9.2 Miners             x    |           |       x
Cuda 10 Miners              x    |     x     |       x
'Lite' version              x    |     x     |       x
Remote Command Interface    x    |     x     |       x
Time Out System             x    |     x     |       x
Bash Script Making          x    |           |       x
User Support                x    |     x     |       x
Vega Support                x    |           |       
RTX Supoort                      |     x     |          
Run Commands via HiveOS     x    | x(with ps)|

```

-Works within HiveOS, or Windows- AMD Miners for windows are new and expirmental.

-No Windows WDDM driver stack means faster spool up times compared to windows. Critical for profit switching.

-Most users report increases in hashrates using Unix as opposed to windows.

-80% integration of HiveOS website in Windows Version, by supplying farm hash and rocket launching SWARM as a custom miner.

-Algorithm specific OC Tuning for linux. Nvidia tuning currently only for Windows. (AMD coming soon).

-Watt calculations, manual or a built in resource Watt-O-Meter.

-Backs up initial benchmarks, making updating or recovery a charm. Remote updates transfers all user settings.

-Shows real time hashrates from miners on screen, background agent shows fan/temps/power usage.

-Displays close to real-time monitoring, directly from miners to HiveOS website. Allows for HiveOS monitoring and graph data.

-Despite its size- Memory use is low, more Read/Write of data is incorporated.

-Latest miners, updated frequently.

-Windows Miners Cuda 9.2 & 10.

-HiveOS Miners Cuda 9.2, and 10.

-Additional HiveOS online commands to open new windows to view stats, miner history, real-time data.

-Hundreds of user configuration options, including the unique ability to build scripts using bash commands on linux version.

-Sophisticated time-out system to avoid pool issues/high rejections/miner issues...All user adjustable.

-Linux launches miners in a unique manner to avoid zombie applications from harming tracking.

-Sophisticated monitoring system, which tracks all activity of mining. However, simple to use interface to manage it.

-Deviates from the current norm of other miners utilizing GUI system interface, and focuses more on mutli-screen/command
 interface, allowing more skilled users to generate their own mining system.

-API interface for statistics with LITE mode- Allows developers to integrate SWARM with their own customized implemtations.

-API command interfacing/bash command control lends towards scalabilty and larger scale implementations.

-Strong support via discord. Users with rig setups of 100s of GPU's are using and troubleshooting as updates are released.

**Pools**
```
nicehash
blockmasters
fairpool
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
miniz (NVIDIA)
ccminer-yescrypt (NVIDIA)
CryptoDredge (NVIDIA)
Tpruvot (NVIDIA)
T-rex (NVIDIA)
Z-Enemy (NVIDIA) 
Claymore (NVIDIA) (AMD)
Phoenix Miner (NVIDIA) (AMD)
Dstm (NVIDIA)
EWBF (NVIDIA)
JayDDee (CPU)
SGminer-Phi2 (AMD)
Sgminer-VII (AMD)
Sgminer-Hex (AMD)
teamredminer (AMD)
WidRig-Multi (AMD)
zjazz (NVIDIA)
excavator (NVIDIA)
lolminer (expirmental) (AMD) (NVIDIA)
```

**Simple Install Instructions (Windows):**

SWARM requires no installation. However there are a few pre-requisites:

-Windows 10 minimum.

-Have the latest cuda/amd drivers installed.

-Latest C++ Redistributable Packages for Visual Studio.

(Optional):

-HiveOS user account, your farm hash ready.

*Install Steps:*

Step 1: Open SWARM.bat, changed wallet with your BTC wallet, modify/add/replace arguments to your specifications. See help
        files for a list of arguments. Or use github wiki.

Step 2: (Optional): If you wish to use HiveOS, add your farm hash.

Step 3: Launch SWARM.bat.

Step 4: (Optional) When miners finish downloading, and background agent starts- Go to HiveOS.

Step 5: (Optional) Create a flight sheet for SWARM (SEE HiveOS install below), you can omit download link, but not arguments!

Step 6: (Optional) Apply flight sheet to your newly created SWARM worker.

Step 7: (Optional) Confirm SWARM has restarted- At this point when background agent starts- SWARM should communicate stats to
        HiveOS, and should be ready to accept commands. You will no longer need to modify the .bat file- You modify arguments
        through HiveOS and your flight sheet.

**Simple Install Instructions (HIVEOS):**

SWARM is simple to install in linux environment, IF a user is familiar with linux operating systems. There are plenty of users to help/support you, if you should decide to learn how to operate/use SWARM. However, it does take the commitment of learning how to use/manage linux.

THere is a Windows version that stats to HiveOS, that is constantly being worked on/improved. If you are unsure of your capabilities of using linux- You can always use the Windows version, and get most of the features SWARM has to offer, as well as help me improve it.

This is an example of how to remote install/update miner. It is the fastest way to get going. Simply enter tar.gz file name from latest release. Then insert link for tar.gz. Next in wallet/worker templates enter 'blah'. Lastly, your setup arguments go in the last box, labeled extra config arguments. After that, you are are good to go! See wiki on proper argument use. Here is a photo of setup:

Coin/Wallet is irrelevant. You can basically enter whatever you want. Then navigate to custom miner:

![alt text](https://raw.githubusercontent.com/MaynardMiner/SWARM/master/build/data/First_Step.png)

From there you should see this window. Pool and URL are setup with arguments. However, Hive 2.0 requires those fields to not be empty. You can simply enter anything there. See photo below on how to setup miner. Just insert the name of the latest release, and the release tar.gz file link. Then insert your arguments in the bottom box:

FULL ARGUMENT LIST:

https://github.com/MaynardMiner/SWARM/blob/master/Help%20Files/SWARM_help.txt

SAMPLE ARGUMENT SETUPS:

https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration)

![alt text](https://raw.githubusercontent.com/MaynardMiner/SWARM/master/build/data/Second.png)

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
```
Alexander
Stoogie
GravityMaster
Zirillian
JC
NLPOOL.NL
HerreHesse
Crypto_Kp
Castillojim
Marcel
PKBO
Incode
Soliduzhs
```
For their help pointing out bugs and issues, and their suggestions, ideas, patience that helped make SWARM what it is today.

Thanks To:

```
Sniffdog
Nemosminer
Uselessguru
Aaronsace
```

SWARM uses the following programs to help with oc tuning:

-nvidiainspector
-wolfamdctrl/ohgodatool
-overdriventool
-OhGodAnETHlargementPill-r2

All licenses and developer information are included. I am not responsible for
these softwares, nor do I maintain them. They are downloaded from their
known distrubution sources and/or are included in mining OS.

You may see other apps inside apps folder- These are depreciated, and no longer
in use.

They were the pioneers to powershell scriptmining. Their scripts helped me to piece together a buggy but workable linux miner, which was the original purpose of SWARM, since none of them did so at the time. Since then it has grown to what it is today.





