# Power Configuration

## KWH

Example:

```
  "KWh": {
    "note": "You can now set Kw/h by hour. KW/h is based on your fiat currency. So the below 0.1 would be .10 USD",
    "0": "0.1",
    "1": "0.1",
    "2": "0.1",
    "3": "0.1",
    "4": "0.1",
    "5": "0.1",
    "6": "0.1",
    "7": "0.1",
    "8": "0.1",
    "9": "0.1",
    "10": "0.1",
    "11": "0.1",
    "12": "0.1",
    "13": "0.1",
    "14": "0.1",
    "15": "0.1",
    "16": "0.1",
    "17": "0.1",
    "18": "0.1",
    "19": "0.1",
    "20": "0.1",
    "21": "0.1",
    "22": "0.1",
    "23": "0.1"
  },
```
### Hashtable "KWh"
* Each hour here can have a different value.
* The value must be a decimal value.
* The values will be based on your fiat currency.

### HashTable "default"

```
  "default": {
    "NVIDIA1_Watts": "",
    "NVIDIA2_Watts": "",
    "NVIDIA3_Watts": "",
    "AMD1_Watts": "",
    "CPU_Watts": ""
  },
```

* This allows you to set default watt values for each device.
An example of this:

```
  "default": {
    "NVIDIA1_Watts": "1056",
    "NVIDIA2_Watts": "",
    "NVIDIA3_Watts": "",
    "AMD1_Watts": "452",
    "CPU_Watts": "75"
  },
```


### Hashtable "Algorithm"
* These are added as SWARM takes benchmarks.
* An example of this:

```
  "ethash": {
    "NVIDIA1_Watts": "",
    "AMD1_Watts": "347.40434875227",
    "CPU_Watts": "",
    "NVIDIA3_Watts": "",
    "NVIDIA2_Watts": "225"
  },
```

* These will only be recorded when ``-WattOMeter`` is set to "Yes"
* They will stay even if ``-WattOmeter`` is set to "No"
* This allows you to turn it on, then lock in/append values by turning it off.

