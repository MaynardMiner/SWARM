# Using / Understandn Miner Configuration Files

Inside this folder are the items which can be actively modified for each miners that exist in SWARM.
This is a breakdown of each file, how to use it, and example uses.

```
    "name": "cc-mtp",
```

```
    "NVIDIA1": {
        "name": "NVIDIA1",
        "delay": "1",
        "prestart": [
            "echo THIS MINER REQUIRES 6GB OF RAM MINIMUM"
        ],
        "commands": {
            "mtp": ""
        },
        "difficulty": {
            "mtp": ""
        },
        "naming": {
            "mtp": "mtp"
        },
        "fee": {
            "mtp": 0
        }
    },
```

## Name                                          [String]
* Current Name of Miner File.

## Device Group (NVIDIA1,AMD1,CPU)               [HASHTABLE]

Each miner file has a section for each device group in SWARM. For example,
cc-mtp.json has an NVIDIA1,NVIDIA2,NVIDIA3 device groups. If you were using
the argument ``-Type NVIDIA1,NVIDIA2`` you would use the NVIDIA2 section for
the NVIDIA2 device group, NVIDIA1 section for the NVIDIA1 device group.

### Name [Device Group]                           [STRING],[Sub-Item Of Device Group]
* Name of current hashtable.

### Delay [int]                                   [Integer],[Sub-Item Of Device Group]
* Whole numbers only (int)
* Specifies a delay period between launches.
* Number signifies seconds.

### Prestart [STRING]                             [STRING],[Sub-Item Of Device Group]
* These are bash/shell/cmd commands.
* These items will be ran immediately before starting miner.
* These commmands will be executed in the same window as shell for miner.
* Only 1 line commands.
* Can launch pre-scripts here.
* Can set environment variables here.

### Commands [String]                            [STRING],[Sub-Item Of Device Group]
* Additional arguments.
* Users can add additional commands / arguments for each miner here.
* Adding "-i 20" for a ccminer would specify an intensity of 20.
* A space should be between each new item "-i 20 --No-NVML"
* This may not work for all miners.

# Difficulty [String]                           [STRING],[Sub-Item of Device Group]
* Add your difficulty setting here.
* This is a string- Do not add int values here. keep " " between number
* "200" would specify difficulty of 200
* This does now work for all miners.

### Naming [STRING]                               [STRING],[Sub-Item of Device Group]
* This is the conversion method from SWARM names algorithm to miner aglortihm
* Some miners use different names than SWARM to denote algorithms.
* If you are adding a new algorithm- You must add it to Pool-Algos.json first.
* The format is SWARM NAME : MINER NAME
* To give an example:
```
            "aergo": "aeriumx",
```
* This may not work for all miners.

### Fee [int]                                     [INT],[Sub-Item of Device Group]
* Fee for current algorithm.
* Must be an integer value.
* Must ALWAYS be present.
* Set to 0 if there is no fee.

