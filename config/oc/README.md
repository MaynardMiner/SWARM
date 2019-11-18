## Note- OC Profiles Have Not Been Tested In Awhile. It is advised to use ``-API_Key`` argument and set OC through HiveOS with OC Profiles.


# Initializing / Starting OC Tuning / Default Settings

The first step to enabling OC Tuning, is to set your default settings. Default settings are used when there is no specific algorithm profile available. It also enables OC Tuning altogether.

Leave "Cards": "" To not use OC tuning, or to turn it off.

For Cards: Enter as shown below in "Cards" example P-Model Cards Must Be Specified As Such: P106-100 P106-090 P104-100 P102-100 If you require more p-model cards- Contact Developer.

## NVIDIA Example

```
{ 
  "Cards": "1070 1070 1070 1050ti 1050ti 1050ti 1070 1050ti 1050ti 1070 1070 1050ti 1050ti" 
}
```

If Cards Is Not Empty: Defaults MUST Be Specified For ALL Cards! You cannot leave blank! "default" is settings used for algorithms left without any oc settings. Have "Cards" set will essentially "turn on" OC-Tuning.

```
"default_NVIDIA1": {
     "Power": "150 150 150 75 75 75 150 75 75 150 150 75 75", 
     "Core": "100 100 100 100 100 100 100 100 100 100 100 100 100", 
     "Memory": "1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000 1000" 
     "Fans": "75 75 75 75 65 75 75 85 75 75 65 75 75"
     } 
```

You may elect to use only 1 value, which will set all cards to that value:

```
"default_NVIDIA1": {
     "Power": "150", 
     "Core": "100", 
     "Memory": "100"
     "Fans": "75 75 75 75 65 75 75 85 75 75 65 75 75"
     } 
```

Here is a sample for Multiple device groups:

-Type NVIDIA1,NVIDIA2 -GPUDevices1 0,4 -GPUDevices2 1,2,3

```
    "Cards": "1080ti 1070 1070 1070 1080ti",  ##List all cards
    "default_NVIDIA1": {
        "Power": "175 175",    ## Cards For NVIDIA1, which is 0,4
        "Core": "100 100",
        "Memory": "1000 1000",
        "Fans": "80 80"
    },
    "default_NVIDIA2": {
        "Power": "150 150 150",   ## Cards for NVIDIA2, which is 1,2,3
        "Core": "100 100",
        "Memory": "1000 1000",
        "Fans": "80 80"
    },
```

Again, setting one value will set all cards in that group to specified value:

-Type NVIDIA1,NVIDIA2 -GPUDevices1 0,4 -GPUDevices2 1,2,3

```
    "Cards": "1080ti 1070 1070 1070 1080ti",  ##List all cards
    "default_NVIDIA1": {
        "Power": "175",    ## Cards For NVIDIA1, which is 0,4
        "Core": "100",
        "Memory": "1000",
        "Fans": "80"
    },
    "default_NVIDIA2": {
        "Power": "150",   ## Cards for NVIDIA2, which is 1,2,3
        "Core": "100",
        "Memory": "1000",
        "Fans": "80"
    },
```

## AMD Example (Linux).

This is identical to HiveOS aggressive overclocking:

```
{ 
  "Cards": "RX580 RX580 Vega56 Vega64" 

    "default_AMD1": {
        "dpm": "5 5 5 5",
        "v": "925 925 1100 1100",
        "core": "1150 1150 1250 1250",
        "mem": "1200 1200 1100 1100",
        "mdpm": "2 2 3 3",
        "fans": "75 75 80 80"
    }
```

Note: Singular values CAN be used.

## AMD Example (Windows):

AMD Windows works differently:

CPU And Memory voltages are set across all P-States by default. You have three methods in which you can set overclock:
Method 1: by dpm

By specifying dpm, SWARM will use that P-State voltage as reference, and will set all voltages to the same voltage as state. By using-

dpm: 5 5 5 5

P-states 1-7 will use the same voltage as P-State 5. If you do not wish to use this method. DO NOT SET dpm!
Method 2: By Core Memory and Mdpm:

example:

```
core: 1200 1200 1200 1200
memory: 1100 1100 1000 1100
mpdm: 2 2 2 2
```

With this setting, you are setting the Core Clock for all P-States to 1200. You are setting Memory Clock for all P-States to 1100. You are setting all memory P-States to use the same voltage as Memory P-State 2.
Method 3:

You can set memory voltage and memory frequency together using ";". This does not work in HiveOS!

example:

```
dpm:
v: "825 825 825 825 825 825",
core: "1150 1150 1150 1150 1150 1150",
memory: "2000;775 2000;775 2000;775 2000;775 2000;775 2000;775",
mdpm: "",
```

