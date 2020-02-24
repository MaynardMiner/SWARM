# SWARM: Profit Switching AI For HiveOS, Linux, & Windows

**IMPORTANT** : SWARM attempts to provide miners that work for as many cards as possible. Some miners may work for your cards, some may not. All miners are set with default settings provided from developers themselves (with logging enabled, if available). There is a ``-Bans`` argument that lets you remotely remove miners from the list. SWARM should support, if not all late model cards.

Windows Version Does Not Require HiveOS Windows. SWARM is built with all HiveOS API methods, and its own utilities like autofan, and overclocking. However, the overclocking for AMD requires prior registry modifications and compute mode activated to fully manipulate power play tables. If you are unsure how to do this- Run Win_Optimize.bat as an administrator. This will make an attempt to edit/make the registry entries for you, and set cards in compute mode. Reboot afterwards.

## SWARM wiki:

https://github.com/MaynardMiner/SWARM/wiki

## What is SWARM?

### Concept

SWARM is an collection scripts written in both powershell and bash, and is a profit switching mining script that will work within any OS with very few/little changes. (The miners that SWARM uses may vary) SWARM, is written to be used as an all purpose/all platform mining system that can be implemented/managed on a large scale basis. It was developed for larger mining administrators, who are generally unable to interact with every mining unit/rig directly, but would like to work with auto-exchange/profit switching mining. It favors command line interfacing vs. GUI.

**This is not a fork of multiminer/nemosminer/sniffdog. This is original software.**

This miner is a commandline tool. It does not require a desktop environment in Linux, and can operate purely from ssh/terminal with commands that can be called from /usr/bin. It was designed to leverage the abilities of Linux, not just to be compatible with it.

### HiveOS Integration (Windows or Linux)

**Note: SWARM is developed and used regulary on latest HiveOS Stable, and is recommended for Ubuntu 18.04, which is the linux version most miners are developed on. If you experience issues using bleeding edge/beta image, please report issue, and I will connect to bleeding edge image, and fix asap.**

To focus solely on SWARM's project mission: SWARM was written to integrate fully with HiveOS as of version 1.4.5. The developer of SWARM recognizes the attempt to make an OS/website as sophisticated as the years of development and effort placed into HiveOS would be pointless. Therefor, knowing that SWARM was capable of operating within HiveOS- SWARM was introduced to HiveOS as an available custom miner, and can be integrated rather easily. SWARM also has created a significant amout of scripts which can be ran automatically through HiveOS, and even locally on rig- Allowing you to run multiple terminals and windows, and customize your own setup. Commands like ``get stats`` and ``benchmark all`` can be ran at any moment- Allowing you to quick make changes as neccessary. You also have ALL of the functionality you would get with HiveOS, along with MOST of the functionality of HiveOS's website in the Windows version.

### Highly Sophisticated Customization
* OC Tuning by algorithm (May be out of date- Use HiveOS if you want this feature)
* ``-API_Key`` allows oc_profiles in HiveOS
* Customize environment variables, add starting scripts
  to miner launches.
* Factor/adjusts power costs.
* Prohibit miners / algorithms / pools with a single argument ``-Bans``
* AI controls / bans miners and pools when issues arise.
* AI can factor items like pool hashrates, and SWARM
  uses specific calculations for each pool.
* Can enable solo mining with wallets.json, control
  multiple wallets / switching at a pool level.
* Tracks historical statistics using rolling
  exponential moving averages.
* Adjust starting difficulty of each miner.
* Control pricing time frames.
* Divide rig into seperate mining groups.
* Test .bat files are made in each .\bin folder of
  miner using last SWARM settings (for miner troubleshooting).
* Intesity/Difficulty are recorded with hashrates, and stored in
  .\bin folder of miner. (Where applicable).

