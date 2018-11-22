**SWARM**



**Hybrid Profit Switching Miner For HiveOS & Windows.**



**Important Note:**



If you would like SWARM incorporated into an OS besides HiveOS, contact the developers, and show them this:



https://github.com/MaynardMiner/SWARM/wiki/Developer's-Corner



**What is SWARM?**



SWARM is an collection scripts written in both powershell and bash, and is a profit switching mining system that will work within any OS. SWARM, is written to be used as an all purpose/all platform mining system that can be implemented/managed on a large scale basis. It was developed for larger mining administrators, who are generally unable to interact with every mining unit/rig directly. SWARM deviates from conventional in-depth GUI interfaces, or a centralized monitoring system/screen which are a burden to mining administrators. SWARM introduces a new method of interface which is meant to assist larger mining systems, by displaying information per user command. Because SWARM's interface is command based as opposed to GUI- Users are able to create scripts of their own to micro-manage their farms/workers.



SWARM has an api layer, which is produced when ``-LITE Yes`` is specified. This ``LITE`` mode allows for the data of SWARM to be displayed in API format through HTTP. This allows both users and developers to create their own mining administration/launch script for miners, and simply use SWARM to gather data and formulate calculations on which miner/pool/algo combination is most profitable.



To focus solely on SWARM's project mission: SWARM was written to integrate fully with HiveOS as of version 1.4.5. The developer of SWARM recognizes the attempt to make an OS/website as sophisticated as the years of development and effort placed into HiveOS would be pointless. Therefor, knowing that SWARM was capable of operating within HiveOS- SWARM was introduced to HiveOS as an available custom miner, and can be integrated rather easily.



SWARM is very customizable. At the base layer- It is easy to setup by simply inputting some basic user configuration at launch, and SWARM will handle the rest. However, beyond the base layer, SWARM offers a sophisticated oc tuning system, along with the ability to customize environment varibles, miner arguments, pool difficulty, and even a system for factoring power cost/calculation into profit analysis.



The key theme SWARM emphasis, is to make SWARM bigger than itself. All commands can be executed via bash scripts/shell commands on the linux side, and we are slowly implementing the same features to the window's side. With the ``Lite`` mode, SWARM can be easily incorporated into any current miningOS available, and users can customer their own launch.



I am a sole developer, and this is a large project. I prioritize workload by requests and activity, if you would like me to develop/improve a particular version Just notify me. Currently, the most popular, most used, and most user supported feature of SWARM is utilizing it as a custom miner in HiveOS.



**How Does SWARM work?**



SWARM can be broken down into 6 phases:



``Startup Phase``

``SWARM begins initial start by detecting current features/platform/devices, and automatically generating default tables in which to build calculations. Once SWARM has built to its environment, including installing possible missing libraries It begins to gather current recorded stat information from previous launches, as well as initializing an update if it required and user has specified it.``



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