-Sets Core voltage for all states to 825 -Sets Core Clock to all states to 1150 -Sets Memory Clock to all states to 2000 -Sets Memory Voltage to all states to 775

(Note: This method cannot be used in HiveOS, due to the ";" that is used.)
Fan Settings

You can set the Fan level for each Fan State, as per HiveOS operation. Optionally- You can set a fan curve by using a ";" between each value. This does not work in HiveOS. The temperatures for the states are preset to a reasonable default which is:

     P0: 55C P1: 60C P2: 65C P3:68C P4:70C

So when P0 temperature is reached 55C the fan speed will be set to the first value, when 60C to the second value and so on. You can set one value for all GPUs or distinct values for each GPU.

    Full example which is working okay for RX580:

```
    "default_AMD1": {
      "dpm": "",
      "v": "825 825 825 825 825 825",
      "core": "1150 1150 1150 1150 1150 1150",
      "memory": "2000;775 2000;775 2000;775 2000;775 2000;775 2000;775",
      "mdpm": "",
      "fans": "20;30;50;65;80", ## Works for all cards
      "target_temps": "60 60 60 60 60 60"  ## This parameter is manually added, but can be used.
    }
```

Another Working Example, using HiveOS Compatible Settings:

```
    "default_AMD1": {
      "dpm": "",
      "v": "825 825 825 825 825 825",
      "core": "1150 1150 1150 1150 1150 1150",
      "memory": "2000 2000 2000 2000 2000 2000",
      "mdpm": "2 2 2 2 2 2",
      "fans": "80 80 80 80 80 80", ## Works for all cards
    }
```

Note: Regardless of checking "Aggressive OC: Aggressive settings will ALWAYS be used.

Setting Algorithm Specific Settings
oc-algos.json

In the same location as the oc-defaults.json, is the oc-algos.json. This sheet allows users to specify specific algorithm profiles for each algorithm available in SWARM. Here are the basic rules:

### NVIDIA
* If you wish to set only 1 value (just power), it is recommended to set all values. (power, core, memory, fans)
* Stock values for Core and Memory are 0
* Negative values can be set for Core and Memory.
* Windows values for memory are halved. Memory 1000 in linux is Memory 500 in Windows.
* If you do not wish to use the ETH pill for that algorithm- leave EthPill: ""
* If you DO wish to use ETH pill for that algorithm- Set ETHPill "Yes"
* If you wish to create a delay between ETHPill and miner start- Use "PillDelay": ""
* If you do not fill out the profile: Default settings are used.

### AMD
* All rules regarding defaults apply the same to each algorithm.
* If you do not fill out the profile: Default settings are used.

## Examples

Here are some examples (Assuming oc-defaults have been filled out as instructed above):

-Type NVIDIA1,NVIDIA2 -GPUDevices1 0,4 -GPUDevices2 1,2,3

```
    "ethash": {
        "NVIDIA1": {
            "Power": "150",   #Since only 1 value used, sets for all cards: Both card 0 and card 4
            "Core": "100",
            "Memory": "500",
            "Fans": "75",
            "ETHPill": "Yes",
            "PillDelay": "1"
        },
        "NVIDIA2": {
            "Power": "75 175 150",  ##Values for card 1 2 and 3
            "Core": "100 90 0",
            "Memory": "1000 750 900",
            "Fans": "75 75 80",
            "ETHPill": "Yes",
            "PillDelay": "1"
        },
        "NVIDIA3": {
            "Power": "",
            "Core": "",
            "Memory": "",
            "Fans": "",
            "ETHPill": "",
            "PillDelay": ""
        },
        "AMD1": {
            "fans": "",
            "v": "",
            "dpm": "",
            "mem": "",
            "mdpm": "",
            "core": ""
        }
    },
```


-Type AMD1

```
   (Cards were RX580 RX580 RX580)

    "ethash": {
        "NVIDIA1": {
            "Power": "",
            "Core": ""
            "Memory": "",
            "Fans": "",
            "ETHPill": ""
            "PillDelay": ""
        },
        "NVIDIA2": {
            "Power": "",
            "Core": "",
            "Memory": "",
            "Fans": "",
            "ETHPill": "",
            "PillDelay": ""
        },
        "NVIDIA3": {
            "Power": "",
            "Core": "",
            "Memory": "",
            "Fans": "",
            "ETHPill": "",
            "PillDelay": ""
        },
        "AMD1": {
            "fans": "80 80 80",
            "v": "1150 1150 1150",
            "dpm": "",
            "mem": "1200 1200 1200",
            "mdpm": "2 2 2",
            "core": "1150 1150 1150"
        }
    },
```
