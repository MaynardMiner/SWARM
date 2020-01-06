
# SWARM Config files.

## asic Folder
asic folder contains an optional .json for adding individual ASIC units to SWARM. Each ASIC created will add another ASIC unit for SWARM to track. See its README for more details.

## miners Folder
miners folder contains user-adjustable control information for each miner. Each miner has a static .ps1 that is located in the miners folder within the main directory. These are meant to be static in design, and will not transfer on updates. The .json within the miners folder WILL transfer on update, so your settings are saved. Each .json allows you to add algorithms, add commands (arguments), adjust fee, and add a unique algorithm name for the algorithm (if the -algorithm argument does not match the name of the algorithm itself). They are seperate so that when updates are made, your data is saved. In some rare cases some data may be overwritten, usually notated on the release when this is the case.

## oc Folder
oc folder allows you to create local profiles for each algorithm within SWARM for gpu mining. See README.md for more details. Note: You can use HiveOS oc settings instead of using a local profile. It is not recommended to use one or the other, but not to use both at the same time. This is for users that do not with to HiveOS, and handle everything locally.

## parameters Folder
parameters folder is the saved user config for arguments. When SWARM is first started, it either parses users arguments, or gathers them from HiveOS. These arguments are converted to .json, and then SWARM laters uses this .json for reference when needed.

## pools Folder

pools folder contains .json control file which handle pool specific items. These items mainly are for name conversion for algorithms, and bans specific for pools or global bans. When a user specifies a ban, they are usually written here for SWARM to reference during startup.

## power Folder

power folder contains .json control file for saving permanent power settings for cards and SWARM. SWARM normally will write stat files, and self-montior power settings. However, if you wish to create a manual entry, you would do so here. These will override SWARM's power AI. There is also the ability to set a variable power cost schema by hour rather than just a flat rate.

## update Folder

update folder contains the miner download information. When you run ``version update``, you are modifying these .json files. SWARM checks the version number and the links of each file. If the version number is different than the current registered version, it triggers and update to run for that miner, using the update link supplied.

## wallets Folder

wallets folder is an advanced config file that allows you to create wallet profiles. This can allow you to do things like solo or party mine specific algorithms when profitable, as well as allow you set admin rates. Most of the abilities in the file can also be done with arguments, but the .json file here allows you to permanently create these settings that will transfer on updates.