SWARM is very customizable. At the base layer- It is easy to setup by simply inputting some basic user configuration at launch, and SWARM will handle the rest. However, beyond the base layer, SWARM offers a sophisticated oc tuning system, along with the ability to customize environment varibles, miner arguments, pool difficulty, and even a system for factoring power cost/calculation into profit analysis. SWARM allows you prohibt miners from certain algorithms, or prohibit mining certain algorithms on certain pools. SWARM also has the ability to control your overclocking internally, including support for AMD Vega in Windows using the latest drivers. It also supports accepting overclocking commands via HiveOS's website, with use of -API_key. 

![alt text](https://github.com/MaynardMiner/SWARM_PHOTOS/blob/master/win%20example.png)

![alt text](https://github.com/MaynardMiner/SWARM_PHOTOS/blob/master/HiveOS_Example.png)

### Bash or Powershell Scripting

SWARM was designed to make SWARM bigger than itself. All commands can be executed via bash scripts/shell commands on the linux side, and we are slowly implementing the same features to the window's side. With the ``Lite`` mode, SWARM can be easily incorporated into any current miningOS available, and users can customize/create their own launch process, independent of SWARM. In Windows, you should be able to run cmd.exe and powershell actions through HiveOS dashboard. An example of this would be:

``get-process | Where-Object name -eq "pwsh-preview"``

Would give you a list of all powershell core processes.

## Development 

I am a sole developer, and this is a large project. I prioritize workload by requests and activity, if you would like me to develop/improve a particular version Just notify me. Currently, the most popular, most used, and most user supported feature of SWARM is utilizing it as a custom miner in HiveOS. This was not an easy task, and also not easy to continue to maintain. This is why the fee of 1.5% is applied.

## Simple Install Instructions 

### Windows

**SWARM requires no installation. However there are a few pre-requisites:**
* Windows 10 is supported, but it should work in Windows 7/8.
* Have recent cuda/amd drivers installed. 
  * Note- The latest drivers aren't always the best to use, see discord support if you have questions.
* C++ Redistributable Packages for Visual Studio. (2012 and up)
  * https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads
* HiveOS user account, your farm hash ready. Ideally a pre-made flight sheet for SWARM. See wiki on how to setup a flight sheet.
  * https://hiveos.farm/
* Latest Powershell Core, along with it being set in your PATH environment variable (should be done during install of Powershell Core).
    https://github.com/PowerShell/PowerShell/releases/tag/v7.0.0-rc.3
* Latest .NET core runtime.
  * https://dotnet.microsoft.com/download/dotnet-core/3.0
* Latest .NET runtime.
  * https://dotnet.microsoft.com/download/dotnet-framework/net472

*Install Steps:*

Optional: Open SWARM.bat, change wallet with your BTC wallet, modify/add/replace arguments to your specifications. See help
          files for a list of arguments. Or use github wiki. If using HiveOS- You will only ever have to do this once.
          You could also instead copy ``config\parameters\defaults.json`` as ``newarguments.json`` in same directory, and edit 
          it as desired.

Launch SWARM.bat. First time run will start ``swarm_help``.

If you chose to use HiveOS:

Step 1: Copy your arguments from swarm. It will instruct you what to copy. 

Step 1: When background agent starts- Go to HiveOS.

Step 2: Create a flight sheet for SWARM (SEE HiveOS install below), you can omit Installation URL since you are already
        Installed. Copy arguments you pasted in flight sheet. See photos below. 

Step 3: Apply flight sheet to your newly created SWARM worker.

Step 4: Confirm SWARM has restarted- At this point when background agent starts- SWARM should communicate stats to
        HiveOS, and should be ready to accept commands. You will no longer need to modify the .bat file/json- You modify arguments
        through HiveOS and your flight sheet.
        
### HIVEOS

NOTE: HiveOS currently uses Cuda 10.2 as default.

SWARM is simple to install in linux environment, if a user is familiar with linux operating systems. There are plenty of users to help/support you, if you should decide to learn how to operate/use SWARM. However, it does take the commitment of learning how to use/manage linux.

There is a Windows version that stats to HiveOS, that is constantly being worked on/improved. If you are unsure of your capabilities of using linux- You can always use the Windows version, and get most of the features SWARM has to offer, as well as help me improve it.

This is an example of how to remote install/update miner. It is the fastest way to get going. Simply enter tar.gz file name from latest release. Then insert link for tar.gz. Next in wallet/worker templates enter 'blah'. Lastly, your setup arguments go in the last box, labeled extra config arguments. After that, you are are good to go! See wiki on proper argument use. Here is a photo of setup:

Coin/Wallet is irrelevant. You can basically enter whatever you want. Then navigate to custom miner:

![alt text](https://github.com/MaynardMiner/SWARM_PHOTOS/blob/master/First_Step.png)

From there you should see this window. Pool and URL are setup with arguments. However, Hive 2.0 requires those fields to not be empty. You can simply enter anything there. See photo below on how to setup miner. Just insert the name of the latest release, and the release tar.gz file link. Then insert your arguments in the bottom box:

## FULL ARGUMENT LIST:

[view ./help/SWARM_help.txt](https://github.com/MaynardMiner/SWARM/blob/master/help/SWARM_help.txt)

## SAMPLE ARGUMENT SETUPS:

https://github.com/MaynardMiner/SWARM/wiki/Arguments-(Miner-Configuration)

![alt text](https://github.com/MaynardMiner/SWARM_PHOTOS/blob/master/Second.png)

**Note**

You may need to Rocket Launch/Reboot in order to have Agent restart and start recieving data from SWARM

## CONTACT

Communication channels For SWARM- 

Discord: https://discord.gg/5YXE6cu

Telegram: @Swarm_Mining

Reddit: https://www.reddit.com/r/SWARM_Miner

## DONATE TO SUPPORT!

BTC WALLET: 1FpuMha1QPaWS4PTPZpU1zGRzKMevnDpwg

NICEHASH WALLET: 39iUh6aforxHcBr3Ayywmnqw2ZHcbmy9Wj

### Integrated Software

SWARM uses the following programs to help with oc tuning/rig setup,

Thank you to the developers that created them:

-nvidiainspector

-wolfamdctrl/ohgodatool

-overdriventool

-OhGodAnETHlargementPill-r2

-techPowerUp GPU-Z

-AMDMemoryTweak

-ODVII (self-created app in SWARM) for AMD ADL methods.

-AmdMemInfo

Consider Donating to these developers for their efforts.

nvfans (self-created app in SWARM) uses the following wrapper for nvidia control in Windows:

https://github.com/falahati/NvAPIWrapper

All licenses and developer information are included. I am not responsible for
their software, nor do I maintain them. They are downloaded from their
known distrubution sources and/or are included in mining OS. USE AT YOUR OWN DISCRETION.

THIS SOFTWARE IS PROVIDED AS-IS, USE AT YOUR OWN DISCRETION- DEVELOPERS TAKE NO RESPONSIBILITY
FROM ANY DAMAGES/ISSUES THAT MAY BE A RESULT OF USING THE THIRD PARTY SOFTWARE INCLUDED
IN SWARM! IT IS HIGHLY RECCOMMENDED THAT USERS ARE FAMILIAR WITH MINING SOFTWARE AND THE MINING
PROCESS IN GENERAL PRIOR TO USING SWARM.

You may see other apps inside apps folder- These are depreciated, and no longer
in use.

### Special Thanks To:

The other developers of open-source mining software, and their efforts. I note these, as I have at one point in time over history consulted their codebase/wisdom looking for solutions to issues. If you are not happy with SWARM, here are some other software you can use that other powershell developers work on:

https://github.com/MrPlusGH/NPlusMiner 

https://github.com/nemosminer/NemosMiner

https://github.com/Sniffdog/Sniffdogminer

https://github.com/MultiPoolMiner/MultiPoolMiner

https://github.com/Quake4/MindMiner

https://github.com/RainbowMiner/RainbowMiner

All projects go in different directions and have different perceptions/perspectives on profit switching and profit calculation.
